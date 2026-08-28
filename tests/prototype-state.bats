#!/usr/bin/env bats

repo_root() {
    echo "$BATS_TEST_DIRNAME/.."
}

state_cli() {
    echo "$(repo_root)/plugins/ralph-specum-codex/scripts/locked_state.py"
}

merge_cli() {
    echo "$(repo_root)/plugins/ralph-specum-codex/scripts/merge_state.py"
}

claude_state_cli() {
    echo "$(repo_root)/plugins/ralph-specum/hooks/scripts/locked-state.py"
}

record_cli() {
    echo "$(repo_root)/plugins/ralph-specum/hooks/scripts/prototype-records.py"
}

resolver_cli() {
    echo "$(repo_root)/plugins/ralph-specum-codex/scripts/resolve_spec_paths.py"
}

entry_json() {
    local prototype_id status revision request_attempt builder_attempt hard_deadline
    prototype_id="$1"
    status="${2:-pending}"
    revision="${3:-1}"
    request_attempt="${4:-1}"
    builder_attempt="${5:-0}"
    hard_deadline="${6:-2099-01-01T00:00:00Z}"
    jq -nc \
        --arg id "$prototype_id" \
        --arg status "$status" \
        --argjson revision "$revision" \
        --argjson request_attempt "$request_attempt" \
        --argjson builder_attempt "$builder_attempt" \
        --arg hard_deadline "$hard_deadline" \
        '{
            id: $id,
            status: $status,
            stateRevision: $revision,
            requestAttempt: $request_attempt,
            builderExecutionAttempt: $builder_attempt,
            builderHardDeadline: $hard_deadline
        }'
}

lock_timeout_record_json() {
    jq -nc '
        def sections: {
            "Question": "Can quick mode record a lock timeout?",
            "Blocking Declaration": "none",
            "Isolation": "none",
            "Run Instructions": "none",
            "Cases Or Variants": "none",
            "Evidence And Observations": "State lock acquisition timed out.",
            "Verdict": "failed",
            "Downstream Handoff": "none",
            "Conflict Resolution": "none",
            "Staleness": "none",
            "Source Disposition": "not_created"
        };
        {
            spec: "demo",
            phase: "prototype",
            id: "quick-lock-timeout",
            status: "terminal",
            verdict: "failed",
            kind: "logic",
            captureMode: "ephemeral",
            triggerMode: "quick",
            triggerPhase: "requirements",
            returnPhase: "design",
            returnTaskIndex: null,
            decisionOwner: "agent",
            resolutionMode: "lock_timeout",
            gateApproved: false,
            created: "2026-08-28T00:00:00Z",
            completed: "2026-08-28T00:00:01Z",
            sourceDisposition: "not_created",
            evidenceHash: null,
            cleanupReceiptHash: null,
            sections: sections
        }'
}

setup() {
    TEST_ROOT="$(mktemp -d)"
    export TEST_ROOT
    STATE_FILE="$TEST_ROOT/specs/demo/.ralph-state.json"
    export STATE_FILE
    mkdir -p "$(dirname "$STATE_FILE")"
    export PYTHONDONTWRITEBYTECODE=1
}

teardown() {
    if [ -n "$TEST_ROOT" ] && [ -d "$TEST_ROOT" ]; then
        rm -rf "$TEST_ROOT"
    fi
}

@test "prototype state: concurrent merges, upserts, and removal preserve every update" {
    local cli seed
    cli="$(state_cli)"
    seed="$(entry_json remove-me)"
    python3 "$cli" merge --state "$STATE_FILE" --set phase=research >/dev/null
    python3 "$cli" upsert-prototype --state "$STATE_FILE" --id remove-me --entry-json "$seed" >/dev/null

    run bash -c '
        cli="$1"
        state="$2"
        one="$3"
        two="$4"
        pids=""
        python3 "$cli" merge --state "$state" --set phase=requirements >/dev/null & pids="$pids $!"
        python3 "$cli" merge --state "$state" --set awaitingApproval=true >/dev/null & pids="$pids $!"
        python3 "$cli" upsert-prototype --state "$state" --id one --entry-json "$one" >/dev/null & pids="$pids $!"
        python3 "$cli" upsert-prototype --state "$state" --id two --entry-json "$two" >/dev/null & pids="$pids $!"
        python3 "$cli" remove-prototype --state "$state" --id remove-me >/dev/null & pids="$pids $!"
        for pid in $pids; do
            wait "$pid" || exit $?
        done
    ' _ "$cli" "$STATE_FILE" "$(entry_json one)" "$(entry_json two)"
    [ "$status" -eq 0 ]

    run jq -e '
        .phase == "requirements" and
        .awaitingApproval == true and
        (.activePrototypes | keys | sort) == ["one", "two"]
    ' "$STATE_FILE"
    [ "$status" -eq 0 ]
}

@test "prototype state: compare-and-set permits only one builder launch" {
    local cli
    cli="$(state_cli)"
    python3 "$cli" upsert-prototype --state "$STATE_FILE" --id race --entry-json "$(entry_json race)" >/dev/null

    run bash -c '
        cli="$1"
        state="$2"
        out="$3"
        python3 "$cli" claim-builder --state "$state" --id race --expected-revision 1 --owner first --lease-token first-token >"$out/first" 2>&1 & first=$!
        python3 "$cli" claim-builder --state "$state" --id race --expected-revision 1 --owner second --lease-token second-token >"$out/second" 2>&1 & second=$!
        first_status=0
        second_status=0
        wait "$first" || first_status=$?
        wait "$second" || second_status=$?
        successes=0
        [ "$first_status" -eq 0 ] && successes=$((successes + 1))
        [ "$second_status" -eq 0 ] && successes=$((successes + 1))
        printf "%s\n" "$successes"
    ' _ "$cli" "$STATE_FILE" "$TEST_ROOT"
    [ "$status" -eq 0 ]
    [ "$output" = "1" ]

    run jq -e '
        .activePrototypes.race.status == "building" and
        .activePrototypes.race.stateRevision == 2 and
        .activePrototypes.race.requestAttempt == 1 and
        .activePrototypes.race.builderExecutionAttempt == 1 and
        (.activePrototypes.race.owner == "first" or .activePrototypes.race.owner == "second")
    ' "$STATE_FILE"
    [ "$status" -eq 0 ]
}

@test "prototype state: heartbeat, renewal, release, and retry keep request and execution counts separate" {
    local cli claim_revision release_revision
    cli="$(state_cli)"
    python3 "$cli" upsert-prototype --state "$STATE_FILE" --id lease --entry-json "$(entry_json lease)" >/dev/null

    run python3 "$cli" claim-builder --state "$STATE_FILE" --id lease --expected-revision 1 --owner worker --lease-token lease-token --lease-seconds 30
    [ "$status" -eq 0 ]
    claim_revision="$(jq -r .stateRevision <<< "$output")"
    [ "$claim_revision" -eq 2 ]

    run python3 "$cli" heartbeat --state "$STATE_FILE" --id lease --lease-token wrong-token
    [ "$status" -ne 0 ]

    run python3 "$cli" heartbeat --state "$STATE_FILE" --id lease --lease-token lease-token
    [ "$status" -eq 0 ]
    run python3 "$cli" renew-lease --state "$STATE_FILE" --id lease --lease-token lease-token --lease-seconds 60
    [ "$status" -eq 0 ]
    run python3 "$cli" release-lease --state "$STATE_FILE" --id lease --lease-token lease-token --status pending
    [ "$status" -eq 0 ]
    release_revision="$(jq -r .stateRevision <<< "$output")"

    run python3 "$cli" claim-builder --state "$STATE_FILE" --id lease --expected-revision "$release_revision" --owner worker --lease-token retry-token
    [ "$status" -eq 0 ]
    [ "$(jq -r .requestAttempt <<< "$output")" -eq 1 ]
    [ "$(jq -r .builderExecutionAttempt <<< "$output")" -eq 2 ]
    [ "$(jq -r .leaseToken <<< "$output")" = "retry-token" ]
}

@test "prototype state: phase writers preserve overlays and guarded deletion refuses active work" {
    local codex_merge claude_cli
    codex_merge="$(merge_cli)"
    claude_cli="$(claude_state_cli)"
    python3 "$claude_cli" upsert-prototype --state "$STATE_FILE" --id active --entry-json "$(entry_json active)" >/dev/null

    run python3 "$codex_merge" "$STATE_FILE" --set phase=design --set awaitingApproval=true
    [ "$status" -eq 0 ]
    run jq -e '.phase == "design" and .awaitingApproval == true and .activePrototypes.active.id == "active"' "$STATE_FILE"
    [ "$status" -eq 0 ]

    run python3 "$claude_cli" delete-state --state "$STATE_FILE"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Refusing to delete state with activePrototypes."* ]]
    [ -f "$STATE_FILE" ]

    python3 "$claude_cli" remove-prototype --state "$STATE_FILE" --id active >/dev/null
    run jq -e 'has("activePrototypes") | not' "$STATE_FILE"
    [ "$status" -eq 0 ]
    run python3 "$claude_cli" delete-state --state "$STATE_FILE"
    [ "$status" -eq 0 ]
    [ ! -e "$STATE_FILE" ]
}

@test "prototype state: configured roots resolve one base path and avoid default-root writes" {
    local config result base_path state_path
    mkdir -p "$TEST_ROOT/.claude" "$TEST_ROOT/custom-specs/demo"
    config=$'---\nspecs_dirs: ["./missing", "./custom-specs"]\nprototype_lock_timeout_seconds: 7\n---\n'
    printf '%s' "$config" > "$TEST_ROOT/.claude/ralph-specum.local.md"
    printf '%s\n' demo > "$TEST_ROOT/custom-specs/.current-spec"

    run python3 "$(resolver_cli)" --cwd "$TEST_ROOT"
    [ "$status" -eq 0 ]
    result="$output"
    base_path="$(jq -r .basePath <<< "$result")"
    [ "$base_path" = "./custom-specs/demo" ]
    [ "$(jq -r .specRoot <<< "$result")" = "./custom-specs" ]
    [ "$(jq -r .prototype_settings.prototype_lock_timeout_seconds <<< "$result")" -eq 7 ]

    state_path="$TEST_ROOT/${base_path#./}/.ralph-state.json"
    python3 "$(state_cli)" merge --state "$state_path" --set phase=requirements >/dev/null
    [ -f "$state_path" ]
    [ ! -e "$TEST_ROOT/specs/demo/.ralph-state.json" ]
}

@test "prototype state: POSIX lock path times out without changing state" {
    local cli lock_path ready holder before after ready_waits lock_status lock_output
    cli="$(state_cli)"
    lock_path="$(dirname "$STATE_FILE")/.ralph-state.lock"
    ready="$TEST_ROOT/lock-ready"
    python3 "$cli" merge --state "$STATE_FILE" --set phase=research >/dev/null
    before="$(shasum -a 256 "$STATE_FILE" | awk '{print $1}')"

    python3 -c '
import fcntl, pathlib, sys, time
lock_path = pathlib.Path(sys.argv[1])
lock_path.parent.mkdir(parents=True, exist_ok=True)
with lock_path.open("a+") as handle:
    fcntl.flock(handle.fileno(), fcntl.LOCK_EX)
    pathlib.Path(sys.argv[2]).touch()
    time.sleep(30)
' "$lock_path" "$ready" &
    holder=$!
    ready_waits=0
    while [ ! -e "$ready" ] && [ "$ready_waits" -lt 100 ]; do
        sleep 0.05
        ready_waits=$((ready_waits + 1))
    done
    if [ ! -e "$ready" ]; then
        kill "$holder" >/dev/null 2>&1 || true
        wait "$holder" >/dev/null 2>&1 || true
    fi
    [ -e "$ready" ]

    run python3 "$cli" merge --state "$STATE_FILE" --timeout 0.1 --set phase=design
    lock_status="$status"
    lock_output="$output"
    kill "$holder" >/dev/null 2>&1 || true
    wait "$holder" >/dev/null 2>&1 || true
    [ "$lock_status" -ne 0 ]
    [[ "$lock_output" == *"Timed out acquiring lock:"* ]]
    [ -f "$lock_path" ]
    after="$(shasum -a 256 "$STATE_FILE" | awk '{print $1}')"
    [ "$after" = "$before" ]
}

@test "prototype state: simulated Windows directory locks break stale owners and time out on live owners" {
    run python3 - "$(state_cli)" "$STATE_FILE" <<'PY'
import importlib.util
import json
import os
import socket
import sys
from pathlib import Path

module_path = Path(sys.argv[1])
state_path = Path(sys.argv[2])
spec = importlib.util.spec_from_file_location("prototype_locked_state", module_path)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)
module.fcntl = None
lock_path = state_path.parent / ".ralph-state.lock"

with module.lock_for(state_path, 0.2):
    assert lock_path.is_dir()
    owner = json.loads((lock_path / "owner.json").read_text(encoding="utf-8"))
    assert owner["host"] == socket.gethostname()
assert not lock_path.exists()

lock_path.mkdir()
(lock_path / "owner.json").write_text(json.dumps({
    "host": socket.gethostname(),
    "pid": os.getpid() + 100000,
    "created": "2000-01-01T00:00:00Z",
    "heartbeatAt": "2000-01-01T00:00:00Z",
}), encoding="utf-8")
with module.directory_lock(lock_path, 0.2, stale_seconds=1):
    current = json.loads((lock_path / "owner.json").read_text(encoding="utf-8"))
    assert current["pid"] == os.getpid()
assert not lock_path.exists()

lock_path.mkdir()
(lock_path / "owner.json").write_text(json.dumps({
    "host": socket.gethostname(),
    "pid": os.getpid(),
    "created": module.utc_now(),
    "heartbeatAt": module.utc_now(),
}), encoding="utf-8")
try:
    with module.directory_lock(lock_path, 0.05, stale_seconds=600):
        raise AssertionError("live lock was acquired")
except module.StateError as exc:
    assert "Timed out acquiring lock:" in str(exc)
else:
    raise AssertionError("live lock did not time out")
PY
    [ "$status" -eq 0 ]
}

@test "prototype state: atomic writer recovers before and after replacement failures" {
    run python3 - "$(state_cli)" "$STATE_FILE" <<'PY'
import importlib.util
import json
import sys
from pathlib import Path

module_path = Path(sys.argv[1])
state_path = Path(sys.argv[2])
spec = importlib.util.spec_from_file_location("prototype_locked_state_recovery", module_path)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

module.write_json_atomic(state_path, {"phase": "research", "preserved": True})
real_replace = module.os.replace

def fail_before_replace(source, target):
    raise OSError("crash before replace")

module.os.replace = fail_before_replace
try:
    module.write_json_atomic(state_path, {"phase": "requirements"})
except OSError:
    pass
else:
    raise AssertionError("pre-replace failure did not surface")
assert module.read_json_object(state_path) == {"phase": "research", "preserved": True}
assert state_path.with_name(state_path.name + ".tmp").exists()

module.os.replace = real_replace
module.write_json_atomic(state_path, {"phase": "requirements", "recovered": True})
assert module.read_json_object(state_path)["recovered"] is True
assert not state_path.with_name(state_path.name + ".tmp").exists()

def fail_after_replace(_path):
    raise OSError("crash after replace")

module.fsync_dir = fail_after_replace
try:
    module.write_json_atomic(state_path, {"phase": "design", "committed": True})
except OSError:
    pass
else:
    raise AssertionError("post-replace failure did not surface")
assert module.read_json_object(state_path) == {"phase": "design", "committed": True}
PY
    [ "$status" -eq 0 ]
}

@test "prototype state: quick lock-timeout publication is exclusive and never reads state" {
    local rendered candidate_hash before published after
    rendered="$(python3 "$(record_cli)" render-candidate --base-path "$(dirname "$STATE_FILE")" --record-json "$(lock_timeout_record_json)")"
    candidate_hash="$(jq -r .candidateHash <<< "$rendered")"
    printf '{ state lock is unavailable\n' > "$STATE_FILE"
    before="$(shasum -a 256 "$STATE_FILE" | awk '{print $1}')"

    run python3 "$(record_cli)" publish \
        --base-path "$(dirname "$STATE_FILE")" \
        --id quick-lock-timeout \
        --publisher-only-lock-timeout \
        --candidate-hash wrong
    [ "$status" -ne 0 ]
    [ -f "$(dirname "$STATE_FILE")/prototypes/.quick-lock-timeout.candidate.md" ]

    run python3 "$(record_cli)" publish \
        --base-path "$(dirname "$STATE_FILE")" \
        --id quick-lock-timeout \
        --publisher-only-lock-timeout \
        --candidate-hash "$candidate_hash"
    [ "$status" -eq 0 ]
    published="$output"
    [ "$(jq -r .publisherOnly <<< "$published")" = "true" ]
    [ "$(jq -r .recordHash <<< "$published")" = "$candidate_hash" ]
    [ -f "$(dirname "$STATE_FILE")/prototypes/quick-lock-timeout.md" ]
    [ ! -e "$(dirname "$STATE_FILE")/prototypes/.quick-lock-timeout.candidate.md" ]
    after="$(shasum -a 256 "$STATE_FILE" | awk '{print $1}')"
    [ "$after" = "$before" ]

    run python3 "$(record_cli)" publish \
        --base-path "$(dirname "$STATE_FILE")" \
        --id quick-lock-timeout \
        --publisher-only-lock-timeout \
        --candidate-hash "$candidate_hash"
    [ "$status" -ne 0 ]
}
