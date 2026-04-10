---
name: e2e
version: 1.0.0
description: Load this skill suite for any spec that involves end-to-end testing, browser automation, Playwright, MCP browser tools, VE tasks, user flow verification, UI testing, or integration tests that drive a real browser. Covers session lifecycle, environment setup, navigation anti-patterns, stable-state detection, auth flows, selector stability, and cleanup guarantees.
agents: [spec-executor, qa-engineer, task-planner]
---

# E2E Skill Suite

This is the entry point for the E2E skill suite. It does not contain implementation
details — it delegates to the sub-skills listed below, each covering a distinct concern.

**Load order is mandatory.** Each sub-skill depends on state written by the previous one.

---

## When to Load This Suite

Load this suite whenever the spec involves any of the following:

- End-to-end tests or browser automation
- VE tasks (VE0, VE1, VE2, VE3) in any workflow phase
- `[VERIFY]` tasks that use browser tools
- Playwright, MCP Playwright tools (`browser_*`)
- User flow verification against a running application
- UI interaction testing (clicks, form fills, navigation)

If any of the above applies: load all sub-skills before writing any browser code.

---

## Sub-Skills — Load in This Order

### 1. `playwright-env.skill.md`
**Purpose**: Resolves the browser execution context — app URL, auth mode, credentials
references, browser config, safety limits. Writes `playwrightEnv` to `.ralph-state.json`.

**Load when**: Always first, before any other E2E skill.

```
Read: ${CLAUDE_PLUGIN_ROOT}/skills/e2e/playwright-env.skill.md
```

### 2. `mcp-playwright.skill.md`
**Purpose**: Validates MCP server availability, handles lock recovery, and emits
`ESCALATE` if the server is unreachable. Writes `mcpPlaywright` to `.ralph-state.json`.

**Load when**: Always second, after playwright-env.

```
Read: ${CLAUDE_PLUGIN_ROOT}/skills/e2e/mcp-playwright.skill.md
```

### 3. `playwright-session.skill.md`
**Purpose**: Governs session lifecycle — start, navigation, stable-state detection,
auth flows, context isolation, unexpected page recovery, and cleanup guarantee.

**CRITICAL sections** (read before writing any browser interaction):
- **Navigation Anti-Patterns** — `page.goto()` on internal routes breaks SPA routing
- **Unexpected Page Recovery** — if you land on 404/login/wrong page, diagnose the
  navigation step, do NOT assume the element is missing

**Load when**: Always third, after mcp-playwright.

```
Read: ${CLAUDE_PLUGIN_ROOT}/skills/e2e/playwright-session.skill.md
```

### 4. `ui-map-init.skill.md`
**Purpose**: Builds or updates `ui-map.local.md` — the authoritative selector map for
the spec. Sub-skills and tasks use selectors from this file; they never invent selectors.

**Load when**: VE0 tasks, or when `ui-map.local.md` is missing or stale.

```
Read: ${CLAUDE_PLUGIN_ROOT}/skills/e2e/ui-map-init.skill.md
```

### 5. `selector-map.skill.md`
**Purpose**: Governs how to read and write selector maps — entry format, confidence
levels, broken selector protocol, and incremental update rules.

**Load when**: Any task that reads `ui-map.local.md` or adds new selectors to it.

```
Read: ${CLAUDE_PLUGIN_ROOT}/skills/e2e/selector-map.skill.md
```

---

## Platform-Specific Examples

For platform-specific navigation patterns and selector conventions, see the `examples/`
directory. These are reference implementations for developers — they show how the
above skills apply to concrete platforms. The task-planner writes the relevant skill
paths directly into VE task bodies after research.

```
${CLAUDE_PLUGIN_ROOT}/skills/e2e/examples/
```

---

## Anti-Patterns Reference

The canonical E2E anti-pattern list lives at:
```
${CLAUDE_PLUGIN_ROOT}/references/e2e-anti-patterns.md
```

Read it before writing any browser code. The Navigation section is the highest-priority.
