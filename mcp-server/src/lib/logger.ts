/**
 * MCP-compliant logger that writes structured JSON to stderr.
 * NEVER uses console.log() - stdout is reserved for JSON-RPC protocol.
 * @module logger
 */

import type { LogLevel, LogMessage } from "./types";

// Re-export types for convenience
export type { LogLevel, LogMessage };

/** Default logger name for the Ralph Specum MCP server */
const DEFAULT_LOGGER_NAME = "ralph-specum-mcp";

/**
 * MCP-compliant structured logger.
 *
 * All output is written to stderr as JSON to avoid corrupting the JSON-RPC
 * protocol on stdout. This logger follows the MCP logging specification
 * for `logging/message` notifications.
 *
 * @example
 * ```typescript
 * const logger = new MCPLogger("my-component");
 * logger.info("Operation completed", { items: 5 });
 * // Output to stderr: {"level":"info","logger":"my-component","data":{"message":"Operation completed","items":5},"timestamp":"2024-01-15T..."}
 * ```
 */
export class MCPLogger {
  private readonly name: string;

  /**
   * Create a new MCPLogger instance.
   *
   * @param name - Logger name, typically the component or module name.
   *               Defaults to "ralph-specum-mcp".
   */
  constructor(name: string = DEFAULT_LOGGER_NAME) {
    this.name = name;
  }

  /**
   * Internal logging method that formats and writes to stderr.
   *
   * @param level - Log severity level
   * @param message - Human-readable log message
   * @param data - Optional additional data to include in the log
   */
  private log(level: LogLevel, message: string, data?: unknown): void {
    const logMessage: LogMessage = {
      level,
      logger: this.name,
      data: data !== undefined
        ? { message, ...((typeof data === "object" && data !== null) ? data : { value: data }) }
        : { message },
      timestamp: new Date().toISOString(),
    };
    // Always use console.error to write to stderr - NEVER console.log
    console.error(JSON.stringify(logMessage));
  }

  /**
   * Log a debug message.
   * Use for detailed diagnostic information during development.
   *
   * @param message - Human-readable debug message
   * @param data - Optional additional data to include
   */
  debug(message: string, data?: unknown): void {
    this.log("debug", message, data);
  }

  /**
   * Log an informational message.
   * Use for general operational messages about application progress.
   *
   * @param message - Human-readable info message
   * @param data - Optional additional data to include
   */
  info(message: string, data?: unknown): void {
    this.log("info", message, data);
  }

  /**
   * Log a warning message.
   * Use for potentially harmful situations that don't prevent operation.
   *
   * @param message - Human-readable warning message
   * @param data - Optional additional data to include
   */
  warning(message: string, data?: unknown): void {
    this.log("warning", message, data);
  }

  /**
   * Log an error message.
   * Use for error events that may still allow the application to continue.
   *
   * @param message - Human-readable error message
   * @param data - Optional additional data to include (e.g., error details)
   */
  error(message: string, data?: unknown): void {
    this.log("error", message, data);
  }
}
