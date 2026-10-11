// Vibe / 精准参考库基准截图（中文浅色 / 深色）：用固定假数据锁定视觉。界面变了这里会失败。
// 只有界面方确认新样子后才更新基准：
//   flutter test --update-goldens test/presentation/ui/refs/refs_golden_test.dart
// 基准在 Windows + 内置真实字体下生成，其他系统跳过。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_contract.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_fixture.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_picker.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'refs_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  final skip = !Platform.isWindows;

  Future<void> pick(WidgetTester t, List<String> keys) async {
    await tapKey(t, 'refs-multi');
    for (final k in keys) {
      await tapKey(t, 'refs-card-$k');
    }
  }

  final scenes =
      <
        (
          String,
          RefsViewData,
          double,
          bool,
          Future<void> Function(WidgetTester)?,
        )
      >[
        (
          'vibe',
          RefsFixture.vibe(),
          1600,
          true,
          (t) async {
            await hoverOver(t, find.byKey(const Key('refs-card-c13')));
          },
        ),
        ('precise', RefsFixture.preciseView(), 1600, true, null),
        (
          'select',
          RefsFixture.vibe(),
          1600,
          true,
          (t) => pick(t, ['c03', 'c15', 'c11', 'c13']),
        ),
        (
          'precise-select',
          RefsFixture.preciseView(),
          1600,
          false,
          (t) => pick(t, ['c20', 'c02', 'c12']),
        ),
        ('v5', RefsFixture.vibe(model: RefsFixture.v5), 1600, false, null),
        (
          'v5-precise',
          RefsFixture.preciseView(model: RefsFixture.v5),
          1600,
          false,
          null,
        ),
        ('reencode', RefsFixture.vibe(selectedKey: 'c11'), 1600, false, null),
        (
          'detail',
          RefsFixture.vibe(selectedKey: 'c11'),
          1600,
          true,
          (t) => tapKey(t, 'refs-insp-preview'),
        ),
        (
          'precise-detail',
          RefsFixture.preciseView(),
          1600,
          false,
          (t) => tapKey(t, 'refs-insp-preview'),
        ),
        (
          'bundle',
          RefsFixture.vibe(selectedKey: 'c14'),
          1600,
          true,
          (t) => tapKey(t, 'refs-insp-open-bundle'),
        ),
        (
          'import',
          RefsFixture.vibe(importDraft: RefsFixture.importDraft()),
          1600,
          true,
          null,
        ),
        ('drop', RefsFixture.vibe(drop: RefsFixture.drop), 1600, false, null),
        (
          'export',
          RefsFixture.vibe(),
          1600,
          false,
          (t) async {
            await pick(t, ['c03', 'c15', 'c11', 'c13']);
            await tapKey(t, 'refs-sel-export');
          },
        ),
        (
          'delete',
          RefsFixture.vibe(),
          1600,
          false,
          (t) async {
            await pick(t, ['c03', 'c15']);
            await tapKey(t, 'refs-sel-delete');
          },
        ),
        (
          'menu',
          RefsFixture.vibe(),
          1600,
          false,
          (t) async {
            await t.tap(find.byKey(const Key('refs-card-c12')), buttons: 2);
            await t.pumpAndSettle();
          },
        ),
        ('empty', RefsFixture.vibe(empty: true), 1600, true, null),
        (
          'empty-precise',
          RefsFixture.preciseView(empty: true),
          1600,
          false,
          null,
        ),
        (
          'no-results',
          RefsFixture.vibe().copyWithEntries(
            const [],
            const RefsFilter(query: '海边'),
          ),
          1600,
          false,
          null,
        ),
        ('narrow', RefsFixture.vibe(), 1100, false, null),
        ('narrower', RefsFixture.vibe(), 820, false, null),
      ];

  for (final (name, data, window, both, interact) in scenes) {
    for (final dark in both ? [false, true] : [false]) {
      final file = '$name${dark ? '-dark' : ''}';
      testWidgets(file, skip: skip, (t) async {
        debugDisableShadows = false;
        await pumpRefs(t, data: data, window: window, dark: dark);
        if (interact != null) {
          await interact(t);
          await t.pumpAndSettle();
        }
        await expectLater(
          find.byKey(const Key('refs-capture')),
          matchesGoldenFile('goldens/$file.png'),
        );
        debugDisableShadows = true;
      });
    }
  }

  for (final (name, picker) in [
    ('picker', RefsFixture.vibePicker()),
    ('picker-precise', RefsFixture.precisePicker()),
  ]) {
    for (final dark in name == 'picker' ? [false, true] : [false]) {
      final file = '$name${dark ? '-dark' : ''}';
      testWidgets(file, skip: skip, (t) async {
        debugDisableShadows = false;
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = const Size(760, 860);
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        await t.pumpWidget(
          refsApp(
            Center(
              child: RefsPicker(
                data: picker,
                actions: RefsPickerActions(
                  onConfirm: (_, {required replace}) {},
                  onClose: () {},
                  onOpenLibrary: () {},
                ),
              ),
            ),
            dark: dark,
          ),
        );
        await precacheRefs(t, [for (final e in picker.entries) ?e.thumb]);
        await tapKey(t, 'refs-picker-card-${picker.entries[1].key}');
        await tapKey(t, 'refs-picker-card-${picker.entries[4].key}');
        await expectLater(
          find.byKey(const Key('refs-capture')),
          matchesGoldenFile('goldens/$file.png'),
        );
        debugDisableShadows = true;
      });
    }
  }
}

extension on RefsViewData {
  RefsViewData copyWithEntries(List<RefsEntry> entries, RefsFilter filter) =>
      RefsViewData(
        kind: kind,
        now: now,
        model: model,
        costs: costs,
        entries: entries,
        counts: counts,
        categories: categories,
        filter: filter,
        tray: tray,
        cardSize: cardSize,
        folderPath: folderPath,
        exportFolder: exportFolder,
      );
}
