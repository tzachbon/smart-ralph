#!/bin/bash
# test-claude-code-regression.sh
# Verifies zero regression for the existing Claude Code plugin.
# All core plugin files must be unchanged from the main branch.
set -e

PASS=0
FAIL=0
PLUGIN_DIR="plugins/ralph-specum"

pass() {
  echo "  PASS: $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "  FAIL: $1"
  FAIL=$((FAIL + 1))
}

# ---------------------------------------------------------------------------
# Test 1: plugin.json unchanged from main
# ---------------------------------------------------------------------------
echo "Test 1: plugin.json unchanged from main..."
DIFF_LINES=$(git diff main -- "$PLUGIN_DIR/.claude-plugin/plugin.json" | grep -c "^[+-][^+-]" 2>/dev/null || true)
if [ "$DIFF_LINES" -eq 0 ]; then
  pass "plugin.json unchanged"
else
  fail "plugin.json has $DIFF_LINES changed lines"
fi

# ---------------------------------------------------------------------------
# Test 2: hooks.json unchanged from main
# ---------------------------------------------------------------------------
echo "Test 2: hooks.json unchanged from main..."
if git ls-tree main -- "$PLUGIN_DIR/hooks/hooks.json" >/dev/null 2>&1; then
  DIFF_LINES=$(git diff main -- "$PLUGIN_DIR/hooks/hooks.json" | grep -c "^[+-][^+-]" 2>/dev/null || true)
  if [ "$DIFF_LINES" -eq 0 ]; then
    pass "hooks.json unchanged"
  else
    fail "hooks.json has $DIFF_LINES changed lines"
  fi
else
  # hooks.json may not exist on main — check it exists locally
  if [ -f "$PLUGIN_DIR/hooks/hooks.json" ]; then
    pass "hooks.json exists (new file, not a regression)"
  else
    pass "hooks.json not present on main or branch (ok)"
  fi
fi

# ---------------------------------------------------------------------------
# Test 3: stop-watcher.sh unchanged from main
# ---------------------------------------------------------------------------
echo "Test 3: stop-watcher.sh unchanged from main..."
DIFF_LINES=$(git diff main -- "$PLUGIN_DIR/hooks/scripts/stop-watcher.sh" | grep -c "^[+-][^+-]" 2>/dev/null || true)
if [ "$DIFF_LINES" -eq 0 ]; then
  pass "stop-watcher.sh unchanged"
else
  fail "stop-watcher.sh has $DIFF_LINES changed lines"
fi

# ---------------------------------------------------------------------------
# Test 4: All existing commands have correct frontmatter
# ---------------------------------------------------------------------------
echo "Test 4: Command frontmatter validation..."
for cmd in "$PLUGIN_DIR"/commands/*.md; do
  BASENAME=$(basename "$cmd")
  # Check YAML frontmatter delimiters
  FIRST_LINE=$(head -1 "$cmd")
  if [ "$FIRST_LINE" != "---" ]; then
    fail "$BASENAME missing opening frontmatter delimiter"
    continue
  fi
  # Find closing delimiter (second ---)
  CLOSING_LINE=$(awk 'NR>1 && /^---$/{print NR; exit}' "$cmd")
  if [ -z "$CLOSING_LINE" ]; then
    fail "$BASENAME missing closing frontmatter delimiter"
    continue
  fi
  # Check for 'description' field in frontmatter
  FRONTMATTER=$(sed -n "2,$((CLOSING_LINE - 1))p" "$cmd")
  if echo "$FRONTMATTER" | grep -q "^description:"; then
    pass "$BASENAME has valid frontmatter with description"
  else
    fail "$BASENAME frontmatter missing 'description' field"
  fi
done

# ---------------------------------------------------------------------------
# Test 5: All existing agents have correct frontmatter
# ---------------------------------------------------------------------------
echo "Test 5: Agent frontmatter validation..."
for agent in "$PLUGIN_DIR"/agents/*.md; do
  BASENAME=$(basename "$agent")
  FIRST_LINE=$(head -1 "$agent")
  if [ "$FIRST_LINE" != "---" ]; then
    fail "$BASENAME missing opening frontmatter delimiter"
    continue
  fi
  CLOSING_LINE=$(awk 'NR>1 && /^---$/{print NR; exit}' "$agent")
  if [ -z "$CLOSING_LINE" ]; then
    fail "$BASENAME missing closing frontmatter delimiter"
    continue
  fi
  FRONTMATTER=$(sed -n "2,$((CLOSING_LINE - 1))p" "$agent")
  # Agents need 'name' and 'description'
  HAS_NAME=false
  HAS_DESC=false
  echo "$FRONTMATTER" | grep -q "^name:" && HAS_NAME=true
  echo "$FRONTMATTER" | grep -q "^description:" && HAS_DESC=true
  if $HAS_NAME && $HAS_DESC; then
    pass "$BASENAME has valid frontmatter (name + description)"
  else
    fail "$BASENAME frontmatter missing name ($HAS_NAME) or description ($HAS_DESC)"
  fi
done

# ---------------------------------------------------------------------------
# Test 6: No core plugin files deleted
# ---------------------------------------------------------------------------
echo "Test 6: No core plugin files deleted..."
DELETED=$(git diff main --diff-filter=D --name-only -- "$PLUGIN_DIR/" 2>/dev/null || true)
if [ -z "$DELETED" ]; then
  pass "No plugin files deleted"
else
  fail "Deleted files: $DELETED"
fi

# ---------------------------------------------------------------------------
# Test 7: Core file checksums match main branch
# ---------------------------------------------------------------------------
echo "Test 7: Core file checksum comparison against main..."
CORE_FILES=(
  "$PLUGIN_DIR/.claude-plugin/plugin.json"
  "$PLUGIN_DIR/hooks/hooks.json"
  "$PLUGIN_DIR/hooks/scripts/stop-watcher.sh"
)
for cf in "${CORE_FILES[@]}"; do
  # Get main branch blob hash
  MAIN_HASH=$(git rev-parse "main:$cf" 2>/dev/null || echo "MISSING")
  HEAD_HASH=$(git rev-parse "HEAD:$cf" 2>/dev/null || echo "MISSING")
  BASENAME=$(basename "$cf")
  if [ "$MAIN_HASH" = "MISSING" ] && [ "$HEAD_HASH" = "MISSING" ]; then
    pass "$BASENAME not present on either branch (ok)"
  elif [ "$MAIN_HASH" = "MISSING" ]; then
    pass "$BASENAME is new (addition, not regression)"
  elif [ "$HEAD_HASH" = "MISSING" ]; then
    fail "$BASENAME exists on main but deleted on branch"
  elif [ "$MAIN_HASH" = "$HEAD_HASH" ]; then
    pass "$BASENAME blob hash matches main ($MAIN_HASH)"
  else
    fail "$BASENAME blob hash differs (main=$MAIN_HASH, HEAD=$HEAD_HASH)"
  fi
done

# ---------------------------------------------------------------------------
# Test 8: Commands unchanged from main (no regressions to existing commands)
# ---------------------------------------------------------------------------
echo "Test 8: Existing commands unchanged from main..."
MODIFIED_CMDS=$(git diff main --diff-filter=M --name-only -- "$PLUGIN_DIR/commands/" 2>/dev/null || true)
if [ -z "$MODIFIED_CMDS" ]; then
  pass "No existing commands modified"
else
  fail "Modified commands: $MODIFIED_CMDS"
fi

# ---------------------------------------------------------------------------
# Test 9: Agents unchanged from main
# ---------------------------------------------------------------------------
echo "Test 9: Existing agents unchanged from main..."
MODIFIED_AGENTS=$(git diff main --diff-filter=M --name-only -- "$PLUGIN_DIR/agents/" 2>/dev/null || true)
if [ -z "$MODIFIED_AGENTS" ]; then
  pass "No existing agents modified"
else
  fail "Modified agents: $MODIFIED_AGENTS"
fi

# ---------------------------------------------------------------------------
# Test 10: Only additions in plugin directory (no unexpected modifications)
# ---------------------------------------------------------------------------
echo "Test 10: Plugin changes are additions only (except allowed template tweak)..."
MODIFIED_FILES=$(git diff main --diff-filter=M --name-only -- "$PLUGIN_DIR/" 2>/dev/null || true)
UNEXPECTED=""
for mf in $MODIFIED_FILES; do
  # settings-template.md modification from task 1.1 is acceptable
  if [ "$(basename "$mf")" != "settings-template.md" ]; then
    UNEXPECTED="$UNEXPECTED $mf"
  fi
done
if [ -z "$UNEXPECTED" ]; then
  pass "Only allowed modifications (settings-template.md or none)"
else
  fail "Unexpected modifications:$UNEXPECTED"
fi

# ---------------------------------------------------------------------------
# Test 11: Hook scripts directory structure intact
# ---------------------------------------------------------------------------
echo "Test 11: Hook scripts directory structure..."
if [ -d "$PLUGIN_DIR/hooks/scripts" ]; then
  pass "hooks/scripts/ directory exists"
else
  fail "hooks/scripts/ directory missing"
fi
if [ -f "$PLUGIN_DIR/hooks/scripts/stop-watcher.sh" ]; then
  pass "stop-watcher.sh present"
else
  fail "stop-watcher.sh missing"
fi
if [ -x "$PLUGIN_DIR/hooks/scripts/stop-watcher.sh" ]; then
  pass "stop-watcher.sh is executable"
else
  fail "stop-watcher.sh is not executable"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "========================================"
echo "  Regression Test Summary"
echo "========================================"
echo "  PASSED: $PASS"
echo "  FAILED: $FAIL"
echo "  TOTAL:  $((PASS + FAIL))"
echo "========================================"

if [ "$FAIL" -gt 0 ]; then
  echo "REGRESSION DETECTED"
  exit 1
fi

echo "ALL REGRESSION CHECKS PASSED"
exit 0
