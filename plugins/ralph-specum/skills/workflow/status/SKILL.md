---
name: ralph:status
description: Show status of all specs — phase, progress, and available workflow commands
---

# Spec Status

## Overview

The status skill gives you a snapshot of all specs in your project: what phase each is in, how many tasks are complete, which artifact files exist, and what to do next.

It reads the spec directory structure and state files -- no external services or tool-specific APIs required. Any AI coding tool can run this skill by reading files and listing directories.

### What It Shows

For each spec found:

- **Phase**: Which workflow phase it is in (research, requirements, design, tasks, execution, or completed).
- **Progress**: How many tasks are checked off vs total (e.g., `12/20 tasks`).
- **Files**: Which artifacts exist (`research.md`, `requirements.md`, `design.md`, `tasks.md`).
- **Active**: Whether this is the currently active spec (per `.current-spec`).

It also shows the next recommended action for the active spec.

---

## Steps

### 1. Find the Active Spec

Read the `.current-spec` file to determine which spec is active:

```bash
SPECS_DIR="./specs"

if [ -f "$SPECS_DIR/.current-spec" ]; then
  CURRENT_SPEC=$(cat "$SPECS_DIR/.current-spec")
else
  CURRENT_SPEC=""
fi
```

The value may be a bare name (e.g., `my-feature`) for the default directory or a full path (e.g., `./packages/api/specs/my-feature`) for non-default directories.

### 2. List All Spec Directories

Enumerate all spec directories. Each subdirectory of the specs root that contains at least one artifact file or a `.ralph-state.json` is a spec:

```bash
SPECS_DIR="./specs"

for SPEC_PATH in "$SPECS_DIR"/*/; do
  SPEC_NAME=$(basename "$SPEC_PATH")
  # Skip hidden directories and index
  [ "$SPEC_NAME" = ".index" ] && continue
  [[ "$SPEC_NAME" == .* ]] && continue
  echo "$SPEC_NAME -> $SPEC_PATH"
done
```

If your project uses multiple spec roots (e.g., `./specs`, `./packages/api/specs`), iterate over each root.

### 3. Check Each Spec's Status

For each spec directory, gather:

**a. Phase detection**

```bash
SPEC_PATH="./specs/<name>"

if [ -f "$SPEC_PATH/.ralph-state.json" ]; then
  PHASE=$(jq -r '.phase' "$SPEC_PATH/.ralph-state.json")
  TASK_INDEX=$(jq -r '.taskIndex' "$SPEC_PATH/.ralph-state.json")
  TOTAL_TASKS=$(jq -r '.totalTasks' "$SPEC_PATH/.ralph-state.json")
else
  # Infer phase from which files exist
  if [ -f "$SPEC_PATH/tasks.md" ]; then
    PHASE="tasks (complete)"
  elif [ -f "$SPEC_PATH/design.md" ]; then
    PHASE="design (complete)"
  elif [ -f "$SPEC_PATH/requirements.md" ]; then
    PHASE="requirements (complete)"
  elif [ -f "$SPEC_PATH/research.md" ]; then
    PHASE="research (complete)"
  else
    PHASE="not started"
  fi
  TASK_INDEX=0
  TOTAL_TASKS=0
fi
```

**b. File existence check**

```bash
SPEC_PATH="./specs/<name>"

for FILE in research.md requirements.md design.md tasks.md; do
  if [ -f "$SPEC_PATH/$FILE" ]; then
    echo "[x] ${FILE%.md}"
  else
    echo "[ ] ${FILE%.md}"
  fi
done
```

**c. Task progress (if tasks.md exists)**

```bash
SPEC_PATH="./specs/<name>"

if [ -f "$SPEC_PATH/tasks.md" ]; then
  COMPLETED=$(grep -c '^\- \[x\]' "$SPEC_PATH/tasks.md" 2>/dev/null || echo 0)
  REMAINING=$(grep -c '^\- \[ \]' "$SPEC_PATH/tasks.md" 2>/dev/null || echo 0)
  TOTAL=$((COMPLETED + REMAINING))
  echo "Progress: $COMPLETED/$TOTAL tasks"
fi
```

### 4. Format Output

Present status grouped by spec, with the active spec marked:

```
# Ralph Spec Status

Active spec: <name> (or "none")

## <spec-name-1> [ACTIVE]
Phase: execution
Progress: 12/20 tasks (60%)
Files: [x] research [x] requirements [x] design [x] tasks

## <spec-name-2>
Phase: design (complete)
Progress: 0/0 tasks
Files: [x] research [x] requirements [x] design [ ] tasks

## <spec-name-3>
Phase: research (complete)
Progress: 0/0 tasks
Files: [x] research [ ] requirements [ ] design [ ] tasks
```

### 5. Show Next Recommended Action

Based on the active spec's phase, suggest the next command:

| Current Phase | Next Action |
|--------------|-------------|
| not started | Run the **start** skill to create a new spec |
| research | Run the **research** skill |
| research (complete) | Run the **requirements** skill |
| requirements (complete) | Run the **design** skill |
| design (complete) | Run the **tasks** skill |
| tasks (complete) | Run the **implement** skill |
| execution | Continue the **implement** skill (tasks in progress) |
| All tasks done | Spec complete -- no further action needed |

```
Next: Run the requirements skill to generate user stories and acceptance criteria.
```

---

## Advanced

### Multiple Spec Roots

If your project has specs in multiple directories (e.g., monorepo with per-package specs), iterate over each configured root:

```bash
# Example roots (configure per project)
SPEC_ROOTS=("./specs" "./packages/api/specs" "./packages/web/specs")

for ROOT in "${SPEC_ROOTS[@]}"; do
  [ -d "$ROOT" ] || continue
  echo "## $ROOT"
  for SPEC_PATH in "$ROOT"/*/; do
    SPEC_NAME=$(basename "$SPEC_PATH")
    [[ "$SPEC_NAME" == .* ]] && continue
    [ "$SPEC_NAME" = ".index" ] && continue
    # ... gather status per spec (same as step 3)
  done
done
```

Specs in non-default directories show their root path as a suffix:

```
## api-auth [packages/api/specs]
Phase: design
Files: [x] research [x] requirements [x] design [ ] tasks
```

### Related Specs

If `.ralph-state.json` contains a `relatedSpecs` array, show related specs with their relevance:

```bash
SPEC_PATH="./specs/<name>"

if jq -e '.relatedSpecs' "$SPEC_PATH/.ralph-state.json" > /dev/null 2>&1; then
  jq -r '.relatedSpecs[] | "\(.name) (\(.relevance))"' "$SPEC_PATH/.ralph-state.json"
fi
```

Display:
```
Related: auth-system (HIGH), api-middleware (MEDIUM)
```

### Phase Display Reference

| State File Phase | Display |
|-----------------|---------|
| `research` | Research |
| `requirements` | Requirements |
| `design` | Design |
| `tasks` | Tasks |
| `execution` | Executing (with task progress) |
| No state file | Inferred from existing artifact files |

### No Specs Found

If no spec directories exist:

```
# Ralph Spec Status

No specs found.

To get started, run the start skill with a name and goal:
  ralph:start my-feature Build a user authentication system
```
