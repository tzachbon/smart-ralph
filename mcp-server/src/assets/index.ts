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
 * Agent prompts for spec-driven development phases
 */
export const AGENTS = {
  researchAnalyst,
  productManager,
  architectReviewer,
  taskPlanner,
  specExecutor,
} as const;

/**
 * Templates for spec files
 */
export const TEMPLATES = {
  progress,
  research,
  requirements,
  design,
  tasks,
} as const;
