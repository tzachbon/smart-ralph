---
name: ralph-specum-requirements
description: Produce requirements for an active Ralph Specum spec with bounded native Codex subagents. Use when the user invokes `$ralph-specum-requirements` or asks Ralph Specum to define requirements.
---

# Ralph Specum Requirements

1. Resolve the active spec and require approved research or explicit user permission to proceed without it.
2. Read the goal, `research.md`, user decisions, related specs, and `progress.md`.
3. Delegate substantive requirements analysis to at least one read-only native subagent with the `product and constraint analyst` role and `medium` reasoning tier. Upgrade a packet to `strongest` when it governs a security boundary, irreversible migration, novel cross-domain contract, or materially conflicting evidence. Add independent compatibility or risk agents only when needed, with three agents as the maximum.
4. Give each subagent the bounded packet from `../../references/workflow.md`, including objective, role, reasoning tier, dependency inputs, allowed files, read-only permission, acceptance criteria, verification command, evidence, and prohibitions on shared state and Git.
5. Require `Answer`, `Evidence`, `Risks`, `Verification performed`, and `Changed files`. Reject unsupported requirements and any file mutation.
6. Validate and synthesize results into `requirements.md` as the root coordinator.
7. Atomically update `progress.md` with `phase: requirements`, decisions, exclusions, blockers, and next action. Preserve approval truth until explicit approval.
8. Present the artifact, delegated roles and tiers, and stop for approval unless the current native goal explicitly owns autonomous execution.

Requirements must include user outcomes, acceptance criteria, functional and non-functional constraints, dependencies, exclusions, and measurable success.
