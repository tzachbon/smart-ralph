# E2E Anti-Patterns — Canonical Reference

> Used by: coordinator-pattern.md, task-planner.md, spec-executor.md, qa-engineer.md, mcp-playwright.skill.md, playwright-session.skill.md

This is the **single source of truth** for E2E anti-patterns. All other files
reference this list. When adding a new anti-pattern, add it here first, then
reference it from the relevant files.

## Navigation Anti-Patterns

| Anti-Pattern | Why it fails | Correct pattern |
|---|---|---|
| `page.goto('/internal/route')` for internal app routes | Bypasses client-side routing and auth state; causes 404, blank pages, or TimeoutErrors | Navigate via UI elements: sidebar clicks, menu items, links |
| Navigating to URLs with `auth_callback`, `code=`, or `state=` params | OAuth tokens are already consumed by the setup process; browser gets auth rejection | Use `new URL(url).origin` to extract the base URL |
| Duplicate `waitForURL` calls for the same expected URL | Dead code; sign of uncertainty about page state | One `waitForURL` per expected navigation state |

**Exception**: `page.goto()` to the **base URL** (app root) is correct for initial navigation and auth flows.

## Selector Anti-Patterns

| Anti-Pattern | Why it fails | Correct pattern |
|---|---|---|
| Hand-written CSS selectors or XPath | Break across app versions, fragile to DOM restructuring | Use `getByRole` > `getByTestId` > `browser_generate_locator` |
| Hardcoded `entity_id`, dynamic IDs, or session-specific values | Unstable across test instances and environments | Use semantic selectors: `getByRole`, `getByLabel`, `getByTestId` |
| Inventing selectors from memory without verification | Selector may not match actual DOM; causes silent failures | Read `ui-map.local.md` or use `browser_generate_locator` from live page |
| Shadow DOM traversal by depth (`>>>` chains) | Fragile to DOM restructuring; breaks when HA updates | Use `getByTestId` or `getByRole` (Playwright traverses shadow DOM automatically) |

## Timing Anti-Patterns

| Anti-Pattern | Why it fails | Correct pattern |
|---|---|---|
| `waitForTimeout(N)` | Flaky: too short = intermittent failures, too long = slow tests | Use condition-based waits: `waitForSelector`, `waitForURL`, `waitForResponse` |
| No stable state check after navigation | Actions on loading pages cause element-not-found errors | Always `browser_snapshot` + loading indicator check after navigation |

## Auth Anti-Patterns

| Anti-Pattern | Why it fails | Correct pattern |
|---|---|---|
| Reusing consumed OAuth/auth callback tokens | Token already used by setup infrastructure; browser gets auth rejection | Use the base URL; let the app handle auth flow from scratch |
| `goto()` to auth-protected routes without established session | App redirects to login or returns 401; test hangs on unexpected state | Complete auth flow first, then navigate via UI |
| Silently re-authenticating mid-flow | Masks auth expiry bugs; test passes but app has a real auth issue | Surface auth expiry as `VERIFICATION_FAIL` |

## Test Quality Anti-Patterns

| Anti-Pattern | Why it fails | Correct pattern |
|---|---|---|
| Tests that only verify `toHaveBeenCalled` with no state/value assertions | Confirms function was called, not that it produced correct results | Assert on real return values and state changes |
| `describe.skip` / `it.skip` without GitHub issue reference | Silently disables tests; failures go unnoticed | `it.skip('TODO: #<issue> — <reason>', ...)` |
| Empty test bodies `it('does X', () => {})` | Always passes, tests nothing | Write real assertions or remove the test |
| Mocking own business logic to make tests pass | Tests verify mocks, not real code | Only mock what the architect marked as mockable in Test Strategy |

## How to Reference This File

In delegation prompts and task descriptions, reference this file as:
```
See: ${CLAUDE_PLUGIN_ROOT}/references/e2e-anti-patterns.md
```

In skill files and agent prompts, use the relative path:
```
See: references/e2e-anti-patterns.md
```
