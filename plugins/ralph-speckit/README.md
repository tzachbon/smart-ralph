# Ralph Speckit

Spec-driven development plugin for Claude Code using the [GitHub spec-kit](https://github.com/github/spec-kit) methodology. Constitution-first approach with specify, plan, tasks, and implement phases.

## Features

- **Constitution-First Approach**: Establish project principles before any feature work
- **Autonomous Execution**: Ralph Wiggum integration for continuous task execution
- **Parallel Task Execution**: Tasks marked `[P]` run simultaneously
- **4-Layer Verification**: Contradiction detection, uncommitted files check, checkmark verification, and completion signals
- **QA Engineer Agent**: Specialized agent for `[VERIFY]` quality checkpoint tasks
- **State Persistence**: Progress tracked across sessions via `.speckit-state.json`
- **Auto Feature IDs**: Automatic feature numbering (001, 002, etc.)
- **Branch Management**: Auto-creates feature branches from default branch

## Prerequisites

- [Claude Code](https://claude.com/claude-code) installed and configured
- **Ralph Wiggum Plugin** (required for autonomous execution):
  ```bash
  /plugin install ralph-wiggum@claude-plugins-official
  ```

## Installation

```bash
# Install the plugin
/plugin install ralph-speckit@claude-plugins-official

# Or install from local directory
claude --plugin-dir /path/to/ralph-speckit
```

## Quick Start

5-minute example workflow:

```bash
# 1. Create project constitution (first-time setup)
/speckit:constitution Define principles for a web API project

# 2. Start a new feature
/speckit:start user-auth Add user authentication with JWT

# 3. Define what the feature should do
/speckit:specify

# 4. Create implementation plan
/speckit:plan

# 5. Generate task list
/speckit:tasks

# 6. Execute tasks autonomously
/speckit:implement
```

## Workflow

```
                    ┌─────────────────┐
                    │  constitution   │  Establish project principles
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │     start       │  Create feature + branch
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │    specify      │  Define user stories
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
     ┌────────▼────────┐     │     ┌────────▼────────┐
     │    clarify      │     │     │    checklist    │
     │   (optional)    │     │     │   (optional)    │
     └────────┬────────┘     │     └────────┬────────┘
              │              │              │
              └──────────────┼──────────────┘
                             │
                    ┌────────▼────────┐
                    │      plan       │  Technical design
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
     ┌────────▼────────┐     │     ┌────────▼────────┐
     │    analyze      │     │     │  taskstoissues  │
     │   (optional)    │     │     │   (optional)    │
     └────────┬────────┘     │     └────────┬────────┘
              │              │              │
              └──────────────┼──────────────┘
                             │
                    ┌────────▼────────┐
                    │     tasks       │  Generate task list
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │   implement     │  Execute via Ralph Wiggum
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │   COMPLETE      │
                    └─────────────────┘
```

## Command Reference

| Command | Description | Usage |
|---------|-------------|-------|
| `/speckit:constitution` | Create/update project principles | `/speckit:constitution [description]` |
| `/speckit:start` | Start new feature with auto-ID | `/speckit:start <name> [goal]` |
| `/speckit:specify` | Define feature specification | `/speckit:specify [description]` |
| `/speckit:clarify` | Clarify spec requirements | `/speckit:clarify [questions]` |
| `/speckit:checklist` | Generate quality checklist | `/speckit:checklist` |
| `/speckit:plan` | Create technical design | `/speckit:plan` |
| `/speckit:analyze` | Analyze implementation approach | `/speckit:analyze` |
| `/speckit:tasks` | Generate task list | `/speckit:tasks` |
| `/speckit:taskstoissues` | Convert tasks to GitHub issues | `/speckit:taskstoissues` |
| `/speckit:implement` | Execute tasks autonomously | `/speckit:implement [--max-task-iterations 5]` |
| `/speckit:status` | Show current feature status | `/speckit:status` |
| `/speckit:switch` | Switch active feature | `/speckit:switch <feature-id>` |
| `/speckit:cancel` | Cancel execution loop | `/speckit:cancel` |

## Directory Structure

After running speckit commands:

```
.specify/
├── .current-feature           # Active feature name
├── memory/
│   └── constitution.md        # Project constitution
├── specs/
│   └── 001-feature-name/
│       ├── spec.md            # Feature specification
│       ├── plan.md            # Technical design
│       ├── tasks.md           # Task list
│       ├── .speckit-state.json # Execution state (transient)
│       └── .progress.md       # Progress tracking (transient)
├── templates/                 # Spec file templates
└── scripts/                   # Helper scripts
```

## State Files

| File | Purpose | Git |
|------|---------|-----|
| `.specify/.current-feature` | Active feature pointer | ignored |
| `.speckit-state.json` | Execution state (phase, taskIndex, iterations) | ignored |
| `.progress.md` | Progress tracking, learnings, context | ignored |
| `spec.md`, `plan.md`, `tasks.md` | Feature specifications | committed |

The `.speckit-state.json` file is deleted on completion. The `.progress.md` file is preserved for learning history.

## Architecture

### Agents

| Agent | Purpose |
|-------|---------|
| `spec-executor` | Executes individual tasks, commits changes, outputs TASK_COMPLETE |
| `qa-engineer` | Handles `[VERIFY]` quality checkpoint tasks |

### Task Markers

- `[P]` - Parallel task (runs simultaneously with adjacent [P] tasks)
- `[VERIFY]` - Verification task (delegates to qa-engineer)
- No marker - Sequential task

### Verification Layers

The execution coordinator validates each task completion:

1. **Contradiction Detection**: Rejects claims of completion with failure phrases
2. **Uncommitted Files Check**: Ensures spec files are committed
3. **Checkmark Verification**: Validates checkmark count matches expected
4. **Completion Signal**: Requires explicit TASK_COMPLETE output

### Execution Protocol

- `spec-executor` outputs `TASK_COMPLETE` per task
- `qa-engineer` outputs `VERIFICATION_PASS` or `VERIFICATION_FAIL`
- Coordinator outputs `ALL_TASKS_COMPLETE` when done
- Failed tasks retry up to `maxTaskIterations` (default: 5)

## Troubleshooting

### "Ralph Wiggum plugin not found"

Install the required dependency:
```bash
/plugin install ralph-wiggum@claude-plugins-official
```

### "No constitution found"

Run constitution command first:
```bash
/speckit:constitution Define your project principles
```

### "No active feature"

Start a feature before implementing:
```bash
/speckit:start my-feature Description of feature
```

### "Tasks not found"

Generate tasks before implementing:
```bash
/speckit:tasks
```

### Task stuck in retry loop

1. Check `.progress.md` Learnings section for failure details
2. Fix the issue manually
3. Run `/speckit:implement` to resume

### State file corrupt

Delete and reinitialize:
```bash
rm .specify/specs/<feature>/.speckit-state.json
/speckit:implement
```

## Dependencies

This plugin requires the **Ralph Wiggum** plugin for autonomous execution loops.

Ralph Wiggum provides:
- `/ralph-loop:ralph-loop` - Continuous execution loop
- `/ralph-loop:cancel-ralph` - Cancel running loop

Without Ralph Wiggum, `/speckit:implement` will fail with an error.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.
