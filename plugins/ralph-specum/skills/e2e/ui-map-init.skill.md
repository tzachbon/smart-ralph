---
name: ui-map-init
version: 5
description: VE0 skill — builds the selector map for the app before VE1+ tasks run. Opens its own browser session (does not reuse any prior session), explores the app, writes ui-map.local.md, then follows playwright-session Session End.
agents: [spec-executor, qa-engineer]
---

# UI Map Init Skill (VE0)

This skill explores the app and builds a stable selector map (`ui-map.local.md`)
before any VE1+ verification task runs. It is always the first VE task in a
fullstack or frontend spec.

> **Session ownership**: ui-map-init opens its **own** browser session. It does
> not reuse any existing session. When exploration is complete, it **must**
> follow `playwright-session.skill.md → Session End` to close the session and
> write the session status to state.

**Prerequisites** (already loaded by spec-executor before this skill):
- `playwright-env.skill.md` — `playwrightEnv` written to state
- `mcp-playwright.skill.md` — `mcpPlaywright` written to state
- `playwright-session.skill.md` — session lifecycle rules in context

---

## When to Run

Run VE0 (this skill) when:
- `ui-map.local.md` does not exist in `<basePath>`
- OR `ui-map.local.md` exists but is marked `stale: true`
- OR the task list explicitly includes a `VE0` task

Skip VE0 (reuse existing map) when:
- `ui-map.local.md` exists, is not stale, and no structural UI changes have been made since it was generated

### Staleness Triggers

Mark `stale: true` in `ui-map.local.md` (or request a VE0 re-run) when **any**
of the following occur:

| Trigger | Why it invalidates the map |
|---|---|
| Client-side routing changes (new route, renamed path, removed route) | Selectors are keyed to routes; a changed route yields a different element tree |
| Component restructuring (element moved, wrapper added/removed) | `browser_generate_locator` output is DOM-tree-relative; structural changes break it |
| `data-testid` rename or removal | Any selector referencing the old id immediately becomes `confidence: broken` |
| Major `authMode` change (e.g. `none` → `form`) | Explored routes were reached without auth; re-exploring them after auth may reveal different elements |

**Rule**: if a staleness trigger fires **before** VE1+ tasks run, `spec-executor`
must insert (or re-enable) the VE0 task and run it before any downstream VE task.
A `FINDING` note is not enough — a stale map produces unreliable selectors that
silently corrupt subsequent VE tasks.

---

## Step 0 — Pre-flight

1. **Check state file exists**: read `.ralph-state.json` from `<basePath>`. If the file
   is missing, emit `ESCALATE` and stop:
    ```text
    ESCALATE
       reason: state-file-missing
       resolution: playwright-env.skill.md must run first to create .ralph-state.json
    ```
2. **Read `mcpPlaywright`** from `.ralph-state.json`:
   - Value `"available"` → proceed with MCP exploration (Step 1A)
   - Value `"missing"` or key absent → switch to degraded mode: write a minimal
     placeholder `ui-map.local.md` (source: static, all selectors confidence: low)
     and emit `VERIFICATION_DEGRADED` with `reason: mcp-playwright-missing`
3. **Read `playwrightEnv.appUrl`** from `.ralph-state.json`. If `playwrightEnv`
   object is absent or `appUrl` is empty/missing, emit `ESCALATE` and stop:
    ```text
    ESCALATE
       reason: playwright-env-incomplete
       resolution: playwright-env.skill.md must complete before ui-map-init;
                         ensure RALPH_APP_URL is set and playwright-env resolves successfully
    ```

---

## Step 1A — MCP Exploration (preferred)

Use browser tools to explore the live app.

> ⚠️ **Protected routes require auth first.** Navigating to a protected route
> before completing the auth flow will land the browser on the login page —
> producing a selector map for the login UI, not the target page. Always
> complete the auth flow (Step 1A-auth below) before exploring any protected
> route. Public routes (e.g. landing, `/login` itself) can be explored before
> auth.

### Step 1A-auth — Complete Auth Flow First

1. Follow `playwright-session.skill.md → Session Lifecycle → Start` to open a
   browser session **and complete the auth flow** according to `authMode` before
   navigating to any exploration target.
   - **On auth failure** (wrong credentials, auth service unreachable): emit
     `VERIFICATION_FAIL` with `reason: session-start-failed-auth` and include
     the error details from the playwright-session error. Follow
     `playwright-session.skill.md → Session End` before stopping. Do NOT write
     a partial `ui-map.local.md`.
   - **On app unreachable or browser crash / MCP error** (connection refused,
     timeout, tool error): follow Step 1B (static mode) instead and emit
     `VERIFICATION_DEGRADED` with `reason: session-start-failed-connectivity`.
     Ensure Session End still writes `lastPlaywrightSession = "closed"` to state
     after any error that left a session open.
2. After `Session Start`, call `browser_snapshot` + stable state check to confirm
   the authenticated state. If auth fails:
   - Emit `VERIFICATION_FAIL` (not `VERIFICATION_DEGRADED`) — a broken auth
     during VE0 makes the entire selector map unreliable for downstream tasks.
   - Follow `playwright-session.skill.md → Session End` before stopping.
   - Do NOT write a partial `ui-map.local.md` — a partial map is worse than
     no map because downstream tasks will silently use broken selectors.

### Step 1A-explore — Explore Entry Points

3. For each entry point in `requirements.md → Verification Contract → Entry points`:
   a. Classify the route as **public** (accessible without auth) or **protected** (requires auth)
   b. `browser_navigate` to the route
   c. `browser_snapshot` + stable state check — if the page is the login form
      (detected by the presence of username/password fields in the snapshot),
      treat as auth-expired: emit `VERIFICATION_FAIL` and stop.
   d. `browser_snapshot` → extract interactive elements (buttons, inputs, links, forms)
   e. `browser_generate_locator` for each key element → record selector
   f. `browser_take_screenshot` → save to `<basePath>/screenshots/ve0-<route-slug>.png`
      - Public routes: `ve0-public-<route-slug>.png`
      - Protected routes: `ve0-auth-<route-slug>.png`
4. Follow `playwright-session.skill.md → Session End` — close the session and
   write `lastPlaywrightSession = "closed"` to state before proceeding to Step 2.

---

## Step 1B — Static Fallback

If MCP exploration fails (browser unavailable, app unreachable after retry):

1. Read component files from the codebase to infer selectors statically
2. Mark all selectors as `confidence: low` in the output
3. Emit `VERIFICATION_DEGRADED` with reason: `mcp-exploration-failed`

---

## Step 2 — Write `ui-map.local.md`

Write to `<basePath>/ui-map.local.md`:

```markdown
# UI Map — <specName>
<!-- generated: <ISO timestamp> -->
<!-- source: mcp | static -->
<!-- stale: false -->

## Routes Explored
- <route>: <page title or description> [public | protected]

## Selectors

### <route>
| Element | Role | Selector | Confidence |
|---|---|---|---|
| <label> | <button/input/link/...> | <selector string> | high/medium/low |
```

Rules:
- One section per explored route
- Annotate each route as `[public]` or `[protected]` in the Routes Explored list
- `confidence: high` = verified via `browser_generate_locator` on live element
- `confidence: medium` = inferred from snapshot but not directly generated
- `confidence: low` = static analysis only (Step 1B fallback)
- Mark `stale: true` if Step 1B was used

---

## Incremental Update

`ui-map.local.md` grows over time. **Never regenerate the full map** unless
`stale: true` or the user explicitly requests a full reset. Instead, patch
only the affected routes.

### Who updates the map

| Agent | When | What to add |
|---|---|---|
| **qa-engineer** | After browser exploration in a [VERIFY] task | New selectors discovered on live app |
| **spec-executor** | After implementing a task that adds `data-testid` to the code | The new testid + route |
| **ui-map-init (VE0)** | Full generation (first run or stale reset) | All routes in Verification Contract |

### Update protocol (incremental)

1. Read current `ui-map.local.md`
2. For each new selector to add:
   - If the route section already exists → append a new row to its table
   - If the route section does not exist → append a new `### <route>` section
3. Update the `<!-- generated: -->` comment to current ISO timestamp
4. Do **not** remove or modify existing rows unless a selector is confirmed broken
5. Never mark `stale: true` during an incremental update — only do so when a
   structural UI change (see Staleness Triggers above) makes existing selectors unreliable

### Broken selector protocol

If during a [VERIFY] task a selector from the map fails to locate the element:
1. Mark the row as `confidence: broken` and add a `<!-- broken: <ISO date> -->` note
2. Attempt `browser_generate_locator` to find the replacement
3. If found: add new row with `confidence: high`, keep broken row for reference
4. If not found: leave broken row marked, emit `FINDING` in the verification output

Never silently remove a broken selector — broken rows are diagnostically valuable.

---

## Done When

- [ ] `ui-map.local.md` written to `<basePath>`
- [ ] Each explored route annotated as `[public]` or `[protected]`
- [ ] Screenshots saved to `<basePath>/screenshots/ve0-*.png`
  - Public routes: `ve0-public-<route-slug>.png`
  - Protected routes: `ve0-auth-<route-slug>.png`
- [ ] Browser session closed (Session End followed)
- [ ] `lastPlaywrightSession = "closed"` written to state
- [ ] Signal emitted: `VERIFICATION_PASS` (full map), `VERIFICATION_FAIL`
  (auth failed during exploration), or `VERIFICATION_DEGRADED` (static fallback/MCP unavailable)
