#!/usr/bin/env bash
# Stops what a developer or a check left running from one worktree, from a ticket's worktree
# ../<repo>-worktrees/<NN>, or from the whole worktrees folder: dev servers, Storybook, vitest
# browser runs and their Chromium. Matches on the working directory of each process, spares this
# shell, its parents and PID 1, and prints what it stopped. In a Session container, PID 1 is
# docker-init in the Runner, and stopping it ends the container. Shells (sh, bash, zsh, dash, fish)
# are never stopped, since they can be the owner's terminal tabs; the script lists them as skipped.
#
# Usage: scripts/stop-leftovers.sh [<worktree> | <NN>]
set -uo pipefail
project="$(dirname "$0")/../../../project.env"
[ -f "$project" ] && . "$project"
main=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
wts=$main/../$(basename "$main")-worktrees
if [[ ${1:-} =~ ^[0-9]+$ ]]; then
  [[ -d $wts/$1 ]] || { echo "no worktree $(realpath -m "$wts")/$1"; exit 0; }
  dirs=("$(realpath -m "$wts/$1")")
else
  dirs=("$(realpath -m "${1:-$wts}")")
fi

skip=" 1 $$ "; p=$PPID
while [[ $p -gt 1 ]]; do
  skip+="$p "
  p=$(awk '/^PPid:/{print $2}' "/proc/$p/status" 2>/dev/null || echo 1)
done

shells=" sh bash zsh dash fish "
pids=()
for d in /proc/[0-9]*; do
  pid=${d#/proc/}
  [[ $skip == *" $pid "* ]] && continue
  cwd=$(readlink "$d/cwd" 2>/dev/null) || continue
  for dir in "${dirs[@]}"; do
    [[ $cwd == "$dir" || $cwd == "$dir"/* ]] || continue
    comm=$(cat "$d/comm" 2>/dev/null)
    arg0=$(tr '\0' '\n' <"$d/cmdline" 2>/dev/null | head -1)
    arg0=${arg0#-}
    if [[ $shells == *" $comm "* || $shells == *" ${arg0##*/} "* ]]; then
      echo "skipping shell $pid: $(tr '\0' ' ' <"$d/cmdline" 2>/dev/null | cut -c1-100) in $cwd"
    else
      pids+=("$pid")
    fi
    break
  done
done

if ((${#pids[@]} == 0)); then
  echo "nothing running under ${dirs[*]}"
else
  for pid in "${pids[@]}"; do
    echo "stopping $pid: $(tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null | cut -c1-100) in $(readlink "/proc/$pid/cwd" 2>/dev/null)"
  done
  kill "${pids[@]}" 2>/dev/null
  sleep 3
  alive=()
  for pid in "${pids[@]}"; do [[ -d /proc/$pid ]] && alive+=("$pid"); done
  ((${#alive[@]})) && kill -9 "${alive[@]}" 2>/dev/null
  echo "stopped ${#pids[@]} process(es)"
fi

for port in ${DEV_PORTS:-}; do
  holder=$(ss -ltnpH "sport = :$port" 2>/dev/null | grep -o 'pid=[0-9]*' | head -1)
  [[ -n $holder ]] && echo "port $port is still held by pid ${holder#pid=}, which runs outside ${dirs[*]}"
done
exit 0
