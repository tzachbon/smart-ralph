export class RalphError extends Error {
  constructor(
    message: string,
    public readonly suggestion: string,
    public readonly exitCode: number = 1
  ) {
    super(message);
    this.name = 'RalphError';
  }
}

export class ConfigError extends RalphError {
  constructor(message: string) {
    super(message, 'Run "ralph init" to set up configuration.', 2);
    this.name = 'ConfigError';
  }
}

export class SpecNotFoundError extends RalphError {
  constructor(name: string) {
    super(
      `Spec "${name}" not found.`,
      'Run "ralph new <name> <goal>" to create a spec, or "ralph status" to list existing specs.'
    );
    this.name = 'SpecNotFoundError';
  }
}

export class ProviderError extends RalphError {
  constructor(message: string, provider: string) {
    super(message, `Check your ${provider} API key and model settings with "ralph doctor".`);
    this.name = 'ProviderError';
  }
}

export class TaskFailedError extends RalphError {
  constructor(taskId: string, attempts: number, lastError: string) {
    super(
      `Task ${taskId} failed after ${attempts} attempts: ${lastError}`,
      'Fix the issue manually, then re-run "ralph run" to resume from this task.',
      1
    );
    this.name = 'TaskFailedError';
  }
}
