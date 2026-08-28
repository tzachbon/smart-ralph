---
name: ralph-specum-help
description: This skill should be used only when the user explicitly asks to use `$ralph-specum-help`, or explicitly asks Ralph Specum in Codex for help or command guidance.
metadata:
  surface: helper
  action: help
---

# Ralph Specum Help

Use this to explain the Ralph Specum surface in Codex.

## Cover

- Primary skill: `$ralph-specum`
- Helper skills: `$ralph-specum-start`, `$ralph-specum-triage`, `$ralph-specum-research`, `$ralph-specum-requirements`, `$ralph-specum-design`, `$ralph-specum-tasks`, `$ralph-specum-prototype`, `$ralph-specum-implement`, `$ralph-specum-status`, `$ralph-specum-switch`, `$ralph-specum-cancel`, `$ralph-specum-index`, `$ralph-specum-refactor`, `$ralph-specum-feedback`, `$ralph-specum-help`
- Normal flow: start, stop, research, approval, requirements, approval, design, approval, tasks, approval, implement
- Large effort flow: triage, then start each unblocked spec
- Quick mode: generate missing artifacts and continue into implementation in one run only when the user explicitly asks for quick or autonomous flow
- Disk contract: `./specs` or configured roots, `.current-spec`, optional `.current-epic`, per-spec markdown files, `.ralph-state.json`

## Optional Prototype Overlay

- Direct mode: invoke `$ralph-specum-prototype` from research, requirements, design, tasks, or execution. Preserve the main phase and current checkout.
- Suggested mode: research or requirements may offer `continue to prototype`, then return to the next normal phase.
- Resume mode: use `$ralph-specum-prototype --resume <id>`. One active entry resumes automatically; several are listed deterministically for selection.
- Quick mode: run exactly one agent-owned request after requirements, ask no prototype questions, take over the oldest design blocker or select the highest-risk grounded, falsifiable question when no blocker exists, own verdict and handoff decisions, and continue to design for every result.
- Cancel mode: use `$ralph-specum-prototype --cancel <id>` or safe spec cancellation. Stop at a safe boundary, publish a reviewed immutable `cancelled` record, and preserve source and partial implementation.

Store terminal records under the resolved `<basePath>/prototypes/`. Run source work in a sibling worktree or eligible scratch area without switching the current checkout or copying unapproved dirty paths. Keep source, evidence, records, and branches local. Require separate authorization for every push, PR or issue change, and other remote action. Require exact-path and local-branch confirmation before local deletion; never delete a remote branch during prototype cleanup.

## Guidance

- Recommend `$ralph-specum` as the default entrypoint.
- Recommend `$ralph-specum-triage` when the user describes a large, multi-part, or dependency-heavy effort.
- Mention helper skills when the user wants explicit phase control.
- Explain that Ralph does not self-advance by default. The user must approve the current artifact, request changes, or explicitly continue to the next step.
- Explain that safe cancel deletes execution state only after verified immutable cancellation records exist. Full spec deletion and each prototype source deletion are separate exact-target confirmations.
- Explain that `$ralph-specum-status` reports active entries, candidates, immutable finals, quarantines, blockers, return phase/task, and source disposition.
- Mention optional bootstrap assets only when the user wants repo-local guidance.
