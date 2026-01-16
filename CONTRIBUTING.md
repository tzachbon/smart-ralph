# Contributing to Smart Ralph

*"I'm learnding!"* - You, after reading this guide

First off, thanks for wanting to contribute! This project welcomes contributors of all experience levels. Whether you're fixing a typo or adding a whole new agent, your help is appreciated.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Ways to Contribute](#ways-to-contribute)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Pull Request Process](#pull-request-process)
- [Style Guide](#style-guide)
- [Getting Help](#getting-help)

## Code of Conduct

Be kind. Be respectful. Remember that behind every GitHub handle is a real person. We're all here to build something useful together.

## Ways to Contribute

Not all contributions require code:

- **Report bugs** - Found something broken? Open an issue
- **Suggest features** - Have an idea? We want to hear it
- **Improve docs** - Typos, unclear explanations, missing examples
- **Answer questions** - Help others in issues and discussions
- **Write code** - Bug fixes, new features, refactoring

### Good First Issues

Look for issues labeled `good first issue` or `help wanted`. These are specifically chosen for newer contributors.

## Development Setup

### Prerequisites

- [Claude Code](https://claude.ai/code) installed
- Git
- A project to test with

### Local Development

```bash
# Clone the repo
git clone https://github.com/tzachbon/smart-ralph.git
cd smart-ralph

# Test the plugin locally
claude --plugin-dir ./plugins/ralph-specum

# Make changes, restart Claude Code to reload
```

### Project Structure

```
smart-ralph/
├── plugins/
│   └── ralph-specum/
│       ├── .claude-plugin/
│       │   └── plugin.json      # Plugin manifest
│       ├── agents/              # Sub-agent definitions
│       ├── commands/            # Slash command implementations
│       ├── hooks/               # Stop watcher (logging only)
│       ├── templates/           # Spec file templates
│       └── schemas/             # JSON schemas for validation
└── README.md
```

### Testing Changes

1. Make your changes
2. Restart Claude Code with `--plugin-dir` pointing to your local copy
3. Run through the workflow: `/ralph-specum:start test-feature Some test goal`
4. Verify each phase works as expected

## Making Changes

### Branch Naming

```
feature/description    # New features
fix/description        # Bug fixes
docs/description       # Documentation only
refactor/description   # Code refactoring
```

### Commit Messages

Keep them short and descriptive:

```
Good:
- Add retry logic to spec-executor
- Fix state cleanup on cancel
- Update installation docs

Bad:
- Fixed stuff
- WIP
- asdfasdf
```

## Pull Request Process

1. **Fork** the repo and create your branch from `main`
2. **Make** your changes
3. **Test** locally with Claude Code
4. **Update** documentation if needed
5. **Submit** PR with clear description of changes

### PR Description Template

```markdown
## What

Brief description of changes

## Why

Why this change is needed

## Testing

How you tested it
```

### Review Process

- PRs require at least one approval
- CI checks must pass
- Maintainers may request changes
- Be patient, we review as quickly as we can

## Style Guide

### General Principles

- Keep it simple
- Prefer clarity over cleverness
- Match existing patterns in the codebase

### Agent Definitions

- Use clear, action-oriented descriptions
- Include examples where helpful
- Keep system prompts focused

### Commands

- Command names should be verb-based (`start`, `cancel`, `status`)
- Include help text for all commands
- Handle errors gracefully with useful messages

### File Naming

- Use kebab-case for files: `spec-executor.md`, `task-planner.md`
- Use descriptive names that indicate purpose

## Getting Help

Stuck? Have questions?

- **Issues** - Open an issue with the `question` label
- **Discussions** - Use GitHub Discussions for general questions

## Recognition

Contributors are recognized in release notes. Significant contributors may be invited as collaborators.

---

<div align="center">

*"My cat's breath smells like cat food."*

Thanks for contributing!

</div>
