#!/usr/bin/env bats

set -e

repo_root() {
    echo "$BATS_TEST_DIRNAME/.."
}

plugin_root() {
    echo "$(repo_root)/plugins/ralph-specum"
}

setup() {
    TEST_DIR="$(mktemp -d)"
}

teardown() {
    if [ -n "${TEST_DIR:-}" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

prepare_approved_state() {
    local state=$1
    local phase=$2
    local interview_id=$3
    local digest=$4
    local goal=$5
    local helper skill algorithm domain skill_hash algorithm_hash domain_hash manifest
    helper="$(plugin_root)/scripts/phase_gate.py"
    skill="$(plugin_root)/skills/interview-framework/SKILL.md"
    algorithm="$(plugin_root)/skills/interview-framework/references/algorithm.md"
    domain="$(plugin_root)/skills/interview-framework/references/domain-modeling.md"
    skill_hash="$(shasum -a 256 "$skill" | awk '{print $1}')"
    algorithm_hash="$(shasum -a 256 "$algorithm" | awk '{print $1}')"
    domain_hash="$(shasum -a 256 "$domain" | awk '{print $1}')"
    manifest="$state.manifest.json"

    mkdir -p "$(dirname "$state")"
    jq -n --arg goal "$goal" --arg name "interview-framework" --arg skill "$skill" \
        '{goal:$goal,discoveredSkills:[{pass:"pass1",revision:"rev-1",name:$name,activeSource:$skill,reason:"core",shadowedSources:[],outcome:"selected"}]}' \
        > "$state"
    jq -n \
        --arg phase "$phase" --arg interview_id "$interview_id" \
        --arg skill "$skill" --arg skill_hash "$skill_hash" \
        --arg algorithm "$algorithm" --arg algorithm_hash "$algorithm_hash" \
        --arg domain "$domain" --arg domain_hash "$domain_hash" \
        --arg digest "$digest" --arg goal "$goal" \
        '{phase:$phase,interviewId:$interview_id,discoveryRevision:"rev-1",contextDigest:$digest,context:{goal:$goal,artifacts:[]},status:"complete",selected:[{name:"interview-framework",reason:"core",source:$skill,core:true,body:{sha256:$skill_hash,loadStatus:"loaded",errors:[]},requiredResourceSources:[$algorithm,$domain],requiredResources:[{source:$algorithm,sha256:$algorithm_hash,loadStatus:"loaded",errors:[]},{source:$domain,sha256:$domain_hash,loadStatus:"loaded",errors:[]}]}],warnings:[],conflicts:[],failures:[],noDomainMatches:true,artifactAgentLoads:[]}' > "$manifest"
    python3 "$helper" mode "$state" --interactive >/dev/null
    python3 "$helper" record-skill-load "$state" --input "$manifest" >/dev/null
    python3 "$helper" begin-interview "$state" --phase "$phase" --interview-id "$interview_id" --round 1 --discovery-revision rev-1 --context-digest "$digest" >/dev/null
    python3 "$helper" open-frontier "$state" --round 1 --decision-id scope >/dev/null
    python3 "$helper" record-answer "$state" --decision-id scope --answer 'Keep the existing contract' >/dev/null
    python3 "$helper" await-confirmation "$state" --decision-id final-approval --approach 'Keep the existing contract' >/dev/null
    python3 "$helper" confirm "$state" --decision-id final-approval --source 'approve-and-delegate' >/dev/null
}

gate_prompt() {
    local state=$1
    local phase=$2
    local interview_id=$3
    local digest=$4
    printf '[RALPH_PHASE_GATE]\nstate=%s\nphase=%s\ninterviewId=%s\ndiscoveryRevision=rev-1\ncontextDigest=%s' \
        "$state" "$phase" "$interview_id" "$digest"
}

context_digest() {
    local phase=$1
    local goal=$2
    python3 - "$phase" "$goal" <<'PY'
import hashlib
import sys

def frame(value):
    return str(len(value)).encode("ascii") + b":" + value

phase = sys.argv[1].encode("utf-8")
goal = sys.argv[2].encode("utf-8")
print(hashlib.sha256(b"".join([
    frame(b"ralph-phase-context-v1"),
    frame(phase),
    frame(goal),
])).hexdigest())
PY
}

@test "all affected Claude commands use the normal gate contract and exact mode flags" {
    local command
    for command in start triage research requirements design tasks; do
        run grep -q 'references/normal-mode-gates.md' "$(plugin_root)/commands/$command.md"
        [ "$status" -eq 0 ]
        run grep -q -- '--quick|--interactive' "$(plugin_root)/commands/$command.md"
        [ "$status" -eq 0 ]
        grep -q 'classify-reply' "$(plugin_root)/commands/$command.md"
        grep -q 'revise --decision-id' "$(plugin_root)/commands/$command.md"
        grep -q 'confirm --source approve-and-delegate' "$(plugin_root)/commands/$command.md"
        grep -q 'both interactive and exact quick mode' "$(plugin_root)/commands/$command.md"
        grep -q 'record.*current.*manifest' "$(plugin_root)/commands/$command.md"
    done
}

@test "interview contract uses whole critical frontiers and transition persistence" {
    local skill algorithm gates
    skill="$(plugin_root)/skills/interview-framework/SKILL.md"
    algorithm="$(plugin_root)/skills/interview-framework/references/algorithm.md"
    gates="$(plugin_root)/references/normal-mode-gates.md"

    grep -q 'whole currently unblocked critical frontier' "$skill"
    grep -q 'open-frontier' "$skill"
    grep -q 'Control-only reply' "$skill"
    grep -q 'skip-confirmation' "$skill"
    grep -q 'resumed: true' "$gates"
    grep -q 'immutable interview inputs only' "$gates"
    grep -q 'classify-reply' "$gates"
    grep -q 'revise.*--decision-id' "$gates"
    grep -q 'rejects terminal interviews' "$gates"
    grep -q 'call one `revise` transition with every affected ID' "$gates"
    grep -q 'Apply clear instruction precedence automatically' "$algorithm"
    grep -q 'length-framed phase, exact goal snapshot, and current artifact-source bytes' "$algorithm"
    ! grep -q 'canonical compact JSON' "$algorithm"
    ! grep -q 'Ask context-driven questions one at a time' "$skill"
}

@test "intent classification cannot prescribe interview depth" {
    local intent="$(plugin_root)/references/intent-classification.md"
    grep -q 'whole currently unblocked critical frontier' "$intent"
    ! grep -q 'Min questions' "$intent"
    ! grep -q 'Question Count Rules' "$intent"
}

@test "skill discovery is cumulative and phaseSkillLoad is the only load proof" {
    local gates
    gates="$(plugin_root)/references/normal-mode-gates.md"
    grep -q 'append-only discovery history' "$gates"
    grep -q 'shadowedSources' "$gates"
    grep -q 'Do not add or consult `invoked` as load proof' "$gates"
    grep -q 'current `phaseSkillLoad` proves loaded contracts' "$gates"
    grep -q 'only the final `research.md` `## Executive Summary` section' "$gates"
    grep -q 'core: false' "$gates"
    grep -q 'failures' "$gates"
    grep -q 'exactly one `core: true` selection' "$gates"
    grep -q 'Submit `artifactAgentLoads` as an empty array' "$gates"
}

@test "quick mode has no alias or settings default" {
    local smart settings
    smart="$(plugin_root)/skills/smart-ralph/SKILL.md"
    settings="$(plugin_root)/templates/settings-template.md"
    ! grep -Eq '\| `--quick` \| `-q`' "$smart"
    grep -q '`--interactive`' "$smart"
    ! grep -q 'quick_mode_default' "$settings"
}

@test "artifact prompts reload only successful sources with unique dispatch receipts" {
    local agent
    for agent in research-analyst product-manager architect-reviewer task-planner triage-analyst; do
        grep -q 'artifactAgentId' "$(plugin_root)/agents/$agent.md"
        grep -q 'whose parent manifest receipt is `loaded`' "$(plugin_root)/agents/$agent.md"
        grep -q 'do not retry sources whose parent receipt failed' "$(plugin_root)/agents/$agent.md"
        grep -q 'check-agent-write' "$(plugin_root)/agents/$agent.md"
        grep -q 'discovery revision' "$(plugin_root)/agents/$agent.md"
    done
}

@test "Task guard is registered and permits read-only Explore" {
    local hook input
    hook="$(plugin_root)/hooks/scripts/phase-task-guard.sh"
    [ -x "$hook" ]
    jq -e '.hooks.PreToolUse[] | select(.matcher == "Task") | .hooks[] | select(.command | contains("phase-task-guard.sh"))' \
        "$(plugin_root)/hooks/hooks.json"

    input='{"tool_input":{"subagent_type":"Explore","prompt":"Read only"}}'
    run bash -c 'printf "%s" "$1" | "$2"' _ "$input" "$hook"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "Task guard blocks artifact delegation without provenance" {
    local cwd hook input
    cwd="$TEST_DIR/project"
    hook="$(plugin_root)/hooks/scripts/phase-task-guard.sh"
    mkdir -p "$cwd"
    input="$(jq -n --arg cwd "$cwd" '{cwd:$cwd,tool_input:{subagent_type:"product-manager",prompt:"Write requirements.md"}}')"
    run bash -c 'printf "%s" "$1" | "$2"' _ "$input" "$hook"
    [ "$status" -eq 0 ]
    [[ "$output" == *'"permissionDecision": "deny"'* ]]
    [[ "$output" == *'missing the [RALPH_PHASE_GATE] marker'* ]]
}

@test "Task guard requires cwd for artifact delegation" {
    local hook input
    hook="$(plugin_root)/hooks/scripts/phase-task-guard.sh"
    input='{"tool_input":{"subagent_type":"product-manager","prompt":"[RALPH_PHASE_GATE]"}}'
    run bash -c 'printf "%s" "$1" | "$2"' _ "$input" "$hook"
    [ "$status" -eq 0 ]
    [[ "$output" == *'hook input cwd is required'* ]]
}

@test "Task guard allows the active spec in a configured spec root" {
    local cwd state digest goal hook prompt input
    cwd="$TEST_DIR/project"
    state="$cwd/packages/api/specs/demo/.ralph-state.json"
    goal='Configured spec gate fixture'
    digest="$(context_digest requirements "$goal")"
    hook="$(plugin_root)/hooks/scripts/phase-task-guard.sh"
    mkdir -p "$cwd/.claude" "$(dirname "$state")"
    printf '%s\n' \
        '---' \
        'specs_dirs: ["./packages/api/specs"]' \
        '---' > "$cwd/.claude/ralph-specum.local.md"
    printf '%s\n' 'demo' > "$cwd/packages/api/specs/.current-spec"
    prepare_approved_state "$state" requirements requirements-1 "$digest" "$goal"
    prompt="$(gate_prompt "$state" requirements requirements-1 "$digest")"
    input="$(jq -n --arg cwd "$cwd" --arg prompt "$prompt" '{cwd:$cwd,tool_input:{subagent_type:"product-manager",prompt:$prompt}}')"
    run bash -c 'printf "%s" "$1" | "$2"' _ "$input" "$hook"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "Task guard denies an approved state from another checkout" {
    local cwd active_state foreign_state digest goal hook prompt input
    cwd="$TEST_DIR/project"
    active_state="$cwd/specs/demo/.ralph-state.json"
    foreign_state="$TEST_DIR/foreign/specs/demo/.ralph-state.json"
    goal='Foreign state gate fixture'
    digest="$(context_digest requirements "$goal")"
    hook="$(plugin_root)/hooks/scripts/phase-task-guard.sh"
    mkdir -p "$(dirname "$active_state")"
    printf '%s\n' 'demo' > "$cwd/specs/.current-spec"
    printf '%s\n' '{}' > "$active_state"
    prepare_approved_state "$foreign_state" requirements requirements-foreign "$digest" "$goal"
    prompt="$(gate_prompt "$foreign_state" requirements requirements-foreign "$digest")"
    input="$(jq -n --arg cwd "$cwd" --arg prompt "$prompt" '{cwd:$cwd,tool_input:{subagent_type:"product-manager",prompt:$prompt}}')"
    run bash -c 'printf "%s" "$1" | "$2"' _ "$input" "$hook"
    [ "$status" -eq 0 ]
    [[ "$output" == *'does not match the active state for phase requirements in hook cwd'* ]]
}

@test "Task guard never crosses spec and epic state types when both are active" {
    local cwd spec_state epic_state spec_digest epic_digest goal hook prompt input
    cwd="$TEST_DIR/project"
    spec_state="$cwd/specs/demo/.ralph-state.json"
    epic_state="$cwd/specs/_epics/platform/.epic-state.json"
    goal='State type isolation fixture'
    spec_digest="$(context_digest requirements "$goal")"
    epic_digest="$(context_digest triage "$goal")"
    hook="$(plugin_root)/hooks/scripts/phase-task-guard.sh"
    mkdir -p "$(dirname "$spec_state")" "$(dirname "$epic_state")"
    printf '%s\n' 'demo' > "$cwd/specs/.current-spec"
    printf '%s\n' 'platform' > "$cwd/specs/.current-epic"
    prepare_approved_state "$spec_state" requirements requirements-1 "$spec_digest" "$goal"
    prepare_approved_state "$epic_state" triage triage-1 "$epic_digest" "$goal"

    prompt="$(gate_prompt "$epic_state" requirements requirements-1 "$spec_digest")"
    input="$(jq -n --arg cwd "$cwd" --arg prompt "$prompt" '{cwd:$cwd,tool_input:{subagent_type:"product-manager",prompt:$prompt}}')"
    run bash -c 'printf "%s" "$1" | "$2"' _ "$input" "$hook"
    [ "$status" -eq 0 ]
    [[ "$output" == *'does not match the active state for phase requirements'* ]]

    prompt="$(gate_prompt "$spec_state" triage triage-1 "$epic_digest")"
    input="$(jq -n --arg cwd "$cwd" --arg prompt "$prompt" '{cwd:$cwd,tool_input:{subagent_type:"triage-analyst",prompt:$prompt}}')"
    run bash -c 'printf "%s" "$1" | "$2"' _ "$input" "$hook"
    [ "$status" -eq 0 ]
    [[ "$output" == *'does not match the active state for phase triage'* ]]
}

@test "Task guard allows the active epic state" {
    local cwd state digest goal hook prompt input
    cwd="$TEST_DIR/project"
    state="$cwd/specs/_epics/platform/.epic-state.json"
    goal='Active epic gate fixture'
    digest="$(context_digest triage "$goal")"
    hook="$(plugin_root)/hooks/scripts/phase-task-guard.sh"
    mkdir -p "$cwd/specs"
    printf '%s\n' 'platform' > "$cwd/specs/.current-epic"
    prepare_approved_state "$state" triage triage-1 "$digest" "$goal"
    prompt="$(gate_prompt "$state" triage triage-1 "$digest")"
    input="$(jq -n --arg cwd "$cwd" --arg prompt "$prompt" '{cwd:$cwd,tool_input:{subagent_type:"triage-analyst",prompt:$prompt}}')"
    run bash -c 'printf "%s" "$1" | "$2"' _ "$input" "$hook"
    [ "$status" -eq 0 ]
    [ -z "$output" ]

    input="$(jq -n --arg cwd "$cwd" --arg prompt "$prompt" '{cwd:$cwd,tool_input:{subagent_type:"research-analyst",prompt:$prompt}}')"
    run bash -c 'printf "%s" "$1" | "$2"' _ "$input" "$hook"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "Task guard denies an artifact subagent that does not match the phase" {
    local cwd state digest goal hook prompt input
    cwd="$TEST_DIR/project"
    state="$cwd/specs/demo/.ralph-state.json"
    goal='Phase mismatch gate fixture'
    digest="$(context_digest requirements "$goal")"
    hook="$(plugin_root)/hooks/scripts/phase-task-guard.sh"
    mkdir -p "$(dirname "$state")"
    printf '%s\n' 'demo' > "$cwd/specs/.current-spec"
    prepare_approved_state "$state" requirements requirements-1 "$digest" "$goal"
    prompt="$(gate_prompt "$state" requirements requirements-1 "$digest")"
    input="$(jq -n --arg cwd "$cwd" --arg prompt "$prompt" '{cwd:$cwd,tool_input:{subagent_type:"task-planner",prompt:$prompt}}')"
    run bash -c 'printf "%s" "$1" | "$2"' _ "$input" "$hook"
    [ "$status" -eq 0 ]
    [[ "$output" == *'subagent type is not authorized for phase requirements'* ]]
}

@test "quick hooks require exact authorization source" {
    local cwd spec state input guard
    cwd="$TEST_DIR/project"
    spec="$cwd/specs/demo"
    state="$spec/.ralph-state.json"
    guard="$(plugin_root)/hooks/scripts/quick-mode-guard.sh"
    mkdir -p "$spec"
    printf '%s\n' 'demo' > "$cwd/specs/.current-spec"
    input="$(jq -n --arg cwd "$cwd" '{cwd:$cwd,tool_input:{questions:[]}}')"

    printf '%s\n' '{"quickMode":true}' > "$state"
    run bash -c 'printf "%s" "$1" | "$2"' _ "$input" "$guard"
    [ "$status" -eq 0 ]
    [ -z "$output" ]

    printf '%s\n' '{"quickMode":true,"quickAuthorization":{"source":"--quick"}}' > "$state"
    run bash -c 'printf "%s" "$1" | "$2"' _ "$input" "$guard"
    [ "$status" -eq 0 ]
    [[ "$output" == *'"permissionDecision": "deny"'* ]]

    grep -q 'QUICK_SOURCE' "$(plugin_root)/hooks/scripts/stop-watcher.sh"
    grep -q '\[ "$QUICK_SOURCE" != "--quick" \]' "$(plugin_root)/hooks/scripts/stop-watcher.sh"
}

@test "quick guard ignores legacy epic quick state and blocks exact epic quick state" {
    local cwd epic state input guard
    cwd="$TEST_DIR/project"
    epic="$cwd/specs/_epics/platform"
    state="$epic/.epic-state.json"
    guard="$(plugin_root)/hooks/scripts/quick-mode-guard.sh"
    mkdir -p "$epic"
    printf '%s\n' 'platform' > "$cwd/specs/.current-epic"
    input="$(jq -n --arg cwd "$cwd" '{cwd:$cwd,tool_input:{questions:[]}}')"

    printf '%s\n' '{"quickMode":true}' > "$state"
    run bash -c 'printf "%s" "$1" | "$2"' _ "$input" "$guard"
    [ "$status" -eq 0 ]
    [ -z "$output" ]

    printf '%s\n' '{"quickMode":true,"quickAuthorization":{"source":"--quick"}}' > "$state"
    run bash -c 'printf "%s" "$1" | "$2"' _ "$input" "$guard"
    [ "$status" -eq 0 ]
    [[ "$output" == *'"permissionDecision": "deny"'* ]]
}

@test "tasks granularity stays outside the interview gate" {
    local tasks
    tasks="$(plugin_root)/commands/tasks.md"
    grep -q 'Treat granularity as workflow administration' "$tasks"
    grep -q 'Never add it to the interview frontier' "$tasks"
    ! sed -n '/Use these as critical decision candidates/,/Inspect test tooling/p' "$tasks" | grep -q 'Task granularity'
}

@test "tasks walkthrough reports all five delivery phases" {
    local tasks
    tasks="$(plugin_root)/commands/tasks.md"
    grep -q 'tasks across 5 phases' "$tasks"
    grep -q 'Phase 5 (PR Lifecycle)' "$tasks"
}

@test "research writers leave approval state to the coordinator" {
    local agent
    agent="$(plugin_root)/agents/research-analyst.md"
    grep -q 'Leave approval-state mutation to the coordinator' "$agent"
    ! grep -q '/tmp/state.json' "$agent"
    ! grep -q "jq '.awaitingApproval = true'" "$agent"
}

@test "triage uses epic gate state and delegates plan artifacts" {
    local triage flow
    triage="$(plugin_root)/commands/triage.md"
    flow="$(plugin_root)/references/triage-flow.md"
    grep -q '.epic-state.json' "$triage"
    grep -q 'phase `triage`' "$triage"
    grep -q 'delegate `plan.md` creation' "$flow"
    grep -q 'unique artifact agent ID' "$flow"
}

@test "quick triage persists its epic and uses a deterministic output without prompting" {
    local triage flow
    triage="$(plugin_root)/commands/triage.md"
    flow="$(plugin_root)/references/triage-flow.md"
    grep -q 'write `$EPIC_NAME` to `./specs/.current-epic`' "$triage"
    grep -q 'either a new or resumed epic state' "$triage"
    grep -q 'replacing any stale pointer' "$triage"
    ! grep -q 'A resumed epic keeps its existing pointer' "$triage"
    grep -q 'Do not call `AskUserQuestion` in any exact-quick branch' "$triage"
    grep -q 'setup answers.*do not satisfy or replace this interview' "$triage"
    grep -q 'select \*\*Spec files\*\* as the deterministic default' "$flow"
    grep -q 'Do not ask an output question' "$flow"
    grep -q 'In interactive mode after explicit artifact approval, ask' "$flow"
    grep -q 'In both interactive and exact quick mode, reload every selected skill' "$triage"
    grep -q 'Call `begin-interview` only after the manifest is accepted' "$triage"
}

@test "configured-root research never falls back to the default specs directory" {
    local parallel
    parallel="$(plugin_root)/references/parallel-research.md"
    grep -q '\$SPEC_PATH/research.md' "$parallel"
    grep -q '\$SPEC_PATH/.research-' "$parallel"
    ! grep -q '\./specs/\$spec' "$parallel"
}

@test "requirements review uses normalized persistent mode" {
    local requirements
    requirements="$(plugin_root)/commands/requirements.md"
    grep -q 'Behavior branches on normalized persistent `quickMode` from state' "$requirements"
    ! sed -n '/## Step 4: Artifact Review/,/## Step 5: Walkthrough/p' "$requirements" | grep -q 'check `--quick` in `\$ARGUMENTS`'
}
