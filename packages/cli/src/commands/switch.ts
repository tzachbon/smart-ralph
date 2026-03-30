import { Command } from 'commander';
import path from 'path';
import { promises as fs } from 'fs';
import { getActiveSpec, setActiveSpec } from '../lib/spec-manager.js';
import { success, error as outputError } from '../lib/output.js';

const SPECS_DIR = 'specs';

export function registerSwitch(program: Command): void {
  program
    .command('switch')
    .description('Switch the active spec')
    .argument('<name>', 'spec name to switch to')
    .action(async (name: string) => {
      const specsDir = path.join(process.cwd(), SPECS_DIR);
      const specPath = path.join(specsDir, name);

      try {
        await fs.access(specPath);
      } catch {
        outputError(`Spec "${name}" not found in ${specsDir}`);
        process.exit(1);
      }

      await setActiveSpec(specsDir, name);
      success(`Active spec is now "${name}"`);
    });
}
