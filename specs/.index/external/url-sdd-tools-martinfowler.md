---
type: external-spec
generated: true
source-type: url
source-id: https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html
fetched: 2026-02-05T15:28:01+02:00
---

# Spec-Driven Development (SDD) Tools

## Source
- **Type**: url
- **URL/ID**: https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html
- **Fetched**: 2026-02-05T15:28:01+02:00

## Summary
Spec-driven development involves creating structured, behavior-oriented specifications before writing code with AI assistance. Specs describe intent in structured, testable language, and agents generate code to match them.

## Key Sections

### Three Implementation Levels
1. **Spec-First**: Write specifications upfront, then delete them after task completion
2. **Spec-Anchored**: Maintain specs throughout feature evolution and maintenance phases
3. **Spec-as-Source**: Treat specifications as primary artifacts; humans only edit specs, never code

### Three Tools Compared

#### Kiro (Lightweight)
- Workflow: Requirements → Design → Tasks
- Three markdown documents guide development
- Memory bank called "steering" (product.md, tech.md, structure.md)
- Best for simple, straightforward implementations

#### Spec-Kit (GitHub's CLI)
- Workflow: Constitution → Specify → Plan → Tasks
- Heavy use of checklists for quality tracking
- Constitution serves as immutable architectural rules

#### Tessl Framework (Beta)
- Only tool explicitly pursuing spec-anchored and spec-as-source approaches
- Low abstraction level (one spec per code file)
- Generated code marked as non-editable by humans

### Key Challenges
- **Workflow Scalability**: Fixed workflows poorly accommodate different problem sizes
- **Review Overhead**: Verbose markdown artifacts create tedious review processes
- **Control Issues**: AI agents frequently ignore detailed instructions
- **Specification Clarity**: Separating functional from technical requirements remains challenging

### Critical Consideration
Warning against repeating historical mistakes from Model-Driven Development, which similarly attempted to generate code from specifications but failed due to inflexibility.

## AI Context
**Keywords**: sdd spec-driven-development spec-first spec-anchored spec-as-source kiro spec-kit tessl constitution
**Related components**: plugins/ralph-specum agents, plugins/ralph-speckit
