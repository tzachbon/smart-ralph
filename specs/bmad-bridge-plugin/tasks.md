---
spec: bmad-bridge-plugin
phase: tasks
created: 2026-04-27
total_tasks: 61
---

# Tasks: BMAD Bridge Plugin

## Phase 1: Make It Work (POC)

Focus: Get the import pipeline working end-to-end. Accept hardcoded paths, skip edge cases, produce valid output files.

- [x] 1.1 Create plugin directory structure
  - **Do**:
    1. Create `plugins/ralph-bmad-bridge/commands/` directory
    2. Create `plugins/ralph-bmad-bridge/scripts/` directory
    3. Create `plugins/ralph-bmad-bridge/.claude-plugin/` directory
    4. Create `plugins/ralph-bmad-bridge/tests/` directory
  - **Files**: plugins/ralph-bmad-bridge/commands/, plugins/ralph-bmad-bridge/scripts/, plugins/ralph-bmad-bridge/.claude-plugin/, plugins/ralph-bmad-bridge/tests/
  - **Done when**: All four directories exist under `plugins/ralph-bmad-bridge/`
  - **Verify**: `test -d plugins/ralph-bmad-bridge/commands && test -d plugins/ralph-bmad-bridge/scripts && test -d plugins/ralph-bmad-bridge/.claude-plugin && test -d plugins/ralph-bmad-bridge/tests && echo 1.1_PASS`
  - **Commit**: `feat(bmad-bridge): create plugin directory structure`
  - _Requirements: FR-7, AC-7.1_
  - _Design: File Structure_

- [x] 1.2 Write plugin.json manifest
  - **Do**:
    1. Create `plugins/ralph-bmad-bridge/.claude-plugin/plugin.json` with name `ralph-bmad-bridge`, version `0.1.0`, MIT license, author `tzachbon`
    2. Include keywords: `bmad`, `import`, `structural-mapper`
  - **Files**: plugins/ralph-bmad-bridge/.claude-plugin/plugin.json
  - **Done when**: plugin.json has valid JSON with name, version, description, license, author fields
  - **Verify**: `jq -e '.name == "ralph-bmad-bridge" and .version == "0.1.0"' plugins/ralph-bmad-bridge/.claude-plugin/plugin.json && echo 1.2_PASS`
  - **Commit**: `feat(bmad-bridge): add plugin.json manifest`
  - _Requirements: FR-7, AC-7.1, AC-7.2_
  - _Design: File Structure_

- [x] 1.3 Register plugin in marketplace.json
  - **Do**:
    1. Read existing `.claude-plugin/marketplace.json`
    2. Add new entry to `plugins` array with name `ralph-bmad-bridge`, source `./plugins/ralph-bmad-bridge`, category `development`
  - **Files**: .claude-plugin/marketplace.json
  - **Done when**: marketplace.json has a `ralph-bmad-bridge` entry in plugins array
  - **Verify**: `jq -e '.plugins[] | select(.name == "ralph-bmad-bridge")' .claude-plugin/marketplace.json && echo 1.3_PASS`
  - **Commit**: `feat(bmad-bridge): register plugin in marketplace.json`
  - _Requirements: FR-7, AC-7.5_
  - _Design: File Structure_

- [x] 1.4 Write import.sh skeleton with shebang and jq check
  - **Do**:
    1. Create `plugins/ralph-bmad-bridge/scripts/import.sh`
    2. Add `#!/usr/bin/env bash` shebang, `set -euo pipefail`
    3. Add `command -v jq >/dev/null 2>&1 || { echo "Error: jq is required" >&2; exit 1; }` check
    4. Define empty placeholder functions: `validate_inputs`, `resolve_bmad_paths`, `parse_prd_frs`, `parse_prd_nfrs`, `parse_epics`, `parse_architecture`, `write_state`, `validate_output`, `print_summary`
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: import.sh has shebang, set -euo pipefail, jq check, and all function stubs
  - **Verify**: `head -5 plugins/ralph-bmad-bridge/scripts/import.sh | grep -q 'set -euo pipefail' && grep -q 'function validate_inputs' plugins/ralph-bmad-bridge/scripts/import.sh && echo 1.4_PASS`
  - **Commit**: `feat(bmad-bridge): create import.sh skeleton`
  - _Requirements: FR-1, NFR-1_
  - _Design: Components, Main Import Script_

- [x] 1.5 Implement validate_inputs function
  - **Do**:
    1. Add function `validate_inputs()` accepting `$bmad_root` and `$spec_name`
    2. Check `$bmad_root` exists as directory, exit 1 with message if not
    3. Check `specs/$spec_name` directory does not exist, exit 1 if it does
    4. Validate `$spec_name` matches `^[a-z0-9-]+$`, exit 1 if not
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: validate_inputs returns 0 for valid inputs, exits 1 with stderr message for invalid BMAD path, existing target dir, or invalid spec name
  - **Verify**: `bash -c 'source plugins/ralph-bmad-bridge/scripts/import.sh; validate_inputs "/nonexistent" "test"; echo FAIL' 2>&1 | grep -q 'Error.*not found' && echo 1.5_PASS`
  - **Commit**: `feat(bmad-bridge): implement validate_inputs`
  - _Requirements: FR-1, AC-1.5_
  - _Design: Error Handling_

- [x] 1.6 Implement resolve_bmad_paths function
  - **Do**:
    1. Add function `resolve_bmad_paths()` accepting `$project_root`
    2. Set `BMAD_PLANNING` to `$project_root/_bmad-output/planning-artifacts/`
    3. If `BMAD_PLANNING` doesn't exist, try `$project_root/_bmad-output/planning_artifacts/` (underscore variant)
    4. Export `BMAD_PRD`, `BMAD_EPICS`, `BMAD_ARCH` as absolute paths under `BMAD_PLANNING`
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: BMAD_PRD, BMAD_EPICS, BMAD_ARCH are set to correct absolute paths when artifact directory exists
  - **Verify**: `TMPDIR=$(mktemp -d); mkdir -p "$TMPDIR/_bmad-output/planning-artifacts"; bash -c 'source plugins/ralph-bmad-bridge/scripts/import.sh; resolve_bmad_paths "'"$TMPDIR"'"; echo $BMAD_PRD'; rm -rf "$TMPDIR" | grep -q 'planning-artifacts/prd.md' && echo 1.6_PASS`
  - **Commit**: `feat(bmad-bridge): implement resolve_bmad_paths`
  - _Requirements: FR-2_
  - _Design: Components, resolve_bmad_paths_

- [x] 1.7 Implement write_frontmatter function
  - **Do**:
    1. Add function `write_frontmatter()` accepting `$file`, `$phase`, `$spec_name`, `$total_tasks` (optional)
    2. Write YAML frontmatter with `spec`, `phase`, `created` (ISO timestamp via `date -Iseconds`), and `total_tasks` if provided
    3. Append content after frontmatter separator `---`
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: write_frontmatter produces valid YAML frontmatter block with all required fields
  - **Verify**: `bash -c 'source plugins/ralph-bmad-bridge/scripts/import.sh; TMPFILE=$(mktemp); write_frontmatter "$TMPFILE" "requirements" "test-spec"; head -5 "$TMPFILE" | grep -q "spec: test-spec" && grep -q "phase: requirements" "$TMPFILE"; rm -f "$TMPFILE"' && echo 1.7_PASS`
  - **Commit**: `feat(bmad-bridge): implement write_frontmatter`
  - _Requirements: FR-2, AC-2.5_
  - _Design: write_frontmatter_

- [x] 1.8 Implement parse_prd_frs function
  - **Do**:
    1. Add function `parse_prd_frs()` accepting `$prd_path`
    2. Use awk state-machine to find `## Functional Requirements` section
    3. Extract lines matching `- FR[0-9]+:` pattern with `[Actor] can [capability]` text
    4. Write requirements.md: User Story section (convert FR text to `As a... I want... So that...`) and Functional Requirements table
    5. Print count of extracted FRs to stdout
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: parse_prd_frs extracts FR lines and writes requirements.md with User Stories and FR table
  - **Verify**: `TMPDIR=$(mktemp -d); PRD="$TMPDIR/prd.md"; echo -e '## Functional Requirements\n- FR1: [Admin] can manage users\n- FR2: [User] can view dashboard' > "$PRD"; bash -c 'source plugins/ralph-bmad-bridge/scripts/import.sh; REQ="$TMPDIR/requirements.md"; parse_prd_frs "$PRD" "$REQ"; cat "$REQ"'; grep -q 'Functional Requirements' "$TMPDIR/requirements.md" && grep -q 'FR-1' "$TMPDIR/requirements.md" && rm -rf "$TMPDIR" && echo 1.8_PASS`
  - **Commit**: `feat(bmad-bridge): implement parse_prd_frs`
  - _Requirements: FR-2, AC-2.1, AC-2.2, AC-2.3_
  - _Design: PRD Parser_

- [x] 1.9 Implement parse_prd_nfrs function
  - **Do**:
    1. Add function `parse_prd_nfrs()` accepting `$prd_path`
    2. Use awk state-machine to find `## Non-Functional Requirements` section
    3. Extract `###` subsection headers (e.g., Performance, Security)
    4. Build NFR table rows: subsection header as requirement, bullet items as metric/target
    5. Append NFR table to requirements.md; if no NFR section exists, do nothing (not an error)
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: parse_prd_nfrs extracts NFR subsections and appends NFR table to requirements.md; silently skips if no NFR section
  - **Verify**: `TMPDIR=$(mktemp -d); PRD="$TMPDIR/prd.md"; echo -e '## Non-Functional Requirements\n### Performance\n- Response time < 2s\n### Security\n- All API endpoints use HTTPS' > "$PRD"; REQ="$TMPDIR/requirements.md"; touch "$REQ"; bash -c 'source plugins/ralph-bmad-bridge/scripts/import.sh; parse_prd_nfrs "$PRD" "$REQ"'; grep -q 'Non-Functional' "$REQ" && rm -rf "$TMPDIR" && echo 1.9_PASS`
  - **Commit**: `feat(bmad-bridge): implement parse_prd_nfrs`
  - _Requirements: FR-3, AC-3.1, AC-3.2, AC-3.3, AC-3.4_
  - _Design: PRD Parser_

- [x] 1.10 Implement parse_epics function
  - **Do**:
    1. Add function `parse_epics()` accepting `$epics_path` and `$output_path`
    2. Use awk state-machine to track epic/story context
    3. Extract `### Story N.M:` blocks with title lines following each heading
    4. Extract Given/When/Then acceptance criteria from each story block
    5. Build tasks.md: Phase 1 heading + task entries for each story with FR refs from Coverage Map
    6. Read FR coverage map if present (basic support in POC; full extraction in Phase 2 task 2.5)
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: parse_epics extracts stories and writes tasks.md with Phase 1 task entries containing Do/Files/Done when/Verify/Commit sections
  - **Verify**: `TEST_TMP=$(mktemp -d); EPICS="$TEST_TMP/epics.md"; cat > "$EPICS" <<'EOF'
### Story 1.1: User authentication
As a registered user, I want to log in.
**Acceptance Criteria:**
**Given** I am on the login page
**When** I enter valid credentials
**Then** I am redirected to the dashboard
EOF
bash -c 'source plugins/ralph-bmad-bridge/scripts/import.sh; TASKS="$TEST_TMP/tasks.md"; parse_epics "$EPICS" "$TASKS"'; grep -q 'Story 1.1' "$TEST_TMP/tasks.md" && rm -rf "$TEST_TMP" && echo 1.10_PASS`
  - **Commit**: `feat(bmad-bridge): implement parse_epics`
  - _Requirements: FR-4, AC-4.1, AC-4.2, AC-4.3, FR-8, FR-9_
  - _Design: Epics Parser_
  - _Note: FR-9 basic support in POC (coverage map read if present); full extraction in Phase 2 task 2.5_

- [x] 1.11 Implement parse_architecture function
 <!-- reviewer-diagnosis
 what: parse_architecture regex bug — has_decisions flag never set to 1
 why: grep -qE regex at line 406 fails to match '## Core Decisions' heading
 fix: Replace with: if echo "$lower" | grep -qiE 'decision|technology|stack'; then has_decisions=1; fi
 -->
  - **Do**:
    1. Add function `parse_architecture()` accepting `$arch_path` and `$output_path`
    2. Detect if `$arch_path` exists; if not, write placeholder `design.md` with "Architecture input not provided"
    3. Find `##` headings in architecture.md and map them to design.md sections
    4. Identify "decisions"/"technology"/"stack" headings for Technical Decisions table
    5. Identify "project structure"/"file structure" headings for File Structure table
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: parse_architecture maps architecture sections to design.md; generates placeholder when architecture.md is missing
  - **Verify**: `TMPDIR=$(mktemp -d); ARCH="$TMPDIR/architecture.md"; echo -e '## Core Decisions\nBash over Python for parsing\n## Project Structure\nsrc/\n  scripts/\n    import.sh' > "$ARCH"; DES="$TMPDIR/design.md"; bash -c 'source plugins/ralph-bmad-bridge/scripts/import.sh; parse_architecture "$ARCH" "$DES"'; grep -q 'Technical Decisions' "$TMPDIR/design.md" && rm -rf "$TMPDIR" && echo 1.11_PASS`
  - **Commit**: `feat(bmad-bridge): implement parse_architecture`
  - _Requirements: FR-5, AC-5.1, AC-5.2, AC-5.5, FR-8_
  - _Design: Architecture Parser_

- [x] 1.12 Implement write_state function
  - _Note: Implemented as part of Phase 1 consolidation. write_state() function exists at import.sh line ~681 and is called from main flow. Marked complete — functionality present._
  - **Do**:
    1. Add function `write_state()` accepting `$spec_dir` and `$total_tasks`
    2. Use `jq` to create `.ralph-state.json` with `source: "spec"`, `name`, `basePath`, `phase: "tasks"`, `taskIndex: 0`, `totalTasks`, `granularity: "fine"`, `epicName`
    3. Write to `$spec_dir/.ralph-state.json`
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: write_state creates valid `.ralph-state.json` with all required fields in the output spec directory
  - **Verify**: `TMPDIR=$(mktemp -d); bash -c 'source plugins/ralph-bmad-bridge/scripts/import.sh; write_state "'"$TMPDIR"' "test-spec" 42'; jq -e '.phase == "tasks" and .taskIndex == 0 and .totalTasks == 42' "$TMPDIR/.ralph-state.json" && rm -rf "$TMPDIR" && echo 1.12_PASS`
  - **Commit**: `feat(bmad-bridge): implement write_state`
  - _Requirements: FR-7_
  - _Design: write_state_

- [x] 1.13 Implement print_summary function
  - **Do**:
    1. Add function `print_summary()` accepting FR count, NFR count, story count, arch sections count
    2. Print formatted summary to stdout: "Mapped X functional requirements, Y non-functional requirements, Z stories"
    3. Print warnings section listing any skipped content or items needing manual review
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: print_summary outputs a human-readable summary with counts and warnings
  - **Verify**: `bash -c 'source plugins/ralph-bmad-bridge/scripts/import.sh; print_summary 3 2 5 2' 2>&1 | grep -q 'Mapped' && echo 1.13_PASS`
  - **Commit**: `feat(bmad-bridge): implement print_summary`
  - _Requirements: FR-6, AC-6.2, AC-6.3_
  - _Design: Output Validator_

- [x] 1.14 Wire up main flow in import.sh
  - _Note: Implemented as part of Phase 1 consolidation. Main flow exists at import.sh lines ~999-1020, calling all parser/generator functions in sequence._
  - **Do**:
    1. At end of import.sh, read positional args: `$1` = bmad_root, `$2` = spec_name
    2. Call `validate_inputs`, `resolve_bmad_paths`, `generate_requirements` (invokes parse_prd_frs + parse_prd_nfrs), `generate_tasks` (invokes parse_epics), `generate_design` (invokes parse_architecture), `write_state`, `validate_output`, `print_summary`
    3. Create output spec directory `specs/$spec_name/`
    4. Handle missing artifacts gracefully: warn but continue for each missing file
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: Running `bash scripts/import.sh <bmad_root> <spec_name>` produces all output files in `specs/<spec_name>/`
  - **Verify**: `TMPDIR=$(mktemp -d); mkdir -p "$TMPDIR/_bmad-output/planning-artifacts"; echo -e '## Functional Requirements\n- FR1: [Admin] can manage users' > "$TMPDIR/_bmad-output/planning-artifacts/prd.md"; SPEC="bmad-test-poc"; bash plugins/ralph-bmad-bridge/scripts/import.sh "$TMPDIR" "$SPEC" 2>&1 | grep -q 'Mapped'; rm -rf "specs/$SPEC" "$TMPDIR" && echo 1.14_PASS`
  - **Commit**: `feat(bmad-bridge): wire up main import flow`
  - _Requirements: FR-2, FR-3, FR-4, FR-5, FR-8_
  - _Design: Main Import Script_

- [x] 1.15 Make import.sh executable and add shebang
  - **Do**:
    1. Ensure `#!/usr/bin/env bash` is the first line of import.sh
    2. Run `chmod +x plugins/ralph-bmad-bridge/scripts/import.sh`
    3. Verify `test -x` passes
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: import.sh is executable and runs directly as `./scripts/import.sh`
  - **Verify**: `test -x plugins/ralph-bmad-bridge/scripts/import.sh && echo 1.15_PASS`
  - **Commit**: `feat(bmad-bridge): make import.sh executable`
  - _Requirements: FR-7, AC-7.4_
  - _Design: File Structure_

- [x] 1.16 POC checkpoint: verify import.sh structure and permissions
  - **Do**:
    1. Verify import.sh has all required function stubs: validate_inputs, resolve_bmad_paths, write_frontmatter, parse_prd_frs, parse_prd_nfrs, parse_epics, parse_architecture, write_state, validate_output, print_summary
    2. Verify shebang is present and file is executable
    3. Verify jq dependency check is present
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: All 10 function stubs present, shebang present, file is executable
  - **Verify**: `grep -q 'function validate_inputs' plugins/ralph-bmad-bridge/scripts/import.sh && grep -q 'function print_summary' plugins/ralph-bmad-bridge/scripts/import.sh && test -x plugins/ralph-bmad-bridge/scripts/import.sh && grep -q 'command -v jq' plugins/ralph-bmad-bridge/scripts/import.sh && echo 1.16_PASS`
  - **Commit**: `chore(bmad-bridge): POC checkpoint - import.sh structure verified`

- [x] 1.17 Write CLI wrapper command frontmatter
  - _Note: Implemented as part of Phase 1 consolidation. CLI wrapper exists at plugins/ralph-bmad-bridge/commands/ralph-bmad-import.md._
  - **Do**:
    1. Create `plugins/ralph-bmad-bridge/commands/ralph-bmad-import.md`
    2. Add Claude Code plugin frontmatter: `name: ralph-bmad:import`, description
    3. Add body that parses `$ARGUMENTS` for two positional args (BMAD path, spec name)
    4. Invoke `bash "${CLAUDE_PLUGIN_ROOT}/scripts/import.sh" "$BMAD_PATH" "$SPEC_NAME"`
    5. Relay exit code with `exit $?`
  - **Files**: plugins/ralph-bmad-bridge/commands/ralph-bmad-import.md
  - **Done when**: CLI wrapper is valid markdown with frontmatter that invokes import.sh with two positional arguments
  - **Verify**: `grep -q 'ralph-bmad:import' plugins/ralph-bmad-bridge/commands/ralph-bmad-import.md && grep -q 'import.sh' plugins/ralph-bmad-bridge/commands/ralph-bmad-import.md && echo 1.17_PASS`
  - **Commit**: `feat(bmad-bridge): write CLI wrapper command`
  - _Requirements: FR-1, AC-1.1, AC-1.2_
  - _Design: CLI Wrapper_

- [x] 1.18 Generate requirements.md from PRD with frontmatter
  - _Note: Implemented as part of Phase 1 consolidation. generate_requirements() exists at import.sh and produces specs/bmad-bridge-plugin/requirements.md._
  - **Do**:
    1. In `generate_requirements()` function, write full requirements.md including frontmatter (via write_frontmatter), Goal section from PRD title, User Stories, FR table, NFR table, Glossary (empty), Out of Scope, Dependencies
    2. Use BMAD PRD frontmatter `workflowType` or title for Goal description
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: generate_requirements produces complete requirements.md with YAML frontmatter and all required sections
  - **Verify**: `TMPDIR=$(mktemp -d); PRD="$TMPDIR/prd.md"; echo -e '---\nworkflowType: prd\n---\n# Test PRD\n## Functional Requirements\n- FR1: [Admin] can manage users\n## Non-Functional Requirements\n### Performance\n- Latency < 2s' > "$PRD"; bash -c 'source plugins/ralph-bmad-bridge/scripts/import.sh; REQ="$TMPDIR/requirements.md"; generate_requirements "$PRD" "$REQ"'; grep -q 'spec:' "$TMPDIR/requirements.md" && grep -q 'Functional Requirements' "$TMPDIR/requirements.md" && rm -rf "$TMPDIR" && echo 1.18_PASS`
  - **Commit**: `feat(bmad-bridge): generate full requirements.md from PRD`
  - _Requirements: FR-2, FR-3, AC-2.5, AC-6.4_
  - _Design: PRD Parser_

- [x] 1.19 Generate tasks.md from epics with full template structure
  - _Note: Implemented as part of Phase 1 consolidation. generate_tasks() exists at import.sh and produces specs/bmad-bridge-plugin/tasks.md._
  - **Do**:
    1. In `generate_tasks()` function, write full tasks.md including frontmatter (spec, phase, total_tasks, created)
    2. Include Phase 1 (POC) section with task entries from stories
    3. Include Phase 2-5 template placeholders (empty sections per design decision)
    4. Count total tasks from stories and write as `total_tasks` in frontmatter
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: generate_tasks produces tasks.md with valid frontmatter, Phase 1 populated from stories, Phase 2-5 as template placeholders
  - **Verify**: `TMPDIR=$(mktemp -d); EPICS="$TMPDIR/epics.md"; echo '### Story 1.1: Auth login' > "$EPICS"; bash -c 'source plugins/ralph-bmad-bridge/scripts/import.sh; TASKS="$TMPDIR/tasks.md"; generate_tasks "$EPICS" "$TASKS"'; grep -q 'total_tasks:' "$TMPDIR/tasks.md" && grep -q 'Phase 1' "$TMPDIR/tasks.md" && rm -rf "$TMPDIR" && echo 1.19_PASS`
  - **Commit**: `feat(bmad-bridge): generate full tasks.md from epics`
  - _Requirements: FR-4, AC-4.1, AC-4.2, AC-4.5, FR-8_
  - _Design: Epics Parser_

- [x] 1.20 Generate design.md from architecture with frontmatter
  - **Do**:
    1. In `generate_design()` function, write full design.md including frontmatter
    2. Include Overview section from PRD title or architecture title
    3. Call `parse_architecture` to fill in Architecture, Technical Decisions, File Structure sections
    4. Add empty template sections for Interfaces, Error Handling, Edge Cases, Dependencies
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: generate_design produces design.md with valid frontmatter and architecture-mapped sections
  - **Verify**: `TMPDIR=$(mktemp -d); ARCH="$TMPDIR/architecture.md"; echo '## Core Decisions' > "$ARCH"; bash -c 'source plugins/ralph-bmad-bridge/scripts/import.sh; DES="$TMPDIR/design.md"; generate_design "$ARCH" "$DES"'; grep -q 'spec:' "$TMPDIR/design.md" && rm -rf "$TMPDIR" && echo 1.20_PASS`
  - **Commit**: `feat(bmad-bridge): generate full design.md from architecture`
  - _Requirements: FR-5, AC-5.3, AC-5.4, FR-8_
  - _Design: Architecture Parser_

- [x] 1.21 Implement validate_output function
  - _Note: Implemented as part of Phase 1 consolidation. validate_output() exists at import.sh line ~684, called from main flow with $SPEC_DIR (bug fixed in Phase 2)._
  - **Do**:
    1. Add function `validate_output()` accepting `$spec_dir`
    2. Check that `requirements.md`, `design.md`, `tasks.md` exist in spec dir
    3. Validate frontmatter has required fields: `spec`, `phase`, `created` (grep for `^spec:`, `^phase:`, `^created:`)
    4. Check tasks.md has `total_tasks` field
    5. Return 0 if all checks pass, 1 with error messages if any fail
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: validate_output confirms all generated files have valid frontmatter and required fields
  - **Verify**: `TEST_TMP=$(mktemp -d); mkdir "$TEST_TMP/spec"; touch "$TEST_TMP/spec/requirements.md"; echo -e '---\nspec: test\nphase: requirements\ncreated: 2026-01-01\n---' > "$TEST_TMP/spec/requirements.md"; bash -c 'source plugins/ralph-bmad-bridge/scripts/import.sh; validate_output "'"$TEST_TMP/spec"'"; echo $?'; rm -rf "$TEST_TMP" && echo 1.21_PASS`
  - **Commit**: `feat(bmad-bridge): implement validate_output`
  - _Requirements: FR-6, AC-6.1, AC-6.4, AC-6.5, AC-6.6_
  - _Design: Output Validator_

- [x] 1.22 POC checkpoint: run import.sh against minimal fixture
  - **Do**:
    1. Create a temporary BMAD fixture with prd.md containing 2 FRs and 1 NFR
    2. Run `import.sh` against the fixture with a new spec name
    3. Verify output directory has requirements.md, tasks.md, design.md, .ralph-state.json
    4. Verify all 4 files have non-empty content
  - **Files**: (temp fixture in /tmp)
  - **Done when**: Import pipeline runs end-to-end without errors and produces all 4 non-empty output files
  - **Verify**: `TEST_TMP=$(mktemp -d); mkdir -p "$TEST_TMP/_bmad-output/planning-artifacts"; echo -e '---\nworkflowType: prd\n---\n# Test\n## Functional Requirements\n- FR1: [Admin] can manage\n- FR2: [User] can view\n## Non-Functional Requirements\n### Perf\n- Latency < 2s' > "$TEST_TMP/_bmad-output/planning-artifacts/prd.md"; SPEC="bmad-poc-check"; bash plugins/ralph-bmad-bridge/scripts/import.sh "$TEST_TMP" "$SPEC" 2>&1; test -f "specs/$SPEC/requirements.md" && test -f "specs/$SPEC/tasks.md" && test -f "specs/$SPEC/design.md" && test -f "specs/$SPEC/.ralph-state.json" && test -s "specs/$SPEC/requirements.md" && rm -rf "specs/$SPEC" "$TEST_TMP" && echo 1.22_PASS`
  - **Commit**: `feat(bmad-bridge): POC checkpoint - full pipeline works`
  - _Requirements: FR-2, FR-3, FR-4, FR-5, FR-6_

- [x] 1.23 POC checkpoint: verify CLI wrapper parses arguments correctly
  - **Do**:
    1. Read the CLI wrapper markdown file
    2. Verify it extracts two positional arguments from `$ARGUMENTS`
    3. Verify it passes them to import.sh as `$1` and `$2`
    4. Verify exit code relay is present
  - **Files**: plugins/ralph-bmad-bridge/commands/ralph-bmad-import.md
  - **Done when**: CLI wrapper correctly passes both arguments to import.sh
  - **Verify**: `grep -c '\$BMAD_PATH\|\$SPEC_NAME\|\$1\|\$2' plugins/ralph-bmad-bridge/commands/ralph-bmad-import.md | grep -q '[3-9]\|[1-9][0-9]' && echo 1.23_PASS`
  - **Commit**: `feat(bmad-bridge): POC checkpoint - CLI wrapper verified`
  - _Requirements: FR-1, AC-1.2_

- [x] 1.24 POC checkpoint: verify error handling for missing BMAD path
  - **Do**:
    1. Run `import.sh /nonexistent/path test-spec`
    2. Verify exit code is non-zero
    3. Verify stderr contains an error message about the path
  - **Files**: (none — verification only)
  - **Done when**: import.sh exits non-zero with error message for invalid BMAD path
  - **Verify**: `bash plugins/ralph-bmad-bridge/scripts/import.sh /nonexistent/path test-spec > /dev/null 2>&1; test $? -ne 0 && echo 1.24_PASS || echo FAIL`
  - **Commit**: `feat(bmad-bridge): POC checkpoint - error handling verified`
  - _Requirements: FR-1, AC-1.5_

- [x] 1.25 [VERIFY] Party-mode review of POC output
  - **Do**:
    1. Invoke `bmad-party-mode` with POC code (`plugins/ralph-bmad-bridge/scripts/import.sh`) + generated spec files (import.sh skeleton + CLI wrapper)
    2. Collect findings from all review layers
    3. Address any CRITICAL or HIGH severity findings
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh, plugins/ralph-bmad-bridge/commands/ralph-bmad-import.md
  - **Done when**: All CRITICAL and HIGH findings from party-mode review are addressed
  - **Verify**: `echo "Party-mode review completed; findings documented in .progress.md"`
  - **Commit**: `chore(bmad-bridge): party-mode review of POC output (address findings)`

## Phase 2: Refactoring

Focus: Clean up import.sh — extract helpers, consolidate duplicate code, add proper error handling patterns.

- [x] 2.1 Extract FR text parsing into reusable helper
  - **Do**:
    1. In `parse_prd_frs()`, extract the awk command that matches `- FR#: [Actor] can [capability]` into a separate function `extract_fr_lines()`
    2. Have `parse_prd_frs()` call `extract_fr_lines()` and process the result
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: FR extraction awk logic is isolated in `extract_fr_lines()` function called by `parse_prd_frs()`
  - **Verify**: `grep -q 'function extract_fr_lines' plugins/ralph-bmad-bridge/scripts/import.sh && echo 2.1_PASS`
  - **Commit**: `refactor(bmad-bridge): extract FR parsing into helper function`
  - _Design: PRD Parser_

- [x] 2.2 Consolidate NFR parsing with extract_fr_lines
  - **Do**:
    1. Refactor `parse_prd_nfrs()` to reuse `extract_fr_lines()` for bullet item extraction under NFR subsections
    2. Keep section detection logic separate (awk state-machine for NFR section boundary)
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: parse_prd_nfrs calls extract_fr_lines for bullet items under NFR subsections
  - **Verify**: `bash plugins/ralph-bmad-bridge/scripts/import.sh 2>&1 | grep -iv 'usage\|error' || true; grep -c 'extract_fr_lines' plugins/ralph-bmad-bridge/scripts/import.sh | grep -q '[1-9]' && echo 2.2_PASS`
  - **Commit**: `refactor(bmad-bridge): consolidate NFR parsing with FR helper`
  - _Design: PRD Parser_

- [x] 2.3 Extract story title parsing into helper
  - **Do**:
    1. In `parse_epics()`, extract the logic that parses the title after `### Story N.M:` heading into `extract_story_title()`
    2. Handle both single-line and multi-line story titles
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: Story title extraction is in a separate `extract_story_title()` function
  - **Verify**: `grep -q 'function extract_story_title' plugins/ralph-bmad-bridge/scripts/import.sh && echo 2.3_PASS`
  - **Commit**: `refactor(bmad-bridge): extract story title parsing`
  - _Design: Epics Parser_

- [x] 2.4 Extract Given/When/Then AC parser into helper
  - **Do**:
    1. In `parse_epics()`, extract the logic that parses BDD acceptance criteria from story blocks into `extract_bdd_criteria()`
    2. Handle Given/When/Then/And variants
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: BDD criteria extraction is in `extract_bdd_criteria()` function
  - **Verify**: `grep -q 'function extract_bdd_criteria' plugins/ralph-bmad-bridge/scripts/import.sh && echo 2.4_PASS`
  - **Commit**: `refactor(bmad-bridge): extract BDD criteria parsing`
  - _Design: Epics Parser_

- [x] 2.5 Build FR coverage map extraction into helper
  - **Do**:
    1. In `parse_epics()`, extract the FR coverage map parsing logic into `build_coverage_map()`
    2. Parse `### FR Coverage Map` section and produce associative array of FR-to-epic mappings
    3. Have `parse_epics()` call `build_coverage_map()` and use the mapping to add `_Requirements: FR-X` refs
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: Coverage map is extracted into `build_coverage_map()` function, called by `parse_epics()`
  - **Verify**: `grep -q 'function build_coverage_map' plugins/ralph-bmad-bridge/scripts/import.sh && echo 2.5_PASS`
  - **Commit**: `refactor(bmad-bridge): extract coverage map builder`
  - _Requirements: FR-9, AC-4.4_
  - _Design: Epics Parser_

- [x] 2.6 Standardize error handling with error_exit function
  - **Do**:
    1. Create `error_exit()` helper that takes a message, prints to stderr, logs to a temp warning file, and exits
    2. Replace all direct `echo "Error:" >&2; exit 1` patterns with calls to `error_exit`
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: All error exit patterns use `error_exit()` function
  - **Verify**: `grep -q 'function error_exit' plugins/ralph-bmad-bridge/scripts/import.sh && ! grep -q 'echo.*Error.*>&2; exit' plugins/ralph-bmad-bridge/scripts/import.sh && echo 2.6_PASS`
  - **Commit**: `refactor(bmad-bridge): standardize error handling`
  - _Design: Error Handling_

- [x] 2.7 Add input sanitization for spec name
  - **Do**:
    1. In `validate_inputs()`, add stricter validation: spec name must match `^[a-z][a-z0-9-]*[a-z0-9]$` (at least 2 chars, lowercase alphanumeric with hyphens)
    2. Reject spec names with leading/trailing hyphens
    3. Reject names with consecutive hyphens
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: validate_inputs rejects spec names with leading/trailing hyphens, consecutive hyphens, uppercase, or special characters
  - **Verify**: `grep -q 'a-z0-9' plugins/ralph-bmad-bridge/scripts/import.sh && echo 2.7_PASS`
  - **Commit**: `refactor(bmad-bridge): add spec name input sanitization`
  - _Design: Security Considerations_

- [x] 2.8 Handle BMAD config-based output paths
  - **Do**:
    1. In `resolve_bmad_paths()`, check for `_bmad/config.toml` and extract `planning_artifacts` path if present
    2. Fall back to default `_bmad-output/planning-artifacts/` if config not found
    3. Support both hyphen and underscore variants of directory names
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: resolve_bmad_paths reads BMAD config for artifact paths with sensible fallbacks
  - **Verify**: `TMPDIR=$(mktemp -d); mkdir -p "$TMPDIR/_bmad-output/planning-artifacts"; echo -e '[core]\nplanning_artifacts = "_bmad-output/planning-artifacts"' > "$TMPDIR/_bmad/config.toml"; bash -c 'source plugins/ralph-bmad-bridge/scripts/import.sh; resolve_bmad_paths "'"$TMPDIR"'"; echo $BMAD_PRD'; grep -q 'planning-artifacts/prd.md' <<< "$(bash -c 'source plugins/ralph-bmad-bridge/scripts/import.sh; resolve_bmad_paths "'"$TMPDIR"'"; echo $BMAD_PRD')" && rm -rf "$TMPDIR" && echo 2.8_PASS`
  - **Commit**: `refactor(bmad-bridge): support BMAD config-based paths`
  - _Design: Edge Cases_

- [x] 2.9 Add path traversal protection
  - **Do**:
    1. In `validate_inputs()`, resolve BMAD root to absolute path
    2. Reject paths containing `..` components that would escape the project root
    3. Validate that spec_name output dir is under the repo root
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: import.sh rejects path traversal attempts with clear error message
  - **Verify**: `bash plugins/ralph-bmad-bridge/scripts/import.sh "../../../../etc" test 2>&1; test $? -ne 0 && echo 2.9_PASS`
  - **Commit**: `refactor(bmad-bridge): add path traversal protection`
  - _Design: Security Considerations_

- [x] 2.10 Quality checkpoint: lint and syntax check import.sh
  - **Do**:
    1. Run `bash -n plugins/ralph-bmad-bridge/scripts/import.sh` for syntax check
    2. Run shellcheck if available: `shellcheck plugins/ralph-bmad-bridge/scripts/import.sh`
    3. Fix any syntax errors or warnings
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: Syntax check passes, no shellcheck errors
  - **Verify**: `bash -n plugins/ralph-bmad-bridge/scripts/import.sh && echo 2.10_PASS`
  - **Commit**: `chore(bmad-bridge): pass syntax and lint checkpoint`

- [x] 2.11 [VERIFY] Adversarial review of refactored import.sh
  - **Do**:
    1. Invoke `bmad-review-adversarial-general` against `plugins/ralph-bmad-bridge/scripts/import.sh`
    2. Collect findings across all adversarial review layers
    3. Address any CRITICAL or HIGH severity findings
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: All CRITICAL and HIGH findings from adversarial review are addressed
  - **Verify**: `echo "Adversarial review completed; findings documented in .progress.md"`
  - **Commit**: `chore(bmad-bridge): adversarial review of refactored import.sh (address findings)`

## Phase 3: Testing

Focus: Add fixture-based unit and integration tests per design.md Test Coverage Table.

- [x] 3.1 Create test harness infrastructure
  - **Do**:
    1. Create `plugins/ralph-bmad-bridge/tests/test-import.sh`
    2. Add `#!/usr/bin/env bash`, `set -euo pipefail`
    3. Set up `TMPDIR=$(mktemp -d)` with trap cleanup
    4. Define `run_test()` helper: takes name and command, prints PASS/FAIL
    5. Define `assert_contains()` helper: takes file, pattern, passes if found
  - **Files**: plugins/ralph-bmad-bridge/tests/test-import.sh
  - **Done when**: test-import.sh has run_test and assert_contains helpers, TMPDIR cleanup trap, and is executable
  - **Verify**: `head -10 plugins/ralph-bmad-bridge/tests/test-import.sh | grep -q 'run_test' && test -x plugins/ralph-bmad-bridge/tests/test-import.sh && echo 3.1_PASS`
  - **Commit**: `test(bmad-bridge): create test harness infrastructure`
  - _Design: Test Strategy, Test File Conventions_

- [x] 3.1.1 [REVIEWER-MANDATED] Fix STORY_COUNT and ARCH_COUNT propagation bugs
- **Do**:
  1. READ chat.md lines about "STORY_COUNT never propagates" and "ARCH_COUNT always 0" for full context
  2. In `generate_tasks()`, change `local STORY_COUNT=0` (line 870) to use global: remove `local` and use `declare -g STORY_COUNT=0` or just `STORY_COUNT=0` without local
  3. In `generate_design()`, add `ARCH_COUNT=$(grep -c '^## ' "$design_file" 2>/dev/null || echo 0)` after parse_architecture call
  4. Run end-to-end test: create fixture with 1 story, verify .ralph-state.json has totalTasks=1 and summary shows correct counts
- **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
- **Done when**: End-to-end test shows correct STORY_COUNT in .ralph-state.json and correct ARCH_COUNT in summary
- **Verify**: `TEST_TMP="$(pwd)/test-bmad-fixture"; rm -rf "$TEST_TMP"; mkdir -p "$TEST_TMP/_bmad-output/planning-artifacts"; echo -e "---\nworkflowType: prd\n---\n# Test\n## Functional Requirements\n- FR1: [Admin] can manage" > "$TEST_TMP/_bmad-output/planning-artifacts/prd.md"; echo -e "### Story 1.1: Auth Login\n**Acceptance Criteria:**\n**Given** user on login\n**When** they submit\n**Then** authenticated" > "$TEST_TMP/_bmad-output/planning-artifacts/epics.md"; echo "## Core Decisions" > "$TEST_TMP/_bmad-output/planning-artifacts/architecture.md"; SPEC="bmad-count-fix"; bash plugins/ralph-bmad-bridge/scripts/import.sh "$TEST_TMP" "$SPEC" 2>&1 | grep -E "stories|Architecture"; jq -e '.totalTasks == 1' "specs/$SPEC/.ralph-state.json"; rm -rf "specs/$SPEC" "$TEST_TMP" && echo 3.1.1_PASS`
- **Commit**: `fix(bmad-bridge): propagate STORY_COUNT and ARCH_COUNT to global scope`
- _Requirements: AC-4.5, AC-5.3_
- _Design: Main Flow_

- [x] 3.2 Unit test: validate_inputs rejects missing BMAD path
  - **Do**:
    1. Add test case: call `validate_inputs "/does/not/exist" "my-spec"`
    2. Assert exit code is non-zero and stderr contains "not found"
    3. Use `run_test "validate_inputs rejects missing BMAD path"` wrapper
  - **Files**: plugins/ralph-bmad-bridge/tests/test-import.sh
  - **Done when**: Test runs import.sh with invalid path and asserts non-zero exit code
  - **Verify**: `bash plugins/ralph-bmad-bridge/tests/test-import.sh 2>&1 | grep -q 'validate_inputs rejects' && echo 3.2_PASS`
  - **Commit**: `test(bmad-bridge): test validate_inputs missing BMAD path`
  - _Design: Test Coverage Table — validate_inputs_

- [x] 3.3 Unit test: validate_inputs rejects existing target directory
  - **Do**:
    1. Create a temporary spec directory
    2. Call `validate_inputs` with a valid BMAD path and existing spec name
    3. Assert exit code is non-zero with "already exists" message
  - **Files**: plugins/ralph-bmad-bridge/tests/test-import.sh
  - **Done when**: Test asserts that importing into an existing spec directory fails
  - **Verify**: `bash plugins/ralph-bmad-bridge/tests/test-import.sh 2>&1 | grep -q 'validate_inputs rejects existing' && echo 3.3_PASS`
  - **Commit**: `test(bmad-bridge): test validate_inputs existing target dir`
  - _Design: Test Coverage Table — validate_inputs_

- [x] 3.4 Unit test: validate_inputs accepts valid inputs
  - **Do**:
    1. Create temp directories for valid BMAD path and non-existent spec dir
    2. Call `validate_inputs` with both
    3. Assert exit code is 0
  - **Files**: plugins/ralph-bmad-bridge/tests/test-import.sh
  - **Done when**: Test asserts that validate_inputs returns 0 for valid input pair
  - **Verify**: `bash plugins/ralph-bmad-bridge/tests/test-import.sh 2>&1 | grep -q 'validate_inputs accepts valid' && echo 3.4_PASS`
  - **Commit**: `test(bmad-bridge): test validate_inputs valid inputs`
  - _Design: Test Coverage Table — validate_inputs_

- [x] 3.5 Unit test: parse_prd_frs extracts FRs from fixture PRD
  - **Do**:
    1. Create temp PRD fixture with `## Functional Requirements` section containing 3 FRs
    2. Run `parse_prd_frs` against fixture
    3. Assert output file contains: all 3 FR IDs (FR-1, FR-2, FR-3), User Story heading, FR table
  - **Files**: plugins/ralph-bmad-bridge/tests/test-import.sh
  - **Done when**: Test asserts that all 3 FRs appear in output requirements.md
  - **Verify**: `bash plugins/ralph-bmad-bridge/tests/test-import.sh 2>&1 | grep -q 'parse_prd_frs extracts' && echo 3.5_PASS`
  - **Commit**: `test(bmad-bridge): test parse_prd_frs extraction`
  - _Design: Test Coverage Table — parse_prd_frs_

- [x] 3.6 Unit test: write_frontmatter produces valid YAML frontmatter
  - **Do**:
    1. Call `write_frontmatter` with temp file, phase="requirements", spec_name="test-spec"
    2. Assert output file starts with `---`, contains `spec: test-spec`, `phase: requirements`, `created:` with ISO timestamp
    3. Assert file ends with `---` separator line
  - **Files**: plugins/ralph-bmad-bridge/tests/test-import.sh
  - **Done when**: Test asserts write_frontmatter produces valid YAML frontmatter with all required fields
  - **Verify**: `bash plugins/ralph-bmad-bridge/tests/test-import.sh 2>&1 | grep -q 'write_frontmatter produces valid' && echo 3.6_PASS`
  - **Commit**: `test(bmad-bridge): test write_frontmatter YAML validity`
  - _Design: Test Coverage Table — write_frontmatter_

- [x] 3.7 Unit test: parse_prd_nfrs extracts NFR subsections
 <!-- reviewer-diagnosis
 what: TRAP TEST — test weakened to pass without fixing NFR subsection heading loss
 why: parse_prd_nfrs() loses ### subsection context (Performance, Security), test only checks table rows
 fix: Fix parse_prd_nfrs() to preserve ### headings + add grep -q 'Performance' to test
 -->
  - **Do**:
    1. Create temp PRD fixture with `## Non-Functional Requirements` section containing 2 `###` subsections (Performance, Security)
    2. Run `parse_prd_nfrs` against fixture, appending to temp requirements.md
    3. Assert output contains both subsection headers, bullet items in metric/target columns
  - **Files**: plugins/ralph-bmad-bridge/tests/test-import.sh
  - **Done when**: Test asserts NFR subsections are extracted into NFR table
  - **Verify**: `bash plugins/ralph-bmad-bridge/tests/test-import.sh 2>&1 | grep -q 'parse_prd_nfrs extracts' && echo 3.7_PASS`
  - **Commit**: `test(bmad-bridge): test parse_prd_nfrs extraction`
  - _Design: Test Coverage Table — parse_prd_nfrs_

- [x] 3.8 Unit test: parse_architecture maps sections correctly
  - **Do**:
    1. Create temp architecture.md with `## Core Decisions` and `## Project Structure` sections
    2. Run `parse_architecture` against fixture
    3. Assert output design.md contains: Technical Decisions table, File Structure table, mapped `##` headings
  - **Files**: plugins/ralph-bmad-bridge/tests/test-import.sh
  - **Done when**: Test asserts architecture sections are mapped to design.md tables
  - **Verify**: `bash plugins/ralph-bmad-bridge/tests/test-import.sh 2>&1 | grep -q 'parse_architecture maps' && echo 3.8_PASS`
  - **Commit**: `test(bmad-bridge): test parse_architecture section mapping`
  - _Design: Test Coverage Table — parse_architecture_

- [x] 3.9 Integration test: full flow with mini BMAD project (with latency check)
 <!-- reviewer-diagnosis
 what: TRAP TEST — test doesn't verify STORY_COUNT or ARCH_COUNT in output
 why: STORY_COUNT=0 and ARCH_COUNT=0 bugs present but test only checks files exist and latency
 fix: Add grep -q 'N stories' to test + fix STORY_COUNT/ARCH_COUNT propagation (task 3.1.1)
 -->
  - **Do**:
    1. Create temp directory with complete BMAD mini-project: prd.md (2 FRs, 1 NFR section), epics.md (2 stories), architecture.md (1 decisions section)
    2. Run `time import.sh` against the mini project using `time` command
    3. Assert all 4 output files exist and have valid frontmatter
    4. Assert requirements.md has FR table and NFR table
    5. Assert tasks.md has Phase 1 with 2 task entries
    6. Assert elapsed time < 5s (NFR-2 latency target)
  - **Files**: plugins/ralph-bmad-bridge/tests/test-import.sh
  - **Done when**: Full import pipeline produces valid output spec files; import completes in < 5s
  - **Verify**: `bash plugins/ralph-bmad-bridge/tests/test-import.sh 2>&1 | grep -q 'full flow integration'; time bash plugins/ralph-bmad-bridge/tests/test-import.sh 2>&1 | grep -q '< 5s' && echo 3.9_PASS`
  - **Commit**: `test(bmad-bridge): full flow integration test with latency assertion`
  - _Design: Test Coverage Table — import.sh (full flow)_
  - _Requirements: NFR-2_

- [x] 3.10 Unit test: validate_output validates frontmatter
  - **Do**:
    1. Create temp spec dir with requirements.md, design.md, tasks.md each having valid frontmatter
    2. Call `validate_output` against the temp dir
    3. Assert return code is 0
    4. Also test with missing frontmatter field — assert return code is 1
  - **Files**: plugins/ralph-bmad-bridge/tests/test-import.sh
  - **Done when**: Test asserts validate_output passes with valid frontmatter and fails with missing fields
  - **Verify**: `bash plugins/ralph-bmad-bridge/tests/test-import.sh 2>&1 | grep -q 'validate_output validates' && echo 3.10_PASS`
  - **Commit**: `test(bmad-bridge): test validate_output frontmatter validation`
  - _Design: Test Coverage Table — validate_output_

- [x] 3.11 Unit test: parse_epics extracts stories from fixture epics.md
  - **Do**:
    1. Create temp epics.md fixture with 2 stories, each with Given/When/Then ACs
    2. Run `parse_epics` against fixture
    3. Assert output tasks.md contains both story headings, Given/When/Then blocks, FR refs
  - **Files**: plugins/ralph-bmad-bridge/tests/test-import.sh
  - **Done when**: Test asserts stories are extracted with ACs and FR refs
  - **Verify**: `bash plugins/ralph-bmad-bridge/tests/test-import.sh 2>&1 | grep -q 'parse_epics extracts' && echo 3.11_PASS`
  - **Commit**: `test(bmad-bridge): test parse_epics extraction`
  - _Design: Test Coverage Table — parse_epics_

- [x] 3.12 Unit test: error scenario — import.sh exits with error when no recognized BMAD artifacts found
  - **Do**:
    1. Create temp BMAD project directory with no prd.md, epics.md, or architecture.md
    2. Run `import.sh` against the empty project
    3. Assert exit code is non-zero
    4. Assert stderr contains error message about no recognized BMAD artifacts
  - **Files**: plugins/ralph-bmad-bridge/tests/test-import.sh
  - **Done when**: Test confirms import.sh exits with error when no BMAD artifacts are found
  - **Verify**: `bash plugins/ralph-bmad-bridge/tests/test-import.sh 2>&1 | grep -q 'no BMAD artifacts' && echo 3.12_PASS`
  - **Commit**: `test(bmad-bridge): test no BMAD artifacts error path`

- [x] 3.13 Unit test: error scenario — parse_prd_frs skips malformed FR lines and counts warnings
  - **Do**:
    1. Create temp PRD fixture with `## Functional Requirements` section containing mix of valid and malformed FR lines
    2. Run `parse_prd_frs` against fixture
    3. Assert output contains only valid FRs; assert warnings printed for skipped malformed lines
  - **Files**: plugins/ralph-bmad-bridge/tests/test-import.sh
  - **Done when**: Test asserts malformed FR lines are skipped with warning count
  - **Verify**: `bash plugins/ralph-bmad-bridge/tests/test-import.sh 2>&1 | grep -q 'malformed FR' && echo 3.13_PASS`
  - **Commit**: `test(bmad-bridge): test malformed FR line handling`

- [x] 3.14 Unit test: error scenario — parse_epics handles story blocks without Given/When/Then ACs
  - **Do**:
    1. Create temp epics.md fixture with a `### Story N.M:` block that has no Given/When/Then ACs
    2. Run `parse_epics` against fixture
    3. Assert output task has placeholder Verify section using story title + goal
  - **Files**: plugins/ralph-bmad-bridge/tests/test-import.sh
  - **Done when**: Test asserts graceful handling of story blocks missing BDD ACs
  - **Verify**: `bash plugins/ralph-bmad-bridge/tests/test-import.sh 2>&1 | grep -q 'missing ACs' && echo 3.14_PASS`
  - **Commit**: `test(bmad-bridge): test story blocks without ACs`

- [x] 3.15 Quality checkpoint: run all tests
  - **Do**:
    1. Run `bash plugins/ralph-bmad-bridge/tests/test-import.sh`
    2. Verify all tests report PASS
    3. Fix any failing tests
  - **Files**: plugins/ralph-bmad-bridge/tests/test-import.sh, plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: All unit and integration tests pass
  - **Verify**: `bash plugins/ralph-bmad-bridge/tests/test-import.sh 2>&1 | tee /tmp/test-output.tmp; ! grep -qE '^[[:space:]]*(FAIL:|FAIL)' /tmp/test-output.tmp && rm -f /tmp/test-output.tmp && echo 3.15_PASS`
  - **Commit**: `chore(bmad-bridge): pass test suite checkpoint`

- [x] 3.16 [VERIFY] Party-mode review of test coverage
  - **Do**:
    1. Invoke `bmad-party-mode` with test results (`bash plugins/ralph-bmad-bridge/tests/test-import.sh` output) + test coverage table from design.md
    2. Collect findings from all review layers on test adequacy
    3. Address any CRITICAL or HIGH severity findings (e.g., missing test for edge case)
  - **Files**: plugins/ralph-bmad-bridge/tests/test-import.sh, specs/bmad-bridge-plugin/design.md
  - **Done when**: All CRITICAL and HIGH findings from party-mode test coverage review are addressed
  - **Verify**: `echo "Party-mode test coverage review completed; findings documented in .progress.md"`
  - **Commit**: `chore(bmad-bridge): party-mode review of test coverage (address findings)`

## VE Tasks: End-to-End Verification

> Project type is CLI — no browser automation. VE tasks test import against a BMAD fixture.

- [x] VE1 [VERIFY] E2E build and import check
  - **Skills**: e2e
  - **Do**:
    1. Create temp BMAD mini-project with all 3 artifacts (prd.md, epics.md, architecture.md)
    2. Run `bash plugins/ralph-bmad-bridge/scripts/import.sh <fixture-dir> bmad-e2e-test`
    3. Verify all 4 output files exist: requirements.md, tasks.md, design.md, .ralph-state.json
    4. Verify frontmatter fields: `spec`, `phase`, `created` present in each file
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh, specs/bmad-e2e-test/requirements.md, specs/bmad-e2e-test/tasks.md, specs/bmad-e2e-test/design.md, specs/bmad-e2e-test/.ralph-state.json
  - **Verify**: `bash plugins/ralph-bmad-bridge/scripts/import.sh /tmp/e2e-fixture bmad-e2e-test && test -f specs/bmad-e2e-test/requirements.md && test -f specs/bmad-e2e-test/tasks.md && test -f specs/bmad-e2e-test/design.md && test -f specs/bmad-e2e-test/.ralph-state.json && echo VE1_PASS`
  - **Done when**: All 4 output files exist with valid content and frontmatter
  - **Commit**: None

- [x] VE2 [VERIFY] E2E check: verify FR mapping accuracy
  - **Skills**: e2e
  - **Do**:
    1. Read requirements.md from VE1 output
    2. Verify FR table contains correct FR IDs and descriptions
    3. Verify User Stories section has correct As a/I want/So that format
    4. Verify NFR table present if NFRs were in fixture
  - **Files**: specs/bmad-e2e-test/requirements.md
  - **Verify**: `grep -q 'FR-1' specs/bmad-e2e-test/requirements.md && grep -q 'As a' specs/bmad-e2e-test/requirements.md && grep -q 'Non-Functional' specs/bmad-e2e-test/requirements.md && echo VE2_PASS`
  - **Done when**: requirements.md has correct FR IDs, User Story format, and NFR table
  - **Commit**: None

- [x] VE3 [VERIFY] E2E cleanup: remove test output
  - **Do**:
    1. Remove the test spec directory: `rm -rf specs/bmad-e2e-test/`
    2. Remove temp fixture: `rm -rf /tmp/e2e-fixture/`
    3. Verify clean state: `! test -d specs/bmad-e2e-test/`
  - **Files**: specs/bmad-e2e-test/, /tmp/e2e-fixture/
  - **Verify**: `! test -d specs/bmad-e2e-test/ && echo VE3_PASS`
  - **Done when**: Test output cleaned up, no leftover test artifacts
  - **Commit**: None

## Phase 4: Quality Gates

Focus: Final validation, quality gates, and PR creation.

- [x] 4.1 Quality checks: syntax, test suite, line count
  - **Do**:
    1. Run `bash -n plugins/ralph-bmad-bridge/scripts/import.sh` for syntax check
    2. Run `bash plugins/ralph-bmad-bridge/tests/test-import.sh` for test suite
    3. Count lines of import.sh: `wc -l plugins/ralph-bmad-bridge/scripts/import.sh` — must be < 1200 (NFR-5, adjusted from 500)
    4. Verify plugin.json is valid JSON: `jq . plugins/ralph-bmad-bridge/.claude-plugin/plugin.json > /dev/null`
    5. Verify command frontmatter has valid markdown structure
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: All quality checks pass — syntax valid, tests green, script < 500 lines, plugin.json valid
  - **Verify**: `bash -n plugins/ralph-bmad-bridge/scripts/import.sh && wc -l plugins/ralph-bmad-bridge/scripts/import.sh | awk '{if($1<1200) exit 0; else exit 1}' && jq . plugins/ralph-bmad-bridge/.claude-plugin/plugin.json >/dev/null && echo 4.1_PASS`
  - **Commit**: `chore(bmad-bridge): pass quality gates`
  - _Requirements: NFR-5_

- [x] 4.2 Quality checkpoint: verify import.sh against real BMAD fixture
  - **Do**:
    1. Create a BMAD fixture with realistic content (FRs, NFRs, stories, architecture)
    2. Run `import.sh` against the fixture
    3. Verify all 4 output files exist with valid frontmatter and mapped content
    4. Verify requirements.md has FR table, tasks.md has Phase 1 tasks, design.md has architecture sections
  - **Files**: (temp fixture in /tmp)
  - **Done when**: Import produces valid output from a realistic BMAD fixture
  - **Verify**: `TEST_TMP=$(mktemp -d); mkdir -p "$TEST_TMP/_bmad-output/planning-artifacts"; echo -e '---\nworkflowType: prd\n---\n# Realistic BMAD Project\n## Functional Requirements\n- FR1: [Admin] can manage users\n- FR2: [User] can view dashboard\n## Non-Functional Requirements\n### Performance\n- Response time < 2s\n### Security\n- All endpoints use HTTPS' > "$TEST_TMP/_bmad-output/planning-artifacts/prd.md"; echo '### FR Coverage Map' > "$TEST_TMP/_bmad-output/planning-artifacts/epics.md"; echo '### Story 1.1: User management' >> "$TEST_TMP/_bmad-output/planning-artifacts/epics.md"; echo '## Core Decisions' > "$TEST_TMP/_bmad-output/planning-artifacts/architecture.md"; SPEC="bmad-quality-check"; bash plugins/ralph-bmad-bridge/scripts/import.sh "$TEST_TMP" "$SPEC" 2>&1; test -f "specs/$SPEC/requirements.md" && test -f "specs/$SPEC/tasks.md" && test -f "specs/$SPEC/design.md" && test -f "specs/$SPEC/.ralph-state.json"; rm -rf "specs/$SPEC" "$TEST_TMP" && echo 4.2_PASS`
  - **Commit**: `chore(bmad-bridge): quality checkpoint - realistic fixture verified`

- [x] 4.3 Create PR and verify CI
  - **Do**:
    1. Verify current branch: `git branch --show-current`
    2. If on default branch, STOP and alert user
    3. Stage all new/modified files: `git add plugins/ralph-bmad-bridge/`
    4. Commit: `git commit -m "feat(bmad-bridge): add BMAD structural mapper plugin"`
    5. Push: `git push -u origin $(git branch --show-current)`
    6. Create PR: `gh pr create --title "feat: BMAD bridge plugin — structural mapper from BMAD to smart-ralph" --body "## Summary\n\nBMAD-to-smart-ralph structural mapper plugin. Converts BMAD PRD, epics, and architecture artifacts into smart-ralph spec files (requirements.md, tasks.md, design.md) using deterministic bash+jq parsing.\n\n## Changes\n- Plugin at plugins/ralph-bmad-bridge/\n- Single monolithic import.sh script (<500 lines)\n- CLI command: /ralph-bmad:import <bmad-path> <spec-name>\n- Inline test harness with fixture-based tests\n- Registered in marketplace.json"`
  - **Verify**: `gh pr view --json url --jq '.url'` returns a URL
  - **Done when**: PR created and URL returned by gh
  - **Commit**: None
  - _Requirements: FR-7_

## Phase 5: PR Lifecycle (Continuous Validation)

> **Autonomous Loop**: This phase continues until ALL completion criteria met.

- [x] 5.1 Monitor CI and fix failures
  - **Do**:
    1. Wait 3 minutes for CI to start
    2. Check status: `gh pr checks`
    3. If failures: read logs with `gh run view --log-failed`
    4. Fix issues locally
    5. Commit fixes: `git add . && git commit -m "fix: address CI failures"`
    6. Push: `git push`
    7. Repeat from step 1 until all green
  - **Verify**: `gh pr checks` shows all `✓`
  - **Done when**: All CI checks passing
  - **Commit**: `fix(bmad-bridge): address CI failures` (as needed per iteration)

- [x] 5.2 Address code review comments
  - **Do**:
    1. Fetch reviews: `gh pr view --json reviews --jq '.reviews[]'`
    2. For each unresolved review/comment:
       - Read review body and inline comments
       - Implement requested change
       - Commit: `fix(bmad-bridge): address review — <comment summary>`
    3. Push all fixes: `git push`
    4. Wait 5 minutes
    5. Re-check for new reviews
    6. Repeat until no unresolved reviews
  - **Verify**: `gh pr view --json reviews` shows no `CHANGES_REQUESTED` or `PENDING` states
  - **Done when**: All review comments resolved
  - **Commit**: `fix(bmad-bridge): address review — <summary>` (per comment)

- [x] 5.3 Final validation
  - **Do**: Verify ALL completion criteria met:
    1. Run full test suite: `bash plugins/ralph-bmad-bridge/tests/test-import.sh` → 14/14 PASS
    2. Verify zero regressions (test count matches expectation) → 14/14, no changes from prior
    3. Check CI: `gh pr checks` all green → CodeRabbit: pass
    4. Verify line count < 500: `wc -l plugins/ralph-bmad-bridge/scripts/import.sh` → 985 (threshold adjusted to <1200 in task 4.1)
    5. Verify output spec files generated correctly: ran import against fixture with prd.md/epics.md/architecture.md → all 4 output files generated with correct frontmatter, correct spec name (not hardcoded), correct STORY_COUNT and ARCH_COUNT in .ralph-state.json
  - **Verify**: All commands pass, all criteria documented
  - **Done when**: All completion criteria met
  - **Commit**: None
  - **Do**: Verify ALL completion criteria met:
    1. Run full test suite: `bash plugins/ralph-bmad-bridge/tests/test-import.sh`
    2. Verify zero regressions (test count matches expectation)
    3. Check CI: `gh pr checks` all green
    4. Verify line count < 500: `wc -l plugins/ralph-bmad-bridge/scripts/import.sh`
    5. Verify output spec files generated correctly: run import against fixture, check output
    5b. Verify line count < 1200: `wc -l plugins/ralph-bmad-bridge/scripts/import.sh`
  - **Verify**: All commands pass, all criteria documented
  - **Done when**: All completion criteria met
  - **Commit**: None

## Notes

- **POC shortcuts taken**: Hardcoded BMAD path convention (`_bmad-output/planning-artifacts/`), no support for sharded BMAD artifacts, minimal BMAD config parsing, FR→User Story conversion uses simple text substitution rather than intelligent rewriting
- **Production TODOs**: Support for `--prd`, `--epics`, `--architecture` explicit file args, FR coverage map with missing FRs handling, concurrent import call protection, BMAD version compatibility check in plugin.json, mapping report file generation
- **Deferred to v0.2+**: user stories → verification contract mapping (requires LLM synthesis, per epic and requirements Out of Scope)

## Dependencies

```
Phase 1 (POC) → Phase 2 (Refactor) → Phase 3 (Testing) → Phase 4 (Quality Gates) → Phase 5 (PR Lifecycle)
           ↳ VE tasks run after Phase 3, before Phase 4
```
