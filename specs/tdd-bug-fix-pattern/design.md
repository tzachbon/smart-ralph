---
generated: auto
---

# Design: TDD Bug Fix Pattern

## Overview

Add `BUG_FIX` as a first-class intent type with a Phase 0 (Reproduce) prepended to the TDD workflow. Six existing reference files receive additive changes only -- no new agents, no new primitives, no breaking changes to existing intents.

## Architecture

```
User goal text
      |
      v
intent-classification.md
  [BUG_FIX keyword match]
      |
      +-- BUG_FIX -----> goal-interview.md [5 bug questions]
      |                        |
      |                        v
      |                  phase-rules.md
      |                  [Phase 0: Reproduce]
      |                  [Phase 1: RED-GREEN-YELLOW]
      |                  [Phase 2: Additional Tests]
      |                  [Phase 3: Quality Gates + VF]
      |                  [Phase 4: PR Lifecycle]
      |
      +-- TRIVIAL/REFACTOR/MID_SIZED --> existing TDD workflow (unchanged)
      +-- GREENFIELD --> existing POC workflow (unchanged)
```

## Data Flow

```
Normal mode:
  start.md
    -> classify intent (intent-classification.md)
    -> if BUG_FIX: ask 5 bug questions (goal-interview.md)
    -> research phase (serial: reproduce first, then root cause)
    -> requirements phase
    -> design phase
    -> tasks phase (task-planner.md: prepend Phase 0 tasks)
    -> execution (spec-executor unchanged)

Quick mode:
  start.md step 10
    -> classify goalType: "fix" (already exists)
    -> infer repro command (new logic)
    -> run command, capture output
    -> write ## Reality Check (BEFORE) to .progress.md
    -> continue to research/requirements/design/tasks
```

## Detailed Changes Per File

### 1. `plugins/ralph-specum/references/intent-classification.md`

**Section: Goal Intent Classification > Classification Logic**

Add `BUG_FIX` before `TRIVIAL` (highest priority -- bug keywords are specific):

```text
0. BUG_FIX: Goal contains keywords like:
   - "fix", "resolve", "debug"
   - "broken", "failing", "not working", "doesn't work"
   - "error", "bug", "patch", "crash", "regression"
   - "reproduce", "repro"
   -> Min questions: 5, Max questions: 5 (fixed count -- all 5 are mandatory; bug interview is structured, not depth-adaptive)
   -> Route: bug interview (see goal-interview.md)
```

**Section: Goal Intent Classification > Dialogue Depth by Intent** -- add row:

| Intent | Min Questions | Max Questions |
|--------|---------------|---------------|
| BUG_FIX | 5 | 5 |

**Section: Store Intent** -- `BUG_FIX` is a valid Type value.

**Section: Goal Type Detection (Quick Mode)** -- no change needed; the existing `fix` regex already covers this path. The new BUG_FIX type is for normal mode intent routing only.

**Priority rule**: BUG_FIX is checked BEFORE TRIVIAL. A goal with "fix typo" matches TRIVIAL (typo wins) but "fix login bug" matches BUG_FIX.

Refined priority order: `BUG_FIX` (bug-specific keywords) > `TRIVIAL` ("typo", "minor", etc.) > `REFACTOR` > `GREENFIELD` > `MID_SIZED`

---

### 2. `plugins/ralph-specum/references/goal-interview.md`

**Add new section: Bug Interview (BUG_FIX intent)**

Insert after `## Prerequisites`:

```markdown
## Bug Interview (BUG_FIX Intent)

When intent is BUG_FIX, replace the standard brainstorming dialogue with exactly 5 structured questions asked sequentially. Ask them one at a time.

### The 5 Bug Questions

1. **Reproduction steps**: Walk me through the exact steps to reproduce this bug. What do you do, in what order?

2. **Expected vs actual**: What did you expect to happen? What actually happens instead? (include any error messages, wrong values, or missing output)

3. **When it started**: When did this start breaking? Was it working before? If yes, do you know what changed around that time (deploy, dependency update, config change)?

4. **Regression check**: Do you have an existing test that covers this behavior? If yes, is that test currently failing or passing?

5. **Reproduction command**: What is the fastest command to reproduce the failure? (e.g., `pnpm test -- --grep "login"`, `curl localhost:3000/api/users`, `node scripts/repro.js`) If you don't have one, describe the manual steps.

### After Bug Interview

Store responses in .progress.md under `## Interview Responses` as normal.

Do NOT propose approach variants -- bug fix approach is fixed: reproduce -> RED test -> GREEN fix -> YELLOW cleanup -> VF verify.

Skip the Spec Location Interview (bug fixes go to default specs dir -- no need to ask).
```

---

### 3. `plugins/ralph-specum/references/phase-rules.md`

**Section: Workflow Selection** -- add BUG_FIX row:

| Intent | Workflow | Rationale |
|--------|----------|-----------|
| BUG_FIX | Bug TDD | Reproduce first, then TDD to lock in fix and prevent regression |

**Add new section: Bug TDD Workflow (BUG_FIX)**

Insert between "TDD Workflow (Non-Greenfield)" and "VF Task for Fix Goals":

```markdown
# Bug TDD Workflow (BUG_FIX)

When Intent Classification is `BUG_FIX`, use Bug TDD workflow. This extends TDD with a mandatory Phase 0 before the RED-GREEN-YELLOW cycle.

## Phase 0: Reproduce

**Goal**: Prove the bug exists. Capture exact failure before touching any code.

**Rules**:
- Run the reproduction command provided in the bug interview (or inferred in quick mode)
- Capture full output (stdout + stderr + exit code)
- Write to .progress.md under `## Reality Check (BEFORE)` (see BEFORE State Format below)
- STOP if reproduction fails (bug cannot be confirmed) -- surface error to user
- No code changes in Phase 0
- **Diagnostic-first principle**: Only make code changes when you are certain you can solve the problem. Otherwise:
  1. Address the root cause, not the symptoms
  2. Add descriptive logging statements and error messages to track variable and code state
  3. Add test functions and statements to isolate the problem

**Phase 0 task format**:
```markdown
- [ ] 0.1 [VERIFY] Reproduce bug: <short description>
  - **Do**: Run reproduction command, capture output verbatim
  - **Files**: .progress.md (append BEFORE state)
  - **Done when**: Command fails with documented error (exit code != 0 OR output matches known-bad pattern)
  - **Verify**: Run cmd, assert failure: `<repro-cmd> 2>&1; [ $? -ne 0 ] && echo REPRO_CONFIRMED`
  - **Commit**: `chore(<spec>): document BEFORE state`
  - _Requirements: FR-3_

- [ ] 0.2 [VERIFY] Confirm repro is consistent: re-run command, assert same failure mode
  - **Do**: Re-run the same reproduction command a second time; compare exit code and error output to 0.1 capture
  - **Files**: .progress.md (append consistency note to BEFORE state block)
  - **Done when**: Second run fails with same exit code and same error pattern as first run
  - **Verify**: `<repro-cmd> 2>&1 | diff - <(grep -A20 'Reality Check (BEFORE)' .progress.md | tail -n+4) || echo CONSISTENT`
  - **Commit**: none (amend 0.1 commit or skip -- consistency note only)
  - _Requirements: AC-3.3_
```

## Reality Check (BEFORE) -- Canonical Format

After Phase 0 succeeds, append to .progress.md:

```markdown
## Reality Check (BEFORE)

- **Reproduction command**: `<exact command>`
- **Exit code**: <N>
- **Output**:
  ```
  <verbatim stdout+stderr, max 50 lines -- truncate with [... N lines truncated]>
  ```
- **Confirmed failing**: yes
- **Timestamp**: <ISO 8601>
```

This section MUST exist before any [RED] task is executed. The VF task reads from this section.

## Phase 1: TDD Cycles (same as TDD workflow)

Same RED-GREEN-YELLOW format as TDD Phase 1. The [RED] test MUST capture the exact failure from the BEFORE state.

**First [RED] task must reference BEFORE state**:
```markdown
- [ ] 1.1 [RED] Failing test: <bug behavior from BEFORE state>
  - **Do**: Write test that reproduces the failure documented in `## Reality Check (BEFORE)`. Test MUST fail.
  - **Files**: <test file>
  - **Done when**: Test exists AND fails with same error pattern as BEFORE state
  - **Verify**: `<test cmd> -- --grep "<test name>" 2>&1 | grep -q "FAIL\|fail\|Error" && echo RED_PASS`
  - **Commit**: `test(scope): red - reproduce bug in test`
  - _Requirements: FR-4, AC-4.1_
```

## Phase 2, 3, 4

Same as TDD Phases 2, 3, 4. VF task is MANDATORY for BUG_FIX (not conditional on BEFORE state existing -- it always exists).
```

**Section: VF Task for Fix Goals** -- update condition:

Change: "When `.progress.md` contains `## Reality Check (BEFORE)`"
To: "When `.progress.md` contains `## Reality Check (BEFORE)` OR Intent Classification is `BUG_FIX`"

(These are equivalent for BUG_FIX -- the BEFORE section always exists. The OR clause is defensive.)

---

### 4. `plugins/ralph-specum/references/quick-mode.md`

**Section: Step 10: Goal Type Detection** -- flesh out the stub:

Replace:
```
- For fix goals: run reproduction, document BEFORE state
```

With:
```
- For fix goals:
  a. INFER reproduction command:
     - Scan goal text for command-like patterns: backtick content, "run X", "by running X"
     - If none found: default to running the project test suite (discover from research.md or package.json scripts)
     - Fallback command priority: (1) goal text command, (2) `pnpm test` / `npm test` / `yarn test`, (3) skip with warning
  b. RUN reproduction command: capture stdout + stderr + exit code
  c. WRITE to .progress.md:
     ```markdown
     ## Reality Check (BEFORE)

     - **Reproduction command**: `<cmd>`
     - **Exit code**: <N>
     - **Output**:
       ```
       <verbatim output, max 50 lines>
       ```
     - **Confirmed failing**: <yes|no -- "no" if exit 0 and no error pattern>
     - **Timestamp**: <ISO 8601>
     ```
  d. If confirmed failing: continue to research phase
  e. If NOT confirmed failing (cmd passes): append warning to .progress.md:
     ```
     **WARNING**: Reproduction command did not fail. Bug may be environment-specific or already fixed.
     ```
     Continue (do not block -- quick mode is non-interactive)
```

---

### 5. `plugins/ralph-specum/agents/task-planner.md`

**Add new section: Bug TDD Task Planning**

Append (or insert in relevant section on workflow selection):

```markdown
## Bug TDD Task Planning (BUG_FIX intent)

When `.progress.md` Intent Classification type is `BUG_FIX`:

1. **Always prepend Phase 0** with exactly two tasks: `0.1 [VERIFY] Reproduce bug` and `0.2 [VERIFY] Confirm repro is consistent` (AC-3.3)
   - Use `Reproduction command` from bug interview responses in .progress.md
   - If not found in .progress.md (quick mode): use the command from `## Reality Check (BEFORE)` if it exists, else use test runner command

2. **First [RED] task must reference BEFORE state**: include "from Reality Check (BEFORE)" in Do description

3. **VF task is mandatory**: always include as final task regardless of BEFORE state presence

4. **No GREENFIELD Phase 1 POC**: BUG_FIX always uses Bug TDD workflow, never POC-first

5. **Reproduction command sources** (priority order):
   - Interview response Q5 (repro command)
   - `## Reality Check (BEFORE)` in .progress.md (written by quick mode step 10)
   - Project test runner (from research.md Verification Tooling)
```

---

## Intent Detection Algorithm (Complete)

```text
BUG_FIX keywords (any match -> BUG_FIX, unless TRIVIAL keywords also present):
  fix, resolve, debug, broken, failing, not working, doesn't work,
  error, bug, patch, crash, regression, reproduce, repro, issue

TRIVIAL overrides BUG_FIX when BOTH match AND trivial-specific keywords present:
  typo, spelling, small change, minor, quick, simple, tiny, rename, update text

Priority resolution:
  1. Check TRIVIAL-specific keywords (typo, spelling, minor, tiny, rename, update text)
     -> If matched: TRIVIAL (these are never bugs, just text edits)
  2. Check BUG_FIX keywords
     -> If matched: BUG_FIX
  3. Check REFACTOR keywords
     -> If matched: REFACTOR
  4. Check GREENFIELD keywords
     -> If matched: GREENFIELD
  5. Default: MID_SIZED
```

## Bug Interview Questions (Exact Text)

Q1: "Walk me through the exact steps to reproduce this bug. What do you do, in what order?"

Q2: "What did you expect to happen? What actually happens instead? Include any error messages, wrong output values, or missing behavior."

Q3: "When did this start breaking? Was it working before -- and if yes, do you know what changed around that time (deploy, dependency update, config change, environment)?"

Q4: "Do you have an existing test that covers this behavior? Is that test currently failing or passing?"

Q5: "What is the fastest command to reproduce the failure? For example: `pnpm test -- --grep 'login'`, `curl localhost:3000/api/users`, `node scripts/repro.js`. If you don't have one yet, describe the manual steps."

## Phase 0 Specification

```
Phase 0: Reproduce
  Input:  repro command (from Q5 or inferred)
  Task 0.1: run command, capture output (stdout + stderr + exit code) -> write ## Reality Check (BEFORE)
  Task 0.2: re-run command, assert same failure mode -> confirm consistency (AC-3.3)
  Output: ## Reality Check (BEFORE) block in .progress.md with consistency confirmed
  Gating: RED task cannot start until both 0.1 and 0.2 pass
  Format: canonical (defined in phase-rules.md, never re-invented per-agent)
```

**BEFORE state format** (canonical, defined once in phase-rules.md):

```markdown
## Reality Check (BEFORE)

- **Reproduction command**: `<exact command>`
- **Exit code**: <N>
- **Output**:
  ```
  <verbatim stdout+stderr, max 50 lines -- truncate with [... N lines truncated]>
  ```
- **Confirmed failing**: <yes|no>
- **Timestamp**: <ISO 8601>
```

## File Structure

| File | Action | What Changes |
|------|--------|--------------|
| `plugins/ralph-specum/references/intent-classification.md` | Modify | Add BUG_FIX intent type with priority rule, add to intent table, note 5 fixed questions |
| `plugins/ralph-specum/references/goal-interview.md` | Modify | Add Bug Interview section with 5 questions, skip approach-proposal and location interview for BUG_FIX |
| `plugins/ralph-specum/references/phase-rules.md` | Modify | Add BUG_FIX to workflow table, add Bug TDD Workflow section with Phase 0 format, canonical BEFORE format, update VF condition |
| `plugins/ralph-specum/references/quick-mode.md` | Modify | Flesh out step 10 stub with command inference, run, capture, write BEFORE state logic |
| `plugins/ralph-specum/agents/task-planner.md` | Modify | Add Bug TDD Task Planning section with Phase 0 prepend rule, mandatory VF, repro command sources |

No new files. No agent changes beyond task-planner.md.

## Technical Decisions

| Decision | Options | Choice | Rationale |
|----------|---------|--------|-----------|
| Where to define BEFORE format | phase-rules.md, goal-interview.md, quick-mode.md | phase-rules.md | Single source of truth -- already referenced by VF task template |
| Normal mode research serial vs parallel | Serial (reproduce->root cause), Parallel (existing model) | Parallel (existing model) | Research agents run in parallel already; reproduction happens in Phase 0 task, not research phase -- no conflict |
| BUG_FIX vs extending MID_SIZED | New type, OR add sub-routing inside MID_SIZED | New BUG_FIX type | Clean separation; MID_SIZED has no reproduce step, interview questions differ completely |
| TRIVIAL vs BUG_FIX conflict resolution | First match wins, keyword count, priority list | Priority list (TRIVIAL-specific keywords override BUG_FIX) | "fix typo" is TRIVIAL, "fix login bug" is BUG_FIX; trivial-specific words ("typo", "minor") are unambiguous |
| Quick mode repro command fallback | Error if no command, run test suite, skip | Run test suite | Non-interactive; test suite most likely to expose the failure; warning if cmd passes |
| Phase 0 task count | 1 task, 2 tasks, variable | Always exactly 2 (0.1 run + capture, 0.2 consistency re-run) | AC-3.3 requires at least two runs to confirm consistency. Two discrete tasks make each step verifiable and committable independently. |

## Error Handling

| Scenario | Handling |
|----------|----------|
| Phase 0: repro command not found in goal/quick-mode | Infer test runner from research.md; if still none, skip Phase 0 with warning in .progress.md |
| Phase 0: command exits 0 (bug not reproduced) | Write BEFORE state with `Confirmed failing: no`, append warning, continue (non-blocking) |
| Phase 0: command times out | Write timeout error to BEFORE state, mark `Confirmed failing: unknown`, continue |
| VF: command that passed in BEFORE now fails | VF is VERIFICATION_FAIL -- retry up to max |
| BUG_FIX detected but no bug interview answers (quick mode) | Skip interview, derive from goal text + quick mode step 10 BEFORE state |

## Edge Cases

- **"fix typo" goal**: TRIVIAL wins over BUG_FIX due to "typo" keyword -- no Phase 0, no bug questions
- **existing test already failing (Q4=yes)**: task-planner uses that test as the [RED] test (no need to write new one -- just confirm it fails)
- **quick mode + BUG_FIX**: step 10 writes BEFORE state; Phase 0 task reads and confirms it, no re-execution needed
- **repro command in Q5 is a multi-step manual process**: task-planner creates a shell script task wrapping the steps before Phase 0

## Test Strategy

### Unit Tests (manual spec validation)

- intent-classification.md: "fix login bug" -> BUG_FIX, "fix typo" -> TRIVIAL, "fix broken auth" -> BUG_FIX
- phase-rules.md: BUG_FIX spec tasks.md always has 0.1 [VERIFY] task before 1.1 [RED] task
- quick-mode.md step 10: goal with backtick command infers it, goal without command defaults to test runner

### Integration Test

- Run `/ralph-specum:start fix-login-bug "Fix login, getting 401 error" --quick` against a test project
- Verify: .progress.md contains `## Reality Check (BEFORE)`, tasks.md starts with `0.1 [VERIFY]`, ends with `VF`

## Existing Patterns Followed

- BUG_FIX intent table follows same format as TRIVIAL/REFACTOR/GREENFIELD/MID_SIZED in intent-classification.md
- Phase 0 task uses same `[VERIFY]` format as all other verification tasks in phase-rules.md
- BEFORE state format uses same `## Section Name` + bullet list format as `.progress.md` conventions throughout the codebase
- Bug interview section in goal-interview.md follows same "ask one at a time" rule as standard brainstorming dialogue
- Task-planner addition follows existing "when intent is X, do Y" pattern already used for workflow selection

## Implementation Steps

1. Modify `intent-classification.md`: add BUG_FIX entry to Classification Logic (before TRIVIAL), add to Dialogue Depth table, add priority rule, note 5 fixed questions
2. Modify `goal-interview.md`: add Bug Interview section with 5 exact questions, skip-approach-proposal note, skip-location-interview note
3. Modify `phase-rules.md`: add BUG_FIX to Workflow Selection table; add "Bug TDD Workflow" section with Phase 0 format, Phase 0 task template, canonical BEFORE state format; update VF condition
4. Modify `quick-mode.md`: replace step 10 stub with full command inference + run + capture + write logic
5. Modify `agents/task-planner.md`: add Bug TDD Task Planning section with Phase 0 prepend, mandatory VF, repro command sources
