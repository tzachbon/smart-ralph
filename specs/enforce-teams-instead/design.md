---
spec: enforce-teams-instead
phase: design
created: 2026-02-19
generated: auto
---

# Design: enforce-teams-instead

## Overview
Introduce a consistent team lifecycle pattern across all Ralph Specum phases by wrapping each phase's subagent delegation in TeamCreate/TaskCreate/SendMessage/TeamDelete calls. Research phase gets full parallel team conversion; single-agent phases (requirements, design, tasks) get a lightweight team wrapper; execution phase converts [P] parallel batches to use teams.

## Architecture

```mermaid
graph TB
    subgraph "Phase Commands (Coordinator)"
        R[research.md]
        REQ[requirements.md]
        D[design.md]
        T[tasks.md]
        I[implement.md]
    end

    subgraph "Team Lifecycle (NEW)"
        TC[TeamCreate]
        TK[TaskCreate]
        TL[TaskList]
        SM[SendMessage shutdown]
        TD[TeamDelete]
    end

    subgraph "Agents (unchanged)"
        RA[research-analyst]
        PM[product-manager]
        AR[architect-reviewer]
        TP[task-planner]
        SE[spec-executor]
        QA[qa-engineer]
    end

    R --> TC --> TK --> RA
    R --> TK --> RA
    REQ --> TC --> TK --> PM
    D --> TC --> TK --> AR
    T --> TC --> TK --> TP
    I -->|parallel [P] tasks| TC --> TK --> SE
    I -->|sequential tasks| SE
    I -->|VERIFY tasks| QA

    TL --> SM --> TD
```

## Team Lifecycle Pattern (Standard)

Every phase follows this lifecycle:

```
1. Check for orphaned team: Read ~/.claude/teams/$phase-$spec/config.json
   - If exists: TeamDelete() to clean up
2. TeamCreate(team_name: "$phase-$spec")
3. TaskCreate(subject, description, activeForm) per work item
4. Task(subagent_type, team_name, name, prompt) per teammate
5. Wait for completion (TaskList or automatic messages)
6. SendMessage(type: "shutdown_request") per teammate
7. Collect/merge results
8. TeamDelete()
```

## Components

### Component A: Team-Based Research (research.md)
**Purpose**: Convert research.md from multi-Task parallelism to full team pattern matching start.md
**Current**: Multiple Task calls in one message (no team infrastructure)
**New**: TeamCreate -> TaskCreate per topic -> Task per teammate -> merge -> TeamDelete

**Changes to `plugins/ralph-specum/commands/research.md`**:

Replace the "Execute Research" section with team-based flow:

```markdown
## Execute Research (Team-Based)

### Step 1: Check for Orphaned Team
Read ~/.claude/teams/research-$spec/config.json
If exists: TeamDelete() to clean up

### Step 2: Create Research Team
TeamCreate(team_name: "research-$spec", description: "Parallel research for $spec")

### Step 3: Create Research Tasks
For each topic identified in "Analyze Research Topics":
TaskCreate(
  subject: "[topic] research",
  description: "Research [topic] for spec $spec...",
  activeForm: "Researching [topic]"
)

### Step 4: Spawn Teammates
ALL Task calls in ONE message:
Task(subagent_type: research-analyst/Explore, team_name: "research-$spec", name: "researcher-N", ...)

### Step 5: Wait for Completion
Monitor via TaskList and automatic teammate messages

### Step 6: Shutdown Teammates
SendMessage(type: "shutdown_request", recipient: each teammate)

### Step 7: Merge Results
[existing merge logic unchanged]

### Step 8: Clean Up Team
TeamDelete()
```

### Component B: Team Wrapper for Requirements (requirements.md)
**Purpose**: Wrap product-manager delegation in team lifecycle
**Current**: Single `Task(subagent_type: product-manager, ...)` call
**New**: TeamCreate -> TaskCreate -> Task (single teammate) -> shutdown -> TeamDelete

**Changes to `plugins/ralph-specum/commands/requirements.md`**:

Replace "Execute Requirements" section:

```markdown
## Execute Requirements (Team-Based)

### Step 1: Check for Orphaned Team
Read ~/.claude/teams/requirements-$spec/config.json
If exists: TeamDelete() to clean up

### Step 2: Create Requirements Team
TeamCreate(team_name: "requirements-$spec", description: "Requirements for $spec")

### Step 3: Create Task
TaskCreate(
  subject: "Generate requirements for $spec",
  description: "...[existing product-manager prompt]...",
  activeForm: "Generating requirements"
)

### Step 4: Spawn Teammate
Task(subagent_type: product-manager, team_name: "requirements-$spec", name: "pm-1", ...)

### Step 5: Wait for Completion
Wait for teammate message or check TaskList

### Step 6: Shutdown & Cleanup
SendMessage(type: "shutdown_request", recipient: "pm-1")
TeamDelete()
```

### Component C: Team Wrapper for Design (design.md)
**Purpose**: Wrap architect-reviewer delegation in team lifecycle
**Pattern**: Same as Component B, using `architect-reviewer` agent type
**Team name**: `design-$spec`
**Teammate name**: `architect-1`

### Component D: Team Wrapper for Tasks (tasks.md)
**Purpose**: Wrap task-planner delegation in team lifecycle
**Pattern**: Same as Component B, using `task-planner` agent type
**Team name**: `tasks-$spec`
**Teammate name**: `planner-1`

### Component E: Team-Based Parallel Execution (implement.md)
**Purpose**: Convert [P] parallel task batches to use teams
**Current**: Multiple Task calls in one message (no team infrastructure)
**New**: For [P] batches: TeamCreate -> TaskCreate per task -> Task per executor -> merge -> TeamDelete
**Sequential tasks**: Unchanged (direct Task call, no team)

**Changes to `plugins/ralph-specum/commands/implement.md`**:

Modify Section 6 "Parallel Execution" to use teams:

```markdown
### Parallel Execution (parallelGroup.isParallel = true, Team-Based):

1. Check for orphaned team: Read ~/.claude/teams/exec-$spec/config.json
   If exists: TeamDelete()

2. TeamCreate(team_name: "exec-$spec", description: "Parallel execution batch")

3. For each taskIndex in parallelGroup.taskIndices:
   TaskCreate(subject: "Execute task $taskIndex", ...)

4. ALL Task calls in ONE message:
   Task(subagent_type: spec-executor, team_name: "exec-$spec", name: "executor-$taskIndex", ...)

5. Wait for all teammates to complete via TaskList

6. SendMessage(type: "shutdown_request") per teammate

7. TeamDelete()

8. Proceed to progress merge and state update
```

## Data Flow

1. Phase command starts -> check for orphaned team -> TeamCreate
2. TaskCreate for work items -> Task tool spawns teammates
3. Teammates execute work, write output files, mark tasks complete
4. Coordinator monitors via TaskList / automatic messages
5. Teammates shut down -> TeamDelete -> merge results
6. Update state file -> commit (if enabled) -> stop or continue

## Technical Decisions

| Decision | Options | Choice | Rationale |
|----------|---------|--------|-----------|
| Single-agent phases use teams | Skip teams / Use teams | Use teams | Consistency across all phases; matches goal of enforcing teams everywhere |
| Sequential execution tasks | Use teams / Keep Task | Keep Task | No parallelism benefit; teams add overhead to each loop iteration |
| Parallel execution batches | Keep multi-Task / Use teams | Use teams | Teams provide better coordination for multi-agent parallel work |
| Team naming convention | Generic / Phase-prefixed | Phase-prefixed | `$phase-$spec` prevents collisions across concurrent phases |
| Orphaned team cleanup | Skip / Auto-cleanup | Auto-cleanup | Prevents stale teams from interrupted sessions |

## File Structure

| File | Action | Purpose |
|------|--------|---------|
| `plugins/ralph-specum/commands/research.md` | Modify | Convert multi-Task to team-based pattern |
| `plugins/ralph-specum/commands/requirements.md` | Modify | Add team lifecycle wrapper around product-manager delegation |
| `plugins/ralph-specum/commands/design.md` | Modify | Add team lifecycle wrapper around architect-reviewer delegation |
| `plugins/ralph-specum/commands/tasks.md` | Modify | Add team lifecycle wrapper around task-planner delegation |
| `plugins/ralph-specum/commands/implement.md` | Modify | Convert [P] parallel batch execution to team-based |
| `plugins/ralph-specum/.claude-plugin/plugin.json` | Modify | Version bump |
| `.claude-plugin/marketplace.json` | Modify | Version bump |

## Error Handling

| Error | Handling | User Impact |
|-------|----------|-------------|
| Orphaned team from interrupted session | Auto-detect and TeamDelete before creating new team | Transparent; no user action needed |
| TeamCreate failure | Fall back to direct Task delegation (no team) | Warning displayed; phase continues |
| Teammate fails to complete | Timeout after reasonable period; check TaskList | Error logged; retry or manual intervention |
| TeamDelete failure | Log warning; team files cleaned up on next run | No impact; cleanup is idempotent |
| Shutdown request rejected by teammate | Log and force cleanup via TeamDelete | Teammate state cleaned regardless |

## Existing Patterns to Follow
- Team lifecycle in `plugins/ralph-specum/commands/start.md` lines 1127-1430 (sections 11a-11h)
- Multi-Task parallelism in `plugins/ralph-specum/commands/research.md` Execute Research section
- Stop-hook loop in `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
- State management pattern: read state -> modify -> write back via jq merge
