/**
 * Status command - Show current workflow status
 */

import { resolve, join } from 'path';
import { logger, COLORS, SYMBOLS } from '../utils/logger.js';
import { findActiveFeatures, read, exists } from '../utils/fs.js';
import { StateManager, PHASES } from '../state/manager.js';
import { getCurrentBranch, hasUncommittedChanges } from '../utils/git.js';

/**
 * Display current workflow status
 */
export async function statusCommand(parsed) {
  logger.header();

  const baseDir = resolve(parsed.flags.dir);

  // Find active features
  const features = await findActiveFeatures(baseDir);

  if (features.length === 0) {
    logger.info('No active workflows found');
    logger.newline();
    logger.info('Start a new workflow with:');
    logger.log('  ralph-specum "your goal description"');
    return;
  }

  // Show status for each feature
  for (const feature of features) {
    await showFeatureStatus(feature, parsed.flags.verbose);
    if (features.length > 1) {
      logger.divider();
    }
  }

  // Show git status
  logger.newline();
  await showGitStatus();
}

/**
 * Show status for a single feature
 */
async function showFeatureStatus(feature, verbose = false) {
  const stateManager = new StateManager(feature.path);
  await stateManager.load();

  const state = stateManager.state;

  // Header
  logger.box(state.featureName, `Goal: ${state.goal}`);
  logger.newline();

  // Phase progress
  logger.log('Phases:');
  for (const phase of PHASES) {
    if (phase === 'execution') continue;

    let status = 'pending';
    let symbol = SYMBOLS.dot;
    let color = 'gray';

    if (state.phaseApprovals[phase]) {
      status = 'approved';
      symbol = SYMBOLS.success;
      color = 'green';
    } else if (state.phase === phase) {
      status = 'current';
      symbol = SYMBOLS.arrow;
      color = 'yellow';
    }

    // Check if file exists
    const filePath = join(feature.path, `${phase}.md`);
    const fileExists = await exists(filePath);
    const fileStatus = fileExists ? '(file exists)' : '';

    console.log(
      `  ${colorize(color, symbol)} ${phase.padEnd(15)} ${colorize('dim', status.padEnd(10))} ${colorize('dim', fileStatus)}`
    );
  }

  // Execution status
  if (state.phase === 'execution') {
    logger.newline();
    logger.log('Execution:');
    logger.log(`  ${colorize('yellow', SYMBOLS.arrow)} Task ${state.taskIndex + 1}/${state.totalTasks}`);
    if (state.currentTaskName) {
      logger.log(`    ${colorize('dim', state.currentTaskName)}`);
    }
  }

  // Stats
  logger.newline();
  logger.log('Stats:');
  logger.log(`  Mode:       ${state.mode}`);
  logger.log(`  Iteration:  ${state.iteration}/${state.maxIterations}`);
  logger.log(`  Started:    ${formatDate(state.createdAt)}`);
  logger.log(`  Updated:    ${formatDate(state.updatedAt)}`);

  // Verbose: show progress file
  if (verbose) {
    const progress = await read(join(feature.path, '.ralph-progress.md'));
    if (progress) {
      logger.newline();
      logger.divider();
      logger.log('Progress File:');
      logger.newline();
      console.log(progress);
    }
  }
}

/**
 * Show git status
 */
async function showGitStatus() {
  try {
    const branch = await getCurrentBranch();
    const hasChanges = await hasUncommittedChanges();

    logger.log('Git:');
    logger.log(`  Branch: ${branch}`);
    logger.log(`  Status: ${hasChanges ? 'uncommitted changes' : 'clean'}`);
  } catch {
    logger.log('Git: not a repository');
  }
}

/**
 * Format ISO date to readable string
 */
function formatDate(isoString) {
  if (!isoString) return 'unknown';
  const date = new Date(isoString);
  return date.toLocaleString();
}

/**
 * Helper to colorize text
 */
function colorize(color, text) {
  const codes = {
    reset: '\x1b[0m',
    dim: '\x1b[2m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    gray: '\x1b[90m',
  };
  return `${codes[color] || ''}${text}${codes.reset}`;
}
