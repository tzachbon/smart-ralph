---
name: ralph-specum-triage
description: This skill should be used only when the user explicitly asks to use `$ralph-specum-triage`, or explicitly asks Ralph Specum in Codex to triage a large effort into multiple specs.
metadata:
  surface: helper
  action: triage
---

# Ralph Specum Triage

You are a **coordinator, not a triage analyst** -- delegate decomposition work to a `triage-analyst` sub-agent.

## Contract

- Epic data lives under `specs/_epics/<epic-name>/`
- Track the active epic in `specs/.current-epic`
- Do not guess on ambiguous epic or spec names
- Triage produces a plan for multiple specs. It does not implement them

## Action

1. Parse exact `--quick` and exact `--interactive` tokens before routing. Reject both together, `-q`, variants, and natural-language substitutes.
2. Check `specs/.current-epic`. If an active epic exists, load its `.epic-state.json` as `STATE` and normalize mode before any possible question. With exact `--quick`, resume the matching active epic without prompting; an explicit different epic must include its goal. In interactive mode, summarize status and offer resume, details, or a new epic.
3. Validate the resolved epic name against `^[a-z0-9]+(-[a-z0-9]+)*$` before constructing any path. Reject invalid names. If `specs/_epics/<epic-name>/.epic-state.json` already exists, reuse and resume it without replacing state or progress. If the directory exists without a valid state, stop and require a different name or an explicit user-authorized reset. Only a missing directory may be initialized.
4. Resolve or create only the epic directory, `.progress.md`, and `.epic-state.json`. Serialize the name and goal through a JSON encoder such as `jq --arg`. Use `.epic-state.json` as `STATE` for every phase gate command with phase `triage`. Use `.epic-state.json` as `STATE` for every writer. After that, do not require `.ralph-state.json`. Create no `research.md`, `epic.md`, or generated `plan.md` before approval.
5. For a new epic, run `scripts/phase_gate.py mode STATE` with the exact parsed mode flag, then register `specs/.current-epic` before discovery. Exact quick mode asks no setup question; missing required name or goal is an input error.
6. Resolve the output destination from explicit input and configuration. In exact quick mode, use local Spec files as the deterministic default and ask nothing. Only interactive mode may ask one administrative destination question when the destination remains ambiguous; that answer never satisfies the interview gate.
7. Ensure skill discovery pass 1 exists for the epic goal. Collect plugin, project `.agents/skills`, project `.claude/skills`, and current harness catalog entries. Select explicitly named skills and record shadowed duplicates.
8. Load `skills/interview-framework-codex/SKILL.md`, its required algorithm and domain-modeling references, and every selected domain contract in both interactive and quick mode. In interactive mode, follow the algorithm for critical decomposition boundaries, stable cross-spec contracts, dependency choices, and sequencing risks. Ask no storage, naming, branch, or discoverable question.
9. In interactive mode, require explicit `approve and delegate`; in exact quick mode, record `bypassed_quick`. In both modes, run `phase_gate.py check-delegation` with phase `triage` and the current loaded-manifest identity before every artifact-producing child. Apply the shared hard-transition invariant before every triage artifact writer. A failed `check-delegation` in either mode stops this invocation before phase transition, child dispatch, or target-artifact write; after a normal-mode failure, only the next explicit invocation creates a fresh manifest/interview identity. After an exact `--quick` delegation failure, the next explicit invocation reruns discovery, records a fresh `phaseSkillLoad` and interview identity, and does not reuse a terminal `bypassed_quick` interview or its discovery revision. Only a matching in-progress `collecting` or `awaiting_confirmation` interview is resumable. Exact `--quick` retains its existing question-and-approval bypass and discovery, manifest, delegation, and writer checks.
10. Read-only exploration children may inspect seams, constraints, and existing boundaries, but they write no epic artifact.
11. Keep the existing epic-state, read-only exploration, and multiwriter flow, plus each child packet, identity tuple, and receipt behavior, unchanged. Use separate unique gated writer dispatches as needed:
   - a triage research writer for `research.md`
   - a triage plan writer for `epic.md` and generated spec `plan.md` files
   - a fresh revision writer for every artifact-review revision
   Pass the absolute gate helper path, epic state path, identity tuple, unique teammate dispatch identity, and verbatim `phaseSkillLoad` manifest to each writer. Each writer records its manifest loads and passes `check-agent-write` with its unique identity before its first filesystem artifact write.
12. The coordinator does not assemble, format, or revise artifact content. Validate the gated writer outputs and persist `.epic-state.json` with each spec, its status, dependencies, and gate receipts.
13. Keep `specs/.current-epic` set to the active epic name.
14. Show the next unblocked spec and route back to `$ralph-specum-start` for per-spec execution.

## Output Shape

The result should make it clear:
- what belongs in each spec
- which specs can start now
- which specs are blocked by dependencies
- what contracts must stay stable across specs

## Stop Behavior

- **Without `--quick`**: STOP HERE. Display the epic summary and approval prompt. Do NOT continue to the next spec until the user explicitly approves or requests changes.
- **With exact `--quick`**: Record the quick bypass and continue directly to the first unblocked spec.

## Response Handoff

- After writing `epic.md`, name `epic.md` and summarize the epic plan briefly.
- When normalized `quickMode` is false, end with exactly one explicit choice prompt:
  - `approve current artifact`
  - `request changes`
  - `continue to the next spec`
- Treat `continue to the next spec` as approval of `epic.md`.
- With exact `--quick`, do not show this prompt; continue directly to the first unblocked spec after the gates succeed.
- During artifact review, `apply the changes` immediately delegates already-recorded feedback through a fresh unique gated revision writer, redisplays the artifacts, and stays at this approval gate. Ask one focused change question only when no feedback is pending. Control-only `continue`, `proceed`, and `go ahead` approve nothing.
