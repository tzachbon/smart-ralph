# Quick Mode

> Used by: start.md

This reference contains the full quick mode flow triggered by the `--quick` flag, including input detection, validation, execution sequence, review loops, and rollback.

## Quick Mode Input Detection

Parse arguments before `--quick` flag and classify input type:

```text
Input Classification:

1. TWO ARGS before --quick:
   - First arg = spec name (must be kebab-case: ^[a-z0-9-]+$)
   - Second arg = goal string OR file path
   - Detect file path if: starts with "./" OR "/" OR ends with ".md"
   - Examples:
     - `my-feature "Add login" --quick` -> name=my-feature, goal="Add login"
     - `my-feature ./plan.md --quick` -> name=my-feature, file=./plan.md

2. ONE ARG before --quick:
   a. FILE PATH: starts with "./" OR "/" OR ends with ".md"
      - Read file content as plan
      - Infer name from plan content
   b. KEBAB-CASE NAME: matches ^[a-z0-9-]+$
      - Check if ./specs/$name/plan.md exists
      - If exists: use plan.md content
      - If not: error "No plan.md found"
   c. GOAL STRING: anything else
      - Use as goal content, infer name

3. ZERO ARGS with --quick:
   - Error: "Quick mode requires a goal or plan file"
```

## File Reading

When file path detected:
1. Validate file exists using Read tool
2. If not exists: error "File not found: $filePath"
3. Read file content
4. Strip frontmatter if present (content between --- markers at start)
5. If content empty after stripping: error "Plan content is empty."
6. Use content as planContent

## Quick Mode Validation

```text
Validation Sequence:

1. ZERO ARGS CHECK -> Error if no args before --quick
2. --specs-dir VALIDATION -> Error if not in configured list
3. FILE NOT FOUND -> Error if file path doesn't exist
4. EMPTY CONTENT CHECK -> Error if empty/whitespace only
5. PLAN TOO SHORT WARNING (< 10 words) -> Warning, continue
6. NAME CONFLICT RESOLUTION -> Append -2, -3, etc. if exists
```

## Quick Mode Execution Sequence

```text
1. Validate input (non-empty goal/plan)
2. Infer name from goal (if not provided)
3. Determine spec directory using path resolver:
   specsDir = (--specs-dir value if valid) OR ralph_get_default_dir()
   basePath = "$specsDir/$name"
4. Create spec directory: mkdir -p "$basePath"
4a. Ensure gitignore entries exist (.current-spec, .progress.md)
5. Write .ralph-state.json:
   { source: "plan", name, basePath, phase: "research",
     taskIndex: 0, totalTasks: 0, taskIteration: 1,
     maxTaskIterations: 5, globalIteration: 1,
     maxGlobalIterations: 100, commitSpec: $commitSpec,
     quickMode: true, discoveredSkills: [] }
6. Write .progress.md with original goal
7. Update .current-spec (bare name or full path)
8. Update Spec Index: ./plugins/ralph-specum/hooks/scripts/update-spec-index.sh --quiet
8.5. Skill Discovery Pass 1: scan skills, match against goal text, invoke matches
9. Goal Type Detection:
   - Classify as "fix" or "add" using regex indicators
   - Fix: fix|resolve|debug|broken|failing|error|bug|crash|issue|not working
   - Add: add|create|build|implement|new|enable|introduce (default)
   - For fix goals: run reproduction, document BEFORE state
10. Research Phase: run Team Research flow (skip walkthrough), clear awaitingApproval
10.5. Skill Discovery Pass 2: re-scan skills using goal + research Executive Summary, invoke new matches
11. Requirements Phase: delegate to product-manager with Quick Mode Directive, review loop
12. Design Phase: delegate to architect-reviewer with Quick Mode Directive, review loop
13. Tasks Phase: delegate to task-planner with Quick Mode Directive, review loop
14. Transition to Execution:
    - Count total tasks (number of `- [ ]` checkboxes)
    - Update state: phase="execution", totalTasks=<count>, taskIndex=0
    - If commitSpec: stage, commit, push spec files
15. Invoke spec-executor for task 1
```

## Step 8.5: Skill Discovery Pass 1

Scan all skill files and match against the goal text:

1. Read each `${CLAUDE_PLUGIN_ROOT}/skills/*/SKILL.md` file's YAML frontmatter (`name`, `description` fields)
2. Determine **context text**: the goal text only (from step 1)
3. Tokenize both context text and each skill's `description` using these rules:
   a. Lowercase the entire string
   b. Replace hyphens with spaces ("brainstorming-style" -> "brainstorming style")
   c. Strip all punctuation (parentheses, commas, periods, colons, quotes, brackets, etc.)
   d. Split on whitespace into word tokens
   e. Remove stopwords: a, an, the, to, for, with, and, or, in, on, by, is, be, that, this, of, it, should, used, when, asks, needs, about
4. Count word overlap between context tokens and description tokens
5. If overlap >= 2 AND skill not already in `discoveredSkills` with `invoked: true`:
   - Invoke: `Skill({ skill: "ralph-specum:<name>" })`
   - On success: add `{ name, matchedAt: "start", invoked: true }` to `discoveredSkills`
   - On failure: add `{ name, matchedAt: "start", invoked: false }`, log warning, continue
6. Update `.ralph-state.json` with updated `discoveredSkills` array
7. Append a `## Skill Discovery` section to `.progress.md` with match details per skill:
   ```markdown
   ## Skill Discovery
   - **<skill-name>**: matched (keywords: <overlapping words>)
   - **<skill-name>**: no match
   ```
   If no skills match: `- No skills matched`

## Step 10.5: Skill Discovery Pass 2 (Post-Research Retry)

Re-scan skills with enriched context after research completes:

1. Read each `${CLAUDE_PLUGIN_ROOT}/skills/*/SKILL.md` file's YAML frontmatter (`name`, `description` fields)
2. Determine **context text**: goal text + the **Executive Summary** section from `research.md`
3. Tokenize both context text and each skill's `description` using these rules:
   a. Lowercase the entire string
   b. Replace hyphens with spaces ("brainstorming-style" -> "brainstorming style")
   c. Strip all punctuation (parentheses, commas, periods, colons, quotes, brackets, etc.)
   d. Split on whitespace into word tokens
   e. Remove stopwords: a, an, the, to, for, with, and, or, in, on, by, is, be, that, this, of, it, should, used, when, asks, needs, about
4. Count word overlap between context tokens and description tokens
5. If overlap >= 2 AND skill not already in `discoveredSkills` with `invoked: true`:
   - Invoke: `Skill({ skill: "ralph-specum:<name>" })`
   - On success: add `{ name, matchedAt: "post-research", invoked: true }` to `discoveredSkills`
   - On failure: add `{ name, matchedAt: "post-research", invoked: false }`, log warning, continue
6. Update `.ralph-state.json` with updated `discoveredSkills` array
7. Append a `### Post-Research Retry` subsection to `.progress.md` under `## Skill Discovery`:
   ```markdown
   ### Post-Research Retry
   - **<skill-name>**: matched (keywords: <overlapping words>)
   - **<skill-name>**: no match (already invoked)
   ```
   If no new skills match: `- No new skills matched`

## Quick Mode Directive

Each agent delegation in steps 10-13 includes this directive in the Task prompt:

```text
Quick Mode Context:
Running in quick mode with no user feedback. You MUST:
- Make strong, opinionated decisions instead of deferring to user
- Choose the simplest, most conventional approach
- Be more critical of your own output
- Prefer existing codebase patterns over novel approaches
- Keep scope tight - interpret the goal strictly, do not expand
- Add `generated: auto` to frontmatter of all artifacts you produce
```

## Quick Mode Review Loop (Per Artifact)

After each phase agent returns in steps 11-13, run spec-reviewer to validate:

```text
Set iteration = 1

WHILE iteration <= 3:
  1. Read the artifact content from $basePath/<artifact>.md
  2. Invoke spec-reviewer via Task tool:
     subagent_type: spec-reviewer
     Review the $artifactType artifact for spec: $name
     Spec path: $basePath/
     Review iteration: $iteration of 3
  3. Parse signal:
     - REVIEW_PASS: Proceed to next phase
     - REVIEW_FAIL (iteration < 3): Revise artifact, increment iteration
     - REVIEW_FAIL (iteration >= 3): Append warning to .progress.md, proceed
     - No signal: Treat as REVIEW_PASS (permissive)
```

## Atomic Rollback

On generation failure after spec directory created:

```text
Rollback Procedure:
1. CAPTURE FAILURE - Phase agent returns error or times out
2. DELETE SPEC DIRECTORY - rm -rf "$basePath"
3. RESTORE .current-spec - If previous spec was set, restore it
4. DISPLAY ERROR - "Generation failed: $errorReason. No spec created."
```

## Quick Mode Branch Handling

In `--quick` mode, still perform branch check but skip user prompts:
- If on default branch: auto-create feature branch in current directory (no worktree prompt)
- If on non-default branch: stay on current branch (no prompt, quick mode is non-interactive)
