---
spec: speckit-stop-hook
phase: requirements
created: 2026-02-14
generated: auto
---

# Requirements: speckit-stop-hook

## Summary

Remove ralph-speckit's dependency on the external ralph-loop plugin by upgrading the stop-watcher to a self-contained JSON-outputting loop controller and updating implement.md/cancel.md to work without external skills.

## User Stories

### US-1: Self-contained execution loop

As a speckit user, I want the execution loop to be self-contained so that I don't need to install the ralph-loop plugin separately.

**Acceptance Criteria**:
- AC-1.1: Running `/speckit:implement` starts execution without invoking `ralph-loop:ralph-loop` skill
- AC-1.2: Stop hook outputs `{decision: "block", reason: ..., systemMessage: ...}` JSON when tasks remain
- AC-1.3: Stop hook exits 0 silently when all tasks are complete
- AC-1.4: Loop continues automatically until `ALL_TASKS_COMPLETE` or max iterations reached

### US-2: Robust loop control

As a speckit user, I want the stop hook to handle edge cases gracefully so that execution doesn't get stuck or loop infinitely.

**Acceptance Criteria**:
- AC-2.1: Corrupt state file outputs JSON error with recovery options
- AC-2.2: Race condition handled via mtime check (wait if state modified <2s ago)
- AC-2.3: `ALL_TASKS_COMPLETE` detected in transcript to prevent re-invocation after completion
- AC-2.4: `stop_hook_active` guard prevents infinite re-invocation loops
- AC-2.5: Global iteration limit (maxGlobalIterations) enforced with stderr error

### US-3: Settings support

As a speckit user, I want to disable the stop hook via a settings file so that I can control when the loop controller is active.

**Acceptance Criteria**:
- AC-3.1: `.claude/ralph-speckit.local.md` with `enabled: false` disables the stop hook
- AC-3.2: Missing or `enabled: true` settings file allows normal operation

### US-4: Self-contained cancellation

As a speckit user, I want `/speckit:cancel` to work without external plugins so that I can stop execution cleanly.

**Acceptance Criteria**:
- AC-4.1: Cancel command deletes `.speckit-state.json` without invoking `ralph-wiggum:cancel-ralph`
- AC-4.2: Cancel command preserves `.progress.md`
- AC-4.3: Cancel displays state summary before cleanup

### US-5: Implement command outputs coordinator prompt directly

As a speckit user, I want `/speckit:implement` to output the coordinator prompt directly instead of writing a file and invoking ralph-loop.

**Acceptance Criteria**:
- AC-5.1: implement.md no longer references ralph-loop skill or `.coordinator-prompt.md` file
- AC-5.2: Coordinator prompt output directly in the conversation
- AC-5.3: Stop hook handles loop continuation (not ralph-loop)

## Functional Requirements

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| FR-1 | Stop hook outputs JSON `{decision, reason, systemMessage}` when `phase=execution && taskIndex < totalTasks` | Must | US-1 |
| FR-2 | Stop hook reads `.specify/.current-feature` and `.specify/specs/$FEATURE/.speckit-state.json` | Must | US-1 |
| FR-3 | Stop hook checks settings file `.claude/ralph-speckit.local.md` for `enabled` flag | Should | US-3 |
| FR-4 | Stop hook handles corrupt JSON with structured error output | Must | US-2 |
| FR-5 | Stop hook checks state file mtime and waits if modified <2s ago | Must | US-2 |
| FR-6 | Stop hook detects `ALL_TASKS_COMPLETE` in transcript (500-line primary, 20-line fallback) | Must | US-2 |
| FR-7 | Stop hook checks `stop_hook_active` to prevent re-invocation loops | Must | US-2 |
| FR-8 | Stop hook enforces `globalIteration >= maxGlobalIterations` limit | Must | US-2 |
| FR-9 | implement.md outputs coordinator prompt directly (no ralph-loop skill) | Must | US-5 |
| FR-10 | implement.md removes "Ralph Loop Dependency Check" section | Must | US-5 |
| FR-11 | implement.md removes `.coordinator-prompt.md` file writing | Must | US-5 |
| FR-12 | cancel.md deletes state file directly (no `ralph-wiggum:cancel-ralph`) | Must | US-4 |
| FR-13 | State schema allows `additionalProperties` for forward compatibility | Should | US-1 |
| FR-14 | Version bump to 1.0.0 in plugin.json and marketplace.json | Must | All |
| FR-15 | JSON continuation prompt includes abbreviated coordinator resume instructions | Must | US-1 |

## Non-Functional Requirements

| ID | Requirement | Category |
|----|-------------|----------|
| NFR-1 | Stop hook must exit within 3s in all code paths | Performance |
| NFR-2 | All JSON output must be valid (parseable by jq) | Reliability |
| NFR-3 | Backwards-compatible with existing `.speckit-state.json` files missing new fields | Compatibility |
| NFR-4 | Tests must cover all code paths in new stop-watcher | Quality |

## Out of Scope

- Path resolver / multi-directory support for speckit
- SessionStart hook for speckit (can be added later)
- Changes to speckit agents (spec-executor, qa-engineer, etc.)
- Changes to speckit start.md, status.md, switch.md commands

## Dependencies

- jq must be available on PATH
- Existing speckit directory structure (`.specify/`) unchanged
- Existing speckit state file schema (`.speckit-state.json`) extended but compatible
