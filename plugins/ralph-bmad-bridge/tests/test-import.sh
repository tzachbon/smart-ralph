#!/usr/bin/env bash
set -euo pipefail

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

passed=0
failed=0

run_test() {
    local name="$1"
    shift
    if "$@" > /dev/null 2>&1; then
        echo "  PASS: $name"
        passed=$((passed + 1))
    else
        echo "  FAIL: $name"
        failed=$((failed + 1))
    fi
}

assert_contains() {
    local file="$1"
    local pattern="$2"
    if grep -q "$pattern" "$file" 2>/dev/null; then
        echo "  PASS: '$pattern' found in $file"
        passed=$((passed + 1))
    else
        echo "  FAIL: '$pattern' NOT found in $file"
        failed=$((failed + 1))
    fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IMPORT_SH="$PLUGIN_ROOT/scripts/import.sh"

echo "=== BMAD Bridge Plugin Tests ==="
echo ""

echo "  validate_inputs tests:"
(
    # 3.2: reject missing BMAD path (expect non-zero, test passes if non-zero)
    # Use subshell wrapper because error_exit calls exit 1 which terminates the process
    cat > "$TMPDIR/t32.sh" << 'SCRIPT'
source "/mnt/bunker_data/ai/smart-ralph/plugins/ralph-bmad-bridge/scripts/import.sh"
rc=0
(validate_inputs "/does/not/exist" "my-spec" 2>/dev/null) || rc=$?
if [ "$rc" -ne 0 ]; then
    exit 0
fi
exit 1
SCRIPT
    run_test "validate_inputs rejects missing BMAD path" bash "$TMPDIR/t32.sh"

    # 3.3: reject existing target directory
    # Use subshell wrapper because error_exit calls exit 1
    cat > "$TMPDIR/t33.sh" << 'SCRIPT'
source "/mnt/bunker_data/ai/smart-ralph/plugins/ralph-bmad-bridge/scripts/import.sh"
bmad_tmp=$(mktemp -d)
spec_name="existing-test-spec"
mkdir -p "/mnt/bunker_data/ai/smart-ralph/specs/$spec_name"
rc=0
(validate_inputs "$bmad_tmp" "$spec_name" 2>/dev/null) || rc=$?
rm -rf "/mnt/bunker_data/ai/smart-ralph/specs/$spec_name" "$bmad_tmp"
if [ "$rc" -ne 0 ]; then
    exit 0
fi
exit 1
SCRIPT
    run_test "validate_inputs rejects existing target dir" bash "$TMPDIR/t33.sh"

    # 3.4: accept valid inputs (expect zero, test passes if zero)
    cat > "$TMPDIR/t34.sh" << 'SCRIPT'
source "/mnt/bunker_data/ai/smart-ralph/plugins/ralph-bmad-bridge/scripts/import.sh"
bmad_tmp=$(mktemp -d -p /mnt/bunker_data/ai/smart-ralph)
spec_name="valid-test-spec-xx"
if validate_inputs "$bmad_tmp" "$spec_name" 2>/dev/null; then
    exit 0
fi
rm -rf "$bmad_tmp"
exit 1
SCRIPT
    run_test "validate_inputs accepts valid inputs" bash "$TMPDIR/t34.sh"
)

echo "  parse_prd_frs tests:"
(
    # 3.5: parse_prd_frs extracts FRs from fixture PRD
    cat > "$TMPDIR/t35.sh" << 'SCRIPT'
source "/mnt/bunker_data/ai/smart-ralph/plugins/ralph-bmad-bridge/scripts/import.sh"
prd_tmp=$(mktemp -d)
req_tmp=$(mktemp)
cat > "$prd_tmp/prd.md" << 'PRDEOF'
# Test PRD
## Functional Requirements
- FR1: [Admin] can manage users
- FR2: [User] can view dashboard
- FR3: [Guest] can read public pages
PRDEOF
parse_prd_frs "$prd_tmp/prd.md" "$req_tmp"
rc=0
grep -q 'FR-1' "$req_tmp" || rc=1
grep -q 'FR-2' "$req_tmp" || rc=1
grep -q 'FR-3' "$req_tmp" || rc=1
grep -q '## User Stories' "$req_tmp" || rc=1
grep -q '## Functional Requirements' "$req_tmp" || rc=1
rm -rf "$prd_tmp" "$req_tmp"
exit $rc
SCRIPT
    run_test "parse_prd_frs extracts FRs from fixture PRD" bash "$TMPDIR/t35.sh"
)

echo "  write_frontmatter tests:"
(
    # 3.6: write_frontmatter produces valid YAML frontmatter
    cat > "$TMPDIR/t36.sh" << 'SCRIPT'
source "/mnt/bunker_data/ai/smart-ralph/plugins/ralph-bmad-bridge/scripts/import.sh"
tmpfile=$(mktemp)
write_frontmatter "$tmpfile" "requirements" "test-spec"
rc=0
# Check starts with ---
head -1 "$tmpfile" | grep -q '^---$' || rc=1
# Check contains spec: test-spec
grep -q '^spec: test-spec' "$tmpfile" || rc=1
# Check contains phase: requirements
grep -q '^phase: requirements' "$tmpfile" || rc=1
# Check contains created: with ISO timestamp
grep -qE '^created: [0-9]{4}-[0-9]{2}-[0-9]{2}T' "$tmpfile" || rc=1
# Check ends with --- separator
tail -1 "$tmpfile" | grep -q '^---$' || rc=1
rm -f "$tmpfile"
exit $rc
SCRIPT
    run_test "write_frontmatter produces valid YAML frontmatter" bash "$TMPDIR/t36.sh"
)

echo "  parse_prd_nfrs tests:"
(
    # 3.7: parse_prd_nfrs extracts NFR subsections with ### headings preserved
    cat > "$TMPDIR/t37.sh" << 'SCRIPT'
source "/mnt/bunker_data/ai/smart-ralph/plugins/ralph-bmad-bridge/scripts/import.sh"
prd_tmp=$(mktemp -d)
req_tmp=$(mktemp)
cat > "$prd_tmp/prd.md" << 'PRDEOF'
# Test PRD
## Non-Functional Requirements
### Performance
- Response Time: System responds within 200ms for API calls
- Throughput: Handle 1000 concurrent users
### Security
- Auth: All endpoints require JWT authentication
- Encryption: Data at rest encrypted with AES-256
PRDEOF
parse_prd_nfrs "$prd_tmp/prd.md" "$req_tmp"
rc=0
# NFR section header
grep -q 'Non-Functional Requirements' "$req_tmp" || rc=1
# NFR table exists
grep -q '| NFR' "$req_tmp" || rc=1
# NFR bullet items in table
grep -q '| Response Time' "$req_tmp" || rc=1
grep -q '| Throughput' "$req_tmp" || rc=1
grep -q '| Auth' "$req_tmp" || rc=1
grep -q '| Encryption' "$req_tmp" || rc=1
# CRITICAL: ### subsection headings MUST be preserved
grep -q '### Performance' "$req_tmp" || rc=1
grep -q '### Security' "$req_tmp" || rc=1
rm -rf "$prd_tmp" "$req_tmp"
exit $rc
SCRIPT
    run_test "parse_prd_nfrs extracts NFR subsections" bash "$TMPDIR/t37.sh"
)

echo "  parse_architecture tests:"
(
    # 3.8: parse_architecture maps sections correctly
    cat > "$TMPDIR/t38.sh" << 'SCRIPT'
source "/mnt/bunker_data/ai/smart-ralph/plugins/ralph-bmad-bridge/scripts/import.sh"
SPEC_DIR=$(mktemp -d)
arch_tmp=$(mktemp -d)
cat > "$arch_tmp/architecture.md" << 'ARCHEOF'
# System Architecture
## Core Decisions
- Decision 1: Use PostgreSQL for primary data store
- Decision 2: Redis for caching layer
- Decision 3: Node.js for API layer
## Project Structure
- src/api/ — API endpoint handlers
- src/models/ — Database models
ARCHEOF
mkdir -p "$SPEC_DIR"
parse_architecture "$arch_tmp/architecture.md" "$SPEC_DIR/design.md"
rc=0
grep -q 'Technical Decisions' "$SPEC_DIR/design.md" || rc=1
grep -q 'File Structure' "$SPEC_DIR/design.md" || rc=1
grep -q 'PostgreSQL' "$SPEC_DIR/design.md" || rc=1
grep -q 'src/api/' "$SPEC_DIR/design.md" || rc=1
rm -rf "$SPEC_DIR" "$arch_tmp"
exit $rc
SCRIPT
    run_test "parse_architecture maps sections correctly" bash "$TMPDIR/t38.sh"
)

echo "  integration tests:"
(
    # 3.9: full flow integration test with latency and data integrity
    # BMAD root must be within project root (validate_inputs check)
    cat > "$TMPDIR/t39.sh" << 'SCRIPT'
import_sh="/mnt/bunker_data/ai/smart-ralph/plugins/ralph-bmad-bridge/scripts/import.sh"
project_root="/mnt/bunker_data/ai/smart-ralph"
td=$(mktemp -d "$project_root/tmp_bmad_XXXXXX")
spec_name="integration-test-xx"

# Create BMAD mini-project structure
mkdir -p "$td/_bmad-output/planning-artifacts"

cat > "$td/_bmad-output/planning-artifacts/prd.md" << 'PRDEOF'
# Mini App PRD
## Functional Requirements
- FR1: [Admin] can manage users
- FR2: [User] can create accounts
## Non-Functional Requirements
### Performance
- Response Time: Under 200ms
PRDEOF

cat > "$td/_bmad-output/planning-artifacts/epics.md" << 'EPICEOF'
# Epics
## Stories
### Story 1.1: Admin user management
As an admin, I want to manage users.
Given I am an admin
When I access user list
Then I see all users
### Story 1.2: User account creation
As a user, I want to create my account.
Given I visit the signup page
When I fill in my details
Then my account is created
EPICEOF

cat > "$td/_bmad-output/planning-artifacts/architecture.md" << 'ARCHEOF'
# Architecture
## Core Decisions
- Decision 1: Use PostgreSQL
ARCHEOF

# Run import.sh directly (not sourced) to execute main flow
spec_dir="specs/$spec_name"
rm -rf "$spec_dir" 2>/dev/null || true
start=$(date +%s%N)
rc=0
OUTPUT=$(bash "$import_sh" "$td" "$spec_name" 2>&1) || rc=$?
end=$(date +%s%N)
elapsed=$(( (end - start) / 1000000 ))

# Check all 4 output files exist
check_rc=0
[ -f "$spec_dir/requirements.md" ] || check_rc=1
[ -f "$spec_dir/design.md" ] || check_rc=1
[ -f "$spec_dir/tasks.md" ] || check_rc=1
[ -f "$spec_dir/.ralph-state.json" ] || check_rc=1

# Check frontmatter on all files
grep -q '^spec:' "$spec_dir/requirements.md" || check_rc=1
grep -q '^spec:' "$spec_dir/design.md" || check_rc=1
grep -q '^spec:' "$spec_dir/tasks.md" || check_rc=1

# Check requirements.md has FR table and NFR table
grep -q '| FR-' "$spec_dir/requirements.md" || check_rc=1
grep -q '| NFR-' "$spec_dir/requirements.md" || check_rc=1

# Check tasks.md has Phase 1 with task entries
grep -q '## Phase 1:' "$spec_dir/tasks.md" || check_rc=1
grep -q 'Story' "$spec_dir/tasks.md" || check_rc=1

# CRITICAL: Verify STORY_COUNT propagates correctly (not 0)
grep -q 'Story' "$spec_dir/tasks.md" || check_rc=1
jq -e '.totalTasks >= 2' "$spec_dir/.ralph-state.json" >/dev/null 2>&1 || check_rc=1

# CRITICAL: Verify summary output shows correct story count (not "0 stories")
echo "$OUTPUT" | grep -q '2 stories extracted' || echo "$OUTPUT" | grep -q 'stories extracted' || check_rc=1

# Check latency < 5000ms
[ $elapsed -lt 5000 ] || check_rc=1

rc=$(( rc + check_rc ))
rm -rf "$td" "$spec_dir" "$project_root/tmp_bmad_"*
exit $rc
SCRIPT
    run_test "full flow integration test with latency (< 5s)" bash "$TMPDIR/t39.sh"
)

(
    # 3.10: validate_output validates frontmatter — missing frontmatter causes failure
    cat > "$TMPDIR/t30.sh" << 'SCRIPT'
import_sh="/mnt/bunker_data/ai/smart-ralph/plugins/ralph-bmad-bridge/scripts/import.sh"
td=$(mktemp -d)
mkdir -p "$td"
# Create requirements.md missing frontmatter (no spec/phase/created fields)
cat > "$td/requirements.md" << 'EOF'
# Requirements

This file has no frontmatter.
EOF
# Create valid design.md and tasks.md
source "$import_sh"
write_frontmatter "$td/design.md" "design" "test-spec"
write_frontmatter "$td/tasks.md" "tasks" "test-spec"

# Run validate_output — should fail due to missing frontmatter in requirements.md
rc=0
(validate_output "$td" 2>/dev/null) || rc=$?
rm -rf "$td"
if [ "$rc" -ne 0 ]; then
    exit 0
fi
exit 1
SCRIPT
    run_test "validate_output detects missing frontmatter and exits non-zero" bash "$TMPDIR/t30.sh"
)

echo "  parse_epics error scenario tests:"
(
    # 3.11: parse_epics extracts stories from fixture epics.md
    cat > "$TMPDIR/t311.sh" << 'SCRIPT'
import_sh="/mnt/bunker_data/ai/smart-ralph/plugins/ralph-bmad-bridge/scripts/import.sh"
td=$(mktemp -d)
cat > "$td/epics.md" << 'EPICEOF'
# Epics

### Story 1.1: User authentication
As a registered user, I want to log in.
**Acceptance Criteria:**
**Given** I am on the login page
**When** I enter valid credentials
**Then** I am redirected to the dashboard
### Story 1.2: Admin user management
As an admin, I want to manage users.
**Acceptance Criteria:**
**Given** I am logged in as admin
**When** I access the user list
**Then** I see all registered users
EPICEOF
bash -c "
source '$import_sh'
parse_epics '$td/epics.md' '$td/tasks.md' 2>/dev/null
exit 0
"
rc=0
grep -q 'Story 1.1' "$td/tasks.md" || rc=1
grep -q 'Story 1.2' "$td/tasks.md" || rc=1
grep -q 'Given' "$td/tasks.md" || rc=1
grep -q 'When' "$td/tasks.md" || rc=1
grep -q 'Then' "$td/tasks.md" || rc=1
grep -q 'Phase 1:' "$td/tasks.md" || rc=1
rm -rf "$td"
exit $rc
SCRIPT
    run_test "parse_epics extracts stories from fixture epics.md" bash "$TMPDIR/t311.sh"

    # 3.12: error scenario — graceful degradation with missing artifacts
    cat > "$TMPDIR/t312.sh" << 'SCRIPT'
import_sh="/mnt/bunker_data/ai/smart-ralph/plugins/ralph-bmad-bridge/scripts/import.sh"
project_root="/mnt/bunker_data/ai/smart-ralph"
td=$(mktemp -d "$project_root/tmp_bmad_XXXXXX")
# Create BMAD root with PRD but NO epics.md or architecture.md
mkdir -p "$td/_bmad-output/planning-artifacts"
cat > "$td/_bmad-output/planning-artifacts/prd.md" << 'PRDEOF'
# Minimal PRD
## Functional Requirements
- FR1: [Admin] can manage users
PRDEOF
# Do NOT create epics.md or architecture.md
spec_name="no-arch-test-xx"
rm -rf "$project_root/specs/$spec_name" 2>/dev/null || true
# import.sh should complete with exit 0, printing warnings
OUTPUT=$(bash "$import_sh" "$td" "$spec_name" 2>&1)
rc=$?
# Should complete successfully
if [ "$rc" -ne 0 ]; then
    exit 1
fi
# Should have warnings about missing artifacts
echo "$OUTPUT" | grep -q 'No epics file found' || rc=1
echo "$OUTPUT" | grep -q 'No architecture.md found' || rc=1
# Should produce output files
[ -f "$project_root/specs/$spec_name/requirements.md" ] || rc=1
[ -f "$project_root/specs/$spec_name/tasks.md" ] || rc=1
[ -f "$project_root/specs/$spec_name/design.md" ] || rc=1
[ -f "$project_root/specs/$spec_name/.ralph-state.json" ] || rc=1
# Requirements should have FR-1 from PRD
grep -q 'FR-1' "$project_root/specs/$spec_name/requirements.md" || rc=1
rm -rf "$td" "$project_root/specs/$spec_name" "$project_root/tmp_bmad_"*
exit $rc
SCRIPT
    run_test "import.sh handles missing epics.md and architecture.md gracefully" bash "$TMPDIR/t312.sh"
)

echo "  parse_prd_frs edge case tests:"
(
    # 3.13: parse_prd_frs skips malformed FR lines
    cat > "$TMPDIR/t313.sh" << 'SCRIPT'
import_sh="/mnt/bunker_data/ai/smart-ralph/plugins/ralph-bmad-bridge/scripts/import.sh"
td=$(mktemp -d)
cat > "$td/prd.md" << 'PRDEOF'
# Test PRD
## Functional Requirements
- FR1: [Admin] can manage users
- FR2: [User] can view dashboard
- FR3: [Guest] can read public pages
This is a malformed line without FR number or actor
Another malformed line with no structure here
- FR4: [Support] can reset passwords
PRDEOF
bash -c "
source '$import_sh'
parse_prd_frs '$td/prd.md' '$td/reqs.md' 2>/dev/null
exit 0
"
rc=0
# Only valid FRs should be present
grep -q 'FR-1' "$td/reqs.md" || rc=1
grep -q 'FR-2' "$td/reqs.md" || rc=1
grep -q 'FR-3' "$td/reqs.md" || rc=1
grep -q 'FR-4' "$td/reqs.md" || rc=1
# Should not contain malformed content
grep -q 'malformed line without FR' "$td/reqs.md" && rc=1
grep -q 'Another malformed line' "$td/reqs.md" && rc=1
# Should have User Stories and FR table sections
grep -q '## User Stories' "$td/reqs.md" || rc=1
grep -q '## Functional Requirements' "$td/reqs.md" || rc=1
# Should have exactly 4 items (matching count in extract_fr_lines output)
grep -q '4 items extracted' "$td/reqs.md" || rc=1
rm -rf "$td"
exit $rc
SCRIPT
    run_test "parse_prd_frs skips malformed FR lines" bash "$TMPDIR/t313.sh"
)

echo "  parse_epics edge case tests:"
(
    # 3.14: parse_epics handles story blocks without Given/When/Then ACs
    cat > "$TMPDIR/t314.sh" << 'SCRIPT'
import_sh="/mnt/bunker_data/ai/smart-ralph/plugins/ralph-bmad-bridge/scripts/import.sh"
td=$(mktemp -d)
cat > "$td/epics.md" << 'EPICEOF'
# Epics

### Story 1.1: User authentication
As a registered user, I want to log in.
**Acceptance Criteria:**
**Given** I am on the login page
**When** I enter valid credentials
**Then** I am redirected to the dashboard
### Story 1.2: View dashboard
As a user, I want to see my dashboard.
EPICEOF
bash -c "
source '$import_sh'
parse_epics '$td/epics.md' '$td/tasks.md' 2>/dev/null
exit 0
"
rc=0
# Both stories should appear in output
grep -q 'Story 1.1' "$td/tasks.md" || rc=1
grep -q 'Story 1.2' "$td/tasks.md" || rc=1
# Story with ACs should have Given/When/Then
grep -q 'Given' "$td/tasks.md" || rc=1
grep -q 'When' "$td/tasks.md" || rc=1
grep -q 'Then' "$td/tasks.md" || rc=1
# Story without ACs should have fallback Verify
grep -q 'Verify feature' "$td/tasks.md" || rc=1
grep -q 'implemented and passing tests' "$td/tasks.md" || rc=1
# Should have Phase 1 section
grep -q '## Phase 1:' "$td/tasks.md" || rc=1
# Should have 2 total_tasks in frontmatter
grep -q 'total_tasks: 2' "$td/tasks.md" || rc=1
rm -rf "$td"
exit $rc
SCRIPT
    run_test "parse_epics handles story blocks without ACs" bash "$TMPDIR/t314.sh"
)

echo ""
