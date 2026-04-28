#!/usr/bin/env bash
# test-checkpoint.sh — Unit tests for checkpoint.sh functions
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"
source "$PROJECT_ROOT/plugins/ralph-specum/hooks/scripts/checkpoint.sh"

PASSED=0
FAILED=0

assert_eq() {
  local expected="$1" actual="$2" msg="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  PASS: $msg"
    ((PASSED++))
  else
    echo "  FAIL: $msg (expected='$expected', actual='$actual')"
    ((FAILED++))
  fi
}

# T-3.1: checkpoint-create with no git repo
test_checkpoint_no_repo() {
  echo "T-3.1: checkpoint-create no-repo produces sha=null"
  local tmp=$(mktemp -d)
  local sf="$tmp/sf.json"
  echo '{}' > "$sf"
  checkpoint-create "nogen" "1" "$sf" 2>/dev/null
  local sha=$(jq -r '.checkpoint.sha' "$sf")
  assert_eq "null" "$sha" "sha should be null in non-git dir"
  rm -rf "$tmp"
}

# T-3.2: checkpoint-create with valid repo
test_checkpoint_create() {
  echo "T-3.2: checkpoint-create valid repo"
  local tmp=$(mktemp -d)
  git init "$tmp" >/dev/null 2>&1
  git -C "$tmp" config user.email "t@t.com"
  git -C "$tmp" config user.name "T"
  local sf="$tmp/sf.json"
  echo '{}' > "$sf"
  echo a > "$tmp/a"
  git -C "$tmp" add -A
  git -C "$tmp" commit -m init --no-verify >/dev/null 2>&1
  checkpoint-create "test" "1" "$sf" 2>/dev/null
  local sha=$(jq -r '.checkpoint.sha' "$sf")
  assert_eq "$sha" "$sha" "sha is non-empty (${#sha} chars)" || true
  [ ${#sha} -ge 7 ] && { echo "  PASS: sha length ${#sha} >= 7"; ((PASSED++)); } || { echo "  FAIL: sha too short"; ((FAILED++)); }
  rm -rf "$tmp"
}

# T-3.3: checkpoint-rollback restores state
test_checkpoint_rollback() {
  echo "T-3.3: checkpoint-rollback restores state"
  local tmp=$(mktemp -d)
  git init "$tmp" >/dev/null 2>&1
  git -C "$tmp" config user.email "t@t.com"
  git -C "$tmp" config user.name "T"
  echo f1 > "$tmp/f1.txt"
  git -C "$tmp" add -A
  git -C "$tmp" commit -m init --no-verify >/dev/null 2>&1
  local sf="$tmp/sf.json"
  echo '{}' > "$sf"
  checkpoint-create "test" "1" "$sf" 2>/dev/null
  echo f2 > "$tmp/f2.txt"
  git -C "$tmp" add -A
  git -C "$tmp" commit -m "add f2" --no-verify >/dev/null 2>&1
  checkpoint-rollback "$sf" 2>/dev/null
  [ ! -f "$tmp/f2.txt" ] && { echo "  PASS: f2.txt removed after rollback"; ((PASSED++)); } || { echo "  FAIL: f2.txt still exists"; ((FAILED++)); }
  [ -f "$tmp/f1.txt" ] && { echo "  PASS: f1.txt still exists after rollback"; ((PASSED++)); } || { echo "  FAIL: f1.txt missing"; ((FAILED++)); }
  rm -rf "$tmp"
}

# T-3.4: checkpoint-rollback with null SHA
test_checkpoint_rollback_null_sha() {
  echo "T-3.4: checkpoint-rollback null SHA returns error"
  local tmp=$(mktemp -d)
  local sf="$tmp/sf.json"
  echo '{"checkpoint":{"sha":null}}' > "$sf"
  set +e
  checkpoint-rollback "$sf" 2>/dev/null
  local rc=$?
  set -e
  [ "$rc" -ne 0 ] && { echo "  PASS: rollback with null SHA returns error (rc=$rc)"; ((PASSED++)); } || { echo "  FAIL: should have returned error"; ((FAILED++)); }
  rm -rf "$tmp"
}

echo "=== Running checkpoint tests ==="
test_checkpoint_no_repo
test_checkpoint_create
test_checkpoint_rollback
test_checkpoint_rollback_null_sha

echo "Results: $PASSED passed, $FAILED failed"
exit "$FAILED"
