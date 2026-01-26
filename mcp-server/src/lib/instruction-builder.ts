/**
 * Instruction response builder for MCP instruction tools.
 * Shared helper for research, requirements, design, and tasks tools.
 */

/**
 * MCP TextContent response format.
 */
export interface TextContent {
  type: "text";
  text: string;
}

/**
 * MCP tool result format.
 */
export interface ToolResult {
  content: TextContent[];
}

/**
 * Parameters for building an instruction response.
 */
export interface InstructionParams {
  /** Spec name being operated on */
  specName: string;
  /** Current phase (research, requirements, design, tasks) */
  phase: string;
  /** Full agent prompt text */
  agentPrompt: string;
  /** Context from prior phases (progress, research, requirements, etc.) */
  context: string;
  /** List of expected actions for the LLM to take */
  expectedActions: string[];
  /** Instruction for what to do when phase is complete */
  completionInstruction: string;
}

/**
 * Build instruction response for LLM execution.
 * Returns structured text with task guidance, context, agent instructions,
 * expected actions, and completion steps.
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
