#!/usr/bin/env python3
"""Create, review, publish, reconcile, and select prototype records."""

from __future__ import annotations

import argparse
import importlib.util
import hashlib
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from types import ModuleType
from typing import Any

sys.dont_write_bytecode = True


def _load_locked_state() -> ModuleType:
    helper = Path(__file__).resolve().with_name("locked-state.py")
    spec = importlib.util.spec_from_file_location("ralph_specum_claude_locked_state", helper)
    if spec is None or spec.loader is None:
        raise ImportError(f"Cannot load locked state helper: {helper}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_locked_state = _load_locked_state()
active_map = _locked_state.active_map
fsync_dir = _locked_state.fsync_dir
mutate_state = _locked_state.mutate_state
read_json_object = _locked_state.read_json_object
StateError = _locked_state.StateError


JSON = dict[str, Any]
VERDICTS = {"validated", "rejected", "inconclusive", "cancelled", "failed", "skipped"}
SOURCE_DISPOSITIONS = {"retained", "deleted", "not_created"}
REQUIRED_FIELDS = {
    "spec",
    "phase",
    "id",
    "status",
    "verdict",
    "kind",
    "captureMode",
    "triggerMode",
    "triggerPhase",
    "returnPhase",
    "decisionOwner",
    "resolutionMode",
    "gateApproved",
    "created",
    "completed",
    "sourceDisposition",
    "staleArtifacts",
    "staleTaskIndexes",
}
REQUIRED_HEADINGS = (
    "Question",
    "Blocking Declaration",
    "Isolation",
    "Run Instructions",
    "Cases Or Variants",
    "Evidence And Observations",
    "Verdict",
    "Downstream Handoff",
    "Conflict Resolution",
    "Staleness",
    "Source Disposition",
)
FRONTMATTER_ORDER = (
    "spec",
    "phase",
    "id",
    "status",
    "verdict",
    "kind",
    "captureMode",
    "triggerMode",
    "triggerPhase",
    "returnPhase",
    "returnTaskIndex",
    "decisionOwner",
    "resolutionMode",
    "gateApproved",
    "created",
    "completed",
    "sourceDisposition",
    "evidenceHash",
    "cleanupReceiptHash",
    "staleArtifacts",
    "staleTaskIndexes",
    "supersedes",
    "conflictsWith",
    "resolves",
    "resolvedAt",
)


class RecordError(SystemExit):
    """Report an invalid or unsafe prototype record operation."""

    pass


def utc_now() -> str:
    """Return the current UTC time in record format."""

    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def sha256_bytes(data: bytes) -> str:
    """Return the SHA-256 digest of exact bytes."""

    return hashlib.sha256(data).hexdigest()


def sha256_path(path: Path) -> str:
    """Return the SHA-256 digest of a file's exact bytes."""

    return sha256_bytes(path.read_bytes())


def safe_id(value: object) -> str:
    """Validate and return a path-safe prototype identifier."""

    if not isinstance(value, str) or not re.fullmatch(r"[a-z0-9][a-z0-9-]{0,79}", value):
        raise RecordError("Prototype id must contain lowercase ASCII letters, digits, and hyphens.")
    return value


def prototype_dir(base_path: Path) -> Path:
    """Return the prototype record directory, creating it when absent."""

    path = base_path.resolve() / "prototypes"
    path.mkdir(parents=True, exist_ok=True)
    return path


def candidate_path(base_path: Path, prototype_id: str) -> Path:
    """Return the private candidate path for a prototype."""

    return prototype_dir(base_path) / f".{safe_id(prototype_id)}.candidate.md"


def final_path(base_path: Path, prototype_id: str) -> Path:
    """Return the published record path for a prototype."""

    return prototype_dir(base_path) / f"{safe_id(prototype_id)}.md"


def parse_scalar(raw: str) -> Any:
    """Parse one restricted frontmatter scalar."""

    value = raw.strip()
    if not value:
        return ""
    try:
        return json.loads(value)
    except json.JSONDecodeError:
        if (value.startswith("'") and value.endswith("'")) or (
            value.startswith('"') and value.endswith('"')
        ):
            return value[1:-1]
        return value


def split_record(text: str) -> tuple[JSON, str]:
    """Split record frontmatter from its Markdown body."""

    match = re.match(r"^---\r?\n(.*?)\r?\n---\r?\n(.*)$", text, re.DOTALL)
    if not match:
        raise RecordError("Prototype record needs YAML frontmatter.")
    frontmatter: JSON = {}
    for line in match.group(1).splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if ":" not in line:
            raise RecordError(f"Malformed frontmatter line: {line}")
        key, raw = line.split(":", 1)
        frontmatter[key.strip()] = parse_scalar(raw)
    return frontmatter, match.group(2)


def body_sections(body: str) -> JSON:
    """Parse second-level Markdown sections from a record body."""

    sections: JSON = {}
    matches = list(re.finditer(r"(?m)^## ([^\r\n]+)\r?$", body))
    for index, match in enumerate(matches):
        end = matches[index + 1].start() if index + 1 < len(matches) else len(body)
        sections[match.group(1).strip()] = body[match.end() : end].strip()
    return sections


def validate_record_text(text: str, expected_id: str | None = None) -> JSON:
    """Validate a terminal record and return its structured content."""

    frontmatter, body = split_record(text)
    missing = sorted(REQUIRED_FIELDS - set(frontmatter))
    if missing:
        raise RecordError(f"Missing prototype fields: {', '.join(missing)}")
    prototype_id = safe_id(frontmatter.get("id"))
    if expected_id is not None and prototype_id != expected_id:
        raise RecordError(f"Record id {prototype_id} does not match path id {expected_id}.")
    if frontmatter.get("phase") != "prototype" or frontmatter.get("status") != "terminal":
        raise RecordError("Terminal records require phase prototype and status terminal.")
    if frontmatter.get("verdict") not in VERDICTS:
        raise RecordError("Prototype verdict is not terminal.")
    if frontmatter.get("kind") not in {"logic", "ui"}:
        raise RecordError("Prototype kind must be logic or ui.")
    if frontmatter.get("captureMode") not in {"retained", "ephemeral"}:
        raise RecordError("Prototype captureMode must be retained or ephemeral.")
    if frontmatter.get("triggerMode") not in {"suggested", "explicit", "quick"}:
        raise RecordError("Prototype triggerMode is invalid.")
    if frontmatter.get("sourceDisposition") not in SOURCE_DISPOSITIONS:
        raise RecordError("Prototype sourceDisposition is invalid.")
    if frontmatter.get("verdict") == "skipped" and frontmatter.get("sourceDisposition") != "not_created":
        raise RecordError("Skipped prototypes require sourceDisposition not_created.")
    if frontmatter.get("sourceDisposition") == "not_created":
        for key in ("sourcePointers", "isolationPath", "isolationBranch"):
            if frontmatter.get(key) is not None:
                raise RecordError(f"No-source prototypes require {key}=null when present.")
    if not isinstance(frontmatter.get("gateApproved"), bool):
        raise RecordError("Prototype gateApproved must be a boolean.")
    stale_artifacts = frontmatter.get("staleArtifacts", [])
    if not isinstance(stale_artifacts, list) or any(not isinstance(item, str) for item in stale_artifacts):
        raise RecordError("Prototype staleArtifacts must be an array of strings.")
    stale_task_indexes = frontmatter.get("staleTaskIndexes", [])
    if not isinstance(stale_task_indexes, list) or any(
        not isinstance(item, int) or isinstance(item, bool) or item < 0 for item in stale_task_indexes
    ):
        raise RecordError("Prototype staleTaskIndexes must be an array of non-negative integers.")
    sections = body_sections(body)
    missing_headings = [heading for heading in REQUIRED_HEADINGS if heading not in sections]
    if missing_headings:
        raise RecordError(f"Missing prototype headings: {', '.join(missing_headings)}")
    if not sections["Question"].strip():
        raise RecordError("Prototype question cannot be empty.")
    return {"frontmatter": frontmatter, "sections": sections}


def yaml_scalar(value: Any) -> str:
    """Render a value as a deterministic frontmatter scalar."""

    if value is None or isinstance(value, (bool, int, float, list, dict)):
        return json.dumps(value, separators=(",", ":"))
    return json.dumps(str(value), ensure_ascii=True)


def render_record(record: JSON) -> str:
    """Render and validate a prototype record as Markdown."""

    markdown = record.get("markdown")
    if isinstance(markdown, str):
        validate_record_text(markdown)
        return markdown if markdown.endswith("\n") else markdown + "\n"
    frontmatter = record.get("frontmatter")
    if not isinstance(frontmatter, dict):
        frontmatter = {key: value for key, value in record.items() if key not in {"sections", "markdown"}}
    sections = record.get("sections")
    if not isinstance(sections, dict):
        raise RecordError("record-json requires a sections object or markdown string.")
    keys = [key for key in FRONTMATTER_ORDER if key in frontmatter]
    keys.extend(sorted(set(frontmatter) - set(keys)))
    lines = ["---", *(f"{key}: {yaml_scalar(frontmatter[key])}" for key in keys), "---", ""]
    for heading in REQUIRED_HEADINGS:
        lines.extend((f"## {heading}", "", str(sections.get(heading, "none")).strip() or "none", ""))
    text = "\n".join(lines).rstrip() + "\n"
    validate_record_text(text)
    return text


def write_exclusive(path: Path, data: bytes) -> None:
    """Durably create a file without overwriting an existing path."""

    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o644)
    except FileExistsError as exc:
        raise RecordError(f"Refusing to overwrite existing path: {path}") from exc
    try:
        with os.fdopen(fd, "wb") as handle:
            handle.write(data)
            handle.flush()
            os.fsync(handle.fileno())
    except Exception:
        path.unlink(missing_ok=True)
        raise
    fsync_dir(path.parent)


def load_json_argument(raw: str) -> JSON:
    """Load a JSON object from inline text or an @path argument."""

    if raw.startswith("@"):
        raw = Path(raw[1:]).read_text(encoding="utf-8")
    try:
        value = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise RecordError(f"Invalid record JSON: {exc.msg}") from exc
    if not isinstance(value, dict):
        raise RecordError("JSON argument must contain an object.")
    return value


def remove_active(
    state_path: Path,
    prototype_id: str,
    timeout: float,
    expected_entry: JSON | None,
    artifact_hash: str,
) -> bool:
    """Remove an active entry matching the snapshot and recovered artifact."""

    if not state_path.exists():
        return False

    removed = False

    def update(state: JSON) -> JSON:
        nonlocal removed
        active = active_map(state)
        current = active.get(prototype_id)
        if (
            expected_entry is None
            or current != expected_entry
            or current.get("reviewedCandidateHash") != artifact_hash
        ):
            return state
        removed = True
        active.pop(prototype_id, None)
        if not active:
            state.pop("activePrototypes", None)
        return state

    mutate_state(state_path, timeout, update)
    return removed


def publish_exact(data: bytes, final: Path) -> None:
    """Publish exact prevalidated bytes without overwriting a record."""

    if final.exists():
        raise RecordError(f"Prototype id collision: {final.name}")
    try:
        write_exclusive(final, data)
    except RecordError as exc:
        raise RecordError(f"Prototype id collision: {final.name}") from exc


def quarantine_candidate(path: Path) -> Path:
    """Move a conflicting candidate to a unique quarantine path."""

    stamp = datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S")
    for suffix in range(1, 1000):
        marker = "" if suffix == 1 else f"-{suffix}"
        target = path.with_name(f"{path.stem}.{stamp}{marker}.quarantine.md")
        if not target.exists():
            path.rename(target)
            fsync_dir(path.parent)
            return target
    raise RecordError(f"Could not allocate quarantine path for {path.name}")


def receipt_path(base_path: Path, prototype_id: str) -> Path:
    """Return the private cleanup receipt path for a prototype."""

    return prototype_dir(base_path) / f".{safe_id(prototype_id)}.cleanup.json"


def validate_cleanup_receipt(record: JSON, receipt: Path) -> JSON:
    """Validate cleanup proof against a terminal record."""

    data = read_json_object(receipt)
    for key in ("candidateHash", "evidenceHash", "isolationPath", "provenance", "reviewedAt"):
        if not data.get(key):
            raise RecordError(f"Cleanup receipt is missing {key}.")
    receipt_hash = sha256_path(receipt)
    frontmatter = record["frontmatter"]
    if frontmatter.get("sourceDisposition") != "deleted":
        raise RecordError("Cleanup receipt review requires sourceDisposition deleted.")
    if frontmatter.get("cleanupReceiptHash") != receipt_hash:
        raise RecordError("Cleanup receipt hash does not match the reviewed record.")
    if frontmatter.get("evidenceHash") != data.get("evidenceHash"):
        raise RecordError("Cleanup receipt evidence hash changed after deletion.")
    source = Path(str(data["isolationPath"])).expanduser().resolve()
    if source.exists():
        raise RecordError(f"Cleanup source still exists: {source}")
    return data


def cmd_render_candidate(args: argparse.Namespace) -> JSON:
    """Render and exclusively reserve candidate record bytes."""

    record = load_json_argument(args.record_json)
    text = render_record(record)
    parsed = validate_record_text(text)
    prototype_id = safe_id(parsed["frontmatter"]["id"])
    path = candidate_path(args.base_path, prototype_id)
    write_exclusive(path, text.encode("utf-8"))
    return {"id": prototype_id, "candidate": str(path), "candidateHash": sha256_path(path)}


def cmd_parse(args: argparse.Namespace) -> JSON:
    """Parse and validate an existing prototype record."""

    parsed = validate_record_text(args.record.read_text(encoding="utf-8"), args.id)
    return {**parsed, "recordHash": sha256_path(args.record)}


def cmd_cleanup_receipt(args: argparse.Namespace) -> JSON:
    """Create a durable cleanup receipt for ephemeral source."""

    data = load_json_argument(args.receipt_json)
    for key in ("candidateHash", "evidenceHash", "isolationPath", "provenance"):
        if not data.get(key):
            raise RecordError(f"Cleanup receipt is missing {key}.")
    data.setdefault("reviewedAt", utc_now())
    path = receipt_path(args.base_path, args.id)
    encoded = (json.dumps(data, indent=2, sort_keys=True) + "\n").encode("utf-8")
    write_exclusive(path, encoded)
    return {"receipt": str(path), "receiptHash": sha256_bytes(encoded)}


def cmd_review_candidate(args: argparse.Namespace) -> JSON:
    """Record REVIEW_PASS for exact candidate and evidence bytes."""

    path = candidate_path(args.base_path, args.id)
    actual_hash = sha256_path(path)
    if actual_hash != args.candidate_hash:
        raise RecordError("Candidate bytes changed after review began.")
    record = validate_record_text(path.read_text(encoding="utf-8"), args.id)
    receipt = None
    if args.cleanup_receipt:
        receipt = validate_cleanup_receipt(record, args.cleanup_receipt)
    state_path = args.state or args.base_path.resolve() / ".ralph-state.json"

    def update(state: JSON) -> JSON:
        active = active_map(state)
        entry = active.get(args.id)
        if not isinstance(entry, dict):
            raise RecordError(f"No active prototype entry for {args.id}.")
        entry["candidateHash"] = actual_hash
        entry["reviewedCandidateHash"] = actual_hash
        entry["reviewedEvidenceHash"] = args.evidence_hash or (receipt or {}).get("evidenceHash")
        entry["status"] = "reviewed"
        entry["stateRevision"] = int(entry.get("stateRevision") or 0) + 1
        return state

    mutate_state(state_path, args.timeout, update)
    return {"id": args.id, "reviewPass": True, "reviewedCandidateHash": actual_hash}


def cmd_publish(args: argparse.Namespace) -> JSON:
    """Publish reviewed candidate bytes and remove matching active state."""

    candidate = candidate_path(args.base_path, args.id)
    if not candidate.exists():
        raise RecordError(f"Candidate does not exist: {candidate}")
    candidate_bytes = candidate.read_bytes()
    candidate_hash = sha256_bytes(candidate_bytes)
    record = validate_record_text(candidate_bytes.decode("utf-8"), args.id)
    if args.publisher_only_lock_timeout:
        if not args.candidate_hash or args.candidate_hash != candidate_hash:
            raise RecordError("Publisher-only candidate hash does not match the exact candidate bytes.")
        frontmatter = record["frontmatter"]
        expected = {
            "triggerMode": "quick",
            "verdict": "failed",
            "resolutionMode": "lock_timeout",
            "gateApproved": False,
            "sourceDisposition": "not_created",
        }
        for key, value in expected.items():
            if frontmatter.get(key) != value:
                raise RecordError(f"Publisher-only lock timeout requires {key}={yaml_scalar(value)}.")
        for key in ("evidenceHash", "cleanupReceiptHash"):
            if key not in frontmatter or frontmatter[key] is not None:
                raise RecordError(f"Publisher-only lock timeout requires {key}=null.")
        for key in ("sourcePointers", "isolationPath", "isolationBranch"):
            if frontmatter.get(key) is not None:
                raise RecordError(f"Publisher-only lock timeout requires {key}=null when present.")
        final = final_path(args.base_path, args.id)
        publish_exact(candidate_bytes, final)
        final_bytes = final.read_bytes()
        if sha256_bytes(final_bytes) != candidate_hash or final_bytes != candidate_bytes:
            raise RecordError("Published bytes do not match the lock-timeout candidate.")
        validate_record_text(final_bytes.decode("utf-8"), args.id)
        candidate.unlink()
        fsync_dir(candidate.parent)
        return {
            "id": args.id,
            "final": str(final),
            "recordHash": candidate_hash,
            "activeRemoved": False,
            "publisherOnly": True,
        }
    state_path = args.state or args.base_path.resolve() / ".ralph-state.json"
    state = read_json_object(state_path)
    entry = active_map(state).get(args.id)
    if not isinstance(entry, dict) or entry.get("reviewedCandidateHash") != candidate_hash:
        raise RecordError("Publisher requires REVIEW_PASS for these exact candidate bytes.")
    reviewed_revision = entry.get("stateRevision")
    if not isinstance(reviewed_revision, int) or isinstance(reviewed_revision, bool):
        raise RecordError("Publisher requires a reviewed state revision.")
    expected_entry = entry.copy()
    final = final_path(args.base_path, args.id)
    removed = False

    def publish_and_remove(current_state: JSON) -> JSON:
        nonlocal removed
        active = active_map(current_state)
        current = active.get(args.id)
        if (
            current != expected_entry
            or current.get("stateRevision") != reviewed_revision
            or current.get("reviewedCandidateHash") != candidate_hash
        ):
            raise RecordError("Active prototype changed after REVIEW_PASS; refusing publication.")
        publish_exact(candidate_bytes, final)
        final_bytes = final.read_bytes()
        if sha256_bytes(final_bytes) != candidate_hash or final_bytes != candidate_bytes:
            raise RecordError("Published bytes do not match the reviewed candidate.")
        validate_record_text(final_bytes.decode("utf-8"), args.id)
        candidate.unlink()
        fsync_dir(candidate.parent)
        active.pop(args.id)
        if not active:
            current_state.pop("activePrototypes", None)
        removed = True
        return current_state

    mutate_state(state_path, args.timeout, publish_and_remove)
    return {"id": args.id, "final": str(final), "recordHash": candidate_hash, "activeRemoved": removed}


def cmd_reconcile(args: argparse.Namespace) -> JSON:
    """Reconcile candidate, final, and active prototype state."""

    directory = prototype_dir(args.base_path)
    state = read_json_object(args.state)
    active = active_map(state)
    actions: list[JSON] = []
    handled: set[str] = set()
    for candidate in sorted(directory.glob(".*.candidate.md")):
        prototype_id = candidate.name[1 : -len(".candidate.md")]
        safe_id(prototype_id)
        handled.add(prototype_id)
        final = final_path(args.base_path, prototype_id)
        if not final.exists():
            actions.append({"id": prototype_id, "action": "resume_review", "candidateHash": sha256_path(candidate)})
            continue
        try:
            validate_record_text(final.read_text(encoding="utf-8"), prototype_id)
        except RecordError as exc:
            actions.append({"id": prototype_id, "action": "quarantine_final", "reason": str(exc)})
            continue
        candidate_hash = sha256_path(candidate)
        final_hash = sha256_path(final)
        if candidate_hash == final_hash:
            candidate.unlink()
            fsync_dir(directory)
            removed = remove_active(
                args.state, prototype_id, args.timeout, active.get(prototype_id), final_hash
            )
            actions.append({"id": prototype_id, "action": "complete_matching_publish", "activeRemoved": removed})
        else:
            quarantine = quarantine_candidate(candidate)
            actions.append({"id": prototype_id, "action": "quarantine_candidate", "path": str(quarantine)})
    for final in sorted(directory.glob("*.md")):
        if final.name.startswith(".") or ".quarantine." in final.name:
            continue
        prototype_id = final.stem
        if prototype_id in handled:
            continue
        handled.add(prototype_id)
        try:
            validate_record_text(final.read_text(encoding="utf-8"), prototype_id)
        except RecordError as exc:
            actions.append({"id": prototype_id, "action": "quarantine_final", "reason": str(exc)})
            continue
        if prototype_id in active:
            removed = remove_active(
                args.state, prototype_id, args.timeout, active[prototype_id], sha256_path(final)
            )
            actions.append({"id": prototype_id, "action": "remove_verified_active", "activeRemoved": removed})
        else:
            actions.append({"id": prototype_id, "action": "complete"})
    for prototype_id, entry in sorted(active.items()):
        if prototype_id not in handled:
            actions.append({"id": prototype_id, "action": "resume_active", "status": entry.get("status")})
    return {"actions": actions}


def cmd_select_downstream(args: argparse.Namespace) -> JSON:
    """Select approved evidence and compute downstream gates."""

    directory = prototype_dir(args.base_path)
    parsed: list[JSON] = []
    quarantined: list[JSON] = []
    for path in sorted(directory.glob("*.md")):
        if path.name.startswith(".") or ".quarantine." in path.name:
            continue
        try:
            record = validate_record_text(path.read_text(encoding="utf-8"), path.stem)
        except RecordError as exc:
            quarantined.append({"path": str(path), "reason": str(exc)})
            continue
        parsed.append({"id": path.stem, "path": str(path), **record})
    superseded = {
        item
        for record in parsed
        for item in (record["frontmatter"].get("supersedes") or [])
        if isinstance(item, str)
    }
    selected = []
    stale_artifacts: set[str] = set()
    stale_tasks: set[int] = set()
    for record in parsed:
        frontmatter = record["frontmatter"]
        if record["id"] in superseded:
            continue
        if frontmatter.get("gateApproved") is not True or frontmatter.get("verdict") not in {"validated", "rejected"}:
            continue
        record_stale_artifacts = frontmatter.get("staleArtifacts") or []
        record_stale_tasks = frontmatter.get("staleTaskIndexes") or []
        stale_artifacts.update(record_stale_artifacts)
        stale_tasks.update(record_stale_tasks)
        selected.append(
            {
                "id": record["id"],
                "path": record["path"],
                "verdict": frontmatter["verdict"],
                "triggerMode": frontmatter["triggerMode"],
                "returnPhase": frontmatter["returnPhase"],
                "returnTaskIndex": frontmatter.get("returnTaskIndex"),
                "staleArtifacts": record_stale_artifacts,
                "staleTaskIndexes": record_stale_tasks,
                "recordHash": sha256_path(Path(record["path"])),
            }
        )
    state = read_json_object(args.state) if args.state and args.state.exists() else {}
    active = active_map(state)
    blockers: list[JSON] = []
    active_entries: list[JSON] = []
    for prototype_id, entry in sorted(active.items()):
        if not isinstance(entry, dict):
            continue
        blocking = entry.get("blocking") or {}
        blocked = (blocking.get("blocks") or []) if isinstance(blocking, dict) else []
        isolation = entry.get("isolation") or {}
        approved_transfers = isolation.get("approvedTransfers") if isinstance(isolation, dict) else None
        proof_available = (
            isinstance(blocking, dict)
            and isinstance(blocking.get("blocks"), list)
            and all(isinstance(item, str) for item in blocking["blocks"])
            and isinstance(isolation, dict)
            and isinstance(approved_transfers, list)
            and all(isinstance(item, str) for item in approved_transfers)
        )
        active_entries.append(
            {
                "id": prototype_id,
                "blocked": blocked,
                "approvedTransfers": approved_transfers if isinstance(approved_transfers, list) else [],
                "proofAvailable": proof_available,
            }
        )
        if blocked:
            blockers.append(
                {
                    "id": prototype_id,
                    "status": entry.get("status"),
                    "blocked": blocked,
                    "returnPhase": entry.get("returnPhase"),
                    "returnTaskIndex": entry.get("returnTaskIndex"),
                    "approvedTransfers": approved_transfers if isinstance(approved_transfers, list) else [],
                    "proofAvailable": proof_available,
                }
            )
        checkpoint = entry.get("decisionCheckpoint") or {}
        if isinstance(checkpoint, dict):
            stale_artifacts.update(item for item in (checkpoint.get("staleArtifacts") or []) if isinstance(item, str))
            stale_tasks.update(item for item in (checkpoint.get("staleTaskIndexes") or []) if isinstance(item, int))
    def paths_overlap(left: str, right: str) -> bool:
        left_path = left.replace("\\", "/").removeprefix("./").strip("/")
        right_path = right.replace("\\", "/").removeprefix("./").strip("/")
        return bool(left_path and right_path) and (
            left_path == right_path
            or left_path.startswith(f"{right_path}/")
            or right_path.startswith(f"{left_path}/")
            or left_path.endswith(f"/{right_path}")
            or right_path.endswith(f"/{left_path}")
        )

    target_paths = [item for item in (args.paths or []) if isinstance(item, str) and item]
    target_decisions: list[JSON] = []
    for target in args.targets or []:
        blocked_by: list[str] = []
        transfer_overlaps: list[JSON] = []
        proof_unavailable: list[str] = []
        for entry in active_entries:
            if not entry["proofAvailable"]:
                proof_unavailable.append(entry["id"])
                continue
            if target in entry["blocked"] or any(paths_overlap(target, item) for item in entry["blocked"]):
                blocked_by.append(entry["id"])
            transfers = entry["approvedTransfers"]
            if transfers and not target_paths:
                proof_unavailable.append(entry["id"])
                continue
            for transfer in transfers:
                if any(paths_overlap(transfer, path) for path in target_paths):
                    transfer_overlaps.append({"id": entry["id"], "path": transfer})
        stale_by = [
            record["id"]
            for record in selected
            if target in record["staleArtifacts"]
            or any(paths_overlap(item, target) for item in record["staleArtifacts"])
            or any(paths_overlap(item, path) for item in record["staleArtifacts"] for path in target_paths)
            or (
                target.startswith("task:")
                and target[5:].isdigit()
                and int(target[5:]) in record["staleTaskIndexes"]
            )
        ]
        proof_available = not proof_unavailable
        target_decisions.append(
            {
                "target": target,
                "proofAvailable": proof_available,
                "proofUnavailableFor": sorted(set(proof_unavailable)),
                "blockedBy": sorted(set(blocked_by)),
                "staleBy": sorted(set(stale_by)),
                "transferOverlaps": transfer_overlaps,
                "eligible": proof_available and not blocked_by and not stale_by and not transfer_overlaps,
            }
        )
    return {
        "selected": selected,
        "superseded": sorted(superseded),
        "quarantined": quarantined,
        "activeBlockers": blockers,
        "staleArtifacts": sorted(stale_artifacts),
        "staleTaskIndexes": sorted(stale_tasks),
        "targetDecisions": target_decisions,
    }


def add_base(parser: argparse.ArgumentParser) -> None:
    """Add the common prototype base-path argument."""

    parser.add_argument("--base-path", required=True, type=Path)


def build_parser() -> argparse.ArgumentParser:
    """Build the prototype record command parser."""

    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    render = sub.add_parser("render-candidate", help="Render and exclusively reserve candidate bytes")
    add_base(render)
    render.add_argument("--record-json", required=True, help="JSON object or @path")
    render.set_defaults(func=cmd_render_candidate)

    parse = sub.add_parser("parse", help="Parse and validate a prototype record")
    parse.add_argument("--record", required=True, type=Path)
    parse.add_argument("--id")
    parse.set_defaults(func=cmd_parse)

    receipt = sub.add_parser("cleanup-receipt", help="Write a durable quick cleanup receipt")
    add_base(receipt)
    receipt.add_argument("--id", required=True)
    receipt.add_argument("--receipt-json", required=True, help="JSON object or @path")
    receipt.set_defaults(func=cmd_cleanup_receipt)

    review = sub.add_parser("review-candidate", help="Gate exact candidate bytes after REVIEW_PASS")
    add_base(review)
    review.add_argument("--id", required=True)
    review.add_argument("--candidate-hash", required=True)
    review.add_argument("--evidence-hash")
    review.add_argument("--cleanup-receipt", type=Path)
    review.add_argument("--state", type=Path)
    review.add_argument("--timeout", type=float, default=10.0)
    review.set_defaults(func=cmd_review_candidate)

    publish = sub.add_parser("publish", help="Publish reviewed bytes without overwrite")
    add_base(publish)
    publish.add_argument("--id", required=True)
    publish.add_argument("--state", type=Path)
    publish.add_argument("--timeout", type=float, default=10.0)
    publish.add_argument("--publisher-only-lock-timeout", action="store_true")
    publish.add_argument("--candidate-hash")
    publish.set_defaults(func=cmd_publish)

    reconcile = sub.add_parser("reconcile", help="Reconcile candidates, finals, and active state")
    add_base(reconcile)
    reconcile.add_argument("--state", required=True, type=Path)
    reconcile.add_argument("--timeout", type=float, default=10.0)
    reconcile.set_defaults(func=cmd_reconcile)

    select = sub.add_parser("select-downstream", help="Select approved non-superseded evidence")
    add_base(select)
    select.add_argument("--state", type=Path)
    select.add_argument("--target", dest="targets", action="append", default=[])
    select.add_argument("--path", dest="paths", action="append", default=[])
    select.set_defaults(func=cmd_select_downstream)
    return parser


def main(argv: list[str] | None = None) -> int:
    """Run a prototype record command and print its JSON result."""

    args = build_parser().parse_args(argv)
    try:
        result = args.func(args)
    except (RecordError, StateError) as exc:
        print(str(exc), file=sys.stderr)
        return 2
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        print(str(exc), file=sys.stderr)
        return 2
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
