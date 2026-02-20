# Research Dispatch Template

> Used by: research.md
> Placeholders: {SPEC_NAME}, {GOAL}, {TOPIC}, {TOPIC_SLUG}, {BASE_PATH}, {EXISTING_SPECS}, {CODEBASE_CONTEXT}

## Task Tool Parameters

- **subagent_type:** `ralph-specum:research-analyst`
- **description:** `Research {TOPIC} for {SPEC_NAME}`

## Prompt

Research the topic "{TOPIC}" in the context of the following goal:

**Goal:** {GOAL}

## Existing Specs

{EXISTING_SPECS}

## Codebase Context

{CODEBASE_CONTEXT}

## Instructions

1. Search the codebase for existing patterns related to this topic
2. Search the web for relevant documentation, best practices, and examples
3. Identify risks, dependencies, and constraints
4. Check compatibility with existing architecture
5. Note any decisions that need user input

## Output Format

Write your findings to a temporary file `{BASE_PATH}/.research-{TOPIC_SLUG}.md` with these sections:

### Key Findings
(Bulleted list of important discoveries)

### Existing Patterns
(What the codebase already does related to this topic)

### External Resources
(Links and summaries from web research)

### Risks & Dependencies
(What could go wrong, what this depends on)

### Open Questions
(Decisions that need user input)
