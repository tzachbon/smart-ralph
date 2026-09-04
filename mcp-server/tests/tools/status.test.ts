/**
 * @module tests/tools/status.test
 * Unit tests for ralph_status tool handler
 */

import { describe, test, expect, beforeEach, afterEach } from "bun:test";
import { handleStatus } from "../../src/tools/status";
import { FileManager } from "../../src/lib/files";
import { StateManager } from "../../src/lib/state";
import { MCPLogger } from "../../src/lib/logger";
import {
  createTempDir,
  cleanupTempDir,
  createMockSpecsDir,
  createMockStateFile,
  createMockCurrentSpec,
} from "../utils";
import { join } from "node:path";
import type { RalphState } from "../../src/lib/types";

describe("handleStatus", () => {
  let tempDir: string;
  let specsDir: string;
  let fileManager: FileManager;
  let stateManager: StateManager;
  let logger: MCPLogger;

  beforeEach(async () => {
    tempDir = await createTempDir();
    specsDir = await createMockSpecsDir(tempDir);
    logger = new MCPLogger("TestStatus");
    fileManager = new FileManager(tempDir, logger);
    stateManager = new StateManager(logger);
  });

  afterEach(async () => {
    await cleanupTempDir(tempDir);
  });

  describe("success responses", () => {
    test("returns 'no specs found' message when no specs exist", () => {
      // Act
      const result = handleStatus(fileManager, stateManager, logger);

      // Assert
      expect(result.content).toHaveLength(1);
      expect(result.content[0].type).toBe("text");
      expect(result.content[0].text).toContain("No specs found");
      expect(result.content[0].text).toContain("ralph_start");
    });

    test("returns formatted status table with single spec", async () => {
      // Arrange
      const specDir = join(specsDir, "test-spec");
      await createMockSpecsDir(tempDir, ["test-spec"]);
      await createMockStateFile(specDir, { phase: "research" });
      await createMockCurrentSpec(specsDir, "test-spec");

      // Act
      const result = handleStatus(fileManager, stateManager, logger);

      // Assert
      expect(result.content).toHaveLength(1);
      expect(result.content[0].text).toContain("# Ralph Specs Status");
      expect(result.content[0].text).toContain("Current spec: test-spec");
      expect(result.content[0].text).toContain("| test-spec *");
      expect(result.content[0].text).toContain("| research |");
    });

    test("returns status for multiple specs", async () => {
      // Arrange
      await createMockSpecsDir(tempDir, ["spec-1", "spec-2", "spec-3"]);
      await createMockStateFile(join(specsDir, "spec-1"), { phase: "research" });
      await createMockStateFile(join(specsDir, "spec-2"), { phase: "design" });
      await createMockStateFile(join(specsDir, "spec-3"), { phase: "execution", taskIndex: 5, totalTasks: 10 });
      await createMockCurrentSpec(specsDir, "spec-2");

      // Act
      const result = handleStatus(fileManager, stateManager, logger);

      // Assert
      expect(result.content[0].text).toContain("spec-1");
      expect(result.content[0].text).toContain("spec-2");
      expect(result.content[0].text).toContain("spec-3");
      expect(result.content[0].text).toContain("| spec-2 *"); // Current spec marker
      expect(result.content[0].text).toContain("| 5/10 |"); // Task progress
    });

    test("shows task progress only for execution phase", async () => {
      // Arrange
      await createMockSpecsDir(tempDir, ["spec-1", "spec-2"]);
      await createMockStateFile(join(specsDir, "spec-1"), { phase: "research" });
      await createMockStateFile(join(specsDir, "spec-2"), {
        phase: "execution",
        taskIndex: 3,
        totalTasks: 8
      });

      // Act
      const result = handleStatus(fileManager, stateManager, logger);

      // Assert
      const text = result.content[0].text;
      // Research phase should show "-" for tasks
      expect(text).toMatch(/spec-1[^|]*\|[^|]*research[^|]*\|[^|]*-[^|]*\|/);
      // Execution phase should show task progress
      expect(text).toContain("3/8");
    });

    test("handles spec without state file (shows unknown phase)", async () => {
      // Arrange
      await createMockSpecsDir(tempDir, ["orphan-spec"]);
      // No state file created

      // Act
      const result = handleStatus(fileManager, stateManager, logger);

      // Assert
      expect(result.content[0].text).toContain("orphan-spec");
      expect(result.content[0].text).toContain("unknown");
      expect(result.content[0].text).toContain("No state file");
    });

    test("shows (none) when no current spec is set", async () => {
      // Arrange
      await createMockSpecsDir(tempDir, ["test-spec"]);
      await createMockStateFile(join(specsDir, "test-spec"), { phase: "research" });
      // No current spec set

      // Act
      const result = handleStatus(fileManager, stateManager, logger);

      // Assert
      expect(result.content[0].text).toContain("Current spec: (none)");
    });
  });

  describe("error handling", () => {
    test("handles unexpected errors gracefully", () => {
      // Arrange - Create a mock that throws
      const brokenFileManager = {
        listSpecs: () => { throw new Error("Test error"); },
        getCurrentSpec: () => null,
        getSpecDir: (name: string) => join(specsDir, name),
      } as unknown as FileManager;

      // Act
      const result = handleStatus(brokenFileManager, stateManager, logger);

      // Assert
      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("unexpected error");
    });
  });
});
