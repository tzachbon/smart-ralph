---
name: ralph-specum
description: This skill should be used when the user asks to "use Ralph Specum in Codex", "start a Ralph spec", "run Ralph quick mode", "resume spec-driven work", "generate research requirements design or tasks", "implement a Ralph spec", "check Ralph status", "switch specs", "cancel Ralph execution", "index a codebase", "refactor Ralph specs", "submit Ralph feedback", or mentions "$ralph-specum".
metadata:
  surface: primary
---

# Ralph Specum

Use this as the primary Codex surface for Ralph Specum. It carries the full reusable workflow and can handle the entire command surface directly when helper skills are not installed.

## Read These References

- `references/workflow.md` for the phase flow, branch and worktree behavior, quick mode, and command routing
- `references/state-contract.md` for `.ralph-state.json`, `.progress.md`, commit rules, and resume semantics
- `references/path-resolution.md` for `specs_dirs`, `.current-spec`, ambiguity handling, and default directory behavior
- `references/parity-matrix.md` for Claude-to-Codex feature translation and command mapping

## Use These Helpers

- `scripts/resolve_spec_paths.py` for spec roots, current spec, and unique or ambiguous name resolution
- `scripts/merge_state.py` for safe top-level state merges
- `scripts/count_tasks.py` for task counts and next incomplete task
- `assets/templates/` for the canonical Ralph markdown file shapes
- `assets/bootstrap/` when the user wants optional project-local Codex guidance

## Primary Routing

Handle these intents directly:

| Intent | Action |
|--------|--------|
| Start, new, resume, quick mode | Follow the start flow in `references/workflow.md` |
| Research | Write `research.md` using the research template shape |
| Requirements | Write `requirements.md` using the requirements template shape |
| Design | Write `design.md` using the design template shape |
| Tasks | Write `tasks.md` using the tasks template shape |
| Implement | Run remaining tasks until completion or a blocker stops progress |
| Status | Show active spec, backlog state, and per-root listing |
| Switch | Update `.current-spec` only |
| Cancel | Stop execution and clean up state, confirm before destructive delete |
| Index | Generate `specs/.index/` component and external specs |
| Refactor | Update existing spec files after implementation learnings |
| Feedback | Open or draft GitHub feedback |
| Help | Summarize the surface and next commands |

If the corresponding helper skill is installed and the user invoked it explicitly, keep behavior aligned with that helper. If not, perform the action here.

## Core Rules

1. Keep the Ralph disk contract stable.
2. Treat `.claude/ralph-specum.local.md` as the settings source when present.
3. Default to `./specs` when no valid config exists.
4. Keep `.current-spec` in the default specs root.
5. Merge state fields. Do not replace the whole state object.
6. Preserve `source`, `name`, `basePath`, `phase`, `taskIndex`, `totalTasks`, `taskIteration`, `maxTaskIterations`, `globalIteration`, `maxGlobalIterations`, `commitSpec`, and `relatedSpecs`.
7. Write `.progress.md` after every phase and after every implementation attempt.
8. Honor the `Commit` line in tasks during implementation unless the user explicitly disables task commits.
9. Use branch creation or worktree creation when the user asks for branch isolation or the repo policy requires it.
10. In quick mode, generate missing artifacts and continue into implementation in the same session.

## Bootstrap

Bootstrap project-local files only when the user wants them.

Suggested bootstrap files:

- `assets/bootstrap/AGENTS.md` to give a consumer repo local Ralph guidance
- `assets/bootstrap/ralph-specum.local.md` to seed local settings

Do not bootstrap by default. Installation into `$CODEX_HOME/skills` is enough.
