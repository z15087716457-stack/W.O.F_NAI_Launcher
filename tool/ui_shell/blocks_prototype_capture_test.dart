// 块系统：和 HTML 原型（.devin/mockups/blocks/mock.html）同场景的实绘，用原型同一批图；
// 外加每个场景关键元素的位置（rects.json），供 blocks_measure.py 出偏差表。
// 管理页原点在主导航右边；侧栏 / 实例卡 / 规则 / 弹窗按各自根元素左上角算，和 blocks_measure.html 一致。
// 运行：flutter test tool/ui_shell/blocks_prototype_capture_test.dart
// 输出在 .dart_tool/ui-shell/blocks/flutter/，不进仓库。
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_dock.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_fixture.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_instance.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_page.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_quick.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_colors.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_fixture_image.dart';

import '../../test/helpers/studio_capture_fonts.dart';
import '../../test/presentation/ui/blocks/blocks_test_harness.dart';

const _assets = '../../mockups/blocks/assets';
final _images = <String, ImageProvider>{};

ImageProvider protoImage(String key) => _images.putIfAbsent(key, () {
  final f = File('$_assets/$key.jpg');
  return f.existsSync()
      ? MemoryImage(f.readAsBytesSync())
      : UiFixtureImage.gradient(key);
});

/// 原型键 → Flutter Key。
final _keys = <String, String>{
  'nav': 'blocks-nav',
  'nav-all': 'blocks-scope-all',
  'toolbar': 'blocks-toolbar',
  'search': 'blocks-search',
  'create': 'blocks-create',
  'multi': 'blocks-multi',
  'sort': 'blocks-sort',
  'view': 'blocks-view',
  'filter': 'blocks-filter-row',
  'quick-all': 'blocks-quick-all',
  'quick-image': 'blocks-quick-image',
  'grid': 'blocks-grid',
  for (final k in ['y99', 'pk', 'cy', 'bl', 'd3', 'fj', 'aq', 'sy', 'ak', 'pf'])
    'card-$k': 'blocks-card-$k',
  'cover-y99': 'blocks-cover-y99',
  'title-y99': 'blocks-title-y99',
  'meta-y99': 'blocks-meta-y99',
  'fav-pk': 'blocks-fav-pk',
  'hoverbar': 'blocks-hoverbar-fj',
  'insp': 'blocks-inspector',
  'insp-thumb': 'blocks-insp-thumb',
  'insp-insert': 'blocks-insp-insert',
  'insp-params': 'blocks-insp-params',
  'insp-colors': 'blocks-insp-colors',
  'insp-atoms': 'blocks-insp-atoms',
  'insp-meta': 'blocks-insp-meta',
  'selbar': 'blocks-selection-bar',
  'check-y99': 'blocks-check-y99',
  'dock': 'dock-root',
  'dock-create': 'dock-create',
  'dock-library': 'dock-library',
  'dock-close': 'dock-close',
  'dock-search': 'dock-search',
  'dock-favorites': 'dock-favorites',
  'dock-pill-pk': 'dock-pill-pk',
  '~hover': 'block-hover-card',
  'card': 'block-card',
  'card-more': 'block-card-more',
  'card-roll': 'block-card-roll',
  'card-rules': 'block-card-rules',
  'card-modes': 'block-card-modes',
  'card-footer': 'block-card-footer',
  'card-lock': 'block-card-lock',
  'card-reroll': 'block-card-reroll',
  'card-side': 'block-card-side',
  'card-toggle': 'block-card-toggle',
  'card-edit': 'block-card-edit',
  'card-remove': 'block-card-remove',
  'step-prev': 'block-card-step-prev',
  'step-next': 'block-card-step-next',
  'card-apply': 'block-card-apply',
  'card-thumb': 'block-card-thumb',
  'card-params': 'block-card-params',
  'rules': 'block-rules',
  'rules-back': 'block-rules-back',
  for (final m in BlockMode.values)
    'mode-${m.name}': 'block-rules-mode-${m.name}',
  'rules-min': 'block-rules-min',
  'rules-max': 'block-rules-max',
  'rules-order': 'block-rules-order',
  'rules-weight': 'block-rules-weight',
  'rules-wmin': 'block-rules-wmin',
  'rules-wavg': 'block-rules-wavg',
  'rules-wmax': 'block-rules-wmax',
  'rules-range': 'block-rules-range',
  'rules-prob': 'block-rules-prob',
  'rules-resample': 'block-rules-resample',
  'rules-sample': 'block-rules-sample',
  'rules-reset': 'block-rules-reset',
  'rules-cancel': 'block-rules-cancel',
  'rules-done': 'block-rules-done',
  'edit': 'block-edit',
  'edit-close': 'block-edit-close',
  'edit-title': 'block-edit-title',
  'edit-folder': 'block-edit-folder',
  'edit-atoms': 'block-edit-atoms',
  'edit-colors': 'block-edit-colors',
  'edit-icons': 'block-edit-icons',
  'edit-looks': 'block-edit-looks',
  'edit-delete': 'block-edit-delete',
  'edit-cancel': 'block-edit-cancel',
  'edit-save': 'block-edit-save',
  'edit-crop': 'block-edit-crop',
  'quick': 'block-quick',
  '~toolbar': 'block-selection-toolbar',
  'quick-title': 'block-quick-title',
  'quick-replace': 'block-quick-replace',
  'quick-colors': 'block-quick-colors',
  'quick-cancel': 'block-quick-cancel',
  'quick-save': 'block-quick-save',
};

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
  final out = Directory('.dart_tool/ui-shell/blocks/flutter')
    ..createSync(recursive: true);
  final rects = <String, Map<String, List<double>>>{};
  final rec = RecordingBlocks();

  Widget lib() => BlocksLibraryPage(
    data: BlocksFixture.library(image: protoImage),
    actions: rec.library,
  );
  Widget inst(BlockInstanceViewData d) =>
      _onPage(BlockInstanceCard(data: d, actions: rec.instance(d)));

  // (名字, 界面, 窗口宽, 窗口高, 有主导航, 根元素, 交互)
  final scenes =
      <
        (
          String,
          Widget,
          double,
          double,
          bool,
          String?,
          Future<void> Function(WidgetTester)?,
        )
      >[
        (
          'lib',
          lib(),
          1600,
          1000,
          true,
          null,
          (t) => hoverOver(t, find.byKey(const Key('blocks-card-fj'))),
        ),
        (
          'sel',
          lib(),
          1600,
          1000,
          true,
          null,
          (t) async {
            await tapKey(t, 'blocks-multi');
            for (final k in ['y99', 'pk', 'bl', 'aq', 'sy']) {
              await tapKey(t, 'blocks-card-$k');
            }
          },
        ),
        (
          'dock',
          Builder(
            builder: (context) => Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  key: const Key('dock-root'),
                  width: 300,
                  child: BlocksDock(
                    data: BlocksFixture.dock(image: protoImage),
                    actions: rec.dock,
                  ),
                ),
                Expanded(child: ColoredBox(color: context.ui.page)),
              ],
            ),
          ),
          1600,
          1000,
          false,
          'dock-root',
          (t) async {
            final y = find.byKey(const Key('dock-pill-y99'));
            await hoverOver(
              t,
              y.evaluate().isNotEmpty
                  ? y.first
                  : find.byKey(const Key('dock-pill-pk')).first,
            );
          },
        ),
        (
          'card',
          inst(BlocksFixture.instanceRandom()),
          600,
          560,
          false,
          'block-card',
          null,
        ),
        (
          'seq',
          inst(BlocksFixture.instanceSeq(protoImage)),
          600,
          600,
          false,
          'block-card',
          null,
        ),
        (
          'fixed',
          inst(BlocksFixture.instanceFixed(protoImage)),
          600,
          700,
          false,
          'block-card',
          null,
        ),
        (
          'rules',
          inst(BlocksFixture.instanceRandom()),
          600,
          900,
          false,
          'block-rules',
          (t) => tapKey(t, 'block-card-rules'),
        ),
        (
          'edit',
          lib(),
          1600,
          1000,
          true,
          'block-edit',
          (t) => tapKey(t, 'blocks-insp-edit'),
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
          600,
          640,
          false,
          'block-quick',
          null,
        ),
      ];

  for (final (name, child, window, height, rail, root, interact) in scenes) {
    testWidgets(name, (t) async {
      debugDisableShadows = false;
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = Size(window - (rail ? blocksRail : 0), height);
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(blocksApp(child));
      await t.runAsync(() async {
        final ctx = t.element(find.byType(Scaffold));
        for (final b in BlocksFixture.blocks(protoImage)) {
          if (b.thumb != null) await precacheImage(b.thumb!.image, ctx);
        }
      });
      await t.pumpAndSettle();
      if (interact != null) {
        await interact(t);
        await t.pumpAndSettle();
      }
      var origin = Offset.zero;
      if (root != null) {
        final r = find.byKey(Key(root));
        if (r.evaluate().length == 1) origin = t.getRect(r).topLeft;
      }
      final m = <String, List<double>>{};
      if (root != null) {
        final r = t.getRect(find.byKey(Key(root)));
        m['@root'] = [r.left, r.top, r.width, r.height];
      }
      for (final MapEntry(key: k, value: id) in _keys.entries) {
        final f = find.byKey(Key(id));
        if (f.evaluate().length == 1) {
          final r = t.getRect(f).shift(-origin);
          m[k] = [r.left, r.top, r.width, r.height];
        }
      }
      rects[name] = m;
      await t.runAsync(() async {
        final b = t.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('blocks-capture')),
        );
        final img = await b.toImage();
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File(
          '${out.path}/$name.png',
        ).writeAsBytesSync(png!.buffer.asUint8List());
      });
      await t.pumpWidget(const SizedBox());
      debugDisableShadows = true;
    });
  }

  tearDownAll(() {
    File(
      '${out.path}/rects.json',
    ).writeAsStringSync(const JsonEncoder.withIndent(' ').convert(rects));
  });
}
