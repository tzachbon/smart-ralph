# Research: token-efficient-executor

## Executive Summary

The 570-line spec-executor agent prompt can be compressed to ~200 lines (60-65% reduction) with zero behavioral change. Three complementary strategies: (1) remove sections redundant with coordinator/stop-watcher (35-40% of content), (2) convert prose to terse bullets/tables using Claude 4.x-optimized formatting, (3) add explicit output constraints with few-shot examples to cut agent output tokens by ~90%. Research confirms combined manual compression achieves 50-65% reduction safely, and Claude 4.x responds better to declarative language than emphatic CAPS/MUST phrasing.

## External Research

### Prompt Compression Techniques

**Highest-impact techniques (ordered by savings):**

| Technique | Savings | Risk |
|-----------|---------|------|
| Prose to bullets | 20-30% | None |
| Deduplication | 15-20% | None |
| Filler removal ("please", "make sure to", "remember to") | 10-15% | None |
| Remove model-default rules | 5-10% | Low |
| Schema over examples (1 schema vs 3 examples) | ~89% per section | None |
| Dial back emphasis ("CRITICAL: MUST" -> "Always") | ~70% per instance | Low |

**Claude 4.x specific findings:**
- Overtriggering is bigger risk than undertriggering -- aggressive language causes issues
- Anthropic: "Where you might have said 'CRITICAL: You MUST use this tool when...', use 'Use this tool when...'"
- XML tags + markdown bullets = optimal format for Claude
- Bookend strategy: critical rules at start AND end (middle gets "lost")
- Declarative phrasing ("The agent commits after each task") outperforms imperative ("You should commit")

**Empirical data:**
- LLMLingua-2: 2-5x compression with <2% accuracy loss (Microsoft/ACL 2024)
- Combined manual techniques: 40-70% reduction maintaining quality (10Clouds, FlowHunt 2025)
- Rules at end followed ~15-20% more reliably than middle rules (Microsoft Research)
- Don't exceed 80% compression -- target 60-65% for safety

### Concise Agent Output Patterns

**Output constraint techniques:**
- Fixed-format template + few-shot examples + suppression instructions = most effective combination
- Plain key:value format beats JSON by ~35% fewer tokens for flat status data
- Token budget in instructions reduced CoT output from 258 to 86 tokens (Nayab et al.)
- CodeAgents: codified prompting reduces tokens by 67.8% vs natural language

**Proposed output format (4-5 lines, ~20-30 tokens):**
```text
TASK_COMPLETE
status: pass|fail|blocked
commit: <hash>|none
verify: <one-line result>
error: <one-line if fail, omit if pass>
```

**Anti-patterns to suppress:**
- Task echoing (restating the task description)
- Reasoning narration ("First I'll check...")
- Success celebration ("Great news!")
- Full error logs (just first relevant line)
- File listings (commit hash is sufficient)
- Explaining "why" (save for commit messages)

### Pitfalls to Avoid
- Don't exceed 80% compression ratio (semantic loss risk)
- Test incrementally -- remove one category at a time
- Keep removed-rule audit trail
- Monitor task completion rate before/after

## Codebase Analysis

### Existing Patterns

The spec-executor (570 lines) has 21 sections. Analysis found:
- **11 sections to KEEP** (core executor responsibilities)
- **4 sections REDUNDANT** (enforced by coordinator/stop-watcher)
- **6 sections to SHORTEN** (contain coordinator-level reasoning)

### Redundancy Map

| Section | Lines | Enforced By | Verdict | Savings |
|---------|-------|-------------|---------|---------|
| Phase-Specific Rules | 160-210 | Task-planner decisions | REMOVE | 50 tokens |
| Parallel Execution detail | 52-76 | Coordinator orchestration | COMPRESS to 5 lines | 45 tokens |
| [VERIFY] Handling | 248-296 | Executor + coordinator | COMPRESS to 10 lines | 40 tokens |
| File Locking detail | 360-396 | Coordinator manages | COMPRESS to 8 lines | 25 tokens |
| State File Protection | 534-550 | Architecture guarantee | REMOVE (1-line note) | 20 tokens |
| Execution Flow diagram | 78-103 | Coordinator loop | COMPRESS to 5 steps | 20 tokens |
| Default Branch Protection | 319-333 | Start command | REMOVE (1-line note) | 15 tokens |
| Completion Integrity detail | 552-569 | Coordinator verification | COMPRESS to 5 lines | 15 tokens |
| When Invoked | 40-50 | Coordinator input | COMPRESS to 3 lines | 15 tokens |
| Error Handling | 398-412 | Coordinator retry | COMPRESS (trim 3 lines) | 10 tokens |

**Total redundancy savings: 175-230 tokens (35-40%)**

### Unique Rules (Must Keep)

1. **End-to-End Validation** -- prove features work in real environments
2. **TDD Tag Handling** -- [RED]/[GREEN]/[YELLOW] interpretation
3. **Task Modification Requests** -- SPLIT_TASK, ADD_PREREQUISITE, ADD_FOLLOWUP signals
4. **Commit Discipline** -- exact files to commit per task
5. **Execution Rules** -- Do/Verify/Commit flow, no user interaction
6. **Progress Updates** -- format and timing
7. **Karpathy Rules** -- surgical changes, simplicity-first
8. **Output Format** -- TASK_COMPLETE signal contract
9. **Communication Style** -- extreme conciseness mandate

### Dependencies
- No external dependencies affected
- Coordinator-executor contract (TASK_COMPLETE signal) unchanged
- Stop-watcher pattern matching unchanged

### Constraints
- Must preserve TASK_COMPLETE and TASK_MODIFICATION_REQUEST output contracts
- Must preserve flock usage for parallel execution (even if explanation is trimmed)
- Cannot remove TDD tag handling or modification request signaling

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|-----------|-------|
| Technical feasibility | High | Pure prompt rewrite, no code changes |
| Risk level | Low | Zero behavioral change, only removing explanatory text |
| Effort | Small | Single file rewrite with clear redundancy map |
| Token savings (prompt) | ~200-250 tokens per invocation | 35-40% of current prompt |
| Token savings (output) | ~170-470 tokens per task | ~90% reduction in completion output |
| Over 40-task spec | ~15,000-29,000 total tokens saved | Significant cost/latency reduction |

## Recommendations for Requirements

1. Rewrite spec-executor.md from 570 to ~200 lines using terse bullet/table format
2. Remove 4 fully redundant sections (phase rules, branch protection, state protection, parallel detail)
3. Compress 6 partially redundant sections to executor-essentials only
4. Add explicit output format template with 2 few-shot examples
5. Add suppression instructions (no narration, no file lists, no celebration)
6. Replace emphatic language (CRITICAL/MUST/ALWAYS) with declarative phrasing
7. Use bookend strategy for critical rules (start + end)
8. Test with sample task execution before/after to verify no behavioral regression

## Open Questions

1. Should we also set max_tokens on executor subagent calls as a hard output guardrail?
2. Should the compressed prompt use XML tags or pure markdown (both work well with Claude)?

## Sources

- [LLMLingua-2 (ACL 2024)](https://arxiv.org/abs/2403.12968)
- [CompactPrompt](https://arxiv.org/html/2510.18043v1)
- [Anthropic Claude 4 Best Practices](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices)
- [Token Optimization (Portkey)](https://portkey.ai/blog/optimize-token-efficiency-in-prompts/)
- [Context Engineering (FlowHunt)](https://www.flowhunt.io/blog/context-engineering-ai-agents-token-optimization/)
- [CodeAgents](https://arxiv.org/html/2507.03254v1)
- [Token-Budget-Aware LLM Reasoning](https://arxiv.org/html/2412.18547v1)
- [Anthropic Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Anthropic Building Effective Agents](https://www.anthropic.com/research/building-effective-agents)
- [Prompt Format Impact](https://arxiv.org/html/2411.10541v1)
- [MCP Schema JSON-to-XML 47% Reduction](https://github.com/Kilo-Org/kilocode/discussions/1301)
