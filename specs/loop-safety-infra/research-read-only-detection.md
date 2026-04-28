# Research: Read-Only Filesystem Detection & Heartbeat Pattern

**Date:** 2026-04-26
**Spec:** loop-safety-infra
**Phase:** Research

---

## 1. Heartbeat Write Check Patterns

### 1.1 Core Pattern

The heartbeat write check is the most reliable method to detect read-only filesystems early, before they cause data corruption or silent failures. The pattern:

1. Write a small temp file to a known-writable directory
2. Verify we can read it back
3. Delete it (clean exit)
4. On any failure: log the error, set a `filesystemHealthy` flag in state

```bash
# Heartbeat check function for stop-watcher.sh
check_filesystem_heartbeat() {
    local check_dir="${1:-$CWD}"
    local heartbeat_file="$check_dir/.ralph-heartbeat.$$"
    local heartbeat_content="ok-$$-$(date +%s)"

    # Attempt write
    if ! echo "$heartbeat_content" > "$heartbeat_file" 2>/tmp/heartbeat-write-err; then
        local write_err
        write_err=$(cat /tmp/heartbeat-write-err 2>/dev/null || echo "unknown")
        echo "[ralph-specum] ALERT: Filesystem heartbeat write failed: $write_err" >&2
        rm -f /tmp/heartbeat-write-err
        return 1
    fi

    # Attempt read (verify round-trip)
    if ! read_content=$(cat "$heartbeat_file" 2>/dev/null); then
        echo "[ralph-specum] ALERT: Filesystem heartbeat read failed after successful write" >&2
        rm -f "$heartbeat_file" /tmp/heartbeat-write-err
        return 1
    fi

    # Verify content integrity
    if [ "$read_content" != "$heartbeat_content" ]; then
        echo "[ralph-specum] ALERT: Filesystem heartbeat content mismatch" >&2
        rm -f "$heartbeat_file" /tmp/heartbeat-write-err
        return 1
    fi

    # Clean up
    rm -f "$heartbeat_file" /tmp/heartbeat-write-err

    return 0
}
```

### 1.2 Why Round-Trip Check Matters

Writing alone is insufficient because:
- Some network filesystems report success on write but lose the data (split-brain)
- Some container overlays allow writes in one layer but not another
- The read-back verifies the filesystem is both writable AND coherent

### 1.3 Fallback: Permission-Based Check

As a lightweight pre-check (before the full heartbeat), test write permission on the spec directory:

```bash
# Lightweight pre-check (fast, no I/O, but less reliable)
check_write_permission() {
    local target_dir="$1"
    # Test-privileged: check if we can actually write, not just if the directory is writable
    # -w checks user permission; but this doesn't catch disk-full or read-only mount
    if [ ! -w "$target_dir" ]; then
        echo "[ralph-specum] WARNING: $target_dir is not writable" >&2
        return 1
    fi
    return 0
}
```

This is fast (no actual I/O) but only catches permission-based issues, not disk-full or read-only mount scenarios. Use it as a pre-filter, not a replacement.

---

## 2. Common Scenarios That Cause Read-Only Filesystems

### 2.1 Disk Full (ENOSPC)

**Most common cause in CI/CD and long-running agents.**

- Docker containers: overlay2 storage fills up
- CI runners: workspace fills up with artifacts, caches, build products
- Agent workspaces: progress files, temp files, git objects accumulate

Detection: `dmesg | grep -i 'no space left'` or check with `df -h`.

The heartbeat write fails with `No space left on device` (errno 28, ENOSPC), not EROFS.

### 2.2 NFS Mount Issues

**Very common in CI/CD environments.**

- NFS server goes down or becomes unreachable
- Network partition between client and NFS server
- NFS server remounts root filesystem read-only (fail-safe behavior)
- `soft` mount option causes I/O errors to propagate immediately

Detection: NFS errors often manifest as `Input/output error` (errno 5, EIO) rather than EROFS.

### 2.3 Container Mounts

**Docker/Podman-specific scenarios:**

- Host filesystem remounted read-only by the host OS (e.g., after filesystem errors)
- Overlayfs layer corruption
- Docker-in-Docker: inner container inherits host mount flags
- Named volumes: underlying storage driver reports errors

Detection: Docker containers get `EROFS` when the underlying host filesystem goes read-only.

### 2.4 Permission Changes

**Can happen through:**
- `chmod` on the spec directory
- `chown` by another process
- SELinux/AppArmor policy changes
- User context switches (sudo, su, container user mapping)

Detection: Permission errors (errno 13, EACCES). The lightweight `-w` test catches most cases.

### 2.5 Filesystem Errors

**OS-level:**
- ext4/xfs remounts read-only after detecting corruption
- `mount -o remount,ro /` triggered by admin or automated tools
- Snapshots/COW: if the snapshot device fails, the origin mount goes RO

Detection: Kernel messages, `dmesg`, `mount | grep ro`.

### 2.6 macOS-Specific: APFS Snapshots

- `tmutil` snapshots make APFS read-only during backup
- SIP can block writes to system directories

---

## 3. Temp File Strategy

### 3.1 Location

**Recommendation: Write to the spec directory itself**

```
specs/<name>/.ralph-heartbeat
```

Reasons:
- This is where the state file lives, so a failure here directly blocks execution
- The spec directory is already being written to (progress, state, etc.), so if it fails, it fails consistently
- It's the most likely directory to be affected by the scenarios above

Alternative locations for secondary checks:
- `$TMPDIR` or `/tmp`: catches host-level issues but misses spec-directory-specific problems
- `$CWD`: catches general CWD issues but not spec-directory-specific permission changes

### 3.2 File Name

Use a deterministic name with process ID:

```
.ralph-heartbeat.$$
```

Or even simpler (since we clean up immediately):

```
.ralph-heartbeat
```

The `.$$` suffix prevents races if multiple invocations happen simultaneously. Since the stop-watcher already uses file locking in other places, the simplest name works too.

**Decision: Use `.ralph-heartbeat` without PID suffix.** The heartbeat is so small (a few bytes) that the race window is negligible, and we use flock elsewhere in the hook.

### 3.3 Content

Keep it minimal. A single line with a timestamp:

```bash
echo "ok-$(date +%s)" > "$heartbeat_file"
```

Size: ~12 bytes. No need for base64 random data or crypto. The goal is functional, not integrity-heavy.

### 3.4 Cleanup Strategy

**Eager cleanup with no persistence.**

```bash
# Always clean up, even on failure paths
rm -f "$heartbeat_file"
```

On heartbeat failure (write/read error), do NOT clean up the file that partially existed — leave it for debugging. But the normal path should always clean up.

**Edge case:** If the filesystem is read-only, `rm` will also fail. That's fine — the file becomes a leftover artifact, but since we check heartbeat every loop iteration, it gets overwritten next time. Over time, stale heartbeat files accumulate in the spec directory.

**Mitigation:** Add a stale file cleanup step that removes `.ralph-heartbeat*` files older than 1 hour (same pattern already used for `.progress-task-*` cleanup at line 760 of stop-watcher.sh).

### 3.5 Alternative: O_TMPF (Linux 3.11+)

Linux supports creating anonymous temp files without a visible name:

```bash
# Linux only: creates file with no directory entry
exec 3<>"$check_dir/.ralph-o-temp" 2>/dev/null || true
if [ -fd 3 ]; then
    echo ok >&3
    # ... verify read ...
    exec 3>&-
fi
```

This avoids leftover files entirely. However:
- Not available on macOS or BSD
- Read-back requires `lseek` + `read`, more complex in bash
- Overkill for this use case

**Decision: Stick with simple temp file. Simplicity > elegance.**

---

## 4. Error Handling: errno Analysis

### 4.1 Primary errno Values

| errno | Value | Shell `$?` | Meaning | Detectable Pattern |
|-------|-------|-----------|---------|-------------------|
| EROFS | 30 | 30 | Read-only file system | `> "$file"` fails, stderr contains "Read-only file system" |
| EACCES | 13 | 13 | Permission denied | `> "$file"` fails, stderr contains "Permission denied" |
| ENOSPC | 28 | 28 | No space left on device | `> "$file"` fails, stderr contains "No space left" |
| EIO | 5 | 5 | Input/output error | `> "$file"` or `cat "$file"` fails, stderr contains "Input/output error" |
| ENOENT | 2 | 2 | No such file or directory | Directory was deleted or path changed |

### 4.2 Shell stderr Patterns

Bash redirection error messages are locale-dependent but generally:

```bash
echo "test" > /readonly/file 2>&1
# English: "Read-only file system"
# Other locales may differ
```

**Strategy: Check stderr content AND exit code.** Don't rely solely on errno values because:
1. Shell redirections don't expose errno directly to bash variables
2. `stat` can check mount flags without writing
3. The error message is more reliable than errno

### 4.3 Stat-Based Detection (Pre-Write Check)

Before attempting a write, check if the mount is read-only:

```bash
check_mount_ro() {
    local path="$1"
    # Read mount flags from /proc/mounts (Linux)
    if [[ "$OSTYPE" == "linux-gnu"* ]] && [ -f /proc/mounts ]; then
        local mount_point
        mount_point=$(df --output=target "$path" 2>/dev/null | tail -1)
        if [ -n "$mount_point" ] && grep -q " $mount_point .*ro," /proc/mounts; then
            return 1  # Read-only mount
        fi
    fi
    # macOS: check if volume is mounted readonly
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! diskutil info "$path" 2>/dev/null | grep -q '"Volume Type":.*RW'; then
            return 1
        fi
    fi
    return 0
}
```

**Limitations:**
- `/proc/mounts` not available on macOS
- Doesn't catch transient read-only (filesystem corruption that triggers ro remount mid-operation)
- Doesn't catch permission changes on individual directories

**Best use: Fast pre-filter before the actual write check.** If stat says RO, skip the write and fail fast. If stat says RW, still do the write check to catch transient issues.

### 4.4 Combined Detection Strategy

```bash
check_filesystem_heartbeat() {
    local check_dir="${1:-$CWD}"
    local heartbeat_file="$check_dir/.ralph-heartbeat"
    local heartbeat_content="ok-$(date +%s)"
    local err_file="/tmp/ralph-heartbeat-err.$$"

    # Step 1: Quick stat-based pre-check (Linux only)
    if [[ "$OSTYPE" == "linux-gnu"* ]] && [ -f /proc/mounts ]; then
        local mount_point
        mount_point=$(df --output=target "$check_dir" 2>/dev/null | tail -1)
        if [ -n "$mount_point" ] && grep -q " $mount_point .*ro," /proc/mounts 2>/dev/null; then
            echo "[ralph-specum] ALERT: $check_dir is mounted read-only (detected via /proc/mounts)" >&2
            rm -f "$err_file"
            return 1
        fi
    fi

    # Step 2: Write attempt
    echo "$heartbeat_content" > "$heartbeat_file" 2>"$err_file"
    if [ $? -ne 0 ]; then
        local err_msg
        err_msg=$(cat "$err_file" 2>/dev/null || echo "unknown error")
        echo "[ralph-specum] ALERT: Filesystem write failed: $err_msg" >&2
        rm -f "$err_file"
        return 1
    fi

    # Step 3: Read-back verification
    local read_content
    read_content=$(cat "$heartbeat_file" 2>/dev/null)
    if [ $? -ne 0 ] || [ "$read_content" != "$heartbeat_content" ]; then
        echo "[ralph-specum] ALERT: Filesystem round-trip failed after successful write" >&2
        rm -f "$heartbeat_file" "$err_file"
        return 1
    fi

    # Step 4: Cleanup
    rm -f "$heartbeat_file" "$err_file"
    return 0
}
```

---

## 5. How Other Tools Handle This

### 5.1 Kubernetes Liveness Probes

Kubernetes liveness probes are the gold standard for heartbeat-based health detection:

```yaml
livenessProbe:
  exec:
    command:
    - cat
    - /tmp/healthz
  initialDelaySeconds: 5
  periodSeconds: 10
  failureThreshold: 3
```

**Key patterns we can borrow:**
1. **Periodic check with threshold**: Fail after N consecutive failures, not just one. This prevents false positives from transient I/O glitches.
2. **Action on failure**: Kill the container (restart), which is analogous to blocking the loop in Ralph.
3. **Command-based, not metric-based**: The probe runs a specific command (`cat /tmp/healthz`) — not a CPU/memory threshold. We should do the same: run a specific filesystem write check.

**Relevance to Ralph**: Ralph is not in Kubernetes, but the threshold concept is valuable. One failed heartbeat should warn; three consecutive failures should block execution.

### 5.2 CI Runner Heartbeat Checks

**GitHub Actions runners:**
- Write a heartbeat file to the workspace every 60 seconds
- If the file stops updating for 3 minutes, the runner is marked as stuck
- Uses `touch` for the heartbeat, not content write

**GitLab CI runners:**
- Check disk space before job execution
- If disk usage > 90%, skip the job with a clear error
- Periodic health checks via HTTP endpoint (not filesystem)

**Buddy Works / Jenkins:**
- Test write to build artifact directory before starting
- If write fails, fail the build with "no write permission"

**Key pattern**: CI tools check filesystem writeability BEFORE starting a job, not during. This is the right approach for Ralph too — check at loop start, before doing any work.

### 5.3 Docker Healthcheck

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD cat /tmp/healthy || exit 1
```

Docker's healthcheck runs a command and treats non-zero exit as unhealthy. After `--retries` failures, the container is marked unhealthy. This is exactly the model Ralph should use.

### 5.4 Systemd Services

Systemd uses `RuntimeDirectory` directives and `ReadWritePaths` for tmpfiles:

```ini
[Service]
RuntimeDirectory=ralph-specum
ReadWritePaths=/home/user/project
```

Systemd enforces these at the service level via `ReadPaths`/`ReadWritePaths` cgroup settings. Not directly applicable to Ralph (no systemd cgroup enforcement), but the concept of declaring writable paths is useful for documentation.

### 5.5 Database Tools

**SQLite:** Opens with WAL mode and checks for journal file writes:
```bash
sqlite3 test.db "PRAGMA journal_mode=WAL;"
# If journal file can't be created, database is effectively read-only
```

Not directly relevant but the "attempt a write, fail fast" pattern is the same.

---

## 6. Integration with stop-watcher.sh

### 6.1 Where to Place the Check

**Location: Early in stop-watcher.sh, after CWD resolution and before state file reading.**

Current stop-watcher.sh flow:
1. Read input from stdin
2. Resolve CWD
3. Check enabled settings
4. Resolve spec path
5. Check state file exists
6. **INSERT HERE: Heartbeat check**
7. Race condition safeguard (stat on state file)
8. Main logic (ALL_TASKS_COMPLETE, repair loops, etc.)

This placement ensures:
- The check happens after we know the spec directory (step 4 resolves it)
- It happens before reading the state file (step 5), so we don't waste time reading state from a dead filesystem
- It gives a clear error message before any other logic runs

### 6.2 When to Check

**Every loop iteration, at stop-watcher start.**

The stop-watcher runs every time Claude Code yields control (after each tool call during task execution). So the heartbeat check runs at least once per task, and possibly multiple times within a task.

This means the check needs to be:
- Fast (< 100ms typically)
- Idempotent (same result every time)
- Cheap in terms of I/O (small file, minimal bytes)

### 6.3 What to Do on Failure

Three-tier response:

```
Tier 1 (first failure):
- Log warning to stderr
- Set filesystemHealthy=false in .ralph-state.json
- Continue execution (might be transient)

Tier 2 (second consecutive failure):
- Log error to stderr
- Output a block prompt: "Filesystem health check failed — verify disk space and permissions"
- Continue execution with warning flag

Tier 3 (third consecutive failure):
- Output BLOCK prompt with detailed recovery instructions
- Include disk space check command suggestions
- Set filesystemHealthy=false in state
- Block further execution until user acknowledges
```

**Implementation using state file fields:**

```json
{
  "filesystemHealthy": true,
  "filesystemHealthFailures": 0,
  "lastFilesystemCheck": "2026-04-26T12:00:00Z"
}
```

These fields get added to the state schema. The heartbeat function updates them.

### 6.4 Pseudo-Integration

```bash
# Insert after state file existence check (around line 46), before stat-based race safeguard

# ========================================
# Filesystem Health Check (heartbeat)
# ========================================
HEARTBEAT_DIR="$CWD/$SPEC_PATH"
HEARTBEAT_FILE="$HEARTBEAT_DIR/.ralph-heartbeat"
HEARTBEAT_CONTENT="ok-$(date +%s)"
HEARTBEAT_ERR="/tmp/ralph-hb-err.$$"

# Check if filesystem was previously marked unhealthy
PREV_HEALTHY=$(jq -r '.filesystemHealthy // true' "$STATE_FILE" 2>/dev/null || echo "true")
FAIL_COUNT=$(jq -r '.filesystemHealthFailures // 0' "$STATE_FILE" 2>/dev/null || echo "0")

# Only check if we're already unhealthy, or always check on first run
if [ "$PREV_HEALTHY" != "true" ] || [ "$FAIL_COUNT" -gt 0 ]; then
    # Attempt heartbeat
    echo "$HEARTBEAT_CONTENT" > "$HEARTBEAT_FILE" 2>"$HEARTBEAT_ERR"
    HB_RC=$?

    if [ $HB_RC -ne 0 ]; then
        HB_ERR=$(cat "$HEARTBEAT_ERR" 2>/dev/null || echo "unknown")
        FAIL_COUNT=$((FAIL_COUNT + 1))
        jq --argjson fc "$FAIL_COUNT" '.filesystemHealthFailures = $fc' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"

        if [ $FAIL_COUNT -ge 3 ]; then
            # Block with recovery instructions
            REASON=$(cat <<EOF
Filesystem health check failed (consecutive failures: $FAIL_COUNT)

Last error: $HB_ERR

## Immediate checks
1. Disk space: df -h "$CWD"
2. Permissions: ls -ld "$CWD"
3. Mount status: mount | grep "$CWD"

## Recovery
1. Fix the underlying issue (disk space, permissions, etc.)
2. Reset: jq '.filesystemHealthFailures = 0 | .filesystemHealthy = true' "$STATE_FILE"
3. Resume with /ralph-specum:implement
EOF
)
            jq -n --arg reason "$REASON" '{
                "decision": "block",
                "reason": $reason,
                "systemMessage": "Ralph-specum: filesystem health check failed — verify disk space and permissions"
            }'
            rm -f "$HEARTBEAT_ERR"
            exit 0
        fi

        echo "[ralph-specum] WARNING: Filesystem health check failed ($FAIL_COUNT/3): $HB_ERR" >&2
    else
        # Read-back verification
        HB_READ=$(cat "$HEARTBEAT_FILE" 2>/dev/null || echo "")
        if [ "$HB_READ" != "$HEARTBEAT_CONTENT" ]; then
            FAIL_COUNT=$((FAIL_COUNT + 1))
            jq --argjson fc "$FAIL_COUNT" '.filesystemHealthFailures = $fc' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
            echo "[ralph-specum] WARNING: Filesystem round-trip mismatch ($FAIL_COUNT/3)" >&2
        else
            # Success — reset counter
            FAIL_COUNT=0
            jq '.filesystemHealthFailures = 0 | .filesystemHealthy = true | .lastFilesystemCheck = now | todate' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
        fi
    fi
    rm -f "$HEARTBEAT_FILE" "$HEARTBEAT_ERR"
fi
```

### 6.5 Performance Impact

The heartbeat check is:
- `echo > file`: ~1ms
- `cat file`: ~1ms
- `rm file`: <1ms
- `grep /proc/mounts` (optional stat pre-check): ~5ms on Linux

Total: ~7ms per invocation. At worst, this adds ~7ms per loop iteration. Given that each loop iteration typically takes seconds to minutes (waiting for Claude to execute tasks), the overhead is negligible.

---

## 7. Recommendations for Smart Ralph Implementation

### 7.1 Tiered Approach (Recommended)

**Phase 1: Write-only heartbeat (MVP)**
- Simple `echo "ok" > .ralph-heartbeat` with error logging
- Set `filesystemHealthy: false` on failure
- Block on 3 consecutive failures
- No stat pre-check, no read-back verification initially
- Time to implement: ~1 hour

**Phase 2: Full round-trip check**
- Add read-back verification
- Add stat-based mount pre-check (Linux only, optional)
- Add filesystem check to state schema
- Time to implement: ~2 hours

**Phase 3: Disk space monitoring**
- Run `df` when heartbeat fails
- Include disk usage % in error messages
- Add configurable thresholds (warn at 90%, block at 95%)
- Time to implement: ~1 hour

### 7.2 Schema Changes

Add these fields to the `state` definition in `spec.schema.json`:

```json
"filesystemHealthy": {
    "type": "boolean",
    "default": true,
    "description": "Whether filesystem health checks have been passing"
},
"filesystemHealthFailures": {
    "type": "integer",
    "minimum": 0,
    "default": 0,
    "description": "Consecutive filesystem health check failures"
},
"lastFilesystemCheck": {
    "type": "string",
    "format": "date-time",
    "description": "ISO timestamp of last filesystem health check"
}
```

### 7.3 Implementation Locations

1. **`hooks/scripts/stop-watcher.sh`** — Insert heartbeat check early in the script (after state file existence check, before main logic)
2. **`schemas/spec.schema.json`** — Add `filesystemHealthy`, `filesystemHealthFailures`, `lastFilesystemCheck` to state definition
3. **`references/loop-safety.md`** — Document the filesystem health check policy and recovery procedures

### 7.4 What NOT to Do

- Don't run the heartbeat during task execution (inside each task). The stop-watcher runs at loop boundaries, which is sufficient.
- Don't add complex alerting (email, Slack, etc.). This is a local-first plugin. Log to stderr and block execution.
- Don't try to auto-heal the filesystem. If disk is full, Ralph can't fix it. Report and block.
- Don't use `O_TMPFILE` or other Linux-specific features. Keep it POSIX-compatible.
- Don't check `/tmp` as the heartbeat location. It might be writable while the spec directory is not.

### 7.5 Test Cases

```bash
# Test 1: Normal operation (should pass)
check_filesystem_heartbeat "/tmp"  # should succeed

# Test 2: Read-only filesystem (should fail)
# Create a loopback device mounted read-only
mkfs.ext4 -F /tmp/ro-test.img 1M
mount -o loop,ro /tmp/ro-test.img /mnt/ro
check_filesystem_heartbeat "/mnt/ro"  # should fail with EROFS

# Test 3: Permission denied (should fail)
mkdir /tmp/ro-test-perm
chmod 000 /tmp/ro-test-perm
check_filesystem_heartbeat "/tmp/ro-test-perm"  # should fail with EACCES

# Test 4: Non-existent directory (should fail)
check_filesystem_heartbeat "/tmp/nonexistent-dir-12345"  # should fail with ENOENT

# Test 5: Disk full (should fail with ENOSPC)
# Create a small loopback and fill it
mkfs.ext4 -F /tmp/full-test.img 1M
mount -o loop /tmp/full-test.img /mnt/full
dd if=/dev/zero of=/mnt/full/fill bs=1M
check_filesystem_heartbeat "/mnt/full"  # should fail with ENOSPC
```

---

## Appendix: Errno Reference Table

| errno | Symbol | Value | Description | Typical Cause |
|-------|--------|-------|-------------|---------------|
| 0 | EPERM/EINVAL | Various | Permission-related | chmod, chown, ACL |
| 2 | ENOENT | 2 | No such file or directory | Path deleted, typo |
| 5 | EIO | 5 | Input/output error | Disk hardware failure, NFS disconnect |
| 13 | EACCES | 13 | Permission denied | chmod 000, SELinux, capability denied |
| 28 | ENOSPC | 28 | No space left on device | Disk full, inode quota exceeded |
| 30 | EROFS | 30 | Read-only file system | mount -o ro, filesystem corruption recovery, NFS server remount |

---

## Appendix: Alternative Approaches Considered

### A. statfs() System Call

```c
// C-level check (not available in bash)
struct statfs fs;
if (statfs(path, &fs) == 0) {
    if (fs.f_flags & ST_RDONLY) {
        // read-only
    }
}
```

Not applicable in bash. Would require a helper binary. **Rejected** for simplicity.

### B. inotify / fanotify Watchers

Monitor filesystem events for read-only transitions. Complex, overkill for a simple health check, and not cross-platform. **Rejected**.

### C. Cron-based Background Health Check

Run a separate process that writes heartbeat files and monitors them. Adds process management complexity. **Rejected** — the stop-watcher already runs every loop iteration, which is sufficient frequency.

### D. Docker / Kubernetes-native Health Endpoint

Expose an HTTP endpoint that checks filesystem health. Works in containerized environments but adds networking complexity. **Rejected** — Ralph runs in Claude Code, not as a service.

---

## Summary of Key Findings

1. **Heartbeat write + read-back** is the most reliable detection method. It catches EROFS, ENOSPC, EIO, and EACCES in a single atomic check.

2. **Stat pre-check** (reading `/proc/mounts` on Linux) is a fast early filter but cannot replace the write check because it misses transient read-only conditions.

3. **Three-tier response** (warn on 1st failure, escalate on 2nd, block on 3rd) prevents false positives from transient I/O glitches while catching persistent issues early.

4. **Placement matters**: Check at stop-watcher start, before state file reads, so we don't waste work on a dead filesystem.

5. **Cost is negligible**: ~7ms per check, running at loop boundaries where each iteration already takes seconds or minutes.

6. **No auto-recovery**: Ralph should report filesystem issues and block, not attempt to fix them. Disk space, NFS mounts, and filesystem corruption are outside the plugin's responsibility.

7. **State tracking**: Use `filesystemHealthy` and `filesystemHealthFailures` fields in `.ralph-state.json` to maintain state across loop iterations.
