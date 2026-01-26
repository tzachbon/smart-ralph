/**
 * StateManager for .ralph-state.json files.
 * Handles reading, writing, and deleting state files with corruption handling.
 */

import { existsSync, renameSync, unlinkSync, writeFileSync, readFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { MCPLogger } from "./logger";

/** Valid workflow phases */
export type Phase = "research" | "requirements" | "design" | "tasks" | "execution";

/** Task source origin */
export type Source = "spec" | "plan" | "direct";

/** Related spec information */
export interface RelatedSpec {
  name: string;
  relevance: "high" | "medium" | "low";
  reason: string;
  mayNeedUpdate?: boolean;
}

/** Parallel task group information */
export interface ParallelGroup {
  startIndex: number;
  endIndex: number;
  taskIndices: number[];
}

/** Task execution result */
export interface TaskResult {
  status: "pending" | "success" | "failed";
  error?: string;
}

/**
 * RalphState interface matching the spec.schema.json definition.
 * Required fields: source, name, basePath, phase
 * Optional fields: taskIndex, totalTasks, taskIteration, etc.
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

const STATE_FILENAME = ".ralph-state.json";

export class StateManager {
  private readonly logger: MCPLogger;

  constructor(logger?: MCPLogger) {
    this.logger = logger ?? new MCPLogger("StateManager");
  }

  /**
   * Get the state file path for a spec directory.
   */
  getStatePath(specDir: string): string {
    return join(specDir, STATE_FILENAME);
  }

  /**
   * Check if a state file exists.
   */
  exists(specDir: string): boolean {
    return existsSync(this.getStatePath(specDir));
  }

  /**
   * Read state from a spec directory.
   * Returns null if file doesn't exist or is corrupt.
   * Corrupt files are backed up before returning null.
   */
  read(specDir: string): RalphState | null {
    const statePath = this.getStatePath(specDir);

    if (!existsSync(statePath)) {
      return null;
    }

    try {
      const content = readFileSync(statePath, "utf-8");
      const parsed = JSON.parse(content);

      // Validate required fields
      if (!this.validateState(parsed)) {
        this.logger.warning("Invalid state file - missing required fields", { path: statePath });
        this.backupCorruptFile(statePath);
        return null;
      }

      return parsed as RalphState;
    } catch (error) {
      this.logger.error("Failed to read state file", {
        path: statePath,
        error: error instanceof Error ? error.message : String(error),
      });
      this.backupCorruptFile(statePath);
      return null;
    }
  }

  /**
   * Write state to a spec directory.
   * Uses atomic write via temp file + rename.
   */
  write(specDir: string, state: RalphState): boolean {
    const statePath = this.getStatePath(specDir);
    const tempPath = `${statePath}.tmp`;

    try {
      // Ensure directory exists
      const dir = dirname(statePath);
      if (!existsSync(dir)) {
        mkdirSync(dir, { recursive: true });
      }

      // Write to temp file first
      const content = JSON.stringify(state, null, 2);
      writeFileSync(tempPath, content, "utf-8");

      // Atomic rename
      renameSync(tempPath, statePath);

      this.logger.debug("State written successfully", { path: statePath });
      return true;
    } catch (error) {
      this.logger.error("Failed to write state file", {
        path: statePath,
        error: error instanceof Error ? error.message : String(error),
      });

      // Clean up temp file if it exists
      try {
        if (existsSync(tempPath)) {
          unlinkSync(tempPath);
        }
      } catch {
        // Ignore cleanup errors
      }

      return false;
    }
  }

  /**
   * Delete state file from a spec directory.
   * Returns true if deleted or didn't exist.
   */
  delete(specDir: string): boolean {
    const statePath = this.getStatePath(specDir);

    if (!existsSync(statePath)) {
      return true;
    }

    try {
      unlinkSync(statePath);
      this.logger.debug("State deleted successfully", { path: statePath });
      return true;
    } catch (error) {
      this.logger.error("Failed to delete state file", {
        path: statePath,
        error: error instanceof Error ? error.message : String(error),
      });
      return false;
    }
  }

  /**
   * Validate that an object has all required RalphState fields.
   */
  private validateState(obj: unknown): boolean {
    if (typeof obj !== "object" || obj === null) {
      return false;
    }

    const state = obj as Record<string, unknown>;

    // Check required fields
    if (typeof state.source !== "string") return false;
    if (!["spec", "plan", "direct"].includes(state.source)) return false;

    if (typeof state.name !== "string") return false;
    if (typeof state.basePath !== "string") return false;

    if (typeof state.phase !== "string") return false;
    if (!["research", "requirements", "design", "tasks", "execution"].includes(state.phase)) return false;

    return true;
  }

  /**
   * Backup a corrupt state file by renaming it with .bak extension.
   */
  private backupCorruptFile(statePath: string): void {
    const backupPath = `${statePath}.bak`;

    try {
      if (existsSync(statePath)) {
        renameSync(statePath, backupPath);
        this.logger.warning("Corrupt state file backed up", { original: statePath, backup: backupPath });
      }
    } catch (error) {
      this.logger.error("Failed to backup corrupt state file", {
        path: statePath,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }
}
