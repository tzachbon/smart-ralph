---
spec: bmad-bridge-plugin
phase: research
created: 2026-04-27T12:00:00Z
---

# Research: BMAD-to-smart-ralph Structural Mapper

## Executive Summary

BMAD (bmalph v2.11.0) stores artifacts in `_bmad-output/{planning_artifacts}/` and `_{implementation_artifacts}/` as markdown files with YAML frontmatter. The existing `ralph_import.sh` (deprecated, from standalone Ralph) uses an LLM for conversion — unsuitable for our needs. A **bash/jq structural mapper** can parse BMAD markdown patterns directly. Key mapping challenges: BMAD epics.md contains epics + stories in one document; PRD is interactive/facilitated (no fixed template beyond frontmatter); architecture.md has no fixed template beyond frontmatter.

## External Research: BMAD Plugin System

### BMAD Architecture (NOT Claude Code plugin)

BMAD does NOT use Claude Code plugin structure. It uses:

| Component | Location | Format |
|-----------|----------|--------|
| Core package | `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/` | npm package (bmalph v2.11.0) |
| External modules | `/home/malka/.bmad/cache/external-modules/{cis|tea|bmb|gds}/` | npm-installed |
| Project config | `{project-root}/_bmad/config.toml` | TOML (not JSON!) |
| Module help | `{project-root}/_bmad/{module}/module-help.csv` | CSV |
| Templates | `{project-root}/_bmad/` (13 .md files) | Markdown |
| Scripts | `{project-root}/_bmad/scripts/resolve_config.py` | Python 3.11+ |
| Output | `{project-root}/_bmad-output/{planning_artifacts,test_artifacts,implementation_artifacts,reviews}/` | Mixed |

BMAD modules (per manifest.yaml at `_bmad/_config/manifest.yaml`):
- `core` (built-in, v6.4.0) — brainstorms, party-mode, editorial review, shard-doc, distillator
- `bmm` (built-in, v6.4.0) — PRD creation, architecture, epics/stories, sprint planning
- `bmb` (external, v1.7.0 from `bmad-builder`) — agent/workflow/module builder
- `cis` (external, v0.2.0 from `bmad-creative-intelligence-suite`) — creative intelligence
- `tea` (external, v1.15.1 from `bmad-method-test-architecture-enterprise`) — test architecture

BMAD config format uses TOML with sections like `[core]`, `[modules.bmm]`, `[agents.bmad-agent-pm]`. Config resolution uses 4-layer deep merge (Python script at `_bmad/scripts/resolve_config.py`).

### Source files:
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/package.json`
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/ralph/RALPH-REFERENCE.md`
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/bmm/workflows/` (all skill workflow files)

## Internal Research: BMAD Artifact Formats

### 1. PRD (`{planning_artifacts}/prd.md`)

**Location in output**: `{project-root}/_bmad-output/planning-artifacts/prd.md`

**Frontmatter** (YAML):
```yaml
---
stepsCompleted: []
inputDocuments: []
workflowType: 'prd'
---
```

**Structure** (built incrementally through 12 steps):
1. Title: `# Product Requirements Document - {project_name}`
2. Author/Date
3. Executive Summary (step-02c)
4. Success Criteria (step-03)
5. User Journeys (step-04)
6. Domain Requirements (step-05)
7. Innovation (step-06)
8. Project Type (step-07)
9. Scope (step-08)
10. **Functional Requirements** (step-09) — CRITICAL section
    - Format: grouped by capability area
    ```markdown
    ## Functional Requirements
    ### [Capability Area Name]
    - FR1: [Actor] can [capability]
    - FR2: [Actor] can [capability]
    ```
11. **Non-Functional Requirements** (step-10)
    ```markdown
    ## Non-Functional Requirements
    ### Performance
    - [Performance requirements]
    ### Security
    - [Security requirements]
    ```

**Key parsing challenges**: PRD has no fixed template beyond frontmatter. Content is user-driven via interactive workflow. FR format is: `- FR#: [Actor] can [capability]`. NFRs are optional and selective.

### 2. Epics + Stories (`{planning_artifacts}/epics.md`)

**Location in output**: `{project-root}/_bmad-output/planning-artifacts/epics.md`

**Frontmatter** (YAML):
```yaml
---
stepsCompleted: []
inputDocuments: []
---
```

**Structure**:
```markdown
# {project_name} - Epic Breakdown

## Overview
{description}

## Requirements Inventory
### Functional Requirements
{{fr_list}}
### NonFunctional Requirements
{{nfr_list}}
### Additional Requirements
{{additional}}
### UX Design Requirements
{{ux}}
### FR Coverage Map
FR1: Epic 1 - ...
FR2: Epic 2 - ...

## Epic List
### Epic 1: {title}
{goal}
**FRs covered:** FR1, FR2, FR3

### Epic 2: {title}
...

## Epic 1: {title}
{goal}

### Story 1.1: {title}
As a {role},
I want {action},
so that {benefit}.

**Acceptance Criteria:**
**Given** {precondition}
**When** {action}
**Then** {outcome}
**And** {additional}
```

**Key parsing rules**:
- Stories use Given/When/Then BDD format
- Stories are nested under Epics
- FR coverage map links FR numbers to epics
- One document contains ALL epics and stories

### 3. Architecture (`{planning_artifacts}/architecture.md`)

**Location in output**: `{project-root}/_bmad-output/planning-artifacts/architecture.md`

**Frontmatter** (YAML):
```yaml
---
stepsCompleted: []
inputDocuments: []
workflowType: 'architecture'
project_name: '{{project_name}}'
user_name: '{{user_name}}'
date: '{{date}}'
---
```

**Sections built through 8 steps**:
1. Init (step-01): Project context detection
2. Context Analysis (step-02): Tech stack, constraints
3. Starter Evaluation (step-03): Template matching
4. **Core Decisions** (step-04): ADR-style decisions
5. **Implementation Patterns** (step-05): Consistency rules
6. **Project Structure** (step-06): File/folder layout
7. Validation (step-07): Cross-check
8. Complete (step-08): Status update

**Completion frontmatter**:
```yaml
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
workflowType: 'architecture'
lastStep: 8
status: 'complete'
completedAt: '{{current_date}}'
```

**Key parsing rules**: No fixed section order — sections appended collaboratively. Architecture decisions are prose-based, not structured ADR format. Must look for patterns like `##` headings, decision sections, file structure sections.

### 4. Individual Story Files (`{implementation_artifacts}/{story_key}.md`)

**Location**: `{project-root}/_bmad-output/implementation-artifacts/{epic_num}-{story_num}-{title}.md`

**Template** (from `bmad-create-story/template.md`):
```markdown
# Story {epic_num}.{story_num}: {story_title}

Status: ready-for-dev

## Story
As a {role},
I want {action},
so that {benefit}.

## Acceptance Criteria
1. [Add acceptance criteria from epics/PRD]

## Tasks / Subtasks
- [ ] Task 1 (AC: #)
  - [ ] Subtask 1.1
- [ ] Task 2 (AC: #)
  - [ ] Subtask 2.1

## Dev Notes
- Relevant architecture patterns and constraints
- Source tree components to touch
- Testing standards summary

### Project Structure Notes
- Alignment with unified project structure

### References
- Cite all technical details with source paths

## Dev Agent Record
### Agent Model Used
{{agent_model_name_version}}

### Debug Log References
### Completion Notes List
### File List
```

### 5. Sprint Status (`{implementation_artifacts}/sprint-status.yaml`)

**Format** (YAML):
```yaml
generated: {date}
last_updated: {date}
project: {project_name}
project_key: NOKEY
tracking_system: file-system
story_location: "{story_location}"

development_status:
  epic-1: backlog  # or in-progress, done
  1-1-user-authentication: done  # or ready-for-dev, in-progress, review, backlog
  1-2-account-management: ready-for-dev
  epic-1-retrospective: optional
```

### 6. QA Summary (`{implementation_artifacts}/tests/test-summary.md`)

Simple markdown summary of generated tests:
```markdown
# Test Automation Summary
## Generated Tests
### API Tests
- [x] tests/api/endpoint.spec.ts
### E2E Tests
- [x] tests/e2e/feature.spec.ts
## Coverage
- API endpoints: 5/10 covered
- UI features: 3/8 covered
```

### 7. BMAD Review Output (`_bmad-output/reviews/`)

Structured markdown report format:
```markdown
# Smart-Ralph Review: {spec-name} (Phase: {phase})
**Spec**: `{spec-name}` | **Epic**: `{epic-name}` (Spec N)
**Review Date**: {ISO timestamp}
**Model**: {model-name}
**Review Mode**: full (5 layers)
**Consensus Threshold**: majority
```
Contains severity-tagged findings (CRITICAL, HIGH, MEDIUM, LOW) with consensus votes from multiple BMAD agents.

### Source files:
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/bmad/core/tasks/bmad-create-prd/workflow.md`
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/bmad/core/tasks/bmad-create-prd/templates/prd-template.md`
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/bmad/bmm/workflows/3-solutioning/bmad-create-epics-and-stories/workflow.md`
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/bmad/bmm/workflows/3-solutioning/bmad-create-epics-and-stories/templates/epics-template.md`
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/bmad/bmm/workflows/4-implementation/bmad-create-story/workflow.md`
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/bmad/bmm/workflows/4-implementation/bmad-create-story/template.md`
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/bmad/bmm/workflows/3-solutioning/bmad-create-architecture/workflow.md`
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/bmad/bmm/workflows/3-solutioning/bmad-create-architecture/steps/step-08-complete.md`
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/bmad/bmm/workflows/4-implementation/bmad-sprint-planning/sprint-status-template.yaml`

## Mapping Targets: smart-ralph Spec File Formats

### 1. research.md
```yaml
---
spec: {{SPEC_NAME}}
phase: research
created: {{TIMESTAMP}}
---
```
**Sections**: Executive Summary, External Research, Codebase Analysis, Related Specs, Feasibility Assessment, Recommendations, Open Questions, Sources

### 2. requirements.md
```yaml
---
spec: {{SPEC_NAME}}
phase: requirements
created: {{TIMESTAMP}}
---
```
**Sections**: Goal, User Stories (As a/I want/So that + Acceptance Criteria), Functional Requirements table, Non-Functional Requirements table, Glossary, Out of Scope, Dependencies, Success Criteria, Risks table, Verification Contract

### 3. design.md
```yaml
---
spec: {{SPEC_NAME}}
phase: design
created: {{TIMESTAMP}}
---
```
**Sections**: Overview, Architecture (mermaid diagrams), Components, Data Flow (mermaid), Technical Decisions table, File Structure table, Interfaces, Error Handling, Edge Cases, Dependencies table, Security/Performance/Concurrency sections, Test Strategy (Test Double Policy, Mock Boundary, Coverage Table, Skip Policy, Test File Conventions)

### 4. tasks.md
```yaml
---
spec: {{SPEC_NAME}}
phase: tasks
total_tasks: {{N}}
created: {{TIMESTAMP}}
---
```
**Sections**: Overview, Completion Criteria, Task Writing Guide, Phase 1 (POC/TDD), Phase 2 (Refactoring/Integration), Phase 3 (Testing), Phase 4 (Quality Gates), Phase 5 (PR Lifecycle)

Each task block:
```markdown
- [ ] 1.1 [P] {{task name}}
  - **Do**: {{steps}}
  - **Files**: {{paths}}
  - **Done when**: {{criteria}}
  - **Verify**: {{command}}
  - **Commit**: `{{message}}`
  - _Requirements: FR-1, AC-1.1_
  - _Design: Component A_
```

### 5. .ralph-state.json (per spec.schema.json)
```json
{
  "source": "spec",
  "name": "spec-name",
  "basePath": "./specs/spec-name",
  "phase": "research|requirements|design|tasks|execution",
  "taskIndex": 0,
  "totalTasks": 0,
  "granularity": "fine|coarse",
  "epicName": "epic-name"
}
```

### Source files:
- `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/templates/research.md`
- `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/templates/requirements.md`
- `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/templates/design.md`
- `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/templates/tasks.md`
- `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/schemas/spec.schema.json`

## Existing Conversion Tools Found

### 1. bmalph ralph_import.sh (DEPRECATED)
**Location**: `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/ralph/ralph_import.sh`
**Approach**: Uses Claude Code CLI to AI-convert PRD into Ralph format (PROMPT.md, fix_plan.md, specs/requirements.md)
**Status**: Deprecated — "Use `bmalph implement` for PRD-to-Ralph transition instead"
**Verdict**: NOT suitable for structural mapper. Uses LLM which is slow, expensive, and non-deterministic.

### 2. bmalph ralph directory (templates + drivers)
**Location**: `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/ralph/`
**Contents**:
- `ralph_import.sh` — deprecated PRD converter
- `ralph_loop.sh` — loop management
- `ralph_monitor.sh` — monitoring
- `templates/` — AGENT.md, PROMPT.md, fix_plan.md, ralphrc.template, REVIEW_PROMPT.md, specs/
- `drivers/` — claude-code.sh, codex.sh, copilot.sh, cursor.sh, opencode.sh
- `RALPH-REFERENCE.md` — reference guide for legacy Ralph system

**Key insight**: The legacy Ralph system used `.ralph/` directory with PROMPT.md, @fix_plan.md, and specs/ — completely different structure from smart-ralph's `specs/` directory with research.md, requirements.md, design.md, tasks.md.

### 3. No existing BMAD→smart-ralph mapper
**Finding**: No existing conversion script or mapping logic. The existing `ralph_import.sh` is for the OLD standalone Ralph system (`.ralph/` format), not smart-ralph.

### Source files:
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/ralph/` (entire directory)
- `/mnt/bunker_data/ai/smart-ralph/_bmad/scripts/resolve_config.py`
- `/mnt/bunker_data/ai/smart-ralph/_bmad/scripts/resolve_customization.py`

## Key Mapping Challenges

### Challenge 1: BMAD PRD has no fixed template
BMAD PRD is built interactively through 12 collaborative steps. Only the frontmatter is fixed. The functional requirements section uses `- FR#: [Actor] can [capability]` format but is user-generated content.

**Strategy**: Pattern-match on `## Functional Requirements` heading, then parse `- FR#: ...` lines. NFRs under `## Non-Functional Requirements` with `###` subsections.

### Challenge 2: BMAD epics.md is a monolithic document
Contains overview + requirements inventory + epic list + ALL epics with ALL stories in one file.

**Strategy**: Parse with state-machine approach — track current epic number, story number. Each `### Story N.M:` starts a new story block.

### Challenge 3: BMAD architecture.md has no fixed structure
Sections appended collaboratively. No consistent heading patterns.

**Strategy**: Partial mapping. Look for `##` headings; map any "decisions", "architecture", "technology", "stack" sections to design.md Technical Decisions table. Map "project structure" or "file structure" sections to design.md File Structure table.

### Challenge 4: Test scenarios exist in BMAD TEA but format varies
TEA generates test designs, not task-level verify commands.

**Strategy**: Map TEA test design output to tasks.md Phase 3 Testing section. Use test framework detection from project.

### Challenge 5: BMAD output paths are configurable
BMAD uses `{project-root}/_bmad-output/planning-artifacts` etc. paths from config.

**Strategy**: Use `_bmad/scripts/resolve_config.py` to resolve output paths, or accept command-line args for BMAD project root.

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | **High** | BMAD output is markdown with predictable patterns; bash+jq can parse |
| Effort Estimate | **Medium** (~3-5 days) | Core mapping logic + template filling + CLI wrapper |
| Risk Level | **Medium** | BMAD PRD format is user-generated (variable); architecture.md has no fixed template |
| Coverage | **Partial** | Can fully map PRD+epics → requirements.md; partial mapping for architecture → design.md; limited for test scenarios → tasks.md verify commands |

### What CAN be mapped structurally (bash/jq):
- PRD FRs → requirements.md User Stories / Functional Requirements
- PRD NFRs → requirements.md Non-Functional Requirements table
- Epics + Stories → tasks.md Phase structure + task entries
- FR Coverage Map → task _Requirements_ refs
- Architecture file structure → design.md File Structure table
- Architecture decisions → design.md Technical Decisions table

### What CANNOT be mapped structurally (needs LLM):
- PRD executive summary → research.md Executive Summary (requires synthesis)
- Architecture prose → design.md component diagrams (mermaid requires intent understanding)
- Architecture patterns → design.md Test Strategy (requires domain knowledge)
- Test scenarios → Verify commands (requires knowing test framework)

## Recommendations for Requirements

1. **Scope the mapper to deterministic mappings only**: Map FR→stories, epics→tasks, architecture file structure→design file structure. Skip PRD executive summary and architecture prose sections — the command should note these require manual review or LLM enhancement.

2. **Support partial BMAD projects**: Not every BMAD workflow produces all artifacts. The mapper should accept a list of BMAD output files and only map what's present. Required inputs: at least one of (prd.md, epics.md).

3. **Use BMAD config resolution**: Call `_bmad/scripts/resolve_config.py` to discover output paths, but also allow explicit `--prd`/`--epics`/`--architecture` CLI args.

4. **Design for augmentation, not replacement**: The output spec files should be "ready to execute" for the requirements→design→tasks phases, but the command should output warnings about unmapped content.

5. **Plugin structure**: Follow `plugins/ralph-specum/.claude-plugin/plugin.json` format. Command at `commands/ralph-bmad-import.md`. Script at `scripts/import.sh`.

## Open Questions

1. **BMAD artifact location**: Are BMAD artifacts always in `_bmad-output/` subdirectories, or can they be anywhere? The config uses configurable `planning_artifacts` and `implementation_artifacts` paths. Should the mapper auto-discover or require explicit paths?

2. **Should the mapper handle sharded BMAD artifacts?** BMAD supports sharded folders (`*prd*/index.md`). Should the mapper support this format?

3. **What about BMAD UX Design artifacts?** BMAD has a separate `bmad-create-ux-design` workflow that produces UX design files. Should these map to design.md sections?

4. **Should the plugin also generate a BMAD→smart-ralph spec mapping report?** A summary of what was mapped, what was skipped, and warnings?

5. **Version pinning**: BMAD is v6.4.0, bmalph is v2.11.0. Should the plugin declare BMAD version compatibility requirements?

## Sources

### BMAD Documentation/Code
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/package.json` (bmalph package manifest)
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/ralph/RALPH-REFERENCE.md` (Ralph reference guide)
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/ralph/ralph_import.sh` (deprecated PRD importer)
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/ralph/templates/` (Ralph templates)
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/bmad/core/tasks/bmad-create-prd/workflow.md` (PRD creation workflow)
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/bmad/core/tasks/bmad-create-prd/templates/prd-template.md` (PRD template)
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/bmad/core/tasks/bmad-create-prd/steps-c/step-09-functional.md` (FR format spec)
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/bmad/core/tasks/bmad-create-prd/steps-c/step-10-nonfunctional.md` (NFR format spec)
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/bmad/bmm/workflows/3-solutioning/bmad-create-epics-and-stories/workflow.md` (epics workflow)
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/bmad/bmm/workflows/3-solutioning/bmad-create-epics-and-stories/templates/epics-template.md` (epics template)
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/bmad/bmm/workflows/3-solutioning/bmad-create-epics-and-stories/steps/step-02-design-epics.md` (epic design step)
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/bmad/bmm/workflows/3-solutioning/bmad-create-epics-and-stories/steps/step-03-create-stories.md` (story creation step)
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/bmad/bmm/workflows/3-solutioning/bmad-create-architecture/workflow.md` (architecture workflow)
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/bmad/bmm/workflows/3-solutioning/bmad-create-architecture/steps/step-08-complete.md` (architecture completion)
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/bmad/bmm/workflows/4-implementation/bmad-create-story/workflow.md` (story creation workflow)
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/bmad/bmm/workflows/4-implementation/bmad-create-story/template.md` (story template)
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/bmad/bmm/workflows/4-implementation/bmad-sprint-planning/sprint-status-template.yaml` (sprint status YAML)
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/bmad/bmm/workflows/bmad-qa-generate-e2e-tests/workflow.md` (QA test generation)
- `/home/malka/.bmad/cache/external-modules/bmb/module-help.csv` (bmb module help)
- `/home/malka/.bmad/cache/external-modules/tea/module-help.csv` (tea module help)
- `/home/malka/.bmad/cache/external-modules/cis/module-help.csv` (cis module help)

### Smart-Ralph Specum Templates
- `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/templates/research.md`
- `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/templates/requirements.md`
- `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/templates/design.md`
- `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/templates/tasks.md`
- `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/schemas/spec.schema.json`
- `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/.claude-plugin/plugin.json`
- `/mnt/bunker_data/ai/smart-ralph/.claude-plugin/marketplace.json`

### BMAD Project Config
- `/mnt/bunker_data/ai/smart-ralph/_bmad/config.toml`
- `/mnt/bunker_data/ai/smart-ralph/_bmad/config.user.toml`
- `/mnt/bunker_data/ai/smart-ralph/_bmad/_config/manifest.yaml`
- `/mnt/bunker_data/ai/smart-ralph/_bmad/scripts/resolve_config.py`
- `/mnt/bunker_data/ai/smart-ralph/_bmad/scripts/resolve_customization.py`
- `/mnt/bunker_data/ai/smart-ralph/_bmad/bmm/module-help.csv`
- `/mnt/bunker_data/ai/smart-ralph/_bmad/tea/module-help.csv`
- `/mnt/bunker_data/ai/smart-ralph/_bmad/core/module-help.csv`
- `/mnt/bunker_data/ai/smart-ralph/_bmad/bmb/module-help.csv`

### Existing Bridge Spec
- `/mnt/bunker_data/ai/smart-ralph/specs/bmad-bridge-plugin/plan.md`
- `/mnt/bunker_data/ai/smart-ralph/specs/_epics/engine-roadmap-epic/epic.md` (Spec 5 entry)
- `/mnt/bunker_data/ai/smart-ralph/specs/_epics/engine-roadmap-epic/.epic-state.json`

### Legacy Ralph (for reference only)
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/ralph/AGENT.md`
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/ralph/templates/PROMPT.md`
- `/home/malka/.local/share/fnm/node-versions/v22.22.2/installation/lib/node_modules/bmalph/ralph/templates/REVIEW_PROMPT.md`
