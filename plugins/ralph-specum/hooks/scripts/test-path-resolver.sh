#!/bin/bash
# Unit tests for path-resolver.sh
# Run: bash plugins/ralph-specum/hooks/scripts/test-path-resolver.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
    export RALPH_CWD="$TEST_TMPDIR"
    export RALPH_SETTINGS_FILE="$TEST_TMPDIR/.claude/ralph-specum.local.md"

    # Source the path resolver
    source "$SCRIPT_DIR/path-resolver.sh"
}

# Cleanup test environment
cleanup() {
    if [ -n "$TEST_TMPDIR" ] && [ -d "$TEST_TMPDIR" ]; then
        rm -rf "$TEST_TMPDIR"
    fi
}

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

# Test helper: assert exit code
assert_exit() {
    local expected="$1"
    local actual="$2"
    local msg="$3"

    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}PASS${NC}: $msg"
        PASS_COUNT=$((PASS_COUNT + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC}: $msg"
        echo "  Expected exit: $expected"
        echo "  Actual exit:   $actual"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return 1
    fi
}

# Test helper: assert line count
assert_line_count() {
    local expected="$1"
    local content="$2"
    local msg="$3"

    local actual
    if [ -z "$content" ]; then
        actual=0
    else
        actual=$(echo "$content" | wc -l | tr -d ' ')
    fi

    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}PASS${NC}: $msg"
        PASS_COUNT=$((PASS_COUNT + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC}: $msg"
        echo "  Expected lines: $expected"
        echo "  Actual lines:   $actual"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return 1
    fi
}

# Create settings file with given specs_dirs
create_settings() {
    local dirs_json="$1"
    mkdir -p "$TEST_TMPDIR/.claude"
    cat > "$RALPH_SETTINGS_FILE" << EOF
---
specs_dirs: $dirs_json
---
# Settings
EOF
}

# =============================================================================
# Tests for ralph_get_specs_dirs()
# =============================================================================

test_get_specs_dirs_no_settings() {
    echo ""
    echo "=== test_get_specs_dirs_no_settings ==="
    setup

    # No settings file exists
    local result
    result=$(ralph_get_specs_dirs)

    assert_eq "./specs" "$result" "Returns default ./specs when no settings file"

    cleanup
}

test_get_specs_dirs_empty_array() {
    echo ""
    echo "=== test_get_specs_dirs_empty_array ==="
    setup

    create_settings "[]"

    local result
    result=$(ralph_get_specs_dirs)

    assert_eq "./specs" "$result" "Returns default ./specs when specs_dirs is empty array"

    cleanup
}

test_get_specs_dirs_single_dir() {
    echo ""
    echo "=== test_get_specs_dirs_single_dir ==="
    setup

    mkdir -p "$TEST_TMPDIR/my-specs"
    create_settings '["./my-specs"]'

    local result
    result=$(ralph_get_specs_dirs)

    assert_eq "./my-specs" "$result" "Returns single configured dir"

    cleanup
}

test_get_specs_dirs_multiple_dirs() {
    echo ""
    echo "=== test_get_specs_dirs_multiple_dirs ==="
    setup

    mkdir -p "$TEST_TMPDIR/specs"
    mkdir -p "$TEST_TMPDIR/packages/api/specs"
    mkdir -p "$TEST_TMPDIR/packages/web/specs"
    create_settings '["./specs", "./packages/api/specs", "./packages/web/specs"]'

    local result
    result=$(ralph_get_specs_dirs)

    assert_line_count 3 "$result" "Returns 3 configured dirs"
    assert_contains "$result" "./specs" "Contains ./specs"
    assert_contains "$result" "./packages/api/specs" "Contains ./packages/api/specs"
    assert_contains "$result" "./packages/web/specs" "Contains ./packages/web/specs"

    cleanup
}

test_get_specs_dirs_skips_invalid_paths() {
    echo ""
    echo "=== test_get_specs_dirs_skips_invalid_paths ==="
    setup

    mkdir -p "$TEST_TMPDIR/valid-specs"
    # Don't create invalid-specs directory
    create_settings '["./valid-specs", "./invalid-specs"]'

    local result
    result=$(ralph_get_specs_dirs 2>/dev/null)

    assert_eq "./valid-specs" "$result" "Only returns valid paths"

    cleanup
}

# =============================================================================
# Tests for ralph_get_default_dir()
# =============================================================================

test_get_default_dir_no_settings() {
    echo ""
    echo "=== test_get_default_dir_no_settings ==="
    setup

    local result
    result=$(ralph_get_default_dir)

    assert_eq "./specs" "$result" "Returns ./specs as default when no settings"

    cleanup
}

test_get_default_dir_returns_first() {
    echo ""
    echo "=== test_get_default_dir_returns_first ==="
    setup

    mkdir -p "$TEST_TMPDIR/first-specs"
    mkdir -p "$TEST_TMPDIR/second-specs"
    create_settings '["./first-specs", "./second-specs"]'

    local result
    result=$(ralph_get_default_dir)

    assert_eq "./first-specs" "$result" "Returns first configured dir as default"

    cleanup
}

# =============================================================================
# Tests for ralph_resolve_current()
# =============================================================================

test_resolve_current_bare_name() {
    echo ""
    echo "=== test_resolve_current_bare_name ==="
    setup

    mkdir -p "$TEST_TMPDIR/specs"
    echo "my-feature" > "$TEST_TMPDIR/specs/.current-spec"

    local result
    result=$(ralph_resolve_current)

    assert_eq "./specs/my-feature" "$result" "Resolves bare name to default dir path"

    cleanup
}

test_resolve_current_full_path() {
    echo ""
    echo "=== test_resolve_current_full_path ==="
    setup

    mkdir -p "$TEST_TMPDIR/specs"
    echo "./packages/api/specs/my-api-feature" > "$TEST_TMPDIR/specs/.current-spec"

    local result
    result=$(ralph_resolve_current)

    assert_eq "./packages/api/specs/my-api-feature" "$result" "Preserves full path from .current-spec"

    cleanup
}

test_resolve_current_missing_file() {
    echo ""
    echo "=== test_resolve_current_missing_file ==="
    setup

    mkdir -p "$TEST_TMPDIR/specs"
    # Don't create .current-spec

    local exit_code=0
    ralph_resolve_current >/dev/null 2>&1 || exit_code=$?

    assert_exit 1 "$exit_code" "Returns exit 1 when .current-spec missing"

    cleanup
}

test_resolve_current_empty_file() {
    echo ""
    echo "=== test_resolve_current_empty_file ==="
    setup

    mkdir -p "$TEST_TMPDIR/specs"
    echo "" > "$TEST_TMPDIR/specs/.current-spec"

    local exit_code=0
    ralph_resolve_current >/dev/null 2>&1 || exit_code=$?

    assert_exit 1 "$exit_code" "Returns exit 1 when .current-spec empty"

    cleanup
}

test_resolve_current_with_trailing_slash() {
    echo ""
    echo "=== test_resolve_current_with_trailing_slash ==="
    setup

    mkdir -p "$TEST_TMPDIR/specs"
    echo "./packages/api/specs/my-feature/" > "$TEST_TMPDIR/specs/.current-spec"

    local result
    result=$(ralph_resolve_current)

    assert_eq "./packages/api/specs/my-feature" "$result" "Normalizes trailing slash"

    cleanup
}

# =============================================================================
# Tests for ralph_find_spec()
# =============================================================================

test_find_spec_unique_name() {
    echo ""
    echo "=== test_find_spec_unique_name ==="
    setup

    mkdir -p "$TEST_TMPDIR/specs/my-feature"

    local result
    result=$(ralph_find_spec "my-feature")
    local exit_code=$?

    assert_exit 0 "$exit_code" "Returns exit 0 for unique spec"
    assert_eq "./specs/my-feature" "$result" "Returns correct path for unique spec"

    cleanup
}

test_find_spec_in_non_default_dir() {
    echo ""
    echo "=== test_find_spec_in_non_default_dir ==="
    setup

    mkdir -p "$TEST_TMPDIR/specs"
    mkdir -p "$TEST_TMPDIR/packages/api/specs/api-feature"
    create_settings '["./specs", "./packages/api/specs"]'

    local result
    result=$(ralph_find_spec "api-feature")
    local exit_code=$?

    assert_exit 0 "$exit_code" "Returns exit 0 for spec in non-default dir"
    assert_eq "./packages/api/specs/api-feature" "$result" "Returns correct path in non-default dir"

    cleanup
}

test_find_spec_ambiguous_name() {
    echo ""
    echo "=== test_find_spec_ambiguous_name ==="
    setup

    mkdir -p "$TEST_TMPDIR/specs/shared-feature"
    mkdir -p "$TEST_TMPDIR/packages/api/specs/shared-feature"
    create_settings '["./specs", "./packages/api/specs"]'

    local exit_code=0
    ralph_find_spec "shared-feature" >/dev/null 2>&1 || exit_code=$?

    assert_exit 2 "$exit_code" "Returns exit 2 for ambiguous spec"

    cleanup
}

test_find_spec_not_found() {
    echo ""
    echo "=== test_find_spec_not_found ==="
    setup

    mkdir -p "$TEST_TMPDIR/specs"

    local exit_code=0
    ralph_find_spec "nonexistent" >/dev/null 2>&1 || exit_code=$?

    assert_exit 1 "$exit_code" "Returns exit 1 for nonexistent spec"

    cleanup
}

test_find_spec_empty_name() {
    echo ""
    echo "=== test_find_spec_empty_name ==="
    setup

    local exit_code=0
    ralph_find_spec "" >/dev/null 2>&1 || exit_code=$?

    assert_exit 1 "$exit_code" "Returns exit 1 for empty name"

    cleanup
}

test_find_spec_with_leading_dot_slash() {
    echo ""
    echo "=== test_find_spec_with_leading_dot_slash ==="
    setup

    mkdir -p "$TEST_TMPDIR/specs/my-feature"

    local result
    result=$(ralph_find_spec "./my-feature")
    local exit_code=$?

    assert_exit 0 "$exit_code" "Returns exit 0 when name has leading ./"
    assert_eq "./specs/my-feature" "$result" "Handles leading ./ correctly"

    cleanup
}

# =============================================================================
# Tests for ralph_list_specs()
# =============================================================================

test_list_specs_empty() {
    echo ""
    echo "=== test_list_specs_empty ==="
    setup

    mkdir -p "$TEST_TMPDIR/specs"

    local result
    result=$(ralph_list_specs)

    assert_eq "" "$result" "Returns empty when no specs exist"

    cleanup
}

test_list_specs_single_root() {
    echo ""
    echo "=== test_list_specs_single_root ==="
    setup

    mkdir -p "$TEST_TMPDIR/specs/feature-a"
    mkdir -p "$TEST_TMPDIR/specs/feature-b"

    local result
    result=$(ralph_list_specs)

    assert_line_count 2 "$result" "Returns 2 specs"
    assert_contains "$result" "feature-a|./specs/feature-a" "Contains feature-a"
    assert_contains "$result" "feature-b|./specs/feature-b" "Contains feature-b"

    cleanup
}

test_list_specs_multiple_roots() {
    echo ""
    echo "=== test_list_specs_multiple_roots ==="
    setup

    mkdir -p "$TEST_TMPDIR/specs/main-feature"
    mkdir -p "$TEST_TMPDIR/packages/api/specs/api-feature"
    mkdir -p "$TEST_TMPDIR/packages/web/specs/web-feature"
    create_settings '["./specs", "./packages/api/specs", "./packages/web/specs"]'

    local result
    result=$(ralph_list_specs)

    assert_line_count 3 "$result" "Returns 3 specs from all roots"
    assert_contains "$result" "main-feature|./specs/main-feature" "Contains main-feature"
    assert_contains "$result" "api-feature|./packages/api/specs/api-feature" "Contains api-feature"
    assert_contains "$result" "web-feature|./packages/web/specs/web-feature" "Contains web-feature"

    cleanup
}

test_list_specs_skips_hidden_dirs() {
    echo ""
    echo "=== test_list_specs_skips_hidden_dirs ==="
    setup

    mkdir -p "$TEST_TMPDIR/specs/visible-spec"
    mkdir -p "$TEST_TMPDIR/specs/.hidden-dir"

    local result
    result=$(ralph_list_specs)

    assert_line_count 1 "$result" "Returns only non-hidden specs"
    assert_contains "$result" "visible-spec" "Contains visible-spec"

    cleanup
}

test_list_specs_with_invalid_cwd() {
    echo ""
    echo "=== test_list_specs_with_invalid_cwd ==="
    setup

    export RALPH_CWD="/nonexistent/path"

    local result
    result=$(ralph_list_specs 2>/dev/null)

    assert_eq "" "$result" "Returns empty when RALPH_CWD invalid"

    cleanup
}

# =============================================================================
# Run all tests
# =============================================================================

echo "====================================="
echo "Unit Tests for path-resolver.sh"
echo "====================================="

# ralph_get_specs_dirs tests
test_get_specs_dirs_no_settings
test_get_specs_dirs_empty_array
test_get_specs_dirs_single_dir
test_get_specs_dirs_multiple_dirs
test_get_specs_dirs_skips_invalid_paths

# ralph_get_default_dir tests
test_get_default_dir_no_settings
test_get_default_dir_returns_first

# ralph_resolve_current tests
test_resolve_current_bare_name
test_resolve_current_full_path
test_resolve_current_missing_file
test_resolve_current_empty_file
test_resolve_current_with_trailing_slash

# ralph_find_spec tests
test_find_spec_unique_name
test_find_spec_in_non_default_dir
test_find_spec_ambiguous_name
test_find_spec_not_found
test_find_spec_empty_name
test_find_spec_with_leading_dot_slash

# ralph_list_specs tests
test_list_specs_empty
test_list_specs_single_root
test_list_specs_multiple_roots
test_list_specs_skips_hidden_dirs
test_list_specs_with_invalid_cwd

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
