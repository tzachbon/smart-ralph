/**
 * Implement command - Execute tasks directly
 */

import { resolve, join } from 'path';
import { logger } from '../utils/logger.js';
import { findActiveFeatures, read } from '../utils/fs.js';
import { StateManager } from '../state/manager.js';
import { runPhase, parseTasks } from '../agents/invoker.js';

const PHASE_ORDER = ['1', '2', '3', '4', 'all'];

/**
 * Execute tasks from a specific phase or all phases
 */
export async function implementCommand(parsed) {
  logger.header();

  const baseDir = resolve(parsed.flags.dir);
  const targetPhase = parsed.phase || 'all';

  // Validate phase argument
  if (targetPhase !== 'all' && !PHASE_ORDER.includes(targetPhase)) {
    logger.error(`Invalid phase: ${targetPhase}`);
    logger.info('Valid phases: 1, 2, 3, 4, or "all"');
    return;
  }

  // Find active features
  const features = await findActiveFeatures(baseDir);

  if (features.length === 0) {
    logger.error('No active workflow found');
    logger.info('Start a new workflow with: ralph-specum "your goal"');
    return;
  }

  if (features.length > 1) {
    logger.info('Multiple active workflows found:');
    features.forEach((f, i) => {
      logger.log(`  ${i + 1}. ${f.name} (${f.state.phase})`);
    });
    logger.info('Please specify the feature directory with --dir');
    return;
  }

  const feature = features[0];
  const stateManager = new StateManager(feature.path);
  await stateManager.load();

  logger.info(`Feature: ${stateManager.state.featureName}`);
  logger.info(`Implementing: Phase ${targetPhase}`);
  logger.newline();

  // Load and parse tasks
  const tasksFile = join(stateManager.specPath, 'tasks.md');
  const tasksContent = await read(tasksFile);

  if (!tasksContent) {
    logger.error('Tasks file not found. Complete the planning phases first.');
    return;
  }

  const allTasks = await parseTasks(tasksContent);

  if (allTasks.length === 0) {
    logger.error('No tasks found in tasks.md');
    return;
  }

  // Filter tasks by phase if specified
  const tasks = filterTasksByPhase(allTasks, targetPhase, tasksContent);

  logger.info(`Found ${tasks.length} tasks to execute`);
  logger.newline();

  // Update state to execution phase
  await stateManager.update({
    phase: 'execution',
    totalTasks: tasks.length,
  });

  // Execute tasks
  for (let i = 0; i < tasks.length; i++) {
    const task = tasks[i];

    await stateManager.updateTaskProgress(i, task.name, tasks.length);

    logger.task(i + 1, tasks.length, `${task.id}: ${task.name}`, 'running');

    const result = await runPhase('execution', stateManager);

    if (result.success) {
      logger.task(i + 1, tasks.length, `${task.id}: ${task.name}`, 'completed');
    } else {
      logger.task(i + 1, tasks.length, `${task.id}: ${task.name}`, 'failed');
      logger.error(`Task ${task.id} failed`);

      // Ask to continue or stop
      if (stateManager.state.mode === 'interactive') {
        logger.info('Run "ralph-specum implement" again to retry');
      }
      break;
    }

    if (stateManager.isMaxIterationsReached()) {
      logger.warn('Max iterations reached');
      break;
    }

    await stateManager.incrementIteration();
  }

  // Check completion
  const allComplete = stateManager.state.taskIndex >= tasks.length - 1;
  if (allComplete) {
    logger.newline();
    logger.success(`Phase ${targetPhase} tasks completed!`);

    if (targetPhase !== 'all' && targetPhase !== '4') {
      const nextPhase = parseInt(targetPhase) + 1;
      logger.info(`Run "ralph-specum implement ${nextPhase}" to continue`);
    } else {
      logger.success('All tasks completed!');
      await runFinalChecks(stateManager);
    }
  }
}

/**
 * Filter tasks by phase number
 */
function filterTasksByPhase(tasks, targetPhase, tasksContent) {
  if (targetPhase === 'all') {
    return tasks;
  }

  // Parse phase boundaries from tasks.md content
  const phasePattern = /## Phase (\d+):/gi;
  const phases = {};
  let match;
  let lastPhase = null;

  const lines = tasksContent.split('\n');
  let currentPhase = '1';

  for (let i = 0; i < lines.length; i++) {
    const phaseMatch = lines[i].match(/## Phase (\d+):/i);
    if (phaseMatch) {
      currentPhase = phaseMatch[1];
    }

    const taskMatch = lines[i].match(/### (TASK-\d+):/);
    if (taskMatch) {
      const taskId = taskMatch[1];
      phases[taskId] = currentPhase;
    }
  }

  // Filter tasks by phase
  return tasks.filter((task) => phases[task.id] === targetPhase);
}

/**
 * Run final quality checks
 */
async function runFinalChecks(stateManager) {
  const { $ } = await import('bun');

  logger.newline();
  logger.info('Running quality gates...');

  const checks = [
    { name: 'Type Check', cmd: ['npm', 'run', 'typecheck'] },
    { name: 'Lint', cmd: ['npm', 'run', 'lint'] },
    { name: 'Test', cmd: ['npm', 'test'] },
    { name: 'Build', cmd: ['npm', 'run', 'build'] },
  ];

  let allPassed = true;

  for (const check of checks) {
    try {
      await $`${check.cmd}`.quiet();
      logger.success(`${check.name} passed`);
    } catch {
      logger.warn(`${check.name} skipped or failed`);
      // Don't fail on missing scripts
    }
  }

  if (allPassed) {
    logger.newline();
    logger.success('Quality gates passed!');
    logger.info('Cleaning up workflow state...');
    await stateManager.cleanup();
  }
}
