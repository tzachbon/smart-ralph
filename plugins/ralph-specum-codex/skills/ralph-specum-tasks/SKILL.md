---
name: ralph-specum-tasks
description: Create an implementation task plan for an active Ralph Specum design with bounded native Codex subagents. Use when the user invokes `$ralph-specum-tasks` or asks Ralph Specum to plan implementation tasks.
---

# Ralph Specum Tasks

1. Resolve the active spec and require approved `requirements.md` and `design.md`.
2. Read research, requirements, design, repository guidance, and `progress.md`.
3. Delegate task decomposition to at least one read-only native subagent with the `task decomposer` role and `light` reasoning tier. Add a `medium` dependency or verification reviewer only when the design is cross-cutting or unusually risky, with three agents as the maximum.
4. Give each subagent the bounded packet from `../../references/workflow.md`, including objective, role, reasoning tier, inputs, allowed files, read-only permission, acceptance criteria, verification command, evidence, and prohibitions on `tasks.md`, `progress.md`, shared state, and Git.
5. Require `Answer`, `Evidence`, `Risks`, `Verification performed`, and `Changed files`. Reject file mutation or unverifiable task proposals.
6. As the root coordinator, write `tasks.md` with unchecked boxes as the authoritative backlog.
7. Group work into coherent verified batches. Mark parallel candidates only when files are disjoint and verification is independent.
8. Give every task allowed files, acceptance criteria, and a verification command. Do not require one commit per small task.
9. Atomically update `progress.md` with `phase: tasks`, the verification strategy, blockers, and next action. Preserve approval truth until explicit approval.
10. Present the artifact, delegated roles and tiers, and stop for approval unless the current native goal explicitly owns autonomous execution.
