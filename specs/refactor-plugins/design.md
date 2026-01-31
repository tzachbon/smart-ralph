---
spec: refactor-plugins
phase: design
created: 2026-01-29
updated: 2026-01-29
---

# Design: Plugin Refactoring to Best Practices

## Overview

Two-phase refactoring: (1) Add missing frontmatter fields (color, version, matcher) and example blocks. (2) Consolidate procedural logic from commands/agents INTO skills. Commands become thin wrappers; agents reference skills for expertise.

## Design Inputs (Interview Responses)

| Parameter | Value |
|-----------|-------|
| Architecture style | Edit files in place |
| Technology constraints | Bash only for validation |
| Integration approach | Minimal - frontmatter/metadata only |
| New direction | Consolidate heavy-lifting into skills |

## Skill Consolidation Strategy

### Current State Analysis

**Commands** (heavy - 100-1200 lines each):
- `implement.md`: 1200+ lines of coordinator logic, recovery orchestration, state machine
- `research.md`: 700+ lines including parallel research patterns, merge logic
- `start.md`: 980+ lines with branch management, quick mode, intent classification
- `design.md`, `requirements.md`, `tasks.md`: 250-300 lines each with interview patterns

**Agents** (moderate - 250-500 lines each):
- `spec-executor.md`: 440 lines with execution rules, phase-specific rules, commit discipline
- `task-planner.md`: 520 lines with POC workflow, quality checkpoints, VF task generation
- `research-analyst.md`: 340 lines with quality command discovery, methodology
- `architect-reviewer.md`: 250 lines with design structure template

**Skills** (light - 50-200 lines each):
- `interview-framework`: 200 lines - already well-consolidated
- `communication-style`: 105 lines - good
- `delegation-principle`: 48 lines - good
- `spec-workflow`: 45 lines - just command reference
- `reality-verification`: ~100 lines - good
- `smart-ralph`: ~100 lines - good

### Consolidation Goals

| Goal | Benefit |
|------|---------|
| Skills = reusable knowledge | Referenced by multiple commands/agents |
| Commands = thin orchestration | ~50-100 lines max, delegate to skills |
| Agents = focused expertise | Reference skills, don't duplicate patterns |

### Content Migration Matrix

| Source | Content to Extract | New Skill | Lines Saved |
|--------|-------------------|-----------|-------------|
| implement.md | Recovery orchestration (6b-6d) | `failure-recovery` | ~400 |
| implement.md | Verification layers (7) | `verification-layers` | ~70 |
| implement.md | Coordinator prompt pattern | `coordinator-pattern` | ~150 |
| start.md | Branch management logic | `branch-management` | ~200 |
| start.md | Intent classification | `intent-classification` | ~100 |
| start.md | Spec scanner | `spec-scanner` | ~80 |
| research.md | Parallel execution pattern | `parallel-research` | ~300 |
| research.md | Merge results algorithm | (in parallel-research) | ~100 |
| spec-executor.md | Phase-specific rules | `phase-rules` | ~50 |
| spec-executor.md | Commit discipline | `commit-discipline` | ~60 |
| task-planner.md | POC-first workflow rules | `poc-workflow` | ~80 |
| task-planner.md | Quality checkpoint rules | `quality-checkpoints` | ~100 |
| task-planner.md | VF task generation | (in reality-verification) | ~40 |
| research-analyst.md | Quality command discovery | `quality-commands` | ~80 |

### New Skills to Create

| Skill | Purpose | Referenced By |
|-------|---------|---------------|
| `failure-recovery` | Iterative fix task generation, recovery loop | implement.md, coordinator |
| `verification-layers` | 4-layer verification (contradiction, uncommitted, checkmark, signal) | implement.md, spec-executor |
| `coordinator-pattern` | Task delegation, state management, completion signal | implement.md |
| `branch-management` | Branch creation, worktree setup, naming conventions | start.md |
| `intent-classification` | Goal analysis for question counts | start.md, all phase commands |
| `spec-scanner` | Related specs discovery | start.md, research.md |
| `parallel-research` | Multi-agent research spawning, merge logic | research.md |
| `phase-rules` | POC/Refactor/Testing/Quality phase behaviors | spec-executor, task-planner |
| `commit-discipline` | Commit rules, spec file inclusion | spec-executor |
| `quality-checkpoints` | [VERIFY] task format, frequency rules | task-planner |
| `quality-commands` | Discovery from package.json/Makefile/CI | research-analyst |

### Command Simplification Plan

After consolidation, commands become thin orchestrators:

```markdown
# Before: implement.md (1200 lines)
- Full coordinator prompt inline
- Recovery orchestration logic inline
- Verification layers inline
- State machine inline

# After: implement.md (~150 lines)
1. Determine active spec
2. Validate prerequisites
3. Parse arguments
4. Initialize state
5. Reference skills:
   - Invoke skill: coordinator-pattern
   - Invoke skill: failure-recovery (if --recovery-mode)
   - Invoke skill: verification-layers
6. Invoke Ralph Loop
```

| Command | Before | After | References Skills |
|---------|--------|-------|-------------------|
| implement.md | 1200 | ~150 | coordinator-pattern, failure-recovery, verification-layers |
| start.md | 980 | ~200 | branch-management, intent-classification, spec-scanner, interview-framework |
| research.md | 700 | ~150 | parallel-research, interview-framework |
| design.md | 300 | ~80 | interview-framework |
| requirements.md | 294 | ~80 | interview-framework |
| tasks.md | 314 | ~80 | interview-framework |

### Agent Simplification Plan

Agents reference skills instead of duplicating patterns:

```markdown
# Before: spec-executor.md (440 lines)
- Phase rules inline (50 lines)
- Commit discipline inline (60 lines)
- Verification handling inline (100 lines)

# After: spec-executor.md (~200 lines)
- Core execution logic
- Reference skill: phase-rules
- Reference skill: commit-discipline
- Reference skill: verification-layers (for [VERIFY] tasks)
```

| Agent | Before | After | References Skills |
|-------|--------|-------|-------------------|
| spec-executor.md | 440 | ~200 | phase-rules, commit-discipline, verification-layers |
| task-planner.md | 520 | ~250 | poc-workflow, quality-checkpoints, phase-rules |
| research-analyst.md | 340 | ~200 | quality-commands |
| architect-reviewer.md | 250 | ~200 | (minimal change - mostly template) |

### Skill Reference Pattern

Commands/agents reference skills using:

```markdown
<skill-reference>
**Apply skill**: `skills/failure-recovery/SKILL.md`
Use the failure recovery pattern when spec-executor does not output TASK_COMPLETE and recoveryMode is true.
</skill-reference>
```

Or inline reference:
```markdown
**Failure Recovery**: Apply standard recovery loop from `skills/failure-recovery/SKILL.md`
```

## Change Strategy

**Approach**: Two-phase refactoring
1. **Phase A**: Metadata fixes (original scope) - color, version, matcher, examples
2. **Phase B**: Skill consolidation - extract patterns to skills, simplify commands/agents

**Safety**:
- All changes are additive (add fields, not remove)
- Skill references maintain full behavior
- Backward compatible - existing usage unchanged
- Phase A can be deployed independently

## File Change Matrix

### ralph-specum Agents (8 files)

| File | Add `color` | Add `<example>` blocks |
|------|-------------|------------------------|
| `plugins/ralph-specum/agents/research-analyst.md` | `blue` | 2 examples |
| `plugins/ralph-specum/agents/product-manager.md` | `cyan` | 2 examples |
| `plugins/ralph-specum/agents/architect-reviewer.md` | `blue` | 2 examples |
| `plugins/ralph-specum/agents/task-planner.md` | `cyan` | 2 examples |
| `plugins/ralph-specum/agents/spec-executor.md` | `green` | 2 examples |
| `plugins/ralph-specum/agents/plan-synthesizer.md` | `green` | 2 examples |
| `plugins/ralph-specum/agents/qa-engineer.md` | `yellow` | 2 examples |
| `plugins/ralph-specum/agents/refactor-specialist.md` | `magenta` | 2 examples |

### ralph-speckit Agents (6 files)

| File | Add `color` | Add `<example>` blocks |
|------|-------------|------------------------|
| `plugins/ralph-speckit/agents/constitution-architect.md` | `magenta` | 2 examples |
| `plugins/ralph-speckit/agents/spec-analyst.md` | `blue` | 2 examples |
| `plugins/ralph-speckit/agents/qa-engineer.md` | `yellow` | 2 examples |
| `plugins/ralph-speckit/agents/spec-executor.md` | `green` | 2 examples |
| `plugins/ralph-speckit/agents/plan-architect.md` | `cyan` | 2 examples |
| `plugins/ralph-speckit/agents/task-planner.md` | `cyan` | 2 examples |

### ralph-specum Skills (6 files)

| File | Add `version` | Fix description |
|------|---------------|-----------------|
| `plugins/ralph-specum/skills/communication-style/SKILL.md` | `0.1.0` | No (OK) |
| `plugins/ralph-specum/skills/delegation-principle/SKILL.md` | `0.1.0` | No (OK) |
| `plugins/ralph-specum/skills/interview-framework/SKILL.md` | `0.1.0` | Yes - rewrite |
| `plugins/ralph-specum/skills/reality-verification/SKILL.md` | `0.1.0` | No (OK) |
| `plugins/ralph-specum/skills/smart-ralph/SKILL.md` | `0.1.0` | No (OK) |
| `plugins/ralph-specum/skills/spec-workflow/SKILL.md` | `0.1.0` | No (OK) |

### ralph-speckit Skills (4 files)

| File | Add `version` | Fix description |
|------|---------------|-----------------|
| `plugins/ralph-speckit/skills/communication-style/SKILL.md` | `0.1.0` | Yes - rewrite |
| `plugins/ralph-speckit/skills/delegation-principle/SKILL.md` | `0.1.0` | Yes - rewrite |
| `plugins/ralph-speckit/skills/smart-ralph/SKILL.md` | `0.1.0` | Yes - rewrite |
| `plugins/ralph-speckit/skills/speckit-workflow/SKILL.md` | `0.1.0` | Yes - rewrite |

### Hooks (2 files)

| File | Change |
|------|--------|
| `plugins/ralph-specum/hooks/hooks.json` | Add `"matcher": "*"` to Stop and SessionStart entries |
| `plugins/ralph-speckit/hooks/hooks.json` | Add `"matcher": "*"` to Stop entry |

### ralph-speckit Commands (5 files + 9 legacy)

**Modern commands - add `name` field:**

| File | Add `name` |
|------|-----------|
| `plugins/ralph-speckit/commands/start.md` | `start` |
| `plugins/ralph-speckit/commands/status.md` | `status` |
| `plugins/ralph-speckit/commands/switch.md` | `switch` |
| `plugins/ralph-speckit/commands/cancel.md` | `cancel` |
| `plugins/ralph-speckit/commands/implement.md` | `implement` |

**Legacy commands - migrate from `.claude/commands/` to `commands/`:**

| Source | Destination | Add frontmatter |
|--------|-------------|-----------------|
| `.claude/commands/speckit.analyze.md` | `commands/analyze.md` | name, allowed_tools |
| `.claude/commands/speckit.checklist.md` | `commands/checklist.md` | name, allowed_tools |
| `.claude/commands/speckit.clarify.md` | `commands/clarify.md` | name, allowed_tools |
| `.claude/commands/speckit.constitution.md` | `commands/constitution.md` | name, allowed_tools |
| `.claude/commands/speckit.implement.md` | REMOVE (duplicate) | - |
| `.claude/commands/speckit.plan.md` | `commands/plan.md` | name, allowed_tools |
| `.claude/commands/speckit.specify.md` | `commands/specify.md` | name, allowed_tools |
| `.claude/commands/speckit.tasks.md` | `commands/tasks.md` | name, allowed_tools |
| `.claude/commands/speckit.taskstoissues.md` | `commands/taskstoissues.md` | name, allowed_tools |

**Post-migration**: Remove `plugins/ralph-speckit/.claude/commands/` directory.

### Validation Script (1 new file)

| File | Purpose |
|------|---------|
| `scripts/validate-plugins.sh` | Check compliance, exit non-zero on failure |

### Documentation (1 file)

| File | Change |
|------|--------|
| `CLAUDE.md` | Add plugin best practices reference section |

## Agent Color Assignments

Color grouping by semantic function:

| Color | Function | Agents |
|-------|----------|--------|
| `blue` | Analysis, review, investigation | research-analyst, architect-reviewer, spec-analyst |
| `cyan` | Planning, coordination | product-manager, task-planner (both), plan-architect |
| `green` | Generation, execution | spec-executor (both), plan-synthesizer |
| `yellow` | Validation, quality | qa-engineer (both) |
| `magenta` | Transformation, creative | refactor-specialist, constitution-architect |

## Example Block Format

Each agent gets 2 examples in description:

```markdown
<example>
Context: [Scenario setup]
user: "[User message]"
assistant: "[Claude response about using agent]"
<commentary>
[Why this triggers the agent]
</commentary>
</example>
```

## Validation Script Design

**Location**: `scripts/validate-plugins.sh`

**Checks**:

```bash
#!/bin/bash
# Plugin compliance validation

ERRORS=0

# 1. Check agents have color field
for agent in plugins/*/agents/*.md; do
  if ! grep -q "^color:" "$agent"; then
    echo "FAIL: Missing color in $agent"
    ((ERRORS++))
  fi
done

# 2. Check agents have <example> blocks (at least 2)
for agent in plugins/*/agents/*.md; do
  count=$(grep -c "<example>" "$agent" || echo 0)
  if [ "$count" -lt 2 ]; then
    echo "FAIL: Need 2+ examples in $agent (found $count)"
    ((ERRORS++))
  fi
done

# 3. Check skills have version field
for skill in plugins/*/skills/*/SKILL.md; do
  if ! grep -q "^version:" "$skill"; then
    echo "FAIL: Missing version in $skill"
    ((ERRORS++))
  fi
done

# 4. Check hooks have matcher field
for hooks in plugins/*/hooks/hooks.json; do
  if ! grep -q '"matcher"' "$hooks"; then
    echo "FAIL: Missing matcher in $hooks"
    ((ERRORS++))
  fi
done

# 5. Check no legacy commands remain
if [ -d "plugins/ralph-speckit/.claude/commands" ]; then
  echo "FAIL: Legacy commands directory still exists"
  ((ERRORS++))
fi

# Summary
if [ $ERRORS -eq 0 ]; then
  echo "PASS: All plugins compliant"
  exit 0
else
  echo "FAIL: $ERRORS compliance issues"
  exit 1
fi
```

## Execution Order

### Phase A: Metadata Fixes (Original Scope)

| Step | Tasks | Files |
|------|-------|-------|
| A1 | Fix ralph-specum agents (color + examples) | 8 files |
| A2 | Fix ralph-speckit agents (color + examples) | 6 files |
| A3 | Fix ralph-specum skills (version) | 6 files |
| A4 | Fix ralph-speckit skills (version + descriptions) | 4 files |
| A5 | Fix hooks (matcher) | 2 files |
| A6 | Fix ralph-speckit modern commands (name) | 5 files |
| A7 | Migrate legacy commands | 8 files create |
| A8 | Remove legacy directory | 1 directory |
| A9 | Create validation script | 1 file |
| A10 | Update CLAUDE.md | 1 file |
| QC-A | Run Phase A validation, verify no regressions | - |

### Phase B: Skill Consolidation (New Scope)

| Step | Tasks | Files |
|------|-------|-------|
| B1 | Create failure-recovery skill | 1 skill |
| B2 | Create verification-layers skill | 1 skill |
| B3 | Create coordinator-pattern skill | 1 skill |
| B4 | Create branch-management skill | 1 skill |
| B5 | Create intent-classification skill | 1 skill |
| B6 | Create spec-scanner skill | 1 skill |
| B7 | Create parallel-research skill | 1 skill |
| B8 | Create phase-rules skill | 1 skill |
| B9 | Create commit-discipline skill | 1 skill |
| B10 | Create quality-checkpoints skill | 1 skill |
| B11 | Create quality-commands skill | 1 skill |
| B12 | Simplify implement.md | 1 command |
| B13 | Simplify start.md | 1 command |
| B14 | Simplify research.md | 1 command |
| B15 | Simplify design.md, requirements.md, tasks.md | 3 commands |
| B16 | Simplify spec-executor.md | 1 agent |
| B17 | Simplify task-planner.md | 1 agent |
| B18 | Simplify research-analyst.md | 1 agent |
| QC-B | Run Phase B validation, test skill references | - |

## Technical Decisions

### Phase A Decisions

| Decision | Options | Choice | Rationale |
|----------|---------|--------|-----------|
| Edit approach | In-place vs temp files | In-place | Simpler, git tracks changes |
| Color strategy | Unique per agent vs grouped | Grouped by function | Consistent semantic meaning |
| Legacy command naming | Keep speckit. prefix vs strip | Strip prefix | Match modern command style |
| Validation location | scripts/ vs plugin dir | scripts/ | Project-wide, not plugin-specific |
| Skill version | Use plugin version vs 0.1.0 | 0.1.0 | Standard initial version |

### Phase B Decisions

| Decision | Options | Choice | Rationale |
|----------|---------|--------|-----------|
| Skill extraction granularity | Few large vs many small | Many small (11) | Better reuse, focused context |
| Reference pattern | Inline expand vs reference | Reference with summary | Keeps commands/agents readable |
| Phase B timing | Same PR vs separate | Same PR | Single atomic refactor |
| Skill naming | Generic vs specific | Specific (failure-recovery not just recovery) | Clear intent, searchable |
| Skill organization | Flat vs grouped | Flat in skills/ | Plugin convention, auto-discovery |
| Content preserved vs trimmed | Keep full detail vs summarize | Keep full detail in skill | Skills are the source of truth |

## Error Handling

| Error | Handling |
|-------|----------|
| Edit fails to match | Investigate file format, use Read to verify |
| Legacy command has unique content | Compare with modern version, keep better |
| Validation fails after changes | Review failed check, fix file |

## Rollback Strategy

Git provides rollback:
```bash
git checkout -- plugins/  # Revert all plugin changes
git checkout -- scripts/  # Revert validation script
```

No database, no external state, no destructive operations.

## Test Strategy

**Validation script**: Run after all changes, must pass
**Manual verification**:
- Claude Code restart with `--plugin-dir` for both plugins
- Test agent triggering via Task tool
- Test skill loading via context matching
- Test command invocation

## File Summary

### Phase A: Metadata Fixes

| Category | Files Changed | Files Created | Files Deleted |
|----------|---------------|---------------|---------------|
| Agents | 14 | 0 | 0 |
| Skills (version) | 10 | 0 | 0 |
| Hooks | 2 | 0 | 0 |
| Commands | 5 | 8 | 9 |
| Scripts | 0 | 1 | 0 |
| Docs | 1 | 0 | 0 |
| **Subtotal A** | **32** | **9** | **9** |

### Phase B: Skill Consolidation

| Category | Files Changed | Files Created | Files Deleted |
|----------|---------------|---------------|---------------|
| Commands (simplify) | 6 | 0 | 0 |
| Agents (simplify) | 4 | 0 | 0 |
| Skills (new) | 0 | 11 | 0 |
| **Subtotal B** | **10** | **11** | **0** |

### Combined Total

| Category | Files Changed | Files Created | Files Deleted |
|----------|---------------|---------------|---------------|
| **Grand Total** | **42** | **20** | **9** |

## Implementation Steps

### Phase A: Metadata Fixes

1. Add `color` field to 8 ralph-specum agents
2. Add `<example>` blocks to 8 ralph-specum agents
3. Add `color` field to 6 ralph-speckit agents
4. Add `<example>` blocks to 6 ralph-speckit agents
5. Add `version: 0.1.0` to 6 ralph-specum skills
6. Add `version: 0.1.0` to 4 ralph-speckit skills
7. Rewrite interview-framework skill description (ralph-specum)
8. Rewrite 4 ralph-speckit skill descriptions
9. Add `"matcher": "*"` to ralph-specum hooks.json
10. Add `"matcher": "*"` to ralph-speckit hooks.json
11. Add `name` field to 5 ralph-speckit commands
12. Migrate 8 legacy commands to `commands/` with frontmatter
13. Remove duplicate speckit.implement.md
14. Remove `.claude/commands/` directory
15. Create `scripts/validate-plugins.sh`
16. Update CLAUDE.md with best practices reference
17. Run validation script Phase A
18. Test both plugins with Claude Code

### Phase B: Skill Consolidation

19. Create `skills/failure-recovery/SKILL.md` from implement.md sections 6b-6d
20. Create `skills/verification-layers/SKILL.md` from implement.md section 7
21. Create `skills/coordinator-pattern/SKILL.md` from implement.md coordinator prompt
22. Create `skills/branch-management/SKILL.md` from start.md
23. Create `skills/intent-classification/SKILL.md` from start.md
24. Create `skills/spec-scanner/SKILL.md` from start.md
25. Create `skills/parallel-research/SKILL.md` from research.md
26. Create `skills/phase-rules/SKILL.md` from spec-executor.md
27. Create `skills/commit-discipline/SKILL.md` from spec-executor.md
28. Create `skills/quality-checkpoints/SKILL.md` from task-planner.md
29. Create `skills/quality-commands/SKILL.md` from research-analyst.md
30. Simplify implement.md to reference skills
31. Simplify start.md to reference skills
32. Simplify research.md to reference skills
33. Simplify design.md, requirements.md, tasks.md to reference interview-framework
34. Simplify spec-executor.md to reference skills
35. Simplify task-planner.md to reference skills
36. Simplify research-analyst.md to reference skills
37. Run validation script Phase B
38. Test skill references work correctly
