import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../utils/app_logger.dart';
import 'krita_bridge_models.dart';
import 'krita_bridge_protocol.dart';
import 'bridge_session.dart';

typedef KritaBridgeSecretGenerator = String Function();
typedef KritaBridgePidProvider = int Function();
typedef KritaBridgeClock = DateTime Function();

class KritaBridgeServer {
  KritaBridgeServer({
    Directory? discoveryDirectory,
    KritaBridgeSecretGenerator? secretGenerator,
    KritaBridgePidProvider? pidProvider,
    KritaBridgeClock? clock,
    this.maxTextFrameBytes = KritaBridgeProtocol.defaultMaxTextFrameBytes,
  }) : _discoveryDirectory = discoveryDirectory ?? _defaultDiscoveryDirectory(),
       _secretGenerator = secretGenerator ?? _generateSecret,
       _pidProvider = pidProvider ?? (() => pid),
       _clock = clock ?? DateTime.now;

  static const String discoveryFileName = 'krita-bridge.json';
  static const String _logTag = 'KritaBridge';

  final Directory _discoveryDirectory;
  final KritaBridgeSecretGenerator _secretGenerator;
  final KritaBridgePidProvider _pidProvider;
  final KritaBridgeClock _clock;
  final int maxTextFrameBytes;

  final StreamController<KritaBridgeMessage> _messageController =
      StreamController<KritaBridgeMessage>.broadcast();
  final StreamController<bool> _authenticationController =
      StreamController<bool>.broadcast();
  final _requests = StreamController<BridgeRequest>.broadcast();
  final _sessions = StreamController<BridgeSession>.broadcast();
  final _disconnections = StreamController<BridgeClient>.broadcast();
  final _sockets = <String, WebSocket>{};
  final _clients = <String, BridgeClient>{};
  final _pending = <String, BridgeRequest>{};
  final _activities = <BridgeActivity>[];
  static final _clientScope = Object();
  int _nextClient = 0;
  int _nextActivity = 0;
  BridgeRequest? _mutationOwner;

  HttpServer? _server;
  String? _secret;
  DateTime? _startedAt;

  Stream<KritaBridgeMessage> get messages => _messageController.stream;

  Stream<bool> get authenticationChanges => _authenticationController.stream;

  int? get port => _server?.port;

  String? get secret => _secret;

  bool get isListening => _server != null;

  bool get isClientAuthenticated => _clients.values.any((c) => !c.isAgent);

  String? get connectedClientLabel =>
      _clients.values.where((c) => !c.isAgent).map((c) => c.name).lastOrNull;
  Stream<BridgeRequest> get requests => _requests.stream;
  Stream<BridgeSession> get sessionChanges => _sessions.stream;
  Stream<BridgeClient> get disconnections => _disconnections.stream;
  BridgeSession get session => BridgeSession(
    clients: List.unmodifiable(_clients.values),
    activities: List.unmodifiable(_activities),
  );
  BridgeClient? get currentClient =>
      (Zone.current[_clientScope] as BridgeRequest?)?.client;
  bool ownsActiveOperation(String clientId) =>
      _mutationOwner?.client.id == clientId;

  Future<void> inClientScope(
    BridgeRequest request,
    Future<void> Function() action,
  ) async {
    try {
      await runZoned(action, zoneValues: {_clientScope: request});
    } catch (_) {
      runZoned(
        () => send({
          'type': 'error',
          'id': request.message.id,
          'code': 'server_error',
          'message': 'Bridge operation failed.',
        }),
        zoneValues: {_clientScope: request},
      );
    } finally {
      _pending.remove(request.key);
      if (_mutationOwner?.key == request.key) _mutationOwner = null;
      _finish(request.key, BridgeActivityStatus.completed);
    }
  }

  File get discoveryFile =>
      File(_join(_discoveryDirectory.path, discoveryFileName));

  Future<void> start({int preferredPort = 0}) async {
    if (_server != null) {
      await stop();
    }

    _secret = _secretGenerator();
    _startedAt = _clock().toUtc();
    _server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      preferredPort,
    );
    unawaited(_acceptRequests(_server!));
    await _writeDiscoveryFile();
    AppLogger.i('Bridge listening on 127.0.0.1:$port', _logTag);
  }

  Future<void> stop() async {
    final sockets = _sockets.values.toList();
    _sockets.clear();
    _clients.clear();
    _pending.clear();
    _mutationOwner = null;
    _activities.clear();
    if (!_authenticationController.isClosed) {
      _authenticationController.add(false);
    }

    _publishSession();
    await Future.wait(sockets.map((s) => s.close()));

    final server = _server;
    _server = null;
    if (server != null) {
      await server.close(force: true);
    }

    final file = discoveryFile;
    if (await file.exists()) {
      await file.delete();
      AppLogger.i('Discovery file deleted: ${file.path}', _logTag);
    }
    AppLogger.i('Bridge stopped', _logTag);
  }

  Future<void> dispose() async {
    await stop();
    await _messageController.close();
    await _authenticationController.close();
    await _requests.close();
    await _sessions.close();
    await _disconnections.close();
  }

  void send(Map<String, dynamic> message) {
    final request = Zone.current[_clientScope] as BridgeRequest?;
    if (request == null) {
      // Unsolicited image pushes are exclusively for Krita.
      for (final c in _clients.values.where((c) => !c.isAgent)) {
        _sockets[c.id]?.add(jsonEncode(message));
      }
      return;
    }
    _sockets[request.client.id]?.add(jsonEncode(message));
    if (message['type'] == 'error') {
      _finish(
        request.key,
        BridgeActivityStatus.failed,
        errorCode: message['code'] as String?,
      );
    }
  }

  void sendBinary(Uint8List bytes) {
    final client = currentClient;
    if (client != null) _sockets[client.id]?.add(bytes);
  }

  Future<void> _acceptRequests(HttpServer server) async {
    await for (final request in server) {
      if (request.uri.path != '/krita' ||
          !WebSocketTransformer.isUpgradeRequest(request)) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        continue;
      }

      if (_sockets.length >= 16) {
        request.response.statusCode = HttpStatus.serviceUnavailable;
        await request.response.close();
        continue;
      }
      final socket = await WebSocketTransformer.upgrade(request);
      final clientId = 'client-${++_nextClient}';
      _sockets[clientId] = socket;
      socket.pingInterval = const Duration(seconds: 30);
      AppLogger.i('Incoming WebSocket connection', _logTag);
      unawaited(_handleSocket(socket, clientId: clientId));
    }
  }

  Future<void> _handleSocket(
    WebSocket socket, {
    required String clientId,
  }) async {
    var socketAuthenticated = false;
    final authTimeout = Timer(const Duration(seconds: 5), () {
      if (!socketAuthenticated) unawaited(socket.close());
    });

    try {
      await for (final data in socket) {
        if (data is! String) {
          _sendError(
            socket,
            const KritaBridgeError(
              code: KritaBridgeErrorCode.invalidRequest,
              message: 'Only JSON text frames are supported in V1',
            ),
          );
          continue;
        }

        final result = KritaBridgeProtocol.decodeIncoming(
          data,
          sessionSecret: _secret ?? '',
          authenticated: socketAuthenticated,
          maxTextFrameBytes: maxTextFrameBytes,
        );

        final error = result.error;
        if (error != null) {
          AppLogger.w(
            'Rejected message: ${error.code.value}'
            '${error.id == null ? '' : ' id=${error.id}'}',
            _logTag,
          );
          _sendError(socket, error);
          continue;
        }

        final message = result.message;
        if (message == null) {
          continue;
        }

        if (message is KritaUnsupportedPingVersionMessage) {
          socket.add(
            jsonEncode(
              KritaBridgeProtocol.encodePong(
                supportedVersions: message.supportedVersions,
              ),
            ),
          );
          AppLogger.w(
            'Rejected ping version: ${message.requestedVersion}',
            _logTag,
          );
          continue;
        }

        if (message is KritaPingMessage) {
          _clients.putIfAbsent(
            clientId,
            () => BridgeClient(
              id: clientId,
              kind: message.clientKind == 'agent'
                  ? BridgeClientKind.agent
                  : BridgeClientKind.krita,
              name: message.clientName,
            ),
          );
          socketAuthenticated = true;
          authTimeout.cancel();
          _authenticationController.add(isClientAuthenticated);
          _publishSession();
          socket.add(
            jsonEncode({
              ...KritaBridgeProtocol.encodePong(),
              'capabilities': ['multi_client', 'guarded_set', 'raw_draft'],
              'client_id': clientId,
            }),
          );
          AppLogger.i('Bridge client authenticated', _logTag);
          continue;
        }

        final request = BridgeRequest(
          client: _clients[clientId]!,
          message: message,
        );
        final mutates = const {
          'set_params',
          'generate',
          'inpaint',
          'img2img',
        }.contains(message.type);
        if (_pending.containsKey(request.key) ||
            (mutates && _mutationOwner != null)) {
          _reject(request, socket, 'busy', 'Another operation is in progress.');
          continue;
        }
        if (message is KritaCancelMessage &&
            _mutationOwner != null &&
            _mutationOwner!.client.id != clientId &&
            !(request.client.isAgent &&
                _mutationOwner!.client.isAgent &&
                request.client.name == _mutationOwner!.client.name &&
                message.id == _mutationOwner!.message.id)) {
          _reject(
            request,
            socket,
            'busy',
            'This request belongs to another client.',
          );
          continue;
        }
        if (mutates) _mutationOwner = request;
        _pending[request.key] = request;
        _record(request);
        _messageController.add(message);
        _requests.add(request);
      }
    } catch (_) {
      // Socket failures are represented in session state without raw payloads.
    } finally {
      authTimeout.cancel();
      _sockets.remove(clientId);
      final client = _clients.remove(clientId);
      if (client != null) {
        _disconnections.add(client);
        for (final r in _pending.values.where((r) => r.client.id == clientId)) {
          _finish(r.key, BridgeActivityStatus.disconnected);
        }
        _authenticationController.add(isClientAuthenticated);
        _publishSession();
      }
    }
  }

  void _record(BridgeRequest request, {String? activityKey}) {
    _activities.insert(
      0,
      BridgeActivity(
        key: activityKey ?? request.key,
        client: request.client,
        operation: request.message.type,
        at: _clock(),
      ),
    );
    if (_activities.length > 8) {
      // Keep a long generation visible when other clients repeatedly read.
      final completed = _activities.lastIndexWhere(
        (a) => a.status != BridgeActivityStatus.running,
      );
      final removable = completed >= 0
          ? completed
          : _activities.lastIndexWhere((a) => a.key != _mutationOwner?.key);
      if (removable >= 0) _activities.removeAt(removable);
    }
    _publishSession();
  }

  void _finish(String key, BridgeActivityStatus status, {String? errorCode}) {
    final i = _activities.indexWhere((a) => a.key == key);
    if (i < 0 || _activities[i].status != BridgeActivityStatus.running) return;
    _activities[i] = _activities[i].finish(status, errorCode: errorCode);
    _publishSession();
  }

  void _reject(
    BridgeRequest request,
    WebSocket socket,
    String code,
    String message,
  ) {
    // A duplicate request must not mark its still-running original as failed.
    final activityKey = '${request.key}:rejected-${++_nextActivity}';
    _record(request, activityKey: activityKey);
    _finish(activityKey, BridgeActivityStatus.failed, errorCode: code);
    socket.add(
      jsonEncode({
        'type': 'error',
        'id': request.message.id,
        'code': code,
        'message': message,
      }),
    );
  }

  void _publishSession() {
    if (!_sessions.isClosed) _sessions.add(session);
  }

  Future<void> disconnectAgents() async {
    final agents = _clients.values.where((c) => c.isAgent).toList();
    await Future.wait(
      agents.map((c) => _sockets[c.id]?.close() ?? Future.value()),
    );
  }

  void _sendError(WebSocket socket, KritaBridgeError error) {
    socket.add(jsonEncode(KritaBridgeProtocol.encodeError(error)));
  }

  Future<void> _writeDiscoveryFile() async {
    await _discoveryDirectory.create(recursive: true);

    final target = discoveryFile;
    final temp = File(
      _join(
        _discoveryDirectory.path,
        '$discoveryFileName.${DateTime.now().microsecondsSinceEpoch}.tmp',
      ),
    );

    final data = <String, dynamic>{
      'port': port,
      'pid': _pidProvider(),
      'version': KritaBridgeProtocol.version,
      'secret': _secret,
      'started_at': _startedAt?.toIso8601String(),
    };

    await temp.writeAsString(jsonEncode(data), flush: true);
    if (await target.exists()) {
      await target.delete();
    }
    await temp.rename(target.path);
    AppLogger.i('Discovery file written: ${target.path}', _logTag);
  }

  static Directory _defaultDiscoveryDirectory() {
    final appData = Platform.environment['APPDATA'];
    if (appData != null && appData.isNotEmpty) {
      return Directory(_join(appData, 'nai-launcher'));
    }

    final home =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.current.path;
    return Directory(_join(home, '.nai-launcher'));
  }

  static String _generateSecret() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static String _join(String left, String right) {
    final separator = Platform.pathSeparator;
    if (left.endsWith(separator)) {
      return '$left$right';
    }
    return '$left$separator$right';
  }
}
