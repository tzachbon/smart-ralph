#!/usr/bin/env python3
"""Persist and validate deterministic phase gates for Ralph Specum."""

from __future__ import annotations

import argparse
import fcntl
import hashlib
import json
import os
import re
import sys
import tempfile
from pathlib import Path
from contextlib import contextmanager
from typing import Any, NoReturn


SKILL_STATUSES = {"complete", "partial_warned", "core_failed"}
INTERVIEW_STATUSES = {
    "collecting",
    "awaiting_confirmation",
    "complete",
    "skipped",
    "bypassed_quick",
}
LOAD_STATUSES = {"loaded", "failed"}
TERMINAL_INTERVIEW_STATUSES = {"complete", "skipped", "bypassed_quick"}
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
CONTROL_PHRASES = {
    "",
    "approved",
    "apply the changes",
    "confirm",
    "confirmed",
    "continue",
    "continue please",
    "go ahead",
    "looks good",
    "next",
    "ok",
    "okay",
    "please continue",
    "proceed",
    "sounds good",
    "y",
    "yes",
}
CANONICAL_CONFIRMATION = "approve-and-delegate"
PHASES = {"start", "triage", "research", "requirements", "design", "tasks"}
CONTEXT_MARKER = b"ralph-phase-context-v1"
PACKAGED_CORES = {
    "ralph-specum": "interview-framework",
    "ralph-specum-codex": "interview-framework-codex",
}
PACKAGED_CORE_RESOURCES = {
    "ralph-specum": ("algorithm.md", "domain-modeling.md"),
    "ralph-specum-codex": ("algorithm.md", "domain-modeling.md"),
}
REQUIRED_PHASE_ARTIFACTS = {
    "design": ("requirements.md",),
    "tasks": ("requirements.md", "design.md"),
}
OPTIONAL_PHASE_ARTIFACTS = {
    "requirements": ("research.md",),
    "design": ("research.md",),
    "tasks": ("research.md",),
}


class PhaseGateError(Exception):
    def __init__(self, code: str, message: str, exit_code: int = 2) -> None:
        super().__init__(message)
        self.code = code
        self.exit_code = exit_code


def fail(code: str, message: str, exit_code: int = 2) -> NoReturn:
    raise PhaseGateError(code, message, exit_code)


def require_object(value: Any, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        fail("INVALID_OBJECT", f"{label} must be a JSON object")
    return value


def require_fields(value: dict[str, Any], fields: list[str], label: str) -> None:
    missing = [field for field in fields if field not in value]
    if missing:
        fail("MISSING_FIELDS", f"{label} is missing: {', '.join(missing)}")


def require_string(value: Any, label: str, nullable: bool = False) -> str | None:
    if nullable and value is None:
        return None
    if not isinstance(value, str) or not value.strip():
        fail("INVALID_STRING", f"{label} must be a non-empty string")
    return value


def require_string_array(value: Any, label: str) -> list[str]:
    if not isinstance(value, list) or any(
        not isinstance(item, str) or not item.strip() for item in value
    ):
        fail("INVALID_ARRAY", f"{label} must be an array of non-empty strings")
    if len(value) != len(set(value)):
        fail("DUPLICATE_VALUES", f"{label} must not contain duplicate values")
    return value


def require_sha256(value: Any, label: str) -> str:
    if not isinstance(value, str) or not SHA256_RE.fullmatch(value):
        fail("INVALID_HASH", f"{label} must be a lowercase SHA-256 digest")
    return value


def require_absolute_source(value: Any, label: str) -> str:
    source = require_string(value, label)
    assert source is not None
    if not Path(source).is_absolute():
        fail("RELATIVE_SOURCE", f"{label} must be an absolute path")
    return source


def verify_file_hash(source: str, expected: str, label: str) -> None:
    actual = hashlib.sha256(read_file_bytes(source, label)).hexdigest()
    if actual != expected:
        fail("HASH_MISMATCH", f"{label} hash does not match current source bytes")


def read_file_bytes(source: str, label: str) -> bytes:
    try:
        return Path(source).read_bytes()
    except OSError as error:
        fail("SOURCE_UNREADABLE", f"{label} source cannot be read: {error}")


def frame(value: bytes) -> bytes:
    return str(len(value)).encode("ascii") + b":" + value


def validate_context(value: dict[str, Any], verify_files: bool) -> None:
    context = require_object(value["context"], "phaseSkillLoad.context")
    require_fields(context, ["goal", "artifacts"], "phaseSkillLoad.context")
    goal = require_string(context["goal"], "phaseSkillLoad.context.goal")
    assert goal is not None
    artifacts = context["artifacts"]
    if not isinstance(artifacts, list):
        fail("INVALID_ARRAY", "phaseSkillLoad.context.artifacts must be an array")

    sources: list[str] = []
    artifact_rows: list[tuple[str, str]] = []
    for index, artifact in enumerate(artifacts):
        label = f"phaseSkillLoad.context.artifacts[{index}]"
        item = require_object(artifact, label)
        require_fields(item, ["source", "sha256"], label)
        source = require_absolute_source(item["source"], f"{label}.source")
        digest = require_sha256(item["sha256"], f"{label}.sha256")
        sources.append(source)
        artifact_rows.append((source, digest))
    if len(sources) != len(set(sources)):
        fail("DUPLICATE_CONTEXT_SOURCE", "phaseSkillLoad.context.artifacts sources must be unique")

    if not verify_files:
        return
    digest_input = [
        frame(CONTEXT_MARKER),
        frame(value["phase"].encode("utf-8")),
        frame(goal.encode("utf-8")),
    ]
    for source, expected_hash in sorted(artifact_rows):
        artifact_bytes = read_file_bytes(source, "phaseSkillLoad.context artifact")
        if hashlib.sha256(artifact_bytes).hexdigest() != expected_hash:
            fail("HASH_MISMATCH", "phaseSkillLoad.context artifact hash does not match current source bytes")
        digest_input.extend([frame(source.encode("utf-8")), frame(artifact_bytes)])
    actual_digest = hashlib.sha256(b"".join(digest_input)).hexdigest()
    if actual_digest != value["contextDigest"]:
        fail("CONTEXT_DIGEST_MISMATCH", "phaseSkillLoad.contextDigest does not match current context inputs")


def validate_state_context(
    state: dict[str, Any], skill_load: dict[str, Any], state_path: Path
) -> None:
    if "goal" in state:
        state_goal = require_string(state["goal"], "state.goal")
        if state_goal != skill_load["context"]["goal"]:
            fail("CONTEXT_GOAL_MISMATCH", "phaseSkillLoad.context.goal does not match state.goal")

    phase = skill_load["phase"]
    state_directory = state_path.resolve().parent
    required_names = REQUIRED_PHASE_ARTIFACTS.get(phase, ())
    missing_files = [name for name in required_names if not (state_directory / name).is_file()]
    if missing_files:
        fail(
            "CONTEXT_ARTIFACT_REQUIRED",
            f"phase {phase} requires current context artifact(s): {', '.join(missing_files)}",
        )

    applicable_names = list(required_names)
    applicable_names.extend(
        name
        for name in OPTIONAL_PHASE_ARTIFACTS.get(phase, ())
        if (state_directory / name).is_file()
    )
    expected_sources = {(state_directory / name).resolve() for name in applicable_names}
    actual_sources = {
        Path(item["source"]).resolve() for item in skill_load["context"]["artifacts"]
    }
    missing_sources = sorted(str(source) for source in expected_sources - actual_sources)
    unexpected_sources = sorted(str(source) for source in actual_sources - expected_sources)
    if missing_sources:
        fail(
            "CONTEXT_ARTIFACT_MISSING",
            f"phaseSkillLoad.context omits applicable artifact(s): {', '.join(missing_sources)}",
        )
    if unexpected_sources:
        fail(
            "CONTEXT_ARTIFACT_UNEXPECTED",
            f"phaseSkillLoad.context includes non-applicable artifact(s): {', '.join(unexpected_sources)}",
        )


def normalize_discovery_pass(value: Any) -> int | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, int):
        return value if value in {1, 2} else None
    if not isinstance(value, str):
        return None
    match = re.fullmatch(r"(?:pass[-_ ]*)?([12])", value.strip().lower())
    return int(match.group(1)) if match else None


def validate_discovery_linkage(
    state: dict[str, Any], skill_load: dict[str, Any], state_path: Path
) -> None:
    history = state.get("discoveredSkills")
    if not isinstance(history, list) or not history:
        fail("DISCOVERY_HISTORY_MISSING", "state.discoveredSkills has no catalog discovery record")

    revision = str(skill_load["discoveryRevision"])
    revision_entries = []
    for entry in history:
        if not isinstance(entry, dict):
            continue
        entry_revision = entry.get("revision", entry.get("discoveryRevision"))
        if entry_revision is not None and str(entry_revision) == revision:
            revision_entries.append(entry)
    if not revision_entries:
        fail("DISCOVERY_REVISION_MISSING", f"no discovery record matches revision {revision}")

    research_exists = (state_path.resolve().parent / "research.md").is_file()
    expected_pass = 2 if skill_load["phase"] in {"requirements", "design", "tasks"} and research_exists else 1
    pass_entries = [
        entry for entry in revision_entries if normalize_discovery_pass(entry.get("pass")) == expected_pass
    ]
    if not pass_entries:
        fail(
            "DISCOVERY_PASS_MISSING",
            f"revision {revision} does not contain applicable pass{expected_pass} discovery",
        )

    discovered_pairs: list[tuple[str, str]] = []
    for index, entry in enumerate(pass_entries):
        label = f"state.discoveredSkills[{index}]"
        require_fields(
            entry,
            ["pass", "revision", "name", "activeSource", "reason", "shadowedSources", "outcome"],
            label,
        )
        require_string(entry["name"], f"{label}.name")
        require_string(entry["reason"], f"{label}.reason")
        active_source = require_absolute_source(entry["activeSource"], f"{label}.activeSource")
        shadowed = require_string_array(entry["shadowedSources"], f"{label}.shadowedSources")
        for shadow_index, source in enumerate(shadowed):
            require_absolute_source(source, f"{label}.shadowedSources[{shadow_index}]")
        outcome = require_string(entry["outcome"], f"{label}.outcome")
        if outcome not in {"selected", "not-selected", "unreadable", "missing-description"}:
            fail("DISCOVERY_OUTCOME_INVALID", f"{label}.outcome is not a supported catalog decision")
        if outcome == "selected":
            discovered_pairs.append((entry["name"], str(Path(active_source).resolve())))

    if len(discovered_pairs) != len(set(discovered_pairs)):
        fail("DUPLICATE_DISCOVERY_SELECTION", "applicable discovery contains duplicate selected skills")
    manifest_pairs = {
        (item["name"], str(Path(item["source"]).resolve())) for item in skill_load["selected"]
    }
    if set(discovered_pairs) != manifest_pairs:
        fail(
            "DISCOVERY_SELECTION_MISMATCH",
            "phaseSkillLoad.selected must exactly match selected skills in the applicable discovery revision",
        )


def packaged_core_contract() -> tuple[str, Path, tuple[Path, ...]]:
    """Return `(core name, source, resources)`.

    Unknown roots require exactly one known packaged core.
    """
    plugin_root = Path(__file__).resolve().parent.parent
    package_key = plugin_root.name
    if package_key not in PACKAGED_CORES:
        matching_package_keys = [
            candidate_key
            for candidate_key, candidate_skill_name in PACKAGED_CORES.items()
            if (plugin_root / "skills" / candidate_skill_name / "SKILL.md").is_file()
        ]
        if len(matching_package_keys) != 1:
            fail("UNRECOGNIZED_PLUGIN_ROOT", "phase gate helper is outside a recognized packaged plugin root")
        package_key = matching_package_keys[0]
    skill_name = PACKAGED_CORES[package_key]
    skill_source = plugin_root / "skills" / skill_name / "SKILL.md"
    resource_names = PACKAGED_CORE_RESOURCES[package_key]
    resource_sources = tuple(
        (plugin_root / "skills" / skill_name / "references" / resource_name).resolve()
        for resource_name in resource_names
    )
    return skill_name, skill_source.resolve(), resource_sources


def validate_load_receipt(receipt: Any, label: str, has_source: bool) -> dict[str, Any]:
    value = require_object(receipt, label)
    fields = ["sha256", "loadStatus", "errors"]
    if has_source:
        fields.insert(0, "source")
    require_fields(value, fields, label)
    if has_source:
        require_absolute_source(value["source"], f"{label}.source")
    if value["loadStatus"] not in LOAD_STATUSES:
        fail("INVALID_LOAD_STATUS", f"{label}.loadStatus must be loaded or failed")
    if value["loadStatus"] == "loaded":
        require_sha256(value["sha256"], f"{label}.sha256")
    elif value["sha256"] is not None:
        fail("INCONSISTENT_LOAD", f"{label}.sha256 must be null when failed")
    require_string_array(value["errors"], f"{label}.errors")
    if value["loadStatus"] == "loaded" and value["errors"]:
        fail("INCONSISTENT_LOAD", f"{label} cannot have errors when loaded")
    if value["loadStatus"] == "failed" and not value["errors"]:
        fail("INCONSISTENT_LOAD", f"{label} must record errors when failed")
    return value


def validate_skill_load(
    payload: Any,
    verify_files: bool = False,
    allow_agent_loads: bool = True,
) -> dict[str, Any]:
    value = require_object(payload, "phaseSkillLoad")
    required = [
        "phase",
        "interviewId",
        "discoveryRevision",
        "contextDigest",
        "context",
        "status",
        "selected",
        "warnings",
        "conflicts",
        "failures",
        "noDomainMatches",
        "artifactAgentLoads",
    ]
    require_fields(value, required, "phaseSkillLoad")
    require_string(value["phase"], "phaseSkillLoad.phase")
    if value["phase"] not in PHASES:
        fail("INVALID_PHASE", "phaseSkillLoad.phase is outside the gated phases")
    require_string(value["interviewId"], "phaseSkillLoad.interviewId")
    revision = value["discoveryRevision"]
    invalid_revision = (
        isinstance(revision, bool)
        or not isinstance(revision, (str, int))
        or (isinstance(revision, str) and not revision.strip())
        or (isinstance(revision, int) and revision < 0)
    )
    if invalid_revision:
        fail("INVALID_REVISION", "phaseSkillLoad.discoveryRevision must be a non-empty string or non-negative integer")
    require_sha256(value["contextDigest"], "phaseSkillLoad.contextDigest")
    validate_context(value, verify_files)
    if value["status"] not in SKILL_STATUSES:
        fail("INVALID_SKILL_STATUS", "phaseSkillLoad.status is invalid")
    if not isinstance(value["selected"], list):
        fail("INVALID_ARRAY", "phaseSkillLoad.selected must be an array")
    require_string_array(value["warnings"], "phaseSkillLoad.warnings")
    require_string_array(value["conflicts"], "phaseSkillLoad.conflicts")
    require_string_array(value["failures"], "phaseSkillLoad.failures")
    if not isinstance(value["noDomainMatches"], bool):
        fail("INVALID_BOOLEAN", "phaseSkillLoad.noDomainMatches must be a boolean")
    if not isinstance(value["artifactAgentLoads"], list):
        fail("INVALID_ARRAY", "phaseSkillLoad.artifactAgentLoads must be an array")

    core_errors: list[str] = []
    domain_errors: list[str] = []
    core_count = 0
    selected_names: list[str] = []
    selected_sources: list[str] = []
    for index, selected in enumerate(value["selected"]):
        label = f"phaseSkillLoad.selected[{index}]"
        item = require_object(selected, label)
        require_fields(
            item,
            [
                "name",
                "reason",
                "source",
                "core",
                "body",
                "requiredResourceSources",
                "requiredResources",
            ],
            label,
        )
        require_string(item["name"], f"{label}.name")
        selected_names.append(item["name"])
        require_string(item["reason"], f"{label}.reason")
        require_absolute_source(item["source"], f"{label}.source")
        selected_sources.append(item["source"])
        if not isinstance(item["core"], bool):
            fail("INVALID_BOOLEAN", f"{label}.core must be a boolean")
        if item["core"]:
            core_count += 1
        body = validate_load_receipt(item["body"], f"{label}.body", False)
        if verify_files and body["loadStatus"] == "loaded":
            verify_file_hash(item["source"], body["sha256"], f"{label}.body")
        inventory = require_string_array(
            item["requiredResourceSources"], f"{label}.requiredResourceSources"
        )
        for source_index, source in enumerate(inventory):
            require_absolute_source(source, f"{label}.requiredResourceSources[{source_index}]")
        if not isinstance(item["requiredResources"], list):
            fail("INVALID_ARRAY", f"{label}.requiredResources must be an array")
        if body["loadStatus"] == "failed":
            (core_errors if item["core"] else domain_errors).extend(body["errors"])
        for resource_index, resource in enumerate(item["requiredResources"]):
            resource_label = f"{label}.requiredResources[{resource_index}]"
            receipt = validate_load_receipt(resource, resource_label, True)
            if verify_files and receipt["loadStatus"] == "loaded":
                verify_file_hash(receipt["source"], receipt["sha256"], resource_label)
            if receipt["loadStatus"] == "failed":
                (core_errors if item["core"] else domain_errors).extend(receipt["errors"])
        receipt_sources = [resource["source"] for resource in item["requiredResources"]]
        if inventory != receipt_sources:
            fail(
                "RESOURCE_INVENTORY_MISMATCH",
                f"{label}.requiredResources must exactly match requiredResourceSources",
            )

    for index, receipt in enumerate(value["artifactAgentLoads"]):
        label = f"phaseSkillLoad.artifactAgentLoads[{index}]"
        item = require_object(receipt, label)
        require_fields(item, ["agent", "source", "sha256", "loadStatus", "errors"], label)
        require_string(item["agent"], f"{label}.agent")
        validated = validate_load_receipt(item, label, True)
        if verify_files and validated["loadStatus"] == "loaded":
            verify_file_hash(validated["source"], validated["sha256"], label)

    identities = [
        (item["agent"], item["source"])
        for item in value["artifactAgentLoads"]
    ]
    if len(identities) != len(set(identities)):
        fail("DUPLICATE_AGENT_LOAD", "artifactAgentLoads must be unique by agent and source")
    if not allow_agent_loads and value["artifactAgentLoads"]:
        fail("PREFILLED_AGENT_LOADS", "record-skill-load requires empty artifactAgentLoads")

    if core_count != 1:
        fail("CORE_SKILL_COUNT", "phaseSkillLoad.selected must include exactly one core interview contract")
    expected_name, expected_source, expected_resources = packaged_core_contract()
    core_item = next(item for item in value["selected"] if item["core"])
    if core_item["name"] != expected_name or Path(core_item["source"]).resolve() != expected_source:
        fail("CORE_SKILL_SOURCE", "core selection must be the packaged interview framework")
    loaded_core_resources = [Path(resource["source"]).resolve() for resource in core_item["requiredResources"]]
    missing_core_resources = [source for source in expected_resources if loaded_core_resources.count(source) != 1]
    if missing_core_resources:
        names = ", ".join(f"references/{source.name}" for source in missing_core_resources)
        fail("CORE_RESOURCE_MISSING", f"core selection must include its packaged {names}")
    if len(selected_names) != len(set(selected_names)) or len(selected_sources) != len(set(selected_sources)):
        fail("DUPLICATE_SELECTION", "selected skill names and sources must be unique")
    has_domain_matches = any(not item["core"] for item in value["selected"])
    if value["noDomainMatches"] == has_domain_matches:
        fail("DOMAIN_MATCH_MISMATCH", "noDomainMatches must equal whether domain selections are absent")
    recorded_warnings = value["warnings"]
    recorded_failures = value["failures"]
    all_errors = core_errors + domain_errors
    if recorded_failures != all_errors:
        fail("INCONSISTENT_SKILL_FAILURES", "phaseSkillLoad.failures must match all failed receipt errors")
    if value["status"] == "complete":
        if all_errors or recorded_warnings:
            fail("INCONSISTENT_SKILL_STATUS", "complete requires every selected load to succeed without warnings")
    if value["status"] == "partial_warned":
        if core_errors:
            fail("INCONSISTENT_SKILL_STATUS", "partial_warned requires the core contract to load")
        if not domain_errors or recorded_warnings != domain_errors:
            fail("INCONSISTENT_SKILL_STATUS", "partial_warned warnings must match domain load errors")
    if value["status"] == "core_failed":
        if not core_errors or recorded_warnings != domain_errors:
            fail("INCONSISTENT_SKILL_STATUS", "core_failed warnings must match domain load errors")
    return value


def quick_is_authorized(state: dict[str, Any]) -> bool:
    authorization = state.get("quickAuthorization")
    return (
        state.get("quickMode") is True
        and isinstance(authorization, dict)
        and authorization.get("source") == "--quick"
    )


def validate_interview(payload: Any, state: dict[str, Any]) -> dict[str, Any]:
    value = require_object(payload, "phaseInterview")
    required = [
        "phase",
        "interviewId",
        "round",
        "status",
        "askedDecisionIds",
        "pendingDecisionIds",
        "answeredDecisionIds",
        "selectedApproach",
        "confirmationSource",
        "bypassReason",
        "assumptionsRecorded",
    ]
    require_fields(value, required, "phaseInterview")
    require_string(value["phase"], "phaseInterview.phase")
    if value["phase"] not in PHASES:
        fail("INVALID_PHASE", "phaseInterview.phase is outside the gated phases")
    require_string(value["interviewId"], "phaseInterview.interviewId")
    if isinstance(value["round"], bool) or not isinstance(value["round"], int) or value["round"] < 1:
        fail("INVALID_ROUND", "phaseInterview.round must be a positive integer")
    if value["status"] not in INTERVIEW_STATUSES:
        fail("INVALID_INTERVIEW_STATUS", "phaseInterview.status is invalid")

    asked = require_string_array(value["askedDecisionIds"], "phaseInterview.askedDecisionIds")
    pending = require_string_array(value["pendingDecisionIds"], "phaseInterview.pendingDecisionIds")
    answered = require_string_array(value["answeredDecisionIds"], "phaseInterview.answeredDecisionIds")
    require_string_array(value["assumptionsRecorded"], "phaseInterview.assumptionsRecorded")
    if not set(pending).issubset(asked) or not set(answered).issubset(asked):
        fail("INVALID_DECISION_SET", "pending and answered decision IDs must have been asked")
    if set(pending) & set(answered):
        fail("INVALID_DECISION_SET", "a decision ID cannot be pending and answered")
    if set(asked) != set(pending) | set(answered):
        fail("INVALID_DECISION_SET", "asked decision IDs must partition into pending and answered")

    selected = require_string(value["selectedApproach"], "phaseInterview.selectedApproach", nullable=True)
    confirmation = require_string(
        value["confirmationSource"], "phaseInterview.confirmationSource", nullable=True
    )
    if confirmation is not None and confirmation != CANONICAL_CONFIRMATION:
        fail("INVALID_CONFIRMATION_SOURCE", f"confirmationSource must be {CANONICAL_CONFIRMATION}")
    bypass = require_string(value["bypassReason"], "phaseInterview.bypassReason", nullable=True)
    status = value["status"]
    if status == "complete":
        if pending or selected is None or confirmation != CANONICAL_CONFIRMATION or bypass is not None:
            fail("INTERVIEW_NOT_COMPLETE", "complete requires an approach, canonical confirmation, and no bypass")
    elif status == "skipped":
        if (
            pending
            or selected is None
            or confirmation != CANONICAL_CONFIRMATION
            or bypass is None
            or not value["assumptionsRecorded"]
        ):
            fail("INTERVIEW_NOT_SKIPPED", "skipped requires an approach, canonical confirmation, and skip reason")
    elif status == "bypassed_quick":
        if pending or selected is not None or confirmation is not None or bypass != "Explicit --quick authorization":
            fail("INTERVIEW_NOT_BYPASSED", "bypassed_quick fields do not match exact quick authorization")
        if not quick_is_authorized(state):
            fail("QUICK_NOT_AUTHORIZED", "bypassed_quick requires authorization from exact --quick input")
    elif status == "awaiting_confirmation":
        if len(pending) != 1 or selected is None or confirmation is not None:
            fail("CONFIRMATION_NOT_PENDING", "awaiting_confirmation requires one pending confirmation and an approach")
    elif status == "collecting" and (confirmation is not None or bypass is not None or selected is not None):
        fail("INTERVIEW_NOT_COLLECTING", "collecting cannot contain confirmation, bypass, or selected approach")
    return value


def manifest_fingerprint(skill_load: dict[str, Any]) -> str:
    stable = {key: value for key, value in skill_load.items() if key != "artifactAgentLoads"}
    encoded = json.dumps(stable, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def read_json(path_or_dash: str, label: str) -> dict[str, Any]:
    try:
        if path_or_dash == "-":
            value = json.load(sys.stdin)
        else:
            with Path(path_or_dash).open(encoding="utf-8") as handle:
                value = json.load(handle)
    except (OSError, json.JSONDecodeError) as error:
        fail("INVALID_JSON", f"Could not read {label}: {error}")
    return require_object(value, label)


def read_state(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return read_json(str(path), "state")


def write_state(path: Path, state: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    mode = path.stat().st_mode & 0o777 if path.exists() else 0o600
    temp_path: str | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            dir=path.parent,
            prefix=".phase-gate-",
            delete=False,
        ) as handle:
            temp_path = handle.name
            json.dump(state, handle, indent=2, sort_keys=True)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.chmod(temp_path, mode)
        os.replace(temp_path, path)
        temp_path = None
        directory_fd = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory_fd)
        finally:
            os.close(directory_fd)
    except OSError as error:
        fail("STATE_WRITE_FAILED", f"Could not write state: {error}")
    finally:
        if temp_path is not None:
            try:
                os.unlink(temp_path)
            except FileNotFoundError:
                pass


@contextmanager
def state_lock(path: Path):
    key = hashlib.sha256(str(path.resolve()).encode("utf-8")).hexdigest()
    lock_path = Path(tempfile.gettempdir()) / f"ralph-phase-gate-{key}.lock"
    descriptor = os.open(lock_path, os.O_CREAT | os.O_RDWR, 0o600)
    try:
        fcntl.flock(descriptor, fcntl.LOCK_EX)
        yield
    finally:
        fcntl.flock(descriptor, fcntl.LOCK_UN)
        os.close(descriptor)


def command_mode(args: argparse.Namespace) -> dict[str, Any]:
    path = Path(args.state)
    if not path.exists():
        if args.quick or args.interactive:
            fail("STATE_NOT_FOUND", f"state file does not exist: {path}")
        return {"ok": True, "quickMode": False, "interviewReset": False, "stateExists": False}
    state = read_state(path)
    if args.quick:
        state["quickMode"] = True
        state["quickAuthorization"] = {"source": "--quick"}
    elif args.interactive:
        state["quickMode"] = False
        state.pop("quickAuthorization", None)
    elif not quick_is_authorized(state):
        state["quickMode"] = False
        state.pop("quickAuthorization", None)
    interview = state.get("phaseInterview")
    interview_reset = False
    if isinstance(interview, dict):
        quick_mode = quick_is_authorized(state)
        incompatible = (
            quick_mode and interview.get("status") != "bypassed_quick"
        ) or (
            not quick_mode and interview.get("status") == "bypassed_quick"
        )
        if incompatible:
            state.pop("phaseInterview", None)
            interview_reset = True
    write_state(path, state)
    return {
        "ok": True,
        "quickMode": state.get("quickMode") is True,
        "interviewReset": interview_reset,
        "stateExists": True,
    }


def command_record_skill_load(args: argparse.Namespace) -> dict[str, Any]:
    path = Path(args.state)
    state = read_state(path)
    new_skill_load = validate_skill_load(
        read_json(args.input, "skill load input"), verify_files=True, allow_agent_loads=False
    )
    old_skill_load = state.get("phaseSkillLoad")
    if "goal" not in state and isinstance(old_skill_load, dict):
        old_context = require_object(
            old_skill_load.get("context"), "existing phaseSkillLoad.context"
        )
        require_fields(old_context, ["goal"], "existing phaseSkillLoad.context")
        old_goal = require_string(
            old_context["goal"], "existing phaseSkillLoad.context.goal"
        )
        if old_goal != new_skill_load["context"]["goal"]:
            fail(
                "CONTEXT_GOAL_MISMATCH",
                "phaseSkillLoad.context.goal does not match the persisted legacy context goal",
            )
    validate_state_context(state, new_skill_load, path)
    validate_discovery_linkage(state, new_skill_load, path)
    if isinstance(old_skill_load, dict) and manifest_fingerprint(old_skill_load) != manifest_fingerprint(new_skill_load):
        state.pop("phaseInterview", None)
    state["phaseSkillLoad"] = new_skill_load
    write_state(path, state)
    return {"ok": True, "recorded": "phaseSkillLoad"}


def current_interview(state: dict[str, Any]) -> dict[str, Any]:
    interview = state.get("phaseInterview")
    if not isinstance(interview, dict):
        reject("INTERVIEW_MISSING", "phaseInterview is missing")
    return validate_interview(interview, state)


def current_skill_load(
    state: dict[str, Any],
    state_path: Path,
    phase: str,
    interview_id: str,
    context_digest: str,
    discovery_revision: str | None = None,
) -> dict[str, Any]:
    skill_load = state.get("phaseSkillLoad")
    if not isinstance(skill_load, dict):
        reject("SKILL_LOAD_MISSING", "phaseSkillLoad is missing")
    try:
        validate_skill_load(skill_load, verify_files=True)
        validate_state_context(state, skill_load, state_path)
        validate_discovery_linkage(state, skill_load, state_path)
    except PhaseGateError as error:
        reject("SKILL_LOAD_STALE", f"phaseSkillLoad is invalid: {error.code}")
    current = (
        skill_load.get("phase") == phase
        and skill_load.get("interviewId") == interview_id
        and skill_load.get("contextDigest") == context_digest
    )
    if discovery_revision is not None:
        current = current and str(skill_load.get("discoveryRevision")) == discovery_revision
    if not current:
        reject("SKILL_LOAD_STALE", "phaseSkillLoad does not match current phase provenance")
    if skill_load.get("status") == "core_failed":
        reject("SKILL_LOAD_FAILED", "phaseSkillLoad reports a core load failure")
    if skill_load.get("status") not in {"complete", "partial_warned"}:
        reject("SKILL_LOAD_INCOMPLETE", "phaseSkillLoad is not complete")
    return skill_load


def new_interview(phase: str, interview_id: str, round_number: int, status: str) -> dict[str, Any]:
    return {
        "phase": phase,
        "interviewId": interview_id,
        "round": round_number,
        "status": status,
        "askedDecisionIds": [],
        "pendingDecisionIds": [],
        "answeredDecisionIds": [],
        "selectedApproach": None,
        "confirmationSource": None,
        "bypassReason": "Explicit --quick authorization" if status == "bypassed_quick" else None,
        "assumptionsRecorded": [],
    }


def command_begin_interview(args: argparse.Namespace) -> dict[str, Any]:
    path = Path(args.state)
    state = read_state(path)
    current_skill_load(
        state,
        path,
        args.phase,
        args.interview_id,
        args.context_digest,
        args.discovery_revision,
    )
    existing = state.get("phaseInterview")
    if isinstance(existing, dict):
        validate_interview(existing, state)
        same_interview = (
            existing.get("phase") == args.phase
            and existing.get("interviewId") == args.interview_id
        )
        if same_interview and existing.get("status") in {"collecting", "awaiting_confirmation"}:
            if existing.get("round") != args.round:
                reject("ROUND_MISMATCH", "begin-interview round does not match the active interview")
            return {"ok": True, "status": existing["status"], "resumed": True}
        if same_interview:
            reject("INTERVIEW_TERMINAL", "begin-interview cannot reopen a terminal interview")
        if existing.get("status") not in TERMINAL_INTERVIEW_STATUSES:
            reject("INTERVIEW_STALE", "begin-interview cannot replace a different active interview")
    if quick_is_authorized(state):
        interview = new_interview(args.phase, args.interview_id, args.round, "bypassed_quick")
    else:
        interview = new_interview(args.phase, args.interview_id, args.round, "collecting")
    state["phaseInterview"] = validate_interview(interview, state)
    write_state(path, state)
    return {"ok": True, "status": interview["status"]}


def normalize_answer(text: str) -> str:
    normalized = re.sub(r"[^a-z0-9]+", " ", text.lower()).strip()
    return re.sub(r"\s+", " ", normalized)


def classify_reply(text: str) -> str:
    normalized = normalize_answer(text)
    words = normalized.split()
    while words and words[0] == "please":
        words.pop(0)
    while words and words[-1] in {"please", "thanks"}:
        words.pop()
    if len(words) >= 2 and words[-2:] == ["thank", "you"]:
        words = words[:-2]
    normalized = " ".join(words)
    if normalized == "skip":
        return "bare_skip"
    if normalized in CONTROL_PHRASES:
        return "control_only"
    return "substantive"


def is_substantive(text: str) -> bool:
    return classify_reply(text) == "substantive"


def command_record_answer(args: argparse.Namespace) -> dict[str, Any]:
    path = Path(args.state)
    state = read_state(path)
    interview = current_interview(state)
    if interview["status"] != "collecting":
        reject("ILLEGAL_INTERVIEW_TRANSITION", "record-answer requires collecting status")
    if not is_substantive(args.answer):
        reject("CONTROL_ONLY_ANSWER", "record-answer requires a substantive decision answer")
    if args.decision_id not in interview["pendingDecisionIds"]:
        reject("DECISION_NOT_PENDING", "record-answer requires a pending decision ID")
    interview["pendingDecisionIds"].remove(args.decision_id)
    interview["answeredDecisionIds"].append(args.decision_id)
    if args.assumption and args.assumption not in interview["assumptionsRecorded"]:
        interview["assumptionsRecorded"].append(args.assumption)
    validate_interview(interview, state)
    write_state(path, state)
    return {"ok": True, "status": "collecting"}


def command_open_frontier(args: argparse.Namespace) -> dict[str, Any]:
    path = Path(args.state)
    state = read_state(path)
    interview = current_interview(state)
    if interview["status"] != "collecting":
        reject("ILLEGAL_INTERVIEW_TRANSITION", "open-frontier requires collecting status")
    current_round = interview["round"]
    if args.round < current_round or args.round > current_round + 1:
        reject("INVALID_ROUND_TRANSITION", "open-frontier round must stay current or advance by one")
    if args.round == current_round + 1:
        if interview["pendingDecisionIds"]:
            reject("DECISIONS_PENDING", "open-frontier cannot advance with pending decisions")
        interview["round"] = args.round
    for decision_id in args.decision_id:
        if decision_id in interview["answeredDecisionIds"]:
            reject("DECISION_ALREADY_RECORDED", f"decision ID {decision_id!r} was already answered")
        if decision_id not in interview["askedDecisionIds"]:
            interview["askedDecisionIds"].append(decision_id)
        if decision_id not in interview["pendingDecisionIds"]:
            interview["pendingDecisionIds"].append(decision_id)
    validate_interview(interview, state)
    write_state(path, state)
    return {"ok": True, "pendingDecisionIds": interview["pendingDecisionIds"]}


def command_await_confirmation(args: argparse.Namespace) -> dict[str, Any]:
    path = Path(args.state)
    state = read_state(path)
    interview = current_interview(state)
    if interview["status"] != "collecting":
        reject("ILLEGAL_INTERVIEW_TRANSITION", "await-confirmation requires collecting status")
    if interview["pendingDecisionIds"]:
        reject("DECISIONS_PENDING", "await-confirmation requires all open decisions to be answered")
    if args.decision_id in interview["askedDecisionIds"]:
        reject("DECISION_ALREADY_RECORDED", "confirmation decision ID was already recorded")
    interview["askedDecisionIds"].append(args.decision_id)
    interview["pendingDecisionIds"].append(args.decision_id)
    interview["selectedApproach"] = args.approach
    interview["status"] = "awaiting_confirmation"
    validate_interview(interview, state)
    write_state(path, state)
    return {"ok": True, "status": "awaiting_confirmation"}


def command_confirm(args: argparse.Namespace) -> dict[str, Any]:
    path = Path(args.state)
    state = read_state(path)
    interview = current_interview(state)
    if interview["status"] != "awaiting_confirmation":
        reject("ILLEGAL_INTERVIEW_TRANSITION", "confirm requires awaiting_confirmation status")
    if args.source != CANONICAL_CONFIRMATION:
        reject("INVALID_CONFIRMATION_SOURCE", f"confirm source must be {CANONICAL_CONFIRMATION}")
    if args.decision_id not in interview["pendingDecisionIds"]:
        reject("CONFIRMATION_ID_MISMATCH", "confirmation decision ID is not pending")
    interview["pendingDecisionIds"].remove(args.decision_id)
    interview["answeredDecisionIds"].append(args.decision_id)
    interview["confirmationSource"] = args.source
    interview["status"] = "skipped" if interview["bypassReason"] is not None else "complete"
    validate_interview(interview, state)
    write_state(path, state)
    return {"ok": True, "status": interview["status"]}


def command_skip(args: argparse.Namespace) -> dict[str, Any]:
    path = Path(args.state)
    state = read_state(path)
    interview = current_interview(state)
    if interview["status"] not in {"collecting", "awaiting_confirmation"}:
        reject("ILLEGAL_INTERVIEW_TRANSITION", "skip requires an active interview")
    assumptions = require_string_array(args.assumption or [], "skip assumptions")
    if not assumptions:
        reject("ASSUMPTION_REQUIRED", "skip requires at least one nonblank --assumption")
    retired = list(interview["pendingDecisionIds"])
    interview["pendingDecisionIds"] = []
    interview["askedDecisionIds"] = [
        decision_id for decision_id in interview["askedDecisionIds"]
        if decision_id not in retired or decision_id in interview["answeredDecisionIds"]
    ]
    if args.decision_id not in interview["askedDecisionIds"]:
        interview["askedDecisionIds"].append(args.decision_id)
    interview["pendingDecisionIds"].append(args.decision_id)
    interview["status"] = "awaiting_confirmation"
    if interview["selectedApproach"] is None:
        interview["selectedApproach"] = "Skip remaining interview decisions"
    interview["bypassReason"] = args.reason
    for assumption in assumptions:
        if assumption not in interview["assumptionsRecorded"]:
            interview["assumptionsRecorded"].append(assumption)
    validate_interview(interview, state)
    write_state(path, state)
    return {"ok": True, "status": "awaiting_confirmation"}


def command_record_agent_load(args: argparse.Namespace) -> dict[str, Any]:
    path = Path(args.state)
    state = read_state(path)
    skill_load = state.get("phaseSkillLoad")
    if not isinstance(skill_load, dict):
        reject("SKILL_LOAD_MISSING", "phaseSkillLoad is missing")
    receipt = read_json(args.input, "agent load input")
    require_fields(receipt, ["agent", "source", "sha256", "loadStatus", "errors"], "agent load input")
    require_string(receipt["agent"], "agent load input.agent")
    validate_load_receipt(receipt, "agent load input", True)
    if receipt["loadStatus"] == "loaded":
        verify_file_hash(receipt["source"], receipt["sha256"], "agent load input")
    receipts = skill_load.setdefault("artifactAgentLoads", [])
    receipts[:] = [
        item for item in receipts
        if not (item.get("agent") == receipt["agent"] and item.get("source") == receipt["source"])
    ]
    receipts.append(receipt)
    validate_skill_load(skill_load, verify_files=True)
    validate_state_context(state, skill_load, path)
    validate_discovery_linkage(state, skill_load, path)
    write_state(path, state)
    return {"ok": True, "recorded": "artifactAgentLoads"}


def reject(code: str, message: str) -> NoReturn:
    fail(code, message, exit_code=3)


def command_check_delegation(args: argparse.Namespace) -> dict[str, Any]:
    state = read_state(Path(args.state))
    interview = current_interview(state)
    if interview.get("phase") != args.phase or interview.get("interviewId") != args.interview_id:
        reject("INTERVIEW_STALE", "phaseInterview does not match the current phase and interview")
    status = interview.get("status")
    if status not in TERMINAL_INTERVIEW_STATUSES:
        reject("INTERVIEW_INCOMPLETE", f"phaseInterview status {status!r} cannot delegate")
    current_skill_load(
        state,
        Path(args.state),
        args.phase,
        args.interview_id,
        args.context_digest,
        args.discovery_revision,
    )
    if status == "bypassed_quick":
        if not quick_is_authorized(state):
            reject("QUICK_NOT_AUTHORIZED", "quick bypass lacks exact --quick authorization")
        return {"ok": True, "decision": "allow", "path": "quick"}

    return {"ok": True, "decision": "allow", "path": "interview"}


def command_check_agent_write(args: argparse.Namespace) -> dict[str, Any]:
    state = read_state(Path(args.state))
    interview = current_interview(state)
    if interview.get("phase") != args.phase or interview.get("interviewId") != args.interview_id:
        reject("INTERVIEW_STALE", "phaseInterview does not match the artifact write")
    if interview.get("status") not in TERMINAL_INTERVIEW_STATUSES:
        reject("INTERVIEW_INCOMPLETE", "artifact write requires a terminal interview")
    skill_load = current_skill_load(
        state,
        Path(args.state),
        args.phase,
        args.interview_id,
        args.context_digest,
        args.discovery_revision,
    )
    expected = {
        (item["source"], item["body"]["sha256"])
        for item in skill_load["selected"]
        if item["body"]["loadStatus"] == "loaded"
    }
    expected.update(
        (resource["source"], resource["sha256"])
        for item in skill_load["selected"]
        for resource in item["requiredResources"]
        if resource["loadStatus"] == "loaded"
    )
    receipts = {
        (item["source"], item["sha256"])
        for item in skill_load["artifactAgentLoads"]
        if item["agent"] == args.agent and item["loadStatus"] == "loaded" and not item["errors"]
    }
    missing = sorted(source for source, digest in expected if (source, digest) not in receipts)
    if missing:
        reject("AGENT_LOAD_MISSING", f"artifact agent lacks current load receipts: {', '.join(missing)}")
    return {"ok": True, "decision": "allow", "agent": args.agent}


def command_is_substantive(args: argparse.Namespace) -> int:
    if not is_substantive(args.text):
        print("control")
        return 1
    print("substantive")
    return 0


def command_classify_reply(args: argparse.Namespace) -> int:
    print(classify_reply(args.text))
    return 0


def command_revise(args: argparse.Namespace) -> dict[str, Any]:
    path = Path(args.state)
    state = read_state(path)
    interview = current_interview(state)
    if interview["status"] != "awaiting_confirmation":
        reject("ILLEGAL_INTERVIEW_TRANSITION", "revise requires awaiting_confirmation status")
    retired = list(interview["pendingDecisionIds"])
    interview["pendingDecisionIds"] = []
    interview["askedDecisionIds"] = [
        decision_id for decision_id in interview["askedDecisionIds"]
        if decision_id not in retired or decision_id in interview["answeredDecisionIds"]
    ]
    for decision_id in args.decision_id:
        if decision_id in interview["answeredDecisionIds"]:
            interview["answeredDecisionIds"].remove(decision_id)
        if decision_id not in interview["askedDecisionIds"]:
            interview["askedDecisionIds"].append(decision_id)
        interview["pendingDecisionIds"].append(decision_id)
    interview["round"] += 1
    interview["status"] = "collecting"
    interview["selectedApproach"] = None
    interview["confirmationSource"] = None
    interview["bypassReason"] = None
    validate_interview(interview, state)
    write_state(path, state)
    return {"ok": True, "status": "collecting", "round": interview["round"]}


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Persist and validate Ralph Specum phase gates."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    mode = subparsers.add_parser(
        "mode", help="Set or normalize interactive mode.", allow_abbrev=False
    )
    mode.add_argument("state")
    selection = mode.add_mutually_exclusive_group()
    selection.add_argument("--quick", action="store_true")
    selection.add_argument("--interactive", action="store_true")
    mode.set_defaults(handler=command_mode)

    skill = subparsers.add_parser("record-skill-load", help="Validate and record phaseSkillLoad.")
    skill.add_argument("state")
    skill.add_argument("--input", required=True, help="JSON file path, or - for stdin.")
    skill.set_defaults(handler=command_record_skill_load)

    begin = subparsers.add_parser("begin-interview", help="Open a current phase interview.")
    begin.add_argument("state")
    begin.add_argument("--phase", required=True)
    begin.add_argument("--interview-id", required=True)
    begin.add_argument("--round", required=True, type=int)
    begin.add_argument("--discovery-revision", required=True)
    begin.add_argument("--context-digest", required=True)
    begin.set_defaults(handler=command_begin_interview)

    answer = subparsers.add_parser("record-answer", help="Record one substantive decision answer.")
    answer.add_argument("state")
    answer.add_argument("--decision-id", required=True)
    answer.add_argument("--answer", required=True)
    answer.add_argument("--assumption")
    answer.set_defaults(handler=command_record_answer)

    frontier = subparsers.add_parser("open-frontier", help="Record decisions before asking them.")
    frontier.add_argument("state")
    frontier.add_argument("--round", required=True, type=int)
    frontier.add_argument("--decision-id", action="append", required=True)
    frontier.set_defaults(handler=command_open_frontier)

    awaiting = subparsers.add_parser("await-confirmation", help="Request explicit approach confirmation.")
    awaiting.add_argument("state")
    awaiting.add_argument("--decision-id", required=True)
    awaiting.add_argument("--approach", required=True)
    awaiting.set_defaults(handler=command_await_confirmation)

    confirm = subparsers.add_parser("confirm", help="Complete an awaiting interview.")
    confirm.add_argument("state")
    confirm.add_argument("--decision-id", required=True)
    confirm.add_argument("--source", required=True)
    confirm.set_defaults(handler=command_confirm)

    skip = subparsers.add_parser("skip", help="Skip an active interview with recorded assumptions.")
    skip.add_argument("state")
    skip.add_argument("--reason", required=True)
    skip.add_argument("--assumption", action="append")
    skip.add_argument("--decision-id", default="skip-confirmation")
    skip.set_defaults(handler=command_skip)

    agent_load = subparsers.add_parser("record-agent-load", help="Record one artifact agent source load.")
    agent_load.add_argument("state")
    agent_load.add_argument("--input", required=True, help="JSON file path, or - for stdin.")
    agent_load.set_defaults(handler=command_record_agent_load)

    revise = subparsers.add_parser("revise", help="Reopen decisions after final review.")
    revise.add_argument("state")
    revise.add_argument("--decision-id", action="append", required=True)
    revise.set_defaults(handler=command_revise)

    check = subparsers.add_parser("check-delegation", help="Reject delegation until current gates pass.")
    check.add_argument("state")
    check.add_argument("--phase", required=True)
    check.add_argument("--interview-id", required=True)
    check.add_argument("--discovery-revision", required=True)
    check.add_argument("--context-digest", required=True)
    check.set_defaults(handler=command_check_delegation)

    agent_write = subparsers.add_parser("check-agent-write", help="Reject artifact writes without current agent receipts.")
    agent_write.add_argument("state")
    agent_write.add_argument("--phase", required=True)
    agent_write.add_argument("--interview-id", required=True)
    agent_write.add_argument("--context-digest", required=True)
    agent_write.add_argument("--discovery-revision", required=True)
    agent_write.add_argument("--agent", required=True)
    agent_write.set_defaults(handler=command_check_agent_write)

    substantive = subparsers.add_parser(
        "is-substantive", help="Classify interview input as substantive or control-only."
    )
    substantive.add_argument("--text", required=True)
    substantive.set_defaults(handler=command_is_substantive)

    classify = subparsers.add_parser("classify-reply", help="Classify an interview reply.")
    classify.add_argument("--text", required=True)
    classify.set_defaults(handler=command_classify_reply)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        if hasattr(args, "state"):
            with state_lock(Path(args.state)):
                result = args.handler(args)
        else:
            result = args.handler(args)
        if isinstance(result, int):
            return result
        print(json.dumps(result, sort_keys=True))
        return 0
    except PhaseGateError as error:
        print(f"ERROR: {error.code}: {error}", file=sys.stderr)
        return error.exit_code


if __name__ == "__main__":
    raise SystemExit(main())
