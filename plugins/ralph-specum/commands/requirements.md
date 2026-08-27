---
description: Generate requirements from goal and research
argument-hint: [spec-name] [--quick|--interactive]
allowed-tools: "*"
---

# Requirements Phase

Generate requirements for the active spec. Require the research artifact to have explicit approval first. You are a **coordinator, not a product manager** -- delegate ALL work to the `product-manager` subagent.

Read `${CLAUDE_PLUGIN_ROOT}/references/normal-mode-gates.md` before gathering context.

## Checklist

Create a task for each item and complete in order:

1. **Gather context** -- resolve spec, read research and goal
2. **Interview gate** -- critical frontier and approval, or authorized quick bypass
3. **Execute requirements** -- dispatch product-manager via team
4. **Artifact review** -- automatic spec-reviewer loop in authorized quick mode
5. **Walkthrough & approval** -- display summary, get user approval
6. **Finalize** -- update state, commit, stop

## Step 1: Gather Context

1. If `$ARGUMENTS` contains a spec name, use `ralph_find_spec()` to resolve it; otherwise use `ralph_resolve_current()`
2. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."
3. Check the resolved spec directory exists
4. Read `.ralph-state.json`; verify the research artifact was explicitly approved before clearing its artifact approval flag
5. Read context: `research.md` (if exists), `.progress.md`, original goal
6. Reject simultaneous exact `--quick` and `--interactive`. Normalize persistent mode with `phase_gate.py mode` before deciding whether to grill.
7. Run skill discovery pass 1 if missing. Run pass 2 now when `research.md` exists and pass 2 is missing.

## Step 2: Skill Load, Critical Grill, and Approval

If normalized `quickMode` is true, call `begin-interview` for phase `requirements` and continue to Step 3.

In interactive mode, reload all selected contracts and apply the interview-framework with phase `requirements`. Candidate critical decisions include user outcome boundaries, materially different scope cuts, priority tradeoffs, and compliance obligations that research cannot resolve. Inspect existing roles, terminology, policies, behavior, and constraints instead of asking about them.

Ask the whole currently unblocked critical frontier, in calls of at most four questions. Persist partial answers. Apply control-only and bare-skip semantics. Present the requirements decision brief and require explicit `Approve and delegate`. On approval, run `check-delegation` and launch Step 3 immediately in the same response.

Use `classify-reply` before applying every reply, `revise --decision-id` for final-approval revisions, and `confirm --source approve-and-delegate` only for the explicit approval selection.

## Step 3: Execute Requirements (Team-Based)

<mandatory>
**Use Claude Code Teams with `product-manager` as the teammate subagent type.**

Follow the full team lifecycle:

1. **Clean up stale team (MANDATORY FIRST ACTION)**: Call `TeamDelete()` before anything else. This releases whatever team the session is currently leading (could be from any prior phase). Errors mean no team was active -- harmless, proceed.
2. **Create team**: `TeamCreate(team_name: "requirements-$spec")`
3. **Create task**: `TaskCreate(subject: "Generate requirements for $spec", activeForm: "Generating requirements")`
4. **Spawn teammate**: Immediately run `check-delegation`, then call `Task(subagent_type: product-manager, team_name: "requirements-$spec", name: "pm-1")`. Include artifact agent ID `pm-1`, the gate marker, full selected-skill manifest, approved decision brief, research context, and goal. Instruct the agent to create user stories with acceptance criteria, functional requirements (FR-*), non-functional requirements (NFR-*), glossary, out-of-scope, and dependencies. Output to `./specs/$spec/requirements.md`.
5. **Wait for completion**: Monitor via TaskList.
6. **Shutdown**: `SendMessage(type: "shutdown_request", recipient: "pm-1")`
7. **Collect results**: Read `./specs/$spec/requirements.md`.
8. **Clean up**: `TeamDelete()`.

**Fallback**: If TeamCreate fails with "already leading" error, call `TeamDelete()` and retry `TeamCreate` once. If still fails, fall back to direct `Task(subagent_type: product-manager)` call.
</mandatory>

## Step 4: Automatic Artifact Review (authorized quick mode)

<mandatory>
**Review loop must complete before walkthrough. Max 3 iterations.**

If normalized `quickMode` is false, skip to Step 5.

Invoke `spec-reviewer` via Task tool. Follow the standard review loop:
- REVIEW_PASS: log to .progress.md, proceed
- REVIEW_FAIL (iteration < 3): log, re-invoke product-manager with feedback, loop
- REVIEW_FAIL (iteration >= 3): graceful degradation, log warning, proceed
- No signal: treat as REVIEW_PASS (permissive)

**Review delegation**: Include full requirements.md content, iteration count, prior findings. Upstream: research.md.

**Revision delegation**: Run `check-delegation`, create a fresh unique artifact agent ID, and re-invoke product-manager with reviewer feedback, gate marker, manifest, and current artifact. The agent reloads successful sources, records receipts, and checks its write gate. Focus on specific issues.

**Error handling**: Reviewer no signal = REVIEW_PASS. Agent failure = retry once, then use original.
</mandatory>

## Step 5: Walkthrough & Approval

<mandatory>
**WALKTHROUGH IS REQUIRED - DO NOT SKIP.**

Read `./specs/$spec/requirements.md` and display:

```
Requirements complete for '$spec'.
Output: $PWD/specs/$spec/requirements.md

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

### User Approval (interactive mode)

If normalized `quickMode` is true, skip to Step 6.

Ask ONE question: "How do you want to proceed?" with these options via AskUserQuestion:
1. **Approve** (Recommended) -- Accept artifact as-is, advance to next phase
2. **Run review** -- Spawn spec-reviewer to validate against rubrics, show findings, then loop back to this choice
3. **Request changes** -- Provide specific feedback to revise the artifact

**If "Approve"**: proceed to Step 6.
**If "Run review"**: Invoke spec-reviewer via Task tool with full requirements.md content (upstream: research.md). Display findings table. If REVIEW_PASS, note it. If REVIEW_FAIL, show feedback. Then loop back to this same 3-choice question (user decides next action).
**If "Request changes", "Other", or `apply the changes`**:
1. Apply already-recorded review or revision feedback immediately. Ask one focused change question only when no pending feedback exists.
2. Run `check-delegation`, then re-invoke product-manager using the **cleanup-and-recreate** team pattern with a new unique artifact agent ID, the gate marker, manifest, current artifact, and feedback
3. Re-display walkthrough, ask again with same 3 choices. Loop until approved.

## Step 6: Finalize

### Update State

1. **Merge** into `.ralph-state.json` (preserve all existing fields):
   ```bash
   jq '. + {"phase": "requirements", "awaitingApproval": true}' \
     "$SPEC_PATH/.ralph-state.json" > "$SPEC_PATH/.ralph-state.json.tmp" && \
     mv "$SPEC_PATH/.ralph-state.json.tmp" "$SPEC_PATH/.ralph-state.json"
   ```
2. Update `.progress.md`: retain the explicit research approval and set current phase

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

(Does not apply when normalized quick mode is authorized.)

1. Display: `-> Next: Run /ralph-specum:design`
2. End your response immediately
3. Wait for user to explicitly run `/ralph-specum:design`
</mandatory>
