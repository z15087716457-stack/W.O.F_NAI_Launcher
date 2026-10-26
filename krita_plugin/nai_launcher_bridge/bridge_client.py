from typing import Any, Dict, Optional

from PyQt5.QtCore import QObject, QTimer, QUrl, pyqtSignal

try:
    from PyQt5.QtWebSockets import QWebSocket
except ImportError:
    QWebSocket = None

from .discovery import BridgeDiscovery, load_discovery
from .fallback_websocket import FallbackWebSocketClient
from .protocol import decode_message, encode_ping, pong_version_error


class BridgeClient(QObject):
    connected_changed = pyqtSignal(bool)
    status_changed = pyqtSignal(str)
    message_received = pyqtSignal(object)
    _fallback_connected = pyqtSignal(int)
    _fallback_disconnected = pyqtSignal(int)
    _fallback_text_message = pyqtSignal(int, str)
    _fallback_error = pyqtSignal(int, str)

    def __init__(self, parent: Optional[QObject] = None) -> None:
        super().__init__(parent)
        self._socket: Optional[QWebSocket] = None
        self._fallback_socket: Optional[FallbackWebSocketClient] = None
        self._discovery: Optional[BridgeDiscovery] = None
        self._authenticated = False
        self._connection_revision = 0
        self._retry_timer = QTimer(self)
        self._retry_timer.setInterval(5000)
        self._retry_timer.timeout.connect(self.connect_to_launcher)
        self._fallback_connected.connect(self._on_connected)
        self._fallback_disconnected.connect(self._on_disconnected)
        self._fallback_text_message.connect(self._on_text_message)
        self._fallback_error.connect(self._on_fallback_error)

    @property
    def is_connected(self) -> bool:
        return self._authenticated

    def start(self) -> None:
        self.connect_to_launcher()
        self._retry_timer.start()

    def stop(self) -> None:
        self._retry_timer.stop()
        self._reset_socket()
        self.connected_changed.emit(False)

    def connect_to_launcher(self) -> None:
        if self._authenticated:
            return
        try:
            self._discovery = load_discovery()
        except Exception as error:
            self.status_changed.emit(f"未找到 Launcher 桥接：{error}")
            return
        self._reset_socket()
        if QWebSocket is None:
            self._connect_with_fallback()
            return

        revision = self._connection_revision
        self._socket = QWebSocket()
        self._socket.connected.connect(lambda: self._on_connected(revision))
        self._socket.disconnected.connect(lambda: self._on_disconnected(revision))
        self._socket.textMessageReceived.connect(
            lambda text: self._on_text_message(revision, text))
        self._socket.error.connect(
            lambda error: self._on_socket_error(revision, error))
        self.status_changed.emit("正在连接 NAI Launcher...")
        self._socket.open(QUrl(self._discovery.url))

    def send_text(self, text: str) -> bool:
        if not self._authenticated:
            self.status_changed.emit("尚未连接 NAI Launcher")
            return False
        if self._socket is not None:
            self._socket.sendTextMessage(text)
            return True
        if self._fallback_socket is not None:
            return self._fallback_socket.send_text(text)
        self.status_changed.emit("尚未连接 NAI Launcher")
        return False

    def _connect_with_fallback(self) -> None:
        if self._discovery is None:
            return
        revision = self._connection_revision
        self._fallback_socket = FallbackWebSocketClient(
            on_connected=lambda: self._fallback_connected.emit(revision),
            on_text_message=lambda text: self._fallback_text_message.emit(revision, text),
            on_disconnected=lambda: self._fallback_disconnected.emit(revision),
            on_error=lambda text: self._fallback_error.emit(revision, text),
        )
        self.status_changed.emit(
            "当前 Krita 缺少 PyQt5.QtWebSockets，正在使用内置 WebSocket 客户端..."
        )
        self._fallback_socket.open(self._discovery.url)

    def _send_raw_text(self, text: str) -> bool:
        if self._socket is not None:
            self._socket.sendTextMessage(text)
            return True
        if self._fallback_socket is not None:
            return self._fallback_socket.send_text(text)
        return False

    def _on_connected(self, revision: int) -> None:
        if revision != self._connection_revision or self._discovery is None:
            return
        self._send_raw_text(encode_ping(self._discovery.secret))

    def _on_disconnected(self, revision: int) -> None:
        if revision != self._connection_revision:
            return
        was_authenticated = self._authenticated
        self._authenticated = False
        if was_authenticated:
            self.connected_changed.emit(False)
        self.status_changed.emit("已断开与 NAI Launcher 的连接")

    def _on_text_message(self, revision: int, text: str) -> None:
        if revision != self._connection_revision:
            return
        try:
            message: Dict[str, Any] = decode_message(text)
        except Exception as error:
            self.status_changed.emit(f"Launcher 消息无效：{error}")
            return

        if message.get("type") == "pong":
            version_error = pong_version_error(message)
            if version_error is not None:
                self._reset_socket()
                self.connected_changed.emit(False)
                self.status_changed.emit(version_error)
                return

            self._authenticated = True
            self.connected_changed.emit(True)
            self.status_changed.emit("已连接 NAI Launcher")
            return

        if not self._authenticated and message.get("type") == "error":
            self._reset_socket()
            self.connected_changed.emit(False)
            self.status_changed.emit(self._handshake_error_text(message))
            return

        self.message_received.emit(message)

    def _on_socket_error(self, revision: int, _error_code: object) -> None:
        if revision != self._connection_revision or self._socket is None:
            return
        self.status_changed.emit(self._socket.errorString())

    def _on_fallback_error(self, revision: int, text: str) -> None:
        if revision == self._connection_revision:
            self.status_changed.emit(text)

    def _reset_socket(self) -> None:
        self._connection_revision += 1
        self._authenticated = False
        socket, fallback = self._socket, self._fallback_socket
        self._socket = None
        self._fallback_socket = None
        if socket is not None:
            socket.close()
            socket.deleteLater()
        if fallback is not None:
            fallback.close()

    def _handshake_error_text(self, message: Dict[str, Any]) -> str:
        code = str(message.get("code") or "")
        if code == "auth_failed":
            return "桥接认证失败，请在 Launcher 中重生成会话后重连"
        detail = str(message.get("message") or "未知错误")
        return f"桥接握手失败：{detail}"
