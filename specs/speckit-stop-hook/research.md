---
spec: speckit-stop-hook
phase: research
created: 2026-02-14
generated: auto
---

# Research: speckit-stop-hook

## Executive Summary

Upgrade ralph-speckit's stop-watcher.sh from a passive watcher (always exits 0, logs only) to a self-contained execution loop controller with JSON output, matching the pattern in ralph-specum's stop-watcher.sh. This removes the external ralph-loop plugin dependency.

## Codebase Analysis

### Existing Patterns

| Pattern | Source | Relevance |
|---------|--------|-----------|
| JSON loop control output | `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` (195 lines) | Primary reference — the target pattern |
| Passive stop watcher | `plugins/ralph-speckit/hooks/scripts/stop-watcher.sh` (56 lines) | Current file to upgrade |
| Ralph-loop skill invocation | `plugins/ralph-speckit/commands/implement.md` (line 93) | Must be removed |
| External cancel dependency | `plugins/ralph-speckit/commands/cancel.md` (line 33) | Must be made self-contained |
| State schema | `plugins/ralph-speckit/schemas/speckit-state.schema.json` | Has `additionalProperties: false`, needs updating |
| Existing tests | `tests/stop-hook.bats` + `tests/helpers/setup.bash` | Tests specum only; speckit needs equivalent tests |

### Key Differences: specum vs speckit

| Aspect | specum | speckit |
|--------|--------|--------|
| Spec dir | `./specs/$name/` or multi-root | `.specify/specs/$id-$name/` (fixed) |
| Current spec file | `specs/.current-spec` | `.specify/.current-feature` |
| State file name | `.ralph-state.json` | `.speckit-state.json` |
| Path resolver | `path-resolver.sh` (multi-dir) | None needed (fixed path) |
| Settings file | `.claude/ralph-specum.local.md` | `.claude/ralph-speckit.local.md` (to be created) |
| Coordinator prompt | References `spec-executor` and `qa-engineer` | Same agents (shared) |
| State schema | Allows additional properties | `additionalProperties: false` — must change |

### Dependencies

- **jq**: Required for JSON parsing/output (same as specum)
- **stat**: Used for mtime race-condition check (macOS + Linux)
- **tail/grep**: Used for transcript detection
- **bats-core**: Test framework for stop-hook tests

### Constraints

- Must keep `.specify/` directory structure unchanged
- Must keep `.speckit-state.json` naming
- Must keep `.current-feature` file naming
- No path-resolver.sh — speckit uses fixed paths
- No multi-directory support needed
- Schema changes must be backwards-compatible with existing state files
- Version bump must be major (1.0.0) since ralph-loop dependency removal is breaking

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | High | Direct port of proven pattern from specum |
| Effort Estimate | M | 7 files to modify, plus new test file |
| Risk Level | Low | Well-understood pattern, no novel architecture |

## Recommendations

1. Port specum stop-watcher logic directly, substituting speckit paths/names
2. Remove all ralph-loop references from implement.md; output coordinator prompt directly
3. Make cancel.md self-contained (just delete state file, no external skill)
4. Update schema to allow `additionalProperties: true` for forward compatibility
5. Add speckit-specific test file mirroring existing stop-hook.bats structure
