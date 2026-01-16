# RFC: Integrate Beads for dependency-aware task execution (v3.0)

## 🎯 Summary

Integrate [Beads](https://github.com/steveyegge/beads) - a lightweight git-based issue tracker designed for AI agents - to replace Smart Ralph's linear task execution with **dependency-aware parallel execution**.

> ⚠️ **Breaking Change**: This would be a major architectural change targeting **v3.0**

---

## 🚀 Why Beads?

| Current Smart Ralph | With Beads |
|---------------------|------------|
| Linear task list with `[P]` markers | True dependency DAG with `blocks` relationships |
| Custom `.ralph-state.json` management | Git-native state via JSONL (auto-sync) |
| Manual parallel task detection | `bd list --ready` finds all unblocked tasks in ~10ms |
| Large `.progress.md` context loading | `bd prime` provides compact 1-2k token context |
| Custom completion verification | `bd doctor` detects orphaned work automatically |
| Race conditions with parallel temp files | Hash-based IDs prevent collisions |

---

## 📊 Key Benefits

### 1. Smarter Parallel Execution
```
Current: Linear scan for [P] markers
         1.1 → 1.2 → [P]1.3 → [P]1.4 → 1.5

With Beads: True dependency resolution
         1.1 ──blocks──► 1.2 ──blocks──┬──► 1.3 ──┐
                                       │          ├──blocks──► 1.5
                                       └──► 1.4 ──┘

bd list --ready automatically returns [1.3, 1.4] when 1.2 completes
```

### 2. Simplified State Management
```bash
# No more custom state file parsing
bd list --ready --json    # What can run now?
bd show $ID --json        # Task details
bd close $ID              # Mark complete
bd sync                   # Push state to git
```

### 3. Better Context Efficiency
- `bd prime`: ~1-2k tokens of structured workflow context
- vs. reading entire `.progress.md` which can grow unbounded

### 4. Built-in Audit Trail
```bash
git commit -m "feat(auth): implement OAuth2 (bd-a3f8e9)"
#                                            ↑ issue ID in commit
```

### 5. Cross-Spec Tracking
```bash
bd create --title "user-auth" --related bd-xyz789
# Native relationship tracking replaces relatedSpecs array
```

---

## 🔧 Proposed Changes

### Phase 1: Non-Breaking Additions
- Add `bd sync` to `ALL_TASKS_COMPLETE` protocol
- Include Beads issue IDs in commit messages
- Use `bd doctor` for completion verification

### Phase 2: Task Management (Breaking)
- `task-planner` creates Beads issues with `--blocks` relationships
- Coordinator uses `bd list --ready` instead of `taskIndex`
- Replace `.ralph-state.json` with Beads as source of truth

### Phase 3: Context Optimization
- Inject `bd prime` output into spec-executor context
- Store learnings in Beads issue notes vs `.progress.md`

---

## 📋 Migration Path

1. **v2.x**: Add optional Beads support (feature flag)
2. **v3.0**: Beads becomes default, legacy mode deprecated
3. **v3.1+**: Remove legacy `.ralph-state.json` support

---

## 🔗 References

- [Beads Repository](https://github.com/steveyegge/beads)
- [Beads Agent Instructions](https://github.com/steveyegge/beads/blob/main/AGENT_INSTRUCTIONS.md)
- [Beads FAQ](https://github.com/steveyegge/beads/blob/main/docs/FAQ.md)

---

## 💬 Discussion

Looking for feedback on:
1. Is the migration path reasonable?
2. Should we support both modes long-term or fully migrate?
3. Any concerns about adding Beads as a dependency?
