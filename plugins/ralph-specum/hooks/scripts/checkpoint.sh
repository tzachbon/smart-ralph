#!/usr/bin/env bash
# checkpoint.sh — Git checkpoint infrastructure for Smart Ralph execution loop.
# Provides checkpoint-create (pre-loop snapshot) and checkpoint-rollback (restore) functions.
# All string fields use jq -n --arg to prevent JSON injection.

# ---------------------------------------------------------------------------
# checkpoint-create: Snapshot the working tree before task execution begins.
#
# Usage: checkpoint-create <spec_name> <total_tasks> <state_file>
#
# Idempotent: if a checkpoint already exists in state_file, returns 0.
# Handles:
#   - No git repo (.git missing)    → sha=null, continue
#   - Detached HEAD                → warning, sha=null, continue
#   - Normal repo                  → git add -A + commit --no-verify, store SHA
# ---------------------------------------------------------------------------

checkpoint-create() {
  local spec_name="$1"
  local total_tasks="$2"
  local state_file="$3"

  # --- Idempotency: skip if checkpoint already stored ---
  if [ -f "$state_file" ] && jq -e '.checkpoint // empty' "$state_file" >/dev/null 2>&1; then
    echo "[ralph-specum] checkpoint already exists, skipping create"
    return 0
  fi

  # --- Locate git repo root ---
  local git_root=""
  local dir="$(cd "$(dirname "$state_file")" && pwd)"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.git" ]; then
      git_root="$dir"
      break
    fi
    dir="$(dirname "$dir")"
  done

  # --- No-repo detection ---
  if [ -z "$git_root" ]; then
    echo "[ralph-specum] no git repo found, storing null checkpoint"
    _write_checkpoint "$state_file" "null" "null" "null" "null"
    return 0
  fi

  # --- SR-017: Pre-check for read-only filesystem via /proc/mounts ---
  # If the filesystem is read-only, git commit will fail. Detect early.
  local fs_check_dir
  fs_check_dir="$(cd "$git_root" && pwd)"
  local is_read_only=false
  if [ -f /proc/mounts ]; then
    if grep -q "^.* ${fs_check_dir}.*ro[,\s]" /proc/mounts 2>/dev/null || \
       grep -q "^.* / ${fs_check_dir%%/*}.*ro[,\s]" /proc/mounts 2>/dev/null; then
      is_read_only=true
    fi
  fi
  # Also check via mount command for systems without /proc/mounts
  if [ "$is_read_only" = false ] && mount 2>/dev/null | grep -q " on ${fs_check_dir} .*ro[,\s]"; then
    is_read_only=true
  fi
  if [ "$is_read_only" = true ]; then
    echo "[ralph-specum] WARNING: filesystem appears read-only at ${fs_check_dir}, storing null checkpoint"
    _write_checkpoint "$state_file" "null" "null" "null" "null"
    return 0
  fi

  # --- Detached HEAD detection ---
  local branch
  branch="$(cd "$git_root" && git symbolic-ref HEAD 2>/dev/null)"
  if [ -z "$branch" ]; then
    echo "[ralph-specum] WARNING: detached HEAD detected, storing null checkpoint"
    _write_checkpoint "$state_file" "null" "null" "null" "null"
    return 0
  fi
  branch="$(echo "$branch" | sed 's|^refs/heads/||')"

  # --- Check jq version ---
  local jq_ver
  jq_ver="$(jq --version 2>/dev/null | sed 's/jq-\([0-9]*\)\.\([0-9]*\).*/\1\2/')"
  if [ "${jq_ver:0:2}" = "14" ] || [ "${jq_ver:0:2}" = "15" ]; then
    : # jq 1.4-1.5 OK
  elif [ -n "$jq_ver" ] && [ "${jq_ver:0:1}" -lt 1 ] 2>/dev/null; then
    echo "[ralph-specum] WARNING: jq version < 1.5 detected, some features may fail" >&2
  fi

  # --- Validate git config ---
  local git_user_name git_user_email
  git_user_name="$(git config user.name 2>/dev/null)"
  git_user_email="$(git config user.email 2>/dev/null)"
  if [ -z "$git_user_name" ] || [ -z "$git_user_email" ]; then
    echo "[ralph-specum] ERROR: git user.name and user.email must be configured" >&2
    return 1
  fi

  # --- Create git commit with --no-verify ---
  cd "$git_root"

  if ! git add -A 2>/dev/null; then
    echo "[ralph-specum] ERROR: git add -A failed, aborting checkpoint"
    return 1
  fi

  # Only commit if there are changes
  if git diff --cached --quiet 2>/dev/null; then
    # No changes — still create a meaningful checkpoint from the latest commit
    local sha
    sha="$(git log -1 --format=%H 2>/dev/null)"
    local ts
    ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    local msg="[ralph-specum] checkpoint ${spec_name} (${total_tasks} tasks) — no changes to commit"
    _write_checkpoint "$state_file" "$sha" "$ts" "$branch" "$msg"
    echo "[ralph-specum] checkpoint created: sha=${sha} (no changes to commit)"
    return 0
  fi

  if ! git commit -m "[ralph-specum] pre-execution checkpoint: ${spec_name}" --no-verify 2>/dev/null; then
    echo "[ralph-specum] ERROR: git commit failed, aborting checkpoint"
    return 1
  fi

  # --- Extract SHA ---
  local sha
  sha="$(git log -1 --format=%H 2>/dev/null)"
  if [ -z "$sha" ]; then
    echo "[ralph-specum] ERROR: failed to extract SHA from git log"
    return 1
  fi

  # --- Timestamp (macOS compatible) ---
  local ts
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  # --- Message ---
  local msg
  msg="[ralph-specum] checkpoint ${spec_name} (${total_tasks} tasks)"

  # --- Write to state file ---
  _write_checkpoint "$state_file" "$sha" "$ts" "$branch" "$msg"

  echo "[ralph-specum] checkpoint created: sha=${sha}"
  return 0
}

# ---------------------------------------------------------------------------
# _write_checkpoint: Write checkpoint object to state file.
# Uses jq -n --arg for all string values to prevent JSON injection.
# null values are passed via jq --argjson.
# ---------------------------------------------------------------------------

_write_checkpoint() {
  local state_file="$1"
  local sha="$2"
  local ts="$3"
  local branch="$4"
  local msg="$5"

  # Build the checkpoint object using jq -n --arg for strings,
  # --argjson for null values to get proper JSON null (not string "null")
  local sha_json ts_json branch_json msg_json

  if [ "$sha" = "null" ]; then
    sha_json="$(jq -n 'null')"
  else
    sha_json="$(jq -n --arg v "$sha" '$v')"
  fi

  if [ "$ts" = "null" ]; then
    ts_json="$(jq -n 'null')"
  else
    ts_json="$(jq -n --arg v "$ts" '$v')"
  fi

  if [ "$branch" = "null" ]; then
    branch_json="$(jq -n 'null')"
  else
    branch_json="$(jq -n --arg v "$branch" '$v')"
  fi

  if [ "$msg" = "null" ]; then
    msg_json="$(jq -n 'null')"
  else
    msg_json="$(jq -n --arg v "$msg" '$v')"
  fi

  # Merge with existing state if present, otherwise create new
  local existing
  existing="$(cat "$state_file" 2>/dev/null || echo '{}')"

  echo "$existing" | jq \
    --argjson sha "$sha_json" \
    --argjson ts "$ts_json" \
    --argjson branch "$branch_json" \
    --argjson msg "$msg_json" \
    '. + {checkpoint: {sha: $sha, timestamp: $ts, branch: $branch, message: $msg}}' \
    > "${state_file}.tmp"

  mv "${state_file}.tmp" "$state_file"
}

# ---------------------------------------------------------------------------
# checkpoint-rollback: Restore the working tree to the checkpoint SHA.
#
# Usage: checkpoint-rollback <state_file>
#
# Steps:
#   1. Read SHA from state file via jq
#   2. Validate SHA is not null/empty → return 1
#   3. Verify SHA exists via git cat-file -e → return 1 if missing
#   4. git reset --hard $sha
#   5. Return 0 on success
# ---------------------------------------------------------------------------

checkpoint-rollback() {
  local state_file="$1"

  if [ ! -f "$state_file" ]; then
    echo "[ralph-specum] ERROR: state file not found: ${state_file}"
    return 1
  fi

  # Read checkpoint SHA
  local sha
  sha="$(jq -r '.checkpoint.sha // empty' "$state_file" 2>/dev/null)"

  if [ -z "$sha" ]; then
    echo "[ralph-specum] ERROR: no checkpoint SHA found in state file"
    return 1
  fi

  # Locate git repo root
  local git_root=""
  local dir="$(cd "$(dirname "$state_file")" && pwd)"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.git" ]; then
      git_root="$dir"
      break
    fi
    dir="$(dirname "$dir")"
  done

  if [ -z "$git_root" ]; then
    echo "[ralph-specum] ERROR: no git repo found for rollback"
    return 1
  fi

  cd "$git_root"

  # Verify SHA exists in the repo
  if ! git cat-file -e "$sha" 2>/dev/null; then
    echo "[ralph-specum] ERROR: checkpoint SHA does not exist: ${sha}"
    return 1
  fi

  # Perform the rollback
  if ! git reset --hard "$sha" 2>/dev/null; then
    echo "[ralph-specum] ERROR: git reset --hard failed for ${sha}"
    return 1
  fi

  echo "[ralph-specum] rolled back to checkpoint: sha=${sha}"
  return 0
}
