---
description: Switch active feature
argument-hint: <feature-name>
allowed-tools: [Read, Write, Bash, Glob, Task]
---

# Switch Active Feature

You are switching the active feature.

## Parse Arguments

From `$ARGUMENTS`:
- **name**: The feature name to switch to (required)

## Validate

1. If no name provided, list available features and ask user to choose
2. Check if `.specify/specs/$name/` exists (supports both `###-name` and plain `name` matching)
3. If not, error: "Feature '$name' not found. Available features: <list>"

## List Available (if no argument)

If `$ARGUMENTS` is empty:

1. List all directories in `.specify/specs/`
2. Read current active feature from `.specify/.current-feature`
3. Show list with current marked

```text
Available features:
- 001-user-auth [ACTIVE]
- 002-payment-flow
- 003-dashboard

Run: /speckit:switch <feature-name>
```

## Execute Switch

1. Find matching feature directory (exact match or partial match on name portion):
   ```bash
   # Check for exact match first
   if [ -d ".specify/specs/$name" ]; then
     FEATURE="$name"
   else
     # Try matching by name suffix (e.g., "user-auth" matches "001-user-auth")
     FEATURE=$(ls -1 .specify/specs/ 2>/dev/null | grep -E "^[0-9]{3}-$name$" | head -1)
   fi
   ```

2. Update `.specify/.current-feature`:
   ```bash
   echo "$FEATURE" > .specify/.current-feature
   ```

3. Read the feature's state:
   - `.speckit-state.json` for phase and progress
   - `.progress.md` for context

## Output

```text
Switched to feature: $FEATURE

Current phase: <phase>
Progress: <taskIndex>/<totalTasks> tasks

Files present:
- [x/blank] spec.md
- [x/blank] plan.md
- [x/blank] tasks.md
- [x/blank] .progress.md

Next: Run /speckit:<appropriate-phase> to continue
```
