import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/shortcuts/default_shortcuts.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/widgets/shortcuts/shortcut_tooltip.dart';

import '../../../helpers/studio_capture_fonts.dart';

class _Shortcuts extends ShortcutConfigNotifier {
  @override
  Future<ShortcutConfig> build() async => ShortcutConfig.createDefault();
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final dark in [false, true]) {
    for (final override in [false, true]) {
      testWidgets(
        'rich tooltip inherits foreground with dark=$dark override=$override',
        (tester) async {
          var theme = AppTheme.getTheme(
            AppStyle.geist,
            dark ? Brightness.dark : Brightness.light,
          );
          if (override) {
            theme = theme.copyWith(
              tooltipTheme: theme.tooltipTheme.copyWith(
                decoration: const BoxDecoration(color: Color(0xff193345)),
                textStyle: const TextStyle(
                  color: Color(0xffffefcf),
                  fontSize: 13,
                ),
              ),
            );
          }
          final captureKey = GlobalKey();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                shortcutConfigNotifierProvider.overrideWith(_Shortcuts.new),
              ],
              child: MaterialApp(
                theme: theme,
                locale: const Locale('zh'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) =>
                    RepaintBoundary(key: captureKey, child: child),
                home: const Scaffold(
                  body: Center(
                    child: ShortcutTooltip(
                      message: '多选',
                      shortcutId: ShortcutIds.enterSelectionMode,
                      waitDuration: Duration(milliseconds: 1),
                      child: SizedBox(
                        key: Key('trigger'),
                        width: 32,
                        height: 32,
                        child: Icon(Icons.check_box_outlined),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(location: Offset.zero);
          addTearDown(mouse.removePointer);
          await mouse.moveTo(
            tester.getCenter(find.byKey(const Key('trigger'))),
          );
          await tester.pumpAndSettle(const Duration(milliseconds: 100));
          expect(find.text('多选'), findsOneWidget);
          expect(find.text('Ctrl+A'), findsOneWidget);
          final background =
              (theme.tooltipTheme.decoration! as BoxDecoration).color!;
          for (final label in ['多选', 'Ctrl+A']) {
            final text = tester.widget<Text>(find.text(label));
            final color = text.style!.color!;
            expect(color, theme.tooltipTheme.textStyle!.color);
            final painted = Color.alphaBlend(color, background);
            final a = painted.computeLuminance(),
                b = background.computeLuminance();
            final contrast = a > b
                ? (a + .05) / (b + .05)
                : (b + .05) / (a + .05);
            expect(contrast, greaterThanOrEqualTo(4.5));
          }
          if (!override &&
              Platform.environment['CAPTURE_GALLERY_FEEDBACK'] == '1') {
            await tester.runAsync(() async {
              final boundary =
                  captureKey.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await boundary.toImage();
              final png = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              image.dispose();
              final dir = Directory(
                '.dart_tool/gallery-feedback-20261022/captures',
              );
              await dir.create(recursive: true);
              await File(
                '${dir.path}/tooltip-${dark ? 'dark' : 'light'}.png',
              ).writeAsBytes(png!.buffer.asUint8List());
            });
          }
          await mouse.moveTo(Offset.zero);
          await tester.pumpAndSettle(const Duration(seconds: 1));
          expect(find.text('多选'), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
