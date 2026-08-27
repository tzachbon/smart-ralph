#!/usr/bin/env bats
# Workflow Guardrail Content Tests
# Verifies that intake binds the authorization boundary before work starts.

GOAL_INTERVIEW="plugins/ralph-specum/references/goal-interview.md"
QUICK_MODE="plugins/ralph-specum/references/quick-mode.md"
NEW_COMMAND="plugins/ralph-specum/commands/new.md"

assert_scope_envelope() {
    local file="$1"

    grep -Fq '## Scope Envelope' "$file"
    grep -Fq -- '- Target:' "$file"
    grep -Fq -- '- Action:' "$file"
    grep -Fq -- '- Bounds:' "$file"
    grep -Fq -- '- Deliverable:' "$file"
    grep -Fq -- '- Complete when:' "$file"
    grep -Fq -- '- Escalate when:' "$file"
}

line_number() {
    local file="$1"
    local literal="$2"

    grep -nF "$literal" "$file" | head -n 1 | cut -d: -f1
}

@test "normal intake persists all six scope-envelope fields" {
    assert_scope_envelope "$GOAL_INTERVIEW"
}

@test "quick intake persists all six scope-envelope fields" {
    assert_scope_envelope "$QUICK_MODE"
}

@test "quick intake binds scope before reproduction and research" {
    local scope_line reproduction_line research_line
    scope_line="$(line_number "$QUICK_MODE" '## Scope Envelope')"
    reproduction_line="$(line_number "$QUICK_MODE" 'Goal Type Detection (BUG_FIX BEFORE state capture):')"
    research_line="$(line_number "$QUICK_MODE" 'Research Phase: TaskCreate')"

    [ -n "$scope_line" ]
    [ -n "$reproduction_line" ]
    [ -n "$research_line" ]
    [ "$scope_line" -lt "$reproduction_line" ]
    [ "$scope_line" -lt "$research_line" ]
}

@test "new command routes through the normal goal interview before research" {
    grep -Fq 'Read `${CLAUDE_PLUGIN_ROOT}/references/goal-interview.md` and resolve its design-tree frontier before research' "$NEW_COMMAND"
}
