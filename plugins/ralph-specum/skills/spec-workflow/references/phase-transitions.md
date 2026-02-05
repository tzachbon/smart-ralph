# Phase Transitions

Detailed flow for spec-driven development phases.

## Phase Order

```
new/start -> research -> requirements -> design -> tasks -> implement
```

## Phase Details

### 1. Research Phase

**Command**: `/ralph-specum:research`
**Agent**: research-analyst
**Output**: `./specs/<name>/research.md`

Activities:
- Web search for best practices
- Codebase analysis for existing patterns
- Related specs discovery
- Quality command discovery
- Feasibility assessment

Ends with: `awaitingApproval: true`

### 2. Requirements Phase

**Command**: `/ralph-specum:requirements`
**Agent**: product-manager
**Output**: `./specs/<name>/requirements.md`

Activities:
- User stories creation
- Acceptance criteria definition
- Functional requirements table
- Non-functional requirements
- Out of scope items

Ends with: `awaitingApproval: true`

### 3. Design Phase

**Command**: `/ralph-specum:design`
**Agent**: architect-reviewer
**Output**: `./specs/<name>/design.md`

Activities:
- Architecture diagrams (mermaid)
- Component definitions
- Interface specifications
- Data flow documentation
- Technical decisions table
- Test strategy

Ends with: `awaitingApproval: true`

### 4. Tasks Phase

**Command**: `/ralph-specum:tasks`
**Agent**: task-planner
**Output**: `./specs/<name>/tasks.md`

Activities:
- POC-first task breakdown
- 4-phase structure (POC, Refactor, Test, Quality)
- Verify commands for each task
- Commit messages
- Quality checkpoints every 2-3 tasks

Ends with: `awaitingApproval: true`

### 5. Execution Phase

**Command**: `/ralph-specum:implement`
**Agent**: spec-executor (via Ralph Wiggum)
**State**: `phase: "execution"`

Activities:
- Task-by-task execution
- Verification after each task
- Commit after verified completion
- Progress tracking in `.progress.md`

Ends with: State file deleted on completion

## Quick Mode

With `--quick` flag:
- All phases run automatically via plan-synthesizer
- No `awaitingApproval` pauses
- Transitions directly to execution

## State File Transitions

| Phase | State Value |
|-------|-------------|
| Research | `"research"` |
| Requirements | `"requirements"` |
| Design | `"design"` |
| Tasks | `"tasks"` |
| Execution | `"execution"` |

## Phase Skipping

Not recommended but possible:
- `/ralph-specum:tasks` can be run after minimal research
- Quality may suffer without full spec phases
- Use `--fresh` to restart from any phase
