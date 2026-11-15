import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/uiux_frontend_capture.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  Future<void> tap(WidgetTester t, Finder finder) async {
    await t.pumpAndSettle();
    await t.ensureVisible(finder);
    await t.tap(finder);
    await t.pumpAndSettle();
  }

  SettingsHostState host(WidgetTester t) => t.state(find.byType(SettingsHost));
  Finder field() => find.descendant(
    of: find.byKey(const Key('agent-workspace-prefix')),
    matching: find.byType(TextField),
  );
  String text(WidgetTester t) => t.widget<TextField>(field()).controller!.text;

  SettingsViewData data() {
    final d = SettingsFixture.view(page: SettingsPageId.agent);
    return d.copyWith(
      agent: d.agent.copyWith(
        systemPrefix: 'SHARED_PREFIX',
        systemPrompt: SettingsFixture.systemPrompt,
        projectRulesText: 'PROJECT_RULES',
        workspaceChoices: const [
          SettingsOption(value: 'inspire', label: 'A'),
          SettingsOption(value: 'b', label: 'B'),
        ],
      ),
    );
  }

  Future<void> select(WidgetTester t, String id) async {
    final picker = find.byKey(const Key('agent-instruction-scope-select'));
    await t.ensureVisible(picker);
    await t.tap(picker);
    await t.pumpAndSettle();
    await t.tap(find.byKey(Key('settings-option-$id')));
    await t.pumpAndSettle();
  }

  Future<void> save(WidgetTester t) => tap(
    t,
    find.descendant(
      of: find.byKey(const Key('agent-unsaved')),
      matching: find.text('保存'),
    ),
  );

  testWidgets(
    'blank workspace prefix inherits without a switch and scope discard preserves the global draft',
    (t) async {
      await pumpSettings(
        t,
        data: data(),
        agentTab: 'instructions',
        window: 1280,
      );
      await t.enterText(find.byKey(const Key('agent-prefix')), 'GLOBAL_DRAFT');
      await select(t, 'inspire');
      expect(text(t), '');
      expect(t.widget<TextField>(field()).readOnly, false);
      expect(
        find.byKey(const Key('agent-workspace-prefix-inherit')),
        findsNothing,
      );
      expect(find.text('留空则沿用全局前置内容。'), findsOneWidget);
      expect(
        t.getTopLeft(find.byKey(const Key('agent-workspace-prefix-hint'))).dy,
        greaterThanOrEqualTo(t.getBottomLeft(field()).dy),
      );
      await t.enterText(field(), 'WORKSPACE_DRAFT');
      await t.pumpAndSettle();
      expect(find.text('Agent 指令有未保存的修改'), findsOneWidget);
      await select(t, '');
      expect(find.byKey(const Key('settings-confirm')), findsOneWidget);
      await tap(t, find.byKey(const Key('confirm-cancel')));
      expect(text(t), 'WORKSPACE_DRAFT');
      await select(t, '');
      await tap(t, find.byKey(const Key('confirm-ok')));
      expect(find.text('GLOBAL_DRAFT'), findsOneWidget);
      expect(find.byKey(const Key('agent-workspace-prefix')), findsNothing);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'workspace prefix saves its own value and clearing it restores inheritance',
    (t) async {
      final rec = await pumpSettings(
        t,
        data: data(),
        agentTab: 'instructions',
        window: 1280,
      );
      final expected = <String?>[];
      rec.saveWorkspacePrefix =
          ({required text, required workspaceId, required expectedText}) async {
            expect(workspaceId, 'inspire');
            expected.add(expectedText);
            final h = host(t);
            h.updateData(
              h.data.copyWith(
                agent: h.data.agent.copyWith(
                  workspacePrefix: () =>
                      text?.trim().isEmpty == true ? null : text,
                ),
              ),
            );
            return true;
          };
      await select(t, 'inspire');
      await t.enterText(field(), 'OWN');
      await save(t);
      expect(find.byKey(const Key('agent-unsaved')), findsNothing);
      expect(find.byKey(const Key('settings-unsaved-dot')), findsNothing);
      await t.enterText(field(), '');
      await save(t);
      expect(host(t).data.agent.workspacePrefix, isNull);
      expect(text(t), '');
      expect(find.byKey(const Key('agent-unsaved')), findsNothing);
      expect(expected, [null, 'OWN']);
      expect(
        rec.calls.where((c) => c.startsWith('saveInstructions:')),
        isEmpty,
      );
      expect(rec.calls.where((c) => c.startsWith('savePrompt:')), isEmpty);
      expect(host(t).data.agent.systemPrefix, 'SHARED_PREFIX');
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'failed workspace prefix save keeps its draft and retry clears the marker',
    (t) async {
      final rec = await pumpSettings(
        t,
        data: data(),
        agentTab: 'instructions',
        window: 1280,
      );
      rec.saveWorkspacePrefix =
          ({
            required text,
            required workspaceId,
            required expectedText,
          }) async => false;
      await select(t, 'inspire');
      await t.enterText(field(), 'RETRY');
      await save(t);
      expect(text(t), 'RETRY');
      expect(
        find.byKey(const Key('agent-workspace-prefix-status')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('settings-unsaved-dot')), findsOneWidget);
      rec.saveWorkspacePrefix =
          ({
            required text,
            required workspaceId,
            required expectedText,
          }) async => true;
      await save(t);
      expect(text(t), 'RETRY');
      expect(find.byKey(const Key('agent-unsaved')), findsNothing);
      expect(
        find.byKey(const Key('agent-workspace-prefix-status')),
        findsNothing,
      );
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'switching workspaces reads each saved prefix and its target id',
    (t) async {
      final rec = await pumpSettings(
        t,
        data: data(),
        agentTab: 'instructions',
        window: 1280,
      );
      rec.selectWorkspace = (id) async {
        final h = host(t);
        h.updateData(
          h.data.copyWith(
            agent: h.data.agent.copyWith(
              systemPrompt: SettingsSystemPrompt(
                builtin: 'BASE',
                workspaceId: id,
                workspaceName: id,
              ),
              workspacePrefix: () => id == 'b' ? 'B_PREFIX' : null,
            ),
          ),
        );
        return true;
      };
      rec.saveWorkspacePrefix =
          ({required text, required workspaceId, required expectedText}) async {
            expect(workspaceId, 'b');
            expect(expectedText, 'B_PREFIX');
            expect(text, 'B_EDIT');
            return true;
          };
      await select(t, 'inspire');
      expect(text(t), '');
      await select(t, 'b');
      expect(text(t), 'B_PREFIX');
      await t.ensureVisible(field());
      await t.enterText(field(), 'B_EDIT');
      await save(t);
      await select(t, 'inspire');
      expect(text(t), '');
      expect(t.widget<TextField>(field()).readOnly, false);
      expect(t.takeException(), isNull);
    },
  );

  for (final locale in ['zh', 'en', 'ja', 'ko', 'zh_TW']) {
    for (final dark in [false, true]) {
      for (final window in [900.0, 1280.0]) {
        testWidgets(
          'workspace prefix layout $locale dark=$dark window=$window',
          (t) async {
            await pumpSettings(
              t,
              data: data(),
              agentTab: 'instructions',
              window: window,
              height: 1200,
              uiScale: window == 900 ? 1.5 : 1,
              locale: locale,
              dark: dark,
            );
            await select(t, 'inspire');
            expect(text(t), '');
            expect(t.widget<TextField>(field()).readOnly, false);
            expect(
              find.byKey(const Key('agent-workspace-prefix-inherit')),
              findsNothing,
            );
            await t.ensureVisible(field());
            await t.pumpAndSettle();
            if (locale == 'zh' && dark && window == 1280) {
              await captureUiuxRegion(
                t,
                find.byKey(const Key('settings-capture')),
                'workspace-prefix-inherited',
                Offset.zero &
                    t.getSize(find.byKey(const Key('settings-capture'))),
              );
            }
            await t.enterText(
              field(),
              'Creative assistant\nUse concise answers. 创作助手',
            );
            await t.pumpAndSettle();
            expect(t.widget<TextField>(field()).readOnly, false);
            expect(
              t.getTopLeft(field()).dy,
              greaterThan(
                t
                    .getBottomLeft(find.byKey(const Key('agent-project-rules')))
                    .dy,
              ),
            );
            expect(t.takeException(), isNull);
            if (locale == 'zh' && dark && window == 1280 ||
                locale == 'en' && dark && window == 900) {
              await captureUiuxRegion(
                t,
                find.byKey(const Key('settings-capture')),
                'workspace-prefix-$locale-${window.toInt()}',
                Offset.zero &
                    t.getSize(find.byKey(const Key('settings-capture'))),
              );
            }
          },
        );
      }
    }
  }
}
