---
generated: auto
granularity: fine
workflow: poc-first
---

# Tasks: Optional prototype capability

## Phase 1: Make It Work

Build one end-to-end local prototype path first. Tests are added in Phase 3 after the coordinator, helpers, and both harness surfaces exist.

- [x] 1.1 Add the shared locked state primitive
  - **Do**: Add matching Python helpers for POSIX `flock` and the Windows lock-directory fallback. Implement `merge`, `upsert-prototype`, `remove-prototype`, `list`, `delete-state`, `claim-builder`, `heartbeat`, `renew-lease`, `release-lease`, and compare-and-set `transition`. Preserve unknown state fields, use configured bounded waits, flush temp files before `os.replace`, and treat unsupported directory `fsync` as best effort. Make the existing Codex merge CLI a compatibility wrapper.
  - **Files**: `plugins/ralph-specum/hooks/scripts/locked-state.py`, `plugins/ralph-specum-codex/scripts/locked_state.py`, `plugins/ralph-specum-codex/scripts/merge_state.py`
  - **Done when**: Both helpers expose the same operations, concurrent writers cannot silently overwrite each other, builder ownership is compare-and-set, and state deletion refuses a nonempty `activePrototypes` map.
  - **Verify**: `python3 plugins/ralph-specum/hooks/scripts/locked-state.py --help >/dev/null && python3 plugins/ralph-specum-codex/scripts/locked_state.py --help >/dev/null && python3 plugins/ralph-specum-codex/scripts/merge_state.py --help >/dev/null`
  - **Commit**: `feat(prototype): add locked overlay state helpers`
  - _Requirements: FR-3, FR-5, NFR-2, NFR-3, NFR-4_

- [x] 1.2 Resolve prototype paths and configuration
  - **Do**: Extend both path resolvers to return `specRoot`, `basePath`, and validated prototype limits from `.claude/ralph-specum.local.md`. Preserve existing resolver output and defaults. Store warnings for invalid values and make every prototype helper accept a resolved base path instead of constructing `specs/<name>`.
  - **Files**: `plugins/ralph-specum/hooks/scripts/path-resolver.sh`, `plugins/ralph-specum-codex/scripts/resolve_spec_paths.py`
  - **Done when**: Default and configured roots resolve to matching Claude and Codex values, invalid limits fall back to approved defaults, and existing resolver callers remain compatible.
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/path-resolver.sh && python3 plugins/ralph-specum-codex/scripts/resolve_spec_paths.py --cwd . | jq -e '.specs_dirs and .default_dir' >/dev/null`
  - **Commit**: `feat(prototype): resolve paths and bounded settings`
  - _Requirements: FR-2, FR-3, FR-5, NFR-1, NFR-4_

- [x] 1.3 Add immutable prototype record publication
  - **Do**: Add matching record helpers and templates. Support exclusive candidate creation, candidate hashing, exact-byte no-overwrite publication, terminal record parsing, reconciliation, quarantine, supersession, downstream selection, cleanup receipts, and reviewed post-deletion bytes. Add ignore rules for locks, temp state, and candidates without ignoring final records.
  - **Files**: `plugins/ralph-specum/hooks/scripts/prototype-records.py`, `plugins/ralph-specum-codex/scripts/prototype_records.py`, `plugins/ralph-specum/templates/prototype.md`, `plugins/ralph-specum-codex/templates/prototype.md`, `.gitignore`
  - **Done when**: Final records are never overwritten, successful publication re-reads and verifies exact bytes, quick cleanup publishes only bytes reviewed after deletion, and superseded or malformed records are excluded downstream.
  - **Verify**: `python3 plugins/ralph-specum/hooks/scripts/prototype-records.py --help >/dev/null && python3 plugins/ralph-specum-codex/scripts/prototype_records.py --help >/dev/null && rg -n 'ralph-state|candidate' .gitignore`
  - **Commit**: `feat(prototype): publish immutable reviewed records`
  - _Requirements: FR-3, FR-4, FR-6, NFR-3_

- [x] 1.4 Add harness control and builder contracts
  - **Do**: Add matching launch, wait, heartbeat, interrupt, and status adapters plus Claude and Codex builder definitions. Adapt the local prototype skill's logic and UI contracts: a single logic HTML artifact or exactly three route variants with one shared switcher. Enforce soft deadlines, activity extensions, hard deadlines, one allowed mechanical retry, source redaction, and child-agent IDs rather than user-owned task threads.
  - **Files**: `plugins/ralph-specum/hooks/scripts/prototype-harness.py`, `plugins/ralph-specum-codex/scripts/prototype_harness.py`, `plugins/ralph-specum/agents/prototype-builder.md`, `plugins/ralph-specum-codex/agent-configs/prototype-builder.toml.template`
  - **Done when**: Both adapters expose the same control outcomes, unavailable controls fail safely, logic and UI outputs follow the approved contracts, and quick mode cannot wait indefinitely.
  - **Verify**: `python3 plugins/ralph-specum/hooks/scripts/prototype-harness.py --help >/dev/null && python3 plugins/ralph-specum-codex/scripts/prototype_harness.py --help >/dev/null && rg -n 'logic|ui|heartbeat|interrupt|hard deadline' plugins/ralph-specum/agents/prototype-builder.md plugins/ralph-specum-codex/agent-configs/prototype-builder.toml.template`
  - **Commit**: `feat(prototype): add bounded builder adapters`
  - _Requirements: FR-2, FR-5, FR-7, NFR-1, NFR-2, NFR-4_

- [x] 1.5 Add the Claude coordinator and direct command
  - **Do**: Add the shared Claude coordinator contract and `/ralph-specum:prototype`. Cover suggestion, explicit invocation from every main phase, safe interruption, isolation, capture choice, duplicate handling, user-owned normal verdict, handoff checkpoints, cancellation, quick ownership, cleanup receipt review, publication, and local-only remote behavior.
  - **Files**: `plugins/ralph-specum/references/prototype-coordinator.md`, `plugins/ralph-specum/commands/prototype.md`
  - **Done when**: Direct invocation preserves the main phase, never switches the current checkout, resumes active entries deterministically, and names every destructive or remote authorization gate.
  - **Verify**: `rg -n 'activePrototypes|returnPhase|sourceDisposition|REVIEW_PASS|quick|remote' plugins/ralph-specum/references/prototype-coordinator.md plugins/ralph-specum/commands/prototype.md`
  - **Commit**: `feat(prototype): add Claude prototype coordinator`
  - _Requirements: FR-1, FR-2, FR-4, FR-5, FR-6, NFR-1_

- [x] 1.6 Add the Codex prototype skill and routing
  - **Do**: Add `$ralph-specum-prototype`, its routing metadata, Codex coordinator reference, and root routing entries. Keep semantics aligned with the Claude coordinator while using Codex child-agent controls and the Codex helper paths.
  - **Files**: `plugins/ralph-specum-codex/skills/ralph-specum-prototype/SKILL.md`, `plugins/ralph-specum-codex/skills/ralph-specum-prototype/agents/openai.yaml`, `plugins/ralph-specum-codex/references/prototype-coordinator.md`, `plugins/ralph-specum-codex/skills/ralph-specum/SKILL.md`, `plugins/ralph-specum-codex/skills/ralph-specum/agents/openai.yaml`
  - **Done when**: The Codex entrypoint can route direct, suggested, resume, quick, and cancel behavior without `create_thread`, and it uses child `agentId` values for builders.
  - **Verify**: `test -f plugins/ralph-specum-codex/skills/ralph-specum-prototype/SKILL.md && rg -n 'ralph-specum-prototype|agentId|activePrototypes' plugins/ralph-specum-codex/skills/ralph-specum/SKILL.md plugins/ralph-specum-codex/references/prototype-coordinator.md`
  - **Commit**: `feat(prototype): add Codex prototype skill`
  - _Requirements: FR-1, FR-6, FR-8, NFR-5_

- [x] 1.7 Wire Claude planning suggestions and quick ownership
  - **Do**: Add `continue to prototype` after successful normal research and requirements. In quick mode run exactly one request after requirements, count the request separately from builder executions, select the highest-risk grounded question, own every decision, perform reviewed cleanup, and continue to design. Select only gate-approved evidence before design or tasks and enforce active-blocker and stale-artifact gates.
  - **Files**: `plugins/ralph-specum/commands/research.md`, `plugins/ralph-specum/commands/requirements.md`, `plugins/ralph-specum/commands/design.md`, `plugins/ralph-specum/commands/tasks.md`, `plugins/ralph-specum/references/quick-mode.md`
  - **Done when**: Normal mode offers but never forces prototype work; quick mode asks no questions, consumes exactly one request, and always continues to design; excluded or stale evidence cannot feed later artifacts.
  - **Verify**: `rg -l 'continue to prototype|activePrototypes|requestAttempt|cleanup' plugins/ralph-specum/commands/{research,requirements,design,tasks}.md plugins/ralph-specum/references/quick-mode.md | wc -l | grep -q '^5$'`
  - **Commit**: `feat(prototype): wire Claude planning gates`
  - _Requirements: FR-1, FR-4, FR-6, NFR-4_

- [x] 1.8 Mirror research and requirements gates in Codex
  - **Do**: Add the normal prototype choices and one post-requirements quick request to the Codex research and requirements skills and routing metadata.
  - **Files**: `plugins/ralph-specum-codex/skills/ralph-specum-research/SKILL.md`, `plugins/ralph-specum-codex/skills/ralph-specum-research/agents/openai.yaml`, `plugins/ralph-specum-codex/skills/ralph-specum-requirements/SKILL.md`, `plugins/ralph-specum-codex/skills/ralph-specum-requirements/agents/openai.yaml`
  - **Done when**: Codex offers the normal choice and quick mode routes exactly one autonomous request without a user question.
  - **Verify**: `rg -l 'ralph-specum-prototype|quick' plugins/ralph-specum-codex/skills/ralph-specum-{research,requirements}/SKILL.md | wc -l | grep -q '^2$'`
  - **Commit**: `feat(prototype): mirror Codex entry gates`
  - _Requirements: FR-1, FR-6, FR-8, NFR-5_

- [x] 1.9 Mirror design and tasks evidence gates in Codex
  - **Do**: Select only gate-approved records and reject active blockers or stale artifacts before Codex design and task generation. Add matching routing metadata.
  - **Files**: `plugins/ralph-specum-codex/skills/ralph-specum-design/SKILL.md`, `plugins/ralph-specum-codex/skills/ralph-specum-design/agents/openai.yaml`, `plugins/ralph-specum-codex/skills/ralph-specum-tasks/SKILL.md`, `plugins/ralph-specum-codex/skills/ralph-specum-tasks/agents/openai.yaml`
  - **Done when**: Excluded, superseded, malformed, and stale prototype evidence cannot feed Codex planning.
  - **Verify**: `rg -l 'activePrototypes|stale|gateApproved' plugins/ralph-specum-codex/skills/ralph-specum-{design,tasks}/SKILL.md | wc -l | grep -q '^2$'`
  - **Commit**: `feat(prototype): mirror Codex evidence gates`
  - _Requirements: FR-3, FR-4, FR-8, NFR-5_

- [x] 1.10 Gate Claude implementation and refactor dispatch
  - **Do**: Block stale or prototype-dependent task dispatch, use `returnTaskIndex` for resume, preserve state while active entries exist, and enforce the same checks in refactor and the stop hook.
  - **Files**: `plugins/ralph-specum/commands/implement.md`, `plugins/ralph-specum/commands/refactor.md`, `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: Only dependent tasks pause and completion cannot delete recovery state while active prototypes remain.
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh && rg -l 'activePrototypes|stale|returnTaskIndex' plugins/ralph-specum/commands/{implement,refactor}.md plugins/ralph-specum/hooks/scripts/stop-watcher.sh | wc -l | grep -q '^3$'`
  - **Commit**: `feat(prototype): gate Claude execution dispatch`
  - _Requirements: FR-1, FR-3, FR-4, FR-5, NFR-3_

- [x] 1.11 Add Claude resume and visibility surfaces
  - **Do**: Reconcile active and terminal records at start, show active entries and candidates in status, and show blockers for the selected spec in switch.
  - **Files**: `plugins/ralph-specum/commands/start.md`, `plugins/ralph-specum/commands/status.md`, `plugins/ralph-specum/commands/switch.md`
  - **Done when**: One active entry resumes automatically, several are listed, and blockers are visible without mutating state.
  - **Verify**: `test "$(rg -l 'activePrototypes|prototype' plugins/ralph-specum/commands/{start,status,switch}.md | wc -l | tr -d '[:space:]')" = 3`
  - **Commit**: `feat(prototype): add Claude resume visibility`
  - _Requirements: FR-3, FR-5, NFR-3_

- [x] 1.12 Add Claude cancel and help behavior
  - **Do**: Make normal cancellation publish and verify an immutable cancelled record before returning, preserve source and partial work, gate every deletion, and document direct and quick behavior in help.
  - **Files**: `plugins/ralph-specum/commands/cancel.md`, `plugins/ralph-specum/commands/help.md`
  - **Done when**: Cancel never deletes prototype source automatically and help names both the current-checkout and remote-action boundaries.
  - **Verify**: `test "$(rg -l 'cancelled|prototype|delet|remote' plugins/ralph-specum/commands/{cancel,help}.md | wc -l | tr -d '[:space:]')" = 2`
  - **Commit**: `feat(prototype): preserve source on Claude cancel`
  - _Requirements: FR-2, FR-3, FR-4, NFR-1, NFR-3_

- [x] 1.13 Gate Codex implementation and refactor dispatch
  - **Do**: Mirror active-blocker, stale-task, resume-index, and completion-state checks in Codex implement, refactor, and stop-hook surfaces with routing metadata.
  - **Files**: `plugins/ralph-specum-codex/skills/ralph-specum-implement/SKILL.md`, `plugins/ralph-specum-codex/skills/ralph-specum-implement/agents/openai.yaml`, `plugins/ralph-specum-codex/skills/ralph-specum-refactor/SKILL.md`, `plugins/ralph-specum-codex/skills/ralph-specum-refactor/agents/openai.yaml`, `plugins/ralph-specum-codex/hooks/stop-watcher.sh`
  - **Done when**: Codex dispatch behavior matches Claude and active recovery state survives completion attempts.
  - **Verify**: `bash -n plugins/ralph-specum-codex/hooks/stop-watcher.sh && test "$(rg -l 'activePrototypes|stale|returnTaskIndex' plugins/ralph-specum-codex/skills/ralph-specum-{implement,refactor}/SKILL.md plugins/ralph-specum-codex/hooks/stop-watcher.sh | wc -l | tr -d '[:space:]')" = 3`
  - **Commit**: `feat(prototype): gate Codex execution dispatch`
  - _Requirements: FR-1, FR-3, FR-4, FR-5, FR-8, NFR-5_

- [x] 1.14 Add Codex resume and visibility surfaces
  - **Do**: Reconcile at start, add routing metadata for resume, show active and terminal records in status, and show blockers in switch.
  - **Files**: `plugins/ralph-specum-codex/skills/ralph-specum-start/SKILL.md`, `plugins/ralph-specum-codex/skills/ralph-specum-start/agents/openai.yaml`, `plugins/ralph-specum-codex/skills/ralph-specum-status/SKILL.md`, `plugins/ralph-specum-codex/skills/ralph-specum-switch/SKILL.md`
  - **Done when**: Codex resumes and reports the same records and blockers as Claude.
  - **Verify**: `rg -l 'activePrototypes|prototype' plugins/ralph-specum-codex/skills/ralph-specum-{start,status,switch}/SKILL.md | wc -l | grep -q '^3$'`
  - **Commit**: `feat(prototype): add Codex resume visibility`
  - _Requirements: FR-3, FR-5, FR-8, NFR-3, NFR-5_

- [x] 1.15 Add Codex cancel and help behavior
  - **Do**: Mirror immutable cancellation, source preservation, deletion gates, direct invocation help, and remote-action boundaries.
  - **Files**: `plugins/ralph-specum-codex/skills/ralph-specum-cancel/SKILL.md`, `plugins/ralph-specum-codex/skills/ralph-specum-help/SKILL.md`
  - **Done when**: Codex cancel and help behavior matches Claude without deleting retained or normal ephemeral source.
  - **Verify**: `rg -l 'cancelled|prototype|delet|remote' plugins/ralph-specum-codex/skills/ralph-specum-{cancel,help}/SKILL.md | wc -l | grep -q '^2$'`
  - **Commit**: `feat(prototype): preserve source on Codex cancel`
  - _Requirements: FR-2, FR-3, FR-4, FR-8, NFR-1, NFR-5_

- [ ] 1.16 [VERIFY] Prove one local end-to-end prototype record flow
  - **Do**: Run the exact automated command below. It uses a temporary directory for each helper stack, creates requirements-phase state, reserves an active entry, renders and publishes a minimal skipped record, reconciles state, and asserts the final/candidate/state results. It does not create a spec directory or touch the current checkout state.
  - **Files**: Read-only
  - **Done when**: Both helper stacks create one verified immutable final record, remove the active entry only after verification, leave no candidate, and produce matching normalized fields.
  - **Verify**:
    ```bash
    python3 - <<'PY'
    import json, pathlib, subprocess, tempfile
    stacks = [
        ("plugins/ralph-specum/hooks/scripts/locked-state.py", "plugins/ralph-specum/hooks/scripts/prototype-records.py"),
        ("plugins/ralph-specum-codex/scripts/locked_state.py", "plugins/ralph-specum-codex/scripts/prototype_records.py"),
    ]
    entry = {"id": "smoke", "stateRevision": 1, "question": "Does publication work?", "questionHash": "smoke", "kind": "logic", "captureMode": "retained", "triggerMode": "explicit", "triggerPhase": "requirements", "returnPhase": "design", "returnTaskIndex": None, "status": "pending", "decisionOwner": "user", "resolutionMode": "normal", "created": "2026-01-01T00:00:00Z", "sourceDisposition": "not_created"}
    record = {"spec": "smoke", "phase": "prototype", "id": "smoke", "question": "Does publication work?", "kind": "logic", "captureMode": "retained", "triggerMode": "explicit", "triggerPhase": "requirements", "returnPhase": "design", "status": "completed", "verdict": "skipped", "created": "2026-01-01T00:00:00Z", "gateApproved": False, "sourceDisposition": "not_created", "runInstructions": "none"}
    for state_cli, record_cli in stacks:
        with tempfile.TemporaryDirectory() as raw:
            base = pathlib.Path(raw)
            state = base / ".ralph-state.json"
            subprocess.run(["python3", state_cli, "merge", "--state", str(state), "--set", "phase=requirements"], check=True)
            subprocess.run(["python3", state_cli, "upsert-prototype", "--state", str(state), "--id", "smoke", "--entry-json", json.dumps(entry)], check=True)
            subprocess.run(["python3", record_cli, "render-candidate", "--base-path", str(base), "--record-json", json.dumps(record)], check=True)
            subprocess.run(["python3", record_cli, "publish", "--base-path", str(base), "--id", "smoke"], check=True)
            subprocess.run(["python3", record_cli, "reconcile", "--base-path", str(base), "--state", str(state)], check=True)
            assert (base / "prototypes" / "smoke.md").is_file()
            assert not (base / "prototypes" / ".smoke.candidate.md").exists()
            assert not json.loads(state.read_text()).get("activePrototypes")
    PY
    ```
  - **Commit**: None
  - _Requirements: FR-1, FR-3, FR-7, FR-8, NFR-1, NFR-3_

## Phase 2: Refactoring

- [ ] 2.1 Migrate Claude phase command state writers
  - **Do**: Replace direct creation and `jq` temp/move updates in new, research, requirements, and design with locked helper calls while preserving every existing field.
  - **Files**: `plugins/ralph-specum/commands/new.md`, `plugins/ralph-specum/commands/research.md`, `plugins/ralph-specum/commands/requirements.md`, `plugins/ralph-specum/commands/design.md`
  - **Done when**: The four commands contain no raw write or move of `.ralph-state.json`.
  - **Verify**: `! rg -n 'jq .*ralph-state|mv .*ralph-state|> .*ralph-state' plugins/ralph-specum/commands/{new,research,requirements,design}.md`
  - **Commit**: `refactor(state): lock Claude phase writers`
  - _Requirements: FR-3, FR-5, NFR-2, NFR-3_

- [ ] 2.2 Migrate Claude task and cleanup command state writers
  - **Do**: Route tasks, implement, refactor, and cancel state updates through the helper. Use `delete-state` only after active entries are empty.
  - **Files**: `plugins/ralph-specum/commands/tasks.md`, `plugins/ralph-specum/commands/implement.md`, `plugins/ralph-specum/commands/refactor.md`, `plugins/ralph-specum/commands/cancel.md`
  - **Done when**: The four commands contain no raw state move or deletion and preserve active prototype recovery data.
  - **Verify**: `! rg -n 'jq .*ralph-state|mv .*ralph-state|rm .*ralph-state' plugins/ralph-specum/commands/{tasks,implement,refactor,cancel}.md`
  - **Commit**: `refactor(state): lock Claude task writers`
  - _Requirements: FR-3, FR-5, NFR-2, NFR-3_

- [ ] 2.3 Migrate phase-agent approval state writers
  - **Do**: Replace each agent's direct approval-state temp/move snippet with the common helper and preserve every unrelated state field.
  - **Files**: `plugins/ralph-specum/agents/research-analyst.md`, `plugins/ralph-specum/agents/product-manager.md`, `plugins/ralph-specum/agents/architect-reviewer.md`, `plugins/ralph-specum/agents/task-planner.md`
  - **Done when**: All four agents merge `awaitingApproval` through `locked-state.py` and perform no direct state move.
  - **Verify**: `! rg -n 'jq .*ralph-state|mv .*ralph-state' plugins/ralph-specum/agents/{research-analyst,product-manager,architect-reviewer,task-planner}.md`
  - **Commit**: `refactor(state): lock phase-agent approvals`
  - _Requirements: FR-3, FR-5, NFR-2, NFR-3_

- [ ] 2.4 Migrate Claude reference state operations
  - **Do**: Replace native task-map, modification-map, recovery, scanner, quick-mode, and worktree-copy state mutations with locked helper calls. Keep `quick-mode.md` behavior from task 1.7 and change only its state operations here.
  - **Files**: `plugins/ralph-specum/references/coordinator-pattern.md`, `plugins/ralph-specum/references/failure-recovery.md`, `plugins/ralph-specum/references/spec-scanner.md`, `plugins/ralph-specum/references/quick-mode.md`, `plugins/ralph-specum/references/branch-management.md`
  - **Done when**: Reference workflows perform no raw move, copy, or deletion of `.ralph-state.json`, and worktree transfer merges through the helper.
  - **Verify**: `! rg -n 'jq .*ralph-state|mv .*ralph-state|rm .*ralph-state|cp .*ralph-state' plugins/ralph-specum/references/{coordinator-pattern,failure-recovery,spec-scanner,quick-mode,branch-management}.md`
  - **Commit**: `refactor(state): lock Claude reference writers`
  - _Requirements: FR-3, FR-5, FR-6, NFR-2, NFR-3_

- [ ] 2.5 Add context, index, and dispatcher visibility
  - **Do**: Make resolved active prototypes, candidates, terminal records, quarantines, counts, and blocker status visible to context loading, indexing, quick guard, and the spec scanner. Make the executor refuse stale or blocked tasks without changing unrelated task behavior.
  - **Files**: `plugins/ralph-specum/hooks/scripts/load-spec-context.sh`, `plugins/ralph-specum/hooks/scripts/update-spec-index.sh`, `plugins/ralph-specum/hooks/scripts/quick-mode-guard.sh`, `plugins/ralph-specum/references/spec-scanner.md`, `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: Every dispatcher sees active blockers and stale indexes, configured roots work, and unrelated tasks remain eligible only after dependency and path checks.
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/{load-spec-context.sh,update-spec-index.sh,quick-mode-guard.sh} && rg -n 'activePrototypes|stale|prototype' plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `refactor(prototype): expose overlay state to dispatchers`
  - _Requirements: FR-3, FR-4, FR-5, NFR-3_

- [ ] 2.6 Complete reviewer and schema contracts
  - **Do**: Extend the reviewer for `artifactType: prototype`, deterministic pass/fail, exact candidate bytes, and cleanup-receipt validation. Add the terminal record frontmatter shape without adding prototype to the main phase enum.
  - **Files**: `plugins/ralph-specum/agents/spec-reviewer.md`, `plugins/ralph-specum-codex/agent-configs/spec-reviewer.toml.template`, `plugins/ralph-specum/schemas/spec.schema.json`, `plugins/ralph-specum-codex/schemas/spec.schema.json`
  - **Done when**: Valid prototype records pass both schemas, `phase: prototype` is limited to record artifacts, and reviewer rules require the exact candidate bytes that will publish.
  - **Verify**: `jq empty plugins/ralph-specum/schemas/spec.schema.json plugins/ralph-specum-codex/schemas/spec.schema.json && rg -n 'artifactType.*prototype|REVIEW_PASS|sourceDisposition' plugins/ralph-specum/agents/spec-reviewer.md plugins/ralph-specum-codex/agent-configs/spec-reviewer.toml.template`
  - **Commit**: `refactor(prototype): align review and schemas`
  - _Requirements: FR-3, FR-7, FR-8, NFR-5_

- [ ] 2.7 Complete Claude workflow and state references
  - **Do**: Document overlay transitions, immutable records, locked state, commit behavior, configured paths, and quick ownership in Claude skills and references.
  - **Files**: `plugins/ralph-specum/skills/spec-workflow/SKILL.md`, `plugins/ralph-specum/skills/spec-workflow/references/phase-transitions.md`, `plugins/ralph-specum/skills/smart-ralph/SKILL.md`, `plugins/ralph-specum/skills/smart-ralph/references/state-file-schema.md`
  - **Done when**: Claude references agree on overlay rather than a main phase and on locked mutations under resolved `basePath`.
  - **Verify**: `rg -l 'activePrototypes|prototype' plugins/ralph-specum/skills/spec-workflow/SKILL.md plugins/ralph-specum/skills/spec-workflow/references/phase-transitions.md plugins/ralph-specum/skills/smart-ralph/SKILL.md plugins/ralph-specum/skills/smart-ralph/references/state-file-schema.md | wc -l | grep -q '^4$'`
  - **Commit**: `docs(prototype): define Claude overlay contract`
  - _Requirements: FR-1, FR-3, FR-6, NFR-3_

- [ ] 2.8 Complete Codex workflow and state references
  - **Do**: Document matching overlay, locked state, path resolution, quick takeover, local-only evidence, and parity mappings for Codex.
  - **Files**: `plugins/ralph-specum-codex/references/workflow.md`, `plugins/ralph-specum-codex/references/state-contract.md`, `plugins/ralph-specum-codex/references/path-resolution.md`, `plugins/ralph-specum-codex/references/parity-matrix.md`
  - **Done when**: Codex references map every Claude behavior to its skill, helper, or hook without changing the contract.
  - **Verify**: `rg -l 'activePrototypes|prototype' plugins/ralph-specum-codex/references/{workflow,state-contract,path-resolution,parity-matrix}.md | wc -l | grep -q '^4$'`
  - **Commit**: `docs(prototype): define Codex overlay contract`
  - _Requirements: FR-1, FR-3, FR-6, FR-8, NFR-5_

- [ ] 2.9 Complete user and consumer documentation
  - **Do**: Document the optional overlay, normal choices, quick placement, source retention, current-checkout safety, local-only prototype evidence, resume/status behavior, and both entrypoint names. Add bootstrap guidance for downstream Codex installations.
  - **Files**: `README.md`, `plugins/ralph-specum-codex/README.md`, `plugins/ralph-specum-codex/assets/bootstrap/AGENTS.md`
  - **Done when**: A user can tell when prototype is suggested, what quick mode does, where records live, and which remote actions still need separate authority.
  - **Verify**: `rg -n 'prototype|current checkout|quick|remote' README.md plugins/ralph-specum-codex/README.md plugins/ralph-specum-codex/assets/bootstrap/AGENTS.md`
  - **Commit**: `docs(prototype): explain optional overlay workflow`
  - _Requirements: FR-1, FR-2, FR-6, FR-8, NFR-1_

- [ ] 2.10 Align both plugin versions at 4.11.0
  - **Do**: Bump only the modified Ralph Specum distributions and marketplace entry to the same new minor version `4.11.0`. Update fixed version assertions that otherwise encode the old baseline.
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugins/ralph-specum-codex/.codex-plugin/plugin.json`, `tests/interview-framework.bats`
  - **Done when**: All three published version fields are `4.11.0` and no applicable fixed assertion expects `4.9.1`, `4.10.0`, or `4.10.1`.
  - **Verify**: `test "$(jq -r .version plugins/ralph-specum/.claude-plugin/plugin.json)" = 4.11.0 && test "$(jq -r '.plugins[] | select(.name == "ralph-specum") | .version' .claude-plugin/marketplace.json)" = 4.11.0 && test "$(jq -r .version plugins/ralph-specum-codex/.codex-plugin/plugin.json)" = 4.11.0`
  - **Commit**: `chore(release): bump prototype capability to 4.11.0`
  - _Requirements: FR-8, NFR-5_

## Phase 3: Testing

- [ ] 3.1 Test locked state, ownership, paths, and races
  - **Do**: Add Bats coverage for concurrent merge/upsert/remove, compare-and-set builder claim, lease operations, phase merges, deletion refusal, configured roots, POSIX and Windows lock paths, stale Windows locks, lock timeout, quick publisher-only failure, crash recovery, and request versus builder execution counts.
  - **Files**: `tests/prototype-state.bats`
  - **Done when**: The tests prove no lost updates, no duplicate builder launch, no wrong-root writes, and compatible Codex merge behavior.
  - **Verify**: `bats tests/prototype-state.bats`
  - **Commit**: `test(prototype): cover locked overlay state`
  - _Requirements: FR-3, FR-5, FR-6, NFR-2, NFR-3, NFR-4_

- [ ] 3.2 Test immutable records and reviewed cleanup
  - **Do**: Add Bats coverage for exclusive candidate creation, collisions, exact-byte publication, malformed quarantine, reconciliation states, supersession, downstream selection, no-source records, remote gates, cleanup receipts, post-deletion review, missing-source resume, and immutable finals.
  - **Files**: `tests/prototype-records.bats`
  - **Done when**: No test path can overwrite a final record or publish unreviewed deleted-source bytes.
  - **Verify**: `bats tests/prototype-records.bats`
  - **Commit**: `test(prototype): cover immutable record publication`
  - _Requirements: FR-2, FR-3, FR-4, FR-6, NFR-3_

- [ ] 3.3 Test normal, quick, builder, and reviewer flows
  - **Do**: Add workflow tests for normal offers and decline, direct invocation, safe boundaries, capture choice, isolation failure, cancellation, handoff, duplicate and conflict resolution, one quick request, highest-risk selection, exact skip, oldest-blocker takeover, no user questions, one retry, logic and UI contracts, reviewer pass/fail, stale gates, and unconditional quick continuation to design.
  - **Files**: `tests/prototype-phase.bats`
  - **Done when**: Every FR-1, FR-2, FR-4, FR-6, and FR-7 acceptance path has a deterministic automated assertion.
  - **Verify**: `bats tests/prototype-phase.bats`
  - **Commit**: `test(prototype): cover lifecycle and quick flow`
  - _Requirements: FR-1, FR-2, FR-4, FR-5, FR-6, FR-7, NFR-1, NFR-4_

- [ ] 3.4 Test both harness control adapters
  - **Do**: Add explicit script tests for launch, wait, heartbeat, interrupt, status, soft timeout, hard timeout, unavailable control, and invalid identifier outcomes. Exercise both Claude and Codex adapters through deterministic stub commands; assert Codex accepts child `agentId` and rejects task `threadId` for internal builders.
  - **Files**: `tests/codex-platform-scripts.bats`, `tests/prototype-phase.bats`
  - **Done when**: Every adapter operation and failure outcome has an assertion on both helper paths, including timeout termination and unavailable-control behavior.
  - **Verify**: `bats tests/codex-platform-scripts.bats tests/prototype-phase.bats`
  - **Commit**: `test(prototype): cover harness control adapters`
  - _Requirements: FR-5, FR-7, FR-8, NFR-4, NFR-5_

- [ ] 3.5 Test Codex inventory, parity, and native Windows behavior
  - **Do**: Update fixed plugin inventories and counts for the skill, agent config, references, template, and helpers. Add a stdlib Windows unittest for lock directories, stale handling, flush-and-replace, unsupported directory `fsync`, exclusive publication, and final cleanup-receipt review. Add a `prototype-windows` `windows-latest` job that runs it.
  - **Files**: `tests/codex-plugin.bats`, `tests/codex-platform.bats`, `tests/codex-platform-scripts.bats`, `tests/test_prototype_windows.py`, `.github/workflows/bats-tests.yml`
  - **Done when**: Codex inventories are exact, shared behaviors are asserted, the unittest passes locally, and GitHub Actions has a native Windows job without requiring Bats on Windows.
  - **Verify**: `bats tests/codex-plugin.bats tests/codex-platform.bats tests/codex-platform-scripts.bats && python3 -m unittest tests/test_prototype_windows.py`
  - **Commit**: `test(prototype): verify Codex parity and Windows paths`
  - _Requirements: FR-8, NFR-2, NFR-5_

- [ ] 3.6 Repair and run focused regressions
  - **Do**: Update only the named assertions affected by the shared state helper, active blocker gates, or version. Preserve all prior phase and stop-loop behavior. Run the focused state, hook, integration, prototype, and Codex suites.
  - **Files**: `tests/state-management.bats`, `tests/stop-hook.bats`, `tests/integration.bats`, `tests/helpers/version-sync.sh`
  - **Done when**: Focused existing suites and all new prototype suites exit zero without weakening old assertions.
  - **Verify**: `bats tests/prototype-state.bats tests/prototype-records.bats tests/prototype-phase.bats tests/codex-plugin.bats tests/codex-platform.bats tests/codex-platform-scripts.bats tests/state-management.bats tests/stop-hook.bats tests/integration.bats && bash tests/helpers/version-sync.sh`
  - **Commit**: `test(prototype): preserve workflow regressions`
  - _Requirements: FR-8, NFR-5_

## Phase 4: Quality Gates

- [ ] V1 [VERIFY] Run the complete local quality gate
  - **Do**: Run all Bats files, the native Windows unittest on the local platform, version sync, shell syntax, schema parsing, whitespace checks, and a tracked-file audit. Restore any test-fixture mutation under `specs/.index/` to its exact pretest bytes before judging the tree.
  - **Files**: Read-only except fixes required by failing checks
  - **Done when**: Every command exits zero and only feature files remain changed.
  - **Verify**: `bats tests/*.bats && python3 -m unittest tests/test_prototype_windows.py && bash tests/helpers/version-sync.sh && bash -n plugins/ralph-specum/hooks/scripts/*.sh plugins/ralph-specum-codex/hooks/*.sh && jq empty plugins/ralph-specum/schemas/spec.schema.json plugins/ralph-specum-codex/schemas/spec.schema.json && git diff --check`
  - **Commit**: `fix(prototype): pass complete local quality gate` only if a focused fix is needed
  - _Requirements: FR-8, NFR-5_

- [ ] V2 [VERIFY] Audit the final contract and scope
  - **Do**: Verify one common state protocol, no hardcoded resolved spec path, no unguarded direct state writer, no top-level prototype phase enum, no automatic remote action, exact 4.11.0 version parity, native Windows CI, and no unrelated tracked change. Record the final commands and results in `.progress.md`.
  - **Files**: Read-only except `.progress.md`
  - **Done when**: The diff maps to the approved exact file map and every FR/NFR has passing test or static evidence.
  - **Verify**: `! rg -n 'specs/<name>' plugins/ralph-specum/commands/prototype.md plugins/ralph-specum/references/prototype-coordinator.md plugins/ralph-specum-codex/skills/ralph-specum-prototype/SKILL.md plugins/ralph-specum-codex/references/prototype-coordinator.md && bats tests/prototype-state.bats tests/prototype-records.bats tests/prototype-phase.bats && bash tests/helpers/version-sync.sh && git diff --check`
  - **Commit**: None
  - _Requirements: FR-1, FR-2, FR-3, FR-4, FR-5, FR-6, FR-7, FR-8, NFR-1, NFR-2, NFR-3, NFR-4, NFR-5_

## Coordinator-only completion

After all tasks are complete, the coordinator runs an independent implementation review, pushes this feature branch, creates the PR, waits for required CI, resolves every actionable human or automated review thread, and finishes only after a fresh GitHub query shows green required checks and zero unresolved actionable threads. The coordinator must not merge or close the PR.
