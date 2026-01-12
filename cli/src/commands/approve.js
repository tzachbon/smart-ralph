/**
 * Approve command - Approve current phase and continue workflow
 */

import { resolve } from 'path';
import { logger } from '../utils/logger.js';
import { findActiveFeatures } from '../utils/fs.js';
import { StateManager, PHASES } from '../state/manager.js';
import { runPhase, parseTasks } from '../agents/invoker.js';

/**
 * Approve current phase and continue to next
 */
export async function approveCommand(parsed) {
  logger.header();

  const baseDir = resolve(parsed.flags.dir);

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

  // Get the single active feature
  const feature = features[0];
  const stateManager = new StateManager(feature.path);
  await stateManager.load();

  const state = stateManager.state;
  const currentPhase = state.phase;

  logger.info(`Feature: ${state.featureName}`);
  logger.info(`Current phase: ${currentPhase}`);
  logger.info(`Mode: ${state.mode}`);
  logger.newline();

  // Check if already in execution phase
  if (currentPhase === 'execution') {
    logger.info('Already in execution phase');
    await continueExecution(stateManager);
    return;
  }

  // Approve current phase
  await stateManager.approvePhase(currentPhase);
  logger.success(`Phase "${currentPhase}" approved`);

  // Advance to next phase
  const nextPhase = stateManager.getNextPhase();
  if (!nextPhase) {
    logger.info('All planning phases complete, starting execution');
    await stateManager.update({ phase: 'execution' });
    await continueExecution(stateManager);
    return;
  }

  await stateManager.advancePhase();
  await stateManager.incrementIteration();

  logger.info(`Advancing to phase: ${nextPhase}`);
  logger.newline();

  // Run next phase
  if (state.mode === 'auto') {
    await runAutoFromPhase(stateManager, nextPhase);
  } else {
    await runSinglePhase(stateManager, nextPhase);
  }
}

/**
 * Continue from a specific phase in auto mode
 */
async function runAutoFromPhase(stateManager, startPhase) {
  const phaseIndex = PHASES.indexOf(startPhase);
  const phasesToRun = PHASES.slice(phaseIndex).filter((p) => p !== 'execution');

  for (const phase of phasesToRun) {
    if (stateManager.isMaxIterationsReached()) {
      logger.warn('Max iterations reached');
      break;
    }

    const result = await runPhase(phase, stateManager);
    if (!result.success) {
      logger.error(`Phase ${phase} failed`);
      return;
    }

    await stateManager.approvePhase(phase);
    if (stateManager.getNextPhase()) {
      await stateManager.advancePhase();
    }
    await stateManager.incrementIteration();

    logger.success(`Phase ${phase} completed`);
  }

  // Start execution
  await stateManager.update({ phase: 'execution' });
  await continueExecution(stateManager);
}

/**
 * Run a single phase (interactive mode)
 */
async function runSinglePhase(stateManager, phase) {
  const result = await runPhase(phase, stateManager);

  if (!result.success) {
    logger.error(`Phase ${phase} failed`);
    return;
  }

  logger.success(`Phase ${phase} completed`);
  logger.newline();

  // Show next steps
  const nextPhase = stateManager.getNextPhase();
  if (nextPhase) {
    logger.box('Next Steps', `Review the generated ${phase}.md file in:
${stateManager.specPath}

Then run:
  ralph-specum approve    - Approve and continue to ${nextPhase}`);
  } else {
    logger.box('Next Steps', `Review the generated tasks.md file in:
${stateManager.specPath}

Then run:
  ralph-specum approve    - Approve and start execution
  ralph-specum implement  - Skip approval and execute`);
  }
}

/**
 * Continue execution phase
 */
async function continueExecution(stateManager) {
  const { read } = await import('../utils/fs.js');
  const { join } = await import('path');

  const tasksFile = join(stateManager.specPath, 'tasks.md');
  const tasksContent = await read(tasksFile);

  if (!tasksContent) {
    logger.error('Tasks file not found');
    return;
  }

  const tasks = await parseTasks(tasksContent);
  const startIndex = stateManager.state.taskIndex;

  logger.info(`Continuing execution from task ${startIndex + 1}/${tasks.length}`);
  logger.newline();

  for (let i = startIndex; i < tasks.length; i++) {
    const task = tasks[i];

    await stateManager.updateTaskProgress(i, task.name, tasks.length);

    logger.task(i + 1, tasks.length, `${task.id}: ${task.name}`, 'running');

    const result = await runPhase('execution', stateManager);

    if (result.success) {
      logger.task(i + 1, tasks.length, `${task.id}: ${task.name}`, 'completed');
    } else {
      logger.task(i + 1, tasks.length, `${task.id}: ${task.name}`, 'failed');
      logger.error(`Task ${task.id} failed`);
      break;
    }

    if (stateManager.isMaxIterationsReached()) {
      logger.warn('Max iterations reached');
      break;
    }

    await stateManager.incrementIteration();
  }

  // Check completion
  if (stateManager.state.taskIndex >= tasks.length - 1) {
    logger.newline();
    logger.success('All tasks completed!');

    // Cleanup
    await stateManager.cleanup();
  }
}
