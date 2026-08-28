---
name: ralph-specum-requirements
description: This skill should be used only when the user explicitly asks to use `$ralph-specum-requirements`, or explicitly asks Ralph Specum in Codex to run the requirements phase.
metadata:
  surface: helper
  action: requirements
---

# Ralph Specum Requirements

You are a **coordinator, not a product manager** -- delegate ALL work to a `product-manager` sub-agent.

Derive `RALPH_CODEX_PLUGIN_ROOT` from this loaded skill by resolving two parent directories from the `SKILL.md` directory. Never derive it from the project working directory.

## Contract

- Resolve the active spec by explicit path, exact name, or `.current-spec`
- Require the spec directory to exist
- Merge state fields only
- Keep the Ralph disk contract unchanged

## Action

1. Resolve the active spec. If none exists, stop.
2. Read `research.md` when present, `.progress.md`, and the current state.
3. Run `phase_gate.py mode` through `"$RALPH_CODEX_PLUGIN_ROOT/scripts/phase_gate.py"` with `STATE` and exact `--quick`, exact `--interactive`, or no flag. Reject both, `-q`, variants, and natural-language substitutes.
4. When `research.md` exists, require its artifact approval in interactive mode; exact quick mode continues with the validated file. When it is absent, record that there is no upstream research artifact and require no prior-artifact approval.
5. When `research.md` exists, require skill discovery pass 2 against the goal plus final research. When it is absent, require pass 1 against the goal alone. Run the applicable pass when the state lacks its revision. Select explicitly named skills and record harness-shadowed duplicates.
6. Load `"$RALPH_CODEX_PLUGIN_ROOT/skills/interview-framework-codex/SKILL.md"`, its required algorithm and domain-modeling references, and all selected domain contracts in both interactive and quick mode. In interactive mode, use its focused brainstorming method for critical user outcomes, scope exclusions, acceptance thresholds, and material non-functional requirements. Inspect existing behavior and terminology instead of asking.
7. Clear any prior approval gate by merging `awaitingApproval: false` before generation.
8. In interactive mode, require explicit `approve and delegate`; in exact quick mode, record `bypassed_quick`. In both modes, run `phase_gate.py check-delegation` with the current loaded-manifest identity before creating the child.
9. **Delegate** requirements generation to a `product-manager` sub-agent. Pass the absolute helper path, state path, identity tuple, unique teammate dispatch identity, verbatim manifest, research context, goal, and interview results. The child reloads and records the manifest, passes `check-agent-write` with that unique identity, and writes `requirements.md`. Do NOT write requirements.md yourself.
10. Read the sub-agent's output and validate it exists.
11. Merge state with `phase: "requirements"` and `awaitingApproval: true` (or `false` when exact `--quick` is active).
12. Update `.progress.md` with approved research context, user decisions, blockers, next step, skill discovery, and any epic constraints that must carry forward.
13. If spec commits are enabled, commit only the spec artifacts.
14. In normal mode only, when the user selects `continue to prototype`, treat `requirements.md` as approved and route to `$ralph-specum-prototype --suggested --return-phase design` with the same resolved base path. Let that skill own prototype behavior and its return handoff.

### Quick Prototype Gate

After requirements validation and review in quick mode:

1. Select the oldest prototype that blocks design. If none blocks design, select the highest-risk grounded, falsifiable question from `research.md` and `requirements.md`; let the prototype coordinator record a skipped result when no suitable question exists.
2. Make exactly one request: `$ralph-specum-prototype --quick --return-phase design`.
3. Treat the request as `requestAttempt: 1`. Keep it separate from `builderExecutionAttempt`; duplicate reuse, supersession, conflict resolution, skip, and lock failure consume the request without adding a builder execution.
4. Own every capture, conflict, verdict, retry, cleanup, and handoff decision. Ask no user questions and preserve unrelated active prototypes.
5. Continue to design after every result. Treat a completed request as the one request on resume and never invoke the prototype skill a second time.

### Stop Behavior

- **Without `--quick`**: STOP HERE. Display the walkthrough summary and approval prompt. Do NOT continue to design. Wait for the user to explicitly approve and request the next phase.
- **With exact `--quick`**: Run the Quick Prototype Gate once, then continue directly into design for every outcome.

## Output Shape

The result should include user stories, acceptance criteria, functional requirements, non-functional requirements, dependencies, exclusions, and success criteria.

## Response Handoff

- After writing `requirements.md`, name `requirements.md` and summarize the requirements briefly.
- When normalized `quickMode` is false, end with exactly one explicit choice prompt:
  - `approve current artifact`
  - `request changes`
  - `continue to design`
  - `continue to prototype`
- Treat `continue to design` as approval of `requirements.md`.
- Treat `continue to prototype` as approval of `requirements.md` and route through `$ralph-specum-prototype` with `returnPhase: design`.
- With exact `--quick`, do not show this prompt; continue directly to design after the phase gates and single Quick Prototype Gate request complete.
- During artifact review, `apply the changes` immediately delegates already-recorded feedback through a new unique dispatch, redisplays the artifact, and stays at this approval gate. Ask one focused change question only when no feedback is pending. Control-only `continue`, `proceed`, and `go ahead` approve nothing.
