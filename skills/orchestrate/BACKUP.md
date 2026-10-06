---
name: orchestrate
description: "Take one ticket from the tracker to a reviewed, CI-green PR ready for human merge. Picks the ticket, delegates implementation to sub-agents, runs the two-axis code review, opens the PR, and loops on CI and Codex review findings until clean."
argument-hint: "Optional ticket id; otherwise the next ready ticket is picked"
disable-model-invocation: true
---

You are the **orchestrator**. You own one ticket from pick-up to a PR that is ready for the human to merge. You delegate the building to sub-agents and keep your own context for decisions: what to build, whether it's good enough, and what to send back.

The issue tracker should have been provided to you. If `docs/agents/issue-tracker.md` is missing, tell the user to run `/setup-matt-pocock-skills`.

## Pipeline

```text
Orchestrator  pick ticket → clarify (human only if unclear) → branch
Implementer   build on branch → internal checks green → return
Review        code-review skill → fix sub-agents → internal checks → verdict
Orchestrator  open/update PR → wait for CI + Codex
Codex         reviews the PR on GitHub
Orchestrator  findings? → Implementer → Review → push → Codex again
              clean? → report to human
Human         reviews PR, merges, ticket closes
```

**Why Review runs in your session**: sub-agents can't spawn sub-agents. The Review stage needs the `code-review` skill (which spawns two) and fix sub-agents, so you run it directly instead of delegating it.

**You never merge and never close the ticket.** Those are the human's.

## 1. Pick the ticket

If the user passed a ticket id, use it. Otherwise list open tickets via `docs/agents/issue-tracker.md` and take the highest-priority one that is unassigned, not blocked by another open ticket, and has no open PR already.

Mark it in progress (assign or label it, whichever the tracker supports) so a parallel run doesn't pick it too.

## 2. Decide whether it's clear

A ticket is **clear** when you can write down, without guessing:

- the acceptance criteria (what observable behaviour proves it's done)
- the area of the codebase it touches
- which seams the tests belong at (see the `tdd` skill)

Read the ticket, its comments, linked tickets, `GLOSSARY.md`, and the code it touches before deciding. Most gaps close by reading. Ask the human only for what remains: a product decision, a conflicting requirement, a missing piece of the spec. Batch the questions into one `AskUserQuestion` call and offer your recommended answer first.

Write the result as a short **brief**: ticket id + link, acceptance criteria, seams to test, constraints, and any answers the human gave. Every sub-agent gets this brief, so it never has to re-read the ticket thread.

## 3. Prepare

- Find the **internal checks**: the repo's own test, typecheck, and lint commands, from `package.json` scripts / `Makefile` / the CI workflow. Write them down as exact commands. Every sub-agent and every gate in this skill uses this same list.
- Create the branch from an up-to-date default branch: `<ticket-id>-<short-slug>`. Check it out in the working tree. One ticket per run, so the implementer works directly on it.

## 4. Implement (sub-agent)

Spawn one implementer sub-agent. Its prompt:

- "Call the Skill tool with `implement` if it exists, and `tdd`."
- The brief from step 2 and the branch name.
- The internal checks, as exact commands.
- The contract:
  - Work only on this branch. Commit in small steps with clear messages. Do not push and do not open a PR.
  - You're done only when every internal check passes locally.
  - If you hit a decision the brief doesn't answer, **stop and return a question** instead of guessing. Say what you've done so far and what each option would mean.
  - Return in this shape:

```text
STATUS: done | blocked
COMMITS: <git log --oneline of your commits>
CHECKS: <each command> → pass/fail
QUESTIONS: <numbered, only if blocked>
NOTES: <anything the reviewer should know: tradeoffs, skipped edge cases>
```

**Answering questions**: answer from the ticket, the code, and your brief. Escalate to the human only when it's genuinely a product decision. Then resume the *same* sub-agent with `SendMessage`, so it keeps its context. Add the answer to your brief and record that you made it (the final report lists these).

## 5. Review (you)

Don't trust a sub-agent's "green". Re-run the internal checks yourself first. If they fail, send the failure output back to the implementer.

1. Call the Skill tool with `code-review`, fixed point = the merge-base with the default branch, spec = the ticket.
2. Triage each finding:
   - **Must fix**: documented-standard violations; Spec findings for missing, partial, or wrong requirements; unasked-for scope creep.
   - **Fix if cheap**: baseline smells (judgement calls). Otherwise note them for the PR.
   - **Dismiss**: false positives. Note why in one line.
3. Spawn fix sub-agents with the brief, the internal checks, and their findings quoted verbatim. Group findings by file. Fix sub-agents run in parallel only if their file sets don't overlap, because they share the working tree. They return in the same shape as the implementer.
4. Re-run the internal checks yourself.
5. If there were must-fix findings, run `code-review` once more. Stop after **2 review rounds**. Carry whatever is left into the PR and the final report rather than looping.

The gate to step 6 is: internal checks green, and no unresolved must-fix findings.

## 6. Open or update the PR

- Push the branch.
- First time: create the PR with the `pr` skill (it writes the body; include `Closes #<ticket>`). Make it ready for review, not a draft, so CI and Codex trigger.
- Later rounds: push and update the PR body with the `pr` skill if the change's shape moved. A fix-only round needs no body edit.

## 7. Wait for CI and Codex

Note the head SHA you just pushed. Both signals are judged against that SHA only. Older results are stale.

- **CI**: `gh pr checks <pr> --watch` in the background. Red → collect the failing job's log (`gh run view <run-id> --log-failed`) as a finding.
- **Codex**: Codex reviews the PR on GitHub and posts as a bot whose login contains `codex`. Poll for its review and inline comments on the current head SHA:
  - `gh api repos/{owner}/{repo}/pulls/<pr>/reviews`
  - `gh api repos/{owner}/{repo}/pulls/<pr>/comments`
  - If nothing has arrived about 10 minutes after CI started, post `@codex review` on the PR once.
  - A Codex review with no inline comments, or a reaction or summary saying it found no issues, counts as **clean**.

Wait with long intervals. Each poll costs context, and neither signal arrives in seconds.

## 8. Loop on findings

Triage Codex comments the same way as step 5. For each dismissed comment, reply briefly on its thread with the reason, so the human sees why it was left.

If CI is red or there are must-fix Codex findings: implementer (step 4, with the findings as its task) → Review (step 5) → push (step 6) → wait (step 7).

Stop after **3 Codex rounds** and report what's still open. Past that point the human is cheaper than another loop.

## 9. Report to the human

When CI is green and Codex is clean (or you hit a cap), report in chat:

```markdown
**<ticket id> — <title>**: <PR link>
Status: ready for review | needs attention (<why>)

- **Built**: <one or two lines>
- **Checks**: <internal checks> green · CI <green/red>
- **Review**: <rounds> rounds · <n> fixed · <n> dismissed
- **Codex**: <rounds> rounds · <n> fixed · <n> dismissed (replied on thread)
- **Decisions I made for you**: <questions answered without asking, with the answer>
- **Open**: <anything left, or "nothing">
```

The "Decisions I made for you" line matters most. It's where the human checks your autonomous calls before merging.
