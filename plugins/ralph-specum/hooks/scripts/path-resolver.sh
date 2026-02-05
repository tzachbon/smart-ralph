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

# Internal: Log warning messages to stderr
_ralph_warn() {
    echo "[ralph-warn] $1" >&2
}

# Internal: Validate RALPH_CWD exists
_ralph_validate_cwd() {
    if [ ! -d "$RALPH_CWD" ]; then
        _ralph_warn "RALPH_CWD does not exist: $RALPH_CWD"
        return 1
    fi
    return 0
}

# Internal: Normalize path (remove trailing slashes, handle spaces)
_ralph_normalize_path() {
    local path="$1"
    # Remove trailing slashes (except for root /)
    path="${path%"${path##*[!/]}"}"
    # Handle empty result (was just slashes) -> return .
    if [ -z "$path" ]; then
        path="."
    fi
    echo "$path"
}

# Get configured specs directories (newline-separated)
# Validates each path and warns about invalid/missing paths
ralph_get_specs_dirs() {
    # Validate RALPH_CWD first
    if ! _ralph_validate_cwd; then
        echo "$RALPH_DEFAULT_SPECS_DIR"
        return 0
    fi

    local dirs=""
    local validated_dirs=""

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

    # If no dirs configured, use default
    if [ -z "$dirs" ]; then
        echo "$RALPH_DEFAULT_SPECS_DIR"
        return 0
    fi

    # Validate each configured path
    while IFS= read -r dir; do
        # Skip empty lines
        [ -z "$dir" ] && continue

        # Normalize path (handle trailing slashes, spaces)
        dir=$(_ralph_normalize_path "$dir")

        # Validate path format
        if [[ "$dir" == /* ]] && [[ "$dir" != "$RALPH_CWD"* ]]; then
            # Absolute path outside RALPH_CWD - check if it exists
            if [ ! -d "$dir" ]; then
                _ralph_warn "Skipping invalid absolute path in specs_dirs: $dir (does not exist)"
                continue
            fi
        elif [[ "$dir" == ./* ]] || [[ "$dir" != /* ]]; then
            # Relative path - check if it exists
            if [ ! -d "$RALPH_CWD/$dir" ]; then
                _ralph_warn "Skipping invalid path in specs_dirs: $dir (directory not found at $RALPH_CWD/$dir)"
                continue
            fi
        fi

        # Add validated dir
        if [ -n "$validated_dirs" ]; then
            validated_dirs="$validated_dirs"$'\n'"$dir"
        else
            validated_dirs="$dir"
        fi
    done <<< "$dirs"

    # If all paths were invalid, fall back to default
    if [ -z "$validated_dirs" ]; then
        _ralph_warn "No valid paths in specs_dirs, using default: $RALPH_DEFAULT_SPECS_DIR"
        echo "$RALPH_DEFAULT_SPECS_DIR"
    else
        echo "$validated_dirs"
    fi
}

# Get default directory for new specs (first in list)
ralph_get_default_dir() {
    local first_dir
    first_dir=$(ralph_get_specs_dirs | head -1)
    # Normalize path before returning
    _ralph_normalize_path "$first_dir"
}

# Resolve .current-spec to full path
# Handles: bare name -> ./specs/$name, full path -> as-is
ralph_resolve_current() {
    # Validate RALPH_CWD first
    if ! _ralph_validate_cwd; then
        return 1
    fi

    local default_dir
    default_dir=$(ralph_get_default_dir)
    local current_spec_file="$RALPH_CWD/$default_dir/.current-spec"

    # Check default location for .current-spec
    if [ -f "$current_spec_file" ]; then
        local content
        content=$(cat "$current_spec_file" 2>/dev/null | tr -d '[:space:]')

        if [ -z "$content" ]; then
            _ralph_warn ".current-spec file is empty"
            return 1
        fi

        # Normalize the path
        content=$(_ralph_normalize_path "$content")

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

    # Validate input
    if [ -z "$name" ]; then
        echo "ERROR: Spec name is required" >&2
        return 1
    fi

    # Validate RALPH_CWD
    if ! _ralph_validate_cwd; then
        return 1
    fi

    # Normalize name (handle trailing slashes, spaces in name)
    name=$(_ralph_normalize_path "$name")
    # Remove leading ./ if present
    name="${name#./}"

    local found=""
    local count=0
    local dirs
    dirs=$(ralph_get_specs_dirs)

    while IFS= read -r dir; do
        # Skip empty lines
        [ -z "$dir" ] && continue

        # Normalize dir path
        dir=$(_ralph_normalize_path "$dir")

        # Handle paths with spaces by quoting properly
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
    # Validate RALPH_CWD
    if ! _ralph_validate_cwd; then
        return 0  # Return empty list, not error
    fi

    local dirs
    dirs=$(ralph_get_specs_dirs)

    while IFS= read -r dir; do
        # Skip empty lines
        [ -z "$dir" ] && continue

        # Normalize dir path
        dir=$(_ralph_normalize_path "$dir")

        if [ -d "$RALPH_CWD/$dir" ]; then
            # Use find for better handling of paths with spaces
            # -maxdepth 1 -mindepth 1 gets only direct children
            while IFS= read -r spec_dir; do
                if [ -d "$spec_dir" ]; then
                    local name
                    name=$(basename "$spec_dir")
                    # Skip hidden directories
                    if [[ "$name" != .* ]]; then
                        echo "$name|$dir/$name"
                    fi
                fi
            done < <(find "$RALPH_CWD/$dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null)
        fi
    done <<< "$dirs"
}
