/**
 * ralph_research tool handler.
 * Returns research-analyst prompt + goal context for LLM to execute.
 * @module tools/research
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
 * Zod schema for research tool input validation.
 */
export const ResearchInputSchema = z.object({
  /** Name of the spec (optional - defaults to current spec) */
  spec_name: z.string().min(1).optional(),
});

/**
 * Input type for the research tool.
 */
export type ResearchInput = z.infer<typeof ResearchInputSchema>;

/**
 * Handle the ralph_research tool.
 *
 * Returns research-analyst instructions for the LLM to execute.
 * The response includes the agent prompt, goal context from .progress.md,
 * expected actions, and completion instructions.
 *
 * Requires spec to be in "research" phase.
 *
 * @param fileManager - FileManager instance for spec file operations
 * @param stateManager - StateManager instance for state file operations
 * @param input - Validated input with optional spec_name
 * @param logger - Optional logger for error logging
 * @returns MCP-compliant tool result with research instructions
 */
export function handleResearch(
  fileManager: FileManager,
  stateManager: StateManager,
  input: ResearchInput,
  logger?: MCPLogger
): ToolResult {
  try {
    // Validate input with Zod
    const parsed = ResearchInputSchema.safeParse(input);
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

    // Validate we're in research phase
    if (state.phase !== "research") {
      return createErrorResponse(
        "PHASE_MISMATCH",
        `Spec "${specName}" is in "${state.phase}" phase, not research. Run the appropriate tool for the current phase.`,
        logger
      );
    }

    // Read .progress.md for goal context
    const progressContent = fileManager.readSpecFile(specName, ".progress.md");
    const context = progressContent
      ? `## Current Progress\n\n${progressContent}`
      : "No progress file found. Goal should have been set during ralph_start.";

    // Build instruction response
    return buildInstructionResponse({
      specName,
      phase: "research",
      agentPrompt: AGENTS.researchAnalyst,
      context,
      expectedActions: [
        "Analyze the goal and understand what needs to be researched",
        "Search the codebase for relevant existing patterns and code",
        "Use web search to find best practices and external knowledge",
        "Document findings in ./specs/" + specName + "/research.md",
        "Update .progress.md with key learnings",
      ],
      completionInstruction:
        "Once research.md is written with comprehensive findings, call ralph_complete_phase to move to requirements.",
    });
  } catch (error) {
    return handleUnexpectedError(error, "ralph_research", logger);
  }
}
