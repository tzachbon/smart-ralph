---
description: Start task execution loop
argument-hint: [--max-task-iterations 5]
allowed-tools: [Read, Write, Edit, Task, Bash]
---

# Start Execution

You are starting the task execution loop. Running this command implicitly approves the tasks phase.

<mandatory>
## CRITICAL: Delegation Requirement

**YOU ARE A COORDINATOR, NOT AN IMPLEMENTER.**

You MUST delegate ALL task execution to the `spec-executor` subagent. This is NON-NEGOTIABLE.

**NEVER do any of these yourself:**
- Execute task steps from tasks.md
- Write code or modify source files
- Run verification commands as part of task execution
- Commit task changes directly
- "Help" by doing any part of a task yourself

**Your ONLY responsibilities are:**
1. Read state files to determine current task
2. Invoke `spec-executor` subagent via Task tool with full context
3. Report completion status to user

Even if a task seems simple, you MUST delegate to `spec-executor`. No exceptions.
</mandatory>

<mandatory>
## Fully Autonomous = End-to-End Validation

This is a FULLY AUTONOMOUS process. That means doing everything a human would do to verify a feature works - not just writing code.

**What "complete" really means:**
- Code is written ✓
- Code compiles ✓
- Tests pass ✓
- **AND the feature is verified working in the real environment** ✓

**Example: PostHog analytics integration**
A human would:
1. Write the integration code
2. Build the project
3. Load extension in real browser
4. Perform user actions
5. **Check PostHog dashboard to confirm events arrived**
6. Only THEN call it complete

**The agent MUST do the same:**
- Use MCP browser tools to spawn real browsers
- Use WebFetch/curl to hit real APIs
- Verify external systems actually received the data
- Never mark complete based only on "code compiles"

**If a task cannot be verified end-to-end with available tools, it should have been designed differently in task-planner. Do not mark it complete - let it fail and block.**
</mandatory>

## Determine Active Spec

1. Read `./specs/.current-spec` to get active spec
2. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."

## Parse Arguments

From `$ARGUMENTS`:
- **--max-task-iterations**: Max retries per task (default: 5)

## Validate

1. Check `./specs/$spec/` directory exists
2. Check `./specs/$spec/tasks.md` exists. If not, error: "Tasks not found. Run /ralph-specum:tasks first."
3. Read `.ralph-state.json`
4. Clear approval flag: update state with `awaitingApproval: false`

## Initialize Execution State

1. Count total tasks in tasks.md (lines matching `- [ ]` or `- [x]`)
2. Count already completed tasks (lines matching `- [x]`)
3. Set taskIndex to first incomplete task

Update `.ralph-state.json`:
```json
{
  "phase": "execution",
  "taskIndex": <first incomplete>,
  "totalTasks": <count>,
  "taskIteration": 1,
  "maxTaskIterations": 5,
  ...
}
```

## Commit Specs First (Before Any Implementation)

<mandatory>
**COMMIT SPECS BEFORE STARTING IMPLEMENTATION**

Before executing any tasks, commit all spec files. This ensures:
- Specs are version-controlled before any code changes
- Clear separation between spec definition and implementation
- Spec history is preserved even if implementation fails
</mandatory>

### Check If Specs Already Committed

Check if this is a fresh start (taskIndex == 0 after initialization) and specs haven't been committed yet:

```bash
# Check if any spec files are uncommitted or untracked
git status --porcelain ./specs/$spec/*.md ./specs/$spec/.progress.md 2>/dev/null | grep -q '.' && echo "uncommitted" || echo "clean"
```

### Commit Spec Files

If specs are uncommitted (new or modified), commit them:

```bash
# Stage all spec files
git add ./specs/$spec/research.md ./specs/$spec/requirements.md ./specs/$spec/design.md ./specs/$spec/tasks.md ./specs/$spec/.progress.md 2>/dev/null

# Commit with descriptive message
git commit -m "docs(spec): add spec for $spec

Spec artifacts:
- research.md: feasibility analysis and codebase exploration
- requirements.md: user stories and acceptance criteria
- design.md: architecture and technical decisions
- tasks.md: POC-first implementation plan

Ready for implementation."
```

If commit succeeds, output:
```
Committed spec files for '$spec'
```

If nothing to commit (specs already committed), continue silently.

## Read Context

Before executing:

1. Read `./specs/$spec/.progress.md` for:
   - Original goal
   - Completed tasks
   - Learnings
   - Blockers

2. Read `./specs/$spec/tasks.md` for current task

## Execute Current Task

<mandatory>
**DELEGATE TO SUBAGENT - DO NOT IMPLEMENT YOURSELF**

Use the Task tool with `subagent_type: spec-executor` to execute the current task.
Execute tasks autonomously with NO human interaction.

You MUST NOT:
- Read task steps and execute them yourself
- Make code changes directly
- Run the verification command yourself
- Commit changes yourself

You MUST:
- Pass ALL context to spec-executor via Task tool
- Let spec-executor handle the ENTIRE task lifecycle
</mandatory>

Find current task (by taskIndex) and invoke spec-executor with:

```
You are executing task for spec: $spec
Spec path: ./specs/$spec/
Task index: $taskIndex (0-based)

Context from .progress.md:
[include progress file content]

Current task from tasks.md:
[include the specific task block]

Your task:
1. Read the task's Do section and execute exactly
2. Only modify files listed in Files section
3. Verify completion with the Verify command
4. Commit with the task's Commit message
5. Update .progress.md:
   - Add task to Completed Tasks with commit hash
   - Add any learnings discovered
   - Update Current Task to next task
6. Mark task as [x] in tasks.md

After successful completion, output exactly:
TASK_COMPLETE

If verification fails, describe the issue and retry.
If task requires manual action, describe what's needed and DO NOT output TASK_COMPLETE.
```

## Task Completion Verification

**TASK_COMPLETE** - The ONLY valid completion signal
- Use when: Task steps executed, verification passed, changes committed
- Stop hook verifies: checkmarks updated, spec files committed, no contradictions

**NEVER use TASK_COMPLETE if:**
- Task requires manual action (block and describe what user needs to do)
- Verification failed
- Implementation is partial
- Changes not committed

## Stop Hook Verification Layers

The stop hook enforces completion integrity with 4 verification layers:

1. **Contradiction Detection**: Rejects TASK_COMPLETE if output contains phrases like "requires manual", "cannot be automated", "could not complete", etc. Agent cannot claim completion while admitting it didn't complete.
2. **Uncommitted Files Check**: Rejects completion if tasks.md or .progress.md have uncommitted changes. All spec files must be committed.
3. **Checkmark Verification**: Validates that task was marked [x] in tasks.md. Counts completed checkmarks and verifies against task index.
4. **Signal Verification**: Requires TASK_COMPLETE to advance to next task.

If any verification fails, the task retries with a specific error message explaining the violation.

## After Task Completes

The spec-executor will:
1. Execute the task
2. Run verification
3. Commit changes (including spec files)
4. Update progress
5. Output "TASK_COMPLETE"

The stop hook will then:
1. Run verification layers (see above)
2. If all pass: Increment taskIndex, reset taskIteration
3. Return block with continue prompt (fresh context)
4. OR allow stop if all tasks done

If task seems to require manual action:
1. NEVER mark complete, lie, or expect user input
2. Use available tools: Bash, WebFetch, MCP browser tools, CLI commands, Task subagents
3. Exhaust ALL automated options before concluding impossible
4. Document each tool attempted and why it didn't work
5. Only if truly impossible after trying all tools: do NOT output TASK_COMPLETE, let retry loop exhaust

## Completion

When all tasks are done:
1. Stop hook deletes `.ralph-state.json`
2. `.progress.md` remains as record
3. Session ends normally

## Output on Start

```
Starting execution for '$spec'

Tasks: $completed/$total completed
Starting from task $taskIndex

The execution loop will:
- Execute one task at a time
- Stop after each task for fresh context
- Continue until all tasks complete or max iterations reached

Beginning task $taskIndex...
```
