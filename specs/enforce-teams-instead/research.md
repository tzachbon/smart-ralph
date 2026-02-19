---
spec: enforce-teams-instead
phase: research
created: 2026-02-19
generated: auto
---

# Research: enforce-teams-instead

## Executive Summary
The Ralph Specum plugin currently uses individual Task-tool subagent calls for requirements, design, tasks, and execution phases, while research already uses Claude Code Teams for parallel work. Converting other phases to teams is feasible but the benefit varies significantly by phase -- research and execution benefit from parallelism, while requirements/design/tasks are inherently sequential single-agent operations where teams add overhead without parallelism gains.

## Codebase Analysis

### Current Phase Architecture

| Phase | Command File | Current Pattern | Subagent(s) | Parallelizable? |
|-------|-------------|----------------|-------------|-----------------|
| Research | `commands/research.md` + `commands/start.md` | Teams (start.md) / Multi-Task parallel (research.md) | research-analyst, Explore | Yes -- already using teams in start.md |
| Requirements | `commands/requirements.md` | Single Task call | product-manager | No -- single agent, sequential |
| Design | `commands/design.md` | Single Task call | architect-reviewer | No -- single agent, sequential |
| Tasks | `commands/tasks.md` | Single Task call | task-planner | No -- single agent, sequential |
| Execution | `commands/implement.md` | Single Task call per task, stop-hook loop | spec-executor, qa-engineer | Partial -- parallel [P] tasks exist |

### Existing Team Pattern (start.md, lines 1127-1430)

The research phase in `start.md` demonstrates the full team lifecycle:
1. `TeamCreate(team_name: "research-$name")` -- create team
2. `TaskCreate()` per topic -- create task list
3. `Task()` per teammate with `team_name` param -- spawn workers
4. `TaskList()` -- monitor completion
5. `SendMessage(type: "shutdown_request")` -- clean shutdown
6. Merge results from partial files
7. `TeamDelete()` -- cleanup

### Existing Parallel Execution (research.md)

The standalone `research.md` command uses multi-Task parallelism (multiple Task tool calls in one message) instead of Teams. Both achieve parallel execution. The key difference: Teams add coordination infrastructure (TaskCreate, TaskList, SendMessage, TeamDelete) while multi-Task is lighter-weight.

### Execution Phase (implement.md)

The execution loop in `implement.md` already has parallel support:
- Sequential tasks: single Task call to spec-executor
- `[P]` marked tasks: multiple Task calls in one message (parallel batch)
- `[VERIFY]` tasks: delegated to qa-engineer instead
- Stop-hook (`hooks/scripts/stop-watcher.sh`) controls loop continuation

The stop-hook reads `.ralph-state.json` and outputs `block` decision to continue execution. Converting this to teams would require significant rearchitecting of the loop mechanism.

### Agent Definitions

| Agent | File | Capabilities |
|-------|------|-------------|
| research-analyst | `agents/research-analyst.md` | WebSearch, WebFetch, Read, Glob, Grep |
| product-manager | `agents/product-manager.md` | Read, Write, Glob, Grep |
| architect-reviewer | `agents/architect-reviewer.md` | Read, Write, Glob, Grep, Bash |
| task-planner | `agents/task-planner.md` | Read, Write, Glob, Grep |
| spec-executor | `agents/spec-executor.md` | Full tool access |
| qa-engineer | `agents/qa-engineer.md` | Read, Bash, Glob, Grep |
| plan-synthesizer | `agents/plan-synthesizer.md` | Full tool access |

### Dependencies
- Claude Code Teams API: TeamCreate, TaskCreate, TaskList, TaskUpdate, SendMessage, TeamDelete
- Claude Code Task tool: subagent_type param, team_name param
- Stop-hook mechanism: `hooks/scripts/stop-watcher.sh`
- State management: `.ralph-state.json`

### Constraints
- **Markdown-only plugin**: No compiled code; all changes are markdown file edits
- **Stop-hook loop**: The execution phase depends on the stop-hook blocking mechanism -- teams cannot replace this
- **Single-agent phases**: Requirements, design, and tasks phases each use one agent doing one job -- teams add overhead without benefit
- **Backwards compatibility**: Changes must not break existing `--quick` mode or normal mode flows

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | High | All infrastructure exists (Teams API, team_name param) |
| Effort Estimate | M | ~10-15 tasks across 4 phases; mostly markdown edits |
| Risk Level | Low | Markdown-only changes; no compilation; easy to test manually |

### Phase-by-Phase Team Conversion Analysis

| Phase | Team Benefit | Recommendation |
|-------|-------------|----------------|
| Research (start.md) | Already uses teams | No change needed |
| Research (research.md) | Uses multi-Task parallel | Convert to match start.md team pattern for consistency |
| Requirements | None -- single agent | Convert to team wrapper for consistency, but acknowledge no parallelism gain |
| Design | None -- single agent | Convert to team wrapper for consistency, but acknowledge no parallelism gain |
| Tasks | None -- single agent | Convert to team wrapper for consistency, but acknowledge no parallelism gain |
| Execution | Partial -- [P] tasks benefit | Convert parallel batches to teams; keep stop-hook loop for sequential flow |

## Recommendations
1. **Standardize research.md** to use the same team pattern as start.md for consistency
2. **Wrap requirements/design/tasks** in team pattern for API consistency, even though single-agent teams add overhead
3. **Convert execution parallel batches** to use teams for [P] task groups
4. **Keep stop-hook loop** -- do not replace the execution loop mechanism with teams
5. **Add team cleanup guards** to prevent orphaned teams on session interruption

## Open Questions
1. Should single-agent phases (requirements, design, tasks) use teams if there is no parallelism benefit? The goal says "if possible" -- this could mean skip where it does not make sense.
2. For execution, should only [P] parallel batches use teams, or should each sequential task also be wrapped in a team?
