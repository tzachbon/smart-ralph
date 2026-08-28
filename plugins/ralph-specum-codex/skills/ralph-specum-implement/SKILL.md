---
name: ralph-specum-implement
description: This skill should be used only when the user explicitly asks to use `$ralph-specum-implement`, or explicitly asks Ralph Specum in Codex to run implementation for approved tasks, quick mode, or an explicit continue request.
metadata:
  surface: helper
  action: implement
---

# Ralph Specum Implement

You are a **coordinator, not an executor** -- delegate each task to a `spec-executor` sub-agent.

## Contract

- Resolve the active spec by explicit path, exact name, or `.current-spec`
- Require `tasks.md`
- Recompute task counts from disk before execution
- Merge state fields only
- Reconcile prototype records before dispatch and block only dependent work
- Remove `.ralph-state.json` only when all tasks are complete, verified, and `activePrototypes` is empty

## Action

1. Resolve the active spec. If none exists, stop.
2. Require `tasks.md`. Read `.progress.md`, current state, and current task markers.
3. Recompute task counters from disk: `total`, `completed`, and `next_index`.
4. Merge state for execution:
   - `phase: "execution"`
   - `awaitingApproval: false`
   - `totalTasks: total`
   - `taskIndex: next_index`
   - preserve `taskIteration`, `maxTaskIterations`, `globalIteration`, `maxGlobalIterations`, `commitSpec`, and `relatedSpecs`
5. Before dispatch, run `prototype_records.py reconcile` and `select-downstream` with the resolver's `basePath` whenever `activePrototypes` is nonempty. Stop only when `activeBlockers` targets execution or the current task, the current index is in `staleTaskIndexes`, or an upstream artifact required by tasks is in `staleArtifacts`. Report the prototype ID and resume through `$ralph-specum-prototype --resume <id>`. Proven unrelated work remains eligible.
6. When a prototype returns to execution, restore `taskIndex` from its `returnTaskIndex` through `merge_state.py`, then verify that it is the first eligible incomplete task.
7. **Delegate** each task to a `spec-executor` sub-agent. Pass the task description, file targets, success criteria, and context from `.progress.md`. The sub-agent implements the task and outputs `TASK_COMPLETE`. Do NOT implement tasks yourself. Execute tasks in order until complete or blocked.
8. `[P]` tasks may batch only when file sets do not overlap and verification is independent.
9. `[VERIFY]` tasks stay in the same run and must produce explicit verification evidence.
10. Marker syntax must be explicitly present in `tasks.md`. If markers are absent, treat tasks as non-batchable by default.
11. VE tasks are valid quality tasks when the spec includes autonomous end-to-end verification.
12. Native task sync metadata should be preserved when present.
13. After each task or safe batch:
   - mark the checkbox
   - update `.progress.md`
   - merge the state update
   - use the task `Commit` line unless commits were explicitly disabled
14. Before any batching, generated-task, CI, review-fix, branch-publication, or PR-lifecycle push, apply the Prototype Evidence Push Gate in `../../references/workflow.md`. Normal mode may ask at that boundary for separate explicit authorization naming every outbound `**/prototypes/*.md` record. Quick mode asks no question and skips every push. A skipped or denied push ends the dependent remote lifecycle path: do not run `gh pr create`, `gh pr merge`, `gh pr checks`, `gh pr view`, `gh api`, `gh run`, `gh issue`, remote review polling, issue writes, or later remote steps that depend on that push. Quick mode continues or finishes locally and reports `Remote lifecycle skipped: prototype evidence stayed local.` Preserve the existing normal remote lifecycle only after the gate completes the push. Never push an isolated prototype source branch. `commitSpec` authorizes local commits only.
15. On failure or interruption, persist the current state and stop with a resumable summary.
16. On full completion, reconcile again. If `activePrototypes` remains nonempty, preserve `.ralph-state.json` and stop with its IDs. Otherwise remove state and report completion.

## Resume Rules

- Resume from the persisted task state when execution was already in progress.
- If disk state and task checkboxes disagree, prefer `tasks.md` for completion and repair state to match.
- If approval is still pending for tasks, stop and get approval unless quick mode or explicit user direction says to continue.
- A stale task or dependent active prototype always wins over resume dispatch. An unrelated active prototype does not pause the current task.
