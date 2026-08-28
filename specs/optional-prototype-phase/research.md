---
spec: optional-prototype-phase
phase: research
created: 2026-08-27T15:15:00Z
---

# Research: optional prototype phase

## In short

Prototype shipped as an optional overlay that leaves the main planning phase unchanged:

```text
research -> requirements -> [prototype overlay] -> design -> tasks -> execution
```

The implementation gives Claude and Codex a command or helper skill, a builder, immutable records under `<basePath>/prototypes/`, and concurrent live entries under `activePrototypes`. The main state value remains `research`, `requirements`, `design`, `tasks`, or `execution`. Normal mode may suggest an overlay after research or requirements and accepts direct invocation from every main phase. Quick mode runs one bounded, question-free request after requirements and continues to design.

Retained source stays on an isolated local branch outside main. Eligible ephemeral source may use a sibling worktree or scratch directory and is deleted only after reviewed evidence and an immutable cleanup receipt exist. The active feature branch receives terminal records and later production code that applies approved evidence.

The implementation kept the main phase enum unchanged and added `phase: prototype` only to prototype-record frontmatter. At the research baseline, the Claude plugin and marketplace were `4.10.0` while the Codex plugin was `4.10.1`; the release work later aligned all three entries at `4.11.0`.

## Baseline workflow before implementation

### Ralph had one linear planning path

The documented phase order is `research -> requirements -> design -> tasks -> implement`. Each planning phase ends with `awaitingApproval: true`, and quick mode skips interviews, walkthroughs, and approval stops. `plugins/ralph-specum/skills/spec-workflow/references/phase-transitions.md:5-9`, `plugins/ralph-specum/skills/spec-workflow/references/phase-transitions.md:88-104`.

The phase commands share the same coordinator shape: gather context, interview, delegate, review in quick mode, walk through the artifact, merge state, optionally commit the artifact, and stop. Research shows the full sequence and state merge at `plugins/ralph-specum/commands/research.md:11-21` and `plugins/ralph-specum/commands/research.md:164-197`. Requirements, design, and tasks repeat it at `plugins/ralph-specum/commands/requirements.md:11-20`, `plugins/ralph-specum/commands/design.md:11-20`, and `plugins/ralph-specum/commands/tasks.md:11-20`.

The next command implicitly approves the preceding artifact. Requirements says that it approves research, design says that it approves requirements, and tasks says that it approves design. `plugins/ralph-specum/commands/requirements.md:7-9`, `plugins/ralph-specum/commands/design.md:7-9`, `plugins/ralph-specum/commands/tasks.md:7-9`.

### Quick mode names every phase in one fixed sequence

Quick mode creates state with `phase: "research"`, runs research, requirements, design, and tasks, then changes the state to `execution`. `plugins/ralph-specum/references/quick-mode.md:60-78`, `plugins/ralph-specum/references/quick-mode.md:111-120`. The start command summarizes the same four-artifact sequence and requires a native task for each phase. `plugins/ralph-specum/commands/start.md:253-259`.

The shipped quick sequence inserts one overlay request after requirements and before design. The Claude stop hook still treats every phase other than `execution` as planning work, and the Codex hook acts only during execution, because the overlay never sets the main phase to `prototype`. `plugins/ralph-specum/hooks/scripts/stop-watcher.sh:159-184`, `plugins/ralph-specum-codex/hooks/stop-watcher.sh:38-47`.

### State readers are partly generic and partly enumerated

The state writers can store a new `phase` value without a new state helper. The Codex merge script loads the existing object, updates supplied keys, and replaces the file atomically. `plugins/ralph-specum-codex/scripts/merge_state.py:46-79`.

Both schema copies enumerate `research`, `requirements`, `design`, `tasks`, and `execution` as the documented phase values. `plugins/ralph-specum/schemas/spec.schema.json:27-30`, `plugins/ralph-specum-codex/schemas/spec.schema.json:27-30`. Both copies also define frontmatter contracts only for the four current artifacts. `plugins/ralph-specum/schemas/spec.schema.json:296-330`. The Codex schema test checks only that the file exists and parses as JSON; it does not prove live runtime validation of phase values. `tests/codex-plugin.bats:164-170`.

Session and index fallbacks also encode the current order. Session start maps completed phases to their next commands and infers phase from the highest present artifact. `plugins/ralph-specum/hooks/scripts/load-spec-context.sh:71-99`. The index updater uses the same file-based inference in two places. `plugins/ralph-specum/hooks/scripts/update-spec-index.sh:93-118`, `plugins/ralph-specum/hooks/scripts/update-spec-index.sh:226-258`.

### Codex parity is an explicit package contract

The Codex workflow maps every Claude command to a primary or helper skill and gives each phase a named sub-agent. `plugins/ralph-specum-codex/references/workflow.md:3-20`, `plugins/ralph-specum-codex/references/workflow.md:22-43`. The primary skill repeats the routing table and prohibits coordinators from writing phase artifacts themselves. `plugins/ralph-specum-codex/skills/ralph-specum/SKILL.md:27-52`.

The Codex tests compare the Claude command set with installed helper skills. A new Claude command without a matching Codex helper will fail `tests/codex-platform.bats:185-204`. Other tests hard-code 15 skills, 9 agent templates, 10 templates, and 3 scripts. `tests/codex-plugin.bats:6-42`, `tests/codex-plugin.bats:66-107`, `tests/codex-plugin.bats:141-162`.

## The prototype source requires two different build paths

The supplied skill defines a prototype as throwaway code that answers one question. It selects logic for state-model questions and UI for look-and-layout questions. If nobody can answer an ambiguity, it uses nearby backend or page code to choose and records the assumption. `/Users/zachbonfil/.agents/skills/prototype/SKILL.md:8-17`.

Rules shared by both paths are concrete: put clearly marked throwaway code near the target module or page, make it trivial to run, keep state in memory, skip tests and polish, show relevant state, and capture the question and verdict on a branch outside main. `/Users/zachbonfil/.agents/skills/prototype/SKILL.md:19-26`.

### Logic prototypes are one interactive HTML file

A logic prototype is one self-contained HTML file with no server or bundler. It contains a pure reducer, state machine, or small set of functions behind a thin page. `/Users/zachbonfil/.agents/skills/prototype/LOGIC.md:18-37`. The page shows readable current state, free-play actions, and repeatable guided cases that cover a normal path, an awkward edge case, and an illegal action. `/Users/zachbonfil/.agents/skills/prototype/LOGIC.md:39-50`.

The HTML shell stays throwaway. Only a validated logic decision may move into production code, and production work must add its normal tests and hardening. `/Users/zachbonfil/.agents/skills/prototype/LOGIC.md:56-67`.

### UI prototypes are three structural variants on one route

A UI prototype should use an existing route when possible. The route keeps its data, parameters, and authentication, while `?variant=` selects only the rendered subtree. A new prototype route is the fallback when no host page exists. `/Users/zachbonfil/.agents/skills/prototype/UI.md:14-32`.

The default is three variants. They must differ in layout, information hierarchy, and primary action, not color alone. `/Users/zachbonfil/.agents/skills/prototype/UI.md:34-54`. A dev-only floating switcher updates the URL, supports arrow keys, and stays out of production builds. `/Users/zachbonfil/.agents/skills/prototype/UI.md:77-92`.

The winning idea must be rewritten under production constraints. Losing variants and the switcher remain only on the throwaway branch. `/Users/zachbonfil/.agents/skills/prototype/UI.md:98-112`.

## Feasible placements

| Option | Behavior | Positive | Negative |
|---|---|---|---|
| A. Dedicated phase after requirements | `requirements -> [prototype] -> design`; users invoke it directly | One question has enough product context, design can absorb the verdict, interrupted runs need one state value | Requires a new artifact, agent, command or helper, schema entries, docs, and tests |
| B. Gate after several artifact walkthroughs | Offer "run prototype" after research, requirements, and design without changing phase state | Fewer new disk artifacts and no new phase enum | No canonical verdict, ambiguous resume point, prototypes can validate three different upstream snapshots |
| C. Generic side path callable from any planning phase | Prototype can interrupt research, requirements, design, or tasks | Maximum flexibility | Needs origin-phase tracking, stale-artifact rules, more transition branches, and more recovery tests |

## The dedicated-phase recommendation was superseded

The initial research recommended option A. The approved implementation superseded that model with an overlay derived from option C: normal mode can invoke prototype work from any main phase, while quick mode has one fixed post-requirements call site.

Requirements are the first artifact that can state the user-visible behavior and acceptance boundary. Design is the first artifact that should commit the implementation architecture. A prototype between them tests the risky state model or UI choice before the design records it.

This placement also preserves a simple skip path. The design command already requires only `requirements.md`. `plugins/ralph-specum/commands/design.md:22-29`. Leaving that prerequisite intact means omission of `prototype` changes nothing for existing specs.

The implementation keeps one official quick-mode slot but permits normal direct invocation from research, requirements, design, tasks, or execution. Dependency selection, stale-artifact gates, return phase, and return task index make post-design and mid-task overlays resumable without changing the main phase.

The prior unmerged `origin/codex/prototype-gates` branch is useful negative evidence. Commit `1a623cf` offered a prototype after research, requirements, and design and stored the result only in `.progress.md`. That implementation kept the disk contract unchanged, so it could not resume a prototype as its own phase or keep one canonical verdict. It also used a terminal logic prototype and omitted the supplied skill's branch capture rules. Do not cherry-pick it into this design.

## Direct invocation keeps opt-in small

### Normal mode

1. A user may invoke `/ralph-specum:prototype` from research, requirements, design, tasks, or execution. Research and requirements may also suggest it.
2. The coordinator records the current main phase, return phase, and return task index without setting `phase: prototype` in `.ralph-state.json`.
3. Omission leaves the normal phase path unchanged.
4. The prototype coordinator delegates isolated source work, reviews a candidate record and runnable evidence, then publishes an immutable terminal record.
5. The user owns normal-mode verdict and handoff decisions. The reviewer checks the artifact and runnable contract, not production test coverage.

This follows the existing approval shape rather than adding a second kind of gate. Phase commands already offer approve, review, or request changes and loop after changes. `plugins/ralph-specum/commands/requirements.md:134-148`.

### Quick mode

Quick mode makes exactly one bounded request after requirements. It takes over the oldest design blocker or selects the highest-risk grounded question, owns verdict and handoff decisions, asks no prototype questions, and continues to design after every outcome.

### The same command resumes an interrupted prototype

The prototype command owns recovery through `activePrototypes`, immutable candidates, and terminal records. The earlier main-state `phase: prototype` proposal is superseded. Start and session guidance route active entries and review recovery through `/ralph-specum:prototype`; they do not infer a main prototype phase from files.

## The canonical artifact should be a decision record

Use immutable `<basePath>/prototypes/<id>.md` records for workflow truth. Keep prototype source out of the spec directory and off the active feature branch.

The template should contain:

| Section | Required content |
|---|---|
| Question | One falsifiable state-model or UI question |
| Kind | `logic` or `ui`, with the reason or fallback assumption |
| Run | Branch, commit, file or route, one run action, and an optional worktree path when the user selected one |
| Cases or variants | Logic guided cases, or UI variant keys and structural differences |
| Observations | What the user observed |
| Verdict | `pending`, `validated`, or `rejected`, plus the exact decision |
| Design input | The decision that design must carry forward and any rejected option it must not revive |
| Capture | Throwaway branch pointer and implementation-issue pointer or `pending authorization` |

Add a `prototypeFrontmatter` definition to both schemas with `spec`, `phase: prototype`, `kind`, `verdict`, and `created`. Keep detailed branch and issue data in the artifact, not transient state.

Keep the main state `phase` enum unchanged. Use `phase: prototype` only in prototype-record frontmatter, and store live overlay coordination under `activePrototypes`. Immutable terminal records own the final kind, verdict, source disposition, return target, and evidence hashes.

## Final capture belongs on a branch outside main

Current phase commands commit and push their spec artifact on the active branch when `commitSpec` is true. Research shows that behavior at `plugins/ralph-specum/commands/research.md:178-186`. Existing branch rules also forbid direct pushes to the default branch. `plugins/ralph-specum/references/commit-discipline.md:96-101`.

The implementation must leave the final prototype commit on a throwaway branch such as `prototype/<spec-name>`, outside main. The user may select a sibling worktree when they want concurrent access to the active feature branch. V1 should not create, copy state into, clean, or remove worktrees automatically. The requirement is the final branch capture, not one workspace layout.

After approval, `prototype.md` records the throwaway branch and commit. The active feature branch receives the decision record when `commitSpec` is true. Design and implementation then carry the validated decision into production code with normal tests.

`commitSpec` currently governs spec artifacts, not unrelated branch pushes. Requirements must not silently reinterpret it. Posting or pushing the prototype branch and writing an implementation-issue pointer are external actions. The command should do them only when the user supplied the issue and authorized the push. Without that authority, `prototype.md` should record the local branch and a ready-to-post pointer as `pending authorization`.

Cancel must never delete the retained prototype branch. Claude cancel currently deletes the spec directory, including the only local pointer if it is not captured first. `plugins/ralph-specum/commands/cancel.md:44-76`. Update cancel to read `prototype.md`, report the retained branch, and leave branch deletion to an explicit destructive request. The Codex cancel path already treats directory deletion as a confirmed action. `plugins/ralph-specum-codex/skills/ralph-specum-cancel/SKILL.md:20-26`.

## Original Claude file proposal (superseded)

| File or component | Change |
|---|---|
| `plugins/ralph-specum/commands/prototype.md` | Add the coordinator flow, interview, logic/UI delegation, walkthrough, review, state merge, commit, and hard stop |
| `plugins/ralph-specum/agents/prototype-builder.md` | Add the self-contained builder rules adapted from the supplied skill |
| `plugins/ralph-specum/templates/prototype.md` | Add the canonical decision-record shape |
| `plugins/ralph-specum/commands/start.md`, `plugins/ralph-specum/hooks/scripts/load-spec-context.sh`, and `plugins/ralph-specum/references/spec-scanner.md` | Add `phase: prototype` guidance to the current resume and approval cases. For interrupted or approval-pending prototype work, tell the user to invoke `/ralph-specum:prototype`; start guidance must never auto-run it, add a start flag, or change quick-mode routing. Current cases: `plugins/ralph-specum/commands/start.md:109-117`, `plugins/ralph-specum/hooks/scripts/load-spec-context.sh:71-99`. |
| `plugins/ralph-specum/agents/spec-reviewer.md` | Accept `artifactType: prototype` and apply a prototype-specific review rubric |
| `plugins/ralph-specum/commands/design.md` | Read an approved `prototype.md` when present; direct design after requirements remains the skip path |
| `plugins/ralph-specum/commands/status.md`, `plugins/ralph-specum/commands/switch.md`, `plugins/ralph-specum/commands/help.md` | Show the phase and artifact and document direct invocation |
| `plugins/ralph-specum/skills/spec-workflow/SKILL.md`, `plugins/ralph-specum/skills/spec-workflow/references/phase-transitions.md`, `plugins/ralph-specum/skills/smart-ralph/SKILL.md`, `plugins/ralph-specum/skills/smart-ralph/references/state-file-schema.md` | Document optional placement, phase value, and skip semantics |
| `plugins/ralph-specum/schemas/spec.schema.json` | Document the `prototype` phase value and add prototype frontmatter |
| `plugins/ralph-specum/commands/cancel.md` | Preserve and report the throwaway branch pointer before deleting spec files |
| `README.md` | Add the command, phase diagram, artifact, direct opt-in, and Claude/Codex mapping |
| `plugins/ralph-specum/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` | Update the description or keywords for prototype support and make the same minor version bump |

No behavioral change is needed in `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`; add a regression test that `phase: prototype` behaves like the other non-execution phases. Quick mode stays unchanged.

## Original Codex file proposal (superseded)

| File or component | Change |
|---|---|
| `plugins/ralph-specum-codex/skills/ralph-specum-prototype/SKILL.md` and `agents/openai.yaml` | Add the explicit helper skill and approval handoff |
| `plugins/ralph-specum-codex/skills/ralph-specum/SKILL.md` and `plugins/ralph-specum-codex/skills/ralph-specum/agents/openai.yaml` | Add primary routing and the new optional phase to coordinator rules |
| `plugins/ralph-specum-codex/skills/ralph-specum-start/SKILL.md` and `plugins/ralph-specum-codex/skills/ralph-specum-start/agents/openai.yaml` | Add resume guidance that tells users to invoke prototype; never auto-run it |
| `plugins/ralph-specum-codex/agent-configs/spec-reviewer.toml.template` | Accept `artifactType: prototype` and apply a prototype-specific review rubric |
| `plugins/ralph-specum-codex/agent-configs/prototype-builder.toml.template` | Add the specialized sub-agent bootstrap template |
| `plugins/ralph-specum-codex/templates/prototype.md` | Mirror the Claude artifact headings |
| `plugins/ralph-specum-codex/skills/ralph-specum-design/SKILL.md` | Consume an approved prototype verdict when present |
| `plugins/ralph-specum-codex/skills/ralph-specum-status/SKILL.md`, `ralph-specum-switch/SKILL.md`, `ralph-specum-help/SKILL.md`, `ralph-specum-cancel/SKILL.md` | Show prototype state and artifact, document the helper, and preserve branch pointers on cancel |
| `plugins/ralph-specum-codex/references/workflow.md`, `state-contract.md`, `parity-matrix.md` | Add direct invocation, pre-design placement, approval, state, and capture rules |
| `plugins/ralph-specum-codex/assets/bootstrap/AGENTS.md` and `plugins/ralph-specum-codex/README.md` | Add consumer-facing phase and helper guidance |
| `plugins/ralph-specum-codex/schemas/spec.schema.json` | Mirror the Claude phase documentation and frontmatter changes |
| `plugins/ralph-specum-codex/.codex-plugin/plugin.json` | Update the description or keywords for prototype support and bump to the same minor version |

No change is needed in `plugins/ralph-specum-codex/scripts/merge_state.py`; it already preserves unknown top-level fields. No change is needed in the Codex stop hook because it exits for every non-execution phase. `plugins/ralph-specum-codex/scripts/merge_state.py:54-79`, `plugins/ralph-specum-codex/hooks/stop-watcher.sh:38-47`.

## Related specs and history

| Source | Reusable decision or conflict | Relevance |
|---|---|---|
| `specs/improve-walkthrough-feature/design.md:60-75` | The command owns artifact extraction and walkthrough presentation; the agent owns generation | High, use the same coordinator split |
| `specs/codex-plugin-sync/research.md:133-150` | Preserve Codex helper skills, agent metadata, bootstrap files, and parity tests | High, prevents a Claude-only phase |
| `specs/enforce-teams-instead/requirements.md:73-85` | Every planning command uses the same team lifecycle and preserves approval behavior | Medium, reuse the single-agent phase pattern |
| Commit `1a623cf` on `origin/codex/prototype-gates` | Prior prototype gates had no phase state or canonical artifact and do not match the supplied logic branch | High conflict, inspect but do not reuse as implementation |

The generated index describes itself as auto-generated and was last updated on 2026-04-07, so treat it as a hint rather than live workflow evidence. `specs/.index/index.md:1-6`. The indexer reads the phase string from state without a phase-specific branch. `plugins/ralph-specum/hooks/scripts/update-spec-index.sh:86-98`.

## Risks and controls

| Risk | Consequence | Control |
|---|---|---|
| Optional becomes mandatory | Every spec pays time and branch cost | Keep normal suggestions user-owned and limit quick mode to one bounded request |
| Prototype code reaches production | Untested code enters implementation | Require final capture on a throwaway branch outside main; a sibling worktree remains optional |
| Post-design invocation changes an approved design | Tasks can reflect conflicting decisions | Track dependencies and block stale downstream artifacts or task indexes before consumption |
| Issue or remote branch changes exceed authority | External state changes without consent | Record a ready pointer and require explicit push or issue-update authority |
| Logic and UI paths blur | Builder produces the wrong artifact | Require one question and one `kind`; ask the user when the choice is unclear |
| Existing count tests fail | Package structure change breaks CI | Replace hard-coded counts with explicit lists that include the new helper, agent, and template |
| Version drift hides package parity | Claude and Codex publish different behavior | Bump Claude manifest, Claude marketplace, and Codex manifest to the same new minor version |

## Verification tooling

The current repository test command is `bats tests/*.bats`; CI runs the same suite. `.github/workflows/bats-tests.yml:23-35`. The Codex package tests cover helper parity, metadata, templates, and scripts. `tests/codex-platform.bats:85-105`, `tests/codex-platform.bats:185-224`, `tests/codex-plugin.bats:66-107`, `tests/codex-plugin.bats:141-162`.

The later implementation should run:

```bash
bats tests/prototype-phase.bats
bats tests/codex-plugin.bats tests/codex-platform.bats tests/codex-platform-scripts.bats
bats tests/state-management.bats tests/stop-hook.bats tests/integration.bats
bats tests/*.bats
bash tests/helpers/version-sync.sh
bash -n plugins/ralph-specum/hooks/scripts/*.sh plugins/ralph-specum-codex/hooks/*.sh
jq empty plugins/ralph-specum/schemas/spec.schema.json plugins/ralph-specum-codex/schemas/spec.schema.json
git diff --check
```

Add tests for:

1. Direct invocation preserves every supported origin phase; normal suggestions stay optional; quick mode makes one post-requirements request.
2. State merge preserves the main phase and unknown fields, stores live work under `activePrototypes`, and resumes through the same command.
3. Logic/UI selection, fallback questioning, required artifact headings, and the normal approval loop.
4. Status, switch, cancel reporting, help, README, schemas, reviewer acceptance and prototype rubric, and all three version entries.
5. Claude/Codex helper parity, updated skill/agent/template lists, script-count coverage, and final prototype capture outside main.

Baseline run on 2026-08-27: `bats tests/codex-plugin.bats tests/codex-platform.bats tests/codex-platform-scripts.bats` -> 40 total: 39 pass, 1 skip. A separate 30-second bounded run of `bats tests/state-management.bats tests/stop-hook.bats tests/integration.bats` timed out before the suite summary; its partial output showed passing tests but does not establish a full result.

The pinned tree has a known version issue. `bash tests/helpers/version-sync.sh` reports `Claude=4.10.0 Codex=4.10.1`; the helper fails on any Claude/Codex mismatch. `tests/helpers/version-sync.sh:3-10`. `tests/interview-framework.bats` also hard-codes obsolete version `4.9.1` at `tests/interview-framework.bats:64-70`; later work should replace those assertions with manifest/marketplace equality plus a semantic-version check.

## Recommendations for requirements

1. Define prototype work as an optional overlay available from every main phase, with user-owned normal suggestions and one question-free quick request after requirements.
2. Preserve the main phase and store concurrent live entries under `activePrototypes`; gate downstream work on blockers, dependencies, and staleness.
3. Publish immutable `<basePath>/prototypes/<id>.md` records with the question, evidence, verdict, handoff, source disposition, and hashes.
4. Keep `prototype` out of the main phase enum; use `phase: prototype` only for prototype-record frontmatter.
5. Delegate to a dedicated builder that follows the supplied logic and UI paths, including the single-file logic demo and three route variants.
6. Require final prototype capture on a throwaway branch outside main. Offer a sibling worktree only when the user selects it.
7. Update Claude and Codex in one change, including the command or helper, agents, templates, schemas, state and transition references, status/help/switch/cancel paths, resume owners, spec-reviewer prototype acceptance and rubric, docs, tests, and matching minor versions.

## Resolved authorization questions

1. Invoking the overlay and enabling `commitSpec` authorize local work only. Pushing terminal records requires separate authorization naming each exact record, and isolated prototype source branches never push.
2. Issue writes and other remote lifecycle actions require their own authorization and run only after the Prototype Evidence Push Gate permits and completes the dependent push.

## Sources

- Current Claude workflow: `plugins/ralph-specum/commands/start.md`, `plugins/ralph-specum/commands/research.md`, `plugins/ralph-specum/commands/requirements.md`, `plugins/ralph-specum/commands/design.md`, `plugins/ralph-specum/commands/tasks.md`.
- Current state and hooks: `plugins/ralph-specum/schemas/spec.schema.json`, `plugins/ralph-specum/hooks/scripts/load-spec-context.sh`, `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`, `plugins/ralph-specum/hooks/scripts/update-spec-index.sh`.
- Current Codex contract: `plugins/ralph-specum-codex/references/workflow.md`, `plugins/ralph-specum-codex/references/state-contract.md`, `plugins/ralph-specum-codex/references/parity-matrix.md`, `plugins/ralph-specum-codex/skills/ralph-specum/SKILL.md`.
- Prototype source: `/Users/zachbonfil/.agents/skills/prototype/SKILL.md`, `/Users/zachbonfil/.agents/skills/prototype/LOGIC.md`, `/Users/zachbonfil/.agents/skills/prototype/UI.md`.
- Prior unmerged approach: commit `1a623cf` and `origin/codex/prototype-gates`, inspected with `git show` only.
- No web source was needed. The live repository and supplied prototype skill answer the architecture questions.
