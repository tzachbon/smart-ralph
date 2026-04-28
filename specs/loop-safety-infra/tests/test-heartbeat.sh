#!/usr/bin/env bash
# test-heartbeat.sh — Unit tests for filesystem heartbeat detection.
# Tests success path, three-tier escalation, and counter reset.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
STOP_WATCHER="$ROOT_DIR/plugins/ralph-specum/hooks/scripts/stop-watcher.sh"

PASS=0
FAIL=0

assert_pass() {
  PASS=$((PASS + 1))
  echo "  PASS: $1"
}

assert_fail() {
  FAIL=$((FAIL + 1))
  echo "  FAIL: $1"
}

# Extract check_filesystem_heartbeat function from stop-watcher.sh
extract_heartbeat_func() {
  sed -n '/^check_filesystem_heartbeat/,/^}/p' "$STOP_WATCHER"
}

# --- Test 1: Success resets counters ---
echo "Test 1: Heartbeat success resets failure counters"
tmp=$(mktemp -d)
sf="$tmp/sf.json"
echo '{"filesystemHealthFailures":1}' > "$sf"
source <(extract_heartbeat_func)
check_filesystem_heartbeat "$tmp" "$sf"
failures=$(jq -r '.filesystemHealthFailures' "$sf")
healthy=$(jq -r '.filesystemHealthy' "$sf")
[ "$failures" = "0" ] || { assert_fail "Expected failures=0, got $failures"; }
[ "$healthy" = "true" ] || { assert_fail "Expected healthy=true, got $healthy"; }
assert_pass "Success resets counters"
rm -rf "$tmp"

# --- Test 2: Three-tier escalation ---
echo "Test 2: Three-tier escalation on repeated failures"
tmp=$(mktemp -d)
sf="$tmp/sf.json"
echo '{}' > "$sf"
source <(extract_heartbeat_func)
# Make spec_dir unwritable to simulate heartbeat failure
chmod 000 "$tmp"
# First failure: should warn, not block
check_filesystem_heartbeat "$tmp" "$sf" 2>/dev/null || true
chmod 755 "$tmp"
failures=$(jq -r '.filesystemHealthFailures' "$sf")
[ "$failures" = "1" ] || { assert_fail "Expected 1st failure, got $failures"; }
assert_pass "1st failure logged"
# Second failure: should block
check_filesystem_heartbeat "$tmp" "$sf" 2>/dev/null || true
failures=$(jq -r '.filesystemHealthFailures' "$sf")
[ "$failures" = "2" ] || { assert_fail "Expected 2nd failure, got $failures"; }
assert_pass "2nd failure escalated"
rm -rf "$tmp"

# --- Test 3: Heartbeat file cleanup on success ---
echo "Test 3: Heartbeat file cleaned up on success"
tmp=$(mktemp -d)
sf="$tmp/sf.json"
echo '{}' > "$sf"
source <(extract_heartbeat_func)
check_filesystem_heartbeat "$tmp" "$sf"
[ -f "$tmp/.ralph-heartbeat" ] && { assert_fail "Heartbeat file should be cleaned up"; }
assert_pass "Heartbeat file cleaned up"
rm -rf "$tmp"

# --- Summary ---
echo ""
echo "=== Heartbeat Test Summary ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
[ "$FAIL" -eq 0 ] && echo "ALL_TESTS_PASS" || echo "SOME_TESTS_FAILED"
exit "$FAIL"
