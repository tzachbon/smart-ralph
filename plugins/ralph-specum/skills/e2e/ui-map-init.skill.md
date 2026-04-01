---
name: ui-map-init
version: 4
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

---

## Step 0 — Pre-flight

1. Read `mcpPlaywright` from `.ralph-state.json` — if `missing`, switch to degraded mode (no browser exploration; write a minimal placeholder `ui-map.local.md` and emit `VERIFICATION_DEGRADED`)
2. Read `playwrightEnv.appUrl` from `.ralph-state.json`

---

## Step 1A — MCP Exploration (preferred)

Use browser tools to explore the live app:

1. Follow `playwright-session.skill.md → Session Lifecycle → Start` to open a
   browser session. This includes completing the auth flow according to `authMode`
   before navigating to exploration targets.
2. For each entry point in `requirements.md → Verification Contract → Entry points`:
   a. `browser_navigate` to the route
   b. `browser_snapshot` → extract interactive elements (buttons, inputs, links, forms)
   c. `browser_generate_locator` for each key element → record selector
   d. `browser_take_screenshot` → save to `<basePath>/screenshots/ve0-<route>.png`
3. Follow `playwright-session.skill.md → Session End` — close the session and
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
- <route>: <page title or description>

## Selectors

### <route>
| Element | Role | Selector | Confidence |
|---|---|---|---|
| <label> | <button/input/link/...> | <selector string> | high/medium/low |
```

Rules:
- One section per explored route
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
   structural UI change makes existing selectors unreliable

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
- [ ] Screenshots saved to `<basePath>/screenshots/ve0-*.png`
- [ ] Browser session closed (Session End followed)
- [ ] `lastPlaywrightSession = "closed"` written to state
- [ ] Signal emitted: `VERIFICATION_PASS` (full map) or `VERIFICATION_DEGRADED` (fallback/partial)
