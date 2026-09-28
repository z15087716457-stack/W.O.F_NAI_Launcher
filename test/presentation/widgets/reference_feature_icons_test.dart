import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/common/collapsible_image_panel.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_animated_icon.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';

import '../../helpers/studio_capture_fonts.dart';

const _features = [
  (StudioIcons.imageToImage, '图生图', '基于底图生成变体'),
  (StudioIcons.styleTransfer, '风格迁移', '改变图像，保留视觉风格'),
  (StudioIcons.referenceFocus, '精准参考', '参考图中的角色、风格与视觉特征'),
];

void main() {
  testWidgets(
    'new feature glyphs match their animated silhouettes including fills',
    (tester) async {
      await tester.runAsync(
        () => (FontLoader(
          'StudioIcons',
        )..addFont(rootBundle.load('assets/fonts/StudioIcons.ttf'))).load(),
      );
      final key = GlobalKey();
      Future<List<int>> render(Widget child, String captureName) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: RepaintBoundary(
                key: key,
                child: SizedBox.square(dimension: 96, child: child),
              ),
            ),
          ),
        );
        await tester.pump();
        return (await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final data = await image.toByteData();
          final pixels = data!.buffer.asUint8List().toList();
          if (Platform.environment['CAPTURE_REFERENCE_FEATURES'] == '1') {
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            File(
              '.dart_tool/$captureName.png',
            ).writeAsBytesSync(png!.buffer.asUint8List());
          }
          image.dispose();
          return pixels;
        }))!;
      }

      for (final feature in _features) {
        final glyph = await render(
          Icon(feature.$1, size: 96, color: Colors.white),
          '${feature.$1.codePoint}-font',
        );
        final paths = await render(
          CustomPaint(
            painter: StudioIconPainter(
              icon: feature.$1,
              progress: const AlwaysStoppedAnimation(0),
              color: Colors.white,
            ),
          ),
          '${feature.$1.codePoint}-paths',
        );
        var intersection = 0;
        var union = 0;
        var unmatched = 0;
        // Text and Canvas use different edge antialiasing. Permit one raster
        // pixel at 4x size, while detecting missing fills or displaced parts.
        bool hasNeighbor(List<int> pixels, int x, int y) {
          for (var dy = -1; dy <= 1; dy++) {
            for (var dx = -1; dx <= 1; dx++) {
              final nx = x + dx;
              final ny = y + dy;
              if (nx >= 0 &&
                  nx < 96 &&
                  ny >= 0 &&
                  ny < 96 &&
                  pixels[(ny * 96 + nx) * 4 + 3] > 100) {
                return true;
              }
            }
          }
          return false;
        }

        for (var i = 3; i < glyph.length; i += 4) {
          final a = glyph[i] > 100;
          final b = paths[i] > 100;
          if (a || b) union++;
          if (a && b) intersection++;
          final pixel = i ~/ 4;
          if ((a && !hasNeighbor(paths, pixel % 96, pixel ~/ 96)) ||
              (b && !hasNeighbor(glyph, pixel % 96, pixel ~/ 96))) {
            unmatched++;
          }
        }
        expect(
          intersection / union,
          greaterThan(.85),
          reason: '${feature.$2} must not change silhouette on activation',
        );
        expect(
          unmatched / union,
          lessThan(.01),
          reason: '${feature.$2} has missing or displaced parts',
        );
      }
    },
  );

  if (Platform.environment['CAPTURE_REFERENCE_FEATURES'] == '1') {
    testWidgets('capture reference cards and motion frames in both themes', (
      tester,
    ) async {
      await tester.runAsync(() async {
        await loadStudioCaptureFonts();
        await (FontLoader(
          'StudioIcons',
        )..addFont(rootBundle.load('assets/fonts/StudioIcons.ttf'))).load();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
      await tester.binding.setSurfaceSize(const Size(900, 620));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final dark in [false, true]) {
        final key = GlobalKey();
        final theme = dark ? GeistTheme.dark : GeistTheme.light;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: RepaintBoundary(
                key: key,
                child: ColoredBox(
                  color: theme.scaffoldBackgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final feature in _features) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 380,
                                child: CollapsibleImagePanel(
                                  title: feature.$2,
                                  subtitle: feature.$3,
                                  icon: feature.$1,
                                  frosted: true,
                                  isExpanded: false,
                                  onToggle: () {},
                                  child: const SizedBox.shrink(),
                                ),
                              ),
                              const SizedBox(width: 25),
                              for (final t in [0.0, .25, .5, .75, 1.0])
                                Padding(
                                  padding: const EdgeInsets.all(11),
                                  child: CustomPaint(
                                    size: const Size.square(40),
                                    painter: StudioIconPainter(
                                      icon: feature.$1,
                                      progress: AlwaysStoppedAnimation(t),
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          children: [
                            for (final feature in _features)
                              Expanded(
                                child: CollapsibleImagePanel(
                                  title: feature.$2,
                                  icon: feature.$1,
                                  frosted: true,
                                  hasData: true,
                                  backgroundImage: const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xff1d5458),
                                          Color(0xff939771),
                                          Color(0xff645b85),
                                        ],
                                      ),
                                    ),
                                  ),
                                  isExpanded: false,
                                  onToggle: () {},
                                  child: const SizedBox.shrink(),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            for (final feature in _features)
                              Icon(feature.$1, size: 88),
                          ],
                        ),
                        const SizedBox(height: 26),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            for (final feature in _features)
                              Row(
                                children: [
                                  for (final size in [16.0, 22.0, 28.0])
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(feature.$1, size: size),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
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
          File(
            '.dart_tool/reference-features-${dark ? 'dark' : 'light'}.png',
          ).writeAsBytesSync(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}
