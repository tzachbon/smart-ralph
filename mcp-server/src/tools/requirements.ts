/**
 * ralph_requirements tool handler.
 * Returns product-manager prompt + research context for LLM to execute.
 */

import { z } from "zod";
import { FileManager } from "../lib/files";
import { StateManager } from "../lib/state";
import { AGENTS } from "../assets";
import { buildInstructionResponse, ToolResult } from "../lib/instruction-builder";

/**
 * Zod schema for requirements tool input validation.
 */
export const RequirementsInputSchema = z.object({
  /** Name of the spec (optional - defaults to current spec) */
  spec_name: z.string().min(1).optional(),
});

/**
 * Input type for the requirements tool.
 */
export type RequirementsInput = z.infer<typeof RequirementsInputSchema>;

/**
 * Handle the ralph_requirements tool.
 * Returns product-manager prompt + research context.
 */
export function handleRequirements(
  fileManager: FileManager,
  stateManager: StateManager,
  input: RequirementsInput
): ToolResult {
  // Validate input with Zod
  const parsed = RequirementsInputSchema.safeParse(input);
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

  // Validate we're in requirements phase
  if (state.phase !== "requirements") {
    return {
      content: [
        {
          type: "text",
          text: `Error: Spec "${specName}" is in "${state.phase}" phase, not requirements. Run the appropriate tool for the current phase.`,
        },
      ],
    };
  }

  // Read .progress.md for goal context
  const progressContent = fileManager.readSpecFile(specName, ".progress.md");

  // Read research.md for research context
  const researchContent = fileManager.readSpecFile(specName, "research.md");

  // Build combined context
  const contextParts: string[] = [];

  if (progressContent) {
    contextParts.push("## Progress Summary\n\n" + progressContent);
  }

  if (researchContent) {
    contextParts.push("## Research Findings\n\n" + researchContent);
  } else {
    contextParts.push(
      "## Research Findings\n\nNo research.md found. Research phase may have been skipped or file is missing."
    );
  }

  const context = contextParts.join("\n\n---\n\n");

  // Build instruction response
  return buildInstructionResponse({
    specName,
    phase: "requirements",
    agentPrompt: AGENTS.productManager,
    context,
    expectedActions: [
      "Review the research findings and goal",
      "Define user stories with clear acceptance criteria",
      "Prioritize requirements (P0, P1, P2)",
      "Document functional and non-functional requirements",
      "Write requirements to ./specs/" + specName + "/requirements.md",
      "Update .progress.md with decisions made",
    ],
    completionInstruction:
      "Once requirements.md is written with user stories and acceptance criteria, call ralph_complete_phase to move to design.",
  });
}
