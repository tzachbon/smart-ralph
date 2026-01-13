---
spec: add-skills-doc
phase: requirements
created: 2026-01-13
generated: auto
---

# Requirements: add-skills-doc

## Summary

Add SKILL.md documentation so Claude Code knows when to auto-invoke ralph-specum commands based on user intent.

## User Stories

### US-1: Auto-invoke spec workflow

As a developer, I want Claude Code to suggest ralph-specum commands when I describe wanting to build something so that I do not need to remember command names.

**Acceptance Criteria**:
- AC-1.1: Saying "I want to build a new feature" suggests `/ralph-specum:start`
- AC-1.2: Saying "show my spec progress" suggests `/ralph-specum:status`

### US-2: Phase-appropriate suggestions

As a developer working on a spec, I want Claude Code to suggest the next phase command so that the workflow is seamless.

**Acceptance Criteria**:
- AC-2.1: After research completes, requirements command is discoverable
- AC-2.2: After design completes, tasks command is discoverable

## Functional Requirements

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| FR-1 | Create skills/ directory in plugin | Must | US-1 |
| FR-2 | Create SKILL.md with command mapping | Must | US-1 |
| FR-3 | Include all 11 commands in skill description | Must | US-1, US-2 |
| FR-4 | Use intent-based descriptions | Should | US-1 |

## Non-Functional Requirements

| ID | Requirement | Category |
|----|-------------|----------|
| NFR-1 | SKILL.md must follow Claude plugin skill format | Compatibility |
| NFR-2 | Descriptions must be concise (<100 chars each) | Usability |

## Out of Scope

- Modifying existing commands
- Adding new commands
- Code changes to plugin logic

## Dependencies

- None
