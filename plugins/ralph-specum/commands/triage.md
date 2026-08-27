---
description: Decompose a large feature into multiple dependency-aware specs (epic triage)
argument-hint: [epic-name] [goal] [--quick|--interactive]
allowed-tools: "*"
---

# Epic Triage

Decompose a large feature into multiple specs with dependency graphs and interface contracts. You are a coordinator, not an implementer.

## Checklist

Create a task for each item and complete in order:

1. **Parse mode** -- recognize exact `--quick` or `--interactive`
2. **Check for active epic** -- detect if resuming or creating new
3. **Handle branch** -- check git branch, create/switch if needed
4. **Set up epic** -- create `.epic-state.json` before discovery
5. **Run gates** -- discover, preload, grill, and get approval
6. **Delegate triage** -- gate explore, decomposition, and validation agents

Read `${CLAUDE_PLUGIN_ROOT}/references/normal-mode-gates.md` first. If exact `--quick` and `--interactive` tokens both occur, stop with an error. Ignore `-q`, substrings, and natural-language quick requests.

## Step 0: Parse Mode Tokens

Tokenize `$ARGUMENTS`. Recognize only exact `--quick` and `--interactive` tokens. If both occur, stop with: `ERROR: --quick and --interactive cannot be used together.` The aliases `-q`, substring matches, and natural-language requests do not select quick mode.

## Step 1: Check for Active Epic

```bash
EPIC_FILE="./specs/.current-epic"
if [ -f "$EPIC_FILE" ]; then
  EPIC_NAME=$(cat "$EPIC_FILE" | tr -d '[:space:]')
  if [[ "$EPIC_NAME" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    EPIC_STATE="./specs/_epics/$EPIC_NAME/.epic-state.json"
  else
    EPIC_NAME=""
    EPIC_STATE=""
  fi
fi
```

**If active epic exists**: Read `.epic-state.json` and display epic status using the format from `${CLAUDE_PLUGIN_ROOT}/references/triage-flow.md` (Epic Status Display section).

Normalize its mode with `phase_gate.py mode` before any possible question or resumed triage delegation. Exact `--quick` enables the quick guard from the active `.epic-state.json`; exact `--interactive` clears it; no flag resets legacy invalid quick state.

With exact `--quick`, do not ask how to handle the active epic. Resume it when no different epic name was supplied or when the supplied name matches. If the command supplies a different epic name and goal, create that epic. If the different name lacks a goal, stop with an input error. Do not call `AskUserQuestion` in any exact-quick branch.

In interactive mode, ask the user:
- **Continue with this epic** -- suggest the next unblocked spec
- **Create a new epic** -- proceed to Step 2
- **View epic details** -- show full epic.md content

If user chooses to continue: suggest next unblocked spec, offer to run `/start <spec-name>`. STOP.

**If no active epic**: Proceed to Step 2.

## Step 2: Branch Management

<mandatory>
Before creating any files or directories, check the current git branch and handle appropriately.
</mandatory>

Read `${CLAUDE_PLUGIN_ROOT}/references/branch-management.md` and follow the full branch decision logic.

With exact `--quick`, follow its Quick Mode Branch Handling section. Do not ask a branch question.

## Step 3: Parse Input

Extract from $ARGUMENTS:
- **epic-name**: First argument (kebab-case). In interactive mode, ask if missing. In exact quick mode, stop with an input error if a new epic needs a name.
- **goal**: Remaining arguments. In interactive mode, ask if missing. In exact quick mode, stop with an input error if a new epic needs a goal.

Create epic directory:
```bash
mkdir -p "./specs/_epics/$EPIC_NAME"
```

Initialize `.progress.md`:
```markdown
# Epic: $EPIC_NAME

## Original Goal
$GOAL

## Completed
(none yet)

## Learnings
(none yet)
```

Initialize `./specs/_epics/$EPIC_NAME/.epic-state.json` before skill discovery:

```json
{
  "name": "$EPIC_NAME",
  "goal": "$GOAL",
  "specs": [],
  "output": null,
  "issueNumber": null,
  "quickMode": false,
  "discoveredSkills": []
}
```

Normalize persistent mode with `phase_gate.py mode`. Exact `--quick` enables the bypass, exact `--interactive` clears it, and no flag resets legacy invalid quick state.

Immediately after the initial state exists, write `$EPIC_NAME` to `./specs/.current-epic` and ensure its gitignore entry. Do this before skill discovery, the interview, or any artifact Task so both guards resolve this exact active epic state. A resumed epic keeps its existing pointer.

## Step 3.5: Skill Discovery, Grill, and Approval

1. Run skill discovery pass 1 from `normal-mode-gates.md` against the epic goal.
2. In normal mode, reload every selected skill and required current-work resource.
3. Run the interview-framework with phase `triage` and only critical decomposition decisions. Inspect codebase boundaries and existing architecture instead of asking the user. Interactive setup answers for epic name, goal, or branch strategy do not satisfy or replace this interview.
4. Present the decision brief and obtain explicit `Approve and delegate` approval. Use `classify-reply` before applying every reply, `revise --decision-id` for final-approval revisions, and `confirm --source approve-and-delegate` only for that explicit approval selection.
5. In quick mode, record `bypassed_quick` through `begin-interview` instead.
6. Run `check-delegation` immediately before the first artifact-producing Task.

## Step 4: Run Triage Flow

Read `${CLAUDE_PLUGIN_ROOT}/references/triage-flow.md` and follow the full explore-brainstorm-validate-finalize sequence.

Pass the phase gate marker and full skill manifest to every `research-analyst` and `triage-analyst` Task. Require their per-source load receipts and write checks. Read-only `Explore` Tasks remain allowed.

<mandatory>
**YOU ARE A COORDINATOR, NOT AN IMPLEMENTER.**

You MUST delegate ALL work to subagents:

| Work Type | Subagent |
|-----------|----------|
| Exploration research | Research Team (parallel-research pattern) |
| Brainstorming/Decomposition | `triage-analyst` agent |
| Validation research | `research-analyst` agent |

Do NOT write epic.md yourself. Do NOT perform research yourself.
</mandatory>

## Step 5: Display Result

<mandatory>
**WALKTHROUGH IS REQUIRED - DO NOT SKIP.**

After epic.md is created and output format is handled, display:

```text
Triage complete for '$EPIC_NAME'.
Output: ./specs/_epics/$EPIC_NAME/epic.md

## Epic Summary

**Vision**: [1-2 sentences from Vision section]

**Specs** ($TOTAL specs):
1. <spec-a>: <goal> [Size]
2. <spec-b>: <goal> [Size] (depends on: spec-a)
3. <spec-c>: <goal> [Size] (depends on: spec-a)
...

**Ready to start**: <first spec with no dependencies>

-> Next: Run /start <first-spec-name> to begin the first spec
   Or run /triage to see epic status at any time
```

Then STOP. End response immediately.
</mandatory>

<mandatory>
## CRITICAL: Delegation Requirement

**YOU ARE A COORDINATOR, NOT AN IMPLEMENTER.**

You MUST delegate ALL substantive work to subagents. This is NON-NEGOTIABLE.

**NEVER do any of these yourself:**
- Write epic.md or research.md content
- Perform research or analysis
- Make decomposition decisions

**ALWAYS delegate to the appropriate subagent.**
</mandatory>
