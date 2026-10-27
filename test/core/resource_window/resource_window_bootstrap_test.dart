import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/resource_window_bootstrap.dart';
import 'package:nai_launcher/core/services/resource_window_protocol.dart';
import 'package:nai_launcher/data/models/resources/floating_window_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel('mixin.one/desktop_multi_window');

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('child waits for late native registration before dispatching', () async {
    const arguments = ResourceWindowArguments(
      kind: FloatingResourceKind.blocks,
    );
    var attempts = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getWindowDefinition');
      if (++attempts < 3) throw MissingPluginException();
      return {'windowId': 'late-child', 'windowArgument': arguments.encode()};
    });

    final controller = await waitForResourceWindowPlugins();
    var mainStarts = 0;
    ResourceWindowArguments? childArguments;
    await dispatchResourceWindow(
      arguments: controller.arguments,
      startMain: () async {
        mainStarts++;
      },
      startResource: (arguments) async {
        childArguments = arguments;
      },
    );
    expect(attempts, 3);
    expect(controller.windowId, 'late-child');
    expect(mainStarts, 0);
    expect(childArguments?.kind, FloatingResourceKind.blocks);
  });

  test('primary engine with registered plugins starts immediately', () async {
    var attempts = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      attempts++;
      return {'windowId': 'main', 'windowArgument': ''};
    });
    final controller = await waitForResourceWindowPlugins();
    expect(controller.arguments, isEmpty);
    expect(attempts, 1);
  });

  test('permanently absent plugin stops at the startup deadline', () async {
    var attempts = 0;
    messenger.setMockMethodCallHandler(channel, (_) async {
      attempts++;
      throw MissingPluginException('not registered');
    });
    await expectLater(
      waitForResourceWindowPlugins(timeout: Duration.zero),
      throwsA(isA<MissingPluginException>()),
    );
    expect(attempts, 1);
  });

  test('native failures are not mistaken for late registration', () async {
    var attempts = 0;
    messenger.setMockMethodCallHandler(channel, (_) async {
      attempts++;
      throw PlatformException(code: 'invalid_window');
    });
    await expectLater(
      waitForResourceWindowPlugins(),
      throwsA(
        isA<PlatformException>().having(
          (e) => e.code,
          'code',
          'invalid_window',
        ),
      ),
    );
    expect(attempts, 1);
  });
}
