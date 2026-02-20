---
description: Start task execution loop
argument-hint: [--max-task-iterations 5] [--max-global-iterations 100] [--recovery-mode]
allowed-tools: [Read, Write, Edit, Task, Bash, Skill]
---

# Start Execution

You are starting the task execution loop.

## Checklist

Create a task for each item and complete in order:

1. **Validate prerequisites** -- check spec and tasks.md exist
2. **Parse arguments** -- extract flags and options
3. **Initialize state** -- write .ralph-state.json
4. **Execute task loop** -- delegate tasks via coordinator pattern
5. **Handle completion** -- cleanup and output ALL_TASKS_COMPLETE

## Step 1: Determine Active Spec and Validate

**Multi-Directory Resolution**: This command uses the path resolver for dynamic spec path resolution.
- `ralph_resolve_current()` -- resolves .current-spec to full path (bare name = ./specs/$name, full path = as-is)
- `ralph_find_spec(name)` -- find spec by name across all configured roots

**Configuration**: Specs directories are configured in `.claude/ralph-specum.local.md`:
```yaml
specs_dirs: ["./specs", "./packages/api/specs", "./packages/web/specs"]
```

**Resolve**:
1. If `$ARGUMENTS` contains a spec name, use `ralph_find_spec()` to resolve it
2. Otherwise, use `ralph_resolve_current()` to get the active spec path
3. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."

**Validate**:
1. Check the resolved spec directory exists
2. Check the spec's tasks.md exists. If not: error "Tasks not found. Run /ralph-specum:tasks first."

## Step 2: Parse Arguments

From `$ARGUMENTS`:
- **--max-task-iterations**: Max retries per task (default: 5)
- **--max-global-iterations**: Max total loop iterations (default: 100). Safety limit to prevent infinite execution loops.
- **--recovery-mode**: Enable iterative failure recovery (default: false). When enabled, failed tasks trigger automatic fix task generation instead of stopping.

## Step 3: Initialize Execution State

1. Count total tasks in tasks.md (lines matching `- [ ]` or `- [x]`)
2. Count already completed tasks (lines matching `- [x]`)
3. Set taskIndex to first incomplete task

**CRITICAL: Merge into existing state -- do NOT overwrite the file.**

Read the existing `.ralph-state.json` first, then **merge** the execution fields into it.
This preserves fields set by earlier phases (e.g., `source`, `name`, `basePath`, `commitSpec`, `relatedSpecs`).

Update `.ralph-state.json` by merging these fields into the existing object:
```json
{
  "phase": "execution",
  "taskIndex": "<first incomplete>",
  "totalTasks": "<count>",
  "taskIteration": 1,
  "maxTaskIterations": "<parsed from --max-task-iterations or default 5>",
  "recoveryMode": "<true if --recovery-mode flag present, false otherwise>",
  "maxFixTasksPerOriginal": 3,
  "maxFixTaskDepth": 3,
  "globalIteration": 1,
  "maxGlobalIterations": "<parsed from --max-global-iterations or default 100>",
  "fixTaskMap": {},
  "modificationMap": {},
  "maxModificationsPerTask": 3,
  "maxModificationDepth": 2,
  "awaitingApproval": false
}
```

Use a jq merge pattern to preserve existing fields:
```bash
jq --argjson taskIndex <first_incomplete> \
   --argjson totalTasks <count> \
   --argjson maxTaskIter <parsed or 5> \
   --argjson recoveryMode <true|false> \
   --argjson maxGlobalIter <parsed or 100> \
   '
   . + {
     phase: "execution",
     taskIndex: $taskIndex,
     totalTasks: $totalTasks,
     taskIteration: 1,
     maxTaskIterations: $maxTaskIter,
     recoveryMode: $recoveryMode,
     maxFixTasksPerOriginal: 3,
     maxFixTaskDepth: 3,
     globalIteration: 1,
     maxGlobalIterations: $maxGlobalIter,
     fixTaskMap: {},
     modificationMap: {},
     maxModificationsPerTask: 3,
     maxModificationDepth: 2,
     awaitingApproval: false
   }
   ' "$SPEC_PATH/.ralph-state.json" > "$SPEC_PATH/.ralph-state.json.tmp" && \
   mv "$SPEC_PATH/.ralph-state.json.tmp" "$SPEC_PATH/.ralph-state.json"
```

**Preserved fields** (set by earlier phases, must NOT be removed):
- `source`, `name`, `basePath`, `commitSpec`, `relatedSpecs`

**Backwards Compatibility**: State files from earlier versions may lack new fields. The system handles missing fields gracefully with defaults (globalIteration: 1, maxGlobalIterations: 100, maxFixTaskDepth: 3, modificationMap: {}, maxModificationsPerTask: 3, maxModificationDepth: 2).

## Step 4: Execute Task Loop

After writing the state file, output the coordinator prompt below. This starts the execution loop.
The stop-hook will continue the loop by blocking stops and prompting the coordinator to check state.

### Coordinator Prompt

Output this prompt directly to start execution:

```text
You are the execution COORDINATOR for spec: $spec
```

Then Read and follow these references in order. They contain the complete coordinator logic:

1. **Core delegation pattern**: Read `${CLAUDE_PLUGIN_ROOT}/references/coordinator-pattern.md` and follow it.
   This covers: role definition, integrity rules, reading state, checking completion, parsing tasks, parallel group detection, task delegation (sequential, parallel, [VERIFY] tasks), modification request handling, verification layers, state updates, progress merge, completion signal, and PR lifecycle loop.

2. **Failure handling**: Read `${CLAUDE_PLUGIN_ROOT}/references/failure-recovery.md` and follow it.
   This covers: parsing failure output, fix task generation, fix task limits and depth checks, iterative recovery orchestrator, fix task insertion into tasks.md, fixTaskMap state tracking, and progress logging for fix chains.

3. **Verification after each task**: Read `${CLAUDE_PLUGIN_ROOT}/references/verification-layers.md` and follow it.
   This covers: 5 layers (contradiction detection, uncommitted spec files, checkmark verification, TASK_COMPLETE signal, artifact review via spec-reviewer). All must pass before advancing.

4. **Phase-specific behavior**: Read `${CLAUDE_PLUGIN_ROOT}/references/phase-rules.md` and follow it.
   This covers: POC-first workflow (Phase 1-4), phase distribution, quality checkpoints, and phase-specific constraints.

5. **Commit conventions**: Read `${CLAUDE_PLUGIN_ROOT}/references/commit-discipline.md` and follow it.
   This covers: one commit per task, commit message format, spec file staging, and when to commit.

### Key Coordinator Behaviors (quick reference — see coordinator-pattern.md for authoritative details)

- **You are a COORDINATOR, not an implementer.** Delegate via Task tool. Never implement yourself.
- **Fully autonomous.** Never ask questions or wait for user input.
- **State-driven loop.** Read .ralph-state.json each iteration to determine current task.
- **Completion check.** If taskIndex >= totalTasks, verify all [x] marks, delete state file, output ALL_TASKS_COMPLETE.
- **Task delegation.** Extract full task block from tasks.md, delegate to spec-executor (or qa-engineer for [VERIFY] tasks).
- **After TASK_COMPLETE.** Run all 5 verification layers, then update state (advance taskIndex, reset taskIteration). In normal mode (not --quick), each completed task goes through a sequential review step before advancing. See coordinator-pattern.md for details.
- **On failure.** Parse failure output, increment taskIteration. If recovery-mode: generate fix task. If max retries exceeded: error and stop.
- **Modification requests.** If TASK_MODIFICATION_REQUEST in output, process SPLIT_TASK / ADD_PREREQUISITE / ADD_FOLLOWUP per coordinator-pattern.md.

### Error States (never output ALL_TASKS_COMPLETE)

- Missing/corrupt state file: error and suggest re-running /ralph-specum:implement
- Missing tasks.md: error and suggest running /ralph-specum:tasks
- Missing spec directory: error and suggest running /ralph-specum:new
- Max retries exceeded: error with failure details, suggest manual fix then resume
- Max fix task depth/count exceeded (recovery mode): error with fix history

## Step 5: Completion

When all tasks complete (taskIndex >= totalTasks):
1. Verify all tasks marked [x] in tasks.md
2. Delete .ralph-state.json
3. Keep .progress.md (preserve learnings and history)
4. Cleanup orphaned temp progress files: `find "$SPEC_PATH" -name ".progress-task-*.md" -mmin +60 -delete 2>/dev/null || true`
5. Update spec index: `./plugins/ralph-specum/hooks/scripts/update-spec-index.sh --quiet`
6. Commit remaining spec changes:
   ```bash
   git add "$SPEC_PATH/tasks.md" "$SPEC_PATH/.progress.md" ./specs/.index/
   git diff --cached --quiet || git commit -m "chore(spec): final progress update for $spec"
   ```
7. Check for PR link: `gh pr view --json url -q .url 2>/dev/null`
8. Output: ALL_TASKS_COMPLETE (and PR link if exists)

## Output on Start

```text
Starting execution for '$spec'

Tasks: $completed/$total completed
Starting from task $taskIndex

The execution loop will:
- Execute one task at a time
- Continue until all tasks complete or max iterations reached

Beginning execution...
```
