---
spec: adaptive-interview
phase: tasks
total_tasks: 23
created: 2026-01-22
updated: 2026-01-22
---

# Tasks: Adaptive Interview System

## Execution Context

From tasks interview:
- Testing depth: Minimal - POC only, add tests later
- Deployment: Standard CI/CD pipeline

## Phase 1: Make It Work (POC)

Focus: Get single-question flow working in start.md first, then propagate to other commands.

### 1.1 Add Intent Classifier to start.md

- [x] 1.1 Add intent classifier section to start.md Goal Interview
  - **Do**:
    1. Open `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/start.md`
    2. Insert new "Intent Classification" section after line 525 (before Goal Interview Questions)
    3. Add intent classification logic that analyzes goal text for keywords:
       - TRIVIAL: "fix typo", "small change", "quick", "simple"
       - REFACTOR: "refactor", "restructure", "reorganize", "clean up"
       - GREENFIELD: "new feature", "add", "build", "implement", "create"
       - MID_SIZED: default
    4. Define min/max questions per intent (trivial:1-2, refactor:3-5, greenfield:5-10, mid-sized:3-7)
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/start.md`
  - **Done when**: Intent classifier section exists with keyword patterns and question counts
  - **Verify**: `grep -c "Intent Classification" plugins/ralph-specum/commands/start.md` returns 1
  - **Commit**: `feat(interview): add intent classifier to start.md`
  - _Requirements: FR-3, AC-3.1, AC-3.2, AC-3.3, AC-3.4, AC-3.5_
  - _Design: Intent Classifier component_

### 1.2 Replace Batch Interview with Single-Question Loop in start.md

- [x] 1.2 Convert Goal Interview to single-question flow
  - **Do**:
    1. Replace the batch AskUserQuestion block (lines 544-565) with single-question loop structure
    2. Each question asked individually via separate AskUserQuestion call
    3. Add loop control: track askedCount, check against minRequired/maxAllowed from intent
    4. Add completion signal detection (user says "done", "proceed", etc.)
    5. After each answer, store in temporary context variable
    6. Add "Any other context?" as final optional question
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/start.md`
  - **Done when**: Goal interview uses single AskUserQuestion per question, not batch
  - **Verify**: `grep -c "AskUserQuestion:" plugins/ralph-specum/commands/start.md` >= 3 (one per question)
  - **Commit**: `feat(interview): convert start.md to single-question flow`
  - _Requirements: FR-1, AC-1.1, AC-1.2, AC-1.3_
  - _Design: Single Question Loop component_

### 1.3 Add Question Classification to start.md

- [x] 1.3 Add question classification instructions
  - **Do**:
    1. Insert "Question Classification" section before single-question loop
    2. Add classification matrix: codebase fact vs user preference
    3. Add instruction: "DO NOT ask user about codebase facts - use Explore agent"
    4. List question types that should go to user: preference, requirement, scope, constraint, risk
    5. List question types that should use Explore: existing patterns, file locations, dependencies
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/start.md`
  - **Done when**: Question classification matrix exists with clear guidance
  - **Verify**: `grep -c "codebase fact" plugins/ralph-specum/commands/start.md` >= 1
  - **Commit**: `feat(interview): add question classification to start.md`
  - _Requirements: FR-2, AC-2.1, AC-2.2, AC-2.3_
  - _Design: Question Classification component_

### 1.4 Add Context Accumulator to start.md

- [x] 1.4 Store interview responses in .progress.md
  - **Do**:
    1. Update "Store Goal Context" section (lines 586-598)
    2. Add structured "Interview Responses" section format
    3. Include intent classification result
    4. Store each question-answer pair with semantic key
    5. Format: `### Goal Interview (from start.md)\n- Problem: [response]\n- Constraints: [response]...`
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/start.md`
  - **Done when**: .progress.md format includes Intent and structured Goal Interview section
  - **Verify**: `grep -c "Interview Responses" plugins/ralph-specum/commands/start.md` >= 1
  - **Commit**: `feat(interview): add context accumulator to start.md`
  - _Requirements: FR-9, AC-5.1_
  - _Design: Context Accumulator component_

### 1.5 V1 [VERIFY] Quality checkpoint after start.md changes

- [x] 1.5 [VERIFY] Quality checkpoint: verify start.md is valid markdown
  - **Do**: Validate start.md has valid structure and no syntax errors
  - **Verify**: `head -5 plugins/ralph-specum/commands/start.md | grep -c "^---"` returns 1 (valid frontmatter)
  - **Done when**: start.md has valid frontmatter and no obvious syntax errors
  - **Commit**: `chore(interview): pass quality checkpoint` (only if fixes needed)

### 1.6 Add Intent-Based Question Pool to start.md

- [x] 1.6 Define question pools per intent type
  - **Do**:
    1. Add "Question Pools" section after Intent Classification
    2. Define Trivial pool: 2 questions (what needs to change, any constraints)
    3. Define Refactor pool: 5 questions (driver, risk tolerance, test coverage, update tests, performance)
    4. Define Greenfield pool: 10 questions (problem, users, priority, constraints, integration, success, security, performance, out-of-scope, other context)
    5. Define Mid-sized pool: 7 questions (core deliverable, priority, out-of-scope, dependencies, testing, deployment, other context)
    6. Mark each question as required or optional
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/start.md`
  - **Done when**: Question pools exist for all 4 intent types with required/optional markers
  - **Verify**: `grep -c "Question Pools" plugins/ralph-specum/commands/start.md` >= 1
  - **Commit**: `feat(interview): add intent-based question pools to start.md`
  - _Requirements: FR-3, AC-3.2, AC-3.3, AC-3.4, AC-3.5_
  - _Design: Dynamic Question Queue component_

### 1.7 POC Checkpoint - Test start.md Single Question Flow

- [x] 1.7 POC Checkpoint: verify single-question flow works in start.md
  - **Do**:
    1. Run `claude --plugin-dir ./plugins/ralph-specum`
    2. Execute `/ralph-specum:start test-adaptive "Add new logging feature"`
    3. Verify: First AskUserQuestion shows exactly 1 question
    4. Answer first question
    5. Verify: Second AskUserQuestion shows exactly 1 question (adapted based on intent)
    6. Say "done" or "proceed" to end interview
    7. Verify: Interview ends, research phase starts
  - **Verify**: `grep -c "## Interview Responses" ./specs/test-adaptive/.progress.md` returns 1
  - **Done when**: Single-question flow works end-to-end, intent classification affects question count
  - **Commit**: `feat(interview): complete POC for start.md adaptive interview`
  - _Requirements: US-1, US-3, US-4_
  - _Design: POC validation_

## Phase 2: Propagate to Other Commands

After POC validated, apply pattern to research.md, requirements.md, design.md, tasks.md.

### 2.1 Propagate to research.md

- [x] 2.1 Add single-question flow to research.md
  - **Do**:
    1. Open `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/research.md`
    2. Read .progress.md context before interview (get intent from start.md)
    3. Replace batch AskUserQuestion (lines 96-111) with single-question loop
    4. Use intent to determine question count (same ranges as start.md)
    5. Add parameter chain: skip questions if answer exists in .progress.md
    6. Store responses in .progress.md under "### Research Interview"
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/research.md`
  - **Done when**: research.md uses single-question flow, reads intent from context
  - **Verify**: `grep -c "single-question" plugins/ralph-specum/commands/research.md` >= 1
  - **Commit**: `feat(interview): propagate single-question flow to research.md`
  - _Requirements: FR-1, FR-5, AC-5.1_
  - _Design: Single Question Loop, Parameter Chain_

### 2.2 Propagate to requirements.md

- [x] 2.2 Add single-question flow to requirements.md
  - **Do**:
    1. Open `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/requirements.md`
    2. Read .progress.md context (get intent, prior responses)
    3. Replace batch AskUserQuestion (lines 53-68) with single-question loop
    4. Add parameter chain: skip questions answered in prior phases
    5. Store responses under "### Requirements Interview"
    6. Add question piping: reference prior answers with {var} syntax
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/requirements.md`
  - **Done when**: requirements.md uses single-question flow with parameter chain
  - **Verify**: `grep -c "single-question" plugins/ralph-specum/commands/requirements.md` >= 1
  - **Commit**: `feat(interview): propagate single-question flow to requirements.md`
  - _Requirements: FR-1, FR-5, FR-6, AC-5.2_
  - _Design: Single Question Loop, Parameter Chain, Question Piping_

### 2.3 V2 [VERIFY] Quality checkpoint after requirements.md

- [x] 2.3 [VERIFY] Quality checkpoint: verify requirements.md is valid
  - **Do**: Validate requirements.md has valid structure
  - **Verify**: `head -5 plugins/ralph-specum/commands/requirements.md | grep -c "^---"` returns 1
  - **Done when**: requirements.md has valid frontmatter
  - **Commit**: `chore(interview): pass quality checkpoint` (only if fixes needed)

### 2.4 Propagate to design.md

- [x] 2.4 Add single-question flow to design.md
  - **Do**:
    1. Open `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/design.md`
    2. Read .progress.md context (get intent, all prior responses)
    3. Replace batch AskUserQuestion (lines 55-70) with single-question loop
    4. Add parameter chain: skip questions with known answers
    5. Store responses under "### Design Interview"
    6. Add question piping with accumulated context
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/design.md`
  - **Done when**: design.md uses single-question flow with parameter chain
  - **Verify**: `grep -c "single-question" plugins/ralph-specum/commands/design.md` >= 1
  - **Commit**: `feat(interview): propagate single-question flow to design.md`
  - _Requirements: FR-1, FR-5, FR-6_
  - _Design: Single Question Loop_

### 2.5 Propagate to tasks.md

- [x] 2.5 Add single-question flow to tasks.md
  - **Do**:
    1. Open `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/tasks.md`
    2. Read .progress.md context (get intent, all prior responses)
    3. Replace batch AskUserQuestion (lines 56-71) with single-question loop
    4. Add parameter chain: skip questions with known answers
    5. Store responses under "### Tasks Interview"
    6. Add question piping with accumulated context
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/tasks.md`
  - **Done when**: tasks.md uses single-question flow with parameter chain
  - **Verify**: `grep -c "single-question" plugins/ralph-specum/commands/tasks.md` >= 1
  - **Commit**: `feat(interview): propagate single-question flow to tasks.md`
  - _Requirements: FR-1, FR-5, FR-6_
  - _Design: Single Question Loop_

### 2.6 V3 [VERIFY] Quality checkpoint after all command files

- [x] 2.6 [VERIFY] Quality checkpoint: verify all command files are valid
  - **Do**: Validate all 5 command files have valid frontmatter
  - **Verify**: `for f in start research requirements design tasks; do head -5 plugins/ralph-specum/commands/$f.md | grep -q "^---" && echo "$f OK"; done | wc -l` returns 5
  - **Done when**: All command files have valid structure
  - **Commit**: `chore(interview): pass quality checkpoint` (only if fixes needed)

## Phase 3: Enhance with Advanced Features

### 3.1 Add Question Piping Implementation

- [x] 3.1 Implement {var} replacement across all command files
  - **Do**:
    1. Add "Question Piping" section to start.md (define available variables)
    2. Document piping syntax: `{goal}`, `{intent}`, `{problem}`, `{constraints}`, `{users}`, `{priority}`
    3. Add instruction: "Before each AskUserQuestion, replace {var} with values from .progress.md"
    4. Add fallback: "If variable not found, use original question text"
    5. Apply same pattern to research.md, requirements.md, design.md, tasks.md
  - **Files**:
    - `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/start.md`
    - `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/research.md`
    - `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/requirements.md`
    - `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/design.md`
    - `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/tasks.md`
  - **Done when**: All command files document piping syntax and fallback behavior
  - **Verify**: `grep -c "{goal}" plugins/ralph-specum/commands/start.md` >= 1
  - **Commit**: `feat(interview): implement question piping with {var} syntax`
  - _Requirements: FR-6, AC-5.2, AC-5.3_
  - _Design: Question Piping component_

### 3.2 Add Spec Scanner to start.md

- [x] 3.2 Add spec scanner to surface related specs
  - **Do**:
    1. Add "Spec Scanner" section to start.md before interview
    2. Add instruction: read all directories in ./specs/
    3. For each spec, read .progress.md for Original Goal
    4. Match keywords from current goal against existing specs
    5. Display max 3 related specs with brief summary
    6. Format: "Related specs found:\n- name: summary..."
    7. Store related specs in .ralph-state.json relatedSpecs array
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/start.md`
  - **Done when**: Spec scanner section exists with clear instructions
  - **Verify**: `grep -c "Spec Scanner" plugins/ralph-specum/commands/start.md` >= 1
  - **Commit**: `feat(interview): add spec scanner to start.md`
  - _Requirements: FR-7, AC-6.1, AC-6.2, AC-6.3_
  - _Design: Spec Scanner component_

### 3.3 Add Adaptive Follow-ups

- [x] 3.3 Enhance "Other" follow-ups to be context-specific
  - **Do**:
    1. Update Adaptive Depth section in all command files
    2. Replace generic "You mentioned [Other response]. Can you elaborate?" with:
       - Acknowledge specific response
       - Ask probing question based on response content
       - Include context from prior answers
    3. Add instruction: "Follow-up questions should reference the specific 'Other' text"
    4. Apply to start.md, research.md, requirements.md, design.md, tasks.md
  - **Files**:
    - `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/start.md`
    - `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/research.md`
    - `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/requirements.md`
    - `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/design.md`
    - `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/tasks.md`
  - **Done when**: All command files have context-specific follow-up instructions
  - **Verify**: `grep -c "context-specific" plugins/ralph-specum/commands/start.md` >= 1
  - **Commit**: `feat(interview): add adaptive context-specific follow-ups`
  - _Requirements: FR-8, AC-7.1, AC-7.2, AC-7.3_
  - _Design: Adaptive follow-ups_

### 3.4 V4 [VERIFY] Quality checkpoint after enhancements

- [x] 3.4 [VERIFY] Quality checkpoint: verify all enhancements
  - **Do**: Validate all command files have piping, spec scanner, and adaptive follow-ups
  - **Verify**: `grep -c "Question Piping\|Spec Scanner\|context-specific" plugins/ralph-specum/commands/start.md` >= 2
  - **Done when**: All enhancement sections present in start.md
  - **Commit**: `chore(interview): pass quality checkpoint` (only if fixes needed)

### 3.5 Add Max 4 Options Constraint

- [x] 3.5 Update all question options to max 4
  - **Do**:
    1. Review all AskUserQuestion blocks in all command files
    2. Reduce any option lists with 5+ options to max 4
    3. Add instruction: "Each question MUST have 2-4 options (max 4 for better UX)"
    4. Keep most relevant options, combine similar ones
  - **Files**:
    - `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/start.md`
    - `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/research.md`
    - `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/requirements.md`
    - `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/design.md`
    - `/Users/zachbonfil/projects/smart-ralph-speckit-adaptive-interview/plugins/ralph-specum/commands/tasks.md`
  - **Done when**: No question has more than 4 options
  - **Verify**: `grep -A10 "options:" plugins/ralph-specum/commands/start.md | grep -c "^\s*-" | head -1` <= 4
  - **Commit**: `feat(interview): enforce max 4 options per question`
  - _Requirements: FR-11_
  - _Design: Question UX_

### 3.6 Verify Quick Mode Bypass

- [x] 3.6 Ensure quick mode still bypasses all interviews
  - **Do**:
    1. Verify all command files check for --quick flag
    2. Ensure skip logic is preserved after interview changes
    3. Test: run `/ralph-specum:start test-quick "Test goal" --quick`
    4. Verify: No AskUserQuestion prompts appear
  - **Files**: All command files (verification only)
  - **Done when**: Quick mode bypasses all interviews in all phases
  - **Verify**: `grep -c "Skip interview if --quick" plugins/ralph-specum/commands/start.md` >= 1
  - **Commit**: `test(interview): verify quick mode bypass preserved`
  - _Requirements: FR-10, AC-8.1, AC-8.2_
  - _Design: Quick Mode_

## Phase 4: Quality Gates

### 4.1 V5 [VERIFY] Full local validation

- [x] 4.1 [VERIFY] Full local CI: validate all files and test workflow
  - **Do**:
    1. Verify all command files have valid frontmatter
    2. Run `claude --plugin-dir ./plugins/ralph-specum` to verify plugin loads
    3. Verify no syntax errors in markdown files
  - **Verify**: `ls plugins/ralph-specum/commands/*.md | xargs -I{} sh -c 'head -1 {} | grep -q "^---" && echo "OK: {}"' | wc -l` returns 5
  - **Done when**: All command files valid, plugin loads without error
  - **Commit**: `chore(interview): pass local CI` (if fixes needed)

### 4.2 Create PR and verify CI

- [x] 4.2 Create PR and verify CI passes
  - **Do**:
    1. Verify current branch is `feat/adaptive-interview`
    2. Stage all changes: `git add plugins/ralph-specum/commands/*.md`
    3. Commit: `feat(interview): implement adaptive interview system`
    4. Push: `git push -u origin feat/adaptive-interview`
    5. Create PR: `gh pr create --title "feat: Adaptive Interview System" --body "..."`
  - **Verify**: `gh pr checks --watch` shows all checks passing
  - **Done when**: PR created, all CI checks green
  - **Commit**: None (PR creation task)

### 4.3 V6 [VERIFY] AC checklist

- [x] 4.3 [VERIFY] AC checklist: verify all acceptance criteria met
  - **Do**: Verify each acceptance criterion programmatically:
    1. AC-1.1: `grep -c "AskUserQuestion:" plugins/ralph-specum/commands/start.md` >= 3 (single questions)
    2. AC-2.1: `grep -c "codebase fact" plugins/ralph-specum/commands/start.md` >= 1 (classification exists)
    3. AC-3.1: `grep -c "Intent Classification" plugins/ralph-specum/commands/start.md` >= 1
    4. AC-4.1: `grep -c "completion signal\|done\|proceed" plugins/ralph-specum/commands/start.md` >= 1
    5. AC-5.1: `grep -c "Interview Responses" plugins/ralph-specum/commands/start.md` >= 1 (accumulator)
    6. AC-6.1: `grep -c "Spec Scanner" plugins/ralph-specum/commands/start.md` >= 1
    7. AC-8.1: `grep -c "Skip interview if --quick" plugins/ralph-specum/commands/start.md` >= 1
  - **Verify**: All grep commands return expected values
  - **Done when**: All acceptance criteria confirmed met
  - **Commit**: None

## Notes

### POC Shortcuts Taken
- No automated E2E testing - verification via manual plugin test
- Question piping uses simple {var} replacement, not a full template engine
- Spec scanner uses keyword matching, not semantic similarity
- Intent classification uses keyword patterns, not ML/AI

### Production TODOs (for future specs)
- Add comprehensive E2E tests using browser automation
- Consider semantic spec matching for better related spec discovery
- Add analytics to track interview completion rates
- Add ability to customize question pools per project type

### Verification Commands Reference

| Type | Command | Purpose |
|------|---------|---------|
| Plugin Load | `claude --plugin-dir ./plugins/ralph-specum` | Verify plugin loads |
| Workflow Test | `/ralph-specum:start test-feature "goal"` | Test interview flow |
| CI Status | `gh pr checks` | Verify CI passes |
| File Validation | `head -5 <file> \| grep "^---"` | Verify frontmatter |
