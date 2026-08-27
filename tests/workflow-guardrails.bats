#!/usr/bin/env bats
# Workflow Guardrail Content Tests
# Verifies that intake binds the authorization boundary before work starts.

GOAL_INTERVIEW="plugins/ralph-specum/references/goal-interview.md"
QUICK_MODE="plugins/ralph-specum/references/quick-mode.md"
NEW_COMMAND="plugins/ralph-specum/commands/new.md"
ARCHITECT_REVIEWER="plugins/ralph-specum/agents/architect-reviewer.md"
TASK_PLANNER="plugins/ralph-specum/agents/task-planner.md"
SPEC_EXECUTOR="plugins/ralph-specum/agents/spec-executor.md"
COORDINATOR="plugins/ralph-specum/references/coordinator-pattern.md"
SPEC_TASKS="specs/scoped-minimal-workflow/tasks.md"
MODIFIED_PROMPTS=(
    "$GOAL_INTERVIEW"
    "$QUICK_MODE"
    "$NEW_COMMAND"
    "$ARCHITECT_REVIEWER"
    "$TASK_PLANNER"
    "$SPEC_EXECUTOR"
    "$COORDINATOR"
)

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

assert_minimal_implementation_order() {
    local file="$1"
    local reuse_line feature_line configure_line add_line
    reuse_line="$(line_number "$file" 'Reuse repository code.')"
    feature_line="$(line_number "$file" 'Use a language or framework feature already available to the project.')"
    configure_line="$(line_number "$file" 'Change configuration or remove obsolete code.')"
    add_line="$(line_number "$file" 'Add code.')"

    [ -n "$reuse_line" ]
    [ -n "$feature_line" ]
    [ -n "$configure_line" ]
    [ -n "$add_line" ]
    [ "$reuse_line" -lt "$feature_line" ]
    [ "$feature_line" -lt "$configure_line" ]
    [ "$configure_line" -lt "$add_line" ]
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

@test "quick intake resolves ambiguity before persisting the scope envelope" {
    local ambiguity_line append_line
    ambiguity_line="$(line_number "$QUICK_MODE" 'If two plausible readings would change any field:')"
    append_line="$(line_number "$QUICK_MODE" 'Otherwise, append this block to .progress.md:')"

    [ -n "$ambiguity_line" ]
    [ -n "$append_line" ]
    [ "$ambiguity_line" -lt "$append_line" ]
    grep -Fq 'quickMode: false' "$QUICK_MODE"
    grep -Fq 'awaitingApproval: true' "$QUICK_MODE"
    [ "$(grep -Fc 'What should <field> be: <reading A> or <reading B>?' "$QUICK_MODE")" -eq 1 ]
    grep -Fq 'Do not append the Scope Envelope or run reproduction, skill discovery, or research.' "$QUICK_MODE"
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

@test "coordinator scope-checks every delegation route before mutation" {
    local preflight_line verify_route_line
    preflight_line="$(line_number "$COORDINATOR" '## Scope Preflight')"
    verify_route_line="$(line_number "$COORDINATOR" '### VERIFY Task Detection')"

    [ -n "$preflight_line" ]
    [ -n "$verify_route_line" ]
    [ "$preflight_line" -lt "$verify_route_line" ]
    grep -Fq 'including `[VERIFY]` tasks sent to qa-engineer' "$COORDINATOR"
    grep -Fq "Compare the current task's Do, Files, Done when, Verify, and external effects" "$COORDINATOR"
    grep -Fq 'If the Scope Envelope is missing or the task must change a field, do not delegate' "$COORDINATOR"
}

@test "coordinator preflights before bidirectional native task updates" {
    local preflight_line bidirectional_sync_line
    preflight_line="$(line_number "$COORDINATOR" '## Scope Preflight')"
    bidirectional_sync_line="$(line_number "$COORDINATOR" '## Native Task Sync - Bidirectional Check')"

    [ -n "$preflight_line" ]
    [ -n "$bidirectional_sync_line" ]
    [ "$preflight_line" -lt "$bidirectional_sync_line" ]
}

@test "coordinator preflights every task in a parallel batch" {
    grep -Fq 'Before any parallel batch delegation or native task update, compare every task in `parallelGroup.taskIndices`' "$COORDINATOR"
}

@test "parallel executors receive the resolved spec path" {
    grep -Fq 'basePath: $SPEC_PATH' "$COORDINATOR"
}

@test "qa fixes use the same no-mutation scope escalation" {
    grep -Fq 'Before any fix, compare its Files and external effects with the Scope Envelope and current task.' "$COORDINATOR"
    grep -Fq 'If either boundary would change, make no mutation and output `SCOPE_ESCALATION_REQUIRED` with `Field:`, `Reason:`, and `Question:`.' "$COORDINATOR"
    grep -Fq 'If delegated task output contains `SCOPE_ESCALATION_REQUIRED`' "$COORDINATOR"
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
    grep -Fq 'optional work, set `awaitingApproval: false`' "$COORDINATOR"
    grep -Fq 'awaitingApproval: true' "$COORDINATOR"
    grep -Eiq 'required.*(stop|blocked)|stop.*required' "$COORDINATOR"
}

@test "every task modification stays inside the scope envelope" {
    grep -Eq 'SPLIT_TASK.*ADD_PREREQUISITE.*ADD_FOLLOWUP.*(inside|within).*Scope Envelope' "$COORDINATOR"
}

@test "removing rejected optional work reconciles execution state" {
    grep -Fq 'If optional work is removed, decrement `totalTasks`, keep `taskIndex` unchanged, reset `taskIteration` to 1, and rebuild `nativeTaskMap`' "$COORDINATOR"
}

@test "native task rebuilding preserves verification task identities" {
    grep -Fq 'such as `V1`, `VF`, or `VE1`' "$COORDINATOR"
}

@test "planner records adjacent issues as learnings instead of tasks" {
    grep -Eiq 'adjacent (finding|issue).*(learning|learnings)' "$TASK_PLANNER"
    grep -Eiq 'adjacent (finding|issue).*(not|never).*(task|tasks)|(not|never).*(task|tasks).*adjacent (finding|issue)' "$TASK_PLANNER"
}

@test "architect uses the ordered minimal-implementation decision" {
    assert_minimal_implementation_order "$ARCHITECT_REVIEWER"
}

@test "planner uses the ordered minimal-implementation decision" {
    assert_minimal_implementation_order "$TASK_PLANNER"
}

@test "executor uses the ordered minimal-implementation decision" {
    assert_minimal_implementation_order "$SPEC_EXECUTOR"
}

@test "dependencies require evidence that existing choices cannot satisfy the requirement" {
    for file in "$ARCHITECT_REVIEWER" "$TASK_PLANNER" "$SPEC_EXECUTOR"; do
        grep -Fq 'A dependency requires evidence that steps 1-3 cannot satisfy a current requirement.' "$file"
    done
}

@test "abstractions require two current uses or an explicit design requirement" {
    for file in "$ARCHITECT_REVIEWER" "$TASK_PLANNER" "$SPEC_EXECUTOR"; do
        grep -Fq 'An abstraction requires two current uses or an explicit design requirement.' "$file"
    done
}

@test "minimal implementation preserves required safeguards and verification" {
    for file in "$ARCHITECT_REVIEWER" "$TASK_PLANNER" "$SPEC_EXECUTOR"; do
        grep -Fq 'The order cannot remove required validation, safety, accessibility, error handling, acceptance criteria, or verification.' "$file"
    done
}

@test "modified prompts do not import or identify the source skills" {
    ! grep -Eiq '(ponytail|stay-in-scope)/SKILL\.md|Skill\(\{[^}]*skill:[[:space:]]*"(ralph-specum:)?(ponytail|stay-in-scope)"' "${MODIFIED_PROMPTS[@]}"
    ! grep -Eq '^# (Ponytail|Stay in scope)$' "${MODIFIED_PROMPTS[@]}"
}

@test "spec verification commands fail closed" {
    ! grep -Fq '**Verify**: `! bats' "$SPEC_TASKS"
    grep -Fq 'git diff --exit-code origin/main -- specs/.index' "$SPEC_TASKS"
    grep -Fq 'markdown_diff="$(mktemp)"' "$SPEC_TASKS"
    grep -Fq "all(.statusCheckRollup[]; if .__typename == \"CheckRun\" then .conclusion == \"SUCCESS\" else .state == \"SUCCESS\" end)" "$SPEC_TASKS"
}

@test "review-thread verification preserves query failure status" {
    grep -Fq 'review_threads="$(gh api graphql' "$SPEC_TASKS"
    grep -Fq ')" && test -z "$review_threads"' "$SPEC_TASKS"

    run bash -c 'gh() { return 42; }; review_threads="$(gh api graphql)" && test -z "$review_threads"'
    [ "$status" -eq 42 ]
}

@test "acceptance evidence covers AC-1.1 through AC-4.3" {
    local ac
    grep -Fq '### Acceptance Evidence' "$SPEC_TASKS"
    for ac in AC-1.1 AC-1.2 AC-1.3 AC-1.4 AC-1.5 \
              AC-2.1 AC-2.2 AC-2.3 AC-2.4 AC-2.5 \
              AC-3.1 AC-3.2 AC-3.3 AC-3.4 AC-3.5 AC-3.6 AC-3.7 \
              AC-4.1 AC-4.2 AC-4.3; do
        grep -Fq "| $ac |" "$SPEC_TASKS"
    done
}
