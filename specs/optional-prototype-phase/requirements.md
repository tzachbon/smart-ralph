---
spec: optional-prototype-phase
phase: requirements
created: 2026-08-27T18:08:55Z
---

# Requirements: Optional prototype capability

## Goal

Let Ralph run isolated, decision-focused prototypes without changing its main phase. Normal mode gives the user control; quick mode runs one bounded unattended attempt before design.

## Confirmed decisions and research conflicts

These product decisions supersede contrary research recommendations. Research proposed one prototype only after requirements, no quick prototype, one root `prototype.md`, and `prototype` as the top-level phase. The confirmed contract prompts after research and requirements, accepts an explicit request during any phase, runs one quick prototype after requirements, writes multiple `prototypes/<prototype-id>.md` records, and uses overlay state.

## User stories

### US-1: Trigger a prototype without changing Ralph's phase

**Priority:** Must

**As a** Ralph user
**I want to** start or select a prototype at the right planning or execution boundary
**So that** I can answer a question without replacing the main workflow.

**Acceptance criteria:**

- AC-1.1: After each successful research and requirements phase in normal mode, Ralph shows `continue to prototype` beside the explicit existing next-phase or skip choice. Selecting prototype implicitly approves the current artifact; declining creates no prototype and preserves research -> requirements or requirements -> design.
- AC-1.2: A user can explicitly request a prototype during any main phase, including tasks and active execution.
- AC-1.3: A suggested prototype waits for a safe phase or task boundary. An explicit user request interrupts at the next safe tool boundary.
- AC-1.4: Ralph keeps its current top-level phase unchanged. Prototype activity uses an overlay instead of `phase: prototype`.
- AC-1.5: Claude exposes `/ralph-specum:prototype` and Codex exposes `$ralph-specum-prototype` for direct invocation.

### US-2: Isolate and retain prototype source safely

**Priority:** Must

**As a** user with active repository work
**I want to** run prototype work outside my current checkout
**So that** prototype work cannot alter unrelated work.

**Acceptance criteria:**

- AC-2.1: Ralph never switches the current conversation checkout or branch for prototype work. It uses a sibling worktree when available.
- AC-2.2: In normal mode, Ralph displays every proposed dirty or untracked path. A sibling worktree starts from committed `HEAD` and receives only paths the user explicitly approves; Ralph never copies all dirty changes.
- AC-2.3: In normal mode, when a sibling worktree is unavailable, a self-contained logic prototype may use isolated scratch. A UI or app-integrated prototype stops and asks the user to wait or cancel.
- AC-2.4: In normal mode, the coordinator recommends `retained` for app-integrated, multi-file, authenticated, real-data, or expensive-to-reconstruct work, and `ephemeral` for self-contained one-off work. The user chooses.
- AC-2.5: Local retained-branch creation is inside prototype scope. Remote push and issue creation or update always need separate explicit authorization.
- AC-2.6: In normal mode, ephemeral source is deleted only after verdict approval, handoff settlement, and explicit deletion confirmation. Interrupt and cancel preserve source.
- AC-2.7: In normal mode, cancel writes an immutable record with `verdict: cancelled`, preserves source, worktree, partial implementation, task progress, origin phase, and downstream artifacts unchanged, then returns to origin. Deletion needs separate approval.

### US-3: Keep separate prototype records and overlay state

**Priority:** Must

**As a** later workflow consumer
**I want to** find each prototype's isolated record and live overlay entry
**So that** I can identify its source, status, and effect on Ralph work.

**Acceptance criteria:**

- AC-3.1: State contains an `activePrototypes` map. Each entry has a mutable lifecycle `status`, identity, explicit `created` timestamp, returnPhase, source pointers, timestamps, blocking metadata, and enough data to resume or report it.
- AC-3.2: The main state phase vocabulary and transition behavior remain compatible with existing specs; prototype data does not become the top-level phase.
- AC-3.3: Ralph writes one immutable terminal record per prototype attempt at `prototypes/<prototype-id>.md`. Normal-mode IDs are question-based and user-confirmed; quick IDs are agent-chosen.
- AC-3.4: A correction, cancellation resolution, timeout decision, or changed conclusion writes a new immutable record with a new ID and `supersedes`; Ralph never edits a terminal record in place. Consumers ignore superseded records.
- AC-3.5: Each terminal record requires `question`, `status`, `verdict`, explicit `created` timestamp, and runnable or run instructions, and includes `spec`, `phase: prototype`, `id`, `kind`, `captureMode`, `triggerMode`, `triggerPhase`, `returnPhase`, timestamps, affected or blocked artifacts or transitions, evidence or observations, handoff decision, source disposition, and optional `supersedes`. Timestamp format is a design decision.
- AC-3.6: `kind` is `logic` or `ui`; `captureMode` is `retained` or `ephemeral`; and `triggerMode` is `suggested`, `explicit`, or `quick`.
- AC-3.7: `pending` is a live lifecycle status. A terminal record verdict is exactly one of `validated`, `rejected`, `inconclusive`, `cancelled`, `failed`, or `skipped`.
- AC-3.8: Retained records contain local branch, commit, and run pointers plus an issue pointer only when separately authorized, otherwise its authorization status. Ephemeral records retain decision evidence and confirm source deletion or other disposition.

### US-4: Let the user decide verdict and downstream handoff

**Priority:** Must

**As a** normal-mode user
**I want to** decide how a completed prototype affects Ralph work
**So that** the workflow reflects my judgment and preserves partial implementation.

**Acceptance criteria:**

- AC-4.1: The normal-mode user owns the verdict. Each prototype declares the artifact or transition it blocks; only dependent work pauses and unrelated work may continue.
- AC-4.2: Downstream phases consume each gate-approved, non-superseded record that affects them. A normal handoff can explicitly exclude a record.
- AC-4.3: After verdict, Ralph interviews the user with dependency-aware choices to resume origin unchanged, revise the earliest affected artifact and cascade, or abandon or replace interrupted work. Ralph remains in prototype handoff until the user chooses.
- AC-4.4: When the user selects revision during partial execution, Ralph preserves partial implementation unchanged, marks the interrupted task and affected downstream artifacts stale, and returns to the selected phase.
- AC-4.5: Ralph never auto-commits, discards, or rolls back partial implementation during prototype handoff.

### US-5: Manage concurrent, duplicate, and delayed decisions

**Priority:** Must

**As a** user running several questions
**I want to** keep prototypes isolated and recover each decision
**So that** concurrent work does not share mutable source or wait forever.

**Acceptance criteria:**

- AC-5.1: Ralph allows multiple active prototypes with no fixed numeric limit only when each has proven isolation. Each uses a separate worktree, branch, or scratch area and shares no mutable paths.
- AC-5.2: In normal mode, Ralph refuses a new prototype when isolation capacity is not available.
- AC-5.3: In normal mode, an explicit prototype ID resumes that record. One active prototype resumes automatically; several active prototypes without an ID are listed for user selection.
- AC-5.4: In normal mode, a duplicate question offers resume, supersede, or a distinct record.
- AC-5.5: Before conflict-timeout expiry, the normal-mode user decides supersession. On expiry Ralph selects the evidence-backed winner, writes an immutable reversible resolution or supersession record, and permits later user supersession.
- AC-5.6: Builder completion and conflict-decision waits have separate configurable bounds, activity resets, retry behavior, and recorded outcomes. Neither can wait silently without an end condition.

### US-6: Run one unattended quick prototype

**Priority:** Must

**As a** quick-mode user
**I want to** receive one bounded prototype attempt before design
**So that** Ralph can test a grounded uncertainty without pausing for a decision.

**Acceptance criteria:**

- AC-6.1: Quick mode runs exactly one unattended prototype after requirements and before design. It asks no prototype question and stops for no prototype decision.
- AC-6.2: Ralph selects the highest-risk grounded falsifiable question. If none exists, it records `skipped: no suitable question` and continues.
- AC-6.3: Ralph owns the quick verdict. `inconclusive` is a completed attempt and supplies no design input.
- AC-6.4: Quick mode overrides normal-mode choice, deletion, stop, and isolation-capacity rules: Ralph selects retained or ephemeral by the scope rule, uses committed `HEAD` only, never copies dirty changes, never switches the current checkout, and never pushes or creates or updates issues.
- AC-6.5: Without isolation capacity or on isolation failure, quick mode makes one bounded mechanical retry, then writes a terminal `failed` record, preserves existing active prototypes and blockers, accepts no user input, and continues to design. A quick ephemeral source is deleted after run evidence and result are recorded; a source that may matter after failure or `inconclusive` is retained before run.
- AC-6.6: If an active prototype blocks design, Ralph resumes the oldest and counts it as its one quick attempt. Ralph owns and completes its verdict under quick rules, records automatic ownership, resolution, and source disposition, skips normal handoff, and never asks. Other active prototypes remain preserved, excluded from design input, and unable to stop quick continuation to design.
- AC-6.7: Ralph creates a new quick prototype only when none blocks design. It resolves duplicate and conflicting questions through recorded evidence-based reuse or supersession without user input, handles timers itself, and does not delegate decisions or questions to the user.
- AC-6.8: Quick `validated` and `rejected` records are automatically gate-approved and supply positive or negative evidence to design. `skipped`, `failed`, and `inconclusive` records supply no design input. Quick mode proceeds to design in every case.

### US-7: Make logic and UI evidence runnable and reviewable

**Priority:** Must

**As a** prototype reviewer
**I want to** run and inspect the selected prototype shape
**So that** the record has evidence behind its outcome.

**Acceptance criteria:**

- AC-7.1: A logic prototype is one self-contained HTML file with a visible question and a pure reducer, state machine, or functions module that has no DOM dependency.
- AC-7.2: Logic UX shows labeled state after each action, free play, and tabbed guided normal, edge, and illegal-action cases that reset to a known initial state.
- AC-7.3: A UI prototype prefers an existing route, preserves its data, parameters, and authentication, and swaps only the relevant rendered subtree.
- AC-7.4: A UI prototype has exactly three visually distinct variants that differ in layout, information hierarchy, and primary action. `?variant=` deep-links each variant.
- AC-7.5: A shared switcher component appears in a fixed bottom bar, shows the current variant label, updates the URL across reloads, supports arrow keys with an input-focus guard, and introduces no production changes.
- AC-7.6: The existing spec reviewer and review loop accept prototype records, remain read-only, produce actionable findings, apply a rubric for record fields, runnable evidence, isolation, outcome, source disposition, blockers, and handoff, and return deterministic `REVIEW_PASS` or `REVIEW_FAIL` signals.

### US-8: Ship matching, tested behavior on both harnesses

**Priority:** Must

**As a** plugin user
**I want to** receive the same capability in Claude and Codex
**So that** harness choice does not change the contract.

**Acceptance criteria:**

- AC-8.1: Claude and Codex ship matching prototype entrypoints, coordination guidance, record and state contracts, review support, user help, and documentation at the same new minor version.
- AC-8.2: Tests cover normal prompts and skips, explicit invocation in every main phase, overlay-state compatibility, immutable terminal records, isolation, displayed dirty-path approval, cancellation, handoff, partial execution, normal resume, concurrency, duplicates, conflicts, and timeouts.
- AC-8.3: Tests cover quick question selection, skip, retained and ephemeral capture, committed-HEAD isolation, retry, cleanup, blocker ownership and ordering, automatic quick handoff, evidence-based conflict handling, and continuation to design.
- AC-8.4: Tests cover logic and UI runnable contracts, reviewer acceptance, version parity, and full existing planning and package regression checks.

## Functional requirements

| ID | Requirement | Priority | Acceptance criteria |
|---|---|---|---|
| FR-1 | Offer and invoke prototypes without changing the main phase. | Must | AC-1.1, AC-1.2, AC-1.3, AC-1.4, AC-1.5 |
| FR-2 | Isolate source, choose capture mode, and preserve source through cancel. | Must | AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.5, AC-2.6, AC-2.7 |
| FR-3 | Store immutable records and resumable prototype overlay entries. | Must | AC-3.1, AC-3.2, AC-3.3, AC-3.4, AC-3.5, AC-3.6, AC-3.7, AC-3.8 |
| FR-4 | Apply user-owned verdict and handoff choices in normal mode. | Must | AC-4.1, AC-4.2, AC-4.3, AC-4.4, AC-4.5 |
| FR-5 | Isolate concurrent work and bound duplicate, conflict, and wait behavior. | Must | AC-5.1, AC-5.2, AC-5.3, AC-5.4, AC-5.5, AC-5.6 |
| FR-6 | Run one bounded unattended prototype in quick mode. | Must | AC-6.1, AC-6.2, AC-6.3, AC-6.4, AC-6.5, AC-6.6, AC-6.7, AC-6.8 |
| FR-7 | Produce runnable logic or UI evidence and review it. | Must | AC-7.1, AC-7.2, AC-7.3, AC-7.4, AC-7.5, AC-7.6 |
| FR-8 | Maintain Claude/Codex parity and regression coverage. | Must | AC-8.1, AC-8.2, AC-8.3, AC-8.4 |

## Non-functional requirements

| ID | Requirement | Priority | Measure and target |
|---|---|---|---|
| NFR-1 | Preserve current-checkout safety. | Must | Prototype work never switches the conversation checkout or copies unapproved dirty paths. |
| NFR-2 | Preserve isolation. | Must | Concurrent records share no mutable paths; normal mode refuses a new prototype when capacity is absent, while quick mode records failure after one bounded retry and continues. |
| NFR-3 | Preserve recoverability. | Must | Each active or completed record has pointers, timestamps, outcome, source disposition, and return data. |
| NFR-4 | Bound unattended behavior. | Must | Builder and decision waits have configurable limits, retries, activity resets, and recorded end states. |
| NFR-5 | Preserve package compatibility. | Must | Existing main-phase behavior and full Claude/Codex regression suites pass with matching versions. |

## Glossary

- **Capture mode**: `retained` keeps prototype source; `ephemeral` removes source after the required gate.
- **Gate-approved**: Record outcome approved for downstream use.
- **Isolation capacity**: A separate worktree, branch, or scratch area with no shared mutable paths.
- **Overlay state**: `activePrototypes` data that supplements, rather than replaces, Ralph's main phase state.

## Dependencies

- Claude and Codex command or skill surfaces, state handling, review loop, cancellation, workflow guidance, schemas, package metadata, and regression suites.
- The supplied prototype logic and UI guidance for runnable artifact behavior.
- Git worktree support and an isolated scratch mechanism for eligible logic prototypes.

## Out of scope

- A new top-level Ralph phase or a fixed cap on active prototypes.
- Automatic copying of all dirty changes, current-checkout switching, remote pushes, or issue changes without separate authorization.
- Exact timeout formula, timer activity-reset method, retry algorithm, JSON layout, patch-copy mechanism, branch names, or optional prototype index.
- Production promotion of prototype source without normal implementation work.

## Risks and controls

| Risk | Impact | Control |
|---|---|---|
| Prototype source alters active work. | High | Use side isolation and exact approved dirty-path copying only. |
| Several prototypes conflict or share files. | High | Require isolation capacity, individual records, and supersession rules. |
| Quick mode blocks on an unanswered decision. | High | Let Ralph own quick decisions and continue after bounded failure. |
| A timer hides unresolved work. | Medium | Record outcomes and require finite, configurable wait behavior. |
| Package behavior diverges. | High | Ship matching surfaces, versions, and regression coverage. |

## Success criteria

- Normal mode offers a prototype after research and requirements, accepts explicit requests in any phase, and returns the user through an isolated handoff.
- Quick mode records exactly one bounded attempt after requirements and reaches design without user prototype decisions.
- Every record exposes its identity, question, source disposition, outcome, blockers, evidence, and downstream decision.
- Tests prove isolation, overlay compatibility, concurrency, recovery, quick behavior, review, timeout bounds, and version parity.

## Unresolved questions

None that prevents requirements verification. The deferred mechanics named in Out of scope belong in design.

## Next steps

1. Review the requirements artifact and approve the contract for design.
2. Define the state, record, isolation, and timeout mechanics in the design artifact.
