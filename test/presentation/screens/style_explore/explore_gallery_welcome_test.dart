import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_gallery_welcome.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';

import '../../../helpers/studio_capture_fonts.dart';

void main() {
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
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(tester.getSize(find.byType(SvgPicture)).width, 300);
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
      final logo = tester.getRect(find.byType(SvgPicture));
      expect(bounds.contains(logo.topLeft), isTrue);
      expect(bounds.contains(logo.bottomRight), isTrue);
      expect(find.text('TIP'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
