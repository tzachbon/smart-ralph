# Phase Rules

> Used by: implement.md, task-planner agent

All specs follow one of two workflows based on intent classification:
- **GREENFIELD** intent → POC-first workflow (5 phases)
- **Non-greenfield** intent (TRIVIAL, REFACTOR, MID_SIZED) → TDD Red-Green-Yellow workflow (4 phases)

## Workflow Selection

Read Intent Classification from `.progress.md`:

```text
## Intent Classification
- Type: [TRIVIAL|REFACTOR|GREENFIELD|MID_SIZED]
```

| Intent | Workflow | Rationale |
|--------|----------|-----------|
| GREENFIELD | POC-first | New feature needs fast validation before investing in tests |
| TRIVIAL | TDD | Fix/small change — existing code has (or should have) tests to build on |
| REFACTOR | TDD | Restructuring existing code — tests guard against regressions |
| MID_SIZED | TDD | Extending existing feature — tests define expected behavior first |

---

# POC-First Workflow (GREENFIELD)

## Phase 1: Make It Work (POC)

**Goal**: Validate the idea works end-to-end. Move fast.

- Skip tests, accept hardcoded values
- Only type check must pass
- Focus on working prototype, not perfection
- By end of Phase 1, the integration must be PROVEN working with real external systems, not just compiling

**Phase distribution**: 50-60% of total tasks

**POC Checkpoint** (last task of Phase 1):
```markdown
- [ ] 1.N POC Checkpoint
  - **Do**: Verify feature works end-to-end using automated tools (WebFetch, curl, browser automation, test runner)
  - **Done when**: Feature can be demonstrated working via automated verification
  - **Verify**: Run automated end-to-end verification
  - **Commit**: `feat(scope): complete POC`
```

## Phase 2: Refactoring

**Goal**: Clean up code structure. No new features.

- Clean up code, add error handling
- Type check must pass
- Follow project patterns
- Extract and modularize components

**Phase distribution**: 15-20% of total tasks

## Phase 3: Testing

**Goal**: Add comprehensive test coverage.

- Write tests as specified (unit, integration, e2e)
- All tests must pass
- Cover main functionality and integration points

**Phase distribution**: 15-20% of total tasks

## Phase 4: Quality Gates

**Goal**: All local checks pass. Create PR and verify CI. VE Tasks (E2E Verification) run after V6 in this phase.

- All local checks must pass (lint, types, tests)
- Create PR, verify CI
- Never push directly to default branch (main/master)
- VE tasks appear after V6, before Phase 5 transition (see "VE Tasks" section)

**Phase distribution**: 10-15% (combined with Phase 5)

**Default Deliverable**: Pull request with ALL completion criteria met:
- Zero test regressions
- Code is modular/reusable
- CI checks green
- Review comments addressed

Phase 4 transitions into Phase 5 (PR Lifecycle) for continuous validation. VE tasks appear in the final verification sequence: V4 -> V5 -> V6 -> VE1/VE2/VE3 -> Phase 5.

## Phase 5: PR Lifecycle

**Goal**: Autonomous PR management loop until all criteria met.

- PR creation
- CI monitoring and fixing
- Code review comment resolution
- Final validation (zero regressions, modularity, real-world verification)

Phase 5 runs autonomously until ALL completion criteria met. The spec is NOT done when Phase 4 completes.

**Loop structure**:
```
PR Creation -> CI Monitoring -> Review Check -> Fix Issues -> Push -> Repeat
```

**Completion criteria** (all must be true):
- All Phase 1-4 tasks complete (checked [x])
- All Phase 5 tasks complete
- CI checks all green
- No unresolved review comments
- Zero test regressions (all existing tests pass)
- Code is modular/reusable (verified in .progress.md)

**Timeout protection**:
- Max 48 hours in PR Lifecycle Loop
- Max 20 CI monitoring cycles
- If exceeded: output error and STOP

---

# TDD Workflow (Non-Greenfield)

When Intent Classification is NOT `GREENFIELD`, use TDD Red-Green-Yellow workflow. Tests come FIRST — they define the expected behavior before implementation.

## TDD Phase 1: Red-Green-Yellow Cycles

**Goal**: Implement features/fixes through disciplined TDD triplets.

Each unit of work is a 3-task cycle:

1. **[RED]** — Write a failing test that captures expected behavior. Verify the test FAILS.
2. **[GREEN]** — Write minimum code to make the test pass. Verify the test PASSES.
3. **[YELLOW]** — Refactor implementation while keeping tests green. Verify tests still pass + lint.

**Rules**:
- Every implementation change starts with a [RED] test
- [GREEN] must be minimal — only enough to pass the test, no more
- [YELLOW] is optional per triplet (skip if code is already clean)
- Quality checkpoints after every 1-2 triplets (every 3-6 tasks)
- Group related behavior into triplets (one triplet per logical behavior)

**Phase distribution**: 60-70% of total tasks

**TDD triplet format**:
```markdown
- [ ] 1.1 [RED] Failing test: <expected behavior>
  - **Do**: Write test asserting expected behavior (must fail initially)
  - **Files**: <test file>
  - **Done when**: Test exists AND fails with expected assertion error
  - **Verify**: `<test cmd> -- --grep "<test name>" 2>&1 | grep -q "FAIL\|fail\|Error" && echo RED_PASS`
  - **Commit**: `test(scope): red - failing test for <behavior>`
  - _Requirements: FR-1, AC-1.1_

- [ ] 1.2 [GREEN] Pass test: <minimal implementation>
  - **Do**: Write minimum code to make failing test pass
  - **Files**: <impl file>
  - **Done when**: Previously failing test now passes
  - **Verify**: `<test cmd> -- --grep "<test name>"`
  - **Commit**: `feat(scope): green - implement <behavior>`
  - _Requirements: FR-1, AC-1.1_

- [ ] 1.3 [YELLOW] Refactor: <cleanup description>
  - **Do**: Refactor while keeping tests green
  - **Files**: <impl file, test file if needed>
  - **Done when**: Code is clean AND all tests pass
  - **Verify**: `<test cmd> && <lint cmd>`
  - **Commit**: `refactor(scope): yellow - clean up <component>`
```

## TDD Phase 2: Additional Testing

**Goal**: Integration and E2E tests beyond what [RED] steps covered.

- Unit tests are already written in Phase 1 [RED] steps
- This phase adds integration tests spanning multiple components
- E2E tests for user-facing flows
- Lighter than POC Phase 3 since core coverage exists

**Phase distribution**: 10-15% of total tasks

## TDD Phase 3: Quality Gates

Same as POC Phase 4. All local checks pass, create PR, verify CI. VE tasks apply identically: after V6 (AC checklist), before Phase 4 (PR Lifecycle). See "VE Tasks (E2E Verification)" section for placement, structure, and rules.

**Phase distribution**: 10-15% of total tasks

## TDD Phase 4: PR Lifecycle

Same as POC Phase 5. Autonomous PR management loop.

**Phase distribution**: 5-10% of total tasks

## TDD Target Task Count

- Standard spec: 30-50+ tasks (smaller than POC since no throw-away prototyping)
- Phase distribution: Phase 1 (TDD cycles) = 60-70%, Phase 2 (Additional tests) = 10-15%, Phase 3-4 (Quality/PR) = 15-25%

## TDD Behaviors Per Phase

| Behavior | TDD Phase 1 | TDD Phase 2 | TDD Phase 3 | TDD Phase 4 |
|----------|-------------|-------------|-------------|-------------|
| Tests required | Yes (from start) | Yes | Yes | Yes |
| Type check must pass | Yes | Yes | Yes | Yes |
| Lint must pass | Yes (in [YELLOW]) | Yes | Yes | Yes |
| Hardcoded values OK | No | No | No | No |
| Error handling required | Yes (test it first) | Yes | Yes | Yes |
| CI must be green | No | No | Yes | Yes |
| PR required | No | No | Yes | Yes |
| Review comments resolved | No | No | No | Yes |

---

## VF Task for Fix Goals

When `.progress.md` contains `## Reality Check (BEFORE)`, the goal is a fix-type and requires a VF (Verification Final) task as the final task in Phase 4:

```markdown
- [ ] VF [VERIFY] Goal verification: original failure now passes
  - **Do**:
    1. Read BEFORE state from .progress.md
    2. Re-run reproduction command from Reality Check (BEFORE)
    3. Compare output with BEFORE failure
    4. Document AFTER state in .progress.md
  - **Verify**: Exit code 0 for reproduction command
  - **Done when**: Command that failed before now passes
  - **Commit**: `chore(<spec>): verify fix resolves original issue`
```

## VE Tasks (E2E Verification)

> See also: `${CLAUDE_PLUGIN_ROOT}/references/quality-checkpoints.md` for VE format details and verify-fix-reverify loop. See `${CLAUDE_PLUGIN_ROOT}/agents/task-planner.md` "VE Task Generation" for VE templates and generation rules.

VE tasks provide autonomous end-to-end verification by spinning up real infrastructure and testing built features against it.

### Placement

VE tasks extend the final verification sequence, after V6 and before Phase 5:

```text
V4 (Full local CI) -> V5 (CI pipeline) -> V6 (AC checklist) -> VE1 -> VE2 -> VE3 -> PR Lifecycle
```

### Structure

VE tasks follow a 3-part structure:

1. **VE1 (Startup)** — Start dev server/infrastructure in background, record PID, wait for ready
2. **VE2 (Check)** — Test critical user flows via curl/browser/CLI, verify expected output
3. **VE3 (Cleanup)** — Kill by PID, kill by port fallback, remove PID file, verify port free

### Rules

- **Sequential**: VE tasks are always sequential (never `[P]`). Infrastructure state is shared.
- **[VERIFY] tagged**: All VE tasks use `[VERIFY]` and are delegated to qa-engineer.
- **Cleanup guaranteed**: VE3 (cleanup) MUST run even if VE1 or VE2 fail. Coordinator skips to VE3 on max retries.
- **Commands from research.md**: All commands (dev server, port, health endpoint) come from research.md Verification Tooling section. Never hardcoded.
- **Recovery mode always enabled**: VE failures trigger fix task generation via existing recovery mode, regardless of state file recoveryMode flag.
- **Max 3 retries per VE task**: After 3 failed attempts, skip to VE-cleanup and report error.

### When Omitted

- **Quick mode**: VE tasks are auto-enabled (no user prompt needed)
- **Normal mode**: User can skip VE tasks during interview (default: YES)
- **Library projects**: Get minimal VE (build + import check only, no dev server startup)

## Quality Checkpoint Rules

Insert quality gate checkpoints throughout the task list to catch issues early.

### Frequency

- After every **2-3 tasks** (depending on task complexity)
- Small/simple tasks: insert checkpoint after 3 tasks
- Medium tasks: insert checkpoint after 2-3 tasks
- Large/complex tasks: insert checkpoint after 2 tasks

### What Quality Checkpoints Verify

1. Type checking passes: `pnpm check-types` or equivalent
2. Lint passes: `pnpm lint` or equivalent
3. Existing tests pass: `pnpm test` or equivalent (if tests exist)
4. E2E tests pass: `pnpm test:e2e` or equivalent (if E2E exists)
5. Code compiles/builds successfully

### Checkpoint Format

Standard [VERIFY] checkpoint (every 2-3 tasks):
```markdown
- [ ] V1 [VERIFY] Quality check: <discovered lint cmd> && <discovered typecheck cmd>
  - **Do**: Run quality commands and verify all pass
  - **Verify**: All commands exit 0
  - **Done when**: No lint errors, no type errors
  - **Commit**: `chore(scope): pass quality checkpoint` (if fixes needed)
```

Final verification sequence (last 3 tasks of spec):
```markdown
- [ ] V4 [VERIFY] Full local CI: <lint> && <typecheck> && <test> && <e2e> && <build>
  - **Do**: Run complete local CI suite including E2E
  - **Verify**: All commands pass
  - **Done when**: Build succeeds, all tests pass, E2E green
  - **Commit**: `chore(scope): pass local CI` (if fixes needed)

- [ ] V5 [VERIFY] CI pipeline passes
  - **Do**: Verify GitHub Actions/CI passes after push
  - **Verify**: `gh pr checks` shows all green
  - **Done when**: CI pipeline passes
  - **Commit**: None

- [ ] V6 [VERIFY] AC checklist
  - **Do**: Read requirements.md, programmatically verify each AC-* is satisfied
  - **Verify**: Grep codebase for AC implementation, run relevant test commands
  - **Done when**: All acceptance criteria confirmed met via automated checks
  - **Commit**: None
```

### [VERIFY] Task Delegation

[VERIFY] tasks are special verification checkpoints:
- Delegated to qa-engineer (not spec-executor)
- Always sequential (break parallel groups)
- VERIFICATION_PASS = treat as TASK_COMPLETE, mark [x], update .progress.md
- VERIFICATION_FAIL = do NOT mark complete, increment taskIteration, retry or error if max reached

### Discovery

Read research.md for actual project commands. Do NOT assume `pnpm lint` or `npm test` exists. Use the commands discovered from the codebase.

## POC Target Task Count

- Standard spec: 40-60+ tasks
- Phase distribution: Phase 1 = 50-60%, Phase 2 = 15-20%, Phase 3 = 15-20%, Phase 4-5 = 10-15%

## POC Behaviors Per Phase

| Behavior | Phase 1 | Phase 2 | Phase 3 | Phase 4 | Phase 5 |
|----------|---------|---------|---------|---------|---------|
| Tests required | No | No | Yes | Yes | Yes |
| Type check must pass | Yes | Yes | Yes | Yes | Yes |
| Lint must pass | No | No | No | Yes | Yes |
| Hardcoded values OK | Yes | No | No | No | No |
| Error handling required | No | Yes | Yes | Yes | Yes |
| CI must be green | No | No | No | Yes | Yes |
| PR required | No | No | No | Yes | Yes |
| Review comments resolved | No | No | No | No | Yes |
