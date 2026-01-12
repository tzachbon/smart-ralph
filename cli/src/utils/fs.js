/**
 * File system utilities for ralph-specum CLI
 */

import { readFile, writeFile, mkdir, readdir, unlink, stat, access } from 'fs/promises';
import { join, dirname, resolve } from 'path';

/**
 * Check if a file or directory exists
 */
export async function exists(path) {
  try {
    await access(path);
    return true;
  } catch {
    return false;
  }
}

/**
 * Check if path is a directory
 */
export async function isDirectory(path) {
  try {
    const stats = await stat(path);
    return stats.isDirectory();
  } catch {
    return false;
  }
}

/**
 * Read a file and return its contents
 */
export async function read(path) {
  try {
    return await readFile(path, 'utf-8');
  } catch (error) {
    if (error.code === 'ENOENT') {
      return null;
    }
    throw error;
  }
}

/**
 * Write content to a file, creating directories if needed
 */
export async function write(path, content) {
  const dir = dirname(path);
  await mkdir(dir, { recursive: true });
  await writeFile(path, content, 'utf-8');
}

/**
 * Read and parse a JSON file
 */
export async function readJson(path) {
  const content = await read(path);
  if (content === null) return null;
  try {
    return JSON.parse(content);
  } catch (error) {
    throw new Error(`Invalid JSON in ${path}: ${error.message}`);
  }
}

/**
 * Write an object as JSON to a file
 */
export async function writeJson(path, data, pretty = true) {
  const content = pretty ? JSON.stringify(data, null, 2) : JSON.stringify(data);
  await write(path, content + '\n');
}

/**
 * Delete a file
 */
export async function remove(path) {
  try {
    await unlink(path);
    return true;
  } catch (error) {
    if (error.code === 'ENOENT') {
      return false;
    }
    throw error;
  }
}

/**
 * List files in a directory
 */
export async function list(path) {
  try {
    return await readdir(path);
  } catch (error) {
    if (error.code === 'ENOENT') {
      return [];
    }
    throw error;
  }
}

/**
 * Get the absolute path to a spec directory
 */
export function getSpecPath(baseDir, featureName) {
  return resolve(baseDir, featureName);
}

/**
 * Get paths to all spec files in a feature directory
 */
export function getSpecFiles(specPath) {
  return {
    state: join(specPath, '.ralph-state.json'),
    progress: join(specPath, '.ralph-progress.md'),
    research: join(specPath, 'research.md'),
    requirements: join(specPath, 'requirements.md'),
    design: join(specPath, 'design.md'),
    tasks: join(specPath, 'tasks.md'),
  };
}

/**
 * Find all feature directories with active ralph state
 */
export async function findActiveFeatures(baseDir) {
  const features = [];
  const dirs = await list(baseDir);

  for (const dir of dirs) {
    const statePath = join(baseDir, dir, '.ralph-state.json');
    if (await exists(statePath)) {
      const state = await readJson(statePath);
      if (state) {
        features.push({
          name: dir,
          path: join(baseDir, dir),
          state,
        });
      }
    }
  }

  return features;
}

/**
 * Get the CLI root directory (where agents/templates are stored)
 */
export function getCliRoot() {
  // When installed globally or via npm, use the package root
  // When running in development, use the parent directory
  const currentFile = new URL(import.meta.url).pathname;
  return resolve(dirname(currentFile), '..', '..');
}

/**
 * Get the project root directory (where the plugin is installed)
 */
export function getProjectRoot() {
  return resolve(getCliRoot(), '..');
}
