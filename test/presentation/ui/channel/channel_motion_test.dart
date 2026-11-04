// 视觉通道「空闲微动」三档：关闭（默认）/ 防烧屏 / 原本效果。
// - 防烧屏：每秒整层挪一小格，场景只画一次、挪动只改图层位置不重画。
// - 原本效果：和上游一样的逐个元素动画，但只按原来 33ms 换一次画面的节拍出帧（≤ 约 30 帧/秒），
//   场景上面的图片光台和时间刻度单独一层、不跟着重录，合起来和一起画逐像素一样。
// 三档在生成中 / 减少动态效果 / 模式关闭时都停；窗口看不见时都停、看得见（哪怕不在前台）时继续。
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/app_visibility.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_contract.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_fixture.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_layer.dart';
import 'package:nai_launcher/presentation/widgets/common/app_visibility_scope.dart';

const _viewport = Size(800, 600);

ChannelViewData _data(ChannelMotion motion, {bool generating = false}) =>
    ChannelViewData(
      settings: ChannelSettings(
        mode: ChannelMode.fixed,
        fixed: ChannelTheme.stars,
        motion: motion,
        seed: 7,
      ),
      camera: const ChannelCamera(offset: Offset(400, 300), scale: .5),
      batches: [for (final g in ChannelFixture.groups()) g.batch],
      now: ChannelFixture.now,
      generating: generating,
    );

Widget _app(Widget child, {bool reduceMotion = false, double dpr = 2}) =>
    MaterialApp(
      theme: GeistTheme.light,
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: _viewport,
          devicePixelRatio: dpr,
          disableAnimations: reduceMotion,
        ),
        child: Center(
          child: RepaintBoundary(
            key: const Key('capture'),
            child: SizedBox.fromSize(size: _viewport, child: child),
          ),
        ),
      ),
    );

Widget _host(
  ChannelViewData data, {
  bool reduceMotion = false,
  bool tickers = true,
  double dpr = 2,
}) => _app(
  TickerMode(
    enabled: tickers,
    child: ChannelBackdrop(data: data),
  ),
  reduceMotion: reduceMotion,
  dpr: dpr,
);

RenderRepaintBoundary _boundaryOf(WidgetTester t, String key) =>
    t.renderObject<RenderCustomPaint>(find.byKey(Key(key))).parent!
        as RenderRepaintBoundary;

/// 场景录下来的那张图层；没重画就一直是同一个对象。
PictureLayer _scenePicture(WidgetTester t) =>
    _boundaryOf(t, 'channel-backdrop').debugLayer!.firstChild! as PictureLayer;

PictureLayer _annotationPicture(WidgetTester t) =>
    _boundaryOf(t, 'channel-annotations').debugLayer!.firstChild!
        as PictureLayer;

Offset _sceneOffset(WidgetTester t) =>
    (_boundaryOf(t, 'channel-backdrop').debugLayer! as OffsetLayer).offset;

ChannelBackdropPainter _scenePainter(WidgetTester t) =>
    t.widget<CustomPaint>(find.byKey(const Key('channel-backdrop'))).painter!
        as ChannelBackdropPainter;

/// 数一段时间里真的画了几帧（每 [step] 推一次时间）。
var _counting = false;
var _frames = 0;

Future<int> _framesDuring(
  WidgetTester t,
  Duration span, {
  Duration step = const Duration(milliseconds: 50),
}) async {
  _frames = 0;
  _counting = true;
  for (var e = Duration.zero; e < span; e += step) {
    await t.pump(step);
  }
  _counting = false;
  return _frames;
}

Future<Uint8List> _shot(WidgetTester t) async {
  final boundary = t.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('capture')),
  );
  return (await t.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  }))!;
}

Future<void> _occlusion(WidgetTester t, bool visible) =>
    t.binding.defaultBinaryMessenger.handlePlatformMessage(
      AppVisibilitySources.channel.name,
      const StandardMethodCodec().encodeMethodCall(
        MethodCall('visibilityChanged', visible),
      ),
      (_) {},
    );

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.addPersistentFrameCallback((_) {
    if (_counting) _frames++;
  });

  group('关闭', () {
    test('默认关闭（两个平台一样）', () {
      expect(const ChannelSettings().motion, ChannelMotion.off);
    });

    testWidgets('不挪、不要帧，场景和视口一样大、在原位，只有一层', (t) async {
      await t.pumpWidget(_host(_data(ChannelMotion.off)));
      await t.pump();
      expect(await _framesDuring(t, const Duration(seconds: 3)), 0);
      expect(t.binding.transientCallbackCount, 0);
      expect(t.getSize(find.byKey(const Key('channel-backdrop'))), _viewport);
      expect(_sceneOffset(t), Offset.zero);
      expect(find.byKey(const Key('channel-annotations')), findsNothing);
      expect(_scenePainter(t).time, isNull, reason: '静止帧');
    });
  });

  group('防烧屏', () {
    testWidgets('每秒只出一帧，没有逐帧的 ticker', (t) async {
      await t.pumpWidget(_host(_data(ChannelMotion.antiBurnIn)));
      await t.pump();
      expect(t.binding.transientCallbackCount, 0);
      expect(await _framesDuring(t, const Duration(seconds: 5)), 5);
    });

    testWidgets('场景只画一次，挪动只改图层位置，一圈 9 格每次挪一格', (t) async {
      await t.pumpWidget(_host(_data(ChannelMotion.antiBurnIn)));
      await t.pump();
      final picture = _scenePicture(t);
      final origin = _sceneOffset(t);
      final step = ChannelBackdrop.shiftStep(2);
      expect(step, 1);
      // 四周各多画一格，挪的时候边上不露底
      expect(
        t.getSize(find.byKey(const Key('channel-backdrop'))),
        Size(_viewport.width + 2 * step, _viewport.height + 2 * step),
      );
      var last = origin;
      const orbit = ChannelBackdrop.shiftOrbit;
      for (var i = 1; i <= orbit.length; i++) {
        await t.pump(const Duration(seconds: 1));
        final now = _sceneOffset(t);
        expect(now - origin, orbit[i % orbit.length] * step, reason: '第 $i 秒');
        final moved = now - last;
        expect(moved.dx.abs(), lessThanOrEqualTo(step));
        expect(moved.dy.abs(), lessThanOrEqualTo(step));
        expect(moved, isNot(Offset.zero));
        expect(_scenePicture(t), same(picture), reason: '第 $i 秒没有重画场景');
        last = now;
      }
    });

    test('一格按物理像素取整', () {
      expect(ChannelBackdrop.shiftStep(1), 1);
      expect(ChannelBackdrop.shiftStep(2), 1);
      expect(ChannelBackdrop.shiftStep(1.25) * 1.25, 1);
      expect(ChannelBackdrop.shiftStep(1.5) * 1.5, 2);
      expect(ChannelBackdrop.shiftStep(3), 1);
    });

    testWidgets('生成中、系统减少动态效果：停下并回到原位', (t) async {
      final data = _data(ChannelMotion.antiBurnIn);
      await t.pumpWidget(_host(data));
      await t.pump(const Duration(seconds: 1));
      expect(_sceneOffset(t), isNot(Offset.zero));

      await t.pumpWidget(
        _host(_data(ChannelMotion.antiBurnIn, generating: true)),
      );
      await t.pump();
      expect(_sceneOffset(t), Offset.zero);
      expect(await _framesDuring(t, const Duration(seconds: 3)), 0);

      await t.pumpWidget(_host(data, reduceMotion: true));
      await t.pump();
      expect(_sceneOffset(t), Offset.zero);
      expect(await _framesDuring(t, const Duration(seconds: 3)), 0);
    });

    testWidgets('窗口看不见（TickerMode 关）时停在当前位置，回来接着挪', (t) async {
      final data = _data(ChannelMotion.antiBurnIn);
      await t.pumpWidget(_host(data));
      await t.pump(const Duration(seconds: 2));
      final paused = _sceneOffset(t);
      await t.pumpWidget(_host(data, tickers: false));
      await t.pump();
      expect(await _framesDuring(t, const Duration(seconds: 3)), 0);
      expect(_sceneOffset(t), paused);
      await t.pumpWidget(_host(data));
      await t.pump();
      expect(await _framesDuring(t, const Duration(seconds: 3)), 3);
    });
  });

  group('原本效果', () {
    testWidgets('最多约每秒 30 帧（原来画面就是 33ms 换一次），没有逐帧的 ticker', (t) async {
      await t.pumpWidget(_host(_data(ChannelMotion.original)));
      await t.pump();
      expect(t.binding.transientCallbackCount, 0);
      expect(ChannelBackdrop.frameInterval, const Duration(milliseconds: 33));
      // 每 4ms 推一次时间（相当于 250Hz 的屏幕）：原来每次都出一帧，现在只按 33ms 出
      final frames = await _framesDuring(
        t,
        const Duration(seconds: 1),
        step: const Duration(milliseconds: 4),
      );
      expect(frames, inInclusiveRange(28, 31));
    });

    testWidgets('场景跟着时间重画，上面的光台和时间刻度只录一次', (t) async {
      await t.pumpWidget(_host(_data(ChannelMotion.original)));
      await t.pump();
      final scene = _scenePicture(t);
      final annotations = _annotationPicture(t);
      final t0 = _scenePainter(t).time!.value;
      await t.pump(const Duration(milliseconds: 500));
      expect(_scenePicture(t), isNot(same(scene)), reason: '在动');
      expect(_annotationPicture(t), same(annotations), reason: '静止部分没重录');
      expect(_scenePainter(t).time!.value, greaterThan(t0 + .4));
      // 不挪位置（那是防烧屏）
      expect(_sceneOffset(t), Offset.zero);
      expect(t.getSize(find.byKey(const Key('channel-backdrop'))), _viewport);
    });

    testWidgets('拆成两层画出来和一起画逐像素一样（就是上游原来的画法）', (t) async {
      final data = _data(ChannelMotion.original);
      await t.pumpWidget(_host(data));
      await t.pump(const Duration(milliseconds: 700));
      final live = _scenePainter(t);
      final split = await _shot(t);
      // 同一时刻，用一张图把场景、光台、刻度一起画
      await t.pumpWidget(
        _app(
          CustomPaint(
            size: Size.infinite,
            painter: ChannelBackdropPainter(
              data: live.data,
              colors: live.colors,
              names: live.names,
              labels: live.labels,
              days: live.days,
              time: ValueNotifier(live.time!.value),
            ),
          ),
        ),
      );
      expect(await _shot(t), split);
    });

    testWidgets('生成中、减少动态效果：停在静止帧，不出帧', (t) async {
      await t.pumpWidget(
        _host(_data(ChannelMotion.original, generating: true)),
      );
      await t.pump();
      expect(_scenePainter(t).time, isNull, reason: '静止帧');
      expect(await _framesDuring(t, const Duration(seconds: 2)), 0);

      await t.pumpWidget(
        _host(_data(ChannelMotion.original), reduceMotion: true),
      );
      await t.pump();
      expect(_scenePainter(t).time, isNull);
      expect(await _framesDuring(t, const Duration(seconds: 2)), 0);
    });

    testWidgets('窗口看不见时停在这一帧，回来从停下的地方接着动', (t) async {
      final data = _data(ChannelMotion.original);
      await t.pumpWidget(_host(data));
      await t.pump(const Duration(seconds: 1));
      await t.pumpWidget(_host(data, tickers: false));
      await t.pump();
      final paused = _scenePainter(t).time!.value;
      expect(await _framesDuring(t, const Duration(seconds: 3)), 0);
      expect(_scenePainter(t).time!.value, paused);

      await t.pumpWidget(_host(data));
      await t.pump(const Duration(milliseconds: 500));
      final resumed = _scenePainter(t).time!.value;
      expect(resumed, greaterThan(paused));
      expect(resumed, lessThan(paused + 1), reason: '看不见的那 3 秒不算');
    });
  });

  test('老档位名之外的值都按关闭读（见存储迁移测试）', () {
    expect(ChannelMotion.values.map((m) => m.name), [
      'off',
      'antiBurnIn',
      'original',
    ]);
  });

  // 三档在两个平台上：藏到托盘 / 菜单栏、最小化时都停，叫回来继续；失焦照常
  for (final platform in [TargetPlatform.macOS, TargetPlatform.windows]) {
    for (final (motion, perSecond) in [
      (ChannelMotion.off, 0),
      (ChannelMotion.antiBurnIn, 1),
      (ChannelMotion.original, 30),
    ]) {
      testWidgets('${platform.name} · ${motion.name}：看不见时停，回来继续', (t) async {
        final sources = AppVisibilitySources(platform: platform);
        addTearDown(sources.detach);
        await t.pumpWidget(
          AppVisibilityScope(sources: sources, child: _host(_data(motion))),
        );
        await t.pump();
        Future<int> twoSeconds() => _framesDuring(
          t,
          const Duration(seconds: 2),
          step: const Duration(milliseconds: 11),
        );
        int near(int frames) => (frames / 2).round();

        expect(near(await twoSeconds()), closeTo(perSecond, 1));
        sources.markHidden();
        await t.pump();
        expect(await twoSeconds(), 0);
        sources.markShown();
        await t.pump();
        expect(near(await twoSeconds()), closeTo(perSecond, 1));

        sources.onWindowEvent('minimize');
        await t.pump();
        expect(await twoSeconds(), 0);
        sources.onWindowEvent('restore');
        await t.pump();
        sources.onWindowEvent('blur');
        await t.pump();
        expect(near(await twoSeconds()), closeTo(perSecond, 1));
      });
    }
  }

  testWidgets('macOS：被别的窗口完全挡住时三档都停（Runner 的遮挡通知）', (t) async {
    for (final motion in ChannelMotion.values) {
      final sources = AppVisibilitySources(platform: TargetPlatform.macOS);
      await t.pumpWidget(
        AppVisibilityScope(sources: sources, child: _host(_data(motion))),
      );
      await t.pump();
      await _occlusion(t, false);
      await t.pump();
      expect(
        await _framesDuring(t, const Duration(seconds: 2)),
        0,
        reason: motion.name,
      );
      await _occlusion(t, true);
      await t.pump();
      if (motion != ChannelMotion.off) {
        expect(
          await _framesDuring(t, const Duration(seconds: 2)),
          greaterThan(0),
          reason: motion.name,
        );
      }
      await t.pumpWidget(const SizedBox());
      sources.detach();
    }
  });
}
