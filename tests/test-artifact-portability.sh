#!/bin/bash
# Test spec artifact portability
# Validates that spec artifacts (.ralph-state.json, tasks.md, templates, schemas)
# are tool-agnostic and can be read/parsed by any tool's adapter.
set -e

PASS=0
FAIL=0

TEMPLATE_DIR="plugins/ralph-specum/templates"
SCHEMA_FILE="plugins/ralph-specum/schemas/spec.schema.json"
SKILL_DIR="plugins/ralph-specum/skills/workflow"
SPEC_DIR="specs/opencode-codex-support"
STATE_FILE="$SPEC_DIR/.ralph-state.json"
TASKS_FILE="$SPEC_DIR/tasks.md"
OPENCODE_ADAPTER="adapters/opencode/hooks/execution-loop.ts"
IMPLEMENT_SKILL="$SKILL_DIR/implement/SKILL.md"

pass() {
  echo "  PASS: $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "  FAIL: $1"
  FAIL=$((FAIL + 1))
}

echo "=== Artifact Portability Tests ==="
echo ""

# ===========================================================================
# 1. Template tool-agnosticism
# ===========================================================================
echo "Test 1: Template tool-agnosticism..."

TOOL_KEYWORDS="Task tool|AskUserQuestion|TeamCreate|SendMessage|Stop hook|allowed-tools|subagent_type"

TEMPLATE_MATCHES=$(grep -rn "$TOOL_KEYWORDS" "$TEMPLATE_DIR"/ 2>/dev/null || true)
if [ -z "$TEMPLATE_MATCHES" ]; then
  pass "Templates contain zero tool-specific references"
else
  fail "Templates contain tool-specific references:"
  echo "$TEMPLATE_MATCHES" | while IFS= read -r line; do
    echo "    $line"
  done
fi

# Check each template individually
TEMPLATE_COUNT=$(ls "$TEMPLATE_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$TEMPLATE_COUNT" -gt 0 ]; then
  pass "Found $TEMPLATE_COUNT template files"
else
  fail "No template files found in $TEMPLATE_DIR"
fi

for tpl in "$TEMPLATE_DIR"/*.md; do
  NAME=$(basename "$tpl")
  MATCHES=$(grep -c "Task tool\|AskUserQuestion\|TeamCreate\|SendMessage\|Stop hook\|allowed-tools\|subagent_type" "$tpl" 2>/dev/null || true)
  if [ "$MATCHES" -eq 0 ]; then
    pass "Template $NAME: zero tool-specific refs"
  else
    fail "Template $NAME: $MATCHES tool-specific references"
  fi
done

echo ""

# ===========================================================================
# 2. State file structure (.ralph-state.json)
# ===========================================================================
echo "Test 2: State file structure..."

if [ ! -f "$STATE_FILE" ]; then
  fail "State file $STATE_FILE does not exist"
else
  pass "State file exists"

  # Check required fields using jq
  if command -v jq >/dev/null 2>&1; then
    REQUIRED_FIELDS="source name basePath phase taskIndex totalTasks taskIteration maxTaskIterations globalIteration maxGlobalIterations"

    for field in $REQUIRED_FIELDS; do
      VAL=$(jq -r ".$field // empty" "$STATE_FILE" 2>/dev/null)
      if [ -n "$VAL" ]; then
        pass "State has field: $field = $VAL"
      else
        fail "State missing field: $field"
      fi
    done

    # Validate field types
    PHASE=$(jq -r '.phase' "$STATE_FILE" 2>/dev/null)
    if echo "$PHASE" | grep -qE '^(research|requirements|design|tasks|execution)$'; then
      pass "State phase is valid enum: $PHASE"
    else
      fail "State phase '$PHASE' is not a valid enum"
    fi

    TASK_INDEX=$(jq -r '.taskIndex' "$STATE_FILE" 2>/dev/null)
    if [ "$TASK_INDEX" -ge 0 ] 2>/dev/null; then
      pass "State taskIndex is non-negative integer: $TASK_INDEX"
    else
      fail "State taskIndex is not a valid integer: $TASK_INDEX"
    fi

    TOTAL_TASKS=$(jq -r '.totalTasks' "$STATE_FILE" 2>/dev/null)
    if [ "$TOTAL_TASKS" -gt 0 ] 2>/dev/null; then
      pass "State totalTasks is positive integer: $TOTAL_TASKS"
    else
      fail "State totalTasks is not a valid positive integer: $TOTAL_TASKS"
    fi
  else
    fail "jq not available -- skipping JSON validation"
  fi
fi

echo ""

# ===========================================================================
# 3. Tasks.md format and parsability
# ===========================================================================
echo "Test 3: Tasks.md format and parsability..."

if [ ! -f "$TASKS_FILE" ]; then
  fail "Tasks file $TASKS_FILE does not exist"
else
  pass "Tasks file exists"

  # Check YAML frontmatter
  FIRST_LINE=$(head -1 "$TASKS_FILE")
  if [ "$FIRST_LINE" = "---" ]; then
    pass "tasks.md has opening frontmatter delimiter"
  else
    fail "tasks.md missing opening --- delimiter"
  fi

  # Extract frontmatter
  FRONTMATTER=$(awk 'NR==1{next} /^---$/{exit} {print}' "$TASKS_FILE")

  # Check spec field
  if echo "$FRONTMATTER" | grep -q '^spec:'; then
    pass "Frontmatter has spec field"
  else
    fail "Frontmatter missing spec field"
  fi

  # Check phase field
  if echo "$FRONTMATTER" | grep -q '^phase:'; then
    pass "Frontmatter has phase field"
  else
    fail "Frontmatter missing phase field"
  fi

  # Check total_tasks field
  if echo "$FRONTMATTER" | grep -q '^total_tasks:'; then
    pass "Frontmatter has total_tasks field"
  else
    fail "Frontmatter missing total_tasks field"
  fi

  # Check for task checkboxes (both checked and unchecked)
  CHECKED=$(grep -c '^\- \[x\]' "$TASKS_FILE" 2>/dev/null || true)
  UNCHECKED=$(grep -c '^\- \[ \]' "$TASKS_FILE" 2>/dev/null || true)
  TOTAL_CHECKBOXES=$((CHECKED + UNCHECKED))
  if [ "$TOTAL_CHECKBOXES" -gt 0 ]; then
    pass "tasks.md has $TOTAL_CHECKBOXES task checkboxes ($CHECKED checked, $UNCHECKED unchecked)"
  else
    fail "tasks.md has no task checkboxes"
  fi

  # Check for phase headers (## Phase N:)
  PHASE_HEADERS=$(grep -c '^## Phase [0-9]' "$TASKS_FILE" 2>/dev/null || true)
  if [ "$PHASE_HEADERS" -gt 0 ]; then
    pass "tasks.md has $PHASE_HEADERS phase headers"
  else
    fail "tasks.md missing phase headers (## Phase N:)"
  fi

  # Check task format includes required sections
  HAS_DO=$(grep -c '\*\*Do\*\*' "$TASKS_FILE" 2>/dev/null || true)
  HAS_FILES=$(grep -c '\*\*Files\*\*' "$TASKS_FILE" 2>/dev/null || true)
  HAS_DONE_WHEN=$(grep -c '\*\*Done when\*\*' "$TASKS_FILE" 2>/dev/null || true)
  HAS_VERIFY=$(grep -c '\*\*Verify\*\*' "$TASKS_FILE" 2>/dev/null || true)
  HAS_COMMIT=$(grep -c '\*\*Commit\*\*' "$TASKS_FILE" 2>/dev/null || true)

  for section in "Do:$HAS_DO" "Files:$HAS_FILES" "Done when:$HAS_DONE_WHEN" "Verify:$HAS_VERIFY" "Commit:$HAS_COMMIT"; do
    NAME="${section%%:*}"
    COUNT="${section##*:}"
    if [ "$COUNT" -gt 0 ]; then
      pass "tasks.md has $COUNT tasks with **$NAME** section"
    else
      fail "tasks.md missing **$NAME** sections in tasks"
    fi
  done
fi

echo ""

# ===========================================================================
# 4. Schema presence and tool-agnosticism
# ===========================================================================
echo "Test 4: Schema presence and tool-agnosticism..."

if [ ! -f "$SCHEMA_FILE" ]; then
  fail "Schema file $SCHEMA_FILE does not exist"
else
  pass "Schema file exists"

  # Check schema has no tool-specific references
  SCHEMA_MATCHES=$(grep -c "Task tool\|AskUserQuestion\|TeamCreate\|SendMessage\|Stop hook\|allowed-tools\|subagent_type\|claude-plugin\|hooks\.json" "$SCHEMA_FILE" 2>/dev/null || true)
  if [ "$SCHEMA_MATCHES" -eq 0 ]; then
    pass "Schema has zero tool-specific references"
  else
    fail "Schema has $SCHEMA_MATCHES tool-specific references"
  fi

  # Validate schema defines state structure
  if command -v jq >/dev/null 2>&1; then
    HAS_STATE_DEF=$(jq -r '.definitions.state // empty' "$SCHEMA_FILE" 2>/dev/null)
    if [ -n "$HAS_STATE_DEF" ]; then
      pass "Schema defines state structure"
    else
      fail "Schema missing state definition"
    fi

    # Check state definition has required fields matching actual state file
    for field in source name basePath phase taskIndex totalTasks taskIteration maxTaskIterations globalIteration maxGlobalIterations; do
      HAS_FIELD=$(jq -r ".definitions.state.properties.$field // empty" "$SCHEMA_FILE" 2>/dev/null)
      if [ -n "$HAS_FIELD" ]; then
        pass "Schema state defines property: $field"
      else
        fail "Schema state missing property: $field"
      fi
    done
  fi
fi

echo ""

# ===========================================================================
# 5. Cross-tool format consistency (OpenCode adapter reads same state format)
# ===========================================================================
echo "Test 5: Cross-tool format consistency..."

if [ ! -f "$OPENCODE_ADAPTER" ]; then
  fail "OpenCode adapter $OPENCODE_ADAPTER does not exist"
else
  pass "OpenCode adapter exists"

  # Check that the adapter's RalphState interface references the same fields
  # as the state file and schema
  STATE_FIELDS="phase taskIndex totalTasks taskIteration globalIteration maxGlobalIterations maxTaskIterations"

  for field in $STATE_FIELDS; do
    if grep -q "$field" "$OPENCODE_ADAPTER"; then
      pass "OpenCode adapter references field: $field"
    else
      fail "OpenCode adapter missing field: $field"
    fi
  done

  # Check adapter reads .ralph-state.json (same filename)
  if grep -q '\.ralph-state\.json' "$OPENCODE_ADAPTER"; then
    pass "OpenCode adapter reads .ralph-state.json"
  else
    fail "OpenCode adapter does not reference .ralph-state.json"
  fi

  # Check adapter reads tasks.md format
  if grep -q 'tasks\.md\|taskIndex\|totalTasks' "$OPENCODE_ADAPTER"; then
    pass "OpenCode adapter uses task index/count from state (compatible with tasks.md)"
  else
    fail "OpenCode adapter does not reference task progress fields"
  fi
fi

echo ""

# ===========================================================================
# 6. SKILL.md documents state format
# ===========================================================================
echo "Test 6: Implement SKILL.md documents state format..."

if [ ! -f "$IMPLEMENT_SKILL" ]; then
  fail "Implement SKILL.md $IMPLEMENT_SKILL does not exist"
else
  pass "Implement SKILL.md exists"

  # Check that SKILL.md documents the .ralph-state.json format
  if grep -q '\.ralph-state\.json' "$IMPLEMENT_SKILL"; then
    pass "SKILL.md documents .ralph-state.json"
  else
    fail "SKILL.md does not mention .ralph-state.json"
  fi

  # Check it documents key state fields
  DOCUMENTED_FIELDS="taskIndex totalTasks taskIteration maxTaskIterations globalIteration maxGlobalIterations"
  for field in $DOCUMENTED_FIELDS; do
    if grep -q "$field" "$IMPLEMENT_SKILL"; then
      pass "SKILL.md documents field: $field"
    else
      fail "SKILL.md does not document field: $field"
    fi
  done

  # Check it has a State File Format section or table
  if grep -q 'State File Format\|State Update Commands' "$IMPLEMENT_SKILL"; then
    pass "SKILL.md has state file format documentation section"
  else
    fail "SKILL.md missing state file format documentation"
  fi

  # Check it documents jq commands for state updates
  if grep -q 'jq' "$IMPLEMENT_SKILL"; then
    pass "SKILL.md documents jq state update commands"
  else
    fail "SKILL.md missing jq state update commands"
  fi

  # Check it documents task format (Do/Files/Done when/Verify/Commit)
  if grep -q 'Task Format' "$IMPLEMENT_SKILL"; then
    pass "SKILL.md documents task format"
  else
    fail "SKILL.md missing task format documentation"
  fi
fi

echo ""

# ===========================================================================
# Summary
# ===========================================================================
echo "========================================="
echo "Results: $PASS passed, $FAIL failed"
echo "========================================="
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "ALL TESTS PASSED"
