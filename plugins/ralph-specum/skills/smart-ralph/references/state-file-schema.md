# State File Schema

Ralph plugins use `.ralph-state.json` to track execution state.

## Location

```
<resolved-basePath>/.ralph-state.json
```

Resolve `specRoot` and `basePath` before reading or writing state. Use `.claude/ralph-specum.local.md` `specs_dirs` when configured; use `./specs` only as the resolver fallback. Derive the state, lock, candidate, terminal record, context, and index paths from the resolved `basePath`.

## Schema

```json
{
  "phase": "research|requirements|design|tasks|execution",
  "taskIndex": 0,
  "totalTasks": 0,
  "taskIteration": 1,
  "maxTaskIterations": 5,
  "awaitingApproval": false,
  "activePrototypes": {
    "risk-check": {
      "id": "risk-check",
      "stateRevision": 1,
      "status": "building",
      "triggerPhase": "requirements",
      "returnPhase": "design",
      "returnTaskIndex": null,
      "decisionOwner": "user|agent",
      "requestAttempt": 1,
      "builderExecutionAttempt": 1,
      "isolation": {
        "path": "/absolute/isolated/path",
        "branch": "local-prototype-branch",
        "baseCommit": "<commit>"
      }
    }
  }
}
```

## Field Definitions

| Field | Type | Description |
|-------|------|-------------|
| `phase` | string | Current workflow phase |
| `taskIndex` | number | 0-based index of current task |
| `totalTasks` | number | Total tasks in tasks.md |
| `taskIteration` | number | Current retry attempt (1-based) |
| `maxTaskIterations` | number | Max retries before blocking |
| `awaitingApproval` | boolean | Waiting for user to proceed |
| `activePrototypes` | object, optional | Live prototype overlays keyed by immutable prototype ID |

A missing `activePrototypes` field means an empty map. The helper creates the map on the first reservation and removes the field when the final active entry is removed. Prototype status is live lifecycle state such as `pending`, `isolating`, `building`, `reviewing`, `awaiting_verdict`, `handoff`, `blocked`, or `timed_out`; `removed` is a helper result, not a stored status.

## Phase Values

| Phase | Description |
|-------|-------------|
| `research` | Research phase active |
| `requirements` | Requirements gathering |
| `design` | Technical design |
| `tasks` | Task planning |
| `execution` | Task execution loop |

`prototype` is excluded from main phase values. It is valid only as terminal record frontmatter under `<basePath>/prototypes/<id>.md`.

## State Transitions

```
research -> requirements -> design -> tasks -> execution
```

Each phase sets `awaitingApproval: true` after completion (except quick mode).

An overlay preserves the main phase. Its active entry records `triggerPhase`, `returnPhase`, and `returnTaskIndex`; terminal handoff restores those values or moves to the earliest artifact made stale by the selected evidence.

## Locked Mutations

Use `plugins/ralph-specum/hooks/scripts/locked-state.py` for `merge`, `upsert-prototype`, `remove-prototype`, `claim-builder`, `heartbeat`, `renew-lease`, `release-lease`, `transition`, and `delete-state`. The helper locks `<basePath>/.ralph-state.lock`, preserves unknown fields, flushes replacement bytes, and atomically replaces state. Reads stay lock-free because replacement is atomic.

Completion may call `delete-state` only when `activePrototypes` is empty. A lock timeout stops normal mutation. Quick mode retries once, leaves state unchanged if the retry fails, publishes a local failed `lock_timeout` record through the exclusive publisher path, and continues to design.

## Records And Gates

Render candidates exclusively under `<basePath>/prototypes/.candidates/`, review the exact bytes and source evidence, then publish `<basePath>/prototypes/<id>.md` without overwrite. Terminal records are immutable. A correction, conflict decision, cancellation, or changed conclusion creates a new ID and names prior records in `supersedes`.

Downstream selection accepts only valid, non-superseded, `gateApproved` records. In normal mode, the user chooses whether validated or rejected evidence is included. In quick mode, the agent approves validated or rejected evidence; skipped, failed, and inconclusive records do not feed design. Active blockers and stale indexes stop only dependent work.

Source remains in the recorded isolated path; the current checkout does not switch. Retained source gets a local isolated-branch commit. `commitSpec` controls local terminal-record commits. Pushes, remote branches, PR inclusion, issue writes, and other remote actions require separate explicit authority.

## Corruption Handling

If state file missing or invalid JSON:
1. Output error with state file path
2. Suggest re-running the implement command
3. Do NOT continue execution

For valid state with interrupted prototype publication, reconcile candidates and finals before dispatch. A valid final with a matching candidate or active entry completes idempotently; a mismatched candidate is quarantined; a malformed final is excluded; an active entry without a candidate resumes from its recorded status and isolation pointers. This recovery does not bypass the missing or invalid JSON guard. Preserve `.ralph-state.json` while any active prototype remains.

## Validation

Coordinator validates state against tasks.md checkmarks. If `taskIndex` does not match the checked task count, repair the counter through a locked merge while preserving `activePrototypes` and unknown fields.
