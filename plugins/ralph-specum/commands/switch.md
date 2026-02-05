---
description: Switch active spec
argument-hint: <spec-name-or-path>
allowed-tools: [Read, Write, Bash, Glob, Task]
---

# Switch Active Spec

You are switching the active specification.

## Multi-Directory Resolution

This command uses the path resolver for multi-root spec discovery:

```bash
# Source the path resolver (conceptual - commands use these patterns)
# ralph_find_spec(name)   - Find spec by name across all roots
# ralph_list_specs()      - List all specs as "name|path" pairs
# ralph_resolve_current() - Get current spec's full path
```

## Parse Arguments

From `$ARGUMENTS`:
- **input**: The spec name OR full path to switch to (required for switching)
  - If starts with `./` or `/`: treat as full path
  - Otherwise: treat as spec name to search for

## Validate

1. If no input provided, list available specs and ask user to choose
2. If input is a full path (starts with `./`):
   - Check if path exists as directory
   - If not, error: "Spec path '$input' not found"
3. If input is a spec name:
   - Use `ralph_find_spec()` pattern to search all configured specs_dirs
   - Exit code 0 (found unique): proceed with switch
   - Exit code 1 (not found): error with list of searched directories
   - Exit code 2 (ambiguous): show disambiguation prompt

## List Available (if no argument)

If `$ARGUMENTS` is empty:

1. Use `ralph_list_specs()` pattern to gather all specs from all roots
2. Read current active spec using `ralph_resolve_current()` pattern
3. Group specs by their root directory with numbered options
4. Show list with current marked and directory context
5. If no specs found, guide user to create one

**With specs found:**

```
Available specs:

./specs (default):
  1. feature-a [ACTIVE]
  2. feature-b

./packages/api/specs:
  3. api-auth
  4. api-users

./packages/web/specs:
  5. web-login

Examples:
  /ralph-specum:switch feature-b
  /ralph-specum:switch api-auth
  /ralph-specum:switch ./packages/api/specs/api-auth  (full path for disambiguation)
```

**No specs found:**

```
No specs found in configured directories.

Searched:
  - ./specs (default)
  - ./packages/api/specs
  - ./packages/web/specs

To create a new spec:
  /ralph-specum:new my-feature
  /ralph-specum:new my-feature --specs-dir ./packages/api/specs
```

## Handle Disambiguation

If spec name exists in multiple roots (exit code 2 from find):

```
Multiple specs named 'api-auth' found:

1. ./specs/api-auth
   Location: default specs directory
   Run: /ralph-specum:switch ./specs/api-auth

2. ./packages/api/specs/api-auth
   Location: packages/api
   Run: /ralph-specum:switch ./packages/api/specs/api-auth

Select by running the command for your desired spec.
```

Do NOT automatically select one. User must specify the full path with the exact command shown.

## Handle Not Found

If spec name does not exist (exit code 1 from find):

```
No spec named 'my-feature' found.

Searched directories:
  - ./specs (default)
  - ./packages/api/specs
  - ./packages/web/specs

To see available specs: /ralph-specum:switch
To create a new spec: /ralph-specum:new my-feature
```

List all configured specs_dirs that were searched, helping user understand where to create the spec.

## Execute Switch

1. Determine the full path:
   - If input was a full path: use as-is
   - If input was a name with single match: use the resolved path

2. Update `./specs/.current-spec`:
   - For specs in default `./specs/` root: write bare name (backward compat)
   - For specs in other roots: write full path

   ```bash
   # Example for default root:
   echo "my-feature" > ./specs/.current-spec

   # Example for non-default root:
   echo "./packages/api/specs/api-auth" > ./specs/.current-spec
   ```

3. Read the spec's state:
   - `.ralph-state.json` for phase and progress
   - `.progress.md` for context

## Output

```
Switched to spec: $name

Location: $full_path
Current phase: <phase>
Progress: <taskIndex>/<totalTasks> tasks

Files present:
- [x/blank] research.md
- [x/blank] requirements.md
- [x/blank] design.md
- [x/blank] tasks.md

Next: Run /ralph-specum:<appropriate-phase> to continue
```
