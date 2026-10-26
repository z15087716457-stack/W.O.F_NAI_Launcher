import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/comfyui/comfyui.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/presentation/providers/comfyui/comfyui_provider.dart';

import '../../helpers/app_logger_test_isolation.dart';

class _RealHttp extends HttpOverrides {}

class _Server {
  _Server(this.http);
  final HttpServer http;
  final sockets = <WebSocket>[];
  final statsStarted = Completer<void>();
  final wsStarted = Completer<void>();
  Completer<void>? statsGate;
  Completer<void>? wsGate;
  int statsRequests = 0;
  int wsRequests = 0;

  String get url => 'http://127.0.0.1:${http.port}';

  static Future<_Server> start() async {
    final server = _Server(
      await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
    );
    server.http.listen(server.handle);
    return server;
  }

  Future<void> handle(HttpRequest request) async {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      wsRequests++;
      if (!wsStarted.isCompleted) wsStarted.complete();
      await wsGate?.future;
      sockets.add(await WebSocketTransformer.upgrade(request));
    } else {
      expect(request.uri.path, '/system_stats');
      statsRequests++;
      if (!statsStarted.isCompleted) statsStarted.complete();
      await statsGate?.future;
      request.response
        ..headers.contentType = ContentType.json
        ..write('{}');
      await request.response.close();
    }
  }

  Future<void> close() async {
    if (statsGate?.isCompleted == false) statsGate!.complete();
    if (wsGate?.isCompleted == false) wsGate!.complete();
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
  late Directory directory;
  late ProviderContainer container;
  late _Server first;
  late _Server second;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('comfy_connection_');
    Hive.init(directory.path);
    final box = await Hive.openBox(StorageKeys.settingsBox);
    first = await _Server.start();
    second = await _Server.start();
    await box.put(StorageKeys.comfyuiServerUrl, first.url);
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await first.close();
    await second.close();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> saveSecondUrl() async {
    await Hive.box(
      StorageKeys.settingsBox,
    ).put(StorageKeys.comfyuiServerUrl, second.url);
    container.invalidate(comfyUISettingsProvider);
    expect(container.read(comfyUISettingsProvider).serverUrl, second.url);
  }

  test(
    'saving a new URL disposes the old connection and next connect uses it',
    () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        final connection = container.read(comfyUIConnectionProvider.notifier);
        expect(await connection.connect(), isTrue);
        final old = connection.manager!;
        await saveSecondUrl();
        expect(
          container.read(comfyUIConnectionProvider),
          ComfyUIConnectionStatus.disconnected,
        );
        expect(connection.manager, isNull);
        expect(old.api, isNull);
        expect(old.ws, isNull);
        expect(await connection.connect(), isTrue);
        expect(connection.manager!.serverUrl, second.url);
        expect(second.statsRequests, 1);
        expect(second.wsRequests, 1);
      }, _RealHttp());
    },
  );

  test('the settings notifier also invalidates the old connection', () async {
    await HttpOverrides.runWithHttpOverrides(() async {
      final connection = container.read(comfyUIConnectionProvider.notifier);
      expect(await connection.connect(), isTrue);
      container
          .read(comfyUISettingsProvider.notifier)
          .setServerUrl('${second.url}/');
      expect(
        container.read(comfyUIConnectionProvider),
        ComfyUIConnectionStatus.disconnected,
      );
      expect(await connection.connect(), isTrue);
      expect(connection.manager!.api!.baseUrl, second.url);
      expect(connection.manager!.ws!.baseUrl, second.url);
    }, _RealHttp());
  });

  for (final phase in ['HTTP', 'WebSocket']) {
    test(
      'URL change during $phase connect prevents an old completion',
      () async {
        await HttpOverrides.runWithHttpOverrides(() async {
          final gate = Completer<void>();
          if (phase == 'HTTP') {
            first.statsGate = gate;
          } else {
            first.wsGate = gate;
          }
          final connection = container.read(comfyUIConnectionProvider.notifier);
          final connecting = connection.connect();
          await (phase == 'HTTP'
              ? first.statsStarted.future
              : first.wsStarted.future);
          await saveSecondUrl();
          expect(
            container.read(comfyUIConnectionProvider),
            ComfyUIConnectionStatus.disconnected,
          );
          expect(await connection.connect(), isTrue);
          final active = connection.manager;
          gate.complete();
          expect(await connecting, isFalse);
          expect(connection.manager, same(active));
          expect(
            container.read(comfyUIConnectionProvider),
            ComfyUIConnectionStatus.connected,
          );
          expect(active!.serverUrl, second.url);
          if (phase == 'HTTP') expect(first.wsRequests, 0);
        }, _RealHttp());
      },
    );
  }

  test(
    'manager URL change cancels a pending connection before reconnecting',
    () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        first.statsGate = Completer<void>();
        final manager = ComfyUIConnectionManager(serverUrl: first.url);
        addTearDown(manager.dispose);
        final connecting = manager.connect();
        await first.statsStarted.future;
        manager.updateServerUrl(second.url);
        expect(manager.status, ComfyUIConnectionStatus.disconnected);
        expect(await manager.connect(), isTrue);
        first.statsGate!.complete();
        expect(await connecting, isFalse);
        expect(manager.status, ComfyUIConnectionStatus.connected);
        expect(manager.api!.baseUrl, second.url);
        expect(manager.ws!.baseUrl, second.url);
        expect(first.wsRequests, 0);
      }, _RealHttp());
    },
  );

  test('disconnect disposes the manager status stream', () async {
    await HttpOverrides.runWithHttpOverrides(() async {
      final connection = container.read(comfyUIConnectionProvider.notifier);
      expect(await connection.connect(), isTrue);
      final closed = Completer<void>();
      connection.manager!.statusStream.listen((_) {}, onDone: closed.complete);
      connection.disconnect();
      await Future<void>.delayed(Duration.zero);
      expect(closed.isCompleted, isTrue);
      expect(
        container.read(comfyUIConnectionProvider),
        ComfyUIConnectionStatus.disconnected,
      );
    }, _RealHttp());
  });
}
