---
spec: fork-ralph-wiggum
phase: requirements
created: 2026-02-14
---

# Requirements: Fix Stop Hook JSON Output Format

## Goal

Fix the ralph-specum execution loop by changing stop-watcher.sh output from plain text to JSON `{"decision":"block","reason":"..."}` format, which is the only way Claude Code Stop hooks can prevent Claude from stopping and re-inject continuation prompts.

## User Decisions

| Question | Answer |
|----------|--------|
| Primary users | Plugin developers AND marketplace consumers |
| Priority tradeoff | Speed of delivery -- get the loop working ASAP with minimal changes |
| Success criteria | Loop correctly re-invokes Claude, executes tasks sequentially until ALL_TASKS_COMPLETE |
| Approach | Fix-in-place, NOT a fork. No new files, no lib/ directory |
| Scope | Selective extraction -- only adopt the JSON output format pattern from Ralph Wiggum |

## User Stories

### US-1: Execution Loop Continuation

**As a** developer running `/ralph-specum:implement`
**I want** the stop hook to block Claude from stopping and re-inject the continuation prompt
**So that** tasks execute sequentially without manual intervention until ALL_TASKS_COMPLETE

**Acceptance Criteria:**
- [ ] AC-1.1: stop-watcher.sh outputs valid JSON with `"decision":"block"` when tasks remain (phase=execution, taskIndex < totalTasks)
- [ ] AC-1.2: JSON `reason` field contains the continuation prompt (spec name, task index, resume instructions)
- [ ] AC-1.3: JSON `systemMessage` field shows user-visible iteration status (e.g., "Ralph-specum iteration 3 | Task 2/5")
- [ ] AC-1.4: Claude receives the `reason` content and resumes execution without user interaction
- [ ] AC-1.5: When all tasks complete (taskIndex >= totalTasks), hook outputs nothing and exits 0 (Claude stops normally)

### US-2: Graceful Silent Exits

**As a** developer using the plugin
**I want** the stop hook to exit silently (no JSON output) when loop should NOT continue
**So that** Claude stops naturally when appropriate

**Acceptance Criteria:**
- [ ] AC-2.1: No stdout output when no state file exists
- [ ] AC-2.2: No stdout output when phase != "execution"
- [ ] AC-2.3: No stdout output when taskIndex >= totalTasks
- [ ] AC-2.4: No stdout output when ALL_TASKS_COMPLETE detected in transcript
- [ ] AC-2.5: No stdout output when plugin is disabled via settings
- [ ] AC-2.6: No stdout output when jq unavailable, empty input, or invalid JSON input

### US-3: Infinite Loop Prevention

**As a** developer running a long spec
**I want** the stop hook to check `stop_hook_active` from hook input
**So that** rapid re-invocation loops are prevented

**Acceptance Criteria:**
- [ ] AC-3.1: Hook reads `stop_hook_active` boolean from stdin JSON
- [ ] AC-3.2: When `stop_hook_active` is true AND `stop_hook_active` guard is relevant, hook respects existing continuation (does not double-block)
- [ ] AC-3.3: Existing max global iteration limit (`maxGlobalIterations`) still enforced

### US-4: Error Cases in JSON Format

**As a** developer debugging a failed spec
**I want** error messages (corrupt state, max iterations) output as JSON with `decision: "block"`
**So that** Claude receives error recovery instructions instead of silently failing

**Acceptance Criteria:**
- [ ] AC-4.1: Corrupt state file outputs JSON with `decision: "block"` and recovery instructions in `reason`
- [ ] AC-4.2: Max iterations exceeded outputs JSON with `decision: "block"` and recovery instructions in `reason`
- [ ] AC-4.3: `systemMessage` field contains user-visible error summary

### US-5: Plugin Conflict Resolution

**As a** marketplace consumer installing ralph-specum
**I want** no competing stop hooks from ralph-wiggum
**So that** only one loop controller fires per Stop event

**Acceptance Criteria:**
- [ ] AC-5.1: `ralph-wiggum@claude-plugins-official` removed from `.claude/settings.json`
- [ ] AC-5.2: Only `ralph-specum@smart-ralph` and `plugin-dev@claude-code-plugins` remain enabled

### US-6: Test Coverage Update

**As a** developer maintaining the plugin
**I want** bats tests updated to assert JSON output format
**So that** CI validates the new behavior

**Acceptance Criteria:**
- [ ] AC-6.1: Tests asserting `"Continue spec"` in plain text updated to assert JSON with `decision: "block"`
- [ ] AC-6.2: Tests asserting `"ERROR: Corrupt state file"` updated to assert JSON format
- [ ] AC-6.3: New test helper `assert_json_decision_block` (or equivalent) added to `setup.bash`
- [ ] AC-6.4: New test for `stop_hook_active` guard behavior
- [ ] AC-6.5: All 18+ existing tests pass with updated assertions
- [ ] AC-6.6: `bats tests/*.bats` passes locally

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | Continuation output uses `jq -n` to produce `{"decision":"block","reason":"...","systemMessage":"..."}` | P0 | stdout is valid JSON parseable by `jq`; contains all 3 fields |
| FR-2 | `reason` field contains abbreviated continuation prompt (spec name, task index, resume instructions) | P0 | `reason` includes spec name, task index, resume steps |
| FR-3 | `systemMessage` field contains user-visible status line | P0 | Shows iteration count and task progress |
| FR-4 | All silent exit paths remain unchanged (exit 0, no stdout) | P0 | No regression in 10+ silent exit scenarios |
| FR-5 | Corrupt state error output changed to JSON format | P1 | JSON with `decision: "block"`, recovery instructions in `reason` |
| FR-6 | Max iterations error output changed to JSON format | P1 | JSON with `decision: "block"`, recovery instructions in `reason` |
| FR-7 | Read `stop_hook_active` from hook input stdin | P1 | Parsed via `jq -r '.stop_hook_active // false'` |
| FR-8 | Remove `ralph-wiggum@claude-plugins-official` from `.claude/settings.json` | P0 | Entry removed, file remains valid JSON |
| FR-9 | Bump plugin version in `plugin.json` and `marketplace.json` | P0 | Both files show matching version > 3.1.1 |
| FR-10 | Update bats tests to assert JSON output | P0 | All tests pass with `bats tests/*.bats` |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Hook execution time | Wall clock time | < 2 seconds (excluding race condition sleep) |
| NFR-2 | Backward compatibility | Silent exit paths | Zero regressions in non-continuation paths |
| NFR-3 | JSON validity | `jq` parseable | All stdout output is valid JSON or empty |
| NFR-4 | Minimal diff | Lines changed in stop-watcher.sh | < 40 net new/changed lines |
| NFR-5 | CI green | bats tests + plugin version check | All workflows pass |

## Glossary

- **Stop hook**: Claude Code hook that fires when Claude finishes responding. Can output JSON to block stopping.
- **decision: "block"**: JSON field that prevents Claude from stopping and feeds `reason` as next instruction.
- **reason**: JSON field whose content is injected back into Claude as the continuation prompt.
- **systemMessage**: JSON field shown to user (not Claude) as a status notification.
- **stop_hook_active**: Boolean in hook input indicating Claude is already continuing from a previous stop hook block.
- **ALL_TASKS_COMPLETE**: Signal string output by the coordinator when all tasks are done, triggers loop termination.
- **Plain text stdout**: What stop-watcher.sh currently outputs. Only visible in verbose mode (Ctrl+O), not processed by Claude.

## Out of Scope

- Creating `plugins/ralph-specum/lib/` directory
- Forking or copying Ralph Wiggum files into this repo
- Changing `.ralph-state.json` schema or format
- Changing the coordinator prompt in `implement.md`
- Adopting Ralph Wiggum's `<promise>` tag transcript detection (current `ALL_TASKS_COMPLETE` approach is simpler)
- Adding Ralph Wiggum's `/ralph-loop` setup command
- Exit code 2 mechanism (does not work from plugins)
- Changing hook registration in `hooks.json`
- Changing `path-resolver.sh`

## Dependencies

- `jq` must be available at runtime (already a dependency; existing guard handles missing jq)
- Claude Code must support JSON `decision: "block"` from plugin hooks (confirmed working -- historical bugs #10412, #10875 are CLOSED)
- Bats test framework installed locally for test validation

## Success Criteria

- Running `/ralph-specum:implement` on a spec with tasks causes Claude to execute tasks sequentially without stopping
- Stop hook re-invokes Claude after each stop until ALL_TASKS_COMPLETE is detected
- `bats tests/*.bats` passes with zero failures
- No `ralph-wiggum@claude-plugins-official` in settings
- Plugin version bumped in both manifest files

## Unresolved Questions

- Should `stop_hook_active` check skip continuation entirely, or still continue but with reduced prompt? Research suggests checking it prevents infinite rapid re-invocation, but the exact guard logic needs design-phase decision.
- Should the `reason` field include the full current prompt content or a shorter version? Current abbreviated approach (lines 144-161) seems right for token efficiency; design phase should confirm.

## Next Steps

1. Approve requirements
2. Design phase: specify exact JSON output format, `stop_hook_active` guard logic, test helper API
3. Task breakdown: changes to stop-watcher.sh, test updates, settings cleanup, version bump
4. Implementation
