---
name: playwright-env
version: 2
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
4. `requirements.md → Verification Contract → Entry points` (URL fallback only)
5. `ESCALATE` — stop and ask the human

Write resolved non-secret values to `.ralph-state.json`:

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
  "timezone": "<resolved>"
}' <basePath>/.ralph-state.json > /tmp/state.json && mv /tmp/state.json <basePath>/.ralph-state.json
```

**Never write passwords, tokens, cookies, or any secret value to `.ralph-state.json`.**

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
# Both must be non-empty
[ -n "$RALPH_LOGIN_USER" ] && [ -n "$RALPH_LOGIN_PASS" ] || emit ESCALATE
```

### `token`
Agent injects an auth token (header or localStorage) to bootstrap authenticated state.
Required: `appUrl`, `RALPH_AUTH_TOKEN` value, documented bootstrap rule in `playwright-env.local.md`

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
External IdP flows that may involve MFA or redirect chains the agent cannot
complete autonomously. Agent must not guess around MFA or external redirects.

Resolution: use `storage-state` with a pre-authenticated session, or emit
`ESCALATE` so the human prepares the session manually.

---

## `playwright-env.local.md` Format

Create in `<basePath>/playwright-env.local.md` and add to `.gitignore`.
This file holds non-secret defaults and references to secret env vars.
**Never put actual passwords, tokens, or cookies in this file.**

```markdown
# Playwright Env — local config (gitignored, never commit)

appUrl: http://localhost:3000
appEnv: local
authMode: form
loginUrl: /login
userRole: admin

# References to env vars that hold the actual secrets:
loginUserVar: RALPH_LOGIN_USER
loginPassVar: RALPH_LOGIN_PASS

allowWrite: true
browser: chromium
headless: true
viewport: desktop
locale: es-ES
timezone: Europe/Madrid

# Optional seed command (runs before verification):
seedCommand: npm run seed:e2e

# Optional tenant / feature flags:
# tenant: acme-corp
# featureFlags: new-dashboard,beta-reports
```

---

## Connectivity Check (MANDATORY after appUrl is resolved)

Before writing `playwrightEnv` to state and before launching any browser tool,
verify the app is actually reachable:

```bash
curl -sf --max-time 5 "$RALPH_APP_URL" -o /dev/null \
  && echo APP_REACHABLE \
  || echo APP_NOT_REACHABLE
```

### Decision tree

```
APP_REACHABLE
  └── Proceed: write playwrightEnv to .ralph-state.json, continue to playwright-session

APP_NOT_REACHABLE
  └── Emit ESCALATE and stop:

ESCALATE
  reason: app-not-reachable
  url: <resolved appUrl>
  appEnv: <resolved appEnv>
  curl_exit: <exit code>
  diagnosis:
    - local: Is the dev server running? (npm run dev / docker compose up)
    - staging: Is the deployment healthy? Check CI/CD pipeline.
    - production: Is the service up? Check status page.
  resolution: Start the app, then re-run the VE task.
```

**Do not proceed to `playwright-session` if the app is not reachable.**
A browser timeout after 30s is a much worse failure signal than this explicit check.

---

## Safety Rules

- **`allowWrite` defaults to `false` for `staging` and `production`** unless explicitly set to `true` in env or local file.
- **`production` environment**: require explicit human confirmation before any action that could mutate data, even if `allowWrite=true`.
- **Never log or persist secrets** in progress files, state files, screenshots, commit messages, or VERIFICATION signals.
- **Seed command** runs only in `local` or `staging` environments. Never in `production`.
- **Feature flags** are informational — the agent notes them in the verification report but does not modify app config to enable them.

---

## Missing Context — ESCALATE

If any critical input cannot be resolved, emit and stop:

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

Stop before launching any browser tool when critical context is missing.

---

## Done When

- [ ] `appUrl` resolved
- [ ] Connectivity check passed (`APP_REACHABLE`) — see Connectivity Check section above
- [ ] `playwrightEnv` written to `.ralph-state.json` (non-secret fields only)
- [ ] `authMode` resolved
- [ ] Secret env vars referenced, not stored
- [ ] `allowWrite` posture confirmed
- [ ] Missing critical context results in `ESCALATE`, not improvisation
