#!/usr/bin/env bash
#
# Plugin Compliance Validation Script
# Validates that all plugins follow plugin-dev best practices
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PLUGINS_DIR="$PROJECT_ROOT/plugins"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

errors=0
warnings=0

log_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

log_fail() {
    echo -e "${RED}✗${NC} $1"
    ((errors++)) || true
}

log_warn() {
    echo -e "${YELLOW}!${NC} $1"
    ((warnings++)) || true
}

log_section() {
    echo ""
    echo "=== $1 ==="
}

# Check 1: Agents have color field
log_section "Checking agents have color field"
for agent_file in "$PLUGINS_DIR"/*/agents/*.md; do
    if [[ -f "$agent_file" ]]; then
        agent_name=$(basename "$agent_file")
        plugin_name=$(basename "$(dirname "$(dirname "$agent_file")")")
        if grep -q "^color:" "$agent_file"; then
            log_pass "$plugin_name/$agent_name has color field"
        else
            log_fail "$plugin_name/$agent_name missing color field"
        fi
    fi
done

# Check 2: Agents have 2+ example blocks
log_section "Checking agents have 2+ example blocks"
for agent_file in "$PLUGINS_DIR"/*/agents/*.md; do
    if [[ -f "$agent_file" ]]; then
        agent_name=$(basename "$agent_file")
        plugin_name=$(basename "$(dirname "$(dirname "$agent_file")")")
        example_count=$(grep -c "<example>" "$agent_file" || echo "0")
        if [[ "$example_count" -ge 2 ]]; then
            log_pass "$plugin_name/$agent_name has $example_count example blocks"
        else
            log_fail "$plugin_name/$agent_name has only $example_count example blocks (need 2+)"
        fi
    fi
done

# Check 3: Skills have version field
log_section "Checking skills have version field"
for skill_file in "$PLUGINS_DIR"/*/skills/*/SKILL.md; do
    if [[ -f "$skill_file" ]]; then
        skill_name=$(basename "$(dirname "$skill_file")")
        plugin_name=$(basename "$(dirname "$(dirname "$(dirname "$skill_file")")")")
        if grep -q "^version:" "$skill_file"; then
            log_pass "$plugin_name/skills/$skill_name has version field"
        else
            log_fail "$plugin_name/skills/$skill_name missing version field"
        fi
    fi
done

# Check 4: Hooks have matcher field
log_section "Checking hooks have matcher field"
for hooks_file in "$PLUGINS_DIR"/*/hooks/hooks.json; do
    if [[ -f "$hooks_file" ]]; then
        plugin_name=$(basename "$(dirname "$(dirname "$hooks_file")")")
        # Validate that every hook object in .hooks.<event>[] has a matcher key
        if jq -e '[.hooks | to_entries[].value[] | has("matcher")] | all' "$hooks_file" > /dev/null 2>&1; then
            log_pass "$plugin_name/hooks/hooks.json has matcher field"
        else
            log_fail "$plugin_name/hooks/hooks.json missing matcher field in one or more hooks"
        fi
    fi
done

# Check 5: No legacy commands directory
log_section "Checking for legacy commands directories"
for plugin_dir in "$PLUGINS_DIR"/*/; do
    if [[ -d "$plugin_dir" ]]; then
        plugin_name=$(basename "$plugin_dir")
        legacy_dir="$plugin_dir.claude/commands"
        if [[ -d "$legacy_dir" ]]; then
            log_fail "$plugin_name has legacy commands directory at .claude/commands/"
        else
            log_pass "$plugin_name has no legacy commands directory"
        fi
    fi
done

# Summary
log_section "Summary"
echo ""
if [[ $errors -eq 0 ]]; then
    echo -e "${GREEN}All compliance checks passed!${NC}"
    if [[ $warnings -gt 0 ]]; then
        echo -e "${YELLOW}$warnings warning(s)${NC}"
    fi
    exit 0
else
    echo -e "${RED}$errors error(s) found${NC}"
    if [[ $warnings -gt 0 ]]; then
        echo -e "${YELLOW}$warnings warning(s)${NC}"
    fi
    exit 1
fi
