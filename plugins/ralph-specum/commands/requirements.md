---
description: Generate requirements from goal and research
argument-hint: [spec-name]
allowed-tools: "*"
---

# Requirements Phase

You are generating requirements for a specification. Running this command implicitly approves the research phase.

<mandatory>
**YOU ARE A COORDINATOR, NOT A PRODUCT MANAGER.**

You MUST delegate ALL requirements work to the `product-manager` subagent.
Do NOT write user stories, acceptance criteria, or requirements.md yourself.
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
2. Read `.ralph-state.json`
3. Clear approval flag: update state with `awaitingApproval: false`

## Gather Context

Read available context:
- `./specs/$spec/research.md` (if exists)
- `./specs/$spec/.progress.md`
- Original goal from conversation or progress file

## Interview

<mandatory>
**Skip interview if --quick flag detected in $ARGUMENTS.**

If NOT quick mode, conduct interview using AskUserQuestion before delegating to subagent.
</mandatory>

### Quick Mode Check

Check if `--quick` appears anywhere in `$ARGUMENTS`. If present, skip directly to "Execute Requirements".

### Read Context from .progress.md

Before conducting the interview, read `.progress.md` to get:
1. **Intent Classification** from start.md (TRIVIAL, REFACTOR, GREENFIELD, MID_SIZED)
2. **Prior interview responses** to enable parameter chain (skip already-answered questions)

```text
Context Reading:
1. Read ./specs/$spec/.progress.md
2. Parse "## Intent Classification" section for intent type and question counts
3. Parse "## Interview Responses" section for prior answers (Goal Interview, Research Interview)
4. Store parsed data for parameter chain checks
```

**Intent-Based Question Counts (same as start.md):**
- TRIVIAL: 1-2 questions (minimal user/priority context needed)
- REFACTOR: 3-5 questions (understand scope and priorities)
- GREENFIELD: 5-10 questions (full user and priority context)
- MID_SIZED: 3-7 questions (balanced approach)

### Brainstorming Dialogue

**Brainstorming Dialogue**: Apply adaptive dialogue from `skills/interview-framework/SKILL.md`

The coordinator asks context-driven questions one at a time based on the exploration territory below and what's already in `.progress.md`. Questions adapt to prior answers. After enough understanding, propose approaches.

### Requirements Exploration Territory

Areas to probe during the UNDERSTAND phase (hints, not a script):

- **Primary users** — who will use this feature? Developers, end users, specific roles, both?
- **Priority tradeoffs** — speed of delivery vs code quality vs feature completeness
- **Success criteria** — what does success look like? Metrics, behaviors, user outcomes
- **Scope boundaries** — what is explicitly out of scope for this iteration?
- **Compliance or regulatory needs** — any security, privacy, or regulatory considerations?

### Requirements Approach Proposals

After the dialogue, propose 2-3 scoping approaches tailored to the user's goal. Examples (illustrative only):

- **(A)** Full feature set — comprehensive user stories covering all use cases
- **(B)** MVP scope — core user stories only, defer edge cases to v2
- **(C)** Phased delivery — essential stories now, planned expansion later

### Store Interview & Approach

After interview and approach selection, append to `.progress.md` under the "Interview Responses" section:

```markdown
### Requirements Interview (from requirements.md)
- [Topic 1]: [response]
- [Topic 2]: [response]
- Chosen approach: [name] — [brief description]
[Any follow-up responses from "Other" selections]
```

Pass the combined context (interview responses + chosen approach) to the Task delegation prompt as "Interview Context".

## Execute Requirements (Team-Based)

<mandatory>
**Requirements uses Claude Code Teams for execution, matching the standard team lifecycle pattern.**

You MUST follow the full team lifecycle below. Use `product-manager` as the teammate subagent type.
</mandatory>

### Step 1: Check for Orphaned Team

```text
1. Read ~/.claude/teams/requirements-$spec/config.json
2. If exists: TeamDelete() to clean up orphaned team from a previous interrupted session
```

### Step 2: Create Team

```text
TeamCreate(team_name: "requirements-$spec", description: "Requirements for $spec")
```

**Fallback**: If TeamCreate fails, log a warning and fall back to a direct `Task(subagent_type: product-manager)` call without a team. Skip Steps 3-6 and 8, and delegate directly via bare Task call.

### Step 3: Create Tasks

```text
TaskCreate(
  subject: "Generate requirements for $spec",
  description: "Product-manager generates requirements.md from research and interview context. See Step 4 for full prompt.",
  activeForm: "Generating requirements"
)
```

### Step 4: Spawn Teammates

```yaml
Task(subagent_type: product-manager, team_name: "requirements-$spec", name: "pm-1",
  prompt: "You are a requirements teammate for spec: $spec
    Spec path: ./specs/$spec/

    Context:
    - Research: [include research.md content if exists]
    - Original goal: [from conversation or progress]

    [If interview was conducted, include:]
    Interview Context:
    $interview_context

    Your task:
    1. Analyze the goal and research findings
    2. Create user stories with acceptance criteria
    3. Define functional requirements (FR-*) with priorities
    4. Define non-functional requirements (NFR-*)
    5. Document glossary, out-of-scope items, dependencies
    6. Output to ./specs/$spec/requirements.md
    7. Include interview responses in a 'User Decisions' section of requirements.md

    Use the requirements.md template with frontmatter:
    ---
    spec: $spec
    phase: requirements
    created: <timestamp>
    ---

    Focus on:
    - Testable acceptance criteria
    - Clear priority levels
    - Explicit success criteria
    - Risk identification

    When done, mark your task complete via TaskUpdate.")
```

### Step 5: Wait for Completion

Wait for teammate message or TaskList showing status: "completed".

**Timeout**: If stalled, check TaskList and retry with a direct Task call.

### Step 6: Shutdown Teammates

```text
SendMessage(
  type: "shutdown_request",
  recipient: "pm-1",
  content: "Requirements complete, shutting down"
)
```

### Step 7: Collect Results

Read `./specs/$spec/requirements.md` from the teammate.

### Step 8: Clean Up Team

`TeamDelete()` — If it fails, log a warning; Step 1 will clean up on next invocation.

## Artifact Review

<mandatory>
**Review loop must complete before walkthrough. Max 3 iterations.**

**Skip review if `--quick` flag detected in `$ARGUMENTS`.** If `--quick` is present, skip directly to "Walkthrough (Before Review)".
</mandatory>

After the product-manager generates requirements.md and before presenting the walkthrough, invoke the `spec-reviewer` agent to validate the artifact.

### Review Loop

```text
Set iteration = 1

WHILE iteration <= 3:
  1. Read ./specs/$spec/requirements.md content
  2. Invoke spec-reviewer via Task tool (see delegation prompt below)
  3. Parse the last line of spec-reviewer output for signal:
     - If output contains "REVIEW_PASS":
       a. Log review iteration to .progress.md (see Review Iteration Logging below)
       b. Break loop, proceed to Walkthrough
     - If output contains "REVIEW_FAIL" AND iteration < 3:
       a. Log review iteration to .progress.md (see Review Iteration Logging below)
       b. Extract "Feedback for Revision" from reviewer output
       c. Re-invoke product-manager with revision prompt (see below)
       d. Re-read updated requirements.md
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
### Review: requirements (Iteration $iteration)
- Status: REVIEW_PASS or REVIEW_FAIL
- Findings: [summary of key findings from spec-reviewer output]
- Action: [revision applied / warnings appended / proceeded]
```

Where:
- **Status**: The actual signal from the reviewer (REVIEW_PASS or REVIEW_FAIL)
- **Findings**: A brief summary of the reviewer's findings (2-3 bullet points max)
- **Action**: What was done in response:
  - "revision applied" if REVIEW_FAIL and iteration < 3 (re-invoked product-manager)
  - "warnings appended, proceeded" if REVIEW_FAIL and iteration >= 3 (graceful degradation)
  - "proceeded" if REVIEW_PASS

### Review Delegation Prompt

Invoke spec-reviewer via Task tool:

```yaml
subagent_type: spec-reviewer

You are reviewing the requirements artifact for spec: $spec
Spec path: ./specs/$spec/

Review iteration: $iteration of 3

Artifact content:
[Full content of ./specs/$spec/requirements.md]

Upstream artifacts (for cross-referencing):
[Full content of ./specs/$spec/research.md]

$priorFindings

Apply the requirements rubric. Output structured findings with REVIEW_PASS or REVIEW_FAIL.

If REVIEW_FAIL, provide specific, actionable feedback for revision. Reference line numbers or sections.
```

Where `$priorFindings` is empty on iteration 1, or on subsequent iterations:
```text
Prior findings (from iteration $prevIteration):
[Full findings output from previous spec-reviewer invocation]
```

### Revision Delegation Prompt

On REVIEW_FAIL, re-invoke product-manager with feedback:

```yaml
subagent_type: product-manager

You are revising the requirements for spec: $spec
Spec path: ./specs/$spec/

Current artifact: ./specs/$spec/requirements.md

Reviewer feedback (iteration $iteration):
$reviewerFindings

Your task:
1. Read the current requirements.md
2. Address each finding from the reviewer
3. Update the artifact to resolve all issues
4. Write the revised content to ./specs/$spec/requirements.md

Focus on the specific issues flagged. Do not rewrite sections that passed review.
```

After the product-manager returns, re-read `./specs/$spec/requirements.md` (now updated) and loop back to invoke spec-reviewer again.

### Graceful Degradation

If max iterations (3) reached without REVIEW_PASS, append to `./specs/$spec/.progress.md`:

```markdown
### Review Warning: requirements
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

After requirements.md is created, you MUST display a concise walkthrough BEFORE asking review questions.

1. Read `./specs/$spec/requirements.md`
2. Display the walkthrough below with actual content from the file

### Display Format

```text
Requirements complete for '$spec'.
Output: ./specs/$spec/requirements.md

## What I Created

**Goal**: [1 sentence summary of the goal]

**User Stories** ([count] total):
- US-1: [title]
- US-2: [title]
- US-3: [title]
[list all, keep titles brief]

**Requirements**: [X] functional, [Y] non-functional
```

Keep it scannable. User will open the file if they want details.
</mandatory>

## Review & Feedback Loop

<mandatory>
**Skip review if --quick flag detected in $ARGUMENTS.**

If NOT quick mode, conduct requirements review using AskUserQuestion after requirements are created.
</mandatory>

### Quick Mode Check

Check if `--quick` appears anywhere in `$ARGUMENTS`. If present, skip directly to "Update State".

### Requirements Review Question

After displaying the walkthrough, ask ONE simple question:

| Question | Key | Options |
|----------|-----|---------|
| Does this look right? | `requirementsApproval` | Approve (Recommended) / Need changes / Other |

### Handle Response

**If "Approve"**: Skip to "Update State"

**If "Need changes" or "Other"**:
1. Ask: "What would you like changed?"
2. Re-invoke product-manager using the team pattern (cleanup-and-recreate)
3. Re-display walkthrough
4. Ask approval question again
5. Loop until approved

<mandatory>
**Feedback Loop Team Pattern: Cleanup-and-Recreate**

When the user requests changes, do NOT reuse the existing team. Instead, repeat Steps 1-8 from "Execute Requirements" above with these modifications:
- Step 3 description: "Update requirements based on user feedback"
- Step 4 prompt: Include `$user_feedback` and instruct the product-manager to read existing requirements.md, address feedback, maintain consistency with research, and append update notes to .progress.md
- All other steps remain the same
</mandatory>

**After update, repeat review questions** (go back to "Requirements Review Question")

**Continue until approved:** Loop until user responds with approval

## Update State

After requirements complete and approved:

1. Update `.ralph-state.json`:
   ```json
   {
     "phase": "requirements",
     "awaitingApproval": true,
     ...
   }
   ```

2. Update `.progress.md`:
   - Mark research as implicitly approved
   - Set current phase to requirements

## Commit Spec (if enabled)

Read `commitSpec` from `.ralph-state.json` (set during `/ralph-specum:start`).

If `commitSpec` is true:

1. Stage requirements file:
   ```bash
   git add ./specs/$spec/requirements.md
   ```
2. Commit with message:
   ```bash
   git commit -m "spec($spec): add requirements"
   ```
3. Push to current branch:
   ```bash
   git push -u origin $(git branch --show-current)
   ```

If commit or push fails, display warning but continue (don't block the workflow).

## Stop

<mandatory>
**STOP HERE. DO NOT PROCEED TO DESIGN.**

(This does not apply in `--quick` mode, which auto-generates all artifacts without stopping.)

After the review is approved and state is updated, you MUST:
1. Display: `→ Next: Run /ralph-specum:design`
2. End your response immediately
3. Wait for user to explicitly run `/ralph-specum:design`

DO NOT automatically invoke the architect-reviewer or run the design phase.
</mandatory>
