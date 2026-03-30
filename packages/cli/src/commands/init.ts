import { Command } from 'commander';
import fs from 'fs';
import path from 'path';
import os from 'os';
import { writeConfig } from '../lib/config.js';
import { success, info } from '../lib/output.js';

const DEFAULT_CONFIG = {
  provider: 'claude',
  model: 'claude-sonnet-4-20250514',
  apiKeyEnvVar: 'ANTHROPIC_API_KEY',
};

export function registerInit(program: Command): void {
  program
    .command('init')
    .description('Initialize ralph in the current project')
    .option('--global', 'write to ~/.ralph/config.json instead of .ralph/config.json')
    .action((opts: { global?: boolean }) => {
      const configPath = opts.global
        ? path.join(os.homedir(), '.ralph', 'config.json')
        : path.join(process.cwd(), '.ralph', 'config.json');

      writeConfig(configPath, DEFAULT_CONFIG);
      success(`Config written to ${configPath}`);

      if (!opts.global) {
        const specsDir = path.join(process.cwd(), 'specs');
        if (!fs.existsSync(specsDir)) {
          fs.mkdirSync(specsDir, { recursive: true });
          success(`Created specs/ directory`);
        } else {
          info(`specs/ directory already exists`);
        }

        info(`Next: run "ralph new <name> \\"<goal>\\"" to create your first spec`);
      }
    });
}
