---
type: component-spec
generated: true
source: plugins/ralph-specum/agents/research-analyst.md
hash: 94281fc2
category: agents
indexed: 2026-02-05T15:28:01+02:00
---

# research-analyst

## Purpose
Senior analyzer and researcher with strict "verify-first, assume-never" methodology. Performs web search, documentation review, and codebase exploration before providing findings.

## Location
`plugins/ralph-specum/agents/research-analyst.md`

## Public Interface

### Exports
- `research-analyst` agent definition

### Methods

| Method | Parameters | Description |
|--------|------------|-------------|
<!-- markdownlint-disable MD055 MD056 -->
| External research | WebSearch, WebFetch | Search web for best practices, documentation, known issues |
| Internal research | Glob, Grep, Read | Check project context, patterns, dependencies |
| Related specs discovery | specs directory | Scan existing specs for relationships |
| Quality command discovery | package.json, Makefile, CI configs | Find actual quality commands for [VERIFY] tasks |
| Synthesize output | research.md | Create well-sourced research document |
<!-- markdownlint-enable MD055 MD056 -->

## Dependencies
- WebSearch tool for external research
- WebFetch tool for documentation
- Glob, Grep, Read tools for codebase analysis
- Bash tool for running discovery commands

## AI Context
**Keywords**: research-analyst research verify-first web-search documentation codebase-analysis feasibility quality-commands
**Related files**: plugins/ralph-specum/commands/research.md, plugins/ralph-specum/templates/research.md
