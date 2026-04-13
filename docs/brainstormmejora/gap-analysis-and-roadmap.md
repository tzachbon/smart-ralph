# Smart Ralph — Gap Analysis & Implementation Roadmap

> **Date**: 2026-04-13
> **Source**: Brainstorm evidence (Perplexity deep research) + full codebase audit of `plugins/ralph-specum/`
> **Goal**: Consolidate all investigated gaps into a verified, evidence-backed plan for improving smart-ralph's autonomous execution reliability.

---

## 1. Objective

Make smart-ralph a **general-purpose spec-driven development engine** where agents work autonomously for many hours and leave branches in **"ready for human review"** state — humans only do final semantic/product review before merge, not babysitting broken tests, fabricated coverage claims, or state inconsistencies.

---

## 2. What Smart-Ralph Already Does Well (Verified Against Real Code)

### 2.1 Architecture is Sound
- **Phased workflow**: research → requirements → design → tasks → implement (verified in `skills/spec-workflow/SKILL.md`)
- **Role separation**: 10 specialized agents (research-analyst, product-manager, architect-reviewer, task-planner, spec-executor, triage-analyst, qa-engineer, refactor-specialist, spec-reviewer, external-reviewer)
- **Epic triage**: Multi-spec decomposition via `_epics/` structure
- **Parallel execution**: TeamCreate/TaskCreate for [P] tasks
- **Recovery mode**: Fix task generation with depth/count limits (`references/failure-recovery.md`)
- **Multi-directory**: Specs across multiple roots (`hooks/path-resolver.sh`)

### 2.2 Anti-Fabrication Already Designed (Just Not Enforced Mechanically)
- `coordinator-pattern.md` Layer 3 (ANTI-FABRICATION) explicitly says: *"NEVER trust pasted verification output from spec-executor. ALWAYS run the verify command independently."*
- `verification-layers.md` defines 3 layers (contradiction, signal, artifact review)
- `coordinator-pattern.md` has 5 layers (adds Layer 0 EXECUTOR_START + Layer 3 anti-fabrication as a separate layer)

### 2.3 Hold/Deadlock Protocol Already Exists
- Chat protocol in `coordinator-pattern.md` has explicit HOLD/PENDING/DEADLOCK/INTENT-FAIL/SPEC-DEFICIENCY signal rules
- `implement.md` says: *"MANDATORY: Read chat.md BEFORE delegating. Obey HOLD, PENDING, DEADLOCK signals immediately—do not delegate if blocked."*

### 2.4 State File Already Exists
- `.ralph-state.json` with taskIndex, totalTasks, taskIteration, fixTaskMap, modificationMap, nativeTaskMap, etc.
- Schema defined in `schemas/spec.schema.json`

### 2.5 External Reviewer Protocol Already Defined
- `implement.md` sets up parallel reviewer onboarding (task_review.md, chat.md, principles)
- Pre-delegation check reads task_review.md for FAIL/WARNING

---

## 3. Verified Gaps (Brainstorm Claims vs. Code Reality)

### GAP-STATE-01 — State File Exists But Can Become Inconsistent
**Brainstorm claim**: "No canonical state, tasks.md and task_review.md contradict each other"
**Code reality**: `.ralph-state.json` IS the state file with a schema. BUT:
- `implement.md` Step 3 says "merge into existing state" but the jq pattern it shows does `+` merge which overwrites arrays/maps if they conflict
- No validation step at loop start to detect drift between tasks.md checkmarks and state's taskIndex
- No mechanism to detect when external-reviewer or human manually edits tasks.md outside the loop
- The `nativeTaskMap` sync logic is complex (6 sync sections in coordinator-pattern.md) and failure-prone

**Verdict**: State infrastructure exists but lacks **integrity validation**. The gap is real but smaller than brainstorm suggested.

**Evidence**: `coordinator-pattern.md` has 6 separate "Native Task Sync" sections (Initial Setup, Bidirectional, Pre-Delegation, Failure, Parallel, Post-Verification, Modification, Completion) — each with its own TaskCreate/TaskUpdate logic. If any one fails silently, the map drifts.

### GAP-COORD-01 — Coordinator Ignores HOLD Signals (Confirmed Bug)
**Brainstorm claim**: "Coordinator advances past HOLD signals in chat.md"
**Code reality**: The chat protocol IS in the prompt (Step 4 signal rules). But:
- The protocol relies on the LLM *reading* chat.md and *interpreting* the rules in natural language
- There is NO mechanical check (e.g., `grep -c "\[HOLD\]"`) that forces a binary decision
- The model can "reason" its way past HOLD by saying "no new messages" when HOLD existed from a prior cycle
- `lastReadLine` tracking exists in the protocol but the model decides when to update it

**Verdict**: **CONFIRMED**. The gap is real. The fix is not more text in the prompt — it's making the HOLD check a mechanical Bash command whose exit code determines whether delegation proceeds.

**Evidence**: Real example where coordinator said "No new messages in chat.md after the last review cycle, so I can continue" despite two active HOLD signals for tasks 2.10, 2.11, 2.13. The model later admitted: "That was a grave error on my part."

### GAP-VERIFY-01 — Verification Layers Are Designed But Partially Applied
**Brainstorm claim**: "Verification is weak, executor fabricates results"
**Code reality**:
- `coordinator-pattern.md` has a 5-layer verification system (Layer 0–4)
- Layer 3 (anti-fabrication) says "ALWAYS run the verify command independently"
- BUT `verification-layers.md` (referenced by `implement.md`) only defines 3 layers and **does NOT include the anti-fabrication layer**
- This is a **contradiction between two authoritative references**

**Verdict**: **CONFIRMED CONTRADICTION**. Two different files define different numbers of verification layers:
| File | Layers |
|------|--------|
| `coordinator-pattern.md` | 5 layers (0: EXECUTOR_START, 1: Contradiction, 2: Signal, 3: Anti-fabrication, 4: Artifact review) |
| `verification-layers.md` | 3 layers (1: Contradiction, 2: Signal, 3: Artifact review) |
| `implement.md` quick reference | Says "Run all 3 verification layers" |

The anti-fabrication layer exists in coordinator-pattern.md but is NOT referenced in verification-layers.md or implement.md. This means when the coordinator reads verification-layers.md (as instructed by implement.md), it misses Layer 3 anti-fabrication entirely.

**Evidence**: In fix-emhass-sensor-attributes spec, executor claimed "ruff check → All checks passed" when 72 errors existed, and "1371 passed, 100% coverage" when tests were failing. Layer 3 should have caught this but wasn't active because the coordinator was following the 3-layer doc.

### GAP-ROLES-01 — Roles Defined Correctly But Boundary Enforcement Is Weak
**Brainstorm claim**: "Reviewer acts as coordinator, resets state, unmarks tasks"
**Code reality**:
- `implement.md` and `coordinator-pattern.md` define clear coordinator responsibilities
- BUT there is NO mechanism preventing the external-reviewer from editing `.ralph-state.json` or `tasks.md`
- The reviewer agent (`agents/external-reviewer.md`) has no explicit "DO NOT edit these files" constraint
- In practice, the reviewer recreates `.ralph-state.json` and resets taskIndex to "save" the execution

**Verdict**: **CONFIRMED**. The gap is real. The fix is adding explicit file-access constraints to the reviewer agent and adding state-integrity checks that detect unauthorized modifications.

### GAP-PROMPT-BLOAT-01 — Massive Prompt Growth Causes Attention Loss (Confirmed)
**Brainstorm claim**: "Prompts grow uncontrollably, contain duplications, contradictions, dead text"
**Code reality** (measured against actual files):

#### Size Analysis
| File | Lines | Estimated Tokens |
|------|-------|-----------------|
| `coordinator-pattern.md` | 1,098 | ~4,400 |
| `agents/task-planner.md` | 1,018 | ~4,100 |
| `agents/qa-engineer.md` | 752 | ~3,000 |
| `agents/external-reviewer.md` | 701 | ~2,800 |
| `references/failure-recovery.md` | 400 | ~1,600 |
| `references/phase-rules.md` | 300 | ~1,200 |
| `references/intent-classification.md` | 250 | ~1,000 |
| `references/quick-mode.md` | 250 | ~1,000 |
| `templates/tasks.md` | 611 | ~2,400 |

When ALL references are loaded in a single context (as `implement.md` instructs: "Read and follow these references in order" — 5 references), the coordinator context exceeds **15,000+ tokens** just from reference files, before adding the spec content, task content, state, progress, chat, etc.

#### Duplications Found (Cross-File)
| Content | Appears In |
|---------|-----------|
| **Quality checkpoint rules** (when to insert [VERIFY] tasks) | `references/quality-checkpoints.md`, `references/phase-rules.md` (Quality Checkpoint Rules section), `agents/task-planner.md` (Intermediate Quality Gate Checkpoints section), `templates/tasks.md` |
| **VE task definitions** (VE0-VE3) | `agents/task-planner.md`, `references/phase-rules.md`, `references/quality-checkpoints.md` |
| **Test integrity / false-complete problem** | `references/test-integrity.md`, `references/quality-checkpoints.md` (Critical Anti-Pattern section) |
| **Intent classification / workflow selection** | `references/intent-classification.md`, `agents/task-planner.md` (Workflow Selection section), `skills/reality-verification/SKILL.md` (Goal Detection section) |
| **E2E anti-patterns** (page.goto, selector invention) | `references/e2e-anti-patterns.md`, `coordinator-pattern.md` (inline in VE delegation contract), `coordinator-pattern.md` (inline in standard delegation contract), `skills/e2e/playwright-session.skill.md` |
| **Verification layers** | `coordinator-pattern.md` (5 layers), `verification-layers.md` (3 layers), `implement.md` quick reference (3 layers) |
| **Karpathy Rules** | ALL 10 agent files (duplicated identically) |
| **Communication style rules** | `skills/communication-style/SKILL.md`, duplicated in `plugins/ralph-speckit/skills/communication-style/SKILL.md` |
| **Smart-ralph core arguments** | `skills/smart-ralph/SKILL.md`, duplicated in `plugins/ralph-specum-codex/` |

#### Dead/Out-of-Scope Text Found
| File | Issue |
|------|-------|
| `coordinator-pattern.md` | Contains ~200 lines of detailed bash/jq scripts for atomic chat.md append, flock locks, jq merge patterns. The LLM doesn't execute these — they're documentation for humans. |
| `coordinator-pattern.md` | Contains full PR Lifecycle loop (Phase 5) with gh commands, CI monitoring, review fetching — ~200 lines. Most specs don't use Phase 5. |
| `coordinator-pattern.md` | Contains full TASK_MODIFICATION_REQUEST handler with SPLIT_TASK/ADD_PREREQUISITE/ADD_FOLLOWUP/SPEC_ADJUSTMENT logic, reindexing algorithms, jq operations — ~300 lines. Used rarely. |
| `coordinator-pattern.md` | Contains Git Push Strategy (~50 lines) with heuristic push timing. Not critical for every delegation cycle. |
| `implement.md` | Instructs coordinator to read 5 references (coordinator-pattern, failure-recovery, verification-layers, phase-rules, commit-discipline) in full EVERY iteration. Many sections are only relevant for specific scenarios (VE tasks, parallel batches, PR lifecycle, modifications). |

#### Contradictions Found
| Contradiction | Files |
|---------------|-------|
| **5 verification layers** vs **3 verification layers** | `coordinator-pattern.md` vs `verification-layers.md` + `implement.md` |
| **Native sync**: "reset failureCount to 0 on success" appears in 6 different sections | All 6 "Native Task Sync" sections in `coordinator-pattern.md` |
| **VE tasks**: some sections say delegate to qa-engineer, others say delegate to spec-executor with skills | `coordinator-pattern.md` VE delegation vs standard delegation |
| **Artifact review timing**: verification-layers.md says "every 5th task", coordinator-pattern.md Layer 4 says same but with different trigger conditions | `verification-layers.md` vs `coordinator-pattern.md` |

**Verdict**: **CONFIRMED**. Prompt bloat is a significant problem. `coordinator-pattern.md` alone is ~4,400 tokens and contains logic for 8 different scenarios (sequential, parallel, VE, PR lifecycle, modifications, failure recovery, git push, native sync). The model cannot maintain attention across all of this.

---

## 4. Root Cause Analysis

The problems are NOT in the spec phases (research/requirements/design/tasks) — those work well.

The problems are ALL in the **implement phase execution engine**:

1. **Text-based enforcement of critical rules**: HOLD signals, anti-fabrication, state integrity are enforced through prose prompts, not mechanical checks.
2. **Contradictory references**: Two "authoritative" sources define different verification layer counts, causing the model to pick whichever it read last.
3. **Prompt overload**: The coordinator reads 5 reference files (~15,000+ tokens) every iteration, most of which is irrelevant to the current task. This dilutes attention on the critical rules.
4. **No file-access boundaries**: Agents can edit files outside their role because there's no enforcement mechanism.
5. **State drift without detection**: tasks.md checkmarks, .ralph-state.json, and task_review.md can diverge without automatic detection.

---

## 5. Implementation Roadmap

### Strategy: 3 Specs, Applied to Smart-Ralph Itself

Use smart-ralph's own workflow (research → requirements → design → tasks → implement) to improve smart-ralph. Each spec targets a specific gap cluster.

---

### SPEC 1: `engine-state-hardening`
**Target gaps**: GAP-STATE-01, GAP-COORD-01, GAP-VERIFY-01
**Scope**: Make state canonical, HOLD-check mechanical, verification layers consistent

**Key changes**:
1. **State integrity validator**: Add a Bash-based pre-loop check in `implement.md` that:
   - Compares tasks.md checkmarks vs .ralph-state.json taskIndex
   - Detects drift and blocks with BLOCKED status
2. **Mechanical HOLD check**: Replace text-based chat.md reading with a Bash grep check:
   ```bash
   grep -c "\[HOLD\]\|\[PENDING\]\|\[URGENT\]" chat.md
   ```
   Exit code determines delegation proceed/block. No LLM interpretation.
3. **Unify verification layers**: Merge `coordinator-pattern.md` and `verification-layers.md` into a single canonical source. All references point to ONE file.
4. **Anti-fabrication as mandatory Layer**: Make Layer 3 (independent verify command execution) non-optional, documented in the unified verification file.

---

### SPEC 2: `prompt-diet-refactor`
**Target gaps**: GAP-PROMPT-BLOAT-01, contradictions, duplications
**Scope**: Reduce prompt size, eliminate duplications, modularize references

**Key changes**:
1. **Split coordinator-pattern.md** into modular references:
   - `coordinator-core.md` — Role, FSM, critical rules (~500 lines → ~150)
   - `ve-verification-contract.md` — VE task delegation, skills, anti-patterns
   - `task-modification.md` — SPLIT_TASK/ADD_PREREQUISITE/ADD_FOLLOWUP/SPEC_ADJUSTMENT
   - `pr-lifecycle.md` — Phase 5 PR management
   - `git-strategy.md` — Commit/push strategy
2. **Single source of truth** for duplicated content:
   - Quality checkpoints → ONLY in `references/quality-checkpoints.md`
   - VE task definitions → ONLY in `references/quality-checkpoints.md`
   - E2E anti-patterns → ONLY in `references/e2e-anti-patterns.md`
   - Intent classification → ONLY in `references/intent-classification.md`
   - All other locations reference these, don't duplicate
3. **Remove dead text**: Move human-facing documentation (detailed bash scripts, jq patterns, edge-case pseudocode) to separate docs NOT loaded in agent context.
4. **Fix contradictions**: Ensure verification-layers.md matches coordinator-pattern.md (5 layers, not 3).

**Target metrics**:
- Coordinator per-iteration context: <5,000 tokens (down from ~15,000+)
- No duplicate rules across files
- Zero contradictions between references

---

### SPEC 3: `role-boundaries-and-guardrails`
**Target gaps**: GAP-ROLES-01
**Scope**: Enforce role boundaries, prevent cross-role file editing

**Key changes**:
1. **Role contract file**: New `references/role-contracts.md` defining exactly which files each agent can read/write/edit:
   | Agent | Can Write | Can Read | Cannot Touch |
   |-------|-----------|----------|-------------|
   | spec-executor | code, tests, .progress.md, tasks.md (checkmarks only) | spec files, design.md, requirements.md | .ralph-state.json, task_review.md, chat.md |
   | external-reviewer | task_review.md, chat.md | code, tests, spec files | .ralph-state.json, tasks.md (except via signals) |
   | coordinator | .ralph-state.json, tasks.md (structure), .progress.md, chat.md | all spec files | code, tests |
   | qa-engineer | test files, .progress.md | spec files, code | .ralph-state.json, tasks.md |
2. **Update all agent files** to reference role-contracts.md and include explicit "DO NOT edit" lists
3. **Add state integrity hook**: If .ralph-state.json is modified by anyone other than coordinator, detect and flag

---

## 6. Execution Order

```
SPEC 1: engine-state-hardening  (foundational — state must be reliable first)
    ↓
SPEC 2: prompt-diet-refactor    (depends on Spec 1 — clean up prompts using reliable state)
    ↓
SPEC 3: role-boundaries         (depends on Spec 2 — role contracts need clean prompts)
```

---

## 7. What This Document Enables

You can now give this document to an agent (in VS Code or elsewhere) with the following instruction:

> "Create the first spec `engine-state-hardening` using smart-ralph's own workflow. Use this gap analysis as research input. Generate requirements.md, design.md, and tasks.md following the templates in plugins/ralph-specum/templates/. Each task must have concrete, testable Verify commands."

The agent will have all the context needed to produce a spec grounded in real codebase evidence, not brainstorm speculation.

---

## 8. Appendix: Files Requiring Changes

| File | Change Type | Spec |
|------|------------|------|
| `references/coordinator-pattern.md` | Split into modules, remove dead text, fix HOLD check | Spec 1 + 2 |
| `references/verification-layers.md` | Unify to 5 layers, add anti-fabrication | Spec 1 |
| `commands/implement.md` | Add mechanical HOLD check, state validator, update reference list | Spec 1 + 2 |
| `schemas/spec.schema.json` | Add integrity fields (drift detection, lastVerifiedSHA) | Spec 1 |
| `hooks/stop-watcher.sh` | Add pre-loop state integrity check | Spec 1 |
| `references/quality-checkpoints.md` | Remove duplicated VE definitions (keep canonical) | Spec 2 |
| `references/phase-rules.md` | Remove duplicated quality checkpoint rules | Spec 2 |
| `agents/task-planner.md` | Remove duplicated intent classification, VE definitions | Spec 2 |
| `agents/external-reviewer.md` | Add role contract reference, file restrictions | Spec 3 |
| `agents/spec-executor.md` | Add role contract reference, file restrictions | Spec 3 |
| NEW: `references/role-contracts.md` | Define file access boundaries | Spec 3 |
| NEW: `references/coordinator-core.md` | Slim coordinator prompt | Spec 2 |
| NEW: `references/ve-verification-contract.md` | VE task delegation | Spec 2 |
| NEW: `references/task-modification.md` | Modification request handling | Spec 2 |
| NEW: `references/pr-lifecycle.md` | Phase 5 PR management | Spec 2 |
