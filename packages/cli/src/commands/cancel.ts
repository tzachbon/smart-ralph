import { Command } from 'commander';
import path from 'path';
import { getActiveSpec, deleteState } from '../lib/spec-manager.js';
import { success, info, error as outputError } from '../lib/output.js';

const SPECS_DIR = 'specs';

export function registerCancel(program: Command): void {
  program
    .command('cancel')
    .description('Cancel active execution for a spec')
    .argument('[name]', 'spec name (defaults to active spec)')
    .action(async (nameArg: string | undefined) => {
      const specsDir = path.join(process.cwd(), SPECS_DIR);

      const name = nameArg ?? await getActiveSpec(specsDir);
      if (!name) {
        outputError('No active spec. Pass a spec name or run "ralph new <name> <goal>".');
        process.exit(1);
      }

      const specPath = path.join(specsDir, name);
      await deleteState(specPath);
      success(`Cancelled execution for spec "${name}"`);
      info('State file removed. Run "ralph run" to restart from the beginning.');
    });
}
