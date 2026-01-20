# Research: implement-ralph-wiggum

## Executive Summary

The goal is to use the official Ralph Loop plugin as the **loop mechanism** for `/implement`, while preserving the current Task tool delegation to spec-executor subagents. Ralph Loop's stop-hook (exit code 2) keeps the root agent running in a loop. On each iteration, the root agent reads state, determines next task(s), and invokes spec-executor via Task tool. This preserves parallel execution ([P] markers) and [VERIFY] delegation since those use Task tool subagents, not the loop mechanism itself.

**Key insight**: Ralph Loop provides the loop. spec-executor provides the execution. They are complementary, not competing.

## User Context

Interview responses:
- **Technical approach**: Use Ralph Loop as the main orchestrator loop. Root agent stays in Ralph Loop loop and invokes spec-executor subagents via Task tool. Parallel execution preserved.
- **Known constraints**: No known constraints

## Target Architecture

```
/implement (thin wrapper)
  └─> calls /ralph-loop "<prompt>" --max-iterations N --completion-promise "ALL_TASKS_COMPLETE"
        └─> <prompt> = current implement.md coordinator logic
              └─> Read .ralph-state.json
              └─> Parse tasks.md, find next task(s)
              └─> Task tool -> spec-executor (fresh context)
              └─> Task tool -> spec-executor (parallel via multi-Task for [P])
              └─> Task tool -> qa-engineer (for [VERIFY])
              └─> Output ALL_TASKS_COMPLETE when taskIndex >= totalTasks
        └─> Ralph Loop stop-hook re-injects prompt each iteration
```

**What changes**:
- `/implement` becomes thin wrapper that calls `/ralph-loop`
- Current implement.md coordinator logic moves INTO the ralph-loop prompt
- Delete custom stop-handler.sh and hooks/hooks.json

**What stays**: Task tool delegation, spec-executor, parallel [P] execution, [VERIFY] qa-engineer delegation.

## External Research

### Official Ralph Loop Plugin

**Repository**: `anthropics/claude-code` at `plugins/ralph-wiggum/`
**Installation**: `/plugin install ralph-wiggum@claude-plugins-official`

### Core Mechanism

1. User runs `/ralph-loop "task" --max-iterations N --completion-promise "TEXT"`
2. Claude works on task
3. Claude attempts to exit
4. Stop hook intercepts via exit code 2
5. Same prompt re-injected into context
6. Repeat until completion-promise found or max-iterations reached

### Plugin Structure

```
ralph-wiggum/
  .claude-plugin/plugin.json
  commands/ralph-loop.md
  commands/cancel-ralph.md
  hooks/hooks.json
  hooks/stop-hook.sh
```

### State File

Location: `.claude/ralph-loop.local.md`

```yaml
---
active: true
iteration: 1
max_iterations: 0
completion_promise: "DONE"
started_at: "2025-01-06T12:00:00Z"
---
The task prompt goes here...
```

### Stop Hook Input (stdin JSON)

```json
{
  "session_id": "...",
  "transcript_path": "/path/to/session.jsonl",
  "cwd": "/project/path",
  "hook_event_name": "Stop",
  "stop_hook_active": false
}
```

### Known Limitations

1. **No parallel execution**: Single-context model
2. **Completion-promise unreliable**: Exact string match
3. **Plugin-installed hooks bug**: Exit code 2 may halt instead of continue
4. **Token consumption**: Accumulating context burns tokens rapidly ($50-100+ for large codebases)

## Codebase Analysis

### Current Architecture

| Component | File | Purpose |
|-----------|------|---------|
| implement.md | commands/implement.md (~1027 lines) | Coordinator, delegates to spec-executor |
| spec-executor.md | agents/spec-executor.md (~391 lines) | Autonomous task executor |
| stop-handler.sh | hooks/scripts/stop-handler.sh (~274 lines) | Task loop control via Stop hook |
| qa-engineer.md | agents/qa-engineer.md (~188 lines) | [VERIFY] task verification |

### Current Flow

```
/implement -> implement.md (coordinator)
  -> Task tool -> spec-executor (fresh context per task)
    -> executes task, commits, outputs TASK_COMPLETE
  -> stop-handler.sh verifies, increments taskIndex
  -> re-prompts implement.md for next task
```

### Key Patterns

1. **Coordinator-Worker**: Commands delegate all work to subagents via Task tool
2. **Fresh Context Per Task**: Each task runs in isolation via Task tool
3. **State-Driven**: .ralph-state.json is source of truth (taskIndex, phase, iterations)
4. **4-Layer Verification**: Contradiction, uncommitted files, checkmarks, signal
5. **Parallel Isolation**: [P] tasks write to .progress-task-N.md, merged after batch

### Architectural Comparison

| Aspect | Current (spec-executor) | Ralph Loop |
|--------|-------------------------|--------------|
| Execution model | Task tool subagents | Single context, same prompt |
| State management | .ralph-state.json | .claude/ralph-loop.local.md |
| Completion signal | TASK_COMPLETE | Completion-promise exact match |
| Task progression | taskIndex increment | Iteration counter |
| Parallelism | [P] marker, multi-Task | None (single context) |
| Context per task | Fresh (via Task tool) | Accumulating (same session) |

## Related Specs

| Name | Relevance | Relationship | mayNeedUpdate |
|------|-----------|--------------|---------------|
| parallel-task-execution | Medium | [P] marker parallelism via Task tool. **Compatible** - root agent in Ralph Loop loop still uses Task tool. | false |
| qa-verification | Medium | [VERIFY] delegation to qa-engineer via Task tool. **Compatible** - delegation pattern unchanged. | false |
| goal-interview | Low | Interviews in commands, not implement. Independent of execution. | false |
| plan-source-feature | Low | Generates tasks, does not execute. Upstream and independent. | false |
| add-skills-doc | Low | Documentation only. | false |

**Note**: Since Ralph Loop only provides the loop mechanism and the root agent still uses Task tool for subagent delegation, existing parallel and verification features remain intact.

## Feasibility Assessment

| Aspect | Feasibility | Notes |
|--------|-------------|-------|
| Ralph Loop as loop mechanism | **High** | Direct use of official plugin stop-hook |
| Pre-prompt mechanism | **High** | Prompt includes implement.md logic + spec context |
| Sequential task execution | **High** | Root agent invokes spec-executor via Task tool |
| [VERIFY] task handling | **High** | Root agent invokes qa-engineer via Task tool (unchanged) |
| Parallel [P] tasks | **High** | Root agent spawns multiple Task tools (unchanged) |
| State management | **Medium** | Keep .ralph-state.json, integrate with Ralph Loop state |
| Custom stop-handler removal | **High** | Replace with Ralph Loop's stop-hook |

## Quality Commands

None. This is a markdown-only plugin repository. CI only checks plugin version bumps.

## Recommendations for Requirements

1. **Implement becomes thin wrapper**: `/implement` command just:
   - Reads spec name from .current-spec
   - Calls `/ralph-loop "<prompt>" --max-iterations N --completion-promise "ALL_TASKS_COMPLETE"`

2. **Move coordinator logic to prompt**: Current implement.md content becomes the ralph-loop prompt:
   - Read .ralph-state.json for taskIndex, phase
   - Parse tasks.md for next task(s)
   - Invoke spec-executor subagent(s) via Task tool
   - Handle [P] parallel batches via multi-Task tool calls
   - Handle [VERIFY] via qa-engineer delegation
   - Output ALL_TASKS_COMPLETE when done

3. **State management**: Keep .ralph-state.json. Ralph Loop handles iteration count in its own state file.

4. **Remove custom loop**: Delete hooks/scripts/stop-handler.sh and hooks/hooks.json. Ralph Loop provides the loop via its stop-hook.

5. **Dependency**: Require Ralph Loop plugin installed. Either:
   - Document as prerequisite
   - Or bundle/fork Ralph Loop into this plugin

## Open Questions

1. Should the prompt be inline in implement.md or read from a separate template file?
2. How to calculate --max-iterations? (totalTasks * maxTaskIterations)?
3. How to handle the prompt size? Current implement.md is ~1000 lines.
4. What minimal stop-hook logic to keep (if any) to complement Ralph Loop?
5. How does /cancel-ralph interact with .ralph-state.json cleanup? Need wrapper?

## Dependency Strategy

**Decision**: Require users to install Ralph Loop plugin separately.

- Install: `/plugin install ralph-wiggum@claude-plugins-official`
- This is a **breaking change** for existing users
- Document in README and migration guide
- `/implement` should check if Ralph Loop is available and error with install instructions if not

**Why not bundle?**
- Ralph Loop is official Anthropic plugin, likely maintained separately
- Avoids version drift and duplication
- Simpler to update when Ralph Loop improves

## Stop Handler Simplification

**Current stop-handler.sh** (~274 lines):
- 4-layer verification (contradiction, uncommitted, checkmarks, signal)
- State manipulation detection
- Task advancement logic
- Cleanup on completion

**After migration**:
- Remove most/all of stop-handler.sh
- Ralph Loop's stop-hook handles the loop
- Verification logic moves INTO the prompt (Claude checks before outputting completion)
- Maybe keep minimal hook for .ralph-state.json cleanup on /cancel-ralph

## Breaking Changes

1. **Requires Ralph Loop plugin**: Users must install it
2. **Stop handler removed/simplified**: Custom hooks.json replaced by Ralph Loop's
3. **State file changes**: May simplify .ralph-state.json since Ralph Loop tracks iterations

## Sources

- [Official Ralph Loop Plugin](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum)
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Claude Code Plugins Reference](https://code.claude.com/docs/en/plugins-reference)
- [Awesome Claude: Ralph Loop](https://awesomeclaude.ai/ralph-wiggum)
- [Ralph Loop Autonomous Loops](https://paddo.dev/blog/ralph-wiggum-autonomous-loops/)
- [Looking4OffSwitch Blog](https://looking4offswitch.github.io/blog/2026/01/04/ralph-wiggum-claude-code/)
- Local codebase: plugins/ralph-specum/commands/implement.md
- Local codebase: plugins/ralph-specum/agents/spec-executor.md
- Local codebase: plugins/ralph-specum/hooks/scripts/stop-handler.sh
- Local specs: parallel-task-execution, qa-verification, goal-interview, plan-source-feature, add-skills-doc
