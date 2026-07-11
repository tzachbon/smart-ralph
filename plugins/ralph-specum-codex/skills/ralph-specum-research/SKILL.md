---
name: ralph-specum-research
description: Research an active Ralph Specum spec with bounded native Codex subagents. Use when the user invokes `$ralph-specum-research` or asks Ralph Specum to research a spec.
---

# Ralph Specum Research

1. Resolve the active spec with `../../scripts/resolve_spec_paths.py` relative to this skill.
2. Read the goal, existing artifacts, repository guidance, related specs, and `progress.md`.
3. Delegate substantive research to at least one read-only native subagent. Use the `medium` reasoning tier and `evidence investigator` role by default. Upgrade a packet to `strongest` for a security boundary, irreversible migration, novel cross-domain architecture, or materially conflicting evidence, and record why. Split independent questions across two or three agents when useful, with three as the maximum.
4. Give each subagent the exact bounded packet from `../../references/workflow.md`, including objective, role, reasoning tier, inputs, allowed files, read-only permission, acceptance criteria, verification command, evidence, and prohibitions on shared state and Git.
5. Require every result to contain `Answer`, `Evidence`, `Risks`, `Verification performed`, and `Changed files`. Reject unexpected changes or unsupported claims.
6. Validate and synthesize results into `research.md` as the root coordinator.
7. Atomically update `progress.md` with `phase: research`, evidence, risks, and next action. Do not alter `approved_through` until the user approves.
8. Present the artifact, delegated roles and tiers, and stop for approval unless the current native goal explicitly owns autonomous execution.

Research must cover existing patterns, constraints, dependencies, material risks, verification options, and a recommendation.
