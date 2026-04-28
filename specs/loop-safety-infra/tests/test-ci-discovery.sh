#!/usr/bin/env bash
# test-ci-discovery.sh — Unit tests for CI command discovery.
# Tests workflow scanning, bats scanning, and empty repo handling.

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

# Extract discover_ci_commands function from stop-watcher.sh
extract_discover_func() {
  sed -n '/^discover_ci_commands/,/^}/p' "$STOP_WATCHER"
}

# --- Test 1: CI discovery with workflow files ---
echo "Test 1: CI discovery from workflow files"
tmp=$(mktemp -d)
mkdir -p "$tmp/.github/workflows"
cat > "$tmp/.github/workflows/ci.yml" <<'EOF'
name: CI
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: bats tests/
      - run: echo lint
EOF
source <(extract_discover_func)
cmds=$(discover_ci_commands "$tmp")
count=$(echo "$cmds" | jq '. | length')
[ "$count" -gt 0 ] || { assert_fail "Expected non-empty command array"; }
echo "$cmds" | jq -e '. | map(test("bats|lint")) | all' >/dev/null 2>&1 || { assert_fail "Expected bats and lint commands"; }
assert_pass "Workflow commands discovered"
rm -rf "$tmp"

# --- Test 2: Empty repo returns empty array ---
echo "Test 2: Empty repo produces empty array"
tmp=$(mktemp -d)
source <(extract_discover_func)
cmds=$(discover_ci_commands "$tmp")
count=$(echo "$cmds" | jq '. | length')
[ "$count" -eq 0 ] || { assert_fail "Expected empty array, got $count items"; }
assert_pass "Empty repo returns empty array"
rm -rf "$tmp"

# --- Test 3: Deduplication ---
echo "Test 3: Duplicate commands are deduplicated"
tmp=$(mktemp -d)
mkdir -p "$tmp/.github/workflows"
cat > "$tmp/.github/workflows/ci.yml" <<'EOF'
name: CI
on: push
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo test
EOF
cat > "$tmp/.github/workflows/test.yml" <<'EOF'
name: Test
on: pull_request
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo test
EOF
source <(extract_discover_func)
cmds=$(discover_ci_commands "$tmp")
count=$(echo "$cmds" | jq '. | length')
[ "$count" -eq 1 ] || { assert_fail "Expected 1 deduplicated command, got $count"; }
assert_pass "Duplicate commands deduplicated"
rm -rf "$tmp"

# --- Summary ---
echo ""
echo "=== CI Discovery Test Summary ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
[ "$FAIL" -eq 0 ] && echo "ALL_TESTS_PASS" || echo "SOME_TESTS_FAILED"
exit "$FAIL"
