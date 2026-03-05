---
spec: tdd-bug-fix-pattern
phase: research
created: 2026-03-05
generated: auto
---

# Research: tdd-bug-fix-pattern

## Executive Summary

Ralph Specum already has partial infrastructure for bug fix workflows: goal type detection (fix vs add), a `VF` verification task template in `phase-rules.md`, and TDD Red-Green-Yellow support in `spec-executor.md`. The gap is that the "fix" path in normal mode does not have a dedicated, documented workflow -- it falls through intent classification as MID_SIZED or TRIVIAL and uses generic TDD without enforcing reproduce-first discipline. The recommended approach is to add a `BUG_FIX` intent type with a dedicated phase sequence: Reproduce (capture BEFORE state) -> Red (failing test for bug) -> Green (minimal fix) -> Yellow (cleanup) -> VF verification.

---

## External Research

### Best Practices: Bug Fix Workflows

Industry consensus is **reproduce first, fix never** before a failing test exists.

| Practice | Description | Source |
|----------|-------------|--------|
| Reproduce before fixing | Cannot verify a fix without consistent reproduction | MIT 6.031, IBM Debugging |
| Document BEFORE state | Capture exact failure output before any code changes | MIT 6.005, WeAreBrain |
| Root cause over symptom | Never patch symptoms; trace to original trigger | ntietz.com, MIT 6.031 |
| Write test before fix | The test IS the bug specification | Martin Fowler TDD bliki |
| ~95% first-time fix rate | Systematic debugging achieves this vs ~40% ad-hoc | WeAreBrain 2026 |
| Scientific debugging | Binary search, hypothesis -> experiment loop | Andreas Zeller "Why Programs Fail" |

**Six-phase framework** (consensus across sources):
1. Reproduce consistently
2. Understand the system (don't jump to code)
3. Form root cause hypothesis
4. Create failing test (formalizes the hypothesis)
5. Apply minimal fix
6. Verify + document

### TDD Applied to Bug Fixes

TDD's Red-Green-Refactor applies directly to bug fixes -- the test captures the bug before the fix exists.

Key distinction from greenfield TDD:

| Greenfield TDD | Bug Fix TDD |
|----------------|-------------|
| Red = test for new behavior | Red = test that reproduces the bug |
| Green = implement feature | Green = minimal fix (smallest change) |
| Yellow = refactor new code | Yellow = refactor + check for similar bugs |
| No BEFORE state needed | BEFORE state is critical (proves bug existed) |

**Golden rule (Kent Beck, Martin Fowler)**: Never fix a bug without a test. The test IS the reproduction step in code form.

RGRC pattern (Steve Smith / Ardalis): Red -> Green -> Refactor -> Commit. Commit after every passing test to enable rollback if refactor breaks things.

### Log Capture and Diagnostics

What to capture when reproducing a bug:

| Category | What to Record |
|----------|---------------|
| Exact command/steps | Copy-pasteable reproduction command |
| Raw output | Full stdout/stderr (not summarized) |
| Exit code | Explicit 0 vs non-zero |
| Environment | OS, runtime version, dependency versions |
| Timestamp | When the failure was observed |
| Expected vs actual | Explicit comparison, not vague |

Best tools: structured logging (multi-level), git bisect for regression isolation, debugger breakpoints for state inspection.

**Key for Ralph**: The BEFORE state must be machine-readable enough that a `VF` task can re-run the same command and compare exit codes / output patterns.

### Debugging Methodologies

| Methodology | When to Use |
|-------------|-------------|
| Scientific debugging | Always -- hypothesis -> experiment -> observe |
| Binary search / git bisect | Regression bugs with known-good state |
| Rubber duck | Logic errors, "should work" bugs |
| Divide and conquer | Large system, unknown component |
| Delta debugging | Minimize failing test case size |
| Tracer bullets | Trace data flow end-to-end |

The systematic approach from MIT 6.031 aligns perfectly with Ralph's task model: each hypothesis is a task, each experiment is a verify step.

---

## Codebase Analysis

### Existing Infrastructure (What Already Works)

| Component | Location | Current Behavior |
|-----------|----------|-----------------|
| Goal type detection | `references/intent-classification.md` L224-232 | Classifies fix vs add using regex |
| Fix goal handling (quick mode) | `references/quick-mode.md` L80-84 | "For fix goals: run reproduction, document BEFORE state" -- **stub, not implemented** |
| VF task template | `references/phase-rules.md` L212-226 | Reads BEFORE from `.progress.md`, re-runs reproduction cmd, documents AFTER |
| TDD triplet format | `references/phase-rules.md` L143-167 | RED/GREEN/YELLOW task format in spec-executor |
| TDD workflow routing | `references/phase-rules.md` L6-24 | Non-GREENFIELD intents route to TDD workflow |
| spec-executor TDD support | `agents/spec-executor.md` L61-84 | `[RED]`, `[GREEN]`, `[YELLOW]` tags with verify patterns |
| Intent classification | `references/intent-classification.md` L147-196 | TRIVIAL/REFACTOR/GREENFIELD/MID_SIZED -- **no BUG_FIX type** |

### What Is Missing

1. **No `BUG_FIX` intent type** -- bug fix goals currently fall into TRIVIAL (if "fix typo") or MID_SIZED. Neither enforces reproduction before coding.

2. **`quick-mode.md` step 10 is a stub** -- "For fix goals: run reproduction, document BEFORE state" has no implementation detail. The researcher/research-analyst doesn't know what "run reproduction" means in practice.

3. **No structured BEFORE state capture format** -- `phase-rules.md` references `## Reality Check (BEFORE)` in `.progress.md` but never defines how it gets there for normal mode (only quick mode detection mentions it).

4. **No bug-specific research phase guidance** -- the research-analyst agent currently does generic web research and codebase analysis. For bugs, it should instead: replicate the bug, capture logs, then research root cause.

5. **No "BUG_FIX" phase sequence** -- the TDD workflow in `phase-rules.md` is designed for REFACTOR/MID_SIZED (extending existing code). A bug fix needs a dedicated Phase 0: Reproduce before Phase 1: TDD cycles.

### Related Specs

| Spec | Relevance | Notes |
|------|-----------|-------|
| `iterative-failure-recovery` | Medium | Failure recovery patterns may overlap with bug fix retry logic |
| `adaptive-interview` | Medium | Interview questions for bug fix goals would differ from feature goals |
| `goal-interview` | High | Goal interview territory doesn't include bug reproduction questions |
| `improve-task-generation` | Medium | Task planner may need BUG_FIX phase templates |

### Existing Patterns to Reuse

- `## Reality Check (BEFORE)` format in `.progress.md` -- already referenced in VF task template
- `[RED]`/`[GREEN]`/`[YELLOW]` task tags -- already supported by spec-executor
- Intent classification routing table -- can add `BUG_FIX` row
- `VF` verification task -- already complete, just needs reliable BEFORE state feeding it
- Quick mode `goalType: "fix"` detection -- exists, needs wiring to normal mode too

---

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | High | All execution primitives exist; changes are additive |
| Effort Estimate | M | 4-6 files to modify, 1 new phase sequence, intent type addition |
| Risk Level | Low | No changes to core loop; only adds new intent routing branch |
| Breaking Changes | None | Existing TRIVIAL/MID_SIZED routing unchanged |

### Implementation Touchpoints (Minimal Set)

1. `references/intent-classification.md` -- add `BUG_FIX` intent type with keywords
2. `references/phase-rules.md` -- add BUG_FIX workflow section (Reproduce -> TDD -> VF)
3. `references/quick-mode.md` -- flesh out step 10 (fix goal reproduction with BEFORE capture)
4. `references/goal-interview.md` -- add bug fix exploration territory (repro steps, expected vs actual)
5. `agents/research-analyst.md` (or parallel-research.md) -- add bug reproduction research mode
6. `agents/task-planner.md` -- add BUG_FIX phase template to task generation rules

### What NOT to Change

- `spec-executor.md` -- RED/GREEN/YELLOW already works
- `stop-watcher.sh` -- loop control is phase-agnostic
- `VF` task template -- already correct, just needs reliable BEFORE state

---

## Recommended Approach

### BUG_FIX Intent Type

Add to `intent-classification.md`:

```text
5. BUG_FIX: Goal contains keywords like:
   - "fix", "bug", "broken", "failing", "error", "crash"
   - "not working", "regression", "issue", "debug", "resolve"
   (distinct from TRIVIAL which requires "fix typo" or "minor")
   -> Min questions: 3, Max questions: 5
   -> Workflow: BUG_FIX (not TDD, not POC)
```

### BUG_FIX Phase Sequence

```text
Phase 0: Reproduce (new -- before any code changes)
  - Understand bug description
  - Run reproduction command (from user or inferred from codebase)
  - Capture full stdout/stderr as BEFORE state in .progress.md
  - Confirm reproduction is consistent (run 2x)
  - Document: expected behavior, actual behavior, reproduction command, exit code

Phase 1: Red (TDD -- existing infrastructure)
  - Write failing test that captures the bug
  - Test MUST fail with the reproduction command's failure mode
  - Commit: test files only

Phase 2: Green (TDD -- existing infrastructure)
  - Write minimum fix to make test pass
  - Verify test passes AND original reproduction command passes
  - Commit: fix files

Phase 3: Yellow (TDD -- existing infrastructure, optional)
  - Refactor: clean up, check for similar bugs in adjacent code
  - Commit: refactor

Phase 4: VF (existing -- reads BEFORE from .progress.md)
  - Re-run original reproduction command
  - Compare with BEFORE state
  - Document AFTER state
```

### BEFORE State Format (Standard)

Define a canonical format so VF task can parse it reliably:

```markdown
## Reality Check (BEFORE)
- **Reproduction command**: `<exact command>`
- **Exit code**: <N>
- **Output**:
  ```
  <exact stdout/stderr>
  ```
- **Expected**: <what should happen>
- **Timestamp**: <ISO date>
```

### Normal Mode vs Quick Mode

| Mode | How Bug Fix Starts |
|------|--------------------|
| Quick mode | `goalType: "fix"` detected at step 10; research phase runs reproduction + BEFORE capture automatically |
| Normal mode | `BUG_FIX` intent classified; goal interview asks for reproduction steps, expected behavior; research-analyst runs reproduction |

### Goal Interview Additions for BUG_FIX

New exploration territory for bug goals:
- "Can you share the exact error message or command output?"
- "What are the steps to reproduce?"
- "What is the expected behavior vs what actually happens?"
- "When did this start? Any recent changes?"
- "Is this a regression (worked before) or a new behavior?"

---

## Quality Commands

No `package.json` found at project root (Ralph Specum is a Claude plugin, not a Node project). Quality checks are performed through the plugin's own verification patterns.

| Type | Command | Source |
|------|---------|--------|
| Lint | Not found | No package.json |
| TypeCheck | Not found | No package.json |
| Test | Not found | No package.json |
| Build | Not applicable | Plugin = markdown files |

**Plugin verification**: Changes are verified by invoking the plugin commands interactively (`/ralph-specum:start`).

---

## Verification Tooling

No automated E2E tooling detected. Ralph Specum is a Claude Code plugin (markdown-based).

**Project Type**: Claude Code Plugin (markdown commands, agents, hooks)
**Verification Strategy**: Manual invocation of plugin commands to verify behavior. Integration testing via `claude --plugin-dir ./plugins/ralph-specum`.

---

## Open Questions

1. **Normal mode research phase**: Should the research-analyst agent have a "bug reproduction mode" that runs the reproduction command, or should this happen in a pre-research step? (Recommendation: pre-research step in `start.md`, keeping research-analyst unchanged.)

2. **Reproduction command source**: In quick mode, where does the reproduction command come from? Options: (a) parse it from the goal text, (b) ask the user (breaks quick mode autonomy), (c) infer from codebase test structure. (Recommendation: parse from goal text; fall back to running existing tests to find the failure.)

3. **Parallel research for bugs**: The current parallel research flow dispatches research teammates. For bugs, should research instead be serial (reproduce -> analyze -> search for fix)? (Recommendation: keep parallel but add a "bug reproduction" teammate that captures BEFORE state.)

---

## Sources

- [Red, Green, Refactor - Codecademy](https://www.codecademy.com/article/tdd-red-green-refactor)
- [James Shore: Red-Green-Refactor](https://www.jamesshore.com/v2/blog/2005/red-green-refactor)
- [Martin Fowler: TDD bliki](https://martinfowler.com/bliki/TestDrivenDevelopment.html)
- [RGRC: Red Green Refactor Commit - Ardalis](https://ardalis.com/rgrc-is-the-new-red-green-refactor-for-test-first-development/)
- [MIT 6.031: Debugging](https://web.mit.edu/6.031/www/fa21/classes/13-debugging/)
- [MIT 6.005: Debugging](https://web.mit.edu/6.005/www/fa15/classes/11-debugging/)
- [Nicole Tietz: A systematic approach to debugging](https://ntietz.com/blog/how-i-debug-2023/)
- [WeAreBrain: 10 debugging techniques 2026](https://wearebrain.com/blog/10-effective-debugging-techniques-for-developers/)
- [IBM: What is Debugging](https://www.ibm.com/think/topics/debugging)
- [BirdEatsBug: Bug Report Writing 101](https://birdeatsbug.com/blog/how-to-write-a-bug-report)
- [Anna Ikoki: How to reproduce a bug](https://annaikoki.medium.com/a-guide-on-how-to-reproduce-a-bug-in-software-development-d57ccc0785b6)
- Internal: `/plugins/ralph-specum/references/intent-classification.md`
- Internal: `/plugins/ralph-specum/references/phase-rules.md`
- Internal: `/plugins/ralph-specum/references/quick-mode.md`
- Internal: `/plugins/ralph-specum/references/goal-interview.md`
- Internal: `/plugins/ralph-specum/agents/spec-executor.md`
