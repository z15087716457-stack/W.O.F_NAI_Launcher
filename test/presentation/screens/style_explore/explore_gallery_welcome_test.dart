import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/tips_provider.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_gallery_welcome.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';

import '../../../helpers/studio_capture_fonts.dart';

void main() {
  testWidgets('solid pixel joins have no antialiased internal seams', (
    tester,
  ) async {
    for (final background in [Colors.white, const Color(0xFF111111)]) {
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
                      child: SvgPicture.asset(
                        'assets/images/wof_nai_lab.svg',
                        width: width,
                        height: width * 657 / 1514,
                      ),
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
            final bytes = (await image.toByteData())!;
            // These joins lie inside solid blue, away from exterior edges.
            // The W/O join at (761, 345) is the user's reported pale line.
            for (final join in const [Offset(761, 345), Offset(750, 385)]) {
              final x = ((8.25 + (join.dx - 130) * width / 1514) * dpr).floor();
              final y = ((8.25 + (join.dy - 96) * width / 1514) * dpr).floor();
              final pixel = (y * image.width + x) * 4;
              final actual = List.generate(4, (i) => bytes.getUint8(pixel + i));
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
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: dark ? GeistTheme.dark : GeistTheme.light,
            home: RepaintBoundary(
              key: captureKey,
              child: const Scaffold(body: ExploreGalleryWelcome()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final zh = lookupAppLocalizations(const Locale('zh'));
      final text = tester
          .widget<Text>(find.byKey(const Key('tip-welcome-text')))
          .data;
      expect(
        tipsFor(TipSurface.lab).map((tip) => tip.text(zh)),
        contains(text),
      );
      expect(find.byKey(const Key('tip-welcome-label')), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(tester.getSize(find.byType(SvgPicture)).width, 340);
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
        ProviderScope(
          child: MaterialApp(
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
        ),
      );
      await tester.pumpAndSettle();
      final bounds = tester.getRect(find.byType(ExploreGalleryWelcome));
      final logo = tester.getRect(find.byType(SvgPicture));
      expect(bounds.contains(logo.topLeft), isTrue);
      expect(bounds.contains(logo.bottomRight), isTrue);
      expect(find.byKey(const Key('tip-welcome-label')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
