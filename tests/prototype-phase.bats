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

@test "prototype phase: conflict decisions persist the approved deadline retry and late-reply runtime" {
    local coordinator

    for coordinator in "$(claude_coordinator)" "$(codex_coordinator)"; do
        assert_has "$coordinator" 'Start conflict-decision runtime only when.*same downstream target.*incompatible evidence'
        assert_has "$coordinator" 'half the resolved initial builder timeout'
        assert_has "$coordinator" 'prototype_conflict_timeout_min_minutes.*prototype_conflict_timeout_max_minutes'
        assert_has "$coordinator" 'Quick timeout is 0 minutes'
        assert_has "$coordinator" 'reset `decisionDeadline` once'
        assert_has "$coordinator" 'decisionDeadline.*resolvedAt: null.*conflictResolutionAttempt: 0.*maxConflictResolutionRetries'
        assert_has "$coordinator" 'locked compare-and-set `transition`'
        assert_has "$coordinator" 'conflictResolutionAttempt <= maxConflictResolutionRetries'
        assert_has "$coordinator" 'first later safe boundary'
        assert_has "$coordinator" 'Normal mode keeps dependent work blocked after failed resolution'
        assert_has "$coordinator" 'Quick mode writes an exclusion record.*continues'
        assert_has "$coordinator" 'reply arrives after expiry.*automatic resolution first.*supersedes'
    done
}

@test "prototype phase: reservation is exclusive and lease mutations require the claimed token" {
    local coordinator

    for coordinator in "$(claude_coordinator)" "$(codex_coordinator)"; do
        assert_has "$coordinator" '`upsert-prototype` is create-only and exclusive'
        assert_has "$coordinator" 'existing ID as a collision'
        assert_has "$coordinator" 'Update an existing entry only through compare-and-set `transition`'
        assert_has "$coordinator" 'pass that exact token to every `heartbeat`, `renew-lease`, and `release-lease` call'
        assert_has "$coordinator" 'token or revision mismatch.*without launching another builder'
    done
}

@test "prototype phase: every push instruction gates outbound prototype records" {
    local root file count
    root="$(repo_root)"
    count=0

    while IFS= read -r file; do
        assert_has "$file" 'Prototype Evidence Push Gate'
        count=$((count + 1))
    done < <(rg -l --glob '*.md' '\bgit push\b' \
        "$root/plugins/ralph-specum" \
        "$root/plugins/ralph-specum-codex")

    [ "$count" -gt 0 ]
    assert_has "$root/plugins/ralph-specum/references/commit-discipline.md" "git log --format= --name-only <remote-target>..HEAD -- '\*\*/prototypes/\*.md'"
    assert_has "$root/plugins/ralph-specum/references/commit-discipline.md" 'authorization naming every exact record path'
    assert_has "$root/plugins/ralph-specum/references/commit-discipline.md" '`commitSpec` remains local commit authorization'
    assert_has "$root/plugins/ralph-specum/references/commit-discipline.md" 'Quick mode asks no question and skips the push'
    assert_has "$root/plugins/ralph-specum/references/commit-discipline.md" 'Never push an isolated `prototype/<spec>/<id>` source branch'
    assert_has "$root/plugins/ralph-specum/references/quick-mode.md" 'Quick mode never asks for push authorization and never pushes'
    assert_both_coordinators 'Never push an isolated prototype source branch'

    for file in research requirements design tasks; do
        assert_has "$(claude_command "$file")" 'In quick mode.*do not push'
    done
}

@test "prototype phase: a skipped push ends every dependent remote lifecycle path" {
    local root file output
    root="$(repo_root)"

    for file in \
        "$root/plugins/ralph-specum/references/commit-discipline.md" \
        "$root/plugins/ralph-specum/references/coordinator-pattern.md" \
        "$root/plugins/ralph-specum/agents/task-planner.md" \
        "$root/plugins/ralph-specum/commands/implement.md" \
        "$root/plugins/ralph-specum/templates/tasks.md" \
        "$root/plugins/ralph-specum-codex/references/workflow.md" \
        "$root/plugins/ralph-specum-codex/skills/ralph-specum-implement/SKILL.md" \
        "$root/plugins/ralph-specum-codex/templates/tasks.md"; do
        assert_has "$file" 'Prototype Evidence Push Gate'
        assert_has "$file" 'dependent remote lifecycle'
        assert_has "$file" 'gh pr create'
        assert_has "$file" 'gh pr merge'
        assert_has "$file" 'gh pr checks'
        assert_has "$file" 'gh issue'
        assert_has "$file" 'remote review polling'
        assert_has "$file" 'issue writes'
        assert_has "$file" 'Remote lifecycle skipped: prototype evidence stayed local'
    done

    for file in \
        "$root/plugins/ralph-specum/templates/tasks.md" \
        "$root/plugins/ralph-specum-codex/templates/tasks.md"; do
        assert_has "$file" 'Only after step .* completes a permitted push, create the PR.*gh pr create'
        assert_has "$file" 'Enter this remote loop only after.*permitted push'
        assert_has "$file" 'Enter this remote review path only while the permitted-push PR lifecycle is active'
        assert_has "$file" 'all applicable completion criteria are met'
        assert_has "$file" 'All applicable commands pass and all applicable criteria are documented'
        assert_has "$file" 'local remote-lifecycle-skipped report is terminal'

        run sed -n '/^> \*\*Prototype Evidence Push Gate\*\*/,/^> \*\*Default Behavior\*\*/p' "$file"
        [ "$status" -eq 0 ]
        [[ "$output" != *$'\n\n'* ]]
    done

    run rg -n 'ALL completion criteria met|Done when.*All completion criteria' \
        "$root/plugins/ralph-specum/templates/tasks.md" \
        "$root/plugins/ralph-specum-codex/templates/tasks.md"
    [ "$status" -eq 1 ]

    assert_has "$root/plugins/ralph-specum/references/coordinator-pattern.md" 'Enter or continue this loop only after the Prototype Evidence Push Gate completes the required push'
    assert_has "$root/plugins/ralph-specum-codex/references/workflow.md" 'When the gate permits and completes the push, preserve the existing normal remote lifecycle'

    file="$root/specs/optional-prototype-phase/tasks.md"
    assert_has "$file" 'Only after the gate permits and completes the feature-branch push'
    assert_has "$file" 'skipped or denied push is terminal'
    assert_has "$file" 'run no dependent PR creation, CI wait, review polling, issue write, or other remote lifecycle step'
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
    local quick codex_requirements codex_help
    quick="$(repo_root)/plugins/ralph-specum/references/quick-mode.md"
    codex_requirements="$(codex_skill requirements)"
    codex_help="$(codex_skill help)"

    assert_has "$quick" 'oldest by `created` timestamp'
    assert_has "$quick" 'highest-risk grounded falsifiable question'
    assert_has "$quick" 'skipped: no suitable question'
    assert_has "$quick" 'one allowed mechanical retry is 2'
    assert_has "$quick" 'Extra active entries remain preserved'
    assert_has "$codex_requirements" 'oldest prototype that blocks design'
    assert_has "$codex_requirements" 'highest-risk grounded, falsifiable question'
    assert_has "$codex_requirements" 'no suitable question exists'
    assert_has "$codex_requirements" 'builderExecutionAttempt'
    assert_has "$codex_help" 'highest-risk grounded, falsifiable question when no blocker exists'
    assert_both_coordinators 'one mechanical retry at most'
}

@test "prototype phase: command and research docs describe the shipped overlay" {
    local root design_prompt claude_help new_command workflow research
    root="$(repo_root)"
    design_prompt="$root/plugins/ralph-specum-codex/skills/ralph-specum-design/agents/openai.yaml"
    claude_help="$root/plugins/ralph-specum/commands/help.md"
    new_command="$root/plugins/ralph-specum/commands/new.md"
    workflow="$root/plugins/ralph-specum/skills/spec-workflow/SKILL.md"
    research="$root/specs/optional-prototype-phase/research.md"

    assert_has "$design_prompt" 'Write design.md directly'
    assert_has "$design_prompt" 'leave routing, blocker delegation, and the next design-decision handoff to the parent coordinator'
    run rg -n 'default_prompt: "Use \$ralph-specum-design' "$design_prompt"
    [ "$status" -eq 1 ]

    assert_has "$claude_help" '/ralph-specum:prototype \[--resume ID \\| --cancel ID \\| --quick\]'
    assert_has "$new_command" 'phase: \$phase'
    assert_has "$new_command" 'Starting \$phase phase'
    assert_has "$new_command" 'Complete \$phase, then proceed to \$nextPhase'
    grep -Fq '[[ "$ARGUMENTS" =~ (^|[[:space:]])--skip-research($|[[:space:]]) ]]' "$new_command"
    ! grep -Fq '== *"--skip-research"*' "$new_command"
    assert_has "$workflow" 'resolved `<basePath>/`'

    assert_has "$research" 'main state value remains `research`, `requirements`, `design`, `tasks`, or `execution`'
    assert_has "$research" 'Quick mode runs one bounded, question-free request after requirements'
    assert_has "$research" 'earlier main-state `phase: prototype` proposal is superseded'
    assert_has "$research" 'Keep `prototype` out of the main phase enum'
    run rg -n 'Quick mode skips prototype|Default and quick workflows skip it' "$research"
    [ "$status" -eq 1 ]
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
    assert_has "$claude_reviewer" 'For prototype, output `REVIEW_PASS` only when every Prototype Rubric dimension is PASS'
    assert_has "$claude_reviewer" 'ARTIFACT_PATH="<exact artifactPath from delegation>"'
    assert_has "$claude_reviewer" 'bash "\$LINT" "\$ARTIFACT_PATH"'
    assert_has "$claude_reviewer" 'one row for every applicable rubric dimension'
    assert_has "$claude_reviewer" 'Requirements reviews include all five judgment dimensions and C1-C8'
    assert_has "$claude_reviewer" 'Prototype reviews include all eight Prototype Rubric dimensions'
    run rg -n 'bash "\$LINT" <artifactPath>|\| 1 \| Completeness \| PASS \| All sections present \|' "$claude_reviewer"
    [ "$status" -eq 1 ]
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

@test "prototype phase: coordinator recovery and dispatch contracts fail closed" {
    local root claude_start claude_implement claude_refactor claude_cancel codex_start codex_implement codex_refactor codex_cancel codex_requirements codex_switch count_line selection_line scope_line
    root="$(repo_root)"
    claude_start="$(claude_command start)"
    claude_implement="$(claude_command implement)"
    claude_refactor="$(claude_command refactor)"
    claude_cancel="$(claude_command cancel)"
    codex_start="$(codex_skill start)"
    codex_implement="$(codex_skill implement)"
    codex_refactor="$(codex_skill refactor)"
    codex_cancel="$(codex_skill cancel)"
    codex_requirements="$(codex_skill requirements)"
    codex_switch="$(codex_skill switch)"

    assert_has "$claude_start" 'classified target'
    assert_has "$claude_start" 'new-spec.*skip|skip.*new-spec'
    assert_has "$claude_start" 'resume_review.*candidate ID.*candidate hash|candidate ID.*candidate hash.*resume_review'
    assert_has "$codex_start" 'resume_review.*candidate ID.*candidate hash|candidate ID.*candidate hash.*resume_review'
    assert_has "$codex_start" 'Quick mode.*does not reach.*Response Handoff|quick mode.*does not reach.*Response Handoff'

    assert_has "$claude_implement" 'fresh execution'
    assert_has "$claude_implement" 'returnTaskIndex'
    assert_has "$claude_implement" 'targetDecisions'
    count_line=$(grep -n 'TOTAL=$(grep' "$claude_implement" | head -1 | cut -d: -f1)
    selection_line=$(grep -n 'select-downstream.*task:\$TASK_INDEX' "$claude_implement" | head -1 | cut -d: -f1)
    [ "$count_line" -lt "$selection_line" ]
    scope_line=$(grep -n 'Check `\$ARGUMENTS` for `--file=` flag' "$claude_refactor" | head -1 | cut -d: -f1)
    selection_line=$(grep -n 'select-downstream.*--target "\$FILE"' "$claude_refactor" | head -1 | cut -d: -f1)
    [ "$scope_line" -lt "$selection_line" ]
    assert_has "$codex_implement" 'prototype history'
    assert_has "$codex_implement" 'targetDecisions'
    assert_has "$codex_refactor" 'whenever.*\.ralph-state\.json.*exists|\.ralph-state\.json.*exists.*whenever'

    assert_has "$claude_cancel" 'leaseToken'
    assert_has "$claude_cancel" 'verified.*interrupt|interrupt.*verified'
    assert_has "$claude_cancel" 'upsert-prototype'
    assert_has "$claude_cancel" 'supersedes'
    assert_has "$claude_cancel" 'candidateHash'
    assert_has "$claude_cancel" 'original active entry.*final verification|final verification.*original active entry'
    assert_has "$claude_start" 'resume_review.*upsert-prototype|upsert-prototype.*resume_review'
    assert_has "$claude_start" 'candidateHash'
    assert_has "$claude_start" 'create-only'
    assert_has "$codex_cancel" 'leaseToken'
    assert_has "$codex_cancel" 'unavailable or unverified'
    assert_has "$codex_cancel" 'upsert-prototype'
    assert_has "$codex_cancel" 'superseding ID'
    assert_has "$codex_cancel" 'candidateHash'
    assert_has "$codex_cancel" 'original active entry.*final verification|final verification.*original active entry'
    assert_has "$codex_start" 'resume_review.*upsert-prototype|upsert-prototype.*resume_review'
    assert_has "$codex_start" 'candidateHash'
    assert_has "$codex_start" 'create-only'
    assert_has "$codex_requirements" 'normal mode only'
    assert_has "$codex_switch" 'returnPhase'
    assert_has "$codex_switch" 'returnTaskIndex'

    assert_has "$root/plugins/ralph-specum/references/branch-management.md" 'If the source-state read fails'
    assert_has "$root/plugins/ralph-specum/agents/research-analyst.md" 'BASE_PATH='
    assert_has "$root/plugins/ralph-specum/agents/task-planner.md" 'BASE_PATH='
    assert_has "$root/plugins/ralph-specum/skills/smart-ralph/references/state-file-schema.md" 'prototypes/\.<prototype-id>\.candidate\.md'
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
