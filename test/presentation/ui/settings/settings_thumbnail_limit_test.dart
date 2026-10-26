// B04（10-24）：缩略图缓存上限可设置，默认 20 GB、最高 50 GB，全部图库合计。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';

import 'settings_test_harness.dart';

void main() {
  testWidgets('存储页：上限滑杆 1–50 GB，默认 20，拖到最右写 50', (t) async {
    final rec = await pumpSettings(t, page: SettingsPageId.storage);
    final slider = find.byKey(const Key('slider-thumbnailCacheLimitGb'));
    await t.ensureVisible(slider);
    await t.pumpAndSettle();
    final w = t.widget<SettingsSlider>(slider);
    expect(w.value, 20);
    expect(w.min, 1);
    expect(w.max, 50);
    expect(find.text('20 GB'), findsWidgets);
    final track = find.descendant(
      of: slider,
      matching: find.byType(GestureDetector),
    );
    final rect = t.getRect(track);
    await t.tapAt(Offset(rect.right - .1, rect.center.dy));
    await t.pumpAndSettle();
    expect(rec.changes.last, (SettingKey.thumbnailCacheLimitGb, 50.0));
    expect(t.takeException(), isNull);
  });

  testWidgets('搜索能找到上限设置', (t) async {
    await pumpSettings(t, initialQuery: 'thumbnailCacheLimitGb');
    expect(find.text('缩略图缓存上限'), findsWidgets);
    expect(t.takeException(), isNull);
  });
}
