# PR #96 Review Fixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Address the 6 concrete issues identified in the code review of PR #96 (`feat/plugin-best-practices-v2`).

**Architecture:** All changes are to markdown plugin files in `plugins/ralph-specum/`. No code, no tests — just editorial fixes to resolve duplication, inconsistency, and minor issues across reference files and commands.

**Tech Stack:** Markdown (Claude Code plugin files), git

---

### Task 1: Resolve Layer 5 duplication between coordinator-pattern.md and verification-layers.md

The full Layer 5 artifact review loop is defined in two places:
- `plugins/ralph-specum/references/coordinator-pattern.md:315-428` (114 lines)
- `plugins/ralph-specum/references/verification-layers.md:64-198` (135 lines)

Make `verification-layers.md` the single source of truth. Replace the inline Layer 5 in `coordinator-pattern.md` with a reference pointer.

**Files:**
- Modify: `plugins/ralph-specum/references/coordinator-pattern.md:255-438`
- Reference (read-only): `plugins/ralph-specum/references/verification-layers.md`

**Step 1: Replace inline Layer 5 in coordinator-pattern.md**

In `coordinator-pattern.md`, replace the full "Layer 5: Artifact Review" section (lines 315-428) with a short pointer:

```markdown
**Layer 5: Artifact Review**

After Layers 1-4 pass, run the full artifact review loop defined in `${CLAUDE_PLUGIN_ROOT}/references/verification-layers.md` (section "Layer 5: Artifact Review"). This includes: review delegation prompt, fix task generation on REVIEW_FAIL, review iteration logging, parallel batch handling, and error handling.
```

Keep the "Verification Summary" block (lines 430-438) as-is since it's a useful quick reference that doesn't duplicate logic.

**Step 2: Verify the edit**

Run: `grep -c "Layer 5" plugins/ralph-specum/references/coordinator-pattern.md`
Expected: 2 (the pointer line and the summary list item)

Run: `wc -l plugins/ralph-specum/references/coordinator-pattern.md`
Expected: ~640 lines (down from 750)

**Step 3: Commit**

```bash
git add plugins/ralph-specum/references/coordinator-pattern.md
git commit -m "fix(ralph-specum): deduplicate Layer 5 — single source in verification-layers.md"
```

---

### Task 2: Consolidate redundant mandatory blocks in start.md

`start.md` has three `<mandatory>` blocks at lines 142-200 that all say variations of the same thing:
1. Lines 142-168: "Delegation Requirement" — don't implement yourself
2. Lines 170-188: "Stop After Each Subagent (Normal Mode)" — don't auto-proceed
3. Lines 189-200: "Stop After Subagent Completes" — check awaitingApproval, stop

Blocks 2 and 3 are redundant. Merge into a single block.

**Files:**
- Modify: `plugins/ralph-specum/commands/start.md:142-200`

**Step 1: Replace the three mandatory blocks with two**

Keep block 1 (delegation) as-is. Replace blocks 2 and 3 with a single consolidated block:

```markdown
<mandatory>
## CRITICAL: Stop After Each Subagent (Normal Mode)

After ANY subagent returns in normal mode (no `--quick` flag):

1. Wait for subagent to return
2. Read `$basePath/.ralph-state.json`
3. If `awaitingApproval: true`: STOP IMMEDIATELY
4. Output a brief status message
5. **END YOUR RESPONSE**

**DO NOT:**
- Invoke another subagent in the same response
- Continue to the next phase automatically
- Ask if the user wants to continue

**The user must explicitly run the next command.** This gives them time to review artifacts.

Exception: `--quick` mode runs all phases without stopping.
</mandatory>
```

**Step 2: Verify no duplication remains**

Run: `grep -c "Stop After" plugins/ralph-specum/commands/start.md`
Expected: 1

Run: `wc -l plugins/ralph-specum/commands/start.md`
Expected: ~215 lines (down from 235)

**Step 3: Commit**

```bash
git add plugins/ralph-specum/commands/start.md
git commit -m "fix(ralph-specum): consolidate redundant mandatory blocks in start.md"
```

---

### Task 3: Add non-authoritative note to quick reference in implement.md

`implement.md:144-153` has a "Key Coordinator Behaviors" section that partially restates `coordinator-pattern.md`. Rather than removing it (it's useful as a quick scannable summary), mark it as non-authoritative.

**Files:**
- Modify: `plugins/ralph-specum/commands/implement.md:144`

**Step 1: Add disclaimer to the heading**

Change line 144 from:
```markdown
### Key Coordinator Behaviors (quick reference)
```

To:
```markdown
### Key Coordinator Behaviors (quick reference — see coordinator-pattern.md for authoritative details)
```

**Step 2: Verify**

Run: `grep "quick reference" plugins/ralph-specum/commands/implement.md`
Expected: Contains "see coordinator-pattern.md for authoritative details"

**Step 3: Commit**

```bash
git add plugins/ralph-specum/commands/implement.md
git commit -m "fix(ralph-specum): mark implement.md quick reference as non-authoritative"
```

---

### Task 4: Standardize $SPEC_PATH variable across references

The reference files inconsistently use `$SPEC_PATH` and `./specs/$spec`. Fix this by:
1. Adding explicit `$SPEC_PATH` definition in `implement.md`
2. Replacing `./specs/$spec` with `$SPEC_PATH` in `verification-layers.md` (which is the only reference file using the wrong form)

**Files:**
- Modify: `plugins/ralph-specum/commands/implement.md:21-35`
- Modify: `plugins/ralph-specum/references/verification-layers.md`

**Step 1: Add $SPEC_PATH definition to implement.md**

After the spec validation in Step 1 (line 35), add:

```markdown
4. Set `$SPEC_PATH` to the resolved spec directory path. All references use this variable.
```

Renumber subsequent items.

**Step 2: Replace ./specs/$spec with $SPEC_PATH in verification-layers.md**

Replace all instances of `./specs/$spec` with `$SPEC_PATH` in `verification-layers.md`. There are 9 occurrences (lines 27, 42, 75, 108, 118, 119, 127, 153, 157).

**Step 3: Verify consistency**

Run: `grep -c './specs/\$spec' plugins/ralph-specum/references/verification-layers.md`
Expected: 0

Run: `grep -c '\$SPEC_PATH' plugins/ralph-specum/references/verification-layers.md`
Expected: 9 (all converted)

**Step 4: Commit**

```bash
git add plugins/ralph-specum/commands/implement.md plugins/ralph-specum/references/verification-layers.md
git commit -m "fix(ralph-specum): standardize \$SPEC_PATH variable across references"
```

---

### Task 5: Diversify agent colors

5 of 8 ralph-specum agents use `cyan`. Change to make each role visually distinct.

Current state and proposed changes:

| Agent | Current | Proposed |
|-------|---------|----------|
| architect-reviewer | cyan | cyan (keep — architect) |
| product-manager | cyan | **magenta** |
| qa-engineer | yellow | yellow (keep) |
| refactor-specialist | magenta | magenta (keep) |
| research-analyst | blue | blue (keep) |
| spec-executor | green | green (keep) |
| spec-reviewer | blue | **yellow** |
| task-planner | cyan | **white** |

**Files:**
- Modify: `plugins/ralph-specum/agents/product-manager.md:4`
- Modify: `plugins/ralph-specum/agents/spec-reviewer.md:4`
- Modify: `plugins/ralph-specum/agents/task-planner.md:4`

**Step 1: Change product-manager color**

In `plugins/ralph-specum/agents/product-manager.md`, change `color: cyan` to `color: magenta`.

**Step 2: Change spec-reviewer color**

In `plugins/ralph-specum/agents/spec-reviewer.md`, change `color: blue` to `color: yellow`.

**Step 3: Change task-planner color**

In `plugins/ralph-specum/agents/task-planner.md`, change `color: cyan` to `color: white`.

**Step 4: Verify no duplicate cyan assignments remain excessive**

Run: `grep -r "color:" plugins/ralph-specum/agents/ | sort -t: -k3`
Expected: At most 1 cyan (architect-reviewer), no color used more than twice.

**Step 5: Commit**

```bash
git add plugins/ralph-specum/agents/product-manager.md plugins/ralph-specum/agents/spec-reviewer.md plugins/ralph-specum/agents/task-planner.md
git commit -m "fix(ralph-specum): diversify agent colors for visual distinction"
```

---

### Task 6: Fix interview-framework path references in phase commands

Four phase commands reference the interview framework skill with a relative path `skills/interview-framework/SKILL.md` instead of the standard `${CLAUDE_PLUGIN_ROOT}/skills/interview-framework/SKILL.md`.

**Files:**
- Modify: `plugins/ralph-specum/commands/research.md:46`
- Modify: `plugins/ralph-specum/commands/requirements.md:43`
- Modify: `plugins/ralph-specum/commands/design.md:44`
- Modify: `plugins/ralph-specum/commands/tasks.md:45`

**Step 1: Fix all four files**

In each file, replace:
```markdown
Apply adaptive dialogue from `skills/interview-framework/SKILL.md`.
```

With:
```markdown
Apply adaptive dialogue from `${CLAUDE_PLUGIN_ROOT}/skills/interview-framework/SKILL.md`.
```

**Step 2: Verify all paths are consistent**

Run: `grep -r "interview-framework" plugins/ralph-specum/commands/`
Expected: All 4 lines contain `${CLAUDE_PLUGIN_ROOT}/skills/interview-framework/SKILL.md`

**Step 3: Commit**

```bash
git add plugins/ralph-specum/commands/research.md plugins/ralph-specum/commands/requirements.md plugins/ralph-specum/commands/design.md plugins/ralph-specum/commands/tasks.md
git commit -m "fix(ralph-specum): use \${CLAUDE_PLUGIN_ROOT} for interview-framework path"
```

---

### Task 7: Bump plugin version

All plugin changes require a version bump per CLAUDE.md rules.

**Files:**
- Modify: `plugins/ralph-specum/.claude-plugin/plugin.json`

**Step 1: Bump patch version**

Change `"version": "3.11.0"` to `"version": "3.11.1"`.

**Step 2: Verify**

Run: `grep '"version"' plugins/ralph-specum/.claude-plugin/plugin.json`
Expected: `"version": "3.11.1"`

**Step 3: Commit**

```bash
git add plugins/ralph-specum/.claude-plugin/plugin.json
git commit -m "chore(ralph-specum): bump version to 3.11.1 for review fixes"
```
