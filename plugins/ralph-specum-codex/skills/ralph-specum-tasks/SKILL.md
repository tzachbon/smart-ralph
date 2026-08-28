---
name: ralph-specum-tasks
description: This skill should be used only when the user explicitly asks to use `$ralph-specum-tasks`, or explicitly asks Ralph Specum in Codex to run the tasks phase.
metadata:
  surface: helper
  action: tasks
---

# Ralph Specum Tasks

You are a **coordinator, not a task planner** -- delegate ALL work to a `task-planner` sub-agent.

Derive `RALPH_CODEX_PLUGIN_ROOT` from this loaded skill by resolving two parent directories from the `SKILL.md` directory. Never derive it from the project working directory.

## Contract

- Resolve the active spec by explicit path, exact name, or `.current-spec`
- Require `requirements.md` and `design.md`
- Merge state fields only
- Keep the Ralph disk contract unchanged

## Action

1. Resolve the active spec. If none exists, stop.
2. Require `requirements.md` and `design.md`. Read `research.md` when present, `.progress.md`, and current state.
3. Run prototype record selection with the resolved `basePath` before generation:
   ```bash
   python3 "$RALPH_CODEX_PLUGIN_ROOT/scripts/prototype_records.py" select-downstream --base-path "$BASE_PATH" --state "$BASE_PATH/.ralph-state.json"
   ```
4. Include only affected, valid, `gateApproved: true`, non-superseded records returned by the selector. Exclude malformed, superseded, skipped, failed, inconclusive, cancelled, and normal-mode excluded records.
5. Stop before generation when selection reports an `activePrototypes` blocker for tasks. Name the active ID and route resume through `$ralph-specum-prototype`. Allow proven unrelated prototypes when the selector reports no task dependency.
6. Stop when selection reports stale `design.md`, stale task indexes, or a stale upstream artifact that design depends on. Route to the earliest stale phase and do not plan from stale design.
7. Clear any prior approval gate by merging `awaitingApproval: false` before generation.
8. Respect `granularity` from state. Allow `--tasks-size fine|coarse` to override it. In quick mode, default unset granularity to `fine`.
9. Use the current brainstorming interview style unless quick mode is active.
10. **Delegate** task planning to a `task-planner` sub-agent. Pass requirements, design, research, selected prototype evidence, the clean blocker/stale-gate result, and interview context. The sub-agent writes `tasks.md`. Do NOT write tasks.md yourself.
11. Read the sub-agent's output and validate it exists.
12. Count tasks and merge state with:
   - `phase: "tasks"`
   - `awaitingApproval: true` (or `false` when `--quick` is active)
   - `taskIndex: first incomplete or totalTasks`
   - `totalTasks: counted tasks`
13. Update `.progress.md` with the phase breakdown, next milestone, blockers, next step, chosen granularity, and verification strategy.
14. If spec commits are enabled, commit only the spec artifacts.

### Stop Behavior

- **Without `--quick`**: STOP HERE. Display the walkthrough summary and approval prompt. Do NOT continue to implementation. Wait for the user to explicitly approve and request the next phase.
- **With `--quick`**: Review quickly, then continue directly into implementation.

## Output Shape

Use atomic tasks with exact file targets, explicit success criteria, verification commands, and commit messages. Preserve POC-first ordering. Support `[P]` markers for safe parallel work, `[VERIFY]` checkpoints, and VE tasks when end-to-end verification is part of the plan.

## Response Handoff

- After writing `tasks.md`, name `tasks.md` and summarize the task plan briefly.
- End with exactly one explicit choice prompt:
  - `approve current artifact`
  - `request changes`
  - `continue to implementation`
- Treat `continue to implementation` as approval of `tasks.md`.
