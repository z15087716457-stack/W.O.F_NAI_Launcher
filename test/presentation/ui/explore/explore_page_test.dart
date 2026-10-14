// 画风探索交互：按契约回调断言（界面只发回调，不改数据），焦点 / 多选 / 页签 / 弹窗这些界面自己的状态直接看界面。
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_contract.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'explore_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  late RecordingExploreActions rec;
  setUp(() => rec = RecordingExploreActions());

  Future<void> pump(
    WidgetTester t, {
    ExploreViewData? data,
    double window = 1600,
    double height = 1000,
  }) => pumpExplore(
    t,
    data: data ?? ExploreFixture.view(),
    actions: rec.actions,
    window: window,
    height: height,
  );

  Future<void> key(WidgetTester t, LogicalKeyboardKey k) async {
    await t.sendKeyEvent(k);
    await t.pumpAndSettle();
  }

  Future<void> ctrlKey(WidgetTester t, LogicalKeyboardKey k) async {
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(k);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pumpAndSettle();
  }

  // 双击判定用真实时钟（同块库），这里真等 0.35 秒。
  Future<void> wait300(WidgetTester t) =>
      t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 350)));

  Finder text(String s) => find.text(s, findRichText: true);

  group('候选墙', () {
    testWidgets('默认看最新一轮的第一张：检查器写 #27', (t) async {
      await pump(t);
      expect(find.byKey(const Key('explore-round-r3')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('explore-inspector')),
          matching: find.text('#27'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('单击看检查器，0.3 秒内再点开大图；Esc 关大图', (t) async {
      await pump(t);
      await t.tap(find.byKey(const Key('explore-card-c29')));
      await t.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('explore-inspector')),
          matching: find.text('#29'),
        ),
        findsOneWidget,
      );
      await t.tap(find.byKey(const Key('explore-card-c29')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('explore-detail')), findsOneWidget);
      await key(t, LogicalKeyboardKey.escape);
      expect(find.byKey(const Key('explore-detail')), findsNothing);
    });

    testWidgets('两次单击隔得久不算双击', (t) async {
      await pump(t);
      await t.tap(find.byKey(const Key('explore-card-c29')));
      await t.pumpAndSettle();
      await wait300(t);
      await t.tap(find.byKey(const Key('explore-card-c29')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('explore-detail')), findsNothing);
    });

    testWidgets('方向键移动焦点，F 收藏、E 开始进化、Del 删除', (t) async {
      await pump(t);
      await key(t, LogicalKeyboardKey.arrowRight);
      expect(
        find.descendant(
          of: find.byKey(const Key('explore-inspector')),
          matching: find.text('#28'),
        ),
        findsOneWidget,
      );
      await key(t, LogicalKeyboardKey.keyF);
      expect(rec.calls.last, 'favorite:c28:true');
      await key(t, LogicalKeyboardKey.delete);
      expect(rec.calls.last, 'delete:c28');
      await key(t, LogicalKeyboardKey.keyE);
      expect(find.byKey(const Key('explore-evolution-dialog')), findsOneWidget);
    });

    testWidgets('数字键归组，0 移出，再按一次同组移出', (t) async {
      await pump(t);
      // #27 在“冷色调”（g1）。
      await key(t, LogicalKeyboardKey.digit2);
      expect(rec.calls.last, 'group:c27:g2');
      await key(t, LogicalKeyboardKey.digit1);
      expect(rec.calls.last, 'group:c27:null');
      await key(t, LogicalKeyboardKey.digit0);
      expect(rec.calls.last, 'group:c27:null');
      await ctrlKey(t, LogicalKeyboardKey.keyC);
      expect(rec.calls.last, 'copy:c27');
    });

    testWidgets('悬停操作条：收藏 / 存为块 / 看大图', (t) async {
      await pump(t);
      await hoverOver(t, find.byKey(const Key('explore-card-c28')));
      await tapKey(t, 'explore-hover-fav-c28');
      expect(rec.calls.last, 'favorite:c28:true');
      await tapKey(t, 'explore-hover-block-c28');
      expect(find.byKey(const Key('explore-block-dialog')), findsOneWidget);
    });

    testWidgets('右键菜单归到新分组：原地输入回车创建', (t) async {
      await pump(t);
      await t.tap(
        find.byKey(const Key('explore-card-c28')),
        buttons: kSecondaryButton,
      );
      await t.pumpAndSettle();
      await tapKey(t, 'explore-menu-new-group');
      await t.enterText(find.byKey(const Key('explore-group-input')), '冷暖对比');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(rec.calls.last, 'newGroup:冷暖对比:c28');
    });

    testWidgets('筛选“收藏”只剩收藏的，空筛选可以一键回到全部', (t) async {
      await pump(t);
      await tapKey(t, 'explore-filter-favorites');
      expect(find.byKey(const Key('explore-card-c28')), findsNothing);
      expect(find.byKey(const Key('explore-card-c27')), findsOneWidget);
      await tapKey(t, 'explore-filter-g2');
      await t.scrollUntilVisible(
        find.byKey(const Key('explore-card-c23')),
        300,
        scrollable: find.descendant(
          of: find.byKey(const Key('explore-wall')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.byKey(const Key('explore-card-c27')), findsNothing);
    });

    testWidgets('排序切成旧的在上：第 1 轮排最前', (t) async {
      await pump(t);
      final before = t.getTopLeft(find.byKey(const Key('explore-round-r3'))).dy;
      await tapKey(t, 'explore-sort');
      expect(find.byKey(const Key('explore-round-r1')), findsOneWidget);
      expect(find.byKey(const Key('explore-round-r3')), findsNothing);
      expect(
        t.getTopLeft(find.byKey(const Key('explore-round-r1'))).dy,
        before,
      );
    });

    testWidgets('失败的轮标题有“重试”', (t) async {
      await pump(t, data: ExploreFixture.view(failed: true));
      await tapKey(t, 'explore-retry-r3');
      expect(rec.calls.last, 'retry');
    });
  });

  group('多选', () {
    testWidgets('多选：点卡片勾选、Shift 连选、Ctrl+A 全选、浮条批量', (t) async {
      await pump(t);
      await tapKey(t, 'explore-select');
      await tapKey(t, 'explore-card-c27');
      await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tapKey(t, 'explore-card-c30');
      await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(text('已选 4 张'), findsWidgets);
      await tapKey(t, 'explore-sel-fav');
      expect(rec.calls.last, 'favorite:c27,c28,c29,c30:true');
      await ctrlKey(t, LogicalKeyboardKey.keyA);
      expect(text('已选 38 张'), findsWidgets);
      await tapKey(t, 'explore-sel-close');
      expect(find.byKey(const Key('explore-selection-bar')), findsNothing);
    });

    testWidgets('Ctrl 单击直接进多选；Esc 退出', (t) async {
      await pump(t);
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tapKey(t, 'explore-card-c29');
      await tapKey(t, 'explore-card-c33');
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(find.byKey(const Key('explore-selection-bar')), findsOneWidget);
      expect(find.byKey(const Key('explore-inspector-multi')), findsOneWidget);
      await key(t, LogicalKeyboardKey.escape);
      expect(find.byKey(const Key('explore-selection-bar')), findsNothing);
    });

    testWidgets('“挑几张去进化”勾上本轮收藏的', (t) async {
      await pump(t);
      await tapKey(t, 'explore-pick-r3');
      // 第 3 轮收藏的：#27 #29 #31 #34。
      expect(text('已选 4 张'), findsWidgets);
    });

    testWidgets('删除 → 撤销提示 → 撤销', (t) async {
      await pump(
        t,
        data: ExploreFixture.view(undo: const ExploreUndo(id: 'u', count: 2)),
      );
      expect(text('已删除 2 张'), findsOneWidget);
      await tapKey(t, 'explore-undo-button');
      expect(rec.calls.last, 'undo');
    });
  });

  group('检查器', () {
    testWidgets('检查器：分组胶囊、复制画师串、完整提示词、删除', (t) async {
      await pump(t);
      await tapKey(t, 'explore-insp-group-g2');
      expect(rec.calls.last, 'group:c27:g2');
      await tapKey(t, 'explore-copy-artists');
      expect(rec.calls.last, 'copy:c27');
      await tapKey(t, 'explore-inspector-prompt-toggle');
      expect(find.byKey(const Key('explore-inspector-prompt')), findsOneWidget);
      await tapKey(t, 'explore-act-apply');
      expect(rec.calls.last, 'apply:c27');
      await tapKey(t, 'explore-inspector-delete');
      expect(rec.calls.last, 'delete:c27');
    });

    testWidgets('检查器左右切换，点图开大图', (t) async {
      await pump(t);
      await tapKey(t, 'explore-inspector-next');
      expect(
        find.descendant(
          of: find.byKey(const Key('explore-inspector')),
          matching: find.text('#28'),
        ),
        findsOneWidget,
      );
      await tapKey(t, 'explore-inspector-open');
      expect(find.byKey(const Key('explore-detail')), findsOneWidget);
    });

    testWidgets('收起检查器回调；窄窗口变抽屉不回调', (t) async {
      await pump(t);
      await tapKey(t, 'explore-inspector-toggle');
      expect(rec.calls.last, 'inspector:false');
      rec.calls.clear();
      await pump(t, window: 1200, height: 860);
      expect(find.byKey(const Key('explore-inspector')), findsNothing);
      await tapKey(t, 'explore-inspector-toggle');
      expect(find.byKey(const Key('explore-drawer')), findsOneWidget);
      expect(rec.calls, isEmpty);
      await tapKey(t, 'explore-drawer-close');
      expect(find.byKey(const Key('explore-drawer')), findsNothing);
    });
  });

  group('进化', () {
    testWidgets('进化页签：勾子代 → 培育下一代', (t) async {
      await pump(t);
      await tapKey(t, 'explore-tab-evolution');
      expect(find.byKey(const Key('explore-evo')), findsOneWidget);
      await tapKey(t, 'explore-kid-check-k3-2');
      await tapKey(t, 'explore-kid-check-k3-5');
      await tapKey(t, 'explore-breed');
      expect(rec.calls.last, 'breed:l1:k3-2,k3-5');
    });

    testWidgets('再生成 N 张子代，张数可调', (t) async {
      await pump(t);
      await tapKey(t, 'explore-tab-evolution');
      await tapKey(t, 'explore-kids-count-up');
      await tapKey(t, 'explore-generate-children');
      expect(rec.calls.last, 'children:l1:9');
    });

    testWidgets('历史代默认折叠，点开只读', (t) async {
      await pump(t);
      await tapKey(t, 'explore-tab-evolution');
      expect(find.byKey(const Key('explore-kid-k1-1')), findsNothing);
      await tapKey(t, 'explore-gen-1');
      expect(find.byKey(const Key('explore-kid-k1-1')), findsOneWidget);
      expect(find.byKey(const Key('explore-kid-check-k1-1')), findsNothing);
    });

    testWidgets('切到另一条进化线', (t) async {
      await pump(t);
      await tapKey(t, 'explore-tab-evolution');
      await tapKey(t, 'explore-line-l2');
      expect(text('第 2 代'), findsOneWidget);
      expect(find.byKey(const Key('explore-compare')), findsOneWidget);
    });

    testWidgets('两两比较：方向键作答，全部比完显示完成', (t) async {
      await pump(t);
      await tapKey(t, 'explore-tab-evolution');
      await tapKey(t, 'explore-compare');
      expect(find.byKey(const Key('explore-compare-dialog')), findsOneWidget);
      await key(t, LogicalKeyboardKey.arrowLeft);
      expect(rec.calls.last, startsWith('compare:l1:'));
      expect(rec.calls.last, endsWith(':left'));
      await tapKey(t, 'explore-compare-right');
      expect(rec.calls.last, endsWith(':right'));
      await key(t, LogicalKeyboardKey.arrowDown);
      expect(rec.calls.last, endsWith(':neither'));
      // 5 个父本 = 10 对。
      for (var i = 0; i < 7; i++) {
        await key(t, LogicalKeyboardKey.space);
      }
      expect(find.byKey(const Key('explore-compare-done')), findsOneWidget);
      await tapKey(t, 'explore-compare-finish');
      expect(find.byKey(const Key('explore-compare-dialog')), findsNothing);
    });

    testWidgets('开始进化：去掉一个父本、加自定义串、创建并生成', (t) async {
      await pump(t);
      await tapKey(t, 'explore-select');
      for (final n in [27, 29, 30]) {
        await tapKey(t, 'explore-card-c$n');
      }
      await tapKey(t, 'explore-sel-evo');
      await t.tap(
        find
            .descendant(
              of: find.byKey(const Key('explore-evo-parent-c29')),
              matching: find.byType(GestureDetector),
            )
            .last,
      );
      await t.pumpAndSettle();
      await tapKey(t, 'explore-evo-add-custom');
      await t.enterText(
        find.descendant(
          of: find.byKey(const Key('explore-evo-custom-input')),
          matching: find.byType(EditableText),
        ),
        'artist:rella',
      );
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      await tapKey(t, 'explore-evo-create-generate');
      expect(rec.calls.last, 'evolution:c27,c30:artist:rella:进化线 3:null:8');
      expect(find.byKey(const Key('explore-evolution-dialog')), findsNothing);
    });

    testWidgets('开始进化：加入现有线的当前代', (t) async {
      await pump(t);
      await tapKey(t, 'explore-card-c28');
      await key(t, LogicalKeyboardKey.keyE);
      await tapKey(t, 'explore-seg-_EvoMode.join');
      await tapKey(t, 'explore-evo-create');
      expect(rec.calls.last, 'evolution:c28::null:l2:null');
    });

    testWidgets('没有进化线时进化页签引导去候选里挑', (t) async {
      final base = ExploreFixture.view();
      final run = base.run!;
      await pump(
        t,
        data: ExploreViewData(
          now: base.now,
          runs: base.runs,
          variables: base.variables,
          run: ExploreRunView(
            id: run.id,
            name: run.name,
            createdAt: run.createdAt,
            candidates: run.candidates,
            rounds: run.rounds,
            groups: run.groups,
          ),
        ),
      );
      await tapKey(t, 'explore-tab-evolution');
      await tapKey(t, 'explore-evo-go-pick');
      expect(find.byKey(const Key('explore-selection-bar')), findsOneWidget);
    });
  });

  group('存为块', () {
    testWidgets('多张合并去重；点 × 去掉一个画师；保存', (t) async {
      await pump(t);
      await tapKey(t, 'explore-select');
      await tapKey(t, 'explore-card-c27');
      await tapKey(t, 'explore-card-c29');
      await tapKey(t, 'explore-sel-block');
      await tapKey(t, 'explore-block-atom-rurudo');
      await tapKey(t, 'explore-block-folder');
      await tapKey(t, 'explore-block-folder-f-artist');
      await tapKey(t, 'explore-block-save');
      expect(
        rec.calls.last,
        'block:柔光画风 · 400 池 · 精选 2:'
        '0.6::artist:ciloranko::|0.6::artist:ask (askzy)::|'
        '0.8::artist:fuzichoco:::false:f-artist',
      );
    });

    testWidgets('单张可以存完整正向', (t) async {
      await pump(t);
      await tapKey(t, 'explore-act-block');
      await tapKey(t, 'explore-seg-_BlockMode.full');
      expect(find.byKey(const Key('explore-block-full')), findsOneWidget);
      await tapKey(t, 'explore-block-save');
      expect(rec.calls.last, startsWith('block:柔光画风 · 400 池 #27::true:'));
    });
  });

  group('块库侧栏', () {
    testWidgets('贴在编辑列右边、整高 300，舞台让位；窗口窄时检查器改抽屉、不溢出', (t) async {
      for (final window in [1600.0, 1250.0]) {
        await pumpExplore(
          t,
          data: ExploreFixture.view(),
          actions: rec.actions,
          window: window,
          dock: const SizedBox.expand(key: Key('dock-body')),
        );
        await t.pumpAndSettle();
        final editor = t.getRect(find.byKey(const Key('explore-editor')));
        final dock = t.getRect(find.byKey(const Key('explore-dock')));
        expect(dock.left, editor.right);
        expect(dock.top, 0);
        expect(dock.width, 300);
        expect(dock.height, editor.height);
        expect(find.byKey(const Key('dock-body')), findsOneWidget);
        expect(
          find.byKey(const Key('explore-inspector')),
          window == 1600 ? findsOneWidget : findsNothing,
        );
        expect(t.takeException(), isNull);
      }
    });
  });

  group('顶栏与生成', () {
    testWidgets('切换探索：搜索、打开另一个、新建', (t) async {
      await pump(t);
      await tapKey(t, 'explore-run-button');
      expect(find.byKey(const Key('explore-run-menu')), findsOneWidget);
      await t.enterText(
        find.descendant(
          of: find.byKey(const Key('explore-run-search')),
          matching: find.byType(EditableText),
        ),
        '冷色',
      );
      await t.pump(const Duration(milliseconds: 350));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('explore-run-run3')), findsNothing);
      await tapKey(t, 'explore-run-run2');
      expect(rec.calls.last, 'openRun:run2');
      await tapKey(t, 'explore-run-button');
      await tapKey(t, 'explore-new-run');
      expect(rec.calls.last, 'newRun');
    });

    testWidgets('右键标题改名；切换列表里删除要确认', (t) async {
      await pump(t);
      await t.tap(
        find.byKey(const Key('explore-run-button')),
        buttons: kSecondaryButton,
      );
      await t.pumpAndSettle();
      await tapKey(t, 'explore-run-menu-rename-item');
      await t.enterText(find.byKey(const Key('explore-run-rename')), '柔光 v2');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(rec.calls.last, 'renameRun:run1:柔光 v2');

      await tapKey(t, 'explore-run-button');
      await hoverOver(t, find.byKey(const Key('explore-run-run3')));
      await tapKey(t, 'explore-run-more-run3');
      await tapKey(t, 'explore-run-delete-run3');
      expect(find.byKey(const Key('explore-delete-run')), findsOneWidget);
      await tapKey(t, 'explore-confirm-delete');
      expect(rec.calls.last, 'deleteRun:run3');
    });

    testWidgets('生成条：张数、抽、停止；进度条暂停只给子代批次', (t) async {
      await pump(t);
      await tapKey(t, 'explore-generate');
      expect(rec.calls.last, 'generate');
      await pump(t, data: ExploreFixture.view(running: true));
      expect(text('停止生成'), findsOneWidget);
      await tapKey(t, 'explore-generate');
      expect(rec.calls.last, 'stop');
      expect(find.byKey(const Key('explore-pause')), findsNothing);
      await tapKey(t, 'explore-stop');
      expect(rec.calls.last, 'stop');
    });

    testWidgets('卡片大小切换', (t) async {
      await pump(t);
      await tapKey(t, 'explore-size-small');
      expect(rec.calls.last, 'size:small');
    });

    testWidgets('随机变量一行点开实例卡', (t) async {
      await pump(t);
      await tapKey(t, 'explore-variable-1');
      expect(rec.calls.last, 'variable:1');
    });
  });

  group('首次使用', () {
    testWidgets('首次使用：三步说明，抽第一批', (t) async {
      await pump(t, data: ExploreFixture.empty());
      expect(find.byKey(const Key('explore-onboarding')), findsOneWidget);
      await tapKey(t, 'explore-onboarding-draw');
      expect(rec.calls.last, 'generate');
    });

    testWidgets('没有随机块：按钮灰掉，引导打开块库', (t) async {
      await pump(t, data: ExploreFixture.empty(vars: const []));
      await tapKey(t, 'explore-onboarding-library');
      expect(rec.calls.last, 'library');
    });
  });

  group('大图', () {
    testWidgets('大图里 F 收藏、数字键归组、左右翻页', (t) async {
      await pump(t);
      await key(t, LogicalKeyboardKey.enter);
      expect(find.byKey(const Key('explore-detail')), findsOneWidget);
      await key(t, LogicalKeyboardKey.keyF);
      expect(rec.calls.last, 'favorite:c27:false');
      await key(t, LogicalKeyboardKey.digit2);
      expect(rec.calls.last, 'group:c27:g2');
      await key(t, LogicalKeyboardKey.arrowRight);
      expect(
        find.descendant(
          of: find.byKey(const Key('explore-detail-info')),
          matching: find.text('#28'),
        ),
        findsOneWidget,
      );
      await tapKey(t, 'explore-detail-delete');
      expect(rec.calls.last, 'delete:c28');
    });
  });
}
