#!/usr/bin/env bats

repo_root() {
    echo "$BATS_TEST_DIRNAME/.."
}

plugin_root() {
    echo "$(repo_root)/plugins/ralph-specum-codex"
}

all_codex_skills() {
    cat <<'EOF'
ralph-specum
ralph-specum-start
ralph-specum-triage
ralph-specum-research
ralph-specum-requirements
ralph-specum-design
ralph-specum-tasks
ralph-specum-implement
ralph-specum-status
ralph-specum-switch
ralph-specum-cancel
ralph-specum-index
ralph-specum-refactor
ralph-specum-feedback
ralph-specum-help
EOF
}

helper_codex_skills() {
    cat <<'EOF'
ralph-specum-start
ralph-specum-triage
ralph-specum-research
ralph-specum-requirements
ralph-specum-design
ralph-specum-tasks
ralph-specum-implement
ralph-specum-status
ralph-specum-switch
ralph-specum-cancel
ralph-specum-index
ralph-specum-refactor
ralph-specum-feedback
ralph-specum-help
EOF
}

assert_python() {
    local script
    script="$1"
    shift
    run env ASSERT_PYTHON_SCRIPT="$script" python3 - "$@" <<'PY'
import os
import sys
from pathlib import Path

ROOT = Path(sys.argv[1])
SCRIPT = os.environ["ASSERT_PYTHON_SCRIPT"]
namespace = {"Path": Path, "ROOT": ROOT, "sys": sys}
exec(SCRIPT, namespace)
PY
    [ "$status" -eq 0 ]
}

@test "codex platform: legacy Codex wrapper files are gone" {
    local root
    root="$(repo_root)"

    [ ! -e "$root/tests/codex-wrapper.bats" ]

    if [ -e "$root/AGENTS.md" ]; then
        run cmp -s "$root/AGENTS.md" "$root/CLAUDE.md"
        [ "$status" -eq 0 ]
    fi

    if [ -d "$root/.agents/skills" ]; then
        run find "$root/.agents/skills" -maxdepth 1 -mindepth 1 -type d \( -name 'ralph-specum' -o -name 'ralph-specum-*' \)
        [ "$status" -eq 0 ]
        [ -z "$output" ]
    fi
}

@test "codex platform: each installable skill has required files" {
    local root skill
    root="$(plugin_root)"

    while IFS= read -r skill; do
        [ -f "$root/skills/$skill/SKILL.md" ]
        [ -f "$root/skills/$skill/agents/openai.yaml" ]
    done < <(all_codex_skills)
}

@test "codex platform: all Codex skill metadata disables implicit invocation" {
    local root
    root="$(repo_root)"

    assert_python '
for skill in (ROOT / "plugins/ralph-specum-codex/skills").glob("ralph-specum*"):
    if not skill.is_dir():
        continue
    text = (skill / "agents/openai.yaml").read_text()
    assert "allow_implicit_invocation: false" in text, skill.name
' "$root"
}

@test "codex platform: primary skill ships shared resources" {
    local root proot
    root="$(repo_root)"
    proot="$(plugin_root)"

    [ -f "$proot/README.md" ]
    [ -f "$proot/references/workflow.md" ]
    [ -f "$proot/references/state-contract.md" ]
    [ -f "$proot/references/path-resolution.md" ]
    [ -f "$proot/references/parity-matrix.md" ]
    [ -f "$proot/scripts/merge_state.py" ]
    [ -f "$proot/scripts/count_tasks.py" ]
    [ -f "$proot/scripts/resolve_spec_paths.py" ]
    [ -f "$proot/assets/bootstrap/AGENTS.md" ]
    [ -f "$proot/assets/bootstrap/ralph-specum.local.md" ]
}

@test "codex platform: helper skills stay self-contained" {
    local root skill skill_text metadata_text
    root="$(plugin_root)"

    while IFS= read -r skill; do
        skill_text="$(<"$root/skills/$skill/SKILL.md")"
        metadata_text="$(<"$root/skills/$skill/agents/openai.yaml")"

        [[ "$skill_text" != *"../"* ]]
        [[ "$skill_text" != *"/home/"* ]]
        [[ "$skill_text" != *"plugins/ralph-specum-codex/skills/ralph-specum/"* ]]
        [[ "$metadata_text" != *"../"* ]]
        [[ "$metadata_text" != *"/home/"* ]]
        [[ "$metadata_text" != *"plugins/ralph-specum-codex/skills/ralph-specum/"* ]]
    done < <(helper_codex_skills)
}

@test "codex platform: docs describe the packaged distribution" {
    local root readme_text trouble_text package_text
    root="$(repo_root)"

    readme_text="$(<"$root/README.md")"
    package_text="$(<"$(plugin_root)/README.md")"

    [[ "$readme_text" == *"ralph-specum-triage"* ]]
    [[ "$package_text" != *"repo-root AGENTS.md"* ]]
    [[ "$package_text" == *"Installation"* ]]
}

@test "codex platform: copied install layout remains usable" {
    local proot temp_codex_home skill
    proot="$(plugin_root)"
    temp_codex_home="$(mktemp -d)"
    trap 'rm -rf "$temp_codex_home"' EXIT

    mkdir -p "$temp_codex_home/skills"

    while IFS= read -r skill; do
        cp -R "$proot/skills/$skill" "$temp_codex_home/skills/$skill"
        [ -f "$temp_codex_home/skills/$skill/SKILL.md" ]
        [ -f "$temp_codex_home/skills/$skill/agents/openai.yaml" ]
    done < <(all_codex_skills)

    [ -f "$proot/assets/bootstrap/AGENTS.md" ]
    [ -f "$proot/assets/bootstrap/ralph-specum.local.md" ]
}

@test "codex platform: skill frontmatter passes quick validation when available" {
    local proot validator skill
    proot="$(plugin_root)"
    validator="/mnt/c/Users/ADMIN/.codex/skills/.system/skill-creator/scripts/quick_validate.py"

    [ -f "$validator" ] || skip

    while IFS= read -r skill; do
        run python3 "$validator" "$proot/skills/$skill"
        [ "$status" -eq 0 ]
    done < <(all_codex_skills)
}

@test "codex platform: helper skill set matches plugin command surface" {
    local root
    root="$(repo_root)"

    assert_python '
plugin_commands = sorted(
    p.stem for p in (ROOT / "plugins/ralph-specum/commands").glob("*.md")
)
codex_helpers = sorted(
    p.name[len("ralph-specum-"):]
    for p in (ROOT / "plugins/ralph-specum-codex/skills").glob("ralph-specum-*")
    if p.is_dir()
)

expected = sorted(cmd for cmd in plugin_commands if cmd != "new")
assert codex_helpers == expected, {
    "expected": expected,
    "actual": codex_helpers,
}
' "$root"
}

@test "codex platform: install docs list every shipped skill" {
    local root
    root="$(repo_root)"

    assert_python '
skills = sorted(
    p.name for p in (ROOT / "plugins/ralph-specum-codex/skills").glob("ralph-specum*")
    if p.is_dir()
)
readme = (ROOT / "README.md").read_text()
package = (ROOT / "plugins/ralph-specum-codex/README.md").read_text()

for skill in skills:
    assert package.count(skill) >= 1, skill
' "$root"
}

@test "codex platform: primary skill routing stays aligned with plugin commands" {
    local root
    root="$(repo_root)"

    assert_python '
primary = (ROOT / "plugins/ralph-specum-codex/skills/ralph-specum/SKILL.md").read_text()
required_tokens = {
    "start": "Start, new, resume, quick mode",
    "triage": "| Triage |",
    "research": "| Research |",
    "requirements": "| Requirements |",
    "design": "| Design |",
    "tasks": "| Tasks |",
    "implement": "| Implement |",
    "status": "| Status |",
    "switch": "| Switch |",
    "cancel": "| Cancel |",
    "index": "| Index |",
    "refactor": "| Refactor |",
    "feedback": "| Feedback |",
    "help": "| Help |",
}

for command, token in required_tokens.items():
    assert token in primary, {"command": command, "token": token}
' "$root"
}

@test "codex platform: default prompts advertise approval handoffs" {
    local root
    root="$(repo_root)"

    assert_python '
expected = {
    "ralph-specum": ["approve current artifact", "request changes", "continue to <named next step>"],
    "ralph-specum-start": ["wait for explicit direction", "research"],
    "ralph-specum-research": ["approve current artifact", "continue to requirements"],
    "ralph-specum-requirements": ["approve current artifact", "continue to design"],
    "ralph-specum-design": ["approve current artifact", "continue to tasks"],
    "ralph-specum-tasks": ["approve current artifact", "continue to implementation"],
    "ralph-specum-cancel": ["whether anything was removed", "exactly what if so"],
    "ralph-specum-triage": ["approve current artifact", "continue to the next spec"],
    "ralph-specum-refactor": ["approve current artifact", "continue to implementation"],
}

for skill, tokens in expected.items():
    text = (ROOT / "plugins/ralph-specum-codex/skills" / skill / "agents/openai.yaml").read_text()
    for token in tokens:
        assert token in text, {"skill": skill, "token": token}
' "$root"
}

@test "codex platform: helper skills retain plugin command semantics" {
    local root
    root="$(repo_root)"

    assert_python '
pairs = {
    "start": ["quick mode", "granularity", ".current-epic", "awaitingApproval"],
    "triage": ["specs/_epics", ".current-epic", ".epic-state.json", "dependencies"],
    "research": ["brainstorming", "research.md", "verification tooling"],
    "requirements": ["brainstorming", "requirements.md", "awaitingApproval"],
    "design": ["brainstorming", "design.md", "awaitingApproval"],
    "tasks": ["granularity", "[P]", "[VERIFY]", "VE tasks", "taskIndex: first incomplete or totalTasks"],
    "implement": ["[P]", "[VERIFY]", "VE tasks", "tasks.md", "approval", "quick mode", "explicit user direction", "file sets do not overlap", "Marker syntax must be explicitly present"],
    "status": [".current-epic", "approval state", "granularity", "there is no active spec"],
    "switch": [".current-spec", "approval state"],
    "cancel": [".ralph-state.json", "Safe cancel", "full removal"],
    "index": ["specs/.index", "dry run", "deterministic"],
    "refactor": ["requirements.md", "design.md", "tasks.md", "[VERIFY]"],
    "feedback": ["GitHub issue", "Codex package", "Claude plugin"],
    "help": ["$ralph-specum-triage", "Large effort flow", ".current-epic"],
}

for name, tokens in pairs.items():
    text = (ROOT / f"plugins/ralph-specum-codex/skills/ralph-specum-{name}/SKILL.md").read_text()
    for token in tokens:
        assert token in text, {"skill": name, "token": token}
' "$root"
}

@test "codex platform: phase skills require approval handoff text" {
    local root
    root="$(repo_root)"

    assert_python '
expected = {
    "research": ["approve current artifact", "request changes", "continue to requirements"],
    "requirements": ["approve current artifact", "request changes", "continue to design"],
    "design": ["approve current artifact", "request changes", "continue to tasks"],
    "tasks": ["approve current artifact", "request changes", "continue to implementation"],
    "triage": ["approve current artifact", "request changes", "continue to the next spec"],
    "refactor": ["approve current artifact", "request changes", "continue to implementation"],
}

for name, tokens in expected.items():
    text = (ROOT / f"plugins/ralph-specum-codex/skills/ralph-specum-{name}/SKILL.md").read_text()
    for token in tokens:
        assert token in text, {"skill": name, "token": token}
' "$root"
}

@test "codex platform: bootstrap and workflow stay aligned with quick mode and triage artifacts" {
    local root proot
    root="$(repo_root)"
    proot="$(plugin_root)"

    assert_python '
bootstrap = (ROOT / "plugins/ralph-specum-codex/assets/bootstrap/AGENTS.md").read_text()
bootstrap_local = (ROOT / "plugins/ralph-specum-codex/assets/bootstrap/ralph-specum.local.md").read_text()
primary = (ROOT / "plugins/ralph-specum-codex/skills/ralph-specum/SKILL.md").read_text()
workflow = (ROOT / "plugins/ralph-specum-codex/references/workflow.md").read_text()
path_resolution = (ROOT / "plugins/ralph-specum-codex/references/path-resolution.md").read_text()
state_contract = (ROOT / "plugins/ralph-specum-codex/references/state-contract.md").read_text()

assert "create, resume, or run in quick mode" in bootstrap
assert "`quick_mode_default` is removed and ignored" in bootstrap_local
assert "Use only when the user explicitly invokes `$ralph-specum`" in primary
assert "## Response Handoff" in primary
assert "epic.md" not in primary.split("## Current Workflow Expectations")[0]
assert "epic.md" not in workflow.split("Treat `continue to <named next step>` as approval of the current artifact.")[0]
assert "Wait for explicit direction to continue to research" in workflow
assert "quick_mode_default" in path_resolution
assert "Approval Prompt Shape" in state_contract
' "$root"
}

@test "codex platform: shared template headings still cover plugin templates" {
    local root
    root="$(repo_root)"

    assert_python '
def headings(path):
    return [line.strip() for line in path.read_text().splitlines() if line.startswith("#")]

template_names = [
    "component-spec.md",
    "design.md",
    "external-spec.md",
    "index-summary.md",
    "progress.md",
    "requirements.md",
    "research.md",
    "settings-template.md",
    "tasks.md",
]

for name in template_names:
    codex = headings(ROOT / "plugins/ralph-specum-codex/templates" / name)
    plugin = headings(ROOT / "plugins/ralph-specum/templates" / name)
    missing = [
        heading for heading in codex
        if not any(other.startswith(heading) for other in plugin)
    ]
    assert not missing, {"template": name, "missing_in_plugin": missing}

must_match_exactly = [
    "component-spec.md",
    "design.md",
    "external-spec.md",
    "index-summary.md",
    "progress.md",
    "requirements.md",
    "research.md",
]

for name in must_match_exactly:
    codex = headings(ROOT / "plugins/ralph-specum-codex/templates" / name)
    plugin = headings(ROOT / "plugins/ralph-specum/templates" / name)
    assert codex == plugin, {"template": name, "codex": codex, "plugin": plugin}
' "$root"
}

@test "codex platform: shared bootstrap and scripts expose current drift-sensitive fields" {
    local root
    root="$(repo_root)"

    assert_python '
import re

bootstrap = (ROOT / "plugins/ralph-specum-codex/assets/bootstrap/AGENTS.md").read_text()
settings = (ROOT / "plugins/ralph-specum-codex/assets/bootstrap/ralph-specum.local.md").read_text()
count_tasks = (ROOT / "plugins/ralph-specum-codex/scripts/count_tasks.py").read_text()
merge_state = (ROOT / "plugins/ralph-specum-codex/scripts/merge_state.py").read_text()
resolve_paths = (ROOT / "plugins/ralph-specum-codex/scripts/resolve_spec_paths.py").read_text()
frontmatter = settings.split("---", 2)[1]

assert "$ralph-specum-start" in bootstrap
assert ".current-spec" in bootstrap
assert "specs_dirs" in settings
assert re.search(r"(?m)^quick_mode_default\\s*:", frontmatter) is None
assert "\"total\"" in count_tasks
assert "\"completed\"" in count_tasks
assert "\"next_index\"" in count_tasks
assert "--set" in merge_state
assert "--json" in merge_state
assert ".current-spec" in resolve_paths
assert "specs_dirs" in resolve_paths
assert "quick_mode_default" not in resolve_paths
' "$root"
}
