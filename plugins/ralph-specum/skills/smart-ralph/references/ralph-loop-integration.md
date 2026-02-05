# Ralph Loop Integration

Ralph Specum uses the Ralph Wiggum loop (ralph-loop) for autonomous task execution.

## Dependency

Install Ralph Loop plugin:
```bash
/plugin install ralph-wiggum@claude-plugins-official
```

## Invocation

```text
Skill: ralph-wiggum:ralph-loop
Args: Read <coordinator-prompt-path> and follow instructions.
      Output ALL_TASKS_COMPLETE when done.
      --max-iterations <calculated>
      --completion-promise ALL_TASKS_COMPLETE
```

## Coordinator Prompt File

Write coordinator prompt to file before invoking Ralph loop:
- Avoids shell argument parsing issues
- Enables complex multi-line prompts
- Path: `<spec-path>/.coordinator-prompt.md`

## Task Completion Signals

### Executor Signals

| Signal | Meaning |
|--------|---------|
| `TASK_COMPLETE` | Task finished successfully |
| `VERIFICATION_PASS` | Verification task passed |
| `VERIFICATION_FAIL` | Verification failed, needs retry |

### Coordinator Signals

| Signal | Meaning |
|--------|---------|
| `ALL_TASKS_COMPLETE` | All tasks done, end loop |

## Max Iterations Calculation

```
maxIterations = (totalTasks * maxTaskIterations) + buffer
```

Where:
- `totalTasks` from state file
- `maxTaskIterations` from args (default 5)
- `buffer` = 10 (overhead for coordinator turns)

## Error Scenarios

### Task Exceeds Max Retries

When `taskIteration > maxTaskIterations`:
1. Output error with task index and attempt count
2. Include last failure reason
3. Suggest manual intervention
4. Do NOT output ALL_TASKS_COMPLETE
5. Loop continues but task stays blocked

### State Corruption During Loop

1. Coordinator detects mismatch between taskIndex and checkmarks
2. Resets taskIndex to actual completed count
3. Logs "STATE MANIPULATION DETECTED"
4. Continues execution from correct position
