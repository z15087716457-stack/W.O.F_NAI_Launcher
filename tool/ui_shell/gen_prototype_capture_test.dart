// 生图页：和 HTML 原型（.devin/mockups/generation/mock.html）同场景、同尺寸（1600 × 1120，含 48 主导航）的实绘，
// 用原型同一批图；外加每个场景关键元素的位置（rects.json，原点在主导航右边），供 gen_measure.py 出偏差表。
// 运行：flutter test tool/ui_shell/gen_prototype_capture_test.dart
// 输出在 .dart_tool/ui-shell/gen/flutter/，不进仓库。
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_fixture.dart';

import '../../test/helpers/studio_capture_fonts.dart';
import '../../test/presentation/ui/gen/gen_test_harness.dart';

const _assets = '../../mockups/generation/assets';
final _images = <String, ImageProvider?>{};

ImageProvider? protoImage(String key) => _images.putIfAbsent(key, () {
  final f = File('$_assets/$key.jpg');
  return f.existsSync() ? MemoryImage(f.readAsBytesSync()) : null;
});

/// 键名 → Flutter 组件 Key（和 gen_measure.html 的键名一致）。
const _keys = {
  'left': 'gen-left',
  'header': 'gen-header',
  'model': 'gen-model',
  'quota': 'gen-quota',
  'prompt': 'gen-prompt',
  'tab-on': 'gen-tab-positive',
  'tab-neg': 'gen-tab-negative',
  'chars': 'gen-characters',
  'char-0': 'gen-character-0',
  'refs': 'gen-refs',
  'ref-img2img': 'gen-ref-img2img-row',
  'ref-vibe': 'gen-ref-vibe-row',
  'ref-precise': 'gen-ref-precise-row',
  'image': 'gen-image',
  'size-group': 'gen-size-group',
  'orientation': 'gen-orientation',
  'width': 'gen-width',
  'height': 'gen-height',
  'count': 'gen-count',
  'repeat': 'gen-repeat',
  'params': 'gen-params',
  'p-steps': 'gen-param-steps',
  'p-scale': 'gen-param-scale',
  'p-seed': 'gen-param-seed',
  'p-sampler': 'gen-param-sampler',
  'p-toggle': 'gen-params-toggle',
  'gbar': 'gen-generate-bar',
  'gbtn': 'gen-generate',
  'cost': 'gen-cost',
  'canvas': 'gen-canvas',
  'cimg': 'gen-tile-i1',
  'bar-top': 'gen-bar-top',
  'bar-info': 'gen-bar-info',
  'bar-actions': 'gen-bar-actions',
  'history': 'gen-history',
  'h-header': 'gen-history-header',
  'h-footer': 'gen-history-footer',
  'batch-0': 'gen-batch-tile-b1',
  'batch-1': 'gen-batch-tile-b2',
  'batch-2': 'gen-batch-tile-b3',
  'batch-3': 'gen-batch-tile-b4',
};

void main() {
  setUpAll(loadStudioCaptureFonts);
  final out = Directory('.dart_tool/ui-shell/gen/flutter')
    ..createSync(recursive: true);
  final rects = <String, Map<String, List<double>>>{};

  final scenes = <(String, GenViewData, bool)>[
    ('a', GenFixture.view(images: protoImage), false),
    ('a-dark', GenFixture.view(images: protoImage), true),
    ('a-v45', GenFixture.view(v45: true, images: protoImage), false),
    ('a-v45-dark', GenFixture.view(v45: true, images: protoImage), true),
  ];

  for (final (name, data, dark) in scenes) {
    testWidgets('capture $name', (tester) async {
      await pumpGen(tester, data: data, dark: dark);
      final m = <String, List<double>>{};
      for (final e in _keys.entries) {
        final f = find.byKey(Key(e.value));
        if (f.evaluate().isEmpty) continue;
        final r = tester.getRect(f.first);
        m[e.key] = [r.left, r.top, r.width, r.height];
      }
      rects[name] = m;
      final boundary =
          tester.renderObject(find.byKey(const Key('gen-capture')))
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '${out.path}/$name.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }

  tearDownAll(() {
    File('${out.path}/rects.json').writeAsStringSync(
      const JsonEncoder.withIndent(' ').convert(rects),
    );
  });
}
