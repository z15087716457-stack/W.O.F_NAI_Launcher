import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_lib_controls.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/uiux_frontend_capture.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final (window, scale) in [(800.0, 1.0), (1600.0, 1.0), (800.0, 1.5)]) {
    testWidgets('GPU capabilities stay at the right edge at $window / $scale', (
      t,
    ) async {
      await pumpSettings(
        t,
        page: SettingsPageId.upscale,
        window: window,
        uiScale: scale,
        dark: true,
      );
      final gpu = find.byKey(const Key('upscale-gpu'));
      final caps = find.descendant(of: gpu, matching: find.byType(UiMini));
      expect(caps, findsWidgets);
      final gap = t.getRect(gpu).right - t.getRect(caps.last).right;
      expect(gap, closeTo(19 * scale, 1));
      expect(t.takeException(), isNull);
      await captureUiuxRegion(
        t,
        find.byKey(const Key('settings-capture')),
        'gpu-${window.toInt()}-$scale',
        t.getRect(gpu).inflate(8),
      );
    });
  }
  for (final locale in ['zh', 'en', 'ja', 'ko', 'zh_TW']) {
    for (final (window, scale) in [(800.0, 1.0), (1600.0, 1.5)]) {
      testWidgets(
        'existing environment needing dependencies is repairable in $locale / $window / $scale',
        (t) async {
          final data = SettingsFixture.view(page: SettingsPageId.rag).copyWith(
            rag: const SettingsRagData(
              runtimeIssue: SettingsRagRuntimeIssue.dependencies,
              runtimePackages: ['jieba'],
              runtimePython: 'C:/existing/python.exe',
            ),
          );
          final rec = await pumpSettings(
            t,
            data: data,
            locale: locale,
            window: window,
            uiScale: scale,
            dark: true,
          );
          final row = find.byKey(const Key('rag-runtime'));
          await t.ensureVisible(row);
          await t.pumpAndSettle();
          expect(
            find.descendant(of: row, matching: find.textContaining('jieba')),
            findsOneWidget,
          );
          expect(find.byKey(const Key('rag-check')), findsOneWidget);
          expect(find.byKey(const Key('rag-install')), findsOneWidget);
          if (locale == 'zh') {
            expect(find.text('需要更新'), findsOneWidget);
            expect(find.text('更新环境'), findsOneWidget);
            expect(find.text('还没有安装'), findsNothing);
          }
          await t.tap(find.byKey(const Key('rag-check')));
          await t.pump();
          expect(rec.calls, contains('ragCheckRuntime'));
          expect(t.takeException(), isNull);
          await captureUiuxRegion(
            t,
            find.byKey(const Key('settings-capture')),
            'runtime-$locale-${window.toInt()}-$scale',
            t.getRect(row).inflate(8),
          );
        },
      );
    }
  }
}
