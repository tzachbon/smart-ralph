# Spec Index

Auto-generated summary of all specs across configured directories.
See [index-state.json](./index-state.json) for machine-readable data.

**Last updated:** 2026-03-03T18:14:05Z

## Directories (1)

| Directory | Specs | Default |
|-----------|-------|---------|
| ./specs | 26 | Yes |

## All Specs (26)

| Spec | Directory | Phase | Status |
|------|-----------|-------|--------|
| parallel-tasks-execution | ./specs | tasks | 46/62 tasks |
| add-skills-doc | ./specs | completed | done |
| enforce-teams-instead | ./specs | completed | done |
| improve-task-generation | ./specs | tasks | 66/68 tasks |
| fix-impl-context-bloat | ./specs | tasks | 47/48 tasks |
| plan-source-feature | ./specs | completed | done |
| implement-ralph-wiggum | ./specs | tasks | 27/35 tasks |
| fork-ralph-wiggum | ./specs | completed | done |
| reality-verification-principle | ./specs | tasks | 9/11 tasks |
| karpathy-skills-rules | ./specs | completed | done |
| speckit-stop-hook | ./specs | tasks | 9/12 tasks |
| task-granularity-levels | ./specs | completed | done |
| qa-verification | ./specs | completed | done |
| ralph-speckit | ./specs | completed | done |
| multi-spec-dirs | ./specs | tasks | 30/33 tasks |
| codebase-indexing | ./specs | completed | done |
| parallel-task-execution | ./specs | tasks | 24/25 tasks |
| iterative-failure-recovery | ./specs | tasks | 14/20 tasks |
| reviewer-subagent | ./specs | completed | done |
| goal-interview | ./specs | completed | done |
| adaptive-interview | ./specs | completed | done |
| add-autonomous-e2e-verify | ./specs | tasks | 54/55 tasks |
| remove-ralph-wiggum | ./specs | completed | done |
| smart-skill-swap-retry | ./specs | tasks | 21/26 tasks |
| improve-walkthrough-feature | ./specs | tasks | 13/14 tasks |
| when-creating-worktree | ./specs | completed | done |
| epic-triage | ./specs | execution | 11/11 tasks |
| test-spec | ./specs | new |  |

## Indexed Components (12)

| Component | Category | Source |
|-----------|----------|--------|
| agent-architect-reviewer | agents | plugins/ralph-specum/agents/architect-reviewer.md |
| agent-product-manager | agents | plugins/ralph-specum/agents/product-manager.md |
| agent-qa-engineer | agents | plugins/ralph-specum/agents/qa-engineer.md |
| agent-research-analyst | agents | plugins/ralph-specum/agents/research-analyst.md |
| agent-spec-executor | agents | plugins/ralph-specum/agents/spec-executor.md |
| agent-task-planner | agents | plugins/ralph-specum/agents/task-planner.md |
| agent-triage-analyst | agents | plugins/ralph-specum/agents/triage-analyst.md |
| command-implement | commands | plugins/ralph-specum/commands/implement.md |
| command-start | commands | plugins/ralph-specum/commands/start.md |
| command-triage | commands | plugins/ralph-specum/commands/triage.md |
| hook-stop-watcher | hooks | plugins/ralph-specum/hooks/scripts/stop-watcher.sh |
| reference-triage-flow | references | plugins/ralph-specum/references/triage-flow.md |

---

**Commands:**
- `/ralph-specum:status` - Show detailed status
- `/ralph-specum:switch <name>` - Switch active spec
- `/ralph-specum:start <name>` - Create or resume spec
- `/ralph-specum:triage <goal>` - Decompose large features into multiple specs
