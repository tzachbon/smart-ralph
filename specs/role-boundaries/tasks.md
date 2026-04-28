---
spec: role-boundaries
phase: tasks
total_tasks: 44
created: 2026-04-25
updated: 2026-04-26
---

# Tasks: Role Boundaries

## Execution Context

From design.md:
- Plugin spec: markdown + shell scripts, no build system
- Verification: manual (file inspection, grep, cat, jq, bash -n)
- No test runner — use `bash -n` for syntax, `jq empty` for JSON, `grep` for content

## Implementation Phase 1: Prompt-Based Enforcement + Baseline (POC)

Focus: Create role-contracts.md, baseline capture, and stop-watcher extension — proves the hook architecture works end-to-end.

### 1.1 Create references/role-contracts.md

- [x] 1.1 Create references/role-contracts.md with full access matrix
  - **Do**:
    1. Create `plugins/ralph-specum/references/role-contracts.md`
    2. Add YAML frontmatter: `name: role-contracts`, `description`, `"> Used by:"` line listing all 10 agents
    3. Add `## Access Matrix` table with 12 rows (10 agents + coordinator + stop-watcher.sh): columns `agent | reads | writes | denylist`
    4. Add `## State Field Ownership` table with 27 fields: columns `field | owner(s) | type`
    5. Add `## Non-Execution Agent Boundaries` section documenting 6 non-execution agents (architect-reviewer, product-manager, research-analyst, task-planner, refactor-specialist, triage-analyst) with their read/write permissions
    6. Add `## Adding a New Agent` section with exactly 4 numbered steps:
       - Step 1: Add access matrix row — include template code block showing `| <agent> | <reads> | <writes> | <denylist> |`
       - Step 2: Append DO NOT list section to agent file — include template DO NOT section code block
       - Step 3: Update channel-map.md if agent uses inter-agent channels — include template channel-map entry
       - Step 4: Update baseline for new state fields — include baseline JSON snippet template
    7. Add `## Relationship to Channel Map` section explaining complementary scope
    8. Add `## Cross-Spec Dependencies` section listing: spec-executor.md (Specs 3/6/7), external-reviewer.md (Specs 3/6), .ralph-state.json (all specs)
    9. Ensure all 10 agents appear: spec-executor, external-reviewer, qa-engineer, spec-reviewer, architect-reviewer, product-manager, research-analyst, task-planner, refactor-specialist, triage-analyst
  - **Files**: `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/references/role-contracts.md`
  - **Done when**: File exists with YAML frontmatter, access matrix with 12 rows, state field ownership table, non-execution agent section, "Adding a New Agent" with 4 numbered steps and template code blocks, "Relationship to Channel Map" section, and "Cross-Spec Dependencies" section
  - **Verify**:
    1. `grep -q "^name: role-contracts" plugins/ralph-specum/references/role-contracts.md` (frontmatter present)
    2. `for agent in spec-executor external-reviewer qa-engineer spec-reviewer architect-reviewer product-manager research-analyst task-planner refactor-specialist triage-analyst; do grep -q "| ${agent} |" plugins/ralph-specum/references/role-contracts.md || echo "MISSING: $agent"; done` (all 10 agents present)
    3. `grep -q "^## Relationship to Channel Map" plugins/ralph-specum/references/role-contracts.md`
    4. `grep -q "^## Cross-Spec Dependencies" plugins/ralph-specum/references/role-contracts.md`
    5. Extract "Adding a New Agent" section and count numbered steps: `awk '/Adding a New Agent/,/^## /' plugins/ralph-specum/references/role-contracts.md | grep -cE "^[0-9]+\\."` (expect 4)
  - **Commit**: `feat(role-boundaries): create references/role-contracts.md with full access matrix for 10 agents`
  - _Requirements: FR-1, FR-5, AC-1.1 through AC-1.7, AC-4.1 through AC-4.3, AC-5.1 through AC-5.5_
  - _Design: Component A_

### 1.2 Add baseline capture to load-spec-context.sh

- [x] 1.2 Add baseline capture logic to load-spec-context.sh
  - **Do**:
    1. Open `plugins/ralph-specum/hooks/scripts/load-spec-context.sh` (110 lines total)
    2. Find the last `exit 0` at line 110 — this is the ONLY exit 0 at the top-level of the script (after all function definitions and the final `fi`)
    3. Insert ~15 lines of baseline capture logic BEFORE line 110:
       - Define `BASELINE_DIR="${SPEC_PATH}/references"` and `BASELINE_FILE="${BASELINE_DIR}/.ralph-field-baseline.json"`
       - Guard: only create if baseline does not already exist AND state file exists: `if [ ! -f "$BASELINE_FILE" ] && [ -f "$STATE_FILE" ]; then`
       - Create references directory: `mkdir -p "$BASELINE_DIR"` with error handling
       - Write baseline using `cat << 'EOF' > "$BASELINE_FILE"` (NOT jq extraction — hand-maintained ownership map):
         ```json
         {
           "chat.executor.lastReadLine": "spec-executor",
           "chat.reviewer.lastReadLine": "external-reviewer",
           "external_unmarks": "external-reviewer",
           "awaitingApproval": ["coordinator", "architect-reviewer", "product-manager", "research-analyst", "task-planner"]
         }
         ```
       - Log success: `echo "[ralph-specum] Baseline captured: $BASELINE_FILE" >&2`
    4. Preserve existing `exit 0` after the block
  - **Files**: `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/load-spec-context.sh`
  - **Done when**: Baseline capture block inserted before `exit 0`, uses `cat << 'EOF'` with correct ownership map, guarded by `[ ! -f "$BASELINE_FILE" ]`
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/load-spec-context.sh` (syntax check passes) && `grep -q "ralph-field-baseline.json" plugins/ralph-specum/hooks/scripts/load-spec-context.sh` && `grep -q "chat.executor.lastReadLine" plugins/ralph-specum/hooks/scripts/load-spec-context.sh` && `grep -q "external_unmarks" plugins/ralph-specum/hooks/scripts/load-spec-context.sh` && `grep -q "awaitingApproval" plugins/ralph-specum/hooks/scripts/load-spec-context.sh`
  - **Commit**: `feat(role-boundaries): add baseline capture to load-spec-context.sh`
  - _Requirements: FR-3, AC-3.1 through AC-3.3_
  - _Design: Component E_

### 1.3 Add field-level validation to stop-watcher.sh

- [x] 1.3 Add field-level validation section to stop-watcher.sh
  - **Do**:
    1. Open `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    2. Find insertion point: AFTER line 526 (the `fi` closing the main if block) and BEFORE line 528 ("Loop control" comment). This places the section between `fi` at line 526 and `# Loop control:` at line 528. The section must include:
    3. Add ~200 lines for field-level validation. The section must include:
       - Heading: `# --- Role Boundaries: Field-Level Validation ---`
       - Baseline path resolution: `BASELINE_FILE="$CWD/$SPEC_PATH/references/.ralph-field-baseline.json"`
       - Missing baseline handling: if baseline doesn't exist, log warning to stderr and continue (graceful degradation): `echo "[ralph-specum] BASELINE_MISSING no baseline at $BASELINE_FILE; skipping field validation" >&2`
       - Invalid JSON handling: `jq empty "$BASELINE_FILE"` check → log BASELINE_CORRUPT if invalid
       - Retry loop for state file reads (3x with 1s delay) to mitigate jq+mv race:
         ```bash
         RETRY_COUNT=0
         STATE_CONTENT=""
         while [ $RETRY_COUNT -lt 3 ]; do
             if STATE_CONTENT=$(cat "$STATE_FILE" 2>/dev/null) && echo "$STATE_CONTENT" | jq empty 2>/dev/null; then
                 break
             fi
             RETRY_COUNT=$((RETRY_COUNT + 1))
             if [ $RETRY_COUNT -lt 3 ]; then sleep 1; fi
         done
         ```
       - Flock on fd 202 for baseline validation lock (different from 200 and 201)
       - Iteration over baseline fields: for each field in baseline:
         - Extract current state value via `jq` path-style addressing
         - Field absent from state → skip with BASELINE_SKIP: `echo "[ralph-specum] BASELINE_SKIP unknown field: <field>" >&2`
         - Field in baseline but not in state → skip: `echo "[ralph-specum] BASELINE_SKIP missing in state: <field>" >&2`
         - Type mismatch (baseline=string owner, state=object/boolean) → skip: `echo "[ralph-specum] BASELINE_SKIP type-mismatch: <field>" >&2`
         - Owner includes "coordinator" → skip (coordinator legitimately writes these fields)
         - Agent-owned-only field changed → BOUNDARY_VIOLATION: `echo "[ralph-specum] BOUNDARY_VIOLATION field=<field> owner=<owner(s)> severity=HIGH" >&2`
       - End heading: `# --- End Role Boundaries Validation ---`
    4. Ensure validation does NOT halt execution — log-and-continue pattern
    5. Agent identity reported as "unknown" (Phase 1 limitation)
  - **Files**: `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: Field-level validation section added to stop-watcher.sh after the fi block (line 526) and before "Loop control" (line 528), includes retry loop, fd 202, graceful degradation, violation logging to stderr, log-and-continue (no halt)
  - **Verify**:
    1. `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh` (syntax check passes)
    2. `grep -q "BOUNDARY_VIOLATION" plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    3. `grep -q "202" plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    4. `grep -q "BASELINE_MISSING" plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    5. `grep -q "BASELINE_SKIP" plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    6. `! grep -q "exit 1" plugins/ralph-specum/hooks/scripts/stop-watcher.sh` (no `exit 1` anywhere — log-and-continue, no halt)
  - **Commit**: `feat(role-boundaries): add field-level validation section to stop-watcher.sh`
  - _Requirements: FR-3, FR-6, AC-3.4 through AC-3.9, AC-6.1 through AC-6.4_
  - _Design: Component D_

### 1.4 [VERIFY] Quality checkpoint: POC validation

- [x] 1.4 [VERIFY] Quality checkpoint: validate Phase 1 artifacts
  - **Do**:
    1. Verify role-contracts.md structure: `test -f plugins/ralph-specum/references/role-contracts.md`
    2. Verify baseline capture in load-spec-context.sh: `bash -n plugins/ralph-specum/hooks/scripts/load-spec-context.sh`
    3. Verify stop-watcher.sh syntax: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    4. Verify all 10 agents in role-contracts.md: loop through agent names and check `| <agent> |` pattern
    5. Verify fd 202 used in stop-watcher.sh: `grep -c "202" plugins/ralph-specum/hooks/scripts/stop-watcher.sh` returns >0
    6. Verify log-and-continue (no exit on violation): check no `exit 1` after BOUNDARY_VIOLATION logging
  - **Verify**: All commands above must pass (exit 0)
  - **Done when**: All 6 verification checks pass
  - **Commit**: `chore(role-boundaries): pass quality checkpoint for Phase 1 artifacts` (only if fixes needed from earlier tasks)
  - _Requirements: FR-1, FR-3, NFR-1_
  - _Design: Test Coverage Table — role-contracts.md structure, baseline capture hook, stop-watcher syntax, fd 202, schema drift_

## Implementation Phase 2: Refactoring (DO NOT Lists)

Focus: Append explicit DO NOT denylist sections to 4 execution agent files.

### 2.1 Append DO NOT list to spec-executor.md

- [x] 2.1 Append DO NOT section to spec-executor.md
  - **Do**:
    1. Open `plugins/ralph-specum/agents/spec-executor.md`
    2. Find insertion point: before `<bookend>` section, after `</modifications>` or last `<section>` tag
    3. Insert DO NOT section (~30 lines) with agent-specific denylist:
       ```markdown
       ## DO NOT Edit — Role Boundaries

       The following files and fields are outside this agent's scope. Modifying them
       constitutes a role boundary violation. Full matrix: `references/role-contracts.md`.

       ### Write Restrictions

       - `.ralph-state.json` — except: `chat.executor.lastReadLine` (see role-contracts.md)
       - `.epic-state.json` — coordinator only
       - `task_review.md` — external-reviewer only
       - Implementation files outside task scope (Karpathy surgical changes)
       - Lock files (`.tasks.lock`, `.git-commit.lock`, `chat.md.lock`) — auto-generated

       ### Lock Files (Auto-Generated)

       - `.tasks.lock`, `.git-commit.lock`, `chat.md.lock` — these are created by the
         flock mechanism. No agent should manually create, modify, or delete them.

       ### Read Boundaries (Advisory — Severity)

       - **HIGH**: Cross-spec `.ralph-state.json` or `.progress.md` — may read another
         spec's uncommitted execution state, leading to taskIndex desync.
       - **MEDIUM**: `task_review.md` from other agents' reviews — may act on unverified feedback.
       - **LOW**: Reference files in `references/` — acceptable and encouraged.

       See `references/role-contracts.md` for the full access matrix.
       ```
    4. Ensure section is placed BEFORE `<bookend>` and references role-contracts.md
  - **Files**: `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: DO NOT section exists before `<bookend>`, lists correct denylisted files for spec-executor, ends with cross-reference to role-contracts.md
  - **Verify**: `grep -q "DO NOT Edit — Role Boundaries" plugins/ralph-specum/agents/spec-executor.md` && `grep -q "references/role-contracts.md" plugins/ralph-specum/agents/spec-executor.md` && `grep -B5 "<bookend>" plugins/ralph-specum/agents/spec-executor.md | grep -q "Role Boundaries"` && `grep -q "chat.executor.lastReadLine" plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `feat(role-boundaries): append DO NOT list to spec-executor.md`
  - _Requirements: FR-2, AC-2.1, AC-2.5, AC-2.6_
  - _Design: Component B (spec-executor placement)_

### 2.2 Append DO NOT list to external-reviewer.md

- [x] 2.2 Append DO NOT section to external-reviewer.md
  - **Do**:
    1. Open `plugins/ralph-specum/agents/external-reviewer.md`
    2. Find insertion point: before `## Section 8 — Never Do`, after `## Section 7`
    3. Insert DO NOT section (~30 lines) with agent-specific denylist:
       ```markdown
       ## DO NOT Edit — Role Boundaries

       The following files and fields are outside this agent's scope. Modifying them
       constitutes a role boundary violation. Full matrix: `references/role-contracts.md`.

       ### Write Restrictions

       - `.ralph-state.json` — except: `chat.reviewer.lastReadLine` and `external_unmarks` (see role-contracts.md)
       - `tasks.md` — only via explicit unmark protocol with flock
       - Implementation files (source code, configs) — never
       - Lock files (`.tasks.lock`, `.git-commit.lock`, `chat.md.lock`) — auto-generated

       ### Lock Files (Auto-Generated)

       - `.tasks.lock`, `.git-commit.lock`, `chat.md.lock` — these are created by the
         flock mechanism. No agent should manually create, modify, or delete them.

       ### Read Boundaries (Advisory — Severity)

       - **HIGH**: Cross-spec `.ralph-state.json` or `.progress.md` — may read another
         spec's uncommitted execution state, leading to taskIndex desync.
       - **MEDIUM**: `task_review.md` from other agents' reviews — may act on unverified feedback.
       - **LOW**: Reference files in `references/` — acceptable and encouraged.

       See `references/role-contracts.md` for the full access matrix.
       ```
    4. Ensure section is placed BEFORE `## Section 8 — Never Do`
  - **Files**: `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/agents/external-reviewer.md`
  - **Done when**: DO NOT section exists before `## Section 8 — Never Do`, lists correct denylisted files for external-reviewer, ends with cross-reference to role-contracts.md
  - **Verify**: `grep -q "DO NOT Edit — Role Boundaries" plugins/ralph-specum/agents/external-reviewer.md` && `grep -q "references/role-contracts.md" plugins/ralph-specum/agents/external-reviewer.md` && `grep -q "## Section 8 — Never Do" plugins/ralph-specum/agents/external-reviewer.md` && `grep -q "chat.reviewer.lastReadLine" plugins/ralph-specum/agents/external-reviewer.md`
  - **Commit**: `feat(role-boundaries): append DO NOT list to external-reviewer.md`
  - _Requirements: FR-2, AC-2.2, AC-2.5, AC-2.6_
  - _Design: Component B (external-reviewer placement)_

### 2.3 Append DO NOT list to qa-engineer.md

- [x] 2.3 Append DO NOT list to qa-engineer.md
  - **Do**:
    1. Open `plugins/ralph-specum/agents/qa-engineer.md`
    2. Find insertion point: right before `## Execution Flow` at line 79 (insert after line 78). The DO NOT section goes between the last paragraph of Section 0 (line 77: "Why this matters...") and `## Execution Flow` (line 79).
    3. Insert DO NOT section (~30 lines) with agent-specific denylist:
       ```markdown
       ## DO NOT Edit — Role Boundaries

       The following files and fields are outside this agent's scope. Modifying them
       constitutes a role boundary violation. Full matrix: `references/role-contracts.md`.

       ### Write Restrictions

       - `.ralph-state.json` — read-only (access taskIndex for context only)
       - `tasks.md` — read-only (do NOT modify task structure, only read for verification)
       - `task_review.md` — read-only (do NOT write review entries; external-reviewer owns this)
       - Implementation files (source code, configs) — read-only for verification, never modify
       - Lock files (`.tasks.lock`, `.git-commit.lock`, `chat.md.lock`) — auto-generated

       ### Lock Files (Auto-Generated)

       - `.tasks.lock`, `.git-commit.lock`, `chat.md.lock` — these are created by the
         flock mechanism. No agent should manually create, modify, or delete them.

       ### Read Boundaries (Advisory — Severity)

       - **HIGH**: Cross-spec `.ralph-state.json` or `.progress.md` — may read another
         spec's uncommitted execution state, leading to taskIndex desync.
       - **MEDIUM**: `task_review.md` from other agents' reviews — may act on unverified feedback.
       - **LOW**: Reference files in `references/` — acceptable and encouraged.

       See `references/role-contracts.md` for the full access matrix.
       ```
    4. Ensure section is placed AFTER `## Section 0 — Review Integration` and BEFORE `## Execution Flow`
  - **Files**: `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/agents/qa-engineer.md`
  - **Done when**: DO NOT section exists after Section 0 and before Execution Flow, lists correct denylisted files for qa-engineer, ends with cross-reference to role-contracts.md
  - **Verify**: `grep -q "DO NOT Edit — Role Boundaries" plugins/ralph-specum/agents/qa-engineer.md` && `grep -q "references/role-contracts.md" plugins/ralph-specum/agents/qa-engineer.md` && `grep -q "## Execution Flow" plugins/ralph-specum/agents/qa-engineer.md` && `grep -B10 "## Execution Flow" plugins/ralph-specum/agents/qa-engineer.md | grep -q "Role Boundaries"`
  - **Commit**: `feat(role-boundaries): append DO NOT list to qa-engineer.md`
  - _Requirements: FR-2, AC-2.3, AC-2.5, AC-2.6_
  - _Design: Component B (qa-engineer placement)_

### 2.4 Append DO NOT list to spec-reviewer.md

- [x] 2.4 Append DO NOT list to spec-reviewer.md
  - **Do**:
    1. Open `plugins/ralph-specum/agents/spec-reviewer.md`
    2. Find insertion point: after `</mandatory>` at line 17 (the FIRST `</mandatory>` in the file, which closes the Core Philosophy section), before `## When Invoked` at line 19. Note: spec-reviewer.md has `</mandatory>` at lines 17, 197, 265, 275 — use the FIRST one only (line 17).
    3. Insert DO NOT section (~25 lines) with agent-specific denylist:
       ```markdown
       ## DO NOT Edit — Role Boundaries

       This agent is **read-only** — you NEVER modify any files. All file access is
       advisory. Full matrix: `references/role-contracts.md`.

       ### Write Restrictions

       - **ALL files** — you are a read-only reviewer. Never call Edit, Write, Bash (for file ops), or any tool that modifies files.
       - This includes: `.ralph-state.json`, `tasks.md`, `task_review.md`, `chat.md`, `.progress.md`, spec artifacts, reference files, lock files

       ### Lock Files (Auto-Generated)

       - `.tasks.lock`, `.git-commit.lock`, `chat.md.lock` — auto-generated by flock.
         No agent should manually create/modify/delete.

       ### Read Boundaries (Advisory — Severity)

       - **HIGH**: Cross-spec `.ralph-state.json` or `.progress.md` — may read another
         spec's uncommitted execution state, leading to taskIndex desync.
       - **MEDIUM**: `task_review.md` from other agents' reviews — may act on unverified feedback.
       - **LOW**: Reference files in `references/` — acceptable and encouraged.

       See `references/role-contracts.md` for the full access matrix.
       ```
    4. Ensure section is placed AFTER the first `</mandatory>` (line 17) and BEFORE `## When Invoked` (line 19). The verify command `grep -A5 "</mandatory>" spec-reviewer.md | head -1` will match line 17 (the first occurrence).
  - **Files**: `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/agents/spec-reviewer.md`
  - **Done when**: DO NOT section exists after Core Philosophy mandatory block and before When Invoked, explicitly states read-only, ends with cross-reference to role-contracts.md
  - **Verify**: `grep -q "DO NOT Edit — Role Boundaries" plugins/ralph-specum/agents/spec-reviewer.md` && `grep -q "references/role-contracts.md" plugins/ralph-specum/agents/spec-reviewer.md` && `grep -A5 "</mandatory>" plugins/ralph-specum/agents/spec-reviewer.md | head -1 | grep -q "Role Boundaries"` && `grep -q "read-only" plugins/ralph-specum/agents/spec-reviewer.md`
  - **Commit**: `feat(role-boundaries): append DO NOT list to spec-reviewer.md`
  - _Requirements: FR-2, AC-2.4, AC-2.5, AC-2.6_
  - _Design: Component B (spec-reviewer placement)_

### 2.5 [VERIFY] Quality checkpoint: DO NOT list verification

- [x] 2.5 [VERIFY] Quality checkpoint: verify DO NOT lists in agent files
  - **Do**:
    1. Verify each of the 4 agent files contains DO NOT section: `grep -q "DO NOT Edit — Role Boundaries" plugins/ralph-specum/agents/<file>` for each agent
    2. Verify each references role-contracts.md: `grep -q "references/role-contracts.md" plugins/ralph-specum/agents/<file>` for each agent
    3. Verify placement correctness:
       - spec-executor.md: section before `<bookend>`
       - external-reviewer.md: section before `## Section 8 — Never Do`
       - qa-engineer.md: section after Section 0 and before Execution Flow
       - spec-reviewer.md: section after `</mandatory>` and before `## When Invoked`
    4. Verify markdown structure preserved — no broken sections
  - **Verify**: All 4 agent files pass grep checks for DO NOT section and role-contracts.md reference
  - **Done when**: All placement and content checks pass
  - **Commit**: `chore(role-boundaries): pass quality checkpoint for DO NOT lists` (only if fixes needed from earlier tasks)
  - _Requirements: FR-2, AC-2.1 through AC-2.4, AC-2.5_
  - _Design: Test Coverage Table — all 4 DO NOT lists_

### 2.7 Add input sanitization for spec name

- [x] 2.7 Add input sanitization for spec name
  - **Do**:
    1. In `validate_inputs()`, add stricter validation: spec name must match `^[a-z](-?[a-z0-9]+)*$`
    2. Reject spec names with leading/trailing hyphens
    3. Reject names with consecutive hyphens
    4. Reject names with uppercase, special characters, or less than 2 chars
  - **Files**: plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: validate_inputs rejects spec names with leading/trailing hyphens, consecutive hyphens, uppercase, or special characters
  - **Verify**: `bash -c 'source plugins/ralph-bmad-bridge/scripts/import.sh; validate_inputs "/tmp" "UPPER" && echo FAIL; validate_inputs "/tmp" "bad--name" && echo FAIL; validate_inputs "/tmp" "good-name" && echo PASS' 2>&1 | grep -q 'PASS' && echo 2.7_PASS`
  - **Commit**: `refactor(bmad-bridge): add spec name input sanitization`
  - _Design: Security Considerations_

## Implementation Phase 3: Testing/Verification

Focus: Manual verification of all artifacts using filesystem checks.

### 3.1 Validate baseline JSON syntax and structure

- [x] 3.1 Validate baseline capture creates valid JSON
  - **Do**:
    1. Run `bash -n plugins/ralph-specum/hooks/scripts/load-spec-context.sh` to verify syntax
    2. Verify baseline capture block contains all 4 field entries: `chat.executor.lastReadLine`, `chat.reviewer.lastReadLine`, `external_unmarks`, `awaitingApproval`
    3. Verify baseline file would use `cat << 'EOF'` (not jq extraction)
    4. Verify guard condition: `[ ! -f "$BASELINE_FILE" ]` prevents overwriting existing baseline
    5. Simulate baseline creation by running the heredoc section and piping to `jq empty`
  - **Verify**: `bash -n` passes, `jq empty` validates the JSON structure, all 4 fields present
  - **Done when**: Baseline JSON is valid, all 4 field ownership entries present, guard condition correct
  - **Commit**: `chore(role-boundaries): validate baseline JSON structure` (only if fixes needed)
  - _Requirements: FR-3, AC-3.1, AC-3.3_
  - _Design: Component C_

### 3.2 Validate stop-watcher.sh shell syntax

- [x] 3.2 Validate stop-watcher.sh shell script syntax
  - **Do**:
    1. Run `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh` to verify syntax
    2. Verify all heredocs in the new section are properly terminated
    3. Verify fd 202 is used consistently (flock + exec)
    4. Verify retry loop logic: `RETRY_COUNT` initialization, increment, condition check
    5. Verify jq path-style addressing works for nested fields (e.g., `chat.executor.lastReadLine`)
    6. Verify no `exit 1` or `exit` after BOUNDARY_VIOLATION logging (log-and-continue)
    7. Verify graceful degradation: missing baseline → warning + continue, not crash
  - **Verify**: `bash -n` passes, no syntax errors in new section
  - **Done when**: Shell syntax check passes
  - **Commit**: `chore(role-boundaries): validate stop-watcher.sh syntax` (only if fixes needed)
  - _Requirements: FR-3, FR-6, NFR-1_
  - _Design: Component D_

### 3.3 Validate role-contracts.md completeness

- [x] 3.3 Validate role-contracts.md completeness
  - **Do**:
    1. Verify YAML frontmatter: `head -20` shows `name:`, `description:`, `"> Used by:"`
    2. Verify all 10 agents in access matrix: loop through agent names and check `| <agent> |`
    3. Verify coordinator and stop-watcher.sh also documented in matrix
    4. Verify state field ownership table has entries for: `chat.executor.lastReadLine`, `chat.reviewer.lastReadLine`, `external_unmarks`, `awaitingApproval` (and the 27 total fields)
    5. Verify "Adding a New Agent" section has exactly 4 numbered steps with template code blocks
    6. Verify "Relationship to Channel Map" section exists
    7. Verify "Cross-Spec Dependencies" section exists with specs 3/6/7 references
    8. Verify Non-Execution Agent Boundaries section has all 6 agents
  - **Verify**: `test -f plugins/ralph-specum/references/role-contracts.md` && all grep checks pass
  - **Done when**: All completeness checks pass
  - **Commit**: `chore(role-boundaries): validate role-contracts.md completeness` (only if fixes needed)
  - _Requirements: FR-1, AC-1.1 through AC-1.7, AC-4.1 through AC-4.3, AC-5.1 through AC-5.5_
  - _Design: Component A_

### 3.4 Verify violation logging format

- [x] 3.4 Verify violation logging format matches spec
  - **Do**:
    1. Verify BOUNDARY_VIOLATION log format in stop-watcher.sh: `[ralph-specum] BOUNDARY_VIOLATION field=<field> owner=<owner(s)> severity=<SEVERITY>`
    2. Verify BASELINE_SKIP messages for each scenario:
       - Unknown field: `[ralph-specum] BASELINE_SKIP unknown field: <field>`
       - Missing in state: `[ralph-specum] BASELINE_SKIP missing in state: <field>`
       - Type mismatch: `[ralph-specum] BASELINE_SKIP type-mismatch: <field>`
    3. Verify BASELINE_MISSING message: `[ralph-specum] BASELINE_MISSING no baseline at <path>; skipping field validation`
    4. Verify all logs go to stderr (`>&2`), not to filesystem
    5. Verify agent identity reported as "unknown" (Phase 1 limitation)
    6. Verify all 6 error handling scenarios have corresponding log strings:
       - BOUNDARY_VIOLATION, BASELINE_SKIP, BASELINE_MISSING, BASELINE_CORRUPT, BASELINE_RETRY_EXHAUSTED, agent identity "unknown"
  - **Verify**:
    1. `grep -q "BOUNDARY_VIOLATION" plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    2. `grep -q "BASELINE_SKIP" plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    3. `grep -q "BASELINE_MISSING" plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    4. `grep -q "BASELINE_CORRUPT" plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    5. `grep -q "BASELINE_RETRY_EXHAUSTED" plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    6. `grep ">&2" plugins/ralph-specum/hooks/scripts/stop-watcher.sh | grep -c "BOUNDARY_VIOLATION\|BASELINE"` (all logs go to stderr)
  - **Done when**: All log format checks pass
  - **Commit**: `chore(role-boundaries): validate violation log format` (only if fixes needed)
  - _Requirements: FR-6, AC-6.1 through AC-6.4_
  - _Design: Component D (violation log format)_

## Phase 4: Quality Gates

Focus: Cross-reference updates and final integration checks.

### 4.1 Update channel-map.md stale data and cross-reference

- [x] 4.1 Update channel-map.md: correct ownership data and add cross-reference
  - **Do**:
    1. Open `plugins/ralph-specum/references/channel-map.md`
    2. Update `.ralph-state.json` row in Channel Registry (find the row containing `.ralph-state.json` in the Channel Registry table) to reflect FULL ownership:
       - Current: `coordinator (taskIndex, state transitions), reviewer (chat.reviewer.lastReadLine, external_unmarks)`
       - New: `coordinator (all fields), spec-executor (chat.executor.lastReadLine), external-reviewer (chat.reviewer.lastReadLine, external_unmarks), planning-agents [architect-reviewer, product-manager, research-analyst, task-planner] (awaitingApproval)`
    3. Update `.ralph-state.json` row in Race Condition Risk Register (find the row containing `.ralph-state.json`) to reflect full ownership partitioning including `awaitingApproval` writes by 4 planning agents
    4. Add cross-reference to `references/role-contracts.md` in "Adding a New Agent" section:
       - After step 5 ("Update the relevant agent files to reference the new contract"), add:
         > **Full boundary checklist**: See `references/role-contracts.md` for the complete access matrix, "Adding a New Agent" checklist (4 steps with template code blocks), and cross-spec dependency tracking. `references/role-contracts.md` is the single source of truth for agent read/write permissions.
    5. Ensure role-contracts.md is referenced as "single source of truth" in the update
  - **Files**: `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/references/channel-map.md`
  - **Done when**: `.ralph-state.json` ownership row updated with full ownership (including awaitingApproval), cross-reference to role-contracts.md added in "Adding a New Agent" section, role-contracts.md referenced as single source of truth
  - **Verify**: `grep -q "awaitingApproval" plugins/ralph-specum/references/channel-map.md` && `grep -q "role-contracts.md" plugins/ralph-specum/references/channel-map.md` && `grep -q "single source of truth" plugins/ralph-specum/references/channel-map.md` && `grep -q "Full boundary checklist" plugins/ralph-specum/references/channel-map.md`
  - **Commit**: `feat(role-boundaries): update channel-map.md ownership data and add role-contracts.md cross-reference`
  - _Requirements: FR-7, AC-4.2, AC-4.3_
  - _Design: Component F_

### 4.2 [VERIFY] Quality checkpoint: integration verification

- [x] 4.2 [VERIFY] Quality checkpoint: integration verification
  - **Do**:
    1. Run ALL verification commands from design.md Verification Contract (line 470-496):
       - `test -f plugins/ralph-specum/references/role-contracts.md`
       - All 10 agents in matrix
       - All 4 agent files have DO NOT sections referencing role-contracts.md
       - `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
       - `bash -n plugins/ralph-specum/hooks/scripts/load-spec-context.sh`
       - `grep -c "202" plugins/ralph-specum/hooks/scripts/stop-watcher.sh` > 0
       - `grep -c "BOUNDARY_VIOLATION" plugins/ralph-specum/hooks/scripts/stop-watcher.sh` > 0
       - channel-map.md updated
    2. Check for FAIL conditions from Verification Contract:
       - Unauthorized field modification NOT halting execution (should be log-and-continue)
       - Baseline missing does NOT crash stop-watcher (graceful skip)
       - `references/role-contracts.md` has "Relationship to Channel Map" section
       - stop-watcher does NOT write to `.progress.md` during violation logging
    3. Hard invariants:
       - stop-watcher does NOT modify `.ralph-state.json` (read-only validation)
       - Field-level validation does NOT interfere with existing stop-watcher phases
       - Validation uses fd 202 (different from 200 and 201)
  - **Verify**: All verification commands pass, no FAIL conditions present, all hard invariants hold
  - **Done when**: All integration checks pass, no FAIL conditions detected
  - **Commit**: `chore(role-boundaries): pass final integration verification` (only if fixes needed)
  - _Requirements: All acceptance criteria_
  - _Design: Verification Contract (line 470-496)_

### 4.3 Record implementation learnings

- [x] 4.3 Record learnings and cross-spec dependencies
  - **Do**:
    1. Append learnings to `specs/role-boundaries/.progress.md` under `## Learnings from Implementation`:
       - Note baseline location: spec's `references/.ralph-field-baseline.json` (not alongside state file)
       - Note baseline capture is hand-maintained ownership map (NOT extracted from state values)
       - Note Phase 1 limitation: agent identity is "unknown" in violation logs
       - Note known gap: existing specs without baselines rely on Phase 1 (prompt-only) enforcement only
       - Note fd 202 used for baseline validation (separate from 200/chat, 201/tasks)
       - Note lock files are auto-generated by flock — agents should not manually interact
    2. Record cross-spec dependency tracking in role-contracts.md `## Cross-Spec Dependencies` section
    3. Verify no stray `.ralph-state.json.tmp` files in spec directory
  - **Files**: `/mnt/bunker_data/ai/smart-ralph/specs/role-boundaries/.progress.md`
  - **Done when**: Learnings section appended with all 6 key points, no stray temp files
  - **Verify**:
    1. `grep -c "Learnings from Implementation" specs/role-boundaries/.progress.md | grep -qE "^1$"` (exactly one occurrence, `$` anchor prevents matching "10", "11", etc.)
    2. `grep -q "role-contracts.md" specs/role-boundaries/.progress.md` (baseline location noted)
    3. `grep -q "agent identity" specs/role-boundaries/.progress.md` (Phase 1 limitation noted)
  - **Commit**: `docs(role-boundaries): record implementation learnings in .progress.md`
  - _Requirements: NFR-3_
  - _Design: Out of Scope → Migration path for existing specs_

## Phase 5: Forensic Audit Fixes

Focus: Fix issues identified by forensic audit (2026-04-26). Each fix is followed by a BMAD adversarial review round.

### 5.1 Fix baseline format mismatch in stop-watcher.sh (CRITICAL — Capa 2 restoration)

- [x] 5.1 Fix baseline format mismatch in stop-watcher.sh to read flat JSON
  - **Do**:
    1. Open `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` lines 570-628
    2. Change baseline reading from nested `.fields` format to flat format matching what `load-spec-context.sh` creates:
       - Replace line 576: `FIELDS=$(jq -r '.fields // {} | keys[]' "$BASELINE_FILE" 2>/dev/null)` → `FIELDS=$(jq -r 'keys[]' "$BASELINE_FILE" 2>/dev/null)`
       - Replace line 580: `BASELINE_OWNER=$(jq -r --arg f "$FIELD" '.fields[$f].owner // "unknown"' "$BASELINE_FILE")` → `BASELINE_OWNER=$(jq -r --arg f "$FIELD" '.[$f] // "unknown"' "$BASELINE_FILE")`
       - Replace line 581: `BASELINE_TYPE=$(jq -r --arg f "$FIELD" '.fields[$f].type // "string"' "$BASELINE_FILE")` → Remove this line (flat format has no type field; hardcode `BASELINE_TYPE="string"`)
       - Replace line 582: `BASELINE_DEFAULT=$(jq -r --arg f "$FIELD" '.fields[$f].default // ""' "$BASELINE_FILE")` → Remove this line (flat format has no default; hardcode `BASELINE_DEFAULT=""`)
    3. Also update the jq type check at line 602: ensure it still works with flat format (it already does since `jq '.[$f] | type'` works on top-level keys)
    4. Ensure the baseline value may be a string OR an array (e.g., `awaitingApproval` is an array). Adjust owner extraction to handle both.
    5. Run `bash -n` to verify syntax
  - **Files**: `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: stop-watcher.sh reads flat JSON format, syntax check passes, all 4 fields (chat.executor.lastReadLine, chat.reviewer.lastReadLine, external_unmarks, awaitingApproval) are iterated correctly
  - **Verify**:
    1. `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh` (syntax check passes)
    2. `! grep -q "'\\.fields" plugins/ralph-specum/hooks/scripts/stop-watcher.sh` (no more `.fields` references in baseline reading)
    3. `grep -q "keys\\[\\]" plugins/ralph-specum/hooks/scripts/stop-watcher.sh` (plain keys iteration)
    4. Simulate: `cat << 'EOF' | jq -r 'keys[]' /dev/stdin` with the flat baseline JSON — verify all 4 keys output
  - **Commit**: `fix(role-boundaries): fix baseline format in stop-watcher.sh to read flat JSON`
  - _Forensic Issue: #1 (CRITICAL — baseline format mismatch)_

### 5.2 [BMAD Adversarial Review] Validate baseline format fix

- [x] 5.2 [BMAD] Adversarial review of T5.1 baseline format fix
  - **Do**:
    1. Run `/bmad-party-mode --review-adversarial` on the changes to `stop-watcher.sh` from T5.1
    2. Use agents: bmad-agent-architect (shell/script review), bmad-agent-dev (implementation review)
    3. Ask: "Does the flat JSON fix correctly restore Capa 2 validation? Are there edge cases with array values (awaitingApproval) or type checking?"
    4. Collect findings, evaluate using decision framework, apply valid fixes
    5. Repeat until 0 findings
  - **Verify**: 0 findings from BMAD adversarial review round
  - **Done when**: BMAD party-mode with adversarial skill finds no issues with the baseline format fix
  - **Commit**: `chore(role-boundaries): BMAD review passed for baseline format fix`

### 5.3 Update .epic-state.json: mark role-boundaries completed

- [x] 5.3 Update .epic-state.json to mark role-boundaries as completed
  - **Do**:
    1. Open `specs/_epics/engine-roadmap-epic/.epic-state.json`
    2. Change `{"name":"role-boundaries","status":"pending"}` → `{"name":"role-boundaries","status":"completed"}`
    3. Verify JSON validity with `jq empty`
  - **Files**: `/mnt/bunker_data/ai/smart-ralph/specs/_epics/engine-roadmap-epic/.epic-state.json`
  - **Done when**: role-boundaries status is "completed" in epic state, JSON valid
  - **Verify**: `jq -e '.specs[] | select(.name == "role-boundaries") | .status' specs/_epics/engine-roadmap-epic/.epic-state.json | grep -q "completed"`
  - **Commit**: `fix(role-boundaries): mark role-boundaries as completed in epic state`
  - _Forensic Issue: #24 (.epic-state.json not updated)_

### 5.4 [BMAD Adversarial Review] Validate epic-state fix

- [x] 5.4 [BMAD] Adversarial review of T5.3 epic-state fix
  - **Do**:
    1. Run `/bmad-party-mode --review-adversarial` on the epic-state.json changes
    2. Use agents: bmad-agent-architect
    3. Ask: "Is updating epic state correct? Should .current-spec also be updated to loop-safety-infra?"
    4. Collect findings, apply valid fixes
    5. Repeat until 0 findings
  - **Verify**: 0 findings from BMAD adversarial review
  - **Done when**: BMAD review passes
  - **Commit**: `chore(role-boundaries): BMAD review passed for epic-state fix`

### 5.5 Update role-contracts.md: add tasks.md to external-reviewer writes

- [x] 5.5 Update role-contracts.md access matrix to add tasks.md to external-reviewer writes
  - **Do**:
    1. Open `plugins/ralph-specum/references/role-contracts.md` line 28
    2. Change the external-reviewer writes column from:
       `task_review.md, chat.md, chat.reviewer.lastReadLine, external_unmarks`
       to:
       `task_review.md, tasks.md, chat.md, chat.reviewer.lastReadLine, external_unmarks`
    3. Also update the denylist column: remove `tasks.md` from deny (external-reviewer now legitimately writes tasks.md)
    4. Update the Non-Execution Agent Boundaries section if external-reviewer is documented there (check lines 82-127)
  - **Files**: `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/references/role-contracts.md`
  - **Done when**: external-reviewer writes column includes tasks.md, denylist no longer excludes tasks.md
  - **Verify**:
    1. `grep "external-reviewer" plugins/ralph-specum/references/role-contracts.md | grep -q "tasks.md" | head -1` (writes column has tasks.md)
    2. Ensure denylist for external-reviewer no longer lists tasks.md as forbidden
  - **Commit**: `fix(role-boundaries): add tasks.md to external-reviewer write permissions in role-contracts.md`
  - _Forensic Issue: #2 (external-reviewer tasks.md write undocumented)_

### 5.6 [BMAD Adversarial Review] Validate role-contracts external-reviewer fix

- [x] 5.6 [BMAD] Adversarial review of T5.5 role-contracts external-reviewer fix
  - **Do**:
    1. Run `/bmad-party-mode --review-adversarial` on role-contracts.md changes
    2. Use agents: bmad-agent-architect, bmad-agent-dev
    3. Ask: "Are the external-reviewer permission changes consistent across all sections of role-contracts.md?"
    4. Collect findings, apply valid fixes
    5. Repeat until 0 findings
  - **Verify**: 0 findings from BMAD adversarial review
  - **Done when**: BMAD review passes
  - **Commit**: `chore(role-boundaries): BMAD review passed for external-reviewer permissions fix`

### 5.7 Add BASELINE_RETRY_EXHAUSTED message to stop-watcher.sh

- [x] 5.7 Add BASELINE_RETRY_EXHAUSTED error message to stop-watcher.sh retry path
  - **Do**:
    1. Open `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` around line 563
    2. Change the message at line 564 from:
       `echo "[ralph-specum] BASELINE_SKIP unable to read state file after retries; skipping validation" >&2`
       to:
       `echo "[ralph-specum] BASELINE_RETRY_EXHAUSTED unable to read state file after 3 retries; skipping validation" >&2`
    3. This aligns the implemented error message with the documented scenarios in tasks.md:399
  - **Files**: `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: BASELINE_RETRY_EXHAUSTED message present in stop-watcher.sh at retry exhaustion point
  - **Verify**: `grep -q "BASELINE_RETRY_EXHAUSTED" plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Commit**: `fix(role-boundaries): add BASELINE_RETRY_EXHAUSTED error message in stop-watcher.sh`
  - _Forensic Issue: #4 (BASELINE_RETRY_EXHAUSTED documented but not implemented)_

### 5.8 [BMAD Adversarial Review] Validate retry exhausted message fix

- [x] 5.8 [BMAD] Adversarial review of T5.7 retry exhausted message fix
  - **Do**:
    1. Run `/bmad-party-mode --review-adversarial` on the stop-watcher.sh line change
    2. Use agents: bmad-agent-dev
    3. Ask: "Is renaming BASELINE_SKIP to BASELINE_RETRY_EXHAUSTED the right approach? Are there downstream consumers of this message?"
    4. Collect findings, apply valid fixes
    5. Repeat until 0 findings
  - **Verify**: 0 findings from BMAD adversarial review
  - **Done when**: BMAD review passes
  - **Commit**: `chore(role-boundaries): BMAD review passed for retry exhausted message fix`

### 5.9 Fix Step 4 path and template in role-contracts.md

- [x] 5.9 Fix Step 4 path reference and JSON template in role-contracts.md
  - **Do**:
    1. Open `plugins/ralph-specum/references/role-contracts.md` lines 167-177 (Step 4)
    2. Fix path: change `plugins/ralph-specum/schemas/baseline.json` → `references/.ralph-field-baseline.json` (relative to spec path, not plugin path)
    3. Fix template JSON: the baseline is flat format `{"fieldName": "ownerName"}` not `{"newField": "initial-value"}` with description
       - Replace:
         ```json
         {
           "newField": "initial-value",
           "description": "What this field tracks"
         }
         ```
         with:
         ```json
         {
           "new.state.field": "agent-name"
         }
         ```
       - Add explanatory text: "The baseline maps field paths to owner agent names (flat format). Arrays (like awaitingApproval) list all authorized writers."
  - **Files**: `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/references/role-contracts.md`
  - **Done when**: Step 4 references correct baseline path, template shows flat field→owner format with array example
  - **Verify**:
    1. `grep "baseline.json" plugins/ralph-specum/references/role-contracts.md` returns no results (old incorrect path removed)
    2. `grep -q "ralph-field-baseline" plugins/ralph-specum/references/role-contracts.md` (correct path present)
    3. No `"description"` field in baseline JSON example
  - **Commit**: `fix(role-boundaries): fix Step 4 path and template in role-contracts.md`
  - _Forensic Issues: #7 (incorrect Step 4 path), #8 (incorrect Step 4 template)_

### 5.10 [BMAD Adversarial Review] Validate Step 4 documentation fix

- [x] 5.10 [BMAD] Adversarial review of T5.9 Step 4 documentation fix
  - **Do**:
    1. Run `/bmad-party-mode --review-adversarial` on role-contracts.md Step 4 changes
    2. Use agents: bmad-agent-architect
    3. Ask: "Is the Step 4 documentation now accurate and consistent with actual baseline format?"
    4. Collect findings, apply valid fixes
    5. Repeat until 0 findings
  - **Verify**: 0 findings from BMAD adversarial review
  - **Done when**: BMAD review passes
  - **Commit**: `chore(role-boundaries): BMAD review passed for Step 4 documentation fix`

### 5.11 Fix duplicate text in design.md

- [x] 5.11 Remove duplicate "Phase 1 agent identity limitation" paragraph from design.md
  - **Do**:
    1. Open `specs/role-boundaries/design.md` lines 198-200
    2. Remove the duplicate paragraph at line 200 (identical content to line 198)
    3. Verify remaining paragraph is the more complete version (line 198 has better explanation)
  - **Files**: `/mnt/bunker_data/ai/smart-ralph/specs/role-boundaries/design.md`
  - **Done when**: Only one instance of "Phase 1 agent identity limitation" paragraph remains
  - **Verify**: `grep -c "Phase 1 agent identity limitation" specs/role-boundaries/design.md | grep -qE "^1$"`
  - **Commit**: `fix(role-boundaries): remove duplicate agent identity limitation paragraph from design.md`
  - _Forensic Issue: #13 (duplicate text in design.md)_

### 5.12 [BMAD Adversarial Review] Validate design.md cleanup

- [x] 5.12 [BMAD] Adversarial review of T5.11 design.md cleanup
  - **Do**:
    1. Run `/bmad-party-mode --review-adversarial` on design.md changes
    2. Use agents: bmad-agent-architect
    3. Ask: "Is the remaining text still complete and accurate after removing the duplicate?"
    4. Collect findings, apply valid fixes
    5. Repeat until 0 findings
  - **Verify**: 0 findings
  - **Done when**: BMAD review passes
  - **Commit**: `chore(role-boundaries): BMAD review passed for design.md cleanup`

### 5.13 Fix empty ## Role Boundaries heading in qa-engineer.md

- [x] 5.13 Remove empty "## Role Boundaries" heading from qa-engineer.md
  - **Do**:
    1. Open `plugins/ralph-specum/agents/qa-engineer.md` around line 105
    2. Delete the empty `## Role Boundaries` heading at line 105 (it sits between DO NOT section at line 103 and `## Execution Flow` at line 107)
  - **Files**: `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/agents/qa-engineer.md`
  - **Done when**: No empty ## Role Boundaries heading in qa-engineer.md
  - **Verify**: `grep -n "Role Boundaries" plugins/ralph-specum/agents/qa-engineer.md` — should only show the DO NOT section content, not a standalone empty heading
  - **Commit**: `fix(role-boundaries): remove empty Role Boundaries heading from qa-engineer.md`
  - _Forensic Issue: #5 (empty heading)_

### 5.14 [BMAD Adversarial Review] Validate qa-engineer cleanup

- [x] 5.14 [BMAD] Adversarial review of T5.13 qa-engineer cleanup
  - **Do**:
    1. Run `/bmad-party-mode --review-adversarial` on qa-engineer.md changes
    2. Use agents: bmad-agent-dev
    3. Ask: "Does removing the empty heading preserve correct markdown structure?"
    4. Collect findings, apply valid fixes
    5. Repeat until 0 findings
  - **Verify**: 0 findings
  - **Done when**: BMAD review passes
  - **Commit**: `chore(role-boundaries): BMAD review passed for qa-engineer cleanup`

### 5.15 Clarify qa-engineer and refactor-specialist wording in role-contracts.md

- [x] 5.15 Clarify ambiguous wording for qa-engineer and refactor-specialist in role-contracts.md
  - **Do**:
    1. Open `plugins/ralph-specum/references/role-contracts.md`
    2. Fix qa-engineer row (line 29): change `_(read-only)_` → `_(read-only for state files; reads spec files for verification)_`
    3. Fix refactor-specialist row (line 35): change `_(read-only, updates spec markdown files)_` → `_(read-only for state files; creates and updates spec markdown files)_`
    4. Also update Non-Execution Agent Boundaries section for consistency:
       - refactor-specialist (line 118): ensure wording matches
       - triage-analyst (line 125): ensure wording is consistent
  - **Files**: `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/references/role-contracts.md`
  - **Done when**: qa-engineer and refactor-specialist rows have clear, unambiguous read/write descriptions
  - **Verify**:
    1. `grep "qa-engineer" plugins/ralph-specum/references/role-contracts.md | head -1 | grep -q "read-only for state"`
    2. `grep "refactor-specialist" plugins/ralph-specum/references/role-contracts.md | head -1 | grep -q "read-only for state"`
  - **Commit**: `fix(role-boundaries): clarify qa-engineer and refactor-specialist permissions in role-contracts.md`
  - _Forensic Issues: #3 (qa-engineer wording), #14 (access matrix ambiguity)_

### 5.16 [BMAD Adversarial Review] Validate wording clarification

- [x] 5.16 [BMAD] Adversarial review of T5.15 wording clarification
  - **Do**:
    1. Run `/bmad-party-mode --review-adversarial` on role-contracts.md wording changes
    2. Use agents: bmad-agent-architect, bmad-agent-dev
    3. Ask: "Are the permission descriptions now unambiguous and consistent across both Access Matrix and Non-Execution sections?"
    4. Collect findings, apply valid fixes
    5. Repeat until 0 findings
  - **Verify**: 0 findings
  - **Done when**: BMAD review passes
  - **Commit**: `chore(role-boundaries): BMAD review passed for wording clarification fix`

### 5.17 [VERIFY] Final verification of all forensic audit fixes

- [x] 5.17 [VERIFY] Verify all forensic audit fixes are complete and correct
  - **Do**:
    1. Verify baseline format fix: `jq -r 'keys[]' specs/role-boundaries/references/.ralph-field-baseline.json 2>/dev/null || echo "no baseline yet"` — all 4 keys should work with flat jq
    2. Verify stop-watcher.sh syntax: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    3. Verify BASELINE_RETRY_EXHAUSTED message: `grep -q "BASELINE_RETRY_EXHAUSTED" plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
    4. Verify epic state: `jq -e '.specs[] | select(.name == "role-boundaries") | .status' specs/_epics/engine-roadmap-epic/.epic-state.json | grep -q "completed"`
    5. Verify role-contracts.md external-reviewer: `grep "external-reviewer" plugins/ralph-specum/references/role-contracts.md | head -1 | grep -q "tasks.md"`
    6. Verify Step 4 path: `grep "baseline.json" plugins/ralph-specum/references/role-contracts.md` should return nothing
    7. Verify design.md dedup: `grep -c "Phase 1 agent identity limitation" specs/role-boundaries/design.md | grep -qE "^1$"`
    8. Verify qa-engineer: `grep -c "## Role Boundaries" plugins/ralph-specum/agents/qa-engineer.md | grep -qE "^1$"` (one from DO NOT section, not empty heading)
  - **Verify**: All 8 verification checks pass
  - **Done when**: All forensic issues resolved and verified
  - **Commit**: `chore(role-boundaries): final verification of forensic audit fixes`
  - _Covers: All forensic audit issues #1-#24_

### 5.18 [BMAD Adversarial Review] Final review of all fixes

- [x] 5.18 [BMAD] Final adversarial review of all forensic audit fixes
  - **Do**:
    1. Run `/bmad-party-mode --review-adversarial --full-spec-review` on the role-boundaries spec after all fixes
    2. Use agents: bmad-agent-architect, bmad-agent-dev, bmad-agent-pm, bmad-testarch-test-review
    3. Ask: "Is the role-boundaries spec now functionally sound? Has Capa 2 been fully restored? Are there any remaining issues?"
    4. Collect findings, evaluate using decision framework
    5. Apply valid fixes
    6. Repeat until 0 findings
  - **Verify**: 0 findings from final BMAD adversarial review
  - **Done when**: Final BMAD review passes with 0 findings
  - **Commit**: `chore(role-boundaries): BMAD final review passed — all forensic audit issues resolved`
  - _Covers: Full spec validation after all fixes_

## Phase 6: Forensic Audit Round 2 Fixes

Focus: Fix verified real issues from second-review report (RR-001, RR-002, RR-003, RR-007). Each fix followed by BMAD adversarial review.

### 6.1 Fix jq nested path resolution (RR-001, CRITICAL)

stop-watcher.sh line 591 uses `jq 'has($f)'` where `$f` = `"chat.executor.lastReadLine"`. State files use NESTED JSON: `{"chat":{"executor":{"lastReadLine":42}}}`. `has("chat.executor.lastReadLine")` looks for a top-level key and returns `false` — the field check always fails, breaking Capa 2 validation.

Baseline file stores flat key names (e.g., `"chat.executor.lastReadLine"`). State file uses nested JSON. The fix: use `getpath(($f | split(".")))` which correctly resolves dotted keys against nested objects.

**Verified bug**:
```
echo '{"chat":{"executor":{"lastReadLine":42}}}' | jq 'has("chat.executor.lastReadLine")' → false (BUG)
echo '{"chat":{"executor":{"lastReadLine":42}}}' | jq 'getpath(("chat.executor.lastReadLine" | split("."))) != null' → true (FIX)
```

- [x] 6.1 Fix jq nested path resolution in stop-watcher.sh (RR-001)
  - **Do**:
    1. Replace line 591: change `has($f)` to `getpath(($f | split("."))) != null`
    2. Replace line 604: change `.[ $f ] | type` to `getpath(($f | split("."))) | type`
    3. Simplify lines 593-599: remove BASELINE_DEFAULT check (it's empty string), just log "missing in state"
    4. Verify syntax: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Files**: `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: `getpath` correctly resolves all 4 dotted field keys against nested state JSON
  - **Verify**:
    1. `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo SYNTAX_PASS`
    2. `echo '{"chat":{"executor":{"lastReadLine":42}}}' | jq 'getpath(("chat.executor.lastReadLine" | split("."))) != null' | grep -q true && echo GETPATH_PASS`
    3. `echo '{"chat":{"reviewer":{"lastReadLine":10}}}' | jq 'getpath(("chat.reviewer.lastReadLine" | split("."))) != null' | grep -q true && echo GETPATH_PASS`
  - **Commit**: `fix(role-boundaries): fix jq nested path resolution using getpath (RR-001)`
  - _Requirements: Capa 2 field validation_
  - _Design: stop-watcher.sh field validation logic_

### 6.2 [BMAD Adversarial Review] Validate RR-001 fix

- [x] 6.2 [BMAD] Adversarial review of jq nested path fix (T6.1)
  - **Do**:
    1. Review the change from `has($f)` / `.[ $f ]` to `getpath(($f | split(".")))`
    2. Verify getpath correctly resolves all 4 baseline fields against nested state structure
    3. Verify getpath handles flat baseline keys correctly (baseline file is flat, state is nested)
    4. Verify no regressions in field validation logic
    5. If findings → fix → review again. Repeat until 0 findings.
  - **Verify**: 0 adversarial findings from jq path fix review
  - **Done when**: BMAD adversarial review passes with 0 findings
  - **Commit**: `chore(role-boundaries): BMAD review passed for jq path fix (RR-001)`

### 6.3 Move validation block before ALL_TASKS_COMPLETE (RR-002, HIGH)

The "All tasks verified complete" `exit 0` at line 525 is INSIDE the execution completion verification `if` block. The Role Boundaries validation block starts at line 528 (AFTER the exit). When all tasks are complete, the script exits at line 525 without ever running the validation.

Fix: Move the validation block (lines 528-633, ~106 lines) to AFTER line 491 (after state logging) and BEFORE the ALL_TASKS_COMPLETE if block (line 494).

- [x] 6.3 Move role boundaries validation block before ALL_TASKS_COMPLETE exit (RR-002)
  - **Do**:
    1. Identify lines 528-633 (Role Boundaries validation block from `# --- End Role Boundaries Validation ---` header through closing `fi`)
    2. Cut the entire block (lines 528-633)
    3. Paste it after line 492 (after state logging `fi` block) and before line 494 (before execution completion verification `if`)
    4. The block now runs BEFORE ALL_TASKS_COMPLETE exit, ensuring validation always executes during non-completion stops
    5. Verify syntax: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Files**: `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: Validation block is positioned before ALL_TASKS_COMPLETE exit and runs on every stop
  - **Verify**:
    1. `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo SYNTAX_PASS`
    2. `grep -n "All tasks verified complete" plugins/ralph-specum/hooks/scripts/stop-watcher.sh` → verify line > role boundaries block line
    3. `grep -n "Role Boundaries: Field-Level Validation" plugins/ralph-specum/hooks/scripts/stop-watcher.sh` → verify block moved to earlier position
  - **Commit**: `fix(role-boundaries): move validation block before ALL_TASKS_COMPLETE exit (RR-002)`
  - _Requirements: Capa 2 field validation always runs_
  - _Design: stop-watcher.sh execution flow_

### 6.4 [BMAD Adversarial Review] Validate validation block relocation (RR-002)

- [x] 6.4 [BMAD] Adversarial review of validation block relocation (T6.3)
  - **Do**:
    1. Verify the moved validation block is logically correct in its new position
    2. Check variable references (STATE_FILE, SPEC_PATH, CWD) are still valid
    3. Verify block runs at correct point: after state logging, before ALL_TASKS_COMPLETE exit
    4. Verify no code gaps created in stop-watcher.sh flow
    5. Verify existing stop-watcher behavior unchanged for non-validation paths
    6. If findings → fix → review again. Repeat until 0 findings.
  - **Verify**: 0 adversarial findings from block relocation review
  - **Done when**: BMAD adversarial review passes with 0 findings
  - **Commit**: `chore(role-boundaries): BMAD review passed for validation block relocation (RR-002)`

### 6.5 Fix baseline.json typo in role-contracts.md (RR-003, LOW)

Line 38 of role-contracts.md Access Matrix says `baseline.json` instead of `.ralph-field-baseline.json`.

- [x] 6.5 Fix baseline.json typo to .ralph-field-baseline.json in role-contracts.md (RR-003)
  - **Do**:
    1. Change line 38: `baseline.json` → `.ralph-field-baseline.json`
  - **Files**: `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/references/role-contracts.md`
  - **Done when**: Access Matrix correctly references `.ralph-field-baseline.json`
  - **Verify**: `grep -q ".ralph-field-baseline.json" plugins/ralph-specum/references/role-contracts.md && echo TYPO_FIX_PASS`
  - **Commit**: `fix(role-boundaries): fix baseline.json typo to .ralph-field-baseline.json (RR-003)`
  - _Requirements: Documentation accuracy_

### 6.6 [BMAD Adversarial Review] Validate typo fix (RR-003)

- [x] 6.6 [BMAD] Adversarial review of baseline filename typo fix (T6.5)
  - **Do**:
    1. Verify the typo fix is correct and matches actual filename used in stop-watcher.sh
    2. Check if `baseline.json` appears anywhere else in the spec that also needs fixing
    3. If findings → fix → review again. Repeat until 0 findings.
  - **Verify**: 0 adversarial findings from typo fix review
  - **Done when**: BMAD adversarial review passes with 0 findings
  - **Commit**: `chore(role-boundaries): BMAD review passed for baseline filename typo fix (RR-003)`

### 6.7 Fix BOUNDARY_VOLATION typo in tasks.md (RR-007, LOW)

Line 117 of tasks.md has `BOUNDARY_VOLATION` (missing 'I') in the grep verify command.

- [x] 6.7 Fix BOUNDARY_VOLATION typo to BOUNDARY_VIOLATION in tasks.md verify command (RR-007)
  - **Do**:
    1. Change line 117: `BOUNDARY_VOLATION` → `BOUNDARY_VIOLATION`
  - **Files**: `/mnt/bunker_data/ai/smart-ralph/specs/role-boundaries/tasks.md`
  - **Done when**: Grep verify command references correct spelling matching stop-watcher.sh
  - **Verify**: `grep -q "BOUNDARY_VIOLATION" specs/role-boundaries/tasks.md && ! grep -q "BOUNDARY_VOLATION" specs/role-boundaries/tasks.md && echo TYPO_FIX_PASS`
  - **Commit**: `fix(role-boundaries): fix BOUNDARY_VOLATION typo to BOUNDARY_VIOLATION (RR-007)`
  - _Requirements: Documentation accuracy_

### 6.8 [BMAD Adversarial Review] Validate typo fix (RR-007)

- [x] 6.8 [BMAD] Adversarial review of BOUNDARY_VOLATION typo fix (T6.7)
  - **Do**:
    1. Verify the typo fix matches the actual string in stop-watcher.sh
    2. Check if `BOUNDARY_VOLATION` appears anywhere else in tasks.md or other spec files
    3. If findings → fix → review again. Repeat until 0 findings.
  - **Verify**: 0 adversarial findings from typo fix review
  - **Done when**: BMAD adversarial review passes with 0 findings
  - **Commit**: `chore(role-boundaries): BMAD review passed for BOUNDARY_VOLATION typo fix (RR-007)`

### 6.9 Final verification of all Phase 6 fixes

- [x] 6.9 [VERIFY] Comprehensive verification of all Phase 6 fixes
  - **Do**:
    1. Verify jq fix: `echo '{"chat":{"executor":{"lastReadLine":42}}}' | jq 'getpath(("chat.executor.lastReadLine" | split("."))) != null' | grep -q true`
    2. Verify validation block position: `grep -n "Role Boundaries\|All tasks verified" plugins/ralph-specum/hooks/scripts/stop-watcher.sh` confirms block before exit
    3. Verify role-contracts.md typo fix: `grep "ralph-field-baseline.json" plugins/ralph-specum/references/role-contracts.md`
    4. Verify tasks.md typo fix: `grep "BOUNDARY_VIOLATION" specs/role-boundaries/tasks.md | grep -v VOLATION`
    5. Verify syntax: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Verify**: All 5 verification checks pass
  - **Done when**: All Phase 6 fixes verified correct
  - **Commit**: `chore(role-boundaries): final verification of forensic audit round 2 fixes`
  - _Covers: RR-001, RR-002, RR-003, RR-007_

### 6.10 [BMAD Adversarial Review] Final review of all Phase 6 fixes

- [x] 6.10 [BMAD] Final adversarial review of all forensic audit round 2 fixes
  - **Do**:
    1. Run BMAD party-mode with adversarial skill on the role-boundaries spec after all Phase 6 fixes
    2. Use agents: bmad-agent-architect, bmad-agent-dev
    3. Ask: "Is the role-boundaries spec now functionally sound? Has Capa 2 been fully restored? Are there any remaining issues from the second-review report?"
    4. Collect findings, evaluate using decision framework
    5. Apply valid fixes
    6. Repeat until 0 findings
  - **Verify**: 0 findings from final BMAD adversarial review
  - **Done when**: Final BMAD review passes with 0 findings
  - **Commit**: `chore(role-boundaries): BMAD final review passed — forensic audit round 2 issues resolved`
  - _Covers: Full spec validation after all Phase 6 fixes_
