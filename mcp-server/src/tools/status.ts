/**
 * ralph_status tool handler.
 * Lists all specs with their phase and task progress.
 * @module tools/status
 */

import type { FileManager } from "../lib/files";
import type { StateManager, RalphState } from "../lib/state";
import type { MCPLogger } from "../lib/logger";
import type { ToolResult, SpecStatus } from "../lib/types";
import { handleUnexpectedError } from "../lib/errors";

/**
 * Format task progress string.
 */
function formatTaskProgress(state: RalphState | null): string {
  if (!state) {
    return "No state file";
  }

  if (state.phase !== "execution") {
    return "-";
  }

  const taskIndex = state.taskIndex ?? 0;
  const totalTasks = state.totalTasks ?? 0;

  if (totalTasks === 0) {
    return "0/0";
  }

  return `${taskIndex}/${totalTasks}`;
}

/**
 * Handle the ralph_status tool.
 *
 * Lists all specs with their current phase and task progress.
 * Shows which spec is currently active.
 *
 * @param fileManager - FileManager instance for spec file operations
 * @param stateManager - StateManager instance for state file operations
 * @param logger - Optional logger for error logging
 * @returns MCP-compliant tool result with formatted status table
 */
export function handleStatus(
  fileManager: FileManager,
  stateManager: StateManager,
  logger?: MCPLogger
): ToolResult {
  try {
    const specs = fileManager.listSpecs();
    const currentSpec = fileManager.getCurrentSpec();

    if (specs.length === 0) {
      return {
        content: [
          {
            type: "text",
            text: "No specs found. Run ralph_start to begin.",
          },
        ],
      };
    }

    // Gather status for each spec
    const statuses: SpecStatus[] = specs.map((specName) => {
      const specDir = fileManager.getSpecDir(specName);
      const state = stateManager.read(specDir);

      return {
        name: specName,
        phase: state?.phase ?? "unknown",
        taskProgress: formatTaskProgress(state),
        isCurrent: specName === currentSpec,
      };
    });

    // Format output
    const lines: string[] = [];
    lines.push("# Ralph Specs Status");
    lines.push("");
    lines.push(`Current spec: ${currentSpec ?? "(none)"}`);
    lines.push("");
    lines.push("| Spec | Phase | Tasks |");
    lines.push("|------|-------|-------|");

    for (const status of statuses) {
      const marker = status.isCurrent ? " *" : "";
      lines.push(
        `| ${status.name}${marker} | ${status.phase} | ${status.taskProgress} |`
      );
    }

    lines.push("");
    lines.push("* = current spec");

    return {
      content: [
        {
          type: "text",
          text: lines.join("\n"),
        },
      ],
    };
  } catch (error) {
    return handleUnexpectedError(error, "ralph_status", logger);
  }
}
