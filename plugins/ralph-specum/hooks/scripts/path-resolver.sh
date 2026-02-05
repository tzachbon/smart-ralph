#!/bin/bash
# Path Resolution Helper for Ralph Specum
# Source this file in hooks and commands
#
# Functions provided:
#   ralph_get_specs_dirs()   - Returns newline-separated list of configured dirs
#   ralph_find_spec(name)    - Returns full path to spec, handles disambiguation
#   ralph_list_specs()       - Returns all specs as "name|path" pairs
#   ralph_resolve_current()  - Returns full path from .current-spec
#   ralph_get_default_dir()  - Returns first specs_dir (for new spec creation)

RALPH_CWD="${RALPH_CWD:-$(pwd)}"
RALPH_SETTINGS_FILE="$RALPH_CWD/.claude/ralph-specum.local.md"
RALPH_DEFAULT_SPECS_DIR="./specs"

# Get configured specs directories (newline-separated)
ralph_get_specs_dirs() {
    local dirs=""

    if [ -f "$RALPH_SETTINGS_FILE" ]; then
        # Parse specs_dirs from YAML frontmatter
        # Format: specs_dirs: ["./specs", "./packages/api/specs"]
        dirs=$(sed -n '/^---$/,/^---$/p' "$RALPH_SETTINGS_FILE" 2>/dev/null \
            | grep -E '^specs_dirs:' \
            | sed 's/specs_dirs:[[:space:]]*//' \
            | tr -d '[]"' \
            | tr ',' '\n' \
            | sed 's/^[[:space:]]*//' \
            | sed 's/[[:space:]]*$//' \
            | grep -v '^$')
    fi

    # Default if empty or not found
    if [ -z "$dirs" ]; then
        echo "$RALPH_DEFAULT_SPECS_DIR"
    else
        echo "$dirs"
    fi
}

# Get default directory for new specs (first in list)
ralph_get_default_dir() {
    ralph_get_specs_dirs | head -1
}

# Resolve .current-spec to full path
# Handles: bare name -> ./specs/$name, full path -> as-is
ralph_resolve_current() {
    local default_dir
    default_dir=$(ralph_get_default_dir)
    local current_spec_file="$RALPH_CWD/$default_dir/.current-spec"

    # Check default location for .current-spec
    if [ -f "$current_spec_file" ]; then
        local content
        content=$(cat "$current_spec_file" 2>/dev/null | tr -d '[:space:]')

        if [ -z "$content" ]; then
            return 1
        fi

        # If starts with ./ or /, it's a full path
        if [[ "$content" == ./* ]] || [[ "$content" == /* ]]; then
            echo "$content"
        else
            # Bare name - assume default dir prefix
            echo "$default_dir/$content"
        fi
        return 0
    fi

    return 1
}

# Find spec by name across all roots
# Returns full path, or prompts if ambiguous
# Exit 1 if not found, exit 2 if ambiguous
ralph_find_spec() {
    local name="$1"
    local found=""
    local count=0
    local dirs
    dirs=$(ralph_get_specs_dirs)

    while IFS= read -r dir; do
        if [ -d "$RALPH_CWD/$dir/$name" ]; then
            if [ -n "$found" ]; then
                found="$found"$'\n'"$dir/$name"
            else
                found="$dir/$name"
            fi
            count=$((count + 1))
        fi
    done <<< "$dirs"

    if [ $count -eq 0 ]; then
        echo "ERROR: Spec '$name' not found in any configured directory" >&2
        return 1
    elif [ $count -eq 1 ]; then
        echo "$found"
        return 0
    else
        # Disambiguation needed
        echo "Multiple specs named '$name' found:" >&2
        echo "$found" | nl >&2
        echo "Specify full path: /ralph-specum:switch <path>" >&2
        return 2
    fi
}

# List all specs across all roots
# Output format: name|path per line
ralph_list_specs() {
    local dirs
    dirs=$(ralph_get_specs_dirs)

    while IFS= read -r dir; do
        if [ -d "$RALPH_CWD/$dir" ]; then
            for spec_dir in "$RALPH_CWD/$dir"/*/; do
                if [ -d "$spec_dir" ]; then
                    local name
                    name=$(basename "$spec_dir")
                    # Skip hidden directories
                    if [[ "$name" != .* ]]; then
                        echo "$name|$dir/$name"
                    fi
                fi
            done
        fi
    done <<< "$dirs"
}
