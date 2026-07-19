---
spec: requirements-process-improvements
phase: tasks
created: 2026-07-19
---

# Tasks: requirements-process-improvements

## Overview

Total tasks: 57

Workflow: POC-first (per tasks interview: thorough fine-grained POC-first breakdown). POC = lint script core + template restructure proving the lint pipeline end-to-end against this spec's own requirements.md. Then agent/command/rubric edits, then full fixture test coverage, then quality gates + PR lifecycle.

Quality commands for this repo (no build system, markdown plugin + bash scripts):
- Syntax: `bash -n <script>`
- Tests: `bash plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh`
- Grep gates on edited markdown (per-task Verify commands)

All paths repo-relative from worktree root. Constraints: ID token formats stable (FR-4); additive-only sections, keep `## Out of Scope` heading (FR-8); rubric prose terse (FR-14/NFR-2); plain bash only, style-matched to `update-spec-index.sh` / `test-path-resolver.sh`.

## Completion Criteria

- Zero regressions (existing hook script tests still pass)
- All 8 lint checks fixture-tested (pass + fail case each)
- Scripted E2E verdict logic proven (FAIL→1, WARN-only→0, usage→2)
- CI green, PR created, review comments resolved
- Version bumped 4.9.1→4.10.0 in both plugin.json and marketplace.json

## Phase 1: Make It Work (POC)

Focus: lint script with all 8 checks + template restructure. Prove pipeline by linting this spec's own requirements.md to exit 0.

- [x] 1.1 Scaffold lint-requirements.sh skeleton
  - **Do**:
    1. Create `plugins/ralph-specum/hooks/scripts/lint-requirements.sh`: `#!/bin/bash`, usage comment block (style of `update-spec-index.sh`), NO `set -e` in main loop
    2. Arg validation: missing arg or unreadable file → print usage to stderr, `exit 2`
    3. Add finding helpers: `fail_finding <check> <msg>` / `warn_finding <check> <msg>` emitting `FAIL|Cn|msg` / `WARN|Cn|msg` to stdout, incrementing counters; per-check status vars C1..C8
    4. Add end-of-run summary: emit `CHECK|Cn|PASS` for each clean check, then `RESULT: <PASS|FAIL> (X FAIL, Y WARN, Z PASS)`; exit 1 if any FAIL else 0; `chmod +x` the script
  - **Files**: plugins/ralph-specum/hooks/scripts/lint-requirements.sh
  - **Done when**: Script runs against any readable file emitting 8 `CHECK|Cn|PASS` lines + `RESULT: PASS (0 FAIL, 0 WARN, 8 PASS)`; no-arg run exits 2
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/lint-requirements.sh && bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh README.md; test $? -eq 0 && bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh; test $? -eq 2 && echo PASS`
  - **Commit**: `feat(lint): scaffold lint-requirements.sh with output/exit-code contract`
  - _Requirements: FR-6, AC-5.1_
  - _Design: Component C, Output Contract_

- [x] 1.2 Implement C1 ID & cross-reference integrity (FAIL-class)
  - **Do**:
    1. Collect defined IDs: `### US-N:` headings, `- AC-N.N:` bullets, `| FR-N |` rows, `| NFR-N |` rows; `FR-N (retired)` counts as defined
    2. FAIL on: duplicate defined ID; malformed ID token; AC ID referenced in FR-table Acceptance Criteria column that is not defined; FR row referencing zero `AC-N.N` IDs
    3. WARN (within C1) on: defined AC referenced by no FR row; suspicious ID sequence (gaps without retirement)
  - **Files**: plugins/ralph-specum/hooks/scripts/lint-requirements.sh
  - **Done when**: A doc with a dangling `AC-9.9` ref in the FR table produces `FAIL|C1|...` and exit 1; a clean doc produces `CHECK|C1|PASS`
  - **Verify**: `printf '### US-1: T\n- AC-1.1: Given a, When b, Then c\n\n| ID | Requirement | Priority | Acceptance Criteria |\n|--|--|--|--|\n| FR-1 | System MUST x | Must | AC-9.9 |\n' > /tmp/c1-bad.md && bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh /tmp/c1-bad.md | grep -q 'FAIL|C1' && echo PASS`
  - **Commit**: `feat(lint): C1 ID and cross-reference integrity check`
  - _Requirements: FR-6, AC-5.1, FR-4, AC-3.3_
  - _Design: Component C, C1; Edge Cases (retired rows)_

- [x] 1.3 Implement C2 GWT clause presence (FAIL-class)
  - **Do**:
    1. For each `- AC-N.N:` bullet, join continuation lines (until next list item or blank line) into one string
    2. FAIL any AC missing one of `Given`, `When`, `Then`; message names the AC ID and missing clause
  - **Files**: plugins/ralph-specum/hooks/scripts/lint-requirements.sh
  - **Done when**: AC missing `Then` → `FAIL|C2|AC-N.N: missing "Then" clause`, exit 1; multi-line AC with clauses across lines passes
  - **Verify**: `printf -- '- AC-1.1: Given a, When b, the outcome happens\n' > /tmp/c2-bad.md && bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh /tmp/c2-bad.md | grep -q 'FAIL|C2' && echo PASS`
  - **Commit**: `feat(lint): C2 Given/When/Then clause presence check`
  - _Requirements: FR-1, AC-1.3_
  - _Design: Component C, C2; Edge Cases (multi-line AC)_

- [x] 1.4 [VERIFY] Quality checkpoint: script syntax + C1/C2 smoke
  - **Do**: Run `bash -n` on the script; run it against `specs/requirements-process-improvements/requirements.md`; confirm no crash, C1/C2 findings plausible (real doc is GWT-form, expect no C2 FAIL)
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/lint-requirements.sh && bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh specs/requirements-process-improvements/requirements.md | grep -q 'RESULT:' && echo PASS`
  - **Done when**: Syntax clean, RESULT line emitted, no C2 FAIL on the real doc
  - **Commit**: `chore(lint): pass quality checkpoint` (only if fixes needed)

- [x] 1.5 Implement C3 MoSCoW priority values (FAIL-class)
  - **Do**:
    1. Scope to FR-table rows only (`^| FR-N |` pattern; awk -F'|' third column) — Risks-table Impact column (High/Medium/Low) must NOT be scanned
    2. FAIL any FR Priority cell not exactly one of Must/Should/Could
  - **Files**: plugins/ralph-specum/hooks/scripts/lint-requirements.sh
  - **Done when**: FR row with `High` → `FAIL|C3|...`, exit 1; doc with High/Medium/Low only in Risks table passes C3
  - **Verify**: `printf '| ID | Requirement | Priority | Acceptance Criteria |\n|--|--|--|--|\n| FR-1 | System MUST x | High | AC-1.1 |\n- AC-1.1: Given a, When b, Then c\n' > /tmp/c3-bad.md && bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh /tmp/c3-bad.md | grep -q 'FAIL|C3' && echo PASS`
  - **Commit**: `feat(lint): C3 MoSCoW priority values check`
  - _Requirements: FR-10, AC-5.4, AC-8.2_
  - _Design: Component C, C3_

- [x] 1.6 Implement C4 requirement-language lint (FAIL-class)
  - **Do**:
    1. FAIL any FR-table row whose Requirement cell lacks `MUST` and `SHOULD`
    2. WARN (within C4) on banned vague terms in FR rows and AC lines only: gracefully, seamless, robust, user-friendly, appropriately, properly, "works correctly" (case-insensitive; heuristic, never FAIL)
  - **Files**: plugins/ralph-specum/hooks/scripts/lint-requirements.sh
  - **Done when**: FR without modal → `FAIL|C4`; AC containing "gracefully" → `WARN|C4` with exit unaffected by the WARN
  - **Verify**: `printf '| FR-1 | System handles x | Must | AC-1.1 |\n- AC-1.1: Given a, When b, Then it works gracefully\n' > /tmp/c4-bad.md && bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh /tmp/c4-bad.md | grep -q 'FAIL|C4' && bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh /tmp/c4-bad.md | grep -q 'WARN|C4' && echo PASS`
  - **Commit**: `feat(lint): C4 requirement-language lint (modal + banned terms)`
  - _Requirements: FR-1, AC-1.1, AC-5.1_
  - _Design: Component C, C4; Error Handling (false positives)_

- [x] 1.7 [VERIFY] Quality checkpoint: C3/C4 on real artifact
  - **Do**: `bash -n` script; run against real requirements.md; confirm C3 passes (FR table already MoSCoW, Risks table not flagged) and C4 emits at most WARN (quoted "handle gracefully" in AC-1.2 is WARN-class)
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/lint-requirements.sh && ! bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh specs/requirements-process-improvements/requirements.md | grep -qE 'FAIL\|C3|FAIL\|C4' && echo PASS`
  - **Done when**: No C3/C4 FAIL on the real doc
  - **Commit**: `chore(lint): pass quality checkpoint` (only if fixes needed)

- [x] 1.8 Implement C5 NFR fill-or-N/A (FAIL-class)
  - **Do**:
    1. For each `| NFR-N |` row: Metric and Target cells must be non-empty and free of `{{...}}` placeholders, OR Target must match `N/A: <reason text>`
    2. FAIL on empty cell, placeholder, or bare `N/A` without `: reason`
  - **Files**: plugins/ralph-specum/hooks/scripts/lint-requirements.sh
  - **Done when**: `{{metric}}` row → `FAIL|C5`; bare `N/A` → `FAIL|C5`; `N/A: markdown-only change` passes
  - **Verify**: `printf '| NFR-1 | Performance | {{metric}} | {{target}} |\n| NFR-2 | Security | N/A | N/A |\n' > /tmp/c5-bad.md && test "$(bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh /tmp/c5-bad.md | grep -c 'FAIL|C5')" -ge 2 && echo PASS`
  - **Commit**: `feat(lint): C5 NFR fill-or-N/A check`
  - _Requirements: FR-12, AC-8.3_
  - _Design: Component C, C5; Edge Cases (N/A NFR rows)_

- [x] 1.9 Implement C6 six-scenario coverage proxy (WARN-class)
  - **Do**:
    1. Split doc into story blocks (`### US-N:` to next `###` or section end); gather each block's AC lines
    2. Story passes if any AC matches keywords (case-insensitive: error, invalid, missing, empty, cancel, denied, unauthorized, limit, boundary) OR block contains an `N/A:` scenario line
    3. Otherwise `WARN|C6|US-N: happy-path-only ACs, no N/A markings` — never FAIL, never affects exit code
  - **Files**: plugins/ralph-specum/hooks/scripts/lint-requirements.sh
  - **Done when**: Happy-path-only story → WARN + exit 0 (absent other FAILs)
  - **Verify**: `printf '### US-1: T\n- AC-1.1: Given a, When b, Then c\n' > /tmp/c6-warn.md && bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh /tmp/c6-warn.md | grep -q 'WARN|C6' && echo PASS`
  - **Commit**: `feat(lint): C6 six-scenario coverage proxy (WARN)`
  - _Requirements: FR-2, AC-2.2_
  - _Design: Component C, C6_

- [x] 1.10 Implement C7 unowned TBD / open questions (WARN-class)
  - **Do**:
    1. Every `TBD` occurrence must carry an `(owner, date)`-style parenthetical (`TBD (` followed by comma-separated content); else `WARN|C7`
    2. Every bullet under `## Unresolved Questions` must contain `Owner:`; else `WARN|C7` naming the item
  - **Files**: plugins/ralph-specum/hooks/scripts/lint-requirements.sh
  - **Done when**: Bare `TBD` and ownerless question bullets each emit WARN; exit stays 0 absent FAILs
  - **Verify**: `printf 'Target is TBD\n## Unresolved Questions\n- what about x?\n' > /tmp/c7-warn.md && test "$(bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh /tmp/c7-warn.md | grep -c 'WARN|C7')" -ge 2 && echo PASS`
  - **Commit**: `feat(lint): C7 unowned TBD and open-question check (WARN)`
  - _Requirements: FR-5, AC-4.3_
  - _Design: Component C, C7_

- [x] 1.11 [VERIFY] Quality checkpoint: C5-C7 wired, WARNs don't flip exit code
  - **Do**: `bash -n`; run script on /tmp/c6-warn.md and /tmp/c7-warn.md confirming exit 0 with WARN lines present
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/lint-requirements.sh && bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh /tmp/c7-warn.md >/dev/null; test $? -eq 0 && echo PASS`
  - **Done when**: WARN-only docs exit 0
  - **Commit**: `chore(lint): pass quality checkpoint` (only if fixes needed)

- [x] 1.12 Implement C8 MUST:SHOULD ratio advisory (WARN-class)
  - **Do**:
    1. Count FR rows and Must-priority rows; if total FRs >= 8 AND Must share > 85% → `WARN|C8|no cut-line signal: N of M FRs are Must`
    2. Suppress entirely when total FRs < 8 (advisory meaningless at small N)
  - **Files**: plugins/ralph-specum/hooks/scripts/lint-requirements.sh
  - **Done when**: 10 all-Must FRs → WARN; 5 all-Must FRs → `CHECK|C8|PASS`
  - **Verify**: `{ printf '| ID | Requirement | Priority | Acceptance Criteria |\n|--|--|--|--|\n'; for i in 1 2 3 4 5 6 7 8 9 10; do printf '| FR-%s | System MUST x | Must | AC-1.1 |\n' "$i"; done; printf -- '- AC-1.1: Given a, When b, Then c\n'; } > /tmp/c8-warn.md && bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh /tmp/c8-warn.md | grep -q 'WARN|C8' && echo PASS`
  - **Commit**: `feat(lint): C8 MUST:SHOULD ratio advisory (WARN)`
  - _Requirements: FR-6, AC-5.1_
  - _Design: Component C, C8; Edge Cases (zero SHOULD tiny specs)_

- [x] 1.13 Finalize output/exit-code contract end-to-end
  - **Do**:
    1. Confirm RESULT verdict logic: `FAIL` if any FAIL finding else `PASS`; counts = checks by worst status (X FAIL, Y WARN, Z PASS summing to 8)
    2. Confirm exit map: 0 = no FAIL (WARNs allowed), 1 = >=1 FAIL, 2 = usage/unreadable file; script is executable
    3. Clean up /tmp/c*-{bad,warn}.md scratch files from prior tasks
  - **Files**: plugins/ralph-specum/hooks/scripts/lint-requirements.sh
  - **Done when**: All three exit paths reproduce on demand; `test -x` passes
  - **Verify**: `test -x plugins/ralph-specum/hooks/scripts/lint-requirements.sh && bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh /nonexistent 2>/dev/null; test $? -eq 2 && echo PASS`
  - **Commit**: `feat(lint): finalize exit-code and RESULT contract`
  - _Requirements: FR-6, AC-5.1, AC-5.3_
  - _Design: Output Contract_

- [x] 1.14 [VERIFY] Quality checkpoint: full script vs real artifact
  - **Do**: Run script against `specs/requirements-process-improvements/requirements.md`; record findings (expected: possible C4/C8 WARNs, no crash); `bash -n` clean
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/lint-requirements.sh && bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh specs/requirements-process-improvements/requirements.md | grep -qE 'RESULT: (PASS|FAIL)' && echo PASS`
  - **Done when**: All 8 checks report; RESULT line well-formed
  - **Commit**: `chore(lint): pass quality checkpoint` (only if fixes needed)

- [x] 1.15 Template: add Problem Statement section
  - **Do**:
    1. In `plugins/ralph-specum/templates/requirements.md`, insert `## Problem Statement` BEFORE `## Goal`: one paragraph slot with `{{problem}}`, `{{affected user}}`, `{{evidence pointer to research.md}}` placeholders
    2. Add one instruction comment: quick mode with no research evidence → derive from goal + stated assumptions or `TBD (user, next review)`, never fabricate
  - **Files**: plugins/ralph-specum/templates/requirements.md
  - **Done when**: Problem Statement precedes Goal; placeholders present; no existing section renamed/removed
  - **Verify**: `awk '/^## Problem Statement/{p=NR} /^## Goal/{g=NR} END{exit !(p && g && p<g)}' plugins/ralph-specum/templates/requirements.md && echo PASS`
  - **Commit**: `feat(template): add Problem Statement section before Goal`
  - _Requirements: FR-9, AC-7.1, AC-7.2_
  - _Design: Component A_

- [x] 1.16 Template: GWT AC skeleton + MoSCoW/AC-ref FR table
  - **Do**:
    1. Replace AC placeholder lines with mandatory 3-clause form: `AC-1.1: Given {{context}}, When {{action}}, Then {{observable outcome}}` (all AC slots)
    2. FR table: Priority column example values → Must/Should/Could; Acceptance Criteria column → AC ID references (e.g., `AC-1.1, AC-2.3`), not free-text verification
    3. Keep Risks table Impact as High/Medium/Low (risk impact, not FR priority); keep all ID token formats (`US-N`, `FR-N`, `AC-N.N`, `NFR-N`) unchanged
  - **Files**: plugins/ralph-specum/templates/requirements.md
  - **Done when**: No High/Medium/Low remains in FR rows; AC skeleton shows all three clauses; Risks table untouched
  - **Verify**: `grep -q 'Given {{context}}, When {{action}}, Then {{observable outcome}}' plugins/ralph-specum/templates/requirements.md && ! grep -E '^\| FR-[0-9]' plugins/ralph-specum/templates/requirements.md | grep -qE 'High|Medium|Low' && grep -E '^\| FR-1 ' plugins/ralph-specum/templates/requirements.md | grep -qE 'Must|Should|Could' && echo PASS`
  - **Commit**: `feat(template): GWT AC skeleton, MoSCoW priorities, AC-ref FR column`
  - _Requirements: FR-1, AC-1.1, FR-3, AC-3.1, FR-10, AC-8.2, FR-4, AC-3.3_
  - _Design: Component A_

- [x] 1.17 Template: NFR fill-or-N/A rule + Out of Scope default-scope rule
  - **Do**:
    1. Above NFR table add instruction line: every row must have metric+target filled or Target `N/A: <reason>`; delete unused boilerplate rows
    2. Under `## Out of Scope` (heading KEPT verbatim) open body with: `Default-scope rule: anything not listed here that falls under the Goal is in scope.` followed by non-goal bullet slots
  - **Files**: plugins/ralph-specum/templates/requirements.md
  - **Done when**: Both rule lines present; `## Out of Scope` heading unchanged
  - **Verify**: `grep -q '^## Out of Scope' plugins/ralph-specum/templates/requirements.md && grep -q 'Default-scope rule' plugins/ralph-specum/templates/requirements.md && grep -q 'N/A: <reason>' plugins/ralph-specum/templates/requirements.md && echo PASS`
  - **Commit**: `feat(template): NFR fill-or-N/A rule and default-scope rule`
  - _Requirements: FR-12, AC-8.3, FR-8, AC-6.1_
  - _Design: Component A_

- [x] 1.18 [VERIFY] Quality checkpoint: template section-order and additive-only gates
  - **Do**: Grep-verify full section order (Problem Statement, Goal, User Stories, Functional Requirements, Non-Functional Requirements, Glossary, Out of Scope, Dependencies, Success Criteria, Risks) and that no pre-existing heading was renamed or dropped
  - **Verify**: `test "$(grep -c '^## ' plugins/ralph-specum/templates/requirements.md)" -ge 10 && grep -q '^## Problem Statement' plugins/ralph-specum/templates/requirements.md && grep -q '^## Out of Scope' plugins/ralph-specum/templates/requirements.md && grep -q '^## Success Criteria' plugins/ralph-specum/templates/requirements.md && echo PASS`
  - **Done when**: All 10 sections present in design order, additive-only confirmed
  - **Commit**: `chore(template): pass quality checkpoint` (only if fixes needed)

- [x] 1.19 POC Checkpoint: lint pipeline proven on real artifact
  - **Do**:
    1. Run `bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh specs/requirements-process-improvements/requirements.md`
    2. Triage findings: fix legitimate doc defects by touching up requirements.md (e.g., stray non-AC token in an FR row's AC column); fix script bugs where a finding violates the design contract (e.g., Risks table flagged by C3)
    3. Re-run until exit 0 (WARNs allowed — C4 quoted "gracefully" and C8 ratio WARN are expected/acceptable)
  - **Files**: specs/requirements-process-improvements/requirements.md, plugins/ralph-specum/hooks/scripts/lint-requirements.sh
  - **Done when**: Real template-conformant artifact passes the full 8-check gate with exit 0
  - **Verify**: `bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh specs/requirements-process-improvements/requirements.md && echo POC_PASS`
  - **Commit**: `feat(lint): complete POC - real artifact passes 8-check gate`
  - _Requirements: FR-6, AC-5.1; Success Criteria (0 FAIL on first/second pass)_
  - _Design: Implementation Steps 1-3, 8_

## Phase 2: Refactoring

Focus: integrate remaining components (agent/command/rubric edits) in lockstep; no lint-script behavior changes.

- [x] 2.1 product-manager: replace inline structure with template reference
  - **Do**:
    1. In `plugins/ralph-specum/agents/product-manager.md`, replace the "Requirements Structure" inline skeleton block (lines ~74-124) with: "Follow `${CLAUDE_PLUGIN_ROOT}/templates/requirements.md` exactly"
    2. Add one-line fallback section-ordering note (Problem Statement, Goal, User Stories, FRs, NFRs, Glossary, Out of Scope, Dependencies, Success Criteria, Risks) for the template-unreadable edge
  - **Files**: plugins/ralph-specum/agents/product-manager.md
  - **Done when**: Inline FR/NFR table skeleton gone; template ref + fallback note present
  - **Verify**: `grep -q 'templates/requirements.md' plugins/ralph-specum/agents/product-manager.md && ! grep -q 'High/Medium/Low' plugins/ralph-specum/agents/product-manager.md && echo PASS`
  - **Commit**: `refactor(pm): consolidate structure to template reference with fallback note`
  - _Requirements: FR-11, AC-8.1, FR-14_
  - _Design: Component B_

- [x] 2.2 product-manager: requirement-language rules + few-shot rewrites
  - **Do**:
    1. Add rules: FR statements phrased "System MUST ..." / "System SHOULD ..."; ACs mandatory Given/When/Then, all 3 clauses, observable outcomes not implementation
    2. Add 2 before/after few-shots: "handle errors gracefully" → "Given an invalid config path, When the command runs, Then it exits non-zero and prints the path in the error message"; "search should be fast" → "Given 10k indexed specs, When a search runs, Then results return in <2s or target is `TBD (owner, date)`"
  - **Files**: plugins/ralph-specum/agents/product-manager.md
  - **Done when**: Both rules and both few-shot pairs present
  - **Verify**: `grep -q 'System MUST' plugins/ralph-specum/agents/product-manager.md && test "$(grep -c 'Given ' plugins/ralph-specum/agents/product-manager.md)" -ge 2 && grep -q 'exits non-zero' plugins/ralph-specum/agents/product-manager.md && echo PASS`
  - **Commit**: `feat(pm): MUST/SHOULD language rules and GWT few-shot rewrites`
  - _Requirements: FR-1, AC-1.1, AC-1.2_
  - _Design: Component B_

- [x] 2.3 product-manager: six-scenario checklist + append-only ID rules
  - **Do**:
    1. Add per-story checklist: happy, empty/none, error, cancellation, permission, boundary; non-applicable scenarios get `N/A: <one-line reason>` under the story's ACs
    2. Add append-only ID rules: never renumber/reuse `US-N/FR-N/AC-N.N/NFR-N`; retire in place with `(retired)` mark
  - **Files**: plugins/ralph-specum/agents/product-manager.md
  - **Done when**: All six scenario names and the append-only/retire rules present
  - **Verify**: `grep -qi 'cancellation' plugins/ralph-specum/agents/product-manager.md && grep -qi 'boundary' plugins/ralph-specum/agents/product-manager.md && grep -qi 'append-only' plugins/ralph-specum/agents/product-manager.md && grep -q '(retired)' plugins/ralph-specum/agents/product-manager.md && echo PASS`
  - **Commit**: `feat(pm): six-scenario AC checklist and append-only ID discipline`
  - _Requirements: FR-2, AC-2.1, FR-3, AC-3.2_
  - _Design: Component B_

- [x] 2.4 [VERIFY] Quality checkpoint: product-manager edits coherent
  - **Do**: Grep-verify tasks 2.1-2.3 assertions together; confirm unchanged blocks intact (Explore usage, Append Learnings, awaitingApproval final step)
  - **Verify**: `grep -q 'awaitingApproval' plugins/ralph-specum/agents/product-manager.md && grep -q 'templates/requirements.md' plugins/ralph-specum/agents/product-manager.md && grep -qi 'six-scenario\|cancellation' plugins/ralph-specum/agents/product-manager.md && echo PASS`
  - **Done when**: All assertions pass; no unrelated section removed
  - **Commit**: `chore(pm): pass quality checkpoint` (only if fixes needed)

- [x] 2.5 product-manager: TBD discipline, quick-mode assumptions, checklist cuts
  - **Do**:
    1. Add TBD discipline: unknown specific → `TBD (owner, expected date)`, never invent; quick mode → state assumptions explicitly (Assumptions note or TBD markers) so generation never stalls
    2. Sweep prompt text to MoSCoW; delete any remaining High/Medium/Low FR-priority mentions
    3. Cut superseded Quality Checklist items now covered mechanically by the lint gate (priority presence, testable-AC phrasing) — net size stays lean
  - **Files**: plugins/ralph-specum/agents/product-manager.md
  - **Done when**: TBD rule + quick-mode rule present; zero High/Medium/Low; superseded checklist lines removed
  - **Verify**: `grep -q 'TBD (owner' plugins/ralph-specum/agents/product-manager.md && ! grep -q 'High/Medium/Low' plugins/ralph-specum/agents/product-manager.md && echo PASS`
  - **Commit**: `feat(pm): TBD-with-owner discipline and quick-mode assumption rules`
  - _Requirements: FR-5, AC-4.1, AC-4.2, FR-10, AC-8.2, FR-14, NFR-2_
  - _Design: Component B_

- [x] 2.6 spec-reviewer: lint script invocation + 8-check mapping
  - **Do**:
    1. In requirements rubric of `plugins/ralph-specum/agents/spec-reviewer.md`: when `artifactType: requirements` and `artifactPath` provided, run `bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/lint-requirements.sh <artifactPath>`
    2. Map each of the 8 checks (C1-C8, terse one-line definitions) into the findings table with PASS/WARN/FAIL status verbatim from script output
    3. Add degradation rule: exit 2 or command error → INFO finding, perform the 8 checks manually from the rubric definitions; warn-and-continue, never abort
  - **Files**: plugins/ralph-specum/agents/spec-reviewer.md
  - **Done when**: Rubric names the script, all 8 checks, and the manual-fallback rule; prose terse
  - **Verify**: `grep -q 'lint-requirements.sh' plugins/ralph-specum/agents/spec-reviewer.md && grep -q 'C8' plugins/ralph-specum/agents/spec-reviewer.md && grep -qi 'manual' plugins/ralph-specum/agents/spec-reviewer.md && echo PASS`
  - **Commit**: `feat(reviewer): hybrid gate - run lint script, map 8 checks into findings`
  - _Requirements: FR-6, AC-5.1_
  - _Design: Component D; Error Handling (script missing)_

- [x] 2.7 [VERIFY] Quality checkpoint: reviewer rubric integration
  - **Do**: `bash -n` unaffected scripts still clean; grep-verify 2.6 assertions; confirm reviewer signal contract lines (REVIEW_PASS/REVIEW_FAIL last-line rule) untouched
  - **Verify**: `grep -q 'REVIEW_PASS' plugins/ralph-specum/agents/spec-reviewer.md && grep -q 'lint-requirements.sh' plugins/ralph-specum/agents/spec-reviewer.md && echo PASS`
  - **Done when**: Rubric edit coherent, output contract intact
  - **Commit**: `chore(reviewer): pass quality checkpoint` (only if fixes needed)

- [x] 2.8 spec-reviewer: judgment dimensions + signal semantics
  - **Do**:
    1. Update judgment dimensions (not counted in the 8): Testability (observable-behavior language), Coverage adequacy (six-scenario N/A legitimacy; WARN for happy-path-only), Scope, Problem Statement quality (problem + user + evidence, not solution restatement), Traceability (FR↔US)
    2. Signal semantics: `REVIEW_FAIL` only when >=1 FAIL-class finding (mechanical or judgment); WARN-only → `REVIEW_PASS` with warnings listed; WARN never blocks
    3. Update rubric examples to GWT form; drop the `automatable (e.g., "grep -q X file.md")` testability example; confirm priority expectation stays Must/Should/Could
  - **Files**: plugins/ralph-specum/agents/spec-reviewer.md
  - **Done when**: FAIL-class-only blocking rule explicit; grep-q example gone; GWT examples in place
  - **Verify**: `grep -qi 'WARN never block' plugins/ralph-specum/agents/spec-reviewer.md && ! grep -q 'grep -q X file.md' plugins/ralph-specum/agents/spec-reviewer.md && grep -q 'Problem Statement' plugins/ralph-specum/agents/spec-reviewer.md && echo PASS`
  - **Commit**: `feat(reviewer): FAIL-class-only blocking and judgment dimensions`
  - _Requirements: FR-6, AC-5.3, AC-5.4, FR-2, AC-2.2, FR-5, FR-14_
  - _Design: Component D_

- [x] 2.9 commands/requirements: review in both modes + artifactPath
  - **Do**:
    1. In `plugins/ralph-specum/commands/requirements.md`, retitle Step 4 to `Artifact Review (both modes)`; remove the "If NOT --quick, skip to Step 5" bypass so review runs after generation in normal AND quick mode
    2. Review delegation gains `artifactPath: ./specs/$spec/requirements.md` alongside content; quick-mode loop semantics preserved verbatim (max 3 iterations, only REVIEW_FAIL re-generates, graceful degradation at 3, no-signal = PASS)
    3. Update product-manager delegation prompt: reference template structure; quick mode → state assumptions explicitly
  - **Files**: plugins/ralph-specum/commands/requirements.md
  - **Done when**: Step 4 runs in both modes with artifactPath; 3-iteration cap text intact
  - **Verify**: `grep -q 'Artifact Review (both modes)' plugins/ralph-specum/commands/requirements.md && grep -q 'artifactPath' plugins/ralph-specum/commands/requirements.md && grep -q 'Max 3 iterations' plugins/ralph-specum/commands/requirements.md && echo PASS`
  - **Commit**: `feat(cmd): auto-run artifact review in both modes with artifactPath`
  - _Requirements: FR-7, AC-5.2, AC-5.3, FR-5, AC-4.2, NFR-3_
  - _Design: Component E_

- [x] 2.10 [VERIFY] Quality checkpoint: command flow coherent
  - **Do**: Grep-verify 2.9 assertions; confirm Step numbering/checklist at top of commands/requirements.md updated consistently (no dangling "only if --quick" references to Step 4)
  - **Verify**: `! grep -q 'Artifact review.*only if.*quick' plugins/ralph-specum/commands/requirements.md && grep -q 'artifactPath' plugins/ralph-specum/commands/requirements.md && echo PASS`
  - **Done when**: No stale quick-only review references remain
  - **Commit**: `chore(cmd): pass quality checkpoint` (only if fixes needed)

- [x] 2.11 commands/requirements: walkthrough validation block + regeneration re-run
  - **Do**:
    1. Step 5 walkthrough gains a "Validation" block: 8-check statuses + judgment findings from the review pass; user approval flow unchanged; "Run review" option kept
    2. On "Request changes" regeneration: re-run review after the product-manager revision, then re-display walkthrough (review re-runs after EVERY regeneration)
  - **Files**: plugins/ralph-specum/commands/requirements.md
  - **Done when**: Validation block documented in walkthrough; regeneration→re-review rule explicit
  - **Verify**: `grep -qi 'Validation' plugins/ralph-specum/commands/requirements.md && grep -q 'Run review' plugins/ralph-specum/commands/requirements.md && grep -qiE 're-run|rerun' plugins/ralph-specum/commands/requirements.md && echo PASS`
  - **Commit**: `feat(cmd): walkthrough validation block and per-regeneration re-review`
  - _Requirements: FR-7, AC-5.2_
  - _Design: Component E; Technical Decisions (review cadence)_

- [x] 2.12 refactor-specialist: lockstep section list
  - **Do**:
    1. In `plugins/ralph-specum/agents/refactor-specialist.md` requirements review order: add "Problem Statement" as item 1 (before Goal), renumbering the ordered list
    2. Annotate the "Out of Scope" entry with non-goal/default-scope semantics; no removals or renames
  - **Files**: plugins/ralph-specum/agents/refactor-specialist.md
  - **Done when**: List starts with Problem Statement; Out of Scope entry annotated
  - **Verify**: `grep -q 'Problem Statement' plugins/ralph-specum/agents/refactor-specialist.md && grep -q 'Out of Scope' plugins/ralph-specum/agents/refactor-specialist.md && echo PASS`
  - **Commit**: `feat(refactor-agent): add Problem Statement to requirements section list`
  - _Requirements: FR-8, AC-6.2, NFR-1_
  - _Design: Component F_

- [x] 2.13 [VERIFY] Quality checkpoint: cross-file grep gates + leanness advisory
  - **Do**:
    1. Gate: zero High/Medium/Low in FR-priority contexts across template/agent/rubric; "Problem Statement" in template + refactor-specialist; product-manager has no inline FR-table skeleton
    2. NFR-2 advisory: report net line delta for product-manager.md + templates/requirements.md via `git diff main --stat -- plugins/ralph-specum/agents/product-manager.md plugins/ralph-specum/templates/requirements.md`; log to .progress.md Learnings
  - **Verify**: `! grep -E '^\| FR-[0-9]' plugins/ralph-specum/templates/requirements.md | grep -qE 'High|Medium|Low' && ! grep -q 'High/Medium/Low' plugins/ralph-specum/agents/product-manager.md && grep -q 'Problem Statement' plugins/ralph-specum/agents/refactor-specialist.md && grep -q 'Must/Should/Could' plugins/ralph-specum/agents/spec-reviewer.md && echo PASS`
  - **Done when**: All grep gates green; line delta recorded
  - **Commit**: `chore(requirements-phase): pass cross-file consistency gates` (only if fixes needed)
  - _Requirements: FR-10, AC-8.2, NFR-2_
  - _Design: Test Strategy (Integration)_

## Phase 3: Testing

Focus: `test-lint-requirements.sh` fixture coverage — pass + fail case for every one of the 8 checks, plus exit-code contract.

- [x] 3.1 Scaffold test harness + clean fixture
  - **Do**:
    1. Create `plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh` following `test-path-resolver.sh` conventions: `set -e` at top level, `mktemp -d` setup/cleanup trap, `assert_eq`/`assert_contains` helpers, PASS/FAIL counters, colored output, non-zero exit on any failure
    2. Add heredoc clean fixture (template-conformant mini doc: Problem Statement, 1 story with GWT ACs incl. one error-path AC, MoSCoW FR table with AC refs, NFR with `N/A: reason`, owned TBD)
    3. Assert: exit 0 AND output contains 8 `CHECK|Cn|PASS` lines AND `RESULT: PASS`
    4. `chmod +x`
  - **Files**: plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh
  - **Done when**: Harness runs green with the clean-fixture case
  - **Verify**: `bash plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh && echo PASS`
  - **Commit**: `test(lint): harness scaffold with clean-fixture 8-PASS case`
  - _Requirements: FR-6, AC-5.1_
  - _Design: Test Strategy (Unit); Existing Patterns_

- [x] 3.2 C1 fixtures: duplicate ID + dangling AC ref
  - **Do**:
    1. Fixture: duplicate `FR-1` rows → assert `FAIL|C1` finding, exit 1
    2. Fixture: FR row referencing undefined `AC-9.9` → assert `FAIL|C1`, exit 1
    3. Fixture: `FR-2 (retired)` referenced elsewhere → assert NO C1 FAIL (retired IDs are valid targets)
  - **Files**: plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh
  - **Done when**: Three C1 cases pass in harness
  - **Verify**: `bash plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh && echo PASS`
  - **Commit**: `test(lint): C1 duplicate-ID, dangling-ref, retired-ID cases`
  - _Requirements: FR-6, AC-5.1, FR-4, AC-3.3, AC-3.2_
  - _Design: C1; Edge Cases (retired rows)_

- [x] 3.3 C2 fixtures: missing clause + multi-line AC
  - **Do**:
    1. Fixture: AC missing `Then` → assert `FAIL|C2` names the AC ID, exit 1
    2. Fixture: AC with Given/When/Then spread across joined continuation lines → assert C2 PASS
  - **Files**: plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh
  - **Done when**: Both C2 cases pass in harness
  - **Verify**: `bash plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh && echo PASS`
  - **Commit**: `test(lint): C2 missing-clause fail and multi-line pass cases`
  - _Requirements: FR-1, AC-1.3_
  - _Design: C2; Edge Cases (multi-line AC)_

- [x] 3.4 [VERIFY] Quality checkpoint: harness + existing script tests
  - **Do**: Run `test-lint-requirements.sh` AND `test-path-resolver.sh` (regression guard); `bash -n` both new scripts
  - **Verify**: `bash plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh && bash plugins/ralph-specum/hooks/scripts/test-path-resolver.sh && echo PASS`
  - **Done when**: Both suites green
  - **Commit**: `chore(lint): pass quality checkpoint` (only if fixes needed)

- [x] 3.5 C3 fixtures: High priority fails, Risks table exempt
  - **Do**:
    1. Fixture: FR row with `High` priority → assert `FAIL|C3`, exit 1
    2. Fixture: MoSCoW FR table + Risks table containing `High` Impact → assert NO C3 finding (scope check)
  - **Files**: plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh
  - **Done when**: Both C3 cases pass
  - **Verify**: `bash plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh && echo PASS`
  - **Commit**: `test(lint): C3 non-MoSCoW fail and Risks-table exemption cases`
  - _Requirements: FR-10, AC-5.4, AC-8.2_
  - _Design: C3_

- [x] 3.6 C4 fixtures: missing modal fails, banned term warns
  - **Do**:
    1. Fixture: FR statement without MUST/SHOULD → assert `FAIL|C4`, exit 1
    2. Fixture: AC containing "gracefully" (otherwise clean) → assert `WARN|C4` AND exit 0 (banned-term is WARN-within-check)
  - **Files**: plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh
  - **Done when**: Both C4 cases pass
  - **Verify**: `bash plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh && echo PASS`
  - **Commit**: `test(lint): C4 modal fail and banned-term warn cases`
  - _Requirements: FR-1, AC-1.1, AC-5.1_
  - _Design: C4_

- [x] 3.7 C5 fixtures: placeholder/bare-N/A fail, reasoned N/A passes
  - **Do**:
    1. Fixture: NFR row with `{{metric}}` placeholder → assert `FAIL|C5`, exit 1
    2. Fixture: NFR Target bare `N/A` → assert `FAIL|C5`, exit 1
    3. Fixture: NFR Target `N/A: markdown-only change` → assert C5 PASS
  - **Files**: plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh
  - **Done when**: Three C5 cases pass
  - **Verify**: `bash plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh && echo PASS`
  - **Commit**: `test(lint): C5 fill-or-N/A cases`
  - _Requirements: FR-12, AC-8.3_
  - _Design: C5; Edge Cases (N/A NFR rows)_

- [x] 3.8 [VERIFY] Quality checkpoint: FAIL-class coverage complete
  - **Do**: Run harness; confirm C1-C5 each has >=1 fail-case and >=1 pass-path assertion (grep harness source for case names)
  - **Verify**: `bash plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh && for c in C1 C2 C3 C4 C5; do grep -q "$c" plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh || exit 1; done && echo PASS`
  - **Done when**: Harness green, all 5 FAIL-class checks covered
  - **Commit**: `chore(lint): pass quality checkpoint` (only if fixes needed)

- [x] 3.9 C6 fixtures: happy-path-only warns, N/A marking passes
  - **Do**:
    1. Fixture: story with only happy-path ACs, no N/A lines → assert `WARN|C6` AND exit 0
    2. Fixture: happy-path story with explicit `N/A: no error path — read-only lookup` scenario line → assert C6 PASS
  - **Files**: plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh
  - **Done when**: Both C6 cases pass; WARN does not flip exit code
  - **Verify**: `bash plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh && echo PASS`
  - **Commit**: `test(lint): C6 coverage-proxy warn and N/A pass cases`
  - _Requirements: FR-2, AC-2.2_
  - _Design: C6_

- [x] 3.10 C7 fixtures: unowned TBD warns, owned TBD passes
  - **Do**:
    1. Fixture: bare `TBD` + ownerless Unresolved Questions bullet → assert two `WARN|C7` findings, exit 0
    2. Fixture: `TBD (alice, 2026-08-01)` + question bullet with `Owner:` → assert C7 PASS
  - **Files**: plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh
  - **Done when**: Both C7 cases pass
  - **Verify**: `bash plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh && echo PASS`
  - **Commit**: `test(lint): C7 unowned-TBD warn and owned pass cases`
  - _Requirements: FR-5, AC-4.3_
  - _Design: C7_

- [x] 3.11 C8 fixtures: ratio warn + small-N suppression
  - **Do**:
    1. Fixture: 10 FRs all Must → assert `WARN|C8`, exit 0
    2. Fixture: 5 FRs all Must → assert `CHECK|C8|PASS` (suppressed below 8 FRs)
  - **Files**: plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh
  - **Done when**: Both C8 cases pass
  - **Verify**: `bash plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh && echo PASS`
  - **Commit**: `test(lint): C8 ratio-warn and small-spec suppression cases`
  - _Requirements: FR-6, AC-5.1_
  - _Design: C8; Edge Cases (tiny specs)_

- [x] 3.12 [VERIFY] Quality checkpoint: WARN-class coverage complete
  - **Do**: Run harness; confirm C6-C8 covered with warn + pass cases and that every WARN case asserts exit 0
  - **Verify**: `bash plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh && for c in C6 C7 C8; do grep -q "$c" plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh || exit 1; done && echo PASS`
  - **Done when**: Harness green, all 8 checks fixture-covered
  - **Commit**: `chore(lint): pass quality checkpoint` (only if fixes needed)

- [x] 3.13 Exit-code contract cases
  - **Do**:
    1. Case: missing file path → assert exit 2
    2. Case: no argument → assert exit 2
    3. Case: WARN-only fixture → assert exit 0 AND `RESULT:` line reports the WARN count
    4. Case: any-FAIL fixture → assert exit 1 AND `RESULT: FAIL`
  - **Files**: plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh
  - **Done when**: All four exit-path cases pass
  - **Verify**: `bash plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh && echo PASS`
  - **Commit**: `test(lint): exit-code contract cases (0/1/2)`
  - _Requirements: FR-6, AC-5.3, NFR-3_
  - _Design: Output Contract_

- [x] 3.14 [VERIFY] Quality checkpoint: full test suite + real-artifact integration
  - **Do**: Run full harness; run `test-path-resolver.sh` and `test-multi-dir-integration.sh` (regression); run lint against real `specs/requirements-process-improvements/requirements.md` expecting exit 0
  - **Verify**: `bash plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh && bash plugins/ralph-specum/hooks/scripts/test-path-resolver.sh && bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh specs/requirements-process-improvements/requirements.md && echo PASS`
  - **Done when**: All suites green, real artifact still exit 0
  - **Commit**: `chore(lint): pass full test checkpoint` (only if fixes needed)

## Phase 4: Quality Gates

> Feature branch is already set at startup. NEVER push to main. PR is the deliverable.

- [x] 4.1 Version bump 4.9.1 → 4.10.0 in both manifests
  - **Do**:
    1. `plugins/ralph-specum/.claude-plugin/plugin.json`: version `4.9.1` → `4.10.0`
    2. `.claude-plugin/marketplace.json`: ralph-specum entry `4.9.1` → `4.10.0` (only the ralph-specum entry; touch nothing else)
  - **Files**: plugins/ralph-specum/.claude-plugin/plugin.json, .claude-plugin/marketplace.json
  - **Done when**: Both files report 4.10.0 for ralph-specum; valid JSON
  - **Verify**: `grep -q '"version": "4.10.0"' plugins/ralph-specum/.claude-plugin/plugin.json && grep -q '4.10.0' .claude-plugin/marketplace.json && python3 -m json.tool plugins/ralph-specum/.claude-plugin/plugin.json > /dev/null && python3 -m json.tool .claude-plugin/marketplace.json > /dev/null && echo PASS`
  - **Commit**: `chore(release): bump ralph-specum to 4.10.0`
  - _Requirements: FR-13, AC-8.4_
  - _Design: Component G_

- [x] 4.2 [VERIFY] V4 Full local CI: scripts + tests + lint + grep gates
  - **Do**:
    1. `bash -n` both new scripts; run `test-lint-requirements.sh`, `test-path-resolver.sh`, `test-multi-dir-integration.sh`
    2. Lint real requirements.md (exit 0); re-run Phase 2.13 cross-file grep gates
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/lint-requirements.sh && bash plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh && bash plugins/ralph-specum/hooks/scripts/test-path-resolver.sh && bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh specs/requirements-process-improvements/requirements.md && ! grep -q 'High/Medium/Low' plugins/ralph-specum/agents/product-manager.md && echo PASS`
  - **Done when**: Everything green locally
  - **Commit**: `chore(requirements-phase): pass local CI` (only if fixes needed)

- [ ] 4.3 Create PR and verify CI
  - **Do**:
    1. Confirm feature branch: `git branch --show-current` (if on main/master, STOP and alert user)
    2. Push: `git push -u origin $(git branch --show-current)`
    3. `gh pr create --title "feat(requirements-phase): hybrid 8-check validation gate and template restructure" --body` summarizing components A-G + test plan
    4. Watch CI: `gh pr checks --watch`; on failure read `gh run view --log-failed`, fix, push, re-watch
  - **Done when**: PR created, all CI checks green
  - **Verify**: `gh pr checks | grep -qv fail && gh pr view --json url --jq .url`
  - **Commit**: None (fix commits only if CI fails)
  - _Requirements: AC-8.4_

- [ ] V5 [VERIFY] CI pipeline passes
  - **Do**: Re-poll CI after any late pushes
  - **Verify**: `gh pr checks` shows all green
  - **Done when**: CI pipeline fully passing
  - **Commit**: None

- [ ] V6 [VERIFY] AC checklist sweep
  - **Do**: For each AC in requirements.md (AC-1.1 … AC-8.4), verify programmatically: grep the edited file for the mandated text (AC-1.1/1.2, 2.1, 3.1/3.2, 4.1/4.2, 5.2, 6.1/6.2, 7.1/7.2, 8.1/8.2/8.4); run harness cases for lint-backed ACs (1.3, 2.2, 3.3, 4.3, 5.1, 5.3, 5.4, 8.3); record per-AC status in .progress.md
  - **Verify**: `bash plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh && grep -q 'Default-scope rule' plugins/ralph-specum/templates/requirements.md && grep -q 'artifactPath' plugins/ralph-specum/commands/requirements.md && grep -q 'Problem Statement' plugins/ralph-specum/agents/refactor-specialist.md && echo PASS`
  - **Done when**: All 22 ACs confirmed via automated checks; failures fixed before proceeding
  - **Commit**: None
  - _Requirements: all FR/AC_

- [ ] VE1 [VERIFY] E2E scripted: toy template-conformant doc passes gate
  - **Do**:
    1. `mkdir -p /tmp/ve-lint-fixtures`; heredoc a toy requirements doc at `/tmp/ve-lint-fixtures/clean.md` following the UPDATED template rules (Problem Statement before Goal, GWT ACs with an error-path AC, MoSCoW FR table with AC-ID refs, NFR `N/A: reason` row, Out of Scope with default-scope rule, owned TBD)
    2. Run `bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh /tmp/ve-lint-fixtures/clean.md`
  - **Verify**: `bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh /tmp/ve-lint-fixtures/clean.md | grep -q 'RESULT: PASS' && echo VE1_PASS`
  - **Done when**: Exit 0, 8 checks PASS — template rules and lint contract agree end-to-end
  - **Commit**: None
  - _Requirements: FR-6, AC-5.1; Success Criteria (first-pass 0 FAIL)_

- [ ] VE2 [VERIFY] E2E scripted: verdict logic (FAIL→1, WARN-only→0, usage→2)
  - **Do**:
    1. Copy clean.md → `fail.md`, strip a `Then` clause; run lint → assert exit 1 + `FAIL|C2` + `RESULT: FAIL`
    2. Copy clean.md → `warn.md`, add a bare `TBD`; run lint → assert exit 0 + `WARN|C7` present in output
    3. Run lint with no args and with `/tmp/ve-lint-fixtures/nope.md` → assert exit 2 both times
  - **Verify**: `bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh /tmp/ve-lint-fixtures/fail.md; test $? -eq 1 && bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh /tmp/ve-lint-fixtures/warn.md; test $? -eq 0 && bash plugins/ralph-specum/hooks/scripts/lint-requirements.sh /tmp/ve-lint-fixtures/nope.md 2>/dev/null; test $? -eq 2 && echo VE2_PASS`
  - **Done when**: All three verdict classes reproduce the AC-5.3 blocking semantics
  - **Commit**: None
  - _Requirements: FR-6, AC-5.3, NFR-3_

- [ ] VE3 [VERIFY] E2E cleanup: remove toy fixtures
  - **Do**: `rm -rf /tmp/ve-lint-fixtures`
  - **Verify**: `! test -d /tmp/ve-lint-fixtures && echo VE3_PASS`
  - **Done when**: No E2E artifacts remain (no dev server involved — CLI/markdown plugin)
  - **Commit**: None

## Phase 5: PR Lifecycle (Continuous Validation)

> Autonomous loop until ALL completion criteria met. PR was created in 4.3.

- [ ] 5.1 Monitor CI and fix failures
  - **Do**:
    1. `gh pr checks`; on failure `gh run view --log-failed`, fix locally, commit `fix(requirements-phase): address CI failures`, push
    2. Repeat until all green
  - **Verify**: `gh pr checks` shows all ✓
  - **Done when**: All CI checks passing
  - **Commit**: `fix(requirements-phase): address CI failures` (as needed)

- [ ] 5.2 Address code review comments
  - **Do**:
    1. `gh pr view --json reviews` + `gh api repos/{owner}/{repo}/pulls/{number}/comments` for inline threads
    2. Implement each requested change, commit `fix(requirements-phase): address review - <summary>`, push; re-check until none unresolved
  - **Verify**: `gh pr view --json reviews` shows no CHANGES_REQUESTED or PENDING
  - **Done when**: All review comments resolved
  - **Commit**: `fix(requirements-phase): address review - <summary>` (per comment)

- [ ] 5.3 Final validation
  - **Do**:
    1. Re-run full local suite (4.2 Verify command)
    2. Confirm CI green (`gh pr checks`), zero regressions in existing script tests, completion criteria documented in .progress.md
  - **Verify**: `bash plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh && bash plugins/ralph-specum/hooks/scripts/test-path-resolver.sh && gh pr checks && echo PASS`
  - **Done when**: All completion criteria met
  - **Commit**: None

## Notes

- **POC shortcuts taken**: none material — lint checks land incrementally with inline /tmp smoke fixtures (cleaned in 1.13); formal fixtures arrive in Phase 3.
- **Production TODOs**: none; live-agent phase runs (normal + quick `/ralph-specum:requirements`) intentionally excluded per tasks interview (scripted E2E only).
- **No [P] markers**: nearly every task chain shares a single file (lint script, then each markdown file in turn); remaining candidates are adjacent to overlapping tasks, so parallel groups would violate the zero-file-overlap rule. Sequential is deliberate.
- **Manual E2E from design Test Strategy** (live phase runs, downstream design run) is deferred to post-merge dogfooding — not automatable in this spec without creating new spec dirs (forbidden).

## Dependencies

```
Phase 1 (POC: lint script + template) → Phase 2 (agent/command/rubric integration) → Phase 3 (fixture tests) → Phase 4 (version bump, gates, PR, scripted E2E) → Phase 5 (PR lifecycle)
```
