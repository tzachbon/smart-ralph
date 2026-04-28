---
spec: loop-safety-infra
phase: design
created: 2026-04-26T20:00:00Z
---

# Design: Loop Safety Infrastructure

**Spec**: `loop-safety-infra` | **Epic**: `engine-roadmap-epic` (Spec 4)

## 1. Overview

This design adds five Bmalph-style safety mechanisms to the Smart Ralph execution loop: a pre-loop git checkpoint with rollback, a circuit breaker for consecutive task failures, per-task JSONL metrics, a read-only filesystem heartbeat, and CI snapshot tracking. All mechanisms integrate as **append-only additions** to the existing `stop-watcher.sh` (765 lines) and `implement.md` (314 lines), preserving all existing logic.

## 2. Architecture

The five safety mechanisms operate at different points in the execution lifecycle, with clear separation between coordinator-written state and hook-read-only checks:

```mermaid
sequenceDiagram
    participant I as implement.md (coordinator)
    participant S as stop-watcher.sh
    participant G as git
    participant F as filesystem
    participant M as .metrics.jsonl

    Note over I,M: Phase: execution starts (implement.md Step 3)
    I->>G: git add -A && git commit --no-verify
    G-->>I: checkpoint SHA
    I->>I: write checkpoint.sha to .ralph-state.json
    I->>I: initialize circuitBreaker (closed, 0 failures)
    I->>I: discover CI commands from workflows/*.yml, tests/*.bats
    I->>F: touch specs/<name>/.metrics.jsonl

    loop per loop iteration (stop-watcher.sh)
        S->>F: write .ralph-heartbeat (heartbeat check)
        F-->>S: success or error

        alt heartbeat error
            S->>S: increment filesystemHealthFailures
            S->>S: three-tier response (warn/escalate/block)
        end

        S->>S: read circuitBreaker.state & consecutiveFailures

        alt consecutiveFailures >= 5 OR session > 48h
            S->>S: output block decision, exit 0
        end
    end

    Note over I,M: Post-task completion (implement.md Step 5)
    I->>M: write_metric.sh flock-append JSONL line
    I->>I: reset circuitBreaker.consecutiveFailures on pass
    I->>I: increment circuitBreaker.consecutiveFailures on fail
    I->>I: if consecutiveFailures >= max, set state to "open"
    end
```

### Key Architectural Decisions

- **Single writer for circuit breaker**: The coordinator in `implement.md` owns ALL writes to `circuitBreaker` state. `stop-watcher.sh` only reads.
- **Append-only to stop-watcher.sh**: All new safety logic appended at end of the 765-line file, defined as bash functions, called from the loop continuation step.
- **Per-spec isolation**: Each spec has its own `.metrics.jsonl`, `.ralph-state.json`, and circuit breaker state.
- **Human-in-the-loop for resets**: Circuit breaker and filesystem block require manual state edits to resume.

## 3. Component Design

### 3.1 Git Checkpoint (`checkpoint.sh`)

**File**: `plugins/ralph-specum/hooks/scripts/checkpoint.sh`

Two functions:

#### `checkpoint-create`

Creates a git commit capturing all current changes before execution starts.

```bash
checkpoint-create() {
    local spec_name="$1" total_tasks="$2" output_file="$3"

    # Check if already created (idempotency)
    if [ -n "$output_file" ] && [ -f "$output_file" ]; then
        local existing_sha
        existing_sha=$(jq -r '.checkpoint.sha // empty' "$output_file" 2>/dev/null || true)
        if [ -n "$existing_sha" ] && [ "$existing_sha" != "null" ]; then
            echo "[ralph-specum] CHECKPOINT_EXISTS sha=$existing_sha, skipping" >&2
            return 0
        fi
    fi

    # Check if this is a git repo
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "[ralph-specum] CHECKPOINT_NO_REPO no git repository found, sha=null" >&2
        if [ -n "$output_file" ]; then
            jq '.checkpoint = {sha: null, timestamp: null, branch: null, message: null}' "$output_file" > "${output_file}.tmp" && mv "${output_file}.tmp" "$output_file"
        fi
        return 0
    fi

    # Check for detached HEAD
    local head_detached
    head_detached=$(git symbolic-ref --short HEAD 2>/dev/null || true)
    if [ -z "$head_detached" ]; then
        echo "[ralph-specum] CHECKPOINT_WARNING detached HEAD state, sha=null" >&2
        if [ -n "$output_file" ]; then
            jq '.checkpoint = {sha: null, timestamp: null, branch: null, message: null}' "$output_file" > "${output_file}.tmp" && mv "${output_file}.tmp" "$output_file"
        fi
        return 0
    fi

    # Log uncommitted changes warning (they will be included in checkpoint)
    local uncommitted
    uncommitted=$(git status --porcelain 2>/dev/null)
    if [ -n "$uncommitted" ]; then
        echo "[ralph-specum] CHECKPOINT_WARNING uncommitted changes included in checkpoint" >&2
    fi

    # Create the checkpoint commit
    local checkpoint_msg="checkpoint: before $spec_name execution (task 0/$total_tasks)"
    local sha
    if ! git add -A; then
        echo "[ralph-specum] CHECKPOINT_FAILURE git add failed." >&2
        return 1
    fi
    if ! git commit --no-verify -m "$checkpoint_msg" 2>&1; then
        echo "[ralph-specum] CHECKPOINT_FAILURE git commit failed. Execution blocked until safety net exists." >&2
        echo "[ralph-specum] Check git config (user.name, user.email) and disk space." >&2
        return 1
    fi
    sha=$(git log -1 --format=%H 2>/dev/null)

    if [ -z "$sha" ]; then
        # Checkpoint commit failed - block execution
        echo "[ralph-specum] CHECKPOINT_FAILURE git commit failed. Execution blocked until safety net exists." >&2
        echo "[ralph-specum] Check git config (user.name, user.email) and disk space." >&2
        return 1
    fi

    # Short SHA (7 chars)
    local short_sha
    short_sha=$(git rev-parse --short=7 "$sha")

    # Store in state file
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    if [ -n "$output_file" ]; then
        jq --arg sha "$short_sha" \
           --arg ts "$timestamp" \
           --arg branch "$head_detached" \
           --arg msg "$checkpoint_msg" \
           '.checkpoint = {sha: $sha, timestamp: $ts, branch: $branch, message: $msg}' \
           "$output_file" > "${output_file}.tmp" && mv "${output_file}.tmp" "$output_file"
    fi

    echo "[ralph-specum] CHECKPOINT sha=$short_sha branch=$head_detached" >&2
    return 0
}
```

**Error handling**:
- No git repo: `sha: null`, execution proceeds.
- Detached HEAD: warning logged, `sha: null`, execution proceeds.
- Uncommitted changes: included with warning.
- Git commit failure (missing user config, disk full): **block execution**, return 1.

#### `checkpoint-rollback`

Rolls back the working tree to the checkpoint SHA.

```bash
checkpoint-rollback() {
    local state_file="$1"

    if [ ! -f "$state_file" ]; then
        echo "[ralph-specum] ROLLBACK_ERROR state file not found: $state_file" >&2
        return 1
    fi

    local sha
    sha=$(jq -r '.checkpoint.sha // empty' "$state_file" 2>/dev/null || true)

    if [ -z "$sha" ] || [ "$sha" = "null" ]; then
        echo "[ralph-specum] ROLLBACK_ERROR checkpoint.sha is null — no checkpoint available for rollback" >&2
        return 1
    fi

    echo "[ralph-specum] ROLLBACK restoring to sha=$sha" >&2

    # Verify the SHA exists (cat-file checks if the object exists, works with short SHAs)
    if ! git cat-file -e "$sha" 2>/dev/null; then
        echo "[ralph-specum] ROLLBACK_ERROR sha=$sha not found in git history" >&2
        return 1
    fi

    git reset --hard "$sha"
    echo "[ralph-specum] ROLLBACK_COMPLETE sha=$sha" >&2
    return 0
}
```

**Integration with `implement.md`**: A new rollback command (`commands/rollback.md`) calls `checkpoint-rollback` with the state file path. The coordinator in `implement.md` calls `checkpoint-create` in Step 3 after state initialization.

### 3.2 Circuit Breaker

#### State Machine

```
CLOSED (normal) ──consecutiveFailures >= 5──> OPEN (tripped)
CLOSED (normal) ──session > 48h─────────────> OPEN (tripped)
CLOSED (normal) ──task pass─────────────────> CLOSED (reset to 0)
OPEN (tripped)  ──manual reset──────────────> CLOSED (human edits state)
```

HALF_OPEN is not implemented: the spec-executor is a deterministic agent; if stuck, it will be stuck again.

#### State Storage

Inline in `.ralph-state.json` under `circuitBreaker`:

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

#### State Write Ownership (Single Writer)

| Event | Writer | Action |
|-------|--------|--------|
| Execution start | Coordinator (Step 3) | Initialize `{state: "closed", consecutiveFailures: 0, sessionStartTime: <epoch>}` |
| Task completes (pass) | Coordinator (post-task) | Reset `consecutiveFailures` to 0 |
| Task completes (fail) | Coordinator (post-task) | Increment `consecutiveFailures` by 1 |
| Circuit trips | Coordinator | Set `state` to `"open"`, record `openedAt` and `trippedReason` |
| Manual reset | Human (direct JSON edit) | Set `state` to `"closed"`, reset `consecutiveFailures` to 0 |

**stop-watcher.sh role**: ONLY READS `circuitBreaker.state` and `circuitBreaker.consecutiveFailures` to check trip conditions. Never writes to the `circuitBreaker` object.

**Note on state file writes**: stop-watcher.sh writes to `filesystemHealthy`, `filesystemHealthFailures`, and `lastFilesystemCheck` fields (Section 3.4). These are explicitly exempted from the single-writer rule because only stop-watcher detects filesystem failures. The `circuitBreaker` and `checkpoint` objects remain write-only from the coordinator.

#### Implementation: stop-watcher.sh (Appended Function)

```bash
# --- Circuit Breaker Check (Spec 4: loop-safety-infra) ---
# Reads circuitBreaker state; does NOT write. Trips if:
#   - consecutiveFailures >= maxConsecutiveFailures (default 5)
#   - session time >= maxSessionSeconds (default 172800 / 48h)
check_circuit_breaker() {
    local state_file="$1"
    local spec_name="$2"

    # Graceful degradation: missing circuitBreaker field defaults to closed
    local cb_state
    cb_state=$(jq -r '.circuitBreaker.state // "closed"' "$state_file" 2>/dev/null || echo "closed")

    # If already open, stop immediately
    if [ "$cb_state" = "open" ]; then
        local tripped_reason
        tripped_reason=$(jq -r '.circuitBreaker.trippedReason // "unknown"' "$state_file" 2>/dev/null || echo "unknown")
        local opened_at
        opened_at=$(jq -r '.circuitBreaker.openedAt // "unknown"' "$state_file" 2>/dev/null || echo "unknown")
        CB_REASON=$(cat <<CB_OPEN_EOF
[ralph-specum] CIRCUIT_BREAKER OPEN — $spec_name

Circuit breaker tripped at $opened_at. Reason: $tripped_reason

## Reset instructions
1. Edit .ralph-state.json:
   - Set circuitBreaker.state to "closed"
   - Set circuitBreaker.consecutiveFailures to 0
2. Resume with /ralph-specum:implement
CB_OPEN_EOF
)
        jq -n \
          --arg reason "$CB_REASON" \
          --arg msg "Ralph-specum circuit breaker OPEN — manual reset required" \
          '{
            "decision": "block",
            "reason": $reason,
            "systemMessage": $msg
          }'
        exit 0
    fi

    # Read counters
    local consecutive_failures
    consecutive_failures=$(jq -r '.circuitBreaker.consecutiveFailures // 0' "$state_file" 2>/dev/null || echo "0")
    local session_start_time
    session_start_time=$(jq -r '.circuitBreaker.sessionStartTime // 0' "$state_file" 2>/dev/null || echo "0")
    local max_consecutive
    max_consecutive=$(jq -r '.circuitBreaker.maxConsecutiveFailures // 5' "$state_file" 2>/dev/null || echo "5")
    local max_session
    max_session=$(jq -r '.circuitBreaker.maxSessionSeconds // 172800' "$state_file" 2>/dev/null || echo "172800")

    local now
    now=$(date +%s)

    # Check 1: consecutive failure threshold
    if [ "$consecutive_failures" -ge "$max_consecutive" ] 2>/dev/null; then
        local cb_msg
        cb_msg=$(cat <<CB_FAILURE_EOF
[ralph-specum] CIRCUIT_BREAKER TRIPPED — consecutive failures ($consecutive_failures/$max_consecutive)

## Reset instructions
1. Edit .ralph-state.json: set circuitBreaker.state to "closed"
2. Set circuitBreaker.consecutiveFailures to 0
3. Resume with /ralph-specum:implement
CB_FAILURE_EOF
)
        jq -n \
          --arg reason "$cb_msg" \
          --arg msg "Ralph-specum circuit breaker: $consecutive_failures consecutive failures" \
          '{
            "decision": "block",
            "reason": $reason,
            "systemMessage": $msg
          }'
        exit 0
    fi

    # Check 2: session time threshold (highest priority)
    if [ "$session_start_time" -gt 0 ] 2>/dev/null; then
        local session_seconds=$((now - session_start_time))
        if [ "$session_seconds" -ge "$max_session" ]; then
            local hours=$((session_seconds / 3600))
            local cb_timeout_msg
            cb_timeout_msg=$(cat <<CB_TIMEOUT_EOF
[ralph-specum] CIRCUIT_BREAKER TRIPPED — session timeout (${hours}h elapsed, ${max_session}s limit)

Session started at sessionStartTime=$session_start_time. Elapsed: ${hours}h.

## Reset instructions
1. Edit .ralph-state.json: set circuitBreaker.state to "closed"
2. Set circuitBreaker.consecutiveFailures to 0
3. Optionally reset sessionStartTime to current epoch
4. Resume with /ralph-specum:implement
CB_TIMEOUT_EOF
)
            jq -n \
              --arg reason "$cb_timeout_msg" \
              --arg msg "Ralph-specum circuit breaker: session timeout (${hours}h)" \
              '{
                "decision": "block",
                "reason": $reason,
                "systemMessage": $msg
              }'
            exit 0
        fi
    fi
}
# --- End Circuit Breaker Check ---
```

**Placement**: Appended after the role boundaries validation section (~line 592) and before the execution completion verification section (~line 594). The circuit breaker check runs at each loop iteration after the state file is already validated as JSON.

**Precedence over repair loop**: The circuit breaker timeout (48h) has highest priority, always blocks immediately. The consecutive failure check runs after the repair loop for the current task completes. Repair loop exhaustion only affects the current task.

### 3.3 Metrics (`write-metric.sh`)

**File**: `plugins/ralph-specum/hooks/scripts/write-metric.sh`

Single function:

```bash
# write_metric <spec_path> <status> <task_index> <task_iteration> [verify_exit_code] [task_title] [task_type] [task_id] [commit_sha]
write_metric() {
    local spec_path="$1"
    local status="$2"
    local task_index="$3"
    local task_iteration="$4"
    local verify_exit_code="${5:-0}"
    local task_title="${6:-}"
    local task_type="${7:-}"
    local task_id="${8:-}"
    local commit_sha="${9:-}"

    local metrics_file="$spec_path/.metrics.jsonl"
    local lock_file="$spec_path/.metrics.jsonl.lock"

    # Create metrics file if it doesn't exist
    touch "$metrics_file"

    # Generate event identity
    local event_id
    # macOS date does not support %N (nanoseconds). Use fallback.
    local epoch_ns
    epoch_ns=$(date +%s%N 2>/dev/null) || epoch_ns=$(python3 -c 'import time; print(int(time.time()*1000000000))' 2>/dev/null || date +%s)
    event_id="${task_index}-${task_iteration}-$(echo "$epoch_ns" | cut -c1-13)"
    local spec_name
    spec_name=$(basename "$spec_path")
    local now
    now=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # Acquire flock for atomic append
    (
        flock -x 200 || { echo "[ralph-specum] METRICS_ERROR flock acquisition failed" >&2; return 1; }

        # Read current globalIteration from state file if available
        local state_file="$spec_path/.ralph-state.json"
        local global_iteration
        global_iteration=$(jq -r '.globalIteration // 0' "$state_file" 2>/dev/null || echo "0")

        # Build JSONL line — all fields present even if null (per schema)
        # Using jq --arg for safe string escaping to prevent JSON injection
        jq -n \
          --argjson schemaVersion 1 \
          --arg eventId "$event_id" \
          --arg spec "$spec_name" \
          --argjson taskIndex "$task_index" \
          --argjson taskIteration "$task_iteration" \
          --argjson globalIteration "$global_iteration" \
          --arg timestamp "$now" \
          --arg taskTitle "$task_title" \
          --arg taskType "$task_type" \
          --arg taskId "$task_id" \
          --arg completedAt "$now" \
          --argjson verifyExitCode "$verify_exit_code" \
          --arg status "$status" \
          --arg commit "$commit_sha" \
          --argjson retries "$((task_iteration - 1))" \
          '{
            "schemaVersion": $schemaVersion,
            "eventId": $eventId,
            "spec": $spec,
            "taskIndex": $taskIndex,
            "taskIteration": $taskIteration,
            "globalIteration": $globalIteration,
            "timestamp": $timestamp,
            "taskTitle": $taskTitle,
            "taskType": $taskType,
            "taskId": $taskId,
            "startedAt": null,
            "completedAt": $completedAt,
            "wallTimeMs": null,
            "verifyTimeMs": null,
            "verifyExitCode": $verifyExitCode,
            "status": $status,
            "commit": $commit,
            "retries": $retries,
            "error": null,
            "errorDetail": null,
            "agent": "spec-executor",
            "toolsUsed": [],
            "ciSnapshotBefore": null,
            "ciSnapshotAfter": null,
            "ciDrift": false
          }' >> "$metrics_file"

    ) 200>"$lock_file"
}
```

**Key design points**:
- Uses `flock -x` for exclusive locking, same pattern as existing `chat.md` lock in `stop-watcher.sh` line 538.
- Lock file is per-spec (`.metrics.jsonl.lock`), not global.
- Each line is self-contained JSON — a crash mid-write corrupts only one line.
- Fields like `wallTimeMs`, `startedAt`, `ciSnapshotBefore/After` are null at write time (future enhancements can populate them; schema version 1 ensures forward compatibility).
- Called from coordinator in `implement.md` Step 5, **not** from spec-executor.

**Metrics schema** (per JSONL line):

| Field | Type | Source |
|-------|------|--------|
| `schemaVersion` | integer | Always 1 |
| `eventId` | string | `{taskIndex}-{taskIteration}-{epoch_ns}` |
| `spec` | string | `basename(spec_path)` |
| `taskIndex` | integer | Passed to function |
| `taskIteration` | integer | Passed to function |
| `globalIteration` | integer | Read from `.ralph-state.json` at write time |
| `timestamp` | ISO 8601 | Current UTC time |
| `taskTitle` | string | Passed to function |
| `taskType` | string | `implementation`, `verification`, etc. |
| `taskId` | string | e.g., `"4.3"` |
| `startedAt` | ISO 8601 | Future: capture at task start |
| `completedAt` | ISO 8601 | Current UTC time |
| `wallTimeMs` | integer | Future: capture delta |
| `verifyTimeMs` | integer or null | `null` (future: capture delta via SECONDS or date delta) |
| `verifyExitCode` | integer | Passed to function |
| `status` | string | `pass`, `fail`, `timeout`, `cancelled`, `ambiguous` |
| `commit` | string | Commit SHA from task output |
| `retries` | integer | `taskIteration - 1` |
| `error` | string or null | Task error message on failure |
| `errorDetail` | string or null | Full error context |
| `agent` | string | Always `"spec-executor"` |
| `toolsUsed` | string[] | Future: extract from task transcript |
| `ciSnapshotBefore` | string/null | CI baseline (null for plugin repos) |
| `ciSnapshotAfter` | string/null | CI current state (null for plugin repos) |
| `ciDrift` | boolean | false (drift detection future enhancement) |

### 3.4 Heartbeat Detection

**Placement**: Appended to `stop-watcher.sh` after state file existence check (~line 46), before the race condition safeguard.

The function runs on **every** loop iteration, including the first:

```bash
# --- Filesystem Health Check: Heartbeat (Spec 4: loop-safety-infra) ---
# Writes .ralph-heartbeat to spec dir, reads back to verify.
# Three-tier response based on filesystemHealthFailures count.
check_filesystem_heartbeat() {
    local spec_path="$1"
    local state_file="$2"

    local heartbeat_file="$spec_path/.ralph-heartbeat"
    local heartbeat_err
    heartbeat_err=$(mktemp)

    # Authoritative write attempt
    echo "heartbeat: $(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$heartbeat_file" 2>"$heartbeat_err"
    local write_ok=$?

    # Cleanup error temp file
    local err_msg
    err_msg=$(cat "$heartbeat_err" 2>/dev/null || echo "unknown error")
    rm -f "$heartbeat_err"

    if [ $write_ok -ne 0 ]; then
        # Read failure — increment counter
        local current_failures
        current_failures=$(jq -r '.filesystemHealthFailures // 0' "$state_file" 2>/dev/null || echo "0")
        local new_failures=$((current_failures + 1))

        # Update state
        local ts
        ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        jq --argjson failures "$new_failures" \
           --arg ts "$ts" \
           '.filesystemHealthFailures = $failures | .lastFilesystemCheck = $ts | .filesystemHealthy = false' \
           "$state_file" > "${state_file}.tmp" 2>/dev/null && mv "${state_file}.tmp" "$state_file"

        # Three-tier response
        case "$new_failures" in
            1)
                # Tier 1: Warn — log to .progress.md, continue
                echo "[ralph-specum] FILESYSTEM_WARN 1st consecutive heartbeat failure: $err_msg" >&2
                echo "- [$(date -u +%Y-%m-%dT%H:%M:%SZ)] FILESYSTEM_WARN: heartbeat write failed ($err_msg). Continuing." >> "$spec_path/.progress.md" 2>/dev/null || true
                ;;
            2)
                # Tier 2: Escalate — block prompt
                local hb_escalate_msg
                hb_escalate_msg=$(cat <<HB_ESC_EOF
[ralph-specum] FILESYSTEM_ESCALATION 2nd consecutive heartbeat failure

Filesystem write failures detected in $spec_path.

## Recovery
1. Check disk space: df -h
2. Check permissions: ls -la $spec_path
3. Fix the issue, then resume with /ralph-specum:implement
HB_ESC_EOF
)
                jq -n \
                  --arg reason "$hb_escalate_msg" \
                  --arg msg "Ralph-specum: filesystem health escalation" \
                  '{
                    "decision": "block",
                    "reason": $reason,
                    "systemMessage": $msg
                  }'
                rm -f "$heartbeat_file"
                exit 0
                ;;
            *)
                # Tier 3+: Full block
                local hb_block_msg
                hb_block_msg=$(cat <<HB_BLK_EOF
[ralph-specum] FILESYSTEM_BLOCK $new_failures+ consecutive heartbeat failures

Filesystem is not writable in $spec_path. Execution stopped.

## Recovery
1. Fix filesystem (disk space, permissions, mount)
2. Reset state: set filesystemHealthy=true, filesystemHealthFailures=0
3. Resume with /ralph-specum:implement
HB_BLK_EOF
)
                jq -n \
                  --arg reason "$hb_block_msg" \
                  --arg msg "Ralph-specum: filesystem block after $new_failures failures" \
                  '{
                    "decision": "block",
                    "reason": $reason,
                    "systemMessage": $msg
                  }'
                rm -f "$heartbeat_file"
                exit 0
                ;;
        esac
    else
        # Successful write — reset counter
        # NOTE: This writes to state file. Unlike circuitBreaker (single-writer: coordinator only),
        # filesystem fields are intentionally written by stop-watcher because only it detects failures.
        # Concurrency is not a concern: stop-watcher runs single-threaded per iteration.
        local ts
        ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        jq --arg ts "$ts" \
           '.filesystemHealthy = true | .filesystemHealthFailures = 0 | .lastFilesystemCheck = $ts' \
           "$state_file" > "${state_file}.tmp" 2>/dev/null && mv "${state_file}.tmp" "$state_file"

        # Verify round-trip: read-back must match the write pattern
        local content
        content=$(cat "$heartbeat_file" 2>/dev/null || echo "")
        if echo "$content" | grep -q "^heartbeat:"; then
            : # Round-trip OK, continue
        else
            # Write appeared to succeed but content is wrong — treat as failure
            rm -f "$heartbeat_file"
            # Fall through to failure path by setting write_ok=1
            write_ok=1
        fi
        rm -f "$heartbeat_file"
    fi
}
# --- End Filesystem Health Check ---
```

**Placement in stop-watcher.sh**: Insert after line 46 (`if [ ! -f "$STATE_FILE" ]; then exit 0; fi`) and before the race condition safeguard (line 48). This ensures the check runs even before other logic that might depend on filesystem writes.

**Performance**: The heartbeat check is a single `echo > file` + `cat file` + cleanup, typically under 3ms on local filesystems. The 10ms NFR is comfortably met.

### 3.5 CI Snapshot

**Discovery**: Runs once at state init in `implement.md` Step 3, not per-loop.

```bash
# CI command discovery (runs once at spec init)
discover_ci_commands() {
    local repo_root="$1"
    local ci_commands="[]"

    # Scan .github/workflows/*.yml
    if [ -d "$repo_root/.github/workflows" ]; then
        while IFS= read -r wf; do
            local basename_wf
            basename_wf=$(basename "$wf")
            # Extract command lines from CI workflow files
            # Note: YAML parsing is heuristic — multi-line run directives may not be captured correctly.
            # A proper YAML parser (yq) would be more accurate but adds a dependency.
            while IFS= read -r cmd_line; do
                # Skip comments, empty lines, and non-command lines
                if echo "$cmd_line" | grep -qE '^\s*-\s*run:' ; then
                    local extracted
                    # Non-greedy: match only the first 'run:' after '- '
                    extracted=$(echo "$cmd_line" | sed 's/^[^:]*run:[[:space:]]*//' | tr -d '"' | tr -d "'" | head -c 200)
                    if [ -n "$extracted" ]; then
                        ci_commands=$(echo "$ci_commands" | jq --arg cmd "workflow/$basename_wf: $extracted" '. + [$cmd]')
                    fi
                fi
            done < "$wf"
        done < <(find "$repo_root/.github/workflows" -name '*.yml' 2>/dev/null)
    fi

    # Scan tests/*.bats
    if [ -d "$repo_root/tests" ]; then
        while IFS= read -r bat; do
            while IFS= read -r line; do
                if echo "$line" | grep -qE '^\s*(bats| bats |\.\/tests?)' ; then
                    local extracted
                    extracted=$(echo "$line" | sed 's/^[[:space:]]*//' | head -c 200)
                    if [ -n "$extracted" ]; then
                        ci_commands=$(echo "$ci_commands" | jq --arg cmd "bats/$(basename "$bat"): $extracted" '. + [$cmd]')
                    fi
                fi
            done < "$bat"
        done < <(find "$repo_root/tests" -name '*.bats' 2>/dev/null)
    fi

    # Deduplicate
    echo "$ci_commands" | jq 'unique'
}
```

**Classification**: Commands are classified by grepping for keywords:

| Category | Keywords | Example |
|----------|----------|---------|
| `test` | "test", "bats" | `bats tests/unit/` |
| `lint` | "lint", "eslint" | `eslint .` |
| `build` | "build", "compile" | `npm run build` |
| `typecheck` | "typecheck", "tsc" | `tsc --noEmit` |

**Selective CI strategy for plugin repos**: For repos with no `package.json`, skip per-task selective CI. Full CI runs only at spec completion. Per-task metric entries have `ciSnapshotBefore: null`, `ciSnapshotAfter: null`, `ciDrift: false`.

**CI drift detection**: `stop-watcher.sh` reads `ciCommands` from state at loop start (once), records a baseline. Post-task or at spec completion, runs the CI commands and compares results.

## 4. File Changes

### New Files

| File | Purpose | Key Functions |
|------|---------|---------------|
| `plugins/ralph-specum/hooks/scripts/checkpoint.sh` | Git checkpoint utilities | `checkpoint-create`, `checkpoint-rollback` |
| `plugins/ralph-specum/hooks/scripts/write-metric.sh` | JSONL metrics append utility | `write_metric` (with flock, jq-safe) |
| `plugins/ralph-specum/references/loop-safety.md` | Safety rules reference: decision log, recovery procedures, configuration defaults | N/A (reference doc) |
| `plugins/ralph-specum/commands/rollback.md` | `/ralph-specum:rollback` slash command | Calls `checkpoint-rollback` |
| `specs/<name>/.metrics.jsonl` | Per-task metrics (created at execution start) | N/A (data file) |

### Modified Files

| File | Section | Change |
|------|---------|--------|
| `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` | After line 46 | Append `check_filesystem_heartbeat()` |
| `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` | After line 592 (role boundaries) | Append `check_circuit_breaker()` |
| `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` | After circuit breaker | Append CI drift check function |
| `plugins/ralph-specum/schemas/spec.schema.json` | `state.properties` | Add `checkpoint`, `circuitBreaker`, `filesystemHealthy`, `filesystemHealthFailures`, `lastFilesystemCheck`, `ciCommands` |
| `plugins/ralph-specum/commands/implement.md` | Step 3 | Add checkpoint creation, CI discovery, metrics file init, circuit breaker init |
| `plugins/ralph-specum/commands/implement.md` | Step 5 | Add metrics write call, circuit breaker state update on task pass/fail |

## 5. Integration Points

### stop-watcher.sh Integration

```
Line ~46:  check_filesystem_heartbeat($SPEC_PATH, $STATE_FILE)
           # Runs first, before any other safety logic

Line ~60:  (existing global iteration check)

Line ~592: check_circuit_breaker($STATE_FILE, $SPEC_NAME)
           # Runs after state is validated as JSON
           # Called from the "loop control" section, before the continuation prompt

Line ~760: (CI drift detection appended at end, called in the continuation section)
```

The order of checks per iteration:
1. Filesystem heartbeat (always, first)
2. Global iteration limit (existing)
3. Circuit breaker (new, after role boundaries)
4. CI drift check (new, appended at end)

### implement.md Integration

```
Step 3 (Initialize Execution State):
  - After counting tasks, call checkpoint-create(spec_name, total_tasks, state_file)
  - After checkpoint success, call discover_ci_commands(repo_root)
  - Initialize circuitBreaker in jq merge:
    {state: "closed", consecutiveFailures: 0, sessionStartTime: <epoch>,
     maxConsecutiveFailures: 5, maxSessionSeconds: 172800}
  - touch "$SPEC_PATH/.metrics.jsonl"

Step 5 (Completion):
  - After TASK_COMPLETE, call write_metric.sh with task result data
  - Update circuitBreaker.consecutiveFailures (reset to 0 on pass, +1 on fail)
  - Check if consecutiveFailures >= maxConsecutiveFailures; if so, set state to "open"
```

## 6. State Schema Changes

### Additions to `spec.schema.json`

All changes are under the `state` definition's `properties` object:

```json
{
  "checkpoint": {
    "type": "object",
    "description": "Git checkpoint before execution",
    "properties": {
      "sha": {
        "type": ["string", "null"],
        "description": "Short commit SHA (7 chars) or null if no checkpoint"
      },
      "timestamp": {
        "type": ["string", "null"],
        "format": "date-time",
        "description": "ISO 8601 timestamp of checkpoint creation"
      },
      "branch": {
        "type": ["string", "null"],
        "description": "Git branch name at checkpoint time"
      },
      "message": {
        "type": ["string", "null"],
        "description": "Checkpoint commit message"
      }
    }
  },
  "circuitBreaker": {
    "type": "object",
    "description": "Circuit breaker state for consecutive failure tracking",
    "properties": {
      "state": {
        "type": "string",
        "enum": ["closed", "open"],
        "default": "closed",
        "description": "Current circuit breaker state"
      },
      "consecutiveFailures": {
        "type": "integer",
        "minimum": 0,
        "default": 0,
        "description": "Number of consecutive task failures"
      },
      "sessionStartTime": {
        "type": "integer",
        "description": "Epoch seconds when execution session started"
      },
      "openedAt": {
        "type": ["string", "null"],
        "description": "ISO 8601 timestamp when circuit opened"
      },
      "trippedReason": {
        "type": ["string", "null"],
        "description": "Reason circuit was tripped"
      },
      "maxConsecutiveFailures": {
        "type": "integer",
        "minimum": 1,
        "default": 5,
        "description": "Threshold for consecutive failure trip"
      },
      "maxSessionSeconds": {
        "type": "integer",
        "minimum": 1,
        "default": 172800,
        "description": "Maximum session duration in seconds (48h default)"
      }
    }
  },
  "filesystemHealthy": {
    "type": "boolean",
    "default": true,
    "description": "Last known filesystem health status"
  },
  "filesystemHealthFailures": {
    "type": "integer",
    "minimum": 0,
    "default": 0,
    "description": "Consecutive heartbeat write failures"
  },
  "lastFilesystemCheck": {
    "type": ["string", "null"],
    "format": "date-time",
    "description": "Timestamp of last filesystem health check"
  },
  "ciCommands": {
    "type": "array",
    "items": { "type": "string" },
    "default": [],
    "description": "Discovered CI commands from .github/workflows/*.yml and tests/*.bats"
  }
}
```

### Schema Merge Plan

Spec 1 and this spec (Spec 4) both modify `spec.schema.json`'s `state.properties` object:

| Spec 1 Fields (Spec 1: schema foundations) | Spec 4 Fields (this spec) |
|-------------------------------------------|---------------------------|
| `nativeTaskMap` (object) | `checkpoint` (object) |
| `nativeSyncEnabled` (boolean) | `circuitBreaker` (object) |
| `nativeSyncFailureCount` (integer) | `filesystemHealthy` (boolean) |
| | `filesystemHealthFailures` (integer) |
| | `lastFilesystemCheck` (string) |
| | `ciCommands` (string[]) |

Since the JSON Schema `properties` object is a flat dictionary, both sets of additions coexist as the **union** of both field sets. No key collisions exist — Spec 1 adds task-related fields, Spec 4 adds safety-related fields. The `required` array does not need modification because all new fields have defaults.

## 7. Technical Decisions

### Decision 1: Absolute Consecutive Count vs. Error-Percentage Model

**Chosen**: Absolute consecutive count (3-state: CLOSED → OPEN → manual reset).

**Options considered**:
- Error-percentage (Netflix Hystrix): Tracks failure rate over sliding window. Too noisy for sequential execution.
- Sliding-window (resilience4j): Counts failures over time window. Overkill for deterministic agent execution.
- Absolute consecutive count (Polly pattern): Simple, matches sequential execution semantics.

**Rationale**: Each task failure in sequential execution is a discrete event. There is no "noise" to average out. 5 consecutive failures is a strong signal that something is fundamentally wrong.

### Decision 2: No HALF_OPEN State

**Chosen**: CLOSED → OPEN → manual reset.

**Rationale**: The spec-executor is a deterministic agent — if it was stuck on a task, it will be stuck again. HALF_OPEN would immediately re-trip, adding complexity with no benefit.

### Decision 3: Append-only to stop-watcher.sh

**Chosen**: All new functions appended at end of file, called from the loop continuation step.

**Rationale**: 765 lines of complex, interdependent logic. Modifying existing code risks breaking the entire execution loop. The epic.md risk assessment rates this as "High" severity.

### Decision 4: Heartbeat Always Runs (Including First Iteration)

**Chosen**: The heartbeat write check runs on every loop iteration, not conditionally.

**Rationale**: A conditional check that only runs when failures were previously detected will skip the first iteration — the most critical check. If the filesystem is read-only from the start, a conditional check would never detect it.

### Decision 5: Manual Circuit Breaker Reset Only

**Chosen**: No automatic reset path. Human must edit state file.

**Rationale**: NFR-004 states that automatic reset could mask fundamental problems. If 5 tasks fail in a row, the system is broken — automatically resetting would let a broken sequence continue.

### Decision 6: JSONL for Metrics, Not JSON Array

**Chosen**: JSONL (one JSON object per line) with flock.

**Rationale**:
- Append-safe: each line is self-contained.
- Crash-resilient: mid-write crash corrupts only one line.
- Stream-processable: consumed line-by-line by jq, awk, grep.
- Standard pattern: used by GitHub Actions, LangGraph, OpenTelemetry.

### Decision 6.5: jq Version Compatibility

**Chosen**: All jq operations use features available since jq 1.5 (the most widely deployed version). SHA shortening uses `cut -c1-7` pattern implicitly via `git rev-parse --short=7` which is a git feature, not jq. For jq `--short=7` flag usage, a fallback is needed.

**Rationale**: The `--short=N` flag in jq was only added in jq 1.6 (2022). Systems running older jq (e.g., Ubuntu 20.04 ships with jq 1.5) would fail. The design uses `git rev-parse --short=7` for SHA shortening (git feature, always available) rather than jq's `--short` flag.

### Decision 7: CI Discovery Scope Limited to `.github/workflows/*.yml` and `tests/*.bats`

**Chosen**: Only scan these two locations for CI commands.

**Rationale**: This is a Claude Code plugin repo. There is no `package.json`, `Makefile`, or `Jenkinsfile`. The actual CI consists of 4 GitHub Actions workflow files running BATS tests. Scanning additional patterns would add complexity with no value.

## 8. Error Handling

### Checkpoint Errors

| Error | Handling |
|-------|----------|
| No git repo | `sha: null`, execution proceeds |
| Detached HEAD | Warning logged, `sha: null`, execution proceeds |
| Uncommitted changes | Included in checkpoint with warning |
| Git commit fails (missing user config) | **Block execution** — return 1 from `checkpoint-create` |
| Disk full during commit | **Block execution** — `checkpoint-create` returns 1 |
| Checkpoint SHA not found on rollback | `checkpoint-rollback` returns 1 with error message |

### Circuit Breaker Errors

| Error | Handling |
|-------|----------|
| Missing `circuitBreaker` field in state | Default to `closed`, 0 failures (graceful degradation) |
| Corrupt state file | Already handled by existing JSON validation (~line 423) |
| Malformed JSON in circuitBreaker values | jq returns defaults on parse failure |
| State file write failure during counter update | `.tmp` file pattern ensures atomic replacement; on failure, original state preserved |

### Metrics Errors

| Error | Handling |
|-------|----------|
| `flock` acquisition fails | Log error, return 1, execution continues (metrics loss is non-critical) |
| Metrics file permission denied | Log error, execution continues |
| Concurrent writes from two specs | flock serializes access — no interleaving |

### Heartbeat Errors

| Error | Handling |
|-------|----------|
| 1st failure | Warning logged, continue |
| 2nd failure | Block prompt with recovery instructions |
| 3rd+ failure | Full block, require human action |
| State file write failure during health reset | `.tmp` pattern; on failure, original state preserved |

### CI Snapshot Errors

| Error | Handling |
|-------|----------|
| No `.github/workflows/` directory | `ciCommands` = empty array, snapshots = null |
| No `tests/*.bats` files | No BATS commands discovered, `ciCommands` contains only workflow commands |
| CI command runs and fails | Logged to `.progress.md`, `ciDrift` set to `true` in metric entry |

## 9. Test Strategy

### Unit Tests for Bash Functions

Each bash function is tested in isolation:

```bash
# Test checkpoint.sh
test_checkpoint_no_repo() {
    local state_file
    state_file=$(mktemp)
    echo '{}' > "$state_file"
    checkpoint-create "test-spec" "10" "$state_file"
    [ "$(jq -r '.checkpoint.sha' "$state_file")" = "null" ]
    rm -f "$state_file"
}

test_checkpoint_create() {
    local state_file
    state_file=$(mktemp)
    echo '{}' > "$state_file"
    # Requires git repo — run in a temp dir
    (
        cd "$(mktemp -d)"
        git init
        git config user.email "test@test.com"
        git config user.name "Test"
        echo "test" > file.txt
        git add -A
        git commit -m "initial" --no-verify >/dev/null 2>&1
        echo "new" > file2.txt
        checkpoint-create "test-spec" "5" "$state_file"
        local sha
        sha=$(jq -r '.checkpoint.sha' "$state_file")
        [ -n "$sha" ] && [ "$sha" != "null" ]
    )
    rm -f "$state_file"
}

test_checkpoint_rollback() {
    # Create a git repo, create a file, commit (checkpoint), create another file,
    # call rollback, verify only the first file remains
    (
        cd "$(mktemp -d)"
        git init
        git config user.email "test@test.com"
        git config user.name "Test"
        echo "file1" > file1.txt
        git add -A
        git commit -m "initial" --no-verify >/dev/null 2>&1
        local state_file
        state_file=$(mktemp)
        echo '{}' > "$state_file"
        checkpoint-create "test-spec" "5" "$state_file"
        echo "file2" > file2.txt
        checkpoint-rollback "$state_file"
        [ ! -f file2.txt ] && [ -f file1.txt ]
        rm -f "$state_file"
    )
}

test_write_metric() {
    local spec_path
    spec_path=$(mktemp -d)
    touch "$spec_path/.metrics.jsonl"
    write_metric "$spec_path" "pass" 0 1 0 "test task" "implementation" "1.1" "abc1234"
    local line_count
    line_count=$(wc -l < "$spec_path/.metrics.jsonl")
    [ "$line_count" -eq 1 ]
    # Verify JSON is valid
    head -1 "$spec_path/.metrics.jsonl" | jq empty
    rm -rf "$spec_path"
}

test_write_metric_flock_concurrent() {
    # Launch two concurrent write_metric calls, verify no interleaved lines
}

test_heartbeat_success() {
    local spec_path state_file
    spec_path=$(mktemp -d)
    state_file=$(mktemp)
    echo '{}' > "$state_file"
    check_filesystem_heartbeat "$spec_path" "$state_file"
    # Verify filesystemHealthFailures was reset to 0
    local failures
    failures=$(jq -r '.filesystemHealthFailures' "$state_file")
    [ "$failures" = "0" ]
    # Verify filesystemHealthy is true
    local healthy
    healthy=$(jq -r '.filesystemHealthy' "$state_file")
    [ "$healthy" = "true" ]
    rm -rf "$spec_path" "$state_file"
}

test_heartbeat_readonly() {
    # Make spec_path read-only, verify tier 1 warning then tier 2 block
    local spec_path state_file
    spec_path=$(mktemp -d)
    state_file=$(mktemp)
    echo '{}' > "$state_file"
    chmod 000 "$spec_path"
    # 1st failure → tier 1 warning (no exit)
    check_filesystem_heartbeat "$spec_path" "$state_file"
    local tier1=$?
    # 2nd failure → tier 2 escalation (exit 0)
    check_filesystem_heartbeat "$spec_path" "$state_file"
    # Should have exited with code 0 and written escalation message
    chmod 755 "$spec_path"
    rm -rf "$spec_path" "$state_file"
}
```

### Integration Tests for Hook Chain

```bash
# Test the full stop-watcher hook with circuit breaker
test_circuit_breaker_integration() {
    # 1. Create a spec with state file containing circuitBreaker
    # 2. Set consecutiveFailures to 5
    # 3. Run stop-watcher.sh — should output circuit breaker block prompt
    # 4. Verify decision = "block" in output JSON
}

test_heartbeat_in_hook() {
    # 1. Create a spec directory
    # 2. Run stop-watcher.sh
    # 3. Verify .ralph-heartbeat file is created and cleaned up
    # 4. Measure time: should be < 10ms
}

test_ci_discover_workflows() {
    # Create a temp .github/workflows dir with a sample workflow
    local repo_root
    repo_root=$(mktemp -d)
    mkdir -p "$repo_root/.github/workflows"
    cat > "$repo_root/.github/workflows/ci.yml" <<'EOF'
name: CI
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo "hello"
      - run: bats tests/
EOF
    local commands
    commands=$(discover_ci_commands "$repo_root")
    echo "$commands" | jq -e '. | length > 0'
    rm -rf "$repo_root"
}

test_ci_discover_bats() {
    local repo_root
    repo_root=$(mktemp -d)
    mkdir -p "$repo_root/tests"
    cat > "$repo_root/tests/test_basic.bats" <<'EOF'
@test "basic pass" {
  bats tests/unit/
}
EOF
    local commands
    commands=$(discover_ci_commands "$repo_root")
    echo "$commands" | jq -e '. | length > 0'
    rm -rf "$repo_root"
}

test_ci_discover_empty() {
    local repo_root
    repo_root=$(mktemp -d)
    # No .github/workflows, no tests/
    local commands
    commands=$(discover_ci_commands "$repo_root")
    [ "$(echo "$commands" | jq '. | length')" = "0" ]
    rm -rf "$repo_root"
}
```

### Performance Benchmarks

```bash
# Heartbeat performance: must be < 10ms
time (for i in $(seq 100); do
    echo "heartbeat" > /tmp/test-hb
    cat /tmp/test-hb >/dev/null
    rm -f /tmp/test-hb
done)
# Expected: ~100ms total for 100 iterations, i.e., ~1ms per invocation
```

## 10. Implementation Order

The five safety mechanisms are independent and can be implemented in any order. The recommended sequence, minimizing schema changes per step:

| Step | Mechanism | Dependencies | Files Created/Modified |
|------|-----------|-------------|----------------------|
| 1 | **Git checkpoint** | Schema `checkpoint` object | `checkpoint.sh` (new), `implement.md` (Step 3), `rollback.md` (new), `spec.schema.json` |
| 2 | **Circuit breaker** | Schema `circuitBreaker` object | `stop-watcher.sh` (append), `implement.md` (Step 3 + Step 5), `spec.schema.json` |
| 3 | **Read-only detection** | Schema flat fields | `stop-watcher.sh` (append), `spec.schema.json` |
| 4 | **Per-task metrics** | None | `write-metric.sh` (new), `implement.md` (Step 5), `spec.schema.json` (minimal — no state fields needed) |
| 5 | **CI snapshot tracking** | Schema `ciCommands` array | `implement.md` (Step 3 discovery), `write-metric.sh` (CI fields), `stop-watcher.sh` (append drift check), `spec.schema.json` |

### Detailed Step Plan

**Step 1: Git Checkpoint (Priority: HIGH)**
1. Add `checkpoint` definition to `spec.schema.json`
2. Create `checkpoint.sh` with `checkpoint-create` and `checkpoint-rollback`
3. Add checkpoint creation to `implement.md` Step 3 (after task count, before state merge)
4. Create `rollback.md` command with frontmatter (description: "Roll back to pre-execution git checkpoint"), slash command `/ralph-specum:rollback`, reads checkpoint SHA from state file, calls `checkpoint-rollback`
5. Test: create a git repo, run checkpoint, verify SHA stored, test rollback

**Step 2: Circuit Breaker (Priority: HIGH)**
1. Add `circuitBreaker` definition to `spec.schema.json`
2. Append `check_circuit_breaker()` to `stop-watcher.sh`
3. Add circuit breaker initialization to `implement.md` Step 3 (in jq merge)
4. Add circuit breaker state updates to `implement.md` Step 5 (post-task pass/fail)
5. Test: set `consecutiveFailures` to 5, verify stop-watcher blocks

**Step 3: Read-Only Detection (Priority: HIGH)**
1. Add flat fields to `spec.schema.json`
2. Append `check_filesystem_heartbeat()` to `stop-watcher.sh` (after line 46)
3. Test: create a read-only directory, verify three-tier response

**Step 4: Per-Task Metrics (Priority: HIGH)**
1. Create `write-metric.sh` with `write_metric` function
2. Add `touch .metrics.jsonl` to `implement.md` Step 3
3. Add `write_metric.sh` call to `implement.md` Step 5 (post-TASK_COMPLETE)
4. Test: verify JSONL file created, lines parse as valid JSON

**Step 5: CI Snapshot Tracking (Priority: MEDIUM)**
1. Add `ciCommands` to `spec.schema.json`
2. Add CI discovery to `implement.md` Step 3
3. Add CI snapshot fields to `write-metric.sh` output
4. Append CI drift check to `stop-watcher.sh`
5. Test: create a workflow file, verify CI commands discovered
