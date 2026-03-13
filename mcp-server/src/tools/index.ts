/**
 * Tool registration barrel.
 * Exports all tool handlers and a registration function for McpServer.
 * @module tools
 */

import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import type { CallToolResult } from "@modelcontextprotocol/sdk/types.js";
import type { FileManager } from "../lib/files";
import type { StateManager } from "../lib/state";
import type { MCPLogger } from "../lib/logger";
import type { ToolResult } from "../lib/types";

// Import tool handlers
import { handleStatus } from "./status";
import { handleHelp } from "./help";
import { handleSwitch, SwitchInputSchema } from "./switch";
import { handleCancel, CancelInputSchema } from "./cancel";
import { handleStart, StartInputSchema } from "./start";
import { handleCompletePhase, CompletePhaseInputSchema } from "./complete-phase";
import { handleResearch, ResearchInputSchema } from "./research";
import { handleRequirements, RequirementsInputSchema } from "./requirements";
import { handleDesign, DesignInputSchema } from "./design";
import { handleTasks, TasksInputSchema } from "./tasks";
import { handleImplement, ImplementInputSchema } from "./implement";

/**
 * Convert internal ToolResult to MCP SDK CallToolResult.
 * The MCP SDK expects an index signature which our internal type lacks.
 *
 * @param result - Internal tool result
 * @returns MCP SDK compatible CallToolResult
 */
function toCallToolResult(result: ToolResult): CallToolResult {
  return { ...result } as CallToolResult;
}

// Re-export all handlers for direct use
export {
  handleStatus,
  handleHelp,
  handleSwitch,
  handleCancel,
  handleStart,
  handleCompletePhase,
  handleResearch,
  handleRequirements,
  handleDesign,
  handleTasks,
  handleImplement,
};

// Re-export all schemas for external use
export {
  SwitchInputSchema,
  CancelInputSchema,
  StartInputSchema,
  CompletePhaseInputSchema,
  ResearchInputSchema,
  RequirementsInputSchema,
  DesignInputSchema,
  TasksInputSchema,
  ImplementInputSchema,
};

// Re-export input types
export type { SwitchInput } from "./switch";
export type { CancelInput } from "./cancel";
export type { StartInput } from "./start";
export type { CompletePhaseInput } from "./complete-phase";
export type { ResearchInput } from "./research";
export type { RequirementsInput } from "./requirements";
export type { DesignInput } from "./design";
export type { TasksInput } from "./tasks";
export type { ImplementInput } from "./implement";

/** Total number of registered tools */
const TOOL_COUNT = 11;

/**
 * Register all Ralph tools with an McpServer instance.
 *
 * Registers all 11 Ralph tools with their schemas, descriptions, and handlers.
 * Tools are:
 * - ralph_status: List all specs with phase and progress
 * - ralph_help: Show usage information and tool list
 * - ralph_switch: Switch to a different spec
 * - ralph_cancel: Cancel a spec and optionally delete files
 * - ralph_start: Create a new spec and begin workflow
 * - ralph_complete_phase: Mark a phase as complete
 * - ralph_research: Get research phase instructions
 * - ralph_requirements: Get requirements phase instructions
 * - ralph_design: Get design phase instructions
 * - ralph_tasks: Get tasks phase instructions
 * - ralph_implement: Get implementation instructions
 *
 * @param server - The McpServer instance to register tools with
 * @param fileManager - FileManager instance for spec file operations
 * @param stateManager - StateManager instance for state file operations
 * @param logger - Optional MCPLogger instance for error logging
 *
 * @example
 * ```typescript
 * const server = new McpServer({ name: "ralph-specum", version: "1.0.0" });
 * const fileManager = new FileManager();
 * const stateManager = new StateManager();
 * const logger = new MCPLogger();
 *
 * registerTools(server, fileManager, stateManager, logger);
 * ```
 */
export function registerTools(
  server: McpServer,
  fileManager: FileManager,
  stateManager: StateManager,
  logger?: MCPLogger
): void {
  // 1. ralph_status - List all specs with phase and progress
  server.registerTool(
    "ralph_status",
    {
      description:
        "List all specs with their current phase and task progress. Shows which spec is currently active.",
      inputSchema: {},
    },
    async () => {
      return toCallToolResult(handleStatus(fileManager, stateManager, logger));
    }
  );

  // 2. ralph_help - Show usage information
  server.registerTool(
    "ralph_help",
    {
      description:
        "Show usage information and list all available Ralph tools with their descriptions and arguments.",
      inputSchema: {},
    },
    async () => {
      return toCallToolResult(handleHelp(logger));
    }
  );

  // 3. ralph_switch - Switch to a different spec
  server.registerTool(
    "ralph_switch",
    {
      description:
        "Switch the active spec to a different one. The specified spec must exist.",
      inputSchema: {
        name: SwitchInputSchema.shape.name.describe("Name of the spec to switch to"),
      },
    },
    async (input) => {
      return toCallToolResult(handleSwitch(fileManager, input, logger));
    }
  );

  // 4. ralph_cancel - Cancel a spec and optionally delete files
  server.registerTool(
    "ralph_cancel",
    {
      description:
        "Cancel a spec by deleting its state file. Optionally delete all spec files. Uses current spec if not specified.",
      inputSchema: {
        spec_name: CancelInputSchema.shape.spec_name.describe(
          "Name of the spec to cancel (uses current spec if not provided)"
        ),
        delete_files: CancelInputSchema.shape.delete_files.describe(
          "Whether to delete the spec directory and all files (default: false)"
        ),
      },
    },
    async (input) => {
      return toCallToolResult(handleCancel(fileManager, stateManager, input, logger));
    }
  );

  // 5. ralph_start - Create a new spec
  server.registerTool(
    "ralph_start",
    {
      description:
        "Create a new spec and begin the workflow. Initializes the spec directory with progress file and state.",
      inputSchema: {
        name: StartInputSchema.shape.name.describe(
          "Name of the spec (optional - generated from goal if not provided)"
        ),
        goal: StartInputSchema.shape.goal.describe(
          "Goal/description for the spec"
        ),
        quick: StartInputSchema.shape.quick.describe(
          "Quick mode - skip interviews"
        ),
      },
    },
    async (input) => {
      return toCallToolResult(handleStart(fileManager, stateManager, input, logger));
    }
  );

  // 6. ralph_complete_phase - Mark a phase as complete
  server.registerTool(
    "ralph_complete_phase",
    {
      description:
        "Mark the current phase as complete and transition to the next phase. Records a summary in progress file.",
      inputSchema: {
        spec_name: CompletePhaseInputSchema.shape.spec_name.describe(
          "Name of the spec (optional - defaults to current spec)"
        ),
        phase: CompletePhaseInputSchema.shape.phase.describe(
          "Phase being completed (must match current phase)"
        ),
        summary: CompletePhaseInputSchema.shape.summary.describe(
          "Summary of what was accomplished in this phase"
        ),
      },
    },
    async (input) => {
      return toCallToolResult(handleCompletePhase(fileManager, stateManager, input, logger));
    }
  );

  // 7. ralph_research - Run research phase
  server.registerTool(
    "ralph_research",
    {
      description:
        "Run the research phase for a spec. Returns research-analyst instructions and goal context for LLM to execute.",
      inputSchema: {
        spec_name: ResearchInputSchema.shape.spec_name.describe(
          "Name of the spec (optional - defaults to current spec)"
        ),
      },
    },
    async (input) => {
      return toCallToolResult(handleResearch(fileManager, stateManager, input, logger));
    }
  );

  // 8. ralph_requirements - Generate requirements
  server.registerTool(
    "ralph_requirements",
    {
      description:
        "Generate requirements from research. Returns product-manager instructions and research context for LLM to execute.",
      inputSchema: {
        spec_name: RequirementsInputSchema.shape.spec_name.describe(
          "Name of the spec (optional - defaults to current spec)"
        ),
      },
    },
    async (input) => {
      return toCallToolResult(handleRequirements(fileManager, stateManager, input, logger));
    }
  );

  // 9. ralph_design - Create technical design
  server.registerTool(
    "ralph_design",
    {
      description:
        "Create technical design from requirements. Returns architect-reviewer instructions and requirements context for LLM to execute.",
      inputSchema: {
        spec_name: DesignInputSchema.shape.spec_name.describe(
          "Name of the spec (optional - defaults to current spec)"
        ),
      },
    },
    async (input) => {
      return toCallToolResult(handleDesign(fileManager, stateManager, input, logger));
    }
  );

  // 10. ralph_tasks - Generate implementation tasks
  server.registerTool(
    "ralph_tasks",
    {
      description:
        "Generate implementation tasks from design. Returns task-planner instructions and design context for LLM to execute.",
      inputSchema: {
        spec_name: TasksInputSchema.shape.spec_name.describe(
          "Name of the spec (optional - defaults to current spec)"
        ),
      },
    },
    async (input) => {
      return toCallToolResult(handleTasks(fileManager, stateManager, input, logger));
    }
  );

  // 11. ralph_implement - Execute tasks
  server.registerTool(
    "ralph_implement",
    {
      description:
        "Execute implementation tasks one by one. Returns spec-executor instructions and current task context for LLM to execute.",
      inputSchema: {
        max_iterations: ImplementInputSchema.shape.max_iterations.describe(
          "Maximum task retries before blocking (defaults to 5)"
        ),
      },
    },
    async (input) => {
      return toCallToolResult(handleImplement(fileManager, stateManager, input, logger));
    }
  );
}

/**
 * Get the total number of registered tools.
 * Useful for logging and validation.
 *
 * @returns Number of tools registered by registerTools()
 */
export function getToolCount(): number {
  return TOOL_COUNT;
}
