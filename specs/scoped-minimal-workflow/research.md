---
spec: scoped-minimal-workflow
phase: research
created: 2026-08-27
generated: auto
---

# Research: scoped-minimal-workflow

## Executive Summary

Ralph Specum already carries simplicity and surgical-change rules. The smallest useful addition is a reuse-first choice inside the three agents that design, plan, and execute work. Scope needs one durable carrier: a six-field block in `.progress.md`, enforced by intake, planning, execution, and the coordinator's existing `awaitingApproval` stop path.

This is a medium-sized prompt change with low runtime risk. It needs no dependency, new skill, state-schema field, hook change, or Codex-plugin change.

## External Research

### Best Practices

- The user supplied Ponytail as the source for a reuse-first choice and Stay in scope as the source for a positive authorization boundary.
- No public research is required. The repository's current prompts, tests, and workflow files are the source of truth for integration.

### Prior Art

- `specs/karpathy-skills-rules/` added general simplicity and surgical-change behavior. This spec extends missing operational rules instead of repeating that content.
- Existing Bats tests use literal prompt-contract assertions, including `tests/interview-framework.bats` and `tests/start-command.bats`.

### Pitfalls to Avoid

- A new skill would be conditional on skill discovery and would not govern every workflow.
- A new hook rule would duplicate the existing `awaitingApproval` stop behavior in `hooks/scripts/stop-watcher.sh:225-232`.
- Prompt tests can prove contract presence and routing, not deterministic model behavior.

## Codebase Analysis

### Existing Patterns

- `plugins/ralph-specum/skills/spec-workflow/SKILL.md:21-38` defines `start -> research -> requirements -> design -> tasks -> implement`.
- `plugins/ralph-specum/commands/start.md:161-205` creates `.progress.md`; `start.md:238-240` runs the normal goal interview before research.
- `plugins/ralph-specum/references/quick-mode.md:60-120` creates progress state, then begins reproduction and research without the normal interview.
- `plugins/ralph-specum/commands/new.md:77-86,150-204` creates progress state and starts research through a separate public path.
- Research, requirements, design, and tasks commands read `.progress.md` before delegation: `commands/research.md:23-29`, `commands/requirements.md:22-29`, `commands/design.md:22-29`, and `commands/tasks.md:22-35`.
- `plugins/ralph-specum/commands/tasks.md:86-120` sends progress context to task-planner.
- `plugins/ralph-specum/references/coordinator-pattern.md:212-237` sends progress context and one task block to spec-executor.
- `plugins/ralph-specum/agents/spec-executor.md:16-29` reads that context before mutation.
- `plugins/ralph-specum/references/coordinator-pattern.md:571-624` can add prerequisite and follow-up tasks during execution.
- `plugins/ralph-specum/hooks/scripts/stop-watcher.sh:225-232` already stops when `awaitingApproval` is true.

### Dependencies

- Reuse `.progress.md`, `.ralph-state.json.awaitingApproval`, agent prompts, coordinator instructions, Bats, and GitHub Actions already in the repository.
- Add no package or plugin component.

### Constraints

- `CLAUDE.md:68-76` requires one semantic version increase in the Ralph Specum manifest and marketplace entry for any plugin change.
- Current Ralph Specum version is `4.10.5`; this behavioral feature uses `4.11.0`.
- `plugins/ralph-specum/references/phase-rules.md:117-176` requires TDD for non-greenfield work.
- `plugins/ralph-specum/references/sizing-rules.md:35-65` permits 8-15 coarse TDD tasks with checkpoints every 2-3 tasks.
- The Codex plugin has separate prompts and versioning and remains out of scope.

## Related Specs

| Spec | Relevance | Relationship | May Need Update |
|---|---|---|---|
| `karpathy-skills-rules` | High | Existing simplicity and surgical-change baseline | No |
| `goal-interview` | High | Existing normal intake and progress persistence | No |

### Coordination Notes

Extend the current rule owners. Do not add a parallel policy store or rewrite either related spec.

## Feasibility Assessment

| Aspect | Assessment | Notes |
|---|---|---|
| Technical Viability | High | Active prompt seams and the stop-state path already exist. |
| Effort Estimate | M | Seven production prompt files, one Bats file, two version entries, and spec artifacts. |
| Risk Level | Low | No dependency, build, data migration, or new hook behavior. |

## Verification Tooling

| Purpose | Command | Source |
|---|---|---|
| New contract | `bats tests/workflow-guardrails.bats` | Bats pattern in `tests/interview-framework.bats:21-113` |
| Focused workflow regression | `bats tests/interview-framework.bats tests/integration.bats tests/stop-hook.bats` | Existing workflow suites |
| Full regression | `bats tests/*.bats` | `.github/workflows/bats-tests.yml:21-36` |
| JSON validity | `python3 -m json.tool plugins/ralph-specum/.claude-plugin/plugin.json >/dev/null && python3 -m json.tool .claude-plugin/marketplace.json >/dev/null` | Modified manifests |
| Diff integrity | `git diff --check` | Repository contribution gate |
| Plugin smoke test | `claude --plugin-dir ./plugins/ralph-specum` then `/ralph-specum:start test-feature Some test goal` | `CONTRIBUTING.md:72-77` |

The full Bats run can update `specs/.index`. Inspect `git status --short` after the suite and keep unrelated generated changes out of the pull request.

## Recommendations for Requirements

1. Persist target, action authority, bounds, deliverable, completion condition, and escalation trigger in one `## Scope Envelope` block before research.
2. Treat missing scope or required expansion as `SCOPE_ESCALATION_REQUIRED`, then use the coordinator to set `awaitingApproval` without consuming a retry.
3. Add a four-step reuse-first choice to architect, planner, and executor prompts; keep safety and verification requirements intact.
4. Pin the active seams with one Bats contract file and bump Ralph Specum to `4.11.0`.

## Open Questions

None. Quick mode uses the plugin-only scope recorded in `.progress.md`.

## Sources

- `plugins/ralph-specum/references/goal-interview.md`
- `plugins/ralph-specum/references/quick-mode.md`
- `plugins/ralph-specum/agents/architect-reviewer.md`
- `plugins/ralph-specum/agents/task-planner.md`
- `plugins/ralph-specum/agents/spec-executor.md`
- `plugins/ralph-specum/references/coordinator-pattern.md`
- `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
- `.github/workflows/plugin-version-check.yml`
