---
spec: ralph-quality-improvements
phase: requirements
created: 2026-04-06
updated: 2026-04-06
---

# Requirements: ralph-quality-improvements

## Goal

Improve Smart Ralph's spec quality by adding self-review checklists to prevent 5 categories of recurring spec errors (Track A), and introduce an External Reviewer Protocol that allows an independent async agent to review completed tasks via filesystem files (Track B).

## User Stories

### US-A1: Prevent Type Annotation Inconsistencies
**As a** spec author
**I want** every Callable type annotation in design.md to be verified against its usage example
**So that** sync/async type mismatches (e.g., `Callable[..., None]` with `await`) are caught before implementation

### US-A2: Detect and Remove Duplicate Document Sections
**As a** spec author
**I want** duplicate H3 headings in any spec document to be detected and removed
**So that** no section appears twice with identical content

### US-A3: Reconcile Stale Text After Partial Updates
**As a** product manager updating an existing requirements.md
**I want** every mention of a replaced concept to be updated or removed across the entire document
**So that** the document header and User Adjustments never contradict the current FRs

### US-A4: Document Concurrency and Ordering Risks Explicitly
**As a** architect reviewer
**I want** every await expression that makes a resource visible to concurrent callers to be documented with its required order
**So that** an implementer cannot accidentally invert a critical sequence

### US-A5: Catch Type Mismatches at Implementation Time
**As a** spec executor
**I want** to verify Callable/Awaitable types match their usage examples before implementing
**So that** type inconsistencies are caught at the point of implementation as a last-resort gate

### US-B1: External Reviewer Can Log Task Results
**As an** external reviewer agent
**I want** to write review results to a task_review.md file in the spec directory
**So that** I can communicate PASS/FAIL/WARNING/PENDING outcomes to Ralph without any shared process

### US-B2: Spec Executor Reads External Reviews Before Each Task
**As a** spec executor
**I want** to read task_review.md at the start of every task
**So that** I respect external review outcomes and apply fixes for FAIL/WARNING entries

### US-B3: Stuck Detection Accounts for External Unmarks
**As a** spec executor
**I want** repeated external unmarks to count toward the stuck threshold
**So that** tasks the external reviewer has already unmarked multiple times escalate without infinite retry loops

### US-B4: External Unmarks Field is Documented in State Schema
**As a** system integrator
**I want** the external_unmarks field to be documented in the .ralph-state.json schema
**So that** I understand when it is written, read, and what values it accepts

## Functional Requirements

### Track A — Spec Quality

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-A1 | Document Self-Review Checklist in architect-reviewer.md | High | architect-reviewer.md has a `<mandatory>` section titled `## Document Self-Review Checklist` with 4 steps (Type consistency, Duplicate section detection, Ordering and concurrency notes, Internal contradiction scan), positioned AFTER "Quality Checklist" and BEFORE "Final Step: Set Awaiting Approval". Checklist adds `[ ] Document Self-Review Checklist passed` to Quality Checklist. |
| FR-A2 | Concurrency & Ordering Risks section in design.md template | High | templates/design.md has `## Concurrency & Ordering Risks` section with the specified table structure, positioned between `## Edge Cases` and `## Test Strategy`. If no risks identified, section must contain "None identified." |
| FR-A3 | On Requirements Update section in product-manager.md | High | product-manager.md has a `<mandatory>` section titled `## On Requirements Update` positioned AFTER "Append Learnings". It describes the 5-step reconciliation process for existing requirements updates. Checklist adds `[ ] If updating existing requirements: On Requirements Update steps completed`. |
| FR-A3b | On Design Update section in architect-reviewer.md | High | architect-reviewer.md has a `<mandatory>` section titled `## On Design Update` describing the same reconciliation process when updating an existing design.md: scan for stale mentions of replaced concepts, update or remove them, verify document header is consistent with current content. Checklist adds `[ ] If updating existing design.md: On Design Update steps completed`. |
| FR-A4 | Type Consistency Pre-Check in spec-executor.md | Medium | spec-executor.md has a subsection titled `### Type Consistency Pre-Check (typed Python or TypeScript tasks)` inside the "Implementation Tasks" section (no tag), positioned after the existing `data-testid` update block. Describes the 5-step verification and escalation process. |

### Track B — External Reviewer Protocol

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-B1 | task_review.md template exists | High | templates/task_review.md exists with the exact structure defined in the spec: title, workflow comment block, and `## Reviews` section with the entry template (status, severity, reviewed_at, criterion_failed, evidence, fix_hint, resolved_at). |
| FR-B2 | External Review Protocol section in spec-executor.md | High | spec-executor.md has a `<mandatory>` section titled `## External Review Protocol` positioned AFTER "## When Invoked" and BEFORE "## Task Loop". Describes the 4-step per-task review reading logic: check existence, read, apply rules by status (FAIL/PENDING/WARNING/PASS), append to .progress.md. |
| FR-B3 | external_unmarks in stuck-detection logic | High | spec-executor.md stuck-detection section references `effectiveIterations = taskIteration + external_unmarks[taskId]` (external_unmarks ADDS to taskIteration — it never replaces it, since they measure different dimensions: taskIteration counts retry attempts in the current session, external_unmarks counts reviewer cycles from prior sessions). Escalates with reason `external-reviewer-repeated-fail` when effectiveIterations >= maxTaskIterations. `external_unmarks` values are never reset by spec-executor. Escalation message includes "External reviewer has unmarked this task N times. Human investigation required." |
| FR-B4 | external_unmarks documented in state schema | Medium | external_unmarks is documented in the state file schema (any file documenting .ralph-state.json fields — README.md, CLAUDE.md, or agent docs) as: type object (map of taskId string to integer), optional default {}, written by external reviewer only, read by spec-executor for stuck detection. |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Surgical changes | Lines modified | Each modification touches only the target section; surrounding content unchanged |
| NFR-2 | No regression | Existing tests | All existing tests in the repo pass after changes |
| NFR-3 | Version bumps | Patch bump | One patch-level version bump applied ONCE at the END of all changes to BOTH `plugins/ralph-specum/.claude-plugin/plugin.json` AND `.claude-plugin/marketplace.json` — not one per file. Current version: 4.9.1 → 4.9.2 |
| NFR-4 | Track separation | Section clarity | Track A and Track B requirements are clearly separated with Track headings |
| NFR-5 | No new dependencies | External services | No new network protocols, polling mechanisms, or external reviewer implementation required |

## Glossary

- **Callable type annotation**: Python type hint like `Callable[[ArgTypes], ReturnType]` declaring a callable signature
- **Awaitable type**: Python `Awaitable[T]` generic for objects that can be awaited (typically async function return types)
- **external_unmarks**: Field in .ralph-state.json tracking how many times an external reviewer has unmarked a given task (cumulative, written only by external reviewer)
- **task_review.md**: File written by external reviewer agent containing review entries for completed tasks
- **Stuck threshold**: Maximum effective iterations (taskIteration + external_unmarks) before spec-executor escalates instead of retrying
- **Concurrency & Ordering Risks**: Section in design.md documenting sequence-critical operations and their required order

## Out of Scope

- External reviewer implementation itself (runs in a different repo/process)
- Any polling mechanism inside Ralph (Ralph is event-driven, not polling)
- Any specific model or provider for the external reviewer
- Any network protocol (filesystem only)
- Changes to research-analyst, task-planner, or triage-analyst agents
- Changes to any command files
- Changes to the anti-stuck pattern logic beyond the external_unmarks addition

## Dependencies

- `plugins/ralph-specum/agents/architect-reviewer.md` — receives Document Self-Review Checklist (FR-A1) and On Design Update section (FR-A3b)
- `plugins/ralph-specum/templates/design.md` — receives Concurrency & Ordering Risks section (FR-A2)
- `plugins/ralph-specum/agents/product-manager.md` — receives On Requirements Update section (FR-A3)
- `plugins/ralph-specum/agents/spec-executor.md` — receives Type Consistency Pre-Check (FR-A4) and External Review Protocol (FR-B2); stuck-detection updated for external_unmarks (FR-B3)
- `plugins/ralph-specum/templates/task_review.md` — new file to be created (FR-B1)
- State schema documentation — external_unmarks field documented (FR-B4)
- `plugins/ralph-specum/.claude-plugin/plugin.json` — version bump 4.9.1 → 4.9.2
- `.claude-plugin/marketplace.json` — version bump 4.9.1 → 4.9.2

## Success Criteria

- Every acceptance criterion is traceable to a specific section in the source spec document
- All 5 Track A FRs produce verifiable in-document changes (not just prose)
- All 4 Track B FRs produce verifiable in-document changes
- No existing behavior of spec-executor is changed except the two documented additions
- external_unmarks is documented in at least one state-schema location
- Version bumped once (4.9.1 → 4.9.2) in both plugin.json and marketplace.json at end of all changes

## User Adjustments

The postmortem analysis established the following priority ordering for Track A improvements. Track B has no ordering dependency and can proceed in parallel.

| Priority | FR | Rationale |
|----------|----|-----------|
| P1 | FR-A1 (architect-reviewer checklist) | Prevents E1, E2, E3, E5 in a single addition — highest leverage |
| P1 | FR-A2 (Concurrency & Ordering Risks template) | Forces explicit documentation of ordering risks in every spec |
| P1 | FR-A3 (On Requirements Update) | Prevents E3 — stale text after partial updates in requirements |
| P1 | FR-A3b (On Design Update) | Prevents E3 — stale text after partial updates in design.md (same risk, same pattern) |
| P2 | FR-A4 (Type Consistency Pre-Check) | Late-stage catch of E1 if architect-reviewer misses it |
| P1 | FR-B1 (task_review.md template) | Foundation for all Track B functionality |
| P1 | FR-B2 (External Review Protocol) | Core spec-executor change for reading reviews |
| P2 | FR-B3 (external_unmarks in stuck detection) | Prevents infinite loops for externally-blocked tasks |
| P2 | FR-B4 (state schema documentation) | Ensures integrators understand the field |

## Verification Contract

**Project type**: `library` (Ralph plugin with no UI — markdown agent prompt files only)

**Entry points**: N/A (no routes, endpoints, or CLI commands affected; all changes are content edits to markdown files)

**Observable signals**:
- PASS looks like: architect-reviewer.md contains `## Document Self-Review Checklist` with 4 steps in a `<mandatory>` block AND `## On Design Update` in `<mandatory>`; templates/design.md contains `## Concurrency & Ordering Risks` between Edge Cases and Test Strategy; product-manager.md contains `## On Requirements Update` in `<mandatory>`; spec-executor.md contains Type Consistency Pre-Check subsection; templates/task_review.md exists with correct schema; spec-executor.md contains `## External Review Protocol` section positioned after "## When Invoked" and before "## Task Loop"; stuck-detection section references `effectiveIterations = taskIteration + external_unmarks[taskId]`
- FAIL looks like: any required section missing from target file; section in wrong position (not between correct anchor sections); `<mandatory>` tag missing where required; table structure missing in Concurrency & Ordering Risks; external_unmarks formula missing or says "replaces" instead of "adds to"

**Hard invariants**:
- No existing content in any modified file is altered outside the target insertion point
- spec-executor.md stuck-detection logic is extended only (effectiveIterations formula added), not replaced
- external_unmarks is never written by spec-executor — only read

**Seed data**: N/A (no data required; all changes are file content insertions)

**Dependency map**: All files are within the same plugin (`plugins/ralph-specum/`) — no cross-package state sharing

**Escalate if**: Any insertion point is ambiguous due to changed file structure; external_unmarks field already exists in .ralph-state.json (name collision)

## Resolved Design Decisions

- **FR-A3 scope**: FR-A3 covers product-manager updating requirements.md; FR-A3b (new) covers architect-reviewer updating design.md. Both use the same reconciliation pattern.
- **FR-B3 effectiveIterations formula**: `external_unmarks` ADDS to `taskIteration` — they measure different dimensions (current-session retries vs. prior-session reviewer cycles) so they stack, never replace.
- **FR-B2 insertion position**: `## External Review Protocol` goes AFTER "## When Invoked" and BEFORE "## Task Loop" (not just after Startup Signal — the ## When Invoked section exists in the real spec-executor and the insertion must go after it).
- **NFR-3 version bumps**: One patch bump total (4.9.1 → 4.9.2), applied to BOTH plugin.json and marketplace.json at the END of all changes, not per-file.

## Learnings

- Postmortem errors E1-E5 were all precision errors in specs, not logic errors — spec quality has higher ROI than implementation quality investment
- E3 (stale text) and E5 (missing ordering docs) revealed that iterative refinement is a structural weak point — linear generation is robust but partial updates leave no reconciliation trail
- The embedded checklist pattern works — Testing Discovery Checklist in architect-reviewer already proved this; self-review checklist extends the same pattern to document hygiene
- Track B external reviewer is designed to be model-agnostic and filesystem-only — no coupling to any specific reviewer implementation
- Version bumps are mandatory per CLAUDE.md for any plugin file change; this spec touches 4 agent files and 1 template (new file), requiring a patch-level version bump on the plugin

## Next Steps

1. Proceed to design phase: architect-reviewer changes (FR-A1, FR-A2, FR-A3b) are first priority per postmortem P1 ordering
2. product-manager.md change (FR-A3) follows, then spec-executor.md changes (FR-A4, FR-B2, FR-B3)
3. task_review.md template creation (FR-B1) is independent and can run parallel to Track A
4. State schema documentation (FR-B4) is last — confirm which file(s) document .ralph-state.json fields
5. Version bump: apply one patch (4.9.1 → 4.9.2) to both plugin.json and marketplace.json at the very end
