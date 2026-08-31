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
3. Run `phase_gate.py mode` through `"$RALPH_CODEX_PLUGIN_ROOT/scripts/phase_gate.py"` with `STATE` and exact `--quick`, exact `--interactive`, or no flag. Reject both, `-q`, variants, and natural-language substitutes.
4. In interactive mode, require artifact approval for the current `design.md` before starting tasks. Exact quick mode continues with the validated artifact.
5. Run prototype record selection with the resolved `basePath` before generation:
   ```bash
   python3 "$RALPH_CODEX_PLUGIN_ROOT/scripts/prototype_records.py" select-downstream --base-path "$BASE_PATH" --state "$BASE_PATH/.ralph-state.json"
   ```
6. Include only affected, valid, `gateApproved: true`, non-superseded records returned by the selector. Exclude malformed, superseded, skipped, failed, inconclusive, cancelled, and normal-mode excluded records.
7. Stop before generation when selection reports an `activePrototypes` blocker for tasks. Name the active ID and route resume through `$ralph-specum-prototype`. Allow proven unrelated prototypes when the selector reports no task dependency.
8. Stop when selection reports stale `design.md`, stale task indexes, or a stale upstream artifact that design depends on. Route to the earliest stale phase and do not plan from stale design.
9. Clear `awaitingApproval` and any prior `approvalGate` before generation.
10. Respect `granularity` from state. Allow `--tasks-size fine|coarse` to override it. Treat task sizing as administration, not an interview question. In exact quick mode, default unset granularity to `fine`.
11. When `research.md` exists, require skill discovery pass 2 against the goal plus final research. When it is absent, require pass 1 against the goal alone. Run the applicable pass when the state lacks its revision. Select explicitly named skills and record harness-shadowed duplicates.
12. Load `"$RALPH_CODEX_PLUGIN_ROOT/skills/interview-framework-codex/SKILL.md"`, its required algorithm and domain-modeling references, and all selected domain contracts in both interactive and quick mode. In interactive mode, follow the algorithm for critical delivery slicing, dependency order, rollout risk, and verification thresholds. Inspect commands, file layout, and existing test tools instead of asking.
13. In interactive mode, handle the canonical `approve and delegate` choice first. At an active interview question, `classify-reply` remains the only parser; only otherwise may `phase_gate.py resolve-approval STATE --text TEXT` accept the sole live `approve-and-delegate` action. An accepted result still runs `confirm --source approve-and-delegate`, then `check-delegation` with the current loaded-manifest identity before creating the child. In exact quick mode, record `bypassed_quick`.
14. **Delegate** task planning to a `task-planner` sub-agent. Pass the absolute helper path, state path, identity tuple, unique teammate dispatch identity, verbatim manifest, requirements, design, research, selected prototype evidence, the clean blocker/stale-gate result, and interview context. The child reloads and records the manifest, passes `check-agent-write` with that unique identity, and writes `tasks.md`. Do NOT write tasks.md yourself.
15. Read the sub-agent's output and validate it exists.
16. Count tasks and merge state with:
   - `phase: "tasks"`
   - `awaitingApproval: true` (or `false` when `--quick` is active)
   - `taskIndex: first incomplete or totalTasks`
   - `totalTasks: counted tasks`
17. Update `.progress.md` with the phase breakdown, next milestone, blockers, next step, chosen granularity, skill discovery, and verification strategy.
18. If spec commits are enabled, commit only the spec artifacts.

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
- Handle the listed canonical artifact choices first. This multi-option menu persists no `approvalGate`, so generic affirmatives leave state unchanged and ask one focused canonical choice. Only at a later single-action gate with `awaitingApproval: true` and one valid current `approvalGate` (nonblank `id`, `phase`, `kind`, and `action`; matching current phase) may a noncanonical reply call `resolve-approval`; missing, invalid, or multiple actions return clarification without a write. A revision descriptor and revision dispatch require recorded nonblank feedback. An accepted result follows the existing continuation or fresh-writer route, then clears or replaces the descriptor only after that route succeeds.
- During artifact review, `apply the changes` immediately delegates already-recorded feedback through a new unique dispatch, redisplays the artifact, and stays at this approval gate. Ask one focused change question only when no feedback is pending. The helper alone appends the accepted reply's audit; chat history never authorizes a later action.
