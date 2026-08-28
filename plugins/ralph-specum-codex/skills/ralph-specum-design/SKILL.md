---
name: ralph-specum-design
description: This skill should be used only when the user explicitly asks to use `$ralph-specum-design`, or explicitly asks Ralph Specum in Codex to run the design phase.
metadata:
  surface: helper
  action: design
---

# Ralph Specum Design

You are a **coordinator, not an architect** -- delegate ALL work to an `architect-reviewer` sub-agent.

Derive `RALPH_CODEX_PLUGIN_ROOT` from this loaded skill by resolving two parent directories from the `SKILL.md` directory. Never derive it from the project working directory.

## Contract

- Resolve the active spec by explicit path, exact name, or `.current-spec`
- Require `requirements.md`
- Merge state fields only
- Keep the Ralph disk contract unchanged

## Action

1. Resolve the active spec. If none exists, stop.
2. Require `requirements.md`. Read `research.md` when present, `.progress.md`, and current state.
3. Run `phase_gate.py mode` through `"$RALPH_CODEX_PLUGIN_ROOT/scripts/phase_gate.py"` with `STATE` and exact `--quick`, exact `--interactive`, or no flag. Reject both, `-q`, variants, and natural-language substitutes.
4. In interactive mode, require artifact approval for the current `requirements.md` before starting design. Exact quick mode continues with the validated artifact.
5. Run prototype record selection with the resolved `basePath` before generation:
   ```bash
   python3 "$RALPH_CODEX_PLUGIN_ROOT/scripts/prototype_records.py" select-downstream --base-path "$BASE_PATH" --state "$BASE_PATH/.ralph-state.json"
   ```
6. Include only affected, valid, `gateApproved: true`, non-superseded records returned by the selector. Exclude malformed, superseded, skipped, failed, inconclusive, cancelled, and normal-mode excluded records.
7. Stop before generation when selection reports an `activePrototypes` blocker for design. Name the active ID and route resume through `$ralph-specum-prototype`.
8. Stop when selection reports stale requirements, research, design, or task indexes that affect design. Route to the earliest stale phase. Allow proven unrelated work only when the selector reports no dependency on the active prototype, stale artifact, stale task index, or approved transfer path.
9. Clear any prior approval gate by merging `awaitingApproval: false` before generation.
10. When `research.md` exists, require skill discovery pass 2 against the goal plus final research. When it is absent, require pass 1 against the goal alone. Run the applicable pass when the state lacks its revision. Select explicitly named skills and record harness-shadowed duplicates.
11. Load `"$RALPH_CODEX_PLUGIN_ROOT/skills/interview-framework-codex/SKILL.md"`, its required algorithm and domain-modeling references, and all selected domain contracts in both interactive and quick mode. In interactive mode, use its focused brainstorming method for material architecture choices, stable interfaces, compatibility or migration decisions, and operational risk. Inspect repository facts and existing conventions instead of asking.
12. In interactive mode, require explicit `approve and delegate`; in exact quick mode, record `bypassed_quick`. In both modes, run `phase_gate.py check-delegation` with the current loaded-manifest identity before creating the child.
13. **Delegate** design generation to an `architect-reviewer` sub-agent. Pass the absolute helper path, state path, identity tuple, unique teammate dispatch identity, verbatim manifest, requirements, research, selected prototype evidence, the clean blocker/stale-gate result, and interview context. The child reloads and records the manifest, passes `check-agent-write` with that unique identity, and writes `design.md`. Do NOT write design.md yourself.
14. Read the sub-agent's output and validate it exists.
15. Merge state with `phase: "design"` and `awaitingApproval: true` (or `false` when exact `--quick` is active).
16. Update `.progress.md` with design decisions, open risks, integration contracts, skill discovery, and next step.
17. If spec commits are enabled, commit only the spec artifacts.

### Stop Behavior

- **Without `--quick`**: STOP HERE. Display the walkthrough summary and approval prompt. Do NOT continue to tasks. Wait for the user to explicitly approve and request the next phase.
- **With exact `--quick`**: Record the quick bypass and continue directly into tasks.

## Output Shape

The result should cover architecture, interfaces, data flow, file changes, technical decisions, error handling, and test strategy.

## Response Handoff

- After writing `design.md`, name `design.md` and summarize the design briefly.
- When normalized `quickMode` is false, end with exactly one explicit choice prompt:
  - `approve current artifact`
  - `request changes`
  - `continue to tasks`
- Treat `continue to tasks` as approval of `design.md`.
- With exact `--quick`, do not show this prompt; continue directly to tasks after the gates succeed.
- During artifact review, `apply the changes` immediately delegates already-recorded feedback through a new unique dispatch, redisplays the artifact, and stays at this approval gate. Ask one focused change question only when no feedback is pending. Control-only `continue`, `proceed`, and `go ahead` approve nothing.
