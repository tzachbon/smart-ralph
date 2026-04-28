---
spec: loop-safety-infra
phase: research
created: 2026-04-26T18:00:00Z
---

# Research: Loop Safety Infrastructure

**Spec**: `loop-safety-infra` | **Epic**: `engine-roadmap-epic` (Spec 4)
**Date**: 2026-04-26

---

## Executive Summary

This research covers the design of Bmalph-style safety infrastructure for the Smart Ralph execution loop. Five independent safety mechanisms are proposed: a pre-loop git checkpoint with rollback, a circuit breaker for consecutive failures, per-task JSONL metrics, a read-only filesystem heartbeat, and CI snapshot tracking. All mechanisms are designed as **append-only additions** to the existing `stop-watcher.sh` (765 lines) and `implement.md` (314 lines), avoiding modification of existing logic.

**Feasibility**: High | **Risk**: Low | **Effort**: Medium (estimated 8-10h implementation)

---

## 1. Git Checkpoint and Rollback

### 1.1 When to Create the Checkpoint

The checkpoint should be created at the transition from the `tasks` phase to the `execution` phase — when `/ralph-specum:implement` is invoked and the state file transitions to `phase: "execution"`.

**Recommendation**: Implement in `implement.md` coordinator (primary) with a verification in `stop-watcher.sh` (backup).

### 1.2 Checkpoint Command

```bash
git add -A && git commit --no-verify -m "checkpoint: before $spec_name execution (task 0/$total_tasks)"
```

Using `git add -A` captures all changes (tracked, deleted, new files). Using `--no-verify` prevents pre-commit hooks (e.g., linters) from blocking checkpoint creation. This is the right default for Smart Ralph because the plugin is used in focused sessions and rollback is always possible.

**Note**: Pre-commit hooks may still fail on the checkpoint itself (blocking execution). If a pre-commit hook is broken, fix it before running any spec. The `--no-verify` flag skips hook validation but does NOT prevent hook errors from blocking the commit.

### 1.3 SHA Storage in State File

```json
{
  "checkpoint": {
    "sha": "a1b2c3d4",
    "timestamp": "2026-04-26T18:30:00Z",
    "branch": "feat/engine-roadmap-epic",
    "message": "checkpoint: before loop-safety-infra execution"
  }
}
```

Nested `checkpoint` object keeps data grouped logically and is extensible (e.g., adding per-task checkpoints later).

### 1.4 Rollback Mechanics

- **Use `git reset --hard $SHA`** — restores working tree to checkpoint state, matching epic success criterion #9
- Preserves the checkpoint commit in git history for audit trail
- Rollback is an **explicit user command** (`/ralph-specum:rollback`), not automatic
- Why not automatic? Automatic rollback on failure could mask real bugs. The engine catches the problem; the human decides the remedy.
- Note: `--hard` discards all working tree changes since checkpoint. If the user wants diff visibility first, they can `git diff <checkpoint-sha> HEAD` before rolling back.

### 1.5 Edge Cases

| Scenario | Handling |
|----------|----------|
| No git repo | Graceful failure with `sha: null` in state |
| Detached HEAD | Graceful failure, log warning |
| Uncommitted changes at checkpoint | Included in checkpoint (with warning) |
| Untracked files | Included in `git add -A`, survive rollback |
| Pre-commit hook failure | **Block execution** — don't proceed without safety net |
| Conflicting changes | Abort checkpoint creation |
| Idempotency | Skip if SHA already stored |

### 1.6 Implementation Artifacts

- **New file**: `plugins/ralph-specum/hooks/scripts/checkpoint.sh` — `checkpoint-create` and `checkpoint-rollback` functions
- **Modified**: `plugins/ralph-specum/commands/implement.md` — add checkpoint step in Step 3
- **Modified**: `plugins/ralph-specum/schemas/spec.schema.json` — add `checkpoint` definition
- **Modified**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` — add checkpoint existence verification

---

## 2. Circuit Breaker

### 2.1 Pattern Selection

Three approaches evaluated (pattern names from existing libraries, implemented in bash):
- **Error-percentage model** (e.g., Netflix Hystrix): Tracks failure rate over a sliding window. Too noisy for sequential execution where each task is independent and there is no parallel noise.
- **Sliding-window model** (e.g., resilience4j): Counts failures over a time window. Overkill for deterministic agent execution where each task failure is a discrete event.
- **Absolute consecutive count** (e.g., Polly): Counts exact number of sequential failures before tripping. Best fit — sequential execution means no oscillating patterns, and the counter is simple to implement in bash with jq.

**Recommendation**: Absolute consecutive count pattern with a three-state machine (CLOSED → OPEN → manual reset to CLOSED).

### 2.2 State Machine

```
CLOSED (normal) → OPEN (tripped) → manual RESET → CLOSED (resumed)
```

HALF_OPEN is not recommended because the spec-executor is a deterministic agent — if it was stuck, it will be stuck again.

### 2.3 Trip Conditions

| Parameter | Default | Description |
|-----------|---------|-------------|
| `maxConsecutiveFailures` | 5 | Tasks that must fail consecutively to trip |
| `maxSessionSeconds` | 172800 (48h) | Maximum session wall-clock time |

The 5-consecutive-failure threshold complements the existing per-task `maxTaskIterations` limit (5 retries per individual task).

### 2.4 State Storage

Inline in `.ralph-state.json` under a `circuitBreaker` object:

```json
{
  "circuitBreaker": {
    "state": "closed",
    "consecutiveFailures": 0,
    "sessionStartTime": 1714145400,
    "openedAt": null,
    "trippedReason": null
  }
}
```

### 2.4.5 State Write Ownership

**Single writer**: The coordinator in `implement.md` owns ALL writes to `circuitBreaker` state.

| Event | Writer | Action |
|-------|--------|--------|
| Execution start | Coordinator (Step 3) | Initialize `circuitBreaker` to `{state: "closed", consecutiveFailures: 0, ...}` |
| Task completes (pass) | Coordinator (post-task) | Reset `consecutiveFailures` to 0 |
| Task completes (fail) | Coordinator (post-task) | Increment `consecutiveFailures` by 1 |
| Circuit trips | Coordinator | Set `state` to `"open"`, record `openedAt` and `trippedReason` |
| Manual reset | Human (direct JSON edit) | Set `state` to `"closed"`, reset `consecutiveFailures` to 0 |

**stop-watcher.sh role**: ONLY READS `circuitBreaker.state` and `circuitBreaker.consecutiveFailures` to check trip conditions. Never writes. This eliminates double-increment bugs where both coordinator and stop-watcher write to the same field.

### 2.5 Reset Strategy

**Manual only.** When the circuit opens, output a block prompt with reset instructions. The human must explicitly set `circuitBreaker.state = "closed"` and `circuitBreaker.consecutiveFailures = 0`.

### 2.6 Edge Cases

| Scenario | Handling |
|----------|----------|
| State file corruption | Default to "closed" with 0 failures (graceful degradation) |
| Session restart | `sessionStartTime` persists — timer is absolute, not reset-on-success |
| Parallel specs | Each spec has its own `.ralph-state.json` and circuit breaker |
| Epic-level execution | Circuit breaker is per-spec, not per-epic |
| Phase transitions | Only applies during "execution" phase |
| Human modifies state while OPEN | Stop-watcher allows exit (not re-block) |

### 2.7 Placement

Add in `stop-watcher.sh` after the global iteration check (~line 460), before role boundaries validation.

### 2.8 Precedence Over Repair Loop

When both the circuit breaker and repair loop could trigger:

1. **Circuit breaker timeout (48h)** — highest priority, always blocks immediately
2. **Circuit breaker consecutive failures** — checks after repair loop completes for the CURRENT task. If the counter exceeds `maxConsecutiveFailures`, execution stops. The repair loop for other pending tasks is not interrupted mid-flight.
3. **Repair loop exhaustion** — per-task block (only affects the current task)

In practice: the circuit breaker counter increments when a task exhausts its repair iterations. The circuit breaker trip is checked on the NEXT loop iteration, not during the current task's repair loop. This means the repair loop completes its 2 retries before the circuit breaker evaluates whether to trip.

### 2.9 Cross-Spec Interaction: Spec 6 Collaboration

Spec 6 (`collaboration-resolution`) encodes an iterative collaboration workflow (cross-branch regression → BUG_DISCOVERY → fix task → repeat). This workflow may produce consecutive task failures by design. The circuit breaker default of 5 consecutive failures could trip during a legitimate collaboration session.

**Mitigation**: Document this as a known interaction in `references/loop-safety.md`. Implementers should:
- Recognize that consecutive failures during Spec 6 collaboration may be intentional
- Consider adding a `circuitBreaker.exemptSignals` field (future enhancement) to pause counting when collaboration signals (`BUG_DISCOVERY`, `FIX_PROPOSAL`) are present
- For now, the 5-failure threshold provides adequate protection: 5 consecutive failures in collaboration is rare and worth blocking

---

## 3. Per-Task Metrics (JSONL) & CI Snapshot Tracking

### 3.1 Why JSONL

JSONL is the standard for append-only event logs. Benefits:
- **Append-safe**: Each line is a self-contained document
- **Stream-processable**: Consumed line-by-line by tools (jq, awk, grep)
- **Crash-resilient**: A crash mid-write corrupts only one line
- **Scalable**: Growing file doesn't change write characteristics

Used by: GitHub Actions, LangGraph/Prefect run tracing, OpenTelemetry file exporters.

### 3.2 Metrics Schema

```jsonc
{
  "schemaVersion": 1,
  // ── Identity ──
  "eventId": "uuid-v4",
  "spec": "loop-safety-infra",
  "taskIndex": 7,
  "taskIteration": 2,
  "globalIteration": 42,
  "timestamp": "2026-04-26T14:30:00Z",

  // ── Task metadata ──
  "taskTitle": "Implement user auth",
  "taskType": "implementation",
  "taskId": "8.3",

  // ── Timing ──
  "startedAt": "2026-04-26T14:30:00Z",
  "completedAt": "2026-04-26T14:32:15Z",
  "wallTimeMs": 135000,
  "verifyTimeMs": 5200,

  // ── Outcome ──
  "status": "pass",           // pass | fail | timeout | cancelled | ambiguous
  "commit": "a1b2c3d",
  "verifyExitCode": 0,
  "retries": 1,

  // ── Errors (only on failure) ──
  "error": null,
  "errorDetail": null,

  // ── Agent context ──
  "agent": "spec-executor",
  "toolsUsed": ["Read", "Edit", "Bash", "Write"],

  // ── CI snapshot ──
  "ciSnapshotBefore": null,
  "ciSnapshotAfter": null,
  "ciDrift": false
}
```

### 3.3 CI Command Discovery

Scan these files at spec initialization (runs once, not per-loop):

| File | Commands Found |
|------|---------------|
| `.github/workflows/*.yml` | CI pipeline steps (`bats tests/*.bats`, file existence checks) |
| `tests/*.bats` | BATS test commands |

**Context**: This is a Claude Code plugin repo. There is no `package.json`, `Makefile`, or `Jenkinsfile`. The actual CI consists of 4 GitHub Actions workflow files (`bats-tests.yml`, `codex-version-check.yml`, `plugin-version-check.yml`, `spec-file-check.yml`) running BATS tests and file checks. CI discovery focuses on `.github/workflows/*.yml` and `tests/*.bats`.

Commands are classified into categories by grepping for keywords in the command text.

### 3.3.1 CI Snapshot Scope Note

For plugin repos with few CI workflows, detailed CI snapshot tracking adds complexity for limited value. The P2 selective post-task CI is the most complex component in this section. Implementers should:
- Capture CI workflow existence at spec start (boolean flag: CI workflows found)
- Run `bats tests/` at spec completion (not per-task)
- Skip per-task CI for plugin repos with no package.json/test suite

### 3.4 CI Snapshot Strategy

Two-entry model:
- `ciSnapshotBefore` — captured at state init (pre-execution baseline)
- `ciSnapshotAfter` — captured post-task or spec-complete

Drift = passed at snapshot but fails now. Pre-execution baseline is the single reference point.

### 3.5 Selective Post-Task CI (Strategy Evaluation)

| Strategy | Pros | Cons | Verdict |
|----------|------|------|---------|
| Run all CI every task | Complete safety | Very slow | Reject |
| Run CI only at spec completion | Fast | Misses regressions | Weak |
| **Selective post-task CI** | Best balance | More complex | **Adopt** |

Selective: skip CI when only test files changed (trust task verify). Run lint+typecheck when source files change. Run full test+build only at spec completion.

### 3.6 Implementation Priority

| Priority | Component | File | Effort |
|----------|-----------|------|--------|
| P0 | Metrics schema + write function | `implement.md` + `write-metric.sh` | 2h |
| P1 | CI command discovery | `implement.md` Step 3 | 1.5h |
| P1 | Pre-execution CI snapshot | `implement.md` Step 3 | 1h |
| P2 | Post-task selective CI | Coordinator | 2h |
| P2 | CI drift detection | `stop-watcher.sh` (read-only) | 1h |

### 3.7 Metrics Lifecycle

| Event | Action |
|-------|--------|
| Spec execution start | `implement.md` Step 3: `touch "$SPEC_PATH/.metrics.jsonl"` (creates empty file) |
| Per-task completion | Coordinator (implement.md) calls `write-metric.sh` to append one JSONL line |
| Spec completion | File persists; no cleanup required |
| Spec cancellation | File persists (for debugging why it was cancelled) |
| Rollback | File persists (historical record; may contain stale data post-rollback) |

### 3.8 Metrics Writing Data Flow

```
Task completes → spec-executor outputs TASK_COMPLETE
  → coordinator (implement.md) parses verify result
  → coordinator calls write-metric.sh with spec_path, status, task_index, verify_result
  → write-metric.sh acquires flock, appends JSONL line, releases lock
```

The coordinator owns metrics writes. The spec-executor does NOT write metrics directly. This keeps the executor agent simple and avoids concurrent file access issues.

### 3.9 write-metric.sh Interface

A new file `plugins/ralph-specum/hooks/scripts/write-metric.sh` with one function:

```bash
write_metric() {
  local spec_path="$1" status="$2" task_index="$3" task_iteration="$4"
  local verify_exit_code="${5:-0}" task_title="${6:-}" task_type="${7:-}"
  local task_id="${8:-}" commit_sha="${9:-}"
  # ... appends JSONL line to "$spec_path/.metrics.jsonl" using flock ...
}
```

Called from `implement.md` coordinator in Step 5 (post-task) after TASK_COMPLETE is received.

### 3.10 Key Design Decisions

- Metrics file is **per-spec**, not global (`specs/<name>/.metrics.jsonl`)
- CI discovery runs **once at state init**, not per-loop iteration
- **stop-watcher only reads metrics** — never writes
- Metrics writing uses **flock** — same concurrency model as existing chat.md lock
- Task-level verify commands remain **independent** of CI commands
- `write-metric.sh` is a **new separate script** (not inline in implement.md) — enables reuse across specs and cleaner testing

---

## 4. Read-Only Filesystem Detection

### 4.1 Heartbeat Pattern

Write a small `.ralph-heartbeat` file to the spec directory, verify round-trip read-back. Total cost ~7ms per invocation.

**Critical**: The heartbeat check must ALWAYS run on every loop iteration, including the first. A conditional check that only runs when failures were previously detected will skip the critical first iteration.

```bash
HEARTBEAT_FILE="$SPEC_PATH/.ralph-heartbeat"
HEARTBEAT_ERR=$(mktemp)

# Always attempt write (authoritative check)
echo "heartbeat: $(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$HEARTBEAT_FILE" 2>"$HEARTBEAT_ERR"
WRITE_OK=$?

if [ $WRITE_OK -ne 0 ]; then
    # Read failure details for escalation
    ERR_MSG=$(cat "$HEARTBEAT_ERR")
    rm -f "$HEARTBEAT_ERR"
    echo "[ralph-specum] FILESYSTEM_ERROR: $ERR_MSG" >&2

    # Increment failure counter in state file
    # (coordinator reads this in stop-watcher to decide response tier)

    # Trip circuit breaker, escalate to human
fi

rm -f "$HEARTBEAT_FILE" "$HEARTBEAT_ERR"
```

The counter reset logic is handled by stop-watcher.sh: on successful write, reset `filesystemHealthFailures` to 0. On failure, increment. Response tier is determined by the counter value.

### 4.2 Error Detection Strategy

**Two-tier approach:**
1. **Stat pre-check** (fast filter): Read `/proc/mounts` on Linux for EROFS detection
2. **Actual write attempt** (authoritative): Catches ENOSPC, EACCES, EIO — the stat pre-check misses transient read-only conditions

### 4.3 Three-Tier Response

| Failure Count | Response |
|---------------|----------|
| 1st consecutive | **Warn** — log to `.progress.md`, continue (could be transient I/O glitch) |
| 2nd consecutive | **Escalate** — output block prompt with recovery instructions |
| 3rd+ consecutive | **Full block** — stop execution, require human action |

### 4.4 Placement

Insert into `stop-watcher.sh` after state file existence check (~line 46), before main logic. This catches failures before any work is done.

### 4.5 State Tracking

Three new fields in `.ralph-state.json`:

```json
{
  "filesystemHealthy": true,
  "filesystemHealthFailures": 0,
  "lastFilesystemCheck": "2026-04-26T18:30:00Z"
}
```

### 4.6 What NOT to Do

- No auto-recovery (Ralph reports and blocks, not fixes)
- No Docker-native health endpoints (Ralph runs in Claude Code, not as a service)
- No `O_TMPFILE` (keep POSIX-compatible)
- No `/tmp` checks (must check spec directory specifically)

---

## 5. Codebase Analysis

### 5.1 stop-watcher.sh (765 lines)

The stop-watcher is strictly read-only for state — never modifies `.ralph-state.json`. Current flow has 11 distinct steps:
1. Bootstrap (cwd, settings check)
2. Race condition safeguard (stat-based age check)
3. ALL_TASKS_COMPLETE detection (transcript parsing)
4. Phase 4 regression sweep
5. Phase 3 repair loop (VERIFICATION_FAIL/DEGRADED handling)
6. State validation (JSON integrity)
7. Global iteration check
8. Quick mode guard
9. Role boundaries / field validation
10. Execution completion cross-check
11. Loop continuation

### 5.2 Existing Safety Patterns

| Pattern | Status | Gap |
|---------|--------|-----|
| Global iteration limit (100) | ✅ Implemented | Covers runaway loops, not failures |
| Per-task max iterations (5) | ✅ Implemented | Per-task only, not across tasks |
| Repair loop (2 max) | ✅ Implemented | Only for verification failures |
| Role boundary validation | ✅ Implemented | Phase 1 (unknown agent identity) |
| Race condition mitigation | ✅ Implemented | stat checks, retry loops, flock |
| **Git checkpoint** | ❌ Absent | **Primary gap for this spec** |
| **Circuit breaker** | ❌ Absent | **Primary gap for this spec** |
| **JSONL metrics** | ❌ Absent | Only `.progress.md` logging exists |
| **Read-only detection** | ❌ Absent | No filesystem health check |
| **CI snapshot** | ❌ Absent | Conceptual rule exists (implement.md:263), no mechanical implementation |

### 5.3 Risk Note from epic.md

`stop-watcher.sh` at 765 lines with complex logic — recommendation is to **append new safety functions at end of file without modifying existing logic**. This spec follows that guidance.

### 5.4 State Field Audit

The schema defines 25+ fields. This spec adds:

| Field | Type | Placement | Notes |
|-------|------|-----------|-------|
| `checkpoint` | object | Nested | sha, timestamp, branch, message |
| `circuitBreaker` | object | Nested | state, consecutiveFailures, sessionStartTime, openedAt, trippedReason |
| `filesystemHealthy` | boolean | Flat | Health flag |
| `filesystemHealthFailures` | integer | Flat | Consecutive failure count |
| `lastFilesystemCheck` | string (ISO) | Flat | Last heartbeat check time |
| `ciCommands` | string array | Flat | Discovered CI commands from `.github/workflows/*.yml` and `tests/*.bats` |

**Namespace note**: Two nested objects (`checkpoint`, `circuitBreaker`) follow the existing pattern of grouping related fields (like `chat`, `parallelGroup`, `taskResults`). The four flat fields (`filesystemHealthy`, `filesystemHealthFailures`, `lastFilesystemCheck`, `ciCommands`) are kept flat for performance (fewer jq traversals in stop-watcher.sh's hot path). A future spec may consolidate these under a `safety` namespace if more safety fields accumulate.

`.metrics.jsonl` — new file, not a state field

---

## 6. Interface Contracts Summary

### 6.1 Files to Create

| File | Purpose |
|------|---------|
| `plugins/ralph-specum/hooks/scripts/checkpoint.sh` | Git checkpoint utilities (`checkpoint-create`, `checkpoint-rollback`) |
| `plugins/ralph-specum/hooks/scripts/write-metric.sh` | JSONL metrics append utility (`write_metric` function with flock) |
| `plugins/ralph-specum/references/loop-safety.md` | Safety rules reference: decision log, recovery procedures, configuration defaults |
| `specs/<name>/.metrics.jsonl` | Per-task metrics (created at execution start via `touch`) |

### 6.2 Files to Modify

| File | Change |
|------|--------|
| `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` | Append checkpoint verification, circuit breaker read-check, filesystem health check, CI drift detection |
| `plugins/ralph-specum/schemas/spec.schema.json` | Add `checkpoint` (object), `circuitBreaker` (object), `filesystemHealthy` (bool), `filesystemHealthFailures` (int), `lastFilesystemCheck` (string), `ciCommands` (string[]) |
| `plugins/ralph-specum/commands/implement.md` | Add pre-loop git checkpoint step, CI discovery, metrics initialization, circuit breaker state writes |

### 6.3 Non-Modifications

- `plugins/ralph-specum/agents/spec-executor.md` — metrics writing is coordinator responsibility, executor does not write metrics
- `plugins/ralph-specum/hooks/scripts/checkpoint.sh` — out of scope (created by this spec)
- `plugins/ralph-specum/references/coordinator-pattern.md` — add CI logic in implement.md instead of modifying coordinator

## 7. Implementation Order

The five safety mechanisms are **independent** — they can be implemented in any order, but the recommended sequence is:

1. **Git checkpoint** (foundation — needs schema change)
2. **Circuit breaker** (builds on state schema additions)
3. **Read-only detection** (simple, self-contained)
4. **Per-task metrics** (append-only, no dependencies)
5. **CI snapshot tracking** (depends on CI command discovery, schema additions)

Each mechanism should be independently testable before adding the next.

---

## Sources

- `.research-git-checkpoint.md` — Git checkpoint and rollback patterns
- `research-circuit-breaker.md` — Circuit breaker pattern comparison (Hystrix, resilience4j, Polly)
- `.research-metrics-and-ci.md` — JSONL metrics and CI command discovery
- `research-read-only-detection.md` — Heartbeat filesystem health patterns
- `.research-codebase.md` — Existing codebase patterns and safety gaps
