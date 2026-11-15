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

  for (final locale in ['zh', 'en', 'ja', 'ko', 'zh_TW']) {
    for (final width in [900.0, 1600.0]) {
      testWidgets('$locale $width 已保存的自定义值不留蓝点、恢复默认不挪标题', (t) async {
        final data = SettingsFixture.view(
          page: SettingsPageId.storage,
          dark: width == 900,
        ).copyWith(modified: {SettingKey.imageSavePath, SettingKey.autoSave});
        await pumpSettings(
          t,
          data: data,
          locale: locale,
          window: width,
          dark: width == 900,
        );
        final previousLeft = <SettingKey, double>{};
        for (final setting in [SettingKey.imageSavePath, SettingKey.autoSave]) {
          final row = find.byKey(Key('setting-${setting.name}'));
          final widget = t.widget<SettingsRow>(row);
          final title = t.getRect(
            find.descendant(of: row, matching: find.text(widget.title)),
          );
          expect(widget.modified, isTrue);
          if (widget.subtitle != null) {
            final subtitle = t.getRect(
              find.descendant(of: row, matching: find.text(widget.subtitle!)),
            );
            expect(subtitle.left, title.left);
          }
          previousLeft[setting] = title.left;
        }
        expect(find.byKey(const Key('settings-unsaved-dot')), findsNothing);
        expect(t.takeException(), isNull);
        await _capture(t, 'storage-$locale-${width.toInt()}');
        final host = t.state<SettingsHostState>(find.byType(SettingsHost));
        host.updateData(data.copyWith(modified: {}));
        await t.pumpAndSettle();
        expect(find.byKey(const Key('settings-unsaved-dot')), findsNothing);
        for (final setting in previousLeft.keys) {
          final row = find.byKey(Key('setting-${setting.name}'));
          expect(
            t
                .getTopLeft(
                  find.descendant(
                    of: row,
                    matching: find.text(t.widget<SettingsRow>(row).title),
                  ),
                )
                .dx,
            previousLeft[setting],
          );
        }
      });
    }
  }

  testWidgets('已保存的非默认设置不显示蓝点，仍可单项恢复默认', (t) async {
    final rec = await pumpSettings(t, page: SettingsPageId.storage);
    expect(find.byKey(const Key('settings-unsaved-dot')), findsNothing);
    final row = find.byKey(const Key('setting-imageSavePath'));
    final mouse = await t.createGesture(kind: ui.PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(t.getCenter(row));
    await t.pumpAndSettle();
    final reset = find.descendant(
      of: row,
      matching: find.byWidgetPredicate(
        (w) => w is SettingsIconBtn && w.glyph == SettingsGlyphs.undo,
      ),
    );
    await t.tap(reset);
    await t.pumpAndSettle();
    expect(rec.calls, ['reset:imageSavePath']);
    expect(rec.changes, isEmpty);
  });

  testWidgets('自定义快捷键不留蓝点，仍保留恢复默认', (t) async {
    final rec = await pumpSettings(
      t,
      page: SettingsPageId.shortcuts,
      window: 900,
    );
    expect(find.byType(SettingsUnsavedMark), findsNothing);
    expect(find.byKey(const Key('settings-unsaved-dot')), findsNothing);
    final reset = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('shortcut-reset-'),
    );
    expect(reset, findsWidgets);
    await t.ensureVisible(reset.first);
    await t.tap(reset.first);
    await t.pumpAndSettle();
    expect(rec.calls.single, startsWith('resetShortcut:'));
    expect(t.takeException(), isNull);
    await _capture(t, 'shortcuts-zh-900');
  });

  testWidgets('隐私设置已保存后不保留修改蓝点', (t) async {
    final base = SettingsFixture.view(page: SettingsPageId.privacy);
    await pumpSettings(
      t,
      data: base.copyWith(modified: SettingKey.values.toSet()),
    );
    expect(find.byKey(const Key('settings-unsaved-dot')), findsNothing);
    final blueDots = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.constraints?.maxWidth == 6 &&
          w.constraints?.maxHeight == 6 &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).shape == BoxShape.circle,
    );
    expect(blueDots, findsNothing);
    expect(t.takeException(), isNull);
    await _capture(t, 'privacy-zh-1600');
  });

  for (final locale in ['zh', 'en', 'ja', 'ko', 'zh_TW']) {
    testWidgets('放大适应画布的说明在 $locale 宽窄与 150% 缩放下完整显示', (t) async {
      for (final width in [900.0, 1600.0]) {
        await pumpSettings(
          t,
          page: SettingsPageId.canvas,
          locale: locale,
          window: width,
          dark: width == 900,
          uiScale: width == 900 ? 1.5 : 1,
        );
        final row = find.byKey(const Key('setting-canvasZoomToFill'));
        await t.ensureVisible(row);
        await t.pumpAndSettle();
        final toggle = find.descendant(
          of: row,
          matching: find.byType(SettingsSwitch),
        );
        expect(t.widget<SettingsSwitch>(toggle).value, isTrue);
        expect(find.byKey(const Key('settings-unsaved-dot')), findsNothing);
        expect(t.takeException(), isNull);
        if (locale == 'zh') {
          await _capture(t, 'canvas-$locale-${width.toInt()}');
        }
      }
    });
  }
}

Future<void> _capture(WidgetTester t, String name) async {
  final output = Platform.environment['SETTINGS_MOD_MARK_CAPTURE_DIR'];
  if (output == null) return;
  final box = t.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('settings-capture')),
  );
  await t.runAsync(() async {
    Directory(output).createSync(recursive: true);
    final image = await box.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$output/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
