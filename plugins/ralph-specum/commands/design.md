---
description: Generate technical design from requirements
argument-hint: [spec-name]
allowed-tools: "*"
---

# Design Phase

Generate technical design for the active spec. Running this command implicitly approves requirements. You are a **coordinator, not an architect** -- delegate ALL work to the `architect-reviewer` subagent.

## Checklist

Create a task for each item and complete in order:

1. **Gather context** -- resolve spec, read requirements and research
2. **Interview** -- brainstorming dialogue (skip if `--quick`)
3. **Execute design** -- dispatch architect-reviewer via team
4. **Artifact review** -- spec-reviewer validation loop (skip if `--quick`)
5. **Walkthrough & approval** -- display summary, get user approval
6. **Finalize** -- update state, commit, stop

## Step 1: Gather Context

1. If `$ARGUMENTS` contains a spec name, use `ralph_find_spec()` to resolve it; otherwise use `ralph_resolve_current()`
2. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."
3. Check the resolved spec directory exists
4. Check `requirements.md` exists. If not, error: "Requirements not found. Run /ralph-specum:requirements first."
5. Read `.ralph-state.json`; clear approval flag: `awaitingApproval: false`
6. Read context: `requirements.md` (required), `research.md` (if exists), `.progress.md`

## Step 2: Interview (skip if --quick)

Check if `--quick` appears in `$ARGUMENTS`. If present, skip to Step 3.

### Read Context from .progress.md

Parse Intent Classification and all prior interview responses to skip already-answered questions.

**Intent-Based Question Counts:**
- TRIVIAL: 1-2 | REFACTOR: 3-5 | GREENFIELD: 5-10 | MID_SIZED: 3-7

### Brainstorming Dialogue

Apply adaptive dialogue from `${CLAUDE_PLUGIN_ROOT}/skills/interview-framework/SKILL.md`. Ask context-driven questions one at a time.

**Design Exploration Territory** (hints, not a script):
- **Architecture fit** -- extend existing architecture, create isolated module, or require refactor?
- **Technology constraints** -- any required or forbidden libraries, frameworks, or patterns?
- **Integration tightness** -- how tightly should this integrate with existing systems?
- **Failure modes** -- what failure scenarios matter? Graceful degradation, retry logic, alerting?
- **Deployment model** -- feature flags, gradual rollout, migrations, or big-bang?

### Design Approach Proposals

After dialogue, propose 2-3 architectural approaches. Examples (illustrative only):
- **(A)** Extend existing service/module layer -- minimal new abstractions
- **(B)** New isolated component -- clean boundaries, own data layer
- **(C)** Hybrid -- new module with shared infrastructure and data layer

### Store Interview & Approach

Append to `.progress.md` under "Interview Responses":
```markdown
### Design Interview (from design.md)
- [Topic 1]: [response]
- Chosen approach: [name] -- [brief description]
```

Pass combined context to delegation prompt as "Interview Context".

## Step 3: Execute Design (Team-Based)

<mandatory>
**Use Claude Code Teams with `architect-reviewer` as the teammate subagent type.**

Follow the full team lifecycle:

1. **Check orphaned team**: Read `~/.claude/teams/design-$spec/config.json`. If exists, `TeamDelete()`.
2. **Create team**: `TeamCreate(team_name: "design-$spec")`
3. **Create task**: `TaskCreate(subject: "Generate technical design for $spec", activeForm: "Generating design")`
4. **Spawn teammate**: Delegate to architect-reviewer with requirements, research, and interview context. Instruct to design architecture with mermaid diagrams, component responsibilities, technical decisions with rationale, file structure, error handling, test strategy. Output to `./specs/$spec/design.md`.
5. **Wait for completion**: Monitor via TaskList.
6. **Shutdown**: `SendMessage(type: "shutdown_request", recipient: "architect-1")`
7. **Collect results**: Read `./specs/$spec/design.md`.
8. **Clean up**: `TeamDelete()`.

**Fallback**: If TeamCreate fails, fall back to direct `Task(subagent_type: architect-reviewer)` call.
</mandatory>

## Step 4: Artifact Review (skip if --quick)

<mandatory>
**Review loop must complete before walkthrough. Max 3 iterations.**

If `--quick`, skip to Step 5.

Invoke `spec-reviewer` via Task tool. Follow the standard review loop:
- REVIEW_PASS: log to .progress.md, proceed
- REVIEW_FAIL (iteration < 3): log, re-invoke architect-reviewer with feedback, loop
- REVIEW_FAIL (iteration >= 3): graceful degradation, log warning, proceed
- No signal: treat as REVIEW_PASS (permissive)

**Review delegation**: Include full design.md content, iteration count, prior findings. Upstream: research.md + requirements.md.

**Revision delegation**: Re-invoke architect-reviewer with reviewer feedback and requirements.md upstream context. Focus on specific issues.

**Error handling**: Reviewer no signal = REVIEW_PASS. Agent failure = retry once, then use original.
</mandatory>

## Step 5: Walkthrough & Approval

<mandatory>
**WALKTHROUGH IS REQUIRED - DO NOT SKIP.**

Read `./specs/$spec/design.md` and display:

```
Design complete for '$spec'.
Output: ./specs/$spec/design.md

## What I Designed

**Approach**: [1-2 sentences from Overview]

**Components**:
- [Component A]: [brief purpose]
- [Component B]: [brief purpose]

**Key Decisions**:
- [Decision 1]: [choice made]
- [Decision 2]: [choice made]

**Files**: [X] to create, [Y] to modify
```
</mandatory>

### User Approval (skip if --quick)

If `--quick`, skip to Step 6.

Ask ONE question: "Does this look right?" with options: Approve (Recommended) / Need changes / Other

**If "Approve"**: proceed to Step 6.
**If "Need changes" or "Other"**:
1. Ask what to change
2. Re-invoke architect-reviewer using **cleanup-and-recreate** team pattern (TeamDelete old -> TeamCreate new -> spawn with feedback -> wait -> shutdown -> TeamDelete)
3. Re-display walkthrough, ask again. Loop until approved.

## Step 6: Finalize

### Update State

1. Update `.ralph-state.json`: `{ "phase": "design", "awaitingApproval": true }`
2. Update `.progress.md`: mark requirements as implicitly approved, set current phase

### Commit Spec (if enabled)

Read `commitSpec` from `.ralph-state.json`. If true:
```bash
git add ./specs/$spec/design.md
git commit -m "spec($spec): add technical design"
git push -u origin $(git branch --show-current)
```
If commit or push fails, display warning but continue.

### Stop

<mandatory>
**STOP HERE. DO NOT PROCEED TO TASKS.**

(Does not apply in `--quick` mode.)

1. Display: `-> Next: Run /ralph-specum:tasks`
2. End your response immediately
3. Wait for user to explicitly run `/ralph-specum:tasks`
</mandatory>
