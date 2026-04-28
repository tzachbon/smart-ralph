# Requirements: Role Boundaries

## Goal
Define who can read/write which files during execution and enforce those boundaries mechanically in all agent prompts and the state integrity hook.

## User Stories

### US-1: Role Contract File
**As a** Smart Ralph engineer
**I want to** have a single `references/role-contracts.md` file with an access matrix covering all 10 agents and all spec artifact files
**So that** I can see at a glance what each agent is allowed to read and write, without scanning individual agent prompts

**Acceptance Criteria:**
- [ ] AC-1.1: `references/role-contracts.md` exists following reference file conventions (YAML frontmatter with `name`/`description`, `"> Used by:"` line, `##` heading sections)
- [ ] AC-1.2: Access matrix includes ALL 10 agents (spec-executor, external-reviewer, qa-engineer, spec-reviewer, architect-reviewer, product-manager, research-analyst, task-planner, refactor-specialist, triage-analyst)
- [ ] AC-1.3: Matrix covers all channels from channel-map.md (chat.md, task_review.md, tasks.md, .progress.md, .ralph-state.json) plus spec artifact files (requirements.md, design.md, tasks.md, research.md)
- [ ] AC-1.4: Each agent row specifies explicit read and write permissions, not just "DO NOT" prohibitions
- [ ] AC-1.5: State field ownership is documented for ALL state fields (not only the 4 write exceptions)
- [ ] AC-1.6: References `channel-map.md` in a "Relationship to Channel Map" section explaining complementary scope
- [ ] AC-1.7: Lock files (`.tasks.lock`, `.git-commit.lock`, `chat.md.lock`) are listed as auto-generated. The coordinator writes `chat.md.lock` and the reviewer writes `tasks.md.lock` per the existing channel-map.md protocol — these are the only agents with lock file write permission; all other agents DO NOT write lock files.

### US-2: Agent Prompt DO NOT Lists
**As a** spec-executor, external-reviewer, qa-engineer, or spec-reviewer
**I want to** have an explicit DO NOT edit list in my agent prompt file that references `role-contracts.md`
**So that** I know at session start which files I am forbidden from touching, and can catch boundary violations before they happen

**Acceptance Criteria:**
- [ ] AC-2.1: `agents/spec-executor.md` has a new section (placed before `<bookend>`) listing files the executor may NOT write to (`.ralph-state.json` except `chat.executor.lastReadLine`, `task_review.md`, code files outside task scope)
- [ ] AC-2.2: `agents/external-reviewer.md` has a new section (placed before Section 8 "Never Do") listing files the reviewer may NOT write to (`.ralph-state.json` except `chat.reviewer.lastReadLine` and `external_unmarks`, `tasks.md` except via explicit unmark protocol, implementation files)
- [ ] AC-2.3: `agents/qa-engineer.md` has a new section (placed after Section 0 "Review Integration" or before "Execution Flow") listing files the qa-engineer may NOT write to (`.ralph-state.json`, `tasks.md`, `task_review.md`, implementation files)
- [ ] AC-2.4: `agents/spec-reviewer.md` has a new section (placed after "Core Philosophy" mandatory block) noting it is read-only and listing files it may NOT modify (all files), with reference to `role-contracts.md`
- [ ] AC-2.5: Each DO NOT section ends with: `See \`references/role-contracts.md\` for the full access matrix.`
- [ ] AC-2.6: Read boundaries are documented as advisory-only with severity ratings in the DO NOT sections: **HIGH** = cross-spec state contamination (e.g., spec-executor reading another spec's .ralph-state.json), **MEDIUM** = reading uncommitted agent context (e.g., another agent's pending task_review.md), **LOW** = reading public reference files (acceptable)

### US-3: State Integrity Hook (Phase 2)
**As a** Smart Ralph engineer maintaining spec integrity
**I want to** detect unauthorized field-level modifications to `.ralph-state.json` via a post-facto validation hook in `stop-watcher.sh`
**So that** I catch accidental overreach (agent writing to a field it does not own) without blocking execution at the agent prompt level (Phase 3)

**Acceptance Criteria:**
- [ ] AC-3.1: Baseline JSON file is created at `<basePath>/references/.ralph-field-baseline.json` within the spec's references directory (not alongside `.ralph-state.json`) to avoid namespace collision with spec-executor write targets and keep baseline separate from execution artifacts.
- [ ] AC-3.2: Baseline file stores field ownership mapping using path-style addressing for nested keys and multi-owner arrays: `{ "chat.executor.lastReadLine": "spec-executor", "chat.reviewer.lastReadLine": "external-reviewer", "external_unmarks": "external-reviewer", "awaitingApproval": ["coordinator", "architect-reviewer", "product-manager", "research-analyst", "task-planner"] }`. For objects with dynamic keys (e.g., `external_unmarks`), the baseline stores the parent key (`"external_unmarks"`) and the validation logic checks if the current state value is an object — if so, all keys within the object are validated as belonging to the same owner. Multi-owner fields list all agents that may write the field.
- [ ] AC-3.3: Baseline capture occurs automatically at spec initialization via `load-spec-context.sh`, which is the hook that runs when the spec directory is first detected. If baseline already exists (re-run of the same spec), it is NOT overwritten. If baseline does not exist (new spec or prior spec), it is created from the current `.ralph-state.json` content.
- [ ] AC-3.4: `stop-watcher.sh` compares current state fields against baseline on each Stop hook, flagging modifications by agents that do not own the field
- [ ] AC-3.5: Unauthorized modification detected: stop-watcher logs warning to stderr, does NOT halt execution (Phase 1 behavior), outputs violation info in the block reason
- [ ] AC-3.6: If baseline file is missing at Stop time: skip field-level validation, log warning to stderr, continue normally (graceful fallback)
- [ ] AC-3.7: Fields present in state but not in baseline: treated as "unknown ownership — skip" rather than "unauthorized change"
- [ ] AC-3.8: Field-level validation uses a dedicated file descriptor (fd 202) for flock on a lock file (e.g., `.ralph-baseline-validation.lock`). Note: this flock protects the stop-watcher's READ of `.ralph-state.json` but does NOT protect against the coordinator's `jq + mv` writes which bypass flock. The stop-watcher should retry reading `.ralph-state.json` up to 3 times with a 1-second delay between retries to mitigate race conditions.
- [ ] AC-3.9: Schema drift is handled by distinguishing three scenarios: (a) new field in state not in baseline = "unknown ownership — skip" (schema evolved), (b) field in baseline not in state = skip (field was legitimately removed or spec uses different schema), (c) field exists in both but ownership doesn't match the modifying agent = violation flag. Each scenario is logged distinctly to avoid confusion.

### US-4: Agent Onboarding Checklist
**As a** Smart Ralph engineer adding a new agent (e.g., bmad-bridge-plugin)
**I want to** follow an explicit checklist when integrating a new agent
**So that** role boundary coverage stays consistent and no agent goes unassigned

**Acceptance Criteria:**
- [ ] AC-4.1: `references/role-contracts.md` includes a "Adding a New Agent" section with exactly 4 numbered steps: (1) add role-contracts.md access matrix entry with read/write permissions, (2) append DO NOT list section to agent file referencing role-contracts.md, (3) update channel-map.md writer/reader ownership if using inter-agent channels, (4) register with hook system if the agent needs custom hook interactions
- [ ] AC-4.2: Checklist includes a "Boundary Template" code block showing the exact format for each step (matrix row format, DO NOT section format, channel-map entry format)
- [ ] AC-4.3: Checklist is cross-referenced from `channel-map.md` "Adding a New Agent" section

### US-5: Non-Execution Agent Boundaries
**As a** Smart Ralph engineer maintaining planning-phase and post-execution agent integrity
**I want to** have explicit boundary declarations for all 6 non-execution agents (4 planning-phase + 2 post-execution)
**So that** accidental overreach by planning/post-execution agents is documented and detectable even if not mechanically enforced in Phase 1

**Acceptance Criteria:**
- [ ] AC-5.1: All 6 non-execution agents appear in `references/role-contracts.md` access matrix with explicit read/write permissions
- [ ] AC-5.2: `architect-reviewer`, `product-manager`, `research-analyst`, `task-planner` boundary declarations note they write `awaitingApproval` to `.ralph-state.json`
- [ ] AC-5.3: `refactor-specialist` boundary declaration notes it reads `.ralph-state.json` for context but has no write permissions
- [ ] AC-5.4: `triage-analyst` boundary declaration notes it reads `.progress.md` and spec files; state file access not confirmed
- [ ] AC-5.5: None of the non-execution agents appear in the Phase 1 DO NOT list rollout (agent files not modified), but they have explicit denylists in `role-contracts.md`

### US-6: Violation Visibility and Response
**As a** Smart Ralph engineer operating the execution engine
**I want to** receive structured violation information when the state integrity hook detects an unauthorized modification and have documented response behavior
**So that** I (the human operator) can log the violation, assess severity, and decide whether to escalate

**Acceptance Criteria:**
- [ ] AC-6.1: Violation log output (to stderr) includes: timestamp, affected field, field owner, ownership baseline (who owns this field), severity
- [ ] AC-6.2: In Phase 1, agent identity is reported as "unknown" in violation logs (stop-watcher cannot determine agent identity from state alone — fundamental Phase 1 limitation)
- [ ] AC-6.3: Violation is logged to stderr only (stop-watcher is read-only; no write to .progress.md from hook to avoid race condition with concurrent coordinator writes)
- [ ] AC-6.4: Phase 1 violation response: log warning to stderr, continue execution (the coordinator reads this output and may manually investigate)

### US-7: Cross-Spec Boundary Consistency
**As a** Smart Ralph engineer running sequential specs (engine-roadmap-epic Specs 3→4→5→6→7)
**I want to** ensure that spec-wide changes to state fields or agent files in one spec do not break the role boundaries established by a prior spec
**So that** each spec in the chain can be executed without manual boundary reconciliation

**Acceptance Criteria:**
- [ ] AC-7.1: When Spec N modifies state fields (adds/removes/changes ownership), role-contracts.md is updated to reflect new ownership as part of Spec N's implementation
- [ ] AC-7.2: The role-contracts.md "Adding a New Agent" checklist includes a step to verify that new agents do not conflict with existing spec file modifications from prior specs
- [ ] AC-7.3: Dependencies section in role-contracts.md explicitly lists all specs that modify the same files with their section boundaries (spec-executor.md → Specs 3/6/7, external-reviewer.md → Specs 3/6, .ralph-state.json → all specs)

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | Create `references/role-contracts.md` with access matrix for all 10 agents | High | AC-1.1 through AC-1.7 |
| FR-2 | Append DO NOT edit sections to 4 target agent files (spec-executor, external-reviewer, qa-engineer, spec-reviewer) | High | AC-2.1 through AC-2.6 |
| FR-3 | Document field ownership in a machine-parseable baseline file (`references/.ralph-field-baseline.json`) consumable by the validation hook, captured automatically at spec initialization by `load-spec-context.sh`, not overwritten on re-run | High | AC-3.1 through AC-3.3 |
| FR-4 | Extend `stop-watcher.sh` with field-level validation against baseline (fd 202 flock with retry loop for jq+mv race mitigation, 3 distinct scenario logging for schema drift, graceful skip on missing baseline) | High | AC-3.4 through AC-3.9 |
| FR-5 | Document violation response behavior for Phase 1 (log-and-continue to stderr); include structured log format with timestamp/field/owner/severity | Medium | AC-6.1 through AC-6.4 |
| FR-6 | Add "Adding a New Agent" checklist to role-contracts.md with 4 explicit steps and template code blocks; cross-reference from channel-map.md | Medium | AC-4.1 through AC-4.3 |
| FR-7 | Document boundaries for all 6 non-execution agents in role-contracts.md | Medium | AC-5.1 through AC-5.5 |
| FR-8 | Maintain cross-spec boundary consistency through dependency tracking and onboarding checklist | Medium | AC-7.1 through AC-7.3 |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Phased enforcement clarity | All phases documented | Phase 1, 2, 3 clearly distinguished with separate ACs |
| NFR-2 | Backward compatibility with existing specs | Baseline creation is automatic with graceful degradation | Graceful fallback when baseline missing; existing specs (created before this spec's deployment) will never have mechanical enforcement — a known coverage gap |
| NFR-3 | Schema drift tolerance | No false positives | Skip fields absent from current state file |
| NFR-4 | Lock contention avoidance | Dedicated fd for baseline validation | Different fd from 200 (chat.md) and 201 (tasks.md) |
| NFR-5 | Read boundary advisory | Clearly marked in agent prompts | Severity ratings (HIGH/MEDIUM/LOW) documented per AC-2.6; advisory target is the agent (no mechanical prevention possible via prompts) |

## Glossary
- **Role Contract**: A declarative document (`references/role-contracts.md`) specifying which agents can read/write which files and state fields
- **DO NOT List**: Explicit denylist of files a specific agent must not modify, appended to agent prompt files
- **Field Ownership**: Attribution of individual `.ralph-state.json` fields to specific agents (e.g., `chat.executor.lastReadLine` owned by `spec-executor`)
- **Baseline File**: `references/.ralph-field-baseline.json` (in spec's references directory) storing field ownership mapping used by the state integrity hook
- **Phase 1**: Prompt-based enforcement only — DO NOT lists in agent files, no mechanical verification
- **Phase 2**: Post-facto mechanical enforcement — stop-watcher validates field writes after the fact
- **Phase 3**: Pre-emptive mechanical enforcement — PreToolUse hook blocks unauthorized writes before execution
- **Access Matrix**: Tabular mapping of agents (rows) to files/fields (columns) with read/write permissions
- **channel-map.md**: Existing reference documenting inter-agent channel protocol (locking, signals, writer/reader ownership)
- **Accidental Overreach**: Agent writes to a file/field it has no business touching, due to misunderstanding constraints
- **Systematic Boundary Creep**: Agent gradually expands its scope beyond intended boundaries across multiple sessions

## Out of Scope
- PreToolUse hook implementation (Phase 3 — deferred to a future spec)
- Programmatic DO NOT list generation from role-contracts.md (drift mitigation — future candidate)
- JSON schema update to add missing 9 fields (`external_unmarks`, `awaitingApproval`, `failedStory`, `originTaskIndex`, `repairIteration`, `maxFixTaskDepth`, `chat.reviewer.lastReadLine`, `commitSpec`, `specName`) — noted as a known gap but separate concern
- Rollback of unauthorized writes (detect and log only in Phase 1/2; rollback is a Phase 3 concern)
- Lock file cleanup or management (existing flock mechanism handles this)
- Agent identity resolution in PreToolUse hooks (agent identity not available in hook input)
- Per-task progress files (`.progress-task-*.md`) — explicitly handled in role-contracts.md access matrix as spec-executor write targets (dynamic naming), but no special mechanism beyond the matrix
- Template file access restrictions — templates/ directory is read-only for execution agents per existing convention; documented in role-contracts.md
- Migration path for existing specs — existing specs created before this spec's deployment will not have baseline files and will rely on Phase 1 (prompt-only) enforcement. No migration script provided; this is a known coverage gap

## Dependencies
- **channel-map.md**: Role contracts should be complementary, not redundant. role-contracts.md extends channel-map.md to cover spec artifact files that channel-map.md does not address
- **references/phase-rules.md**: Phase-based separation already exists; role boundaries are orthogonal to phase-based directory separation
- **engine-state-hardening** (Spec 1): Modifies `.ralph-state.json` field ownership — role-boundaries hook should coordinate to avoid double-reporting
- **engine-roadmap-epic Specs 6 and 7**: Depend on Spec 3's modifications to `spec-executor.md` and `external-reviewer.md` — must validate proposed changes against role-contracts.md before implementation

## Success Criteria
- All 10 agents have documented read/write permissions in `references/role-contracts.md`
- All 4 execution agent files have explicit DO NOT sections referencing role-contracts.md
- State integrity hook (Phase 2) correctly **detects and logs** (not prevents) unauthorized field modifications
- Adding a new agent requires no guesswork — checklist is explicit and actionable with template code blocks
- Zero false positives from the field-level validation when running new specs (graceful fallback when baseline missing for existing specs)
- Coordinator receives structured violation information (field, owner, severity) — agent identity reported as "unknown" (Phase 1 limitation)
- Cross-spec dependencies on shared agent files are explicitly documented in role-contracts.md
- Known gap documented: existing specs without baselines rely on Phase 1 only

## Verification Contract

**Project type**: `fullstack` — Smart Ralph is a Claude Code plugin with both file-system operations (agent prompt files, spec artifacts) and shell-script execution (hooks, stop-watcher).

**Entry points**:
- `references/role-contracts.md` — new file, created once per spec
- `references/.ralph-field-baseline.json` — new file, auto-created at spec start (in spec's references directory)
- `agents/spec-executor.md` — appended DO NOT section before `<bookend>`
- `agents/external-reviewer.md` — appended DO NOT section before "Never Do" guidance section
- `agents/qa-engineer.md` — appended DO NOT section before Execution Flow section
- `agents/spec-reviewer.md` — appended DO NOT section after Core Philosophy mandatory block
- `stop-watcher.sh` — extended with field-level validation logic

**Observable signals**:
- PASS: `references/role-contracts.md` exists with frontmatter, 10 agent rows, and channel map reference
- PASS: `grep -q "references/role-contracts.md"` succeeds in all 4 target agent files within their new DO NOT sections
- PASS: `jq empty references/.ralph-field-baseline.json` exits 0 (valid JSON) after spec initialization
- PASS: `jq '.chat.executor.lastReadLine' references/.ralph-field-baseline.json` returns `"spec-executor"` (ownership mapping exists)
- PASS: `stop-watcher.sh` logs `[ralph-specum] BOUNDARY_VIOLATION` to stderr when unauthorized field modification is detected
- PASS: `grep -c "spec-executor\|external-reviewer\|qa-engineer\|spec-reviewer\|architect-reviewer\|product-manager\|research-analyst\|task-planner\|refactor-specialist\|triage-analyst" references/role-contracts.md` returns 10 (all agents in matrix)
- FAIL: Unauthorized field modification logged but execution halted (should be log-and-continue in Phase 1)
- FAIL: Baseline missing but stop-watcher crashes instead of graceful skip
- FAIL: `references/role-contracts.md` missing "Relationship to Channel Map" section
- FAIL: stop-watcher writes to .progress.md during violation logging (hook must be read-only; log to stderr only)

**Hard invariants**:
- stop-watcher must NOT modify `.ralph-state.json` — read-only during validation
- Field-level validation must NOT interfere with existing stop-watcher phases (ALL_TASKS_COMPLETE, repair loop, quick mode, taskIndex cross-check)
- Baseline validation must use a file descriptor different from 200 (chat.md.lock) and 201 (tasks.md.lock)

**Seed data**:
- A spec directory with `.ralph-state.json` must exist for baseline capture to work
- At least one existing state file for regression testing (e.g., `prompt-diet-refactor` or `ralph-quality-improvements`)
- No special config flags or environment variables required for Phase 1/2

**Dependency map**:
- `channel-map.md` — complementary contract; role-contracts.md references it
- `stop-watcher.sh` — host of Phase 2 validation logic
- `spec.schema.json` — known gap: schema missing 9 fields (documented, not fixed in this spec)
- Specs 6+7 (engine-roadmap-epic) — depend on this spec's agent file modifications

**Escalate if**:
- Baseline capture would modify an existing spec's `.ralph-state.json` in a way that corrupts its execution state (baseline is read-only capture)
- A field in role-contracts.md is genuinely owned by multiple agents with concurrent write access — requires design decision on lock strategy
- The user wants Phase 3 (PreToolUse write-block) implemented — requires different architecture (hook input modification for agent identity)
- Adding DO NOT sections to agent files that use different structural conventions (triage-analyst has ~95 lines with numbered sections, not XML tags) — requires judgment on placement
- Rollback of unauthorized writes is requested — Phase 1 is detect-and-log only; rollback requires additional design

## Unresolved Questions
- Should role-contracts.md use glob patterns (e.g., `specs/**`) for broader coverage, or explicit paths for precision? (Recommendation: explicit paths, globs as future candidate)
- What severity rating should be assigned to each read boundary type? **RESOLVED**: HIGH = cross-spec state contamination, MEDIUM = reading uncommitted agent context, LOW = reading public reference files (defined in AC-2.6)
- Should spec-reviewer need an explicit DO NOT list given it already states "NEVER modify any files"? **RESOLVED**: yes, explicit list for consistency and role-contracts.md reference (AC-2.4)
- **Channel-map.md update**: The existing channel-map.md references outdated `.ralph-state.json` ownership (claims only `chat.reviewer.*` and `external_unmarks` are exceptions, missing `awaitingApproval` writes by planning agents). FR-1 implicitly covers updating this reference since role-contracts.md AC-1.6 requires a "Relationship to Channel Map" section. An explicit task to update channel-map.md will be added in the tasks spec.

## Next Steps
1. Approve requirements — user reviews and signs off on requirements.md
2. Create `references/role-contracts.md` with full access matrix
3. Append DO NOT sections to all 4 target agent files
4. Implement baseline capture and stop-watcher extension (Phase 2)
5. Add "Adding a New Agent" checklist to role-contracts.md
6. Append learnings to `.progress.md`
