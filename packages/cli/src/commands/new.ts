import { Command } from 'commander';
import path from 'path';
import {
  validateSpecName,
  createSpec,
  setActiveSpec,
} from '../lib/spec-manager.js';
import { success, error as outputError, info } from '../lib/output.js';

const SPECS_DIR = 'specs';

export function registerNew(program: Command): void {
  program
    .command('new')
    .description('Create a new spec')
    .argument('<name>', 'spec name (lowercase, hyphens allowed)')
    .argument('<goal>', 'one-sentence goal for this spec')
    .option('--force', 'overwrite existing spec if it exists')
    .action(async (name: string, goal: string) => {
      if (!validateSpecName(name)) {
        outputError(`Invalid spec name "${name}". Must match /^[a-z0-9][a-z0-9\\-_]*$/`);
        process.exit(1);
      }

      const specsDir = path.join(process.cwd(), SPECS_DIR);

      try {
        const specPath = await createSpec(specsDir, name, goal);
        await setActiveSpec(specsDir, name);
        success(`Created spec "${name}" at ${specPath}`);
        info(`Active spec set to "${name}"`);
        info(`Next: run "ralph research" to generate research for this spec`);
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        outputError(msg);
        process.exit(1);
      }
    });
}
