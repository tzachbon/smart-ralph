---
spec: multi-spec-dirs
phase: requirements
created: 2026-02-04
---

# Requirements: Multi-Spec Directories

## Goal

Enable organizing specs in configurable directories beyond `./specs/`, supporting subdirectories and multiple roots while maintaining full backward compatibility with existing behavior.

## User Decisions

Interview responses that shaped requirements:

| Question | Response |
|----------|----------|
| Primary users | End users of ralph-specum (developers using the plugin) |
| Priority tradeoffs | Backward compatibility first - existing `./specs/` never breaks |
| Config location | Both config file AND CLI flag (config for defaults, CLI to override) |
| Current-spec management | Store full path (bare name implies `./specs/` for backward compat) |
| Success criteria | All commands work with any configured specs dir; zero breaking changes; no migration needed |

## User Stories

### US-1: Configure Multiple Specs Directories

**As a** developer with a monorepo
**I want to** define multiple specs directories in my config
**So that** I can organize specs by project or area

**Acceptance Criteria:**
- [ ] AC-1.1: Can add `specs_dirs` array to `.claude/ralph-specum.local.md` frontmatter
- [ ] AC-1.2: Array accepts relative paths (e.g., `["./specs", "./packages/api/specs", "./packages/web/specs"]`)
- [ ] AC-1.3: Empty array or missing setting defaults to `["./specs"]`
- [ ] AC-1.4: Invalid paths logged as warnings, valid paths still work

### US-2: Create Specs in Specified Directory

**As a** developer
**I want to** create new specs in any configured directory
**So that** I can organize specs where they belong

**Acceptance Criteria:**
- [ ] AC-2.1: `/ralph-specum:start my-feature` creates in first configured dir by default
- [ ] AC-2.2: `/ralph-specum:start my-feature --specs-dir ./packages/api/specs` creates in specified dir
- [ ] AC-2.3: `--specs-dir` works with all phase commands (start, new)
- [ ] AC-2.4: Error if `--specs-dir` path not in configured `specs_dirs` array
- [ ] AC-2.5: Spec directory auto-created if doesn't exist

### US-3: View All Specs Across Directories

**As a** developer
**I want to** see all specs from all configured directories
**So that** I can find and manage specs regardless of location

**Acceptance Criteria:**
- [ ] AC-3.1: `/ralph-specum:status` lists specs from all `specs_dirs`
- [ ] AC-3.2: Each spec shows its root directory (e.g., `api-auth [packages/api/specs]`)
- [ ] AC-3.3: Active spec indicator works across all directories
- [ ] AC-3.4: Specs sorted alphabetically within each directory grouping

### US-4: Switch Between Specs Across Directories

**As a** developer
**I want to** switch to any spec regardless of its directory
**So that** I can work on specs in different areas

**Acceptance Criteria:**
- [ ] AC-4.1: `/ralph-specum:switch` lists all specs with directory context
- [ ] AC-4.2: Can switch to spec by name if unique across all dirs
- [ ] AC-4.3: If duplicate name exists, shows disambiguation prompt with paths
- [ ] AC-4.4: Can switch using full path: `/ralph-specum:switch packages/api/specs/my-feature`
- [ ] AC-4.5: `.current-spec` updated with full path, not just name

### US-5: Backward Compatible Default Behavior

**As an** existing user
**I want** my current setup to work unchanged
**So that** I don't need to migrate or reconfigure anything

**Acceptance Criteria:**
- [ ] AC-5.1: No config file = `./specs/` used (current behavior)
- [ ] AC-5.2: Existing `.current-spec` with bare name = `./specs/{name}`
- [ ] AC-5.3: All existing commands work without any config changes
- [ ] AC-5.4: Existing specs in `./specs/` discovered and usable
- [ ] AC-5.5: No errors or warnings for users without custom config

### US-6: Auto-Discovery of Specs

**As a** developer
**I want** ralph-specum to find specs automatically
**So that** I don't need to manually register each spec

**Acceptance Criteria:**
- [ ] AC-6.1: Searches all `specs_dirs` for directories containing `.ralph-state.json`
- [ ] AC-6.2: Discovery runs on status, switch, and any list operation
- [ ] AC-6.3: Only direct children of specs_dirs considered (no recursive glob)
- [ ] AC-6.4: Hidden directories (starting with `.`) excluded from discovery

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | Add `specs_dirs` setting to config | High | Array of paths in frontmatter, validated on read |
| FR-2 | Add `--specs-dir` CLI flag | High | Overrides default root for spec creation |
| FR-3 | Update `.current-spec` format | High | Store full path; bare name = `./specs/` for compat |
| FR-4 | Create path resolver helper script | High | Shell functions for hooks and commands to source |
| FR-5 | Update all commands (12 files) | High | Use path resolver instead of hardcoded `./specs/` |
| FR-6 | Update all hooks (2 files) | High | Read settings, use path resolver |
| FR-7 | Update all agents (8 files) | Medium | Reference dynamic paths in prompts |
| FR-8 | Handle duplicate spec names | Medium | Prompt for disambiguation when name not unique |
| FR-9 | Update worktree copying logic | Medium | Copy from active spec's root only |
| FR-10 | Update settings template | Low | Document `specs_dirs` setting |
| FR-11 | Update help command | Low | Document multi-dir functionality |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Discovery performance | Time to list specs | < 500ms for 10 dirs, 100 specs |
| NFR-2 | Backward compatibility | Breaking changes | Zero |
| NFR-3 | Config validation | Error clarity | All invalid paths produce actionable warnings |
| NFR-4 | Path resolution consistency | Relative path handling | All paths relative to project root |

## Glossary

- **Specs Root**: A directory containing spec subdirectories (e.g., `./specs/`, `./packages/api/specs/`)
- **specs_dirs**: Config array listing all specs roots to search
- **Current Spec**: The active spec stored in `.current-spec`, now as full path
- **Path Resolver**: Shell script providing functions to resolve spec paths across roots
- **Disambiguation**: Process of selecting between specs with same name in different roots

## Out of Scope

- Glob patterns in `specs_dirs` (explicit paths only, no `packages/*/specs`)
- Recursive spec discovery (only direct children of specs_dirs)
- Environment variable for specs_dirs (CLI flag and config only)
- Migrating existing specs between directories
- GUI/visual selector for directory choice
- Per-spec directory configuration (all specs in a root share settings)

## Dependencies

- Ralph Loop plugin (existing dependency, no changes needed)
- Shell (bash) for path resolver helper script
- `.claude/ralph-specum.local.md` config file (optional, creates if needed)

## Success Criteria

- All phase commands work with specs in any configured directory
- `/ralph-specum:status` shows specs from all configured roots
- `/ralph-specum:switch` can navigate to any spec across roots
- Existing users with no config see zero behavioral changes
- New users can configure multiple roots in under 1 minute

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking backward compatibility | High | Extensive testing with bare-name `.current-spec` |
| Duplicate spec name confusion | Medium | Clear disambiguation UX with full path display |
| Performance on many directories | Low | Limit to explicit paths, no deep recursion |
| Shell script portability | Low | Use POSIX-compliant shell features only |
| State file conflicts | Medium | Each spec retains own `.ralph-state.json` with full basePath |

## Unresolved Questions

1. **Duplicate spec names** - Should duplicate names across roots be an error, warning, or allowed with disambiguation? (Recommendation: Allow with disambiguation)
2. **Default directory for new specs** - First item in `specs_dirs` array, or require explicit `--specs-dir`? (Recommendation: First item as default)
3. **Worktree behavior** - When using git worktrees, copy specs from all roots or just active spec's root? (Recommendation: Just active spec's root)

## Next Steps

1. Review requirements with user for approval
2. Proceed to design phase to detail implementation approach
3. Create path resolver helper script specification
4. Define update sequence for 25+ files
