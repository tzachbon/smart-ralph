/**
 * Ralph Execution Loop Adapter for OpenCode
 *
 * Mirrors the logic of plugins/ralph-specum/hooks/scripts/stop-watcher.sh
 * in TypeScript for OpenCode's JS/TS plugin system.
 *
 * Fires on `session.idle` and `tool.execute.after` events. When a Ralph spec
 * is in the execution phase with remaining tasks, outputs a continuation prompt
 * so the session keeps processing tasks until all are complete.
 */

import * as fs from "node:fs";
import * as path from "node:path";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface RalphState {
  phase: string;
  taskIndex: number;
  totalTasks: number;
  taskIteration: number;
  globalIteration: number;
  maxGlobalIterations: number;
  maxTaskIterations: number;
  recoveryMode: boolean;
}

interface HookContext {
  /** Current working directory of the OpenCode session */
  cwd: string;
  /** Optional transcript path for completion detection */
  transcriptPath?: string;
}

interface HookResult {
  /** "continue" to allow normal flow, "block" to inject a continuation prompt */
  decision: "continue" | "block";
  /** Message displayed to the user / injected into the session */
  reason?: string;
  /** Short status line shown in the UI */
  systemMessage?: string;
}

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

/** Default directory where specs live (relative to cwd) */
const DEFAULT_SPECS_DIR = "./specs";

/** Name of the file that tracks the active spec */
const CURRENT_SPEC_FILE = ".current-spec";

/** State file name inside a spec directory */
const STATE_FILE_NAME = ".ralph-state.json";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Read the configured specs directories from the settings file.
 * Falls back to DEFAULT_SPECS_DIR when no settings exist.
 */
function getSpecsDirs(cwd: string): string[] {
  const settingsPath = path.join(cwd, ".claude", "ralph-specum.local.md");

  if (!fs.existsSync(settingsPath)) {
    return [DEFAULT_SPECS_DIR];
  }

  try {
    const content = fs.readFileSync(settingsPath, "utf-8");
    // Extract specs_dirs from YAML frontmatter
    const frontmatter = content.match(/^---\n([\s\S]*?)\n---/);
    if (!frontmatter) return [DEFAULT_SPECS_DIR];

    const match = frontmatter[1].match(/^specs_dirs:\s*\[([^\]]*)\]/m);
    if (!match) return [DEFAULT_SPECS_DIR];

    const dirs = match[1]
      .split(",")
      .map((d) => d.trim().replace(/^["']|["']$/g, ""))
      .filter(Boolean);

    return dirs.length > 0 ? dirs : [DEFAULT_SPECS_DIR];
  } catch {
    return [DEFAULT_SPECS_DIR];
  }
}

/**
 * Resolve the current active spec path from .current-spec.
 * Returns the relative spec path (e.g. "./specs/my-feature") or null.
 */
function resolveCurrentSpec(cwd: string): string | null {
  const specsDirs = getSpecsDirs(cwd);
  const defaultDir = specsDirs[0] ?? DEFAULT_SPECS_DIR;
  const currentSpecFile = path.join(cwd, defaultDir, CURRENT_SPEC_FILE);

  if (!fs.existsSync(currentSpecFile)) {
    return null;
  }

  try {
    const raw = fs.readFileSync(currentSpecFile, "utf-8").trim();
    if (!raw) return null;

    // If already a path (starts with ./ or /), use as-is
    if (raw.startsWith("./") || raw.startsWith("/")) {
      return raw;
    }

    // Bare name -> prepend default specs dir
    return `${defaultDir}/${raw}`;
  } catch {
    return null;
  }
}

/**
 * Read and parse .ralph-state.json from the spec directory.
 * Returns null if the file is missing or invalid.
 */
function readState(cwd: string, specPath: string): RalphState | null {
  const stateFilePath = path.join(cwd, specPath, STATE_FILE_NAME);

  if (!fs.existsSync(stateFilePath)) {
    return null;
  }

  try {
    const raw = fs.readFileSync(stateFilePath, "utf-8");
    const data = JSON.parse(raw);

    return {
      phase: data.phase ?? "unknown",
      taskIndex: data.taskIndex ?? 0,
      totalTasks: data.totalTasks ?? 0,
      taskIteration: data.taskIteration ?? 1,
      globalIteration: data.globalIteration ?? 1,
      maxGlobalIterations: data.maxGlobalIterations ?? 100,
      maxTaskIterations: data.maxTaskIterations ?? 5,
      recoveryMode: data.recoveryMode ?? false,
    };
  } catch {
    return null;
  }
}

/**
 * Check whether the plugin is explicitly disabled via settings.
 */
function isPluginDisabled(cwd: string): boolean {
  const settingsPath = path.join(cwd, ".claude", "ralph-specum.local.md");

  if (!fs.existsSync(settingsPath)) {
    return false;
  }

  try {
    const content = fs.readFileSync(settingsPath, "utf-8");
    const frontmatter = content.match(/^---\n([\s\S]*?)\n---/);
    if (!frontmatter) return false;

    const match = frontmatter[1].match(/^enabled:\s*(.+)$/m);
    if (!match) return false;

    const value = match[1].trim().replace(/["']/g, "").toLowerCase();
    return value === "false";
  } catch {
    return false;
  }
}

/**
 * Check transcript for ALL_TASKS_COMPLETE signal (backup termination detection).
 */
function isCompletionSignalInTranscript(transcriptPath?: string): boolean {
  if (!transcriptPath || !fs.existsSync(transcriptPath)) {
    return false;
  }

  try {
    const content = fs.readFileSync(transcriptPath, "utf-8");
    const lines = content.split("\n");
    // Check last 500 lines for the completion signal
    const tail = lines.slice(-500);
    return tail.some((line) => /^ALL_TASKS_COMPLETE\s*$/.test(line));
  } catch {
    return false;
  }
}

/**
 * Clean up orphaned temp progress files older than 60 minutes.
 */
function cleanupOrphanedProgressFiles(
  cwd: string,
  specPath: string
): void {
  const specDir = path.join(cwd, specPath);
  const cutoffMs = 60 * 60 * 1000; // 60 minutes

  try {
    const entries = fs.readdirSync(specDir);
    const now = Date.now();

    for (const entry of entries) {
      if (/^\.progress-task-\d+\.md$/.test(entry)) {
        const fullPath = path.join(specDir, entry);
        const stat = fs.statSync(fullPath);
        if (now - stat.mtimeMs > cutoffMs) {
          fs.unlinkSync(fullPath);
        }
      }
    }
  } catch {
    // Ignore cleanup errors
  }
}

// ---------------------------------------------------------------------------
// Core hook logic
// ---------------------------------------------------------------------------

/**
 * Main execution loop handler. Called on session.idle and tool.execute.after.
 *
 * Returns a HookResult:
 * - { decision: "continue" } when no action needed (no active spec, wrong phase, etc.)
 * - { decision: "block", reason, systemMessage } to inject a continuation prompt
 */
function handleExecutionLoop(context: HookContext): HookResult {
  const { cwd } = context;

  // 1. Check if plugin is disabled
  if (isPluginDisabled(cwd)) {
    return { decision: "continue" };
  }

  // 2. Resolve current spec
  const specPath = resolveCurrentSpec(cwd);
  if (!specPath) {
    return { decision: "continue" };
  }

  const specName = path.basename(specPath);

  // 3. Read state file
  const state = readState(cwd, specPath);
  if (!state) {
    return { decision: "continue" };
  }

  // 4. Check for completion signal in transcript (backup detection)
  if (isCompletionSignalInTranscript(context.transcriptPath)) {
    console.error(
      `[ralph-opencode] ALL_TASKS_COMPLETE detected in transcript`
    );
    return { decision: "continue" };
  }

  // 5. Check global iteration limit
  if (state.globalIteration >= state.maxGlobalIterations) {
    console.error(
      `[ralph-opencode] ERROR: Maximum global iterations (${state.maxGlobalIterations}) reached. ` +
        `Review .progress.md for failure patterns.`
    );
    console.error(
      `[ralph-opencode] Recovery: fix issues manually, then re-run implement or cancel`
    );
    return { decision: "continue" };
  }

  // 6. Skip non-execution phases
  if (state.phase !== "execution") {
    return { decision: "continue" };
  }

  // 7. Log current state
  console.error(
    `[ralph-opencode] Session stopped during spec: ${specName} | ` +
      `Task: ${state.taskIndex + 1}/${state.totalTasks} | ` +
      `Attempt: ${state.taskIteration}`
  );

  // 8. If all tasks done, signal completion
  if (state.taskIndex >= state.totalTasks) {
    return {
      decision: "block",
      reason:
        `All tasks complete for spec: ${specName}\n\n` +
        `Delete ${specPath}/${STATE_FILE_NAME} and output ALL_TASKS_COMPLETE.`,
      systemMessage: `Ralph: all ${state.totalTasks} tasks complete`,
    };
  }

  // 9. Output continuation prompt for next task
  const reason = [
    `Continue spec: ${specName} (Task ${state.taskIndex + 1}/${state.totalTasks}, Iter ${state.globalIteration})`,
    "",
    "## State",
    `Path: ${specPath} | Index: ${state.taskIndex} | Iteration: ${state.taskIteration}/${state.maxTaskIterations} | Recovery: ${state.recoveryMode}`,
    "",
    "## Resume",
    `1. Read ${specPath}/${STATE_FILE_NAME} and ${specPath}/tasks.md`,
    `2. Delegate task ${state.taskIndex} to spec-executor (or qa-engineer for [VERIFY])`,
    "3. On TASK_COMPLETE: verify, update state, advance",
    `4. If taskIndex >= totalTasks: delete state file, output ALL_TASKS_COMPLETE`,
    "",
    "## Critical",
    "- Delegate via Task tool - do NOT implement yourself",
    "- Verify all 4 layers before advancing (see implement SKILL.md)",
    "- On failure: increment taskIteration, retry or generate fix task if recoveryMode",
  ].join("\n");

  const systemMessage = `Ralph iteration ${state.globalIteration} | Task ${state.taskIndex + 1}/${state.totalTasks}`;

  // 10. Clean up orphaned temp progress files
  cleanupOrphanedProgressFiles(cwd, specPath);

  return {
    decision: "block",
    reason,
    systemMessage,
  };
}

// ---------------------------------------------------------------------------
// OpenCode plugin export
// ---------------------------------------------------------------------------

export default {
  name: "ralph-execution-loop",
  description:
    "Manages the Ralph spec-driven execution loop, continuing task " +
    "execution until all tasks are complete.",

  hooks: {
    /**
     * Fires when the session becomes idle. Checks if there are remaining
     * Ralph tasks and injects a continuation prompt if so.
     */
    "session.idle": async (context: HookContext): Promise<HookResult> => {
      return handleExecutionLoop(context);
    },

    /**
     * Fires after a tool execution completes. Checks if the tool was a
     * task completion and whether more tasks remain.
     */
    "tool.execute.after": async (context: HookContext): Promise<HookResult> => {
      return handleExecutionLoop(context);
    },
  },
};
