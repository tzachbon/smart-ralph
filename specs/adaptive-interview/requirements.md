---
spec: adaptive-interview
phase: requirements
created: 2026-01-22
---

# Requirements: Adaptive Interview System

## Goal

Transform static interview questions into context-aware, adaptive questions that consider conversation history, prior phase outputs, and related specs to collect genuinely useful information.

## User Decisions

From goal interview:
- Problem type: Fixing a bug - questions are too static
- Constraints: None specified
- Success: Questions adapt based on context

From requirements interview:
- Primary users: Both developers and end users
- Priority: Code quality and maintainability

## User Stories

### US-1: Context-Aware Questions
**As a** spec creator
**I want** interview questions to reference what's already known
**So that** I don't answer the same questions repeatedly

**Acceptance Criteria:**
- [ ] AC-1.1: Questions skip topics already answered in prior phases
- [ ] AC-1.2: Questions reference prior answers using piping (e.g., "You mentioned {goal}...")
- [ ] AC-1.3: If research identified tech constraints, design interview pre-populates that context

### US-2: Spec-Aware Questions
**As a** spec creator working on related features
**I want** questions to consider existing specs
**So that** new features align with prior decisions

**Acceptance Criteria:**
- [ ] AC-2.1: System reads `./specs/` directory to find related specs
- [ ] AC-2.2: Questions reference relevant prior decisions from related specs
- [ ] AC-2.3: User sees summary of related specs before answering

### US-3: Adaptive Follow-ups
**As a** user selecting "Other"
**I want** follow-up questions that probe my specific response
**So that** I can clarify without generic prompts

**Acceptance Criteria:**
- [ ] AC-3.1: Follow-up questions are option-specific, not generic
- [ ] AC-3.2: AI generates contextual follow-up based on "Other" text
- [ ] AC-3.3: Follow-up acknowledges what user said before asking for more

### US-4: Phase-Specific Context
**As a** spec creator in later phases
**I want** interviews to build on prior phase outputs
**So that** I'm not asked things already documented

**Acceptance Criteria:**
- [ ] AC-4.1: Requirements interview reads research.md findings
- [ ] AC-4.2: Design interview reads requirements.md decisions
- [ ] AC-4.3: Tasks interview reads design.md choices
- [ ] AC-4.4: Questions adapt based on content from prior artifacts

### US-5: Quick Mode Bypass
**As a** user in quick mode
**I want** all interviews skipped
**So that** auto-generation proceeds without interruption

**Acceptance Criteria:**
- [ ] AC-5.1: `--quick` flag bypasses all AskUserQuestion calls (existing behavior preserved)
- [ ] AC-5.2: Default answers used when interview skipped

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | Parameter chain: check if info exists before asking | P0 | Test: Question skipped when answer exists in prior artifacts |
| FR-2 | Question piping: insert prior answers into question text | P0 | Test: Question contains interpolated prior response |
| FR-3 | Spec awareness: read related specs from ./specs/ | P1 | Test: Related specs listed before questions |
| FR-4 | Phase context injection: read prior phase artifacts | P0 | Test: requirements.md content influences design questions |
| FR-5 | Adaptive follow-ups: context-specific when "Other" selected | P1 | Test: Follow-up references specific "Other" response |
| FR-6 | Accumulate responses: store interview answers in .progress.md | P0 | Test: All interview responses persisted across phases |
| FR-7 | Option branching: different follow-ups per selected option | P2 | Test: Selecting "Performance critical" triggers different branch than "No constraints" |
| FR-8 | Related spec summary: show 1-2 sentence summary of relevant specs | P1 | Test: Summary displayed before asking about architecture |
| FR-9 | Max 5 options per question (existing limit enforced) | P0 | Test: No question has >5 options |
| FR-10 | Explain "why" before asking (value framing) | P2 | Test: Questions include brief rationale |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Testability | Coverage | Rule-based logic has manual test scenarios |
| NFR-2 | Maintainability | Complexity | Question templates remain in single location per phase |
| NFR-3 | Performance | Latency | Spec scanning completes <2s for 50 specs |
| NFR-4 | Backward compatibility | Regression | Existing quick mode behavior unchanged |

## Glossary

| Term | Definition |
|------|------------|
| Parameter chain | Pattern: check "do we have X?" before asking for X |
| Question piping | Inserting prior answers into question text (e.g., "You mentioned {X}...") |
| Phase artifact | Output file from a phase (research.md, requirements.md, design.md, tasks.md) |
| Related spec | Spec in ./specs/ with similar goal or shared patterns |
| Adaptive follow-up | Context-specific question when user selects "Other" |
| Quick mode | --quick flag that bypasses all interviews |

## Out of Scope

- AI-generated questions from scratch (using enhanced templates with context slots instead)
- Cross-session memory (context resets per claude session)
- Interviews during task execution (spec-executor cannot use AskUserQuestion)
- Complex branching trees (keeping to 2-level max: main question + follow-up)
- Reordering questions based on context (keeping existing question order)
- Custom question sets per project type

## Dependencies

| Dependency | Type | Status |
|------------|------|--------|
| AskUserQuestion tool | Claude Code tool | Available |
| ./specs/ directory structure | Existing pattern | In use |
| .progress.md file | State file | In use |
| Phase artifacts (research.md, etc.) | Existing outputs | In use |

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Context parsing errors | Questions fail to adapt | Use defensive parsing with fallback to static questions |
| Too many related specs | Overwhelms user with context | Limit to top 3 most relevant specs |
| Spec format changes | Context extraction breaks | Define stable extraction patterns, version check |
| Question complexity increases maintenance | Hard to update questions | Keep templates centralized, document context slots |

## Success Criteria

1. **Quantitative**: Questions skip >=50% of already-answered topics in later phases
2. **Qualitative**: User perceives questions as "aware" of prior conversation
3. **Regression**: Quick mode behavior unchanged
4. **Test coverage**: Each FR has documented manual test scenario
