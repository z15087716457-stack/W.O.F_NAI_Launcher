// B03（10-24）：存储分类悬停显示来源目录；读取不完整的分类带警示，整体给一句说明。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';

import 'settings_test_harness.dart';

const _gb = 1024 * 1024 * 1024;

SettingsViewData _data({
  required bool incomplete,
  int thumbs = 0,
  int limit = 0,
  DateTime? at,
}) {
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
      thumbnailBytes: thumbs,
      thumbnailLimit: limit,
      thumbnailCount: 35493,
      measuredAt: at,
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

  // E06（10-27）：2.26 GB 不再四舍五入成 2.0；比例条按配额比例；悬停显示张数。
  testWidgets('缩略图配额：两位小数 + 比例条 + 张数提示', (t) async {
    await pumpSettings(
      t,
      data: _data(
        incomplete: false,
        thumbs: (2.26 * _gb).round(),
        limit: 20 * _gb,
        at: DateTime.now(),
      ),
    );
    final quota = find.byKey(const Key('thumb-quota'));
    await t.ensureVisible(quota);
    await t.pumpAndSettle();
    expect(find.textContaining('2.26'), findsOneWidget);
    expect(find.textContaining('/ 20 GB'), findsOneWidget);
    final bar = t.getSize(find.byKey(const Key('thumb-quota-bar')));
    final fill = t.getSize(
      find.descendant(
        of: find.byKey(const Key('thumb-quota-bar')),
        matching: find.byType(FractionallySizedBox),
      ),
    );
    expect(fill.width / bar.width, closeTo(2.26 / 20, .01));
    expect(t.widget<Tooltip>(quota).message, startsWith('35493 张缩略图'));
    expect(t.takeException(), isNull);
  });

  testWidgets('统计超过 5 分钟：进页面自动重算一次；新鲜的不重算', (t) async {
    final stale = await pumpSettings(
      t,
      data: _data(
        incomplete: false,
        thumbs: _gb,
        limit: 20 * _gb,
        at: DateTime.now().subtract(const Duration(minutes: 6)),
      ),
    );
    expect(stale.calls.where((c) => c == 'recomputeStorage').length, 1);
    final fresh = await pumpSettings(
      t,
      data: _data(
        incomplete: false,
        thumbs: _gb,
        limit: 20 * _gb,
        at: DateTime.now(),
      ),
    );
    expect(fresh.calls, isNot(contains('recomputeStorage')));
  });
}
