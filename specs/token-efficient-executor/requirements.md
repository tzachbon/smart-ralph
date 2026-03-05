# Requirements: token-efficient-executor

## Goal

Rewrite the spec-executor agent prompt from 570 lines to ~200 lines and add output constraints to reduce agent output tokens by ~90%, with zero behavioral regression.

## User Stories

### US-1: Reduced Prompt Token Cost

**As a** Ralph Specum user
**I want** the spec-executor prompt to be 60-65% smaller
**So that** each task invocation consumes fewer input tokens, reducing cost and latency across 40-60 task specs

**Acceptance Criteria:**
- AC-1.1: Rewritten spec-executor.md is 200 lines or fewer (down from 570)
- AC-1.2: All 9 unique behavioral rules identified in research are preserved (end-to-end validation, TDD tags, task modification requests, commit discipline, execution rules, progress updates, Karpathy rules, output format, communication style)
- AC-1.3: No sections removed that contain executor-unique logic

### US-2: Reduced Output Token Cost

**As a** Ralph Specum user
**I want** the executor agent to produce minimal output per task
**So that** output tokens drop ~90% (from ~200-500 tokens to ~20-30 tokens per task)

**Acceptance Criteria:**
- AC-2.1: Prompt includes a fixed-format output template (key:value, not JSON)
- AC-2.2: Prompt includes at least 2 few-shot examples (pass and fail cases)
- AC-2.3: Prompt includes explicit suppression instructions for narration, celebration, file lists, and task echoing
- AC-2.4: TASK_COMPLETE and TASK_MODIFICATION_REQUEST signal contracts are unchanged

### US-3: No Behavioral Regression

**As a** Ralph Specum user
**I want** the compressed prompt to produce identical task execution behavior
**So that** specs complete correctly without rewriting tasks or coordinator logic

**Acceptance Criteria:**
- AC-3.1: Manual test run of a sample task produces correct commit, progress update, and TASK_COMPLETE signal
- AC-3.2: [VERIFY] tasks still delegate to qa-engineer
- AC-3.3: TDD [RED]/[GREEN]/[YELLOW] tags still trigger correct execution modes
- AC-3.4: Parallel execution (progressFile parameter) still works correctly
- AC-3.5: Task modification requests (SPLIT_TASK, ADD_PREREQUISITE, ADD_FOLLOWUP) still emit correct JSON format

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | Remove fully redundant sections: Phase-Specific Rules (lines 160-210), Default Branch Protection (lines 319-333), State File Protection (lines 534-550) | High | Sections absent from rewrite; behavior unchanged because coordinator/start-command/architecture enforce these |
| FR-2 | Compress partially redundant sections to executor-essentials only: Parallel Execution detail to ~5 lines, [VERIFY] Handling to ~10 lines, File Locking to ~8 lines, Execution Flow to ~5 steps, When Invoked to ~3 lines, Error Handling trim ~3 lines, Completion Integrity to ~5 lines | High | Each section present but at target line count; no executor-unique rule lost |
| FR-3 | Rewrite all emphatic language (CRITICAL, MUST, ALWAYS, NEVER, NON-NEGOTIABLE) to declarative phrasing | High | Zero instances of ALL-CAPS emphasis words except signal names (TASK_COMPLETE, TASK_MODIFICATION_REQUEST) and tag names ([RED], [GREEN], [YELLOW], [VERIFY]) |
| FR-4 | Add fixed-format output template for task completion (key:value, ~4-5 lines, ~20-30 tokens) | High | Template present in prompt with fields: status, commit, verify, error (optional) |
| FR-5 | Add 2 few-shot output examples: one pass case, one fail case | High | Examples present showing exact expected output format |
| FR-6 | Add explicit suppression instructions listing banned output patterns: task echoing, reasoning narration, success celebration, full error logs, file listings | High | Suppression list present in prompt |
| FR-7 | Use bookend strategy: place critical rules (end-to-end validation, completion integrity, no-user-interaction) at both start and end of prompt | Medium | Critical rules appear in opening section and are restated in closing section |
| FR-8 | Convert prose paragraphs to terse bullets and tables where possible | Medium | No prose paragraphs longer than 2 sentences remain |
| FR-9 | Preserve the Explore subagent guidance (when and how to use Explore for codebase understanding) | Medium | Explore usage instructions present in compressed form |
| FR-10 | Preserve Task Modification Request JSON schema and all 3 modification types with their rules | High | TASK_MODIFICATION_REQUEST section retained with schema, type table, and rules |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Prompt size | Line count | 200 lines max |
| NFR-2 | Prompt compression ratio | % reduction from 570 lines | 60-65% |
| NFR-3 | Output token reduction | Tokens per task completion | ~20-30 tokens (down from ~200-500) |
| NFR-4 | Compression safety margin | Max compression ratio | Do not exceed 80% reduction (risk of semantic loss) |
| NFR-5 | Verification approach | Manual test | Run at least one sample task before/after and compare: commit correctness, progress update format, signal output |
| NFR-6 | No behavioral regression | Task completion rate | Same pass rate on equivalent tasks before and after rewrite |
| NFR-7 | Format compatibility | Claude 4.x optimization | Use XML tags + markdown bullets (optimal format per research) |

## Glossary

- **Executor**: The spec-executor agent that runs one task at a time
- **Coordinator**: The implement command loop that delegates tasks to the executor and manages state
- **Stop-watcher**: The hook script that detects ALL_TASKS_COMPLETE and controls loop termination; TASK_COMPLETE is consumed by the coordinator
- **Bookend strategy**: Placing critical rules at both the beginning and end of a prompt to maximize adherence
- **Suppression instructions**: Explicit instructions telling the agent what NOT to output
- **Few-shot examples**: Concrete output samples that demonstrate expected format
- **Declarative phrasing**: Stating rules as facts ("The agent commits after each task") rather than imperatives ("You MUST commit")

## Out of Scope

- Changes to the coordinator prompt (implement.md)
- Changes to the stop-watcher script (stop-watcher.sh)
- Changes to other agents (research-analyst, product-manager, architect-reviewer, task-planner, triage-analyst)
- Changes to the qa-engineer agent
- Setting max_tokens on executor subagent calls (potential follow-up)
- Automated regression testing framework (manual test is sufficient for this scope)
- Changes to the TASK_COMPLETE or TASK_MODIFICATION_REQUEST signal contracts

## Dependencies

- Current spec-executor.md (570 lines) as source material
- Research findings (research.md) for compression strategy and redundancy map
- Existing coordinator and stop-watcher contracts (TASK_COMPLETE signal format) must remain stable

## Success Criteria

- spec-executor.md rewritten to 200 lines or fewer
- Zero instances of emphatic ALL-CAPS language (except signal/tag names)
- Output template with 2 few-shot examples and suppression list present
- Manual test of sample task shows identical behavior (commit, progress, signal)
- Removed-section audit trail documented (which sections were removed and why)

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Over-compression causes executor to miss edge cases (e.g., parallel locking, TDD tags) | High | Stay within 60-65% compression; keep all 9 unique rules; test with edge-case tasks |
| Declarative tone reduces adherence on safety rules (no user interaction, no state file writes) | Medium | Bookend strategy places these at start and end; test specifically for these behaviors |
| Few-shot examples anchor output too rigidly, breaking task modification request format | Medium | Include separate few-shot for modification requests alongside pass/fail examples |
| Removing phase rules causes executor to run tests during POC phase | Low | Phase rules are enforced by task-planner (tasks don't include test steps in Phase 1); verify with POC task test |
