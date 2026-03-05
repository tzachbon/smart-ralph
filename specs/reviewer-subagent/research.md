---
spec: reviewer-subagent
phase: research
created: 2026-02-17
generated: auto
---

# Research: reviewer-subagent

## Executive Summary

Introducing a reviewer sub-agent that validates spec artifacts and execution output before user-facing presentation. External verification (separate agent with own context) significantly outperforms intrinsic self-correction. The existing Ralph plugin architecture supports this via Task tool delegation, inserting review loops between phase agent completion and `awaitingApproval` state transitions.

## External Research

### Best Practices

- **Evaluator-Reflect-Refine Loop** (AWS pattern): Generator produces output, evaluator rates against rubric, refine and resubmit if below threshold. Loop until convergence or retry limit.
- **Role-Based Reviewer** (CrewAI): Explicit "reviewer" role with SOPs. Two-layer architecture separates generation from evaluation.
- **Constitutional AI**: Set of principles used as a review rubric. The constitution defines what "good" looks like per artifact type.
- **Reflexion/Self-Reflection**: Generate-Critique-Refine cycle. GPT-4 baseline 78.6% -> 97.1% with self-reflection loops.

### Iteration Best Practices

| Aspect | Recommendation |
|--------|---------------|
| Typical iterations | 2-3 before convergence |
| Hard cap | 3 review iterations per artifact |
| Convergence signal | Reviewer approves OR delta between iterations < epsilon |
| Termination | System (coordinator), not agent, guarantees termination |
| Degradation | After max iterations, present best result with quality warnings |

### Infinite Loop Prevention

1. Maximum iteration limits (hard cap = 3)
2. Repetitive output detection (reviewer flags identical feedback)
3. Graceful degradation (present best result with warnings)
4. Coordinator owns loop control, not the reviewer

### Review Rubric Dimensions

| Dimension | What to Check |
|-----------|--------------|
| Completeness | All required sections present |
| Consistency | Cross-references valid, no contradictions |
| Grounding | Claims backed by evidence (file paths, URLs) |
| Testability | ACs are specific and automatable |
| Traceability | Tasks trace to requirements, design refs components |
| Feasibility | Design implementable given constraints |
| Format Compliance | Follows template structure |
| Scope Adherence | Doesn't exceed stated scope |
| Actionability | Tasks have concrete Do/Files/Verify/Commit |

## Codebase Analysis

### Existing Patterns

| Pattern | Location | Relevance |
|---------|----------|-----------|
| Agent definition (markdown + frontmatter) | `plugins/ralph-specum/agents/spec-executor.md` | Template for spec-reviewer.md |
| Signal protocol (PASS/FAIL) | `agents/qa-engineer.md` | Reuse REVIEW_PASS/REVIEW_FAIL signals |
| Coordinator delegation pattern | `commands/research.md`, `commands/requirements.md` | Insert review step before `awaitingApproval` |
| Task tool subagent invocation | `commands/implement.md` Section 6 | Same pattern for reviewer delegation |
| Quick mode synthesis | `agents/plan-synthesizer.md` | Add review step in quick mode flow |
| `awaitingApproval` state flag | All phase commands | Natural insertion point: review BEFORE setting flag |

### Existing Review Infrastructure (Gaps)

1. **qa-engineer agent** - Handles `[VERIFY]` tasks during execution. Gap: only execution phase, only command-based checks.
2. **4-Layer Verification** in coordinator - Verifies task completion integrity. Gap: not artifact quality review.
3. **awaitingApproval pattern** - Human reviews between phases. Gap: no automated pre-review before human sees output.
4. **Walkthrough pattern** - Displays summary after research. Gap: no structured quality check.

### Architecture Constraints

- Task tool spawns subagents with fresh context. Reviewer gets clean context but needs artifact content passed in prompt.
- Subagents cannot spawn other subagents. Reviewer must be invoked by coordinator (command), not by phase agent.
- Stop-hook is prompt-based (Haiku model). Cannot use stop-hook for review logic.
- Each phase agent sets `awaitingApproval`. Natural insertion point: review BEFORE setting awaitingApproval.
- Agents defined as markdown files with frontmatter. No build step required.

### Dependencies

- No new external dependencies. Reviewer is a markdown agent file using existing Task tool infrastructure.
- Existing signal pattern (VERIFICATION_PASS/FAIL) can be extended to REVIEW_PASS/REVIEW_FAIL.

## Quality Commands

| Type | Command | Source |
|------|---------|--------|
| Lint (plugin) | `grep` pattern matching in markdown files | Manual verification |
| Test (plugin) | N/A - markdown plugin, no build/test | Plugin architecture |
| Verify | Pattern grep in modified files | Task verify fields |

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | High | Uses existing Task tool + agent pattern. No new infrastructure needed. |
| Effort Estimate | M | 10 files to create/modify. All markdown, no build step. |
| Risk Level | Low | Additive change. Review loop is opt-in per phase. Graceful degradation on max iterations. |
| Breaking Changes | None | Existing flow preserved. Review inserted as additional step before awaitingApproval. |

## Recommendations

1. Create `spec-reviewer.md` agent with read-only review focus and type-specific rubrics
2. Integrate review loop into each phase command between agent completion and awaitingApproval
3. Use REVIEW_PASS/REVIEW_FAIL signals with max 3 iterations
4. For execution phase, reviewer checks implementation quality (distinct from qa-engineer command verification)
5. Graceful degradation: after 3 iterations, present best result with quality warnings appended

## Sources

- Codebase: `plugins/ralph-specum/agents/spec-executor.md`, `qa-engineer.md`, `research-analyst.md`
- Codebase: `plugins/ralph-specum/commands/research.md`, `requirements.md`, `design.md`, `tasks.md`, `implement.md`, `start.md`
- Codebase: `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
- External: AWS Evaluator-Reflect-Refine, CrewAI role-based reviewer, Reflexion self-reflection patterns
