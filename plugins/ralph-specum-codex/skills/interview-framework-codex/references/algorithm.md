# Codex phase interview algorithm

The existing `phase_gate.py` stays unchanged and remains the deterministic state boundary. Resolve its absolute path before starting a phase. Use the spec's `.ralph-state.json` as `STATE`. Triage uses the active epic's `.epic-state.json` instead.

## 1. Resolve mode

Run exactly one mode command at phase entry:

```text
python3 <phase-gate-script> mode STATE
python3 <phase-gate-script> mode STATE --quick
python3 <phase-gate-script> mode STATE --interactive
```

Only the exact `--quick` flag enables persistent quick mode. Only the exact `--interactive` flag clears it. Reject both flags together, `-q`, variants, and natural-language autonomy requests. A no-flag call resets legacy or invalid quick state to interactive.

For quick mode, create a fresh phase identity, complete the applicable discovery and contract-load steps below, then run `begin-interview`. The helper records `phaseInterview.status: "bypassed_quick"` from the exact quick authorization. Record the assumptions used and run `check-delegation` with that identity immediately before dispatch. Exact `--quick` preserves discovery, manifest, parent-delegation provenance, receipt recording, and `check-agent-write`. It skips frontier questions and final interview confirmation only.

## 2. Discover relevant skills

Run pass 1 after start setup and before the initial goal grill. Run pass 2 after the final research artifact and before requirements. A direct or resumed phase without its applicable pass runs that pass before continuing.

Collect metadata before selecting from:

- every plugin `skills/*/SKILL.md`
- project `.agents/skills/*/SKILL.md`
- project `.claude/skills/*/SKILL.md`
- the current Codex harness available-skills catalog

Always select an explicitly named skill. For duplicate names, use the active source resolved by the harness catalog and record every other candidate as shadowed in the active selection's `reason` and in `.progress.md`. Reserve manifest `warnings` for domain load errors that allow continuation. Record every failed body or resource error in `failures`. Select other domain skills by semantic relevance to the goal for pass 1. In pass 2, use the goal plus only the final `research.md` `## Executive Summary` section through the next level-2 heading. Use no other research section for relevance. Record `noDomainMatches: true` when only the core interview skill applies.

Append one `discoveredSkills` entry for every catalog decision in every pass. Each entry contains `pass`, `revision`, `name`, `activeSource`, `reason`, `shadowedSources`, and `outcome`. Keep the array cumulative and append-only. Each new pass revision repeats the complete current selected set, including selections retained from pass 1. Discovery reads metadata and selects contracts; it executes no skill action. Treat legacy `invoked` as history only. It never proves a current load; only `phaseSkillLoad` does. The helper requires selected manifest names and sources to match the applicable discovery revision exactly.

Increment `discoveryRevision` for a new applicable catalog pass. Create or retain an `interviewId` for the current phase attempt.

Compute `contextDigest` as SHA-256 of this byte stream:

```text
frame("ralph-phase-context-v1")
frame(PHASE)
frame(GOAL)
frame(ARTIFACT_SOURCE_1) frame(ARTIFACT_BYTES_1)
...
```

`frame(BYTES)` is the ASCII decimal byte length, one colon byte, then the unmodified bytes. Encode the fixed marker, phase, exact goal snapshot, and absolute artifact source labels as UTF-8. Sort artifacts lexically by absolute source. Store the exact nonblank goal in `phaseSkillLoad.context.goal` and each artifact as an absolute `source` plus its lowercase SHA-256 in `phaseSkillLoad.context.artifacts`. The helper reads and hashes current artifact bytes, checks every artifact receipt, recomputes the digest at record, begin, delegation check, and agent-write check, and rejects any mismatch. When top-level `state.goal` exists, it is the canonical goal and must equal the snapshot. A legacy state without `goal` uses the persisted snapshot as its source of truth. Exclude interview answers, load receipts, discovery history, progress bookkeeping, and skill bytes.

Use exact phase inputs: requirements includes `research.md` when present; design requires `requirements.md` and includes `research.md` when present; tasks requires `requirements.md` plus `design.md` and includes `research.md` when present. Start, triage, and research have no prior artifact. Requirements, design, and tasks use pass 2 whenever research exists and pass 1 otherwise; all other gated phases use pass 1.

Keep the tuple immutable while resuming an interview against the same inputs. Reload contracts, call `begin-interview` with the stored round, and preserve prior answers. Advance rounds through `open-frontier`. A changed goal or any included artifact byte starts a new tuple, new `interviewId`, and new round 1. Contract hashes live in `phaseSkillLoad`, not `contextDigest`; every gate re-verifies them, so changed contract bytes make the manifest stale and block reuse of terminal approval.

## 3. Reload contracts

Before each new or resumed grill, reload the complete body of every selected `SKILL.md` and every reference that the skill requires for the current work. Hash the bytes with SHA-256 and build this receipt:

```json
{
  "phase": "<phase>",
  "interviewId": "<id>",
  "discoveryRevision": 1,
  "contextDigest": "<sha256>",
  "context": {"goal": "<exact goal>", "artifacts": []},
  "status": "complete",
  "selected": [],
  "warnings": [],
  "failures": [],
  "conflicts": [],
  "noDomainMatches": false,
  "artifactAgentLoads": []
}
```

Each `selected` item contains `name`, `reason`, `source`, required `core: true|false`, a `body` receipt with `sha256`, `loadStatus`, and `errors`, `requiredResourceSources`, and matching `requiredResources` receipts with the same load fields. Build the source inventory only after reading the complete skill; list every resource it marks required for the current work, and use an empty array only when none exists. Receipt sources must match the inventory exactly and in order. Put this plugin's packaged `skills/interview-framework-codex/SKILL.md` first with `core: true`, and include its packaged `references/algorithm.md` and `references/domain-modeling.md` in both the inventory and receipts. A readable file elsewhere with `core: true` is not the core contract. Mark every domain skill `core: false`.

A loaded receipt has the current lowercase SHA-256 digest, `loadStatus: "loaded"`, and no errors. A failed receipt has `sha256: null`, `loadStatus: "failed"`, and at least one exact error. Never reuse a stale or guessed digest for a failed load.

Set status to:

- `complete` when every selected body and required resource loads, with empty `warnings` and `failures`.
- `partial_warned` when the core loads and one or more domain loads fail, with `warnings` and `failures` both equal to the domain errors.
- `core_failed` when this skill or either required core reference fails, with `failures` equal to all core and domain errors and `warnings` equal only to domain errors.

Record the payload with:

```text
python3 <phase-gate-script> record-skill-load STATE --input FILE
```

Stop on `core_failed`. Warn and continue on domain failures. Apply clear conflicts through the current harness instruction precedence and record the resolution in `conflicts`. Ask no question for a precedence-resolved conflict. Put only unresolved material conflicts in the first decision layer.

## 4. Traverse frontier rounds

Read the goal, prior artifacts, progress, loaded contracts, configured spec index, applicable `CONTEXT.md`, and persisted interview receipt. Build a decision graph of critical user decisions only. Apply `references/domain-modeling.md` throughout; update resolved project terms inline and create no ADR.

For each round:

1. Resolve facts by inspection.
2. Mark decisions already answered by the goal, prior phases, or persisted partial answers.
3. Find the whole currently unblocked critical frontier.
4. Open all IDs in the current batch before the native question:

```text
python3 <phase-gate-script> open-frontier STATE --round N --decision-id ID [--decision-id ID ...]
```

5. Ask that frontier through Codex native user input, in batches of at most three questions only because the tool caps a call at three.
6. Put the recommended option first. Give two or three viable choices with one-sentence tradeoffs.
7. Persist every returned answer before asking the next batch. Unanswered IDs remain pending.
8. Recompute the frontier until no critical decision remains.

Track nodes as open, investigating, resolved, or explicitly out of scope. Turn an `Other` response into a specific dependent decision, add branches exposed by answers, and never use a generic follow-up.

Begin or resume the interview with:

```text
python3 <phase-gate-script> begin-interview STATE --phase PHASE --interview-id ID --round N --discovery-revision REV --context-digest SHA256
```

On resume, use the same identity tuple and the stored round in `begin-interview`. The helper preserves asked, pending, and answered IDs plus assumptions. Re-open only the still-pending frontier with the same `open-frontier --round`. Use the next integer round only when asking a newly unblocked frontier; the helper permits the current round or current plus one and rejects gaps or regression.

Classify and persist each returned answer before the next frontier batch:

```text
python3 <phase-gate-script> classify-reply --text TEXT
python3 <phase-gate-script> record-answer STATE --decision-id ID --answer TEXT
python3 <phase-gate-script> record-answer STATE --decision-id ID --answer TEXT --assumption TEXT
```

`classify-reply` prints exactly `bare_skip`, `control_only`, or `substantive`. It strips polite wrappers only when the whole reply is otherwise a pure control. A `control_only` result leaves the active decision pending. Record only `substantive` answers. The helper keeps status `collecting` while decisions remain and maintains the asked, pending, and answered decision IDs. Re-call `open-frontier` with the same round and remaining pending IDs before re-asking them.

If the reply is bare `skip`, fill remaining critical decisions with recommended defaults, record each assumption, and run `skip STATE --reason TEXT --assumption TEXT --decision-id skip-confirmation`. This moves to final confirmation without authorizing delegation. A sentence that contains the word `skip` is normal answer text unless it is only the bare control word.

## 5. Obtain final approval

Present one compact decision ledger with selected choices, recommendations accepted or overridden, material tradeoffs, loaded-contract warnings, conflicts resolved, and assumptions. Record the final decision and approach:

```text
python3 <phase-gate-script> await-confirmation STATE --decision-id ID --approach TEXT
```

Ask one final native user-input question with these choices:

- `Approve and delegate (Recommended)`
- `Revise decisions`
- `Cancel`

Only the explicit first choice completes approval. Control-only replies do not. On approval, record status `complete` and the explicit source:

```text
python3 <phase-gate-script> confirm STATE --decision-id ID --source approve-and-delegate
```

If the user chooses `Revise decisions`, reopen every affected decision in one transition:

```text
python3 <phase-gate-script> revise STATE --decision-id ID [--decision-id ID ...]
```

`revise` requires `awaiting_confirmation`, retires the pending confirmation ID, clears the selected approach and bypass reason, and advances the round by one. Persist the revised answers, call `await-confirmation` again with the same final confirmation decision ID, and require the canonical confirmation above.

If the user chooses `Cancel`, leave the interview nonterminal and stop without delegation.

When the interview used bare skip, first record all resolved defaults through `record-answer`, then record the skip before asking for final approval:

```text
python3 <phase-gate-script> skip STATE --reason "user skipped remaining phase interview" --assumption TEXT --decision-id skip-confirmation
```

After the user explicitly approves, run:

```text
python3 <phase-gate-script> confirm STATE --decision-id skip-confirmation --source approve-and-delegate
```

The helper promotes the terminal status to `skipped` only after that confirmation.

Immediately before every affected transition or child dispatch, run the parent delegation check after confirmation:

```text
python3 <phase-gate-script> check-delegation STATE --phase PHASE --interview-id ID --discovery-revision REV --context-digest SHA256
```

Delegate immediately when the command succeeds. A failed normal-mode check ends this invocation rather than continuing. On the next explicit invocation, record a fresh manifest/interview identity before `begin-interview`; a matching in-progress interview that has not reached this failed boundary remains valid for resume.

## 6. Pass and enforce the manifest

Include the absolute gate script path, state path, full identity tuple, verbatim `phaseSkillLoad` manifest, and a unique dispatch identity in the artifact agent packet. Do not reuse the artifact agent type as the dispatch identity; each teammate run gets its own value.

The artifact agent performs these first actions before reading or writing the target artifact:

1. Reload every successfully loaded selected body and required resource from the passed manifest. Failed domain receipts remain recorded warnings and are not reloaded.
2. Verify each SHA-256 receipt.
3. Record one receipt per source with `record-agent-load STATE --input RECEIPT`.
4. Run the child write guard with the exact agent name:

```text
python3 <phase-gate-script> check-agent-write STATE --phase PHASE --interview-id ID --context-digest SHA256 --discovery-revision REV --agent UNIQUE_DISPATCH_ID
```

The coordinator has already run `check-delegation` immediately before creating the child and passed the current manifest in both interactive and quick mode. Keep `check-agent-write` as the last pre-write guard. Refuse artifact writes when it fails, a manifest source is missing, or a hash differs. During preload, collect contract constraints only. Start artifact work after every receipt is stored and `check-agent-write` succeeds.

## 7. Review the artifact

After the agent writes the artifact, validate the file and set `awaitingApproval: true`. Present the existing artifact approval choices.

- `approve current artifact` approves without starting a new phase.
- `continue to <named next step>` approves and enters that phase's discovery, reload, grill, and approval path.
- `request changes` or a concrete correction records revision feedback.
- `apply the changes` immediately delegates already-recorded revision feedback through a new unique dispatch, then redisplays and remains at artifact approval. Ask one focused change question only when no pending feedback exists.
- `continue`, `proceed`, and `go ahead` alone approve nothing.
