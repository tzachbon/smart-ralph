/**
 * ralph_implement tool handler.
 * Returns spec-executor prompt + coordinator instructions + current task.
 * @module tools/implement
 */

import { z } from "zod";
import type { FileManager } from "../lib/files";
import type { StateManager } from "../lib/state";
import type { MCPLogger } from "../lib/logger";
import type { ToolResult } from "../lib/types";
import { AGENTS } from "../assets";
import { handleUnexpectedError, createErrorResponse } from "../lib/errors";

/**
 * Zod schema for implement tool input validation.
 */
export const ImplementInputSchema = z.object({
  /** Maximum task retries before blocking (defaults to 5) */
  max_iterations: z.number().int().min(1).max(100).optional().default(5),
});

/**
 * Input type for the implement tool.
 */
export type ImplementInput = z.infer<typeof ImplementInputSchema>;

/**
 * Parse tasks.md to extract task blocks.
 *
 * Identifies tasks by their numbered format (e.g., "- [ ] 1.1 Task name")
 * and extracts the full task block including Do, Files, Done when, etc.
 *
 * @param content - Raw content of tasks.md file
 * @returns Array of task strings, each containing the full task block
 */
function parseTasksFile(content: string): string[] {
  const tasks: string[] = [];
  const lines = content.split("\n");
  let currentTask = "";
  let inTask = false;

  for (const line of lines) {
    // Match task lines like "- [ ] 1.1 Task name" or "- [x] 1.2 Task name"
    const taskMatch = line.match(/^- \[[ x]\] \d+\.\d+/);

    if (taskMatch) {
      // Save previous task if exists
      if (currentTask) {
        tasks.push(currentTask.trim());
      }
      currentTask = line;
      inTask = true;
    } else if (inTask) {
      // Check if we've hit a new section (## or another task)
      if (line.startsWith("## ") || line.startsWith("# ")) {
        // Save task and exit
        if (currentTask) {
          tasks.push(currentTask.trim());
        }
        currentTask = "";
        inTask = false;
      } else if (line.startsWith("- [ ]") || line.startsWith("- [x]")) {
        // Hit a non-numbered task list item, stop this task
        if (currentTask) {
          tasks.push(currentTask.trim());
        }
        currentTask = "";
        inTask = false;
      } else {
        // Continue building task content
        currentTask += "\n" + line;
      }
    }
  }

  // Don't forget last task
  if (currentTask) {
    tasks.push(currentTask.trim());
  }

  return tasks;
}

/**
 * Find the first uncompleted task in the task list.
 *
 * @param tasks - Array of task strings from parseTasksFile
 * @returns 0-based index of the first task starting with "- [ ]", or -1 if all complete
 */
function getFirstUncompletedTaskIndex(tasks: string[]): number {
  for (let i = 0; i < tasks.length; i++) {
    if (tasks[i].startsWith("- [ ]")) {
      return i;
    }
  }
  return -1; // All tasks complete
}

/**
 * Parameters for building an execution response.
 */
interface ExecutionResponseParams {
  /** Name of the spec being executed */
  specName: string;
  /** Path to the spec directory */
  specPath: string;
  /** Current task index (0-based) */
  taskIndex: number;
  /** Total number of tasks */
  totalTasks: number;
  /** Maximum task retries before blocking */
  maxIterations: number;
  /** Full text of the current task block */
  currentTask: string;
  /** Content of .progress.md for context */
  progressContext: string;
  /** The spec-executor agent prompt */
  agentPrompt: string;
}

/**
 * Build the execution instruction response for the LLM.
 *
 * Creates a formatted response containing spec information, current task,
 * progress context, agent instructions, and task completion protocol.
 *
 * @param params - Parameters for building the response
 * @returns MCP-compliant tool result with execution instructions
 */
function buildExecutionResponse(params: ExecutionResponseParams): ToolResult {
  const text = `## Execute Task ${params.taskIndex + 1} of ${params.totalTasks} for "${params.specName}"

### Spec Information
- **Spec**: ${params.specName}
- **Path**: ${params.specPath}
- **Task Index**: ${params.taskIndex} (0-based)
- **Max Iterations**: ${params.maxIterations}

### Current Task
\`\`\`
${params.currentTask}
\`\`\`

### Progress Context
${params.progressContext}

### Agent Instructions
${params.agentPrompt}

### Task Completion Protocol

1. Read the **Do** section and execute exactly as specified
2. Modify ONLY the **Files** listed in the task
3. Check **Done when** criteria is met
4. Run the **Verify** command - must pass before proceeding
5. **Commit** using the exact message from the task's Commit line
6. Update .progress.md with completion and learnings
7. Mark the task as complete with [x] in tasks.md

### When Complete

After successfully completing this task:
1. Ensure verification passed
2. Ensure changes are committed
3. Output: \`TASK_COMPLETE\`

### On Failure

If the task cannot be completed:
1. Document error in .progress.md Learnings section
2. Attempt to fix if straightforward
3. Retry verification
4. If still blocked, describe the issue - DO NOT output TASK_COMPLETE`;

  return {
    content: [
      {
        type: "text",
        text,
      },
    ],
  };
}

/**
 * Handle the ralph_implement tool.
 *
 * Returns spec-executor instructions for the LLM to execute the current task.
 * Parses tasks.md to find the next uncompleted task and returns execution
 * instructions including the task details, progress context, and completion protocol.
 *
 * Requires spec to be in "tasks" or "execution" phase.
 *
 * @param fileManager - FileManager instance for spec file operations
 * @param stateManager - StateManager instance for state file operations
 * @param input - Validated input with optional max_iterations
 * @param logger - Optional logger for error logging
 * @returns MCP-compliant tool result with task execution instructions
 */
export function handleImplement(
  fileManager: FileManager,
  stateManager: StateManager,
  input: ImplementInput,
  logger?: MCPLogger
): ToolResult {
  try {
    // Validate input with Zod
    const parsed = ImplementInputSchema.safeParse(input);
    if (!parsed.success) {
      return createErrorResponse(
        "VALIDATION_ERROR",
        parsed.error.errors[0]?.message ?? "Invalid input",
        logger
      );
    }

    const { max_iterations } = parsed.data;

    // Get current spec
    const currentSpec = fileManager.getCurrentSpec();
    if (!currentSpec) {
      return createErrorResponse(
        "MISSING_PREREQUISITES",
        "No current spec set. Run ralph_start first.",
        logger
      );
    }

    // Verify spec exists
    if (!fileManager.specExists(currentSpec)) {
      return createErrorResponse(
        "SPEC_NOT_FOUND",
        `Spec "${currentSpec}" not found. Run ralph_status to see available specs.`,
        logger
      );
    }

    // Read current state
    const specDir = fileManager.getSpecDir(currentSpec);
    const state = stateManager.read(specDir);

    if (!state) {
      return createErrorResponse(
        "INVALID_STATE",
        `No state found for spec "${currentSpec}". Run ralph_start to initialize the spec.`,
        logger
      );
    }

    // Validate we're in execution phase (tasks phase can also implement)
    if (state.phase !== "execution" && state.phase !== "tasks") {
      return createErrorResponse(
        "PHASE_MISMATCH",
        `Spec "${currentSpec}" is in "${state.phase}" phase. Complete the tasks phase first (run ralph_tasks, then ralph_complete_phase).`,
        logger
      );
    }

    // Read tasks.md
    const tasksContent = fileManager.readSpecFile(currentSpec, "tasks.md");
    if (!tasksContent) {
      return createErrorResponse(
        "MISSING_PREREQUISITES",
        `tasks.md not found for spec "${currentSpec}". Run ralph_tasks to generate tasks.`,
        logger
      );
    }

    // Parse tasks
    const tasks = parseTasksFile(tasksContent);
    if (tasks.length === 0) {
      return createErrorResponse(
        "MISSING_PREREQUISITES",
        `No tasks found in tasks.md for spec "${currentSpec}". Run ralph_tasks to generate tasks.`,
        logger
      );
    }

    // Determine current task index
    // Use state.taskIndex if available, otherwise find first uncompleted task
    let taskIndex = state.taskIndex ?? 0;

    // If the task at taskIndex is already completed, find the next uncompleted one
    if (taskIndex < tasks.length && tasks[taskIndex].startsWith("- [x]")) {
      taskIndex = getFirstUncompletedTaskIndex(tasks);
    }

    // Check if all tasks are complete
    if (taskIndex === -1 || taskIndex >= tasks.length) {
      logger?.info(`All tasks complete for spec "${currentSpec}". Total: ${tasks.length} tasks.`);
      return {
        content: [
          {
            type: "text",
            text: `All tasks complete for spec "${currentSpec}". Total: ${tasks.length} tasks executed.

Spec execution finished successfully.`,
          },
        ],
      };
    }

    // Get current task
    const currentTask = tasks[taskIndex];

    // Read .progress.md for context
    const progressContent = fileManager.readSpecFile(currentSpec, ".progress.md");
    const progressContext = progressContent
      ? progressContent
      : "No progress file found.";

    // Build execution response
    return buildExecutionResponse({
      specName: currentSpec,
      specPath: specDir,
      taskIndex,
      totalTasks: tasks.length,
      maxIterations: max_iterations,
      currentTask,
      progressContext,
      agentPrompt: AGENTS.specExecutor,
    });
  } catch (error) {
    return handleUnexpectedError(error, "ralph_implement", logger);
  }
}
