import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_controls.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  testWidgets(
    'finished verification has ready controls, no build badge or pause',
    (t) async {
      final base = SettingsFixture.view(page: SettingsPageId.rag);
      await pumpSettings(
        t,
        data: base.copyWith(
          values: base.values.copyWith(SettingKey.ragEnabled, true),
          rag: const SettingsRagData(
            runtimeReady: true,
            indexBusy: false,
            sources: [
              SettingsRagSource(
                kind: SettingsRagSourceKind.tags,
                state: SettingsRagState.ready,
                done: 638024,
                total: 638024,
              ),
              SettingsRagSource(
                kind: SettingsRagSourceKind.blocks,
                state: SettingsRagState.ready,
                done: 727,
                total: 727,
              ),
            ],
          ),
        ),
      );
      final l = AppLocalizations.of(t.element(find.byType(SettingsHost)))!;
      expect(find.text(l.set_rgBuilding), findsNothing);
      expect(find.text(l.set_rgPartial), findsNothing);
      expect(find.text(l.set_pause), findsNothing);
      for (final kind in [
        SettingsRagSourceKind.tags,
        SettingsRagSourceKind.blocks,
      ]) {
        final more = find.byKey(Key('rag-more-${kind.name}'));
        expect(more, findsOneWidget);
        expect(t.widget<SettingsMoreButton>(more).enabled, true);
      }
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'unread indexes are loading rather than empty; known counts survive reconnect',
    (t) async {
      for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
        for (final dark in [false, true]) {
          for (final width in [900.0, 1280.0]) {
            final base = SettingsFixture.view(page: SettingsPageId.rag);
            final rec = await pumpSettings(
              t,
              locale: locale,
              dark: dark,
              window: width,
              data: base.copyWith(
                values: base.values.copyWith(SettingKey.ragEnabled, true),
                rag: SettingsRagData(
                  runtimeReady: true,
                  initializing: true,
                  initializationPhase: 'restoring',
                  initializationProcessed: 256,
                  initializationTotal: 736159,
                  sources: [
                    for (final kind in SettingsRagSourceKind.values)
                      SettingsRagSource(
                        kind: kind,
                        state: SettingsRagState.loading,
                        known: false,
                      ),
                  ],
                ),
              ),
            );
            final l = AppLocalizations.of(
              t.element(find.byType(SettingsHost)),
            )!;
            expect(find.text(l.set_rgEmpty), findsNothing);
            expect(find.text(l.set_rgBuild), findsNothing);
            expect(find.text('0%'), findsNothing);
            expect(find.text(l.set_rgReady), findsNothing);
            expect(find.text(l.set_rgPartial), findsNothing);
            expect(find.text(l.set_rgLoading), findsWidgets);
            expect(
              find.text(l.set_rgRestoring('256', '736,159')),
              findsOneWidget,
            );
            for (final kind in SettingsRagSourceKind.values) {
              expect(find.byKey(Key('rag-more-${kind.name}')), findsNothing);
            }
            expect(rec.calls, isEmpty);
            expect(t.takeException(), isNull);
            final output = Platform.environment['RAG_STARTUP_CAPTURE'];
            if (output != null) {
              final box = t.renderObject<RenderRepaintBoundary>(
                find.byKey(const Key('settings-capture')),
              );
              await t.runAsync(() async {
                final bitmap = await box.toImage(pixelRatio: 1);
                final bytes = await bitmap.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                Directory(output).createSync(recursive: true);
                File(
                  '$output/$locale-${dark ? 'dark' : 'light'}-${width.toInt()}.png',
                ).writeAsBytesSync(bytes!.buffer.asUint8List());
                bitmap.dispose();
              });
            }
          }
        }
      }
      await t.pumpWidget(const SizedBox.shrink());
      final base = SettingsFixture.view(page: SettingsPageId.rag);
      await pumpSettings(
        t,
        data: base.copyWith(
          rag: const SettingsRagData(
            initializing: true,
            runtimeReady: true,
            sources: [
              SettingsRagSource(
                kind: SettingsRagSourceKind.tags,
                state: SettingsRagState.loading,
                done: 638024,
                total: 638024,
              ),
            ],
          ),
        ),
      );
      expect(find.textContaining('638,024'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('failed unread status has a retry and no zero count', (t) async {
    final base = SettingsFixture.view(page: SettingsPageId.rag);
    final rec = await pumpSettings(
      t,
      data: base.copyWith(
        rag: const SettingsRagData(
          runtimeReady: true,
          error: 'initialization_timeout',
          sources: [
            SettingsRagSource(
              kind: SettingsRagSourceKind.tags,
              state: SettingsRagState.error,
              known: false,
              error: 'initialization_timeout',
            ),
          ],
        ),
      ),
    );
    final l = AppLocalizations.of(t.element(find.byType(SettingsHost)))!;
    expect(find.text(l.set_rgLoadingTimeout), findsNWidgets(2));
    expect(find.text('0%'), findsNothing);
    expect(find.text(l.set_rgBuild), findsNothing);
    expect(find.text(l.set_retry), findsOneWidget);
    expect(find.text(l.set_rgReady), findsNothing);
    expect(find.text(l.set_rgNotReady), findsOneWidget);
    expect(
      t
          .widget<SettingsBtn>(find.widgetWithText(SettingsBtn, l.set_retry))
          .onTap,
      isNotNull,
    );
    expect(find.byKey(const Key('rag-more-tags')), findsNothing);
    await t.tap(find.widgetWithText(SettingsBtn, l.set_retry));
    expect(rec.calls, ['ragRefresh']);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'settings search never turns an unread failure into zero percent',
    (t) async {
      final base = SettingsFixture.view(page: SettingsPageId.rag);
      await pumpSettings(
        t,
        initialQuery: 'rag',
        data: base.copyWith(
          rag: const SettingsRagData(
            error: 'initialization_timeout',
            sources: [
              SettingsRagSource(
                kind: SettingsRagSourceKind.tags,
                state: SettingsRagState.error,
                known: false,
              ),
            ],
          ),
        ),
      );
      expect(find.text('0%'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
}
