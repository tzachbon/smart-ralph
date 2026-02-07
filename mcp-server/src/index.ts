#!/usr/bin/env bun
/**
 * MCP Server entry point for Ralph Specum.
 * Creates an MCP server with all Ralph tools and connects via stdio transport.
 */

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

import { MCPLogger } from "./lib/logger";
import { StateManager } from "./lib/state";
import { FileManager } from "./lib/files";
import { registerTools } from "./tools";

// Get version from package.json
import packageJson from "../package.json";

const SERVER_NAME = "ralph-specum";
const SERVER_VERSION = packageJson.version;

/**
 * Print version and exit.
 */
function printVersion(): void {
  console.log(`${SERVER_NAME} v${SERVER_VERSION}`);
  process.exit(0);
}

/**
 * Print usage help and exit.
 */
function printHelp(): void {
  console.log(`${SERVER_NAME} v${SERVER_VERSION}

MCP server for Ralph Specum spec-driven development.

USAGE:
  ralph-specum-mcp [OPTIONS]

OPTIONS:
  --help, -h      Show this help message
  --version, -v   Show version number

DESCRIPTION:
  This MCP server provides tools for spec-driven development workflows.
  It communicates via stdio using the Model Context Protocol (MCP).

TOOLS:
  ralph_start           Start a new spec or resume existing
  ralph_status          Show current spec status
  ralph_switch          Switch active spec
  ralph_cancel          Cancel current spec
  ralph_help            Show available tools
  ralph_complete_phase  Mark a phase as complete
  ralph_research        Get research phase instructions
  ralph_requirements    Get requirements phase instructions
  ralph_design          Get design phase instructions
  ralph_tasks           Get tasks phase instructions
  ralph_implement       Get implementation instructions

CONFIGURATION:
  Add to your MCP client config (e.g., Claude Desktop):

  {
    "mcpServers": {
      "ralph-specum": {
        "command": "/path/to/ralph-specum-mcp"
      }
    }
  }

For more information, visit: https://github.com/smart-ralph/ralph-specum-mcp
`);
  process.exit(0);
}

/**
 * Parse CLI arguments and handle flags.
 * Returns true if server should start, false if handled by flag.
 */
function handleCliFlags(): boolean {
  const args = process.argv.slice(2);

  for (const arg of args) {
    if (arg === "--help" || arg === "-h") {
      printHelp();
      return false;
    }
    if (arg === "--version" || arg === "-v") {
      printVersion();
      return false;
    }
  }

  return true;
}

/**
 * Main entry point - starts the MCP server.
 */
async function main(): Promise<void> {
  // Handle CLI flags first
  if (!handleCliFlags()) {
    return;
  }
  const logger = new MCPLogger(SERVER_NAME);

  logger.info("Starting MCP server", {
    name: SERVER_NAME,
    version: SERVER_VERSION,
  });

  // Create server instance
  const server = new McpServer({
    name: SERVER_NAME,
    version: SERVER_VERSION,
  });

  // Initialize managers
  const fileManager = new FileManager(undefined, logger);
  const stateManager = new StateManager(logger);

  // Register all tools with logger for error handling
  registerTools(server, fileManager, stateManager, logger);

  logger.info("Tools registered", { count: 11 });

  // Create stdio transport
  const transport = new StdioServerTransport();

  // Connect server to transport
  await server.connect(transport);

  logger.info("Server connected and ready");
}

// Run the server
main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
