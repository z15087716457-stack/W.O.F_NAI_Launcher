import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/widgets/branding/brand_logo.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  for (final (width, dark) in [(1600.0, false), (900.0, true)]) {
    testWidgets('关于页完整长方形 Logo $width $dark', (t) async {
      await pumpSettings(
        t,
        page: SettingsPageId.about,
        window: width,
        dark: dark,
      );
      final logo = find.byType(BrandLogo);
      expect(logo, findsOneWidget);
      final image = t.widget<Image>(
        find.descendant(of: logo, matching: find.byType(Image)),
      );
      expect(
        (image.image as AssetImage).assetName,
        'assets/images/wof_logo_full.png',
      );
      expect(image.fit, BoxFit.contain);
      await t.runAsync(() => precacheImage(image.image, t.element(logo)));
      await t.pumpAndSettle();
      final raw = t.widget<RawImage>(
        find.descendant(of: logo, matching: find.byType(RawImage)),
      );
      expect(raw.image, isNotNull);
      expect(raw.image!.width / raw.image!.height, closeTo(1111 / 547, .001));
      final bounds = t.getRect(logo);
      final slot = t.getRect(find.byKey(const Key('about-brand-slot')));
      final name = t.getRect(find.byKey(const Key('about-brand-name')));
      expect(slot.size, const Size(112, 56));
      expect(bounds.width / bounds.height, closeTo(1111 / 547, .001));
      expect(bounds.center, slot.center);
      expect(name.left - slot.right, 16);
      expect(find.text('W'), findsNothing);
      expect(t.takeException(), isNull);
      final output = Platform.environment['ABOUT_BRAND_CAPTURE_DIR'];
      if (output != null) {
        final box = t.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('settings-capture')),
        );
        await t.runAsync(() async {
          Directory(output).createSync(recursive: true);
          final bitmap = await box.toImage(pixelRatio: 1);
          final bytes = await bitmap.toByteData(format: ui.ImageByteFormat.png);
          File(
            '$output/about-${width.toInt()}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          bitmap.dispose();
        });
      }
    });
  }
}
