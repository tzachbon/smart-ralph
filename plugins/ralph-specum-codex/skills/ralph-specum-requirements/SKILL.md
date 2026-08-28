---
name: ralph-specum-requirements
description: This skill should be used only when the user explicitly asks to use `$ralph-specum-requirements`, or explicitly asks Ralph Specum in Codex to run the requirements phase.
metadata:
  surface: helper
  action: requirements
---

# Ralph Specum Requirements

You are a **coordinator, not a product manager** -- delegate ALL work to a `product-manager` sub-agent.

## Contract

- Resolve the active spec by explicit path, exact name, or `.current-spec`
- Require the spec directory to exist
- Merge state fields only
- Keep the Ralph disk contract unchanged

## Action

1. Resolve the active spec. If none exists, stop.
2. Read `research.md` when present, `.progress.md`, and the current state.
3. Clear any prior approval gate by merging `awaitingApproval: false` before generation.
4. Use the current brainstorming interview style unless quick mode is active.
5. **Delegate** requirements generation to a `product-manager` sub-agent. Pass research context, goal, and interview results. The sub-agent writes `requirements.md`. Do NOT write requirements.md yourself.
6. Read the sub-agent's output and validate it exists.
7. Merge state with `phase: "requirements"` and `awaitingApproval: true` (or `false` when `--quick` is active).
8. Update `.progress.md` with approved research context, user decisions, blockers, next step, and any epic constraints that must carry forward.
9. If spec commits are enabled, commit only the spec artifacts.
10. In normal mode, when the user selects `continue to prototype`, treat `requirements.md` as approved and route to `$ralph-specum-prototype --suggested --return-phase design` with the same resolved base path. Let that skill own prototype behavior and its return handoff.

### Quick Prototype Gate

After requirements validation and review in quick mode:

1. Select the oldest prototype that blocks design. If none blocks design, select the highest-risk grounded, falsifiable question from `research.md` and `requirements.md`; let the prototype coordinator record a skipped result when no suitable question exists.
2. Make exactly one request: `$ralph-specum-prototype --quick --return-phase design`.
3. Treat the request as `requestAttempt: 1`. Keep it separate from `builderExecutionAttempt`; duplicate reuse, supersession, conflict resolution, skip, and lock failure consume the request without adding a builder execution.
4. Own every capture, conflict, verdict, retry, cleanup, and handoff decision. Ask no user questions and preserve unrelated active prototypes.
5. Continue to design after every result. Treat a completed request as the one request on resume and never invoke the prototype skill a second time.

### Stop Behavior

- **Without `--quick`**: STOP HERE. Display the walkthrough summary and choice prompt. Do NOT continue until the user selects the design or prototype route.
- **With `--quick`**: Run the Quick Prototype Gate once, then continue directly into design for every outcome.

## Output Shape

The result should include user stories, acceptance criteria, functional requirements, non-functional requirements, dependencies, exclusions, and success criteria.

## Response Handoff

- After writing `requirements.md`, name `requirements.md` and summarize the requirements briefly.
- In normal mode only, end with exactly one explicit choice prompt:
  - `approve current artifact`
  - `request changes`
  - `continue to design`
  - `continue to prototype`
- In normal mode, treat `continue to design` as approval of `requirements.md`.
- In normal mode, treat `continue to prototype` as approval of `requirements.md` and route through `$ralph-specum-prototype` with `returnPhase: design`.
- In quick mode, omit the choice prompt and any second prototype route. After the single Quick Prototype Gate request completes, continue directly to design.
