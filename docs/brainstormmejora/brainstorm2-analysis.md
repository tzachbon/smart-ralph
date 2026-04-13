# Smart Ralph — Brainstorm 2 Analysis: BMAD Integration & Architecture Simplification

> **Date**: 2026-04-13
> **Source**: Second brainstorm (Perplexity deep research) + full codebase audit
> **Focus**: Whether smart-ralph is over-engineering vs. Bmalph, BMAD integration path, simplification opportunities

---

## 1. Executive Summary

The second brainstorm raises a **strategic question**: Is smart-ralph over-engineering compared to Bmalph?

**Verdict**: No — but the **complexity is in the wrong place**. Smart-ralph targets a higher autonomy level than Bmalph (which aims for "ready for human review"), but smart-ralph's complexity lives in fragile text-based agent coordination rather than in solid infra (rollback, circuit breakers, metrics). The fix is not to abandon smart-ralph but to:

1. **Borrow Bmalph's infra-first approach** (git checkpoints, circuit breakers, metrics)
2. **Add BMAD as a spec generator** for heavy features
3. **Reduce text-based agent coordination complexity** by making critical rules mechanical
4. **Keep smart-ralph's existing agents** for lightweight specs

---

## 2. Bmalph vs. Smart-Ralph: What Each Actually Does

### Bmalph (from public repo analysis)
| Aspect | What Bmalph Does |
|--------|-----------------|
| **Goal** | BMAD planning → Ralph execution loop → "branch ready for human review" |
| **Complexity focus** | Loop safety: git pre-loop checkpoint, heartbeat for read-only detection, metrics append-only, circuit breaker, test failure injection |
| **Agent sophistication** | Minimal — relies on Ralph's simple loop, not multi-agent coordination |
| **Quality gates** | Basic — assumes CI exists, doesn't enforce per-task mypy/ruff/coverage |
| **Target use** | Large features where context loss is the main risk |
| **Autonomy level** | "Loop won't destroy repo + makes reasonable progress" |
| **Recent issues/PRs** | Swarm mode (multi-agent parallel), pre-loop git checkpoint, metrics, docs, cross-platform support |

### Smart-Ralph (from codebase audit)
| Aspect | What Smart-Ralph Does |
|--------|----------------------|
| **Goal** | Spec → research/requirements/design/tasks → autonomous implementation → "PR ready for merge" |
| **Complexity focus** | Multi-agent coordination: coordinator, spec-executor, external-reviewer, qa-engineer, spec-reviewer |
| **Agent sophistication** | High — 10 specialized agents, chat protocol, signal system, parallel execution |
| **Quality gates** | Strong — per-task VERIFY commands, 5-layer verification, coverage/mypy/ruff enforcement |
| **Target use** | Any feature spec, from small bug fixes to large epics |
| **Autonomy level** | "Agents work autonomously for hours, human only does final semantic review" |
| **Recent work** | Gap analysis from first brainstorm (state consistency, verification unification, prompt bloat) |

### Key Insight
They solve **different parts** of the problem:
- **Bmalph** = planning + safe execution loop (infra-first)
- **Smart-Ralph** = spec-driven development + multi-agent coordination (quality-first)

**Neither is "better" — they're complementary.** The optimal system combines Bmalph's safety infra with smart-ralph's spec rigor.

---

## 3. Where Smart-Ralph IS Over-Engineering (Confirmed)

### 3.1 Text-Based Agent Coordination
**Problem**: The coordinator reads 5 reference files (~15,000+ tokens) and interprets HOLD signals in natural language. This is the "fragile" complexity.

**Evidence**: Real example where coordinator said "no new messages" despite 2 active HOLD signals. The model reasoned its way past the rule.

**Bmalph approach**: Would use a simple grep/exit-code check, not a 200-line chat protocol.

### 3.2 Multiple Contradictory References
**Problem**: Two files define different verification layer counts (5 vs 3). The model picks whichever it read last.

**Evidence**: `coordinator-pattern.md` (5 layers) vs `verification-layers.md` (3 layers) vs `implement.md` quick reference (3 layers).

**Bmalph approach**: Wouldn't have this problem — single source of truth, minimal references.

### 3.3 Reviewer Acting as Emergency Coordinator
**Problem**: External reviewer recreates `.ralph-state.json`, resets taskIndex, unmarks tasks — doing the coordinator's job.

**Evidence**: In fix-emhass-sensor-attributes, reviewer had to manually fix state because coordinator advanced past FAIL/HOLD.

**Root cause**: No mechanical enforcement of role boundaries, only text-based rules.

### 3.4 What Bmalph Has That Smart-Ralph Lacks
| Feature | Bmalph | Smart-Ralph |
|---------|--------|-------------|
| Pre-loop git checkpoint (rollback safety) | ✅ | ❌ |
| Circuit breaker (stop after N failures) | ✅ | Partial (maxTaskIterations, but no global circuit breaker) |
| Metrics/telemetry of loop performance | ✅ | ❌ |
| Test failure injection into context | ✅ | ❌ |
| Read-only repo detection (heartbeat) | ✅ | ❌ |
| Swarm mode (parallel story execution) | ✅ | Partial (TeamCreate for [P] tasks only) |

---

## 4. Where Smart-Ralph IS Correctly Complex

### 4.1 Spec Phases (research → requirements → design → tasks)
This is **not over-engineering**. It's a proven SDLC pattern. Bmalph skips this (uses BMAD for planning, then jumps to Ralph). Smart-ralph's phased approach produces better specs for autonomous execution.

### 4.2 Verification Layers
Having multiple verification layers is correct. The problem is not the layers — it's that they're **inconsistently defined** across files.

### 4.3 External Reviewer
Parallel review is valuable. The problem is not the reviewer — it's that the reviewer has to **compensate for coordinator failures**.

### 4.4 Epic Triage / Multi-Spec Decomposition
This is correct architecture for large features. Not over-engineering.

---

## 5. BMAD Integration: Strategic Path

### 5.1 The Opportunity
BMAD (via Bmalph) excels at generating **rigid, deterministic specifications** for large features:
- PRD (Product Requirements Document)
- User stories with acceptance criteria
- Architecture decisions
- Task decomposition

Smart-ralph excels at **executing specs autonomously** with quality gates.

**Synergy**: Use BMAD to generate specs for heavy features, execute them with smart-ralph's loop.

### 5.2 Current Plugin Landscape
| Plugin | Purpose | Used? |
|--------|---------|-------|
| `ralph-specum` | Main spec generator (research → requirements → design → tasks → implement) | ✅ Active |
| `ralph-specum-codex` | OpenAI Codex adapter (same workflow, different model platform) | ✅ Active |
| `ralph-speckit` | GitHub spec-kit methodology adapter (constitution-first) | ❌ Not used |

### 5.3 Proposed Architecture

```
┌─────────────────────────────────────────────────┐
│                   User Entry                     │
│  /ralph-specum:start <goal>                     │
└────────────────────┬────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         │   Spec Generator       │
         │   (chooses based on    │
         │   complexity/size)     │
         └───────────┬───────────┘
                     │
    ┌────────────────┼────────────────┐
    │                │                │
    ▼                ▼                ▼
┌────────┐    ┌──────────┐    ┌────────────┐
│ BMAD   │    │ Specum   │    │  Speckit   │
│ Bridge │    │ (default)│    │ (optional) │
│        │    │          │    │            │
│ Heavy  │    │ Medium/  │    │ Constitution│
│ features│   │ Light    │    │ -first     │
└────┬───┘    └────┬─────┘    └─────┬──────┘
     │             │                │
     └─────────────┼────────────────┘
                   │
         ┌─────────▼─────────┐
         │   Common Format    │
         │   specs/<name>/    │
         │   (research.md,    │
         │    requirements.md,│
         │    design.md,      │
         │    tasks.md)       │
         └─────────┬─────────┘
                   │
         ┌─────────▼─────────┐
         │   Execution Engine │
         │   (coordinator,    │
         │    spec-executor,  │
         │    reviewer, QA)   │
         └────────────────────┘
```

### 5.4 BMAD Bridge Plugin

**Location**: `plugins/ralph-bmad-bridge/`

**Responsibilities**:
1. Read BMAD artifacts (`_bmad/` directory, PRD, user stories, etc.)
2. Map to smart-ralph spec format (research.md, requirements.md, design.md, tasks.md)
3. Place the spec in `specs/<name>/` for execution
4. **NOT** a complex prompt engine — a structural mapper only

**What it does NOT do**:
- Execute the spec (that's the execution engine's job)
- Generate micro-rules for agent behavior
- Replace specum for lightweight specs

**Mapping example**:
| BMAD Artifact | Smart-Ralph Target |
|---------------|-------------------|
| PRD / Product Brief | requirements.md → User Stories + FR/NFR |
| User Stories with Acceptance Criteria | requirements.md → Verification Contract |
| Architecture Decision Records | design.md → Architecture section |
| Epic / Feature Breakdown | tasks.md → Phase breakdown |
| Test Scenarios | tasks.md → Verify commands |

---

## 6. Updated Gap Analysis (Consolidated from Both Brainstorms)

### Critical Gaps (Must Fix First)

| Gap | Severity | Root Cause | Fix Approach |
|-----|----------|------------|-------------|
| **GAP-VERIFY-01**: Contradictory verification layer definitions | **HIGH** | Two authoritative files define different layer counts | Unify to single source |
| **GAP-COORD-01**: HOLD signals ignored | **HIGH** | Text-based interpretation instead of mechanical check | Bash grep + exit code |
| **GAP-STATE-01**: State drift undetected | **HIGH** | No pre-loop validation | Validate tasks.md vs .ralph-state.json at start |

### Important Gaps (Fix Second)

| Gap | Severity | Root Cause | Fix Approach |
|-----|----------|------------|-------------|
| **GAP-PROMPT-BLOAT-01**: 15,000+ token coordinator context | **MEDIUM** | 5 references loaded every iteration, most irrelevant | Split into modular refs, load on demand |
| **GAP-ROLES-01**: No role boundary enforcement | **MEDIUM** | Text-based rules, no mechanical enforcement | Role contract file + file-access constraints |
| **GAP-INFRA-01**: Missing Bmalph-style safety | **MEDIUM** | No git checkpoint, circuit breaker, metrics | Borrow from Bmalph |

### Strategic Gaps (Future)

| Gap | Severity | Root Cause | Fix Approach |
|-----|----------|------------|-------------|
| **GAP-BMAD-01**: No BMAD integration | **LOW** (strategic) | BMAD bridge doesn't exist yet | Create ralph-bmad-bridge plugin |
| **GAP-SPECKIT-01**: Unused plugin | **LOW** | Speckit exists but not integrated | Either integrate or remove |

---

## 7. Updated Implementation Roadmap

### Phase 1: Foundation (Fix Critical Gaps)
**Spec**: `engine-state-hardening` (already defined in gap-analysis-and-roadmap.md)
- Unify verification layers (fix contradiction)
- Mechanical HOLD check (grep-based)
- State integrity validation at loop start

### Phase 2: Prompt Diet (Reduce Bloat)
**Spec**: `prompt-diet-refactor` (already defined)
- Split coordinator-pattern.md into modular references
- Eliminate duplications across files
- Remove dead text from agent context

### Phase 3: Role Boundaries
**Spec**: `role-boundaries` (already defined)
- Define role contracts
- Enforce file-access boundaries
- Add state integrity hook

### Phase 4: Bmalph-Style Safety Infra
**Spec**: `loop-safety-infra` (NEW)
- Pre-loop git checkpoint (git stash + commit before execution)
- Circuit breaker (stop after N consecutive failures or N hours)
- Metrics append (iterations, tasks completed, fabrications detected)
- Read-only repo detection (heartbeat write check)

### Phase 5: BMAD Bridge
**Spec**: `bmad-bridge-plugin` (NEW)
- Create `plugins/ralph-bmad-bridge/`
- Define BMAD → smart-ralph spec mapping
- Implement structural mapper (no prompt complexity)
- Test with a real BMAD project

---

## 8. What to Keep vs. What to Simplify

### KEEP (This Complexity is Correct)
- ✅ Phased spec workflow (research → requirements → design → tasks)
- ✅ Multi-agent architecture (specialized roles)
- ✅ Verification layers (5 layers, properly unified)
- ✅ External reviewer (parallel review)
- ✅ Epic triage (multi-spec decomposition)
- ✅ Recovery mode (fix task generation)

### SIMPLIFY (This Complexity is Fragile)
- ❌ 5-reference coordinator context → split into modular refs
- ❌ Text-based HOLD interpretation → mechanical grep check
- ❌ 6 Native Task Sync sections → consolidate to 2
- ❌ Detailed bash/jq scripts in prompts → move to hooks/scripts
- ❌ PR lifecycle in coordinator → separate reference
- ❌ Modification request handler inline → separate reference

### ADD (Missing Infra That Bmalph Has)
- ➕ Pre-loop git checkpoint
- ➕ Circuit breaker
- ➕ Loop metrics
- ➕ BMAD bridge plugin

---

## 9. Updated Spec Creation Prompts

The prompts from `create-spec-prompt.md` remain valid for Specs 1-3.

For the NEW specs (Phase 4 and 5), see the appendices below.

---

## 10. Appendix A: Phase 4 Spec Brief (Loop Safety Infra)

### `loop-safety-infra`
**Goal**: Add Bmalph-style safety mechanisms to smart-ralph's execution engine.

**Key changes**:
1. **Pre-loop git checkpoint**: Before execution starts, create a checkpoint commit. If execution goes catastrophically wrong, `git reset --hard <checkpoint>` restores the repo.
2. **Circuit breaker**: Stop execution after N consecutive task failures (configurable, default 5) OR after N hours (configurable, default 48h). Log to .progress.md.
3. **Metrics append**: After each task, append to `specs/<name>/.metrics.jsonl`:
   ```json
   {"taskIndex": 5, "iteration": 1, "verifyTime": 12.3, "fabricationDetected": false, "timestamp": "2026-04-13T17:05:00Z"}
   ```
4. **Read-only detection**: At loop start, attempt a small write to .progress.md. If it fails, exit with "Repository is read-only — execution cannot proceed."

**Files to modify**:
- `commands/implement.md` — Add checkpoint initialization, circuit breaker check, metrics setup
- `references/coordinator-pattern.md` — Add circuit breaker rules, metrics logging
- NEW: `references/loop-safety.md` — All safety rules in one place
- NEW: `hooks/scripts/checkpoint.sh` — Git checkpoint utilities
- `hooks/stop-watcher.sh` — Integrate circuit breaker

---

## 11. Appendix B: Phase 5 Spec Brief (BMAD Bridge)

### `bmad-bridge-plugin`
**Goal**: Create a plugin that converts BMAD artifacts into smart-ralph spec format.

**Key changes**:
1. **Plugin structure**:
   ```
   plugins/ralph-bmad-bridge/
     .claude-plugin/plugin.json
     commands/
       import-bmad.md     # Entry point: converts BMAD → spec
     scripts/
       bmad-mapper.sh     # Structural mapper (not AI prompts)
     templates/
       bmad-to-spec.md    # Mapping reference
   ```

2. **Mapping rules** (structural, not behavioral):
   - BMAD PRD → requirements.md User Stories
   - BMAD User Stories → requirements.md Verification Contract
   - BMAD Architecture → design.md
   - BMAD Epics → tasks.md Phase breakdown
   - BMAD Test Scenarios → tasks.md Verify commands

3. **Entry point**: `/ralph-bmad:import <bmad-project-path> <spec-name>`
   - Reads BMAD artifacts
   - Generates smart-ralph spec structure
   - Places in `specs/<spec-name>/`
   - Ready for `/ralph-specum:implement`

**NOT in scope**:
- Agent prompts for BMAD behavior
- Complex prompt engineering
- Execution logic (that stays in specum)

---

## 12. Conclusion

The second brainstorm confirmed what the first hinted at but didn't fully articulate:

**Smart-ralph's complexity is not wrong — it's just in the wrong place.**

The fix is:
1. **Move complexity from fragile text-based coordination to solid mechanical checks** (grep, exit codes, state validation)
2. **Borrow Bmalph's safety infra** (checkpoint, circuit breaker, metrics)
3. **Add BMAD as a spec generator** for heavy features
4. **Keep smart-ralph's phased workflow and multi-agent architecture** — they're correct for the target autonomy level

The result will be a system that:
- Handles heavy features (BMAD → rigid specs)
- Handles light features (specum → agile specs)
- Executes autonomously with safety (checkpoint, circuit breaker, verified state)
- Escalates to human only when semantic/product judgment is needed
- Doesn't require the human to be a "messenger between IAs"
