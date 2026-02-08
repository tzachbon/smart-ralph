---
name: team-research
description: Use when running research phase with CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS enabled and goal spans 3+ parallel research topics. Manages team creation, parallel analyst spawning, findings merging, and team cleanup.
---

# Team Research Skill

Auto-invoked skill for parallel research with agent teams. Spawns 3-5 research teammates, merges findings, and manages team lifecycle.

## When To Use

Invoke this skill when ALL conditions are met:
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` environment variable is set to `1`
- Research phase has 3+ parallel research topics (web search, codebase analysis, documentation)
- No active team exists in `.ralph-state.json` (check `teamName` field)

**Example trigger scenarios:**
- Goal: "Add authentication with OAuth2, refresh tokens, and session management" (3+ topics)
- Goal: "Build dashboard with charts, real-time updates, and export to PDF" (3+ topics)
- Goal: "Implement caching, rate limiting, and request validation" (3+ topics)

## Environment Check

```bash
# Verify teams are enabled
if [ -z "$CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" ]; then
  echo "WARNING: Agent teams not enabled. Falling back to Task tool delegation."
  echo "Set CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 to enable teams."
  # Use existing Task tool workflow
  return
fi
```

## Team Naming Pattern

```
research-{specName}-{timestamp}
```

Examples:
- `research-auth-flow-1738900000`
- `research-dashboard-1738901234`
- `research-api-cache-1738902345`

## Workflow

### Step 1: Validate State File

Before creating team, ensure no active team exists:

```bash
STATE_FILE="./specs/${SPEC_NAME}/.ralph-state.json"

# Check for existing team
EXISTING_TEAM=$(jq -r '.teamName // empty' "$STATE_FILE" 2>/dev/null)

if [ -n "$EXISTING_TEAM" ]; then
  echo "ERROR: Active team already exists: $EXISTING_TEAM"
  echo "Cannot create new team. Use /ralph-specum:cancel to clean up existing team."
  exit 1
fi
```

### Step 2: Create Team

Use TeamCreate to initialize research team:

```
TeamCreate: research-{specName}-{timestamp}

Teammates: 3-5 research-analyst or Explore agents
```

Example:
```
TeamCreate("research-auth-flow-1738900000", {
  teammates: [
    "oauth2-researcher",
    "security-analyst",
    "codebase-explorer",
    "session-specialist",
    "token-expert"
  ]
})
```

### Step 3: Spawn Teammates

Delegate research topics to teammates in parallel. Use Task tool for each teammate:

```
# For web research topics
Task("oauth2-researcher", {
  type: "research-analyst",
  focus: "OAuth2 best practices, RFC 6749, security considerations",
  output: ".research-oauth2.md"
})

Task("security-analyst", {
  type: "research-analyst",
  focus: "Authentication security, OWASP guidelines, common vulnerabilities",
  output: ".research-security.md"
})

# For codebase analysis
Task("codebase-explorer", {
  type: "Explore",
  focus: "Analyze existing auth patterns, identify integration points",
  output: ".research-codebase.md"
})

# For documentation
Task("session-specialist", {
  type: "research-analyst",
  focus: "Session management best practices, cookie security",
  output: ".research-session.md"
})

Task("token-expert", {
  type: "research-analyst",
  focus: "JWT tokens, refresh token rotation, revocation strategies",
  output: ".research-tokens.md"
})
```

**Topic assignment patterns:**
- **Web search**: Use `research-analyst` agent for RFC docs, OWASP guides, best practices
- **Codebase analysis**: Use `Explore` agent for existing patterns, integration points
- **Documentation**: Use `research-analyst` for framework docs, API references
- **Security**: Use `research-analyst` for security guides, vulnerability patterns

### Step 4: Merge Findings

After all teammates complete, merge findings into `research.md`:

```bash
# Concatenate teammate outputs
cat > "./specs/${SPEC_NAME}/research.md" <<EOF
# Research: ${SPEC_NAME}

## Web Research

$(cat .research-oauth2.md)

$(cat .research-security.md)

## Codebase Analysis

$(cat .research-codebase.md)

## Documentation Review

$(cat .research-session.md)

$(cat .research-tokens.md)

## Key Findings

[Summarize merged insights, identify patterns, highlight conflicts]
EOF

# Cleanup temporary files
rm -f .research-*.md
```

**Merging guidelines:**
- Group by source type (Web Research, Codebase Analysis, Documentation)
- Remove duplicate findings
- Identify conflicting information (flag for resolution)
- Extract actionable insights for requirements phase
- Cite sources when applicable

### Step 5: Update State File

Record team creation in state:

```bash
# Update state with team metadata
jq --arg teamName "research-${SPEC_NAME}-${TIMESTAMP}" \
   --argjson teammateNames ["oauth2-researcher","security-analyst","codebase-explorer","session-specialist","token-expert"] \
   --arg teamPhase "research" \
   '. + {
     teamName: $teamName,
     teammateNames: $teammateNames,
     teamPhase: $teamPhase
   }' "$STATE_FILE" > "$STATE_FILE.tmp" && \
mv "$STATE_FILE.tmp" "$STATE_FILE"
```

### Step 6: Coordinate Shutdown Protocol

When research is complete, initiate graceful shutdown:

```bash
# Send shutdown requests to all teammates
for teammate in "${TEAMMATES[@]}"; do
  SendMessage({
    type: "shutdown_request",
    recipient: "$teammate",
    content: "Research complete. Shutting down team."
  })
done

# Wait for approvals (up to 10 seconds)
TIMEOUT=10
STARTED=$(date +%s)

while [ $(($(date +%s) - STARTED)) -lt $TIMEOUT ]; do
  # Check if all teammates approved
  APPROVED=$(jq -r '.teammateNames | all(.approved == true)' "$STATE_FILE")

  if [ "$APPROVED" = "true" ]; then
    break
  fi

  sleep 1
done
```

**Shutdown protocol:**
1. Send `shutdown_request` to all teammates via SendMessage
2. Wait up to 10 seconds for `shutdown_response` approvals
3. If timeout: Force shutdown (log warning, proceed to TeamDelete)
4. Each teammate responds with `shutdown_response(approve: true/false)`
5. Log any rejected shutdowns with teammate reasoning

### Step 7: Delete Team

Execute TeamDelete after shutdown protocol:

```
TeamDelete("research-{specName}-{timestamp}")
```

**Post-deletion validation:**
- Verify `~/.claude/teams/research-{specName}-{timestamp}/` directory removed
- Check for orphaned tmux sessions: `tmux list-sessions | grep research-`
- Log cleanup status

### Step 8: Clear State File

Remove team metadata from state:

```bash
# Clear team fields
jq 'del(.teamName, .teammateNames, .teamPhase)' "$STATE_FILE" > "$STATE_FILE.tmp" && \
mv "$STATE_FILE.tmp" "$STATE_FILE"
```

## Fallback Behavior

If teams unavailable or creation fails:

```bash
# ERROR: TeamCreate failed
echo "WARNING: Failed to create research team: $ERROR"
echo "Falling back to sequential Task tool delegation."

# Use existing research workflow (single research-analyst)
Task("research-analyst", {
  focus: "$GOAL",
  output: "research.md"
})
```

**Fallback triggers:**
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` not set
- TeamCreate command fails (API unavailable, permissions error)
- State file has existing `teamName` (team already active)
- Fewer than 3 research topics (parallelism not beneficial)

## Error Handling

### TeamCreate Fails

```
ERROR: TeamCreate failed - "API unavailable"
ACTION: Fallback to Task tool, log warning, continue with sequential research
```

### Teammate Spawn Fails

```
ERROR: Failed to spawn teammate "oauth2-researcher"
ACTION: Retry once, then continue with remaining teammates
LOG: "Research proceeding with 4/5 teammates"
```

### Findings Merge Fails

```
ERROR: Missing output .research-oauth2.md from teammate
ACTION: Log partial results, continue with available findings
LOG: "WARNING: Partial research results - 4/5 teammates completed"
```

### TeamDelete Fails

```
ERROR: TeamDelete failed - "Team not responding"
ACTION: Log tmux session ID, suggest manual cleanup
LOG: "WARNING: Orphaned team may require manual cleanup: tmux kill-session -t research-auth-flow-1738900000"
```

## Teammate Messaging

Encourage teammates to share discoveries:

```javascript
// Cross-team discovery sharing
SendMessage({
  type: "message",
  recipient: "security-analyst",
  content: "Found OAuth2 RFC 6749 recommends PKCE for public clients. Relevant to our security analysis.",
  summary: "OAuth2 PKCE recommendation"
})

// Conflict resolution
SendMessage({
  type: "message",
  recipient: "codebase-explorer",
  content: "Security guide says avoid localStorage for tokens, but codebase uses localStorage. Need to resolve this conflict.",
  summary: "Token storage conflict"
})
```

**When teammates should message:**
- Found patterns relevant to other teammates' focus
- Discovered conflicting information
- Completed early and can help with remaining topics
- Need clarification from another teammate's findings

## Quality Checks

After merging findings, verify:

```bash
# Check research.md created
test -f "./specs/${SPEC_NAME}/research.md" || {
  echo "ERROR: research.md not created"
  exit 1
}

# Check team deleted from state
jq -e '.teamName == null' "$STATE_FILE" || {
  echo "ERROR: teamName not cleared from state"
  exit 1
}

# Check no orphaned team directory
test ! -d "~/.claude/teams/research-${SPEC_NAME}-"*/ || {
  echo "WARNING: Orphaned team directory may exist"
  ls -la ~/.claude/teams/ | grep "research-${SPEC_NAME}"
}
```

## Integration Points

**Called by:**
- `commands/research.md` - After topic analysis detects 3+ parallel topics

**Updates:**
- `./specs/{specName}/.ralph-state.json` - Sets teamName, teammateNames, teamPhase
- `./specs/{specName}/research.md` - Creates merged research document

**Uses tools:**
- TeamCreate - Initialize research team
- Task - Spawn research teammates
- SendMessage - Coordinate shutdown, share discoveries
- TeamDelete - Cleanup after research complete

## References

- Design: `specs/ralph-agent-teams/design.md` - Components - New Team-Based Skills
- Requirements: AC-1.1 through AC-1.7, FR-1, FR-13
- State schema: `plugins/ralph-specum/schemas/spec.schema.json` - teamName, teammateNames, teamPhase
