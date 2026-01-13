---
spec: plan-source-feature
phase: requirements
created: 2026-01-13
---

# Requirements: Quick Start Mode (--quick flag)

## Goal

Allow users to skip spec phases (research, requirements, design) and jump directly to task execution by providing their own plan or goal. The system auto-generates all spec artifacts in a single pass without user interaction.

## User Stories

### US-1: Quick Start with Goal String

**As a** developer with a clear feature in mind
**I want to** start execution immediately with just a goal description
**So that** I avoid the overhead of the full spec workflow for straightforward features

**Acceptance Criteria:**
- [ ] AC-1.1: Running `/ralph-specum:start "Build auth with JWT" --quick` creates a spec with auto-generated name
- [ ] AC-1.2: All four spec artifacts (research.md, requirements.md, design.md, tasks.md) are generated without prompts
- [ ] AC-1.3: State file shows `source: "plan"` and `phase: "tasks"` after generation
- [ ] AC-1.4: User can immediately run `/ralph-specum:implement` to start execution

### US-2: Quick Start with Explicit Name

**As a** developer who wants control over spec naming
**I want to** provide both name and goal in quick mode
**So that** the spec directory follows my naming convention

**Acceptance Criteria:**
- [ ] AC-2.1: Running `/ralph-specum:start my-feature "Build auth" --quick` creates `./specs/my-feature/`
- [ ] AC-2.2: Provided name is used verbatim (no auto-inference)
- [ ] AC-2.3: Goal is used as input for auto-generation

### US-3: Quick Start from Plan File

**As a** developer with an existing plan document
**I want to** import my plan file and skip to execution
**So that** I can reuse plans written outside ralph-specum

**Acceptance Criteria:**
- [ ] AC-3.1: Running `/ralph-specum:start ./my-plan.md --quick` reads the file as plan input
- [ ] AC-3.2: Spec name is inferred from plan content when not provided
- [ ] AC-3.3: File paths starting with `./`, `/`, or ending in `.md` are detected as files
- [ ] AC-3.4: Error displayed if file does not exist or is empty

### US-4: Quick Start with Existing Plan in Spec Directory

**As a** developer who pre-created a plan in the spec folder
**I want to** run quick mode against that plan
**So that** I can prepare plans before starting execution

**Acceptance Criteria:**
- [ ] AC-4.1: Running `/ralph-specum:start my-feature --quick` checks for `./specs/my-feature/plan.md`
- [ ] AC-4.2: If plan.md exists, it is used as input for auto-generation
- [ ] AC-4.3: If no plan.md exists and name looks like kebab-case, prompt for goal

### US-5: Fully Autonomous Execution

**As a** developer who wants maximum speed
**I want** execution to start immediately after generation
**So that** I don't need any additional commands

**Acceptance Criteria:**
- [ ] AC-5.1: After generation, execution starts automatically without prompts
- [ ] AC-5.2: Generated artifacts marked with `generated: auto` in frontmatter
- [ ] AC-5.3: Brief summary shown before execution begins (task count only)

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | Add `--quick` flag to `/ralph-specum:start` command | High | Flag parsed and triggers quick flow |
| FR-2 | Detect input type: file path vs name vs goal string | High | File paths detected by `./`, `/`, or `.md` suffix |
| FR-3 | Auto-infer spec name from goal/plan content | High | Generates valid kebab-case name |
| FR-4 | Auto-generate all spec artifacts in single pass | High | Creates research.md, requirements.md, design.md, tasks.md |
| FR-5 | Set state `source: "plan"` for quick-started specs | High | State file reflects plan source |
| FR-6 | Start execution immediately after generation | High | State set to execution phase, spec-executor invoked |
| FR-7 | Validate plan input (non-empty, file exists) | Medium | Error message for invalid input |
| FR-8 | Support reading plan from `./specs/$name/plan.md` | Medium | Checks for existing plan file |
| FR-9 | Display generation summary after completion | Medium | Shows task count and artifact status |
| FR-10 | Mark generated artifacts with `generated: auto` | Low | Frontmatter includes generated field |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Generation speed | Time to generate all artifacts | Under 60 seconds for typical goal |
| NFR-2 | Generated task quality | Tasks follow POC-first 4-phase structure | 100% compliance |
| NFR-3 | Backwards compatibility | Existing specs unaffected | Zero breaking changes |
| NFR-4 | Error recoverability | Failed generation leaves no partial state | Clean rollback on failure |

## Glossary

- **Quick mode**: Workflow that skips manual spec phases and auto-generates artifacts from user-provided plan/goal
- **Plan source**: State where `source: "plan"`, indicating tasks were derived from quick mode rather than full workflow
- **Auto-generation**: AI-driven creation of spec artifacts (research, requirements, design, tasks) from a single input
- **POC-first structure**: 4-phase task breakdown: Foundation/Scaffolding, Core Implementation, Integration, Polish/Cleanup

## Out of Scope

- Interactive prompts during quick mode (fully autonomous)
- Review/approval step before execution (user can cancel if needed)
- Structured plan formats (JSON, YAML) as input (markdown/text only for v1)
- Partial quick mode (e.g., skip only research but keep requirements prompts)
- Re-running quick mode on existing spec (use normal commands to regenerate phases)
- Support for `source: "direct"` (manual tasks.md without other artifacts)

## Dependencies

- Existing `/ralph-specum:start` command (extend, not replace)
- Task tool for invoking auto-generation agent
- Schema support for `source: "plan"` (already defined in spec.schema.json)
- spec-executor agent (unchanged, executes generated tasks)

## Success Criteria

- Single command (`--quick`) goes from goal to executing first task with no further input
- Generated tasks pass execution loop without structural issues
- Zero impact on existing full-workflow specs

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Low-quality auto-generation leads to failed tasks | High | Display summary for user review, mark artifacts as auto-generated |
| Vague goals produce vague requirements | Medium | Validate minimum input length (>10 words recommended) |
| Name inference produces duplicates/conflicts | Low | Check for existing spec before creating, error if conflict |
| Scope creep in generated artifacts | Medium | Constrain generation agent to strict plan interpretation |
