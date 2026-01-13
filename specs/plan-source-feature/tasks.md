---
spec: plan-source-feature
phase: tasks
total_tasks: 11
created: 2026-01-13
generated: auto
---

# Tasks: Quick Start Mode (--quick flag)

## Phase 1: Make It Work (POC)

Focus: Get --quick flag working end-to-end with goal string input. Skip edge cases, hardcode where needed.

- [x] 1.1 Add --quick flag parsing to start.md
  - **Do**:
    1. Add `--quick` to argument-hint in frontmatter
    2. Add detection for `--quick` flag in Parse Arguments section
    3. Add Quick Mode Flow section after New Flow with basic detection logic:
       - Check if `--quick` flag present in $ARGUMENTS
       - Extract args before `--quick` (name and/or goal)
       - Basic classification: two args = name+goal, one arg = goal (for POC)
  - **Files**: `plugins/ralph-specum/commands/start.md`
  - **Done when**: start.md has --quick flag documented and basic detection logic
  - **Verify**: Read start.md and confirm --quick sections exist
  - **Commit**: `feat(start): add --quick flag parsing`
  - _Requirements: FR-1, FR-2_
  - _Design: Input Detector_

- [x] 1.2 Create plan-synthesizer agent
  - **Do**:
    1. Create new agent file at `plugins/ralph-specum/agents/plan-synthesizer.md`
    2. Copy frontmatter pattern from task-planner.md
    3. Set name: plan-synthesizer, tools: [Read, Write, Edit, Glob, Grep, Task]
    4. Add instructions to:
       - Accept plan/goal content as input
       - Generate research.md (abbreviated, feasibility-focused)
       - Generate requirements.md (derived from plan)
       - Generate design.md (architecture from plan + codebase patterns)
       - Generate tasks.md (POC-first 4-phase structure)
       - Mark all artifacts with `generated: auto` in frontmatter
    5. Include output templates for each artifact
  - **Files**: `plugins/ralph-specum/agents/plan-synthesizer.md`
  - **Done when**: Agent file exists with complete generation instructions
  - **Verify**: Read plan-synthesizer.md and confirm it has all four artifact templates
  - **Commit**: `feat(agents): create plan-synthesizer for quick mode`
  - _Requirements: FR-4, FR-10_
  - _Design: Plan Synthesizer Agent_

- [x] 1.3 Add Quick Mode Flow to start.md
  - **Do**:
    1. Add Quick Mode Flow section after Parse Arguments
    2. Include flow steps:
       - Validate input (non-empty goal/plan)
       - Infer name from goal (basic: first 3 words, kebab-case, max 30 chars)
       - Create spec directory `./specs/$name/`
       - Write `.ralph-state.json` with `source: "plan"`, `phase: "tasks"`
       - Write `.progress.md` with original goal
       - Update `.current-spec`
       - Invoke plan-synthesizer agent via Task tool
       - After generation: update state `phase: "execution"`, `taskIndex: 0`
       - Display brief summary
       - Invoke spec-executor for task 1
  - **Files**: `plugins/ralph-specum/commands/start.md`
  - **Done when**: Complete quick mode flow documented in start.md
  - **Verify**: Read start.md and trace full --quick flow from input to execution
  - **Commit**: `feat(start): add quick mode flow with plan-synthesizer`
  - _Requirements: FR-3, FR-5, FR-6, FR-9_
  - _Design: Data Flow, State Initializer_

- [x] 1.4 POC Checkpoint
  - **Do**:
    1. Manually test quick mode with a simple goal
    2. Run `/ralph-specum:start "Add hello world endpoint" --quick`
    3. Verify spec directory created with all artifacts
    4. Verify state file has `source: "plan"`
    5. Verify execution begins automatically
  - **Done when**: Quick mode creates spec and starts execution without prompts
  - **Verify**: Check ./specs/ for new spec with generated artifacts
  - **Commit**: `feat(quick-mode): complete POC`
  - _Requirements: AC-1.1, AC-1.2, AC-1.3, AC-5.1_

## Phase 2: Refactoring

Clean up code, add proper input detection, error handling.

- [x] 2.1 Add full input detection logic
  - **Do**:
    1. Expand input detection in start.md to handle all cases:
       - Two args before --quick: first=name, second=goal or file
       - One arg file path: starts with `./` or `/` or ends with `.md`
       - One arg kebab-case: matches `^[a-z0-9-]+$`, check for existing plan.md
       - One arg goal string: anything else, infer name
       - Zero args: error
    2. Add file reading logic: if file path detected, read content
    3. Add existing plan.md check for name-only input
  - **Files**: `plugins/ralph-specum/commands/start.md`
  - **Done when**: All input type detection rules implemented
  - **Verify**: Review detection logic covers all cases from design doc
  - **Commit**: `refactor(start): complete input detection logic`
  - _Requirements: FR-2, FR-8_
  - _Design: Input Detector, Detection Rules_

- [x] 2.2 Add error handling and validation
  - **Do**:
    1. Add validation before spec creation:
       - File not found: "File not found: ./path.md"
       - Empty content: "Plan content is empty. Provide a goal or non-empty file."
       - Name conflict: Append `-2`, `-3` etc, show "Created 'name-2' (name exists)"
       - Zero args: "Quick mode requires a goal or plan file"
       - Plan too short: Warning "Short plan may produce vague tasks"
    2. Add atomic rollback section:
       - On generation failure: delete spec dir
       - Restore previous .current-spec
       - Show error with reason
  - **Files**: `plugins/ralph-specum/commands/start.md`
  - **Done when**: All error scenarios from design doc handled
  - **Verify**: Review error handling covers: file not found, empty, conflict, rollback
  - **Commit**: `refactor(start): add error handling for quick mode`
  - _Requirements: FR-7, NFR-4_
  - _Design: Error Handling_

- [x] 2.3 Improve name inference in plan-synthesizer
  - **Do**:
    1. Update plan-synthesizer to improve name inference:
       - Extract key terms (nouns, verbs) from goal
       - Convert to kebab-case
       - Max 30 characters
       - Handle unicode by stripping to ASCII
    2. Add examples for various goal formats
  - **Files**: `plugins/ralph-specum/agents/plan-synthesizer.md`
  - **Done when**: Name inference handles varied goal formats
  - **Verify**: Review name inference logic in agent
  - **Commit**: `refactor(plan-synthesizer): improve name inference`
  - _Requirements: FR-3_
  - _Design: Name Inferrer_

## Phase 3: Testing

Manual verification of all user stories.

- [x] 3.1 Test goal string input (US-1)
  - **Do**:
    1. Test: `/ralph-specum:start "Build auth with JWT" --quick`
    2. Verify: Spec created with auto-generated name
    3. Verify: All four artifacts generated (research.md, requirements.md, design.md, tasks.md)
    4. Verify: State has `source: "plan"` and `phase: "execution"`
    5. Verify: Artifacts have `generated: auto` in frontmatter
    6. Document results in test notes
  - **Done when**: US-1 acceptance criteria verified
  - **Verify**: Manual inspection of generated spec
  - **Commit**: `test(quick-mode): verify goal string input`
  - _Requirements: AC-1.1, AC-1.2, AC-1.3, AC-5.2_

- [x] 3.2 Test explicit name input (US-2)
  - **Do**:
    1. Test: `/ralph-specum:start my-feature "Build auth" --quick`
    2. Verify: Spec created at `./specs/my-feature/`
    3. Verify: Provided name used verbatim
    4. Document results
  - **Done when**: US-2 acceptance criteria verified
  - **Verify**: Check spec directory name matches provided name
  - **Commit**: `test(quick-mode): verify explicit name input`
  - _Requirements: AC-2.1, AC-2.2, AC-2.3_

- [x] 3.3 Test file input (US-3)
  - **Do**:
    1. Create test file: `./test-plan.md` with plan content
    2. Test: `/ralph-specum:start ./test-plan.md --quick`
    3. Verify: File content used as plan input
    4. Verify: Name inferred from plan content
    5. Test error: non-existent file path
    6. Clean up test file
    7. Document results
  - **Done when**: US-3 acceptance criteria verified
  - **Verify**: Check spec created from file content
  - **Commit**: `test(quick-mode): verify file input`
  - _Requirements: AC-3.1, AC-3.2, AC-3.3, AC-3.4_

## Phase 4: Quality Gates

- [x] 4.1 Review and final cleanup
  - **Do**:
    1. Review start.md for consistency with other commands
    2. Review plan-synthesizer.md for consistency with other agents
    3. Ensure all detection rules match design doc
    4. Verify error messages are direct (no emojis per CLAUDE.md)
    5. Check backwards compatibility: normal start flow unchanged
  - **Verify**: Manual review of all modified files
  - **Done when**: Code follows project patterns, no regressions
  - **Commit**: `fix(quick-mode): final cleanup`
  - _Requirements: NFR-3_

- [x] 4.2 Create PR and verify
  - **Do**:
    1. Push branch: `git push -u origin feat/v2-spec-workflow-refactor`
    2. Create PR: `gh pr create --title "feat: add --quick flag for quick start mode" --body "Adds --quick flag to /ralph-specum:start that auto-generates all spec artifacts and immediately starts task execution."`
    3. If gh CLI unavailable, provide manual PR URL
  - **Verify**: `gh pr checks --watch` (all checks pass)
  - **Done when**: PR created with passing CI
  - **If CI fails**: Read `gh pr checks`, fix issues, push, re-verify

## Notes

- **POC shortcuts taken**:
  - Phase 1 only handles goal string input (one arg)
  - Name inference is basic (first 3 words)
  - No file input handling in POC
  - No conflict detection in POC
- **Production TODOs**:
  - Full input type detection (Phase 2.1)
  - Error handling and rollback (Phase 2.2)
  - Improved name inference (Phase 2.3)
