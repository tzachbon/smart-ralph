# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ⛔ CRITICAL SAFETY RULES

1. **NEVER merge PRs without explicit user permission** — If unsure whether to merge, the answer is NO
2. **NEVER close PRs without explicit user permission** — Only fix conflicts, push changes, create PRs
3. **NEVER delete branches on remote without explicit user permission**
4. **Ask before any destructive action** — When in doubt, ask the user

## Overview

Smart Ralph is a Claude Code plugin for spec-driven development. It transforms feature requests into structured specs (research, requirements, design, tasks) then executes them task-by-task with fresh context per task.

## Development

```bash
# Test plugin locally
claude --plugin-dir ./plugins/ralph-specum

# Test the workflow
/ralph-specum:start test-feature Some test goal
```

> **⚠️ CRITICAL: Version bumps are REQUIRED for ANY plugin change**
>
> When making ANY changes to plugin files (commands, agents, hooks, templates, schemas):
> 1. **ALWAYS bump the version** in BOTH files for the modified plugin:
>    - `plugins/<plugin-name>/.claude-plugin/plugin.json` (the plugin you're modifying)
>    - `.claude-plugin/marketplace.json` (update the corresponding plugin entry)
> 2. Use semantic versioning: patch (fixes), minor (features), major (breaking)
> 3. Bump once per set of related changes (not per commit)
> 4. Only update the version for plugins you actually modified

No build step required. Changes take effect on Claude Code restart.

## Architecture

### Plugin Structure

```
plugins/ralph-specum/
├── .claude-plugin/plugin.json   # Plugin manifest
├── agents/                      # Sub-agent definitions (markdown)
├── commands/                    # Slash command definitions (markdown)
├── hooks/                       # Stop hook (controls execution loop)
├── templates/                   # Spec file templates
└── schemas/                     # JSON schema for spec validation
```

### Execution Flow

1. **Spec Phases**: Each command (`/ralph-specum:research`, `:requirements`, `:design`, `:tasks`) invokes a specialized agent to generate corresponding markdown in `./specs/<spec-name>/`
2. **Execution Loop**: During execution (`/ralph-specum:implement`), the stop-hook blocks session exit and injects a continuation prompt. The coordinator reads `.ralph-state.json`, delegates tasks to spec-executor via Task tool, and outputs `ALL_TASKS_COMPLETE` when done.
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

Spec-executor must output `TASK_COMPLETE` for coordinator to advance. Coordinator outputs `ALL_TASKS_COMPLETE` to end the execution loop (detected by stop-hook). If task fails, retries up to 5 times then blocks with error.

## Key Files

- `commands/implement.md` - Initializes state + coordinator prompt for execution
- `commands/cancel.md` - Cleanup (removes state file to stop loop)
- `hooks/scripts/stop-watcher.sh` - Controls execution loop (blocks exit, injects continuation)
- `agents/spec-executor.md` - Task execution rules, commit discipline
- `agents/task-planner.md` - Task format, quality checkpoint rules, POC workflow
- `templates/*.md` - Spec file templates with structure requirements
