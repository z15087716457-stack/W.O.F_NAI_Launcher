import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:nai_launcher/core/services/resource_window_protocol.dart';
import 'package:nai_launcher/core/services/resource_window_service.dart';
import 'package:nai_launcher/data/models/resources/floating_window_data.dart';
import 'package:nai_launcher/main.dart' show AppWindowListener;
import 'package:nai_launcher/presentation/resource_window/resource_window_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const windows = MethodChannel('mixin.one/desktop_multi_window');
  const channels = MethodChannel('mixin.one/desktop_multi_window/channels');
  const native = MethodChannel('com.nailauncher/resource_window_native');
  final service = ResourceWindowService();
  final calls = <MethodCall>[];

  Future<Object?> incoming(
    String channel,
    String method,
    Object? arguments,
  ) async {
    final reply = Completer<Object?>();
    await messenger.handlePlatformMessage(
      channel,
      const StandardMethodCodec().encodeMethodCall(
        MethodCall(method, arguments),
      ),
      (data) {
        try {
          reply.complete(const StandardMethodCodec().decodeEnvelope(data!));
        } catch (error, stack) {
          reply.completeError(error, stack);
        }
      },
    );
    return reply.future;
  }

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(windows, (call) async {
      calls.add(call);
      if (call.method == 'createWindow') return 'child-id';
      if (call.method == 'getWindowDefinition') {
        return {'windowId': 'child-id', 'windowArgument': ''};
      }
      return null;
    });
    messenger.setMockMethodCallHandler(channels, (call) async {
      calls.add(call);
      if (call.method == 'invokeMethod') return {'version': 1};
      return null;
    });
    messenger.setMockMethodCallHandler(native, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() async {
    await ResourceWindowService.hostChannel.setMethodCallHandler(null);
    for (final channel in [
      windows,
      channels,
      native,
      const MethodChannel('window_manager'),
    ]) {
      messenger.setMockMethodCallHandler(channel, null);
    }
  });

  test(
    'create passes the versioned launch arguments and starts hidden',
    () async {
      const arguments = ResourceWindowArguments(
        kind: FloatingResourceKind.blocks,
      );
      final child = await service.open(arguments);
      expect(child.windowId, 'child-id');
      final config = calls.single.arguments as Map;
      expect(config['hiddenAtLaunch'], true);
      expect(config['arguments'], arguments.encode());
    },
  );

  test(
    'host uses one unidirectional handler and rejects unimplemented data methods',
    () async {
      await service.initialize();
      expect(calls.single.arguments, {
        'channel': ResourceWindowService.hostChannel.name,
        'mode': 'unidirectional',
      });
      expect(
        await incoming(channels.name, 'methodCall', {
          'channel': ResourceWindowService.hostChannel.name,
          'method': 'ready',
          'arguments': {'windowId': 'child-id', 'kind': 'blocks'},
        }),
        {'version': 1},
      );
      // MissingPluginException is encoded as a null platform response.
      final reply = Completer<ByteData?>();
      await messenger.handlePlatformMessage(
        channels.name,
        const StandardMethodCodec().encodeMethodCall(
          MethodCall('methodCall', {
            'channel': ResourceWindowService.hostChannel.name,
            'method': 'query',
          }),
        ),
        reply.complete,
      );
      expect(await reply.future, isNull);
    },
  );

  test(
    'individual controls address the child; closeAll needs no ready handshake',
    () async {
      final child = WindowController.fromWindowId('child-id');
      await service.close(child);
      await service.setAlwaysOnTop(child, true);
      await service.closeAll();
      expect(calls.map((c) => c.method), [
        'invokeMethod',
        'invokeMethod',
        'closeAll',
      ]);
      expect(calls.first.arguments, {
        'channel': 'mixin.one/window_controller/child-id',
        'method': 'resource.close',
        'arguments': null,
      });
      expect((calls[1].arguments as Map)['arguments'], true);
    },
  );

  test(
    'main close posts child closure before hiding the main window',
    () async {
      messenger.setMockMethodCallHandler(
        const MethodChannel('window_manager'),
        (call) async {
          calls.add(call);
          return null;
        },
      );
      await AppWindowListener().onWindowClose();
      expect(calls.map((call) => call.method), [
        'setPreventClose',
        'closeAll',
        'hide',
      ]);
    },
  );

  testWidgets('child entry initializes only its channels and placeholder', (
    tester,
  ) async {
    final controller = WindowController.fromWindowId('child-id');
    await runResourceWindow(
      controller,
      const ResourceWindowArguments(kind: FloatingResourceKind.blocks),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ResourceWindowPlaceholder), findsOneWidget);
    expect(
      calls.map((c) => c.method),
      containsAllInOrder([
        'registerMethodHandler',
        'getWindowDefinition',
        'invokeMethod',
        'window_show',
      ]),
    );
    final ready = calls.singleWhere((call) => call.method == 'invokeMethod');
    expect((ready.arguments as Map)['method'], 'ready');
    expect((ready.arguments as Map)['arguments'], {
      'windowId': 'child-id',
      'kind': 'blocks',
    });
    await incoming(channels.name, 'methodCall', {
      'channel': 'mixin.one/window_controller/child-id',
      'method': 'resource.setAlwaysOnTop',
      'arguments': true,
    });
    await incoming(channels.name, 'methodCall', {
      'channel': 'mixin.one/window_controller/child-id',
      'method': 'resource.close',
      'arguments': null,
    });
    expect(calls.reversed.take(2).map((c) => c.method), [
      'close',
      'setAlwaysOnTop',
    ]);
    await controller.setWindowMethodHandler(null);
  });
}
