/**
 * @module tests/tools/help.test
 * Unit tests for ralph_help tool handler
 */

import { describe, test, expect } from "bun:test";
import { handleHelp } from "../../src/tools/help";
import { MCPLogger } from "../../src/lib/logger";

describe("handleHelp", () => {
  const logger = new MCPLogger("TestHelp");

  describe("success responses", () => {
    test("returns help content with header", () => {
      // Act
      const result = handleHelp(logger);

      // Assert
      expect(result.content).toHaveLength(1);
      expect(result.content[0].type).toBe("text");
      expect(result.content[0].text).toContain("# Ralph Specum MCP Server");
    });

    test("includes workflow description", () => {
      // Act
      const result = handleHelp(logger);

      // Assert
      expect(result.content[0].text).toContain("## Workflow");
      expect(result.content[0].text).toContain("ralph_start");
      expect(result.content[0].text).toContain("ralph_research");
      expect(result.content[0].text).toContain("ralph_requirements");
      expect(result.content[0].text).toContain("ralph_design");
      expect(result.content[0].text).toContain("ralph_tasks");
      expect(result.content[0].text).toContain("ralph_implement");
    });

    test("includes all 11 tools in table", () => {
      // Act
      const result = handleHelp(logger);
      const text = result.content[0].text;

      // Assert - All tools present
      const tools = [
        "ralph_start",
        "ralph_research",
        "ralph_requirements",
        "ralph_design",
        "ralph_tasks",
        "ralph_implement",
        "ralph_complete_phase",
        "ralph_status",
        "ralph_switch",
        "ralph_cancel",
        "ralph_help",
      ];

      for (const tool of tools) {
        expect(text).toContain(tool);
      }
    });

    test("includes tools table with headers", () => {
      // Act
      const result = handleHelp(logger);

      // Assert
      expect(result.content[0].text).toContain("## Available Tools");
      expect(result.content[0].text).toContain("| Tool | Description | Arguments |");
      expect(result.content[0].text).toContain("|------|-------------|-----------|");
    });

    test("includes tool descriptions", () => {
      // Act
      const result = handleHelp(logger);
      const text = result.content[0].text;

      // Assert - Check some descriptions
      expect(text).toContain("Create a new spec");
      expect(text).toContain("Run research phase");
      expect(text).toContain("Execute tasks");
      expect(text).toContain("Mark a phase as complete");
      expect(text).toContain("List all specs");
    });

    test("includes tool arguments", () => {
      // Act
      const result = handleHelp(logger);
      const text = result.content[0].text;

      // Assert - Check argument examples
      expect(text).toContain("name?, goal?, quick?");
      expect(text).toContain("spec_name?");
      expect(text).toContain("max_iterations?");
      expect(text).toContain("phase, summary");
      expect(text).toContain("(none)");
    });

    test("includes quick start example", () => {
      // Act
      const result = handleHelp(logger);

      // Assert
      expect(result.content[0].text).toContain("## Quick Start");
      expect(result.content[0].text).toContain("ralph_start");
      expect(result.content[0].text).toContain("goal:");
      expect(result.content[0].text).toContain("quick: true");
    });

    test("includes file structure information", () => {
      // Act
      const result = handleHelp(logger);
      const text = result.content[0].text;

      // Assert
      expect(text).toContain("./specs/<name>/");
      expect(text).toContain(".current-spec");
      expect(text).toContain(".ralph-state.json");
    });

    test("does not return error", () => {
      // Act
      const result = handleHelp(logger);

      // Assert
      expect(result.isError).toBeUndefined();
    });
  });

  describe("without logger", () => {
    test("works without logger parameter", () => {
      // Act
      const result = handleHelp();

      // Assert
      expect(result.content).toHaveLength(1);
      expect(result.content[0].text).toContain("Ralph Specum");
    });
  });

  describe("error handling", () => {
    test("function executes without throwing", () => {
      // Act & Assert - Should not throw
      expect(() => handleHelp(logger)).not.toThrow();
    });
  });
});
