---
name: spec-workflow
version: 0.1.0
description: This skill should be used when the user asks to "build a feature", "create a spec", "start spec-driven development", "run research phase", "generate requirements", "create design", "plan tasks", "implement spec", "check spec status", or needs guidance on the spec-driven development workflow.
---

# Spec Workflow Skill

Spec-driven development workflow for building features through research, requirements, design, and task phases.

## When to Use

Use these commands when user wants to:
- Build a new feature or system
- Create technical specifications
- Plan development work
- Track spec progress
- Execute spec-driven implementation

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

## Phase Flow

See `references/phase-transitions.md` for detailed phase flow documentation.
