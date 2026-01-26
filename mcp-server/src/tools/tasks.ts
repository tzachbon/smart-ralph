/**
 * ralph_tasks tool handler.
 * Returns task-planner prompt + design context for LLM to execute.
 */

import { z } from "zod";
import { FileManager } from "../lib/files";
import { StateManager } from "../lib/state";
import { AGENTS } from "../assets";
import { buildInstructionResponse, ToolResult } from "../lib/instruction-builder";

/**
 * Zod schema for tasks tool input validation.
 */
export const TasksInputSchema = z.object({
  /** Name of the spec (optional - defaults to current spec) */
  spec_name: z.string().min(1).optional(),
});

/**
 * Input type for the tasks tool.
 */
export type TasksInput = z.infer<typeof TasksInputSchema>;

/**
 * Handle the ralph_tasks tool.
 * Returns task-planner prompt + design context.
 */
export function handleTasks(
  fileManager: FileManager,
  stateManager: StateManager,
  input: TasksInput
): ToolResult {
  // Validate input with Zod
  const parsed = TasksInputSchema.safeParse(input);
  if (!parsed.success) {
    return {
      content: [
        {
          type: "text",
          text: `Error: ${parsed.error.errors[0]?.message ?? "Invalid input"}`,
        },
      ],
    };
  }

  const { spec_name } = parsed.data;

  // Determine spec name (use provided or current)
  let specName: string;
  if (spec_name) {
    specName = spec_name;
  } else {
    const currentSpec = fileManager.getCurrentSpec();
    if (!currentSpec) {
      return {
        content: [
          {
            type: "text",
            text: "Error: No spec specified and no current spec set. Run ralph_start first or specify spec_name.",
          },
        ],
      };
    }
    specName = currentSpec;
  }

  // Verify spec exists
  if (!fileManager.specExists(specName)) {
    return {
      content: [
        {
          type: "text",
          text: `Error: Spec "${specName}" not found. Run ralph_status to see available specs.`,
        },
      ],
    };
  }

  // Read current state
  const specDir = fileManager.getSpecDir(specName);
  const state = stateManager.read(specDir);

  if (!state) {
    return {
      content: [
        {
          type: "text",
          text: `Error: No state found for spec "${specName}". Run ralph_start to initialize the spec.`,
        },
      ],
    };
  }

  // Validate we're in tasks phase
  if (state.phase !== "tasks") {
    return {
      content: [
        {
          type: "text",
          text: `Error: Spec "${specName}" is in "${state.phase}" phase, not tasks. Run the appropriate tool for the current phase.`,
        },
      ],
    };
  }

  // Read .progress.md for goal context
  const progressContent = fileManager.readSpecFile(specName, ".progress.md");

  // Read research.md for research context
  const researchContent = fileManager.readSpecFile(specName, "research.md");

  // Read requirements.md for requirements context
  const requirementsContent = fileManager.readSpecFile(specName, "requirements.md");

  // Read design.md for design context
  const designContent = fileManager.readSpecFile(specName, "design.md");

  // Build combined context
  const contextParts: string[] = [];

  if (progressContent) {
    contextParts.push("## Progress Summary\n\n" + progressContent);
  }

  if (researchContent) {
    contextParts.push("## Research Findings\n\n" + researchContent);
  }

  if (requirementsContent) {
    contextParts.push("## Requirements\n\n" + requirementsContent);
  }

  if (designContent) {
    contextParts.push("## Design\n\n" + designContent);
  } else {
    contextParts.push(
      "## Design\n\nNo design.md found. Design phase may have been skipped or file is missing."
    );
  }

  const context = contextParts.join("\n\n---\n\n");

  // Build instruction response
  return buildInstructionResponse({
    specName,
    phase: "tasks",
    agentPrompt: AGENTS.taskPlanner,
    context,
    expectedActions: [
      "Review the design, requirements, and research",
      "Break down work into executable tasks with POC-first approach",
      "Define clear Do, Files, Done when, Verify, and Commit for each task",
      "Insert quality checkpoints every 2-3 tasks",
      "Organize into phases: POC, Refactoring, Testing, Quality Gates, PR Lifecycle",
      "Write tasks to ./specs/" + specName + "/tasks.md",
      "Update .progress.md with task planning summary",
    ],
    completionInstruction:
      "Once tasks.md is written with phased task breakdown, call ralph_complete_phase to move to execution.",
  });
}
