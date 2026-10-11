// 预览模拟器冒烟：用 tool/ui_shell/explore_preview.dart 的模拟器驱动页面，走一遍抽候选 → 收藏 → 删除撤销 → 进化 → 培育，
// 确保预览里的按钮都能点、状态往返不崩。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_fixture_editor.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_page.dart';

import '../../../../tool/ui_shell/explore_preview.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'explore_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);

  Future<ExplorePreviewSim> pumpSim(WidgetTester t, ExploreScene scene) async {
    final logs = <String>[];
    final sim = ExplorePreviewSim(log: logs.add)..scene = scene;
    addTearDown(sim.dispose);
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1600 - exploreRail, 1000);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      exploreApp(
        ListenableBuilder(
          listenable: sim,
          builder: (context, _) => StyleExplorePage(
            data: sim.data,
            actions: sim.actions,
            editor: (context, parts) => exploreFixtureEditor(context, parts),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    return sim;
  }

  testWidgets('首次使用 → 抽第一批 → 全部出完', (t) async {
    final sim = await pumpSim(t, ExploreScene.empty);
    await tapKey(t, 'explore-onboarding-draw');
    expect(find.byKey(const Key('explore-progress')), findsOneWidget);
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(milliseconds: 700));
    }
    await t.pumpAndSettle();
    expect(sim.data.run!.progress, isNull);
    expect(sim.data.run!.candidates.where((c) => c.done), hasLength(10));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('收藏、删除撤销、进化、培育一路点下来', (t) async {
    final sim = await pumpSim(t, ExploreScene.main);
    await tapKey(t, 'explore-act-favorite');
    expect(sim.data.run!.candidate('c27')!.favorite, isFalse);

    await tapKey(t, 'explore-inspector-delete');
    expect(sim.data.run!.candidate('c27'), isNull);
    await tapKey(t, 'explore-undo-button');
    expect(sim.data.run!.candidate('c27'), isNotNull);

    await tapKey(t, 'explore-select');
    await tapKey(t, 'explore-card-c28');
    await tapKey(t, 'explore-card-c29');
    await tapKey(t, 'explore-sel-evo');
    await tapKey(t, 'explore-evo-create-generate');
    expect(sim.data.run!.lines, hasLength(3));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 700));
    }
    await t.pumpAndSettle();
    expect(sim.data.run!.lines.last.current.childKeys, hasLength(8));

    await tapKey(t, 'explore-tab-evolution');
    final kids = sim.data.run!.lines.last.current.childKeys;
    await tapKey(t, 'explore-kid-check-${kids[0]}');
    await tapKey(t, 'explore-kid-check-${kids[1]}');
    await tapKey(t, 'explore-breed');
    expect(sim.data.run!.lines.last.generations, hasLength(2));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 700));
    }
    await t.pumpAndSettle();
    expect(sim.data.run!.progress, isNull);

    await tapKey(t, 'explore-compare');
    await tapKey(t, 'explore-compare-left');
    await tapKey(t, 'explore-dialog-close');
    await t.pumpWidget(const SizedBox());
  });
}
