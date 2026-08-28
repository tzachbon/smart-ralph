#!/usr/bin/env bats

repo_root() {
    echo "$BATS_TEST_DIRNAME/.."
}

claude_command() {
    echo "$(repo_root)/plugins/ralph-specum/commands/$1.md"
}

codex_skill() {
    echo "$(repo_root)/plugins/ralph-specum-codex/skills/ralph-specum-$1/SKILL.md"
}

claude_coordinator() {
    echo "$(repo_root)/plugins/ralph-specum/references/prototype-coordinator.md"
}

codex_coordinator() {
    echo "$(repo_root)/plugins/ralph-specum-codex/references/prototype-coordinator.md"
}

claude_harness() {
    echo "$(repo_root)/plugins/ralph-specum/hooks/scripts/prototype-harness.py"
}

harness_json() {
    local path
    path="$1"
    python3 -c 'import json, sys
value = json.load(sys.stdin)
for part in sys.argv[1].split("."):
    value = value[part]
if isinstance(value, bool):
    print(str(value).lower())
else:
    print(value)' "$path"
}

wait_for_prototype_pid_exit() {
    local pid attempt
    pid="$1"
    for attempt in $(seq 1 100); do
        if ! kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
        sleep 0.02
    done
    return 1
}

setup() {
    export PYTHONDONTWRITEBYTECODE=1
    PROTOTYPE_HARNESS_PID=""
}

teardown() {
    if [ -n "$PROTOTYPE_HARNESS_PID" ] && kill -0 "$PROTOTYPE_HARNESS_PID" 2>/dev/null; then
        kill -TERM "-$PROTOTYPE_HARNESS_PID" 2>/dev/null \
            || kill -TERM "$PROTOTYPE_HARNESS_PID" 2>/dev/null \
            || true
    fi
}

assert_has() {
    local file pattern
    file="$1"
    pattern="$2"
    rg -q -- "$pattern" "$file"
}

assert_both_coordinators() {
    local pattern
    pattern="$1"
    assert_has "$(claude_coordinator)" "$pattern"
    assert_has "$(codex_coordinator)" "$pattern"
}

@test "prototype phase: normal research and requirements offer prototype without forcing it" {
    local claude_research claude_requirements codex_research codex_requirements
    claude_research="$(claude_command research)"
    claude_requirements="$(claude_command requirements)"
    codex_research="$(codex_skill research)"
    codex_requirements="$(codex_skill requirements)"

    assert_has "$claude_research" 'continue to prototype'
    assert_has "$claude_research" 'Continue to requirements.*without creating a prototype'
    assert_has "$claude_requirements" 'continue to prototype'
    assert_has "$claude_requirements" 'Continue to design.*without creating a prototype'
    assert_has "$codex_research" 'continue to requirements'
    assert_has "$codex_research" 'continue to prototype'
    assert_has "$codex_research" 'when the user selects `continue to prototype`'
    assert_has "$codex_requirements" 'continue to design'
    assert_has "$codex_requirements" 'continue to prototype'
    assert_has "$codex_requirements" 'when the user selects `continue to prototype`'
}

@test "prototype phase: direct invocation preserves any origin and stops only at a safe boundary" {
    local claude codex
    claude="$(claude_command prototype)"
    codex="$(codex_skill prototype)"

    assert_has "$claude" 'Accept direct invocation by default'
    assert_has "$claude" 'Preserve the current main phase and current checkout'
    assert_has "$claude" 'Stop at safe tool boundaries'
    assert_has "$codex" 'direct by default'
    assert_has "$codex" 'keep the main Ralph phase unchanged'
    assert_has "$(codex_coordinator)" 'direct.*preserve the current phase as `returnPhase`'
    assert_has "$(codex_coordinator)" 'Stop at a safe tool boundary'
    assert_has "$(claude_coordinator)" 'Do not interrupt a running tool call'
}

@test "prototype phase: capture choice and retained isolation failure stay user-owned in normal mode" {
    assert_both_coordinators 'Recommend `retained`'
    assert_both_coordinators 'Recommend `ephemeral`'
    assert_both_coordinators 'Show both'
    assert_both_coordinators 'If retained isolation fails, ask whether to wait, cancel, or'
    assert_both_coordinators 'self-contained logic.*file'
    assert_both_coordinators 'Quick.*never transfers dirty paths'
}

@test "prototype phase: cancellation preserves source and handoff restores the recorded origin" {
    assert_both_coordinators 'publish an immutable `cancelled` record'
    assert_both_coordinators 'Preserve source, partial implementation, origin phase, return phase, return task index'
    assert_both_coordinators 'Remove the active entry only after final verification'
    assert_has "$(claude_coordinator)" 'return to the recorded phase or task'
    assert_has "$(codex_coordinator)" 'resume the recorded phase or task'
    assert_both_coordinators 'Normal mode has two user-owned checkpoints'
    assert_both_coordinators 'Ask whether.*include or exclude'
}

@test "prototype phase: duplicate and conflict decisions are explicit and bounded" {
    assert_both_coordinators 'same question.*offer resume, supersede, or a distinct record'
    assert_both_coordinators 'incompatible evidence.*conflict set'
    assert_both_coordinators '(?i)quick mode.*supported evidence.*exclude'
    assert_both_coordinators 'count.*result.*one request'
    assert_both_coordinators 'quick takes over the oldest blocking entry|quick mode take over the oldest blocking entry'
}

@test "prototype phase: quick mode has one post-requirements request and no delegated decisions" {
    local root claude_count codex_count
    root="$(repo_root)"
    claude_count="$(rg -F '/ralph-specum:prototype --quick --return-phase design' \
        "$root/plugins/ralph-specum/references/quick-mode.md" \
        "$root/plugins/ralph-specum/commands/research.md" \
        "$root/plugins/ralph-specum/commands/requirements.md" | wc -l | tr -d '[:space:]')"
    codex_count="$(rg -F '$ralph-specum-prototype --quick --return-phase design' \
        "$root/plugins/ralph-specum-codex/skills/ralph-specum-research/SKILL.md" \
        "$root/plugins/ralph-specum-codex/skills/ralph-specum-requirements/SKILL.md" | wc -l | tr -d '[:space:]')"
    [ "$claude_count" -eq 1 ]
    [ "$codex_count" -eq 1 ]
    assert_has "$root/plugins/ralph-specum/references/quick-mode.md" 'only quick prototype call site'
    assert_has "$(codex_skill research)" 'Do not request a prototype from research'
    assert_has "$(codex_skill requirements)" 'Make exactly one request'
    assert_has "$root/plugins/ralph-specum/references/quick-mode.md" 'without asking the user'
    assert_has "$root/plugins/ralph-specum/references/quick-mode.md" 'never delegates a decision to the user'
    assert_has "$(codex_skill requirements)" 'Ask no user questions'
}

@test "prototype phase: quick selection, skip, takeover, and retry rules are deterministic" {
    local quick codex_requirements
    quick="$(repo_root)/plugins/ralph-specum/references/quick-mode.md"
    codex_requirements="$(codex_skill requirements)"

    assert_has "$quick" 'oldest by `created` timestamp'
    assert_has "$quick" 'highest-risk grounded falsifiable question'
    assert_has "$quick" 'skipped: no suitable question'
    assert_has "$quick" 'one allowed mechanical retry is 2'
    assert_has "$quick" 'Extra active entries remain preserved'
    assert_has "$codex_requirements" 'oldest prototype that blocks design'
    assert_has "$codex_requirements" 'highest-risk grounded, falsifiable question'
    assert_has "$codex_requirements" 'no suitable question exists'
    assert_has "$codex_requirements" 'builderExecutionAttempt'
    assert_both_coordinators 'one mechanical retry at most'
}

@test "prototype phase: every quick result continues to design" {
    local root
    root="$(repo_root)"
    assert_has "$root/plugins/ralph-specum/references/quick-mode.md" 'Continue to design after every result'
    assert_has "$(claude_coordinator)" 'Every quick outcome continues to design, including duplicate, conflict, timeout, lock failure, builder failure, and skip'
    assert_has "$(codex_coordinator)" 'Every quick result continues to design'
    assert_has "$(codex_skill requirements)" 'Continue to design after every result'
    assert_has "$(claude_command prototype)" 'continue to design without a user stop'
    assert_has "$(codex_skill prototype)" 'continue to design after every terminal outcome'
}

@test "prototype phase: logic and UI builders have matching falsifiable contracts" {
    local root claude_builder codex_builder
    root="$(repo_root)"
    claude_builder="$root/plugins/ralph-specum/agents/prototype-builder.md"
    codex_builder="$root/plugins/ralph-specum-codex/agent-configs/prototype-builder.toml.template"

    for pattern in \
        'self-contained interactive HTML' \
        'falsifiable question' \
        'pure non-DOM module' \
        'free play.*normal, edge, and illegal' \
        'exactly three variants' \
        'fixed-bottom.*switcher' \
        'left and right arrow keys' \
        'development-only production gate'; do
        assert_has "$claude_builder" "$pattern"
        assert_has "$codex_builder" "$pattern"
    done
}

@test "prototype phase: reviewer pass and fail signals gate exact candidate evidence" {
    local root claude_reviewer codex_reviewer
    root="$(repo_root)"
    claude_reviewer="$root/plugins/ralph-specum/agents/spec-reviewer.md"
    codex_reviewer="$root/plugins/ralph-specum-codex/agent-configs/spec-reviewer.toml.template"

    assert_has "$claude_reviewer" 'artifactType: prototype'
    assert_has "$claude_reviewer" 'exact candidate file bytes'
    assert_has "$claude_reviewer" 'Every review MUST end with exactly one of: `REVIEW_PASS` or `REVIEW_FAIL`'
    assert_has "$claude_reviewer" 'Any missing input or mismatch is REVIEW_FAIL|A missing input is a failure'
    assert_has "$codex_reviewer" 'exact candidate file bytes'
    assert_has "$codex_reviewer" 'Every response must end with exactly REVIEW_PASS or REVIEW_FAIL'
    assert_has "$codex_reviewer" 'Any missing input or mismatch is REVIEW_FAIL'
    assert_has "$codex_reviewer" 'only when every prototype dimension passes'
}

@test "prototype phase: design and task generation enforce active and stale gates on both surfaces" {
    local claude_design claude_tasks codex_design codex_tasks
    claude_design="$(claude_command design)"
    claude_tasks="$(claude_command tasks)"
    codex_design="$(codex_skill design)"
    codex_tasks="$(codex_skill tasks)"

    for file in "$claude_design" "$claude_tasks" "$codex_design" "$codex_tasks"; do
        assert_has "$file" 'select-downstream'
        assert_has "$file" 'gateApproved: true'
        assert_has "$file" 'activePrototypes.*blocker'
        assert_has "$file" 'stale'
        assert_has "$file" 'unrelated'
    done
    assert_has "$claude_design" 'stop and route to the earliest stale phase or task'
    assert_has "$claude_tasks" 'Do not generate tasks from stale design'
    assert_has "$codex_design" 'Route to the earliest stale phase'
    assert_has "$codex_tasks" 'Route to the earliest stale phase'
}

@test "prototype harness: Claude launch wait status heartbeat and interrupt are bounded" {
    local script registry pid
    script="$(claude_harness)"
    registry="$BATS_TEST_TMPDIR/claude-harness"

    run python3 "$script" launch \
        --registry "$registry" \
        --id claude-complete \
        --kind claude_background \
        --command-json '["python3","-c","print(\"claude complete\")"]' \
        --soft-timeout 1 \
        --activity-extension 1 \
        --hard-timeout 2
    [ "$status" -eq 0 ]
    [ "$(harness_json outcome <<< "$output")" = "launched" ]
    pid="$(harness_json pid <<< "$output")"
    PROTOTYPE_HARNESS_PID="$pid"

    run python3 "$script" wait --registry "$registry" --id claude-complete --until-seconds 1 --poll-seconds 0.02
    [ "$status" -eq 0 ]
    [ "$(harness_json outcome <<< "$output")" = "completed" ]
    [[ "$(harness_json output <<< "$output")" == *"claude complete"* ]]
    run python3 "$script" status --registry "$registry" --id claude-complete
    [ "$status" -eq 0 ]
    [ "$(harness_json outcome <<< "$output")" = "completed" ]
    wait_for_prototype_pid_exit "$pid"

    run python3 "$script" launch \
        --registry "$registry" \
        --id claude-live \
        --kind claude_background \
        --command-json '["python3","-c","import time; time.sleep(30)"]' \
        --soft-timeout 0.4 \
        --activity-extension 1 \
        --hard-timeout 3
    [ "$status" -eq 0 ]
    pid="$(harness_json pid <<< "$output")"
    PROTOTYPE_HARNESS_PID="$pid"
    run python3 "$script" heartbeat --registry "$registry" --id claude-live
    [ "$status" -eq 0 ]
    [ "$(harness_json outcome <<< "$output")" = "heartbeat" ]
    run python3 "$script" interrupt --registry "$registry" --id claude-live
    [ "$status" -eq 0 ]
    [ "$(harness_json outcome <<< "$output")" = "stopped" ]
    wait_for_prototype_pid_exit "$pid"
    PROTOTYPE_HARNESS_PID=""
}

@test "prototype harness: Claude soft and hard timeouts leave no child" {
    local script registry pid
    script="$(claude_harness)"
    registry="$BATS_TEST_TMPDIR/claude-harness"

    run python3 "$script" launch \
        --registry "$registry" \
        --id claude-soft \
        --kind claude_background \
        --command-json '["python3","-c","import time; time.sleep(30)"]' \
        --soft-timeout 0.15 \
        --activity-extension 0.15 \
        --hard-timeout 3
    [ "$status" -eq 0 ]
    pid="$(harness_json pid <<< "$output")"
    PROTOTYPE_HARNESS_PID="$pid"
    run python3 "$script" wait --registry "$registry" --id claude-soft --until-seconds 0.6 --poll-seconds 0.02
    [ "$status" -eq 0 ]
    [ "$(harness_json outcome <<< "$output")" = "timeout" ]
    [ "$(harness_json hard <<< "$output")" = "false" ]
    run python3 "$script" interrupt --registry "$registry" --id claude-soft
    [ "$status" -eq 0 ]
    wait_for_prototype_pid_exit "$pid"

    run python3 "$script" launch \
        --registry "$registry" \
        --id claude-hard \
        --kind claude_background \
        --command-json '["python3","-c","import time; time.sleep(30)"]' \
        --soft-timeout 0.2 \
        --activity-extension 0.2 \
        --hard-timeout 0.2
    [ "$status" -eq 0 ]
    pid="$(harness_json pid <<< "$output")"
    PROTOTYPE_HARNESS_PID="$pid"
    run python3 "$script" wait --registry "$registry" --id claude-hard --until-seconds 1 --poll-seconds 0.02
    [ "$status" -eq 0 ]
    [ "$(harness_json outcome <<< "$output")" = "timeout" ]
    [ "$(harness_json hard <<< "$output")" = "true" ]
    wait_for_prototype_pid_exit "$pid"
    PROTOTYPE_HARNESS_PID=""
}

@test "prototype harness: Claude failures and Codex child identifier contract are explicit" {
    local script registry codex
    script="$(claude_harness)"
    registry="$BATS_TEST_TMPDIR/claude-harness"
    codex="$(codex_skill prototype)"

    run python3 "$script" launch \
        --registry "$registry" \
        --id claude-unavailable \
        --kind claude_background \
        --command-json '["python3","-c","print(1)"]' \
        --unavailable-control
    [ "$status" -eq 0 ]
    [ "$(harness_json outcome <<< "$output")" = "unavailable-control" ]

    run python3 "$script" status --registry "$registry" --id 'bad/id'
    [ "$status" -eq 2 ]
    [ "$(harness_json outcome <<< "$output")" = "invalid-id" ]

    assert_has "$codex" 'Store only the returned `agentId`'
    assert_has "$codex" 'Never use `create_thread` or a `threadId`'
    assert_has "$(codex_coordinator)" 'Store only its `agentId`'
    assert_has "$(codex_coordinator)" 'Never use `create_thread`, a user-visible task, or `threadId`'
}
