# Research: role-boundaries

> **Spec**: role-boundaries (Spec 3 of engine-roadmap-epic)
> **Date**: 2026-04-25
> **Source**: Codebase audit, external research (CrewAI, LangGraph, MCP, CODEOWNERS), BMAD patterns
> **Epic**: specs/_epics/engine-roadmap-epic/epic.md

---

## Executive Summary

This spec addresses I2 (Role Boundary Violations) from the ENGINE_ROADMAP.md. Analysis of the current codebase confirms that **no mechanical or declarative role boundaries exist** for any of the 10 agents. The only constraints are textual DO NOT rules scattered in agent prompts (e.g., spec-executor says "Never modify .ralph-state.json" but there's no enforcement).

**Threat model**: The primary threat is accidental overreach (agent doesn't fully understand constraints). Systematic creep and intentional violations require a PreToolUse layer (Phase 3). Concurrent write corruption is handled by the existing flock mechanism.

Industry patterns (CrewAI tool scoping, LangGraph reducers, GitHub CODEOWNERS) confirm that the most effective approach combines **prompt-based declaration + hook-based verification**. MCP Server Roots is less applicable than previously assumed (category difference: MCP enforces at server level during operations, Smart Ralph hooks fire at session boundaries). BMAD provides useful patterns (phase-based directories, capability menus) but zero mechanical enforcement. Smart Ralph already implements phase-based directory separation via `phase-rules.md` and the phase enum.

**Existing infrastructure**: `channel-map.md` already documents inter-agent channel protocol (locking, signals, writer/reader ownership). `role-contracts.md` should be complementary, extending to cover spec artifact files.

**Key findings**:
- The state file has 27 top-level keys (24 in alternative state files). The access matrix covers ~8. ~19 fields are undocumented.
- The JSON schema is incomplete — missing `external_unmarks`, `awaitingApproval`, `failedStory`, `originTaskIndex`, `repairIteration`, `maxFixTaskDepth`, `chat.reviewer.lastReadLine`, `commitSpec`, `specName`. (The schema correctly defines `maxFixTasksPerOriginal`, `maxTaskIterations`, `globalIteration`, `maxGlobalIterations` and `chat.executor.*`.) The schema also defines `epicName`, `parallelGroup`, `relatedSpecs`, and `taskResults` which may not appear in every state file.
- `chat.reviewer.lastReadLine` IS materialized in at least one state file (`prompt-diet-refactor`), but `chat.executor.lastReadLine` is null there. In `ralph-quality-improvements`, `chat` is null entirely. The schema defines `chat.executor.*` but NOT `chat.reviewer.*`.
- Only 4 fields are written by agents other than the coordinator: `chat.executor.lastReadLine` (spec-executor), `chat.reviewer.lastReadLine` (external-reviewer), `external_unmarks` (external-reviewer), `awaitingApproval` (4 planning agents).
- The 6 planning-phase agents were initially classified as read-only, but `architect-reviewer`, `research-analyst`, `task-planner`, and `product-manager` all write to `.ralph-state.json` (setting `awaitingApproval = true`). They require boundary declarations.

**Recommended approach (phased)**:
- **Phase 1**: Prompt-based DO NOT lists + `references/role-contracts.md` (this spec's primary deliverable)
- **Phase 2**: Field-level state integrity validation in stop-watcher (partial mechanical)
- **Phase 3**: PreToolUse write-block (full mechanical, deferred)

---

## External Research

### Best Practices for AI Agent Role Boundaries

**1. CrewAI — Tool Scoping by Agent Identity** (HIGH RELEVANCE)
Each CrewAI agent is instantiated with its own tool list. Tools are not globally shared — scoped to the declaring agent. This is the most directly applicable pattern: define a file-access matrix where each agent has an explicit allowlist of paths it may read/write.

**2. LangGraph — State Reducer Pattern** (MEDIUM RELEVANCE)
LangGraph uses `StateGraph` where each node receives full state but only writes to fields it owns via reducer functions. **Important caveat**: LangGraph reducers are declarative conventions enforced by the framework runtime — there is no runtime check that a node "wrote to a field it owns." The reducer only defines *how* values merge, not *who* may write. Maps to Smart Ralph as a documentation-only pattern for `.ralph-state.json` field ownership. True field-level enforcement would require a wrapper that validates writes against an ownership map.

**3. MCP Server Roots** (LOW RELEVANCE)
MCP servers can only access files within declared `file://` roots. This provides mechanical enforcement at the server level. **Category difference**: MCP enforcement is at the server process level during operations, while Smart Ralph's stop-watcher fires at Stop boundaries (after Claude has already acted). The stop-watcher has no visibility into what files the agent accessed during the session. The pattern is useful as inspiration for future design, but enforcement would require a PreToolUse hook that intercepts Edit/Write tool calls — a different architecture than what stop-watcher provides.

**4. GitHub CODEOWNERS** (MEDIUM RELEVANCE)
Path-based ownership with last-match-wins precedence and enforced review requirements. Suggests designating spec-reviewer as the "owner" of `references/role-contracts.md` (no other agent should modify it).

### Permission Enforcement Patterns

**Threat Model**

Before evaluating enforcement patterns, the threat model must be defined:

| Threat | Description | Sufficient Defense |
|--------|-------------|-------------------|
| Accidental overreach | Agent doesn't fully understand its constraints | Prompt DO NOT lists + post-facto hook validation |
| Systematic boundary creep | Agent gradually expands scope beyond intended boundaries | PreToolUse write blocking + baseline checksums |
| Concurrent write corruption | Two agents write to the same file/field simultaneously | Existing flock mechanism (already in place) |
| Model failure to follow negative constraints | LLM generates tool calls that violate boundaries despite instructions (not "intent" — LLMs lack agency) | PreToolUse blocking (required; post-facto not sufficient for repeated failures) |
| State file deletion/truncation | Agent or process deletes or corrupts `.ralph-state.json` entirely | Stop-watcher file-existence check + backup/rollback protocol (out of scope for Phase 1) |

The role-boundaries spec primarily targets accidental overreach (Phase 1). Systematic and intentional violations require the PreToolUse layer (Phase 3).

**Hybrid Enforcement (Prompt + Hook)** — The most effective pattern for AI agent systems combines:
1. Prompt-based declaration: agent system prompt explicitly states what it can/cannot access (DO NOT edit lists)
2. Hook-based verification: external process validates access before/after operations

This is exactly what Smart Ralph needs: the prompt provides first-line defense during execution, the hook provides post-facto validation.

**Explicit DENY Lists** — Instead of allowlists (which require enumerating everything allowed), denylists are more practical for Smart Ralph's model where agents read broadly but write narrowly. Example: "DO NOT write .ralph-state.json" is simpler than "CAN read everything except .ralph-state.json."

### State Integrity Detection

**State File Hash Checksums** — Store SHA-256 hashes of critical state files at checkpoints. On subsequent agent runs, compute and compare. Lightweight and works with the existing file-based state model.

**Pre-Operation Validation Hooks** — A hook validates access before allowing file writes by checking the role-contracts.md matrix. Requires integration with Task delegation layer.

**Git-Based Change Detection** — `git diff --name-only HEAD` against agent allowlists. After each task commit, compare modified files against what the agent is allowed to touch.

### Relevant Prior Art

- **CrewAI**: Tool scoping per agent — direct model for file access matrix
- **MCP Server Roots**: File:// URI boundaries — inspiration for boundary design, but enforcement architecture differs (server-level vs hook-level)
- **LangGraph reducers**: Field ownership documentation — convention-only, not mechanical enforcement
- **GitHub CODEOWNERS**: Path-based ownership convention — model for designating role-contracts.md owner
- **Claude Code permissions**: User-level allowlist — less relevant (single-user model)
- **Smart Ralph channel-map.md**: Existing inter-agent channel protocol (locking, signals) — foundation for role-contracts.md

---

## Codebase Analysis

### Existing Agent File Patterns

All 10 agents in `plugins/ralph-specum/agents/` are markdown files with YAML frontmatter (`name`, `description`, `color`). Beyond that, structure varies significantly:
- `spec-executor.md`, `external-reviewer.md`: Use XML-like section tags (`<role>`, `<startup>`, `<rules>`, `<bookend>`)
- `spec-reviewer.md`: Uses rubric-based sections with `<mandatory>` tags
- `task-planner.md`: Numbered sections with `<mandatory>` tags
- `triage-analyst.md`: Simple numbered sections (~95 lines, different shape)
- Others: Mixed patterns

This structural diversity means any automated tooling (e.g., programmatic DO NOT list generation from role-contracts.md) would need to handle multiple formats. Appending sections to XML-tagged files is safer than to numbered-section files.

**Key agents**:
- `spec-executor.md` (373 lines): Uses `<bookend>` to restate critical rules. Already has "Never modify .ralph-state.json" — but no mechanical enforcement.
- `external-reviewer.md` (700 lines): 8 numbered sections. Already has "Never modify .ralph-state.json (except chat state fields and external_unmarks)" — but no enforcement.
- `qa-engineer.md` (751 lines): Reads `.ralph-state.json` for taskIndex. No explicit DO NOT list.
- `spec-reviewer.md` (275 lines): Already read-only ("NEVER modify any files"). No DO NOT list needed.

### Reference File Conventions

16 of 18 reference files in `plugins/ralph-specum/references/` follow:
1. YAML frontmatter with `name`/`description`
2. `"> Used by:"` line listing consumers
3. `##` heading sections
4. Tables, code blocks, lists

### Inter-Agent Communication: channel-map.md

A critical existing document was identified: `references/channel-map.md`. This is a comprehensive reference documenting:
- All inter-agent channels (chat.md, task_review.md, tasks.md, .progress.md, .ralph-state.json)
- Writer/reader ownership per channel
- Locking strategy (fd 200 for chat.md, fd 201 for tasks.md)
- A "Race Condition Risk Register" with HIGH/MEDIUM/LOW ratings
- An "Adding a New Agent" checklist

**Impact on role-boundaries design**: `channel-map.md` already fulfills much of what `role-contracts.md` would provide for filesystem channels. The relationship should be:
- `channel-map.md` = channel-level protocol (who writes what, locking, signals)
- `role-contracts.md` = file-level boundaries (who can read/write which files, denylists)
- They are complementary, not redundant. `role-contracts.md` should reference `channel-map.md` and extend it to cover spec artifact files (requirements.md, design.md, etc.) that channel-map.md does not address.

### Inter-Agent Communication: chat.md Identity Protocol

The chat.md template documents a bidirectional agent-chat protocol with:
- Identity-labeled messages: `### [YYYY-MM-DD HH:MM:SS] writer -> addressee`
- Signal types: OVER, ACK, CONTINUE, HOLD, PENDING, STILL, DEADLOCK, URGENT, etc.
- Mechanical HOLD/PENDING/DEADLOCK detection via `grep` (detected by stop-watcher)
- The coordinator reads chat.md before delegating

This is a form of existing cross-agent boundary enforcement: the external-reviewer can halt the executor via chat.md signals. The role-boundaries spec should note that `chat.executor.lastReadLine` is the executor's read pointer into this channel, and `chat.reviewer.lastReadLine` is the reviewer's pointer.

### Inter-Agent Communication: progressFile Patterns

The codebase uses per-task progress files (`.progress-task-*.md`) for parallel execution. The `spec-executor` writes to these dynamically-named files. The stop-watcher handles parallel group coordination and cleanup of orphaned temp progress files. Role-contracts.md must account for `progressFile` paths as write targets for spec-executor, noting that these are dynamically named per task.

### Additional Boundary-Sensitive Files

Beyond the core channels, these files require boundary declarations:
- **`.progress.md`**: Multi-writer (coordinator, spec-executor, external-reviewer). No explicit flock — potential contention risk. Boundary: only coordinator + spec-executor + external-reviewer may write; all others DO NOT.
- **`task_review.md`**: Single-writer (external-reviewer only, no locking needed per channel-map.md). Readers: spec-executor (External Review Protocol step 2b), coordinator (Pre-Delegation Check). Role-contracts.md should declare: spec-executor has NO write permission; no other agent should write.

### Current State File Access Matrix

| Agent | Reads | Writes | Specific Fields |
|-------|-------|--------|----------------|
| **Coordinator** | ALL | ALL | Primary state writer |
| **spec-executor** | phase, taskIndex, totalTasks, chat.executor.lastReadLine | chat.executor.lastReadLine only | Forbidden: "Never modify .ralph-state.json (except chat.lastReadLine)" |
| **external-reviewer** | All state fields | external_unmarks[taskId], chat.reviewer.lastReadLine | Forbidden: ".ralph-state.json (except chat state fields and external_unmarks)" |
| `chat.reviewer.lastReadLine` is materialized in prompt-diet-refactor (value 490); `chat.executor.lastReadLine` is null there. The schema defines `chat.executor.*` but NOT `chat.reviewer.*`. |
| **qa-engineer** | taskIndex | Nothing | Reads-only |
| **spec-reviewer** | Nothing (content from delegation) | Nothing | Purely read-only |
| **stop-watcher.sh** | All fields | Nothing | Read-only |

**Finding**: Only 4 fields are written by agents other than the coordinator. But the constraints are text-only — no mechanical enforcement exists. The spec-executor uses `jq` to write `chat.executor.lastReadLine`, which is an indirect write pattern that hooks cannot intercept.

**Critical gap**: The research matrix covers ~8 of 27 top-level state fields (24 in alternative state files). Additional fields not in the matrix: `awaitingApproval`, `failedStory`, `repairIteration`, `originTaskIndex`, `fixTaskMap`, `modificationMap`, `maxFixTasksPerOriginal`, `maxFixTaskDepth`, `maxModificationsPerTask`, `maxModificationDepth`, `nativeTaskMap`, `nativeSyncEnabled`, `nativeSyncFailureCount`, `granularity`, `globalIteration`, `maxGlobalIterations`, `maxTaskIterations`, `recoveryMode`, `taskResults`. **Schema incompleteness**: The JSON schema at `plugins/ralph-specum/schemas/spec.schema.json` is missing 9 fields present in state files: `external_unmarks`, `awaitingApproval`, `failedStory`, `originTaskIndex`, `repairIteration`, `maxFixTaskDepth`, `chat.reviewer.lastReadLine`, `commitSpec`, `specName`. (The schema correctly defines `maxFixTasksPerOriginal`, `maxTaskIterations`, `globalIteration`, `maxGlobalIterations` and `chat.executor.*` — but `chat.executor.lastReadLine` is null in state files while `chat.reviewer.lastReadLine=490` is materialized.) State files vary: `prompt-diet-refactor` has `source`/`name`/`chat` with `reviewer.lastReadLine=490`; `ralph-quality-improvements` has `specName` and `chat=null`. A complete `role-contracts.md` must document ALL state fields, not just the write exceptions.

**Non-execution agents**: The codebase has 10 agents total. 4 run once per spec lifecycle (planning phase): architect-reviewer, product-manager, research-analyst, task-planner. 2 run post-execution: refactor-specialist (updates spec files after execution), triage-analyst (decomposes features). **Classification gap**: `architect-reviewer`, `research-analyst`, `task-planner`, and `product-manager` all write to `.ralph-state.json` (setting `awaitingApproval = true` via jq). These are not purely read-only — they are state writers with limited write scope. `refactor-specialist` reads `.ralph-state.json` for context (confirmed no writes found). `triage-analyst` reads `.progress.md` and spec files; state file access not confirmed. The research recommends that ALL agents with state access should have explicit boundary declarations, with non-execution agents receiving DO NOT lists in the initial rollout (same as execution agents).

### State File Schema Drift

Comparing actual state files reveals discrepancies that affect baseline storage:
- `prompt-diet-refactor` uses `source`/`name`, has `chat` object with `reviewer.lastReadLine=490`
- `ralph-quality-improvements` uses `specName` (not `source`/`name`), `chat=null`
- `basePath` is relative (`specs/...`) in one, absolute (`/mnt/...`) in another

**Impact on field-level diff**: The stop-watcher must handle schema-version-dependent field presence. When comparing fields against baseline, skip fields that don't exist in a given spec's state file rather than flagging them as unauthorized changes.

### Hook Capabilities

**Current hooks**: PreToolUse (quick-mode-guard blocks AskUserQuestion), Stop (stop-watcher), SessionStart (load-spec-context).

**stop-watcher.sh — Current capabilities** (what it DOES today):
- JSON syntax validation of `.ralph-state.json` (mechanical corruption detection)
- Cross-check: taskIndex vs unchecked items in tasks.md
- Transcript signal detection (ALL_TASKS_COMPLETE, VERIFICATION_FAIL/PASS/DEGRADED, HOLD, DEADLOCK)
- quickMode enforcement (blocks non-quick-mode agents)
- Global iteration limit enforcement
- Repair loop exhaustion detection
- Parallel group coordination

**stop-watcher.sh — Proposed additions** (what the role-boundaries spec would add):
- Baseline field-level snapshot of `.ralph-state.json` at spec start
- Field-level diff on each Stop hook: compare individually-owned fields against baseline
- Flag unauthorized field modifications (agent wrote to a field it does not own)
- Git diff allowlist checking: compare modified files against agent boundaries

**stop-watcher.sh — Still CANNOT detect** (even after extension):
- File access during the session (hooks only fire at Stop boundaries)
- Which specific agent made a modification (agent identity not available in hook input)
- Semantic correctness of state values (only field ownership can be checked)

**PreToolUse hooks**: Can deny tool calls via `hookSpecificOutput.permissionDecision: "deny"`. This is the only path to pre-emptive mechanical enforcement of file write boundaries. Key limitation: agent identity may not be available in the hook input, limiting boundary checks to agent-agnostic rules (e.g., "non-coordinator agents cannot write to .ralph-state.json").

---

## BMAD Role Boundary Patterns

### BMAD Has No Mechanical Enforcement

BMAD uses procedural instructions only. Transferable patterns:

| BMAD Pattern | Transferability | Smart Ralph Adaptation |
|-------------|----------------|----------------------|
| Phase-based directories (planning vs implementation) | Already implemented | Smart Ralph already implements phase-based separation via `phase-rules.md` and the phase enum in schema. The BMAD pattern transfer is moot — the infrastructure exists. |
| Capability menu (agents can only invoke listed skills) | Medium | Hook-level validation that only allowed skills are dispatched per agent |
| Story file section discipline | Medium | Template sections with explicit executor-writable markers |
| Role statements in config | Low | Already done via agent markdown definitions |
| Shared config as coordination layer | Medium | `.ralph-state.json` is a mutable execution state machine, NOT a static config. Using it for role declarations would be architecturally different from BMAD's intent. `role-contracts.md` is the correct complementary file. |
| Mechanical enforcement | None found | Must be invented — hook-level path validation |
| Negative constraints (DO NOT lists) | None found | Must be invented — denylist or capability-based ACL |

**Key BMAD insight**: Phase-based directory separation is the most transferable pattern. Smart Ralph could pass agent-permitted paths as session-scoped config variables — the executor simply doesn't receive the paths it's not allowed to write to.

---

## Related Specs

| Spec | Relevance | Relationship | May Need Update |
|------|-----------|--------------|-----------------|
| `loop-safety-infra` (Spec 4) | Medium | May introduce a new agent (loop-safety component) that needs its own role-contracts.md entry. Will need to validate changes against role-contracts.md before implementation. | Introduces a new agent that needs role contract entry |
| `engine-state-hardening` (Spec 1, completed) | Low | Modifies `.ralph-state.json` field ownership and adds state integrity validation. The role-boundaries hook should coordinate to avoid double-reporting or conflicts with Spec 1's validation. | Coordinate with Spec 1's state integrity validation |
| `bmad-bridge-plugin` (Spec 5) | Medium | New plugin — needs role-contracts.md entry for bmad-bridge agent. Will need the full agent onboarding checklist (Rec #6). | Introduces a new agent that needs role contract entry |
| `collaboration-resolution` (Spec 6) | High | Depends on Spec 3 — modifies same agent files (spec-executor.md, external-reviewer.md). **Must validate proposed changes against role-contracts.md boundaries before implementation.** | Validates changes against role-contracts.md; may update it if boundary expansion is needed |
| `pair-debug-auto-trigger` (Spec 7) | High | Depends on Spec 3 — modifies spec-executor.md. **Must validate changes against role-contracts.md before implementation.** | Validates changes against role-contracts.md; may update it if boundary expansion is needed |

---

## Quality Commands

Not applicable for this spec — no project-level lint/test/build commands to discover.

---

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|-----------|-------|
| **Technical feasibility** | High | Changes are surgical: append to existing files, create one new reference file. No infrastructure changes needed. |
| **Risk** | Low-Medium | Most modifications are additive. However, stop-watcher.sh extension (665 lines) introduces new execution paths that need regression testing. Even additive changes to hooks carry non-trivial risk. |
| **Effort** | Medium | 1 new file (role-contracts.md, ~100-150 lines) + 4 file modifications (~50 lines each) + stop-watcher field-level extension (~200-400 lines) + hook testing. The field-level diff logic is more complex than a simple checksum. |
| **Mechanical enforcement** | Phased (see Rec #5) | Phase 1: Prompt-only. Phase 2: Post-facto field-level validation. Phase 3: PreToolUse pre-emptive blocking. Initial rollout has no mechanical layer. |
| **Future-proof** | Moderate | role-contracts.md design leaves room for new agents. However, the drift between role-contracts.md and agent prompt DO NOT lists is a real risk that needs mitigation. |
| **Testing** | Non-trivial | Hook testing requires integration tests that spin up a spec, inject a violating agent, and verify the hook catches it. |

---

## Recommendations for Requirements

1. **role-contracts.md design**: Use path-based DENY lists (not allowlists) since most agents read broadly. Follow reference file conventions (frontmatter, "Used by" line, ## sections). **Designate the coordinator (human) as owner of role-contracts.md**, NOT spec-reviewer. The CODEOWNERS analogy fails here: spec-reviewer's agent file explicitly states "NEVER modify any files", so it cannot fulfill the ownership responsibility. Define BOTH read and write permissions. **Reference `channel-map.md`** for channel-level protocol (locking, signals) and extend to cover spec artifact files. **CrewAI caveat**: CrewAI agents run in separate Python processes with separate tool registries. Smart Ralph agents all run within the same Claude Code session with the same full tool access. The CrewAI pattern provides conceptual inspiration only, not direct implementation guidance.

2. **State field ownership**: Define clear ownership for ALL 27 state fields in role-contracts.md, not just the 4 write exceptions (spec-executor → chat.executor.lastReadLine, external-reviewer → chat.reviewer.lastReadLine + external_unmarks, 4 planning agents → awaitingApproval). Also flag that the JSON schema is incomplete — 9 fields are missing from `spec.schema.json`: `external_unmarks`, `awaitingApproval`, `failedStory`, `originTaskIndex`, `repairIteration`, `maxFixTaskDepth`, `chat.reviewer.lastReadLine`, `commitSpec`, `specName`. The schema correctly defines `maxFixTasksPerOriginal`, `maxTaskIterations`, `globalIteration`, `maxGlobalIterations` and `chat.executor.*`. The schema also defines `epicName`, `parallelGroup`, `relatedSpecs`, and `taskResults` which may not appear in every state file.

3. **DO NOT lists**: Append to each of the 4 target agent files. Placement: before `<bookend>` (spec-executor), before final section (other agents). Mirror the existing pattern of restating critical rules. **Write boundaries** should use explicit denylists. **Read boundaries** are advisory-only — there is no mechanism to prevent agents from reading files (the Read tool cannot be restricted by prompt instructions, and no PreToolUse hook exists for the Read tool). Document read boundary risks by severity: **HIGH** — cross-spec state contamination (partially mitigable via path isolation); **MEDIUM** — reading uncommitted agent context (advisory only); **LOW** — reading public reference files (acceptable). Note: templates/ directory files are read-only for execution agents. Template modifications should be done by planning-phase agents or human review. Lock files (`.tasks.lock`, `.git-commit.lock`) should be declared as "auto-generated — no agent should manually create, modify, or delete." The stop-watcher should not validate lock file changes.

4. **Field-level state integrity hook**: Instead of a single file checksum (which cannot distinguish legitimate coordinator writes from unauthorized agent writes), use a field-level snapshot approach: (a) At spec start, extract each individually-owned field into a **baseline JSON file** (e.g., `.ralph-field-baseline.json` alongside `.ralph-state.json`), NOT stored within the state file itself to avoid the same concurrency vulnerability. (b) On Stop hook, diff each field individually against the baseline. (c) Only flag if an agent wrote to a field it does not own. **Concurrency note**: The state file uses `jq` read-modify-write via temp file + `mv` atomic writes. **This pattern is NOT flock-protected** (unlike chat.md and tasks.md writes). If the coordinator and external-reviewer write simultaneously, one write can silently overwrite the other (last-writer-wins). The stop-watcher's field diff logic must use its own flock or retry loop to avoid reading partial state during concurrent writes (false positive risk). **Fallback**: If baseline is missing at Stop time (e.g., spec started without baseline capture, or migrated from older format), skip field-level validation for this spec and log a warning. Fields present in state but not in baseline: treat as "unknown ownership — skip" rather than "unauthorized change."

5. **Phased mechanical enforcement**: Explicitly define the enforcement layers as phased:
   - **Phase 1**: Prompt-based DO NOT lists (this spec's primary deliverable)
   - **Phase 2**: Post-facto field-level validation in stop-watcher (partial mechanical)
   - **Phase 3**: PreToolUse write-block (full mechanical, deferred)
   Acceptance criteria should be tied to the appropriate phase. Claiming "mechanical enforcement" for Phase 1 is inaccurate.

6. **Agent onboarding checklist**: When a new agent is added (e.g., bmad-bridge-plugin), follow a minimal checklist: (a) Add role-contracts.md entry, (b) Append DO NOT list to the agent file, (c) Update channel-map.md if the agent uses inter-agent channels, (d) Register with hook system if needed.

7. **Conflict resolution**: Define what happens when two agents have overlapping write permissions. The existing flock mechanism handles concurrent writes to chat.md and tasks.md, but the role-contracts.md should explicitly state which files have concurrent-write support and which are single-writer-only.

8. **Rollback mechanism**: Define system behavior when a violation is detected: halt spec, log warning and continue, or require manual review? This is an open design decision for the requirements phase.

9. **Non-execution agent boundaries**: Explicitly address the 6 non-execution agents (4 planning-phase: architect-reviewer, product-manager, research-analyst, task-planner; 2 post-execution: refactor-specialist, triage-analyst). Recommend at minimum read-only boundary declarations, even if not part of the initial DO NOT list rollout.

10. **PreToolUse hook (future)**: Consider adding a PreToolUse hook that checks Edit/Write tool calls against role-contracts.md. This would provide pre-emptive blocking of unauthorized writes. Key challenge: agent identity is not available in hook input, limiting to agent-agnostic rules. Defer to Phase 3.

11. **Drift mitigation**: **Out of scope for this spec.** Programmatic generation requires a parser for role-contracts.md and embedding into agent prompts — neither infrastructure exists. Manual validation requires a process that "almost certainly won't happen without automation." Both options require non-trivial investment. Document the risk and add drift mitigation as a candidate for a future spec, not Phase 1 or Phase 2.

---

## Open Questions

1. **Should role-contracts.md use glob patterns or explicit paths?** Glob patterns (e.g., `specs/**`) are more flexible but harder to audit. Explicit paths are more precise but require updates when new files are added.

2. **What level of enforcement is viable with PreToolUse hooks?** The research initially suggested accepting that hooks cannot detect file access during the session. However, PreToolUse hooks CAN intercept Edit/Write tool calls before they execute, and the tool input includes the file path. The real question is whether agent identity is available in hook input (likely not without modification).

3. **Should spec-reviewer need a DO NOT list?** It's already read-only ("NEVER modify any files").

4. **What is the rollback mechanism when a violation is detected?** If the hook detects an unauthorized write, what is the system behavior? Options: (a) halt spec, (b) log warning and continue, (c) attempt rollback, (d) require manual review. This is a critical design decision for the requirements phase.

5. **How should role-contracts.md relate to channel-map.md?** channel-map.md already documents channel-level protocol (locking, signals, writer/reader ownership) for core channels. Should role-contracts.md replace it, be complementary, or reference it?

6. **How do we prevent drift between role-contracts.md and agent prompt DO NOT lists?** Two representations of the same boundary knowledge will inevitably drift. This requires a decision in the requirements phase — either accept duplication, or invest in generating DO NOT lists programmatically from role-contracts.md at session start.

---

## Sources

### Codebase Files Audited
- `plugins/ralph-specum/agents/spec-executor.md` (373 lines)
- `plugins/ralph-specum/agents/external-reviewer.md` (700 lines)
- `plugins/ralph-specum/agents/qa-engineer.md` (751 lines)
- `plugins/ralph-specum/agents/spec-reviewer.md` (275 lines)
- `plugins/ralph-specum/agents/task-planner.md` (1017 lines)
- `plugins/ralph-specum/agents/triage-analyst.md` (95 lines)
- `plugins/ralph-specum/hooks/hooks.json`
- `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` (665 lines)
- `plugins/ralph-specum/hooks/scripts/load-spec-context.sh` (110 lines)
- `plugins/ralph-specum/hooks/scripts/quick-mode-guard.sh` (47 lines)
- `plugins/ralph-specum/hooks/scripts/path-resolver.sh` (252 lines)
- `plugins/ralph-specum/references/phase-rules.md`
- `plugins/ralph-specum/references/commit-discipline.md`
- `plugins/ralph-specum/references/channel-map.md` (critical existing reference for inter-agent channels)
- `plugins/ralph-specum/references/` (18 files, 16 with "Used by" convention)
- `plugins/ralph-specum/templates/chat.md`
- `plugins/ralph-specum/schemas/spec.schema.json` (incomplete — missing 9 fields: `external_unmarks`, `awaitingApproval`, `failedStory`, `originTaskIndex`, `repairIteration`, `maxFixTaskDepth`, `chat.reviewer.lastReadLine`, `commitSpec`, `specName`)

### External Sources
- CrewAI documentation — tool scoping per agent
- LangGraph StateGraph — reducer pattern for state field ownership
- MCP Specification — Server Roots filesystem boundaries
- GitHub CODEOWNERS — path-based file ownership
- BMAD framework — role statements, phase-based directories, capability menus (`.agents/skills/bmad-agent-*/`)
