import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  testWidgets('17 页正文和侧卡在超宽主内容区整体居中', (t) async {
    for (final page in SettingsPageId.values) {
      await t.pumpWidget(const SizedBox.shrink());
      await pumpSettings(t, page: page, window: 3440, height: 1392);
      _expectCentered(t);
      expect(t.takeException(), isNull, reason: page.name);
    }
  });

  for (final locale in ['zh', 'en', 'ja', 'ko', 'zh_TW']) {
    testWidgets('账号 $locale 缩放窗口保留居中、卡片宽度与窄窗堆叠', (t) async {
      await pumpSettings(
        t,
        page: SettingsPageId.account,
        locale: locale,
        window: 3440,
        height: 1392,
      );
      final host = t.state<SettingsHostState>(find.byType(SettingsHost));
      for (final width in [3440.0, 1600.0, 1280.0, 900.0, 3440.0]) {
        t.view.physicalSize = Size(width - settingsRail, 1392);
        await t.pumpAndSettle();
        _expectCentered(t);
        expect(t.state(find.byType(SettingsHost)), same(host));
        final frame = t.widget<SettingsPageFrame>(
          find.byType(SettingsPageFrame),
        );
        final main = t.getRect(find.byWidget(frame.title));
        final aside = t.getRect(find.byWidget(frame.aside.first));
        if (width >= 1280) {
          expect(main.width, width >= 1600 ? 780 : 604);
          expect(aside.width, 292);
          expect(aside.left - main.right, 40);
          expect(aside.top, main.top);
        } else {
          expect(aside.left, main.left);
          expect(aside.width, main.width);
          expect(aside.top, greaterThan(main.bottom));
        }
        expect(t.takeException(), isNull);
      }
    });
  }

  for (final (name, page, width, dark, query) in [
    ('account-3440-light', SettingsPageId.account, 3440.0, false, ''),
    ('account-3440-dark', SettingsPageId.account, 3440.0, true, ''),
    ('account-900-light', SettingsPageId.account, 900.0, false, ''),
    ('models-3440-light', SettingsPageId.models, 3440.0, false, ''),
    ('search-3440-light', SettingsPageId.overview, 3440.0, false, 'anlas'),
  ]) {
    testWidgets('$name 居中布局实绘', (t) async {
      await pumpSettings(
        t,
        page: page,
        window: width,
        height: 1392,
        dark: dark,
        initialQuery: query,
      );
      _expectCentered(t);
      expect(t.takeException(), isNull);
      final output = Platform.environment['SETTINGS_CENTER_CAPTURE_DIR'];
      if (output != null) {
        final box = t.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('settings-capture')),
        );
        await t.runAsync(() async {
          final image = await box.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory(output)..createSync(recursive: true);
          File(
            '${directory.path}/$name.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}

void _expectCentered(WidgetTester t) {
  final scroll = find.byKey(const Key('settings-scroll'));
  final widget = t.widget<SingleChildScrollView>(scroll);
  final viewport = t.getRect(scroll);
  final group = t.getRect(find.byWidget((widget.child! as Align).child!));
  final padding = widget.padding!.resolve(TextDirection.ltr);
  expect(group.center.dx, closeTo(viewport.center.dx, .001));
  expect(group.left, greaterThanOrEqualTo(viewport.left + padding.left));
  expect(group.right, lessThanOrEqualTo(viewport.right - padding.right));
  expect(group.top, viewport.top + padding.top);
}
