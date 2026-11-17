import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

SettingsViewData _data({
  bool cleanup = false,
  bool failed = false,
  bool plan = false,
}) {
  final base = SettingsFixture.view(page: SettingsPageId.rag);
  return base.copyWith(
    values: base.values.copyWith(SettingKey.ragEnabled, true),
    rag: SettingsRagData(
      runtimeReady: true,
      sources: [
        SettingsRagSource(
          kind: SettingsRagSourceKind.tags,
          state: cleanup ? SettingsRagState.ready : SettingsRagState.empty,
          done: cleanup ? 1004407 : 0,
          total: 1004407,
          upgradeAvailable: true,
          cleanupOnly: cleanup,
          upgradeFailed: failed,
        ),
        const SettingsRagSource(
          kind: SettingsRagSourceKind.wiki,
          state: SettingsRagState.ready,
          done: 313616,
          total: 313616,
        ),
        const SettingsRagSource(
          kind: SettingsRagSourceKind.blocks,
          state: SettingsRagState.ready,
          done: 726,
          total: 726,
        ),
      ],
      plan: plan
          ? SettingsRagPlan(
              kind: SettingsRagSourceKind.tags,
              total: 638963,
              upgrade: true,
              cleanupOnly: cleanup,
              legacyBytes: 4400000000,
            )
          : null,
    ),
  );
}

Future<void> _capture(WidgetTester t, String name) async {
  final folder = Platform.environment['RAG_UPGRADE_CAPTURES'];
  if (folder == null) return;
  await t.runAsync(() async {
    final boundary = t.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('settings-capture')),
    );
    final image = await boundary.toImage();
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$folder/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(png!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(loadStudioCaptureFonts);

  testWidgets(
    'upgrade reuses the confirmed build flow and keeps the other sources ready',
    (t) async {
      final rec = await pumpSettings(t, data: _data());
      final l = AppLocalizations.of(t.element(find.byType(SettingsHost)))!;
      expect(find.text(l.set_rgUpgradeNotice), findsOneWidget);
      expect(find.text('313,616 / 313,616 段'), findsOneWidget);
      await t.tap(find.byKey(const Key('rag-upgrade-tags')));
      expect(rec.calls, ['ragBuild:tags']);
      expect(t.takeException(), isNull);

      await t.pumpWidget(const SizedBox.shrink());
      final confirm = await pumpSettings(t, data: _data(plan: true));
      expect(
        t.widget<SettingsBtn>(find.byKey(const Key('rag-upgrade-tags'))).onTap,
        isNull,
      );
      await t.tap(find.byKey(const Key('rag-plan-start')));
      expect(confirm.calls, ['ragStartPlan']);
    },
  );

  testWidgets(
    'cleanup failure stays usable and retry opens a cleanup-only confirmation',
    (t) async {
      final rec = await pumpSettings(
        t,
        data: _data(cleanup: true, failed: true),
      );
      final l = AppLocalizations.of(t.element(find.byType(SettingsHost)))!;
      expect(find.text(l.set_rgUpgradeCleanupFailed), findsOneWidget);
      expect(find.text(l.set_rgError), findsNothing);
      expect(find.text(l.set_rgCleanupLegacy), findsOneWidget);
      await t.tap(find.byKey(const Key('rag-upgrade-tags')));
      expect(rec.calls, ['ragBuild:tags']);
      await t.pumpWidget(const SizedBox.shrink());
      await pumpSettings(t, data: _data(cleanup: true, plan: true));
      expect(
        t.widget<SettingsBtn>(find.byKey(const Key('rag-plan-start'))).label,
        l.set_rgCleanupLegacy,
      );
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'upgrade and cleanup plans fit all locales, themes and supported narrow widths',
    (t) async {
      debugDisableShadows = false;
      try {
        for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
          for (final dark in [false, true]) {
            for (final width in [900.0, 1280.0]) {
              for (final cleanup in [false, true]) {
                await t.pumpWidget(const SizedBox.shrink());
                await pumpSettings(
                  t,
                  locale: locale,
                  dark: dark,
                  window: width,
                  data: _data(cleanup: cleanup, plan: true),
                );
                expect(find.byKey(const Key('rag-plan-tags')), findsOneWidget);
                expect(
                  t.takeException(),
                  isNull,
                  reason: '$locale $dark $width $cleanup',
                );
                if ((locale == 'zh' && width == 1280 && !cleanup) ||
                    (locale == 'en' && width == 900 && cleanup)) {
                  await _capture(
                    t,
                    '$locale-${dark ? 'dark' : 'light'}-${width.toInt()}-${cleanup ? 'cleanup' : 'upgrade'}',
                  );
                }
              }
            }
          }
        }
      } finally {
        debugDisableShadows = true;
      }
    },
  );
}
