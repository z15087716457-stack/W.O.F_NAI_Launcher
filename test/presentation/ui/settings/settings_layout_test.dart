// 设置页布局：17 页 × 宽窄 × 浅深 × 多语言都不抛布局异常（溢出、无界约束）。
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  for (final p in SettingsPageId.values) {
    testWidgets('${p.name} 宽屏浅色', (t) async {
      await pumpSettings(t, page: p);
      expect(t.takeException(), isNull);
    });
    testWidgets('${p.name} 窄窗深色', (t) async {
      await pumpSettings(t, page: p, window: 1100, dark: true);
      expect(t.takeException(), isNull);
    });
    for (final l in ['en', 'ja', 'ko', 'zh_TW']) {
      testWidgets('${p.name} $l 1280', (t) async {
        await pumpSettings(t, page: p, window: 1280, locale: l);
        expect(t.takeException(), isNull);
      });
    }
    testWidgets('${p.name} 新装', (t) async {
      await pumpSettings(t, page: p, scene: SettingsScene.fresh);
      expect(t.takeException(), isNull);
    });
  }

  // 语义检索的忙碌状态：下载进度、计划卡、出错行、安装中。
  for (final (name, rag) in [
    ('下载与计划', SettingsFixture.ragBusy),
    ('安装中', SettingsFixture.ragInstalling),
  ]) {
    for (final (w, l, dark) in [
      (1600.0, 'zh', false),
      (1100.0, 'zh', true),
      (1280.0, 'en', false),
      (900.0, 'ja', false),
    ]) {
      testWidgets('rag $name $l $w', (t) async {
        await pumpSettings(
          t,
          window: w,
          locale: l,
          dark: dark,
          data: SettingsFixture.view(
            page: SettingsPageId.rag,
            dark: dark,
          ).copyWith(rag: rag),
        );
        expect(t.takeException(), isNull);
      });
    }
  }

  testWidgets('最小窗口 900', (t) async {
    for (final p in SettingsPageId.values) {
      await pumpSettings(t, page: p, window: 900, locale: 'en');
      expect(t.takeException(), isNull, reason: p.name);
    }
  });
}
