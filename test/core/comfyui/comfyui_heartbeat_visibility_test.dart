import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/comfyui/comfyui.dart';
import 'package:nai_launcher/core/services/app_visibility.dart';

import '../../helpers/app_logger_test_isolation.dart';

/// flutter_test answers HttpClient requests with a fake 400; use real sockets.
class _RealHttp extends HttpOverrides {}

/// A local ComfyUI: /system_stats and the progress WebSocket.
class _Server {
  _Server(this.http);
  final HttpServer http;
  final sockets = <WebSocket>[];
  int stats = 0;

  String get url => 'http://127.0.0.1:${http.port}';

  static Future<_Server> start() async {
    final server = _Server(
      await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
    );
    server.http.listen((request) async {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        server.sockets.add(await WebSocketTransformer.upgrade(request));
        return;
      }
      server.stats++;
      request.response
        ..headers.contentType = ContentType.json
        ..write('{}');
      await request.response.close();
    });
    return server;
  }

  Future<void> close() async {
    for (final socket in sockets) {
      await socket.close();
    }
    await http.close(force: true);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  final visibility = AppVisibility.instance;

  // The window signal itself is platform code (menu bar on macOS, tray on
  // Windows); the heartbeat only follows it, the same way on both.
  for (final platform in [TargetPlatform.macOS, TargetPlatform.windows]) {
    test(
      '${platform.name}: the heartbeat pauses while the window is hidden',
      () async {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() {
          debugDefaultTargetPlatformOverride = null;
          visibility.debugSet(true);
        });
        await HttpOverrides.runWithHttpOverrides(() async {
          final server = await _Server.start();
          final manager = ComfyUIConnectionManager(
            serverUrl: server.url,
            heartbeatInterval: const Duration(milliseconds: 40),
          );
          try {
            expect(await manager.connect(), isTrue);
            await Future<void>.delayed(const Duration(milliseconds: 300));
            expect(server.stats, greaterThan(3), reason: 'heartbeat running');

            visibility.debugSet(false);
            await Future<void>.delayed(const Duration(milliseconds: 60));
            final hidden = server.stats;
            await Future<void>.delayed(const Duration(milliseconds: 400));
            expect(server.stats, hidden, reason: 'nothing while hidden');
            expect(manager.status, ComfyUIConnectionStatus.connected);

            visibility.debugSet(true);
            await Future<void>.delayed(const Duration(milliseconds: 20));
            expect(server.stats, hidden + 1, reason: 'one check at once');
            await Future<void>.delayed(const Duration(milliseconds: 300));
            expect(server.stats, greaterThan(hidden + 3));
          } finally {
            manager.dispose();
            await server.close();
          }
        }, _RealHttp());
      },
    );
  }

  test(
    'connecting while hidden starts the heartbeat only when shown',
    () async {
      addTearDown(() => visibility.debugSet(true));
      await HttpOverrides.runWithHttpOverrides(() async {
        final server = await _Server.start();
        final manager = ComfyUIConnectionManager(
          serverUrl: server.url,
          heartbeatInterval: const Duration(milliseconds: 40),
        );
        try {
          visibility.debugSet(false);
          expect(await manager.connect(), isTrue);
          final connected = server.stats;
          await Future<void>.delayed(const Duration(milliseconds: 300));
          expect(server.stats, connected);
          visibility.debugSet(true);
          await Future<void>.delayed(const Duration(milliseconds: 300));
          expect(server.stats, greaterThan(connected + 3));
        } finally {
          manager.dispose();
          await server.close();
        }
      }, _RealHttp());
    },
  );
}
