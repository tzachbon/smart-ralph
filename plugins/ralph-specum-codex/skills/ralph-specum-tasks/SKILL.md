---
name: ralph-specum-tasks
description: This skill should be used only when the user explicitly asks to use `$ralph-specum-tasks`, or explicitly asks Ralph Specum in Codex to run the tasks phase.
metadata:
  surface: helper
  action: tasks
---

# Ralph Specum Tasks

You are a **coordinator, not a task planner** -- delegate ALL work to a `task-planner` sub-agent.

## Contract

- Resolve the active spec by explicit path, exact name, or `.current-spec`
- Require `requirements.md` and `design.md`
- Merge state fields only
- Keep the Ralph disk contract unchanged

## Action

1. Resolve the active spec. If none exists, stop.
2. Require `requirements.md` and `design.md`. Read `research.md` when present, `.progress.md`, and current state.
3. Run `scripts/phase_gate.py mode STATE` with exact `--quick`, exact `--interactive`, or no flag. Reject both, `-q`, variants, and natural-language substitutes.
4. In interactive mode, require artifact approval for the current `design.md` before starting tasks. Exact quick mode continues with the validated artifact.
5. Respect `granularity` from state. Allow `--tasks-size fine|coarse` to override it. Treat task sizing as administration, not an interview question. In exact quick mode, default unset granularity to `fine`.
6. When `research.md` exists, require skill discovery pass 2 against the goal plus final research. When it is absent, require pass 1 against the goal alone. Run the applicable pass when the state lacks its revision. Select explicitly named skills and record harness-shadowed duplicates.
7. Load `skills/interview-framework-codex/SKILL.md`, its required algorithm and domain-modeling references, and all selected domain contracts in both interactive and quick mode. In interactive mode, follow the algorithm for critical delivery slicing, dependency order, rollout risk, and verification thresholds. Inspect commands, file layout, and existing test tools instead of asking.
8. In interactive mode, require explicit `approve and delegate`; in exact quick mode, record `bypassed_quick`. In both modes, run `phase_gate.py check-delegation` with the current loaded-manifest identity before creating the child.
9. **Delegate** task planning to a `task-planner` sub-agent. Pass the absolute helper path, state path, identity tuple, unique teammate dispatch identity, verbatim manifest, requirements, design, research, and interview context. The child reloads and records the manifest, passes `check-agent-write` with that unique identity, and writes `tasks.md`. Do NOT write tasks.md yourself.
10. Read the sub-agent's output and validate it exists.
11. Count tasks and merge state with:
   - `phase: "tasks"`
   - `awaitingApproval: true` (or `false` when `--quick` is active)
   - `taskIndex: first incomplete or totalTasks`
   - `totalTasks: counted tasks`
12. Update `.progress.md` with the phase breakdown, next milestone, blockers, next step, chosen granularity, skill discovery, and verification strategy.
13. If spec commits are enabled, commit only the spec artifacts.

### Stop Behavior

- **Without `--quick`**: STOP HERE. Display the walkthrough summary and approval prompt. Do NOT continue to implementation. Wait for the user to explicitly approve and request the next phase.
- **With exact `--quick`**: Record the quick bypass, review, then continue directly into implementation.

## Output Shape

Use atomic tasks with exact file targets, explicit success criteria, verification commands, and commit messages. Preserve POC-first ordering. Support `[P]` markers for safe parallel work, `[VERIFY]` checkpoints, and VE tasks when end-to-end verification is part of the plan.

## Response Handoff

- After writing `tasks.md`, name `tasks.md` and summarize the task plan briefly.
- When normalized `quickMode` is false, end with exactly one explicit choice prompt:
  - `approve current artifact`
  - `request changes`
  - `continue to implementation`
- Treat `continue to implementation` as approval of `tasks.md`.
- With exact `--quick`, do not show this prompt; continue directly to implementation after the gates succeed.
- During artifact review, `apply the changes` immediately delegates already-recorded feedback through a new unique dispatch, redisplays the artifact, and stays at this approval gate. Ask one focused change question only when no feedback is pending. Control-only `continue`, `proceed`, and `go ahead` approve nothing.
