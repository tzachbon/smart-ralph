# CI Fix + CodeRabbit Review Comments Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix the CI failure (marketplace.json version mismatch for ralph-speckit) and address 6 actionable CodeRabbit review comments on PR #96.

**Architecture:** All changes are to markdown plugin files. One CI-blocking fix, then editorial/logic fixes to reference files, commands, and templates.

**Tech Stack:** Markdown (Claude Code plugin files), git

---

### Task 1: Fix CI — bump ralph-speckit version in marketplace.json

CI fails because `ralph-speckit` plugin.json is 0.5.1 but marketplace.json still has 0.5.0.

**Files:**
- Modify: `.claude-plugin/marketplace.json:30`

**Step 1: Bump the version**

Change the `ralph-speckit` entry's version from `"0.5.0"` to `"0.5.1"` in `.claude-plugin/marketplace.json`.

**Step 2: Verify**

Run: `jq -r '.plugins[] | "\(.name): \(.version)"' .claude-plugin/marketplace.json`
Expected:
```
ralph-specum: 3.11.1
ralph-speckit: 0.5.1
```

**Step 3: Commit and push**

```bash
git add .claude-plugin/marketplace.json
git commit -m "fix: sync ralph-speckit marketplace.json version to 0.5.1"
git push
```

---

### Task 2: Add explicit jq merge guidance for state updates in phase commands

The "Update State" sections in design.md:153, requirements.md:150, and research.md:165 are ambiguous — they show JSON fields to set but don't say to merge (not replace). This can silently destroy fields set by start.md (source, name, basePath, commitSpec, relatedSpecs).

**Files:**
- Modify: `plugins/ralph-specum/commands/design.md:151-154`
- Modify: `plugins/ralph-specum/commands/requirements.md:148-151`
- Modify: `plugins/ralph-specum/commands/research.md:162-166`

**Step 1: Fix design.md**

Replace:
```markdown
1. Update `.ralph-state.json`: `{ "phase": "design", "awaitingApproval": true }`
```

With:
```markdown
1. **Merge** into `.ralph-state.json` (preserve all existing fields):
   ```bash
   jq '. + {"phase": "design", "awaitingApproval": true}' \
     "$SPEC_PATH/.ralph-state.json" > "$SPEC_PATH/.ralph-state.json.tmp" && \
     mv "$SPEC_PATH/.ralph-state.json.tmp" "$SPEC_PATH/.ralph-state.json"
   ```
```

**Step 2: Fix requirements.md**

Same pattern — replace the ambiguous line with explicit merge:
```markdown
1. **Merge** into `.ralph-state.json` (preserve all existing fields):
   ```bash
   jq '. + {"phase": "requirements", "awaitingApproval": true}' \
     "$SPEC_PATH/.ralph-state.json" > "$SPEC_PATH/.ralph-state.json.tmp" && \
     mv "$SPEC_PATH/.ralph-state.json.tmp" "$SPEC_PATH/.ralph-state.json"
   ```
```

**Step 3: Fix research.md**

Same pattern with phase-specific fields:
```markdown
1. Parse "Related Specs" table from research.md
2. **Merge** into `.ralph-state.json` (preserve all existing fields):
   ```bash
   jq --argjson specs "$RELATED_SPECS_JSON" \
     '. + {"phase": "research", "awaitingApproval": true, "relatedSpecs": $specs}' \
     "$SPEC_PATH/.ralph-state.json" > "$SPEC_PATH/.ralph-state.json.tmp" && \
     mv "$SPEC_PATH/.ralph-state.json.tmp" "$SPEC_PATH/.ralph-state.json"
   ```
```

**Step 4: Commit**

```bash
git add plugins/ralph-specum/commands/design.md plugins/ralph-specum/commands/requirements.md plugins/ralph-specum/commands/research.md
git commit -m "fix(ralph-specum): add explicit jq merge for state updates in phase commands"
```

---

### Task 3: Add explicit teammate name in spawn steps for phase commands

The phase commands hardcode teammate names in shutdown (e.g. `"planner-1"`, `"architect-1"`, `"pm-1"`) without setting them in the spawn step. If the runtime assigns a different name, shutdown silently fails.

Fix: Add explicit `name:` parameter to the spawn step in each command.

**Files:**
- Modify: `plugins/ralph-specum/commands/tasks.md:86,93`
- Modify: `plugins/ralph-specum/commands/design.md:81,83`
- Modify: `plugins/ralph-specum/commands/requirements.md:80,82`

**Step 1: Fix tasks.md**

In Step 3 item 4, change the spawn instruction to include explicit name:
```markdown
4. **Spawn teammate**: `Task(subagent_type: task-planner, team_name: "tasks-$spec", name: "planner-1")` — delegate with requirements, design, and interview context. Instruct to:
```

This documents that `"planner-1"` is the canonical name set at spawn time, matching the shutdown recipient in item 6.

**Step 2: Fix design.md**

Same pattern for architect-reviewer:
```markdown
4. **Spawn teammate**: `Task(subagent_type: architect-reviewer, team_name: "design-$spec", name: "architect-1")` — delegate with requirements, research, and interview context. Instruct to design architecture with mermaid diagrams, component responsibilities, technical decisions with rationale, file structure, error handling, test strategy. Output to `./specs/$spec/design.md`.
```

**Step 3: Fix requirements.md**

Same pattern for product-manager:
```markdown
4. **Spawn teammate**: `Task(subagent_type: product-manager, team_name: "requirements-$spec", name: "pm-1")` — delegate with research context, goal, and interview context. Instruct to create user stories with acceptance criteria, functional requirements (FR-*), non-functional requirements (NFR-*), glossary, out-of-scope, dependencies. Output to `./specs/$spec/requirements.md`.
```

**Step 4: Commit**

```bash
git add plugins/ralph-specum/commands/tasks.md plugins/ralph-specum/commands/design.md plugins/ralph-specum/commands/requirements.md
git commit -m "fix(ralph-specum): add explicit teammate name in spawn steps"
```

---

### Task 4: Remove redundant Sequential Review Pattern — Layer 5 already covers this

In coordinator-pattern.md, the Sequential Review Pattern (lines 236-251) runs AFTER all 5 verification layers pass, including Layer 5 (Artifact Review) which already invokes spec-reviewer with up to 3 iterations and fix task generation. This means spec-reviewer runs twice per task in normal mode (up to 5 invocations total).

Remove the Sequential Review Pattern. Layer 5 is more comprehensive (checks against design.md/requirements.md, has fix task generation).

**Files:**
- Modify: `plugins/ralph-specum/references/coordinator-pattern.md:236-251`
- Modify: `plugins/ralph-specum/commands/implement.md:151` (remove reference to sequential review)
- Delete: `plugins/ralph-specum/templates/prompts/reviewer-prompt.md` (no longer used)

**Step 1: Remove Sequential Review Pattern from coordinator-pattern.md**

Delete the entire "## Sequential Review Pattern" section (lines 236-251). This is the block starting with `## Sequential Review Pattern` and ending before `## Verification Layers`.

**Step 2: Remove sequential review reference from implement.md**

In `implement.md`, line 151 says:
```
- **After TASK_COMPLETE.** Run all 5 verification layers, then update state (advance taskIndex, reset taskIteration). In normal mode (not --quick), each completed task goes through a sequential review step before advancing. See coordinator-pattern.md for details.
```

Replace with:
```
- **After TASK_COMPLETE.** Run all 5 verification layers, then update state (advance taskIndex, reset taskIteration).
```

**Step 3: Delete reviewer-prompt.md**

```bash
rm plugins/ralph-specum/templates/prompts/reviewer-prompt.md
```

This template was only used by the Sequential Review Pattern.

**Step 4: Commit**

```bash
git add plugins/ralph-specum/references/coordinator-pattern.md plugins/ralph-specum/commands/implement.md
git rm plugins/ralph-specum/templates/prompts/reviewer-prompt.md
git commit -m "fix(ralph-specum): remove redundant Sequential Review Pattern (Layer 5 covers this)"
```

---

### Task 5: Fix recovery mode vs Layer 3 checkmark mismatch

When recovery mode generates fix tasks that get marked [x], the extra checkmarks cause Layer 3 to reject the original task completion (expected count is taskIndex + 1, but actual is higher due to fix task checkmarks).

Fix: Skip verification layers for fix-task completions (they're intermediate), and adjust Layer 3's expected count for original tasks when fix tasks exist.

**Files:**
- Modify: `plugins/ralph-specum/references/failure-recovery.md` (add fix-task verification bypass)
- Modify: `plugins/ralph-specum/references/verification-layers.md:37-51` (adjust Layer 3 for recovery mode)
- Modify: `plugins/ralph-specum/references/coordinator-pattern.md` (add fix-task bypass in After Delegation)

**Step 1: Add fix-task verification bypass to coordinator-pattern.md**

In the "After Delegation" section (around line 219), after checking for TASK_MODIFICATION_REQUEST, add a new rule:

```markdown
**Fix Task Bypass**: If the just-completed task is a fix task (task ID contains `[FIX`), skip verification layers and proceed directly to retry the original task per failure-recovery.md "Execute Fix Task and Retry Original" section.
```

**Step 2: Adjust Layer 3 in verification-layers.md**

Replace the current Layer 3 expected count logic:
```markdown
Expected checkmark count = taskIndex + 1 (0-based index, so task 0 complete = 1 checkmark).
```

With:
```markdown
Expected checkmark count calculation:
- **Standard mode**: taskIndex + 1 (0-based index, so task 0 complete = 1 checkmark)
- **Recovery mode** (recoveryMode = true in state): taskIndex + 1 + total completed fix tasks for indices <= taskIndex. Calculate by summing `fixTaskMap[id].fixTaskIds.length` for all task IDs whose base index <= taskIndex. This accounts for fix task checkmarks inserted into tasks.md.

```bash
# Standard mode
EXPECTED=$((taskIndex + 1))

# Recovery mode adjustment
if [ "$RECOVERY_MODE" = "true" ]; then
  FIX_COUNT=$(jq --argjson idx "$taskIndex" '
    [.fixTaskMap // {} | to_entries[] | select(.key | split(".")[0] | tonumber <= $idx) | .value.fixTaskIds | length] | add // 0
  ' "$SPEC_PATH/.ralph-state.json")
  EXPECTED=$((EXPECTED + FIX_COUNT))
fi
```
```

**Step 3: Add note to failure-recovery.md**

At the end of the "Execute Fix Task and Retry Original" section, add:

```markdown
**Verification Layer Bypass**: When a fix task completes (TASK_COMPLETE), the coordinator MUST NOT run the 5 verification layers. Fix tasks are intermediate — only the original task's completion triggers full verification. After fix task TASK_COMPLETE, proceed directly to "Retry Original Task".
```

**Step 4: Commit**

```bash
git add plugins/ralph-specum/references/coordinator-pattern.md plugins/ralph-specum/references/verification-layers.md plugins/ralph-specum/references/failure-recovery.md
git commit -m "fix(ralph-specum): fix recovery mode vs Layer 3 checkmark mismatch"
```

---

### Task 6: Use ralph_find_spec() in intent-classification.md quick mode

Lines 88-92 in intent-classification.md hardcode `./specs/$name/plan.md` which breaks non-default specs-dir configs.

**Files:**
- Modify: `plugins/ralph-specum/references/intent-classification.md:88-92`

**Step 1: Replace hardcoded path with ralph_find_spec()**

Replace lines 88-92:
```markdown
   b. KEBAB-CASE NAME: matches ^[a-z0-9-]+$
      - Check if ./specs/$name/plan.md exists
      - If exists: use plan.md content, name=$name
      - If not exists: error "No plan.md found in ./specs/$name/. Provide goal: /ralph-specum:start $name 'your goal' --quick"
      - Example: `my-feature --quick` -> check ./specs/my-feature/plan.md
```

With:
```markdown
   b. KEBAB-CASE NAME: matches ^[a-z0-9-]+$
      - Use `ralph_find_spec($name)` to resolve spec path
      - If found and `$specPath/plan.md` exists: use plan.md content, name=$name
      - If found but no plan.md: error "No plan.md found in $specPath/. Provide goal: /ralph-specum:start $name 'your goal' --quick"
      - If not found: error "Spec '$name' not found. Provide goal: /ralph-specum:start $name 'your goal' --quick"
      - Example: `my-feature --quick` -> resolve spec path, check plan.md
```

**Step 2: Commit**

```bash
git add plugins/ralph-specum/references/intent-classification.md
git commit -m "fix(ralph-specum): use ralph_find_spec() in quick mode intent classification"
```

---

### Task 7: Add BASE_PATH and TOPIC_SLUG to research-prompt.md

The research-prompt.md template instructs the analyst to write to `.research-{TOPIC}.md` with no path prefix, so files land in cwd instead of the spec directory. Also, `{TOPIC}` may contain spaces.

**Files:**
- Modify: `plugins/ralph-specum/templates/prompts/research-prompt.md:4,35`

**Step 1: Update placeholder list and output instruction**

Change line 4 from:
```markdown
> Placeholders: {SPEC_NAME}, {GOAL}, {TOPIC}, {EXISTING_SPECS}, {CODEBASE_CONTEXT}
```

To:
```markdown
> Placeholders: {SPEC_NAME}, {GOAL}, {TOPIC}, {TOPIC_SLUG}, {BASE_PATH}, {EXISTING_SPECS}, {CODEBASE_CONTEXT}
```

Change line 35 from:
```markdown
Write your findings to a temporary file `.research-{TOPIC}.md` with these sections:
```

To:
```markdown
Write your findings to a temporary file `{BASE_PATH}/.research-{TOPIC_SLUG}.md` with these sections:
```

**Step 2: Commit**

```bash
git add plugins/ralph-specum/templates/prompts/research-prompt.md
git commit -m "fix(ralph-specum): add BASE_PATH and TOPIC_SLUG placeholders to research-prompt.md"
```

---

### Task 8: Bump plugin version to 3.11.2

**Files:**
- Modify: `plugins/ralph-specum/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`

**Step 1: Bump both files**

Change version in both files from `"3.11.1"` to `"3.11.2"`.

**Step 2: Verify sync**

Run: `jq -r '.plugins[] | select(.name=="ralph-specum") | .version' .claude-plugin/marketplace.json`
Expected: `3.11.2`

Run: `jq -r '.version' plugins/ralph-specum/.claude-plugin/plugin.json`
Expected: `3.11.2`

**Step 3: Commit and push**

```bash
git add plugins/ralph-specum/.claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "chore(ralph-specum): bump version to 3.11.2 for review comment fixes"
git push
```
