---
description: Generate technical design from requirements
argument-hint: [spec-name]
allowed-tools: "*"
---

# Design Phase

You are generating technical design for a specification. Running this command implicitly approves the requirements phase.

<mandatory>
**YOU ARE A COORDINATOR, NOT AN ARCHITECT.**

You MUST delegate ALL design work to the `architect-reviewer` subagent.
Do NOT create architecture diagrams, technical decisions, or design.md yourself.
</mandatory>

## Multi-Directory Resolution

This command uses the path resolver for dynamic spec path resolution:

**Path Resolver Functions**:
- `ralph_resolve_current()` - Resolves .current-spec to full path (handles bare name = ./specs/$name, full path = as-is)
- `ralph_find_spec(name)` - Find spec by name across all configured roots

**Configuration**: Specs directories are configured in `.claude/ralph-specum.local.md`:
```yaml
specs_dirs: ["./specs", "./packages/api/specs", "./packages/web/specs"]
```

## Determine Active Spec

1. If `$ARGUMENTS` contains a spec name, use `ralph_find_spec()` to resolve it
2. Otherwise, use `ralph_resolve_current()` to get the active spec path
3. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."

The spec path is dynamically resolved - it may be in `./specs/` or any other configured specs directory.

## Validate

1. Check the resolved spec directory exists
2. Check the spec's requirements.md exists. If not, error: "Requirements not found. Run /ralph-specum:requirements first."
3. Read `.ralph-state.json`
4. Clear approval flag: update state with `awaitingApproval: false`

## Gather Context

Read:
- `./specs/$spec/requirements.md` (required)
- `./specs/$spec/research.md` (if exists)
- `./specs/$spec/.progress.md`
- Existing codebase patterns (via exploration)

## Interview

<mandatory>
**Skip interview if --quick flag detected in $ARGUMENTS.**

If NOT quick mode, conduct interview using AskUserQuestion before delegating to subagent.
</mandatory>

### Quick Mode Check

Check if `--quick` appears anywhere in `$ARGUMENTS`. If present, skip directly to "Execute Design".

### Read Context from .progress.md

Before conducting the interview, read `.progress.md` to get:
1. **Intent Classification** from start.md (TRIVIAL, REFACTOR, GREENFIELD, MID_SIZED)
2. **All prior interview responses** to enable parameter chain (skip already-answered questions)

```
Context Reading:
1. Read ./specs/$spec/.progress.md
2. Parse "## Intent Classification" section for intent type and question counts
3. Parse "## Interview Responses" section for prior answers (Goal Interview, Research Interview, Requirements Interview)
4. Store parsed data for parameter chain checks
```

**Intent-Based Question Counts (same as start.md):**
- TRIVIAL: 1-2 questions (minimal architecture context needed)
- REFACTOR: 3-5 questions (understand architecture impact)
- GREENFIELD: 5-10 questions (full architecture context)
- MID_SIZED: 3-7 questions (balanced approach)

### Brainstorming Dialogue

**Brainstorming Dialogue**: Apply adaptive dialogue from `skills/interview-framework/SKILL.md`

The coordinator asks context-driven questions one at a time based on the exploration territory below and what's already in `.progress.md`. Questions adapt to prior answers. After enough understanding, propose approaches.

### Design Exploration Territory

Areas to probe during the UNDERSTAND phase (hints, not a script):

- **Architecture fit** — should this extend the existing architecture, create an isolated module, or require a refactor?
- **Technology constraints** — any required or forbidden libraries, frameworks, or patterns?
- **Integration tightness** — how tightly should this integrate with existing systems?
- **Failure modes** — what failure scenarios matter? Graceful degradation, retry logic, alerting?
- **Deployment model** — feature flags, gradual rollout, migrations, or big-bang?

### Design Approach Proposals

After the dialogue, propose 2-3 architectural approaches tailored to the user's goal. Examples (illustrative only):

- **(A)** Extend existing service/module layer — minimal new abstractions
- **(B)** New isolated component — clean boundaries, own data layer
- **(C)** Hybrid — new module with shared infrastructure and data layer

### Store Interview & Approach

After interview and approach selection, append to `.progress.md` under the "Interview Responses" section:

```markdown
### Design Interview (from design.md)
- [Topic 1]: [response]
- [Topic 2]: [response]
- Chosen approach: [name] — [brief description]
[Any follow-up responses from "Other" selections]
```

Pass the combined context (interview responses + chosen approach) to the Task delegation prompt as "Interview Context".

## Execute Design (Team-Based)

<mandatory>
**Design uses Claude Code Teams for execution, matching the standard team lifecycle pattern.**

You MUST follow the full team lifecycle below. Use `architect-reviewer` as the teammate subagent type.
</mandatory>

### Step 1: Check for Orphaned Team

```text
1. Read ~/.claude/teams/design-$spec/config.json
2. If exists: TeamDelete() to clean up orphaned team from a previous interrupted session
```

### Step 2: Create Team

```text
TeamCreate(team_name: "design-$spec", description: "Design for $spec")
```

**Fallback**: If TeamCreate fails, fall back to direct `Task(subagent_type: architect-reviewer)` call, skipping Steps 3-6 and 8.

### Step 3: Create Tasks

```text
TaskCreate(
  subject: "Generate technical design for $spec",
  description: "Architect-reviewer generates design.md from requirements and research. See Step 4 for full prompt.",
  activeForm: "Generating design"
)
```

### Step 4: Spawn Teammates

```text
Task(subagent_type: architect-reviewer, team_name: "design-$spec", name: "architect-1",
  prompt: "You are creating technical design for spec: $spec
    Spec path: ./specs/$spec/

    Context:
    - Requirements: [include requirements.md content]
    - Research: [include research.md if exists]

    [If interview was conducted, include:]
    Interview Context:
    $interview_context

    Your task:
    1. Read and understand all requirements
    2. Explore the codebase for existing patterns to follow
    3. Design architecture with mermaid diagrams
    4. Define component responsibilities and interfaces
    5. Document technical decisions with rationale
    6. Plan file structure (create/modify)
    7. Define error handling and edge cases
    8. Create test strategy
    9. Output to ./specs/$spec/design.md
    10. Include interview responses in a 'Design Inputs' section of design.md

    Use the design.md template with frontmatter:
    ---
    spec: $spec
    phase: design
    created: <timestamp>
    ---

    Include:
    - Architecture diagram (mermaid)
    - Data flow diagram (mermaid sequence)
    - Technical decisions table
    - File structure matrix
    - TypeScript interfaces
    - Error handling table
    - Test strategy

    When done, mark your task complete via TaskUpdate.")
```

### Step 5: Wait for Completion

Wait for teammate message or check TaskList until task status is "completed".

**Timeout**: If stalled, retry with a direct Task call.

### Step 6: Shutdown Teammates

```text
SendMessage(type: "shutdown_request", recipient: "architect-1", content: "Design complete")
```

### Step 7: Collect Results

Read `./specs/$spec/design.md`.

### Step 8: Clean Up Team

```text
TeamDelete()
```

If TeamDelete fails, log warning. Orphaned teams are cleaned up via Step 1 on next invocation.

## Artifact Review

<mandatory>
**Review loop must complete before walkthrough. Max 3 iterations.**

**Skip review if `--quick` flag detected in `$ARGUMENTS`.** If `--quick` is present, skip directly to "Walkthrough (Before Review)".
</mandatory>

After the architect-reviewer completes design.md and before presenting the walkthrough, invoke the `spec-reviewer` agent to validate the artifact.

### Review Loop

```text
Set iteration = 1

WHILE iteration <= 3:
  1. Read ./specs/$spec/design.md content
  2. Invoke spec-reviewer via Task tool (see delegation prompt below)
  3. Parse the last line of spec-reviewer output for signal:
     - If output contains "REVIEW_PASS":
       a. Log review iteration to .progress.md (see Review Iteration Logging below)
       b. Break loop, proceed to Walkthrough
     - If output contains "REVIEW_FAIL" AND iteration < 3:
       a. Log review iteration to .progress.md (see Review Iteration Logging below)
       b. Extract "Feedback for Revision" from reviewer output
       c. Re-invoke architect-reviewer with revision prompt (see below)
       d. Re-read design.md (now updated)
       e. iteration = iteration + 1
       f. Continue loop
     - If output contains "REVIEW_FAIL" AND iteration >= 3:
       a. Log review iteration to .progress.md (see Review Iteration Logging below)
       b. Append warnings to .progress.md (see Graceful Degradation below)
       c. Break loop, proceed to Walkthrough
     - If output contains NEITHER signal (reviewer error):
       a. Treat as REVIEW_PASS (permissive)
       b. Log review iteration to .progress.md with status "REVIEW_PASS (no signal)"
       c. Break loop, proceed to Walkthrough
```

### Review Iteration Logging

After each review iteration (regardless of outcome), append to `./specs/$spec/.progress.md`:

```markdown
### Review: design (Iteration $iteration)
- Status: REVIEW_PASS or REVIEW_FAIL
- Findings: [summary of key findings from spec-reviewer output]
- Action: [revision applied / warnings appended / proceeded]
```

Where:
- **Status**: The actual signal from the reviewer (REVIEW_PASS or REVIEW_FAIL)
- **Findings**: A brief summary of the reviewer's findings (2-3 bullet points max)
- **Action**: What was done in response:
  - "revision applied" if REVIEW_FAIL and iteration < 3 (re-invoked architect-reviewer)
  - "warnings appended, proceeded" if REVIEW_FAIL and iteration >= 3 (graceful degradation)
  - "proceeded" if REVIEW_PASS

### Review Delegation Prompt

Invoke spec-reviewer via Task tool:

```yaml
subagent_type: spec-reviewer

You are reviewing the design artifact for spec: $spec
Spec path: ./specs/$spec/

Review iteration: $iteration of 3

Artifact content:
[Full content of ./specs/$spec/design.md]

Upstream artifacts (for cross-referencing):
[Full content of ./specs/$spec/research.md]
[Full content of ./specs/$spec/requirements.md]

$priorFindings

Apply the design rubric. Output structured findings with REVIEW_PASS or REVIEW_FAIL.

If REVIEW_FAIL, provide specific, actionable feedback for revision. Reference line numbers or sections.
```

Where `$priorFindings` is empty on iteration 1, or on subsequent iterations:
```text
Prior findings (from iteration $prevIteration):
[Full findings output from previous spec-reviewer invocation]
```

### Revision Delegation Prompt

On REVIEW_FAIL, re-invoke architect-reviewer with feedback:

```yaml
subagent_type: architect-reviewer

You are revising the technical design for spec: $spec
Spec path: ./specs/$spec/

Current artifact: ./specs/$spec/design.md

Upstream context:
[Full content of ./specs/$spec/requirements.md]

Reviewer feedback (iteration $iteration):
$reviewerFindings

Your task:
1. Read the current design.md
2. Read requirements.md for upstream context
3. Address each finding from the reviewer
4. Update the artifact to resolve all issues
5. Write the revised content to ./specs/$spec/design.md

Focus on the specific issues flagged. Do not rewrite sections that passed review.
```

After the architect-reviewer returns, re-read `./specs/$spec/design.md` (now updated) and loop back to invoke spec-reviewer again.

### Graceful Degradation

If max iterations (3) reached without REVIEW_PASS, append to `./specs/$spec/.progress.md`:

```markdown
### Review Warning: design
- Max iterations (3) reached without REVIEW_PASS
- Proceeding with best available version
- Outstanding issues: [list from last REVIEW_FAIL findings]
```

Then proceed to Walkthrough.

### Error Handling

- **Reviewer fails to output signal**: treat as REVIEW_PASS (permissive) and log with status "REVIEW_PASS (no signal)"
- **Phase agent fails during revision**: retry the revision once; if it fails again, use the original artifact and proceed
- **Iteration counter edge cases**: if iteration is missing or invalid, default to 1

## Walkthrough (Before Review)

<mandatory>
**WALKTHROUGH IS REQUIRED - DO NOT SKIP THIS SECTION.**

After design.md is created, you MUST display a concise walkthrough BEFORE asking review questions.

1. Read `./specs/$spec/design.md`
2. Display the walkthrough below with actual content from the file

### Display Format

```
Design complete for '$spec'.
Output: ./specs/$spec/design.md

## What I Designed

**Approach**: [1-2 sentences from Overview - the core approach]

**Components**:
- [Component A]: [brief purpose]
- [Component B]: [brief purpose]
[list main components]

**Key Decisions**:
- [Decision 1]: [choice made]
- [Decision 2]: [choice made]

**Files**: [X] to create, [Y] to modify
```

Keep it scannable. User will open the file if they want details.
</mandatory>

## Review & Feedback Loop

<mandatory>
**Skip review if --quick flag detected in $ARGUMENTS.**

If NOT quick mode, conduct design review using AskUserQuestion after design is created.
</mandatory>

### Quick Mode Check

Check if `--quick` appears anywhere in `$ARGUMENTS`. If present, skip directly to "Update State".

### Design Review Question

After displaying the walkthrough, ask ONE simple question:

| Question | Key | Options |
|----------|-----|---------|
| Does this look right? | `designApproval` | Approve (Recommended) / Need changes / Other |

### Handle Response

**If "Approve"**: Skip to "Update State"

**If "Need changes" or "Other"**:
1. Ask: "What would you like changed?"
2. Re-invoke architect-reviewer using the team pattern (cleanup-and-recreate)
3. Re-display walkthrough
4. Ask approval question again
5. Loop until approved

<mandatory>
**Feedback Loop Team Pattern: Cleanup-and-Recreate**

When the user requests changes, do NOT reuse the existing team or send messages to completed teammates.
Instead, use the cleanup-and-recreate approach for each feedback iteration:

1. `TeamDelete()` the current team (cleanup previous session)
2. `TeamCreate()` a new team with the same name (fresh team for re-invocation)
3. `TaskCreate` with updated prompt including user feedback
4. Spawn new teammate, wait for completion, shutdown, `TeamDelete`

This is simpler and more reliable than trying to reuse teams or message completed teammates.
Each feedback iteration gets a completely fresh team context.
</mandatory>

**Re-invoke architect-reviewer with team lifecycle (cleanup-and-recreate):**

Repeat Steps 1-8 from "Execute Design" above, with these changes:
- Step 3 subject: "Update design for $spec"
- Step 4 prompt: Include `$user_feedback` and instruct the architect to read existing design.md, address the feedback, maintain consistency with requirements, update design.md, and append update notes to .progress.md.

**After update, repeat review questions** (go back to "Design Review Question")

**Continue until approved:** Loop until user responds with approval

## Update State

After design complete and approved:

1. Update `.ralph-state.json`:
   ```json
   {
     "phase": "design",
     "awaitingApproval": true,
     ...
   }
   ```

2. Update `.progress.md`:
   - Mark requirements as implicitly approved
   - Set current phase to design

## Commit Spec (if enabled)

Read `commitSpec` from `.ralph-state.json` (set during `/ralph-specum:start`).

If `commitSpec` is true:

1. Stage design file:
   ```bash
   git add ./specs/$spec/design.md
   ```
2. Commit with message:
   ```bash
   git commit -m "spec($spec): add technical design"
   ```
3. Push to current branch:
   ```bash
   git push -u origin $(git branch --show-current)
   ```

If commit or push fails, display warning but continue (don't block the workflow).

## Stop

<mandatory>
**STOP HERE. DO NOT PROCEED TO TASKS.**

(This does not apply in `--quick` mode, which auto-generates all artifacts without stopping.)

After the review is approved and state is updated, you MUST:
1. Display: `→ Next: Run /ralph-specum:tasks`
2. End your response immediately
3. Wait for user to explicitly run `/ralph-specum:tasks`

DO NOT automatically invoke the task-planner or run the tasks phase.
</mandatory>
