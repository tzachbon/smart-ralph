---
description: Create new spec and start research phase
argument-hint: <spec-name> [--skip-research]
allowed-tools: [Bash, Write, Task]
---

# Create New Spec

You are creating a new specification and starting the research phase.

## Parse Arguments

From `$ARGUMENTS`, extract:
- **name**: The spec name (required, must be kebab-case)
- **--skip-research**: If present, skip research and start with requirements

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

3. Create `.ralph-state.json` in the spec directory:
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

4. Create initial `.progress.md`:
   ```markdown
   ---
   spec: $name
   phase: research
   task: 0/0
   updated: <current timestamp>
   ---

   # Progress: $name

   ## Original Goal

   <user's goal from conversation>

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
