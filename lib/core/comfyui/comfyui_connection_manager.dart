import 'dart:async';

import 'package:uuid/uuid.dart';

import '../services/app_visibility.dart';
import '../utils/app_logger.dart';
import 'comfyui_api_service.dart';
import 'comfyui_models.dart';
import 'comfyui_url_utils.dart';
import 'comfyui_websocket_service.dart';

/// ComfyUI 连接管理器
///
/// 管理与 ComfyUI 服务器的连接生命周期，包括：
/// - HTTP API 服务实例
/// - WebSocket 进度服务实例
/// - 连接状态追踪
/// - 心跳检测（主窗口藏起来时暂停，显示时先查一次再继续）
class ComfyUIConnectionManager {
  static const String _tag = 'ComfyUI-Conn';

  String _serverUrl;
  final String clientId;

  ComfyUIApiService? _apiService;
  ComfyUIWebSocketService? _wsService;
  Timer? _heartbeatTimer;
  int _connectionRevision = 0;

  final _statusController =
      StreamController<ComfyUIConnectionStatus>.broadcast();

  ComfyUIConnectionStatus _status = ComfyUIConnectionStatus.disconnected;

  ComfyUIConnectionStatus get status => _status;
  Stream<ComfyUIConnectionStatus> get statusStream => _statusController.stream;
  String get serverUrl => _serverUrl;

  ComfyUIApiService? get api => _apiService;
  ComfyUIWebSocketService? get ws => _wsService;

  ComfyUIConnectionManager({
    String serverUrl = 'http://127.0.0.1:8188',
    this.heartbeatInterval = const Duration(seconds: 30),
    AppVisibility? visibility,
  }) : _serverUrl = normalizeComfyUIBaseUrl(serverUrl),
       clientId = const Uuid().v4(),
       _visibility = visibility ?? AppVisibility.instance {
    _visibility.addListener(_visibilityChanged);
  }

  final Duration heartbeatInterval;
  final AppVisibility _visibility;

  /// 更新服务器地址（需要重新连接）
  void updateServerUrl(String url) {
    final normalizedUrl = normalizeComfyUIBaseUrl(url);
    if (normalizedUrl == _serverUrl) return;
    _serverUrl = normalizedUrl;
    disconnect();
  }

  /// 连接到 ComfyUI
  Future<bool> connect() async {
    if (_statusController.isClosed ||
        _status == ComfyUIConnectionStatus.connecting) {
      return false;
    }
    disconnect();
    final revision = _connectionRevision;
    _setStatus(ComfyUIConnectionStatus.connecting);

    try {
      final api = ComfyUIApiService(baseUrl: _serverUrl);
      _apiService = api;

      final ok = await api.testConnection();
      if (revision != _connectionRevision) return false;
      if (!ok) {
        _setStatus(ComfyUIConnectionStatus.error);
        return false;
      }

      final ws = ComfyUIWebSocketService(
        baseUrl: _serverUrl,
        clientId: clientId,
      );
      _wsService = ws;
      await ws.connect();
      if (revision != _connectionRevision) return false;

      _startHeartbeat();
      _setStatus(ComfyUIConnectionStatus.connected);
      AppLogger.i('Connected to ComfyUI at $_serverUrl', _tag);
      return true;
    } catch (e) {
      if (revision != _connectionRevision) return false;
      AppLogger.e('Failed to connect: $e', _tag);
      _setStatus(ComfyUIConnectionStatus.error);
      return false;
    }
  }

  /// 断开连接
  void disconnect() {
    if (_statusController.isClosed) return;
    _connectionRevision++;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _wsService?.dispose();
    _wsService = null;
    _apiService?.dispose();
    _apiService = null;
    _setStatus(ComfyUIConnectionStatus.disconnected);
    AppLogger.i('Disconnected from ComfyUI', _tag);
  }

  /// 释放所有资源
  void dispose() {
    _visibility.removeListener(_visibilityChanged);
    disconnect();
    _statusController.close();
  }

  /// Hidden window: no heartbeat. Shown again while connected: check once
  /// right away, then every [heartbeatInterval] as before.
  void _visibilityChanged() {
    if (_statusController.isClosed ||
        _apiService == null ||
        _status != ComfyUIConnectionStatus.connected) {
      return;
    }
    if (!_visibility.isVisible) {
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
      return;
    }
    if (_heartbeatTimer != null) return;
    unawaited(_checkConnection(_connectionRevision, _apiService!));
    _startHeartbeat();
  }

  Future<void> _checkConnection(int revision, ComfyUIApiService api) async {
    final ok = await api.testConnection();
    if (revision == _connectionRevision &&
        !ok &&
        _status == ComfyUIConnectionStatus.connected) {
      _setStatus(ComfyUIConnectionStatus.error);
    }
  }

  void _setStatus(ComfyUIConnectionStatus newStatus) {
    if (_status == newStatus) return;
    _status = newStatus;
    _statusController.add(newStatus);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    if (!_visibility.isVisible) return;
    final revision = _connectionRevision;
    final api = _apiService!;
    _heartbeatTimer = Timer.periodic(
      heartbeatInterval,
      (_) => unawaited(_checkConnection(revision, api)),
    );
  }
}
