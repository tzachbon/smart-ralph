/**
 * Error handling utilities for MCP tools.
 * Provides standardized error responses and logging.
 * @module errors
 */

import type { MCPLogger } from "./logger";
import type { RalphErrorCode, ToolResult } from "./types";

// Re-export types for convenience
export type { RalphErrorCode, ToolResult };
export type { TextContent } from "./types";

/**
 * User-friendly prefixes for each error code.
 * Maps error codes to human-readable descriptions.
 */
const ERROR_PREFIXES: Record<RalphErrorCode, string> = {
  SPEC_NOT_FOUND: "Spec not found",
  INVALID_STATE: "Invalid state",
  MISSING_PREREQUISITES: "Missing prerequisites",
  PHASE_MISMATCH: "Phase mismatch",
  VALIDATION_ERROR: "Validation error",
  FILE_OPERATION_ERROR: "File operation failed",
  INTERNAL_ERROR: "Internal error",
};

/**
 * Create a standardized error response for MCP tools.
 *
 * Formats the error message with a user-friendly prefix and optionally
 * logs the error to stderr. Never exposes stack traces to the client.
 *
 * @param code - The error code categorizing this error
 * @param message - Detailed error message for the user
 * @param logger - Optional logger instance for stderr logging
 * @returns MCP-compliant error response with isError flag set
 *
 * @example
 * ```typescript
 * return createErrorResponse(
 *   "SPEC_NOT_FOUND",
 *   'Spec "my-feature" not found',
 *   logger
 * );
 * ```
 */
export function createErrorResponse(
  code: RalphErrorCode,
  message: string,
  logger?: MCPLogger
): ToolResult {
  const prefix = ERROR_PREFIXES[code];
  const fullMessage = `Error: ${prefix} - ${message}`;

  // Log error to stderr if logger provided
  if (logger) {
    logger.error(fullMessage, { code });
  }

  return {
    content: [
      {
        type: "text",
        text: fullMessage,
      },
    ],
    isError: true,
  };
}

/**
 * Handle unexpected errors safely.
 *
 * Logs the full error details to stderr for debugging but returns
 * a safe, generic message to the client. Stack traces are never
 * exposed to prevent information leakage.
 *
 * @param error - The caught error (may be Error, string, or unknown)
 * @param toolName - Name of the tool where the error occurred
 * @param logger - Optional logger instance for stderr logging
 * @returns MCP-compliant error response with generic message
 *
 * @example
 * ```typescript
 * try {
 *   // ... tool logic
 * } catch (error) {
 *   return handleUnexpectedError(error, "ralph_status", logger);
 * }
 * ```
 */
export function handleUnexpectedError(
  error: unknown,
  toolName: string,
  logger?: MCPLogger
): ToolResult {
  // Extract error message safely without exposing internals
  const errorMessage = error instanceof Error ? error.message : "Unknown error";

  // Log full error details to stderr for debugging
  if (logger) {
    logger.error(`Unexpected error in ${toolName}`, {
      error: errorMessage,
      tool: toolName,
      // Log stack trace to stderr for debugging but don't include in response
      stack: error instanceof Error ? error.stack : undefined,
    });
  }

  // Return safe message to client (no stack trace)
  return {
    content: [
      {
        type: "text",
        text: `Error: An unexpected error occurred in ${toolName}. Please try again or run ralph_status to check the current state.`,
      },
    ],
    isError: true,
  };
}

/**
 * Common error messages for reuse across tools.
 * Provides consistent messaging and reduces duplication.
 */
export const ErrorMessages = {
  /**
   * Error message when no current spec is set and none specified.
   */
  noCurrentSpec: "No current spec set. Run ralph_start first or specify spec_name.",

  /**
   * Error message when a specified spec does not exist.
   * @param specName - Name of the spec that was not found
   * @returns Formatted error message
   */
  specNotFound: (specName: string): string =>
    `Spec "${specName}" not found. Run ralph_status to see available specs.`,

  /**
   * Error message when state file is missing or corrupt.
   * @param specName - Name of the spec with missing state
   * @returns Formatted error message
   */
  noStateFound: (specName: string): string =>
    `No state found for spec "${specName}". Run ralph_start to initialize the spec.`,

  /**
   * Error message when trying to perform an operation in the wrong phase.
   * @param specName - Name of the spec
   * @param currentPhase - The phase the spec is currently in
   * @param expectedPhase - The phase required for the operation
   * @returns Formatted error message
   */
  phaseMismatch: (specName: string, currentPhase: string, expectedPhase: string): string =>
    `Spec "${specName}" is in "${currentPhase}" phase, not ${expectedPhase}. Run the appropriate tool for the current phase.`,

  /**
   * Error message when a prerequisite file is missing.
   * @param specName - Name of the spec
   * @param prerequisite - Name of the missing prerequisite (e.g., "research.md")
   * @returns Formatted error message
   */
  missingPrerequisite: (specName: string, prerequisite: string): string =>
    `${prerequisite} not found for spec "${specName}". Complete the previous phase first.`,
};
