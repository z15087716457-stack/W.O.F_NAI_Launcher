import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_contract.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_fixture.dart';
import 'package:nai_launcher/presentation/ui/nav/nav_tips.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'nav_test_harness.dart';

Finder _k(String key) => find.byKey(Key(key));

void main() {
  setUpAll(loadStudioCaptureFonts);

  group('图标栏', () {
    testWidgets('四组九页 + 设置，点图标切页', (tester) async {
      final rec = RecordingNavActions();
      await pumpNav(tester, data: NavFixture.view(), actions: rec.actions);
      for (final p in NavPage.values) {
        expect(_k('main-nav-${p.name}'), findsOneWidget, reason: p.name);
      }
      expect(find.byKey(const Key('main-nav-line-3')), findsOneWidget);
      await tester.tap(_k('main-nav-statistics'));
      await tester.tap(_k('main-nav-settings'));
      expect(rec.pages, [NavPage.statistics, NavPage.settings]);
    });

    testWidgets('隐藏的页面不显示；整组隐藏时分隔线也去掉；当前页和生图不受隐藏', (tester) async {
      await pumpNav(
        tester,
        data: NavFixture.view(
          current: NavPage.statistics,
          hidden: {
            NavPage.generation,
            NavPage.styleExplore,
            NavPage.tagWiki,
            NavPage.statistics,
          },
        ),
      );
      expect(_k('main-nav-generation'), findsOneWidget);
      expect(_k('main-nav-styleExplore'), findsNothing);
      expect(_k('main-nav-tagWiki'), findsNothing);
      expect(_k('main-nav-statistics'), findsOneWidget);

      await pumpNav(
        tester,
        data: NavFixture.view(hidden: {NavPage.tagWiki, NavPage.statistics}),
      );
      expect(_k('main-nav-line-3'), findsNothing);
    });

    testWidgets('悬停 0.3 秒出提示，带快捷键', (tester) async {
      await pumpNav(tester, data: NavFixture.view());
      await hoverOver(tester, _k('main-nav-onlineGallery'));
      final tip = find.byType(NavSimpleTip);
      expect(tip, findsOneWidget);
      expect(
        find.descendant(of: tip, matching: find.text('在线画廊')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tip, matching: find.text('4')),
        findsOneWidget,
      );
    });

    testWidgets('关掉“提示中显示快捷键”后提示只写页面名', (tester) async {
      await pumpNav(
        tester,
        data: const NavViewData(
          current: NavPage.localGallery,
          shortcuts: NavFixture.shortcuts,
          showShortcutsInTips: false,
        ),
      );
      await hoverOver(tester, _k('main-nav-onlineGallery'));
      expect(
        find.descendant(
          of: find.byType(NavSimpleTip),
          matching: find.text('Ctrl'),
        ),
        findsNothing,
      );
    });

    testWidgets('生图状态：进度圈 + 第几张；悬停是富提示', (tester) async {
      await pumpNav(
        tester,
        data: NavFixture.view(generation: NavFixture.running),
      );
      expect(find.text('2/4'), findsOneWidget);
      await hoverOver(tester, _k('main-nav-generation'));
      expect(find.byType(NavGenerationTip), findsOneWidget);
      expect(find.text('生成中 · 第 2 / 4 张'), findsOneWidget);
      expect(find.text('63% · 流式预览'), findsOneWidget);
    });

    testWidgets('生图失败的富提示写出原因', (tester) async {
      await pumpNav(
        tester,
        data: NavFixture.view(
          generation: const NavGeneration(
            state: NavGenerationState.failed,
            error: 'Anlas 不足\n详细堆栈',
          ),
        ),
      );
      await hoverOver(tester, _k('main-nav-generation'));
      expect(find.text('生成失败'), findsOneWidget);
      expect(find.text('Anlas 不足'), findsOneWidget);
    });

    testWidgets('订阅快到期时头像有提醒点；没有订阅数据就没有', (tester) async {
      await pumpNav(tester, data: NavFixture.view());
      expect(_k('main-nav-subscription-dot'), findsOneWidget);
      await pumpNav(
        tester,
        data: NavFixture.view(
          account: const NavAccountData(
            current: NavAccount(id: 'a', name: '鹈鹕'),
          ),
        ),
      );
      expect(_k('main-nav-subscription-dot'), findsNothing);
    });

    testWidgets('没有后台任务时不显示任务图标', (tester) async {
      await pumpNav(tester, data: NavFixture.view());
      expect(_k('main-nav-tasks'), findsNothing);
      await pumpNav(tester, data: NavFixture.view(tasks: NavFixture.tasks));
      expect(_k('main-nav-tasks'), findsOneWidget);
    });

    testWidgets('Tab 聚焦后 Enter 切页', (tester) async {
      final rec = RecordingNavActions();
      await pumpNav(tester, data: NavFixture.view(), actions: rec.actions);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // 头像
      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // 生图
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(rec.pages, [NavPage.generation]);
    });

    testWidgets('窗口很矮时中间几组可以滚动，底部按钮不被挤掉', (tester) async {
      await pumpNav(
        tester,
        data: NavFixture.view(tasks: NavFixture.tasks),
        size: const Size(900, 420),
      );
      expect(tester.takeException(), isNull);
      expect(_k('main-nav-settings').hitTestable(), findsOneWidget);
      expect(_k('main-nav-statistics').hitTestable(), findsNothing);
      await tester.drag(_k('main-nav-primary-scroll'), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(_k('main-nav-statistics').hitTestable(), findsOneWidget);
    });
  });

  group('按住 Ctrl', () {
    testWidgets('按住 0.4 秒出编号和第一次的说明，松开消失并记为看过', (tester) async {
      final rec = RecordingNavActions();
      await pumpNav(
        tester,
        data: NavFixture.view(ctrlHintSeen: false),
        actions: rec.actions,
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('1'), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('1'), findsOneWidget);
      expect(find.text(','), findsOneWidget);
      expect(_k('main-nav-ctrl-hint'), findsOneWidget);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(find.text('1'), findsNothing);
      expect(rec.hintSeen, 1);
    });

    testWidgets('Ctrl+C 这类组合键按得快不出编号；关掉开关后也不出', (tester) async {
      await pumpNav(tester, data: NavFixture.view());
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('1'), findsNothing);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      await pumpNav(
        tester,
        data: const NavViewData(
          current: NavPage.localGallery,
          shortcuts: NavFixture.shortcuts,
          ctrlNumbers: false,
        ),
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('1'), findsNothing);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    });
  });

  group('展开', () {
    testWidgets('展开是浮层：页面不动；Esc、点外面、选了页面都收起', (tester) async {
      final rec = RecordingNavActions();
      await pumpNav(tester, data: NavFixture.view(), actions: rec.actions);
      final contentLeft = tester.getTopLeft(_k('nav-content')).dx;

      await tester.tap(_k('main-nav-toggle'));
      await tester.pumpAndSettle();
      expect(_k('main-nav-panel'), findsOneWidget);
      expect(tester.getTopLeft(_k('nav-content')).dx, contentLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_k('main-nav-panel'), findsNothing);

      await tester.tap(_k('main-nav-toggle'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(1000, 500));
      await tester.pumpAndSettle();
      expect(_k('main-nav-panel'), findsNothing);

      await tester.tap(_k('main-nav-toggle'));
      await tester.pumpAndSettle();
      await tester.tap(_k('main-nav-panel-vibeLibrary'));
      await tester.pumpAndSettle();
      expect(rec.pages, [NavPage.vibeLibrary]);
      expect(_k('main-nav-panel'), findsNothing);
    });

    testWidgets('浮层里打开“钉住”回调 true', (tester) async {
      final rec = RecordingNavActions();
      await pumpNav(tester, data: NavFixture.view(), actions: rec.actions);
      await tester.tap(_k('main-nav-toggle'));
      await tester.pumpAndSettle();
      await tester.tap(_k('main-nav-panel-pin'));
      await tester.pumpAndSettle();
      expect(rec.pinned, [true]);
    });

    testWidgets('钉住时常驻并推开页面，“收起”取消钉住', (tester) async {
      final rec = RecordingNavActions();
      await pumpNav(
        tester,
        data: NavFixture.view(pinned: true),
        actions: rec.actions,
      );
      expect(_k('main-nav-rail'), findsNothing);
      expect(tester.getTopLeft(_k('nav-content')).dx, 236);
      await tester.tap(_k('main-nav-panel-collapse'));
      expect(rec.pinned, [false]);
    });
  });

  group('弹层', () {
    testWidgets('账号弹窗：Anlas、切换、添加、管理、退出；命令在弹窗关掉之后回调', (tester) async {
      final rec = RecordingNavActions();
      await pumpNav(tester, data: NavFixture.view(), actions: rec.actions);
      await tester.tap(_k('main-nav-avatar'));
      await tester.pumpAndSettle();
      expect(_k('account-popover'), findsOneWidget);
      expect(find.text('9,866'), findsOneWidget);
      expect(find.text('订阅 2026-10-12 到期 · 还剩 5 天'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('account-popover-switch-alt')),
      );
      expect(rec.switched, isEmpty, reason: '要等弹窗关掉这一帧结束');
      await tester.pumpAndSettle();
      expect(rec.switched, ['alt']);
      expect(_k('account-popover'), findsNothing);

      for (final (key, count) in [
        ('account-popover-add', () => rec.added),
        ('account-popover-manage', () => rec.managed),
        ('account-popover-logout', () => rec.loggedOut),
      ]) {
        await tester.tap(_k('main-nav-avatar'));
        await tester.pumpAndSettle();
        await tester.tap(_k(key));
        await tester.pumpAndSettle();
        expect(count(), 1, reason: key);
      }
    });

    testWidgets('登录中切换 / 添加 / 退出不可点，管理账号可点', (tester) async {
      final rec = RecordingNavActions();
      final a = NavFixture.account;
      await pumpNav(
        tester,
        data: NavFixture.view(
          account: NavAccountData(
            current: a.current,
            others: a.others,
            anlas: a.anlas,
            busy: true,
          ),
        ),
        actions: rec.actions,
      );
      await tester.tap(_k('main-nav-avatar'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('account-popover-switch-alt')),
      );
      await tester.tap(_k('account-popover-add'));
      await tester.tap(_k('account-popover-logout'));
      await tester.pumpAndSettle();
      expect(rec.switched, isEmpty);
      expect(rec.added + rec.loggedOut, 0);
      await tester.tap(_k('account-popover-manage'));
      await tester.pumpAndSettle();
      expect(rec.managed, 1);
    });

    testWidgets('Esc 关弹窗', (tester) async {
      await pumpNav(tester, data: NavFixture.view());
      await tester.tap(_k('main-nav-avatar'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_k('account-popover'), findsNothing);
    });

    testWidgets('后台任务：生图列第一行，查看 / 取消 / 撤销', (tester) async {
      final rec = RecordingNavActions();
      await pumpNav(
        tester,
        data: NavFixture.view(
          generation: NavFixture.running,
          tasks: NavFixture.tasks,
        ),
        actions: rec.actions,
      );
      await tester.tap(_k('main-nav-tasks'));
      await tester.pumpAndSettle();
      expect(find.text('3 个进行中'), findsOneWidget);
      expect(find.text('放大中 · 42%'), findsOneWidget);
      expect(find.text('120 / 300'), findsOneWidget);
      expect(find.text('移到回收站 12 张'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('main-nav-task-cancel-upscale')),
      );
      await tester.tap(find.byKey(const ValueKey('main-nav-task-undo-trash')));
      expect(rec.cancelled, ['upscale']);
      expect(rec.undone, ['trash']);
      await tester.tap(_k('main-nav-task-view'));
      await tester.pumpAndSettle();
      expect(rec.pages, [NavPage.generation]);
      expect(_k('main-nav-tasks-popover'), findsNothing);
    });

    testWidgets('右键 → 自定义导航栏：勾选立即生效，生图锁定，恢复默认', (tester) async {
      final rec = RecordingNavActions();
      await pumpNav(
        tester,
        data: NavFixture.view(hidden: {NavPage.tagWiki}),
        actions: rec.actions,
      );
      await tester.tapAt(const Offset(24, 300), buttons: kSecondaryButton);
      await tester.pumpAndSettle();
      await tester.tap(_k('main-nav-customize-menu'));
      await tester.pumpAndSettle();
      expect(_k('main-nav-customize'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('main-nav-customize-statistics')),
      );
      await tester.tap(
        find.byKey(const ValueKey('main-nav-customize-tagWiki')),
      );
      await tester.tap(
        find.byKey(const ValueKey('main-nav-customize-generation')),
      );
      await tester.tap(_k('main-nav-customize-ctrl'));
      expect(rec.hidden, [
        {NavPage.tagWiki, NavPage.statistics},
        <NavPage>{},
      ]);
      expect(rec.ctrlNumbers, [false]);

      await tester.tap(_k('main-nav-customize-reset'));
      expect(rec.hidden.last, isEmpty);
      expect(rec.ctrlNumbers.last, isTrue);
      await tester.tap(_k('main-nav-customize-done'));
      await tester.pumpAndSettle();
      expect(_k('main-nav-customize'), findsNothing);
    });
  });
}
