# Engine Roadmap Epic — Research

> **Date**: 2026-04-25
> **Source**: ENGINE_ROADMAP.md Section 6 (Specs 3-7), full codebase audit
> **Specs excluded**: Spec 1 (merged, PR #12), Spec 2 (cancelled by user)

---

## 1. Spec 1 Completion Verification

**Verdict: CONFIRMED COMPLETE** — PR #12 merged to main (commit `c20e962`). All 5 changes verified against real files.

| Spec 1 Change | File | Verified? |
|---|---|---|
| Unified 5-layer verification | `references/verification-layers.md` has all 5 layers (0-4). `implement.md` line 235 says "5 layers". `coordinator-pattern.md` line 618 references this file as canonical source. | YES |
| Mechanical HOLD check | `implement.md` lines 249-255: `grep -c '^\[HOLD\]$\|^\[PENDING\]$\|^\[URGENT\]$'` before delegation. Exit code > 0 blocks delegation. Resolved signals marked `[RESOLVED]` (not matched by grep). | YES |
| State integrity validation | `implement.md` lines 135-156: Pre-loop check comparing `[x]` count vs `taskIndex`. Corrects drift, logs to `.progress.md`. | YES |
| Schema update | `schemas/spec.schema.json` lines 194-229: `nativeTaskMap`, `nativeSyncEnabled`, `nativeSyncFailureCount`, `chat.executor.lastReadLine` all present. | YES |
| CI snapshot separation (conceptual) | `implement.md` line 263: Rule that task Verify and global CI must be reported separately. Deferred CI command discovery noted for Spec 4. | YES |

---

## 2. Codebase Landscape

### Directory Structure

All engine files live under `plugins/ralph-specum/`:

| Directory | Purpose | Key Files |
|---|---|---|
| `agents/` | 10 agent definitions (subagent prompts) | spec-executor.md, external-reviewer.md, qa-engineer.md, spec-reviewer.md, etc. |
| `references/` | 16 reference docs loaded by coordinator | coordinator-pattern.md (1024 lines), failure-recovery.md (545 lines), verification-layers.md, etc. |
| `commands/` | Slash command definitions | implement.md (entry point for execution loop) |
| `hooks/` | Stop hook + utility scripts | stop-watcher.sh (666 lines) |
| `schemas/` | JSON schema for .ralph-state.json | spec.schema.json |
| `templates/` | Spec file templates | chat.md, tasks.md, requirements.md, task_review.md |

### Existing Reference Files (Relevant to Specs 3-7)

| File | Lines | Specs That Modify It | Notes |
|---|---|---|---|
| `references/coordinator-pattern.md` | 1024 | Spec 7 (pair-debug announcement) | Large, monolithic. Spec 2 would have split it (but is cancelled). |
| `references/failure-recovery.md` | 545 | Spec 6 (extend fix task trigger), Spec 7 (extend pair-debug) | Shared by both specs. Must be careful about order. |
| `references/verification-layers.md` | 236 | None (Spec 1 already done) | Unified 5-layer source. Spec 1 Line 62 notes CI command discovery deferred to Spec 4. |
| `agents/spec-executor.md` | 374 | Spec 3 (file restrictions), Spec 6 (collab rules), Spec 7 (debug logging) | Three specs modify this. High conflict risk. |
| `agents/external-reviewer.md` | 701 | Spec 3 (file restrictions), Spec 6 (baseline rule, collab rules) | Two specs modify this. Moderate conflict risk. |
| `commands/implement.md` | 314 | None (Specs 2, 4 would modify but 2 is cancelled) | Contains state integrity check, HOLD check, CI separation rule. |
| `templates/chat.md` | 62 | Spec 6 (add collaboration signals) | Signal legend at top. New signals: HYPOTHESIS, EXPERIMENT, FINDING, ROOT_CAUSE, FIX_PROPOSAL, BUG_DISCOVERY. |
| `hooks/scripts/stop-watcher.sh` | 666 | Spec 4 (circuit breaker, state integrity) | Already has: repair loop, regression sweep, state validation, completion verification. |

### Files Spec 3-7 Would Create (All New)

| File | Spec | Purpose |
|---|---|---|
| `references/role-contracts.md` | 3 | Who can read/write which files |
| `references/loop-safety.md` | 4 | Git checkpoint, circuit breaker, metrics, read-only detection |
| `hooks/scripts/checkpoint.sh` | 4 | Git checkpoint utilities |
| `plugins/ralph-bmad-bridge/` | 5 | New plugin directory |
| `references/collaboration-resolution.md` | 6 | Cross-branch regression workflow, experiment pattern |
| `references/pair-debug.md` | 7 | Auto-trigger condition, Driver/Navigator roles |

All new files are in different paths from each other. No conflicts between new files.

---

## 3. Dependency Analysis

### Explicit Dependencies (from ROADMAP.md Section 9)

The roadmap states: "Sequential only: Each spec depends on the previous. Do not skip or parallelize."

### File-Level Dependencies

```
Spec 3 (role-boundaries)
  ├── Modifies: agents/*.md (4 files)
  ├── Creates: references/role-contracts.md
  └── No file conflicts with Spec 5

Spec 5 (bmad-bridge-plugin)
  ├── Creates: plugins/ralph-bmad-bridge/ (entirely new directory)
  └── No file conflicts with any other spec

Spec 4 (loop-safety-infra)
  ├── Modifies: hooks/scripts/stop-watcher.sh, schemas/spec.schema.json (adds ciCommands)
  ├── Creates: references/loop-safety.md, hooks/scripts/checkpoint.sh
  └── Reads from: schemas/spec.schema.json (nativeTaskMap, nativeSync fields from Spec 1)

Spec 6 (collaboration-resolution)
  ├── Modifies: references/failure-recovery.md, templates/chat.md
  ├── Modifies: agents/external-reviewer.md, agents/spec-executor.md
  ├── Creates: references/collaboration-resolution.md
  └── Reads from: references/failure-recovery.md (Spec 7 also modifies this)

Spec 7 (pair-debug-auto-trigger)
  ├── Modifies: references/failure-recovery.md, agents/spec-executor.md, references/coordinator-pattern.md
  ├── Creates: references/pair-debug.md
  └── Depends on: Spec 6's changes to failure-recovery.md (BUG_DISCOVERY → fix task flow)
```

### Hidden Dependencies

**None discovered.** The specs were carefully designed to have minimal overlap. The only shared modification files are:

1. `agents/spec-executor.md` — modified by Specs 3, 6, and 7 (different sections)
2. `agents/external-reviewer.md` — modified by Specs 3 and 6 (different sections)
3. `references/failure-recovery.md` — modified by Specs 6 and 7 (different sections)

These overlaps are manageable because:
- Each spec adds to different sections of the same files
- Spec 7's pair-debug builds on Spec 6's BUG_DISCOVERY pattern (logical dependency, not file conflict)

### Schema Dependencies

Spec 4 references schema fields added in Spec 1:
- `nativeTaskMap`, `nativeSyncEnabled`, `nativeSyncFailureCount` — confirmed present in schema
- Spec 4 adds `ciCommands: string[]` — NEW field for Spec 4

**Note**: Spec 2 (cancelled) would have created `coordinator-core.md`. Spec 7's target file is listed as `coordinator-pattern.md` (or `coordinator-core.md` after Spec 2). Since Spec 2 is cancelled, Spec 7 modifies `coordinator-pattern.md` directly.

---

## 4. Constraint Discovery

### Constraint 1: Existing Safety Infrastructure in stop-watcher.sh

The stop-watcher.sh already has extensive safety infrastructure:
- Repair loop (VERIFICATION_FAIL → repair, max 2 iterations)
- Regression sweep (post-completion dependency verification)
- State validation (corrupt state detection, task completion cross-check)
- Global iteration limit enforcement
- Quick mode guard
- Parallel task handling

**Implication for Spec 4**: The circuit breaker, metrics, and read-only detection should be added to stop-watcher.sh, but the existing safety mechanisms mean some of what Spec 4 would add already exists in different form. Spec 4 should not duplicate existing mechanisms.

### Constraint 2: Agent Files Are Large and Sensitive

- `agents/external-reviewer.md` is 701 lines with detailed protocols
- `agents/spec-executor.md` is 374 lines with complex delegation logic
- These agents are loaded by Claude Code as system prompts — changes must be surgical

**Implication for Specs 3, 6, 7**: Each spec that modifies agent files must add clearly sectioned content with frontmatter annotations so future specs can find and modify the right sections.

### Constraint 3: Chat Template Signal Legend

`templates/chat.md` has a signal legend table (lines 1-20). New signals from Spec 6 must be added to this table. Spec 7 adds the `PAIR-DEBUG` concept but does NOT add new chat signals — it uses the collaboration signals from Spec 6 plus the existing signal mechanism.

**Implication**: Spec 6 MUST come before Spec 7 if they share signal definitions. Spec 7 references Spec 6's signals.

### Constraint 4: failure-recovery.md Is the Shared Anchor

`references/failure-recovery.md` (545 lines) is the single file that both Spec 6 and Spec 7 modify:
- Spec 6 extends it to support BUG_DISCOVERY → fix task trigger
- Spec 7 extends it to announce pair-debug mode before fix task

These are additive changes in different sections but the same file.

**Implication**: Spec 6 should complete before Spec 7, or they must be carefully coordinated to avoid merge conflicts. The roadmap's sequential order handles this.

### Constraint 5: No Spec 2, No coordinator-core.md

Spec 2 would have split `coordinator-pattern.md` into modular references. Since it's cancelled:
- All specs that reference `coordinator-core.md` must use `coordinator-pattern.md` instead
- The file remains 1024 lines, which is the I1 (prompt bloat) problem Spec 2 would have solved
- This is a known, accepted trade-off since the user cancelled Spec 2

---

## 5. Seam Identification

### Natural Boundaries

| Spec | Seam | Independence |
|---|---|---|
| 3 | Role contracts + agent file restrictions | HIGH — adds new reference file, adds sections to agent files. No spec reads role-contracts.md during execution (coordinator loads references, but role-contracts.md would be loaded on agent invocation, not coordinator). |
| 4 | Safety infra + CI tracking | HIGH — new files, modifies stop-watcher.sh (hook layer, not agent layer). No other spec depends on these new files. |
| 5 | New plugin — BMAD bridge | COMPLETELY INDEPENDENT — entirely new directory, no shared files with any other spec. |
| 6 | Collaboration protocol + chat signals | MEDIUM — shares agent files with Specs 3, 7. Shares failure-recovery.md with Spec 7. But creates a new reference file (collaboration-resolution.md) that is self-contained. |
| 7 | Pair-debug mode | MEDIUM — depends on Spec 6's signals and BUG_DISCOVERY pattern. Shares agent files with Specs 3, 6. |

### Parallelization Assessment

The roadmap says "sequential only," but here's the reality:

**Can Spec 3 run in parallel with Spec 5?** Yes. Different files entirely.
**Can Spec 4 run independently?** Yes. New files, different modification targets.
**Can Spec 6 run after Spec 3?** Yes. Spec 3 adds file restrictions to agent files; Spec 6 adds collaboration rules to the same files in different sections.
**Can Spec 7 run before Spec 6?** No. Spec 7 references Spec 6's collaboration signals (HYPOTHESIS, EXPERIMENT, etc.).

**Optimal order**: 3 → 4 → 5 → 6 → 7 (as roadmap specifies)

**Alternative (if parallelization desired)**: (3 + 5) → 4 → 6 → 7

But the sequential order is cleaner and avoids any risk of merge conflicts on shared agent files.

---

## 6. Risk Assessment

### High Risk

| Spec | Risk | Mitigation |
|---|---|---|
| 3 | Agent file modifications (4 files) could conflict with future Spec 6/7 changes | Use clearly sectioned additions with frontmatter markers |
| 4 | stop-watcher.sh is 666 lines and has complex existing logic | Add new features as functions at the end, don't modify existing logic |
| 7 | Modifies coordinator-pattern.md (1024 lines) — largest reference file | Surgical additions only, new reference file pair-debug.md |

### Medium Risk

| Spec | Risk | Mitigation |
|---|---|---|
| 6 | Two specs (6 and 7) modify failure-recovery.md | Spec 7 should read Spec 6's changes first |
| 6 | Modifies templates/chat.md signal legend | Well-defined addition point (table rows) |

### Low Risk

| Spec | Risk | Mitigation |
|---|---|---|
| 5 | New plugin — no shared files | Self-contained, no conflicts possible |
| 4 | New files in references/ and hooks/scripts/ | All new, no conflicts |

---

## 7. Schema Impact

Spec 4 adds `ciCommands: string[]` to the state schema. This is a simple addition:

```json
"ciCommands": {
  "type": "array",
  "items": { "type": "string" },
  "description": "Discovered CI commands for this spec (from Verification Contract or project config)"
}
```

All other schema fields referenced by specs 3-7 are already present (from Spec 1).

---

## 8. Summary of Findings

1. **Spec 1 is fully complete and merged.** All 5 changes verified against real code.
2. **No hidden dependencies between Specs 3-7.** The roadmap's sequential order is driven by logical dependencies (Spec 7 builds on Spec 6's signals), not file conflicts.
3. **Three shared files** across Specs 3-7: `agents/spec-executor.md` (3 specs), `agents/external-reviewer.md` (2 specs), `references/failure-recovery.md` (2 specs). All modifications are additive (new sections), not overlapping edits.
4. **All new files are in unique paths.** No conflicts between new file creation.
5. **Spec 5 is completely independent.** New plugin directory, no file overlap with any other spec.
6. **stop-watcher.sh already has safety infrastructure** (repair loop, regression sweep, state validation). Spec 4's circuit breaker, metrics, and read-only detection fit naturally as additions.
7. **Spec 7 depends on Spec 6** because it uses Spec 6's collaboration signals (HYPOTHESIS, EXPERIMENT, etc.) and builds on the BUG_DISCOVERY pattern.
8. **The cancelled Spec 2 has no blocking impact.** coordinator-core.md doesn't exist; specs reference coordinator-pattern.md directly.

---

## 9. Validation Findings (Codebase Audit)

### Per-Spec Validation

| Spec | Can build independently? | Dependencies correct? | Interface contracts accurate? | Scope appropriate? | Issues |
|------|--------------------------|----------------------|------------------------------|-------------------|--------|
| 3: role-boundaries | YES | YES (no deps) | YES | YES | None. Confirmed: NONE of the 4 agent files currently have role restrictions, file access matrices, or "DO NOT edit" lists. The only "DO NOT" patterns are about verification proceeding, not file access. Spec 3 creates entirely new content. |
| 4: loop-safety-infra | YES | PARTIAL (see below) | YES | YES | Text says "Spec 3 and 5 can be done first" but this is misleading. Spec 4's file targets (stop-watcher.sh, schema, implement.md) don't overlap with Spec 3 or 5, so they are independently buildable. The text likely means Spec 4 *reads* schema fields from Spec 1. No safety infra exists in stop-watcher.sh (no checkpoint, no circuit breaker, no metrics, no read-only detection). All Spec 4 changes are entirely new. |
| 5: bmad-bridge-plugin | YES (completely independent) | YES (no deps) | YES | Slightly optimistic for "small" | No bmad-bridge directory exists (expected). Plugin structure is standard and well-understood from ralph-specum. The mapping table (PRD→requirements, user stories→verification, ADRs→design, epic→tasks, test scenarios→verify) is straightforward structural mapping. Could edge up to "medium" if BMAD artifacts have complex structure not captured. |
| 6: collaboration-resolution | YES (after Spec 3) | PARTIAL (see below) | YES | YES | Confirmed: NO new chat signals exist (only "Signal Legend" header with existing 12 signals). NO cross-branch regression workflow. NO BUG_DISCOVERY pattern. NO experiment-propose-validate pattern. The "before modifying tests, check baseline" rule does not exist. All 5 changes are entirely new. Spec 6 text says "Spec 3 and 5 can be done independently but sequential order avoids conflict" — this is technically true (different sections of same files) but Spec 6 references role-contracts.md which Spec 3 creates, so there IS an implicit dependency. |
| 7: pair-debug-auto-trigger | YES (after Specs 3, 6) | PARTIAL (see below) | YES | YES | Confirmed: NO pair-debug concept, NO Driver/Navigator roles, NO PAIR-DEBUG mode announcement, NO debug logging as investigation technique. All changes entirely new. Depends on Spec 6's signals AND Spec 3's role restrictions (spec-executor gets debug logging rule). Spec 7's interface contracts are accurate but don't list spec-reviewer.md or qa-engineer.md — these are correct since Spec 7 only modifies spec-executor.md from the agent files (not external-reviewer.md). |

### Dependency Graph Issues

**Issue 1: Spec 4 dependency text is misleading.**

Epic text: `"Dependencies: Spec 1 (schema fields...; Spec 3 and 5 can be done first but this spec reads schema fields from Spec 1)"`

- **Problem**: Implies Spec 3 and 5 are prerequisites or that Spec 4 has some relationship with them. It does not. Spec 4's file targets are entirely independent.
- **Fix**: Change to `"Dependencies: Spec 1 (COMPLETE — merged in PR #12; schema fields nativeTaskMap, nativeSyncEnabled, nativeSyncFailureCount confirmed present). Adds ciCommands field. All other file targets independent of Specs 3-7."`

**Issue 2: Spec 6 dependency text is imprecise.**

Epic text: `"Dependencies: Spec 3 (agent file modifications are additive to different sections; Spec 5 can be done independently but sequential order avoids any conflict risk)"`

- **Problem**: Spec 6 creates `references/collaboration-resolution.md` and modifies `references/failure-recovery.md` and `templates/chat.md`. It references `references/role-contracts.md` (created by Spec 3) in agent modifications. Spec 5 has zero relationship to Spec 6.
- **Fix**: Change to `"Dependencies: Spec 3 (references role-contracts.md in agent file modifications). Spec 6 should read Spec 3's additions to agent files before making its own additions to the same files."`

**Issue 3: Spec 7 dependency on Spec 3 not stated.**

Epic text: `"Dependencies: Spec 6 (depends on Spec 6's collaboration signals and BUG_DISCOVERY pattern in failure-recovery.md)"`

- **Problem**: Spec 7 modifies `agents/spec-executor.md` (adding debug logging as first-class technique). Spec 3 and 6 also modify this file. Spec 7 should read both Spec 3's and Spec 6's additions to spec-executor.md. This is not stated.
- **Fix**: Change to `"Dependencies: Spec 3 (adds role restrictions to spec-executor.md that Spec 7 adds to), Spec 6 (collaboration signals, BUG_DISCOVERY pattern in failure-recovery.md). Spec 7 should read both Spec 3 and 6's additions to spec-executor.md before making its own."`

**Corrected dependency graph:**

```
Spec 3 (role-boundaries) — NO DEPS
  └── Modifies: agents/spec-executor.md, agents/external-reviewer.md,
               agents/qa-engineer.md, agents/spec-reviewer.md
  └── Creates: references/role-contracts.md
  └── │
  ▼
Spec 4 (loop-safety-infra) — NO DEPS (independent file targets)
  ├── Modifies: hooks/scripts/stop-watcher.sh, schemas/spec.schema.json,
  │            commands/implements.md
  ├── Creates: references/loop-safety.md, hooks/scripts/checkpoint.sh
  ├── Reads: schemas/spec.schema.json (nativeTaskMap etc. from Spec 1, already present)
  │
  ▼
Spec 5 (bmad-bridge-plugin) — NO DEPS (entirely new plugin)
  └── Creates: plugins/ralph-bmad-bridge/
  │
  ▼
Spec 6 (collaboration-resolution) — DEPS: Spec 3
  ├── Reads: references/role-contracts.md (created by Spec 3)
  ├── Modifies: references/failure-recovery.md, templates/chat.md
  ├── Modifies: agents/spec-executor.md (after Spec 3), agents/external-reviewer.md (after Spec 3)
  ├── Creates: references/collaboration-resolution.md
  │
  ▼
Spec 7 (pair-debug-auto-trigger) — DEPS: Spec 3, Spec 6
  ├── Reads: references/role-contracts.md (Spec 3)
  ├── Reads: references/collaboration-resolution.md (Spec 6)
  ├── Reads: references/failure-recovery.md (Spec 6's BUG_DISCOVERY changes)
  ├── Reads: templates/chat.md signals (Spec 6's new signals)
  ├── Modifies: references/failure-recovery.md (after Spec 6)
  ├── Modifies: agents/spec-executor.md (after Spec 3 and 6)
  ├── Modifies: references/coordinator-pattern.md
  └── Creates: references/pair-debug.md
```

### File Existence Verification

| Referenced File | Exists? | Lines (actual) | Lines (research doc) | Match? |
|----------------|---------|---------------|---------------------|--------|
| agents/spec-executor.md | YES | 373 | 374 | YES (off by 1) |
| agents/external-reviewer.md | YES | 700 | 701 | YES (off by 1) |
| agents/qa-engineer.md | YES | 751 | not counted | N/A |
| agents/spec-reviewer.md | YES | 275 | not counted | N/A |
| hooks/scripts/stop-watcher.sh | YES | 665 | 666 | YES (off by 1) |
| schemas/spec.schema.json | YES | 487 | not counted | N/A |
| commands/implement.md | YES | 313 | 314 | YES (off by 1) |
| templates/chat.md | YES | 61 | 62 | YES (off by 1) |
| references/failure-recovery.md | YES | 544 | 545 | YES (off by 1) |
| references/coordinator-pattern.md | YES | 1023 | 1024 | YES (off by 1) |

All line counts are within 1 line of the research doc values. Likely the files grew by 1 line between research write and this audit, or vice versa. Negligible.

### Missing Specs?

**None identified.** The 5 specs map 1-to-1 with the remaining roadmap phases (3-7). Spec 2 (prompt-diet-refactor) is intentionally excluded per user decision.

### Unnecessary Specs?

**None identified.** Each spec targets a distinct gap:
- Spec 3: No role enforcement exists today
- Spec 4: No safety infra exists today
- Spec 5: No BMAD bridge exists today
- Spec 6: No collaboration protocol exists today
- Spec 7: No auto-trigger exists today

### Scope Assessment

| Spec | Claimed Size | Actual Complexity | Notes |
|------|-------------|-------------------|-------|
| 3: role-boundaries | medium | medium | 4 agent files + 1 new reference + hook logic. Straightforward additions. |
| 4: loop-safety-infra | medium | medium-hi | stop-watcher.sh is 665 lines of complex logic. New features must be added as functions at end without modifying existing logic. This is harder than it sounds. |
| 5: bmad-bridge-plugin | small | small-medium | Structural mapper is straightforward IF BMAD artifact format is predictable. If BMAD PRDs/ADRs have complex nesting, mapping gets harder. |
| 6: collaboration-resolution | medium | medium | 4 file modifications + 1 new reference. Mostly adding rules/patterns to existing text. Straightforward. |
| 7: pair-debug-auto-trigger | small-medium | small-medium | 2 file modifications + 1 new reference. Simple trigger logic + role definitions. Straightforward. |

### Content Verification (What Exists vs What Needs Adding)

| Feature | Exists Today? | Spec That Adds It |
|---------|--------------|-------------------|
| Role contract file (role-contracts.md) | NO | 3 |
| "DO NOT edit" lists in agents | NO (only verification DO NOTs) | 3 |
| State integrity hook for unauthorized edits | PARTIAL (state validation in implement.md, but no hook-level check) | 3 |
| Pre-loop git checkpoint | NO | 4 |
| Circuit breaker | NO | 4 |
| Per-task metrics (.metrics.jsonl) | NO | 4 |
| Read-only detection | NO | 4 |
| CI command discovery | NO | 4 |
| `ciCommands` schema field | NO | 4 |
| BMAD bridge plugin | NO | 5 |
| Cross-branch regression workflow | NO | 6 |
| Experiment-propose-validate pattern | NO | 6 |
| BUG_DISCOVERY signal | NO | 6 |
| New chat signals (HYPOTHESIS, etc.) | NO | 6 |
| "Check baseline before modifying tests" rule | NO | 6 |
| Pair-debug auto-trigger | NO | 7 |
| Driver/Navigator roles | NO | 7 |
| Debug logging as first-class technique | NO | 7 |

### Overall Assessment

**PASS (with minor corrections needed)**

The epic decomposition is sound. All 5 specs are real, all targets are real, all interface contracts are accurate, and all referenced files exist with approximately correct line counts. The dependency graph is mostly correct but needs 3 text clarifications:

1. Spec 4 should not mention Spec 3/5 as dependencies — they are independent
2. Spec 6 should explicitly state it reads role-contracts.md (created by Spec 3)
3. Spec 7 should explicitly state it reads additions from both Spec 3 and Spec 6 in spec-executor.md

The sequential order 3 → 4 → 5 → 6 → 7 is correct and practical. Specs 3, 4, and 5 could theoretically parallelize (different file targets), but sequential avoids all risk on the shared agent files and matches the roadmap's intent.

The research.md already correctly identified the key constraints (large agent files, stop-watcher.sh complexity, coordinator-pattern.md size) and the risks table is accurate.
