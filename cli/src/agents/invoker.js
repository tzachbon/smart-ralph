/**
 * Agent invocation system for ralph-specum CLI
 * Orchestrates calling Claude Code with agent-specific prompts
 */

import { $ } from 'bun';
import { read, getCliRoot, getProjectRoot, getSpecFiles } from '../utils/fs.js';
import { join } from 'path';
import { logger } from '../utils/logger.js';

const AGENT_FILES = {
  research: 'research-analyst.md',
  requirements: 'product-manager.md',
  design: 'architect-reviewer.md',
  tasks: 'task-planner.md',
  execution: 'spec-executor.md',
};

const TEMPLATE_FILES = {
  research: 'research.md',
  requirements: 'requirements.md',
  design: 'design.md',
  tasks: 'tasks.md',
  progress: 'progress.md',
};

/**
 * Load an agent prompt from the agents directory
 */
export async function loadAgentPrompt(agentName) {
  const fileName = AGENT_FILES[agentName];
  if (!fileName) {
    throw new Error(`Unknown agent: ${agentName}`);
  }

  // Try project root first (when used as plugin), then CLI root
  const projectPath = join(getProjectRoot(), 'agents', fileName);
  let content = await read(projectPath);

  if (!content) {
    const cliPath = join(getCliRoot(), '..', 'agents', fileName);
    content = await read(cliPath);
  }

  if (!content) {
    throw new Error(`Agent prompt not found: ${agentName}`);
  }

  return content;
}

/**
 * Load a template from the templates directory
 */
export async function loadTemplate(templateName) {
  const fileName = TEMPLATE_FILES[templateName];
  if (!fileName) {
    throw new Error(`Unknown template: ${templateName}`);
  }

  const projectPath = join(getProjectRoot(), 'templates', fileName);
  let content = await read(projectPath);

  if (!content) {
    const cliPath = join(getCliRoot(), '..', 'templates', fileName);
    content = await read(cliPath);
  }

  if (!content) {
    throw new Error(`Template not found: ${templateName}`);
  }

  return content;
}

/**
 * Build context for agent invocation
 */
export async function buildAgentContext(phase, stateManager) {
  const state = stateManager.state;
  const files = getSpecFiles(stateManager.specPath);

  const context = {
    goal: state.goal,
    featureName: state.featureName,
    specPath: state.specPath,
    phase,
    iteration: state.iteration,
    mode: state.mode,
  };

  // Load progress file (always included)
  const progress = await read(files.progress);
  if (progress) {
    context.progress = progress;
  }

  // Load phase-specific context
  switch (phase) {
    case 'requirements':
      context.research = await read(files.research);
      break;
    case 'design':
      context.research = await read(files.research);
      context.requirements = await read(files.requirements);
      break;
    case 'tasks':
      context.requirements = await read(files.requirements);
      context.design = await read(files.design);
      break;
    case 'execution':
      context.tasks = await read(files.tasks);
      context.design = await read(files.design);
      context.taskIndex = state.taskIndex;
      context.totalTasks = state.totalTasks;
      context.currentTaskName = state.currentTaskName;
      break;
  }

  return context;
}

/**
 * Build the full prompt for an agent invocation
 */
export async function buildPrompt(phase, context) {
  const agentPrompt = await loadAgentPrompt(phase);
  const template = await loadTemplate(phase === 'execution' ? 'tasks' : phase);

  let prompt = `# Agent Context

## Goal
${context.goal}

## Feature Name
${context.featureName}

## Spec Directory
${context.specPath}

## Mode
${context.mode}

## Iteration
${context.iteration}

`;

  // Add progress file
  if (context.progress) {
    prompt += `## Progress (ALWAYS READ THIS FIRST)
${context.progress}

`;
  }

  // Add phase-specific context
  if (context.research) {
    prompt += `## Research Findings
${context.research}

`;
  }

  if (context.requirements) {
    prompt += `## Requirements
${context.requirements}

`;
  }

  if (context.design) {
    prompt += `## Design
${context.design}

`;
  }

  if (context.tasks && phase === 'execution') {
    prompt += `## Tasks
${context.tasks}

## Current Task
Index: ${context.taskIndex}
Name: ${context.currentTaskName}
Total: ${context.totalTasks}

`;
  }

  // Add template reference
  prompt += `## Output Template
${template}

`;

  // Add agent instructions
  prompt += `## Agent Instructions
${agentPrompt}
`;

  return prompt;
}

/**
 * Invoke Claude Code with a prompt
 * This spawns claude-code CLI with the constructed prompt
 */
export async function invokeClaudeCode(prompt, options = {}) {
  const { cwd = process.cwd(), interactive = false } = options;

  try {
    // Write prompt to temp file to avoid shell escaping issues
    const tempFile = `/tmp/ralph-specum-prompt-${Date.now()}.md`;
    await Bun.write(tempFile, prompt);

    // Build claude command
    const args = ['claude', '--print'];

    if (!interactive) {
      args.push('--no-input');
    }

    // Execute claude with the prompt
    const result = await $`cat ${tempFile} | ${args}`.cwd(cwd);

    // Clean up temp file
    await $`rm ${tempFile}`.quiet();

    return {
      success: true,
      output: result.stdout.toString(),
    };
  } catch (error) {
    return {
      success: false,
      error: error.message,
      output: error.stdout?.toString() || '',
    };
  }
}

/**
 * Run an agent phase
 */
export async function runPhase(phase, stateManager, options = {}) {
  logger.phase(phase, 'starting');

  // Build context and prompt
  const context = await buildAgentContext(phase, stateManager);
  const prompt = await buildPrompt(phase, context);

  logger.debug(`Prompt length: ${prompt.length} characters`);

  // Invoke Claude Code
  logger.phase(phase, 'running');
  const result = await invokeClaudeCode(prompt, {
    cwd: stateManager.specPath,
    interactive: stateManager.state.mode === 'interactive',
  });

  if (result.success) {
    logger.phase(phase, 'completed');
    await stateManager.updateProgress({ phase });
  } else {
    logger.phase(phase, 'failed');
    logger.error(result.error);
  }

  return result;
}

/**
 * Parse tasks from tasks.md file
 */
export async function parseTasks(tasksContent) {
  const tasks = [];
  const lines = tasksContent.split('\n');

  let currentTask = null;
  let currentSection = null;

  for (const line of lines) {
    // Task header: ### TASK-XX: Task Name
    const taskMatch = line.match(/^###\s+(TASK-\d+):\s*(.+)/);
    if (taskMatch) {
      if (currentTask) {
        tasks.push(currentTask);
      }
      currentTask = {
        id: taskMatch[1],
        name: taskMatch[2],
        phase: null,
        do: '',
        files: [],
        doneWhen: '',
        verify: '',
        commit: '',
      };
      continue;
    }

    // Phase header: ## Phase X:
    const phaseMatch = line.match(/^##\s+Phase\s+(\d+)/i);
    if (phaseMatch) {
      currentSection = `phase-${phaseMatch[1]}`;
      continue;
    }

    // Task sections
    if (currentTask) {
      if (line.startsWith('**Do:**')) {
        currentSection = 'do';
        continue;
      }
      if (line.startsWith('**Files:**')) {
        currentSection = 'files';
        continue;
      }
      if (line.startsWith('**Done when:**')) {
        currentSection = 'doneWhen';
        continue;
      }
      if (line.startsWith('**Verify:**')) {
        currentSection = 'verify';
        continue;
      }
      if (line.startsWith('**Commit:**')) {
        currentSection = 'commit';
        continue;
      }

      // Add content to current section
      if (currentSection === 'do') {
        currentTask.do += line + '\n';
      } else if (currentSection === 'files') {
        const fileMatch = line.match(/^[-*]\s*`?([^`]+)`?/);
        if (fileMatch) {
          currentTask.files.push(fileMatch[1].trim());
        }
      } else if (currentSection === 'doneWhen') {
        currentTask.doneWhen += line + '\n';
      } else if (currentSection === 'verify') {
        const verifyMatch = line.match(/```[\w]*\n?([\s\S]*?)```|`([^`]+)`/);
        if (verifyMatch) {
          currentTask.verify = (verifyMatch[1] || verifyMatch[2]).trim();
        }
      } else if (currentSection === 'commit') {
        const commitMatch = line.match(/`([^`]+)`/);
        if (commitMatch) {
          currentTask.commit = commitMatch[1];
        }
      }
    }
  }

  if (currentTask) {
    tasks.push(currentTask);
  }

  return tasks;
}

export { AGENT_FILES, TEMPLATE_FILES };
