import importlib
import json
import os
import shutil
import sys
import tempfile
import types
import unittest
from pathlib import Path
from unittest import mock

PLUGIN_ROOT = Path(__file__).resolve().parents[1] / "nai_launcher_bridge"

# What the Launcher writes to krita-bridge.json (no pid, so no process check).
LAUNCHER_DISCOVERY = {"port": 52381, "secret": "session-secret", "version": 1}
PLATFORMS = ("macos", "windows")


class FakeSignal:
    def __init__(self):
        self._callbacks = []

    def connect(self, callback):
        self._callbacks.append(callback)

    def emit(self, *args):
        for callback in list(self._callbacks):
            callback(*args)


class FakeQObject:
    def __init__(self, *_args, **_kwargs):
        pass


class FakeClock:
    """Fake time for the stubbed QTimer: advance() fires due timers in order."""

    def __init__(self):
        self.reset()

    def reset(self):
        self.now = 0.0
        self.timers = []
        self.fired_at = []

    def advance(self, seconds):
        end = self.now + seconds
        while True:
            due = [timer for timer in self.timers if timer.started and timer.due <= end]
            if not due:
                break
            timer = min(due, key=lambda item: item.due)
            self.now = timer.due
            self.fired_at.append(self.now)
            timer.fire()
        self.now = end


CLOCK = FakeClock()


class FakeTimer:
    def __init__(self, *_args, **_kwargs):
        self.timeout = FakeSignal()
        self.started = False
        self.single_shot = False
        self.interval = None
        self.due = None
        CLOCK.timers.append(self)

    def setInterval(self, interval):
        self.interval = interval
        if self.started:  # Qt restarts a running timer with the new interval
            self.start()

    def setSingleShot(self, single_shot):
        self.single_shot = bool(single_shot)

    def start(self, *interval):
        if interval:
            self.interval = interval[0]
        self.started = True
        self.due = CLOCK.now + self.interval / 1000

    def stop(self):
        self.started = False

    def isActive(self):
        return self.started

    def fire(self):
        if self.single_shot:
            self.started = False
        else:
            self.due += self.interval / 1000
        self.timeout.emit()


class FakeFallbackSocket:
    instances = []

    def __init__(
        self,
        *,
        on_connected,
        on_text_message,
        on_disconnected,
        on_error,
    ):
        self.on_connected = on_connected
        self.on_text_message = on_text_message
        self.on_disconnected = on_disconnected
        self.on_error = on_error
        self.sent = []
        self.opened_url = None
        self.closed = False
        FakeFallbackSocket.instances.append(self)

    def open(self, url):
        self.opened_url = url
        self.on_connected()

    def send_text(self, text):
        self.sent.append(text)
        return True

    def close(self):
        self.closed = True


class LauncherFolder:
    """Where the Launcher writes krita-bridge.json, inside a temp folder.

    macOS: ~/.nai-launcher. Windows: %APPDATA%/nai-launcher. The platform is
    injected (_is_windows, APPDATA, home folder), so both paths run on any
    machine. `reads` counts how often the plugin opens the file.
    """

    def __init__(self, test, discovery, platform, pid_alive=None):
        root = Path(tempfile.mkdtemp(prefix="krita-bridge-test-"))
        test.addCleanup(shutil.rmtree, root, True)
        windows = platform == "windows"
        app_data = root / "AppData" / "Roaming"
        if windows:
            self.path = app_data / "nai-launcher" / "krita-bridge.json"
        else:
            self.path = root / ".nai-launcher" / "krita-bridge.json"
        self.reads = 0
        self._mtime_ns = 1_800_000_000 * 10**9
        real_open = Path.open
        folder = self

        def counting_open(path, mode="r", *args, **kwargs):
            if "r" in mode and Path(path) == folder.path:
                folder.reads += 1
            return real_open(path, mode, *args, **kwargs)

        environ = mock.patch.dict(os.environ)
        environ.start()
        test.addCleanup(environ.stop)
        os.environ.pop("APPDATA", None)
        if windows:
            os.environ["APPDATA"] = str(app_data)
        for patcher in (
            mock.patch.object(discovery, "_is_windows", return_value=windows),
            mock.patch.object(Path, "home", return_value=root),
            mock.patch.object(Path, "open", counting_open),
            mock.patch.object(
                discovery,
                "_pid_is_alive",
                side_effect=pid_alive or (lambda _pid: True),
            ),
            mock.patch.object(
                discovery, "_process_started_at_matches", return_value=True
            ),
        ):
            patcher.start()
            test.addCleanup(patcher.stop)

    def write(self, **data):
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with open(self.path, "w", encoding="utf-8") as handle:
            json.dump(data, handle)
        # Every write gets a later modification time, as when the Launcher writes it.
        self._mtime_ns += 10**9
        os.utime(self.path, ns=(self._mtime_ns, self._mtime_ns))

    def remove(self):
        self.path.unlink()


def _install_stubs():
    FakeFallbackSocket.instances.clear()
    CLOCK.reset()
    pyqt5 = types.ModuleType("PyQt5")
    qtcore = types.ModuleType("PyQt5.QtCore")

    qtcore.QObject = FakeQObject
    qtcore.QTimer = FakeTimer
    qtcore.QUrl = str
    qtcore.pyqtSignal = lambda *_args, **_kwargs: FakeSignal()

    sys.modules["PyQt5"] = pyqt5
    sys.modules["PyQt5.QtCore"] = qtcore
    sys.modules.pop("PyQt5.QtWebSockets", None)

    package = types.ModuleType("nai_launcher_bridge")
    package.__path__ = [str(PLUGIN_ROOT)]
    sys.modules["nai_launcher_bridge"] = package


def _load_bridge_client(
    test,
    platform="macos",
    discovery=LAUNCHER_DISCOVERY,
    pid_alive=None,
):
    """A fresh bridge_client on fake Qt and sockets.

    krita-bridge.json lives in a temp LauncherFolder; it is not written when
    discovery is None.
    """
    _install_stubs()
    for name in list(sys.modules):
        if name.startswith("nai_launcher_bridge.") and name != "nai_launcher_bridge":
            del sys.modules[name]

    module = importlib.import_module("nai_launcher_bridge.bridge_client")
    module.FallbackWebSocketClient = FakeFallbackSocket
    module.QWebSocket = None
    folder = LauncherFolder(
        test,
        sys.modules["nai_launcher_bridge.discovery"],
        platform,
        pid_alive,
    )
    if discovery is not None:
        folder.write(**discovery)
    return module, folder


def _pong(socket):
    socket.on_text_message('{"type":"pong","version":1}')


class FakeNativeSocket:
    instances = []

    def __init__(self):
        self.connected = FakeSignal()
        self.disconnected = FakeSignal()
        self.textMessageReceived = FakeSignal()
        self.error = FakeSignal()
        self.sent = []
        self.closed = False
        self.instances.append(self)

    def open(self, _url):
        self.connected.emit()

    def sendTextMessage(self, text):
        self.sent.append(text)

    def errorString(self):
        return 'fixture transport error'

    def close(self):
        self.closed = True
        self.disconnected.emit()

    def deleteLater(self):
        pass


class BridgeTransportOwnershipTests(unittest.TestCase):
    def connect(self, native):
        module, _folder = _load_bridge_client(self)
        if native:
            FakeNativeSocket.instances.clear()
            module.QWebSocket = FakeNativeSocket
        client = module.BridgeClient()
        statuses, messages, connected = [], [], []
        client.status_changed.connect(statuses.append)
        client.message_received.connect(messages.append)
        client.connected_changed.connect(connected.append)
        client.start()
        instances = FakeNativeSocket.instances if native else FakeFallbackSocket.instances
        return client, instances, statuses, messages, connected

    def emit_all(self, socket, native):
        if native:
            socket.connected.emit()
            socket.textMessageReceived.emit('{"type":"pong","version":99}')
            socket.textMessageReceived.emit('{"type":"progress","id":"old"}')
            socket.error.emit(1)
            socket.disconnected.emit()
        else:
            socket.on_connected()
            socket.on_text_message('{"type":"pong","version":99}')
            socket.on_text_message('{"type":"progress","id":"old"}')
            socket.on_error('old transport error')
            socket.on_disconnected()

    def pong(self, socket, native):
        text = '{"type":"pong","version":1}'
        if native:
            socket.textMessageReceived.emit(text)
        else:
            socket.on_text_message(text)

    def test_previous_transport_callbacks_do_not_touch_authenticated_replacement(self):
        for native in (False, True):
            with self.subTest(native=native):
                client, instances, statuses, messages, connected = self.connect(native)
                old = instances[-1]
                client._retry_timer.timeout.emit()
                current = instances[-1]
                self.assertIsNot(old, current)
                self.pong(current, native)
                before = (list(statuses), list(current.sent), list(connected))
                self.emit_all(old, native)
                self.assertTrue(client.is_connected)
                self.assertFalse(current.closed)
                self.assertEqual((statuses, current.sent, connected), before)
                self.assertEqual(messages, [])
                self.assertTrue(client.send_text('current message'))

    def test_stop_retires_all_callbacks_including_late_pong(self):
        for native in (False, True):
            with self.subTest(native=native):
                client, instances, statuses, messages, connected = self.connect(native)
                old = instances[-1]
                self.pong(old, native)
                client.stop()
                before = (list(statuses), list(connected))
                self.emit_all(old, native)
                self.pong(old, native)
                self.assertFalse(client.is_connected)
                self.assertEqual((statuses, connected), before)
                self.assertEqual(messages, [])

    def test_current_transport_disconnect_still_disables_sending(self):
        for native in (False, True):
            with self.subTest(native=native):
                client, instances, _, _, connected = self.connect(native)
                current = instances[-1]
                self.pong(current, native)
                if native:
                    current.disconnected.emit()
                else:
                    current.on_disconnected()
                self.assertFalse(client.is_connected)
                self.assertFalse(client.send_text('not sent'))
                self.assertEqual(connected, [True, False])


class BridgeClientFallbackTests(unittest.TestCase):
    def test_fallback_connection_uses_signals_for_handshake_and_messages(self):
        bridge_client, _folder = _load_bridge_client(self)
        connected = []
        received = []

        client = bridge_client.BridgeClient()
        client.connected_changed.connect(connected.append)
        client.message_received.connect(received.append)

        client.connect_to_launcher()

        socket = FakeFallbackSocket.instances[-1]
        self.assertEqual(socket.opened_url, "ws://127.0.0.1:52381/krita")
        self.assertEqual(len(socket.sent), 1)
        self.assertEqual(
            json.loads(socket.sent[0]),
            {"type": "ping", "version": 1, "secret": "session-secret"},
        )

        socket.on_text_message('{"type":"pong","version":1}')

        self.assertTrue(client.is_connected)
        self.assertEqual(connected, [True])

        socket.on_text_message('{"type":"progress","id":"img-1","progress":0.5}')

        self.assertEqual(
            received,
            [{"type": "progress", "id": "img-1", "progress": 0.5}],
        )

    def test_auth_failed_error_during_handshake_stays_disconnected(self):
        bridge_client, _folder = _load_bridge_client(self)
        connected = []
        received = []
        statuses = []

        client = bridge_client.BridgeClient()
        client.connected_changed.connect(connected.append)
        client.message_received.connect(received.append)
        client.status_changed.connect(statuses.append)

        client.connect_to_launcher()
        socket = FakeFallbackSocket.instances[-1]

        socket.on_text_message(
            '{"type":"error","code":"auth_failed","message":"Bridge authentication failed"}'
        )

        self.assertFalse(client.is_connected)
        self.assertEqual(received, [])
        self.assertTrue(socket.closed)
        self.assertIn(False, connected)
        self.assertTrue(any("认证失败" in status for status in statuses))

    def test_auth_failed_status_is_not_overwritten_by_followup_disconnect(self):
        bridge_client, _folder = _load_bridge_client(self)
        statuses = []

        client = bridge_client.BridgeClient()
        client.status_changed.connect(statuses.append)

        client.connect_to_launcher()
        socket = FakeFallbackSocket.instances[-1]

        socket.on_text_message(
            '{"type":"error","code":"auth_failed","message":"Bridge authentication failed"}'
        )
        socket.on_disconnected()

        self.assertIn("认证失败", statuses[-1])
        self.assertNotEqual(statuses[-1], "已断开与 NAI Launcher 的连接")

    def test_start_retries_after_five_seconds_when_launcher_is_missing(self):
        bridge_client, _folder = _load_bridge_client(self, discovery=None)
        statuses = []

        client = bridge_client.BridgeClient()
        client.status_changed.connect(statuses.append)

        client.start()

        self.assertTrue(client._retry_timer.started)
        self.assertEqual(client._retry_timer.interval, 5000)
        self.assertTrue(any("未找到 Launcher 桥接" in status for status in statuses))

        client._retry_timer.timeout.emit()

        missing_statuses = [
            status for status in statuses if "未找到 Launcher 桥接" in status
        ]
        self.assertEqual(len(missing_statuses), 2)


class RetryScheduleTests(unittest.TestCase):
    """How often the plugin wakes up, reads krita-bridge.json and dials Launcher.

    Launcher never answers in these tests unless a test sends the pong. Times
    are seconds since the docker started.
    """

    def start(self, platform, discovery=LAUNCHER_DISCOVERY, pid_alive=None):
        module, folder = _load_bridge_client(self, platform, discovery, pid_alive)
        client = module.BridgeClient()
        self.statuses = []
        client.status_changed.connect(self.statuses.append)
        client.start()
        return client, folder

    def dialled(self):
        return [socket.opened_url for socket in FakeFallbackSocket.instances]

    def test_without_launcher_it_backs_off_to_every_30_s_and_reads_the_file_once(self):
        for platform in PLATFORMS:
            with self.subTest(platform=platform):
                _client, folder = self.start(platform, discovery=None)
                CLOCK.advance(3600)
                self.assertEqual(
                    {
                        "first checks": CLOCK.fired_at[:6],
                        "wakeups in an hour": len(CLOCK.fired_at),
                        "reads": folder.reads,
                        "dialled": self.dialled(),
                    },
                    {
                        "first checks": [5, 15, 35, 65, 95, 125],
                        "wakeups in an hour": 121,
                        "reads": 1,
                        "dialled": [],
                    },
                )
                self.assertIn("未找到 Launcher 桥接", self.statuses[-1])
                self.assertIn("krita-bridge.json", self.statuses[-1])

    def test_a_file_written_meanwhile_is_dialled_at_the_next_check_and_backoff_restarts(self):
        for platform in PLATFORMS:
            with self.subTest(platform=platform):
                _client, folder = self.start(platform, discovery=None)
                CLOCK.advance(100)  # checked at 5, 15, 35, 65 and 95 s
                folder.write(port=52390, secret="turned-on", version=1)
                CLOCK.advance(120)
                self.assertEqual(
                    {
                        "checks": CLOCK.fired_at[5:],
                        "reads": folder.reads,
                        "dialled": self.dialled(),
                    },
                    {
                        "checks": [125, 130, 140, 160, 190, 220],
                        "reads": 2,
                        "dialled": ["ws://127.0.0.1:52390/krita"] * 6,
                    },
                )

    def test_a_rewritten_file_is_read_and_dialled_at_the_next_check(self):
        for platform in PLATFORMS:
            with self.subTest(platform=platform):
                _client, folder = self.start(platform)
                CLOCK.advance(100)  # dialled at 0, 5, 15, 35, 65 and 95 s
                folder.write(port=52391, secret="regenerated", version=1)
                CLOCK.advance(30)
                last = FakeFallbackSocket.instances[-1]
                self.assertEqual(
                    {
                        "checks": CLOCK.fired_at[5:],
                        "reads": folder.reads,
                        "dialled": last.opened_url,
                        "secret": json.loads(last.sent[0])["secret"],
                    },
                    {
                        "checks": [125, 130],
                        "reads": 2,
                        "dialled": "ws://127.0.0.1:52391/krita",
                        "secret": "regenerated",
                    },
                )

    def test_connected_it_no_longer_wakes_up(self):
        for platform in PLATFORMS:
            with self.subTest(platform=platform):
                client, folder = self.start(platform)
                _pong(FakeFallbackSocket.instances[-1])
                CLOCK.advance(3600)
                self.assertTrue(client.is_connected)
                self.assertEqual(
                    {
                        "wakeups in an hour": len(CLOCK.fired_at),
                        "reads": folder.reads,
                        "dialled": len(self.dialled()),
                    },
                    {"wakeups in an hour": 0, "reads": 1, "dialled": 1},
                )

    def test_after_a_disconnect_it_retries_after_5_10_20_and_30_s(self):
        for platform in PLATFORMS:
            with self.subTest(platform=platform):
                client, folder = self.start(platform)
                _pong(FakeFallbackSocket.instances[-1])
                CLOCK.advance(600)
                folder.remove()  # the bridge is turned off in Launcher ...
                FakeFallbackSocket.instances[-1].on_disconnected()  # ... which hangs up
                CLOCK.advance(65)
                self.assertFalse(client.is_connected)
                self.assertIn("未找到 Launcher 桥接", self.statuses[-1])
                folder.write(port=52392, secret="back-on", version=1)
                CLOCK.advance(30)
                self.assertEqual(
                    {
                        "checks": CLOCK.fired_at,
                        "reads": folder.reads,
                        "dialled": self.dialled(),
                    },
                    {
                        "checks": [605, 615, 635, 665, 695],
                        "reads": 3,
                        "dialled": [
                            "ws://127.0.0.1:52381/krita",
                            "ws://127.0.0.1:52392/krita",
                        ],
                    },
                )

    def test_a_launcher_that_quit_without_removing_its_file_is_not_dialled_again(self):
        for platform in PLATFORMS:
            with self.subTest(platform=platform):
                alive = [True]
                _client, folder = self.start(
                    platform,
                    discovery=dict(
                        LAUNCHER_DISCOVERY,
                        pid=4242,
                        started_at="2026-10-30T08:00:00Z",
                    ),
                    pid_alive=lambda _pid: alive[0],
                )
                _pong(FakeFallbackSocket.instances[-1])
                alive[0] = False  # Launcher crashed; krita-bridge.json stays behind
                FakeFallbackSocket.instances[-1].on_disconnected()
                CLOCK.advance(65)
                self.assertEqual(
                    {
                        "checks": CLOCK.fired_at,
                        "reads": folder.reads,
                        "dialled": len(self.dialled()),
                    },
                    {"checks": [5, 15, 35, 65], "reads": 1, "dialled": 1},
                )
                self.assertIn("stopped Launcher", self.statuses[-1])

    def test_nowhere_to_look_for_the_file_is_shown_and_retried(self):
        for platform in PLATFORMS:
            with self.subTest(platform=platform):
                module, _folder = _load_bridge_client(self, platform, discovery=None)
                discovery = sys.modules["nai_launcher_bridge.discovery"]
                with mock.patch.object(
                    discovery,
                    "discovery_file_path",
                    side_effect=RuntimeError("Could not determine home directory."),
                ):
                    client = module.BridgeClient()
                    statuses = []
                    client.status_changed.connect(statuses.append)
                    client.start()
                    CLOCK.advance(15)
                self.assertEqual(CLOCK.fired_at, [5, 15])
                self.assertEqual(
                    statuses[-1],
                    "未找到 Launcher 桥接：Could not determine home directory.",
                )

    def test_connect_button_reads_a_new_file_and_dials_at_once(self):
        for platform in PLATFORMS:
            with self.subTest(platform=platform):
                client, folder = self.start(platform, discovery=None)
                CLOCK.advance(100)
                folder.write(**LAUNCHER_DISCOVERY)
                client.connect_to_launcher()  # Connect, between two checks
                self.assertEqual(self.dialled(), ["ws://127.0.0.1:52381/krita"])
                _pong(FakeFallbackSocket.instances[-1])
                CLOCK.advance(3600)
                self.assertTrue(client.is_connected)
                self.assertEqual(CLOCK.fired_at, [5, 15, 35, 65, 95])

    def test_connect_button_leaves_the_retry_schedule_alone(self):
        for platform in PLATFORMS:
            with self.subTest(platform=platform):
                client, folder = self.start(platform, discovery=None)
                for _ in range(3):  # Connect at 1, 2 and 3 s, Launcher still off
                    CLOCK.advance(1)
                    client.connect_to_launcher()
                CLOCK.advance(1)
                folder.write(**LAUNCHER_DISCOVERY)  # bridge turned on at 4 s
                CLOCK.advance(1)
                self.assertEqual(
                    {"checks": CLOCK.fired_at, "dialled": self.dialled()},
                    {"checks": [5], "dialled": ["ws://127.0.0.1:52381/krita"]},
                )

    def test_connect_button_while_backing_off_keeps_the_next_check(self):
        for platform in PLATFORMS:
            with self.subTest(platform=platform):
                client, folder = self.start(platform, discovery=None)
                CLOCK.advance(70)  # checked at 5, 15, 35 and 65 s; next at 95 s
                for _ in range(5):
                    CLOCK.advance(4)
                    client.connect_to_launcher()
                CLOCK.advance(100)
                self.assertEqual(
                    {"checks": CLOCK.fired_at, "reads": folder.reads},
                    {"checks": [5, 15, 35, 65, 95, 125, 155, 185], "reads": 1},
                )

    def test_a_read_that_failed_once_is_tried_again_at_the_next_check(self):
        for platform in PLATFORMS:
            with self.subTest(platform=platform):
                module, folder = _load_bridge_client(self, platform)
                discovery = sys.modules["nai_launcher_bridge.discovery"]
                real_read = discovery.read_discovery_data
                # e.g. another program had krita-bridge.json open exclusively
                failures = [PermissionError(13, "Permission denied")]

                def flaky_read(path):
                    if failures:
                        raise failures.pop()
                    return real_read(path)

                with mock.patch.object(
                    discovery, "read_discovery_data", side_effect=flaky_read
                ):
                    client = module.BridgeClient()
                    statuses = []
                    client.status_changed.connect(statuses.append)
                    client.start()
                    self.assertIn("Permission denied", statuses[-1])
                    CLOCK.advance(5)
                self.assertEqual(CLOCK.fired_at, [5])
                self.assertEqual(self.dialled(), ["ws://127.0.0.1:52381/krita"])


if __name__ == "__main__":
    unittest.main()
