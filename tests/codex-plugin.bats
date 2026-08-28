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
ralph-specum-prototype
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
ralph-specum-prototype
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

@test "codex plugin: manifest declares a valid Stop hook" {
    local manifest hook_manifest
    manifest="$(plugin_root)/.codex-plugin/plugin.json"
    hook_manifest="$(plugin_root)/hooks/hooks.json"

    run python3 -c "
import json
manifest = json.load(open('$manifest'))
hooks = json.load(open('$hook_manifest'))
assert manifest['hooks'] == './hooks/hooks.json'
assert set(hooks['hooks']) == {'Stop'}
assert len(hooks['hooks']['Stop']) == 1
handlers = hooks['hooks']['Stop'][0]['hooks']
assert len(handlers) == 1
handler = handlers[0]
assert handler['type'] == 'command'
command = handler['command']
assert command == 'bash \"\${PLUGIN_ROOT}/hooks/stop-watcher.sh\"'
print('ok')
"
    [ "$status" -eq 0 ]
}

@test "codex plugin: declared Stop hook executes the bundled watcher" {
    local command workspace
    workspace="$BATS_TEST_TMPDIR/hook-workspace"
    mkdir -p "$workspace/specs/test-spec"
    printf 'test-spec\n' > "$workspace/specs/.current-spec"
    printf '%s\n' \
        '{"phase":"execution","taskIndex":0,"totalTasks":2,"awaitingApproval":false}' \
        > "$workspace/specs/test-spec/.ralph-state.json"
    command=$(python3 -c "
import json
hooks = json.load(open('$(plugin_root)/hooks/hooks.json'))
print(hooks['hooks']['Stop'][0]['hooks'][0]['command'])
")

    run env PLUGIN_ROOT="$(plugin_root)" bash -c "$command" \
        <<< "{\"cwd\":\"$workspace\"}"

    [ "$status" -eq 0 ]
    [[ "$output" == *'"decision":"block"'* ]]
    [[ "$output" == *'Continue to task 1/2'* ]]
}

@test "codex plugin: marketplace installs with authentication on install" {
    local marketplace manifest
    marketplace="$(repo_root)/.agents/plugins/marketplace.json"
    manifest="$(plugin_root)/.codex-plugin/plugin.json"

    run python3 -c "
import json, os
marketplace = json.load(open('$marketplace'))
manifest = json.load(open('$manifest'))
assert marketplace['name'] == 'smart-ralph'
plugins = [
    plugin
    for plugin in marketplace['plugins']
    if plugin['name'] == 'ralph-specum'
]
assert len(plugins) == 1
plugin = plugins[0]
assert plugin['name'] == manifest['name']
assert plugin['source']['source'] == 'local'
assert plugin['source']['path'] == './plugins/ralph-specum-codex'
source = os.path.normpath(os.path.join('$(repo_root)', plugin['source']['path']))
assert source == os.path.normpath('$(plugin_root)')
assert os.path.isdir(source)
assert plugin['policy']['installation'] == 'AVAILABLE'
assert plugin['policy']['authentication'] == 'ON_INSTALL'
print('ok')
"
    [ "$status" -eq 0 ]
}

@test "codex plugin: install docs fetch and install the plugin" {
    local root readme
    root="$(repo_root)"

    for readme in "$root/README.md" "$(plugin_root)/README.md"; do
        grep -Fq -- "--sparse .agents/plugins" "$readme"
        grep -Fq -- "--sparse plugins/ralph-specum-codex" "$readme"
        grep -Fq "codex plugin add ralph-specum@smart-ralph" "$readme"
        grep -Fq "codex plugin marketplace add ." "$readme"
    done
}

@test "codex plugin: docs use the current hook trust flow" {
    local root readme workflow
    root="$(repo_root)"
    workflow="$(plugin_root)/references/workflow.md"

    run grep -E "plugin_hooks|codex_hooks" \
        "$root/README.md" \
        "$(plugin_root)/README.md" \
        "$workflow"
    [ "$status" -eq 1 ]

    for readme in "$root/README.md" "$(plugin_root)/README.md"; do
        grep -Fq '/hooks' "$readme"
        grep -Fq 'review' "$readme"
        grep -Fq 'trust' "$readme"
    done

    grep -Fq '`bash`' "$workflow"
    grep -Fq '`jq`' "$workflow"
    grep -Fq 'Manual Fallback Path' "$workflow"
}

@test "codex plugin: all 16 skill directories have SKILL.md" {
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

@test "codex plugin: 10 agent-config templates exist" {
    local root count
    root="$(plugin_root)"
    count=$(ls "$root/agent-configs/"*.toml.template 2>/dev/null | wc -l)
    [ "$count" -eq 10 ]
    [ -f "$root/agent-configs/prototype-builder.toml.template" ]
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

@test "codex plugin: all 5 reference files exist" {
    local root
    root="$(plugin_root)"
    [ -f "$root/references/workflow.md" ]
    [ -f "$root/references/state-contract.md" ]
    [ -f "$root/references/path-resolution.md" ]
    [ -f "$root/references/parity-matrix.md" ]
    [ -f "$root/references/prototype-coordinator.md" ]
}

@test "codex plugin: all 11 template files exist" {
    local root
    root="$(plugin_root)"
    [ -f "$root/templates/component-spec.md" ]
    [ -f "$root/templates/design.md" ]
    [ -f "$root/templates/epic.md" ]
    [ -f "$root/templates/external-spec.md" ]
    [ -f "$root/templates/index-summary.md" ]
    [ -f "$root/templates/progress.md" ]
    [ -f "$root/templates/prototype.md" ]
    [ -f "$root/templates/requirements.md" ]
    [ -f "$root/templates/research.md" ]
    [ -f "$root/templates/settings-template.md" ]
    [ -f "$root/templates/tasks.md" ]
}

@test "codex plugin: all 6 Python scripts exist" {
    local root
    root="$(plugin_root)"
    [ -f "$root/scripts/count_tasks.py" ]
    [ -f "$root/scripts/locked_state.py" ]
    [ -f "$root/scripts/merge_state.py" ]
    [ -f "$root/scripts/prototype_harness.py" ]
    [ -f "$root/scripts/prototype_records.py" ]
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
