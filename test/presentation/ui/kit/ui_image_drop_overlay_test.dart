import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_controls.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_image_drop_overlay.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_scale.dart';

import '../../../helpers/studio_capture_fonts.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  for (final locale in AppLocalizations.supportedLocales) {
    for (final brightness in Brightness.values) {
      for (final width in [320.0, 736.0]) {
        for (final scale in [1.0, 1.5]) {
          testWidgets('$locale $brightness width=$width scale=$scale', (
            t,
          ) async {
            await t.binding.setSurfaceSize(Size(width, 600));
            addTearDown(() => t.binding.setSurfaceSize(null));
            var taps = 0;
            Rect? draggingRect;
            for (final processing in [false, true]) {
              await t.pumpWidget(
                MaterialApp(
                  themeAnimationDuration: Duration.zero,
                  locale: locale,
                  theme: AppTheme.getTheme(AppStyle.geist, brightness),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (_, child) => UiScale(scale: scale, child: child!),
                  home: Scaffold(
                    body: Stack(
                      fit: StackFit.expand,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => taps++,
                          child: const SizedBox.expand(),
                        ),
                        UiImageDropOverlay(processing: processing),
                      ],
                    ),
                  ),
                ),
              );
              await t.pump(const Duration(milliseconds: 20));
              final context = t.element(find.byType(UiImageDropOverlay));
              expect(Theme.of(context).brightness, brightness);
              final l = AppLocalizations.of(context)!;
              final notice = t.getRect(
                find.byKey(const Key('image-drop-notice')),
              );
              expect(
                notice.width,
                closeTo(math.min(400 * scale, width - 48 * scale), .01),
              );
              expect(notice.center.dx, closeTo(width / 2, .01));
              expect(notice.center.dy, closeTo(300, .01));
              expect(notice.height, greaterThanOrEqualTo(180 * scale));
              expect(notice.top, greaterThanOrEqualTo(24 * scale));
              expect(notice.bottom, lessThanOrEqualTo(600 - 24 * scale));
              final icon = t.getRect(find.byKey(const Key('image-drop-icon')));
              expect(icon.size, Size.square(40 * scale));
              expect(icon.center.dx, closeTo(notice.center.dx, .01));
              for (final text in [
                processing ? l.drop_processing : l.drop_hint,
                processing ? l.drop_processingSubtitle : l.drop_hintSubtitle,
              ]) {
                final bounds = t.getRect(find.text(text));
                expect(notice.contains(bounds.topLeft), isTrue);
                expect(notice.contains(bounds.bottomRight), isTrue);
              }
              if (!processing) draggingRect = notice;
              expect(notice, draggingRect);
              final backdropFinder = find.byKey(
                const Key('image-drop-backdrop'),
              );
              expect(t.getRect(backdropFinder), Offset.zero & Size(width, 600));
              expect(
                t.widget<ColoredBox>(backdropFinder).color,
                Colors.black.withValues(alpha: .4),
              );
              expect(
                find.byType(UiSpinner),
                processing ? findsOneWidget : findsNothing,
              );
              final countBefore = taps;
              await t.tapAt(const Offset(20, 20));
              await t.pump();
              expect(taps, countBefore + (processing ? 0 : 1));
              expect(t.takeException(), isNull);
            }
            await t.pumpWidget(const SizedBox());
          });
        }
      }
    }
  }
}
