---
description: Display active agent teams
argument-hint: [spec-name]
allowed-tools: [Read, Bash, Skill, AskUserQuestion]
---

# Team Status

Display active agent teams and their status.

## Determine Active Spec

1. If `$ARGUMENTS` contains a spec name, resolve the spec path
2. Otherwise, use the current spec from `.current-spec`
3. If no spec provided and no current spec, display all active teams across all specs

## Invoke team-management Skill

The team-management skill handles:
1. Querying state files for active teams (teamName field)
2. Scanning ~/.claude/teams/ for team directories
3. Cross-referencing to find orphaned teams
4. Querying TaskList for teammate status (if available)

## Display Format

For each active team:

```
Team: research-test-spec-1234567890
Spec: ./specs/test-spec
Phase: research
Teammates: 3
  - research-analyst-1: idle
  - research-analyst-2: working (task 1.2)
  - research-analyst-3: idle
Status: Active
```

For orphaned teams:

```
WARNING: Orphaned team
Team: exec-old-spec-9876543210
Directory: ~/.claude/teams/exec-old-spec-9876543210
Age: 120 minutes
Cleanup: /ralph-specum:cleanup-teams
```

## Output

1. Active teams first (sorted by spec name)
2. Orphaned teams last (sorted by age, oldest first)
3. Summary: "X active teams, Y orphaned teams"

If no teams found: "No active agent teams"
