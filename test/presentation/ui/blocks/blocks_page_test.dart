// 块系统交互测试：每个按钮 / 快捷键 / 拖放都回调到契约，接线方照着这些回调接 provider。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_dock.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_fixture.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_instance.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_page.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_quick.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_block_pill.dart';

import 'blocks_test_harness.dart';

void main() {
  late RecordingBlocks rec;
  setUp(() => rec = RecordingBlocks());

  BlocksLibraryViewData view({
    bool empty = false,
    BlocksView v = BlocksView.grid,
    BlocksScope scope = const BlocksScope.all(),
  }) => BlocksFixture.library(
    image: blocksTestImage,
    empty: empty,
    view: v,
    scope: scope,
  );

  Future<void> lib(
    WidgetTester t, {
    BlocksLibraryViewData? data,
    double window = 1600,
  }) => pumpBlocks(
    t,
    BlocksLibraryPage(data: data ?? view(), actions: rec.library),
    window: window,
  );

  Future<void> key(
    WidgetTester t,
    LogicalKeyboardKey k, {
    bool ctrl = false,
  }) async {
    if (ctrl) await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(k);
    if (ctrl) await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pumpAndSettle();
  }

  group('块库管理页', () {
    testWidgets('左栏范围、收起左栏、导入导出菜单', (t) async {
      await lib(t);
      await tapKey(t, 'blocks-scope-favorites');
      await tapKey(t, 'blocks-scope-uncategorized');
      await tapKey(t, 'blocks-collection-k-artists');
      await tapKey(t, 'blocks-folder-f-style');
      await tapKey(t, 'blocks-folder-toggle-f-style');
      await t.tap(find.byKey(const Key('blocks-tag-质量')));
      await t.pumpAndSettle();
      await tapKey(t, 'blocks-collapse-nav');
      await tapKey(t, 'blocks-io');
      await t.tap(find.text('导入 TXT…'));
      await t.pumpAndSettle();
      expect(rec.calls, [
        'scope:favorites:null',
        'scope:uncategorized:null',
        'scope:collection:k-artists',
        'scope:folder:f-style',
        'toggleFolder:f-style:true',
        'scope:tag:质量',
        'sidebar:false',
        'importTxt',
      ]);
    });

    testWidgets('新建文件夹 / 收藏集：内联输入回车提交，空名不提交', (t) async {
      await lib(t);
      await tapKey(t, 'blocks-new-folder');
      await t.enterText(find.byKey(const Key('blocks-nav-input')), '新的');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      await tapKey(t, 'blocks-new-collection');
      await t.enterText(find.byKey(const Key('blocks-nav-input')), '');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(rec.calls, ['createFolder:新的:null']);
      expect(find.byKey(const Key('blocks-nav-input')), findsNothing);
    });

    testWidgets('文件夹右键：新建子文件夹 / 重命名 / 上移 / 删除', (t) async {
      await lib(t);
      Future<void> menu(String label) async {
        await t.tapAt(
          t.getCenter(find.byKey(const Key('blocks-folder-f-style'))),
          buttons: 2,
        );
        await t.pumpAndSettle();
        await t.tap(find.text(label));
        await t.pumpAndSettle();
      }

      await menu('重命名');
      await t.enterText(find.byKey(const Key('blocks-nav-input')), '画风 2');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      await menu('上移');
      await menu('删除文件夹…');
      expect(rec.calls, [
        'renameFolder:f-style:画风 2',
        'reorderFolder:f-style:-1',
        'deleteFolder:f-style',
      ]);
    });

    testWidgets('工具栏：搜索停 300ms 回调、排序、视图、详情开关、快速筛选、卡片大小', (t) async {
      await lib(t);
      await t.enterText(
        find.descendant(
          of: find.byKey(const Key('blocks-search')),
          matching: find.byType(EditableText),
        ),
        '画师',
      );
      await t.pump(const Duration(milliseconds: 400));
      await tapKey(t, 'blocks-sort');
      await tapKey(t, 'blocks-sort-title');
      await t.tap(
        find.descendant(
          of: find.byKey(const Key('blocks-view')),
          matching: find.byTooltip('列表'),
        ),
      );
      await t.pumpAndSettle();
      await tapKey(t, 'blocks-inspector-toggle');
      await tapKey(t, 'blocks-quick-image');
      await tapKey(t, 'blocks-quick-negative');
      final slider = find.byKey(const Key('blocks-card-size'));
      await t.tapAt(
        t.getTopLeft(slider) +
            Offset(t.getSize(slider).width - 2, t.getSize(slider).height / 2),
      );
      await t.pumpAndSettle();
      expect(rec.calls.take(6), [
        'query:画师',
        'sort:title:true',
        'view:list',
        'inspector:false',
        'quick:image',
        'quick:negative',
      ]);
      expect(rec.calls.last, startsWith('size:'));
    });

    testWidgets('瀑布流与按文件夹分组：吸顶文件夹条、开关回调', (t) async {
      final base = BlocksFixture.library(
        image: blocksTestImage,
        view: BlocksView.masonry,
      );
      await lib(t, data: base);
      expect(find.byKey(const Key('blocks-folder-bar-null')), findsNothing);
      expect(find.byKey(const Key('blocks-card-y99')), findsOneWidget);
      await tapKey(t, 'blocks-group-folders');
      expect(rec.calls.last, 'group:true');

      final blocks = base.blocks.take(6).toList();
      final grouped = BlocksLibraryViewData(
        now: base.now,
        blocks: blocks,
        counts: base.counts,
        folders: base.folders,
        view: BlocksView.masonry,
        groupByFolder: true,
        groups: const [
          BlocksGroup(folderId: null, path: '', start: 0, count: 3),
          BlocksGroup(folderId: 'f-char', path: '角色', start: 3, count: 3),
        ],
        catalog: base.catalog,
      );
      await lib(t, data: grouped);
      expect(find.byKey(const Key('blocks-folder-bar-null')), findsOneWidget);
      expect(find.text('未分类'), findsWidgets);
      expect(find.byKey(const Key('blocks-folder-bar-f-char')), findsOneWidget);
      await tapKey(t, 'blocks-group-folders');
      expect(rec.calls.last, 'group:false');

      // 窄屏：独立开关收进排序菜单。
      await lib(t, data: base, window: 1000);
      expect(find.byKey(const Key('blocks-group-folders')), findsNothing);
      await tapKey(t, 'blocks-sort');
      await tapKey(t, 'blocks-sort-group');
      expect(rec.calls.last, 'group:true');
    });

    testWidgets('卡片：单击选中、悬停操作条、右键菜单、双击编辑', (t) async {
      await lib(t);
      await tapKey(t, 'blocks-card-pk');
      await hoverOver(t, find.byKey(const Key('blocks-card-fj')));
      await tapKey(t, 'blocks-insert-fj');
      await t.tapAt(
        t.getCenter(find.byKey(const Key('blocks-card-cy'))),
        buttons: 2,
      );
      await t.pumpAndSettle();
      await t.tap(find.text('复制一份'));
      await t.pumpAndSettle();
      expect(rec.calls, [
        'select:pk',
        'insert:fj',
        'select:cy',
        'duplicate:cy',
      ]);

      final card = find.byKey(const Key('blocks-card-aq'));
      await t.tap(card);
      await t.pump(const Duration(milliseconds: 50));
      await t.tap(card);
      await t.pumpAndSettle();
      expect(find.byKey(const Key('block-edit')), findsOneWidget);
    });

    testWidgets('键盘：方向键选下一张、Enter 插入、F 收藏、Ctrl+D 复制、E 编辑、Delete 删除确认', (
      t,
    ) async {
      await lib(t);
      await key(t, LogicalKeyboardKey.arrowRight);
      expect(rec.calls.last, 'select:pk');
      await key(t, LogicalKeyboardKey.enter);
      await key(t, LogicalKeyboardKey.keyF);
      await key(t, LogicalKeyboardKey.keyD, ctrl: true);
      expect(rec.calls.skip(1), [
        'insert:y99',
        'favorite:y99:true',
        'duplicate:y99',
      ]);
      await key(t, LogicalKeyboardKey.delete);
      expect(find.byKey(const Key('blocks-delete')), findsOneWidget);
      await tapKey(t, 'blocks-delete-confirm');
      expect(rec.calls.last, 'delete:y99');
      await key(t, LogicalKeyboardKey.keyE);
      expect(find.byKey(const Key('block-edit')), findsOneWidget);
    });

    testWidgets('Ctrl+N 新建、/ 聚焦搜索', (t) async {
      await lib(t);
      await key(t, LogicalKeyboardKey.slash);
      expect(
        FocusManager.instance.primaryFocus?.context
                    ?.findAncestorWidgetOfExactType<EditableText>() !=
                null ||
            FocusManager.instance.primaryFocus?.context?.widget is EditableText,
        isTrue,
      );
      await key(t, LogicalKeyboardKey.escape);
      await key(t, LogicalKeyboardKey.escape);
      await t.tap(find.byKey(const Key('blocks-card-pk')));
      await t.pumpAndSettle();
      await key(t, LogicalKeyboardKey.keyN, ctrl: true);
      expect(find.text('新建块'), findsWidgets);
      expect(find.byKey(const Key('block-edit')), findsOneWidget);
    });

    testWidgets('多选：勾选 → 浮条收藏 / 放进积木 / 移到… / 删除；Ctrl+A 全选；Esc 退出', (t) async {
      await lib(t);
      await tapKey(t, 'blocks-multi');
      await tapKey(t, 'blocks-card-pk');
      await tapKey(t, 'blocks-card-bl');
      expect(find.byKey(const Key('blocks-selection-bar')), findsOneWidget);
      expect(find.text('已选 2 个块'), findsOneWidget);
      await tapKey(t, 'blocks-sel-favorite');
      await tapKey(t, 'blocks-sel-palette');
      await tapKey(t, 'blocks-sel-move');
      await t.tap(find.text('角色').last);
      await t.pumpAndSettle();
      await tapKey(t, 'blocks-sel-delete');
      await tapKey(t, 'blocks-delete-confirm');
      expect(rec.calls, [
        'favorite:pk,bl:false',
        'palette:pk,bl',
        'dropFolder:pk,bl:f-char:move',
        'delete:pk,bl',
      ]);
      await tapKey(t, 'blocks-multi');
      await key(t, LogicalKeyboardKey.keyA, ctrl: true);
      expect(find.textContaining('已选 22 个'), findsWidgets);
      await key(t, LogicalKeyboardKey.escape);
      expect(find.byKey(const Key('blocks-selection-bar')), findsNothing);
    });

    testWidgets('多选详情：依次插入、合并成新块（内容按顺序拼接）、统一外观', (t) async {
      await lib(t);
      await tapKey(t, 'blocks-multi');
      await tapKey(t, 'blocks-card-aq');
      await tapKey(t, 'blocks-card-sy');
      await tapKey(t, 'blocks-multi-insert');
      await tapKey(t, 'blocks-multi-style');
      await tapKey(t, 'blocks-batch-look-solid');
      expect(rec.calls, ['insert:aq,sy', 'batchStyle:2:solid:false']);
      await tapKey(t, 'blocks-multi-merge');
      await tapKey(t, 'block-edit-save');
      final d = rec.drafts.single;
      final aq = BlocksFixture.byId('aq');
      final sy = BlocksFixture.byId('sy');
      expect(d.atoms, [...aq.atoms, ...sy.atoms]);
      expect(d.negativeAtoms, [...aq.negativeAtoms, ...sy.negativeAtoms]);
    });

    testWidgets('详情栏：插入 / 收藏 / 复制内容 / 改名 / 改颜色 / 改外观 / 移文件夹 / 去标签 / 应用参数', (
      t,
    ) async {
      await lib(t);
      await tapKey(t, 'blocks-insp-insert');
      await tapKey(t, 'blocks-insp-favorite');
      await tapKey(t, 'blocks-insp-copy');
      await tapKey(t, 'blocks-insp-apply');
      await tapKey(t, 'blocks-insp-rename');
      await t.enterText(find.byKey(const Key('blocks-insp-name')), '1999 改');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      await tapKey(t, 'block-color-2');
      await tapKey(t, 'blocks-insp-look');
      await tapKey(t, 'blocks-look-dots');
      await tapKey(t, 'blocks-insp-folder');
      await t.tap(find.text('未分类').last);
      await t.pumpAndSettle();
      expect(rec.calls, [
        'insert:y99',
        'favorite:y99:true',
        'copyText:y99',
        'applyParams:y99',
        'dropFolder:y99:null:move',
      ]);
      expect(
        rec.patches.map(
          (p) =>
              p.$2.title ??
              p.$2.look?.name ??
              (p.$2.color == null ? '' : 'color'),
        ),
        ['1999 改', 'color', 'dots'],
      );
    });

    testWidgets('把卡片拖到文件夹：松手选移动或复制；拖到收藏集：加入', (t) async {
      await lib(t);
      Future<void> drag(String card, String target) async {
        final g = await t.startGesture(t.getCenter(find.byKey(Key(card))));
        await t.pump(const Duration(milliseconds: 50));
        await g.moveBy(const Offset(-20, 0));
        await t.pump();
        await g.moveTo(t.getCenter(find.byKey(Key(target))));
        await t.pump();
        await g.up();
        await t.pumpAndSettle();
      }

      await drag('blocks-card-pk', 'blocks-folder-f-char');
      await tapKey(t, 'blocks-drop-copy');
      await drag('blocks-card-bl', 'blocks-collection-k-daily');
      await tapKey(t, 'blocks-drop-copy');
      expect(rec.calls, [
        'dropFolder:pk:f-char:copy',
        'dropCollection:bl:k-daily:copy',
      ]);
    });

    testWidgets('自定义排序：卡片拖到另一张前面 → onReorder', (t) async {
      await lib(
        t,
        data: BlocksFixture.library(
          image: blocksTestImage,
          sort: BlocksSort.custom,
        ),
      );
      final g = await t.startGesture(
        t.getCenter(find.byKey(const Key('blocks-card-pk'))),
      );
      await t.pump(const Duration(milliseconds: 50));
      await g.moveBy(const Offset(20, 0));
      await t.pump();
      await g.moveTo(t.getCenter(find.byKey(const Key('blocks-card-bl'))));
      await t.pump();
      await g.up();
      await t.pumpAndSettle();
      expect(rec.calls, ['reorder:pk:bl']);
    });

    testWidgets('空库：新建 / 导入 TXT / 整理导入；工具栏只剩新建', (t) async {
      await lib(t, data: view(empty: true));
      expect(find.byKey(const Key('blocks-empty')), findsOneWidget);
      expect(find.byKey(const Key('blocks-sort')), findsNothing);
      expect(find.byKey(const Key('blocks-multi')), findsNothing);
      await t.tap(find.text('导入 TXT…'));
      await t.tap(find.text('整理导入…'));
      await t.pumpAndSettle();
      expect(rec.calls, ['importTxt', 'importCuration']);
    });

    testWidgets('窄窗口：先收详情再收左栏，展开按钮回调', (t) async {
      await lib(t, window: 1100);
      expect(find.byKey(const Key('blocks-inspector')), findsNothing);
      expect(find.byKey(const Key('blocks-nav')), findsOneWidget);
      await lib(t, window: 760);
      expect(find.byKey(const Key('blocks-nav')), findsNothing);
      await tapKey(t, 'blocks-expand-nav');
      expect(rec.calls, ['sidebar:true']);
    });

    testWidgets('列表视图：单击选中、Ctrl 单击进多选', (t) async {
      await lib(t, data: view(v: BlocksView.list));
      await tapKey(t, 'blocks-row-pk');
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tapKey(t, 'blocks-row-bl');
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(rec.calls, ['select:pk']);
      expect(find.byKey(const Key('blocks-selection-bar')), findsOneWidget);
    });
  });

  group('编辑块', () {
    Future<void> open(WidgetTester t) async {
      await lib(t);
      await tapKey(t, 'blocks-insp-edit');
    }

    testWidgets('加一项（回车 / 逗号）、删一项、负面页、改名、保存 → onSave 带完整草稿', (t) async {
      await open(t);
      final y99 = BlocksFixture.byId('y99', blocksTestImage);
      await t.enterText(find.byKey(const Key('block-atom-input')), 'new tag');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('block-atom-input')), 'a, b,');
      await t.pumpAndSettle();
      await hoverOver(t, find.byKey(const Key('block-atom-0')));
      await tapKey(t, 'block-atom-remove-0');
      await tapKey(t, 'block-edit-tab-negative');
      await t.enterText(find.byKey(const Key('block-atom-input')), 'lowres');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('block-edit-title')), '1999 v2');
      await tapKey(t, 'block-icon-star');
      await tapKey(t, 'block-edit-look-stripes');
      await tapKey(t, 'block-edit-save');
      expect(rec.calls, ['save:y99']);
      final d = rec.drafts.single;
      expect(d.title, '1999 v2');
      expect(d.atoms, [...y99.atoms.skip(1), 'new tag', 'a', 'b']);
      expect(d.negativeAtoms, [...y99.negativeAtoms, 'lowres']);
      expect(d.icon, 'star');
      expect(d.look, BlockAppearance.stripes);
    });

    testWidgets('Ctrl+Enter 保存、取消不回调、删除要二次确认', (t) async {
      await open(t);
      await tapKey(t, 'block-edit-delete');
      expect(find.byKey(const Key('block-edit-delete-yes')), findsOneWidget);
      await tapKey(t, 'block-edit-delete-no');
      await tapKey(t, 'block-edit-cancel');
      expect(find.byKey(const Key('block-edit')), findsNothing);
      expect(rec.calls, isEmpty);
      await tapKey(t, 'blocks-insp-edit');
      await t.tap(find.byKey(const Key('block-edit-title')));
      await key(t, LogicalKeyboardKey.enter, ctrl: true);
      expect(rec.calls, ['save:y99']);
      await tapKey(t, 'blocks-insp-edit');
      await tapKey(t, 'block-edit-delete');
      await tapKey(t, 'block-edit-delete-yes');
      expect(rec.calls.last, 'delete:y99');
    });

    testWidgets('纯文本页原样保存；换图 / 清除预览图；参数从当前读取', (t) async {
      await open(t);
      await tapKey(t, 'block-edit-clear-thumb');
      await tapKey(t, 'block-edit-pick');
      expect(rec.calls, ['pickThumb']);
      await tapKey(t, 'block-edit-params');
      await tapKey(t, 'block-param-capture');
      expect(rec.calls.last, 'captureParams');
      await t.tap(find.text('完成'));
      await t.pumpAndSettle();
      await tapKey(t, 'block-edit-tab-text');
      await t.enterText(
        find.byKey(const Key('block-edit-text')),
        '1girl, (solo:1.2)',
      );
      await tapKey(t, 'block-edit-save');
      final d = rec.drafts.single;
      expect(d.text, '1girl, (solo:1.2)');
      expect(d.thumbToken, 'c12');
      expect(d.params, BlocksFixture.y99Params);
    });

    testWidgets('附带参数质量词与 UC 预设可编辑并随保存返回', (t) async {
      await open(t);
      await tapKey(t, 'block-edit-params');
      await tapKey(t, 'block-param-quality');
      await tapKey(t, 'block-param-quality-standard');
      await tapKey(t, 'block-param-uc');
      await tapKey(t, 'block-param-uc-1');
      await t.tap(find.text('完成'));
      await t.pumpAndSettle();
      await tapKey(t, 'block-edit-save');
      expect(rec.drafts.single.params!.qualityPreset, 'standard');
      expect(rec.drafts.single.params!.ucPreset, 1);
    });

    testWidgets('新建块：没内容时保存不可点，有内容后 onCreate', (t) async {
      await lib(t);
      await tapKey(t, 'blocks-create');
      await tapKey(t, 'block-edit-save');
      expect(rec.drafts, isEmpty);
      await t.enterText(find.byKey(const Key('block-atom-input')), 'blue sky');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      await tapKey(t, 'block-edit-save');
      expect(rec.drafts.single.atoms, ['blue sky']);
      expect(rec.calls, isEmpty);
    });
  });

  group('生图页侧栏', () {
    Future<void> dock(WidgetTester t) => pumpBlocks(
      t,
      Row(
        children: [
          SizedBox(
            width: 300,
            child: BlocksDock(
              data: BlocksFixture.dock(image: blocksTestImage),
              actions: rec.dock,
            ),
          ),
          const Spacer(),
        ],
      ),
      window: 900,
      rail: false,
    );

    testWidgets('点药丸插入、筛选、搜索、展开收起、新建、打开块库、关闭', (t) async {
      await dock(t);
      await t.tap(find.byKey(const Key('dock-pill-aq')).first);
      await t.pumpAndSettle();
      await tapKey(t, 'dock-chip-fav');
      await t.tap(
        find.descendant(
          of: find.byKey(const Key('dock-group-f-artists')),
          matching: find.text('画师集'),
        ),
      );
      await t.pumpAndSettle();
      await tapKey(t, 'dock-create');
      await tapKey(t, 'dock-library');
      await tapKey(t, 'dock-close');
      await t.enterText(
        find.descendant(
          of: find.byKey(const Key('dock-search')),
          matching: find.byType(EditableText),
        ),
        'rella',
      );
      await t.pump(const Duration(milliseconds: 400));
      expect(rec.calls, [
        'dock.insert:aq',
        'dock.filter:true:null',
        'dock.toggle:f-artists:false',
        'dock.create',
        'dock.openLibrary',
        'dock.close',
        'dock.query:rella',
      ]);
    });

    testWidgets('悬停 180ms 出预览卡；右键菜单编辑 / 收藏', (t) async {
      await dock(t);
      await hoverOver(t, find.byKey(const Key('dock-pill-pk')).first);
      await t.pump(const Duration(milliseconds: 200));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('block-hover-card')), findsOneWidget);
      await t.tapAt(
        t.getCenter(find.byKey(const Key('dock-pill-pk')).first),
        buttons: 2,
      );
      await t.pumpAndSettle();
      await t.tap(find.text('编辑'));
      await t.pumpAndSettle();
      expect(rec.calls, ['dock.edit:pk']);
    });
  });

  group('实例卡', () {
    Future<void> card(WidgetTester t, BlockInstanceViewData d) => pumpBlocks(
      t,
      Align(
        alignment: Alignment.topLeft,
        child: BlockInstanceCard(data: d, actions: rec.instance(d)),
      ),
      window: 600,
      height: 1000,
      rail: false,
    );

    testWidgets('随机：重抽、锁定、换模式、作用于负面、停用、改块、移除', (t) async {
      await card(t, BlocksFixture.instanceRandom());
      await tapKey(t, 'block-card-reroll');
      await tapKey(t, 'block-card-lock');
      await tapKey(t, 'block-card-mode-sequential');
      await tapKey(t, 'block-card-toggle');
      await tapKey(t, 'block-card-edit');
      await tapKey(t, 'block-card-remove');
      expect(rec.calls, [
        'reroll',
        'lock:true',
        'mode:sequential',
        'enabled:false',
        'editBlock',
        'remove',
      ]);
    });

    testWidgets('锁定时重抽不可点，解锁回调 false', (t) async {
      await card(t, BlocksFixture.instanceRandom(locked: true));
      await tapKey(t, 'block-card-reroll');
      await tapKey(t, 'block-card-lock');
      expect(rec.calls, ['lock:false']);
    });

    testWidgets('顺序：上一项 / 下一项', (t) async {
      await card(t, BlocksFixture.instanceSeq(blocksTestImage));
      await tapKey(t, 'block-card-step-prev');
      await tapKey(t, 'block-card-step-next');
      expect(rec.calls, ['step:-1', 'step:1']);
    });

    testWidgets('抽取规则：改数量和出现概率，点完成才回调；取消不回调', (t) async {
      final d = BlocksFixture.instanceRandom();
      await card(t, d);
      await tapKey(t, 'block-card-rules');
      await tapKey(t, 'block-rules-max');
      await t.enterText(
        find.descendant(
          of: find.byKey(const Key('block-rules-max')),
          matching: find.byType(EditableText),
        ),
        '3',
      );
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(rec.settings, isEmpty);
      expect(find.text('有改动 · 点完成后生效'), findsOneWidget);
      await tapKey(t, 'block-rules-done');
      expect(rec.settings.single.countMax, 3);
      expect(rec.settings.single.countMin, d.settings.countMin);

      await tapKey(t, 'block-card-rules');
      await tapKey(t, 'block-rules-order-original');
      await tapKey(t, 'block-rules-cancel');
      expect(rec.settings, hasLength(1));
    });

    testWidgets('抽取规则：换到固定只留概率；恢复默认', (t) async {
      await card(t, BlocksFixture.instanceRandom());
      await tapKey(t, 'block-card-rules');
      await tapKey(t, 'block-rules-mode-fixed');
      expect(find.byKey(const Key('block-rules-min')), findsNothing);
      expect(find.byKey(const Key('block-rules-prob')), findsOneWidget);
      await tapKey(t, 'block-rules-reset');
      await tapKey(t, 'block-rules-done');
      expect(rec.settings.single.mode, BlockMode.fixed);
    });
  });

  group('存为块', () {
    testWidgets('改名、换色、关掉“换成块”，回车保存；取消', (t) async {
      await pumpBlocks(
        t,
        Align(
          alignment: Alignment.topLeft,
          child: BlockQuickSave(data: BlocksFixture.quick, actions: rec.quick),
        ),
        window: 600,
        height: 700,
        rail: false,
      );
      await t.enterText(find.byKey(const Key('block-quick-title')), '白裙');
      await tapKey(t, 'block-color-3');
      await tapKey(t, 'block-quick-replace');
      expect(find.byType(UiBlockPill), findsOneWidget);
      await t.tap(find.byKey(const Key('block-quick-title')));
      await key(t, LogicalKeyboardKey.enter);
      final q = rec.quicks.single;
      expect(q.title, '白裙');
      expect(q.atoms, BlocksFixture.quick.atoms);
      expect(q.replaceSelection, isFalse);
      await tapKey(t, 'block-quick-cancel');
      expect(rec.calls, ['quick.cancel']);
    });

    testWidgets('选择工具条三个按钮', (t) async {
      final calls = <String>[];
      await pumpBlocks(
        t,
        Center(
          child: BlockSelectionToolbar(
            onSaveAsBlock: () => calls.add('save'),
            onCopy: () => calls.add('copy'),
            onLookup: () => calls.add('lookup'),
          ),
        ),
        window: 600,
        height: 300,
        rail: false,
      );
      await tapKey(t, 'block-sel-save');
      await tapKey(t, 'block-sel-copy');
      await tapKey(t, 'block-sel-lookup');
      expect(calls, ['save', 'copy', 'lookup']);
    });
  });
}
