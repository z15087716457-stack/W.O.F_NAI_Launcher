// B03（10-24）：存储分类悬停显示来源目录；读取不完整的分类带警示，整体给一句说明。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';

import 'settings_test_harness.dart';

const _gb = 1024 * 1024 * 1024;

SettingsViewData _data({required bool incomplete}) {
  final base = SettingsFixture.view(page: SettingsPageId.storage);
  return base.copyWith(
    storage: SettingsStorageData(
      slices: [
        const SettingsStorageSlice(
          SettingsStorageKind.images,
          31 * _gb,
          paths: [r'E:\A.I\NovelAI\outputs', r'D:\Pixiv'],
        ),
        SettingsStorageSlice(
          SettingsStorageKind.other,
          2 * _gb,
          paths: const [r'E:\A.I\NovelAI\outputs'],
          incomplete: incomplete,
        ),
      ],
      diskLabel: 'E:',
      diskFree: 200 * _gb,
      incomplete: incomplete,
    ),
  );
}

void main() {
  testWidgets('完整统计：无警示，悬停列出来源目录', (t) async {
    await pumpSettings(t, data: _data(incomplete: false));
    final slice = find.byKey(const Key('storage-slice-images'));
    await t.ensureVisible(slice);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('storage-incomplete')), findsNothing);
    expect(find.byKey(const Key('storage-incomplete-other')), findsNothing);
    expect(
      t.widget<Tooltip>(slice).message,
      [r'E:\A.I\NovelAI\outputs', r'D:\Pixiv'].join('\n'),
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('读取不完整：该分类带警示，提示条出现', (t) async {
    await pumpSettings(t, data: _data(incomplete: true));
    final warn = find.byKey(const Key('storage-incomplete-other'));
    await t.ensureVisible(warn);
    await t.pumpAndSettle();
    expect(warn, findsOneWidget);
    expect(find.byKey(const Key('storage-incomplete')), findsOneWidget);
    final tip = t.widget<Tooltip>(find.byKey(const Key('storage-slice-other')));
    expect(tip.message!.split('\n').length, 2);
    expect(t.takeException(), isNull);
  });
}
