# Prompt for VS Code Agent — Create First Spec: engine-state-hardening

Copy everything below and give it to your agent in VS Code working on the smart-ralph repository.

---

## Goal

Create the first improvement spec for smart-ralph itself: **`engine-state-hardening`**.

This spec will harden smart-ralph's execution engine to make autonomous execution reliable. It targets the three most critical gaps identified through extensive research and codebase audit.

## Context

Read these files BEFORE creating the spec:
1. `/mnt/bunker_data/ai/smart-ralph/docs/brainstormmejora/gap-analysis-and-roadmap.md` — Full gap analysis with evidence
2. `plugins/ralph-specum/templates/requirements.md` — Requirements template
3. `plugins/ralph-specum/templates/design.md` — Design template
4. `plugins/ralph-specum/templates/tasks.md` — Tasks template
5. `plugins/ralph-specum/references/coordinator-pattern.md` — Current coordinator logic
6. `plugins/ralph-specum/references/verification-layers.md` — Current verification logic
7. `plugins/ralph-specum/commands/implement.md` — Current implementation start

## What You Know From the Codebase Audit

### The Good (Already Well-Designed)
- `.ralph-state.json` exists with a schema (`schemas/spec.schema.json`)
- Chat protocol with HOLD/DEADLOCK signals exists in `coordinator-pattern.md`
- 5-layer verification exists in `coordinator-pattern.md` (Layer 0-4)
- Anti-fabrication rule exists: "NEVER trust pasted output, ALWAYS run verify command"
- Pre-delegation task_review.md check exists in `coordinator-pattern.md`
- External reviewer onboarding exists in `implement.md`

### The Problems (Verified Against Real Code)
1. **Contradiction**: `coordinator-pattern.md` defines 5 verification layers, but `verification-layers.md` defines only 3 (missing anti-fabrication). `implement.md` says "run all 3".
2. **HOLD check is text-based**: The coordinator reads chat.md and decides in natural language whether HOLD exists. No mechanical `grep` check forces a binary decision.
3. **State drift undetected**: No pre-loop validation that tasks.md checkmarks match .ralph-state.json taskIndex.
4. **Prompt overload**: Coordinator reads 5 references (~15,000+ tokens) every iteration, most irrelevant to current task.
5. **No role boundaries**: External reviewer can edit .ralph-state.json because no file-access constraints exist.

### Scope of THIS Spec
This spec targets problems 1-3 only:
- Unify verification layers (fix the contradiction)
- Make HOLD check mechanical (grep-based, not text interpretation)
- Add state integrity validation at loop start

Problems 4-5 are addressed in subsequent specs (prompt-diet-refactor and role-boundaries).

## Deliverables

Create a spec at `specs/engine-state-hardening/` with these files:

### 1. `research.md`
Use the research-analyst agent. Research should cover:
- Current state file schema and usage patterns
- How verification layers are currently referenced across files
- How chat protocol signals are currently processed
- Best practices for mechanical vs text-based rule enforcement in LLM agents

### 2. `requirements.md`
Use the product-manager agent. Must include:
- **Project type**: `library` (this is a Claude Code plugin)
- **Entry points**:
  - Tests: None needed (this is plugin code, not application code)
  - Verification: Manual testing by running `/ralph-specum:implement` on a test spec
- **User stories** for: coordinator reliability, state consistency, verification integrity
- **Verification Contract** with specific acceptance criteria

### 3. `design.md`
Use the architect-reviewer agent. Must include:
- Architecture changes (which files get modified, which new files created)
- How the mechanical HOLD check integrates with existing chat protocol
- How verification layer unification works (which file becomes canonical)
- State integrity validation flow

### 4. `tasks.md`
Use the task-planner agent. Tasks must:
- Follow POC-first workflow (Phase 1: Make It Work)
- Have concrete **Verify** commands for each task (e.g., grep checks, file existence, content validation)
- Be numbered and have Do/Files/Done when/Verify/Commit fields
- Include quality checkpoints every 2-3 tasks

## Specific Requirements for This Spec

### R1: Verification Layer Unification
- Create ONE canonical file that defines all 5 verification layers
- Update `coordinator-pattern.md`, `verification-layers.md`, and `implement.md` to reference this single source
- The 5 layers must be:
  - Layer 0: EXECUTOR_START signal
  - Layer 1: Contradiction detection
  - Layer 2: TASK_COMPLETE signal
  - Layer 3: Anti-fabrication (independent verify command execution)
  - Layer 4: Periodic artifact review

### R2: Mechanical HOLD Check
- Replace the text-based "read chat.md for signals" with a Bash grep command
- The coordinator MUST execute this command and check exit code BEFORE delegating
- If grep finds HOLD/PENDING/URGENT → block delegation, log to .progress.md, stop iteration
- The existing chat protocol (Step 5 announce, Step 6 completion notice) remains unchanged

### R3: State Integrity Validation
- Add a pre-loop validation step in `implement.md` that:
  - Counts [x] tasks in tasks.md
  - Compares with taskIndex in .ralph-state.json
  - If taskIndex is ahead of the last [x] task → block with error
  - If taskIndex is behind the first incomplete task → advance to correct position
  - Log validation result to .progress.md

### R4: No Breaking Changes
- All existing specs must continue to work
- Existing .ralph-state.json files from prior versions must be handled gracefully
- The stop-watcher hook must continue functioning

## Task Format Example

For reference, tasks should look like this:

```markdown
- [ ] 1.1 Unify verification layers
  - **Do**:
    1. Create `references/verification-layers-unified.md` with all 5 layers
    2. Update `coordinator-pattern.md` to reference the unified file
    3. Update `verification-layers.md` to be a symlink or redirect
    4. Update `implement.md` quick reference to say "5 layers"
  - **Files**: references/coordinator-pattern.md, references/verification-layers.md, commands/implement.md, NEW references/verification-layers-unified.md
  - **Done when**: All 3 references point to the same 5-layer definition
  - **Verify**: `grep -c "verification layer" plugins/ralph-specum/references/verification-layers.md plugins/ralph-specum/references/coordinator-pattern.md` — all should reference 5 layers
  - **Commit**: `fix(engine): unify verification layers to single canonical source`
```

## Constraints

- **DO NOT** modify agent system prompts (agents/*.md) in this spec — that's for the prompt-diet-refactor spec
- **DO NOT** restructure the coordinator into modules — that's for the prompt-diet-refactor spec
- **DO** make minimal, targeted changes to fix the 3 specific gaps
- **DO** ensure all changes are testable via Verify commands

## After Creating the Spec

1. Show me the tasks.md for review before starting implementation
2. Do NOT start implementation until I approve the tasks
