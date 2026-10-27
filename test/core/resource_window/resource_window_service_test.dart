import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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
  late ResourceWindowService service;
  final calls = <MethodCall>[];
  var created = 0;

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
    created = 0;
    service = ResourceWindowService();
    messenger.setMockMethodCallHandler(windows, (call) async {
      calls.add(call);
      if (call.method == 'createWindow') {
        created++;
        return created == 1 ? 'child-id' : 'child-$created';
      }
      if (call.method == 'getWindowDefinition') {
        return {'windowId': 'child-id', 'windowArgument': ''};
      }
      return null;
    });
    messenger.setMockMethodCallHandler(channels, (call) async {
      calls.add(call);
      if (call.method == 'invokeMethod') {
        final args = call.arguments as Map;
        if (args['method'] == 'ready') return {'version': 1};
        if (args['method'] == 'resources.query') {
          final request = args['arguments'] as Map;
          return {
            'requestId': request['requestId'],
            'revision': 0,
            'total': 0,
            'hasMore': false,
            'items': [],
            'layout': 'grid',
            'cellSize': 132,
          };
        }
      }
      return null;
    });
    messenger.setMockMethodCallHandler(native, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() async {
    await service.dispose();
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
    'host uses one unidirectional handler and reports not_ready before data attachment',
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
      await expectLater(
        incoming(channels.name, 'methodCall', {
          'channel': ResourceWindowService.hostChannel.name,
          'method': 'resources.query',
          'arguments': {},
        }),
        throwsA(
          isA<PlatformException>().having((e) => e.code, 'code', 'not_ready'),
        ),
      );
    },
  );

  test(
    'registry focuses an existing kind, explicit new opens another and changes push revisions',
    () async {
      const arguments = ResourceWindowArguments(
        kind: FloatingResourceKind.blocks,
      );
      final a = await service.open(arguments);
      final waiting = service.open(arguments);
      await service.handle(
        const MethodCall('ready', {'windowId': 'child-id', 'kind': 'blocks'}),
      );
      expect((await waiting).windowId, a.windowId);
      expect(calls.where((c) => c.method == 'createWindow'), hasLength(1));
      await service.open(arguments, newWindow: true);
      expect(service.windows, hasLength(2));
      await service.viewChanged(FloatingResourceKind.blocks, 'list');
      expect(service.host.revisions[FloatingResourceKind.blocks], 0);
      final views = calls.where(
        (c) =>
            c.method == 'invokeMethod' &&
            (c.arguments as Map)['method'] == 'resources.viewChanged',
      );
      expect(views, hasLength(2));
      expect(
        ((views.first.arguments as Map)['arguments'] as Map)['layout'],
        'list',
      );
      await service.changed(FloatingResourceKind.blocks);
      final pushed = calls.where(
        (c) =>
            c.method == 'invokeMethod' &&
            (c.arguments as Map)['method'] == 'resources.changed',
      );
      expect(pushed, hasLength(2));
      expect(
        ((pushed.first.arguments as Map)['arguments'] as Map)['revision'],
        1,
      );
      await service.handle(
        const MethodCall('resources.kind', {
          'windowId': 'child-id',
          'kind': 'vibe',
        }),
      );
      expect(service.windows['child-id'], FloatingResourceKind.vibe);
      await service.handle(
        const MethodCall('resources.closed', {'windowId': 'child-id'}),
      );
      expect(service.windows, hasLength(1));
      await service.closeAll();
      expect(service.windows, isEmpty);
    },
  );

  test(
    'closeAll waits for in-flight creation without waiting for child ready',
    () async {
      final created = Completer<String>();
      final started = Completer<void>();
      messenger.setMockMethodCallHandler(windows, (call) async {
        if (call.method == 'createWindow') {
          started.complete();
          return created.future;
        }
        return null;
      });
      final opening = service.open(
        const ResourceWindowArguments(kind: FloatingResourceKind.blocks),
      );
      await started.future;
      final closing = service.closeAll();
      expect(calls.where((c) => c.method == 'closeAll'), isEmpty);
      created.complete('pending');
      await opening;
      await closing;
      expect(calls.last.method, 'closeAll');
      expect(service.windows, isEmpty);
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

  testWidgets('child entry initializes channels and real page without stores', (
    tester,
  ) async {
    final controller = WindowController.fromWindowId('child-id');
    await runResourceWindow(
      controller,
      const ResourceWindowArguments(kind: FloatingResourceKind.blocks),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ResourceWindowApp), findsOneWidget);
    expect(
      calls.map((c) => c.method),
      containsAllInOrder([
        'registerMethodHandler',
        'getWindowDefinition',
        'invokeMethod',
        'window_show',
      ]),
    );
    final ready = calls.singleWhere(
      (call) =>
          call.method == 'invokeMethod' &&
          (call.arguments as Map)['method'] == 'ready',
    );
    expect((ready.arguments as Map)['method'], 'ready');
    expect((ready.arguments as Map)['arguments'], {
      'windowId': 'child-id',
      'kind': 'blocks',
    });
    await incoming(
      const MethodChannel('com.nailauncher/resource_window_native').name,
      'maximizedChanged',
      true,
    );
    expect(
      tester
          .widget<ResourceWindowApp>(find.byType(ResourceWindowApp))
          .controller
          .data
          .maximized,
      true,
    );
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
    await tester.pumpWidget(const SizedBox.shrink());
    await controller.setWindowMethodHandler(null);
  });
}
