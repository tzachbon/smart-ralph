# Epic: Engine Roadmap (Specs 3-7)

## Goal

Implement the remaining phases of the engine improvement plan: enforce role boundaries, add Bmalph-style safety infrastructure, bridge BMAD specs, encode agent collaboration patterns, and auto-trigger pair-debug mode — in strict sequential order.

## Vision

Smart Ralph should autonomously handle the full execution lifecycle: enforce role boundaries mechanically, rollback safely on catastrophe, accept BMAD-generated specs, collaborate with reviewer to solve regressions without human escalation, and enter pair-debug mode when stuck. The human remains arbiter for semantic/product judgment only — all mechanical problems are caught by the engine.

## Specs

---

### Spec 3: `role-boundaries`

**Goal**: Define who can read/write which files during execution and enforce those boundaries mechanically in all agent prompts and the state integrity hook.

**Targets**: I2 (Role Boundary Violations)

**Size**: medium

**Dependencies**: None (first spec in the chain)

**Interface Contracts**:

| Action | File | Detail |
|--------|------|--------|
| Creates | `references/role-contracts.md` | File access matrix: agent → allowed writes, forbidden writes |
| Modifies | `agents/spec-executor.md` | Add role contract reference + DO NOT edit list (spec-executor: cannot touch .ralph-state.json, task_review.md, chat.md) |
| Modifies | `agents/external-reviewer.md` | Add role contract reference + DO NOT edit list (external-reviewer: cannot touch .ralph-state.json, tasks.md) |
| Modifies | `agents/qa-engineer.md` | Add role contract reference + DO NOT edit list (qa-engineer: cannot touch .ralph-state.json, tasks.md, task_review.md) |
| Modifies | `agents/spec-reviewer.md` | Add role contract reference + DO NOT edit list (spec-reviewer: cannot touch code, tests, .ralph-state.json, tasks.md, task_review.md) |

**Key Changes** (from roadmap Section 6):
1. Create role contract file (`references/role-contracts.md`) with file access matrix
2. Add "See role-contracts.md for file access rules" + explicit DO NOT edit lists to 4 agent files
3. State integrity hook to detect unauthorized .ralph-state.json modifications

---

### Spec 4: `loop-safety-infra`

**Goal**: Add Bmalph-style pre-loop git checkpoint, circuit breaker, per-task metrics, read-only detection, and CI snapshot tracking to the execution loop.

**Targets**: I3 (Missing Bmalph-Style Safety Infra), C4 (CI snapshot tracking)

**Size**: medium

**Dependencies**: Spec 1 (schema fields: nativeTaskMap, nativeSyncEnabled, nativeSyncFailureCount must exist; Spec 4 adds `ciCommands` to the same schema)

**Interface Contracts**:

| Action | File | Detail |
|--------|------|--------|
| Creates | `references/loop-safety.md` | All safety rules: checkpoint, circuit breaker, metrics, read-only detection |
| Creates | `hooks/scripts/checkpoint.sh` | Git checkpoint utilities (pre-loop save, rollback by SHA) |
| Modifies | `hooks/scripts/stop-watcher.sh` | Add circuit breaker logic, metrics append, read-only heartbeat write check |
| Modifies | `schemas/spec.schema.json` | Add `ciCommands: string[]` field for discovered CI commands |
| Modifies | `commands/implement.md` | Pre-loop git checkpoint step before execution starts |

**Key Changes** (from roadmap Section 6):
1. Pre-loop git checkpoint: `git add -A && git commit -m "checkpoint: before $spec execution"`, store SHA in state
2. Circuit breaker: stop after N consecutive failures (default 5) or N hours (default 48h)
3. Metrics append: `specs/<name>/.metrics.jsonl` with per-task performance data
4. Read-only detection: heartbeat write check at loop start
5. CI snapshot tracking: auto-detect CI commands from project config, record global CI state separate from task verify

---

### Spec 5: `bmad-bridge-plugin`

**Goal**: Create a BMAD→smart-ralph structural mapper plugin that converts BMAD artifacts (PRD, epics/stories, architecture decisions) into smart-ralph spec files.

**Targets**: S1 (No BMAD Integration)

**Size**: medium

**Dependencies**: None (completely independent — no shared files with any other spec)

**Interface Contracts**:

| Action | File | Detail |
|--------|------|--------|
| Creates | `plugins/ralph-bmad-bridge/.claude-plugin/plugin.json` | Plugin manifest |
| Creates | `plugins/ralph-bmad-bridge/commands/` | `/ralph-bmad:import` command |
| Creates | `plugins/ralph-bmad-bridge/scripts/` | Mapping logic scripts |
| Creates | (via command) `specs/<name>/requirements.md` | Mapped from BMAD PRD + user stories |
| Creates | (via command) `specs/<name>/design.md` | Mapped from BMAD architecture decisions |
| Creates | (via command) `specs/<name>/tasks.md` | Mapped from BMAD epic breakdown (test scenario mapping deferred — requires LLM synthesis) |

**Key Changes** (from roadmap Section 6):
1. Create `plugins/ralph-bmad-bridge/` plugin directory following standard plugin structure
2. Structural mapper (not AI prompts): BMAD artifacts → smart-ralph spec format
3. Entry point: `/ralph-bmad:import <bmad-project-path> <spec-name>`
4. Mapping table: PRD → requirements.md, ADRs → design.md, epic breakdown → tasks.md. Deferred to v0.2+: user stories → verification contract, test scenarios → Verify commands (require LLM synthesis, see Out of Scope in requirements.md)

---

### Spec 6: `collaboration-resolution`

**Goal**: Encode the ad-hoc agent collaboration pattern (discovered in live execution) into explicit, repeatable rules: cross-branch regression workflow, experiment-propose-validate chat pattern, BUG_DISCOVERY-triggered fix tasks, and new chat signals.

**Targets**: New gap — agents collaborating to solve regressions without human escalation

**Size**: medium

**Dependencies**: Spec 3 (modifies the same agent files: spec-executor.md gets cross-branch investigation rules after Spec 3's file restrictions; external-reviewer.md gets collaboration rules after Spec 3's role contract reference)

**Interface Contracts**:

| Action | File | Detail |
|--------|------|--------|
| Creates | `references/collaboration-resolution.md` | Cross-branch regression workflow, experiment pattern, chat signals |
| Creates | (signals in) `templates/chat.md` | HYPOTHESIS, EXPERIMENT, FINDING, ROOT_CAUSE, FIX_PROPOSAL, BUG_DISCOVERY |
| Modifies | `references/failure-recovery.md` | Extend fix task generation: BUG_DISCOVERY entry in task_review.md triggers fix task |
| Modifies | `templates/chat.md` | Add new collaboration signals to signal legend table |
| Modifies | `agents/spec-executor.md` | Reference collaboration-resolution for cross-branch investigation workflow |
| Modifies | `agents/external-reviewer.md` | Add "before modifying tests, check baseline" hard rule + reference collaboration-resolution |

**Key Changes** (from roadmap Section 6):
1. Cross-branch regression workflow: `git diff main...HEAD` on failing test code path, identify semantic break, propose fix
2. Experiment-propose-validate pattern: formalized in collaboration-resolution.md with new chat signals
3. Auto-fix-task for discovered bugs: reviewer writes BUG_DISCOVERY to task_review.md, coordinator generates fix task
4. Chat signals extension: HYPOTHESIS, EXPERIMENT, FINDING, ROOT_CAUSE, FIX_PROPOSAL, BUG_DISCOVERY
5. "Before modifying tests, check baseline" rule in external-reviewer.md

---

### Spec 7: `pair-debug-auto-trigger`

**Goal**: Add automatic pair-debug mode trigger (3-condition check) and Driver/Navigator role split so agents collaborate on hard bugs without human push.

**Targets**: Critical gap — collaboration currently requires human push; needs auto-trigger

**Size**: small-medium

**Dependencies**: Spec 6 (depends on Spec 6's collaboration signals and BUG_DISCOVERY pattern), Spec 3 (reads Spec 3's role restriction additions to spec-executor.md before adding its own debug logging section)

**Interface Contracts**:

| Action | File | Detail |
|--------|------|--------|
| Creates | `references/pair-debug.md` | Auto-trigger condition (3 conditions), Driver/Navigator roles |
| Creates | (announcement in) `references/failure-recovery.md` | "First fix failed → escalate to pair" pattern |
| Modifies | `references/failure-recovery.md` | Extend to announce pair-debug mode before fix task (pre-existing test failures, taskIteration >= 2) |
| Modifies | `agents/spec-executor.md` | Add debug logging as first-class investigation technique in pair-debug mode |
| Modifies | `references/coordinator-pattern.md` | Add pair-debug mode announcement to signal handling |

**Key Changes** (from roadmap Section 6):
1. Auto-detect pair-debug mode: test was green→red + test unchanged + fix attempt failed (taskIteration >= 2) + reviewer didn't mark FAIL
2. Driver/Navigator split: Driver = spec-executor (writes code, runs commands), Navigator = external-reviewer (reads diff, proposes hypotheses)
3. Debug logging as first-class technique: spec-executor may add temporary `_LOGGER.warning()` / `console.log()` in pair mode, must clean up before task complete
4. "First fix failed → escalate to pair": when taskIteration >= 2 AND failing test is pre-existing, announce pair-debug mode in chat.md before fix task
5. Coordinator announces pair mode: writes PAIR-DEBUG MODE ACTIVATED to chat.md with Driver/Navigator roles and trigger summary

---

## Dependency Graph

```
Spec 3 (role-boundaries)
  │
  ├── Modifies: agents/spec-executor.md, agents/external-reviewer.md, agents/qa-engineer.md, agents/spec-reviewer.md
  ├── Creates: references/role-contracts.md
  │
  ▼
Spec 4 (loop-safety-infra)
  │
  ├── Modifies: hooks/scripts/stop-watcher.sh, schemas/spec.schema.json, commands/implement.md
  ├── Creates: references/loop-safety.md, hooks/scripts/checkpoint.sh
  │
  ▼
Spec 5 (bmad-bridge-plugin)
  │
  ├── Creates: plugins/ralph-bmad-bridge/ (entirely new plugin, no file conflicts)
  │
  ▼
Spec 6 (collaboration-resolution)
  │
  ├── Modifies: references/failure-recovery.md, templates/chat.md
  ├── Modifies: agents/spec-executor.md, agents/external-reviewer.md
  ├── Creates: references/collaboration-resolution.md
  │
  ▼
Spec 7 (pair-debug-auto-trigger)
  │
  ├── Modifies: references/failure-recovery.md, agents/spec-executor.md, references/coordinator-pattern.md
  ├── Creates: references/pair-debug.md
  └── Depends on: Spec 6's BUG_DISCOVERY signals in failure-recovery.md and chat.md
```

**Shared files** (modifications are additive to different sections):
- `agents/spec-executor.md` — Specs 3, 6, 7 (different sections)
- `agents/external-reviewer.md` — Specs 3, 6 (different sections)
- `references/failure-recovery.md` — Specs 6, 7 (different sections)

## Execution Order

```
Spec 3 → Spec 4 → Spec 5 → Spec 6 → Spec 7
```

Strict sequential. Spec 7 depends on Spec 6's signals. Specs 3-5 could theoretically run in parallel with each other (different file targets) but sequential order avoids any risk of merge conflicts on shared agent files.

## Risks

| Spec | Risk | Severity | Mitigation |
|------|------|----------|------------|
| 3 | Agent file modifications (4 files) could conflict with future Specs 6/7 changes | High | Use clearly sectioned additions with frontmatter markers; add sections at end of files |
| 4 | stop-watcher.sh is 666 lines with complex existing logic (repair loop, regression sweep) | High | Add new features as functions at end of file, don't modify existing logic |
| 5 | New plugin — no shared files | Low | Self-contained, no conflicts possible |
| 6 | Two specs (6 and 7) modify failure-recovery.md | Medium | Spec 7 should read Spec 6's changes first; additive changes in different sections |
| 6 | Modifies templates/chat.md signal legend | Medium | Well-defined addition point (table rows at top of file) |
| 7 | Modifies coordinator-pattern.md (1024 lines) — largest reference file | High | Surgical additions only, new reference file pair-debug.md for details |

## Success Criteria

Criteria relevant to Specs 3-7 (from roadmap Section 8):

| # | Criteria | Spec | How to Verify |
|---|----------|------|--------------|
| 8 | No reviewer editing state files | 3 | Role contract in all agent files. Test: ask reviewer to edit .ralph-state.json — it must refuse. |
| 9 | Rollback available | 4 | Pre-loop checkpoint SHA stored in .ralph-state.json. Test: run spec, break code, `git reset --hard <SHA>` restores. |
| 10 | Circuit breaker stops runaway loops | 4 | After N consecutive failures, execution stops with error. Test: create spec with failing tasks, verify stop. |
| 11 | Metrics visible | 4 | `.metrics.jsonl` file exists after execution with per-task entries. |
| 12 | BMAD specs accepted | 5 | `/ralph-bmad:import` produces valid spec in `specs/<name>/` that `/ralph-specum:implement` can execute. |
| 14 | Cross-branch regression solved autonomously | 6 | When test passes on main but fails on HEAD (no test/fixture changes), agents follow collaboration workflow to find root cause. |
| 15 | BUG_DISCOVERY creates fix tasks | 6 | Reviewer writes BUG_DISCOVERY to task_review.md, coordinator generates fix task. |
| 16 | Pair-debug auto-triggers without human push | 7 | When pre-existing test fails and first fix fails (taskIteration >= 2), pair-debug mode activates automatically. |
| 17 | Driver/Navigator produces root cause | 7 | In pair-debug mode, Driver instruments code, Navigator analyzes diff, they exchange hypotheses and converge on root cause. |
| 18 | Debug logging added and cleaned up | 7 | Debug logging used in pair mode, removed (or converted to tests) before task completion. |
