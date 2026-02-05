#!/bin/bash
# Integration tests for multi-directory workflow
# Run: bash plugins/ralph-specum/hooks/scripts/test-multi-dir-integration.sh

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

# Simulate spec creation in default dir
create_spec_default() {
    local name="$1"
    local default_dir
    default_dir=$(ralph_get_default_dir)

    # Create spec directory structure
    mkdir -p "$TEST_TMPDIR/$default_dir/$name"
    mkdir -p "$TEST_TMPDIR/$default_dir"

    # Write bare name to .current-spec (default behavior)
    echo "$name" > "$TEST_TMPDIR/$default_dir/.current-spec"
}

# Simulate spec creation with --specs-dir flag (custom dir)
create_spec_custom() {
    local name="$1"
    local specs_dir="$2"

    # Create spec directory structure
    mkdir -p "$TEST_TMPDIR/$specs_dir/$name"
    mkdir -p "$TEST_TMPDIR/$specs_dir"

    # Get default dir to determine .current-spec location and content
    local default_dir
    default_dir=$(ralph_get_default_dir)
    mkdir -p "$TEST_TMPDIR/$default_dir"

    # Write full path to .current-spec for non-default roots
    if [ "$specs_dir" = "$default_dir" ]; then
        # Default dir - write bare name
        echo "$name" > "$TEST_TMPDIR/$default_dir/.current-spec"
    else
        # Non-default dir - write full path
        echo "./$specs_dir/$name" > "$TEST_TMPDIR/$default_dir/.current-spec"
    fi
}

# =============================================================================
# Integration Test 1: Create spec in default dir, verify .current-spec content
# =============================================================================

test_create_spec_default_dir() {
    echo ""
    echo "=== test_create_spec_default_dir ==="
    setup

    # Create default specs directory
    mkdir -p "$TEST_TMPDIR/specs"

    # Simulate creating a spec in default dir
    create_spec_default "my-feature"

    # Verify .current-spec contains bare name
    local content
    content=$(cat "$TEST_TMPDIR/specs/.current-spec")
    assert_eq "my-feature" "$content" "Default dir: .current-spec contains bare name"

    # Verify ralph_resolve_current resolves to full path
    local resolved
    resolved=$(ralph_resolve_current)
    assert_eq "./specs/my-feature" "$resolved" "Default dir: resolved path includes dir prefix"

    cleanup
}

# =============================================================================
# Integration Test 2: Create spec with --specs-dir, verify full path in .current-spec
# =============================================================================

test_create_spec_custom_dir() {
    echo ""
    echo "=== test_create_spec_custom_dir ==="
    setup

    # Setup multi-dir config
    mkdir -p "$TEST_TMPDIR/specs"
    mkdir -p "$TEST_TMPDIR/packages/api/specs"
    create_settings '["./specs", "./packages/api/specs"]'

    # Simulate creating a spec with --specs-dir in non-default location
    create_spec_custom "api-feature" "packages/api/specs"

    # Verify .current-spec contains full path for non-default dir
    local content
    content=$(cat "$TEST_TMPDIR/specs/.current-spec")
    assert_eq "./packages/api/specs/api-feature" "$content" "Custom dir: .current-spec contains full path"

    # Verify ralph_resolve_current returns the full path
    local resolved
    resolved=$(ralph_resolve_current)
    assert_eq "./packages/api/specs/api-feature" "$resolved" "Custom dir: resolved path matches"

    cleanup
}

# =============================================================================
# Integration Test 3: List specs from multiple roots
# =============================================================================

test_list_specs_multiple_roots() {
    echo ""
    echo "=== test_list_specs_multiple_roots ==="
    setup

    # Setup multi-dir config
    mkdir -p "$TEST_TMPDIR/specs/main-feature"
    mkdir -p "$TEST_TMPDIR/packages/api/specs/api-feature"
    mkdir -p "$TEST_TMPDIR/packages/web/specs/web-feature"
    create_settings '["./specs", "./packages/api/specs", "./packages/web/specs"]'

    # List all specs
    local result
    result=$(ralph_list_specs)

    # Verify all specs are listed
    assert_line_count 3 "$result" "Lists 3 specs from all roots"
    assert_contains "$result" "main-feature|./specs/main-feature" "Contains spec from default root"
    assert_contains "$result" "api-feature|./packages/api/specs/api-feature" "Contains spec from api root"
    assert_contains "$result" "web-feature|./packages/web/specs/web-feature" "Contains spec from web root"

    cleanup
}

# =============================================================================
# Integration Test 4: Switch between specs in different roots
# =============================================================================

test_switch_between_specs_different_roots() {
    echo ""
    echo "=== test_switch_between_specs_different_roots ==="
    setup

    # Setup multi-dir config
    mkdir -p "$TEST_TMPDIR/specs/main-feature"
    mkdir -p "$TEST_TMPDIR/packages/api/specs/api-feature"
    create_settings '["./specs", "./packages/api/specs"]'

    # Start with main-feature in default dir
    echo "main-feature" > "$TEST_TMPDIR/specs/.current-spec"

    # Verify current spec is main-feature
    local resolved
    resolved=$(ralph_resolve_current)
    assert_eq "./specs/main-feature" "$resolved" "Initial spec is main-feature"

    # Simulate switching to api-feature (ralph_find_spec finds it)
    local found_path
    found_path=$(ralph_find_spec "api-feature")
    assert_eq "./packages/api/specs/api-feature" "$found_path" "Found api-feature path"

    # Write full path to .current-spec (simulate switch)
    echo "$found_path" > "$TEST_TMPDIR/specs/.current-spec"

    # Verify new current spec is api-feature
    resolved=$(ralph_resolve_current)
    assert_eq "./packages/api/specs/api-feature" "$resolved" "Switched to api-feature"

    # Simulate switching back to main-feature
    found_path=$(ralph_find_spec "main-feature")
    assert_eq "./specs/main-feature" "$found_path" "Found main-feature path"

    # Write back bare name for default dir
    echo "main-feature" > "$TEST_TMPDIR/specs/.current-spec"

    resolved=$(ralph_resolve_current)
    assert_eq "./specs/main-feature" "$resolved" "Switched back to main-feature"

    cleanup
}

# =============================================================================
# Integration Test 5: Backward compat - bare name .current-spec resolves to ./specs/
# =============================================================================

test_backward_compat_bare_name() {
    echo ""
    echo "=== test_backward_compat_bare_name ==="
    setup

    # Create default specs directory with existing bare-name .current-spec
    mkdir -p "$TEST_TMPDIR/specs/legacy-feature"
    echo "legacy-feature" > "$TEST_TMPDIR/specs/.current-spec"

    # No settings file (old behavior - no custom config)

    # Verify bare name resolves to ./specs/name
    local resolved
    resolved=$(ralph_resolve_current)
    assert_eq "./specs/legacy-feature" "$resolved" "Bare name resolves to ./specs/ prefix"

    # Verify ralph_find_spec finds it
    local found
    found=$(ralph_find_spec "legacy-feature")
    local exit_code=$?
    assert_exit 0 "$exit_code" "Find returns exit 0 for legacy spec"
    assert_eq "./specs/legacy-feature" "$found" "Found legacy spec in default dir"

    cleanup
}

# =============================================================================
# Integration Test 6: Backward compat - no settings file defaults to ./specs/
# =============================================================================

test_backward_compat_no_settings() {
    echo ""
    echo "=== test_backward_compat_no_settings ==="
    setup

    # Create default specs directory, no settings file
    mkdir -p "$TEST_TMPDIR/specs/feature-a"
    mkdir -p "$TEST_TMPDIR/specs/feature-b"

    # Verify default dir is ./specs
    local default_dir
    default_dir=$(ralph_get_default_dir)
    assert_eq "./specs" "$default_dir" "No settings: default dir is ./specs"

    # Verify specs_dirs returns default
    local dirs
    dirs=$(ralph_get_specs_dirs)
    assert_eq "./specs" "$dirs" "No settings: specs_dirs returns ./specs"

    # Verify listing works
    local list
    list=$(ralph_list_specs)
    assert_line_count 2 "$list" "No settings: lists 2 specs"
    assert_contains "$list" "feature-a|./specs/feature-a" "No settings: contains feature-a"
    assert_contains "$list" "feature-b|./specs/feature-b" "No settings: contains feature-b"

    cleanup
}

# =============================================================================
# Integration Test 7: Disambiguation - same spec name in multiple roots
# =============================================================================

test_disambiguation_same_name() {
    echo ""
    echo "=== test_disambiguation_same_name ==="
    setup

    # Setup multi-dir with same spec name in two locations
    mkdir -p "$TEST_TMPDIR/specs/shared-feature"
    mkdir -p "$TEST_TMPDIR/packages/api/specs/shared-feature"
    create_settings '["./specs", "./packages/api/specs"]'

    # Verify ralph_find_spec returns exit 2 for ambiguous
    local exit_code=0
    ralph_find_spec "shared-feature" >/dev/null 2>&1 || exit_code=$?
    assert_exit 2 "$exit_code" "Disambiguation: returns exit 2 for ambiguous spec"

    # Verify listing shows both
    local list
    list=$(ralph_list_specs)
    assert_contains "$list" "shared-feature|./specs/shared-feature" "Disambiguation: lists spec from default root"
    assert_contains "$list" "shared-feature|./packages/api/specs/shared-feature" "Disambiguation: lists spec from api root"

    cleanup
}

# =============================================================================
# Integration Test 8: Full path switch bypasses disambiguation
# =============================================================================

test_full_path_switch() {
    echo ""
    echo "=== test_full_path_switch ==="
    setup

    # Setup multi-dir with same spec name in two locations
    mkdir -p "$TEST_TMPDIR/specs/shared-feature"
    mkdir -p "$TEST_TMPDIR/packages/api/specs/shared-feature"
    create_settings '["./specs", "./packages/api/specs"]'

    # Write full path directly to .current-spec (bypass disambiguation)
    echo "./packages/api/specs/shared-feature" > "$TEST_TMPDIR/specs/.current-spec"

    # Verify resolved path is the full path
    local resolved
    resolved=$(ralph_resolve_current)
    assert_eq "./packages/api/specs/shared-feature" "$resolved" "Full path switch: correct resolution"

    cleanup
}

# =============================================================================
# Integration Test 9: Workflow - create in default, create in custom, list all
# =============================================================================

test_complete_workflow() {
    echo ""
    echo "=== test_complete_workflow ==="
    setup

    # Setup multi-dir config
    mkdir -p "$TEST_TMPDIR/specs"
    mkdir -p "$TEST_TMPDIR/packages/api/specs"
    create_settings '["./specs", "./packages/api/specs"]'

    # Step 1: Create spec in default dir
    create_spec_default "first-feature"

    local resolved
    resolved=$(ralph_resolve_current)
    assert_eq "./specs/first-feature" "$resolved" "Workflow: created first-feature in default"

    # Step 2: Create spec in custom dir (simulates --specs-dir)
    create_spec_custom "api-feature" "packages/api/specs"

    resolved=$(ralph_resolve_current)
    assert_eq "./packages/api/specs/api-feature" "$resolved" "Workflow: created api-feature in custom"

    # Step 3: Create another spec in default
    create_spec_default "second-feature"

    resolved=$(ralph_resolve_current)
    assert_eq "./specs/second-feature" "$resolved" "Workflow: created second-feature in default"

    # Step 4: List all specs
    local list
    list=$(ralph_list_specs)
    assert_line_count 3 "$list" "Workflow: lists all 3 specs"
    assert_contains "$list" "first-feature|./specs/first-feature" "Workflow: contains first-feature"
    assert_contains "$list" "api-feature|./packages/api/specs/api-feature" "Workflow: contains api-feature"
    assert_contains "$list" "second-feature|./specs/second-feature" "Workflow: contains second-feature"

    cleanup
}

# =============================================================================
# Integration Test 10: Paths with trailing slashes normalized
# =============================================================================

test_trailing_slash_normalization() {
    echo ""
    echo "=== test_trailing_slash_normalization ==="
    setup

    # Create spec directory
    mkdir -p "$TEST_TMPDIR/specs/my-feature"

    # Write path with trailing slash
    echo "./specs/my-feature/" > "$TEST_TMPDIR/specs/.current-spec"

    # Verify trailing slash is normalized
    local resolved
    resolved=$(ralph_resolve_current)
    assert_eq "./specs/my-feature" "$resolved" "Trailing slash normalized"

    cleanup
}

# =============================================================================
# Integration Test 11: Backward compat - all functions work without config
# =============================================================================

test_all_functions_work_without_config() {
    echo ""
    echo "=== test_all_functions_work_without_config ==="
    setup

    # Create default specs directory, NO settings file at all
    mkdir -p "$TEST_TMPDIR/specs/feature-x"
    mkdir -p "$TEST_TMPDIR/specs/feature-y"
    echo "feature-x" > "$TEST_TMPDIR/specs/.current-spec"

    # Ensure no settings file exists
    rm -f "$RALPH_SETTINGS_FILE"
    rmdir "$TEST_TMPDIR/.claude" 2>/dev/null || true

    # Test ralph_get_specs_dirs works without config
    local dirs
    dirs=$(ralph_get_specs_dirs)
    assert_eq "./specs" "$dirs" "No config: ralph_get_specs_dirs returns ./specs"

    # Test ralph_get_default_dir works without config
    local default_dir
    default_dir=$(ralph_get_default_dir)
    assert_eq "./specs" "$default_dir" "No config: ralph_get_default_dir returns ./specs"

    # Test ralph_resolve_current works without config
    local resolved
    resolved=$(ralph_resolve_current)
    assert_eq "./specs/feature-x" "$resolved" "No config: ralph_resolve_current works"

    # Test ralph_find_spec works without config
    local found
    found=$(ralph_find_spec "feature-y")
    local exit_code=$?
    assert_exit 0 "$exit_code" "No config: ralph_find_spec finds spec"
    assert_eq "./specs/feature-y" "$found" "No config: ralph_find_spec returns correct path"

    # Test ralph_list_specs works without config
    local list
    list=$(ralph_list_specs)
    assert_line_count 2 "$list" "No config: ralph_list_specs lists both specs"
    assert_contains "$list" "feature-x|./specs/feature-x" "No config: list contains feature-x"
    assert_contains "$list" "feature-y|./specs/feature-y" "No config: list contains feature-y"

    cleanup
}

# =============================================================================
# Integration Test 12: Backward compat - no warnings for users without config
# =============================================================================

test_no_warnings_without_config() {
    echo ""
    echo "=== test_no_warnings_without_config ==="
    setup

    # Create default specs directory, NO settings file
    mkdir -p "$TEST_TMPDIR/specs/my-spec"
    echo "my-spec" > "$TEST_TMPDIR/specs/.current-spec"

    # Ensure no settings file exists
    rm -f "$RALPH_SETTINGS_FILE"
    rmdir "$TEST_TMPDIR/.claude" 2>/dev/null || true

    # Capture stderr for all functions to ensure no warnings
    local stderr_output
    local result

    # Test ralph_get_specs_dirs - no warnings
    stderr_output=$(ralph_get_specs_dirs 2>&1 >/dev/null)
    if [ -z "$stderr_output" ]; then
        echo -e "${GREEN}PASS${NC}: No config: ralph_get_specs_dirs produces no warnings"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo -e "${RED}FAIL${NC}: No config: ralph_get_specs_dirs produced warning: $stderr_output"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    # Test ralph_get_default_dir - no warnings
    stderr_output=$(ralph_get_default_dir 2>&1 >/dev/null)
    if [ -z "$stderr_output" ]; then
        echo -e "${GREEN}PASS${NC}: No config: ralph_get_default_dir produces no warnings"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo -e "${RED}FAIL${NC}: No config: ralph_get_default_dir produced warning: $stderr_output"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    # Test ralph_resolve_current - no warnings
    stderr_output=$(ralph_resolve_current 2>&1 >/dev/null)
    if [ -z "$stderr_output" ]; then
        echo -e "${GREEN}PASS${NC}: No config: ralph_resolve_current produces no warnings"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo -e "${RED}FAIL${NC}: No config: ralph_resolve_current produced warning: $stderr_output"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    # Test ralph_find_spec - no warnings
    stderr_output=$(ralph_find_spec "my-spec" 2>&1 >/dev/null)
    if [ -z "$stderr_output" ]; then
        echo -e "${GREEN}PASS${NC}: No config: ralph_find_spec produces no warnings"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo -e "${RED}FAIL${NC}: No config: ralph_find_spec produced warning: $stderr_output"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    # Test ralph_list_specs - no warnings
    stderr_output=$(ralph_list_specs 2>&1 >/dev/null)
    if [ -z "$stderr_output" ]; then
        echo -e "${GREEN}PASS${NC}: No config: ralph_list_specs produces no warnings"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo -e "${RED}FAIL${NC}: No config: ralph_list_specs produced warning: $stderr_output"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    cleanup
}

# =============================================================================
# Integration Test 13: Backward compat - empty settings file same as no settings
# =============================================================================

test_empty_settings_file() {
    echo ""
    echo "=== test_empty_settings_file ==="
    setup

    # Create default specs directory
    mkdir -p "$TEST_TMPDIR/specs/test-feature"
    echo "test-feature" > "$TEST_TMPDIR/specs/.current-spec"

    # Create empty settings file (no specs_dirs defined)
    mkdir -p "$TEST_TMPDIR/.claude"
    cat > "$RALPH_SETTINGS_FILE" << 'EOF'
---
# Empty settings - no specs_dirs
---
EOF

    # Verify defaults to ./specs like no file at all
    local default_dir
    default_dir=$(ralph_get_default_dir)
    assert_eq "./specs" "$default_dir" "Empty settings: defaults to ./specs"

    local dirs
    dirs=$(ralph_get_specs_dirs)
    assert_eq "./specs" "$dirs" "Empty settings: specs_dirs returns ./specs"

    local resolved
    resolved=$(ralph_resolve_current)
    assert_eq "./specs/test-feature" "$resolved" "Empty settings: resolve works"

    cleanup
}

# =============================================================================
# Integration Test 14: Backward compat - settings with other keys, no specs_dirs
# =============================================================================

test_settings_without_specs_dirs() {
    echo ""
    echo "=== test_settings_without_specs_dirs ==="
    setup

    # Create default specs directory
    mkdir -p "$TEST_TMPDIR/specs/another-feature"
    echo "another-feature" > "$TEST_TMPDIR/specs/.current-spec"

    # Create settings file with other keys but no specs_dirs
    mkdir -p "$TEST_TMPDIR/.claude"
    cat > "$RALPH_SETTINGS_FILE" << 'EOF'
---
some_other_setting: true
another_key: "value"
---
# Settings without specs_dirs
EOF

    # Verify defaults to ./specs
    local default_dir
    default_dir=$(ralph_get_default_dir)
    assert_eq "./specs" "$default_dir" "Settings without specs_dirs: defaults to ./specs"

    local resolved
    resolved=$(ralph_resolve_current)
    assert_eq "./specs/another-feature" "$resolved" "Settings without specs_dirs: resolve works"

    cleanup
}

# =============================================================================
# Run all tests
# =============================================================================

echo "====================================="
echo "Integration Tests for Multi-Dir Workflow"
echo "====================================="

# Test 1: Create spec in default dir
test_create_spec_default_dir

# Test 2: Create spec with --specs-dir
test_create_spec_custom_dir

# Test 3: List specs from multiple roots
test_list_specs_multiple_roots

# Test 4: Switch between specs in different roots
test_switch_between_specs_different_roots

# Test 5: Backward compat - bare name resolves to ./specs/
test_backward_compat_bare_name

# Test 6: Backward compat - no settings defaults to ./specs/
test_backward_compat_no_settings

# Test 7: Disambiguation - same spec name in multiple roots
test_disambiguation_same_name

# Test 8: Full path switch bypasses disambiguation
test_full_path_switch

# Test 9: Complete workflow
test_complete_workflow

# Test 10: Trailing slash normalization
test_trailing_slash_normalization

# Test 11: Backward compat - all functions work without config
test_all_functions_work_without_config

# Test 12: Backward compat - no warnings for users without config
test_no_warnings_without_config

# Test 13: Backward compat - empty settings file
test_empty_settings_file

# Test 14: Backward compat - settings without specs_dirs key
test_settings_without_specs_dirs

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

echo "All integration tests passed!"
exit 0
