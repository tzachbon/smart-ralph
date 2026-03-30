# Tasks: cli-support-gsd-v2

## Overview

Total tasks: 66

**POC-first workflow** (GREENFIELD):
1. Phase 1: Make It Work (POC) - Validate idea end-to-end
2. Phase 2: Refactoring - Clean up code structure
3. Phase 3: Testing - Add unit/integration/e2e tests
4. Phase 4: Quality Gates - Local quality checks and PR creation
5. Phase 5: PR Lifecycle - Autonomous CI monitoring, review resolution, final validation

## Completion Criteria (Autonomous Execution Standard)

This spec is not complete until ALL criteria are met:

✅ **Zero Regressions**: All existing tests pass (no broken functionality)
✅ **Modular & Reusable**: Code follows project patterns, properly abstracted
✅ **Real-World Validation**: Feature tested in actual environment (not just unit tests)
✅ **All Tests Pass**: Unit, integration, E2E all green
✅ **CI Green**: All CI checks passing
✅ **PR Ready**: Pull request created, reviewed, approved
✅ **Review Comments Resolved**: All code review feedback addressed

> **Quality Checkpoints**: Intermediate quality gate checks are inserted every 2-3 tasks to catch issues early.

## Phase 1: Make It Work (POC)

### Scaffolding & Types (1.1-1.5)

- [x] 1.1 [P] Scaffold packages/cli with package.json, tsconfig, tsup config
  - **Do**:
    1. Create `packages/cli/package.json` with name `smart-ralph-cli`, bin entry `ralph` pointing to `dist/cli.js`, dependencies (commander@^12, @anthropic-ai/sdk@^0.39, zod@^3, chalk@^5, ora@^8), devDependencies (tsup@^8, typescript@^5, vitest@^2)
    2. Create `packages/cli/tsconfig.json` targeting ES2022, module NodeNext, strict mode, outDir dist
    3. Create `packages/cli/tsup.config.ts` with entry `src/cli.ts`, format esm, target node18, banner with shebang `#!/usr/bin/env node`
  - **Files**: `packages/cli/package.json`, `packages/cli/tsconfig.json`, `packages/cli/tsup.config.ts`
  - **Done when**: `cd packages/cli && npx tsc --noEmit` exits 0 (after types are added)
  - **Verify**: `ls packages/cli/package.json packages/cli/tsconfig.json packages/cli/tsup.config.ts`
  - **Commit**: `feat(cli): scaffold package with build config`
  - _Requirements: FR-1, US-1_
  - _Design: File Structure_

- [x] 1.2 [P] Define all shared TypeScript types
  - **Do**:
    1. Create `packages/cli/src/types/index.ts` with interfaces: `Provider`, `AgentContext`, `RunAgentOptions`, `AgentResult`, `SpecState`, `RalphConfig`, `ParsedTask`, `ParallelGroup`, `TaskResult`, `FixTaskEntry`, `ModificationEntry`, `RelatedSpec`
    2. Export all types from the file
  - **Files**: `packages/cli/src/types/index.ts`
  - **Done when**: All interfaces from design section 5 are defined and exported
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): define shared TypeScript types`
  - _Requirements: FR-4, FR-8_
  - _Design: Key Interfaces_

- [x] 1.3 Create error classes
  - **Do**:
    1. Create `packages/cli/src/lib/errors.ts` with `RalphError` (message, suggestion, exitCode), `ConfigError`, `SpecNotFoundError`, `ProviderError`, `TaskFailedError`
    2. Each subclass sets appropriate default suggestion and exit code per design section 9
  - **Files**: `packages/cli/src/lib/errors.ts`
  - **Done when**: All 5 error classes exist with proper constructor signatures
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): add error classes`
  - _Requirements: FR-14, US-15_
  - _Design: Error Handling Strategy_

- [x] 1.4 Create output utilities
  - **Do**:
    1. Create `packages/cli/src/lib/output.ts` with functions: `info(msg)` (cyan `>`), `success(msg)` (green `+`), `warn(msg)` (yellow `!`), `error(msg)` (red `-`), `debug(msg)` (only when `--debug`)
    2. Add `isJsonMode()` and `isDebugMode()` checks reading from a module-level state set by CLI entry
    3. Use chalk for colors, detect TTY with `process.stdout.isTTY`
  - **Files**: `packages/cli/src/lib/output.ts`
  - **Done when**: All 5 output functions exist with correct prefix characters and color
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): add output utilities with prefix system`
  - _Requirements: FR-13, US-15_
  - _Design: User-Facing Message Format_

- [x] 1.5 [VERIFY] Quality check: type check passes
  - **Do**: Run type check on the scaffolded package
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Done when**: Zero type errors
  - **Commit**: `chore(cli): pass quality checkpoint` (only if fixes needed)

### Monorepo Integration (1.6)

- [x] 1.6 Register packages/cli in monorepo and update CI
  - **Do**:
    1. Check if root `package.json` uses workspaces; if so, add `packages/cli` to the workspaces array
    2. Update root CI config (`.github/workflows/*.yml` or equivalent) to include `packages/cli` in the build/test matrix
    3. Run existing plugin tests (`npm test` or equivalent at repo root) to confirm the new package does not break them
    4. Commit any CI/workspace changes
  - **Files**: `package.json` (root), `.github/workflows/*.yml` (or equivalent CI config)
  - **Done when**: Root CI config includes `packages/cli`; existing plugin tests still pass
  - **Verify**: `npm test` (or equivalent) at repo root exits 0
  - **Commit**: `chore: register packages/cli in monorepo workspaces and CI`
  - _Requirements: FR-1_
  - _Design: File Structure_

### Config & Spec Manager (1.7-1.11)

- [x] 1.7 Implement config resolver
  - **Do**:
    1. Create `packages/cli/src/lib/config.ts` with `resolveConfig()` that checks env vars (`RALPH_PROVIDER`, `RALPH_MODEL`) then `.ralph/config.json` then `~/.ralph/config.json`
    2. Add `writeConfig(configPath, config)` for `ralph init`
    3. Add `getApiKey(config)` that reads `process.env[config.apiKeyEnvVar]`
    4. Use zod schema to validate config shape
  - **Files**: `packages/cli/src/lib/config.ts`
  - **Done when**: `resolveConfig()` returns `RalphConfig | null` with correct precedence order
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): implement config resolver with env/project/global precedence`
  - _Requirements: FR-5, FR-12, US-2, US-3_
  - _Design: Config Resolver_

- [x] 1.8 Implement spec manager core (create, read, write, active spec)
  - **Do**:
    1. Create `packages/cli/src/lib/spec-manager.ts` with `createSpec(name, goal)` that scaffolds `specs/<name>/` with stub files
    2. Add `getActiveSpec()` reading `.current-spec`, `setActiveSpec(name)` writing it
    3. Add `readSpecFile(specPath, phase)` and `writeSpecFile(specPath, phase, content)`
    4. Add spec name validation with regex `/^[a-z0-9][a-z0-9\-_]*$/`
  - **Files**: `packages/cli/src/lib/spec-manager.ts`
  - **Done when**: Can create a spec directory, read/write phase files, get/set active spec
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): implement spec manager core operations`
  - _Requirements: FR-3, FR-7, US-4, US-5_
  - _Design: Spec Manager_

- [x] 1.9 Add state management to spec manager
  - **Do**:
    1. Add `readState(specPath)` that parses `.ralph-state.json` with zod validation and default values
    2. Add `writeState(specPath, state)` with atomic write (temp file + rename)
    3. Add `deleteState(specPath)` for cancel
  - **Files**: `packages/cli/src/lib/spec-manager.ts`
  - **Done when**: State read/write/delete works with atomic writes and zod validation
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): add state management with atomic writes`
  - _Requirements: FR-8, FR-11, US-12_
  - _Design: State Management_

- [x] 1.10 Implement task parser
  - **Do**:
    1. Create `packages/cli/src/lib/task-parser.ts` with `parseTasks(content: string): ParsedTask[]`
    2. Parse `- [ ]` / `- [x]` checkboxes, extract ID, title, tags (`[P]`, `[VERIFY]`, `[RED]`, `[GREEN]`, `[YELLOW]`)
    3. Parse body fields: Do, Files, Done when, Verify, Commit
    4. Add `markTaskComplete(content, index)` that flips `[ ]` to `[x]` and returns updated content
    5. Add `detectParallelGroups(tasks)` that finds consecutive `[P]` tasks (max 5 per group)
  - **Files**: `packages/cli/src/lib/task-parser.ts`
  - **Done when**: Parser extracts all fields from the task format defined in design section 7
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): implement task parser with parallel group detection`
  - _Requirements: FR-9, US-12_
  - _Design: Task Parsing_

- [ ] 1.11 [VERIFY] Quality check: type check passes
  - **Do**: Run type check on all lib modules
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Done when**: Zero type errors
  - **Commit**: `chore(cli): pass quality checkpoint` (only if fixes needed)

### Provider Layer (1.12-1.15)

- [ ] 1.12 Define provider interface and factory
  - **Do**:
    1. Create `packages/cli/src/providers/interface.ts` re-exporting `Provider`, `AgentContext`, `AgentResult`, `RunAgentOptions` from types (or defining them here if cleaner)
    2. Create `packages/cli/src/providers/factory.ts` with `createProvider(config: RalphConfig): Provider` using a switch on `config.provider`
  - **Files**: `packages/cli/src/providers/interface.ts`, `packages/cli/src/providers/factory.ts`
  - **Done when**: Factory returns a provider instance for 'claude' and throws `RalphError` for unknown providers
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): add provider interface and factory`
  - _Requirements: FR-4_
  - _Design: Provider Abstraction Design_

- [ ] 1.13 Implement Claude provider
  - **Do**:
    1. Create `packages/cli/src/providers/claude.ts` implementing `Provider` interface
    2. Constructor reads API key from env var, creates `Anthropic` client
    3. `runAgent()` calls `client.messages.stream()`, invokes `onStream` callback per chunk, collects full response
    4. Returns `AgentResult` with content, token usage, stop reason
  - **Files**: `packages/cli/src/providers/claude.ts`
  - **Done when**: Claude provider streams responses and returns structured results
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): implement Claude provider with streaming`
  - _Requirements: FR-4, US-8_
  - _Design: Claude Provider Implementation_

- [ ] 1.14 Bundle agent prompts
  - **Do**:
    1. Create `packages/cli/src/agents/research-analyst.ts` exporting the system prompt string
    2. Create `packages/cli/src/agents/product-manager.ts` exporting the system prompt string
    3. Create `packages/cli/src/agents/architect-reviewer.ts` exporting the system prompt string
    4. Create `packages/cli/src/agents/task-planner.ts` exporting the system prompt string
  - **Files**: `packages/cli/src/agents/research-analyst.ts`, `packages/cli/src/agents/product-manager.ts`, `packages/cli/src/agents/architect-reviewer.ts`, `packages/cli/src/agents/task-planner.ts`
  - **Done when**: Each file exports a `prompt` string constant with the agent's system prompt (extracted from plugin agent markdown, frontmatter stripped)
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): bundle agent system prompts`
  - _Requirements: FR-6_
  - _Design: Bundled Agent Prompts_

- [ ] 1.15 [P] Create spec-executor prompt and agent prompt registry
  - **Do**:
    1. Create `packages/cli/src/agents/spec-executor.ts` exporting the spec-executor system prompt
    2. Create `packages/cli/src/agents/index.ts` with `getPrompt(agentName: string): string` that returns the prompt for the given agent name
  - **Files**: `packages/cli/src/agents/spec-executor.ts`, `packages/cli/src/agents/index.ts`
  - **Done when**: `getPrompt('research-analyst')` returns the research analyst prompt string
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): add spec-executor prompt and agent registry`
  - _Requirements: FR-6_
  - _Design: Bundled Agent Prompts_

### Agent Runner (1.16-1.17)

- [ ] 1.16 Implement agent runner
  - **Do**:
    1. Create `packages/cli/src/lib/agent-runner.ts` with `runAgent(agentName, specPath, config, options?)`
    2. Load system prompt via `getPrompt(agentName)`
    3. Build `AgentContext` from spec files on disk (read research.md, requirements.md, design.md, tasks.md, .progress.md)
    4. Call `provider.runAgent()` with streaming callback that writes to stdout
    5. Return `AgentResult`
  - **Files**: `packages/cli/src/lib/agent-runner.ts`
  - **Done when**: Agent runner loads prompts, builds context from spec files, calls provider, streams output
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): implement agent runner with prompt loading and streaming`
  - _Requirements: FR-6, US-8_
  - _Design: Agent Runner_

- [ ] 1.17 [VERIFY] Quality check: type check passes
  - **Do**: Run type check on all modules so far
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Done when**: Zero type errors
  - **Commit**: `chore(cli): pass quality checkpoint` (only if fixes needed)

### CLI Entry & Simple Commands (1.18-1.25)

- [ ] 1.18 Create CLI entry point with Commander.js
  - **Do**:
    1. Create `packages/cli/src/cli.ts` with Commander program, version from package.json, global options (`--debug`, `--no-color`, `--json`)
    2. Register all subcommands (lazy-loaded)
    3. Add top-level error handler that catches unhandled rejections, formats with `output.error()`, sets exit code
  - **Files**: `packages/cli/src/cli.ts`
  - **Done when**: `ralph --help` would list all subcommands, `ralph --version` would print version
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): create CLI entry point with Commander.js`
  - _Requirements: FR-1, FR-2, FR-14, US-1_
  - _Design: CLI Entry_

- [ ] 1.19 Implement `ralph init` command
  - **Do**:
    1. Create `packages/cli/src/commands/init.ts` with `--global` flag
    2. Writes `.ralph/config.json` (or `~/.ralph/config.json` with `--global`) with default values: provider `claude`, model `claude-sonnet-4-20250514`, apiKeyEnvVar `ANTHROPIC_API_KEY`
    3. Creates `specs/` directory if it doesn't exist
    4. Prints success message with next steps
  - **Files**: `packages/cli/src/commands/init.ts`
  - **Done when**: Running init creates config file and specs directory
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): implement ralph init command`
  - _Requirements: FR-12, US-2_
  - _Design: Command Handlers_

- [ ] 1.20 Implement `ralph new` command
  - **Do**:
    1. Create `packages/cli/src/commands/new.ts` accepting `<name>` and `"<goal>"` arguments, `--force` option
    2. Validate name with spec manager, create spec directory with stubs
    3. Set as active spec
    4. Print success message with next command suggestion
  - **Files**: `packages/cli/src/commands/new.ts`
  - **Done when**: `ralph new my-feature "Build X"` creates spec dir and sets it active
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): implement ralph new command`
  - _Requirements: FR-3, FR-7, US-4_
  - _Design: Command Handlers_

- [ ] 1.21 [P] Implement `ralph switch` command
  - **Do**:
    1. Create `packages/cli/src/commands/switch.ts` accepting `<name>` argument
    2. Verify spec exists, call `setActiveSpec(name)`
    3. Print confirmation
  - **Files**: `packages/cli/src/commands/switch.ts`
  - **Done when**: `ralph switch other-spec` updates `.current-spec`
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): implement ralph switch command`
  - _Requirements: US-5_
  - _Design: Command Handlers_

- [ ] 1.22 [P] Implement `ralph status` command
  - **Do**:
    1. Create `packages/cli/src/commands/status.ts` accepting optional `[name]`, `--json` flag
    2. Read active spec or named spec, read state file if exists, parse tasks for completion count
    3. Print phase, task progress (X/Y), completion percentage
    4. With `--json`: output `{ name, phase, taskIndex, totalTasks, completionPercent }` to stdout
  - **Files**: `packages/cli/src/commands/status.ts`
  - **Done when**: `ralph status` prints human-readable status, `ralph status --json` prints valid JSON
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): implement ralph status command with JSON output`
  - _Requirements: FR-13, US-5, US-6_
  - _Design: Command Handlers_

- [ ] 1.23 [P] Implement `ralph cancel` command
  - **Do**:
    1. Create `packages/cli/src/commands/cancel.ts` accepting optional `[name]`
    2. Delete `.ralph-state.json` for the spec
    3. Print confirmation
  - **Files**: `packages/cli/src/commands/cancel.ts`
  - **Done when**: `ralph cancel` removes state file, `ralph status` reflects no active execution
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): implement ralph cancel command`
  - _Requirements: US-7_
  - _Design: Command Handlers_

- [ ] 1.24 [P] Implement `ralph doctor` command
  - **Do**:
    1. Create `packages/cli/src/commands/doctor.ts`
    2. Check: config file or env vars present, API key env var set, Node.js >= 18, `specs/` directory exists
    3. Print pass/fail per check with description
    4. Exit 0 only if all pass, exit 1 otherwise
  - **Files**: `packages/cli/src/commands/doctor.ts`
  - **Done when**: `ralph doctor` prints checklist and exits with correct code
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): implement ralph doctor command`
  - _Requirements: US-2, US-14_
  - _Design: Command Handlers_

- [ ] 1.25 [VERIFY] Quality check: type check passes
  - **Do**: Run type check on full codebase
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Done when**: Zero type errors
  - **Commit**: `chore(cli): pass quality checkpoint` (only if fixes needed)

### AI-Powered Commands (1.26-1.30)

- [ ] 1.26 Implement `ralph research` command
  - **Do**:
    1. Create `packages/cli/src/commands/research.ts` accepting optional `[name]`, `--force` flag
    2. Resolve config, create provider, call agent runner with `research-analyst`
    3. Write result to `specs/<name>/research.md`
    4. Prompt before overwriting existing file (skip with `--force`)
  - **Files**: `packages/cli/src/commands/research.ts`
  - **Done when**: Command streams AI output and writes research.md
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): implement ralph research command`
  - _Requirements: US-8_
  - _Design: Command Handlers_

- [ ] 1.27 [P] Implement `ralph requirements` command
  - **Do**:
    1. Create `packages/cli/src/commands/requirements.ts` accepting optional `[name]`, `--force` flag
    2. Resolve config, create provider, call agent runner with `product-manager`
    3. Write result to `specs/<name>/requirements.md`
  - **Files**: `packages/cli/src/commands/requirements.ts`
  - **Done when**: Command streams AI output and writes requirements.md
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): implement ralph requirements command`
  - _Requirements: US-9_
  - _Design: Command Handlers_

- [ ] 1.28 [P] Implement `ralph design` command
  - **Do**:
    1. Create `packages/cli/src/commands/design.ts` accepting optional `[name]`, `--force` flag
    2. Resolve config, create provider, call agent runner with `architect-reviewer`
    3. Write result to `specs/<name>/design.md`
  - **Files**: `packages/cli/src/commands/design.ts`
  - **Done when**: Command streams AI output and writes design.md
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): implement ralph design command`
  - _Requirements: US-10_
  - _Design: Command Handlers_

- [ ] 1.29 [P] Implement `ralph tasks` command
  - **Do**:
    1. Create `packages/cli/src/commands/tasks.ts` accepting optional `[name]`, `--tasks-size coarse|fine`, `--force` flag
    2. Resolve config, create provider, call agent runner with `task-planner`
    3. Pass tasks-size option to agent context
    4. Write result to `specs/<name>/tasks.md`
  - **Files**: `packages/cli/src/commands/tasks.ts`
  - **Done when**: Command streams AI output and writes tasks.md with granularity option
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): implement ralph tasks command with granularity option`
  - _Requirements: US-11_
  - _Design: Command Handlers_

- [ ] 1.30 [VERIFY] Quality check: type check passes
  - **Do**: Run type check on full codebase
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Done when**: Zero type errors
  - **Commit**: `chore(cli): pass quality checkpoint` (only if fixes needed)

### Execution Loop & Run Command (1.31-1.37)

- [ ] 1.31 Implement execution loop core
  - **Do**:
    1. Create `packages/cli/src/lib/execution-loop.ts` with `executeSpec(specPath, config, options)`
    2. Parse tasks from tasks.md, find first incomplete task
    3. Main while loop: delegate task to agent runner with spec-executor prompt, check for TASK_COMPLETE signal
    4. Update state after each task (taskIndex, globalIteration)
    5. Mark completed tasks in tasks.md via `markTaskComplete`
  - **Files**: `packages/cli/src/lib/execution-loop.ts`
  - **Done when**: Loop advances through tasks, updates state, marks completions
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): implement execution loop core`
  - _Requirements: FR-10, US-12_
  - _Design: Execution Loop Design_

- [ ] 1.32 Add retry and failure handling to execution loop
  - **Do**:
    1. Add retry logic: increment `taskIteration`, retry up to 3 times on failure
    2. On max retries: exit with `TaskFailedError` (or decompose if recovery mode on)
    3. Add decompose-on-failure: generate fix subtasks, insert into tasks.md, update `fixTaskMap`
    4. Write failure details to `.progress.md`
  - **Files**: `packages/cli/src/lib/execution-loop.ts`
  - **Done when**: Failed tasks retry 3 times, then decompose or exit with error
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): add retry and decompose-on-failure to execution loop`
  - _Requirements: FR-10, US-12_
  - _Design: Retry and Decompose_

- [ ] 1.33 Add parallel task execution to execution loop
  - **Do**:
    1. Detect consecutive `[P]` tasks using `detectParallelGroups`
    2. Run group tasks concurrently via `Promise.all`, each with its own agent runner call
    3. Track individual results in `taskResults`
    4. Retry only failed tasks within a group
    5. Advance past group only when all tasks succeed
  - **Files**: `packages/cli/src/lib/execution-loop.ts`
  - **Done when**: Parallel task groups execute concurrently and handle individual failures
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): add parallel task execution to loop`
  - _Requirements: FR-10, US-12_
  - _Design: Parallel Execution_

- [ ] 1.34 Implement `ralph run` command
  - **Do**:
    1. Create `packages/cli/src/commands/run.ts` accepting optional `[name]`, `--headless` flag
    2. Resolve config, read or create state, call `executeSpec()`
    3. In headless mode: skip all prompts, exit 0 on complete, non-zero on failure
    4. On resume: check existing state, prompt to resume or restart (skip prompt in headless)
    5. On completion: print summary, delete state file, exit 0
  - **Files**: `packages/cli/src/commands/run.ts`
  - **Done when**: `ralph run` executes tasks sequentially with state persistence and resume
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `feat(cli): implement ralph run command with headless mode`
  - _Requirements: FR-10, FR-11, US-12, US-13_
  - _Design: Command Handlers_

- [ ] 1.35 [VERIFY] Quality check: type check and build
  - **Do**: Run type check and attempt a build
  - **Verify**: `cd packages/cli && npx tsc --noEmit && npx tsup`
  - **Done when**: Zero type errors and build produces `dist/cli.js`
  - **Commit**: `chore(cli): pass quality checkpoint` (only if fixes needed)

### POC Checkpoint (1.36-1.37)

- [ ] 1.36 Install dependencies and verify build
  - **Do**:
    1. Run `cd packages/cli && npm install`
    2. Run `npx tsup` to produce the bundled binary
    3. Verify `dist/cli.js` exists and has shebang
    4. Run `node dist/cli.js --help` to verify it prints help
    5. Run `node dist/cli.js --version` to verify version output
  - **Files**: `packages/cli/dist/cli.js` (build output)
  - **Done when**: Built binary prints help and version without errors
  - **Verify**: `cd packages/cli && node dist/cli.js --help && node dist/cli.js --version`
  - **Commit**: `feat(cli): verify build produces working binary`

- [ ] 1.37 [VERIFY] POC Checkpoint: end-to-end spec lifecycle
  - **Do**:
    1. Create temp directory, set as working dir
    2. Run `node <path>/dist/cli.js init` and verify `.ralph/config.json` created
    3. Run `node <path>/dist/cli.js new test-spec "Hello world"` and verify `specs/test-spec/` created with stubs
    4. Run `node <path>/dist/cli.js status` and verify it prints spec info
    5. Run `node <path>/dist/cli.js status --json` and verify valid JSON output
    6. Run `node <path>/dist/cli.js doctor` and verify it runs checks
    7. Run `node <path>/dist/cli.js cancel test-spec` and verify state cleanup
    8. Clean up temp directory
  - **Verify**: All 6 commands exit 0 with expected output
  - **Done when**: Full non-AI lifecycle works: init, new, status, status --json, doctor, cancel
  - **Commit**: `feat(cli): complete POC - spec lifecycle verified`

## Phase 2: Refactoring

- [ ] 2.1 Add input validation and edge case handling to spec manager
  - **Do**:
    1. Add validation for duplicate spec names in `createSpec` (fail unless `--force`)
    2. Add validation for missing specs directory (auto-create or clear error)
    3. Handle corrupt `.ralph-state.json` (log warning, reset to defaults)
    4. Handle missing `.current-spec` (return null, don't throw)
  - **Files**: `packages/cli/src/lib/spec-manager.ts`
  - **Done when**: All edge cases return useful errors instead of stack traces
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `refactor(cli): add input validation to spec manager`
  - _Requirements: FR-3, US-15_
  - _Design: Spec Manager_

- [ ] 2.2 Add proper error handling to all commands
  - **Do**:
    1. Wrap each command handler in try/catch that maps to appropriate RalphError subclass
    2. AI commands: catch provider errors, wrap as `ProviderError` with suggestion
    3. File commands: catch ENOENT/EACCES, wrap as `RalphError` with path info
    4. Config commands: catch missing config, wrap as `ConfigError`
  - **Files**: `packages/cli/src/commands/init.ts`, `packages/cli/src/commands/new.ts`, `packages/cli/src/commands/research.ts`, `packages/cli/src/commands/run.ts`
  - **Done when**: Every command produces a user-friendly error message with suggestion for common failure modes
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `refactor(cli): add structured error handling to commands`
  - _Requirements: FR-14, US-15_
  - _Design: Error Handling Strategy_

- [ ] 2.3 [VERIFY] Quality check: type check passes
  - **Do**: Run type check
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Done when**: Zero type errors
  - **Commit**: `chore(cli): pass quality checkpoint` (only if fixes needed)
  - _Requirements: FR-14, US-15_
  - _Design: Error Handling Strategy_

- [ ] 2.4 Extract shared command helpers
  - **Do**:
    1. Extract common patterns from command files into `packages/cli/src/commands/_helpers.ts`: `resolveSpecName(nameArg)` (falls back to active spec), `requireConfig()` (resolves config or throws ConfigError), `confirmOverwrite(filePath, force)` (prompt or skip)
    2. Update all command files to use shared helpers instead of duplicated logic
  - **Files**: `packages/cli/src/commands/_helpers.ts`, all command files that duplicate these patterns
  - **Done when**: No duplicated config resolution or spec name resolution across commands
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `refactor(cli): extract shared command helpers`
  - _Requirements: FR-2, FR-5_
  - _Design: Command Handlers_

- [ ] 2.5 Clean up hardcoded values and add proper defaults
  - **Do**:
    1. Move hardcoded defaults (model name, max retries, max parallel tasks) to a `packages/cli/src/lib/constants.ts` file
    2. Replace all magic numbers/strings in execution-loop.ts, config.ts, and command files
    3. Document each constant with a brief comment
  - **Files**: `packages/cli/src/lib/constants.ts`, `packages/cli/src/lib/execution-loop.ts`, `packages/cli/src/lib/config.ts`
  - **Done when**: No hardcoded magic values remain in source files
  - **Verify**: `cd packages/cli && npx tsc --noEmit`
  - **Commit**: `refactor(cli): extract constants and remove hardcoded values`
  - _Requirements: FR-10_
  - _Design: Execution Loop Design_

- [ ] 2.6 [VERIFY] Quality check: type check and build
  - **Do**: Run type check and build
  - **Verify**: `cd packages/cli && npx tsc --noEmit && npx tsup`
  - **Done when**: Zero type errors, build succeeds
  - **Commit**: `chore(cli): pass quality checkpoint` (only if fixes needed)
  - _Requirements: FR-1_
  - _Design: File Structure_

## Phase 3: Testing

- [ ] 3.1 Set up vitest config and test fixtures
  - **Do**:
    1. Create `packages/cli/vitest.config.ts` with test root, coverage config (80% target)
    2. Create `packages/cli/test/fixtures/sample-tasks.md` with a variety of task formats (parallel, verify, completed, pending)
    3. Create `packages/cli/test/fixtures/sample-state.json` with valid state
    4. Create `packages/cli/test/helpers/mock-provider.ts` implementing `Provider` with configurable responses
  - **Files**: `packages/cli/vitest.config.ts`, `packages/cli/test/fixtures/sample-tasks.md`, `packages/cli/test/fixtures/sample-state.json`, `packages/cli/test/helpers/mock-provider.ts`
  - **Done when**: `npx vitest run` executes (even if no tests yet) and mock provider is ready
  - **Verify**: `cd packages/cli && npx vitest run`
  - **Commit**: `test(cli): set up vitest config, fixtures, and mock provider`
  - _Requirements: NFR-5_
  - _Design: Test Strategy_

- [ ] 3.2 Unit tests for task parser
  - **Do**:
    1. Create `packages/cli/test/lib/task-parser.test.ts`
    2. Test: parse complete task, parse task with all tags, parse [P] groups, parse [x] completed tasks, handle malformed input, detect parallel groups (max 5), extract body fields (Do, Files, Done when, Verify, Commit)
    3. Use sample-tasks.md fixture as input
  - **Files**: `packages/cli/test/lib/task-parser.test.ts`
  - **Done when**: Tests cover all ParsedTask fields and edge cases; all assertions pass
  - **Verify**: `cd packages/cli && npx vitest run test/lib/task-parser.test.ts`
  - **Commit**: `test(cli): add unit tests for task parser`
  - _Requirements: NFR-5_
  - _Design: Test Strategy_

- [ ] 3.3 [P] Unit tests for config resolver
  - **Do**:
    1. Create `packages/cli/test/lib/config.test.ts`
    2. Test: env var precedence over file, project file over global, missing config returns null, getApiKey reads from env, writeConfig creates file, zod validation rejects bad shapes
  - **Files**: `packages/cli/test/lib/config.test.ts`
  - **Done when**: Tests cover resolution order and all edge cases; all assertions pass
  - **Verify**: `cd packages/cli && npx vitest run test/lib/config.test.ts`
  - **Commit**: `test(cli): add unit tests for config resolver`
  - _Requirements: NFR-5_
  - _Design: Test Strategy_

- [ ] 3.4 [P] Unit tests for spec manager
  - **Do**:
    1. Create `packages/cli/test/lib/spec-manager.test.ts`
    2. Test: createSpec scaffolds directory, name validation rejects bad names, getActiveSpec/setActiveSpec roundtrip, readState with defaults, writeState atomic write, readSpecFile/writeSpecFile, deleteState
  - **Files**: `packages/cli/test/lib/spec-manager.test.ts`
  - **Done when**: Tests cover all spec manager operations with temp dirs; all assertions pass
  - **Verify**: `cd packages/cli && npx vitest run test/lib/spec-manager.test.ts`
  - **Commit**: `test(cli): add unit tests for spec manager`
  - _Requirements: NFR-5_
  - _Design: Test Strategy_

- [ ] 3.5 [P] Unit tests for output utilities
  - **Do**:
    1. Create `packages/cli/test/lib/output.test.ts`
    2. Test: info/success/warn/error produce correct prefix, JSON mode suppresses non-JSON output, debug mode shows debug messages
  - **Files**: `packages/cli/test/lib/output.test.ts`
  - **Done when**: Tests verify prefix characters and mode behavior; all assertions pass
  - **Verify**: `cd packages/cli && npx vitest run test/lib/output.test.ts`
  - **Commit**: `test(cli): add unit tests for output utilities`
  - _Requirements: NFR-5_
  - _Design: Test Strategy_

- [ ] 3.6 [VERIFY] Quality check: all tests pass
  - **Do**: Run full test suite
  - **Verify**: `cd packages/cli && npx vitest run`
  - **Done when**: All tests pass
  - **Commit**: `chore(cli): pass quality checkpoint` (only if fixes needed)
  - _Requirements: NFR-5_
  - _Design: Test Strategy_

- [ ] 3.7 Unit tests for execution loop
  - **Do**:
    1. Create `packages/cli/test/lib/execution-loop.test.ts`
    2. Use mock provider to test: sequential task advancement, state updates after each task, retry on failure (up to 3), parallel group execution, resume from existing state, TASK_COMPLETE signal detection
  - **Files**: `packages/cli/test/lib/execution-loop.test.ts`
  - **Done when**: Tests cover main loop, retry, parallel, and resume paths; all assertions pass
  - **Verify**: `cd packages/cli && npx vitest run test/lib/execution-loop.test.ts`
  - **Commit**: `test(cli): add unit tests for execution loop`
  - _Requirements: NFR-5_
  - _Design: Test Strategy_

- [ ] 3.8 [P] Unit tests for error classes
  - **Do**:
    1. Create `packages/cli/test/lib/errors.test.ts`
    2. Test: each error class sets correct message, suggestion, and exit code; RalphError base class works; instanceof checks work for each subclass
  - **Files**: `packages/cli/test/lib/errors.test.ts`
  - **Done when**: All error class constructors and properties verified; all assertions pass
  - **Verify**: `cd packages/cli && npx vitest run test/lib/errors.test.ts`
  - **Commit**: `test(cli): add unit tests for error classes`
  - _Requirements: NFR-5_
  - _Design: Test Strategy_

- [ ] 3.9 [P] Unit tests for agent prompt registry
  - **Do**:
    1. Create `packages/cli/test/agents/index.test.ts`
    2. Test: getPrompt returns non-empty string for each agent name, getPrompt throws for unknown agent
  - **Files**: `packages/cli/test/agents/index.test.ts`
  - **Done when**: Registry returns prompts for all 5 agents; all assertions pass
  - **Verify**: `cd packages/cli && npx vitest run test/agents/index.test.ts`
  - **Commit**: `test(cli): add unit tests for agent prompt registry`
  - _Requirements: NFR-5_
  - _Design: Test Strategy_

- [ ] 3.10 Security test: writeConfig never serializes API key value
  - **Do**:
    1. Create `packages/cli/test/lib/config-security.test.ts`
    2. Set a dummy API key in `process.env.ANTHROPIC_API_KEY`
    3. Call `writeConfig()` with a config referencing that env var
    4. Read the written file and assert it does not contain the key value — only the env var name
    5. Repeat for any other paths that write config or state to disk
  - **Files**: `packages/cli/test/lib/config-security.test.ts`
  - **Done when**: Test asserts no API key value appears in any written file; all assertions pass
  - **Verify**: `cd packages/cli && npx vitest run test/lib/config-security.test.ts`
  - **Commit**: `test(cli): add security test asserting API keys never written to disk`
  - _Requirements: NFR-7_
  - _Design: Config Resolver_

- [ ] 3.11 Integration test: CI env var-only workflow
  - **Do**:
    1. Create `packages/cli/test/integration/ci-env-vars.test.ts`
    2. In a temp directory with no config file present, set `RALPH_PROVIDER` and `RALPH_MODEL` env vars only
    3. Call `resolveConfig()` and assert it returns a valid config sourced from env vars
    4. Run `ralph doctor` equivalent check and assert it reports env vars as the active configuration source
    5. Assert that all non-AI commands work (init, new, status) without any config file on disk
  - **Files**: `packages/cli/test/integration/ci-env-vars.test.ts`
  - **Done when**: Config resolves from env vars alone; doctor identifies the correct source; all assertions pass
  - **Verify**: `cd packages/cli && npx vitest run test/integration/ci-env-vars.test.ts`
  - **Commit**: `test(cli): add integration test for CI env var-only configuration`
  - _Requirements: US-3_
  - _Design: Config Resolver_

- [ ] 3.12 Integration test: spec lifecycle (init -> new -> status -> cancel)
  - **Do**:
    1. Create `packages/cli/test/integration/spec-lifecycle.test.ts`
    2. Test in temp directory: init creates config, new creates spec dir, status reads spec, switch changes active, cancel removes state
    3. Verify file contents at each step
  - **Files**: `packages/cli/test/integration/spec-lifecycle.test.ts`
  - **Done when**: Full non-AI lifecycle tested against real filesystem in temp dir; all assertions pass
  - **Verify**: `cd packages/cli && npx vitest run test/integration/spec-lifecycle.test.ts`
  - **Commit**: `test(cli): add integration test for spec lifecycle`
  - _Requirements: NFR-5, US-4, US-5, US-6, US-7_
  - _Design: Test Strategy_

- [ ] 3.13 Integration test: execution loop with mock provider
  - **Do**:
    1. Create `packages/cli/test/integration/execution-loop.test.ts`
    2. Pre-populate a temp spec with tasks.md, use mock provider that returns TASK_COMPLETE
    3. Test: loop advances through all tasks, state file updated correctly, tasks marked [x], progress.md updated
    4. Test resume: stop mid-run, re-run, verify picks up from correct task
  - **Files**: `packages/cli/test/integration/execution-loop.test.ts`
  - **Done when**: Execution loop integration works end-to-end with mock provider; all assertions pass
  - **Verify**: `cd packages/cli && npx vitest run test/integration/execution-loop.test.ts`
  - **Commit**: `test(cli): add integration test for execution loop`
  - _Requirements: NFR-5, US-12_
  - _Design: Test Strategy_

- [ ] 3.14 Integration test: plugin interoperability smoke test
  - **Do**:
    1. Create `packages/cli/test/integration/plugin-interop.test.ts`
    2. Write a minimal spec directory (research.md, requirements.md, design.md, tasks.md, .ralph-state.json) using the exact schema the plugin produces (copy a real fixture or generate it programmatically)
    3. Call `readState()`, `parseTasks()`, and `readSpecFile()` on the fixture and assert all fields parse without error
    4. Write the spec back out using CLI write functions and assert the on-disk bytes match the expected plugin-compatible format
  - **Files**: `packages/cli/test/integration/plugin-interop.test.ts`, `packages/cli/test/fixtures/plugin-written-spec/` (fixture directory)
  - **Done when**: CLI reads and writes plugin-format specs without data loss or schema errors; all assertions pass
  - **Verify**: `cd packages/cli && npx vitest run test/integration/plugin-interop.test.ts`
  - **Commit**: `test(cli): add plugin interoperability smoke test`
  - _Requirements: US-16, FR-7, FR-8_
  - _Design: Migration Path_

- [ ] 3.15 [VERIFY] Quality check: all tests pass with coverage
  - **Do**: Run full test suite with coverage
  - **Verify**: `cd packages/cli && npx vitest run --coverage`
  - **Done when**: All tests pass, coverage report generated
  - **Commit**: `chore(cli): pass quality checkpoint` (only if fixes needed)
  - _Requirements: NFR-5_
  - _Design: Test Strategy_

## Phase 4: Quality Gates

- [ ] 4.1 Startup time verification
  - **Do**:
    1. Build the binary: `cd packages/cli && npx tsup`
    2. Run `time node dist/cli.js --help` at least 5 times and record results
    3. Assert the median wall time is under 100ms
    4. If over 100ms: profile with `node --prof dist/cli.js --help` and address the largest initialization costs (e.g., lazy-load heavy imports)
  - **Files**: `packages/cli/src/cli.ts` (lazy-load fixes if needed)
  - **Done when**: `time node dist/cli.js --help` consistently completes in under 100ms
  - **Verify**: `time node packages/cli/dist/cli.js --help`
  - **Commit**: `perf(cli): ensure --help startup under 100ms`
  - _Requirements: NFR-1_
  - _Design: CLI Entry_

- [ ] 4.2 Local quality check
  - **Do**: Run ALL quality checks locally before creating PR
  - **Verify**: All commands must pass:
    - Type check: `cd packages/cli && npx tsc --noEmit`
    - Tests: `cd packages/cli && npx vitest run`
    - Build: `cd packages/cli && npx tsup`
  - **Done when**: All commands pass with no errors
  - **Commit**: `fix(cli): address lint/type issues` (if fixes needed)
  - _Requirements: FR-1, FR-14_
  - _Design: File Structure_

- [ ] 4.3 Create PR and verify CI
  - **Do**:
    1. Verify current branch is a feature branch: `git branch --show-current`
    2. If on default branch, STOP and alert user (branch should be set at startup)
    3. Push branch: `git push -u origin $(git branch --show-current)`
    4. Create PR using gh CLI:
       ```bash
       gh pr create --title "feat: add Smart Ralph CLI binary" --body "## Summary
       Standalone Node.js/TypeScript CLI for spec-driven development.

       ## Test Plan
       - [x] Local quality gates pass (types, tests, build)
       - [ ] CI checks pass"
       ```
    5. If gh CLI unavailable, output: "Create PR at: https://github.com/<org>/<repo>/compare/<branch>"
  - **Verify**: `gh pr checks --watch`
  - **Done when**: All CI checks show passing, PR ready for review
  - **If CI fails**:
    1. View failures: `gh pr checks`
    2. Get detailed logs: `gh run view <run-id> --log-failed`
    3. Fix issues locally
    4. Commit and push: `git add . && git commit -m "fix: address CI failures" && git push`
    5. Re-verify: `gh pr checks --watch`
  - _Requirements: FR-1, FR-14_
  - _Design: File Structure_

- [ ] VE1 [VERIFY] E2E startup: build and verify binary
  - **Do**:
    1. Build: `cd packages/cli && npx tsup`
    2. Verify binary exists: `test -f packages/cli/dist/cli.js`
    3. Verify shebang: `head -1 packages/cli/dist/cli.js | grep -q "#!/usr/bin/env node"`
  - **Verify**: `cd packages/cli && node dist/cli.js --help > /dev/null && echo PASS`
  - **Done when**: Binary builds and responds to --help
  - **Commit**: None

- [ ] VE2 [VERIFY] E2E check: run init, new, status in temp dir
  - **Do**:
    1. Create temp dir: `TMPDIR=$(mktemp -d)`
    2. Run `cd $TMPDIR && node <abs-path>/packages/cli/dist/cli.js init`
    3. Run `node <abs-path>/packages/cli/dist/cli.js new test-spec "Test goal"`
    4. Run `node <abs-path>/packages/cli/dist/cli.js status --json` and verify JSON with jq
  - **Verify**: `cd $TMPDIR && node <abs-path>/packages/cli/dist/cli.js status --json | jq .name && echo PASS`
  - **Done when**: All 3 commands succeed in fresh temp directory with valid JSON output
  - **Commit**: None

- [ ] VE3 [VERIFY] E2E cleanup: remove temp directory
  - **Do**:
    1. Remove temp dir: `rm -rf $TMPDIR`
    2. Verify removed: `test ! -d $TMPDIR`
  - **Verify**: `test ! -d $TMPDIR && echo PASS`
  - **Done when**: Temp directory cleaned up
  - **Commit**: None

## Phase 5: PR Lifecycle (Continuous Validation)

- [ ] 5.1 Create pull request
  - **Do**:
    1. Verify current branch: `git branch --show-current`
    2. Push: `git push -u origin $(git branch --show-current)`
    3. Create PR: `gh pr create --title "feat: add Smart Ralph CLI" --body "$(cat <<'EOF'
## Summary
Standalone Node.js/TypeScript CLI binary for spec-driven development. Replicates the Smart Ralph plugin workflow as a self-contained tool with embedded AI SDK calls.

## Completion Criteria
- [x] Zero regressions (all existing tests pass)
- [x] Code is modular and reusable
- [x] Real-world validation complete
- [ ] CI checks green
- [ ] Code review approved
EOF
)"`
  - **Verify**: `gh pr view` shows PR URL
  - **Done when**: PR created and URL returned
  - **Commit**: None
  - _Requirements: FR-1, FR-14_
  - _Design: File Structure_

- [ ] 5.2 Monitor CI and fix failures
  - **Do**:
    1. Wait 3 minutes for CI to start
    2. Check status: `gh pr checks`
    3. If failures: read logs with `gh run view --log-failed`
    4. Fix issues locally
    5. Commit fixes: `git add . && git commit -m "fix: address CI failures"`
    6. Push: `git push`
    7. Repeat from step 1 until all green
  - **Verify**: `gh pr checks` shows all passing
  - **Done when**: All CI checks passing
  - **Commit**: `fix: address CI failures` (as needed per iteration)
  - _Requirements: FR-1, FR-14_
  - _Design: File Structure_

- [ ] 5.3 Address code review comments
  - **Do**:
    1. Fetch reviews: `gh pr view --json reviews --jq '.reviews[] | select(.state == "CHANGES_REQUESTED" or .state == "PENDING")'`
    2. For each unresolved review/comment: read, implement fix, commit
    3. Push all fixes: `git push`
    4. Re-check for new reviews
  - **Verify**: `gh pr view --json reviews` shows no CHANGES_REQUESTED
  - **Done when**: All review comments resolved
  - **Commit**: `fix: address review - {{summary}}` (per comment)
  - _Requirements: FR-1, FR-14_
  - _Design: File Structure_

- [ ] 5.4 Final validation
  - **Do**: Verify ALL completion criteria met:
    1. Run full test suite: `cd packages/cli && npx vitest run`
    2. Build: `cd packages/cli && npx tsup`
    3. Type check: `cd packages/cli && npx tsc --noEmit`
    4. Check CI: `gh pr checks` all green
  - **Verify**: All commands pass, all criteria documented
  - **Done when**: All completion criteria met, PR approved and ready to merge
  - **Commit**: None
  - _Requirements: FR-1, FR-14_
  - _Design: File Structure_

## Notes

- **POC shortcuts taken**: Agent prompts are placeholder strings in Phase 1 (refined in Phase 2), no interactive prompt for overwrite confirmation (just --force flag), no spinner animation during AI calls
- **Production TODOs**: Extract real agent prompts from plugin markdown files, add ora spinner to AI commands, add readline-based confirmation prompts

## Dependencies

```
Phase 1 (POC) → Phase 2 (Refactor) → Phase 3 (Testing) → Phase 4 (Quality) → Phase 5 (PR Lifecycle)
```
