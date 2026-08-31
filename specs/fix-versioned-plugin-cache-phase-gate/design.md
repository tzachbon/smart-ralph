---
spec: fix-versioned-plugin-cache-phase-gate
phase: design
created: 2026-08-31
---

# Design: Versioned Plugin-Cache Phase Gate

## Approach

Fix the shared root-cause resolver, `packaged_core_contract()`, in both shipped `phase_gate.py` copies. Keep its current direct package-name lookup. Only when `plugin_root.name` is unknown, inspect `plugin_root / "skills" / <known-core> / "SKILL.md"` for each `PACKAGED_CORES` entry. Use the package key only when exactly one path is a file; otherwise raise the existing `UNRECOGNIZED_PLUGIN_ROOT` error.

```text
package_key = plugin_root.name
if package_key not in PACKAGED_CORES:
    matches = [key for key, core in PACKAGED_CORES.items()
               if (plugin_root / "skills" / core / "SKILL.md").is_file()]
    if len(matches) != 1:
        fail(UNRECOGNIZED_PLUGIN_ROOT, existing message)
    package_key = matches[0]
```

The established resource lookup then continues unchanged, using `package_key` to obtain the core name and required reference names.

## Behavior and Error Handling

- Recognized `ralph-specum` and `ralph-specum-codex` roots retain their current behavior, including later resource validation.
- A versioned or otherwise arbitrary cache root succeeds only when exactly one known core `SKILL.md` is present.
- Zero matches and multiple matches retain the exact `UNRECOGNIZED_PLUGIN_ROOT` failure; the resolver must not choose the first match or infer a parent cache directory.
- No configuration, new dependency, or new public interface is introduced.

## File Changes

| File | Change |
|---|---|
| `plugins/ralph-specum/scripts/phase_gate.py` | Add the exact-one-core fallback. |
| `plugins/ralph-specum-codex/scripts/phase_gate.py` | Apply the byte-identical mirror change. |
| `tests/phase-gates.bats` | Add a real `record-skill-load` fixture rooted under an arbitrary version directory. |
| Plugin manifests and Claude marketplace entry | Bump `4.12.0` to `4.12.1`. |
| `tests/interview-framework.bats`, `tests/codex-phase-flow.bats` | Update fixed version assertions to `4.12.1`. |

`.agents/plugins/marketplace.json` is unchanged because its local Codex-plugin entry has no version field.

## Regression Strategy

Build the fixture inside the existing Bats temporary directory: copy the Codex helper, `interview-framework-codex/SKILL.md`, and its two required references into a `.../4.11.0/` root. Generate a matching manifest and discovery entry against that copied helper, then run its real `record-skill-load` command.

Assert all three cases:

1. Only the Codex core exists: success and the copied core/reference paths validate.
2. No known core exists: `UNRECOGNIZED_PLUGIN_ROOT`.
3. Both known cores exist: `UNRECOGNIZED_PLUGIN_ROOT`.

Keep the existing `cmp` assertion as the parity check for both production helpers.

## Verification

1. Run the new regression red against the pre-fix helper, then green after the resolver change.
2. Run `python3 -m py_compile` on both helpers and `cmp` them.
3. Run `bats tests/phase-gates.bats` locally when available; CI continues to run `bats tests/*.bats`.
4. Run the version-sync/fixed-version tests and `git diff --check`.

## Risks

The only behavioral risk is accepting an ambiguous package. Exact match-count enforcement and the zero/multiple regression cases prevent it.
