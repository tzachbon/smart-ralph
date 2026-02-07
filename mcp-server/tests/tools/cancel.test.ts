/**
 * @module tests/tools/cancel.test
 * Unit tests for ralph_cancel tool handler
 */

import { describe, test, expect, beforeEach, afterEach } from "bun:test";
import { handleCancel, CancelInputSchema } from "../../src/tools/cancel";
import { FileManager } from "../../src/lib/files";
import { StateManager } from "../../src/lib/state";
import { MCPLogger } from "../../src/lib/logger";
import {
  createTempDir,
  cleanupTempDir,
  createMockSpecsDir,
  createMockStateFile,
  createMockCurrentSpec,
  createMockProgressFile,
  fileExists,
} from "../utils";
import { join } from "node:path";

describe("handleCancel", () => {
  let tempDir: string;
  let specsDir: string;
  let fileManager: FileManager;
  let stateManager: StateManager;
  let logger: MCPLogger;

  beforeEach(async () => {
    tempDir = await createTempDir();
    specsDir = await createMockSpecsDir(tempDir);
    logger = new MCPLogger("TestCancel");
    fileManager = new FileManager(tempDir, logger);
    stateManager = new StateManager(logger);
  });

  afterEach(async () => {
    await cleanupTempDir(tempDir);
  });

  describe("input validation with Zod", () => {
    test("accepts empty input (uses current spec)", () => {
      const result = CancelInputSchema.safeParse({});
      expect(result.success).toBe(true);
    });

    test("accepts spec_name parameter", () => {
      const result = CancelInputSchema.safeParse({ spec_name: "my-spec" });
      expect(result.success).toBe(true);
      expect(result.data?.spec_name).toBe("my-spec");
    });

    test("accepts delete_files parameter", () => {
      const result = CancelInputSchema.safeParse({ delete_files: true });
      expect(result.success).toBe(true);
      expect(result.data?.delete_files).toBe(true);
    });

    test("defaults delete_files to false", () => {
      const result = CancelInputSchema.safeParse({});
      expect(result.success).toBe(true);
      expect(result.data?.delete_files).toBe(false);
    });

    test("accepts both parameters together", () => {
      const result = CancelInputSchema.safeParse({
        spec_name: "test",
        delete_files: true
      });
      expect(result.success).toBe(true);
    });
  });

  describe("success responses", () => {
    test("cancels current spec by deleting state file", async () => {
      // Arrange
      const specDir = join(specsDir, "test-spec");
      await createMockSpecsDir(tempDir, ["test-spec"]);
      await createMockStateFile(specDir, { phase: "research" });
      await createMockCurrentSpec(specsDir, "test-spec");

      // Act
      const result = handleCancel(fileManager, stateManager, {}, logger);

      // Assert
      expect(result.isError).toBeUndefined();
      expect(result.content[0].text).toContain('"test-spec" cancelled');
      expect(result.content[0].text).toContain("Deleted .ralph-state.json");
      expect(result.content[0].text).toContain("Spec files preserved");

      // State file should be gone
      expect(stateManager.exists(specDir)).toBe(false);
      // But spec directory should still exist
      expect(await fileExists(specDir)).toBe(true);
    });

    test("cancels named spec instead of current", async () => {
      // Arrange
      await createMockSpecsDir(tempDir, ["current", "target"]);
      await createMockStateFile(join(specsDir, "current"), { phase: "research" });
      await createMockStateFile(join(specsDir, "target"), { phase: "design" });
      await createMockCurrentSpec(specsDir, "current");

      // Act
      const result = handleCancel(fileManager, stateManager, { spec_name: "target" }, logger);

      // Assert
      expect(result.content[0].text).toContain('"target" cancelled');
      expect(stateManager.exists(join(specsDir, "target"))).toBe(false);
      // Current spec state should be untouched
      expect(stateManager.exists(join(specsDir, "current"))).toBe(true);
    });

    test("deletes spec directory when delete_files is true", async () => {
      // Arrange
      const specDir = join(specsDir, "test-spec");
      await createMockSpecsDir(tempDir, ["test-spec"]);
      await createMockStateFile(specDir, { phase: "research" });
      await createMockProgressFile(specDir);
      await createMockCurrentSpec(specsDir, "test-spec");

      // Act
      const result = handleCancel(
        fileManager,
        stateManager,
        { delete_files: true },
        logger
      );

      // Assert
      expect(result.content[0].text).toContain("cancelled and deleted");
      expect(result.content[0].text).toContain("Deleted spec directory");
      expect(await fileExists(specDir)).toBe(false);
    });

    test("switches to another spec when deleting current spec", async () => {
      // Arrange
      await createMockSpecsDir(tempDir, ["to-delete", "remaining"]);
      await createMockStateFile(join(specsDir, "to-delete"), { phase: "research" });
      await createMockStateFile(join(specsDir, "remaining"), { phase: "design" });
      await createMockCurrentSpec(specsDir, "to-delete");

      // Act
      const result = handleCancel(
        fileManager,
        stateManager,
        { spec_name: "to-delete", delete_files: true },
        logger
      );

      // Assert
      expect(result.content[0].text).toContain("Switched current spec to:");
      expect(fileManager.getCurrentSpec()).toBe("remaining");
    });

    test("reports no remaining specs when deleting last spec", async () => {
      // Arrange
      const specDir = join(specsDir, "last-spec");
      await createMockSpecsDir(tempDir, ["last-spec"]);
      await createMockStateFile(specDir, { phase: "research" });
      await createMockCurrentSpec(specsDir, "last-spec");

      // Act
      const result = handleCancel(
        fileManager,
        stateManager,
        { delete_files: true },
        logger
      );

      // Assert
      expect(result.content[0].text).toContain("No remaining specs");
    });

    test("succeeds even when state file does not exist", async () => {
      // Arrange
      await createMockSpecsDir(tempDir, ["test-spec"]);
      await createMockCurrentSpec(specsDir, "test-spec");
      // No state file created

      // Act
      const result = handleCancel(fileManager, stateManager, {}, logger);

      // Assert
      // Should still succeed - state delete returns true even if file doesn't exist
      expect(result.isError).toBeUndefined();
      expect(result.content[0].text).toContain('"test-spec" cancelled');
    });
  });

  describe("error responses", () => {
    test("returns error when no spec specified and no current spec", () => {
      // Act
      const result = handleCancel(fileManager, stateManager, {}, logger);

      // Assert
      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("Missing prerequisites");
      expect(result.content[0].text).toContain("No spec specified");
    });

    test("returns error when named spec does not exist", async () => {
      // Arrange
      await createMockSpecsDir(tempDir, ["existing"]);

      // Act
      const result = handleCancel(
        fileManager,
        stateManager,
        { spec_name: "non-existent" },
        logger
      );

      // Assert
      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("Spec not found");
      expect(result.content[0].text).toContain('"non-existent"');
    });
  });

  describe("error handling", () => {
    test("handles unexpected errors gracefully", () => {
      // Arrange - Create a mock that throws
      const brokenFileManager = {
        getCurrentSpec: () => { throw new Error("Test error"); },
        specExists: () => true,
        getSpecDir: () => "/test",
        deleteSpec: () => true,
        listSpecs: () => [],
      } as unknown as FileManager;

      // Act
      const result = handleCancel(brokenFileManager, stateManager, {}, logger);

      // Assert
      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("unexpected error");
    });
  });
});
