---
name: ralph:requirements
description: Generate product requirements — user stories, acceptance criteria, and functional/non-functional requirements
---

# Requirements Phase

## Overview

The requirements phase translates research findings into structured product requirements. It answers three questions:

1. **Who benefits?** -- Define user stories with clear personas and value propositions.
2. **What must it do?** -- Specify functional requirements with priority and acceptance criteria.
3. **What constraints apply?** -- Capture non-functional requirements (performance, security, reliability).

Requirements produces `requirements.md` in the spec directory and sets `awaitingApproval: true` in state so the user reviews requirements before moving to design.

### Inputs

- `specs/<name>/research.md` -- Research findings, codebase analysis, feasibility assessment.
- `specs/<name>/.progress.md` -- Original goal and learnings from research phase.
- `specs/<name>/.ralph-state.json` -- Current state (should have `phase: "requirements"`).

### Output

- `specs/<name>/requirements.md` -- Structured requirements (see template below).
- Updated `.ralph-state.json` with `awaitingApproval: true`.
- Appended learnings in `.progress.md`.

---

## Steps

### 1. Read Research Findings

Read `research.md` and `.progress.md` to understand the context:

```bash
SPEC_DIR="./specs/<name>"
cat "$SPEC_DIR/research.md"
cat "$SPEC_DIR/.progress.md"
```

Extract key inputs:
- Original goal from `.progress.md`
- Feasibility assessment from research
- Existing patterns and constraints from codebase analysis
- Recommendations for requirements from research

### 2. Define User Stories

For each distinct user interaction or capability, create a user story:

```markdown
### US-1: [Story Title]

**As a** [user type]
**I want to** [action/capability]
**So that** [benefit/value]

**Acceptance Criteria:**
- AC-1.1: [Specific, testable criterion]
- AC-1.2: [Specific, testable criterion]
```

Guidelines for acceptance criteria:
- Each criterion must be testable (can be verified with a command or automated check)
- Avoid ambiguous language ("fast", "easy", "simple", "better")
- Include boundary conditions and edge cases
- Reference specific behavior, not implementation details

### 3. Define Functional Requirements

Create a table of functional requirements with priority and verification:

```markdown
## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | [description] | High | [how to verify] |
| FR-2 | [description] | Medium | [how to verify] |
| FR-3 | [description] | Low | [how to verify] |
```

Priority guidelines:
- **High**: Must-have for the feature to work at all
- **Medium**: Important for production quality but not POC-blocking
- **Low**: Nice-to-have, can be deferred

### 4. Define Non-Functional Requirements

Capture performance, security, reliability, and other cross-cutting concerns:

```markdown
## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Performance | [metric] | [target value] |
| NFR-2 | Reliability | [metric] | [target value] |
| NFR-3 | Security | [standard] | [compliance level] |
```

Base NFRs on research findings -- use discovered constraints and project conventions.

### 5. Define Scope Boundaries

Explicitly list what is out of scope to prevent scope creep:

```markdown
## Out of Scope
- [Item explicitly not included]
- [Another exclusion]
```

Also document dependencies and risks:

```markdown
## Dependencies
- [External dependency or prerequisite]

## Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| [Risk 1] | High/Medium/Low | [How to mitigate] |
```

### 6. Define Success Criteria

State measurable outcomes that define success:

```markdown
## Success Criteria
- [Measurable outcome]
- [Another measurable outcome]
```

### 7. Write requirements.md

Create `specs/<name>/requirements.md` with all sections organized into the standard format (see Output Format below).

### 8. Update State and Progress

Update `.ralph-state.json` to signal completion:

```bash
SPEC_DIR="./specs/<name>"
jq '.awaitingApproval = true' "$SPEC_DIR/.ralph-state.json" > /tmp/state.json && mv /tmp/state.json "$SPEC_DIR/.ralph-state.json"
```

Append any significant discoveries to the `## Learnings` section of `.progress.md`:

- Ambiguities discovered during requirements analysis
- Scope decisions that may affect implementation
- Business logic complexities uncovered
- Dependencies between user stories
- Assumptions made that should be validated

---

## Advanced

### Output Format: requirements.md Template

```markdown
# Requirements: <Feature Name>

## Goal

[1-2 sentence description of what this feature accomplishes and why it matters]

## User Stories

### US-1: [Story Title]

**As a** [user type]
**I want to** [action/capability]
**So that** [benefit/value]

**Acceptance Criteria:**
- AC-1.1: [Specific, testable criterion]
- AC-1.2: [Specific, testable criterion]

### US-2: [Story Title]

**As a** [user type]
**I want to** [action/capability]
**So that** [benefit/value]

**Acceptance Criteria:**
- AC-2.1: [Specific, testable criterion]
- AC-2.2: [Specific, testable criterion]

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | [description] | High | [how to verify] |
| FR-2 | [description] | Medium | [how to verify] |
| FR-3 | [description] | Low | [how to verify] |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Performance | [metric] | [target value] |
| NFR-2 | Reliability | [metric] | [target value] |
| NFR-3 | Security | [standard] | [compliance level] |

## Glossary

- **[Term 1]**: [Definition relevant to this feature]
- **[Term 2]**: [Another domain-specific term]

## Out of Scope

- [Item explicitly not included in this implementation]
- [Another exclusion to prevent scope creep]

## Dependencies

- [External dependency or prerequisite]
- [Another dependency]

## Success Criteria

- [Measurable outcome that defines success]
- [Another measurable outcome]

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| [Risk 1] | High/Medium/Low | [How to mitigate] |
| [Risk 2] | High/Medium/Low | [How to mitigate] |
```

### Requirements Quality Checklist

Before finalizing, verify:

- [ ] Every user story has testable acceptance criteria
- [ ] No ambiguous language ("fast", "easy", "simple", "better")
- [ ] Clear priority for each functional requirement
- [ ] Non-functional requirements have measurable targets
- [ ] Out-of-scope section prevents scope creep
- [ ] Glossary defines domain-specific terms
- [ ] Success criteria are measurable
- [ ] Set `awaitingApproval: true` in state file
- [ ] Appended learnings to `.progress.md`

### Anti-Patterns

- **Never skip research review** -- Requirements must be grounded in research findings.
- **Never write untestable criteria** -- If you cannot describe how to verify it, it is not an acceptance criterion.
- **Never omit out-of-scope** -- Every feature has boundaries. Make them explicit.
- **Never use vague priorities** -- High/Medium/Low with clear rationale, not "important" or "nice to have".
- **Never hide assumptions** -- State them explicitly so they can be validated.
