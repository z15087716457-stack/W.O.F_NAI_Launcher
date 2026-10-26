import 'dart:async';

import 'package:uuid/uuid.dart';

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
/// - 心跳检测
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

  ComfyUIConnectionManager({String serverUrl = 'http://127.0.0.1:8188'})
    : _serverUrl = normalizeComfyUIBaseUrl(serverUrl),
      clientId = const Uuid().v4();

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
    disconnect();
    _statusController.close();
  }

  void _setStatus(ComfyUIConnectionStatus newStatus) {
    if (_status == newStatus) return;
    _status = newStatus;
    _statusController.add(newStatus);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    final revision = _connectionRevision;
    final api = _apiService!;
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final ok = await api.testConnection();
      if (revision == _connectionRevision &&
          !ok &&
          _status == ComfyUIConnectionStatus.connected) {
        _setStatus(ComfyUIConnectionStatus.error);
      }
    });
  }
}
