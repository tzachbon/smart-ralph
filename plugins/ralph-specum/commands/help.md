---
description: Show help for Ralph Specum plugin commands and workflow.
---

# Ralph Specum Help

## Overview

Ralph Specum is a spec-driven development plugin that guides you through research, requirements, design, and task generation phases, then executes tasks autonomously with fresh context per task.

## Commands

| Command | Description |
|---------|-------------|
| `/ralph-specum:start [name] [goal]` | Smart entry point: resume or create new |
| `/ralph-specum:new <name> [goal]` | Create new spec and start research |
| `/ralph-specum:research` | Run/re-run research phase |
| `/ralph-specum:requirements` | Generate requirements (approves research) |
| `/ralph-specum:design` | Generate design (approves requirements) |
| `/ralph-specum:tasks` | Generate tasks (approves design) |
| `/ralph-specum:prototype [--resume ID \| --cancel ID \| --quick]` | Run, resume, or cancel optional prototype evidence |
| `/ralph-specum:implement` | Start execution loop (approves tasks) |
| `/ralph-specum:status` | Show all specs and progress |
| `/ralph-specum:switch <name>` | Change active spec |
| `/ralph-specum:cancel` | Safely cancel active work; source is preserved |
| `/ralph-specum:feedback [message]` | Submit feedback or report an issue |
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
# Easiest: use start (auto-detects resume or new)
/ralph-specum:start user-auth Add JWT authentication

# Or resume an existing spec
/ralph-specum:start

# Manual workflow with individual commands:
/ralph-specum:new user-auth Add JWT authentication
/ralph-specum:requirements
/ralph-specum:design
/ralph-specum:tasks
/ralph-specum:implement
```

## Optional Prototype Overlay

Research and requirements may offer `continue to prototype`; declining continues the normal workflow. `/ralph-specum:prototype` is also available directly from research, requirements, design, tasks, or execution without changing the main phase.

- `/ralph-specum:prototype --resume <id>` resumes an explicit active entry. One active entry resumes automatically; several are listed for selection in normal mode.
- `/ralph-specum:prototype --cancel <id>` stops at a safe boundary, publishes and verifies an immutable `cancelled` record, and preserves source and partial work.
- `--quick` runs exactly one agent-owned request after requirements. It asks no prototype questions, takes over the oldest design blocker when one exists, owns verdict and handoff decisions, and continues to design.
- Prototype source runs in a sibling worktree or eligible scratch area. Ralph never switches the current conversation checkout or copies unapproved dirty paths.
- Source, evidence, branches, and records stay local. Pushes, PR or issue changes, and every remote action require separate explicit authorization. Local deletion also requires exact-path and local-branch approval; remote branches are never deleted by prototype cleanup.

Terminal records live under the resolved `<basePath>/prototypes/`. `status` shows active entries, review candidates, immutable finals, quarantines, blockers, return phase/task, and source disposition.

## Options

### start command
```
/ralph-specum:start [name] [goal] [--fresh] [--quick] [--commit-spec] [--no-commit-spec]
```
- `--fresh`: Force new spec, overwrite if exists (skips "resume or fresh?" prompt)
- `--quick`: Skip interactive phases, auto-generate all specs, start execution immediately
- `--commit-spec`: Commit spec files locally after each phase (default: true in normal mode, false in quick mode). Normal-mode phase pushes keep their existing behavior after the Prototype Evidence Push Gate; prototype records require separate authorization naming the exact records.
- `--no-commit-spec`: Explicitly disable committing spec files

The `--commit-spec` setting is stored in `.ralph-state.json` and applies to local commits in all subsequent phases (research, requirements, design, tasks). It authorizes no remote prototype evidence action.

### new command
```
/ralph-specum:new <name> [goal] [--skip-research]
```
- `--skip-research`: Skip research phase, start with requirements

### phase commands (research, requirements, design, tasks)
```
/ralph-specum:<phase> [spec-name]
```
Phase commands use the `commitSpec` setting from `.ralph-state.json` (set during `/ralph-specum:start`).

### implement command
```
/ralph-specum:implement [--max-task-iterations 5]
```
- `--max-task-iterations`: Max retries per task before failure (default: 5)

### cancel command

Safe cancel deletes only execution state after every active prototype has a verified immutable `cancelled` record. It keeps the spec, prototype source, partial implementation, records, and local branches. Full spec removal requires a second confirmation naming the exact resolved directory; prototype paths and branches require separate confirmations.

## Directory Structure

Specs are stored in `./specs/` by default:
```
./specs/
├── .current-spec           # Active spec name (or full path for multi-dir)
├── my-feature/
│   ├── .ralph-state.json   # Loop state (deleted on completion)
│   ├── .progress.md        # Progress tracking (persists)
│   ├── research.md         # Research findings
│   ├── requirements.md     # Requirements
│   ├── design.md           # Technical design
│   ├── tasks.md            # Implementation tasks
│   └── prototypes/         # Immutable terminal prototype records
```

## Multi-Directory Support

You can organize specs across multiple directories using the `specs_dirs` configuration.

### Configuration

Add `specs_dirs` to your settings file at `.claude/ralph-specum.local.md`:

```yaml
---
specs_dirs:
  - ./specs
  - ./packages/api/specs
  - ./packages/web/specs
---
```

If not configured, defaults to `["./specs"]` for backward compatibility.

### Using --specs-dir Flag

The `start` and `new` commands accept `--specs-dir` to specify where to create a spec:

```bash
# Create spec in default directory (./specs/)
/ralph-specum:start my-feature Some goal

# Create spec in a specific directory
/ralph-specum:start my-feature Some goal --specs-dir ./packages/api/specs
/ralph-specum:new api-auth --specs-dir ./packages/api/specs
```

The specified directory must be listed in `specs_dirs` configuration.

### Monorepo Example

For a monorepo with multiple packages:

```
my-monorepo/
├── .claude/
│   └── ralph-specum.local.md    # specs_dirs config
├── packages/
│   ├── api/
│   │   └── specs/               # API-related specs
│   │       └── auth-feature/
│   └── web/
│       └── specs/               # Web-related specs
│           └── dashboard-feature/
└── specs/                       # Shared/root specs
    └── infrastructure-feature/
```

Settings file:
```yaml
---
specs_dirs:
  - ./specs
  - ./packages/api/specs
  - ./packages/web/specs
---
```

### Disambiguation

When the same spec name exists in multiple directories, commands will prompt for disambiguation:

```
Multiple specs named "auth-feature" found:
  1. ./specs/auth-feature
  2. ./packages/api/specs/auth-feature

Specify the full path to switch:
  /ralph-specum:switch ./packages/api/specs/auth-feature
```

Use the full path to target a specific spec when names are ambiguous.

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
