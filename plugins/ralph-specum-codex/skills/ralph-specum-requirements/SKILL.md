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
3. Run `scripts/phase_gate.py mode STATE` with exact `--quick`, exact `--interactive`, or no flag. Reject both, `-q`, variants, and natural-language substitutes.
4. When `research.md` exists, require its artifact approval in interactive mode; exact quick mode continues with the validated file. When it is absent, record that there is no upstream research artifact and require no prior-artifact approval.
5. When `research.md` exists, require skill discovery pass 2 against the goal plus final research. When it is absent, require pass 1 against the goal alone. Run the applicable pass when the state lacks its revision. Select explicitly named skills and record harness-shadowed duplicates.
6. Load `skills/interview-framework-codex/SKILL.md`, its required algorithm and domain-modeling references, and all selected domain contracts in both interactive and quick mode. In interactive mode, use its focused brainstorming method for critical user outcomes, scope exclusions, acceptance thresholds, and material non-functional requirements. Inspect existing behavior and terminology instead of asking.
7. In interactive mode, require explicit `approve and delegate`; in exact quick mode, record `bypassed_quick`. In both modes, run `phase_gate.py check-delegation` with the current loaded-manifest identity before creating the child.
8. **Delegate** requirements generation to a `product-manager` sub-agent. Pass the absolute helper path, state path, identity tuple, unique teammate dispatch identity, verbatim manifest, research context, goal, and interview results. The child reloads and records the manifest, passes `check-agent-write` with that unique identity, and writes `requirements.md`. Do NOT write requirements.md yourself.
9. Read the sub-agent's output and validate it exists.
10. Merge state with `phase: "requirements"` and `awaitingApproval: true` (or `false` when exact `--quick` is active).
11. Update `.progress.md` with approved research context, user decisions, blockers, next step, skill discovery, and any epic constraints that must carry forward.
12. If spec commits are enabled, commit only the spec artifacts.

### Stop Behavior

- **Without `--quick`**: STOP HERE. Display the walkthrough summary and approval prompt. Do NOT continue to design. Wait for the user to explicitly approve and request the next phase.
- **With exact `--quick`**: Record the quick bypass and continue directly into design.

## Output Shape

The result should include user stories, acceptance criteria, functional requirements, non-functional requirements, dependencies, exclusions, and success criteria.

## Response Handoff

- After writing `requirements.md`, name `requirements.md` and summarize the requirements briefly.
- When normalized `quickMode` is false, end with exactly one explicit choice prompt:
  - `approve current artifact`
  - `request changes`
  - `continue to design`
- Treat `continue to design` as approval of `requirements.md`.
- With exact `--quick`, do not show this prompt; continue directly to design after the gates succeed.
- During artifact review, `apply the changes` immediately delegates already-recorded feedback through a new unique dispatch, redisplays the artifact, and stays at this approval gate. Ask one focused change question only when no feedback is pending. Control-only `continue`, `proceed`, and `go ahead` approve nothing.
