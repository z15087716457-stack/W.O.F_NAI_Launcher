// 生图页左右两栏背后的模糊通道背景（GenerationPanelBackdropWiring）。
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/services/mac_display_options.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/canvas_channel_feed_provider.dart';
import 'package:nai_launcher/presentation/providers/canvas_channel_provider.dart';
import 'package:nai_launcher/presentation/providers/simple_output_viewer_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_feed_layout.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/generation_canvas_controller.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_contract.dart';
import 'package:nai_launcher/presentation/widgets/common/system_display_options_scope.dart';
import 'package:nai_launcher/presentation/wiring/generation_backdrop_wiring.dart';

class _Channel extends CanvasChannelNotifier {
  @override
  ChannelSettings build() => const ChannelSettings(
    mode: ChannelMode.fixed,
    fixed: ChannelTheme.stars,
    level: ChannelLevel.strong,
    seed: 7,
  );
}

class _Simple extends SimpleOutputViewerNotifier {
  @override
  bool build() => false;
}

class _Layout extends CanvasFeedLayoutNotifier {
  @override
  CanvasFeedLayoutResult build() => CanvasFeedLayoutResult(
    items: const [],
    groups: [CanvasFeedGroup(key: 'run:1', runId: 1, tiles: const [])],
    bounds: Rect.zero,
  );
}

/// 页面 1200×700，中间画布 300–900，左右两栏各 300 宽。
const backdropViewport = Rect.fromLTWH(300, 0, 600, 700);

ProviderContainer backdropContainer() => ProviderContainer(
  overrides: [
    canvasChannelNotifierProvider.overrideWith(_Channel.new),
    simpleOutputViewerNotifierProvider.overrideWith(_Simple.new),
    canvasFeedLayoutProvider.overrideWith(_Layout.new),
    canvasChannelFeedProvider.overrideWithValue(
      CanvasChannelFeed(batches: const [], now: DateTime(2026, 10, 30)),
    ),
  ],
);

Future<void> pumpBackdrop(
  WidgetTester tester,
  ProviderContainer container, {
  MacDisplayOptions? options,
  bool dark = false,
}) async {
  tester.view.physicalSize = const Size(1200, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: SystemDisplayOptionsScope(
        source: options ?? MacDisplayOptions(platform: TargetPlatform.windows),
        child: MaterialApp(
          theme: dark ? GeistTheme.dark : GeistTheme.light,
          themeAnimationDuration: Duration.zero,
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RepaintBoundary(
            key: Key('backdrop-capture'),
            child: GenerationPanelBackdropWiring(
              canvasViewport: backdropViewport,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  late ProviderContainer container;
  setUp(() => container = backdropContainer());
  tearDown(() => container.dispose());

  testWidgets('默认两栏都铺模糊的通道', (tester) async {
    await pumpBackdrop(tester, container);
    for (final side in ['left', 'right']) {
      final scene = find.byKey(ValueKey('gen-panel-backdrop-$side'));
      expect(scene, findsOneWidget);
      expect(
        find.ancestor(of: scene, matching: find.byType(ImageFiltered)),
        findsOneWidget,
      );
    }
  });

  testWidgets('系统「降低透明度」：两栏不透出模糊的通道（同高对比度）', (tester) async {
    final options = MacDisplayOptions(platform: TargetPlatform.windows)
      ..value = const SystemDisplayOptions(reduceTransparency: true);
    await pumpBackdrop(tester, container, options: options);
    expect(find.byKey(const ValueKey('gen-panel-backdrop-left')), findsNothing);
    expect(
      find.byKey(const ValueKey('gen-panel-backdrop-right')),
      findsNothing,
    );
    expect(find.byType(ImageFiltered), findsNothing);

    options.value = const SystemDisplayOptions();
    await tester.pump();
    expect(
      find.byKey(const ValueKey('gen-panel-backdrop-left')),
      findsOneWidget,
    );
  });

  group('停稳后两栏贴拍好的图', () {
    // 拍图前后的画面逐像素比
    Future<Uint8List> shot(WidgetTester tester) async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('backdrop-capture')),
      );
      return (await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        return data!.buffer.asUint8List();
      }))!;
    }

    /// 模糊图层还在不在合成树里：在 = 每次合成都要重做模糊。
    int blurLayers(WidgetTester tester) =>
        tester.layers.whereType<ImageFilterLayer>().length;

    testWidgets('停稳 300ms 后不再每帧重做模糊，样子逐像素不变', (tester) async {
      await pumpBackdrop(tester, container);
      expect(blurLayers(tester), 2, reason: '刚画出来时照常模糊');
      final live = await shot(tester);

      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(blurLayers(tester), 0, reason: '两栏都换成了拍好的图');
      expect(await shot(tester), live);
    });

    testWidgets('拖动画布时每帧照常跟着画，停下来再拍', (tester) async {
      await pumpBackdrop(tester, container);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(blurLayers(tester), 0);
      final before = await shot(tester);

      final camera = container.read(generationCanvasCameraProvider.notifier);
      for (var i = 1; i <= 5; i++) {
        camera.jump(
          CanvasCamera(offset: Offset(80, 40 - i * 37.0), scale: 1),
          notifyIdle: false,
        );
        await tester.pump(const Duration(milliseconds: 16));
        expect(blurLayers(tester), 2, reason: '拖动中第 $i 帧');
      }
      final moving = await shot(tester);
      expect(moving, isNot(before));

      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(blurLayers(tester), 0);
      expect(await shot(tester), moving);
    });

    testWidgets('换深色主题：旧图作废，停稳后拍新的', (tester) async {
      await pumpBackdrop(tester, container);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      final light = await shot(tester);

      await pumpBackdrop(tester, container, dark: true);
      expect(blurLayers(tester), 2);
      final dark = await shot(tester);
      expect(dark, isNot(light));

      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(blurLayers(tester), 0);
      expect(await shot(tester), dark);
    });
  });
}
