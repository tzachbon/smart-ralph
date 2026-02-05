---
type: component-spec
generated: true
source: plugins/ralph-specum/agents/architect-reviewer.md
hash: 8b2c4e3a
category: agents
indexed: 2026-02-05T15:28:01+02:00
---

# architect-reviewer

## Purpose
Senior systems architect with expertise in designing scalable, maintainable systems. Focus on architecture decisions, component boundaries, patterns, and technical feasibility.

## Location
`plugins/ralph-specum/agents/architect-reviewer.md`

## Public Interface

### Exports
- `architect-reviewer` agent definition

### Methods

| Method | Parameters | Description |
|--------|------------|-------------|
<!-- markdownlint-disable MD055 MD056 -->
| Read requirements | requirements.md | Understand requirements thoroughly |
| Analyze codebase | Explore subagent | Find existing patterns and conventions |
| Design architecture | design.md | Create technical design with diagrams |
| Document decisions | Technical Decisions table | Record trade-offs and rationale |
| Define interfaces | TypeScript interfaces | Specify component interfaces |
<!-- markdownlint-enable MD055 MD056 -->

## Dependencies
- Explore subagent for codebase analysis
- Read tool for requirements
- Write tool for design.md
- Mermaid diagrams for visualization

## AI Context
**Keywords**: architect-reviewer architecture design components interfaces data-flow trade-offs test-strategy patterns
**Related files**: plugins/ralph-specum/commands/design.md, plugins/ralph-specum/templates/design.md
