#!/usr/bin/env bats

set -e

repo_root() {
    echo "$BATS_TEST_DIRNAME/.."
}

claude_helper() {
    echo "$(repo_root)/plugins/ralph-specum/scripts/phase_gate.py"
}

codex_helper() {
    echo "$(repo_root)/plugins/ralph-specum-codex/scripts/phase_gate.py"
}

context_digest() {
    python3 - "$@" <<'PY'
import hashlib
import sys
from pathlib import Path

phase, goal, *sources = sys.argv[1:]

def frame(value):
    return str(len(value)).encode("ascii") + b":" + value

parts = [frame(b"ralph-phase-context-v1"), frame(phase.encode()), frame(goal.encode())]
for source in sorted(sources):
    parts.extend([frame(source.encode()), frame(Path(source).read_bytes())])
print(hashlib.sha256(b"".join(parts)).hexdigest())
PY
}

setup() {
    TEST_DIR="$(mktemp -d)"
    STATE_FILE="$TEST_DIR/state.json"
    SKILL_FILE="$TEST_DIR/SKILL.md"
    RESOURCE_FILE="$TEST_DIR/reference.md"
    DOMAIN_FILE="$TEST_DIR/domain-skill.md"
    RESEARCH_FILE="$TEST_DIR/research.md"
    REQUIREMENTS_FILE="$TEST_DIR/requirements.md"
    DESIGN_FILE="$TEST_DIR/design.md"
    GOAL="Demo goal"
    printf '%s\n' '# skill' > "$SKILL_FILE"
    printf '%s\n' '# reference' > "$RESOURCE_FILE"
    printf '%s\n' '# domain skill' > "$DOMAIN_FILE"
    printf '%s\n' '# Research' 'current research' > "$RESEARCH_FILE"
    printf '%s\n' '# Requirements' 'current requirements' > "$REQUIREMENTS_FILE"
    printf '%s\n' '# Design' 'current design' > "$DESIGN_FILE"
    SKILL_HASH="$(shasum -a 256 "$SKILL_FILE" | awk '{print $1}')"
    RESOURCE_HASH="$(shasum -a 256 "$RESOURCE_FILE" | awk '{print $1}')"
    DOMAIN_HASH="$(shasum -a 256 "$DOMAIN_FILE" | awk '{print $1}')"
    DIGEST="$(context_digest requirements "$GOAL" "$RESEARCH_FILE")"
    export TEST_DIR STATE_FILE SKILL_FILE RESOURCE_FILE DOMAIN_FILE RESEARCH_FILE REQUIREMENTS_FILE DESIGN_FILE DIGEST GOAL SKILL_HASH RESOURCE_HASH DOMAIN_HASH
    jq -n --arg base_path "$TEST_DIR" \
        '{source:"spec",name:"demo",goal:"Demo goal",basePath:$base_path,phase:"requirements",unknown:{keep:true}}' \
        > "$STATE_FILE"
}

teardown() {
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

write_skill_load() {
    local status resource_status warnings resource_errors failures plugin_root plugin_name
    local core_name core_source core_algorithm core_domain core_hash core_algorithm_hash core_domain_hash resource_sha
    local manifest_phase manifest_interview_id discovery_pass context_json source source_hash
    local context_sources=()
    status="${1:-complete}"
    resource_status="${2:-loaded}"
    warnings="${3:-[]}"
    resource_errors="${4:-[]}"
    failures="${5:-[]}"
    plugin_root="${PHASE_GATE_TEST_PLUGIN_ROOT:-$(dirname "$(dirname "$helper")")}"
    plugin_name="${PHASE_GATE_TEST_PLUGIN_NAME:-$(basename "$plugin_root")}"
    if [ "$plugin_name" = "ralph-specum-codex" ]; then
        core_name="interview-framework-codex"
    else
        core_name="interview-framework"
    fi
    core_source="$plugin_root/skills/$core_name/SKILL.md"
    core_algorithm="$plugin_root/skills/$core_name/references/algorithm.md"
    core_domain="$plugin_root/skills/$core_name/references/domain-modeling.md"
    core_hash="$(shasum -a 256 "$core_source" | awk '{print $1}')"
    core_algorithm_hash="$(shasum -a 256 "$core_algorithm" | awk '{print $1}')"
    core_domain_hash="$(shasum -a 256 "$core_domain" | awk '{print $1}')"
    if [ "$resource_status" = "failed" ]; then
        resource_sha=null
    else
        resource_sha="\"$core_algorithm_hash\""
    fi
    manifest_phase="${phase:-requirements}"
    manifest_interview_id="${interview_id:-requirements-1}"
    case "$manifest_phase" in
        requirements) [ -f "$RESEARCH_FILE" ] && context_sources+=("$RESEARCH_FILE") ;;
        design)
            [ -f "$RESEARCH_FILE" ] && context_sources+=("$RESEARCH_FILE")
            [ -f "$REQUIREMENTS_FILE" ] && context_sources+=("$REQUIREMENTS_FILE")
            ;;
        tasks)
            [ -f "$RESEARCH_FILE" ] && context_sources+=("$RESEARCH_FILE")
            [ -f "$REQUIREMENTS_FILE" ] && context_sources+=("$REQUIREMENTS_FILE")
            [ -f "$DESIGN_FILE" ] && context_sources+=("$DESIGN_FILE")
            ;;
    esac
    if [[ "$manifest_phase" =~ ^(requirements|design|tasks)$ ]] && [ -f "$RESEARCH_FILE" ]; then
        discovery_pass="pass2"
    else
        discovery_pass="pass1"
    fi
    DIGEST="$(context_digest "$manifest_phase" "$GOAL" "${context_sources[@]}")"
    export DIGEST
    context_json='[]'
    for source in "${context_sources[@]}"; do
        source_hash="$(shasum -a 256 "$source" | awk '{print $1}')"
        context_json="$(jq --arg source "$source" --arg sha256 "$source_hash" \
            '. + [{source:$source,sha256:$sha256}]' <<< "$context_json")"
    done
    jq --arg pass "$discovery_pass" --arg name "$core_name" --arg source "$core_source" \
        '.discoveredSkills = [{pass:$pass,revision:"rev-7",name:$name,activeSource:$source,reason:"Required phase interview framework",shadowedSources:[],outcome:"selected"}]' \
        "$STATE_FILE" > "$TEST_DIR/state-with-discovery.json"
    mv "$TEST_DIR/state-with-discovery.json" "$STATE_FILE"
    printf '%s\n' "{
  \"phase\": \"$manifest_phase\",
  \"interviewId\": \"$manifest_interview_id\",
  \"discoveryRevision\": \"rev-7\",
  \"contextDigest\": \"$DIGEST\",
  \"context\": {\"goal\": \"$GOAL\", \"artifacts\": $context_json},
  \"status\": \"$status\",
  \"selected\": [{
    \"name\": \"$core_name\",
    \"reason\": \"Required phase interview framework\",
    \"source\": \"$core_source\",
    \"core\": true,
    \"body\": {\"sha256\": \"$core_hash\", \"loadStatus\": \"loaded\", \"errors\": []},
    \"requiredResourceSources\": [\"$core_algorithm\", \"$core_domain\"],
    \"requiredResources\": [
      {\"source\": \"$core_algorithm\", \"sha256\": $resource_sha, \"loadStatus\": \"$resource_status\", \"errors\": $resource_errors},
      {\"source\": \"$core_domain\", \"sha256\": \"$core_domain_hash\", \"loadStatus\": \"loaded\", \"errors\": []}
    ]
  }],
  \"warnings\": $warnings,
  \"conflicts\": [],
  \"failures\": $failures,
  \"noDomainMatches\": true,
  \"artifactAgentLoads\": []
}" > "$TEST_DIR/skill-load.json"
}

add_discovery_selection() {
    local name=$1
    local source=$2
    jq --arg name "$name" --arg source "$source" \
        '.discoveredSkills[0] as $base | .discoveredSkills += [{pass:$base.pass,revision:$base.revision,name:$name,activeSource:$source,reason:"Relevant domain guidance",shadowedSources:[],outcome:"selected"}]' \
        "$STATE_FILE" > "$TEST_DIR/state-with-domain-discovery.json"
    mv "$TEST_DIR/state-with-domain-discovery.json" "$STATE_FILE"
}

write_interview() {
    local status selected confirmation bypass pending answered
    status="${1:-complete}"
    selected="${2:-\"Use the existing state file\"}"
    confirmation="${3:-\"approve-and-delegate\"}"
    bypass="${4:-null}"
    pending="${5:-[]}"
    answered="${6:-[\"storage\"]}"
    printf '%s\n' "{
  \"phase\": \"requirements\",
  \"interviewId\": \"requirements-1\",
  \"round\": 1,
  \"status\": \"$status\",
  \"askedDecisionIds\": [\"storage\"],
  \"pendingDecisionIds\": $pending,
  \"answeredDecisionIds\": $answered,
  \"selectedApproach\": $selected,
  \"confirmationSource\": $confirmation,
  \"bypassReason\": $bypass,
  \"assumptionsRecorded\": []
}" > "$TEST_DIR/interview.json"
}

record_complete_gate() {
    local helper
    helper="$1"
    write_skill_load
    python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    python3 "$helper" begin-interview "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 --round 1 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    python3 "$helper" open-frontier "$STATE_FILE" --round 1 --decision-id storage
    python3 "$helper" record-answer "$STATE_FILE" \
        --decision-id storage --answer "Use the existing state file"
    python3 "$helper" await-confirmation "$STATE_FILE" \
        --decision-id final-approach --approach "Use the existing state file"
    python3 "$helper" confirm "$STATE_FILE" \
        --decision-id final-approach --source "approve-and-delegate"
}

write_approval_fixture() {
    local fixture="$1"
    local awaiting=false
    local gate=null
    local interview=null
    local pending_interview='{"phase":"requirements","interviewId":"requirements-1","round":1,"status":"awaiting_confirmation","askedDecisionIds":["final-approval"],"pendingDecisionIds":["final-approval"],"answeredDecisionIds":[],"selectedApproach":"Use the existing path","confirmationSource":null,"bypassReason":null,"assumptionsRecorded":[]}'

    case "$fixture" in
        pre-delegation)
            interview="$pending_interview"
            ;;
        artifact)
            awaiting=true
            gate='{"id":"artifact-review","phase":"requirements","kind":"artifact","action":"continue-to-design"}'
            ;;
        revision)
            awaiting=true
            gate='{"id":"revision-review","phase":"requirements","kind":"revision","action":"apply-revision","feedback":"Clarify the migration boundary"}'
            ;;
        missing-descriptor)
            awaiting=true
            ;;
        stale-descriptor)
            awaiting=true
            gate='{"id":"stale-artifact-review","phase":"design","kind":"artifact","action":"continue-to-design"}'
            ;;
        missing-feedback)
            awaiting=true
            gate='{"id":"revision-review","phase":"requirements","kind":"revision","action":"apply-revision"}'
            ;;
        malformed-feedback)
            awaiting=true
            gate='{"id":"revision-review","phase":"requirements","kind":"revision","action":"apply-revision","feedback":42}'
            ;;
        competing)
            awaiting=true
            interview="$pending_interview"
            gate='{"id":"artifact-review","phase":"requirements","kind":"artifact","action":"continue-to-design"}'
            ;;
        *)
            return 1
            ;;
    esac

    jq -n --arg base_path "$TEST_DIR" --argjson awaiting "$awaiting" \
        --argjson gate "$gate" --argjson interview "$interview" '
        {source:"spec",name:"demo",goal:"Demo goal",basePath:$base_path,phase:"requirements"}
        + (if $awaiting then {awaitingApproval:true} else {} end)
        + (if $gate == null then {} else {approvalGate:$gate} end)
        + (if $interview == null then {} else {phaseInterview:$interview} end)
    ' > "$STATE_FILE"
}

assert_contextual_approval_accepted() {
    local helper="$1"
    local reply="$2"
    local action="$3"
    local gate_id="$4"

    run env PYTHONDONTWRITEBYTECODE=1 python3 "$helper" resolve-approval "$STATE_FILE" --text "$reply"
    [ "$status" -eq 0 ]
    run jq -e --arg action "$action" --arg gate_id "$gate_id" \
        '.decision == "accepted" and .action == $action and .gateId == $gate_id' <<<"$output"
    [ "$status" -eq 0 ]
    run jq -e --arg reply "$reply" --arg action "$action" --arg gate_id "$gate_id" \
        '.approvalAudit[-1] == {originalReply:$reply,normalizedAction:$action,gateId:$gate_id}' "$STATE_FILE"
    [ "$status" -eq 0 ]
}

assert_contextual_approval_rejected_unchanged() {
    local helper="$1"
    local reply="$2"

    cp "$STATE_FILE" "$TEST_DIR/approval-before.json"
    run env PYTHONDONTWRITEBYTECODE=1 python3 "$helper" resolve-approval "$STATE_FILE" --text "$reply"
    [ "$status" -eq 0 ]
    run jq -e '.decision == "clarification"' <<<"$output"
    [ "$status" -eq 0 ]
    run cmp "$TEST_DIR/approval-before.json" "$STATE_FILE"
    [ "$status" -eq 0 ]
}

@test "phase gate helpers are byte-identical and expose the documented commands" {
    run cmp "$(claude_helper)" "$(codex_helper)"
    [ "$status" -eq 0 ]

    run python3 "$(claude_helper)" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"record-skill-load"* ]]
    [[ "$output" == *"begin-interview"* ]]
    [[ "$output" == *"record-answer"* ]]
    [[ "$output" == *"open-frontier"* ]]
    [[ "$output" == *"await-confirmation"* ]]
    [[ "$output" == *"check-agent-write"* ]]
    [[ "$output" == *"check-delegation"* ]]
    [[ "$output" == *"is-substantive"* ]]
    [[ "$output" == *"resolve-approval"* ]]
}

@test "versioned Codex cache roots require exactly one packaged core" {
    local source_root state_template cache_root zero_root both_root
    local one_state zero_state both_state one_input zero_input both_input
    source_root="$(repo_root)/plugins/ralph-specum-codex"
    state_template="$STATE_FILE"
    cache_root="$TEST_DIR/cache/smart-ralph/ralph-specum-codex/4.11.0"
    zero_root="$TEST_DIR/zero-cache/smart-ralph/ralph-specum-codex/4.11.0"
    both_root="$TEST_DIR/both-cache/smart-ralph/ralph-specum-codex/4.11.0"

    mkdir -p "$cache_root/scripts" "$cache_root/skills/interview-framework-codex/references"
    cp "$source_root/scripts/phase_gate.py" "$cache_root/scripts/phase_gate.py"
    cp "$source_root/skills/interview-framework-codex/SKILL.md" \
        "$cache_root/skills/interview-framework-codex/SKILL.md"
    cp "$source_root/skills/interview-framework-codex/references/algorithm.md" \
        "$cache_root/skills/interview-framework-codex/references/algorithm.md"
    cp "$source_root/skills/interview-framework-codex/references/domain-modeling.md" \
        "$cache_root/skills/interview-framework-codex/references/domain-modeling.md"

    one_state="$TEST_DIR/one-cache-state.json"
    one_input="$TEST_DIR/one-cache-skill-load.json"
    cp "$state_template" "$one_state"
    STATE_FILE="$one_state"
    helper="$cache_root/scripts/phase_gate.py"
    PHASE_GATE_TEST_PLUGIN_ROOT="$cache_root" \
        PHASE_GATE_TEST_PLUGIN_NAME="ralph-specum-codex" write_skill_load
    mv "$TEST_DIR/skill-load.json" "$one_input"

    mkdir -p "$zero_root/scripts"
    cp "$cache_root/scripts/phase_gate.py" "$zero_root/scripts/phase_gate.py"
    zero_state="$TEST_DIR/zero-cache-state.json"
    zero_input="$TEST_DIR/zero-cache-skill-load.json"
    cp "$state_template" "$zero_state"
    STATE_FILE="$zero_state"
    helper="$zero_root/scripts/phase_gate.py"
    PHASE_GATE_TEST_PLUGIN_ROOT="$cache_root" \
        PHASE_GATE_TEST_PLUGIN_NAME="ralph-specum-codex" write_skill_load
    mv "$TEST_DIR/skill-load.json" "$zero_input"

    mkdir -p "$both_root"
    cp -R "$cache_root/." "$both_root"
    mkdir -p "$both_root/skills/interview-framework"
    cp "$source_root/skills/interview-framework-codex/SKILL.md" \
        "$both_root/skills/interview-framework/SKILL.md"
    both_state="$TEST_DIR/both-cache-state.json"
    both_input="$TEST_DIR/both-cache-skill-load.json"
    cp "$state_template" "$both_state"
    STATE_FILE="$both_state"
    helper="$both_root/scripts/phase_gate.py"
    PHASE_GATE_TEST_PLUGIN_ROOT="$both_root" \
        PHASE_GATE_TEST_PLUGIN_NAME="ralph-specum-codex" write_skill_load
    mv "$TEST_DIR/skill-load.json" "$both_input"

    run python3 "$zero_root/scripts/phase_gate.py" record-skill-load "$zero_state" --input "$zero_input"
    [ "$status" -eq 2 ]
    [[ "$output" == *"UNRECOGNIZED_PLUGIN_ROOT"* ]]

    run python3 "$both_root/scripts/phase_gate.py" record-skill-load "$both_state" --input "$both_input"
    [ "$status" -eq 2 ]
    [[ "$output" == *"UNRECOGNIZED_PLUGIN_ROOT"* ]]

    run python3 "$cache_root/scripts/phase_gate.py" record-skill-load "$one_state" --input "$one_input"
    [ "$status" -eq 0 ]
}

@test "schemas expose matching required phase gate state" {
    run cmp "$(repo_root)/plugins/ralph-specum/schemas/spec.schema.json" "$(repo_root)/plugins/ralph-specum-codex/schemas/spec.schema.json"
    [ "$status" -eq 0 ]

    run env REPO_ROOT="$(repo_root)" python3 - <<'PY'
import json
import os
from pathlib import Path

root = Path(os.environ["REPO_ROOT"])
paths = [
    root / "plugins/ralph-specum/schemas/spec.schema.json",
    root / "plugins/ralph-specum-codex/schemas/spec.schema.json",
]
schemas = [json.loads(path.read_text(encoding="utf-8")) for path in paths]
assert schemas[0] == schemas[1]
definitions = schemas[0]["definitions"]
properties = definitions["state"]["properties"]
assert properties["phaseSkillLoad"] == {"$ref": "#/definitions/phaseSkillLoad"}
assert properties["phaseInterview"] == {"$ref": "#/definitions/phaseInterview"}
assert properties["quickAuthorization"] == {"$ref": "#/definitions/quickAuthorization"}
assert properties["quickMode"] == {"type": "boolean"}
assert properties["approvalGate"] == {"$ref": "#/definitions/approvalGate"}
assert properties["approvalAudit"] == {"$ref": "#/definitions/approvalAudit"}
assert properties["discoveredSkills"] == {"type": "array", "items": {"$ref": "#/definitions/discoveredSkill"}}
epic_properties = definitions["epicState"]["properties"]
assert epic_properties["phaseSkillLoad"] == {"$ref": "#/definitions/phaseSkillLoad"}
assert epic_properties["phaseInterview"] == {"$ref": "#/definitions/phaseInterview"}
assert epic_properties["quickAuthorization"] == {"$ref": "#/definitions/quickAuthorization"}
assert epic_properties["quickMode"] == {"type": "boolean"}
assert epic_properties["approvalGate"] == {"$ref": "#/definitions/approvalGate"}
assert epic_properties["approvalAudit"] == {"$ref": "#/definitions/approvalAudit"}
assert definitions["quickAuthorization"]["properties"]["source"]["const"] == "--quick"
approval_gate = definitions["approvalGate"]
assert approval_gate["required"] == ["id", "phase", "kind", "action"]
assert approval_gate["properties"]["kind"]["enum"] == ["artifact", "revision"]
assert approval_gate["allOf"][0]["then"]["required"] == ["feedback"]
approval_audit = definitions["approvalAudit"]
assert approval_audit["items"]["required"] == ["originalReply", "normalizedAction", "gateId"]
assert definitions["phaseSkillLoad"]["required"] == [
    "phase", "interviewId", "discoveryRevision", "contextDigest", "context", "status",
    "selected", "warnings", "conflicts", "failures", "noDomainMatches", "artifactAgentLoads",
]
selected = definitions["phaseSkillLoad"]["properties"]["selected"]["items"]
assert "requiredResourceSources" in selected["required"]
assert selected["properties"]["requiredResourceSources"]["uniqueItems"] is True
load_receipt = definitions["loadReceipt"]
assert load_receipt["properties"]["source"]["pattern"] == "^/"
loaded, failed = load_receipt["allOf"]
assert loaded["then"]["properties"]["errors"]["maxItems"] == 0
assert failed["then"]["properties"]["sha256"]["const"] is None
assert failed["then"]["properties"]["errors"]["minItems"] == 1
context = definitions["phaseSkillLoad"]["properties"]["context"]
assert context["required"] == ["goal", "artifacts"]
assert context["properties"]["artifacts"]["items"]["properties"]["source"]["pattern"] == "^/"
assert definitions["state"]["properties"]["goal"]["pattern"] == "\\S"
assert definitions["phaseInterview"]["required"] == [
    "phase", "interviewId", "round", "status", "askedDecisionIds",
    "pendingDecisionIds", "answeredDecisionIds", "selectedApproach",
    "confirmationSource", "bypassReason", "assumptionsRecorded",
]
PY
    [ "$status" -eq 0 ]
}

@test "skill load requires the applicable discovery pass and exact selected set" {
    local helper
    helper="$(claude_helper)"
    write_skill_load

    jq 'del(.discoveredSkills)' "$STATE_FILE" > "$TEST_DIR/no-discovery.json"
    mv "$TEST_DIR/no-discovery.json" "$STATE_FILE"
    run python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    [ "$status" -eq 2 ]
    [[ "$output" == *"DISCOVERY_HISTORY_MISSING"* ]]

    write_skill_load
    jq '.discoveredSkills[0].pass = "pass1"' "$STATE_FILE" > "$TEST_DIR/wrong-pass.json"
    mv "$TEST_DIR/wrong-pass.json" "$STATE_FILE"
    run python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    [ "$status" -eq 2 ]
    [[ "$output" == *"DISCOVERY_PASS_MISSING"* ]]

    write_skill_load
    add_discovery_selection "domain-skill" "$DOMAIN_FILE"
    run python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    [ "$status" -eq 2 ]
    [[ "$output" == *"DISCOVERY_SELECTION_MISMATCH"* ]]
}

@test "phase context requires every applicable upstream artifact" {
    local helper empty_digest
    helper="$(codex_helper)"
    write_skill_load
    empty_digest="$(context_digest requirements "$GOAL")"
    env EMPTY_DIGEST="$empty_digest" python3 - "$TEST_DIR/skill-load.json" <<'PY'
import json
import os
import sys

path = sys.argv[1]
value = json.load(open(path, encoding="utf-8"))
value["contextDigest"] = os.environ["EMPTY_DIGEST"]
value["context"]["artifacts"] = []
json.dump(value, open(path, "w", encoding="utf-8"))
PY
    run python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    [ "$status" -eq 2 ]
    [[ "$output" == *"CONTEXT_ARTIFACT_MISSING"* ]]

    rm "$REQUIREMENTS_FILE"
    phase=design
    interview_id=design-1
    write_skill_load
    run python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    [ "$status" -eq 2 ]
    [[ "$output" == *"CONTEXT_ARTIFACT_REQUIRED"* ]]
}

@test "direct requirements without research use pass1 and stale when research appears" {
    local helper no_research_digest
    helper="$(claude_helper)"
    rm "$RESEARCH_FILE"
    write_skill_load
    no_research_digest="$DIGEST"
    python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    python3 "$helper" mode "$STATE_FILE" --quick
    python3 "$helper" begin-interview "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 --round 1 \
        --discovery-revision rev-7 --context-digest "$no_research_digest"

    printf '%s\n' '# Research' 'added later' > "$RESEARCH_FILE"
    run python3 "$helper" check-delegation "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 \
        --discovery-revision rev-7 --context-digest "$no_research_digest"
    [ "$status" -eq 3 ]
    [[ "$output" == *"SKILL_LOAD_STALE"* ]]
}

@test "legacy state preserves the persisted skill-load goal across reloads" {
    local helper changed_goal changed_digest
    helper="$(claude_helper)"
    write_skill_load
    python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    jq 'del(.goal)' "$STATE_FILE" > "$TEST_DIR/legacy-state.json"
    mv "$TEST_DIR/legacy-state.json" "$STATE_FILE"

    changed_goal="Changed goal"
    changed_digest="$(context_digest requirements "$changed_goal" "$RESEARCH_FILE")"
    jq --arg goal "$changed_goal" --arg digest "$changed_digest" \
        '.context.goal = $goal | .contextDigest = $digest' \
        "$TEST_DIR/skill-load.json" > "$TEST_DIR/changed-goal-load.json"

    run python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/changed-goal-load.json"
    [ "$status" -eq 2 ]
    [[ "$output" == *"CONTEXT_GOAL_MISMATCH"* ]]
    run jq -e '.phaseSkillLoad.context.goal == "Demo goal"' "$STATE_FILE"
    [ "$status" -eq 0 ]
}

@test "complete interview delegates only with current skill provenance" {
    local helper
    helper="$(claude_helper)"
    record_complete_gate "$helper"

    run python3 "$helper" check-delegation "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    [ "$status" -eq 0 ]
    [[ "$output" == *'"decision": "allow"'* ]]

    run python3 -c 'import json,sys; s=json.load(open(sys.argv[1])); assert s["unknown"] == {"keep": True}' "$STATE_FILE"
    [ "$status" -eq 0 ]
}

@test "delegation rejects missing, stale, and failed skill provenance" {
    local helper
    helper="$(claude_helper)"
    write_interview
    python3 - "$STATE_FILE" "$TEST_DIR/interview.json" <<'PY'
import json
import sys

state_path, interview_path = sys.argv[1:]
with open(state_path, encoding="utf-8") as handle:
    state = json.load(handle)
with open(interview_path, encoding="utf-8") as handle:
    state["phaseInterview"] = json.load(handle)
with open(state_path, "w", encoding="utf-8") as handle:
    json.dump(state, handle)
PY

    run python3 "$helper" check-delegation "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    [ "$status" -eq 3 ]
    [[ "$output" == *"SKILL_LOAD_MISSING"* ]]

    write_skill_load
    python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"

    run python3 "$helper" check-delegation "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 \
        --discovery-revision stale --context-digest "$DIGEST"
    [ "$status" -eq 3 ]
    [[ "$output" == *"SKILL_LOAD_STALE"* ]]

    run python3 "$helper" check-delegation "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 \
        --discovery-revision rev-7 --context-digest "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
    [ "$status" -eq 3 ]
    [[ "$output" == *"SKILL_LOAD_STALE"* ]]

    write_skill_load core_failed failed '[]' '["Core skill could not load"]' '["Core skill could not load"]'
    python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    write_interview
    python3 - "$STATE_FILE" "$TEST_DIR/interview.json" <<'PY'
import json
import sys

state_path, interview_path = sys.argv[1:]
with open(state_path, encoding="utf-8") as handle:
    state = json.load(handle)
with open(interview_path, encoding="utf-8") as handle:
    state["phaseInterview"] = json.load(handle)
with open(state_path, "w", encoding="utf-8") as handle:
    json.dump(state, handle)
PY
    run python3 "$helper" check-delegation "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    [ "$status" -eq 3 ]
    [[ "$output" == *"SKILL_LOAD_FAILED"* ]]
}

@test "partial warned skill load permits delegation after warning is recorded" {
    local helper
    helper="$(codex_helper)"
    write_skill_load partial_warned loaded '["Optional reference could not load"]' '[]' '["Optional reference could not load"]'
    env DOMAIN_FILE="$DOMAIN_FILE" DOMAIN_HASH="$DOMAIN_HASH" RESOURCE_FILE="$RESOURCE_FILE" RESOURCE_HASH="$RESOURCE_HASH" python3 - "$TEST_DIR/skill-load.json" <<'PY'
import json
import os
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as handle:
    value = json.load(handle)
value["selected"].append({
    "name": "domain-skill",
    "reason": "Relevant domain guidance",
    "source": os.environ["DOMAIN_FILE"],
    "core": False,
    "body": {"sha256": os.environ["DOMAIN_HASH"], "loadStatus": "loaded", "errors": []},
    "requiredResourceSources": [os.environ["RESOURCE_FILE"]],
    "requiredResources": [{
        "source": os.environ["RESOURCE_FILE"],
        "sha256": None,
        "loadStatus": "failed",
        "errors": ["Optional reference could not load"],
    }],
})
value["noDomainMatches"] = False
with open(path, "w", encoding="utf-8") as handle:
    json.dump(value, handle)
PY
    add_discovery_selection "domain-skill" "$DOMAIN_FILE"
    python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    python3 "$helper" begin-interview "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 --round 1 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    python3 "$helper" skip "$STATE_FILE" \
        --reason "User skipped remaining decisions" --assumption "Use documented defaults"

    run python3 "$helper" check-delegation "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    [ "$status" -eq 3 ]
    [[ "$output" == *"INTERVIEW_INCOMPLETE"* ]]

    python3 "$helper" confirm "$STATE_FILE" \
        --decision-id skip-confirmation --source "approve-and-delegate"

    run python3 "$helper" check-delegation "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    [ "$status" -eq 0 ]
}

@test "nonterminal interview states reject delegation" {
    local helper
    helper="$(claude_helper)"
    write_skill_load
    python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    python3 "$helper" begin-interview "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 --round 1 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    python3 "$helper" await-confirmation "$STATE_FILE" \
        --decision-id storage --approach "Use the existing state file"

    run python3 "$helper" check-delegation "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    [ "$status" -eq 3 ]
    [[ "$output" == *"INTERVIEW_INCOMPLETE"* ]]
}

@test "legacy quick mode resets and exact quick authorization enables bypass" {
    local helper
    helper="$(codex_helper)"
    python3 -c 'import json,sys; p=sys.argv[1]; s=json.load(open(p)); s["quickMode"]=True; json.dump(s,open(p,"w"))' "$STATE_FILE"

    run python3 "$helper" mode "$STATE_FILE"
    [ "$status" -eq 0 ]
    run python3 -c 'import json,sys; s=json.load(open(sys.argv[1])); assert s["quickMode"] is False; assert "quickAuthorization" not in s' "$STATE_FILE"
    [ "$status" -eq 0 ]

    run python3 "$helper" mode "$STATE_FILE" --quick
    [ "$status" -eq 0 ]
    run python3 "$helper" begin-interview "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 --round 1 \
        --discovery-revision unused --context-digest "$DIGEST"
    [ "$status" -eq 3 ]
    [[ "$output" == *"SKILL_LOAD_MISSING"* ]]

    write_skill_load
    python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    python3 "$helper" begin-interview "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 --round 1 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    run python3 "$helper" check-delegation "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    [ "$status" -eq 0 ]
    [[ "$output" == *'"path": "quick"'* ]]

    run python3 "$helper" mode "$STATE_FILE" --interactive
    [ "$status" -eq 0 ]
    run python3 -c 'import json,sys; s=json.load(open(sys.argv[1])); assert s["quickMode"] is False; assert "quickAuthorization" not in s; assert "phaseInterview" not in s' "$STATE_FILE"
    [ "$status" -eq 0 ]

    python3 "$helper" begin-interview "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 --round 1 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    python3 "$helper" open-frontier "$STATE_FILE" --round 1 --decision-id storage
    run python3 "$helper" mode "$STATE_FILE" --quick
    [ "$status" -eq 0 ]
    [[ "$output" == *'"interviewReset": true'* ]]
    run python3 -c 'import json,sys; assert "phaseInterview" not in json.load(open(sys.argv[1]))' "$STATE_FILE"
    [ "$status" -eq 0 ]
    run python3 "$helper" begin-interview "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 --round 1 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    [ "$status" -eq 0 ]
    [[ "$output" == *'"status": "bypassed_quick"'* ]]
}

@test "quick and interactive flags cannot be combined" {
    run python3 "$(claude_helper)" mode "$STATE_FILE" --quick --interactive
    [ "$status" -eq 2 ]

    local flag
    for flag in --qui --interactiv --quick=true -q; do
        run python3 "$(claude_helper)" mode "$STATE_FILE" "$flag"
        [ "$status" -eq 2 ]
    done
}

@test "mode never creates a partial state file" {
    local helper missing
    for helper in "$(claude_helper)" "$(codex_helper)"; do
        missing="$TEST_DIR/missing-$(basename "$(dirname "$(dirname "$helper")")").json"

        run python3 "$helper" mode "$missing"
        [ "$status" -eq 0 ]
        [[ "$output" == *'"stateExists": false'* ]]
        [ ! -e "$missing" ]

        run python3 "$helper" mode "$missing" --quick
        [ "$status" -eq 2 ]
        [[ "$output" == *"STATE_NOT_FOUND"* ]]
        [ ! -e "$missing" ]
    done
}

@test "pure control phrases are not substantive answers" {
    local helper phrase
    helper="$(claude_helper)"
    for phrase in "" "continue" "go ahead" "proceed" "next" "yes" "looks good" "sounds good" "apply the changes"; do
        run python3 "$helper" is-substantive --text "$phrase"
        [ "$status" -eq 1 ]
        [ "$output" = "control" ]
    done

    run python3 "$helper" is-substantive --text "Use PostgreSQL and keep the existing migration path"
    [ "$status" -eq 0 ]
    [ "$output" = "substantive" ]

    run python3 "$helper" is-substantive --text "Apply the changes with PostgreSQL and no new dependency"
    [ "$status" -eq 0 ]
    [ "$output" = "substantive" ]

    for phrase in "please apply the changes" "go ahead please" "proceed, thanks"; do
        run python3 "$helper" classify-reply --text "$phrase"
        [ "$status" -eq 0 ]
        [ "$output" = "control_only" ]
    done
    for phrase in "apply the changes" "continue" "go ahead" "looks good"; do
        run python3 "$helper" classify-reply --text "$phrase"
        [ "$status" -eq 0 ]
        [ "$output" = "control_only" ]
    done
    run python3 "$helper" classify-reply --text "skip"
    [ "$output" = "bare_skip" ]
    run python3 "$helper" classify-reply --text "skip auth but keep billing"
    [ "$output" = "substantive" ]
    run python3 "$helper" classify-reply --text "continue with PostgreSQL"
    [ "$output" = "substantive" ]
}

@test "contextual approval resolves one live action and records its audit on both helpers" {
    local helper
    for helper in "$(claude_helper)" "$(codex_helper)"; do
        write_approval_fixture pre-delegation
        assert_contextual_approval_accepted "$helper" "yes" "approve-and-delegate" "final-approval"

        write_approval_fixture artifact
        assert_contextual_approval_accepted "$helper" "looks good, continue" "continue-to-design" "artifact-review"

        jq '.approvalGate = {
            id: "artifact-resume",
            phase: "requirements",
            kind: "artifact",
            action: "continue-to-design"
        }' "$STATE_FILE" > "$TEST_DIR/resumed-approval.json"
        mv "$TEST_DIR/resumed-approval.json" "$STATE_FILE"
        assert_contextual_approval_accepted "$helper" "continue to design" "continue-to-design" "artifact-resume"
        run jq -e '.approvalAudit == [
            {originalReply:"looks good, continue",normalizedAction:"continue-to-design",gateId:"artifact-review"},
            {originalReply:"continue to design",normalizedAction:"continue-to-design",gateId:"artifact-resume"}
        ]' "$STATE_FILE"
        [ "$status" -eq 0 ]

        write_approval_fixture revision
        assert_contextual_approval_accepted "$helper" "do it" "apply-revision" "revision-review"
    done
}

@test "contextual approval rejects unsafe or ambiguous replies without mutating either helper state" {
    local helper scenario fixture reply
    for helper in "$(claude_helper)" "$(codex_helper)"; do
        for scenario in question quote negation revision change unrelated missing stale missing-feedback malformed-feedback competing; do
            case "$scenario" in
                question) fixture=pre-delegation; reply="looks good?" ;;
                quote) fixture=pre-delegation; reply='"looks good"' ;;
                negation) fixture=artifact; reply="do not continue" ;;
                revision) fixture=artifact; reply="revise this" ;;
                change) fixture=artifact; reply="change the design" ;;
                unrelated) fixture=artifact; reply="looks good but add caching" ;;
                missing) fixture=missing-descriptor; reply="yes" ;;
                stale) fixture=stale-descriptor; reply="continue" ;;
                missing-feedback) fixture=missing-feedback; reply="do it" ;;
                malformed-feedback) fixture=malformed-feedback; reply="do it" ;;
                competing) fixture=competing; reply="yes" ;;
            esac
            write_approval_fixture "$fixture"
            assert_contextual_approval_rejected_unchanged "$helper" "$reply"
        done
    done
}

@test "interview transition commands reject control answers and illegal order" {
    local helper
    helper="$(claude_helper)"
    write_skill_load
    python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"

    run python3 "$helper" confirm "$STATE_FILE" --decision-id final --source "continue"
    [ "$status" -eq 3 ]
    [[ "$output" == *"INTERVIEW_MISSING"* ]]

    python3 "$helper" begin-interview "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 --round 1 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    python3 "$helper" open-frontier "$STATE_FILE" --round 1 --decision-id storage
    run python3 "$helper" record-answer "$STATE_FILE" --decision-id storage --answer "apply the changes"
    [ "$status" -eq 3 ]
    [[ "$output" == *"CONTROL_ONLY_ANSWER"* ]]

    run python3 "$helper" confirm "$STATE_FILE" --decision-id final --source "continue"
    [ "$status" -eq 3 ]
    [[ "$output" == *"ILLEGAL_INTERVIEW_TRANSITION"* ]]

    python3 "$helper" record-answer "$STATE_FILE" \
        --decision-id storage --answer "Use PostgreSQL"
    python3 "$helper" await-confirmation "$STATE_FILE" \
        --decision-id final --approach "Use PostgreSQL"
    run python3 "$helper" confirm "$STATE_FILE" --decision-id final --source "continue"
    [ "$status" -eq 3 ]
    [[ "$output" == *"INVALID_CONFIRMATION_SOURCE"* ]]
}

@test "skip requires a nonblank assumption and preserves prior answers" {
    local helper
    helper="$(claude_helper)"
    write_skill_load
    python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    python3 "$helper" begin-interview "$STATE_FILE" --phase requirements \
        --interview-id requirements-1 --round 1 --discovery-revision rev-7 \
        --context-digest "$DIGEST"
    python3 "$helper" open-frontier "$STATE_FILE" --round 1 \
        --decision-id storage --decision-id authorization
    python3 "$helper" record-answer "$STATE_FILE" --decision-id storage --answer "Use PostgreSQL"

    run python3 "$helper" skip "$STATE_FILE" --reason "User skipped"
    [ "$status" -eq 3 ]
    [[ "$output" == *"ASSUMPTION_REQUIRED"* ]]
    run python3 "$helper" skip "$STATE_FILE" --reason "User skipped" --assumption " "
    [ "$status" -ne 0 ]

    python3 "$helper" skip "$STATE_FILE" --reason "User skipped" \
        --assumption "Keep the existing authorization model"
    run python3 -c 'import json,sys; i=json.load(open(sys.argv[1]))["phaseInterview"]; assert i["answeredDecisionIds"] == ["storage"]; assert i["assumptionsRecorded"] == ["Keep the existing authorization model"]; assert i["pendingDecisionIds"] == ["skip-confirmation"]' "$STATE_FILE"
    [ "$status" -eq 0 ]
}

@test "domain body failure warns and continues while core failure blocks" {
    local helper
    helper="$(claude_helper)"
    write_skill_load partial_warned loaded '["Domain skill body could not load"]' '[]' '["Domain skill body could not load"]'
    env DOMAIN_FILE="$DOMAIN_FILE" DOMAIN_HASH="$DOMAIN_HASH" python3 - "$TEST_DIR/skill-load.json" <<'PY'
import json
import os
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as handle:
    value = json.load(handle)
value["selected"].append({
    "name": "domain-skill",
    "reason": "Relevant domain guidance",
    "source": os.environ["DOMAIN_FILE"],
    "core": False,
    "body": {
        "sha256": None,
        "loadStatus": "failed",
        "errors": ["Domain skill body could not load"],
    },
    "requiredResourceSources": [],
    "requiredResources": [],
})
value["noDomainMatches"] = False
with open(path, "w", encoding="utf-8") as handle:
    json.dump(value, handle)
PY
    add_discovery_selection "domain-skill" "$DOMAIN_FILE"
    python3 - "$TEST_DIR/skill-load.json" "$TEST_DIR/missing-failures.json" <<'PY'
import json
import sys

source, target = sys.argv[1:]
with open(source, encoding="utf-8") as handle:
    value = json.load(handle)
value["failures"] = []
with open(target, "w", encoding="utf-8") as handle:
    json.dump(value, handle)
PY
    run python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/missing-failures.json"
    [ "$status" -eq 2 ]
    [[ "$output" == *"INCONSISTENT_SKILL_FAILURES"* ]]

    run python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    [ "$status" -eq 0 ]
    run python3 "$helper" begin-interview "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 --round 1 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    [ "$status" -eq 0 ]

    write_skill_load core_failed loaded '[]' '[]' '["Core skill body could not load"]'
    python3 - "$TEST_DIR/skill-load.json" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as handle:
    value = json.load(handle)
value["selected"][0]["body"] = {
    "sha256": None,
    "loadStatus": "failed",
    "errors": ["Core skill body could not load"],
}
with open(path, "w", encoding="utf-8") as handle:
    json.dump(value, handle)
PY
    run python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    [ "$status" -eq 0 ]
    run python3 "$helper" begin-interview "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 --round 2 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    [ "$status" -eq 3 ]
    [[ "$output" == *"SKILL_LOAD_FAILED"* ]]
}

@test "partial frontier keeps unanswered decisions pending for re-ask" {
    local helper
    helper="$(codex_helper)"
    write_skill_load
    python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    python3 "$helper" begin-interview "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 --round 1 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    python3 "$helper" open-frontier "$STATE_FILE" \
        --round 1 --decision-id storage --decision-id authorization
    python3 "$helper" record-answer "$STATE_FILE" \
        --decision-id storage --answer "Use PostgreSQL"

    run python3 -c 'import json,sys; i=json.load(open(sys.argv[1]))["phaseInterview"]; assert i["askedDecisionIds"] == ["storage", "authorization"]; assert i["answeredDecisionIds"] == ["storage"]; assert i["pendingDecisionIds"] == ["authorization"]' "$STATE_FILE"
    [ "$status" -eq 0 ]

    run python3 "$helper" await-confirmation "$STATE_FILE" \
        --decision-id final --approach "Use PostgreSQL"
    [ "$status" -eq 3 ]
    [[ "$output" == *"DECISIONS_PENDING"* ]]

    python3 "$helper" open-frontier "$STATE_FILE" --round 1 --decision-id authorization
    python3 "$helper" record-answer "$STATE_FILE" \
        --decision-id authorization --answer "Use the existing role model"
    run python3 -c 'import json,sys; i=json.load(open(sys.argv[1]))["phaseInterview"]; assert i["pendingDecisionIds"] == []; assert i["answeredDecisionIds"] == ["storage", "authorization"]' "$STATE_FILE"
    [ "$status" -eq 0 ]

    python3 "$helper" open-frontier "$STATE_FILE" --round 2 --decision-id caching
    run python3 -c 'import json,sys; i=json.load(open(sys.argv[1]))["phaseInterview"]; assert i["round"] == 2; assert i["pendingDecisionIds"] == ["caching"]' "$STATE_FILE"
    [ "$status" -eq 0 ]
}

@test "begin interview resumes matching active state without losing frontier" {
    local helper
    helper="$(claude_helper)"
    write_skill_load
    python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    python3 "$helper" begin-interview "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 --round 1 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    python3 "$helper" open-frontier "$STATE_FILE" \
        --round 1 --decision-id storage --decision-id authorization
    python3 "$helper" record-answer "$STATE_FILE" \
        --decision-id storage --answer "Use PostgreSQL"

    python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    run python3 "$helper" begin-interview "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 --round 1 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    [ "$status" -eq 0 ]
    [[ "$output" == *'"resumed": true'* ]]
    run python3 -c 'import json,sys; i=json.load(open(sys.argv[1]))["phaseInterview"]; assert i["answeredDecisionIds"] == ["storage"]; assert i["pendingDecisionIds"] == ["authorization"]' "$STATE_FILE"
    [ "$status" -eq 0 ]
}

@test "changed context bytes and state goal invalidate a reused digest" {
    local helper
    helper="$(claude_helper)"
    printf '%s\n' '# Research' 'original bytes' > "$TEST_DIR/research.md"
    write_skill_load
    DIGEST="$(context_digest requirements "$GOAL" "$TEST_DIR/research.md")"
    export DIGEST
    env DIGEST="$DIGEST" CONTEXT_FILE="$TEST_DIR/research.md" python3 - "$TEST_DIR/skill-load.json" <<'PY'
import hashlib
import json
import os
import sys

path = sys.argv[1]
value = json.load(open(path, encoding="utf-8"))
source = os.environ["CONTEXT_FILE"]
value["contextDigest"] = os.environ["DIGEST"]
value["context"]["artifacts"] = [{
    "source": source,
    "sha256": hashlib.sha256(open(source, "rb").read()).hexdigest(),
}]
json.dump(value, open(path, "w", encoding="utf-8"))
PY
    python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    python3 "$helper" begin-interview "$STATE_FILE" --phase requirements --interview-id requirements-1 \
        --round 1 --discovery-revision rev-7 --context-digest "$DIGEST"
    python3 "$helper" await-confirmation "$STATE_FILE" --decision-id final --approach "Use current research"
    python3 "$helper" confirm "$STATE_FILE" --decision-id final --source approve-and-delegate
    printf '%s\n' '# Research' 'changed bytes' > "$TEST_DIR/research.md"

    run python3 "$helper" check-delegation "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    [ "$status" -eq 3 ]
    [[ "$output" == *"SKILL_LOAD_STALE"* ]]

    printf '%s\n' '# Research' 'original bytes' > "$TEST_DIR/research.md"
    python3 -c 'import json,sys; p=sys.argv[1]; s=json.load(open(p)); s["goal"]="Changed goal"; json.dump(s,open(p,"w"))' "$STATE_FILE"
    run python3 "$helper" check-delegation "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    [ "$status" -eq 3 ]
    [[ "$output" == *"SKILL_LOAD_STALE"* ]]
}

@test "artifact write requires current receipts for every selected source" {
    local helper
    helper="$(codex_helper)"
    record_complete_gate "$helper"

    run python3 "$helper" check-agent-write "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 --context-digest "$DIGEST" \
        --discovery-revision rev-7 \
        --agent requirements-dispatch-001
    [ "$status" -eq 3 ]
    [[ "$output" == *"AGENT_LOAD_MISSING"* ]]

    python3 - "$STATE_FILE" "$TEST_DIR/agent-skill.json" "$TEST_DIR/agent-algorithm.json" "$TEST_DIR/agent-domain.json" <<'PY'
import json
import sys

state_path, body_path, algorithm_path, domain_path = sys.argv[1:]
selected = json.load(open(state_path, encoding="utf-8"))["phaseSkillLoad"]["selected"][0]
json.dump({"agent": "requirements-dispatch-001", "source": selected["source"], **selected["body"]}, open(body_path, "w", encoding="utf-8"))
algorithm, domain = selected["requiredResources"]
json.dump({"agent": "requirements-dispatch-001", **algorithm}, open(algorithm_path, "w", encoding="utf-8"))
json.dump({"agent": "requirements-dispatch-001", **domain}, open(domain_path, "w", encoding="utf-8"))
PY
    run bash -c 'python3 "$1" record-agent-load "$2" --input "$3" & first=$!; python3 "$1" record-agent-load "$2" --input "$4" & second=$!; python3 "$1" record-agent-load "$2" --input "$5" & third=$!; wait "$first" && wait "$second" && wait "$third"' \
        _ "$helper" "$STATE_FILE" "$TEST_DIR/agent-skill.json" "$TEST_DIR/agent-algorithm.json" "$TEST_DIR/agent-domain.json"
    [ "$status" -eq 0 ]

    run python3 "$helper" check-agent-write "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 --context-digest "$DIGEST" \
        --discovery-revision rev-7 \
        --agent requirements-dispatch-001
    [ "$status" -eq 0 ]
    [[ "$output" == *'"decision": "allow"'* ]]

    run python3 "$helper" check-agent-write "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 --context-digest "$DIGEST" \
        --discovery-revision rev-7 \
        --agent requirements-dispatch-002
    [ "$status" -eq 3 ]
    [[ "$output" == *"AGENT_LOAD_MISSING"* ]]

    run python3 "$helper" check-agent-write "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 --context-digest "$DIGEST" \
        --discovery-revision rev-8 \
        --agent requirements-dispatch-001
    [ "$status" -eq 3 ]
    [[ "$output" == *"SKILL_LOAD_STALE"* ]]
}

@test "triage gates work in epic state and preserve epic fields" {
    local helper epic_state phase interview_id
    helper="$(claude_helper)"
    phase="triage"
    interview_id="triage-1"
    epic_state="$TEST_DIR/epic-state.json"
    printf '%s\n' '{"name":"demo-epic","goal":"Demo goal","specs":[],"phase":"triage","ownerNote":"keep"}' > "$epic_state"
    STATE_FILE="$epic_state"
    write_skill_load
    python3 "$helper" record-skill-load "$epic_state" --input "$TEST_DIR/skill-load.json"
    python3 "$helper" begin-interview "$epic_state" \
        --phase triage --interview-id triage-1 --round 1 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    python3 "$helper" skip "$epic_state" --reason "User deferred decomposition" \
        --assumption "Keep one spec" --assumption "Use documented defaults"
    python3 "$helper" confirm "$epic_state" \
        --decision-id skip-confirmation --source "approve-and-delegate"

    run python3 "$helper" check-delegation "$epic_state" \
        --phase triage --interview-id triage-1 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    [ "$status" -eq 0 ]
    run python3 -c 'import json,sys; s=json.load(open(sys.argv[1])); assert s["ownerNote"] == "keep"; assert s["goal"] == "Demo goal"' "$epic_state"
    [ "$status" -eq 0 ]
    run python3 -c 'import json,sys; a=json.load(open(sys.argv[1]))["phaseInterview"]["assumptionsRecorded"]; assert a == ["Keep one spec", "Use documented defaults"]' "$epic_state"
    [ "$status" -eq 0 ]
}

@test "failed receipts require null hashes and core selection is packaged" {
    local helper missing
    helper="$(claude_helper)"
    missing="$TEST_DIR/missing-domain.md"
    write_skill_load partial_warned loaded '["Domain source missing"]' '[]' '["Domain source missing"]'
    env MISSING="$missing" python3 - "$TEST_DIR/skill-load.json" <<'PY'
import json
import os
import sys

path = sys.argv[1]
value = json.load(open(path, encoding="utf-8"))
value["selected"].append({
    "name": "missing-domain",
    "reason": "Relevant but unavailable",
    "source": os.environ["MISSING"],
    "core": False,
    "body": {"sha256": None, "loadStatus": "failed", "errors": ["Domain source missing"]},
    "requiredResourceSources": [],
    "requiredResources": [],
})
value["noDomainMatches"] = False
json.dump(value, open(path, "w", encoding="utf-8"))
PY
    add_discovery_selection "missing-domain" "$missing"
    run python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    [ "$status" -eq 0 ]

    python3 - "$TEST_DIR/skill-load.json" <<'PY'
import json
import sys

path = sys.argv[1]
value = json.load(open(path, encoding="utf-8"))
value["selected"][1]["body"]["sha256"] = "b" * 64
json.dump(value, open(path, "w", encoding="utf-8"))
PY
    run python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    [ "$status" -eq 2 ]
    [[ "$output" == *"INCONSISTENT_LOAD"* ]]

    write_skill_load
    env SKILL_FILE="$SKILL_FILE" SKILL_HASH="$SKILL_HASH" python3 - "$TEST_DIR/skill-load.json" <<'PY'
import json
import os
import sys

path = sys.argv[1]
value = json.load(open(path, encoding="utf-8"))
value["selected"][0]["name"] = "fake-core"
value["selected"][0]["source"] = os.environ["SKILL_FILE"]
value["selected"][0]["body"]["sha256"] = os.environ["SKILL_HASH"]
json.dump(value, open(path, "w", encoding="utf-8"))
PY
    run python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    [ "$status" -eq 2 ]
    [[ "$output" == *"CORE_SKILL_SOURCE"* ]]

    write_skill_load
    python3 -c 'import json,sys; p=sys.argv[1]; v=json.load(open(p)); v["selected"][0]["requiredResourceSources"]=[]; v["selected"][0]["requiredResources"]=[]; json.dump(v,open(p,"w"))' "$TEST_DIR/skill-load.json"
    run python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    [ "$status" -eq 2 ]
    [[ "$output" == *"CORE_RESOURCE_MISSING"* ]]

    write_skill_load
    env DOMAIN_FILE="$DOMAIN_FILE" DOMAIN_HASH="$DOMAIN_HASH" RESOURCE_FILE="$RESOURCE_FILE" python3 - "$TEST_DIR/skill-load.json" <<'PY'
import json
import os
import sys

path = sys.argv[1]
value = json.load(open(path, encoding="utf-8"))
value["selected"].append({
    "name": "domain-skill",
    "reason": "Relevant domain guidance",
    "source": os.environ["DOMAIN_FILE"],
    "core": False,
    "body": {"sha256": os.environ["DOMAIN_HASH"], "loadStatus": "loaded", "errors": []},
    "requiredResourceSources": [os.environ["RESOURCE_FILE"]],
    "requiredResources": [],
})
value["noDomainMatches"] = False
json.dump(value, open(path, "w", encoding="utf-8"))
PY
    add_discovery_selection "domain-skill" "$DOMAIN_FILE"
    run python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    [ "$status" -eq 2 ]
    [[ "$output" == *"RESOURCE_INVENTORY_MISMATCH"* ]]

    write_skill_load
    python3 - "$TEST_DIR/skill-load.json" <<'PY'
import json
import sys

path = sys.argv[1]
value = json.load(open(path, encoding="utf-8"))
value["selected"][0]["source"] = "relative/SKILL.md"
json.dump(value, open(path, "w", encoding="utf-8"))
PY
    run python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    [ "$status" -eq 2 ]
    [[ "$output" == *"RELATIVE_SOURCE"* ]]
}

@test "manifest rejects prefilled receipts, duplicate selections, and inconsistent domain flags" {
    local helper variant
    helper="$(codex_helper)"
    write_skill_load
    variant="$TEST_DIR/variant.json"

    env SKILL_FILE="$SKILL_FILE" SKILL_HASH="$SKILL_HASH" python3 - "$TEST_DIR/skill-load.json" "$variant" <<'PY'
import json
import os
import sys

source, target = sys.argv[1:]
value = json.load(open(source, encoding="utf-8"))
value["artifactAgentLoads"] = [{"agent": "dispatch-1", "source": os.environ["SKILL_FILE"], "sha256": os.environ["SKILL_HASH"], "loadStatus": "loaded", "errors": []}]
json.dump(value, open(target, "w", encoding="utf-8"))
PY
    run python3 "$helper" record-skill-load "$STATE_FILE" --input "$variant"
    [ "$status" -eq 2 ]
    [[ "$output" == *"PREFILLED_AGENT_LOADS"* ]]

    python3 - "$TEST_DIR/skill-load.json" "$variant" <<'PY'
import json
import sys

source, target = sys.argv[1:]
value = json.load(open(source, encoding="utf-8"))
duplicate = dict(value["selected"][0])
duplicate["core"] = False
value["selected"].append(duplicate)
value["noDomainMatches"] = False
json.dump(value, open(target, "w", encoding="utf-8"))
PY
    run python3 "$helper" record-skill-load "$STATE_FILE" --input "$variant"
    [ "$status" -eq 2 ]
    [[ "$output" == *"DUPLICATE_SELECTION"* ]]

    python3 - "$TEST_DIR/skill-load.json" "$variant" <<'PY'
import json
import sys

source, target = sys.argv[1:]
value = json.load(open(source, encoding="utf-8"))
value["noDomainMatches"] = False
json.dump(value, open(target, "w", encoding="utf-8"))
PY
    run python3 "$helper" record-skill-load "$STATE_FILE" --input "$variant"
    [ "$status" -eq 2 ]
    [[ "$output" == *"DOMAIN_MATCH_MISMATCH"* ]]

    python3 - "$TEST_DIR/skill-load.json" "$variant" <<'PY'
import json
import sys

source, target = sys.argv[1:]
value = json.load(open(source, encoding="utf-8"))
value["selected"][0]["core"] = False
value["noDomainMatches"] = False
json.dump(value, open(target, "w", encoding="utf-8"))
PY
    run python3 "$helper" record-skill-load "$STATE_FILE" --input "$variant"
    [ "$status" -eq 2 ]
    [[ "$output" == *"CORE_SKILL_COUNT"* ]]

    python3 - "$TEST_DIR/skill-load.json" "$variant" <<'PY'
import json
import sys

source, target = sys.argv[1:]
value = json.load(open(source, encoding="utf-8"))
value["discoveryRevision"] = -1
json.dump(value, open(target, "w", encoding="utf-8"))
PY
    run python3 "$helper" record-skill-load "$STATE_FILE" --input "$variant"
    [ "$status" -eq 2 ]
    [[ "$output" == *"INVALID_REVISION"* ]]

    python3 - "$TEST_DIR/skill-load.json" "$variant" <<'PY'
import json
import sys

source, target = sys.argv[1:]
value = json.load(open(source, encoding="utf-8"))
value["conflicts"] = [" "]
json.dump(value, open(target, "w", encoding="utf-8"))
PY
    run python3 "$helper" record-skill-load "$STATE_FILE" --input "$variant"
    [ "$status" -eq 2 ]
    [[ "$output" == *"INVALID_ARRAY"* ]]
}

@test "revise reopens decisions and reuses the canonical confirmation ID" {
    local helper
    helper="$(claude_helper)"
    write_skill_load
    python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    python3 "$helper" begin-interview "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 --round 1 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    python3 "$helper" open-frontier "$STATE_FILE" --round 1 --decision-id storage
    python3 "$helper" record-answer "$STATE_FILE" --decision-id storage --answer "Use PostgreSQL"
    python3 "$helper" await-confirmation "$STATE_FILE" --decision-id final-approval --approach "Use PostgreSQL"

    python3 "$helper" revise "$STATE_FILE" --decision-id storage
    run python3 -c 'import json,sys; i=json.load(open(sys.argv[1]))["phaseInterview"]; assert i["round"] == 2; assert i["pendingDecisionIds"] == ["storage"]; assert "final-approval" not in i["askedDecisionIds"]' "$STATE_FILE"
    [ "$status" -eq 0 ]
    python3 "$helper" record-answer "$STATE_FILE" --decision-id storage --answer "Use SQLite"
    python3 "$helper" await-confirmation "$STATE_FILE" --decision-id final-approval --approach "Use SQLite"
    python3 "$helper" confirm "$STATE_FILE" --decision-id final-approval --source "approve-and-delegate"
    run python3 "$helper" check-delegation "$STATE_FILE" \
        --phase requirements --interview-id requirements-1 \
        --discovery-revision rev-7 --context-digest "$DIGEST"
    [ "$status" -eq 0 ]
}

@test "changed manifest invalidates terminal interview evidence" {
    local helper
    helper="$(codex_helper)"
    record_complete_gate "$helper"
    write_skill_load
    env DOMAIN_FILE="$DOMAIN_FILE" DOMAIN_HASH="$DOMAIN_HASH" python3 - "$TEST_DIR/skill-load.json" <<'PY'
import json
import os
import sys

path = sys.argv[1]
value = json.load(open(path, encoding="utf-8"))
value["selected"].append({
    "name": "domain-skill",
    "reason": "New selected contract",
    "source": os.environ["DOMAIN_FILE"],
    "core": False,
    "body": {"sha256": os.environ["DOMAIN_HASH"], "loadStatus": "loaded", "errors": []},
    "requiredResourceSources": [],
    "requiredResources": [],
})
value["noDomainMatches"] = False
json.dump(value, open(path, "w", encoding="utf-8"))
PY
    add_discovery_selection "domain-skill" "$DOMAIN_FILE"
    python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    run python3 -c 'import json,sys; assert "phaseInterview" not in json.load(open(sys.argv[1]))' "$STATE_FILE"
    [ "$status" -eq 0 ]
}

@test "inconsistent interview status fields report the exact rejected invariant" {
    local helper base scenario expected_code
    helper="$(claude_helper)"
    record_complete_gate "$helper"
    base="$TEST_DIR/valid-complete-state.json"
    cp "$STATE_FILE" "$base"

    for scenario in complete_bypass skipped_without_reason awaiting_without_approach collecting_with_confirmation quick_with_confirmation; do
        case "$scenario" in
            complete_bypass) expected_code="INTERVIEW_NOT_COMPLETE" ;;
            skipped_without_reason) expected_code="INTERVIEW_NOT_SKIPPED" ;;
            awaiting_without_approach) expected_code="CONFIRMATION_NOT_PENDING" ;;
            collecting_with_confirmation) expected_code="INTERVIEW_NOT_COLLECTING" ;;
            quick_with_confirmation) expected_code="INTERVIEW_NOT_BYPASSED" ;;
        esac
        env SCENARIO="$scenario" python3 - "$base" "$STATE_FILE" <<'PY'
import json
import os
import sys

source, target = sys.argv[1:]
state = json.load(open(source, encoding="utf-8"))
interview = state["phaseInterview"]
scenario = os.environ["SCENARIO"]
if scenario == "complete_bypass":
    interview["bypassReason"] = "unexpected"
elif scenario == "skipped_without_reason":
    interview["status"] = "skipped"
elif scenario == "awaiting_without_approach":
    interview["status"] = "awaiting_confirmation"
    interview["confirmationSource"] = None
    interview["selectedApproach"] = None
    final = interview["answeredDecisionIds"].pop()
    interview["pendingDecisionIds"] = [final]
elif scenario == "collecting_with_confirmation":
    interview["status"] = "collecting"
    interview["selectedApproach"] = None
elif scenario == "quick_with_confirmation":
    state["quickMode"] = True
    state["quickAuthorization"] = {"source": "--quick"}
    interview.update({
        "status": "bypassed_quick",
        "askedDecisionIds": [],
        "pendingDecisionIds": [],
        "answeredDecisionIds": [],
        "selectedApproach": None,
        "bypassReason": "Explicit --quick authorization",
    })
json.dump(state, open(target, "w", encoding="utf-8"))
PY
        run python3 "$helper" check-delegation "$STATE_FILE" \
            --phase requirements --interview-id requirements-1 \
            --discovery-revision rev-7 --context-digest "$DIGEST"
        [ "$status" -ne 0 ]
        [[ "$output" == *"$expected_code"* ]]
    done
}

@test "both helpers complete the gate flow for all six phases" {
    local helper phase state interview_id
    for helper in "$(claude_helper)" "$(codex_helper)"; do
        for phase in start triage research requirements design tasks; do
            GOAL="Matrix"
            state="$TEST_DIR/matrix-$(basename "$(dirname "$helper")")-$phase.json"
            interview_id="$phase-1"
            if [ "$phase" = "triage" ]; then
                printf '%s\n' '{"name":"matrix-epic","goal":"Matrix","specs":[]}' > "$state"
            else
                printf '%s\n' '{"source":"spec","name":"matrix","goal":"Matrix","basePath":"./specs/matrix","phase":"requirements"}' > "$state"
            fi
            STATE_FILE="$state"
            write_skill_load
            python3 "$helper" record-skill-load "$state" --input "$TEST_DIR/skill-load.json"
            python3 "$helper" begin-interview "$state" --phase "$phase" --interview-id "$interview_id" \
                --round 1 --discovery-revision rev-7 --context-digest "$DIGEST"
            python3 "$helper" open-frontier "$state" --round 1 --decision-id choice
            python3 "$helper" record-answer "$state" --decision-id choice --answer "Use the existing path"
            python3 "$helper" await-confirmation "$state" --decision-id final-approval --approach "Use the existing path"
            python3 "$helper" confirm "$state" --decision-id final-approval --source "approve-and-delegate"
            run python3 "$helper" check-delegation "$state" --phase "$phase" --interview-id "$interview_id" \
                --discovery-revision rev-7 --context-digest "$DIGEST"
            [ "$status" -eq 0 ]
        done
    done
}

@test "state writes are atomic and leave no helper temporary files" {
    local helper
    helper="$(claude_helper)"
    write_skill_load
    run python3 "$helper" record-skill-load "$STATE_FILE" --input "$TEST_DIR/skill-load.json"
    [ "$status" -eq 0 ]

    run find "$TEST_DIR" -maxdepth 1 -name '.phase-gate-*' -print
    [ "$status" -eq 0 ]
    [ -z "$output" ]
    run find "$TEST_DIR" -maxdepth 1 -name '*.phase-gate.lock' -print
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}
