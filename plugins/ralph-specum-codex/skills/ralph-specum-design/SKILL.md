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
3. Run prototype record selection with the resolved `basePath` before generation:
   ```bash
   python3 "$RALPH_CODEX_PLUGIN_ROOT/scripts/prototype_records.py" select-downstream --base-path "$BASE_PATH" --state "$BASE_PATH/.ralph-state.json"
   ```
4. Include only affected, valid, `gateApproved: true`, non-superseded records returned by the selector. Exclude malformed, superseded, skipped, failed, inconclusive, cancelled, and normal-mode excluded records.
5. Stop before generation when selection reports an `activePrototypes` blocker for design. Name the active ID and route resume through `$ralph-specum-prototype`.
6. Stop when selection reports stale requirements, research, design, or task indexes that affect design. Route to the earliest stale phase. Allow proven unrelated work only when the selector reports no dependency on the active prototype, stale artifact, stale task index, or approved transfer path.
7. Clear any prior approval gate by merging `awaitingApproval: false` before generation.
8. Use the current brainstorming interview style unless quick mode is active.
9. **Delegate** design generation to an `architect-reviewer` sub-agent. Pass requirements, research, selected prototype evidence, the clean blocker/stale-gate result, and interview context. The sub-agent writes `design.md`. Do NOT write design.md yourself.
10. Read the sub-agent's output and validate it exists.
11. Merge state with `phase: "design"` and `awaitingApproval: true` (or `false` when `--quick` is active).
12. Update `.progress.md` with design decisions, open risks, integration contracts, and next step.
13. If spec commits are enabled, commit only the spec artifacts.

### Stop Behavior

- **Without `--quick`**: STOP HERE. Display the walkthrough summary and approval prompt. Do NOT continue to tasks. Wait for the user to explicitly approve and request the next phase.
- **With `--quick`**: Continue directly into tasks.

## Output Shape

The result should cover architecture, interfaces, data flow, file changes, technical decisions, error handling, and test strategy.

## Response Handoff

- After writing `design.md`, name `design.md` and summarize the design briefly.
- End with exactly one explicit choice prompt:
  - `approve current artifact`
  - `request changes`
  - `continue to tasks`
- Treat `continue to tasks` as approval of `design.md`.
