# Phase Rules

> Used by: implement.md, task-planner agent

All specs MUST follow the POC-first workflow with 5 phases. This is non-negotiable.

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

**Goal**: All local checks pass. Create PR and verify CI.

- All local checks must pass (lint, types, tests)
- Create PR, verify CI
- Never push directly to default branch (main/master)

**Phase distribution**: 10-15% (combined with Phase 5)

**Default Deliverable**: Pull request with ALL completion criteria met:
- Zero test regressions
- Code is modular/reusable
- CI checks green
- Review comments addressed

Phase 4 transitions into Phase 5 (PR Lifecycle) for continuous validation.

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

## Target Task Count

- Standard spec: 40-60+ tasks
- Phase distribution: Phase 1 = 50-60%, Phase 2 = 15-20%, Phase 3 = 15-20%, Phase 4-5 = 10-15%

## Behaviors That Change Per Phase

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
