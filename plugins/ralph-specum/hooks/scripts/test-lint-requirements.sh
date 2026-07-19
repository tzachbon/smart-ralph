#!/bin/bash
# Unit tests for lint-requirements.sh
# Run: bash plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINT="$SCRIPT_DIR/lint-requirements.sh"
TEST_TMPDIR=""
PASS_COUNT=0
FAIL_COUNT=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Setup test environment
setup() {
    TEST_TMPDIR=$(mktemp -d)
}

# Cleanup test environment
cleanup() {
    if [ -n "$TEST_TMPDIR" ] && [ -d "$TEST_TMPDIR" ]; then
        rm -rf "$TEST_TMPDIR"
    fi
}

trap cleanup EXIT

# Test helper: assert equals
assert_eq() {
    local expected="$1"
    local actual="$2"
    local msg="$3"

    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}PASS${NC}: $msg"
        PASS_COUNT=$((PASS_COUNT + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC}: $msg"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return 1
    fi
}

# Test helper: assert contains
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local msg="$3"

    if echo "$haystack" | grep -q "$needle"; then
        echo -e "${GREEN}PASS${NC}: $msg"
        PASS_COUNT=$((PASS_COUNT + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC}: $msg"
        echo "  Expected to contain: '$needle'"
        echo "  Actual: '$haystack'"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return 1
    fi
}

# Test helper: assert does not contain
assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local msg="$3"

    if echo "$haystack" | grep -q "$needle"; then
        echo -e "${RED}FAIL${NC}: $msg"
        echo "  Expected NOT to contain: '$needle'"
        echo "  Actual: '$haystack'"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return 1
    else
        echo -e "${GREEN}PASS${NC}: $msg"
        PASS_COUNT=$((PASS_COUNT + 1))
        return 0
    fi
}

# =============================================================================
# Fixtures
# =============================================================================

# Template-conformant mini requirements doc: passes all 8 checks
write_clean_fixture() {
    cat > "$TEST_TMPDIR/requirements.md" << 'EOF'
# Requirements: Demo Feature

## Problem Statement

Spec authors cannot lint requirements documents automatically. Exact report
format is TBD (Zach, 2026-07-25).

## User Stories

### US-1: Lint a requirements document

As a spec author, I want automated lint checks, so that structural defects are
caught before review.

**Acceptance Criteria**:
  - AC-1.1: Given a well-formed requirements file, When the lint runs, Then it
    prints a summary line and exits 0
  - AC-1.2: Given an invalid file path, When the lint runs, Then it exits with
    code 2 and prints an error to stderr

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | The linter MUST print a summary line on every run | Must | AC-1.1 |
| FR-2 | The linter SHOULD exit 2 on unreadable input | Should | AC-1.2 |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Lint runtime | Wall-clock seconds | N/A: single-file CLI, runtime negligible |

## Unresolved Questions

- Should WARN findings block merge? Owner: Zach
EOF
}

# Clean fixture but with FR-1 defined twice in the FR table
write_duplicate_fr_fixture() {
    write_clean_fixture
    sed -E 's/^\| FR-2 \|.*/| FR-1 | The linter MUST exit 2 on unreadable input | Must | AC-1.2 |/' \
        "$TEST_TMPDIR/requirements.md" > "$TEST_TMPDIR/requirements.md.tmp"
    mv "$TEST_TMPDIR/requirements.md.tmp" "$TEST_TMPDIR/requirements.md"
}

# Clean fixture but FR-2 references undefined AC-9.9
write_dangling_ac_ref_fixture() {
    write_clean_fixture
    sed -E 's/^(\| FR-2 \|.*\| Should \|) AC-1.2 \|$/\1 AC-9.9 |/' \
        "$TEST_TMPDIR/requirements.md" > "$TEST_TMPDIR/requirements.md.tmp"
    mv "$TEST_TMPDIR/requirements.md.tmp" "$TEST_TMPDIR/requirements.md"
}

# Clean fixture but FR-2 is retired (empty AC column) and referenced elsewhere
write_retired_fr_fixture() {
    write_clean_fixture
    sed -E -e 's/^\| FR-2 \|.*/| FR-2 (retired) | Superseded by FR-1 | Should | |/' \
        -e 's/^- Should WARN findings block merge\?/- Should FR-2 behavior return? See FR-2./' \
        "$TEST_TMPDIR/requirements.md" > "$TEST_TMPDIR/requirements.md.tmp"
    mv "$TEST_TMPDIR/requirements.md.tmp" "$TEST_TMPDIR/requirements.md"
}

# =============================================================================
# Tests
# =============================================================================

test_clean_fixture_all_checks_pass() {
    echo ""
    echo "=== test_clean_fixture_all_checks_pass ==="
    setup
    write_clean_fixture

    local output exit_code=0
    output=$(bash "$LINT" "$TEST_TMPDIR/requirements.md") || exit_code=$?

    assert_eq 0 "$exit_code" "Clean fixture exits 0"

    local check_pass_count
    check_pass_count=$(echo "$output" | grep -cE '^CHECK\|C[1-8]\|PASS$' || true)
    assert_eq 8 "$check_pass_count" "Output contains 8 CHECK|Cn|PASS lines"

    assert_contains "$output" "RESULT: PASS" "Output contains RESULT: PASS"

    cleanup
}

test_c1_duplicate_fr_id_fails() {
    echo ""
    echo "=== test_c1_duplicate_fr_id_fails ==="
    setup
    write_duplicate_fr_fixture

    local output exit_code=0
    output=$(bash "$LINT" "$TEST_TMPDIR/requirements.md") || exit_code=$?

    assert_eq 1 "$exit_code" "Duplicate FR-1 fixture exits 1"
    assert_contains "$output" "FAIL|C1|duplicate ID defined: FR-1" "Output contains C1 duplicate-ID FAIL for FR-1"

    cleanup
}

test_c1_dangling_ac_ref_fails() {
    echo ""
    echo "=== test_c1_dangling_ac_ref_fails ==="
    setup
    write_dangling_ac_ref_fixture

    local output exit_code=0
    output=$(bash "$LINT" "$TEST_TMPDIR/requirements.md") || exit_code=$?

    assert_eq 1 "$exit_code" "Dangling AC-9.9 ref fixture exits 1"
    assert_contains "$output" "FAIL|C1|FR-2 references undefined AC-9.9" "Output contains C1 dangling-ref FAIL for AC-9.9"

    cleanup
}

test_c1_retired_fr_is_valid_target() {
    echo ""
    echo "=== test_c1_retired_fr_is_valid_target ==="
    setup
    write_retired_fr_fixture

    local output exit_code=0
    output=$(bash "$LINT" "$TEST_TMPDIR/requirements.md") || exit_code=$?

    assert_eq 0 "$exit_code" "Retired FR-2 fixture exits 0"
    assert_not_contains "$output" "FAIL|C1" "Output contains no C1 FAIL for retired FR-2"

    cleanup
}

# =============================================================================
# Run all tests
# =============================================================================

echo "====================================="
echo "Unit Tests for lint-requirements.sh"
echo "====================================="

test_clean_fixture_all_checks_pass
test_c1_duplicate_fr_id_fails
test_c1_dangling_ac_ref_fails
test_c1_retired_fr_is_valid_target

# Summary
echo ""
echo "====================================="
echo "Test Summary"
echo "====================================="
echo -e "${GREEN}PASSED${NC}: $PASS_COUNT"
echo -e "${RED}FAILED${NC}: $FAIL_COUNT"
echo "====================================="

if [ $FAIL_COUNT -gt 0 ]; then
    exit 1
fi

echo "All tests passed!"
exit 0
