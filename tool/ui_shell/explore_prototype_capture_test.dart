// 画风探索：和 HTML 原型（.devin/mockups/style-explore/mock.html）同场景、同尺寸（1600 × 1000，含 48 主导航）的实绘，
// 用原型同一批图；外加每个场景关键元素的位置（rects.json，原点在主导航右边；大图按自己的根元素），
// 供 explore_measure.py 出偏差表。
// 运行：flutter test tool/ui_shell/explore_prototype_capture_test.dart
// 输出在 .dart_tool/ui-shell/explore/flutter/，不进仓库。
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_contract.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_fixture.dart';

import '../../test/helpers/studio_capture_fonts.dart';
import '../../test/presentation/ui/explore/explore_test_harness.dart';

const _assets = '../../mockups/style-explore/assets';
final _images = <String, ImageProvider?>{};

ImageProvider? protoImage(String name) => _images.putIfAbsent(name, () {
  final f = File('$_assets/$name.jpg');
  return f.existsSync() ? MemoryImage(f.readAsBytesSync()) : null;
});

/// 原型键名；Flutter Key 默认是 `explore-键名`。
const _names = [
  'editor', 'vars', 'genbar', 'header', 'run-button', 'progress', //
  'inspector-toggle', 'size-small', 'size-large', 'tab-candidates',
  'tab-evolution', 'line-l1', 'line-l2', 'new-line', 'evo-help', 'evo',
  'gen-3', 'gen-2', 'gen-1', 'compare', 'generate-children', 'breed',
  'parent-p3-1', 'parent-p3-5', 'kid-k3-1', 'kid-k3-2', 'kid-k3-12',
  'kid-check-k3-2', 'filter-all', 'filter-favorites', 'filter-ungrouped',
  'filter-g1', 'filter-g2', 'add-group', 'select', 'sort', 'select-all',
  'round-r3', 'round-r2', 'card-c27', 'card-c28', 'card-c29', 'card-c30',
  'card-c38', 'card-c17', 'heart-c27', 'pick-r3', 'selection-bar',
  'check-c27', 'inspector-multi', 'inspector', 'inspector-image',
  'copy-artists', 'act-favorite', 'act-evolution', 'act-block', 'act-apply',
  'inspector-delete', 'inspector-prompt-toggle', 'run-menu', 'run-search',
  'new-run', 'run-run1', 'run-run2', 'run-run5', 'onboarding-steps',
  'onboarding-runs', 'compare-dialog', 'compare-left', 'compare-right',
  'compare-neither', 'compare-skip', 'rank-p3-1', 'compare-left-image',
  'compare-right-image', 'evolution-dialog', 'evo-name', 'evo-parent-c27',
  'evo-parent-c33', 'evo-add-custom', 'evo-create', 'evo-create-generate',
  'block-dialog', 'block-name', 'block-folder', 'block-full', 'block-cancel',
  'block-save', 'detail', 'detail-info', 'detail-favorite',
  'detail-evolution', 'detail-block', 'detail-apply', 'detail-delete',
];
const _override = {
  'vars': 'explore-variables',
  'genbar': 'explore-generate-bar',
};

void main() {
  setUpAll(loadStudioCaptureFonts);
  final out = Directory('.dart_tool/ui-shell/explore/flutter')
    ..createSync(recursive: true);
  final rects = <String, Map<String, List<double>>>{};

  Future<void> select(WidgetTester t, List<int> numbers) async {
    await tapKey(t, 'explore-select');
    for (final n in numbers) {
      await t.tap(find.byKey(Key('explore-card-c$n')));
      await t.pumpAndSettle();
    }
  }

  final view = ExploreFixture.view(images: protoImage);
  // (名字, 数据, 根元素, 交互)
  final scenes =
      <
        (String, ExploreViewData, String?, Future<void> Function(WidgetTester)?)
      >[
        (
          'main',
          view,
          null,
          (t) => hoverOver(t, find.byKey(const Key('explore-card-c29'))),
        ),
        (
          'gen',
          ExploreFixture.view(images: protoImage, running: true),
          null,
          null,
        ),
        ('sel', view, null, (t) => select(t, [27, 29, 30, 33])),
        (
          'evo',
          view,
          null,
          (t) async {
            await tapKey(t, 'explore-tab-evolution');
            for (final k in ['k3-2', 'k3-5', 'k3-8']) {
              await tapKey(t, 'explore-kid-check-$k');
            }
          },
        ),
        ('runs', view, null, (t) => tapKey(t, 'explore-run-button')),
        ('empty', ExploreFixture.empty(images: protoImage), null, null),
        (
          'detail',
          view,
          'explore-detail',
          (t) async {
            await t.sendKeyEvent(LogicalKeyboardKey.enter);
            await t.pumpAndSettle();
          },
        ),
        (
          'ab',
          view,
          null,
          (t) async {
            await tapKey(t, 'explore-tab-evolution');
            await tapKey(t, 'explore-compare');
          },
        ),
        (
          'family',
          view,
          null,
          (t) async {
            await select(t, [27, 29, 30, 33]);
            await tapKey(t, 'explore-sel-evo');
          },
        ),
        (
          'adopt',
          view,
          null,
          (t) async {
            await select(t, [27, 29, 30]);
            await tapKey(t, 'explore-sel-block');
          },
        ),
      ];

  for (final (name, data, root, interact) in scenes) {
    testWidgets(name, (t) async {
      debugDisableShadows = false;
      await pumpExplore(t, data: data);
      if (interact != null) {
        await interact(t);
        await t.pumpAndSettle();
      }
      var origin = Offset.zero;
      final m = <String, List<double>>{};
      if (root != null) {
        final r = t.getRect(find.byKey(Key(root)));
        origin = r.topLeft;
        m['@root'] = [r.left, r.top, r.width, r.height];
      }
      for (final n in _names) {
        final f = find.byKey(Key(_override[n] ?? 'explore-$n'));
        if (f.evaluate().length == 1) {
          final r = t.getRect(f).shift(-origin);
          m[n] = [r.left, r.top, r.width, r.height];
        }
      }
      rects[name] = m;
      await t.runAsync(() async {
        final b = t.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('explore-capture')),
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
