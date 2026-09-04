/**
 * @module tests/integration/workflow.test
 * Integration tests for full workflow: start -> research -> requirements -> design -> tasks
 */

import { describe, test, expect, beforeEach, afterEach } from "bun:test";
import { join } from "node:path";
import { FileManager } from "../../src/lib/files";
import { StateManager } from "../../src/lib/state";
import { MCPLogger } from "../../src/lib/logger";
import { handleStart } from "../../src/tools/start";
import { handleResearch } from "../../src/tools/research";
import { handleRequirements } from "../../src/tools/requirements";
import { handleDesign } from "../../src/tools/design";
import { handleTasks } from "../../src/tools/tasks";
import { handleCompletePhase } from "../../src/tools/complete-phase";
import { handleStatus } from "../../src/tools/status";
import { handleImplement } from "../../src/tools/implement";
import {
  createTempDir,
  cleanupTempDir,
  fileExists,
  readTestFile,
} from "../utils";

describe("Integration: Full Workflow", () => {
  let tempDir: string;
  let fileManager: FileManager;
  let stateManager: StateManager;
  let logger: MCPLogger;

  beforeEach(async () => {
    tempDir = await createTempDir();
    logger = new MCPLogger("TestWorkflow");
    fileManager = new FileManager(tempDir, logger);
    stateManager = new StateManager(logger);
  });

  afterEach(async () => {
    await cleanupTempDir(tempDir);
  });

  describe("start -> research workflow", () => {
    test("creates spec and enters research phase", async () => {
      // Start a new spec
      const startResult = handleStart(
        fileManager,
        stateManager,
        { name: "test-feature", goal: "Add user authentication" },
        logger
      );

      // Verify spec created successfully
      expect(startResult.isError).toBeUndefined();
      expect(startResult.content[0].text).toContain("# Spec Created: test-feature");

      // Verify files exist
      const specDir = join(tempDir, "specs", "test-feature");
      expect(await fileExists(specDir)).toBe(true);
      expect(await fileExists(join(specDir, ".progress.md"))).toBe(true);
      expect(await fileExists(join(specDir, ".ralph-state.json"))).toBe(true);

      // Verify state is research phase
      const state = stateManager.read(specDir);
      expect(state).not.toBeNull();
      expect(state?.phase).toBe("research");
      expect(state?.name).toBe("test-feature");

      // Verify current spec is set
      expect(fileManager.getCurrentSpec()).toBe("test-feature");

      // Verify research tool returns instructions
      const researchResult = handleResearch(fileManager, stateManager, {}, logger);
      expect(researchResult.isError).toBeUndefined();
      expect(researchResult.content[0].text).toContain("research-analyst");
      expect(researchResult.content[0].text).toContain("Add user authentication");
    });
  });

  describe("complete phase transitions", () => {
    test("transitions through all phases: research -> requirements -> design -> tasks -> execution", async () => {
      const specName = "workflow-test";
      const specDir = join(tempDir, "specs", specName);

      // Step 1: Start spec
      handleStart(
        fileManager,
        stateManager,
        { name: specName, goal: "Test the full workflow" },
        logger
      );

      // Verify research phase
      let state = stateManager.read(specDir);
      expect(state?.phase).toBe("research");

      // Step 2: Complete research phase
      const researchComplete = handleCompletePhase(
        fileManager,
        stateManager,
        { phase: "research", summary: "Researched existing patterns" },
        logger
      );
      expect(researchComplete.isError).toBeUndefined();
      expect(researchComplete.content[0].text).toContain("**Next Phase**: requirements");

      state = stateManager.read(specDir);
      expect(state?.phase).toBe("requirements");

      // Step 3: Complete requirements phase
      const requirementsComplete = handleCompletePhase(
        fileManager,
        stateManager,
        { phase: "requirements", summary: "Defined user stories" },
        logger
      );
      expect(requirementsComplete.isError).toBeUndefined();
      expect(requirementsComplete.content[0].text).toContain("**Next Phase**: design");

      state = stateManager.read(specDir);
      expect(state?.phase).toBe("design");

      // Step 4: Complete design phase
      const designComplete = handleCompletePhase(
        fileManager,
        stateManager,
        { phase: "design", summary: "Created architecture" },
        logger
      );
      expect(designComplete.isError).toBeUndefined();
      expect(designComplete.content[0].text).toContain("**Next Phase**: tasks");

      state = stateManager.read(specDir);
      expect(state?.phase).toBe("tasks");

      // Step 5: Complete tasks phase
      const tasksComplete = handleCompletePhase(
        fileManager,
        stateManager,
        { phase: "tasks", summary: "Generated task list" },
        logger
      );
      expect(tasksComplete.isError).toBeUndefined();
      expect(tasksComplete.content[0].text).toContain("**Next Phase**: execution");

      state = stateManager.read(specDir);
      expect(state?.phase).toBe("execution");

      // Step 6: Complete execution phase
      const executionComplete = handleCompletePhase(
        fileManager,
        stateManager,
        { phase: "execution", summary: "All tasks completed" },
        logger
      );
      expect(executionComplete.isError).toBeUndefined();
      expect(executionComplete.content[0].text).toContain("**Status**: All phases complete");
    });
  });

  describe("instruction tools require correct phase", () => {
    test("research tool only works in research phase", async () => {
      const specName = "phase-test";
      const specDir = join(tempDir, "specs", specName);

      // Start in research phase
      handleStart(fileManager, stateManager, { name: specName, goal: "Test" }, logger);

      // Research should work
      let result = handleResearch(fileManager, stateManager, {}, logger);
      expect(result.isError).toBeUndefined();

      // Move to requirements phase
      handleCompletePhase(
        fileManager,
        stateManager,
        { phase: "research", summary: "Done" },
        logger
      );

      // Research should fail now
      result = handleResearch(fileManager, stateManager, {}, logger);
      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("Phase mismatch");
    });

    test("requirements tool only works in requirements phase", async () => {
      const specName = "req-phase-test";

      // Start in research phase
      handleStart(fileManager, stateManager, { name: specName, goal: "Test" }, logger);

      // Requirements should fail in research phase
      let result = handleRequirements(fileManager, stateManager, {}, logger);
      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("Phase mismatch");

      // Move to requirements phase
      handleCompletePhase(
        fileManager,
        stateManager,
        { phase: "research", summary: "Done" },
        logger
      );

      // Requirements should work now
      result = handleRequirements(fileManager, stateManager, {}, logger);
      expect(result.isError).toBeUndefined();
      expect(result.content[0].text).toContain("product-manager");
    });

    test("design tool only works in design phase", async () => {
      const specName = "design-phase-test";

      // Start and move to design phase
      handleStart(fileManager, stateManager, { name: specName, goal: "Test" }, logger);
      handleCompletePhase(fileManager, stateManager, { phase: "research", summary: "Done" }, logger);
      handleCompletePhase(fileManager, stateManager, { phase: "requirements", summary: "Done" }, logger);

      // Design should work
      const result = handleDesign(fileManager, stateManager, {}, logger);
      expect(result.isError).toBeUndefined();
      expect(result.content[0].text).toContain("architect-reviewer");
    });

    test("tasks tool only works in tasks phase", async () => {
      const specName = "tasks-phase-test";

      // Start and move to tasks phase
      handleStart(fileManager, stateManager, { name: specName, goal: "Test" }, logger);
      handleCompletePhase(fileManager, stateManager, { phase: "research", summary: "Done" }, logger);
      handleCompletePhase(fileManager, stateManager, { phase: "requirements", summary: "Done" }, logger);
      handleCompletePhase(fileManager, stateManager, { phase: "design", summary: "Done" }, logger);

      // Tasks should work
      const result = handleTasks(fileManager, stateManager, {}, logger);
      expect(result.isError).toBeUndefined();
      expect(result.content[0].text).toContain("task-planner");
    });
  });

  describe("file creation verification", () => {
    test("progress file is updated with phase completion summaries", async () => {
      const specName = "progress-test";
      const specDir = join(tempDir, "specs", specName);

      // Start spec
      handleStart(fileManager, stateManager, { name: specName, goal: "Test progress" }, logger);

      // Complete research with summary
      handleCompletePhase(
        fileManager,
        stateManager,
        { phase: "research", summary: "Found existing auth patterns in codebase" },
        logger
      );

      // Read progress file
      const progressContent = await readTestFile(join(specDir, ".progress.md"));

      // Verify summary was appended
      expect(progressContent).toContain("Research Phase Complete");
      expect(progressContent).toContain("Found existing auth patterns in codebase");
    });

    test("state file maintains correct structure throughout workflow", async () => {
      const specName = "state-test";
      const specDir = join(tempDir, "specs", specName);

      // Start spec
      handleStart(fileManager, stateManager, { name: specName, goal: "Test state" }, logger);

      // Verify initial state structure
      let state = stateManager.read(specDir);
      expect(state?.source).toBe("spec");
      expect(state?.name).toBe(specName);
      expect(state?.basePath).toBe(`./specs/${specName}`);
      expect(state?.phase).toBe("research");

      // Complete phases and verify structure maintained
      handleCompletePhase(fileManager, stateManager, { phase: "research", summary: "Done" }, logger);
      state = stateManager.read(specDir);
      expect(state?.source).toBe("spec");
      expect(state?.name).toBe(specName);
      expect(state?.phase).toBe("requirements");

      handleCompletePhase(fileManager, stateManager, { phase: "requirements", summary: "Done" }, logger);
      state = stateManager.read(specDir);
      expect(state?.phase).toBe("design");
    });
  });

  describe("status tool integration", () => {
    test("shows spec with correct phase after transitions", async () => {
      const specName = "status-test";

      // Start spec
      handleStart(fileManager, stateManager, { name: specName, goal: "Test status" }, logger);

      // Check status in research phase
      let statusResult = handleStatus(fileManager, stateManager, {}, logger);
      expect(statusResult.content[0].text).toContain("status-test");
      expect(statusResult.content[0].text).toContain("research");

      // Move to requirements
      handleCompletePhase(fileManager, stateManager, { phase: "research", summary: "Done" }, logger);

      // Check status shows requirements phase
      statusResult = handleStatus(fileManager, stateManager, {}, logger);
      expect(statusResult.content[0].text).toContain("requirements");
    });

    test("shows multiple specs with different phases", async () => {
      // Create first spec and advance to requirements
      handleStart(fileManager, stateManager, { name: "spec-one", goal: "First" }, logger);
      handleCompletePhase(fileManager, stateManager, { phase: "research", summary: "Done" }, logger);

      // Create second spec (stays in research)
      handleStart(fileManager, stateManager, { name: "spec-two", goal: "Second" }, logger);

      // Status should show both
      const statusResult = handleStatus(fileManager, stateManager, {}, logger);
      const text = statusResult.content[0].text;
      expect(text).toContain("spec-one");
      expect(text).toContain("spec-two");
    });
  });

  describe("implement tool integration", () => {
    test("implement returns executor instructions in execution phase", async () => {
      const specName = "implement-test";
      const specDir = join(tempDir, "specs", specName);

      // Start and move to execution phase
      handleStart(fileManager, stateManager, { name: specName, goal: "Test implement" }, logger);
      handleCompletePhase(fileManager, stateManager, { phase: "research", summary: "Done" }, logger);
      handleCompletePhase(fileManager, stateManager, { phase: "requirements", summary: "Done" }, logger);
      handleCompletePhase(fileManager, stateManager, { phase: "design", summary: "Done" }, logger);
      handleCompletePhase(fileManager, stateManager, { phase: "tasks", summary: "Done" }, logger);

      // Create a tasks.md file for implement to read
      const tasksContent = `---
spec: ${specName}
phase: tasks
total_tasks: 2
---

# Tasks

## Phase 1: POC

- [ ] 1.1 First task
  - **Do**: Do something
  - **Files**: /path/to/file.ts
  - **Done when**: Task is complete
  - **Verify**: echo "OK"
  - **Commit**: feat: add feature

- [ ] 1.2 Second task
  - **Do**: Do something else
  - **Files**: /path/to/other.ts
  - **Done when**: Other task complete
  - **Verify**: echo "OK"
  - **Commit**: feat: add other feature
`;
      fileManager.writeSpecFile(specName, "tasks.md", tasksContent);

      // Implement should work in execution phase
      const result = handleImplement(fileManager, stateManager, {}, logger);
      expect(result.isError).toBeUndefined();
      expect(result.content[0].text).toContain("spec-executor");
      expect(result.content[0].text).toContain("1.1");
    });

    test("implement fails before execution phase", async () => {
      const specName = "implement-fail-test";

      // Start but stay in research
      handleStart(fileManager, stateManager, { name: specName, goal: "Test" }, logger);

      // Implement should fail
      const result = handleImplement(fileManager, stateManager, {}, logger);
      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("Phase mismatch");
    });
  });

  describe("error handling in workflow", () => {
    test("completing wrong phase returns error", async () => {
      const specName = "error-test";

      // Start in research phase
      handleStart(fileManager, stateManager, { name: specName, goal: "Test errors" }, logger);

      // Try to complete requirements (wrong phase)
      const result = handleCompletePhase(
        fileManager,
        stateManager,
        { phase: "requirements", summary: "Should fail" },
        logger
      );

      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("Phase mismatch");
      expect(result.content[0].text).toContain('Current phase is "research"');
    });

    test("instruction tool on non-existent spec returns error", async () => {
      const result = handleResearch(
        fileManager,
        stateManager,
        { spec_name: "does-not-exist" },
        logger
      );

      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("Spec not found");
    });
  });

  describe("quick mode workflow", () => {
    test("quick mode flag is preserved in start response", async () => {
      const result = handleStart(
        fileManager,
        stateManager,
        { name: "quick-test", goal: "Test quick mode", quick: true },
        logger
      );

      expect(result.isError).toBeUndefined();
      expect(result.content[0].text).toContain("**Quick mode**: Yes");
    });

    test("quick mode requires goal", async () => {
      const result = handleStart(
        fileManager,
        stateManager,
        { name: "quick-test", quick: true },
        logger
      );

      expect(result.isError).toBe(true);
      expect(result.content[0].text).toContain("Quick mode requires a goal");
    });
  });

  describe("multiple specs workflow", () => {
    test("can work with multiple specs using spec_name parameter", async () => {
      // Create two specs
      handleStart(fileManager, stateManager, { name: "spec-a", goal: "First spec" }, logger);
      handleStart(fileManager, stateManager, { name: "spec-b", goal: "Second spec" }, logger);

      // Current spec is now spec-b
      expect(fileManager.getCurrentSpec()).toBe("spec-b");

      // Complete research on spec-a (not current)
      const result = handleCompletePhase(
        fileManager,
        stateManager,
        { spec_name: "spec-a", phase: "research", summary: "Done on A" },
        logger
      );

      expect(result.isError).toBeUndefined();
      expect(result.content[0].text).toContain("**Spec**: spec-a");

      // Verify spec-a is in requirements, spec-b still in research
      const stateA = stateManager.read(join(tempDir, "specs", "spec-a"));
      const stateB = stateManager.read(join(tempDir, "specs", "spec-b"));
      expect(stateA?.phase).toBe("requirements");
      expect(stateB?.phase).toBe("research");
    });
  });
});
