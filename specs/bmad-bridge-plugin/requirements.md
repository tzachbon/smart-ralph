---
spec: bmad-bridge-plugin
phase: requirements
created: 2026-04-27
---

# Requirements: BMAD Bridge Plugin

## Goal

Create a bash-based structural mapper plugin that converts BMAD markdown artifacts (PRD, epics/stories, architecture) into smart-ralph spec files, enabling teams to reuse BMAD planning work without manual reformatting.

## User Stories

### US-1: Import BMAD artifacts into a smart-ralph spec
**As a** smart-ralph user
**I want to** run `/ralph-bmad:import <bmad-project-path> <spec-name>`
**So that** BMAD planning artifacts are converted into executable smart-ralph spec files

**Acceptance Criteria:**
- [ ] AC-1.1: Command exists at `plugins/ralph-bmad-bridge/commands/ralph-bmad-import.md` and is invoked as `/ralph-bmad:import`
- [ ] AC-1.2: Command accepts two positional arguments: BMAD project path and output spec name
- [ ] AC-1.3: Command exits with code 0 on success, non-zero on failure
- [ ] AC-1.4: Command prints progress/status messages to stdout
- [ ] AC-1.5: Command exits with error when BMAD project path does not exist

### US-2: Map PRD functional requirements to requirements.md
**As a** product manager
**I want to** have BMAD PRD functional requirements automatically converted into smart-ralph User Stories and a Functional Requirements table
**So that** I can resume work in smart-ralph without rewriting requirements

**Acceptance Criteria:**
- [ ] AC-2.1: Parser extracts FRs from `## Functional Requirements` section using `- FR#: [Actor] can [capability]` pattern
- [ ] AC-2.2: Each FR becomes a User Story with As a/I want/So that format (derived from FR actor + capability text)
- [ ] AC-2.3: Each FR also appears in the Functional Requirements table with auto-generated IDs (FR-1, FR-2, ...)
- [ ] AC-2.4: If no PRD is found, the command prints a warning and proceeds with other mappings
- [ ] AC-2.5: Output requirements.md passes the YAML frontmatter format required by smart-ralph templates
- [ ] AC-2.6: If PRD exists but has no `## Functional Requirements` section, the command prints a warning listing the missing section and proceeds with other mappings

### US-3: Map PRD non-functional requirements
**As a** quality engineer
**I want to** have BMAD PRD non-functional requirements mapped to a smart-ralph NFR table
**So that** performance, security, and reliability constraints are preserved in the smart-ralph spec

**Acceptance Criteria:**
- [ ] AC-3.1: Parser extracts NFRs from `## Non-Functional Requirements` section with `###` subsection headers
- [ ] AC-3.2: Each NFR subsection becomes a row in the Non-Functional Requirements table
- [ ] AC-3.3: Subsection header becomes the "Requirement" column value
- [ ] AC-3.4: NFR items under each subsection are consolidated into the appropriate metric/target columns
- [ ] AC-3.5: If no NFR section exists in PRD, NFR table is omitted from output (not an error)

### US-4: Map BMAD epics and stories to tasks.md
**As a** task planner
**I want to** have BMAD epics.md converted into smart-ralph tasks.md with Phase structure and task entries
**So that** BMAD story breakdown drives smart-ralph task execution

**Acceptance Criteria:**
- [ ] AC-4.1: Parser handles BMAD epics.md monolithic format: overview + requirements inventory + epic list + stories
- [ ] AC-4.2: Each `### Story N.M:` block becomes a task entry in Phase 1 (POC) of tasks.md
- [ ] AC-4.3: Story Given/When/Then acceptance criteria are extracted and placed into task Done when and Verify sections
- [ ] AC-4.4: FR coverage map from epics.md is used to add `_Requirements: FR-X` refs to generated tasks
- [ ] AC-4.5: Epic-level grouping is preserved in tasks.md section headings
- [ ] AC-4.6: If epics.md is missing, the command prints a warning and generates a minimal tasks.md with a single "Manual review required" task
- [ ] AC-4.7: If epics.md has no `### FR Coverage Map` section, generated tasks omit `_Requirements:` refs and the command prints a warning

### US-5: Map architecture decisions to design.md
**As a** architect reviewer
**I want to** have BMAD architecture.md decisions and file structure mapped to smart-ralph design.md
**So that** architectural context from BMAD is available during smart-ralph implementation

**Acceptance Criteria:**
- [ ] AC-5.1: Parser identifies "decisions", "architecture", "technology", and "stack" sections in architecture.md and maps them to design.md Technical Decisions table
- [ ] AC-5.2: Parser identifies "project structure" or "file structure" sections and maps them to design.md File Structure table
- [ ] AC-5.3: Each `##` heading in architecture.md is mapped to a corresponding design.md section
- [ ] AC-5.4: Output design.md follows the smart-ralph design.md template structure with YAML frontmatter
- [ ] AC-5.5: If architecture.md is missing, the command generates a minimal design.md with "Architecture input not provided" placeholder and continues

### US-6: Validate output and emit warnings
**As a** smart-ralph executor
**I want to** have the output spec files validated and receive warnings for unmapped content
**So that** I can identify gaps that need manual review before execution

**Acceptance Criteria:**
- [ ] AC-6.1: After mapping, the command validates all generated spec files against smart-ralph template structure
- [ ] AC-6.2: The command prints a summary: number of FRs mapped, stories mapped, architecture sections mapped
- [ ] AC-6.3: The command prints a warnings section listing: BMAD sections that were not mapped, content that may need manual review
- [ ] AC-6.4: The command verifies that generated requirements.md has valid frontmatter (spec, phase, created fields present)
- [ ] AC-6.5: The command verifies that generated tasks.md has valid frontmatter (spec, phase, created, total_tasks fields present)
- [ ] AC-6.6: The command verifies that generated design.md has valid frontmatter (spec, phase, created fields present)

### US-7: Plugin structure and registration
**As a** smart-ralph plugin manager
**I want to** install the BMAD bridge as a Claude Code plugin under `plugins/ralph-bmad-bridge/`
**So that** the `/ralph-bmad:import` command is available alongside other Ralph commands

**Acceptance Criteria:**
- [ ] AC-7.1: Plugin directory `plugins/ralph-bmad-bridge/` exists with standard structure: `.claude-plugin/plugin.json`, `commands/`, `scripts/`
- [ ] AC-7.2: `plugin.json` has valid manifest: name (`ralph-bmad-bridge`), version (semver), description, license, author
- [ ] AC-7.3: Command file `commands/ralph-bmad-import.md` has correct Claude Code plugin frontmatter
- [ ] AC-7.4: Mapping logic script at `scripts/import.sh` is executable and uses bash+jq for deterministic parsing
- [ ] AC-7.5: Plugin version is bumped in `.claude-plugin/marketplace.json` alongside `plugin.json`

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | `/ralph-bmad:import` CLI command with positional arguments | High | AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5 |
| FR-2 | PRD functional requirements parser | High | AC-2.1, AC-2.2, AC-2.3, AC-2.6 |
| FR-3 | PRD non-functional requirements parser | High | AC-3.1, AC-3.2, AC-3.3, AC-3.4 |
| FR-4 | Epics-to-tasks structural mapper | High | AC-4.1, AC-4.2, AC-4.3, AC-4.4, AC-4.5, AC-4.6, AC-4.7 |
| FR-5 | Architecture-to-design structural mapper | High | AC-5.1, AC-5.2, AC-5.3, AC-5.4, AC-5.5 |
| FR-6 | Output validation and summary report | High | AC-6.1, AC-6.2, AC-6.3, AC-6.4, AC-6.5, AC-6.6 |
| FR-7 | Plugin manifest and directory structure | High | AC-7.1, AC-7.2, AC-7.3, AC-7.4, AC-7.5 |
| FR-8 | Graceful handling of missing BMAD artifacts | Medium | AC-2.4, AC-2.6, AC-3.5, AC-4.6, AC-4.7, AC-5.5 |
| FR-9 | FR coverage map integration into tasks | Medium | AC-4.4 |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Deterministic execution | No LLM/tool calls during import | 100% bash+jq, zero API calls |
| NFR-2 | Import latency | Time from command to output files | < 5 seconds for a typical BMAD project |
| NFR-3 | Error reporting | Exit code on failure | Non-zero exit code with stderr message |
| NFR-4 | Portability | Shell compatibility | POSIX sh / bash 4+, no node/npm dependencies |
| NFR-5 | Plugin size | Total script lines | < 500 lines of bash code |

## Glossary

| Term | Definition |
|------|------------|
| BMAD | bmalph — a BMAD Method agent framework (v2.11.0) that produces planning artifacts in `_bmad-output/` |
| PRD | Product Requirements Document — BMAD artifact containing functional and non-functional requirements |
| FR | Functional Requirement — a BMAD requirement in format `- FR#: [Actor] can [capability]` |
| NFR | Non-Functional Requirement — performance, security, reliability constraint in a BMAD PRD |
| ADR | Architecture Decision Record — BMAD architecture.md contains prose-based decisions, not structured ADRs |
| smart-ralph | The spec-driven development plugin system this project extends |
| spec | A single feature specification directory under `specs/<name>/` containing research.md, requirements.md, design.md, tasks.md |
| Given/When/Then | BDD (Behavior-Driven Development) acceptance criteria format used in BMAD stories |
| `_bmad-output/` | BMAD output directory containing `planning-artifacts/`, `implementation-artifacts/`, and `reviews/` |

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| BMAD artifact format changes across versions | High | Pin to v6.4.0 format; warn on version mismatch |
| PRD has no fixed template beyond frontmatter | Medium | awk state-machine uses section heading matching, not positional assumptions |
| Generated spec files may need manual review | Medium | Validation + warnings output; summary report |
| < 500 line constraint limits feature additions | Low | Single monolithic script; extract helpers in Phase 2 |

## Out of Scope

- LLM-based content synthesis (e.g., generating research.md executive summaries from PRD prose)
- BMAD-to-smart-ralsh bidirectional sync (one-way import only)
- Support for sharded BMAD artifacts (`*prd*/index.md` format)
- BMAD UX Design artifact mapping
- BMAD test scenario to Verify command generation (out-of-scope per research findings; deferred — requires LLM synthesis as noted in research.md)
- Epic Key Change #4 "test scenarios → Verify commands" and "user stories → verification contract" mappings — these require LLM synthesis and are out of scope for v0.1.0; tracked as Production TODOs in tasks.md Notes
- Automatic BMAD project path discovery — user must provide the path explicitly
- Plugin auto-installation — user must place plugin in `plugins/` directory manually
- Support for BMAD versions older than v6.4.0 (untested)

## Dependencies

- BMAD v2.11.0+ output artifact format (as documented in research.md)
- `jq` must be available on the host system (for JSON/YAML processing in bash)
- `bash` 4.0+ or POSIX-compatible shell
- No shared files with any other spec in the engine-roadmap-epic

## Success Criteria

- A BMAD project's PRD and epics.md can be converted to smart-ralph spec files with a single command: `/ralph-bmad:import /path/to/bmad-project my-feature`
- Generated spec files pass validation (correct frontmatter, required sections present)
- Generated tasks.md can be fed into `/ralph-specum:implement` without manual editing
- No LLM/tool-call dependency — entirely deterministic bash+jq execution

## Verification Contract

**Project type**: cli

**Entry points**:
- `/ralph-bmad:import <bmad-project-path> <spec-name>` — Claude Code slash command
- `plugins/ralph-bmad-bridge/scripts/import.sh` — internal mapping script invoked by command
- `plugins/ralph-bmad-bridge/.claude-plugin/plugin.json` — plugin manifest

**Observable signals**:
- PASS: `specs/<spec-name>/requirements.md`, `design.md`, `tasks.md` created with valid YAML frontmatter and content sections
- PASS: Command exits with code 0 and prints summary of mapped items
- FAIL: Command exits with non-zero code and prints error to stderr
- FAIL: Generated spec files missing required frontmatter fields (spec, phase, created)
- FAIL: Generated spec files missing required top-level sections per template (requirements.md, design.md, tasks.md — research.md excluded per Out of Scope)

**Hard invariants**:
- Plugin directory must not overwrite any existing files in `specs/<name>/` — fail with error if target spec directory already exists
- Plugin must not modify any files outside `specs/<spec-name>/`
- Import must not call any LLM, web service, or external API — purely local bash+jq
- Generated files must not include BMAD internal fields (e.g., `stepsCompleted`, `workflowType`)

**Seed data**:
- A BMAD project directory with at least one of: `prd.md`, `epics.md` (required inputs per research.md recommendation)
- BMAD output in standard location: `{project-root}/_bmad-output/planning-artifacts/`
- `jq` installed and on PATH

**Dependency map**:
- `plugins/ralph-specum/` — shares spec template formats; generated files must match ralph-specum template structure
- `specs/_epics/engine-roadmap-epic/` — this is Spec 5 of the epic; no file-level dependency but part of the same epic state
- No other specs share files or database state

**Escalate if**:
- BMAD project path is valid but contains no recognized artifacts (no prd.md, no epics.md, no architecture.md)
- Generated spec files cannot be validated against template structure (malformed output detected)
- Target spec directory already exists with content (risk of overwriting)
- jq is not available on the system (hard dependency)

## Resolved Questions

1. **Mapping report file**: Decision: No — add to Production TODOs in tasks.md Notes. Rationale: YAGNI; summary output to stdout is sufficient.
2. **BMAD version compatibility**: Decision: Yes — add `"bmadVersion": ">=6.4.0"` to plugin.json keywords/metadata. Rationale: Format was verified against v6.4.0.
3. **Explicit file args**: Decision: No for v0.1.0 — add to Production TODOs. Rationale: Convention-based discovery is simpler; explicit args can be added later.

## Next Steps
1. Review and approve requirements
2. Spawn architect-reviewer agent for technical design (design.md)
3. Spawn task-planner agent for task breakdown (tasks.md)
4. Execute implementation via `/ralph-specum:implement`
