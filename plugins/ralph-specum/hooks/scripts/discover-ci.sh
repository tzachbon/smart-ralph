#!/usr/bin/env bash
# discover-ci.sh — CI command discovery for Smart Ralph execution loop.
# Provides discover_ci_commands function that scans repo for CI commands.
# This is a standalone version to avoid sourcing the entire stop-watcher.sh.

# CI Command Discovery
discover_ci_commands() {
  local repo_root="$1"
  local tmpfile
  tmpfile=$(mktemp)

  # Scan .github/workflows/*.yml for "- run:" command lines
  if [ -d "$repo_root/.github/workflows" ]; then
    for wf in "$repo_root/.github/workflows"/*.yml; do
      [ -f "$wf" ] || continue
      # Extract content after "- run:" from each workflow file
      { grep -E '^\s+-\s+run:' "$wf" 2>/dev/null \
          | sed -E 's/^[[:space:]]*-[[:space:]]+run:[[:space:]]*//' \
          | while IFS= read -r line; do
              [ -z "$line" ] && continue
              # Skip YAML block scalar indicators and comments
              case "$line" in
                \#*|"|"*) continue ;;
              esac
              line=$(echo "$line" | sed 's/[[:space:]]*$//')
              [ -z "$line" ] && continue
              echo "$line"
            done; } >> "$tmpfile"
    done
  fi

  # Scan tests/*.bats for test commands
  if [ -d "$repo_root/tests" ]; then
    for bats_file in "$repo_root/tests"/*.bats; do
      [ -f "$bats_file" ] || continue
      # Extract test runner invocations (e.g., "bats tests/", "test/unit.sh")
      grep -E '^\s*(bats|test|./tests/)' "$bats_file" 2>/dev/null \
        | grep -v '^\s*#' \
        | grep -v '^\s*local ' \
        | head -5 \
        | sed 's/^[[:space:]]*//' \
        | sed 's/[[:space:]]*$//' \
        | grep -v '^$' \
        >> "$tmpfile"
    done
  fi

  # Deduplicate and return as JSON array
  if [ -s "$tmpfile" ]; then
    jq -R -n '[inputs | select(length > 0)] | unique' < "$tmpfile"
  else
    echo '[]'
  fi

  rm -f "$tmpfile"
}
