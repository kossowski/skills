#!/usr/bin/env bash
# Install the skills for Claude Code and other agents.
#
#   curl -fsSL https://raw.githubusercontent.com/kossowski/skills/main/install.sh | bash
#
# Skills are copied into <base>/.agents/skills/ and symlinked from
# <base>/.claude/skills/, where <base> is $HOME (global) or a project directory.
# Projects also get AGENTS.md, CLAUDE.md and docs/agents/ if they are missing.
set -euo pipefail

REPO_URL=https://github.com/kossowski/skills.git

# A set CDPATH makes `cd` print the directory, which breaks `$(cd ... && pwd)`.
unset CDPATH

# With `curl | bash` stdin is the script itself, so prompts use the terminal.
ask() {
  printf '%s' "$1" >/dev/tty
  read -r REPLY </dev/tty
}

ask_project() {
  ask "Project directory [$PWD]: "
  project=${REPLY:-$PWD}
  project=${project/#\~/$HOME}
  [[ -d $project ]] || { echo "not a directory: $project" >&2; exit 1; }
  project=$(cd -- "$project" && pwd)
  # Claude Code loads ~/CLAUDE.md in every project below home.
  if [[ $(cd -- "$project" && pwd -P) == "$(cd -- "$HOME" && pwd -P)" ]]; then
    echo "refusing to install project files into your home directory" >&2
    exit 1
  fi
}

cat >/dev/tty <<'EOF'
What do you want to install?
  1) Global skills  (~/.agents, ~/.claude)
  2) Project        (skills + AGENTS.md, CLAUDE.md, docs/agents)
  3) Only Project docs   (AGENTS.md, CLAUDE.md, docs/agents, no skills)
EOF
ask '> '
skills_base="" project=""
case $REPLY in
  1) skills_base=$HOME ;;
  2) ask_project; skills_base=$project ;;
  3) ask_project ;;
  *) echo "invalid choice: $REPLY" >&2; exit 1 ;;
esac

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
git clone --quiet --depth 1 "$REPO_URL" "$tmp/repo"

if [[ -n $skills_base ]]; then
  mkdir -p "$skills_base/.agents/skills" "$skills_base/.claude/skills"
  # Relative links survive moving the project, but only resolve correctly when
  # .claude/skills is not reached through a symlink (e.g. a dotfiles repo).
  link_base="../../.agents/skills"
  if [[ $(cd -- "$skills_base/.claude/skills" && pwd -P) != "$(cd -- "$skills_base" && pwd -P)/.claude/skills" ]]; then
    link_base="$(cd -- "$skills_base/.agents/skills" && pwd -P)"
  fi
  for dir in "$tmp"/repo/skills/*/; do
    src=${dir%/}
    name=${src##*/}
    link="$skills_base/.claude/skills/$name"
    if [[ -e $link && ! -L $link ]]; then
      echo "skipped $name: $link exists and is not a symlink" >&2
      continue
    fi
    rm -rf "$skills_base/.agents/skills/$name"
    rm -f "$link"
    cp -R "$src" "$skills_base/.agents/skills/$name"
    ln -s "$link_base/$name" "$link"
    echo "installed $name"
  done
fi

# Agent docs describe one repo, so they only go into projects. Existing files
# are kept because they are meant to be edited per project.
if [[ -n $project ]]; then
  mkdir -p "$project/docs/agents"
  for src in "$tmp/repo/AGENTS.md" "$tmp/repo/CLAUDE.md" "$tmp"/repo/docs/agents/*.md; do
    rel=${src#"$tmp/repo/"}
    if [[ -e $project/$rel ]]; then
      echo "kept $rel"
    else
      cp "$src" "$project/$rel"
      echo "copied $rel"
    fi
  done
fi
