---
name: reality-verification
description: Detect fix vs add goals, diagnose failures before work, verify fixes after. Ensures "fix X" specs actually fix X.
---

# Reality Verification

## Core Rule

**For fix goals: reproduce the failure BEFORE work, verify resolution AFTER.**

## Goal Detection

Classify user goals to determine if diagnosis is needed.

### Detection Heuristics

| Pattern | Type | Match |
|---------|------|-------|
| fix, repair, resolve, debug, patch | Fix | `\b(fix\|repair\|resolve\|debug\|patch)\b` |
| broken, failing, error, bug, issue | Fix | `\b(broken\|failing\|error\|bug\|issue)\b` |
| "not working", "doesn't work" | Fix | `not\s+working\|doesn't\s+work` |
| add, create, build, implement, new | Add | `\b(add\|create\|build\|implement\|new)\b` |

**Conflict resolution**: If both Fix and Add patterns present, treat as Fix. Fixing enables the feature.

## Command Mapping

Map goal keywords to reproduction commands.

| Goal Keywords | Reproduction Command |
|---------------|---------------------|
| CI, pipeline, actions | `gh run view --log-failed` |
| test, tests, spec | project test command (package.json scripts.test) |
| type, types, typescript | `pnpm check-types` or `tsc --noEmit` |
| lint, linting | `pnpm lint` or `eslint .` |
| build, compile | `pnpm build` or `npm run build` |
| deploy, deployment | `gh api` or MCP fetch to check status |
| E2E, UI, browser, visual | MCP playwright to screenshot or run E2E suite |
| endpoint, API, response | MCP fetch with expected status/response validation |
| site, page, live | MCP fetch/playwright to verify live behavior |

**Fallback**: If no keyword match, ask user or skip diagnosis.

## E2E Verification with MCP Tools

For deployment and UI verification, use MCP tools:

### Playwright (UI/E2E)
```
When goal involves: UI broken, E2E failing, visual regression, page not loading

BEFORE: Use MCP playwright to:
- Capture screenshot of broken state
- Run failing E2E test
- Document visible error

AFTER: Same action should:
- Show fixed UI
- E2E test passes
- No visible error
```

### Fetch (API/Deployment)
```
When goal involves: API down, endpoint failing, deployment broken, 500 errors

BEFORE: Use MCP fetch to:
- Hit endpoint, capture status code
- Document error response body
- Note timestamp

AFTER: Same endpoint should:
- Return expected status (200, 201, etc)
- Response matches expected schema
- No error in body
```

## BEFORE/AFTER Documentation

### BEFORE State (Diagnosis)

Document in `.progress.md` under `## Reality Check (BEFORE)`:

```markdown
## Reality Check (BEFORE)

**Goal type**: Fix
**Reproduction command**: `pnpm test`
**Failure observed**: Yes
**Output**:
```
FAIL src/auth.test.ts
  Expected: 200
  Received: 401
```
**Timestamp**: 2026-01-16T10:30:00Z
```

### AFTER State (Verification)

Document in `.progress.md` under `## Reality Check (AFTER)`:

```markdown
## Reality Check (AFTER)

**Command**: `pnpm test`
**Result**: PASS
**Output**:
```
PASS src/auth.test.ts
All tests passed
```
**Comparison**: BEFORE failed with 401, AFTER passes
**Verified**: Issue resolved
```

## VF Task Format

Add as task 4.3 (after PR creation) for fix-type specs:

```markdown
- [ ] 4.3 VF: Verify original issue resolved
  - **Do**:
    1. Read BEFORE state from .progress.md
    2. Re-run reproduction command: `<command>`
    3. Compare output with BEFORE state
    4. Document AFTER state in .progress.md
  - **Verify**: `grep -q "Verified: Issue resolved" ./specs/<name>/.progress.md`
  - **Done when**: AFTER shows issue resolved, documented in .progress.md
  - **Commit**: `chore(<name>): verify fix resolves original issue`
```

## Why This Matters

| Without | With |
|---------|------|
| "Fix CI" spec completes but CI still red | CI verified green before merge |
| Tests "fixed" but original failure unknown | Before/after comparison proves fix |
| Silent regressions | Explicit failure reproduction |
| Manual verification required | Automated verification in workflow |
# Version 2.1.0
