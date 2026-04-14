# Research: engine-state-hardening

## Executive Summary

Critical gaps in the Ralph Specum engine cause execution failures: verification layer contradictions (3 vs 5 layers across docs), HOLD signals ignored due to text-based checks, state drift undetected, partial verification masking CI failures, and incomplete schema. Root cause: critical rules enforced through text interpretation instead of mechanical checks.

## External Research

### Best Practices

**Mechanical over Textual Validation**
- Use exit codes and grep for binary checks (HOLD detection should be `grep -c "\[HOLD\]\|\[PENDING\]\|\[URGENT\]"` → exit code)
- State validation must run pre-loop: compare tasks.md checkmarks with .ralph-state.json taskIndex
- Single source of truth for critical rules (verification layers defined in one place only)

**Schema Completeness**
- All runtime fields must be defined in schema
- Missing fields cause silent failures and state drift

### Prior Art

**Bmalph (comparison benchmark)**
- Has git checkpoint (rollback safety)
- Has circuit breaker (stop after N consecutive failures)
- Has metrics append (per-task performance data)
- Has read-only detection (heartbeat write check)
- Uses infra (git commands, exit codes, counters) over agent coordination text

### Pitfalls to Avoid

- Text-based HOLD check → LLM reasons past the rule ("no new messages" despite active HOLDs)
- Duplicated rule definitions → divergence (verification-layers.md says 3 layers, coordinator-pattern.md says 5)
- Schema drift → nativeTaskMap/nativeSyncEnabled used in code but not in schema

## Codebase Analysis

### Existing Patterns

**Verification Layers (CONTRADICTORY)**
- `coordinator-pattern.md` line ~617: **5 layers** (EXECUTOR_START, Contradiction, Signal, Anti-fabrication, Artifact review)
- `verification-layers.md` line 5: **3 layers** (Contradiction, Signal, Artifact review)
- `implement.md` line ~210: "This covers: **3 layers**"

**State File Usage**
- `.ralph-state.json` used in `implement.md` and `coordinator-pattern.md`
- Fields used but NOT in schema: `nativeTaskMap`, `nativeSyncEnabled`, `nativeSyncFailureCount`, `chat.executor.lastReadLine`

**Native Task Sync**
- 8 sync sections in coordinator-pattern.md (Initial Setup, Bidirectional, Pre-Delegation, Parallel, Failure, Post-Verification, Completion, Modification)
- Each follows graceful degradation pattern (nativeSyncFailureCount >= 3 → disable)

**HOLD Signal Protocol**
- Defined in coordinator-pattern.md chat protocol table
- lastReadLine tracking exists but check is text-based ("no new messages after lastReadLine")

### Dependencies

- Plugin: ralph-specum
- State schema: `schemas/spec.schema.json`
- Reference files: `references/verification-layers.md`, `references/coordinator-pattern.md`, `commands/implement.md`

### Constraints

**Scope Constraints (from roadmap)**
- DON'T restructure coordinator
- DON'T split files (that's Spec 2)
- DON'T add new references
- DON'T change agent files
- Minimal, targeted changes only

## Related Specs

| Spec | Relevance | Relationship | May Need Update |
|------|-----------|--------------|-----------------|
| prompt-diet-refactor | HIGH | Spec 2 depends on Spec 1 verification unification | Will consume Spec 1 changes |
| loop-safety-infra | MEDIUM | Spec 4 adds checkpoint/circuit breaker | Builds on Spec 1 state integrity |
| role-boundaries | LOW | Spec 3 enforces file access rules | Independent |

## Quality Commands

| Type | Command | Source |
|------|---------|--------|
| Schema validation | `jq validate .ralph-state.json schemas/spec.schema.json` | Inferred |
| Verification check | `grep -c "layer" references/verification-layers.md` | Success criterion |
| HOLD test | `grep -c "\[HOLD\]\|\[PENDING\]\|\[URGENT\]" chat.md` | Success criterion |

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Unify verification layers | **HIGH** | Single file edit (verification-layers.md) + reference updates |
| Mechanical HOLD check | **HIGH** | Add grep check to implement.md before delegation |
| State integrity validation | **HIGH** | Add pre-loop validation to implement.md |
| Schema update | **HIGH** | Add 4 missing fields to spec.schema.json |
| CI snapshot separation | **MEDIUM** | Add rule to implement.md for separate reporting |

## Recommendations for Requirements

1. **Verification Contract**: Must specify 5 layers explicitly (0-4)
2. **HOLD Detection**: Must use mechanical grep check (exit code based)
3. **State Validation**: Must run pre-loop (before task 1)
4. **Schema Fields**: Add nativeTaskMap, nativeSyncEnabled, nativeSyncFailureCount, chat.executor.lastReadLine
5. **CI Separation**: Task verification (what Verify command checks) ≠ global CI (ruff/mypy project-wide)

## Open Questions

- None (roadmap provides complete specification)

## Sources

- `docs/ENGINE_ROADMAP.md` (34KB, verified against real code)
- `plugins/ralph-specum/references/verification-layers.md` (current: 3 layers)
- `plugins/ralph-specum/references/coordinator-pattern.md` (current: 5 layers)
- `plugins/ralph-specum/commands/implement.md` (current: 3 layers reference)
- `plugins/ralph-specum/schemas/spec.schema.json` (missing 4 fields)
