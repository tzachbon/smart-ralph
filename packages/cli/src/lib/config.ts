import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { z } from 'zod';
import { ConfigError } from './errors.js';
import type { RalphConfig } from '../types/index.js';

export const RalphConfigSchema = z.object({
  provider: z.string().min(1),
  model: z.string().min(1),
  apiKeyEnvVar: z.string().min(1),
});

const PROJECT_CONFIG_PATH = path.join('.ralph', 'config.json');
const GLOBAL_CONFIG_PATH = path.join(os.homedir(), '.ralph', 'config.json');

function readConfigFile(filePath: string): Partial<RalphConfig> | null {
  try {
    const raw = fs.readFileSync(filePath, 'utf-8');
    const parsed = JSON.parse(raw);
    return parsed as Partial<RalphConfig>;
  } catch {
    return null;
  }
}

/**
 * Resolve config with precedence:
 * 1. Env vars (RALPH_PROVIDER, RALPH_MODEL)
 * 2. Project config: .ralph/config.json (relative to cwd)
 * 3. Global config: ~/.ralph/config.json
 *
 * Throws ConfigError if no valid config is found.
 */
export function resolveConfig(): RalphConfig {
  const projectConfig = readConfigFile(path.resolve(process.cwd(), PROJECT_CONFIG_PATH));
  const globalConfig = readConfigFile(GLOBAL_CONFIG_PATH);

  // Merge: global < project < env vars
  const base: Partial<RalphConfig> = {
    ...globalConfig,
    ...projectConfig,
  };

  const provider = process.env['RALPH_PROVIDER'] ?? base.provider;
  const model = process.env['RALPH_MODEL'] ?? base.model;
  const apiKeyEnvVar = base.apiKeyEnvVar;

  const result = RalphConfigSchema.safeParse({ provider, model, apiKeyEnvVar });

  if (!result.success) {
    const missing = result.error.issues.map((i) => i.path.join('.')).join(', ');
    throw new ConfigError(`Invalid or missing config fields: ${missing}`);
  }

  return result.data;
}

/**
 * Write config to disk. Never writes the actual API key, only apiKeyEnvVar.
 */
export function writeConfig(configPath: string, config: RalphConfig): void {
  const dir = path.dirname(configPath);
  fs.mkdirSync(dir, { recursive: true });

  const toWrite: RalphConfig = {
    provider: config.provider,
    model: config.model,
    apiKeyEnvVar: config.apiKeyEnvVar,
  };

  fs.writeFileSync(configPath, JSON.stringify(toWrite, null, 2) + '\n', 'utf-8');
}

/**
 * Read the actual API key from the environment variable named in config.apiKeyEnvVar.
 * Returns null if the variable is not set.
 */
export function getApiKey(config: RalphConfig): string | null {
  return process.env[config.apiKeyEnvVar] ?? null;
}
