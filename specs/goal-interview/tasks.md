---
spec: goal-interview
phase: tasks
total_tasks: 14
created: 2026-01-15
---

# Tasks: Goal Interview

## Phase 1: Make It Work (POC)

Focus: Add interview logic to start.md (goal clarification) and 4 phase commands. Remove tools field from 5 agents. All 10 files modified in POC phase per user decision.

- [x] 1.1 Remove tools field from research-analyst.md
  - **Do**: Delete line 5 containing `tools: [Read, Write, Edit, Glob, Grep, WebFetch, WebSearch, Task]` from frontmatter
  - **Files**: `plugins/ralph-specum/agents/research-analyst.md`
  - **Done when**: File has no `tools:` line in frontmatter, only name/description/model remain
  - **Verify**: `grep -n "^tools:" plugins/ralph-specum/agents/research-analyst.md` returns nothing
  - **Commit**: `refactor(agents): remove deprecated tools field from research-analyst`
  - _Requirements: FR-14, AC-6.1_
  - _Design: Agent File Cleanup_

- [x] 1.2 Remove tools field from remaining 4 agents
  - **Do**: Delete tools line from frontmatter in each file:
    - product-manager.md line 5: `tools: [Read, Write, Edit, Glob, Grep, WebSearch, Task]`
    - architect-reviewer.md line 5: `tools: [Read, Write, Edit, Bash, Glob, Grep, Task]`
    - task-planner.md line 5: `tools: [Read, Write, Edit, Glob, Grep, Task]`
    - plan-synthesizer.md line 6: `tools: [Read, Write, Edit, Glob, Grep, Task]`
  - **Files**:
    - `plugins/ralph-specum/agents/product-manager.md`
    - `plugins/ralph-specum/agents/architect-reviewer.md`
    - `plugins/ralph-specum/agents/task-planner.md`
    - `plugins/ralph-specum/agents/plan-synthesizer.md`
  - **Done when**: No agent file contains `tools:` line in frontmatter
  - **Verify**: `grep -rn "^tools:" plugins/ralph-specum/agents/` returns nothing
  - **Commit**: `refactor(agents): remove deprecated tools field from all agents`
  - _Requirements: FR-15, FR-16, FR-17, FR-18, AC-6.2, AC-6.3, AC-6.4, AC-6.5_
  - _Design: Agent File Cleanup_

- [x] 1.3 Quality Checkpoint
  - **Do**: Verify agent files still have valid frontmatter structure
  - **Verify**: All commands must pass:
    - Check frontmatter: `head -6 plugins/ralph-specum/agents/*.md` shows name/description/model only
    - No tools field: `grep -rn "^tools:" plugins/ralph-specum/agents/` returns empty
  - **Done when**: All agent frontmatters valid, no tools field present
  - **Commit**: `chore(agents): pass quality checkpoint` (only if fixes needed)

- [x] 1.4 Add goal interview to start.md (pre-research)
  - **Do**:
    1. start.md already has AskUserQuestion in allowed-tools (line 5)
    2. Add goal interview section in "New Flow" after spec directory created, before research-analyst invocation:
       - Quick mode check (skip if --quick in arguments)
       - Questions about overall goal: "What problem are you solving?", "Any constraints or must-haves?", "Success criteria?"
       - Adaptive depth for "Other" selections (max 5 rounds)
       - Store responses in .progress.md under "Goal Context"
    3. Pass goal interview context to research-analyst delegation
  - **Files**: `plugins/ralph-specum/commands/start.md`
  - **Done when**: Normal mode asks goal questions before research. --quick skips interview.
  - **Verify**: Manual test: `/ralph-specum:start test --quick` skips questions, `/ralph-specum:start test2 "Some goal"` asks questions
  - **Commit**: `feat(start): add goal interview before research phase`
  - _Requirements: Goal clarification before research_
  - _Design: Pre-research interview_

- [x] 1.5 Add interview to research.md
  - **Do**:
    1. Add `AskUserQuestion` to allowed-tools in frontmatter line 4
    2. Add interview section between "## Validate" and "## Execute Research" with:
       - Quick mode check (skip if --quick in $ARGUMENTS)
       - Questions about technical approach and known constraints
       - Adaptive depth logic for "Other" selections (max 5 rounds)
       - Format responses as Interview Context to pass to subagent
    3. Update Task delegation prompt to include interview context
    4. Add instruction for subagent to store responses in "User Context" section
  - **Files**: `plugins/ralph-specum/commands/research.md`
  - **Done when**: Command has AskUserQuestion in allowed-tools, interview section with questions, quick mode bypass, context passed to subagent
  - **Verify**: Manual test: run `/ralph-specum:research` on test spec, verify questions appear
  - **Commit**: `feat(research): add user interview before research phase`
  - _Requirements: FR-1, FR-2, FR-6, FR-10, FR-11, FR-12, AC-1.1, AC-1.5, AC-2.1, AC-2.2, AC-2.4, AC-3.1_
  - _Design: Interview Logic Template, Question Format Examples (Research)_

- [x] 1.6 Add interview to requirements.md
  - **Do**:
    1. Add `AskUserQuestion` to allowed-tools in frontmatter line 4
    2. Add interview section between "## Gather Context" and "## Execute Requirements" with:
       - Quick mode check (skip if --quick in $ARGUMENTS)
       - Questions about user types and priority tradeoffs
       - Adaptive depth logic for "Other" selections (max 5 rounds)
       - Format responses as Interview Context
    3. Update Task delegation prompt to include interview context
    4. Add instruction for subagent to store responses in "User Decisions" section
  - **Files**: `plugins/ralph-specum/commands/requirements.md`
  - **Done when**: Command has AskUserQuestion in allowed-tools, interview section with questions
  - **Verify**: Manual test: run `/ralph-specum:requirements` on test spec, verify questions appear
  - **Commit**: `feat(requirements): add user interview before requirements phase`
  - _Requirements: FR-1, FR-3, FR-7, FR-10, FR-11, FR-12, AC-1.2, AC-1.5, AC-2.1, AC-2.2, AC-2.4, AC-3.1_
  - _Design: Interview Logic Template, Question Format Examples (Requirements)_

- [x] 1.7 Quality Checkpoint
  - **Do**: Verify research.md and requirements.md have valid structure
  - **Verify**: All commands must pass:
    - AskUserQuestion in tools: `grep "AskUserQuestion" plugins/ralph-specum/commands/research.md plugins/ralph-specum/commands/requirements.md`
    - Quick mode check present: `grep -l "\-\-quick" plugins/ralph-specum/commands/research.md plugins/ralph-specum/commands/requirements.md`
  - **Done when**: Both files have AskUserQuestion tool and quick mode bypass
  - **Commit**: `chore(commands): pass quality checkpoint` (only if fixes needed)

- [x] 1.8 Add interview to design.md
  - **Do**:
    1. Add `AskUserQuestion` to allowed-tools in frontmatter line 4
    2. Add interview section between "## Gather Context" and "## Execute Design" with:
       - Quick mode check (skip if --quick in $ARGUMENTS)
       - Questions about architecture style and technology constraints
       - Adaptive depth logic for "Other" selections (max 5 rounds)
       - Format responses as Interview Context
    3. Update Task delegation prompt to include interview context
    4. Add instruction for subagent to store responses in "Design Inputs" section
  - **Files**: `plugins/ralph-specum/commands/design.md`
  - **Done when**: Command has AskUserQuestion in allowed-tools, interview section with questions
  - **Verify**: Manual test: run `/ralph-specum:design` on test spec, verify questions appear
  - **Commit**: `feat(design): add user interview before design phase`
  - _Requirements: FR-1, FR-4, FR-8, FR-10, FR-11, FR-12, AC-1.3, AC-1.5, AC-2.1, AC-2.2, AC-2.4, AC-3.1_
  - _Design: Interview Logic Template, Question Format Examples (Design)_

- [x] 1.9 Add interview to tasks.md
  - **Do**:
    1. Add `AskUserQuestion` to allowed-tools in frontmatter line 4
    2. Add interview section between "## Gather Context" and "## Execute Tasks Generation" with:
       - Quick mode check (skip if --quick in $ARGUMENTS)
       - Questions about testing depth and deployment considerations
       - Adaptive depth logic for "Other" selections (max 5 rounds)
       - Format responses as Interview Context
    3. Update Task delegation prompt to include interview context
    4. Add instruction for subagent to store responses in "Execution Context" section
  - **Files**: `plugins/ralph-specum/commands/tasks.md`
  - **Done when**: Command has AskUserQuestion in allowed-tools, interview section with questions
  - **Verify**: Manual test: run `/ralph-specum:tasks` on test spec, verify questions appear
  - **Commit**: `feat(tasks): add user interview before tasks phase`
  - _Requirements: FR-1, FR-5, FR-9, FR-10, FR-11, FR-12, AC-1.4, AC-1.5, AC-2.1, AC-2.2, AC-2.4, AC-3.1_
  - _Design: Interview Logic Template, Question Format Examples (Tasks)_

- [x] 1.10 Quality Checkpoint
  - **Do**: Verify all 4 command files have valid interview structure
  - **Verify**: All commands must pass:
    - AskUserQuestion in all: `grep -l "AskUserQuestion" plugins/ralph-specum/commands/research.md plugins/ralph-specum/commands/requirements.md plugins/ralph-specum/commands/design.md plugins/ralph-specum/commands/tasks.md | wc -l` equals 4
    - Quick mode in all: `grep -l "\-\-quick" plugins/ralph-specum/commands/research.md plugins/ralph-specum/commands/requirements.md plugins/ralph-specum/commands/design.md plugins/ralph-specum/commands/tasks.md | wc -l` equals 4
  - **Done when**: All 4 commands have interview logic with quick mode bypass
  - **Commit**: `chore(commands): pass quality checkpoint` (only if fixes needed)

- [x] 1.11 POC Checkpoint
  - **Do**: Verify full interview flow works end-to-end
  - **Done when**:
    - All 5 agents have no tools field
    - start.md has goal interview (pre-research)
    - All 4 phase commands have AskUserQuestion and interview logic
    - Quick mode (--quick) skips all interviews
    - Normal mode shows interview questions
  - **Verify**: Manual test full workflow:
    1. Create test spec: `/ralph-specum:start test-interview "Test goal"`
    2. Verify goal interview questions appear in start
    3. Verify research interview questions appear
    4. Test --quick mode skips all questions
  - **Commit**: `feat(interview): complete POC for goal interview feature`

## Phase 2: Refactoring

Not needed per user decision. POC changes are simple markdown modifications with no code to refactor.

## Phase 3: Testing

Manual verification only per user decision. No automated test scripts for plugin commands.

- [x] 3.1 Manual verification of interview flow
  - **Do**: Test complete interview workflow:
    1. Create fresh spec without --quick flag
    2. Verify goal interview appears in start (pre-research)
    3. Verify research interview appears with 2 questions
    4. Select "Other" and verify follow-up question appears
    5. Complete research, verify User Context section in research.md
    6. Run requirements, verify different questions appear
    7. Run design, verify architecture questions appear
    8. Run tasks, verify testing/deployment questions appear
    9. Test --quick mode skips all interviews
  - **Done when**: All interview flows work (start + 4 phases), quick mode bypasses all
  - **Verify**: Manual test passes all steps above
  - **Commit**: `test(interview): verify interview flow manually`
  - _Requirements: AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-3.1, AC-4.1, AC-4.2, AC-4.3, AC-4.4_

## Phase 4: Quality Gates

- [x] 4.1 Bump plugin version
  - **Do**: Update version in plugin.json from 1.3.0 to 1.4.0 (minor version for new feature)
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`
  - **Done when**: Version is 1.4.0
  - **Verify**: `cat plugins/ralph-specum/.claude-plugin/plugin.json | grep version`
  - **Commit**: `chore(plugin): bump version to 1.4.0 for goal interview feature`

- [x] 4.2 Create PR and verify CI
  - **Do**:
    1. Verify current branch is feat/goal-interview: `git branch --show-current`
    2. Stage all changes: `git add -A`
    3. Push branch: `git push -u origin feat/goal-interview`
    4. Create PR: `gh pr create --title "feat: add goal interview to phase commands" --body "Add user interviews using AskUserQuestion before each phase delegation. Includes quick mode bypass and removes deprecated tools field from agents."`
  - **Verify**: `gh pr checks --watch` all green
  - **Done when**: PR created, CI passes, ready for review
  - **If CI fails**: Read failure, fix locally, push, re-verify

## Notes

- **POC shortcuts taken**: None needed, changes are simple markdown additions
- **Production TODOs**: None, feature is complete after POC
- **Files modified**: 10 total (5 commands + 5 agents)
- **Testing approach**: Manual only per user decision
