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
4. **Artifact review** -- spec-reviewer validation loop (both modes)
5. **Walkthrough & approval** -- display summary, get user approval
6. **Finalize** -- update state, commit, stop

## Step 1: Gather Context

1. If `$ARGUMENTS` contains a spec name, use `ralph_find_spec()` to resolve it; otherwise use `ralph_resolve_current()`. Store the resolved spec directory as `SPEC_PATH`.
2. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."
3. Check the resolved spec directory exists
4. Read `.ralph-state.json`, reject simultaneous exact `--quick` and `--interactive`, and normalize persistent mode with `phase_gate.py mode`.
5. If `research.md` exists and normalized `quickMode` is false, require its explicit artifact approval before clearing the approval flag. Exact quick mode continues with the validated file. When `research.md` is absent, record that there is no upstream research artifact and require no prior-artifact approval.
6. Clear the approval flag through the locked helper while preserving every other field:
   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/locked-state.py" merge \
     --state "$SPEC_PATH/.ralph-state.json" \
     --set "awaitingApproval=false"
   ```
7. Read context: `research.md` (if exists), `.progress.md`, original goal.
8. Run skill discovery pass 1 if missing. Run pass 2 now when `research.md` exists and pass 2 is missing.

## Step 2: Skill Load, Critical Grill, and Approval

Apply `${CLAUDE_PLUGIN_ROOT}/skills/interview-framework/SKILL.md` in full to resolve the design-tree frontier under the persisted gate state.

In both interactive and exact quick mode, reload all selected contracts and required current-work resources, hash them, record the current manifest, then call `begin-interview` for phase `requirements`. A core load failure blocks either mode.

If normalized `quickMode` is true, the helper records `bypassed_quick`; continue to Step 3 without questions.

In interactive mode, apply the interview-framework with phase `requirements`. Candidate critical decisions include user outcome boundaries, materially different scope cuts, priority tradeoffs, and compliance obligations that research cannot resolve. Inspect existing roles, terminology, policies, behavior, and constraints instead of asking about them.

Ask the whole currently unblocked critical frontier, in calls of at most four questions. Persist partial answers. Apply control-only and bare-skip semantics. Present the requirements decision brief and require explicit `Approve and delegate`. On approval, run `check-delegation` and launch Step 3 immediately in the same response.

Use `classify-reply` for active decision frontiers and `revise --decision-id` for final-approval revisions. Keep canonical final choices first; only then may a noncanonical reply use the single-action `resolve-approval` fallback from `normal-mode-gates.md`. An accepted live `approve-and-delegate` result still requires `confirm --source approve-and-delegate` followed by `check-delegation`.

**Requirements Exploration Territory** (hints, not a script):
- **Primary users** -- who will use this feature? Developers, end users, specific roles?
- **Priority tradeoffs** -- speed of delivery vs code quality vs feature completeness
- **Success criteria** -- what does success look like? Metrics, behaviors, user outcomes
- **Scope boundaries** -- what is explicitly out of scope for this iteration?
- **Compliance or regulatory needs** -- security, privacy, or regulatory considerations?

### Scope Approach Branch

When scope requires a user decision, add 2-3 grounded approaches to the design tree. Examples (illustrative only):
- **(A)** Full feature set -- comprehensive user stories covering all use cases
- **(B)** MVP scope -- core user stories only, defer edge cases to v2
- **(C)** Phased delivery -- essential stories now, planned expansion later

### Store Grill Results

Append to `.progress.md` under "Interview Responses":
```markdown
### Requirements Grill (from requirements.md)
- [Round decisions and resolved facts]
- Chosen approach: [name] -- [brief description]
- Shared understanding: confirmed
```

Pass combined context to delegation prompt as "Interview Context".

## Step 3: Execute Requirements (Team-Based)

<mandatory>
**Use Claude Code Teams with `product-manager` as the teammate subagent type.**

Follow the full team lifecycle:

1. **Clean up stale team (MANDATORY FIRST ACTION)**: Call `TeamDelete()` before anything else. This releases whatever team the session is currently leading (could be from any prior phase). Errors mean no team was active -- harmless, proceed.
2. **Create team**: `TeamCreate(team_name: "requirements-$spec")`
3. **Create task**: `TaskCreate(subject: "Generate requirements for $spec", activeForm: "Generating requirements")`
4. **Spawn teammate**: Immediately run `check-delegation`, then call `Task(subagent_type: product-manager, team_name: "requirements-$spec", name: "pm-1")`. Include the absolute state and helper paths, complete `[RALPH_PHASE_GATE]` tuple (`state`, `phase`, `interviewId`, `discoveryRevision`, `contextDigest`), verbatim manifest, fresh artifact agent ID `pm-1`, matching load/write-check instructions, approved decision brief, research context, goal, and `Interview Context`. Instruct the agent to follow `${CLAUDE_PLUGIN_ROOT}/templates/requirements.md`, including canonical section order, user stories with acceptance criteria, functional requirements (FR-*), non-functional requirements (NFR-*), glossary, out-of-scope, and dependencies. In authorized quick mode, state defaulted assumptions explicitly rather than leaving gaps. Output to `$SPEC_PATH/requirements.md`.
5. **Wait for completion**: Monitor via TaskList.
6. **Shutdown**: `SendMessage(type: "shutdown_request", recipient: "pm-1")`
7. **Collect results**: Read `$SPEC_PATH/requirements.md`.
8. **Clean up**: `TeamDelete()`.

**Fallback**: If TeamCreate fails with "already leading" error, call `TeamDelete()` and retry `TeamCreate` once. If still failing, run `check-delegation` and use a direct `Task(subagent_type: product-manager)` with the same complete gate packet and a fresh unique artifact agent ID.
</mandatory>

## Step 4: Artifact Review (both modes)

<mandatory>
**Review runs after generation in normal AND quick mode. Behavior branches on normalized persistent `quickMode` from state.** Must complete before the walkthrough; do not re-read raw `$ARGUMENTS` to choose review behavior.

Before every requirements review delegation, run the deterministic lint from the coordinator's runtime-resolved `SPEC_PATH`. Keep the artifact path in the quoted variable expansion shown here; do not rebuild this command by inserting a path into its source:

```bash
LINT="${CLAUDE_PLUGIN_ROOT:+$CLAUDE_PLUGIN_ROOT/hooks/scripts/lint-requirements.sh}"
[ -f "$LINT" ] || LINT="plugins/ralph-specum/hooks/scripts/lint-requirements.sh"
if [ -f "$LINT" ]; then
  if REQUIREMENTS_LINT_OUTPUT=$(bash "$LINT" "$SPEC_PATH/requirements.md" 2>&1); then
    REQUIREMENTS_LINT_EXIT=0
  else
    REQUIREMENTS_LINT_EXIT=$?
  fi
else
  REQUIREMENTS_LINT_EXIT=unavailable
  REQUIREMENTS_LINT_OUTPUT=""
fi
```

**Review delegation (both modes)**: Invoke `spec-reviewer` via Task tool. Include full requirements.md content, `artifactType: requirements`, `artifactPath: $SPEC_PATH/requirements.md`, `requirementsLintExit: $REQUIREMENTS_LINT_EXIT`, the exact `requirementsLintOutput` as data, iteration count, and prior findings. Upstream: research.md. Re-run the coordinator lint after every quick-mode revision and before any user-requested re-review. When `requirementsLintExit` is `unavailable`, the reviewer applies its manual Degradation rule.

### Normal mode: single pass

Run `spec-reviewer` exactly ONCE. Do NOT loop or auto-regenerate on FAIL.
- Log the result (REVIEW_PASS or REVIEW_FAIL) and all findings to .progress.md.
- Carry the findings forward -- **including any FAIL-class findings** -- into the Step 5 walkthrough Validation block. The user decides what to do with them (approve as-is, request changes, or re-run review).
- No signal: treat as REVIEW_PASS (permissive); note the missing signal in the Validation block.

### Quick mode: max-3 loop

Follow the standard review loop (unchanged):
- REVIEW_PASS: log to .progress.md, proceed
- REVIEW_FAIL (iteration < 3): log, re-invoke product-manager with feedback, loop
- REVIEW_FAIL (iteration >= 3): graceful degradation, log warning, proceed
- No signal: treat as REVIEW_PASS (permissive)

**Revision delegation (quick mode)**: Record nonblank reviewer feedback in the revision context before creating a revision descriptor or dispatching a revision. Then run `check-delegation`, create a fresh unique artifact agent ID, and re-invoke product-manager with the absolute state/helper paths, complete marker identity tuple, verbatim manifest, matching load/write-check instructions, reviewer feedback, current artifact, and research context. Focus on specific issues.

**Error handling (both modes)**: Reviewer no signal = REVIEW_PASS. Agent failure = retry once, then use original.
</mandatory>

## Step 5: Walkthrough & Approval

<mandatory>
**WALKTHROUGH IS REQUIRED - DO NOT SKIP.**

Read `$SPEC_PATH/requirements.md` and display:

```
Requirements complete for '$spec'.
Output: $SPEC_PATH/requirements.md

## What I Created

**Goal**: [1 sentence summary]

**User Stories** ([count] total):
- US-1: [title]
- US-2: [title]
- US-3: [title]
[list all, keep titles brief]

**Requirements**: [X] functional, [Y] non-functional

## Validation

**Checks** (from the Step 4 review, one row per check; show real statuses including any FAIL):
| # | Check | Status |
|---|-------|--------|
| C1 | ID & cross-reference integrity | PASS / WARN / FAIL |
| C2 | GWT clause presence | PASS / WARN / FAIL |
| C3 | MoSCoW priority values | PASS / WARN / FAIL |
| C4 | Requirement-language modals | PASS / WARN / FAIL |
| C5 | NFR fill-or-N/A | PASS / WARN / FAIL |
| C6 | Six-scenario coverage | PASS / WARN / FAIL |
| C7 | Unowned TBD / open questions | PASS / WARN / FAIL |
| C8 | MUST:SHOULD ratio advisory | PASS / WARN / FAIL |

**Judgment findings**: [reviewer's judgment-based findings, or "None"]
```

The Validation block reports the statuses of the 8 rubric checks plus any judgment findings from the most recent Step 4 review (normal mode: the single pass; FAILs are shown here for the user to decide on). User approval flow is unchanged.
</mandatory>

### User Approval (interactive mode)

If normalized `quickMode` is true, skip to Step 6.

Ask ONE question: "How do you want to proceed?" with these options via AskUserQuestion:
1. **Continue to design** (Recommended) -- Approve requirements and keep the normal phase path
2. **continue to prototype** -- Approve requirements and run one suggested prototype before design
3. **Run review** -- Spawn spec-reviewer to validate against rubrics, show findings, then loop back to this choice
4. **Request changes** -- Provide specific feedback to revise the artifact

This is a multi-option view: persist no `approvalGate`, and treat a bare affirmative as a clarification that re-asks one focused canonical choice. A later concrete artifact or revision handoff may call `resolve-approval` only when `awaitingApproval` is true and one persisted descriptor names its sole action. Create a revision descriptor or dispatch a revision only after recorded nonblank feedback. Handle canonical choices first; an accepted result must take the existing continuation or fresh-writer route, and clear or replace its descriptor only after that route succeeds. On clarification, leave state unchanged and do not advance.

**If "Continue to design"**: set `nextAction: design`, then proceed to Step 6 without creating a prototype.
**If "continue to prototype"**: set `nextAction: prototype`, treat requirements as approved, then proceed to Step 6.
**If "Run review"**: Invoke spec-reviewer via Task tool with full requirements.md content (upstream: research.md). Display findings table. If REVIEW_PASS, note it. If REVIEW_FAIL, show feedback. Then loop back to this same 4-choice question (user decides next action).
**If "Request changes", "Other", or `apply the changes`**:
1. Apply already-recorded review or revision feedback immediately. Ask one focused change question only when no pending feedback exists, record its nonblank answer, and only then create a revision descriptor or dispatch a revision.
2. Run `check-delegation`, then re-invoke product-manager using the **cleanup-and-recreate** team pattern with the same complete packet and a new unique artifact agent ID, current artifact, and feedback
3. Re-run the deterministic lint and Step 4 review behavior for the current mode on the revised artifact.
4. Re-display the walkthrough with its updated Validation block and ask the same 4-choice approval question again. Loop until the user selects a continue option.

## Step 6: Finalize

### Update State

1. **Merge** into `.ralph-state.json` through the locked helper (preserve all existing and unknown fields):
   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/locked-state.py" merge \
     --state "$SPEC_PATH/.ralph-state.json" \
     --set "phase=requirements" \
     --set "awaitingApproval=true"
   ```
2. Update `.progress.md`: retain the explicit research approval and set current phase

### Commit Spec (if enabled)

Read `commitSpec` from `.ralph-state.json`. It authorizes the local commit only. If true:
```bash
git add "$SPEC_PATH/requirements.md"
git commit -m "spec($spec): add requirements"
```

In quick mode, skip only this push: do not ask a remote question, do not push, and continue the quick phase flow. In normal mode, run the Prototype Evidence Push Gate from `${CLAUDE_PLUGIN_ROOT}/references/commit-discipline.md` immediately before the existing push. If outbound commits contain `**/prototypes/*.md`, require separate explicit authorization naming every exact record; otherwise preserve the existing push behavior.

```bash
git push -u origin $(git branch --show-current)
```
If commit or push fails, display warning but continue.

### Stop

<mandatory>
**STOP HERE. DO NOT PROCEED TO DESIGN.**

(Does not apply when normalized quick mode is authorized.)

If `nextAction: prototype`:
1. Invoke `/ralph-specum:prototype --suggested --return-phase design` with the resolved `basePath` at this phase boundary.
2. Let the prototype coordinator own resume, review, verdict, cleanup, publication, and handoff.
3. End after the coordinator returns to design. Do not generate design in this command.

Otherwise:
1. Display: `-> Next: Run /ralph-specum:design`
2. End your response immediately.
3. Wait for the user to run `/ralph-specum:design`.
</mandatory>

### Quick continuation

When `--quick` is active, do not ask the approval question above. After Step 6, execute the single Post-Requirements Prototype Gate in `${CLAUDE_PLUGIN_ROOT}/references/quick-mode.md`, then continue to design for every prototype outcome. That reference owns the only quick prototype call site; do not invoke it a second time here.
