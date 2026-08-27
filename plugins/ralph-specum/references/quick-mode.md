# Quick Mode

> Used by: start.md

This reference contains the full quick mode flow triggered only by an exact `--quick` argument token. `-q`, substrings, and natural-language requests never trigger it. Exact `--quick` with exact `--interactive` is an error.

## Quick Mode Input Detection

Tokenize the arguments, remove the exact `--quick` token, and classify the remaining positional input. Preserve other flags for their normal handlers.

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
   { source: "plan", name, goal, basePath, phase: "research",
     taskIndex: 0, totalTasks: 0, taskIteration: 1,
     maxTaskIterations: 5, globalIteration: 1,
     maxGlobalIterations: 100, commitSpec: $commitSpec,
     quickMode: false, discoveredSkills: [] }
5a. Run `phase_gate.py mode "$STATE" --quick` to create the exact persistent quick authorization.
6. Write .progress.md with original goal
7. Update .current-spec (bare name or full path)
8. Update Spec Index: ./plugins/ralph-specum/hooks/scripts/update-spec-index.sh --quiet
9. Skill Discovery Pass 1: follow `normal-mode-gates.md`, including explicit names, all four catalogs, active duplicate resolution, and shadow recording
10. Goal Type Detection (BUG_FIX BEFORE state capture):
    - Classify as "fix" or "add" using regex indicators
    - Fix: fix|resolve|debug|broken|failing|error|bug|crash|issue|not working
    - Add: add|create|build|implement|new|enable|introduce (default)
    - For fix goals, execute sub-steps a-e:
      a. INFER reproduction command from goal text:
         - Scan goal text for backtick-quoted content (e.g., `pnpm test foo`) -- use first match
         - Scan goal text for "run X" or "by running X" patterns -- use captured X
         - Fallback priority: (1) command from goal text, (2) pnpm test / npm test / yarn test (whichever lock file exists), (3) skip with warning logged to .progress.md
      b. RUN the inferred command: capture full stdout, stderr, and exit code
      c. WRITE canonical `## Reality Check (BEFORE)` block to .progress.md:
         ```markdown
         ## Reality Check (BEFORE)
         - Reproduction command: `<exact command>`
         - Exit code: <N>
         - Output: <relevant snippet>
         - Confirmed failing: yes
         - Timestamp: <ISO 8601>
         ```
      d. If exit code != 0 (confirmed failing): continue to step 11
      e. If exit code == 0 (NOT confirmed failing): append WARNING to .progress.md and continue
         (non-interactive -- do not block or prompt user)
         ```markdown
         ## Reality Check (BEFORE)
         - Reproduction command: `<exact command>`
         - Exit code: 0
         - Output: <relevant snippet>
         - Confirmed failing: no
         - WARNING: Reproduction command exited 0; bug may not be reproducible with this command
         - Timestamp: <ISO 8601>
         ```
11. Research Phase: reload selected contracts and record the current `start` manifest; call `begin-interview` for phase `start` to record `bypassed_quick`; run `check-delegation`; create the native task; run Team Research with a gate marker and unique artifact agent ID per research teammate; skip walkthrough; clear awaitingApproval; mark the native task complete
12. Skill Discovery Pass 2: follow `normal-mode-gates.md` using goal + research Executive Summary
13. Requirements Phase: reload selected contracts and record the current `requirements` manifest; call `begin-interview`; run `check-delegation`; create the native task; delegate to product-manager with a unique artifact agent ID, gate marker, manifest, and Quick Mode Directive; run review loop; mark complete
14. Design Phase: reload selected contracts and record the current `design` manifest; call `begin-interview`; run `check-delegation`; create the native task; delegate to architect-reviewer with a unique artifact agent ID, gate marker, manifest, and Quick Mode Directive; run review loop; mark complete
15. Tasks Phase: reload selected contracts and record the current `tasks` manifest; call `begin-interview`; run `check-delegation`; create the native task; delegate to task-planner with a unique artifact agent ID, gate marker, manifest, and Quick Mode Directive; run review loop; mark complete
16. Transition to Execution:
    - Count total tasks (number of `- [ ]` checkboxes)
    - Update state: phase="execution", totalTasks=<count>, taskIndex=0
    - If commitSpec: stage, commit, push spec files
17. Invoke spec-executor for task 1
```

## Step 9: Skill Discovery Pass 1

Follow `${CLAUDE_PLUGIN_ROOT}/references/normal-mode-gates.md` exactly. Do not use keyword overlap as a substitute for explicit names and semantic relevance. Store selected active sources, shadowed duplicates, warnings, and pass revision.

## Step 12: Skill Discovery Pass 2

After research and before requirements, follow pass 2 in `normal-mode-gates.md`. Retain pass 1 selections and add newly relevant active sources. Record shadowed duplicates and failures.

## Quick Mode Directive

Each agent delegation in steps 11-15 includes this directive in the Task prompt:

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

Each artifact Task also includes a unique artifact agent ID, the `[RALPH_PHASE_GATE]` marker, and the full selected-skill manifest. Run `check-delegation` immediately before the Task. The artifact agent records one load receipt per successfully loaded selected body/resource and calls `check-agent-write` with the marker's phase, interview ID, discovery revision, context digest, and unique agent ID before its first write.

## Quick Mode Review Loop (Per Artifact)

After each phase agent returns in steps 13-15, run spec-reviewer to validate:

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
     - REVIEW_FAIL (iteration < 3): Run parent `check-delegation`, create a fresh unique artifact agent ID, and dispatch the phase artifact agent with reviewer feedback, current artifact, gate marker, and full manifest. The agent reloads successful sources, records its own receipts, calls `check-agent-write`, revises, then increment iteration
     - REVIEW_FAIL (iteration >= 3): Append warning to .progress.md, proceed
     - No signal: Treat as REVIEW_PASS (permissive)
```

`spec-reviewer` is read-only and does not need the artifact write gate. Every revision writer is a new gated dispatch; never reuse another run's receipt identity.

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
