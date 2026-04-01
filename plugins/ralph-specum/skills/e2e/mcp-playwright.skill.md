---
name: mcp-playwright
version: 3
description: Load this skill when you need to verify UI features using MCP Playwright browser tools. Covers browser verification protocol, tool selection, dependency check, degradation strategy, and signal emission.
agents: [spec-executor, qa-engineer]
---

# MCP Playwright Verification Skill

This skill defines the **exact protocol** for browser-based verification using `@playwright/mcp`. It is not a wrapper of the README — it is a decision tree that tells you what to do, in what order, with what evidence, for every verification scenario.

---

## Step -1: Resolve Environment Context (MANDATORY FIRST)

Before the dependency check, resolve the browser execution context by loading
`playwright-env.skill.md`.

```
Load: playwright-env.skill.md
```

`playwright-env` will:
- Resolve `appUrl`, `authMode`, `allowWrite`, browser config, locale, timezone
- Validate that secret env vars are exported and readable
- Run seed command if configured (local/staging only)
- Check app connectivity before writing state
- Write non-secret resolved values to `.ralph-state.json → playwrightEnv`
- Emit `ESCALATE` and stop if critical context is missing

**Do not proceed to Step 0 if `playwright-env` emits `ESCALATE`.**

If `playwright-env` was already run in this session (`.ralph-state.json → playwrightEnv.appUrl` is non-empty), skip re-running it.

---

## Step 0: Dependency Check (MANDATORY)

After environment context is resolved, verify MCP Playwright is available.

```bash
npx @playwright/mcp@latest --version 2>/dev/null && echo MCP_PLAYWRIGHT_AVAILABLE || echo MCP_PLAYWRIGHT_MISSING
```

Write result to `.ralph-state.json`:

```bash
# If AVAILABLE:
jq '.mcpPlaywright = "available"' <basePath>/.ralph-state.json > /tmp/state.json && mv /tmp/state.json <basePath>/.ralph-state.json

# If MISSING:
jq '.mcpPlaywright = "missing"' <basePath>/.ralph-state.json > /tmp/state.json && mv /tmp/state.json <basePath>/.ralph-state.json
```

> ⚠️ **Parallel execution note**: these `jq` writes use a read-modify-write pattern
> via `/tmp/state.json`. If two VE tasks run in parallel against the same
> `basePath`, writes can interleave and corrupt `.ralph-state.json`. To avoid
> this, either (a) run VE tasks sequentially per basePath, or (b) use a
> basePath-scoped lock file (`.tasks.lock`, already in `.gitignore`) before
> each `jq` write. Parallel VE execution is not the default — flag this if
> you enable it.

### Decision tree after check

```
MCP_PLAYWRIGHT_AVAILABLE
  └── Follow Protocol A (Full MCP — this skill, sections below)

MCP_PLAYWRIGHT_MISSING
  ├── Spec has UI entry points?
  │     ├── YES → Follow Protocol B (Degraded) + emit ESCALATE
  │     └── NO  → Follow Protocol B (Degraded) silently, note in summary
  └── Write mcpPlaywright:missing to .ralph-state.json
```

---

## Protocol A: Full MCP Verification

### Tool Selection Rules

Never pick tools arbitrarily. Use this table:

| Situation | Tool to use | Why |
|---|---|---|
| Need to act on the page (click, fill, navigate) | `browser_snapshot` first, then action tool | Snapshot gives you the real accessibility tree to find elements |
| Need to assert element exists | `browser_snapshot` + inspect tree | More reliable than screenshot for assertions |
| Need to assert text is visible | `browser_snapshot` → search in tree | Screenshot cannot be parsed programmatically |
| Need evidence for a pass/fail report | `browser_take_screenshot` | Human-readable evidence only — never use for logic |
| Debugging a failed assertion | `browser_console_messages` + `browser_network_requests` + `browser_snapshot` | Triangulate: is it a JS error, a network failure, or a DOM issue? |
| Generating a stable locator | `browser_generate_locator` | Never hand-write selectors — generate from live page |
| Suspecting race condition or timing issue | `--caps=devtools` tracing (see Tracing section) | Devtools trace shows exact event timeline |

**Rule**: `browser_snapshot` is your primary tool for reading state. `browser_take_screenshot` is for evidence only — never use it to make decisions.

---

### Verification Sequence (Standard Flow)

For every user story or acceptance criterion with a UI entry point:

1. **Navigate** to the relevant URL via `browser_navigate`
2. **Stable state check** — see `playwright-session.skill.md → Stable State Detection`
3. **Snapshot** the page: `browser_snapshot` → read the accessibility tree
4. **Generate locator** for each element you need to interact with: `browser_generate_locator`
5. **Perform action** (click, fill, submit) using the generated locator
6. **Stable state check** again after action
7. **Snapshot again** → verify the DOM changed as expected
8. **Check network** if the action should trigger a request: `browser_network_requests`
9. **Check console** for errors: `browser_console_messages`
10. **Screenshot** as evidence: `browser_take_screenshot` — attach to verification report
11. **Emit signal**: `VERIFICATION_PASS` or `VERIFICATION_FAIL` (see Signal Format below)

---

### Multi-Step Flow Verification

When the spec involves a multi-step user flow (e.g., login → dashboard → action):

1. Execute each step in sequence — do NOT batch
2. After each step: stable state check + `browser_snapshot` to confirm state before proceeding
3. If a step produces an unexpected state, **stop and diagnose** (see Diagnostic Protocol below) before continuing
4. Emit one signal per logical flow, not per step

---

### Diagnostic Protocol (on unexpected state)

When a snapshot reveals unexpected state:

```
1. browser_console_messages  → Look for JS errors, unhandled rejections
2. browser_network_requests  → Look for failed requests (4xx, 5xx, timeouts)
3. browser_snapshot          → Re-read DOM to confirm state is stable
4. browser_take_screenshot   → Capture evidence
5. Emit VERIFICATION_FAIL with:
   - Expected state (from spec)
   - Actual state (from snapshot tree)
   - Console errors (if any)
   - Network failures (if any)
   - Screenshot path
```

Do NOT retry the same action more than once without re-running the diagnostic.

---

### Tracing (High-Quality Failure Analysis)

Activate devtools tracing when:
- A verification fails and console + network do not explain it
- The failure is intermittent
- You suspect a timing or render issue

To activate: launch MCP server with `--caps=devtools` flag.

Always attach trace summary to `VERIFICATION_FAIL` reports when devtools was active.

---

### Signal Format

```
VERIFICATION_PASS
  spec: <spec name>
  ac: <AC-x.y from requirements.md>
  flow: <brief description of what was verified>
  evidence: <screenshot path or "snapshot-only">
  tools_used: [browser_snapshot, browser_navigate, ...]
```

```
VERIFICATION_FAIL
  spec: <spec name>
  ac: <AC-x.y from requirements.md>
  flow: <brief description of what was attempted>
  expected: <what the spec requires>
  actual: <what the snapshot/network/console showed>
  console_errors: <list or "none">
  network_errors: <list or "none">
  evidence: <screenshot path>
  tools_used: [browser_snapshot, browser_console_messages, ...]
  diagnosis: <root cause hypothesis>
```

**Never emit a PASS without evidence. Never emit a FAIL without diagnosis.**

---

## Protocol B: Degraded Mode (MCP Missing)

When `@playwright/mcp` is not available, degrade gracefully.

1. **Static analysis**: grep source for expected UI elements, event handlers, route definitions
2. **Build check**: verify the project builds without errors
3. **curl / WebFetch**: hit the URL and check HTTP response and basic HTML structure
4. **Source inspection**: verify correct component is rendered

```
VERIFICATION_DEGRADED
  spec: <spec name>
  ac: <AC-x.y>
  reason: MCP Playwright not available
  degraded_checks_passed:
    - source: <what was found in source>
    - build: PASS/FAIL
    - http: <status code or SKIP>
  coverage_gap: UI interaction and visual assertion not verified
  install_hint: npx @playwright/mcp@latest --version (requires Node 18+)
```

If spec has UI entry points, emit ESCALATE after VERIFICATION_DEGRADED.

---

## Capability Flags Reference

| Flag | What it enables | When to use |
|---|---|---|
| `--caps=testing` | `browser_verify_*` assertion tools | Any spec with assertions |
| `--caps=devtools` | Devtools tracing, detailed timing | Intermittent failures, race conditions |
| `--caps=pdf` | PDF generation | PDF export specs only |
| Default (no flag) | Navigation, snapshot, screenshot, form interaction | Standard flows |

Always use `--caps=testing` as baseline. Add `--caps=devtools` only when diagnosing.

---

## Anti-Patterns (Never Do These)

- **Never use `browser_take_screenshot` to make assertions** — use `browser_snapshot`.
- **Never hand-write CSS selectors or XPath** — always use `browser_generate_locator`.
- **Never retry a failed action without re-running diagnostic**.
- **Never emit PASS without screenshot evidence**.
- **Never emit FAIL without console + network inspection**.
- **Never continue a multi-step flow after an unexpected state** — stop and diagnose.
- **Never install `@playwright/mcp` automatically** — always escalate to human if missing.
- **Never start a browser session without first completing Step -1**.
- **Never skip the stable state check after navigation or action**.
