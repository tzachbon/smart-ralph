#!/usr/bin/env bash
# write-metric.sh — Per-task JSONL metrics for Smart Ralph execution loop.
# Provides write_metric function that appends atomic JSONL lines
# to a per-spec metrics file with flock concurrency protection.
# All string fields use jq -n --arg to prevent JSON injection.

# ---------------------------------------------------------------------------
# write_metric: Append one JSONL metric line for a completed task.
#
# Usage: write_metric <spec_path> <status> <task_index> <task_iteration>
#        [verify_exit_code] [task_title] [task_type] [task_id] [commit_sha]
#
# Appends one JSONL line to "$spec_path/.metrics.jsonl" with flock protection.
# The metrics file is per-spec (not global), one line per task completion.
#
# Parameters:
#   spec_path          Path to the spec directory (contains .metrics.jsonl)
#   status             pass | fail | timeout | cancelled | ambiguous
#   task_index         Numeric task index (0-based)
#   task_iteration     Numeric retry iteration (0-based)
#   verify_exit_code   Exit code from the task's verify command (default: 0)
#   task_title         Human-readable task title (default: "unknown")
#   task_type          Task type: implementation | test | refactor | quality (default: "implementation")
#   task_id            Task identifier like "1.5" (default: "unknown")
#   commit_sha         Git commit SHA from task commit (default: "00000000")
#
# Creates .metrics.jsonl if it doesn't exist (touch via append).
# Uses flock -x for concurrency safety (same model as chat.md.lock).
# ---------------------------------------------------------------------------

write_metric() {
  local spec_path="$1"
  local status="$2"
  local task_index="${3:-0}"
  local task_iteration="${4:-0}"
  local verify_exit_code="${5:-0}"
  local task_title="${6:-unknown}"
  local task_type="${7:-implementation}"
  local task_id="${8:-unknown}"
  local commit_sha="${9:-00000000}"

  # --- Check jq version (1.5+ required for --arg support) ---
  local jq_ver
  jq_ver="$(jq --version 2>/dev/null | sed 's/jq-\([0-9]*\)\.\([0-9]*\).*/\1\2/')"
  if [ -n "$jq_ver" ] && [ "${jq_ver:0:1}" -lt 1 ] 2>/dev/null; then
    echo "[ralph-specum] WARNING: jq version < 1.5 may not support --arg" >&2
  fi

  # --- Read spec name from state file ---
  local state_file="$spec_path/.ralph-state.json"
  local spec_name
  spec_name="$(jq -r '.spec // empty' "$state_file" 2>/dev/null)"
  if [ -z "$spec_name" ]; then
    spec_name="$(basename "$spec_path" 2>/dev/null)"
    if [ -z "$spec_name" ]; then
      spec_name="unknown"
    fi
  fi

  # --- Generate unique event ID: {task_index}-{task_iteration}-{epoch_ns} ---
  # Uses date +%s%N for nanosecond precision (macOS fallback via python3).
  local epoch_ns
  if epoch_ns="$(date +%s%N 2>/dev/null)" && [ -n "$epoch_ns" ] && [ "$epoch_ns" != "N" ]; then
    : # Linux: date +%s%N produces epoch in nanoseconds
  elif epoch_ns="$(python3 -c 'import time; print(int(time.time()*1000000000))' 2>/dev/null)" && [ -n "$epoch_ns" ]; then
    : # macOS fallback: python3 produces epoch * 1e9
  else
    epoch_ns="$(date +%s 2>/dev/null || echo 0)"000000000 # Final fallback: epoch seconds + padding
  fi
  local event_id="${task_index}-${task_iteration}-${epoch_ns}"

  # --- Current timestamp (ISO 8601 UTC) ---
  local timestamp
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")"

  # --- Acquire exclusive lock for concurrent write safety ---
  # Lock file placed alongside .metrics.jsonl (per-spec isolation).
  local lock_file="$spec_path/.metrics.lock"
  local metrics_file="$spec_path/.metrics.jsonl"

  (
    flock -x 200 || {
      echo "[ralph-specum] ERROR: failed to acquire lock for $metrics_file" >&2
      exit 1
    }

    # --- Build JSONL line via jq -n --arg (all strings escaped) ---
    # String fields: schemaVersion eventId spec status taskIndex taskIteration
    #   verifyExitCode taskTitle taskType taskId timestamp commitSha
    # Null fields: completedAt wallTimeMs verifyTimeMs retries error errorDetail
    #   agent toolsUsed ciSnapshotBefore ciSnapshotAfter ciDrift
    #
    # Uses --argjson for null values (jq null, not string "null").

    # SR-014: Read globalIteration from state file (was always null)
    local global_iteration
    global_iteration="$(jq -r '.globalIteration // 1' "$state_file" 2>/dev/null || echo "1")"

    # SR-013: Read agent name from state file (was always null)
    local agent
    agent="$(jq -r '.chat.executor.agent // "spec-executor"' "$state_file" 2>/dev/null || echo "spec-executor")"

    local jq_args=()
    jq_args+=( --arg schemaVersion "1" )
    jq_args+=( --arg eventId "$event_id" )
    jq_args+=( --arg spec "$spec_name" )
    jq_args+=( --arg status "$status" )
    jq_args+=( --arg taskIndex "$task_index" )
    jq_args+=( --arg taskIteration "$task_iteration" )
    jq_args+=( --arg verifyExitCode "$verify_exit_code" )
    jq_args+=( --arg taskTitle "$task_title" )
    jq_args+=( --arg taskType "$task_type" )
    jq_args+=( --arg taskId "$task_id" )
    jq_args+=( --arg timestamp "$timestamp" )
    jq_args+=( --arg commitSha "$commit_sha" )
    jq_args+=( --arg globalIteration "$global_iteration" )
    jq_args+=( --arg agent "$agent" )
    jq_args+=( --argjson nullNull null )
    jq_args+=( --argjson zeroNum 0 )
    jq_args+=( --argjson trueBool true )
    jq_args+=( --argjson falseBool false )

    # SR-006: Capture exit code properly and propagate errors
    local write_exit=0
    echo "$spec_path" | jq -c -n \
      --arg spec "$spec_path" \
      "${jq_args[@]}" \
      '{
        schemaVersion: ($schemaVersion | tonumber),
        eventId: $eventId,
        timestamp: $timestamp,
        spec: $spec,
        status: $status,
        taskIndex: ($taskIndex | tonumber),
        taskIteration: ($taskIteration | tonumber),
        verifyExitCode: ($verifyExitCode | tonumber),
        taskTitle: $taskTitle,
        taskType: $taskType,
        taskId: $taskId,
        commitSha: $commitSha,
        wallTimeMs: $zeroNum,
        startedAt: $timestamp,
        completedAt: $nullNull,
        verifyTimeMs: $nullNull,
        globalIteration: ($globalIteration | tonumber),
        commit: (if $commitSha == "00000000" then $nullNull else $commitSha end),
        retries: $zeroNum,
        error: $nullNull,
        errorDetail: $nullNull,
        agent: $agent,
        toolsUsed: $nullNull,
        ciSnapshotBefore: $nullNull,
        ciSnapshotAfter: $nullNull,
        ciDrift: $falseBool
      }' >> "$metrics_file" || write_exit=$?

    # SR-006: Return non-zero on write failure
    if [ "$write_exit" -ne 0 ]; then
      echo "[ralph-specum] ERROR: Failed to write metric (exit code $write_exit)" >&2
      return "$write_exit"
    fi

    return 0

  ) 200>"$lock_file"

  return 0
}
