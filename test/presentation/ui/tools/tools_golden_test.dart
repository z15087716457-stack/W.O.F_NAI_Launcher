// 画布工具基准截图（中文浅色 / 深色）：用固定假数据锁定视觉。界面变了这里会失败。
// 只有界面方确认新样子后才更新基准：
//   flutter test --update-goldens test/presentation/ui/tools/tools_golden_test.dart
// 基准在 Windows + 内置真实字体下生成，其他系统跳过。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_contract.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_fixture.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'tools_test_harness.dart';

typedef _Pump = Future<void> Function(WidgetTester t, bool dark);

void main() {
  setUpAll(loadStudioCaptureFonts);
  final skip = !Platform.isWindows;

  _Pump gen({
    GenToolSheet? sheet,
    double? progress,
    bool custom = false,
    bool local = false,
  }) =>
      (t, dark) => pumpToolsGen(
        t,
        r: ToolsRecorder(),
        sheet: sheet,
        progress: progress,
        custom: custom,
        local: local,
        dark: dark,
      );

  _Pump editor({
    ToolsEditorMode mode = ToolsEditorMode.edit,
    bool focus = false,
    bool expand = false,
    double width = 1600,
    Future<void> Function(WidgetTester)? then,
  }) => (t, dark) async {
    await pumpToolsEditor(
      t,
      data: ToolsFixture.editor(mode: mode, focus: focus, expand: expand),
      dark: dark,
      width: width,
    );
    await then?.call(t);
  };

  _Pump director(
    ToolsDirectorData data, {
    double width = 1600,
    Future<void> Function(WidgetTester)? then,
  }) => (t, dark) async {
    await pumpToolsDirector(t, data: data, dark: dark, width: width);
    await then?.call(t);
  };

  // (文件名, 装载, 也拍深色)
  final scenes = <(String, _Pump, bool)>[
    ('enhance', gen(sheet: GenToolSheet.enhance), true),
    ('enhance-custom', gen(sheet: GenToolSheet.enhance, custom: true), false),
    ('enhance-local', gen(sheet: GenToolSheet.enhance, local: true), false),
    ('upscale', gen(sheet: GenToolSheet.upscale), true),
    (
      'upscale-advanced',
      (t, dark) async {
        await gen(sheet: GenToolSheet.upscale)(t, dark);
        await tapKey(t, 'tools-upscale-advanced');
      },
      false,
    ),
    ('uprun', gen(progress: .37), true),
    (
      'bar-tip',
      (t, dark) async {
        await gen()(t, dark);
        await hoverOver(t, find.byKey(const Key('gen-variations')));
        await t.pump(const Duration(milliseconds: 400));
      },
      false,
    ),
    ('edit', editor(), true),
    (
      'edit-narrow',
      editor(width: 980, then: (t) => tapKey(t, 'tools-editor-side-toggle')),
      false,
    ),
    ('inpaint', editor(mode: ToolsEditorMode.inpaint), true),
    (
      'inpaint-menu',
      editor(
        mode: ToolsEditorMode.inpaint,
        then: (t) => tapKey(t, 'tools-editor-apply-menu'),
      ),
      true,
    ),
    (
      'inpaint-focus',
      editor(mode: ToolsEditorMode.inpaint, focus: true),
      false,
    ),
    (
      'inpaint-expand',
      editor(mode: ToolsEditorMode.inpaint, expand: true),
      true,
    ),
    ('dt', director(ToolsFixture.director()), true),
    (
      'dt-wipe',
      director(
        ToolsFixture.director(),
        then: (t) => tapKey(t, 'tools-compare-wipe'),
      ),
      false,
    ),
    ('dt-emotion', director(ToolsFixture.emotion()), true),
    ('dt-removebg', director(ToolsFixture.removeBg()), false),
    ('dt-running', director(ToolsFixture.running()), false),
    ('dt-failed', director(ToolsFixture.failed()), true),
    ('dt-pixel', director(ToolsFixture.pixel()), false),
    ('dt-empty', director(ToolsFixture.empty), false),
    ('dt-compact', director(ToolsFixture.director(), width: 1200), false),
  ];

  for (final (file, pump, alsoDark) in scenes) {
    for (final dark in [false, if (alsoDark) true]) {
      final name = dark ? '$file-dark' : file;
      testWidgets('golden $name', skip: skip, (t) async {
        await pump(t, dark);
        await expectLater(
          find.byKey(const Key('gen-capture')),
          matchesGoldenFile('goldens/$name.png'),
        );
        await t.pump(const Duration(seconds: 1));
      });
    }
  }
}
