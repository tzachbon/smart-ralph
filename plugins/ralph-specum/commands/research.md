---
description: Run or re-run research phase for current spec
argument-hint: [spec-name] [--quick|--interactive]
allowed-tools: "*"
---

# Research Phase

Run parallel research for the active spec. You are a **coordinator, not a researcher** -- delegate ALL work to subagents.

Read `${CLAUDE_PLUGIN_ROOT}/references/normal-mode-gates.md` before gathering context. Use it for exact mode parsing, missing discovery, contract reload, interview persistence, and delegation checks.

## Checklist

Create a task for each item and complete in order:

1. **Gather context** -- resolve spec, read goal and existing files
2. **Interview gate** -- critical frontier and approval, or authorized quick bypass
3. **Execute parallel research** -- dispatch team of research-analyst + Explore agents
4. **Merge results** -- synthesize partial files into research.md
5. **Artifact review** -- automatic spec-reviewer loop in authorized quick mode
6. **Walkthrough & approval** -- display summary, get user approval
7. **Finalize** -- update state, commit, stop

## Step 1: Gather Context

1. If `$ARGUMENTS` contains a spec name, use `ralph_find_spec()` to resolve it; otherwise use `ralph_resolve_current()`
2. If no active spec, error: "No active spec. Run /ralph-specum:new <name> first."
3. Check the resolved spec directory exists
4. Read `.ralph-state.json` if it exists
5. Read `.progress.md` to understand the goal
6. Reject simultaneous exact `--quick` and `--interactive` tokens. Normalize `.ralph-state.json` with `phase_gate.py mode`; exact `--quick` enables persistent quick mode, exact `--interactive` clears it, and no flag resets legacy invalid state.
7. Run skill discovery pass 1 if the state lacks it. Reuse the current pass when present.

## Step 2: Skill Load, Critical Grill, and Approval

If normalized `quickMode` is true, call `begin-interview` for phase `research` to record the authorized quick bypass, then continue to Step 3.

In interactive mode:

1. Reload the complete selected-skill manifest and every required current-work resource.
2. Apply `${CLAUDE_PLUGIN_ROOT}/skills/interview-framework/SKILL.md` with phase `research`.
3. Build critical decision candidates from research direction, material constraints, systems in scope, and alternatives whose comparison would change later artifacts.
4. Inspect repository facts, prior specs, existing technology, and available commands. Do not ask setup, administrative, discoverable, or low-impact questions.
5. Ask the whole unblocked critical frontier, at most four questions per `AskUserQuestion` call.
6. Persist partial answers, handle control-only and bare-skip replies through the helper, and require explicit final approval. Use `classify-reply` before applying every reply, `revise --decision-id` for final-approval revisions, and `confirm --source approve-and-delegate` only for the explicit approval selection.
7. On approval, run `check-delegation` and continue immediately to Step 3 in the same response.

Pass the approved brief and full skill manifest to artifact agents.

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

Follow the full team lifecycle: Clean up stale team (MANDATORY TeamDelete first) -> Create team -> Create tasks -> Spawn teammates (ALL in ONE message) -> Wait -> Shutdown -> Collect results -> Clean up team.

Immediately before each `research-analyst` Task call, run `phase_gate.py check-delegation`. Include the `[RALPH_PHASE_GATE]` marker, complete selected-skill manifest, and approved decision brief in its prompt. The PreToolUse hook repeats this check. `Explore` is read-only and remains allowed without a marker.

**Fallback**: If TeamCreate fails with "already leading" error, call `TeamDelete()` and retry `TeamCreate` once. If still fails, fall back to direct Task calls without a team.
</mandatory>

## Step 4: Delegate Result Merge

After all parallel tasks complete, run `check-delegation` and delegate the unified `./specs/$spec/research.md` write to a fresh `research-analyst` with a unique artifact agent ID, gate marker, full selected-skill manifest, approved brief, partial artifact paths, and returned Explore findings.

Read `${CLAUDE_PLUGIN_ROOT}/references/parallel-research.md` "Merging Results" section for the exact merge structure and process.

After merge, delete partial files: `rm ./specs/$spec/.research-*.md`

## Step 5: Automatic Artifact Review (authorized quick mode)

<mandatory>
**Review loop must complete before walkthrough. Max 3 iterations.**

If normalized `quickMode` is false, skip to Step 6.

Invoke `spec-reviewer` via Task tool to validate research.md. Follow the standard review loop:
- REVIEW_PASS: log to .progress.md, proceed to walkthrough
- REVIEW_FAIL (iteration < 3): log, extract feedback, re-invoke research-analyst with revision prompt, re-read, loop
- REVIEW_FAIL (iteration >= 3): log warning to .progress.md (graceful degradation), proceed
- No signal: treat as REVIEW_PASS (permissive)

**Review delegation**: Include full research.md content, iteration count, and prior findings. Upstream: none (research is first artifact).

**Revision delegation**: Run `check-delegation`, create a fresh unique artifact agent ID, and re-invoke research-analyst with reviewer feedback, gate marker, manifest, and current artifact. The agent reloads successful sources, records receipts, and checks its write gate. Focus on the flagged issues.

**Error handling**: Reviewer no signal = REVIEW_PASS. Agent failure during revision = retry once, then use original.
</mandatory>

## Step 6: Walkthrough & Approval

<mandatory>
**WALKTHROUGH IS REQUIRED - DO NOT SKIP.**

Read `./specs/$spec/research.md` and display:

```
Research complete for '$spec'.
Output: $PWD/specs/$spec/research.md

## What I Found

**Summary**: [1-2 sentences from Executive Summary]

**Key Recommendations**:
1. [First recommendation]
2. [Second recommendation]
3. [Third recommendation]

**Feasibility**: [High/Medium/Low] | **Risk**: [High/Medium/Low] | **Effort**: [S/M/L/XL]
```
</mandatory>

### User Approval (interactive mode)

If normalized `quickMode` is true, skip to Step 7.

Ask ONE question: "How do you want to proceed?" with these options via AskUserQuestion:
1. **Approve** (Recommended) -- Accept artifact as-is, advance to next phase
2. **Run review** -- Spawn spec-reviewer to validate against rubrics, show findings, then loop back to this choice
3. **Request changes** -- Provide specific feedback to revise the artifact

**If "Approve"**: proceed to Step 7.
**If "Run review"**: Invoke spec-reviewer via Task tool with full research.md content (upstream: none). Display findings table. If REVIEW_PASS, note it. If REVIEW_FAIL, show feedback. Then loop back to this same 3-choice question (user decides next action).
**If "Request changes", "Other", or `apply the changes`**: Apply already-recorded review or revision feedback immediately. Ask one focused change question only when no pending feedback exists. Run the delegation gate, invoke the research agents with the feedback and original marker/manifest, re-merge, re-display the walkthrough, and ask again with the same choices. Stay in artifact approval until explicit `Approve`.

## Step 7: Finalize

### Update State

1. Parse "Related Specs" table from research.md
2. **Merge** into `.ralph-state.json` (preserve all existing fields):
   ```bash
   jq --argjson specs "$RELATED_SPECS_JSON" \
     '. + {"phase": "research", "awaitingApproval": true, "relatedSpecs": $specs}' \
     "$SPEC_PATH/.ralph-state.json" > "$SPEC_PATH/.ralph-state.json.tmp" && \
     mv "$SPEC_PATH/.ralph-state.json.tmp" "$SPEC_PATH/.ralph-state.json"
   ```
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

(Does not apply when normalized quick mode is authorized.)

1. Display: `-> Next: Run /ralph-specum:requirements`
2. End your response immediately
3. Wait for user to explicitly run `/ralph-specum:requirements`
</mandatory>
