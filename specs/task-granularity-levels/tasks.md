# Tasks: Task Granularity Levels

## Phase 1: Make It Work (POC)

Focus: Get `--tasks-size fine|coarse` flag working end-to-end: flag parsed, stored in state, read by task-planner, sizing rules applied.

- [x] 1.1 Create sizing-rules.md reference file
  - **Do**:
    1. Create `plugins/ralph-specum/references/sizing-rules.md` with the full content from design.md Component 1
    2. Include fine table, coarse table, split/combine rules for each, coarse guidance, and shared rules section
    3. Use the `> Used by: task-planner agent` header pattern (matches quality-checkpoints.md, phase-rules.md)
  - **Files**: `plugins/ralph-specum/references/sizing-rules.md`
  - **Done when**: File exists with fine/coarse tables, split/combine rules, shared rules section
  - **Verify**: `test -f plugins/ralph-specum/references/sizing-rules.md && grep -q "## Fine" plugins/ralph-specum/references/sizing-rules.md && grep -q "## Coarse" plugins/ralph-specum/references/sizing-rules.md && grep -q "## Shared Rules" plugins/ralph-specum/references/sizing-rules.md && echo PASS`
  - **Commit**: `feat(task-planner): add sizing-rules.md reference for fine/coarse granularity`
  - _Requirements: FR-5, FR-6, AC-3.1-3.5, AC-4.1-4.6_
  - _Design: Component 1_

- [x] 1.2 Replace hardcoded sizing section in task-planner.md
  - **Do**:
    1. Replace lines 510-541 (the `## Task Sizing Rules` `<mandatory>` block) with the conditional reference from design.md Component 2
    2. Keep the `## Task Sizing Rules` header, replace body with `Read ${CLAUDE_PLUGIN_ROOT}/references/sizing-rules.md` directive + granularity detection + simplicity/surgical/clarity principles
    3. Do NOT modify any other sections of task-planner.md
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: Hardcoded "Max 4 numbered steps" and "Standard spec: 40-60+ tasks" replaced with reference to sizing-rules.md; simplicity/surgical/clarity principles retained inline
  - **Verify**: `grep -q 'sizing-rules.md' plugins/ralph-specum/agents/task-planner.md && ! grep -q 'Max 4 numbered steps in Do section' plugins/ralph-specum/agents/task-planner.md && ! grep -q 'Standard spec: 40-60+ tasks' plugins/ralph-specum/agents/task-planner.md && echo PASS`
  - **Commit**: `feat(task-planner): replace hardcoded sizing with conditional reference`
  - _Requirements: FR-4, FR-5, FR-6, AC-6.3_
  - _Design: Component 2_

- [x] 1.3 Update quality checklist in task-planner.md
  - **Do**:
    1. Find the POC-specific checklist item `Total task count is 40+` (line ~873) and replace with: `Fine: Total task count is 40+` and add new line `Coarse: Total task count is 10+`
    2. Find the TDD-specific checklist item `Total task count is 30+` (line ~881) and replace with: `Fine: Total task count is 30+` and add new line `Coarse: Total task count is 8+`
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: Quality checklist has granularity-aware task count thresholds for both POC and TDD
  - **Verify**: `grep -q 'Fine: Total task count is 40+' plugins/ralph-specum/agents/task-planner.md && grep -q 'Coarse: Total task count is 10+' plugins/ralph-specum/agents/task-planner.md && grep -q 'Coarse: Total task count is 8+' plugins/ralph-specum/agents/task-planner.md && echo PASS`
  - **Commit**: `feat(task-planner): add granularity-aware task count thresholds`
  - _Requirements: FR-5, FR-6, AC-3.1, AC-4.1_
  - _Design: Component 2 (Quality Checklist)_

- [x] 1.4 [P] Add --tasks-size to intent-classification.md
  - **Do**:
    1. Add `- **--tasks-size <fine|coarse>**: Task granularity level for task generation` to the argument parsing bullet list (after `--specs-dir`)
    2. Add 2 examples to the Examples section showing `--tasks-size` usage
  - **Files**: `plugins/ralph-specum/references/intent-classification.md`
  - **Done when**: `--tasks-size` documented in argument parsing and examples section
  - **Verify**: `grep -q '\-\-tasks-size' plugins/ralph-specum/references/intent-classification.md && grep -c 'tasks-size' plugins/ralph-specum/references/intent-classification.md | grep -q '[3-9]' && echo PASS`
  - **Commit**: `feat(intent-classification): document --tasks-size flag`
  - _Requirements: FR-1, FR-2_
  - _Design: Component 5_

- [x] 1.5 [P] Add granularity field to spec.schema.json
  - **Do**:
    1. Add `"granularity"` property to `definitions.state.properties` with `type: "string"`, `enum: ["fine", "coarse"]`, `description: "Task sizing level: fine (40-60+ tasks) or coarse (10-20 tasks)"`
    2. Do NOT add to `required` array (backwards compatible)
  - **Files**: `plugins/ralph-specum/schemas/spec.schema.json`
  - **Done when**: `granularity` field exists in state properties with correct enum values, not in required
  - **Verify**: `python3 -c "import json; d=json.load(open('plugins/ralph-specum/schemas/spec.schema.json')); p=d['definitions']['state']['properties']; assert 'granularity' in p; assert p['granularity']['enum']==['fine','coarse']; assert 'granularity' not in d['definitions']['state']['required']; print('PASS')"`
  - **Commit**: `feat(schema): add optional granularity field to state`
  - _Requirements: FR-3, AC-6.1, AC-6.2_
  - _Design: Component 6_

- [x] 1.6 [P] Update start.md frontmatter and flag parsing
  - **Do**:
    1. Update `argument-hint` in frontmatter to include `[--tasks-size fine|coarse]`
    2. In Step 2 summary text, add `--tasks-size` to the flags list
    3. In the state initialization JSON (Step 4, New Flow, item 7), add conditional `"granularity": "<value>"` field when `--tasks-size` flag present with valid value; omit when absent; warn + default to fine on invalid
  - **Files**: `plugins/ralph-specum/commands/start.md`
  - **Done when**: start.md parses `--tasks-size`, stores in state init, handles invalid values with warning
  - **Verify**: `grep -q '\-\-tasks-size fine|coarse' plugins/ralph-specum/commands/start.md && grep -q 'granularity' plugins/ralph-specum/commands/start.md && echo PASS`
  - **Commit**: `feat(start): parse --tasks-size flag and store granularity in state`
  - _Requirements: FR-1, FR-3, AC-1.1, AC-1.2, AC-1.3, AC-1.4_
  - _Design: Component 3_

- [x] 1.7 [P] Document --tasks-size flag in CLAUDE.md
  - **Do**:
    1. In the Development section, after the test workflow example and before the version bump warning, add a brief subsection documenting `--tasks-size fine|coarse`
    2. Include: what each level produces (fine=40-60+ tasks, coarse=10-20 tasks), example commands, and note that fine is default
  - **Files**: `CLAUDE.md`
  - **Done when**: CLAUDE.md documents `--tasks-size` flag with both levels explained and example usage
  - **Verify**: `grep -q '\-\-tasks-size' CLAUDE.md && grep -q 'coarse' CLAUDE.md && echo PASS`
  - **Commit**: `docs(claude-md): document --tasks-size flag`
  - _Requirements: FR-13, AC-8.1_

- [x] 1.8 Update tasks.md frontmatter and flag parsing
  - **Do**:
    1. Update `argument-hint` in frontmatter to `[spec-name] [--tasks-size fine|coarse]`
    2. In Step 1, add instruction to check `$ARGUMENTS` for `--tasks-size` flag; if present and valid (`fine` or `coarse`), update `granularity` in `.ralph-state.json`; if invalid value, warn and default to fine
  - **Files**: `plugins/ralph-specum/commands/tasks.md`
  - **Done when**: tasks.md frontmatter includes `--tasks-size`, Step 1 parses and stores flag value
  - **Verify**: `grep -q '\-\-tasks-size fine|coarse' plugins/ralph-specum/commands/tasks.md && grep -q 'granularity' plugins/ralph-specum/commands/tasks.md && echo PASS`
  - **Commit**: `feat(tasks): parse --tasks-size flag in tasks command`
  - _Requirements: FR-2, FR-8, AC-2.1, AC-2.2, AC-2.3, AC-2.4_
  - _Design: Component 4 (frontmatter + Step 1)_

- [x] 1.9 Add granularity interview question to tasks.md
  - **Do**:
    1. In Step 2 (Brainstorming Dialogue), add `- **Task granularity** -- fine (40-60+ small tasks, [VERIFY] every 2-3, ideal for parallel) or coarse (10-20 larger tasks, no intermediate [VERIFY], fewer tokens)? Fine is recommended.` to the exploration territory list
    2. Add instruction after the list: ask granularity question only when NOT `--quick` AND `granularity` not already set in `.ralph-state.json`; store response in `.progress.md` and update `.ralph-state.json`
    3. In `--quick` mode, default to fine silently (no question)
  - **Files**: `plugins/ralph-specum/commands/tasks.md`
  - **Done when**: Interview territory includes granularity question with skip conditions for quick mode and pre-set values
  - **Verify**: `grep -q 'Task granularity' plugins/ralph-specum/commands/tasks.md && echo PASS`
  - **Commit**: `feat(tasks): add granularity interview question`
  - _Requirements: FR-7, FR-12, AC-5.1, AC-5.2, AC-5.3, AC-5.4, AC-5.5_
  - _Design: Component 4 (Step 2)_

- [x] 1.10 Add granularity to tasks.md delegation context
  - **Do**:
    1. In Step 3 (Execute Task Generation), add instruction to include `granularity` value from `.ralph-state.json` in the delegation context passed to task-planner
    2. Add `- **Granularity**: [fine|coarse] (from .ralph-state.json)` to the delegation inputs alongside VE delegation context
  - **Files**: `plugins/ralph-specum/commands/tasks.md`
  - **Done when**: Delegation context includes granularity value for task-planner to read
  - **Verify**: `grep -q 'Granularity' plugins/ralph-specum/commands/tasks.md && echo PASS`
  - **Commit**: `feat(tasks): pass granularity to task-planner delegation`
  - _Requirements: FR-4, AC-6.3_
  - _Design: Component 4 (Step 3)_

- [x] 1.11 POC Checkpoint
  - **Do**: Verify all 9 files are modified/created with correct content by running automated checks
  - **Done when**: All files exist, contain expected patterns, schema is valid JSON
  - **Verify**: `test -f plugins/ralph-specum/references/sizing-rules.md && grep -q 'sizing-rules.md' plugins/ralph-specum/agents/task-planner.md && grep -q '\-\-tasks-size' plugins/ralph-specum/commands/start.md && grep -q '\-\-tasks-size' plugins/ralph-specum/commands/tasks.md && grep -q '\-\-tasks-size' plugins/ralph-specum/references/intent-classification.md && python3 -c "import json; json.load(open('plugins/ralph-specum/schemas/spec.schema.json'))" && grep -q '\-\-tasks-size' CLAUDE.md && echo POC_PASS`
  - **Commit**: `feat(task-granularity): complete POC`

## Phase 2: Refactoring

Focus: Clean up any rough edges from POC. Ensure consistency across all modified files.

- [x] 2.1 Ensure sizing-rules.md formatting matches existing references
  - **Do**:
    1. Compare formatting of `sizing-rules.md` against `references/quality-checkpoints.md` and `references/phase-rules.md` for consistent header style, table formatting, and `> Used by:` convention
    2. Fix any formatting inconsistencies (header levels, table alignment, whitespace)
  - **Files**: `plugins/ralph-specum/references/sizing-rules.md`
  - **Done when**: Formatting matches existing reference file conventions
  - **Verify**: `head -3 plugins/ralph-specum/references/sizing-rules.md | grep -q '> Used by:' && echo PASS`
  - **Commit**: `refactor(sizing-rules): align formatting with existing references`
  - _Design: Existing Patterns to Follow_

- [x] 2.2 Verify task-planner.md conditional reference is clear
  - **Do**:
    1. Re-read the replaced sizing section in task-planner.md
    2. Verify the `${CLAUDE_PLUGIN_ROOT}/references/sizing-rules.md` path uses the correct variable
    3. Ensure the "Determine granularity level" instruction is unambiguous for the agent
  - **Files**: `plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: Reference path uses `${CLAUDE_PLUGIN_ROOT}` variable, instructions are clear for agent consumption
  - **Verify**: `grep -q 'CLAUDE_PLUGIN_ROOT.*sizing-rules.md' plugins/ralph-specum/agents/task-planner.md && echo PASS`
  - **Commit**: `refactor(task-planner): verify conditional reference clarity`

- [x] 2.3 Verify flag parsing consistency across start.md and tasks.md
  - **Do**:
    1. Confirm `--tasks-size` parsing follows the same `$ARGUMENTS` string matching pattern as `--quick`, `--fresh`, `--commit-spec`
    2. Ensure both commands handle invalid values identically (warn + default to fine)
    3. Ensure both commands store value in `.ralph-state.json` with same field name `granularity`
  - **Files**: `plugins/ralph-specum/commands/start.md`, `plugins/ralph-specum/commands/tasks.md`
  - **Done when**: Flag parsing pattern is consistent between both commands
  - **Verify**: `grep -c 'granularity' plugins/ralph-specum/commands/start.md | grep -q '[1-9]' && grep -c 'granularity' plugins/ralph-specum/commands/tasks.md | grep -q '[1-9]' && echo PASS`
  - **Commit**: `refactor(commands): ensure consistent --tasks-size parsing`
  - _Design: Existing Patterns to Follow_

## Phase 3: Testing

Focus: No compiled tests exist for this plugin (markdown-only). Validate via structural checks and schema consistency.

- [x] 3.1 Validate schema JSON is well-formed
  - **Do**:
    1. Parse `spec.schema.json` with Python json module to verify valid JSON
    2. Verify `granularity` field has correct structure: type=string, enum=[fine,coarse]
    3. Verify `granularity` not in required array
  - **Files**: `plugins/ralph-specum/schemas/spec.schema.json`
  - **Done when**: Schema parses as valid JSON with correct granularity field
  - **Verify**: `python3 -c "import json; d=json.load(open('plugins/ralph-specum/schemas/spec.schema.json')); p=d['definitions']['state']['properties']; assert 'granularity' in p; assert p['granularity']['type']=='string'; assert p['granularity']['enum']==['fine','coarse']; assert 'granularity' not in d['definitions']['state']['required']; print('PASS')"`
  - **Commit**: None (verification only)
  - _Requirements: FR-3, AC-6.1, AC-6.2_

- [x] 3.2 Validate sizing-rules.md content completeness
  - **Do**:
    1. Verify all required sections exist: Fine, Coarse, Shared Rules
    2. Verify fine constraints match requirements: 40-60+, max 4 steps, max 3 files
    3. Verify coarse constraints match requirements: 10-20, max 8-10 steps, max 5-6 files
    4. Verify coarse has "No intermediate [VERIFY]" and fine has "[VERIFY] every 2-3 tasks"
  - **Files**: `plugins/ralph-specum/references/sizing-rules.md`
  - **Done when**: All required sizing values present and matching requirements
  - **Verify**: `grep -q '40-60+' plugins/ralph-specum/references/sizing-rules.md && grep -q '10-20' plugins/ralph-specum/references/sizing-rules.md && grep -q 'Max Do steps.*4' plugins/ralph-specum/references/sizing-rules.md && grep -q 'Max Do steps.*8-10' plugins/ralph-specum/references/sizing-rules.md && grep -q 'Every 2-3 tasks' plugins/ralph-specum/references/sizing-rules.md && grep -q 'None' plugins/ralph-specum/references/sizing-rules.md && echo PASS`
  - **Commit**: None (verification only)
  - _Requirements: FR-5, FR-6, AC-3.1-3.5, AC-4.1-4.6_

- [x] 3.3 Validate all AC references are addressable
  - **Do**:
    1. Check start.md covers flag parsing (AC-1.1-1.4)
    2. Check tasks.md covers flag override (AC-2.1-2.4) and interview question (AC-5.1-5.5)
    3. Check task-planner.md references sizing-rules.md (AC-6.3)
    4. Check CLAUDE.md documents flag (AC-8.1)
  - **Files**: (read-only verification across multiple files)
  - **Done when**: All acceptance criteria have corresponding implementation in the correct files
  - **Verify**: `grep -q 'granularity' plugins/ralph-specum/commands/start.md && grep -q 'Task granularity' plugins/ralph-specum/commands/tasks.md && grep -q 'sizing-rules.md' plugins/ralph-specum/agents/task-planner.md && grep -q '\-\-tasks-size' plugins/ralph-specum/references/intent-classification.md && grep -q '\-\-tasks-size' CLAUDE.md && echo PASS`
  - **Commit**: None (verification only)
  - _Requirements: All AC-*_

## Phase 4: Quality Gates

- [x] 4.1 [P] Bump plugin.json version 4.4.0 to 4.5.0
  - **Do**:
    1. Update `version` field in `plugins/ralph-specum/.claude-plugin/plugin.json` from `4.4.0` to `4.5.0`
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`
  - **Done when**: plugin.json version is `4.5.0`
  - **Verify**: `python3 -c "import json; d=json.load(open('plugins/ralph-specum/.claude-plugin/plugin.json')); assert d['version']=='4.5.0'; print('PASS')"`
  - **Commit**: `chore(ralph-specum): bump version to 4.5.0`
  - _Design: Component 7_

- [x] 4.2 [P] Bump marketplace.json version 4.4.0 to 4.5.0
  - **Do**:
    1. Update the ralph-specum entry's `version` field in `.claude-plugin/marketplace.json` from `4.4.0` to `4.5.0`
  - **Files**: `.claude-plugin/marketplace.json`
  - **Done when**: marketplace.json ralph-specum version is `4.5.0`
  - **Verify**: `python3 -c "import json; d=json.load(open('.claude-plugin/marketplace.json')); p=[x for x in d['plugins'] if x['name']=='ralph-specum'][0]; assert p['version']=='4.5.0'; print('PASS')"`
  - **Commit**: `chore(marketplace): bump ralph-specum to 4.5.0`
  - _Design: Component 7_

- [x] V4 [VERIFY] Full local quality check
  - **Do**: Run all structural verifications:
    1. Verify all 9 target files exist and contain expected patterns
    2. Verify schema JSON is valid
    3. Verify plugin.json and marketplace.json versions match (both 4.5.0)
    4. Verify no unintended file changes outside the 9 target files
  - **Verify**: `python3 -c "import json; p=json.load(open('plugins/ralph-specum/.claude-plugin/plugin.json')); m=json.load(open('.claude-plugin/marketplace.json')); mp=[x for x in m['plugins'] if x['name']=='ralph-specum'][0]; assert p['version']==mp['version']=='4.5.0'; s=json.load(open('plugins/ralph-specum/schemas/spec.schema.json')); assert 'granularity' in s['definitions']['state']['properties']; print('PASS')" && test -f plugins/ralph-specum/references/sizing-rules.md && grep -q 'sizing-rules.md' plugins/ralph-specum/agents/task-planner.md && echo V4_PASS`
  - **Done when**: All verifications pass, versions match, schema valid
  - **Commit**: `chore(task-granularity): pass local quality check` (if fixes needed)

- [x] V5 [VERIFY] CI pipeline passes
  - **Do**: Verify GitHub Actions/CI passes after push
  - **Verify**: `gh pr checks --watch` or `gh pr checks`
  - **Done when**: CI pipeline passes
  - **Commit**: None

- [x] V6 [VERIFY] AC checklist
  - **Do**: Programmatically verify each acceptance criterion:
    1. AC-1.1/1.2: start.md stores granularity -> `grep granularity plugins/ralph-specum/commands/start.md`
    2. AC-1.3: Omitting flag doesn't set field -> start.md state init omits when absent
    3. AC-1.4/2.4: Invalid value handling -> both commands mention warning + default
    4. AC-2.1-2.3: tasks.md stores + overrides -> `grep granularity plugins/ralph-specum/commands/tasks.md`
    5. AC-3.1-3.5: Fine sizing -> sizing-rules.md fine table
    6. AC-4.1-4.6: Coarse sizing -> sizing-rules.md coarse table
    7. AC-5.1-5.5: Interview question -> tasks.md Step 2
    8. AC-6.1-6.4: State field -> schema + commands
    9. AC-7.1-7.3: [P] markers -> sizing-rules.md shared rules
    10. AC-8.1: CLAUDE.md docs -> CLAUDE.md --tasks-size
  - **Verify**: `grep -q 'granularity' plugins/ralph-specum/commands/start.md && grep -q 'granularity' plugins/ralph-specum/commands/tasks.md && grep -q '40-60+' plugins/ralph-specum/references/sizing-rules.md && grep -q '10-20' plugins/ralph-specum/references/sizing-rules.md && grep -q 'Task granularity' plugins/ralph-specum/commands/tasks.md && grep -q '\[P\]' plugins/ralph-specum/references/sizing-rules.md && grep -q '\-\-tasks-size' CLAUDE.md && echo V6_PASS`
  - **Done when**: All 10 AC groups confirmed met
  - **Commit**: None

## Phase 5: PR Lifecycle

- [x] 5.1 Create PR and verify CI
  - **Do**:
    1. Verify current branch is a feature branch: `git branch --show-current`
    2. Push branch: `git push -u origin $(git branch --show-current)`
    3. Create PR: `gh pr create --title "feat(ralph-specum): add --tasks-size fine|coarse granularity flag" --body "..."`
    4. Monitor CI: `gh pr checks --watch`
  - **Verify**: `gh pr checks` shows all green
  - **Done when**: PR created, all CI checks passing
  - **Commit**: None
  - **If CI fails**: Read failure details, fix locally, push fixes, re-verify

- [x] 5.2 Address review comments
  - **Do**:
    1. Check for review comments: `gh pr view --comments`
    2. Address each comment with targeted fixes
    3. Push fixes and verify CI passes
  - **Verify**: `gh pr checks` shows all green after fixes
  - **Done when**: All review comments resolved, CI green
  - **Commit**: `fix(task-granularity): address review feedback` (if changes needed)

## Notes

- **POC shortcuts taken**: None significant -- all files are markdown/JSON, no runtime code
- **Production TODOs**: None -- feature is complete as specified
- **No VE tasks**: E2E verification disabled per interview (markdown-only plugin, no dev server)
- **No intermediate [VERIFY] tasks**: No lint/typecheck/build commands available for markdown files; structural verification handled in POC checkpoint and Phase 4
- **Parallel groups**: Tasks 1.4+1.5+1.6+1.7 touch different files (parallel group). Tasks 1.8/1.9/1.10 all touch tasks.md (sequential). Tasks 4.1+4.2 touch different files (parallel group). Tasks 1.2+1.3 both touch task-planner.md (sequential, NOT parallel).
