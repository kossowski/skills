# Personal skills

Agent skills for Claude Code and other agents that read `.agents/skills/`.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/kossowski/skills/main/install.sh | bash
```

The installer asks where to install:

1. **Global**: skills go into `~/.agents/skills/`, with symlinks in `~/.claude/skills/`.
2. **Project**: the same skills, installed into a project directory, plus `AGENTS.md`, `CLAUDE.md` and `docs/agents/`.
3. **Only project docs**: `AGENTS.md`, `CLAUDE.md` and `docs/agents/`, without skills.

Existing project docs are kept, because you are meant to edit them per project.

## Skills

Skills marked * only run when you call them (for example `/to-spec`). The agent loads the others by itself when they fit the task.

### Planning

| Skill             | What it does                                                                            |
| ----------------- | --------------------------------------------------------------------------------------- |
| `grilling`        | Stress-tests a plan, decision or idea                                                   |
| `interview` *     | Sharpens a plan through an interview and writes ADRs and glossary entries along the way |
| `domain-modeling` | Maintains `GLOSSARY.md` and ADRs                                                        |
| `to-spec` *       | Turns the conversation into a spec in the issue tracker                                 |
| `to-tickets` *    | Breaks a spec into tracer-bullet tickets with blocking edges                            |
| `triage` *        | Moves issues and external PRs through the triage roles and writes agent-ready briefs    |

### Implementation

| Skill              | What it does                                                                                |
| ------------------ | ------------------------------------------------------------------------------------------- |
| `implement` *      | Implements one spec or set of tickets on the current branch, test-first, then reviews it    |
| `implement-spec` * | Implements a whole spec by running subagents over the ticket graph on an integration branch |
| `developer`        | Implements one brief in a git worktree: test-first, checked, committed and reported         |
| `tdd`              | Test-driven development, red-green-refactor                                                 |
| `code-review`      | Reviews changes since a fixed point against the repo's standards and the originating spec   |
| `pr`               | Creates pull requests and writes their descriptions                                         |

### Architecture

| Skill                             | What it does                                                                        |
| --------------------------------- | ----------------------------------------------------------------------------------- |
| `codebase-design`                 | Shared vocabulary for designing deep modules, seams and testable interfaces         |
| `improve-codebase-architecture` * | Scans a codebase for deepening opportunities, reports them as HTML, then grills one |

### Writing

| Skill                | What it does                                                                  |
| -------------------- | ----------------------------------------------------------------------------- |
| `technical-writing`  | Writing standard for docs, RFCs, READMEs, PR descriptions and commit messages |
| `unslop-writing`     | Cuts AI tells from prose in project files                                     |
| `writing-for-agents` | Writes skills, `AGENTS.md` and `CLAUDE.md` for agents to read                 |

### Sessions

| Skill              | What it does                                                         |
| ------------------ | -------------------------------------------------------------------- |
| `chief-of-staff` * | Pursues a long-running goal in one session by coordinating subagents |
| `handoff` *        | Compacts the conversation into a handoff document for another agent  |
| `retro` *          | Runs a retrospective on a coding session                             |

## Project docs

`docs/agents/` tells the skills how a project works:

- `issue-tracker.md`: where issues live (GitHub issues through the `gh` CLI by default) and whether external PRs count as requests for `triage`
- `triage-labels.md`: the triage label vocabulary
- `domain.md`: where the glossary and ADRs live

## Credits

Most skills here are derived from [mattpocock/skills](https://github.com/mattpocock/skills) by Matt Pocock (MIT). See [`CREDITS.md`](CREDITS.md).
