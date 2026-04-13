# Requirements: Engine State Hardening

## Goal

Fix 5 critical gaps in Ralph Specum engine internals where rules are enforced through text interpretation instead of mechanical checks, causing execution failures (contradictory verification docs, HOLD signals ignored, state drift undetected, partial CI verification, incomplete schema).

## User Stories

### US-1: Unify Verification Layer Documentation

**As a** plugin developer
**I want to** see exactly 5 verification layers in one canonical file
**So that** all coordinator/executor references agree and no agent misinterprets the layer count

**Acceptance Criteria:**
- [ ] AC-1.1: `verification-layers.md` defines 5 layers (Layer 0: EXECUTOR_START, Layer 1: Contradiction, Layer 2: Signal, Layer 3: Anti-fabrication, Layer 4: Artifact Review)
- [ ] AC-1.2: `verification-layers.md` contains no mention of "3 layers" or "all 3"
- [ ] AC-1.3: `implement.md` references "5 layers" (not 3) when listing verification-layers.md coverage
- [ ] AC-1.4: `coordinator-pattern.md` Verification Layers section says "defined in verification-layers.md" instead of inlining Layer 1-4 definitions

### US-2: Mechanical HOLD Signal Detection

**As a** coordinator agent
**I want** a grep-based check for HOLD/PENDING/URGENT signals before every delegation
**So that** blocking signals are never missed due to LLM text interpretation failures

**Acceptance Criteria:**
- [ ] AC-2.1: `implement.md` coordinator prompt includes a pre-delegation step: `grep -c "\[HOLD\]\|\[PENDING\]\|\[URGENT\]" "$SPEC_PATH/chat.md"` (exit code > 0 = block)
- [ ] AC-2.2: When HOLD detected, delegation is blocked and logged to `.progress.md`: `"COORDINATOR BLOCKED: active HOLD/PENDING/URGENT signal in chat.md for task $taskIndex"`
- [ ] AC-2.3: Resolved signals tracked: either `[HOLD:resolved]` markup in chat.md or signals moved under `## Resolved Signals` section

### US-3: State Integrity Validation

**As a** coordinator agent
**I want** the loop to validate state file against tasks.md before starting
**So that** state drift (stale taskIndex) is detected and corrected before execution

**Acceptance Criteria:**
- [ ] AC-3.1: `implement.md` Step 4 (Execute Task Loop) begins with a state integrity check: count `[x]` in tasks.md, compare with `taskIndex` in `.ralph-state.json`
- [ ] AC-3.2: If `taskIndex < completed_count`: set `taskIndex = completed_count`, log `"STATE DRIFT: taskIndex was $old, corrected to $completed_count"` to `.progress.md`
- [ ] AC-3.3: If `taskIndex > completed_count` and `taskIndex < totalTasks`: log warning but do NOT correct (tasks may have been unmarked intentionally)

### US-4: Schema Completeness

**As a** plugin developer
**I want** all runtime state fields defined in the JSON schema
**So that** schema validation catches missing/malformed fields instead of silent failures

**Acceptance Criteria:**
- [ ] AC-4.1: `spec.schema.json` state definition includes `nativeTaskMap` (object, default {})
- [ ] AC-4.2: `spec.schema.json` state definition includes `nativeSyncEnabled` (boolean, default true)
- [ ] AC-4.3: `spec.schema.json` state definition includes `nativeSyncFailureCount` (integer, minimum 0, default 0)
- [ ] AC-4.4: `spec.schema.json` state definition includes `chat` object with `executor.lastReadLine` (integer, minimum 0, default 0)

### US-5: CI Snapshot Separation

**As a** coordinator agent
**I want** task verification results reported separately from global CI results
**So that** passing task-level checks don't mask project-wide CI failures (and vice versa)

**Acceptance Criteria:**
- [ ] AC-5.1: `implement.md` coordinator prompt includes a rule: task `Verify` command results (task-scoped) must be reported separately from global CI commands (`ruff check .`, `mypy .`, project-wide linting)
- [ ] AC-5.2: Anti-fabrication Layer 3 must run BOTH the task's `Verify` command AND any global CI check independently; both must pass for the layer to pass
- [ ] AC-5.3: If task Verify passes but global CI fails: log `"TASK VERIFY PASS but GLOBAL CI FAIL"` to `.progress.md`, do NOT advance taskIndex

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | `verification-layers.md` is canonical 5-layer source | High | AC-1.1, AC-1.2 |
| FR-2 | `implement.md` references 5 layers | High | AC-1.3 |
| FR-3 | `coordinator-pattern.md` defers to verification-layers.md for layer definitions | High | AC-1.4 |
| FR-4 | Pre-delegation HOLD check is grep-based | High | AC-2.1 |
| FR-5 | HOLD block logs to .progress.md | High | AC-2.2 |
| FR-6 | Resolved signals tracked in chat.md | Medium | AC-2.3 |
| FR-7 | Pre-loop state integrity check compares taskIndex vs [x] count | High | AC-3.1 |
| FR-8 | Drift correction: taskIndex < completed → correct | High | AC-3.2 |
| FR-9 | Drift warning: taskIndex > completed → warn only | Medium | AC-3.3 |
| FR-10 | Schema defines nativeTaskMap, nativeSyncEnabled, nativeSyncFailureCount | High | AC-4.1, AC-4.2, AC-4.3 |
| FR-11 | Schema defines chat.executor.lastReadLine | High | AC-4.4 |
| FR-12 | Task Verify and global CI reported separately | High | AC-5.1 |
| FR-13 | Anti-fabrication layer runs both task and global checks | High | AC-5.2 |
| FR-14 | Task passes + global fails = no advance | High | AC-5.3 |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Minimal diff size | Lines changed per file | < 30 lines per file (excluding verification-layers.md rewrite) |
| NFR-2 | No behavior change | Existing test scenarios | All existing execution flows preserved |
| NFR-3 | Grep-verifiable | Automated validation | Every AC has a grep/diff command that can verify it |

## Glossary

- **Layer 0 (EXECUTOR_START)**: Signal that spec-executor was actually invoked (not coordinator self-implementing)
- **Layer 1 (Contradiction)**: Detects executor claiming TASK_COMPLETE alongside failure phrases
- **Layer 2 (Signal)**: Verifies TASK_COMPLETE is explicitly present in output
- **Layer 3 (Anti-fabrication)**: Runs verify commands independently to catch fabricated results
- **Layer 4 (Artifact Review)**: Periodic spec-reviewer invocation for implementation quality
- **State drift**: taskIndex in .ralph-state.json diverges from actual [x] count in tasks.md
- **Global CI**: Project-wide linting/type-checking (ruff, mypy) separate from task-scoped Verify commands

## Out of Scope

- Coordinator restructuring (Spec 2: prompt-diet-refactor)
- File splitting or new reference files (Spec 2)
- Agent file changes (Spec 3: role-boundaries)
- Loop safety infrastructure (Spec 4: loop-safety-infra)
- stop-watcher.sh changes
- New test files

## Dependencies

- Ralph Specum plugin must be installed and loaded
- `jq` available for state file manipulation
- `grep` with `-c` and `-e` flag support

## Success Criteria

- `grep -c "all 3" plugins/ralph-specum/references/verification-layers.md` returns 0
- `grep -c "Layer [0-4]" plugins/ralph-specum/references/verification-layers.md` returns >= 5
- `grep -c "\[HOLD\]" plugins/ralph-specum/commands/implement.md` returns >= 1
- `grep -c "STATE DRIFT" plugins/ralph-specum/commands/implement.md` returns >= 1
- `jq '.definitions.state.properties | has("nativeTaskMap")' plugins/ralph-specum/schemas/spec.schema.json` returns true
- `jq '.definitions.state.properties | has("nativeSyncEnabled")' plugins/ralph-specum/schemas/spec.schema.json` returns true
- `jq '.definitions.state.properties | has("nativeSyncFailureCount")' plugins/ralph-specum/schemas/spec.schema.json` returns true
- `jq '.definitions.state.properties.chat.properties.executor.properties | has("lastReadLine")' plugins/ralph-specum/schemas/spec.schema.json` returns true
- `grep -c "GLOBAL CI" plugins/ralph-specum/commands/implement.md` returns >= 1

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| verification-layers.md rewrite introduces inconsistencies | High | Diff against coordinator-pattern.md Layer 0-4 definitions |
| HOLD check false positives (stale signals) | Medium | Resolved signal tracking (AC-2.3) |
| State drift correction skips intentionally unmarked tasks | Low | Only correct when taskIndex < completed_count |

## Verification Contract

**Project type**: library

**Entry points**:
- `plugins/ralph-specum/references/verification-layers.md` (canonical verification doc)
- `plugins/ralph-specum/references/coordinator-pattern.md` (coordinator logic)
- `plugins/ralph-specum/commands/implement.md` (execution entry point)
- `plugins/ralph-specum/schemas/spec.schema.json` (state schema)

**Observable signals**:
- PASS looks like: grep commands in Success Criteria all return expected counts; `jq` validates schema fields exist
- FAIL looks like: "3 layers" text remains in verification-layers.md; grep for HOLD check absent from implement.md; schema fields missing; no "GLOBAL CI" in implement.md

**Hard invariants**:
- No changes to agent files (spec-executor.md, task-planner.md, etc.)
- No new files created
- No changes to stop-watcher.sh
- Existing execution flow preserved (same delegation, same state update pattern)

**Seed data**: Existing plugin files at their current content (read in research phase)

**Dependency map**: None (this spec modifies engine internals with no runtime dependencies on other specs)

**Escalate if**:
- verification-layers.md rewrite exceeds 50% of original content (scope creep)
- coordinator-pattern.md changes break cross-reference consistency
- Schema update breaks existing .ralph-state.json files (backwards compatibility)

## Unresolved Questions

- None. Roadmap provides complete specification for all 5 changes.

## Next Steps

1. Get user approval on requirements
2. Generate design.md with exact edit locations per file
3. Generate tasks.md with surgical edit tasks per AC
