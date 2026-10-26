// 块系统基准截图（中文浅色 / 深色）：用固定假数据锁定视觉。界面变了这里会失败。
// 只有界面方确认新样子后才更新基准：
//   flutter test --update-goldens test/presentation/ui/blocks/blocks_golden_test.dart
// 基准在 Windows + 内置真实字体下生成，其他系统跳过。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_dock.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_fixture.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_instance.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_page.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_quick.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_colors.dart';

import '../../../helpers/approved_visual_regions.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'blocks_test_harness.dart';

typedef _Interact = Future<void> Function(WidgetTester t);

/// 实例卡挂在一块页面底色上（左上留 40）。
Widget _onPage(Widget child) => Builder(
  builder: (context) => ColoredBox(
    color: context.ui.page,
    child: Align(
      alignment: Alignment.topLeft,
      child: Padding(padding: const EdgeInsets.all(40), child: child),
    ),
  ),
);

void main() {
  setUpAll(loadStudioCaptureFonts);
  final skip = !Platform.isWindows;
  final rec = RecordingBlocks();

  Widget lib(BlocksLibraryViewData d) =>
      BlocksLibraryPage(data: d, actions: rec.library);
  BlocksLibraryViewData view({
    BlocksView v = BlocksView.grid,
    bool empty = false,
    bool loading = false,
    String? selectedId = 'y99',
  }) => BlocksFixture.library(
    image: blocksTestImage,
    view: v,
    empty: empty,
    loading: loading,
    selectedId: selectedId,
  );

  Widget dock({
    BlocksDockFilter filter = const BlocksDockFilter.all(),
    String query = '',
    bool empty = false,
  }) => Builder(
    builder: (context) => Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 300,
          child: BlocksDock(
            data: empty
                ? const BlocksDockViewData()
                : BlocksFixture.dock(
                    image: blocksTestImage,
                    filter: filter,
                    query: query,
                  ),
            actions: rec.dock,
          ),
        ),
        Expanded(child: ColoredBox(color: context.ui.page)),
      ],
    ),
  );

  Widget inst(BlockInstanceViewData d) =>
      _onPage(BlockInstanceCard(data: d, actions: rec.instance(d)));

  final scenes = <(String, Widget, double, double, bool, _Interact?)>[
    (
      'lib',
      lib(view()),
      1600,
      1000,
      true,
      (t) => hoverOver(t, find.byKey(const Key('blocks-card-fj'))),
    ),
    (
      'lib-select',
      lib(view()),
      1600,
      1000,
      true,
      (t) async {
        await tapKey(t, 'blocks-multi');
        for (final k in ['y99', 'pk', 'bl', 'aq', 'sy']) {
          await tapKey(t, 'blocks-card-$k');
        }
      },
    ),
    ('lib-list', lib(view(v: BlocksView.list)), 1600, 1000, false, null),
    ('lib-empty', lib(view(empty: true)), 1600, 1000, true, null),
    ('lib-loading', lib(view(loading: true)), 1600, 1000, false, null),
    ('lib-plain', lib(view(selectedId: 'pk')), 1600, 1000, false, null),
    ('lib-narrow', lib(view()), 1100, 860, false, null),
    ('lib-narrower', lib(view()), 760, 860, false, null),
    (
      'lib-menu',
      lib(view()),
      1600,
      1000,
      false,
      (t) async {
        await t.tapAt(
          t.getCenter(find.byKey(const Key('blocks-card-cy'))),
          buttons: 2,
        );
        await t.pumpAndSettle();
      },
    ),
    (
      'edit',
      lib(view()),
      1600,
      1000,
      true,
      (t) => tapKey(t, 'blocks-insp-edit'),
    ),
    (
      'edit-new',
      lib(view()),
      1600,
      1000,
      false,
      (t) => tapKey(t, 'blocks-create'),
    ),
    (
      'dock',
      dock(),
      900,
      1000,
      true,
      (t) => hoverOver(t, find.byKey(const Key('dock-pill-pk')).first),
    ),
    ('dock-search', dock(query: '画师'), 900, 1000, false, null),
    ('dock-empty', dock(empty: true), 900, 1000, false, null),
    ('inst-random', inst(BlocksFixture.instanceRandom()), 600, 520, true, null),
    (
      'inst-locked',
      inst(BlocksFixture.instanceRandom(locked: true)),
      600,
      520,
      false,
      null,
    ),
    (
      'inst-seq',
      inst(BlocksFixture.instanceSeq(blocksTestImage)),
      600,
      560,
      true,
      null,
    ),
    (
      'inst-fixed',
      inst(BlocksFixture.instanceFixed(blocksTestImage)),
      600,
      640,
      false,
      null,
    ),
    (
      'inst-off',
      inst(BlocksFixture.instanceRandom(enabled: false)),
      600,
      520,
      false,
      null,
    ),
    (
      'rules',
      inst(BlocksFixture.instanceRandom()),
      600,
      860,
      true,
      (t) => tapKey(t, 'block-card-rules'),
    ),
    (
      'rules-advanced',
      inst(BlocksFixture.instanceRandom()),
      600,
      1000,
      false,
      (t) async {
        await tapKey(t, 'block-card-rules');
        await tapKey(t, 'block-rules-advanced');
      },
    ),
    (
      'quick',
      _onPage(
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            BlockSelectionToolbar(
              onSaveAsBlock: () {},
              onCopy: () {},
              onLookup: () {},
            ),
            BlockQuickSave(data: BlocksFixture.quick, actions: rec.quick),
          ],
        ),
      ),
      520,
      640,
      true,
      null,
    ),
  ];

  for (final (name, child, window, height, both, interact) in scenes) {
    for (final dark in both ? [false, true] : [false]) {
      final file = '$name${dark ? '-dark' : ''}';
      testWidgets(file, skip: skip, (t) async {
        debugDisableShadows = false;
        await pumpBlocks(
          t,
          child,
          window: window,
          height: height,
          dark: dark,
          rail: name.startsWith('lib') || name.startsWith('edit'),
        );
        if (interact != null) {
          await interact(t);
          await t.pumpAndSettle();
        }
        // 2026-10-21：块库工具栏加长搜索框、视图分段加“瀑布流”、新增“按文件夹分组”
        // 开关（用户确认）。只排除工具栏这一行；卡片墙仍按原网格逐像素比对。
        final bar = find.byKey(const Key('blocks-toolbar'));
        await expectOutsideApprovedRegions(
          t,
          find.byKey(const Key('blocks-capture')),
          'test/presentation/ui/blocks/goldens/$file.png',
          [
            if (bar.evaluate().isNotEmpty) t.getRect(bar).deflate(1),
            // 2026-10-27 C03（用户确认）：图标网格末尾新增「更多图标」格，只排除这一格。
            for (final e in find.byKey(const Key('block-icon-more')).evaluate())
              t.getRect(find.byWidget(e.widget)).inflate(1),
          ],
        );
        debugDisableShadows = true;
      });
    }
  }
}
