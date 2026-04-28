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
    # Detect VERIFICATION_FAIL or VERIFICATION_DEGRADED in transcript.
    # DEGRADED: MCP Playwright not available — block and escalate to human for install.
    # FAIL: implementation bug — activate repair loop (max 2 iterations).
    # Max 2 repair iterations per story before escalating to human.
    TRANSCRIPT_TAIL=$(tail -500 "$TRANSCRIPT_PATH" 2>/dev/null || true)
    # Only activate if the most recent verification signal is FAIL, PASS, or DEGRADED.
    if echo "$TRANSCRIPT_TAIL" | grep -qE '(^|\W)VERIFICATION_(FAIL|PASS|DEGRADED)(\W|$)'; then
        LAST_SIGNAL_LINE=$(echo "$TRANSCRIPT_TAIL" | grep -E '(^|\W)VERIFICATION_(FAIL|PASS|DEGRADED)(\W|$)' | tail -1)
        if echo "$LAST_SIGNAL_LINE" | grep -qE '(^|\W)VERIFICATION_DEGRADED(\W|$)'; then
            # DEGRADED is not a code bug — MCP Playwright is simply not installed.
            # spec-executor already emitted ESCALATE (reason: verification-degraded) for this.
            # If that ESCALATE is in the transcript, do NOT emit another escalation block —
            # that would cause double-escalation (both spec-executor and stop-watcher blocking).
            # Instead, allow the stop so the human sees only the single spec-executor escalation.
            if echo "$TRANSCRIPT_TAIL" | grep -qE '(^|\W)ESCALATE(\W|$)' && echo "$TRANSCRIPT_TAIL" | grep -qE 'verification-degraded'; then
                echo "[ralph-specum] DEGRADED + ESCALATE (verification-degraded) already in transcript — allowing stop (spec-executor handled)" >&2
                exit 0
            fi
            STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
            if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
                echo "[ralph-specum] stop_hook_active=true in DEGRADED handler, allowing stop" >&2
                exit 0
            fi
            DEGRADED_REASON=$(cat <<DEGRADED_EOF
[ralph-specum] ESCALATION REQUIRED — VERIFICATION_DEGRADED detected for: $SPEC_NAME

UI verification was skipped because @playwright/mcp is not installed.
The repair loop cannot fix a missing tool — human action is required.

## What happened
- qa-engineer emitted VERIFICATION_DEGRADED (Protocol B in mcp-playwright.skill.md)
- @playwright/mcp was not found on PATH
- UI interaction and visual assertions were NOT verified

## Action required from human
1. Install @playwright/mcp:
     npm install -g @playwright/mcp   (requires Node 18+)
   or add to project devDependencies:
     npm install --save-dev @playwright/mcp
2. Verify the binary is on PATH:
     npx --no-install @playwright/mcp --version
3. Ensure your MCP client config includes the server with --isolated --caps=testing
   (see mcp-playwright.skill.md § MCP Server Configuration)
4. Resume verification:
     /ralph-specum:implement
DEGRADED_EOF
)
            jq -n \
              --arg reason "$DEGRADED_REASON" \
              --arg msg "Ralph-specum Phase 3: ESCALATION — VERIFICATION_DEGRADED (MCP Playwright not installed)" \
              '{
                "decision": "block",
                "reason": $reason,
                "systemMessage": $msg
              }'
            exit 0
        elif echo "$LAST_SIGNAL_LINE" | grep -qE '(^|\W)VERIFICATION_FAIL(\W|$)'; then
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
4. Check $SPEC_PATH/design.md → Mock Boundary
   The declared double type may be architecturally incorrect for this component
   (e.g., "Real" for a component with circular dependencies that prevents real testing).
5. Fix manually or clarify the spec
6. Reset repair state: update .ralph-state.json — set phase back to "execution",
   repairIteration to 0, remove failedStory and originTaskIndex
7. Resume with /ralph-specum:implement
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
3. Check for structured category signal:
   - grep "category:" $SPEC_PATH/.progress.md | tail -1
   - If "category: test_quality" found → classify as test_quality (do NOT re-classify as impl_bug)
4. Classify failure type (skip if category: already determined above):
   - impl_bug: implementation does not match the Observable signals
   - env_issue: environment/dependency problem (DB, service, config)
   - spec_ambiguity: the contract is unclear or contradictory
   - flaky: non-deterministic failure (timing, race condition)
   - test_quality: qa-engineer detected mock-only tests, missing real imports, high mock/assertion ratio
5. If impl_bug: backtrack to origin task $ORIGIN_TASK in tasks.md, delegate
   a targeted fix to spec-executor. Do NOT re-implement unrelated tasks.
6. If env_issue: report the specific env problem and halt (set awaitingApproval=true)
7. If spec_ambiguity: propose a clarification to the Verification Contract and halt
8. If flaky: retry the verification once more via qa-engineer [STORY-VERIFY]
9. If test_quality: delegate a test-rewrite task (NOT implementation fix) to spec-executor,
   targeting the test file and fixing: real module imports, mock/assertion ratio, state-based assertions
   Note: Pass fix_type=test_quality in the task delivery so spec-executor knows it is a test rewrite.
10. After fix: re-run qa-engineer [STORY-VERIFY] for '$FAILED_STORY' only
11. Update .ralph-state.json: increment repairIteration to $NEXT_REPAIR
12. On VERIFICATION_PASS: reset repair state (remove failedStory, repairIteration,
    originTaskIndex), resume normal execution from taskIndex
13. On VERIFICATION_FAIL again: this hook will escalate on next iteration

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
    fi  # closes: if echo "$TRANSCRIPT_TAIL" | grep -qE VERIFICATION_(FAIL|PASS|DEGRADED)
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

# --- Role Boundaries: Field-Level Validation ---
# Validates state file fields against a baseline to detect role boundary violations.
# Phase 1 limitation: agent identity reported as "unknown" — we only flag
# agent-owned fields (owner != "coordinator") regardless of who changed them.

# Resolve baseline file path
BASELINE_FILE="$CWD/$SPEC_PATH/references/.ralph-field-baseline.json"

# Graceful degradation: if no baseline exists, skip validation
if [ ! -f "$BASELINE_FILE" ]; then
    echo "[ralph-specum] BASELINE_MISSING no baseline at $BASELINE_FILE; skipping field validation" >&2
    VALIDATION_SKIPPED=1
else
    # Validate baseline is valid JSON before proceeding
    if ! jq empty "$BASELINE_FILE" 2>/dev/null; then
        echo "[ralph-specum] BASELINE_CORRUPT invalid JSON in baseline at $BASELINE_FILE; skipping field validation" >&2
        VALIDATION_SKIPPED=1
    else
        VALIDATION_SKIPPED=0
    fi
fi

# Read state file with retry loop to mitigate jq+mv race condition
# (3 attempts with 1s delay between retries)
STATE_CONTENT=""
if [ $VALIDATION_SKIPPED -eq 0 ]; then
    RETRY_COUNT=0
    while [ $RETRY_COUNT -lt 3 ]; do
        if STATE_CONTENT=$(cat "$STATE_FILE" 2>/dev/null) && echo "$STATE_CONTENT" | jq empty 2>/dev/null; then
            break
        fi
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -lt 3 ]; then sleep 1; fi
    done

    if [ -z "$STATE_CONTENT" ]; then
        echo "[ralph-specum] BASELINE_RETRY_EXHAUSTED unable to read state file after 3 retries; skipping validation" >&2
        VALIDATION_SKIPPED=1
    fi
fi

# Perform field-level validation if baseline is available and valid
if [ $VALIDATION_SKIPPED -eq 0 ]; then
    (
        exec 202>"${BASELINE_FILE}.lock"
        flock -x 202 || exit 0

        # Iterate over each field defined in the baseline (flat JSON format)
        # Flat format: {"field": "string" | ["array"]} — values are owners directly
        FIELDS=$(jq -r 'keys[]' "$BASELINE_FILE" 2>/dev/null)

        for FIELD in $FIELDS; do
            # Extract baseline owner — value itself is the owner (string or array)
            BASELINE_OWNER=$(jq -r --arg f "$FIELD" '.[$f] // "unknown"' "$BASELINE_FILE" 2>/dev/null)
            # Derive baseline type from the actual baseline value (string | array)
            BASELINE_TYPE=$(jq -r --arg f "$FIELD" '.[$f] | type' "$BASELINE_FILE" 2>/dev/null)
            BASELINE_DEFAULT=""

            # Resolve the jq path for this field from state
            # Strip leading dot if present to avoid double-dot paths
            CLEAN_FIELD="${FIELD#.}"

            # Check if field exists in state file using getpath for nested path resolution
            if ! echo "$STATE_CONTENT" | jq --arg f "$CLEAN_FIELD" 'getpath(($f | split("."))) != null' 2>/dev/null | grep -q true; then
                echo "[ralph-specum] BASELINE_SKIP missing in state: $FIELD (owner=$BASELINE_OWNER)" >&2
                continue
            fi

            # Extract current state value type
            FIELD_VALUE_TYPE=$(echo "$STATE_CONTENT" | jq -r --arg f "$CLEAN_FIELD" 'getpath(($f | split("."))) | type' 2>/dev/null)

            # Type mismatch: baseline owner is a simple type (string=owner name)
            # but state value is structured (object/array) — baseline stores OWNER names,
            # not data values, so we skip validation for such fields.
            # Baseline arrays (multi-owner fields) fall through to coordinator check.
            case "$BASELINE_TYPE" in
                string|number|boolean)
                    if [ "$FIELD_VALUE_TYPE" = "object" ] || [ "$FIELD_VALUE_TYPE" = "array" ]; then
                        echo "[ralph-specum] BASELINE_SKIP type-mismatch: $FIELD (baseline=$BASELINE_TYPE, state=$FIELD_VALUE_TYPE)" >&2
                        continue
                    fi
                    ;;
            esac

            # Skip coordinator-owned fields — coordinator legitimately writes these
            case "$BASELINE_OWNER" in
                *coordinator*)
                    echo "[ralph-specum] BASELINE_SKIP coordinator-owned: $FIELD (owner=$BASELINE_OWNER)" >&2
                    continue
                    ;;
            esac

            # Agent-owned-only field changed or present — report boundary violation
            # In Phase 1, we report agent identity as "unknown"
            echo "[ralph-specum] BOUNDARY_VIOLATION field=$FIELD owner=$BASELINE_OWNER severity=HIGH agent=unknown" >&2
        done
    ) 202>"${BASELINE_FILE}.lock"
fi
# --- End Role Boundaries Validation ---

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


# Filesystem Health Check
check_filesystem_heartbeat() {
  local spec_dir="$1"
  local state_file="$2"
  local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # Write heartbeat file
  echo "heartbeat: $timestamp" > "$spec_dir/.ralph-heartbeat"

  # Read it back and verify content
  local content
  content=$(cat "$spec_dir/.ralph-heartbeat")
  if echo "$content" | grep -q "^heartbeat:"; then
    # Success — reset failure tracking AND set filesystemHealthy=true
    local tmp="${state_file}.tmp"
    jq \
      --arg now "$timestamp" \
      '.filesystemHealthy = true | .filesystemHealthFailures = 0 | .lastFilesystemCheck = $now' \
      "$state_file" > "$tmp" && mv "$tmp" "$state_file"
    echo "[ralph-specum] Filesystem heartbeat OK" >&2
    # SR-018: Cleanup heartbeat file on success (avoid stale file)
    rm -f "$spec_dir/.ralph-heartbeat"
    return 0
  fi

  # Failure — increment counter in state AND set filesystemHealthy=false
  local failures
  failures=$(jq -r '.filesystemHealthFailures // 0' "$state_file" 2>/dev/null || echo "0")
  failures=$((failures + 1))
  local tmp="${state_file}.tmp"
  jq --argjson f "$failures" --arg now "$timestamp" \
    '.filesystemHealthFailures = $f | .lastFilesystemCheck = $now | .filesystemHealthy = false' \
    "$state_file" > "$tmp" && mv "$tmp" "$state_file"

  echo "[ralph-specum] Filesystem heartbeat FAILED (attempt $failures)" >&2

  if [ "$failures" -eq 1 ]; then
    # 1st failure: warn, log to .progress.md (SR-008), continue
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] WARN: Filesystem heartbeat failed (1/$failures). Filesystem may be read-only." >> "$spec_dir/.progress.md" 2>/dev/null || true
    return 0
  elif [ "$failures" -eq 2 ]; then
    # 2nd failure: escalate, log to .progress.md, block
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR: Filesystem heartbeat failed (2/2). Filesystem is likely read-only." >> "$spec_dir/.progress.md" 2>/dev/null || true
    local recovery_instructions='
## Recovery
1. Check filesystem: mount | grep "$(df "$spec_dir" | tail -1 | awk \"{print \\$1}\")"
2. If read-only: remount rw: sudo mount -o remount,rw /path/to/mount
3. Or resume with /ralph-specum:cancel and re-run in a writable environment'
    printf '{"decision":"block","reason":"Filesystem heartbeat failed 2nd time — filesystem may be degraded","filesystemHealthFailures":%d,"spec":"%s","recoveryInstructions":"%s"}\n' "$failures" "$SPEC_NAME" "$(echo "$recovery_instructions" | tr '\n' ' ' | sed 's/  */ /g')"
    exit 0
  else
    # 3rd+ failure: full block and exit
    printf '{"decision":"block","reason":"Filesystem heartbeat failed %d consecutive times — full filesystem block","filesystemHealthFailures":%d,"spec":"%s"}\n' "$failures" "$failures" "$SPEC_NAME"
    exit 0
  fi
}


# Circuit Breaker Check
check_circuit_breaker() {
  local state_file="$1"
  local spec_name="$2"

  # Read circuitBreaker state (default: closed)
  local cb_state=$(jq -r '.circuitBreaker.state // "closed"' "$state_file")

  # If already open, block
  if [ "$cb_state" = "open" ]; then
    printf '{"decision":"block","reason":"Circuit breaker OPEN — manual reset required","spec":"%s"}\n' "$spec_name"
    exit 0
  fi

  # Read failure counts
  local max_failures=$(jq -r '.circuitBreaker.maxConsecutiveFailures // 5' "$state_file")
  local consec_failures=$(jq -r '.circuitBreaker.consecutiveFailures // 0' "$state_file")
  local max_session=$(jq -r '.circuitBreaker.maxSessionSeconds // 172800' "$state_file")
  local session_start=$(jq -r '.circuitBreaker.sessionStartTime // ""' "$state_file")

  # Check consecutive failures
  # NOTE: State write is intentionally REMOVED here (SR-005: single-writer principle).
  # The coordinator (implement.md) owns state writes. stop-watcher.sh only BLOCKS.
  if [ "$consec_failures" -ge "$max_failures" ] 2>/dev/null; then
    printf '{"decision":"block","reason":"Consecutive failures exceeded","consecutiveFailures":%d,"maxConsecutiveFailures":%d,"spec":"%s"}\n' "$consec_failures" "$max_failures" "$spec_name"
    exit 0
  fi

  # Check session timeout
  # SR-016: sessionStartTime is now ISO 8601 string (not epoch integer)
  if [ -n "$session_start" ]; then
    local start_epoch=$(date -u -d "$session_start" +%s 2>/dev/null || echo 0)
    local now_epoch=$(date -u +%s)
    local session_elapsed=$((now_epoch - start_epoch))
    if [ "$session_elapsed" -ge "$max_session" ] 2>/dev/null; then
      printf '{"decision":"block","reason":"Session timeout exceeded","sessionElapsedSeconds":%d,"maxSessionSeconds":%d,"spec":"%s"}\n' "$session_elapsed" "$max_session" "$spec_name"
      exit 0
    fi
  fi
}


# CI Command Discovery
discover_ci_commands() {
  local spec_dir="$1"
  local tmpfile
  tmpfile=$(mktemp)

  # Scan .github/workflows/*.yml for "- run:" command lines
  if [ -d "$spec_dir/.github/workflows" ]; then
    for wf in "$spec_dir/.github/workflows"/*.yml; do
      [ -f "$wf" ] || continue
      # Extract content after "- run:" from each workflow file
      { grep -E '^\s+-\s+run:' "$wf" 2>/dev/null \
          | sed -E 's/^[[:space:]]*-[[:space:]]+run:[[:space:]]*//' \
          | while IFS= read -r line; do
              [ -z "$line" ] && continue
              # Skip YAML block scalar indicators and comments
              case "$line" in
                \#*|"|"*) continue ;;
              esac
              line=$(echo "$line" | sed 's/[[:space:]]*$//')
              [ -z "$line" ] && continue
              echo "$line"
            done; } >> "$tmpfile"
    done
  fi

  # Scan tests/*.bats for test commands
  if [ -d "$spec_dir/tests" ]; then
    for bats_file in "$spec_dir/tests"/*.bats; do
      [ -f "$bats_file" ] || continue
      # Extract test runner invocations (e.g., "bats tests/", "test/unit.sh")
      grep -E '^\s*(bats|test|./tests/)' "$bats_file" 2>/dev/null \
        | grep -v '^\s*#' \
        | grep -v '^\s*local ' \
        | head -5 \
        | sed 's/^[[:space:]]*//' \
        | sed 's/[[:space:]]*$//' \
        | grep -v '^$' \
        >> "$tmpfile"
    done
  fi

  # Deduplicate and return as JSON array
  if [ -s "$tmpfile" ]; then
    jq -R -n '[inputs | select(length > 0)] | unique' < "$tmpfile"
  else
    echo '[]'
  fi

  rm -f "$tmpfile"
}

# CI drift snapshot check
check_ci_drift() {
  local state_file="$1"

  # Read ciCommands array from state file (default: empty)
  local ci_commands
  ci_commands=$(jq -r '.ciCommands // [] | .[]' "$state_file" 2>/dev/null || true)
  if [ -z "$ci_commands" ]; then
    printf '{"drift":false,"commands":[],"baseline":{},"current":{},"spec":"%s"}\n' "$(basename "$(dirname "$state_file")")"
    return 0
  fi

  # Resolve baseline file path
  local spec_dir
  spec_dir=$(dirname "$state_file")
  local baseline_file="$spec_dir/.ci-ci-drift-baseline.json"

  # Run each CI command and record pass/fail
  local current_results=""
  local cmd_count=0
  while IFS= read -r cmd; do
    [ -z "$cmd" ] && continue
    cmd_count=$((cmd_count + 1))
    local cmd_hash
    cmd_hash=$(echo "$cmd" | jq -R -s 'sha256sum | split(" ")[0]')
    local start_time
    start_time=$(date +%s%N 2>/dev/null || date +%s)
    set +e
    # SR-010: Replace eval with bash -c to avoid injection risk
    bash -c "$cmd" > /dev/null 2>&1
    local exit_code=$?
    set -e
    local end_time
    end_time=$(date +%s%N 2>/dev/null || date +%s)
    local status="pass"
    if [ "$exit_code" -ne 0 ]; then
      status="fail"
    fi
    if [ -n "$current_results" ]; then
      current_results="$current_results,"
    fi
    current_results="${current_results}\"${cmd_hash}\":\"${status}\""
  done <<< "$ci_commands"

  # Read baseline if it exists
  local baseline_json="{}"
  if [ -f "$baseline_file" ]; then
    baseline_json=$(cat "$baseline_file")
  fi

  # Compare against baseline and compute drift
  # SR-011: Use jq --arg instead of string concatenation for JSON safety
  local drift=false
  local drifted_json="{}"
  for cmd_hash in $(echo "{${current_results}}" | jq -r 'keys[]' 2>/dev/null); do
    local baseline_status
    baseline_status=$(echo "$baseline_json" | jq -r --arg h "$cmd_hash" '.[$h] // "unknown"' 2>/dev/null)
    local current_status
    current_status=$(echo "{${current_results}}" | jq -r --arg h "$cmd_hash" '.[$h]' 2>/dev/null)
    if [ "$baseline_status" != "unknown" ] && [ "$baseline_status" != "$current_status" ]; then
      drift=true
      # Use jq --arg for safe JSON string escaping (SR-011)
      drifted_json=$(echo "$drifted_json" | jq \
        --arg h "$cmd_hash" \
        --arg bs "$baseline_status" \
        --arg cs "$current_status" \
        '. + {($h): {"baseline": $bs, "current": $cs}}')
    fi
  done

  # Persist baseline for next comparison
  printf '{%s}' "$current_results" > "$baseline_file" 2>/dev/null || true

  # Return drift result as JSON
  local spec_name
  spec_name=$(basename "$(dirname "$state_file")")
  jq -n \
    --argjson drift "$drift" \
    --argjson commands "$(echo "[$ci_commands]" | jq -R -s 'split("\n") | map(select(length > 0))')" \
    --argjson baseline "$baseline_json" \
    --argjson current "{${current_results}}" \
    --argjson drifted "$drifted_json" \
    --arg spec "$spec_name" \
    '{
      drift: $drift,
      commands: $commands,
      baseline: $baseline,
      current: $current,
      drifted: $drifted,
      spec: $spec
    }'
}
