---
name: ralph-specum
description: Use only when the user explicitly invokes `$ralph-specum`, requests Ralph Specum in Codex, or asks Ralph Specum to handle a named phase.
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
- `skills/interview-framework-codex/SKILL.md` and its required algorithm and domain-modeling references for every normal-mode phase interview

## Use These Helpers

- `scripts/resolve_spec_paths.py` for spec roots, current spec, and unique or ambiguous name resolution
- `scripts/merge_state.py` for safe top-level state merges
- `scripts/count_tasks.py` for task counts and next incomplete task
- `scripts/phase_gate.py` for mode, skill-load, interview, parent-delegation, and artifact-write gates
- `assets/templates/` for the canonical Ralph markdown file shapes
- `assets/bootstrap/` when the user wants optional project-local Codex guidance

## Primary Routing

Handle these intents directly:

| Intent | Action |
|--------|--------|
| Start, new, resume, quick mode | Follow the start flow in `references/workflow.md` |
| Triage | Delegate to `triage-analyst` sub-agent to decompose into epic and specs |
| Research | Delegate to `research-analyst` sub-agent to write `research.md` |
| Requirements | Delegate to `product-manager` sub-agent to write `requirements.md` |
| Design | Delegate to `architect-reviewer` sub-agent to write `design.md` |
| Tasks | Delegate to `task-planner` sub-agent to write `tasks.md` |
| Implement | Delegate each task to `spec-executor` sub-agent until complete or blocked |
| Status | Show active spec, backlog state, and per-root listing |
| Switch | Update `.current-spec` only |
| Cancel | Stop execution and clean up state, confirm before destructive delete |
| Index | Generate `specs/.index/` component and external specs |
| Refactor | Delegate to `refactor-specialist` sub-agent to update spec files |
| Feedback | Open or draft GitHub feedback |
| Help | Summarize the surface and next commands |

If the corresponding helper skill is installed and the user invoked it explicitly, keep behavior aligned with that helper. If not, perform the action here.

## Core Rules

0. **You are a coordinator, not a doer.** Delegate each phase to the appropriate sub-agent and never write spec artifacts (`research.md`, `requirements.md`, `design.md`, or `tasks.md`) yourself. For only `start`, `triage`, `research`, `requirements`, `design`, and `tasks`, gather context, discover and preload contracts, run the interview, obtain final approval, pass the gate, delegate, validate the output, and present results for artifact approval. Keep the existing delegation flows for `implement` and `refactor` unchanged; the new phase gates do not apply to them.
1. Keep the Ralph disk contract stable.
2. Treat `.claude/ralph-specum.local.md` as the settings source when present.
3. Default to `./specs` when no valid config exists.
4. Keep `.current-spec` in the default specs root.
5. Merge state fields. Do not replace the whole state object.
6. Preserve `source`, `name`, `goal`, `basePath`, `phase`, `taskIndex`, `totalTasks`, `taskIteration`, `maxTaskIterations`, `globalIteration`, `maxGlobalIterations`, `commitSpec`, and `relatedSpecs`.
7. Also preserve newer state fields when present, especially `awaitingApproval`, `quickMode`, `granularity`, `epicName`, `discoveredSkills`, and native task sync metadata.
8. Write `.progress.md` after every phase and after every implementation attempt.
9. Keep pre-delegation interview approval separate from post-generation artifact approval.
10. Honor the `Commit` line in tasks during implementation unless the user explicitly disables task commits.
11. Use branch creation or worktree creation when the user asks for branch isolation or the repo policy requires it.
12. Run `phase_gate.py mode` at entry to every affected phase. Only exact `--quick` enables quick mode; exact `--interactive` clears it. Reject both together, `-q`, variants, and natural-language substitutes. No flags normalize invalid legacy quick state to interactive.
13. In exact quick mode, run discovery and contract loading, record the current manifest and `bypassed_quick`, generate missing artifacts, default task granularity to `fine` when unset, and continue into implementation in the same session.
14. For normal-mode start, triage, research, requirements, design, and tasks, follow `skills/interview-framework-codex/references/algorithm.md` before each delegation.

## Stop Enforcement

Before delegating any affected phase in normal mode, you MUST:

1. Complete the applicable discovery pass and reload receipts
2. Finish all critical decision frontiers
3. Obtain explicit `approve and delegate`
4. Pass `phase_gate.py check-delegation`

After completing any phase artifact (research, requirements, design, tasks), you MUST:

1. Display the walkthrough summary
2. Present the approval prompt (approve / request changes / continue to next)
3. **STOP and wait for user response**

The ONLY exception is exact `--quick` mode with a valid bypass receipt. Without it, you MUST NOT auto-continue to the next phase.

## Response Handoff

- After writing `research.md`, `requirements.md`, `design.md`, `tasks.md`, or refactored spec files outside quick mode:
  - name the file or files that changed
  - give a short summary
  - end with exactly one explicit choice prompt:
    - `approve current artifact`
    - `request changes`
    - `continue to <named next step>`
- Treat `continue to <named next step>` as approval of the current artifact and permission to enter that phase's discovery and interview path.
- Treat `apply the changes` during artifact review as immediate authorization to delegate already-recorded revision feedback through a new unique dispatch. Redisplay and remain at artifact approval. Ask one focused change question only when no feedback is pending.
- Treat control-only `continue`, `proceed`, and `go ahead` as approval of nothing.
- After normal-mode `start` or `new` setup, run discovery pass 1 and begin the goal grill. Explicit final approval delegates research immediately.

## Current Workflow Expectations

- Use critical-decision frontier interviews for start, triage, research, requirements, design, and tasks when quick mode is not active. Ask no setup, administration, or discoverable question.
- Route obviously large or cross-cutting efforts to triage before normal spec generation.
- Support active epic state via `specs/.current-epic` and per-epic state in `specs/_epics/<epic-name>/`.
- Treat task planning as POC-first with `[P]` markers for safe parallel work and `[VERIFY]` checkpoints for explicit quality validation.
- Support VE tasks when the plan needs autonomous end-to-end verification.
- During implementation, recompute task counts from disk, resume from the first incomplete task, and prefer task file truth over stale state.
- Native task sync is part of the current Ralph execution model. Keep Codex wording aligned with that behavior without promising Claude-only hook mechanics.

## Bootstrap

Bootstrap project-local files only when the user wants them.

Suggested bootstrap files:

- `assets/bootstrap/AGENTS.md` to give a consumer repo local Ralph guidance
- `assets/bootstrap/ralph-specum.local.md` to seed local settings

Do not bootstrap by default. Installation into `$CODEX_HOME/skills` is enough.
