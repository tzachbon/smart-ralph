---
generated: auto
---

# Requirements: Update Index on Spec Completion

## Goal

Guarantee the spec index (`specs/.index/index-state.json`) reflects completed specs by calling `update-spec-index.sh` from the stop-watcher hook when ALL_TASKS_COMPLETE is detected, removing reliance on the LLM coordinator.

## User Stories

### US-1: Reliable Index Update on Completion
**As a** developer using ralph-specum
**I want** the spec index to automatically update when a spec finishes executing
**So that** the index always reflects the true state of my specs without manual intervention

**Acceptance Criteria:**
- [ ] AC-1.1: When stop-watcher.sh detects ALL_TASKS_COMPLETE in transcript, `update-spec-index.sh --quiet` runs before exit
- [ ] AC-1.2: Index update failure does not prevent the stop-watcher from exiting cleanly (non-blocking, errors suppressed)
- [ ] AC-1.3: Both detection paths (primary 500-line check and fallback 20-line check) trigger the index update

### US-2: No Regression in Existing Behavior
**As a** developer
**I want** the hook change to not affect execution loop behavior
**So that** task continuation, quick mode, and error handling remain unchanged

**Acceptance Criteria:**
- [ ] AC-2.1: Stop-watcher still exits 0 after ALL_TASKS_COMPLETE detection (no change to exit behavior)
- [ ] AC-2.2: Existing implement.md Section 10 index update call remains (defense in depth, not removed)
- [ ] AC-2.3: Hook execution time increase is negligible (<1s, update-spec-index.sh runs fast)

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | Call `update-spec-index.sh --quiet` in stop-watcher.sh when ALL_TASKS_COMPLETE detected (primary path, line ~71) | High | Index updated after primary detection grep succeeds |
| FR-2 | Call `update-spec-index.sh --quiet` in stop-watcher.sh when ALL_TASKS_COMPLETE detected (fallback path, line ~78) | High | Index updated after fallback detection grep succeeds |
| FR-3 | Suppress errors from index update call (`2>/dev/null \|\| true`) | High | Hook exits cleanly even if update-spec-index.sh fails |
| FR-4 | Use `$SCRIPT_DIR` to resolve update-spec-index.sh path (same pattern as existing source statement) | High | Script found regardless of working directory |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | No hook latency regression | Execution time added | <1s |
| NFR-2 | Idempotency preserved | Multiple calls produce same result | Yes (update-spec-index.sh rebuilds from scratch) |

## Glossary
- **stop-watcher.sh**: Stop hook that controls the ralph-specum execution loop. Detects completion, outputs continuation prompts.
- **update-spec-index.sh**: Script that rebuilds `specs/.index/index-state.json` and `specs/.index/index.md` by scanning all spec directories.
- **ALL_TASKS_COMPLETE**: Terminal signal output by the implement.md coordinator when all tasks are done.
- **index-state.json**: Machine-readable JSON tracking all specs, their phases, and task progress.

## Out of Scope
- Changing the implement.md coordinator's index update call (keep as defense in depth)
- Adding index updates to other stop-watcher exit paths (e.g., corrupt state, awaiting approval)
- Adding index updates to the "all tasks verified complete" path (lines 183-185) -- that path already implies the coordinator ran and should have updated the index itself
- New hooks or hook types
- Changes to update-spec-index.sh itself

## Dependencies
- `update-spec-index.sh` must be in the same directory as `stop-watcher.sh` (already true: both in `plugins/ralph-specum/hooks/scripts/`)
- `path-resolver.sh` must be sourced before index update runs (already true: sourced at line 21)

## Assumptions
- The `$SCRIPT_DIR` variable is already set correctly in stop-watcher.sh (line 18) and points to the scripts directory containing both files
- `update-spec-index.sh --quiet` is safe to call at any point during the hook lifecycle since it rebuilds the index from scratch

## Success Criteria
- After any spec completes execution via the ralph-specum loop, `specs/.index/index-state.json` reflects the completed spec with phase "completed" -- regardless of whether the LLM coordinator remembered to call the update script
