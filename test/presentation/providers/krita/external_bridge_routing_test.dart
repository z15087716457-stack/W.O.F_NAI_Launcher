import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/krita/bridge_agent_service.dart';
import 'package:nai_launcher/core/krita/bridge_session.dart';
import 'package:nai_launcher/core/krita/krita_bridge_models.dart';
import 'package:nai_launcher/core/krita/krita_bridge_server.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'krita_bridge_notifier_test.dart' show RecordingKritaBridgeService;

class _Agent implements BridgeAgentService {
  _Agent(this.server);
  final KritaBridgeServer server;
  final disconnectedClients = <String>[];
  var closed = false;
  @override
  Future<void> handle(BridgeRequest request) async => server.send({
    'type': 'agent_result',
    'id': request.message.id,
    'result': {'native': true},
  });
  @override
  void disconnected(BridgeClient client) => disconnectedClients.add(client.id);
  @override
  void close() {
    closed = true;
  }
}

void main() {
  for (final enabled in [false, true]) {
    test(
      'notifier routes external tools without capturing classic requests: enabled=$enabled',
      () async {
        final root = await Directory.systemTemp.createTemp('external-routing-');
        final legacy = RecordingKritaBridgeService();
        late _Agent agent;
        final notifier = KritaBridgeNotifier(
          serverFactory: () => KritaBridgeServer(discoveryDirectory: root),
          serviceFactory: (_) => legacy,
          agentServiceFactory: enabled
              ? (server) => agent = _Agent(server)
              : null,
        );
        await notifier.enable(persist: false);
        final socket = await WebSocket.connect(
          'ws://127.0.0.1:${notifier.server!.port}/krita',
        );
        final frames = StreamIterator(socket);
        Future<Map> next() async {
          expect(
            await frames.moveNext().timeout(const Duration(seconds: 3)),
            isTrue,
          );
          return jsonDecode(frames.current as String) as Map;
        }

        try {
          socket.add(
            jsonEncode({
              'type': 'agent_request',
              'id': 'no-auth',
              'payload': {'operation': 'session'},
            }),
          );
          expect((await next())['code'], 'unauthorized_bridge_client');
          socket.add(
            jsonEncode({
              'type': 'ping',
              'version': 1,
              'secret': notifier.server!.secret,
              'client': {'kind': 'agent', 'name': 'Test'},
            }),
          );
          final pong = await next();
          expect(
            (pong['capabilities'] as List).contains('agent_tools_v1'),
            enabled,
          );
          socket.add(
            jsonEncode({
              'type': 'agent_request',
              'id': 'session',
              'payload': {'operation': 'session'},
            }),
          );
          final result = await next();
          expect(result['type'], enabled ? 'agent_result' : 'error');
          expect(notifier.state.isBridgeGenerating, isFalse);
          final classic = legacy.stream.first;
          socket.add(jsonEncode({'type': 'get_params', 'id': 'classic'}));
          expect(
            await classic.timeout(const Duration(seconds: 3)),
            isA<KritaGetParamsMessage>(),
          );
          expect(legacy.messages, hasLength(1));
          await socket.close();
          await Future<void>.delayed(const Duration(milliseconds: 20));
          if (enabled) expect(agent.disconnectedClients, hasLength(1));
          await notifier.disable(persist: false);
          if (enabled) expect(agent.closed, isTrue);
        } finally {
          await frames.cancel();
          await socket.close();
          await notifier.close();
          notifier.dispose();
          await legacy.close();
          await root.delete(recursive: true);
        }
      },
    );
  }
}
