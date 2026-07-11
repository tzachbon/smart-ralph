#!/usr/bin/env bats

repo_root() { echo "$BATS_TEST_DIRNAME/.."; }

@test "native packages: serialized files, manifests, frontmatter, and resources are valid" {
    run python3 "$(repo_root)/scripts/validate-packages.py"
    [ "$status" -eq 0 ]
    [[ "$output" == *"native packages are valid"* ]]
}

@test "native packages: Codex has no hook or custom-agent requirement" {
    local root="$(repo_root)/plugins/ralph-specum-codex"
    [ -z "$(find "$root/hooks" -type f -print -quit 2>/dev/null)" ]
    [ -z "$(find "$root/agent-configs" -type f -print -quit 2>/dev/null)" ]
    ! grep -q '"hooks"' "$root/.codex-plugin/plugin.json"
}

@test "native packages: both adapters use tracked progress and keep legacy logs migration-only" {
    local root="$(repo_root)"
    grep -q 'progress.md' "$root/core/rules/state.md"
    grep -q 'Never stage or commit the raw `.progress.md`' "$root/core/rules/state.md"
    ! grep -R -q 'git add .*\.progress.md' "$root/plugins/ralph-specum" "$root/plugins/ralph-specum-codex"
}

@test "native packages: isolated Claude install resolves plugin-root resources" {
    local install_root plugin
    install_root="$(mktemp -d)"
    plugin="$install_root/ralph-specum"
    cp -R "$(repo_root)/plugins/ralph-specum" "$plugin"

    run python3 - "$plugin" <<'PY'
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1]).resolve()
missing = []
pattern = re.compile(r"\$\{CLAUDE_PLUGIN_ROOT\}/([A-Za-z0-9_./-]+)")
for path in root.rglob("*"):
    if not path.is_file():
        continue
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        continue
    for relative in pattern.findall(text):
        target = root / relative.rstrip("./")
        if not target.exists():
            missing.append(f"{path.relative_to(root)}: {relative}")
assert not missing, "\n".join(missing)
PY
    rm -rf "$install_root"
    [ "$status" -eq 0 ]
}
