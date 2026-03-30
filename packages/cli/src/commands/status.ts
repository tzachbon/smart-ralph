import { Command } from 'commander';
import path from 'path';
import { getActiveSpec, readState, readSpecFile } from '../lib/spec-manager.js';
import { parseTasks } from '../lib/task-parser.js';
import { info, error as outputError } from '../lib/output.js';

const SPECS_DIR = 'specs';

interface StatusOutput {
  name: string;
  phase: string;
  taskIndex: number;
  totalTasks: number;
  completionPercent: number;
}

export function registerStatus(program: Command): void {
  program
    .command('status')
    .description('Show status of the active or named spec')
    .argument('[name]', 'spec name (defaults to active spec)')
    .option('--json', 'output as JSON')
    .action(async (nameArg: string | undefined, opts: { json?: boolean }) => {
      const specsDir = path.join(process.cwd(), SPECS_DIR);

      const name = nameArg ?? await getActiveSpec(specsDir);
      if (!name) {
        outputError('No active spec. Pass a spec name or run "ralph new <name> <goal>".');
        process.exit(1);
      }

      const specPath = path.join(specsDir, name);
      const state = await readState(specPath);

      // Parse tasks for accurate completion count
      let completedCount = 0;
      let totalCount = state.totalTasks;
      try {
        const tasksContent = await readSpecFile(specPath, 'tasks');
        const tasks = parseTasks(tasksContent);
        totalCount = tasks.length;
        completedCount = tasks.filter((t) => t.completed).length;
      } catch {
        // tasks.md may not exist yet
        completedCount = state.taskIndex;
        totalCount = state.totalTasks;
      }

      const completionPercent =
        totalCount > 0 ? Math.round((completedCount / totalCount) * 100) : 0;

      const output: StatusOutput = {
        name,
        phase: state.phase,
        taskIndex: completedCount,
        totalTasks: totalCount,
        completionPercent,
      };

      if (opts.json) {
        console.log(JSON.stringify(output));
        return;
      }

      info(`Spec:     ${name}`);
      info(`Phase:    ${state.phase}`);
      info(`Tasks:    ${completedCount}/${totalCount} (${completionPercent}%)`);
    });
}
