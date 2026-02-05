---
type: external-spec
generated: true
source-type: url
source-id: https://github.com/github/spec-kit/blob/main/spec-driven.md
fetched: 2026-02-05T15:28:01+02:00
---

# Specification-Driven Development Methodology

## Source
- **Type**: url
- **URL/ID**: https://github.com/github/spec-kit/blob/main/spec-driven.md
- **Fetched**: 2026-02-05T15:28:01+02:00

## Summary
SDD inverts traditional development by making specifications the primary artifact. Rather than treating code as the source of truth, specifications now generate implementation. The methodology treats "the specification as the lingua franca" while code becomes its expression.

## Key Sections

### Three-Command Workflow

#### `/speckit.specify`
- Auto-generates feature numbers by scanning existing specs
- Creates semantic branch names automatically
- Establishes proper directory structure (`specs/[branch-name]/`)

#### `/speckit.plan`
- Analyzes requirements and acceptance criteria
- Ensures constitutional compliance
- Generates supporting documents: data models, API contracts, research

#### `/speckit.tasks`
- Converts contracts and entities into specific tasks
- Marks parallelizable work with `[P]` indicators
- Outputs `tasks.md` ready for agent execution

### File Structure
```
specs/[feature-branch]/
├── spec.md           # What & why
├── plan.md           # How structured
├── data-model.md     # Entity definitions
├── research.md       # Technical investigation
├── contracts/        # API specifications
├── quickstart.md     # Key validation scenarios
└── tasks.md          # Executable task breakdown
```

### Nine Constitutional Articles
- **Article I**: Every feature begins as standalone, reusable library
- **Article II**: All libraries expose functionality through CLI
- **Article III**: "No implementation code shall be written before unit tests"
- **Articles VII & VIII**: Limit to three projects; use frameworks directly
- **Article IX**: Prefer real databases over mocks; contract tests required

### Template-Driven Quality Controls
- **Clarity Markers**: `[NEEDS CLARIFICATION]` tags for ambiguities
- **Completeness Checklists**: Systematic self-review
- **Constitutional Gates**: Pre-implementation checks
- **Test-First Ordering**: Mandate test creation before implementation

### Operational Principles
- Specifications remain source of truth across iterations
- Changes propagate: modify requirements → regenerate plans → update tasks
- Multiple implementations can be explored from single specifications
- Consistency validation occurs continuously

## AI Context
**Keywords**: speckit specification constitution library-first cli-mandate test-first parallelizable clarity-markers contracts
**Related components**: plugins/ralph-speckit, plugins/ralph-specum
