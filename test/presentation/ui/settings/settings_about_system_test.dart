import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

const _os = '"Windows 10 Pro" 10.0 (Build 26300)';
const _longId =
    '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

void main() {
  setUpAll(loadStudioCaptureFonts);

  testWidgets('长系统信息自动换行，标签不挤压，五语言宽窄与大字号不越界', (t) async {
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    for (final locale in ['zh', 'en', 'ja', 'ko', 'zh_TW']) {
      for (final (width, scale) in [
        (1600.0, 1.0),
        (900.0, 1.0),
        (1600.0, 1.5),
      ]) {
        await t.pumpWidget(const SizedBox.shrink());
        t.platformDispatcher.textScaleFactorTestValue = scale;
        await pumpSettings(
          t,
          data: _longSystemData(),
          window: width,
          height: 1400,
          locale: locale,
          dark: width == 900,
        );
        final card = find.byKey(const Key('about-system'));
        final bounds = t.getRect(card);
        Rect? previous;
        for (final (label, value) in [
          ('OS', _os),
          ('Dart', '3.13.5'),
          ('ID', _longId),
        ]) {
          final labelBox = t.getRect(
            find.descendant(of: card, matching: find.text(label)),
          );
          final valueFinder = find.descendant(
            of: card,
            matching: find.text(value),
          );
          final valueBox = t.getRect(valueFinder);
          expect(valueBox.left - labelBox.right, closeTo(12, .001));
          expect(valueBox.top, labelBox.top);
          expect(labelBox.left, greaterThan(bounds.left));
          expect(valueBox.right, lessThan(bounds.right));
          expect(valueBox.bottom, lessThan(bounds.bottom));
          expect(labelBox.height, closeTo(17 * scale, 1));
          expect(
            t.renderObject<RenderParagraph>(valueFinder).didExceedMaxLines,
            isFalse,
          );
          if (previous != null) {
            expect(valueBox.top, greaterThan(previous.bottom));
          }
          if (width == 1600 && value != '3.13.5') {
            expect(valueBox.height, greaterThan(labelBox.height));
          }
          previous = valueBox;
        }
        expect(t.takeException(), isNull);
        final output = Platform.environment['ABOUT_SYSTEM_CAPTURE_DIR'];
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
              '$output/$locale-${width.toInt()}-$scale.png',
            ).writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
    }
  });
}

SettingsViewData _longSystemData() {
  final d = SettingsFixture.view(page: SettingsPageId.about);
  return SettingsViewData(
    page: d.page,
    values: d.values,
    now: d.now,
    version: d.version,
    options: d.options,
    account: d.account,
    canvas: d.canvas,
    shortcuts: d.shortcuts,
    generation: d.generation,
    storage: d.storage,
    dictionaries: d.dictionaries,
    models: d.models,
    agent: d.agent,
    rag: d.rag,
    upscale: d.upscale,
    bridges: d.bridges,
    network: d.network,
    privacy: d.privacy,
    backup: d.backup,
    about: const SettingsAboutData(
      platform: 'Windows x64',
      system: [('OS', _os), ('Dart', '3.13.5'), ('ID', _longId)],
    ),
  );
}
