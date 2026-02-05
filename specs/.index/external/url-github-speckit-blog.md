---
type: external-spec
generated: true
source-type: url
source-id: https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/
fetched: 2026-02-05T15:28:01+02:00
---

# GitHub's Spec-Driven Development Toolkit

## Source
- **Type**: url
- **URL/ID**: https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/
- **Fetched**: 2026-02-05T15:28:01+02:00

## Summary
GitHub introduced Spec Kit, an open-source toolkit enabling developers to use AI coding agents for specification-driven development. The approach treats specifications as "living, executable artifacts" rather than static documents.

## Key Sections

### Four-Phase Workflow

#### 1. Specify
Focus on user journeys and outcomes rather than technical details. AI generates detailed specification capturing who, what, and how.

#### 2. Plan
Developers provide technical direction—stack, architecture, constraints, compliance. AI produces comprehensive technical implementation plan.

#### 3. Tasks
Specification and plan decomposed into "small, reviewable chunks" for isolated testing and validation.

#### 4. Implement
AI tackles tasks sequentially, with developers reviewing focused changes.

### Key Commands
| Command | Purpose |
|---------|---------|
| `uvx --from git+https://github.com/github/spec-kit.git specify init` | Initialize project |
| `/specify` | Generate specification from description |
| `/plan` | Create technical implementation plan |
| `/tasks` | Break into actionable work items |

### Core Innovation
Provides clarity: "Instead of guessing at your needs, it knows what to build, how to build it, and in what sequence." LLMs excel at pattern completion but struggle with ambiguous requirements.

### Ideal Use Cases
- Greenfield projects (zero-to-one development)
- Feature development in existing systems
- Legacy system modernization

## AI Context
**Keywords**: spec-kit github specify plan tasks implement greenfield feature-development legacy-modernization
**Related components**: plugins/ralph-speckit, plugins/ralph-specum
