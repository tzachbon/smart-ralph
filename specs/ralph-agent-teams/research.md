---
spec: ralph-agent-teams
phase: research
created: 2025-02-07
---

# Research: ralph-agent-teams

## Executive Summary

Agent teams provide parallel task execution with direct inter-agent messaging and shared task lists. Ralph-specum's current subagent delegation pattern can be enhanced with agent teams for research and execution phases. Best fit: research phase (multiple parallel analysts) and task execution (parallel workers). Requires UX design for team lifecycle (create → delegate → shutdown → cleanup).

## External Research

### Best Practices

| Practice | Source | Application |
|----------|--------|-------------|
| Create teams for parallel exploration | [Agent Teams Docs](https://code.claude.com/docs/en/agent-teams) | Research phase spawns 3-5 analysts in parallel |
| One team per session | [Agent Teams Docs](https://code.claude.com/docs/en/agent-teams) | Create one team per ralph phase, not per spec |
| Explicit shutdown before cleanup | [Agent Teams Docs](https://code.claude.com/docs/en/agent-teams) | Shutdown all teammates before TeamDelete |
| Start with research/review tasks | [Agent Teams Docs](https://code.claude.com/docs/en/agent-teams) | Ideal for research phase |
| Delegate mode for coordination-only | [Agent Teams Docs](https://code.claude.com/docs/en/agent-teams) | Use for execution loop coordinator |

### Prior Art

**Research with Competing Hypotheses** (from agent teams docs):
```
Users report the app exits after one message instead of staying connected.
Spawn 5 agent teammates to investigate different hypotheses. Have them talk to
each other to try to disprove each other's theories, like a scientific
debate. Update the findings doc with whatever consensus emerges.
```
→ Pattern applicable to ralph research phase with multiple research-analyst agents

**Parallel Code Review** (from agent teams docs):
```
Create an agent team to review PR #142. Spawn three reviewers:
- One focused on security implications
- One checking performance impact
- One validating test coverage
```
→ Pattern matches ralph's current multi-agent research delegation

### Pitfalls to Avoid

| Pitfall | Impact | Mitigation |
|---------|--------|------------|
| Starting multiple teams per session | Error: "One team per session" | Create one team per phase, reuse for multiple tasks |
| Not shutting down teammates before cleanup | TeamDelete fails | Implement shutdown protocol in cancel flow |
| Orphaned tmux sessions | Resource leaks | Detect and cleanup in stop-hook |
| Too many permission prompts | Friction | Pre-approve common operations in settings |
| Teammates stopping on errors | Wasted effort | Implement retry with new teammate spawn |

## Codebase Analysis

### Current Ralph Workflow

**Phase-Based Delegation Pattern:**

| Phase | Current Implementation | Agent Type | Parallelization |
|-------|------------------------|------------|-----------------|
| Research | `research.md` command | Multiple `research-analyst` + `Explore` | Manual (multiple Task calls in one message) |
| Requirements | `requirements.md` command | Single `product-manager` | None |
| Design | `design.md` command | Single `architect-reviewer` | None |
| Tasks | `tasks.md` command | Single `task-planner` | None |
| Execution | `implement.md` loop | Single `spec-executor` per task | Manual ([P] marker for parallel) |

**Research Phase** (`commands/research.md`):
- Already spawns 3-5 agents in parallel (multiple `research-analyst` + `Explore`)
- Uses Task tool with explicit "spawn ALL in ONE message" pattern
- Merges results from `.research-*.md` partial files
- **Ripe for agent teams conversion**

**Execution Phase** (`commands/implement.md`):
- Coordinator delegates to `spec-executor` via Task tool
- Parallel support via [P] marker (creates multiple Task calls)
- Each executor writes to isolated `.progress-task-N.md`
- **Candidate for agent teams with shared task list**

### Existing Patterns

**Parallel Delegation Pattern** (research.md lines 216-401):
```text
Task 1 (research-analyst): OAuth authentication patterns
Task 2 (research-analyst): Rate limiting strategies
Task 3 (Explore): Existing auth implementation
[All Task calls in ONE message for parallel execution]
```
→ Can be replaced with TeamCreate + 3 teammates

**Progress Merge Pattern** (implement.md lines 1105-1132):
```text
After parallel batch completes:
1. Read each temp progress file (.progress-task-N.md)
2. Extract completed task entries and learnings
3. Append to main .progress.md in task index order
4. Delete temp files after merge
```
→ Agent teams provide automatic task list, no manual merge needed

**State File Pattern** (start.md lines 656-664):
```json
{
  "phase": "research",
  "awaitingApproval": true,
  "relatedSpecs": [...],
  "commitSpec": true
}
```
→ Add `teamName` field for tracking active team across phases

### Dependencies

| Component | Role | Agent Teams Integration |
|-----------|------|-------------------------|
| `hooks/scripts/stop-watcher.sh` | Loop controller | Detect team completion, cleanup orphaned teams |
| `commands/cancel.md` | Dual cleanup | Must shutdown team before state file deletion |
| Task tool | Delegation | Replace with TeamCreate/SendMessage for teams |
| `.ralph-state.json` | State tracking | Add `teamName`, `teammateNames` fields |

### Constraints

**Single Session Constraint:**
- "One team per session" from agent teams docs
- Ralph uses one Claude Code session per command invocation
- **Implication**: Each phase (research/requirements/design/tasks/execution) can have at most one team
- **Solution**: Create team → delegate all phase work → shutdown before next phase

**Cleanup Requirement:**
- TeamDelete fails if active teammates exist
- Must gracefully shutdown all teammates before calling TeamDelete
- **Implication**: cancel.md must send shutdown requests to all teammates

**Token Cost:**
- Agent teams use significantly more tokens (each teammate = separate instance)
- Research phase already spawns 3-5 subagents → similar cost to teams
- **Benefit**: Inter-agent messaging, shared task list, automatic coordination

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | High | Agent teams API available (TeamCreate, SendMessage, TeamDelete) |
| Effort Estimate | M | 2-3 weeks for full integration across phases |
| Risk Level | Medium | New API, requires careful shutdown/cleanup handling |

## Recommendations for Requirements

1. **Research Phase Integration (High Priority)**
   - Create team with 3-5 teammates on `/ralph-specum:research`
   - Assign distinct research topics to each teammate
   - Enable peer discussion via direct messaging
   - Shutdown team after research.md merge complete

2. **Execution Phase Integration (Medium Priority)**
   - Create team with 2-3 parallel executors for [P] tasks
   - Use shared task list for self-coordination
   - Enable teammates to claim next unblocked task automatically
   - Shutdown team after phase completion

3. **Team Lifecycle Management (Critical)**
   - Add `teamName` field to `.ralph-state.json`
   - Implement shutdown protocol in cancel.md (send requests to all teammates)
   - Detect orphaned teams in stop-watcher.sh (check `~/.claude/teams/`)
   - Add cleanup command `/ralph-specum:cleanup-teams`

4. **UX Design for Team Operations**
   - Display teammate status in `/ralph-specum:status` output
   - Show "Researching with 3 teammates..." message during team work
   - Provide progress indicators (teammate name + current task)
   - Offer manual teammate interaction hint ("Use Shift+Up/Down to message teammates")

5. **Graceful Degradation (Low Priority)**
   - Fallback to subagent pattern if team creation fails
   - Detect env var `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`
   - Show warning if agent teams not enabled
   - Preserve existing Task tool delegation for non-team phases

## Open Questions

- Should requirements/design phases use teams? (Current single-agent model works well)
- How to handle user interruption during team operations? (Send shutdown to all)
- Should team creation be configurable? (Some users may prefer subagent-only mode)
- How to display teammate activity in terminal? (In-process vs split-pane mode)

## Sources

- [Agent Teams Documentation](https://code.claude.com/docs/en/agent-teams) - Complete API reference, patterns, limitations
- `/home/lazysloth/dev/smart-ralph/plugins/ralph-specum/commands/research.md` - Current parallel research implementation
- `/home/lazysloth/dev/smart-ralph/plugins/ralph-specum/commands/implement.md` - Execution loop coordinator
- `/home/lazysloth/dev/smart-ralph/plugins/ralph-specum/commands/start.md` - Branch management, state initialization
- `/home/lazysloth/dev/smart-ralph/plugins/ralph-specum/agents/research-analyst.md` - Research subagent spec
- `/home/lazysloth/dev/smart-ralph/plugins/ralph-specum/agents/spec-executor.md` - Task executor agent
- `/home/lazysloth/dev/smart-ralph/plugins/ralph-specum/hooks/scripts/stop-watcher.sh` - Loop controller
