// 登录 / 启动页的字符场：每秒最多约 30 帧（和原来 33ms 节流的画面更新一样快），不再
// 每次屏幕刷新都要一帧；窗口看不见时停，回来继续；系统减少动态效果时只画静止帧。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/app_visibility.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/branding/entry_field.dart';
import 'package:nai_launcher/presentation/widgets/common/app_visibility_scope.dart';

var _counting = false;
var _frames = 0;

Future<int> _framesDuring(WidgetTester t, Duration span) async {
  _frames = 0;
  _counting = true;
  for (var e = Duration.zero; e < span; e += const Duration(milliseconds: 4)) {
    await t.pump(const Duration(milliseconds: 4));
  }
  _counting = false;
  return _frames;
}

Widget _field({bool tickers = true, bool reduceMotion = false}) => MaterialApp(
  theme: GeistTheme.dark,
  home: MediaQuery(
    data: MediaQueryData(
      size: const Size(900, 600),
      disableAnimations: reduceMotion,
    ),
    child: TickerMode(enabled: tickers, child: const EntryField(signal: 0.3)),
  ),
);

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.addPersistentFrameCallback((_) {
    if (_counting) _frames++;
  });

  testWidgets('每秒最多约 30 帧，没有每次刷新都要帧的 ticker', (t) async {
    await t.pumpWidget(_field());
    await t.pump(const Duration(milliseconds: 100));
    expect(t.binding.transientCallbackCount, 0);
    // 每 4ms 推一次时间（相当于 250Hz 的屏幕）：原来每次都出一帧，现在只按 33ms 的节拍出
    final frames = await _framesDuring(t, const Duration(seconds: 1));
    expect(frames, inInclusiveRange(28, 31));
    expect(EntryField.frameInterval, const Duration(milliseconds: 33));
  });

  testWidgets('窗口看不见（TickerMode 关）时一帧都不出，回来接着走', (t) async {
    await t.pumpWidget(_field());
    await t.pump(const Duration(milliseconds: 100));
    await t.pumpWidget(_field(tickers: false));
    await t.pump();
    expect(await _framesDuring(t, const Duration(seconds: 2)), 0);
    await t.pumpWidget(_field());
    expect(
      await _framesDuring(t, const Duration(seconds: 1)),
      inInclusiveRange(28, 31),
    );
  });

  for (final platform in [TargetPlatform.macOS, TargetPlatform.windows]) {
    testWidgets('${platform.name}：藏到托盘 / 最小化时停，叫回来继续', (t) async {
      final visibility = AppVisibilitySources(platform: platform);
      addTearDown(visibility.detach);
      await t.pumpWidget(
        AppVisibilityScope(sources: visibility, child: _field()),
      );
      await t.pump(const Duration(milliseconds: 100));
      visibility.markHidden();
      await t.pump();
      expect(await _framesDuring(t, const Duration(seconds: 1)), 0);
      visibility.markShown();
      await t.pump();
      expect(
        await _framesDuring(t, const Duration(seconds: 1)),
        inInclusiveRange(28, 31),
      );
      visibility.onWindowEvent('minimize');
      await t.pump();
      expect(await _framesDuring(t, const Duration(seconds: 1)), 0);
      visibility.onWindowEvent('restore');
      await t.pump();
      expect(
        await _framesDuring(t, const Duration(seconds: 1)),
        greaterThan(25),
      );
    });
  }

  testWidgets('系统减少动态效果：只画一张静止帧', (t) async {
    await t.pumpWidget(_field(reduceMotion: true));
    await t.pump();
    await t.pump();
    expect(await _framesDuring(t, const Duration(seconds: 1)), 0);
  });
}
