#!/usr/bin/env python3
"""Control bounded prototype-builder subprocesses through a small JSON CLI."""

from __future__ import annotations

import argparse
import json
import os
import re
import signal
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


JSON = dict[str, Any]
VALID_ID = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$")


class HarnessError(Exception):
    def __init__(self, outcome: str, message: str, *, exit_code: int = 2):
        super().__init__(message)
        self.outcome = outcome
        self.exit_code = exit_code


def utc_now(timestamp: float | None = None) -> str:
    value = time.time() if timestamp is None else timestamp
    return datetime.fromtimestamp(value, timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def validate_id(run_id: str) -> None:
    if not VALID_ID.fullmatch(run_id):
        raise HarnessError("invalid-id", f"Invalid harness id: {run_id}")


def registry_path(registry: Path, run_id: str) -> Path:
    validate_id(run_id)
    return registry / f"{run_id}.json"


def output_path(registry: Path, run_id: str) -> Path:
    validate_id(run_id)
    return registry / f"{run_id}.output"


def write_metadata(path: Path, metadata: JSON) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(f"{path.suffix}.tmp")
    encoded = json.dumps(metadata, indent=2, sort_keys=True) + "\n"
    with temporary.open("w", encoding="utf-8") as handle:
        handle.write(encoded)
        handle.flush()
        os.fsync(handle.fileno())
    os.replace(temporary, path)


def read_metadata(registry: Path, run_id: str) -> JSON:
    path = registry_path(registry, run_id)
    if not path.exists():
        raise HarnessError("not-found", f"Harness run not found: {run_id}", exit_code=0)
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise HarnessError("unavailable-control", f"Cannot read harness run: {run_id}") from exc
    if not isinstance(data, dict):
        raise HarnessError("unavailable-control", f"Invalid harness metadata: {run_id}")
    return data


def _windows_pid_running(pid: int) -> bool:
    import ctypes
    from ctypes import wintypes

    process_query_limited_information = 0x1000
    still_active = 259
    error_access_denied = 5
    kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
    open_process = kernel32.OpenProcess
    open_process.argtypes = (wintypes.DWORD, wintypes.BOOL, wintypes.DWORD)
    open_process.restype = wintypes.HANDLE
    get_exit_code = kernel32.GetExitCodeProcess
    get_exit_code.argtypes = (wintypes.HANDLE, ctypes.POINTER(wintypes.DWORD))
    get_exit_code.restype = wintypes.BOOL
    close_handle = kernel32.CloseHandle
    close_handle.argtypes = (wintypes.HANDLE,)
    close_handle.restype = wintypes.BOOL

    handle = open_process(process_query_limited_information, False, pid)
    if not handle:
        return ctypes.get_last_error() == error_access_denied
    exit_code = wintypes.DWORD()
    try:
        if not get_exit_code(handle, ctypes.byref(exit_code)):
            return True
        return exit_code.value == still_active
    finally:
        close_handle(handle)


def _terminate_windows_process(pid: int) -> None:
    import ctypes
    from ctypes import wintypes

    process_terminate = 0x0001
    error_invalid_parameter = 87
    kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
    open_process = kernel32.OpenProcess
    open_process.argtypes = (wintypes.DWORD, wintypes.BOOL, wintypes.DWORD)
    open_process.restype = wintypes.HANDLE
    terminate_process = kernel32.TerminateProcess
    terminate_process.argtypes = (wintypes.HANDLE, wintypes.UINT)
    terminate_process.restype = wintypes.BOOL
    close_handle = kernel32.CloseHandle
    close_handle.argtypes = (wintypes.HANDLE,)
    close_handle.restype = wintypes.BOOL

    handle = open_process(process_terminate, False, pid)
    if not handle:
        error = ctypes.get_last_error()
        if error == error_invalid_parameter:
            return
        raise ctypes.WinError(error)
    try:
        if not terminate_process(handle, 1):
            raise ctypes.WinError(ctypes.get_last_error())
    finally:
        close_handle(handle)


def pid_running(pid: int) -> bool:
    if pid <= 0:
        return False
    if os.name == "nt":
        return _windows_pid_running(pid)
    proc_stat = Path(f"/proc/{pid}/stat")
    try:
        if proc_stat.exists() and proc_stat.read_text(encoding="utf-8").split()[2] == "Z":
            return False
    except (OSError, IndexError):
        pass
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    except OSError:
        return False
    return True


def read_output(registry: Path, run_id: str) -> str:
    path = output_path(registry, run_id)
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return ""


def refresh(metadata: JSON, registry: Path) -> JSON:
    run_id = str(metadata["id"])
    if metadata.get("status") != "running":
        return metadata
    if pid_running(int(metadata.get("pid") or 0)):
        return metadata
    metadata["status"] = "completed"
    metadata["completedAt"] = utc_now()
    metadata["output"] = read_output(registry, run_id)
    write_metadata(registry_path(registry, run_id), metadata)
    return metadata


def launch(
    *,
    registry: Path,
    run_id: str,
    kind: str,
    command: list[str],
    name: str | None = None,
    agent_id: str | None = None,
    soft_timeout: float = 60.0,
    activity_extension: float = 30.0,
    hard_timeout: float = 120.0,
    request_attempt: int = 1,
    builder_execution_attempt: int = 1,
    max_builder_executions: int = 2,
    unavailable_control: bool = False,
) -> JSON:
    validate_id(run_id)
    if unavailable_control:
        raise HarnessError("unavailable-control", "Harness control is unavailable.", exit_code=0)
    if kind == "codex_agent":
        if not agent_id:
            raise HarnessError("invalid-id", "Codex prototype builders require agentId.")
    if not command or any(not isinstance(item, str) or not item for item in command):
        raise HarnessError("unavailable-control", "command-json must be a nonempty string array.")
    if min(soft_timeout, activity_extension, hard_timeout) <= 0 or hard_timeout < soft_timeout:
        raise HarnessError("unavailable-control", "Timeout values must be positive and hard timeout must cover soft timeout.")
    if (
        request_attempt < 1
        or builder_execution_attempt < 1
        or not 1 <= max_builder_executions <= 5
        or builder_execution_attempt > max_builder_executions
    ):
        raise HarnessError("unavailable-control", "Builder execution counts must stay between one and five.")
    path = registry_path(registry, run_id)
    if path.exists():
        raise HarnessError("invalid-id", f"Harness id already exists: {run_id}")
    registry.mkdir(parents=True, exist_ok=True)
    output = output_path(registry, run_id)
    started = time.time()
    try:
        with output.open("wb") as handle:
            process = subprocess.Popen(
                command,
                stdin=subprocess.DEVNULL,
                stdout=handle,
                stderr=subprocess.STDOUT,
                start_new_session=True,
            )
    except (OSError, ValueError) as exc:
        raise HarnessError("unavailable-control", f"Cannot launch harness command: {exc}", exit_code=0) from exc
    metadata: JSON = {
        "outcome": "launched",
        "kind": kind,
        "id": run_id,
        "name": name or run_id,
        "agentId": agent_id,
        "pid": process.pid,
        "status": "running",
        "startedAt": utc_now(started),
        "startedEpoch": started,
        "heartbeatAt": utc_now(started),
        "rollingDeadlineEpoch": started + soft_timeout,
        "hardDeadlineEpoch": started + hard_timeout,
        "softTimeoutSeconds": soft_timeout,
        "activityExtensionSeconds": activity_extension,
        "requestAttempt": request_attempt,
        "builderExecutionAttempt": builder_execution_attempt,
        "maxBuilderExecutions": max_builder_executions,
    }
    write_metadata(path, metadata)
    return metadata


def heartbeat(*, registry: Path, run_id: str) -> JSON:
    metadata = refresh(read_metadata(registry, run_id), registry)
    if metadata.get("status") != "running":
        return {**metadata, "outcome": "already-complete"}
    now = time.time()
    metadata["heartbeatAt"] = utc_now(now)
    metadata["rollingDeadlineEpoch"] = min(
        max(
            float(metadata["rollingDeadlineEpoch"]),
            now + float(metadata["activityExtensionSeconds"]),
        ),
        float(metadata["hardDeadlineEpoch"]),
    )
    metadata["outcome"] = "heartbeat"
    write_metadata(registry_path(registry, run_id), metadata)
    return metadata


def interrupt(*, registry: Path, run_id: str, outcome: str = "stopped") -> JSON:
    metadata = refresh(read_metadata(registry, run_id), registry)
    if metadata.get("status") != "running":
        return {**metadata, "outcome": "already-complete"}
    pid = int(metadata.get("pid") or 0)
    if os.name == "nt":
        try:
            _terminate_windows_process(pid)
        except (ProcessLookupError, PermissionError, OSError):
            pass
    else:
        try:
            os.killpg(pid, signal.SIGTERM)
        except (ProcessLookupError, PermissionError, OSError):
            try:
                os.kill(pid, signal.SIGTERM)
            except (ProcessLookupError, PermissionError, OSError):
                pass
    metadata["status"] = "timed_out" if outcome == "timeout" else "stopped"
    metadata["outcome"] = outcome
    if outcome == "timeout":
        metadata["hard"] = True
    metadata["completedAt"] = utc_now()
    metadata["output"] = read_output(registry, run_id)
    write_metadata(registry_path(registry, run_id), metadata)
    return metadata


def status(*, registry: Path, run_id: str) -> JSON:
    metadata = refresh(read_metadata(registry, run_id), registry)
    return {**metadata, "outcome": str(metadata.get("status"))}


def wait(
    *, registry: Path, run_id: str, until_seconds: float = 10.0, poll_seconds: float = 0.05
) -> JSON:
    stop_at = time.monotonic() + max(0.0, until_seconds)
    while True:
        metadata = refresh(read_metadata(registry, run_id), registry)
        if metadata.get("status") != "running":
            return {**metadata, "outcome": "completed", "output": read_output(registry, run_id)}
        now = time.time()
        if now >= float(metadata["hardDeadlineEpoch"]):
            return interrupt(registry=registry, run_id=run_id, outcome="timeout")
        output = output_path(registry, run_id)
        if output.exists() and output.stat().st_mtime > float(metadata["startedEpoch"]):
            last_activity = float(metadata.get("lastOutputMtime") or 0)
            current_activity = output.stat().st_mtime
            if current_activity > last_activity:
                metadata["lastOutputMtime"] = current_activity
                metadata["heartbeatAt"] = utc_now(current_activity)
                metadata["rollingDeadlineEpoch"] = min(
                    max(
                        float(metadata["rollingDeadlineEpoch"]),
                        now + float(metadata["activityExtensionSeconds"]),
                    ),
                    float(metadata["hardDeadlineEpoch"]),
                )
                write_metadata(registry_path(registry, run_id), metadata)
        if now >= float(metadata["rollingDeadlineEpoch"]) or time.monotonic() >= stop_at:
            return {**metadata, "outcome": "timeout", "hard": False, "output": read_output(registry, run_id)}
        time.sleep(max(0.01, poll_seconds))


def parse_command(raw: str) -> list[str]:
    try:
        value = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise HarnessError("unavailable-control", f"Invalid command JSON: {exc.msg}") from exc
    if not isinstance(value, list):
        raise HarnessError("unavailable-control", "command-json must be an array.")
    return value


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    launch_parser = sub.add_parser("launch", help="Launch a bounded builder command")
    launch_parser.add_argument("--registry", type=Path, required=True)
    launch_parser.add_argument("--id", required=True)
    launch_parser.add_argument("--kind", choices=("claude_background", "codex_agent"), required=True)
    launch_parser.add_argument("--command-json", required=True)
    launch_parser.add_argument("--name")
    launch_parser.add_argument("--agent-id")
    launch_parser.add_argument("--soft-timeout", type=float, default=60.0)
    launch_parser.add_argument("--activity-extension", type=float, default=30.0)
    launch_parser.add_argument("--hard-timeout", type=float, default=120.0)
    launch_parser.add_argument("--request-attempt", type=int, default=1)
    launch_parser.add_argument("--builder-execution-attempt", type=int, default=1)
    launch_parser.add_argument("--max-builder-executions", type=int, default=2)
    launch_parser.add_argument("--unavailable-control", action="store_true")

    for name in ("wait", "heartbeat", "interrupt", "status"):
        child = sub.add_parser(name)
        child.add_argument("--registry", type=Path, required=True)
        child.add_argument("--id", required=True)
        if name == "wait":
            child.add_argument("--until-seconds", type=float, default=10.0)
            child.add_argument("--poll-seconds", type=float, default=0.05)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        if args.command == "launch":
            result = launch(
                registry=args.registry,
                run_id=args.id,
                kind=args.kind,
                command=parse_command(args.command_json),
                name=args.name,
                agent_id=args.agent_id,
                soft_timeout=args.soft_timeout,
                activity_extension=args.activity_extension,
                hard_timeout=args.hard_timeout,
                request_attempt=args.request_attempt,
                builder_execution_attempt=args.builder_execution_attempt,
                max_builder_executions=args.max_builder_executions,
                unavailable_control=args.unavailable_control,
            )
        elif args.command == "wait":
            result = wait(
                registry=args.registry,
                run_id=args.id,
                until_seconds=args.until_seconds,
                poll_seconds=args.poll_seconds,
            )
        elif args.command == "heartbeat":
            result = heartbeat(registry=args.registry, run_id=args.id)
        elif args.command == "interrupt":
            result = interrupt(registry=args.registry, run_id=args.id)
        else:
            result = status(registry=args.registry, run_id=args.id)
    except HarnessError as exc:
        print(json.dumps({"outcome": exc.outcome, "message": str(exc)}, sort_keys=True))
        return exc.exit_code
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
