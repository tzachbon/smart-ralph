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

Validate the resolved epic name before constructing any path. Reject it unless it matches `^[a-z0-9]+(-[a-z0-9]+)*$`.

Set `EPIC_DIR="./specs/_epics/$EPIC_NAME"`. Before creating or initializing anything:

- If `$EPIC_DIR/.epic-state.json` exists, reuse that epic state and resume it. Never overwrite its `.progress.md` or state.
- If `$EPIC_DIR` exists without a valid `.epic-state.json`, stop with an input error and require a different epic name or an explicit user-authorized reset.
- Only when `$EPIC_DIR` does not exist, create and initialize it.

Create a new epic directory:
```bash
mkdir -p "$EPIC_DIR"
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

Initialize `$EPIC_DIR/.epic-state.json` before skill discovery. Serialize the user-provided name and goal through `jq --arg`:

```bash
jq -n \
  --arg name "$EPIC_NAME" \
  --arg goal "$GOAL" \
  '{
    name: $name,
    goal: $goal,
    specs: [],
    output: null,
    issueNumber: null,
    quickMode: false,
    discoveredSkills: []
  }' > "$EPIC_DIR/.epic-state.json"
```

Normalize persistent mode with `phase_gate.py mode`. Exact `--quick` enables the bypass, exact `--interactive` clears it, and no flag resets legacy invalid quick state.

After resolving either a new or resumed epic state, write `$EPIC_NAME` to `./specs/.current-epic`, replacing any stale pointer, and ensure its gitignore entry. Do this before skill discovery, the interview, or any artifact Task so both guards resolve this exact active epic state.

## Step 3.5: Skill Discovery, Grill, and Approval

1. Run skill discovery pass 1 from `normal-mode-gates.md` against the epic goal.
2. In both interactive and exact quick mode, reload every selected skill and required current-work resource, hash them, and record the current `phaseSkillLoad` manifest. A core load failure blocks both modes.
3. Call `begin-interview` only after the manifest is accepted.
4. In interactive mode, run the interview-framework with phase `triage` and only critical decomposition decisions. Inspect codebase boundaries and existing architecture instead of asking the user. Interactive setup answers for epic name, goal, or branch strategy do not satisfy or replace this interview.
5. Present the decision brief and obtain `Approve and delegate` approval. Use `classify-reply` for active decision frontiers and `revise --decision-id` for final-approval revisions. Keep canonical final choices first; only then may a noncanonical reply use the single-action `resolve-approval` fallback from `normal-mode-gates.md`. An accepted live `approve-and-delegate` result still requires `confirm --source approve-and-delegate` followed by `check-delegation`. In exact quick mode, `begin-interview` records `bypassed_quick` and asks no questions.
6. Run `check-delegation` immediately before the first artifact-producing Task.

## Step 4: Run Triage Flow

Read `${CLAUDE_PLUGIN_ROOT}/references/triage-flow.md` and follow the full explore-brainstorm-validate-finalize sequence.

Pass every writer the absolute epic-state and helper paths, complete `[RALPH_PHASE_GATE]` tuple (`state`, `phase`, `interviewId`, `discoveryRevision`, `contextDigest`), verbatim manifest, complete approved brief, fresh `artifactAgentId`, and matching per-source load/write-check instructions. Use a fresh identity for every revision. Read-only `Explore` Tasks remain allowed.

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
