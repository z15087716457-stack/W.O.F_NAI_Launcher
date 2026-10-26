import importlib
import json
import sys
import types
import unittest
from pathlib import Path

PLUGIN_ROOT = Path(__file__).resolve().parents[1] / "nai_launcher_bridge"


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


class FakeTimer:
    def __init__(self, *_args, **_kwargs):
        self.timeout = FakeSignal()
        self.started = False

    def setInterval(self, interval):
        self.interval = interval

    def start(self):
        self.started = True

    def stop(self):
        self.started = False


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


def _install_stubs():
    FakeFallbackSocket.instances.clear()
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


def _load_bridge_client():
    _install_stubs()
    for name in list(sys.modules):
        if name.startswith("nai_launcher_bridge.") and name != "nai_launcher_bridge":
            del sys.modules[name]

    module = importlib.import_module("nai_launcher_bridge.bridge_client")
    module.FallbackWebSocketClient = FakeFallbackSocket
    module.QWebSocket = None
    module.load_discovery = lambda: module.BridgeDiscovery(
        port=52381,
        secret="session-secret",
        pid=12345,
        version=1,
        started_at="2026-05-10T00:00:00Z",
    )
    return module


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
        module = _load_bridge_client()
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
        bridge_client = _load_bridge_client()
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
        bridge_client = _load_bridge_client()
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
        bridge_client = _load_bridge_client()
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

    def test_start_retries_every_five_seconds_when_launcher_is_missing(self):
        bridge_client = _load_bridge_client()
        statuses = []
        bridge_client.load_discovery = lambda: (_ for _ in ()).throw(
            FileNotFoundError("krita-bridge.json")
        )

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


if __name__ == "__main__":
    unittest.main()
