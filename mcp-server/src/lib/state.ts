/**
 * StateManager for .ralph-state.json files.
 * Handles reading, writing, and deleting state files with corruption handling.
 * @module state
 */

import { existsSync, renameSync, unlinkSync, writeFileSync, readFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { z } from "zod";
import { MCPLogger } from "./logger";
import type { Phase, Source, RelatedSpec, ParallelGroup, TaskResult, RalphState } from "./types";

// Re-export types for convenience
export type { Phase, Source, RelatedSpec, ParallelGroup, TaskResult, RalphState };

/** Default filename for state files */
const STATE_FILENAME = ".ralph-state.json";

// Zod schemas for validation

/**
 * Zod schema for RelatedSpec validation.
 */
const RelatedSpecSchema = z.object({
  name: z.string(),
  relevance: z.enum(["high", "medium", "low"]),
  reason: z.string(),
  mayNeedUpdate: z.boolean().optional(),
});

/**
 * Zod schema for ParallelGroup validation.
 */
const ParallelGroupSchema = z.object({
  startIndex: z.number(),
  endIndex: z.number(),
  taskIndices: z.array(z.number()),
});

/**
 * Zod schema for TaskResult validation.
 */
const TaskResultSchema = z.object({
  status: z.enum(["pending", "success", "failed"]),
  error: z.string().optional(),
});

/**
 * Zod schema for RalphState validation.
 * Validates all required and optional fields according to the spec schema.
 */
export const RalphStateSchema = z.object({
  source: z.enum(["spec", "plan", "direct"]),
  name: z.string(),
  basePath: z.string(),
  phase: z.enum(["research", "requirements", "design", "tasks", "execution"]),
  taskIndex: z.number().optional(),
  totalTasks: z.number().optional(),
  taskIteration: z.number().optional(),
  maxTaskIterations: z.number().optional(),
  globalIteration: z.number().optional(),
  maxGlobalIterations: z.number().optional(),
  relatedSpecs: z.array(RelatedSpecSchema).optional(),
  parallelGroup: ParallelGroupSchema.optional(),
  taskResults: z.record(z.string(), TaskResultSchema).optional(),
});

/**
 * StateManager for reading, writing, and managing .ralph-state.json files.
 *
 * Handles:
 * - Atomic writes via temp file + rename
 * - Schema validation using Zod
 * - Corrupt file backup and recovery
 * - Logging of all operations
 *
 * @example
 * ```typescript
 * const logger = new MCPLogger("StateManager");
 * const stateManager = new StateManager(logger);
 *
 * // Read state
 * const state = stateManager.read("/path/to/spec");
 * if (state) {
 *   console.log(state.phase); // "research"
 * }
 *
 * // Write state
 * stateManager.write("/path/to/spec", { ...state, phase: "requirements" });
 * ```
 */
export class StateManager {
  private readonly logger: MCPLogger;

  /**
   * Create a new StateManager instance.
   *
   * @param logger - Optional MCPLogger instance. If not provided, creates
   *                 a new logger with name "StateManager".
   */
  constructor(logger?: MCPLogger) {
    this.logger = logger ?? new MCPLogger("StateManager");
  }

  /**
   * Get the full path to the state file for a spec directory.
   *
   * @param specDir - Path to the spec directory
   * @returns Full path to the .ralph-state.json file
   */
  getStatePath(specDir: string): string {
    return join(specDir, STATE_FILENAME);
  }

  /**
   * Check if a state file exists for the given spec directory.
   *
   * @param specDir - Path to the spec directory
   * @returns true if the state file exists, false otherwise
   */
  exists(specDir: string): boolean {
    return existsSync(this.getStatePath(specDir));
  }

  /**
   * Read and validate state from a spec directory.
   *
   * If the state file is missing, returns null.
   * If the state file is corrupt or invalid, backs it up and returns null.
   *
   * @param specDir - Path to the spec directory
   * @returns Validated RalphState object, or null if not found/invalid
   */
  read(specDir: string): RalphState | null {
    const statePath = this.getStatePath(specDir);

    if (!existsSync(statePath)) {
      return null;
    }

    try {
      const content = readFileSync(statePath, "utf-8");
      const parsed = JSON.parse(content);

      // Validate with Zod schema
      const validatedState = this.validateState(parsed);
      if (!validatedState) {
        this.logger.warning("Invalid state file - schema validation failed", { path: statePath });
        this.backupCorruptFile(statePath);
        return null;
      }

      return validatedState;
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
   * Write state to a spec directory using atomic write.
   *
   * Uses temp file + rename pattern to ensure atomic writes.
   * Creates the spec directory if it doesn't exist.
   *
   * @param specDir - Path to the spec directory
   * @param state - The RalphState object to write
   * @returns true on success, false on failure
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
   *
   * @param specDir - Path to the spec directory
   * @returns true if deleted or didn't exist, false on error
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
   * Validate that an object is a valid RalphState using Zod schema.
   *
   * @param obj - The object to validate
   * @returns Validated RalphState, or null if validation fails
   */
  private validateState(obj: unknown): RalphState | null {
    const result = RalphStateSchema.safeParse(obj);
    if (result.success) {
      return result.data;
    }
    return null;
  }

  /**
   * Backup a corrupt state file by renaming it with .bak extension.
   *
   * @param statePath - Path to the corrupt state file
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
