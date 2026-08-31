---
spec: fix-versioned-plugin-cache-phase-gate
phase: requirements
created: 2026-08-31
---

# Requirements: Versioned Plugin-Cache Phase Gate

## Problem Statement

`phase_gate.py` rejects a valid Codex plugin installed beneath a version directory because it identifies the package from the immediate directory name. The deterministic reproduction and root cause are documented in [research.md](research.md).

## Goal

Allow the shared phase-gate helper to identify exactly one packaged core interview skill from a versioned cache root, while retaining current behavior for recognized roots and malformed layouts.

## User Story

### US-1: Load a versioned Codex package

**As a** Codex plugin user
**I want** `record-skill-load` to work from an installed versioned plugin-cache directory
**So that** Ralph Specum phases can start and load their required core resources.

**Acceptance Criteria:**

- Given a copied Codex package rooted at an arbitrary version directory with only `skills/interview-framework-codex/SKILL.md` and its required references, when `record-skill-load` runs, then it succeeds and resolves those exact files.
- Given a package rooted directly at `ralph-specum` or `ralph-specum-codex`, when `record-skill-load` runs, then its existing core-resolution behavior remains valid.
- Given an unknown root with zero known core skill files, or with both known core skill files, when `record-skill-load` runs, then it fails with `UNRECOGNIZED_PLUGIN_ROOT`.

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | `packaged_core_contract()` MUST retain its direct lookup for recognized package-root names. For another root name, it MUST inspect each known packaged core at `skills/<core>/SKILL.md` and use its package key only when exactly one exists. | Must | US-1 direct-root and versioned-root criteria |
| FR-2 | The fallback MUST keep the existing `UNRECOGNIZED_PLUGIN_ROOT` failure when zero or more than one known core matches. It MUST not choose the first match or infer a cache-parent name. | Must | US-1 malformed-layout criterion |
| FR-3 | The same resolver change MUST be applied byte-for-byte to `plugins/ralph-specum/scripts/phase_gate.py` and `plugins/ralph-specum-codex/scripts/phase_gate.py`; the existing parity check must remain green. | Must | Helper comparison test passes |
| FR-4 | A focused regression in `tests/phase-gates.bats` MUST exercise the real `record-skill-load` path from a versioned Codex cache fixture, including one-core success and zero-/multiple-core rejection. | Must | The test is red before the resolver change and green after it |
| FR-5 | Release metadata MUST move from `4.12.0` to `4.12.1` in `plugins/ralph-specum/.claude-plugin/plugin.json`, `plugins/ralph-specum-codex/.codex-plugin/plugin.json`, and the `ralph-specum` entry in `.claude-plugin/marketplace.json`. Fixed expectations in `tests/interview-framework.bats` and `tests/codex-phase-flow.bats` MUST also become `4.12.1`. | Must | Version-sync and fixed-version assertions pass |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Resolution is deterministic. | Matching package cores | Exactly one match succeeds; zero or multiple fail. |
| NFR-2 | The fix has no new runtime dependency or configuration. | Added dependencies/configuration | 0 |
| NFR-3 | Existing package layouts remain compatible. | Direct-root regression | Both recognized package roots retain their current mapping. |

## Glossary

- **Recognized package root**: A root directory named `ralph-specum` or `ralph-specum-codex`.
- **Versioned cache root**: The arbitrary version-directory root from which an installed plugin helper executes.
- **Known core**: A `PACKAGED_CORES` entry whose packaged `skills/<core>/SKILL.md` is present.

## Out of Scope

- Changing phase interview, discovery, manifest, or resource-validation semantics beyond package-root identification.
- Adding cache-layout configuration, plugin dependencies, or support for unknown core skill names.
- Updating `.agents/plugins/marketplace.json`, which has no version field for its local Codex plugin source.

## Dependencies

- Python standard library (`pathlib.Path`) and existing `PACKAGED_CORES` / `PACKAGED_CORE_RESOURCES` constants.
- Bats coverage in CI; the local environment may not provide the `bats` executable.

## Success Criteria

- The versioned-cache reproduction from [research.md](research.md) succeeds with the correct Codex core and reference paths.
- Zero- and multiple-core fixtures still produce `UNRECOGNIZED_PLUGIN_ROOT`.
- Both helper copies compare equal, the targeted Bats regression passes where Bats is available, and the release metadata is synchronized at `4.12.1`.

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| An ambiguous cache layout silently selects a core. | Medium | Require an exact count of one and test zero/multiple matches. |
| Plugin copies or release versions drift. | Low | Retain parity and version-sync assertions. |

## Unresolved Questions

- None.
