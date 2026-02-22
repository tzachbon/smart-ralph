---
generated: auto
---

# Tasks: Smart Skill Swap & Retry

## Phase 1: Make It Work (POC)

Focus: Get skill discovery working end-to-end in both normal and quick mode. Accept inline duplication between the two files -- we can DRY up later if warranted.

- [x] 1.1 Add discoveredSkills to state initialization in start.md (normal mode)
  - **Do**:
    1. Open `plugins/ralph-specum/commands/start.md`
    2. In Step 7 (New Flow), add `"discoveredSkills": []` to the `.ralph-state.json` initialization JSON block (after `quickMode`)
  - **Files**: `plugins/ralph-specum/commands/start.md`
  - **Done when**: The JSON block in start.md step 7 includes `"discoveredSkills": []`
  - **Verify**: `grep -c 'discoveredSkills' plugins/ralph-specum/commands/start.md` returns >= 1
  - **Commit**: `feat(ralph-specum): add discoveredSkills to normal mode state init`
  - _Requirements: FR-5, AC-3.1_
  - _Design: State Schema Changes_

- [x] 1.2 Add discoveredSkills to state initialization in quick-mode.md
  - **Do**:
    1. Open `plugins/ralph-specum/references/quick-mode.md`
    2. In step 5 (Write .ralph-state.json), add `"discoveredSkills": []` to the JSON block (after `quickMode`)
  - **Files**: `plugins/ralph-specum/references/quick-mode.md`
  - **Done when**: The JSON block in quick-mode.md step 5 includes `"discoveredSkills": []`
  - **Verify**: `grep -c 'discoveredSkills' plugins/ralph-specum/references/quick-mode.md` returns >= 1
  - **Commit**: `feat(ralph-specum): add discoveredSkills to quick mode state init`
  - _Requirements: FR-5, AC-3.1_
  - _Design: State Schema Changes_

- [x] 1.3 Add Skill Discovery Pass 1 to start.md (normal mode, Step 2.5)
  - **Do**:
    1. Open `plugins/ralph-specum/commands/start.md`
    2. Insert a new section `## Step 2.5: Skill Discovery Pass 1` between the "Quick Mode Check" subsection (after Step 2) and Step 3 (Scan Existing Specs)
    3. Include the full inline discovery instructions from design.md "Discovery Instructions Block" template, configured for Pass 1:
       - Context text: goal text only
       - matchedAt: `"start"`
       - Tokenization rules (lowercase, hyphens->spaces, strip punctuation, split whitespace, remove stopwords)
       - Threshold: overlap >= 2 words
       - Skip skills already invoked
       - Invoke via `Skill({ skill: "ralph-specum:<name>" })`
       - Update `.ralph-state.json` discoveredSkills array
       - Append `## Skill Discovery` section to `.progress.md` with match details
    4. Add a note that this step runs in normal mode only (quick mode skips to Step 5)
  - **Files**: `plugins/ralph-specum/commands/start.md`
  - **Done when**: Step 2.5 exists between Quick Mode Check and Step 3, contains full tokenization rules, matching algorithm, state update, and progress logging instructions
  - **Verify**: `grep -A2 'Step 2.5' plugins/ralph-specum/commands/start.md | head -3` shows the section header
  - **Commit**: `feat(ralph-specum): add skill discovery pass 1 to normal mode`
  - _Requirements: FR-1, FR-2, FR-3, AC-1.1, AC-1.2, AC-1.3, AC-1.5_
  - _Design: Discovery Instructions Block, Insertion Points (Normal Mode)_

- [x] 1.4 [VERIFY] Quality checkpoint: grep for consistent terminology
  - **Do**: Verify start.md uses consistent naming (discoveredSkills, matchedAt, invoked) matching design.md
  - **Verify**: `grep -c 'discoveredSkills' plugins/ralph-specum/commands/start.md` returns >= 2 (init + pass 1) AND `grep -c 'matchedAt' plugins/ralph-specum/commands/start.md` returns >= 1
  - **Done when**: Terminology matches design spec
  - **Commit**: `chore(ralph-specum): fix terminology` (only if fixes needed)

- [x] 1.5 Add Skill Discovery Pass 2 to start.md (normal mode, post-research)
  - **Do**:
    1. Open `plugins/ralph-specum/commands/start.md`
    2. In the New Flow section, insert a new step after step 11 (Team Research Phase) and before step 12 (STOP/walkthrough). Renumber if needed, or insert as step 11.5
    3. Include the full inline discovery instructions configured for Pass 2:
       - Context text: goal text + Executive Summary section from research.md
       - matchedAt: `"post-research"`
       - Same tokenization rules as Pass 1
       - Skip skills already in discoveredSkills with `invoked: true`
       - Invoke newly matched skills
       - Update state
       - Append `### Post-Research Retry` subsection to `.progress.md`
  - **Files**: `plugins/ralph-specum/commands/start.md`
  - **Done when**: Post-research pass exists after research and before walkthrough/STOP, references Executive Summary as context source, skips already-invoked skills
  - **Verify**: `grep -c 'Post-Research' plugins/ralph-specum/commands/start.md` returns >= 1
  - **Commit**: `feat(ralph-specum): add skill discovery pass 2 to normal mode`
  - _Requirements: FR-4, FR-7, AC-2.1, AC-2.2, AC-2.3_
  - _Design: Discovery Instructions Block, Insertion Points (Normal Mode)_

- [x] 1.6 Add Skill Discovery Pass 1 to quick-mode.md (Step 8.5)
  - **Do**:
    1. Open `plugins/ralph-specum/references/quick-mode.md`
    2. In the Quick Mode Execution Sequence, insert step 8.5 between step 8 (Update Spec Index) and step 9 (Goal Type Detection)
    3. Add the step as: `8.5. Skill Discovery Pass 1: scan skills, match against goal text, invoke matches`
    4. Include the full inline discovery instructions (same as start.md Pass 1 but self-contained in this file):
       - Context text: goal text only
       - matchedAt: `"start"`
       - Full tokenization rules
       - Threshold >= 2, skip already-invoked
       - Invoke, update state, log to progress
  - **Files**: `plugins/ralph-specum/references/quick-mode.md`
  - **Done when**: Step 8.5 exists between steps 8 and 9, contains full discovery instructions
  - **Verify**: `grep -c 'Skill Discovery Pass 1' plugins/ralph-specum/references/quick-mode.md` returns >= 1
  - **Commit**: `feat(ralph-specum): add skill discovery pass 1 to quick mode`
  - _Requirements: FR-1, FR-2, FR-3, AC-1.1, AC-5.1_
  - _Design: Insertion Points (Quick Mode)_

- [x] 1.7 [VERIFY] Quality checkpoint: both files have Pass 1
  - **Do**: Verify both start.md and quick-mode.md contain Skill Discovery Pass 1 with matching algorithm
  - **Verify**: `grep -c 'Skill Discovery Pass 1' plugins/ralph-specum/commands/start.md` >= 1 AND `grep -c 'Skill Discovery Pass 1' plugins/ralph-specum/references/quick-mode.md` >= 1 AND `grep -c 'overlap >= 2' plugins/ralph-specum/commands/start.md` >= 1 AND `grep -c 'overlap >= 2' plugins/ralph-specum/references/quick-mode.md` >= 1
  - **Done when**: Both files have consistent Pass 1 instructions with threshold
  - **Commit**: `chore(ralph-specum): align pass 1 instructions` (only if fixes needed)

- [x] 1.8 Add Skill Discovery Pass 2 to quick-mode.md (Step 10.5)
  - **Do**:
    1. Open `plugins/ralph-specum/references/quick-mode.md`
    2. Insert step 10.5 between step 10 (Research Phase) and step 11 (Requirements Phase)
    3. Add the step as: `10.5. Skill Discovery Pass 2: re-scan skills using goal + research Executive Summary, invoke new matches`
    4. Include full inline discovery instructions for Pass 2:
       - Context text: goal text + Executive Summary from research.md
       - matchedAt: `"post-research"`
       - Skip already-invoked skills
       - Full tokenization rules
       - Update state, log to progress under `### Post-Research Retry`
  - **Files**: `plugins/ralph-specum/references/quick-mode.md`
  - **Done when**: Step 10.5 exists between steps 10 and 11, uses Executive Summary as context source
  - **Verify**: `grep -c 'Post-Research' plugins/ralph-specum/references/quick-mode.md` returns >= 1 AND `grep -c 'Executive Summary' plugins/ralph-specum/references/quick-mode.md` returns >= 1
  - **Commit**: `feat(ralph-specum): add skill discovery pass 2 to quick mode`
  - _Requirements: FR-4, FR-7, AC-2.1, AC-2.2, AC-2.4_
  - _Design: Insertion Points (Quick Mode)_

- [x] 1.9 Add error handling instructions to both discovery passes
  - **Do**:
    1. In start.md Step 2.5 and post-research pass, add explicit error handling notes:
       - If SKILL.md is unreadable: skip skill, log warning
       - If SKILL.md has no description field: skip skill, log "no description"
       - If Skill tool invocation fails: set `invoked: false`, log warning, continue
       - If no skills match: log "No skills matched"
    2. Add same error handling to quick-mode.md steps 8.5 and 10.5
  - **Files**: `plugins/ralph-specum/commands/start.md`, `plugins/ralph-specum/references/quick-mode.md`
  - **Done when**: Error handling for all 4 scenarios (unreadable, no description, invoke fail, no match) is documented in all 4 insertion points
  - **Verify**: `grep -c 'invoked: false' plugins/ralph-specum/commands/start.md` >= 1 AND `grep -c 'invoked: false' plugins/ralph-specum/references/quick-mode.md` >= 1
  - **Commit**: `feat(ralph-specum): add error handling to skill discovery`
  - _Requirements: FR-8, AC-5.3_
  - _Design: Error Handling_

- [ ] 1.10 [VERIFY] Quality checkpoint: full content verification
  - **Do**: Verify all 4 discovery insertion points exist and have required elements
  - **Verify**: Run all of these:
    - `grep -c 'Skill Discovery' plugins/ralph-specum/commands/start.md` >= 2 (pass 1 + pass 2)
    - `grep -c 'Skill Discovery' plugins/ralph-specum/references/quick-mode.md` >= 2 (pass 1 + pass 2)
    - `grep -c 'discoveredSkills' plugins/ralph-specum/commands/start.md` >= 3 (init + 2 passes)
    - `grep -c 'discoveredSkills' plugins/ralph-specum/references/quick-mode.md` >= 3 (init + 2 passes)
    - `grep -c 'stopwords' plugins/ralph-specum/commands/start.md` >= 1
    - `grep -c 'stopwords' plugins/ralph-specum/references/quick-mode.md` >= 1
  - **Done when**: All grep counts meet thresholds
  - **Commit**: `chore(ralph-specum): pass POC quality checkpoint` (only if fixes needed)

- [ ] 1.11 POC Checkpoint: verify feature works end-to-end
  - **Do**:
    1. Read start.md fully and trace the normal mode flow: Step 1 -> Step 2 -> Step 2.5 (Pass 1) -> Step 3 -> Step 4 (New Flow) -> steps 1-11 -> Post-Research (Pass 2) -> STOP
    2. Read quick-mode.md fully and trace: steps 1-8 -> 8.5 (Pass 1) -> 9-10 -> 10.5 (Pass 2) -> 11-15
    3. Verify no step numbering conflicts or broken references
    4. Verify the tokenization rules and stopword list are identical across all 4 insertion points
  - **Verify**: `grep -c 'ralph-specum:<name>' plugins/ralph-specum/commands/start.md` >= 1 AND `grep -c 'ralph-specum:<name>' plugins/ralph-specum/references/quick-mode.md` >= 1 (proves Skill invocation syntax present in both)
  - **Done when**: Both files have complete, consistent skill discovery instructions at correct insertion points with no broken step numbering
  - **Commit**: `feat(ralph-specum): complete skill discovery POC`

## Phase 2: Refactoring

Focus: Clean up inline instructions for clarity. Ensure consistent formatting between normal and quick mode.

- [ ] 2.1 Ensure tokenization rules are identically worded in all 4 passes
  - **Do**:
    1. Compare the tokenization rules text in start.md Pass 1 vs Pass 2 vs quick-mode.md Pass 1 vs Pass 2
    2. Pick the clearest wording and normalize all 4 to use identical phrasing
    3. Ensure the stopword list is the same across all 4: `a, an, the, to, for, with, and, or, in, on, by, is, be, that, this, of, it, should, used, when, asks, needs, about`
  - **Files**: `plugins/ralph-specum/commands/start.md`, `plugins/ralph-specum/references/quick-mode.md`
  - **Done when**: Tokenization rules are word-for-word identical in all 4 insertion points
  - **Verify**: Extract tokenization sections from both files and diff them (manual read + compare)
  - **Commit**: `refactor(ralph-specum): normalize tokenization rules across discovery passes`
  - _Design: Tokenization Rules_

- [ ] 2.2 Clean up step numbering in start.md
  - **Do**:
    1. Review start.md New Flow numbered list (steps 1-12)
    2. Decide: either use X.5 numbering (2.5, 11.5) or renumber to integers
    3. Ensure the Quick Mode Check note ("skip to Step 5") still references the correct step
    4. Ensure all cross-references within start.md are consistent
  - **Files**: `plugins/ralph-specum/commands/start.md`
  - **Done when**: Step numbering is clean with no broken cross-references
  - **Verify**: `grep -n 'Step [0-9]' plugins/ralph-specum/commands/start.md` shows sequential numbering
  - **Commit**: `refactor(ralph-specum): clean up step numbering in start.md`

- [ ] 2.3 Clean up step numbering in quick-mode.md
  - **Do**:
    1. Review Quick Mode Execution Sequence numbered list
    2. Decide: either use X.5 numbering (8.5, 10.5) or renumber to integers
    3. Ensure all internal references are consistent
  - **Files**: `plugins/ralph-specum/references/quick-mode.md`
  - **Done when**: Step numbering is clean with no broken references
  - **Verify**: `grep -n '^[0-9]' plugins/ralph-specum/references/quick-mode.md` shows logical sequence
  - **Commit**: `refactor(ralph-specum): clean up step numbering in quick-mode.md`

- [ ] 2.4 [VERIFY] Quality checkpoint: refactoring consistency
  - **Do**: Verify both files are internally consistent and cross-references work
  - **Verify**: `grep -c 'Skill Discovery' plugins/ralph-specum/commands/start.md` >= 2 AND `grep -c 'Skill Discovery' plugins/ralph-specum/references/quick-mode.md` >= 2 AND no broken "Step N" references exist
  - **Done when**: Both files read cleanly with no orphaned references
  - **Commit**: `chore(ralph-specum): pass refactoring quality checkpoint` (only if fixes needed)

## Phase 3: Testing

Focus: Verify the markdown instructions are correct and complete by automated content checks. No runtime test framework exists -- validation is structural.

- [ ] 3.1 Verify all 6 skills are discoverable via frontmatter
  - **Do**:
    1. Read each SKILL.md under `plugins/ralph-specum/skills/*/SKILL.md`
    2. Verify each has `name` and `description` in YAML frontmatter
    3. Verify the Skill invocation syntax `ralph-specum:<name>` matches actual skill directory names
  - **Files**: All 6 SKILL.md files (read-only verification)
  - **Done when**: All 6 skills have name + description frontmatter matching their directory names
  - **Verify**: `for d in plugins/ralph-specum/skills/*/; do name=$(basename "$d"); grep -l "name: $name" "$d/SKILL.md" || echo "MISSING: $name"; done` outputs 6 matches and no MISSING lines
  - **Commit**: none (read-only check)
  - _Requirements: AC-1.1, AC-1.4_

- [ ] 3.2 Verify tokenization handles existing skill descriptions correctly
  - **Do**:
    1. Read interview-framework SKILL.md description: "Adaptive brainstorming-style dialogue for all spec phases (Understand, Propose Approaches, Confirm & Store)"
    2. Apply tokenization rules manually:
       - Lowercase: "adaptive brainstorming-style dialogue for all spec phases (understand, propose approaches, confirm & store)"
       - Hyphens->spaces: "adaptive brainstorming style dialogue for all spec phases (understand, propose approaches, confirm & store)"
       - Strip punctuation: "adaptive brainstorming style dialogue for all spec phases understand propose approaches confirm store"
       - Split: ["adaptive", "brainstorming", "style", "dialogue", "for", "all", "spec", "phases", "understand", "propose", "approaches", "confirm", "store"]
       - Remove stopwords: ["adaptive", "brainstorming", "style", "dialogue", "all", "spec", "phases", "understand", "propose", "approaches", "confirm", "store"]
    3. Verify a goal like "Add adaptive brainstorming for goal exploration" would match (overlap: adaptive, brainstorming = 2 words)
    4. Document this test case in .progress.md under Learnings
  - **Files**: `specs/smart-skill-swap-retry/.progress.md` (append)
  - **Done when**: Tokenization produces expected tokens, match threshold works for sample case
  - **Verify**: `grep -c 'tokenization' specs/smart-skill-swap-retry/.progress.md` >= 1
  - **Commit**: `test(ralph-specum): verify tokenization against real skill descriptions`
  - _Design: Tokenization Rules, Matching Algorithm_

- [ ] 3.3 Verify discovery instructions reference correct CLAUDE_PLUGIN_ROOT path
  - **Do**:
    1. Check that all discovery instructions in start.md and quick-mode.md use `${CLAUDE_PLUGIN_ROOT}/skills/*/SKILL.md` (not hardcoded paths)
    2. Verify the Skill invocation uses `ralph-specum:<name>` format
  - **Files**: `plugins/ralph-specum/commands/start.md`, `plugins/ralph-specum/references/quick-mode.md` (read-only)
  - **Done when**: All path references use CLAUDE_PLUGIN_ROOT variable
  - **Verify**: `grep -c 'CLAUDE_PLUGIN_ROOT' plugins/ralph-specum/commands/start.md` >= 2 (existing + new) AND `grep -c 'CLAUDE_PLUGIN_ROOT' plugins/ralph-specum/references/quick-mode.md` >= 1
  - **Commit**: none (read-only check) or `fix(ralph-specum): correct plugin root paths` if fixes needed
  - _Requirements: AC-1.1_

- [ ] 3.4 [VERIFY] Quality checkpoint: content completeness
  - **Do**: Run all structural checks to ensure nothing was missed
  - **Verify**: All of these pass:
    - `grep -c 'discoveredSkills' plugins/ralph-specum/commands/start.md` >= 3
    - `grep -c 'discoveredSkills' plugins/ralph-specum/references/quick-mode.md` >= 3
    - `grep -c 'matchedAt' plugins/ralph-specum/commands/start.md` >= 2
    - `grep -c 'matchedAt' plugins/ralph-specum/references/quick-mode.md` >= 2
    - `grep -c 'invoked' plugins/ralph-specum/commands/start.md` >= 2
    - `grep -c 'invoked' plugins/ralph-specum/references/quick-mode.md` >= 2
    - `grep -c 'Post-Research' plugins/ralph-specum/commands/start.md` >= 1
    - `grep -c 'Post-Research' plugins/ralph-specum/references/quick-mode.md` >= 1
    - `grep -c 'progress.md' plugins/ralph-specum/commands/start.md` >= 2 (existing + discovery logging)
    - `grep -c 'progress.md' plugins/ralph-specum/references/quick-mode.md` >= 2
  - **Done when**: All counts meet thresholds
  - **Commit**: `chore(ralph-specum): pass content completeness checkpoint` (only if fixes needed)

- [ ] 3.5 Verify AC coverage by tracing each acceptance criterion
  - **Do**:
    1. For each AC in requirements.md, verify the corresponding instruction exists in start.md or quick-mode.md:
       - AC-1.1: Read SKILL.md files -> check for CLAUDE_PLUGIN_ROOT/skills reference
       - AC-1.2: Keyword overlap matching -> check for tokenization + overlap >= 2
       - AC-1.3: Invoke via Skill tool -> check for `ralph-specum:<name>` invocation
       - AC-1.4: user-invocable: false still eligible -> check no filtering on this field
       - AC-1.5: Discovery before phase delegation -> check Step 2.5 placement
       - AC-2.1: Re-run with Executive Summary -> check post-research pass
       - AC-2.2: Skip already-invoked -> check duplicate prevention logic
       - AC-2.3: Before requirements -> check quick-mode step 10.5 before 11
       - AC-2.4: Both modes -> check both files have pass 2
       - AC-3.1-3.4: State tracking -> check discoveredSkills in state updates
       - AC-4.1-4.4: Progress logging -> check progress.md append instructions
       - AC-5.1-5.3: No prompts, immediate invoke, failure handling -> check no confirmation prompts, error handling
    2. Document any gaps found
  - **Files**: `specs/smart-skill-swap-retry/.progress.md` (append if gaps found)
  - **Done when**: Every AC-* has a traceable instruction in the modified files
  - **Verify**: `grep -c 'Skill Discovery' plugins/ralph-specum/commands/start.md` >= 2 AND `grep -c 'Skill Discovery' plugins/ralph-specum/references/quick-mode.md` >= 2 (proves both passes exist in both modes)
  - **Commit**: `fix(ralph-specum): address AC coverage gaps` (only if fixes needed)
  - _Requirements: All ACs_

## Phase 4: Quality Gates

- [ ] 4.1 Bump plugin version
  - **Do**:
    1. Bump patch version in `plugins/ralph-specum/.claude-plugin/plugin.json` (4.1.2 -> 4.2.0, minor bump for new feature)
    2. Bump matching version in `.claude-plugin/marketplace.json` (4.1.2 -> 4.2.0)
  - **Files**: `plugins/ralph-specum/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  - **Done when**: Both files show version 4.2.0
  - **Verify**: `grep '"version"' plugins/ralph-specum/.claude-plugin/plugin.json` shows 4.2.0 AND `grep -A1 'ralph-specum' .claude-plugin/marketplace.json | grep version` shows 4.2.0
  - **Commit**: `chore(ralph-specum): bump version to 4.2.0`

- [ ] 4.2 [VERIFY] Full local quality check
  - **Do**: Verify all modified files are syntactically valid markdown and contain no broken references
  - **Verify**: All pass:
    - `test -f plugins/ralph-specum/commands/start.md` (file exists)
    - `test -f plugins/ralph-specum/references/quick-mode.md` (file exists)
    - `grep -c 'discoveredSkills' plugins/ralph-specum/commands/start.md` >= 3
    - `grep -c 'discoveredSkills' plugins/ralph-specum/references/quick-mode.md` >= 3
    - `grep -c 'Step' plugins/ralph-specum/commands/start.md` >= 6 (all steps still present)
    - JSON parse check: `python3 -c "import json; json.loads(open('plugins/ralph-specum/.claude-plugin/plugin.json').read())"` exits 0
    - JSON parse check: `python3 -c "import json; json.loads(open('.claude-plugin/marketplace.json').read())"` exits 0
  - **Done when**: All files valid, all checks pass
  - **Commit**: `fix(ralph-specum): address quality issues` (only if fixes needed)

- [ ] 4.3 Create PR and verify CI
  - **Do**:
    1. Verify current branch is a feature branch: `git branch --show-current`
    2. If on default branch, STOP and alert user
    3. Stage modified files: `git add plugins/ralph-specum/commands/start.md plugins/ralph-specum/references/quick-mode.md plugins/ralph-specum/.claude-plugin/plugin.json .claude-plugin/marketplace.json`
    4. Push branch: `git push -u origin $(git branch --show-current)`
    5. Create PR: `gh pr create --title "feat(ralph-specum): auto-discover and invoke skills on start" --body "..."`
  - **Verify**: `gh pr checks --watch` shows all green (or `gh pr checks` if no CI configured)
  - **Done when**: PR created, CI passes (or no CI to run)
  - **Commit**: none (PR creation, not a code change)

- [ ] 4.4 Monitor CI and fix failures
  - **Do**:
    1. Check CI status: `gh pr checks`
    2. If failures: read failure details, fix, push
    3. Re-verify: `gh pr checks`
  - **Verify**: `gh pr checks` shows all passing or no checks configured
  - **Done when**: All CI checks green

- [ ] 4.5 [VERIFY] AC checklist final verification
  - **Do**:
    1. Read requirements.md
    2. For each AC, verify implementation exists via grep/read
    3. Confirm: discoveredSkills in state (AC-3), progress logging (AC-4), both modes (AC-2.4, AC-5), error handling (AC-5.3)
  - **Verify**: `grep -c 'discoveredSkills' plugins/ralph-specum/commands/start.md` >= 3 AND `grep -c 'discoveredSkills' plugins/ralph-specum/references/quick-mode.md` >= 3 AND `grep -c 'Post-Research' plugins/ralph-specum/commands/start.md` >= 1 AND `grep -c 'Post-Research' plugins/ralph-specum/references/quick-mode.md` >= 1
  - **Done when**: All ACs confirmed implemented
  - **Commit**: none

- [ ] 4.6 Address review comments (if any)
  - **Do**:
    1. Check for PR review comments: `gh pr view --comments`
    2. Address each comment
    3. Push fixes
  - **Verify**: `gh pr checks` still green after fixes
  - **Done when**: All review comments resolved

## Notes

- **POC shortcuts taken**: Inline discovery instructions are duplicated between start.md and quick-mode.md (4 insertion points, each self-contained). This is intentional per design -- only 2 files, minor differences in context source.
- **Production TODOs**: If skill count grows beyond ~10, consider a centralized discovery reference file. For now, inline is simpler.
- **Key insight**: The "code" is markdown instructions for an AI agent. There is no runtime, no build, no test framework. "Testing" means structural validation of the markdown content.
- **Stopword list**: a, an, the, to, for, with, and, or, in, on, by, is, be, that, this, of, it, should, used, when, asks, needs, about (25 words)
- **Threshold**: 2 word overlap -- prevents false positives while catching real matches
