---
name: ralph:research
description: Conduct research for a spec — codebase analysis, external research, and feasibility assessment
---

# Research Phase

## Overview

The research phase gathers information needed to write solid requirements. It answers three questions:

1. **What exists?** -- Explore the codebase for existing patterns, dependencies, conventions, and related implementations.
2. **What is known?** -- Search the web for best practices, prior art, libraries, and pitfalls.
3. **Is it feasible?** -- Assess effort, risk, and technical viability based on findings.

Research produces `research.md` in the spec directory and sets `awaitingApproval: true` in state so the user reviews findings before moving to requirements.

### Inputs

- `specs/<name>/.progress.md` -- Contains the original goal and any learnings from previous phases.
- `specs/<name>/.ralph-state.json` -- Current state (should have `phase: "research"`).

### Output

- `specs/<name>/research.md` -- Structured findings (see template below).
- Updated `.ralph-state.json` with `awaitingApproval: true`.
- Appended learnings in `.progress.md`.

---

## Steps

### 1. Read the Goal

Read `.progress.md` and extract the `## Original Goal` section. This is the primary input for all research.

```bash
SPEC_DIR="./specs/<name>"
cat "$SPEC_DIR/.progress.md"
```

Break the goal into 2-5 research topics. Each topic becomes a thread of investigation.

### 2. Explore the Codebase

For each research topic, search the existing codebase for relevant patterns:

- **Find related files**: Search for files matching keywords from the goal.
- **Read existing implementations**: Look for patterns that the new feature should follow or integrate with.
- **Check dependencies**: Identify existing libraries, utilities, and shared modules that can be leveraged.
- **Note conventions**: Observe naming, structure, error handling, and testing patterns already in use.
- **Scan related specs**: Check other spec directories for overlapping or conflicting work.

Record file paths and code snippets as evidence for each finding.

### 3. Search the Web

For each research topic, search for external information:

- **Best practices**: Current standards and recommended approaches.
- **Prior art**: How others have solved similar problems.
- **Library options**: Available packages, their maturity, and trade-offs.
- **Pitfalls**: Common mistakes, known issues, edge cases.

Record source URLs for every finding.

### 4. Discover Quality Commands

Check the project for available quality/CI commands that future tasks will need:

```bash
# Check package.json scripts
cat package.json | jq -r '.scripts | keys[]' 2>/dev/null || echo "No package.json"

# Check Makefile targets
grep -E '^[a-z_-]+:' Makefile 2>/dev/null | head -20 || echo "No Makefile"

# Check CI workflow commands
grep -rh 'run:' .github/workflows/*.yml 2>/dev/null | head -20 || echo "No CI configs"
```

Look for: `lint`, `typecheck`, `test`, `build`, `e2e`, `integration`, `unit`, `verify`, `check`.

### 5. Assess Feasibility

Based on codebase and external research, evaluate:

| Aspect | Question |
|--------|----------|
| Technical Viability | Can this be built with current architecture? |
| Effort Estimate | How large is this (S/M/L/XL)? |
| Risk Level | What could go wrong? |

### 6. Find Related Specs

Scan existing spec directories for related work:

1. List all specs (check `specs/` and any configured spec directories).
2. For each spec (except the current one), read `.progress.md` for the Original Goal.
3. Classify relevance: **High** (direct overlap), **Medium** (shared components), **Low** (tangential).
4. Note if the current spec may require updates to existing specs.

### 7. Write research.md

Create `specs/<name>/research.md` with all findings organized into the standard sections (see Output Format below).

### 8. Update State and Progress

Update `.ralph-state.json` to signal completion:

```bash
SPEC_DIR="./specs/<name>"
jq '.awaitingApproval = true' "$SPEC_DIR/.ralph-state.json" > /tmp/state.json && mv /tmp/state.json "$SPEC_DIR/.ralph-state.json"
```

Append any significant discoveries to the `## Learnings` section of `.progress.md`:

- Unexpected technical constraints
- Useful patterns found in codebase
- External best practices that differ from current implementation
- Dependencies or limitations affecting future tasks

---

## Advanced

### Parallel vs Sequential Research

When your tool supports delegating work to multiple agents in parallel:

- **Parallel approach**: Break research topics into independent threads. Assign each topic to a separate agent. Merge results into a single `research.md`.
- **Sequential approach**: Research topics one at a time. This works in any tool and is the fallback when parallel delegation is not available.

Both approaches produce the same output. Parallel is faster for large specs with many independent topics.

### Output Format: research.md Template

```markdown
---
spec: <spec-name>
phase: research
created: <timestamp>
---

# Research: <spec-name>

## Executive Summary
[2-3 sentence overview of findings and feasibility]

## External Research

### Best Practices
- [Finding with source URL]

### Prior Art
- [Similar solutions found]

### Pitfalls to Avoid
- [Common mistakes from community]

## Codebase Analysis

### Existing Patterns
- [Pattern found in codebase with file path]

### Dependencies
- [Existing deps that can be leveraged]

### Constraints
- [Technical limitations discovered]

## Related Specs

| Spec | Relevance | Relationship | May Need Update |
|------|-----------|--------------|-----------------|
| <spec-name> | High/Medium/Low | <why related> | Yes/No |

### Coordination Notes
[How this spec relates to existing specs, potential conflicts]

## Quality Commands

| Type | Command | Source |
|------|---------|--------|
| Lint | `<command>` | <where found> |
| TypeCheck | `<command>` | <where found> |
| Unit Test | `<command>` | <where found> |
| Build | `<command>` | <where found> |

**Local CI**: `<combined command>`

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | High/Medium/Low | [Why] |
| Effort Estimate | S/M/L/XL | [Basis] |
| Risk Level | High/Medium/Low | [Key risks] |

## Recommendations for Requirements

1. [Specific recommendation based on research]
2. [Another recommendation]

## Open Questions

- [Questions that need clarification]

## Sources
- [URL with description]
- [File path with context]
```

### Research Quality Checklist

Before finalizing, verify:

- [ ] Searched the web for current information on each topic
- [ ] Explored the codebase for existing patterns and conventions
- [ ] Cross-referenced external best practices with internal implementation
- [ ] Cited all sources (URLs and file paths)
- [ ] Identified uncertainties and open questions
- [ ] Provided actionable recommendations for requirements
- [ ] Discovered and documented quality commands
- [ ] Scanned for related specs
- [ ] Set `awaitingApproval: true` in state file
- [ ] Appended learnings to `.progress.md`

### Anti-Patterns

- **Never guess** -- If information is not found, say so explicitly.
- **Never skip web search** -- External information may be more current than your training data.
- **Never skip codebase exploration** -- Project-specific patterns override general best practices.
- **Never provide unsourced claims** -- Every finding needs a source (URL or file path).
- **Never hide uncertainty** -- Be explicit about confidence level and flag open questions.
