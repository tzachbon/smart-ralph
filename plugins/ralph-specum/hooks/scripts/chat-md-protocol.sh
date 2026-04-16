#!/bin/bash
# chat-md-protocol.sh
# Atomic append with flock to prevent concurrent write corruption to chat.md
# Reference: plugins/ralph-specum/hooks/scripts/native-sync-pattern.md
# Used by: coordinator-core.md, all coordinator modules

# Atomic append for OVER response (when reviewer asks a question)
# Usage: ./chat-md-protocol.sh "Coordinator → External-Reviewer" "T1" "ACK" "Response to reviewer's question"
atomic_over_response() {
  local spec_path="$1"
  local writer="$2"
  local task="$3"
  local signal="$4"
  local response="$5"

  (
    exec 200>"$spec_path/chat.md.lock"
    flock -e 200 || exit 1
    cat >> "$spec_path/chat.md" << MSGEOF
### [$(date '+%Y-%m-%d %H:%M:%S')] Coordinator → External-Reviewer
**Task**: $task
**Signal**: $signal

$response
MSGEOF
  ) 200>"$spec_path/chat.md.lock"
}

# Step 5 — Announce task (write to chat.md before every delegation)
# This is the "pilot callout" — the coordinator announces what it is about to do
# so the reviewer can raise a HOLD before the task executes (on the NEXT cycle if needed)
announce_task() {
  local spec_path="$1"
  local task_index="$2"
  local task_title="$3"
  local do_summary="$4"
  local files_list="$5"
  local verify_cmd="$6"

  (
    exec 200>"$spec_path/chat.md.lock"
    flock -e 200 || exit 1
    cat >> "$spec_path/chat.md" << MSGEOF
### [$(date '+%Y-%m-%d %H:%M:%S')] Coordinator → External-Reviewer
**Task**: T$task_index — $task_title
**Signal**: CONTINUE

Delegating task $task_index to spec-executor:
- Do: $do_summary
- Files: $files_list
- Verify: $verify_cmd
MSGEOF
  ) 200>"$spec_path/chat.md.lock"
}

# Step 6 — After task completes: write a completion notice to chat.md
announce_task_complete() {
  local spec_path="$1"
  local task_index="$2"
  local task_title="$3"

  (
    exec 200>"$spec_path/chat.md.lock"
    flock -e 200 || exit 1
    cat >> "$spec_path/chat.md" << MSGEOF
### [$(date '+%Y-%m-%d %H:%M:%S')] Coordinator → External-Reviewer
**Task**: T$task_index — $task_title
**Signal**: CONTINUE

Task complete. Advancing to next task.
MSGEOF
  ) 200>"$spec_path/chat.md.lock"
}

# Helper: Get current timestamp
get_timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

# Usage examples:
# atomic_over_response "/path/to/spec" "Coordinator → External-Reviewer" "T1" "ACK" "Here is the response"
# announce_task "/path/to/spec" "1.1" "Create module" "Create the module file" "module.md" "test -f module.md"
# announce_task_complete "/path/to/spec" "1.1" "Create module"
