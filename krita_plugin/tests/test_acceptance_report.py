import importlib.util
import io
import json
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from unittest.mock import patch

PLUGIN_ROOT = Path(__file__).resolve().parents[1]
DESKTOP_MANIFEST_TEXT = (
    "ServiceTypes=Krita/PythonPlugin\n"
    "X-KDE-Library=nai_launcher_bridge\n"
    "Name=NAI Launcher Bridge\n"
)


def _load_module(name: str, file_name: str):
    spec = importlib.util.spec_from_file_location(name, PLUGIN_ROOT / file_name)
    module = importlib.util.module_from_spec(spec)
    assert spec is not None and spec.loader is not None
    spec.loader.exec_module(module)
    return module


def _run_main_silently(module) -> int:
    with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
        return module.main()


def _install_current_profile(install_plugin, root: Path):
    pykrita_dir = root / "pykrita"
    kritarc_path = root / "kritarc"
    install_plugin.install_plugin(
        pykrita_dir=pykrita_dir,
        kritarc_path=kritarc_path,
        backup_dir=root / "backup",
        apply=True,
        krita_running=False,
    )
    profile = install_plugin.check_profile(
        pykrita_dir=pykrita_dir,
        kritarc_path=kritarc_path,
    )
    return pykrita_dir, kritarc_path, profile


class AcceptanceReportTests(unittest.TestCase):
    def test_report_marks_missing_diagnostics_as_pending(self):
        module = _load_module(
            "krita_bridge_acceptance_report_test",
            "acceptance_report.py",
        )
        install_plugin = _load_module(
            "krita_bridge_install_for_acceptance_test",
            "install_plugin.py",
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            profile = install_plugin.check_profile(
                pykrita_dir=root / "pykrita",
                kritarc_path=root / "kritarc",
            )

            report = module.build_acceptance_report(
                profile=profile,
                diagnostics=None,
                diagnostics_path=root / "missing.json",
            )

            by_name = {gate.name: gate.status for gate in report.gates}
            self.assertFalse(report.ok)
            self.assertEqual("fail", by_name["profile_installed_enabled"])
            self.assertEqual("pending", by_name["diagnostics_report"])
            self.assertEqual("pending", by_name["docker_visible"])

    def test_report_accepts_profile_and_diagnostics_evidence(self):
        module = _load_module(
            "krita_bridge_acceptance_report_test",
            "acceptance_report.py",
        )
        install_plugin = _load_module(
            "krita_bridge_install_for_acceptance_test",
            "install_plugin.py",
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            _pykrita_dir, _kritarc_path, profile = _install_current_profile(
                install_plugin,
                root,
            )

            diagnostics = {
                "schema_version": 1,
                "plugin": "nai_launcher_bridge",
                "checks": [
                    {"name": "plugin_layout", "status": "pass"},
                    {"name": "launcher_discovery", "status": "pass"},
                    {"name": "active_document", "status": "pass"},
                    {"name": "canvas_png_round_trip", "status": "pass"},
                    {"name": "selection_and_masks", "status": "pass"},
                ],
            }

            report = module.build_acceptance_report(
                profile=profile,
                diagnostics=diagnostics,
                diagnostics_path=root / "diagnostics.json",
            )

            by_name = {gate.name: gate.status for gate in report.gates}
            self.assertFalse(report.ok)
            self.assertEqual("pass", by_name["profile_installed_enabled"])
            self.assertEqual("pass", by_name["diagnostics_report"])
            self.assertEqual("pass", by_name["canvas_png_round_trip"])
            self.assertEqual("pending", by_name["docker_visible"])

    def test_report_rejects_diagnostics_without_bridge_schema_marker(self):
        module = _load_module(
            "krita_bridge_acceptance_report_test",
            "acceptance_report.py",
        )
        install_plugin = _load_module(
            "krita_bridge_install_for_acceptance_test",
            "install_plugin.py",
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            pykrita_dir = root / "pykrita"
            plugin_dir = pykrita_dir / "nai_launcher_bridge"
            plugin_dir.mkdir(parents=True)
            (pykrita_dir / "nai_launcher_bridge.desktop").write_text(
                DESKTOP_MANIFEST_TEXT,
                encoding="utf-8",
            )
            for _check_name, relative_path in install_plugin.REQUIRED_PLUGIN_FILES:
                (plugin_dir / relative_path).write_text("", encoding="utf-8")
            kritarc_path = root / "kritarc"
            kritarc_path.write_text(
                "[python]\nenable_nai_launcher_bridge=true\n",
                encoding="utf-8",
            )
            profile = install_plugin.check_profile(
                pykrita_dir=pykrita_dir,
                kritarc_path=kritarc_path,
            )

            report = module.build_acceptance_report(
                profile=profile,
                diagnostics={
                    "checks": [
                        {"name": "launcher_discovery", "status": "pass"},
                    ],
                },
                diagnostics_path=root / "diagnostics.json",
            )

            by_name = {gate.name: gate for gate in report.gates}
            self.assertFalse(report.ok)
            self.assertEqual("fail", by_name["diagnostics_report"].status)
            self.assertIn("schema_version", by_name["diagnostics_report"].detail)
            self.assertEqual("pending", by_name["launcher_discovery"].status)

    def test_report_rejects_non_object_diagnostics_without_crashing(self):
        module = _load_module(
            "krita_bridge_acceptance_report_test",
            "acceptance_report.py",
        )
        install_plugin = _load_module(
            "krita_bridge_install_for_acceptance_test",
            "install_plugin.py",
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            profile = install_plugin.check_profile(
                pykrita_dir=root / "pykrita",
                kritarc_path=root / "kritarc",
            )

            report = module.build_acceptance_report(
                profile=profile,
                diagnostics=[],
                diagnostics_path=root / "diagnostics.json",
            )

            by_name = {gate.name: gate for gate in report.gates}
            self.assertFalse(report.ok)
            self.assertEqual("fail", by_name["diagnostics_report"].status)
            self.assertIn("JSON object", by_name["diagnostics_report"].detail)
            self.assertEqual("pending", by_name["launcher_discovery"].status)

    def test_report_rejects_diagnostics_when_plugin_layout_check_did_not_pass(self):
        module = _load_module(
            "krita_bridge_acceptance_report_test",
            "acceptance_report.py",
        )
        install_plugin = _load_module(
            "krita_bridge_install_for_acceptance_test",
            "install_plugin.py",
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            pykrita_dir = root / "pykrita"
            plugin_dir = pykrita_dir / "nai_launcher_bridge"
            plugin_dir.mkdir(parents=True)
            (pykrita_dir / "nai_launcher_bridge.desktop").write_text(
                DESKTOP_MANIFEST_TEXT,
                encoding="utf-8",
            )
            for _check_name, relative_path in install_plugin.REQUIRED_PLUGIN_FILES:
                (plugin_dir / relative_path).write_text("", encoding="utf-8")
            kritarc_path = root / "kritarc"
            kritarc_path.write_text(
                "[python]\nenable_nai_launcher_bridge=true\n",
                encoding="utf-8",
            )
            profile = install_plugin.check_profile(
                pykrita_dir=pykrita_dir,
                kritarc_path=kritarc_path,
            )

            report = module.build_acceptance_report(
                profile=profile,
                diagnostics={
                    "schema_version": 1,
                    "plugin": "nai_launcher_bridge",
                    "checks": [
                        {"name": "plugin_layout", "status": "fail"},
                        {"name": "launcher_discovery", "status": "pass"},
                    ],
                },
                diagnostics_path=root / "diagnostics.json",
            )

            by_name = {gate.name: gate for gate in report.gates}
            self.assertFalse(report.ok)
            self.assertEqual("fail", by_name["diagnostics_report"].status)
            self.assertIn("plugin_layout", by_name["diagnostics_report"].detail)
            self.assertEqual("pending", by_name["launcher_discovery"].status)

    def test_manual_evidence_can_close_gui_and_end_to_end_gates(self):
        module = _load_module(
            "krita_bridge_acceptance_report_test",
            "acceptance_report.py",
        )
        install_plugin = _load_module(
            "krita_bridge_install_for_acceptance_test",
            "install_plugin.py",
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            _pykrita_dir, _kritarc_path, profile = _install_current_profile(
                install_plugin,
                root,
            )
            diagnostics = {
                "schema_version": 1,
                "plugin": "nai_launcher_bridge",
                "checks": [
                    {"name": "plugin_layout", "status": "pass"},
                    {"name": "launcher_discovery", "status": "pass"},
                    {"name": "active_document", "status": "pass"},
                    {"name": "canvas_png_round_trip", "status": "pass"},
                    {"name": "selection_and_masks", "status": "pass"},
                ],
            }

            report = module.build_acceptance_report(
                profile=profile,
                diagnostics=diagnostics,
                diagnostics_path=root / "diagnostics.json",
                manual_evidence={
                    "plugin_manager_visible": True,
                    "docker_visible": True,
                    "launcher_settings_toggle": True,
                    "auto_discovery_connect": True,
                    "auth_failure_safe": True,
                    "img2img_e2e": True,
                    "inpaint_e2e": True,
                    "krita_cancel_e2e": True,
                    "no_selection_behavior": True,
                    "large_canvas_rejected": True,
                    "disconnect_generation_safe": True,
                    "preview_throttle": True,
                    "result_layer_aligned": True,
                    "launcher_history_recorded": True,
                    "novelai_token_launcher_only": True,
                    "bridge_rejects_unauthenticated": True,
                    "gallery_send_e2e": True,
                    "disabled_bridge_existing_flows": True,
                },
            )

            by_name = {gate.name: gate.status for gate in report.gates}
            self.assertTrue(report.ok)
            self.assertEqual("pass", by_name["plugin_manager_visible"])
            self.assertEqual("pass", by_name["docker_visible"])
            self.assertEqual("pass", by_name["launcher_settings_toggle"])
            self.assertEqual("pass", by_name["auto_discovery_connect"])
            self.assertEqual("pass", by_name["auth_failure_safe"])
            self.assertEqual("pass", by_name["img2img_e2e"])
            self.assertEqual("pass", by_name["inpaint_e2e"])
            self.assertEqual("pass", by_name["krita_cancel_e2e"])
            self.assertEqual("pass", by_name["no_selection_behavior"])
            self.assertEqual("pass", by_name["large_canvas_rejected"])
            self.assertEqual("pass", by_name["disconnect_generation_safe"])
            self.assertEqual("pass", by_name["preview_throttle"])
            self.assertEqual("pass", by_name["result_layer_aligned"])
            self.assertEqual("pass", by_name["launcher_history_recorded"])
            self.assertEqual("pass", by_name["novelai_token_launcher_only"])
            self.assertEqual("pass", by_name["bridge_rejects_unauthenticated"])
            self.assertEqual("pass", by_name["gallery_send_e2e"])
            self.assertEqual("pass", by_name["disabled_bridge_existing_flows"])

    def test_missing_manual_evidence_keeps_end_to_end_gates_pending(self):
        module = _load_module(
            "krita_bridge_acceptance_report_test",
            "acceptance_report.py",
        )
        install_plugin = _load_module(
            "krita_bridge_install_for_acceptance_test",
            "install_plugin.py",
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            profile = install_plugin.check_profile(
                pykrita_dir=root / "pykrita",
                kritarc_path=root / "kritarc",
            )
            report = module.build_acceptance_report(
                profile=profile,
                diagnostics=None,
                diagnostics_path=root / "missing.json",
            )

            by_name = {gate.name: gate.status for gate in report.gates}
            self.assertEqual("pending", by_name["plugin_manager_visible"])
            self.assertEqual("pending", by_name["launcher_settings_toggle"])
            self.assertEqual("pending", by_name["auto_discovery_connect"])
            self.assertEqual("pending", by_name["auth_failure_safe"])
            self.assertEqual("pending", by_name["img2img_e2e"])
            self.assertEqual("pending", by_name["inpaint_e2e"])
            self.assertEqual("pending", by_name["krita_cancel_e2e"])
            self.assertEqual("pending", by_name["no_selection_behavior"])
            self.assertEqual("pending", by_name["large_canvas_rejected"])
            self.assertEqual("pending", by_name["disconnect_generation_safe"])
            self.assertEqual("pending", by_name["preview_throttle"])
            self.assertEqual("pending", by_name["result_layer_aligned"])
            self.assertEqual("pending", by_name["launcher_history_recorded"])
            self.assertEqual("pending", by_name["novelai_token_launcher_only"])
            self.assertEqual("pending", by_name["bridge_rejects_unauthenticated"])
            self.assertEqual("pending", by_name["gallery_send_e2e"])
            self.assertEqual("pending", by_name["disabled_bridge_existing_flows"])

    def test_acceptance_artifacts_include_json_and_markdown_gate_table(self):
        module = _load_module(
            "krita_bridge_acceptance_report_test",
            "acceptance_report.py",
        )
        install_plugin = _load_module(
            "krita_bridge_install_for_acceptance_test",
            "install_plugin.py",
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            profile = install_plugin.check_profile(
                pykrita_dir=root / "pykrita",
                kritarc_path=root / "kritarc",
            )
            report = module.build_acceptance_report(
                profile=profile,
                diagnostics=None,
                diagnostics_path=root / "missing.json",
            )
            json_path = root / "acceptance.json"
            markdown_path = root / "acceptance.md"

            module.write_acceptance_artifacts(
                report=report,
                json_path=json_path,
                markdown_path=markdown_path,
            )

            json_text = json_path.read_text(encoding="utf-8")
            markdown_text = markdown_path.read_text(encoding="utf-8")
            self.assertIn('"acceptance_ok": false', json_text)
            self.assertIn('"profile_installed_enabled"', json_text)
            self.assertIn("# Krita Bridge Acceptance Report", markdown_text)
            self.assertIn("| profile_installed_enabled | fail |", markdown_text)

    def test_evidence_file_adds_manual_gate_notes_to_artifacts(self):
        module = _load_module(
            "krita_bridge_acceptance_report_test",
            "acceptance_report.py",
        )
        install_plugin = _load_module(
            "krita_bridge_install_for_acceptance_test",
            "install_plugin.py",
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            pykrita_dir = root / "pykrita"
            plugin_dir = pykrita_dir / "nai_launcher_bridge"
            plugin_dir.mkdir(parents=True)
            (pykrita_dir / "nai_launcher_bridge.desktop").write_text(
                DESKTOP_MANIFEST_TEXT,
                encoding="utf-8",
            )
            (plugin_dir / "nai_launcher_bridge.py").write_text("", encoding="utf-8")
            (plugin_dir / "__init__.py").write_text("", encoding="utf-8")
            (plugin_dir / "plugin.py").write_text("", encoding="utf-8")
            (plugin_dir / "bridge_dock.py").write_text("", encoding="utf-8")
            (plugin_dir / "ui.py").write_text("", encoding="utf-8")
            (plugin_dir / "bridge_client.py").write_text("", encoding="utf-8")
            (plugin_dir / "canvas_io.py").write_text("", encoding="utf-8")
            (plugin_dir / "protocol.py").write_text("", encoding="utf-8")
            (plugin_dir / "canvas_utils.py").write_text("", encoding="utf-8")
            (plugin_dir / "diagnostics.py").write_text("", encoding="utf-8")
            (plugin_dir / "discovery.py").write_text("", encoding="utf-8")
            (plugin_dir / "fallback_websocket.py").write_text("", encoding="utf-8")
            kritarc_path = root / "kritarc"
            kritarc_path.write_text(
                "[python]\nenable_nai_launcher_bridge=true\n",
                encoding="utf-8",
            )
            profile = install_plugin.check_profile(
                pykrita_dir=pykrita_dir,
                kritarc_path=kritarc_path,
            )
            evidence_path = root / "evidence.json"
            evidence_path.write_text(
                json.dumps(
                    {
                        "docker_visible": {
                            "passed": True,
                            "note": "Observed Settings > Dockers entry.",
                        },
                        "img2img_e2e": {
                            "passed": True,
                            "note": "1024x1024 result layer matched canvas.",
                        },
                    }
                ),
                encoding="utf-8",
            )

            report = module.build_acceptance_report(
                profile=profile,
                diagnostics={"checks": []},
                diagnostics_path=root / "diagnostics.json",
                manual_evidence=module.load_manual_evidence(evidence_path),
            )
            json_path = root / "acceptance.json"
            markdown_path = root / "acceptance.md"
            module.write_acceptance_artifacts(
                report=report,
                json_path=json_path,
                markdown_path=markdown_path,
            )

            json_text = json_path.read_text(encoding="utf-8")
            markdown_text = markdown_path.read_text(encoding="utf-8")
            self.assertIn('"evidence": "Observed Settings > Dockers entry."', json_text)
            self.assertIn("1024x1024 result layer matched canvas.", markdown_text)

    def test_manual_evidence_rejects_unknown_gate_names(self):
        module = _load_module(
            "krita_bridge_acceptance_report_test",
            "acceptance_report.py",
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "evidence.json"
            path.write_text(
                json.dumps({"dock_visible": {"passed": True}}),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "Unknown evidence gate"):
                module.load_manual_evidence(path)

    def test_manual_evidence_file_rejects_passed_gate_without_note(self):
        module = _load_module(
            "krita_bridge_acceptance_report_test",
            "acceptance_report.py",
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "evidence.json"
            path.write_text(
                json.dumps(
                    {
                        "img2img_e2e": {
                            "passed": True,
                            "note": "   ",
                        },
                    },
                ),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "Manual evidence.*note"):
                module.load_manual_evidence(path)

    def test_manual_evidence_file_rejects_scalar_true_gate(self):
        module = _load_module(
            "krita_bridge_acceptance_report_test",
            "acceptance_report.py",
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "evidence.json"
            path.write_text(
                json.dumps({"img2img_e2e": True}),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "Manual evidence.*note"):
                module.load_manual_evidence(path)

    def test_automation_evidence_rejects_unknown_gate_names(self):
        module = _load_module(
            "krita_bridge_acceptance_report_test",
            "acceptance_report.py",
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "automation_evidence.json"
            path.write_text(
                json.dumps({"gallery_send": {"note": "typo"}}),
                encoding="utf-8",
            )

            with self.assertRaisesRegex(ValueError, "Unknown evidence gate"):
                module.load_automation_evidence(path)

    def test_example_evidence_templates_match_known_gate_names(self):
        module = _load_module(
            "krita_bridge_acceptance_report_test",
            "acceptance_report.py",
        )

        manual = json.loads(
            (PLUGIN_ROOT / "acceptance_evidence.example.json").read_text(
                encoding="utf-8",
            ),
        )
        automation = json.loads(
            (PLUGIN_ROOT / "automation_evidence.example.json").read_text(
                encoding="utf-8",
            ),
        )

        self.assertEqual(module.KNOWN_MANUAL_EVIDENCE_KEYS, set(manual))
        self.assertTrue(set(automation).issubset(module.KNOWN_MANUAL_EVIDENCE_KEYS))

    def test_require_ok_returns_failure_when_any_gate_is_open(self):
        module = _load_module(
            "krita_bridge_acceptance_report_test",
            "acceptance_report.py",
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            with patch.object(
                sys,
                "argv",
                [
                    "acceptance_report.py",
                    "--pykrita-dir",
                    str(root / "pykrita"),
                    "--kritarc",
                    str(root / "kritarc"),
                    "--diagnostics",
                    str(root / "missing.json"),
                    "--require-ok",
                ],
            ):
                self.assertEqual(1, _run_main_silently(module))

    def test_require_ok_returns_success_when_all_gates_pass(self):
        module = _load_module(
            "krita_bridge_acceptance_report_test",
            "acceptance_report.py",
        )
        install_plugin = _load_module(
            "krita_bridge_install_for_acceptance_test",
            "install_plugin.py",
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            pykrita_dir, kritarc_path, _profile = _install_current_profile(
                install_plugin,
                root,
            )
            diagnostics_path = root / "diagnostics.json"
            diagnostics_path.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "plugin": "nai_launcher_bridge",
                        "checks": [
                            {"name": "plugin_layout", "status": "pass"},
                            {"name": "launcher_discovery", "status": "pass"},
                            {"name": "active_document", "status": "pass"},
                            {"name": "canvas_png_round_trip", "status": "pass"},
                            {"name": "selection_and_masks", "status": "pass"},
                        ],
                    },
                ),
                encoding="utf-8",
            )
            evidence_path = root / "evidence.json"
            evidence_path.write_text(
                json.dumps(
                    {
                        key: {"passed": True, "note": "confirmed"}
                        for key in module.KNOWN_MANUAL_EVIDENCE_KEYS
                    },
                ),
                encoding="utf-8",
            )
            with patch.object(
                sys,
                "argv",
                [
                    "acceptance_report.py",
                    "--pykrita-dir",
                    str(pykrita_dir),
                    "--kritarc",
                    str(kritarc_path),
                    "--diagnostics",
                    str(diagnostics_path),
                    "--evidence-file",
                    str(evidence_path),
                    "--require-ok",
                ],
            ):
                self.assertEqual(0, _run_main_silently(module))

    def test_require_ok_rejects_bare_manual_evidence_flags(self):
        module = _load_module(
            "krita_bridge_acceptance_report_test",
            "acceptance_report.py",
        )
        install_plugin = _load_module(
            "krita_bridge_install_for_acceptance_test",
            "install_plugin.py",
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            pykrita_dir = root / "pykrita"
            plugin_dir = pykrita_dir / "nai_launcher_bridge"
            plugin_dir.mkdir(parents=True)
            (pykrita_dir / "nai_launcher_bridge.desktop").write_text(
                DESKTOP_MANIFEST_TEXT,
                encoding="utf-8",
            )
            for _check_name, relative_path in install_plugin.REQUIRED_PLUGIN_FILES:
                (plugin_dir / relative_path).write_text("", encoding="utf-8")
            kritarc_path = root / "kritarc"
            kritarc_path.write_text(
                "[python]\nenable_nai_launcher_bridge=true\n",
                encoding="utf-8",
            )
            diagnostics_path = root / "diagnostics.json"
            diagnostics_path.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "plugin": "nai_launcher_bridge",
                        "checks": [
                            {"name": "plugin_layout", "status": "pass"},
                            {"name": "launcher_discovery", "status": "pass"},
                            {"name": "active_document", "status": "pass"},
                            {"name": "canvas_png_round_trip", "status": "pass"},
                            {"name": "selection_and_masks", "status": "pass"},
                        ],
                    },
                ),
                encoding="utf-8",
            )
            evidence_flags = [
                "--evidence-plugin-manager-visible",
                "--evidence-docker-visible",
                "--evidence-launcher-settings-toggle",
                "--evidence-auto-discovery-connect",
                "--evidence-auth-failure-safe",
                "--evidence-img2img-e2e",
                "--evidence-inpaint-e2e",
                "--evidence-krita-cancel-e2e",
                "--evidence-no-selection-behavior",
                "--evidence-large-canvas-rejected",
                "--evidence-disconnect-generation-safe",
                "--evidence-preview-throttle",
                "--evidence-result-layer-aligned",
                "--evidence-launcher-history-recorded",
                "--evidence-novelai-token-launcher-only",
                "--evidence-bridge-rejects-unauthenticated",
                "--evidence-gallery-send-e2e",
                "--evidence-disabled-bridge-existing-flows",
            ]
            json_path = root / "acceptance.json"
            markdown_path = root / "acceptance.md"
            with patch.object(
                sys,
                "argv",
                [
                    "acceptance_report.py",
                    "--pykrita-dir",
                    str(pykrita_dir),
                    "--kritarc",
                    str(kritarc_path),
                    "--diagnostics",
                    str(diagnostics_path),
                    "--output-json",
                    str(json_path),
                    "--output-markdown",
                    str(markdown_path),
                    *evidence_flags,
                    "--require-ok",
                ],
            ):
                self.assertEqual(1, _run_main_silently(module))

            json_text = json_path.read_text(encoding="utf-8")
            markdown_text = markdown_path.read_text(encoding="utf-8")
            self.assertIn('"acceptance_ok": false', json_text)
            self.assertIn('"manual_evidence_notes"', json_text)
            self.assertIn("| manual_evidence_notes | fail |", markdown_text)

    def test_require_ok_reports_bare_manual_flags_when_other_gates_are_open(self):
        module = _load_module(
            "krita_bridge_acceptance_report_test",
            "acceptance_report.py",
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            json_path = root / "acceptance.json"
            markdown_path = root / "acceptance.md"
            with patch.object(
                sys,
                "argv",
                [
                    "acceptance_report.py",
                    "--pykrita-dir",
                    str(root / "pykrita"),
                    "--kritarc",
                    str(root / "kritarc"),
                    "--output-json",
                    str(json_path),
                    "--output-markdown",
                    str(markdown_path),
                    "--evidence-plugin-manager-visible",
                    "--require-ok",
                ],
            ):
                self.assertEqual(1, _run_main_silently(module))

            json_text = json_path.read_text(encoding="utf-8")
            markdown_text = markdown_path.read_text(encoding="utf-8")
            self.assertIn('"acceptance_ok": false', json_text)
            self.assertIn('"manual_evidence_notes"', json_text)
            self.assertIn("| manual_evidence_notes | fail |", markdown_text)

    def test_automation_evidence_is_attached_without_closing_manual_gates(self):
        module = _load_module(
            "krita_bridge_acceptance_report_test",
            "acceptance_report.py",
        )
        install_plugin = _load_module(
            "krita_bridge_install_for_acceptance_test",
            "install_plugin.py",
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            profile = install_plugin.check_profile(
                pykrita_dir=root / "pykrita",
                kritarc_path=root / "kritarc",
            )
            report = module.build_acceptance_report(
                profile=profile,
                diagnostics=None,
                diagnostics_path=root / "missing.json",
                automation_evidence={
                    "novelai_token_launcher_only": {
                        "note": "Dart bridge payload tests and package scan passed.",
                        "commands": [
                            "flutter test test/presentation/providers/krita/krita_bridge_service_test.dart",
                            "python3 -m unittest krita_plugin.tests.test_package_plugin",
                        ],
                    },
                    "bridge_rejects_unauthenticated": {
                        "note": "WebSocket server rejects unauthenticated messages.",
                    },
                },
            )

            by_name = {gate.name: gate for gate in report.gates}
            self.assertEqual("pending", by_name["novelai_token_launcher_only"].status)
            self.assertIn(
                "Automation: Dart bridge payload tests and package scan passed.",
                by_name["novelai_token_launcher_only"].evidence,
            )
            self.assertIn(
                "flutter test test/presentation/providers/krita/krita_bridge_service_test.dart",
                by_name["novelai_token_launcher_only"].evidence,
            )
            self.assertEqual("pending", by_name["bridge_rejects_unauthenticated"].status)
            self.assertIn(
                "Automation: WebSocket server rejects unauthenticated messages.",
                by_name["bridge_rejects_unauthenticated"].evidence,
            )


if __name__ == "__main__":
    unittest.main()
