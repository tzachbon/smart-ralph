/**
 * @module tests/logger.test
 * Unit tests for MCPLogger
 */

import { describe, test, expect, beforeEach, afterEach, mock, spyOn } from "bun:test";
import { MCPLogger } from "../src/lib/logger";
import type { LogMessage } from "../src/lib/types";

describe("MCPLogger", () => {
  let originalConsoleError: typeof console.error;
  let capturedOutput: string[];

  beforeEach(() => {
    // Capture stderr output by mocking console.error
    capturedOutput = [];
    originalConsoleError = console.error;
    console.error = (...args: unknown[]) => {
      capturedOutput.push(args.map(String).join(" "));
    };
  });

  afterEach(() => {
    // Restore original console.error
    console.error = originalConsoleError;
  });

  /**
   * Helper to parse the last captured log message
   */
  function getLastLogMessage(): LogMessage | null {
    if (capturedOutput.length === 0) return null;
    try {
      return JSON.parse(capturedOutput[capturedOutput.length - 1]);
    } catch {
      return null;
    }
  }

  describe("constructor", () => {
    test("creates logger with default name", () => {
      // Act
      const logger = new MCPLogger();
      logger.info("test");

      // Assert
      const log = getLastLogMessage();
      expect(log?.logger).toBe("ralph-specum-mcp");
    });

    test("creates logger with custom name", () => {
      // Act
      const logger = new MCPLogger("custom-component");
      logger.info("test");

      // Assert
      const log = getLastLogMessage();
      expect(log?.logger).toBe("custom-component");
    });
  });

  describe("log levels", () => {
    let logger: MCPLogger;

    beforeEach(() => {
      logger = new MCPLogger("test-logger");
    });

    test("debug() logs with level 'debug'", () => {
      // Act
      logger.debug("Debug message");

      // Assert
      const log = getLastLogMessage();
      expect(log?.level).toBe("debug");
    });

    test("info() logs with level 'info'", () => {
      // Act
      logger.info("Info message");

      // Assert
      const log = getLastLogMessage();
      expect(log?.level).toBe("info");
    });

    test("warning() logs with level 'warning'", () => {
      // Act
      logger.warning("Warning message");

      // Assert
      const log = getLastLogMessage();
      expect(log?.level).toBe("warning");
    });

    test("error() logs with level 'error'", () => {
      // Act
      logger.error("Error message");

      // Assert
      const log = getLastLogMessage();
      expect(log?.level).toBe("error");
    });
  });

  describe("output format", () => {
    let logger: MCPLogger;

    beforeEach(() => {
      logger = new MCPLogger("format-test");
    });

    test("outputs valid JSON", () => {
      // Act
      logger.info("Test message");

      // Assert
      expect(capturedOutput.length).toBe(1);
      expect(() => JSON.parse(capturedOutput[0])).not.toThrow();
    });

    test("includes all required fields: level, logger, data, timestamp", () => {
      // Act
      logger.info("Test message");

      // Assert
      const log = getLastLogMessage();
      expect(log).not.toBeNull();
      expect(log).toHaveProperty("level");
      expect(log).toHaveProperty("logger");
      expect(log).toHaveProperty("data");
      expect(log).toHaveProperty("timestamp");
    });

    test("timestamp is valid ISO 8601 format", () => {
      // Act
      logger.info("Test message");

      // Assert
      const log = getLastLogMessage();
      expect(log?.timestamp).toBeDefined();
      // Verify it parses as a valid date
      const date = new Date(log!.timestamp);
      expect(date.toString()).not.toBe("Invalid Date");
      // Verify ISO format (contains T and ends with Z or timezone offset)
      expect(log?.timestamp).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/);
    });

    test("data contains message when no additional data provided", () => {
      // Act
      logger.info("Simple message");

      // Assert
      const log = getLastLogMessage();
      expect(log?.data).toEqual({ message: "Simple message" });
    });

    test("data merges message with additional object data", () => {
      // Act
      logger.info("Operation completed", { count: 5, status: "ok" });

      // Assert
      const log = getLastLogMessage();
      expect(log?.data).toEqual({
        message: "Operation completed",
        count: 5,
        status: "ok",
      });
    });

    test("data wraps primitive values in 'value' field", () => {
      // Act
      logger.info("Number value", 42);

      // Assert
      const log = getLastLogMessage();
      expect(log?.data).toEqual({
        message: "Number value",
        value: 42,
      });
    });

    test("data wraps string values in 'value' field", () => {
      // Act
      logger.info("String value", "extra-info");

      // Assert
      const log = getLastLogMessage();
      expect(log?.data).toEqual({
        message: "String value",
        value: "extra-info",
      });
    });

    test("data wraps null in 'value' field", () => {
      // Act
      logger.info("Null value", null);

      // Assert
      const log = getLastLogMessage();
      expect(log?.data).toEqual({
        message: "Null value",
        value: null,
      });
    });
  });

  describe("stderr output", () => {
    test("logs are written to stderr via console.error", () => {
      // Arrange - reset capture to verify console.error is called
      capturedOutput = [];
      const logger = new MCPLogger("stderr-test");

      // Act
      logger.info("Test message");

      // Assert
      expect(capturedOutput.length).toBe(1);
    });

    test("multiple logs accumulate in stderr", () => {
      // Arrange
      const logger = new MCPLogger("multi-test");

      // Act
      logger.debug("First");
      logger.info("Second");
      logger.warning("Third");
      logger.error("Fourth");

      // Assert
      expect(capturedOutput.length).toBe(4);

      // Verify each is valid JSON with correct level
      const logs = capturedOutput.map((line) => JSON.parse(line) as LogMessage);
      expect(logs[0].level).toBe("debug");
      expect(logs[1].level).toBe("info");
      expect(logs[2].level).toBe("warning");
      expect(logs[3].level).toBe("error");
    });

    test("each log is a single line (no embedded newlines)", () => {
      // Arrange
      const logger = new MCPLogger("newline-test");

      // Act
      logger.info("Message with\nnewline in content", { key: "value\nwith\nnewlines" });

      // Assert
      expect(capturedOutput.length).toBe(1);
      // JSON.stringify escapes newlines, so the output should be a single line
      const rawOutput = capturedOutput[0];
      expect(rawOutput.split("\n").length).toBe(1);
    });
  });

  describe("edge cases", () => {
    test("handles empty message", () => {
      // Arrange
      const logger = new MCPLogger();

      // Act
      logger.info("");

      // Assert
      const log = getLastLogMessage();
      expect(log?.data).toEqual({ message: "" });
    });

    test("handles undefined data", () => {
      // Arrange
      const logger = new MCPLogger();

      // Act
      logger.info("Message", undefined);

      // Assert
      const log = getLastLogMessage();
      expect(log?.data).toEqual({ message: "Message" });
    });

    test("handles complex nested object data", () => {
      // Arrange
      const logger = new MCPLogger();
      const complexData = {
        nested: {
          deeply: {
            value: "test",
          },
        },
        array: [1, 2, 3],
      };

      // Act
      logger.info("Complex data", complexData);

      // Assert
      const log = getLastLogMessage();
      expect(log?.data).toEqual({
        message: "Complex data",
        nested: { deeply: { value: "test" } },
        array: [1, 2, 3],
      });
    });

    test("handles special characters in message", () => {
      // Arrange
      const logger = new MCPLogger();

      // Act
      logger.info("Message with \"quotes\" and \\backslashes\\");

      // Assert
      const log = getLastLogMessage();
      expect(log?.data.message).toBe("Message with \"quotes\" and \\backslashes\\");
    });

    test("handles unicode in message and data", () => {
      // Arrange
      const logger = new MCPLogger();

      // Act
      logger.info("Unicode: \u2603 \u{1F600}", { emoji: "\u{1F4E6}" });

      // Assert
      const log = getLastLogMessage();
      expect(log?.data.message).toBe("Unicode: \u2603 \u{1F600}");
      expect(log?.data.emoji).toBe("\u{1F4E6}");
    });
  });
});
