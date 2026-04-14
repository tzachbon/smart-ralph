# Tasks: Engine State Hardening

## Overview

Total tasks: 52

**POC-first workflow** (REFACTOR intent, but no test runner -- grep/jq verification only):
1. Phase 1: Make It Work -- surgical edits to 4 files
2. Phase 2: Refactoring -- cross-reference consistency cleanup
3. Phase 3: Testing -- AC verification via grep/jq commands
4. Phase 4: Quality Gates -- version bump, final validation
5. Phase 5: PR Lifecycle -- CI, review, completion

## Completion Criteria (Autonomous Execution Standard)

All AC grep/jq commands from requirements.md Success Criteria must pass:
- `grep -c "all 3" verification-layers.md` returns 0
- `grep -c "Layer [0-4]" verification-layers.md` returns >= 5
- `grep -c "\[HOLD\]" implement.md` returns >= 1
- `grep -c "STATE DRIFT" implement.md` returns >= 1
- `jq '.definitions.state.properties | has("nativeTaskMap")' spec.schema.json` returns true
- `jq '.definitions.state.properties | has("nativeSyncEnabled")' spec.schema.json` returns true
- `jq '.definitions.state.properties | has("nativeSyncFailureCount")' spec.schema.json` returns true
- `jq '.definitions.state.properties.chat.properties.executor.properties | has("lastReadLine")' spec.schema.json` returns true
- `grep -c "GLOBAL CI" implement.md` returns >= 1

> **Quality Checkpoints**: [VERIFY] tasks inserted every 2-3 tasks. All verification is grep/jq (no test runner).

## Phase 1: Make It Work (POC)

Surgical edits to 4 files. Each task = one atomic change.

### Schema Changes (spec.schema.json)

- [x] 1.1 Add nativeTaskMap property to schema
  - **Do**: Add `"nativeTaskMap"` object property to `definitions.state.properties` after `granularity` at line 193. Property: type object, description "Maps taskIndex to native task IDs for external sync", default {}, additionalProperties type string.
  - **Files**: plugins/ralph-specum/schemas/spec.schema.json
  - **Done when**: `jq '.definitions.state.properties | has("nativeTaskMap")' plugins/ralph-specum/schemas/spec.schema.json` returns `true`
  - **Verify**: `jq '.definitions.state.properties | has("nativeTaskMap")' plugins/ralph-specum/schemas/spec.schema.json`
  - **Commit**: `feat(schema): add nativeTaskMap property to state definition`
  - _Requirements: FR-10, AC-4.1_

- [x] 1.2 Add nativeSyncEnabled property to schema
  - **Do**: Add `"nativeSyncEnabled"` boolean property after `nativeTaskMap`. Property: type boolean, default true, description "Whether native task sync is active".
  - **Files**: plugins/ralph-specum/schemas/spec.schema.json
  - **Done when**: `jq '.definitions.state.properties | has("nativeSyncEnabled")' plugins/ralph-specum/schemas/spec.schema.json` returns `true`
  - **Verify**: `jq '.definitions.state.properties | has("nativeSyncEnabled")' plugins/ralph-specum/schemas/spec.schema.json`
  - **Commit**: `feat(schema): add nativeSyncEnabled property to state definition`
  - _Requirements: FR-10, AC-4.2_

- [x] 1.3 Add nativeSyncFailureCount property to schema
- [x] 1.4 Add chat.executor.lastReadLine nested property to schema
- [x] 1.6 Update intro line 5: "Three" to "Five"
- [x] 1.7 Add Layer 0 (EXECUTOR_START) section after intro
- [x] 1.8 Add Layer 3 (Anti-fabrication) section before current Layer 3
- [x] 1.9 Rename Layer 3 to Layer 4 (Artifact Review)
- [x] 1.10 Update "All 3 layers" to "All 5 layers" in Verification Summary
- [x] 1.11 Update "3 verification layers" to "5 verification layers" at bottom
- [x] 1.17 Update "3 layers" to "5 layers" at line 211
- [x] 1.18 Update "all 3 verification layers" to "all 5 verification layers" at line 239
- [x] 1.19 Add mechanical HOLD grep check before line 225
- [x] 1.20 Add state integrity check before coordinator prompt output
- [x] 1.21 Add CI snapshot separation rule after anti-fabrication bullet
  - **Do**: Add `"nativeSyncFailureCount"` integer property after `nativeSyncEnabled`. Property: type integer, minimum 0, default 0, description "Consecutive native sync failures (disables at 3)".
  - **Files**: plugins/ralph-specum/schemas/spec.schema.json
  - **Done when**: `jq '.definitions.state.properties | has("nativeSyncFailureCount")' plugins/ralph-specum/schemas/spec.schema.json` returns `true`
  - **Verify**: `jq '.definitions.state.properties | has("nativeSyncFailureCount")' plugins/ralph-specum/schemas/spec.schema.json`
  - **Commit**: `feat(schema): add nativeSyncFailureCount property to state definition`
  - _Requirements: FR-10, AC-4.3_

- [ ] 1.4 Add chat.executor.lastReadLine nested property to schema
  - **Do**: Add `"chat"` object property after `nativeSyncFailureCount`. Structure: chat (object, description "Chat protocol state") -> executor (object) -> lastReadLine (integer, minimum 0, default 0, description "Last line read in chat.md by executor").
  - **Files**: plugins/ralph-specum/schemas/spec.schema.json
  - **Done when**: `jq '.definitions.state.properties.chat.properties.executor.properties | has("lastReadLine")' plugins/ralph-specum/schemas/spec.schema.json` returns `true`
  - **Verify**: `jq '.definitions.state.properties.chat.properties.executor.properties | has("lastReadLine")' plugins/ralph-specum/schemas/spec.schema.json`
  - **Commit**: `feat(schema): add chat.executor.lastReadLine to state definition`
  - _Requirements: FR-11, AC-4.4_

- [ ] 1.5 [VERIFY] Quality checkpoint: validate schema JSON syntax
  - **Do**: Verify spec.schema.json is valid JSON and all 4 new fields exist
  - **Verify**: `jq empty plugins/ralph-specum/schemas/spec.schema.json && jq '.definitions.state.properties | has("nativeTaskMap") and has("nativeSyncEnabled") and has("nativeSyncFailureCount") and has("chat")' plugins/ralph-specum/schemas/spec.schema.json | grep -q true && echo PASS`
  - **Done when**: JSON valid, all 4 new fields present
  - **Commit**: `chore(schema): pass quality checkpoint` (only if fixes needed)

### Verification Layers Document (verification-layers.md)

- [ ] 1.6 Update intro line 5: "Three" to "Five"
  - **Do**: Replace "Three verification layers" with "Five verification layers" on line 5
  - **Files**: plugins/ralph-specum/references/verification-layers.md
  - **Done when**: `grep -c "Three verification" plugins/ralph-specum/references/verification-layers.md` returns 0
  - **Verify**: `grep "Five verification layers" plugins/ralph-specum/references/verification-layers.md | head -1`
  - **Commit**: `feat(vl): update intro from 3 to 5 verification layers`
  - _Requirements: FR-1, AC-1.2_

- [ ] 1.7 Add Layer 0 (EXECUTOR_START) section after intro
  - **Do**: Insert new `## Layer 0: EXECUTOR_START Signal (MANDATORY -- blocks all other layers)` section after line 6 (after `> Used by: implement.md` and the intro paragraph). Content: EXECUTOR_START verification rules, hard gate logic, ESCALATE on absence. **IMPORTANT**: Layer 0 must be self-contained — do NOT reference coordinator-pattern.md. Include escalation instructions directly (log "EXECUTOR_START absent for task $taskIndex" to .progress.md, stop iteration).
  - **Files**: plugins/ralph-specum/references/verification-layers.md
  - **Done when**: `grep -c "Layer 0: EXECUTOR_START" plugins/ralph-specum/references/verification-layers.md` returns >= 1
  - **Verify**: `grep -c "Layer 0: EXECUTOR_START" plugins/ralph-specum/references/verification-layers.md`
  - **Commit**: `feat(vl): add Layer 0 EXECUTOR_START section`
  - _Requirements: FR-1, AC-1.1_

- [ ] 1.8 Add Layer 3 (Anti-fabrication) section before current Layer 3
  - **Do**: Insert new `## Layer 3: Anti-fabrication (Verification Claim Integrity)` section before the current Layer 3. Content: independent verify command execution, fabrication detection, CI snapshot separation with generic wording (no hardcoded ruff/mypy). CI command discovery deferred to Spec 4.
  - **Files**: plugins/ralph-specum/references/verification-layers.md
  - **Done when**: `grep -c "Layer 3: Anti-fabrication" plugins/ralph-specum/references/verification-layers.md` returns >= 1
  - **Verify**: `grep -c "Layer 3: Anti-fabrication" plugins/ralph-specum/references/verification-layers.md`
  - **Commit**: `feat(vl): add Layer 3 Anti-fabrication section`
  - _Requirements: FR-1, AC-1.1, FR-13_

- [ ] 1.9 Rename Layer 3 to Layer 4 (Artifact Review)
  - **Do**: Change `## Layer 3: Artifact Review` to `## Layer 4: Artifact Review` and update all internal references to "Layer 3" within that section to "Layer 4"
  - **Files**: plugins/ralph-specum/references/verification-layers.md
  - **Done when**: `grep -c "^## Layer 4: Artifact Review" plugins/ralph-specum/references/verification-layers.md` returns >= 1 and no old "Layer 3: Artifact Review" heading exists
  - **Verify**: `grep -c "^## Layer 4: Artifact Review" plugins/ralph-specum/references/verification-layers.md`
  - **Commit**: `refactor(vl): rename Layer 3 to Layer 4 Artifact Review`
  - _Requirements: FR-1, AC-1.1_

- [ ] 1.10 Update "All 3 layers" to "All 5 layers" in Verification Summary
  - **Do**: Change "All 3 layers must pass" to "All 5 layers must pass" (~line 173). Update the numbered list from 3 items to 5 items (0-4).
  - **Files**: plugins/ralph-specum/references/verification-layers.md
  - **Done when**: `grep -c "All 3 layers" plugins/ralph-specum/references/verification-layers.md` returns 0
  - **Verify**: `grep "All 5 layers must pass" plugins/ralph-specum/references/verification-layers.md | head -1`
  - **Commit**: `fix(vl): update verification summary from 3 to 5 layers`
  - _Requirements: FR-1, AC-1.2_

- [ ] 1.11 Update "3 verification layers" to "5 verification layers" at bottom
  - **Do**: Change "The coordinator enforces 3 verification layers:" to "The coordinator enforces 5 verification layers:" (~line 194). Update the numbered list from 3 items to 5 items.
  - **Files**: plugins/ralph-specum/references/verification-layers.md
  - **Done when**: `grep -c "3 verification layers" plugins/ralph-specum/references/verification-layers.md` returns 0
  - **Verify**: `grep "5 verification layers" plugins/ralph-specum/references/verification-layers.md | head -1`
  - **Commit**: `fix(vl): update enforcement summary from 3 to 5 layers`
  - _Requirements: FR-1, AC-1.2_

- [ ] 1.12 [VERIFY] Quality checkpoint: verify verification-layers.md has 5 layers, no "3" refs
  - **Do**: Grep for layer count consistency
  - **Verify**: `grep -c "Layer [0-4]" plugins/ralph-specum/references/verification-layers.md | awk '{if($1>=5) print "PASS"; else print "FAIL: found "$1" layer refs, need >=5"}'` AND `grep -cE "all 3|All 3|3 layers|3 verification|Three verification" plugins/ralph-specum/references/verification-layers.md | awk '{if($1==0) print "PASS"; else print "FAIL: found "$1" stale 3-layer refs"}'`
  - **Done when**: 5+ layer headings found, zero "3 layers" references remain
  - **Commit**: `chore(vl): pass quality checkpoint` (only if fixes needed)

### Coordinator Pattern (coordinator-pattern.md)

- [x] 1.13 Update "Layer 3 artifact review" reference at line 304 to "Layer 4"
  - **Do**: Change "used by Layer 3 artifact review" to "used by Layer 4 artifact review" at line 304
  - **Files**: plugins/ralph-specum/references/coordinator-pattern.md
  - **Done when**: `grep -c "Layer 3 artifact review" plugins/ralph-specum/references/coordinator-pattern.md` returns 0
  - **Verify**: `grep "Layer 4 artifact review" plugins/ralph-specum/references/coordinator-pattern.md | head -1`
  - **Commit**: `fix(cp): update Layer 3 artifact review ref to Layer 4`
  - _Requirements: FR-3_

- [x] 1.14 Replace inline Layer definitions (lines 620-686) with VL reference
- [x] 1.15 Update "Layer 3: Artifact Review" reference at line 686 to "Layer 4"
- [x] 1.16 [VERIFY] Quality checkpoint: verify CP layer refs consistent
  - **Do**: Replace the inline Layer 0-4 definitions at lines 620-686 with a short reference block pointing to verification-layers.md as canonical source. Keep key rules as quick reference.
  - **Files**: plugins/ralph-specum/references/coordinator-pattern.md
  - **Done when**: `grep -c "canonical source for all 5 verification layers" plugins/ralph-specum/references/coordinator-pattern.md` returns >= 1 AND inline layer definitions replaced
  - **Verify**: `grep -c "verification-layers.md" plugins/ralph-specum/references/coordinator-pattern.md | awk '{if($1>=3) print "PASS"; else print "FAIL: need >=3 VL refs, found "$1}'`
  - **Commit**: `refactor(cp): replace inline layer definitions with VL reference`
  - _Requirements: FR-3, AC-1.4_

- [ ] 1.15 Update "Layer 3: Artifact Review" reference at line 686 to "Layer 4"
  - **Do**: In the artifact review trigger section, update "section 'Layer 3: Artifact Review'" to "section 'Layer 4: Artifact Review'"
  - **Files**: plugins/ralph-specum/references/coordinator-pattern.md
  - **Done when**: `grep "Layer 4: Artifact Review" plugins/ralph-specum/references/coordinator-pattern.md | grep verification-layers | head -1`
  - **Verify**: `grep -c "Layer 3: Artifact Review" plugins/ralph-specum/references/coordinator-pattern.md | awk '{if($1==0) print "PASS"; else print "FAIL: "$1" stale L3 refs remain"}'`
  - **Commit**: `fix(cp): update Layer 3 Artifact Review ref to Layer 4 in trigger section`
  - _Requirements: FR-3_

- [ ] 1.16 [VERIFY] Quality checkpoint: verify CP layer refs consistent
  - **Do**: Verify coordinator-pattern.md has no stale "Layer 3" refs in layer context, still has Layer 0 inline in Task Delegation
  - **Verify**: `grep -c "Layer 3: Artifact Review" plugins/ralph-specum/references/coordinator-pattern.md | awk '{if($1==0) print "PASS"; else print "FAIL: "$1" stale refs"}'` && `grep -c "Layer 0: EXECUTOR_START" plugins/ralph-specum/references/coordinator-pattern.md | awk '{if($1>=1) print "PASS: L0 inline kept"; else print "FAIL: L0 missing"}'`
  - **Done when**: Zero "Layer 3: Artifact Review" refs, Layer 0 still inline in Task Delegation
  - **Commit**: `chore(cp): pass quality checkpoint` (only if fixes needed)

### Implement Command (implement.md)

- [ ] 1.17 Update "3 layers" to "5 layers" at line 211
  - **Do**: Change "This covers: 3 layers (contradiction detection, TASK_COMPLETE signal, periodic artifact review via spec-reviewer). All must pass before advancing." to "This covers: 5 layers (EXECUTOR_START, contradiction detection, TASK_COMPLETE signal, anti-fabrication, periodic artifact review via spec-reviewer). All must pass before advancing."
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: `grep "5 layers" plugins/ralph-specum/commands/implement.md | grep -c "EXECUTOR_START"` returns >= 1
  - **Verify**: `grep "5 layers.*EXECUTOR_START.*contradiction" plugins/ralph-specum/commands/implement.md | head -1`
  - **Commit**: `fix(im): update layer count from 3 to 5 in coordinator reference`
  - _Requirements: FR-2, AC-1.3_

- [ ] 1.18 Update "all 3 verification layers" to "all 5 verification layers" at line 239
  - **Do**: Change "Run all 3 verification layers" to "Run all 5 verification layers"
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: `grep -c "all 3 verification" plugins/ralph-specum/commands/implement.md` returns 0
  - **Verify**: `grep "all 5 verification layers" plugins/ralph-specum/commands/implement.md | head -1`
  - **Commit**: `fix(im): update verification layer count from 3 to 5`
  - _Requirements: FR-2, AC-1.3_

- [ ] 1.19 Add mechanical HOLD grep check before line 225
  - **Do**: Insert new bullet before "MANDATORY: Read chat.md BEFORE delegating" (~line 225). Content: grep-based HOLD/PENDING/URGENT check with exact line matching, resolved signal tracking ([RESOLVED] marker), log to .progress.md.
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: `grep -c "\^\\\[HOLD\\\]\$\|\^\\\[PENDING\\\]\$\|\^\\\[URGENT\\\]\$" plugins/ralph-specum/commands/implement.md` returns >= 1 AND `grep -c "COORDINATOR BLOCKED" plugins/ralph-specum/commands/implement.md` returns >= 1
  - **Verify**: `grep -c "COORDINATOR BLOCKED" plugins/ralph-specum/commands/implement.md | awk '{if($1>=1) print "PASS"; else print "FAIL"}'`
  - **Commit**: `feat(im): add mechanical HOLD grep check before delegation`
  - _Requirements: FR-4, FR-5, AC-2.1, AC-2.2_

- [ ] 1.20 Add state integrity check before coordinator prompt output
  - **Do**: Insert `### State Integrity Check (before loop starts)` section after the "Execute Task Loop" heading (~line 134, before Parallel Reviewer Onboarding). Content: bash commands to count [x], compare taskIndex, drift correction logic.
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: `grep -c "STATE DRIFT" plugins/ralph-specum/commands/implement.md` returns >= 1
  - **Verify**: `grep -c "STATE DRIFT" plugins/ralph-specum/commands/implement.md | awk '{if($1>=1) print "PASS"; else print "FAIL"}'`
  - **Commit**: `feat(im): add state integrity check before task loop`
  - _Requirements: FR-7, FR-8, FR-9, AC-3.1, AC-3.2, AC-3.3_

- [ ] 1.21 Add CI snapshot separation rule after anti-fabrication bullet
  - **Do**: Insert new bullet after the "CRITICAL: Verify independently, never trust executor" section (~line 231). Content: task Verify and global CI reported separately, both must pass, "TASK VERIFY PASS but GLOBAL CI FAIL" log rule. Use generic wording — no hardcoded ruff/mypy commands. CI command discovery is deferred to Spec 4 (loop-safety-infra).
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: `grep -c "GLOBAL CI" plugins/ralph-specum/commands/implement.md` returns >= 1
  - **Verify**: `grep -c "GLOBAL CI" plugins/ralph-specum/commands/implement.md | awk '{if($1>=1) print "PASS"; else print "FAIL"}'`
  - **Commit**: `feat(im): add CI snapshot separation rule`
  - _Requirements: FR-12, FR-13, FR-14, AC-5.1, AC-5.2, AC-5.3_

- [x] 1.22 [VERIFY] Quality checkpoint: verify implement.md changes complete
- [x] 1.23 POC Checkpoint: validate all 4 files modified correctly
  - **Do**: Verify all 4 implement.md changes are in place
  - **Verify**: `grep -c "5 layers" plugins/ralph-specum/commands/implement.md | awk '{if($1>=2) print "PASS: 5-layers refs found"; else print "FAIL: need >=2, found "$1}'` && `grep -c "COORDINATOR BLOCKED" plugins/ralph-specum/commands/implement.md | awk '{if($1>=1) print "PASS: HOLD check present"; else print "FAIL"}'` && `grep -c "STATE DRIFT" plugins/ralph-specum/commands/implement.md | awk '{if($1>=1) print "PASS: state integrity present"; else print "FAIL"}'` && `grep -c "GLOBAL CI" plugins/ralph-specum/commands/implement.md | awk '{if($1>=1) print "PASS: CI separation present"; else print "FAIL"}'`
  - **Done when**: All 4 grep checks pass
  - **Commit**: `chore(im): pass quality checkpoint` (only if fixes needed)

- [ ] 1.23 POC Checkpoint: validate all 4 files modified correctly
  - **Do**: Run all Success Criteria commands from requirements.md
  - **Done when**: All 9 grep/jq success criteria pass
  - **Verify**: `echo "=== SC1: no 'all 3' in VL ===" && grep -c "all 3" plugins/ralph-specum/references/verification-layers.md && echo "=== SC2: 5+ layer refs in VL ===" && grep -c "Layer [0-4]" plugins/ralph-specum/references/verification-layers.md && echo "=== SC3: HOLD in IM ===" && grep -c '\[HOLD\]' plugins/ralph-specum/commands/implement.md && echo "=== SC4: STATE DRIFT in IM ===" && grep -c "STATE DRIFT" plugins/ralph-specum/commands/implement.md && echo "=== SC5: nativeTaskMap ===" && jq '.definitions.state.properties | has("nativeTaskMap")' plugins/ralph-specum/schemas/spec.schema.json && echo "=== SC6: nativeSyncEnabled ===" && jq '.definitions.state.properties | has("nativeSyncEnabled")' plugins/ralph-specum/schemas/spec.schema.json && echo "=== SC7: nativeSyncFailureCount ===" && jq '.definitions.state.properties | has("nativeSyncFailureCount")' plugins/ralph-specum/schemas/spec.schema.json && echo "=== SC8: chat.executor.lastReadLine ===" && jq '.definitions.state.properties.chat.properties.executor.properties | has("lastReadLine")' plugins/ralph-specum/schemas/spec.schema.json && echo "=== SC9: GLOBAL CI in IM ===" && grep -c "GLOBAL CI" plugins/ralph-specum/commands/implement.md`
  - **Commit**: `feat(engine): complete POC for engine state hardening`

## Phase 2: Refactoring

Cross-reference consistency cleanup between files.

- [x] 2.1 Verify VL Layer 0 is self-contained (no circular CP reference)
- [x] 2.2 Verify VL Layer 3 has CI separation with generic wording (no hardcoded commands)
- [x] 2.3 Verify CP reference block lists correct layer descriptions
- [x] 2.4 Verify implement.md HOLD check text matches AC-2.1 exact grep pattern
- [x] 2.5 Verify implement.md state integrity check matches AC-3.1/3.2/3.3 logic
- [x] 2.6 [VERIFY] Quality checkpoint: full cross-reference consistency
- [x] 2.7 Clean up any duplicate content between VL and CP
  - **Do**: Read VL Layer 0 section. Ensure it does NOT reference coordinator-pattern.md. ESCALATE instructions must be inline (log to .progress.md, stop iteration). CP keeps its own Layer 0 in Task Delegation section for delegation-specific context, but VL is the canonical self-contained source.
  - **Files**: plugins/ralph-specum/references/verification-layers.md
  - **Done when**: `grep -c "coordinator-pattern.md" plugins/ralph-specum/references/verification-layers.md` returns 0 in Layer 0 section
  - **Verify**: `grep -A20 "Layer 0: EXECUTOR_START" plugins/ralph-specum/references/verification-layers.md | grep -c "coordinator-pattern" | awk '{if($1==0) print "PASS: no circular ref"; else print "FAIL: circular ref found"}'`
  - **Commit**: `refactor(vl): ensure Layer 0 is self-contained` (only if changes needed)
  - _Requirements: FR-1_

- [x] 2.2 Verify VL Layer 3 has CI separation with generic wording (no hardcoded commands)
  - **Do**: Read VL Layer 3. Ensure it has CI snapshot separation with generic wording ("project-wide linting, type-checking") — NOT hardcoded ruff/mypy. Verify note about Spec 4 deferral is present.
  - **Files**: plugins/ralph-specum/references/verification-layers.md
  - **Done when**: VL Layer 3 contains "GLOBAL CI" separation rule AND no hardcoded "ruff" or "mypy"
  - **Verify**: `grep -c "GLOBAL CI" plugins/ralph-specum/references/verification-layers.md | awk '{if($1>=1) print "PASS: CI rule present"; else print "FAIL"}'` && `grep -cE "ruff|mypy" plugins/ralph-specum/references/verification-layers.md | awk '{if($1==0) print "PASS: no hardcoded CI commands"; else print "FAIL: "$1" hardcoded refs found"}'`
  - **Commit**: `refactor(vl): ensure Layer 3 uses generic CI wording`
  - _Requirements: FR-13_

- [x] 2.3 Verify CP reference block lists correct layer descriptions
  - **Do**: Re-read the CP reference block from task 1.14. Ensure quick-reference bullets match VL content exactly (Layer 0 hard gate, Layers 1-2 text checks, Layer 3 anti-fabrication, Layer 4 periodic).
  - **Files**: plugins/ralph-specum/references/coordinator-pattern.md
  - **Done when**: CP quick reference bullets are consistent with VL content
  - **Verify**: `grep -A5 "Key rules.*quick reference" plugins/ralph-specum/references/coordinator-pattern.md | grep -c "Layer" | awk '{if($1>=4) print "PASS"; else print "FAIL"}'`
  - **Commit**: `refactor(cp): verify reference block consistency` (only if changes needed)

- [x] 2.4 Verify implement.md HOLD check text matches AC-2.1 exact grep pattern
  - **Do**: Read the HOLD check inserted in task 1.19. Verify the grep pattern is exactly `grep -c "^\[HOLD\]$|^\[PENDING\]$|^\[URGENT\]$" "$SPEC_PATH/chat.md"` (exact line matching, anchors required) and the blocking logic matches AC-2.1/AC-2.2.
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: HOLD grep pattern exactly matches AC-2.1 spec (anchors + dollar signs)
  - **Verify**: `grep -c '\^.*HOLD.*\^.*PENDING.*\^.*URGENT' plugins/ralph-specum/commands/implement.md | awk '{if($1>=1) print "PASS"; else print "FAIL"}'`
  - **Commit**: `refactor(im): verify HOLD grep pattern alignment` (only if changes needed)

- [x] 2.5 Verify implement.md state integrity check matches AC-3.1/3.2/3.3 logic
  - **Do**: Read state integrity check. Verify: (1) counts `[x]` in tasks.md, (2) compares with taskIndex, (3) corrects if taskIndex < completed, (4) warns if taskIndex > completed, (5) no action if equal.
  - **Files**: plugins/ralph-specum/commands/implement.md
  - **Done when**: All 3 drift scenarios (AC-3.1, AC-3.2, AC-3.3) covered in check
  - **Verify**: `grep -c "STATE DRIFT" plugins/ralph-specum/commands/implement.md | awk '{if($1>=1) print "PASS"}'` && `grep -c "STATE WARNING" plugins/ralph-specum/commands/implement.md | awk '{if($1>=1) print "PASS: AC-3.3 warn present"; else print "FAIL: AC-3.3 missing"}'`
  - **Commit**: `refactor(im): verify state integrity check completeness` (only if changes needed)

- [x] 2.6 [VERIFY] Quality checkpoint: full cross-reference consistency
  - **Do**: Verify all files reference each other correctly and all layer counts are consistent
  - **Verify**: `echo "=== Cross-ref check ===" && grep -c "verification-layers.md" plugins/ralph-specum/references/coordinator-pattern.md | awk '{if($1>=2) print "PASS: CP refs VL ("$1" refs)"; else print "FAIL: need >=2 VL refs"}' && grep -c "coordinator-pattern.md" plugins/ralph-specum/references/verification-layers.md | awk '{if($1>=1) print "PASS: VL refs CP"; else print "FAIL"}' && echo "=== Layer count consistency ===" && grep -cE "3 layers|3 verification|Three verification|all 3" plugins/ralph-specum/references/verification-layers.md plugins/ralph-specum/commands/implement.md plugins/ralph-specum/references/coordinator-pattern.md 2>/dev/null | grep -v ":0$" | wc -l | awk '{if($1==0) print "PASS: no stale 3-layer refs"; else print "FAIL: stale refs found"}'`
  - **Done when**: CP references VL, VL references CP, zero stale "3 layers" across all 3 files
  - **Commit**: `chore(engine): pass cross-reference quality checkpoint` (only if fixes needed)

- [x] 2.7 Clean up any duplicate content between VL and CP
  - **Do**: Final sweep. Ensure no content is duplicated between VL and CP that should be single-source. CP should only have quick-reference bullets + Layer 0 Task Delegation inline. All full layer definitions should be in VL only.
  - **Files**: plugins/ralph-specum/references/coordinator-pattern.md, plugins/ralph-specum/references/verification-layers.md
  - **Done when**: No full layer definitions duplicated in CP (only quick-ref + L0 delegation)
  - **Verify**: `grep -c "Check spec-executor output for contradiction" plugins/ralph-specum/references/coordinator-pattern.md | awk '{if($1==0) print "PASS: no L1 detail in CP"; else print "WARN: L1 detail still in CP"}'`
  - **Commit**: `refactor(cp): remove duplicate layer details` (only if changes needed)

## Phase 3: Testing (AC Verification)

Systematic verification of every acceptance criterion via grep/jq.

### US-1: Unify Verification Layer Documentation

- [x] 3.1 Verify AC-1.1: VL defines 5 layers (0-4)
- [x] 3.2 Verify AC-1.2: VL contains no "3 layers" references
- [x] 3.3 Verify AC-1.3: implement.md references 5 layers (line 211)
- [x] 3.4 Verify AC-1.4: CP defers to VL (contains verification-layers.md reference)
- [x] 3.5 Verify AC-2.1: implement.md has HOLD grep check
- [x] 3.6 Verify AC-2.2: implement.md has COORDINATOR BLOCKED log
- [x] 3.7 Verify AC-2.3: implement.md has RESOLVED signal tracking
- [x] 3.8 Verify AC-3.1: implement.md has state integrity check
- [x] 3.9 Verify AC-3.2: implement.md has STATE DRIFT correction
- [x] 3.10 Verify AC-3.3: implement.md has STATE WARNING
- [x] 3.11 Verify AC-4.1: schema has nativeTaskMap
- [x] 3.12 Verify AC-4.2: schema has nativeSyncEnabled
- [x] 3.13 Verify AC-4.3: schema has nativeSyncFailureCount
- [x] 3.14 Verify AC-4.4: schema has chat.executor.lastReadLine
- [x] 3.15 Verify AC-5.1: implement.md has CI separation rule
- [x] 3.16 Verify AC-5.2: implement.md has GLOBAL CI guidance
- [x] 3.17 Verify AC-5.3: implement.md has "TASK VERIFY PASS but GLOBAL CI FAIL" log
- [x] 3.18 [VERIFY] Phase 3 complete: all AC verified
  - **Do**: Run grep for each layer heading in verification-layers.md
  - **Verify**: `grep -c "Layer 0: EXECUTOR_START" plugins/ralph-specum/references/verification-layers.md | awk '{if($1>=1) print "PASS: L0 present"; else print "FAIL: L0 missing"}'` && `grep -c "Layer 1: Contradiction" plugins/ralph-specum/references/verification-layers.md | awk '{if($1>=1) print "PASS: L1 present"; else print "FAIL: L1 missing"}'` && `grep -c "Layer 2: TASK_COMPLETE" plugins/ralph-specum/references/verification-layers.md | awk '{if($1>=1) print "PASS: L2 present"; else print "FAIL: L2 missing"}'` && `grep -c "Layer 3: Anti-fabrication" plugins/ralph-specum/references/verification-layers.md | awk '{if($1>=1) print "PASS: L3 present"; else print "FAIL: L3 missing"}'` && `grep -c "Layer 4: Artifact Review" plugins/ralph-specum/references/verification-layers.md | awk '{if($1>=1) print "PASS: L4 present"; else print "FAIL: L4 missing"}'`
  - **Done when**: All 5 layer headings found
  - **Commit**: None (verification only)

- [ ] 3.2 Verify AC-1.2: VL contains no "3 layers" references
  - **Do**: Grep for any remaining "3 layers", "all 3", "All 3", "3 verification", "Three verification" in VL
  - **Verify**: `grep -cE "all 3|All 3|3 layers|3 verification|Three verification" plugins/ralph-specum/references/verification-layers.md | awk '{if($1==0) print "PASS: no stale 3-layer refs"; else print "FAIL: "$1" refs found"}'`
  - **Done when**: Zero matches
  - **Commit**: None (verification only)

- [ ] 3.3 Verify AC-1.3: IM references "5 layers"
  - **Do**: Grep implement.md for "5 layers" and "5 verification"
  - **Verify**: `grep -cE "5 layers|5 verification" plugins/ralph-specum/commands/implement.md | awk '{if($1>=2) print "PASS: "$1" 5-layer refs found"; else print "FAIL: need >=2, found "$1}'`
  - **Done when**: At least 2 references to "5 layers" in implement.md
  - **Commit**: None (verification only)

- [ ] 3.4 Verify AC-1.4: CP defers to VL for layer definitions
  - **Do**: Grep coordinator-pattern.md Verification Layers section for "verification-layers.md" reference
  - **Verify**: `grep "Verification Layers" -A20 plugins/ralph-specum/references/coordinator-pattern.md | grep -c "verification-layers.md" | awk '{if($1>=1) print "PASS: CP defers to VL"; else print "FAIL: no VL ref in CP Verification Layers section"}'`
  - **Done when**: CP Verification Layers section references verification-layers.md
  - **Commit**: None (verification only)

### US-2: Mechanical HOLD Signal Detection

- [ ] 3.5 Verify AC-2.1: HOLD grep check in IM
  - **Do**: Grep implement.md for HOLD/PENDING/URGENT with exact line matching (anchors)
  - **Verify**: `grep -c '\^.*HOLD.*\$.*\^.*PENDING.*\$.*\^.*URGENT' plugins/ralph-specum/commands/implement.md | awk '{if($1>=1) print "PASS: HOLD grep check present with anchors"; else print "FAIL"}'`
  - **Done when**: Anchored HOLD/PENDING/URGENT grep pattern found in implement.md
  - **Commit**: None (verification only)

- [ ] 3.6 Verify AC-2.2: HOLD block logs to .progress.md
  - **Do**: Grep implement.md for "COORDINATOR BLOCKED" log message
  - **Verify**: `grep -c "COORDINATOR BLOCKED" plugins/ralph-specum/commands/implement.md | awk '{if($1>=1) print "PASS"; else print "FAIL"}'`
  - **Done when**: "COORDINATOR BLOCKED" log present
  - **Commit**: None (verification only)

### US-3: State Integrity Validation

- [ ] 3.7 Verify AC-3.1: State integrity check in IM
  - **Do**: Grep implement.md for `[x]` count and taskIndex comparison
  - **Verify**: `grep -c "STATE DRIFT" plugins/ralph-specum/commands/implement.md | awk '{if($1>=1) print "PASS"; else print "FAIL"}'`
  - **Done when**: State drift detection present
  - **Commit**: None (verification only)

- [ ] 3.8 Verify AC-3.2/3.3: Drift correction and warning logic in IM
  - **Do**: Verify both correction (taskIndex < completed) and warning (taskIndex > completed) logic present
  - **Verify**: `grep -c "STATE DRIFT.*taskIndex" plugins/ralph-specum/commands/implement.md | awk '{if($1>=1) print "PASS: AC-3.2 correction present"; else print "FAIL"}'` && `grep -c "STATE WARNING" plugins/ralph-specum/commands/implement.md | awk '{if($1>=1) print "PASS: AC-3.3 warning present"; else print "FAIL"}'`
  - **Done when**: Both drift correction and warning present
  - **Commit**: None (verification only)

### US-4: Schema Completeness

- [ ] 3.9 Verify AC-4.1 through AC-4.4: Schema has all 4 new fields
  - **Do**: Run jq for each field
  - **Verify**: `jq '.definitions.state.properties | has("nativeTaskMap")' plugins/ralph-specum/schemas/spec.schema.json | grep -q true && echo "AC-4.1 PASS"` && `jq '.definitions.state.properties | has("nativeSyncEnabled")' plugins/ralph-specum/schemas/spec.schema.json | grep -q true && echo "AC-4.2 PASS"` && `jq '.definitions.state.properties | has("nativeSyncFailureCount")' plugins/ralph-specum/schemas/spec.schema.json | grep -q true && echo "AC-4.3 PASS"` && `jq '.definitions.state.properties.chat.properties.executor.properties | has("lastReadLine")' plugins/ralph-specum/schemas/spec.schema.json | grep -q true && echo "AC-4.4 PASS"`
  - **Done when**: All 4 jq commands return true
  - **Commit**: None (verification only)

### US-5: CI Snapshot Separation

- [ ] 3.10 Verify AC-5.1: CI separation rule in IM
  - **Do**: Grep implement.md for "GLOBAL CI" separation rule
  - **Verify**: `grep -c "GLOBAL CI" plugins/ralph-specum/commands/implement.md | awk '{if($1>=1) print "PASS"; else print "FAIL"}'`
  - **Done when**: GLOBAL CI separation rule present
  - **Commit**: None (verification only)

- [ ] 3.11 Verify AC-5.2/5.3: Anti-fabrication runs both, no-advance rule (generic wording)
  - **Do**: Verify VL Layer 3 has CI separation with generic wording (no ruff/mypy) and implement.md has no-advance rule
  - **Verify**: `grep -c "TASK VERIFY PASS but GLOBAL CI FAIL" plugins/ralph-specum/commands/implement.md | awk '{if($1>=1) print "PASS: AC-5.3 no-advance rule"; else print "FAIL"}'` && `grep -c "GLOBAL CI" plugins/ralph-specum/references/verification-layers.md | awk '{if($1>=1) print "PASS: AC-5.2 in VL"; else print "FAIL"}'` && `grep -cE "ruff|mypy" plugins/ralph-specum/references/verification-layers.md | awk '{if($1==0) print "PASS: generic wording only"; else print "FAIL: hardcoded CI commands"}'`
  - **Done when**: Both rules present, no hardcoded CI commands
  - **Commit**: None (verification only)

- [ ] 3.12 [VERIFY] Quality checkpoint: run ALL requirements.md Success Criteria
  - **Do**: Execute all 9 success criteria commands from requirements.md in sequence
  - **Verify**: `SC_PASS=0 && SC_FAIL=0 && grep -c "all 3" plugins/ralph-specum/references/verification-layers.md | awk '{if($1==0) SC_PASS++; else SC_FAIL++}' ; grep -c "Layer [0-4]" plugins/ralph-specum/references/verification-layers.md | awk '{if($1>=5) SC_PASS++; else SC_FAIL++}' ; grep -c '\[HOLD\]' plugins/ralph-specum/commands/implement.md | awk '{if($1>=1) SC_PASS++; else SC_FAIL++}' ; grep -c "STATE DRIFT" plugins/ralph-specum/commands/implement.md | awk '{if($1>=1) SC_PASS++; else SC_FAIL++}' ; jq -e '.definitions.state.properties | has("nativeTaskMap")' plugins/ralph-specum/schemas/spec.schema.json && SC_PASS=$((SC_PASS+1)) || SC_FAIL=$((SC_FAIL+1)) ; jq -e '.definitions.state.properties | has("nativeSyncEnabled")' plugins/ralph-specum/schemas/spec.schema.json && SC_PASS=$((SC_PASS+1)) || SC_FAIL=$((SC_FAIL+1)) ; jq -e '.definitions.state.properties | has("nativeSyncFailureCount")' plugins/ralph-specum/schemas/spec.schema.json && SC_PASS=$((SC_PASS+1)) || SC_FAIL=$((SC_FAIL+1)) ; jq -e '.definitions.state.properties.chat.properties.executor.properties | has("lastReadLine")' plugins/ralph-specum/schemas/spec.schema.json && SC_PASS=$((SC_PASS+1)) || SC_FAIL=$((SC_FAIL+1)) ; grep -c "GLOBAL CI" plugins/ralph-specum/commands/implement.md | awk '{if($1>=1) SC_PASS++; else SC_FAIL++}' ; echo "PASS: $SC_PASS / FAIL: $SC_FAIL"`
  - **Done when**: All 9 criteria pass
  - **Commit**: `chore(engine): all success criteria verified`

## Phase 4: Quality Gates

- [x] 4.1 Verify schema defaults are backwards compatible
  - **Do**: Check that all new schema fields have defaults. Validate schema structure with jq.
  - **Files**: plugins/ralph-specum/schemas/spec.schema.json
  - **Done when**: `jq '.definitions.state.properties.nativeTaskMap.default' plugins/ralph-specum/schemas/spec.schema.json` returns `{}` and all other fields have defaults
  - **Verify**: `jq '.definitions.state.properties.nativeTaskMap.default' plugins/ralph-specum/schemas/spec.schema.json && jq '.definitions.state.properties.nativeSyncEnabled.default' plugins/ralph-specum/schemas/spec.schema.json && jq '.definitions.state.properties.nativeSyncFailureCount.default' plugins/ralph-specum/schemas/spec.schema.json && jq '.definitions.state.properties.chat.properties.executor.properties.lastReadLine.default' plugins/ralph-specum/schemas/spec.schema.json`
  - **Commit**: `fix(schema): ensure all new fields have backwards-compatible defaults` (only if fixes needed)

- [x] 4.2 Verify no agent files were modified
  - **Do**: Check git diff -- no agent files should appear
  - **Verify**: `git diff --name-only HEAD~30 -- plugins/ralph-specum/agents/ | wc -l | awk '{if($1==0) print "PASS: no agent changes"; else print "FAIL: "$1" agent files changed"}'`
  - **Done when**: Zero agent files modified
  - **Commit**: None (verification only)

- [x] 4.3 Verify no new files created
  - **Do**: Check git status for untracked files in plugin directory
  - **Verify**: `git status --porcelain plugins/ralph-specum/ | grep "^??" | wc -l | awk '{if($1==0) print "PASS: no new files"; else print "FAIL: "$1" new files found"}'`
  - **Done when**: Zero new files in plugin directory
  - **Commit**: None (verification only)

- [x] 4.4 Verify diff size within NFR-1 bounds (< 30 lines per file, excluding VL)
  - **Do**: Count changed lines per file via git diff
  - **Verify**: `for f in plugins/ralph-specum/schemas/spec.schema.json plugins/ralph-specum/commands/implement.md plugins/ralph-specum/references/coordinator-pattern.md; do echo "$f:"; git diff HEAD -- "$f" | grep -c "^[+-]" | awk '{if($1<=60) print " PASS ("$1" lines)"; else print " WARN ("$1" lines -- check NFR-1)"}'; done`
  - **Done when**: Diff sizes within bounds
  - **Commit**: None (verification only)

- [x] 4.5 [P] Bump version in plugin.json
  - **Do**: Increment patch version from 4.11.0 to 4.12.0 in plugin.json
  - **Files**: plugins/ralph-specum/.claude-plugin/plugin.json
  - **Done when**: Version is 4.12.0
  - **Verify**: `jq '.version' plugins/ralph-specum/.claude-plugin/plugin.json | grep -q "4.12.0" && echo PASS`
  - **Commit**: `chore(plugin): bump version to 4.12.0`

- [ ] 4.6 [P] Bump version in marketplace.json
  - **Do**: Update ralph-specum entry version from 4.11.0 to 4.12.0 in marketplace.json
  - **Files**: .claude-plugin/marketplace.json
  - **Done when**: ralph-specum version in marketplace.json is 4.12.0
  - **Verify**: `jq '.plugins[] | select(.name=="ralph-specum") | .version' .claude-plugin/marketplace.json | grep -q "4.12.0" && echo PASS`
  - **Commit**: `chore(marketplace): bump ralph-specum version to 4.12.0`

- [ ] 4.7 [VERIFY] Final full CI: run all success criteria one last time
  - **Do**: Execute complete success criteria suite
  - **Verify**: `grep -c "all 3" plugins/ralph-specum/references/verification-layers.md | awk '{if($1==0) print "SC1 PASS"; else print "SC1 FAIL"}' && grep -c "Layer [0-4]" plugins/ralph-specum/references/verification-layers.md | awk '{if($1>=5) print "SC2 PASS"; else print "SC2 FAIL"}' && grep -c '\[HOLD\]' plugins/ralph-specum/commands/implement.md | awk '{if($1>=1) print "SC3 PASS"; else print "SC3 FAIL"}' && grep -c "STATE DRIFT" plugins/ralph-specum/commands/implement.md | awk '{if($1>=1) print "SC4 PASS"; else print "SC4 FAIL"}' && jq -e '.definitions.state.properties | has("nativeTaskMap")' plugins/ralph-specum/schemas/spec.schema.json | grep -q true && echo "SC5 PASS" && jq -e '.definitions.state.properties | has("nativeSyncEnabled")' plugins/ralph-specum/schemas/spec.schema.json | grep -q true && echo "SC6 PASS" && jq -e '.definitions.state.properties | has("nativeSyncFailureCount")' plugins/ralph-specum/schemas/spec.schema.json | grep -q true && echo "SC7 PASS" && jq -e '.definitions.state.properties.chat.properties.executor.properties | has("lastReadLine")' plugins/ralph-specum/schemas/spec.schema.json | grep -q true && echo "SC8 PASS" && grep -c "GLOBAL CI" plugins/ralph-specum/commands/implement.md | awk '{if($1>=1) print "SC9 PASS"; else print "SC9 FAIL"}'`
  - **Done when**: All 9 criteria pass
  - **Commit**: None (final verification)

## Phase 5: PR Lifecycle

- [x] 5.1 Create feature branch and push
- [x] 5.2 Create PR via gh CLI
- [x] 5.3 Monitor CI and resolve any failures
- [x] 5.4 Final validation: all completion criteria met
  - **Do**:
    1. Verify on feature branch: `git branch --show-current`
    2. Stage all changed files: `git add plugins/ralph-specum/schemas/spec.schema.json plugins/ralph-specum/references/verification-layers.md plugins/ralph-specum/references/coordinator-pattern.md plugins/ralph-specum/commands/implement.md plugins/ralph-specum/.claude-plugin/plugin.json .claude-plugin/marketplace.json`
    3. Push: `git push -u origin $(git branch --show-current)`
  - **Files**: all 6 modified files
  - **Done when**: Branch pushed to remote
  - **Verify**: `git log --oneline -5`
  - **Commit**: None (push only)

- [ ] 5.2 Create PR via gh CLI
  - **Do**: Create PR with title and body summarizing the 5 engine fixes
  - **Verify**: `gh pr view --json url -q .url`
  - **Done when**: PR URL returned
  - **Commit**: None

- [ ] 5.3 Monitor CI and resolve any failures
  - **Do**: Watch CI checks, fix any issues
  - **Verify**: `gh pr checks 2>&1 | head -20`
  - **Done when**: All CI checks green (or no CI configured)
  - **Commit**: `fix(engine): resolve CI failures` (if needed)

- [ ] 5.4 Final validation: all completion criteria met
  - **Do**: Re-run all success criteria + diff size check + version check
  - **Verify**: `echo "=== Final Validation ===" && jq '.version' plugins/ralph-specum/.claude-plugin/plugin.json && jq '.plugins[] | select(.name=="ralph-specum") | .version' .claude-plugin/marketplace.json && echo "--- SC ---" && grep -c "all 3" plugins/ralph-specum/references/verification-layers.md && grep -c "Layer [0-4]" plugins/ralph-specum/references/verification-layers.md && grep -c '\[HOLD\]' plugins/ralph-specum/commands/implement.md && grep -c "STATE DRIFT" plugins/ralph-specum/commands/implement.md && jq -e '.definitions.state.properties | has("nativeTaskMap") and has("nativeSyncEnabled") and has("nativeSyncFailureCount") and has("chat")' plugins/ralph-specum/schemas/spec.schema.json && grep -c "GLOBAL CI" plugins/ralph-specum/commands/implement.md`
  - **Done when**: All checks pass, versions match, PR created
  - **Commit**: None

## Notes

- **POC shortcuts**: None -- all changes are surgical edits, no shortcuts needed
- **Production TODOs**: CI command discovery (which global CI commands to run per project type) deferred to Spec 4 (loop-safety-infra). This spec only adds the conceptual separation rule.
- **Design decision**: VL Layer 0 is self-contained (no circular reference to CP). CP keeps its own Layer 0 in Task Delegation section for delegation-specific context.
- **Out of scope (noted for future)**:
  - stop-watcher.sh:636 says "3 layers" -- Spec 2 or 4
  - failure-recovery.md:429 says "3 verification layers" -- Spec 2
  - agents/spec-executor.md EXECUTOR_START emission -- Spec 3
