---
spec: reality-verification-principle
phase: requirements
created: 2026-01-16
generated: auto
---

# Requirements: reality-verification-principle

## Summary

Add reality verification principle: diagnose actual failure before spec generation, verify fix after implementation.

## User Stories

### US-1: Goal Type Detection

As a spec-driven developer, I want the system to detect fix vs add goals so that fix goals trigger diagnosis.

**Acceptance Criteria**:
- AC-1.1: Goals with fix/repair/resolve/debug/patch keywords detected as Fix type
- AC-1.2: Goals with broken/failing/error/bug/issue keywords detected as Fix type
- AC-1.3: Goals with add/create/build/implement/new keywords detected as Add type
- AC-1.4: When both patterns present, Fix takes precedence

### US-2: Pre-Spec Diagnosis

As a spec-driven developer, I want fix goals to observe actual failure before generating specs so that specs address real problems.

**Acceptance Criteria**:
- AC-2.1: For fix goals, relevant reproduction command is run
- AC-2.2: Failure output captured and documented in .progress.md BEFORE section
- AC-2.3: If no failure observed, warning logged in .progress.md

### US-3: Post-Implementation Verification

As a spec-driven developer, I want fix goals verified after all tasks complete so that the original issue is confirmed resolved.

**Acceptance Criteria**:
- AC-3.1: VF task added to Phase 4 for fix-type specs
- AC-3.2: VF task re-runs same command from diagnosis
- AC-3.3: VF task compares BEFORE vs AFTER states
- AC-3.4: VF task documents result in Reality Check (AFTER) section

## Functional Requirements

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| FR-1 | Create reality-verification SKILL.md with detection rules | Must | US-1 |
| FR-2 | Add goal detection to plan-synthesizer.md | Must | US-1 |
| FR-3 | Run diagnosis command for fix goals in plan-synthesizer | Must | US-2 |
| FR-4 | Add VF task template to templates/tasks.md | Must | US-3 |
| FR-5 | Update task-planner.md to include VF for fix goals | Must | US-3 |
| FR-6 | Update qa-engineer.md to handle VF task type | Should | US-3 |

## Non-Functional Requirements

| ID | Requirement | Category |
|----|-------------|----------|
| NFR-1 | Detection adds <100ms to spec generation | Performance |
| NFR-2 | Diagnosis command has 60s timeout | Reliability |

## Out of Scope

- Automatic fix suggestions based on diagnosis
- Multi-command diagnosis sequences
- Historical failure tracking across specs

## Dependencies

- Existing agent infrastructure (plan-synthesizer, task-planner, qa-engineer)
- Bash tool access for running reproduction commands
