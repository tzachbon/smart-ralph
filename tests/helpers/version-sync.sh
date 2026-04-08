#!/usr/bin/env bash
set -euo pipefail
CLAUDE_VER=$(jq -r .version plugins/ralph-specum/.claude-plugin/plugin.json)
CODEX_VER=$(jq -r .version plugins/codex/.codex-plugin/plugin.json)
# marketplace may not have version field - skip if absent
if [ "$CLAUDE_VER" != "$CODEX_VER" ]; then
  echo "FAIL: Claude=$CLAUDE_VER Codex=$CODEX_VER"
  exit 1
fi
echo "PASS: versions in sync ($CLAUDE_VER)"
