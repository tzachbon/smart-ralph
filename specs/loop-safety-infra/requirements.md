---
spec: loop-safety-infra
phase: requirements
created: 2026-04-26T19:00:00Z
---

# Requirements: Loop Safety Infrastructure

**Spec**: `loop-safety-infra` | **Epic**: `engine-roadmap-epic` (Spec 4)

## User Stories

### US-1: Git Checkpoint & Rollback

**As a** spec executor,
**I want** a pre-loop git checkpoint before execution starts,
**So that** I can rollback to a clean state if execution catastrophically fails.

**Acceptance Criteria:**
- AC-1.1: A git commit is created at execution start capturing all current changes with the message `checkpoint: before <spec-name> execution (task 0/<total>)`.
- AC-1.2: The commit SHA is stored in `.ralph-state.json` under `checkpoint.sha`.
- AC-1.3: The SHA is accompanied by `checkpoint.timestamp`, `checkpoint.branch`, and `checkpoint.message` in the state file (epic success criterion #9).
- AC-1.4: If no git repo exists, the state file records `sha: null` and execution proceeds without a checkpoint.
- AC-1.5: Rollback is an explicit user command (`/ralph-specum:rollback`) that runs `git reset --hard <SHA>`, restoring the working tree to the checkpoint state. This command must be defined as a new slash command in the plugin (e.g., `commands/rollback.md`).
- AC-1.7: If `checkpoint.sha` is `null` (no git repo, detached HEAD), the rollback command outputs an error explaining the checkpoint is unavailable.
- AC-1.6: If the git commit command fails during checkpoint creation (e.g., missing `user.name`/`user.email` config, disk full), execution is blocked — the safety net must exist before proceeding.

### US-2: Circuit Breaker

**As a** developer,
**I want** the execution loop to stop after repeated consecutive failures,
**So that** I don't waste tokens running doomed tasks indefinitely.

**Acceptance Criteria:**
- AC-2.1: The circuit breaker counts exact consecutive task failures (absolute consecutive count pattern).
- AC-2.2: The circuit defaults to CLOSED state with `consecutiveFailures: 0` at execution start.
- AC-2.3: When `consecutiveFailures` reaches `maxConsecutiveFailures` (default 5), the circuit transitions to OPEN and execution stops.
- AC-2.4: When the session wall-clock time exceeds `maxSessionSeconds` (default 172800 / 48 hours), the circuit trips to OPEN. Both timer and consecutive-failure checks run at the same checkpoint: after the repair loop for the current task completes, not mid-flight.
- AC-2.5: An OPEN circuit outputs a block prompt with reset instructions; only manual reset (human edits state file to `state: "closed"`) resumes execution.
- AC-2.6: The circuit breaker counter resets to 0 on any task pass.
- AC-2.7: State file corruption (missing file, malformed JSON, missing `circuitBreaker` field) defaults to CLOSED with 0 failures (graceful degradation).
- AC-2.8: Circuit breaker timeout (48h) has highest priority over all other loop safety checks.

### US-3: Per-Task Metrics

**As a** developer,
**I want** per-task metrics recorded as JSONL after each task completes,
**So that** I can analyze execution performance and debug issues.

**Acceptance Criteria:**
- AC-3.1: A `.metrics.jsonl` file exists in the spec directory (`specs/<name>/.metrics.jsonl`) after execution starts (epic success criterion #11).
- AC-3.2: Each completed task appends exactly one JSONL line containing: `eventId`, `spec`, `taskIndex`, `taskIteration`, `globalIteration`, `timestamp`, `taskTitle`, `taskType`, `taskId`, `startedAt`, `completedAt`, `wallTimeMs`, `verifyTimeMs`, `verifyExitCode`, `status`, `commit`, `retries`, `error`, `errorDetail`, `agent`, `toolsUsed`, `ciSnapshotBefore`, `ciSnapshotAfter`, `ciDrift`.
- AC-3.3: The metrics file is per-spec, not global — each spec directory has its own `.metrics.jsonl`.
- AC-3.4: Metrics writing uses `flock` for concurrency safety.
- AC-3.5: The coordinator in `implement.md` owns all metrics writes; the spec-executor agent never writes metrics directly.
- AC-3.6: The `.metrics.jsonl` file persists after execution completion, cancellation, and rollback.
- AC-3.7: The schema uses `schemaVersion: 1` for forward compatibility.
- AC-3.8: A `write-metric.sh` helper script provides the `write_metric` function with flock-protected append.

### US-4: Read-Only Filesystem Detection

**As a** developer,
**I want** the loop to detect read-only filesystems at startup,
**So that** I don't silently fail to write progress or state files.

**Acceptance Criteria:**
- AC-4.1: A heartbeat write check runs on every loop iteration, including the first (not conditional on prior failures).
- AC-4.2: The heartbeat writes a small `.ralph-heartbeat` file to the spec directory, then verifies round-trip by reading it back.
- AC-4.3: Total heartbeat check cost is under 10ms per invocation.
- AC-4.4: Three-tier response based on consecutive failure count:
  - 1st consecutive: **Warn** — log to `.progress.md`, continue (transient I/O glitch).
  - 2nd consecutive: **Escalate** — output block prompt with recovery instructions.
  - 3rd+ consecutive: **Full block** — stop execution, require human action.
- AC-4.5: Two-tier error detection: stat pre-check on `/proc/mounts` (EROFS detection) + authoritative write attempt (catches ENOSPC, EACCES, EIO).
- AC-4.6: Three new state fields track health: `filesystemHealthy` (boolean), `filesystemHealthFailures` (integer), `lastFilesystemCheck` (ISO timestamp).
- AC-4.7: No automatic recovery — Ralph reports and blocks, does not fix the filesystem.

### US-5: CI Snapshot Tracking

**As a** developer,
**I want** the loop to auto-detect CI commands and record CI state snapshots,
**So that** I can detect CI drift caused by execution changes.

**Acceptance Criteria:**
- AC-5.1: At spec initialization, the loop discovers CI commands by scanning `.github/workflows/*.yml` and `tests/*.bats`.
- AC-5.2: Discovered CI commands are stored in the state file under `ciCommands` (string array).
- AC-5.3: A `ciSnapshotBefore` is captured at state init (pre-execution baseline).
- AC-5.4: A `ciSnapshotAfter` is captured post-task or at spec completion.
- AC-5.5: CI drift is detected as a difference between the two snapshots (passed at snapshot but fails now).
- AC-5.6: For plugin repos with no `package.json`, per-task selective CI is skipped; full CI runs only at spec completion. In this case, `ciSnapshotBefore`/`ciSnapshotAfter`/`ciDrift` are set to `null` for all per-task metric entries, with a single CI capture at spec completion.
- AC-5.7: CI discovery runs once at state init, not per-loop iteration.

---

## Functional Requirements

### FR-001: Pre-loop git checkpoint creation

**Priority**: HIGH
**Maps to**: US-1

At execution start (transition from `tasks` phase to `execution` phase in `implement.md` Step 3), the coordinator runs `git add -A && git commit --no-verify` with the message `checkpoint: before <spec-name> execution (task 0/<total>)`. The `--no-verify` flag skips pre-commit hook validation to prevent linter failures from blocking checkpoint creation. **Important**: `--no-verify` does NOT prevent all git errors (e.g., missing `user.name`/`user.email` config, disk full errors). The resulting commit SHA is parsed from the output and stored in `.ralph-state.json` under `checkpoint.sha`, with `checkpoint.timestamp`, `checkpoint.branch`, and `checkpoint.message` populated.

If the git repo does not exist, the SHA is recorded as `null` and execution proceeds. If the repo is in a detached HEAD state, a warning is logged and execution proceeds with `sha: null`. If uncommitted changes exist at checkpoint time, they are included in the checkpoint with a warning logged to `.progress.md`. **Note on `--no-verify`**: This flag skips pre-commit hook validation, but other git errors (e.g., missing `user.name`/`user.email` config, disk full) can still block the commit. Such errors block execution because the safety net must exist before proceeding.

**State fields added**: `checkpoint.sha`, `checkpoint.timestamp`, `checkpoint.branch`, `checkpoint.message`
**Schema change**: Add `checkpoint` object definition to `spec.schema.json`
**New files**: `hooks/scripts/checkpoint.sh` (functions: `checkpoint-create`, `checkpoint-rollback`)
**Modified files**: `commands/implement.md` (add checkpoint step), `schemas/spec.schema.json` (add checkpoint definition)

### FR-002: Git checkpoint rollback

**Priority**: HIGH
**Maps to**: US-1

When invoked via `/ralph-specum:rollback`, the coordinator reads the checkpoint SHA from `.ralph-state.json` and executes `git reset --hard <SHA>`. This restores the working tree to the exact state at checkpoint creation time. The checkpoint commit is preserved in git history for audit trail.

Rollback is an **explicit user command** — it is not automatic. The engine catches the problem; the human decides the remedy. After rollback, the checkpoint commit remains in history, allowing `git diff <checkpoint-sha> HEAD` for diff visibility before re-execution.

**State fields read**: `checkpoint.sha`
**New files**: `hooks/scripts/checkpoint.sh` (`checkpoint-rollback` function)
**Modified files**: `commands/implement.md` (rollback command handler)

### FR-003: Circuit breaker state machine

**Priority**: HIGH
**Maps to**: US-2

The circuit breaker implements a three-state machine: CLOSED (normal), OPEN (tripped), manual RESET to CLOSED. HALF_OPEN is not implemented because the spec-executor is a deterministic agent — if it was stuck, it will be stuck again.

The coordinator in `implement.md` owns ALL writes to `circuitBreaker` state:
- Execution start: initialize `{state: "closed", consecutiveFailures: 0, sessionStartTime: <epoch-seconds-integer>}`
- Task completes (pass): reset `consecutiveFailures` to 0
- Task completes (fail): increment `consecutiveFailures` by 1
- Circuit trips: set `state` to `"open"`, record `openedAt` and `trippedReason`
- Manual reset: human directly edits state file to `{state: "closed", consecutiveFailures: 0}`

`stop-watcher.sh` ONLY reads `circuitBreaker.state`, `circuitBreaker.consecutiveFailures`, `circuitBreaker.sessionStartTime`, and `maxSessionSeconds`. It never writes. This eliminates double-increment bugs. The 48h timer computation (`now - sessionStartTime >= maxSessionSeconds`) requires reading `sessionStartTime` from the state.

**Trip conditions**:
- `maxConsecutiveFailures` (default 5): triggered when `consecutiveFailures >= maxConsecutiveFailures`
- `maxSessionSeconds` (default 172800 / 48h): triggered when `now - sessionStartTime >= maxSessionSeconds`

**Precedence**: Circuit breaker timeout (48h) has highest priority. Consecutive failure check runs after the repair loop for the current task. Repair loop exhaustion only affects the current task.

**State fields added**: `circuitBreaker.state`, `circuitBreaker.consecutiveFailures`, `circuitBreaker.sessionStartTime`, `circuitBreaker.openedAt`, `circuitBreaker.trippedReason`
**Schema change**: Add `circuitBreaker` object definition to `spec.schema.json`
**Modified files**: `hooks/scripts/stop-watcher.sh` (append circuit breaker read-check), `commands/implement.md` (coordinator writes circuit breaker state)

### FR-004: Metrics file initialization and lifecycle

**Priority**: HIGH
**Maps to**: US-3

At execution start (in `implement.md` Step 3), the coordinator creates an empty `.metrics.jsonl` file in the spec directory via `touch "$SPEC_PATH/.metrics.jsonl"`. The file is per-spec, stored at `specs/<name>/.metrics.jsonl`.

The file persists after execution completion, cancellation, and rollback. It is never deleted or cleaned up during the spec lifecycle.

**State fields**: None (file-based, not state-file-based)
**New files**: `specs/<name>/.metrics.jsonl` (created at execution start), `hooks/scripts/write-metric.sh`
**Modified files**: `commands/implement.md` (add metrics file initialization)

### FR-005: Per-task metrics recording

**Priority**: HIGH
**Maps to**: US-3

After each task completes (in the coordinator's post-task step in `implement.md` Step 5), the coordinator calls `write-metric.sh` with: `spec_path`, `status`, `task_index`, `task_iteration`, `verify_exit_code`, `task_title`, `task_type`, `task_id`, `commit_sha`.

The `write_metric` function in `write-metric.sh` acquires an `flock`, appends one JSONL line to `$SPEC_PATH/.metrics.jsonl`, and releases the lock. Each line contains the full metrics schema defined in research.md section 3.2 (eventId, spec, taskIndex, taskIteration, globalIteration, timestamp, taskTitle, taskType, taskId, startedAt, completedAt, wallTimeMs, verifyExitCode, status, commit, retries, error, errorDetail, agent, toolsUsed, ciSnapshotBefore, ciSnapshotAfter, ciDrift).

The schema includes `schemaVersion: 1` for forward compatibility. Error fields (`error`, `errorDetail`) are null when status is "pass". Future schema versions should handle migration by checking `schemaVersion` and transforming existing entries if needed. The full metrics schema field list is defined in AC-3.2 above.

**State fields**: None (file-based)
**New files**: `hooks/scripts/write-metric.sh` (function: `write_metric`)
**Modified files**: `commands/implement.md` (coordinator calls write-metric.sh after each task)

### FR-006: Heartbeat write check

**Priority**: HIGH
**Maps to**: US-4

At the start of each loop iteration (in `stop-watcher.sh`, after state file existence check ~line 46), the filesystem health check writes a `.ralph-heartbeat` file to the spec directory, attempts to read it back, and verifies the content matches.

The check ALWAYS runs (not conditional on prior failures). This is critical: a conditional check that only runs after failures were previously detected will skip the first iteration, which is the most important check.

Error detection uses two tiers:
1. Stat pre-check: read `/proc/mounts` on Linux for EROFS detection (fast filter)
2. Actual write attempt: catches ENOSPC, EACCES, EIO (authoritative)

The heartbeat check costs under 10ms per invocation.

**State fields added**: `filesystemHealthy` (boolean), `filesystemHealthFailures` (integer), `lastFilesystemCheck` (ISO timestamp string). These are **flat fields** at the root level of the state schema (not nested) for performance — fewer jq traversals in stop-watcher.sh's hot path. This contrasts with `checkpoint` and `circuitBreaker` which are nested objects grouping related sub-fields.

**Schema change**: Add flat fields to `spec.schema.json`
**Modified files**: `hooks/scripts/stop-watcher.sh` (append filesystem health check function)

### FR-007: Three-tier filesystem health response

**Priority**: MEDIUM
**Maps to**: US-4

Based on `filesystemHealthFailures` consecutive failure count:
- **1st consecutive failure**: Write a warning to `.progress.md`, continue execution. This handles transient I/O glitches.
- **2nd consecutive failure**: Output a block prompt with filesystem recovery instructions. Require human acknowledgment before continuing.
- **3rd+ consecutive failure**: Stop execution entirely. No automatic recovery. The human must fix the filesystem and manually set `filesystemHealthy: true` and `filesystemHealthFailures: 0` in the state file (same pattern as circuit breaker manual reset: human edits state file fields to restore safety).

On successful heartbeat write, `filesystemHealthFailures` is reset to 0.

**State fields used**: `filesystemHealthFailures`, `filesystemHealthy`, `lastFilesystemCheck`
**Modified files**: `hooks/scripts/stop-watcher.sh` (append three-tier response logic)

### FR-008: CI command discovery

**Priority**: MEDIUM
**Maps to**: US-5

At spec initialization (in `implement.md` Step 3), scan these files to discover CI commands:
- `.github/workflows/*.yml` — extract CI pipeline step commands
- `tests/*.bats` — extract BATS test commands

Commands are classified into categories by grepping for keywords in the command text. Categories: `test` (contains "test", "bats"), `lint` (contains "lint", "eslint"), `build` (contains "build", "compile"), `typecheck` (contains "typecheck", "tsc"). The discovered commands are stored in the state file under `ciCommands` (string array).

This discovery runs **once at state init**, not per-loop iteration. For plugin repos with no `package.json`, the discovery focuses on `.github/workflows/*.yml` and `tests/*.bats` only (no `Makefile`, no `Jenkinsfile`, no `package.json`).

**State fields added**: `ciCommands` (string array, flat field)
**Schema change**: Add `ciCommands` to `spec.schema.json`
**Modified files**: `commands/implement.md` (add CI discovery in Step 3)

### FR-009: CI snapshot capture and drift detection

**Priority**: MEDIUM
**Maps to**: US-5

Two-entry CI snapshot model:
- `ciSnapshotBefore`: captured at state init (pre-execution baseline). Records which CI commands were passing.
- `ciSnapshotAfter`: captured post-task or at spec completion. Records current CI state.

Drift is detected as commands that passed at snapshot but fail now. For plugin repos with no `package.json` and no substantial test suite, per-task selective CI is skipped. Full CI runs only at spec completion.

The metrics entry for each task includes `ciSnapshotBefore`, `ciSnapshotAfter`, and `ciDrift` (boolean) fields.

**State fields used**: `ciCommands`, `ciSnapshotBefore` (per metric entry), `ciSnapshotAfter` (per metric entry), `ciDrift` (per metric entry)
**New files**: None (uses existing metrics infrastructure from FR-005)
**Modified files**: `hooks/scripts/write-metric.sh` (add CI snapshot fields to metrics output)

---

## Non-Functional Requirements

### NFR-001: Append-only to stop-watcher.sh

**Category**: Safety

The following safety mechanisms that live in `stop-watcher.sh` must be implemented as **append-only additions** to the end of `stop-watcher.sh` (765 lines). No existing logic may be modified, reordered, or refactored. New safety functions are defined as bash functions at the end of the file, called from the loop continuation step. Additionally, all new script files (`checkpoint.sh`, `write-metric.sh`) are new creations (not modifications to existing files).

Mechanisms in `stop-watcher.sh`: circuit breaker read-check, filesystem health check, CI drift detection.
Mechanisms in `implement.md`: git checkpoint, metrics initialization/recording, CI discovery, circuit breaker state writes.

This is the highest-priority non-functional requirement. The existing `stop-watcher.sh` has complex interdependent logic (11 distinct steps) and any modification risks breaking the entire execution loop.

**Verification**: Diff of `stop-watcher.sh` shows only additions at end of file. No line deletions or modifications to lines before the appended safety functions.

### NFR-002: Performance — heartbeat under 10ms

**Category**: Performance

The filesystem heartbeat check (FR-006) must complete in under 10ms per invocation. This check runs on every loop iteration, so excessive overhead would slow down the entire execution loop.

**Verification**: Benchmark the heartbeat write+read cycle; measure with `time` command. If overhead exceeds 10ms, investigate filesystem-specific issues.

### NFR-003: Safety — rollback preserves checkpoint commit

**Category**: Safety

The git rollback (FR-002) uses `git reset --hard` which restores the working tree but **preserves the checkpoint commit in git history**. This ensures an audit trail exists for forensic investigation.

**Verification**: After rollback, `git log` shows the checkpoint commit. `git diff <checkpoint-sha> HEAD` shows what changed since checkpoint.

### NFR-004: Safety — circuit breaker has no automatic reset

**Category**: Safety

The circuit breaker (FR-003) never automatically resets from OPEN to CLOSED. Only manual intervention (human edits state file) can resume execution. This prevents the circuit from silently re-closing and allowing a fundamentally broken task sequence to continue.

**Verification**: After circuit trips to OPEN, the only way to resume is editing `.ralph-state.json.circuitBreaker.state` to `"closed"`.

### NFR-005: Metrics — JSONL append-safety

**Category**: Reliability

The metrics file (FR-005) uses `flock` for file-level locking, matching the concurrency model of the existing `chat.md` lock in the codebase. Each JSONL line is a self-contained document, so a crash mid-write corrupts only one line, not the entire file.

**Verification**: The `write_metric` function uses `flock` on a lock file. Running concurrent metrics writes (if any) should not produce interleaved or truncated JSONL lines.

### NFR-006: Schema — additive only

**Category**: Compatibility

All schema changes (FR-001 through FR-009) are additive — no existing fields are removed or have their types changed. This ensures backward compatibility with existing specs and state files.

**Verification**: `spec.schema.json` diff shows only additions to the `properties` object and `required` arrays. No existing field definitions are modified.

---

## Glossary

| Term | Definition |
|------|-----------|
| **Circuit breaker** | A fault-tolerance pattern that stops execution after a configurable number of consecutive failures or a time limit. Three states: CLOSED (normal), OPEN (tripped), manual RESET. |
| **Heartbeat** | A small file written to verify filesystem write capability. Used for read-only filesystem detection. |
| **JSONL** | JSON Lines — one JSON object per line, append-safe, stream-processable. |
| **`flock`** | Linux file-locking utility used for concurrent access safety. |
| **`git reset --hard`** | Git command that restores the working tree to a specific commit, discarding all changes since that commit. |
| **`--no-verify`** | Git flag that skips pre-commit hooks during commit. Used for checkpoint creation to avoid blocking on linter failures. Note: does NOT prevent all git errors (e.g., missing user config, disk full). |
| **Coordinator** | The logic in `implement.md` that orchestrates task execution, writes state, and manages safety mechanisms. |
| **stop-watcher** | The `hooks/scripts/stop-watcher.sh` script that runs on every loop iteration to check for loop-continuation conditions. |
| **spec-executor** | The agent that implements individual tasks. Does NOT write metrics or state directly; delegates to coordinator. |

---

## Out of Scope

| Item | Reason |
|------|--------|
| Per-task git checkpoints | Too granular; pre-loop checkpoint covers the critical path. A future spec may add per-task checkpoints if needed. |
| Automatic circuit breaker reset | Deliberate design decision — automatic reset could mask fundamental problems. See NFR-004. |
| Automatic filesystem recovery | Ralph reports and blocks, not fixes. See FR-007 and NFR-003. |
| Docker-native health endpoints | Ralph runs in Claude Code, not as a Docker service. See research section 4.6. |
| O_TMPFILE for atomic writes | POSIX compatibility; keep it simple. See research section 4.6. |
| /tmp filesystem checks | Must check spec directory specifically, not arbitrary temp locations. |
| Epic-level circuit breaker | Circuit breaker is per-spec, not per-epic. Each spec has its own state file. |
| Cross-spec metrics aggregation | Each spec has its own `.metrics.jsonl`. No aggregation or cross-spec analysis. |
| Full CI pipeline implementation | Only discovery and snapshot tracking; the CI workflows themselves are not created or modified. |
| Selective post-task CI for plugin repos | For plugin repos with no `package.json`, per-task selective CI is skipped. Full CI at spec completion only. |
| `/proc/mounts` stat pre-check on non-Linux | Stat pre-check is Linux-specific. On non-Linux systems, only the authoritative write attempt is used. |

---

## Dependencies

| Dependency | Status | Impact |
|------------|--------|--------|
| Spec 1 (schema fields: `nativeTaskMap`, `nativeSyncEnabled`, `nativeSyncFailureCount`) | Required | This spec adds `ciCommands` to the same schema modified by Spec 1. Schema must include these fields before this spec's schema changes are applied. |
| Spec 3 (`references/role-contracts.md`) | Required | This spec modifies agent files via the implement.md coordinator; role contracts must exist before any agent file modifications in the epic chain. |

**Note**: The five safety mechanisms are **independent** of each other. They can be implemented in any order during execution, but the recommended sequence from research.md is: (1) git checkpoint, (2) circuit breaker, (3) read-only detection, (4) per-task metrics, (5) CI snapshot tracking.

**Schema merge plan**: This spec and Spec 1 both modify `spec.schema.json`. The merge plan is: Spec 1 adds `nativeTaskMap`, `nativeSyncEnabled`, `nativeSyncFailureCount`. This spec adds `checkpoint`, `circuitBreaker`, `filesystemHealthy`, `filesystemHealthFailures`, `lastFilesystemCheck`, `ciCommands`. Since they target different sections of the schema (Spec 1 adds task-related fields, this spec adds safety fields), conflicts are unlikely. If the schema uses a flat `properties` object, the combined changes are simply the union of both sets of additions.

---

## Verification Contract

**Project type**: cli
**Entry points**: `/ralph-specum:implement` (execution entry point); `/ralph-specum:rollback` (rollback command)
**No UI**: All verification is via CLI and file inspection.

| Verification Target | How to Verify |
|---------------------|---------------|
| FR-001/002: Checkpoint exists and rollback works | After running a spec, check `.ralph-state.json.checkpoint.sha` is a valid git SHA. Run `/ralph-specum:rollback` and verify working tree is restored. Edge cases: test `sha: null` when no git repo, test warning on detached HEAD. |
| FR-003: Circuit breaker trips | Create a spec with failing tasks; verify execution stops after 5 consecutive failures. Check `.ralph-state.json.circuitBreaker.state` is `"open"`. Test state corruption (missing file, malformed JSON) defaults to CLOSED. |
| FR-004/005: Metrics file with per-task entries | After execution, inspect `specs/<name>/.metrics.jsonl` — should have one JSONL line per task with all required fields. Each line must parse as valid JSON. Verify concurrent writes (two specs running simultaneously) produce no interleaved/truncated lines. |
| FR-006/007: Read-only detection | Test read-only detection by running the loop with a spec directory that has restricted permissions (e.g., `chmod 000` on a subdirectory). Verify first failure logs warning, second escalates, third blocks. |
| FR-008/009: CI snapshot | After execution, parse JSONL entries in `.metrics.jsonl` for `ciSnapshotBefore`, `ciSnapshotAfter`, and `ciDrift` fields. |
| NFR-001: Append-only to stop-watcher.sh | Diff `stop-watcher.sh` — only additions at end of file, no existing line modifications. |
| NFR-002: Performance | Run `time` on the heartbeat function across 100 iterations; average must be < 10ms. |
| NFR-003: Safety — rollback preserves checkpoint commit | After rollback, `git log` shows the checkpoint commit. `git diff <checkpoint-sha> HEAD` shows what changed since checkpoint. |
| NFR-004: Safety — circuit breaker has no automatic reset | After circuit trips to OPEN, verify no automatic path exists to reset (no timer-based or success-based auto-reset). The only resume path is manual state edit. |
| NFR-005: Metrics — JSONL append-safety | Run `write_metric` concurrently from two specs; verify no interleaved/truncated JSONL lines. |
| NFR-006: Schema additive only | Diff `spec.schema.json` — only additions, no existing field changes. |

**Epic success criteria references**:
- Criterion #9 (Rollback available): Verified by FR-001/002 acceptance criteria AC-1.1 through AC-1.6.
- Criterion #10 (Circuit breaker stops runaway loops): Verified by FR-003 acceptance criteria AC-2.1 through AC-2.9.
- Criterion #11 (Metrics visible): Verified by FR-004/005 acceptance criteria AC-3.1 through AC-3.8.
