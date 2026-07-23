# Requirements: {{FEATURE_NAME}}

## Problem Statement

<!-- Quick mode with no research evidence: derive from the goal + stated assumptions or use `TBD (user, next review)` -- never fabricate evidence. -->
{{problem}} affecting {{affected user}}. Evidence: {{evidence pointer to research.md}}

## Goal

{{1-2 sentence description of what this feature accomplishes and why it matters}}

## User Stories

### US-1: {{Story Title}}

**As a** {{user type}}
**I want to** {{action/capability}}
**So that** {{benefit/value}}

**Acceptance Criteria:**
- AC-1.1: Given {{context}}, When {{action}}, Then {{observable outcome}}
- AC-1.2: Given {{context}}, When {{action}}, Then {{observable outcome}}

### US-2: {{Story Title}}

**As a** {{user type}}
**I want to** {{action/capability}}
**So that** {{benefit/value}}

**Acceptance Criteria:**
- AC-2.1: Given {{context}}, When {{action}}, Then {{observable outcome}}
- AC-2.2: Given {{context}}, When {{action}}, Then {{observable outcome}}

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | System MUST {{description}} | Must | AC-1.1, AC-1.2 |
| FR-2 | System SHOULD {{description}} | Should | AC-2.1 |
| FR-3 | System MAY {{description}} | Could | AC-2.2 |

## Non-Functional Requirements

<!-- Every row must have Metric and Target filled, or Target set to `N/A: <reason>`. Delete unused boilerplate rows. -->

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Performance | {{metric}} | {{target value}} |
| NFR-2 | Reliability | {{metric}} | {{target value}} |
| NFR-3 | Security | {{standard}} | {{compliance level}} |

## Glossary

- **{{Term 1}}**: {{Definition relevant to this feature}}
- **{{Term 2}}**: {{Another domain-specific term}}

## Out of Scope

Default-scope rule: anything not listed here that falls under the Goal is in scope.

- {{Non-goal explicitly not included in this implementation}}
- {{Another non-goal to prevent scope creep}}

## Dependencies

- {{External dependency or prerequisite}}
- {{Another dependency}}

## Success Criteria

- {{Measurable outcome that defines success}}
- {{Another measurable outcome}}

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| {{Risk 1}} | High/Medium/Low | {{How to mitigate}} |
| {{Risk 2}} | High/Medium/Low | {{How to mitigate}} |

## Unresolved Questions

<!-- Open ambiguities that still need a decision. Each bullet needs an owner and date (e.g., `Owner: name, 2026-08-01`), or state "None". -->

- {{Open question}} Owner: {{name}}, {{expected date}}
