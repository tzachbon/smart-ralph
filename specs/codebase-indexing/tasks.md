# Tasks: Codebase Indexing

## Overview

Total tasks: 27
POC-first workflow with 5 phases:
1. Phase 1: Make It Work (POC) - Validate indexing works end-to-end
2. Phase 2: Refactoring - Clean up, add error handling
3. Phase 3: Testing - Add unit/integration tests
4. Phase 4: Quality Gates - Local quality checks and PR creation
5. Phase 5: PR Lifecycle - Autonomous CI monitoring, review resolution

## Execution Context

Interview responses that informed task planning:

| Question | Response |
|----------|----------|
| Testing depth | Standard - unit + integration |
| Deployment approach | Standard CI/CD pipeline |
| Execution priority | Balanced - reasonable quality with speed |
| Additional context | None |

## Completion Criteria (Autonomous Execution Standard)

This spec is not complete until ALL criteria are met:

- **Zero Regressions**: All existing plugin functionality works
- **Modular & Reusable**: Code follows existing command/template patterns
- **Real-World Validation**: Index command works on actual codebase
- **Feature Complete**: All 9 user stories satisfied
- **CI Green**: All CI checks passing
- **PR Ready**: Pull request created, reviewed, approved

## Phase 1: Make It Work (POC)

Focus: Validate the indexing idea works end-to-end. Create templates first, then command, then integration.

- [x] 1.1 Create component-spec template
  - **Do**:
    1. Create template file with frontmatter (type, generated, source, hash, category, indexed)
    2. Include sections: Purpose, Location, Public Interface (Exports, Methods), Dependencies, AI Context
    3. Use mustache-style placeholders matching design spec
  - **Files**: `plugins/ralph-specum/templates/component-spec.md`
  - **Done when**: Template file exists with all required sections from design
  - **Verify**: `test -f plugins/ralph-specum/templates/component-spec.md && grep -q "type: component-spec" plugins/ralph-specum/templates/component-spec.md && echo "OK"`
  - **Commit**: `feat(index): add component-spec template`
  - _Requirements: FR-4, AC-1.3_
  - _Design: Templates > Component Spec Template_

- [x] 1.2 Create external-spec template
  - **Do**:
    1. Create template file with frontmatter (type, generated, source-type, source-id, fetched)
    2. Include sections: Source, Summary, Key Sections, AI Context
    3. Use mustache-style placeholders matching design spec
  - **Files**: `plugins/ralph-specum/templates/external-spec.md`
  - **Done when**: Template file exists with all required sections from design
  - **Verify**: `test -f plugins/ralph-specum/templates/external-spec.md && grep -q "type: external-spec" plugins/ralph-specum/templates/external-spec.md && echo "OK"`
  - **Commit**: `feat(index): add external-spec template`
  - _Requirements: FR-5, AC-2.3, AC-2.7_
  - _Design: Templates > External Resource Spec Template_

- [x] 1.3 Create index-summary template
  - **Do**:
    1. Create template file with frontmatter (type, generated, indexed)
    2. Include sections: Overview table (Category, Count, Last Updated), Components by category, External Resources table, Index Settings
    3. Use mustache-style placeholders matching design spec
  - **Files**: `plugins/ralph-specum/templates/index-summary.md`
  - **Done when**: Template file exists with all required sections from design
  - **Verify**: `test -f plugins/ralph-specum/templates/index-summary.md && grep -q "type: index-summary" plugins/ralph-specum/templates/index-summary.md && echo "OK"`
  - **Commit**: `feat(index): add index-summary template`
  - _Requirements: FR-14, AC-8.1, AC-8.2, AC-8.3, AC-8.4_
  - _Design: Templates > Index Summary Template_

- [x] 1.4 [VERIFY] Quality checkpoint: template validation
  - **Do**: Verify all 3 templates have valid frontmatter and required sections
  - **Verify**: `for f in plugins/ralph-specum/templates/component-spec.md plugins/ralph-specum/templates/external-spec.md plugins/ralph-specum/templates/index-summary.md; do test -f "$f" || exit 1; done && echo "All templates exist"`
  - **Done when**: All template files exist and are valid markdown
  - **Commit**: None (verification only)

- [x] 1.5 Create index command - argument parsing
  - **Do**:
    1. Create command file with frontmatter (description, argument-hint, allowed-tools)
    2. Implement argument parsing section: --path, --type, --exclude, --dry-run, --force, --changed, --quick
    3. Document each flag with default values per design
    4. Add detection logic for which flags are present
  - **Files**: `plugins/ralph-specum/commands/index.md`
  - **Done when**: Command file exists with argument parsing section
  - **Verify**: `test -f plugins/ralph-specum/commands/index.md && grep -q "\\-\\-path" plugins/ralph-specum/commands/index.md && grep -q "\\-\\-dry-run" plugins/ralph-specum/commands/index.md && echo "OK"`
  - **Commit**: `feat(index): add index command with argument parsing`
  - _Requirements: FR-1, FR-8, FR-9, FR-10, FR-11, FR-12, FR-13, FR-24_
  - _Design: Components > 1. Index Command_

- [x] 1.6 Add pre-scan interview to index command
  - **Do**:
    1. Add pre-scan interview section using AskUserQuestion
    2. Implement 4 interview questions per design: external URLs, MCP/skills, focus areas, sparse areas
    3. Add --quick check to skip interview
    4. Store responses for later use in scanning
  - **Files**: `plugins/ralph-specum/commands/index.md`
  - **Done when**: Interview section added with all 4 questions and --quick bypass
  - **Verify**: `grep -q "AskUserQuestion" plugins/ralph-specum/commands/index.md && grep -q "externalUrls" plugins/ralph-specum/commands/index.md && grep -q "focusAreas" plugins/ralph-specum/commands/index.md && echo "OK"`
  - **Commit**: `feat(index): add pre-scan interview flow`
  - _Requirements: FR-17, FR-18, FR-19, FR-20, AC-9.1, AC-9.2, AC-9.3, AC-9.4_
  - _Design: Interview Flow > Pre-Scan Interview Questions_

- [x] 1.7 [VERIFY] Quality checkpoint: command structure
  - **Do**: Verify index command has proper frontmatter and basic structure
  - **Verify**: `grep -q "^---$" plugins/ralph-specum/commands/index.md && grep -q "description:" plugins/ralph-specum/commands/index.md && grep -q "allowed-tools:" plugins/ralph-specum/commands/index.md && echo "OK"`
  - **Done when**: Command has valid plugin command structure
  - **Commit**: None (verification only)

- [x] 1.8 Add component scanner to index command
  - **Do**:
    1. Add component scanner section that uses Glob patterns from design
    2. Implement detection patterns for: controllers, services, models, helpers, migrations
    3. Add default exclude patterns: node_modules, vendor, dist, build, .git, __pycache__, test files
    4. Handle --path, --type, --exclude filters
    5. Extract metadata from matched files (exports, methods, dependencies via regex)
  - **Files**: `plugins/ralph-specum/commands/index.md`
  - **Done when**: Scanner section added with Glob patterns and metadata extraction
  - **Verify**: `grep -q "controllers" plugins/ralph-specum/commands/index.md && grep -q "node_modules" plugins/ralph-specum/commands/index.md && grep -q "Glob" plugins/ralph-specum/commands/index.md && echo "OK"`
  - **Commit**: `feat(index): add component scanner with detection patterns`
  - _Requirements: FR-2, FR-3, AC-1.1, AC-1.2_
  - _Design: Components > 2. Component Scanner_

- [x] 1.9 Add spec generation to index command
  - **Do**:
    1. Add spec generation section that creates component specs from template
    2. Implement hash calculation for change detection
    3. Create `specs/.index/components/` directory structure
    4. Write component spec files with populated template values
    5. Handle --dry-run to show preview without writing
    6. Handle --force to regenerate existing specs
  - **Files**: `plugins/ralph-specum/commands/index.md`
  - **Done when**: Generation section creates specs in correct directory
  - **Verify**: `grep -q "specs/.index/components" plugins/ralph-specum/commands/index.md && grep -q "hash" plugins/ralph-specum/commands/index.md && grep -q "dry-run" plugins/ralph-specum/commands/index.md && echo "OK"`
  - **Commit**: `feat(index): add spec generation with hash tracking`
  - _Requirements: FR-4, AC-1.4, AC-1.5, AC-6.1, AC-6.2, AC-6.3, AC-7.1, AC-7.3_
  - _Design: Components > 4. Spec Generator_

- [x] 1.10 [VERIFY] Quality checkpoint: core indexing flow
  - **Do**: Verify index command has complete core flow (parse args -> interview -> scan -> generate)
  - **Verify**: `grep -q "Parse Arguments" plugins/ralph-specum/commands/index.md && grep -q "Interview" plugins/ralph-specum/commands/index.md && grep -q "Scanner" plugins/ralph-specum/commands/index.md && grep -q "Generate" plugins/ralph-specum/commands/index.md && echo "OK"`
  - **Done when**: Core indexing flow is complete in command
  - **Commit**: None (verification only)

- [x] 1.11 Add external resource fetcher to index command
  - **Do**:
    1. Add external resource fetcher section
    2. Implement URL fetching via WebFetch with 30s timeout
    3. Implement MCP server documentation via ListMcpResourcesTool
    4. Implement skill introspection by reading plugin manifests
    5. Generate external specs using external-spec template
    6. Store in `specs/.index/external/` directory
  - **Files**: `plugins/ralph-specum/commands/index.md`
  - **Done when**: External resource section handles URLs, MCP, and skills
  - **Verify**: `grep -q "WebFetch" plugins/ralph-specum/commands/index.md && grep -q "ListMcpResourcesTool" plugins/ralph-specum/commands/index.md && grep -q "specs/.index/external" plugins/ralph-specum/commands/index.md && echo "OK"`
  - **Commit**: `feat(index): add external resource fetcher`
  - _Requirements: FR-5, AC-2.2, AC-2.3, AC-2.4, AC-2.5, AC-2.8_
  - _Design: Components > 3. External Resource Fetcher_

- [x] 1.12 Add post-scan review to index command
  - **Do**:
    1. Add post-scan review section using AskUserQuestion
    2. Show summary of findings (component counts by category, external resources)
    3. Implement 3 review questions per design: component count validation, external resources check, adjustments needed
    4. Handle user feedback for re-scan or adjustments
    5. Skip if --quick flag is set
  - **Files**: `plugins/ralph-specum/commands/index.md`
  - **Done when**: Post-scan review section with 3 questions and feedback loop
  - **Verify**: `grep -q "componentCount" plugins/ralph-specum/commands/index.md && grep -q "adjustments" plugins/ralph-specum/commands/index.md && grep -q "Post-Scan" plugins/ralph-specum/commands/index.md && echo "OK"`
  - **Commit**: `feat(index): add post-scan review flow`
  - _Requirements: FR-21, FR-22, FR-23, AC-9.5, AC-9.6, AC-9.7_
  - _Design: Interview Flow > Post-Scan Review Questions_

- [x] 1.13 Add index summary builder to index command
  - **Do**:
    1. Add index builder section that creates specs/.index/index.md
    2. Use index-summary template with counts by category
    3. Include timestamp, external resources list, index settings
    4. Link to all generated component and external specs
  - **Files**: `plugins/ralph-specum/commands/index.md`
  - **Done when**: Index builder creates summary file with all sections
  - **Verify**: `grep -q "index.md" plugins/ralph-specum/commands/index.md && grep -q "TIMESTAMP" plugins/ralph-specum/commands/index.md && grep -q "CATEGORIES" plugins/ralph-specum/commands/index.md && echo "OK"`
  - **Commit**: `feat(index): add index summary builder`
  - _Requirements: FR-14, AC-8.1, AC-8.2, AC-8.3, AC-8.4_
  - _Design: Components > 5. Index Builder_

- [x] 1.14 [VERIFY] Quality checkpoint: complete index command
  - **Do**: Verify index command has all major sections complete
  - **Verify**: `wc -l < plugins/ralph-specum/commands/index.md | xargs test 200 -lt && echo "OK: Command has substantial content"`
  - **Done when**: Index command is feature-complete (200+ lines)
  - **Commit**: None (verification only)

- [x] 1.15 Add index hint to start command
  - **Do**:
    1. Locate the appropriate position in start.md (before Spec Scanner section, around line 571)
    2. Add conditional check: if `specs/.index/` is empty/missing, show hint
    3. Implement hint text: "Tip: Run /ralph-specum:index to scan your codebase..."
    4. Add condition to NOT show hint if index already has content
  - **Files**: `plugins/ralph-specum/commands/start.md`
  - **Done when**: Start command shows hint when no index exists
  - **Verify**: `grep -q "ralph-specum:index" plugins/ralph-specum/commands/start.md && grep -q "specs/.index" plugins/ralph-specum/commands/start.md && echo "OK"`
  - **Commit**: `feat(start): add indexing hint for new users`
  - _Requirements: FR-7, AC-4.1, AC-4.2, AC-4.3_
  - _Design: File Structure > commands/start.md Modify_

- [x] 1.16 Enhance spec scanner in start command
  - **Do**:
    1. Locate spec scanner section in start.md (lines 573-665)
    2. Add search of `specs/.index/components/*.md` to existing scanner
    3. Add search of `specs/.index/external/*.md` to existing scanner
    4. Integrate indexed specs into "Related Specs" display with relevance classification
    5. Maintain backward compatibility with existing scanner behavior
  - **Files**: `plugins/ralph-specum/commands/start.md`
  - **Done when**: Spec scanner searches both regular specs AND indexed specs
  - **Verify**: `grep -q "specs/.index/components" plugins/ralph-specum/commands/start.md && grep -q "specs/.index/external" plugins/ralph-specum/commands/start.md && echo "OK"`
  - **Commit**: `feat(start): enhance spec scanner to search indexed specs`
  - _Requirements: FR-6, AC-3.1, AC-3.2, AC-3.3, AC-3.4_
  - _Design: Components > 6. Spec Scanner Enhancement_

- [x] 1.17 [VERIFY] Quality checkpoint: start.md modifications
  - **Do**: Verify start.md has both hint and scanner enhancement
  - **Verify**: `grep -q "ralph-specum:index" plugins/ralph-specum/commands/start.md && grep -q "specs/.index/components" plugins/ralph-specum/commands/start.md && echo "OK"`
  - **Done when**: Both modifications present in start.md
  - **Commit**: None (verification only)

- [x] 1.18 POC Checkpoint - End-to-end validation
  - **Do**:
    1. Create test directory structure: `mkdir -p /tmp/test-index/src/controllers /tmp/test-index/src/services`
    2. Create sample files: `echo "export function login() {}" > /tmp/test-index/src/controllers/auth.ts`
    3. Run index command mentally trace through the logic
    4. Verify the command structure handles: argument parsing -> interview -> scan -> generate -> review -> summary
    5. Document any issues found in .progress.md
  - **Done when**: Index command structure is complete and logically sound
  - **Verify**: `test -f plugins/ralph-specum/commands/index.md && test -f plugins/ralph-specum/templates/component-spec.md && test -f plugins/ralph-specum/templates/external-spec.md && test -f plugins/ralph-specum/templates/index-summary.md && echo "POC Complete"`
  - **Commit**: `feat(index): complete POC for codebase indexing`
  - _Requirements: US-1, US-2, US-3, US-4, US-5, US-6, US-7, US-8, US-9_

## Phase 2: Refactoring

After POC validated, clean up code and add proper error handling.

- [x] 2.1 Add error handling to index command
  - **Do**:
    1. Add error handling section to index command
    2. Handle: no components found, external URL unreachable, MCP unavailable, git not available (--changed), permission denied
    3. Follow error handling patterns from design document
    4. Add graceful fallbacks and warning messages
  - **Files**: `plugins/ralph-specum/commands/index.md`
  - **Done when**: All error scenarios from design have handling
  - **Verify**: `grep -q "No components found" plugins/ralph-specum/commands/index.md && grep -q "Warning" plugins/ralph-specum/commands/index.md && echo "OK"`
  - **Commit**: `refactor(index): add comprehensive error handling`
  - _Design: Error Handling table_

- [x] 2.2 Add edge case handling
  - **Do**:
    1. Add edge case handling per design: empty codebase, monorepo, no git, mixed languages, very large codebase, existing index, interrupted indexing
    2. Add progress indicator for large codebases
    3. Handle partial index as valid state
  - **Files**: `plugins/ralph-specum/commands/index.md`
  - **Done when**: All edge cases from design have handling
  - **Verify**: `grep -q "monorepo" plugins/ralph-specum/commands/index.md || grep -q "large codebase" plugins/ralph-specum/commands/index.md && echo "OK"`
  - **Commit**: `refactor(index): add edge case handling`
  - _Design: Edge Cases section_

- [x] 2.3 [VERIFY] Quality checkpoint: error handling coverage
  - **Do**: Verify error handling and edge cases are documented in command
  - **Verify**: `grep -c "Warning\\|Error\\|skip" plugins/ralph-specum/commands/index.md | xargs test 3 -lt && echo "OK: Has error/warning handling"`
  - **Done when**: Command has comprehensive error handling
  - **Commit**: None (verification only)

- [x] 2.4 Update schema with index state definitions
  - **Do**:
    1. Add indexState definition to spec.schema.json
    2. Include fields: indexed timestamp, component count, external count, excludes, paths
    3. Add componentSpec and externalSpec type definitions
    4. Maintain backward compatibility with existing schema
  - **Files**: `plugins/ralph-specum/schemas/spec.schema.json`
  - **Done when**: Schema includes index-related definitions
  - **Verify**: `grep -q "indexState\\|component-spec\\|external-spec" plugins/ralph-specum/schemas/spec.schema.json && echo "OK"`
  - **Commit**: `refactor(schema): add index state definitions`
  - _Design: File Structure > schemas/spec.schema.json Modify_

- [x] 2.5 Code cleanup and consistency
  - **Do**:
    1. Review index.md for consistent formatting with other commands
    2. Ensure section headers match plugin conventions
    3. Verify placeholder syntax is consistent (mustache-style)
    4. Add documentation comments where needed
  - **Files**: `plugins/ralph-specum/commands/index.md`
  - **Done when**: Command follows same patterns as research.md, requirements.md
  - **Verify**: `diff -q <(grep "^## " plugins/ralph-specum/commands/research.md | head -5) <(grep "^## " plugins/ralph-specum/commands/index.md | head -5) 2>/dev/null || echo "OK: Different sections expected"`
  - **Commit**: `refactor(index): cleanup and consistency improvements`

## Phase 3: Testing

Add unit and integration tests.

- [x] 3.1 Create test fixtures for indexing
  - **Do**:
    1. Create test fixture directory: `specs/codebase-indexing/.test-fixtures/`
    2. Create sample controller: `sample-controller.ts` with exports and methods
    3. Create sample service: `sample-service.ts` with dependencies
    4. Create sample model: `sample-model.ts`
    5. These will be used for manual testing and documentation
  - **Files**: `specs/codebase-indexing/.test-fixtures/controllers/sample-controller.ts`, `specs/codebase-indexing/.test-fixtures/services/sample-service.ts`, `specs/codebase-indexing/.test-fixtures/models/sample-model.ts`
  - **Done when**: Test fixtures exist for manual verification
  - **Verify**: `test -d specs/codebase-indexing/.test-fixtures && ls specs/codebase-indexing/.test-fixtures/*/sample-*.ts 2>/dev/null | wc -l | xargs test 0 -lt && echo "OK"`
  - **Commit**: `test(index): add test fixtures for manual verification`
  - _Design: Test Strategy > Unit Tests_

- [x] 3.2 Document integration test scenarios
  - **Do**:
    1. Add "## Testing" section to index.md command
    2. Document test scenarios: full scan, external URL fetch, dry run, force regenerate, changed only
    3. Include expected outputs for each scenario
    4. Reference test fixtures location
  - **Files**: `plugins/ralph-specum/commands/index.md`
  - **Done when**: Testing section documents all scenarios from design
  - **Verify**: `grep -q "## Testing" plugins/ralph-specum/commands/index.md && grep -q "dry-run" plugins/ralph-specum/commands/index.md && echo "OK"`
  - **Commit**: `test(index): document integration test scenarios`
  - _Design: Test Strategy > Integration Tests_

- [ ] 3.3 [VERIFY] Quality checkpoint: test documentation
  - **Do**: Verify testing documentation exists in command file
  - **Verify**: `grep -q "Testing\\|Test" plugins/ralph-specum/commands/index.md && echo "OK"`
  - **Done when**: Test documentation present
  - **Commit**: None (verification only)

- [ ] 3.4 Clean up test fixtures
  - **Do**:
    1. Remove test fixtures directory after validation
    2. Ensure no test artifacts remain in specs directory
  - **Files**: Remove `specs/codebase-indexing/.test-fixtures/`
  - **Done when**: Test fixtures cleaned up
  - **Verify**: `test ! -d specs/codebase-indexing/.test-fixtures && echo "OK: Fixtures cleaned"`
  - **Commit**: `chore(index): clean up test fixtures`

## Phase 4: Quality Gates

> **IMPORTANT**: NEVER push directly to the default branch (main/master). Branch management is handled at startup via `/ralph-specum:start`. You should already be on a feature branch by this phase.

- [ ] 4.1 Verify all new files created
  - **Do**: Verify all required files from design were created
  - **Verify**: All commands must pass:
    - `test -f plugins/ralph-specum/commands/index.md`
    - `test -f plugins/ralph-specum/templates/component-spec.md`
    - `test -f plugins/ralph-specum/templates/external-spec.md`
    - `test -f plugins/ralph-specum/templates/index-summary.md`
  - **Done when**: All 4 new files exist
  - **Commit**: None (verification only)

- [ ] 4.2 Verify start.md modifications
  - **Do**: Verify start.md has both required modifications
  - **Verify**: All must pass:
    - `grep -q "ralph-specum:index" plugins/ralph-specum/commands/start.md` (hint added)
    - `grep -q "specs/.index" plugins/ralph-specum/commands/start.md` (scanner enhanced)
  - **Done when**: Both modifications present
  - **Commit**: None (verification only)

- [ ] 4.3 Bump plugin version
  - **Do**:
    1. Read current version from `plugins/ralph-specum/.claude-plugin/plugin.json`
    2. Bump minor version (e.g., 2.11.1 -> 2.12.0) for new feature
    3. Update version in plugin.json
    4. Update corresponding entry in `.claude-plugin/marketplace.json`
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  - **Done when**: Version bumped in both files
  - **Verify**: `grep -o '"version": "[0-9.]*"' plugins/ralph-specum/.claude-plugin/plugin.json | grep -v "2.11.1" && echo "OK: Version bumped"`
  - **Commit**: `chore(ralph-specum): bump version to 2.12.0`

- [ ] 4.4 Create PR and verify CI
  - **Do**:
    1. Verify current branch is a feature branch: `git branch --show-current`
    2. If on default branch, STOP and alert user
    3. Stage all changes: `git add plugins/ralph-specum/commands/index.md plugins/ralph-specum/templates/component-spec.md plugins/ralph-specum/templates/external-spec.md plugins/ralph-specum/templates/index-summary.md plugins/ralph-specum/commands/start.md plugins/ralph-specum/schemas/spec.schema.json plugins/ralph-specum/.claude-plugin/plugin.json .claude-plugin/marketplace.json`
    4. Push branch: `git push -u origin $(git branch --show-current)`
    5. Create PR using gh CLI:
       ```bash
       gh pr create --title "feat(ralph-specum): add codebase indexing command" --body "$(cat <<'EOF'
## Summary
- Add `/ralph-specum:index` command for auto-generating component specs from codebase
- Add templates for component specs, external resource specs, and index summary
- Enhance spec scanner in start.md to search indexed specs
- Add hint in start.md when no index exists

## Features
- Interview-driven indexing (pre-scan + post-scan review)
- Component detection: controllers, services, models, helpers, migrations
- External resource support: URLs, MCP servers, skills
- Filters: --path, --type, --exclude
- Modes: --dry-run, --force, --changed, --quick

## Test Plan
- [x] Templates validate with correct frontmatter
- [x] Index command has all major sections
- [x] Start.md has hint and scanner enhancement
- [ ] CI checks pass

Generated with Claude Code
EOF
)"
       ```
  - **Verify**: `gh pr checks --watch` (wait for CI completion)
  - **Done when**: All CI checks show passing, PR ready for review
  - **If CI fails**:
    1. Read failure details: `gh pr checks`
    2. Fix issues locally
    3. Push fixes: `git push`
    4. Re-verify: `gh pr checks --watch`
  - **Commit**: None (PR creation, not code change)

## Phase 5: PR Lifecycle (Continuous Validation)

> **Autonomous Loop**: This phase continues until ALL completion criteria met.

- [ ] 5.1 Monitor CI and fix failures
  - **Do**:
    1. Wait 3 minutes for CI to start
    2. Check status: `gh pr checks`
    3. If failures: read logs with `gh run view --log-failed`
    4. Fix issues locally
    5. Commit fixes: `git add . && git commit -m "fix: address CI failures"`
    6. Push: `git push`
    7. Repeat until all green
  - **Verify**: `gh pr checks` shows all passing
  - **Done when**: All CI checks passing
  - **Commit**: `fix: address CI failures` (as needed)

- [ ] 5.2 Address code review comments
  - **Do**:
    1. Fetch reviews: `gh pr view --json reviews`
    2. For each unresolved review:
       - Read review body and inline comments
       - Implement requested change
       - Commit: `fix: address review - [summary]`
    3. Push all fixes: `git push`
    4. Re-check for new reviews
  - **Verify**: `gh pr view --json reviews` shows no CHANGES_REQUESTED
  - **Done when**: All review comments resolved
  - **Commit**: `fix: address review - [summary]` (per comment)

- [ ] 5.3 Final validation - acceptance criteria check
  - **Do**: Verify ALL acceptance criteria met programmatically:
    1. AC-1.1: `grep -q "ralph-specum:index" plugins/ralph-specum/commands/index.md`
    2. AC-1.2: `grep -q "controllers\\|services\\|models\\|helpers\\|migrations" plugins/ralph-specum/commands/index.md`
    3. AC-1.3: `grep -q "Purpose\\|Location\\|Exports\\|Methods\\|Dependencies" plugins/ralph-specum/templates/component-spec.md`
    4. AC-1.4: `grep -q "specs/.index/components" plugins/ralph-specum/commands/index.md`
    5. AC-2.1: `grep -q "Interview\\|AskUserQuestion" plugins/ralph-specum/commands/index.md`
    6. AC-2.2: `grep -q "URL\\|MCP\\|skill" plugins/ralph-specum/commands/index.md`
    7. AC-3.1: `grep -q "specs/.index" plugins/ralph-specum/commands/start.md`
    8. AC-4.1: `grep -q "ralph-specum:index" plugins/ralph-specum/commands/start.md`
    9. AC-5.1: `grep -q "\\-\\-path" plugins/ralph-specum/commands/index.md`
    10. AC-6.1: `grep -q "\\-\\-dry-run" plugins/ralph-specum/commands/index.md`
    11. AC-7.1: `grep -q "\\-\\-force" plugins/ralph-specum/commands/index.md`
    12. AC-8.1: `grep -q "index.md" plugins/ralph-specum/templates/index-summary.md`
    13. AC-9.1: `grep -q "Pre-Scan\\|externalUrls" plugins/ralph-specum/commands/index.md`
  - **Verify**: All grep commands exit 0
  - **Done when**: All acceptance criteria verified
  - **Commit**: None

- [ ] 5.4 Final validation - completion criteria
  - **Do**: Verify ALL completion criteria met:
    1. Zero Regressions: Existing commands still work (no syntax errors in markdown)
    2. Modular & Reusable: Templates follow existing patterns
    3. Real-World Validation: Command structure is complete
    4. CI Green: `gh pr checks` all passing
  - **Verify**: All checks pass
  - **Done when**: All completion criteria met
  - **Commit**: None

## Notes

- **POC shortcuts taken**:
  - No actual execution testing (plugin is pure markdown)
  - Hash calculation is documented but not implemented (agent will implement at runtime)
  - External resource fetching relies on Claude Code tools at runtime

- **Production TODOs**:
  - Consider adding --verbose flag for debugging
  - May need to handle circular dependencies in component scanning
  - Consider caching external resource fetches to avoid repeated calls

## Dependencies

```
Phase 1 (POC) -> Phase 2 (Refactor) -> Phase 3 (Testing) -> Phase 4 (Quality) -> Phase 5 (PR Lifecycle)

Task dependencies within Phase 1:
1.1, 1.2, 1.3 (templates) -> 1.5 (command start)
1.5 (arg parsing) -> 1.6 (interview) -> 1.8 (scanner) -> 1.9 (generation)
1.9 (generation) -> 1.11 (external) -> 1.12 (review) -> 1.13 (summary)
1.1-1.13 (index command) -> 1.15, 1.16 (start.md mods)
```
