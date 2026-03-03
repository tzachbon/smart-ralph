# Research: task-granularity-levels

## Executive Summary

Task granularity in ralph-specum is currently hardcoded to produce 40-60+ fine-grained tasks per spec, which creates excessive context-injection overhead for sequential execution (~2-3M tokens for a 12-file feature). The task-planner agent enforces max 4 Do steps and 3 files per task, with [VERIFY] checkpoints every 2-3 tasks consuming full iteration cycles for trivial lint commands.

The solution is configurable granularity levels (fine/coarse/auto) that adjust task sizing rules, checkpoint frequency, and target task counts. The "auto" mode detects whether parallel dispatch is available (fine if yes, coarse if no). All changes are localized to the task-planner agent prompt and command flag parsing — no stop-watcher or hook infrastructure changes needed.

## External Research

### Best Practices
- **Optimal task size**: 20-50 lines of code changes per task yields 85% first-try success rate; 200+ lines drops to 35%
- **Granularity spectrum**: Coarse (2-5 tasks) for simple/familiar work; balanced (5-8) for typical features; fine (10-15+) for complex/parallel execution
- **Recovery semantics**: Fine granularity enables single-task retry (5-10% failure rate requiring more than retry) vs coarse (30-50% requiring full restart)

### Prior Art
- Industry tools (Cursor, Copilot Workspace, SWE-agent) generally generate balanced granularity (5-8 logical units)
- Fine granularity shines for parallel dispatch and distributed execution
- Coarse granularity preferred when verification is strong and executor is experienced

### Pitfalls to Avoid
- Over-decomposition: 1-2 line changes as separate tasks waste more on context switching than they save
- Under-decomposition: 200+ LOC tasks have high failure rates and poor recovery
- Checkpoint overhead: Each [VERIFY] task in the stop-hook loop costs ~50K tokens for a 2-second lint command

## Codebase Analysis

### Task Planner Agent (agents/task-planner.md)
**Current hardcoded constraints (lines 512-541)**:
- Max 4 steps in Do section
- Max 3 files per task
- Target: 40-60+ tasks (the root cause of issue #99)
- [VERIFY] checkpoints every 2-3 tasks

**Workflow selection**: GREENFIELD → POC-first (5 phases); TRIVIAL/REFACTOR/MID_SIZED → TDD Red-Green-Yellow

**Extension point**: The "Task Sizing Rules" section is where granularity-dependent values replace hardcoded targets.

### Commands (commands/tasks.md, commands/start.md)
- Flags parsed from `$ARGUMENTS` via simple string matching
- Existing flags: `--quick`, `--fresh`, `--commit-spec`, `--no-commit-spec`, `--specs-dir`
- `--granularity` follows same pattern: parse from args, store in `.ralph-state.json`, pass to task-planner
- `tasks.md` command accepts optional spec name + flags, delegates to task-planner team

### Stop Watcher (hooks/scripts/stop-watcher.sh)
- No changes needed for granularity — it just reads taskIndex and extracts the current task block
- [VERIFY] tasks treated identically to regular tasks in the loop (distinction at coordinator level)
- Parallel [P] groups already detected and bundled for dispatch

### Hook Infrastructure (hooks/hooks.json)
- Current hooks: PreToolUse (quick-mode-guard), Stop (stop-watcher), SessionStart (load-spec-context)
- No verification hooks currently — all verification via [VERIFY] tasks in task flow
- User decision: keep [VERIFY] as opt-in tasks, don't convert to hooks

### .ralph-state.json Schema
- Add `granularity: "fine"|"coarse"|"auto"` field
- Backwards compatible: default to "fine" when field missing (preserves current behavior)
- Read by tasks.md command to pass to task-planner delegation

## Related Specs

| Spec | Relevance | Relationship | May Need Update |
|------|-----------|-------------|-----------------|
| improve-task-generation | High | Set current 40-60+ target and sizing rules; granularity extends this | Yes - sizing rules become granularity-dependent |
| qa-verification | Medium | Introduced [VERIFY] tasks and qa-engineer agent | No - orthogonal; checkpoint frequency changes in task-planner |
| parallel-task-execution | Medium | [P] markers and parallel dispatch; fine granularity enables better parallelism | No - works independently |
| fix-impl-context-bloat | Low | Addressed token bloat in implementation; granularity reduces it differently | No |

## Quality Commands

| Type | Command | Source |
|------|---------|--------|
| Version check | Plugin version validation | CI workflow |
| Spec validation | Schema consistency check | CI workflow |
| Shell tests | bats test framework | CI workflow |
| Lint | N/A (plugin repo, not npm) | — |
| Typecheck | N/A | — |

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|-----------|-------|
| Technical complexity | Low | Changes localized to task-planner prompt + command flag parsing |
| Risk | Low | Backwards compatible; default preserves current behavior |
| Impact on existing specs | None | Only affects new task generation; existing tasks.md files unaffected |
| Testing | Medium | Need to verify each granularity level produces expected task counts |
| Effort | Small-Medium | ~5-8 files to modify, all markdown/JSON |

## Recommendations for Requirements

1. **Three granularity levels**: fine (40-60+ tasks, current default), coarse (10-20 tasks), auto (detect parallel)
2. **Flag on /start + /tasks**: `--granularity fine|coarse|auto`; start passes through, tasks reads from state
3. **Interview question**: Ask during tasks interview with fine pre-selected (user preference for many tasks)
4. **[VERIFY] opt-in**: Only generate intermediate checkpoints in fine mode; final V4-V6 always generated
5. **Auto detection**: Check for parallel dispatch plugin availability; fine if available, coarse if not
6. **Plugin setting**: Optional `default_granularity` in `.claude/ralph-specum.local.md`
7. **Task sizing per level**:
   - Fine: max 4 steps, 3 files, 40-60+ tasks, [VERIFY] every 2-3
   - Coarse: max 8-10 steps, 5-6 files, 10-20 tasks, no intermediate [VERIFY]
   - Auto: resolves to fine or coarse based on detection

## Open Questions

1. How should auto mode detect parallel plugin availability? Check for specific files/config?
2. Should coarse mode still generate [P] markers for tasks that could parallelize?
3. What happens if user switches granularity mid-spec (e.g., re-runs /tasks with different flag)?

## Sources

- GitHub Issue #99: https://github.com/tzachbon/smart-ralph/issues/99
- plugins/ralph-specum/agents/task-planner.md (task sizing rules)
- plugins/ralph-specum/commands/tasks.md (command structure)
- plugins/ralph-specum/commands/start.md (flag parsing)
- plugins/ralph-specum/hooks/scripts/stop-watcher.sh (execution loop)
- plugins/ralph-specum/hooks/hooks.json (hook infrastructure)
- specs/improve-task-generation/ (related spec)
- specs/qa-verification/ (related spec)
- specs/parallel-task-execution/ (related spec)
