---
name: playwright-session
version: 7
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

- One context per spec — do not share across different specs
- Always re-snapshot after any navigation or significant DOM mutation before continuing

### End (MANDATORY)

Always close the session, even if verification failed:

```
1. browser_close
2. Write session status to .ralph-state.json:
   jq '.lastPlaywrightSession = "closed"' <basePath>/.ralph-state.json > /tmp/state.json && mv /tmp/state.json <basePath>/.ralph-state.json
```

**If `browser_close` fails or the session terminated abnormally** (timeout, tool error, unexpected disconnect):

```bash
# The server process is managed by the human — do NOT pkill it.
# Only clean up the stale lock file so the next session can start cleanly.
# Only do this if browser_close failed — do not remove a lock owned by a live process.
MCP_LOCK="$HOME/.cache/ms-playwright/mcp-chrome/SingletonLock"
LOCK_PID=$(cat "$MCP_LOCK" 2>/dev/null | cut -d- -f1)
if [ -n "$LOCK_PID" ] && ! kill -0 "$LOCK_PID" 2>/dev/null; then
  rm -f "$MCP_LOCK"
  echo MCP_LOCK_STALE_REMOVED
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

```javascript
// Step 1: navigate to the app URL first to establish the correct origin
await page.goto(appUrl);
// Step 2: now inject the token into the correct origin's localStorage
await page.evaluate((token, key) => {
  localStorage.setItem(key, token);  // key = tokenLocalStorageKey from playwright-env.local.md
}, process.env.RALPH_AUTH_TOKEN, tokenLocalStorageKey);
// Step 3: reload so the app reads the token from localStorage on init
await page.reload();
```

Then `browser_snapshot` + stable state check → confirm authenticated state.

**Pattern B — Authorization header** (for apps that read the header on every request):
```javascript
// Set default headers on the browser context before navigating
await context.setExtraHTTPHeaders({
  Authorization: `Bearer ${process.env.RALPH_AUTH_TOKEN}`
});
await page.goto(appUrl);
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
| Multiple VE tasks in same spec | Same context OK if flows are sequential and related |
| Independent user flows (e.g., logged-in vs logged-out) | Use `isolated=true` (default) — each session starts with a fresh ephemeral profile. If the server is running with `isolated=false` and full state isolation is needed, emit `ESCALATE` asking the human to restart the MCP server with `--isolated` |
| Parallel VE tasks | Never share context across tasks — one session per task |

---

## State Persistence

Reuse the authenticated session within a spec rather than re-authenticating per sub-step:
1. Complete auth flow once at session start
2. `browser_snapshot` + stable state check to confirm auth state before proceeding to first VE task
3. If auth expires mid-flow, treat as `VERIFICATION_FAIL` (unexpected state) and run diagnostic
4. Do NOT re-authenticate silently — surface the expiry in the failure report

---

## Cleanup Checklist

Before marking any VE task complete:

- [ ] `browser_close` called (or lock recovery run if close failed — see Session End above)
- [ ] If `browser_close` failed: stale lock removed after confirming PID is not live
- [ ] Session status written to `.ralph-state.json`
- [ ] Screenshots saved to `<basePath>/screenshots/` (create dir if absent)
- [ ] Signal emitted (`VERIFICATION_PASS`, `VERIFICATION_FAIL`, or `VERIFICATION_DEGRADED`)
