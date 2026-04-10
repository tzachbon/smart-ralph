---
name: playwright-session
version: 9
description: Load this skill before any Playwright browser interaction in a VE task. Covers session lifecycle, context isolation, auth flows, stable-state detection, cache isolation, and cleanup. Requires playwright-env and mcp-playwright to be loaded first.
agents: [spec-executor, qa-engineer]
---

# Playwright Session Skill

This skill governs the **session lifecycle** for MCP Playwright interactions. Load it before any VE task that uses browser tools.

**Prerequisites** (load in this order before this skill):
1. `playwright-env.skill.md` — resolves appUrl, authMode, isolated, writes `playwrightEnv` to state
2. `mcp-playwright.skill.md` — dependency check, lock recovery, writes `mcpPlaywright` to state

Session start reads `appUrl`, `authMode`, `isolated`, and related values from
`.ralph-state.json → playwrightEnv` and `.ralph-state.json → mcpPlaywright` —
never from hardcoded values.

> ⚠️ **The MCP server is managed by the human**, not the agent. The agent
> never launches, kills, or restarts the server process. The agent only calls
> `browser_*` tools exposed by the already-running server. If the server
> appears to be missing or misconfigured, emit `ESCALATE`.

---

## Session Lifecycle

### Start

1. Check `mcpPlaywright` in `.ralph-state.json` — if `missing`, switch to degraded mode (see `mcp-playwright.skill.md`)
2. Read `playwrightEnv` from `.ralph-state.json` — use `appUrl`, `browser`, `headless`, `viewport`, `locale`, `timezone`, `isolated`
3. If `isolated = false`: run lock-recovery check from `mcp-playwright.skill.md → Step 0b` before proceeding
4. Open the browser session and complete auth according to `authMode`. The sequence
   **varies by authMode** — follow the table below exactly:

   | authMode | Sequence |
   |---|---|
   | `none` | `browser_navigate(appUrl)` → stable state check |
   | `form` | `browser_navigate(loginUrl or appUrl)` → Auth Flow → stable state check |
   | `token` | `browser_navigate(appUrl)` → inject token (Pattern A/B) → Auth Flow confirms state |
   | `cookie` | inject cookie into context **before any navigation** → `browser_navigate(appUrl)` → stable state check |
   | `storage-state` | load state file **before any navigation** → `browser_navigate(appUrl)` → stable state check |
   | `basic` | `browser_navigate(appUrl with credentials)` → stable state check |
   | `oauth` / `sso` | emit `ESCALATE` (see Auth Flow section) |

   > ⚠️ **`browser_navigate` does NOT reset browser state** (cookies, localStorage,
   > session data) within the same server session. Isolation comes from the server
   > being started with `--isolated` (ephemeral profile), not from per-navigation resets.
   > Never assume a new `browser_navigate` gives you a clean slate.

5. Navigate to the target URL (if different from the auth URL used above)
6. Wait for stable state — see Stable State Detection below

### During

> **Scope**: "during" means within a single VE task — the steps between Session Start
> and Session End for one task. Do NOT reuse a session across multiple VE tasks.
> `spec-executor.md` is the authority on session policy between VE tasks.

- Always re-snapshot after any navigation or significant DOM mutation before continuing

### End (MANDATORY)

Always close the session, even if verification failed:

```bash
1. browser_close
2. Write session status to .ralph-state.json atomically using a unique temp file:

   TMP_STATE_FILE=$(mktemp "<basePath>/.ralph-state.json.tmp.XXXXXX") || TMP_STATE_FILE="/tmp/.ralph-state.json.$$"
   if jq '.lastPlaywrightSession = "closed"' <basePath>/.ralph-state.json > "$TMP_STATE_FILE"; then
     mv "$TMP_STATE_FILE" <basePath>/.ralph-state.json
   else
     rm -f "$TMP_STATE_FILE" 2>/dev/null || true
     echo "STATE_WRITE_FAILED" >&2
   fi
```

**If `browser_close` fails or the session terminated abnormally** (timeout, tool error, unexpected disconnect):

```bash
# The server process is managed by the human — do NOT pkill it.
# Only clean up the stale lock file so the next session can start cleanly.
# Only do this if browser_close failed — do not remove a lock owned by a live process.
MCP_LOCK="$HOME/.cache/ms-playwright/mcp-chrome/SingletonLock"
if [ -f "$MCP_LOCK" ]; then
  # Read the full lock file content first (used for TOCTOU re-check below)
  LOCK_CONTENT=$(cat "$MCP_LOCK" 2>/dev/null)
  LOCK_PID=$(echo "$LOCK_CONTENT" | cut -d- -f1)
  # Validate that the PID is numeric before using it
  if ! echo "$LOCK_PID" | grep -qE '^[0-9]+$'; then
    # Invalid / unreadable lock format — safe to remove
    rm -f "$MCP_LOCK"
    echo MCP_LOCK_INVALID_FORMAT_REMOVED
  elif kill -0 "$LOCK_PID" 2>/dev/null; then
    # PID is live — do not remove
    echo MCP_LOCK_HELD_BY_LIVE_PROCESS
  else
    # PID is gone — re-read to guard against a new process taking the lock
    # between the kill -0 check and the rm
    CURRENT_LOCK=$(cat "$MCP_LOCK" 2>/dev/null)
    if [ "$LOCK_CONTENT" = "$CURRENT_LOCK" ]; then
      rm -f "$MCP_LOCK"
      echo MCP_LOCK_STALE_REMOVED
    else
      # Lock was replaced by a new owner between our check and now — abort
      echo MCP_LOCK_CHANGED_DURING_CHECK_RETRY
    fi
  fi
fi
```

A stale lock will block subsequent VE tasks — always clean it up after an abnormal termination.

---

## Stable State Detection

After every `browser_navigate` or significant action, confirm the page is stable
before proceeding. Do NOT assume stability — always verify.

**Step 1**: call `browser_snapshot` and inspect the accessibility tree.

**Step 2**: check for loading indicators:
- Any element with `aria-busy="true"`
- Any element whose visible text matches: `loading`, `cargando`, `spinner`, `please wait`
- Any skeleton element (role=`presentation` with no meaningful children)

**Step 3**:
```
No loading indicators found
  └── Page is stable — proceed

Loading indicators found
  └── Wait 1000ms
  └── Call browser_snapshot again
  └── If still loading → emit VERIFICATION_FAIL
        actual: page not stable after 1000ms retry
        diagnosis: slow render, failed data fetch, or infinite loading state
  └── If stable → proceed
```

**Rule**: one retry maximum. If the page is still loading after the retry, treat
it as a failure — do not keep waiting silently.

---

## Auth Flow

Read `authMode` from `.ralph-state.json → playwrightEnv`. Then follow the
matching pattern. Credentials come exclusively from environment variables —
never from state files or hardcoded strings.

### `none`
No auth step needed. Navigate directly to `appUrl`.

### `form`
1. Navigate to `loginUrl` (or `appUrl` if not set)
2. `browser_snapshot` → locate username and password fields using `browser_generate_locator`
3. **CAPTCHA / 2FA check**: before filling credentials, scan the snapshot for:
   - CAPTCHA elements: `role=img` or visible text matching `captcha`, `I'm not a robot`, `verify you are human`
   - 2FA / MFA fields: visible text matching `verification code`, `authenticator`, `one-time password`, `OTP`, `2FA`
   - If found → emit `ESCALATE` immediately:
     ```
     ESCALATE
       reason: login form requires CAPTCHA or 2FA
       detected: <element description from snapshot>
       resolution: use authMode=storage-state with a pre-authenticated session,
                   or disable CAPTCHA/2FA in the test environment
     ```
4. Fill credentials from env vars (`RALPH_LOGIN_USER`, `RALPH_LOGIN_PASS`)
5. Submit the form
6. `browser_snapshot` + stable state check → confirm authenticated state (absence of login form, presence of authenticated UI)
7. If auth fails → emit `VERIFICATION_FAIL` with diagnosis, do not proceed

### `token`

Token injection requires knowing **how** the app consumes the token. This must
be documented in `playwright-env.local.md` as `tokenBootstrapRule`. Three
standard patterns:

**Pattern A — localStorage** (most common for JWT / SPA apps):

⚠️ **Critical order**: `localStorage` is origin-scoped. Inject the token AFTER
navigating to the app URL — never before. Injecting on `about:blank` writes to
a different origin and the value will not be available when the app loads.

```
// Step 1: navigate to the app URL first to establish the correct origin
// (use MCP tool: browser_navigate with url=appUrl)
browser_navigate(appUrl)

// Step 2: inject the token safely — pass the token as a separate argument,
// never via string concatenation or template literals to avoid injection/syntax errors.
// The controller reads RALPH_AUTH_TOKEN from the environment and passes it as a
// parameter — the script body itself is a static string.
// (use MCP tool: browser_execute_script)
browser_execute_script(
  script: "localStorage.setItem(arguments[0], arguments[1])",
  args: [tokenLocalStorageKey, <value of RALPH_AUTH_TOKEN from env>]
)

// Step 3: reload so the app reads the token from localStorage on init
// (use MCP tool: browser_navigate to force reload)
browser_navigate(appUrl)
```

Then `browser_snapshot` + stable state check → confirm authenticated state.

**Pattern B — Authorization header** (for apps that read the header on every request):
```
// Set default headers on the browser context before navigating.
// The controller reads RALPH_AUTH_TOKEN from env and passes it as a parameter.
// (use MCP tool: browser_set_extra_http_headers or equivalent context setup)
browser_set_extra_http_headers(
  headers: { "Authorization": "Bearer <value of RALPH_AUTH_TOKEN from env>" }
)
browser_navigate(appUrl)
```
Then `browser_snapshot` → confirm authenticated state.

**Pattern C — Cookie fallback** (when the token is actually a session cookie value):
Use `cookie` authMode instead — see that section below.

**Rule**: if `playwright-env.local.md` does not specify `tokenBootstrapRule`,
emit `ESCALATE`:
```
ESCALATE
  reason: token auth mode requires tokenBootstrapRule
  resolution: add tokenBootstrapRule to playwright-env.local.md
              options: localStorage | authorization-header
              key name (for localStorage): add tokenLocalStorageKey — check app source for the localStorage key name
```

### `cookie`

⚠️ **Inject before any navigation.** Cookie injection must happen before
`browser_navigate` — injecting after navigation sets the cookie for future
requests but the current page load already happened without it.

1. Inject cookie from env vars (`RALPH_SESSION_COOKIE_NAME`, `RALPH_SESSION_COOKIE_VALUE`) into the browser context before navigating
2. Navigate to `appUrl`
3. `browser_snapshot` + stable state check → confirm authenticated state

### `basic`
1. Navigate to `appUrl` with Basic Auth credentials from env vars embedded in the request
2. `browser_snapshot` → confirm page loaded without 401

### `storage-state`

⚠️ **Load before any navigation.** The storage state (cookies + localStorage)
must be applied to the context before navigating — applying it after navigation
has no effect on the page already loaded.

1. Load browser state from `RALPH_STORAGE_STATE_PATH` when creating the context — before any `browser_navigate`
2. Navigate to `appUrl`
3. `browser_snapshot` + stable state check → confirm authenticated state (session may have expired — treat expired session as `VERIFICATION_FAIL`)

### `oauth` / `sso`
Agent cannot complete external IdP flows or MFA autonomously.
Emit `ESCALATE` unless a valid `storage-state` has been prepared:

```
ESCALATE
  reason: oauth/sso auth requires pre-authenticated session
  resolution: set authMode=storage-state and provide RALPH_STORAGE_STATE_PATH
```

---

## Context Isolation Rules

| Scenario | Rule |
|---|---|
| Sub-steps within a single VE task | Reuse the same context — do not re-authenticate between steps of the same task |
| Independent user flows (e.g., logged-in vs logged-out) | Use `isolated=true` (default) — each session starts with a fresh ephemeral profile. If the server is running with `isolated=false` and full state isolation is needed, emit `ESCALATE` asking the human to restart the MCP server with `--isolated` |
| Parallel VE tasks | Never share context across tasks — one session per task |

> **Between VE tasks**: always follow Session End before starting the next VE task.
> `spec-executor.md` is the authority on inter-task session policy.

---

## State Persistence

Reuse the authenticated session within a spec rather than re-authenticating per sub-step:
1. Complete auth flow once at session start
2. `browser_snapshot` + stable state check to confirm auth state before proceeding to first VE task
3. If auth expires mid-flow, treat as `VERIFICATION_FAIL` (unexpected state) and run diagnostic
4. Do NOT re-authenticate silently — surface the expiry in the failure report

---

## Navigation Anti-Patterns (MANDATORY for all VE tasks)

<mandatory>
### NEVER use `page.goto()` for internal app routes

For single-page applications and platforms with client-side routing (e.g., Home Assistant, React apps, Angular apps), using `page.goto('/some/internal/route')` bypasses the app's routing and auth state management. This causes:
- **Auth failures**: the app expects session state established during initial load
- **404/blank pages**: client-side routes are not directly addressable via server requests
- **TimeoutErrors**: the page loads but never reaches the expected state

**✅ CORRECT — navigate via UI elements:**
```typescript
// Navigate using sidebar/menu clicks
await page.locator('[data-panel-id="config"]').click();
await page.waitForSelector('ha-config-dashboard', { state: 'visible', timeout: 15000 });
```

**❌ WRONG — direct URL navigation to internal routes:**
```typescript
// This bypasses client-side routing and auth state
await page.goto('/config/integrations');
await page.goto(baseUrl + '/config/integrations');
```

**Exception**: `page.goto()` to the **base URL** (app root) is correct for initial navigation and auth flows. Only internal sub-routes are problematic.

### NEVER use consumed OAuth/auth callback URLs

If the test infrastructure (e.g., `hass-taste-test`, auth setup scripts) returns a URL with `auth_callback`, `code=`, or `state=` parameters, these tokens are **already consumed** by the setup process. Navigating the browser to these URLs produces auth failures.

**✅ CORRECT — use the base URL (origin only):**
```typescript
const baseUrl = new URL(serverInfo.link).origin; // "http://127.0.0.1:8542"
await page.goto(baseUrl);
```

**❌ WRONG — use the full callback URL:**
```typescript
await page.goto(serverInfo.link); // "http://127.0.0.1:8542/?auth_callback=1&code=...&state=..."
```

### NEVER duplicate waitForURL calls
Each `waitForURL` should appear exactly once per expected navigation. Duplicating them is dead code and a sign of uncertainty — investigate the actual expected state instead.

### Platform-specific navigation patterns
For platform-specific navigation (Home Assistant sidebar, etc.), load the domain-specific selector map skill:
- **Home Assistant**: `skills/e2e/examples/homeassistant-selector-map.skill.md`
- The skill documents the exact selectors (`data-panel-id`) and patterns for safe navigation.
</mandatory>

---

## Unexpected Page Recovery

<mandatory>
After any navigation action (`browser_navigate`, click that triggers navigation, form submit), run this check BEFORE asserting anything:

### Step 1 — Snapshot and identify current page

Call `browser_snapshot` and inspect:
1. Current URL (from snapshot title or accessibility tree root)
2. Page title and visible H1

### Step 2 — Classify the page

| What you see | Classification | Action |
|---|---|---|
| Login form / `username` + `password` fields | **Auth redirect** | Run Step 3 |
| HTTP 404 / "Page not found" / blank page | **Bad URL** | Run Step 3 |
| Unexpected panel / wrong path in URL | **Wrong route** | Run Step 3 |
| Expected content | **OK** | Proceed normally |

### Step 3 — Diagnose BEFORE fixing

**Do NOT**:
- Assume the element you were looking for does not exist
- Simplify the test to avoid the problematic navigation
- Try harder on the wrong page

**DO**:
1. Identify which navigation step caused the unexpected landing:
   - Was `page.goto()` used on an internal route? → That is the bug. See Navigation Anti-Patterns above.
   - Was `auth_callback` URL used? → That is the bug. Use `new URL(url).origin` instead.
   - Was a UI element clicked that does not navigate to the right place?
2. Note the diagnosis in your output.

### Step 4 — Recover

1. Navigate back to the base URL: `browser_navigate(appUrl)` — use `appUrl` from `playwrightEnv`
2. Run Stable State Detection
3. Re-navigate using the **correct** UI path (sidebar click, menu click, etc.) per `ui-map.local.md`
4. If the recovery succeeds: continue the test from the correct page
5. If the recovery fails twice (still landing on unexpected page): emit `VERIFICATION_FAIL`:
   ```
   VERIFICATION_FAIL
     actual: unexpected page after navigation recovery
     expected: <expected route/panel>
     diagnosis: <root cause identified in Step 3>
     recovery_attempts: 2
   ```

### Golden rule

> The unexpected page is evidence that a **previous navigation step was wrong**.
> It is never evidence that the target element does not exist.
> Roll back, fix the navigation, then try again.
</mandatory>

---

## Cleanup Checklist

Before marking any VE task complete:

- [ ] `browser_close` called (or lock recovery run if close failed — see Session End above)
- [ ] If `browser_close` failed: stale lock removed after confirming PID is not live
- [ ] Session status written to `.ralph-state.json`
- [ ] Screenshots saved to `<basePath>/screenshots/` (create dir if absent)
- [ ] Signal emitted (`VERIFICATION_PASS`, `VERIFICATION_FAIL`, or `VERIFICATION_DEGRADED`)
