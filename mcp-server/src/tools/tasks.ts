/**
 * ralph_tasks tool handler.
 * Returns task-planner prompt + design context for LLM to execute.
 * @module tools/tasks
 */

import { z } from "zod";
import type { FileManager } from "../lib/files";
import type { StateManager } from "../lib/state";
import type { MCPLogger } from "../lib/logger";
import type { ToolResult } from "../lib/types";
import { AGENTS } from "../assets";
import { buildInstructionResponse } from "../lib/instruction-builder";
import { handleUnexpectedError, createErrorResponse } from "../lib/errors";

/**
 * Zod schema for tasks tool input validation.
 */
export const TasksInputSchema = z.object({
  /** Name of the spec (optional - defaults to current spec) */
  spec_name: z.string().min(1).optional(),
});

/**
 * Input type for the tasks tool.
 */
export type TasksInput = z.infer<typeof TasksInputSchema>;

/**
 * Handle the ralph_tasks tool.
 *
 * Returns task-planner instructions for the LLM to execute.
 * The response includes the agent prompt, design context from
 * design.md, expected actions, and completion instructions.
 *
 * Requires spec to be in "tasks" phase.
 *
 * @param fileManager - FileManager instance for spec file operations
 * @param stateManager - StateManager instance for state file operations
 * @param input - Validated input with optional spec_name
 * @param logger - Optional logger for error logging
 * @returns MCP-compliant tool result with task planning instructions
 */
export function handleTasks(
  fileManager: FileManager,
  stateManager: StateManager,
  input: TasksInput,
  logger?: MCPLogger
): ToolResult {
  try {
    // Validate input with Zod
    const parsed = TasksInputSchema.safeParse(input);
    if (!parsed.success) {
      return createErrorResponse(
        "VALIDATION_ERROR",
        parsed.error.errors[0]?.message ?? "Invalid input",
        logger
      );
    }

    const { spec_name } = parsed.data;

    // Determine spec name (use provided or current)
    let specName: string;
    if (spec_name) {
      specName = spec_name;
    } else {
      const currentSpec = fileManager.getCurrentSpec();
      if (!currentSpec) {
        return createErrorResponse(
          "MISSING_PREREQUISITES",
          "No spec specified and no current spec set. Run ralph_start first or specify spec_name.",
          logger
        );
      }
      specName = currentSpec;
    }

    // Verify spec exists
    if (!fileManager.specExists(specName)) {
      return createErrorResponse(
        "SPEC_NOT_FOUND",
        `Spec "${specName}" not found. Run ralph_status to see available specs.`,
        logger
      );
    }

    // Read current state
    const specDir = fileManager.getSpecDir(specName);
    const state = stateManager.read(specDir);

    if (!state) {
      return createErrorResponse(
        "INVALID_STATE",
        `No state found for spec "${specName}". Run ralph_start to initialize the spec.`,
        logger
      );
    }

    // Validate we're in tasks phase
    if (state.phase !== "tasks") {
      return createErrorResponse(
        "PHASE_MISMATCH",
        `Spec "${specName}" is in "${state.phase}" phase, not tasks. Run the appropriate tool for the current phase.`,
        logger
      );
    }

    // Read .progress.md for goal context
    const progressContent = fileManager.readSpecFile(specName, ".progress.md");

    // Read research.md for research context
    const researchContent = fileManager.readSpecFile(specName, "research.md");

    // Read requirements.md for requirements context
    const requirementsContent = fileManager.readSpecFile(specName, "requirements.md");

    // Read design.md for design context
    const designContent = fileManager.readSpecFile(specName, "design.md");

    // Build combined context
    const contextParts: string[] = [];

    if (progressContent) {
      contextParts.push("## Progress Summary\n\n" + progressContent);
    }

    if (researchContent) {
      contextParts.push("## Research Findings\n\n" + researchContent);
    }

    if (requirementsContent) {
      contextParts.push("## Requirements\n\n" + requirementsContent);
    }

    if (designContent) {
      contextParts.push("## Design\n\n" + designContent);
    } else {
      // Log warning but continue - design file is expected but not blocking
      logger?.warning(`No design.md found for spec "${specName}"`);
      contextParts.push(
        "## Design\n\nNo design.md found. Design phase may have been skipped or file is missing."
      );
    }

    const context = contextParts.join("\n\n---\n\n");

    // Build instruction response
    return buildInstructionResponse({
      specName,
      phase: "tasks",
      agentPrompt: AGENTS.taskPlanner,
      context,
      expectedActions: [
        "Review the design, requirements, and research",
        "Break down work into executable tasks with POC-first approach",
        "Define clear Do, Files, Done when, Verify, and Commit for each task",
        "Insert quality checkpoints every 2-3 tasks",
        "Organize into phases: POC, Refactoring, Testing, Quality Gates, PR Lifecycle",
        "Write tasks to ./specs/" + specName + "/tasks.md",
        "Update .progress.md with task planning summary",
      ],
      completionInstruction:
        "Once tasks.md is written with phased task breakdown, call ralph_complete_phase to move to execution.",
    });
  } catch (error) {
    return handleUnexpectedError(error, "ralph_tasks", logger);
  }
}
