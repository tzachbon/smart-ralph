---
spec: reviewer-subagent
phase: tasks
total_tasks: 19
created: 2026-02-17
generated: auto
---

# Tasks: reviewer-subagent

## Phase 1: Make It Work (POC)

Focus: Create the reviewer agent and wire it into one phase command to validate the concept end-to-end.

- [x] 1.1 Create spec-reviewer.md agent definition
  - **Do**: Create `plugins/ralph-specum/agents/spec-reviewer.md` with:
    1. Frontmatter: name=spec-reviewer, description including trigger phrases ("review artifact", "validate spec output", "check quality"), model=inherit
    2. Core role: read-only reviewer that validates artifacts against rubrics
    3. When Invoked section: receives artifactType, artifact content, upstream artifacts, iteration number via Task delegation
    4. Type-specific rubrics for: research, requirements, design, tasks, execution (inline in agent)
    5. Structured output format: findings table (Dimension/Status/Finding), summary, feedback for revision
    6. Signal protocol: REVIEW_PASS or REVIEW_FAIL at end of output
    7. Mandatory blocks: never modify files, always output signal, read artifact content from prompt
    8. Iteration awareness: note which iteration this is, reference prior findings if provided
  - **Files**: `plugins/ralph-specum/agents/spec-reviewer.md`
  - **Done when**: Agent file exists with frontmatter, rubrics, signal protocol, and structured output format
  - **Verify**: `grep -q "REVIEW_PASS" plugins/ralph-specum/agents/spec-reviewer.md && grep -q "REVIEW_FAIL" plugins/ralph-specum/agents/spec-reviewer.md && grep -q "name: spec-reviewer" plugins/ralph-specum/agents/spec-reviewer.md`
  - **Commit**: `feat(reviewer): create spec-reviewer agent definition`
  - _Requirements: FR-1_
  - _Design: Component A_

- [x] 1.2 Add review loop to research.md command (POC integration)
  - **Do**: Modify `plugins/ralph-specum/commands/research.md` to add a review loop section:
    1. After the "Merge Results" section and before "Walkthrough (Before Review)", add a new section "## Artifact Review"
    2. Section should: read research.md content, invoke spec-reviewer via Task tool with artifactType="research", parse REVIEW_PASS/REVIEW_FAIL response
    3. On REVIEW_FAIL (iteration < 3): re-invoke research-analyst with reviewer feedback, re-merge, re-review
    4. On REVIEW_FAIL (iteration >= 3): append warnings to .progress.md, proceed to walkthrough
    5. On REVIEW_PASS: proceed to walkthrough
    6. Add mandatory block: "Review loop must complete before walkthrough. Max 3 iterations."
    7. Add quick mode check: skip review if --quick flag detected
  - **Files**: `plugins/ralph-specum/commands/research.md`
  - **Done when**: Research command contains review loop section with Task delegation to spec-reviewer, iteration tracking, graceful degradation
  - **Verify**: `grep -q "spec-reviewer" plugins/ralph-specum/commands/research.md && grep -q "REVIEW_PASS" plugins/ralph-specum/commands/research.md && grep -q "Artifact Review" plugins/ralph-specum/commands/research.md`
  - **Commit**: `feat(reviewer): add review loop to research command`
  - _Requirements: FR-2, FR-8, FR-9_
  - _Design: Component B_

- [x] 1.3 [VERIFY] POC checkpoint - reviewer agent and research integration
  - **Do**: Verify the spec-reviewer agent and research.md review loop are correctly wired
  - **Done when**: spec-reviewer.md exists with all required sections, research.md has review loop, patterns match existing agent/command conventions
  - **Verify**: `grep -q "name: spec-reviewer" plugins/ralph-specum/agents/spec-reviewer.md && grep -q "model: inherit" plugins/ralph-specum/agents/spec-reviewer.md && grep -q "Artifact Review" plugins/ralph-specum/commands/research.md && grep -q "iteration" plugins/ralph-specum/commands/research.md`
  - **Commit**: `chore(qa): pass POC quality checkpoint`

## Phase 2: Complete Integration

After POC validated, wire reviewer into all remaining phase commands and execution flow.

- [x] 2.1 Add review loop to requirements.md command
  - **Do**: Modify `plugins/ralph-specum/commands/requirements.md`:
    1. After "Execute Requirements" section (after product-manager Task completes) and before "Walkthrough (Before Review)", add "## Artifact Review" section
    2. Same pattern as research.md: invoke spec-reviewer with artifactType="requirements", pass requirements.md content + research.md as upstream
    3. On REVIEW_FAIL: re-invoke product-manager with feedback, re-review (max 3)
    4. On REVIEW_PASS or max iterations: proceed to walkthrough
    5. Add quick mode check: skip if --quick
  - **Files**: `plugins/ralph-specum/commands/requirements.md`
  - **Done when**: Requirements command has review loop section matching research.md pattern
  - **Verify**: `grep -q "spec-reviewer" plugins/ralph-specum/commands/requirements.md && grep -q "REVIEW_PASS" plugins/ralph-specum/commands/requirements.md && grep -q "Artifact Review" plugins/ralph-specum/commands/requirements.md`
  - **Commit**: `feat(reviewer): add review loop to requirements command`
  - _Requirements: FR-3_
  - _Design: Component B_

- [x] 2.2 Add review loop to design.md command
  - **Do**: Modify `plugins/ralph-specum/commands/design.md`:
    1. After "Execute Design" section (after architect-reviewer Task completes) and before "Walkthrough (Before Review)", add "## Artifact Review" section
    2. Invoke spec-reviewer with artifactType="design", pass design.md + requirements.md + research.md as upstream
    3. On REVIEW_FAIL: re-invoke architect-reviewer with feedback, re-review (max 3)
    4. On REVIEW_PASS or max iterations: proceed to walkthrough
    5. Add quick mode check: skip if --quick
  - **Files**: `plugins/ralph-specum/commands/design.md`
  - **Done when**: Design command has review loop section
  - **Verify**: `grep -q "spec-reviewer" plugins/ralph-specum/commands/design.md && grep -q "REVIEW_PASS" plugins/ralph-specum/commands/design.md && grep -q "Artifact Review" plugins/ralph-specum/commands/design.md`
  - **Commit**: `feat(reviewer): add review loop to design command`
  - _Requirements: FR-4_
  - _Design: Component B_

- [x] 2.3 Add review loop to tasks.md command
  - **Do**: Modify `plugins/ralph-specum/commands/tasks.md`:
    1. After "Execute Tasks Generation" section (after task-planner Task completes) and before "Walkthrough (Before Review)", add "## Artifact Review" section
    2. Invoke spec-reviewer with artifactType="tasks", pass tasks.md + design.md + requirements.md as upstream
    3. On REVIEW_FAIL: re-invoke task-planner with feedback, re-review (max 3)
    4. On REVIEW_PASS or max iterations: proceed to walkthrough
    5. Add quick mode check: skip if --quick
  - **Files**: `plugins/ralph-specum/commands/tasks.md`
  - **Done when**: Tasks command has review loop section
  - **Verify**: `grep -q "spec-reviewer" plugins/ralph-specum/commands/tasks.md && grep -q "REVIEW_PASS" plugins/ralph-specum/commands/tasks.md && grep -q "Artifact Review" plugins/ralph-specum/commands/tasks.md`
  - **Commit**: `feat(reviewer): add review loop to tasks command`
  - _Requirements: FR-5_
  - _Design: Component B_

- [x] 2.4 [VERIFY] Phase commands integration checkpoint
  - **Do**: Verify all four phase commands have review loops with consistent patterns
  - **Done when**: All four commands (research, requirements, design, tasks) contain Artifact Review section, spec-reviewer delegation, REVIEW_PASS/FAIL handling, iteration limits, quick mode skip
  - **Verify**: `for cmd in research requirements design tasks; do grep -q "Artifact Review" "plugins/ralph-specum/commands/${cmd}.md" && grep -q "spec-reviewer" "plugins/ralph-specum/commands/${cmd}.md" || echo "FAIL: ${cmd}"; done`
  - **Commit**: `chore(qa): pass phase commands review integration checkpoint`

- [x] 2.5 Add execution review to implement.md coordinator
  - **Do**: Modify `plugins/ralph-specum/commands/implement.md`:
    1. In Section 7 "Verification Layers", after Layer 4 (TASK_COMPLETE signal verification), add Layer 5: "Artifact Review"
    2. Layer 5: invoke spec-reviewer with artifactType="execution", pass changed files from task, design.md, requirements.md
    3. On REVIEW_PASS: proceed to State Update (section 8)
    4. On REVIEW_FAIL (iteration < 3): reviewer provides feedback. Coordinator can:
       a. Add fix tasks to tasks.md (same pattern as Section 6c fix task generator)
       b. Log suggested spec updates in .progress.md for manual review
    5. On REVIEW_FAIL (iteration >= 3): proceed with warnings logged
    6. Update the "Verification Summary" to list 5 layers instead of 4
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: implement.md has Layer 5 in verification section with spec-reviewer delegation and iteration handling
  - **Verify**: `grep -q "Layer 5" plugins/ralph-specum/commands/implement.md && grep -q "spec-reviewer" plugins/ralph-specum/commands/implement.md && grep -q "Artifact Review" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `feat(reviewer): add execution review to coordinator verification layers`
  - _Requirements: FR-6_
  - _Design: Component C_

- [x] 2.6 Add review step to plan-synthesizer.md for quick mode
  - **Do**: Modify `plugins/ralph-specum/agents/plan-synthesizer.md`:
    1. After "Generate all four artifacts in sequence" step (step 4) and before "Append learnings" (step 6), add step: "Review generated artifacts"
    2. Review step: for each artifact (research, requirements, design, tasks), invoke spec-reviewer via Task tool
    3. On REVIEW_FAIL: revise the artifact inline and re-review (max 3 iterations per artifact)
    4. On REVIEW_PASS or max iterations: continue to next artifact
    5. Update the numbered steps in "When Invoked" section to include the review step
    6. Add a "## Artifact Review" section with review loop implementation details
  - **Files**: `plugins/ralph-specum/agents/plan-synthesizer.md`
  - **Done when**: plan-synthesizer has review step after artifact generation with bounded iteration loop
  - **Verify**: `grep -q "spec-reviewer" plugins/ralph-specum/agents/plan-synthesizer.md && grep -q "REVIEW_PASS" plugins/ralph-specum/agents/plan-synthesizer.md && grep -q "Artifact Review" plugins/ralph-specum/agents/plan-synthesizer.md`
  - **Commit**: `feat(reviewer): add review step to plan-synthesizer quick mode`
  - _Requirements: FR-7, FR-12_
  - _Design: Component D_

- [x] 2.7 Add review logging to .progress.md
  - **Do**: Update review loop sections in all modified commands to log review findings:
    1. In each review loop (research, requirements, design, tasks commands + implement.md), after each review iteration, append to .progress.md:
       ```markdown
       ### Review: $artifactType (Iteration $N)
       - Status: REVIEW_PASS/REVIEW_FAIL
       - Findings: [summary of findings]
       - Action: [revision applied / warnings appended / proceeded]
       ```
    2. On graceful degradation (max iterations), append warning:
       ```markdown
       ### Review Warning: $artifactType
       - Max iterations (3) reached without REVIEW_PASS
       - Proceeding with best available version
       - Outstanding issues: [list from last REVIEW_FAIL]
       ```
    3. Ensure logging is consistent across all commands
  - **Files**: `plugins/ralph-specum/commands/research.md`, `plugins/ralph-specum/commands/requirements.md`, `plugins/ralph-specum/commands/design.md`, `plugins/ralph-specum/commands/tasks.md`, `plugins/ralph-specum/commands/implement.md`
  - **Done when**: All review loops include .progress.md logging for each iteration and graceful degradation warnings
  - **Verify**: `grep -c "progress.md" plugins/ralph-specum/commands/research.md | grep -v "^0$" && grep -q "Review Warning" plugins/ralph-specum/commands/research.md`
  - **Commit**: `feat(reviewer): add review findings logging to progress tracking`
  - _Requirements: FR-10_
  - _Design: Component B_

- [x] 2.8 [VERIFY] Full integration checkpoint
  - **Do**: Verify complete reviewer integration across all components
  - **Done when**: spec-reviewer.md agent exists, all 4 phase commands have review loops, implement.md has Layer 5, plan-synthesizer has review step, progress logging in all loops
  - **Verify**: `test -f plugins/ralph-specum/agents/spec-reviewer.md && for cmd in research requirements design tasks; do grep -q "Artifact Review" "plugins/ralph-specum/commands/${cmd}.md" || echo "FAIL: ${cmd}"; done && grep -q "Layer 5" plugins/ralph-specum/commands/implement.md && grep -q "spec-reviewer" plugins/ralph-specum/agents/plan-synthesizer.md`
  - **Commit**: `chore(qa): pass full reviewer integration checkpoint`

## Phase 3: Refinement and Version Bump

- [x] 3.1 Bump version in plugin.json
  - **Do**: Update `plugins/ralph-specum/.claude-plugin/plugin.json`:
    1. Change version from "3.4.0" to "3.5.0"
    2. Update description to mention reviewer capability
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`
  - **Done when**: plugin.json version is "3.5.0"
  - **Verify**: `grep -q '"3.5.0"' plugins/ralph-specum/.claude-plugin/plugin.json`
  - **Commit**: `chore(plugin): bump ralph-specum version to 3.5.0`
  - _Requirements: FR-11_
  - _Design: File Structure_

- [x] 3.2 Bump version in marketplace.json
  - **Do**: Update `.claude-plugin/marketplace.json`:
    1. Change ralph-specum version from "3.4.0" to "3.5.0"
    2. Update description to mention reviewer capability
  - **Files**: `.claude-plugin/marketplace.json`
  - **Done when**: marketplace.json ralph-specum version is "3.5.0"
  - **Verify**: `grep -q '"3.5.0"' .claude-plugin/marketplace.json`
  - **Commit**: `chore(plugin): bump marketplace version to 3.5.0`
  - _Requirements: FR-11_
  - _Design: File Structure_

- [x] 3.3 Review and refine spec-reviewer rubrics
  - **Do**: Re-read spec-reviewer.md and refine rubrics:
    1. Ensure each rubric dimension has clear pass/fail criteria (not vague)
    2. Add examples of PASS and FAIL for each dimension
    3. Ensure execution rubric cross-references design.md component responsibilities
    4. Verify rubric dimensions match the table in design.md
    5. Add edge case handling: empty artifacts, missing upstream artifacts
  - **Files**: `plugins/ralph-specum/agents/spec-reviewer.md`
  - **Done when**: Each rubric has clear criteria, examples, and edge case handling
  - **Verify**: `grep -c "PASS" plugins/ralph-specum/agents/spec-reviewer.md | xargs test 5 -le`
  - **Commit**: `refactor(reviewer): refine rubric criteria and add examples`
  - _Requirements: FR-1_
  - _Design: Component A_

- [ ] 3.4 Ensure error handling in all review loops
  - **Do**: Review all modified commands for error handling:
    1. Reviewer fails to output signal -> treat as REVIEW_PASS
    2. Phase agent fails during revision -> retry once, then use original artifact
    3. Iteration counter edge cases -> default to 1
    4. Add these error handling rules consistently to all review loop sections
  - **Files**: `plugins/ralph-specum/commands/research.md`, `plugins/ralph-specum/commands/requirements.md`, `plugins/ralph-specum/commands/design.md`, `plugins/ralph-specum/commands/tasks.md`, `plugins/ralph-specum/commands/implement.md`
  - **Done when**: All review loops have consistent error handling for reviewer failures, phase agent failures, and edge cases
  - **Verify**: `grep -q "treat as REVIEW_PASS" plugins/ralph-specum/commands/research.md && grep -q "treat as REVIEW_PASS" plugins/ralph-specum/commands/requirements.md`
  - **Commit**: `refactor(reviewer): add consistent error handling to review loops`
  - _Design: Error Handling_

- [ ] 3.5 [VERIFY] Refinement checkpoint
  - **Do**: Verify version bumps and refinements
  - **Done when**: Version is 3.5.0 in both files, rubrics refined, error handling consistent
  - **Verify**: `grep -q '"3.5.0"' plugins/ralph-specum/.claude-plugin/plugin.json && grep -q '"3.5.0"' .claude-plugin/marketplace.json && grep -q "treat as REVIEW_PASS" plugins/ralph-specum/commands/research.md`
  - **Commit**: `chore(qa): pass refinement checkpoint`

## Phase 4: Quality Gates

- [ ] 4.1 [VERIFY] Full pattern consistency check
  - **Do**: Verify all files follow plugin conventions:
    1. spec-reviewer.md has correct frontmatter (name, description, model: inherit)
    2. All modified commands maintain existing structure (no broken sections)
    3. Review loop pattern is identical across all four phase commands
    4. Signal names (REVIEW_PASS/REVIEW_FAIL) are consistent everywhere
    5. Mandatory blocks are properly formatted with `<mandatory>` tags
  - **Done when**: Pattern consistency verified across all files
  - **Verify**: `grep -q "model: inherit" plugins/ralph-specum/agents/spec-reviewer.md && grep -c "REVIEW_PASS" plugins/ralph-specum/commands/research.md && grep -c "REVIEW_PASS" plugins/ralph-specum/commands/requirements.md && grep -c "REVIEW_PASS" plugins/ralph-specum/commands/design.md && grep -c "REVIEW_PASS" plugins/ralph-specum/commands/tasks.md`
  - **Commit**: `chore(qa): pass full pattern consistency check`

- [ ] 4.2 [VERIFY] AC checklist verification
  - **Do**: Verify all acceptance criteria from requirements.md are met:
    - AC-1.1 through AC-1.7 (phase reviews)
    - AC-2.1 through AC-2.5 (execution reviews)
    - AC-3.1 through AC-3.4 (iteration loop)
    - AC-4.1 through AC-4.4 (quick mode review)
    - AC-5.1 through AC-5.5 (agent definition)
  - **Done when**: All ACs verified with evidence
  - **Verify**: `test -f plugins/ralph-specum/agents/spec-reviewer.md && grep -q "Layer 5" plugins/ralph-specum/commands/implement.md && grep -q "spec-reviewer" plugins/ralph-specum/agents/plan-synthesizer.md && grep -q '"3.5.0"' plugins/ralph-specum/.claude-plugin/plugin.json`
  - **Commit**: `chore(qa): pass AC checklist verification`

## Phase 5: PR Lifecycle

- [ ] 5.1 Create PR and verify CI
  - **Do**: Push branch, create PR with gh CLI
  - **Verify**: `gh pr checks --watch` all green
  - **Done when**: PR created and CI passes
  - **Commit**: None (PR creation, no code change)

## Notes

- **POC shortcuts taken**: Only research.md wired in Phase 1 to validate pattern before replicating to all commands
- **Production TODOs in Phase 2**: Wire remaining 3 phase commands, execution review, quick mode review
- **No build/test step**: This is a markdown plugin. Verification = grep pattern matching
- **Review is additive**: Existing flow unchanged. Review is an additional step inserted before awaitingApproval
- **Backwards compatible**: Review loops include quick mode skip (--quick flag) for existing quick mode behavior
