---
name: ralph-specum-triage
description: Decompose a large Ralph Specum effort into dependency-aware specs using bounded native Codex subagents. Use when the user invokes `$ralph-specum-triage` or asks Ralph Specum to triage a broad or cross-cutting effort.
---

# Ralph Specum Triage

1. Resolve the repository and existing spec roots. Inspect existing specs before proposing new boundaries.
2. Delegate the primary decomposition to a read-only native subagent with the `decomposition architect` role and `strongest` reasoning tier. Add independent code-seam or product-slice investigators only when useful, with three agents as the maximum.
3. Give each subagent the bounded packet from `../../references/workflow.md`, including objective, role, reasoning tier, inputs, allowed files, read-only permission, acceptance criteria, verification command, evidence, and prohibitions on shared state and Git.
4. Require `Answer`, `Evidence`, `Risks`, `Verification performed`, and `Changed files`. Reject mutation or unsupported dependency claims.
5. Validate and synthesize one epic plan with independently deliverable specs, stable contracts, dependency order, and explicit blockers.
6. As the root coordinator, write the epic artifacts and `progress.md`. Do not implement any spec during triage.
7. Present the epic, delegated roles and tiers, and next unblocked spec, then stop for approval unless the current native goal explicitly owns autonomous execution.

Prefer vertical, independently verifiable slices. Avoid speculative infrastructure specs without a consumer.
