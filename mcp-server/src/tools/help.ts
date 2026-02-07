/**
 * ralph_help tool handler.
 * Returns usage information and tool list.
 * @module tools/help
 */

import type { MCPLogger } from "../lib/logger";
import type { ToolResult, ToolInfo } from "../lib/types";
import { handleUnexpectedError } from "../lib/errors";

/**
 * List of all available tools.
 */
const TOOLS: ToolInfo[] = [
  {
    name: "ralph_start",
    description: "Create a new spec and begin the workflow",
    args: "name?, goal?, quick?",
  },
  {
    name: "ralph_research",
    description: "Run research phase for current spec",
    args: "spec_name?",
  },
  {
    name: "ralph_requirements",
    description: "Generate requirements from research",
    args: "spec_name?",
  },
  {
    name: "ralph_design",
    description: "Create technical design from requirements",
    args: "spec_name?",
  },
  {
    name: "ralph_tasks",
    description: "Generate implementation tasks from design",
    args: "spec_name?",
  },
  {
    name: "ralph_implement",
    description: "Execute tasks with spec-executor",
    args: "max_iterations?",
  },
  {
    name: "ralph_complete_phase",
    description: "Mark a phase as complete and advance",
    args: "phase, summary, spec_name?",
  },
  {
    name: "ralph_status",
    description: "List all specs with phase and progress",
    args: "(none)",
  },
  {
    name: "ralph_switch",
    description: "Switch to a different spec",
    args: "name",
  },
  {
    name: "ralph_cancel",
    description: "Cancel spec and optionally delete files",
    args: "spec_name?, delete_files?",
  },
  {
    name: "ralph_help",
    description: "Show this help information",
    args: "(none)",
  },
];

/**
 * Handle the ralph_help tool.
 *
 * Returns comprehensive usage information including:
 * - Workflow overview
 * - All available tools with descriptions and arguments
 * - Quick start example
 * - File structure information
 *
 * @param logger - Optional logger for error logging
 * @returns MCP-compliant tool result with formatted help text
 */
export function handleHelp(logger?: MCPLogger): ToolResult {
  try {
    const lines: string[] = [];

    lines.push("# Ralph Specum MCP Server");
    lines.push("");
    lines.push("Spec-driven development workflow for AI-assisted coding.");
    lines.push("");
    lines.push("## Workflow");
    lines.push("");
    lines.push("1. **ralph_start** - Create a new spec with a goal");
    lines.push("2. **ralph_research** - Analyze codebase and gather context");
    lines.push("3. **ralph_requirements** - Define user stories and acceptance criteria");
    lines.push("4. **ralph_design** - Create technical architecture");
    lines.push("5. **ralph_tasks** - Generate implementation tasks");
    lines.push("6. **ralph_implement** - Execute tasks one by one");
    lines.push("");
    lines.push("Use **ralph_complete_phase** after each phase (research through tasks).");
    lines.push("");
    lines.push("## Available Tools");
    lines.push("");
    lines.push("| Tool | Description | Arguments |");
    lines.push("|------|-------------|-----------|");

    for (const tool of TOOLS) {
      lines.push(`| ${tool.name} | ${tool.description} | ${tool.args} |`);
    }

    lines.push("");
    lines.push("## Quick Start");
    lines.push("");
    lines.push("```");
    lines.push("ralph_start({ goal: 'Add user authentication', quick: true })");
    lines.push("```");
    lines.push("");
    lines.push("This creates a spec and immediately starts the research phase.");
    lines.push("");
    lines.push("## More Information");
    lines.push("");
    lines.push("- Specs are stored in `./specs/<name>/`");
    lines.push("- Current spec tracked in `./specs/.current-spec`");
    lines.push("- State stored in `.ralph-state.json` within spec directory");
    lines.push("- Use `ralph_status` to see all specs and their progress");

    return {
      content: [
        {
          type: "text",
          text: lines.join("\n"),
        },
      ],
    };
  } catch (error) {
    return handleUnexpectedError(error, "ralph_help", logger);
  }
}
