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

| Skill             | What it does                                                                              |
| ----------------- | ----------------------------------------------------------------------------------------- |
| `code-review`     | Reviews changes since a fixed point against the repo's standards and the originating spec |
| `domain-modeling` | Maintains `GLOSSARY.md` and ADRs                                                          |
| `grilling`        | Stress-tests a plan, decision or idea                                                     |
| `interview`       | Sharpens a plan through an interview and writes ADRs and glossary entries along the way   |
| `to-spec`         | Turns the conversation into a spec in the issue tracker                                   |
| `to-ticket`       | Breaks a spec into tracer-bullet tickets with blocking edges                              |
| `orchestrate`     | Implements specs and tickets in code                                                      |
| `tdd`             | Test-driven development, red-green-refactor                                               |
| `pr`              | Creates pull requests and writes their descriptions                                       |
| `handoff`         | Compacts the conversation into a handoff document for another agent                       |
| `retro`           | Runs a retrospective on a coding session                                                  |

## Project docs

`docs/agents/` tells the skills how a project works:

- `issue-tracker.md`: where issues live (local markdown under `.scratch/` by default)
- `triage-labels.md`: the triage label vocabulary
- `domain.md`: where the glossary and ADRs live

## Credits

Most skills here are derived from [mattpocock/skills](https://github.com/mattpocock/skills) by Matt Pocock (MIT). See [`CREDITS.md`](CREDITS.md).
