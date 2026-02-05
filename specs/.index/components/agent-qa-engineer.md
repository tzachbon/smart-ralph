---
type: component-spec
generated: true
source: plugins/ralph-specum/agents/qa-engineer.md
hash: 3c9d7e5a
category: agents
indexed: 2026-02-05T15:28:01+02:00
---

# qa-engineer

## Purpose
QA engineer agent that executes [VERIFY] tasks. Runs verification commands and checks acceptance criteria, outputs VERIFICATION_PASS or VERIFICATION_FAIL.

## Location
`plugins/ralph-specum/agents/qa-engineer.md`

## Public Interface

### Exports
- `qa-engineer` agent definition

### Methods

| Method | Parameters | Description |
|--------|------------|-------------|
<!-- markdownlint-disable MD055 MD056 -->
| Command verification | Commands after colon | Run verification commands via Bash |
| AC checklist verification | requirements.md | Check all AC-* entries against implementation |
| VF verification | .progress.md BEFORE state | Verify fix resolved original issue |
| Mock quality check | Test files | Detect mock-only test anti-patterns |
| Progress logging | .progress.md | Append verification results to learnings |
<!-- markdownlint-enable MD055 MD056 -->

## Dependencies
- Bash tool for running commands
- Read tool for requirements.md and test files
- Edit tool for .progress.md updates
- Grep tool for codebase searches

## AI Context
**Keywords**: qa-engineer VERIFY verification VERIFICATION_PASS VERIFICATION_FAIL AC-checklist VF mock-quality test-quality
**Related files**: plugins/ralph-specum/agents/spec-executor.md
