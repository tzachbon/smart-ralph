/**
 * @module tests/state.test
 * Unit tests for StateManager
 */

import { describe, test, expect, beforeEach, afterEach } from "bun:test";
import { StateManager } from "../src/lib/state";
import { MCPLogger } from "../src/lib/logger";
import {
  createTempDir,
  cleanupTempDir,
  createMockSpecsDir,
  fileExists,
  readTestFile,
} from "./utils";
import { join } from "node:path";
import { writeFile, mkdir, readFile } from "node:fs/promises";
import type { RalphState } from "../src/lib/types";

describe("StateManager", () => {
  let tempDir: string;
  let specsDir: string;
  let specDir: string;
  let stateManager: StateManager;

  const validState: RalphState = {
    source: "spec",
    name: "test-spec",
    basePath: "/test/path",
    phase: "research",
  };

  beforeEach(async () => {
    tempDir = await createTempDir();
    specsDir = await createMockSpecsDir(tempDir, ["test-spec"]);
    specDir = join(specsDir, "test-spec");
    // Create logger that won't output during tests
    const logger = new MCPLogger("TestStateManager");
    stateManager = new StateManager(logger);
  });

  afterEach(async () => {
    await cleanupTempDir(tempDir);
  });

  describe("read()", () => {
    test("returns state when file exists and is valid", async () => {
      // Arrange
      await writeFile(
        join(specDir, ".ralph-state.json"),
        JSON.stringify(validState, null, 2)
      );

      // Act
      const result = stateManager.read(specDir);

      // Assert
      expect(result).not.toBeNull();
      expect(result?.phase).toBe("research");
      expect(result?.source).toBe("spec");
      expect(result?.name).toBe("test-spec");
      expect(result?.basePath).toBe("/test/path");
    });

    test("returns state with optional fields", async () => {
      // Arrange
      const stateWithOptionals: RalphState = {
        ...validState,
        taskIndex: 5,
        totalTasks: 10,
        taskIteration: 2,
        maxTaskIterations: 5,
        globalIteration: 1,
        maxGlobalIterations: 3,
        relatedSpecs: [
          { name: "other-spec", relevance: "high", reason: "Related feature" },
        ],
        parallelGroup: {
          startIndex: 0,
          endIndex: 3,
          taskIndices: [0, 1, 2, 3],
        },
        taskResults: {
          "0": { status: "success" },
          "1": { status: "failed", error: "Test error" },
        },
      };
      await writeFile(
        join(specDir, ".ralph-state.json"),
        JSON.stringify(stateWithOptionals, null, 2)
      );

      // Act
      const result = stateManager.read(specDir);

      // Assert
      expect(result).not.toBeNull();
      expect(result?.taskIndex).toBe(5);
      expect(result?.totalTasks).toBe(10);
      expect(result?.relatedSpecs?.length).toBe(1);
      expect(result?.parallelGroup?.taskIndices).toEqual([0, 1, 2, 3]);
      expect(result?.taskResults?.["0"]?.status).toBe("success");
      expect(result?.taskResults?.["1"]?.error).toBe("Test error");
    });

    test("returns null for missing file", () => {
      // Act - specDir exists but no state file
      const result = stateManager.read(specDir);

      // Assert
      expect(result).toBeNull();
    });

    test("returns null for non-existent directory", () => {
      // Act
      const result = stateManager.read(join(tempDir, "non-existent-spec"));

      // Assert
      expect(result).toBeNull();
    });

    test("handles corrupt JSON and creates backup", async () => {
      // Arrange
      const statePath = join(specDir, ".ralph-state.json");
      await writeFile(statePath, "{ invalid json }}}");

      // Act
      const result = stateManager.read(specDir);

      // Assert
      expect(result).toBeNull();
      // Should have created backup
      expect(await fileExists(join(specDir, ".ralph-state.json.bak"))).toBe(
        true
      );
      // Original file should be removed (renamed to backup)
      expect(await fileExists(statePath)).toBe(false);
    });

    test("handles invalid schema and creates backup", async () => {
      // Arrange - valid JSON but missing required fields
      const statePath = join(specDir, ".ralph-state.json");
      await writeFile(
        statePath,
        JSON.stringify({ phase: "research" }, null, 2)
      );

      // Act
      const result = stateManager.read(specDir);

      // Assert
      expect(result).toBeNull();
      expect(await fileExists(join(specDir, ".ralph-state.json.bak"))).toBe(
        true
      );
    });

    test("handles invalid phase value", async () => {
      // Arrange
      const invalidState = { ...validState, phase: "invalid-phase" };
      await writeFile(
        join(specDir, ".ralph-state.json"),
        JSON.stringify(invalidState, null, 2)
      );

      // Act
      const result = stateManager.read(specDir);

      // Assert
      expect(result).toBeNull();
    });

    test("handles empty file", async () => {
      // Arrange
      await writeFile(join(specDir, ".ralph-state.json"), "");

      // Act
      const result = stateManager.read(specDir);

      // Assert
      expect(result).toBeNull();
    });
  });

  describe("write()", () => {
    test("creates file when it doesn't exist", () => {
      // Act
      const result = stateManager.write(specDir, validState);

      // Assert
      expect(result).toBe(true);
      expect(stateManager.exists(specDir)).toBe(true);
    });

    test("overwrites existing file", async () => {
      // Arrange
      await writeFile(
        join(specDir, ".ralph-state.json"),
        JSON.stringify(validState, null, 2)
      );

      const updatedState: RalphState = {
        ...validState,
        phase: "requirements",
      };

      // Act
      const result = stateManager.write(specDir, updatedState);

      // Assert
      expect(result).toBe(true);
      const readBack = stateManager.read(specDir);
      expect(readBack?.phase).toBe("requirements");
    });

    test("atomic write - no partial content on disk", async () => {
      // Act
      stateManager.write(specDir, validState);

      // Assert - read the file directly to verify it's complete JSON
      const content = await readTestFile(join(specDir, ".ralph-state.json"));
      const parsed = JSON.parse(content);
      expect(parsed.phase).toBe("research");
      expect(parsed.source).toBe("spec");
    });

    test("creates directory if it doesn't exist", async () => {
      // Arrange
      const newSpecDir = join(specsDir, "new-spec");

      // Act
      const result = stateManager.write(newSpecDir, validState);

      // Assert
      expect(result).toBe(true);
      expect(await fileExists(newSpecDir)).toBe(true);
      expect(await fileExists(join(newSpecDir, ".ralph-state.json"))).toBe(
        true
      );
    });

    test("writes formatted JSON with indentation", async () => {
      // Act
      stateManager.write(specDir, validState);

      // Assert
      const content = await readTestFile(join(specDir, ".ralph-state.json"));
      expect(content).toContain("  "); // Has indentation
      expect(content.split("\n").length).toBeGreaterThan(1); // Multiple lines
    });

    test("cleans up temp file after successful write", async () => {
      // Act
      stateManager.write(specDir, validState);

      // Assert - no .tmp file should remain
      expect(await fileExists(join(specDir, ".ralph-state.json.tmp"))).toBe(
        false
      );
    });
  });

  describe("delete()", () => {
    test("removes existing file", async () => {
      // Arrange
      await writeFile(
        join(specDir, ".ralph-state.json"),
        JSON.stringify(validState, null, 2)
      );
      expect(stateManager.exists(specDir)).toBe(true);

      // Act
      const result = stateManager.delete(specDir);

      // Assert
      expect(result).toBe(true);
      expect(stateManager.exists(specDir)).toBe(false);
    });

    test("returns true when file doesn't exist (no error)", () => {
      // Act - file doesn't exist
      const result = stateManager.delete(specDir);

      // Assert
      expect(result).toBe(true);
    });

    test("returns true when directory doesn't exist", () => {
      // Act
      const result = stateManager.delete(join(tempDir, "non-existent"));

      // Assert
      expect(result).toBe(true);
    });
  });

  describe("exists()", () => {
    test("returns true when file exists", async () => {
      // Arrange
      await writeFile(
        join(specDir, ".ralph-state.json"),
        JSON.stringify(validState, null, 2)
      );

      // Act
      const result = stateManager.exists(specDir);

      // Assert
      expect(result).toBe(true);
    });

    test("returns false when file doesn't exist", () => {
      // Act
      const result = stateManager.exists(specDir);

      // Assert
      expect(result).toBe(false);
    });

    test("returns false when directory doesn't exist", () => {
      // Act
      const result = stateManager.exists(join(tempDir, "non-existent"));

      // Assert
      expect(result).toBe(false);
    });
  });

  describe("getStatePath()", () => {
    test("returns correct path", () => {
      // Act
      const result = stateManager.getStatePath(specDir);

      // Assert
      expect(result).toBe(join(specDir, ".ralph-state.json"));
    });
  });

  describe("constructor", () => {
    test("creates with default logger if none provided", () => {
      // Act
      const manager = new StateManager();

      // Assert - should not throw and should work
      const exists = manager.exists(specDir);
      expect(typeof exists).toBe("boolean");
    });

    test("uses provided logger", () => {
      // Act
      const customLogger = new MCPLogger("CustomLogger");
      const manager = new StateManager(customLogger);

      // Assert - should work with custom logger
      const exists = manager.exists(specDir);
      expect(typeof exists).toBe("boolean");
    });
  });
});
