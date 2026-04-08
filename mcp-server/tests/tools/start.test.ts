/**
 * @module tests/tools/start.test
 * Unit tests for ralph_start tool handler
 */

import { describe, test, expect, beforeEach, afterEach } from "bun:test";
import { handleStart, StartInputSchema } from "../../src/tools/start";
import { FileManager } from "../../src/lib/files";
import { StateManager } from "../../src/lib/state";
import { MCPLogger } from "../../src/lib/logger";
import {
  createTempDir,
  cleanupTempDir,
  createMockSpecsDir,
  fileExists,
  readTestFile,
} from "../utils";
import { join } from "node:path";

describe("handleStart", () => {
  let tempDir: string;
  let specsDir: string;
  let fileManager: FileManager;
  let stateManager: StateManager;
  let logger: MCPLogger;

  beforeEach(async () => {
    tempDir = await createTempDir();
    specsDir = await createMockSpecsDir(tempDir);
    logger = new MCPLogger("TestStart");
    fileManager = new FileManager(tempDir, logger);
    stateManager = new StateManager(logger);
  });

  afterEach(async () => {
    await cleanupTempDir(tempDir);
  });

  describe("input validation with Zod", () => {
    test("accepts empty input", () => {
      const result = StartInputSchema.safeParse({});
      expect(result.success).toBe(true);
    });

    test("accepts name only", () => {
      const result = StartInputSchema.safeParse({ name: "my-spec" });
      expect(result.success).toBe(true);
      expect(result.data?.name).toBe("my-spec");
    });

    test("accepts goal only", () => {
      const result = StartInputSchema.safeParse({ goal: "Add authentication" });
      expect(result.success).toBe(true);
      expect(result.data?.goal).toBe("Add authentication");
    });

    test("accepts quick mode flag", () => {
      const result = StartInputSchema.safeParse({
        goal: "Test",
        quick: true
      });
      expect(result.success).toBe(true);
      expect(result.data?.quick).toBe(true);
    });

    test("accepts all parameters", () => {
      const result = StartInputSchema.safeParse({
        name: "auth-feature",
        goal: "Add authentication",
        quick: true
      });
      expect(result.success).toBe(true);
    });

    test("rejects empty string name", () => {
      const result = StartInputSchema.safeParse({ name: "" });
      expect(result.success).toBe(false);
    });

    test("rejects empty string goal", () => {
      const result = StartInputSchema.safeParse({ goal: "" });
      expect(result.success).toBe(false);
    });
  });

  describe("success responses", () => {
    test("creates spec with provided name", async () => {
      // Act
      const result = handleStart(
        fileManager,
        stateManager,
        { name: "my-feature", goal: "Test goal" },
        logger
      );

      // Assert
      expect(result.isError).toBeUndefined();
      expect(result.content[0].text).toContain("# Spec Created: my-feature");
      expect(result.content[0].text).toContain("**Goal**: Test goal");
      expect(result.content[0].text).toContain("**Phase**: research");

      // Verify files created
      const specDir = join(specsDir, "my-feature");
      expect(await fileExists(specDir)).toBe(true);
      expect(await fileExists(join(specDir, ".progress.md"))).toBe(true);
      expect(await fileExists(join(specDir, ".ralph-state.json"))).toBe(true);
    });

    test("generates name from goal when name not provided", async () => {
      // Act
      const result = handleStart(
        fileManager,
        stateManager,
        { goal: "Add user authentication" },
        logger
      );

      // Assert
      expect(result.content[0].text).toContain("add-user-authentication");
      expect(await fileExists(join(specsDir, "add-user-authentication"))).toBe(true);
    });

    test("converts goal to kebab-case for name generation", async () => {
      // Act
      const result = handleStart(
        fileManager,
        stateManager,
        { goal: "Add  Multiple   Spaces   And CAPS" },
        logger
      );

      // Assert
      expect(result.content[0].text).toContain("add-multiple-spaces-and-caps");
    });

    test("removes special characters from generated name", async () => {
      // Act
      const result = handleStart(
        fileManager,
        stateManager,
        { goal: "Fix bug #123! (urgent)" },
        logger
      );

      // Assert
      expect(result.content[0].text).toContain("fix-bug-123-urgent");
    });

    test("truncates long goals for name generation", async () => {
      // Act
      const longGoal = "This is a very long goal description that should be truncated to prevent excessively long spec names";
      const result = handleStart(
        fileManager,
        stateManager,
        { goal: longGoal },
        logger
      );

      // Assert - Name should be <= 50 chars from goal
      const text = result.content[0].text;
      const match = text.match(/# Spec Created: ([^\n]+)/);
      expect(match).not.toBeNull();
      expect(match![1].length).toBeLessThanOrEqual(60); // Some margin for conversion
    });

    test("appends suffix for duplicate spec names", async () => {
      // Arrange
      await createMockSpecsDir(tempDir, ["my-spec", "my-spec-2"]);

      // Act
      const result = handleStart(
        fileManager,
        stateManager,
        { name: "my-spec" },
        logger
      );

      // Assert
      expect(result.content[0].text).toContain("my-spec-3");
      expect(await fileExists(join(specsDir, "my-spec-3"))).toBe(true);
    });

    test("creates default goal when only name provided", async () => {
      // Act
      const result = handleStart(
        fileManager,
        stateManager,
        { name: "my-feature" },
        logger
      );

      // Assert
      expect(result.content[0].text).toContain("**Goal**: Implement my-feature");
    });

    test("initializes state with research phase", async () => {
      // Act
      handleStart(
        fileManager,
        stateManager,
        { name: "test-spec" },
        logger
      );

      // Assert
      const specDir = join(specsDir, "test-spec");
      const state = stateManager.read(specDir);
      expect(state).not.toBeNull();
      expect(state?.phase).toBe("research");
      expect(state?.source).toBe("spec");
      expect(state?.name).toBe("test-spec");
    });

    test("sets new spec as current spec", async () => {
      // Act
      handleStart(
        fileManager,
        stateManager,
        { name: "new-spec" },
        logger
      );

      // Assert
      expect(fileManager.getCurrentSpec()).toBe("new-spec");
    });

    test("shows quick mode status in response", async () => {
      // Act - with quick mode
      const resultQuick = handleStart(
        fileManager,
        stateManager,
        { name: "quick-spec", goal: "Test", quick: true },
        logger
      );

      // Assert
      expect(resultQuick.content[0].text).toContain("**Quick mode**: Yes");

      // Act - without quick mode
      const resultNormal = handleStart(
        fileManager,
        stateManager,
        { name: "normal-spec", goal: "Test", quick: false },
        logger
      );

      // Assert
      expect(resultNormal.content[0].text).toContain("**Quick mode**: No");
    });

    test("includes next step instructions", async () => {
      // Act
      const result = handleStart(
        fileManager,
        stateManager,
        { name: "test-spec" },
        logger
      );

      // Assert
      expect(result.content[0].text).toContain("## Next Step");
      expect(result.content[0].text).toContain("ralph_research");
    });

    test("creates .progress.md with goal content", async () => {
      // Act
      handleStart(
        fileManager,
        stateManager,
        { name: "test-spec", goal: "My test goal" },
        logger
      );

      // Assert
      const progressContent = await readTestFile(
        join(specsDir, "test-spec", ".progress.md")
      );
      expect(progressContent).toContain("My test goal");
    });
  });

  describe("error responses", () => {
    test("returns error when neither name nor goal provided", () => {
      // Act
      const result = handleStart(fileManager, stateManager, {}, logger);

      // Assert
      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("Validation error");
      expect(result.content[0].text).toContain("'name' or 'goal' must be provided");
    });

    test("returns error for quick mode without goal", () => {
      // Act
      const result = handleStart(
        fileManager,
        stateManager,
        { name: "test", quick: true },
        logger
      );

      // Assert
      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("Quick mode requires a goal");
    });

    test("returns error when goal produces empty name", () => {
      // Act
      const result = handleStart(
        fileManager,
        stateManager,
        { goal: "!@#$%^&*()" },
        logger
      );

      // Assert
      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("Could not generate spec name");
    });
  });

  describe("error handling", () => {
    test("handles file operation errors gracefully", () => {
      // Arrange - Create a mock that returns false for createSpecDir
      const brokenFileManager = {
        specExists: () => false,
        createSpecDir: () => false,
        getCurrentSpec: () => null,
        setCurrentSpec: () => true,
        writeSpecFile: () => true,
        getSpecDir: (name: string) => join(specsDir, name),
      } as unknown as FileManager;

      // Act
      const result = handleStart(
        brokenFileManager,
        stateManager,
        { name: "test" },
        logger
      );

      // Assert
      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("File operation failed");
    });

    test("handles unexpected errors gracefully", () => {
      // Arrange - Create a mock that throws
      const brokenFileManager = {
        specExists: () => { throw new Error("Test error"); },
      } as unknown as FileManager;

      // Act
      const result = handleStart(
        brokenFileManager,
        stateManager,
        { name: "test" },
        logger
      );

      // Assert
      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("unexpected error");
    });
  });
});
