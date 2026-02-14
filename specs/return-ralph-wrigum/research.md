---
spec: return-ralph-wrigum
phase: research
created: 2026-02-14
generated: auto
---

# Research: return-ralph-wrigum

## Executive Summary

Re-introducing the Ralph Wiggum (ralph-loop) plugin as the execution loop mechanism is feasible. The current v3.0.0 codebase is self-contained with stop-watcher.sh providing loop control. Reverting means: (1) making stop-watcher.sh passive again (logging only), (2) having implement.md invoke `/ralph-loop` instead of outputting coordinator prompt directly, (3) having cancel.md call `/cancel-ralph`, and (4) documenting the dependency. This is essentially a partial revert of PR #85 combined with v3.0.0 improvements (bats tests, path-resolver, recovery mode, fix-task generation).

## Codebase Analysis

### Current State (v3.1.1, post PR #85)

| Component | File | Lines | Role |
|-----------|------|-------|------|
| implement.md | `commands/implement.md` | ~1260 | Coordinator, writes state, outputs prompt directly |
| cancel.md | `commands/cancel.md` | ~119 | Deletes state files, removes spec dir |
| stop-watcher.sh | `hooks/scripts/stop-watcher.sh` | ~171 | **Loop controller**: reads state, outputs continuation prompt |
| path-resolver.sh | `hooks/scripts/path-resolver.sh` | ~253 | Spec directory resolution |
| hooks.json | `hooks/hooks.json` | ~25 | Declares Stop + SessionStart hooks |
| spec-executor.md | `agents/spec-executor.md` | ~391 | Autonomous task executor |
| qa-engineer.md | `agents/qa-engineer.md` | ~188 | [VERIFY] task handler |

### What PR #85 Changed (v3.0.0)

1. **stop-watcher.sh**: Added loop control logic (was logging-only before)
2. **implement.md**: Removed ralph-loop skill invocation, outputs coordinator prompt directly
3. **cancel.md**: Removed `/cancel-ralph` call, simplified to file deletion
4. **References**: Removed all ralph-loop/ralph-wiggum mentions
5. **Tests**: Added 39 bats-core tests for stop-hook and state management
6. **CI**: Added GitHub Actions workflow for bats tests

### What PR #38 Added (v2.0.0)

1. **implement.md**: Thin wrapper calling `/ralph-loop "<prompt>" --max-iterations N --completion-promise "ALL_TASKS_COMPLETE"`
2. **cancel.md**: Called `/cancel-ralph` for dual cleanup
3. **stop-handler.sh**: Deleted (replaced by Ralph Wiggum's stop-hook)
4. **hooks.json**: Deleted
5. **Dependency**: Required `/plugin install ralph-wiggum@claude-plugins-official`

### Key Differences Between v2.0.0 and Current

| Aspect | v2.0.0 (PR #38) | v3.1.1 (Current) |
|--------|-----------------|-------------------|
| Loop mechanism | Ralph Wiggum stop-hook | Custom stop-watcher.sh |
| State files | .ralph-state.json + .claude/ralph-loop.local.md | .ralph-state.json only |
| Hooks | None (deleted) | Stop + SessionStart |
| Tests | None | 39 bats-core tests |
| Recovery mode | No | Yes (--recovery-mode) |
| Fix task generation | No | Yes (iterative failure recovery) |
| Parallel execution | [P] markers | [P] markers (unchanged) |
| Global iteration limit | No | Yes (--max-global-iterations) |
| Path resolution | Simple | Multi-directory support |

## External Research: Current Ralph Wiggum Plugin

### Official Plugin

**Repository**: `anthropics/claude-code` at `plugins/ralph-wiggum/`
**Installation**: `/plugin install ralph-wiggum@claude-plugins-official`

### Plugin Structure

```
ralph-wiggum/
  .claude-plugin/plugin.json
  commands/ralph-loop.md
  commands/cancel-ralph.md
  hooks/hooks.json
  hooks/stop-hook.sh
  scripts/setup-ralph-loop.sh
  README.md
```

### Commands

| Command | Purpose | Options |
|---------|---------|---------|
| `/ralph-loop` | Start autonomous loop | `--max-iterations <n>`, `--completion-promise "<text>"` |
| `/cancel-ralph` | Cancel active loop | None |

### State File

Location: `.claude/ralph-loop.local.md`

```yaml
---
active: true
iteration: 1
max_iterations: 0
completion_promise: "ALL_TASKS_COMPLETE"
started_at: "2026-02-14T00:00:00Z"
---
[Coordinator prompt text]
```

### Mechanism

1. User runs `/ralph-loop "prompt" --max-iterations N --completion-promise "TEXT"`
2. Setup script creates state file, injects prompt
3. Claude processes prompt, attempts to exit
4. Stop-hook reads state, checks completion criteria
5. If not complete: increments iteration, re-injects prompt
6. Loop until completion-promise found or max-iterations reached

### Known Issues (as of Jan 2026)

1. **--max-iterations=N bug**: Equals-sign syntax silently ignored, use space syntax instead
2. **Context accumulation**: Plugin keeps same session context (growing tokens), unlike original Ralph technique (fresh context per iteration)
3. **Completion promise**: Exact string match only, case-sensitive

### Compatibility Considerations

- Ralph Wiggum uses Stop hook - our stop-watcher.sh also uses Stop hook
- **Hook conflict**: Both will trigger on Stop events
- Our hooks.json declares Stop hook AND SessionStart hook
- Ralph Wiggum's hooks.json also declares Stop hook
- **Resolution**: Remove loop control from our stop-watcher.sh, let Ralph Wiggum handle it
- Keep SessionStart hook for load-spec-context.sh

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | High | Partial revert of PR #85, well-understood changes |
| Effort Estimate | M | Need to preserve v3.0.0 improvements while reverting loop control |
| Risk Level | Medium | Hook conflicts between plugins, test updates needed |

## Key Challenges

1. **Hook Coexistence**: Both Ralph Wiggum and our plugin declare Stop hooks. Need to ensure our stop-watcher.sh does NOT output continuation prompts (let Ralph Wiggum handle loop control), but still provides logging and orphan cleanup.

2. **Test Updates**: 39 existing bats tests assume stop-watcher.sh controls the loop. Tests for loop control behavior need to be updated/removed since Ralph Wiggum handles it now.

3. **Preserve v3.0.0 Features**: Recovery mode, fix-task generation, global iteration limits - these live in implement.md's coordinator prompt. They must be preserved in the ralph-loop prompt.

4. **State Dual-Management**: Ralph Wiggum tracks iterations in `.claude/ralph-loop.local.md`. We track task progress in `.ralph-state.json`. Both coexist.

5. **Max Iterations Calculation**: Need to compute from totalTasks * maxTaskIterations to set Ralph Wiggum's --max-iterations.

## Recommendations

1. **Revert stop-watcher.sh** to logging-only (remove loop control logic, keep logging + orphan cleanup)
2. **Modify implement.md** to invoke `/ralph-loop` with coordinator prompt instead of outputting directly
3. **Modify cancel.md** to call `/cancel-ralph` before file cleanup
4. **Keep hooks.json** with Stop (passive watcher) + SessionStart hooks
5. **Update bats tests** to reflect passive stop-watcher behavior
6. **Bump version** to 4.0.0 (breaking change: requires ralph-wiggum dependency)
7. **Update README** with dependency installation instructions
8. **Preserve all v3.0.0 features** in coordinator prompt passed to ralph-loop

## Sources

- [Official Ralph Wiggum Plugin](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum)
- [Ralph Wiggum README](https://github.com/anthropics/claude-code/blob/main/plugins/ralph-wiggum/README.md)
- [DeepWiki: Ralph Wiggum Plugin](https://deepwiki.com/anthropics/claude-code/4.5-ralph-wiggum-plugin)
- [Known Bug: max-iterations ignored](https://github.com/anthropics/claude-code/issues/18646)
- [Context accumulation issue](https://github.com/anthropics/claude-plugins-official/issues/125)
- [Awesome Claude: Ralph Wiggum](https://awesomeclaude.ai/ralph-wiggum)
- Local specs: implement-ralph-wiggum, remove-ralph-wiggum
- Local codebase: implement.md, cancel.md, stop-watcher.sh, hooks.json
