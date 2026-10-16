import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  testWidgets('原 SeedVR2 与 NVIDIA 标记跟随对应标题，五语言宽窄浅深均可见', (t) async {
    for (final locale in ['zh', 'en', 'ja', 'ko', 'zh_TW']) {
      for (final width in [900.0, 1600.0]) {
        await t.pumpWidget(const SizedBox.shrink());
        await pumpSettings(
          t,
          page: SettingsPageId.upscale,
          window: width,
          height: 2000,
          locale: locale,
          dark: width == 900,
        );
        await t.runAsync(
          () => precacheImage(
            const AssetImage('assets/icons/seedvr_logo.png'),
            t.element(find.byType(SettingsHost)),
          ),
        );
        await t.pumpAndSettle();
        expect(
          t
              .widget<RawImage>(
                find.descendant(
                  of: find.byKey(const Key('settings-upscale-seed-logo')),
                  matching: find.byType(RawImage),
                ),
              )
              .image,
          isNotNull,
        );
        final l = AppLocalizations.of(t.element(find.byType(SettingsHost)))!;
        for (final (key, title) in [
          ('settings-upscale-seed-logo', l.set_upSeed),
          ('settings-upscale-rtx-logo', l.set_upRtx),
        ]) {
          final logo = t.getRect(find.byKey(Key(key)));
          final section = find.ancestor(
            of: find.byKey(Key(key)),
            matching: find.byType(SettingsSection),
          );
          final text = t.getRect(
            find.descendant(of: section, matching: find.text(title)),
          );
          expect(logo.size, const Size(18, 18));
          expect(logo.left - text.right, closeTo(6, .001));
          expect(logo.center.dy, closeTo(text.center.dy, .001));
          expect(logo.right, lessThanOrEqualTo(width - settingsRail));
        }
        expect(t.takeException(), isNull);
        final output =
            Platform.environment['SETTINGS_UPSCALE_BRAND_CAPTURE_DIR'];
        if (output != null) {
          final box = t.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('settings-capture')),
          );
          await t.runAsync(() async {
            Directory(output).createSync(recursive: true);
            final image = await box.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            File(
              '$output/$locale-${width.toInt()}.png',
            ).writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
    }
  });
}
