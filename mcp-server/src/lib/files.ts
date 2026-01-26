/**
 * FileManager for spec file operations.
 * Handles reading, writing, listing specs and managing the current spec.
 */

import { existsSync, mkdirSync, readdirSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { MCPLogger } from "./logger";

const SPECS_DIR = "specs";
const CURRENT_SPEC_FILE = ".current-spec";

export class FileManager {
  private readonly logger: MCPLogger;
  private readonly basePath: string;

  constructor(basePath?: string, logger?: MCPLogger) {
    this.basePath = basePath ?? process.cwd();
    this.logger = logger ?? new MCPLogger("FileManager");
  }

  /**
   * Get the specs directory path.
   */
  getSpecsDir(): string {
    return join(this.basePath, SPECS_DIR);
  }

  /**
   * Get the path for a specific spec directory.
   */
  getSpecDir(specName: string): string {
    return join(this.getSpecsDir(), specName);
  }

  /**
   * Get the path for a file within a spec directory.
   */
  getSpecFilePath(specName: string, fileName: string): string {
    return join(this.getSpecDir(specName), fileName);
  }

  /**
   * Get the path to the .current-spec file.
   */
  getCurrentSpecPath(): string {
    return join(this.getSpecsDir(), CURRENT_SPEC_FILE);
  }

  /**
   * Check if a spec exists.
   */
  specExists(specName: string): boolean {
    const specDir = this.getSpecDir(specName);
    return existsSync(specDir) && statSync(specDir).isDirectory();
  }

  /**
   * List all specs (directories in ./specs/).
   * Returns only directory names, not files.
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
   * Returns true on success, false on failure.
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
   * Returns true on success or if spec didn't exist.
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
   * Returns null if file doesn't exist or on error.
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
   * Creates the spec directory if it doesn't exist.
   * Returns true on success, false on failure.
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
   * Returns null if no current spec is set.
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
   * Creates the specs directory if it doesn't exist.
   * Returns true on success, false on failure.
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
