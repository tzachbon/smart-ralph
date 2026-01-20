# Contributing to Ralph Speckit

Thank you for your interest in contributing to Ralph Speckit. This document outlines how to contribute effectively.

## Getting Started

### Prerequisites

- Claude Code installed and configured
- Git
- Ralph Wiggum plugin for testing execution features

### Local Development

```bash
# Clone the repository
git clone <repository-url>
cd ralph-speckit

# Test the plugin locally
claude --plugin-dir ./plugins/ralph-speckit

# Run a test workflow
/speckit:constitution Test constitution
/speckit:start test-feature Test goal
```

## Making Changes

### Branch Naming

Use descriptive branch names:
- `feat/add-new-command` - New feature
- `fix/broken-state-handling` - Bug fix
- `docs/update-readme` - Documentation
- `refactor/cleanup-agents` - Code cleanup

### File Locations

| Type | Location |
|------|----------|
| Commands | `.claude/commands/speckit.*.md` |
| Agents | `agents/*.md` |
| Templates | `.specify/templates/*.md` |
| Hooks | `hooks/scripts/*.sh` |
| Schemas | `schemas/*.json` |

### Version Updates

For each change, update the version in BOTH files:
- `plugins/ralph-speckit/.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json` (root)

Use semantic versioning:
- MAJOR: Breaking changes
- MINOR: New features, backward compatible
- PATCH: Bug fixes, documentation

## Code Standards

### Command Files

Commands should include:
```yaml
---
description: Clear description of what the command does
argument-hint: <required-arg> [optional-arg]
allowed-tools: [Read, Write, Edit, Task, Bash]
handoffs:
  - label: Next Step
    agent: speckit.next
    prompt: Continue with...
---
```

### Agent Files

Agents should define:
- Model configuration (use `model: inherit`)
- Clear execution flows
- Mandatory sections with `<mandatory>` tags
- Completion signals (TASK_COMPLETE, VERIFICATION_PASS/FAIL)

### Error Handling

Always include error handling tables:
```markdown
## Error Handling

| Error | Action |
|-------|--------|
| Missing file | Guide user to create it |
| Invalid input | Show usage example |
```

## Testing

### Manual Testing

1. Run through the complete workflow:
   ```bash
   /speckit:constitution [test principles]
   /speckit:start test-feature Test goal
   /speckit:specify
   /speckit:plan
   /speckit:tasks
   /speckit:implement
   ```

2. Test error cases:
   - Missing constitution
   - Invalid feature names
   - Corrupt state files
   - Failed tasks

3. Test parallel execution with `[P]` marked tasks

### Verification

- Ensure all commands complete without errors
- Verify state files are created/cleaned correctly
- Check that gitignore entries are added

## Pull Requests

### Before Submitting

1. Test your changes locally
2. Update version numbers
3. Update CHANGELOG.md
4. Update documentation if needed

### PR Description

Include:
- Summary of changes
- Related issues (if any)
- Testing performed
- Breaking changes (if any)

### Review Process

1. PRs require at least one approval
2. All CI checks must pass
3. Documentation must be updated for new features

## Reporting Issues

### Bug Reports

Include:
- Claude Code version
- Plugin version
- Steps to reproduce
- Expected vs actual behavior
- Relevant log output

### Feature Requests

Include:
- Use case description
- Proposed solution
- Alternatives considered

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Help others learn
- Focus on the technical aspects

## Questions

For questions about contributing:
- Open a GitHub discussion
- Check existing issues for similar questions

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
