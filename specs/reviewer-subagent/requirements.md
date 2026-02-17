---
spec: reviewer-subagent
phase: requirements
created: 2026-02-17
generated: auto
---

# Requirements: reviewer-subagent

## Summary

Add a spec-reviewer sub-agent to the Ralph Specum plugin that validates artifact quality after each spec phase and implementation correctness during execution, iterating with the orchestrator up to 3 times before presenting output to users.

## User Stories

### US-1: Phase Artifact Review

As a spec user, I want each spec artifact (research, requirements, design, tasks) to be automatically reviewed before I see it, so that I receive higher-quality, grounded, and consistent output.

**Acceptance Criteria**:
- AC-1.1: After research-analyst completes, coordinator delegates artifact to spec-reviewer before setting awaitingApproval
- AC-1.2: After product-manager completes, coordinator delegates artifact to spec-reviewer before setting awaitingApproval
- AC-1.3: After architect-reviewer completes, coordinator delegates artifact to spec-reviewer before setting awaitingApproval
- AC-1.4: After task-planner completes, coordinator delegates artifact to spec-reviewer before setting awaitingApproval
- AC-1.5: Reviewer outputs REVIEW_PASS or REVIEW_FAIL with structured findings
- AC-1.6: On REVIEW_FAIL, coordinator re-invokes phase agent with reviewer feedback, then re-reviews
- AC-1.7: Review loop limited to max 3 iterations per artifact

### US-2: Execution Review

As a spec user, I want completed tasks reviewed for correctness and spec alignment, so that implementation issues are caught early and fixed automatically.

**Acceptance Criteria**:
- AC-2.1: After spec-executor completes a task (TASK_COMPLETE), coordinator can invoke spec-reviewer to check implementation
- AC-2.2: Reviewer checks implementation against design.md and requirements.md for alignment
- AC-2.3: On REVIEW_FAIL, reviewer can suggest new fix tasks to be added to tasks.md
- AC-2.4: On REVIEW_FAIL, reviewer can suggest spec file updates (requirements.md, design.md)
- AC-2.5: Execution review iterates up to 3 times before accepting with warnings

### US-3: Iteration Loop with Convergence

As the coordinator, I want a bounded review loop that converges or gracefully degrades, so that the workflow never gets stuck in infinite review cycles.

**Acceptance Criteria**:
- AC-3.1: Max 3 review iterations per artifact/task enforced by coordinator
- AC-3.2: On reaching max iterations without REVIEW_PASS, coordinator proceeds with quality warnings appended to .progress.md
- AC-3.3: Reviewer convergence signal is "REVIEW_PASS" with optional notes
- AC-3.4: Each review iteration's findings logged in .progress.md for context

### US-4: Quick Mode Review

As a quick-mode user, I want the plan-synthesizer to include a review step, so that auto-generated artifacts are validated before execution begins.

**Acceptance Criteria**:
- AC-4.1: plan-synthesizer invokes spec-reviewer after generating all four artifacts
- AC-4.2: Review applies to all four artifacts in sequence (research, requirements, design, tasks)
- AC-4.3: Max 3 iterations per artifact in quick mode review
- AC-4.4: Quick mode review uses same rubric as phase-by-phase review

### US-5: Reviewer Agent Definition

As a plugin developer, I want the spec-reviewer defined as a markdown agent following existing patterns, so that it integrates seamlessly with the plugin infrastructure.

**Acceptance Criteria**:
- AC-5.1: `spec-reviewer.md` exists in `plugins/ralph-specum/agents/` with correct frontmatter
- AC-5.2: Agent has type-specific rubrics for each artifact type (research, requirements, design, tasks, execution)
- AC-5.3: Agent uses REVIEW_PASS/REVIEW_FAIL signal pattern consistent with qa-engineer
- AC-5.4: Agent receives artifact content via Task delegation prompt (reads files, does not modify them)
- AC-5.5: Agent is registered in plugin.json (version bump applied)

## Functional Requirements

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| FR-1 | Create spec-reviewer.md agent with review rubrics per artifact type | Must | US-5 |
| FR-2 | Add review loop to research.md command between merge and awaitingApproval | Must | US-1 |
| FR-3 | Add review loop to requirements.md command between generation and awaitingApproval | Must | US-1 |
| FR-4 | Add review loop to design.md command between generation and awaitingApproval | Must | US-1 |
| FR-5 | Add review loop to tasks.md command between generation and awaitingApproval | Must | US-1 |
| FR-6 | Add review checkpoint in implement.md coordinator after task completion | Should | US-2 |
| FR-7 | Add review step in plan-synthesizer.md for quick mode | Should | US-4 |
| FR-8 | Implement max 3 iteration enforcement in all review loops | Must | US-3 |
| FR-9 | Implement graceful degradation (proceed with warnings) on max iterations | Must | US-3 |
| FR-10 | Log review findings in .progress.md per iteration | Must | US-3 |
| FR-11 | Bump version in plugin.json and marketplace.json | Must | US-5 |
| FR-12 | Add review step in start.md for quick mode flow | Should | US-4 |

## Non-Functional Requirements

| ID | Requirement | Category |
|----|-------------|----------|
| NFR-1 | Review loop adds no more than 3 extra subagent invocations per phase (bounded by max iterations) | Performance |
| NFR-2 | Reviewer is read-only; never modifies spec artifacts directly | Safety |
| NFR-3 | Review findings are structured (JSON-like) for coordinator to parse | Maintainability |
| NFR-4 | Existing workflow unchanged when reviewer is not invoked (backwards compatible) | Compatibility |
| NFR-5 | All review signals (REVIEW_PASS/REVIEW_FAIL) follow existing VERIFICATION pattern | Consistency |

## Out of Scope

- Reviewer modifying files directly (it only provides feedback; coordinator/phase-agent applies fixes)
- Real-time review during spec-executor task execution (only post-task review)
- Review of .progress.md or .ralph-state.json files
- UI/CLI for review configuration (hardcoded max 3 iterations)
- Review of commit messages or git operations

## Dependencies

- Existing Task tool infrastructure for subagent delegation
- Existing agent markdown format with frontmatter
- Existing VERIFICATION_PASS/FAIL signal pattern from qa-engineer
- Existing awaitingApproval state pattern in phase commands

## Glossary

| Term | Definition |
|------|-----------|
| Phase Review | Automated quality check of a spec artifact before user presentation |
| Execution Review | Quality check of implementation after task completion |
| Review Loop | Coordinator-managed cycle: review -> feedback -> revise -> re-review |
| Graceful Degradation | Proceeding with best result + warnings when max iterations reached |
| REVIEW_PASS | Signal that artifact meets quality standards |
| REVIEW_FAIL | Signal that artifact needs revision, includes structured findings |
