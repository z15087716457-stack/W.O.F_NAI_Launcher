import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  testWidgets('preview is enlarged once and the page has one scale control', (
    t,
  ) async {
    double? original;
    for (final scale in [1.0, 1.3, 1.5]) {
      await t.pumpWidget(const SizedBox.shrink());
      final base = SettingsFixture.view(page: SettingsPageId.appearance);
      await pumpSettings(
        t,
        uiScale: scale,
        dark: true,
        data: base.copyWith(
          values: base.values.copyWith(SettingKey.uiScale, scale),
        ),
      );
      final sample = find.byKey(const Key('font-sample'));
      final title = find
          .descendant(of: sample, matching: find.byType(Text))
          .first;
      await t.ensureVisible(title);
      await t.pumpAndSettle();
      final widget = t.widget<Text>(title);
      expect(widget.style!.fontSize, 15);
      expect(MediaQuery.textScalerOf(t.element(title)).scale(15), 15);
      final height = t.getRect(title).height;
      original ??= height;
      expect(height, closeTo(original * scale, .001));
      expect(find.byType(SettingsSlider), findsOneWidget);
      expect(find.byKey(const Key('slider-uiScale')), findsOneWidget);
      expect(t.takeException(), isNull);

      final output = Platform.environment['UI_SCALE_CAPTURE'];
      if (output != null) {
        final section = find
            .ancestor(of: sample, matching: find.byType(SettingsSection))
            .first;
        await Scrollable.ensureVisible(t.element(section), alignment: .25);
        await t.pumpAndSettle();
        final rect = t.getRect(section);
        final boundary = t.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('settings-capture')),
        );
        await t.runAsync(() async {
          final bitmap = await boundary.toImage(pixelRatio: 1);
          final recorder = ui.PictureRecorder();
          Canvas(
            recorder,
          ).drawImageRect(bitmap, rect, Offset.zero & rect.size, Paint());
          final picture = recorder.endRecording();
          final cropped = await picture.toImage(
            rect.width.ceil(),
            rect.height.ceil(),
          );
          final bytes = await cropped.toByteData(
            format: ui.ImageByteFormat.png,
          );
          await Directory(output).create(recursive: true);
          await File(
            '$output/settings-${(scale * 100).round()}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          cropped.dispose();
          picture.dispose();
          bitmap.dispose();
        });
      }
    }
  });

  testWidgets('all settings pages fit a minimum window at 150%', (t) async {
    final errors = <String>[];
    for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
      for (final page in SettingsPageId.values) {
        await t.pumpWidget(const SizedBox());
        await pumpSettings(
          t,
          page: page,
          window: 800,
          uiScale: 1.5,
          locale: locale,
        );
        final error = t.takeException();
        if (error != null) errors.add('$locale / ${page.name}: $error');
      }
    }
    expect(errors, isEmpty);
  });

  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      testWidgets('whole settings layout $locale dark=$dark at scale limits', (
        t,
      ) async {
        for (final window in [800.0, 1600.0]) {
          for (final scale in [.8, 1.5]) {
            await t.pumpWidget(const SizedBox.shrink());
            await pumpSettings(
              t,
              page: SettingsPageId.appearance,
              window: window,
              locale: locale,
              dark: dark,
              uiScale: scale,
            );
            await t.ensureVisible(find.byKey(const Key('slider-uiScale')));
            await t.pumpAndSettle();
            final error = t.takeException();
            expect(error, isNull, reason: '$window / $scale\n$error');
          }
        }
      });
    }
  }
}
