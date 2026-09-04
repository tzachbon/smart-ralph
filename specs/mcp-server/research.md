---
spec: mcp-server
phase: research
created: 2026-01-26
---

# Research: mcp-server

## Executive Summary

Converting ralph-specum to an MCP server is highly feasible using Bun and the official TypeScript SDK. The approach involves creating a **standalone compiled binary** that:

1. **Works independently** - No Claude Code plugin required
2. **Self-contained** - Agent prompts, templates, and logic embedded at compile time
3. **No runtime dependency** - Users don't need Bun/Node installed
4. **Cross-platform** - Binaries for macOS (arm64 + x64), Linux, Windows via GitHub releases

## External Research

### MCP Protocol Fundamentals

The Model Context Protocol (MCP) is an open standard by Anthropic for LLM-tool integration.

| Component | Description |
|-----------|-------------|
| Transport | stdio (local) or Streamable HTTP (remote) |
| Message Format | JSON-RPC 2.0 |
| Server Capabilities | Tools, Resources, Prompts |
| Latest Spec | 2025-11-25 with parallel tool calls, server-side agent loops |

**Sources**: [MCP Specification](https://modelcontextprotocol.io/specification/2025-11-25), [TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk)

### Best Practices for Bun MCP Servers

1. **Never write to stdout** - corrupts JSON-RPC messages. Use `console.error()` or logging to stderr
2. **Use Zod for schema validation** - required peer dependency for SDK
3. **Shebang for executable** - `#!/usr/bin/env bun` allows direct execution
4. **Use McpServer class** - high-level API from `@modelcontextprotocol/sdk`
5. **StdioServerTransport** - standard transport for CLI tools

**Project Setup Pattern** (from official docs):
```bash
mkdir mcp-server && cd mcp-server
bun init
bun add @modelcontextprotocol/sdk zod
```

**Tool Registration Pattern**:
```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

const server = new McpServer({
  name: "ralph-specum",
  version: "2.8.2"
});

server.registerTool(
  "start",
  {
    description: "Start a new spec or resume existing",
    inputSchema: {
      name: z.string().optional().describe("Spec name (kebab-case)"),
      goal: z.string().optional().describe("Goal description"),
      quick: z.boolean().optional().describe("Skip interactive phases")
    }
  },
  async ({ name, goal, quick }) => {
    // Implementation
    return { content: [{ type: "text", text: "Spec created" }] };
  }
);

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}
main();
```

**Sources**: [DEV.to Bun MCP Guide](https://dev.to/gorosun/building-high-performance-mcp-servers-with-bun-a-complete-guide-32nj), [MCP Build Server Docs](https://modelcontextprotocol.io/docs/develop/build-server)

### Standalone Compiled Binary (User Requirement)

**Build Command:**
```bash
# Single platform
bun build --compile ./src/index.ts --outfile ralph-specum-mcp

# Cross-platform builds for distribution
bun build --compile --target=bun-darwin-arm64 ./src/index.ts --outfile dist/ralph-specum-mcp-darwin-arm64
bun build --compile --target=bun-darwin-x64 ./src/index.ts --outfile dist/ralph-specum-mcp-darwin-x64
bun build --compile --target=bun-linux-x64 ./src/index.ts --outfile dist/ralph-specum-mcp-linux-x64
bun build --compile --target=bun-windows-x64 ./src/index.ts --outfile dist/ralph-specum-mcp-windows-x64.exe
```

**Benefits:**
- Single binary with Bun runtime embedded
- No runtime dependency (Bun/Node not required on user's machine)
- Fast cold start (~95ms vs ~1,270ms for Node.js)
- 61% less memory than Node.js equivalent

**Embedding Assets at Compile Time:**
```typescript
// Agent prompts embedded in binary
import researchAnalyst from "./agents/research-analyst.md" with { type: "text" };
import productManager from "./agents/product-manager.md" with { type: "text" };
// ... etc
```

**Client Configuration** (claude_desktop_config.json):
```json
{
  "mcpServers": {
    "ralph-specum": {
      "command": "/usr/local/bin/ralph-specum-mcp"
    }
  }
}
```

**Distribution (3 methods):**

1. **One-line install script** (recommended for most users):
   ```bash
   curl -fsSL https://raw.githubusercontent.com/tzachbon/smart-ralph/main/install.sh | bash
   ```

2. **npm package** (for Node.js users):
   ```bash
   npm install -g @smart-ralph/ralph-specum-mcp
   # or
   npx @smart-ralph/ralph-specum-mcp
   ```

3. **GitHub Releases** (manual download):
   - Download platform-specific binary from releases page
   - Optional: Homebrew tap for macOS (`brew install smart-ralph/tap/mcp`)

### Install Script Pattern

**install.sh** (hosted in repo root):
```bash
#!/bin/bash
set -e

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
  x86_64) ARCH="x64" ;;
  aarch64|arm64) ARCH="arm64" ;;
esac

# Determine binary name
BINARY="ralph-specum-mcp-${OS}-${ARCH}"
if [ "$OS" = "windows" ]; then
  BINARY="${BINARY}.exe"
fi

# Get latest release
LATEST=$(curl -fsSL https://api.github.com/repos/tzachbon/smart-ralph/releases/latest | grep tag_name | cut -d'"' -f4)

# Download and install
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
echo "Installing ralph-specum-mcp ${LATEST} to ${INSTALL_DIR}..."

curl -fsSL "https://github.com/tzachbon/smart-ralph/releases/download/${LATEST}/${BINARY}" -o /tmp/ralph-specum-mcp
chmod +x /tmp/ralph-specum-mcp
sudo mv /tmp/ralph-specum-mcp "${INSTALL_DIR}/ralph-specum-mcp"

echo "Installed! Run 'ralph-specum-mcp --help' to get started."
echo ""
echo "Add to your MCP client config:"
echo '  "ralph-specum": { "command": "ralph-specum-mcp" }'
```

**Benefits:**
- Single command installation
- Auto-detects OS and architecture
- Downloads correct binary from latest release
- Installs to PATH (/usr/local/bin)
- Prints setup instructions for MCP clients

### npm Package (@smart-ralph/ralph-specum-mcp)

**package.json:**
```json
{
  "name": "@smart-ralph/ralph-specum-mcp",
  "version": "1.0.0",
  "description": "MCP server for spec-driven development",
  "type": "module",
  "bin": {
    "smart-ralph-mcp": "./src/index.ts"
  },
  "files": [
    "src",
    "agents",
    "templates"
  ],
  "scripts": {
    "start": "bun src/index.ts"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0",
    "zod": "^3.25.0"
  },
  "engines": {
    "node": ">=18",
    "bun": ">=1.0"
  }
}
```

**Usage with npx:**
```bash
# Run directly (requires Bun)
npx @smart-ralph/ralph-specum-mcp

# Or install globally
npm install -g @smart-ralph/ralph-specum-mcp
ralph-specum-mcp
```

**Client Configuration (npm):**
```json
{
  "mcpServers": {
    "ralph-specum": {
      "command": "npx",
      "args": ["-y", "@smart-ralph/ralph-specum-mcp"]
    }
  }
}
```

**Note:** npm package requires Bun runtime. For zero-dependency install, use the install script or GitHub releases.

**Sources**: [Bun Single-file Executables](https://bun.sh/docs/bundler/executables), [Build MCP Server Guide](https://mcpcat.io/guides/building-stdio-mcp-server/)

### Prior Art

| Project | Approach | Notes |
|---------|----------|-------|
| [bun-mcp](https://github.com/TomasHubelbauer/bun-mcp) | Bun + SDK | Simple todo list example |
| [mcp-bun](https://github.com/carlosedp/mcp-bun) | Bun runtime tools | Full-featured Bun tooling |
| [MCP Proxy Wrapper](https://mcp-proxy.dev/) | Plugin architecture | Hook-based tool interception |

### Pitfalls to Avoid

1. **stdout corruption** - Any `console.log()` breaks JSON-RPC. Use `console.error()` only
2. **SSE deprecation** - Use Streamable HTTP or stdio, not legacy SSE
3. **Blocking operations** - Long-running tools should use Tasks (new in Nov 2025 spec)
4. **Missing shebang** - Without `#!/usr/bin/env bun`, executable won't run directly
5. **Zod version mismatch** - SDK requires Zod v3.25+ with `zod/v4` imports

## Codebase Analysis

### Existing Plugin Structure

```
plugins/ralph-specum/
├── .claude-plugin/plugin.json   # Plugin manifest (name, version, description)
├── agents/                      # 8 agents: research-analyst, product-manager, etc.
├── commands/                    # 14 commands: start, research, requirements, etc.
├── hooks/                       # Stop watcher (logging only)
├── templates/                   # Spec file templates (6 files)
├── schemas/                     # JSON schema for spec validation
└── skills/                      # 7 skills for progressive disclosure
```

### Commands to Expose as MCP Tools

| Plugin Command | MCP Tool Name | Input Schema | Notes |
|----------------|---------------|--------------|-------|
| `/ralph-specum:start` | `ralph_start` | name?, goal?, quick?, fresh? | Entry point |
| `/ralph-specum:research` | `ralph_research` | spec_name? | Parallel agent delegation |
| `/ralph-specum:requirements` | `ralph_requirements` | spec_name? | Product manager delegation |
| `/ralph-specum:design` | `ralph_design` | spec_name? | Architect delegation |
| `/ralph-specum:tasks` | `ralph_tasks` | spec_name? | Task planner delegation |
| `/ralph-specum:implement` | `ralph_implement` | max_task_iterations? | Execution loop |
| `/ralph-specum:status` | `ralph_status` | - | Show all specs status |
| `/ralph-specum:switch` | `ralph_switch` | name | Switch active spec |
| `/ralph-specum:cancel` | `ralph_cancel` | spec_name? | Cancel and cleanup |
| `/ralph-specum:refactor` | `ralph_refactor` | spec_name? | Update spec files |

### State Files (Must Be Preserved)

| File | Purpose | Location |
|------|---------|----------|
| `.current-spec` | Active spec pointer | `./specs/.current-spec` |
| `.ralph-state.json` | Execution state | `./specs/<name>/.ralph-state.json` |
| `.progress.md` | Progress tracking | `./specs/<name>/.progress.md` |

### Agent Delegation Pattern

Commands don't implement logic directly. They coordinate:
1. Read state/progress files
2. Invoke subagent via Task tool (research-analyst, product-manager, etc.)
3. Subagent writes output (research.md, requirements.md, etc.)
4. Command updates state, outputs next steps

**Challenge**: MCP tools don't have Task tool. Agent delegation must be reimplemented as:
- Direct function calls to agent prompts
- Or: Instruct the LLM client to handle multi-step workflows

### Dependencies

| Dependency | Current | Required |
|------------|---------|----------|
| Claude Code Plugin System | v2.8.2 | Maintain compatibility |
| Ralph Loop Plugin | External | For /implement execution |
| Git | CLI | For state/commits |
| Bash | CLI | For scripts |

### Constraints

1. **No Task tool** - MCP servers can't spawn subagents. Logic must be in tool or delegated back to client
2. **No AskUserQuestion** - MCP has no built-in user prompting. Client must handle via prompts
3. **Stateless calls** - Each tool call is independent. State via files only
4. **Working directory** - Server runs from configured cwd, must handle relative paths
5. **Execution environment** - Bun must be installed on user's system

## Related Specs

| Spec | Relevance | Relationship | May Need Update |
|------|-----------|--------------|-----------------|
| ralph-speckit | Medium | Similar plugin architecture, uses spec-kit methodology | No - independent plugin |
| implement-ralph-wiggum | Medium | Ralph Wiggum integration pattern | No - MCP server won't use Ralph Loop |

## Quality Commands

| Type | Command | Source |
|------|---------|--------|
| Lint | Not found | No package.json in repo root |
| TypeCheck | Not found | Will need for MCP server |
| Test | Not found | Will need for MCP server |
| Build | Not found | Will need `bun build` |

**Note**: This is a markdown-only plugin currently. MCP server will introduce TypeScript build pipeline.

**Local CI** (proposed): `bun run lint && bun run typecheck && bun test && bun run build`

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | High | MCP SDK + Bun is well-documented path |
| Effort Estimate | M-L | 10-15 tools, state management, testing |
| Risk Level | Medium | Agent delegation pattern needs redesign |
| Breaking Changes | Low | Plugin remains separate, MCP is additive |

## Technical Approach: Standalone MCP Server

### Architecture (User Requirement: Standalone Executable)

The MCP server is **self-contained** and works independently of the Claude Code plugin:

```
ralph-specum-mcp/
├── src/
│   ├── index.ts               # MCP server entry point
│   ├── tools/                 # Tool implementations
│   │   ├── start.ts           # Create spec, init state
│   │   ├── research.ts        # Return research instructions
│   │   ├── requirements.ts    # Return requirements instructions
│   │   ├── design.ts          # Return design instructions
│   │   ├── tasks.ts           # Return task planning instructions
│   │   ├── implement.ts       # Return execution instructions
│   │   ├── status.ts          # Direct: read and format status
│   │   ├── switch.ts          # Direct: update .current-spec
│   │   ├── cancel.ts          # Direct: cleanup state files
│   │   └── help.ts            # Direct: return usage info
│   ├── agents/                # Agent prompts (embedded at compile)
│   │   ├── research-analyst.md
│   │   ├── product-manager.md
│   │   ├── architect-reviewer.md
│   │   ├── task-planner.md
│   │   └── spec-executor.md
│   ├── templates/             # Spec templates (embedded at compile)
│   │   ├── research.md
│   │   ├── requirements.md
│   │   └── ...
│   └── lib/
│       ├── state.ts           # State file management
│       ├── files.ts           # File operations
│       └── git.ts             # Git CLI wrapper
├── package.json
├── tsconfig.json
└── README.md
```

**Key Design Decisions:**

1. **Self-contained binary** - All agent prompts and templates embedded at compile time
2. **No plugin dependency** - Works in any MCP-compatible client without Claude Code
3. **State file compatibility** - Same .ralph-state.json format if user also has plugin
4. **Instruction-return pattern** - Complex tools return prompts for LLM to execute

### Plugin Relationship

| Scenario | Behavior |
|----------|----------|
| MCP server only | Fully functional, standalone workflow |
| Plugin only | Works as before in Claude Code |
| Both installed | Compatible - same state files, can switch between |

**Note**: The existing plugin remains unchanged. MCP server is a separate, independent implementation.

## Instruction-Return Pattern (Core Architecture)

### Key Insight

MCP servers cannot spawn subagents (no Task tool equivalent). The solution is to return **structured instructions** that guide the LLM client to perform the workflow.

### Tool Categories

| Category | Tools | Implementation |
|----------|-------|----------------|
| **Direct** | status, switch, cancel, help | Execute immediately, return results |
| **Instruction** | research, requirements, design, tasks | Return agent prompt + context + instructions |
| **Orchestrated** | implement, start --quick | Return multi-step workflow instructions |

### Example: `ralph_research` Tool

```typescript
server.tool("ralph_research", {
  specName: z.string(),
}, async ({ specName }) => {
  // Read current state
  const state = await readState(specName);
  const progress = await readProgress(specName);

  // Get embedded agent prompt
  const agentPrompt = EMBEDDED_AGENTS.researchAnalyst;

  return {
    content: [{
      type: "text",
      text: `## Research Phase for "${specName}"

### Your Task
Execute research for this spec using the guidance below.

### Goal
${progress.goal}

### Research Agent Instructions
${agentPrompt}

### Expected Actions
1. Use web search to find best practices for: ${progress.goal}
2. Analyze the codebase for existing patterns
3. Document findings in ./specs/${specName}/research.md
4. Update ./specs/${specName}/.progress.md with learnings

### When Complete
Call \`ralph_complete_phase\` tool with:
- specName: "${specName}"
- phase: "research"
- summary: <brief summary of findings>`
    }]
  };
});
```

### Example Workflow in Cursor/Claude Desktop

```
User: "Start a new spec for user authentication"
↓
LLM calls: ralph_start({ name: "user-auth", goal: "Add JWT authentication" })
↓
MCP returns: "Spec created at ./specs/user-auth/. Call ralph_research to begin."
↓
LLM calls: ralph_research({ specName: "user-auth" })
↓
MCP returns: Research instructions + embedded agent prompt
↓
LLM executes research (web search, codebase analysis)
↓
LLM writes ./specs/user-auth/research.md
↓
LLM calls: ralph_complete_phase({ specName: "user-auth", phase: "research" })
↓
MCP updates state, returns: "Research complete. Call ralph_requirements to continue."
```

This approach:
- Keeps MCP server simple (no complex orchestration)
- Leverages LLM client's full capabilities (web search, file editing, etc.)
- Works with any MCP-compatible client (Cursor, Continue, Claude Desktop, etc.)

## Recommendations for Requirements

1. **Standalone compiled binary** - Primary distribution via GitHub releases
2. **Embed all assets** - Agent prompts, templates bundled at compile time
3. **Cross-platform builds** - macOS (arm64 + x64), Linux, Windows
4. **Instruction-return pattern** - Complex tools return prompts for LLM client
5. **Direct tools for simple ops** - status, switch, cancel execute immediately
6. **State file compatibility** - Same .ralph-state.json format as plugin
7. **stdio transport only** - Standard for local MCP servers
8. **Test with multiple clients** - Claude Desktop, Cursor, Continue

## Resolved Questions

| Question | Decision |
|----------|----------|
| Distribution method | Compiled binary via GitHub releases (not bunx/npx) |
| Runtime dependency | None - Bun embedded in binary |
| Plugin relationship | Independent, standalone (not a wrapper) |
| Complex tool pattern | Instruction-return (LLM client executes) |
| Asset embedding | Compile-time bundling of prompts/templates |

## Open Questions for Requirements

1. **Interview questions** - Skip in MCP version or simplify?
   - Likely: Skip, use goal from tool input directly

2. **Implement command** - Full task loop or single-task execution?
   - Option A: Return full coordinator prompt, LLM manages loop
   - Option B: `ralph_execute_task` for single task, client loops

3. **Quick mode** - Support or defer to later version?
   - Likely: Support - important for non-interactive use

4. **Phase completion** - Explicit tool or automatic detection?
   - Likely: `ralph_complete_phase` tool for explicit state transitions

## Sources

### Official Documentation
- [MCP Specification 2025-11-25](https://modelcontextprotocol.io/specification/2025-11-25)
- [MCP Build Server Guide](https://modelcontextprotocol.io/docs/develop/build-server)
- [TypeScript SDK GitHub](https://github.com/modelcontextprotocol/typescript-sdk)

### Tutorials & Guides
- [Building High-Performance MCP Servers with Bun](https://dev.to/gorosun/building-high-performance-mcp-servers-with-bun-a-complete-guide-32nj)
- [Build an MCP Server from Scratch](https://akoskm.com/build-an-mcp-server-from-scratch/)
- [Building a Simple MCP Server with Bun](https://www.groff.dev/blog/building-simple-remote-mcp-server-bun)

### Example Projects
- [bun-mcp](https://github.com/TomasHubelbauer/bun-mcp) - Bun MCP server demo
- [mcp-bun](https://github.com/carlosedp/mcp-bun) - Bun runtime MCP server

### Codebase Files
- `/Users/zachbonfil/projects/smart-ralph-mcp-server/plugins/ralph-specum/.claude-plugin/plugin.json`
- `/Users/zachbonfil/projects/smart-ralph-mcp-server/plugins/ralph-specum/commands/*.md`
- `/Users/zachbonfil/projects/smart-ralph-mcp-server/plugins/ralph-specum/agents/*.md`
