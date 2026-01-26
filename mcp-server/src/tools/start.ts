/**
 * ralph_start tool handler.
 * Creates a new spec with initial files and state.
 */

import { z } from "zod";
import { FileManager } from "../lib/files";
import { StateManager, type RalphState } from "../lib/state";
import { MCPLogger } from "../lib/logger";
import { TEMPLATES } from "../assets";
import {
  handleUnexpectedError,
  createErrorResponse,
  type ToolResult,
} from "../lib/errors";

/**
 * Zod schema for start tool input validation.
 */
export const StartInputSchema = z.object({
  /** Name of the spec (optional - generated from goal if not provided) */
  name: z.string().min(1).optional(),
  /** Goal/description for the spec */
  goal: z.string().min(1).optional(),
  /** Quick mode - skip interviews */
  quick: z.boolean().optional(),
});

/**
 * Input type for the start tool.
 */
export type StartInput = z.infer<typeof StartInputSchema>;

/**
 * Generate a spec name from a goal string.
 * Converts to kebab-case.
 */
function generateNameFromGoal(goal: string): string {
  // Take first 50 chars, convert to kebab-case
  const truncated = goal.slice(0, 50);
  return truncated
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, "") // Remove special chars
    .replace(/\s+/g, "-") // Spaces to hyphens
    .replace(/-+/g, "-") // Collapse multiple hyphens
    .replace(/^-|-$/g, ""); // Trim hyphens from ends
}

/**
 * Get a unique spec name by appending -2, -3, etc if needed.
 */
function getUniqueSpecName(fileManager: FileManager, baseName: string): string {
  if (!fileManager.specExists(baseName)) {
    return baseName;
  }

  let suffix = 2;
  let uniqueName = `${baseName}-${suffix}`;

  while (fileManager.specExists(uniqueName)) {
    suffix++;
    uniqueName = `${baseName}-${suffix}`;
  }

  return uniqueName;
}

/**
 * Create initial .progress.md from template.
 */
function createProgressContent(goal: string): string {
  return TEMPLATES.progress.replace("{{USER_GOAL_DESCRIPTION}}", goal);
}

/**
 * Handle the ralph_start tool.
 * Creates spec directory with initial files.
 */
export function handleStart(
  fileManager: FileManager,
  stateManager: StateManager,
  input: StartInput,
  logger?: MCPLogger
): ToolResult {
  try {
    // Validate input with Zod
    const parsed = StartInputSchema.safeParse(input);
    if (!parsed.success) {
      return createErrorResponse(
        "VALIDATION_ERROR",
        parsed.error.errors[0]?.message ?? "Invalid input",
        logger
      );
    }

    const { name, goal, quick } = parsed.data;

    // Validate quick mode requires a goal
    if (quick && !goal) {
      return createErrorResponse(
        "VALIDATION_ERROR",
        "Quick mode requires a goal. Provide a goal to use quick mode.",
        logger
      );
    }

    // Determine spec name
    let specName: string;

    if (name) {
      // Use provided name
      specName = name;
    } else if (goal) {
      // Generate from goal
      specName = generateNameFromGoal(goal);
      if (!specName) {
        return createErrorResponse(
          "VALIDATION_ERROR",
          "Could not generate spec name from goal. Please provide a name.",
          logger
        );
      }
    } else {
      // Neither provided
      return createErrorResponse(
        "VALIDATION_ERROR",
        "Either 'name' or 'goal' must be provided to create a spec.",
        logger
      );
    }

    // Ensure unique name
    specName = getUniqueSpecName(fileManager, specName);

    // Determine goal text
    const goalText = goal ?? `Implement ${specName}`;

    // Create spec directory
    if (!fileManager.createSpecDir(specName)) {
      return createErrorResponse(
        "FILE_OPERATION_ERROR",
        `Failed to create spec directory for "${specName}".`,
        logger
      );
    }

    // Initialize .progress.md from template
    const progressContent = createProgressContent(goalText);
    if (!fileManager.writeSpecFile(specName, ".progress.md", progressContent)) {
      return createErrorResponse(
        "FILE_OPERATION_ERROR",
        `Failed to create .progress.md for "${specName}".`,
        logger
      );
    }

    // Initialize .ralph-state.json with phase: "research"
    const specDir = fileManager.getSpecDir(specName);
    const initialState: RalphState = {
      source: "spec",
      name: specName,
      basePath: `./specs/${specName}`,
      phase: "research",
    };

    if (!stateManager.write(specDir, initialState)) {
      return createErrorResponse(
        "FILE_OPERATION_ERROR",
        `Failed to create .ralph-state.json for "${specName}".`,
        logger
      );
    }

    // Update ./specs/.current-spec
    if (!fileManager.setCurrentSpec(specName)) {
      // Non-fatal warning - spec was created successfully
      logger?.warning(`Spec created but failed to set as current: ${specName}`);
      return {
        content: [
          {
            type: "text",
            text: `Warning: Spec created but failed to set as current. Run ralph_switch to activate.`,
          },
        ],
      };
    }

    // Build success response
    const lines: string[] = [];
    lines.push(`# Spec Created: ${specName}`);
    lines.push("");
    lines.push(`**Goal**: ${goalText}`);
    lines.push(`**Phase**: research`);
    lines.push(`**Quick mode**: ${quick ? "Yes" : "No"}`);
    lines.push("");
    lines.push("## Files Created");
    lines.push(`- \`./specs/${specName}/.progress.md\``);
    lines.push(`- \`./specs/${specName}/.ralph-state.json\``);
    lines.push("");
    lines.push("## Next Step");
    lines.push("");
    lines.push("Run **ralph_research** to begin the research phase.");
    lines.push("");
    lines.push("This will analyze the codebase and gather context for your goal.");

    return {
      content: [
        {
          type: "text",
          text: lines.join("\n"),
        },
      ],
    };
  } catch (error) {
    return handleUnexpectedError(error, "ralph_start", logger);
  }
}
