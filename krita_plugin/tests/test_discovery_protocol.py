import base64
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

PLUGIN_ROOT = Path(__file__).resolve().parents[1] / "nai_launcher_bridge"


def _load_module(name: str, file_name: str):
    spec = importlib.util.spec_from_file_location(name, PLUGIN_ROOT / file_name)
    module = importlib.util.module_from_spec(spec)
    assert spec is not None and spec.loader is not None
    spec.loader.exec_module(module)
    return module


def _write_discovery_file(path: Path, **data):
    path.write_text(json.dumps(data), encoding="utf-8")


discovery = _load_module("krita_bridge_discovery_test", "discovery.py")
protocol = _load_module("krita_bridge_protocol_test", "protocol.py")


class DiscoveryTests(unittest.TestCase):
    def test_load_discovery_without_pid_uses_loopback_url(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "krita-bridge.json"
            _write_discovery_file(
                path,
                port=52381,
                version=1,
                secret="session-secret",
            )

            result = discovery.load_discovery(path)

            self.assertEqual(result.url, "ws://127.0.0.1:52381/krita")
            self.assertEqual(result.secret, "session-secret")
            self.assertIsNone(result.pid)
            self.assertIsNone(result.started_at)

    def test_load_discovery_rejects_missing_secret(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "krita-bridge.json"
            _write_discovery_file(
                path,
                port=52381,
                pid=12345,
                version=1,
                started_at="2026-05-07T10:30:00.000Z",
            )

            with self.assertRaisesRegex(ValueError, "missing secret"):
                discovery.load_discovery(path)

    def test_load_discovery_rejects_empty_secret(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "krita-bridge.json"
            _write_discovery_file(
                path,
                port=52381,
                version=1,
                secret="",
            )

            with self.assertRaisesRegex(ValueError, "empty secret"):
                discovery.load_discovery(path)

    def test_load_discovery_rejects_stopped_launcher_pid(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "krita-bridge.json"
            _write_discovery_file(
                path,
                port=52381,
                pid=12345,
                version=1,
                secret="session-secret",
                started_at="2026-05-07T10:30:00.000Z",
            )

            with mock.patch.object(discovery, "_pid_is_alive", return_value=False):
                with mock.patch.object(
                    discovery,
                    "_process_started_at_matches",
                    return_value=True,
                    create=True,
                ) as started_at_matches:
                    with self.assertRaisesRegex(ValueError, "stopped Launcher"):
                        discovery.load_discovery(path)

            started_at_matches.assert_not_called()

    def test_load_discovery_rejects_live_pid_without_started_at(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "krita-bridge.json"
            _write_discovery_file(
                path,
                port=52381,
                pid=12345,
                version=1,
                secret="session-secret",
            )

            with mock.patch.object(discovery, "_pid_is_alive", return_value=True):
                with mock.patch.object(
                    discovery,
                    "_process_started_at_matches",
                    return_value=True,
                    create=True,
                ) as started_at_matches:
                    with self.assertRaisesRegex(ValueError, "missing start time"):
                        discovery.load_discovery(path)

            started_at_matches.assert_not_called()

    def test_load_discovery_rejects_started_at_mismatch(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "krita-bridge.json"
            _write_discovery_file(
                path,
                port=52381,
                pid=12345,
                version=1,
                secret="session-secret",
                started_at="2026-05-07T10:30:00.000Z",
            )

            with mock.patch.object(discovery, "_pid_is_alive", return_value=True):
                with mock.patch.object(
                    discovery,
                    "_process_started_at_matches",
                    return_value=False,
                    create=True,
                ):
                    with self.assertRaisesRegex(ValueError, "start time"):
                        discovery.load_discovery(path)

    def test_load_discovery_accepts_live_pid_and_matching_started_at(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "krita-bridge.json"
            _write_discovery_file(
                path,
                port=52381,
                pid=12345,
                version=1,
                secret="session-secret",
                started_at="2026-05-07T10:30:00.000Z",
            )

            with mock.patch.object(discovery, "_pid_is_alive", return_value=True):
                with mock.patch.object(
                    discovery,
                    "_process_started_at_matches",
                    return_value=True,
                    create=True,
                ):
                    result = discovery.load_discovery(path)

            self.assertEqual(result.port, 52381)
            self.assertEqual(result.secret, "session-secret")
            self.assertEqual(result.pid, 12345)
            self.assertEqual(result.version, 1)
            self.assertEqual(result.started_at, "2026-05-07T10:30:00.000Z")


class ProtocolTests(unittest.TestCase):
    def test_encode_get_params_and_cancel_use_request_ids(self):
        params = json.loads(protocol.encode_get_params("params-1"))
        cancel = json.loads(protocol.encode_cancel("img-1"))

        self.assertEqual(params, {"type": "get_params", "id": "params-1"})
        self.assertEqual(cancel, {"type": "cancel", "id": "img-1"})

    def test_encode_img2img_includes_image_and_controls(self):
        text = protocol.encode_img2img(
            request_id="img-1",
            image_png=b"image",
            prompt="cat",
            negative_prompt="lowres",
            strength=0.35,
            noise=0.2,
        )

        payload = json.loads(text)

        self.assertEqual(payload["type"], "img2img")
        self.assertEqual(payload["id"], "img-1")
        self.assertEqual(base64.b64decode(payload["image"]), b"image")
        self.assertEqual(payload["prompt"], "cat")
        self.assertEqual(payload["negative_prompt"], "lowres")
        self.assertEqual(payload["strength"], 0.35)
        self.assertEqual(payload["noise"], 0.2)

    def test_pong_version_error_accepts_matching_launcher_version(self):
        self.assertIsNone(
            protocol.pong_version_error(
                {"type": "pong", "version": protocol.PROTOCOL_VERSION}
            )
        )

    def test_pong_version_error_reports_supported_launcher_versions(self):
        error = protocol.pong_version_error(
            {"type": "pong", "version": 999, "supported_versions": [1]}
        )

        self.assertIsNotNone(error)
        self.assertIn("协议版本不兼容", error)
        self.assertIn("Launcher: 999", error)
        self.assertIn("插件: 1", error)
        self.assertIn("支持: 1", error)

    def test_encode_inpaint_includes_canvas_mask_and_controls(self):
        text = protocol.encode_inpaint(
            request_id="req-1",
            image_png=b"image",
            mask_png=b"mask",
            prompt="1girl",
            negative_prompt="bad anatomy",
            strength=0.7,
            noise=0.1,
            inpaint_strength=0.9,
        )

        payload = json.loads(text)

        self.assertEqual(payload["type"], "inpaint")
        self.assertEqual(payload["id"], "req-1")
        self.assertEqual(base64.b64decode(payload["image"]), b"image")
        self.assertEqual(base64.b64decode(payload["mask"]), b"mask")
        self.assertEqual(payload["prompt"], "1girl")
        self.assertEqual(payload["negative_prompt"], "bad anatomy")
        self.assertEqual(payload["strength"], 0.7)
        self.assertEqual(payload["noise"], 0.1)
        self.assertEqual(payload["inpaint_strength"], 0.9)
        self.assertNotIn("focused_inpaint", payload)
        self.assertNotIn("selection_rect", payload)
        self.assertNotIn("minimum_context_pixels", payload)

    def test_decode_image_field_reads_base64_image(self):
        data = protocol.decode_image_field(
            {"image": base64.b64encode(b"png").decode("ascii")},
            "image",
        )

        self.assertEqual(data, b"png")


if __name__ == "__main__":
    unittest.main()
