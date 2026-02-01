---
spec: mcp-server
phase: requirements
created: 2026-01-26
---

# Requirements: Ralph Specum MCP Server

## Goal

Create a standalone MCP server that exposes ralph-specum workflows to any MCP-compatible client (Cursor, Continue, Claude Desktop), enabling spec-driven development outside Claude Code with feature parity and one-line installation.

## User Decisions (from Interview)

| Topic | Decision |
|-------|----------|
| Primary users | End users via MCP clients (Cursor, Continue, Claude Desktop) |
| Priority tradeoffs | Speed of delivery - MVP fast, iterate later |
| Success criteria | Feature parity + major client compatibility + easy install |
| Distribution | Standalone compiled binary (no runtime dependency) |

## User Stories

### US-1: Install MCP Server

**As a** developer using an MCP-compatible client
**I want to** install the ralph-specum MCP server with a single command
**So that** I can start using spec-driven development without complex setup

**Acceptance Criteria:**
- [ ] AC-1.1: `curl -fsSL .../install.sh | bash` downloads correct binary for OS/arch
- [ ] AC-1.2: Binary auto-detects macOS (arm64/x64), Linux (x64), Windows (x64)
- [ ] AC-1.3: Installs to /usr/local/bin (configurable via INSTALL_DIR)
- [ ] AC-1.4: Prints MCP client config snippet after install
- [ ] AC-1.5: Running `ralph-specum-mcp --help` shows usage info

### US-2: Configure MCP Client

**As a** developer
**I want to** add the server to my MCP client config
**So that** my AI assistant can access ralph tools

**Acceptance Criteria:**
- [ ] AC-2.1: Server works with `{ "command": "/path/to/ralph-specum-mcp" }` config
- [ ] AC-2.2: Server starts via stdio transport (JSON-RPC 2.0)
- [ ] AC-2.3: Server advertises all tools on connection handshake
- [ ] AC-2.4: Server works in Claude Desktop without errors
- [ ] AC-2.5: Server works in Cursor without errors

### US-3: Start New Spec

**As a** developer
**I want to** create a new spec via MCP tool call
**So that** I can begin spec-driven development for a feature

**Acceptance Criteria:**
- [ ] AC-3.1: `ralph_start` tool accepts name (optional), goal (optional), quick (optional)
- [ ] AC-3.2: Creates `./specs/<name>/` directory structure
- [ ] AC-3.3: Initializes `.progress.md` with goal and interview responses placeholder
- [ ] AC-3.4: Creates `.ralph-state.json` with phase: "research"
- [ ] AC-3.5: Updates `./specs/.current-spec` with spec name
- [ ] AC-3.6: Returns success message with next step instruction

### US-4: Run Research Phase

**As a** developer
**I want to** run research for my spec
**So that** best practices and codebase patterns inform my design

**Acceptance Criteria:**
- [ ] AC-4.1: `ralph_research` tool accepts spec_name (optional, defaults to current)
- [ ] AC-4.2: Returns embedded research-analyst agent prompt
- [ ] AC-4.3: Includes goal context from .progress.md
- [ ] AC-4.4: Instructs LLM to write findings to `./specs/<name>/research.md`
- [ ] AC-4.5: Includes expected actions and completion criteria

### US-5: Run Requirements Phase

**As a** developer
**I want to** generate requirements from research
**So that** I have clear user stories and acceptance criteria

**Acceptance Criteria:**
- [ ] AC-5.1: `ralph_requirements` tool accepts spec_name (optional)
- [ ] AC-5.2: Returns embedded product-manager agent prompt
- [ ] AC-5.3: Includes research summary from research.md
- [ ] AC-5.4: Instructs LLM to write to `./specs/<name>/requirements.md`
- [ ] AC-5.5: Includes requirements template structure

### US-6: Run Design Phase

**As a** developer
**I want to** create technical design from requirements
**So that** implementation has clear architecture guidance

**Acceptance Criteria:**
- [ ] AC-6.1: `ralph_design` tool accepts spec_name (optional)
- [ ] AC-6.2: Returns embedded architect-reviewer agent prompt
- [ ] AC-6.3: Includes requirements summary
- [ ] AC-6.4: Instructs LLM to write to `./specs/<name>/design.md`

### US-7: Generate Tasks

**As a** developer
**I want to** break design into executable tasks
**So that** I have a clear implementation roadmap

**Acceptance Criteria:**
- [ ] AC-7.1: `ralph_tasks` tool accepts spec_name (optional)
- [ ] AC-7.2: Returns embedded task-planner agent prompt
- [ ] AC-7.3: Includes design summary and POC-first workflow guidance
- [ ] AC-7.4: Instructs LLM to write to `./specs/<name>/tasks.md`
- [ ] AC-7.5: Tasks follow checkbox format with phases

### US-8: Execute Implementation

**As a** developer
**I want to** execute tasks with fresh context per task
**So that** complex features get implemented systematically

**Acceptance Criteria:**
- [ ] AC-8.1: `ralph_implement` tool accepts max_iterations (optional)
- [ ] AC-8.2: Returns embedded spec-executor prompt + coordinator instructions
- [ ] AC-8.3: Includes current task from tasks.md
- [ ] AC-8.4: Instructs LLM on task completion protocol
- [ ] AC-8.5: Supports iterative execution (LLM calls tool repeatedly)

### US-9: Check Spec Status

**As a** developer
**I want to** see status of all specs
**So that** I know what's in progress and what's complete

**Acceptance Criteria:**
- [ ] AC-9.1: `ralph_status` tool requires no parameters
- [ ] AC-9.2: Lists all specs in ./specs/ directory
- [ ] AC-9.3: Shows phase, task progress, active spec indicator
- [ ] AC-9.4: Executes directly (no instruction-return pattern)

### US-10: Switch Active Spec

**As a** developer
**I want to** switch between specs
**So that** I can work on multiple features

**Acceptance Criteria:**
- [ ] AC-10.1: `ralph_switch` tool accepts name (required)
- [ ] AC-10.2: Updates `./specs/.current-spec`
- [ ] AC-10.3: Returns spec status after switch
- [ ] AC-10.4: Errors if spec doesn't exist

### US-11: Cancel Spec

**As a** developer
**I want to** cancel and clean up a spec
**So that** I can abandon work without orphaned state

**Acceptance Criteria:**
- [ ] AC-11.1: `ralph_cancel` tool accepts spec_name (optional)
- [ ] AC-11.2: Deletes `.ralph-state.json` for the spec
- [ ] AC-11.3: Optionally deletes entire spec directory (with confirmation)
- [ ] AC-11.4: Updates .current-spec if cancelled spec was active

### US-12: Complete Phase

**As a** developer
**I want to** mark a phase complete
**So that** state transitions correctly to next phase

**Acceptance Criteria:**
- [ ] AC-12.1: `ralph_complete_phase` tool accepts spec_name, phase, summary
- [ ] AC-12.2: Updates `.ralph-state.json` with next phase
- [ ] AC-12.3: Appends summary to `.progress.md`
- [ ] AC-12.4: Returns next step instruction

### US-13: Get Help

**As a** developer
**I want to** get usage information
**So that** I understand available tools and workflow

**Acceptance Criteria:**
- [ ] AC-13.1: `ralph_help` tool requires no parameters
- [ ] AC-13.2: Lists all tools with descriptions
- [ ] AC-13.3: Explains typical workflow sequence
- [ ] AC-13.4: Includes example usage

### US-14: Run via npx (npm Distribution)

**As a** developer
**I want to** run the MCP server via `npx @smart-ralph/ralph-specum-mcp` without global install
**So that** I can quickly try the server or use it in CI/CD without managing installations

**Acceptance Criteria:**
- [ ] AC-14.1: Package published to npm under `@smart-ralph/ralph-specum-mcp` scope
- [ ] AC-14.2: `npx @smart-ralph/ralph-specum-mcp` starts the MCP server
- [ ] AC-14.3: MCP client config works with npx command: `{ "command": "npx", "args": ["@smart-ralph/ralph-specum-mcp"] }`
- [ ] AC-14.4: Package requires Bun runtime (documented prerequisite)
- [ ] AC-14.5: README documents npx usage alongside compiled binary option
- [ ] AC-14.6: Package.json bin field points to TypeScript entry point for Bun execution

### US-15: MCP Standard Logging

**As a** developer debugging MCP server issues
**I want to** receive structured log messages via MCP notifications
**So that** I can diagnose problems without corrupting the JSON-RPC transport

**Acceptance Criteria:**
- [ ] AC-15.1: Server sends `logging/message` notifications per MCP spec
- [ ] AC-15.2: All logs written to stderr only (never stdout)
- [ ] AC-15.3: Log format is structured JSON: `{ level, logger, data, timestamp }`
- [ ] AC-15.4: Supports log levels: debug, info, warning, error
- [ ] AC-15.5: Logger name identifies component (e.g., "ralph.tools", "ralph.state")
- [ ] AC-15.6: No console.log/console.info in production code paths

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | Compile to standalone binary with embedded Bun runtime | P0 | Binary runs without Bun/Node installed |
| FR-2 | Embed agent prompts at compile time | P0 | No external file dependencies |
| FR-3 | Embed spec templates at compile time | P0 | Templates available without file system |
| FR-4 | Use stdio transport for MCP communication | P0 | Works with all major MCP clients |
| FR-5 | Implement 10 MCP tools (start, research, requirements, design, tasks, implement, status, switch, cancel, help) | P0 | All tools registered and callable |
| FR-6 | Add phase completion tool | P1 | State transitions explicit |
| FR-7 | Support quick mode (skip interviews) | P1 | `quick: true` skips interactive phases |
| FR-8 | Cross-platform builds (macOS arm64/x64, Linux x64, Windows x64) | P1 | All binaries in GitHub release |
| FR-9 | Install script with OS/arch detection | P1 | Single curl command installs |
| FR-10 | npm package distribution | P2 | `npx @smart-ralph/ralph-specum-mcp` works |
| FR-11 | State file compatibility with plugin | P2 | Same .ralph-state.json format |
| FR-12 | MCP standard logging via `logging/message` notifications | P0 | Structured logs to stderr, never stdout |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Binary startup time | Cold start | < 200ms |
| NFR-2 | Binary size | Compiled size | < 100MB |
| NFR-3 | Memory usage | Peak RSS | < 50MB during operation |
| NFR-4 | Response time | Tool call latency | < 100ms for direct tools |
| NFR-5 | Compatibility | MCP clients tested | Claude Desktop, Cursor, Continue |
| NFR-6 | Reliability | No stdout corruption | Zero console.log in production |
| NFR-7 | Logging compliance | MCP logging/message spec | All logs via notifications, stderr only |

## Glossary

- **MCP**: Model Context Protocol - Anthropic's standard for LLM-tool integration
- **stdio transport**: Communication via stdin/stdout using JSON-RPC 2.0
- **Instruction-return pattern**: Tool returns instructions for LLM to execute rather than executing directly
- **Direct tool**: Tool that executes immediately and returns results
- **Spec**: A structured feature specification with research, requirements, design, and tasks
- **Phase**: One stage of spec development (research, requirements, design, tasks, implement)

## Out of Scope (MVP)

- Remote/HTTP transport (stdio only for MVP)
- MCP Resources capability (tools only) - deferred to v2, considered for exposing spec files
- MCP Prompts capability (tools only) - deferred to v2, considered for workflow templates
- Interview questions in MCP version (use goal directly)
- Homebrew tap distribution
- Auto-update mechanism
- Windows ARM64 builds
- Refactor command (can be added later)

## Dependencies

| Dependency | Type | Notes |
|------------|------|-------|
| Bun 1.0+ | Build-time | For compilation only |
| @modelcontextprotocol/sdk | Runtime (bundled) | Official MCP SDK |
| Zod 3.25+ | Runtime (bundled) | Schema validation |
| Git CLI | Runtime (user's system) | For git operations |

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Client incompatibility | Medium | High | Test with multiple clients early |
| Binary size too large | Low | Medium | Bun compile is typically efficient |
| Instruction pattern confusion | Medium | Medium | Clear documentation, examples |
| State file corruption | Low | High | Validate JSON before write |

## Success Criteria

1. **Installation**: User can install with single curl command in < 30 seconds
2. **Compatibility**: Works in Claude Desktop AND Cursor without modification
3. **Feature parity**: All 10 core tools functional (excluding refactor)
4. **Documentation**: README with clear setup instructions for each client
5. **Reliability**: No crashes or stdout corruption in 1 hour of usage

## MVP Tool Summary

| Tool | Type | Input | Output |
|------|------|-------|--------|
| `ralph_start` | Direct | name?, goal?, quick? | Creates spec, returns next step |
| `ralph_research` | Instruction | spec_name? | Agent prompt + context |
| `ralph_requirements` | Instruction | spec_name? | Agent prompt + context |
| `ralph_design` | Instruction | spec_name? | Agent prompt + context |
| `ralph_tasks` | Instruction | spec_name? | Agent prompt + context |
| `ralph_implement` | Instruction | max_iterations? | Executor prompt + current task |
| `ralph_status` | Direct | - | Formatted status |
| `ralph_switch` | Direct | name | Confirmation |
| `ralph_cancel` | Direct | spec_name? | Cleanup confirmation |
| `ralph_complete_phase` | Direct | spec_name, phase, summary | Next step |
| `ralph_help` | Direct | - | Usage info |

## Next Steps

1. Approve requirements with user
2. Run `/ralph-specum:design` to create technical architecture
3. Design tool schemas and embedded asset structure
4. Plan build and release pipeline
