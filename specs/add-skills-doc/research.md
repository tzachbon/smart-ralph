---
spec: add-skills-doc
phase: research
created: 2026-01-13
generated: auto
---

# Research: add-skills-doc

## Executive Summary

Adding SKILL.md files to ralph-specum is straightforward documentation work. The plugin has 11 commands but no skills/ folder. Skills enable Claude Code to auto-invoke commands based on user intent.

## Codebase Analysis

### Existing Patterns

- Commands follow consistent frontmatter: `description`, `argument-hint`, `allowed-tools`
- Plugin structure: `.claude-plugin/plugin.json`, `commands/*.md`, `agents/*.md`, `templates/*.md`
- No existing skills/ directory in source repo

### Commands to Document

| Command | Purpose |
|---------|---------|
| start | Smart entry point, resume or create |
| new | Create new spec, start research |
| research | Run research phase |
| requirements | Generate requirements |
| design | Generate design |
| tasks | Generate tasks |
| implement | Start execution loop |
| status | Show all specs status |
| switch | Change active spec |
| cancel | Cancel active loop |
| help | Show help |

### Dependencies

- None. Pure documentation addition.

### Constraints

- Must follow SKILL.md frontmatter format: `name`, `description`
- Skills should be grouped logically in a subfolder

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | High | Just adding markdown files |
| Effort Estimate | S | ~1 hour work |
| Risk Level | Low | No code changes |

## Recommendations

1. Create `skills/spec-workflow/SKILL.md` for spec lifecycle commands
2. Group by intent: starting work, phases, management, help
3. Keep descriptions actionable and intent-focused
