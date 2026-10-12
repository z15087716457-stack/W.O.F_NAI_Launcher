// 预览模拟器冒烟：工具条按钮开面板、进编辑器 / 导演工具、假运行出结果。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_contract.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_director.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_editor.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_fixture.dart';

import '../../../../tool/ui_shell/tools_preview.dart';
import '../../../helpers/studio_capture_fonts.dart';
import '../gen/gen_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  Future<ToolsPreviewSim> pumpSim(WidgetTester t, [ToolsScene? scene]) async {
    final sim = ToolsPreviewSim(log: (_) {});
    if (scene != null) sim.scene = scene;
    addTearDown(sim.dispose);
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1552, 1000);
    addTearDown(t.view.resetPhysicalSize);
    await t.pumpWidget(
      genApp(
        ListenableBuilder(
          listenable: sim,
          builder: (context, _) => switch (sim.view) {
            ToolsView.gen => GenerationPage(
              data: sim.gen.data,
              actions: sim.gen.actions,
              slots: GenSlots(editor: sim.gen.editor, toolSheet: sim.sheet()),
            ),
            ToolsView.editor => ToolsEditorPage(
              data: sim.editor,
              actions: sim.editorActions,
              slots: const ToolsEditorSlots(canvas: ToolsFixtureStage.builder),
            ),
            ToolsView.director => ToolsDirectorPage(
              data: sim.director,
              actions: sim.directorActions,
            ),
          },
        ),
      ),
    );
    await t.pumpAndSettle();
    return sim;
  }

  testWidgets('增强 / 放大设置面板开关，放大设置里换成云端', (t) async {
    await pumpSim(t);
    await tapKey(t, 'gen-enhance');
    expect(find.byKey(const Key('tools-enhance-sheet')), findsOneWidget);
    await tapKey(t, 'tools-scale-1.5');
    expect(find.text('832×1216 → 1248×1824'), findsOneWidget);
    await tapKey(t, 'gen-upscale-menu');
    expect(find.byKey(const Key('tools-upscale-sheet')), findsOneWidget);
    await tapKey(t, 'tools-backend-novelai');
    expect(find.byKey(const Key('tools-upscale-method')), findsNothing);
    await tapKey(t, 'tools-sheet-close');
    expect(find.byKey(const Key('tools-upscale-sheet')), findsNothing);
  });

  testWidgets('点放大：进度走完自动结束', (t) async {
    await pumpSim(t);
    await tapKey(t, 'gen-upscale');
    await t.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('gen-upscale-strip')), findsOneWidget);
    await t.pump(const Duration(seconds: 7));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('gen-upscale-strip')), findsNothing);
  });

  testWidgets('编辑图像：切工具、加图层，取消回生图', (t) async {
    await pumpSim(t);
    await tapKey(t, 'gen-edit');
    expect(find.byKey(const Key('tools-editor')), findsOneWidget);
    await tapKey(t, 'tools-tool-blur');
    expect(find.byKey(const Key('tools-opt-intensity')), findsOneWidget);
    await tapKey(t, 'tools-layer-add');
    expect(find.text('图层 2'), findsWidgets);
    await tapKey(t, 'tools-editor-back');
    await t.tap(find.text('放弃'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('gen-canvas')), findsOneWidget);
  });

  testWidgets('局部重绘：进出扩展边缘，应用回生图', (t) async {
    await pumpSim(t);
    await tapKey(t, 'gen-inpaint');
    await tapKey(t, 'tools-tool-expand');
    expect(find.byKey(const Key('tools-expand-done')), findsOneWidget);
    await tapKey(t, 'tools-expand-done');
    expect(find.byKey(const Key('tools-expand-done')), findsNothing);
    await tapKey(t, 'tools-editor-apply-main');
    expect(find.byKey(const Key('gen-canvas')), findsOneWidget);
  });

  testWidgets('导演工具：选线稿提取运行，结果进列表并选中', (t) async {
    final sim = await pumpSim(t);
    await tapKey(t, 'gen-send-tools');
    expect(find.byKey(const Key('tools-director')), findsOneWidget);
    final before = sim.director.runs.length;
    await tapKey(t, 'tools-dt-lineArt');
    await tapKey(t, 'tools-dt-run');
    expect(find.byKey(const Key('tools-result-running')), findsOneWidget);
    await t.pump(const Duration(seconds: 2));
    await t.pumpAndSettle();
    expect(sim.director.runs.length, before + 1);
    expect(sim.director.currentRun?.tool, ToolsDirectorTool.lineArt);
    await tapKey(t, 'tools-act-continue');
    expect(sim.director.inputs.length, 4);
  });

  testWidgets('所有预设状态都能渲染', (t) async {
    for (final s in ToolsScene.values) {
      final sim = await pumpSim(t, s);
      expect(t.takeException(), isNull, reason: s.name);
      sim.scene = ToolsScene.bar; // 停掉放大进度的计时器
    }
  });
}
