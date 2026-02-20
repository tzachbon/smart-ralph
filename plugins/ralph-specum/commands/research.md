---
description: Run or re-run research phase for current spec
argument-hint: [spec-name]
allowed-tools: "*"
---

# Research Phase

Run parallel research for the active spec. You are a **coordinator, not a researcher** -- delegate ALL work to subagents.

## Checklist

Create a task for each item and complete in order:

1. **Gather context** -- resolve spec, read goal and existing files
2. **Interview** -- brainstorming dialogue (skip if `--quick`)
3. **Execute parallel research** -- dispatch team of research-analyst + Explore agents
4. **Merge results** -- synthesize partial files into research.md
5. **Artifact review** -- spec-reviewer validation loop (skip if `--quick`)
6. **Walkthrough & approval** -- display summary, get user approval
7. **Finalize** -- update state, commit, stop

## Step 1: Gather Context

1. If `$ARGUMENTS` contains a spec name, use `ralph_find_spec()` to resolve it; otherwise use `ralph_resolve_current()`
2. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."
3. Check the resolved spec directory exists
4. Read `.ralph-state.json` if it exists
5. Read `.progress.md` to understand the goal

## Step 2: Interview (skip if --quick)

Check if `--quick` appears in `$ARGUMENTS`. If present, skip to Step 3.

### Read Context from .progress.md

Read `.progress.md` and parse:
1. **Intent Classification** (TRIVIAL, REFACTOR, GREENFIELD, MID_SIZED) for question counts
2. **Prior interview responses** to skip already-answered questions

**Intent-Based Question Counts:**
- TRIVIAL: 1-2 | REFACTOR: 3-5 | GREENFIELD: 5-10 | MID_SIZED: 3-7

### Brainstorming Dialogue

Apply adaptive dialogue from `skills/interview-framework/SKILL.md`. Ask context-driven questions one at a time, adapting to prior answers.

**Research Exploration Territory** (hints, not a script):
- **Technical approach preference** -- follow existing patterns or introduce new ones?
- **Known constraints** -- performance, compatibility, timeline, budget
- **Integration surface area** -- which systems, services, or APIs does this touch?
- **Prior knowledge** -- what does the user already know vs what needs discovery?
- **Technologies to evaluate or avoid** -- specific libraries, frameworks, or patterns

### Research Approach Proposals

After dialogue, propose 2-3 research strategies. Examples (illustrative only):
- **(A)** Deep dive on specific technology/library comparison
- **(B)** Focus on existing codebase patterns with minimal external research
- **(C)** Broad survey across multiple alternatives before narrowing

### Store Interview & Approach

Append to `.progress.md` under "Interview Responses":
```markdown
### Research Interview (from research.md)
- [Topic 1]: [response]
- Chosen approach: [name] -- [brief description]
```

Pass combined context to subagent delegation as "Interview Context".

## Step 3: Execute Parallel Research (Team-Based)

<mandatory>
**PARALLEL EXECUTION IS MANDATORY - NO EXCEPTIONS.**

Read `${CLAUDE_PLUGIN_ROOT}/references/parallel-research.md` and follow the full dispatch pattern described there.

Key rules:
- Minimum 2 agents (1 research-analyst + 1 Explore). There are ZERO exceptions.
- ALL Task calls MUST be in ONE message for true parallelism
- Each research-analyst handles ONE external topic; each Explore handles ONE codebase concern
- Break external research into MULTIPLE research-analyst teammates (do NOT combine)

**Pre-Step**: Identify and output research topics before spawning:
```
Research topics identified for parallel execution:
1. [Topic name] - [Agent type: research-analyst/Explore]
2. [Topic name] - [Agent type: research-analyst/Explore]
...
```

Follow the full team lifecycle: Check orphaned team -> Create team -> Create tasks -> Spawn teammates (ALL in ONE message) -> Wait -> Shutdown -> Collect results -> Clean up team.

**Fallback**: If TeamCreate fails, fall back to direct Task calls without a team.
</mandatory>

## Step 4: Merge Results

After ALL parallel tasks complete, merge into unified `./specs/$spec/research.md`.

Read `${CLAUDE_PLUGIN_ROOT}/references/parallel-research.md` "Merging Results" section for the exact merge structure and process.

After merge, delete partial files: `rm ./specs/$spec/.research-*.md`

## Step 5: Artifact Review (skip if --quick)

<mandatory>
**Review loop must complete before walkthrough. Max 3 iterations.**

If `--quick`, skip to Step 6.

Invoke `spec-reviewer` via Task tool to validate research.md. Follow the standard review loop:
- REVIEW_PASS: log to .progress.md, proceed to walkthrough
- REVIEW_FAIL (iteration < 3): log, extract feedback, re-invoke research-analyst with revision prompt, re-read, loop
- REVIEW_FAIL (iteration >= 3): log warning to .progress.md (graceful degradation), proceed
- No signal: treat as REVIEW_PASS (permissive)

**Review delegation**: Include full research.md content, iteration count, and prior findings. Upstream: none (research is first artifact).

**Revision delegation**: Re-invoke research-analyst with reviewer feedback. Focus on specific issues flagged.

**Error handling**: Reviewer no signal = REVIEW_PASS. Agent failure during revision = retry once, then use original.
</mandatory>

## Step 6: Walkthrough & Approval

<mandatory>
**WALKTHROUGH IS REQUIRED - DO NOT SKIP.**

Read `./specs/$spec/research.md` and display:

```
Research complete for '$spec'.
Output: ./specs/$spec/research.md

## What I Found

**Summary**: [1-2 sentences from Executive Summary]

**Key Recommendations**:
1. [First recommendation]
2. [Second recommendation]
3. [Third recommendation]

**Feasibility**: [High/Medium/Low] | **Risk**: [High/Medium/Low] | **Effort**: [S/M/L/XL]
```
</mandatory>

### User Approval (skip if --quick)

If `--quick`, skip to Step 7.

Ask ONE question: "Does this look right?" with options: Approve (Recommended) / Need changes / Other

**If "Approve"**: proceed to Step 7.
**If "Need changes" or "Other"**: Ask what to change, invoke subagents with feedback, re-merge, re-display walkthrough, ask again. Loop until approved.

## Step 7: Finalize

### Update State

1. Parse "Related Specs" table from research.md
2. Update `.ralph-state.json`: `{ "phase": "research", "awaitingApproval": true, "relatedSpecs": [...] }`
3. Update `.progress.md` with research completion

### Commit Spec (if enabled)

Read `commitSpec` from `.ralph-state.json`. If true:
```bash
git add ./specs/$spec/research.md
git commit -m "spec($spec): add research findings"
git push -u origin $(git branch --show-current)
```
If commit or push fails, display warning but continue.

### Stop

<mandatory>
**STOP HERE. DO NOT PROCEED TO REQUIREMENTS.**

(Does not apply in `--quick` mode.)

1. Display: `-> Next: Run /ralph-specum:requirements`
2. End your response immediately
3. Wait for user to explicitly run `/ralph-specum:requirements`
</mandatory>
