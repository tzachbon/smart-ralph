---
spec: ralph-speckit
phase: tasks
total_tasks: 25
created: 2026-01-16T00:00:00Z
approach: wrapper
---

# Tasks: ralph-speckit (Wrapper Approach)

**Key Insight**: Instead of creating all commands/agents from scratch, leverage GitHub's spec-kit CLI (`specify init`) to generate base structure. ralph-speckit adds only the autonomous task loop execution layer on top.

**What spec-kit CLI provides (DO NOT recreate):**
- `/speckit.constitution`, `/speckit.specify`, `/speckit.plan`, `/speckit.tasks`, `/speckit.implement`
- `/speckit.clarify`, `/speckit.analyze`, `/speckit.checklist`
- Templates for constitution, spec, plan, tasks
- `.specify/` directory structure

**What ralph-speckit ADDS:**
- Stop-handler hook for autonomous task loop
- State management (.speckit-state.json)
- spec-executor agent for task execution with TASK_COMPLETE signal
- qa-engineer agent for [VERIFY] tasks
- Session commands: start, status, switch, cancel
- Integration between spec-kit output and execution loop

## Phase 1: Foundation - Bootstrap with spec-kit CLI

- [x] 1.1 Install and verify spec-kit CLI
  - **Do**: Check if spec-kit is already installed via `specify --help`. If not, install via npm (`npm install -g @anthropic/specify`) or clone from GitHub and follow install instructions.
  - **Verify**: `specify --help` returns usage information
  - **Done when**: spec-kit CLI is available and executable
  - **Commit**: `chore(speckit): verify spec-kit CLI installed`
  - _Spec: FR-1_

- [x] 1.2 Run `specify init` to bootstrap plugin
  - **Do**: Run `specify init plugins/ralph-speckit --ai claude` from repository root. This generates the base command structure in `.specify/` format.
  - **Files**: `plugins/ralph-speckit/.specify/` (entire directory generated)
  - **Verify**: `ls plugins/ralph-speckit/.specify/` shows: commands/, templates/, memory/, specs/
  - **Done when**: .specify directory exists with spec-kit's standard structure
  - **Commit**: `feat(speckit): bootstrap with specify init`
  - _Spec: FR-1, FR-2_
  - _Plan: Directory Structure_

- [x] 1.3 Document spec-kit generated structure
  - **Do**: Read all generated files in `plugins/ralph-speckit/.specify/`. Document in .progress.md what was generated: which commands exist, template format, directory layout. This informs integration work.
  - **Files**: `./specs/ralph-speckit/.progress.md`
  - **Verify**: .progress.md has "Spec-kit Generated Structure" section listing all generated files
  - **Done when**: Full inventory of spec-kit output documented with observations
  - **Commit**: `docs(speckit): document spec-kit generated structure`
  - _Spec: FR-1_

- [x] 1.4 [VERIFY] Quality checkpoint: spec-kit bootstrap complete
  - **Do**: Verify spec-kit files generated correctly. Check for plugin.json, commands/, templates/.
  - **Verify**: `ls -la plugins/ralph-speckit/.specify/`
  - **Done when**: Spec-kit directory structure exists
  - **Commit**: `chore(speckit): pass bootstrap checkpoint` (if fixes needed)

## Phase 2: Integration Layer - Add Autonomous Execution

### Stop Handler for Task Loop

- [x] 2.1 Create hooks directory and configuration
  - **Do**: Create `plugins/ralph-speckit/hooks/hooks.json` pointing to stop-watcher.sh. Use same structure as ralph-specum but with adapted paths for .specify/.
  - **Files**: `plugins/ralph-speckit/hooks/hooks.json`
  - **Verify**: `cat plugins/ralph-speckit/hooks/hooks.json | jq .`
  - **Done when**: hooks.json has Stop hook pointing to stop-watcher.sh
  - **Commit**: `feat(speckit): add hooks configuration`
  - _Spec: FR-7, AC-5.2_
  - _Plan: Stop Watcher Hook_

- [x] 2.2 Create stop-watcher.sh adapted for .specify paths
  - **Do**: Copy ralph-specum's stop-watcher.sh. Adapt paths:
    - `./specs/$SPEC_NAME/` -> `.specify/specs/$FEATURE_ID-$NAME/`
    - `specs/.current-spec` -> `.specify/.current-feature`
    - `.ralph-state.json` -> `.speckit-state.json`
    Keep watcher-only behavior (exit 0, log progress, cleanup orphans). Make executable.
  - **Files**: `plugins/ralph-speckit/hooks/scripts/stop-watcher.sh`
  - **Verify**: `bash -n plugins/ralph-speckit/hooks/scripts/stop-watcher.sh` (syntax check)
  - **Done when**: Stop watcher uses .specify paths and is executable
  - **Commit**: `feat(speckit): add stop-watcher for .specify structure`
  - _Spec: FR-7, AC-5.2_
  - _Plan: Stop Watcher Hook_

- [x] 2.3 [VERIFY] Quality checkpoint: hook syntax valid
  - **Do**: Validate JSON and bash syntax
  - **Verify**: `jq . plugins/ralph-speckit/hooks/hooks.json && bash -n plugins/ralph-speckit/hooks/scripts/stop-watcher.sh`
  - **Done when**: Both commands exit 0
  - **Commit**: `chore(speckit): pass hook syntax checkpoint` (if fixes needed)

### State Management

- [x] 2.4 Create state schema for .speckit-state.json
  - **Do**: Create JSON schema at `plugins/ralph-speckit/schemas/speckit-state.schema.json`. Include fields: featureId, name, basePath, phase (specify|plan|tasks|execution), taskIndex, totalTasks, taskIteration, maxTaskIterations, globalIteration, maxGlobalIterations, awaitingApproval.
  - **Files**: `plugins/ralph-speckit/schemas/speckit-state.schema.json`
  - **Verify**: `jq . plugins/ralph-speckit/schemas/speckit-state.schema.json`
  - **Done when**: Schema defines all state fields with types
  - **Commit**: `feat(speckit): add state schema`
  - _Spec: AC-5.2, AC-6.4_
  - _Plan: State Machine_

### Execution Agents

- [x] 2.5 Create spec-executor agent
  - **Do**: Adapt ralph-specum's spec-executor.md for speckit. Key path changes:
    - `.specify/specs/$FEATURE/tasks.md`
    - `.specify/specs/$FEATURE/.progress.md`
    - `.specify/specs/$FEATURE/.speckit-state.json`
    Keep: TASK_COMPLETE signal, [VERIFY] delegation to qa-engineer, commit discipline, parallel execution support.
  - **Files**: `plugins/ralph-speckit/agents/spec-executor.md`
  - **Verify**: `grep -q "TASK_COMPLETE" plugins/ralph-speckit/agents/spec-executor.md && grep -q ".specify" plugins/ralph-speckit/agents/spec-executor.md`
  - **Done when**: spec-executor uses .specify paths and outputs TASK_COMPLETE
  - **Commit**: `feat(speckit): add spec-executor agent`
  - _Spec: FR-7, AC-5.2, AC-5.3, AC-5.4, AC-5.5_
  - _Plan: Spec Executor Agent_

- [x] 2.6 Create qa-engineer agent
  - **Do**: Adapt ralph-specum's qa-engineer.md. Update paths from `./specs/` to `.specify/specs/`. Keep VERIFICATION_PASS/VERIFICATION_FAIL signals, command execution, AC checklist handling.
  - **Files**: `plugins/ralph-speckit/agents/qa-engineer.md`
  - **Verify**: `grep -q "VERIFICATION_PASS\|VERIFICATION_FAIL" plugins/ralph-speckit/agents/qa-engineer.md`
  - **Done when**: qa-engineer handles [VERIFY] tasks with correct paths
  - **Commit**: `feat(speckit): add qa-engineer agent`
  - _Spec: AC-5.6_
  - _Plan: QA Engineer Agent_

- [x] 2.7 [VERIFY] Quality checkpoint: agents valid
  - **Do**: Check both agents have valid frontmatter and correct path references
  - **Verify**: `head -10 plugins/ralph-speckit/agents/spec-executor.md && head -10 plugins/ralph-speckit/agents/qa-engineer.md`
  - **Done when**: Both agents have correct frontmatter structure
  - **Commit**: `chore(speckit): pass agent checkpoint` (if fixes needed)

## Phase 3: Session Management Commands

- [x] 3.1 Create implement command (task loop entry)
  - **Do**: Create `plugins/ralph-speckit/commands/implement.md`. This command:
    1. Validates tasks.md exists in current feature at `.specify/specs/<id>-<name>/`
    2. Commits spec files before starting (if not committed)
    3. Initializes state with phase=execution
    4. Delegates to spec-executor for current task
    5. Ralph Wiggum handles loop continuation via exit code 2
  - **Files**: `plugins/ralph-speckit/commands/implement.md`
  - **Verify**: `grep -q "spec-executor" plugins/ralph-speckit/commands/implement.md`
  - **Done when**: Implement command triggers task execution loop
  - **Commit**: `feat(speckit): add implement command`
  - _Spec: FR-7, FR-8, AC-5.1_
  - _Plan: Implement Command_

- [x] 3.2 Create start command (smart entry point)
  - **Do**: Create `plugins/ralph-speckit/commands/start.md`. This command:
    1. Checks for `.specify/memory/constitution.md`, guides to `/speckit:constitution` if missing
    2. Auto-generates feature ID by scanning `.specify/specs/` for highest ID + 1 (format: 001, 002)
    3. Creates feature branch `<id>-<name>` if on main/master
    4. Creates `.specify/specs/<id>-<name>/` directory
    5. Initializes `.speckit-state.json` with phase=specify
    6. Updates `.specify/.current-feature`
  - **Files**: `plugins/ralph-speckit/commands/start.md`
  - **Verify**: `grep -q "current-feature" plugins/ralph-speckit/commands/start.md && grep -q "featureId\|feature ID" plugins/ralph-speckit/commands/start.md`
  - **Done when**: Start command handles branch creation, ID generation, and state initialization
  - **Commit**: `feat(speckit): add start command with feature ID auto-increment`
  - _Spec: FR-3, AC-6.1, AC-6.2, AC-6.3, AC-6.4, AC-6.5, AC-6.6_
  - _Plan: Start Command_

- [x] 3.3 Create status command
  - **Do**: Create `plugins/ralph-speckit/commands/status.md`. Shows:
    - Current feature (from `.specify/.current-feature`)
    - Phase (from `.speckit-state.json`)
    - Task progress (X/N completed)
    - List of completed tasks
    - Current/next task
    - Blockers from .progress.md
  - **Files**: `plugins/ralph-speckit/commands/status.md`
  - **Verify**: `grep -q "current-feature\|speckit-state" plugins/ralph-speckit/commands/status.md`
  - **Done when**: Status displays current feature, phase, progress
  - **Commit**: `feat(speckit): add status command`
  - _Spec: AC-7.1, AC-7.2, AC-7.3_
  - _Plan: Status Command_

- [x] 3.4 Create switch command
  - **Do**: Create `plugins/ralph-speckit/commands/switch.md`. Changes active feature by:
    1. Validating feature exists in `.specify/specs/`
    2. Updating `.specify/.current-feature`
    3. Displaying new active feature
  - **Files**: `plugins/ralph-speckit/commands/switch.md`
  - **Verify**: `grep -q "current-feature" plugins/ralph-speckit/commands/switch.md`
  - **Done when**: Switch updates feature pointer
  - **Commit**: `feat(speckit): add switch command`
  - _Spec: AC-7.4_
  - _Plan: Switch Command_

- [x] 3.5 Create cancel command
  - **Do**: Create `plugins/ralph-speckit/commands/cancel.md`. Terminates execution by:
    1. Deleting `.speckit-state.json`
    2. Optionally clearing `.specify/.current-feature`
    3. Reporting cancellation status
  - **Files**: `plugins/ralph-speckit/commands/cancel.md`
  - **Verify**: `grep -q "speckit-state" plugins/ralph-speckit/commands/cancel.md`
  - **Done when**: Cancel cleans up state files
  - **Commit**: `feat(speckit): add cancel command`
  - _Spec: AC-7.5_
  - _Plan: Cancel Command_

- [x] 3.6 [VERIFY] Quality checkpoint: session commands complete
  - **Do**: Verify all 5 session commands exist: implement, start, status, switch, cancel
  - **Verify**: `ls plugins/ralph-speckit/commands/{implement,start,status,switch,cancel}.md 2>/dev/null | wc -l`
  - **Done when**: Count shows 5
  - **Commit**: `chore(speckit): pass session commands checkpoint` (if fixes needed)

## Phase 4: Templates and Progress Tracking

- [x] 4.1 Create progress.md template
  - **Do**: Create template at `plugins/ralph-speckit/templates/progress.md` with sections: Original Goal, Current Phase, Completed Tasks, Current Task, Learnings, Blockers, Next Steps. Follow ralph-specum format.
  - **Files**: `plugins/ralph-speckit/templates/progress.md`
  - **Verify**: `grep -c "##" plugins/ralph-speckit/templates/progress.md` (should be 5+)
  - **Done when**: Progress template has all sections
  - **Commit**: `feat(speckit): add progress template`
  - _Spec: AC-5.4_
  - _Plan: Templates_

- [x] 4.2 Add gitignore entries for state files
  - **Do**: Add to .gitignore:
    ```
    .specify/.current-feature
    **/.progress.md
    **/.speckit-state.json
    **/.progress-task-*.md
    **/.tasks.lock
    **/.git-commit.lock
    ```
  - **Files**: `.gitignore`
  - **Verify**: `grep ".speckit-state.json" .gitignore`
  - **Done when**: State files excluded from git
  - **Commit**: `chore(speckit): add gitignore entries`
  - _Plan: State file handling_

- [x] 4.3 [VERIFY] Quality checkpoint: plugin structure complete
  - **Do**: Verify plugin has: .specify/ (from spec-kit), hooks/, agents/, commands/, schemas/
  - **Verify**: `ls -d plugins/ralph-speckit/hooks plugins/ralph-speckit/agents plugins/ralph-speckit/commands plugins/ralph-speckit/schemas 2>/dev/null | wc -l`
  - **Done when**: Count shows 4
  - **Commit**: `chore(speckit): pass structure checkpoint` (if fixes needed)

## Phase 5: Integration Testing

- [x] 5.1 Test full workflow manually
  - **Do**:
    1. Load plugin: `claude --plugin-dir ./plugins/ralph-speckit`
    2. Run `/speckit:start test-feature "Test goal"`
    3. Verify feature directory created at `.specify/specs/001-test-feature/`
    4. Run through spec-kit phases: constitution -> specify -> plan -> tasks
    5. Run `/speckit:implement`
    6. Verify stop-watcher logs progress
    7. Verify TASK_COMPLETE advances tasks
  - **Verify**: Feature can be specified, planned, tasked, and implemented end-to-end
  - **Done when**: Complete workflow executes without errors
  - **Commit**: `test(speckit): verify end-to-end workflow`
  - _Spec: Success Criteria_

- [x] 5.2 Test stop-handler task loop
  - **Do**: Start implementation phase with test feature. Verify:
    1. Stop-watcher logs task progress to stderr
    2. State file updates after each task
    3. Task checkmarks appear in tasks.md
    4. TASK_COMPLETE signal triggers next task
  - **Verify**: `grep "\[x\]" .specify/specs/*/tasks.md` shows completed tasks
  - **Done when**: Stop-handler loop advances through 3+ tasks automatically
  - **Commit**: `test(speckit): verify stop-handler loop`
  - _Spec: FR-7, AC-5.2_

- [x] 5.3 [VERIFY] Quality checkpoint: e2e tests pass
  - **Do**: Confirm manual tests from 5.1 and 5.2 passed
  - **Verify**: Manual confirmation
  - **Done when**: All test scenarios passed
  - **Commit**: `test(speckit): pass e2e checkpoint` (if fixes needed)

## Phase 6: Quality Gates

- [x] V1 [VERIFY] Full local verification
  - **Do**: Verify all plugin files valid:
    - hooks.json is valid JSON
    - stop-watcher.sh passes bash syntax check
    - All agent .md files have frontmatter
    - Schema is valid JSON
  - **Verify**: `jq . plugins/ralph-speckit/hooks/hooks.json && bash -n plugins/ralph-speckit/hooks/scripts/stop-watcher.sh && jq . plugins/ralph-speckit/schemas/speckit-state.schema.json`
  - **Done when**: All validation commands exit 0
  - **Commit**: `chore(speckit): pass local verification` (if fixes needed)

- [x] V2 [VERIFY] CI pipeline passes
  - **Do**: Push branch, verify GitHub Actions/CI passes
  - **Verify**: `gh pr checks --watch` shows all green
  - **Done when**: CI pipeline passes
  - **Commit**: None

- [x] V3 [VERIFY] AC checklist
  - **Do**: Read requirements.md, verify each key AC is satisfied:
    - AC-5.1: Spec files committed before implementation
    - AC-5.2: Stop-handler reads state and advances taskIndex
    - AC-5.3: Completed tasks marked [x]
    - AC-5.4: Progress updated with learnings
    - AC-5.5: Each task committed separately
    - AC-5.6: [VERIFY] tasks delegated to qa-engineer
    - AC-6.1: Start creates feature branch
    - AC-6.2: Feature directory at .specify/specs/<id>-<name>/
    - AC-6.4: State file initialized
    - AC-7.1-7.5: Status/switch/cancel commands work
  - **Verify**: Manual review against implementation
  - **Done when**: All key acceptance criteria confirmed met
  - **Commit**: None

- [x] V4 Create PR
  - **Do**:
    1. Verify on feature branch: `git branch --show-current`
    2. Push: `git push -u origin $(git branch --show-current)`
    3. Create PR: `gh pr create --title "feat(speckit): add ralph-speckit plugin as spec-kit wrapper" --body "Adds ralph-speckit plugin that wraps GitHub spec-kit CLI with autonomous task loop execution. Uses spec-kit for core workflow commands, adds stop-handler, state management, and session commands."`
  - **Verify**: PR created on GitHub
  - **Done when**: PR ready for review
  - **Commit**: None

## Notes

**Wrapper Approach Benefits:**
- Reuse spec-kit's tested commands and templates
- Focus effort on unique value: autonomous task loop
- Stay aligned with spec-kit updates
- Smaller codebase to maintain

**POC Shortcuts:**
- Manual testing only (no automated tests for markdown plugin)
- Assumes spec-kit CLI generates expected .specify/ structure
- May need path adjustments based on actual spec-kit output

**Dependencies:**
- spec-kit CLI must be installed (task 1.1)
- Ralph Wiggum handles loop continuation (stop-watcher is logging only)

**File Count (ralph-speckit unique):**
- Hooks: 2 (hooks.json, stop-watcher.sh)
- Agents: 2 (spec-executor.md, qa-engineer.md)
- Commands: 5 (implement.md, start.md, status.md, switch.md, cancel.md)
- Schemas: 1 (speckit-state.schema.json)
- Templates: 1 (progress.md)
- Total ralph-speckit files: 11 (plus whatever spec-kit generates)
