---
spec: requirements-process-improvements
phase: requirements
created: 2026-07-17
---

# Requirements: requirements-process-improvements

## Problem Statement

The ralph-specum requirements phase produces free-text FRs/ACs with no structured syntax, no problem framing, and a broken priority-scale contract (template says High/Medium/Low, reviewer rubric says Must/Should/Could). Evidence: research.md weaknesses W1-W12. Two dominant failure modes: untestable prose ACs and confident fabrication of specifics. In non-quick mode no automated review runs at all by default.

## Goal

Upgrade the requirements phase (product-manager agent, /ralph-specum:requirements command, templates/requirements.md, spec-reviewer rubric) with 7 cherry-picked PM patterns so generated requirements are structurally testable, fabrication-resistant, and mechanically validated in both normal and quick mode.

## User Stories

### US-1: Structured requirement language

**As a** spec author (product-manager agent)
**I want to** write FRs with MUST/SHOULD semantics and ACs in mandatory Given/When/Then form
**So that** every requirement is testable and downstream phases don't guess at intent

**Acceptance Criteria:**
- AC-1.1: Given the updated product-manager prompt and template, When a requirements.md is generated, Then every FR statement uses "System MUST" or "System SHOULD" phrasing and every AC contains all three Given/When/Then clauses.
- AC-1.2: Given the updated prompt, When the agent is instructed on requirement language, Then it includes at least 2 before/after few-shot examples rewriting vague prose ("handle gracefully") into testable form.
- AC-1.3: Given an AC missing a Given, When, or Then clause, When the validation gate runs, Then the check reports FAIL for that AC (lintable).

### US-2: Six-scenario AC coverage

**As a** spec author
**I want** each user story checked against a six-scenario coverage checklist (happy, empty, error, cancellation, permission, boundary)
**So that** error/edge paths are covered or explicitly marked N/A instead of silently omitted

**Acceptance Criteria:**
- AC-2.1: Given the updated product-manager prompt, When generating stories, Then each story's ACs are derived from the six-scenario checklist, with non-applicable scenarios marked N/A with a one-line reason.
- AC-2.2: Given the updated spec-reviewer rubric, When reviewing a story with only happy-path ACs and no N/A markings, Then the review reports a finding (WARN at minimum).

### US-3: Canonical FR table discipline

**As a** downstream consumer (task-planner, architect-reviewer)
**I want** the FR table to be the single home for FR-level verification with append-only stable IDs
**So that** the two-competing-AC-homes ambiguity is removed and ID references never break

**Acceptance Criteria:**
- AC-3.1: Given the updated template, When a requirements.md is generated, Then ACs live only under user stories (AC-N.N) and the FR table references AC IDs instead of duplicating free-text verification prose.
- AC-3.2: Given the updated prompt/template rules, When requirements are edited later, Then rules state IDs are append-only: never renumbered or reused; retired requirements are marked retired in place.
- AC-3.3: Given the change, When downstream consumers parse IDs, Then US-N, FR-N, AC-N.N, NFR-N token formats are unchanged.

### US-4: TBD-with-owner anti-confabulation

**As a** spec consumer
**I want** unknown specifics marked `TBD (owner, expected date)` instead of invented
**So that** fabricated numbers/facts don't flow into design and tasks

**Acceptance Criteria:**
- AC-4.1: Given the updated product-manager prompt, When the agent lacks information for a required field, Then it writes a TBD marker with owner and expected resolution, never an invented specific.
- AC-4.2: Given quick mode (no interview), When a decision would normally need user input, Then the agent states the assumption explicitly (Assumptions list or TBD) so the artifact is generatable autonomously.
- AC-4.3: Given the validation gate, When an Unresolved Question or TBD lacks an owner, Then the gate reports it (WARN).

### US-5: Mechanical validation gate

**As a** user of the requirements command
**I want** an 8-check PASS/WARN/FAIL validation gate to auto-run after generation in both normal and quick mode
**So that** structural defects are caught mechanically instead of by vibes

**Acceptance Criteria:**
- AC-5.1: Given the updated spec-reviewer requirements rubric, When it runs, Then it applies 8 mechanical checks including at minimum: ID cross-reference integrity, Given/When/Then clause presence, requirement-language lint (MUST/SHOULD, banned vague words), MUST:SHOULD ratio advisory, unowned open questions, MoSCoW priority values, six-scenario coverage, NFR fill-or-N/A.
- AC-5.2: Given normal (non-quick) mode, When the product-manager finishes generation, Then the command auto-runs spec-reviewer once, shows findings in the walkthrough, and still requires user approval.
- AC-5.3: Given quick mode, When the review loop runs, Then only FAIL-class checks block (max 3 iterations preserved); WARN-class checks are advisory and never block.
- AC-5.4: Given the rubric update, When priorities are checked, Then the expected scale is MoSCoW (Must/Should/Could) matching template and agent.

### US-6: Explicit Non-Goals with default-scope rule

**As a** downstream planner
**I want** the scope section governed by the rule "not listed as a non-goal = in scope"
**So that** scope ambiguity doesn't leak into design and tasks

**Acceptance Criteria:**
- AC-6.1: Given the updated template, When the scope section is generated, Then it carries the explicit default-scope rule and lists concrete non-goals.
- AC-6.2: Given refactor-specialist's named-section coupling, When the section is added or its semantics changed, Then refactor-specialist's section list is updated in the same change (no removed/renamed section left dangling).

### US-7: Lite problem statement

**As a** reader of requirements.md
**I want** a single templated Problem Statement paragraph before Goal, evidence-linked to research.md
**So that** requirements state the problem, not just the solution

**Acceptance Criteria:**
- AC-7.1: Given the updated template, When requirements.md is generated, Then a Problem Statement section precedes Goal containing problem, affected user, and an evidence pointer to research.md findings.
- AC-7.2: Given quick mode, When no interview evidence exists, Then the problem statement is derived from research.md or marked with stated assumptions (never fabricated user pain).

### US-8: Consolidated source of truth and consistent scales

**As a** plugin maintainer
**I want** the artifact structure defined once (template) with agent/rubric referencing it, MoSCoW everywhere, and NFR fill-or-N/A
**So that** the template/agent/rubric never drift again

**Acceptance Criteria:**
- AC-8.1: Given the change, When product-manager.md is read, Then it references templates/requirements.md for structure instead of duplicating the full inline section skeleton.
- AC-8.2: Given the change, When priority values appear in template, agent prompt, or rubric, Then all use Must/Should/Could; no High/Medium/Low remains for FR priority.
- AC-8.3: Given the updated template, When the NFR table is generated, Then every category row is either filled with metric+target or explicitly marked N/A with reason; pre-seeded boilerplate rows without values fail the gate.
- AC-8.4: Given any plugin file change, When the change set lands, Then version is bumped in plugins/ralph-specum/.claude-plugin/plugin.json and .claude-plugin/marketplace.json.

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | System MUST enforce "System MUST/SHOULD" language for FRs and mandatory 3-clause Given/When/Then ACs in prompt + template, with ≥2 prose-to-testable few-shot examples | Must | AC-1.1, AC-1.2, AC-1.3 |
| FR-2 | System MUST apply the six-scenario AC coverage checklist per story (happy, empty, error, cancellation, permission, boundary; N/A with reason allowed) | Must | AC-2.1, AC-2.2 |
| FR-3 | System MUST make the FR table the canonical FR-verification home referencing AC-N.N IDs (no duplicated free-text AC column), with append-only ID discipline | Must | AC-3.1, AC-3.2 |
| FR-4 | System MUST keep US-N, FR-N, AC-N.N, NFR-N token formats unchanged | Must | AC-3.3 |
| FR-5 | System MUST require TBD (owner, expected date) markers instead of invented specifics, with quick-mode assumption-stating defaults | Must | AC-4.1, AC-4.2, AC-4.3 |
| FR-6 | System MUST upgrade the spec-reviewer requirements rubric to an 8-check mechanical gate with PASS/WARN/FAIL split | Must | AC-5.1, AC-5.3, AC-5.4 |
| FR-7 | System MUST auto-run the validation gate after generation in normal mode (one pass, findings in walkthrough, approval preserved) and keep the quick-mode loop (max 3, FAIL-only blocking) | Must | AC-5.2, AC-5.3 |
| FR-8 | System MUST add explicit Non-Goals semantics with the default-scope rule to the scope section | Must | AC-6.1, AC-6.2 |
| FR-9 | System MUST add a lite Problem Statement section before Goal, evidence-linked to research.md | Must | AC-7.1, AC-7.2 |
| FR-10 | System MUST unify FR priority scale to MoSCoW across template, agent, and rubric | Must | AC-8.2 |
| FR-11 | System SHOULD consolidate structure to template-only with the agent referencing it | Should | AC-8.1 |
| FR-12 | System MUST enforce NFR fill-or-mark-N/A rule | Must | AC-8.3 |
| FR-13 | System MUST bump plugin version in plugin.json and marketplace.json | Must | AC-8.4 |
| FR-14 | System SHOULD keep net prompt/template size lean by cutting superseded checklist text as new rules land | Should | AC-8.1, NFR-2 |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Compatibility: downstream consumers (task-planner, design phase, refactor-specialist, schema) keep working unmodified except deliberate lockstep edits | Consumers parsing IDs/sections | Zero broken references; refactor-specialist section list updated in same change |
| NFR-2 | Leanness: phase stays concise per communication-style skill | Net line delta across product-manager.md + template | New rules offset by cuts; artifact stays table-heavy (advisory, checked in review) |
| NFR-3 | Quick-mode robustness: autonomous runs don't stall on new gates | Quick-mode review loop | Completes within existing 3-iteration cap; WARN never blocks |
| NFR-4 | Performance | N/A | N/A: markdown prompt/template edits only, no runtime code |
| NFR-5 | Security | N/A | N/A: no code, no data handling changes |

## Glossary

- **MoSCoW**: Priority scale Must/Should/Could (Won't = non-goal).
- **GWT**: Given/When/Then acceptance-criterion structure; all three clauses required.
- **Validation gate**: Mechanical 8-check lint in spec-reviewer's requirements rubric with PASS/WARN/FAIL per check.
- **Quick mode**: `--quick` flag; no interview, no user approval, reviewer loop max 3 iterations.
- **TBD-with-owner**: Marker `TBD (owner, expected date)` replacing any specific the author cannot ground.
- **Six-scenario checklist**: Happy path, empty/none, error, cancellation, permission, boundary.
- **Append-only IDs**: Requirement IDs are never renumbered or reused; retired items stay with a retired mark.

## Out of Scope (Non-Goals)

Default-scope rule: anything not listed here that falls under the Goal is in scope.

- Full red-team adversarial review pass (P8) — deferred to a separate spec.
- Requirements↔design drift check (P13) — cross-phase, belongs to a design-phase spec.
- Full confidence/assumptions register (P6) — only TBD/assumptions discipline adopted.
- Journey rules (P11), Guardrails section (P12), full discovery gate (P14), RICE/ICE scoring, section-by-section human review (P15).
- Changing ID token formats or renaming/removing existing requirements.md sections.
- Changes to other phases (research, design, tasks) beyond lockstep rubric/section-list updates.
- New runtime code, hooks, or schema body validation.

## Dependencies

- `plugins/ralph-specum/agents/product-manager.md`, `templates/requirements.md`, `agents/spec-reviewer.md`, `commands/requirements.md` edited in lockstep.
- `agents/refactor-specialist.md` section list updated for added Problem Statement / Non-Goals semantics.
- Version bump: `plugins/ralph-specum/.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json`.
- No external dependencies; no schema ID-format changes.

## Success Criteria

- A requirements.md generated with the updated phase passes all 8 validation checks (0 FAIL) on first or second pass.
- Priority-scale mismatch eliminated: zero High/Medium/Low FR priorities across template/agent/rubric.
- Quick-mode run completes end-to-end without user input and without exceeding the 3-iteration review cap.
- Validation findings appear in the normal-mode walkthrough before approval.
- Downstream phases (design, tasks) run against a new-format requirements.md with zero ID-reference breakage.

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Stricter rubric over-blocks quick-mode loop | Medium | FAIL/WARN split; only structural checks block; 3-iteration cap with graceful degradation preserved |
| Prompt bloat vs "keep phase lean" | Medium | FR-14: cut superseded checklist text; NFR-2 line-delta check |
| Section additions break refactor-specialist walkthrough | Low | Additive-only sections; update its section list in same change (AC-6.2) |
| Template-only consolidation breaks agent output when template unreadable | Low | Agent keeps a minimal fallback ordering note; consolidation is Should (FR-11) |

## Unresolved Questions

- Exact composition of the 8 checks: AC-5.1 lists candidate checks; final selection and per-check FAIL vs WARN classification to be fixed in design. Owner: architect-reviewer (design phase).
- Whether the scope section keeps the heading "Out of Scope" (safe for refactor-specialist) or is retitled "Non-Goals" (requires consumer update). Recommendation: keep heading, add default-scope rule + non-goal semantics inside. Owner: architect-reviewer (design phase).
- Whether normal-mode auto-review re-runs after "Request changes" edits or only once post-generation. Recommendation: re-run after each regeneration. Owner: user, at design approval.
