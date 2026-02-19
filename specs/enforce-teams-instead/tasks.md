---
spec: enforce-teams-instead
phase: tasks
total_tasks: 14
created: 2026-02-19
generated: auto
---

# Tasks: enforce-teams-instead

## Phase 1: Make It Work (POC)

Focus: Convert each phase command to use teams. Validate that the team lifecycle works end-to-end for each phase. Accept hardcoded values and skip tests.

- [x] 1.1 Convert research.md to team-based pattern
  - **Do**: Replace the "Execute Research" section in `plugins/ralph-specum/commands/research.md` with a team-based flow matching start.md's pattern. Add sections for: (1) orphaned team check, (2) TeamCreate, (3) TaskCreate per research topic, (4) spawn teammates via Task with team_name, (5) wait for completion via TaskList, (6) shutdown teammates, (7) merge results (keep existing merge logic), (8) TeamDelete. Keep all other sections (Interview, Walkthrough, Review, Update State, Commit, Stop) unchanged.
  - **Files**: `plugins/ralph-specum/commands/research.md`
  - **Done when**: research.md Execute Research section uses TeamCreate/TaskCreate/SendMessage/TeamDelete lifecycle instead of bare multi-Task calls
  - **Verify**: Read the file and confirm TeamCreate, TaskCreate, SendMessage(shutdown_request), and TeamDelete are all referenced in the Execute Research section
  - **Commit**: `feat(ralph-specum): convert research.md to team-based execution`
  - _Requirements: FR-1_
  - _Design: Component A_

- [x] 1.2 Add team lifecycle to requirements.md
  - **Do**: Replace the "Execute Requirements" section in `plugins/ralph-specum/commands/requirements.md` with a team-based flow. Add: (1) orphaned team check for `requirements-$spec`, (2) TeamCreate, (3) TaskCreate with existing product-manager prompt, (4) spawn single teammate via Task with team_name, (5) wait for completion, (6) shutdown teammate, (7) TeamDelete. Keep the review/feedback loop -- if user requests changes, the re-invocation of product-manager should also use the team pattern (or spawn a new teammate in the existing team).
  - **Files**: `plugins/ralph-specum/commands/requirements.md`
  - **Done when**: requirements.md Execute Requirements section uses team lifecycle with product-manager as a teammate
  - **Verify**: Read the file and confirm TeamCreate and TeamDelete are referenced in Execute Requirements section
  - **Commit**: `feat(ralph-specum): convert requirements.md to team-based execution`
  - _Requirements: FR-2_
  - _Design: Component B_

- [x] 1.3 Add team lifecycle to design.md
  - **Do**: Replace the "Execute Design" section in `plugins/ralph-specum/commands/design.md` with the same team-based wrapper pattern used in requirements.md. Team name: `design-$spec`. Teammate name: `architect-1`. Use `architect-reviewer` subagent type. Keep all review/feedback/walkthrough sections unchanged.
  - **Files**: `plugins/ralph-specum/commands/design.md`
  - **Done when**: design.md Execute Design section uses team lifecycle with architect-reviewer as a teammate
  - **Verify**: Read the file and confirm TeamCreate and TeamDelete are referenced in Execute Design section
  - **Commit**: `feat(ralph-specum): convert design.md to team-based execution`
  - _Requirements: FR-3_
  - _Design: Component C_

- [x] 1.4 Add team lifecycle to tasks.md command
  - **Do**: Replace the "Execute Tasks Generation" section in `plugins/ralph-specum/commands/tasks.md` with the team-based wrapper pattern. Team name: `tasks-$spec`. Teammate name: `planner-1`. Use `task-planner` subagent type. Keep all review/feedback/walkthrough sections unchanged.
  - **Files**: `plugins/ralph-specum/commands/tasks.md`
  - **Done when**: tasks.md Execute Tasks Generation section uses team lifecycle with task-planner as a teammate
  - **Verify**: Read the file and confirm TeamCreate and TeamDelete are referenced in Execute Tasks Generation section
  - **Commit**: `feat(ralph-specum): convert tasks.md to team-based execution`
  - _Requirements: FR-4_
  - _Design: Component D_

- [x] 1.5 Convert parallel execution in implement.md to team-based
  - **Do**: Modify the "Parallel Execution" subsection of Section 6 "Task Delegation" in `plugins/ralph-specum/commands/implement.md`. Replace the current multi-Task parallel pattern with: (1) orphaned team check for `exec-$spec`, (2) TeamCreate, (3) TaskCreate per parallel task, (4) Task per executor with team_name, (5) wait via TaskList, (6) shutdown, (7) TeamDelete. Keep sequential execution and [VERIFY] task handling unchanged. Keep the stop-hook loop mechanism completely unchanged.
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: Parallel [P] task execution in implement.md uses TeamCreate/TaskCreate/TeamDelete lifecycle; sequential tasks unchanged
  - **Verify**: Read Section 6 of implement.md and confirm team lifecycle is used for parallel batches but not for sequential tasks
  - **Commit**: `feat(ralph-specum): convert parallel execution to team-based`
  - _Requirements: FR-5_
  - _Design: Component E_

- [x] 1.6 POC Checkpoint
  - **Do**: Review all 5 modified command files to verify: (a) each has consistent team lifecycle pattern, (b) team naming follows `$phase-$spec` convention, (c) orphaned team cleanup is present in each, (d) no syntax errors in markdown structure, (e) existing non-team sections are preserved
  - **Files**: `plugins/ralph-specum/commands/research.md`, `plugins/ralph-specum/commands/requirements.md`, `plugins/ralph-specum/commands/design.md`, `plugins/ralph-specum/commands/tasks.md`, `plugins/ralph-specum/commands/implement.md`
  - **Done when**: All 5 files have consistent team lifecycle and the rest of each file is unchanged
  - **Verify**: Read each file and check for TeamCreate and TeamDelete presence
  - **Commit**: `feat(ralph-specum): complete POC for team-based phases`

## Phase 2: Refactoring

After POC validated, clean up and standardize the team patterns across files.

- [ ] 2.1 Standardize team lifecycle documentation across all command files
  - **Do**: Ensure all 5 command files use the exact same team lifecycle structure: same step numbering, same section headers ("Step 1: Check for Orphaned Team", "Step 2: Create Team", etc.), same cleanup pattern. Extract any inconsistencies introduced during POC and make them uniform. Ensure the mandatory/critical blocks wrap the team sections properly.
  - **Files**: `plugins/ralph-specum/commands/research.md`, `plugins/ralph-specum/commands/requirements.md`, `plugins/ralph-specum/commands/design.md`, `plugins/ralph-specum/commands/tasks.md`, `plugins/ralph-specum/commands/implement.md`
  - **Done when**: All team lifecycle sections follow identical structure and naming conventions
  - **Verify**: Compare team lifecycle sections across all 5 files for structural consistency
  - **Commit**: `refactor(ralph-specum): standardize team lifecycle across phases`
  - _Design: Architecture_

- [ ] 2.2 Add error handling for team operations
  - **Do**: Add fallback behavior to each command file: if TeamCreate fails, fall back to direct Task delegation (no team). Add this as a documented pattern in each Execute section: "If TeamCreate fails, log warning and fall back to direct Task(subagent_type: ...) call without team." Also add timeout notes for teammate completion waiting.
  - **Files**: `plugins/ralph-specum/commands/research.md`, `plugins/ralph-specum/commands/requirements.md`, `plugins/ralph-specum/commands/design.md`, `plugins/ralph-specum/commands/tasks.md`, `plugins/ralph-specum/commands/implement.md`
  - **Done when**: Each command file documents fallback behavior for TeamCreate failure and teammate timeout
  - **Verify**: Search all 5 files for "fallback" or "TeamCreate fails" text
  - **Commit**: `refactor(ralph-specum): add error handling for team operations`
  - _Design: Error Handling_

- [x] 2.3 Update review/feedback loops to work with teams
  - **Do**: In requirements.md, design.md, and tasks.md, update the "Handle Response" sections for when user requests changes. When the user says "Need changes", the re-invocation of the subagent should either: (a) spawn a new teammate in the existing team, or (b) create a new team for the re-invocation. Choose option (b) for simplicity -- cleanup and recreate team for each feedback iteration. Document this clearly.
  - **Files**: `plugins/ralph-specum/commands/requirements.md`, `plugins/ralph-specum/commands/design.md`, `plugins/ralph-specum/commands/tasks.md`
  - **Done when**: Feedback loops document team creation/cleanup for re-invocations
  - **Verify**: Read "Handle Response" sections and confirm team lifecycle is addressed
  - **Commit**: `refactor(ralph-specum): handle feedback loops with team pattern`
  - _Requirements: FR-8_

## Phase 3: Testing

- [ ] 3.1 Validate plugin loads without errors
  - **Do**: Run `claude --plugin-dir ./plugins/ralph-specum` with a simple test command to verify the plugin loads correctly. Check that all command files are parsed without syntax errors by listing available commands.
  - **Files**: None (read-only validation)
  - **Done when**: Plugin loads and all commands appear in help
  - **Verify**: `claude --plugin-dir ./plugins/ralph-specum --help` shows all ralph-specum commands
  - **Commit**: None (verification only)

- [ ] 3.2 Verify markdown structure integrity
  - **Do**: For each modified command file, verify: (a) frontmatter is valid YAML between `---` markers, (b) all mandatory blocks have matching open/close tags, (c) code blocks are properly fenced, (d) heading hierarchy is correct (no skipped levels), (e) all original sections still present
  - **Files**: `plugins/ralph-specum/commands/research.md`, `plugins/ralph-specum/commands/requirements.md`, `plugins/ralph-specum/commands/design.md`, `plugins/ralph-specum/commands/tasks.md`, `plugins/ralph-specum/commands/implement.md`
  - **Done when**: All files pass structural validation
  - **Verify**: Read each file and verify frontmatter, mandatory blocks, and heading structure
  - **Commit**: `fix(ralph-specum): fix any structural issues` (if needed)

## Phase 4: Quality Gates

- [ ] 4.1 Bump plugin version
  - **Do**: Increment the minor version in both `plugins/ralph-specum/.claude-plugin/plugin.json` (e.g., 3.4.1 -> 3.5.0) and `.claude-plugin/marketplace.json` (update the ralph-specum entry version to match). This is required per CLAUDE.md for any plugin file changes.
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  - **Done when**: Both files have matching updated version numbers
  - **Verify**: Read both files and confirm version numbers match and are incremented
  - **Commit**: `chore(ralph-specum): bump version to 3.5.0`

- [ ] 4.2 Create PR and verify
  - **Do**: Push branch, create PR with `gh pr create` summarizing the team-based conversion across all phases. PR body should list all modified files and the team pattern applied.
  - **Verify**: `gh pr checks --watch` all green (or no CI configured)
  - **Done when**: PR created and ready for review
  - **Commit**: None (PR creation only)

## Notes

- **POC shortcuts taken**: Feedback loop team handling may not be fully fleshed out in POC; refined in Phase 2
- **Production TODOs**: Single-agent team phases add overhead; monitor if this causes issues and consider optimization
- **Key constraint**: Stop-hook loop mechanism in implement.md is NOT modified -- teams only used for [P] parallel batches within the existing loop
