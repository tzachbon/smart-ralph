---
spec: requirements-process-improvements
phase: research
created: 2026-07-17
---

# Research: requirements-process-improvements

## Executive Summary

The ralph-specum requirements phase produces free-text FRs/ACs with no structured syntax, no problem framing, shallow success metrics, and a broken priority-scale contract (High/Med/Low vs Must/Should/Could between template and reviewer). The PM craft repo yields 15 generic patterns; 7 are cherry-picked as prompt/template-level changes (S/M effort) that directly attack the two dominant failure modes: untestable prose and confident fabrication. **Key recommendation**: adopt the 7-pattern shortlist below via edits to product-manager.md, templates/requirements.md, and spec-reviewer.md in lockstep, fixing the priority-scale mismatch in the same pass.

## Codebase Analysis

### Existing Patterns (current phase inventory)

| File | Role |
|---|---|
| `plugins/ralph-specum/commands/requirements.md` | Coordinator: gather context → interview (skipped in `--quick`) → dispatch product-manager → reviewer loop (`--quick` only) → approval → finalize state |
| `plugins/ralph-specum/agents/product-manager.md` | Generator agent; inline structure duplicating template; quality checklist; sets `awaitingApproval` |
| `plugins/ralph-specum/templates/requirements.md` | Artifact template: Goal, US-N stories + AC-N.N, FR table, NFR table, Glossary, Out of Scope, Dependencies, Success Criteria, Risks |
| `plugins/ralph-specum/agents/spec-reviewer.md` | Requirements rubric: Completeness / Testability / Traceability / Scope |
| `plugins/ralph-specum/skills/interview-framework/` | Pre-phase interview algorithm; thin PM territory hints |
| `plugins/ralph-specum/agents/refactor-specialist.md` | Section-by-section post-execution walkthrough (name-coupled) |
| `plugins/ralph-specum/schemas/spec.schema.json` | Frontmatter contract; `requirements_refs` ID storage |

### Downstream Contracts (hard)

- ID namespaces `US-N`, `FR-N`, `AC-N.N`, `NFR-N` consumed by task-planner (`_Requirements: FR-1, AC-1.1_` footers), tasks template, spec-reviewer rubrics, schema `requirements_refs`. Keep formats or update all consumers atomically.
- refactor-specialist iterates named sections; adding sections is safe, renaming/removing is not.
- design phase maps components ↔ FRs; orphan FRs FAIL design review.
- product-manager must end with `awaitingApproval: true`; don't disturb state protocol.

### Constraints

- Version bump required: `plugins/ralph-specum/.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json`.
- Quick mode: no interview/approval; new sections need autonomous defaults ("state assumptions", TBD markers). New mandatory sections become hard gates in the quick-mode review loop — must have clear PASS criteria.
- Dual source of truth: structure lives in both agent prompt and template; edits must hit both (or consolidate).
- Artifact must stay table-heavy/concise per communication-style skill; walkthrough counts US/FR/NFR.

### Current Weaknesses (condensed)

| # | Gap |
|---|---|
| W1 | No structured requirement syntax (no EARS/GWT); ACs drift to grep-level checks |
| W2 | No problem framing; starts at solution ("Goal"); no link back to research |
| W3 | Priority-scale contradiction: template High/Med/Low vs reviewer Must/Should/Could |
| W4 | Template/agent drift (Risks section; duplicated structure) |
| W5 | Shallow success metrics: no baseline/target/method; unreviewed |
| W6 | NFR table is boilerplate ritual; never validated |
| W7 | No prioritization method or cut-line |
| W8 | No red-team/negative pass; no automated review by default in non-quick mode |
| W9 | Weak AC quality bar; no error-path coverage requirement |
| W10 | Traceability one-directional, unchecked at authoring time; two competing AC homes |
| W11 | Interview thin on PM fundamentals; quick mode has no assumption-stating requirement |
| W12 | No POC-critical vs deferred signal for downstream |

## External Research

Source: internal AI-native PM craft repo (sdd-prd-toolkit, craft-prd, prd-generator, pm-product-discovery, redteam, sdd-drift-check). 15 ranked patterns extracted; mapped against weaknesses:

| # | Pattern | Fixes | Files touched | Difficulty |
|---|---|---|---|---|
| P1 | Stable requirement IDs + canonical "System MUST" table; append-only, never renumber, retire in place | W10, W4 | product-manager.md, templates/requirements.md, spec-reviewer.md | S |
| P2 | Six-scenario AC coverage checklist per story (happy, empty, error, cancellation, permission, boundary) | W1, W9 | product-manager.md, spec-reviewer.md | S |
| P3 | Mechanical validation gate (8-check PASS/WARN/FAIL lint: ID cross-ref, GWT clauses, language lint, SHOULD ratio, unowned questions) | W8, W10, W3 | spec-reviewer.md, commands/requirements.md | M |
| P4 | Requirement-language rules: MUST/SHOULD semantics + prose→testable before/after few-shots | W1, W9 | product-manager.md, templates/requirements.md | S |
| P5 | "Can't write the AC → open question with owner + date, blocks next phase"; decisions logged | W8, W11 | product-manager.md, templates/requirements.md | S |
| P6 | Confidence labels + assumptions register ("if wrong, impact"); no HYPOTHESIZED load-bearing assumption | W11, W2 | product-manager.md, templates/requirements.md | S–M |
| P7 | Explicit Non-Goals with default-scope rule ("not listed = in scope") | W7 | templates/requirements.md (rename Out of Scope semantics), product-manager.md | S |
| P8 | Red-team adversarial review pass (claim inventory, orphan reqs, coverage gaps) | W8 | spec-reviewer.md or new pass | M–L |
| P9 | Never invent specifics; `TBD (owner / expected date)` discipline | W5, W11 | product-manager.md | S |
| P10 | Categorized NFR checklist: every row filled or explicit N/A/TBD, derived from feature | W6 | templates/requirements.md, product-manager.md, spec-reviewer.md | S |
| P11 | Journey rules (steady-state, structurally-blocked users) | W9 | product-manager.md | M |
| P12 | Guardrails section for agentic features | — (new class) | template | S |
| P13 | Requirements↔design drift check with coverage ratios | W10 (cross-phase) | new capability | M–L |
| P14 | Problem-statement quality gate + root-cause anchoring | W2 | product-manager.md, template | M |
| P15 | Section-by-section human review + de-dup pass | — | commands | L |

### Pitfalls to Avoid (from source anti-patterns)

- Goal language in FRs ("Enable seamless X"); prose ACs ("handle gracefully").
- Inventing specifics to fill template gaps instead of TBD-with-owner.
- Reusing/renumbering requirement IDs.
- Shipping a skeleton (TBD sections presented as complete).
- Review anti-patterns: grading on a curve, silently editing, style-nit findings.
- UI description instead of behavior in ACs.

## Related Specs

| Spec | Relevance | Relationship | May Need Update |
|------|-----------|--------------|-----------------|
| (none active) | — | No other specs in this worktree touch the requirements phase | No |

### Coordination Notes
Changes cascade to design/tasks phase consumers (task-planner, spec-reviewer design rubric) via ID contracts; keep formats stable.

## Recommendation: Cherry-Picked Shortlist (7 patterns)

| Pick | Pattern | Rationale |
|---|---|---|
| 1 | **P4 Requirement-language rules** (MUST/SHOULD + few-shot rewrites) | Biggest failure mode is untestable prose; pure prompt change |
| 2 | **P2 Six-scenario AC checklist** | Cheap, forces error/edge coverage the pipeline currently guesses at |
| 3 | **P1 Canonical FR table discipline** (append-only IDs, one AC home) | Fixes two-competing-AC-homes; strengthens existing ID contract without changing formats |
| 4 | **P9 TBD-with-owner anti-confabulation** | Directly counters LLM fabrication; essential for quick mode |
| 5 | **P3 Mechanical validation gate** | Upgrades spec-reviewer rubric from vibes to checkable rules; fixes W3 priority mismatch in same pass; enables review-by-default |
| 6 | **P7 Non-Goals with default-scope rule** | One-line rule, large ambiguity reduction downstream |
| 7 | **P14-lite Problem statement** (single templated paragraph before Goal, evidence-linked to research.md) | Fixes W2 without heavy discovery process; additive section (safe for refactor-specialist) |

Supporting fixes bundled in: resolve W3 (standardize on MoSCoW or High/Med/Low everywhere), consolidate W4 dual-source drift (agent references template), P10-lite NFR "fill or mark N/A" rule (one sentence).

### Considered and Deferred/Rejected

| Pattern | Verdict | Why |
|---|---|---|
| P15 Section-by-section human review + de-dup | Rejected | Too interaction-heavy for autonomous/quick pipeline |
| P8 Full red-team pass | Deferred | Valuable but M–L; P3 validation gate covers the mechanical half; revisit as separate spec |
| P13 Drift check | Deferred | Cross-phase capability; belongs to a design-phase spec |
| P6 Full confidence/assumptions register | Partially adopted | Labels are cheap but full register bloats a lean phase; fold "Assumptions" bullet list with TBD discipline (P9) instead |
| P11 Journey rules | Deferred | P2 scenario checklist captures most value at lower prompt cost |
| P12 Guardrails section | Deferred | Feature-class-specific; add later as conditional section |
| P14 full discovery gate (Five Whys etc.) | Rejected | Upstream discovery process, too heavy; lite version adopted |
| RIC/ICE scoring, phase-gated process | Rejected | Org-process machinery, not artifact quality |

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | High | All picks are markdown prompt/template edits; no code, no schema breaks |
| Effort Estimate | M | ~4 files (product-manager, template, spec-reviewer, requirements command) + version bump; lockstep rubric updates are the bulk |
| Risk Level | Low–Medium | Main risks: rubric changes making quick-mode loop over-strict (mitigate: WARN vs FAIL split); prompt bloat vs "keep phase lean" (mitigate: cut existing checklist text as new rules land); section-name coupling with refactor-specialist (additive sections only, update its list) |

## Recommendations for Requirements

1. Scope the spec to the 7-pick shortlist + bundled fixes (W3 scale unification, W4 consolidation).
2. Define lockstep edit sets: any template change pairs with product-manager + spec-reviewer + refactor-specialist section list.
3. Specify quick-mode defaults for every new rule (TBD markers, stated assumptions) so autonomous runs don't stall.
4. Keep existing ID token formats (`US-N`, `FR-N`, `AC-N.N`, `NFR-N`) unchanged; add append-only discipline on top.
5. Split PASS-blocking checks (FAIL) from advisory checks (WARN) in the new rubric to protect the 3-iteration quick loop.

## Open Questions

- Priority scale: standardize on MoSCoW (reviewer's current expectation) or High/Med/Low (template's)? Recommend MoSCoW.
- Should the validation gate run by default in non-quick mode (currently review is opt-in)? Recommend yes, one pass.
- Consolidate structure into template-only (agent references it) or keep dual with a sync note? Recommend template-only.

## Sources

- `specs/requirements-process-improvements/.research-inputs/pm-craft-findings.md` — ranked patterns, anti-patterns, snippets
- `specs/requirements-process-improvements/.research-inputs/current-phase-map.md` — phase inventory, weaknesses, constraints
- `plugins/ralph-specum/agents/product-manager.md`, `templates/requirements.md`, `agents/spec-reviewer.md`, `commands/requirements.md`
