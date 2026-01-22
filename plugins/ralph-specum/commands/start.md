---
description: Smart entry point that detects if you need a new spec or should resume existing
argument-hint: [name] [goal] [--fresh] [--quick] [--commit-spec] [--no-commit-spec]
allowed-tools: [Read, Write, Bash, Task, AskUserQuestion]
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

```
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
```
Spec name: user-auth
Branch: feat/user-auth

If feat/user-auth exists:
Branch: feat/user-auth-2
```

### Worktree Details

When user chooses worktree option:

```bash
# Get repo name for path suggestion
REPO_NAME=$(basename $(git rev-parse --show-toplevel))

# Default worktree path
WORKTREE_PATH="../${REPO_NAME}-${SPEC_NAME}"

# Create worktree with new branch
git worktree add "$WORKTREE_PATH" -b "feat/${SPEC_NAME}"
```

After worktree creation:
- Inform user of the worktree path
- IMPORTANT: Output clear guidance for the user:
  ```
  Created worktree at '<path>' on branch '<branch-name>'

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

## Quick Mode Uses Ralph Loop

In quick mode (`--quick`), execution uses `/ralph-loop` for autonomous task completion.

After generating spec artifacts in quick mode, invoke ralph-loop:
```
Skill: ralph-loop:ralph-loop
Args: Read ./specs/$spec/.coordinator-prompt.md and follow those instructions exactly. Output ALL_TASKS_COMPLETE when done. --max-iterations <calculated> --completion-promise ALL_TASKS_COMPLETE
```

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
| Research | `research-analyst` |
| Requirements | `product-manager` |
| Design | `architect-reviewer` |
| Task Planning | `task-planner` |
| Artifact Generation (quick mode) | `plan-synthesizer` |
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

### Commit Spec Flag Logic

```text
1. Check if --no-commit-spec in $ARGUMENTS → commitSpec = false
2. Else if --commit-spec in $ARGUMENTS → commitSpec = true
3. Else if --quick in $ARGUMENTS → commitSpec = false (quick mode default)
4. Else → commitSpec = true (normal mode default)
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

```
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
1. Check if `./specs/$name/plan.md` exists
2. If exists: read content, use as planContent
3. If not exists: error with guidance message

### Name Inference

If no explicit name provided, infer from goal:
1. Take first 3 words of goal
2. Convert to kebab-case (lowercase, spaces to hyphens)
3. Truncate to max 30 characters
4. Strip non-alphanumeric except hyphens

Example: "Build authentication with JWT tokens" -> "build-authentication-with"

### Quick Mode Execution

<mandatory>
**REMINDER: Even in quick mode, you MUST delegate ALL work to subagents.**
- Artifact generation → delegate to `plan-synthesizer` via Task tool
- Task execution → delegate to `spec-executor` via Task tool
- You only handle: directory creation, state file writes, and coordination
</mandatory>

```
1. Validate input (non-empty goal/plan)
   |
2. Infer name from goal (if not provided)
   |
3. Create spec directory: ./specs/$name/
   |
3a. Ensure gitignore entries exist for spec state files:
   - Add specs/.current-spec to .gitignore if not present
   - Add **/.progress.md to .gitignore if not present
   |
4. Write .ralph-state.json:
   {
     "source": "plan",
     "name": "$name",
     "basePath": "./specs/$name",
     "phase": "tasks",
     "taskIndex": 0,
     "totalTasks": 0,
     "taskIteration": 1,
     "maxTaskIterations": 5,
     "globalIteration": 1,
     "maxGlobalIterations": 100,
     "commitSpec": $commitSpec
   }
   |
5. Write .progress.md with original goal
   |
6. Update .current-spec: echo "$name" > ./specs/.current-spec
   |
7. Invoke plan-synthesizer agent via Task tool:
   Task: plan-synthesizer
   Input: goal="$goal", basePath="./specs/$name"
   |
8. After generation completes:
   - Update .ralph-state.json: phase="execution", taskIndex=0
   - Read tasks.md to get totalTasks count
   |
8a. If commitSpec is true:
   - Stage spec files: git add ./specs/$name/research.md ./specs/$name/requirements.md ./specs/$name/design.md ./specs/$name/tasks.md
   - Commit: git commit -m "spec($name): add spec artifacts"
   - Push: git push -u origin $(git branch --show-current)
   |
9. Display brief summary:
   Quick mode: Created spec '$name'
   [If commitSpec: "Spec committed and pushed."]
   Starting execution...
   |
10. Invoke spec-executor for task 1
```

### Quick Mode Validation

Before creating the spec, validate all inputs:

```
Validation Sequence:

1. ZERO ARGS CHECK (if no args before --quick)
   - Error: "Quick mode requires a goal or plan file"

2. FILE NOT FOUND (if file path detected)
   - If file not exists: "File not found: $filePath"

3. EMPTY CONTENT CHECK
   - If empty or whitespace only: "Plan content is empty. Provide a goal or non-empty file."

4. PLAN TOO SHORT WARNING (< 10 words)
   - If word count < 10: "Warning: Short plan may produce vague tasks"
   - Continue with warning displayed

5. NAME CONFLICT RESOLUTION
   - If ./specs/$name/ already exists:
     - Append -2, -3, etc. until unique name found
     - Display: "Created '$name-2' ($name already exists)"
```

### Atomic Rollback

On generation failure after spec directory created:

```
Rollback Procedure:

1. CAPTURE FAILURE
   - plan-synthesizer agent returns error or times out

2. DELETE SPEC DIRECTORY
   - rm -rf "./specs/$name"

3. RESTORE .current-spec
   - If previous spec was set, restore it

4. DISPLAY ERROR
   - "Generation failed: $errorReason. No spec created."
```

## Detection Logic

```
1. Check if name provided in arguments
   |
   +-- Yes: Check if ./specs/$name/ exists
   |   |
   |   +-- Exists + no --fresh: Ask "Resume '$name' or start fresh?"
   |   |   +-- Resume: Go to resume flow
   |   |   +-- Fresh: Delete existing, go to new flow
   |   |
   |   +-- Exists + --fresh: Delete existing, go to new flow
   |   |
   |   +-- Not exists: Go to new flow
   |
   +-- No: Check ./specs/.current-spec
       |
       +-- Has active spec: Go to resume flow
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
| research | Invoke research-analyst agent |
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

```
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
3. Create spec directory: `./specs/$name/`
4. Update active spec: `echo "$name" > ./specs/.current-spec`
5. Ensure gitignore entries exist for spec state files:
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
6. Initialize `.ralph-state.json`:
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
     "maxGlobalIterations": 100,
     "commitSpec": $commitSpec
   }
   ```
6. Create `.progress.md` with goal
7. **Goal Interview** (skip if --quick in $ARGUMENTS)
8. Invoke research-analyst agent with goal interview context
9. **STOP** - research-analyst sets awaitingApproval=true. Output status and wait for user to run `/ralph-specum:requirements`

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

```
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

**Question Count Rules:**
- TRIVIAL: 1-2 questions (get essentials, move fast)
- REFACTOR: 3-5 questions (understand scope and risks)
- GREENFIELD: 5-10 questions (full context needed)
- MID_SIZED: 3-7 questions (balanced approach)

**Store Intent:**
After classification, store the result in `.progress.md`:
```markdown
## Intent Classification
- Type: [TRIVIAL|REFACTOR|GREENFIELD|MID_SIZED]
- Min questions: [N]
- Max questions: [N]
- Keywords matched: [list of matched keywords]
```

### Question Pools

Define question pools for each intent type. Questions are asked in order until completion signal or max reached.

**Trivial Pool (2 questions):**

| # | Question | Required | Key |
|---|----------|----------|-----|
| 1 | What specifically needs to change? | Required | `change` |
| 2 | Any constraints or considerations? | Optional | `constraints` |

**Refactor Pool (5 questions):**

| # | Question | Required | Key |
|---|----------|----------|-----|
| 1 | What's driving this refactor? | Required | `driver` |
| 2 | How important is backwards compatibility? | Required | `riskTolerance` |
| 3 | What's the current test coverage? | Required | `testCoverage` |
| 4 | Should tests be updated as part of this? | Optional | `updateTests` |
| 5 | Any performance concerns to address? | Optional | `performance` |

**Greenfield Pool (10 questions):**

| # | Question | Required | Key |
|---|----------|----------|-----|
| 1 | What problem are you solving? | Required | `problem` |
| 2 | Who are the primary users? | Required | `users` |
| 3 | What's the priority level? | Required | `priority` |
| 4 | Any constraints or must-haves? | Required | `constraints` |
| 5 | How should this integrate with existing code? | Required | `integration` |
| 6 | How will you know this is successful? | Optional | `success` |
| 7 | Any security considerations? | Optional | `security` |
| 8 | Any performance requirements? | Optional | `performance` |
| 9 | What's explicitly out of scope? | Optional | `outOfScope` |
| 10 | Any other context to share? | Optional | `otherContext` |

**Mid-sized Pool (7 questions):**

| # | Question | Required | Key |
|---|----------|----------|-----|
| 1 | What's the core deliverable? | Required | `coreDeliverable` |
| 2 | What's the priority level? | Required | `priority` |
| 3 | What's explicitly out of scope? | Required | `outOfScope` |
| 4 | Any dependencies on other systems? | Optional | `dependencies` |
| 5 | What level of testing is expected? | Optional | `testing` |
| 6 | Any deployment considerations? | Optional | `deployment` |
| 7 | Any other context to share? | Optional | `otherContext` |

**Pool Selection Logic:**

```
1. Get intent from Intent Classification step
2. Select corresponding pool:
   - TRIVIAL → Trivial Pool
   - REFACTOR → Refactor Pool
   - GREENFIELD → Greenfield Pool
   - MID_SIZED → Mid-sized Pool
3. Ask Required questions first, then Optional questions
4. Stop when:
   - User signals completion (after minRequired reached)
   - All questions asked (maxAllowed reached)
   - User selects "No, let's proceed" on optional question
```

### Question Classification

Before asking any question, classify it to determine the appropriate source for the answer.

**Classification Matrix:**

| Question Type | Source | Examples |
|---------------|--------|----------|
| Codebase fact | Explore agent | "What patterns exist?", "Where is X located?", "What dependencies are used?" |
| User preference | AskUserQuestion | "What priority level?", "Which approach do you prefer?" |
| Requirement | AskUserQuestion | "What must this feature do?", "What are the constraints?" |
| Scope decision | AskUserQuestion | "Should this include X?", "What's in/out of scope?" |
| Risk tolerance | AskUserQuestion | "How critical is backwards compatibility?" |
| Constraint | AskUserQuestion | "Any performance requirements?", "Timeline constraints?" |

<mandatory>
**DO NOT ask user about codebase facts - use Explore agent instead.**

Questions that should go to the user (AskUserQuestion):
- Preference: "Which approach do you prefer?"
- Requirement: "What must this feature accomplish?"
- Scope: "Should this include feature X?"
- Constraint: "Any performance/timeline constraints?"
- Risk: "How important is backwards compatibility?"

Questions that should use Explore agent (NOT AskUserQuestion):
- Existing patterns: "How does the codebase handle X?"
- File locations: "Where are the authentication modules?"
- Dependencies: "What libraries are currently used for Y?"
- Code conventions: "What naming patterns are used?"
- Architecture: "How is the service layer structured?"

**Before each interview question, check: Is this a codebase fact or user decision?**
- Codebase fact → Use Explore agent to find the answer automatically
- User decision → Ask via AskUserQuestion
</mandatory>

### Goal Interview Questions (Single-Question Flow)

Use individual AskUserQuestion calls to clarify the goal before research. This enables adaptive questioning based on prior answers.

**Single-Question Loop Structure:**

```
Initialize:
  askedCount = 0
  responses = {}
  intent = [result from Intent Classification]
  minRequired = intent.minQuestions
  maxAllowed = intent.maxQuestions
  completionSignals = ["done", "proceed", "skip", "enough", "that's all", "continue", "next"]

Question Pool (asked in order until completion):
  1. problemQuestion: "What problem are you solving?"
  2. constraintsQuestion: "Any constraints or must-haves?"
  3. successQuestion: "How will you know this is successful?"
  4. finalQuestion: "Any other context you'd like to share?" (always last, optional)

Loop:
  WHILE askedCount < maxAllowed:
    |
    +-- Select next question from pool
    |
    +-- Ask single question:
    |   ```
    |   AskUserQuestion:
    |     question: "[Current question text]"
    |     options:
    |       - "[Option 1]"
    |       - "[Option 2]"
    |       - "[Option 3]"
    |       - "Other"
    |   ```
    |
    +-- Store response in responses[questionKey]
    |
    +-- askedCount++
    |
    +-- Check completion conditions:
    |   |
    |   +-- If askedCount >= minRequired AND user response matches completionSignal:
    |   |   → EXIT loop (user signaled done)
    |   |
    |   +-- If askedCount >= minRequired AND currentQuestion == finalQuestion:
    |   |   → EXIT loop (reached final optional question)
    |   |
    |   +-- If user selected "Other":
    |   |   → Ask follow-up (see Adaptive Depth)
    |   |   → DO NOT increment toward maxAllowed
    |   |
    |   +-- Otherwise:
    |       → CONTINUE to next question
```

**Question 1: Problem Definition**

```
AskUserQuestion:
  question: "What problem are you solving with this feature?"
  options:
    - "Fixing a bug or issue"
    - "Adding new functionality"
    - "Improving existing behavior"
    - "Other"
```

Store response as `responses.problem`.

**Question 2: Constraints**

```
AskUserQuestion:
  question: "Any constraints or must-haves for this feature?"
  options:
    - "No special constraints"
    - "Must integrate with existing code"
    - "Performance is critical"
    - "Other"
```

Store response as `responses.constraints`.

**Question 3: Success Criteria**

```
AskUserQuestion:
  question: "How will you know this feature is successful?"
  options:
    - "Tests pass and code works"
    - "Users can complete specific workflow"
    - "Performance meets target metrics"
    - "Other"
```

Store response as `responses.success`.

**Final Question: Additional Context (Optional)**

After reaching minRequired questions, ask final optional question:

```
AskUserQuestion:
  question: "Any other context you'd like to share? (or say 'done' to proceed)"
  options:
    - "No, let's proceed"
    - "Yes, I have more details"
    - "Other"
```

Store response as `responses.additionalContext`.

**Completion Signal Detection:**

After each response, check if user wants to end the interview:
- If response contains any of: "done", "proceed", "skip", "enough", "that's all", "continue", "next"
- AND askedCount >= minRequired
- THEN exit the interview loop

Example detection:
```
userResponse = [last answer from AskUserQuestion]
if askedCount >= minRequired:
  for signal in completionSignals:
    if signal in userResponse.lower():
      → EXIT interview loop
```

### Adaptive Depth

If user selects "Other" for any question:
1. Ask follow-up question to clarify their custom response
2. Continue until clarity reached or 5 rounds complete
3. Each follow-up round uses single question focused on the "Other" response

Example follow-up:
```
AskUserQuestion:
  questions:
    - question: "You mentioned [Other response]. Can you elaborate?"
      options:
        - "[Contextual option 1]"
        - "[Contextual option 2]"
        - "This is sufficient detail"
        - "Other"
```

### Store Goal Context

After interview, update `.progress.md` to include Intent Classification and Interview Responses sections:

```markdown
## Intent Classification
- Type: [TRIVIAL|REFACTOR|GREENFIELD|MID_SIZED]
- Min questions: [N]
- Max questions: [N]
- Keywords matched: [list of matched keywords]

## Interview Responses

### Goal Interview (from start.md)
- Problem: [responses.problem]
- Constraints: [responses.constraints]
- Success criteria: [responses.success]
- Additional context: [responses.additionalContext]
[Any follow-up responses from "Other" selections]
```

**Context Accumulator Instructions:**

1. After intent classification, immediately write the "Intent Classification" section
2. After each AskUserQuestion response, append to the "Interview Responses" section
3. Use semantic keys matching the question type:
   - `responses.problem` → "Problem:"
   - `responses.constraints` → "Constraints:"
   - `responses.success` → "Success criteria:"
   - `responses.additionalContext` → "Additional context:"
4. For "Other" follow-up responses, append with descriptive key based on the follow-up question
5. Format must be parseable for later parameter chain checks in subsequent phases

### Pass Context to Research

Include goal interview context when invoking research-analyst:

```
Task delegation prompt should include:

Goal Interview Context:
- Problem: [response]
- Constraints: [response]
- Success criteria: [response]

Use this context to focus research on relevant areas.
```

## Quick Mode Flow

Triggered when `--quick` flag detected. Skips all spec phases and auto-generates artifacts.

```
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
   - If one arg: `goal` = arg, `name` = infer from goal (first 3 words, kebab-case, max 30 chars)
2. Validate non-empty goal
3. Create spec directory: `./specs/$name/`
4. Initialize `.ralph-state.json` with `source: "plan"`:
   ```json
   {
     "source": "plan",
     "name": "$name",
     "basePath": "./specs/$name",
     "phase": "tasks",
     "taskIndex": 0,
     "totalTasks": 0,
     "taskIteration": 1,
     "maxTaskIterations": 5,
     "globalIteration": 1,
     "maxGlobalIterations": 100
   }
   ```
5. Write `.progress.md` with goal
6. Update `.current-spec` with name
7. Invoke plan-synthesizer agent to generate all artifacts
8. After generation: update state `phase: "execution"`, read task count
9. Invoke spec-executor for task 1

## Status Display (on resume)

Before resuming, show brief status:

```
Resuming: user-auth
Phase: execution
Progress: 3/8 tasks complete
Current: 2.1 Add error handling

Continuing...
```

## Output

After detection and action:

**New spec:**
```
Created spec 'user-auth' at ./specs/user-auth/

Starting research phase...
```

**Resume:**
```
Resuming 'user-auth' at execution phase, task 4/8

Continuing task: 2.2 Extract retry logic
```

**Quick mode:**
```
Quick mode: Created 'build-auth-with' at ./specs/build-auth-with/
Generated 4 artifacts from goal.
Starting task 1/N...
```
