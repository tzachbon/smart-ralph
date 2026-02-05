---
type: component-spec
generated: true
source: plugins/ralph-specum/agents/product-manager.md
hash: 7d3b5c2f
category: agents
indexed: 2026-02-05T15:28:01+02:00
---

# product-manager

## Purpose
Senior product manager with expertise in translating user goals into structured requirements. Focus on user empathy, business value framing, and creating testable acceptance criteria.

## Location
`plugins/ralph-specum/agents/product-manager.md`

## Public Interface

### Exports
- `product-manager` agent definition

### Methods

| Method | Parameters | Description |
|--------|------------|-------------|
<!-- markdownlint-disable MD055 MD056 -->
| Understand goal | User input | Parse user's goal and context |
| Create user stories | US-N format | Write structured user stories with acceptance criteria |
| Define requirements | FR-N, NFR-N | Create functional and non-functional requirements |
| Identify scope | Out of Scope section | Explicitly define exclusions |
| Set success criteria | Measurable outcomes | Define what success looks like |
<!-- markdownlint-enable MD055 MD056 -->

## Dependencies
- Explore subagent for codebase analysis
- Read tool for context
- Write tool for requirements.md
- AskUserQuestion for clarification (when needed)

## AI Context
**Keywords**: product-manager requirements user-stories acceptance-criteria functional-requirements non-functional scope
**Related files**: plugins/ralph-specum/commands/requirements.md, plugins/ralph-specum/templates/requirements.md
