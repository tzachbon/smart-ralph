/**
 * ralph_cancel tool handler.
 * Cancels a spec by deleting .ralph-state.json and optionally the spec directory.
 * @module tools/cancel
 */

import { z } from "zod";
import type { FileManager } from "../lib/files";
import type { StateManager } from "../lib/state";
import type { MCPLogger } from "../lib/logger";
import type { ToolResult } from "../lib/types";
import { handleUnexpectedError, createErrorResponse } from "../lib/errors";

/**
 * Zod schema for cancel tool input validation.
 */
export const CancelInputSchema = z.object({
  /** Name of the spec to cancel (uses current spec if not provided) */
  spec_name: z.string().optional(),
  /** Whether to delete the spec directory and all files (default: false) */
  delete_files: z.boolean().optional().default(false),
});

/**
 * Input type for the cancel tool.
 */
export type CancelInput = z.infer<typeof CancelInputSchema>;

/**
 * Handle the ralph_cancel tool.
 *
 * Cancels a spec by deleting its .ralph-state.json file.
 * Optionally deletes the entire spec directory and all files.
 * Uses current spec if spec_name is not provided.
 *
 * @param fileManager - FileManager instance for spec file operations
 * @param stateManager - StateManager instance for state file operations
 * @param input - Validated input with optional spec_name and delete_files flag
 * @param logger - Optional logger for error logging
 * @returns MCP-compliant tool result with cancellation confirmation
 */
export function handleCancel(
  fileManager: FileManager,
  stateManager: StateManager,
  input: CancelInput,
  logger?: MCPLogger
): ToolResult {
  try {
    // Validate input with Zod
    const parsed = CancelInputSchema.safeParse(input);
    if (!parsed.success) {
      return createErrorResponse(
        "VALIDATION_ERROR",
        parsed.error.errors[0]?.message ?? "Invalid input",
        logger
      );
    }

    const { spec_name, delete_files } = parsed.data;

    // Determine which spec to cancel
    const specName = spec_name ?? fileManager.getCurrentSpec();
    if (!specName) {
      return createErrorResponse(
        "MISSING_PREREQUISITES",
        "No spec specified and no current spec set. Use ralph_switch to select a spec or provide spec_name parameter.",
        logger
      );
    }

    // Check if spec exists
    if (!fileManager.specExists(specName)) {
      return createErrorResponse(
        "SPEC_NOT_FOUND",
        `Spec "${specName}" not found.`,
        logger
      );
    }

    const specDir = fileManager.getSpecDir(specName);
    const results: string[] = [];

    // Delete .ralph-state.json
    const stateDeleted = stateManager.delete(specDir);
    if (stateDeleted) {
      results.push("- Deleted .ralph-state.json");
    } else {
      results.push("- Warning: Failed to delete .ralph-state.json (may not exist)");
    }

    // Optionally delete the entire spec directory
    if (delete_files) {
      const specDeleted = fileManager.deleteSpec(specName);
      if (specDeleted) {
        results.push(`- Deleted spec directory: ${specName}/`);

        // Clear current spec if it was the deleted one
        const currentSpec = fileManager.getCurrentSpec();
        if (currentSpec === specName) {
          // Find another spec to set as current, or clear
          const remainingSpecs = fileManager.listSpecs();
          if (remainingSpecs.length > 0) {
            fileManager.setCurrentSpec(remainingSpecs[0]);
            results.push(`- Switched current spec to: ${remainingSpecs[0]}`);
          } else {
            // No need to clear .current-spec as specs dir may be empty
            results.push("- No remaining specs");
          }
        }
      } else {
        results.push(`- Error: Failed to delete spec directory`);
      }
    }

    // Build response
    const action = delete_files ? "cancelled and deleted" : "cancelled";
    const lines = [
      `Spec "${specName}" ${action}.`,
      "",
      "Actions taken:",
      ...results,
    ];

    if (!delete_files) {
      lines.push("");
      lines.push("Spec files preserved. Run again with delete_files: true to remove all files.");
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
    return handleUnexpectedError(error, "ralph_cancel", logger);
  }
}
