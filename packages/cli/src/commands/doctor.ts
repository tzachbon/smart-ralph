import { Command } from 'commander';
import fs from 'fs';
import path from 'path';
import os from 'os';
import { resolveConfig, getApiKey } from '../lib/config.js';

const SPECS_DIR = 'specs';

interface Check {
  label: string;
  pass: boolean;
  detail?: string;
}

function printCheck(check: Check): void {
  const icon = check.pass ? '[PASS]' : '[FAIL]';
  const detail = check.detail ? ` — ${check.detail}` : '';
  console.log(`  ${icon} ${check.label}${detail}`);
}

export function registerDoctor(program: Command): void {
  program
    .command('doctor')
    .description('Check environment and configuration')
    .action(() => {
      const checks: Check[] = [];

      // Node.js version check
      const nodeVersion = process.versions.node;
      const [major] = nodeVersion.split('.').map(Number);
      checks.push({
        label: `Node.js >= 18 (found ${nodeVersion})`,
        pass: major >= 18,
        detail: major < 18 ? 'Upgrade Node.js to v18 or later' : undefined,
      });

      // Config present
      let config = null;
      let configError: string | undefined;
      try {
        config = resolveConfig();
      } catch (err) {
        configError = err instanceof Error ? err.message : String(err);
      }
      checks.push({
        label: 'Config found (env vars or config file)',
        pass: config !== null,
        detail: configError,
      });

      // API key set
      if (config) {
        const apiKey = getApiKey(config);
        checks.push({
          label: `API key env var set ($${config.apiKeyEnvVar})`,
          pass: apiKey !== null && apiKey.length > 0,
          detail: apiKey ? undefined : `Set the ${config.apiKeyEnvVar} environment variable`,
        });
      } else {
        checks.push({
          label: 'API key env var set',
          pass: false,
          detail: 'Cannot check — no config found',
        });
      }

      // specs/ directory
      const projectSpecsDir = path.join(process.cwd(), SPECS_DIR);
      const globalSpecsDir = path.join(os.homedir(), SPECS_DIR);
      const specsExists =
        fs.existsSync(projectSpecsDir) || fs.existsSync(globalSpecsDir);
      checks.push({
        label: 'specs/ directory exists',
        pass: specsExists,
        detail: specsExists ? undefined : 'Run "ralph init" to create it',
      });

      console.log('\nRalph Doctor\n');
      for (const check of checks) {
        printCheck(check);
      }
      console.log('');

      const allPass = checks.every((c) => c.pass);
      if (!allPass) {
        process.exit(1);
      }
    });
}
