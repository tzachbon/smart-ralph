# Requirements: adopt-grill-me-interview

## Goal

Adopt Matt Pocock's grill-me skill patterns into the existing `interview-framework` SKILL.md, making every Ralph interview feel more opinionated, recommendation-driven, and codebase-aware. Includes cleanup of a duplicate rule in `goal-interview.md`, version bumps, bats tests, and doc updates.

## User Stories

### US-1: Recommendation-First Questioning

**As a** developer running a Ralph spec phase,
**I want** every interview question to lead with the AI's recommended answer and its rationale,
**so that** I can accept a well-reasoned default quickly instead of reading all options equally.

**Acceptance Criteria:**
- [ ] AC-1.1: Every `AskUserQuestion` call presents the recommended option first, labeled `[Recommended]` with a one-line rationale in parentheses.
- [ ] AC-1.2: Non-recommended options follow without rationale labels.
- [ ] AC-1.3: The SKILL.md algorithm section specifies recommendation generation as a required step before presenting each question.
- [ ] AC-1.4: The "Other" path is still available as the final option on every question.

### US-2: Remove Question Caps

**As a** developer with a complex greenfield goal,
**I want** the interview to keep asking until I signal completion rather than stopping at an arbitrary cap,
**so that** the spec captures all relevant context without cutting off prematurely.

**Acceptance Criteria:**
- [ ] AC-2.1: The intent-based question cap table (`maxAllowed`) is removed from SKILL.md.
- [ ] AC-2.2: The `WHILE askedCount < maxAllowed` loop condition is replaced with a completion-signal-only exit.
- [ ] AC-2.3: Min questions remain as an advisory floor (do not exit before `minRequired` unless user explicitly signals done).
- [ ] AC-2.4: Completion signal detection logic is preserved and documented.

### US-3: Strict Codebase-First Exploration

**As a** Ralph interview agent,
**I want** a strict rule enforced in SKILL.md that requires codebase exploration before asking any question that could be answered from code,
**so that** users are never asked to provide facts the codebase already contains.

**Acceptance Criteria:**
- [ ] AC-3.1: SKILL.md contains a clearly labeled "Codebase-First Rule" section.
- [ ] AC-3.2: The rule states: explore codebase before asking; only ask about decisions, not discoverable facts.
- [ ] AC-3.3: The rule applies to Phase 1 (UNDERSTAND) question generation.
- [ ] AC-3.4: An example distinguishing "codebase fact" vs "user decision" is included in the rule.

### US-4: Decision-Tree Traversal Guidance

**As a** Ralph interview agent,
**I want** questions to follow dependency order (foundational decisions before dependent ones),
**so that** follow-up questions are informed by prior answers rather than jumping between unrelated topics.

**Acceptance Criteria:**
- [ ] AC-4.1: SKILL.md Phase 1 algorithm specifies that questions must be ordered by dependency (foundational first).
- [ ] AC-4.2: The algorithm includes a step to identify which open questions depend on previously unanswered decisions and defer them.
- [ ] AC-4.3: Existing "builds on prior answers" rule is preserved and strengthened to reference dependency ordering explicitly.

### US-5: Cleanup Duplicate Codebase-First Rule

**As a** Ralph plugin maintainer,
**I want** the codebase-first mandatory block in `goal-interview.md` removed,
**so that** there is a single source of truth in SKILL.md and no drift risk.

**Acceptance Criteria:**
- [ ] AC-5.1: The `<mandatory>` block in `goal-interview.md` (lines 32-38) is removed.
- [ ] AC-5.2: `goal-interview.md` retains a prose reference pointing to SKILL.md for the codebase-first rule.
- [ ] AC-5.3: No other content in `goal-interview.md` is changed.

### US-6: Version Bump

**As a** Ralph plugin consumer,
**I want** the plugin version incremented after this change,
**so that** I can distinguish the updated behavior from the prior version.

**Acceptance Criteria:**
- [ ] AC-6.1: `plugins/ralph-specum/.claude-plugin/plugin.json` version is bumped (minor bump: new interview behavior).
- [ ] AC-6.2: `.claude-plugin/marketplace.json` entry for ralph-specum reflects the same new version.
- [ ] AC-6.3: Both files are updated in a single commit with the spec changes.

### US-7: Bats Tests for SKILL.md Content

**As a** contributor,
**I want** bats tests that verify the key grill-me patterns exist in SKILL.md,
**so that** regressions (accidentally reverting the new patterns) are caught automatically.

**Acceptance Criteria:**
- [ ] AC-7.1: A new bats test file exists at `tests/skills/interview-framework.bats` (or matches existing test path convention).
- [ ] AC-7.2: Test asserts `[Recommended]` label pattern is present in SKILL.md.
- [ ] AC-7.3: Test asserts the question cap table (`maxAllowed`) is absent from SKILL.md.
- [ ] AC-7.4: Test asserts "Codebase-First Rule" section heading is present in SKILL.md.
- [ ] AC-7.5: Test asserts completion signal detection logic is present in SKILL.md.
- [ ] AC-7.6: Tests pass in CI (`bats tests/`).

### US-8: Documentation Update

**As a** developer reading Ralph docs,
**I want** the README or docs to reflect the new interview behavior,
**so that** I understand what to expect when running spec phases.

**Acceptance Criteria:**
- [ ] AC-8.1: `docs/README.md` (or equivalent) mentions recommendation-first questioning.
- [ ] AC-8.2: Docs mention that question caps are removed and completion signals drive exit.
- [ ] AC-8.3: No other sections of the docs are modified beyond the interview behavior description.

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | Every question in Phase 1 (UNDERSTAND) leads with `[Recommended]` option plus rationale | High | AC-1.1, AC-1.2 |
| FR-2 | SKILL.md algorithm mandates recommendation generation before each question | High | AC-1.3 |
| FR-3 | Remove `maxAllowed` cap; loop exits only on completion signal or agent judgment | High | AC-2.1, AC-2.2 |
| FR-4 | Preserve `minRequired` as advisory floor | Medium | AC-2.3 |
| FR-5 | Add "Codebase-First Rule" section to SKILL.md with fact/decision distinction | High | AC-3.1–AC-3.4 |
| FR-6 | Require dependency-ordered question sequencing in Phase 1 algorithm | Medium | AC-4.1, AC-4.2 |
| FR-7 | Remove duplicate `<mandatory>` codebase-first block from `goal-interview.md` | Medium | AC-5.1, AC-5.2 |
| FR-8 | Bump plugin version in both manifest files | Low | AC-6.1, AC-6.2 |
| FR-9 | Add bats tests verifying key pattern presence/absence in SKILL.md | Medium | AC-7.1–AC-7.6 |
| FR-10 | Update docs to reflect new interview behavior | Low | AC-8.1, AC-8.2 |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | No runtime overhead | SKILL.md is static content | No dynamic evaluation added |
| NFR-2 | Test suite speed | bats test execution time | Under 5 seconds |
| NFR-3 | Single source of truth | Codebase-first rule locations | Exactly 1 (SKILL.md) after cleanup |

## Glossary

- **grill-me**: Matt Pocock's interview skill pattern emphasizing relentless single questions, recommendation-first options, and dependency-ordered traversal.
- **Completion signal**: A word or phrase from the user (e.g., "done", "proceed", "skip") that signals they want to end the interview early.
- **Codebase fact**: Information discoverable by reading the codebase (file paths, existing implementations, config values). Agents must look these up, not ask the user.
- **User decision**: A preference or trade-off that cannot be inferred from the codebase (e.g., naming choices, scope boundaries, priority calls).
- **minRequired**: Advisory minimum question count before a completion signal is accepted. Not a hard cap.
- **Recommendation-first**: Pattern where the AI presents its preferred answer as the first option, labeled `[Recommended]`, with a brief rationale.
- **Decision-tree traversal**: Ordering questions so foundational choices are resolved before dependent ones are asked.

## Out of Scope

- Changes to any other SKILL.md files (communication-style, etc.).
- Changes to phase-specific reference files other than `goal-interview.md` (e.g., `research-interview.md`, if any).
- Changing the `AskUserQuestion` tool interface or its schema.
- Adding voice/audio output to interviews.
- Automated migration of existing `.progress.md` files from old interview format.
- Performance testing beyond CI pass/fail.

## Dependencies

- Existing `plugins/ralph-specum/skills/interview-framework/SKILL.md` must be the sole canonical interview algorithm.
- `goal-interview.md` references SKILL.md via `apply adaptive dialogue from` syntax; that reference must remain after cleanup.
- bats must be available in CI environment (verify `.github/workflows/` or equivalent test runner config).

## Success Criteria

- Running a spec phase with the updated SKILL.md produces questions where option 1 is always labeled `[Recommended]` with visible rationale.
- The interview continues past previous cap limits when user has not signaled done.
- Agents do not ask users about file paths, existing implementations, or other codebase-discoverable facts.
- `bats tests/` passes with all new SKILL.md content tests green.
- No content in `goal-interview.md`'s mandatory block duplicates SKILL.md after cleanup.
