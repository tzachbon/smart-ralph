# Tasks: ralph-quality-improvements

Total tasks: 16 (12 implementation + 4 verification checkpoints)

---

## Phase 1: Make It Work

### Track A — Spec Quality

- [ ] 1.1 [POC] FR-A1: Insert Document Self-Review Checklist in architect-reviewer.md
  - **Do**: Insert the `## Document Self-Review Checklist` section (with 4 steps in `<mandatory>` block) into `plugins/ralph-specum/agents/architect-reviewer.md` AFTER `## Analysis Process` section and BEFORE `## Final Step: Set Awaiting Approval`. Use section names as anchor — ## Quality Checklist appears twice in the file (once inside a code block), so use ## Analysis Process as the unambiguous preceding anchor. Also add checklist item to Quality Checklist as the penúltimo item (before "Set awaitingApproval in state").
  - **Files**: `plugins/ralph-specum/agents/architect-reviewer.md`
  - **Done when**: Section inserted at correct anchor position; Quality Checklist has new item as penúltimo; all 4 step headings present (Type consistency, Duplicate section detection, Ordering and concurrency notes, Internal contradiction scan)
  - **Verify**: `grep -n "Document Self-Review Checklist" plugins/ralph-specum/agents/architect-reviewer.md`; `grep -n "Document Self-Review Checklist passed" plugins/ralph-specum/agents/architect-reviewer.md`
  - **Commit**: `feat(architect-reviewer): add Document Self-Review Checklist for spec quality`
  - _Requirements: FR-A1_

- [ ] 1.2 [POC] FR-A3b: Insert On Design Update section in architect-reviewer.md
  - **Do**: Insert the `## On Design Update` section (with 5-step reconciliation process in `<mandatory>` block) into `plugins/ralph-specum/agents/architect-reviewer.md` AFTER `## Final Step: Set Awaiting Approval` section and BEFORE `## Karpathy Rules`. After task 1.1 inserts ## Document Self-Review Checklist between ## Analysis Process and ## Final Step: Set Awaiting Approval, the correct insertion point for ## On Design Update is after ## Final Step: Set Awaiting Approval. Also add checklist item to Quality Checklist.
  - **Files**: `plugins/ralph-specum/agents/architect-reviewer.md`
  - **Done when**: Section inserted at correct anchor position; Quality Checklist has new item; 5 reconciliation steps present
  - **Verify**: `grep -n "## On Design Update" plugins/ralph-specum/agents/architect-reviewer.md`; `grep -n "If updating existing design.md" plugins/ralph-specum/agents/architect-reviewer.md`
  - **Commit**: `feat(architect-reviewer): add On Design Update reconciliation section`
  - _Requirements: FR-A3b_

- [ ] 1.3 [VERIFY] Track A checkpoint 1 — architect-reviewer.md
  - **Do**: Verify FR-A1 and FR-A3b insertions in architect-reviewer.md are present and correctly positioned.
  - **Verify**: `grep -n "Document Self-Review Checklist" plugins/ralph-specum/agents/architect-reviewer.md`; `grep -n "On Design Update" plugins/ralph-specum/agents/architect-reviewer.md`; both non-empty
  - _Requirements: FR-A1, FR-A3b_

- [ ] 1.4 [POC] FR-A2: Insert Concurrency & Ordering Risks in design.md template
  - **Do**: Insert `## Concurrency & Ordering Risks` section (with table structure: Operation | Required Order | Risk if Inverted) into `plugins/ralph-specum/templates/design.md` AFTER `## Performance Considerations` section and BEFORE `## Test Strategy` section. Include example row as reference pattern.
  - **Files**: `plugins/ralph-specum/templates/design.md`
  - **Done when**: Section inserted between correct anchor sections; table has correct 3-column structure with headers; example row present
  - **Verify**: `grep -n "Concurrency & Ordering Risks" plugins/ralph-specum/templates/design.md`; section between Performance Considerations and Test Strategy
  - **Commit**: `feat(templates): add Concurrency & Ordering Risks section to design.md`
  - _Requirements: FR-A2_

- [ ] 1.5 [VERIFY] Track A checkpoint 2 — design.md template
  - **Do**: Verify FR-A2 insertion in templates/design.md is present and correctly positioned between Performance Considerations and Test Strategy.
  - **Verify**: `grep -n "Concurrency & Ordering Risks" plugins/ralph-specum/templates/design.md`; `grep -n "Performance Considerations" plugins/ralph-specum/templates/design.md`; `grep -n "Test Strategy" plugins/ralph-specum/templates/design.md`; section between the two anchors
  - _Requirements: FR-A2_

- [ ] 1.6 [POC] FR-A3: Insert On Requirements Update section in product-manager.md
  - **Do**: Insert `## On Requirements Update` section (with 5-step reconciliation process in `<mandatory>` block) into `plugins/ralph-specum/agents/product-manager.md` AFTER `## Append Learnings` section (line 55) and BEFORE `## Requirements Structure` (line 75). Add checklist item to Quality Checklist.
  - **Files**: `plugins/ralph-specum/agents/product-manager.md`
  - **Done when**: Section inserted at correct anchor position; Quality Checklist has new item; 5 reconciliation steps present
  - **Verify**: `grep -n "On Requirements Update" plugins/ralph-specum/agents/product-manager.md`; `grep -n "If updating existing requirements" plugins/ralph-specum/agents/product-manager.md`
  - **Commit**: `feat(product-manager): add On Requirements Update reconciliation section`
  - _Requirements: FR-A3_

- [ ] 1.7 [POC] FR-A4: Insert Type Consistency Pre-Check in spec-executor.md
  - **Do**: Insert `### Type Consistency Pre-Check (typed Python or TypeScript tasks)` subsection into `plugins/ralph-specum/agents/spec-executor.md` inside Implementation Tasks section (after line 86 where data-testid block ends), BEFORE Exit Code Gate. NO `<mandatory>` tag. 5-step verification process.
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: Subsection inserted after data-testid block; 5 verification steps present describing Callable/Awaitable type consistency checking
  - **Verify**: `grep -n "Type Consistency Pre-Check" plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `feat(spec-executor): add Type Consistency Pre-Check subsection`
  - _Requirements: FR-A4_

- [ ] 1.8 [VERIFY] Track A checkpoint 3 — product-manager.md + spec-executor.md
  - **Do**: Verify FR-A3 and FR-A4 insertions are present.
  - **Verify**: `grep -n "On Requirements Update" plugins/ralph-specum/agents/product-manager.md`; `grep -n "Type Consistency Pre-Check" plugins/ralph-specum/agents/spec-executor.md`; both non-empty
  - _Requirements: FR-A3, FR-A4_

### Track B — External Reviewer Protocol

- [ ] 1.9 [POC] FR-B1: Create task_review.md template
  - **Do**: Create new file `plugins/ralph-specum/templates/task_review.md` with exact structure: title `# Task Review Log`, workflow comment block describing FAIL/WARNING/PASS/PENDING statuses, `## Reviews` section, and entry template with fields (status, severity, reviewed_at, criterion_failed, evidence, fix_hint, resolved_at).
  - **Files**: `plugins/ralph-specum/templates/task_review.md` (NEW)
  - **Done when**: File exists with correct title, workflow comment block, Reviews section, and complete entry template with all required fields
  - **Verify**: `grep -n "Task Review Log" plugins/ralph-specum/templates/task_review.md`; `grep -n "## Reviews" plugins/ralph-specum/templates/task_review.md`; `grep -n "status" plugins/ralph-specum/templates/task_review.md`; `grep -n "severity" plugins/ralph-specum/templates/task_review.md`; `grep -n "reviewed_at" plugins/ralph-specum/templates/task_review.md`; `grep -n "criterion_failed" plugins/ralph-specum/templates/task_review.md`; `grep -n "evidence" plugins/ralph-specum/templates/task_review.md`; `grep -n "fix_hint" plugins/ralph-specum/templates/task_review.md`; `grep -n "resolved_at" plugins/ralph-specum/templates/task_review.md`
  - **Commit**: `feat(templates): add task_review.md for external reviewer protocol`
  - _Requirements: FR-B1_

- [ ] 1.10 [VERIFY] Track B checkpoint 1 — task_review.md template
  - **Do**: Verify the new task_review.md template exists with all required structure elements.
  - **Verify**: `test -f plugins/ralph-specum/templates/task_review.md && echo "EXISTS"`; all grep commands for required fields return non-empty
  - _Requirements: FR-B1_

- [ ] 1.11 [POC] FR-B2: Insert External Review Protocol in spec-executor.md
  - **Do**: Insert `## External Review Protocol` section (4-step logic in `<mandatory>`) into `plugins/ralph-specum/agents/spec-executor.md` AFTER `## When Invoked` section and BEFORE `## Task Loop` section. Use section names as anchor — file has been modified by prior tasks and line numbers have shifted. FAIL/PENDING/WARNING/PASS handling, appends to .progress.md.
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: Section inserted at correct anchor position; 4-step review reading logic present; FAIL/PENDING/WARNING/PASS status handling documented
  - **Verify**: `grep -n "External Review Protocol" plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `feat(spec-executor): add External Review Protocol section`
  - _Requirements: FR-B2_

- [ ] 1.12 [POC] FR-B3: Update stuck-detection with effectiveIterations formula
  - **Do**: In `plugins/ralph-specum/agents/spec-executor.md`, update two sections:
    1. In `## Stuck State Protocol`: Add NOTE: `effectiveIterations = taskIteration + external_unmarks[taskId]` (taskIteration: current session retries; external_unmarks: reviewer cycles, NEVER reset by spec-executor). Use section names as anchor — file has been modified by prior tasks and line numbers have shifted. Update escalation to use `effectiveIterations >= maxTaskIterations` with reason `external-reviewer-repeated-fail`. Message includes "External reviewer has unmarked this task N times. Human investigation required."
    2. In `## Task Loop`: Add effectiveIterations reference near stuck-detection description.
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: Stuck State Protocol has effectiveIterations formula; escalation reason is `external-reviewer-repeated-fail`; formula appears in both Stuck State Protocol and Task Loop
  - **Verify**: `grep -n "effectiveIterations" plugins/ralph-specum/agents/spec-executor.md`; `grep -n "external-reviewer-repeated-fail" plugins/ralph-specum/agents/spec-executor.md`; `grep -n "External reviewer has unmarked" plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `feat(spec-executor): add external_unmarks to stuck-detection with effectiveIterations`
  - _Requirements: FR-B3_

- [ ] 1.13 [POC] FR-B4: Document external_unmarks field schema in spec-executor.md
  - **Do**: In `plugins/ralph-specum/agents/spec-executor.md`, in the Task Loop section near where `.ralph-state.json` is documented, add `## external_unmarks field` documentation (type object, default {}, written by reviewer only, read by executor for stuck detection, cumulative, NEVER reset by spec-executor). Use section names as anchor — file has been modified by prior tasks and line numbers have shifted. Include JSON example.
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: Field documentation present with type, default, written-by, read-by, lifetime, and example fields
  - **Verify**: `grep -n "external_unmarks" plugins/ralph-specum/agents/spec-executor.md`; field schema documented with all required attributes
  - **Commit**: `docs(spec-executor): document external_unmarks field schema`
  - _Requirements: FR-B4_

- [ ] 1.14 [VERIFY] Track B checkpoint 2 — spec-executor.md external protocol
  - **Do**: Verify FR-B2, FR-B3, FR-B4 insertions in spec-executor.md are present.
  - **Verify**: `grep -n "External Review Protocol" plugins/ralph-specum/agents/spec-executor.md`; `grep -n "effectiveIterations" plugins/ralph-specum/agents/spec-executor.md` (at least 2 occurrences); `grep -n "external-reviewer-repeated-fail" plugins/ralph-specum/agents/spec-executor.md`; `grep -n "external_unmarks" plugins/ralph-specum/agents/spec-executor.md`
  - _Requirements: FR-B2, FR-B3, FR-B4_

- [ ] 1.15 [VERIFY] Regression — surrounding content unchanged
  - **Do**: Verify critical sections in modified files remain intact and unchanged.
  - **Verify**: `grep -n "## Karpathy Rules" plugins/ralph-specum/agents/architect-reviewer.md`; `grep -n "## Final Step: Set Awaiting Approval" plugins/ralph-specum/agents/architect-reviewer.md`; `grep -n "## Test Strategy" plugins/ralph-specum/templates/design.md`; `grep -n "## Requirements Structure" plugins/ralph-specum/agents/product-manager.md`; `grep -n "## Stuck State Protocol" plugins/ralph-specum/agents/spec-executor.md`
  - _Requirements: NFR-1_

- [ ] 1.16 [VERIFY] Final — version bump
  - **Do**: Read current version from `plugins/ralph-specum/.claude-plugin/plugin.json`, increment patch version, write updated version to both `plugins/ralph-specum/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. Both must show the same new version (patch +1 from current).
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  - **Done when**: Both files have identical version string bumped by +1 patch from current value
  - **Verify**: Read both files, compute patch bump from current version, verify both show same new version; `grep "version" plugins/ralph-specum/.claude-plugin/plugin.json` and `grep "version" .claude-plugin/marketplace.json` show identical bumped version
  - **Commit**: `chore(version): bump patch version for quality improvements release`
  - _Requirements: NFR-3_
