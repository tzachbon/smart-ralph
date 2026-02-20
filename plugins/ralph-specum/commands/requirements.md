---
description: Generate requirements from goal and research
argument-hint: [spec-name]
allowed-tools: "*"
---

# Requirements Phase

Generate requirements for the active spec. Running this command implicitly approves research. You are a **coordinator, not a product manager** -- delegate ALL work to the `product-manager` subagent.

## Checklist

Create a task for each item and complete in order:

1. **Gather context** -- resolve spec, read research and goal
2. **Interview** -- brainstorming dialogue (skip if `--quick`)
3. **Execute requirements** -- dispatch product-manager via team
4. **Artifact review** -- spec-reviewer validation loop (skip if `--quick`)
5. **Walkthrough & approval** -- display summary, get user approval
6. **Finalize** -- update state, commit, stop

## Step 1: Gather Context

1. If `$ARGUMENTS` contains a spec name, use `ralph_find_spec()` to resolve it; otherwise use `ralph_resolve_current()`
2. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."
3. Check the resolved spec directory exists
4. Read `.ralph-state.json`; clear approval flag: `awaitingApproval: false`
5. Read context: `research.md` (if exists), `.progress.md`, original goal

## Step 2: Interview (skip if --quick)

Check if `--quick` appears in `$ARGUMENTS`. If present, skip to Step 3.

### Read Context from .progress.md

Parse Intent Classification and prior interview responses to skip already-answered questions.

**Intent-Based Question Counts:**
- TRIVIAL: 1-2 | REFACTOR: 3-5 | GREENFIELD: 5-10 | MID_SIZED: 3-7

### Brainstorming Dialogue

Apply adaptive dialogue from `skills/interview-framework/SKILL.md`. Ask context-driven questions one at a time.

**Requirements Exploration Territory** (hints, not a script):
- **Primary users** -- who will use this feature? Developers, end users, specific roles?
- **Priority tradeoffs** -- speed of delivery vs code quality vs feature completeness
- **Success criteria** -- what does success look like? Metrics, behaviors, user outcomes
- **Scope boundaries** -- what is explicitly out of scope for this iteration?
- **Compliance or regulatory needs** -- security, privacy, or regulatory considerations?

### Requirements Approach Proposals

After dialogue, propose 2-3 scoping approaches. Examples (illustrative only):
- **(A)** Full feature set -- comprehensive user stories covering all use cases
- **(B)** MVP scope -- core user stories only, defer edge cases to v2
- **(C)** Phased delivery -- essential stories now, planned expansion later

### Store Interview & Approach

Append to `.progress.md` under "Interview Responses":
```markdown
### Requirements Interview (from requirements.md)
- [Topic 1]: [response]
- Chosen approach: [name] -- [brief description]
```

Pass combined context to delegation prompt as "Interview Context".

## Step 3: Execute Requirements (Team-Based)

<mandatory>
**Use Claude Code Teams with `product-manager` as the teammate subagent type.**

Follow the full team lifecycle:

1. **Check orphaned team**: Read `~/.claude/teams/requirements-$spec/config.json`. If exists, `TeamDelete()`.
2. **Create team**: `TeamCreate(team_name: "requirements-$spec")`
3. **Create task**: `TaskCreate(subject: "Generate requirements for $spec", activeForm: "Generating requirements")`
4. **Spawn teammate**: Delegate to product-manager with research context, goal, and interview context. Instruct to create user stories with acceptance criteria, functional requirements (FR-*), non-functional requirements (NFR-*), glossary, out-of-scope, dependencies. Output to `./specs/$spec/requirements.md`.
5. **Wait for completion**: Monitor via TaskList.
6. **Shutdown**: `SendMessage(type: "shutdown_request", recipient: "pm-1")`
7. **Collect results**: Read `./specs/$spec/requirements.md`.
8. **Clean up**: `TeamDelete()`.

**Fallback**: If TeamCreate fails, fall back to direct `Task(subagent_type: product-manager)` call.
</mandatory>

## Step 4: Artifact Review (skip if --quick)

<mandatory>
**Review loop must complete before walkthrough. Max 3 iterations.**

If `--quick`, skip to Step 5.

Invoke `spec-reviewer` via Task tool. Follow the standard review loop:
- REVIEW_PASS: log to .progress.md, proceed
- REVIEW_FAIL (iteration < 3): log, re-invoke product-manager with feedback, loop
- REVIEW_FAIL (iteration >= 3): graceful degradation, log warning, proceed
- No signal: treat as REVIEW_PASS (permissive)

**Review delegation**: Include full requirements.md content, iteration count, prior findings. Upstream: research.md.

**Revision delegation**: Re-invoke product-manager with reviewer feedback. Focus on specific issues.

**Error handling**: Reviewer no signal = REVIEW_PASS. Agent failure = retry once, then use original.
</mandatory>

## Step 5: Walkthrough & Approval

<mandatory>
**WALKTHROUGH IS REQUIRED - DO NOT SKIP.**

Read `./specs/$spec/requirements.md` and display:

```
Requirements complete for '$spec'.
Output: ./specs/$spec/requirements.md

## What I Created

**Goal**: [1 sentence summary]

**User Stories** ([count] total):
- US-1: [title]
- US-2: [title]
- US-3: [title]
[list all, keep titles brief]

**Requirements**: [X] functional, [Y] non-functional
```
</mandatory>

### User Approval (skip if --quick)

If `--quick`, skip to Step 6.

Ask ONE question: "Does this look right?" with options: Approve (Recommended) / Need changes / Other

**If "Approve"**: proceed to Step 6.
**If "Need changes" or "Other"**:
1. Ask what to change
2. Re-invoke product-manager using **cleanup-and-recreate** team pattern (TeamDelete old -> TeamCreate new -> spawn with feedback -> wait -> shutdown -> TeamDelete)
3. Re-display walkthrough, ask again. Loop until approved.

## Step 6: Finalize

### Update State

1. Update `.ralph-state.json`: `{ "phase": "requirements", "awaitingApproval": true }`
2. Update `.progress.md`: mark research as implicitly approved, set current phase

### Commit Spec (if enabled)

Read `commitSpec` from `.ralph-state.json`. If true:
```bash
git add ./specs/$spec/requirements.md
git commit -m "spec($spec): add requirements"
git push -u origin $(git branch --show-current)
```
If commit or push fails, display warning but continue.

### Stop

<mandatory>
**STOP HERE. DO NOT PROCEED TO DESIGN.**

(Does not apply in `--quick` mode.)

1. Display: `-> Next: Run /ralph-specum:design`
2. End your response immediately
3. Wait for user to explicitly run `/ralph-specum:design`
</mandatory>
