# Quality Checkpoints

> Used by: task-planner agent

## Purpose

Quality gate checkpoints are inserted throughout the task list to catch type errors, lint issues, and regressions early. They prevent accumulation of technical debt and make debugging easier by limiting the scope of potential issues.

## Frequency Rules

| Task Complexity | Checkpoint Frequency |
|----------------|---------------------|
| Small/simple tasks | After every 3 tasks |
| Medium tasks | After every 2-3 tasks |
| Large/complex tasks | After every 2 tasks |

## What Checkpoints Verify

1. Type checking passes: `pnpm check-types` or equivalent
2. Lint passes: `pnpm lint` or equivalent
3. Existing tests pass: `pnpm test` or equivalent (if tests exist)
4. E2E tests pass: `pnpm test:e2e` or equivalent (if E2E exists)
5. Code compiles/builds successfully

**Discovery**: Read `research.md` for actual project commands. Do NOT assume `pnpm lint` or `npm test` exists.

## [VERIFY] Task Format

All checkpoints use the `[VERIFY]` tag and follow the standard Do/Verify/Done when/Commit format.

### Standard Checkpoint (every 2-3 tasks)

```markdown
- [ ] V1 [VERIFY] Quality check: <discovered lint cmd> && <discovered typecheck cmd>
  - **Do**: Run quality commands and verify all pass
  - **Verify**: All commands exit 0
  - **Done when**: No lint errors, no type errors
  - **Commit**: `chore(scope): pass quality checkpoint` (if fixes needed)
```

### Phase-Specific Checkpoints

**Phase 1 (POC)**: Lint + type check only.

```markdown
- [ ] 1.3 [VERIFY] Quality checkpoint: <lint cmd> && <typecheck cmd>
  - **Do**: Run quality commands discovered from research.md
  - **Verify**: All commands exit 0
  - **Done when**: No lint errors, no type errors
  - **Commit**: `chore(scope): pass quality checkpoint` (only if fixes needed)
```

**Phase 2 (Refactoring)**: Lint + type check + tests.

```markdown
- [ ] 2.3 [VERIFY] Quality checkpoint: <lint cmd> && <typecheck cmd> && <test cmd>
  - **Do**: Run quality commands discovered from research.md
  - **Verify**: All commands exit 0
  - **Done when**: No lint errors, no type errors, tests pass
  - **Commit**: `chore(scope): pass quality checkpoint` (only if fixes needed)
```

**Phase 3 (Testing)**: Lint + type check + tests (same as Phase 2).

```markdown
- [ ] 3.3 [VERIFY] Quality checkpoint: <lint cmd> && <typecheck cmd> && <test cmd>
  - **Do**: Run quality commands discovered from research.md
  - **Verify**: All commands exit 0
  - **Done when**: No lint errors, no type errors, tests pass
  - **Commit**: `chore(scope): pass quality checkpoint` (only if fixes needed)
```

**Phase 4 (Quality Gates)**: Full local CI suite.

```markdown
- [ ] 4.1 Local quality check
  - **Do**: Run ALL quality checks locally
  - **Verify**: All commands must pass:
    - Type check: `pnpm check-types` or equivalent
    - Lint: `pnpm lint` or equivalent
    - Tests: `pnpm test` or equivalent
  - **Done when**: All commands pass with no errors
  - **Commit**: `fix(scope): address lint/type issues` (if fixes needed)
```

## Final Verification Sequence (Last 3 Tasks)

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
  - **Do**: Read requirements.md, programmatically verify each AC-* is satisfied by checking code/tests/behavior
  - **Verify**: Grep codebase for AC implementation, run relevant test commands
  - **Done when**: All acceptance criteria confirmed met via automated checks
  - **Commit**: None
```

## VF Task for Fix Goals

When `.progress.md` contains `## Reality Check (BEFORE)`, the goal is a fix-type. Add a VF task as the final task in Phase 4 (after PR creation):

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

## Execution: How [VERIFY] Tasks Are Handled

The spec-executor does NOT execute [VERIFY] tasks directly. It delegates them to the `qa-engineer` subagent via Task tool:

1. Detect `[VERIFY]` tag in task description
2. Delegate to qa-engineer with spec name, path, and full task body
3. On VERIFICATION_PASS: mark task complete, update progress, commit if fixes made
4. On VERIFICATION_FAIL: do NOT mark complete, log failure in .progress.md Learnings, let retry loop handle it
