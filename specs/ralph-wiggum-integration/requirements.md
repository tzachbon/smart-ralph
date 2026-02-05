---
spec: ralph-wiggum-integration
phase: requirements
created: 2026-02-05
generated: auto
---

# Requirements: ralph-wiggum-integration

## Summary

Adapt smart-ralph's implement.md command to use the ralph-wiggum plugin API, changing completion signals from raw text to `<promise>` tag format.

## User Stories

### US-1: Execute spec with ralph-wiggum

As a developer, I want `/ralph-specum:implement` to work with ralph-wiggum so that the execution loop runs correctly with the new plugin API.

**Acceptance Criteria**:
- AC-1.1: Command invokes `ralph-wiggum:ralph-wiggum` skill instead of `ralph-loop:ralph-loop`
- AC-1.2: Loop continues until `<promise>ALL_TASKS_COMPLETE</promise>` detected
- AC-1.3: State-based coordinator works correctly when same prompt re-fed each iteration

### US-2: Correct completion signaling

As a coordinator prompt, I want to output completion in `<promise>` tag format so that ralph-wiggum detects completion and exits the loop.

**Acceptance Criteria**:
- AC-2.1: Coordinator outputs `<promise>ALL_TASKS_COMPLETE</promise>` instead of raw `ALL_TASKS_COMPLETE`
- AC-2.2: Promise tags appear only when all tasks truly complete
- AC-2.3: Existing verification layers still run before completion signal

### US-3: Updated documentation

As a developer, I want CLAUDE.md to reference ralph-wiggum so that setup instructions are accurate.

**Acceptance Criteria**:
- AC-3.1: Dependencies section references `ralph-wiggum@claude-plugins-official`
- AC-3.2: All references to "Ralph Loop" updated to "ralph-wiggum"

## Functional Requirements

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| FR-1 | Update skill invocation from `ralph-loop:ralph-loop` to `ralph-wiggum:ralph-wiggum` | Must | US-1 |
| FR-2 | Wrap completion signal in `<promise>` tags | Must | US-2 |
| FR-3 | Update CLAUDE.md dependency reference | Must | US-3 |
| FR-4 | Ensure coordinator prompt idempotent (works when re-fed) | Must | US-1 |

## Non-Functional Requirements

| ID | Requirement | Category |
|----|-------------|----------|
| NFR-1 | Changes must not break existing spec execution flow | Compatibility |
| NFR-2 | No additional dependencies beyond ralph-wiggum | Simplicity |

## Out of Scope

- Changes to spec-executor.md (TASK_COMPLETE remains raw text, coordinator handles promise)
- Changes to ralph-wiggum plugin itself
- Migration tooling for existing specs

## Dependencies

- ralph-wiggum plugin v1.0.0+
- Claude Code with plugin support
