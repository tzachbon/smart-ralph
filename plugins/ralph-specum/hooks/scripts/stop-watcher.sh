#!/usr/bin/env bash
# Stop Hook for Ralph Specum — Loop controller for task execution continuation
# Exits silently (code 0) when no active spec, outputs block JSON when tasks remain.

# Read hook input from stdin
INPUT=$(cat)

# Bail out cleanly if jq is unavailable
command -v jq >/dev/null 2>&1 || exit 0

# Get working directory (guard against parse failures)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)
if [ -z "$CWD" ]; then
    exit 0
fi

# Source path resolver for spec directory resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_CWD="$CWD"
export RALPH_CWD
source "$SCRIPT_DIR/path-resolver.sh"

# Check for settings file to see if plugin is enabled
SETTINGS_FILE="$CWD/.claude/ralph-specum.local.md"
if [ -f "$SETTINGS_FILE" ]; then
    # Extract enabled setting from YAML frontmatter (normalize case and strip quotes)
    ENABLED=$(sed -n '/^---$/,/^---$/p' "$SETTINGS_FILE" 2>/dev/null \
        | awk -F: '/^enabled:/{val=$2; gsub(/[[:space:]"'"'"']/, "", val); print tolower(val); exit}')
    if [ "$ENABLED" = "false" ]; then
        exit 0
    fi
fi

# Resolve current spec using path resolver (handles multi-directory support)
SPEC_PATH=$(ralph_resolve_current 2>/dev/null)
if [ -z "$SPEC_PATH" ]; then
    exit 0
fi

# Extract spec name from path (last component)
SPEC_NAME=$(basename "$SPEC_PATH")

STATE_FILE="$CWD/$SPEC_PATH/.ralph-state.json"
if [ ! -f "$STATE_FILE" ]; then
    exit 0
fi

# Race condition safeguard: if state file was modified in last 2 seconds, wait briefly
# This allows the coordinator to finish writing before we read
if command -v stat >/dev/null 2>&1; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS stat
        MTIME=$(stat -f %m "$STATE_FILE" 2>/dev/null || echo "0")
    else
        # Linux stat
        MTIME=$(stat -c %Y "$STATE_FILE" 2>/dev/null || echo "0")
    fi
    NOW=$(date +%s)
    AGE=$((NOW - MTIME))
    if [ "$AGE" -lt 2 ]; then
        sleep 1
    fi
fi

# Check for ALL_TASKS_COMPLETE in transcript (backup termination detection)
# Use specific pattern to avoid false positives from code/comments containing the phrase
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || true)
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
    # Primary: 500 lines covers most sessions for reliable detection
    if tail -500 "$TRANSCRIPT_PATH" 2>/dev/null | grep -qE '(^|\W)ALL_TASKS_COMPLETE(\W|$)'; then
        echo "[ralph-specum] ALL_TASKS_COMPLETE detected in transcript" >&2
        # Note: State file cleanup is handled by the coordinator (implement.md Section 10)
        # Do not delete here to avoid race condition
        # Update epic state if this spec belongs to an epic
        EPIC_NAME_VAL=$(jq -r '.epicName // empty' "$STATE_FILE" 2>/dev/null || true)
        CURRENT_EPIC_FILE="$CWD/specs/.current-epic"
        if [ -n "$EPIC_NAME_VAL" ] && [ -f "$CURRENT_EPIC_FILE" ]; then
            EPIC_STATE_FILE="$CWD/specs/_epics/$EPIC_NAME_VAL/.epic-state.json"
            if [ -f "$EPIC_STATE_FILE" ]; then
                TMP_FILE=$(mktemp "${EPIC_STATE_FILE}.tmp.XXXXXX")
                if jq --arg spec "$SPEC_NAME" '
                  .specs |= map(if .name == $spec then .status = "completed" else . end)
                ' "$EPIC_STATE_FILE" > "$TMP_FILE"; then
                    mv "$TMP_FILE" "$EPIC_STATE_FILE"
                else
                    rm -f "$TMP_FILE"
                fi
                echo "[ralph-specum] Updated epic '$EPIC_NAME_VAL': spec '$SPEC_NAME' marked completed" >&2
            fi
        fi
        "$SCRIPT_DIR/update-spec-index.sh" --quiet 2>/dev/null || true

        # --- Phase 4: Regression Sweep ---
        # After spec completion, re-run verification contracts for specs listed in
        # the dependency map of the completed spec's requirements.md.
        # Three tiers: local (dependency map) only. Invariants and full-suite
        # are left for nightly / final merge (out of scope for this hook).
        REQUIREMENTS_FILE="$CWD/$SPEC_PATH/requirements.md"
        if [ -f "$REQUIREMENTS_FILE" ]; then
            # Guard: skip sweep if REGRESSION_SWEEP_COMPLETE already appears after
            # the last ALL_TASKS_COMPLETE in the transcript. The transcript is
            # append-only, so without this check the sweep would re-trigger on
            # every subsequent stop, causing an infinite loop of sweep prompts.
            LAST_COMPLETE_LINE=$(grep -n 'ALL_TASKS_COMPLETE' "$TRANSCRIPT_PATH" 2>/dev/null | tail -1 | cut -d: -f1)
            if [ -n "$LAST_COMPLETE_LINE" ]; then
                SWEEP_ALREADY_DONE=$(tail -n +"$LAST_COMPLETE_LINE" "$TRANSCRIPT_PATH" 2>/dev/null \
                    | grep -cE '(^|\W)REGRESSION_SWEEP_COMPLETE(\W|$)' || echo "0")
            else
                SWEEP_ALREADY_DONE="0"
            fi

            if [ "$SWEEP_ALREADY_DONE" -gt 0 ]; then
                echo "[ralph-specum] Phase 4 regression sweep already completed, skipping" >&2
            else
                # Extract the Dependency map entries from the Verification Contract section
                DEP_SPECS=$(awk '
                    BEGIN {
                        in_vc = 0      # inside "Verification Contract" section
                        in_dep = 0     # currently collecting dependency map lines
                    }

                    # Enter the Verification Contract section
                    /^##[[:space:]]+Verification Contract/ {
                        in_vc = 1
                        next
                    }

                    # Any other top-level header ends the Verification Contract section
                    /^##[[:space:]]+/ {
                        if (in_vc) {
                            exit
                        }
                        next
                    }

                    {
                        # Ignore everything outside the Verification Contract section
                        if (!in_vc) {
                            next
                        }

                        # Start of dependency map line
                        if (!in_dep && /\*\*Dependency map\*\*:[[:space:]]*/) {
                            in_dep = 1
                            # Strip label and leading whitespace; keep any inline entries
                            sub(/.*\*\*Dependency map\*\*:[[:space:]]*/, "")
                            if (NF > 0) {
                                print
                            }
                            next
                        }

                        # While in dependency map, collect bullets and continuation lines
                        if (in_dep) {
                            # Blank lines are skipped but do not by themselves end the map
                            if ($0 ~ /^[[:space:]]*$/) {
                                next
                            }

                            # Safety: a new header also ends the dependency map
                            if ($0 ~ /^##[[:space:]]+/) {
                                exit
                            }

                            # Bullet items or indented continuation lines
                            if ($0 ~ /^[[:space:]]*[-*][[:space:]]+/ || $0 ~ /^[[:space:]]+[^\-*\t ]/) {
                                line = $0
                                # Strip leading whitespace and optional bullet marker
                                sub(/^[[:space:]]*[-*]?[[:space:]]*/, "", line)
                                print line
                                next
                            }

                            # A non-indented, non-bullet line ends the dependency map
                            if ($0 ~ /^[^[:space:]]/) {
                                in_dep = 0
                                next
                            }
                        }
                    }
                ' "$REQUIREMENTS_FILE" | tr ',' '\n' | sed 's/^[[:space:]]*//' | grep -v '^$' || true)

                if [ -n "$DEP_SPECS" ]; then
                    echo "[ralph-specum] Phase 4 regression sweep: found dependency map entries" >&2
                    SWEEP_LIST=""
                    while IFS= read -r dep; do
                        # dep may be a spec name or relative path — resolve to spec path
                        dep=$(echo "$dep" | sed 's/^- //' | tr -d '`')
                        # Try to find the spec directory matching the dep name
                        DEP_REQ="$CWD/specs/$dep/requirements.md"
                        if [ -f "$DEP_REQ" ]; then
                            SWEEP_LIST="${SWEEP_LIST}"$'\n'"- specs/$dep"
                        fi
                    done <<< "$DEP_SPECS"

                    if [ -n "$SWEEP_LIST" ]; then
                        STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
                        if [ "$STOP_HOOK_ACTIVE" != "true" ]; then
                            SWEEP_REASON=$(cat <<SWEEP_EOF
[ralph-specum] Regression sweep triggered by completion of: $SPEC_NAME

## Specs to sweep (from Dependency map)
$SWEEP_LIST

## Action
For each spec listed above:
1. Read its requirements.md Verification Contract
2. Delegate a [STORY-VERIFY] task to qa-engineer: verify only the Observable signals and Hard invariants
3. Emit VERIFICATION_PASS or VERIFICATION_FAIL per spec
4. Do NOT re-implement. Verification only.
5. After all sweeps complete, output REGRESSION_SWEEP_COMPLETE

## Critical
- Do NOT modify any source files
- Do NOT add new tasks to tasks.md
- If any sweep emits VERIFICATION_FAIL, treat as a new repair loop (Phase 3)
SWEEP_EOF
)
                            jq -n \
                              --arg reason "$SWEEP_REASON" \
                              --arg msg "Ralph-specum Phase 4: regression sweep for $SPEC_NAME dependencies" \
                              '{
                                "decision": "block",
                                "reason": $reason,
                                "systemMessage": $msg
                              }'
                            exit 0
                        fi
                    fi
                fi
            fi  # closes: if [ "$SWEEP_ALREADY_DONE" -gt 0 ]
        fi
        # --- End Phase 4 ---

        exit 0
    fi
    # Fallback: check last 20 lines for edge cases (very recent signal)
    if tail -20 "$TRANSCRIPT_PATH" 2>/dev/null | grep -qE '(^|\W)ALL_TASKS_COMPLETE(\W|$)'; then
        echo "[ralph-specum] ALL_TASKS_COMPLETE detected in transcript (tail-end)" >&2
        # Update epic state if this spec belongs to an epic
        EPIC_NAME_VAL=$(jq -r '.epicName // empty' "$STATE_FILE" 2>/dev/null || true)
        CURRENT_EPIC_FILE="$CWD/specs/.current-epic"
        if [ -n "$EPIC_NAME_VAL" ] && [ -f "$CURRENT_EPIC_FILE" ]; then
            EPIC_STATE_FILE="$CWD/specs/_epics/$EPIC_NAME_VAL/.epic-state.json"
            if [ -f "$EPIC_STATE_FILE" ]; then
                TMP_FILE=$(mktemp "${EPIC_STATE_FILE}.tmp.XXXXXX")
                if jq --arg spec "$SPEC_NAME" '
                  .specs |= map(if .name == $spec then .status = "completed" else . end)
                ' "$EPIC_STATE_FILE" > "$TMP_FILE"; then
                    mv "$TMP_FILE" "$EPIC_STATE_FILE"
                else
                    rm -f "$TMP_FILE"
                fi
                echo "[ralph-specum] Updated epic '$EPIC_NAME_VAL': spec '$SPEC_NAME' marked completed" >&2
            fi
        fi
        "$SCRIPT_DIR/update-spec-index.sh" --quiet 2>/dev/null || true
        exit 0
    fi

    # --- Phase 3: Repair Loop ---
    # Detect VERIFICATION_FAIL in transcript and activate repair mode.
    # Max 2 repair iterations per story before escalating to human.
    TRANSCRIPT_TAIL=$(tail -500 "$TRANSCRIPT_PATH" 2>/dev/null || true)
    # Only activate repair if the most recent verification signal is a FAIL.
    if echo "$TRANSCRIPT_TAIL" | grep -qE '(^|\W)VERIFICATION_(FAIL|PASS)(\W|$)'; then
        LAST_SIGNAL_LINE=$(echo "$TRANSCRIPT_TAIL" | grep -E '(^|\W)VERIFICATION_(FAIL|PASS)(\W|$)' | tail -1)
        if echo "$LAST_SIGNAL_LINE" | grep -qE '(^|\W)VERIFICATION_FAIL(\W|$)'; then
            REPAIR_ITER=$(jq -r '.repairIteration // 0' "$STATE_FILE" 2>/dev/null || echo "0")
            FAILED_STORY=$(jq -r '.failedStory // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
            ORIGIN_TASK=$(jq -r '.originTaskIndex // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
            MAX_REPAIR=2

            echo "[ralph-specum] VERIFICATION_FAIL detected | story: $FAILED_STORY | repair iter: $REPAIR_ITER/$MAX_REPAIR" >&2

            STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
            if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
                echo "[ralph-specum] stop_hook_active=true in repair loop, allowing stop" >&2
                exit 0
            fi

            if [ "$REPAIR_ITER" -ge "$MAX_REPAIR" ]; then
                # Escalate to human
                ESCALATE_REASON=$(cat <<ESCALATE_EOF
[ralph-specum] ESCALATION REQUIRED — Repair loop exhausted for: $FAILED_STORY

The verification for story '$FAILED_STORY' has failed $MAX_REPAIR times.
Automatic repair has been exhausted.

## What happened
- Story: $FAILED_STORY
- Origin task index: $ORIGIN_TASK
- Repair attempts: $REPAIR_ITER/$MAX_REPAIR

## Action required from human
1. Review $SPEC_PATH/requirements.md — Verification Contract for '$FAILED_STORY'
2. Review $SPEC_PATH/tasks.md — task at index $ORIGIN_TASK
3. Check $SPEC_PATH/.progress.md for failure details
4. Fix manually or clarify the spec
5. Reset repair state: update .ralph-state.json — set phase back to "execution",
   repairIteration to 0, remove failedStory and originTaskIndex
6. Resume with /ralph-specum:implement
ESCALATE_EOF
)
            jq -n \
              --arg reason "$ESCALATE_REASON" \
              --arg msg "Ralph-specum Phase 3: ESCALATION — repair exhausted for $FAILED_STORY" \
              '{
                "decision": "block",
                "reason": $reason,
                "systemMessage": $msg
              }'
            exit 0
        fi

        # Classify failure and trigger targeted repair
        NEXT_REPAIR=$((REPAIR_ITER + 1))
        REPAIR_REASON=$(cat <<REPAIR_EOF
[ralph-specum] Repair loop — attempt $NEXT_REPAIR/$MAX_REPAIR for story: $FAILED_STORY

## State
Spec: $SPEC_PATH | Failed story: $FAILED_STORY | Origin task index: $ORIGIN_TASK

## Action
1. Read $SPEC_PATH/requirements.md — Verification Contract for '$FAILED_STORY'
2. Read $SPEC_PATH/.progress.md — identify root cause of VERIFICATION_FAIL
3. Classify failure type:
   - impl_bug: implementation does not match the Observable signals
   - env_issue: environment/dependency problem (DB, service, config)
   - spec_ambiguity: the contract is unclear or contradictory
   - flaky: non-deterministic failure (timing, race condition)
4. If impl_bug: backtrack to origin task $ORIGIN_TASK in tasks.md, delegate
   a targeted fix to spec-executor. Do NOT re-implement unrelated tasks.
5. If env_issue: report the specific env problem and halt (set awaitingApproval=true)
6. If spec_ambiguity: propose a clarification to the Verification Contract and halt
7. If flaky: retry the verification once more via qa-engineer [STORY-VERIFY]
8. After fix: re-run qa-engineer [STORY-VERIFY] for '$FAILED_STORY' only
9. Update .ralph-state.json: increment repairIteration to $NEXT_REPAIR
10. On VERIFICATION_PASS: reset repair state (remove failedStory, repairIteration,
    originTaskIndex), resume normal execution from taskIndex
11. On VERIFICATION_FAIL again: this hook will escalate on next iteration

## Critical
- Surgical fix only — do NOT touch unrelated tasks or files
- Do NOT output ALL_TASKS_COMPLETE until repair resolves and normal flow resumes
REPAIR_EOF
)
        jq -n \
          --arg reason "$REPAIR_REASON" \
          --arg msg "Ralph-specum Phase 3: repair $NEXT_REPAIR/$MAX_REPAIR — $FAILED_STORY" \
          '{
            "decision": "block",
            "reason": $reason,
            "systemMessage": $msg
          }'
        exit 0
    fi
    fi  # closes: if echo "$LAST_SIGNAL_LINE" | grep -qE VERIFICATION_FAIL
    fi  # closes: if echo "$TRANSCRIPT_TAIL" | grep -qE VERIFICATION_(FAIL|PASS)
    # --- End Phase 3 ---
fi  # closes: if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]

# Validate state file is readable JSON
if ! jq empty "$STATE_FILE" 2>/dev/null; then
    REASON=$(cat <<EOF
ERROR: Corrupt state file at $SPEC_PATH/.ralph-state.json

Recovery options:
1. Reset state: /ralph-specum:implement (reinitializes from tasks.md)
2. Cancel spec: /ralph-specum:cancel
EOF
)

    jq -n \
      --arg reason "$REASON" \
      --arg msg "Ralph-specum: corrupt state file" \
      '{
        "decision": "block",
        "reason": $reason,
        "systemMessage": $msg
      }'
    exit 0
fi

# Read state
PHASE=$(jq -r '.phase // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
TASK_INDEX=$(jq -r '.taskIndex // 0' "$STATE_FILE" 2>/dev/null || echo "0")
TOTAL_TASKS=$(jq -r '.totalTasks // 0' "$STATE_FILE" 2>/dev/null || echo "0")
TASK_ITERATION=$(jq -r '.taskIteration // 1' "$STATE_FILE" 2>/dev/null || echo "1")
QUICK_MODE=$(jq -r '.quickMode // false' "$STATE_FILE" 2>/dev/null || echo "false")
NATIVE_SYNC=$(jq -r '.nativeSyncEnabled // true' "$STATE_FILE" 2>/dev/null || echo "true")

# Check global iteration limit
GLOBAL_ITERATION=$(jq -r '.globalIteration // 1' "$STATE_FILE" 2>/dev/null || echo "1")
MAX_GLOBAL=$(jq -r '.maxGlobalIterations // 100' "$STATE_FILE" 2>/dev/null || echo "100")

if [ "$GLOBAL_ITERATION" -ge "$MAX_GLOBAL" ]; then
    echo "[ralph-specum] ERROR: Maximum global iterations ($MAX_GLOBAL) reached. Review .progress.md for failure patterns." >&2
    echo "[ralph-specum] Recovery: fix issues manually, then run /ralph-specum:implement or /ralph-specum:cancel" >&2
    exit 0
fi

# Quick mode guard: block stop during ANY phase when quickMode is active
if [ "$QUICK_MODE" = "true" ] && [ "$PHASE" != "execution" ]; then
    STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
    if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
        echo "[ralph-specum] stop_hook_active=true in quick mode, allowing stop to prevent loop" >&2
        exit 0
    fi

    REASON=$(cat <<EOF
Quick mode active — do NOT stop. Continue spec phase: $PHASE for $SPEC_NAME.

You are running in quick mode. Do NOT stop, do NOT ask the user questions.
Continue generating artifacts for the current phase ($PHASE) and proceed to the next phase.
Make strong, opinionated decisions autonomously.
EOF
)
    jq -n \
      --arg reason "$REASON" \
      --arg msg "Ralph-specum quick mode: continue $PHASE phase" \
      '{
        "decision": "block",
        "reason": $reason,
        "systemMessage": $msg
      }'
    exit 0
fi

# Log current state
if [ "$PHASE" = "execution" ]; then
    echo "[ralph-specum] Session stopped during spec: $SPEC_NAME | Task: $((TASK_INDEX + 1))/$TOTAL_TASKS | Attempt: $TASK_ITERATION" >&2
fi

# Execution completion verification: cross-check state AND tasks.md
if [ "$PHASE" = "execution" ] && [ "$TASK_INDEX" -ge "$TOTAL_TASKS" ] && [ "$TOTAL_TASKS" -gt 0 ]; then
    TASKS_FILE="$CWD/$SPEC_PATH/tasks.md"
    if [ -f "$TASKS_FILE" ]; then
        UNCHECKED=$(grep -c '^\s*- \[ \]' "$TASKS_FILE" 2>/dev/null || echo "0")
        if [ "$UNCHECKED" -gt 0 ]; then
            echo "[ralph-specum] State says complete but tasks.md has $UNCHECKED unchecked items" >&2
            REASON=$(cat <<EOF
Tasks incomplete: state index ($TASK_INDEX) reached total ($TOTAL_TASKS), but tasks.md has $UNCHECKED unchecked items.

## Action Required
1. Read $SPEC_PATH/tasks.md and find unchecked tasks (- [ ])
2. Execute remaining unchecked tasks via spec-executor
3. Update .ralph-state.json totalTasks to match actual count
4. Only output ALL_TASKS_COMPLETE when every task in tasks.md is checked off
5. Do NOT add new tasks — complete existing ones only
EOF
)
            jq -n \
              --arg reason "$REASON" \
              --arg msg "Ralph-specum: $UNCHECKED unchecked tasks remain in tasks.md" \
              '{
                "decision": "block",
                "reason": $reason,
                "systemMessage": $msg
              }'
            exit 0
        fi
    fi
    # All tasks verified complete — allow stop
    echo "[ralph-specum] All tasks verified complete for $SPEC_NAME" >&2
    exit 0
fi

# Loop control: output continuation prompt if more tasks remain
if [ "$PHASE" = "execution" ] && [ "$TASK_INDEX" -lt "$TOTAL_TASKS" ]; then
    # Respect user approval gates (e.g. PR creation, manual review steps)
    AWAITING=$(jq -r '.awaitingApproval // false' "$STATE_FILE" 2>/dev/null || echo "false")
    if [ "$AWAITING" = "true" ]; then
        echo "[ralph-specum] awaitingApproval=true, allowing stop for user gate" >&2
        exit 0
    fi

    # Read recovery mode for prompt customization
    RECOVERY_MODE=$(jq -r '.recoveryMode // false' "$STATE_FILE" 2>/dev/null || echo "false")
    MAX_TASK_ITER=$(jq -r '.maxTaskIterations // 5' "$STATE_FILE" 2>/dev/null || echo "5")

    # Safety guard: prevent infinite re-invocation loop
    # If a stop event fires while already processing a stop-hook continuation,
    # re-blocking would cause infinite loops. Allow Claude to stop; the next
    # session start will detect remaining tasks via .ralph-state.json.
    # Claude Code sets stop_hook_active: true in Stop hook input when a stop
    # fires during an existing stop-hook continuation.
    STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
    if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
        echo "[ralph-specum] stop_hook_active=true, skipping continuation to prevent re-invocation loop" >&2
        exit 0
    fi

    # Extract current task block from tasks.md for inline continuation
    TASKS_FILE="$CWD/$SPEC_PATH/tasks.md"
    TASK_BLOCK=""
    if [ -f "$TASKS_FILE" ]; then
        # Extract task at TASK_INDEX (0-based) by counting unchecked+checked task lines
        # If TASK_INDEX exceeds number of tasks, awk outputs nothing (TASK_BLOCK stays empty)
        # and the coordinator falls back to reading tasks.md directly
        # Note: awk count variable starts at 0 (default) to match 0-based TASK_INDEX
        TASK_BLOCK=$(awk -v idx="$TASK_INDEX" '
            /^- \[[ x]\]/ {
                if (count == idx) { found=1; print; next }
                if (found) { exit }
                count++
            }
            found && /^  / { print; next }
            found && /^$/ { print; next }
            found && !/^  / && !/^$/ { exit }
        ' "$TASKS_FILE" | sed -e :a -e '/^[[:space:]]*$/{' -e '$d' -e N -e ba -e '}')
    fi

    # Parallel group detection: if current task has [P] marker, scan for consecutive [P] tasks and include all in continuation prompt
    IS_PARALLEL="false"
    if echo "$TASK_BLOCK" | head -1 | grep -q '\[P\]'; then
        IS_PARALLEL="true"
    fi

    # When parallel marker detected, scan for all consecutive [P] tasks from TASK_INDEX
    if [ "$IS_PARALLEL" = "true" ] && [ -f "$TASKS_FILE" ]; then
        PARALLEL_TASKS=$(awk -v idx="$TASK_INDEX" -v max_group=5 '
            /^- \[[ x]\]/ {
                if (count >= idx) {
                    if (/\[P\]/ && pcount < max_group) { found=1; pcount++; block=block $0 "\n"; next }
                    else if (found) { exit }
                }
                count++
            }
            found && /^  / { block=block $0 "\n"; next }
            found && /^$/ { block=block $0 "\n"; next }
            found && !/^  / && !/^$/ { exit }
            END { printf "%s", block }
        ' "$TASKS_FILE")
        if [ -n "$PARALLEL_TASKS" ]; then
            TASK_BLOCK="$PARALLEL_TASKS"
        fi
    fi

    # DESIGN NOTE: Prompt Duplication
    # This continuation prompt is intentionally abbreviated compared to implement.md.
    # - implement.md = full specification (source of truth for coordinator behavior)
    # - stop-watcher.sh = abbreviated resume prompt (minimal context for loop continuation)
    # This is an intentional design choice, not accidental duplication. The full
    # specification lives in implement.md; this prompt provides just enough context
    # for the coordinator to resume execution efficiently.

    # Build task section header and instructions based on parallel mode
    if [ "$IS_PARALLEL" = "true" ]; then
        TASK_HEADER="## Current Task Group (PARALLEL)"
        PARALLEL_INSTRUCTIONS="
PARALLEL: These are [P] tasks -- dispatch ALL in ONE message via Task tool. Each gets progressFile: .progress-task-\$INDEX.md. After all complete: merge progress, advance taskIndex past group."
    else
        TASK_HEADER="## Current Task"
        PARALLEL_INSTRUCTIONS=""
    fi

    REASON=$(cat <<STOP_WATCHER_REASON_EOF
Continue spec: $SPEC_NAME (Task $((TASK_INDEX + 1))/$TOTAL_TASKS, Iter $GLOBAL_ITERATION)

## State
Path: $SPEC_PATH | Index: $TASK_INDEX | Iteration: $TASK_ITERATION/$MAX_TASK_ITER | Recovery: $RECOVERY_MODE | NativeSync: $NATIVE_SYNC

$TASK_HEADER
$TASK_BLOCK
$PARALLEL_INSTRUCTIONS

## Resume
1. Read $SPEC_PATH/.ralph-state.json for current state
2. Native sync (if NativeSync != false): (a) if nativeTaskMap is empty, rebuild from tasks.md (TaskCreate all, store IDs in state), (b) TaskUpdate current task to in_progress with activeForm
3. Delegate the task above to spec-executor (or qa-engineer for [VERIFY])
4. On TASK_COMPLETE: verify, update state, advance. Then TaskUpdate task to completed (if NativeSync != false)
5. If taskIndex >= totalTasks: finalize all native tasks to completed (if NativeSync != false), read $SPEC_PATH/tasks.md to verify all [x], delete state file, output ALL_TASKS_COMPLETE

## Critical
- Delegate via Task tool - do NOT implement yourself
- Verify all 3 layers before advancing (see verification-layers.md)
- Do NOT push after every commit - batch pushes per phase or every 5 commits (see coordinator-pattern.md § 'Git Push Strategy')
- On failure: increment taskIteration, retry or generate fix task if recoveryMode
- On TASK_MODIFICATION_REQUEST: validate, insert tasks, update state (see coordinator-pattern.md § 'Modification Request Handler')
STOP_WATCHER_REASON_EOF
)

    SYSTEM_MSG="Ralph-specum iteration $GLOBAL_ITERATION | Task $((TASK_INDEX + 1))/$TOTAL_TASKS"
    if [ "$IS_PARALLEL" = "true" ]; then
        SYSTEM_MSG="$SYSTEM_MSG (PARALLEL GROUP)"
    fi

    jq -n \
      --arg reason "$REASON" \
      --arg msg "$SYSTEM_MSG" \
      '{
        "decision": "block",
        "reason": $reason,
        "systemMessage": $msg
      }'
fi

# Cleanup orphaned temp progress files (from interrupted parallel batches)
# Only remove files older than 60 minutes to avoid race conditions with active executors
find "$CWD/$SPEC_PATH" -name ".progress-task-*.md" -mmin +60 -delete 2>/dev/null || true

# Note: .progress.md and .ralph-state.json are preserved for loop continuation
# Use /ralph-specum:cancel to explicitly stop execution and cleanup state

exit 0
