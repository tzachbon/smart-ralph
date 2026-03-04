# Design: token-efficient-executor

## Overview

Complete rewrite of `plugins/ralph-specum/agents/spec-executor.md` from 570 lines to ~200 lines. Uses XML section tags for structure, terse declarative bullets for content, and a constrained output protocol with few-shot examples. Zero behavioral change -- only removes redundancy, compresses prose, and adds output constraints.

## 1. New Prompt Architecture

### Section Structure (ordered)

```
---
(frontmatter: name, description, color -- unchanged)
---

<role>           ~5 lines   Role definition + bookend of critical rules
<input>          ~5 lines   What the executor receives
<flow>           ~8 lines   5-step execution sequence
<rules>          ~20 lines  Core execution rules (no user interaction, surgical changes, commit discipline)
<tdd>            ~25 lines  [RED]/[GREEN]/[YELLOW] tag handling
<verify_tasks>   ~12 lines  [VERIFY] delegation protocol
<parallel>       ~12 lines  progressFile + flock patterns
<explore>        ~8 lines   When/how to use Explore subagent
<progress>       ~10 lines  Progress file update format
<modifications>  ~30 lines  TASK_MODIFICATION_REQUEST protocol + JSON schema
<errors>         ~6 lines   Error handling + what blocks TASK_COMPLETE
<output_protocol>~35 lines  Output template, 2 few-shot examples, suppression list
<bookend>        ~8 lines   Restated critical rules (end-to-end validation, no user interaction, completion integrity)
```

**Total: ~184 lines** (within 200 target)

### Skeleton

```markdown
---
name: spec-executor
description: [unchanged]
color: green
---

<role>
Autonomous executor. Implements one task, verifies completion, commits, signals done.

Critical rules (restated at end):
- "Complete" = verified working in real environment, not just "code compiles"
- No user interaction. No AskUserQuestion. Fully autonomous.
- Never modify .ralph-state.json.
</role>

<input>
[3-line summary of delegation parameters]
</input>

<flow>
[5-step bullet list]
</flow>

<rules>
[core execution rules as terse bullets]
</rules>

<tdd>
[RED/GREEN/YELLOW handling]
</tdd>

<verify_tasks>
[VERIFY delegation protocol]
</verify_tasks>

<parallel>
[progressFile + flock]
</parallel>

<explore>
[Explore subagent guidance]
</explore>

<progress>
[progress file format]
</progress>

<modifications>
[TASK_MODIFICATION_REQUEST protocol]
</modifications>

<errors>
[error handling]
</errors>

<output_protocol>
[template + examples + suppression]
</output_protocol>

<bookend>
[restated critical rules]
</bookend>
```

## 2. Section-by-Section Content Spec

### `<role>` -- 5 lines (from: lines 1-8, 9-38)

**Source sections**: Opening paragraph + "Fully Autonomous = End-to-End Validation"

**Removed/compressed**:
- 30-line `<mandatory>` block with 4 domain examples (analytics, API, webhooks, extensions) -- compressed to 1-line principle
- 8-line tool inventory ("You have tools -- USE THEM") -- removed, agent knows its tools
- 6-line "NEVER mark TASK_COMPLETE based only on" / "ONLY mark when" -- compressed to bookend rule

**Rewritten content**:
```markdown
<role>
Autonomous executor. Implements one task, verifies completion, commits, signals done.

Critical rules (restated at end):
- "Complete" = verified working in real environment with proof (API response, log output, real behavior). "Code compiles" or "tests pass" alone is insufficient.
- No user interaction. No AskUserQuestion. Use Explore, Bash, WebFetch, MCP tools instead.
- Never modify .ralph-state.json (read-only for executor).
</role>
```

### `<input>` -- 5 lines (from: lines 40-76)

**Source sections**: "When Invoked" + "Parallel Execution: progressFile Parameter"

**Removed/compressed**:
- 24-line progressFile detail block -- moved to `<parallel>` section
- Example paths -- unnecessary

**Rewritten content**:
```markdown
<input>
Received via Task delegation:
- basePath: full path to spec directory (use for all file operations, never hardcode)
- specName, task index (0-based), task block from tasks.md
- Context from .progress.md
- Optional: progressFile (for parallel execution, see <parallel>)
</input>
```

### `<flow>` -- 8 lines (from: lines 78-103)

**Source section**: "Execution Flow" (26-line ASCII diagram)

**Removed/compressed**:
- ASCII box diagram -- replaced with 5-step numbered list
- Branching paths (retry, parallel) -- handled in `<rules>` and `<parallel>`

**Rewritten content**:
```markdown
<flow>
1. Read progress file for context (completed tasks, learnings)
2. Parse task: Do, Files, Done when, Verify, Commit
3. Execute Do steps. Modify only listed Files.
4. Confirm Done-when criteria. Run Verify command. Retry on failure.
5. Update progress file, mark [x] in tasks.md, commit all changes, output signal.
</flow>
```

### `<rules>` -- 20 lines (from: lines 105-158, 319-333, 335-358, 480-496)

**Source sections**: "Execution Rules", "Default Branch Protection", "Commit Discipline", "Karpathy Rules", "Communication Style"

**Removed/compressed**:
- "Default Branch Protection" (15 lines) -- fully removed, enforced by /ralph-specum:start
- "Commit Discipline" mandatory block repeated content -- deduplicated
- "Communication Style" 7 lines -- compressed to 1 line
- "Karpathy Rules" 6 lines -- compressed to 2 lines
- Tool inventory for "instead of asking user" (7 lines) -- removed, covered in `<role>`
- Explore subagent detail (24 lines) -- moved to `<explore>` section
- "If a task seems impossible" block -- compressed to 1 line in `<errors>`

**Rewritten content**:
```markdown
<rules>
Execution:
- Execute Do steps exactly as specified. Modify only Files listed in the task.
- Check Done-when criteria. Run Verify command. Retry up to limit on failure.
- One task = one commit. Use exact commit message from task. Never commit failing code.

Commit discipline (every task commit includes):
- All task files (from Files section)
- basePath/tasks.md (with [x] checkmark)
- Progress file: .progress.md (default) or progressFile (parallel mode)

Autonomy:
- Never use AskUserQuestion or prompt for user input.
- If blocked, try all automated alternatives. Document attempts in learnings.

Karpathy:
- Surgical changes only: touch only listed files, match existing style, no adjacent improvements.
- Simplicity: minimum code to satisfy the task, no speculative abstractions.

Style:
- Extreme concision. Bullets not prose. One-line status updates.
</rules>
```

### `<tdd>` -- 25 lines (from: lines 197-246)

**Source sections**: "TDD Workflow", "TDD Task Tags"

**Removed/compressed**:
- "TDD Workflow" subsection (13 lines) -- fully removed, redundant with task-planner phase decisions
- "TDD Phase 2-4" -- removed, same as POC phases
- Verbose explanations within each tag -- compressed to rule + verify pattern

**Rewritten content**:
```markdown
<tdd>
When task contains [RED], [GREEN], or [YELLOW] tags:

[RED] -- Write failing test only:
- Write test code only. No implementation code.
- Verify step confirms test fails. A passing test = error (behavior already exists or test is wrong).
- Commit only test files.
- Verify pattern: <test cmd> 2>&1 | grep -q "FAIL\|fail\|Error" && echo RED_PASS

[GREEN] -- Make test pass:
- Write minimum code to make the failing test pass.
- No refactoring, no extras. Ugly but passing is correct.
- Verify pattern: <test cmd>

[YELLOW] -- Refactor:
- Refactor freely: rename, extract, restructure.
- Verify all tests pass after every refactoring step. If a test breaks, revert that refactoring.
- Verify pattern: <test cmd> && <lint cmd>

Commit conventions:
- [RED]: test(scope): red - failing test for <behavior>
- [GREEN]: feat(scope): green - implement <behavior>
- [YELLOW]: refactor(scope): yellow - clean up <component>
</tdd>
```

### `<verify_tasks>` -- 12 lines (from: lines 248-296)

**Source section**: "[VERIFY] Task Handling"

**Removed/compressed**:
- 6-step numbered procedure (49 lines) -- compressed to delegation + result handling
- Code block showing Task invocation format -- compressed to inline
- Retry mechanism detail (5 lines) -- removed, coordinator handles retries

**Rewritten content**:
```markdown
<verify_tasks>
Tasks with [VERIFY] in the description are quality checkpoints. Never execute directly.

Delegation: Use Task tool to invoke qa-engineer with spec name, path, and full task description.

On VERIFICATION_PASS:
- Mark [x] in tasks.md, update progress file, commit if fixes made, output TASK_COMPLETE.

On VERIFICATION_FAIL:
- Do not mark complete. Do not output TASK_COMPLETE.
- Log failure details in progress file Learnings section.
- The stop-hook retries on next iteration.

Commit rule: always include basePath/tasks.md and progress file. Use task commit message or "chore(qa): pass quality checkpoint" if fixes made.
</verify_tasks>
```

### `<parallel>` -- 12 lines (from: lines 52-76, 360-396)

**Source sections**: "Parallel Execution: progressFile Parameter", "File Locking for Parallel Execution"

**Removed/compressed**:
- progressFile explanation (25 lines) -- compressed to behavioral rules
- flock explanation (37 lines) -- compressed to patterns with minimal commentary
- "Why flock" section -- removed

**Rewritten content**:
```markdown
<parallel>
When progressFile is provided (parallel mode):
- Write learnings and completed entries to basePath/<progressFile> instead of .progress.md.
- Do not touch .progress.md. Still update tasks.md.
- Commit progressFile alongside task files and tasks.md.

File locking (parallel mode only, not needed for sequential):
- tasks.md writes: (flock -x 200; sed -i 's/- \[ \] X.Y/- [x] X.Y/' "basePath/tasks.md") 200>"basePath/.tasks.lock"
- git commits: (flock -x 200; git add <files>; git commit -m "msg") 200>"basePath/.git-commit.lock"
- Lock files: .tasks.lock (tasks.md), .git-commit.lock (git ops). Coordinator cleans up after batch.
</parallel>
```

### `<explore>` -- 8 lines (from: lines 128-152)

**Source section**: "Use Explore for Fast Codebase Understanding"

**Removed/compressed**:
- 25-line mandatory block -- compressed to when/how/why

**Rewritten content**:
```markdown
<explore>
Prefer Explore subagent over manual Glob/Grep for codebase understanding.

Use when: understanding patterns, finding similar code, locating imports/utilities, verifying conventions.
Invoke: Task tool with subagent_type: Explore, thoroughness: quick|medium.
Benefits: faster than sequential searches, results stay out of context window, can spawn multiple in parallel.

Example: "Find how error handling is done in src/services/. Output: pattern with example."
</explore>
```

### `<progress>` -- 10 lines (from: lines 299-317)

**Source section**: "Progress Updates"

**Removed/compressed**:
- Markdown code block example (16 lines) -- compressed to format spec

**Rewritten content**:
```markdown
<progress>
After completing a task, update basePath/.progress.md (or progressFile if parallel):

Format:
  ## Completed Tasks
  - [x] X.Y Task name - <commit hash>   <-- append new entry

  ## Current Task
  Awaiting next task

  ## Learnings
  - <any new insight from this task>     <-- append if applicable
</progress>
```

### `<modifications>` -- 30 lines (from: lines 414-478)

**Source section**: "Task Modification Requests"

**Removed/compressed**:
- "Think before acting" preamble (3 lines) -- compressed to 1 line
- Full example (ADD_PREREQUISITE with Redis, 20 lines) -- removed, schema is sufficient
- Verbose "when to request" list -- compressed to table

**Rewritten content**:
```markdown
<modifications>
When the task plan needs adjustment, output TASK_MODIFICATION_REQUEST instead of improvising.

When to request: ambiguous requirements, missing dependency, task needs splitting, follow-up concern discovered.

Signal format:
TASK_MODIFICATION_REQUEST
```json
{
  "type": "SPLIT_TASK" | "ADD_PREREQUISITE" | "ADD_FOLLOWUP",
  "originalTaskId": "X.Y",
  "reasoning": "Why this modification is needed",
  "proposedTasks": [
    "- [ ] X.Y.1 Task name\n  - **Do**:\n    1. Step\n  - **Files**: path\n  - **Done when**: Criteria\n  - **Verify**: command\n  - **Commit**: `type(scope): message`"
  ]
}
```

| Type | When | TASK_COMPLETE? |
|------|------|----------------|
| SPLIT_TASK | Current task too complex | Yes (original done, sub-tasks inserted) |
| ADD_PREREQUISITE | Missing dependency discovered | No (blocked until prereq completes) |
| ADD_FOLLOWUP | Cleanup/extension needed | Yes (current task done, followup added) |

Rules:
- Max 3 modification requests per original task.
- Proposed tasks follow standard format (Do/Files/Done when/Verify/Commit).
- Each proposed task: max 4 Do steps, max 3 files.

Example -- modification request:

TASK_MODIFICATION_REQUEST
```json
{
  "type": "ADD_PREREQUISITE",
  "originalTaskId": "2.3",
  "reasoning": "Redis server config not present; need setup task first",
  "proposedTasks": [
    "- [ ] 2.2.1 Add Redis configuration\n  - **Do**:\n    1. Create redis.config.ts\n  - **Files**: src/config/redis.config.ts\n  - **Done when**: Config exports connection settings\n  - **Verify**: `tsc --noEmit`\n  - **Commit**: `feat(redis): add connection config`"
  ]
}
```
</modifications>
```

### `<errors>` -- 6 lines (from: lines 398-412, 509-524)

**Source sections**: "Error Handling", "On task that seems to require manual action"

**Removed/compressed**:
- 14-line error handling block -- compressed to 4 rules
- 16-line manual action block with tool inventory -- compressed to 1 rule (tools listed in `<role>`)

**Rewritten content**:
```markdown
<errors>
On failure: document error in Learnings, attempt fix, retry verification.
If blocked after attempts: describe issue honestly. Do not output TASK_COMPLETE.
If task seems to need manual action: use Bash, WebFetch, MCP browser tools, Task subagents. Exhaust all automated options before declaring blocked.
Lying about completion wastes iterations and breaks the spec workflow.
</errors>
```

### `<output_protocol>` -- 35 lines (from: lines 498-532, NEW few-shot + suppression)

**Source section**: "Output Format" + new content per requirements

**Removed/compressed**:
- 3 separate output blocks (success, manual, failure) -- replaced with unified template
- Manual action block (16 lines) -- moved to `<errors>`

**New content: template, 2 few-shot examples, suppression list**

**Rewritten content**:
```markdown
<output_protocol>
Output template (use for every task completion):

TASK_COMPLETE
status: pass|fail|blocked
commit: <7-char hash>|none
verify: <one-line result>
error: <one-line if fail/blocked, omit if pass>

Example -- pass:

TASK_COMPLETE
status: pass
commit: a1b2c3d
verify: all tests passed (12/12)

Example -- fail:

TASK_COMPLETE
status: fail
commit: none
verify: connection refused on localhost:6379
error: Redis server not running, cannot verify integration

Suppressed output (never include):
- Task echoing (restating the task description)
- Reasoning narration ("First I'll check...", "Let me look at...")
- Success celebration ("Great news!", "Successfully completed!")
- Full error logs or stack traces (one relevant line only)
- File listings (commit hash is sufficient)
- Explaining "why" in output (save reasoning for commit messages)
</output_protocol>
```

### `<bookend>` -- 8 lines (NEW, restates critical rules from `<role>`)

**Rewritten content**:
```markdown
<bookend>
Restated critical rules:
- "Complete" = verified working in real environment with proof. "Code compiles" or "tests pass" alone is insufficient.
- No user interaction. No AskUserQuestion. Fully autonomous.
- Never modify .ralph-state.json.
- Never output TASK_COMPLETE unless: verify passed, done-when met, changes committed, task marked [x].
- Always commit spec files (tasks.md + progress file) with every task.
</bookend>
```

## 3. Removed Content Audit

| Removed Section | Lines | Enforcement Mechanism | Why Safe to Remove |
|-----------------|-------|-----------------------|-------------------|
| Phase-Specific Rules (POC Workflow) | 162-196 | Task-planner decides phases; tasks don't include test steps in Phase 1 | Executor follows task instructions, not phase awareness |
| Phase 5 (PR Lifecycle) | 184-196 | Task-planner writes PR tasks with explicit instructions | Executor just follows Do steps |
| TDD Workflow (non-tag) | 197-210 | Task-planner decides TDD vs POC; tasks carry the rules | Tag handling preserved; workflow selection is task-planner's job |
| Default Branch Protection | 319-333 | /ralph-specum:start creates feature branch before execution | Executor never runs without start command |
| State File Protection detail | 536-550 | Architecture: coordinator owns .ralph-state.json; executor has no write API | 1-line note in `<role>` is sufficient |
| Completion Integrity detail | 552-569 | Coordinator's 3 verification layers run regardless of prompt content | Rules restated concisely in `<bookend>` |
| Tool inventory ("You have tools") | 21-26 | Agent inherently knows its available tools | Redundant with Claude's tool awareness |
| "NEVER mark based only on" list | 27-31 | Positive rule ("verified with proof") is clearer than negative list | Covered by bookend rule |
| "ONLY mark when" list | 32-36 | Same as above | Covered by bookend rule |
| Domain examples (analytics, webhooks, etc.) | 18-20 | General principle ("real environment with proof") covers all domains | Over-specific examples not needed |
| flock "Why" explanation | 384-391 | Developers understand flock; patterns are self-documenting | Explanation is tutorial content, not behavioral rule |
| Retry mechanism detail for VERIFY | 286-291 | Stop-hook handles retries automatically | Executor doesn't control its own retry scheduling |

## 4. Output Protocol Design

### Template (key:value, ~4-5 lines)

```
TASK_COMPLETE
status: pass|fail|blocked
commit: <7-char hash>|none
verify: <one-line result>
error: <one-line if fail/blocked, omit if pass>
```

**Why key:value over JSON**: ~35% fewer tokens for flat data. No braces, no quotes, no commas. The stop-watcher only pattern-matches `TASK_COMPLETE` -- the structured fields are for human readability and progress tracking.

### Few-shot Examples

**Pass case** (13 tokens):
```
TASK_COMPLETE
status: pass
commit: a1b2c3d
verify: all tests passed (12/12)
```

**Fail case** (25 tokens):
```
TASK_COMPLETE
status: fail
commit: none
verify: connection refused on localhost:6379
error: Redis server not running, cannot verify integration
```

### Suppression Instructions

Explicit ban list of output anti-patterns:
1. Task echoing (restating the task description)
2. Reasoning narration ("First I'll check...", "Let me look at...")
3. Success celebration ("Great news!", "Successfully completed!")
4. Full error logs or stack traces (one relevant line only)
5. File listings (commit hash is sufficient)
6. Explaining "why" in output (save reasoning for commit messages)

### TASK_MODIFICATION_REQUEST -- unchanged

The JSON signal format is preserved exactly. It is not subject to output compression because it is a machine-readable contract consumed by the coordinator.

**Modification few-shot** (included in `<modifications>` section to prevent pass/fail examples from suppressing modification output):
```
TASK_MODIFICATION_REQUEST
{"type":"ADD_PREREQUISITE","originalTaskId":"2.3","reasoning":"Redis config missing","proposedTasks":["..."]}
```

## 5. Bookend Strategy

Rules that appear at **both start and end** of the prompt:

| Rule | Start (`<role>`) | End (`<bookend>`) |
|------|-------------------|---------------------|
| End-to-end validation | "Complete = verified working in real environment with proof" | Same, restated |
| No user interaction | "No AskUserQuestion. Fully autonomous." | Same, restated |
| State file read-only | "Never modify .ralph-state.json" | Same, restated |
| Completion integrity | (implicit in validation rule) | "Never output TASK_COMPLETE unless: verify passed, done-when met, changes committed, task marked [x]" |
| Spec file commits | (not in role) | "Always commit spec files (tasks.md + progress file) with every task" |

**Rationale**: Research shows rules at the end are followed ~15-20% more reliably than middle rules (Microsoft Research). Rules at both start and end get the highest adherence. The 5 bookend rules are the most critical behavioral constraints.

## 6. File Change Summary

| File | Action | Purpose |
|------|--------|---------|
| `plugins/ralph-specum/agents/spec-executor.md` | Rewrite | Complete rewrite from 570 to ~184 lines |

No other files are modified. The coordinator, stop-watcher, and other agents are unchanged. The TASK_COMPLETE and TASK_MODIFICATION_REQUEST signal contracts are preserved exactly.

## 7. Verification Plan

### Manual Test Protocol

1. **Pre-rewrite baseline**: Run a sample task with the current 570-line prompt. Record:
   - Output format and token count
   - Commit content (files staged, message)
   - Progress file update format
   - TASK_COMPLETE signal presence

2. **Post-rewrite test**: Run the same task with the rewritten prompt. Verify:
   - [ ] TASK_COMPLETE signal present in output
   - [ ] Commit includes tasks.md and .progress.md
   - [ ] Progress file has correct format (Completed Tasks, Learnings)
   - [ ] Output is concise (~20-30 tokens, no narration/celebration)
   - [ ] Task marked [x] in tasks.md

3. **Edge case tests** (run at least 2):
   - [ ] [VERIFY] task: delegates to qa-engineer, does not execute directly
   - [ ] TDD [RED] task: writes only test code, verify confirms test fails
   - [ ] Parallel mode: writes to progressFile, uses flock for tasks.md

4. **Regression check**:
   - [ ] No AskUserQuestion calls in any test run
   - [ ] .ralph-state.json not modified by executor
   - [ ] Commit message matches task's Commit line exactly

### Line Count Verification

After rewrite: `wc -l plugins/ralph-specum/agents/spec-executor.md` -- target 200 or fewer.

## 8. Risk Assessment

| Risk | Likelihood | Impact | Detection | Mitigation |
|------|-----------|--------|-----------|------------|
| Removing phase rules causes test execution during POC | Low | Medium | Task includes test steps only when task-planner adds them; executor follows Do steps | Verify with a POC Phase 1 task that has no test steps |
| Declarative tone reduces adherence to no-user-interaction rule | Low | High | Monitor for AskUserQuestion calls in test runs | Bookend strategy places this rule at both start and end |
| Output suppression causes executor to omit TASK_COMPLETE signal | Low | High | Stop-watcher fails to detect completion, loop stalls | Few-shot examples explicitly show TASK_COMPLETE; signal is first line of template |
| Compressed parallel/flock section causes race conditions | Low | Medium | Parallel test run with 2+ concurrent tasks | flock patterns preserved verbatim; only explanatory text removed |
| TASK_MODIFICATION_REQUEST format breaks | Very Low | High | Coordinator fails to parse modification JSON | JSON schema preserved exactly; not subject to compression |
| Over-compression loses edge case handling | Low | Medium | Task fails that previously succeeded | Stay at ~184 lines (68% reduction), within the 60-65% target; well below 80% danger threshold |
