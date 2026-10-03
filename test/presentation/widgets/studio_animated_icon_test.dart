import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_animated_icon.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';

const _icons = <String, IconData>{
  '生图': StudioIcons.generation,
  '画风遗传': StudioIcons.styleExplore,
  '本地画廊': StudioIcons.localGallery,
  '在线画廊': StudioIcons.onlineGallery,
  '提示词块': StudioIcons.promptBlocks,
  'Vibe 库': StudioIcons.vibeLibrary,
  '精准参考': StudioIcons.preciseReference,
  '统计': StudioIcons.statistics,
  '设置': StudioIcons.settings,
  '遗传按钮': StudioIcons.inherit,
  '积木悬浮窗': StudioIcons.promptBlockPalette,
  '图生图': StudioIcons.imageToImage,
  '风格迁移': StudioIcons.styleTransfer,
  '参考聚焦': StudioIcons.referenceFocus,
  '标签百科': StudioIcons.tagWiki,
};

Finder get _painting => find.byWidgetPredicate(
  (widget) => widget is CustomPaint && widget.painter is StudioIconPainter,
);

Widget _host(
  IconData icon,
  int trigger, {
  bool reduce = false,
  bool ticking = true,
  bool preferenceReduced = false,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduce),
      child: TickerMode(
        enabled: ticking,
        child: Center(
          child: StudioAnimatedIcon(
            icon: icon,
            trigger: trigger,
            reducedMotion: preferenceReduced,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Wiki reduced-motion preference cancels without replay', (
    tester,
  ) async {
    await tester.pumpWidget(_host(StudioIcons.tagWiki, 0));
    await tester.pumpWidget(_host(StudioIcons.tagWiki, 1));
    await tester.pump(const Duration(milliseconds: 120));
    expect(_painting, findsOneWidget);
    await tester.pumpWidget(
      _host(StudioIcons.tagWiki, 1, preferenceReduced: true),
    );
    expect(_painting, findsNothing);
    await tester.pumpWidget(
      _host(StudioIcons.tagWiki, 2, preferenceReduced: true),
    );
    await tester.pumpWidget(_host(StudioIcons.tagWiki, 2));
    expect(_painting, findsNothing);
    await tester.pumpWidget(_host(StudioIcons.tagWiki, 3));
    expect(_painting, findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });
  for (final entry in _icons.entries) {
    testWidgets(
      '${entry.key}: idle has no ticker, activation plays once and settles',
      (tester) async {
        await tester.pumpWidget(_host(entry.value, 0));
        await tester.pumpAndSettle();
        expect(_painting, findsNothing);
        expect(tester.binding.transientCallbackCount, 0);
        await tester.pumpWidget(_host(entry.value, 1));
        await tester.pump(const Duration(milliseconds: 120));
        expect(_painting, findsOneWidget);
        final painter =
            tester.widget<CustomPaint>(_painting).painter! as StudioIconPainter;
        expect(painter.progress.value, greaterThan(0));
        await tester.pumpAndSettle();
        expect(_painting, findsNothing);
        expect(find.byIcon(entry.value), findsOneWidget);
        expect(tester.binding.transientCallbackCount, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'rapid triggers neither restart nor queue; dispose cancels ticker',
    (tester) async {
      await tester.pumpWidget(_host(StudioIcons.generation, 0));
      await tester.pumpWidget(_host(StudioIcons.generation, 1));
      await tester.pump(const Duration(milliseconds: 200));
      final painter =
          tester.widget<CustomPaint>(_painting).painter! as StudioIconPainter;
      final before = painter.progress.value;
      for (var i = 2; i < 12; i++) {
        await tester.pumpWidget(_host(StudioIcons.generation, i));
      }
      expect(painter.progress.value, closeTo(before, .001));
      await tester.pump(const Duration(milliseconds: 450));
      expect(_painting, findsNothing);
      await tester.pumpWidget(_host(StudioIcons.generation, 12));
      expect(_painting, findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reduced motion and hidden retained pages cancel and do not replay stale clicks',
    (tester) async {
      await tester.pumpWidget(_host(StudioIcons.settings, 0, reduce: true));
      await tester.pumpWidget(_host(StudioIcons.settings, 1, reduce: true));
      expect(_painting, findsNothing);
      await tester.pumpWidget(_host(StudioIcons.settings, 1));
      expect(_painting, findsNothing);
      await tester.pumpWidget(_host(StudioIcons.settings, 2));
      await tester.pump(const Duration(milliseconds: 80));
      expect(_painting, findsOneWidget);
      await tester.pumpWidget(_host(StudioIcons.settings, 2, ticking: false));
      expect(_painting, findsNothing);
      await tester.pumpWidget(_host(StudioIcons.settings, 3, ticking: false));
      await tester.pumpWidget(_host(StudioIcons.settings, 3));
      expect(_painting, findsNothing);
      await tester.pumpWidget(_host(StudioIcons.settings, 4));
      expect(_painting, findsOneWidget);
      await tester.pumpWidget(_host(StudioIcons.settings, 4, reduce: true));
      expect(_painting, findsNothing);
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets(
    'all paths return to their starting silhouette and stay inside a 32px envelope',
    (tester) async {
      final key = GlobalKey();
      Future<ui.Image> render(
        IconData icon,
        double t, {
        double size = 24,
      }) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: RepaintBoundary(
                key: key,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: CustomPaint(
                    size: Size.square(size),
                    painter: StudioIconPainter(
                      icon: icon,
                      progress: AlwaysStoppedAnimation(t),
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        return tester
            .runAsync(
              () =>
                  (key.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage(pixelRatio: 3),
            )
            .then((value) => value!);
      }

      for (final entry in _icons.entries) {
        final first = await render(entry.value, 0);
        final last = await render(entry.value, 1);
        final a = (await tester.runAsync(
          () => first.toByteData(),
        ))!.buffer.asUint8List();
        final b = (await tester.runAsync(
          () => last.toByteData(),
        ))!.buffer.asUint8List();
        var different = 0;
        for (var i = 3; i < a.length; i += 4) {
          if ((a[i] - b[i]).abs() > 16) different++;
        }
        expect(
          different,
          lessThan(30),
          reason: '${entry.key} must not jump on return',
        );
        first.dispose();
        last.dispose();
        if (entry.value == StudioIcons.tagWiki) {
          final idle = await render(entry.value, 0, size: 20);
          final peak = await render(entry.value, .32, size: 20);
          final idlePixels = (await tester.runAsync(
            () => idle.toByteData(),
          ))!.buffer.asUint8List();
          final peakPixels = (await tester.runAsync(
            () => peak.toByteData(),
          ))!.buffer.asUint8List();
          var inkPixels = 0;
          var changedPixels = 0;
          for (var i = 3; i < idlePixels.length; i += 4) {
            if (idlePixels[i] > 16) inkPixels++;
            if ((idlePixels[i] - peakPixels[i]).abs() > 32) changedPixels++;
          }
          expect(
            changedPixels,
            greaterThan(inkPixels * .45),
            reason:
                'The actual 20px Wiki icon needs a clearly visible click gesture.',
          );
          idle.dispose();
          peak.dispose();
        }
        for (final t
            in entry.value == StudioIcons.tagWiki
                ? [.1, .2, .3, .4, .5, .6, .7, .8, .9]
                : [.2, .4, .6, .8]) {
          final image = await render(entry.value, t);
          final pixels = (await tester.runAsync(
            () => image.toByteData(),
          ))!.buffer.asUint8List();
          for (var i = 0; i < image.width; i++) {
            expect(
              pixels[i * 4 + 3],
              0,
              reason: '${entry.key}: top overflow at $t',
            );
            expect(pixels[((image.height - 1) * image.width + i) * 4 + 3], 0);
          }
          for (var i = 0; i < image.height; i++) {
            expect(pixels[(i * image.width) * 4 + 3], 0);
            expect(pixels[(i * image.width + image.width - 1) * 4 + 3], 0);
          }
          image.dispose();
        }
      }
    },
  );

  if (Platform.environment['CAPTURE_STUDIO_ICON_MOTION'] == '1') {
    testWidgets('capture actual vector frames, themes and small icons', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await (FontLoader(
          'StudioIcons',
        )..addFont(rootBundle.load('assets/fonts/StudioIcons.ttf'))).load();
        await (FontLoader('Harmony')..addFont(
              rootBundle.load('assets/fonts/HarmonyOS_Sans_SC_Regular.ttf'),
            ))
            .load();
      });
      await tester.binding.setSurfaceSize(const Size(980, 820));
      for (final dark in [false, true]) {
        final key = GlobalKey();
        final fg = dark ? const Color(0xffededed) : const Color(0xff71767d);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RepaintBoundary(
                key: key,
                child: ColoredBox(
                  color: dark ? const Color(0xff111111) : Colors.white,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      for (final entry in _icons.entries)
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              SizedBox(
                                width: 110,
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontFamily: 'Harmony',
                                    color: fg,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Icon(entry.value, size: 40, color: fg),
                              for (final t in [0.0, .25, .5, .75, 1.0])
                                CustomPaint(
                                  size: const Size.square(40),
                                  painter: StudioIconPainter(
                                    icon: entry.value,
                                    progress: AlwaysStoppedAnimation(t),
                                    color: const Color(0xff0866ff),
                                  ),
                                ),
                              for (final s in [24.0, 18.0, 12.0])
                                Icon(entry.value, size: s, color: fg),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 1.5);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final folder = Platform.environment['CAPTURE_WIKI_MOTION'] == '1'
              ? 'wiki-motion-captures/'
              : Platform.environment['CAPTURE_WIKI_POLISH'] == '1'
              ? 'wiki-polish-captures/'
              : '';
          File(
            '.dart_tool/${folder}studio-motion-${dark ? 'dark' : 'light'}.png',
          ).writeAsBytesSync(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.binding.setSurfaceSize(null);
    });
  }
}
