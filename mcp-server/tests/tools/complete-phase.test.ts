/**
 * @module tests/tools/complete-phase.test
 * Unit tests for ralph_complete_phase tool handler
 */

import { describe, test, expect, beforeEach, afterEach } from "bun:test";
import { handleCompletePhase, CompletePhaseInputSchema } from "../../src/tools/complete-phase";
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
  readTestFile,
} from "../utils";
import { join } from "node:path";

describe("handleCompletePhase", () => {
  let tempDir: string;
  let specsDir: string;
  let fileManager: FileManager;
  let stateManager: StateManager;
  let logger: MCPLogger;

  beforeEach(async () => {
    tempDir = await createTempDir();
    specsDir = await createMockSpecsDir(tempDir);
    logger = new MCPLogger("TestCompletePhase");
    fileManager = new FileManager(tempDir, logger);
    stateManager = new StateManager(logger);
  });

  afterEach(async () => {
    await cleanupTempDir(tempDir);
  });

  describe("input validation with Zod", () => {
    test("requires phase parameter", () => {
      const result = CompletePhaseInputSchema.safeParse({
        summary: "Test summary"
      });
      expect(result.success).toBe(false);
    });

    test("requires summary parameter", () => {
      const result = CompletePhaseInputSchema.safeParse({
        phase: "research"
      });
      expect(result.success).toBe(false);
    });

    test("validates phase enum values", () => {
      const validPhases = ["research", "requirements", "design", "tasks", "execution"];
      for (const phase of validPhases) {
        const result = CompletePhaseInputSchema.safeParse({
          phase,
          summary: "Test"
        });
        expect(result.success).toBe(true);
      }
    });

    test("rejects invalid phase value", () => {
      const result = CompletePhaseInputSchema.safeParse({
        phase: "invalid",
        summary: "Test"
      });
      expect(result.success).toBe(false);
    });

    test("accepts optional spec_name", () => {
      const result = CompletePhaseInputSchema.safeParse({
        spec_name: "my-spec",
        phase: "research",
        summary: "Test"
      });
      expect(result.success).toBe(true);
      expect(result.data?.spec_name).toBe("my-spec");
    });

    test("rejects empty summary", () => {
      const result = CompletePhaseInputSchema.safeParse({
        phase: "research",
        summary: ""
      });
      expect(result.success).toBe(false);
    });

    test("returns validation error for missing required fields", () => {
      // Act
      const result = handleCompletePhase(
        fileManager,
        stateManager,
        { phase: "research" } as any,
        logger
      );

      // Assert
      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("Validation error");
    });
  });

  describe("success responses - phase transitions", () => {
    test("transitions from research to requirements", async () => {
      // Arrange
      const specDir = join(specsDir, "test-spec");
      await createMockSpecsDir(tempDir, ["test-spec"]);
      await createMockStateFile(specDir, { phase: "research" });
      await createMockProgressFile(specDir);
      await createMockCurrentSpec(specsDir, "test-spec");

      // Act
      const result = handleCompletePhase(
        fileManager,
        stateManager,
        { phase: "research", summary: "Research complete" },
        logger
      );

      // Assert
      expect(result.isError).toBeUndefined();
      expect(result.content[0].text).toContain("# Phase Complete: research");
      expect(result.content[0].text).toContain("**Next Phase**: requirements");
      expect(result.content[0].text).toContain("ralph_requirements");

      // Verify state updated
      const state = stateManager.read(specDir);
      expect(state?.phase).toBe("requirements");
    });

    test("transitions from requirements to design", async () => {
      // Arrange
      const specDir = join(specsDir, "test-spec");
      await createMockSpecsDir(tempDir, ["test-spec"]);
      await createMockStateFile(specDir, { phase: "requirements" });
      await createMockProgressFile(specDir);
      await createMockCurrentSpec(specsDir, "test-spec");

      // Act
      const result = handleCompletePhase(
        fileManager,
        stateManager,
        { phase: "requirements", summary: "Requirements done" },
        logger
      );

      // Assert
      expect(result.content[0].text).toContain("**Next Phase**: design");
      expect(result.content[0].text).toContain("ralph_design");

      const state = stateManager.read(specDir);
      expect(state?.phase).toBe("design");
    });

    test("transitions from design to tasks", async () => {
      // Arrange
      const specDir = join(specsDir, "test-spec");
      await createMockSpecsDir(tempDir, ["test-spec"]);
      await createMockStateFile(specDir, { phase: "design" });
      await createMockProgressFile(specDir);
      await createMockCurrentSpec(specsDir, "test-spec");

      // Act
      const result = handleCompletePhase(
        fileManager,
        stateManager,
        { phase: "design", summary: "Design finalized" },
        logger
      );

      // Assert
      expect(result.content[0].text).toContain("**Next Phase**: tasks");
      expect(result.content[0].text).toContain("ralph_tasks");

      const state = stateManager.read(specDir);
      expect(state?.phase).toBe("tasks");
    });

    test("transitions from tasks to execution", async () => {
      // Arrange
      const specDir = join(specsDir, "test-spec");
      await createMockSpecsDir(tempDir, ["test-spec"]);
      await createMockStateFile(specDir, { phase: "tasks" });
      await createMockProgressFile(specDir);
      await createMockCurrentSpec(specsDir, "test-spec");

      // Act
      const result = handleCompletePhase(
        fileManager,
        stateManager,
        { phase: "tasks", summary: "Tasks generated" },
        logger
      );

      // Assert
      expect(result.content[0].text).toContain("**Next Phase**: execution");
      expect(result.content[0].text).toContain("ralph_implement");

      const state = stateManager.read(specDir);
      expect(state?.phase).toBe("execution");
    });

    test("handles execution phase completion (no next phase)", async () => {
      // Arrange
      const specDir = join(specsDir, "test-spec");
      await createMockSpecsDir(tempDir, ["test-spec"]);
      await createMockStateFile(specDir, { phase: "execution" });
      await createMockProgressFile(specDir);
      await createMockCurrentSpec(specsDir, "test-spec");

      // Act
      const result = handleCompletePhase(
        fileManager,
        stateManager,
        { phase: "execution", summary: "All tasks complete" },
        logger
      );

      // Assert
      expect(result.content[0].text).toContain("**Status**: All phases complete");
      expect(result.content[0].text).toContain("ready for final review");
    });
  });

  describe("success responses - progress file updates", () => {
    test("appends summary to .progress.md", async () => {
      // Arrange
      const specDir = join(specsDir, "test-spec");
      await createMockSpecsDir(tempDir, ["test-spec"]);
      await createMockStateFile(specDir, { phase: "research" });
      await createMockProgressFile(specDir);
      await createMockCurrentSpec(specsDir, "test-spec");

      // Act
      handleCompletePhase(
        fileManager,
        stateManager,
        { phase: "research", summary: "Found important patterns" },
        logger
      );

      // Assert
      const progressContent = await readTestFile(join(specDir, ".progress.md"));
      expect(progressContent).toContain("Research Phase Complete");
      expect(progressContent).toContain("Found important patterns");
    });

    test("includes date in phase completion heading", async () => {
      // Arrange
      const specDir = join(specsDir, "test-spec");
      await createMockSpecsDir(tempDir, ["test-spec"]);
      await createMockStateFile(specDir, { phase: "design" });
      await createMockProgressFile(specDir);
      await createMockCurrentSpec(specsDir, "test-spec");

      // Act
      handleCompletePhase(
        fileManager,
        stateManager,
        { phase: "design", summary: "Architecture defined" },
        logger
      );

      // Assert
      const progressContent = await readTestFile(join(specDir, ".progress.md"));
      // Should contain date in format YYYY-MM-DD
      expect(progressContent).toMatch(/Design Phase Complete \(\d{4}-\d{2}-\d{2}\)/);
    });

    test("includes summary in response", async () => {
      // Arrange
      const specDir = join(specsDir, "test-spec");
      await createMockSpecsDir(tempDir, ["test-spec"]);
      await createMockStateFile(specDir, { phase: "requirements" });
      await createMockProgressFile(specDir);
      await createMockCurrentSpec(specsDir, "test-spec");

      // Act
      const result = handleCompletePhase(
        fileManager,
        stateManager,
        { phase: "requirements", summary: "User stories defined" },
        logger
      );

      // Assert
      expect(result.content[0].text).toContain("## Summary");
      expect(result.content[0].text).toContain("User stories defined");
    });
  });

  describe("success responses - named spec", () => {
    test("uses provided spec_name instead of current", async () => {
      // Arrange
      await createMockSpecsDir(tempDir, ["current", "target"]);
      await createMockStateFile(join(specsDir, "current"), { phase: "research" });
      await createMockStateFile(join(specsDir, "target"), { phase: "design" });
      await createMockProgressFile(join(specsDir, "target"));
      await createMockCurrentSpec(specsDir, "current");

      // Act
      const result = handleCompletePhase(
        fileManager,
        stateManager,
        { spec_name: "target", phase: "design", summary: "Done" },
        logger
      );

      // Assert
      expect(result.content[0].text).toContain("**Spec**: target");
      expect(stateManager.read(join(specsDir, "target"))?.phase).toBe("tasks");
      // Current spec should be unchanged
      expect(stateManager.read(join(specsDir, "current"))?.phase).toBe("research");
    });
  });

  describe("error responses", () => {
    test("returns error when no current spec and no spec_name provided", () => {
      // Act
      const result = handleCompletePhase(
        fileManager,
        stateManager,
        { phase: "research", summary: "Test" },
        logger
      );

      // Assert
      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("Missing prerequisites");
      expect(result.content[0].text).toContain("No spec specified");
    });

    test("returns error when spec does not exist", async () => {
      // Arrange
      await createMockSpecsDir(tempDir, ["existing"]);

      // Act
      const result = handleCompletePhase(
        fileManager,
        stateManager,
        { spec_name: "non-existent", phase: "research", summary: "Test" },
        logger
      );

      // Assert
      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("Spec not found");
    });

    test("returns error when state file is missing", async () => {
      // Arrange
      await createMockSpecsDir(tempDir, ["test-spec"]);
      await createMockCurrentSpec(specsDir, "test-spec");
      // No state file

      // Act
      const result = handleCompletePhase(
        fileManager,
        stateManager,
        { phase: "research", summary: "Test" },
        logger
      );

      // Assert
      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("Invalid state");
      expect(result.content[0].text).toContain("No state found");
    });

    test("returns error for phase mismatch", async () => {
      // Arrange
      const specDir = join(specsDir, "test-spec");
      await createMockSpecsDir(tempDir, ["test-spec"]);
      await createMockStateFile(specDir, { phase: "design" });
      await createMockCurrentSpec(specsDir, "test-spec");

      // Act
      const result = handleCompletePhase(
        fileManager,
        stateManager,
        { phase: "research", summary: "Test" },
        logger
      );

      // Assert
      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("Phase mismatch");
      expect(result.content[0].text).toContain('Current phase is "design"');
      expect(result.content[0].text).toContain('tried to complete "research"');
    });
  });

  describe("error handling", () => {
    test("handles state write errors", async () => {
      // Arrange
      const specDir = join(specsDir, "test-spec");
      await createMockSpecsDir(tempDir, ["test-spec"]);
      await createMockStateFile(specDir, { phase: "research" });
      await createMockProgressFile(specDir);
      await createMockCurrentSpec(specsDir, "test-spec");

      const brokenStateManager = {
        read: () => ({ phase: "research", source: "spec", name: "test", basePath: "/test" }),
        write: () => false,
      } as unknown as StateManager;

      // Act
      const result = handleCompletePhase(
        fileManager,
        brokenStateManager,
        { phase: "research", summary: "Test" },
        logger
      );

      // Assert
      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("File operation failed");
    });

    test("handles unexpected errors gracefully", () => {
      // Arrange
      const brokenFileManager = {
        getCurrentSpec: () => { throw new Error("Test error"); },
        specExists: () => true,
        getSpecDir: () => "/test",
      } as unknown as FileManager;

      // Act
      const result = handleCompletePhase(
        brokenFileManager,
        stateManager,
        { phase: "research", summary: "Test" },
        logger
      );

      // Assert
      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("unexpected error");
    });
  });
});
