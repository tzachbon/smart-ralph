---
description: Create new spec and start research phase
argument-hint: <spec-name> [goal description] [--skip-research]
allowed-tools: [Bash, Write, Task, AskUserQuestion]
---

# Create New Spec

You are creating a new specification and starting the research phase.

## Parse Arguments

From `$ARGUMENTS`, extract:
- **name**: The spec name (required, must be kebab-case, first argument)
- **goal**: Everything after the name except flags (optional)
- **--skip-research**: If present, skip research and start with requirements

Examples:
- `/ralph-specum:new user-auth` -> name="user-auth", goal=none
- `/ralph-specum:new user-auth Add OAuth2 login` -> name="user-auth", goal="Add OAuth2 login"
- `/ralph-specum:new user-auth --skip-research` -> name="user-auth", goal=none, skip research

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
3. Check if `./specs/$name/` already exists. If so, ask user if they want to resume or overwrite

## Initialize

1. Create directory structure:
   ```bash
   mkdir -p ./specs/$name
   ```

2. Update active spec tracker:
   ```bash
   echo "$name" > ./specs/.current-spec
   ```

3. Ensure gitignore entries exist for spec state files:
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

4. Create `.ralph-state.json` in the spec directory:
   ```json
   {
     "source": "spec",
     "name": "$name",
     "basePath": "./specs/$name",
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

5. Create initial `.progress.md` with the captured goal:
   ```markdown
   ---
   spec: $name
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
- The spec name and path
- Instructions to output `./specs/$name/research.md`

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
- The spec name and path
- Instructions to output `./specs/$name/requirements.md`

## Output

After completion, inform the user:

```
Spec '$name' created at ./specs/$name/

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
