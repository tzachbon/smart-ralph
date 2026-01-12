/**
 * Run command - Main workflow orchestrator for ralph-specum
 */

import { mkdir } from 'fs/promises';
import { resolve, join } from 'path';
import { logger } from '../utils/logger.js';
import { validateGoal, deriveFeatureName } from '../utils/args.js';
import { exists, getSpecPath } from '../utils/fs.js';
import { StateManager, PHASES } from '../state/manager.js';
import { runPhase, parseTasks } from '../agents/invoker.js';
import { isGitRepo, getCurrentBranch, isMainBranch, hasGhCli } from '../utils/git.js';

/**
 * Run the main ralph-specum workflow
 */
export async function runCommand(parsed) {
  logger.header();

  // Validate goal
  const goal = validateGoal(parsed.goal);
  const featureName = deriveFeatureName(goal);
  const baseDir = resolve(parsed.flags.dir);
  const specPath = getSpecPath(baseDir, featureName);
  const mode = parsed.flags.mode;
  const maxIterations = parsed.flags.maxIterations;

  logger.info(`Goal: ${goal}`);
  logger.info(`Feature: ${featureName}`);
  logger.info(`Spec directory: ${specPath}`);
  logger.info(`Mode: ${mode}`);
  logger.newline();

  // Check if already running
  const stateManager = new StateManager(specPath);
  if (await stateManager.exists()) {
    const existingState = await stateManager.load();
    logger.warn(`Found existing workflow in ${specPath}`);
    logger.info(`Phase: ${existingState.phase}, Iteration: ${existingState.iteration}`);
    logger.info('Use "ralph-specum approve" to continue or "ralph-specum cancel" to start fresh');
    return;
  }

  // Create spec directory
  await mkdir(specPath, { recursive: true });
  logger.success(`Created spec directory: ${specPath}`);

  // Initialize state
  await stateManager.initialize({
    mode,
    goal,
    featureName,
    specPath,
    maxIterations,
  });
  logger.success('Initialized workflow state');

  // Check git status
  if (await isGitRepo()) {
    const branch = await getCurrentBranch();
    const onMain = await isMainBranch();
    logger.info(`Git branch: ${branch}`);
    if (onMain) {
      logger.warn('You are on the main branch. Consider creating a feature branch.');
    }
  }

  // Check gh CLI availability
  const hasGh = await hasGhCli();
  if (!hasGh) {
    logger.warn('GitHub CLI (gh) not found. PR creation will be skipped.');
  }

  logger.divider();

  // Run workflow based on mode
  if (mode === 'auto') {
    await runAutoMode(stateManager);
  } else {
    await runInteractiveMode(stateManager);
  }
}

/**
 * Run workflow in auto mode (fully autonomous)
 */
async function runAutoMode(stateManager) {
  logger.info('Running in AUTO mode - phases will advance automatically');
  logger.newline();

  const phasesToRun = ['research', 'requirements', 'design', 'tasks'];

  for (const phase of phasesToRun) {
    // Check iteration limit
    if (stateManager.isMaxIterationsReached()) {
      logger.warn(`Max iterations (${stateManager.state.maxIterations}) reached`);
      break;
    }

    // Run phase
    const result = await runPhase(phase, stateManager);
    if (!result.success) {
      logger.error(`Phase ${phase} failed. Stopping workflow.`);
      await stateManager.addLearning(`Phase ${phase} failed: ${result.error}`);
      return;
    }

    // Auto-approve phase
    await stateManager.approvePhase(phase);
    await stateManager.advancePhase();
    await stateManager.incrementIteration();

    logger.success(`Phase ${phase} completed and approved`);
    logger.newline();
  }

  // Run execution phase
  if (stateManager.getPhase() === 'execution') {
    await runExecutionPhase(stateManager);
  }
}

/**
 * Run workflow in interactive mode (pause for approval)
 */
async function runInteractiveMode(stateManager) {
  logger.info('Running in INTERACTIVE mode - will pause for approval after each phase');
  logger.newline();

  const phase = stateManager.getPhase();

  // Run current phase
  const result = await runPhase(phase, stateManager);
  if (!result.success) {
    logger.error(`Phase ${phase} failed`);
    await stateManager.addLearning(`Phase ${phase} failed: ${result.error}`);
    return;
  }

  logger.success(`Phase ${phase} completed`);
  logger.newline();

  // Show next steps
  logger.box('Next Steps', `Review the generated ${phase}.md file in:
${stateManager.specPath}

Then run one of:
  ralph-specum approve    - Approve and continue
  ralph-specum cancel     - Cancel the workflow`);
}

/**
 * Run the execution phase (task by task)
 */
async function runExecutionPhase(stateManager) {
  const { read } = await import('../utils/fs.js');
  const tasksFile = join(stateManager.specPath, 'tasks.md');
  const tasksContent = await read(tasksFile);

  if (!tasksContent) {
    logger.error('Tasks file not found');
    return;
  }

  const tasks = await parseTasks(tasksContent);
  await stateManager.update({ totalTasks: tasks.length });

  logger.info(`Found ${tasks.length} tasks to execute`);
  logger.newline();

  for (let i = 0; i < tasks.length; i++) {
    const task = tasks[i];

    // Update state
    await stateManager.updateTaskProgress(i, task.name, tasks.length);

    logger.task(i + 1, tasks.length, `${task.id}: ${task.name}`, 'running');

    // Run execution phase for this task
    const result = await runPhase('execution', stateManager);

    if (result.success) {
      logger.task(i + 1, tasks.length, `${task.id}: ${task.name}`, 'completed');
    } else {
      logger.task(i + 1, tasks.length, `${task.id}: ${task.name}`, 'failed');
      logger.error(`Task ${task.id} failed: ${result.error}`);
      await stateManager.addLearning(`Task ${task.id} failed: ${result.error}`);
      break;
    }

    // Check iteration limit
    if (stateManager.isMaxIterationsReached()) {
      logger.warn(`Max iterations reached during execution`);
      break;
    }

    await stateManager.incrementIteration();
  }

  // Workflow complete
  if (stateManager.state.taskIndex >= tasks.length - 1) {
    logger.newline();
    logger.success('All tasks completed!');
    logger.info('Running final quality checks...');

    // Quality gates would run here
    await runQualityGates(stateManager);
  }
}

/**
 * Run quality gates (final phase)
 */
async function runQualityGates(stateManager) {
  const { $ } = await import('bun');
  const checks = [
    { name: 'Type Check', cmd: 'npm run typecheck', optional: true },
    { name: 'Lint', cmd: 'npm run lint', optional: true },
    { name: 'Test', cmd: 'npm test', optional: true },
    { name: 'Build', cmd: 'npm run build', optional: true },
  ];

  for (const check of checks) {
    try {
      logger.info(`Running ${check.name}...`);
      await $`${check.cmd.split(' ')}`.quiet();
      logger.success(`${check.name} passed`);
    } catch (error) {
      if (check.optional) {
        logger.warn(`${check.name} not available or failed (optional)`);
      } else {
        logger.error(`${check.name} failed`);
        await stateManager.addLearning(`Quality gate "${check.name}" failed`);
        return false;
      }
    }
  }

  // Cleanup on success
  logger.newline();
  logger.success('Workflow completed successfully!');
  logger.info('Cleaning up state files...');
  await stateManager.cleanup();

  return true;
}
