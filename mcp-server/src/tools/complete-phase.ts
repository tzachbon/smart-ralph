/**
 * ralph_complete_phase tool handler.
 * Marks a phase as complete and transitions to the next phase.
 * @module tools/complete-phase
 */

import { z } from "zod";
import type { FileManager } from "../lib/files";
import type { StateManager, Phase } from "../lib/state";
import type { MCPLogger } from "../lib/logger";
import type { ToolResult } from "../lib/types";
import { handleUnexpectedError, createErrorResponse } from "../lib/errors";

/**
 * Phase transition map: current phase -> next phase
 */
const PHASE_TRANSITIONS: Record<Phase, Phase | null> = {
  research: "requirements",
  requirements: "design",
  design: "tasks",
  tasks: "execution",
  execution: null, // No next phase
};

/**
 * Next step instructions for each phase
 */
const NEXT_STEP_INSTRUCTIONS: Record<Phase, string> = {
  research: "Run **ralph_requirements** to generate user stories and acceptance criteria.",
  requirements: "Run **ralph_design** to create technical architecture.",
  design: "Run **ralph_tasks** to break down the design into executable tasks.",
  tasks: "Run **ralph_implement** to begin task execution.",
  execution: "All phases complete. Spec is ready for final review.",
};

/**
 * Zod schema for complete_phase tool input validation.
 */
export const CompletePhaseInputSchema = z.object({
  /** Name of the spec (optional - defaults to current spec) */
  spec_name: z.string().min(1).optional(),
  /** Phase being completed */
  phase: z.enum(["research", "requirements", "design", "tasks", "execution"]),
  /** Summary of what was accomplished in this phase */
  summary: z.string().min(1),
});

/**
 * Input type for the complete_phase tool.
 */
export type CompletePhaseInput = z.infer<typeof CompletePhaseInputSchema>;

/**
 * Handle the ralph_complete_phase tool.
 *
 * Marks the current phase as complete and transitions to the next phase.
 * Appends a summary to .progress.md and updates .ralph-state.json.
 *
 * Phase transitions:
 * - research -> requirements
 * - requirements -> design
 * - design -> tasks
 * - tasks -> execution
 * - execution -> (no next phase)
 *
 * @param fileManager - FileManager instance for spec file operations
 * @param stateManager - StateManager instance for state file operations
 * @param input - Validated input with phase and summary
 * @param logger - Optional logger for error logging
 * @returns MCP-compliant tool result with transition confirmation
 */
export function handleCompletePhase(
  fileManager: FileManager,
  stateManager: StateManager,
  input: CompletePhaseInput,
  logger?: MCPLogger
): ToolResult {
  try {
    // Validate input with Zod
    const parsed = CompletePhaseInputSchema.safeParse(input);
    if (!parsed.success) {
      return createErrorResponse(
        "VALIDATION_ERROR",
        parsed.error.errors[0]?.message ?? "Invalid input",
        logger
      );
    }

    const { spec_name, phase, summary } = parsed.data;

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

    // Validate phase matches current state
    if (state.phase !== phase) {
      return createErrorResponse(
        "PHASE_MISMATCH",
        `Current phase is "${state.phase}", but you tried to complete "${phase}". Complete the current phase first.`,
        logger
      );
    }

    // Get next phase
    const nextPhase = PHASE_TRANSITIONS[phase];

    // Update state with next phase
    const updatedState = {
      ...state,
      phase: nextPhase ?? state.phase, // Keep execution phase if already there
    };

    if (!stateManager.write(specDir, updatedState)) {
      return createErrorResponse(
        "FILE_OPERATION_ERROR",
        `Failed to update state for spec "${specName}".`,
        logger
      );
    }

    // Append summary to .progress.md
    const progressContent = fileManager.readSpecFile(specName, ".progress.md");
    if (progressContent !== null) {
      const timestamp = new Date().toISOString().split("T")[0]; // YYYY-MM-DD
      const phaseHeading = `### ${phase.charAt(0).toUpperCase() + phase.slice(1)} Phase Complete (${timestamp})`;
      const summarySection = `\n\n${phaseHeading}\n\n${summary}\n`;

      // Find the "## Learnings" section or append at end
      let updatedProgress: string;
      const learningsIndex = progressContent.indexOf("\n## Learnings");
      if (learningsIndex !== -1) {
        // Insert before Learnings section
        updatedProgress =
          progressContent.slice(0, learningsIndex) +
          summarySection +
          progressContent.slice(learningsIndex);
      } else {
        // Append at end
        updatedProgress = progressContent + summarySection;
      }

      if (!fileManager.writeSpecFile(specName, ".progress.md", updatedProgress)) {
        // Non-fatal warning - state was updated successfully
        logger?.warning(`State updated but failed to append summary to .progress.md for spec "${specName}"`);
        return {
          content: [
            {
              type: "text",
              text: `Warning: State updated but failed to append summary to .progress.md for spec "${specName}".`,
            },
          ],
        };
      }
    }

    // Build success response
    const lines: string[] = [];
    lines.push(`# Phase Complete: ${phase}`);
    lines.push("");
    lines.push(`**Spec**: ${specName}`);
    lines.push(`**Completed Phase**: ${phase}`);

    if (nextPhase) {
      lines.push(`**Next Phase**: ${nextPhase}`);
      lines.push("");
      lines.push("## Summary");
      lines.push("");
      lines.push(summary);
      lines.push("");
      lines.push("## Next Step");
      lines.push("");
      lines.push(NEXT_STEP_INSTRUCTIONS[phase]);
    } else {
      lines.push(`**Status**: All phases complete`);
      lines.push("");
      lines.push("## Summary");
      lines.push("");
      lines.push(summary);
      lines.push("");
      lines.push("## Next Step");
      lines.push("");
      lines.push(NEXT_STEP_INSTRUCTIONS.execution);
    }

    return {
      content: [
        {
          type: "text",
          text: lines.join("\n"),
        },
      ],
    };
  } catch (error) {
    return handleUnexpectedError(error, "ralph_complete_phase", logger);
  }
}
