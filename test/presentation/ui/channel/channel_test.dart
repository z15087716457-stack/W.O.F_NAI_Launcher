import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_contract.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_fixture.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_format.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_geometry.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_layer.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture_editor.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';

import '../gen/gen_test_harness.dart';
import 'channel_test_harness.dart';

Future<void> _openDisplay(WidgetTester t) => tapKey(t, 'gen-display');

void main() {
  group('几何与随机', () {
    test('同一种子顺序固定，换种子会变', () {
      final a = ChannelEnv.orderFor(ChannelSettings.allThemes, 7);
      expect(ChannelEnv.orderFor(ChannelSettings.allThemes, 7), a);
      expect(a.toSet(), ChannelSettings.allThemes);
      final others = {
        for (var s = 1; s < 20; s++)
          ChannelEnv.orderFor(ChannelSettings.allThemes, s).join(),
      };
      expect(others.length, greaterThan(5));
    });

    test('池子过滤；少于两个时用全部', () {
      final pool = {ChannelTheme.stars, ChannelTheme.wave};
      expect(ChannelEnv.orderFor(pool, 3).toSet(), pool);
      expect(
        ChannelEnv.orderFor({ChannelTheme.herb}, 3).toSet(),
        ChannelSettings.allThemes,
      );
    });

    test('随机数在 [0,1) 且可复现', () {
      final r1 = ChannelRng(channelHash(['x', 1, -5])),
          r2 = ChannelRng(channelHash(['x', 1, -5]));
      for (var i = 0; i < 200; i++) {
        final v = r1();
        expect(v, inInclusiveRange(0, 1));
        expect(v, lessThan(1));
        expect(r2(), v);
      }
      expect(channelHash(['a']), isNot(channelHash(['b'])));
    });

    test('过渡层中心权重 0，段中间权重 1', () {
      const k = 2;
      final zs = ChannelGeo.zoneStart(k);
      expect(ChannelGeo.zoneWeight(k, zs), 0);
      expect(ChannelGeo.zoneWeight(k, zs + ChannelGeo.zone / 2), 1);
      expect(ChannelGeo.zoneOf(zs + 1), k);
      expect(ChannelGeo.zoneOf(zs - 1), k - 1);
    });

    test('最新一批（世界 y≈0）落在第 0 段主体里', () {
      const y = 0 / ChannelGeo.decorScale;
      expect(ChannelGeo.zoneOf(y), 0);
      expect(ChannelGeo.zoneWeight(0, y), 1);
    });

    test('固定模式：每段同一主题、权重恒为 1', () {
      final env = ChannelEnv.of(
        channelSettings(mode: ChannelMode.fixed, fixed: ChannelTheme.abyss),
      );
      expect(
        {for (var k = -3; k < 3; k++) env.themeOf(k)},
        {ChannelTheme.abyss},
      );
      expect(env.weight(1, ChannelGeo.zoneStart(1)), 1);
    });

    test('相机换算互逆', () {
      const cam = ChannelCamera(offset: Offset(461, 500), scale: .72);
      const p = Offset(-300, 1250);
      final back = cam.screenToWorld(cam.worldToScreen(p));
      expect((back - p).distance, lessThan(1e-9));
    });
  });

  group('文案', () {
    testWidgets('换日与批次标签', (t) async {
      late BuildContext ctx;
      await t.pumpWidget(
        genApp(Builder(builder: (c) => (ctx = c, const SizedBox()).$2)),
      );
      final now = DateTime(2026, 10, 14, 23, 20);
      expect(ChannelFormat.day(ctx, now, now), '今天 · 10月14日 周三');
      expect(
        ChannelFormat.day(ctx, DateTime(2026, 10, 13, 9), now),
        '昨天 · 10月13日 周二',
      );
      expect(
        ChannelFormat.day(ctx, DateTime(2026, 10, 11, 9), now),
        '10月11日 周日',
      );
      final b = ChannelBatch(id: 'b', rect: Rect.zero, time: now, count: 4);
      expect(ChannelFormat.batch(ctx, b, newest: true), '23:20 · 4 张 · 最新');
      expect(ChannelFormat.batch(ctx, b, newest: false), '23:20 · 4 张');
      expect(
        ChannelFormat.batch(
          ctx,
          const ChannelBatch(id: 'p', rect: Rect.zero, count: 2, pending: true),
          newest: true,
        ),
        '生成中 · 2 张',
      );
    });
  });

  group('显示设置里的视觉通道', () {
    testWidgets('不给通道设置时弹层照旧（宽 260、没有这一节）', (t) async {
      await pumpGen(t, data: GenFixture.view());
      await _openDisplay(t);
      expect(find.byKey(const Key('channel-settings')), findsNothing);
      expect(
        t.getSize(find.byKey(const Key('gen-display-popover'))).width,
        260,
      );
    });

    testWidgets('模式、卡片、浓淡、开关都回调', (t) async {
      final calls = await pumpChannel(t);
      await _openDisplay(t);
      expect(find.byKey(const Key('channel-settings')), findsOneWidget);
      expect(
        t.getSize(find.byKey(const Key('gen-display-popover'))).width,
        316,
      );
      expect(find.text('视觉通道'), findsOneWidget);
      expect(find.byKey(const Key('channel-sequence')), findsOneWidget);

      await tapKey(t, 'channel-mode-fixed');
      expect(calls.last, contains('ChannelSettings(fixed,'));
      await tapKey(t, 'channel-card-arcade');
      expect(calls.last, contains('fixed: arcade'));
      expect(find.textContaining('俯视的教堂平面图'), findsOneWidget);

      await tapKey(t, 'channel-level-strong');
      expect(calls.last, contains('strong,'));
      await tapKey(t, 'channel-ruler');
      expect(calls.last, contains('ruler: false'));
      await tapKey(t, 'channel-motion');
      expect(calls.last, contains('motion: false'));
    });

    testWidgets('随机：去掉主题、至少留两个、换一组', (t) async {
      final calls = await pumpChannel(
        t,
        settings: channelSettings(
          pool: {ChannelTheme.stars, ChannelTheme.herb, ChannelTheme.wave},
        ),
      );
      await _openDisplay(t);
      await tapKey(t, 'channel-card-wave');
      expect(calls.last, contains('pool: [stars, herb]'));
      final n = calls.length;
      await tapKey(t, 'channel-card-herb');
      expect(calls.length, n, reason: '只剩两个时不再去掉');
      expect(find.text('随机至少保留两个主题'), findsOneWidget);
      await t.pump(const Duration(seconds: 2));
      expect(find.text('随机至少保留两个主题'), findsNothing);
      await tapKey(t, 'channel-card-circuit');
      expect(calls.last, contains('pool: [circuit, stars, herb]'));

      await tapKey(t, 'channel-reroll');
      expect(calls.last, isNot(contains('seed: $channelSeed')));
    });

    testWidgets('关闭时卡片和开关不可点', (t) async {
      final calls = await pumpChannel(
        t,
        settings: channelSettings(mode: ChannelMode.off),
      );
      await _openDisplay(t);
      expect(find.text('关闭后保留现在的像素底纹'), findsOneWidget);
      final n = calls.length;
      await t.tap(
        find.byKey(const Key('channel-card-stars')),
        warnIfMissed: false,
      );
      await t.tap(find.byKey(const Key('channel-ruler')), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(calls.length, n);
      await tapKey(t, 'channel-mode-random');
      expect(calls.last, contains('ChannelSettings(random,'));
    });

    testWidgets('生成中写“动画已暂停”', (t) async {
      await pumpChannel(t, generating: true);
      await _openDisplay(t);
      expect(find.text('生成中 · 动画已暂停'), findsOneWidget);
    });
  });

  group('画布上的通道', () {
    testWidgets('进入提示：随机时出现、4.2 秒后收起；固定时不出', (t) async {
      final calls = <String>[];
      await t.pumpWidget(
        genApp(ChannelHost(initial: channelSettings(), calls: calls)),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('channel-toast')), findsOneWidget);
      expect(find.text('本次通道'), findsOneWidget);
      await t.pump(const Duration(seconds: 5));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('channel-toast')), findsNothing);

      await pumpChannel(t, settings: channelSettings(mode: ChannelMode.fixed));
      expect(find.byKey(const Key('channel-toast')), findsNothing);
    });

    testWidgets('刻度条：点一下跳过去，悬停出主题和时间', (t) async {
      final calls = await pumpChannel(t);
      final bar = find.byKey(const Key('channel-scrubber'));
      expect(bar, findsOneWidget);
      final r = t.getRect(bar);
      await t.tapAt(Offset(r.center.dx, r.top + r.height * .6));
      await t.pump();
      expect(calls.where((c) => c.startsWith('onJumpTo(')), hasLength(1));

      await hoverOver(t, bar);
      expect(find.byKey(const Key('channel-scrub-tip')), findsOneWidget);
    });

    testWidgets('关掉时间刻度后没有刻度条', (t) async {
      await pumpChannel(t, settings: channelSettings(ruler: false));
      expect(find.byKey(const Key('channel-scrubber')), findsNothing);
    });

    testWidgets('滚轮上下翻、Ctrl+滚轮缩放（假画布）', (t) async {
      await pumpChannel(t);
      final canvas = find.byKey(const Key('channel-fixture-canvas'));
      final before = t.getRect(find.byType(Image).first);
      final p = t.getCenter(canvas);
      await t.sendEventToBinding(
        PointerScrollEvent(position: p, scrollDelta: const Offset(0, 300)),
      );
      await t.pump();
      final after = t.getRect(find.byType(Image).first);
      expect(after.top, lessThan(before.top));
    });

    testWidgets('空闲微动：开着且没在生成时 ticker 在跑，生成中停', (t) async {
      Widget host({required bool generating}) => MaterialApp(
        theme: GeistTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: ChannelBackdrop(
            data: ChannelViewData(
              settings: channelSettings(),
              camera: const ChannelCamera(offset: Offset(400, 300), scale: .5),
              batches: [for (final g in ChannelFixture.groups()) g.batch],
              now: ChannelFixture.now,
              generating: generating,
            ),
          ),
        ),
      );
      await t.pumpWidget(host(generating: false));
      expect(SchedulerBinding.instance.transientCallbackCount, greaterThan(0));
      await t.pumpWidget(host(generating: true));
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
    });

    testWidgets('六个主题在各种缩放、明暗、钉板下都能画', (t) async {
      for (final dark in [false, true]) {
        for (final th in ChannelTheme.values) {
          for (final (scale, y) in [
            (.02, 0.0),
            (.15, 4000.0),
            (.72, -9000.0),
            (4.0, 20000.0),
          ]) {
            await t.pumpWidget(
              MaterialApp(
                theme: dark ? GeistTheme.dark : GeistTheme.light,
                home: ChannelBackdrop(
                  data: ChannelViewData(
                    settings: channelSettings(
                      mode: ChannelMode.fixed,
                      fixed: th,
                      level: ChannelLevel.strong,
                    ),
                    camera: ChannelCamera(
                      offset: Offset(400, 300 - y * scale),
                      scale: scale,
                    ),
                    batches: [for (final g in ChannelFixture.groups()) g.batch],
                    now: ChannelFixture.now,
                    pinboard: const Rect.fromLTWH(-2900, -400, 1000, 3000),
                  ),
                ),
              ),
            );
            expect(t.takeException(), isNull);
          }
        }
      }
    });

    testWidgets('随机模式跨过过渡层也能画', (t) async {
      await pumpChannel(t, focusY: 4012, focusScale: .35);
      expect(t.takeException(), isNull);
      await pumpChannel(t, overview: true);
      expect(t.takeException(), isNull);
    });
  });

  testWidgets('GenActions.withChannel 只换通道回调', (t) async {
    final calls = <String>[];
    final a = GenActions.logging(calls.add);
    final b = a.withChannel(null);
    expect(b.onChannelChanged, isNull);
    b.onGenerate();
    expect(calls, ['onGenerate']);
    await t.pumpWidget(
      genApp(
        GenerationPage(
          data: GenFixture.view(),
          actions: b,
          slots: const GenSlots(editor: GenFixtureEditor.builder),
        ),
      ),
    );
  });
}
