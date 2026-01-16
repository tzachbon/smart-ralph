# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Smart Ralph is a Claude Code plugin for spec-driven development. It transforms feature requests into structured specs (research, requirements, design, tasks) then executes them task-by-task with fresh context per task.

## Development

```bash
# Test plugin locally
claude --plugin-dir ./plugins/ralph-specum

# Test the workflow
/ralph-specum:start test-feature Some test goal
```

> Update each change, fix or addition, update the plugin version in the plugin.json file.

No build step required. Changes take effect on Claude Code restart.

## Architecture

### Plugin Structure

```
plugins/ralph-specum/
├── .claude-plugin/plugin.json   # Plugin manifest
├── agents/                      # Sub-agent definitions (markdown)
├── commands/                    # Slash command definitions (markdown)
├── hooks/                       # Stop watcher (logging only, Ralph Wiggum handles loop)
├── templates/                   # Spec file templates
└── schemas/                     # JSON schema for spec validation
```

### Execution Flow

1. **Spec Phases**: Each command (`/ralph-specum:research`, `:requirements`, `:design`, `:tasks`) invokes a specialized agent to generate corresponding markdown in `./specs/<spec-name>/`
2. **Ralph Wiggum Loop**: During execution (`/ralph-specum:implement`), the command invokes `/ralph-loop` from the Ralph Wiggum plugin. The coordinator prompt reads `.ralph-state.json`, delegates tasks to spec-executor via Task tool, and outputs `ALL_TASKS_COMPLETE` when done.
3. **Fresh Context**: Each task runs in isolation via Task tool. Progress persists in `.progress.md` and task checkmarks in `tasks.md`

### State Files

- `./specs/.current-spec` - Active spec name
- `./specs/<name>/.ralph-state.json` - Loop state (phase, taskIndex, iterations). Deleted on completion
- `./specs/<name>/.progress.md` - Progress tracking, learnings, context for agents

### Agents

| Agent | File | Purpose |
|-------|------|---------|
| research-analyst | `agents/research-analyst.md` | Web search, codebase analysis |
| product-manager | `agents/product-manager.md` | User stories, acceptance criteria |
| architect-reviewer | `agents/architect-reviewer.md` | Technical design, architecture |
| task-planner | `agents/task-planner.md` | POC-first task breakdown |
| spec-executor | `agents/spec-executor.md` | Autonomous task implementation |

### POC-First Workflow (Mandatory)

All specs follow 4 phases:
1. **Phase 1: Make It Work** - POC validation, skip tests
2. **Phase 2: Refactoring** - Code cleanup
3. **Phase 3: Testing** - Unit, integration, e2e
4. **Phase 4: Quality Gates** - Lint, types, CI, PR

Quality checkpoints inserted every 2-3 tasks throughout all phases.

### Task Completion Protocol

Spec-executor must output `TASK_COMPLETE` for coordinator to advance. Coordinator outputs `ALL_TASKS_COMPLETE` to end the Ralph Wiggum loop. If task fails, retries up to 5 times then blocks with error.

### Dependencies

Requires Ralph Wiggum plugin: `/plugin install ralph-wiggum@claude-plugins-official`

## Key Files

- `commands/implement.md` - Thin wrapper + coordinator prompt for Ralph Wiggum loop
- `commands/cancel.md` - Dual cleanup (cancel-ralph + state file deletion)
- `hooks/scripts/stop-watcher.sh` - Logging/validation watcher (does NOT control loop)
- `agents/spec-executor.md` - Task execution rules, commit discipline
- `agents/task-planner.md` - Task format, quality checkpoint rules, POC workflow
- `templates/*.md` - Spec file templates with structure requirements
