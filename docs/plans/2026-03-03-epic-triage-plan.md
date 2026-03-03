# Epic Triage Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add `/ralph-specum:triage` command for decomposing large features into multiple dependency-aware specs (epics), and enhance `/start` with epic awareness.

**Architecture:** New `triage.md` command + `triage-analyst.md` agent + `epic.md` template. The triage flow follows explore-brainstorm-validate-finalize with two research passes. Epic state lives in `specs/_epics/<name>/` with `.epic-state.json` and `.current-epic`. `/start` gains epic detection in its routing logic. Stop-watcher updates epic state on spec completion.

**Tech Stack:** Markdown commands/agents (Claude Code plugin system), bash (stop-watcher.sh), JSON schema, jq for state management.

**Design Doc:** `docs/plans/2026-03-03-epic-triage-design.md`

---

### Task 1: Add epic state schema definition

**Files:**
- Modify: `plugins/ralph-specum/schemas/spec.schema.json:184` (after the `state` closing brace, before `task` definition)

**Step 1: Add `epicState` definition to the schema**

Add this new definition after the `state` definition (line 185) and before the `task` definition (line 187):

```json
    "epicState": {
      "type": "object",
      "description": "State for epic (multi-spec) tracking",
      "required": ["name", "goal", "specs"],
      "properties": {
        "name": {
          "type": "string",
          "pattern": "^[a-z0-9-]+$",
          "description": "Epic name in kebab-case"
        },
        "goal": {
          "type": "string",
          "description": "High-level epic goal"
        },
        "specs": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["name", "status", "dependencies"],
            "properties": {
              "name": {
                "type": "string",
                "pattern": "^[a-z0-9-]+$",
                "description": "Spec name in kebab-case"
              },
              "status": {
                "type": "string",
                "enum": ["pending", "in_progress", "completed", "cancelled"],
                "description": "Spec completion status within the epic"
              },
              "dependencies": {
                "type": "array",
                "items": { "type": "string" },
                "description": "Names of specs that must complete before this one"
              }
            }
          },
          "description": "Ordered list of specs in this epic with dependency graph"
        },
        "output": {
          "type": "string",
          "enum": ["spec-files", "github-issues", "both"],
          "description": "Where the epic plan was stored"
        },
        "issueNumber": {
          "type": ["integer", "null"],
          "description": "GitHub parent issue number (if output includes github-issues)"
        }
      }
    },
```

**Step 2: Add `epicName` to the existing `state` definition**

Add this property inside the `state.properties` object (after `discoveredSkills` or alongside other optional fields around line 183):

```json
        "epicName": {
          "type": "string",
          "pattern": "^[a-z0-9-]+$",
          "description": "Parent epic name if this spec belongs to an epic"
        }
```

**Step 3: Verify schema is valid JSON**

Run: `jq empty plugins/ralph-specum/schemas/spec.schema.json`
Expected: no output (valid JSON)

**Step 4: Commit**

```bash
git add plugins/ralph-specum/schemas/spec.schema.json
git commit -m "feat(ralph-specum): add epicState schema and epicName field"
```

---

### Task 2: Create epic.md template

**Files:**
- Create: `plugins/ralph-specum/templates/epic.md`

**Step 1: Create the template file**

```markdown
---
epic: {{EPIC_NAME}}
created: {{TIMESTAMP}}
---

# Epic: {{EPIC_NAME}}

## Vision

{{1-2 sentence problem statement describing what this epic achieves}}

## Success Criteria

- {{Measurable criterion 1}}
- {{Measurable criterion 2}}
- {{Measurable criterion 3}}

## Specs

### 1. {{spec-name}}

**Goal**: As a {{user}} I want {{capability}} so that {{outcome}}

**Acceptance Criteria**:
- {{Specific, testable condition}}
- {{Another testable condition}}

**MVP Scope**:
- In: {{what's included}}
- Out: {{what's explicitly excluded}}

**Dependencies**: none

**Interface Contracts**:
- Exposes: {{API endpoint, data shape, or message schema this spec provides}}
- Consumes: {{what this spec needs from other specs}}

**Architecture** (advisory):
{{Key components, data flow, suggested patterns. This guides decomposition but does not constrain the spec's own design phase.}}

**Size**: {{S/M/L/XL}}

## Dependency Graph

{{Mermaid or text representation of spec dependencies}}

## Notes

{{Any additional context, constraints, or coordination notes from the triage session}}
```

**Step 2: Verify file exists**

Run: `ls -la plugins/ralph-specum/templates/epic.md`
Expected: file exists

**Step 3: Commit**

```bash
git add plugins/ralph-specum/templates/epic.md
git commit -m "feat(ralph-specum): add epic.md template for triage output"
```

---

### Task 3: Create triage-analyst agent

**Files:**
- Create: `plugins/ralph-specum/agents/triage-analyst.md`

**Step 1: Create the agent file**

```markdown
---
name: triage-analyst
description: This agent should be used to "decompose a large feature", "triage a big task", "break down into multiple specs", "create epic decomposition", or needs guidance on splitting large features into dependency-aware spec graphs.
model: inherit
color: orange
---

You are a senior engineering manager and product strategist. Your job is to decompose large features into independently deliverable specs with clear dependency graphs and interface contracts.

## Core Philosophy

You think in vertical slices (user-value driven), not horizontal layers (technical decomposition). Each spec you produce must be independently deliverable and provide user value on its own.

<mandatory>
## Rules
1. Decompose by USER JOURNEY, not by technical layer
2. Every spec must be independently deliverable
3. Interface contracts are the #1 artifact -- without them, parallel work is fiction
4. Architecture thinking informs the decomposition but does not become a spec deliverable
5. Err on fewer, larger specs over many tiny ones (coordination overhead matters)
6. Never produce specs that can only ship together -- that's a single spec
</mandatory>

## When Invoked

You receive via Task delegation:
- **basePath**: Full path to epic directory (e.g., `./specs/_epics/my-epic`)
- **epicName**: Epic name
- **goal**: The user's high-level feature goal
- **researchOutput**: Content from the exploration research phase

Use `basePath` for ALL file operations.

## Process

### 1. Understand

Run an intensive brainstorming dialogue (interview-framework style):
- What problem does this solve? Who are the users?
- What are the success criteria for the whole feature?
- What are the constraints (technical, timeline, team)?
- What existing components can be leveraged? (from research)

### 2. Map User Journeys

Identify all distinct user flows/capabilities:
- List each journey as a potential spec boundary
- Mark which journeys are independent vs dependent
- Use research findings to ground in reality (e.g., "the codebase already has X")
- Identify shared infrastructure needs (these become dependency specs)

### 3. Propose Decomposition

Present candidate specs as vertical slices:
- Each spec = one independently deliverable capability
- Show the dependency graph
- Include interface contracts between specs
- Use architecture thinking to inform ordering
- Estimate size per spec

### 4. Refine with User

Iterate on the decomposition:
- Merge specs that are too small
- Split specs that are too large
- Adjust dependencies
- Confirm interface contracts
- Validate MVP scope boundaries

## Output: epic.md

Create `<basePath>/epic.md` using the epic template structure.

The epic.md must include:
- Vision statement
- Success criteria
- Per-spec detail: goal (user story format), acceptance criteria, MVP scope, dependencies, interface contracts, advisory architecture, size estimate
- Dependency graph (text or mermaid)

## Append Learnings

<mandatory>
After completing, append discoveries to `<basePath>/.progress.md`:
- Key decomposition decisions and rationale
- Interface contracts that emerged
- Risks identified
- Dependencies between specs
</mandatory>

## Communication Style

<mandatory>
Be extremely concise. Sacrifice grammar for concision.
No filler words. No preamble. No "I think" or "I believe".
State findings directly.
</mandatory>
```

**Step 2: Verify agent file exists and has valid frontmatter**

Run: `head -6 plugins/ralph-specum/agents/triage-analyst.md`
Expected: YAML frontmatter with name, description, model, color fields

**Step 3: Commit**

```bash
git add plugins/ralph-specum/agents/triage-analyst.md
git commit -m "feat(ralph-specum): add triage-analyst agent for epic decomposition"
```

---

### Task 4: Create triage-flow reference

**Files:**
- Create: `plugins/ralph-specum/references/triage-flow.md`

**Step 1: Create the reference file**

This reference contains the explore-brainstorm-validate-finalize flow that `triage.md` delegates to.

```markdown
# Triage Flow: Explore-Brainstorm-Validate-Finalize

> Used by: triage.md

## Overview

The triage flow decomposes a large feature into multiple specs. It uses two research passes (explore + validate) sandwiching a brainstorming/decomposition phase.

## Step 1: Exploration Research

Spawn research team (same parallel-research pattern as /start) with a triage-focused prompt.

### Research Prompt Customization

When spawning the research team, use this directive instead of the standard spec research directive:

```
TRIAGE RESEARCH DIRECTIVE:
You are researching for an EPIC TRIAGE -- a large feature decomposition.
Focus on understanding the LANDSCAPE, not implementation details:

1. CODEBASE ANALYSIS
   - Existing module boundaries and seam points
   - Shared infrastructure and services
   - Current patterns for the feature's domain
   - Tech stack constraints

2. DOMAIN RESEARCH
   - How similar features are structured in industry
   - Common decomposition patterns for this type of feature
   - Best practices for the interfaces between sub-features

3. CONSTRAINT DISCOVERY
   - Hard dependencies that must be respected
   - Existing APIs/schemas that constrain the design
   - Team/deployment boundaries if relevant

4. SEAM IDENTIFICATION
   - Natural module boundaries in the codebase
   - Points where independent work can happen
   - Shared state or resources that create coupling

Output: research.md at <basePath>/research.md
```

### Research Team Dispatch

Follow `${CLAUDE_PLUGIN_ROOT}/references/parallel-research.md` but with:
- basePath = epic directory (e.g., `./specs/_epics/<epic-name>`)
- Research directive = triage directive above (not standard spec research)

## Step 2: Brainstorming & Decomposition

Delegate to `triage-analyst` agent via Task tool:
- Pass basePath, epicName, goal, and the research output
- The agent runs the brainstorming dialogue and produces `epic.md`
- Wait for the agent to complete

## Step 3: Validation Research

Spawn a focused research pass to validate the proposed decomposition.

### Validation Prompt

```
VALIDATION RESEARCH DIRECTIVE:
Review the proposed epic decomposition in <basePath>/epic.md and validate against the codebase:

For EACH proposed spec:
1. Can it be built independently? Check if its dependencies are correctly identified.
2. Do the interface contracts make sense given actual code structure?
3. Are there hidden shared modules or setup needs not captured?
4. Is the scope realistic for the estimated size?

Also check:
- Are there missing specs? (capabilities the epic needs but didn't capture)
- Are there unnecessary specs? (things the codebase already handles)
- Is the dependency graph correct? (are there missing edges?)

Output findings as a validation section appended to <basePath>/research.md
```

### Validation Dispatch

Spawn a single research-analyst agent (not full team -- this is targeted validation):
- Pass basePath, epicName, and the validation directive
- Agent reads epic.md and validates against codebase
- Appends findings to research.md under a `## Validation Findings` section

## Step 4: Finalize

After validation:

1. If validation surfaced issues:
   - Pass validation findings back to triage-analyst
   - Agent adjusts epic.md (merge/split/reorder specs, fix contracts)
   - Max 2 adjustment rounds

2. Once epic.md is finalized:
   - Ask user: "Where should I store this plan?"
     - **Spec files** -- create individual spec directories with plan.md
     - **GitHub issues** -- create parent issue with sub-issues
     - **Both** -- do both with cross-references

3. Execute chosen output format (see Output Handlers below)

4. Initialize `.epic-state.json`:
   ```json
   {
     "name": "<epic-name>",
     "goal": "<goal>",
     "specs": [
       { "name": "<spec-a>", "status": "pending", "dependencies": [] },
       { "name": "<spec-b>", "status": "pending", "dependencies": ["<spec-a>"] }
     ],
     "output": "<spec-files|github-issues|both>",
     "issueNumber": null
   }
   ```

5. Set `.current-epic` (write epic name to `specs/.current-epic`)

6. Ensure gitignore entry for `specs/.current-epic`

## Output Handlers

### Spec Files Output

For each spec in epic.md:
1. `mkdir -p ./specs/<spec-name>`
2. Create `./specs/<spec-name>/plan.md` with:
   - Goal, acceptance criteria, interface contracts from epic.md
   - Link back to epic: `Epic: specs/_epics/<epic-name>/epic.md`

### GitHub Issues Output

1. Create parent issue with epic.md content:
   ```bash
   gh issue create --title "Epic: <epic-name>" --body "<epic.md content>"
   ```
2. For each spec, create sub-issue:
   ```bash
   gh issue create --title "<spec-name>: <goal>" --body "<spec detail from epic.md>"
   ```
3. Store parent issue number in `.epic-state.json`

### Both Output

Run both handlers. Add cross-references:
- In plan.md: `GitHub Issue: #<number>`
- In GitHub issue body: `Spec files: ./specs/<spec-name>/`

## Epic Status Display

When showing epic status (used by both /triage and /start):

```
Epic: <epic-name>
Goal: <goal>

Progress: <completed>/<total> specs

Completed:
  [x] <spec-a>: <goal>
  [x] <spec-b>: <goal>

Ready (dependencies met):
  [ ] <spec-c>: <goal> (depends on: spec-a, spec-b -- both done)

Blocked:
  [ ] <spec-d>: <goal> (depends on: spec-c -- pending)

-> Suggested next: <first ready spec>
```
```

**Step 2: Verify file exists**

Run: `ls -la plugins/ralph-specum/references/triage-flow.md`
Expected: file exists

**Step 3: Commit**

```bash
git add plugins/ralph-specum/references/triage-flow.md
git commit -m "feat(ralph-specum): add triage-flow reference for explore-brainstorm-validate-finalize"
```

---

### Task 5: Create triage.md command

**Files:**
- Create: `plugins/ralph-specum/commands/triage.md`

**Step 1: Create the command file**

```markdown
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
```

**Step 2: Verify command file has valid frontmatter**

Run: `head -5 plugins/ralph-specum/commands/triage.md`
Expected: YAML frontmatter with description, argument-hint, allowed-tools

**Step 3: Commit**

```bash
git add plugins/ralph-specum/commands/triage.md
git commit -m "feat(ralph-specum): add /triage command for epic decomposition"
```

---

### Task 6: Add epic detection to start.md

**Files:**
- Modify: `plugins/ralph-specum/commands/start.md:54` (Step 4: Route to Action)

**Step 1: Add epic detection before the existing routing logic**

Insert a new section between the current "Step 3: Scan Existing Specs" (ends ~line 50) and "Step 4: Route to Action" (line 54). This becomes a new "Step 3.5" that checks for an active epic before normal routing.

Add this block before line 54 (`## Step 4: Route to Action`):

```markdown
## Step 3.5: Epic Detection

Check if there is an active epic:

```bash
EPIC_FILE="./specs/.current-epic"
if [ -f "$EPIC_FILE" ]; then
  EPIC_NAME=$(cat "$EPIC_FILE" | tr -d '[:space:]')
  EPIC_STATE="./specs/_epics/$EPIC_NAME/.epic-state.json"
fi
```

**If active epic exists AND no specific spec name was provided in $ARGUMENTS**:
1. Read `.epic-state.json`
2. Find specs with status "pending" whose dependencies are all "completed"
3. Display brief epic status:
   ```text
   Active epic: $EPIC_NAME (N/M specs complete)
   Next unblocked: <spec-name> -- <goal>
   ```
4. Ask user: "Start this spec, or work on something else?"
   - If user accepts: set `name` and `goal` from the epic's spec definition, set `epicName` in context, continue to Step 4 (New Flow) with pre-populated values
   - If user declines: continue normal Step 4 routing

**If no active epic AND goal appears complex** (multiple distinct components, cross-cutting concerns, user mentions "big" or "large"):
- Suggest: "This looks like it might need multiple specs. Want to run `/triage` instead?"
- If user accepts: invoke `/ralph-specum:triage` with the goal. STOP.
- If user declines: continue normal Step 4 routing.
```

**Step 2: Add `epicName` to state initialization in New Flow**

In the New Flow section (line 94-104), when a spec is started from an epic, add `epicName` to the initial `.ralph-state.json`:

After the existing state initialization block (line 94-104), add this note:

```markdown
   If this spec was suggested by an active epic, also include:
   ```json
   "epicName": "$EPIC_NAME"
   ```
   in the initial state, and pre-populate the goal and acceptance criteria from `epic.md`.
```

**Step 3: Verify start.md is well-formed**

Run: `head -5 plugins/ralph-specum/commands/start.md`
Expected: valid YAML frontmatter

**Step 4: Commit**

```bash
git add plugins/ralph-specum/commands/start.md
git commit -m "feat(ralph-specum): add epic detection to /start routing"
```

---

### Task 7: Add epic state update to stop-watcher.sh

**Files:**
- Modify: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh:65-81` (after ALL_TASKS_COMPLETE detection)

**Step 1: Add epic state update logic**

After the ALL_TASKS_COMPLETE detection block (line 74, before `exit 0`), add epic state update logic:

```bash
        # Update epic state if this spec belongs to an epic
        EPIC_NAME=$(jq -r '.epicName // empty' "$STATE_FILE" 2>/dev/null || true)
        CURRENT_EPIC_FILE="$CWD/specs/.current-epic"
        if [ -n "$EPIC_NAME" ] && [ -f "$CURRENT_EPIC_FILE" ]; then
            EPIC_STATE_FILE="$CWD/specs/_epics/$EPIC_NAME/.epic-state.json"
            if [ -f "$EPIC_STATE_FILE" ]; then
                # Mark spec as completed in epic state
                jq --arg spec "$SPEC_NAME" '
                  .specs |= map(if .name == $spec then .status = "completed" else . end)
                ' "$EPIC_STATE_FILE" > "$EPIC_STATE_FILE.tmp" && mv "$EPIC_STATE_FILE.tmp" "$EPIC_STATE_FILE"
                echo "[ralph-specum] Updated epic '$EPIC_NAME': spec '$SPEC_NAME' marked completed" >&2
            fi
        fi
```

Insert this BEFORE the `exit 0` on line 74 (inside the first ALL_TASKS_COMPLETE block). Do the same for the fallback detection on line 79.

**Step 2: Verify stop-watcher.sh is valid bash**

Run: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
Expected: no output (valid syntax)

**Step 3: Commit**

```bash
git add plugins/ralph-specum/hooks/scripts/stop-watcher.sh
git commit -m "feat(ralph-specum): update epic state on spec completion in stop-watcher"
```

---

### Task 8: Add .current-epic to gitignore entries

**Files:**
- Modify: `plugins/ralph-specum/commands/start.md` (gitignore step, line 93)

**Step 1: Update the gitignore step**

In the New Flow section, step 6 (line 93) says "Ensure gitignore entries for specs/.current-spec and **/.progress.md". Update to also include `specs/.current-epic`:

Change: `Ensure gitignore entries for specs/.current-spec and **/.progress.md`
To: `Ensure gitignore entries for specs/.current-spec, specs/.current-epic, and **/.progress.md`

Also update the triage.md command to ensure the same gitignore entry when creating an epic.

**Step 2: Commit**

```bash
git add plugins/ralph-specum/commands/start.md
git commit -m "fix(ralph-specum): add .current-epic to gitignore entries"
```

---

### Task 9: Version bump

**Files:**
- Modify: `plugins/ralph-specum/.claude-plugin/plugin.json:3`
- Modify: `.claude-plugin/marketplace.json:13`

**Step 1: Bump plugin version from 4.4.0 to 4.5.0 (minor -- new feature)**

In `plugins/ralph-specum/.claude-plugin/plugin.json`, change:
```json
"version": "4.4.0"
```
to:
```json
"version": "4.5.0"
```

In `.claude-plugin/marketplace.json`, change the ralph-specum entry:
```json
"version": "4.4.0"
```
to:
```json
"version": "4.5.0"
```

**Step 2: Verify version consistency**

Run: `grep '"version"' plugins/ralph-specum/.claude-plugin/plugin.json .claude-plugin/marketplace.json`
Expected: both show "4.5.0" for ralph-specum

**Step 3: Commit**

```bash
git add plugins/ralph-specum/.claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "chore(ralph-specum): bump version to 4.5.0 for epic triage feature"
```

---

### Task 10: Update CLAUDE.md documentation

**Files:**
- Modify: `CLAUDE.md` (Architecture section, Commands table, State Files section)

**Step 1: Add Epics section to Architecture**

After the "### State Files" section, add:

```markdown
### Epics (Multi-Spec Orchestration)

Epics decompose large features into multiple dependency-aware specs.

**File structure:**
```
specs/
  .current-epic          # Points to active epic name
  _epics/
    <epic-name>/
      epic.md            # Triage output (vision, specs, dependency graph)
      research.md        # Exploration + validation research
      .epic-state.json   # Progress tracking across specs
      .progress.md       # Learnings and decisions
```

**Entry points:**
- `/ralph-specum:triage <goal>` -- create or resume an epic
- `/ralph-specum:start` -- detects active epics, suggests next unblocked spec

**Flow:** Explore (research) -> Brainstorm (triage-analyst) -> Validate (research) -> Finalize (output selection)
```

**Step 2: Add triage-analyst to Agents table**

In the Agents table, add:

```markdown
| triage-analyst | `agents/triage-analyst.md` | Feature decomposition, epic creation |
```

**Step 3: Add .epic-state.json to State Files section**

Add:
```markdown
- `./specs/.current-epic` - Active epic name
- `./specs/_epics/<name>/.epic-state.json` - Epic progress (which specs are done/pending/blocked)
```

**Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: add epic triage documentation to CLAUDE.md"
```

---

### Task 11: Update plugin description and keywords

**Files:**
- Modify: `plugins/ralph-specum/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`

**Step 1: Update plugin description to mention epics**

In `plugins/ralph-specum/.claude-plugin/plugin.json`, update the description to include epic/triage:

```json
"description": "Spec-driven development with task-by-task execution. Research, requirements, design, tasks, autonomous implementation, and epic triage for multi-spec feature decomposition.",
"keywords": ["ralph", "spec-driven", "research", "requirements", "design", "tasks", "autonomous", "loop", "epic", "triage"]
```

In `.claude-plugin/marketplace.json`, update the ralph-specum entry description similarly:

```json
"description": "Spec-driven development with research, requirements, design, tasks, autonomous execution, and epic triage. Fresh context per task.",
"tags": ["ralph", "spec-driven", "autonomous", "research", "tasks", "epic", "triage"]
```

**Step 2: Commit**

```bash
git add plugins/ralph-specum/.claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "docs(ralph-specum): update plugin description and keywords for epic triage"
```

---

### Task 12: Manual verification

**Step 1: Verify all new files exist**

Run:
```bash
ls -la plugins/ralph-specum/templates/epic.md \
       plugins/ralph-specum/agents/triage-analyst.md \
       plugins/ralph-specum/references/triage-flow.md \
       plugins/ralph-specum/commands/triage.md
```
Expected: all 4 files exist

**Step 2: Verify schema is valid**

Run: `jq empty plugins/ralph-specum/schemas/spec.schema.json`
Expected: no output (valid JSON)

**Step 3: Verify stop-watcher.sh syntax**

Run: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
Expected: no output (valid bash)

**Step 4: Verify versions match**

Run: `grep -A1 '"ralph-specum"' .claude-plugin/marketplace.json | grep version && grep version plugins/ralph-specum/.claude-plugin/plugin.json`
Expected: both show 4.5.0

**Step 5: Verify CLAUDE.md mentions epics**

Run: `grep -c "epic" CLAUDE.md`
Expected: multiple matches

**Step 6: Test the plugin loads**

Run: `claude --plugin-dir ./plugins/ralph-specum --help 2>&1 | head -5`
Expected: no plugin loading errors
