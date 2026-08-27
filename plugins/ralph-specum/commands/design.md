---
description: Generate technical design from requirements
argument-hint: [spec-name] [--quick|--interactive]
allowed-tools: "*"
---

# Design Phase

Generate technical design for the active spec after explicit requirements artifact approval. You are a **coordinator, not an architect** -- delegate ALL work to the `architect-reviewer` subagent.

Read `${CLAUDE_PLUGIN_ROOT}/references/normal-mode-gates.md` before gathering context.

## Checklist

Create a task for each item and complete in order:

1. **Gather context** -- resolve spec, read requirements and research
2. **Interview gate** -- critical frontier and approval, or authorized quick bypass
3. **Execute design** -- dispatch architect-reviewer via team
4. **Artifact review** -- automatic spec-reviewer loop in authorized quick mode
5. **Walkthrough & approval** -- display summary, get user approval
6. **Finalize** -- update state, commit, stop

## Step 1: Gather Context

1. If `$ARGUMENTS` contains a spec name, use `ralph_find_spec()` to resolve it; otherwise use `ralph_resolve_current()`
2. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."
3. Check the resolved spec directory exists
4. Check `requirements.md` exists. If not, error: "Requirements not found. Run /ralph-specum:requirements first."
5. Read `.ralph-state.json`; verify explicit requirements artifact approval before clearing its artifact approval flag
6. Read context: `requirements.md` (required), `research.md` (if exists), `.progress.md`
7. Reject simultaneous exact `--quick` and `--interactive`. Normalize persistent mode with `phase_gate.py mode` before deciding whether to grill.
8. Run any missing applicable skill discovery pass. When research exists, pass 2 must be present.

## Step 2: Skill Load, Critical Grill, and Approval

If normalized `quickMode` is true, call `begin-interview` for phase `design` and continue to Step 3.

In interactive mode, reload all selected contracts and apply the interview-framework with phase `design`. Candidate critical decisions include architecture boundaries with materially different coupling, failure-policy choices, compatibility or migration commitments, and rollout risk. Inspect existing architecture, libraries, integration seams, deployment tooling, and conventions instead of asking about them.

Ask the whole currently unblocked critical frontier, in calls of at most four questions. Persist partial answers. Apply control-only and bare-skip semantics. Present the design decision brief and require explicit `Approve and delegate`. On approval, run `check-delegation` and launch Step 3 immediately in the same response.

Use `classify-reply` before applying every reply, `revise --decision-id` for final-approval revisions, and `confirm --source approve-and-delegate` only for the explicit approval selection.

## Step 3: Execute Design (Team-Based)

<mandatory>
**Use Claude Code Teams with `architect-reviewer` as the teammate subagent type.**

Follow the full team lifecycle:

1. **Clean up stale team (MANDATORY FIRST ACTION)**: Call `TeamDelete()` before anything else. This releases whatever team the session is currently leading (could be from any prior phase). Errors mean no team was active -- harmless, proceed.
2. **Create team**: `TeamCreate(team_name: "design-$spec")`
3. **Create task**: `TaskCreate(subject: "Generate technical design for $spec", activeForm: "Generating design")`
4. **Spawn teammate**: Immediately run `check-delegation`, then call `Task(subagent_type: architect-reviewer, team_name: "design-$spec", name: "architect-1")`. Include artifact agent ID `architect-1`, the gate marker, full selected-skill manifest, approved decision brief, requirements, and research. Instruct the agent to design architecture with mermaid diagrams, component responsibilities, technical decisions with rationale, file structure, error handling, and test strategy. Output to `./specs/$spec/design.md`.
5. **Wait for completion**: Monitor via TaskList.
6. **Shutdown**: `SendMessage(type: "shutdown_request", recipient: "architect-1")`
7. **Collect results**: Read `./specs/$spec/design.md`.
8. **Clean up**: `TeamDelete()`.

**Fallback**: If TeamCreate fails with "already leading" error, call `TeamDelete()` and retry `TeamCreate` once. If still fails, fall back to direct `Task(subagent_type: architect-reviewer)` call.
</mandatory>

## Step 4: Automatic Artifact Review (authorized quick mode)

<mandatory>
**Review loop must complete before walkthrough. Max 3 iterations.**

If normalized `quickMode` is false, skip to Step 5.

Invoke `spec-reviewer` via Task tool. Follow the standard review loop:
- REVIEW_PASS: log to .progress.md, proceed
- REVIEW_FAIL (iteration < 3): log, re-invoke architect-reviewer with feedback, loop
- REVIEW_FAIL (iteration >= 3): graceful degradation, log warning, proceed
- No signal: treat as REVIEW_PASS (permissive)

**Review delegation**: Include full design.md content, iteration count, prior findings. Upstream: research.md + requirements.md.

**Revision delegation**: Run `check-delegation`, create a fresh unique artifact agent ID, and re-invoke architect-reviewer with reviewer feedback, gate marker, manifest, current artifact, and requirements.md. The agent reloads successful sources, records receipts, and checks its write gate. Focus on specific issues.

**Error handling**: Reviewer no signal = REVIEW_PASS. Agent failure = retry once, then use original.
</mandatory>

## Step 5: Walkthrough & Approval

<mandatory>
**WALKTHROUGH IS REQUIRED - DO NOT SKIP.**

Read `./specs/$spec/design.md` and display:

```
Design complete for '$spec'.
Output: $PWD/specs/$spec/design.md

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

### User Approval (interactive mode)

If normalized `quickMode` is true, skip to Step 6.

Ask ONE question: "How do you want to proceed?" with these options via AskUserQuestion:
1. **Approve** (Recommended) -- Accept artifact as-is, advance to next phase
2. **Run review** -- Spawn spec-reviewer to validate against rubrics, show findings, then loop back to this choice
3. **Request changes** -- Provide specific feedback to revise the artifact

**If "Approve"**: proceed to Step 6.
**If "Run review"**: Invoke spec-reviewer via Task tool with full design.md content (upstream: research.md + requirements.md). Display findings table. If REVIEW_PASS, note it. If REVIEW_FAIL, show feedback. Then loop back to this same 3-choice question (user decides next action).
**If "Request changes", "Other", or `apply the changes`**:
1. Apply already-recorded review or revision feedback immediately. Ask one focused change question only when no pending feedback exists.
2. Run `check-delegation`, then re-invoke architect-reviewer using the **cleanup-and-recreate** team pattern with a new unique artifact agent ID, the gate marker, manifest, current artifact, and feedback
3. Re-display walkthrough, ask again with same 3 choices. Loop until approved.

## Step 6: Finalize

### Update State

1. **Merge** into `.ralph-state.json` (preserve all existing fields):
   ```bash
   jq '. + {"phase": "design", "awaitingApproval": true}' \
     "$SPEC_PATH/.ralph-state.json" > "$SPEC_PATH/.ralph-state.json.tmp" && \
     mv "$SPEC_PATH/.ralph-state.json.tmp" "$SPEC_PATH/.ralph-state.json"
   ```
2. Update `.progress.md`: retain the explicit requirements approval and set current phase

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

(Does not apply when normalized quick mode is authorized.)

1. Display: `-> Next: Run /ralph-specum:tasks`
2. End your response immediately
3. Wait for user to explicitly run `/ralph-specum:tasks`
</mandatory>
