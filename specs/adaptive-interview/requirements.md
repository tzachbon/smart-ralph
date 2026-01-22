---
spec: adaptive-interview
phase: requirements
created: 2026-01-22
updated: 2026-01-22
---

# Requirements: Adaptive Interview System

## Goal

Transform static, fixed interview questions into a dynamic, continuous interview system that:
1. Asks ONE question at a time (not batches)
2. Classifies questions by type (codebase fact vs user preference)
3. Continues until user signals completion
4. Adapts based on conversation, prior phases, and related specs

## User Decisions

From goal interview:
- Problem type: Fixing a bug - questions are too static
- Constraints: None specified
- Success: Questions adapt based on context

From requirements interview:
- Primary users: Both developers and end users
- Priority: Code quality and maintainability

From research (oh-my-claudecode patterns):
- Single question at a time (never batch)
- Question classification before asking
- Continuous interview until user says "done"
- Intent classification first (trivial/refactor/greenfield/mid-sized)

## User Stories

### US-1: Single Question Flow
**As a** spec creator
**I want** interview questions asked ONE at a time
**So that** I can give thoughtful responses that inform the next question

**Acceptance Criteria:**
- [ ] AC-1.1: Each AskUserQuestion call contains exactly 1 question
- [ ] AC-1.2: Next question adapts based on previous answer
- [ ] AC-1.3: User never sees multiple questions in one prompt

### US-2: Question Classification
**As a** spec creator
**I want** the system to NOT ask me about things it can discover from codebase
**So that** I only answer questions about my preferences and requirements

**Acceptance Criteria:**
- [ ] AC-2.1: System distinguishes "codebase fact" vs "user preference" questions
- [ ] AC-2.2: Codebase facts gathered via Explore agent, not user questions
- [ ] AC-2.3: Only preference/requirement/scope questions asked to user

**Question Classification Matrix:**
| Type | Example | Ask User? |
|------|---------|-----------|
| Codebase fact | "What patterns exist?" | NO - use Explore |
| Codebase fact | "Where is X implemented?" | NO - use Explore |
| Preference | "Should we prioritize speed or quality?" | YES |
| Requirement | "What's the deadline?" | YES |
| Scope | "Should this include feature Y?" | YES |
| Constraint | "Are there performance requirements?" | YES |
| Risk tolerance | "How much refactoring is acceptable?" | YES |

### US-3: Intent Classification
**As a** spec creator
**I want** interview depth to match task complexity
**So that** simple tasks get quick interviews, complex tasks get thorough ones

**Acceptance Criteria:**
- [ ] AC-3.1: System classifies intent as trivial/refactor/greenfield/mid-sized
- [ ] AC-3.2: Trivial tasks: 1-2 questions, fast turnaround
- [ ] AC-3.3: Greenfield tasks: discovery focus, explore patterns first
- [ ] AC-3.4: Refactor tasks: safety focus, test coverage questions
- [ ] AC-3.5: Mid-sized tasks: boundary focus, clear deliverables

**Intent Classification:**
| Intent | Signal | Interview Focus | Question Count |
|--------|--------|-----------------|----------------|
| Trivial | "quick fix", "small change" | Fast turnaround | 1-2 |
| Refactoring | "refactor", "restructure" | Safety, test coverage | 3-5 |
| Greenfield | "new feature", "build from scratch" | Discovery, explore first | 5-10 |
| Mid-sized | Scoped feature | Boundaries, deliverables | 3-7 |

### US-4: Continuous Interview
**As a** spec creator
**I want** the interview to continue until I say it's complete
**So that** I can provide all necessary context before proceeding

**Acceptance Criteria:**
- [ ] AC-4.1: Interview continues until user signals completion
- [ ] AC-4.2: User can say "done", "that's enough", "proceed" to end interview
- [ ] AC-4.3: System asks "Any other context?" before concluding
- [ ] AC-4.4: Minimum questions based on intent classification (not skippable)

### US-5: Context-Aware Questions (from prior design)
**As a** spec creator
**I want** interview questions to reference what's already known
**So that** I don't answer the same questions repeatedly

**Acceptance Criteria:**
- [ ] AC-5.1: Questions skip topics already answered in prior phases
- [ ] AC-5.2: Questions reference prior answers using piping (e.g., "You mentioned {goal}...")
- [ ] AC-5.3: If research identified tech constraints, design interview pre-populates that context

### US-6: Spec-Aware Questions (from prior design)
**As a** spec creator working on related features
**I want** questions to consider existing specs
**So that** new features align with prior decisions

**Acceptance Criteria:**
- [ ] AC-6.1: System reads `./specs/` directory to find related specs
- [ ] AC-6.2: Questions reference relevant prior decisions from related specs
- [ ] AC-6.3: User sees summary of related specs (max 3) before answering

### US-7: Adaptive Follow-ups (from prior design)
**As a** user selecting "Other"
**I want** follow-up questions that probe my specific response
**So that** I can clarify without generic prompts

**Acceptance Criteria:**
- [ ] AC-7.1: Follow-up questions are option-specific, not generic
- [ ] AC-7.2: Follow-up acknowledges what user said before asking for more
- [ ] AC-7.3: Follow-up informed by conversation context

### US-8: Quick Mode Bypass (from prior design)
**As a** user in quick mode
**I want** all interviews skipped
**So that** auto-generation proceeds without interruption

**Acceptance Criteria:**
- [ ] AC-8.1: `--quick` flag bypasses all AskUserQuestion calls
- [ ] AC-8.2: Default answers used when interview skipped

## Functional Requirements

| ID | Requirement | Priority | User Story |
|----|-------------|----------|------------|
| FR-1 | Single question per AskUserQuestion call | P0 | US-1 |
| FR-2 | Question classification (fact vs preference) | P0 | US-2 |
| FR-3 | Intent classification (trivial/refactor/greenfield/mid-sized) | P0 | US-3 |
| FR-4 | Continuous interview until user completion signal | P0 | US-4 |
| FR-5 | Parameter chain: skip questions with known answers | P0 | US-5 |
| FR-6 | Question piping: interpolate prior answers into question text | P0 | US-5 |
| FR-7 | Spec awareness: read and summarize related specs | P1 | US-6 |
| FR-8 | Adaptive follow-ups: context-specific probing | P1 | US-7 |
| FR-9 | Accumulate responses in .progress.md | P0 | US-5 |
| FR-10 | Quick mode bypass preserves existing behavior | P0 | US-8 |
| FR-11 | Max 4 options per question (better UX than 5) | P1 | US-1 |
| FR-12 | Explain "why" before asking (value framing) | P2 | US-1 |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Testability | Coverage | Each FR has manual test scenario |
| NFR-2 | Maintainability | Complexity | Question logic centralized per phase |
| NFR-3 | Performance | Latency | Spec scanning <2s for 50 specs |
| NFR-4 | Backward compatibility | Regression | Quick mode unchanged |
| NFR-5 | User experience | Efficiency | Codebase facts never asked to user |

## Glossary

| Term | Definition |
|------|------------|
| Single question flow | One AskUserQuestion per prompt, not batches |
| Question classification | Categorizing questions as codebase fact vs user preference |
| Intent classification | Categorizing task as trivial/refactor/greenfield/mid-sized |
| Continuous interview | Interview that continues until user signals completion |
| Parameter chain | Check "do we have X?" before asking for X |
| Question piping | Inserting prior answers into question text |
| Codebase fact | Information discoverable via code exploration |
| User preference | Decision only the user can make |

## Out of Scope

- AI-generated questions from scratch (using dynamic templates instead)
- Cross-session memory (context resets per session)
- Interviews during task execution (spec-executor cannot use AskUserQuestion)
- Complex branching trees beyond 2-level (main + follow-up)
- Custom question sets per project type

## Dependencies

| Dependency | Type | Status |
|------------|------|--------|
| AskUserQuestion tool | Claude Code tool | Available |
| Explore subagent | Codebase analysis | Available |
| ./specs/ directory structure | Existing pattern | In use |
| .progress.md file | State file | In use |

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Too many questions | User fatigue | Intent classification sets max count |
| Too few questions | Incomplete context | Minimum questions per intent |
| Wrong question classification | Bad UX | Test classification rules thoroughly |
| Continuous interview never ends | Stuck | Auto-conclude after max rounds |

## Success Criteria

1. **Single question**: Every AskUserQuestion contains exactly 1 question
2. **Classification**: Zero codebase-fact questions asked to user
3. **Intent-aware**: Trivial tasks complete in ≤2 questions
4. **Continuous**: Complex tasks get thorough interview (5+ questions)
5. **Regression**: Quick mode behavior unchanged
