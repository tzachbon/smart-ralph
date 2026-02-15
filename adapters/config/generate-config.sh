#!/usr/bin/env bash
#
# generate-config.sh
#
# Reads ralph-config.json and generates tool-specific configuration files
# for Claude Code, OpenCode, and Codex CLI.
#
# Usage:
#   bash adapters/config/generate-config.sh [--config <path>] [--dry-run]
#
# Options:
#   --config <path>   Path to ralph-config.json (default: ./ralph-config.json)
#   --dry-run         Show what would be generated without writing files
#   --help            Show this help message
#
# Requirements:
#   - jq (JSON processor)

set -euo pipefail

# --- Defaults ---

CONFIG_PATH="./ralph-config.json"
DRY_RUN=false
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Colors (if terminal supports them) ---

if [ -t 1 ]; then
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  RED='\033[0;31m'
  BLUE='\033[0;34m'
  NC='\033[0m'
else
  GREEN='' YELLOW='' RED='' BLUE='' NC=''
fi

log_info()  { printf "${BLUE}[info]${NC}  %s\n" "$1"; }
log_ok()    { printf "${GREEN}[ok]${NC}    %s\n" "$1"; }
log_warn()  { printf "${YELLOW}[warn]${NC}  %s\n" "$1"; }
log_err()   { printf "${RED}[error]${NC} %s\n" "$1" >&2; }
log_dry()   { printf "${YELLOW}[dry]${NC}   %s\n" "$1"; }

# --- Argument parsing ---

usage() {
  printf "Usage: %s [--config <path>] [--dry-run]\n" "$(basename "$0")"
  printf "\nReads ralph-config.json and generates tool-specific configs.\n"
  printf "\nOptions:\n"
  printf "  --config <path>   Path to ralph-config.json (default: ./ralph-config.json)\n"
  printf "  --dry-run         Show what would be generated without writing files\n"
  printf "  --help            Show this help message\n"
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --config)
      CONFIG_PATH="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help)
      usage
      ;;
    *)
      log_err "Unknown option: $1"
      exit 1
      ;;
  esac
done

# --- Prerequisites ---

if ! command -v jq &>/dev/null; then
  log_err "jq is required but not installed. Install it: brew install jq (macOS) or apt install jq (Linux)"
  exit 1
fi

if [ ! -f "$CONFIG_PATH" ]; then
  log_err "Config file not found: $CONFIG_PATH"
  log_info "Create ralph-config.json in your project root. See adapters/config/README.md for format."
  exit 1
fi

# --- Read config ---

CONFIG="$(cat "$CONFIG_PATH")"

# Helper: read a config value with a default fallback
cfg() {
  local path="$1"
  local default="$2"
  local val
  val="$(printf '%s' "$CONFIG" | jq -r "$path // empty")"
  if [ -z "$val" ]; then
    printf '%s' "$default"
  else
    printf '%s' "$val"
  fi
}

# --- Read shared settings ---

SPEC_DIRS="$(printf '%s' "$CONFIG" | jq -r '.spec_dirs // ["./specs"] | .[]')"
DEFAULT_BRANCH="$(cfg '.default_branch' 'main')"

log_info "Config: $CONFIG_PATH"
log_info "Spec dirs: $(printf '%s' "$SPEC_DIRS" | tr '\n' ', ')"
log_info "Default branch: $DEFAULT_BRANCH"

SUMMARY=()

# --- Helper: write file (respects --dry-run) ---

write_file() {
  local path="$1"
  local content="$2"
  local desc="$3"

  if [ "$DRY_RUN" = true ]; then
    log_dry "Would write: $path ($desc)"
    return
  fi

  mkdir -p "$(dirname "$path")"
  printf '%s\n' "$content" > "$path"
  log_ok "Wrote: $path ($desc)"
}

# --- Claude Code ---

configure_claude_code() {
  local enabled
  enabled="$(cfg '.tools.claude_code.enabled' 'true')"
  if [ "$enabled" != "true" ]; then
    log_info "Claude Code: disabled, skipping"
    return
  fi

  local plugin_dir
  plugin_dir="$(cfg '.tools.claude_code.plugin_dir' './plugins/ralph-specum')"

  local plugin_json="${plugin_dir}/.claude-plugin/plugin.json"
  if [ -f "$plugin_json" ]; then
    log_ok "Claude Code: plugin already configured at $plugin_json"
    SUMMARY+=("Claude Code: validated (plugin at $plugin_dir)")
  else
    log_warn "Claude Code: plugin.json not found at $plugin_json"
    log_info "  Install the ralph-specum plugin or set tools.claude_code.plugin_dir in config"
    SUMMARY+=("Claude Code: WARNING - plugin not found at $plugin_dir")
  fi
}

# --- OpenCode ---

configure_opencode() {
  local enabled
  enabled="$(cfg '.tools.opencode.enabled' 'true')"
  if [ "$enabled" != "true" ]; then
    log_info "OpenCode: disabled, skipping"
    return
  fi

  local hooks_dir
  hooks_dir="$(cfg '.tools.opencode.hooks_dir' './adapters/opencode/hooks')"
  local generated_count=0

  # Create/update opencode.json with plugin entry
  local opencode_json="./opencode.json"
  if [ -f "$opencode_json" ]; then
    # Check if ralph plugin entry already exists
    if printf '%s' "$(cat "$opencode_json")" | jq -e '.plugins[] | select(.name == "ralph-specum")' &>/dev/null 2>&1; then
      log_ok "OpenCode: plugin entry already exists in opencode.json"
    else
      # Add ralph plugin entry to existing config
      local updated
      updated="$(jq --arg hooks "$hooks_dir" \
        '.plugins += [{"name": "ralph-specum", "hooks": $hooks}]' \
        "$opencode_json")"
      write_file "$opencode_json" "$updated" "OpenCode config (added ralph plugin)"
      generated_count=$((generated_count + 1))
    fi
  else
    # Create new opencode.json
    local new_config
    new_config=$(jq -n --arg hooks "$hooks_dir" '{
      "plugins": [
        {
          "name": "ralph-specum",
          "hooks": $hooks
        }
      ]
    }')
    write_file "$opencode_json" "$new_config" "OpenCode config"
    generated_count=$((generated_count + 1))
  fi

  # Create .opencode/ directories for commands and agents
  if [ "$DRY_RUN" = true ]; then
    log_dry "Would create: .opencode/commands/ .opencode/agents/"
  else
    mkdir -p .opencode/commands .opencode/agents
    log_ok "OpenCode: ensured .opencode/commands/ and .opencode/agents/ exist"
  fi

  # Copy workflow SKILL.md files to .opencode/ for discovery
  local skills_src="./plugins/ralph-specum/skills/workflow"
  if [ -d "$skills_src" ]; then
    local skill_count=0
    for skill_dir in "$skills_src"/*/; do
      local skill_name
      skill_name="$(basename "$skill_dir")"
      local skill_file="${skill_dir}SKILL.md"
      if [ -f "$skill_file" ]; then
        local dest=".opencode/commands/ralph-${skill_name}.md"
        if [ "$DRY_RUN" = true ]; then
          log_dry "Would copy: $skill_file -> $dest"
        else
          cp "$skill_file" "$dest"
        fi
        skill_count=$((skill_count + 1))
      fi
    done
    if [ "$DRY_RUN" = false ]; then
      log_ok "OpenCode: copied $skill_count workflow skills to .opencode/commands/"
    fi
    generated_count=$((generated_count + skill_count))
  else
    log_warn "OpenCode: workflow skills not found at $skills_src"
  fi

  SUMMARY+=("OpenCode: $generated_count files generated/updated")
}

# --- Codex CLI ---

configure_codex() {
  local enabled
  enabled="$(cfg '.tools.codex.enabled' 'true')"
  if [ "$enabled" != "true" ]; then
    log_info "Codex CLI: disabled, skipping"
    return
  fi

  local skills_dir
  skills_dir="$(cfg '.tools.codex.skills_dir' './.agents/skills')"
  local gen_agents
  gen_agents="$(cfg '.tools.codex.generate_agents_md' 'true')"
  local generated_count=0

  # Create skills directory
  if [ "$DRY_RUN" = true ]; then
    log_dry "Would create: ${skills_dir}/"
  else
    mkdir -p "$skills_dir"
  fi

  # Copy workflow SKILL.md files from the plugin
  local skills_src="./plugins/ralph-specum/skills/workflow"
  if [ -d "$skills_src" ]; then
    local skill_count=0
    for skill_dir in "$skills_src"/*/; do
      local skill_name
      skill_name="$(basename "$skill_dir")"
      local skill_file="${skill_dir}SKILL.md"
      if [ -f "$skill_file" ]; then
        local dest="${skills_dir}/ralph-${skill_name}"
        if [ "$DRY_RUN" = true ]; then
          log_dry "Would copy: $skill_file -> ${dest}/SKILL.md"
        else
          mkdir -p "$dest"
          cp "$skill_file" "${dest}/SKILL.md"
        fi
        skill_count=$((skill_count + 1))
      fi
    done
    if [ "$DRY_RUN" = false ]; then
      log_ok "Codex CLI: copied $skill_count workflow skills to ${skills_dir}/"
    fi
    generated_count=$((generated_count + skill_count))
  else
    log_warn "Codex CLI: workflow skills not found at $skills_src"
  fi

  # Copy Codex-specific implement SKILL.md (overrides the generic one)
  local codex_implement="./adapters/codex/skills/ralph-implement/SKILL.md"
  if [ -f "$codex_implement" ]; then
    local dest="${skills_dir}/ralph-implement"
    if [ "$DRY_RUN" = true ]; then
      log_dry "Would copy (Codex-specific): $codex_implement -> ${dest}/SKILL.md"
    else
      mkdir -p "$dest"
      cp "$codex_implement" "${dest}/SKILL.md"
      log_ok "Codex CLI: copied Codex-specific implement skill (overrides generic)"
    fi
    generated_count=$((generated_count + 1))
  fi

  # Generate AGENTS.md if enabled
  if [ "$gen_agents" = "true" ]; then
    local agents_script="./plugins/ralph-specum/scripts/generate-agents-md.sh"
    if [ -f "$agents_script" ]; then
      # Find the most recent spec with a design.md
      local latest_spec=""
      for spec_root in $SPEC_DIRS; do
        if [ -d "$spec_root" ]; then
          # Check .current-spec first
          local current_spec_file="${spec_root}/.current-spec"
          if [ -f "$current_spec_file" ]; then
            local current_name
            current_name="$(cat "$current_spec_file" | tr -d '[:space:]')"
            local candidate="${spec_root}/${current_name}"
            if [ -f "${candidate}/design.md" ]; then
              latest_spec="$candidate"
              break
            fi
          fi
          # Fallback: find most recently modified design.md
          for design_file in "$spec_root"/*/design.md; do
            if [ -f "$design_file" ]; then
              latest_spec="$(dirname "$design_file")"
            fi
          done
        fi
      done

      if [ -n "$latest_spec" ]; then
        if [ "$DRY_RUN" = true ]; then
          log_dry "Would run: generate-agents-md.sh --spec-path $latest_spec --force"
        else
          bash "$agents_script" --spec-path "$latest_spec" --force
          generated_count=$((generated_count + 1))
        fi
      else
        log_warn "Codex CLI: no spec with design.md found for AGENTS.md generation"
      fi
    else
      log_warn "Codex CLI: generate-agents-md.sh not found at $agents_script"
    fi
  fi

  SUMMARY+=("Codex CLI: $generated_count files generated/updated")
}

# --- Main ---

printf "\n"
log_info "=== Ralph Configuration Bridge ==="
printf "\n"

configure_claude_code
printf "\n"
configure_opencode
printf "\n"
configure_codex

# --- Summary ---

printf "\n"
log_info "=== Summary ==="
for item in "${SUMMARY[@]}"; do
  log_info "  $item"
done
printf "\n"

if [ "$DRY_RUN" = true ]; then
  log_warn "Dry run complete. No files were written."
else
  log_ok "Configuration generation complete."
fi
