#!/usr/bin/env bats

repo_root() {
    echo "$BATS_TEST_DIRNAME/.."
}

codex_record_cli() {
    echo "$(repo_root)/plugins/ralph-specum-codex/scripts/prototype_records.py"
}

claude_record_cli() {
    echo "$(repo_root)/plugins/ralph-specum/hooks/scripts/prototype-records.py"
}

state_cli() {
    echo "$(repo_root)/plugins/ralph-specum-codex/scripts/locked_state.py"
}

record_json() {
    local prototype_id verdict gate disposition supersedes evidence_hash cleanup_hash stale_artifacts stale_task_indexes
    prototype_id="$1"
    verdict="${2:-validated}"
    gate="${3:-true}"
    disposition="${4:-retained}"
    supersedes="${5:-[]}"
    evidence_hash="${6:-}"
    cleanup_hash="${7:-}"
    stale_artifacts="${8:-[]}"
    stale_task_indexes="${9:-[]}"
    jq -nc \
        --arg id "$prototype_id" \
        --arg verdict "$verdict" \
        --argjson gate "$gate" \
        --arg disposition "$disposition" \
        --argjson supersedes "$supersedes" \
        --argjson stale_artifacts "$stale_artifacts" \
        --argjson stale_task_indexes "$stale_task_indexes" \
        --arg evidence_hash "$evidence_hash" \
        --arg cleanup_hash "$cleanup_hash" '
        def sections: {
            "Question": ("Does " + $id + " answer the design question?"),
            "Blocking Declaration": "design",
            "Isolation": (if $disposition == "not_created" then "none" else "isolated source" end),
            "Run Instructions": (if $disposition == "not_created" then "none" else "run locally" end),
            "Cases Or Variants": "normal and edge",
            "Evidence And Observations": "deterministic evidence",
            "Verdict": $verdict,
            "Downstream Handoff": "design",
            "Conflict Resolution": "none",
            "Staleness": "none",
            "Source Disposition": $disposition
        };
        {
            spec: "demo",
            phase: "prototype",
            id: $id,
            status: "terminal",
            verdict: $verdict,
            kind: "logic",
            captureMode: (if $disposition == "deleted" then "ephemeral" else "retained" end),
            triggerMode: "explicit",
            triggerPhase: "requirements",
            returnPhase: "design",
            returnTaskIndex: null,
            decisionOwner: "user",
            resolutionMode: "normal",
            gateApproved: $gate,
            created: "2026-08-28T00:00:00Z",
            completed: "2026-08-28T00:00:01Z",
            sourceDisposition: $disposition,
            evidenceHash: (if $evidence_hash == "" then null else $evidence_hash end),
            cleanupReceiptHash: (if $cleanup_hash == "" then null else $cleanup_hash end),
            staleArtifacts: $stale_artifacts,
            staleTaskIndexes: $stale_task_indexes,
            supersedes: $supersedes,
            conflictsWith: [],
            resolves: [],
            resolvedAt: null,
            sourcePointers: null,
            isolationPath: null,
            isolationBranch: null,
            sections: sections
        }'
}

active_entry_json() {
    local prototype_id status checkpoint blocking
    prototype_id="$1"
    status="${2:-reviewing}"
    checkpoint="${3-}"
    blocking="${4-}"
    [ -n "$checkpoint" ] || checkpoint='{}'
    [ -n "$blocking" ] || blocking='{}'
    jq -nc \
        --arg id "$prototype_id" \
        --arg status "$status" \
        --argjson checkpoint "$checkpoint" \
        --argjson blocking "$blocking" \
        '{id: $id, status: $status, stateRevision: 1, decisionCheckpoint: $checkpoint, blocking: $blocking}'
}

render_candidate() {
    local cli base record
    cli="$1"
    base="$2"
    record="$3"
    python3 "$cli" render-candidate --base-path "$base" --record-json "$record"
}

upsert_active() {
    local prototype_id entry
    prototype_id="$1"
    entry="${2:-$(active_entry_json "$prototype_id")}"
    python3 "$(state_cli)" upsert-prototype \
        --state "$STATE_FILE" \
        --id "$prototype_id" \
        --entry-json "$entry" >/dev/null
}

publish_record() {
    local prototype_id record rendered candidate_hash
    prototype_id="$1"
    record="$2"
    upsert_active "$prototype_id"
    rendered="$(render_candidate "$(codex_record_cli)" "$BASE_PATH" "$record")"
    candidate_hash="$(jq -r .candidateHash <<< "$rendered")"
    python3 "$(claude_record_cli)" review-candidate \
        --base-path "$BASE_PATH" \
        --state "$STATE_FILE" \
        --id "$prototype_id" \
        --candidate-hash "$candidate_hash" >/dev/null
    python3 "$(codex_record_cli)" publish \
        --base-path "$BASE_PATH" \
        --state "$STATE_FILE" \
        --id "$prototype_id"
}

setup() {
    TEST_ROOT="$(mktemp -d)"
    export TEST_ROOT
    BASE_PATH="$TEST_ROOT/specs/demo"
    export BASE_PATH
    STATE_FILE="$BASE_PATH/.ralph-state.json"
    export STATE_FILE
    mkdir -p "$BASE_PATH"
    export PYTHONDONTWRITEBYTECODE=1
}

teardown() {
    if [ -n "$TEST_ROOT" ] && [ -d "$TEST_ROOT" ]; then
        rm -rf "$TEST_ROOT"
    fi
}

@test "prototype records: candidate reservation is exclusive and no-source fields are enforced" {
    local cli skipped failed invalid
    cli="$(claude_record_cli)"
    skipped="$(record_json skipped skipped false not_created)"
    failed="$(record_json failed-before-source failed false not_created)"

    run render_candidate "$cli" "$BASE_PATH" "$skipped"
    [ "$status" -eq 0 ]
    run render_candidate "$cli" "$BASE_PATH" "$skipped"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Refusing to overwrite existing path:"* ]]

    run render_candidate "$(codex_record_cli)" "$BASE_PATH" "$failed"
    [ "$status" -eq 0 ]

    invalid="$(record_json invalid-skip skipped false retained)"
    run render_candidate "$(codex_record_cli)" "$BASE_PATH" "$invalid"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Skipped prototypes require sourceDisposition not_created."* ]]
    [ ! -e "$BASE_PATH/prototypes/.invalid-skip.candidate.md" ]
}

@test "prototype records: only reviewed exact candidate bytes publish" {
    local cli prototype_id rendered candidate_hash snapshot
    cli="$(codex_record_cli)"
    prototype_id="exact-review"
    upsert_active "$prototype_id"
    rendered="$(render_candidate "$cli" "$BASE_PATH" "$(record_json "$prototype_id")")"
    candidate_hash="$(jq -r .candidateHash <<< "$rendered")"
    snapshot="$TEST_ROOT/reviewed.md"
    cp "$BASE_PATH/prototypes/.$prototype_id.candidate.md" "$snapshot"

    run python3 "$cli" review-candidate --base-path "$BASE_PATH" --state "$STATE_FILE" --id "$prototype_id" --candidate-hash wrong
    [ "$status" -ne 0 ]
    run python3 "$cli" review-candidate --base-path "$BASE_PATH" --state "$STATE_FILE" --id "$prototype_id" --candidate-hash "$candidate_hash"
    [ "$status" -eq 0 ]
    run python3 "$cli" publish --base-path "$BASE_PATH" --state "$STATE_FILE" --id "$prototype_id"
    [ "$status" -eq 0 ]
    cmp "$snapshot" "$BASE_PATH/prototypes/$prototype_id.md"
    [ ! -e "$BASE_PATH/prototypes/.$prototype_id.candidate.md" ]
    run jq -e '.activePrototypes["exact-review"] == null' "$STATE_FILE"
    [ "$status" -eq 0 ]

    prototype_id="changed-after-review"
    upsert_active "$prototype_id"
    rendered="$(render_candidate "$cli" "$BASE_PATH" "$(record_json "$prototype_id")")"
    candidate_hash="$(jq -r .candidateHash <<< "$rendered")"
    python3 "$cli" review-candidate --base-path "$BASE_PATH" --state "$STATE_FILE" --id "$prototype_id" --candidate-hash "$candidate_hash" >/dev/null
    printf '%s\n' changed-after-review >> "$BASE_PATH/prototypes/.$prototype_id.candidate.md"
    run python3 "$cli" publish --base-path "$BASE_PATH" --state "$STATE_FILE" --id "$prototype_id"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Publisher requires REVIEW_PASS for these exact candidate bytes."* ]]
    [ ! -e "$BASE_PATH/prototypes/$prototype_id.md" ]
    run jq -e '.activePrototypes["changed-after-review"] != null' "$STATE_FILE"
    [ "$status" -eq 0 ]
}

@test "prototype records: an existing final is immutable and a collision preserves both byte sets" {
    local prototype_id final_path original_hash rendered candidate_hash
    prototype_id="immutable"
    publish_record "$prototype_id" "$(record_json "$prototype_id" validated true)" >/dev/null
    final_path="$BASE_PATH/prototypes/$prototype_id.md"
    original_hash="$(shasum -a 256 "$final_path" | awk '{print $1}')"

    upsert_active "$prototype_id"
    rendered="$(render_candidate "$(codex_record_cli)" "$BASE_PATH" "$(record_json "$prototype_id" rejected true)")"
    candidate_hash="$(jq -r .candidateHash <<< "$rendered")"
    python3 "$(codex_record_cli)" review-candidate --base-path "$BASE_PATH" --state "$STATE_FILE" --id "$prototype_id" --candidate-hash "$candidate_hash" >/dev/null
    run python3 "$(codex_record_cli)" publish --base-path "$BASE_PATH" --state "$STATE_FILE" --id "$prototype_id"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Prototype id collision:"* ]]
    [ "$(shasum -a 256 "$final_path" | awk '{print $1}')" = "$original_hash" ]
    [ -f "$BASE_PATH/prototypes/.$prototype_id.candidate.md" ]
    run jq -e '.activePrototypes.immutable != null' "$STATE_FILE"
    [ "$status" -eq 0 ]
}

@test "prototype records: reconciliation covers every candidate, final, and active state" {
    local other rendered
    other="$TEST_ROOT/other"
    mkdir -p "$other/prototypes" "$BASE_PATH/prototypes"

    render_candidate "$(codex_record_cli)" "$BASE_PATH" "$(record_json resume)" >/dev/null

    render_candidate "$(codex_record_cli)" "$BASE_PATH" "$(record_json matching)" >/dev/null
    cp "$BASE_PATH/prototypes/.matching.candidate.md" "$BASE_PATH/prototypes/matching.md"
    upsert_active matching

    render_candidate "$(codex_record_cli)" "$BASE_PATH" "$(record_json mismatch validated true)" >/dev/null
    rendered="$(render_candidate "$(codex_record_cli)" "$other" "$(record_json mismatch rejected true)")"
    cp "$(jq -r .candidate <<< "$rendered")" "$BASE_PATH/prototypes/mismatch.md"
    upsert_active mismatch

    rendered="$(render_candidate "$(codex_record_cli)" "$other" "$(record_json final-only)")"
    cp "$(jq -r .candidate <<< "$rendered")" "$BASE_PATH/prototypes/final-only.md"

    rendered="$(render_candidate "$(codex_record_cli)" "$other" "$(record_json final-active)")"
    cp "$(jq -r .candidate <<< "$rendered")" "$BASE_PATH/prototypes/final-active.md"
    upsert_active final-active

    upsert_active active-only "$(active_entry_json active-only blocked)"
    printf '%s\n' 'not a prototype record' > "$BASE_PATH/prototypes/malformed.md"

    run python3 "$(claude_record_cli)" reconcile --base-path "$BASE_PATH" --state "$STATE_FILE"
    [ "$status" -eq 0 ]
    jq -e '
        any(.actions[]; .id == "resume" and .action == "resume_review") and
        any(.actions[]; .id == "matching" and .action == "complete_matching_publish") and
        any(.actions[]; .id == "mismatch" and .action == "quarantine_candidate") and
        any(.actions[]; .id == "final-only" and .action == "complete") and
        any(.actions[]; .id == "final-active" and .action == "remove_verified_active") and
        any(.actions[]; .id == "active-only" and .action == "resume_active" and .status == "blocked") and
        any(.actions[]; .id == "malformed" and .action == "quarantine_final")
    ' <<< "$output"

    [ ! -e "$BASE_PATH/prototypes/.matching.candidate.md" ]
    [ -n "$(find "$BASE_PATH/prototypes" -name '.mismatch*.quarantine.md' -print -quit)" ]
    [ -f "$BASE_PATH/prototypes/malformed.md" ]
    run jq -e '
        .activePrototypes.matching == null and
        .activePrototypes["final-active"] == null and
        .activePrototypes.mismatch != null and
        .activePrototypes["active-only"] != null
    ' "$STATE_FILE"
    [ "$status" -eq 0 ]
}

@test "prototype records: every live status resumes with its decision checkpoint unchanged" {
    local statuses before after index status checkpoint
    statuses=(pending isolating building reviewing awaiting_verdict handoff blocked timed_out)
    index=0
    for status in "${statuses[@]}"; do
        checkpoint="$(jq -nc --arg verdict "verdict-$index" --argjson task "$index" '{selectedVerdict: $verdict, staleArtifacts: ["design.md"], staleTaskIndexes: [$task]}')"
        upsert_active "status-$index" "$(active_entry_json "status-$index" "$status" "$checkpoint")"
        index=$((index + 1))
    done
    before="$(shasum -a 256 "$STATE_FILE" | awk '{print $1}')"

    run python3 "$(codex_record_cli)" reconcile --base-path "$BASE_PATH" --state "$STATE_FILE"
    [ "$status" -eq 0 ]
    [ "$(jq '[.actions[] | select(.action == "resume_active")] | length' <<< "$output")" -eq 8 ]
    index=0
    for status in "${statuses[@]}"; do
        jq -e --arg id "status-$index" --arg expected "$status" \
            'any(.actions[]; .id == $id and .action == "resume_active" and .status == $expected)' <<< "$output"
        index=$((index + 1))
    done
    after="$(shasum -a 256 "$STATE_FILE" | awk '{print $1}')"
    [ "$after" = "$before" ]
    run jq -e '.activePrototypes["status-4"].decisionCheckpoint.selectedVerdict == "verdict-4"' "$STATE_FILE"
    [ "$status" -eq 0 ]
}

@test "prototype records: downstream selection excludes superseded and malformed evidence and returns nested gates" {
    local blocker_entry selected
    publish_record old "$(record_json old validated true retained '[]' '' '' '["superseded.md"]' '[98]')" >/dev/null
    publish_record replacement "$(record_json replacement rejected true retained '["old"]')" >/dev/null
    publish_record excluded "$(record_json excluded inconclusive false retained '[]' '' '' '["excluded.md"]' '[99]')" >/dev/null
    printf '%s\n' malformed > "$BASE_PATH/prototypes/bad.md"
    blocker_entry="$(active_entry_json blocker blocked \
        '{"staleArtifacts":["tasks.md","design.md"],"staleTaskIndexes":[7,3]}' \
        '{"blocks":["design","task:3"]}')"
    blocker_entry="$(jq '. + {blockedArtifacts:["legacy"],staleArtifacts:["legacy.md"],staleTaskIndexes:[99]}' <<< "$blocker_entry")"
    upsert_active blocker "$blocker_entry"

    run python3 "$(claude_record_cli)" select-downstream --base-path "$BASE_PATH" --state "$STATE_FILE"
    [ "$status" -eq 0 ]
    selected="$output"
    [ "$(jq -c '[.selected[].id]' <<< "$selected")" = '["replacement"]' ]
    [ "$(jq -c .superseded <<< "$selected")" = '["old"]' ]
    [ "$(jq -r '.quarantined[] | select(.path | endswith("/bad.md")) | .reason' <<< "$selected")" != "" ]
    [ "$(jq -c '[.activeBlockers[] | {blocked,id,status}]' <<< "$selected")" = '[{"blocked":["design","task:3"],"id":"blocker","status":"blocked"}]' ]
    [ "$(jq -c .staleArtifacts <<< "$selected")" = '["design.md","tasks.md"]' ]
    [ "$(jq -c .staleTaskIndexes <<< "$selected")" = '[3,7]' ]
}

@test "prototype records: downstream selection proves each requested target or blocks conservatively" {
    local entry selected
    entry="$(active_entry_json dependency building '{}' '{"blocks":["design"]}')"
    entry="$(jq '. + {
        returnPhase:"execution",
        returnTaskIndex:4,
        isolation:{approvedTransfers:["src/prototype.ts"]}
    }' <<< "$entry")"
    upsert_active dependency "$entry"

    run python3 "$(claude_record_cli)" select-downstream \
        --base-path "$BASE_PATH" --state "$STATE_FILE" \
        --target design --path design.md
    [ "$status" -eq 0 ]
    selected="$output"
    [ "$(jq -c '.activeBlockers[0] | {id,returnPhase,returnTaskIndex}' <<< "$selected")" = \
        '{"id":"dependency","returnPhase":"execution","returnTaskIndex":4}' ]
    [ "$(jq -r '.targetDecisions[0].eligible' <<< "$selected")" = false ]
    [ "$(jq -c '.targetDecisions[0].blockedBy' <<< "$selected")" = '["dependency"]' ]

    run python3 "$(codex_record_cli)" select-downstream \
        --base-path "$BASE_PATH" --state "$STATE_FILE" \
        --target tasks --path tasks.md
    [ "$status" -eq 0 ]
    [ "$(jq -r '.targetDecisions[0].proofAvailable' <<< "$output")" = true ]
    [ "$(jq -r '.targetDecisions[0].eligible' <<< "$output")" = true ]

    entry="$(active_entry_json unknown building '{}' '{}')"
    upsert_active unknown "$entry"
    run python3 "$(codex_record_cli)" select-downstream \
        --base-path "$BASE_PATH" --state "$STATE_FILE" --target tasks
    [ "$status" -eq 0 ]
    [ "$(jq -r '.targetDecisions[0].proofAvailable' <<< "$output")" = false ]
    [ "$(jq -r '.targetDecisions[0].eligible' <<< "$output")" = false ]
    [ "$(jq -c '.targetDecisions[0].proofUnavailableFor' <<< "$output")" = '["dependency","unknown"]' ]
}

@test "prototype records: published terminal staleness survives active-state removal and rejects malformed types" {
    local cli selected invalid_artifacts invalid_indexes
    publish_record terminal-stale \
        "$(record_json terminal-stale validated true retained '[]' '' '' '["design.md","tasks.md","src/api"]' '[3,7]')" >/dev/null
    run jq -e 'has("activePrototypes") | not' "$STATE_FILE"
    [ "$status" -eq 0 ]

    run python3 "$(codex_record_cli)" select-downstream --base-path "$BASE_PATH" --state "$STATE_FILE"
    [ "$status" -eq 0 ]
    selected="$output"
    [ "$(jq -c '.selected[0].staleArtifacts' <<< "$selected")" = '["design.md","tasks.md","src/api"]' ]
    [ "$(jq -c '.selected[0].staleTaskIndexes' <<< "$selected")" = '[3,7]' ]
    [ "$(jq -c .staleArtifacts <<< "$selected")" = '["design.md","src/api","tasks.md"]' ]
    [ "$(jq -c .staleTaskIndexes <<< "$selected")" = '[3,7]' ]

    for cli in "$(claude_record_cli)" "$(codex_record_cli)"; do
        run python3 "$cli" select-downstream \
            --base-path "$BASE_PATH" --state "$STATE_FILE" \
            --target src/api/handler.ts
        [ "$status" -eq 0 ]
        [ "$(jq -c '.targetDecisions[0].staleBy' <<< "$output")" = '["terminal-stale"]' ]
        [ "$(jq -r '.targetDecisions[0].eligible' <<< "$output")" = false ]
    done

    invalid_artifacts="$(record_json invalid-artifacts validated true retained '[]' '' '' '"design.md"' '[]')"
    run render_candidate "$(codex_record_cli)" "$BASE_PATH" "$invalid_artifacts"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Prototype staleArtifacts must be an array of strings."* ]]

    invalid_indexes="$(record_json invalid-indexes validated true retained '[]' '' '' '[]' '[true]')"
    run render_candidate "$(codex_record_cli)" "$BASE_PATH" "$invalid_indexes"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Prototype staleTaskIndexes must be an array of non-negative integers."* ]]
}

@test "prototype records: state failures exit two without a traceback" {
    local cli invalid_active
    printf '{ invalid\n' > "$STATE_FILE"
    for cli in "$(claude_record_cli)" "$(codex_record_cli)"; do
        run python3 "$cli" select-downstream --base-path "$BASE_PATH" --state "$STATE_FILE"
        [ "$status" -eq 2 ]
        [[ "$output" == *"State file is not valid JSON:"* ]]
        [[ "$output" != *"Traceback"* ]]
    done

    for invalid_active in null false 0 '[]' '""'; do
        printf '{"activePrototypes":%s}\n' "$invalid_active" > "$STATE_FILE"
        for cli in "$(claude_record_cli)" "$(codex_record_cli)"; do
            run python3 "$cli" reconcile --base-path "$BASE_PATH" --state "$STATE_FILE"
            [ "$status" -eq 2 ]
            [[ "$output" == *"activePrototypes must be an object."* ]]
            [[ "$output" != *"Traceback"* ]]
        done
    done
}

@test "prototype records: cleanup receipt gates post-deletion review and missing-source resume" {
    local source_path receipt receipt_path receipt_hash evidence_hash rendered candidate_hash
    source_path="$TEST_ROOT/ephemeral-source"
    mkdir -p "$source_path"
    evidence_hash="bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
    receipt="$(python3 "$(codex_record_cli)" cleanup-receipt \
        --base-path "$BASE_PATH" \
        --id cleanup \
        --receipt-json "$(jq -nc --arg source "$source_path" --arg evidence "$evidence_hash" '{candidateHash:("a" * 64),evidenceHash:$evidence,isolationPath:$source,provenance:"quick_ephemeral"}')")"
    receipt_path="$(jq -r .receipt <<< "$receipt")"
    receipt_hash="$(jq -r .receiptHash <<< "$receipt")"
    upsert_active cleanup
    rendered="$(render_candidate "$(claude_record_cli)" "$BASE_PATH" "$(record_json cleanup validated true deleted '[]' "$evidence_hash" "$receipt_hash")")"
    candidate_hash="$(jq -r .candidateHash <<< "$rendered")"

    run python3 "$(codex_record_cli)" review-candidate \
        --base-path "$BASE_PATH" --state "$STATE_FILE" --id cleanup \
        --candidate-hash "$candidate_hash" --cleanup-receipt "$receipt_path"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Cleanup source still exists:"* ]]

    rmdir "$source_path"
    run python3 "$(codex_record_cli)" reconcile --base-path "$BASE_PATH" --state "$STATE_FILE"
    [ "$status" -eq 0 ]
    jq -e 'any(.actions[]; .id == "cleanup" and .action == "resume_review")' <<< "$output"

    run python3 "$(codex_record_cli)" review-candidate \
        --base-path "$BASE_PATH" --state "$STATE_FILE" --id cleanup \
        --candidate-hash "$candidate_hash" --cleanup-receipt "$receipt_path"
    [ "$status" -eq 0 ]
    run python3 "$(claude_record_cli)" publish --base-path "$BASE_PATH" --state "$STATE_FILE" --id cleanup
    [ "$status" -eq 0 ]
    [ -f "$BASE_PATH/prototypes/cleanup.md" ]
    run jq -e '.activePrototypes.cleanup == null' "$STATE_FILE"
    [ "$status" -eq 0 ]
}

@test "prototype records: candidates and receipts stay local while finals remain committable" {
    local root
    root="$(repo_root)"
    run git -C "$root" check-ignore -q specs/example/prototypes/.candidate.candidate.md
    [ "$status" -eq 0 ]
    run git -C "$root" check-ignore -q specs/example/prototypes/.candidate.cleanup.json
    [ "$status" -eq 0 ]
    run git -C "$root" check-ignore -q specs/example/prototypes/final.md
    [ "$status" -ne 0 ]
    run git -C "$root" check-ignore -q specs/example/prototypes/.candidate.20260828.quarantine.md
    [ "$status" -ne 0 ]

    run rg -n 'subprocess|requests|urllib|git push|gh pr|curl' \
        "$(codex_record_cli)" \
        "$(state_cli)"
    [ "$status" -eq 1 ]
    run rg -l 'does not authorize a push' \
        "$root/plugins/ralph-specum/references/prototype-coordinator.md" \
        "$root/plugins/ralph-specum-codex/references/prototype-coordinator.md"
    [ "$status" -eq 0 ]
    [ "$(wc -l <<< "$output" | tr -d '[:space:]')" -eq 2 ]
}
