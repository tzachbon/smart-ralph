# Tasks: add-auto-flag

## Phase 1: Make It Work

Focus: Apply all file edits in dependency order. Skill-first (SKILL.md), then command layer, then hooks.

---

- [x] 1.1 Update smart-ralph SKILL.md with --auto definition
  - **Files**: `plugins/ralph-specum/skills/smart-ralph/SKILL.md`
  - **Do**:
    1. Replace the `--quick` row description to: "Run all planning phases autonomously (research, requirements, design, tasks), then stop before implementation"
    2. Add `--auto` row: "Run all phases including implementation autonomously, no stopping"
    3. Add mutual-exclusivity note: "--quick and --auto are mutually exclusive"
    4. Rename "Quick Mode" execution modes section to "Plan-Only Mode (--quick)" and add "Full Autonomous Mode (--auto)" section with the old Quick Mode description
    5. In Branch Management section: update "Quick mode: auto-create branch" to "Quick or auto mode: auto-create branch, no prompts"
  - **Done when**: SKILL.md defines both flags, documents mutual exclusivity, and no longer equates --quick with full autonomous execution
  - **Verify**: `grep -n "\-\-auto" plugins/ralph-specum/skills/smart-ralph/SKILL.md | grep -q "auto" && grep -n "mutually exclusive" plugins/ralph-specum/skills/smart-ralph/SKILL.md | grep -q "mutually" && echo PASS`
  - **Commit**: `feat(ralph-specum): document --auto flag and redefine --quick in smart-ralph skill`
  - _Requirements: FR-8, AC-4.1, AC-4.2, AC-4.3_
  - _Design: ralph-specum section 6_

---

- [x] 1.2 [P] Update intent-classification.md with --auto parsing
  - **Files**: `plugins/ralph-specum/references/intent-classification.md`
  - **Do**:
    1. Add `--auto` row to the Argument Parsing table
    2. Prepend mutual-exclusivity rule to the Commit Spec Flag Logic section: "If both --quick and --auto in $ARGUMENTS -> Error: --quick and --auto are mutually exclusive. Use one or the other."
    3. Add `--auto with goal/file -> Auto mode flow (full autonomous)` to the Routing Summary table
    4. Add `Both --quick and --auto -> Error: mutually exclusive` to the Routing Summary table
    5. Add --auto to the examples list
  - **Done when**: intent-classification.md documents --auto parsing, mutual-exclusivity rule appears before commitSpec logic, routing table covers all four flag combinations
  - **Verify**: `grep -n "\-\-auto" plugins/ralph-specum/references/intent-classification.md | grep -q "auto" && grep -n "mutually exclusive" plugins/ralph-specum/references/intent-classification.md | grep -q "mutually" && echo PASS`
  - **Commit**: `feat(ralph-specum): add --auto to intent-classification reference`
  - _Requirements: FR-4, AC-3.1_
  - _Design: ralph-specum section 5_

- [x] 1.3 [P] Update quick-mode.md to branch on --quick vs --auto
  - **Files**: `plugins/ralph-specum/references/quick-mode.md`
  - **Do**:
    1. Add "Mode Selector" section at top: "This reference is used for both --quick (plan-only) and --auto (full autonomous) flows. The flows are identical through the Tasks Phase. They diverge at the Transition to Execution step."
    2. In the state-write step (step 5): branch on mode -- `--quick: { quickMode: true, autoMode: false, ... }` / `--auto: { quickMode: false, autoMode: true, ... }`
    3. In the Transition to Execution step (step 16): add fork. --quick path: set `awaitingApproval: true`, output "Plan complete for '$name'. Run /ralph-specum:implement to execute, or review tasks.md first.", STOP. --auto path: existing behavior (count tasks, transition to execution, invoke spec-executor).
    4. Rename "Quick Mode Directive" header to "Autonomous Mode Directive"
  - **Done when**: quick-mode.md has a Mode Selector section, step 16 forks by flag, --quick path sets awaitingApproval and stops without invoking spec-executor
  - **Verify**: `grep -n "Mode Selector" plugins/ralph-specum/references/quick-mode.md | grep -q "Mode" && grep -n "awaitingApproval" plugins/ralph-specum/references/quick-mode.md | grep -q "awaitingApproval" && grep -n "Autonomous Mode Directive" plugins/ralph-specum/references/quick-mode.md | grep -q "Autonomous" && echo PASS`
  - **Commit**: `feat(ralph-specum): split quick-mode.md into --quick (plan-only) and --auto (full autonomous) paths`
  - _Requirements: FR-1, FR-5, AC-1.3, AC-1.5_
  - _Design: ralph-specum section 2_

---

- [ ] 1.4 [VERIFY] Quality checkpoint
  - **Do**: Verify the three files edited so far have no obvious broken references
  - **Verify**: `grep -rn "autoMode" plugins/ralph-specum/skills/smart-ralph/SKILL.md plugins/ralph-specum/references/intent-classification.md plugins/ralph-specum/references/quick-mode.md | grep -q "autoMode" && echo PASS`
  - **Done when**: All three files mention autoMode
  - **Commit**: none

---

- [x] 1.5 Update commands/start.md (ralph-specum)
  - **Files**: `plugins/ralph-specum/commands/start.md`
  - **Do**:
    1. Add `--auto` to the argument-hint line alongside existing flags
    2. In Step 2 (Quick Mode Check): expand to detect both flags. Add mutual-exclusivity check first: if both present, output error and STOP before creating any files. Then route --quick to Step 5 Quick Mode Flow (plan-only), --auto to Step 5 Auto Mode Flow (full autonomous).
    3. In state initialization template: add `"autoMode": false` field alongside existing `"quickMode": false`
    4. Update Step 5 summary line to distinguish plan-only (--quick) from full autonomous (--auto)
    5. Update the "Stop After Each Subagent" exception note from `--quick` to `--quick or --auto`
  - **Done when**: start.md argument-hint includes --auto, mutual-exclusivity check precedes flag routing, state template includes autoMode field
  - **Verify**: `grep -n "\-\-auto" plugins/ralph-specum/commands/start.md | grep -q "auto" && grep -n "autoMode" plugins/ralph-specum/commands/start.md | grep -q "autoMode" && grep -n "mutually exclusive" plugins/ralph-specum/commands/start.md | grep -q "mutually" && echo PASS`
  - **Commit**: `feat(ralph-specum): add --auto flag parsing and mutual-exclusivity check to start.md`
  - _Requirements: FR-2, FR-3, AC-2.1, AC-3.1, AC-3.2_
  - _Design: ralph-specum section 1_

---

- [x] 1.6 [P] Update stop-watcher.sh (ralph-specum)
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Do**:
    1. After the existing `QUICK_MODE` read (line ~146), add: `AUTO_MODE=$(jq -r '.autoMode // false' "$STATE_FILE" 2>/dev/null || echo "false")`
    2. In the quick mode guard block (lines ~159-184): replace the `if [ "$QUICK_MODE" = "true" ]` condition with a merged AUTONOMOUS_MODE variable:
       ```bash
       AUTONOMOUS_MODE="false"
       if [ "$QUICK_MODE" = "true" ] || [ "$AUTO_MODE" = "true" ]; then
           AUTONOMOUS_MODE="true"
       fi
       ```
       Then use `if [ "$AUTONOMOUS_MODE" = "true" ] && [ "$PHASE" != "execution" ]`
    3. Update the REASON string: replace "Quick mode active" with "Autonomous mode active"
    4. Update the jq `--arg msg` string: replace "quick mode" with "autonomous mode"
  - **Done when**: stop-watcher reads autoMode, planning guard blocks when either quickMode or autoMode is true, log messages say "autonomous mode"
  - **Verify**: `grep -n "AUTO_MODE" plugins/ralph-specum/hooks/scripts/stop-watcher.sh | grep -q "AUTO_MODE" && grep -n "AUTONOMOUS_MODE" plugins/ralph-specum/hooks/scripts/stop-watcher.sh | grep -q "AUTONOMOUS_MODE" && echo PASS`
  - **Commit**: `feat(ralph-specum): extend stop-watcher planning guard to cover --auto flag`
  - _Requirements: FR-5, FR-6, AC-1.7, AC-2.7_
  - _Design: ralph-specum section 3_

- [x] 1.7 [P] Update quick-mode-guard.sh (ralph-specum)
  - **Files**: `plugins/ralph-specum/hooks/scripts/quick-mode-guard.sh`
  - **Do**:
    1. After the existing `QUICK_MODE` read line, add: `AUTO_MODE=$(jq -r '.autoMode // false' "$STATE_FILE" 2>/dev/null || echo "false")`
    2. Replace the `if [ "$QUICK_MODE" != "true" ]` guard with: `if [ "$QUICK_MODE" != "true" ] && [ "$AUTO_MODE" != "true" ]; then exit 0; fi`
    3. Update the systemMessage to: "Autonomous mode active: do NOT ask the user any questions. Make opinionated decisions autonomously. Choose the simplest, most conventional approach."
  - **Done when**: guard blocks AskUserQuestion when either quickMode or autoMode is true; passes through when both are false
  - **Verify**: `grep -n "AUTO_MODE" plugins/ralph-specum/hooks/scripts/quick-mode-guard.sh | grep -q "AUTO_MODE" && grep -n "Autonomous mode" plugins/ralph-specum/hooks/scripts/quick-mode-guard.sh | grep -q "Autonomous" && echo PASS`
  - **Commit**: `feat(ralph-specum): extend quick-mode-guard to block AskUserQuestion in --auto mode`
  - _Requirements: FR-7, AC-1.6, AC-2.6_
  - _Design: ralph-specum section 4_

---

- [ ] 1.8 [VERIFY] Quality checkpoint: ralph-specum changes consistent
  - **Do**: Verify all ralph-specum files reference autoMode consistently
  - **Verify**: `grep -rn "autoMode" plugins/ralph-specum/commands/start.md plugins/ralph-specum/hooks/scripts/stop-watcher.sh plugins/ralph-specum/hooks/scripts/quick-mode-guard.sh | wc -l | xargs -I{} sh -c '[ {} -ge 4 ] && echo PASS || echo FAIL'`
  - **Done when**: At least 4 autoMode references across the three hook/command files
  - **Commit**: none

---

- [x] 1.9 Update commands/start.md (ralph-speckit)
  - **Files**: `plugins/ralph-speckit/commands/start.md`
  - **Do**:
    1. After the Parse Arguments section, add a "Flag Parsing" block: detect --quick (plan-only) and --auto (full autonomous). Add mutual-exclusivity check: if both present, output "Error: --quick and --auto are mutually exclusive. Use one or the other." and STOP before creating any feature directory.
    2. In the Initialize State File block: add `"quickMode": false` and `"autoMode": false` fields. Set `quickMode: true` when --quick detected; set `autoMode: true` when --auto detected.
    3. After state init, add post-init routing: if quickMode=true or autoMode=true, skip interactive prompts and run all spec phases sequentially. If quickMode=true after tasks phase: set awaitingApproval=true, output completion message, STOP. If autoMode=true: transition to execution.
  - **Done when**: start.md has flag parsing with mutual-exclusivity check, state init includes both fields, post-init routing block handles both autonomous modes
  - **Verify**: `grep -n "quickMode" plugins/ralph-speckit/commands/start.md | grep -q "quickMode" && grep -n "autoMode" plugins/ralph-speckit/commands/start.md | grep -q "autoMode" && grep -n "mutually exclusive" plugins/ralph-speckit/commands/start.md | grep -q "mutually" && echo PASS`
  - **Commit**: `feat(ralph-speckit): add --quick and --auto flag parsing to start.md`
  - _Requirements: FR-9, AC-5.1, AC-5.2_
  - _Design: ralph-speckit section 1_

---

- [ ] 1.10 [P] Update stop-watcher.sh (ralph-speckit)
  - **Files**: `plugins/ralph-speckit/hooks/scripts/stop-watcher.sh`
  - **Do**:
    1. After the existing state reads (PHASE, TASK_INDEX, etc.), add reads for both flags:
       ```bash
       QUICK_MODE=$(jq -r '.quickMode // false' "$STATE_FILE" 2>/dev/null || echo "false")
       AUTO_MODE=$(jq -r '.autoMode // false' "$STATE_FILE" 2>/dev/null || echo "false")
       ```
    2. After the global iteration check, add a planning phase guard block (mirrors ralph-specum pattern):
       ```bash
       if { [ "$QUICK_MODE" = "true" ] || [ "$AUTO_MODE" = "true" ]; } && [ "$PHASE" != "execution" ]; then
           STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
           if [ "$STOP_HOOK_ACTIVE" = "true" ]; then exit 0; fi
           jq -n --arg reason "Autonomous mode active — continue spec phase: $PHASE for $FEATURE_NAME." \
                 --arg msg "Ralph-speckit autonomous mode: continue $PHASE phase" \
             '{"decision": "block", "reason": $reason, "systemMessage": $msg}'
           exit 0
       fi
       ```
    3. In the execution loop block (line ~129), add an `awaitingApproval` check before the continuation prompt:
       ```bash
       AWAITING=$(jq -r '.awaitingApproval // false' "$STATE_FILE" 2>/dev/null || echo "false")
       if [ "$AWAITING" = "true" ]; then
           echo "[ralph-speckit] awaitingApproval=true, allowing stop for user gate" >&2
           exit 0
       fi
       ```
  - **Done when**: stop-watcher reads quickMode and autoMode, blocks during planning phases for either autonomous mode, and checks awaitingApproval before continuing execution loop
  - **Verify**: `grep -n "QUICK_MODE\|AUTO_MODE\|awaitingApproval" plugins/ralph-speckit/hooks/scripts/stop-watcher.sh | wc -l | xargs -I{} sh -c '[ {} -ge 3 ] && echo PASS || echo FAIL'`
  - **Commit**: `feat(ralph-speckit): add autonomous mode planning guard and awaitingApproval check to stop-watcher`
  - _Requirements: FR-9, AC-5.3, AC-5.4_
  - _Design: ralph-speckit section 2_

- [x] 1.11 [P] Create quick-mode-guard.sh (ralph-speckit) and register hook
  - **Files**: `plugins/ralph-speckit/hooks/scripts/quick-mode-guard.sh` (new), `plugins/ralph-speckit/.claude-plugin/plugin.json`
  - **Do**:
    1. Create `plugins/ralph-speckit/hooks/scripts/quick-mode-guard.sh` mirroring the ralph-specum guard but using `.speckit-state.json` and `.specify/specs/$FEATURE_NAME/` path:
       ```bash
       #!/usr/bin/env bash
       # PreToolUse hook: Block AskUserQuestion in autonomous modes (quickMode or autoMode)
       set -euo pipefail
       INPUT=$(cat)
       command -v jq >/dev/null 2>&1 || exit 0
       CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)
       [ -z "$CWD" ] && exit 0
       CURRENT_FEATURE_FILE="$CWD/.specify/.current-feature"
       [ ! -f "$CURRENT_FEATURE_FILE" ] && exit 0
       FEATURE_NAME=$(cat "$CURRENT_FEATURE_FILE" 2>/dev/null | tr -d '[:space:]')
       [ -z "$FEATURE_NAME" ] && exit 0
       STATE_FILE="$CWD/.specify/specs/$FEATURE_NAME/.speckit-state.json"
       [ ! -f "$STATE_FILE" ] && exit 0
       QUICK_MODE=$(jq -r '.quickMode // false' "$STATE_FILE" 2>/dev/null || echo "false")
       AUTO_MODE=$(jq -r '.autoMode // false' "$STATE_FILE" 2>/dev/null || echo "false")
       if [ "$QUICK_MODE" != "true" ] && [ "$AUTO_MODE" != "true" ]; then exit 0; fi
       jq -n '{"hookSpecificOutput": {"permissionDecision": "deny"}, "systemMessage": "Autonomous mode active: do NOT ask the user any questions. Make opinionated decisions autonomously."}'
       ```
    2. Make the new script executable: `chmod +x plugins/ralph-speckit/hooks/scripts/quick-mode-guard.sh`
    3. In `plugins/ralph-speckit/.claude-plugin/plugin.json`, add a `hooks` array with the new entry:
       ```json
       "hooks": [
         {
           "event": "PreToolUse",
           "matcher": "AskUserQuestion",
           "command": "hooks/scripts/quick-mode-guard.sh"
         }
       ]
       ```
    4. Bump ralph-speckit version in plugin.json (patch: 0.5.2 -> 0.5.3)
  - **Done when**: guard script exists, is executable, plugin.json registers it as a PreToolUse hook
  - **Verify**: `[ -x plugins/ralph-speckit/hooks/scripts/quick-mode-guard.sh ] && grep -q "AskUserQuestion" plugins/ralph-speckit/.claude-plugin/plugin.json && echo PASS`
  - **Commit**: `feat(ralph-speckit): add AskUserQuestion guard for autonomous modes`
  - _Requirements: FR-9, AC-5.5_
  - _Design: ralph-speckit sections 3 and 4_

---

- [ ] 1.12 [VERIFY] Quality checkpoint: ralph-speckit changes consistent
  - **Do**: Verify speckit state file, hook, and plugin.json are all coherent
  - **Verify**: `grep -rn "autoMode\|quickMode" plugins/ralph-speckit/commands/start.md plugins/ralph-speckit/hooks/scripts/stop-watcher.sh plugins/ralph-speckit/hooks/scripts/quick-mode-guard.sh | grep -q "autoMode" && echo PASS`
  - **Done when**: autoMode appears in all three speckit files
  - **Commit**: none

---

- [x] 1.13 [P] Update ralph-specum-codex skills
  - **Files**: `plugins/ralph-specum-codex/skills/ralph-specum-start/SKILL.md`, `plugins/ralph-specum-codex/skills/ralph-specum/SKILL.md`
  - **Do**:
    1. In `ralph-specum-start/SKILL.md` Step 1 (parse): add `--auto` to the flag list. Add mutual-exclusivity check: "If both --quick and --auto present: Respond 'Error: --quick and --auto are mutually exclusive. Use one or the other.' STOP."
    2. In `ralph-specum-start/SKILL.md` Step 7 (state initialization): add `autoMode` field. Set `quickMode: true, autoMode: false` for --quick; `quickMode: false, autoMode: true` for --auto.
    3. In `ralph-specum-start/SKILL.md` Step 11 (quick mode behavior): split into two cases. --quick: generate all artifacts autonomously, then set awaitingApproval: true, output "Plan complete. Run /ralph-specum:implement to execute.", STOP. --auto: generate all artifacts autonomously then continue into implementation without stopping (current --quick behavior).
    4. In `ralph-specum/SKILL.md` Core Rules section: update rule 12 to distinguish --quick (plan-only) from --auto (full autonomous) and note mutual exclusivity. Update rule 7 to add `autoMode` to the preserve list alongside `quickMode`.
  - **Done when**: ralph-specum-start/SKILL.md handles both flags with mutual-exclusivity check and split step 11; ralph-specum/SKILL.md rules 7 and 12 reference autoMode
  - **Verify**: `grep -rn "autoMode\|mutually exclusive" plugins/ralph-specum-codex/skills/ | wc -l | xargs -I{} sh -c '[ {} -ge 4 ] && echo PASS || echo FAIL'`
  - **Commit**: `feat(ralph-specum-codex): add --auto flag and split --quick/--auto behavior in skills`
  - _Requirements: FR-10, AC-6.1, AC-6.2, AC-6.3, AC-6.4_
  - _Design: ralph-specum-codex sections 1 and 2_

---

- [ ] 1.14 Bump plugin versions in marketplace.json
  - **Files**: `.claude-plugin/marketplace.json`, `plugins/ralph-specum/.claude-plugin/plugin.json`
  - **Do**:
    1. Bump ralph-specum version: 4.9.1 -> 4.10.0 (minor: new --auto feature) in `plugins/ralph-specum/.claude-plugin/plugin.json`
    2. Update ralph-specum entry in `.claude-plugin/marketplace.json` to match: 4.9.1 -> 4.10.0
    3. Update ralph-speckit entry in `.claude-plugin/marketplace.json` to match plugin.json: 0.5.2 -> 0.5.3
    4. If ralph-specum-codex has an entry in marketplace.json, bump its version too (patch)
  - **Done when**: ralph-specum is 4.10.0 in both files, ralph-speckit is 0.5.3 in both files
  - **Verify**: `grep -A2 '"ralph-specum"' .claude-plugin/marketplace.json | grep -q "4.10.0" && grep -A2 '"ralph-speckit"' .claude-plugin/marketplace.json | grep -q "0.5.3" && echo PASS`
  - **Commit**: `chore: bump ralph-specum to 4.10.0 and ralph-speckit to 0.5.3 for --auto flag`
  - _Design: Implementation Steps 13_

---

## Phase 2: Verification

- [ ] V4 [VERIFY] Full AC checklist
  - **Do**:
    1. AC-1.1/2.1: `grep -rn "\-\-auto\|\-\-quick" plugins/ralph-specum/commands/start.md plugins/ralph-speckit/commands/start.md plugins/ralph-specum-codex/skills/ralph-specum-start/SKILL.md | grep -q "auto" && echo AC-1.1-2.1-PASS`
    2. AC-3.1/3.3: `grep -rn "mutually exclusive" plugins/ralph-specum/commands/start.md plugins/ralph-speckit/commands/start.md plugins/ralph-specum-codex/skills/ralph-specum-start/SKILL.md | wc -l | xargs -I{} sh -c '[ {} -ge 3 ] && echo AC-3.1-3.3-PASS || echo AC-3.1-3.3-FAIL'`
    3. AC-1.4/2.4: `grep -rn "autoMode" plugins/ralph-specum/commands/start.md plugins/ralph-specum/references/quick-mode.md | grep -q "autoMode" && echo AC-1.4-2.4-PASS`
    4. AC-5.5: `[ -x plugins/ralph-speckit/hooks/scripts/quick-mode-guard.sh ] && grep -q "AskUserQuestion" plugins/ralph-speckit/.claude-plugin/plugin.json && echo AC-5.5-PASS`
    5. AC-4.1/4.2/4.3: `grep -n "mutually exclusive\|--auto\|--quick" plugins/ralph-specum/skills/smart-ralph/SKILL.md | wc -l | xargs -I{} sh -c '[ {} -ge 3 ] && echo AC-4-PASS || echo AC-4-FAIL'`
  - **Verify**: All 5 checks above print PASS
  - **Done when**: Every AC outputs PASS
  - **Commit**: none

- [ ] V5 [VERIFY] No broken cross-references
  - **Do**:
    1. Verify quick-mode.md is still referenced correctly from start.md: `grep -n "quick-mode" plugins/ralph-specum/commands/start.md | grep -q "quick-mode" && echo PASS`
    2. Verify stop-watcher.sh in ralph-specum still references QUICK_MODE for backward compat: `grep -n "QUICK_MODE" plugins/ralph-specum/hooks/scripts/stop-watcher.sh | grep -q "QUICK_MODE" && echo PASS`
    3. Verify ralph-speckit plugin.json is valid JSON: `jq . plugins/ralph-speckit/.claude-plugin/plugin.json > /dev/null && echo PASS`
    4. Verify ralph-specum plugin.json is valid JSON: `jq . plugins/ralph-specum/.claude-plugin/plugin.json > /dev/null && echo PASS`
  - **Verify**: All 4 checks print PASS
  - **Done when**: No broken references, all JSON files parse cleanly
  - **Commit**: none

## Phase 3: PR

- [ ] 3.1 Create PR
  - **Do**:
    1. Verify branch: `git branch --show-current`
    2. Push: `git push -u origin $(git branch --show-current)`
    3. Create PR: `gh pr create --title "feat: add --auto flag, redefine --quick as plan-only" --body "$(cat <<'EOF'
## Summary

- Redefines \`--quick\` as plan-only mode: runs all 4 planning phases autonomously then stops before implementation
- Adds \`--auto\` as full autonomous mode (what \`--quick\` currently does)
- Applies both flags across ralph-specum, ralph-speckit, and ralph-specum-codex
- \`--quick\` and \`--auto\` are mutually exclusive; combining them errors immediately

## Migration

Existing \`--quick\` users: replace with \`--auto\` to restore the old behavior.

## Files changed

- ralph-specum: start.md, quick-mode.md, intent-classification.md, stop-watcher.sh, quick-mode-guard.sh, smart-ralph SKILL.md
- ralph-speckit: start.md, stop-watcher.sh, quick-mode-guard.sh (new), plugin.json
- ralph-specum-codex: ralph-specum-start/SKILL.md, ralph-specum/SKILL.md
- marketplace.json, plugin.json (version bumps)
EOF
)"`
  - **Verify**: `gh pr view --json url | jq -r .url`
  - **Done when**: PR created, URL returned
  - **Commit**: none

- [ ] 3.2 [VERIFY] CI passes
  - **Do**: `gh pr checks --watch`
  - **Verify**: All checks green
  - **Done when**: No failing checks
  - **Commit**: none (fix and push if checks fail)

## Notes

- **Backward compat**: Old state files without `autoMode` field work fine. All reads use `jq -r '.autoMode // false'`.
- **Key asymmetry**: `--quick` sets `awaitingApproval: true` after tasks phase (coordinator does this, not stop-watcher). Stop-watcher already exits 0 when awaitingApproval=true, so no stop-watcher change is needed for the plan-only stop behavior.
- **ralph-specum-codex**: No shell hooks to modify. Intent detection only.
- **ralph-speckit plugin.json**: Currently has no `hooks` array at all. Task 1.11 adds it fresh.
