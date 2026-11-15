import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_dialog_kit.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/uiux_frontend_capture.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  final longRules = List.generate(
    60,
    (i) => 'Rule $i: keep project files and confirmed choices.',
  ).join('\n');

  Future<void> select(WidgetTester t, String id) async {
    final picker = find.byKey(const Key('agent-instruction-scope-select'));
    await t.ensureVisible(picker);
    await t.tap(picker);
    await t.pumpAndSettle();
    await t.tap(find.byKey(Key('settings-option-$id')));
    await t.pumpAndSettle();
  }

  SettingsViewData data({String? text, bool missing = false}) {
    final d = SettingsFixture.view(page: SettingsPageId.agent);
    return d.copyWith(
      agent: missing
          ? SettingsAgentData(
              workspaceChoices: d.agent.workspaceChoices,
              systemPrompt: SettingsFixture.systemPrompt,
              projectRulesPath: 'workspaces/inspire/AGENTS.md',
            )
          : d.agent.copyWith(
              systemPrompt: SettingsFixture.systemPrompt,
              projectRulesText: text ?? longRules,
            ),
    );
  }

  testWidgets(
    'scope card follows context; workspace replaces global editors with scrollable readonly rules',
    (t) async {
      await pumpSettings(
        t,
        data: data(),
        agentTab: 'instructions',
        window: 1280,
        dark: true,
      );
      expect(
        t.getTopLeft(find.byKey(const Key('agent-instruction-scope'))).dy,
        greaterThan(t.getBottomLeft(find.byKey(const Key('agent-context'))).dy),
      );
      await t.enterText(
        find.byKey(const Key('agent-global')),
        'retained global draft',
      );
      await select(t, 'inspire');
      expect(find.byKey(const Key('agent-global')), findsNothing);
      expect(find.byKey(const Key('agent-prefix')), findsNothing);
      final pane = find.byKey(const Key('agent-project-rules'));
      expect(pane, findsOneWidget);
      expect(find.byType(SettingsCodeView), findsOneWidget);
      expect(find.textContaining('instructions.md'), findsNothing);
      final scrollable = find.descendant(
        of: pane,
        matching: find.byType(SingleChildScrollView),
      );
      final position = t
          .widget<SingleChildScrollView>(scrollable)
          .controller!
          .position;
      await t.drag(pane, const Offset(0, -140));
      await t.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
      expect(t.getSize(pane).height, 328);
      position.jumpTo(0);
      await t.pumpAndSettle();
      final captureDirectory =
          Platform.environment['UIUX_FRONTEND_CAPTURE_DIR'];
      if (captureDirectory != null) {
        final context = t.getRect(find.byKey(const Key('agent-context')));
        final scope = t.getRect(
          find.byKey(const Key('agent-instruction-scope')),
        );
        await t.runAsync(() async {
          final metrics = File('$captureDirectory/agent-rules-metrics.json');
          await metrics.parent.create(recursive: true);
          await metrics.writeAsString(
            jsonEncode({
              'context': [
                context.left,
                context.top,
                context.width,
                context.height,
              ],
              'scope': [scope.left, scope.top, scope.width, scope.height],
              'paneHeight': t.getSize(pane).height,
              'asideGap': scope.top - context.bottom,
            }),
          );
        });
      }
      await captureUiuxRegion(
        t,
        find.byKey(const Key('settings-capture')),
        'workspace-dark',
        Offset.zero & t.getSize(find.byKey(const Key('settings-capture'))),
      );
      await select(t, '');
      expect(find.text('retained global draft'), findsOneWidget);
      expect(t.takeException(), isNull);
      await captureUiuxRegion(
        t,
        find.byKey(const Key('settings-capture')),
        'global-dark',
        Offset.zero & t.getSize(find.byKey(const Key('settings-capture'))),
      );
    },
  );

  testWidgets(
    'missing project file has a readonly empty state and no creation action',
    (t) async {
      await pumpSettings(
        t,
        data: data(missing: true),
        agentTab: 'instructions',
      );
      await select(t, 'inspire');
      expect(find.textContaining('尚未创建 AGENTS.md'), findsOneWidget);
      expect(find.byKey(const Key('settings-dialog-copy')), findsNothing);
      expect(t.takeException(), isNull);
    },
  );

  for (final locale in ['zh', 'en', 'ja', 'ko', 'zh_TW']) {
    for (final dark in [false, true]) {
      testWidgets('project rules reflow in $locale, dark=$dark at 150%', (
        t,
      ) async {
        await pumpSettings(
          t,
          data: data(),
          agentTab: 'instructions',
          window: 900,
          uiScale: 1.5,
          locale: locale,
          dark: dark,
        );
        await select(t, 'inspire');
        expect(find.byKey(const Key('agent-project-rules')), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }
  }
}
