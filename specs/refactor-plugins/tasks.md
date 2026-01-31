---
spec: refactor-plugins
phase: tasks
total_tasks: 32
created: 2026-01-29
---

# Tasks: Plugin Refactoring to Best Practices

## Phase 1: Make It Work (POC) - Phase A Metadata Fixes

Focus: Fix all missing frontmatter fields (color, version, matcher, name) and add example blocks to agents.

### A1: Agent Metadata

- [x] 1.1 Add color and examples to ralph-specum agents (8 files)
  - **Do**:
    1. For each of 8 agents, add `color` field after `model` in frontmatter
    2. Add 2 `<example>` blocks with Context/user/assistant/commentary format to description
    3. Colors: research-analyst=blue, product-manager=cyan, architect-reviewer=blue, task-planner=cyan, spec-executor=green, plan-synthesizer=green, qa-engineer=yellow, refactor-specialist=magenta
  - **Files**:
    - `plugins/ralph-specum/agents/research-analyst.md`
    - `plugins/ralph-specum/agents/product-manager.md`
    - `plugins/ralph-specum/agents/architect-reviewer.md`
    - `plugins/ralph-specum/agents/task-planner.md`
    - `plugins/ralph-specum/agents/spec-executor.md`
    - `plugins/ralph-specum/agents/plan-synthesizer.md`
    - `plugins/ralph-specum/agents/qa-engineer.md`
    - `plugins/ralph-specum/agents/refactor-specialist.md`
  - **Done when**: All 8 agents have color field and 2+ example blocks
  - **Verify**: `for f in plugins/ralph-specum/agents/*.md; do grep -q "^color:" "$f" && test $(grep -c "<example>" "$f") -ge 2 || echo "FAIL: $f"; done | grep -c FAIL | xargs test 0 -eq`
  - **Commit**: `feat(ralph-specum): add color and examples to all agents`
  - _Requirements: AC-1.1, AC-1.3, AC-1.4, AC-1.5_
  - _Design: ralph-specum Agents, Agent Color Assignments_

- [x] 1.2 Add color and examples to ralph-speckit agents (6 files)
  - **Do**:
    1. For each of 6 agents, add `color` field after `model` in frontmatter
    2. Add 2 `<example>` blocks with Context/user/assistant/commentary format to description
    3. Colors: constitution-architect=magenta, spec-analyst=blue, qa-engineer=yellow, spec-executor=green, plan-architect=cyan, task-planner=cyan
  - **Files**:
    - `plugins/ralph-speckit/agents/constitution-architect.md`
    - `plugins/ralph-speckit/agents/spec-analyst.md`
    - `plugins/ralph-speckit/agents/qa-engineer.md`
    - `plugins/ralph-speckit/agents/spec-executor.md`
    - `plugins/ralph-speckit/agents/plan-architect.md`
    - `plugins/ralph-speckit/agents/task-planner.md`
  - **Done when**: All 6 agents have color field and 2+ example blocks
  - **Verify**: `for f in plugins/ralph-speckit/agents/*.md; do grep -q "^color:" "$f" && test $(grep -c "<example>" "$f") -ge 2 || echo "FAIL: $f"; done | grep -c FAIL | xargs test 0 -eq`
  - **Commit**: `feat(ralph-speckit): add color and examples to all agents`
  - _Requirements: AC-1.2, AC-1.3, AC-1.4, AC-1.5_
  - _Design: ralph-speckit Agents, Agent Color Assignments_

- [x] 1.3 [VERIFY] Quality checkpoint: agent metadata
  - **Do**: Verify all 14 agents have color field and 2+ example blocks
  - **Verify**: `count=0; for f in plugins/*/agents/*.md; do grep -q "^color:" "$f" && test $(grep -c "<example>" "$f") -ge 2 || ((count++)); done; test $count -eq 0`
  - **Done when**: All agents pass color and example validation
  - **Commit**: `chore(plugins): pass agent metadata checkpoint` (only if fixes needed)

### A2: Skill Metadata

- [x] 1.4 Add version to ralph-specum skills (6 files)
  - **Do**:
    1. Add `version: 0.1.0` to frontmatter of each skill
    2. Fix interview-framework description to third-person format with trigger phrases
  - **Files**:
    - `plugins/ralph-specum/skills/communication-style/SKILL.md`
    - `plugins/ralph-specum/skills/delegation-principle/SKILL.md`
    - `plugins/ralph-specum/skills/interview-framework/SKILL.md`
    - `plugins/ralph-specum/skills/reality-verification/SKILL.md`
    - `plugins/ralph-specum/skills/smart-ralph/SKILL.md`
    - `plugins/ralph-specum/skills/spec-workflow/SKILL.md`
  - **Done when**: All 6 skills have version field, interview-framework has third-person description
  - **Verify**: `for f in plugins/ralph-specum/skills/*/SKILL.md; do grep -q "^version:" "$f" || echo "FAIL: $f"; done | grep -c FAIL | xargs test 0 -eq`
  - **Commit**: `feat(ralph-specum): add version to all skills`
  - _Requirements: AC-2.1, AC-2.5_
  - _Design: ralph-specum Skills_

- [x] 1.5 Add version and fix descriptions for ralph-speckit skills (4 files)
  - **Do**:
    1. Add `version: 0.1.0` to frontmatter of each skill
    2. Rewrite all 4 descriptions to third-person format: "This skill should be used when..."
    3. Include at least 3 trigger phrases in quotes
  - **Files**:
    - `plugins/ralph-speckit/skills/communication-style/SKILL.md`
    - `plugins/ralph-speckit/skills/delegation-principle/SKILL.md`
    - `plugins/ralph-speckit/skills/smart-ralph/SKILL.md`
    - `plugins/ralph-speckit/skills/speckit-workflow/SKILL.md`
  - **Done when**: All 4 skills have version field and third-person descriptions
  - **Verify**: `for f in plugins/ralph-speckit/skills/*/SKILL.md; do grep -q "^version:" "$f" && grep -q "This skill should be used when" "$f" || echo "FAIL: $f"; done | grep -c FAIL | xargs test 0 -eq`
  - **Commit**: `feat(ralph-speckit): add version and fix descriptions for all skills`
  - _Requirements: AC-2.2, AC-2.3, AC-2.4_
  - _Design: ralph-speckit Skills_

### A3: Hook Metadata

- [x] 1.6 Add matcher field to hooks (2 files)
  - **Do**:
    1. Add `"matcher": "*"` to Stop entry in ralph-specum hooks.json
    2. Add `"matcher": "*"` to SessionStart entry in ralph-specum hooks.json
    3. Add `"matcher": "*"` to Stop entry in ralph-speckit hooks.json
  - **Files**:
    - `plugins/ralph-specum/hooks/hooks.json`
    - `plugins/ralph-speckit/hooks/hooks.json`
  - **Done when**: All hook entries have matcher field
  - **Verify**: `for f in plugins/*/hooks/hooks.json; do grep -q '"matcher"' "$f" || echo "FAIL: $f"; done | grep -c FAIL | xargs test 0 -eq`
  - **Commit**: `feat(plugins): add matcher field to all hook entries`
  - _Requirements: AC-3.1, AC-3.2, AC-3.3_
  - _Design: Hooks_

- [x] 1.7 [VERIFY] Quality checkpoint: skills and hooks
  - **Do**: Verify all skills have version and all hooks have matcher
  - **Verify**: `count=0; for f in plugins/*/skills/*/SKILL.md; do grep -q "^version:" "$f" || ((count++)); done; for f in plugins/*/hooks/hooks.json; do grep -q '"matcher"' "$f" || ((count++)); done; test $count -eq 0`
  - **Done when**: All skills and hooks pass validation
  - **Commit**: `chore(plugins): pass skills/hooks checkpoint` (only if fixes needed)

### A4: Command Fixes

- [x] 1.8 Add name field to ralph-speckit modern commands (5 files)
  - **Do**:
    1. Add `name: <command>` field to frontmatter of each command
    2. Names: start, status, switch, cancel, implement
  - **Files**:
    - `plugins/ralph-speckit/commands/start.md` (name: start)
    - `plugins/ralph-speckit/commands/status.md` (name: status)
    - `plugins/ralph-speckit/commands/switch.md` (name: switch)
    - `plugins/ralph-speckit/commands/cancel.md` (name: cancel)
    - `plugins/ralph-speckit/commands/implement.md` (name: implement)
  - **Done when**: All 5 commands have name field in frontmatter
  - **Verify**: `for f in plugins/ralph-speckit/commands/*.md; do grep -q "^name:" "$f" || echo "FAIL: $f"; done | grep -c FAIL | xargs test 0 -eq`
  - **Commit**: `feat(ralph-speckit): add name field to modern commands`
  - _Requirements: AC-4.1_
  - _Design: ralph-speckit Commands_

- [x] 1.9 Migrate legacy commands to commands/ directory (8 files)
  - **Do**:
    1. For each legacy command in `.claude/commands/`:
       - Copy to `plugins/ralph-speckit/commands/` with new name (strip speckit. prefix)
       - Add proper frontmatter: name, description, allowed_tools
    2. Files to migrate (skip speckit.implement.md - duplicate):
       - speckit.analyze.md -> analyze.md
       - speckit.checklist.md -> checklist.md
       - speckit.clarify.md -> clarify.md
       - speckit.constitution.md -> constitution.md
       - speckit.plan.md -> plan.md
       - speckit.specify.md -> specify.md
       - speckit.tasks.md -> tasks.md
       - speckit.taskstoissues.md -> taskstoissues.md
  - **Files**:
    - `plugins/ralph-speckit/commands/analyze.md` (create)
    - `plugins/ralph-speckit/commands/checklist.md` (create)
    - `plugins/ralph-speckit/commands/clarify.md` (create)
    - `plugins/ralph-speckit/commands/constitution.md` (create)
    - `plugins/ralph-speckit/commands/plan.md` (create)
    - `plugins/ralph-speckit/commands/specify.md` (create)
    - `plugins/ralph-speckit/commands/tasks.md` (create)
    - `plugins/ralph-speckit/commands/taskstoissues.md` (create)
  - **Done when**: All 8 commands exist in commands/ with proper frontmatter
  - **Verify**: `for cmd in analyze checklist clarify constitution plan specify tasks taskstoissues; do test -f "plugins/ralph-speckit/commands/$cmd.md" && grep -q "^name:" "plugins/ralph-speckit/commands/$cmd.md" || echo "FAIL: $cmd"; done | grep -c FAIL | xargs test 0 -eq`
  - **Commit**: `feat(ralph-speckit): migrate legacy commands to commands/`
  - _Requirements: AC-4.2, AC-4.5_
  - _Design: Legacy commands migration_

- [x] 1.10 Remove legacy commands directory
  - **Do**:
    1. Verify all commands migrated successfully (from 1.9)
    2. Delete `.claude/commands/` directory from ralph-speckit
    3. This removes duplicate speckit.implement.md
  - **Files**:
    - `plugins/ralph-speckit/.claude/commands/` (delete entire directory)
  - **Done when**: Legacy directory no longer exists
  - **Verify**: `test ! -d "plugins/ralph-speckit/.claude/commands"`
  - **Commit**: `chore(ralph-speckit): remove legacy commands directory`
  - _Requirements: AC-4.3, AC-4.4_
  - _Design: Post-migration cleanup_

- [x] 1.11 [VERIFY] Quality checkpoint: commands
  - **Do**: Verify all ralph-speckit commands have name field and legacy dir removed
  - **Verify**: `count=0; for f in plugins/ralph-speckit/commands/*.md; do grep -q "^name:" "$f" || ((count++)); done; test ! -d "plugins/ralph-speckit/.claude/commands" || ((count++)); test $count -eq 0`
  - **Done when**: All commands valid, legacy directory removed
  - **Commit**: `chore(ralph-speckit): pass commands checkpoint` (only if fixes needed)

### A5: Validation and Documentation

- [x] 1.12 Create validation script
  - **Do**:
    1. Create `scripts/validate-plugins.sh` with compliance checks:
       - Agents have color field
       - Agents have 2+ example blocks
       - Skills have version field
       - Hooks have matcher field
       - No legacy commands directory
    2. Script exits 0 on pass, non-zero on failure
    3. Make script executable
  - **Files**:
    - `scripts/validate-plugins.sh` (create)
  - **Done when**: Script runs and validates all checks
  - **Verify**: `test -x scripts/validate-plugins.sh && bash scripts/validate-plugins.sh`
  - **Commit**: `feat(scripts): add plugin compliance validation script`
  - _Requirements: AC-5.1, AC-5.2, AC-5.3, AC-5.4_
  - _Design: Validation Script Design_

- [x] 1.13 Update CLAUDE.md with best practices
  - **Do**:
    1. Add section referencing plugin-dev skills for best practices
    2. Include validation script usage
    3. Document color conventions for agents
  - **Files**:
    - `CLAUDE.md` (edit)
  - **Done when**: CLAUDE.md has plugin best practices reference
  - **Verify**: `grep -q "validate-plugins" CLAUDE.md && grep -q "plugin-dev" CLAUDE.md`
  - **Commit**: `docs: add plugin best practices reference to CLAUDE.md`
  - _Requirements: AC-5.5_
  - _Design: Documentation_

- [x] 1.14 [VERIFY] Phase A complete validation
  - **Do**: Run full validation script to verify all Phase A changes
  - **Verify**: `bash scripts/validate-plugins.sh && echo "Phase A PASS"`
  - **Done when**: Validation script passes with 0 errors
  - **Commit**: `chore(plugins): pass Phase A validation` (only if fixes needed)

---

## Phase 2: Refactoring - Phase B Skill Consolidation

Focus: Extract procedural logic from commands/agents into reusable skills, then simplify sources.

### B1: Create New Skills

- [x] 2.1 Create failure-recovery skill
  - **Do**:
    1. Extract recovery orchestration logic from implement.md sections 6b-6d
    2. Create skill with proper frontmatter (name, description, version)
    3. Document recovery loop pattern, fix task generation, recovery state management
  - **Files**:
    - `plugins/ralph-specum/skills/failure-recovery/SKILL.md` (create)
  - **Done when**: Skill contains full recovery pattern, ~300-400 lines
  - **Verify**: `test -f plugins/ralph-specum/skills/failure-recovery/SKILL.md && grep -q "^version:" plugins/ralph-specum/skills/failure-recovery/SKILL.md`
  - **Commit**: `feat(ralph-specum): add failure-recovery skill`
  - _Design: New Skills - failure-recovery_

- [x] 2.2 Create verification-layers skill
  - **Do**:
    1. Extract 4-layer verification pattern from implement.md section 7
    2. Document: contradiction check, uncommitted changes, checkmark verification, completion signal
  - **Files**:
    - `plugins/ralph-specum/skills/verification-layers/SKILL.md` (create)
  - **Done when**: Skill contains all 4 verification layers
  - **Verify**: `test -f plugins/ralph-specum/skills/verification-layers/SKILL.md && grep -q "contradiction" plugins/ralph-specum/skills/verification-layers/SKILL.md`
  - **Commit**: `feat(ralph-specum): add verification-layers skill`
  - _Design: New Skills - verification-layers_

- [x] 2.3 Create coordinator-pattern skill
  - **Do**:
    1. Extract coordinator prompt pattern from implement.md
    2. Document role definition, state reading, task delegation, completion signaling
  - **Files**:
    - `plugins/ralph-specum/skills/coordinator-pattern/SKILL.md` (create)
  - **Done when**: Skill contains coordinator delegation pattern
  - **Verify**: `test -f plugins/ralph-specum/skills/coordinator-pattern/SKILL.md && grep -q "COORDINATOR" plugins/ralph-specum/skills/coordinator-pattern/SKILL.md`
  - **Commit**: `feat(ralph-specum): add coordinator-pattern skill`
  - _Design: New Skills - coordinator-pattern_

- [x] 2.4 [VERIFY] Quality checkpoint: new skills batch 1
  - **Do**: Verify first 3 new skills have proper structure
  - **Verify**: `count=0; for s in failure-recovery verification-layers coordinator-pattern; do test -f "plugins/ralph-specum/skills/$s/SKILL.md" && grep -q "^version:" "plugins/ralph-specum/skills/$s/SKILL.md" || ((count++)); done; test $count -eq 0`
  - **Done when**: All 3 skills exist with version field
  - **Commit**: `chore(ralph-specum): pass new skills batch 1 checkpoint` (only if fixes needed)

- [x] 2.5 Create branch-management skill
  - **Do**:
    1. Extract branch management logic from start.md
    2. Document branch creation, worktree setup, naming conventions, default branch detection
  - **Files**:
    - `plugins/ralph-specum/skills/branch-management/SKILL.md` (create)
  - **Done when**: Skill contains branch workflow patterns
  - **Verify**: `test -f plugins/ralph-specum/skills/branch-management/SKILL.md && grep -q "branch" plugins/ralph-specum/skills/branch-management/SKILL.md`
  - **Commit**: `feat(ralph-specum): add branch-management skill`
  - _Design: New Skills - branch-management_

- [x] 2.6 Create intent-classification skill
  - **Do**:
    1. Extract intent classification logic from start.md
    2. Document goal type detection, keyword matching, question count determination
  - **Files**:
    - `plugins/ralph-specum/skills/intent-classification/SKILL.md` (create)
  - **Done when**: Skill contains intent detection patterns and keyword tables
  - **Verify**: `test -f plugins/ralph-specum/skills/intent-classification/SKILL.md && grep -q "intent" plugins/ralph-specum/skills/intent-classification/SKILL.md`
  - **Commit**: `feat(ralph-specum): add intent-classification skill`
  - _Design: New Skills - intent-classification_

- [x] 2.7 Create spec-scanner skill
  - **Do**:
    1. Extract spec discovery logic from start.md
    2. Document related specs finding, status checking, recommendation logic
  - **Files**:
    - `plugins/ralph-specum/skills/spec-scanner/SKILL.md` (create)
  - **Done when**: Skill contains spec discovery patterns
  - **Verify**: `test -f plugins/ralph-specum/skills/spec-scanner/SKILL.md && grep -q "spec" plugins/ralph-specum/skills/spec-scanner/SKILL.md`
  - **Commit**: `feat(ralph-specum): add spec-scanner skill`
  - _Design: New Skills - spec-scanner_

- [x] 2.8 Create parallel-research skill
  - **Do**:
    1. Extract parallel execution pattern from research.md
    2. Document multi-agent spawning, parallel search, results merge algorithm
  - **Files**:
    - `plugins/ralph-specum/skills/parallel-research/SKILL.md` (create)
  - **Done when**: Skill contains parallel execution and merge patterns
  - **Verify**: `test -f plugins/ralph-specum/skills/parallel-research/SKILL.md && grep -q "parallel" plugins/ralph-specum/skills/parallel-research/SKILL.md`
  - **Commit**: `feat(ralph-specum): add parallel-research skill`
  - _Design: New Skills - parallel-research_

- [x] 2.9 [VERIFY] Quality checkpoint: new skills batch 2
  - **Do**: Verify skills 4-7 have proper structure
  - **Verify**: `count=0; for s in branch-management intent-classification spec-scanner parallel-research; do test -f "plugins/ralph-specum/skills/$s/SKILL.md" && grep -q "^version:" "plugins/ralph-specum/skills/$s/SKILL.md" || ((count++)); done; test $count -eq 0`
  - **Done when**: All 4 skills exist with version field
  - **Commit**: `chore(ralph-specum): pass new skills batch 2 checkpoint` (only if fixes needed)

- [x] 2.10 Create phase-rules skill
  - **Do**:
    1. Extract phase-specific rules from spec-executor.md
    2. Document POC/Refactor/Testing/Quality phase behaviors, shortcuts allowed per phase
  - **Files**:
    - `plugins/ralph-specum/skills/phase-rules/SKILL.md` (create)
  - **Done when**: Skill contains all 4 phase behavior definitions
  - **Verify**: `test -f plugins/ralph-specum/skills/phase-rules/SKILL.md && grep -q "Phase" plugins/ralph-specum/skills/phase-rules/SKILL.md`
  - **Commit**: `feat(ralph-specum): add phase-rules skill`
  - _Design: New Skills - phase-rules_

- [x] 2.11 Create commit-discipline skill
  - **Do**:
    1. Extract commit rules from spec-executor.md
    2. Document commit message format, spec file inclusion, commit frequency rules
  - **Files**:
    - `plugins/ralph-specum/skills/commit-discipline/SKILL.md` (create)
  - **Done when**: Skill contains commit conventions and rules
  - **Verify**: `test -f plugins/ralph-specum/skills/commit-discipline/SKILL.md && grep -q "commit" plugins/ralph-specum/skills/commit-discipline/SKILL.md`
  - **Commit**: `feat(ralph-specum): add commit-discipline skill`
  - _Design: New Skills - commit-discipline_

- [x] 2.12 Create quality-checkpoints skill
  - **Do**:
    1. Extract [VERIFY] task rules from task-planner.md
    2. Document checkpoint frequency, format, verification commands
  - **Files**:
    - `plugins/ralph-specum/skills/quality-checkpoints/SKILL.md` (create)
  - **Done when**: Skill contains checkpoint insertion rules and formats
  - **Verify**: `test -f plugins/ralph-specum/skills/quality-checkpoints/SKILL.md && grep -q "VERIFY" plugins/ralph-specum/skills/quality-checkpoints/SKILL.md`
  - **Commit**: `feat(ralph-specum): add quality-checkpoints skill`
  - _Design: New Skills - quality-checkpoints_

- [x] 2.13 Create quality-commands skill
  - **Do**:
    1. Extract quality command discovery from research-analyst.md
    2. Document package.json/Makefile/CI discovery patterns, fallback commands
  - **Files**:
    - `plugins/ralph-specum/skills/quality-commands/SKILL.md` (create)
  - **Done when**: Skill contains command discovery patterns
  - **Verify**: `test -f plugins/ralph-specum/skills/quality-commands/SKILL.md && grep -q "package.json" plugins/ralph-specum/skills/quality-commands/SKILL.md`
  - **Commit**: `feat(ralph-specum): add quality-commands skill`
  - _Design: New Skills - quality-commands_

- [x] 2.14 [VERIFY] Quality checkpoint: new skills batch 3
  - **Do**: Verify skills 8-11 have proper structure
  - **Verify**: `count=0; for s in phase-rules commit-discipline quality-checkpoints quality-commands; do test -f "plugins/ralph-specum/skills/$s/SKILL.md" && grep -q "^version:" "plugins/ralph-specum/skills/$s/SKILL.md" || ((count++)); done; test $count -eq 0`
  - **Done when**: All 4 skills exist with version field
  - **Commit**: `chore(ralph-specum): pass new skills batch 3 checkpoint` (only if fixes needed)

### B2: Simplify Commands

- [x] 2.15 Simplify implement.md command
  - **Do**:
    1. Replace inline coordinator prompt with skill reference to coordinator-pattern
    2. Replace inline recovery logic with skill reference to failure-recovery
    3. Replace inline verification logic with skill reference to verification-layers
    4. Target: ~150 lines (down from 1200+)
  - **Files**:
    - `plugins/ralph-specum/commands/implement.md` (edit)
  - **Done when**: Command references skills, reduced to ~150-200 lines
  - **Verify**: `test $(wc -l < plugins/ralph-specum/commands/implement.md) -lt 300 && grep -q "skill" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `refactor(ralph-specum): simplify implement.md to reference skills`
  - _Design: Command Simplification Plan_

- [x] 2.16 Simplify start.md command
  - **Do**:
    1. Replace inline branch management with skill reference to branch-management
    2. Replace inline intent classification with skill reference to intent-classification
    3. Replace inline spec scanning with skill reference to spec-scanner
    4. Target: ~200 lines (down from 980+)
  - **Files**:
    - `plugins/ralph-specum/commands/start.md` (edit)
  - **Done when**: Command references skills, reduced to ~200-250 lines
  - **Verify**: `test $(wc -l < plugins/ralph-specum/commands/start.md) -lt 350 && grep -q "skill" plugins/ralph-specum/commands/start.md`
  - **Commit**: `refactor(ralph-specum): simplify start.md to reference skills`
  - _Design: Command Simplification Plan_

- [x] 2.17 Simplify research.md command
  - **Do**:
    1. Replace inline parallel execution with skill reference to parallel-research
    2. Target: ~150 lines (down from 700+)
  - **Files**:
    - `plugins/ralph-specum/commands/research.md` (edit)
  - **Done when**: Command references skills, reduced to ~150-200 lines
  - **Verify**: `test $(wc -l < plugins/ralph-specum/commands/research.md) -lt 250 && grep -q "skill" plugins/ralph-specum/commands/research.md`
  - **Commit**: `refactor(ralph-specum): simplify research.md to reference skills`
  - _Design: Command Simplification Plan_

- [x] 2.18 Simplify design.md, requirements.md, tasks.md commands
  - **Do**:
    1. Each command already uses interview-framework skill
    2. Ensure explicit skill references are present
    3. Target: ~80 lines each (down from ~300)
  - **Files**:
    - `plugins/ralph-specum/commands/design.md` (edit)
    - `plugins/ralph-specum/commands/requirements.md` (edit)
    - `plugins/ralph-specum/commands/tasks.md` (edit)
  - **Done when**: Commands explicitly reference interview-framework skill
  - **Verify**: `for f in design requirements tasks; do test $(wc -l < "plugins/ralph-specum/commands/$f.md") -lt 150 || echo "FAIL: $f"; done | grep -c FAIL | xargs test 0 -eq`
  - **Commit**: `refactor(ralph-specum): simplify phase commands to reference skills`
  - _Design: Command Simplification Plan_

- [x] 2.19 [VERIFY] Quality checkpoint: command simplification
  - **Do**: Verify all simplified commands are under target line counts
  - **Verify**: `count=0; test $(wc -l < plugins/ralph-specum/commands/implement.md) -lt 300 || ((count++)); test $(wc -l < plugins/ralph-specum/commands/start.md) -lt 350 || ((count++)); test $(wc -l < plugins/ralph-specum/commands/research.md) -lt 250 || ((count++)); test $count -eq 0`
  - **Done when**: All major commands under target line counts
  - **Commit**: `chore(ralph-specum): pass command simplification checkpoint` (only if fixes needed)

### B3: Simplify Agents

- [x] 2.20 Simplify spec-executor.md agent
  - **Do**:
    1. Replace inline phase rules with skill reference to phase-rules
    2. Replace inline commit discipline with skill reference to commit-discipline
    3. Add skill reference to verification-layers for [VERIFY] tasks
    4. Target: ~200 lines (down from 440)
  - **Files**:
    - `plugins/ralph-specum/agents/spec-executor.md` (edit)
  - **Done when**: Agent references skills, reduced to ~200-250 lines
  - **Verify**: `test $(wc -l < plugins/ralph-specum/agents/spec-executor.md) -lt 300 && grep -q "skill" plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `refactor(ralph-specum): simplify spec-executor.md to reference skills`
  - _Design: Agent Simplification Plan_

- [x] 2.21 Simplify task-planner.md agent
  - **Do**:
    1. Replace inline POC workflow with skill reference to phase-rules
    2. Replace inline quality checkpoints with skill reference to quality-checkpoints
    3. Target: ~250 lines (down from 520)
  - **Files**:
    - `plugins/ralph-specum/agents/task-planner.md` (edit)
  - **Done when**: Agent references skills, reduced to ~250-300 lines
  - **Verify**: `test $(wc -l < plugins/ralph-specum/agents/task-planner.md) -lt 350 && grep -q "skill" plugins/ralph-specum/agents/task-planner.md`
  - **Commit**: `refactor(ralph-specum): simplify task-planner.md to reference skills`
  - _Design: Agent Simplification Plan_

- [x] 2.22 Simplify research-analyst.md agent
  - **Do**:
    1. Replace inline quality command discovery with skill reference to quality-commands
    2. Target: ~200 lines (down from 340)
  - **Files**:
    - `plugins/ralph-specum/agents/research-analyst.md` (edit)
  - **Done when**: Agent references skills, reduced to ~200-250 lines
  - **Verify**: `test $(wc -l < plugins/ralph-specum/agents/research-analyst.md) -lt 280 && grep -q "skill" plugins/ralph-specum/agents/research-analyst.md`
  - **Commit**: `refactor(ralph-specum): simplify research-analyst.md to reference skills`
  - _Design: Agent Simplification Plan_

- [x] 2.23 [VERIFY] Quality checkpoint: agent simplification
  - **Do**: Verify all simplified agents are under target line counts
  - **Verify**: `count=0; test $(wc -l < plugins/ralph-specum/agents/spec-executor.md) -lt 300 || ((count++)); test $(wc -l < plugins/ralph-specum/agents/task-planner.md) -lt 350 || ((count++)); test $(wc -l < plugins/ralph-specum/agents/research-analyst.md) -lt 280 || ((count++)); test $count -eq 0`
  - **Done when**: All simplified agents under target line counts
  - **Commit**: `chore(ralph-specum): pass agent simplification checkpoint` (only if fixes needed)

---

## Phase 3: Testing

Minimal testing per interview context.

- [x] 3.1 Run full validation script
  - **Do**: Execute validation script to verify all compliance requirements
  - **Files**: (none - verification only)
  - **Done when**: Validation script passes with 0 errors
  - **Verify**: `bash scripts/validate-plugins.sh`
  - **Commit**: None (verification only)
  - _Requirements: AC-5.1, AC-5.2, AC-5.3, AC-5.4_

---

## Phase 4: Quality Gates

- [x] 4.1 [VERIFY] Full local validation
  - **Do**: Run validation script and verify all components
  - **Verify**: `bash scripts/validate-plugins.sh && echo "All checks pass"`
  - **Done when**: Validation passes, no compliance issues
  - **Commit**: `fix(plugins): address validation issues` (only if fixes needed)

- [x] 4.2 Create PR and verify
  - **Do**:
    1. Verify current branch is feature branch: `git branch --show-current`
    2. Push branch: `git push -u origin $(git branch --show-current)`
    3. Create PR: `gh pr create --title "refactor(plugins): apply plugin-dev best practices" --body "..."`
    4. Wait for CI: `gh pr checks --watch`
  - **Verify**: `gh pr checks | grep -v "pending\|in_progress" | grep -c "fail" | xargs test 0 -eq`
  - **Done when**: PR created, CI passes
  - **Commit**: None (PR creation)

---

## Phase 5: PR Lifecycle

- [x] 5.1 Monitor CI and fix failures
  - **Do**:
    1. Watch CI status: `gh pr checks --watch`
    2. If failures, read logs and fix issues
    3. Push fixes and re-verify
  - **Verify**: `gh pr checks | grep -c "fail" | xargs test 0 -eq`
  - **Done when**: All CI checks pass
  - **Commit**: `fix(plugins): address CI failures` (only if fixes needed)

- [x] 5.2 [VERIFY] AC checklist verification
  - **Do**: Programmatically verify each acceptance criterion
  - **Verify**:
    ```bash
    # AC-1.1, AC-1.2: All agents have color
    for f in plugins/*/agents/*.md; do grep -q "^color:" "$f" || exit 1; done
    # AC-1.3: All agents have 2+ examples
    for f in plugins/*/agents/*.md; do test $(grep -c "<example>" "$f") -ge 2 || exit 1; done
    # AC-2.1, AC-2.2: All skills have version
    for f in plugins/*/skills/*/SKILL.md; do grep -q "^version:" "$f" || exit 1; done
    # AC-3.1, AC-3.2, AC-3.3: All hooks have matcher
    for f in plugins/*/hooks/hooks.json; do grep -q '"matcher"' "$f" || exit 1; done
    # AC-4.1: ralph-speckit commands have name
    for f in plugins/ralph-speckit/commands/*.md; do grep -q "^name:" "$f" || exit 1; done
    # AC-4.4: Legacy directory removed
    test ! -d "plugins/ralph-speckit/.claude/commands" || exit 1
    # AC-5.1-5.4: Validation script works
    bash scripts/validate-plugins.sh
    echo "All ACs verified"
    ```
  - **Done when**: All acceptance criteria confirmed met
  - **Commit**: None (verification only)

---

## Notes

### POC Shortcuts Taken

- Validation script is bash-only (no test framework)
- Manual Claude Code testing deferred to user
- No automated E2E tests for plugin loading

### Production TODOs

- Consider adding CI integration for validation script
- May want to add more sophisticated skill trigger phrase detection
- Consider adding tools restrictions to agents in future iteration

### File Counts

| Phase | Files Changed | Files Created | Files Deleted |
| --------- | ------------- | ------------- | ------------- |
| Phase A | 32 | 9 | 9 |
| Phase B | 10 | 11 | 0 |
| **Total** | **42** | **20** | **9** |

### Skill Reference Pattern

Commands/agents reference skills using:

```markdown
<skill-reference>
**Apply skill**: `skills/failure-recovery/SKILL.md`
Use the failure recovery pattern when spec-executor does not output TASK_COMPLETE.
</skill-reference>
```
