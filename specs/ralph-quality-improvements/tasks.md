# Tasks: ralph-quality-improvements

Total tasks: 25 (12 implementation + 4 verification checkpoints + 9 fix tasks)

---

## Phase 1: Make It Work

### Track A — Spec Quality

- [x] 1.1 [POC] FR-A1: Insert Document Self-Review Checklist in architect-reviewer.md
  - **Do**: Insert the `## Document Self-Review Checklist` section (with 4 steps in `<mandatory>` block) into `plugins/ralph-specum/agents/architect-reviewer.md` AFTER `## Analysis Process` section and BEFORE `## Final Step: Set Awaiting Approval`. Use section names as anchor — ## Quality Checklist appears twice in the file (once inside a code block), so use ## Analysis Process as the unambiguous preceding anchor. Also add checklist item to Quality Checklist as the penúltimo item (before "Set awaitingApproval in state").
  - **Files**: `plugins/ralph-specum/agents/architect-reviewer.md`
  - **Done when**: Section inserted at correct anchor position; Quality Checklist has new item as penúltimo; all 4 step headings present (Type consistency, Duplicate section detection, Ordering and concurrency notes, Internal contradiction scan)
  - **Verify**: `grep -n "Document Self-Review Checklist" plugins/ralph-specum/agents/architect-reviewer.md`; `grep -n "Document Self-Review Checklist passed" plugins/ralph-specum/agents/architect-reviewer.md`
  - **Commit**: `feat(architect-reviewer): add Document Self-Review Checklist for spec quality`
  - _Requirements: FR-A1_

- [x] 1.2 [POC] FR-A3b: Insert On Design Update section in architect-reviewer.md
  - **Do**: Insert the `## On Design Update` section (with 5-step reconciliation process in `<mandatory>` block) into `plugins/ralph-specum/agents/architect-reviewer.md` AFTER `## Final Step: Set Awaiting Approval` section and BEFORE `## Karpathy Rules`. After task 1.1 inserts ## Document Self-Review Checklist between ## Analysis Process and ## Final Step: Set Awaiting Approval, the correct insertion point for ## On Design Update is after ## Final Step: Set Awaiting Approval. Also add checklist item to Quality Checklist.
  - **Files**: `plugins/ralph-specum/agents/architect-reviewer.md`
  - **Done when**: Section inserted at correct anchor position; Quality Checklist has new item; 5 reconciliation steps present
  - **💡 HINT**: The current file has the 5 steps OUTSIDE `<mandatory>`. You need to WRAP the steps AND intro text inside `<mandatory>...</mandatory>`. The `<mandatory>` block should replace or include the current anchor note. Look at how `## Document Self-Review Checklist` (task 1.1) does it — `<mandatory>` opens BEFORE the steps and closes AFTER them. That's the pattern to follow.
  - **Verify**: `grep -n "## On Design Update" plugins/ralph-specum/agents/architect-reviewer.md`; `grep -n "If updating existing design.md" plugins/ralph-specum/agents/architect-reviewer.md`
  - **Commit**: `feat(architect-reviewer): add On Design Update reconciliation section`
  - _Requirements: FR-A3b_

- [x] 1.3 [VERIFY] Track A checkpoint 1 — architect-reviewer.md
  - **Do**: Verify FR-A1 and FR-A3b insertions in architect-reviewer.md are present and correctly positioned.
  - **Verify**: `grep -n "Document Self-Review Checklist" plugins/ralph-specum/agents/architect-reviewer.md`; `grep -n "On Design Update" plugins/ralph-specum/agents/architect-reviewer.md`; both non-empty
  - **⚠️ REVERTED x2**: Cannot pass while task 1.2 remains incomplete
  - _Requirements: FR-A1, FR-A3b_

- [x] 1.4 [POC] FR-A2: Insert Concurrency & Ordering Risks in design.md template
  - **Do**: Insert `## Concurrency & Ordering Risks` section (with table structure: Operation | Required Order | Risk if Inverted) into `plugins/ralph-specum/templates/design.md` AFTER `## Performance Considerations` section and BEFORE `## Test Strategy` section. Include example row as reference pattern.
  - **Files**: `plugins/ralph-specum/templates/design.md`
  - **Done when**: Section inserted between correct anchor sections; table has correct 3-column structure with headers; example row present
  - **Verify**: `grep -n "Concurrency & Ordering Risks" plugins/ralph-specum/templates/design.md`; section between Performance Considerations and Test Strategy
  - **Commit**: `feat(templates): add Concurrency & Ordering Risks section to design.md`
  - _Requirements: FR-A2_

- [x] 1.5 [VERIFY] Track A checkpoint 2 — design.md template
  - **Do**: Verify FR-A2 insertion in templates/design.md is present and correctly positioned between Performance Considerations and Test Strategy.
  - **Verify**: `grep -n "Concurrency & Ordering Risks" plugins/ralph-specum/templates/design.md`; `grep -n "Performance Considerations" plugins/ralph-specum/templates/design.md`; `grep -n "Test Strategy" plugins/ralph-specum/templates/design.md`; section between the two anchors
  - _Requirements: FR-A2_

- [x] 1.6 [POC] FR-A3: Insert On Requirements Update section in product-manager.md
  - **Do**: Insert `## On Requirements Update` section (with 5-step reconciliation process in `<mandatory>` block) into `plugins/ralph-specum/agents/product-manager.md` AFTER `## Append Learnings` section (line 55) and BEFORE `## Requirements Structure` (line 75). Add checklist item to Quality Checklist.
  - **Files**: `plugins/ralph-specum/agents/product-manager.md`
  - **Done when**: Section inserted at correct anchor position; Quality Checklist has new item; 5 reconciliation steps present
  - **Verify**: `grep -n "On Requirements Update" plugins/ralph-specum/agents/product-manager.md`; `grep -n "If updating existing requirements" plugins/ralph-specum/agents/product-manager.md`
  - **Commit**: `feat(product-manager): add On Requirements Update reconciliation section`
  - _Requirements: FR-A3_

- [x] 1.7 [POC] FR-A4: Insert Type Consistency Pre-Check in spec-executor.md
  - **Do**: Insert `### Type Consistency Pre-Check (typed Python or TypeScript tasks)` subsection into `plugins/ralph-specum/agents/spec-executor.md` inside Implementation Tasks section (after line 86 where data-testid block ends), BEFORE Exit Code Gate. NO `<mandatory>` tag. 5-step verification process.
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: Subsection inserted after data-testid block; 5 verification steps present describing Callable/Awaitable type consistency checking
  - **Verify**: `grep -n "Type Consistency Pre-Check" plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `feat(spec-executor): add Type Consistency Pre-Check subsection`
  - _Requirements: FR-A4_

- [x] 1.8 [VERIFY] Track A checkpoint 3 — product-manager.md + spec-executor.md
  - **Do**: Verify FR-A3 and FR-A4 insertions are present.
  - **Verify**: `grep -n "On Requirements Update" plugins/ralph-specum/agents/product-manager.md`; `grep -n "Type Consistency Pre-Check" plugins/ralph-specum/agents/spec-executor.md`; both non-empty
  - _Requirements: FR-A3, FR-A4_

### Track B — External Reviewer Protocol

- [x] 1.9 [POC] FR-B1: Create task_review.md template
  - **Do**: Create new file `plugins/ralph-specum/templates/task_review.md` with exact structure: title `# Task Review Log`, workflow comment block describing FAIL/WARNING/PASS/PENDING statuses, `## Reviews` section, and entry template with fields (status, severity, reviewed_at, criterion_failed, evidence, fix_hint, resolved_at).
  - **Files**: `plugins/ralph-specum/templates/task_review.md` (NEW)
  - **Done when**: File exists with correct title, workflow comment block, Reviews section, and complete entry template with all required fields
  - **Verify**: `grep -n "Task Review Log" plugins/ralph-specum/templates/task_review.md`; `grep -n "## Reviews" plugins/ralph-specum/templates/task_review.md`; `grep -n "status" plugins/ralph-specum/templates/task_review.md`; `grep -n "severity" plugins/ralph-specum/templates/task_review.md`; `grep -n "reviewed_at" plugins/ralph-specum/templates/task_review.md`; `grep -n "criterion_failed" plugins/ralph-specum/templates/task_review.md`; `grep -n "evidence" plugins/ralph-specum/templates/task_review.md`; `grep -n "fix_hint" plugins/ralph-specum/templates/task_review.md`; `grep -n "resolved_at" plugins/ralph-specum/templates/task_review.md`
  - **Commit**: `feat(templates): add task_review.md for external reviewer protocol`
  - _Requirements: FR-B1_

- [x] 1.10 [VERIFY] Track B checkpoint 1 — task_review.md template
  - **Do**: Verify the new task_review.md template exists with all required structure elements.
  - **Verify**: `test -f plugins/ralph-specum/templates/task_review.md && echo "EXISTS"`; all grep commands for required fields return non-empty
  - _Requirements: FR-B1_

- [x] 1.11 [POC] FR-B2: Insert External Review Protocol in spec-executor.md
  - **Do**: Insert `## External Review Protocol` section (4-step logic in `<mandatory>`) into `plugins/ralph-specum/agents/spec-executor.md` AFTER `## When Invoked` section and BEFORE `## Task Loop` section. Use section names as anchor — file has been modified by prior tasks and line numbers have shifted. FAIL/PENDING/WARNING/PASS handling, appends to .progress.md.
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: Section inserted at correct anchor position; 4-step review reading logic present; FAIL/PENDING/WARNING/PASS status handling documented
  - **Verify**: `grep -n "External Review Protocol" plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `feat(spec-executor): add External Review Protocol section`
  - _Requirements: FR-B2_

- [x] 1.12 [POC] FR-B3: Update stuck-detection with effectiveIterations formula
  - **Do**: In `plugins/ralph-specum/agents/spec-executor.md`, update two sections:
    1. In `## Stuck State Protocol`: Add NOTE: `effectiveIterations = taskIteration + external_unmarks[taskId]` (taskIteration: current session retries; external_unmarks: reviewer cycles, NEVER reset by spec-executor). Use section names as anchor — file has been modified by prior tasks and line numbers have shifted. Update escalation to use `effectiveIterations >= maxTaskIterations` with reason `external-reviewer-repeated-fail`. Message includes "External reviewer has unmarked this task N times. Human investigation required."
    2. In `## Task Loop`: Add effectiveIterations reference near stuck-detection description.
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: Stuck State Protocol has effectiveIterations formula; escalation reason is `external-reviewer-repeated-fail`; formula appears in both Stuck State Protocol and Task Loop
  - **Verify**: `grep -n "effectiveIterations" plugins/ralph-specum/agents/spec-executor.md`; `grep -n "external-reviewer-repeated-fail" plugins/ralph-specum/agents/spec-executor.md`; `grep -n "External reviewer has unmarked" plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `feat(spec-executor): add external_unmarks to stuck-detection with effectiveIterations`
  - _Requirements: FR-B3_

- [x] 1.13 [POC] FR-B4: Document external_unmarks field schema in spec-executor.md
  - **Do**: In `plugins/ralph-specum/agents/spec-executor.md`, in the Task Loop section near where `.ralph-state.json` is documented, add `## external_unmarks field` documentation (type object, default {}, written by reviewer only, read by executor for stuck detection, cumulative, NEVER reset by spec-executor). Use section names as anchor — file has been modified by prior tasks and line numbers have shifted. Include JSON example.
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: Field documentation present with type, default, written-by, read-by, lifetime, and example fields
  - **Verify**: `grep -n "external_unmarks" plugins/ralph-specum/agents/spec-executor.md`; field schema documented with all required attributes
  - **Commit**: `docs(spec-executor): document external_unmarks field schema`
  - _Requirements: FR-B4_

- [x] 1.14 [VERIFY] Track B checkpoint 2 — spec-executor.md external protocol
  - **Do**: Verify FR-B2, FR-B3, FR-B4 insertions in spec-executor.md are present.
  - **Verify**: `grep -n "External Review Protocol" plugins/ralph-specum/agents/spec-executor.md`; `grep -n "effectiveIterations" plugins/ralph-specum/agents/spec-executor.md` (at least 2 occurrences); `grep -n "external-reviewer-repeated-fail" plugins/ralph-specum/agents/spec-executor.md`; `grep -n "external_unmarks" plugins/ralph-specum/agents/spec-executor.md`
  - _Requirements: FR-B2, FR-B3, FR-B4_

- [x] 1.15 [VERIFY] Regression — surrounding content unchanged
  - **Do**: Verify critical sections in modified files remain intact and unchanged.
  - **Verify**: `grep -n "## Karpathy Rules" plugins/ralph-specum/agents/architect-reviewer.md`; `grep -n "## Final Step: Set Awaiting Approval" plugins/ralph-specum/agents/architect-reviewer.md`; `grep -n "## Test Strategy" plugins/ralph-specum/templates/design.md`; `grep -n "## Requirements Structure" plugins/ralph-specum/agents/product-manager.md`; `grep -n "## Stuck State Protocol" plugins/ralph-specum/agents/spec-executor.md`
  - _Requirements: NFR-1_

- [x] 1.16 [VERIFY] Final — version bump
  - **Do**: Read current version from `plugins/ralph-specum/.claude-plugin/plugin.json`, increment patch version, write updated version to both `plugins/ralph-specum/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. Both must show the same new version (patch +1 from current).
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  - **Done when**: Both files have identical version string bumped by +1 patch from current value
  - **Verify**: Read both files, compute patch bump from current version, verify both show same new version; `grep "version" plugins/ralph-specum/.claude-plugin/plugin.json` and `grep "version" .claude-plugin/marketplace.json` show identical bumped version
  - **Commit**: `chore(version): bump patch version for quality improvements release`
  - _Requirements: NFR-3_

---

## Phase 2: Fix Verified Issues from Unresolved Comments

- [ ] 2.1 [FIX] architect-reviewer.md: Move Document Self-Review Checklist AFTER Quality Checklist
  - **Do**: The `## Document Self-Review Checklist` section (currently at line 347) is positioned BEFORE `## Quality Checklist` (line 382). Per FR-A1 spec, it must be positioned AFTER `## Quality Checklist` and BEFORE `## Final Step: Set Awaiting Approval`. Move the entire section (lines 347-380) to between the Quality Checklist section and the Final Step section.
  - **Files**: `plugins/ralph-specum/agents/architect-reviewer.md`
  - **Done when**: Document Self-Review Checklist appears AFTER Quality Checklist section, BEFORE Final Step
  - **Verify**: `grep -n "Quality Checklist" plugins/ralph-specum/agents/architect-reviewer.md` shows Quality Checklist at lower line number than Document Self-Review Checklist
  - **Commit**: `fix(architect-reviewer): reposition Document Self-Review Checklist after Quality Checklist per FR-A1`
  - _Requirements: FR-A1_

- [ ] 2.2 [FIX] spec-executor.md: Fix External Review Protocol PENDING/FAIL handling
  - **Do**: Update the External Review Protocol section (lines 53-65) to match FR-B2 spec:
    - **PENDING**: Change from "Task needs review. Proceed but note in .progress.md." to "do NOT start the task. Append to .progress.md: 'External review PENDING for task X — waiting one cycle'. Skip this task and move to the next unchecked one."
    - **FAIL**: Add "treat as VERIFICATION_FAIL. Apply fix using fix_hint as starting point, then mark the entry's resolved_at with timestamp before marking the task complete in tasks.md"
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: PENDING handling says to skip task, FAIL handling mentions resolved_at and VERIFICATION_FAIL
  - **Verify**: `grep -A 3 "PENDING" plugins/ralph-specum/agents/spec-executor.md | grep -i "skip"`; `grep -A 3 "FAIL" plugins/ralph-specum/agents/spec-executor.md | grep -i "resolved_at"`
  - **Commit**: `fix(spec-executor): correct External Review Protocol PENDING/FAIL handling per FR-B2`
  - _Requirements: FR-B2_

- [ ] 2.3 [FIX] spec-executor.md: Fix external_unmarks documentation
  - **Do**: Update the external_unmarks field documentation (lines 88-96) to correctly state where the field lives. Change "Written by: External reviewer only (task_review.md)" to "Written by: external reviewer only (increments when unmarking a task in .ralph-state.json)". The field lives in `.ralph-state.json`, not in `task_review.md`.
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: Documentation correctly states external_unmarks is written to .ralph-state.json
  - **Verify**: `grep -A 2 "Written by" plugins/ralph-specum/agents/spec-executor.md | grep ".ralph-state.json"`
  - **Commit**: `docs(spec-executor): correct external_unmarks documentation to reference .ralph-state.json`
  - _Requirements: FR-B4_

- [ ] 2.4 [FIX] spec-executor.md: Reorder Type Consistency Pre-Check AFTER data-testid block
  - **Do**: Move the `### Type Consistency Pre-Check` section (lines 107-123) to AFTER the data-testid update block (which ends around line 145). Per FR-A4 spec, Type Consistency Pre-Check must be "positioned after the existing data-testid update block". Also fix step 5: change from "Add a usage example" to "If both the type AND the usage are ambiguous (neither clearly implies sync or async): ESCALATE before implementing, do not guess."
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: Type Consistency Pre-Check appears AFTER data-testid block; step 5 says ESCALATE if both ambiguous
  - **Verify**: `grep -n "data-testid" plugins/ralph-specum/agents/spec-executor.md` shows lower line number than `grep -n "Type Consistency Pre-Check"`
  - **Commit**: `fix(spec-executor): reposition Type Consistency Pre-Check after data-testid block per FR-A4`
  - _Requirements: FR-A4_

- [ ] 2.5 [FIX] task_review.md: Update PENDING description to match FR-B2
  - **Do**: Update the task_review.md template workflow comment (lines 9-15) to change PENDING description from "Task needs review - proceed but note status" to match FR-B2: "PENDING: reviewer is working on it, spec-executor should not re-mark this task until status changes. spec-executor: skip this task and move to the next unchecked one."
  - **Files**: `plugins/ralph-specum/templates/task_review.md`
  - **Done when**: PENDING description in workflow comment matches FR-B2 spec
  - **Verify**: `grep -A 2 "PENDING" plugins/ralph-specum/templates/task_review.md | grep -i "skip"`
  - **Commit**: `fix(templates): update task_review.md PENDING description to match FR-B2`
  - _Requirements: FR-B1_

- [ ] 2.6 [FIX] Align plugin version with tests
  - **Do**: The tests/interview-framework.bats expects version 4.9.3 but plugin.json and marketplace.json have 4.9.2. Either update the tests to expect 4.9.2 OR bump the version to 4.9.3. Since NFR-3 of this spec already bumped from 4.9.1 → 4.9.2, and the tests expect 4.9.3, bump both files from 4.9.2 → 4.9.3.
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  - **Done when**: Both files show version 4.9.3
  - **Verify**: `grep '"version"' plugins/ralph-specum/.claude-plugin/plugin.json | grep "4.9.3"`; `jq -r '.plugins[] | select(.name == "ralph-specum") | .version' .claude-plugin/marketplace.json | grep "4.9.3"`
  - **Commit**: `chore(version): bump 4.9.2 → 4.9.3 to align with interview-framework.bats tests`
  - _Requirements: NFR-3_

- [ ] 2.7 [FIX] Add YAML frontmatter to ralph-quality-improvements spec files
  - **Do**: Add standard YAML frontmatter to the three spec files that are missing it:
    - `specs/ralph-quality-improvements/requirements.md`
    - `specs/ralph-quality-improvements/design.md`
    - `specs/ralph-quality-improvements/tasks.md`
    
    Each file should have:
    ```yaml
    ---
    spec: ralph-quality-improvements
    phase: <requirements|design|tasks>
    created: <date from git history>
    updated: <date from git history>
    ---
    ```
    
    Use the git history to determine created/updated dates.
  - **Files**: `specs/ralph-quality-improvements/requirements.md`, `specs/ralph-quality-improvements/design.md`, `specs/ralph-quality-improvements/tasks.md`
  - **Done when**: All three files have valid YAML frontmatter at the top
  - **Verify**: `head -6 specs/ralph-quality-improvements/requirements.md | grep "spec: ralph-quality-improvements"`; same for design.md and tasks.md
  - **Commit**: `chore(specs): add YAML frontmatter to ralph-quality-improvements spec files`
  - _Requirements: consistency_

- [ ] 2.8 [FIX] product-manager.md: Align checklist item with FR-A3 spec
  - **Do**: Update the Quality Checklist item in product-manager.md (line 215) to exactly match FR-A3 spec. Change from:
    `- [ ] **If updating existing requirements.md: On Requirements Update steps completed**`
    To:
    `- [ ] If updating existing requirements: On Requirements Update steps completed`
    
    Also update step 5 of the On Requirements Update section to include the HTML comment format:
    ```
    5. Append a one-line changelog at the bottom of requirements.md:
       `<!-- Changed: <brief description> — supersedes User Adjustment #N if applicable -->`
    ```
  - **Files**: `plugins/ralph-specum/agents/product-manager.md`
  - **Done when**: Checklist item matches FR-A3 spec text exactly; step 5 includes HTML comment format
  - **Verify**: `grep "If updating existing requirements:" plugins/ralph-specum/agents/product-manager.md`; `grep -A 1 "Append a one-line changelog" plugins/ralph-specum/agents/product-manager.md | grep "<!-- Changed:"`
  - **Commit**: `fix(product-manager): align checklist item and changelog format with FR-A3 spec`
  - _Requirements: FR-A3_

- [ ] 2.9 [FIX] spec-executor.md: Integrate effectiveIterations as the escalation trigger in Stuck State Protocol
  - **Do**: The Stuck State Protocol currently has `effectiveIterations` as a NOTE after the main ESCALATE block. The hardcoded `reason: stuck-state-unresolved` with `attempts: 5` is the primary trigger. This must be replaced so that effectiveIterations is the actual decision point.
    
    Replace step 6 in the Stuck State Protocol:
    ```
    OLD (step 6):
    6. IF after 2 more attempts (5 total) the test still fails → ESCALATE:
         reason: stuck-state-unresolved
         attempts: 5
    
    NEW (step 6):
    6. Compute effectiveIterations = taskIteration + external_unmarks[taskId]
       IF effectiveIterations >= maxTaskIterations → ESCALATE:
         reason: external-reviewer-repeated-fail
         attempts: <effectiveIterations>
         Note: external_unmarks contributed <N> reviewer cycles
    ```
    
    Remove the separate "### Note: Effective Iterations Formula" block — integrate its content INTO step 6 so the formula IS the trigger, not a post-hoc note.
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: Stuck State Protocol step 6 uses effectiveIterations >= maxTaskIterations as the ESCALATE condition; reason is external-reviewer-repeated-fail; no separate "Note: Effective Iterations Formula" block exists (merged into step 6); hardcoded "attempts: 5" removed
  - **Verify**: `grep -n "stuck-state-unresolved" plugins/ralph-specum/agents/spec-executor.md` returns empty (no occurrences in Stuck State Protocol); `grep -B 3 "effectiveIterations >= maxTaskIterations" plugins/ralph-specum/agents/spec-executor.md` shows it as an IF condition leading to ESCALATE
  - **Commit**: `fix(spec-executor): integrate effectiveIterations as Stuck State Protocol escalation trigger per FR-B3`
  - _Requirements: FR-B3_
