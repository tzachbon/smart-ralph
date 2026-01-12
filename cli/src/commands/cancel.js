/**
 * Cancel command - Cancel and cleanup the current workflow
 */

import { resolve } from 'path';
import { logger } from '../utils/logger.js';
import { findActiveFeatures, remove } from '../utils/fs.js';
import { StateManager } from '../state/manager.js';

/**
 * Cancel the current workflow and cleanup state files
 */
export async function cancelCommand(parsed) {
  logger.header();

  const baseDir = resolve(parsed.flags.dir);
  const keepSpecs = parsed.flags['keep-specs'] || false;

  // Find active features
  const features = await findActiveFeatures(baseDir);

  if (features.length === 0) {
    logger.info('No active workflow found');
    return;
  }

  if (features.length > 1) {
    logger.info('Multiple active workflows found:');
    features.forEach((f, i) => {
      logger.log(`  ${i + 1}. ${f.name} (${f.state.phase})`);
    });

    if (parsed.flags.all) {
      logger.newline();
      logger.warn('Canceling ALL workflows...');

      for (const feature of features) {
        await cancelFeature(feature, keepSpecs);
      }

      logger.newline();
      logger.success(`Canceled ${features.length} workflows`);
      return;
    }

    logger.info('Use --all to cancel all, or --dir to specify one');
    return;
  }

  // Cancel single feature
  const feature = features[0];
  await cancelFeature(feature, keepSpecs);
}

/**
 * Cancel a single feature workflow
 */
async function cancelFeature(feature, keepSpecs) {
  const stateManager = new StateManager(feature.path);
  await stateManager.load();

  const state = stateManager.state;

  logger.info(`Canceling workflow: ${state.featureName}`);
  logger.info(`  Phase: ${state.phase}`);
  logger.info(`  Iteration: ${state.iteration}`);
  logger.info(`  Tasks: ${state.taskIndex}/${state.totalTasks}`);
  logger.newline();

  // Record cancellation in progress before cleanup
  await stateManager.addLearning(`Workflow canceled at phase "${state.phase}"`);

  // Clean up state files
  await stateManager.cleanup();
  logger.success('Removed state files');

  if (!keepSpecs) {
    // Optionally remove spec files
    const { join } = await import('path');

    const specFiles = ['research.md', 'requirements.md', 'design.md', 'tasks.md'];

    for (const file of specFiles) {
      const removed = await remove(join(feature.path, file));
      if (removed) {
        logger.info(`  Removed ${file}`);
      }
    }
  } else {
    logger.info('Spec files preserved (--keep-specs)');
  }

  logger.newline();
  logger.success(`Workflow "${state.featureName}" canceled`);
}
