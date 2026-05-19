# Ralph State Contract

## Core Files

Each spec directory uses:

- `.ralph-state.json`
- `.progress.md`
- `research.md`
- `requirements.md`
- `design.md`
- `tasks.md`

## Required State Fields

Preserve these fields across all phases:

- `source`
- `name`
- `basePath`
- `phase`
- `taskIndex`
- `totalTasks`
- `taskIteration`
- `maxTaskIterations`
- `globalIteration`
- `maxGlobalIterations`
- `commitSpec`
- `relatedSpecs`

Optional but common:

- `awaitingApproval`
- `recoveryMode`
- `fixTaskMap`

## New Spec Defaults

Use these defaults when a new spec starts:

```json
{
  "source": "spec",
  "name": "<spec-name>",
  "basePath": "<resolved-spec-path>",
  "phase": "research",
  "taskIndex": 0,
  "totalTasks": 0,
  "taskIteration": 1,
  "maxTaskIterations": 5,
  "globalIteration": 1,
  "maxGlobalIterations": 100,
  "commitSpec": true,
  "relatedSpecs": [],
  "awaitingApproval": false
}
```

Read `default_max_iterations` and `auto_commit_spec` from `.claude/ralph-specum.local.md` when present.

## Merge Rule

Never rebuild state from scratch once the file exists. Merge only the fields needed for the current phase.

Use `scripts/merge_state.py` for deterministic top-level merges.

## Approval Contract

`awaitingApproval: true` is not enough on its own.

This mirrors `Approval Prompt Shape` in `references/workflow.md` and should stay in sync with that section. Current enforcement is via Codex platform review plus the repo-local metadata and content checks.

When a phase sets `awaitingApproval: true`, the visible assistant response must also:

- name the file or files that changed
- give a short summary
- end with exactly one explicit choice prompt:
  - `approve current artifact`
  - `request changes`
  - `continue to <named next step>`

Treat `continue to <named next step>` as approval of the current artifact and permission to move forward.

## Progress File

`.progress.md` is persistent. Keep:

- original goal
- current phase
- current task summary
- completed task notes
- learnings
- blockers
- next step

## Commit Rules

- Spec artifacts may be auto-committed when `commitSpec` is true.
- Implementation tasks should use the task's `Commit` line by default.
- If the user disables commits, keep the disk state and progress updates but skip git commits.
