import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_gallery_welcome.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/lab_logo_mark.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';

import '../../../helpers/studio_capture_fonts.dart';

void main() {
  testWidgets('LAB logo has binary edges at varied widths and screen scales', (
    tester,
  ) async {
    for (final background in [Colors.white, const Color(0xFF111111)]) {
      final backdrop = background == Colors.white ? 255 : 17;
      for (final width in [340.0, 214.4]) {
        for (final dpr in [1.0, 1.25, 1.5, 2.0]) {
          final key = GlobalKey();
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: RepaintBoundary(
                  key: key,
                  child: ColoredBox(
                    color: background,
                    child: Padding(
                      padding: const EdgeInsets.all(8.25),
                      child: LabLogoMark(width: width),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: dpr);
            final bytes = (await image.toByteData())!.buffer.asUint8List();
            var bluePixels = 0;
            // The outer RepaintBoundary sits at a fractional Center offset.
            // Its own white/dark edge is unrelated to the padded logo.
            final margin = (3 * dpr).ceil();
            for (var y = margin; y < image.height - margin; y++) {
              for (var x = margin; x < image.width - margin; x++) {
                final pixel = (y * image.width + x) * 4;
                final isBlue =
                    bytes[pixel] == 0 &&
                    bytes[pixel + 1] == 93 &&
                    bytes[pixel + 2] == 255 &&
                    bytes[pixel + 3] == 255;
                final isBackdrop =
                    bytes[pixel] == backdrop &&
                    bytes[pixel + 1] == backdrop &&
                    bytes[pixel + 2] == backdrop &&
                    bytes[pixel + 3] == 255;
                if (!isBlue && !isBackdrop) {
                  fail(
                    'Blended edge at pixel ${pixel ~/ 4} for '
                    '$width / DPR $dpr / $background: '
                    '${bytes.sublist(pixel, pixel + 4)}',
                  );
                }
                if (isBlue) bluePixels++;
              }
            }
            expect(bluePixels, greaterThan(1000));
            // These joins lie inside solid blue, away from exterior edges.
            // The W/O join at (761, 345) is the user's reported pale line.
            for (final join in const [Offset(761, 345), Offset(750, 385)]) {
              final x = ((8.25 + (join.dx - 130) * width / 1514) * dpr).floor();
              final y = ((8.25 + (join.dy - 96) * width / 1514) * dpr).floor();
              final pixel = (y * image.width + x) * 4;
              final actual = bytes.sublist(pixel, pixel + 4);
              expect(actual, [
                0,
                93,
                255,
                255,
              ], reason: 'solid join $join at width $width / DPR $dpr');
            }
            image.dispose();
          });
        }
      }
    }
  });

  for (final dark in [false, true]) {
    testWidgets('LAB welcome renders on ${dark ? 'dark' : 'light'} surfaces', (
      tester,
    ) async {
      await tester.runAsync(loadStudioCaptureFonts);
      final captureKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: dark ? GeistTheme.dark : GeistTheme.light,
          home: RepaintBoundary(
            key: captureKey,
            child: const Scaffold(body: ExploreGalleryWelcome()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('TIP'), findsOneWidget);
      expect(find.text('选择喜欢的候选，让画风逐代进化。'), findsOneWidget);
      expect(find.byType(LabLogoMark), findsOneWidget);
      expect(tester.getSize(find.byType(LabLogoMark)).width, 340);
      expect(tester.takeException(), isNull);
      if (Platform.environment['CAPTURE_LAB_WELCOME'] == '1') {
        await tester.runAsync(() async {
          final boundary =
              captureKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '.dart_tool/lab-welcome-${dark ? 'dark' : 'light'}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }

  testWidgets('narrow short gallery supports all locales and larger text', (
    tester,
  ) async {
    for (final locale in AppLocalizations.supportedLocales) {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: const Scaffold(
            body: SizedBox(
              width: 160,
              height: 180,
              child: ExploreGalleryWelcome(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final bounds = tester.getRect(find.byType(ExploreGalleryWelcome));
      final logo = tester.getRect(find.byType(LabLogoMark));
      expect(bounds.contains(logo.topLeft), isTrue);
      expect(bounds.contains(logo.bottomRight), isTrue);
      expect(find.text('TIP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
