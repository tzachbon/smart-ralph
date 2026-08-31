# Tasks: Fix Versioned Plugin-Cache Phase Gate

## Overview

Total tasks: 5

Intent: focused bug fix using a TDD red-green cycle. The skipped quick prototype is sufficient evidence; no separate prototype, dependency, refactor, push, or PR work is needed.

## Completion Criteria

- A versioned Codex cache root with exactly one known core completes the real `record-skill-load` path.
- Zero and multiple known-core layouts still return `UNRECOGNIZED_PLUGIN_ROOT`.
- Both shipped helpers remain byte-identical and release metadata is synchronized at `4.12.1`.
- Local verification is complete; quick mode skips the remote lifecycle.

## Phase 1: Red-Green-Yellow Cycles

- [x] 1.1 [RED] Add the versioned Codex cache regression fixture
  - **Do**:
    1. Add one focused Bats test to `tests/phase-gates.bats` that copies the Codex helper, `interview-framework-codex/SKILL.md`, and its two required references beneath an arbitrary `4.11.0` cache-root directory.
    2. Build matching discovery and skill-load JSON for that copied package and invoke its real `record-skill-load` command.
    3. Assert one known core is expected to succeed, while zero known cores and both known cores must return `UNRECOGNIZED_PLUGIN_ROOT`.
  - **Files**: `tests/phase-gates.bats`
  - **Done when**: Before the resolver fix, the one-core assertion fails specifically with `UNRECOGNIZED_PLUGIN_ROOT`; the zero- and multiple-core assertions already prove the preserved rejection behavior.
  - **Verify**: `command -v bats >/dev/null && bash -c 'bats tests/phase-gates.bats --filter "versioned Codex cache root"; test $? -ne 0'`
  - **Commit**: `test(phase-gate): red - cover versioned Codex cache roots`
  - _Requirements: FR-1, FR-2, FR-4_
  - _Design: Regression Strategy_

- [x] 1.2 [GREEN] Resolve exactly one packaged core from an unknown root
  - **Do**:
    1. Keep the recognized-root lookup in `packaged_core_contract()` unchanged.
    2. For an unrecognized root only, collect `PACKAGED_CORES` entries whose `skills/<core>/SKILL.md` exists and accept the package key only when the count is exactly one.
    3. Preserve the existing `UNRECOGNIZED_PLUGIN_ROOT` error for zero or multiple matches, then apply the same bytes to the mirrored helper.
  - **Files**: `plugins/ralph-specum/scripts/phase_gate.py`, `plugins/ralph-specum-codex/scripts/phase_gate.py`
  - **Done when**: The red fixture passes, direct package roots retain their current mapping, and both helper files compare equal.
  - **Verify**: `command -v bats >/dev/null && bats tests/phase-gates.bats --filter "versioned Codex cache root" && cmp plugins/ralph-specum/scripts/phase_gate.py plugins/ralph-specum-codex/scripts/phase_gate.py`
  - **Commit**: `fix(phase-gate): support versioned plugin cache roots`
  - _Requirements: FR-1, FR-2, FR-3_
  - _Design: Approach; Behavior and Error Handling_

## Phase 2: Release Compatibility

- [x] 2.1 Bump the two plugin manifests and Claude marketplace entry
  - **Do**:
    1. Change the Ralph Specum version from `4.12.0` to `4.12.1` in both modified plugin manifests.
    2. Change only the `ralph-specum` entry in the Claude marketplace to `4.12.1`.
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`, `plugins/ralph-specum-codex/.codex-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  - **Done when**: Both manifests and the marketplace entry report exactly `4.12.1`; no unrelated marketplace entry changes.
  - **Verify**: `bash tests/helpers/version-sync.sh && jq -e '.plugins[] | select(.name == "ralph-specum") | .version == "4.12.1"' .claude-plugin/marketplace.json`
  - **Commit**: `chore(ralph-specum): bump plugin version to 4.12.1`
  - _Requirements: FR-5_

- [x] 2.2 Update fixed version expectations
  - **Do**:
    1. Update the Ralph Specum marketplace-version assertion to `4.12.1`.
    2. Update the Codex phase-flow manifest-version assertion to `4.12.1`.
  - **Files**: `tests/interview-framework.bats`, `tests/codex-phase-flow.bats`
  - **Done when**: Both fixed assertions agree with the released manifest version and still test their original contracts.
  - **Verify**: `rg -n '4\.12\.1' tests/interview-framework.bats tests/codex-phase-flow.bats`
  - **Commit**: `test(ralph-specum): align fixed version assertions`
  - _Requirements: FR-5_

## Phase 3: Final Local Quality Gate

- [x] VF [VERIFY] Validate the cache fix, release synchronization, and diff
  - **Do**:
    1. Compile both helpers from their source bytes without creating cache files.
    2. Run the Bats fixture's manual copied-cache reproduction: the one-core `record-skill-load` invocation must return `0` and its selected core/reference paths must be inside the temporary `4.11.0` root; the zero- and both-core variants must return `2` with `UNRECOGNIZED_PLUGIN_ROOT`.
    3. Run parity, version, Bats-when-available, and whitespace checks; do not push, open a PR, or perform remote lifecycle work.
  - **Files**: None
  - **Done when**: Python compilation succeeds, the manual cache reproduction has the required three outcomes, helpers are byte-identical, versions are `4.12.1`, applicable Bats tests pass, and `git diff --check` is clean.
  - **Verify**:
    ```bash
    python3 - <<'PY'
    from pathlib import Path
    for source in (
        "plugins/ralph-specum/scripts/phase_gate.py",
        "plugins/ralph-specum-codex/scripts/phase_gate.py",
    ):
        compile(Path(source).read_text(encoding="utf-8"), source, "exec")
    PY
    # Run the fixture's three copied-cache record-skill-load commands.
    cmp plugins/ralph-specum/scripts/phase_gate.py plugins/ralph-specum-codex/scripts/phase_gate.py
    bash tests/helpers/version-sync.sh
    jq -e '.plugins[] | select(.name == "ralph-specum") | .version == "4.12.1"' .claude-plugin/marketplace.json
    if command -v bats >/dev/null; then bats tests/phase-gates.bats tests/interview-framework.bats tests/codex-phase-flow.bats; else echo 'Bats unavailable locally; CI runs the Bats suite'; fi
    git diff --check
    ```
  - **Commit**: None
  - _Requirements: FR-1, FR-2, FR-3, FR-4, FR-5; NFR-1, NFR-2, NFR-3_

## Dependencies

```text
1.1 [RED] -> 1.2 [GREEN] -> 2.1 -> 2.2 -> VF [VERIFY]
```

## Notes

- No yellow refactor task is needed: the resolver fallback is the complete minimal implementation and the mirror parity test guards against drift.
- Remote lifecycle skipped: prototype evidence stayed local.
