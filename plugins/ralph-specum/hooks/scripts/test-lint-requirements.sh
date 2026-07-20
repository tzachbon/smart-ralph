#!/bin/bash
# Unit tests for lint-requirements.sh
# Run: bash plugins/ralph-specum/hooks/scripts/test-lint-requirements.sh
#
# NOTE: no `set -e` -- assertion helpers must be able to return non-zero without
# aborting the run, so the harness keeps collecting FAIL_COUNT and reaches the
# final summary. External lint calls are already guarded (`|| exit_code=$?`).

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

# Clean fixture but AC-1.2 has no Then clause
write_missing_then_fixture() {
    write_clean_fixture
    sed -E 's/, Then it exits with$/, it exits with/' \
        "$TEST_TMPDIR/requirements.md" > "$TEST_TMPDIR/requirements.md.tmp"
    mv "$TEST_TMPDIR/requirements.md.tmp" "$TEST_TMPDIR/requirements.md"
}

# Clean fixture but AC-1.2 has Given/When/Then spread across continuation lines
write_multiline_ac_fixture() {
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
  - AC-1.2: Given an invalid file path,
    When the lint runs,
    Then it exits with code 2 and prints an error to stderr

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

# Clean fixture but FR-2 has non-MoSCoW priority "High"
write_high_priority_fixture() {
    write_clean_fixture
    sed -E 's/^(\| FR-2 \|.*\|) Should (\| AC-1.2 \|)$/\1 High \2/' \
        "$TEST_TMPDIR/requirements.md" > "$TEST_TMPDIR/requirements.md.tmp"
    mv "$TEST_TMPDIR/requirements.md.tmp" "$TEST_TMPDIR/requirements.md"
}

# Clean fixture plus a Risks table whose Impact column contains "High"
write_risks_table_fixture() {
    write_clean_fixture
    cat >> "$TEST_TMPDIR/requirements.md" << 'EOF'

## Risks

| ID | Risk | Impact | Mitigation |
|----|------|--------|------------|
| R-1 | Lint false positives block authors | High | Heuristic checks are WARN-only |
EOF
}

# Clean fixture but FR-2 requirement text lacks MUST/SHOULD modal
write_missing_modal_fixture() {
    write_clean_fixture
    sed -E 's/^\| FR-2 \| The linter SHOULD exit 2 on unreadable input \|/| FR-2 | The linter exits 2 on unreadable input |/' \
        "$TEST_TMPDIR/requirements.md" > "$TEST_TMPDIR/requirements.md.tmp"
    mv "$TEST_TMPDIR/requirements.md.tmp" "$TEST_TMPDIR/requirements.md"
}

# Clean fixture but AC-1.1 contains banned vague term "gracefully"
write_banned_term_fixture() {
    write_clean_fixture
    sed -E 's/^(  - AC-1.1: Given a well-formed requirements file,) When the lint runs,/\1 When the lint runs gracefully,/' \
        "$TEST_TMPDIR/requirements.md" > "$TEST_TMPDIR/requirements.md.tmp"
    mv "$TEST_TMPDIR/requirements.md.tmp" "$TEST_TMPDIR/requirements.md"
}

# Clean fixture but NFR-1 Metric cell holds an unfilled {{metric}} placeholder
write_nfr_placeholder_fixture() {
    write_clean_fixture
    sed -E 's/^\| NFR-1 \| Lint runtime \| Wall-clock seconds \|.*/| NFR-1 | Lint runtime | {{metric}} | Under 1 second |/' \
        "$TEST_TMPDIR/requirements.md" > "$TEST_TMPDIR/requirements.md.tmp"
    mv "$TEST_TMPDIR/requirements.md.tmp" "$TEST_TMPDIR/requirements.md"
}

# Clean fixture but NFR-1 Target is bare N/A (no ": reason")
write_nfr_bare_na_fixture() {
    write_clean_fixture
    sed -E 's/^\| NFR-1 \| Lint runtime \| Wall-clock seconds \|.*/| NFR-1 | Lint runtime | Wall-clock seconds | N\/A |/' \
        "$TEST_TMPDIR/requirements.md" > "$TEST_TMPDIR/requirements.md.tmp"
    mv "$TEST_TMPDIR/requirements.md.tmp" "$TEST_TMPDIR/requirements.md"
}

# Clean fixture but NFR-1 Target is a reasoned N/A
write_nfr_reasoned_na_fixture() {
    write_clean_fixture
    sed -E 's/^\| NFR-1 \| Lint runtime \| Wall-clock seconds \|.*/| NFR-1 | Lint runtime | Wall-clock seconds | N\/A: markdown-only change |/' \
        "$TEST_TMPDIR/requirements.md" > "$TEST_TMPDIR/requirements.md.tmp"
    mv "$TEST_TMPDIR/requirements.md.tmp" "$TEST_TMPDIR/requirements.md"
}

# Clean fixture but AC-1.2 rewritten happy-path (no failure keywords, no N/A)
write_happy_path_only_fixture() {
    write_clean_fixture
    sed -E -e 's/^(  - AC-1.2:) Given an invalid file path, When the lint runs, Then it exits with$/\1 Given a second well-formed file, When the lint runs, Then it prints/' \
        -e 's/^    code 2 and prints an error to stderr$/    a RESULT line and exits 0/' \
        "$TEST_TMPDIR/requirements.md" > "$TEST_TMPDIR/requirements.md.tmp"
    mv "$TEST_TMPDIR/requirements.md.tmp" "$TEST_TMPDIR/requirements.md"
}

# Happy-path-only fixture plus an explicit N/A scenario line in the story block
write_happy_path_na_fixture() {
    write_happy_path_only_fixture
    awk '{print} /^    a RESULT line and exits 0$/ {print "  - N/A: no error path -- read-only lookup"}' \
        "$TEST_TMPDIR/requirements.md" > "$TEST_TMPDIR/requirements.md.tmp"
    mv "$TEST_TMPDIR/requirements.md.tmp" "$TEST_TMPDIR/requirements.md"
}

# Clean fixture but bare TBD and an ownerless Unresolved Questions bullet
write_unowned_tbd_fixture() {
    write_clean_fixture
    sed -E -e 's/TBD \(Zach, 2026-07-25\)/TBD/' \
        -e 's/^- Should WARN findings block merge\? Owner: Zach$/- Should WARN findings block merge?/' \
        "$TEST_TMPDIR/requirements.md" > "$TEST_TMPDIR/requirements.md.tmp"
    mv "$TEST_TMPDIR/requirements.md.tmp" "$TEST_TMPDIR/requirements.md"
}

# Clean fixture but TBD carries (owner, date) and question bullet keeps Owner:
write_owned_tbd_fixture() {
    write_clean_fixture
    sed -E 's/TBD \(Zach, 2026-07-25\)/TBD (alice, 2026-08-01)/' \
        "$TEST_TMPDIR/requirements.md" > "$TEST_TMPDIR/requirements.md.tmp"
    mv "$TEST_TMPDIR/requirements.md.tmp" "$TEST_TMPDIR/requirements.md"
}

# 10-FR fixture, all Must -> C8 ratio advisory WARN fires (>= 8 FRs)
write_ten_must_fixture() {
    cat > "$TEST_TMPDIR/requirements.md" << 'EOF'
# Requirements: Demo Feature

## Problem Statement

Spec authors cannot lint requirements documents automatically.

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
| FR-2 | The linter MUST exit 2 on unreadable input | Must | AC-1.2 |
| FR-3 | The linter MUST run all eight checks | Must | AC-1.1 |
| FR-4 | The linter MUST report one line per finding | Must | AC-1.2 |
| FR-5 | The linter MUST exit 1 on any FAIL finding | Must | AC-1.1 |
| FR-6 | The linter MUST exit 0 when only WARNs fire | Must | AC-1.2 |
| FR-7 | The linter MUST print a RESULT summary line | Must | AC-1.1 |
| FR-8 | The linter MUST scope C3 to FR rows only | Must | AC-1.2 |
| FR-9 | The linter MUST treat retired rows as valid targets | Must | AC-1.1 |
| FR-10 | The linter MUST never abort mid-run | Must | AC-1.2 |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Lint runtime | Wall-clock seconds | N/A: single-file CLI, runtime negligible |

## Unresolved Questions

- Should WARN findings block merge? Owner: Zach
EOF
}

# 5-FR fixture, all Must -> C8 suppressed below 8 FRs -> CHECK|C8|PASS
write_five_must_fixture() {
    cat > "$TEST_TMPDIR/requirements.md" << 'EOF'
# Requirements: Demo Feature

## Problem Statement

Spec authors cannot lint requirements documents automatically.

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
| FR-2 | The linter MUST exit 2 on unreadable input | Must | AC-1.2 |
| FR-3 | The linter MUST run all eight checks | Must | AC-1.1 |
| FR-4 | The linter MUST report one line per finding | Must | AC-1.2 |
| FR-5 | The linter MUST exit 1 on any FAIL finding | Must | AC-1.1 |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Lint runtime | Wall-clock seconds | N/A: single-file CLI, runtime negligible |

## Unresolved Questions

- Should WARN findings block merge? Owner: Zach
EOF
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

test_c2_missing_then_fails() {
    echo ""
    echo "=== test_c2_missing_then_fails ==="
    setup
    write_missing_then_fixture

    local output exit_code=0
    output=$(bash "$LINT" "$TEST_TMPDIR/requirements.md") || exit_code=$?

    assert_eq 1 "$exit_code" "Missing-Then fixture exits 1"
    assert_contains "$output" 'FAIL|C2|AC-1.2: missing "Then" clause' "Output contains C2 missing-Then FAIL naming AC-1.2"

    cleanup
}

test_c2_multiline_ac_passes() {
    echo ""
    echo "=== test_c2_multiline_ac_passes ==="
    setup
    write_multiline_ac_fixture

    local output exit_code=0
    output=$(bash "$LINT" "$TEST_TMPDIR/requirements.md") || exit_code=$?

    assert_eq 0 "$exit_code" "Multi-line AC fixture exits 0"
    assert_contains "$output" "CHECK|C2|PASS" "Output contains C2 PASS for multi-line AC"

    cleanup
}

test_c3_high_priority_fails() {
    echo ""
    echo "=== test_c3_high_priority_fails ==="
    setup
    write_high_priority_fixture

    local output exit_code=0
    output=$(bash "$LINT" "$TEST_TMPDIR/requirements.md") || exit_code=$?

    assert_eq 1 "$exit_code" "High-priority fixture exits 1"
    assert_contains "$output" 'FAIL|C3|FR-2: Priority "High" is not a MoSCoW value' "Output contains C3 FAIL for FR-2 High priority"

    cleanup
}

test_c3_risks_table_exempt() {
    echo ""
    echo "=== test_c3_risks_table_exempt ==="
    setup
    write_risks_table_fixture

    local output exit_code=0
    output=$(bash "$LINT" "$TEST_TMPDIR/requirements.md") || exit_code=$?

    assert_eq 0 "$exit_code" "Risks-table fixture exits 0"
    assert_not_contains "$output" "FAIL|C3" "Output contains no C3 finding for Risks-table High"
    assert_contains "$output" "CHECK|C3|PASS" "Output contains C3 PASS with Risks table present"

    cleanup
}

test_c4_missing_modal_fails() {
    echo ""
    echo "=== test_c4_missing_modal_fails ==="
    setup
    write_missing_modal_fixture

    local output exit_code=0
    output=$(bash "$LINT" "$TEST_TMPDIR/requirements.md") || exit_code=$?

    assert_eq 1 "$exit_code" "Missing-modal fixture exits 1"
    assert_contains "$output" "FAIL|C4|FR-2: Requirement text lacks MUST/SHOULD modal" "Output contains C4 FAIL for FR-2 missing modal"

    cleanup
}

test_c4_fail_emits_check_status_line() {
    echo ""
    echo "=== test_c4_fail_emits_check_status_line ==="
    setup
    write_missing_modal_fixture

    local output exit_code=0
    output=$(bash "$LINT" "$TEST_TMPDIR/requirements.md") || exit_code=$?

    assert_eq 1 "$exit_code" "Missing-modal fixture exits 1"
    assert_contains "$output" "CHECK|C4|FAIL" "Failed check emits a canonical CHECK|C4|FAIL status line"

    cleanup
}

test_c4_banned_term_warns() {
    echo ""
    echo "=== test_c4_banned_term_warns ==="
    setup
    write_banned_term_fixture

    local output exit_code=0
    output=$(bash "$LINT" "$TEST_TMPDIR/requirements.md") || exit_code=$?

    assert_eq 0 "$exit_code" "Banned-term fixture exits 0 (WARN only)"
    assert_contains "$output" 'WARN|C4|vague term "gracefully"' "Output contains C4 WARN for gracefully"

    cleanup
}

test_c5_placeholder_fails() {
    echo ""
    echo "=== test_c5_placeholder_fails ==="
    setup
    write_nfr_placeholder_fixture

    local output exit_code=0
    output=$(bash "$LINT" "$TEST_TMPDIR/requirements.md") || exit_code=$?

    assert_eq 1 "$exit_code" "Placeholder-metric fixture exits 1"
    assert_contains "$output" "FAIL|C5|NFR-1: Metric contains unfilled placeholder" "Output contains C5 FAIL for {{metric}} placeholder"

    cleanup
}

test_c5_bare_na_fails() {
    echo ""
    echo "=== test_c5_bare_na_fails ==="
    setup
    write_nfr_bare_na_fixture

    local output exit_code=0
    output=$(bash "$LINT" "$TEST_TMPDIR/requirements.md") || exit_code=$?

    assert_eq 1 "$exit_code" "Bare-N/A target fixture exits 1"
    assert_contains "$output" 'FAIL|C5|NFR-1: Target is bare N/A without ": reason"' "Output contains C5 FAIL for bare N/A target"

    cleanup
}

test_c5_reasoned_na_passes() {
    echo ""
    echo "=== test_c5_reasoned_na_passes ==="
    setup
    write_nfr_reasoned_na_fixture

    local output exit_code=0
    output=$(bash "$LINT" "$TEST_TMPDIR/requirements.md") || exit_code=$?

    assert_eq 0 "$exit_code" "Reasoned-N/A fixture exits 0"
    assert_contains "$output" "CHECK|C5|PASS" "Output contains C5 PASS for reasoned N/A"

    cleanup
}

test_c6_happy_path_only_warns() {
    echo ""
    echo "=== test_c6_happy_path_only_warns ==="
    setup
    write_happy_path_only_fixture

    local output exit_code=0
    output=$(bash "$LINT" "$TEST_TMPDIR/requirements.md") || exit_code=$?

    assert_eq 0 "$exit_code" "Happy-path-only fixture exits 0 (WARN only)"
    assert_contains "$output" "WARN|C6|US-1: happy-path-only ACs, no N/A markings" "Output contains C6 WARN for US-1"

    cleanup
}

test_c6_na_marking_passes() {
    echo ""
    echo "=== test_c6_na_marking_passes ==="
    setup
    write_happy_path_na_fixture

    local output exit_code=0
    output=$(bash "$LINT" "$TEST_TMPDIR/requirements.md") || exit_code=$?

    assert_eq 0 "$exit_code" "N/A-marked fixture exits 0"
    assert_not_contains "$output" "WARN|C6" "Output contains no C6 WARN with N/A scenario line"
    assert_contains "$output" "CHECK|C6|PASS" "Output contains C6 PASS with N/A scenario line"

    cleanup
}

test_c7_unowned_tbd_warns() {
    echo ""
    echo "=== test_c7_unowned_tbd_warns ==="
    setup
    write_unowned_tbd_fixture

    local output exit_code=0
    output=$(bash "$LINT" "$TEST_TMPDIR/requirements.md") || exit_code=$?

    assert_eq 0 "$exit_code" "Unowned-TBD fixture exits 0 (WARN only)"
    assert_contains "$output" "WARN|C7|bare TBD without (owner, date)" "Output contains C7 WARN for bare TBD"
    assert_contains "$output" "WARN|C7|unowned question at line" "Output contains C7 WARN for ownerless question"

    local c7_warn_count
    c7_warn_count=$(echo "$output" | grep -cE '^WARN\|C7\|' || true)
    assert_eq 2 "$c7_warn_count" "Output contains exactly 2 WARN|C7 findings"

    cleanup
}

test_c7_owned_tbd_passes() {
    echo ""
    echo "=== test_c7_owned_tbd_passes ==="
    setup
    write_owned_tbd_fixture

    local output exit_code=0
    output=$(bash "$LINT" "$TEST_TMPDIR/requirements.md") || exit_code=$?

    assert_eq 0 "$exit_code" "Owned-TBD fixture exits 0"
    assert_not_contains "$output" "WARN|C7" "Output contains no C7 WARN for owned TBD + owned question"
    assert_contains "$output" "CHECK|C7|PASS" "Output contains C7 PASS for owned TBD + owned question"

    cleanup
}

test_c8_ratio_warn() {
    echo ""
    echo "=== test_c8_ratio_warn ==="
    setup
    write_ten_must_fixture

    local output exit_code=0
    output=$(bash "$LINT" "$TEST_TMPDIR/requirements.md") || exit_code=$?

    assert_eq 0 "$exit_code" "10-FR all-Must fixture exits 0 (WARN only)"
    assert_contains "$output" "WARN|C8|no cut-line signal: 10 of 10 FRs are Must" "Output contains C8 ratio-advisory WARN"

    cleanup
}

test_c8_small_spec_suppressed() {
    echo ""
    echo "=== test_c8_small_spec_suppressed ==="
    setup
    write_five_must_fixture

    local output exit_code=0
    output=$(bash "$LINT" "$TEST_TMPDIR/requirements.md") || exit_code=$?

    assert_eq 0 "$exit_code" "5-FR all-Must fixture exits 0"
    assert_not_contains "$output" "WARN|C8" "Output contains no C8 WARN below 8 FRs"
    assert_contains "$output" "CHECK|C8|PASS" "Output contains C8 PASS (suppressed below 8 FRs)"

    cleanup
}

test_exit2_missing_file() {
    echo ""
    echo "=== test_exit2_missing_file ==="
    setup

    local exit_code=0
    bash "$LINT" "$TEST_TMPDIR/does-not-exist.md" >/dev/null 2>&1 || exit_code=$?

    assert_eq 2 "$exit_code" "Missing file path exits 2"

    cleanup
}

test_exit2_no_argument() {
    echo ""
    echo "=== test_exit2_no_argument ==="

    local exit_code=0
    bash "$LINT" >/dev/null 2>&1 || exit_code=$?

    assert_eq 2 "$exit_code" "No argument exits 2"
}

test_exit0_warn_only_reports_count() {
    echo ""
    echo "=== test_exit0_warn_only_reports_count ==="
    setup
    write_banned_term_fixture

    local output exit_code=0
    output=$(bash "$LINT" "$TEST_TMPDIR/requirements.md") || exit_code=$?

    assert_eq 0 "$exit_code" "WARN-only fixture exits 0"
    assert_contains "$output" "RESULT: PASS (0 FAIL, 1 WARN, 7 PASS)" "RESULT line reports the WARN count"

    cleanup
}

test_exit1_any_fail_reports_fail() {
    echo ""
    echo "=== test_exit1_any_fail_reports_fail ==="
    setup
    write_duplicate_fr_fixture

    local output exit_code=0
    output=$(bash "$LINT" "$TEST_TMPDIR/requirements.md") || exit_code=$?

    assert_eq 1 "$exit_code" "Any-FAIL fixture exits 1"
    assert_contains "$output" "RESULT: FAIL" "RESULT line reports FAIL"

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
test_c2_missing_then_fails
test_c2_multiline_ac_passes
test_c3_high_priority_fails
test_c3_risks_table_exempt
test_c4_missing_modal_fails
test_c4_fail_emits_check_status_line
test_c4_banned_term_warns
test_c5_placeholder_fails
test_c5_bare_na_fails
test_c5_reasoned_na_passes
test_c6_happy_path_only_warns
test_c6_na_marking_passes
test_c7_unowned_tbd_warns
test_c7_owned_tbd_passes
test_c8_ratio_warn
test_c8_small_spec_suppressed
test_exit2_missing_file
test_exit2_no_argument
test_exit0_warn_only_reports_count
test_exit1_any_fail_reports_fail

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
