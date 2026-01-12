/**
 * State management for ralph-specum CLI
 * Handles .ralph-state.json and .ralph-progress.md
 */

import { readJson, writeJson, read, write, remove, exists, getSpecFiles } from '../utils/fs.js';
import { join, resolve } from 'path';

const PHASES = ['research', 'requirements', 'design', 'tasks', 'execution'];

/**
 * Default state structure
 */
function createDefaultState(options = {}) {
  return {
    mode: options.mode || 'interactive',
    goal: options.goal || '',
    featureName: options.featureName || '',
    specPath: options.specPath || '',
    phase: 'research',
    taskIndex: 0,
    totalTasks: 0,
    currentTaskName: '',
    phaseApprovals: {
      research: false,
      requirements: false,
      design: false,
      tasks: false,
    },
    iteration: 1,
    maxIterations: options.maxIterations || 10,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
}

/**
 * State manager class
 */
export class StateManager {
  constructor(specPath) {
    this.specPath = resolve(specPath);
    this.files = getSpecFiles(this.specPath);
    this.state = null;
  }

  /**
   * Initialize a new state
   */
  async initialize(options) {
    this.state = createDefaultState({
      ...options,
      specPath: this.specPath,
    });
    await this.save();
    await this.initializeProgress(options.goal);
    return this.state;
  }

  /**
   * Load existing state
   */
  async load() {
    this.state = await readJson(this.files.state);
    return this.state;
  }

  /**
   * Save current state
   */
  async save() {
    if (!this.state) {
      throw new Error('No state to save');
    }
    this.state.updatedAt = new Date().toISOString();
    await writeJson(this.files.state, this.state);
  }

  /**
   * Update state properties
   */
  async update(updates) {
    if (!this.state) {
      await this.load();
    }
    Object.assign(this.state, updates);
    await this.save();
    return this.state;
  }

  /**
   * Check if state exists
   */
  async exists() {
    return await exists(this.files.state);
  }

  /**
   * Get current phase
   */
  getPhase() {
    return this.state?.phase || 'research';
  }

  /**
   * Get next phase
   */
  getNextPhase() {
    const currentIndex = PHASES.indexOf(this.getPhase());
    if (currentIndex < 0 || currentIndex >= PHASES.length - 1) {
      return null;
    }
    return PHASES[currentIndex + 1];
  }

  /**
   * Advance to next phase
   */
  async advancePhase() {
    const nextPhase = this.getNextPhase();
    if (!nextPhase) {
      throw new Error('Already at final phase');
    }
    await this.update({ phase: nextPhase });
    return nextPhase;
  }

  /**
   * Approve current phase
   */
  async approvePhase(phase = null) {
    const targetPhase = phase || this.getPhase();
    if (!this.state.phaseApprovals.hasOwnProperty(targetPhase)) {
      throw new Error(`Invalid phase for approval: ${targetPhase}`);
    }
    this.state.phaseApprovals[targetPhase] = true;
    await this.save();
  }

  /**
   * Check if phase is approved
   */
  isPhaseApproved(phase = null) {
    const targetPhase = phase || this.getPhase();
    return this.state?.phaseApprovals?.[targetPhase] || false;
  }

  /**
   * Increment iteration counter
   */
  async incrementIteration() {
    this.state.iteration = (this.state.iteration || 1) + 1;
    await this.save();
    return this.state.iteration;
  }

  /**
   * Check if max iterations reached
   */
  isMaxIterationsReached() {
    return this.state.iteration >= this.state.maxIterations;
  }

  /**
   * Update task progress
   */
  async updateTaskProgress(taskIndex, taskName = '', totalTasks = null) {
    const updates = {
      taskIndex,
      currentTaskName: taskName,
    };
    if (totalTasks !== null) {
      updates.totalTasks = totalTasks;
    }
    await this.update(updates);
  }

  /**
   * Clean up state files (on completion or cancel)
   */
  async cleanup() {
    await remove(this.files.state);
    await remove(this.files.progress);
  }

  /**
   * Initialize progress file
   */
  async initializeProgress(goal) {
    const content = `# Ralph Specum Progress

## Goal
${goal}

## Feature
${this.state.featureName}

## Current Status
- **Phase**: ${this.state.phase}
- **Mode**: ${this.state.mode}
- **Started**: ${this.state.createdAt}

## Learnings
<!-- This section survives context compaction. Add important learnings here. -->

## Decisions
<!-- Record key decisions made during development. -->

## Blockers
<!-- Document any blockers encountered. -->

## Notes
<!-- Additional notes and observations. -->
`;
    await write(this.files.progress, content);
  }

  /**
   * Update progress file with current status
   */
  async updateProgress(updates = {}) {
    let content = await read(this.files.progress);
    if (!content) {
      await this.initializeProgress(this.state.goal);
      content = await read(this.files.progress);
    }

    // Update status section
    const statusSection = `## Current Status
- **Phase**: ${updates.phase || this.state.phase}
- **Mode**: ${this.state.mode}
- **Iteration**: ${this.state.iteration}/${this.state.maxIterations}
- **Tasks**: ${this.state.taskIndex}/${this.state.totalTasks}
- **Updated**: ${new Date().toISOString()}`;

    content = content.replace(/## Current Status[\s\S]*?(?=\n## |$)/, statusSection + '\n\n');

    await write(this.files.progress, content);
  }

  /**
   * Add a learning to progress file
   */
  async addLearning(learning) {
    let content = await read(this.files.progress);
    if (!content) return;

    const timestamp = new Date().toISOString().slice(0, 16).replace('T', ' ');
    const newLearning = `- [${timestamp}] ${learning}`;

    content = content.replace(
      /## Learnings\n<!-- This section survives context compaction\. Add important learnings here\. -->/,
      `## Learnings\n<!-- This section survives context compaction. Add important learnings here. -->\n${newLearning}`
    );

    await write(this.files.progress, content);
  }

  /**
   * Add a decision to progress file
   */
  async addDecision(decision) {
    let content = await read(this.files.progress);
    if (!content) return;

    const timestamp = new Date().toISOString().slice(0, 16).replace('T', ' ');
    const newDecision = `- [${timestamp}] ${decision}`;

    content = content.replace(
      /## Decisions\n<!-- Record key decisions made during development\. -->/,
      `## Decisions\n<!-- Record key decisions made during development. -->\n${newDecision}`
    );

    await write(this.files.progress, content);
  }

  /**
   * Get progress content
   */
  async getProgress() {
    return await read(this.files.progress);
  }
}

/**
 * Load or create state manager for a spec path
 */
export async function getStateManager(specPath) {
  const manager = new StateManager(specPath);
  if (await manager.exists()) {
    await manager.load();
  }
  return manager;
}

export { PHASES };
