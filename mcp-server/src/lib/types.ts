/**
 * Shared type definitions for the Ralph Specum MCP Server.
 * These types are exported for external use by consumers of the package.
 * @module types
 */

/**
 * MCP TextContent response format.
 * Represents a text content block in an MCP tool response.
 */
export interface TextContent {
  /** Content type identifier */
  type: "text";
  /** The text content */
  text: string;
}

/**
 * MCP tool result format.
 * Standard response format for all Ralph MCP tools.
 */
export interface ToolResult {
  /** Array of content blocks in the response */
  content: TextContent[];
  /** Whether this result represents an error condition */
  isError?: boolean;
}

/**
 * Valid workflow phases in the Ralph spec-driven development process.
 * - research: Analyzing codebase and gathering context
 * - requirements: Defining user stories and acceptance criteria
 * - design: Creating technical architecture
 * - tasks: Breaking down work into executable tasks
 * - execution: Implementing tasks one by one
 */
export type Phase = "research" | "requirements" | "design" | "tasks" | "execution";

/**
 * Task source origin indicating how the spec was created.
 * - spec: Full workflow from research through execution
 * - plan: Skip directly to tasks phase
 * - direct: Manual tasks.md file provided
 */
export type Source = "spec" | "plan" | "direct";

/**
 * Relevance level for related specs.
 */
export type Relevance = "high" | "medium" | "low";

/**
 * Task execution status.
 */
export type TaskStatus = "pending" | "success" | "failed";

/**
 * Related spec information for cross-referencing.
 */
export interface RelatedSpec {
  /** Name of the related spec */
  name: string;
  /** How relevant this spec is to the current work */
  relevance: Relevance;
  /** Explanation of why this spec is related */
  reason: string;
  /** Whether this related spec may need updates as a result of current work */
  mayNeedUpdate?: boolean;
}

/**
 * Parallel task group information for batch execution.
 */
export interface ParallelGroup {
  /** Starting task index (inclusive) */
  startIndex: number;
  /** Ending task index (inclusive) */
  endIndex: number;
  /** Array of task indices in this group */
  taskIndices: number[];
}

/**
 * Task execution result for tracking parallel batch outcomes.
 */
export interface TaskResult {
  /** Current status of the task */
  status: TaskStatus;
  /** Error message if task failed */
  error?: string;
}

/**
 * RalphState interface representing the spec workflow state.
 * This is stored in .ralph-state.json within each spec directory.
 */
export interface RalphState {
  /** Origin of tasks: spec (full workflow), plan (skip to tasks), direct (manual tasks.md) */
  source: Source;
  /** Spec name in kebab-case */
  name: string;
  /** Path to spec directory (e.g., ./specs/my-feature) */
  basePath: string;
  /** Current workflow phase */
  phase: Phase;
  /** Current task index (0-based) */
  taskIndex?: number;
  /** Total number of tasks in tasks.md */
  totalTasks?: number;
  /** Current iteration for this task (resets per task) */
  taskIteration?: number;
  /** Max retries per task before failure */
  maxTaskIterations?: number;
  /** Total loop iterations across all tasks */
  globalIteration?: number;
  /** Safety cap on total iterations */
  maxGlobalIterations?: number;
  /** Existing specs related to this one */
  relatedSpecs?: RelatedSpec[];
  /** Current parallel task group being executed */
  parallelGroup?: ParallelGroup;
  /** Per-task execution results for parallel batch */
  taskResults?: Record<string, TaskResult>;
}

/**
 * Parameters for building an instruction response.
 * Used by instruction tools (research, requirements, design, tasks).
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
 * Standard error codes for Ralph MCP tools.
 * Used to categorize errors for consistent handling and messaging.
 */
export type RalphErrorCode =
  | "SPEC_NOT_FOUND"
  | "INVALID_STATE"
  | "MISSING_PREREQUISITES"
  | "PHASE_MISMATCH"
  | "VALIDATION_ERROR"
  | "FILE_OPERATION_ERROR"
  | "INTERNAL_ERROR";

/**
 * Log levels for MCP-compliant logging.
 */
export type LogLevel = "debug" | "info" | "warning" | "error";

/**
 * Structured log message format.
 * All logs are written as JSON to stderr.
 */
export interface LogMessage {
  /** Severity level of the log */
  level: LogLevel;
  /** Name of the logger (usually component name) */
  logger: string;
  /** Log payload data */
  data: unknown;
  /** ISO 8601 timestamp */
  timestamp: string;
}

/**
 * Tool information for help display.
 */
export interface ToolInfo {
  /** Tool name (e.g., ralph_start) */
  name: string;
  /** Brief description of what the tool does */
  description: string;
  /** Comma-separated list of arguments */
  args: string;
}

/**
 * Status information for a single spec.
 * Used by ralph_status tool.
 */
export interface SpecStatus {
  /** Spec name */
  name: string;
  /** Current workflow phase */
  phase: string;
  /** Task progress string (e.g., "5/10") */
  taskProgress: string;
  /** Whether this is the currently active spec */
  isCurrent: boolean;
}
