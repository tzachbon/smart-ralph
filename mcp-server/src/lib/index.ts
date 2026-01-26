/**
 * Library barrel for Ralph Specum MCP Server.
 *
 * Re-exports all public types, classes, and functions from the lib modules.
 * This provides a single import point for consumers of the library.
 *
 * @module lib
 */

// Export all types
export * from "./types";

// Export classes
export { MCPLogger } from "./logger";
export { StateManager, RalphStateSchema } from "./state";
export { FileManager } from "./files";

// Export error utilities
export {
  createErrorResponse,
  handleUnexpectedError,
  ErrorMessages,
} from "./errors";

// Export instruction builder
export { buildInstructionResponse } from "./instruction-builder";
