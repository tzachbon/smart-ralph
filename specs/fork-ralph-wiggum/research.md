---
spec: fork-ralph-wiggum
phase: research
created: 2026-02-14
---

# Research: fork-ralph-wiggum

## Executive Summary

Ralph Wiggum's loop mechanism relies on a **Stop hook that outputs `{"decision": "block", "reason": "<prompt>"}` as JSON to stdout** -- this is the standard Claude Code API for preventing Claude from stopping and re-injecting a continuation prompt. The current stop-watcher.sh outputs plain text to stdout, which appears in the transcript but is NOT processed as a blocking decision. The fix is straightforward: change stop-watcher.sh to output the correct JSON format. A full fork of Ralph Wiggum is likely unnecessary -- only the JSON output format change is needed.

## Critical Discovery: Why the Current Approach Fails

### Root Cause (Verified via Official Docs)

The current `stop-watcher.sh` outputs a plain text continuation prompt via `cat <<EOF`:

```text
Continue spec: test-spec (Task 1/5, Iter 1)
## State
Path: specs/test-spec | Index: 0 | ...
```

Per Claude Code's hook documentation, **plain text stdout on exit 0 is only shown in verbose mode (Ctrl+O)** and is NOT fed back to Claude for most hook events. For Stop hooks specifically, the hook must output a **JSON object** with `decision: "block"` and a `reason` field to prevent Claude from stopping and provide continuation instructions.

### What Ralph Wiggum Does Correctly

The Ralph Wiggum `stop-hook.sh` (line ~170) outputs:

```bash
jq -n \
  --arg prompt "$PROMPT_TEXT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'
```

This is the correct format per official docs. The `reason` field content is fed back to Claude as continuation instructions.

### Key Difference

| Aspect | Ralph Wiggum (works) | Current stop-watcher.sh (broken) |
|--------|---------------------|----------------------------------|
| stdout format | JSON `{"decision":"block","reason":"..."}` | Plain text continuation prompt |
| Exit code | 0 | 0 |
| Effect | Claude blocked from stopping, receives `reason` as next instruction | Text shown in verbose mode only, Claude stops normally |

## External Research

### Ralph Wiggum Plugin Architecture

**Source**: [anthropics/claude-code/plugins/ralph-wiggum](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum)

The plugin has 4 files:

| File | Lines | Purpose |
|------|-------|---------|
| `.claude-plugin/plugin.json` | 9 | Plugin manifest (name, version, author) |
| `commands/ralph-loop.md` | ~20 | Command that runs `setup-ralph-loop.sh` to create state file |
| `scripts/setup-ralph-loop.sh` | ~203 | Parses args, creates `.claude/ralph-loop.local.md` state file |
| `hooks/stop-hook.sh` | ~170 | **Core mechanism**: reads state, reads transcript, checks completion, outputs JSON block decision |
| `hooks/hooks.json` | 15 | Registers Stop hook |
| `commands/cancel-ralph.md` | ~15 | Deletes state file to stop loop |

### Stop Hook JSON Output Format (Official Docs)

**Source**: [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)

For Stop hooks, the JSON output supports:

| Field | Description |
|-------|-------------|
| `decision` | `"block"` prevents Claude from stopping. Omit to allow stop |
| `reason` | **Required** when blocking. Content is fed to Claude as continuation instruction |
| `continue` | Boolean, default `true`. If `false`, overrides everything and forces Claude to stop |
| `systemMessage` | Warning message shown to user (not Claude) |
| `stopReason` | Message when `continue: false` (shown to user, not Claude) |

### Two Continuation Mechanisms (from hook architecture research)

Claude Code Stop hooks support two approaches -- **must choose one, not both**:

| Mechanism | Exit Code | Output Channel | Works from Plugins? |
|-----------|-----------|----------------|---------------------|
| JSON `decision: "block"` | 0 | stdout (JSON) | YES (used by Ralph Wiggum) |
| Exit code 2 | 2 | stderr (text) | **NO** - known bug [#10412](https://github.com/anthropics/claude-code/issues/10412) |

Priority order: `continue: false` > `decision: "block"` (JSON) > exit code 2

**Critical**: Exit code 2 does NOT work from plugin hooks (only from `.claude/hooks/`). We MUST use the JSON approach.

### `stop_hook_active` Guard

The Stop hook input includes `stop_hook_active: true` when Claude is already continuing due to a stop hook. This is the infinite loop prevention mechanism. Current stop-watcher.sh does NOT check this field -- it should.

### Known Plugin Hook Bugs (Historical)

**Sources**: [Issue #10412](https://github.com/anthropics/claude-code/issues/10412), [Issue #10875](https://github.com/anthropics/claude-code/issues/10875)

There were bugs where plugin-installed hooks didn't properly capture stdout JSON. These issues are now marked **CLOSED/COMPLETED**. The official Ralph Wiggum plugin (shipped by Anthropic) uses plugin hooks successfully, confirming the fix is in production.

### Claude Code Stop Hook Input

The Stop hook receives on stdin:

```json
{
  "session_id": "...",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/project/path",
  "permission_mode": "default",
  "hook_event_name": "Stop",
  "stop_hook_active": true
}
```

The `stop_hook_active` field is `true` when Claude is already continuing from a previous stop hook block. This is important to prevent infinite loops.

## Codebase Analysis

### Current Stop-Watcher.sh Architecture

File: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` (172 lines)

Already implements:
- Reading hook input from stdin (JSON parsing with jq)
- Path resolution via `path-resolver.sh`
- Plugin enabled/disabled check
- State file reading and validation
- ALL_TASKS_COMPLETE transcript detection
- Corrupt state file handling
- Global iteration limit check
- Race condition safeguard (2-second wait on recent state file modification)
- Orphaned temp file cleanup
- Recovery mode awareness

**Only missing**: JSON decision output format. Currently outputs plain text via `cat <<EOF`.

### Current State File Location

State file: `$SPEC_PATH/.ralph-state.json` (per-spec, in spec directory)
Ralph Wiggum state: `.claude/ralph-loop.local.md` (global, in .claude directory)

These serve different purposes and both can coexist.

### Existing Bats Tests

3 test files with comprehensive coverage:
- `tests/stop-hook.bats` -- 18 tests for stop-watcher.sh
- `tests/state-management.bats` -- state file operations
- `tests/integration.bats` -- integration tests

Tests expect:
- Exit code 0 in all cases
- Plain text continuation prompt in stdout (e.g., `assert_output_contains "Continue spec"`)
- These tests will need updating to expect JSON output format

### Plugin Configuration (CONFLICT DETECTED)

`.claude/settings.json` shows `ralph-wiggum@claude-plugins-official` is currently enabled alongside `ralph-specum@smart-ralph`. This means **BOTH stop hooks fire on every Stop event** -- which WILL cause conflicts. The ralph-wiggum stop hook will try to read its own state (`.claude/ralph-loop.local.md`) while ralph-specum's stop-watcher reads `.ralph-state.json`. If ralph-wiggum's state doesn't exist, it exits silently -- but this is a source of potential issues and should be cleaned up by removing `ralph-wiggum@claude-plugins-official` from settings.

### Hooks Registration

`plugins/ralph-specum/hooks/hooks.json` registers Stop and SessionStart hooks. This is correct and will continue to work.

## Files to Extract from Ralph Wiggum

### Minimal approach (RECOMMENDED)

**No files need to be extracted.** The fix is to change the output format of the existing `stop-watcher.sh` from plain text to JSON.

Specifically, change lines 144-161 from:

```bash
cat <<EOF
Continue spec: $SPEC_NAME (Task $((TASK_INDEX + 1))/$TOTAL_TASKS, Iter $GLOBAL_ITERATION)
...
EOF
```

To:

```bash
jq -n \
  --arg reason "Continue spec: $SPEC_NAME ... [coordinator instructions]" \
  --arg msg "Ralph-specum iteration $GLOBAL_ITERATION | Task $((TASK_INDEX + 1))/$TOTAL_TASKS" \
  '{
    "decision": "block",
    "reason": $reason,
    "systemMessage": $msg
  }'
```

### Optional patterns to adopt from Ralph Wiggum

| Pattern | Description | Recommendation |
|---------|-------------|----------------|
| Completion promise via transcript | Ralph Wiggum reads transcript JSONL, parses last assistant message, checks for `<promise>` tags | Not needed -- current approach checks for `ALL_TASKS_COMPLETE` in transcript which is simpler |
| Iteration tracking in state file | Ralph Wiggum tracks iteration in `.claude/ralph-loop.local.md` | Already have `globalIteration` in `.ralph-state.json` |
| `stop_hook_active` check | Ralph Wiggum doesn't check this, but docs recommend it | Should add to prevent infinite rapid re-invocation |
| Setup command | `/ralph-loop` creates state file | Not needed -- `/ralph-specum:implement` already creates `.ralph-state.json` |

## How the Loop Mechanism Works (Technical)

1. User runs `/ralph-specum:implement`
2. `implement.md` creates `.ralph-state.json` and outputs coordinator prompt
3. Claude processes coordinator prompt, delegates tasks via Task tool
4. Claude finishes responding -> Stop hook fires
5. `stop-watcher.sh` reads stdin JSON, resolves spec path, reads state
6. **If tasks remain**: output `{"decision": "block", "reason": "...continuation prompt..."}` -> Claude receives the reason and continues working
7. **If all done**: output nothing (or `exit 0` silently) -> Claude stops

Step 6 is what's currently broken (plain text instead of JSON).

## Integration Plan

### Approach: Fix-in-place (not a fork)

Rather than creating `plugins/ralph-specum/lib/` with forked files, the fix is to modify the existing `stop-watcher.sh` to output the correct JSON format. This is simpler, maintains the existing test infrastructure, and avoids unnecessary code duplication.

### Changes Required

| File | Change |
|------|--------|
| `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` | Change continuation output from plain text to `{"decision":"block","reason":"..."}` JSON format |
| `tests/stop-hook.bats` | Update assertions to expect JSON output instead of plain text |
| `tests/helpers/setup.bash` | May need helper to parse JSON output |

### Optional Enhancements (from Ralph Wiggum patterns)

| Enhancement | Value | Effort |
|-------------|-------|--------|
| Add `stop_hook_active` check | Prevents rapid re-invocation loops | Low |
| Add `systemMessage` field | Shows user-visible iteration status | Low |
| Move error messages to JSON format | Consistent output format | Low |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| JSON format change breaks existing behavior | Low | Medium | Comprehensive bats tests already exist; update them first |
| Plugin hook stdout not captured | Low | High | Historical bug is fixed; Ralph Wiggum official plugin works via same mechanism |
| `stop_hook_active` infinite loop | Medium | Medium | Add check for `stop_hook_active` field from hook input |
| Conflict with ralph-wiggum plugin | Medium | Low | Remove `ralph-wiggum@claude-plugins-official` from `.claude/settings.json` since we're self-containing |
| Continuation prompt too large for JSON | Low | Low | Keep prompt concise; current abbreviated format is fine |

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | **High** | Single-line format change; mechanism proven by official plugin |
| Effort Estimate | **S** | Modify 1 script, update tests. No new files needed |
| Risk Level | **Low** | Well-understood mechanism with official documentation |
| Test Coverage | **High** | 18 existing bats tests; CI runs on push |

## Related Specs

| Spec | Relevance | Relationship | mayNeedUpdate |
|------|-----------|--------------|---------------|
| implement-ralph-wiggum | HIGH | Added ralph-wiggum as dependency. This spec undoes that dependency by fixing the underlying issue | NO |
| remove-ralph-wiggum | HIGH | Removed ralph-wiggum but didn't fix the JSON output format. This completes that work | NO |
| return-ralph-wrigum | MEDIUM | Empty spec, likely abandoned in favor of this one | NO |
| iterative-failure-recovery | LOW | Uses the execution loop; will benefit from it working | NO |
| parallel-task-execution | LOW | Uses Task tool within the loop; compatible | NO |

## Quality Commands

| Type | Command | Source |
|------|---------|--------|
| Unit Test | `bats tests/*.bats` | `.github/workflows/bats-tests.yml` |
| Plugin Version Check | CI workflow | `.github/workflows/plugin-version-check.yml` |
| Spec File Check | CI workflow | `.github/workflows/spec-file-check.yml` |
| Lint | Not found | -- |
| TypeCheck | Not found | -- |
| Build | Not found | -- |

**Local CI**: `bats tests/*.bats`

## Recommendations for Requirements

1. **Fix JSON output format** in `stop-watcher.sh` -- change `cat <<EOF` plain text to `jq -n` JSON with `decision: "block"` and `reason` field
2. **Add `stop_hook_active` guard** to prevent rapid re-invocation if Claude is already in a continuation loop
3. **Update bats tests** to assert JSON output format instead of plain text
4. **Remove `ralph-wiggum@claude-plugins-official`** from `.claude/settings.json` to avoid conflicting stop hooks
5. **Do NOT create `lib/` directory** -- the forked-files approach is unnecessary; fix-in-place is simpler and better
6. **Bump plugin version** to reflect the change

## Open Questions

1. Should the `reason` field contain the full coordinator prompt or an abbreviated version? (Current abbreviated approach seems right for token efficiency)
2. Should we also emit JSON for error cases (corrupt state, max iterations) to keep output format consistent?
3. Is the `systemMessage` field worth adding for user-visible iteration status?

## Sources

- [Official Ralph Wiggum Plugin (GitHub)](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum)
- [Claude Code Hooks Reference (Official Docs)](https://code.claude.com/docs/en/hooks)
- [Issue #10412: Stop hooks exit code 2 bug](https://github.com/anthropics/claude-code/issues/10412)
- [Issue #10875: Plugin hooks JSON output not captured](https://github.com/anthropics/claude-code/issues/10875)
- [Steve Kinney: Claude Code Hook Control Flow](https://stevekinney.com/courses/ai-development/claude-code-hook-control-flow)
- [Egghead: Force Claude to Ask What's Next](https://egghead.io/force-claude-to-ask-whats-next-with-a-continuous-stop-hook-workflow~oiqzj)
- Local: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
- Local: `plugins/ralph-specum/hooks/hooks.json`
- Local: `plugins/ralph-specum/commands/implement.md`
- Local: `tests/stop-hook.bats`
- Local: `specs/implement-ralph-wiggum/research.md`
- Local: `specs/remove-ralph-wiggum/research.md`
