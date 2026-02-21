---
generated: auto
---

# Tasks: Fix Implementation Context Bloat

## Overview

Total tasks: 41
POC-first workflow with 4 phases:
1. Phase 1: Make It Work (POC) - Surgical edits to 6 files
2. Phase 2: Refactoring - Orphan cleanup, cross-file consistency
3. Phase 3: Testing - Verification of correctness via grep/awk
4. Phase 4: Quality Gates - Local quality check, PR creation, CI verification

## Completion Criteria (Autonomous Execution Standard)

This spec is not complete until ALL criteria are met:

- Zero Regressions: No behavioral regression in coordinator/executor flow
- Modular & Reusable: Changes follow existing reference file patterns
- All verifications pass: grep-based content checks confirm correct edits
- CI Green: All CI checks passing
- PR Ready: Pull request created and CI verified

> **Quality Checkpoints**: Intermediate quality gate checks inserted every 2-3 tasks. Since this is a markdown/shell-only plugin (no build/lint/typecheck), quality checks use grep-based content verification.

## Phase 1: Make It Work (POC)

Focus: Apply all 6 file changes specified in design.md. Verify each edit via grep.

### verification-layers.md changes

- [x] 1.1 Update opening line and remove Layer 2 from verification-layers.md
  - **Do**:
    1. Change line 5 "Five verification layers" to "Three verification layers"
    2. Remove the entire Layer 2 section (lines 22-35, "## Layer 2: Uncommitted Spec Files Check" through the paragraph ending before Layer 3)
  - **Files**: `plugins/ralph-specum/references/verification-layers.md`
  - **Done when**: Opening line says "Three verification layers"; no "Layer 2: Uncommitted" section exists
  - **Verify**: `grep -c "Three verification layers" plugins/ralph-specum/references/verification-layers.md | grep -q 1 && ! grep -q "Uncommitted Spec Files Check" plugins/ralph-specum/references/verification-layers.md && echo PASS`
  - **Commit**: `refactor(verification): remove redundant Layer 2 (uncommitted files check)`
  - _Requirements: FR-1, AC-1.1_
  - _Design: Detailed Changes 1. verification-layers.md_

- [x] 1.2 Remove Layer 3 (Checkmark Verification) from verification-layers.md
  - **Do**:
    1. Remove the entire Layer 3 section (lines 37-67, "## Layer 3: Checkmark Verification" through the retry line)
  - **Files**: `plugins/ralph-specum/references/verification-layers.md`
  - **Done when**: No "Layer 3: Checkmark Verification" section exists
  - **Verify**: `! grep -q "Checkmark Verification" plugins/ralph-specum/references/verification-layers.md && echo PASS`
  - **Commit**: `refactor(verification): remove redundant Layer 3 (checkmark verification)`
  - _Requirements: FR-2, AC-1.2_
  - _Design: Detailed Changes 1. verification-layers.md_

- [x] 1.3 Renumber Layer 4 to Layer 2 in verification-layers.md
  - **Do**:
    1. Change "## Layer 4: TASK_COMPLETE Signal Verification" to "## Layer 2: TASK_COMPLETE Signal Verification"
  - **Files**: `plugins/ralph-specum/references/verification-layers.md`
  - **Done when**: Section heading says "Layer 2: TASK_COMPLETE Signal Verification"
  - **Verify**: `grep -q "## Layer 2: TASK_COMPLETE Signal Verification" plugins/ralph-specum/references/verification-layers.md && echo PASS`
  - **Commit**: `refactor(verification): renumber TASK_COMPLETE signal to Layer 2`
  - _Requirements: FR-3, AC-1.3_
  - _Design: Detailed Changes 1. verification-layers.md_

- [x] 1.4 [VERIFY] Quality checkpoint: verify verification-layers.md layer removal
  - **Do**: Verify layers 2 and 3 are fully removed, layer 4 renumbered to 2
  - **Verify**: `! grep -q "Uncommitted Spec Files" plugins/ralph-specum/references/verification-layers.md && ! grep -q "Checkmark Verification" plugins/ralph-specum/references/verification-layers.md && grep -q "## Layer 2: TASK_COMPLETE" plugins/ralph-specum/references/verification-layers.md && echo PASS`
  - **Done when**: No traces of old Layer 2/3, Layer 4 is now Layer 2
  - **Commit**: `chore(verification): pass quality checkpoint` (only if fixes needed)

- [x] 1.5 Renumber Layer 5 to Layer 3 and add periodic rules in verification-layers.md
  - **Do**:
    1. Change "## Layer 5: Artifact Review" to "## Layer 3: Artifact Review"
    2. Change "After Layers 1-4 pass" to "After Layers 1-2 pass"
    3. Insert a "### When to Run" subsection immediately after the "## Layer 3: Artifact Review" heading and before "### Review Loop", with these conditions: phase boundary, every 5th task (taskIndex % 5 == 0), final task (taskIndex == totalTasks - 1). When skipped, coordinator appends "Skipping artifact review (next at task N)" to .progress.md
  - **Files**: `plugins/ralph-specum/references/verification-layers.md`
  - **Done when**: Section is "Layer 3: Artifact Review" with "When to Run" subsection containing periodic conditions
  - **Verify**: `grep -q "## Layer 3: Artifact Review" plugins/ralph-specum/references/verification-layers.md && grep -q "### When to Run" plugins/ralph-specum/references/verification-layers.md && grep -q "taskIndex % 5 == 0" plugins/ralph-specum/references/verification-layers.md && echo PASS`
  - **Commit**: `refactor(verification): renumber artifact review to Layer 3, add periodic rules`
  - _Requirements: FR-3, FR-4, AC-1.3, AC-2.1, AC-2.2, AC-2.4_
  - _Design: Detailed Changes 1. verification-layers.md_

- [x] 1.6 Update git diff to --name-only in verification-layers.md review delegation prompt
  - **Do**:
    1. In the Review Delegation Prompt section, change `git diff` to `git diff --name-only HEAD~1` for the Changed files collection line
  - **Files**: `plugins/ralph-specum/references/verification-layers.md`
  - **Done when**: Review delegation prompt uses `git diff --name-only` not bare `git diff`
  - **Verify**: `grep -q "git diff --name-only" plugins/ralph-specum/references/verification-layers.md && echo PASS`
  - **Commit**: `refactor(verification): use git diff --name-only for artifact review`
  - _Requirements: FR-6, AC-4.3_
  - _Design: Detailed Changes 1. verification-layers.md_

- [x] 1.7 Update Verification Summary in verification-layers.md
  - **Do**:
    1. Replace the "## Verification Summary" section (lines 188-197) with the 3-layer version from design.md: All 3 layers must pass (contradiction, TASK_COMPLETE signal, artifact review periodic)
  - **Files**: `plugins/ralph-specum/references/verification-layers.md`
  - **Done when**: Summary lists exactly 3 layers, no references to "spec files committed" or "checkmark count"
  - **Verify**: `grep -q "All 3 layers must pass" plugins/ralph-specum/references/verification-layers.md && ! grep -q "Spec files committed" plugins/ralph-specum/references/verification-layers.md && ! grep -q "Checkmark count" plugins/ralph-specum/references/verification-layers.md && echo PASS`
  - **Commit**: `refactor(verification): update verification summary to 3 layers`
  - _Requirements: FR-3, AC-1.3, AC-1.4_
  - _Design: Detailed Changes 1. verification-layers.md_

- [x] 1.8 Update Spec-Executor Self-Verification section in verification-layers.md
  - **Do**:
    1. Replace lines 199-214 ("## Spec-Executor Self-Verification") with the updated version from design.md that: (a) keeps the 4 self-verification steps, (b) replaces the "stop-hook enforces 4 of the 5" paragraph with "The coordinator trusts spec-executor for commit and checkmark verification. Coordinator layers focus on higher-order checks: contradictions, signal presence, and periodic artifact review." and lists the 3 coordinator layers
  - **Files**: `plugins/ralph-specum/references/verification-layers.md`
  - **Done when**: Self-verification section mentions "3 verification layers" for coordinator, lists contradiction/signal/artifact review
  - **Verify**: `grep -q "coordinator trusts spec-executor" plugins/ralph-specum/references/verification-layers.md && grep -q "3 verification layers" plugins/ralph-specum/references/verification-layers.md && echo PASS`
  - **Commit**: `refactor(verification): update self-verification section for 3-layer model`
  - _Requirements: AC-1.5_
  - _Design: Detailed Changes 1. verification-layers.md_

- [x] 1.9 [VERIFY] Quality checkpoint: full verification-layers.md validation
  - **Do**: Verify all changes to verification-layers.md are correct and consistent
  - **Verify**: `grep -c "Layer" plugins/ralph-specum/references/verification-layers.md | head -1 && grep -q "Three verification layers" plugins/ralph-specum/references/verification-layers.md && grep -q "## Layer 1: Contradiction" plugins/ralph-specum/references/verification-layers.md && grep -q "## Layer 2: TASK_COMPLETE" plugins/ralph-specum/references/verification-layers.md && grep -q "## Layer 3: Artifact Review" plugins/ralph-specum/references/verification-layers.md && ! grep -q "## Layer 4" plugins/ralph-specum/references/verification-layers.md && ! grep -q "## Layer 5" plugins/ralph-specum/references/verification-layers.md && grep -q "When to Run" plugins/ralph-specum/references/verification-layers.md && grep -q "All 3 layers" plugins/ralph-specum/references/verification-layers.md && echo PASS`
  - **Done when**: Exactly 3 layers (1, 2, 3), no Layer 4/5, periodic rules present, summary says 3
  - **Commit**: `chore(verification): pass quality checkpoint` (only if fixes needed)

### coordinator-pattern.md changes

- [x] 1.10 Update Integrity Rules layer count in coordinator-pattern.md
  - **Do**:
    1. Change line 19 "all 5 in the Verification section" to "all 3 in the Verification section"
  - **Files**: `plugins/ralph-specum/references/coordinator-pattern.md`
  - **Done when**: Integrity rules reference "all 3" not "all 5"
  - **Verify**: `grep -q "all 3 in the Verification section" plugins/ralph-specum/references/coordinator-pattern.md && echo PASS`
  - **Commit**: `refactor(coordinator): update integrity rules to 3 verification layers`
  - _Requirements: FR-3, AC-1.4_
  - _Design: Detailed Changes 2. coordinator-pattern.md_

- [x] 1.11 Replace Verification Layers section in coordinator-pattern.md -- remove layers 2+3
  - **Do**:
    1. Change line 240 "these 5 verifications" to "these 3 verifications"
    2. Remove Layer 2 (Uncommitted Spec Files Check) section (lines 256-271)
    3. Remove Layer 3 (Checkmark Verification) section (lines 273-287)
  - **Files**: `plugins/ralph-specum/references/coordinator-pattern.md`
  - **Done when**: Verification section has no Layer 2 (uncommitted) or Layer 3 (checkmark) subsections
  - **Verify**: `grep -q "these 3 verifications" plugins/ralph-specum/references/coordinator-pattern.md && ! grep -q "Uncommitted Spec Files Check" plugins/ralph-specum/references/coordinator-pattern.md && ! grep -q "Checkmark Verification" plugins/ralph-specum/references/coordinator-pattern.md && echo PASS`
  - **Commit**: `refactor(coordinator): remove redundant verification layers 2 and 3`
  - _Requirements: FR-1, FR-2, AC-1.1, AC-1.2_
  - _Design: Detailed Changes 2. coordinator-pattern.md_

- [x] 1.12 Renumber remaining layers in coordinator-pattern.md Verification section
  - **Do**:
    1. Change "**Layer 4: TASK_COMPLETE Signal Verification**" to "**Layer 2: TASK_COMPLETE Signal Verification**"
    2. Change "**Layer 5: Artifact Review**" to "**Layer 3: Artifact Review (Periodic)**"
    3. Add periodic conditions to Layer 3: runs only at phase boundary, every 5th task, or final task. When skipped: append skip message to .progress.md and proceed to State Update
  - **Files**: `plugins/ralph-specum/references/coordinator-pattern.md`
  - **Done when**: Layers are numbered 1-3, Layer 3 has periodic conditions
  - **Verify**: `grep -q "Layer 2: TASK_COMPLETE Signal Verification" plugins/ralph-specum/references/coordinator-pattern.md && grep -q "Layer 3: Artifact Review (Periodic)" plugins/ralph-specum/references/coordinator-pattern.md && ! grep -q "Layer 4:" plugins/ralph-specum/references/coordinator-pattern.md && ! grep -q "Layer 5:" plugins/ralph-specum/references/coordinator-pattern.md && echo PASS`
  - **Commit**: `refactor(coordinator): renumber verification layers to 1-3 with periodic artifact review`
  - _Requirements: FR-3, FR-4, AC-1.3, AC-2.5_
  - _Design: Detailed Changes 2. coordinator-pattern.md_

- [x] 1.13 Update Verification Summary in coordinator-pattern.md
  - **Do**:
    1. Replace the "**Verification Summary**" block (lines 304-313) with the 3-layer version: contradiction, TASK_COMPLETE signal, artifact review (periodic auto-pass when skipped)
  - **Files**: `plugins/ralph-specum/references/coordinator-pattern.md`
  - **Done when**: Summary lists exactly 3 items, mentions "auto-pass when skipped per periodic rules"
  - **Verify**: `grep -q "All 3 layers must pass" plugins/ralph-specum/references/coordinator-pattern.md && grep -q "auto-pass when skipped" plugins/ralph-specum/references/coordinator-pattern.md && echo PASS`
  - **Commit**: `refactor(coordinator): update verification summary to 3 layers`
  - _Requirements: FR-3, AC-1.4_
  - _Design: Detailed Changes 2. coordinator-pattern.md_

- [x] 1.14 [VERIFY] Quality checkpoint: coordinator-pattern.md verification section
  - **Do**: Verify coordinator verification layers are correctly restructured
  - **Verify**: `grep -c "Layer" plugins/ralph-specum/references/coordinator-pattern.md | head -1 && grep -q "all 3 in the Verification" plugins/ralph-specum/references/coordinator-pattern.md && grep -q "these 3 verifications" plugins/ralph-specum/references/coordinator-pattern.md && grep -q "All 3 layers" plugins/ralph-specum/references/coordinator-pattern.md && echo PASS`
  - **Done when**: All "3" references consistent, no "4" or "5" layer references remain in verification context
  - **Commit**: `chore(coordinator): pass quality checkpoint` (only if fixes needed)

- [x] 1.15 Add patient waiting directive to coordinator-pattern.md parallel Step 5
  - **Do**:
    1. Replace Step 5 content (line 207) "Monitor via TaskList. Wait for all teammates to report done. On timeout, proceed with completed tasks and handle failures via Progress Merge." with: "Wait for automatic teammate idle notifications. Use TaskList ONCE to verify all tasks complete. Do NOT poll TaskList in a loop. After spawning teammates, wait for their messages -- they will notify you when done."
  - **Files**: `plugins/ralph-specum/references/coordinator-pattern.md`
  - **Done when**: Step 5 contains "Do NOT poll TaskList in a loop"
  - **Verify**: `grep -q "Do NOT poll TaskList in a loop" plugins/ralph-specum/references/coordinator-pattern.md && grep -q "TaskList ONCE" plugins/ralph-specum/references/coordinator-pattern.md && echo PASS`
  - **Commit**: `refactor(coordinator): add patient waiting directive for parallel execution`
  - _Requirements: FR-7, AC-5.1, AC-5.2_
  - _Design: Detailed Changes 2. coordinator-pattern.md_

### commit-discipline.md changes

- [x] 1.16 Update Layer reference in commit-discipline.md State File Protection
  - **Do**:
    1. Change line 110 "Shortcuts are detected via checkmark mismatch (Layer 3 of verification)." to "State file is verified via contradiction detection and signal verification (Layers 1-2 of verification)."
  - **Files**: `plugins/ralph-specum/references/commit-discipline.md`
  - **Done when**: Line references "Layers 1-2" not "Layer 3"
  - **Verify**: `grep -q "Layers 1-2 of verification" plugins/ralph-specum/references/commit-discipline.md && ! grep -q "Layer 3 of verification" plugins/ralph-specum/references/commit-discipline.md && echo PASS`
  - **Commit**: `refactor(commit-discipline): update layer reference to match 3-layer model`
  - _Requirements: FR-3, AC-1.3_
  - _Design: Detailed Changes 3. commit-discipline.md_

### stop-watcher.sh changes

- [x] 1.17 Add task block extraction function to stop-watcher.sh
  - **Do**:
    1. Before the continuation prompt (before line 214), add the task block extraction code from design.md: define TASKS_FILE, TASK_BLOCK variables, use awk to extract the task at TASK_INDEX by counting task lines matching `- [[ x]]`
    2. Place this after the STOP_HOOK_ACTIVE check (after line 204) and before the REASON heredoc (line 214)
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: TASK_BLOCK variable is set from awk extraction of current task
  - **Verify**: `grep -q "TASK_BLOCK" plugins/ralph-specum/hooks/scripts/stop-watcher.sh && grep -q 'awk.*idx.*TASK_INDEX' plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo PASS`
  - **Commit**: `feat(stop-watcher): add task block extraction for inline continuation`
  - _Requirements: FR-5, AC-3.1, AC-3.4_
  - _Design: Detailed Changes 4. stop-watcher.sh_

- [x] 1.18 Update continuation prompt in stop-watcher.sh to inline task block
  - **Do**:
    1. Replace the REASON heredoc (lines 214-231) with the new version from design.md that: (a) includes `## Current Task` section with `$TASK_BLOCK`, (b) Step 1 reads only .ralph-state.json (not tasks.md), (c) Step 4 reads tasks.md only at completion, (d) references "3 layers" not "4 layers"
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: Continuation prompt includes "## Current Task" with TASK_BLOCK, references "3 layers", Step 1 does not mention tasks.md
  - **Verify**: `grep -q "Current Task" plugins/ralph-specum/hooks/scripts/stop-watcher.sh && grep -q "TASK_BLOCK" plugins/ralph-specum/hooks/scripts/stop-watcher.sh && grep -q "3 layers" plugins/ralph-specum/hooks/scripts/stop-watcher.sh && ! grep "Resume" plugins/ralph-specum/hooks/scripts/stop-watcher.sh | grep -q "tasks.md" && echo PASS`
  - **Commit**: `feat(stop-watcher): inline task block in continuation prompt, reduce re-reads`
  - _Requirements: FR-5, FR-8, AC-3.1, AC-3.2, AC-3.3_
  - _Design: Detailed Changes 4. stop-watcher.sh_

- [x] 1.19 [VERIFY] Quality checkpoint: stop-watcher.sh changes
  - **Do**: Verify stop-watcher.sh is syntactically valid and contains expected changes
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh && grep -q "TASK_BLOCK" plugins/ralph-specum/hooks/scripts/stop-watcher.sh && grep -q "Current Task" plugins/ralph-specum/hooks/scripts/stop-watcher.sh && grep -q "3 layers" plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo PASS`
  - **Done when**: Shell script has no syntax errors, all expected patterns present
  - **Commit**: `chore(stop-watcher): pass quality checkpoint` (only if fixes needed)

### implement.md changes

- [x] 1.20 Update "5 layers" to "3 layers" in implement.md Step 4 reference
  - **Do**:
    1. Change line 137 "5 layers (contradiction detection, uncommitted spec files, checkmark verification, TASK_COMPLETE signal, artifact review via spec-reviewer)" to "3 layers (contradiction detection, TASK_COMPLETE signal, periodic artifact review via spec-reviewer)"
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: Line 137 says "3 layers" with correct list
  - **Verify**: `grep -q "3 layers (contradiction detection, TASK_COMPLETE signal, periodic artifact review" plugins/ralph-specum/commands/implement.md && echo PASS`
  - **Commit**: `refactor(implement): update verification layer count to 3`
  - _Requirements: FR-3, AC-1.4_
  - _Design: Detailed Changes 5. implement.md_

- [x] 1.21 Update "all 5 verification layers" to "all 3" in implement.md Key Coordinator Behaviors
  - **Do**:
    1. Change line 152 "Run all 5 verification layers" to "Run all 3 verification layers"
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: Key behaviors section says "all 3 verification layers"
  - **Verify**: `grep -q "all 3 verification layers" plugins/ralph-specum/commands/implement.md && ! grep -q "all 5 verification layers" plugins/ralph-specum/commands/implement.md && echo PASS`
  - **Commit**: `refactor(implement): update key behaviors layer count`
  - _Requirements: FR-3, AC-1.4_
  - _Design: Detailed Changes 5. implement.md_

### spec-executor.md changes

- [ ] 1.22 Update Completion Integrity section in spec-executor.md
  - **Do**:
    1. Replace lines 511-517 (the "stop-hook enforces 4 verification layers" block) with the 3-layer version from design.md: "The coordinator enforces 3 verification layers: 1. Contradiction detection, 2. Signal verification, 3. Periodic artifact review"
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: Completion Integrity lists 3 coordinator layers, no mention of "uncommitted files check" or "checkmark verification"
  - **Verify**: `grep -q "3 verification layers" plugins/ralph-specum/agents/spec-executor.md && grep -q "Periodic artifact review" plugins/ralph-specum/agents/spec-executor.md && ! grep -q "Uncommitted files check" plugins/ralph-specum/agents/spec-executor.md && ! grep -q "Checkmark verification" plugins/ralph-specum/agents/spec-executor.md && echo PASS`
  - **Commit**: `refactor(spec-executor): update coordinator layer references to 3`
  - _Requirements: AC-1.4_
  - _Design: Detailed Changes 6. spec-executor.md_

- [ ] 1.23 [VERIFY] Quality checkpoint: all 6 files layer count consistency
  - **Do**: Verify no file references "5 layers", "4 layers", "Layer 4:", or "Layer 5:" in verification context
  - **Verify**: `! grep -l "all 5 verification\|all 4 verification\|5 verification layers\|4 verification layers" plugins/ralph-specum/references/verification-layers.md plugins/ralph-specum/references/coordinator-pattern.md plugins/ralph-specum/references/commit-discipline.md plugins/ralph-specum/hooks/scripts/stop-watcher.sh plugins/ralph-specum/commands/implement.md plugins/ralph-specum/agents/spec-executor.md 2>/dev/null && echo PASS`
  - **Done when**: Zero matches for old layer counts across all 6 files
  - **Commit**: `chore(spec): pass quality checkpoint` (only if fixes needed)

- [ ] 1.24 POC Checkpoint
  - **Do**: Verify all 6 files are correctly modified end-to-end:
    1. verification-layers.md: 3 layers, periodic rules, --name-only, updated summary and self-verification
    2. coordinator-pattern.md: 3 layers, periodic artifact review, patient waiting
    3. commit-discipline.md: Layers 1-2 reference
    4. stop-watcher.sh: task block extraction, inline continuation, 3 layers, valid shell syntax
    5. implement.md: 3 layers references
    6. spec-executor.md: 3 coordinator layers
  - **Done when**: All grep checks pass, shell syntax valid, no stale layer references
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh && grep -q "Three verification layers" plugins/ralph-specum/references/verification-layers.md && grep -q "all 3 in the Verification" plugins/ralph-specum/references/coordinator-pattern.md && grep -q "Layers 1-2" plugins/ralph-specum/references/commit-discipline.md && grep -q "Current Task" plugins/ralph-specum/hooks/scripts/stop-watcher.sh && grep -q "3 layers" plugins/ralph-specum/commands/implement.md && grep -q "3 verification layers" plugins/ralph-specum/agents/spec-executor.md && echo "POC PASS"`
  - **Commit**: `feat(context-bloat): complete POC - all 6 files updated`

## Phase 2: Refactoring

Focus: Ensure edits are clean, no orphaned references, consistent wording.

- [ ] 2.1 Audit verification-layers.md for orphaned "Layer 4" or "Layer 5" references in prose
  - **Do**:
    1. Search verification-layers.md for any remaining references to "Layer 4", "Layer 5", "Layers 1-4", "Layers 2-3" or "5 layers" in non-heading text
    2. Fix any found references to use correct new numbering
  - **Files**: `plugins/ralph-specum/references/verification-layers.md`
  - **Done when**: No orphaned old-numbering references in prose text
  - **Verify**: `! grep -iE "Layer [45]|Layers 1-4|5 layers" plugins/ralph-specum/references/verification-layers.md && echo PASS`
  - **Commit**: `refactor(verification): fix orphaned layer references`
  - _Requirements: AC-1.3_

- [ ] 2.2 Audit coordinator-pattern.md for orphaned layer references in non-verification sections
  - **Do**:
    1. Search coordinator-pattern.md for any "Layer 2" references meaning "uncommitted" or "Layer 3" meaning "checkmark" (old numbering) outside the verification section
    2. Check "After Delegation" section (line 220) and other sections for stale references
    3. Fix any found
  - **Files**: `plugins/ralph-specum/references/coordinator-pattern.md`
  - **Done when**: No stale layer references in any section
  - **Verify**: `! grep -E "5 verifications|5 layers|Layer 4:|Layer 5:" plugins/ralph-specum/references/coordinator-pattern.md && echo PASS`
  - **Commit**: `refactor(coordinator): fix orphaned layer references`
  - _Requirements: AC-1.4_

- [ ] 2.3 [VERIFY] Quality checkpoint: cross-file consistency audit
  - **Do**: Run comprehensive check across all 6 files for any remaining old-model references
  - **Verify**: `for f in plugins/ralph-specum/references/verification-layers.md plugins/ralph-specum/references/coordinator-pattern.md plugins/ralph-specum/references/commit-discipline.md plugins/ralph-specum/hooks/scripts/stop-watcher.sh plugins/ralph-specum/commands/implement.md plugins/ralph-specum/agents/spec-executor.md; do if grep -qE "5 verification|4 verification|Layer 4:|Layer 5:|5 layers|4 layers|uncommitted spec files check|checkmark mismatch \(Layer 3" "$f" 2>/dev/null; then echo "STALE: $f"; exit 1; fi; done && echo PASS`
  - **Done when**: Zero stale references across all files
  - **Commit**: `chore(spec): pass cross-file consistency checkpoint` (only if fixes needed)

- [ ] 2.4 Ensure stop-watcher.sh DESIGN NOTE comment is accurate
  - **Do**:
    1. Update the DESIGN NOTE comment (lines 206-212) if it references outdated layer count or behavior
    2. Verify the comment accurately describes the abbreviated vs full specification relationship
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: DESIGN NOTE comment is accurate for the new continuation prompt format
  - **Verify**: `grep -A5 "DESIGN NOTE" plugins/ralph-specum/hooks/scripts/stop-watcher.sh | grep -q "abbreviated" && echo PASS`
  - **Commit**: `refactor(stop-watcher): update design note comment`

- [ ] 2.5 Verify spec-executor.md State File Protection section is consistent
  - **Do**:
    1. Check lines 492-497 in spec-executor.md for "checkmark count mismatch" reference -- this should be updated since coordinator no longer does checkmark verification
    2. Update to reference the new verification model (contradiction detection + signal verification)
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: State File Protection no longer references checkmark count mismatch as detection method
  - **Verify**: `! grep -q "checkmark count mismatch" plugins/ralph-specum/agents/spec-executor.md && echo PASS`
  - **Commit**: `refactor(spec-executor): update state file protection to match 3-layer model`
  - _Requirements: AC-1.4_

- [ ] 2.6 [VERIFY] Quality checkpoint: post-refactoring validation
  - **Do**: Full validation of all changes post-refactoring
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh && ! grep -rlE "5 verification|4 verification|Layer 4:|Layer 5:|checkmark mismatch \(Layer" plugins/ralph-specum/references/ plugins/ralph-specum/hooks/scripts/stop-watcher.sh plugins/ralph-specum/commands/implement.md plugins/ralph-specum/agents/spec-executor.md 2>/dev/null && echo PASS`
  - **Done when**: Shell valid, zero stale references across all modified files
  - **Commit**: `chore(spec): pass post-refactoring quality checkpoint` (only if fixes needed)

## Phase 3: Testing

Focus: Verify behavioral correctness through content-based tests.

- [ ] 3.1 Verify verification-layers.md has exactly 3 layer headings
  - **Do**:
    1. Count "## Layer" headings in verification-layers.md
    2. Verify they are exactly: Layer 1 (Contradiction), Layer 2 (TASK_COMPLETE), Layer 3 (Artifact Review)
  - **Files**: `plugins/ralph-specum/references/verification-layers.md`
  - **Done when**: Exactly 3 "## Layer" headings in correct order
  - **Verify**: `test "$(grep -c '^## Layer' plugins/ralph-specum/references/verification-layers.md)" -eq 3 && grep -m1 '^## Layer' plugins/ralph-specum/references/verification-layers.md | grep -q "Layer 1" && echo PASS`
  - **Commit**: None (read-only verification)

- [ ] 3.2 Verify periodic review conditions are complete in verification-layers.md
  - **Do**:
    1. Check that the "When to Run" section contains all 3 conditions: phase boundary, every 5th task, final task
    2. Verify skip message format is documented
  - **Files**: `plugins/ralph-specum/references/verification-layers.md`
  - **Done when**: All 3 periodic conditions present, skip message documented
  - **Verify**: `grep -q "Phase boundary" plugins/ralph-specum/references/verification-layers.md && grep -q "Every 5th task" plugins/ralph-specum/references/verification-layers.md && grep -q "Final task" plugins/ralph-specum/references/verification-layers.md && grep -q "Skipping artifact review" plugins/ralph-specum/references/verification-layers.md && echo PASS`
  - **Commit**: None (read-only verification)

- [ ] 3.3 Verify coordinator-pattern.md Verification Summary matches verification-layers.md
  - **Do**:
    1. Compare the 3-item summary lists in both files
    2. Verify they describe the same 3 layers
  - **Files**: `plugins/ralph-specum/references/coordinator-pattern.md`, `plugins/ralph-specum/references/verification-layers.md`
  - **Done when**: Both summaries list the same 3 layers
  - **Verify**: `grep -A4 "All 3 layers" plugins/ralph-specum/references/verification-layers.md | grep -q "contradiction" && grep -A4 "All 3 layers" plugins/ralph-specum/references/coordinator-pattern.md | grep -q "contradiction" && grep -A4 "All 3 layers" plugins/ralph-specum/references/verification-layers.md | grep -q "TASK_COMPLETE" && grep -A4 "All 3 layers" plugins/ralph-specum/references/coordinator-pattern.md | grep -q "TASK_COMPLETE" && echo PASS`
  - **Commit**: None (read-only verification)

- [ ] 3.4 [VERIFY] Quality checkpoint: test phase validation
  - **Do**: Run all verification commands from tests 3.1-3.3
  - **Verify**: `test "$(grep -c '^## Layer' plugins/ralph-specum/references/verification-layers.md)" -eq 3 && grep -q "Phase boundary" plugins/ralph-specum/references/verification-layers.md && grep -q "All 3 layers" plugins/ralph-specum/references/coordinator-pattern.md && echo PASS`
  - **Done when**: All structural tests pass
  - **Commit**: `chore(spec): pass test phase quality checkpoint` (only if fixes needed)

- [ ] 3.5 Verify stop-watcher.sh task extraction awk handles task format
  - **Do**:
    1. Verify the awk script in stop-watcher.sh correctly matches `- [ ]` and `- [x]` patterns
    2. Verify it handles multi-line task blocks (indented continuation lines)
    3. Run a dry syntax check
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: Awk pattern matches both checked and unchecked tasks, handles indented lines
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh && grep -q '\- \[[ x]\]' plugins/ralph-specum/hooks/scripts/stop-watcher.sh && grep -q 'found.*\/\^  \/' plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo PASS`
  - **Commit**: None (read-only verification)

- [ ] 3.6 Verify stop-watcher.sh continuation prompt structure
  - **Do**:
    1. Verify continuation prompt has: State section, Current Task section, Resume section, Critical section
    2. Verify Resume step 1 references only .ralph-state.json (not tasks.md)
    3. Verify Resume step 4 references tasks.md for completion check only
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: Prompt structure matches design spec
  - **Verify**: `grep -q "## State" plugins/ralph-specum/hooks/scripts/stop-watcher.sh && grep -q "## Current Task" plugins/ralph-specum/hooks/scripts/stop-watcher.sh && grep -q "## Resume" plugins/ralph-specum/hooks/scripts/stop-watcher.sh && grep -q "## Critical" plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo PASS`
  - **Commit**: None (read-only verification)

- [ ] 3.7 Verify patient waiting directive matches parallel-research.md pattern
  - **Do**:
    1. Confirm coordinator-pattern.md Step 5 has "Do NOT poll TaskList in a loop"
    2. Confirm it says "wait for their messages"
  - **Files**: `plugins/ralph-specum/references/coordinator-pattern.md`
  - **Done when**: Patient waiting directive present with anti-polling language
  - **Verify**: `grep -q "Do NOT poll TaskList" plugins/ralph-specum/references/coordinator-pattern.md && grep -q "wait for their messages" plugins/ralph-specum/references/coordinator-pattern.md && echo PASS`
  - **Commit**: None (read-only verification)

- [ ] 3.8 Verify implement.md has no "5" layer references remaining
  - **Do**:
    1. Check implement.md for any remaining "5 layers", "5 verification", "all 5" references
  - **Files**: `plugins/ralph-specum/commands/implement.md`
  - **Done when**: Zero "5 layer" references in implement.md
  - **Verify**: `! grep -qE "5 layers|5 verification|all 5 verification" plugins/ralph-specum/commands/implement.md && echo PASS`
  - **Commit**: None (read-only verification)

- [ ] 3.9 [VERIFY] Quality checkpoint: full behavioral test suite
  - **Do**: Run all verification commands from Phase 3 as a single comprehensive check
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh && test "$(grep -c '^## Layer' plugins/ralph-specum/references/verification-layers.md)" -eq 3 && grep -q "Do NOT poll TaskList" plugins/ralph-specum/references/coordinator-pattern.md && ! grep -qE "5 layers|5 verification|all 5|all 4 verification|4 layers" plugins/ralph-specum/commands/implement.md plugins/ralph-specum/references/coordinator-pattern.md plugins/ralph-specum/references/verification-layers.md plugins/ralph-specum/agents/spec-executor.md 2>/dev/null && echo "ALL TESTS PASS"`
  - **Done when**: Complete behavioral test suite passes
  - **Commit**: `chore(spec): pass full behavioral test checkpoint` (only if fixes needed)

## Phase 4: Quality Gates

> **IMPORTANT**: NEVER push directly to the default branch (main/master). Branch management is handled at startup via `/ralph-specum:start`. You should already be on a feature branch by this phase.

- [ ] 4.1 Local quality check
  - **Do**: Run comprehensive quality checks locally. Since this is a markdown/shell plugin with no build system, verify:
    1. Shell syntax valid: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    2. No stale layer references across all 6 files
    3. All AC criteria met (spot check each AC-*)
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh && ! grep -rlE "5 verification|4 verification|Layer [45]:" plugins/ralph-specum/references/ plugins/ralph-specum/hooks/scripts/ plugins/ralph-specum/commands/implement.md plugins/ralph-specum/agents/spec-executor.md 2>/dev/null && echo "LOCAL QUALITY PASS"`
  - **Done when**: All local quality checks pass
  - **Commit**: `fix(context-bloat): address quality issues` (if fixes needed)

- [ ] 4.2 Create PR and verify CI
  - **Do**:
    1. Verify current branch is a feature branch: `git branch --show-current`
    2. If on default branch, STOP and alert user (branch should be set at startup)
    3. Push branch: `git push -u origin $(git branch --show-current)`
    4. Create PR using gh CLI:
       ```bash
       gh pr create --title "refactor: reduce coordinator context bloat by removing redundant verification layers" --body "$(cat <<'EOF'
       ## Summary
       - Remove 2 redundant verification layers (uncommitted files check, checkmark verification) already handled by spec-executor self-verification
       - Make artifact review periodic (phase boundaries + every 5th task + final task) instead of per-task
       - Inline current task block in stop-watcher continuation prompt to avoid re-reading tasks.md every iteration
       - Add patient waiting directive for parallel execution
       - Replace verbose git diff with --name-only in artifact review

       ## Test Plan
       - [x] Shell syntax validation (`bash -n stop-watcher.sh`)
       - [x] No stale layer references across all 6 modified files
       - [x] Exactly 3 verification layer headings in verification-layers.md
       - [x] Periodic review conditions (phase boundary, every 5th, final) documented
       - [x] Patient waiting directive present in coordinator-pattern.md
       - [ ] CI checks pass
       EOF
       )"
       ```
  - **Verify**: `gh pr checks` shows all green (or `gh pr checks --watch`)
  - **Done when**: All CI checks passing, PR ready for review
  - **If CI fails**:
    1. View failures: `gh pr checks`
    2. Get detailed logs: `gh run view --log-failed`
    3. Fix issues locally
    4. Commit and push fixes
    5. Re-verify: `gh pr checks --watch`

## Notes

- **POC shortcuts taken**: None -- all changes are surgical edits to existing markdown/shell files, no shortcuts needed
- **Production TODOs**: None -- changes are production-ready as specified
- **No build/lint/typecheck**: This is a Claude Code plugin (markdown + shell). Quality verification uses grep/awk content checks and `bash -n` syntax validation
- **6 files modified**: verification-layers.md, coordinator-pattern.md, commit-discipline.md, stop-watcher.sh, implement.md, spec-executor.md
- **Key risk**: awk task extraction in stop-watcher.sh -- empty TASK_BLOCK is handled gracefully (coordinator falls back to reading tasks.md)

## Dependencies

```
Phase 1 (POC: all 6 file edits) → Phase 2 (Refactor: orphan cleanup) → Phase 3 (Testing: content verification) → Phase 4 (Quality Gates + PR)
```
