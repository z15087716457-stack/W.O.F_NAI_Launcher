// 设置页交互：目录、自动保存与撤销、恢复默认、搜索、需重启、确认框、Agent 草稿、快捷键录制。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_kit.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_colors.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'settings_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  Future<void> tap(WidgetTester t, String key) async {
    final f = find.byKey(Key(key));
    await t.ensureVisible(f.first);
    await t.pumpAndSettle();
    await t.tap(f.first);
    await t.pumpAndSettle();
  }

  testWidgets('默认打开概览，目录切页走 onOpenPage', (t) async {
    final rec = await pumpSettings(t);
    expect(find.byKey(const Key('settings-account-hero')), findsOneWidget);
    expect(find.byKey(const Key('settings-attention')), findsOneWidget);
    await tap(t, 'settings-nav-network');
    expect(rec.pages, [SettingsPageId.network]);
    expect(find.byKey(const Key('endpoint-github.com')), findsOneWidget);
  });

  testWidgets('概览卡片跳到对应页', (t) async {
    final rec = await pumpSettings(t);
    await tap(t, 'settings-tile-${SettingsPageId.rag.name}');
    expect(rec.pages.last, SettingsPageId.rag);
  });

  testWidgets('开关直接回调，底部弹“已保存 · 撤销”，撤销带 id', (t) async {
    final rec = await pumpSettings(t, page: SettingsPageId.appearance);
    await tap(t, 'switch-completionSound');
    expect(rec.changes.single, (SettingKey.completionSound, false));
    expect(find.byKey(const Key('settings-toast')), findsOneWidget);
    await t.tap(
      find.descendant(
        of: find.byKey(const Key('settings-toast')),
        matching: find.text('撤销'),
      ),
    );
    await t.pumpAndSettle();
    expect(rec.calls, contains('undo:c1'));
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('默认跟随系统，主题选项按系统、浅色、深色排列且仍可手动选择', (t) async {
    final rec = await pumpSettings(
      t,
      page: SettingsPageId.appearance,
      data: SettingsFixture.view(
        page: SettingsPageId.appearance,
      ).copyWith(values: const SettingsValues({})),
    );
    final system = find.byKey(const Key('theme-system'));
    final light = find.byKey(const Key('theme-light'));
    final dark = find.byKey(const Key('theme-dark'));
    expect(t.getTopLeft(system).dx, lessThan(t.getTopLeft(light).dx));
    expect(t.getTopLeft(light).dx, lessThan(t.getTopLeft(dark).dx));
    expect(t.widget<SettingsOptionCard>(system).selected, isTrue);
    await t.tap(dark);
    await t.pumpAndSettle();
    expect(rec.changes.single, (SettingKey.themeMode, 'dark'));
    expect(t.widget<SettingsOptionCard>(dark).selected, isTrue);
    expect(t.widget<SettingsOptionCard>(system).selected, isFalse);
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('分段和步进直接改值', (t) async {
    final rec = await pumpSettings(t, page: SettingsPageId.generation);
    final seg = find.byKey(const Key('seg-wheelModifier'));
    await t.ensureVisible(seg);
    await t.pumpAndSettle();
    await t.tap(find.descendant(of: seg, matching: find.text('Ctrl')));
    await t.pumpAndSettle();
    expect(rec.changes.last, (SettingKey.wheelModifier, 'ctrl'));
    await tap(t, 'stepper-costThreshold');
    expect(rec.changes.length, 1, reason: '点数字本身不改值');
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('已修改的项有蓝点，“恢复本页默认”先确认', (t) async {
    final rec = await pumpSettings(t, page: SettingsPageId.generation);
    expect(find.byKey(const Key('settings-modified-dot')), findsWidgets);
    await tap(t, 'settings-reset-page');
    expect(find.byKey(const Key('settings-confirm')), findsOneWidget);
    expect(rec.calls, isEmpty);
    await tap(t, 'confirm-ok');
    expect(rec.calls, ['resetPage:generation']);
  });

  testWidgets('取消确认不回调', (t) async {
    final rec = await pumpSettings(t, page: SettingsPageId.dictionaries);
    await tap(t, 'clear-danbooru');
    await tap(t, 'confirm-cancel');
    expect(rec.calls, isEmpty);
    await tap(t, 'clear-danbooru');
    await tap(t, 'confirm-ok');
    expect(rec.calls, ['clearCache:danbooru']);
  });

  testWidgets('Ctrl+F 聚焦搜索，结果里的开关可以直接改', (t) async {
    final rec = await pumpSettings(t);
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyF);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('settings-search-input')), '元数据');
    await t.pumpAndSettle();
    expect(find.byKey(const Key('hit-stripMetadata')), findsOneWidget);
    await tap(t, 'switch-stripMetadata');
    expect(rec.changes.single, (SettingKey.stripMetadata, false));
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('搜索英文键名和同义词也能命中', (t) async {
    await pumpSettings(t, initialQuery: 'proxy');
    expect(find.byKey(const Key('hit-proxyEnabled')), findsOneWidget);
  });

  testWidgets('搜索无结果给提示', (t) async {
    await pumpSettings(t, initialQuery: 'zzzz');
    expect(find.byKey(const Key('search-empty')), findsOneWidget);
  });

  testWidgets('搜索框里 ↓ 选下一条，Enter 跳过去', (t) async {
    final rec = await pumpSettings(t);
    await t.enterText(find.byKey(const Key('settings-search-input')), 'proxy');
    await t.pumpAndSettle();
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    expect(rec.pages.last, SettingsPageId.network);
  });

  testWidgets('搜索结果跳转到所在页', (t) async {
    final rec = await pumpSettings(t, initialQuery: 'proxy');
    await tap(t, 'jump-proxyEnabled');
    expect(rec.pages.last, SettingsPageId.network);
  });

  testWidgets('需重启：提示条“立即重启”回调，“稍后”收起', (t) async {
    final rec = await pumpSettings(
      t,
      page: SettingsPageId.network,
      scene: SettingsScene.restart,
    );
    expect(find.byKey(const Key('settings-restart-banner')), findsOneWidget);
    await t.tap(find.text('立即重启'));
    await t.pumpAndSettle();
    expect(rec.calls, contains('restart'));
    await tap(t, 'restart-later');
    expect(find.byKey(const Key('settings-restart-banner')), findsNothing);
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('Agent 指令是草稿：改了出底栏，保存才回调', (t) async {
    final rec = await pumpSettings(
      t,
      page: SettingsPageId.agent,
      agentTab: 'instructions',
    );
    expect(find.byKey(const Key('agent-unsaved')), findsNothing);
    await t.enterText(find.byKey(const Key('agent-global')), '新指令');
    await t.pumpAndSettle();
    expect(find.byKey(const Key('agent-unsaved')), findsOneWidget);
    expect(rec.calls, isEmpty);
    await t.tap(
      find.descendant(
        of: find.byKey(const Key('agent-unsaved')),
        matching: find.text('保存'),
      ),
    );
    await t.pumpAndSettle();
    expect(rec.calls, ['saveInstructions:新指令']);
  });

  testWidgets('快捷键：点组合进入录制，按下的组合规范化后回调', (t) async {
    final rec = await pumpSettings(t, page: SettingsPageId.shortcuts);
    await tap(t, 'shortcut-keys-clear');
    expect(find.byKey(const Key('shortcut-recorder')), findsOneWidget);
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyK);
    await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pumpAndSettle();
    expect(rec.calls.where((c) => c.startsWith('record:')), [
      'record:clear:Ctrl+Shift+K',
    ]);
  });

  testWidgets('快捷键冲突列出并可一键修复', (t) async {
    await pumpSettings(t, page: SettingsPageId.shortcuts);
    expect(find.byKey(const Key('shortcut-conflicts')), findsOneWidget);
  });

  testWidgets('全部视图允许互斥页面复用同一按键，不误标红', (t) async {
    await pumpSettings(
      t,
      data: SettingsFixture.view(page: SettingsPageId.shortcuts).copyWith(
        shortcuts: const SettingsShortcutsData(
          contexts: [
            SettingsShortcutContext(id: 'global', label: '全局'),
            SettingsShortcutContext(id: 'generation', label: '生图'),
            SettingsShortcutContext(id: 'viewer', label: '大图'),
          ],
          shortcuts: [
            SettingsShortcut(
              id: 'g',
              context: 'generation',
              label: '生图复用',
              keys: ['Ctrl', 'R'],
              defaultKeys: ['Ctrl', 'R'],
            ),
            SettingsShortcut(
              id: 'v',
              context: 'viewer',
              label: '大图复用',
              keys: ['Ctrl', 'R'],
              defaultKeys: ['Ctrl', 'R'],
            ),
          ],
        ),
      ),
    );
    await t.tap(find.widgetWithText(SettingsChip, '全部'));
    await t.pumpAndSettle();
    final key = find.byKey(const Key('key-R'));
    final box = t.widget<Container>(
      find.descendant(of: key, matching: find.byType(Container)).first,
    );
    final border = (box.decoration! as BoxDecoration).border! as Border;
    expect(border.top.color, isNot(t.element(key).ui.error));
    expect(
      find.descendant(
        of: find.byKey(const Key('shortcut-conflicts')),
        matching: find.text('没有冲突'),
      ),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
  });

  for (final customized in [false, true]) {
    testWidgets('冲突摘要包含未改默认，优先修复自定义一侧：$customized', (t) async {
      final rec = await pumpSettings(
        t,
        data: SettingsFixture.view(page: SettingsPageId.shortcuts).copyWith(
          shortcuts: SettingsShortcutsData(
            contexts: const [
              SettingsShortcutContext(id: 'global', label: '全局'),
              SettingsShortcutContext(id: 'generation', label: '生成页面'),
            ],
            shortcuts: [
              const SettingsShortcut(
                id: 'default',
                context: 'global',
                label: '全局动作',
                keys: ['Ctrl', 'M'],
                defaultKeys: ['Ctrl', 'M'],
                conflictWith: 'local',
              ),
              SettingsShortcut(
                id: 'local',
                context: 'generation',
                label: '页面动作',
                keys: const ['Ctrl', 'M'],
                defaultKeys: customized
                    ? const ['Alt', 'M']
                    : const ['Ctrl', 'M'],
                conflictWith: 'default',
              ),
            ],
          ),
        ),
      );
      final aside = find.byKey(const Key('shortcut-conflicts'));
      expect(
        find.descendant(of: aside, matching: find.text('没有冲突')),
        findsNothing,
      );
      expect(
        find.descendant(of: aside, matching: find.text('1 项')),
        findsOneWidget,
      );
      if (customized) {
        await t.tap(find.byKey(const Key('shortcut-fix-local')));
        await t.pumpAndSettle();
        expect(rec.calls, ['resetShortcut:local']);
      }
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('黑名单：回车添加，点叉移除', (t) async {
    final rec = await pumpSettings(t, page: SettingsPageId.privacy);
    await t.enterText(find.byKey(const Key('blacklist-input')), 'sketch');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    expect(rec.calls, contains('addTag:sketch'));
  });

  testWidgets('账号页列出过期账号', (t) async {
    final rec = await pumpSettings(t, page: SettingsPageId.account);
    expect(find.byKey(const Key('account-test')), findsOneWidget);
    expect(rec.calls, isEmpty);
  });

  testWidgets('新装：概览不崩，账号区给出添加入口', (t) async {
    await pumpSettings(t, scene: SettingsScene.fresh);
    expect(t.takeException(), isNull);
  });

  testWidgets('契约：每个 SettingKey 都有 spec，默认值类型和种类一致', (t) async {
    for (final k in SettingKey.values) {
      final s = SettingSpec.of(k);
      final d = s.defaultValue;
      switch (s.kind) {
        case SettingKind.toggle:
          expect(d, isA<bool>(), reason: k.name);
        case SettingKind.number:
          expect(d, isA<double>(), reason: k.name);
          expect(d! as double, inInclusiveRange(s.min, s.max), reason: k.name);
        case SettingKind.choice:
          if (s.choices.isNotEmpty) {
            expect(s.choices, contains(d), reason: k.name);
          }
        case SettingKind.path || SettingKind.text:
          expect(d == null || d is String, isTrue, reason: k.name);
      }
    }
  });

  testWidgets('假数据：标为已修改的项确实和默认值不同', (t) async {
    const v = SettingsFixture.values;
    for (final k in SettingsFixture.modified) {
      expect(v[k], isNot(SettingSpec.of(k).defaultValue), reason: k.name);
    }
  });

  testWidgets('默认值和现有实现一致（接线时不能把用户的真实设置当成“已修改”）', (t) async {
    const expected = <SettingKey, Object?>{
      SettingKey.themeMode: 'system',
      SettingKey.fontFamily: 'system',
      SettingKey.language: 'zh',
      SettingKey.shortcutsInMenus: false,
      SettingKey.navNumberBadges: true,
      SettingKey.costWarning: false,
      SettingKey.costThreshold: 50.0,
      SettingKey.intervalLimit: false,
      SettingKey.intervalSeconds: 5.0,
      SettingKey.intervalJitter: 0.0,
      SettingKey.agentMaxRequests: 32.0,
      SettingKey.ragEnabled: false,
      SettingKey.ragContext: 'around',
      SettingKey.ragDevice: 'auto',
      SettingKey.seedCpuOffload: 0.0,
      SettingKey.seedVaeTiling: true,
      SettingKey.seedVaeTile: '1024',
      SettingKey.proxyEnabled: true,
      SettingKey.blacklistAutoSync: true,
      SettingKey.stripMetadata: false,
      SettingKey.comfyEnabled: false,
      SettingKey.kritaBridge: false,
    };
    for (final MapEntry(:key, :value) in expected.entries) {
      expect(SettingSpec.of(key).defaultValue, value, reason: key.name);
    }
  });

  group('语义检索', () {
    Future<SettingsRecorder> rag(WidgetTester t, SettingsRagData d) =>
        pumpSettings(
          t,
          data: SettingsFixture.view(page: SettingsPageId.rag).copyWith(rag: d),
        );

    testWidgets('重新安装先在原地选 CUDA / CPU，再回调', (t) async {
      final rec = await pumpSettings(t, page: SettingsPageId.rag);
      expect(find.byKey(const Key('rag-install-choice')), findsNothing);
      await tap(t, 'rag-reinstall');
      expect(find.byKey(const Key('rag-install-choice')), findsOneWidget);
      expect(rec.calls, isEmpty);
      await tap(t, 'rag-install-cpu');
      expect(rec.calls, ['ragInstall:false']);
      expect(find.byKey(const Key('rag-install-choice')), findsNothing);
    });

    testWidgets('下载模型、查找本地模型、选解释器', (t) async {
      final rec = await pumpSettings(t, page: SettingsPageId.rag);
      await tap(t, 'rag-download-btn-reranker');
      await tap(t, 'rag-discover-btn');
      final py = find.byKey(const Key('path-ragPythonPath'));
      await t.ensureVisible(py);
      await t.pumpAndSettle();
      expect(
        find.descendant(of: py, matching: find.text('自动')),
        findsOneWidget,
        reason: '没选解释器时显示当前环境并标“自动”',
      );
      await t.tap(find.descendant(of: py, matching: find.byTooltip('更改')));
      await t.pumpAndSettle();
      expect(rec.calls, [
        'ragDownload:reranker',
        'ragDiscover',
        'pickPath:ragPythonPath',
      ]);
    });

    testWidgets('下载中：进度行、取消；其他重活按钮不可点', (t) async {
      final rec = await rag(t, SettingsFixture.ragBusy);
      expect(find.byKey(const Key('rag-download-embedder')), findsOneWidget);
      expect(find.byKey(const Key('rag-error')), findsOneWidget);
      expect(find.byKey(const Key('rag-models-missing')), findsOneWidget);
      await tap(t, 'rag-download-btn-reranker');
      await tap(t, 'rag-use-python');
      expect(rec.calls, isEmpty, reason: '下载中不能再开别的重活');
      await tap(t, 'rag-download-cancel-embedder');
      expect(rec.calls, ['ragCancelDownload']);
    });

    testWidgets('计划卡原地确认：开始 / 取消', (t) async {
      final rec = await rag(
        t,
        const SettingsRagData(
          runtimeReady: true,
          plan: SettingsRagPlan(kind: SettingsRagSourceKind.wiki),
          sources: [
            SettingsRagSource(
              kind: SettingsRagSourceKind.wiki,
              state: SettingsRagState.empty,
            ),
          ],
        ),
      );
      expect(find.byKey(const Key('rag-plan-wiki')), findsOneWidget);
      await tap(t, 'rag-plan-start');
      await tap(t, 'rag-plan-cancel');
      expect(rec.calls, ['ragStartPlan', 'ragCancelPlan']);
    });

    testWidgets('未建库的来源出“建立索引”，空闲时可点', (t) async {
      const idle = SettingsRagData(
        runtimeReady: true,
        pythonPending: true,
        sources: [
          SettingsRagSource(
            kind: SettingsRagSourceKind.tags,
            state: SettingsRagState.empty,
          ),
          SettingsRagSource(
            kind: SettingsRagSourceKind.wiki,
            state: SettingsRagState.ready,
            done: 10,
            total: 20,
          ),
        ],
      );
      final rec = await rag(t, idle);
      await tap(t, 'rag-build-tags');
      await tap(t, 'rag-build-wiki');
      await tap(t, 'rag-use-python');
      expect(rec.calls, ['ragBuild:tags', 'ragBuild:wiki', 'ragUsePython']);
    });

    testWidgets('安装中：阶段、用时、取消', (t) async {
      final rec = await rag(t, SettingsFixture.ragInstalling);
      expect(find.byKey(const Key('rag-install')), findsOneWidget);
      expect(find.textContaining('2:31'), findsOneWidget);
      expect(find.byKey(const Key('rag-plan-gallery')), findsOneWidget);
      await tap(t, 'rag-plan-start');
      expect(rec.calls, isEmpty, reason: '还在统计时“开始”不可点');
      await tap(t, 'rag-install-cancel');
      expect(rec.calls, ['ragCancelInstall']);
    });

    testWidgets('已完成的来源也能从“更多”重建 / 清除', (t) async {
      final rec = await pumpSettings(t, page: SettingsPageId.rag);
      expect(find.byKey(const Key('rag-more-tags')), findsOneWidget);
      expect(rec.calls, isEmpty);
    });
  });
}
