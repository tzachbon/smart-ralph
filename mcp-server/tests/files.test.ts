/**
 * @module tests/files.test
 * Unit tests for FileManager
 */

import { describe, test, expect, beforeEach, afterEach } from "bun:test";
import { FileManager } from "../src/lib/files";
import { MCPLogger } from "../src/lib/logger";
import {
  createTempDir,
  cleanupTempDir,
  createMockSpecsDir,
  fileExists,
  readTestFile,
} from "./utils";
import { join } from "node:path";
import { writeFile, mkdir } from "node:fs/promises";

describe("FileManager", () => {
  let tempDir: string;
  let specsDir: string;
  let fileManager: FileManager;

  beforeEach(async () => {
    tempDir = await createTempDir();
    specsDir = await createMockSpecsDir(tempDir, []);
    // Create logger that won't output during tests
    const logger = new MCPLogger("TestFileManager");
    fileManager = new FileManager(tempDir, logger);
  });

  afterEach(async () => {
    await cleanupTempDir(tempDir);
  });

  describe("listSpecs()", () => {
    test("returns empty array when no specs exist", () => {
      // Act
      const result = fileManager.listSpecs();

      // Assert
      expect(result).toEqual([]);
    });

    test("returns only directories, not files", async () => {
      // Arrange - create a mix of directories and files
      await mkdir(join(specsDir, "spec-one"));
      await mkdir(join(specsDir, "spec-two"));
      await writeFile(join(specsDir, ".current-spec"), "spec-one");
      await writeFile(join(specsDir, "some-file.txt"), "content");

      // Act
      const result = fileManager.listSpecs();

      // Assert
      expect(result).toEqual(["spec-one", "spec-two"]);
      expect(result).not.toContain(".current-spec");
      expect(result).not.toContain("some-file.txt");
    });

    test("returns sorted list of spec names", async () => {
      // Arrange - create specs in non-alphabetical order
      await mkdir(join(specsDir, "zebra-spec"));
      await mkdir(join(specsDir, "alpha-spec"));
      await mkdir(join(specsDir, "mango-spec"));

      // Act
      const result = fileManager.listSpecs();

      // Assert
      expect(result).toEqual(["alpha-spec", "mango-spec", "zebra-spec"]);
    });

    test("returns empty array when specs directory does not exist", async () => {
      // Arrange - use a fileManager with a non-existent base path
      const nonExistentManager = new FileManager(
        join(tempDir, "non-existent"),
        new MCPLogger("Test")
      );

      // Act
      const result = nonExistentManager.listSpecs();

      // Assert
      expect(result).toEqual([]);
    });
  });

  describe("specExists()", () => {
    test("returns true when spec directory exists", async () => {
      // Arrange
      await mkdir(join(specsDir, "existing-spec"));

      // Act
      const result = fileManager.specExists("existing-spec");

      // Assert
      expect(result).toBe(true);
    });

    test("returns false when spec directory does not exist", () => {
      // Act
      const result = fileManager.specExists("non-existent-spec");

      // Assert
      expect(result).toBe(false);
    });

    test("returns false when path exists but is a file, not a directory", async () => {
      // Arrange - create a file where spec would be
      await writeFile(join(specsDir, "file-not-dir"), "content");

      // Act
      const result = fileManager.specExists("file-not-dir");

      // Assert
      expect(result).toBe(false);
    });
  });

  describe("createSpecDir()", () => {
    test("creates spec directory when it does not exist", async () => {
      // Act
      const result = fileManager.createSpecDir("new-spec");

      // Assert
      expect(result).toBe(true);
      expect(await fileExists(join(specsDir, "new-spec"))).toBe(true);
    });

    test("creates nested directory structure if needed", async () => {
      // Arrange - use a fileManager that needs to create specs/ too
      await cleanupTempDir(specsDir); // Remove the specs directory
      const freshManager = new FileManager(tempDir, new MCPLogger("Test"));

      // Act
      const result = freshManager.createSpecDir("nested-spec");

      // Assert
      expect(result).toBe(true);
      expect(await fileExists(join(tempDir, "specs", "nested-spec"))).toBe(true);
    });

    test("returns true when directory already exists", async () => {
      // Arrange
      await mkdir(join(specsDir, "existing-spec"));

      // Act
      const result = fileManager.createSpecDir("existing-spec");

      // Assert
      expect(result).toBe(true);
    });
  });

  describe("getCurrentSpec()", () => {
    test("returns null when .current-spec file does not exist", () => {
      // Act
      const result = fileManager.getCurrentSpec();

      // Assert
      expect(result).toBeNull();
    });

    test("returns spec name when .current-spec file exists", async () => {
      // Arrange
      await writeFile(join(specsDir, ".current-spec"), "my-spec");

      // Act
      const result = fileManager.getCurrentSpec();

      // Assert
      expect(result).toBe("my-spec");
    });

    test("trims whitespace from spec name", async () => {
      // Arrange
      await writeFile(join(specsDir, ".current-spec"), "  my-spec  \n");

      // Act
      const result = fileManager.getCurrentSpec();

      // Assert
      expect(result).toBe("my-spec");
    });

    test("returns null when file is empty", async () => {
      // Arrange
      await writeFile(join(specsDir, ".current-spec"), "");

      // Act
      const result = fileManager.getCurrentSpec();

      // Assert
      expect(result).toBeNull();
    });

    test("returns null when file is whitespace only", async () => {
      // Arrange
      await writeFile(join(specsDir, ".current-spec"), "   \n  ");

      // Act
      const result = fileManager.getCurrentSpec();

      // Assert
      expect(result).toBeNull();
    });
  });

  describe("setCurrentSpec()", () => {
    test("creates .current-spec file with spec name", async () => {
      // Act
      const result = fileManager.setCurrentSpec("new-current-spec");

      // Assert
      expect(result).toBe(true);
      const content = await readTestFile(join(specsDir, ".current-spec"));
      expect(content).toBe("new-current-spec");
    });

    test("overwrites existing .current-spec file", async () => {
      // Arrange
      await writeFile(join(specsDir, ".current-spec"), "old-spec");

      // Act
      const result = fileManager.setCurrentSpec("new-spec");

      // Assert
      expect(result).toBe(true);
      const content = await readTestFile(join(specsDir, ".current-spec"));
      expect(content).toBe("new-spec");
    });

    test("creates specs directory if it does not exist", async () => {
      // Arrange
      await cleanupTempDir(specsDir);
      const freshManager = new FileManager(tempDir, new MCPLogger("Test"));

      // Act
      const result = freshManager.setCurrentSpec("my-spec");

      // Assert
      expect(result).toBe(true);
      expect(await fileExists(join(tempDir, "specs"))).toBe(true);
      const content = await readTestFile(join(tempDir, "specs", ".current-spec"));
      expect(content).toBe("my-spec");
    });
  });

  describe("readSpecFile()", () => {
    test("returns file content when file exists", async () => {
      // Arrange
      await mkdir(join(specsDir, "test-spec"));
      await writeFile(join(specsDir, "test-spec", "research.md"), "# Research\n\nContent here");

      // Act
      const result = fileManager.readSpecFile("test-spec", "research.md");

      // Assert
      expect(result).toBe("# Research\n\nContent here");
    });

    test("returns null when file does not exist", async () => {
      // Arrange
      await mkdir(join(specsDir, "test-spec"));

      // Act
      const result = fileManager.readSpecFile("test-spec", "nonexistent.md");

      // Assert
      expect(result).toBeNull();
    });

    test("returns null when spec directory does not exist", () => {
      // Act
      const result = fileManager.readSpecFile("nonexistent-spec", "file.md");

      // Assert
      expect(result).toBeNull();
    });

    test("reads different file types correctly", async () => {
      // Arrange
      await mkdir(join(specsDir, "test-spec"));
      await writeFile(
        join(specsDir, "test-spec", ".ralph-state.json"),
        JSON.stringify({ phase: "research" }, null, 2)
      );

      // Act
      const result = fileManager.readSpecFile("test-spec", ".ralph-state.json");

      // Assert
      expect(result).not.toBeNull();
      const parsed = JSON.parse(result!);
      expect(parsed.phase).toBe("research");
    });
  });

  describe("writeSpecFile()", () => {
    test("creates file in existing spec directory", async () => {
      // Arrange
      await mkdir(join(specsDir, "test-spec"));

      // Act
      const result = fileManager.writeSpecFile("test-spec", "design.md", "# Design\n\nNew content");

      // Assert
      expect(result).toBe(true);
      const content = await readTestFile(join(specsDir, "test-spec", "design.md"));
      expect(content).toBe("# Design\n\nNew content");
    });

    test("creates spec directory if it does not exist", async () => {
      // Act
      const result = fileManager.writeSpecFile("new-spec", "research.md", "Content");

      // Assert
      expect(result).toBe(true);
      expect(await fileExists(join(specsDir, "new-spec"))).toBe(true);
      const content = await readTestFile(join(specsDir, "new-spec", "research.md"));
      expect(content).toBe("Content");
    });

    test("overwrites existing file", async () => {
      // Arrange
      await mkdir(join(specsDir, "test-spec"));
      await writeFile(join(specsDir, "test-spec", "file.md"), "Old content");

      // Act
      const result = fileManager.writeSpecFile("test-spec", "file.md", "New content");

      // Assert
      expect(result).toBe(true);
      const content = await readTestFile(join(specsDir, "test-spec", "file.md"));
      expect(content).toBe("New content");
    });

    test("writes UTF-8 content correctly", async () => {
      // Arrange
      const utf8Content = "# Design\n\nUnicode: \u2603 \u2764 \u2728\nJapanese: \u3053\u3093\u306b\u3061\u306f";
      await mkdir(join(specsDir, "test-spec"));

      // Act
      const result = fileManager.writeSpecFile("test-spec", "unicode.md", utf8Content);

      // Assert
      expect(result).toBe(true);
      const content = await readTestFile(join(specsDir, "test-spec", "unicode.md"));
      expect(content).toBe(utf8Content);
    });
  });

  describe("path helper methods", () => {
    test("getSpecsDir() returns correct path", () => {
      // Act
      const result = fileManager.getSpecsDir();

      // Assert
      expect(result).toBe(join(tempDir, "specs"));
    });

    test("getSpecDir() returns correct path", () => {
      // Act
      const result = fileManager.getSpecDir("my-spec");

      // Assert
      expect(result).toBe(join(tempDir, "specs", "my-spec"));
    });

    test("getSpecFilePath() returns correct path", () => {
      // Act
      const result = fileManager.getSpecFilePath("my-spec", "design.md");

      // Assert
      expect(result).toBe(join(tempDir, "specs", "my-spec", "design.md"));
    });

    test("getCurrentSpecPath() returns correct path", () => {
      // Act
      const result = fileManager.getCurrentSpecPath();

      // Assert
      expect(result).toBe(join(tempDir, "specs", ".current-spec"));
    });
  });

  describe("deleteSpec()", () => {
    test("deletes existing spec directory and contents", async () => {
      // Arrange
      const specDir = join(specsDir, "to-delete");
      await mkdir(specDir);
      await writeFile(join(specDir, "file1.md"), "content1");
      await writeFile(join(specDir, "file2.md"), "content2");

      // Act
      const result = fileManager.deleteSpec("to-delete");

      // Assert
      expect(result).toBe(true);
      expect(await fileExists(specDir)).toBe(false);
    });

    test("returns true when spec does not exist", () => {
      // Act
      const result = fileManager.deleteSpec("nonexistent-spec");

      // Assert
      expect(result).toBe(true);
    });
  });

  describe("constructor", () => {
    test("uses process.cwd() when no basePath provided", () => {
      // Act
      const manager = new FileManager();

      // Assert - should use cwd as base
      expect(manager.getSpecsDir()).toBe(join(process.cwd(), "specs"));
    });

    test("creates default logger if none provided", () => {
      // Act
      const manager = new FileManager(tempDir);

      // Assert - should work without errors
      const exists = manager.specExists("test");
      expect(typeof exists).toBe("boolean");
    });

    test("uses provided logger", () => {
      // Act
      const customLogger = new MCPLogger("CustomLogger");
      const manager = new FileManager(tempDir, customLogger);

      // Assert - should work with custom logger
      const exists = manager.specExists("test");
      expect(typeof exists).toBe("boolean");
    });
  });
});
