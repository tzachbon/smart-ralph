#!/usr/bin/env bats

repo_root() {
    echo "$BATS_TEST_DIRNAME/.."
}

all_codex_skills() {
    cat <<'EOF'
ralph-specum
ralph-specum-start
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

@test "codex platform: repo root wrapper files are gone" {
    local root
    root="$(repo_root)"

    [ ! -e "$root/AGENTS.md" ]
    [ ! -e "$root/tests/codex-wrapper.bats" ]

    run find "$root/.agents/skills" -maxdepth 1 -mindepth 1 -type d \( -name 'ralph-specum' -o -name 'ralph-specum-*' \)
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "codex platform: each installable skill has required files" {
    local root skill
    root="$(repo_root)"

    while IFS= read -r skill; do
        [ -f "$root/platforms/codex/skills/$skill/SKILL.md" ]
        [ -f "$root/platforms/codex/skills/$skill/agents/openai.yaml" ]
    done < <(all_codex_skills)
}

@test "codex platform: primary skill ships shared resources" {
    local root
    root="$(repo_root)"

    [ -f "$root/platforms/codex/README.md" ]
    [ -f "$root/platforms/codex/skills/ralph-specum/references/workflow.md" ]
    [ -f "$root/platforms/codex/skills/ralph-specum/references/state-contract.md" ]
    [ -f "$root/platforms/codex/skills/ralph-specum/references/path-resolution.md" ]
    [ -f "$root/platforms/codex/skills/ralph-specum/references/parity-matrix.md" ]
    [ -f "$root/platforms/codex/skills/ralph-specum/scripts/merge_state.py" ]
    [ -f "$root/platforms/codex/skills/ralph-specum/scripts/count_tasks.py" ]
    [ -f "$root/platforms/codex/skills/ralph-specum/scripts/resolve_spec_paths.py" ]
    [ -f "$root/platforms/codex/skills/ralph-specum/assets/bootstrap/AGENTS.md" ]
    [ -f "$root/platforms/codex/skills/ralph-specum/assets/bootstrap/ralph-specum.local.md" ]
}

@test "codex platform: helper skills stay self-contained" {
    local root skill skill_text metadata_text
    root="$(repo_root)"

    while IFS= read -r skill; do
        skill_text="$(<"$root/platforms/codex/skills/$skill/SKILL.md")"
        metadata_text="$(<"$root/platforms/codex/skills/$skill/agents/openai.yaml")"

        [[ "$skill_text" != *"../"* ]]
        [[ "$skill_text" != *"/home/"* ]]
        [[ "$skill_text" != *"platforms/codex/skills/ralph-specum/"* ]]
        [[ "$metadata_text" != *"../"* ]]
        [[ "$metadata_text" != *"/home/"* ]]
        [[ "$metadata_text" != *"platforms/codex/skills/ralph-specum/"* ]]
    done < <(helper_codex_skills)
}

@test "codex platform: docs describe the packaged distribution" {
    local root readme_text trouble_text package_text
    root="$(repo_root)"

    readme_text="$(<"$root/README.md")"
    trouble_text="$(<"$root/TROUBLESHOOTING.md")"
    package_text="$(<"$root/platforms/codex/README.md")"

    [[ "$readme_text" == *"platforms/codex/README.md"* ]]
    [[ "$readme_text" == *"platforms/codex/skills/ralph-specum"* ]]
    [[ "$trouble_text" == *"platforms/codex/skills/ralph-specum"* ]]
    [[ "$package_text" != *"repo-root AGENTS.md"* ]]
}

@test "codex platform: copied install layout remains usable" {
    local root temp_codex_home skill
    root="$(repo_root)"
    temp_codex_home="$(mktemp -d)"

    mkdir -p "$temp_codex_home/skills"

    while IFS= read -r skill; do
        cp -R "$root/platforms/codex/skills/$skill" "$temp_codex_home/skills/$skill"
        [ -f "$temp_codex_home/skills/$skill/SKILL.md" ]
        [ -f "$temp_codex_home/skills/$skill/agents/openai.yaml" ]
    done < <(all_codex_skills)

    [ -f "$temp_codex_home/skills/ralph-specum/assets/bootstrap/AGENTS.md" ]
    [ -f "$temp_codex_home/skills/ralph-specum/assets/bootstrap/ralph-specum.local.md" ]

    rm -rf "$temp_codex_home"
}

@test "codex platform: skill frontmatter passes quick validation when available" {
    local root validator skill
    root="$(repo_root)"
    validator="/mnt/c/Users/ADMIN/.codex/skills/.system/skill-creator/scripts/quick_validate.py"

    [ -f "$validator" ] || skip

    while IFS= read -r skill; do
        run python3 "$validator" "$root/platforms/codex/skills/$skill"
        [ "$status" -eq 0 ]
    done < <(all_codex_skills)
}
