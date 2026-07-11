---
name: ralph-specum-design
description: Produce technical design for an active Ralph Specum spec with bounded native Codex subagents. Use when the user invokes `$ralph-specum-design` or asks Ralph Specum to design an approved feature.
---

# Ralph Specum Design

1. Resolve the active spec and require approved `requirements.md`.
2. Read requirements, research, repository architecture, related specs, and `progress.md`.
3. Delegate the primary architecture analysis to a read-only native subagent with the `systems architect` role and `strongest` reasoning tier. Add independent integration or verification critics only when useful, with three agents as the maximum.
4. Give each subagent the bounded packet from `../../references/workflow.md`, including objective, role, reasoning tier, inputs, allowed files, read-only permission, acceptance criteria, verification command, evidence, and prohibitions on shared state and Git.
5. Require `Answer`, `Evidence`, `Risks`, `Verification performed`, and `Changed files`. Reject unsupported interfaces or any file mutation.
6. Validate and synthesize results into `design.md` as the root coordinator.
7. Atomically update `progress.md` with `phase: design`, decisions, contracts, risks, and next action. Preserve approval truth until explicit approval.
8. Present the artifact, delegated roles and tiers, and stop for approval unless the current native goal explicitly owns autonomous execution.

Design must cover architecture, interfaces, data flow, failure modes, migration, observability when relevant, and test strategy.
