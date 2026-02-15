---
spec: opencode-codex-support
phase: requirements
created: 2026-02-15
generated: auto
---

# Requirements: opencode-codex-support

## Summary

Enable the Smart Ralph spec-driven workflow (research, requirements, design, tasks, execute) to work natively across Claude Code, OpenCode, and Codex CLI by converting commands to universal SKILL.md files, creating tool-specific execution adapters, and building a configuration bridge.

## User Stories

### US-1: Portable spec workflow via SKILL.md
As an OpenCode or Codex CLI user, I want to discover and run the Ralph spec workflow through SKILL.md files so that I can use spec-driven development without Claude Code.

**Acceptance Criteria**:
- AC-1.1: SKILL.md files exist for all 8 core commands (start, research, requirements, design, tasks, implement, status, cancel)
- AC-1.2: Each SKILL.md uses progressive disclosure (overview -> details -> advanced)
- AC-1.3: SKILL.md files contain no Claude Code-specific tool references (no Task tool, no AskUserQuestion, no TeamCreate)
- AC-1.4: A user in OpenCode can invoke `$ralph:start` or equivalent and begin the workflow
- AC-1.5: A user in Codex CLI can discover Ralph skills and follow the workflow

### US-2: Cross-tool spec artifact compatibility
As a developer using multiple AI tools, I want spec artifacts generated in one tool to be executable in another so that I can switch tools mid-workflow.

**Acceptance Criteria**:
- AC-2.1: Spec artifacts (research.md, requirements.md, design.md, tasks.md, .progress.md, .ralph-state.json) contain zero tool-specific references
- AC-2.2: Templates and schemas produce identical output regardless of tool
- AC-2.3: .ralph-state.json schema works across all three tools

### US-3: Execution loop in OpenCode
As an OpenCode user, I want the task execution loop to run autonomously so that tasks execute sequentially without manual intervention.

**Acceptance Criteria**:
- AC-3.1: OpenCode JS/TS adapter provides execution loop via hook system
- AC-3.2: Adapter reads .ralph-state.json and advances tasks
- AC-3.3: Adapter delegates to spec-executor equivalent
- AC-3.4: Adapter handles TASK_COMPLETE and ALL_TASKS_COMPLETE signals

### US-4: Execution guidance in Codex CLI
As a Codex CLI user, I want step-by-step task execution guidance so that I can complete tasks sequentially using SKILL.md progressive disclosure.

**Acceptance Criteria**:
- AC-4.1: Implement SKILL.md guides through current task based on .ralph-state.json
- AC-4.2: After each task, user can re-invoke skill for next task
- AC-4.3: State file updates work without hooks

### US-5: AGENTS.md generation
As an OpenCode or Codex CLI user, I want an AGENTS.md file generated from spec design decisions so that my tool has project-level context.

**Acceptance Criteria**:
- AC-5.1: AGENTS.md generated as optional output alongside spec artifacts
- AC-5.2: Contains key architecture decisions, patterns, and conventions from design.md
- AC-5.3: Format compatible with both OpenCode and Codex CLI

### US-6: Configuration bridge
As a developer setting up Ralph in a new tool, I want a unified config that generates tool-specific configurations so that setup is straightforward.

**Acceptance Criteria**:
- AC-6.1: `ralph-config.json` defines tool-agnostic Ralph settings
- AC-6.2: Generator produces Claude Code config (.claude-plugin/plugin.json, hooks/)
- AC-6.3: Generator produces OpenCode config (opencode.json, .opencode/)
- AC-6.4: Generator produces Codex CLI config (AGENTS.md, skills/)

### US-7: Zero regression for Claude Code users
As an existing Claude Code user, I want the current plugin to work identically after this change.

**Acceptance Criteria**:
- AC-7.1: All existing commands work unchanged
- AC-7.2: Stop hook continues to function
- AC-7.3: Agent delegation via Task tool unchanged
- AC-7.4: Team research via TeamCreate unchanged

## Functional Requirements

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| FR-1 | Create SKILL.md files for 8 core commands: start, research, requirements, design, tasks, implement, status, cancel | Must | US-1 |
| FR-2 | SKILL.md files use progressive disclosure (Level 1: overview, Level 2: steps, Level 3: advanced config) | Must | US-1 |
| FR-3 | SKILL.md files reference tool-agnostic state management (read/write .ralph-state.json and .progress.md) | Must | US-1, US-2 |
| FR-4 | Audit and fix any Claude Code-specific assumptions in templates and schemas | Must | US-2 |
| FR-5 | Create OpenCode JS/TS execution adapter with hooks for execution loop | Should | US-3 |
| FR-6 | Create Codex CLI implement SKILL.md with manual task progression guidance | Must | US-4 |
| FR-7 | Generate AGENTS.md from design.md during spec synthesis | Should | US-5 |
| FR-8 | Create ralph-config.json schema and tool-specific config generators | Could | US-6 |
| FR-9 | Preserve all existing Claude Code plugin functionality without changes | Must | US-7 |
| FR-10 | Create adapter abstraction layer for tool-specific behaviors (delegation, hooks, team research) | Should | US-3, US-4 |

## Non-Functional Requirements

| ID | Requirement | Category |
|----|-------------|----------|
| NFR-1 | SKILL.md files must be under 500 lines each (progressive disclosure keeps them scannable) | Usability |
| NFR-2 | Existing Claude Code plugin startup time must not increase | Performance |
| NFR-3 | New files must follow existing project conventions (kebab-case, markdown) | Maintainability |
| NFR-4 | Tool-specific adapters must be isolated in separate directories | Maintainability |

## Out of Scope

- MCP server implementation for Codex (future deliverable)
- OpenCode/Codex CI/CD integration
- GUI or web interface
- Automated migration of existing specs between tools
- Plugin marketplace publishing for OpenCode/Codex

## Dependencies

- OpenCode JS/TS plugin API documentation
- Codex CLI SKILL.md discovery mechanism
- Existing Claude Code plugin system (no changes)
