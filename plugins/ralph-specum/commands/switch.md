---
description: Switch active spec
argument-hint: <spec-name>
allowed-tools: [Read, Write, Bash, Glob, Task]
---

# Switch Active Spec

You are switching the active specification.

## Parse Arguments

From `$ARGUMENTS`:
- **name**: The spec name to switch to (required)

## Validate

1. If no name provided, list available specs and ask user to choose
2. Check if `./specs/$name/` exists
3. If not, error: "Spec '$name' not found. Available specs: <list>"

## List Available (if no argument)

If `$ARGUMENTS` is empty:

1. List all directories in `./specs/`
2. Read current active spec from `./specs/.current-spec`
3. Show list with current marked

```
Available specs:
- feature-a [ACTIVE]
- feature-b
- feature-c

Run: /ralph-specum:switch <spec-name>
```

## Execute Switch

1. Update `./specs/.current-spec`:
   ```bash
   echo "$name" > ./specs/.current-spec
   ```

2. Read the spec's state:
   - `.ralph-state.json` for phase and progress
   - `.progress.md` for context

## Output

```
Switched to spec: $name

Current phase: <phase>
Progress: <taskIndex>/<totalTasks> tasks

Files present:
- [x/blank] research.md
- [x/blank] requirements.md
- [x/blank] design.md
- [x/blank] tasks.md

Next: Run /ralph-specum:<appropriate-phase> to continue
```
