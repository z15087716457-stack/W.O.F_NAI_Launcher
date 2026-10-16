import 'dart:io';
import 'dart:ui' as ui;

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
      testWidgets('$locale $width 蓝点紧跟文字、说明对齐且状态更新不挪标题', (t) async {
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
          final dot = t.getRect(
            find.descendant(
              of: row,
              matching: find.byKey(const Key('settings-modified-dot')),
            ),
          );
          expect(dot.left - title.right, closeTo(7, .001));
          expect(dot.center.dy, closeTo(title.center.dy, .001));
          expect(dot.size, const Size(6, 6));
          if (widget.subtitle != null) {
            final subtitle = t.getRect(
              find.descendant(of: row, matching: find.text(widget.subtitle!)),
            );
            expect(subtitle.left, title.left);
          }
          previousLeft[setting] = title.left;
        }
        expect(t.takeException(), isNull);
        await _capture(t, 'storage-$locale-${width.toInt()}');
        final host = t.state<SettingsHostState>(find.byType(SettingsHost));
        host.updateData(data.copyWith(modified: {}));
        await t.pumpAndSettle();
        expect(find.byKey(const Key('settings-modified-dot')), findsNothing);
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

  testWidgets('尾部蓝点保留单项恢复默认回调', (t) async {
    final rec = await pumpSettings(t, page: SettingsPageId.storage);
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

  testWidgets('独立标签的蓝点也紧跟文字并允许长标签换行', (t) async {
    await pumpSettings(t, page: SettingsPageId.shortcuts, window: 900);
    final marks = find
        .byType(SettingsModMark)
        .evaluate()
        .where((e) => (e.widget as SettingsModMark).on);
    expect(marks, isNotEmpty);
    for (final element in marks) {
      final mark = element.widget as SettingsModMark;
      final text = t.getRect(find.byWidget(mark.child));
      final dot = t.getRect(
        find.descendant(
          of: find.byWidget(mark),
          matching: find.byKey(const Key('settings-modified-dot')),
        ),
      );
      expect(dot.left - text.right, closeTo(7, .001));
    }
    expect(t.takeException(), isNull);
    await _capture(t, 'shortcuts-zh-900');
  });
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
