// 画布工具：和 HTML 原型（.devin/mockups/tools/mock.html）同场景、同尺寸（1568 × 980）的实绘，
// 用原型同一批图；外加每个场景关键元素的位置（rects.json），供 tools_measure.py 出偏差表。
// 生图页画布、编辑器的坐标原点在主导航右边（窗口 x − 48）；导演工具整窗，原点在窗口左上。
// 运行：flutter test tool/ui_shell/tools_prototype_capture_test.dart
// 输出在 .dart_tool/ui-shell/tools/flutter/，不进仓库。
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_contract.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_fixture.dart';

import '../../test/helpers/studio_capture_fonts.dart';
import '../../test/presentation/ui/tools/tools_test_harness.dart';

final _images = <String, ImageProvider?>{};

ImageProvider? protoImage(String key) => _images.putIfAbsent(key, () {
  for (final p in [
    '../../mockups/tools/assets/$key.jpg',
    '../../mockups/tools/assets/$key.png',
    '../../mockups/generation/assets/$key.jpg',
  ]) {
    final f = File(p);
    if (f.existsSync()) return MemoryImage(f.readAsBytesSync());
  }
  return null;
});

/// 生图画布上的图换成工具原型的 src.jpg。
ImageProvider? genImage(String key) =>
    protoImage(key == 'canvas' ? 'src' : key);

/// 键名 → Flutter 组件 Key（和 tools_measure.html 的键名一致）。
const keys = {
  // 工具条 + 面板
  'bar-top': 'gen-bar-top',
  'tb-enhance': 'gen-enhance',
  'tb-upscale': 'gen-upscale',
  'tb-upmenu': 'gen-upscale-menu',
  'sheet': 'tools-enhance-sheet',
  'usheet': 'tools-upscale-sheet',
  'sheet-head': 'tools-sheet-head',
  'sheet-foot': 'tools-sheet-footer',
  'sheet-close': 'tools-sheet-close',
  'e-scale': 'tools-enhance-scale',
  'e-out': 'tools-enhance-out',
  'e-mag': 'tools-enhance-magnitude',
  'e-values': 'tools-enhance-values',
  'e-switch': 'tools-enhance-custom-switch',
  'e-custom': 'tools-enhance-custom',
  'e-local': 'tools-enhance-local',
  'e-run': 'tools-enhance-run',
  'e-cancel': 'tools-enhance-cancel',
  'u-backends': 'tools-upscale-backends',
  'u-local': 'tools-backend-local',
  'u-cloud': 'tools-backend-novelai',
  'u-method': 'tools-upscale-method',
  'u-model': 'tools-upscale-model',
  'u-manage': 'tools-upscale-manage',
  'u-scale': 'tools-upscale-scale',
  'u-out': 'tools-upscale-out',
  'u-adv': 'tools-upscale-advanced',
  'u-run': 'tools-upscale-run',
  'strip': 'gen-upscale-strip',
  'tip': 'gen-bar-tip',
  // 编辑器
  'ed-top': 'tools-editor-top',
  'ed-title': 'tools-editor-title',
  'ed-zoom': 'tools-editor-zoom',
  'ed-apply': 'tools-editor-apply',
  'ed-cancel': 'tools-editor-cancel',
  'ed-opt': 'tools-editor-options',
  'ed-rail': 'tools-editor-rail',
  'ed-work': 'tools-editor-work',
  'ed-img': 'tools-stage-image',
  'ed-side': 'tools-editor-side',
  'ed-stat': 'tools-editor-status',
  'ed-layers': 'tools-layers',
  'ed-adjust': 'tools-adjust',
  'ed-canvas': 'tools-canvas-size',
  'ed-iset': 'tools-inpaint-settings',
  'ed-note': 'tools-inpaint-note',
  'tool-0': 'tools-tool-brush',
  'tool-1': 'tools-tool-eraser',
  'tool-focus': 'tools-tool-focus',
  'opt-size': 'tools-opt-size',
  'opt-tip': 'tools-opt-tip',
  'mask-look': 'tools-mask-look',
  'apply-menu': 'tools-apply-menu',
  'layer-0': 'tools-layer-l1',
  'layer-mask': 'tools-layer-mask',
  'layer-base': 'tools-layer-base',
  'expand-out': 'tools-expand-out',
  // 导演工具
  'dt-top': 'tools-director-top',
  'dt-tools': 'tools-director-tools',
  'dt-stage': 'tools-director-stage',
  'dt-bar': 'tools-director-stagebar',
  'dt-seg': 'tools-compare',
  'dt-area': 'tools-director-area',
  'dt-acts': 'tools-director-actions',
  'dt-queue': 'tools-director-queue',
  'dt-side': 'tools-director-side',
  'dt-head': 'tools-dt-head',
  'dt-run': 'tools-dt-run',
  'dt-results': 'tools-dt-results',
  'dt-tool-0': 'tools-dt-removeBackground',
  'dt-tool-3': 'tools-dt-sketch',
  'dt-tool-5': 'tools-dt-emotion',
  'dt-tool-6': 'tools-dt-pixelSnap',
  'dt-emo': 'tools-dt-emotions',
  'dt-defry': 'tools-defry',
  'dt-prompt': 'tools-dt-prompt-box',
  'dt-run-0': 'tools-run-r1|tools-run-r2',
  'dt-q-0': 'tools-queue-in1',
  'dt-q-add': 'tools-queue-add',
  'dt-init': 'tools-act-init',
  'dt-orig': 'tools-pane-original',
  'dt-res': 'tools-pane-result',
  'dt-wipe': 'tools-pane-wipe',
};

typedef Scene = (String, Future<void> Function(WidgetTester));

void main() {
  setUpAll(loadStudioCaptureFonts);
  final out = Directory('.dart_tool/ui-shell/tools/flutter')
    ..createSync(recursive: true);
  final rects = <String, Map<String, List<double>>>{};

  Future<void> gen(
    WidgetTester t, {
    GenToolSheet? sheet,
    double? progress,
    bool custom = false,
    bool local = false,
    bool dark = false,
  }) => pumpToolsGen(
    t,
    r: ToolsRecorder(),
    sheet: sheet,
    progress: progress,
    custom: custom,
    local: local,
    dark: dark,
    images: genImage,
  );

  Future<void> editor(
    WidgetTester t, {
    ToolsEditorMode mode = ToolsEditorMode.edit,
    bool focus = false,
    bool expand = false,
    bool dark = false,
  }) => pumpToolsEditor(
    t,
    data: ToolsFixture.editor(
      mode: mode,
      focus: focus,
      expand: expand,
      images: protoImage,
    ),
    dark: dark,
  );

  final scenes = <Scene>[
    ('enhance', (t) => gen(t, sheet: GenToolSheet.enhance)),
    ('enhance-dark', (t) => gen(t, sheet: GenToolSheet.enhance, dark: true)),
    (
      'enhance-custom',
      (t) => gen(t, sheet: GenToolSheet.enhance, custom: true),
    ),
    ('enhance-local', (t) => gen(t, sheet: GenToolSheet.enhance, local: true)),
    ('upscale', (t) => gen(t, sheet: GenToolSheet.upscale)),
    ('upscale-dark', (t) => gen(t, sheet: GenToolSheet.upscale, dark: true)),
    ('uprun', (t) => gen(t, progress: .62)),
    (
      'bar',
      (t) async {
        await gen(t);
        await hoverOver(t, find.byKey(const Key('gen-variations')));
        await t.pump(const Duration(milliseconds: 400));
      },
    ),
    ('edit', (t) => editor(t)),
    ('edit-dark', (t) => editor(t, dark: true)),
    ('inpaint', (t) => editor(t, mode: ToolsEditorMode.inpaint)),
    (
      'inpaint-dark',
      (t) => editor(t, mode: ToolsEditorMode.inpaint, dark: true),
    ),
    (
      'inpaint-menu',
      (t) async {
        await editor(t, mode: ToolsEditorMode.inpaint);
        await tapKey(t, 'tools-editor-apply-menu');
      },
    ),
    (
      'inpaint-focus',
      (t) => editor(t, mode: ToolsEditorMode.inpaint, focus: true),
    ),
    (
      'inpaint-expand',
      (t) => editor(t, mode: ToolsEditorMode.inpaint, expand: true),
    ),
    (
      'dt',
      (t) =>
          pumpToolsDirector(t, data: ToolsFixture.director(images: protoImage)),
    ),
    (
      'dt-dark',
      (t) => pumpToolsDirector(
        t,
        data: ToolsFixture.director(images: protoImage),
        dark: true,
      ),
    ),
    (
      'dt-wipe',
      (t) async {
        await pumpToolsDirector(
          t,
          data: ToolsFixture.director(images: protoImage),
        );
        await tapKey(t, 'tools-compare-wipe');
      },
    ),
    (
      'dt-emotion',
      (t) =>
          pumpToolsDirector(t, data: ToolsFixture.emotion(images: protoImage)),
    ),
    (
      'dt-emotion-dark',
      (t) => pumpToolsDirector(
        t,
        data: ToolsFixture.emotion(images: protoImage),
        dark: true,
      ),
    ),
  ];

  for (final (name, pump) in scenes) {
    testWidgets('capture $name', (tester) async {
      await pump(tester);
      final m = <String, List<double>>{};
      for (final e in keys.entries) {
        // “a|b”：先找 a，没有再找 b（同一位置不同场景的 id 不同）。
        final f = e.value
            .split('|')
            .map((k) => find.byKey(Key(k)))
            .where((f) => f.evaluate().isNotEmpty)
            .firstOrNull;
        if (f == null) continue;
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
      // 悬停提示的计时器
      await tester.pump(const Duration(seconds: 1));
    });
  }

  tearDownAll(() {
    File(
      '${out.path}/rects.json',
    ).writeAsStringSync(const JsonEncoder.withIndent(' ').convert(rects));
  });
}
