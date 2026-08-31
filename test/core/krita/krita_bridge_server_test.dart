import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/krita/krita_bridge_models.dart';
import 'package:nai_launcher/core/krita/krita_bridge_server.dart';

void main() {
  late Directory tempDir;
  late KritaBridgeServer server;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'krita_bridge_server_test_',
    );
    server = KritaBridgeServer(
      discoveryDirectory: tempDir,
      pidProvider: () => 12345,
      secretGenerator: () => 'server-secret',
      clock: () => DateTime.utc(2026, 5, 7, 10, 30),
    );
  });

  tearDown(() async {
    await server.stop();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('start writes discovery file and stop deletes it', () async {
    await server.start(preferredPort: 0);

    final file = File(
      '${tempDir.path}${Platform.pathSeparator}krita-bridge.json',
    );
    expect(await file.exists(), isTrue);

    final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    expect(data['port'], server.port);
    expect(data['pid'], 12345);
    expect(data['version'], 1);
    expect(data['secret'], 'server-secret');
    expect(data['started_at'], '2026-05-07T10:30:00.000Z');

    await server.stop();

    expect(await file.exists(), isFalse);
  });

  test(
    'rejects unauthenticated messages and keeps them off message stream',
    () async {
      await server.start(preferredPort: 0);
      final socket = await WebSocket.connect(
        'ws://127.0.0.1:${server.port}/krita',
      );
      final messages = <KritaBridgeMessage>[];
      final subscription = server.messages.listen(messages.add);

      socket.add(jsonEncode({'type': 'get_params', 'id': 'req-1'}));

      final response =
          jsonDecode(await socket.first as String) as Map<String, dynamic>;
      expect(response['type'], 'error');
      expect(
        response['code'],
        KritaBridgeErrorCode.unauthorizedBridgeClient.value,
      );
      expect(messages, isEmpty);

      await subscription.cancel();
      await socket.close();
    },
  );

  test('authenticates with ping and forwards later messages', () async {
    await server.start(preferredPort: 0);
    final socket = await WebSocket.connect(
      'ws://127.0.0.1:${server.port}/krita',
    );
    final nextMessage = server.messages.first;

    socket.add(
      jsonEncode({'type': 'ping', 'version': 1, 'secret': 'server-secret'}),
    );
    final pong =
        jsonDecode(await socket.first as String) as Map<String, dynamic>;
    expect(pong['type'], 'pong');
    expect(pong['version'], 1);
    expect(server.isClientAuthenticated, isTrue);

    socket.add(jsonEncode({'type': 'get_params', 'id': 'req-2'}));
    final message = await nextMessage.timeout(const Duration(seconds: 2));

    expect(message, isA<KritaGetParamsMessage>());
    expect(message.id, 'req-2');

    await socket.close();
  });

  test(
    'does not share authentication with a second unauthenticated client',
    () async {
      await server.start(preferredPort: 0);
      final first = await WebSocket.connect(
        'ws://127.0.0.1:${server.port}/krita',
      );
      final firstIterator = StreamIterator(first);
      final second = await WebSocket.connect(
        'ws://127.0.0.1:${server.port}/krita',
      );
      final messages = <KritaBridgeMessage>[];
      final subscription = server.messages.listen(messages.add);

      first.add(
        jsonEncode({'type': 'ping', 'version': 1, 'secret': 'server-secret'}),
      );
      expect(await firstIterator.moveNext(), isTrue);
      expect(server.isClientAuthenticated, isTrue);

      second.add(jsonEncode({'type': 'get_params', 'id': 'req-second'}));

      final response =
          jsonDecode(await second.first as String) as Map<String, dynamic>;
      expect(response['type'], 'error');
      expect(
        response['code'],
        KritaBridgeErrorCode.unauthorizedBridgeClient.value,
      );
      await Future<void>.delayed(Duration.zero);
      expect(messages, isEmpty);

      await subscription.cancel();
      await firstIterator.cancel();
      await first.close();
      await second.close();
    },
  );

  test(
    'reports supported versions without authenticating mismatched ping',
    () async {
      await server.start(preferredPort: 0);
      final socket = await WebSocket.connect(
        'ws://127.0.0.1:${server.port}/krita',
      );

      socket.add(
        jsonEncode({'type': 'ping', 'version': 999, 'secret': 'server-secret'}),
      );

      final response =
          jsonDecode(await socket.first as String) as Map<String, dynamic>;
      expect(response['type'], 'pong');
      expect(response['version'], 1);
      expect(response['supported_versions'], [1]);
      expect(server.isClientAuthenticated, isFalse);

      await socket.close();
    },
  );

  test(
    'new authenticated client replaces the old authenticated client',
    () async {
      await server.start(preferredPort: 0);
      final first = await WebSocket.connect(
        'ws://127.0.0.1:${server.port}/krita',
      );
      final firstIterator = StreamIterator(first);
      first.add(
        jsonEncode({'type': 'ping', 'version': 1, 'secret': 'server-secret'}),
      );
      expect(await firstIterator.moveNext(), isTrue);

      final second = await WebSocket.connect(
        'ws://127.0.0.1:${server.port}/krita',
      );
      final secondIterator = StreamIterator(second);
      second.add(
        jsonEncode({'type': 'ping', 'version': 1, 'secret': 'server-secret'}),
      );
      expect(await secondIterator.moveNext(), isTrue);
      final pong =
          jsonDecode(secondIterator.current as String) as Map<String, dynamic>;

      expect(pong['type'], 'pong');
      await expectLater(
        firstIterator.moveNext().timeout(const Duration(seconds: 2)),
        completion(isFalse),
      );

      await firstIterator.cancel();
      await secondIterator.cancel();
      await second.close();
    },
  );

  test('replaced authenticated client cannot forward messages', () async {
    await server.start(preferredPort: 0);
    final messages = <KritaBridgeMessage>[];
    final subscription = server.messages.listen(messages.add);

    final first = await WebSocket.connect(
      'ws://127.0.0.1:${server.port}/krita',
    );
    final firstIterator = StreamIterator(first);
    first.add(
      jsonEncode({'type': 'ping', 'version': 1, 'secret': 'server-secret'}),
    );
    expect(await firstIterator.moveNext(), isTrue);

    final second = await WebSocket.connect(
      'ws://127.0.0.1:${server.port}/krita',
    );
    final secondIterator = StreamIterator(second);
    second.add(
      jsonEncode({'type': 'ping', 'version': 1, 'secret': 'server-secret'}),
    );
    expect(await secondIterator.moveNext(), isTrue);

    first.add(jsonEncode({'type': 'get_params', 'id': 'from-old'}));
    second.add(jsonEncode({'type': 'get_params', 'id': 'from-current'}));

    final currentMessage = await server.messages.first.timeout(
      const Duration(seconds: 2),
    );
    await Future<void>.delayed(Duration.zero);

    expect(currentMessage, isA<KritaGetParamsMessage>());
    expect(currentMessage.id, 'from-current');
    expect(
      messages.whereType<KritaGetParamsMessage>().map((message) => message.id),
      isNot(contains('from-old')),
    );

    await subscription.cancel();
    await firstIterator.cancel();
    await secondIterator.cancel();
    await first.close();
    await second.close();
  });
}
