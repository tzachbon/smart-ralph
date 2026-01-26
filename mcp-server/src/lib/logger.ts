/**
 * MCP-compliant logger that writes structured JSON to stderr.
 * NEVER uses console.log() - stdout is reserved for JSON-RPC protocol.
 */

export type LogLevel = "debug" | "info" | "warning" | "error";

export interface LogMessage {
  level: LogLevel;
  logger: string;
  data: unknown;
  timestamp: string;
}

export class MCPLogger {
  private readonly name: string;

  constructor(name: string = "ralph-specum-mcp") {
    this.name = name;
  }

  private log(level: LogLevel, message: string, data?: unknown): void {
    const logMessage: LogMessage = {
      level,
      logger: this.name,
      data: data !== undefined ? { message, ...((typeof data === 'object' && data !== null) ? data : { value: data }) } : { message },
      timestamp: new Date().toISOString(),
    };
    // Always use console.error to write to stderr - NEVER console.log
    console.error(JSON.stringify(logMessage));
  }

  debug(message: string, data?: unknown): void {
    this.log("debug", message, data);
  }

  info(message: string, data?: unknown): void {
    this.log("info", message, data);
  }

  warning(message: string, data?: unknown): void {
    this.log("warning", message, data);
  }

  error(message: string, data?: unknown): void {
    this.log("error", message, data);
  }
}
