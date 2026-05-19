#!/usr/bin/env bats

repo_root() { echo "$BATS_TEST_DIRNAME/.."; }
plugin_root() { echo "$(repo_root)/plugins/ralph-specum-codex"; }

all_skills() {
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

helper_skills() {
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

@test "codex plugin: manifest exists and is valid JSON" {
    local manifest
    manifest="$(plugin_root)/.codex-plugin/plugin.json"
    [ -f "$manifest" ]
    run python3 -c "import json; json.load(open('$manifest'))"
    [ "$status" -eq 0 ]
}

@test "codex plugin: manifest has required fields" {
    local manifest
    manifest="$(plugin_root)/.codex-plugin/plugin.json"
    run python3 -c "
import json, sys
d = json.load(open('$manifest'))
for field in ('name', 'version', 'description'):
    assert field in d, f'Missing field: {field}'
print('ok')
"
    [ "$status" -eq 0 ]
}

@test "codex plugin: all 15 skill directories have SKILL.md" {
    local root skill
    root="$(plugin_root)"

    while IFS= read -r skill; do
        [ -f "$root/skills/$skill/SKILL.md" ]
    done < <(all_skills)
}

@test "codex plugin: all skill SKILL.md files have valid frontmatter" {
    local root skill
    root="$(plugin_root)"

    while IFS= read -r skill; do
        run python3 -c "
import re, sys
text = open('$root/skills/$skill/SKILL.md').read()
match = re.match(r'---\n(.*?)\n---', text, re.DOTALL)
assert match, 'No frontmatter found'
fm = match.group(1)
assert 'name:' in fm, 'Missing name in frontmatter'
assert 'description:' in fm, 'Missing description in frontmatter'
print('ok')
"
        [ "$status" -eq 0 ]
    done < <(all_skills)
}

@test "codex plugin: all helper skills have agents/openai.yaml" {
    local root skill
    root="$(plugin_root)"

    while IFS= read -r skill; do
        [ -f "$root/skills/$skill/agents/openai.yaml" ]
    done < <(helper_skills)
}

@test "codex plugin: 9 agent-config templates exist" {
    local root count
    root="$(plugin_root)"
    count=$(ls "$root/agent-configs/"*.toml.template 2>/dev/null | wc -l)
    [ "$count" -eq 9 ]
}

@test "codex plugin: spec-executor template contains TASK_COMPLETE" {
    local template
    template="$(plugin_root)/agent-configs/spec-executor.toml.template"
    [ -f "$template" ]
    grep -q "TASK_COMPLETE" "$template"
}

@test "codex plugin: README.md exists and has Installation and Migration sections" {
    local readme
    readme="$(plugin_root)/README.md"
    [ -f "$readme" ]
    grep -q "Installation" "$readme"
    grep -q "Migration" "$readme"
}

@test "codex plugin: stop-watcher hook is executable" {
    local hook
    hook="$(plugin_root)/hooks/stop-watcher.sh"
    [ -f "$hook" ]
    [ -x "$hook" ]
}

@test "codex plugin: all 4 reference files exist" {
    local root
    root="$(plugin_root)"
    [ -f "$root/references/workflow.md" ]
    [ -f "$root/references/state-contract.md" ]
    [ -f "$root/references/path-resolution.md" ]
    [ -f "$root/references/parity-matrix.md" ]
}

@test "codex plugin: all 10 template files exist" {
    local root
    root="$(plugin_root)"
    [ -f "$root/templates/component-spec.md" ]
    [ -f "$root/templates/design.md" ]
    [ -f "$root/templates/epic.md" ]
    [ -f "$root/templates/external-spec.md" ]
    [ -f "$root/templates/index-summary.md" ]
    [ -f "$root/templates/progress.md" ]
    [ -f "$root/templates/requirements.md" ]
    [ -f "$root/templates/research.md" ]
    [ -f "$root/templates/settings-template.md" ]
    [ -f "$root/templates/tasks.md" ]
}

@test "codex plugin: all 3 Python scripts exist" {
    local root
    root="$(plugin_root)"
    [ -f "$root/scripts/count_tasks.py" ]
    [ -f "$root/scripts/merge_state.py" ]
    [ -f "$root/scripts/resolve_spec_paths.py" ]
}

@test "codex plugin: schema file exists and is valid JSON" {
    local schema
    schema="$(plugin_root)/schemas/spec.schema.json"
    [ -f "$schema" ]
    run python3 -c "import json; json.load(open('$schema'))"
    [ "$status" -eq 0 ]
}

@test "codex plugin: bootstrap assets exist" {
    local root
    root="$(plugin_root)"
    [ -d "$root/assets/bootstrap" ]
    [ "$(ls -A "$root/assets/bootstrap")" ]
}
