/**
 * FileManager for spec file operations.
 * Handles reading, writing, listing specs and managing the current spec.
 * @module files
 */

import { existsSync, mkdirSync, readdirSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { MCPLogger } from "./logger";

/** Default directory name for specs */
const SPECS_DIR = "specs";

/** Filename for tracking the current active spec */
const CURRENT_SPEC_FILE = ".current-spec";

/**
 * FileManager for managing spec files and directories.
 *
 * Handles all file system operations for the Ralph Specum workflow:
 * - Creating and deleting spec directories
 * - Reading and writing spec files
 * - Managing the current active spec
 * - Listing all available specs
 *
 * @example
 * ```typescript
 * const logger = new MCPLogger("FileManager");
 * const fileManager = new FileManager(process.cwd(), logger);
 *
 * // List all specs
 * const specs = fileManager.listSpecs();
 *
 * // Read a spec file
 * const content = fileManager.readSpecFile("my-feature", "research.md");
 *
 * // Write a spec file
 * fileManager.writeSpecFile("my-feature", "design.md", "# Design\n...");
 * ```
 */
export class FileManager {
  private readonly logger: MCPLogger;
  private readonly basePath: string;

  /**
   * Create a new FileManager instance.
   *
   * @param basePath - Base directory for all operations. Defaults to process.cwd().
   * @param logger - Optional MCPLogger instance. If not provided, creates a new
   *                 logger with name "FileManager".
   */
  constructor(basePath?: string, logger?: MCPLogger) {
    this.basePath = basePath ?? process.cwd();
    this.logger = logger ?? new MCPLogger("FileManager");
  }

  /**
   * Get the absolute path to the specs directory.
   *
   * @returns Absolute path to ./specs/
   */
  getSpecsDir(): string {
    return join(this.basePath, SPECS_DIR);
  }

  /**
   * Get the absolute path to a specific spec's directory.
   *
   * @param specName - Name of the spec
   * @returns Absolute path to ./specs/{specName}/
   */
  getSpecDir(specName: string): string {
    return join(this.getSpecsDir(), specName);
  }

  /**
   * Get the absolute path to a file within a spec directory.
   *
   * @param specName - Name of the spec
   * @param fileName - Name of the file within the spec directory
   * @returns Absolute path to ./specs/{specName}/{fileName}
   */
  getSpecFilePath(specName: string, fileName: string): string {
    return join(this.getSpecDir(specName), fileName);
  }

  /**
   * Get the absolute path to the .current-spec file.
   *
   * @returns Absolute path to ./specs/.current-spec
   */
  getCurrentSpecPath(): string {
    return join(this.getSpecsDir(), CURRENT_SPEC_FILE);
  }

  /**
   * Check if a spec directory exists.
   *
   * @param specName - Name of the spec to check
   * @returns true if the spec directory exists and is a directory
   */
  specExists(specName: string): boolean {
    const specDir = this.getSpecDir(specName);
    return existsSync(specDir) && statSync(specDir).isDirectory();
  }

  /**
   * List all spec directories.
   *
   * Returns only directory names (not files) from the specs directory,
   * sorted alphabetically.
   *
   * @returns Array of spec names, or empty array if none exist
   */
  listSpecs(): string[] {
    const specsDir = this.getSpecsDir();

    if (!existsSync(specsDir)) {
      return [];
    }

    try {
      const entries = readdirSync(specsDir, { withFileTypes: true });
      return entries
        .filter((entry) => entry.isDirectory())
        .map((entry) => entry.name)
        .sort();
    } catch (error) {
      this.logger.error("Failed to list specs", {
        path: specsDir,
        error: error instanceof Error ? error.message : String(error),
      });
      return [];
    }
  }

  /**
   * Create a spec directory.
   *
   * Creates the directory recursively if parent directories don't exist.
   *
   * @param specName - Name of the spec directory to create
   * @returns true on success, false on failure
   */
  createSpecDir(specName: string): boolean {
    const specDir = this.getSpecDir(specName);

    try {
      if (!existsSync(specDir)) {
        mkdirSync(specDir, { recursive: true });
        this.logger.debug("Created spec directory", { path: specDir });
      }
      return true;
    } catch (error) {
      this.logger.error("Failed to create spec directory", {
        path: specDir,
        error: error instanceof Error ? error.message : String(error),
      });
      return false;
    }
  }

  /**
   * Delete a spec directory and all its contents.
   *
   * @param specName - Name of the spec directory to delete
   * @returns true on success or if spec didn't exist, false on error
   */
  deleteSpec(specName: string): boolean {
    const specDir = this.getSpecDir(specName);

    if (!existsSync(specDir)) {
      return true;
    }

    try {
      rmSync(specDir, { recursive: true, force: true });
      this.logger.debug("Deleted spec directory", { path: specDir });
      return true;
    } catch (error) {
      this.logger.error("Failed to delete spec directory", {
        path: specDir,
        error: error instanceof Error ? error.message : String(error),
      });
      return false;
    }
  }

  /**
   * Read a file from a spec directory.
   *
   * @param specName - Name of the spec
   * @param fileName - Name of the file to read
   * @returns File contents as string, or null if file doesn't exist or on error
   */
  readSpecFile(specName: string, fileName: string): string | null {
    const filePath = this.getSpecFilePath(specName, fileName);

    if (!existsSync(filePath)) {
      return null;
    }

    try {
      return readFileSync(filePath, "utf-8");
    } catch (error) {
      this.logger.error("Failed to read spec file", {
        path: filePath,
        error: error instanceof Error ? error.message : String(error),
      });
      return null;
    }
  }

  /**
   * Write a file to a spec directory.
   *
   * Creates the spec directory if it doesn't exist.
   *
   * @param specName - Name of the spec
   * @param fileName - Name of the file to write
   * @param content - Content to write to the file
   * @returns true on success, false on failure
   */
  writeSpecFile(specName: string, fileName: string, content: string): boolean {
    const specDir = this.getSpecDir(specName);
    const filePath = this.getSpecFilePath(specName, fileName);

    try {
      // Ensure spec directory exists
      if (!existsSync(specDir)) {
        mkdirSync(specDir, { recursive: true });
      }

      writeFileSync(filePath, content, "utf-8");
      this.logger.debug("Wrote spec file", { path: filePath });
      return true;
    } catch (error) {
      this.logger.error("Failed to write spec file", {
        path: filePath,
        error: error instanceof Error ? error.message : String(error),
      });
      return false;
    }
  }

  /**
   * Get the current active spec name.
   *
   * @returns Current spec name, or null if no current spec is set
   */
  getCurrentSpec(): string | null {
    const currentSpecPath = this.getCurrentSpecPath();

    if (!existsSync(currentSpecPath)) {
      return null;
    }

    try {
      const content = readFileSync(currentSpecPath, "utf-8").trim();
      return content || null;
    } catch (error) {
      this.logger.error("Failed to read current spec", {
        path: currentSpecPath,
        error: error instanceof Error ? error.message : String(error),
      });
      return null;
    }
  }

  /**
   * Set the current active spec.
   *
   * Creates the specs directory if it doesn't exist.
   *
   * @param specName - Name of the spec to set as current
   * @returns true on success, false on failure
   */
  setCurrentSpec(specName: string): boolean {
    const specsDir = this.getSpecsDir();
    const currentSpecPath = this.getCurrentSpecPath();

    try {
      // Ensure specs directory exists
      if (!existsSync(specsDir)) {
        mkdirSync(specsDir, { recursive: true });
      }

      writeFileSync(currentSpecPath, specName, "utf-8");
      this.logger.debug("Set current spec", { specName });
      return true;
    } catch (error) {
      this.logger.error("Failed to set current spec", {
        specName,
        error: error instanceof Error ? error.message : String(error),
      });
      return false;
    }
  }
}
