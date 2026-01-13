---
spec: add-skills-doc
phase: design
created: 2026-01-13
generated: auto
---

# Design: add-skills-doc

## Overview

Add a single SKILL.md file under `skills/spec-workflow/` that maps user intents to ralph-specum commands.

## Architecture

```
plugins/ralph-specum/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   └── *.md (11 files, unchanged)
├── skills/                    <-- NEW
│   └── spec-workflow/         <-- NEW
│       └── SKILL.md           <-- NEW
├── agents/
├── templates/
└── hooks/
```

## Components

### SKILL.md

**Purpose**: Help Claude Code match user intent to commands
**Content Structure**:
- Frontmatter: name, description
- Body: Intent patterns and command mappings

## SKILL.md Content Design

```markdown
---
name: spec-workflow
description: Spec-driven development workflow for building features with research, requirements, design, and task phases
---

# Spec Workflow Skill

## When to Use

Use these commands when user wants to:
- Build a new feature or system
- Create technical specifications
- Plan development work
- Track spec progress

## Commands

### Starting Work
- `/ralph-specum:start [name] [goal]` - Start or resume a spec (smart entry point)
- `/ralph-specum:new <name> [goal]` - Create new spec and begin research

### Spec Phases
- `/ralph-specum:research` - Run research phase
- `/ralph-specum:requirements` - Generate requirements from research
- `/ralph-specum:design` - Generate technical design
- `/ralph-specum:tasks` - Generate implementation tasks

### Execution
- `/ralph-specum:implement` - Start autonomous task execution

### Management
- `/ralph-specum:status` - Show all specs and progress
- `/ralph-specum:switch <name>` - Change active spec
- `/ralph-specum:cancel` - Cancel active execution

### Help
- `/ralph-specum:help` - Show plugin help
```

## File Structure

| File | Action | Purpose |
|------|--------|---------|
| `plugins/ralph-specum/skills/spec-workflow/SKILL.md` | Create | Enable Claude auto-invocation |

## Existing Patterns to Follow

- Command frontmatter uses `description`, `argument-hint`
- Following same style: brief, action-oriented descriptions
- Path pattern: `plugins/ralph-specum/<type>/<name>/<file>`
