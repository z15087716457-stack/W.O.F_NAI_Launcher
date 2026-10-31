// 接线补齐：账号余额 / 订阅“未读取”；Agent 基础提示词（全局 / 工作区分开、沿用全局、恢复内置、保存保护）。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  Future<void> tap(WidgetTester t, Finder f) async {
    await t.ensureVisible(f.first);
    await t.pumpAndSettle();
    await t.tap(f.first);
    await t.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester t, String key) =>
      tap(t, find.byKey(Key(key)));

  group('账号未读取', () {
    SettingsViewData unread(SettingsPageId page) =>
        SettingsFixture.view(page: page).copyWith(
          account: const SettingsAccountData(
            accounts: [
              SettingsAccount(
                id: 'cur',
                name: '鹈鹕',
                tier: null,
                anlas: null,
                loginKind: SettingsLoginKind.email,
                maskedId: 'pelican@****.com',
                current: true,
              ),
              SettingsAccount(
                id: 'zero',
                name: '零',
                tier: SettingsTier.none,
                anlas: 0,
                loginKind: SettingsLoginKind.token,
                maskedId: 'pst-****0001',
              ),
            ],
          ),
        );

    testWidgets('账号页：未读取不显示成 0 / 无订阅，已知 0 照旧', (t) async {
      await pumpSettings(t, data: unread(SettingsPageId.account));
      expect(find.byKey(const Key('account-unread-cur')), findsOneWidget);
      expect(find.byKey(const Key('account-unread-zero')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('account-zero')),
          matching: find.text('0'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('account-cur')),
          matching: find.text('0'),
        ),
        findsNothing,
      );
      expect(find.text('Opus'), findsNothing);
      expect(find.text('无订阅'), findsNothing);
    });

    testWidgets('概览和搜索：余额显示未读取', (t) async {
      await pumpSettings(t, data: unread(SettingsPageId.overview));
      expect(find.text('Anlas · 未读取'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('搜索：余额显示未读取', (t) async {
      await pumpSettings(
        t,
        data: unread(SettingsPageId.overview),
        initialQuery: 'anlas',
      );
      expect(find.text('未读取 · 鹈鹕', findRichText: true), findsOneWidget);
    });
  });

  testWidgets('全局 AGENTS.md 提示仅作空白提示，不写入指令或触发保存', (t) async {
    for (final locale in ['zh', 'en', 'ja', 'ko', 'zh_TW']) {
      await t.pumpWidget(const SizedBox.shrink());
      final d = SettingsFixture.view(page: SettingsPageId.agent);
      final rec = await pumpSettings(
        t,
        data: d.copyWith(agent: d.agent.copyWith(globalInstructions: '')),
        locale: locale,
        agentTab: 'instructions',
      );
      final global = find.byKey(const Key('agent-global'));
      final l = AppLocalizations.of(t.element(global))!;
      final input = find.descendant(
        of: global,
        matching: find.byType(TextField),
      );
      final decoration = find.descendant(
        of: global,
        matching: find.byType(InputDecorator),
      );
      expect(
        t.widget<TextField>(input).decoration!.hintText,
        l.set_agGlobalHint,
      );
      expect(t.widget<TextField>(input).controller!.text, isEmpty);
      expect(t.widget<InputDecorator>(decoration).isEmpty, isTrue);
      await t.enterText(input, 'fixture global rules');
      await t.pump();
      expect(t.widget<InputDecorator>(decoration).isEmpty, isFalse);
      expect(
        t.widget<TextField>(input).controller!.text,
        'fixture global rules',
      );
      expect(rec.calls, isEmpty);
      await t.enterText(input, '');
      await t.pump();
      expect(t.widget<InputDecorator>(decoration).isEmpty, isTrue);
      expect(find.byKey(const Key('agent-unsaved')), findsNothing);
      expect(rec.calls, isEmpty);
    }
  });

  testWidgets('生效顺序：内置提示词前 → 内置系统提示词 → 全局指令 → 工作区规则 → Skill 目录', (t) async {
    await pumpSettings(t, page: SettingsPageId.agent, agentTab: 'instructions');
    double x(String s) => t
        .getTopLeft(
          find.descendant(
            of: find.byType(SettingsChip),
            matching: find.text(s),
          ),
        )
        .dx;
    final xs = [
      for (final s in ['内置提示词前', '内置系统提示词', '全局指令', '工作区规则', 'Skill 目录']) x(s),
    ];
    expect([...xs]..sort(), xs);
  });

  testWidgets('MCP 尚未连接：灰点中性状态，不出登录、不算出错', (t) async {
    final d = SettingsFixture.view(page: SettingsPageId.agent);
    await pumpSettings(
      t,
      data: d.copyWith(
        agent: SettingsAgentData(
          mcp: const [
            SettingsMcpServer(
              id: 'fs',
              name: 'filesystem',
              transport: 'stdio · npx',
              state: SettingsMcpState.unchecked,
              mode: SettingsMcpMode.deferred,
            ),
          ],
          tools: d.agent.tools,
        ),
      ),
      agentTab: 'tools',
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('mcp-fs')),
        matching: find.text('尚未连接'),
      ),
      findsOneWidget,
    );
    expect(find.text('连接失败'), findsNothing);
    expect(find.text('登录'), findsNothing);
  });

  group('基础提示词', () {
    SettingsViewData withPrompt([SettingsSystemPrompt? sp]) {
      final d = SettingsFixture.view(page: SettingsPageId.agent);
      return d.copyWith(
        agent: d.agent.copyWith(
          systemPrompt: sp ?? SettingsFixture.systemPrompt,
        ),
      );
    }

    Future<void> saveDock(WidgetTester t) => tap(
      t,
      find.descendant(
        of: find.byKey(const Key('agent-unsaved')),
        matching: find.text('保存'),
      ),
    );

    testWidgets('没给数据就不显示', (t) async {
      await pumpSettings(
        t,
        page: SettingsPageId.agent,
        agentTab: 'instructions',
      );
      expect(find.byKey(const Key('agent-base')), findsNothing);
    });

    testWidgets('全局：展开、编辑、底栏保存，带上工作区核对', (t) async {
      final rec = await pumpSettings(
        t,
        data: withPrompt(),
        agentTab: 'instructions',
      );
      expect(find.text('全局：内置 · 工作区「灵感」：沿用全局'), findsOneWidget);
      expect(find.byKey(const Key('agent-base-editor')), findsNothing);
      await tapKey(t, 'agent-base-toggle');
      expect(find.byKey(const Key('agent-base-editor')), findsOneWidget);
      expect(find.textContaining('你是 NAI Studio 里的创作助手'), findsOneWidget);
      await tapKey(t, 'agent-base-restore');
      expect(
        find.byKey(const Key('settings-confirm')),
        findsNothing,
        reason: '全局没自定义时“恢复内置”不可点',
      );
      await t.enterText(find.byKey(const Key('agent-base-text')), '新基础');
      await t.pumpAndSettle();
      expect(find.text('Agent 指令有未保存的修改'), findsOneWidget);
      expect(rec.calls, isEmpty);
      await saveDock(t);
      expect(rec.calls, ['savePrompt:global:新基础:inspire']);
      expect(find.byKey(const Key('agent-unsaved')), findsNothing);
    });

    testWidgets('工作区：沿用全局只读，关掉才单独保存；再打开存 null', (t) async {
      final rec = await pumpSettings(
        t,
        data: withPrompt(),
        agentTab: 'instructions',
      );
      await tapKey(t, 'agent-base-toggle');
      await tap(t, find.text('工作区 · 灵感'));
      final inherit = find.byKey(const Key('agent-base-inherit'));
      expect(inherit, findsOneWidget);
      final field = find.descendant(
        of: find.byKey(const Key('agent-base-text')),
        matching: find.byType(TextField),
      );
      expect(t.widget<TextField>(field).readOnly, isTrue);
      await tap(t, inherit);
      expect(t.widget<TextField>(field).readOnly, isFalse);
      await t.enterText(find.byKey(const Key('agent-base-text')), '工作区专用');
      await t.pumpAndSettle();
      await saveDock(t);
      expect(rec.calls, ['savePrompt:workspace:工作区专用:inspire']);
      await tap(t, inherit);
      await saveDock(t);
      expect(rec.calls.last, 'savePrompt:workspace:null:inspire');
    });

    testWidgets('有草稿时切范围要确认；离开本页也要确认', (t) async {
      final rec = await pumpSettings(
        t,
        data: withPrompt(),
        agentTab: 'instructions',
      );
      await tapKey(t, 'agent-base-toggle');
      await t.enterText(find.byKey(const Key('agent-base-text')), '草稿');
      await t.pumpAndSettle();
      await tap(t, find.text('工作区 · 灵感'));
      expect(find.text('放弃内置系统提示词的修改？'), findsOneWidget);
      await tapKey(t, 'confirm-cancel');
      expect(find.byKey(const Key('agent-base-inherit')), findsNothing);
      await tapKey(t, 'settings-nav-network');
      expect(find.byKey(const Key('settings-confirm')), findsOneWidget);
      expect(rec.pages, isEmpty);
      await tapKey(t, 'confirm-cancel');
      await tap(t, find.text('工作区 · 灵感'));
      await tapKey(t, 'confirm-ok');
      expect(find.byKey(const Key('agent-base-inherit')), findsOneWidget);
      expect(find.byKey(const Key('agent-unsaved')), findsNothing);
      expect(rec.calls, isEmpty);
    });

    testWidgets('保存失败保留草稿并提示', (t) async {
      final rec = await pumpSettings(
        t,
        data: withPrompt(),
        agentTab: 'instructions',
      );
      rec.promptResult = false;
      await tapKey(t, 'agent-base-toggle');
      await t.enterText(find.byKey(const Key('agent-base-text')), '会失败');
      await t.pumpAndSettle();
      await saveDock(t);
      expect(rec.calls, ['savePrompt:global:会失败:inspire']);
      expect(find.byKey(const Key('agent-base-status')), findsOneWidget);
      expect(find.byKey(const Key('agent-unsaved')), findsOneWidget);
      expect(find.text('会失败'), findsOneWidget);
    });

    testWidgets('全局已自定义：恢复内置先确认，存 null', (t) async {
      final rec = await pumpSettings(
        t,
        data: withPrompt(
          const SettingsSystemPrompt(
            builtin: '内置正文',
            global: '我的全局',
            workspaceId: 'inspire',
            workspaceName: '灵感',
            workspace: '工作区正文',
          ),
        ),
        agentTab: 'instructions',
      );
      expect(find.text('全局：已自定义 · 工作区「灵感」：单独设置'), findsOneWidget);
      await tapKey(t, 'agent-base-toggle');
      expect(find.text('我的全局'), findsOneWidget);
      await tapKey(t, 'agent-base-restore');
      expect(find.text('恢复内置系统提示词？'), findsOneWidget);
      await tapKey(t, 'confirm-ok');
      expect(rec.calls, ['savePrompt:global:null:inspire']);
      expect(find.text('内置正文'), findsOneWidget);
    });

    testWidgets('没有工作区时只出全局', (t) async {
      await pumpSettings(
        t,
        data: withPrompt(const SettingsSystemPrompt(builtin: '内置正文')),
        agentTab: 'instructions',
      );
      expect(find.text('全局：内置'), findsOneWidget);
      await tapKey(t, 'agent-base-toggle');
      expect(find.byKey(const Key('agent-base-scope')), findsNothing);
    });

    testWidgets('搜索能找到，跳过去高亮这一行', (t) async {
      final rec = await pumpSettings(
        t,
        data: withPrompt().copyWith(page: SettingsPageId.overview),
        initialQuery: '系统提示词',
      );
      expect(find.byKey(const Key('agent-base')), findsNothing);
      expect(find.byKey(const Key('hit-agentSystemPrompt')), findsOneWidget);
      await tapKey(t, 'jump-agentSystemPrompt');
      expect(rec.pages.last, SettingsPageId.agent);
      expect(find.byKey(const Key('agent-base')), findsOneWidget);
    });
  });
}
