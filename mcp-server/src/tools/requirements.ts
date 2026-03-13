/**
 * ralph_requirements tool handler.
 * Returns product-manager prompt + research context for LLM to execute.
 * @module tools/requirements
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
 * Zod schema for requirements tool input validation.
 */
export const RequirementsInputSchema = z.object({
  /** Name of the spec (optional - defaults to current spec) */
  spec_name: z.string().min(1).optional(),
});

/**
 * Input type for the requirements tool.
 */
export type RequirementsInput = z.infer<typeof RequirementsInputSchema>;

/**
 * Handle the ralph_requirements tool.
 *
 * Returns product-manager instructions for the LLM to execute.
 * The response includes the agent prompt, research context from
 * research.md, expected actions, and completion instructions.
 *
 * Requires spec to be in "requirements" phase.
 *
 * @param fileManager - FileManager instance for spec file operations
 * @param stateManager - StateManager instance for state file operations
 * @param input - Validated input with optional spec_name
 * @param logger - Optional logger for error logging
 * @returns MCP-compliant tool result with requirements instructions
 */
export function handleRequirements(
  fileManager: FileManager,
  stateManager: StateManager,
  input: RequirementsInput,
  logger?: MCPLogger
): ToolResult {
  try {
    // Validate input with Zod
    const parsed = RequirementsInputSchema.safeParse(input);
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

    // Validate we're in requirements phase
    if (state.phase !== "requirements") {
      return createErrorResponse(
        "PHASE_MISMATCH",
        `Spec "${specName}" is in "${state.phase}" phase, not requirements. Run the appropriate tool for the current phase.`,
        logger
      );
    }

    // Read .progress.md for goal context
    const progressContent = fileManager.readSpecFile(specName, ".progress.md");

    // Read research.md for research context
    const researchContent = fileManager.readSpecFile(specName, "research.md");

    // Build combined context
    const contextParts: string[] = [];

    if (progressContent) {
      contextParts.push("## Progress Summary\n\n" + progressContent);
    }

    if (researchContent) {
      contextParts.push("## Research Findings\n\n" + researchContent);
    } else {
      // Log warning but continue - research file is optional
      logger?.warning(`No research.md found for spec "${specName}"`);
      contextParts.push(
        "## Research Findings\n\nNo research.md found. Research phase may have been skipped or file is missing."
      );
    }

    const context = contextParts.join("\n\n---\n\n");

    // Build instruction response
    return buildInstructionResponse({
      specName,
      phase: "requirements",
      agentPrompt: AGENTS.productManager,
      context,
      expectedActions: [
        "Review the research findings and goal",
        "Define user stories with clear acceptance criteria",
        "Prioritize requirements (P0, P1, P2)",
        "Document functional and non-functional requirements",
        "Write requirements to ./specs/" + specName + "/requirements.md",
        "Update .progress.md with decisions made",
      ],
      completionInstruction:
        "Once requirements.md is written with user stories and acceptance criteria, call ralph_complete_phase to move to design.",
    });
  } catch (error) {
    return handleUnexpectedError(error, "ralph_requirements", logger);
  }
}
