#!/usr/bin/env bats

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    PLUGIN_ROOT="$REPO_ROOT/plugins/ralph-specum"
}

@test "Claude agents skills and hooks use canonical progress.md only" {
    run rg -n '\.progress\.md' \
        "$PLUGIN_ROOT/agents" "$PLUGIN_ROOT/skills" "$PLUGIN_ROOT/hooks" \
        "$PLUGIN_ROOT/templates/prompts"

    [ "$status" -eq 1 ]
    [ -z "$output" ]
    run rg -n 'progress\.md' "$PLUGIN_ROOT/hooks/scripts/load-spec-context.sh"
    [ "$status" -eq 0 ]
}

@test "legacy progress migration is read-only and never staged" {
    run rg -n 'legacy file as read-only historical input' \
        "$PLUGIN_ROOT/references/progress-state.md"
    [ "$status" -eq 0 ]
    run rg -n 'git add[^\n]*\.progress\.md' "$PLUGIN_ROOT" \
        --glob '!templates/**'
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

@test "tracked progress is not added to gitignore" {
    run rg -n '(echo|append)[^\n]*\*\*/progress\.md' "$PLUGIN_ROOT" \
        --glob '!templates/**'
    [ "$status" -eq 1 ]
    [ -z "$output" ]
    run rg -n '\*\*/\.progress\.md' \
        "$PLUGIN_ROOT/commands/new.md" "$PLUGIN_ROOT/commands/start.md"
    [ "$status" -eq 0 ]
}

@test "canonical progress frontmatter and task truth are explicit" {
    run rg -n 'approved_through: none' "$PLUGIN_ROOT/commands/new.md"
    [ "$status" -eq 0 ]
    run rg -n 'sole source of truth for task completion' \
        "$PLUGIN_ROOT/references/progress-state.md" \
        "$PLUGIN_ROOT/references/coordinator-pattern.md"
    [ "$status" -eq 0 ]
}

@test "parallel progress files remain adapter-local temporaries" {
    run rg -n '\.progress-task-' \
        "$PLUGIN_ROOT/agents/spec-executor.md" \
        "$PLUGIN_ROOT/references/coordinator-pattern.md"
    [ "$status" -eq 0 ]
}
