import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/nai_agent/panel_layout.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_window_controller.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:nai_launcher/presentation/ui/agent/agent_panel.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent_generation_host.dart';

import '../../../helpers/studio_capture_fonts.dart';
import '../../ui/gen/drag_preview_test_support.dart';
import '../../wiring/nai_agent/agent_wiring_harness.dart';

class _CountingController extends AgentTestController {
  _CountingController(super.store);
  final widths = <double>[];
  Completer<void>? writeGate;
  @override
  Future<void> updateSettings(
    Map<String, dynamic> patch, {
    Map<String, dynamic>? expected,
  }) async {
    if (patch['panelWidth'] case final num width) {
      widths.add(width.toDouble());
      await writeGate?.future;
    }
    await super.updateSettings(patch, expected: expected);
  }
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  late AgentWiringHarness h;
  late _CountingController controller;
  setUp(() async {
    h = AgentWiringHarness();
    await h.init(
      controller: (AgentWorkspaceStore store) =>
          controller = _CountingController(store),
    );
    await controller.updateSettings({'panelExpanded': true});
    h.container
        .read(naiAgentUiPreferencesProvider)
        .replace(controller.settings);
  });
  tearDown(() async => h.dispose());
  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });
  const key = 'nai-agent-resize';
  Future<DragCounts> pump(
    WidgetTester t, {
    Brightness brightness = Brightness.light,
  }) async {
    final counts = DragCounts();
    await h.pump(
      t,
      width: 1600,
      brightness: brightness,
      child: NaiAgentIntegrationScope(
        child: NaiAgentGenerationHost(
          child: DragCountProbe(counts, key: const Key('page-probe')),
        ),
      ),
    );
    return counts;
  }

  for (final brightness in Brightness.values) {
    testWidgets('Agent drag freezes page and panel; commit once $brightness', (
      t,
    ) async {
      final counts = await pump(t, brightness: brightness);
      final before = counts.snapshot;
      final page = t.getSize(find.byKey(const Key('page-probe')));
      final panel = t.getSize(find.byType(AgentPanel));
      final element = find.byKey(const Key('page-probe')).evaluate().single;
      final agentElement = find.byType(AgentPanel).evaluate().single;
      final panelRender = t.renderObject<RenderBox>(find.byType(AgentPanel));
      final g = await beginDividerDrag(t, key);
      var delta = 0.0;
      for (final dx in [-40.0, -70.0, -650.0]) {
        delta += dx;
        await g.moveBy(Offset(dx, 0));
        await t.pump();
        final width = AgentPanelLayout.resolve(520 - delta, 1600);
        expect(previewPainter(t, key)!.position, 1600 - width - 4);
        expect(t.getSize(find.byKey(const Key('page-probe'))), page);
        expect(panelRender.size, panel);
        expect(counts.snapshot, before);
        expect(controller.widths, isEmpty);
      }
      await checkPreviewPaint(t, key);
      final line = previewPainter(t, key)!.position;
      await g.up();
      await t.pumpAndSettle();
      expect(previewPainter(t, key), isNull);
      expect(t.getCenter(find.byKey(const Key(key))).dx, line);
      expect(controller.widths, [1192]);
      expect(controller.settings.panelWidth, 1192);
      expect(counts.layouts, before.$2 + 1);
      expect(h.container.read(naiAgentWindowControllerProvider).addedWidth, 0);
      expect(
        find.byKey(const Key('page-probe')).evaluate().single,
        same(element),
      );
      expect(find.byType(AgentPanel).evaluate().single, same(agentElement));
      expect(t.takeException(), isNull);
    });
  }
  for (final escape in [false, true]) {
    testWidgets('Agent ${escape ? 'Esc' : 'pointer cancel'} does not persist', (
      t,
    ) async {
      final counts = await pump(t);
      final before = counts.snapshot;
      final g = await beginDividerDrag(t, key);
      await g.moveBy(const Offset(-80, 0));
      await t.pump();
      await cancelDividerDrag(t, g, key, escape: escape);
      expect(controller.widths, isEmpty);
      expect(controller.settings.panelWidth, 520);
      expect(counts.snapshot, before);
      expect(t.getSize(find.byType(AgentPanel)).width, 520);
    });
  }
  testWidgets(
    'Agent pending persistence and preference notification do not snap back',
    (t) async {
      final counts = await pump(t);
      controller.addListener(() {
        h.container
            .read(naiAgentUiPreferencesProvider)
            .replace(controller.settings);
      });
      final before = counts.layouts;
      final gate = controller.writeGate = Completer<void>();
      final g = await beginDividerDrag(t, key);
      await g.moveBy(const Offset(-80, 0));
      await t.pump();
      final line = previewPainter(t, key)!.position;
      await g.up();
      await t.pump();
      expect(previewPainter(t, key), isNull);
      expect(t.getCenter(find.byKey(const Key(key))).dx, line);
      expect(counts.layouts, before + 1);
      gate.complete();
      await t.pumpAndSettle();
      expect(controller.widths, [600]);
      expect(t.getCenter(find.byKey(const Key(key))).dx, line);
      expect(counts.layouts, before + 1);
    },
  );

  testWidgets('Agent zero net movement does not persist or relayout', (
    t,
  ) async {
    final counts = await pump(t);
    final before = counts.snapshot;
    final g = await beginDividerDrag(t, key);
    await g.moveBy(const Offset(-60, 0));
    await t.pump();
    await g.moveBy(const Offset(60, 0));
    await t.pump();
    await g.up();
    await t.pumpAndSettle();
    expect(controller.widths, isEmpty);
    expect(counts.snapshot, before);
    expect(t.getSize(find.byType(AgentPanel)).width, 520);
  });
}
