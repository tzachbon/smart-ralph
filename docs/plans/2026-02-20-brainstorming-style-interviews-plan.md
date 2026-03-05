# Brainstorming-Style Phase Interviews Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace fixed question pool interviews with adaptive brainstorming-style dialogue across all 4 Ralph Specum phases.

**Architecture:** Rewrite the `interview-framework` skill from a fixed-pool loop to a 3-phase brainstorming algorithm (Understand → Propose Approaches → Confirm & Store). Update each phase command's Interview section to provide "exploration territories" instead of question pool tables.

**Tech Stack:** Markdown prompt files (Claude Code plugin system). No build step.

**Design doc:** `docs/plans/2026-02-20-brainstorming-style-interviews-design.md`

---

### Task 1: Rewrite interview-framework skill

**Files:**
- Modify: `plugins/ralph-specum/skills/interview-framework/SKILL.md` (full content replacement)

**Step 1: Write the new skill content**

Replace the entire content of `SKILL.md` with the new brainstorming-style algorithm. The new skill has 3 phases:

1. **UNDERSTAND** - Adaptive dialogue loop (context-driven, not pool-driven)
2. **PROPOSE APPROACHES** - 2-3 phase-specific approaches with trade-offs
3. **CONFIRM & STORE** - Recap and store in .progress.md

Preserve from old skill:
- Frontmatter (name, description — update description)
- Option limit rule (2-4 options, max 4)
- Completion signal detection
- Context accumulator pattern (.progress.md storage format)
- Adaptive depth on "Other" responses (context-specific follow-ups)

Remove from old skill:
- Single-Question Loop Structure (the fixed pool algorithm)
- Canonical Semantic Keys table
- Parameter Chain Logic (rigid key-matching)
- Question Piping table (replaced with inline instructions)

Add to new skill:
- 3-phase algorithm with pseudocode
- Adaptive question generation instructions
- Context-based skip logic (semantic, not key-based)
- Approach proposal format and rules
- Confirm & store step
- Per-phase approach examples table

**Step 2: Verify the file reads correctly**

Run: `wc -l plugins/ralph-specum/skills/interview-framework/SKILL.md`
Expected: Roughly 150-200 lines (was 195)

**Step 3: Commit**

```bash
git add plugins/ralph-specum/skills/interview-framework/SKILL.md
git commit -m "feat(ralph-specum): rewrite interview-framework as brainstorming-style dialogue"
```

---

### Task 2: Update research.md Interview section

**Files:**
- Modify: `plugins/ralph-specum/commands/research.md` (lines ~107-185 only)

**Step 1: Replace the Interview section**

Remove these subsections (between `## Interview` and `## Execute Research`):
- `### Research Interview (Single-Question Flow)`
- `### Phase-Specific Configuration`
- `### Research Interview Question Pool` (the table)
- `### Store Research Interview Responses`
- `### Interview Context Format`

Replace with:
- `### Brainstorming Dialogue` — reference to interview-framework skill
- `### Research Exploration Territory` — bullet list of areas to probe
- `### Research Approach Proposals` — instructions for proposing 2-3 research strategies
- `### Store Interview & Approach` — how to store in .progress.md

Keep unchanged:
- `### Quick Mode Check`
- `### Read Context from .progress.md`
- Everything before `## Interview` and after `## Execute Research`

**Step 2: Verify no broken references**

Run: `grep -n "Question Pool\|Single-Question Flow\|Phase-Specific Configuration" plugins/ralph-specum/commands/research.md`
Expected: No matches (these sections were removed)

Run: `grep -n "interview-framework" plugins/ralph-specum/commands/research.md`
Expected: At least 1 match (reference to the skill)

**Step 3: Commit**

```bash
git add plugins/ralph-specum/commands/research.md
git commit -m "feat(ralph-specum): replace research interview with brainstorming dialogue"
```

---

### Task 3: Update requirements.md Interview section

**Files:**
- Modify: `plugins/ralph-specum/commands/requirements.md` (lines ~84-131 only)

**Step 1: Replace the Interview section**

Same pattern as Task 2. Remove fixed question pool subsections. Replace with:
- `### Brainstorming Dialogue` — reference to interview-framework skill
- `### Requirements Exploration Territory` — users, priorities, success criteria, scope, compliance
- `### Requirements Approach Proposals` — instructions for proposing 2-3 scoping approaches
- `### Store Interview & Approach`

Keep the same sections unchanged as Task 2.

**Step 2: Verify no broken references**

Run: `grep -n "Question Pool\|Single-Question Flow\|Phase-Specific Configuration" plugins/ralph-specum/commands/requirements.md`
Expected: No matches

**Step 3: Commit**

```bash
git add plugins/ralph-specum/commands/requirements.md
git commit -m "feat(ralph-specum): replace requirements interview with brainstorming dialogue"
```

---

### Task 4: Update design.md Interview section

**Files:**
- Modify: `plugins/ralph-specum/commands/design.md` (lines ~86-131 only)

**Step 1: Replace the Interview section**

Same pattern. Remove fixed question pool subsections. Replace with:
- `### Brainstorming Dialogue` — reference to interview-framework skill
- `### Design Exploration Territory` — architecture fit, tech constraints, integration, failures, deployment
- `### Design Approach Proposals` — instructions for proposing 2-3 architectural approaches
- `### Store Interview & Approach`

**Step 2: Verify no broken references**

Run: `grep -n "Question Pool\|Single-Question Flow\|Phase-Specific Configuration" plugins/ralph-specum/commands/design.md`
Expected: No matches

**Step 3: Commit**

```bash
git add plugins/ralph-specum/commands/design.md
git commit -m "feat(ralph-specum): replace design interview with brainstorming dialogue"
```

---

### Task 5: Update tasks.md Interview section

**Files:**
- Modify: `plugins/ralph-specum/commands/tasks.md` (lines ~87-131 only)

**Step 1: Replace the Interview section**

Same pattern. Remove fixed question pool subsections. Replace with:
- `### Brainstorming Dialogue` — reference to interview-framework skill
- `### Tasks Exploration Territory` — testing depth, deployment, execution priority, dependencies, workflow
- `### Tasks Approach Proposals` — instructions for proposing 2-3 execution strategies
- `### Store Interview & Approach`

**Step 2: Verify no broken references**

Run: `grep -n "Question Pool\|Single-Question Flow\|Phase-Specific Configuration" plugins/ralph-specum/commands/tasks.md`
Expected: No matches

**Step 3: Commit**

```bash
git add plugins/ralph-specum/commands/tasks.md
git commit -m "feat(ralph-specum): replace tasks interview with brainstorming dialogue"
```

---

### Task 6: Version bump

**Files:**
- Modify: `plugins/ralph-specum/.claude-plugin/plugin.json` (version field)
- Modify: `.claude-plugin/marketplace.json` (version field for ralph-specum)

**Step 1: Bump version**

This is a minor feature change (new interview behavior, no breaking changes to commands or agents). Bump from `3.8.0` to `3.9.0`.

Update both files.

**Step 2: Verify versions match**

Run: `grep '"version"' plugins/ralph-specum/.claude-plugin/plugin.json .claude-plugin/marketplace.json`
Expected: Both show `"3.9.0"`

**Step 3: Commit**

```bash
git add plugins/ralph-specum/.claude-plugin/plugin.json .claude-plugin/marketplace.json
git commit -m "chore(ralph-specum): bump version to 3.9.0"
```

---

### Task 7: Update skill description in plugin.json

**Files:**
- Modify: `plugins/ralph-specum/.claude-plugin/plugin.json` (skills section, if interview-framework is listed)

**Step 1: Check if skill is registered**

Run: `grep -A2 "interview-framework" plugins/ralph-specum/.claude-plugin/plugin.json`

If listed, update the description to reflect the new brainstorming-style behavior.

**Step 2: Commit (if changed)**

```bash
git add plugins/ralph-specum/.claude-plugin/plugin.json
git commit --amend --no-edit  # fold into version bump commit
```

Note: If no description change needed, skip this task.
