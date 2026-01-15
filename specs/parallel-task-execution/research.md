# Research: Parallel Task Execution

## Executive Summary

Parallel task execution in agent systems is well-established with mature patterns. The dominant approaches are orchestrator-worker (Anthropic's recommended pattern), fork-join, and scatter-gather. For ralph-specum, the user's preferred approach is to have the root agent spawn multiple spec-executors in parallel using the existing Task tool pattern (already proven in research.md parallel invocations). The stop-handler should NOT be modified. Instead, implement.md coordinator handles parallel grouping, spawning, and result aggregation.

Key findings:
- **External patterns**: Fork-join, scatter-gather, orchestrator-worker, DAG-based scheduling all applicable
- **Codebase ready**: Task tool parallel pattern already established in research.md
- **State challenges**: .progress.md has race conditions, .ralph-state.json tracks single taskIndex
- **Related specs impacted**: qa-verification (V4/V5/V6 sequential order) and goal-interview (.progress.md writes)

## User Context

Interview responses:
- **Technical approach**: Root agent spawns multiple spec-executors in parallel (not stop-handler extension)
- **Known constraints**: None

## External Research

### Best Practices

**Anthropic Multi-Agent Pattern**:
- Orchestrator-worker: lead agent coordinates, specialized subagents execute in parallel
- 3-5 parallel subagents for complex tasks
- Detailed task specs with objective, output format, tools, boundaries
- External memory for state persistence

**LangGraph State Management**:
- Isolated state copies prevent data races
- Deterministic ordering for update application
- Unique keys per agent to prevent conflicts

**Google ADK**:
- ParallelAgent primitive for simultaneous sub-agents
- Shared session state with unique write keys
- Avoid cross-dependencies between parallel tasks

### Common Patterns

| Pattern | Description | Use Case |
|---------|-------------|----------|
| Fork-Join | Tasks fork, work independently, join at barrier | Recursive decomposition |
| Scatter-Gather | Broadcast to workers, aggregate results | Map-reduce style work |
| Orchestrator-Worker | Lead agent spawns and coordinates workers | **Best fit for ralph-specum** |
| DAG-Based | Topological sort respects dependencies | Complex dependency graphs |

### Marker Conventions

**Proposed for ralph-specum**:
```markdown
### [PARALLEL] group-1
- [ ] Task A - independent work
- [ ] Task B - independent work
### [/PARALLEL]
- [ ] Task C - depends on group-1
```

Alternative: Simple `[P]` marker on consecutive parallelizable tasks.

### Error Handling

- Retry with exponential backoff
- Circuit breaker (Closed/Open/Half-Open)
- Checkpointing for resume
- Per-task error tracking with partial success

### Claude Code Specifics

- Background subagents run concurrently but auto-deny unpermitted actions
- Subagents cannot spawn other subagents (no nesting)
- Task tool already supports parallel invocation in single message

## Codebase Analysis

### Current Sequential Flow

```
/ralph-specum:implement
    -> implement.md reads .ralph-state.json
    -> Task tool invokes spec-executor (single task)
    -> spec-executor executes, outputs TASK_COMPLETE
    -> stop-handler.sh intercepts stop
    -> Verifies TASK_COMPLETE in transcript
    -> Updates state: taskIndex++
    -> Returns block decision with next task prompt
```

### Parallel Pattern Already Exists

research.md already uses parallel Task tool invocations:
```
Invoke 3 research-analysts in parallel (all in ONE message with multiple Task tool calls)
```

Same pattern applies to spec-executor:
```
Invoke N spec-executors in parallel (all in ONE message with multiple Task tool calls)
```

### Extension Points

**User's preferred approach**: Coordinator-only at implement.md level
1. Parse `[P]` markers from tasks.md
2. Group consecutive `[P]` tasks
3. Spawn multiple spec-executors via Task tool
4. Wait for all to complete
5. Merge results
6. Continue to next group/task

### Challenges Identified

| Challenge | Mitigation |
|-----------|------------|
| Commit conflicts | Serialize commits after parallel batch |
| .progress.md race | Each executor writes temp file, coordinator merges |
| Stop handler loop | Do not modify. Coordinator handles all parallel logic |
| Partial failures | Mark failed task, continue with others, retry in next iteration |

### Quality Commands

None found. This is a markdown-only Claude Code plugin with no build/test system.

## Related Specs

| Name | Relevance | Relationship | mayNeedUpdate |
|------|-----------|--------------|---------------|
| qa-verification | **High** | [VERIFY] tasks assume sequential V4->V5->V6 order. Retry mechanism assumes single task. | true |
| goal-interview | **High** | .progress.md shared mutable state for interview data and task progress. | true |
| plan-source-feature | Medium | Generates sequential tasks. May want parallelization markers later. | false |
| add-skills-doc | Low | Documentation only. | false |
| skills-per-capability | Low | Incomplete spec. | false |
| verification-phase-qa | Low | Superseded by qa-verification. | false |

### Key Conflicts

1. **qa-verification**: V4/V5/V6 verification sequence must remain sequential. Mark [VERIFY] tasks as non-parallelizable.
2. **goal-interview**: .progress.md "Current Task" section assumes single task. Need redesign to append-only log.

## Feasibility Assessment

| Aspect | Feasibility | Notes |
|--------|-------------|-------|
| Task tool parallel invocation | High | Already proven in research.md |
| [P] marker parsing | High | Simple regex/string match |
| Coordinator logic in implement.md | High | Extends existing pattern |
| Stop-handler changes | N/A | User explicitly wants no changes |
| State management | Medium | Needs parallel-aware fields |
| .progress.md merge | Medium | Temp files + coordinator merge |
| [VERIFY] task handling | High | Mark as non-parallelizable |

## Recommendations for Requirements

1. **Simple [P] marker**: Tasks marked `[P]` that are consecutive form a parallel group
2. **Coordinator-only**: implement.md handles grouping and parallel invocation
3. **No stop-handler changes**: All parallel logic before stop-handler sees result
4. **Non-parallelizable tags**: [VERIFY] and explicit [SEQUENTIAL] tasks never parallel
5. **Temp progress files**: Each spec-executor writes .progress-task-N.md, coordinator merges
6. **Batch completion**: BATCH_COMPLETE signal instead of TASK_COMPLETE for parallel groups

## Open Questions

1. How to handle partial failures in parallel batch? (Suggested: mark failed, continue, retry)
2. Should task-planner auto-detect parallelizable tasks or require manual [P] marking?
3. Max concurrent executors? (Suggested: configurable, default 3)
4. Should parallel groups be explicit blocks or inferred from consecutive [P] markers?

## Sources

- [Anthropic Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system)
- [Claude Code Subagents Documentation](https://code.claude.com/docs/en/sub-agents)
- [LangGraph State Management](https://medium.com/@bharatraj1918/langgraph-state-management-part-1-how-langgraph-manages-state-for-multi-agent-workflows-da64d352c43b)
- [Fork-Join Model - Wikipedia](https://en.wikipedia.org/wiki/Fork%E2%80%93join_model)
- [Scatter-Gather Pattern - Enterprise Integration](https://www.enterpriseintegrationpatterns.com/patterns/messaging/BroadcastAggregate.html)
- [Temporal Error Handling](https://temporal.io/blog/error-handling-in-distributed-systems)
- plugins/ralph-specum/hooks/scripts/stop-handler.sh
- plugins/ralph-specum/commands/implement.md
- plugins/ralph-specum/commands/research.md
- plugins/ralph-specum/agents/spec-executor.md
- plugins/ralph-specum/schemas/spec.schema.json
