import base64
import importlib.util
import json
import os
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


class DiscoveryPathTests(unittest.TestCase):
    """The plugin must look where the Launcher writes krita-bridge.json."""

    home = Path("/Users/alice")

    def _path(self, windows: bool, environ: dict) -> Path:
        with mock.patch.object(
            discovery, "_is_windows", return_value=windows
        ), mock.patch.dict(discovery.os.environ, environ, clear=True), mock.patch.object(
            discovery.Path, "home", return_value=self.home
        ):
            return discovery.discovery_file_path()

    def test_macos_reads_the_dot_nai_launcher_folder_in_home(self):
        self.assertEqual(
            self._path(False, {}),
            self.home / ".nai-launcher" / "krita-bridge.json",
        )

    def test_windows_reads_appdata(self):
        self.assertEqual(
            self._path(True, {"APPDATA": "C:/Users/alice/AppData/Roaming"}),
            Path("C:/Users/alice/AppData/Roaming") / "nai-launcher" / "krita-bridge.json",
        )

    def test_windows_without_appdata_keeps_the_roaming_fallback(self):
        self.assertEqual(
            self._path(True, {}),
            self.home / "AppData" / "Roaming" / "nai-launcher" / "krita-bridge.json",
        )

    def test_appdata_wins_on_every_platform_like_the_launcher(self):
        self.assertEqual(
            self._path(False, {"APPDATA": "/tmp/appdata"}),
            Path("/tmp/appdata") / "nai-launcher" / "krita-bridge.json",
        )


class DiscoveryFileTests(unittest.TestCase):
    """krita-bridge.json is read again only when its modification time changes."""

    def setUp(self):
        temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(temp_dir.cleanup)
        self.path = Path(temp_dir.name) / "krita-bridge.json"
        self.mtime_ns = 1_800_000_000 * 10**9
        self.reads = 0
        real_open = Path.open

        def counting_open(path, mode="r", *args, **kwargs):
            if "r" in mode and Path(path) == self.path:
                self.reads += 1
            return real_open(path, mode, *args, **kwargs)

        patcher = mock.patch.object(Path, "open", counting_open)
        patcher.start()
        self.addCleanup(patcher.stop)
        self.file = discovery.DiscoveryFile(self.path)

    def write(self, text=None, **data):
        self.path.write_text(
            json.dumps(data) if text is None else text,
            encoding="utf-8",
        )
        # Every write gets a later modification time, as when the Launcher writes it.
        self.mtime_ns += 10**9
        os.utime(self.path, ns=(self.mtime_ns, self.mtime_ns))

    def test_an_unchanged_file_is_not_read_again(self):
        self.write(port=52381, secret="first", version=1)

        self.assertTrue(self.file.refresh())
        for _ in range(3):
            self.assertFalse(self.file.refresh())

        self.assertEqual(self.file.current().secret, "first")
        self.assertEqual(self.reads, 1)

    def test_a_new_modification_time_reads_the_new_file(self):
        self.write(port=52381, secret="first", version=1)
        self.file.refresh()

        self.write(port=52382, secret="second", version=1)

        self.assertTrue(self.file.refresh())
        current = self.file.current()
        self.assertEqual((current.port, current.secret), (52382, "second"))
        self.assertEqual(self.reads, 2)

    def test_a_missing_file_is_looked_for_once_until_it_appears(self):
        self.assertFalse(self.file.refresh())
        self.assertFalse(self.file.refresh())
        with self.assertRaisesRegex(OSError, "krita-bridge.json"):
            self.file.current()
        self.assertEqual(self.reads, 1)

        self.write(port=52381, secret="first", version=1)

        self.assertTrue(self.file.refresh())
        self.assertEqual(self.file.current().port, 52381)
        self.assertEqual(self.reads, 2)

    def test_a_removed_file_is_not_a_new_version(self):
        self.write(port=52381, secret="first", version=1)
        self.file.refresh()

        self.path.unlink()

        self.assertFalse(self.file.refresh())
        with self.assertRaisesRegex(OSError, "No such file"):
            self.file.current()

    def test_a_read_that_failed_is_tried_again_without_counting_as_new(self):
        # A passing read error (another program holding the file open on
        # Windows, an I/O error) is not kept until the file changes.
        self.write(port=52381, secret="first", version=1)
        real_read = discovery.read_discovery_data
        failures = [PermissionError(13, "Permission denied")]
        calls = []

        def flaky_read(path):
            calls.append(path)
            if failures:
                raise failures.pop()
            return real_read(path)

        with mock.patch.object(
            discovery, "read_discovery_data", side_effect=flaky_read
        ):
            self.assertTrue(self.file.refresh())
            with self.assertRaisesRegex(PermissionError, "Permission denied"):
                self.file.current()
            self.assertFalse(self.file.refresh())  # the same file, read again
            self.assertEqual(self.file.current().secret, "first")
            self.assertFalse(self.file.refresh())  # read now: not again
        self.assertEqual(len(calls), 2)

    def test_broken_content_is_read_again_only_when_the_file_changes(self):
        self.write("{not json")

        self.assertTrue(self.file.refresh())
        for _ in range(3):
            self.assertFalse(self.file.refresh())
        with self.assertRaises(ValueError):
            self.file.current()
        self.assertEqual(self.reads, 1)

        self.write(port=52381, secret="fixed", version=1)
        self.assertTrue(self.file.refresh())
        self.assertEqual(self.file.current().secret, "fixed")

    def test_manual_retry_rechecks_invalid_json_with_the_same_timestamp(self):
        self.write("{partial")
        self.file.refresh()
        with self.assertRaises(ValueError):
            self.file.current()
        before = self.path.stat().st_mtime_ns
        self.write(port=52381, secret="complete", version=1)
        os.utime(self.path, ns=(before, before))
        self.assertFalse(self.file.refresh())
        self.assertFalse(self.file.refresh(force=True))
        self.assertEqual(self.file.current().secret, "complete")
        self.assertEqual(self.reads, 2)

    def test_manual_retry_rechecks_json_with_a_missing_secret(self):
        self.write(port=52381, version=1)
        self.file.refresh()
        with self.assertRaises(ValueError):
            self.file.current()
        old_mtime = self.path.stat().st_mtime_ns
        self.write(port=52381, secret="restored", version=1)
        os.utime(self.path, ns=(old_mtime, old_mtime))
        self.file.refresh(force=True)
        self.assertEqual(self.file.current().secret, "restored")

    def test_errors_read_as_they_did_with_load_discovery(self):
        # The docker shows "未找到 Launcher 桥接：<error>"; that text stays the same.
        cases = {
            "missing": None,
            "broken": "{not json",
            "no secret": json.dumps({"port": 52381, "version": 1}),
        }
        for name, text in cases.items():
            with self.subTest(name):
                if text is None:
                    if self.path.exists():
                        self.path.unlink()
                else:
                    self.write(text)
                with self.assertRaises(Exception) as before:
                    discovery.load_discovery(self.path)
                self.file.refresh()
                with self.assertRaises(Exception) as now:
                    self.file.current()
                self.assertEqual(str(now.exception), str(before.exception))

    def test_the_launcher_process_is_checked_on_every_use_without_reading_again(self):
        self.write(
            port=52381,
            secret="first",
            version=1,
            pid=4242,
            started_at="2026-10-30T08:00:00Z",
        )
        with mock.patch.object(
            discovery, "_process_started_at_matches", return_value=True
        ):
            with mock.patch.object(discovery, "_pid_is_alive", return_value=True):
                self.file.refresh()
                self.assertEqual(self.file.current().pid, 4242)
            with mock.patch.object(discovery, "_pid_is_alive", return_value=False):
                self.assertFalse(self.file.refresh())
                with self.assertRaisesRegex(ValueError, "stopped Launcher"):
                    self.file.current()
        self.assertEqual(self.reads, 1)

    def test_the_default_location_follows_the_platform(self):
        for windows in (False, True):
            with self.subTest(windows=windows), tempfile.TemporaryDirectory() as root:
                home = Path(root)
                app_data = home / "AppData" / "Roaming"
                environ = {"APPDATA": str(app_data)} if windows else {}
                folder = app_data / "nai-launcher" if windows else home / ".nai-launcher"
                folder.mkdir(parents=True)
                (folder / "krita-bridge.json").write_text(
                    json.dumps({"port": 52381, "secret": "here", "version": 1}),
                    encoding="utf-8",
                )
                with mock.patch.object(
                    discovery, "_is_windows", return_value=windows
                ), mock.patch.dict(
                    discovery.os.environ, environ, clear=True
                ), mock.patch.object(
                    discovery.Path, "home", return_value=home
                ):
                    located = discovery.DiscoveryFile()
                    self.assertTrue(located.refresh())
                    self.assertEqual(located.current().secret, "here")


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
