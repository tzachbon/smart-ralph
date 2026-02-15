---
name: ralph:cancel
description: Cancel active spec execution — delete state files and optionally remove spec directory
---

# Cancel Spec Execution

## Overview

The cancel skill stops an active spec execution and cleans up state files. It can also permanently remove the entire spec directory if requested.

Two levels of cancellation:

1. **Cancel execution only** (default): Deletes `.ralph-state.json`, which stops the execution loop. All spec artifacts (research.md, requirements.md, design.md, tasks.md, .progress.md) are preserved. You can resume later by running the start skill again.
2. **Remove spec entirely** (`--remove`): Deletes the entire spec directory and all its contents. This is irreversible.

This skill is tool-agnostic -- it works by deleting files and clearing markers. No tool-specific APIs required.

---

## Steps

### 1. Determine Target Spec

Identify which spec to cancel. Accept an optional spec name or path as input.

```bash
SPECS_DIR="./specs"

# If a name or path was provided:
if [ -n "$INPUT" ]; then
  case "$INPUT" in
    ./*|/*) SPEC_PATH="$INPUT" ;;         # Full path provided
    *)      SPEC_PATH="$SPECS_DIR/$INPUT"  # Bare name provided
  esac
else
  # No input: use the active spec
  if [ -f "$SPECS_DIR/.current-spec" ]; then
    CURRENT=$(cat "$SPECS_DIR/.current-spec")
    case "$CURRENT" in
      ./*|/*) SPEC_PATH="$CURRENT" ;;
      *)      SPEC_PATH="$SPECS_DIR/$CURRENT" ;;
    esac
  else
    echo "No active spec found. Nothing to cancel."
    exit 0
  fi
fi

SPEC_NAME=$(basename "$SPEC_PATH")
```

If the spec directory does not exist, report that there is nothing to cancel:

```
No spec found at: $SPEC_PATH
Nothing to cancel.
```

### 2. Show Current State Before Cancellation

If `.ralph-state.json` exists, read and display the current state so the user knows what they are canceling:

```bash
if [ -f "$SPEC_PATH/.ralph-state.json" ]; then
  PHASE=$(jq -r '.phase' "$SPEC_PATH/.ralph-state.json")
  TASK_INDEX=$(jq -r '.taskIndex' "$SPEC_PATH/.ralph-state.json")
  TOTAL_TASKS=$(jq -r '.totalTasks' "$SPEC_PATH/.ralph-state.json")
  ITERATION=$(jq -r '.globalIteration' "$SPEC_PATH/.ralph-state.json")

  echo "Canceling spec: $SPEC_NAME"
  echo "Phase: $PHASE"
  echo "Progress: $TASK_INDEX/$TOTAL_TASKS tasks"
  echo "Iterations: $ITERATION"
else
  echo "No active execution loop for spec: $SPEC_NAME"
  echo "(No .ralph-state.json found)"
fi
```

### 3. Delete State File

Remove the execution state file. This stops any execution loop (hook-based or manual):

```bash
rm -f "$SPEC_PATH/.ralph-state.json"
```

Once `.ralph-state.json` is deleted:
- Hook-based execution loops (stop hooks, event hooks) will detect its absence and stop.
- Manual re-invocations of the implement skill will see no state file and report nothing to execute.

### 4. Clear the Active Spec Marker

If the canceled spec is the currently active spec, clear the marker:

```bash
SPECS_DIR="./specs"

if [ -f "$SPECS_DIR/.current-spec" ]; then
  CURRENT=$(cat "$SPECS_DIR/.current-spec")
  # Match by name or full path
  if [ "$CURRENT" = "$SPEC_NAME" ] || [ "$CURRENT" = "$SPEC_PATH" ]; then
    rm -f "$SPECS_DIR/.current-spec"
  fi
fi
```

### 5. Report Cancellation

```
Canceled: $SPEC_NAME

State before cancellation:
- Phase: <phase>
- Progress: <taskIndex>/<totalTasks> tasks
- Iterations: <iteration>

Cleanup:
- [x] Removed .ralph-state.json (execution stopped)
- [x] Cleared active spec marker

Spec artifacts preserved at: $SPEC_PATH
To resume later, run the start skill with the same spec name.
```

---

## Advanced

### Remove Entire Spec (`--remove`)

To permanently delete the spec directory and all artifacts, pass `--remove`:

**WARNING: This is irreversible. All spec artifacts (research.md, requirements.md, design.md, tasks.md, .progress.md) will be permanently deleted.**

```bash
# Only after confirming with the user or when --remove is explicitly requested
rm -rf "$SPEC_PATH"
rm -f "$SPECS_DIR/.current-spec"
```

Before removing, list what will be deleted:

```bash
echo "The following will be permanently deleted:"
ls -la "$SPEC_PATH/"
echo ""
echo "This action is irreversible."
```

After removal:

```
Canceled and removed: $SPEC_NAME

Cleanup:
- [x] Removed .ralph-state.json
- [x] Removed spec directory ($SPEC_PATH)
- [x] Cleared active spec marker

All spec files have been permanently deleted.

To start a new spec:
  ralph:start <name> <goal>
```

**Always warn the user before removing a spec directory.** If not explicitly requested via `--remove`, only delete `.ralph-state.json` and preserve the spec artifacts.

### Multiple Spec Roots

If the spec name exists in multiple directories (e.g., monorepo):

```bash
SPEC_ROOTS=("./specs" "./packages/api/specs" "./packages/web/specs")
MATCHES=()

for ROOT in "${SPEC_ROOTS[@]}"; do
  if [ -d "$ROOT/$SPEC_NAME" ]; then
    MATCHES+=("$ROOT/$SPEC_NAME")
  fi
done

if [ ${#MATCHES[@]} -gt 1 ]; then
  echo "Multiple specs named '$SPEC_NAME' found:"
  for i in "${!MATCHES[@]}"; do
    echo "  $((i+1)). ${MATCHES[$i]}"
  done
  echo ""
  echo "Specify the full path to cancel a specific one:"
  echo "  ralph:cancel ${MATCHES[0]}"
  exit 1
fi
```

Do not automatically select one -- require the user to specify the full path when there is ambiguity.

### Cancel Without Active Execution

If `.ralph-state.json` does not exist but the spec directory does, the cancel skill still clears the active spec marker and (with `--remove`) deletes the directory:

```
No active execution loop found for spec: $SPEC_NAME
Spec artifacts remain at: $SPEC_PATH

Cleanup:
- [x] Cleared active spec marker

To remove the spec entirely, use: ralph:cancel <name> --remove
```

### What Gets Preserved vs Deleted

| File | Cancel (default) | Cancel --remove |
|------|-----------------|-----------------|
| `.ralph-state.json` | Deleted | Deleted |
| `.current-spec` marker | Cleared (if matches) | Cleared |
| `research.md` | Preserved | Deleted |
| `requirements.md` | Preserved | Deleted |
| `design.md` | Preserved | Deleted |
| `tasks.md` | Preserved | Deleted |
| `.progress.md` | Preserved | Deleted |

### Resuming After Cancel

After a default cancel (execution only), all artifacts remain. To resume:

1. Run the start skill with the same spec name.
2. It will detect the existing spec directory and resume from the last known phase.
3. If tasks were partially completed, the implement skill will pick up from the last unchecked task.

The `.progress.md` file preserves learnings and completed task history, so context is not lost even after cancellation.
