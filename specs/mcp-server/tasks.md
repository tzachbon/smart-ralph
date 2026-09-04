---
spec: mcp-server
phase: tasks
total_tasks: 46
created: 2026-01-26
---

# Tasks: Ralph Specum MCP Server

## Overview

Total tasks: 46
POC-first workflow with 5 phases:
1. Phase 1: Make It Work (POC) - Validate idea end-to-end (18 tasks)
2. Phase 2: Refactoring - Clean up code structure (6 tasks)
3. Phase 3: Testing - Add unit/integration tests (8 tasks)
4. Phase 4: Quality Gates - Local quality checks and PR creation (4 tasks)
5. Phase 5: PR Lifecycle - Autonomous CI monitoring, review resolution, final validation (4 tasks)

## Execution Context (from Interview)

| Topic | Decision |
|-------|----------|
| Testing depth | Standard - unit + integration |
| Deployment approach | Standard CI/CD pipeline |
| Execution priority | Balanced - reasonable quality with speed |

## Completion Criteria (Autonomous Execution Standard)

This spec is not complete until ALL criteria are met:

- Zero Regressions: All existing tests pass (no broken functionality)
- Modular & Reusable: Code follows project patterns, properly abstracted
- Real-World Validation: Feature tested in actual environment (not just unit tests)
- All Tests Pass: Unit, integration all green
- CI Green: All CI checks passing
- PR Ready: Pull request created, reviewed, approved
- Review Comments Resolved: All code review feedback addressed

**Note**: The executor will continue working until all criteria are met. Do not stop at Phase 4 if CI fails or review comments exist.

> **Quality Checkpoints**: Intermediate quality gate checks are inserted every 2-3 tasks to catch issues early.

## Phase 1: Make It Work (POC)

Focus: Validate the idea works end-to-end. Skip tests, accept hardcoded values.

- [x] 1.1 Initialize repository with Bun and corepack
  - **Do**:
    1. Create `package.json` in repo root with `"packageManager": "bun@1.2.0"` field
    2. Add `"type": "module"` to package.json
    3. Run `corepack enable` to enable corepack
    4. Create minimal `.nvmrc` with `22` for Node compatibility
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-mcp-server/package.json`, `/Users/zachbonfil/projects/smart-ralph-mcp-server/.nvmrc`
  - **Done when**: `corepack enable && bun --version` runs without error
  - **Verify**: `bun --version && cat package.json | grep packageManager`
  - **Commit**: `chore: initialize repo with bun and corepack`
  - _Requirements: User feedback from design review_
  - _Design: npm Package Configuration_

- [x] 1.2 Initialize mcp-server directory structure
  - **Do**:
    1. Create `mcp-server/` directory
    2. Create `mcp-server/package.json` with name `@smart-ralph/ralph-specum-mcp`, dependencies (@modelcontextprotocol/sdk, zod), scripts (start, build, typecheck)
    3. Create `mcp-server/tsconfig.json` with strict mode, ESM, Bun types
    4. Create `mcp-server/src/` directory structure: `tools/`, `lib/`, `assets/agents/`, `assets/templates/`
  - **Files**:
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/package.json`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/tsconfig.json`
  - **Done when**: `cd mcp-server && bun install` succeeds
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun install && ls -la src/`
  - **Commit**: `feat(mcp): initialize mcp-server directory with bun project`
  - _Requirements: FR-1, FR-4_
  - _Design: File Structure_

- [x] 1.3 Copy agent prompts to MCP server assets
  - **Do**:
    1. Copy `plugins/ralph-specum/agents/research-analyst.md` to `mcp-server/src/assets/agents/`
    2. Copy `plugins/ralph-specum/agents/product-manager.md` to `mcp-server/src/assets/agents/`
    3. Copy `plugins/ralph-specum/agents/architect-reviewer.md` to `mcp-server/src/assets/agents/`
    4. Copy `plugins/ralph-specum/agents/task-planner.md` to `mcp-server/src/assets/agents/`
    5. Copy `plugins/ralph-specum/agents/spec-executor.md` to `mcp-server/src/assets/agents/`
  - **Files**:
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/assets/agents/research-analyst.md`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/assets/agents/product-manager.md`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/assets/agents/architect-reviewer.md`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/assets/agents/task-planner.md`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/assets/agents/spec-executor.md`
  - **Done when**: All 5 agent files exist in mcp-server/src/assets/agents/
  - **Verify**: `ls /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/assets/agents/*.md | wc -l` returns 5
  - **Commit**: `feat(mcp): copy agent prompts to mcp-server assets`
  - _Requirements: FR-2_
  - _Design: Embedded Assets_

- [x] 1.4 Copy templates to MCP server assets
  - **Do**:
    1. Copy `plugins/ralph-specum/templates/progress.md` to `mcp-server/src/assets/templates/`
    2. Copy `plugins/ralph-specum/templates/research.md` to `mcp-server/src/assets/templates/`
    3. Copy `plugins/ralph-specum/templates/requirements.md` to `mcp-server/src/assets/templates/`
    4. Copy `plugins/ralph-specum/templates/design.md` to `mcp-server/src/assets/templates/`
    5. Copy `plugins/ralph-specum/templates/tasks.md` to `mcp-server/src/assets/templates/`
  - **Files**:
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/assets/templates/progress.md`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/assets/templates/research.md`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/assets/templates/requirements.md`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/assets/templates/design.md`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/assets/templates/tasks.md`
  - **Done when**: All 5 template files exist in mcp-server/src/assets/templates/
  - **Verify**: `ls /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/assets/templates/*.md | wc -l` returns 5
  - **Commit**: `feat(mcp): copy spec templates to mcp-server assets`
  - _Requirements: FR-3_
  - _Design: Embedded Assets_

- [x] 1.5 Create assets barrel with Bun text imports
  - **Do**:
    1. Create `mcp-server/src/assets/index.ts` with Bun `import with { type: "text" }` for all agents and templates
    2. Export `AGENTS` object with researchAnalyst, productManager, architectReviewer, taskPlanner, specExecutor
    3. Export `TEMPLATES` object with progress, research, requirements, design, tasks
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/assets/index.ts`
  - **Done when**: File compiles without error, exports AGENTS and TEMPLATES
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run src/assets/index.ts`
  - **Commit**: `feat(mcp): create assets barrel with embedded text imports`
  - _Requirements: FR-2, FR-3_
  - _Design: Embedded Assets, src/assets/index.ts_

- [x] 1.6 [VERIFY] Quality checkpoint: typecheck
  - **Do**: Run typecheck to verify assets compile correctly
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run typecheck`
  - **Done when**: No type errors
  - **Commit**: `chore(mcp): pass quality checkpoint` (only if fixes needed)

- [x] 1.7 Implement MCPLogger
  - **Do**:
    1. Create `mcp-server/src/lib/logger.ts`
    2. Define `LogLevel` type: "debug" | "info" | "warning" | "error"
    3. Define `LogMessage` interface: { level, logger, data, timestamp }
    4. Implement `MCPLogger` class with methods: debug, info, warning, error
    5. All output via `console.error()` to stderr (NEVER console.log)
    6. Format: JSON stringified `LogMessage`
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/lib/logger.ts`
  - **Done when**: Logger writes structured JSON to stderr
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run -e "import {MCPLogger} from './src/lib/logger'; const l = new MCPLogger(); l.info('test', {msg: 'hello'})" 2>&1 | grep -q '"level":"info"' && echo "OK"`
  - **Commit**: `feat(mcp): implement MCPLogger with stderr output`
  - _Requirements: FR-12, US-15, AC-15.1 through AC-15.6_
  - _Design: MCPLogger component_

- [x] 1.8 Implement StateManager
  - **Do**:
    1. Create `mcp-server/src/lib/state.ts`
    2. Define `RalphState` interface matching existing schema (phase, taskIndex, totalTasks, etc.)
    3. Implement StateManager class with methods: read, write, delete, exists
    4. read(): Parse JSON, validate required fields, return null if not found
    5. write(): Atomic write via temp file + rename
    6. Handle corruption gracefully (backup corrupt file, return null)
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/lib/state.ts`
  - **Done when**: Can read/write .ralph-state.json files
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run typecheck`
  - **Commit**: `feat(mcp): implement StateManager for .ralph-state.json`
  - _Requirements: FR-11_
  - _Design: StateManager component_

- [x] 1.9 Implement FileManager
  - **Do**:
    1. Create `mcp-server/src/lib/files.ts`
    2. Implement FileManager class with methods: readSpecFile, writeSpecFile, listSpecs, specExists, createSpecDir, deleteSpec, getCurrentSpec, setCurrentSpec
    3. Use process.cwd() as base path for relative spec paths
    4. getCurrentSpec reads ./specs/.current-spec
    5. setCurrentSpec writes to ./specs/.current-spec
    6. listSpecs reads ./specs/ directory, filters directories only
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/lib/files.ts`
  - **Done when**: Can list specs, read/write spec files
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run typecheck`
  - **Commit**: `feat(mcp): implement FileManager for spec file operations`
  - _Requirements: FR-5_
  - _Design: FileManager component_

- [x] 1.10 [VERIFY] Quality checkpoint: typecheck
  - **Do**: Run typecheck to verify lib modules compile correctly
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run typecheck`
  - **Done when**: No type errors
  - **Commit**: `chore(mcp): pass quality checkpoint` (only if fixes needed)

- [x] 1.11 Implement direct tools: status, help
  - **Do**:
    1. Create `mcp-server/src/tools/status.ts` - handleStatus: list all specs with phase, task progress
    2. Create `mcp-server/src/tools/help.ts` - handleHelp: return usage info and tool list
    3. Each handler receives FileManager, StateManager instances
    4. Return MCP TextContent response format
  - **Files**:
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/tools/status.ts`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/tools/help.ts`
  - **Done when**: Both tools return formatted text responses
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run typecheck`
  - **Commit**: `feat(mcp): implement ralph_status and ralph_help tools`
  - _Requirements: US-9, US-13, AC-9.1 through AC-9.4, AC-13.1 through AC-13.4_
  - _Design: Direct Tools_

- [x] 1.12 Implement direct tools: switch, cancel
  - **Do**:
    1. Create `mcp-server/src/tools/switch.ts` - handleSwitch: validate spec exists, update .current-spec
    2. Create `mcp-server/src/tools/cancel.ts` - handleCancel: delete .ralph-state.json, optionally delete spec dir
    3. Include Zod schema for input validation
  - **Files**:
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/tools/switch.ts`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/tools/cancel.ts`
  - **Done when**: Tools execute and return confirmation
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run typecheck`
  - **Commit**: `feat(mcp): implement ralph_switch and ralph_cancel tools`
  - _Requirements: US-10, US-11, AC-10.1 through AC-10.4, AC-11.1 through AC-11.4_
  - _Design: Direct Tools_

- [x] 1.13 Implement ralph_start tool
  - **Do**:
    1. Create `mcp-server/src/tools/start.ts`
    2. Input schema: name?, goal?, quick?
    3. If name not provided, generate from goal or prompt for name
    4. Create ./specs/<name>/ directory
    5. Initialize .progress.md from template with goal
    6. Initialize .ralph-state.json with phase: "research"
    7. Update ./specs/.current-spec
    8. Return success message with next step
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/tools/start.ts`
  - **Done when**: Creates spec directory with initial files
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run typecheck`
  - **Commit**: `feat(mcp): implement ralph_start tool`
  - _Requirements: US-3, AC-3.1 through AC-3.6_
  - _Design: ralph_start handler_

- [x] 1.14 [VERIFY] Quality checkpoint: typecheck
  - **Do**: Run typecheck to verify direct tools compile correctly
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run typecheck`
  - **Done when**: No type errors
  - **Commit**: `chore(mcp): pass quality checkpoint` (only if fixes needed)

- [x] 1.15 Implement ralph_complete_phase tool
  - **Do**:
    1. Create `mcp-server/src/tools/complete-phase.ts`
    2. Input schema: spec_name?, phase, summary
    3. Validate phase matches current state
    4. Update .ralph-state.json with next phase
    5. Append summary to .progress.md
    6. Return next step instruction
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/tools/complete-phase.ts`
  - **Done when**: Transitions state and updates progress
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run typecheck`
  - **Commit**: `feat(mcp): implement ralph_complete_phase tool`
  - _Requirements: US-12, AC-12.1 through AC-12.4_
  - _Design: ralph_complete_phase handler_

- [x] 1.16 Implement instruction tools: research, requirements, design, tasks
  - **Do**:
    1. Create `mcp-server/src/tools/research.ts` - return research-analyst prompt + goal context
    2. Create `mcp-server/src/tools/requirements.ts` - return product-manager prompt + research context
    3. Create `mcp-server/src/tools/design.ts` - return architect-reviewer prompt + requirements context
    4. Create `mcp-server/src/tools/tasks.ts` - return task-planner prompt + design context
    5. Each uses buildInstructionResponse helper
    6. Include expected actions and completion instruction
  - **Files**:
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/tools/research.ts`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/tools/requirements.ts`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/tools/design.ts`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/tools/tasks.ts`
  - **Done when**: All 4 tools return structured instruction responses
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run typecheck`
  - **Commit**: `feat(mcp): implement instruction tools for spec phases`
  - _Requirements: US-4, US-5, US-6, US-7, AC-4.1 through AC-7.5_
  - _Design: Instruction Tools_

- [x] 1.17 Implement ralph_implement tool
  - **Do**:
    1. Create `mcp-server/src/tools/implement.ts`
    2. Input schema: max_iterations?
    3. Read current task from tasks.md using taskIndex
    4. Return spec-executor prompt + coordinator instructions + current task
    5. Include task completion protocol in response
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/tools/implement.ts`
  - **Done when**: Returns executor prompt with task context
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run typecheck`
  - **Commit**: `feat(mcp): implement ralph_implement tool`
  - _Requirements: US-8, AC-8.1 through AC-8.5_
  - _Design: ralph_implement handler_

- [x] 1.18 Create tool registration barrel
  - **Do**:
    1. Create `mcp-server/src/tools/index.ts`
    2. Export all tool handlers
    3. Export tool registration function that takes McpServer instance
    4. Register all 11 tools with schemas and descriptions
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/tools/index.ts`
  - **Done when**: Single function registers all tools
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run typecheck`
  - **Commit**: `feat(mcp): create tool registration barrel`
  - _Requirements: FR-5_
  - _Design: Tool Handlers_

- [x] 1.19 [VERIFY] Quality checkpoint: typecheck
  - **Do**: Run typecheck to verify all tools compile correctly
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run typecheck`
  - **Done when**: No type errors
  - **Commit**: `chore(mcp): pass quality checkpoint` (only if fixes needed)

- [x] 1.20 Create MCP server entry point
  - **Do**:
    1. Create `mcp-server/src/index.ts`
    2. Create McpServer instance with name "ralph-specum", version from package.json
    3. Initialize FileManager, StateManager, MCPLogger
    4. Register all tools via barrel
    5. Create StdioServerTransport
    6. Connect server to transport
    7. Add shebang `#!/usr/bin/env bun`
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/index.ts`
  - **Done when**: Server starts and accepts connections
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && timeout 2 bun run src/index.ts || true`
  - **Commit**: `feat(mcp): create MCP server entry point`
  - _Requirements: FR-4_
  - _Design: McpServer Entry Point_

- [x] 1.21 Add CLI flags (--help, --version)
  - **Do**:
    1. Parse process.argv for --help and --version
    2. --help: Print usage info and exit
    3. --version: Print version from package.json and exit
    4. Only start server if no flags provided
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/index.ts`
  - **Done when**: `--help` and `--version` work
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run src/index.ts --version && bun run src/index.ts --help`
  - **Commit**: `feat(mcp): add CLI flags for help and version`
  - _Requirements: AC-1.5_
  - _Design: McpServer Entry Point_

- [x] 1.22 POC Checkpoint: End-to-end validation with real MCP client
  - **Do**:
    1. Build the MCP server: `cd mcp-server && bun run build`
    2. Add server to Claude Desktop config (claude_desktop_config.json)
    3. Start Claude Desktop
    4. Test tool discovery: server should advertise all 11 tools
    5. Test ralph_status tool: should list specs
    6. Test ralph_help tool: should return usage info
    7. Test ralph_start tool: should create spec directory
    8. Test full workflow: start -> research -> complete_phase
  - **Verify**: Manual testing in Claude Desktop - document results in .progress.md
  - **Done when**: All 11 tools callable from Claude Desktop, basic workflow functions
  - **Commit**: `feat(mcp): complete POC with Claude Desktop validation`
  - _Requirements: AC-2.1 through AC-2.4, NFR-5_
  - _Design: Data Flow diagrams_

## Phase 2: Refactoring

After POC validated, clean up code.

- [x] 2.1 Extract instruction response builder
  - **Do**:
    1. Create `mcp-server/src/lib/instruction-builder.ts`
    2. Implement `buildInstructionResponse` function matching design spec
    3. Params: specName, phase, agentPrompt, context, expectedActions, completionInstruction
    4. Returns MCP TextContent response
    5. Update all instruction tools to use this helper
  - **Files**:
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/lib/instruction-builder.ts`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/tools/research.ts`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/tools/requirements.ts`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/tools/design.ts`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/tools/tasks.ts`
  - **Done when**: No duplicate instruction building code
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run typecheck`
  - **Commit**: `refactor(mcp): extract instruction response builder`
  - _Design: Instruction-Return Template_

- [x] 2.2 Add comprehensive error handling
  - **Do**:
    1. Add try/catch to all tool handlers
    2. Return MCP-compliant error responses
    3. Add specific error messages for: spec not found, invalid state, missing prerequisites, phase mismatch
    4. Use MCPLogger to log errors to stderr
    5. Never expose stack traces to client
  - **Files**: All tool files in `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/tools/`
  - **Done when**: All error scenarios return helpful messages
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run typecheck`
  - **Commit**: `refactor(mcp): add comprehensive error handling`
  - _Design: Error Handling table_

- [x] 2.3 [VERIFY] Quality checkpoint: typecheck
  - **Do**: Run typecheck to verify refactoring doesn't break types
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run typecheck`
  - **Done when**: No type errors
  - **Commit**: `chore(mcp): pass quality checkpoint` (only if fixes needed)

- [x] 2.4 Add JSON schema validation for state files
  - **Do**:
    1. Create Zod schema for RalphState in state.ts
    2. Validate on read, return null if invalid
    3. On corruption: backup to .ralph-state.json.bak, log error
    4. Include all optional fields from full schema
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/lib/state.ts`
  - **Done when**: Invalid JSON returns null, corrupt file backed up
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run typecheck`
  - **Commit**: `refactor(mcp): add JSON schema validation for state files`
  - _Design: StateManager validation_

- [x] 2.5 Add edge case handling
  - **Do**:
    1. Handle no specs exist case in ralph_status
    2. Handle spec with no state file (treat as needs restart)
    3. Handle empty goal in ralph_start (error: "Quick mode requires a goal")
    4. Handle duplicate spec name (append -2, -3 suffix)
  - **Files**:
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/tools/status.ts`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/tools/start.ts`
  - **Done when**: All edge cases from design doc handled
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run typecheck`
  - **Commit**: `refactor(mcp): add edge case handling`
  - _Design: Edge Cases section_

- [x] 2.6 Code cleanup and final types
  - **Do**:
    1. Remove any hardcoded values
    2. Add proper TypeScript types for all parameters
    3. Export types for external use
    4. Add JSDoc comments to public functions
    5. Ensure consistent code style
  - **Files**: All files in `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/src/`
  - **Done when**: No TODOs remain, all types explicit
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run typecheck`
  - **Commit**: `refactor(mcp): cleanup and finalize types`

## Phase 3: Testing

- [x] 3.1 Set up test infrastructure
  - **Do**:
    1. Add `bun:test` configuration to package.json
    2. Create `mcp-server/tests/` directory
    3. Add test script: `"test": "bun test"`
    4. Create test utilities for mocking file system
  - **Files**:
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/package.json`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/tests/utils.ts`
  - **Done when**: `bun test` runs (even with no tests)
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun test`
  - **Commit**: `test(mcp): set up test infrastructure`
  - _Design: Test Strategy_

- [x] 3.2 Unit tests for StateManager
  - **Do**:
    1. Create `mcp-server/tests/state.test.ts`
    2. Test read(): returns state, returns null for missing, handles corruption
    3. Test write(): creates file, overwrites existing, atomic write
    4. Test delete(): removes file, no error if missing
    5. Test exists(): returns boolean
    6. Mock file system using temp directories
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/tests/state.test.ts`
  - **Done when**: All StateManager methods tested
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun test state`
  - **Commit**: `test(mcp): add unit tests for StateManager`
  - _Design: Test Strategy - Unit Tests_

- [x] 3.3 Unit tests for FileManager
  - **Do**:
    1. Create `mcp-server/tests/files.test.ts`
    2. Test listSpecs(): returns directories only
    3. Test specExists(): returns boolean
    4. Test createSpecDir(): creates nested directory
    5. Test getCurrentSpec/setCurrentSpec: read/write .current-spec
    6. Test readSpecFile/writeSpecFile: file operations
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/tests/files.test.ts`
  - **Done when**: All FileManager methods tested
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun test files`
  - **Commit**: `test(mcp): add unit tests for FileManager`
  - _Design: Test Strategy - Unit Tests_

- [x] 3.4 [VERIFY] Quality checkpoint: typecheck + tests
  - **Do**: Run typecheck and tests
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run typecheck && bun test`
  - **Done when**: No type errors, all tests pass
  - **Commit**: `chore(mcp): pass quality checkpoint` (only if fixes needed)

- [x] 3.5 Unit tests for MCPLogger
  - **Do**:
    1. Create `mcp-server/tests/logger.test.ts`
    2. Test all log levels: debug, info, warning, error
    3. Test output format: JSON with level, logger, data, timestamp
    4. Test output goes to stderr (capture stderr)
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/tests/logger.test.ts`
  - **Done when**: Logger output format verified
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun test logger`
  - **Commit**: `test(mcp): add unit tests for MCPLogger`
  - _Design: Test Strategy - Unit Tests_

- [x] 3.6 Unit tests for tool handlers
  - **Do**:
    1. Create `mcp-server/tests/tools/` directory
    2. Create tests for each direct tool: status, switch, cancel, help, start, complete-phase
    3. Test input validation with Zod
    4. Test success responses
    5. Test error responses
    6. Mock StateManager and FileManager
  - **Files**:
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/tests/tools/status.test.ts`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/tests/tools/switch.test.ts`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/tests/tools/cancel.test.ts`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/tests/tools/help.test.ts`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/tests/tools/start.test.ts`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/tests/tools/complete-phase.test.ts`
  - **Done when**: All direct tools tested
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun test tools`
  - **Commit**: `test(mcp): add unit tests for tool handlers`
  - _Design: Test Strategy - Unit Tests_

- [x] 3.7 Integration tests for full workflow
  - **Do**:
    1. Create `mcp-server/tests/integration/workflow.test.ts`
    2. Test full workflow: start -> research -> requirements -> design -> tasks
    3. Verify state transitions
    4. Verify file creation
    5. Use real file system in temp directory
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/tests/integration/workflow.test.ts`
  - **Done when**: Full workflow tested end-to-end
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun test integration`
  - **Commit**: `test(mcp): add integration tests for full workflow`
  - _Design: Test Strategy - Integration Tests_

- [x] 3.8 [VERIFY] Quality checkpoint: typecheck + all tests
  - **Do**: Run typecheck and all tests
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run typecheck && bun test`
  - **Done when**: No type errors, all tests pass
  - **Commit**: `chore(mcp): pass quality checkpoint` (only if fixes needed)

## Phase 4: Quality Gates

> **IMPORTANT**: NEVER push directly to the default branch (main/master). Branch management is handled at startup via `/ralph-specum:start`. You should already be on a feature branch by this phase.

- [x] 4.1 Create build and install scripts
  - **Do**:
    1. Create `mcp-server/scripts/build.sh` - cross-platform builds for darwin-arm64, darwin-x64, linux-x64, windows-x64
    2. Create `mcp-server/scripts/install.sh` - OS/arch detection, download from GitHub releases
    3. Add build:all script to package.json
    4. Make scripts executable
  - **Files**:
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/scripts/build.sh`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/scripts/install.sh`
    - `/Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server/package.json`
  - **Done when**: `./scripts/build.sh` creates binaries, `./scripts/install.sh` runs
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && chmod +x scripts/*.sh && ./scripts/build.sh && ls -la dist/`
  - **Commit**: `feat(mcp): add build and install scripts`
  - _Requirements: FR-8, FR-9, AC-1.1 through AC-1.4_
  - _Design: Build Script, Install Script_

- [x] 4.2 Create GitHub Actions workflow
  - **Do**:
    1. Create `.github/workflows/mcp-release.yml`
    2. Trigger on tag push (v*)
    3. Build binaries for all platforms
    4. Create GitHub release with binaries
    5. Publish to npm with `npm publish`
  - **Files**: `/Users/zachbonfil/projects/smart-ralph-mcp-server/.github/workflows/mcp-release.yml`
  - **Done when**: Workflow file valid YAML
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server && cat .github/workflows/mcp-release.yml | head -20`
  - **Commit**: `ci(mcp): add GitHub Actions release workflow`
  - _Requirements: FR-10_
  - _Design: Implementation Steps - CI/CD_

- [x] 4.3 Local quality check
  - **Do**: Run ALL quality checks locally
  - **Verify**: All commands must pass:
    - Type check: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run typecheck`
    - Tests: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun test`
    - Build: `cd /Users/zachbonfil/projects/smart-ralph-mcp-server/mcp-server && bun run build`
  - **Done when**: All commands pass with no errors
  - **Commit**: `fix(mcp): address quality issues` (if fixes needed)

- [x] 4.4 Create PR and verify CI
  - **Do**:
    1. Verify current branch is a feature branch: `git branch --show-current`
    2. If on default branch, STOP and alert user
    3. Push branch: `git push -u origin $(git branch --show-current)`
    4. Create PR: `gh pr create --title "feat(mcp): add MCP server for ralph-specum" --body "..."`
  - **Verify**: `gh pr checks --watch` - all checks must show passing
  - **Done when**: All CI checks green, PR ready for review
  - **Commit**: None (PR creation, not code change)

## Phase 5: PR Lifecycle (Continuous Validation)

> **Autonomous Loop**: This phase continues until ALL completion criteria met.

- [x] 5.1 Monitor CI and fix failures
  - **Do**:
    1. Wait 3 minutes for CI to start
    2. Check status: `gh pr checks`
    3. If failures: read logs with `gh run view --log-failed`
    4. Fix issues locally
    5. Commit fixes: `git add . && git commit -m "fix(mcp): address CI failures"`
    6. Push: `git push`
    7. Repeat from step 1 until all green
  - **Verify**: `gh pr checks` shows all passing
  - **Done when**: All CI checks passing
  - **Commit**: `fix(mcp): address CI failures` (as needed)

- [x] 5.2 Address code review comments
  - **Do**:
    1. Fetch reviews: `gh pr view --json reviews`
    2. For inline comments: `gh api repos/{owner}/{repo}/pulls/{number}/comments`
    3. For each unresolved review: implement change, commit with message referencing comment
    4. Push fixes
    5. Wait 5 minutes, re-check for new reviews
    6. Repeat until no unresolved reviews
  - **Verify**: `gh pr view --json reviews` shows no CHANGES_REQUESTED
  - **Done when**: All review comments resolved
  - **Commit**: `fix(mcp): address review - <summary>` (per comment)

- [x] 5.3 Final validation
  - **Do**: Verify ALL completion criteria met:
    1. Run full test suite: `cd mcp-server && bun test`
    2. Verify zero regressions
    3. Check CI: `gh pr checks` all green
    4. Verify modularity: code follows patterns from design
    5. Real-world validation: documented Claude Desktop testing in .progress.md
  - **Verify**: All commands pass, all criteria documented
  - **Done when**: All completion criteria met
  - **Commit**: None

- [x] 5.4 Document completion
  - **Do**:
    1. Update .progress.md with final status
    2. Document any deferred items
    3. Return PR URL
  - **Verify**: `.progress.md` updated with completion status
  - **Done when**: Documentation complete, PR ready for merge
  - **Commit**: `docs(mcp): document completion status`

## Notes

- **POC shortcuts taken**:
  - Error messages may be generic in POC (refined in Phase 2)
  - No retry logic for file operations in POC
  - Claude Desktop testing is manual in POC

- **Production TODOs** (addressed in later phases):
  - Comprehensive error handling (Phase 2)
  - JSON schema validation for state files (Phase 2)
  - Edge case handling (Phase 2)
  - Full test coverage (Phase 3)

## Dependencies

```
Phase 1 (POC) -> Phase 2 (Refactor) -> Phase 3 (Testing) -> Phase 4 (Quality) -> Phase 5 (PR Lifecycle)
```

Within Phase 1:
- 1.1 (repo init) -> 1.2 (mcp-server init) -> 1.3-1.5 (assets) -> 1.6 (checkpoint)
- 1.7-1.9 (lib modules) -> 1.10 (checkpoint)
- 1.11-1.13 (direct tools) -> 1.14 (checkpoint)
- 1.15-1.18 (remaining tools) -> 1.19 (checkpoint)
- 1.20-1.21 (entry point) -> 1.22 (POC validation)
