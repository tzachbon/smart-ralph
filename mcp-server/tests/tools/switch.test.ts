/**
 * @module tests/tools/switch.test
 * Unit tests for ralph_switch tool handler
 */

import { describe, test, expect, beforeEach, afterEach } from "bun:test";
import { handleSwitch, SwitchInputSchema } from "../../src/tools/switch";
import { FileManager } from "../../src/lib/files";
import { MCPLogger } from "../../src/lib/logger";
import {
  createTempDir,
  cleanupTempDir,
  createMockSpecsDir,
  createMockCurrentSpec,
} from "../utils";
import { join } from "node:path";

describe("handleSwitch", () => {
  let tempDir: string;
  let specsDir: string;
  let fileManager: FileManager;
  let logger: MCPLogger;

  beforeEach(async () => {
    tempDir = await createTempDir();
    specsDir = await createMockSpecsDir(tempDir);
    logger = new MCPLogger("TestSwitch");
    fileManager = new FileManager(tempDir, logger);
  });

  afterEach(async () => {
    await cleanupTempDir(tempDir);
  });

  describe("input validation with Zod", () => {
    test("validates required name field", () => {
      const result = SwitchInputSchema.safeParse({});
      expect(result.success).toBe(false);
    });

    test("rejects empty string name", () => {
      const result = SwitchInputSchema.safeParse({ name: "" });
      expect(result.success).toBe(false);
    });

    test("accepts valid name", () => {
      const result = SwitchInputSchema.safeParse({ name: "my-spec" });
      expect(result.success).toBe(true);
      expect(result.data?.name).toBe("my-spec");
    });

    test("returns validation error for missing name", () => {
      // Act
      const result = handleSwitch(fileManager, {}, logger);

      // Assert
      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("Validation error");
    });

    test("returns validation error for empty name", () => {
      // Act
      const result = handleSwitch(fileManager, { name: "" }, logger);

      // Assert
      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("Validation error");
    });
  });

  describe("success responses", () => {
    test("switches to existing spec", async () => {
      // Arrange
      await createMockSpecsDir(tempDir, ["spec-a", "spec-b"]);
      await createMockCurrentSpec(specsDir, "spec-a");

      // Act
      const result = handleSwitch(fileManager, { name: "spec-b" }, logger);

      // Assert
      expect(result.isError).toBeUndefined();
      expect(result.content[0].text).toContain('Switched to spec "spec-b"');
      expect(result.content[0].text).toContain("Previous: spec-a");
      expect(result.content[0].text).toContain("Current: spec-b");

      // Verify file was updated
      expect(fileManager.getCurrentSpec()).toBe("spec-b");
    });

    test("returns already on spec message when switching to current", async () => {
      // Arrange
      await createMockSpecsDir(tempDir, ["my-spec"]);
      await createMockCurrentSpec(specsDir, "my-spec");

      // Act
      const result = handleSwitch(fileManager, { name: "my-spec" }, logger);

      // Assert
      expect(result.isError).toBeUndefined();
      expect(result.content[0].text).toContain('Already on spec "my-spec"');
    });

    test("shows (none) as previous when no current spec", async () => {
      // Arrange
      await createMockSpecsDir(tempDir, ["target-spec"]);
      // No current spec set

      // Act
      const result = handleSwitch(fileManager, { name: "target-spec" }, logger);

      // Assert
      expect(result.content[0].text).toContain("Previous: (none)");
      expect(result.content[0].text).toContain("Current: target-spec");
    });
  });

  describe("error responses", () => {
    test("returns error when spec does not exist", async () => {
      // Arrange
      await createMockSpecsDir(tempDir, ["existing-spec"]);

      // Act
      const result = handleSwitch(fileManager, { name: "non-existent" }, logger);

      // Assert
      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("Spec not found");
      expect(result.content[0].text).toContain('"non-existent"');
      expect(result.content[0].text).toContain("Available specs:");
      expect(result.content[0].text).toContain("existing-spec");
    });

    test("returns error with (none) available when no specs exist", () => {
      // Act
      const result = handleSwitch(fileManager, { name: "any-spec" }, logger);

      // Assert
      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("Available specs: (none)");
    });
  });

  describe("error handling", () => {
    test("handles unexpected errors gracefully", () => {
      // Arrange - Create a mock that throws
      const brokenFileManager = {
        specExists: () => { throw new Error("Test error"); },
        listSpecs: () => [],
        getCurrentSpec: () => null,
        setCurrentSpec: () => true,
      } as unknown as FileManager;

      // Act
      const result = handleSwitch(brokenFileManager, { name: "test" }, logger);

      // Assert
      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("unexpected error");
    });
  });
});
