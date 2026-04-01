---
name: ui-map-init
version: 2
description: Load this skill to build the ui-map.local.md selector map before running Playwright tests. Explores the running app, catalogs stable selectors, and writes the map file.
agents: [spec-executor, qa-engineer]
---

# UI Map Init Skill

This skill builds `ui-map.local.md` — a catalog of stable, verified selectors for the running app. Every Playwright VE task references this map instead of guessing selectors.

---

## When to Run

Run once per spec, as task `VE0`, immediately before the first Playwright VE task. Skip if `ui-map.local.md` already exists at `basePath`.

```bash
[ -f <basePath>/ui-map.local.md ] && echo EXISTS_SKIP || echo NEEDS_INIT
```

---

## Step -1: Resolve Environment Context (MANDATORY FIRST)

Before anything else, load `playwright-env.skill.md` to resolve the browser
execution context.

```
Load: playwright-env.skill.md
```

`playwright-env` will resolve `appUrl`, validate connectivity, run seedCommand
if configured, and write `playwrightEnv` to `.ralph-state.json`.

**Do not proceed to Step 0 if `playwright-env` emits `ESCALATE`.**

This step is identical to Step -1 in `mcp-playwright.skill.md`. If both skills
are loaded in the same VE session, `playwright-env` only needs to run once —
check `.ralph-state.json → playwrightEnv` before re-running.

```bash
jq -r '.playwrightEnv.appUrl // empty' <basePath>/.ralph-state.json
# If non-empty: playwrightEnv already resolved, skip Step -1
# If empty: run playwright-env now
```

---

## Step 0: Dependency Check

After environment context is resolved, verify MCP Playwright is available (read from `.ralph-state.json`):

```bash
jq -r '.mcpPlaywright' <basePath>/.ralph-state.json
```

- `available` → proceed with MCP exploration (Step 1A)
- `missing` → proceed with static exploration (Step 1B)
- key absent → run dependency check from `mcp-playwright.skill.md` Step 0, then re-read

---

## Step 1A: MCP Exploration (Preferred)

1. Navigate to `appUrl` (from `.ralph-state.json → playwrightEnv.appUrl`)
2. `browser_snapshot` → read full accessibility tree
3. For each significant UI region (nav, main, forms, modals, CTAs):
   - `browser_generate_locator` for key interactive elements
   - Record: element type, generated locator, visible text/label, region
4. Navigate to each main route (if discoverable from nav)
5. Repeat snapshot + locator generation per route
6. Write `ui-map.local.md` (see Output Format)

---

## Step 1B: Static Exploration (Degraded)

When MCP is not available:

1. Search source for `data-testid`, `aria-label`, `role`, `id` attributes in templates/JSX/HTML
2. Search for route definitions
3. Build best-effort selector map from source
4. Mark all entries as `source: static` in the map
5. Write `ui-map.local.md` with degradation note

---

## Output Format: ui-map.local.md

```markdown
# UI Map — <spec name>

Generated: <timestamp>
Source: mcp | static
App URL: <base URL>

## Routes

| Route | Description |
|---|---|
| / | Home / landing |
| /login | Auth entry point |

## Selectors

| Region | Element | Locator | Label / Text | Source |
|---|---|---|---|---|
| nav | Logo link | <generated locator> | Home | mcp |
| nav | Login button | <generated locator> | Log in | mcp |
| main | CTA button | <generated locator> | Get started | mcp |
| login form | Email input | <generated locator> | Email | mcp |
| login form | Submit | <generated locator> | Sign in | mcp |

## Notes

- <any anomalies found during exploration>
- <elements with unstable or missing locators>
```

---

## Rules

- **Never hardcode selectors in VE tasks.** Reference `ui-map.local.md` entries by label.
- If a locator in the map becomes stale (element moved/renamed), re-run `ui-map-init` for that route.
- Static-source entries are lower confidence — flag them in verification reports.
- `ui-map.local.md` is a local artifact (`.gitignore` it) — it describes the running instance, not the source of truth.
