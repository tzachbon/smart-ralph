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
2. **Grill** -- resolve the design-tree frontier (skip if `--quick`)
3. **Execute requirements** -- dispatch product-manager via team
4. **Artifact review** -- spec-reviewer validation loop (both modes)
5. **Walkthrough & approval** -- display summary, get user approval
6. **Finalize** -- update state, commit, stop

## Step 1: Gather Context

1. If `$ARGUMENTS` contains a spec name, use `ralph_find_spec()` to resolve it; otherwise use `ralph_resolve_current()`
2. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."
3. Check the resolved spec directory exists
4. Clear the approval flag through the locked helper while preserving every other field:
   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/locked-state.py" merge \
     --state "$SPEC_PATH/.ralph-state.json" \
     --set "awaitingApproval=false"
   ```
5. Read context: `research.md` (if exists), `.progress.md`, original goal

## Step 2: Grill (skip if --quick)

Check if `--quick` appears in `$ARGUMENTS`. If present, skip to Step 3.

### Grilling

Apply `${CLAUDE_PLUGIN_ROOT}/skills/interview-framework/SKILL.md` in full. It owns context and spec-index reading, fact lookup, the design tree, frontier rounds, domain-language work, progress capture, and the shared-understanding confirmation gate.

Read intent classification and prior interview responses only as context for building the tree. Do not derive question counts from intent.

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
4. **Spawn teammate**: `Task(subagent_type: product-manager, team_name: "requirements-$spec", name: "pm-1")` — delegate with research context, goal, and interview context. Instruct to follow the structure in `${CLAUDE_PLUGIN_ROOT}/templates/requirements.md` (canonical section order and formats): user stories with acceptance criteria, functional requirements (FR-*), non-functional requirements (NFR-*), glossary, out-of-scope, dependencies. In `--quick` mode (no interview context), instruct to state assumptions explicitly in the artifact rather than leaving gaps. Output to `./specs/$spec/requirements.md`.
5. **Wait for completion**: Monitor via TaskList.
6. **Shutdown**: `SendMessage(type: "shutdown_request", recipient: "pm-1")`
7. **Collect results**: Read `./specs/$spec/requirements.md`.
8. **Clean up**: `TeamDelete()`.

**Fallback**: If TeamCreate fails with "already leading" error, call `TeamDelete()` and retry `TeamCreate` once. If still fails, fall back to direct `Task(subagent_type: product-manager)` call.
</mandatory>

## Step 4: Artifact Review (both modes)

<mandatory>
**Review runs after generation in normal AND quick mode. Behavior branches on mode** (check `--quick` in `$ARGUMENTS`). Must complete before the walkthrough.

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

**Revision delegation (quick mode)**: Re-invoke product-manager with reviewer feedback. Focus on specific issues.

**Error handling (both modes)**: Reviewer no signal = REVIEW_PASS. Agent failure = retry once, then use original.
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

### User Approval (skip if --quick)

If `--quick`, skip to Step 6.

Ask ONE question: "How do you want to proceed?" with these options via AskUserQuestion:
1. **Continue to design** (Recommended) -- Approve requirements and keep the normal phase path
2. **continue to prototype** -- Approve requirements and run one suggested prototype before design
3. **Run review** -- Spawn spec-reviewer to validate against rubrics, show findings, then loop back to this choice
4. **Request changes** -- Provide specific feedback to revise the artifact

**If "Continue to design"**: set `nextAction: design`, then proceed to Step 6 without creating a prototype.
**If "continue to prototype"**: set `nextAction: prototype`, treat requirements as approved, then proceed to Step 6.
**If "Run review"**: Invoke spec-reviewer via Task tool with full requirements.md content (upstream: research.md). Display findings table. If REVIEW_PASS, note it. If REVIEW_FAIL, show feedback. Then loop back to this same 4-choice question (user decides next action).
**If "Request changes" or "Other"**:
1. Ask what to change
2. Re-invoke product-manager using **cleanup-and-recreate** team pattern (TeamDelete old -> TeamCreate new -> spawn with feedback -> wait -> shutdown -> TeamDelete)
3. Re-run the Step 4 review loop on the revised artifact (review re-runs after EVERY regeneration, no exceptions)
4. Re-display walkthrough (with updated Validation block), ask again with the same 4 choices. Loop until approved.

## Step 6: Finalize

### Update State

1. **Merge** into `.ralph-state.json` through the locked helper (preserve all existing and unknown fields):
   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/locked-state.py" merge \
     --state "$SPEC_PATH/.ralph-state.json" \
     --set "phase=requirements" \
     --set "awaitingApproval=true"
   ```
2. Update `.progress.md`: mark research as implicitly approved, set current phase

### Commit Spec (if enabled)

Read `commitSpec` from `.ralph-state.json`. It authorizes the local commit only. If true:
```bash
git add ./specs/$spec/requirements.md
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

(Does not apply in `--quick` mode.)

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
