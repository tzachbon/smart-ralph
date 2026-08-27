# Normal-Mode Gates

> Used by: start.md, triage.md, research.md, requirements.md, design.md, tasks.md, and artifact agents

Run this sequence before every artifact-producing delegation:

```text
discover relevant skills -> load contracts -> layered grill -> explicit final approval -> gate check -> delegate
```

Use `scripts/phase_gate.py` for enforcement state. Use the spec `.ralph-state.json` for `start`, `research`, `requirements`, `design`, and `tasks`. Use the epic `.epic-state.json` for `triage`.

## 1. Resolve mode

Parse flags as exact argument tokens before other routing:

- Exact `--quick`: run `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/phase_gate.py" mode "$STATE" --quick`.
- Exact `--interactive`: run the same command with `--interactive`.
- Both tokens: stop with an error. Do not mutate mode.
- Neither token: run `mode "$STATE"` so legacy invalid quick state resets to interactive.

The aliases `-q`, prose such as `quick mode`, and substring matches never enable quick mode. `--quick` persists in the state until exact `--interactive` clears it. Read `quickMode` from the normalized state for every later branch.

## 2. Discover skills

Run catalog pass 1 after the state and spec or epic directory exist, before the first grill. Run pass 2 after `research.md` exists and before the requirements grill. A direct or resumed phase runs any applicable missing pass before its grill.

Build one catalog before matching:

1. Plugin skills: `${CLAUDE_PLUGIN_ROOT}/skills/*/SKILL.md`.
2. Project skills: `.agents/skills/*/SKILL.md` and `.claude/skills/*/SKILL.md`.
3. Current Claude harness user-global skills: `${HOME}/.claude/skills/*/SKILL.md` plus the active Skill tool catalog.

Select explicitly named skills first. Then select skills whose frontmatter description is materially relevant to the goal in pass 1. In pass 2, use the goal plus only the final `research.md` `## Executive Summary` section through the next level-2 heading. Use no other research section for relevance. Always select `ralph-specum:interview-framework` for normal mode.

When names duplicate:

- Use the source that the current harness resolves as active.
- Record every other source as shadowed.
- Do not load a shadowed copy.

Record unreadable files, missing descriptions, and selection reasons. Pass 2 retains pass 1 selections and adds newly relevant skills; it does not silently replace an active source.

Keep `discoveredSkills` as append-only discovery history. Preserve legacy entries. Add one entry per catalog decision with:

```json
{
  "pass": "pass1",
  "revision": "rev-1",
  "name": "skill-name",
  "activeSource": "/absolute/active/SKILL.md",
  "reason": "why selected or rejected",
  "shadowedSources": ["/absolute/shadowed/SKILL.md"],
  "outcome": "selected"
}
```

Use outcomes `selected`, `not-selected`, `unreadable`, or `missing-description`. Do not add or consult `invoked` as load proof. Only the current `phaseSkillLoad` proves loaded contracts. Mirror each pass/revision in `.progress.md`.

Each new pass revision records the complete selected set for that pass, including selections retained from pass 1. The helper requires the manifest's selected names and active sources to match that exact revision. Requirements, design, and tasks use pass 2 whenever `research.md` exists; otherwise they use pass 1. The other gated phases use pass 1.

## 3. Load contracts

Before every new or resumed grill, read in full:

- Every selected `SKILL.md` from the resolved active source.
- Every reference or resource that the selected skill requires for the current work.
- The interview-framework `SKILL.md`, `references/algorithm.md`, and `references/domain-modeling.md`.

Load optional examples and assets only when the current work needs them. Do not mark an unused optional file as required.

Preload only. Do not execute task actions prescribed by a domain skill during this step.

The interview-framework load is core. A core load failure blocks. A domain load failure records `partial_warned`, warns the user, and continues. Put unresolved material conflicts into the first interview frontier.

Apply clear instruction precedence automatically. Do not ask the user to resolve a conflict when system, developer, user, project, plugin, or selected-skill precedence already decides it. Put only unresolved material conflicts into the first frontier.

Create a manifest with this shape and record it:

```json
{
  "phase": "requirements",
  "interviewId": "requirements-1",
  "discoveryRevision": "rev-7",
  "contextDigest": "<64 lowercase hex>",
  "context": {"goal": "<exact goal>", "artifacts": []},
  "status": "complete",
  "selected": [
    {
      "name": "interview-framework",
      "core": true,
      "reason": "Required phase interview framework",
      "source": "/absolute/path/SKILL.md",
      "body": {"sha256": "<sha256>", "loadStatus": "loaded", "errors": []},
      "requiredResourceSources": ["/absolute/path/reference.md"],
      "requiredResources": [
        {"source": "/absolute/path/reference.md", "sha256": "<sha256>", "loadStatus": "loaded", "errors": []}
      ]
    }
  ],
  "warnings": [],
  "failures": [],
  "conflicts": [],
  "noDomainMatches": true,
  "artifactAgentLoads": []
}
```

Set `core: false` on every domain skill. `failures` must exactly equal every failed body/resource error. Use `complete` only when every selected body/resource loads and both `warnings` and `failures` are empty. Use `partial_warned` when all core sources load but domain sources fail; keep failed domain receipts in `selected` and make `warnings == failures == domain errors`. Use `core_failed` when any core source fails; make `failures` equal core plus domain errors, keep `warnings` equal domain errors only, and stop.

Every selected contract records `requiredResourceSources` after its complete `SKILL.md` is inspected. List every resource the skill marks required for the current work, and use an empty array only when that inspection finds none. `requiredResources` must contain one receipt for each inventory source in the same order; the helper rejects any omitted or added receipt.

The manifest has exactly one `core: true` selection: `${CLAUDE_PLUGIN_ROOT}/skills/interview-framework/SKILL.md`. Its resource inventory and receipts contain both `${CLAUDE_PLUGIN_ROOT}/skills/interview-framework/references/algorithm.md` and `${CLAUDE_PLUGIN_ROOT}/skills/interview-framework/references/domain-modeling.md`. A readable file elsewhere with `core: true` is not the core contract. A failed receipt uses `sha256: null`, `loadStatus: failed`, and nonempty `errors`; a loaded receipt uses the current source hash and empty errors. Submit `artifactAgentLoads` as an empty array. Only `record-agent-load` may append artifact-agent receipts after the manifest is accepted.

Write the JSON to a temporary file and run:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/phase_gate.py" record-skill-load "$STATE" --input "$MANIFEST_FILE"
```

## 4. Grill and approve

Load `${CLAUDE_PLUGIN_ROOT}/skills/interview-framework/SKILL.md` and follow it without redefining its question algorithm in the calling command. Persist each transition:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/phase_gate.py" begin-interview "$STATE" --phase "$PHASE" --interview-id "$INTERVIEW_ID" --round "$ROUND" --discovery-revision "$REVISION" --context-digest "$DIGEST"
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/phase_gate.py" open-frontier "$STATE" --round "$ROUND" --decision-id "$DECISION_ID_1" --decision-id "$DECISION_ID_2"
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/phase_gate.py" classify-reply --text "$REPLY"
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/phase_gate.py" record-answer "$STATE" --decision-id "$DECISION_ID" --answer "$ANSWER"
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/phase_gate.py" await-confirmation "$STATE" --decision-id "$CONFIRMATION_ID" --approach "$APPROACH"
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/phase_gate.py" confirm "$STATE" --decision-id "$CONFIRMATION_ID" --source "approve-and-delegate"
```

Compute `contextDigest` from immutable interview inputs only, as SHA-256 of this byte stream:

```text
frame("ralph-phase-context-v1")
frame(PHASE)
frame(GOAL)
frame(ARTIFACT_SOURCE_1) frame(ARTIFACT_BYTES_1)
...
```

`frame(BYTES)` is the ASCII decimal byte length, one colon byte, then the unmodified bytes. Encode the fixed marker, phase, exact goal snapshot, and absolute artifact source labels as UTF-8. Sort artifacts lexically by absolute source. Store the exact nonblank goal in `phaseSkillLoad.context.goal` and each artifact as an absolute `source` plus its lowercase SHA-256 in `phaseSkillLoad.context.artifacts`. The helper reads and hashes current artifact bytes, checks every artifact receipt, recomputes the digest at record, begin, delegation check, and agent-write check, and rejects any mismatch. When top-level `state.goal` exists, it is the canonical goal and must equal the snapshot. A legacy state without `goal` uses the persisted snapshot as its source of truth. Exclude interview answers, load receipts, discovery history, progress bookkeeping, and skill bytes.

Context artifacts are exact phase inputs: requirements includes `research.md` when present; design requires `requirements.md` and includes `research.md` when present; tasks requires `requirements.md` plus `design.md` and includes `research.md` when present. Start, triage, and research have no prior-artifact input. The helper rejects omitted, extra, missing, or newly applicable artifacts, so an approval cannot survive an upstream change.

On resume, reuse the same phase, interview ID, immutable digest, discovery revision, and current round. For a matching active interview, `begin-interview` returns `resumed: true` and preserves answers and pending IDs. It rejects terminal interviews and different active tuples. Call `open-frontier --round N` to re-ask pending decisions. Advance to exactly `N+1` only when no decision is pending. Never restart `begin-interview` with a new tuple merely because the user answered partially.

Call `open-frontier` for every decision ID before the native question call. This makes unanswered IDs remain pending when a response is partial.

Use `classify-reply` on the whole reply before recording any answer; it returns exactly `bare_skip`, `control_only`, or `substantive`. For a substantive reply, record only the answered pending IDs. For a control-only reply, leave the frontier unchanged. If the user chooses `Revise decisions` after the brief, call one `revise` transition with every affected ID, for example `revise "$STATE" --decision-id "$ID_1" --decision-id "$ID_2"`. Re-answer reopened decisions, call `await-confirmation` with the same final confirmation ID, and obtain canonical approval again.

For bare skip, use `skip "$STATE" --reason ... --assumption ... --decision-id skip-confirmation`. The helper moves to `awaiting_confirmation`; it does not authorize delegation. Present the defaulted brief, obtain explicit final approval, then call `confirm "$STATE" --decision-id skip-confirmation --source "approve-and-delegate"`. The helper promotes the terminal status to `skipped` only after that approval.

In exact quick mode, still run applicable discovery, reload every successfully selected contract, record the current manifest, then call `begin-interview` for the phase. The helper records `bypassed_quick`; do not ask questions.

If a newly recorded manifest changes the phase context, discovery revision, or selected contract provenance, prior terminal interview evidence is invalidated. Never reuse an approval across that manifest change.

## 5. Gate and delegate

Immediately before every artifact-agent `Task` call, run:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/phase_gate.py" check-delegation "$STATE" --phase "$PHASE" --interview-id "$INTERVIEW_ID" --discovery-revision "$REVISION" --context-digest "$DIGEST"
```

Stop on any nonzero exit. Add this exact marker to the Task prompt so the deterministic PreToolUse guard can repeat the check:

```text
[RALPH_PHASE_GATE]
state=<absolute state path>
phase=<phase>
interviewId=<interview ID>
discoveryRevision=<revision>
contextDigest=<64 lowercase hex>
```

Pass the full load manifest with the task and a unique `artifactAgentId` equal to that Task or teammate dispatch name. Require the artifact agent to reload every successfully loaded selected body and required resource. For every loaded source, call `record-agent-load` with that unique dispatch identity, source path, current SHA-256, `loadStatus: loaded`, and no errors. Then call `check-agent-write` with the same phase, interview ID, discovery revision, context digest, and unique identity immediately before the first artifact write. Parallel agents never share receipts. `Explore` remains read-only and may run without this marker.

## 6. Artifact approval

After the artifact is written, show the phase walkthrough and require explicit artifact approval. `apply the changes` delegates a revision and returns to the same artifact approval gate. It never advances the phase.
