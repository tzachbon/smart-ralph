/**
 * Asset barrel for embedded agent prompts and templates.
 *
 * All markdown files are imported using Bun's `import with { type: "text" }`
 * syntax, which embeds the file contents as strings at compile time. This
 * means the compiled binary is self-contained and doesn't need runtime
 * file access for these assets.
 *
 * @module assets
 */

// Agent prompts - embedded at compile time
import researchAnalyst from "./agents/research-analyst.md" with { type: "text" };
import productManager from "./agents/product-manager.md" with { type: "text" };
import architectReviewer from "./agents/architect-reviewer.md" with { type: "text" };
import taskPlanner from "./agents/task-planner.md" with { type: "text" };
import specExecutor from "./agents/spec-executor.md" with { type: "text" };

// Templates - embedded at compile time
import progress from "./templates/progress.md" with { type: "text" };
import research from "./templates/research.md" with { type: "text" };
import requirements from "./templates/requirements.md" with { type: "text" };
import design from "./templates/design.md" with { type: "text" };
import tasks from "./templates/tasks.md" with { type: "text" };

/**
 * Agent prompts for spec-driven development phases.
 *
 * Each agent prompt provides specialized instructions for a particular
 * phase of the Ralph workflow:
 * - researchAnalyst: Analyzes codebase and gathers context
 * - productManager: Defines user stories and acceptance criteria
 * - architectReviewer: Creates technical architecture and design
 * - taskPlanner: Breaks down work into executable tasks
 * - specExecutor: Implements tasks one by one
 */
export const AGENTS = {
  /** Research phase agent prompt */
  researchAnalyst,
  /** Requirements phase agent prompt */
  productManager,
  /** Design phase agent prompt */
  architectReviewer,
  /** Tasks phase agent prompt */
  taskPlanner,
  /** Execution phase agent prompt */
  specExecutor,
} as const;

/**
 * Type representing available agent prompt names.
 */
export type AgentName = keyof typeof AGENTS;

/**
 * Templates for spec files.
 *
 * These templates provide the initial structure for spec files created
 * during the workflow:
 * - progress: Initial .progress.md with goal tracking
 * - research: Structure for research.md findings
 * - requirements: Structure for requirements.md
 * - design: Structure for design.md
 * - tasks: Structure for tasks.md
 */
export const TEMPLATES = {
  /** Progress file template */
  progress,
  /** Research file template */
  research,
  /** Requirements file template */
  requirements,
  /** Design file template */
  design,
  /** Tasks file template */
  tasks,
} as const;

/**
 * Type representing available template names.
 */
export type TemplateName = keyof typeof TEMPLATES;
