import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/uiux_frontend_capture.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  Future<void> requests(WidgetTester t) async {
    await t.tap(find.byKey(const Key('models-tab-requests')));
    await t.pumpAndSettle();
  }

  testWidgets('only the hovered row exposes its own stable record id', (
    t,
  ) async {
    final rec = await pumpSettings(t, page: SettingsPageId.models);
    await requests(t);
    final first = find.byKey(const Key('request-details-request-0'));
    final other = find.byKey(const Key('request-details-request-4'));
    expect(first.hitTestable(), findsNothing);
    expect(other.hitTestable(), findsNothing);
    final before = t.getRect(find.byKey(const ValueKey('request-0')));
    final mouse = await t.createGesture(kind: ui.PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    addTearDown(mouse.removePointer);
    await mouse.moveTo(before.center);
    await t.pumpAndSettle();
    expect(first.hitTestable(), findsOneWidget);
    expect(other.hitTestable(), findsNothing);
    expect(t.getRect(find.byKey(const ValueKey('request-0'))), before);
    expect(find.textContaining('412'), findsOneWidget);
    await t.tap(first);
    await t.pumpAndSettle();
    expect(rec.calls, ['requestDetails:request-0']);
    await mouse.moveTo(t.getCenter(find.byKey(const ValueKey('request-4'))));
    await t.pumpAndSettle();
    expect(first.hitTestable(), findsNothing);
    expect(other.hitTestable(), findsOneWidget);
    await t.tap(other);
    expect(rec.calls.last, 'requestDetails:request-4');
    await mouse.moveTo(const Offset(1, 1));
    await t.pumpAndSettle();
    expect(other.hitTestable(), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'a summary without a retained record has no dead details action',
    (t) async {
      final data = SettingsFixture.view(page: SettingsPageId.models);
      final rec = await pumpSettings(
        t,
        data: data.copyWith(
          models: SettingsModelsData(
            requests: [
              SettingsRequestLog(
                at: data.now,
                task: SettingsModelTask.promptTranslate,
                provider: 'Fixture',
                model: 'fixture',
                ok: false,
              ),
            ],
            requestTotal: 1,
          ),
        ),
      );
      await requests(t);
      expect(find.widgetWithText(SettingsBtn, '详情'), findsNothing);
      expect(rec.calls, isEmpty);
    },
  );

  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final scenario in [(1600.0, 1.0), (900.0, 1.0), (1600.0, 1.5)]) {
      testWidgets('request hover fits $locale $scenario', (t) async {
        await pumpSettings(
          t,
          data: SettingsFixture.view(page: SettingsPageId.models).copyWith(
            models: SettingsModelsData(
              requests: SettingsFixture.view(
                page: SettingsPageId.models,
              ).models.requests,
              requestTotal: 8,
            ),
          ),
          locale: locale,
          window: scenario.$1,
          dark: locale == 'en',
        );
        await requests(t);
        t.platformDispatcher.textScaleFactorTestValue = scenario.$2;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        await t.pumpAndSettle();
        final button = find.byKey(const Key('request-details-request-0'));
        await t.ensureVisible(button);
        await t.pumpAndSettle();
        final mouse = await t.createGesture(kind: ui.PointerDeviceKind.mouse);
        await mouse.addPointer(location: const Offset(1, 1));
        addTearDown(mouse.removePointer);
        await mouse.moveTo(t.getCenter(button));
        await t.pumpAndSettle();
        expect(button.hitTestable(), findsOneWidget);
        expect(t.takeException(), isNull, reason: uiuxOverflowDetails(t));
        if (locale == 'zh' && scenario.$1 == 1600 ||
            locale == 'en' && scenario.$2 == 1.5) {
          final capture = find.byKey(const Key('settings-capture'));
          await captureUiuxRegion(
            t,
            capture,
            'requests-$locale-${scenario.$1}-${scenario.$2}',
            t.getRect(capture),
          );
        }
      });
    }
  }
}
