---
spec: remove-ralph-wiggum
phase: research
created: 2026-02-05
generated: auto
---

# Research: remove-ralph-wiggum

## Executive Summary

Removing ralph-wiggum/ralph-loop plugin dependency is feasible. The stop-hook already has infrastructure for state reading; it needs loop control logic added. implement.md currently writes coordinator prompt to file then invokes external skill - this can be simplified to direct state management. cancel.md can be reduced to file deletion.

## Codebase Analysis

### Current Architecture

| Component | Current Behavior | New Behavior |
|-----------|-----------------|--------------|
| `implement.md` | Writes `.coordinator-prompt.md`, invokes `ralph-loop:ralph-loop` skill | Writes `.ralph-state.json`, outputs coordinator prompt directly |
| `cancel.md` | Invokes `ralph-loop:cancel-ralph`, deletes state files, removes spec | Deletes `.ralph-state.json`, removes spec dir via `rm -rf $spec_path` (which removes `.progress.md`), clears `.current-spec`, updates Spec Index |
| `stop-watcher.sh` | Logs state, cleans orphaned temp files, does NOT control loop | Becomes loop controller: checks state, outputs continuation prompt |

### Key Files

| File | Path | Role |
|------|------|------|
| implement.md | `plugins/ralph-specum/commands/implement.md` | 1255 lines, massive coordinator prompt |
| cancel.md | `plugins/ralph-specum/commands/cancel.md` | 126 lines, calls external skill |
| stop-watcher.sh | `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` | 80 lines, logging only |
| path-resolver.sh | `plugins/ralph-specum/hooks/scripts/path-resolver.sh` | 253 lines, spec directory resolution |
| hooks.json | `plugins/ralph-specum/hooks/hooks.json` | Declares Stop and SessionStart hooks |

### State File Schema

```json
{
  "phase": "execution",
  "taskIndex": 0,
  "totalTasks": 10,
  "taskIteration": 1,
  "maxTaskIterations": 5,
  "recoveryMode": false,
  "maxFixTasksPerOriginal": 3,
  "fixTaskMap": {}
}
```

### Existing Patterns

1. **Path Resolution**: `path-resolver.sh` provides `ralph_resolve_current()` - already used by stop-watcher
2. **State Reading**: stop-watcher reads state with jq, validates JSON integrity
3. **Settings Check**: stop-watcher reads `.claude/ralph-specum.local.md` for enabled status
4. **Hook System**: `hooks.json` declares Stop hook as command type executing shell script

### Dependencies

- `jq` - JSON parsing (already used in stop-watcher)
- `path-resolver.sh` - Spec path resolution (already sourced)
- Claude Code hook system - Stop hook triggers after each response

### Constraints

1. **Stop hook output**: Must output prompt text that Claude will process
2. **State file location**: Dynamic based on resolved spec path
3. **Completion signal**: Must detect `ALL_TASKS_COMPLETE` to terminate loop
4. **Task delegation**: Coordinator prompt relies on Task tool for spec-executor

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | High | All components exist, just need rewiring |
| Effort Estimate | M | Stop-hook logic + testing + CI |
| Risk Level | Low | Breaking change but clean cut |

## Testing Infrastructure

### Current State

- No bats-core tests in project
- Two existing GitHub Actions workflows:
  - `plugin-version-check.yml` - Verifies version bumps
  - `spec-file-check.yml` - Prevents .current-spec commits
- Shell scripts exist: `test-path-resolver.sh`, `test-multi-dir-integration.sh`

### bats-core Integration

```bash
# Test structure
tests/
  stop-hook.bats        # Loop control tests
  state-management.bats # State file operations
  helpers/
    setup.bash          # Common fixtures
```

### GitHub Actions CI

New workflow needed for bats-core tests running on push/PR.

## Recommendations

1. **Inline coordinator prompt** directly in implement.md output (no external file)
2. **Stop-hook becomes loop controller** - reads state, outputs continuation prompt if more tasks
3. **Simplify cancel.md** - just `rm` state files, no skill invocation
4. **Add bats-core tests** for stop-hook state machine
5. **Bump to v3.0.0** - removing external dependency is breaking change
