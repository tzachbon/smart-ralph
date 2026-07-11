#!/usr/bin/env bats

repo_root() { echo "$BATS_TEST_DIRNAME/.."; }
sync_script() { echo "$(repo_root)/scripts/sync-core-assets.py"; }

setup() {
    export PYTHONDONTWRITEBYTECODE=1
}

@test "core sync: canonical assets are valid and synchronized" {
    run python3 "$(sync_script)" --check
    [ "$status" -eq 0 ]
    [[ "$output" == *"valid and synchronized"* ]]
}

@test "core sync: every declared asset is byte-identical in both plugins" {
    run python3 - "$(repo_root)" <<'PY'
import importlib.util
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
spec = importlib.util.spec_from_file_location("sync_core_assets", root / "scripts/sync-core-assets.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
for relative in module.SHARED_ASSETS:
    expected = (root / "core" / relative).read_bytes()
    for plugin in ("ralph-specum", "ralph-specum-codex"):
        actual = (root / "plugins" / plugin / relative).read_bytes()
        assert actual == expected, f"{plugin}/{relative} differs"
PY
    [ "$status" -eq 0 ]
}

@test "core sync: check detects drift without rewriting the destination" {
    local fixture="$BATS_TEST_TMPDIR/repository"
    mkdir -p "$fixture/scripts" "$fixture/plugins/ralph-specum" "$fixture/plugins/ralph-specum-codex"
    cp -R "$(repo_root)/core" "$fixture/core"
    cp "$(sync_script)" "$fixture/scripts/sync-core-assets.py"
    cp -R "$(repo_root)/plugins/ralph-specum/templates" "$fixture/plugins/ralph-specum/templates"
    cp -R "$(repo_root)/plugins/ralph-specum/schemas" "$fixture/plugins/ralph-specum/schemas"
    cp -R "$(repo_root)/plugins/ralph-specum-codex/templates" "$fixture/plugins/ralph-specum-codex/templates"
    cp -R "$(repo_root)/plugins/ralph-specum-codex/schemas" "$fixture/plugins/ralph-specum-codex/schemas"
    printf '\ndrift\n' >> "$fixture/plugins/ralph-specum/templates/research.md"
    local before
    before="$(sha256sum "$fixture/plugins/ralph-specum/templates/research.md")"

    run python3 "$fixture/scripts/sync-core-assets.py" --check
    [ "$status" -eq 1 ]
    [[ "$output" == *"generated asset differs"* ]]
    [ "$before" = "$(sha256sum "$fixture/plugins/ralph-specum/templates/research.md")" ]

    run python3 "$fixture/scripts/sync-core-assets.py"
    [ "$status" -eq 0 ]
    cmp "$fixture/core/templates/research.md" "$fixture/plugins/ralph-specum/templates/research.md"
}

@test "progress contract: tracked template and legacy migration rules are explicit" {
    run python3 - "$(repo_root)" <<'PY'
import importlib.util
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
spec = importlib.util.spec_from_file_location("sync_core_assets", root / "scripts/sync-core-assets.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
frontmatter = module.parse_frontmatter(root / "core/templates/progress.md")
assert tuple(frontmatter) == ("spec", "phase", "approved_through", "updated")
workflow = (root / "core/rules/workflow.md").read_text()
state = (root / "core/rules/state.md").read_text()
assert "Task checkboxes in `tasks.md` are the authoritative" in workflow
assert "`progress.md` is absent and legacy" in state
assert "Never stage or commit the raw `.progress.md`" in state
PY
    [ "$status" -eq 0 ]
}
