---
description: Create new spec and start research phase
argument-hint: <spec-name> [goal description] [--skip-research] [--specs-dir <path>]
allowed-tools: [Bash, Write, Task, AskUserQuestion]
---

# Create New Spec

You are creating a new specification and starting the research phase.

## Parse Arguments

From `$ARGUMENTS`, extract:
- **name**: The spec name (required, must be kebab-case, first argument)
- **goal**: Everything after the name except flags (optional)
- **--skip-research**: If present, skip research and start with requirements
- **--specs-dir <path>**: Create spec in specified directory (must be in configured specs_dirs array)

Examples:
- `/ralph-specum:new user-auth` -> name="user-auth", goal=none
- `/ralph-specum:new user-auth Add OAuth2 login` -> name="user-auth", goal="Add OAuth2 login"
- `/ralph-specum:new user-auth --skip-research` -> name="user-auth", goal=none, skip research
- `/ralph-specum:new api-auth --specs-dir ./packages/api/specs` -> create in specified dir

## Multi-Directory Resolution

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

## --specs-dir Validation

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

## Spec Directory Resolution

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

## Capture Goal

<mandatory>
The goal MUST be captured before proceeding:

1. If goal text was provided in arguments, use it
2. If NO goal text provided, use AskUserQuestion to ask:
   "What is the goal for this spec? Describe what you want to build or achieve."
3. Store the goal verbatim in .progress.md under "Original Goal"
</mandatory>

## Validation

1. Verify spec name is provided
2. Verify spec name is kebab-case (lowercase, hyphens only)
3. If --specs-dir provided, validate against configured specs_dirs
4. Determine target directory: specsDir = (validated --specs-dir) OR ralph_get_default_dir()
5. Check if `$specsDir/$name/` already exists. If so, ask user if they want to resume or overwrite

## Initialize

1. Determine spec directory and base path:
   ```text
   specsDir = (validated --specs-dir) OR ralph_get_default_dir()
   basePath = "$specsDir/$name"
   defaultDir = ralph_get_default_dir()
   ```

2. Create directory structure:
   ```bash
   mkdir -p "$basePath"
   ```

3. Update active spec tracker based on root directory:
   ```bash
   # Write to .current-spec in default specs dir
   if [ "$specsDir" = "$defaultDir" ]; then
       echo "$name" > "$defaultDir/.current-spec"     # Bare name for default root
   else
       echo "$basePath" > "$defaultDir/.current-spec" # Full path for non-default root
   fi
   ```

4. Ensure gitignore entries exist for spec state files:
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

5. Create `.ralph-state.json` in the spec directory (note: basePath uses resolved path):
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
     "maxGlobalIterations": 100
   }
   ```

   If `--skip-research`, set `"phase": "requirements"` instead.

6. Create initial `.progress.md` with the captured goal:
   ```markdown
   ---
   spec: $name
   basePath: $basePath
   phase: research
   task: 0/0
   updated: <current timestamp>
   ---

   # Progress: $name

   ## Original Goal

   $goal

   ## Completed Tasks

   _No tasks completed yet_

   ## Current Task

   Starting research phase

   ## Learnings

   _Discoveries and insights will be captured here_

   ## Blockers

   - None currently

   ## Next

   Complete research, then proceed to requirements
   ```

## Execute Research Phase

If NOT `--skip-research`:

<mandatory>
Use the Task tool with `subagent_type: research-analyst` to run the research phase.
</mandatory>

Invoke research-analyst agent with:
- The user's goal/feature description from the conversation
- The spec name and basePath (resolved from --specs-dir or default)
- Instructions to output `$basePath/research.md`

The agent will:
1. Search web for best practices and prior art
2. Explore codebase for existing patterns
3. Assess feasibility
4. Create research.md with findings and recommendations

After research completes:

<mandatory>
**STOP HERE. DO NOT PROCEED TO REQUIREMENTS.**

(This does not apply in `--quick` mode, which auto-generates all artifacts without stopping.)

After displaying the output, you MUST:
1. End your response immediately
2. Wait for the user to review research.md
3. Only proceed to requirements when user explicitly runs `/ralph-specum:requirements`

DO NOT automatically invoke the product-manager or run the requirements phase.
The user needs time to review research findings before proceeding.
</mandatory>

## Execute Requirements Phase (if --skip-research)

If `--skip-research` was specified:

<mandatory>
Use the Task tool with `subagent_type: product-manager` to run the requirements phase.
</mandatory>

Invoke product-manager agent with:
- The user's goal/feature description
- The spec name and basePath (resolved from --specs-dir or default)
- Instructions to output `$basePath/requirements.md`

## Output

After completion, inform the user:

```
Spec '$name' created at $basePath/

Current phase: research (or requirements if skipped)

Next steps:
- Review the generated research.md (or requirements.md)
- Run /ralph-specum:requirements to proceed (or /ralph-specum:design if skipped research)
```

**With --specs-dir:**
```
Spec '$name' created at $basePath/ (--specs-dir: $specsDir)

Current phase: research (or requirements if skipped)

Next steps:
- Review the generated research.md (or requirements.md)
- Run /ralph-specum:requirements to proceed (or /ralph-specum:design if skipped research)
```

<mandatory>
**STOP AFTER DISPLAYING OUTPUT.**

(This does not apply in `--quick` mode, which auto-generates all artifacts without stopping.)

Do NOT proceed to the next phase automatically.
Wait for explicit user command to continue.
</mandatory>
