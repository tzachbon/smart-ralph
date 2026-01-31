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

### Plugin Validation

Run the validation script to check all plugins for compliance:

```bash
bash scripts/validate-plugins.sh
```

This checks:
- Agent `color:` fields and `<example>` blocks
- Skill `version:` fields
- Hook `matcher` fields
- No legacy command directories

### Agent Color Conventions

Assign colors by function for visual consistency:
- **blue/cyan** - Analysis agents (research-analyst, architect-reviewer)
- **green** - Execution agents (spec-executor)
- **yellow** - Validation agents (qa-engineer)
- **magenta** - Transformation agents (task-planner, product-manager)

### Plugin Development Skills (ALWAYS USE)

When creating or modifying plugin components, **ALWAYS** use the `plugin-dev` skills for guidance:

- `/plugin-dev:plugin-structure` - Plugin manifest, directory layout, component organization
- `/plugin-dev:command-development` - Creating slash commands with frontmatter
- `/plugin-dev:skill-development` - Creating skills with progressive disclosure
- `/plugin-dev:agent-development` - Creating subagents with system prompts
- `/plugin-dev:hook-development` - Creating hooks (PreToolUse, PostToolUse, Stop, etc.)
- `/plugin-dev:mcp-integration` - Integrating MCP servers into plugins
- `/plugin-dev:plugin-settings` - Plugin configuration with .local.md files
- `/plugin-dev:create-plugin` - Guided end-to-end plugin creation workflow

**Example:** Before adding a new command, run `/plugin-dev:command-development` to ensure correct frontmatter and structure.

## Architecture

### Plugin Structure

```
plugins/ralph-specum/
├── .claude-plugin/plugin.json   # Plugin manifest
├── agents/                      # Sub-agent definitions (markdown)
├── commands/                    # Slash command definitions (markdown)
├── hooks/                       # Stop watcher (logging only, Ralph Loop handles loop)
├── templates/                   # Spec file templates
└── schemas/                     # JSON schema for spec validation
```

### Execution Flow

1. **Spec Phases**: Each command (`/ralph-specum:research`, `:requirements`, `:design`, `:tasks`) invokes a specialized agent to generate corresponding markdown in `./specs/<spec-name>/`
2. **Ralph Loop**: During execution (`/ralph-specum:implement`), the command invokes `/ralph-loop` from the Ralph Loop plugin. The coordinator prompt reads `.ralph-state.json`, delegates tasks to spec-executor via Task tool, and outputs `ALL_TASKS_COMPLETE` when done.
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

Spec-executor must output `TASK_COMPLETE` for coordinator to advance. Coordinator outputs `ALL_TASKS_COMPLETE` to end the Ralph Loop. If task fails, retries up to 5 times then blocks with error.

### Dependencies

Requires Ralph Loop plugin: `/plugin install ralph-loop@claude-plugins-official`

**Note:** If you see "marketplace not found" errors, first add the official marketplace:
```bash
/plugin marketplace add anthropics/claude-code
/plugin install ralph-loop@claude-plugins-official
```

## Key Files

- `commands/implement.md` - Thin wrapper + coordinator prompt for Ralph Loop
- `commands/cancel.md` - Dual cleanup (cancel-ralph + state file deletion)
- `hooks/scripts/stop-watcher.sh` - Logging/validation watcher (does NOT control loop)
- `agents/spec-executor.md` - Task execution rules, commit discipline
- `agents/task-planner.md` - Task format, quality checkpoint rules, POC workflow
- `templates/*.md` - Spec file templates with structure requirements
