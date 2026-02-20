# Plugin Best Practices Refresh — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Apply plugin-dev best practices to ralph-specum and ralph-speckit: metadata compliance, reference extraction from bloated commands, and superpowers-style task/team patterns.

**Architecture:** Three phases — (A) mechanical metadata fixes, (B) extract procedural logic from commands into `references/` directory loaded via Read tool, (C) add checklist-to-tasks patterns and subagent dispatch templates. Commands become thin orchestrators.

**Tech Stack:** Markdown files (plugin commands, agents, skills), JSON (plugin.json), Bash (validation script)

**Design Doc:** `docs/plans/2026-02-20-plugin-best-practices-design.md`

---

## Phase A: Metadata Compliance

### Task 1: Add color field to ralph-specum agents

**Files:**
- Modify: `plugins/ralph-specum/agents/research-analyst.md:1-4`
- Modify: `plugins/ralph-specum/agents/spec-reviewer.md:1-4`
- Modify: `plugins/ralph-specum/agents/spec-executor.md:1-4`
- Modify: `plugins/ralph-specum/agents/architect-reviewer.md:1-4`
- Modify: `plugins/ralph-specum/agents/task-planner.md:1-4`
- Modify: `plugins/ralph-specum/agents/product-manager.md:1-4`
- Modify: `plugins/ralph-specum/agents/qa-engineer.md:1-4`
- Modify: `plugins/ralph-specum/agents/refactor-specialist.md:1-4`

**Step 1: Add color to each agent's YAML frontmatter**

Add `color` field after `model: inherit` in each file. Color assignment by role:

| Agent | Color | Role |
|-------|-------|------|
| research-analyst | blue | Analysis/Research |
| spec-reviewer | blue | Analysis/Research |
| spec-executor | green | Execution |
| architect-reviewer | cyan | Planning/Design |
| task-planner | cyan | Planning/Design |
| product-manager | cyan | Planning/Design |
| qa-engineer | yellow | Validation/QA |
| refactor-specialist | magenta | Transformation |

Example frontmatter change for `research-analyst.md`:
```yaml
---
name: research-analyst
description: This agent should be used to...
model: inherit
color: blue
---
```

**Step 2: Verify all 8 agents have color field**

Run:
```bash
for f in plugins/ralph-specum/agents/*.md; do
  name=$(basename "$f")
  color=$(grep -m1 '^color:' "$f" | awk '{print $2}')
  echo "$name: ${color:-MISSING}"
done
```
Expected: All 8 agents show their color, none show MISSING.

**Step 3: Commit**

```bash
git add plugins/ralph-specum/agents/*.md
git commit -m "feat(ralph-specum): add color field to all agents"
```

---

### Task 2: Add color field to ralph-speckit agents

**Files:**
- Modify: `plugins/ralph-speckit/agents/spec-analyst.md:1-4`
- Modify: `plugins/ralph-speckit/agents/constitution-architect.md:1-4`
- Modify: `plugins/ralph-speckit/agents/plan-architect.md:1-4`
- Modify: `plugins/ralph-speckit/agents/spec-executor.md:1-4`
- Modify: `plugins/ralph-speckit/agents/task-planner.md:1-4`
- Modify: `plugins/ralph-speckit/agents/qa-engineer.md:1-4`

**Step 1: Add color to each agent's YAML frontmatter**

| Agent | Color | Role |
|-------|-------|------|
| spec-analyst | blue | Analysis/Research |
| constitution-architect | cyan | Planning/Design |
| plan-architect | cyan | Planning/Design |
| spec-executor | green | Execution |
| task-planner | cyan | Planning/Design |
| qa-engineer | yellow | Validation/QA |

**Step 2: Verify all 6 agents have color field**

Run same verification as Task 1 but with `plugins/ralph-speckit/agents/*.md`.

**Step 3: Commit**

```bash
git add plugins/ralph-speckit/agents/*.md
git commit -m "feat(ralph-speckit): add color field to all agents"
```

---

### Task 3: Add version to all skills

**Files:**
- Modify: `plugins/ralph-specum/skills/communication-style/SKILL.md:1-3`
- Modify: `plugins/ralph-specum/skills/delegation-principle/SKILL.md:1-3`
- Modify: `plugins/ralph-specum/skills/interview-framework/SKILL.md:1-3`
- Modify: `plugins/ralph-specum/skills/reality-verification/SKILL.md:1-3`
- Modify: `plugins/ralph-specum/skills/smart-ralph/SKILL.md:1-3`
- Modify: `plugins/ralph-specum/skills/spec-workflow/SKILL.md:1-3`
- Modify: `plugins/ralph-speckit/skills/communication-style/SKILL.md:1-3`
- Modify: `plugins/ralph-speckit/skills/delegation-principle/SKILL.md:1-3`
- Modify: `plugins/ralph-speckit/skills/smart-ralph/SKILL.md:1-3`
- Modify: `plugins/ralph-speckit/skills/speckit-workflow/SKILL.md:1-3`

**Step 1: Add `version: 0.1.0` to each SKILL.md frontmatter**

Current format:
```yaml
---
name: spec-workflow
description: This skill should be used when...
---
```

Target format:
```yaml
---
name: spec-workflow
description: This skill should be used when...
version: 0.1.0
---
```

**Step 2: Verify all 10 skills have version field**

Run:
```bash
for f in plugins/ralph-specum/skills/*/SKILL.md plugins/ralph-speckit/skills/*/SKILL.md; do
  name=$(basename "$(dirname "$f")")
  version=$(grep -m1 '^version:' "$f" | awk '{print $2}')
  echo "$name: ${version:-MISSING}"
done
```
Expected: All 10 skills show `0.1.0`, none show MISSING.

**Step 3: Commit**

```bash
git add plugins/ralph-specum/skills/*/SKILL.md plugins/ralph-speckit/skills/*/SKILL.md
git commit -m "feat(plugins): add version field to all skills"
```

---

### Task 4: Add examples to feedback.md and bump versions

**Files:**
- Modify: `plugins/ralph-specum/commands/feedback.md`
- Modify: `plugins/ralph-specum/.claude-plugin/plugin.json`
- Modify: `plugins/ralph-speckit/.claude-plugin/plugin.json`

**Step 1: Add example blocks to feedback.md**

The file already has an `## Example Usage` section with code blocks. Add proper `<example>` blocks that Claude Code uses for triggering:

Add after the frontmatter `---` closing, before the `# Submit Feedback` heading:

```markdown
<example>
user: /ralph-specum:feedback The task verification system sometimes misses TASK_COMPLETE markers
assistant: I'll create an issue for that feedback.
</example>

<example>
user: /ralph-specum:feedback Feature request: add support for parallel task execution
assistant: I'll submit that feature request as an issue.
</example>
```

**Step 2: Bump plugin versions**

In `plugins/ralph-specum/.claude-plugin/plugin.json`, change version from `3.10.0` to `3.11.0`.
In `plugins/ralph-speckit/.claude-plugin/plugin.json`, change version from `0.5.0` to `0.5.1`.

**Step 3: Verify**

Run:
```bash
grep '"version"' plugins/ralph-specum/.claude-plugin/plugin.json plugins/ralph-speckit/.claude-plugin/plugin.json
grep -c '<example>' plugins/ralph-specum/commands/feedback.md
```
Expected: versions show 3.11.0 and 0.5.1, example count >= 2.

**Step 4: Commit**

```bash
git add plugins/ralph-specum/commands/feedback.md plugins/ralph-specum/.claude-plugin/plugin.json plugins/ralph-speckit/.claude-plugin/plugin.json
git commit -m "chore(plugins): add feedback examples and bump versions for metadata compliance"
```

---

## Phase B: Reference Extraction

### Task 5: Create references directory and extract from implement.md (coordinator + failure recovery)

**Files:**
- Create: `plugins/ralph-specum/references/coordinator-pattern.md`
- Create: `plugins/ralph-specum/references/failure-recovery.md`
- Read: `plugins/ralph-specum/commands/implement.md`

**Step 1: Read implement.md fully**

Read the entire `plugins/ralph-specum/commands/implement.md` file. Identify:
- The coordinator prompt section (task delegation logic, state management, task dispatch)
- The failure recovery section (retry logic, fix-task generation, maxTaskIterations)

**Step 2: Create coordinator-pattern.md**

Create `plugins/ralph-specum/references/coordinator-pattern.md` containing:
- Header: `# Coordinator Pattern` with note: `Used by: implement.md`
- The full coordinator task delegation logic extracted from implement.md
- How to read `.ralph-state.json` for current task index
- How to parse tasks from `tasks.md`
- How to dispatch spec-executor via Task tool
- How to update state after task completion
- The `TASK_COMPLETE` / `ALL_TASKS_COMPLETE` protocol

**Step 3: Create failure-recovery.md**

Create `plugins/ralph-specum/references/failure-recovery.md` containing:
- Header: `# Failure Recovery` with note: `Used by: implement.md`
- Retry logic (increment taskIteration, check maxTaskIterations)
- Fix-task generation logic (when recoveryMode is true)
- Error reporting format
- When to block execution vs retry

**Step 4: Verify files exist and have content**

Run:
```bash
wc -l plugins/ralph-specum/references/coordinator-pattern.md plugins/ralph-specum/references/failure-recovery.md
```
Expected: Both files exist with substantial content (100+ lines each).

**Step 5: Commit**

```bash
git add plugins/ralph-specum/references/
git commit -m "feat(ralph-specum): extract coordinator pattern and failure recovery references"
```

---

### Task 6: Extract remaining implement.md references (verification, phases, commits)

**Files:**
- Create: `plugins/ralph-specum/references/verification-layers.md`
- Create: `plugins/ralph-specum/references/phase-rules.md`
- Create: `plugins/ralph-specum/references/commit-discipline.md`
- Read: `plugins/ralph-specum/commands/implement.md`
- Read: `plugins/ralph-specum/agents/spec-executor.md`

**Step 1: Read implement.md and spec-executor.md**

Identify:
- Verification logic (what checks happen after each task)
- Phase rules (POC, Refactor, Testing, Quality Gates behaviors)
- Commit discipline (conventions from both implement.md and spec-executor.md)

**Step 2: Create verification-layers.md**

- Header: `# Verification Layers` with note: `Used by: implement.md`
- The 4-layer verification pattern after each task completion
- What each layer checks and expected outputs
- How to handle verification failures

**Step 3: Create phase-rules.md**

- Header: `# Phase Rules` with note: `Used by: implement.md, task-planner agent`
- POC phase: skip tests, focus on making it work
- Refactor phase: code cleanup, no new features
- Testing phase: unit, integration, e2e
- Quality Gates phase: lint, types, CI

**Step 4: Create commit-discipline.md**

- Header: `# Commit Discipline` with note: `Used by: implement.md, spec-executor agent`
- Commit message format and conventions
- When to commit (after each task, after verification)
- What to include in commits
- Branch naming conventions

**Step 5: Verify and commit**

```bash
wc -l plugins/ralph-specum/references/verification-layers.md plugins/ralph-specum/references/phase-rules.md plugins/ralph-specum/references/commit-discipline.md
git add plugins/ralph-specum/references/
git commit -m "feat(ralph-specum): extract verification, phase rules, and commit discipline references"
```

---

### Task 7: Extract start.md references (intent, scanner, branches)

**Files:**
- Create: `plugins/ralph-specum/references/intent-classification.md`
- Create: `plugins/ralph-specum/references/spec-scanner.md`
- Create: `plugins/ralph-specum/references/branch-management.md`
- Read: `plugins/ralph-specum/commands/start.md`

**Step 1: Read start.md fully**

Identify:
- Intent classification logic (how it determines if user wants new spec, resume, quick mode)
- Spec scanner logic (how it discovers and matches existing specs)
- Branch management logic (branch creation, naming, worktree setup)

**Step 2: Create intent-classification.md**

- Header: `# Intent Classification` with note: `Used by: start.md`
- Goal type detection from user input
- Keywords and patterns for each intent type
- Routing logic (which command to invoke based on intent)

**Step 3: Create spec-scanner.md**

- Header: `# Spec Scanner` with note: `Used by: start.md, switch.md`
- How to scan `./specs/` directory for existing specs
- How to match user input to existing spec names
- Validation rules for spec directories
- `.current-spec` file management

**Step 4: Create branch-management.md**

- Header: `# Branch Management` with note: `Used by: start.md, implement.md`
- Branch naming conventions
- Worktree setup instructions
- When to create new branches vs use existing

**Step 5: Verify and commit**

```bash
wc -l plugins/ralph-specum/references/intent-classification.md plugins/ralph-specum/references/spec-scanner.md plugins/ralph-specum/references/branch-management.md
git add plugins/ralph-specum/references/
git commit -m "feat(ralph-specum): extract intent classification, spec scanner, and branch management references"
```

---

### Task 8: Extract remaining references (research, quality)

**Files:**
- Create: `plugins/ralph-specum/references/parallel-research.md`
- Create: `plugins/ralph-specum/references/quality-checkpoints.md`
- Create: `plugins/ralph-specum/references/quality-commands.md`
- Read: `plugins/ralph-specum/commands/research.md`
- Read: `plugins/ralph-specum/agents/task-planner.md`
- Read: `plugins/ralph-specum/agents/spec-executor.md`

**Step 1: Read source files**

Identify:
- Parallel research dispatch pattern from research.md
- Quality checkpoint insertion rules from task-planner.md
- Quality command discovery from spec-executor.md

**Step 2: Create parallel-research.md**

- Header: `# Parallel Research` with note: `Used by: research.md`
- How to split research goal into topics
- How to dispatch multiple research-analyst agents in parallel via Task tool
- How to merge results from parallel agents
- Topic deduplication logic

**Step 3: Create quality-checkpoints.md**

- Header: `# Quality Checkpoints` with note: `Used by: task-planner agent`
- Rules for inserting [VERIFY] tasks
- Frequency (every 2-3 tasks)
- What each checkpoint should verify
- Checkpoint task format

**Step 4: Create quality-commands.md**

- Header: `# Quality Commands` with note: `Used by: spec-executor agent`
- How to discover available test/lint/build commands
- Package.json script discovery
- Makefile target discovery
- Fallback strategies when no config found

**Step 5: Verify and commit**

```bash
wc -l plugins/ralph-specum/references/parallel-research.md plugins/ralph-specum/references/quality-checkpoints.md plugins/ralph-specum/references/quality-commands.md
ls plugins/ralph-specum/references/ | wc -l
```
Expected: 11 reference files total.

```bash
git add plugins/ralph-specum/references/
git commit -m "feat(ralph-specum): extract parallel research and quality references"
```

---

### Task 9: Slim down implement.md to thin orchestrator

**Files:**
- Modify: `plugins/ralph-specum/commands/implement.md`

**Step 1: Read current implement.md (1557 lines)**

Understand the full structure. Identify which sections map to which reference files.

**Step 2: Rewrite implement.md as a thin orchestrator**

The rewritten implement.md should:
- Keep the frontmatter unchanged
- Keep the top-level structure (heading, purpose, prerequisites)
- Replace inline procedural logic with Read references:
  ```markdown
  ## Coordinator Logic
  Read `${CLAUDE_PLUGIN_ROOT}/references/coordinator-pattern.md` and follow the task delegation pattern.
  ```
- Add a checklist section (Phase C1):
  ```markdown
  ## Checklist
  Create a task for each item and complete in order:
  1. Validate prerequisites — check spec exists, tasks.md present
  2. Initialize state — write .ralph-state.json
  3. Execute task loop — delegate tasks via coordinator pattern
  4. Handle completion — output ALL_TASKS_COMPLETE
  ```
- Target: ~250 lines

**Step 3: Verify the rewritten file**

Run:
```bash
wc -l plugins/ralph-specum/commands/implement.md
```
Expected: Under 300 lines.

Verify all reference paths are correct:
```bash
grep 'CLAUDE_PLUGIN_ROOT.*references' plugins/ralph-specum/commands/implement.md
```
Expected: References to coordinator-pattern.md, failure-recovery.md, verification-layers.md, phase-rules.md, commit-discipline.md.

**Step 4: Commit**

```bash
git add plugins/ralph-specum/commands/implement.md
git commit -m "refactor(ralph-specum): slim implement.md to thin orchestrator with reference reads"
```

---

### Task 10: Slim down start.md to thin orchestrator

**Files:**
- Modify: `plugins/ralph-specum/commands/start.md`

**Step 1: Read current start.md (1552 lines)**

**Step 2: Rewrite start.md as thin orchestrator**

- Replace intent classification logic with Read reference
- Replace spec scanning logic with Read reference
- Replace branch management logic with Read reference
- Add checklist section
- Target: ~300 lines

**Step 3: Verify under 350 lines, reference paths correct**

**Step 4: Commit**

```bash
git add plugins/ralph-specum/commands/start.md
git commit -m "refactor(ralph-specum): slim start.md to thin orchestrator with reference reads"
```

---

### Task 11: Slim down index.md to thin orchestrator

**Files:**
- Modify: `plugins/ralph-specum/commands/index.md`

**Step 1: Read current index.md (1388 lines)**

**Step 2: Rewrite as thin orchestrator (~250 lines)**

Index.md handles codebase indexing. Extract any reusable scanning/cataloging logic that overlaps with existing references, or create new reference files if needed. Add checklist.

**Step 3: Verify under 300 lines**

**Step 4: Commit**

```bash
git add plugins/ralph-specum/commands/index.md
git commit -m "refactor(ralph-specum): slim index.md to thin orchestrator"
```

---

### Task 12: Slim down remaining phase commands

**Files:**
- Modify: `plugins/ralph-specum/commands/research.md` (672 → ~150 lines)
- Modify: `plugins/ralph-specum/commands/requirements.md` (480 → ~150 lines)
- Modify: `plugins/ralph-specum/commands/design.md` (508 → ~150 lines)
- Modify: `plugins/ralph-specum/commands/tasks.md` (510 → ~150 lines)
- Modify: `plugins/ralph-specum/commands/refactor.md` (333 → ~150 lines)

**Step 1: Read each file**

Identify procedural logic that belongs in references vs orchestration logic that stays.

**Step 2: Rewrite each as thin orchestrator**

For each command:
- Keep frontmatter and purpose
- Replace inline procedural logic with Read references where applicable
- Add checklist section for Phase C1
- Target: ~150 lines each

**Step 3: Verify all under 200 lines**

```bash
wc -l plugins/ralph-specum/commands/research.md plugins/ralph-specum/commands/requirements.md plugins/ralph-specum/commands/design.md plugins/ralph-specum/commands/tasks.md plugins/ralph-specum/commands/refactor.md
```

**Step 4: Commit**

```bash
git add plugins/ralph-specum/commands/research.md plugins/ralph-specum/commands/requirements.md plugins/ralph-specum/commands/design.md plugins/ralph-specum/commands/tasks.md plugins/ralph-specum/commands/refactor.md
git commit -m "refactor(ralph-specum): slim phase commands to thin orchestrators"
```

---

## Phase C: Task/Team Patterns

### Task 13: Create subagent dispatch templates

**Files:**
- Create: `plugins/ralph-specum/templates/prompts/executor-prompt.md`
- Create: `plugins/ralph-specum/templates/prompts/reviewer-prompt.md`
- Create: `plugins/ralph-specum/templates/prompts/research-prompt.md`

**Step 1: Read spec-executor.md and spec-reviewer.md agents**

Understand the current agent capabilities and how they're invoked from commands.

**Step 2: Create executor-prompt.md**

Template for dispatching spec-executor via Task tool:

```markdown
# Executor Dispatch Template

> Used by: implement.md coordinator
> Placeholders: {SPEC_NAME}, {TASK_TEXT}, {TASK_INDEX}, {CONTEXT}

## Task Tool Parameters

- **subagent_type:** `ralph-specum:spec-executor`
- **description:** `Execute task {TASK_INDEX} for {SPEC_NAME}`
- **prompt:** (below)

---

You are executing task {TASK_INDEX} for spec `{SPEC_NAME}`.

## Task
{TASK_TEXT}

## Context
{CONTEXT}

## Instructions
1. Read the full task description
2. Implement exactly what is specified
3. Verify your implementation works
4. Commit changes with descriptive message
5. Output TASK_COMPLETE when done
```

**Step 3: Create reviewer-prompt.md**

Template for dispatching spec-reviewer for post-task validation:

```markdown
# Reviewer Dispatch Template

> Used by: implement.md coordinator (sequential review pattern)
> Placeholders: {SPEC_NAME}, {TASK_TEXT}, {IMPLEMENTER_REPORT}

## Task Tool Parameters

- **subagent_type:** `ralph-specum:spec-reviewer`
- **description:** `Review task completion for {SPEC_NAME}`
- **prompt:** (below)

---

Review whether the implementation matches the task specification.

## What Was Requested
{TASK_TEXT}

## What Implementer Reports
{IMPLEMENTER_REPORT}

## CRITICAL: Do Not Trust the Report
Verify independently:
1. Read the changed files
2. Check the actual behavior matches spec
3. Run any relevant tests

Output REVIEW_PASS or REVIEW_FAIL with explanation.
```

**Step 4: Create research-prompt.md**

Template for dispatching research-analyst agents in parallel:

```markdown
# Research Dispatch Template

> Used by: research.md
> Placeholders: {SPEC_NAME}, {GOAL}, {TOPIC}, {EXISTING_SPECS}

## Task Tool Parameters

- **subagent_type:** `ralph-specum:research-analyst`
- **description:** `Research {TOPIC} for {SPEC_NAME}`
- **prompt:** (below)

---

Research the topic "{TOPIC}" in the context of goal: {GOAL}

## Existing Specs
{EXISTING_SPECS}

## Instructions
1. Search the codebase for related patterns
2. Search the web for relevant documentation
3. Identify risks and dependencies
4. Return structured findings
```

**Step 5: Verify templates exist**

```bash
ls -la plugins/ralph-specum/templates/prompts/
```
Expected: 3 template files.

**Step 6: Commit**

```bash
git add plugins/ralph-specum/templates/prompts/
git commit -m "feat(ralph-specum): add subagent dispatch templates for executor, reviewer, and research"
```

---

### Task 14: Add sequential review pattern to implement coordinator

**Files:**
- Modify: `plugins/ralph-specum/commands/implement.md`
- Modify: `plugins/ralph-specum/references/coordinator-pattern.md`

**Step 1: Read the current coordinator-pattern.md reference**

**Step 2: Add review step to coordinator pattern**

After the executor dispatch completes with `TASK_COMPLETE`, add:

```markdown
## Sequential Review (skip if --quick mode)

After executor reports TASK_COMPLETE:

1. Read `${CLAUDE_PLUGIN_ROOT}/templates/prompts/reviewer-prompt.md`
2. Fill placeholders with current task text and executor's report
3. Dispatch reviewer via Task tool
4. If REVIEW_PASS: advance to next task
5. If REVIEW_FAIL: re-dispatch executor with reviewer feedback (max 2 retries)
```

**Step 3: Update implement.md to reference the review pattern**

Add `--quick` mode flag handling that skips review:
```markdown
## Quick Mode

If `--quick` flag is present in arguments, skip the sequential review step after each task.
```

**Step 4: Verify**

```bash
grep -c 'REVIEW_PASS\|REVIEW_FAIL\|reviewer' plugins/ralph-specum/references/coordinator-pattern.md
```
Expected: Multiple matches showing review logic is present.

**Step 5: Commit**

```bash
git add plugins/ralph-specum/commands/implement.md plugins/ralph-specum/references/coordinator-pattern.md
git commit -m "feat(ralph-specum): add sequential review pattern to coordinator"
```

---

### Task 15: Final version bump, validation, and PR

**Files:**
- Modify: `plugins/ralph-specum/.claude-plugin/plugin.json` (if not already bumped sufficiently)

**Step 1: Run validation checks**

```bash
# Check all agents have color
echo "=== Agent colors ==="
for f in plugins/ralph-specum/agents/*.md plugins/ralph-speckit/agents/*.md; do
  name=$(basename "$f")
  color=$(grep -m1 '^color:' "$f" | awk '{print $2}')
  echo "$name: ${color:-MISSING}"
done

# Check all skills have version
echo "=== Skill versions ==="
for f in plugins/ralph-specum/skills/*/SKILL.md plugins/ralph-speckit/skills/*/SKILL.md; do
  name=$(basename "$(dirname "$f")")
  version=$(grep -m1 '^version:' "$f" | awk '{print $2}')
  echo "$name: ${version:-MISSING}"
done

# Check command sizes
echo "=== Command sizes ==="
wc -l plugins/ralph-specum/commands/implement.md plugins/ralph-specum/commands/start.md plugins/ralph-specum/commands/index.md

# Check reference count
echo "=== References ==="
ls plugins/ralph-specum/references/ | wc -l

# Check template count
echo "=== Templates ==="
ls plugins/ralph-specum/templates/prompts/ | wc -l

# Check no new skills
echo "=== Skills count ==="
ls -d plugins/ralph-specum/skills/*/SKILL.md | wc -l
```

Expected:
- 0 agents with MISSING color
- 0 skills with MISSING version
- implement.md, start.md, index.md each under 300 lines
- 11 reference files
- 3 template files
- 6 skills (unchanged)

**Step 2: Commit any final fixes**

**Step 3: Create PR**

```bash
gh pr create --title "refactor(plugins): apply plugin-dev best practices v2" --body "$(cat <<'EOF'
## Summary

Fresh approach replacing stale PR #79. Applies plugin-dev best practices to both plugins:

- **Phase A: Metadata** — Added `color` to 14 agents, `version` to 10 skills, examples to feedback.md
- **Phase B: Reference extraction** — Extracted procedural logic from bloated commands (implement.md 1557→~250 lines) into 11 internal reference files in `references/` directory
- **Phase C: Task/team patterns** — Added checklists for TaskCreate progress tracking, subagent dispatch templates, sequential review pattern

### Key design decisions
- **References over skills**: Extracted logic lives in `references/` (not `skills/`) to avoid bloating the `/` namespace. Loaded via Read tool on-demand.
- **Thin orchestrators**: Commands became ~70-80% smaller by referencing shared logic
- **Sequential review**: Post-task review step (skippable via `--quick`)

## Design Doc
See `docs/plans/2026-02-20-plugin-best-practices-design.md`

## Test Plan
- [ ] All 14 agents have `color` field
- [ ] All 10 skills have `version` field
- [ ] implement.md, start.md, index.md each under 300 lines
- [ ] 11 reference files exist in `references/`
- [ ] 3 dispatch templates exist in `templates/prompts/`
- [ ] No new entries in `/` skill namespace (still 6 ralph-specum skills)
- [ ] Plugin loads correctly with `claude --plugin-dir ./plugins/ralph-specum`

🤖 Generated with [Claude Code](https://claude.ai/code)
EOF
)"
```
