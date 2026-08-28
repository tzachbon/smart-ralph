"""Native and simulated Windows coverage for prototype durability primitives."""

from __future__ import annotations

import argparse
import json
import os
import signal
import socket
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path
from unittest import mock


REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = REPO_ROOT / "plugins" / "ralph-specum-codex" / "scripts"
sys.path.insert(0, str(SCRIPTS))

import locked_state  # noqa: E402
import prototype_harness  # noqa: E402
import prototype_records  # noqa: E402


HEADINGS = (
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


class PrototypeWindowsTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.base_path = Path(self.temp.name) / "specs" / "demo"
        self.base_path.mkdir(parents=True)
        self.state_path = self.base_path / ".ralph-state.json"

    def tearDown(self) -> None:
        self.temp.cleanup()

    def test_simulated_windows_pid_probes_do_not_call_os_kill(self) -> None:
        with mock.patch.object(locked_state.os, "name", "nt"):
            with mock.patch.object(locked_state, "_windows_pid_running", return_value=True):
                with mock.patch.object(locked_state.os, "kill") as kill_spy:
                    self.assertTrue(locked_state.pid_exists(123))
                    kill_spy.assert_not_called()

        with mock.patch.object(prototype_harness.os, "name", "nt"):
            with mock.patch.object(prototype_harness, "_windows_pid_running", return_value=True):
                with mock.patch.object(prototype_harness.os, "kill") as kill_spy:
                    self.assertTrue(prototype_harness.pid_running(123))
                    kill_spy.assert_not_called()

    def test_posix_pid_probe_parses_zombie_state_after_command_name(self) -> None:
        """Treat a spaced-command /proc zombie entry as no longer running."""

        proc_stat = mock.Mock()
        proc_stat.exists.return_value = True
        proc_stat.read_text.return_value = "123 (builder command with spaces) Z 1 2 3\n"

        with mock.patch.object(prototype_harness, "Path", return_value=proc_stat):
            with mock.patch.object(prototype_harness.os, "kill") as kill_spy:
                self.assertFalse(prototype_harness.pid_running(123))
                kill_spy.assert_not_called()

    def test_simulated_windows_interrupt_failure_keeps_run_running(self) -> None:
        registry = Path(self.temp.name) / "harness"
        run_id = "windows-interrupt-failure"
        metadata_path = prototype_harness.registry_path(registry, run_id)
        prototype_harness.write_metadata(
            metadata_path,
            {
                "id": run_id,
                "pid": 12345,
                "status": "running",
                "startedEpoch": time.time(),
            },
        )
        failed = subprocess.CompletedProcess(
            ["taskkill", "/PID", "12345", "/T", "/F"],
            returncode=1,
            stdout="",
            stderr="termination failed",
        )

        with mock.patch.object(prototype_harness.os, "name", "nt"):
            with mock.patch.object(prototype_harness, "pid_running", return_value=True) as running_spy:
                with mock.patch.object(prototype_harness.subprocess, "run", return_value=failed) as run_spy:
                    with self.assertRaises(prototype_harness.HarnessError) as raised:
                        prototype_harness.interrupt(registry=registry, run_id=run_id)

        self.assertEqual(raised.exception.outcome, "unavailable-control")
        run_spy.assert_called_once_with(
            ["taskkill", "/PID", "12345", "/T", "/F"],
            check=False,
            capture_output=True,
            text=True,
            timeout=5.0,
            shell=False,
        )
        running_spy.assert_called_once_with(12345)
        persisted = json.loads(metadata_path.read_text(encoding="utf-8"))
        self.assertEqual(persisted["status"], "running")
        self.assertTrue(persisted["terminationUnverified"])
        self.assertIn("taskkill exited with status 1", persisted["controlError"])

    def test_simulated_windows_interrupt_rejects_unverified_parent_exit(self) -> None:
        registry = Path(self.temp.name) / "harness"
        run_id = "windows-interrupt-race"
        metadata_path = prototype_harness.registry_path(registry, run_id)
        started = time.time()
        prototype_harness.write_metadata(
            metadata_path,
            {
                "id": run_id,
                "pid": 12345,
                "status": "running",
                "startedEpoch": started,
                "rollingDeadlineEpoch": started + 30,
                "hardDeadlineEpoch": started + 60,
                "activityExtensionSeconds": 10,
            },
        )
        parent_running = True

        def pid_running(_pid: int) -> bool:
            return parent_running

        def failed_taskkill(*_args: object, **_kwargs: object) -> subprocess.CompletedProcess[str]:
            nonlocal parent_running
            parent_running = False
            return subprocess.CompletedProcess(
                ["taskkill", "/PID", "12345", "/T", "/F"],
                returncode=1,
                stdout="",
                stderr="parent exited before process-tree confirmation",
            )

        with mock.patch.object(prototype_harness.os, "name", "nt"):
            with mock.patch.object(prototype_harness, "pid_running", side_effect=pid_running):
                with mock.patch.object(prototype_harness.subprocess, "run", side_effect=failed_taskkill) as run_spy:
                    with self.assertRaises(prototype_harness.HarnessError) as raised:
                        prototype_harness.interrupt(registry=registry, run_id=run_id)

        self.assertEqual(raised.exception.outcome, "unavailable-control")
        run_spy.assert_called_once_with(
            ["taskkill", "/PID", "12345", "/T", "/F"],
            check=False,
            capture_output=True,
            text=True,
            timeout=5.0,
            shell=False,
        )
        persisted = json.loads(metadata_path.read_text(encoding="utf-8"))
        self.assertEqual(persisted["status"], "running")
        self.assertTrue(persisted["terminationUnverified"])
        self.assertIn("taskkill exited with status 1", persisted["controlError"])
        self.assertFalse(parent_running)
        rolling_deadline = persisted["rollingDeadlineEpoch"]

        for operation in (
            lambda: prototype_harness.status(registry=registry, run_id=run_id),
            lambda: prototype_harness.wait(registry=registry, run_id=run_id, until_seconds=0),
            lambda: prototype_harness.heartbeat(registry=registry, run_id=run_id),
        ):
            with self.assertRaises(prototype_harness.HarnessError) as control_raised:
                operation()
            self.assertEqual(control_raised.exception.outcome, "unavailable-control")

        persisted = json.loads(metadata_path.read_text(encoding="utf-8"))
        self.assertEqual(persisted["status"], "running")
        self.assertEqual(persisted["rollingDeadlineEpoch"], rolling_deadline)

        successful = subprocess.CompletedProcess(
            ["taskkill", "/PID", "12345", "/T", "/F"],
            returncode=0,
            stdout="SUCCESS",
            stderr="",
        )
        with mock.patch.object(prototype_harness.os, "name", "nt"):
            with mock.patch.object(prototype_harness, "pid_running", return_value=False):
                with mock.patch.object(
                    prototype_harness.subprocess, "run", return_value=successful
                ) as retry_spy:
                    result = prototype_harness.interrupt(registry=registry, run_id=run_id)

        self.assertEqual(result["outcome"], "stopped")
        retry_spy.assert_called_once_with(
            ["taskkill", "/PID", "12345", "/T", "/F"],
            check=False,
            capture_output=True,
            text=True,
            timeout=5.0,
            shell=False,
        )
        persisted = json.loads(metadata_path.read_text(encoding="utf-8"))
        self.assertEqual(persisted["status"], "stopped")
        self.assertNotIn("terminationUnverified", persisted)
        self.assertNotIn("controlError", persisted)
        self.assertNotIn("controlErrorAt", persisted)

    def test_simulated_posix_interrupt_failure_stays_unverified(self) -> None:
        """Keep a run active when POSIX process-group termination cannot be verified."""

        registry = Path(self.temp.name) / "harness"
        run_id = "posix-interrupt-failure"
        metadata_path = prototype_harness.registry_path(registry, run_id)
        prototype_harness.write_metadata(
            metadata_path,
            {
                "id": run_id,
                "pid": 12345,
                "status": "running",
                "startedEpoch": time.time(),
            },
        )

        sigkill = getattr(signal, "SIGKILL", signal.SIGTERM)
        with mock.patch.object(prototype_harness.os, "name", "posix"):
            with mock.patch.object(prototype_harness, "pid_running", return_value=True):
                with mock.patch.object(prototype_harness.os, "killpg", create=True) as killpg_spy:
                    with mock.patch.object(prototype_harness.signal, "SIGKILL", sigkill, create=True):
                        with mock.patch.object(
                            prototype_harness.time,
                            "monotonic",
                            side_effect=(10.0, 12.0, 20.0, 26.0),
                        ):
                            with self.assertRaises(prototype_harness.HarnessError) as raised:
                                prototype_harness.interrupt(registry=registry, run_id=run_id)

        self.assertEqual(raised.exception.outcome, "unavailable-control")
        self.assertEqual(
            killpg_spy.call_args_list,
            [
                mock.call(12345, signal.SIGTERM),
                mock.call(12345, 0),
                mock.call(12345, sigkill),
                mock.call(12345, 0),
            ],
        )
        persisted = json.loads(metadata_path.read_text(encoding="utf-8"))
        self.assertEqual(persisted["status"], "running")
        self.assertTrue(persisted["terminationUnverified"])
        self.assertIn("process group did not exit", persisted["controlError"])

    @unittest.skipUnless(os.name == "nt", "requires native Windows process APIs")
    def test_native_windows_pid_probes_leave_a_live_process_running(self) -> None:
        process = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(30)"])
        try:
            self.assertTrue(locked_state.pid_exists(process.pid))
            self.assertTrue(prototype_harness.pid_running(process.pid))
            self.assertIsNone(process.poll())
        finally:
            process.terminate()
            process.wait(timeout=5)

    @unittest.skipUnless(os.name == "nt", "requires native Windows process APIs")
    def test_native_windows_interrupt_terminates_builder_process_tree(self) -> None:
        registry = Path(self.temp.name) / "harness"
        launched = prototype_harness.launch(
            registry=registry,
            run_id="windows-interrupt",
            kind="codex_agent",
            command=[
                sys.executable,
                "-c",
                (
                    "import subprocess, sys, time; "
                    "child = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(30)']); "
                    "print(child.pid, flush=True); "
                    "time.sleep(30)"
                ),
            ],
            agent_id="windows-child",
        )
        parent_pid = int(launched["pid"])
        child_pid = 0
        try:
            output_deadline = time.monotonic() + 5.0
            while time.monotonic() < output_deadline:
                output = prototype_harness.read_output(registry, "windows-interrupt").strip()
                if output.isdigit():
                    child_pid = int(output)
                    break
                time.sleep(0.05)
            self.assertGreater(child_pid, 0, "builder did not report its descendant PID")

            result = prototype_harness.interrupt(registry=registry, run_id="windows-interrupt")
            self.assertEqual(result["outcome"], "stopped")
            for pid in (parent_pid, child_pid):
                exit_deadline = time.monotonic() + 5.0
                while prototype_harness.pid_running(pid) and time.monotonic() < exit_deadline:
                    time.sleep(0.05)
                self.assertFalse(prototype_harness.pid_running(pid), f"Windows process {pid} survived interrupt")
        finally:
            for pid in (parent_pid, child_pid):
                if pid > 0 and prototype_harness.pid_running(pid):
                    subprocess.run(
                        ["taskkill", "/PID", str(pid), "/T", "/F"],
                        check=False,
                        capture_output=True,
                        text=True,
                        timeout=5.0,
                        shell=False,
                    )

    def test_directory_lock_lifecycle_and_stale_handling(self) -> None:
        lock_path = self.base_path / ".ralph-state.lock"
        with mock.patch.object(locked_state, "fcntl", None):
            with locked_state.lock_for(self.state_path, 0.2):
                self.assertTrue(lock_path.is_dir())
                owner = json.loads((lock_path / "owner.json").read_text(encoding="utf-8"))
                self.assertEqual(owner["host"], socket.gethostname())
            self.assertFalse(lock_path.exists())

            lock_path.mkdir()
            (lock_path / "owner.json").write_text(
                json.dumps(
                    {
                        "host": socket.gethostname(),
                        "pid": 999999,
                        "created": "2000-01-01T00:00:00Z",
                        "heartbeatAt": "2000-01-01T00:00:00Z",
                    }
                ),
                encoding="utf-8",
            )
            with mock.patch.object(locked_state, "pid_exists", return_value=False):
                with locked_state.directory_lock(lock_path, 0.2, stale_seconds=1):
                    replacement = json.loads((lock_path / "owner.json").read_text(encoding="utf-8"))
                    self.assertEqual(replacement["pid"], os.getpid())
            self.assertFalse(lock_path.exists())

            lock_path.mkdir()
            (lock_path / "owner.json").write_text(
                json.dumps(
                    {
                        "host": socket.gethostname(),
                        "pid": os.getpid(),
                        "created": locked_state.utc_now(),
                        "heartbeatAt": locked_state.utc_now(),
                    }
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(locked_state.StateError, "Timed out acquiring lock"):
                with locked_state.directory_lock(lock_path, 0.02, stale_seconds=600):
                    self.fail("live directory lock was acquired")

    def test_ownerless_directory_lock_recovers_only_after_stale_age(self) -> None:
        lock_path = self.base_path / ".ralph-state.lock"
        lock_path.mkdir()

        with self.assertRaisesRegex(locked_state.StateError, "Timed out acquiring lock"):
            with locked_state.directory_lock(lock_path, 0.02, stale_seconds=1):
                self.fail("fresh ownerless lock was acquired")
        self.assertTrue(lock_path.is_dir())

        stale_time = locked_state.time.time() - 2
        os.utime(lock_path, (stale_time, stale_time))
        with locked_state.directory_lock(lock_path, 0.2, stale_seconds=1):
            self.assertTrue((lock_path / "owner.json").is_file())
        self.assertFalse(lock_path.exists())

    def test_malformed_stale_owner_pid_uses_normal_recovery(self) -> None:
        """Recover a stale directory lock whose owner PID is malformed."""

        lock_path = self.base_path / ".ralph-state.lock"
        lock_path.mkdir()
        (lock_path / "owner.json").write_text(
            json.dumps(
                {
                    "host": socket.gethostname(),
                    "pid": "not-a-pid",
                    "created": "2000-01-01T00:00:00Z",
                    "heartbeatAt": "2000-01-01T00:00:00Z",
                }
            ),
            encoding="utf-8",
        )

        with locked_state.directory_lock(lock_path, 0.2, stale_seconds=1):
            owner = json.loads((lock_path / "owner.json").read_text(encoding="utf-8"))
            self.assertEqual(owner["pid"], os.getpid())
        self.assertFalse(lock_path.exists())

    def test_state_error_is_a_catchable_application_exception(self) -> None:
        """Expose rejected state operations as catchable StateError exceptions."""

        caught: Exception | None = None
        try:
            locked_state.parse_pairs(["missing-separator"], as_json=False)
        except Exception as exc:
            caught = exc

        self.assertIsInstance(caught, locked_state.StateError)
        self.assertNotIsInstance(caught, SystemExit)

    def test_directory_lock_cleans_up_when_owner_metadata_write_fails(self) -> None:
        lock_path = self.base_path / ".ralph-state.lock"
        with mock.patch.object(Path, "write_text", side_effect=OSError("metadata failure")):
            with self.assertRaisesRegex(OSError, "metadata failure"):
                with locked_state.directory_lock(lock_path, 0.2):
                    self.fail("lock with missing metadata was acquired")
        self.assertFalse(lock_path.exists())

    def test_atomic_replace_flushes_file_and_ignores_unsupported_directory_fsync(self) -> None:
        real_fsync = os.fsync
        real_replace = os.replace
        with mock.patch.object(locked_state.os, "fsync", wraps=real_fsync) as fsync_spy:
            with mock.patch.object(locked_state.os, "replace", wraps=real_replace) as replace_spy:
                locked_state.write_json_atomic(self.state_path, {"phase": "requirements", "value": 3})

        self.assertGreaterEqual(fsync_spy.call_count, 1)
        replace_spy.assert_called_once()
        self.assertEqual(locked_state.read_json_object(self.state_path)["value"], 3)
        self.assertFalse(self.state_path.with_name(self.state_path.name + ".tmp").exists())

        with mock.patch.object(locked_state.os, "open", side_effect=OSError("unsupported")):
            locked_state.fsync_dir(self.base_path)

    def test_exclusive_publication_never_overwrites_final_bytes(self) -> None:
        candidate = self.base_path / "prototypes" / ".exclusive.candidate.md"
        final = self.base_path / "prototypes" / "exclusive.md"
        candidate.parent.mkdir()
        candidate.write_bytes(b"reviewed bytes\n")

        prototype_records.publish_exact(candidate, final)
        self.assertEqual(final.read_bytes(), b"reviewed bytes\n")

        second = self.base_path / "prototypes" / ".second.candidate.md"
        second.write_bytes(b"replacement bytes\n")
        with self.assertRaisesRegex(prototype_records.RecordError, "collision"):
            prototype_records.publish_exact(second, final)
        self.assertEqual(final.read_bytes(), b"reviewed bytes\n")

    def test_deleted_source_receipt_gates_final_review_and_publication(self) -> None:
        prototype_id = "quick-cleanup"
        evidence_hash = "b" * 64
        missing_source = Path(self.temp.name) / "deleted-source"
        entry = {"id": prototype_id, "status": "reviewing", "stateRevision": 1}
        locked_state.write_json_atomic(
            self.state_path,
            {"phase": "requirements", "activePrototypes": {prototype_id: entry}},
        )

        receipt = prototype_records.cmd_cleanup_receipt(
            argparse.Namespace(
                base_path=self.base_path,
                id=prototype_id,
                receipt_json=json.dumps(
                    {
                        "candidateHash": "a" * 64,
                        "evidenceHash": evidence_hash,
                        "isolationPath": str(missing_source),
                        "provenance": "scratch",
                    }
                ),
            )
        )
        receipt_path = Path(receipt["receipt"])
        sections = {heading: "none" for heading in HEADINGS}
        sections["Question"] = "Can deleted source still produce reviewed final bytes?"
        sections["Source Disposition"] = "Deleted after verified cleanup receipt."
        record = {
            "spec": "demo",
            "phase": "prototype",
            "id": prototype_id,
            "status": "terminal",
            "verdict": "validated",
            "kind": "logic",
            "captureMode": "ephemeral",
            "triggerMode": "quick",
            "triggerPhase": "requirements",
            "returnPhase": "design",
            "returnTaskIndex": None,
            "decisionOwner": "agent",
            "resolutionMode": "quick",
            "gateApproved": True,
            "created": "2026-08-28T00:00:00Z",
            "completed": "2026-08-28T00:00:01Z",
            "sourceDisposition": "deleted",
            "evidenceHash": evidence_hash,
            "cleanupReceiptHash": receipt["receiptHash"],
            "staleArtifacts": [],
            "staleTaskIndexes": [],
            "sections": sections,
        }
        rendered = prototype_records.cmd_render_candidate(
            argparse.Namespace(base_path=self.base_path, record_json=json.dumps(record))
        )
        reviewed = prototype_records.cmd_review_candidate(
            argparse.Namespace(
                base_path=self.base_path,
                id=prototype_id,
                candidate_hash=rendered["candidateHash"],
                evidence_hash=evidence_hash,
                cleanup_receipt=receipt_path,
                state=self.state_path,
                timeout=1.0,
            )
        )
        self.assertTrue(reviewed["reviewPass"])

        published = prototype_records.cmd_publish(
            argparse.Namespace(
                base_path=self.base_path,
                id=prototype_id,
                state=self.state_path,
                timeout=1.0,
                publisher_only_lock_timeout=False,
                candidate_hash=None,
            )
        )
        final = Path(published["final"])
        self.assertEqual(published["recordHash"], rendered["candidateHash"])
        self.assertTrue(final.is_file())
        self.assertFalse(Path(rendered["candidate"]).exists())
        self.assertFalse(missing_source.exists())
        self.assertNotIn("activePrototypes", locked_state.read_json_object(self.state_path))


if __name__ == "__main__":
    unittest.main()
