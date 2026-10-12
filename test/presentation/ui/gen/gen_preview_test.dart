// 预览模拟器冒烟：各场景能画出来，“生成”按计时器假装出图，进历史栏。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';

import '../../../../tool/ui_shell/gen_preview.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'gen_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  Future<GenPreviewSim> pumpSim(WidgetTester t, GenScene scene) async {
    final sim = GenPreviewSim(log: (_) {})..scene = scene;
    addTearDown(sim.dispose);
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1552, 1120);
    addTearDown(t.view.resetPhysicalSize);
    await t.pumpWidget(
      genApp(
        ListenableBuilder(
          listenable: sim,
          builder: (context, _) => GenerationPage(
            data: sim.data,
            actions: sim.actions,
            slots: GenSlots(editor: sim.editor, dock: sim.dock()),
          ),
        ),
      ),
    );
    await t.pump();
    return sim;
  }

  for (final s in GenScene.values.where((s) => s != GenScene.blocksDemo)) {
    testWidgets('场景 ${s.name} 能画出来', (t) async {
      await pumpSim(t, s);
      expect(find.byType(GenerationPage), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('生成：计时器出图，进历史栏', (t) async {
    final sim = await pumpSim(t, GenScene.v5);
    final before = sim.data.history.batches.length;
    await tapKey(t, 'gen-count-2');
    await t.tap(find.byKey(const Key('gen-generate')));
    await t.pump();
    expect(sim.data.generate.state, GenRunState.generating);
    await t.pump(const Duration(seconds: 4));
    expect(sim.data.generate.state, GenRunState.ready);
    expect(sim.data.history.batches, hasLength(before + 1));
    expect(sim.data.history.batches.first.images, hasLength(2));
  });

  testWidgets('打开块库侧栏', (t) async {
    await pumpSim(t, GenScene.v5);
    await tapKey(t, 'gen-tool-dock');
    expect(find.byKey(const Key('gen-dock')), findsOneWidget);
  });
}
