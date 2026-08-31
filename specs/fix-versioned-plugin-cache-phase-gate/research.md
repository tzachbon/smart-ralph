---
spec: fix-versioned-plugin-cache-phase-gate
phase: research
created: 2026-08-31
---

# Research: fix-versioned-plugin-cache-phase-gate

## Executive Summary

Issue #147 is reproducible: `record-skill-load` rejects a valid Codex package when its immediate package directory is a version (for example, `4.11.0`) rather than `ralph-specum-codex`. The smallest safe repair is a content-based fallback in `packaged_core_contract()`: for an unknown directory name, accept exactly one known core whose `skills/<core>/SKILL.md` exists; retain `UNRECOGNIZED_PLUGIN_ROOT` for zero or multiple matches.

Both shipped helpers are byte-identical, so update both with the same bytes and keep the existing equality test. This is a patch-level plugin fix with no new dependency or abstraction.

## External Research

### Best Practices

- The primary issue explicitly specifies content-based discovery, exactly-one-match acceptance, and preserved zero/multiple-match errors: [Issue #147](https://github.com/tzachbon/smart-ralph/issues/147).
- Use the existing `PACKAGED_CORES`, `PACKAGED_CORE_RESOURCES`, `Path`, and `PhaseGateError`; no dependency is needed.

### Prior Art

- Existing recognized-root behavior maps package keys through `PACKAGED_CORES` and then derives `SKILL.md`, `algorithm.md`, and `domain-modeling.md` from that root.

### Pitfalls to Avoid

- Do not select the first discovered core: ambiguity must continue to fail.
- Do not infer a cache parent directory; the installed version directory is intentionally arbitrary.
- Do not alter behavior for a recognized package key, including its current later file-validation behavior.

## Codebase Analysis

### Existing Patterns

- `packaged_core_contract()` uses `Path(__file__).resolve().parent.parent` and immediately looks up `plugin_root.name` in `PACKAGED_CORES` at `plugins/ralph-specum-codex/scripts/phase_gate.py:296` (identical in `plugins/ralph-specum/scripts/phase_gate.py:296`).
- `validate_skill_load()` calls this resolver before accepting a core receipt; `record-skill-load`, stale-load validation, and artifact-load validation all flow through it (`plugins/ralph-specum-codex/scripts/phase_gate.py:332`, `:676`, `:716`, `:934`). Fixing the shared resolver covers every caller.
- The copies have the same SHA-256 (`a45af8e033d7bca651219961f170435e423da324b17c8328353ba5fe708a947f`) and `tests/phase-gates.bats:202` already asserts `cmp` equality.

### Reproduction

Executed a valid start-phase `record-skill-load` fixture from this temporary package layout (the helper and the Codex core skill plus both references were copied from the repository):

```text
<tmp>/cache/smart-ralph/ralph-specum-codex/4.11.0/
  scripts/phase_gate.py
  skills/interview-framework-codex/SKILL.md
  skills/interview-framework-codex/references/{algorithm.md,domain-modeling.md}

python3 <tmp>/cache/smart-ralph/ralph-specum-codex/4.11.0/scripts/phase_gate.py \
  record-skill-load <tmp>/state.json --input <tmp>/manifest.json
```

```text
ERROR: UNRECOGNIZED_PLUGIN_ROOT: phase gate helper is outside a recognized packaged plugin root
```

The manifest has matching hashes, discovery, and context digest; the only differing condition is the valid versioned immediate directory. This is a deterministic, red-capable reproduction of the reported command failure.

### Dependencies

- Python standard library only (`pathlib.Path.is_file()` is sufficient).
- Bats test coverage already exists in `tests/phase-gates.bats`; the local image lacks `bats` (`bats: command not found`). CI installs it and runs `bats tests/*.bats` in `.github/workflows/bats-tests.yml:37`.

### Constraints

- The fallback must inspect only `plugin_root / "skills" / core_name / "SKILL.md"` for each key in `PACKAGED_CORES`; use the key only when the match count is exactly one.
- Keep the existing `UNRECOGNIZED_PLUGIN_ROOT` error for zero and multiple matches.
- The repository rules require a patch version bump for each modified plugin. Current manifests are `4.12.0`; bump to `4.12.1` in both plugin manifests and the Claude marketplace entry. Update the two hard-coded version assertions in `tests/interview-framework.bats:155` and `tests/codex-phase-flow.bats:19-23`.
- `tests/helpers/version-sync.sh:3-9` requires the Claude and Codex plugin manifests to match; `.github/workflows/codex-version-check.yml:18-100` also checks a Codex package change has a version bump.

## Related Specs

| Spec | Relevance | Relationship | May Need Update |
|------|-----------|--------------|-----------------|
| None identified | Low | Isolated package-root resolution fix | No |

### Coordination Notes

No cross-spec coordination is needed. The two plugin distributions must remain synchronized.

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | High | A small fallback in the shared resolver fixes every gate caller. |
| Effort Estimate | S | Two identical helper edits, one focused regression test, and required version updates. |
| Risk Level | Low | Exact-match selection preserves rejection of malformed and ambiguous layouts. |

## Recommendations for Requirements

1. In both `phase_gate.py` copies, retain direct lookup for known roots; otherwise collect `PACKAGED_CORES` keys whose packaged core `SKILL.md` exists, require exactly one, and use that key for the existing resource lookup.
2. Add a focused `tests/phase-gates.bats` regression covering a versioned Codex layout with one core (success and exact returned skill/reference paths), no cores (same error), and both cores (same error). The existing byte-equality test covers the mirrored helper after both files are updated identically.
3. Bump `4.12.0` to `4.12.1` in `plugins/ralph-specum/.claude-plugin/plugin.json`, `plugins/ralph-specum-codex/.codex-plugin/plugin.json`, and `.claude-plugin/marketplace.json`, then update the two fixed-version Bats assertions.

## Open Questions

- None. The issue defines the required fallback and ambiguity behavior.

## Sources

- [Issue #147: versioned plugin-cache failure and required behavior](https://github.com/tzachbon/smart-ralph/issues/147)
- `plugins/ralph-specum-codex/scripts/phase_gate.py:52-59,296-307,332-456,676-740,934-1021`
- `plugins/ralph-specum/scripts/phase_gate.py:52-59,296-307` (byte-identical mirror)
- `tests/phase-gates.bats:1-220,928-1030`
- `.github/workflows/bats-tests.yml:37-43`
- `tests/helpers/version-sync.sh:3-9`, `.github/workflows/codex-version-check.yml:18-100`
- `plugins/ralph-specum/.claude-plugin/plugin.json`, `plugins/ralph-specum-codex/.codex-plugin/plugin.json`, `.claude-plugin/marketplace.json`
