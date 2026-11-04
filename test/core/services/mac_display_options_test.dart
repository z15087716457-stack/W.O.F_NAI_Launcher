// macOS 的「减少动态效果」「降低透明度」由 Runner 读系统设置后经通道传进来；
// Windows 不接这个通道（它的系统动画设置由引擎报成 MediaQuery.disableAnimations）。
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/mac_display_options.dart';

Future<void> _fromNative(Map<String, bool> options) =>
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          MacDisplayOptions.channel.name,
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('displayOptionsChanged', options),
          ),
          (_) {},
        );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var queries = 0;
  Map<String, bool>? native;

  setUp(() {
    queries = 0;
    native = {'reduceMotion': false, 'reduceTransparency': false};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MacDisplayOptions.channel, (call) async {
          if (call.method != 'getDisplayOptions') return null;
          queries++;
          if (native == null) throw MissingPluginException();
          return native;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MacDisplayOptions.channel, null);
  });

  group('macOS', () {
    late MacDisplayOptions options;
    setUp(() => options = MacDisplayOptions(platform: TargetPlatform.macOS));
    tearDown(() => options.detach());

    test('启动时读一次系统设置', () async {
      native = {'reduceMotion': true, 'reduceTransparency': true};
      options.attach();
      await pumpEventQueue();
      expect(queries, 1);
      expect(
        options.value,
        const SystemDisplayOptions(
          reduceMotion: true,
          reduceTransparency: true,
        ),
      );
    });

    test('系统设置改了跟着变，重复 attach 不重复读', () async {
      options
        ..attach()
        ..attach();
      await pumpEventQueue();
      expect(queries, 1);
      expect(options.value, const SystemDisplayOptions());

      await _fromNative({'reduceMotion': true, 'reduceTransparency': false});
      expect(options.value.reduceMotion, isTrue);
      expect(options.value.reduceTransparency, isFalse);

      await _fromNative({'reduceMotion': false, 'reduceTransparency': true});
      expect(options.value.reduceMotion, isFalse);
      expect(options.value.reduceTransparency, isTrue);
    });

    test('旧 Runner 没有这个通道：照旧不跟系统，也不报错', () async {
      native = null;
      options.attach();
      await pumpEventQueue();
      expect(options.value, const SystemDisplayOptions());
    });
  });

  test('Windows 不接这个通道', () async {
    final options = MacDisplayOptions(platform: TargetPlatform.windows)
      ..attach();
    addTearDown(options.detach);
    await pumpEventQueue();
    expect(queries, 0);
    await _fromNative({'reduceMotion': true, 'reduceTransparency': true});
    expect(options.value, const SystemDisplayOptions());
  });
}
