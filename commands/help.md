---
description: Show help for Ralph Specum plugin commands and workflow.
---

# Ralph Specum Help

## Overview

Ralph Specum is a spec-driven development plugin that guides you through research, requirements, design, and task generation phases, then executes tasks autonomously with fresh context per task.

## Commands

| Command | Description |
|---------|-------------|
| `/ralph-specum:new <name>` | Create new spec and start research |
| `/ralph-specum:research` | Run/re-run research phase |
| `/ralph-specum:requirements` | Generate requirements (approves research) |
| `/ralph-specum:design` | Generate design (approves requirements) |
| `/ralph-specum:tasks` | Generate tasks (approves design) |
| `/ralph-specum:implement` | Start execution loop (approves tasks) |
| `/ralph-specum:status` | Show all specs and progress |
| `/ralph-specum:switch <name>` | Change active spec |
| `/ralph-specum:cancel` | Cancel active loop, cleanup state |
| `/ralph-specum:help` | Show this help |

## Workflow

```
/ralph-specum:new "my-feature"
    |
    v
[Research Phase] - Automatic on new
    |
    v (review research.md)
/ralph-specum:requirements
    |
    v (review requirements.md)
/ralph-specum:design
    |
    v (review design.md)
/ralph-specum:tasks
    |
    v (review tasks.md)
/ralph-specum:implement
    |
    v
[Task-by-task execution with fresh context]
    |
    v
Done!
```

## Quick Start

```bash
# Create new spec (auto-runs research)
/ralph-specum:new user-authentication

# Review research.md, then generate requirements
/ralph-specum:requirements

# Review requirements.md, then generate design
/ralph-specum:design

# Review design.md, then generate tasks
/ralph-specum:tasks

# Review tasks.md, then start execution
/ralph-specum:implement
```

## Options

### new command
```
/ralph-specum:new <name> [--skip-research]
```
- `--skip-research`: Skip research phase, start with requirements

### implement command
```
/ralph-specum:implement [--max-task-iterations 5]
```
- `--max-task-iterations`: Max retries per task before failure (default: 5)

## Directory Structure

Specs are stored in `./specs/`:
```
./specs/
├── .current-spec           # Active spec name
├── my-feature/
│   ├── .ralph-state.json   # Loop state (deleted on completion)
│   ├── .progress.md        # Progress tracking (persists)
│   ├── research.md         # Research findings
│   ├── requirements.md     # Requirements
│   ├── design.md           # Technical design
│   └── tasks.md            # Implementation tasks
```

## Execution Loop

The implement command runs tasks one at a time:
1. Execute task from tasks.md
2. Verify completion
3. Commit changes
4. Update progress
5. Stop and restart with fresh context
6. Continue until all tasks done

This ensures each task has full context without accumulating irrelevant history.

## Sub-Agents

Each phase uses a specialized agent:
- **research-analyst**: Research and feasibility analysis
- **product-manager**: Requirements and user stories
- **architect-reviewer**: Technical design and architecture
- **task-planner**: POC-first task breakdown
- **spec-executor**: Autonomous task execution

## POC-First Workflow

Tasks follow a 4-phase structure:
1. **Phase 1: Make It Work** - POC validation, skip tests
2. **Phase 2: Refactoring** - Clean up code
3. **Phase 3: Testing** - Unit, integration, e2e tests
4. **Phase 4: Quality Gates** - Lint, types, CI

## Troubleshooting

**Spec not found?**
- Run `/ralph-specum:status` to see available specs
- Run `/ralph-specum:switch <name>` to change active spec

**Task failing repeatedly?**
- After 5 attempts, hook blocks with error message
- Fix manually, then run `/ralph-specum:implement` to resume

**Want to restart?**
- Run `/ralph-specum:cancel` to cleanup state
- Progress file is preserved with completed tasks
