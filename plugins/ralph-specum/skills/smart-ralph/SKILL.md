---
name: smart-ralph
version: 0.1.0
description: This skill should be used when the user asks about "ralph arguments", "quick mode", "commit spec", "max iterations", "ralph state file", "execution modes", "ralph loop integration", or needs guidance on common Ralph plugin arguments and state management patterns.
---

# Smart Ralph

Core skill for all Ralph plugins. Defines common arguments, execution modes, and shared behaviors.

## Common Arguments

All Ralph commands support these standard arguments:

| Argument | Short | Description | Default |
|----------|-------|-------------|---------|
| `--quick` | `-q` | Skip interactive phases, auto-generate artifacts, start execution immediately | false |
| `--commit` | `-c` | Commit and push spec/feature files after generation | true (normal), false (quick) |
| `--no-commit` | | Explicitly disable committing files | - |
| `--max-task-iterations` | `-m` | Max retries per failed task before stopping | 5 |
| `--fresh` | `-f` | Force new spec/feature, overwrite if exists | false |

## Argument Parsing Rules

```text
Priority Order (highest to lowest):
1. --no-commit (explicit disable)
2. --commit (explicit enable)
3. --quick mode default (false)
4. Normal mode default (true)
```

### Parsing Logic

```text
commitSpec = true  // default

if "--no-commit" in args:
  commitSpec = false
else if "--commit" in args:
  commitSpec = true
else if "--quick" in args:
  commitSpec = false  // quick mode defaults to no commit
// else keep default (true)
```

## Execution Modes

### Normal Mode (Interactive)

- User reviews artifacts between phases
- Phase transitions require explicit commands
- Each phase sets `awaitingApproval: true`
- Commits spec files by default

### Quick Mode (`--quick`)

- Skips all interactive prompts and interviews
- Auto-generates all artifacts in sequence
- Immediately starts execution after generation
- Does NOT commit by default (use `--commit` to override)
- Still delegates to subagents (delegation is mandatory)

## State File

All Ralph plugins use `.ralph-state.json` for execution state. See `references/state-file-schema.md` for full schema.

Key fields: `phase`, `taskIndex`, `totalTasks`, `taskIteration`, `maxTaskIterations`, `awaitingApproval`.

## Commit Behavior

When `commitSpec` is true:

1. Stage spec/feature files after generation
2. Commit with message: `chore(<plugin>): commit spec files before implementation`
3. Push to current branch

When `commitSpec` is false:

- Files remain uncommitted
- User can manually commit later

## Ralph Loop Integration

All Ralph plugins use Ralph Wiggum loop for task execution. See `references/ralph-loop-integration.md` for details.

Key signals:
- `TASK_COMPLETE` - executor finished task
- `ALL_TASKS_COMPLETE` - coordinator ends loop

## Error Handling

When `taskIteration > maxTaskIterations`: block task, suggest manual intervention.

If state file missing/invalid: output error, suggest re-running implement command.

## Branch Management

All Ralph plugins follow consistent branch strategy:

1. Check current branch before starting
2. If on default branch (main/master): prompt for branch strategy
3. If on feature branch: offer to continue or create new
4. Quick mode: auto-create branch, no prompts
