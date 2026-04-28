#!/usr/bin/env bash
# test-write-metric.sh — Unit tests for write_metric function.
# Tests JSONL output validity, flock concurrency, and field completeness.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
METRIC_SCRIPT="$ROOT_DIR/plugins/ralph-specum/hooks/scripts/write-metric.sh"

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

# --- Test 1: Valid JSONL output ---
echo "Test 1: write_metric produces valid JSONL"
tmp=$(mktemp -d)
sf="$tmp/.ralph-state.json"
echo '{}' > "$sf"
source "$METRIC_SCRIPT"
write_metric "$tmp" "pass" 0 1 0 "test task" "implementation" "1.1" "abc123def456"
lines=$(wc -l < "$tmp/.metrics.jsonl")
[ "$lines" -eq 1 ] || { assert_fail "Expected 1 line, got $lines"; }
head -1 "$tmp/.metrics.jsonl" | jq empty 2>/dev/null || { assert_fail "JSON parse failed"; }
head -1 "$tmp/.metrics.jsonl" | jq -e '.schemaVersion and .status and .taskIndex' >/dev/null 2>&1 || { assert_fail "Required fields missing"; }
assert_pass "Valid JSONL with required fields"
rm -rf "$tmp"

# --- Test 2: Flock concurrency ---
echo "Test 2: Concurrent writes produce no corruption"
tmp=$(mktemp -d)
sf="$tmp/.ralph-state.json"
echo '{}' > "$sf"
source "$METRIC_SCRIPT"
for i in 1 2 3; do
  write_metric "$tmp" "pass" "$i" 1 0 "test" "impl" "$i" "abc" &
done
wait
lines=$(wc -l < "$tmp/.metrics.jsonl")
[ "$lines" -eq 3 ] || { assert_fail "Expected 3 lines, got $lines"; }
while IFS= read -r line; do
  echo "$line" | jq empty 2>/dev/null || { assert_fail "Corrupted line: $line"; break; }
done < "$tmp/.metrics.jsonl"
assert_pass "All 3 concurrent lines valid"
rm -rf "$tmp"

# --- Test 3: JSON injection protection ---
echo "Test 3: JSON injection protection via jq --arg"
tmp=$(mktemp -d)
sf="$tmp/.ralph-state.json"
echo '{}' > "$sf"
source "$METRIC_SCRIPT"
write_metric "$tmp" 'pass"; echo "injected"' 0 1 0 "test\"injection" "impl" "1.1" "abc"
head -1 "$tmp/.metrics.jsonl" | jq empty 2>/dev/null || { assert_fail "JSON parse failed on injected input"; }
assert_pass "Injected characters properly escaped"
rm -rf "$tmp"

# --- Summary ---
echo ""
echo "=== write_metric Test Summary ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
[ "$FAIL" -eq 0 ] && echo "ALL_TESTS_PASS" || echo "SOME_TESTS_FAILED"
exit "$FAIL"
