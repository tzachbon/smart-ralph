---
generated: auto
---

# Tasks: remove-codex-prefix

## Phase 1: Red-Green-Yellow Cycles

Intent: REFACTOR. TDD workflow. Every change driven by making the verification commands pass.

- [x] 1.1 [RED] Failing test: bats suite references old path
  - **Do**:
    1. Run `bats tests/codex-plugin.bats tests/codex-platform.bats tests/codex-platform-scripts.bats` from repo root
    2. Confirm tests fail because `plugins/ralph-specum-codex` does not match expected state (or confirm they currently pass with old path, establishing baseline)
    3. Record exit code in .progress.md
  - **Files**: (read-only)
  - **Done when**: Baseline test state documented; we know current pass/fail
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph && bats tests/codex-plugin.bats 2>&1 | tail -5`
  - **Commit**: None (baseline only)
  - _Requirements: FR-6, AC-4.1_

- [x] 1.2 [GREEN] Rename directory and update plugin.json + marketplace.json
  - **Do**:
    1. From repo root: `git mv plugins/ralph-specum-codex plugins/codex`
    2. Edit `plugins/codex/.codex-plugin/plugin.json`: set `name` to `ralph-specum`, bump `version` to `4.9.2`
    3. Edit `.agents/plugins/marketplace.json`: update the `ralph-specum-codex` entry — set `name` to `ralph-specum`, update `source.path` to `./plugins/codex`, bump version to `4.9.2`
  - **Files**: `plugins/codex/.codex-plugin/plugin.json`, `.agents/plugins/marketplace.json`
  - **Done when**: `jq .name plugins/codex/.codex-plugin/plugin.json` returns `ralph-specum`; `ls plugins/ralph-specum-codex` fails; `ls plugins/codex` succeeds
  - **Verify**: `jq .name /Users/zachbonfil/projects/smart-ralph/plugins/codex/.codex-plugin/plugin.json | grep -q ralph-specum && echo PASS`
  - **Commit**: `feat(codex): rename plugin dir to plugins/codex, update name to ralph-specum`
  - _Requirements: FR-1, FR-2, FR-3, AC-1.1, AC-2.1, AC-2.2, AC-2.3_

- [ ] 1.3 [GREEN] Update CI workflow files
  - **Do**:
    1. Edit `.github/workflows/codex-version-check.yml`: replace all occurrences of `plugins/ralph-specum-codex` with `plugins/codex`; replace name assertion string `ralph-specum-codex` with `ralph-specum`
    2. Edit `.github/workflows/bats-tests.yml`: replace all occurrences of `plugins/ralph-specum-codex` with `plugins/codex`
  - **Files**: `.github/workflows/codex-version-check.yml`, `.github/workflows/bats-tests.yml`
  - **Done when**: `grep -r "ralph-specum-codex" .github/` returns no matches
  - **Verify**: `grep -r "ralph-specum-codex" /Users/zachbonfil/projects/smart-ralph/.github/ && echo FAIL || echo PASS`
  - **Commit**: `fix(ci): update workflow path triggers and name assertion to plugins/codex`
  - _Requirements: FR-4, FR-5, AC-3.1, AC-3.2, AC-3.3_

- [ ] 1.4 [GREEN] Update BATS test files and version-sync helper
  - **Do**:
    1. Edit `tests/codex-plugin.bats`: update `plugin_root()` to return `plugins/codex`
    2. Edit `tests/codex-platform.bats`: replace all ~30 occurrences — path strings `ralph-specum-codex` become `codex`; plugin name assertions `ralph-specum-codex` become `ralph-specum`. Use grep to identify each occurrence type before replacing.
    3. Edit `tests/codex-platform-scripts.bats`: replace the single path reference `ralph-specum-codex` with `codex`
    4. Edit `tests/helpers/version-sync.sh`: replace path reference `ralph-specum-codex` with `codex`
  - **Files**: `tests/codex-plugin.bats`, `tests/codex-platform.bats`, `tests/codex-platform-scripts.bats`, `tests/helpers/version-sync.sh`
  - **Done when**: `grep -r "ralph-specum-codex" tests/` returns no matches
  - **Verify**: `grep -r "ralph-specum-codex" /Users/zachbonfil/projects/smart-ralph/tests/ && echo FAIL || echo PASS`
  - **Commit**: `fix(tests): update bats test paths and name references from ralph-specum-codex to codex`
  - _Requirements: FR-6, FR-7, AC-4.1, AC-4.2, AC-4.3, AC-4.4_

- [ ] 1.5 [GREEN] Update README files and path-resolution.md
  - **Do**:
    1. Edit root `README.md`: replace all ~12 occurrences of `ralph-specum-codex` (path segments become `codex`, plugin name strings become `ralph-specum` as appropriate)
    2. Edit `plugins/codex/README.md`: replace self-references to `ralph-specum-codex` with `codex` (path) or `ralph-specum` (name)
    3. Edit `plugins/codex/references/path-resolution.md`: replace path references from `ralph-specum-codex` to `codex`
  - **Files**: `README.md`, `plugins/codex/README.md`, `plugins/codex/references/path-resolution.md`
  - **Done when**: `grep -r "ralph-specum-codex" README.md plugins/codex/README.md plugins/codex/references/` returns no matches
  - **Verify**: `grep "ralph-specum-codex" /Users/zachbonfil/projects/smart-ralph/README.md /Users/zachbonfil/projects/smart-ralph/plugins/codex/README.md 2>&1 && echo FAIL || echo PASS`
  - **Commit**: `docs: update README and path-resolution.md for plugins/codex rename`
  - _Requirements: FR-8, AC-5.1, AC-5.2, AC-5.3_

- [ ] 1.6 [GREEN] Update specs/codex-plugin-sync/ references
  - **Do**:
    1. List files: `ls specs/codex-plugin-sync/`
    2. For each of the 4 files, replace occurrences of `ralph-specum-codex` with `codex` (paths) or `ralph-specum` (plugin name)
  - **Files**: `specs/codex-plugin-sync/*.md` (4 files)
  - **Done when**: `grep -r "ralph-specum-codex" specs/codex-plugin-sync/` returns no matches
  - **Verify**: `grep -r "ralph-specum-codex" /Users/zachbonfil/projects/smart-ralph/specs/codex-plugin-sync/ && echo FAIL || echo PASS`
  - **Commit**: `fix(specs): update codex-plugin-sync spec files to reference plugins/codex`
  - _Requirements: FR-9, AC-6.1_

## Phase 2: Additional Testing

- [ ] 2.1 [VERIFY] Confirm zero stale references repo-wide
  - **Do**:
    1. Run: `grep -r "ralph-specum-codex" . --exclude-dir=.git --exclude-dir=node_modules 2>/dev/null`
    2. Verify output is empty
  - **Verify**: `grep -r "ralph-specum-codex" /Users/zachbonfil/projects/smart-ralph --exclude-dir=.git --exclude-dir=node_modules 2>/dev/null | grep -v "specs/remove-codex-prefix" && echo FAIL || echo PASS`
  - **Done when**: No occurrences of `ralph-specum-codex` in any tracked file (ignoring the current spec directory)
  - **Commit**: None

- [ ] 2.2 [VERIFY] Run BATS test suite
  - **Do**:
    1. From repo root: `bats tests/codex-plugin.bats tests/codex-platform.bats tests/codex-platform-scripts.bats`
    2. All tests must exit 0
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph && bats tests/codex-plugin.bats tests/codex-platform.bats tests/codex-platform-scripts.bats`
  - **Done when**: `bats` exits 0 for all three test files
  - **Commit**: None
  - _Requirements: AC-4.5, NFR-3_

## Phase 3: Quality Gates

- [ ] V4 [VERIFY] Full local CI: confirm plugin.json name and version, no stale refs, tests pass
  - **Do**:
    1. `jq .name plugins/codex/.codex-plugin/plugin.json` — must return `"ralph-specum"`
    2. `jq .version plugins/codex/.codex-plugin/plugin.json` — must return `"4.9.2"`
    3. `grep -r "ralph-specum-codex" . --exclude-dir=.git` — must return no output
    4. `bats tests/codex-plugin.bats tests/codex-platform.bats tests/codex-platform-scripts.bats` — must exit 0
  - **Verify**: `cd /Users/zachbonfil/projects/smart-ralph && jq .name plugins/codex/.codex-plugin/plugin.json | grep -q ralph-specum && bats tests/codex-plugin.bats tests/codex-platform.bats tests/codex-platform-scripts.bats && echo ALL_PASS`
  - **Done when**: All commands exit 0, `ALL_PASS` printed
  - **Commit**: `chore(codex): pass full local CI after rename`

- [ ] V5 [VERIFY] CI pipeline passes
  - **Do**: Push branch and check CI status
  - **Verify**: `gh pr checks --watch`
  - **Done when**: All CI checks green
  - **Commit**: None

- [ ] V6 [VERIFY] AC checklist
  - **Do**:
    1. `ls /Users/zachbonfil/projects/smart-ralph/plugins/codex` — AC-1.1
    2. `ls /Users/zachbonfil/projects/smart-ralph/plugins/ralph-specum-codex 2>&1 | grep -q "No such file"` — AC-1.1 (old dir gone)
    3. `jq .name /Users/zachbonfil/projects/smart-ralph/plugins/codex/.codex-plugin/plugin.json | grep -q ralph-specum` — AC-2.1
    4. `jq .version /Users/zachbonfil/projects/smart-ralph/plugins/codex/.codex-plugin/plugin.json | grep -q 4.9.2` — AC-2.2
    5. `grep -q "ralph-specum" /Users/zachbonfil/projects/smart-ralph/.agents/plugins/marketplace.json` — AC-2.3
    6. `grep -q "plugins/codex" /Users/zachbonfil/projects/smart-ralph/.github/workflows/codex-version-check.yml` — AC-3.1
    7. `bats tests/codex-plugin.bats tests/codex-platform.bats tests/codex-platform-scripts.bats` — AC-4.5
  - **Verify**: All commands above exit 0
  - **Done when**: All acceptance criteria confirmed via automated checks
  - **Commit**: None

## Phase 4: PR Lifecycle

- [ ] 4.1 Create PR
  - **Do**:
    1. Verify on feature branch: `git branch --show-current`
    2. Push: `git push -u origin $(git branch --show-current)`
    3. Create PR: `gh pr create --title "rename plugins/ralph-specum-codex to plugins/codex" --body "$(cat <<'EOF'
## Summary
- Rename \`plugins/ralph-specum-codex/\` to \`plugins/codex/\` via \`git mv\`
- Update plugin name in \`plugin.json\` from \`ralph-specum-codex\` to \`ralph-specum\`, bump version to 4.9.2
- Update all cross-references in CI, tests, docs, and spec files

## Test plan
- [ ] \`bats tests/codex-plugin.bats tests/codex-platform.bats tests/codex-platform-scripts.bats\` exits 0
- [ ] \`grep -r "ralph-specum-codex" . --exclude-dir=.git\` returns no matches
- [ ] CI green on all checks
EOF
)"`
  - **Verify**: `gh pr view --json url | jq .url`
  - **Done when**: PR created, URL returned
  - **Commit**: None

- [ ] 4.2 Monitor and fix CI
  - **Do**:
    1. `gh pr checks --watch`
    2. If failures: read logs with `gh run view`, fix locally, push
  - **Verify**: `gh pr checks | grep -v pass | grep -v skipping | wc -l | grep -q "^0$" && echo CI_GREEN`
  - **Done when**: All CI checks pass
  - **Commit**: `fix(ci): address CI failures` (only if fixes needed)

## Notes

- Pure rename: no logic changes, no new abstractions
- Critical distinction in `tests/codex-platform.bats`: path refs use `codex`, name assertion refs use `ralph-specum`. Do not blindly replace all occurrences with the same string.
- Version bump is patch only: 4.9.1 -> 4.9.2, required in both `plugin.json` and `marketplace.json` simultaneously or CI version-check will fail
- `specs/remove-codex-prefix/` is excluded from the stale-ref grep in 2.1 (spec files legitimately mention the old name in context)
