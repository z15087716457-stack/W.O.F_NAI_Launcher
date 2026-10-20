import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_scope.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  Finder key(String k) => find.byKey(Key(k));

  testWidgets('默认常规页：模型和快捷信息，其余分页的内容不出现', (t) async {
    await pumpSettings(t, page: SettingsPageId.agent);
    expect(key('agent-tabs'), findsOneWidget);
    expect(key('select-agentModel'), findsOneWidget);
    expect(key('quick-add'), findsOneWidget);
    expect(key('agent-trash-card'), findsOneWidget);
    expect(key('agent-global'), findsNothing);
    expect(key('skill-add'), findsNothing);
    expect(key('mcp-fs'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('每个分页只放自己的分区和侧卡', (t) async {
    await pumpSettings(t, page: SettingsPageId.agent, agentTab: 'instructions');
    expect(key('agent-global'), findsOneWidget);
    expect(key('agent-context'), findsOneWidget);
    expect(key('select-agentModel'), findsNothing);

    await openAgentTab(t, 'skills');
    expect(key('skill-add'), findsOneWidget);
    expect(key('agent-skill-folders'), findsOneWidget);
    expect(key('agent-global'), findsNothing);

    await openAgentTab(t, 'tools');
    expect(find.textContaining('read_prompt'), findsWidgets);
    expect(key('skill-add'), findsNothing);
    expect(key('agent-trash-card'), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets('切走再回来，指令草稿和底栏还在；指令分页带小圆点', (t) async {
    await pumpSettings(t, page: SettingsPageId.agent, agentTab: 'instructions');
    expect(key('agent-tab-dirty'), findsNothing);
    await t.enterText(key('agent-global'), '草稿');
    await t.pumpAndSettle();
    expect(key('agent-tab-dirty'), findsOneWidget);
    await openAgentTab(t, 'skills');
    expect(key('agent-unsaved'), findsOneWidget);
    expect(key('agent-tab-dirty'), findsOneWidget);
    await openAgentTab(t, 'instructions');
    expect(find.text('草稿'), findsOneWidget);
  });

  testWidgets('离开再进来记住上次的分页', (t) async {
    final rec = await pumpSettings(
      t,
      page: SettingsPageId.agent,
      agentTab: 'tools',
    );
    final host = t.state<SettingsHostState>(find.byType(SettingsHost));
    host.updateData(host.data.copyWith(page: SettingsPageId.network));
    await t.pumpAndSettle();
    expect(key('agent-tabs'), findsNothing);
    host.updateData(host.data.copyWith(page: SettingsPageId.agent));
    await t.pumpAndSettle();
    expect(key('skill-add'), findsNothing);
    expect(key('mcp-fs'), findsOneWidget);
    expect(rec.calls, isEmpty);
  });

  testWidgets('搜索跳转先切到锚点所在分页再高亮', (t) async {
    final rec = await pumpSettings(t, initialQuery: 'skill');
    await t.tap(key('jump-agentSkills'));
    await t.pumpAndSettle();
    expect(rec.pages.last, SettingsPageId.agent);
    expect(key('skill-add'), findsOneWidget);
    expect(key('settings-anchor-agentSkills'), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('“去设置”跳到单次请求上限：从别的分页切回常规', (t) async {
    final rec = await pumpSettings(
      t,
      page: SettingsPageId.agent,
      agentTab: 'tools',
    );
    SettingsScope.of(
      t.element(find.byKey(const Key('agent-tabs'))),
    ).jump(SettingsPageId.agent, anchor: 'agentMaxRequests');
    await t.pumpAndSettle();
    expect(key('select-agentModel'), findsOneWidget);
    expect(key('stepper-agentMaxRequests'), findsOneWidget);
    expect(rec.calls, isEmpty);
    await t.pump(const Duration(seconds: 3));
  });

  for (final locale in ['en', 'ja', 'ko', 'zh_TW']) {
    testWidgets('分页条在 $locale 窄窗下不溢出', (t) async {
      await pumpSettings(
        t,
        page: SettingsPageId.agent,
        locale: locale,
        window: 900,
      );
      expect(key('agent-tabs'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
}
