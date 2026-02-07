/**
 * @module tests/utils
 * Test utilities for mocking file system and test fixtures
 */

import { mkdtemp, rm, mkdir, writeFile, readFile, stat } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { RalphState, Phase } from "../src/lib/types";

/**
 * Creates a temporary directory for isolated test execution.
 * The directory should be cleaned up after tests using cleanupTempDir.
 *
 * @returns Promise<string> - Path to the temporary directory
 *
 * @example
 * const tempDir = await createTempDir();
 * // ... run tests ...
 * await cleanupTempDir(tempDir);
 */
export async function createTempDir(): Promise<string> {
  return await mkdtemp(join(tmpdir(), "ralph-test-"));
}

/**
 * Cleans up a temporary directory created by createTempDir.
 * Safely handles non-existent directories.
 *
 * @param dir - Path to the directory to remove
 */
export async function cleanupTempDir(dir: string): Promise<void> {
  try {
    await rm(dir, { recursive: true, force: true });
  } catch {
    // Ignore errors - directory may not exist
  }
}

/**
 * Creates a mock specs directory structure for testing.
 * Sets up the base ./specs/ directory and optionally creates spec folders.
 *
 * @param baseDir - Base directory (temp directory)
 * @param specNames - Optional list of spec names to create
 * @returns Promise<string> - Path to the specs directory
 *
 * @example
 * const specsDir = await createMockSpecsDir(tempDir, ["my-spec"]);
 */
export async function createMockSpecsDir(
  baseDir: string,
  specNames: string[] = []
): Promise<string> {
  const specsDir = join(baseDir, "specs");
  await mkdir(specsDir, { recursive: true });

  for (const name of specNames) {
    await mkdir(join(specsDir, name), { recursive: true });
  }

  return specsDir;
}

/**
 * Creates a mock .ralph-state.json file in a spec directory.
 *
 * @param specDir - Path to the spec directory
 * @param state - Partial RalphState to write (defaults applied)
 *
 * @example
 * await createMockStateFile(specDir, { phase: "requirements" });
 */
export async function createMockStateFile(
  specDir: string,
  state: Partial<RalphState> = {}
): Promise<void> {
  // Extract spec name from path for default values
  const specName = specDir.split("/").pop() ?? "test-spec";
  const defaultState: RalphState = {
    source: "spec",
    name: specName,
    basePath: `./specs/${specName}`,
    phase: "research",
    ...state,
  };
  await writeFile(
    join(specDir, ".ralph-state.json"),
    JSON.stringify(defaultState, null, 2)
  );
}

/**
 * Creates a mock .progress.md file in a spec directory.
 *
 * @param specDir - Path to the spec directory
 * @param content - Optional content (defaults to basic progress template)
 *
 * @example
 * await createMockProgressFile(specDir, "# Progress\n\n## Goal\nTest goal");
 */
export async function createMockProgressFile(
  specDir: string,
  content?: string
): Promise<void> {
  const defaultContent = `# Progress

## Original Goal
Test goal

## Status
- Phase: research
- Started: 2026-01-26

## Completed Tasks
(none)

## Current Task
Awaiting next task

## Learnings
(none)

## Blockers
(none)

## Next
Begin research phase
`;
  await writeFile(join(specDir, ".progress.md"), content ?? defaultContent);
}

/**
 * Creates a mock .current-spec file in the specs directory.
 *
 * @param specsDir - Path to the specs directory
 * @param specName - Name of the current spec
 *
 * @example
 * await createMockCurrentSpec(specsDir, "my-spec");
 */
export async function createMockCurrentSpec(
  specsDir: string,
  specName: string
): Promise<void> {
  await writeFile(join(specsDir, ".current-spec"), specName);
}

/**
 * Creates a mock tasks.md file in a spec directory.
 *
 * @param specDir - Path to the spec directory
 * @param tasks - Array of task descriptions (unchecked by default)
 * @param completedIndices - Array of indices that should be marked as completed
 *
 * @example
 * await createMockTasksFile(specDir, ["Task 1", "Task 2"], [0]);
 * // Creates tasks with Task 1 checked, Task 2 unchecked
 */
export async function createMockTasksFile(
  specDir: string,
  tasks: string[] = ["1.1 First task", "1.2 Second task"],
  completedIndices: number[] = []
): Promise<void> {
  const taskLines = tasks.map((task, index) => {
    const checked = completedIndices.includes(index) ? "x" : " ";
    return `- [${checked}] ${task}`;
  });

  const content = `---
spec: test-spec
phase: tasks
total_tasks: ${tasks.length}
---

# Tasks

## Phase 1: POC

${taskLines.join("\n")}
`;
  await writeFile(join(specDir, "tasks.md"), content);
}

/**
 * Reads a file and returns its content as a string.
 * Useful for asserting file contents in tests.
 *
 * @param filePath - Absolute path to the file
 * @returns Promise<string> - File contents
 *
 * @example
 * const content = await readTestFile(join(specDir, ".progress.md"));
 * expect(content).toContain("research");
 */
export async function readTestFile(filePath: string): Promise<string> {
  return await readFile(filePath, "utf-8");
}

/**
 * Checks if a file or directory exists at the given path.
 *
 * @param filePath - Absolute path to check
 * @returns Promise<boolean> - True if file or directory exists
 *
 * @example
 * const exists = await fileExists(join(specDir, ".ralph-state.json"));
 */
export async function fileExists(filePath: string): Promise<boolean> {
  try {
    await stat(filePath);
    return true;
  } catch {
    return false;
  }
}

/**
 * Creates a complete mock spec setup for integration testing.
 * Sets up tempDir, specs directory, spec folder, state file, and progress file.
 *
 * @param specName - Name of the spec to create
 * @param options - Configuration options
 * @returns Object with paths and cleanup function
 *
 * @example
 * const { tempDir, specDir, specsDir, cleanup } = await createFullMockSpec("test-spec", {
 *   phase: "design",
 *   withTasks: true
 * });
 * try {
 *   // ... run tests ...
 * } finally {
 *   await cleanup();
 * }
 */
export async function createFullMockSpec(
  specName: string,
  options: {
    phase?: Phase;
    withTasks?: boolean;
    tasks?: string[];
    completedTasks?: number[];
    progressContent?: string;
  } = {}
): Promise<{
  tempDir: string;
  specsDir: string;
  specDir: string;
  cleanup: () => Promise<void>;
}> {
  const tempDir = await createTempDir();
  const specsDir = await createMockSpecsDir(tempDir, [specName]);
  const specDir = join(specsDir, specName);

  await createMockStateFile(specDir, { phase: options.phase ?? "research" });
  await createMockProgressFile(specDir, options.progressContent);
  await createMockCurrentSpec(specsDir, specName);

  if (options.withTasks || options.tasks) {
    await createMockTasksFile(
      specDir,
      options.tasks,
      options.completedTasks ?? []
    );
  }

  return {
    tempDir,
    specsDir,
    specDir,
    cleanup: async () => cleanupTempDir(tempDir),
  };
}

/**
 * Mock FileManager for unit testing tools without file system access.
 * Provides in-memory implementation of FileManager interface.
 */
export class MockFileManager {
  private files: Map<string, string> = new Map();
  private directories: Set<string> = new Set();
  private currentSpec: string | null = null;

  constructor(private basePath: string = "/mock") {}

  /**
   * Set up mock files for testing
   */
  setFile(relativePath: string, content: string): void {
    this.files.set(join(this.basePath, relativePath), content);
  }

  /**
   * Set up mock directories for testing
   */
  setDirectory(relativePath: string): void {
    this.directories.add(join(this.basePath, relativePath));
  }

  /**
   * Mock implementations of FileManager methods
   */
  async readSpecFile(specName: string, fileName: string): Promise<string | null> {
    const path = join(this.basePath, "specs", specName, fileName);
    return this.files.get(path) ?? null;
  }

  async writeSpecFile(specName: string, fileName: string, content: string): Promise<void> {
    const path = join(this.basePath, "specs", specName, fileName);
    this.files.set(path, content);
  }

  async listSpecs(): Promise<string[]> {
    const specsPath = join(this.basePath, "specs");
    return Array.from(this.directories)
      .filter((d) => d.startsWith(specsPath) && d !== specsPath)
      .map((d) => d.replace(specsPath + "/", "").split("/")[0])
      .filter((v, i, a) => a.indexOf(v) === i); // unique
  }

  async specExists(specName: string): Promise<boolean> {
    return this.directories.has(join(this.basePath, "specs", specName));
  }

  async createSpecDir(specName: string): Promise<void> {
    this.directories.add(join(this.basePath, "specs", specName));
  }

  async deleteSpec(specName: string): Promise<void> {
    const prefix = join(this.basePath, "specs", specName);
    for (const path of this.files.keys()) {
      if (path.startsWith(prefix)) {
        this.files.delete(path);
      }
    }
    this.directories.delete(prefix);
  }

  async getCurrentSpec(): Promise<string | null> {
    return this.currentSpec;
  }

  async setCurrentSpec(specName: string): Promise<void> {
    this.currentSpec = specName;
  }

  getBasePath(): string {
    return this.basePath;
  }
}

/**
 * Mock StateManager for unit testing tools without file system access.
 */
export class MockStateManager {
  private states: Map<string, RalphState> = new Map();

  constructor(private basePath: string = "/mock") {}

  /**
   * Set up mock state for testing
   */
  setState(specName: string, state: RalphState): void {
    this.states.set(specName, state);
  }

  /**
   * Mock implementations of StateManager methods
   */
  async read(specDir: string): Promise<RalphState | null> {
    const specName = specDir.split("/").pop()!;
    return this.states.get(specName) ?? null;
  }

  async write(specDir: string, state: RalphState): Promise<void> {
    const specName = specDir.split("/").pop()!;
    this.states.set(specName, state);
  }

  async delete(specDir: string): Promise<void> {
    const specName = specDir.split("/").pop()!;
    this.states.delete(specName);
  }

  async exists(specDir: string): Promise<boolean> {
    const specName = specDir.split("/").pop()!;
    return this.states.has(specName);
  }
}
