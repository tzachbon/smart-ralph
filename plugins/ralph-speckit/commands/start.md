---
description: Smart entry point for new features with auto ID and branch management
argument-hint: <feature-name> [goal]
allowed-tools: [Read, Write, Edit, Task, Bash]
---

# Start Feature

Smart entry point for ralph-speckit. Checks constitution, auto-generates feature ID, creates branch, initializes state.

## Constitution Check (FIRST)

Before any feature work, constitution must exist.

```bash
# Check if constitution exists
if [ ! -f ".specify/memory/constitution.md" ]; then
  echo "CONSTITUTION_MISSING"
else
  echo "CONSTITUTION_EXISTS"
fi
```

If CONSTITUTION_MISSING:
1. Output: "No constitution found. Run /speckit:constitution first to establish project principles."
2. STOP - do not continue

## Parse Arguments

From `$ARGUMENTS`, extract:
- **feature-name**: Required, kebab-case name for the feature
- **goal**: Optional description of what the feature should accomplish

Examples:
- `/speckit:start user-auth` - Create feature named user-auth
- `/speckit:start user-auth Add OAuth2 support` - Create with goal

If no feature-name provided:
1. Output: "Usage: /speckit:start <feature-name> [goal]"
2. Output: "Example: /speckit:start user-auth Add OAuth2 support"
3. STOP

Validate feature-name is kebab-case:
- Only lowercase letters, numbers, hyphens
- Must start with letter
- Regex: `^[a-z][a-z0-9-]*$`

If invalid:
1. Output: "Invalid feature name. Use kebab-case (e.g., user-auth, api-v2)"
2. STOP

## Auto-Generate Feature ID

Scan `.specify/specs/` for existing feature directories and find highest ID.

```bash
# Find highest existing feature ID
HIGHEST_ID=0
if [ -d ".specify/specs" ]; then
  for dir in .specify/specs/*/; do
    if [ -d "$dir" ]; then
      dirname=$(basename "$dir")
      # Extract numeric prefix (first 3 chars)
      prefix="${dirname:0:3}"
      if [[ "$prefix" =~ ^[0-9]+$ ]]; then
        num=$((10#$prefix))
        if [ $num -gt $HIGHEST_ID ]; then
          HIGHEST_ID=$num
        fi
      fi
    fi
  done
fi

# Next ID is highest + 1
NEXT_ID=$((HIGHEST_ID + 1))

# Format as 3-digit zero-padded
FEATURE_ID=$(printf "%03d" $NEXT_ID)
echo "FEATURE_ID: $FEATURE_ID"
```

The feature ID follows format `001`, `002`, `003`, etc.

Full feature name: `$FEATURE_ID-$feature-name` (e.g., `001-user-auth`)

## Branch Management

### Step 1: Check Current Branch

```bash
git branch --show-current
```

### Step 2: Determine Default Branch

```bash
# Try to get default branch from origin
DEFAULT=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

# Fallback to checking main/master
if [ -z "$DEFAULT" ]; then
  git rev-parse --verify origin/main 2>/dev/null && DEFAULT="main" || DEFAULT="master"
fi

echo "DEFAULT_BRANCH: $DEFAULT"
```

### Step 3: Branch Decision

If on default branch (main/master):
1. Generate branch name: `$FEATURE_ID-$feature-name` (e.g., `001-user-auth`)
2. Create and switch: `git checkout -b $FEATURE_ID-$feature-name`
3. Output: "Created branch '$FEATURE_ID-$feature-name'"

If on non-default branch:
1. Stay on current branch
2. Output: "Using current branch: $current_branch"

## Create Feature Directory

```bash
# Ensure .specify/specs exists
mkdir -p ".specify/specs"

# Create feature directory
mkdir -p ".specify/specs/$FEATURE_ID-$feature-name"
```

## Initialize State File

Write `.specify/specs/$FEATURE_ID-$feature-name/.speckit-state.json`:

```json
{
  "featureId": "$FEATURE_ID",
  "name": "$feature-name",
  "basePath": ".specify/specs/$FEATURE_ID-$feature-name",
  "phase": "specify",
  "taskIndex": 0,
  "totalTasks": 0,
  "taskIteration": 1,
  "maxTaskIterations": 5,
  "globalIteration": 1,
  "maxGlobalIterations": 100,
  "awaitingApproval": false
}
```

## Update Current Feature Pointer

```bash
echo "$FEATURE_ID-$feature-name" > .specify/.current-feature
```

## Initialize Progress File

Create `.specify/specs/$FEATURE_ID-$feature-name/.progress.md`:

```markdown
# Progress: $FEATURE_ID-$feature-name

## Original Goal

$goal (or "Not specified" if no goal provided)

## Current Phase

specify

## Completed Tasks

(none yet)

## Current Task

Awaiting specification

## Learnings

(none yet)

## Blockers

(none)
```

## Ensure Gitignore Entries

Add state files to .gitignore if not present:

```bash
if [ -f .gitignore ]; then
  grep -q ".specify/.current-feature" .gitignore || echo ".specify/.current-feature" >> .gitignore
  grep -q "\*\*/\.progress\.md" .gitignore || echo "**/.progress.md" >> .gitignore
  grep -q "\*\*/\.speckit-state\.json" .gitignore || echo "**/.speckit-state.json" >> .gitignore
else
  cat > .gitignore << 'EOF'
.specify/.current-feature
**/.progress.md
**/.speckit-state.json
EOF
fi
```

## Output

```text
Feature '$FEATURE_ID-$feature-name' created

Location: .specify/specs/$FEATURE_ID-$feature-name/
Branch: $branch-name
Phase: specify

Next: Run /speckit:specify to define what this feature should do.
```

## Error Handling

| Error | Action |
|-------|--------|
| No constitution | Guide to /speckit:constitution |
| No feature name | Show usage |
| Invalid feature name | Show kebab-case requirement |
| Branch exists | Append -2, -3 suffix |
| Directory exists | Error, suggest different name |

## Feature ID Collision Handling

If feature directory already exists with same name (different ID):
1. Check for `*-$feature-name` in .specify/specs/
2. If found: error "Feature '$feature-name' already exists at .specify/specs/$existing/"
3. Suggest: "Use a different name or resume with /speckit:switch $existing"

If same ID-name combo exists (race condition):
1. Increment ID and retry
2. Output: "ID collision detected, using $new_id"
