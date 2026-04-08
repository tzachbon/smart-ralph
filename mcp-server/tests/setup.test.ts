/**
 * @module tests/setup.test
 * Basic test to verify test infrastructure is working
 */

import { describe, test, expect } from "bun:test";
import {
  createTempDir,
  cleanupTempDir,
  createMockSpecsDir,
  createMockStateFile,
  createMockProgressFile,
  fileExists,
} from "./utils";
import { join } from "node:path";

describe("Test Infrastructure", () => {
  test("bun test runs successfully", () => {
    expect(true).toBe(true);
  });

  test("createTempDir creates a temporary directory", async () => {
    const tempDir = await createTempDir();
    expect(tempDir).toContain("ralph-test-");
    await cleanupTempDir(tempDir);
  });

  test("createMockSpecsDir sets up specs directory", async () => {
    const tempDir = await createTempDir();
    try {
      const specsDir = await createMockSpecsDir(tempDir, ["test-spec"]);
      expect(await fileExists(join(specsDir, "test-spec"))).toBe(true);
    } finally {
      await cleanupTempDir(tempDir);
    }
  });

  test("mock state and progress files can be created", async () => {
    const tempDir = await createTempDir();
    try {
      const specsDir = await createMockSpecsDir(tempDir, ["test-spec"]);
      const specDir = join(specsDir, "test-spec");

      await createMockStateFile(specDir, { phase: "design" });
      await createMockProgressFile(specDir);

      expect(await fileExists(join(specDir, ".ralph-state.json"))).toBe(true);
      expect(await fileExists(join(specDir, ".progress.md"))).toBe(true);
    } finally {
      await cleanupTempDir(tempDir);
    }
  });
});
