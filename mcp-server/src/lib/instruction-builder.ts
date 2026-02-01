/**
 * Instruction response builder for MCP instruction tools.
 * Shared helper for research, requirements, design, and tasks tools.
 * @module instruction-builder
 */

import type { InstructionParams, ToolResult } from "./types";

// Re-export types for convenience
export type { InstructionParams, ToolResult };

/**
 * Build instruction response for LLM execution.
 *
 * Creates a structured text response with task guidance, context, agent instructions,
 * expected actions, and completion steps. This format is designed to be consumed
 * by LLM clients that will execute the specified workflow.
 *
 * @param params - The instruction parameters containing all context for the phase
 * @param params.specName - Name of the spec being operated on
 * @param params.phase - Current workflow phase (research, requirements, design, tasks)
 * @param params.agentPrompt - Full agent prompt text for this phase
 * @param params.context - Context from prior phases
 * @param params.expectedActions - List of actions the LLM should take
 * @param params.completionInstruction - What to do when phase is complete
 * @returns MCP-compliant tool result with structured instructions
 *
 * @example
 * ```typescript
 * const result = buildInstructionResponse({
 *   specName: "my-feature",
 *   phase: "research",
 *   agentPrompt: AGENTS.researchAnalyst,
 *   context: "## Goal\nImplement user authentication",
 *   expectedActions: ["Analyze codebase", "Search for patterns"],
 *   completionInstruction: "Call ralph_complete_phase when done"
 * });
 * ```
 */
export function buildInstructionResponse(params: InstructionParams): ToolResult {
  const text = `## ${params.phase} Phase for "${params.specName}"

### Your Task
Execute the ${params.phase} phase for this spec using the guidance below.

### Context
${params.context}

### Agent Instructions
${params.agentPrompt}

### Expected Actions
${params.expectedActions.map((a, i) => `${i + 1}. ${a}`).join("\n")}

### When Complete
${params.completionInstruction}

Call \`ralph_complete_phase\` with:
- spec_name: "${params.specName}"
- phase: "${params.phase}"
- summary: <brief summary of what was done>`;

  return {
    content: [
      {
        type: "text",
        text,
      },
    ],
  };
}
