#!/bin/bash
# Test SKILL.md discoverability
# Validates all 8 workflow SKILL.md files are properly structured,
# discoverable, and tool-agnostic.
set -e

SKILL_DIR="plugins/ralph-specum/skills/workflow"
PASS=0
FAIL=0

EXPECTED_SKILLS="cancel design implement requirements research start status tasks"

pass() {
  echo "  PASS: $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "  FAIL: $1"
  FAIL=$((FAIL + 1))
}

# ---------------------------------------------------------------------------
# Test 1: SKILL.md file count
# ---------------------------------------------------------------------------
echo "Test 1: SKILL.md file count..."
COUNT=$(ls "$SKILL_DIR"/*/SKILL.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$COUNT" -eq 8 ]; then
  pass "Found $COUNT SKILL.md files"
else
  fail "Expected 8, found $COUNT"
fi

# ---------------------------------------------------------------------------
# Test 2: All expected skill directories exist
# ---------------------------------------------------------------------------
echo "Test 2: Expected skill directories..."
for skill in $EXPECTED_SKILLS; do
  if [ -f "$SKILL_DIR/$skill/SKILL.md" ]; then
    pass "$skill/SKILL.md exists"
  else
    fail "$skill/SKILL.md missing"
  fi
done

# ---------------------------------------------------------------------------
# Test 3: YAML frontmatter validation (name and description)
# ---------------------------------------------------------------------------
echo "Test 3: YAML frontmatter validation..."
for skill in $EXPECTED_SKILLS; do
  FILE="$SKILL_DIR/$skill/SKILL.md"
  # Check opening ---
  FIRST_LINE=$(head -1 "$FILE")
  if [ "$FIRST_LINE" != "---" ]; then
    fail "$skill: missing opening --- frontmatter delimiter"
    continue
  fi

  # Extract frontmatter (between first and second ---)
  FRONTMATTER=$(awk 'NR==1{next} /^---$/{exit} {print}' "$FILE")

  # Check name: field
  if echo "$FRONTMATTER" | grep -q '^name:'; then
    pass "$skill: has name field"
  else
    fail "$skill: missing name field in frontmatter"
  fi

  # Check description: field
  if echo "$FRONTMATTER" | grep -q '^description:'; then
    pass "$skill: has description field"
  else
    fail "$skill: missing description field in frontmatter"
  fi
done

# ---------------------------------------------------------------------------
# Test 4: Content after frontmatter
# ---------------------------------------------------------------------------
echo "Test 4: Content after frontmatter..."
for skill in $EXPECTED_SKILLS; do
  FILE="$SKILL_DIR/$skill/SKILL.md"
  # Count lines after second --- delimiter
  CONTENT_LINES=$(awk 'BEGIN{fm=0} /^---$/{fm++; next} fm>=2{print}' "$FILE" | grep -c . || true)
  if [ "$CONTENT_LINES" -gt 10 ]; then
    pass "$skill: has $CONTENT_LINES lines of content"
  else
    fail "$skill: only $CONTENT_LINES lines of content (expected >10)"
  fi
done

# ---------------------------------------------------------------------------
# Test 5: Progressive disclosure -- ## headings
# ---------------------------------------------------------------------------
echo "Test 5: Progressive disclosure (## headings)..."
for skill in $EXPECTED_SKILLS; do
  FILE="$SKILL_DIR/$skill/SKILL.md"
  HEADING_COUNT=$(grep -c '^## ' "$FILE" || true)
  if [ "$HEADING_COUNT" -ge 2 ]; then
    pass "$skill: has $HEADING_COUNT section headings"
  else
    fail "$skill: only $HEADING_COUNT section headings (expected >=2)"
  fi
done

# ---------------------------------------------------------------------------
# Test 6: Each has ## Overview section
# ---------------------------------------------------------------------------
echo "Test 6: Overview section present..."
for skill in $EXPECTED_SKILLS; do
  FILE="$SKILL_DIR/$skill/SKILL.md"
  if grep -q '^## Overview' "$FILE"; then
    pass "$skill: has ## Overview"
  else
    fail "$skill: missing ## Overview section"
  fi
done

# ---------------------------------------------------------------------------
# Test 7: Tool-agnosticism -- zero Claude Code-specific tool references
# ---------------------------------------------------------------------------
echo "Test 7: Tool-agnosticism (no Claude Code-specific references)..."
TOOL_REFS=$(grep -rn \
  "Task tool\|AskUserQuestion\|TeamCreate\|SendMessage\|allowed-tools\|subagent_type\|PreToolUse\|PostToolUse\|\.claude-plugin\|hooks\.json" \
  "$SKILL_DIR"/ 2>/dev/null || true)
if [ -z "$TOOL_REFS" ]; then
  pass "Zero Claude Code-specific tool references"
else
  fail "Found Claude Code-specific references:"
  echo "$TOOL_REFS" | while IFS= read -r line; do
    echo "    $line"
  done
fi

# ---------------------------------------------------------------------------
# Test 8: No broken internal file references
# ---------------------------------------------------------------------------
echo "Test 8: No broken file references..."
BROKEN=0
for skill in $EXPECTED_SKILLS; do
  FILE="$SKILL_DIR/$skill/SKILL.md"
  # Extract paths that look like file references (not URLs, not code blocks)
  # Check for references to other SKILL.md files within the workflow directory
  REFS=$(grep -oE 'workflow/[a-z]+/SKILL\.md' "$FILE" 2>/dev/null || true)
  if [ -n "$REFS" ]; then
    while IFS= read -r ref; do
      FULL_PATH="plugins/ralph-specum/skills/$ref"
      if [ ! -f "$FULL_PATH" ]; then
        fail "$skill: broken reference to $ref"
        BROKEN=$((BROKEN + 1))
      fi
    done <<< "$REFS"
  fi
done
if [ "$BROKEN" -eq 0 ]; then
  pass "No broken file references found"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "========================================="
echo "Results: $PASS passed, $FAIL failed"
echo "========================================="
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
echo "ALL TESTS PASSED"
