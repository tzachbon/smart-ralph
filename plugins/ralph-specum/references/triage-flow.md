# Triage Flow: Explore-Brainstorm-Validate-Finalize

> Used by: triage.md

## Overview

The triage flow decomposes a large feature into multiple specs. It uses two research passes (explore + validate) sandwiching a brainstorming/decomposition phase.

## Step 1: Exploration Research

Spawn research team (same parallel-research pattern as /start) with a triage-focused prompt.

### Research Prompt Customization

When spawning the research team, use this directive instead of the standard spec research directive:

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
   ```
   gh issue create --title "Epic: <epic-name>" --body "<epic.md content>"
   ```
2. For each spec, create sub-issue:
   ```
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
