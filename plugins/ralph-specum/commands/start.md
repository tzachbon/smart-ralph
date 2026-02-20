---
description: Smart entry point that detects if you need a new spec or should resume existing
argument-hint: [name] [goal] [--fresh] [--quick] [--commit-spec] [--no-commit-spec] [--specs-dir <path>]
allowed-tools: "*"
---

# Start

Smart entry point for ralph-specum. Detects whether to create a new spec or resume an existing one.

## Branch Management (FIRST STEP)

<mandatory>
Before creating any files or directories, check the current git branch and handle appropriately.
</mandatory>

### Step 1: Check Current Branch

```bash
git branch --show-current
```

### Step 2: Determine Default Branch

Check which is the default branch:
```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
```

If that fails, assume `main` or `master` (check which exists):
```bash
git rev-parse --verify origin/main 2>/dev/null && echo "main" || echo "master"
```

### Step 3: Branch Decision Logic

```text
1. Get current branch name
   |
   +-- ON DEFAULT BRANCH (main/master):
   |   |
   |   +-- Ask user for branch strategy:
   |   |   "Starting new spec work. How would you like to handle branching?"
   |   |   1. Create branch in current directory (git checkout -b)
   |   |   2. Create git worktree (separate directory)
   |   |
   |   +-- If user chooses 1 (current directory):
   |   |   - Generate branch name from spec name: feat/$specName
   |   |   - If spec name not yet known, use temp name: feat/spec-work-<timestamp>
   |   |   - Create and switch: git checkout -b <branch-name>
   |   |   - Inform user: "Created branch '<branch-name>' for this work"
   |   |   - Suggest: "Run /ralph-specum:research to start the research phase."
   |   |
   |   +-- If user chooses 2 (worktree):
   |   |   - Generate branch name from spec name: feat/$specName
   |   |   - Determine worktree path: ../<repo-name>-<spec-name> or prompt user
   |   |   - Create worktree: git worktree add <path> -b <branch-name>
   |   |   - Inform user: "Created worktree at '<path>' on branch '<branch-name>'"
   |   |   - IMPORTANT: Suggest user to cd to worktree and resume conversation there:
   |   |     "For best results, cd to '<path>' and start a new Claude Code session from there."
   |   |     "Then run /ralph-specum:research to begin."
   |   |   - STOP HERE - do not continue to Parse Arguments (user needs to switch directories)
   |   |
   |   +-- Continue to Parse Arguments
   |
   +-- ON NON-DEFAULT BRANCH (feature branch):
       |
       +-- Ask user for preference:
       |   "You are currently on branch '<current-branch>'.
       |    Would you like to:
       |    1. Continue working on this branch
       |    2. Create a new branch in current directory
       |    3. Create git worktree (separate directory)"
       |
       +-- If user chooses 1 (continue):
       |   - Stay on current branch
       |   - Suggest: "Run /ralph-specum:research to start the research phase."
       |   - Continue to Parse Arguments
       |
       +-- If user chooses 2 (new branch):
       |   - Generate branch name from spec name: feat/$specName
       |   - If spec name not yet known, use temp name: feat/spec-work-<timestamp>
       |   - Create and switch: git checkout -b <branch-name>
       |   - Inform user: "Created branch '<branch-name>' for this work"
       |   - Suggest: "Run /ralph-specum:research to start the research phase."
       |   - Continue to Parse Arguments
       |
       +-- If user chooses 3 (worktree):
           - Generate branch name from spec name: feat/$specName
           - Determine worktree path: ../<repo-name>-<spec-name> or prompt user
           - Create worktree: git worktree add <path> -b <branch-name>
           - Inform user: "Created worktree at '<path>' on branch '<branch-name>'"
           - IMPORTANT: Suggest user to cd to worktree and resume conversation there:
             "For best results, cd to '<path>' and start a new Claude Code session from there."
             "Then run /ralph-specum:research to begin."
           - STOP HERE - do not continue to Parse Arguments (user needs to switch directories)
```

### Branch Naming Convention

When creating a new branch:
- Use format: `feat/<spec-name>` (e.g., `feat/user-auth`)
- If spec name contains special chars, sanitize to kebab-case
- If branch already exists, append `-2`, `-3`, etc.

Example:
```text
Spec name: user-auth
Branch: feat/user-auth

If feat/user-auth exists:
Branch: feat/user-auth-2
```

### Worktree Details

When user chooses worktree option:

**State files copied to worktree:**
- `$DEFAULT_SPECS_DIR/.current-spec` - Active spec name/path pointer
- `$SPEC_PATH/.ralph-state.json` - Loop state (phase, taskIndex, iterations)
- `$SPEC_PATH/.progress.md` - Progress tracking and learnings

**Note**: The spec may be in any configured specs_dir, not just `./specs/`. Use `ralph_resolve_current()` to get the full spec path.

These files are copied when:
1. The worktree is created via `git worktree add`
2. A spec is currently active (resolved via `ralph_resolve_current()`)
3. The source files exist in the main worktree

Copy uses non-overwrite semantics (skips if file already exists in target).

```bash
# Get repo name for path suggestion
REPO_NAME=$(basename $(git rev-parse --show-toplevel))

# Get default specs dir and resolve current spec path using path resolver
DEFAULT_SPECS_DIR=$(ralph_get_default_dir)  # e.g., "./specs"
SPEC_PATH=""
SPEC_NAME=""

# Resolve current spec (handles both bare names and full paths)
if SPEC_PATH=$(ralph_resolve_current 2>/dev/null); then
    SPEC_NAME=$(basename "$SPEC_PATH")
fi

# Default worktree path
WORKTREE_PATH="../${REPO_NAME}-${SPEC_NAME}"

# Create worktree with new branch
git worktree add "$WORKTREE_PATH" -b "feat/${SPEC_NAME}"

# Copy spec state files to worktree (failures are warnings, not errors)
# Note: Always copy .current-spec from default specs dir
if [ -d "$DEFAULT_SPECS_DIR" ]; then
    mkdir -p "$WORKTREE_PATH/$DEFAULT_SPECS_DIR" || echo "Warning: Failed to create specs directory in worktree"

    # Copy .current-spec if exists (don't overwrite existing)
    if [ -f "$DEFAULT_SPECS_DIR/.current-spec" ] && [ ! -f "$WORKTREE_PATH/$DEFAULT_SPECS_DIR/.current-spec" ]; then
        cp "$DEFAULT_SPECS_DIR/.current-spec" "$WORKTREE_PATH/$DEFAULT_SPECS_DIR/.current-spec" || echo "Warning: Failed to copy .current-spec to worktree"
    fi
fi

# If spec path resolved, copy spec state files from that path
# (may be in non-default specs dir like ./packages/api/specs/my-feature)
if [ -n "$SPEC_PATH" ] && [ -d "$SPEC_PATH" ]; then
    # Create parent directory structure in worktree
    SPEC_PARENT_DIR=$(dirname "$SPEC_PATH")
    mkdir -p "$WORKTREE_PATH/$SPEC_PARENT_DIR" || echo "Warning: Failed to create spec parent directory in worktree"
    mkdir -p "$WORKTREE_PATH/$SPEC_PATH" || echo "Warning: Failed to create spec directory in worktree"

    # Copy state files (don't overwrite existing)
    if [ -f "$SPEC_PATH/.ralph-state.json" ] && [ ! -f "$WORKTREE_PATH/$SPEC_PATH/.ralph-state.json" ]; then
        cp "$SPEC_PATH/.ralph-state.json" "$WORKTREE_PATH/$SPEC_PATH/" || echo "Warning: Failed to copy .ralph-state.json to worktree"
    fi

    if [ -f "$SPEC_PATH/.progress.md" ] && [ ! -f "$WORKTREE_PATH/$SPEC_PATH/.progress.md" ]; then
        cp "$SPEC_PATH/.progress.md" "$WORKTREE_PATH/$SPEC_PATH/" || echo "Warning: Failed to copy .progress.md to worktree"
    fi
fi
```

After worktree creation:
- Inform user of the worktree path
- IMPORTANT: Output clear guidance for the user:
  ```text
  Created worktree at '<path>' on branch '<branch-name>'
  Spec state files copied to worktree.

  For best results, cd to the worktree directory and start a new Claude Code session from there:

    cd <path>
    claude

  Then run /ralph-specum:research to begin the research phase.
  ```
- STOP the command here - do not continue to Parse Arguments or create spec files
- The user needs to switch directories first to work in the worktree
- To clean up later: `git worktree remove <path>`

### Quick Mode Branch Handling

In `--quick` mode, still perform branch check but skip the user prompt for non-default branches:
- If on default branch: auto-create feature branch in current directory (no worktree prompt in quick mode)
- If on non-default branch: stay on current branch (no prompt, quick mode is non-interactive)

## Quick Mode Execution

In quick mode (`--quick`), execution uses the self-contained stop-hook loop for autonomous task completion.

After generating spec artifacts in quick mode, the stop-hook automatically continues execution by delegating tasks to spec-executor until `ALL_TASKS_COMPLETE` is output.

<mandatory>
## CRITICAL: Delegation Requirement

**YOU ARE A COORDINATOR, NOT AN IMPLEMENTER.**

You MUST delegate ALL substantive work to subagents. This is NON-NEGOTIABLE regardless of mode (normal or quick).

**NEVER do any of these yourself:**
- Write code or modify source files
- Perform research or analysis
- Generate spec artifacts (research.md, requirements.md, design.md, tasks.md)
- Execute task steps
- Run verification commands as part of task execution

**ALWAYS delegate to the appropriate subagent:**
| Work Type | Subagent |
|-----------|----------|
| Research | Research Team (multiple parallel teammates) |
| Requirements | `product-manager` |
| Design | `architect-reviewer` |
| Task Planning | `task-planner` |
| Artifact Review | `spec-reviewer` |
| Task Execution | `spec-executor` |

Quick mode does NOT exempt you from delegation - it only skips interactive phases.
</mandatory>

<mandatory>
## CRITICAL: Stop After Each Subagent (Normal Mode)

In normal mode (no `--quick` flag), you MUST STOP your response after each subagent completes.

**After invoking a subagent via Task tool:**
1. Wait for subagent to return
2. Output a brief status message (e.g., "Research phase complete. Run /ralph-specum:requirements to continue.")
3. **END YOUR RESPONSE IMMEDIATELY**

**DO NOT:**
- Invoke another subagent in the same response
- Continue to the next phase automatically
- Ask if the user wants to continue

**The user must explicitly run the next command.** This gives them time to review artifacts.

Exception: `--quick` mode runs all phases without stopping.
</mandatory>


## Parse Arguments

From `$ARGUMENTS`, extract:
- **name**: Optional spec name (kebab-case)
- **goal**: Everything after the name except flags (optional)
- **--fresh**: Force new spec without prompting if one exists
- **--quick**: Skip all spec phases, auto-generate artifacts, start execution immediately
- **--commit-spec**: Commit and push spec files after generation (default: true in normal mode, false in quick mode)
- **--no-commit-spec**: Explicitly disable committing spec files
- **--specs-dir <path>**: Create spec in specified directory (must be in configured specs_dirs array)

### Multi-Directory Resolution

This command uses the path resolver for multi-directory support:

```bash
# Source path resolver (conceptually - commands don't execute bash directly)
# These functions are available via the path-resolver.sh helper:

ralph_get_specs_dirs()    # Returns all configured spec directories
ralph_get_default_dir()   # Returns first specs_dir (default for new specs)
ralph_find_spec(name)     # Find spec by name, returns full path
ralph_list_specs()        # List all specs as "name|path" pairs
ralph_resolve_current()   # Resolve .current-spec to full path
```

### --specs-dir Validation

When `--specs-dir` is provided:
1. Call `ralph_get_specs_dirs()` to get configured directories
2. Check if provided path matches one of the configured directories
3. If NOT in configured list: Error "Invalid --specs-dir: '$path' is not in configured specs_dirs"
4. If valid: Use this path as the spec root instead of default

```text
--specs-dir Validation Logic:

1. Extract --specs-dir value from $ARGUMENTS
2. Get configured dirs: dirs = ralph_get_specs_dirs()
3. Normalize paths (remove trailing slashes)
4. Check: specsDir in dirs?
   - YES: Use specsDir for spec creation
   - NO: Error "Invalid --specs-dir: '$specsDir' is not in configured specs_dirs. Configured: $dirs"
```

### Commit Spec Flag Logic

```text
1. Check if --no-commit-spec in $ARGUMENTS → commitSpec = false
2. Else if --commit-spec in $ARGUMENTS → commitSpec = true
3. Else if --quick in $ARGUMENTS → commitSpec = false (quick mode default)
4. Else → commitSpec = true (normal mode default)
```

### Spec Directory Resolution

```text
Spec Directory Logic:

1. Check if --specs-dir in $ARGUMENTS
   - YES: Validate against configured specs_dirs, use if valid
   - NO: Use ralph_get_default_dir() (first configured dir, defaults to ./specs)

2. Determine spec base path:
   specsDir = validated --specs-dir OR ralph_get_default_dir()
   basePath = "$specsDir/$name"

3. For .current-spec:
   - If specsDir == "./specs" (default): Write bare name
   - If specsDir != "./specs" (non-default): Write full path "$specsDir/$name"
```

Examples:
- `/ralph-specum:start` -> Auto-detect: resume active or ask for new
- `/ralph-specum:start user-auth` -> Resume or create user-auth
- `/ralph-specum:start user-auth Add OAuth2` -> Create user-auth with goal
- `/ralph-specum:start user-auth --fresh` -> Force new, overwrite if exists
- `/ralph-specum:start "Build auth with JWT" --quick` -> Quick mode with goal string
- `/ralph-specum:start my-feature "Add logging" --quick` -> Quick mode with name+goal
- `/ralph-specum:start ./my-plan.md --quick` -> Quick mode with file input
- `/ralph-specum:start my-feature ./plan.md --quick` -> Quick mode with name+file
- `/ralph-specum:start my-feature --quick` -> Quick mode using existing plan.md

## Quick Mode Flow

When `--quick` flag detected, bypass interactive spec phases and auto-generate all artifacts.

### Quick Mode Input Detection

Parse arguments before `--quick` flag and classify input type:

```text
Input Classification:

1. TWO ARGS before --quick:
   - First arg = spec name (must be kebab-case: ^[a-z0-9-]+$)
   - Second arg = goal string OR file path
   - Detect file path if: starts with "./" OR "/" OR ends with ".md"
   - Examples:
     - `my-feature "Add login" --quick` -> name=my-feature, goal="Add login"
     - `my-feature ./plan.md --quick` -> name=my-feature, file=./plan.md

2. ONE ARG before --quick:
   a. FILE PATH: starts with "./" OR "/" OR ends with ".md"
      - Read file content as plan
      - Infer name from plan content
      - Example: `./my-plan.md --quick` -> read file, infer name

   b. KEBAB-CASE NAME: matches ^[a-z0-9-]+$
      - Check if ./specs/$name/plan.md exists
      - If exists: use plan.md content, name=$name
      - If not exists: error "No plan.md found in ./specs/$name/. Provide goal: /ralph-specum:start $name 'your goal' --quick"
      - Example: `my-feature --quick` -> check ./specs/my-feature/plan.md

   c. GOAL STRING: anything else (contains spaces, uppercase, special chars)
      - Use as goal content
      - Infer name from goal
      - Example: `"Build auth with JWT" --quick` -> goal, infer name

3. ZERO ARGS with --quick:
   - Error: "Quick mode requires a goal or plan file"
```

### File Reading

When file path detected:
1. Validate file exists using Read tool
2. If not exists: error "File not found: $filePath"
3. Read file content
4. Strip frontmatter if present (content between --- markers at start)
5. If content empty after stripping: error "Plan content is empty. Provide a goal or non-empty file."
6. Use content as planContent

### Existing Plan Check

When kebab-case name provided without goal:
1. Use `ralph_find_spec(name)` to locate existing spec
2. If found: Check if `$specPath/plan.md` exists
   - If plan.md exists: read content, use as planContent
   - If plan.md not exists: error "No plan.md found in $specPath. Provide goal: /ralph-specum:start $name 'your goal' --quick"
3. If not found: error "Spec '$name' not found. Provide goal: /ralph-specum:start $name 'your goal' --quick"

### Name Inference

If no explicit name provided, infer from goal:

1. **Extract key terms**: Identify nouns and verbs from the goal
   - Skip common words: a, an, the, to, for, with, and, or, in, on, by, from, is, be, that
   - Prioritize: action verbs (add, build, create, fix, implement, update, remove, enable)
   - Then: descriptive nouns (auth, api, user, config, endpoint, handler)
2. **Build name**: Take up to 4 key terms, join with hyphens, convert to lowercase
3. **Normalize**: Strip unicode to ASCII, remove special characters except hyphens, collapse multiple hyphens
4. **Truncate**: Max 30 characters, truncate at word boundary (hyphen) when possible

Examples:
| Goal | Inferred Name |
|------|---------------|
| "Add user authentication with JWT" | add-user-authentication-jwt |
| "Build a REST API for products" | build-rest-api-products |
| "Fix the login bug where users can't reset password" | fix-login-bug-reset |
| "Implement rate limiting" | implement-rate-limiting |

### Quick Mode Execution

<mandatory>
**REMINDER: Even in quick mode, you MUST delegate ALL work to subagents.**
- Research → delegate to Research Team (parallel teammates)
- Requirements → delegate to `product-manager` via Task tool
- Design → delegate to `architect-reviewer` via Task tool
- Task planning → delegate to `task-planner` via Task tool
- Task execution → delegate to `spec-executor` via Task tool
- You only handle: directory creation, state file writes, and coordination
</mandatory>

```text
1. Validate input (non-empty goal/plan)
   |
2. Infer name from goal (if not provided)
   |
3. Determine spec directory using path resolver:
   specsDir = (--specs-dir value if provided and valid) OR ralph_get_default_dir()
   basePath = "$specsDir/$name"
   |
4. Create spec directory: mkdir -p "$basePath"
   |
4a. Ensure gitignore entries exist for spec state files:
   - Add specs/.current-spec to .gitignore if not present
   - Add **/.progress.md to .gitignore if not present
   |
5. Write .ralph-state.json (note: basePath uses resolved path):
   {
     "source": "plan",
     "name": "$name",
     "basePath": "$basePath",
     "phase": "research",
     "taskIndex": 0,
     "totalTasks": 0,
     "taskIteration": 1,
     "maxTaskIterations": 5,
     "globalIteration": 1,
     "maxGlobalIterations": 100,
     "commitSpec": $commitSpec,
     "quickMode": true
   }
   |
6. Write .progress.md with original goal
   |
7. Update .current-spec based on root directory:
   defaultDir = ralph_get_default_dir()
   if specsDir == defaultDir:
       echo "$name" > "$defaultDir/.current-spec"     # Bare name for default root
   else:
       echo "$basePath" > "$defaultDir/.current-spec" # Full path for non-default root
   |
8. Update Spec Index:
   ./plugins/ralph-specum/hooks/scripts/update-spec-index.sh --quiet
   |
9. Goal Type Detection:
   - Classify goal as "fix" or "add" using regex indicators:
     Fix: fix|resolve|debug|broken|failing|error|bug|crash|issue|not working
     Add: add|create|build|implement|new|enable|introduce (default)
   - For fix goals: run reproduction command, document BEFORE state in .progress.md
   |
10. Research Phase:
   - Run the SAME Team Research flow (steps 11a-11j from New Flow section)
   - Skip walkthrough (step 11k) and do NOT wait for user response
   - After research completes, explicitly clear awaitingApproval from state:
     Update .ralph-state.json: set awaitingApproval = false
   |
11. Requirements Phase:
   - Read $basePath/research.md for context
   - Delegate to product-manager via Task tool with Quick Mode Directive (see below)
   - After product-manager returns, run spec-reviewer review loop (max 3 iterations)
   - Clear awaitingApproval from state:
     Update .ralph-state.json: set awaitingApproval = false, phase = "requirements"
   |
12. Design Phase:
   - Read $basePath/research.md + $basePath/requirements.md for context
   - Delegate to architect-reviewer via Task tool with Quick Mode Directive (see below)
   - After architect-reviewer returns, run spec-reviewer review loop (max 3 iterations)
   - Clear awaitingApproval from state:
     Update .ralph-state.json: set awaitingApproval = false, phase = "design"
   |
13. Tasks Phase:
   - Read $basePath/requirements.md + $basePath/design.md for context
   - Delegate to task-planner via Task tool with Quick Mode Directive (see below)
   - After task-planner returns, run spec-reviewer review loop (max 3 iterations)
   |
14. Transition to Execution:
   - Count total tasks from tasks.md (number of `- [ ]` checkboxes)
   - Update .ralph-state.json: phase="execution", totalTasks=<count>, taskIndex=0
   - If commitSpec is true:
     - Stage spec files: git add $basePath/research.md $basePath/requirements.md $basePath/design.md $basePath/tasks.md
     - Commit: git commit -m "spec($name): add spec artifacts"
     - Push: git push -u origin $(git branch --show-current)
   |
15. Display brief summary:
   Quick mode: Created spec '$name' at $basePath
   [If commitSpec: "Spec committed and pushed."]
   Starting execution...
   |
16. Invoke spec-executor for task 1
```

### Quick Mode Directive

Each agent delegation in steps 11-13 includes this directive in the Task prompt:

```text
Quick Mode Context:
Running in quick mode with no user feedback. You MUST:
- Make strong, opinionated decisions instead of deferring to user
- Choose the simplest, most conventional approach
- Be more critical of your own output
- Prefer existing codebase patterns over novel approaches
- Keep scope tight - interpret the goal strictly, do not expand
- Add `generated: auto` to frontmatter of all artifacts you produce
```

### Quick Mode Review Loop (Per Artifact)

After each phase agent returns in steps 11-13, run spec-reviewer to validate the artifact:

```text
Set iteration = 1

WHILE iteration <= 3:
  1. Read the artifact content from $basePath/<artifact>.md
  2. Invoke spec-reviewer via Task tool:
     subagent_type: spec-reviewer
     Review the $artifactType artifact for spec: $name
     Spec path: $basePath/
     Review iteration: $iteration of 3
  3. Parse signal:
     - REVIEW_PASS: Proceed to next phase
     - REVIEW_FAIL (iteration < 3): Revise artifact, increment iteration
     - REVIEW_FAIL (iteration >= 3): Append warning to .progress.md, proceed
     - No signal: Treat as REVIEW_PASS (permissive)
```

### Quick Mode Validation

Before creating the spec, validate all inputs:

```text
Validation Sequence:

1. ZERO ARGS CHECK (if no args before --quick)
   - Error: "Quick mode requires a goal or plan file"

2. --specs-dir VALIDATION (if provided)
   - Get configured dirs via ralph_get_specs_dirs()
   - If --specs-dir value NOT in configured list:
     - Error: "Invalid --specs-dir: '$path' is not in configured specs_dirs"
   - If valid: Use as specsDir

3. FILE NOT FOUND (if file path detected)
   - If file not exists: "File not found: $filePath"

4. EMPTY CONTENT CHECK
   - If empty or whitespace only: "Plan content is empty. Provide a goal or non-empty file."

5. PLAN TOO SHORT WARNING (< 10 words)
   - If word count < 10: "Warning: Short plan may produce vague tasks"
   - Continue with warning displayed

6. NAME CONFLICT RESOLUTION
   - specsDir = validated --specs-dir OR ralph_get_default_dir()
   - If $specsDir/$name/ already exists:
     - Append -2, -3, etc. until unique name found
     - Display: "Created '$name-2' at $specsDir ($name already exists)"
```

### Atomic Rollback

On generation failure after spec directory created:

```text
Rollback Procedure:

1. CAPTURE FAILURE
   - Phase agent returns error or times out

2. DELETE SPEC DIRECTORY
   - rm -rf "./specs/$name"

3. RESTORE .current-spec
   - If previous spec was set, restore it

4. DISPLAY ERROR
   - "Generation failed: $errorReason. No spec created."
```

## Detection Logic

```text
1. Determine target specs directory:
   - If --specs-dir provided: Use validated path
   - Else: Use ralph_get_default_dir()
   |
2. Check if name provided in arguments
   |
   +-- Yes: Use ralph_find_spec(name) to check if spec exists
   |   |
   |   +-- Found + no --fresh: Ask "Resume '$name' or start fresh?"
   |   |   +-- Resume: Go to resume flow (use found path)
   |   |   +-- Fresh: Delete existing, go to new flow
   |   |
   |   +-- Found + --fresh: Delete existing, go to new flow
   |   |
   |   +-- Not found: Go to new flow (create in target specs dir)
   |   |
   |   +-- Ambiguous (exit 2): Show paths, ask user to specify
   |
   +-- No: Use ralph_resolve_current() to check active spec
       |
       +-- Has active spec: Go to resume flow (use resolved path)
       |
       +-- No active spec: Ask for name and goal, go to new flow
```

## Resume Flow

1. Read `./specs/$name/.ralph-state.json`
2. If no state file (completed or never started):
   - Check what files exist (research.md, requirements.md, etc.)
   - Determine last completed phase
   - Ask: "Continue to next phase or restart?"
3. If state file exists:
   - Read current phase and task index
   - Show brief status:
     ```
     Resuming '$name'
     Phase: execution, Task 3/8
     Last: "Add error handling"
     ```
   - Continue from current phase

### Resume by Phase

| Phase | Action |
|-------|--------|
| research | Create research team, spawn parallel teammates, merge results |
| requirements | Invoke product-manager agent |
| design | Invoke architect-reviewer agent |
| tasks | Invoke task-planner agent |
| execution | Invoke spec-executor for current task |

<mandatory>
## CRITICAL: Stop After Subagent Completes

After ANY subagent (research-analyst, product-manager, architect-reviewer, task-planner) returns, you MUST:

1. **Read the state file**: `cat ./specs/$name/.ralph-state.json`
2. **Check awaitingApproval**: If `awaitingApproval: true`, you MUST STOP IMMEDIATELY
3. **Do NOT invoke the next phase** - the user must explicitly run the next command

```text
Subagent returns
↓
Read .ralph-state.json
↓
awaitingApproval == true?
↓
YES → STOP. Output: "Phase complete. Run /ralph-specum:<next> to continue."
NO → Continue (only in quick mode where awaitingApproval is not set)
```

**This is NON-NEGOTIABLE in normal mode.** Each phase requires user approval before proceeding.

The only exception is `--quick` mode, which skips approval between phases.
</mandatory>

## New Flow

1. If no name provided, ask:
   - "What should we call this spec?" (validates kebab-case)
2. If no goal provided, ask:
   - "What is the goal? Describe what you want to build."
3. Determine spec directory using path resolver and interview response:
   ```text
   # Resolve target directory (priority order)
   specsDir = (--specs-dir value if provided and valid)
              OR (interview response specsDir if multi-dir was asked)
              OR ralph_get_default_dir()
   basePath = "$specsDir/$name"
   ```
4. Create spec directory: `mkdir -p "$basePath"`
5. Update active spec based on root directory:
   ```text
   # Write to .current-spec
   defaultDir = ralph_get_default_dir()
   if specsDir == defaultDir:
       echo "$name" > "$defaultDir/.current-spec"     # Bare name for default root
   else:
       echo "$basePath" > "$defaultDir/.current-spec" # Full path for non-default root
   ```
6. Ensure gitignore entries exist for spec state files:
   ```bash
   # Add .current-spec and .progress.md to .gitignore if not already present
   if [ -f .gitignore ]; then
     grep -q "specs/.current-spec" .gitignore || echo "specs/.current-spec" >> .gitignore
     grep -q "\*\*/\.progress\.md" .gitignore || echo "**/.progress.md" >> .gitignore
   else
     echo "specs/.current-spec" > .gitignore
     echo "**/.progress.md" >> .gitignore
   fi
   ```
7. Initialize `.ralph-state.json` (note: basePath uses resolved path):
   ```json
   {
     "source": "spec",
     "name": "$name",
     "basePath": "$basePath",
     "phase": "research",
     "taskIndex": 0,
     "totalTasks": 0,
     "taskIteration": 1,
     "maxTaskIterations": 5,
     "globalIteration": 1,
     "maxGlobalIterations": 100,
     "commitSpec": $commitSpec,
     "quickMode": false
   }
   ```
8. Create `.progress.md` with goal
9. **Update Spec Index**:
   ```bash
   # Update the spec index after creating the spec
   ./plugins/ralph-specum/hooks/scripts/update-spec-index.sh --quiet
   ```
10. **Goal Interview** (skip if --quick in $ARGUMENTS)
11. **Team Research Phase** - Create research team, spawn parallel teammates, merge results (see "Team Research Phase" section below)
12. **STOP** - After merge and state update (awaitingApproval=true), display walkthrough and wait for user to run `/ralph-specum:requirements`

## Index Hint

Before starting a new spec, check if codebase indexing exists. If not, show a helpful hint.

<mandatory>
**Skip index hint if --quick flag detected in $ARGUMENTS.**
</mandatory>

### Check Index Status

```bash
# Session guard (skip if already shown in this session)
if [ -z "${RALPH_SPECUM_INDEX_HINT_SHOWN:-}" ]; then
  # Check if specs/.index/ exists and has content
  if [ ! -d "./specs/.index" ] || [ -z "$(ls -A ./specs/.index 2>/dev/null)" ]; then
    # Index is empty or missing - show hint
    SHOW_INDEX_HINT=true
  else
    # Index has content - don't show hint
    SHOW_INDEX_HINT=false
  fi
else
  # Already shown in this session - don't show again
  SHOW_INDEX_HINT=false
fi
```

### Display Hint

If `SHOW_INDEX_HINT` is true, display the following hint before continuing and set `RALPH_SPECUM_INDEX_HINT_SHOWN=true` for this session:

```text
Tip: Run /ralph-specum:index to scan your codebase and create indexed specs.
This helps the research phase find relevant existing code patterns and components.
```

After displaying the hint, export the session guard: `export RALPH_SPECUM_INDEX_HINT_SHOWN=1`

**Note**: Only show this hint once per session. After displaying, continue with Spec Scanner.

## Spec Scanner

Before conducting the Goal Interview, scan existing specs to find related work. This helps surface prior context and avoid duplicate effort.

<mandatory>
**Skip spec scanner if --quick flag detected in $ARGUMENTS.**
</mandatory>

### Scan Steps

```text
1. List all specs across all configured directories using ralph_list_specs():
   - Returns "name|path" pairs for each spec
   - Searches all directories in ralph_get_specs_dirs()
   - Exclude the current spec being created (if known)
   - Exclude .index directory (handled separately in step 1b)
   |
1b. Scan indexed specs (if ./specs/.index/ exists):
   - List component specs: ls ./specs/.index/components/*.md 2>/dev/null
   - List external specs: ls ./specs/.index/external/*.md 2>/dev/null
   - For each indexed spec:
     - Read the file and extract "## Purpose" section (component) or "## Summary" section (external)
     - Use the purpose/summary as the match text
     - Mark as "indexed" type for display differentiation
   |
2. For each spec found (name|path pair):
   - Read $path/.progress.md (using the full path from ralph_list_specs)
   - Extract "Original Goal" section (line after "## Original Goal")
   - If .progress.md doesn't exist, skip this spec
   |
3. Keyword matching:
   - Extract keywords from current goal (split by spaces, lowercase)
   - Remove common words: "the", "a", "an", "to", "for", "with", "and", "or"
   - For each existing spec, count matching keywords with its Original Goal
   - For each indexed spec, count matching keywords with its Purpose/Summary
   - Score = number of matching keywords
   |
4. Rank and filter:
   - Sort ALL specs (regular + indexed) by score (descending)
   - Take top 5 specs with score > 0 (increased from 3 to accommodate indexed specs)
   - If no matches found, skip display step
   - Classify relevance: High (score >= 5), Medium (score 3-4), Low (score 1-2)
   |
5. Display related specs (if any found):
   |
   Related specs found:

   Feature specs:
   - spec-name-1 [High]: [first 50 chars of Original Goal]... [dir-path if non-default]
   - spec-name-2 [Medium]: [first 50 chars of Original Goal]... [dir-path if non-default]

   Indexed components (from specs/.index/components):
   - auth-controller [High]: Handles authentication and session management...
   - user-service [Medium]: User CRUD operations and validation...

   Indexed external (from specs/.index/external):
   - api-docs [Low]: External API documentation for...
   |
   This context may inform the interview questions.
   |
6. Store in state file:
   - Update .ralph-state.json with relatedSpecs array:
     {
       ...existing state,
       "relatedSpecs": [
         {"name": "spec-name-1", "path": "full/path", "goal": "Original Goal text", "score": N, "type": "feature", "relevance": "High"},
         {"name": "spec-name-2", "path": "full/path", "goal": "Original Goal text", "score": N, "type": "feature", "relevance": "Medium"},
         {"name": "auth-controller", "path": "specs/.index/components", "goal": "Purpose text", "score": N, "type": "indexed-component", "relevance": "High"},
         {"name": "api-docs", "path": "specs/.index/external", "goal": "Summary text", "score": N, "type": "indexed-external", "relevance": "Low"}
       ]
     }
```

### Keyword Extraction

Extract meaningful keywords from the goal:

```javascript
// Pseudocode for keyword extraction
function extractKeywords(text) {
  const stopWords = ["the", "a", "an", "to", "for", "with", "and", "or", "is", "it", "this", "that", "be", "on", "in", "of"];
  return text
    .toLowerCase()
    .split(/\s+/)
    .filter(word => word.length > 2)
    .filter(word => !stopWords.includes(word));
}
```

### Match Scoring

Simple keyword overlap scoring:

```javascript
// Pseudocode for scoring
function scoreMatch(currentGoalKeywords, existingGoalKeywords) {
  let score = 0;
  for (const keyword of currentGoalKeywords) {
    if (existingGoalKeywords.includes(keyword)) {
      score += 1;
    }
  }
  return score;
}
```

### Example Output

```text
Related specs found:
- user-auth: Add OAuth2 authentication with JWT tokens...
- api-refactor: Restructure API endpoints for better...
- error-handling: Implement consistent error handling...

This context may inform the interview questions.
```

### Usage in Interview

After scanning, if related specs were found, you may reference them when asking clarifying questions. For example:
- "I noticed you have a spec 'user-auth' for authentication. Does this new feature relate to or depend on that work?"
- "There's an existing 'api-refactor' spec. Should this work integrate with those changes?"

**For indexed specs**, reference them to understand existing codebase patterns:
- "The indexed auth-controller component handles authentication. Should this feature extend that controller or create a new one?"
- "I found an indexed external spec for your API documentation. Does this feature need to follow the patterns described there?"

## Goal Interview (Pre-Research)

<mandatory>
**Skip interview if --quick flag detected in $ARGUMENTS.**

If NOT quick mode, conduct goal interview using AskUserQuestion before research phase.
</mandatory>

### Quick Mode Check

Check if `--quick` appears in `$ARGUMENTS`. If present, skip directly to "Invoke research-analyst".

### Intent Classification

Before asking interview questions, classify the user's goal to determine question depth.

**Classification Logic:**

Analyze the goal text for keywords to determine intent type:

```text
Intent Classification:

1. TRIVIAL: Goal contains keywords like:
   - "fix typo", "typo", "spelling"
   - "small change", "minor"
   - "quick", "simple", "tiny"
   - "rename", "update text"
   → Min questions: 1, Max questions: 2

2. REFACTOR: Goal contains keywords like:
   - "refactor", "restructure", "reorganize"
   - "clean up", "cleanup", "simplify"
   - "extract", "consolidate", "modularize"
   - "improve code", "tech debt"
   → Min questions: 3, Max questions: 5

3. GREENFIELD: Goal contains keywords like:
   - "new feature", "new system", "new module"
   - "add", "build", "implement", "create"
   - "integrate", "introduce"
   - "from scratch"
   → Min questions: 5, Max questions: 10

4. MID_SIZED: Default if no clear match
   → Min questions: 3, Max questions: 7
```

**Confidence Threshold:**

| Match Count | Confidence | Action |
|-------------|------------|--------|
| 3+ keywords | High | Use matched category |
| 1-2 keywords | Medium | Use matched category |
| 0 keywords | Low | Default to MID_SIZED |

**Question Count Rules:**
- TRIVIAL: 1-2 questions (get essentials, move fast)
- REFACTOR: 3-5 questions (understand scope and risks)
- GREENFIELD: 5-10 questions (full context needed)
- MID_SIZED: 3-7 questions (balanced approach)

**Store Intent:**
After classification, store the result in `.progress.md`:
```markdown
## Interview Format
- Version: 1.0

## Intent Classification
- Type: [TRIVIAL|REFACTOR|GREENFIELD|MID_SIZED]
- Confidence: [high|medium|low] ([N] keywords matched)
- Min questions: [N]
- Max questions: [N]
- Keywords matched: [list of matched keywords]
```

### Dialogue Depth by Intent

Intent classification determines how deep the brainstorming dialogue goes — fewer questions for trivial goals, more thorough exploration for greenfield work:

| Intent | Min Questions | Max Questions |
|--------|---------------|---------------|
| TRIVIAL | 1 | 2 |
| REFACTOR | 3 | 5 |
| GREENFIELD | 5 | 10 |
| MID_SIZED | 3 | 7 |

Use these ranges to calibrate the brainstorming dialogue below. TRIVIAL goals need minimal probing; GREENFIELD goals warrant full exploration of the territory.

### Brainstorming Dialogue

**Brainstorming Dialogue**: Apply adaptive dialogue from `skills/interview-framework/SKILL.md`

The coordinator asks context-driven questions one at a time based on the exploration territory below and what's already known from the goal text. Questions adapt to prior answers. After enough understanding, propose approaches.

<mandatory>
**Before asking any question, check: is this a codebase fact or a user decision?**
- Codebase fact → Use Explore agent to find the answer automatically
- User decision → Ask via AskUserQuestion

Never ask the user about things you can discover from the code.
</mandatory>

### Goal Exploration Territory

Areas to probe during the UNDERSTAND phase (hints, not a script — generate actual questions from these based on context):

- **Problem being solved** — what pain point or need is driving this goal?
- **Constraints and must-haves** — performance, compatibility, timeline, integration requirements
- **Success criteria** — how will the user know this feature works correctly?
- **Scope boundaries** — what's explicitly in and out of scope?
- **User's existing knowledge** — what does the user already know about the problem space vs what needs discovery?

### Goal Approach Proposals

After the dialogue, propose 2-3 high-level approaches tailored to the user's goal. Examples (illustrative only — approaches should be specific, not generic):

- **(A)** Extend existing system/module to support the new capability
- **(B)** Build a new standalone module with clean boundaries
- **(C)** Lightweight integration using existing primitives with minimal new code

### Spec Location Interview

After the standard Goal Interview questions, determine where the spec should be stored:

```text
Spec Location Logic:

1. Check if --specs-dir already provided in $ARGUMENTS
   → SKIP spec location question entirely, use provided value

2. Get configured directories: dirs = ralph_get_specs_dirs()

3. If dirs.length > 1 (multiple directories configured):
   → ASK using AskUserQuestion:
     Question: "Where should this spec be stored?"
     Options: [each configured directory as an option]
   → Store response as specsDir

4. If dirs.length == 1 (only default directory):
   → OUTPUT awareness message (non-blocking, just inform):
     "Spec will be created in ./specs/
      Tip: You can organize specs in multiple directories.
      See /ralph-specum:help for multi-directory setup."
   → Use default directory as specsDir
   → Continue immediately without waiting for response

5. Store specsDir for use in spec creation
```

**Multi-Directory Question Format:**

When multiple directories are configured, use AskUserQuestion with dynamic options:

```text
Question: "Where should this spec be stored?"
Header: "Location"
Options: [
  { label: "./specs (Recommended)", description: "Default specs directory" },
  { label: "./packages/api/specs", description: "API-related specs" },
  ... additional configured directories
]
```

**Awareness Message Format:**

When only the default directory is configured, output this informational message:

```text
Spec will be created in ./specs/

Tip: You can organize specs in multiple directories by configuring
specs_dirs in .claude/ralph-specum.local.md. See /ralph-specum:help
for multi-directory setup instructions.
```

This is NOT a blocking question - continue immediately after displaying.

### Store Goal Context

After interview and approach selection, update `.progress.md` with Interview Format, Intent Classification, and Interview Responses sections:

```markdown
## Interview Format
- Version: 1.0

## Intent Classification
- Type: [TRIVIAL|REFACTOR|GREENFIELD|MID_SIZED]
- Confidence: [high|medium|low] ([N] keywords matched)
- Min questions: [N]
- Max questions: [N]
- Keywords matched: [list of matched keywords]

## Interview Responses

### Goal Interview (from start.md)
- [Topic 1]: [response]
- [Topic 2]: [response]
- Chosen approach: [name] — [one-line rationale]
- Spec location: [responses.specsDir] (if multi-dir was asked)
[Any follow-up responses from "Other" selections]
```

### Pass Context to Research Team

Include goal interview context in each research teammate's task description:

```text
Each TaskCreate description should include:

Goal Interview Context:
[Include all topic-response pairs from the Goal Interview section of .progress.md]
Chosen Approach: [name]

Use this context to focus research on relevant areas.
```

## Team Research Phase

<mandatory>
**This section implements step 11 of the New Flow.**

Research uses Claude Code Teams to spawn multiple parallel researcher teammates in both normal and quick mode. The only difference: in quick mode, skip the walkthrough display (step 11k) and do NOT wait for user response - proceed directly to the next phase.
</mandatory>

### 11a: Analyze Research Topics

Break the goal into 2-5 distinct research topics based on the goal interview context. Classify each topic by agent type:

```text
Topic Analysis:

1. Parse the goal and interview responses from .progress.md
2. Identify distinct research areas:
   - External/web topics (best practices, libraries, APIs) → research-analyst teammate
   - Codebase analysis topics (existing patterns, dependencies) → Explore teammate
   - Quality commands discovery → Explore teammate
   - Related specs discovery → Explore teammate
3. Output topic list:

   Research topics identified:
   1. [Topic A] → research-analyst
   2. [Topic B] → research-analyst
   3. Codebase patterns → Explore
   4. Quality commands → Explore
   ...

Minimum: 2 topics (1 research-analyst + 1 Explore)
Maximum: 5 topics
```

### 11b: Create Research Team

```text
1. Check if team "research-$name" already exists:
   - Read ~/.claude/teams/research-$name/config.json
   - If exists: TeamDelete() first to clean up orphaned team

2. Create team:
   TeamCreate(team_name: "research-$name", description: "Parallel research for spec $name")
```

### 11c: Create Research Tasks

Create one TaskCreate per topic with detailed descriptions and output file paths:

```text
For each topic identified in 11a:

TaskCreate(
  subject: "[Topic name] research",
  description: "Research topic: [topic]
    Spec: $name
    Spec path: $basePath
    Output file: $basePath/.research-[topic-slug].md

    Goal Interview Context:
    - Problem: [from .progress.md]
    - Constraints: [from .progress.md]
    - Success criteria: [from .progress.md]

    Instructions:
    [topic-specific research instructions]

    Write all findings to the output file.",
  activeForm: "Researching [topic]"
)
```

**Output file naming convention:**
- External topics: `.research-[topic-slug].md` (e.g., `.research-oauth-patterns.md`)
- Codebase analysis: `.research-codebase.md`
- Quality commands: `.research-quality.md`
- Related specs: `.research-related-specs.md`

### 11d: Spawn Teammates

<mandatory>
**ALL Task calls MUST be in ONE message to ensure true parallel execution.**

Spawn one teammate per task. Use the appropriate subagent_type:
- `research-analyst` for web/external research topics
- `Explore` for codebase analysis topics

Each Task call should include:
- `team_name: "research-$name"` to join the team
- `name: "researcher-N"` or `"explorer-N"` for identification
- The full task description with spec path, output file, and context
</mandatory>

```text
Example - 4 topics spawn 4 teammates in ONE message:

Task(
  subagent_type: research-analyst,
  team_name: "research-$name",
  name: "researcher-1",
  prompt: "You are a research teammate...
    Topic: OAuth authentication patterns
    Output: $basePath/.research-oauth.md
    [goal context]
    Research best practices, libraries, pitfalls.
    Write findings to output file.
    When done, mark your task complete via TaskUpdate."
)

Task(
  subagent_type: research-analyst,
  team_name: "research-$name",
  name: "researcher-2",
  prompt: "You are a research teammate...
    Topic: Rate limiting strategies
    Output: $basePath/.research-rate-limiting.md
    [goal context]
    Research strategies, algorithms, implementations.
    Write findings to output file.
    When done, mark your task complete via TaskUpdate."
)

Task(
  subagent_type: Explore,
  team_name: "research-$name",
  name: "explorer-1",
  prompt: "Analyze codebase for spec: $name
    Output: $basePath/.research-codebase.md
    Find existing patterns, dependencies, constraints.
    Write findings to output file."
)

Task(
  subagent_type: Explore,
  team_name: "research-$name",
  name: "explorer-2",
  prompt: "Discover quality commands for spec: $name
    Output: $basePath/.research-quality.md
    Check package.json scripts, Makefile, CI workflows.
    Write findings to output file."
)
```

### 11e: Wait for Completion

Monitor teammate progress via TaskList and automatic teammate messages:

```text
1. Teammates send messages automatically when they complete tasks or need help
2. Messages are delivered automatically to you (no polling needed)
3. Use TaskList periodically to check overall progress
4. Wait until ALL tasks show status: "completed"
5. If a teammate reports an error, note it for the merge step
```

### 11f: Shutdown Teammates

After all tasks complete, gracefully shut down each teammate:

```text
For each teammate:
  SendMessage(
    type: "shutdown_request",
    recipient: "[teammate-name]",
    content: "Research complete, shutting down"
  )
```

### 11g: Merge Results

<mandatory>
After all teammates complete, merge partial research files into a single research.md.
</mandatory>

```text
1. Read all .research-*.md files from $basePath:
   - .research-[topic-slug].md files (from research-analyst teammates)
   - .research-codebase.md (from Explore teammates)
   - .research-quality.md (from Explore teammates)
   - .research-related-specs.md (from Explore teammates)
   - Handle missing files gracefully (note gaps in merge)

2. Create unified $basePath/research.md with standard structure:

   # Research: $name

   ## Executive Summary
   [Synthesize key findings from ALL teammates - 2-3 sentences]

   ## External Research
   [Merge from all .research-[topic].md files]
   ### Best Practices
   ### Prior Art
   ### Pitfalls to Avoid

   ## Codebase Analysis
   [From .research-codebase.md]
   ### Existing Patterns
   ### Dependencies
   ### Constraints

   ## Related Specs
   [From .research-related-specs.md if exists]

   ## Quality Commands
   [From .research-quality.md if exists]

   ## Feasibility Assessment
   [Synthesize from all sources]

   ## Recommendations for Requirements
   [Consolidated recommendations]

   ## Open Questions
   [Consolidated from all teammates]

   ## Sources
   [All URLs and file paths from all teammates]

3. Delete partial research files after successful merge:
   rm $basePath/.research-*.md

4. Quality check: Ensure no duplicate information, consistent formatting
```

### 11h: Clean Up Team

```text
TeamDelete()
```

This removes the team directory and task list for `research-$name`.

### 11i: Update State

```text
1. Update $basePath/.ralph-state.json:
   - Normal mode:
     {
       ...existing state,
       "phase": "research",
       "awaitingApproval": true
     }
   - Quick mode:
     {
       ...existing state,
       "phase": "research"
     }
     (Do NOT set awaitingApproval - proceed directly to next phase)

2. Update $basePath/.progress.md with research completion:
   - Add "## Research Phase" section
   - Note: parallel team research completed
   - List topics researched and teammate count
```

### 11j: Commit Spec

Read `commitSpec` from `.ralph-state.json`.

If `commitSpec` is true:
```bash
git add $basePath/research.md
git commit -m "spec($name): add research findings"
git push -u origin $(git branch --show-current)
```

If commit or push fails, display warning but continue.

### 11k: Display Walkthrough

<mandatory>
**WALKTHROUGH IS REQUIRED IN NORMAL MODE - DO NOT SKIP.**

**Quick mode (`--quick`)**: Skip the walkthrough display. Do NOT stop or wait for user response. Proceed directly to the next phase (requirements).

**Normal mode**: After research.md is created, display a concise walkthrough:

```
Research complete for '$name'.
Output: $basePath/research.md

## What I Found

**Summary**: [1-2 sentences from Executive Summary]

**Key Recommendations**:
1. [First recommendation]
2. [Second recommendation]
3. [Third recommendation]

**Feasibility**: [High/Medium/Low] | **Risk**: [High/Medium/Low] | **Effort**: [S/M/L/XL]
```

Then STOP. Output: `→ Next: Run /ralph-specum:requirements`
End response immediately. Wait for user to run `/ralph-specum:requirements`.
</mandatory>

### Edge Cases

- **Orphaned team on session interrupt**: Step 11b checks if team `research-$name` already exists and cleans it up first
- **Teammate failure**: Merge step (11g) handles missing `.research-*.md` files gracefully, notes gaps in the merged research.md
- **Quick mode**: Runs Team Research Phase but skips walkthrough and does not wait for user response - proceeds directly to next phase
- **Team name conflicts**: Uses `research-$name` where spec names are unique within a project

## Quick Mode Flow (Summary)

Triggered when `--quick` flag detected. Runs all spec phases sequentially using the same agents as normal mode, without interactive prompts.

```text
1. Check if --quick flag present in $ARGUMENTS
   |
   +-- Yes: Extract args before --quick
   |   |
   |   +-- Two args: name = first, goal = second
   |   |
   |   +-- One arg: goal = first (infer name later)
   |   |
   |   +-- Zero args: Error "Quick mode requires a goal or plan"
   |
   +-- No: Continue to normal Detection Logic
```

### Quick Mode Steps (POC)

1. Parse args before `--quick`:
   - If two args: `name` = first arg (kebab-case), `goal` = second arg
   - If one arg: `goal` = arg, `name` = infer from goal (up to 4 key terms, kebab-case, max 30 chars)
2. Validate non-empty goal
3. Determine spec directory using path resolver:
   - `specsDir` = (--specs-dir value if provided and valid) OR `ralph_get_default_dir()`
   - `basePath` = "$specsDir/$name"
4. Create spec directory: `mkdir -p "$basePath"`
5. Initialize `.ralph-state.json` with `source: "plan"` (note: basePath uses resolved path):
   ```json
   {
     "source": "plan",
     "name": "$name",
     "basePath": "$basePath",
     "phase": "research",
     "taskIndex": 0,
     "totalTasks": 0,
     "taskIteration": 1,
     "maxTaskIterations": 5,
     "globalIteration": 1,
     "maxGlobalIterations": 100,
     "commitSpec": $commitSpec,
     "quickMode": true
   }
   ```
6. Write `.progress.md` with goal
7. Update `.current-spec` based on root:
   - If specsDir == default: write bare name
   - If specsDir != default: write full path "$basePath"
4a. Ensure gitignore entries exist for spec state files:
   - Add specs/.current-spec to .gitignore if not present
   - Add **/.progress.md to .gitignore if not present
8. **Update Spec Index**:
   ```bash
   ./plugins/ralph-specum/hooks/scripts/update-spec-index.sh --quiet
   ```
9. Goal Type Detection: classify as "fix" or "add", run reproduction for fix goals
10. Research Phase: run Team Research flow (skip walkthrough), clear awaitingApproval
11. Requirements Phase: delegate to product-manager with quick mode directive, review, clear awaitingApproval
12. Design Phase: delegate to architect-reviewer with quick mode directive, review, clear awaitingApproval
13. Tasks Phase: delegate to task-planner with quick mode directive, review
14. Transition: count tasks, update state phase="execution", optionally commit specs
15. Invoke spec-executor for task 1

## Status Display (on resume)

Before resuming, show brief status:

```text
Resuming: user-auth
Phase: execution
Progress: 3/8 tasks complete
Current: 2.1 Add error handling

Continuing...
```

## Output

After detection and action:

**New spec:**
```text
Created spec 'user-auth' at ./specs/user-auth/

Starting research phase...
```

**Resume:**
```text
Resuming 'user-auth' at execution phase, task 4/8

Continuing task: 2.2 Extract retry logic
```

**Quick mode:**
```text
Quick mode: Created 'build-auth-with' at ./specs/build-auth-with/
Generated 4 artifacts from goal.
Starting task 1/N...
```

**Quick mode with --specs-dir:**
```text
Quick mode: Created 'api-auth' at ./packages/api/specs/api-auth/
Generated 4 artifacts from goal.
Starting task 1/N...
```
