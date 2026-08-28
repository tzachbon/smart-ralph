---
name: ralph-specum-research
description: This skill should be used only when the user explicitly asks to use `$ralph-specum-research`, or explicitly asks Ralph Specum in Codex to run the research phase.
metadata:
  surface: helper
  action: research
---

# Ralph Specum Research

You are a **coordinator, not a researcher** -- delegate ALL work to a `research-analyst` sub-agent.

Derive `RALPH_CODEX_PLUGIN_ROOT` from this loaded skill by resolving two parent directories from the `SKILL.md` directory. Never derive it from the project working directory.

## Contract

- Resolve the active spec by explicit path, exact name, or `.current-spec`
- Respect `.claude/ralph-specum.local.md` when present
- Default specs root is `./specs`
- Keep the canonical Ralph file names
- Merge state fields only

## Action

1. Resolve the active spec. If none exists, stop and tell the user to start a spec first.
2. Read the goal, `.progress.md`, current state, indexed codebase context, related specs, and epic context when present.
3. Run `phase_gate.py mode` through `"$RALPH_CODEX_PLUGIN_ROOT/scripts/phase_gate.py"` with `STATE` and exact `--quick`, exact `--interactive`, or no flag. Reject both, `-q`, variants, and natural-language substitutes.
4. Run skill discovery pass 1 when the state lacks an applicable revision. Select explicitly named skills and record harness-shadowed duplicates.
5. Load `"$RALPH_CODEX_PLUGIN_ROOT/skills/interview-framework-codex/SKILL.md"`, its required algorithm and domain-modeling references, and all selected domain contracts in both interactive and quick mode. In interactive mode, use its focused brainstorming method for critical evidence scope, decision thresholds, and material unknowns. Inspect source availability, code facts, and existing patterns instead of asking.
6. In interactive mode, require explicit `approve and delegate`; in exact quick mode, record `bypassed_quick`. In both modes, run `phase_gate.py check-delegation` with the current loaded-manifest identity before creating the child.
7. **Delegate** research generation to a `research-analyst` sub-agent. Pass the absolute gate helper path, state path, full identity tuple, unique teammate dispatch identity, verbatim skill manifest, goal, context, and interview results. The sub-agent reloads and records the manifest, passes `check-agent-write` with that unique identity, and writes `research.md`. Do NOT write research.md yourself.
8. Read the sub-agent's output and validate it exists.
9. Merge state with `phase: "research"` and `awaitingApproval: true` (or `false` when exact `--quick` is active).
10. Update `.progress.md` with the research summary, blockers, learnings, next step, skill discovery, and verification tooling notes when relevant.
11. If spec commits are enabled, commit only the spec artifacts.
12. In normal mode, when the user selects `continue to prototype`, treat `research.md` as approved and route to `$ralph-specum-prototype --suggested --return-phase requirements` with the same resolved base path. Let that skill own prototype behavior and its return handoff.

### Stop Behavior

- **Without `--quick`**: STOP HERE. Display the walkthrough summary and approval prompt. Do NOT continue to requirements. Wait for the user to explicitly approve and request the next phase.
- **With exact `--quick`**: Record the quick bypass and continue directly into requirements. Do not request a prototype from research; quick mode has one post-requirements request only.

## Output Shape

The result should identify existing code patterns, external references, constraints, related specs, risks, verification tooling, and a clear recommendation for the next phase.

## Response Handoff

- After writing `research.md`, name `research.md` and summarize the research briefly.
- When normalized `quickMode` is false, end with exactly one explicit choice prompt:
  - `approve current artifact`
  - `request changes`
  - `continue to requirements`
  - `continue to prototype`
- Treat `continue to requirements` as approval of `research.md`.
- Treat `continue to prototype` as approval of `research.md` and route through `$ralph-specum-prototype` with `returnPhase: requirements`.
- With exact `--quick`, do not show this prompt; continue directly to requirements after the gates succeed.
- During artifact review, `apply the changes` immediately delegates already-recorded feedback through a new unique dispatch, redisplays the artifact, and stays at this approval gate. Ask one focused change question only when no feedback is pending. Control-only `continue`, `proceed`, and `go ahead` approve nothing.
