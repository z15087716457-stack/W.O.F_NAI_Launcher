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
    );
    await t.scrollUntilVisible(
      find.byKey(const Key('skill-add')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await t.pump();
    return rec;
  }

  testWidgets('Skill 分区：内置只读、用户可开关／改调用方式、出错行不给开关', (t) async {
    final rec = await open(t);
    final builtin = find.byKey(const Key('skill-builtin/nai-studio'));
    await t.ensureVisible(builtin);
    await t.pump();
    expect(
      find.descendant(of: builtin, matching: find.byType(SettingsSwitch)),
      findsNothing,
    );
    await t.tap(find.descendant(of: builtin, matching: find.text('查看')));
    expect(rec.calls, contains('viewSkill:builtin/nai-studio'));

    final user = find.byKey(const Key('skill-global/style-replica'));
    await t.ensureVisible(user);
    await t.pump();
    await t.tap(
      find.descendant(of: user, matching: find.byType(SettingsSwitch)),
    );
    expect(rec.calls, contains('skillEnabled:global/style-replica:false'));
    await t.tap(find.byKey(const Key('skill-mode-global/style-replica')));
    await t.pumpAndSettle();
    await t.tap(find.text('仅手动').last);
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
    final rec = await pumpSettings(t, page: SettingsPageId.agent);
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
