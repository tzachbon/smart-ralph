# Git Strategy

Commit and push strategy.

Loaded for: COMMIT tasks.

---

## Git Push Strategy

Commit after every task, but batch pushes to avoid excessive remote operations.

**When to push:**
- After completing each phase (Phase 1, Phase 2, etc.)
- After every 5 commits if within a long phase
- Before creating a PR (Phase 4/5)
- When awaitingApproval is set (user gate requires remote state)

**When NOT to push:**
- After every individual task commit
- During mid-phase execution with fewer than 5 pending commits

**Implementation:**
1. Track commits since last push (count via `git rev-list @{push}..HEAD 2>/dev/null | wc -l` or maintain a counter)
2. After State Update, check push conditions:
   - Phase boundary: current task's phase header differs from previous task's
   - Commit count: 5+ commits since last push
   - Approval gate: awaitingApproval about to be set
3. If any condition met: `git push`
4. Log push in .progress.md: "Pushed N commits (reason: phase boundary / batch limit / approval gate)"

---

## Native Task Sync - Modification

> **Reference**: See `${CLAUDE_PLUGIN_ROOT}/references/task-modification.md` for modification operation handling (SPLIT/PREREQ/FOLLOWUP/ADJUST).

---

## PR Lifecycle Loop (Phase 5)

> **Reference**: See `${CLAUDE_PLUGIN_ROOT}/references/pr-lifecycle.md` for Phase 5 PR management and CI monitoring.
