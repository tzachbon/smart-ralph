# Ralph Specum v5 Architecture

Ralph Specum ships as two native, self-contained plugins. They share a canonical specification contract but not a generic user experience.

## Shared specification core

The shared core owns artifact templates, schemas, phase rules, approval rules, verification rules, validators, and conformance fixtures.

It is a build-time source of truth. Users do not install it, and installed plugins do not load files from it. A standard-library sync command copies canonical assets into both plugin packages. CI verifies that committed package assets match the core.

The core does not generate platform orchestration prompts. Claude and Codex instructions remain native and hand-written.

## Durable workflow contract

- `research.md`, `requirements.md`, `design.md`, and `tasks.md` are canonical artifacts.
- `tasks.md` checkboxes are authoritative task completion state.
- Tracked `progress.md` records the current phase, approval frontier, durable learnings, blockers, and next step.
- `.current-spec` is a local ignored pointer.
- Adapter runtime state is disposable and must be reconstructable from the artifacts.

## Claude adapter

Claude exposes slash commands, Claude agents, teams, approval prompts, and hook-driven autonomous execution. Claude runtime state is local. All hook paths are resolved from `${CLAUDE_PLUGIN_ROOT}` and the supplied workspace root.

## Codex adapter

Codex exposes a primary skill and explicit phase skills. Native subagents perform bounded work. Substantive phases must delegate and carry a semantic reasoning tier: light for task decomposition, medium for research, requirements, and normal implementation, and strongest for design and broad triage. Codex maps these tiers to native model or effort controls when the active spawn surface exposes them. Otherwise the tier remains an explicit work-packet requirement because v5 does not require custom agent configuration. Native `/goal` owns long-running continuation only after an explicit autonomous request. The Codex package has no Stop hook and requires no custom agent configuration.

Claude pins these phase roles through native plugin-agent frontmatter: Haiku for task planning and mechanical QA, Sonnet for research, requirements, and normal execution, and Opus for architecture and broad triage. Research and requirements may escalate a specific invocation from Sonnet to Opus for security boundaries, irreversible migrations, novel cross-domain decisions, or materially conflicting evidence.

## Ownership and parallelism

The root coordinator is the only owner of shared workflow state and Git.

- Up to three read-only subagents may run concurrently.
- One write subagent runs at a time by default.
- Parallel writes require disjoint file ownership and isolated worktrees.
- Each task receives at most three attempts.
- Commits occur after verified logical batches.

Subagents return evidence and changed-file summaries. They never edit `tasks.md`, `progress.md`, runtime state, or the shared Git index.
