---
spec: add-walk-through-of
phase: requirements
created: 2026-01-29
generated: auto
---

# Requirements: Phase Walkthrough

## Goal

Add a developer-friendly summary of changes after each spec phase completes, enabling quick understanding of what changed without requiring file-by-file inspection.

## User Stories

### US-1: View Phase Summary

**As a** developer using Ralph
**I want to** see a summary of changes after each phase completes
**So that** I can quickly understand what was generated/modified

**Acceptance Criteria:**
- AC-1.1: After research phase, walkthrough shows research.md creation
- AC-1.2: After requirements phase, walkthrough shows requirements.md creation
- AC-1.3: After design phase, walkthrough shows design.md creation
- AC-1.4: After tasks phase, walkthrough shows tasks.md creation

### US-2: Scannable Format

**As a** developer
**I want** the walkthrough to be easy to scan
**So that** I can quickly identify relevant changes

**Acceptance Criteria:**
- AC-2.1: Walkthrough uses tables or bullets (not prose)
- AC-2.2: File paths are clearly visible
- AC-2.3: Change type indicated (created/modified/deleted)
- AC-2.4: Line counts shown for context (+N/-N lines)

### US-3: Deep Dive Access

**As a** developer
**I want** to easily deep dive into actual files
**So that** I can see full details when needed

**Acceptance Criteria:**
- AC-3.1: Walkthrough references file paths explicitly
- AC-3.2: No need to duplicate full content in walkthrough
- AC-3.3: Developer can use file path to navigate directly

### US-4: Persistent Walkthrough

**As a** developer
**I want** the walkthrough stored persistently
**So that** I can review it later across sessions

**Acceptance Criteria:**
- AC-4.1: Walkthrough appended to .progress.md after each phase
- AC-4.2: Each phase walkthrough clearly labeled
- AC-4.3: Historical walkthroughs preserved (not overwritten)

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | Generate walkthrough after each spec phase | High | AC-1.1-1.4 |
| FR-2 | Use git diff for change detection | High | AC-2.3, AC-2.4 |
| FR-3 | Format as scannable table/bullets | High | AC-2.1, AC-2.2 |
| FR-4 | Store in .progress.md | High | AC-4.1-4.3 |
| FR-5 | Include file paths for deep dive | Medium | AC-3.1-3.3 |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Performance | Walkthrough generation time | <5 seconds |
| NFR-2 | Conciseness | Lines per phase walkthrough | <20 lines |

## Glossary

- **Walkthrough**: Summary of changes made during a spec phase
- **Phase**: One step in spec workflow (research, requirements, design, tasks, execution)

## Out of Scope

- Execution phase per-task walkthroughs (too granular)
- Interactive walkthrough viewing
- Walkthrough diffing between runs

## Dependencies

- Git available in execution environment
- Existing .progress.md template structure

## Success Criteria

- Developer can understand phase output in <30 seconds by reading walkthrough
- No need to open individual files for basic understanding

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Git not available | Medium | Fallback to "Files modified" list |
| Large diffs | Low | Truncate with note about full diff |
