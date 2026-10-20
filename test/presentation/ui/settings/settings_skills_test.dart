import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  Future<SettingsRecorder> open(WidgetTester t, {String locale = 'zh'}) async {
    final rec = await pumpSettings(
      t,
      page: SettingsPageId.agent,
      locale: locale,
      agentTab: 'skills',
    );
    await t.scrollUntilVisible(
      find.byKey(const Key('skill-add')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await t.pump();
    return rec;
  }

  testWidgets('默认模型：按钮和下拉项左边是厂商图标，自定义端点才用字母', (t) async {
    await pumpSettings(t, page: SettingsPageId.agent);
    expect(find.text('默认模型'), findsOneWidget);
    final select = find.byKey(const Key('select-agentModel'));
    // 当前选中的是 Anthropic 预设：按钮左边画品牌图标，不画字母块。
    final current = t.widget<SettingsLogo>(
      find.descendant(of: select, matching: find.byType(SettingsLogo)),
    );
    expect(current.logoAsset, 'anthropic');
    await t.tap(select);
    await t.pump();
    SettingsLogo logo(String value) => t.widget<SettingsLogo>(
      find.descendant(
        of: find.byKey(Key('settings-option-$value')),
        matching: find.byType(SettingsLogo),
      ),
    );
    expect(logo('claude-sonnet-4.5').logoAsset, 'anthropic');
    expect(logo('gpt-4.1').logoAsset, 'openai');
    expect(logo('deepseek-chat').logoAsset, isNull);
    expect(logo('deepseek-chat').mark, 'DS');
  });

  testWidgets('快捷信息分区：列出、上下移、编辑、删除、新增、恢复默认', (t) async {
    final rec = await pumpSettings(t, page: SettingsPageId.agent);
    await t.scrollUntilVisible(
      find.byKey(const Key('quick-add')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await t.pump();
    expect(find.text('换成水彩'), findsOneWidget);
    expect(find.text('直接发送'), findsOneWidget);
    expect(find.text('欢迎页显示 2 / 2'), findsOneWidget);
    await t.ensureVisible(find.byKey(const Key('quick-builtin-review')));
    await t.pump();
    final warn = t.takeException();
    expect(warn, isNull);
    await t.tap(find.byKey(const Key('quick-up-mine')));
    await t.tap(find.byKey(const Key('quick-edit-mine')));
    await t.tap(find.byKey(const Key('quick-remove-builtin-review')));
    await t.tap(find.byKey(const Key('quick-add')));
    await t.tap(find.byKey(const Key('quick-restore')));
    // 第一条不能再上移，最后一条不能再下移。
    await t.tap(find.byKey(const Key('quick-up-builtin-review')));
    await t.tap(find.byKey(const Key('quick-down-mine')));
    expect(rec.calls, [
      'moveQuick:mine:-1',
      'editQuick:mine',
      'removeQuick:builtin-review',
      'editQuick:null',
      'restoreQuick',
    ]);
  });

  testWidgets('Skill 分区：内置置顶且可开关／改调用方式、用户同样、出错行不给开关', (t) async {
    final rec = await open(t);
    final builtin = find.byKey(const Key('skill-builtin/nai-studio'));
    await t.ensureVisible(builtin);
    await t.pump();
    final rows = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('skill-') &&
          (w.key! as ValueKey<String>).value.contains('/'),
    );
    final order = [
      for (final e in rows.evaluate())
        (e.widget.key! as ValueKey<String>).value,
    ].where((k) => !k.startsWith('skill-mode-')).toList();
    expect(order.take(2).every((k) => k.startsWith('skill-builtin/')), isTrue);
    await t.tap(
      find.descendant(of: builtin, matching: find.byType(SettingsSwitch)),
    );
    expect(rec.calls, contains('skillEnabled:builtin/nai-studio:false'));
    await t.tap(find.byKey(const Key('skill-mode-builtin/nai-studio')));
    await t.pumpAndSettle();
    // 菜单项在弹层里（第一个匹配）；下面某行的“仅手动调用”标签也会被找到。
    await t.tap(find.text('仅手动调用').first);
    await t.pumpAndSettle();
    expect(rec.calls, contains('skillManual:builtin/nai-studio:true'));

    final user = find.byKey(const Key('skill-global/style-replica'));
    await t.ensureVisible(user);
    await t.pump();
    await t.tap(
      find.descendant(of: user, matching: find.byType(SettingsSwitch)),
    );
    expect(rec.calls, contains('skillEnabled:global/style-replica:false'));
    await t.tap(find.byKey(const Key('skill-mode-global/style-replica')));
    await t.pumpAndSettle();
    await t.tap(find.text('仅手动调用').last);
    await t.pumpAndSettle();
    expect(rec.calls, contains('skillManual:global/style-replica:true'));

    final broken = find.byKey(const Key('skill-global/old-notes'));
    expect(
      find.descendant(of: broken, matching: find.byType(SettingsSwitch)),
      findsNothing,
    );
    expect(
      find.descendant(of: broken, matching: find.text('未加载')),
      findsOneWidget,
    );

    await t.ensureVisible(find.byKey(const Key('skill-add')));
    await t.pump();
    await t.tap(find.byKey(const Key('skill-add')));
    await t.tap(find.byKey(const Key('skill-new')));
    expect(rec.calls, containsAll(['addSkill', 'newSkill']));
    expect(find.text('5 个已加载'), findsOneWidget);
  });

  testWidgets('侧栏：常驻上下文与 Skill 位置；指令顺序末环是 Skill 目录', (t) async {
    final rec = await pumpSettings(
      t,
      page: SettingsPageId.agent,
      agentTab: 'skills',
    );
    expect(find.byKey(const Key('agent-context')), findsOneWidget);
    expect(find.text('Skill 目录 · 4 项'), findsOneWidget);
    expect(find.text('工具地图'), findsNothing);
    final folders = find.byKey(const Key('agent-skill-folders'));
    await t.tap(
      find
          .descendant(of: folders, matching: find.byType(SettingsIconBtn))
          .first,
    );
    expect(rec.calls, contains('openSkillRoot:global'));
  });

  for (final locale in ['en', 'ja', 'ko', 'zh_TW']) {
    testWidgets('Skill 分区在 $locale 下不溢出', (t) async {
      await open(t, locale: locale);
      expect(t.takeException(), isNull);
      expect(find.byKey(const Key('skill-builtin/nai-prompt')), findsOneWidget);
    });
  }
}
