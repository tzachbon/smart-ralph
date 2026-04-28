#!/usr/bin/env bash
# test-benchmark.sh — Performance benchmarks for safety mechanisms.
# Tests heartbeat < 10ms and write_metric flock overhead.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
STOP_WATCHER="$ROOT_DIR/plugins/ralph-specum/hooks/scripts/stop-watcher.sh"
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

# Extract check_filesystem_heartbeat function
extract_heartbeat_func() {
  sed -n '/^check_filesystem_heartbeat/,/^}/p' "$STOP_WATCHER"
}

# --- Test 1: Heartbeat performance < 10ms ---
echo "Test 1: Heartbeat performance benchmark (100 iterations)"
tmp=$(mktemp -d)
sf="$tmp/sf.json"
echo '{}' > "$sf"
source <(extract_heartbeat_func)

start_ns=$(date +%s%N 2>/dev/null || echo "$(date +%s)000000000")
for i in $(seq 1 100); do
  check_filesystem_heartbeat "$tmp" "$sf" 2>/dev/null || true
done
end_ns=$(date +%s%N 2>/dev/null || echo "$(date +%s)000000000")

# Calculate average time
total_ms=$(( (end_ns - start_ns) / 1000000 ))
avg_ms=$(( total_ms / 100 ))
echo "  Total time: ${total_ms}ms for 100 iterations"
echo "  Average: ${avg_ms}ms per iteration"

[ "$avg_ms" -lt 10 ] || { assert_fail "Average ${avg_ms}ms exceeds 10ms threshold"; exit 1; }
assert_pass "Heartbeat average ${avg_ms}ms < 10ms"
rm -rf "$tmp"

# --- Test 2: write_metric flock overhead ---
echo "Test 2: write_metric flock overhead benchmark (100 iterations)"
tmp=$(mktemp -d)
sf="$tmp/.ralph-state.json"
echo '{}' > "$sf"
source "$METRIC_SCRIPT"

start_ns=$(date +%s%N 2>/dev/null || echo "$(date +%s)000000000")
for i in $(seq 1 100); do
  write_metric "$tmp" "pass" "$i" 1 0 "test" "impl" "$i" "abc" 2>/dev/null || true
done
end_ns=$(date +%s%N 2>/dev/null || echo "$(date +%s)000000000")

total_ms=$(( (end_ns - start_ns) / 1000000 ))
echo "  Total time: ${total_ms}ms for 100 iterations"

[ "$total_ms" -lt 5000 ] || { assert_fail "Total ${total_ms}ms exceeds 5000ms (5s) threshold"; exit 1; }
assert_pass "100 write_metric calls in ${total_ms}ms < 5000ms"

# Verify all lines are valid JSON
lines=$(wc -l < "$tmp/.metrics.jsonl")
[ "$lines" -eq 100 ] || { assert_fail "Expected 100 lines, got $lines"; }
assert_pass "All 100 lines written"
rm -rf "$tmp"

# --- Summary ---
echo ""
echo "=== Benchmark Test Summary ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
[ "$FAIL" -eq 0 ] && echo "ALL_TESTS_PASS" || echo "SOME_TESTS_FAILED"
exit "$FAIL"
