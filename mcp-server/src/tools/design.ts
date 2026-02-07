/**
 * ralph_design tool handler.
 * Returns architect-reviewer prompt + requirements context for LLM to execute.
 * @module tools/design
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
 * Zod schema for design tool input validation.
 */
export const DesignInputSchema = z.object({
  /** Name of the spec (optional - defaults to current spec) */
  spec_name: z.string().min(1).optional(),
});

/**
 * Input type for the design tool.
 */
export type DesignInput = z.infer<typeof DesignInputSchema>;

/**
 * Handle the ralph_design tool.
 *
 * Returns architect-reviewer instructions for the LLM to execute.
 * The response includes the agent prompt, requirements context from
 * requirements.md, expected actions, and completion instructions.
 *
 * Requires spec to be in "design" phase.
 *
 * @param fileManager - FileManager instance for spec file operations
 * @param stateManager - StateManager instance for state file operations
 * @param input - Validated input with optional spec_name
 * @param logger - Optional logger for error logging
 * @returns MCP-compliant tool result with design instructions
 */
export function handleDesign(
  fileManager: FileManager,
  stateManager: StateManager,
  input: DesignInput,
  logger?: MCPLogger
): ToolResult {
  try {
    // Validate input with Zod
    const parsed = DesignInputSchema.safeParse(input);
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

    // Validate we're in design phase
    if (state.phase !== "design") {
      return createErrorResponse(
        "PHASE_MISMATCH",
        `Spec "${specName}" is in "${state.phase}" phase, not design. Run the appropriate tool for the current phase.`,
        logger
      );
    }

    // Read .progress.md for goal context
    const progressContent = fileManager.readSpecFile(specName, ".progress.md");

    // Read research.md for research context
    const researchContent = fileManager.readSpecFile(specName, "research.md");

    // Read requirements.md for requirements context
    const requirementsContent = fileManager.readSpecFile(specName, "requirements.md");

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
    } else {
      // Log warning but continue - requirements file is expected but not blocking
      logger?.warning(`No requirements.md found for spec "${specName}"`);
      contextParts.push(
        "## Requirements\n\nNo requirements.md found. Requirements phase may have been skipped or file is missing."
      );
    }

    const context = contextParts.join("\n\n---\n\n");

    // Build instruction response
    return buildInstructionResponse({
      specName,
      phase: "design",
      agentPrompt: AGENTS.architectReviewer,
      context,
      expectedActions: [
        "Review the requirements and research findings",
        "Design the technical architecture and component structure",
        "Define data flow and interfaces",
        "Make key technical decisions with rationale",
        "Document the design in ./specs/" + specName + "/design.md",
        "Update .progress.md with architecture decisions",
      ],
      completionInstruction:
        "Once design.md is written with architecture, components, and technical decisions, call ralph_complete_phase to move to tasks.",
    });
  } catch (error) {
    return handleUnexpectedError(error, "ralph_design", logger);
  }
}
