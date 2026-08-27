#!/usr/bin/env bats
# Workflow Guardrail Content Tests
# Verifies that intake binds the authorization boundary before work starts.

GOAL_INTERVIEW="plugins/ralph-specum/references/goal-interview.md"
QUICK_MODE="plugins/ralph-specum/references/quick-mode.md"
NEW_COMMAND="plugins/ralph-specum/commands/new.md"
TASK_PLANNER="plugins/ralph-specum/agents/task-planner.md"
SPEC_EXECUTOR="plugins/ralph-specum/agents/spec-executor.md"
COORDINATOR="plugins/ralph-specum/references/coordinator-pattern.md"

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

@test "planner checks every task and adjacent finding against the scope envelope" {
    grep -Fq '## Scope Envelope' "$TASK_PLANNER"
    grep -Eiq 'every planned task.*scope envelope|scope envelope.*every planned task' "$TASK_PLANNER"
    grep -Eiq 'adjacent (finding|issue).*scope envelope|scope envelope.*adjacent (finding|issue)' "$TASK_PLANNER"
}

@test "executor compares the full task contract and external effects before mutation" {
    grep -Fq '## Scope Envelope' "$SPEC_EXECUTOR"
    grep -Eiq 'before (any )?mutation|before modifying' "$SPEC_EXECUTOR"
    grep -Fq 'Do' "$SPEC_EXECUTOR"
    grep -Fq 'Files' "$SPEC_EXECUTOR"
    grep -Fq 'Done when' "$SPEC_EXECUTOR"
    grep -Fq 'Verify' "$SPEC_EXECUTOR"
    grep -Eiq 'external (effects|actions|side effects)' "$SPEC_EXECUTOR"
}

@test "executor emits the exact scope escalation signal and fields" {
    grep -Fq 'SCOPE_ESCALATION_REQUIRED' "$SPEC_EXECUTOR"
    grep -Fq 'Field:' "$SPEC_EXECUTOR"
    grep -Fq 'Reason:' "$SPEC_EXECUTOR"
    grep -Fq 'Question:' "$SPEC_EXECUTOR"
}

@test "coordinator gates scope escalation before ordinary failure without advancing counters" {
    local escalation_line failure_line
    escalation_line="$(line_number "$COORDINATOR" 'SCOPE_ESCALATION_REQUIRED')"
    failure_line="$(line_number "$COORDINATOR" 'If no completion signal:')"

    [ -n "$escalation_line" ]
    [ -n "$failure_line" ]
    [ "$escalation_line" -lt "$failure_line" ]
    grep -Fq 'awaitingApproval: true' "$COORDINATOR"
    grep -Eq 'taskIndex.*taskIteration.*globalIteration.*(remain |stay )?unchanged|unchanged.*taskIndex.*taskIteration.*globalIteration' "$COORDINATOR"
}

@test "scope approval updates the envelope before clearing the gate and resuming" {
    local update_line clear_line resume_line
    update_line="$(line_number "$COORDINATOR" 'Update `## Scope Envelope`')"
    clear_line="$(line_number "$COORDINATOR" 'awaitingApproval: false')"
    resume_line="$(line_number "$COORDINATOR" 'Replan or retry')"

    [ -n "$update_line" ]
    [ -n "$clear_line" ]
    [ -n "$resume_line" ]
    [ "$update_line" -lt "$clear_line" ]
    [ "$clear_line" -lt "$resume_line" ]
    grep -Eiq 'replan or retry.*(fit|inside|within).*scope envelope' "$COORDINATOR"
}

@test "scope rejection preserves the envelope and stops or removes optional work" {
    grep -Eiq 'reject.*preserve.*scope envelope|preserve.*scope envelope.*reject' "$COORDINATOR"
    grep -Eiq 'revise or remove|remove or revise' "$COORDINATOR"
    grep -Fq 'awaitingApproval: true' "$COORDINATOR"
    grep -Eiq 'required.*(stop|blocked)|stop.*required' "$COORDINATOR"
}

@test "prerequisite and followup modifications stay inside the scope envelope" {
    grep -Eq 'ADD_PREREQUISITE.*ADD_FOLLOWUP.*(inside|within).*Scope Envelope' "$COORDINATOR"
}

@test "planner records adjacent issues as learnings instead of tasks" {
    grep -Eiq 'adjacent (finding|issue).*(learning|learnings)' "$TASK_PLANNER"
    grep -Eiq 'adjacent (finding|issue).*(not|never).*(task|tasks)|(not|never).*(task|tasks).*adjacent (finding|issue)' "$TASK_PLANNER"
}
