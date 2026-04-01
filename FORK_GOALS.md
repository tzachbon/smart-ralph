# Fork Goals — Agentic Verification Loop

> **Fork of [tzachbon/smart-ralph](https://github.com/tzachbon/smart-ralph)**
> Maintainer: [@informatico-madrid](https://github.com/informatico-madrid)

---

## The Problem

After nearly two years working with agents and SSD workflows, the testing layer
remains the most painful part. Classical test coverage strategies — unit tests,
mocks, CI suites — were designed for humans writing tests for humans to read.
When an agent writes and executes those same tests, you get:

- Tests that pass but don't verify real behavior (mock-only anti-patterns)
- High coverage numbers that give false confidence
- A test suite nobody maintains because the agent keeps rewriting it
- No self-correction when something breaks mid-spec

The root issue: **classical testing is a human artifact, not a verification
mechanism designed for agentic loops.**

---

## The Idea

> Give the agent the ability to read a user story, reason about what "working"
> looks like, explore the system creatively, detect failures, fix them, and
> verify the rest of the product wasn't broken — without a human holding its hand.

This is not BDD with Gherkin. Gherkin was invented so humans could communicate
intent to other humans. An agent that understands natural language doesn't need
a formal DSL — it needs **a contract of what to observe and a license to explore**.

We call this the **Verification Contract**: a lightweight, structured section in
each spec that tells the agent *what to observe*, not *how to test*.

---

## Core Concepts

### 1. Verification Contract (not test scripts)

Each `requirements.md` spec gets a `## Verification Contract` section:

```markdown
## Verification Contract

**Entry points**: routes, endpoints, or UI surfaces this story touches
**Observable signals**: what PASS looks like (HTTP status, visible element, persisted data, log output)
**Hard invariants**: what must NEVER break (auth, permissions, adjacent flows)
**Seed data**: minimum system state needed to verify
**Dependency map**: other specs/modules that share state with this one
**Escalate if**: conditions that require human judgment
```

The agent receives this and decides *how* to probe. It can use CLI commands,
HTTP requests, browser navigation, database queries, log inspection — whatever
makes sense given the entry points. No scripted steps. No Gherkin.

### 2. Creative Exploration over Scripted Verification

The `qa-engineer` agent today runs commands and checks AC checklists. The goal
is to extend it with **exploratory reasoning**: given a user story and a
verification contract, derive and execute checks the original author didn't
anticipate.

Examples from a single user story ("filter invoices by date"):
- Does the filter actually filter, or just visually sort?
- What happens with an invalid date range?
- Does the filter state persist across page reload?
- Does it reflect in the URL (shareable state)?
- What happens with zero results?
- Does it respect the user's timezone?
- Can it be combined with other filters?

None of these come from a script. They come from reasoning about intent.

### 3. Repair Loop (not just retry)

Today `stop-watcher.sh` retries a failed task up to 5 times — same task, same
approach. The repair loop is different:

```
VERIFICATION_FAIL on story X
  → classify failure type (impl bug / env issue / spec ambiguity / flaky)
  → if impl bug: backtrack to originating task, apply targeted fix
  → rerun verification for story X only
  → if pass: continue to regression sweep
  → if fail again after 2 repair iterations: escalate to human
```

This requires a new state in `.ralph-state.json`:
```json
{ "phase": "repair", "failedStory": "US-3", "originTaskIndex": 7, "repairIteration": 1 }
```

### 4. Regression Sweep (impact-driven, not full suite)

After a spec completes, use the `Dependency map` in each story's verification
contract to identify which other specs share state. Run only their verification
contracts — not their full implementation. Fast, targeted, meaningful.

Three tiers:
- **Local**: specs directly touching the same modules
- **Invariants**: auth, navigation, persistence, error handling
- **Full**: nightly or at final merge only

### 5. Browser as one tool among many (not the centerpiece)

Browser automation is valuable but fragile if it's the only signal. The
verification agent should combine:

| Signal layer | What it catches |
|---|---|
| CLI / test runner | Logic, edge cases, unit behavior |
| HTTP / API | Contracts, side effects, data integrity |
| Browser | Real user flows, render, wiring, UX regressions |
| Logs / traces | Root cause, silent failures, perf |

Browser becomes a Phase 5 addition (MCP Playwright), not the foundation.

---

## Phases

### Phase 0 — Fork setup ✅
- [x] Fork created
- [x] `FORK_GOALS.md` added

### Phase 0.1 — E2E skill foundation ✅
- [x] `skills/e2e/homeassistant-selector-map.skill.md` — stable Playwright
  selector strategy with Home Assistant examples. Reusable as reference
  for other projects (copy + adapt domain examples).
- [x] `skills/e2e/ui-map-init.skill.md` — agnostic protocol for generating
  `ui-map.local.md` in any project. Runs once per project/installation.
  Output is gitignored — never committed.
- [x] `skills/e2e/e2e-verify-integration.skill.md` — signal contract for
  ralph-specum (`VERIFICATION_PASS/FAIL` via `qa-engineer`,
  `ALL_TASKS_COMPLETE` via `stop-watcher` transcript detection; single
  checkbox per task; user stories in `requirements.md` not `tasks.md`)
- [x] `.gitignore`: added `**/ui-map.local.md`

Skills are referenced from `tasks.md` task entries via `**Skills**` field.
Additive only. Zero risk to existing flow.

### Phase 0.2 — task-planner auto-injection ✅
- [x] `agents/task-planner.md` — new `### Playwright E2E Tasks: ui-map-init
  Prerequisite` block inside `## VE Task Generation`.
  - Detects Playwright usage in any VE task (by `Verify`/`Do` field content).
  - Auto-inserts `VE0` task immediately before the first Playwright VE task.
  - `VE0` checks for `ui-map.local.md` existence first; skips exploration if
    already present (idempotent).
  - All Playwright VE tasks get `**Skills**: skills/e2e/playwright-session.skill.md`.
  - Quality Checklist updated with the corresponding gate.

Previously, `**Skills**` had to be written manually in each `tasks.md`. Now
`task-planner` injects the prerequisite automatically on every spec that uses
Playwright. Zero human memory required.

### Phase 1 — Verification Contract in specs ✅
- [x] `templates/requirements.md` — added `## Verification Contract` section
  with all six fields: Entry points, Observable signals, Hard invariants,
  Seed data, Dependency map, Escalate if.
- [x] `agents/product-manager.md` — added guidelines to populate the
  Verification Contract from user stories, plus quality checklist items.
- Additive only. Zero risk to existing flow.

### Phase 2 — Exploratory qa-engineer ✅
- [x] `agents/qa-engineer.md` — added `## Story Verification` mode activated
  by `[STORY-VERIFY]` tag.
  - Reads user story + Verification Contract, derives checks autonomously.
  - Emits structured findings: `VERIFICATION_PASS`, `VERIFICATION_FAIL`,
    `FINDING` (unexpected behavior worth noting).
  - No Gherkin. No scripted steps.

### Phase 3 — Repair loop in stop-watcher ✅
- [x] `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` — new repair loop
  block after transcript detection.
  - Detects `VERIFICATION_FAIL` in transcript.
  - Reads `repairIteration`, `failedStory`, `originTaskIndex` from
    `.ralph-state.json`.
  - Classifies failure type (impl_bug / env_issue / spec_ambiguity / flaky)
    and issues targeted repair prompt.
  - Max 2 repair iterations per story; escalates to human on exhaustion.
  - Respects `stop_hook_active` guard to prevent infinite loops.
  - New `.ralph-state.json` fields: `repairIteration`, `failedStory`,
    `originTaskIndex`.

### Phase 4 — Regression sweep ✅
- [x] `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` — regression sweep
  block inside `ALL_TASKS_COMPLETE` detection.
  - Reads `**Dependency map**` from the completed spec's `requirements.md`.
  - Resolves each dep to its spec path under `specs/`.
  - Issues targeted `[STORY-VERIFY]` sweep prompt (verification only, no
    re-implementation).
  - Expects `REGRESSION_SWEEP_COMPLETE` signal when all sweeps pass.
  - If any sweep emits `VERIFICATION_FAIL`, Phase 3 repair loop activates.
  - Respects `stop_hook_active` guard.
  - Local tier only (dependency map). Invariants and full-suite are nightly.

### Phase 5 — Browser tool (experimental branch)
- [ ] MCP Playwright integration as optional qa-engineer tool
- [ ] Activated only when entry points include UI routes
- [ ] Separate branch `feat/browser-verification`, not merged to main until stable

---

## Contribution Strategy

Changes in Phases 0.1–2 are purely additive and should be PRable upstream.
Phases 3–4 touch `stop-watcher.sh` — open a discussion issue on upstream first.
Phase 5 lives as a separate plugin `ralph-bdd-browser` to keep the core clean.

All changes follow upstream Karpathy Rules: surgical, no speculation, version
bump on every plugin change, no features beyond what's asked.

---

## What this is NOT

- Not a Gherkin/BDD framework
- Not a replacement for `qa-engineer` (it extends it)
- Not a browser-testing tool (browser is one signal layer, not the product)
- Not a full rewrite of smart-ralph (every phase is a small additive change)

---

## Status

**Current phase**: 4 complete — repair loop + regression sweep active in stop-watcher.
**Next step**: Phase 5 — MCP Playwright integration (experimental branch `feat/browser-verification`).
