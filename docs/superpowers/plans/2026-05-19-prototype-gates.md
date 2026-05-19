# Prototype Gates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task by task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add optional prototype gates to Ralph Specum phase handoffs for Claude Code and Codex.

**Architecture:** Keep the disk contract unchanged. Update phase command prompts and Codex skill guidance so normal mode uses `grill-with-docs`, shows walkthroughs, then asks a native choice: continue, run review, run prototype where useful, or request changes.

**Tech Stack:** Markdown command prompts, Claude Code plugin metadata, Codex skill docs, Bats validation.

---

## File Structure

- Modify `plugins/ralph-specum/commands/start.md`: use `grill-with-docs` during setup and align research handoff.
- Modify `plugins/ralph-specum/commands/research.md`: use `grill-with-docs`, add prototype choice after walkthrough.
- Modify `plugins/ralph-specum/commands/requirements.md`: use `grill-with-docs`, add prototype choice after PRD walkthrough.
- Modify `plugins/ralph-specum/commands/design.md`: use `grill-with-docs`, add prototype choice after design walkthrough.
- Modify `plugins/ralph-specum/commands/tasks.md`: use `grill-with-docs`, keep review and continue gate.
- Modify `plugins/ralph-specum/skills/spec-workflow/SKILL.md`: document phase gate behavior.
- Create `plugins/ralph-specum/skills/grill-with-docs/SKILL.md`: bundled Claude plugin grill fallback.
- Create `plugins/ralph-specum/skills/prototype/SKILL.md`: bundled Claude plugin prototype fallback.
- Modify `plugins/ralph-specum/.claude-plugin/plugin.json`: bump minor version.
- Modify `.claude-plugin/marketplace.json`: match plugin version.
- Modify `platforms/codex/skills/ralph-specum/references/workflow.md`: shared Codex phase flow.
- Modify `platforms/codex/skills/ralph-specum/SKILL.md`: primary Codex contract.
- Modify helper skills under `platforms/codex/skills/ralph-specum-*`: phase specific handoffs.
- Modify Codex wording so `$grill-with-docs` and `$prototype` are optional, with inline behavior when missing.
- Modify `platforms/codex/skills/ralph-specum/assets/bootstrap/AGENTS.md`: consumer repo guidance.
- Modify `README.md` and `platforms/codex/README.md`: public flow docs.
- Modify `tests/codex-platform.bats`: assert Codex docs expose prototype gate text.

### Task 1: Claude Phase Prompts

**Files:**
- Modify: `plugins/ralph-specum/commands/start.md`
- Modify: `plugins/ralph-specum/commands/research.md`
- Modify: `plugins/ralph-specum/commands/requirements.md`
- Modify: `plugins/ralph-specum/commands/design.md`
- Modify: `plugins/ralph-specum/commands/tasks.md`
- Modify: `plugins/ralph-specum/skills/spec-workflow/SKILL.md`

- [ ] **Step 1: Patch interview instructions**

Replace normal mode `interview-framework` references with `grill-with-docs` first, with fallback to existing interview framework if skill unavailable.

- [ ] **Step 2: Patch approval gates**

Research, requirements, and design AskUserQuestion options become:

```text
1. Continue to <next phase> (Recommended)
2. Run review agent
3. Run prototype
4. Request changes
```

Tasks AskUserQuestion options become:

```text
1. Continue to implementation (Recommended)
2. Run review agent
3. Request changes
```

- [ ] **Step 3: Add prototype branch**

Prototype branch invokes `Skill({ skill: "prototype" })`, runs throwaway prototype against current artifact and upstream context, captures result in `.progress.md`, then redisplays walkthrough and asks again.

### Task 2: Codex Skill Contract

**Files:**
- Modify: `platforms/codex/skills/ralph-specum/references/workflow.md`
- Modify: `platforms/codex/skills/ralph-specum/SKILL.md`
- Modify: `platforms/codex/skills/ralph-specum-start/SKILL.md`
- Modify: `platforms/codex/skills/ralph-specum-research/SKILL.md`
- Modify: `platforms/codex/skills/ralph-specum-requirements/SKILL.md`
- Modify: `platforms/codex/skills/ralph-specum-design/SKILL.md`
- Modify: `platforms/codex/skills/ralph-specum-tasks/SKILL.md`
- Modify: `platforms/codex/skills/ralph-specum/assets/bootstrap/AGENTS.md`
- Modify: `platforms/codex/README.md`
- Modify: `README.md`

- [ ] **Step 1: Patch workflow reference**

Normal flow documents `grill-with-docs` before phase generation and prototype gates after research, requirements, and design.

- [ ] **Step 2: Patch helper handoffs**

Each helper skill names the exact choice prompt. Prototype appears only on research, requirements, and design.

- [ ] **Step 3: Patch docs**

Root README and Codex README mention optional prototype gates after artifact walkthroughs.

### Task 3: Version And Tests

**Files:**
- Modify: `plugins/ralph-specum/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Modify: `tests/codex-platform.bats`

- [ ] **Step 1: Bump version**

Set Ralph Specum plugin version to `4.9.0` in both manifest files.

- [ ] **Step 2: Add Codex assertions**

Add Bats checks that primary and helper skill docs include `grill-with-docs` and prototype gate wording.

- [ ] **Step 3: Verify**

Run:

```bash
bats tests/codex-platform.bats
```

Expected: all tests pass.
