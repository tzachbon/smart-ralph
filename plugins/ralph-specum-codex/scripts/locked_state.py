#!/usr/bin/env python3
"""Locked Ralph state updates for overlay prototype state."""

from __future__ import annotations

import argparse
import contextlib
import json
import os
import socket
import sys
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable

try:
    import fcntl  # type: ignore
except ImportError:  # pragma: no cover - exercised on Windows
    fcntl = None


JSON = dict[str, Any]
Update = Callable[[JSON], JSON | None]


class StateError(SystemExit):
    pass


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def parse_scalar(raw: str) -> Any:
    lowered = raw.lower()
    if lowered == "true":
        return True
    if lowered == "false":
        return False
    if lowered == "null":
        return None
    try:
        return int(raw)
    except ValueError:
        return raw


def parse_pairs(items: list[str], as_json: bool) -> JSON:
    merged: JSON = {}
    for item in items:
        if "=" not in item:
            raise StateError(f"Invalid assignment: {item}")
        key, value = item.split("=", 1)
        key = key.strip()
        value = value.strip()
        if not key:
            raise StateError(f"Invalid assignment: {item}")
        if as_json:
            try:
                merged[key] = json.loads(value)
            except json.JSONDecodeError as exc:
                raise StateError(f"Invalid JSON for '{key}': {exc.msg}") from exc
        else:
            merged[key] = parse_scalar(value)
    return merged


def read_json_object(path: Path) -> JSON:
    if not path.exists():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise StateError(f"State file is not valid JSON: {path} ({exc.msg})") from exc
    if not isinstance(data, dict):
        raise StateError("State file must contain a JSON object.")
    return data


def fsync_dir(path: Path) -> None:
    if not hasattr(os, "O_DIRECTORY"):
        return
    try:
        fd = os.open(path, os.O_RDONLY | os.O_DIRECTORY)
    except OSError:
        return
    try:
        os.fsync(fd)
    except OSError:
        return
    finally:
        os.close(fd)


def write_json_atomic(path: Path, state: JSON) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp_path = path.parent / f"{path.name}.tmp"
    encoded = json.dumps(state, indent=2, sort_keys=True) + "\n"
    with tmp_path.open("w", encoding="utf-8") as handle:
        handle.write(encoded)
        handle.flush()
        os.fsync(handle.fileno())
    os.replace(tmp_path, path)
    fsync_dir(path.parent)


def pid_exists(pid: int) -> bool:
    if pid <= 0:
        return False
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    except OSError:
        return False
    return True


def lock_metadata() -> JSON:
    return {
        "host": socket.gethostname(),
        "pid": os.getpid(),
        "created": utc_now(),
        "heartbeatAt": utc_now(),
    }


@contextlib.contextmanager
def posix_lock(lock_path: Path, timeout: float):
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    with lock_path.open("a+", encoding="utf-8") as handle:
        deadline = time.monotonic() + timeout
        while True:
            try:
                fcntl.flock(handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)  # type: ignore[union-attr]
                handle.seek(0)
                handle.truncate()
                handle.write(json.dumps(lock_metadata(), sort_keys=True) + "\n")
                handle.flush()
                os.fsync(handle.fileno())
                break
            except BlockingIOError:
                if time.monotonic() >= deadline:
                    raise StateError(f"Timed out acquiring lock: {lock_path}")
                time.sleep(0.05)
        try:
            yield
        finally:
            fcntl.flock(handle.fileno(), fcntl.LOCK_UN)  # type: ignore[union-attr]


def parse_time(raw: Any) -> float | None:
    if not isinstance(raw, str):
        return None
    try:
        return datetime.fromisoformat(raw.replace("Z", "+00:00")).timestamp()
    except ValueError:
        return None


def try_break_stale_lock(lock_path: Path, stale_seconds: int) -> bool:
    owner_path = lock_path / "owner.json"
    try:
        owner = json.loads(owner_path.read_text(encoding="utf-8"))
    except Exception:
        return False
    if not isinstance(owner, dict):
        return False
    heartbeat = parse_time(owner.get("heartbeatAt") or owner.get("created"))
    if heartbeat is None or time.time() - heartbeat < stale_seconds:
        return False
    if owner.get("host") == socket.gethostname() and pid_exists(int(owner.get("pid") or 0)):
        return False
    try:
        owner_path.unlink(missing_ok=True)
        lock_path.rmdir()
        return True
    except OSError:
        return False


@contextlib.contextmanager
def directory_lock(lock_path: Path, timeout: float, stale_seconds: int = 600):
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    deadline = time.monotonic() + timeout
    acquired = False
    while True:
        try:
            os.mkdir(lock_path)
            acquired = True
            (lock_path / "owner.json").write_text(json.dumps(lock_metadata(), sort_keys=True) + "\n", encoding="utf-8")
            break
        except FileExistsError:
            try_break_stale_lock(lock_path, stale_seconds)
            if time.monotonic() >= deadline:
                raise StateError(f"Timed out acquiring lock: {lock_path}")
            time.sleep(0.05)
    try:
        yield
    finally:
        if acquired:
            try:
                (lock_path / "owner.json").unlink(missing_ok=True)
                lock_path.rmdir()
            except OSError:
                pass


def lock_for(state_path: Path, timeout: float):
    lock_path = state_path.parent / ".ralph-state.lock"
    if fcntl is not None and os.name != "nt":
        return posix_lock(lock_path, timeout)
    return directory_lock(lock_path, timeout)


def mutate_state(state_path: Path, timeout: float, update: Update, *, delete: bool = False) -> JSON:
    with lock_for(state_path, timeout):
        state = read_json_object(state_path)
        result = update(state)
        if result is None:
            result = state
        if delete:
            active = result.get("activePrototypes")
            if isinstance(active, dict) and active:
                raise StateError("Refusing to delete state with activePrototypes.")
            if state_path.exists():
                state_path.unlink()
                fsync_dir(state_path.parent)
            return {"deleted": True}
        write_json_atomic(state_path, result)
        return result


def active_map(state: JSON) -> JSON:
    active = state.get("activePrototypes")
    if active is None:
        active = {}
        state["activePrototypes"] = active
    if not isinstance(active, dict):
        raise StateError("activePrototypes must be an object.")
    return active


def get_entry(state: JSON, prototype_id: str) -> JSON:
    entry = active_map(state).get(prototype_id)
    if not isinstance(entry, dict):
        raise StateError(f"Prototype not found: {prototype_id}")
    return entry


def bump(entry: JSON) -> None:
    entry["stateRevision"] = int(entry.get("stateRevision") or 0) + 1
    entry["updated"] = utc_now()


def ensure_revision(entry: JSON, expected: int | None) -> None:
    if expected is None:
        return
    current = int(entry.get("stateRevision") or 0)
    if current != expected:
        raise StateError(f"stateRevision mismatch: expected {expected}, found {current}")


def ensure_token(entry: JSON, token: str | None) -> None:
    if token is not None and entry.get("leaseToken") != token:
        raise StateError("leaseToken mismatch")


def live_lease(entry: JSON, owner: str) -> bool:
    entry_owner = entry.get("owner")
    if not entry_owner or entry_owner == owner:
        return False
    expires = parse_time(entry.get("leaseExpires"))
    return expires is not None and expires > time.time()


def lease_until(seconds: int, hard_deadline: Any = None) -> str:
    target = time.time() + seconds
    hard = parse_time(hard_deadline)
    if hard is not None:
        target = min(target, hard)
    return datetime.fromtimestamp(target, timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def cmd_merge(args: argparse.Namespace) -> JSON:
    if args.stdout:
        state = read_json_object(args.state)
        state.update(parse_pairs(args.set, as_json=False))
        state.update(parse_pairs(args.json, as_json=True))
        return state

    def update(state: JSON) -> JSON:
        state.update(parse_pairs(args.set, as_json=False))
        state.update(parse_pairs(args.json, as_json=True))
        return state

    return mutate_state(args.state, args.timeout, update)


def cmd_upsert(args: argparse.Namespace) -> JSON:
    try:
        entry = json.loads(args.entry_json)
    except json.JSONDecodeError as exc:
        raise StateError(f"Invalid entry JSON: {exc.msg}") from exc
    if not isinstance(entry, dict):
        raise StateError("entry-json must be a JSON object.")
    entry["id"] = args.id

    def update(state: JSON) -> JSON:
        active_map(state)[args.id] = entry
        return state

    return mutate_state(args.state, args.timeout, update)


def cmd_remove(args: argparse.Namespace) -> JSON:
    def update(state: JSON) -> JSON:
        active = active_map(state)
        active.pop(args.id, None)
        if not active:
            state.pop("activePrototypes", None)
        return state

    mutate_state(args.state, args.timeout, update)
    return {"removed": args.id}


def cmd_list(args: argparse.Namespace) -> JSON:
    state = read_json_object(args.state)
    return {"activePrototypes": state.get("activePrototypes") or {}}


def cmd_delete(args: argparse.Namespace) -> JSON:
    return mutate_state(args.state, args.timeout, lambda state: state, delete=True)


def cmd_claim(args: argparse.Namespace) -> JSON:
    token = args.lease_token or uuid.uuid4().hex

    def update(state: JSON) -> JSON:
        entry = get_entry(state, args.id)
        ensure_revision(entry, args.expected_revision)
        if live_lease(entry, args.owner):
            raise StateError("Prototype is owned by another live lease.")
        if entry.get("status") in {"building", "reviewing", "awaiting_verdict", "handoff"}:
            raise StateError(f"Prototype status does not allow builder launch: {entry.get('status')}")
        entry["owner"] = args.owner
        entry["leaseToken"] = token
        entry["leaseExpires"] = lease_until(args.lease_seconds, entry.get("builderHardDeadline"))
        entry["heartbeatAt"] = utc_now()
        entry["status"] = "building"
        entry["builderExecutionAttempt"] = int(entry.get("builderExecutionAttempt") or 0) + 1
        bump(entry)
        return state

    return get_entry(mutate_state(args.state, args.timeout, update), args.id)


def cmd_heartbeat(args: argparse.Namespace) -> JSON:
    def update(state: JSON) -> JSON:
        entry = get_entry(state, args.id)
        ensure_token(entry, args.lease_token)
        entry["heartbeatAt"] = utc_now()
        bump(entry)
        return state

    return get_entry(mutate_state(args.state, args.timeout, update), args.id)


def cmd_renew(args: argparse.Namespace) -> JSON:
    def update(state: JSON) -> JSON:
        entry = get_entry(state, args.id)
        ensure_token(entry, args.lease_token)
        entry["heartbeatAt"] = utc_now()
        entry["leaseExpires"] = lease_until(args.lease_seconds, entry.get("builderHardDeadline"))
        bump(entry)
        return state

    return get_entry(mutate_state(args.state, args.timeout, update), args.id)


def cmd_release(args: argparse.Namespace) -> JSON:
    def update(state: JSON) -> JSON:
        entry = get_entry(state, args.id)
        ensure_token(entry, args.lease_token)
        entry["owner"] = None
        entry["leaseToken"] = None
        entry["leaseExpires"] = None
        if args.status:
            entry["status"] = args.status
        bump(entry)
        return state

    return get_entry(mutate_state(args.state, args.timeout, update), args.id)


def cmd_transition(args: argparse.Namespace) -> JSON:
    patch: JSON = {}
    if args.patch_json:
        try:
            patch = json.loads(args.patch_json)
        except json.JSONDecodeError as exc:
            raise StateError(f"Invalid patch JSON: {exc.msg}") from exc
        if not isinstance(patch, dict):
            raise StateError("patch-json must be a JSON object.")

    def update(state: JSON) -> JSON:
        entry = get_entry(state, args.id)
        ensure_revision(entry, args.expected_revision)
        if args.from_status and entry.get("status") != args.from_status:
            raise StateError(f"status mismatch: expected {args.from_status}, found {entry.get('status')}")
        entry.update(patch)
        entry["status"] = args.to_status
        bump(entry)
        return state

    return get_entry(mutate_state(args.state, args.timeout, update), args.id)


def add_common(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--state", required=True, type=Path, help="Path to .ralph-state.json")
    parser.add_argument("--timeout", type=float, default=10.0, help="Lock acquisition timeout in seconds")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    merge = sub.add_parser("merge", help="Merge top-level fields")
    add_common(merge)
    merge.add_argument("--set", action="append", default=[], help="key=value assignment")
    merge.add_argument("--json", action="append", default=[], help="key=<json> assignment")
    merge.add_argument("--stdout", action="store_true", help="Print merged JSON without writing")
    merge.set_defaults(func=cmd_merge)

    upsert = sub.add_parser("upsert-prototype", help="Upsert an active prototype entry")
    add_common(upsert)
    upsert.add_argument("--id", required=True)
    upsert.add_argument("--entry-json", required=True)
    upsert.set_defaults(func=cmd_upsert)

    remove = sub.add_parser("remove-prototype", help="Remove an active prototype entry")
    add_common(remove)
    remove.add_argument("--id", required=True)
    remove.set_defaults(func=cmd_remove)

    list_parser = sub.add_parser("list", help="List active prototypes")
    add_common(list_parser)
    list_parser.set_defaults(func=cmd_list)

    delete = sub.add_parser("delete-state", help="Delete state if no active prototypes remain")
    add_common(delete)
    delete.set_defaults(func=cmd_delete)

    claim = sub.add_parser("claim-builder", help="Claim builder ownership with compare-and-set")
    add_common(claim)
    claim.add_argument("--id", required=True)
    claim.add_argument("--expected-revision", required=True, type=int)
    claim.add_argument("--owner", required=True)
    claim.add_argument("--lease-token")
    claim.add_argument("--lease-seconds", type=int, default=600)
    claim.set_defaults(func=cmd_claim)

    heartbeat = sub.add_parser("heartbeat", help="Record builder activity")
    add_common(heartbeat)
    heartbeat.add_argument("--id", required=True)
    heartbeat.add_argument("--lease-token")
    heartbeat.set_defaults(func=cmd_heartbeat)

    renew = sub.add_parser("renew-lease", help="Extend builder lease")
    add_common(renew)
    renew.add_argument("--id", required=True)
    renew.add_argument("--lease-token")
    renew.add_argument("--lease-seconds", type=int, default=600)
    renew.set_defaults(func=cmd_renew)

    release = sub.add_parser("release-lease", help="Release builder lease")
    add_common(release)
    release.add_argument("--id", required=True)
    release.add_argument("--lease-token")
    release.add_argument("--status")
    release.set_defaults(func=cmd_release)

    transition = sub.add_parser("transition", help="Move an entry between statuses with compare-and-set")
    add_common(transition)
    transition.add_argument("--id", required=True)
    transition.add_argument("--expected-revision", type=int)
    transition.add_argument("--from-status")
    transition.add_argument("--to-status", required=True)
    transition.add_argument("--patch-json")
    transition.set_defaults(func=cmd_transition)

    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    result = args.func(args)
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except StateError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(2)
