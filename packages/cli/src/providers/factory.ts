import type { Provider } from './interface.js';
import type { RalphConfig } from '../types/index.js';
import { ProviderError } from '../lib/errors.js';
import { ClaudeProvider } from './claude.js';

export function createProvider(config: RalphConfig): Provider {
  switch (config.provider) {
    case 'claude':
      return new ClaudeProvider(config);
    default:
      throw new ProviderError(
        `Unknown provider: "${config.provider}"`,
        config.provider
      );
  }
}
