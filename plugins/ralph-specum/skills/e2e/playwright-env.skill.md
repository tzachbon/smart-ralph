---
name: playwright-env
version: 7
description: Load this skill before any MCP Playwright session. Resolves browser execution context — app URL, auth mode, credentials references, seed data, browser config, and safety limits. Emits ESCALATE if critical context is missing or app is unreachable.
agents: [spec-executor, qa-engineer]
---

# Playwright Environment Skill

This skill resolves the **browser execution context** before any MCP Playwright
interaction. It must be loaded before `playwright-session` and before any
browser tool call.

This skill does **not** store secrets. It resolves non-secret settings and
validates that secret environment variables are exported and readable.

---

## Resolution Order

Resolve each setting in this order, stopping at the first source that provides
a value:

1. Shell environment variable (e.g. `RALPH_APP_URL`)
2. `playwright-env.local.md` in `<basePath>` (gitignored, never committed)
3. Non-secret values already written in `.ralph-state.json → playwrightEnv`
   ⚠️ **State fallback warning**: values from `.ralph-state.json` may be stale
   from a previous session. **Always check the `resolvedAt` timestamp**:
   - If `resolvedAt` is older than ~2 hours, treat as low-confidence and prefer sources 1–2.
   - If `resolvedAt` is missing entirely, discard the cached block and re-resolve from sources 1–2.
   - Never rely on state-file values for security-sensitive settings
     (`authMode`, `tokenBootstrapRule`). Those must always come from sources 1–2.
   ⚠️ **Circular fallback prevention**: if sources 1 and 2 are both absent and
   source 3 is the only available value, emit a warning before using it:
   ```
   WARNING: playwright-env resolved from state cache only (no env vars, no local md).
   resolvedAt: <timestamp>. Values may be stale. Proceeding with low confidence.
   ```
   This prevents a silent feedback loop where stale state values are treated as
   authoritative across multiple task invocations.
4. `requirements.md → Verification Contract → Entry points` (URL fallback only)
5. `ESCALATE` — stop and ask the human

---

## Settings Reference

### Core

| Setting | Env var | Default | Notes |
|---|---|---|---|
| App URL | `RALPH_APP_URL` | — | **Required. No default.** |
| App environment | `RALPH_APP_ENV` | `local` | `local`, `staging`, `production` |
| Allow writes | `RALPH_ALLOW_WRITE` | `false` (staging/prod) / `true` (local) | Override explicitly for non-local |
| Browser | `RALPH_BROWSER` | `chromium` | `chromium`, `firefox`, `webkit` |
| Headless | `RALPH_HEADLESS` | `true` | Set `false` for local debug |
| Viewport | `RALPH_VIEWPORT` | `desktop` | `desktop`, `tablet`, `mobile`, or `1280x800` |
| Locale | `RALPH_LOCALE` | `en-US` | Affects date formats, text content assertions |
| Timezone | `RALPH_TIMEZONE` | `UTC` | Affects time-sensitive assertions |
| Isolated mode | `RALPH_PLAYWRIGHT_ISOLATED` | `true` | Launches MCP with `--isolated` flag (ephemeral profile, no disk cache). Set `false` only when auth persistence between steps is required and you explicitly manage the user-data-dir. |

### Authentication

| Setting | Env var | Notes |
|---|---|---|
| Auth mode | `RALPH_AUTH_MODE` | `none`, `form`, `token`, `cookie`, `oauth`, `basic`, `storage-state` |
| Login URL | `RALPH_LOGIN_URL` | Optional. Defaults to `appUrl` if not set |
| Username / email | `RALPH_LOGIN_USER` | Used by `form` and `basic` modes |
| Password | `RALPH_LOGIN_PASS` | Used by `form` and `basic` modes |
| Auth token | `RALPH_AUTH_TOKEN` | Used by `token` mode |
| Session cookie name | `RALPH_SESSION_COOKIE_NAME` | Used by `cookie` mode |
| Session cookie value | `RALPH_SESSION_COOKIE_VALUE` | Used by `cookie` mode |
| Storage state path | `RALPH_STORAGE_STATE_PATH` | Used by `storage-state` mode. Must be a readable local file |
| Test user role | `RALPH_USER_ROLE` | Optional. `admin`, `editor`, `viewer`, etc. Documents intent |
| Token bootstrap rule | `tokenBootstrapRule` | Required for `token` mode. `localStorage` or `authorization-header`. Set in `playwright-env.local.md`. |
| Token localStorage key | `tokenLocalStorageKey` | Required when `tokenBootstrapRule=localStorage`. The exact key the app uses to store the token in `localStorage` (check app source). Set in `playwright-env.local.md`. |

### App state / seed

| Setting | Env var | Notes |
|---|---|---|
| Seed command | `RALPH_SEED_COMMAND` | Optional shell command to prepare app state before verification |
| Tenant / workspace | `RALPH_TENANT` | Optional. For multi-tenant apps |
| Feature flags | `RALPH_FEATURE_FLAGS` | Optional. Comma-separated list of flags to enable |

---

## Auth Mode Rules

### `none`
No credentials needed. Use for public UIs or auth-disabled dev environments.
Required: `appUrl`

### `form`
Agent completes a login form in the browser.
Required: `appUrl`, `RALPH_LOGIN_USER` value, `RALPH_LOGIN_PASS` value
Optional: `RALPH_LOGIN_URL` (separate login URL)

Resolution check:
```bash
[ -n "$RALPH_LOGIN_USER" ] && [ -n "$RALPH_LOGIN_PASS" ] || emit ESCALATE
```

### `token`
Agent injects an auth token to bootstrap authenticated state.
Required: `appUrl`, `RALPH_AUTH_TOKEN` value, `tokenBootstrapRule` in `playwright-env.local.md`
See `playwright-session.skill.md → Auth Flow → token` for the 3 injection patterns.

### `cookie`
Agent injects a pre-issued session cookie directly into the browser context.
Required: `appUrl`, `RALPH_SESSION_COOKIE_NAME`, `RALPH_SESSION_COOKIE_VALUE`

### `basic`
HTTP Basic Auth via URL or Authorization header.
Required: `appUrl`, `RALPH_LOGIN_USER`, `RALPH_LOGIN_PASS`

### `storage-state`
Agent loads a pre-authenticated browser state from a local file.
Required: `appUrl`, `RALPH_STORAGE_STATE_PATH` pointing to a readable JSON file

Resolution check:
```bash
[ -f "$RALPH_STORAGE_STATE_PATH" ] || emit ESCALATE
```

### `oauth` / `sso`
External IdP flows the agent cannot complete autonomously.
Resolution: use `storage-state` with a pre-authenticated session, or emit `ESCALATE`.

---

## Connectivity Check (MANDATORY — step 1 after appUrl resolved)

Before running the seed command or writing state, verify the app is reachable:

```bash
curl -sf --max-time 5 "$RALPH_APP_URL" -o /dev/null \
  && echo APP_REACHABLE \
  || echo APP_NOT_REACHABLE
```

```
APP_REACHABLE     → proceed to Seed Command step
APP_NOT_REACHABLE → emit ESCALATE and stop:

ESCALATE
  reason: app-not-reachable
  url: <resolved appUrl>
  appEnv: <resolved appEnv>
  diagnosis:
    - local: Is the dev server running? (npm run dev / docker compose up)
    - staging: Is the deployment healthy? Check CI/CD pipeline.
    - production: Is the service up? Check status page.
  resolution: Start the app, then re-run the VE task.
```

---

## Seed Command (MANDATORY order — step 2, after connectivity check)

If `RALPH_SEED_COMMAND` or `seedCommand` in `playwright-env.local.md` is set:

```
appEnv = local OR staging  → run seed command
appEnv = production        → SKIP — never seed production
```

```bash
# Always run via eval to correctly handle commands with arguments or spaces
# (e.g. "npm run seed:e2e -- --env=staging" would break without eval)
eval "$RALPH_SEED_COMMAND" && echo SEED_OK || echo SEED_FAILED
```

```
SEED_OK     → proceed to write playwrightEnv to state
SEED_FAILED → emit ESCALATE and stop:

ESCALATE
  reason: seed-command-failed
  command: <RALPH_SEED_COMMAND value>
  resolution: Fix the seed command, then re-run the VE task.
```

**Why this order matters**: the seed command prepares the app state (database
records, fixtures, feature flags). Running it after the browser is open, or
skipping it entirely, produces incorrect test state.

---

## Write State

Only after connectivity check passes and seed command succeeds (if set):

```bash
jq '.playwrightEnv = {
  "appUrl": "<resolved>",
  "appEnv": "<resolved>",
  "authMode": "<resolved>",
  "allowWrite": <true|false>,
  "browser": "<resolved>",
  "headless": <true|false>,
  "viewport": "<resolved>",
  "locale": "<resolved>",
  "timezone": "<resolved>",
  "isolated": <true|false>,
  "resolvedAt": "<ISO 8601 timestamp — e.g. 2026-04-01T14:30:00Z>"
}' <basePath>/.ralph-state.json > /tmp/state.json && mv /tmp/state.json <basePath>/.ralph-state.json
```

**Never write passwords, tokens, cookies, or any secret value to `.ralph-state.json`.**

---

## `playwright-env.local.md` Format

Create in `<basePath>/playwright-env.local.md` and add to `.gitignore`.
**Never put actual passwords, tokens, or cookies in this file.**

```markdown
# Playwright Env — local config (gitignored, never commit)

appUrl: http://localhost:3000
appEnv: local
authMode: form
loginUrl: /login
userRole: admin

loginUserVar: RALPH_LOGIN_USER
loginPassVar: RALPH_LOGIN_PASS

# For token mode — required if authMode is token:
# tokenBootstrapRule: localStorage        # or: authorization-header
# tokenLocalStorageKey: auth_token        # exact key the app uses in localStorage (check app source)

# Isolated mode (default: true)
# isolated: true    # ephemeral browser profile, no disk cache between sessions (recommended)
# isolated: false   # persistent profile — only use when you need cross-step auth persistence

allowWrite: true
browser: chromium
headless: true
viewport: desktop
locale: es-ES
timezone: Europe/Madrid

# seedCommand: npm run seed:e2e
# tenant: acme-corp
# featureFlags: new-dashboard,beta-reports
```

---

## Safety Rules

- **`allowWrite` defaults to `false` for `staging` and `production`** unless explicitly overridden.
- **`production` environment**: require explicit human confirmation before any mutating action, even if `allowWrite=true`.
- **Never log or persist secrets** in progress files, state files, screenshots, commit messages, or VERIFICATION signals.
- **Seed command** runs only in `local` or `staging`. Never in `production`.
- **Feature flags** are informational — agent notes them but does not modify app config.
- **`isolated` defaults to `true`**. The persistent `mcp-chrome` profile accumulates HTTP disk cache across sessions, which can cause stale-cache test contamination. Use `isolated: false` only when you explicitly need auth state to persist between separate VE tasks, and you manage cleanup manually.

---

## Missing Context — ESCALATE

```
ESCALATE
  reason: browser verification context incomplete
  missing:
    - appUrl        (RALPH_APP_URL not set, not in playwright-env.local.md, not in requirements.md)
    - credentials   (RALPH_LOGIN_USER / RALPH_LOGIN_PASS not exported)
    - storage-state (RALPH_STORAGE_STATE_PATH file not found)
  required_for: [AC-x.y, AC-x.z]
  resolution:
    1. Create <basePath>/playwright-env.local.md (see playwright-env.local.md.example)
    2. Export missing env vars in your shell before re-running
    3. For oauth/sso: prepare a storage-state file with RALPH_STORAGE_STATE_PATH
```

---

## Done When

- [ ] `appUrl` resolved
- [ ] Connectivity check passed (APP_REACHABLE)
- [ ] Seed command ran and succeeded — or skipped (not configured / production)
- [ ] `playwrightEnv` written to `.ralph-state.json` (non-secret fields only, including `resolvedAt`)
- [ ] `resolvedAt` freshness verified when source 3 (state cache) was used — stale
  values (>2 hours) must trigger re-resolution from sources 1–2, not silent reuse
- [ ] `authMode` resolved
- [ ] `isolated` setting resolved and written to state
- [ ] `tokenBootstrapRule` documented in `playwright-env.local.md` if `authMode=token`
- [ ] `tokenLocalStorageKey` documented in `playwright-env.local.md` if `tokenBootstrapRule=localStorage`
- [ ] Secret env vars referenced, not stored
- [ ] `allowWrite` posture confirmed
- [ ] Missing critical context results in `ESCALATE`, not improvisation
