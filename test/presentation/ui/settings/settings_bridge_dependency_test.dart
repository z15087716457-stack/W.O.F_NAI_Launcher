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

  testWidgets('外部 Agent 跟随桥接开关，无需 Krita 插件已连接', (t) async {
    final fixture = SettingsFixture.view(page: SettingsPageId.bridges);
    late SettingsHostState host;
    final rec = await pumpSettings(
      t,
      data: fixture.copyWith(
        values: fixture.values.copyWith(SettingKey.kritaBridge, false),
        bridges: const SettingsBridgesData(agentClients: 2),
      ),
      onHost: (value) => host = value,
    );
    final row = find.byKey(const Key('external-agent-bridge'));
    final hint = find.byKey(const Key('agent-krita-required'));
    final copy = find.byKey(const Key('agent-copy-takeover'));
    final end = find.byKey(const Key('agent-end-connections'));
    final bridge = find.byKey(const Key('switch-kritaBridge'));

    expect(t.widget<SettingsRow>(row).disabled, isTrue);
    expect(hint, findsOneWidget);
    expect(t.widget<SettingsBtn>(copy).onTap, isNull);
    expect(t.widget<SettingsBtn>(end).onTap, isNull);

    await t.tap(bridge);
    await t.pumpAndSettle();
    expect(rec.changes.single, (SettingKey.kritaBridge, true));
    expect(host.data.bridges.kritaConnected, isFalse);
    expect(t.widget<SettingsRow>(row).disabled, isFalse);
    expect(hint, findsNothing);
    await t.tap(copy);
    await t.tap(end);
    expect(rec.calls, ['copyAgentTakeover', 'endAgentConnections']);

    await t.tap(bridge);
    await t.pumpAndSettle();
    expect(t.widget<SettingsRow>(row).disabled, isTrue);
    expect(hint, findsOneWidget);
    expect(t.widget<SettingsBtn>(copy).onTap, isNull);
    expect(t.widget<SettingsBtn>(end).onTap, isNull);

    host.updateData(
      host.data.copyWith(
        values: host.data.values.copyWith(SettingKey.kritaBridge, true),
        bridges: const SettingsBridgesData(),
      ),
    );
    await t.pumpAndSettle();
    expect(t.widget<SettingsBtn>(copy).onTap, isNotNull);
    expect(t.widget<SettingsBtn>(end).onTap, isNull);
    await t.pump(const Duration(seconds: 5));
    expect(t.takeException(), isNull);
  });

  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      testWidgets('桥接关闭提示布局 $locale dark=$dark', (t) async {
        final fixture = SettingsFixture.view(page: SettingsPageId.bridges);
        await pumpSettings(
          t,
          window: 1100,
          locale: locale,
          dark: dark,
          data: fixture.copyWith(
            values: fixture.values.copyWith(SettingKey.kritaBridge, false),
            bridges: const SettingsBridgesData(),
          ),
        );
        final hint = find.byKey(const Key('agent-krita-required'));
        expect(hint, findsOneWidget);
        expect(t.widget<Text>(hint).style!.fontSize, 11);
        expect(t.takeException(), isNull);
        if (locale == 'zh') {
          final boundary = find.byKey(const Key('settings-capture'));
          await captureUiuxRegion(
            t,
            boundary,
            'bridge-disabled-${dark ? 'dark' : 'light'}',
            Offset.zero & t.getSize(boundary),
          );
        }
      });
    }
  }
}
