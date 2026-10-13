import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_contract.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/uiux_frontend_capture.dart';
import 'viewer_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      for (final pixels in [32, 64, 128, 512]) {
        testWidgets('loading $locale dark=$dark pixels=$pixels', (t) async {
          final data = ViewerViewData(
            mode: ViewerMode.gallery,
            currentKey: '08',
            now: DateTime(2026, 10, 13),
            infoOpen: false,
            items: [
              ViewerItem(
                key: '08',
                width: pixels,
                height: pixels,
                sizeBytes: pixels == 32 ? null : 2048000,
              ),
            ],
          );
          await pumpViewer(t, data: data, locale: locale, dark: dark);
          expect(t.takeException(), isNull);
          final loading = find.byKey(const Key('viewer-loading'));
          expect(loading, findsOneWidget);
          // Fit retains original pixels for small images.
          expect(
            t.getSize(loading),
            Size(pixels.toDouble(), pixels.toDouble()),
          );
          if (pixels == 32 || pixels == 128) {
            await captureUiuxRegion(
              t,
              find.byKey(const Key('viewer-capture')),
              'viewer-$locale-$dark-$pixels',
              t.getRect(loading).inflate(50),
            );
          }
          final message = AppLocalizations.of(t.element(loading))!;
          final text = pixels == 32
              ? message.imageViewer_loadingOriginal
              : message.imageViewer_loadingOriginalSize('1.95 MB');
          if (pixels == 32) {
            final gesture = await hoverOver(t, loading);
            await t.pump(const Duration(seconds: 1));
            expect(find.text(text), findsOneWidget);
            await gesture.moveTo(Offset.zero);
          }
          await t.pumpWidget(const SizedBox());
          expect(t.takeException(), isNull);
        });
      }
    }
  }
}
