---
description: Start implementation from approved tasks. Executes tasks autonomously following POC-first workflow.
argument-hint: [phase-number] [--dir ./spec-dir]
---

# Implement Tasks

Execute tasks from approved spec autonomously.

## Parse Arguments

From `$ARGUMENTS`, extract:
- **phase**: Phase number to execute (optional, default: current incomplete phase)
- **dir**: Spec directory path (default: `./spec`)

## Context Check

1. Verify `.ralph-state.json` exists
2. Verify all phases approved (requirements, design, tasks)
3. Read current progress from `.ralph-progress.md`

## Current State

Read tasks.md and show:
- Phase overview
- Incomplete tasks
- Current task index

## Execution Rules

<mandatory>
Execute tasks autonomously with NO human interaction:
1. Read the **Do** section - execute exactly as specified
2. Modify only the **Files** listed
3. Check **Done when** criteria is met
4. Run the **Verify** command - must pass before moving on
5. **Commit** using the message from the task's Commit line
6. Mark task complete in .ralph-progress.md
</mandatory>

## Phase-Specific Rules

### Phase 1 (POC)
- Goal: Working prototype
- Skip tests, accept hardcoded values
- Only type check must pass
- Move fast, validate idea

### Phase 2 (Refactoring)
- POC must be validated first
- Clean up code, add error handling
- Type check must pass

### Phase 3 (Testing)
- Write tests as specified in tasks
- All tests must pass before proceeding

### Phase 4 (Quality Gates)
- All local checks must pass before pushing
- Create PR, verify CI green
- Merge only after CI passes

## Execution Loop

For each task in the specified phase:

```
1. Read task details from tasks.md
   ↓
2. Execute Do steps exactly
   ↓
3. Check Done when criteria
   ↓
4. Run Verify command
   ↓
5. If Verify fails → fix and retry
   ↓
6. If Verify passes → commit changes
   ↓
7. Update .ralph-progress.md:
   - Mark task [x]
   - Add learnings
   ↓
8. Update .ralph-state.json:
   - Increment taskIndex
   ↓
9. Output: TASK_COMPLETE: <task_number>
   ↓
10. Move to next task
```

## Commit Discipline

- Each task = one commit
- Commit AFTER verify passes
- Use exact commit message from task
- Never commit failing code

## Error Handling

If a task fails:
1. Document the error in .ralph-progress.md Learnings
2. Attempt to fix if straightforward
3. If blocked, add to Blockers section
4. Do not skip to next task without resolution

## Completion

When all tasks in phase complete:
1. Verify phase quality gate passed
2. If more phases remain, continue to next
3. When all phases done, output: `RALPH_COMPLETE`

## Usage Examples

```bash
# Execute current incomplete phase
/ralph-specum:implement

# Execute specific phase
/ralph-specum:implement 2

# Execute from specific directory
/ralph-specum:implement --dir ./my-spec
```

Start implementing now!
