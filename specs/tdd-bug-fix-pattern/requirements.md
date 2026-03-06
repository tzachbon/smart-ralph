---
spec: tdd-bug-fix-pattern
phase: requirements
created: 2026-03-05
generated: auto
---

# Requirements: TDD Bug Fix Pattern

## Goal

Add a dedicated `BUG_FIX` intent type and phase sequence to Ralph Specum so that bug fix goals trigger a reproduce-first workflow (BEFORE state capture -> Red test -> Green fix -> Yellow cleanup -> VF verification) instead of falling through to generic TDD without reproduction enforcement.

---

## User Stories

### US-1: BUG_FIX Intent Classification

**As a** Ralph user reporting a bug
**I want to** have my bug fix goal recognized as a distinct intent type
**So that** Ralph routes it to the reproduce-first workflow instead of generic TDD

**Acceptance Criteria:**
- [ ] AC-1.1: Goals containing "fix", "bug", "broken", "failing", "error", "crash", "not working", "regression", "issue", "debug", "resolve" are classified as `BUG_FIX`
- [ ] AC-1.2: `BUG_FIX` is distinct from `TRIVIAL` -- "fix typo" stays TRIVIAL; "fix the crash in auth" becomes BUG_FIX
- [ ] AC-1.3: `BUG_FIX` appears in `intent-classification.md` routing table with exactly 5 interview questions (min 5, max 5 -- bug interview is structured; all 5 questions are mandatory)
- [ ] AC-1.4: Existing TRIVIAL/REFACTOR/GREENFIELD/MID_SIZED classification is unchanged

---

### US-2: Bug-Specific Goal Interview

**As a** Ralph user reporting a bug
**I want to** be asked targeted questions about the bug
**So that** Ralph has enough context to reproduce and fix it without back-and-forth later

**Acceptance Criteria:**
- [ ] AC-2.1: Goal interview for BUG_FIX goals includes at minimum: reproduction steps, expected vs actual behavior, when the bug started, and whether it is a regression
- [ ] AC-2.2: In normal mode, interview asks for the exact error message or output if not already in the goal
- [ ] AC-2.3: In quick mode, these fields are derived from goal text or left as inference tasks for the research phase (interview is skipped per quick mode rules)

---

### US-3: Phase 0 -- Reproduce Before Coding

**As a** Ralph agent executing a bug fix spec
**I want to** run the reproduction command before writing any code
**So that** I have a verified BEFORE state that proves the bug exists

**Acceptance Criteria:**
- [ ] AC-3.1: BUG_FIX phase sequence starts with Phase 0 (Reproduce), before any Red/Green tasks
- [ ] AC-3.2: Phase 0 tasks run the reproduction command and capture full stdout/stderr
- [ ] AC-3.3: Reproduction is run at least twice to confirm consistency
- [ ] AC-3.4: Phase 0 produces a `## Reality Check (BEFORE)` section in `.progress.md` in the canonical format (see FR-4)
- [ ] AC-3.5: If reproduction cannot be confirmed, Phase 0 blocks with an error rather than proceeding to Red

---

### US-4: TDD Red-Green-Yellow with Bug Fix Semantics

**As a** Ralph agent implementing a bug fix
**I want to** write a failing test that reproduces the bug before writing any fix code
**So that** the fix is verified by an automated test, not just manual inspection

**Acceptance Criteria:**
- [ ] AC-4.1: `[RED]` task writes a test that fails with the same failure mode as the reproduction command
- [ ] AC-4.2: `[GREEN]` task applies the minimum fix to make the test pass
- [ ] AC-4.3: `[GREEN]` task also verifies the original reproduction command now exits 0 (or expected output)
- [ ] AC-4.4: `[YELLOW]` task (optional) refactors and checks adjacent code for similar bugs
- [ ] AC-4.5: Each phase commits only its own file types (test files for Red, fix files for Green)

---

### US-5: VF Verification Against BEFORE State

**As a** Ralph agent completing a bug fix
**I want to** re-run the original reproduction command and compare it to the documented BEFORE state
**So that** there is a machine-readable proof that the bug is resolved

**Acceptance Criteria:**
- [ ] AC-5.1: VF task reads `## Reality Check (BEFORE)` from `.progress.md`
- [ ] AC-5.2: VF task re-runs the exact reproduction command from the BEFORE state
- [ ] AC-5.3: VF task documents an `## Reality Check (AFTER)` section showing exit code and output
- [ ] AC-5.4: VF task fails if the reproduction command still exits with the BEFORE failure mode
- [ ] AC-5.5: Existing VF task template in `phase-rules.md` is reused without modification to its format

---

### US-6: Quick Mode Bug Fix Support

**As a** Ralph user running in quick mode with a bug fix goal
**I want to** have the reproduction and BEFORE state capture happen automatically during research
**So that** quick mode is fully autonomous for bug fix goals

**Acceptance Criteria:**
- [ ] AC-6.1: `quick-mode.md` step 10 ("For fix goals: run reproduction, document BEFORE state") is fully implemented with explicit instructions, not left as a stub
- [ ] AC-6.2: Quick mode derives the reproduction command from the goal text or infers it from the codebase test structure (does not prompt the user)
- [ ] AC-6.3: Quick mode captures BEFORE state in the canonical format before moving to task generation

---

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | Add `BUG_FIX` intent type to `intent-classification.md` | High | AC-1.1, AC-1.2, AC-1.3 |
| FR-2 | Add BUG_FIX phase sequence to `phase-rules.md` (Phase 0: Reproduce -> Red -> Green -> Yellow -> VF) | High | AC-3.1, AC-4.1 |
| FR-3 | Add bug-specific exploration territory to `goal-interview.md` | Medium | AC-2.1, AC-2.2 |
| FR-4 | Define canonical `## Reality Check (BEFORE)` format in `phase-rules.md` | High | AC-3.4, AC-5.1 |
| FR-5 | Flesh out `quick-mode.md` step 10 with reproduction instructions | High | AC-6.1, AC-6.2, AC-6.3 |
| FR-6 | Add BUG_FIX phase template to `task-planner.md` | Medium | AC-3.1, AC-4.5 |

### FR-4 Detail: Canonical BEFORE State Format

```markdown
## Reality Check (BEFORE)
- **Reproduction command**: `<exact command>`
- **Exit code**: <N>
- **Output**:
  ```
  <exact stdout/stderr>
  ```
- **Expected**: <what should happen>
- **Timestamp**: <ISO date>
```

---

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | No breaking changes | Existing intent types (TRIVIAL/REFACTOR/GREENFIELD/MID_SIZED) unchanged | Zero regressions |
| NFR-2 | Additive only | All 6 file changes add new sections; no existing sections removed | Code review: no deletions to existing routing logic |
| NFR-3 | Consistency | BEFORE format parseable by VF task without ambiguity | VF task reads BEFORE state with no format errors |

---

## Glossary

- **BUG_FIX**: New intent type for goals that fix existing broken behavior (distinct from adding new features)
- **Phase 0 (Reproduce)**: Pre-TDD phase that confirms a bug exists and captures its failure signature
- **BEFORE state**: Documented failure output captured before any code changes; stored in `.progress.md`
- **AFTER state**: Documented success output captured after the fix; stored in `.progress.md` by VF task
- **VF task**: Verification task template that compares BEFORE and AFTER states
- **RED/GREEN/YELLOW**: TDD phase tags used by spec-executor to enforce commit discipline per phase
- **Reproduction command**: The exact CLI command or test invocation that triggers the bug consistently

---

## Out of Scope

- Changes to `spec-executor.md` -- RED/GREEN/YELLOW support already works
- Changes to `stop-watcher.sh` -- loop control is phase-agnostic
- Changes to the VF task template format -- it already reads from `.progress.md`
- Automated E2E testing -- Ralph is a markdown plugin with no test runner
- Debugger integration (breakpoints, step-through) -- out of scope for this spec
- Multi-bug tracking (one spec = one bug)
- Regression test suites -- only the single failing test for the specific bug

---

## Dependencies

- `references/intent-classification.md` must exist and follow current routing table format
- `references/phase-rules.md` must have the existing VF task template at L212-226
- `references/quick-mode.md` step 10 stub must be present (confirmed in research)
- `references/goal-interview.md` must have an exploration territories section
- `agents/task-planner.md` must have per-intent phase templates

---

## Success Criteria

- A goal like "fix the crash in auth login" is classified as BUG_FIX, not TRIVIAL or MID_SIZED
- Generated task list for a BUG_FIX spec starts with a Reproduce task before any RED task
- `.progress.md` contains a `## Reality Check (BEFORE)` section with reproduction command, exit code, and raw output before any fix code is written
- The VF task at spec end re-runs the reproduction command and documents exit code 0 (or expected output)
- All 6 file changes are additive -- no existing routing branches removed

---

## Unresolved Questions

- **Reproduction command in quick mode**: If the goal text does not contain an explicit command, should quick mode run the full test suite to find a failure, or require the user to include the command in their goal? (Recommendation: run existing tests, surface any failure as the reproduction target.)
- **Parallel research with bugs**: Current research flow dispatches 3 parallel research teammates. For bugs, serial flow (reproduce -> root cause search) may be more appropriate. Does adding a "bug reproduction" teammate preserve parallelism adequately?

## Next Steps

1. Design phase: define exact text changes per file (intent-classification.md, phase-rules.md, quick-mode.md, goal-interview.md, task-planner.md + canonical BEFORE format)
2. Task generation: break into 6 file-change tasks (one per touchpoint) with a VF verification task at the end
3. Implementation: apply changes file by file, verify no existing tests/routing broken after each
