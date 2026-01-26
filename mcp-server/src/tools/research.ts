/**
 * ralph_research tool handler.
 * Returns research-analyst prompt + goal context for LLM to execute.
 */

import { z } from "zod";
import { FileManager } from "../lib/files";
import { StateManager } from "../lib/state";
import { AGENTS } from "../assets";
import { buildInstructionResponse, ToolResult } from "../lib/instruction-builder";

/**
 * Zod schema for research tool input validation.
 */
export const ResearchInputSchema = z.object({
  /** Name of the spec (optional - defaults to current spec) */
  spec_name: z.string().min(1).optional(),
});

/**
 * Input type for the research tool.
 */
export type ResearchInput = z.infer<typeof ResearchInputSchema>;

/**
 * Handle the ralph_research tool.
 * Returns research-analyst prompt + goal context.
 */
export function handleResearch(
  fileManager: FileManager,
  stateManager: StateManager,
  input: ResearchInput
): ToolResult {
  // Validate input with Zod
  const parsed = ResearchInputSchema.safeParse(input);
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

  // Validate we're in research phase
  if (state.phase !== "research") {
    return {
      content: [
        {
          type: "text",
          text: `Error: Spec "${specName}" is in "${state.phase}" phase, not research. Run the appropriate tool for the current phase.`,
        },
      ],
    };
  }

  // Read .progress.md for goal context
  const progressContent = fileManager.readSpecFile(specName, ".progress.md");
  const context = progressContent
    ? `## Current Progress\n\n${progressContent}`
    : "No progress file found. Goal should have been set during ralph_start.";

  // Build instruction response
  return buildInstructionResponse({
    specName,
    phase: "research",
    agentPrompt: AGENTS.researchAnalyst,
    context,
    expectedActions: [
      "Analyze the goal and understand what needs to be researched",
      "Search the codebase for relevant existing patterns and code",
      "Use web search to find best practices and external knowledge",
      "Document findings in ./specs/" + specName + "/research.md",
      "Update .progress.md with key learnings",
    ],
    completionInstruction:
      "Once research.md is written with comprehensive findings, call ralph_complete_phase to move to requirements.",
  });
}
