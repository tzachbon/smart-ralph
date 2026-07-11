#!/usr/bin/env bats

repo_root() { echo "$BATS_TEST_DIRNAME/.."; }
plugin_root() { echo "$(repo_root)/plugins/ralph-specum-codex"; }

first_class_skills() {
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
EOF
}

shim_skills() {
    cat <<'EOF'
ralph-specum-switch
ralph-specum-cancel
ralph-specum-index
ralph-specum-refactor
ralph-specum-feedback
ralph-specum-help
EOF
}

@test "codex platform: manifest describes a native v5 package" {
    local manifest
    manifest="$(plugin_root)/.codex-plugin/plugin.json"
    run python3 - "$manifest" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text())
assert data["name"] == path.parents[1].name
assert data["version"] == "5.0.0"
assert data["skills"] == "./skills/"
assert "hooks" not in data
PY
    [ "$status" -eq 0 ]
}

@test "codex platform: nine first-class native skills are installed" {
    local skill
    while IFS= read -r skill; do
        [ -f "$(plugin_root)/skills/$skill/SKILL.md" ]
        [ -f "$(plugin_root)/skills/$skill/agents/openai.yaml" ]
    done < <(first_class_skills)
}

@test "codex platform: six version 5 shims warn and route to the primary skill" {
    local skill text
    while IFS= read -r skill; do
        text="$(<"$(plugin_root)/skills/$skill/SKILL.md")"
        [[ "$text" == *"v6"* ]]
        [[ "$text" == *'$ralph-specum'* ]]
    done < <(shim_skills)
}

@test "codex platform: every skill requires explicit invocation" {
    local metadata
    while IFS= read -r metadata; do
        grep -q 'allow_implicit_invocation: false' "$metadata"
    done < <(find "$(plugin_root)/skills" -path '*/agents/openai.yaml' -type f | sort)
}

@test "codex platform: implementation uses native goal only for explicit autonomous intent" {
    local text
    text="$(<"$(plugin_root)/skills/ralph-specum-implement/SKILL.md")"
    [[ "$text" == *'autonomous, quick, finish, or long-running'* ]]
    [[ "$text" == *'Without explicit autonomous intent'* ]]
    [[ "$text" == *'one verified logical batch'* ]]
    [[ "$text" == *'Do not include a token budget'* ]]
}

@test "codex platform: subagent packets are bounded and root-owned" {
    local workflow
    workflow="$(<"$(plugin_root)/references/workflow.md")"
    for token in Objective Role "Reasoning tier" "Dependency inputs" "Allowed files" "Acceptance criteria" "Verification command" "Required evidence" "Answer" "Changed files"; do
        [[ "$workflow" == *"$token"* ]]
    done
    [[ "$workflow" == *'at most three read-only subagents'* ]]
    [[ "$workflow" == *'one write subagent at a time'* ]]
    [[ "$workflow" == *'at most three times'* ]]
    [[ "$workflow" == *'do not edit tasks.md, progress.md'* ]]
}

@test "codex platform: spec phases mandate tiered native delegation" {
    local workflow
    workflow="$(<"$(plugin_root)/references/workflow.md")"
    [[ "$workflow" == *'Delegate substantive research, requirements, design, tasks, and triage'* ]]
    [[ "$workflow" == *'| Research | evidence investigator | medium |'* ]]
    [[ "$workflow" == *'| Design | systems architect | strongest |'* ]]
    [[ "$workflow" == *'| Tasks | task decomposer | light |'* ]]
    [[ "$workflow" == *'Upgrade a research or requirements packet from `medium` to `strongest`'* ]]
    [[ "$workflow" == *'Never install or require custom agent TOML'* ]]
}

@test "claude platform: phase agents pin native model strengths" {
    local root
    root="$(repo_root)/plugins/ralph-specum/agents"
    grep -q '^model: sonnet$' "$root/research-analyst.md"
    grep -q '^model: sonnet$' "$root/product-manager.md"
    grep -q '^model: opus$' "$root/architect-reviewer.md"
    grep -q '^model: haiku$' "$root/task-planner.md"
    grep -q '^model: opus$' "$root/triage-analyst.md"
}

@test "codex platform: status combines artifacts with native goal state" {
    local text
    text="$(<"$(plugin_root)/skills/ralph-specum-status/SKILL.md")"
    [[ "$text" == *'task checkboxes'* ]]
    [[ "$text" == *'progress.md'* ]]
    [[ "$text" == *'native goal'* ]]
}

@test "codex platform: no custom continuation mechanism is shipped" {
    local root
    root="$(plugin_root)"
    [ ! -f "$root/hooks/stop-watcher.sh" ]
    [ ! -f "$root/scripts/merge_state.py" ]
    [ -z "$(find "$root/agent-configs" -type f -print -quit 2>/dev/null)" ]
}

@test "codex platform: an isolated installed copy resolves all resources" {
    local install_root
    install_root="$(mktemp -d)"
    cp -R "$(plugin_root)" "$install_root/ralph-specum-codex"
    run env PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s "$install_root/ralph-specum-codex/tests"
    rm -rf "$install_root"
    [ "$status" -eq 0 ]
}

@test "codex platform: canonical generated assets match the shared core" {
    run python3 "$(repo_root)/scripts/sync-core-assets.py" --check
    [ "$status" -eq 0 ]
}
