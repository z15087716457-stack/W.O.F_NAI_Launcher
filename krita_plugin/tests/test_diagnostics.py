import importlib.util
import json
import sys
import tempfile
import types
import unittest
from pathlib import Path

PLUGIN_ROOT = Path(__file__).resolve().parents[1] / "nai_launcher_bridge"


def _install_krita_stubs():
    pyqt5 = types.ModuleType("PyQt5")
    qtcore = types.ModuleType("PyQt5.QtCore")
    qtgui = types.ModuleType("PyQt5.QtGui")
    krita = types.ModuleType("krita")

    class _QByteArray(bytes):
        pass

    class _QBuffer:
        def open(self, *_args):
            return True

        def data(self):
            return b""

    class _QIODevice:
        WriteOnly = 1

    class _QImage:
        Format_Grayscale8 = 1
        Format_RGBA8888 = 2

        def loadFromData(self, *_args):
            return False

    class _InfoObject:
        pass

    class _Krita:
        @staticmethod
        def instance():
            return None

    qtcore.QByteArray = _QByteArray
    qtcore.QBuffer = _QBuffer
    qtcore.QIODevice = _QIODevice
    qtgui.QImage = _QImage
    krita.InfoObject = _InfoObject
    krita.Krita = _Krita

    sys.modules["PyQt5"] = pyqt5
    sys.modules["PyQt5.QtCore"] = qtcore
    sys.modules["PyQt5.QtGui"] = qtgui
    sys.modules["krita"] = krita


def _load_diagnostics():
    _install_krita_stubs()
    package = types.ModuleType("nai_launcher_bridge")
    package.__path__ = [str(PLUGIN_ROOT)]
    sys.modules["nai_launcher_bridge"] = package
    spec = importlib.util.spec_from_file_location(
        "nai_launcher_bridge.diagnostics",
        PLUGIN_ROOT / "diagnostics.py",
    )
    module = importlib.util.module_from_spec(spec)
    assert spec is not None and spec.loader is not None
    sys.modules["nai_launcher_bridge.diagnostics"] = module
    spec.loader.exec_module(module)
    return module


diagnostics = _load_diagnostics()


class DiagnosticsTests(unittest.TestCase):
    def test_run_diagnostics_reports_layout_without_krita_document(self):
        report = diagnostics.run_diagnostics(write_report=False)
        by_name = {check["name"]: check for check in report["checks"]}

        self.assertEqual(report["schema_version"], 1)
        self.assertEqual(report["plugin"], "nai_launcher_bridge")
        self.assertEqual(by_name["plugin_layout"]["status"], "pass")
        self.assertEqual(by_name["active_document"]["status"], "skip")
        self.assertIn("summary", report)

    def test_format_summary_includes_counts_and_path(self):
        text = diagnostics.format_summary(
            {
                "summary": {
                    "pass": 1,
                    "fail": 2,
                    "warning": 3,
                    "skip": 4,
                },
                "report_path": "C:/tmp/krita-bridge-diagnostics.json",
            }
        )

        self.assertIn("pass=1", text)
        self.assertIn("fail=2", text)
        self.assertIn("C:/tmp/krita-bridge-diagnostics.json", text)

    def test_discovery_report_exposes_secret_length_not_secret_value(self):
        original_path = diagnostics.discovery_file_path
        original_load = diagnostics.load_discovery
        secret = "session-secret-value"
        try:
            with tempfile.TemporaryDirectory() as temp_dir:
                path = Path(temp_dir) / "krita-bridge.json"
                path.write_text("{}", encoding="utf-8")
                diagnostics.discovery_file_path = lambda: path
                diagnostics.load_discovery = lambda _path: types.SimpleNamespace(
                    url="ws://127.0.0.1:52381/krita",
                    pid=12345,
                    version=1,
                    started_at="2026-05-10T00:00:00Z",
                    secret=secret,
                )

                report = diagnostics.run_diagnostics(write_report=False)

            by_name = {check["name"]: check for check in report["checks"]}
            discovery_check = by_name["launcher_discovery"]
            self.assertEqual(discovery_check["status"], "pass")
            self.assertEqual(discovery_check["secret_length"], len(secret))
            self.assertNotIn("secret", set(discovery_check) - {"secret_length"})
            self.assertNotIn(secret, json.dumps(report, ensure_ascii=False))
        finally:
            diagnostics.discovery_file_path = original_path
            diagnostics.load_discovery = original_load

    def test_selection_diagnostics_accepts_non_rectangular_selection_bounds(self):
        original_active_document = diagnostics.canvas_io.active_document
        original_selection_bounds = diagnostics.canvas_io.active_selection_bounds
        original_export_mask = diagnostics.canvas_io.export_inpaint_mask_png

        class FakeDocument:
            def width(self):
                return 128

            def height(self):
                return 96

        try:
            diagnostics.canvas_io.active_document = lambda: FakeDocument()
            diagnostics.canvas_io.active_selection_bounds = lambda: {
                "x": 10,
                "y": 12,
                "w": 32,
                "h": 24,
            }
            diagnostics.canvas_io.export_inpaint_mask_png = lambda: (
                (_ for _ in ()).throw(RuntimeError("mask unavailable"))
            )

            checks = []
            diagnostics._check_selection_and_masks(checks)

            self.assertEqual("selection_and_masks", checks[0]["name"])
            self.assertEqual("pass", checks[0]["status"])
            self.assertEqual(
                {"x": 10, "y": 12, "w": 32, "h": 24},
                checks[0]["selection_rect"],
            )
            self.assertEqual("pass", checks[0]["selection_status"])
            self.assertIn("selection bounds", checks[0]["detail"])
        finally:
            diagnostics.canvas_io.active_document = original_active_document
            diagnostics.canvas_io.active_selection_bounds = original_selection_bounds
            diagnostics.canvas_io.export_inpaint_mask_png = original_export_mask


if __name__ == "__main__":
    unittest.main()
