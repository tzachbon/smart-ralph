---
name: quality-checkpoints
description: This skill should be used when the user asks about "quality checkpoints", "VERIFY tasks", "checkpoint frequency", "quality gate format", "intermediate validation", "task verification", or needs guidance on inserting and formatting quality checkpoints in task lists.
version: 0.1.0
---

# Quality Checkpoints

Quality checkpoints are `[VERIFY]` tagged tasks inserted throughout a spec to catch issues early. They ensure type checking, lint, and tests pass incrementally rather than finding many errors at the end.

## Checkpoint Frequency Rules

Insert quality checkpoints based on task complexity:

| Task Complexity | Checkpoint Frequency |
|-----------------|---------------------|
| Small/simple tasks | Every 3 tasks |
| Medium tasks | Every 2-3 tasks |
| Large/complex tasks | Every 2 tasks |

**Rationale:**
- Catch type errors, lint issues, and regressions early
- Prevent accumulation of technical debt
- Make debugging easier by limiting scope of potential issues
- Ensure each batch of work maintains code quality

## What Checkpoints Verify

Each checkpoint runs available quality commands:

1. Type checking: `pnpm check-types` or equivalent
2. Lint: `pnpm lint` or equivalent
3. Existing tests: `pnpm test` or equivalent (if tests exist)
4. E2E tests: `pnpm test:e2e` or equivalent (if E2E exists)
5. Build: Verify code compiles/builds successfully

**Important:** Discover actual commands from research.md. Do NOT assume `pnpm lint` or `npm test` exists.

## [VERIFY] Task Format

All quality checkpoints use the `[VERIFY]` tag prefix.

### Standard Checkpoint (Every 2-3 Tasks)

```markdown
- [ ] V1 [VERIFY] Quality check: <discovered lint cmd> && <discovered typecheck cmd>
  - **Do**: Run quality commands and verify all pass
  - **Verify**: All commands exit 0
  - **Done when**: No lint errors, no type errors
  - **Commit**: `chore(scope): pass quality checkpoint` (if fixes needed)
```

### Numbered Checkpoint in Phase

```markdown
- [ ] 1.3 [VERIFY] Quality checkpoint: <lint cmd> && <typecheck cmd>
  - **Do**: Run quality commands discovered from research.md
  - **Verify**: All commands exit 0
  - **Done when**: No lint errors, no type errors
  - **Commit**: `chore(scope): pass quality checkpoint` (only if fixes needed)
```

### With Tests

```markdown
- [ ] 2.3 [VERIFY] Quality checkpoint: <lint cmd> && <typecheck cmd> && <test cmd>
  - **Do**: Run quality commands discovered from research.md
  - **Verify**: All commands exit 0
  - **Done when**: No lint errors, no type errors, tests pass
  - **Commit**: `chore(scope): pass quality checkpoint` (only if fixes needed)
```

## Final Verification Sequence

The last 3 tasks of a spec should be a final verification sequence:

### Full Local CI (V4)

```markdown
- [ ] V4 [VERIFY] Full local CI: <lint> && <typecheck> && <test> && <e2e> && <build>
  - **Do**: Run complete local CI suite including E2E
  - **Verify**: All commands pass
  - **Done when**: Build succeeds, all tests pass, E2E green
  - **Commit**: `chore(scope): pass local CI` (if fixes needed)
```

### CI Pipeline (V5)

```markdown
- [ ] V5 [VERIFY] CI pipeline passes
  - **Do**: Verify GitHub Actions/CI passes after push
  - **Verify**: `gh pr checks` shows all green
  - **Done when**: CI pipeline passes
  - **Commit**: None
```

### Acceptance Criteria (V6)

```markdown
- [ ] V6 [VERIFY] AC checklist
  - **Do**: Read requirements.md, programmatically verify each AC-* is satisfied by checking code/tests/behavior
  - **Verify**: Grep codebase for AC implementation, run relevant test commands
  - **Done when**: All acceptance criteria confirmed met via automated checks
  - **Commit**: None
```

## Phase-Specific Placement

| Phase | Checkpoint After |
|-------|------------------|
| Phase 1 (POC) | Tasks 1.2, 1.5 (end of POC) |
| Phase 2 (Refactor) | Tasks 2.2, 2.4 |
| Phase 3 (Testing) | Tasks 3.2, 3.4 |
| Phase 4 (Quality) | V4, V5, V6 as final sequence |

## Example Task List with Checkpoints

```markdown
## Phase 1: Make It Work (POC)

- [ ] 1.1 Create component structure
  - **Do**: ...
  - **Verify**: `test -f src/Component.tsx`
  - **Commit**: `feat(ui): add component structure`

- [ ] 1.2 Add component logic
  - **Do**: ...
  - **Verify**: Component renders
  - **Commit**: `feat(ui): add component logic`

- [ ] 1.3 [VERIFY] Quality checkpoint: pnpm lint && pnpm check-types
  - **Do**: Run quality commands
  - **Verify**: All commands exit 0
  - **Done when**: No lint/type errors
  - **Commit**: `chore(ui): pass quality checkpoint` (if fixes needed)

- [ ] 1.4 Add API integration
  - **Do**: ...
  - **Verify**: API call succeeds
  - **Commit**: `feat(ui): add API integration`

- [ ] 1.5 POC validation
  - **Do**: End-to-end test of feature
  - **Verify**: Feature works via automated test
  - **Commit**: `feat(ui): complete POC`
```

## VF Task for Fix Goals

When `.progress.md` contains `## Reality Check (BEFORE)`, the goal is a fix-type and requires a VF (Verification Final) task at the end of Phase 4:

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

## Checkpoint Execution by spec-executor

When spec-executor receives a `[VERIFY]` task:

1. **Detection**: Check if task description contains `[VERIFY]` tag
2. **Delegation**: Delegate to qa-engineer subagent
3. **Result handling**:
   - `VERIFICATION_PASS`: Mark complete, commit if fixes made
   - `VERIFICATION_FAIL`: Keep task open, log details in .progress.md Learnings

### qa-engineer Invocation

```
Task: Execute this verification task

Spec: <spec-name>
Path: <spec-path>

Task: <full task description>

Task Body:
<Do/Verify/Done when sections>
```

## Commit Rules for Checkpoints

| Scenario | Commit Required |
|----------|-----------------|
| All checks pass, no fixes | No commit |
| Fixes were needed | Yes: `chore(scope): pass quality checkpoint` |
| Verification-only (V5, V6) | No commit |

Always include spec files in commits:
```bash
git add ./specs/<spec>/tasks.md ./specs/<spec>/.progress.md
```

## Usage in Agents

Reference this skill for checkpoint guidance:

```markdown
<skill-reference>
**Apply skill**: `skills/quality-checkpoints/SKILL.md`
Use checkpoint format and frequency rules when planning quality gates.
</skill-reference>
```

## Quality Checklist for Task Planning

Before completing task list, verify:

- [ ] Checkpoint inserted after every 2-3 tasks
- [ ] Checkpoints use actual commands from research.md
- [ ] Final verification sequence includes V4, V5, V6
- [ ] VF task included if goal is fix-type
- [ ] All checkpoints follow [VERIFY] format
