---
name: phase-rules
description: This skill should be used when the user asks about "POC phase", "refactoring phase", "testing phase", "quality gates phase", "PR lifecycle phase", "phase-specific rules", "shortcuts allowed", "phase behaviors", or needs guidance on what behaviors, shortcuts, and requirements apply during each development phase.
version: 0.1.0
---

# Phase-Specific Rules

The spec workflow progresses through 5 distinct phases. Each phase has specific goals, allowed shortcuts, and requirements that must be followed.

## Phase Overview

| Phase | Goal | Shortcuts Allowed | Must Pass |
|-------|------|-------------------|-----------|
| 1 - POC | Working prototype | Tests, hardcoded values | Type check |
| 2 - Refactoring | Clean code | None | Type check |
| 3 - Testing | Complete tests | None | All tests |
| 4 - Quality Gates | CI ready | None | All local checks |
| 5 - PR Lifecycle | Merged PR | None | CI + reviews |

## Phase 1: POC (Proof of Concept)

**Goal**: Get a working prototype as fast as possible.

**Allowed Shortcuts**:
- Skip writing tests (deferred to Phase 3)
- Accept hardcoded values (cleaned up in Phase 2)
- Minimal error handling (enhanced in Phase 2)
- Ignore code style/lint issues temporarily
- Use simple implementations over elegant ones

**Must Pass**:
- Type check (if applicable to project)
- Basic functionality works

**Mindset**: "Make it work first, make it right later."

**What NOT to Skip**:
- Core functionality
- Security-critical code
- Breaking existing tests (existing tests must still pass)

## Phase 2: Refactoring

**Goal**: Clean up POC code, add robustness.

**Allowed Shortcuts**:
- None - this is the cleanup phase

**Must Pass**:
- Type check
- Lint checks (if not too burdensome)
- Code follows project patterns

**Tasks**:
- Replace hardcoded values with configuration
- Add proper error handling
- Follow project naming conventions
- Reduce code duplication
- Add missing type annotations
- Improve code organization

**Mindset**: "Make it right."

## Phase 3: Testing

**Goal**: Comprehensive test coverage.

**Allowed Shortcuts**:
- None

**Must Pass**:
- All new tests pass
- All existing tests pass
- Test coverage meets project requirements (if specified)

**Tasks**:
- Write unit tests for new code
- Write integration tests if applicable
- Add edge case tests
- Ensure mocking is appropriate
- Verify test isolation

**Mindset**: "Make it reliable."

## Phase 4: Quality Gates

**Goal**: Ready for CI/CD pipeline.

**Allowed Shortcuts**:
- None

**Must Pass**:
- All local checks: lint, type, test, build
- PR created successfully
- CI pipeline passes

**Tasks**:
1. Run all local quality checks
2. Fix any issues found
3. Create PR with proper description
4. Verify CI passes

**Commands to Run** (project-specific):
```bash
# Discover from package.json, Makefile, or CI config
npm run lint        # or equivalent
npm run typecheck   # or equivalent
npm run test        # or equivalent
npm run build       # or equivalent
```

**Mindset**: "Make it pass all gates."

## Phase 5: PR Lifecycle

**Goal**: Get PR merged with all checks passing.

**Allowed Shortcuts**:
- None - this is the final validation

**Must Pass**:
- Zero test regressions
- Code is modular/reusable
- CI green
- Review comments resolved

**Execution Pattern**: Wait-and-iterate loop

1. Push changes
2. Wait 3-5 minutes for CI
3. Check CI status via `gh pr checks`
4. If failures: read logs, fix issues, push again
5. Monitor review comments via `gh api`
6. Address feedback, push updates
7. Repeat until all criteria met

**Tools**:
```bash
# Monitor CI
gh pr checks --watch

# Get PR comments
gh api repos/{owner}/{repo}/pulls/{pr}/comments

# Check CI status
gh pr checks | grep -v "pending\|in_progress"
```

**Mindset**: "Iterate until done."

**Completion Criteria**:
- All CI checks pass (green)
- All review comments addressed
- No test regressions
- Ready for merge

## Phase Detection

Tasks in `tasks.md` are grouped by phase:

```markdown
## Phase 1: Make It Work (POC)
- [ ] 1.1 Core functionality
- [ ] 1.2 Basic integration

## Phase 2: Refactoring
- [ ] 2.1 Clean up hardcoded values
- [ ] 2.2 Add error handling

## Phase 3: Testing
- [ ] 3.1 Unit tests
- [ ] 3.2 Integration tests

## Phase 4: Quality Gates
- [ ] 4.1 Local validation
- [ ] 4.2 Create PR

## Phase 5: PR Lifecycle
- [ ] 5.1 Fix CI failures
- [ ] 5.2 Address review comments
```

Read the phase header to determine current phase behavior rules.

## Quality Checkpoints

Quality checkpoints (`[VERIFY]` tasks) appear throughout all phases, typically every 2-3 tasks. These are NOT phase-specific but ensure ongoing quality.

See `skills/quality-checkpoints/SKILL.md` for checkpoint handling.

## Shortcuts Summary Table

| Action | Phase 1 | Phase 2 | Phase 3 | Phase 4 | Phase 5 |
|--------|---------|---------|---------|---------|---------|
| Skip tests | OK | NO | NO | NO | NO |
| Hardcoded values | OK | NO | NO | NO | NO |
| Minimal error handling | OK | NO | NO | NO | NO |
| Skip lint | OK | OK | OK | NO | NO |
| Skip type check | NO | NO | NO | NO | NO |
| Skip existing tests | NO | NO | NO | NO | NO |

## Usage in Agents

Reference this skill when phase-aware behavior is needed:

```markdown
<skill-reference>
**Apply skill**: `skills/phase-rules/SKILL.md`
Follow phase-specific rules for allowed shortcuts and requirements.
</skill-reference>
```

## Common Mistakes

**Phase 1 Mistakes**:
- Over-engineering the POC
- Writing tests too early
- Perfecting code style before it works

**Phase 2 Mistakes**:
- Skipping error handling
- Not removing hardcoded values
- Changing functionality (should only refactor)

**Phase 3 Mistakes**:
- Writing tests that test implementation details
- Insufficient coverage
- Flaky tests

**Phase 4/5 Mistakes**:
- Pushing without running local checks
- Not monitoring CI results
- Ignoring review comments
