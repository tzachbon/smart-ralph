---
spec: optional-prototype-phase
phase: research
created: 2026-08-27T15:15:00Z
---

# Research: optional prototype phase

## In short

Add `prototype` as an optional planning phase between requirements and design:

```text
research -> requirements -> [prototype] -> design -> tasks -> execution
```

The smallest useful version gives Claude and Codex each one new command or helper skill, one new agent, one `prototype.md` decision record, one template, and one new state value. Users opt in by running the prototype command after requirements. The default workflow and quick mode skip it.

The phase must capture its final prototype code on a throwaway branch outside main. A sibling worktree is an optional isolation method that the user may select, not part of the phase contract. The active feature branch should receive only `prototype.md` and later production code that applies the verdict.

The Claude and Codex schema copies enumerate and document the current phase values. Both copies need the same `prototype` update. The pinned tree also has a version mismatch: the Claude plugin and marketplace are `4.10.0`, while the Codex plugin is `4.10.1`. `plugins/ralph-specum/.claude-plugin/plugin.json:1-4`, `.claude-plugin/marketplace.json:9-17`, `plugins/ralph-specum-codex/.codex-plugin/plugin.json:1-4`. A minor bump for both packages should bring all three versioned entries to one value.

## Confirmed current workflow

### Ralph has one linear planning path

The documented phase order is `research -> requirements -> design -> tasks -> implement`. Each planning phase ends with `awaitingApproval: true`, and quick mode skips interviews, walkthroughs, and approval stops. `plugins/ralph-specum/skills/spec-workflow/references/phase-transitions.md:5-9`, `plugins/ralph-specum/skills/spec-workflow/references/phase-transitions.md:88-104`.

The phase commands share the same coordinator shape: gather context, interview, delegate, review in quick mode, walk through the artifact, merge state, optionally commit the artifact, and stop. Research shows the full sequence and state merge at `plugins/ralph-specum/commands/research.md:11-21` and `plugins/ralph-specum/commands/research.md:164-197`. Requirements, design, and tasks repeat it at `plugins/ralph-specum/commands/requirements.md:11-20`, `plugins/ralph-specum/commands/design.md:11-20`, and `plugins/ralph-specum/commands/tasks.md:11-20`.

The next command implicitly approves the preceding artifact. Requirements says that it approves research, design says that it approves requirements, and tasks says that it approves design. `plugins/ralph-specum/commands/requirements.md:7-9`, `plugins/ralph-specum/commands/design.md:7-9`, `plugins/ralph-specum/commands/tasks.md:7-9`.

### Quick mode names every phase in one fixed sequence

Quick mode creates state with `phase: "research"`, runs research, requirements, design, and tasks, then changes the state to `execution`. `plugins/ralph-specum/references/quick-mode.md:60-78`, `plugins/ralph-specum/references/quick-mode.md:111-120`. The start command summarizes the same four-artifact sequence and requires a native task for each phase. `plugins/ralph-specum/commands/start.md:253-259`.

V1 should leave that quick sequence unchanged. The Claude stop hook already treats every phase other than `execution` as planning work, and the Codex hook acts only during execution. Neither hook needs new behavior for a directly invoked prototype phase. `plugins/ralph-specum/hooks/scripts/stop-watcher.sh:159-184`, `plugins/ralph-specum-codex/hooks/stop-watcher.sh:38-47`.

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

## One optional slot after requirements is the smallest viable design

Recommend option A for the first release.

Requirements are the first artifact that can state the user-visible behavior and acceptance boundary. Design is the first artifact that should commit the implementation architecture. A prototype between them tests the risky state model or UI choice before the design records it.

This placement also preserves a simple skip path. The design command already requires only `requirements.md`. `plugins/ralph-specum/commands/design.md:22-29`. Leaving that prerequisite intact means omission of `prototype` changes nothing for existing specs.

The phase should have one official slot. The prototype command must require `requirements.md` and reject invocation when `design.md` exists or state has advanced to design, tasks, or execution. Post-design re-entry would need artifact revision ordering and invalidation rules. Defer that behavior until a later release.

The prior unmerged `origin/codex/prototype-gates` branch is useful negative evidence. Commit `1a623cf` offered a prototype after research, requirements, and design and stored the result only in `.progress.md`. That implementation kept the disk contract unchanged, so it could not resume a prototype as its own phase or keep one canonical verdict. It also used a terminal logic prototype and omitted the supplied skill's branch capture rules. Do not cherry-pick it into this design.

## Direct invocation keeps opt-in small

### Normal mode

1. A user opts in by running `/ralph-specum:prototype` after requirements and before design.
2. The command rejects the run if `requirements.md` is absent, `design.md` exists, or state has moved beyond the pre-design slot.
3. Omission means skip. Running `/ralph-specum:design` after requirements keeps the current path unchanged.
4. The prototype coordinator clears the prior approval gate, delegates to `prototype-builder`, checks `prototype.md` and the runnable prototype, then presents the run path or URL.
5. Approval accepts the recorded verdict and makes design the next phase. A change request reuses the same builder with the user's observations. A review checks the artifact and runnable contract, not production test coverage.

This follows the existing approval shape rather than adding a second kind of gate. Phase commands already offer approve, review, or request changes and loop after changes. `plugins/ralph-specum/commands/requirements.md:134-148`.

### Quick mode

Quick mode skips prototype in v1. It keeps the existing research, requirements, design, and tasks sequence. A future release may add an explicit quick-mode prototype option after it defines how an unattended run can obtain a user verdict.

### The same command resumes an interrupted prototype

The prototype command owns its own recovery. With `phase: prototype` and `awaitingApproval: false`, rerunning it resumes the builder from `prototype.md` and the recorded branch. With `awaitingApproval: true`, rerunning it shows the verdict and approval choices. Standard start and session guidance should tell the user to run `/ralph-specum:prototype` in both cases. They must not invoke the phase, add a start flag, change quick-mode routing, or infer prototype from files when state is absent.

## The canonical artifact should be a decision record

Use `specs/<name>/prototype.md` for workflow truth. Keep the prototype code out of the spec directory and off the active feature branch.

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

Add only `prototype` as a documented `phase` value. Do not add opt-in, kind, branch, verdict, or return fields to `.ralph-state.json`. `prototype.md` owns those values, and the current state contract keeps phase artifacts outside the runtime state object. `plugins/ralph-specum-codex/references/state-contract.md:14-35`, `plugins/ralph-specum-codex/references/state-contract.md:61-65`.

## Final capture belongs on a branch outside main

Current phase commands commit and push their spec artifact on the active branch when `commitSpec` is true. Research shows that behavior at `plugins/ralph-specum/commands/research.md:178-186`. Existing branch rules also forbid direct pushes to the default branch. `plugins/ralph-specum/references/commit-discipline.md:96-101`.

The implementation must leave the final prototype commit on a throwaway branch such as `prototype/<spec-name>`, outside main. The user may select a sibling worktree when they want concurrent access to the active feature branch. V1 should not create, copy state into, clean, or remove worktrees automatically. The requirement is the final branch capture, not one workspace layout.

After approval, `prototype.md` records the throwaway branch and commit. The active feature branch receives the decision record when `commitSpec` is true. Design and implementation then carry the validated decision into production code with normal tests.

`commitSpec` currently governs spec artifacts, not unrelated branch pushes. Requirements must not silently reinterpret it. Posting or pushing the prototype branch and writing an implementation-issue pointer are external actions. The command should do them only when the user supplied the issue and authorized the push. Without that authority, `prototype.md` should record the local branch and a ready-to-post pointer as `pending authorization`.

Cancel must never delete the retained prototype branch. Claude cancel currently deletes the spec directory, including the only local pointer if it is not captured first. `plugins/ralph-specum/commands/cancel.md:44-76`. Update cancel to read `prototype.md`, report the retained branch, and leave branch deletion to an explicit destructive request. The Codex cancel path already treats directory deletion as a confirmed action. `plugins/ralph-specum-codex/skills/ralph-specum-cancel/SKILL.md:20-26`.

## Affected Claude plugin files

| File or component | Change |
|---|---|
| `plugins/ralph-specum/commands/prototype.md` | Add the coordinator flow, interview, logic/UI delegation, walkthrough, review, state merge, commit, and hard stop |
| `plugins/ralph-specum/agents/prototype-builder.md` | Add the self-contained builder rules adapted from the supplied skill |
| `plugins/ralph-specum/templates/prototype.md` | Add the canonical decision-record shape |
| `plugins/ralph-specum/commands/start.md` and `plugins/ralph-specum/hooks/scripts/load-spec-context.sh` | Add `phase: prototype` guidance to the current resume and approval cases. For interrupted or approval-pending prototype work, tell the user to run `/ralph-specum:prototype`. Do not auto-run it, add a start flag, or change quick-mode routing. Current cases: `plugins/ralph-specum/commands/start.md:109-117`, `plugins/ralph-specum/hooks/scripts/load-spec-context.sh:71-99`. |
| `plugins/ralph-specum/commands/design.md` | Read an approved `prototype.md` when present; direct design after requirements remains the skip path |
| `plugins/ralph-specum/commands/status.md`, `plugins/ralph-specum/commands/switch.md`, `plugins/ralph-specum/commands/help.md` | Show the phase and artifact and document direct invocation |
| `plugins/ralph-specum/skills/spec-workflow/SKILL.md`, `plugins/ralph-specum/skills/spec-workflow/references/phase-transitions.md`, `plugins/ralph-specum/skills/smart-ralph/SKILL.md`, `plugins/ralph-specum/skills/smart-ralph/references/state-file-schema.md` | Document optional placement, phase value, and skip semantics |
| `plugins/ralph-specum/schemas/spec.schema.json` | Document the `prototype` phase value and add prototype frontmatter |
| `plugins/ralph-specum/commands/cancel.md` | Preserve and report the throwaway branch pointer before deleting spec files |
| `README.md` | Add the command, phase diagram, artifact, direct opt-in, and Claude/Codex mapping |
| `plugins/ralph-specum/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` | Update the description or keywords for prototype support and make the same minor version bump |

No behavioral change is needed in `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`; add a regression test that `phase: prototype` behaves like the other non-execution phases. Quick mode stays unchanged.

## Affected Codex plugin files

| File or component | Change |
|---|---|
| `plugins/ralph-specum-codex/skills/ralph-specum-prototype/SKILL.md` and `agents/openai.yaml` | Add the explicit helper skill and approval handoff |
| `plugins/ralph-specum-codex/skills/ralph-specum/SKILL.md` and `agents/openai.yaml` | Add primary routing and the new optional phase to coordinator rules |
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
| Optional becomes mandatory | Every spec pays time and branch cost | Add only a direct command and leave design callable after requirements |
| Prototype code reaches production | Untested code enters implementation | Require final capture on a throwaway branch outside main; a sibling worktree remains optional |
| Post-design invocation changes an approved design | Tasks can reflect conflicting decisions | Reject prototype when design exists or state has advanced past the pre-design slot |
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

1. Direct invocation succeeds only after requirements and before design; default and quick flows still skip it.
2. State merge preserves existing fields, stores `phase: prototype`, resumes through the same command, and rejects post-design invocation.
3. Logic/UI selection, fallback questioning, required artifact headings, and the normal approval loop.
4. Status, switch, cancel reporting, help, README, schemas, and all three version entries.
5. Claude/Codex helper parity, updated skill/agent/template lists, script-count coverage, and final prototype capture outside main.

Baseline run on 2026-08-27: `bats tests/codex-plugin.bats tests/codex-platform.bats tests/codex-platform-scripts.bats` -> 40 pass, 1 skip. A separate 30-second bounded run of `bats tests/state-management.bats tests/stop-hook.bats tests/integration.bats` timed out before the suite summary; its partial output showed passing tests but does not establish a full result.

The pinned tree has a known version issue. `bash tests/helpers/version-sync.sh` reports `Claude=4.10.0 Codex=4.10.1`; the helper fails on any Claude/Codex mismatch. `tests/helpers/version-sync.sh:3-10`. `tests/interview-framework.bats` also hard-codes obsolete version `4.9.1` at `tests/interview-framework.bats:64-70`; later work should replace those assertions with manifest/marketplace equality plus a semantic-version check.

## Recommendations for requirements

1. Define `prototype` as an optional direct command after requirements and before design. Default and quick workflows skip it.
2. Reject invocation when requirements are missing, design exists, or state has advanced beyond the pre-design slot.
3. Require one canonical `prototype.md` with question, kind, run instructions, observations, verdict, design input, branch pointer, and issue-pointer status.
4. Add only `prototype` as a documented phase value. Keep branch, kind, and verdict in `prototype.md`.
5. Delegate to a dedicated builder that follows the supplied logic and UI paths, including the single-file logic demo and three route variants.
6. Require final prototype capture on a throwaway branch outside main. Offer a sibling worktree only when the user selects it.
7. Update Claude and Codex in one change, including the command or helper, agents, templates, schemas, state and transition references, status/help/switch/cancel paths, docs, tests, and matching minor versions.

## Open questions

1. Does invoking the prototype phase authorize pushing its throwaway branch, or must the phase ask separately? Current `commitSpec` wording covers spec artifacts only.
2. Which issue systems can receive the required branch pointer, and is writing that pointer part of the phase or a draft for later approval?

## Sources

- Current Claude workflow: `plugins/ralph-specum/commands/start.md`, `plugins/ralph-specum/commands/research.md`, `plugins/ralph-specum/commands/requirements.md`, `plugins/ralph-specum/commands/design.md`, `plugins/ralph-specum/commands/tasks.md`.
- Current state and hooks: `plugins/ralph-specum/schemas/spec.schema.json`, `plugins/ralph-specum/hooks/scripts/load-spec-context.sh`, `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`, `plugins/ralph-specum/hooks/scripts/update-spec-index.sh`.
- Current Codex contract: `plugins/ralph-specum-codex/references/workflow.md`, `plugins/ralph-specum-codex/references/state-contract.md`, `plugins/ralph-specum-codex/references/parity-matrix.md`, `plugins/ralph-specum-codex/skills/ralph-specum/SKILL.md`.
- Prototype source: `/Users/zachbonfil/.agents/skills/prototype/SKILL.md`, `/Users/zachbonfil/.agents/skills/prototype/LOGIC.md`, `/Users/zachbonfil/.agents/skills/prototype/UI.md`.
- Prior unmerged approach: commit `1a623cf` and `origin/codex/prototype-gates`, inspected with `git show` only.
- No web source was needed. The live repository and supplied prototype skill answer the architecture questions.
