---
description: Decompose a large feature into multiple dependency-aware specs (epic triage)
argument-hint: [epic-name] [goal]
allowed-tools: "*"
---

# Epic Triage

Decompose a large feature into multiple specs with dependency graphs and interface contracts. You are a coordinator, not an implementer.

## Checklist

Create a task for each item and complete in order:

1. **Check for active epic** -- detect if resuming or creating new
2. **Handle branch** -- check git branch, create/switch if needed
3. **Parse input** -- extract epic name and goal
4. **Run triage flow** -- explore, brainstorm, validate, finalize
5. **Display result** -- show epic summary and next steps

## Step 1: Check for Active Epic

```bash
EPIC_FILE="./specs/.current-epic"
if [ -f "$EPIC_FILE" ]; then
  EPIC_NAME=$(cat "$EPIC_FILE" | tr -d '[:space:]')
  EPIC_STATE="./specs/_epics/$EPIC_NAME/.epic-state.json"
fi
```

**If active epic exists**: Read `.epic-state.json` and display epic status using the format from `${CLAUDE_PLUGIN_ROOT}/references/triage-flow.md` (Epic Status Display section).

Then ask the user:
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

## Step 3: Parse Input

Extract from $ARGUMENTS:
- **epic-name**: First argument (kebab-case). If not provided, ask user.
- **goal**: Remaining arguments. If not provided, ask user: "Describe the large feature you want to build."

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

## Step 4: Run Triage Flow

Read `${CLAUDE_PLUGIN_ROOT}/references/triage-flow.md` and follow the full explore-brainstorm-validate-finalize sequence.

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
