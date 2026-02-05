---
spec: codebase-indexing
phase: requirements
created: 2026-02-04
---

# Requirements: Codebase Indexing

## Goal

Enable spec-driven development on legacy codebases by auto-generating component specs from both local code analysis AND external documentation sources, making existing functionality discoverable during new feature research.

## User Decisions

Captured during requirements interview:

| Question | User Response |
|----------|---------------|
| Primary users | End users via command line (developers using CLI) |
| Priority tradeoffs | Prioritize feature completeness over speed |
| Success criteria | Gather all codebase functionality from existing AND external resources (like online docs) |
| Additional context | Indexing is the concept; real goal is having spec files for old codebases so new features can search existing specs during research |

**Key Insight**: User explicitly expanded scope beyond local code analysis to include external documentation (online docs, APIs, etc.).

## User Stories

### US-1: Index Local Codebase Components

**As a** developer working on a legacy codebase
**I want to** scan the repository and auto-generate specs for existing components
**So that** new feature research can discover and reference existing code

**Acceptance Criteria:**
- [ ] AC-1.1: Running `/ralph-specum:index` scans the codebase and generates component specs
- [ ] AC-1.2: Components are categorized (controllers, services, models, helpers, etc.)
- [ ] AC-1.3: Each generated spec includes: purpose, location, exports, methods, dependencies
- [ ] AC-1.4: Specs are stored in `specs/.index/components/` directory
- [ ] AC-1.5: Running index twice skips already-indexed components (unless `--force`)

### US-2: Include External Resources

**As a** developer onboarding to a codebase
**I want to** index external resources (docs, MCP servers, skills) alongside code
**So that** I have complete context about how the system works

**Acceptance Criteria:**
- [ ] AC-2.1: External resources are discovered via pre-scan interview conversation
- [ ] AC-2.2: Supports multiple resource types: URLs, MCP servers, installed skills
- [ ] AC-2.3: URL resources are fetched and stored in `specs/.index/external/`
- [ ] AC-2.4: MCP resources are queried and capabilities documented in specs
- [ ] AC-2.5: Skill resources have their commands/agents documented in specs
- [ ] AC-2.6: Links between code components and external resources are detected where possible
- [ ] AC-2.7: Resource specs include source type, identifier, and fetch date for freshness tracking
- [ ] AC-2.8: Supports common doc formats: Markdown, HTML, plain text

### US-3: Discover Indexed Specs During Research

**As a** developer starting a new feature
**I want to** `/ralph-specum:start` to search indexed specs automatically
**So that** I get relevant context about existing components

**Acceptance Criteria:**
- [ ] AC-3.1: Research phase searches both `specs/*/` AND `specs/.index/`
- [ ] AC-3.2: Indexed specs appear in "Related Specs" with relevance classification
- [ ] AC-3.3: Component specs are searchable by keywords, exports, dependencies
- [ ] AC-3.4: External doc specs are searchable by content keywords

### US-4: Guided Indexing for New Users

**As a** new user running Ralph for the first time
**I want to** be prompted to index the codebase if no index exists
**So that** I don't miss out on context discovery benefits

**Acceptance Criteria:**
- [ ] AC-4.1: `/ralph-specum:start` shows hint when `specs/.index/` is empty/missing
- [ ] AC-4.2: Hint explains the benefit: "improves context discovery for new features"
- [ ] AC-4.3: Hint is NOT shown if index already has content
- [ ] AC-4.4: Hint appears once per session (not repeatedly)

### US-5: Selective Indexing with Filters

**As a** developer with a large codebase
**I want to** filter which components get indexed
**So that** I can focus on relevant parts and avoid noise

**Acceptance Criteria:**
- [ ] AC-5.1: `--path=src/` limits indexing to specific directory
- [ ] AC-5.2: `--type=controllers,services` limits to specific component types
- [ ] AC-5.3: `--exclude=test,spec,mock` excludes patterns from indexing
- [ ] AC-5.4: Filters can be combined (e.g., `--path=src/ --type=services`)

### US-6: Preview Before Generating

**As a** developer uncertain about indexing scope
**I want to** preview what will be generated without writing files
**So that** I can verify the scope before committing

**Acceptance Criteria:**
- [ ] AC-6.1: `--dry-run` shows list of components that would be indexed
- [ ] AC-6.2: Dry run output includes component type, file path, and estimated spec size
- [ ] AC-6.3: Dry run does NOT write any files to disk
- [ ] AC-6.4: Summary shows total count by component type

### US-7: Regenerate Outdated Specs

**As a** developer whose codebase has evolved
**I want to** regenerate specs for changed components
**So that** indexed specs stay accurate

**Acceptance Criteria:**
- [ ] AC-7.1: `--force` regenerates all specs (overwrites existing)
- [ ] AC-7.2: `--changed` regenerates only modified files (via git diff)
- [ ] AC-7.3: Generated specs include file hash for change detection
- [ ] AC-7.4: Warning shown when regenerating previously modified specs

### US-8: Index Summary Dashboard

**As a** team lead reviewing codebase coverage
**I want to** see a summary of what's indexed
**So that** I understand the completeness of our documentation

**Acceptance Criteria:**
- [ ] AC-8.1: `specs/.index/index.md` lists all indexed components with links
- [ ] AC-8.2: Index shows counts by category (controllers: 5, services: 12, etc.)
- [ ] AC-8.3: Index includes "Last indexed" timestamp
- [ ] AC-8.4: Index lists external docs sources with fetch dates

### US-9: Interview-Driven Indexing Experience

**As a** developer running `/ralph-specum:index`
**I want to** be guided through a pre-scan interview and post-scan review
**So that** the indexing captures everything relevant and validates completeness

**Acceptance Criteria:**
- [ ] AC-9.1: Pre-scan interview asks about external resources conversationally (URLs, MCP servers, skills, etc.)
- [ ] AC-9.2: Pre-scan interview asks about specific areas to focus on
- [ ] AC-9.3: Pre-scan interview asks about areas lacking comments needing extra attention
- [ ] AC-9.4: External resources are collected flexibly - user can provide any type in any format
- [ ] AC-9.5: Post-scan review shows summary of findings (components, categories, counts, external resources)
- [ ] AC-9.6: Post-scan review asks "Did I find everything you were looking for?"
- [ ] AC-9.7: User can provide feedback and request re-scan or adjustments
- [ ] AC-9.8: Interview flow mirrors Ralph spec workflow (start.md, research.md, requirements.md patterns)
- [ ] AC-9.9: `--quick` flag skips interview and proceeds directly to scan (no external resources indexed)

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | `/ralph-specum:index` command scans codebase | High | Runs without error, detects components |
| FR-2 | Component detection by path patterns | High | Categorizes controllers, services, models, helpers, migrations |
| FR-3 | Code analysis extracts functions, exports, dependencies | High | Populated in generated specs |
| FR-4 | Specs stored in `specs/.index/components/` | High | Files created with correct template |
| FR-5 | External resources discovered via interview | High | Supports URLs, MCP servers, skills; stores specs |
| FR-6 | Spec scanner enhanced to search `.index` | High | Research finds indexed specs |
| FR-7 | Start command hint when no index | Medium | Shows tip on first run |
| FR-8 | Filter by path with `--path` | Medium | Only indexes specified directory |
| FR-9 | Filter by type with `--type` | Medium | Only indexes specified types |
| FR-10 | Exclude patterns with `--exclude` | Medium | Skips matching files |
| FR-11 | Dry run with `--dry-run` | Medium | Shows preview, no writes |
| FR-12 | Force regenerate with `--force` | Medium | Overwrites existing specs |
| FR-13 | Changed-only with `--changed` | Low | Uses git to detect changes |
| FR-14 | Index summary file `index.md` | Medium | Auto-generated, lists all specs |
| FR-15 | Interactive mode with `--interactive` | Low | Prompts y/n per component |
| FR-16 | Batch mode (default) | High | No prompts, generates all |
| FR-17 | Pre-scan interview with AskUserQuestion | High | Asks 3+ questions before scanning |
| FR-18 | Pre-scan: external resources question | High | Asks conversationally about URLs, MCP servers, skills, or other resources |
| FR-19 | Pre-scan: focus areas question | High | Asks about directories/modules to prioritize |
| FR-20 | Pre-scan: sparse areas question | Medium | Asks about code lacking comments |
| FR-21 | Post-scan review summary | High | Shows component counts by category |
| FR-22 | Post-scan completeness check | High | Asks user to validate findings |
| FR-23 | Post-scan feedback loop | Medium | Allows re-scan or adjustments based on feedback |
| FR-24 | `--quick` skips interview | High | Quick mode bypasses pre/post interview |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Performance | Index 100 files | < 60 seconds |
| NFR-2 | Memory | Large codebase (1000+ files) | No OOM errors |
| NFR-3 | Reliability | External URL fetch | Timeout after 30s, graceful error |
| NFR-4 | Usability | Zero config start | Works with defaults |
| NFR-5 | Compatibility | Codebase types | JS/TS, Python, Go (configurable patterns) |
| NFR-6 | Maintainability | Spec template | Editable by users |
| NFR-7 | Idempotency | Rerun safety | Same input = same output |

## Glossary

- **Component Spec**: Auto-generated spec file describing a single code component (controller, service, etc.)
- **External Doc Spec**: Spec generated from external documentation source (URL)
- **Index**: The collection of auto-generated specs in `specs/.index/`
- **Component Type**: Category of code (controller, service, model, helper, migration)
- **Spec Scanner**: Existing feature in `/ralph-specum:start` that finds related specs

## Out of Scope

- Real-time/automatic re-indexing on file changes (manual trigger only)
- Semantic code understanding beyond pattern matching (no AI summarization)
- Version control for generated specs (they're regeneratable)
- Multi-repo indexing (single repo per index)
- Private/authenticated external docs (public URLs only for v1)
- Diagram generation (Mermaid, etc.) - future enhancement
- Spec quality scoring or coverage metrics

## Dependencies

- Claude Code tools: Glob, Read, Write, WebFetch
- Git (optional, for `--changed` mode)
- Existing templates in `plugins/ralph-specum/templates/`
- Spec scanner in `plugins/ralph-specum/commands/start.md`
- Research analyst in `plugins/ralph-specum/agents/research-analyst.md`

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Large codebases cause slow indexing | Medium | Batch processing, progress indicator, filters |
| External docs unavailable/changed | Low | Cache locally, show fetch date, graceful fallback |
| Over-indexing creates noise | Medium | Default excludes (node_modules, vendor, dist) |
| Generated specs become stale | Medium | Hash-based change detection, `--changed` flag |

## Success Criteria

1. **Feature adoption**: Users can run `/ralph-specum:index` and generate specs for 80%+ of identifiable components
2. **Discovery value**: New feature research surfaces relevant indexed specs via keyword search
3. **External integration**: At least one external doc URL can be indexed successfully
4. **No workflow disruption**: Existing `/ralph-specum:start` flow works unchanged, with index as additive enhancement

## Unresolved Questions

- What default exclude patterns work across JS/TS, Python, Go ecosystems?
- Should indexed specs be gitignored (regeneratable) or committed (reviewed)?
- How should MCP server capabilities be documented (list all tools? summarize?)?

## Next Steps

1. Review requirements with stakeholder
2. Proceed to design phase to architect component analyzer
3. Define spec templates for component and external doc types
4. Plan scanner enhancement for `.index` directory search
