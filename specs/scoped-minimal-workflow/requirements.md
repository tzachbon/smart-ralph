---
spec: scoped-minimal-workflow
phase: requirements
created: 2026-08-27
generated: auto
---

# Requirements: scoped-minimal-workflow

## Problem Statement

Ralph Specum has general simplicity and scope language, but no single authorization boundary survives every phase. It also lacks an ordered decision for whether new code, a dependency, or an abstraction is necessary. Evidence: `research.md` Codebase Analysis.

## Goal

Bind a positive scope envelope before research, preserve it through planning and execution, stop for a new decision when work would expand it, and choose the first existing mechanism that satisfies the current requirement and verification contract.

## Scope Envelope

- Target: The Claude Ralph Specum intake, planning, execution, and coordination prompts.
- Action: Add prompt-level behavior and tests through an open pull request.
- Bounds: Modify seven active Claude-plugin prompt files, one new Bats test, two Ralph Specum version entries, and this spec. Do not modify the Codex plugin, hooks, schemas, dependencies, or unrelated files.
- Deliverable: One reviewed pull request that demonstrates the workflow contract.
- Complete when: Local checks pass, every triggered GitHub check passes, and no pull-request review thread remains unresolved.
- Escalate when: A required fix changes another plugin, adds an external side effect, performs a destructive action, merges or closes the pull request, or broadens the behavior contract.

## User Stories

### US-1: Bind scope before research

**As a** Ralph Specum user
**I want to** record the authorized target, action, bounds, result, finish condition, and escalation point once
**So that** later agents do not reinterpret my request

**Acceptance Criteria:**
- AC-1.1: Given normal start intake has resolved the goal interview, When research begins, Then `.progress.md` already contains all six scope-envelope fields.
- AC-1.2: Given quick input states all six fields, When quick mode starts, Then it derives and persists the envelope before reproduction or research.
- AC-1.3: Given two plausible quick-mode readings would change an envelope field, When Ralph cannot bind that field, Then it sets `quickMode: false`, sets `awaitingApproval: true`, asks one exact question, and starts no reproduction or research.
- AC-1.4: Given a user invokes `/new`, When progress state is created, Then Ralph runs the same normal goal-interview contract before research.
- AC-1.5: Given an action may affect an external system, When Ralph binds `Action` and `Bounds`, Then those fields state whether the user authorized read, draft, write, send, deploy, merge, delete, or the applicable authority level.

### US-2: Plan the smallest correct implementation

**As a** Ralph Specum user
**I want to** reuse project mechanisms before adding ownership burden
**So that** the implementation remains easy to understand and maintain

**Acceptance Criteria:**
- AC-2.1: Given architecture can satisfy a requirement in multiple ways, When architect-reviewer decides, Then it checks repository reuse, project language or framework features, configuration or deletion, and new code in that order.
- AC-2.2: Given a design proposes a new dependency, When an earlier option can satisfy the requirement, Then architect-reviewer rejects the dependency.
- AC-2.3: Given a design proposes a new abstraction, When it has fewer than two current uses and no explicit requirement, Then architect-reviewer rejects the abstraction.
- AC-2.4: Given task-planner writes a task, When it fills `Do` and `Files`, Then it applies the same order and checks the result before completion.
- AC-2.5: Given a shorter path would remove required validation, safety, accessibility, error handling, acceptance criteria, or verification, When an agent applies the ordered choice, Then it keeps the required behavior.

### US-3: Stop execution at the authorization boundary

**As a** Ralph Specum user
**I want to** approve any required expansion before mutation
**So that** execution does not turn an adjacent discovery into unauthorized work

**Acceptance Criteria:**
- AC-3.1: Given spec-executor receives a task, When it is about to mutate, Then it compares `Do`, `Files`, `Done when`, `Verify`, and external effects with the full scope envelope.
- AC-3.2: Given the envelope is missing or the task must change a field, When spec-executor cannot finish inside the boundary, Then it emits `SCOPE_ESCALATION_REQUIRED` with the field, reason, and one exact question before mutation.
- AC-3.3: Given coordinator receives `SCOPE_ESCALATION_REQUIRED`, When it handles the result, Then it records the blocker, sets `awaitingApproval: true`, and leaves task and failure counters unchanged.
- AC-3.4: Given executor requests `ADD_PREREQUISITE` or `ADD_FOLLOWUP`, When coordinator evaluates the request, Then it adds the task only if `Do`, `Files`, `Verify`, and external effects fit the envelope.
- AC-3.5: Given a user approves the expansion, When coordinator resumes, Then it updates the envelope, clears `awaitingApproval`, and replans or retries only after the task fits the new boundary.
- AC-3.6: Given a user declines the expansion, When coordinator resumes, Then it keeps the original envelope, revises or removes the blocked task when the deliverable remains possible, or records the spec as blocked and stops when it does not.
- AC-3.7: Given an agent finds an adjacent non-blocking issue, When it reports the issue, Then Ralph records it as a learning and creates no task without authorization.

### US-4: Prove and release the behavior

**As a** plugin maintainer
**I want to** pin the prompt contract and version change
**So that** reviewers can verify the behavior before release

**Acceptance Criteria:**
- AC-4.1: Given the new Bats test runs, When it inspects active prompt seams, Then it proves all six scope labels, intake order, reuse-first order, executor signal, coordinator state handling, and bounded task modifications are present.
- AC-4.2: Given Ralph Specum files are scanned, When the test searches for source-skill paths, imports, and the headings `# Ponytail` or `# Stay in scope`, Then it finds none.
- AC-4.3: Given the base version is `4.10.5`, When the feature is ready, Then the Ralph Specum manifest and marketplace entry both equal `4.11.0` while the Codex manifest remains unchanged.
- AC-4.4: Given the pull request is open, When delivery finishes, Then every triggered GitHub check is successful, review-thread pagination is complete, and the unresolved thread list is empty.

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | System MUST persist one six-field `## Scope Envelope` block in `.progress.md` before research. | Must | AC-1.1, AC-1.2 |
| FR-2 | System MUST use the existing goal interview for normal intake and `/new`. | Must | AC-1.1, AC-1.4 |
| FR-3 | System MUST disable quick mode and pause when a field-changing ambiguity remains. | Must | AC-1.3 |
| FR-4 | System MUST record the authorized external-action level when relevant. | Must | AC-1.5 |
| FR-5 | System MUST apply the ordered minimal-implementation choice in architect, planner, and executor prompts. | Must | AC-2.1, AC-2.4, AC-2.5 |
| FR-6 | System MUST reject avoidable dependencies and unjustified single-use abstractions. | Must | AC-2.2, AC-2.3 |
| FR-7 | System MUST compare planned and executed tasks with the scope envelope before mutation. | Must | AC-3.1, AC-3.2 |
| FR-8 | System MUST handle scope escalation as an approval stop without consuming a retry. | Must | AC-3.3, AC-3.5, AC-3.6 |
| FR-9 | System MUST keep automatic task modifications and adjacent discoveries inside the envelope. | Must | AC-3.4, AC-3.7 |
| FR-10 | System MUST pin the active prompt contract with Bats tests. | Must | AC-4.1, AC-4.2 |
| FR-11 | System MUST bump both Ralph Specum version entries to `4.11.0`. | Must | AC-4.3 |
| FR-12 | System MUST leave the pull request open with green triggered checks and zero unresolved review threads. | Must | AC-4.4 |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | One scope carrier | Count of persisted scope-policy blocks | 1 canonical block in `.progress.md` |
| NFR-2 | No added runtime ownership | New dependencies, skills, hooks, or schema fields | 0 |
| NFR-3 | Bounded prompt growth | Added non-test production files | 7 existing files, 0 new production files |
| NFR-4 | Prompt quality | Non-ASCII and banned AI-tell scan findings in changed prose | 0 |
| NFR-5 | Regression safety | Failing tests in `bats tests/*.bats` | 0 |
| NFR-6 | Model compliance rate | Deterministic runtime compliance | N/A: prompt-contract tests cannot measure model behavior deterministically |

## Glossary

- **Scope envelope**: Six persisted fields that define authorized work and its stop condition.
- **Authority level**: Whether the user authorized reading, drafting, writing, sending, deploying, merging, deleting, or another external action.
- **Minimal-implementation choice**: Ordered check for reuse, project features, configuration or deletion, and new code.
- **Scope escalation**: A required step that changes any scope-envelope field.

## Out of Scope

Default-scope rule: anything not listed here that falls under the Goal is in scope.

- Modify `plugins/ralph-specum-codex` or its version.
- Add host-level tool interception, a new hook rule, a skill, configuration surface, dependency, or schema field.
- Rewrite existing Karpathy rules, phase architecture, task sizing, or unrelated prompts.
- Merge or close the pull request.

## Dependencies

- Existing `.progress.md` phase context.
- Existing `.ralph-state.json.awaitingApproval` and stop-hook behavior.
- Existing Bats and GitHub Actions workflows.

## Success Criteria

- All AC-1.1 through AC-4.3 have automated prompt-contract or state-path evidence.
- Focused tests, `bats tests/*.bats`, JSON validation, and `git diff --check` pass locally.
- All triggered GitHub checks report success.
- The review-thread query returns `hasNextPage: false` and an empty unresolved list.

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Prompt rules do not mechanically intercept tools. | Medium | Route the explicit escalation signal through the existing approval state gate. |
| Legacy specs have no envelope. | Medium | Stop before mutation and ask one bounded question. |
| Automatic task changes widen the original plan. | High | Apply the envelope check to both task-modification paths. |
| Full Bats updates spec-index files. | Low | Inspect status and exclude unrelated generated changes. |

## Unresolved Questions

None.
