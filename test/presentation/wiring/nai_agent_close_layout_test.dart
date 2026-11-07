import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_window_controller.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:nai_launcher/presentation/wiring/nai_agent_generation_host.dart';

import 'nai_agent/agent_wiring_harness.dart';

const _page = Key('kept-page');
const _dock = Key('nai-agent-reveal');

class _NativeWindow extends NaiAgentWindowHost {
  _NativeWindow(this.workAreaRight);

  final double workAreaRight;
  Rect rect = const Rect.fromLTWH(100, 40, 1000, 700);
  final restore = Completer<void>();
  bool requestedRestore = false;
  bool ignoreRestore = false;

  @override
  Future<Rect> bounds() async => rect;

  @override
  Future<bool> locked() async => false;

  @override
  Future<List<Rect>> workAreas() async => [
    Rect.fromLTWH(0, 0, workAreaRight, 1040),
  ];

  @override
  Future<void> setBounds(Rect bounds) async {
    if (bounds.width < rect.width) {
      requestedRestore = true;
      await restore.future;
      if (ignoreRestore) return;
    }
    rect = bounds;
  }
}

void main() {
  late AgentWiringHarness harness;
  late _NativeWindow native;
  late NaiAgentWindowController controller;

  Future<void> open(WidgetTester tester, {double workAreaRight = 1920}) async {
    addTearDown(tester.view.reset);
    native = _NativeWindow(workAreaRight);
    harness = AgentWiringHarness();
    await tester.runAsync(
      () => harness.init(
        overrides: [naiAgentWindowHostProvider.overrideWithValue(native)],
      ),
    );
    controller = harness.container.read(naiAgentWindowControllerProvider);
    await harness.pump(
      tester,
      width: 1000,
      height: 700,
      child: const NaiAgentIntegrationScope(
        child: NaiAgentGenerationHost(child: SizedBox.expand(key: _page)),
      ),
    );
    await tester.runAsync(controller.toggle);
    harness.container
        .read(naiAgentUiPreferencesProvider)
        .replace(harness.c.settings);
    tester.view.physicalSize = Size(native.rect.width, 700);
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(_page)).width, native.rect.width - 528);
    expect(tester.getSize(find.byKey(_dock)).width, 528);
  }

  // Publish the preference while leaving the native resize reply pending.
  Future<Future<void> Function()> startClosing(WidgetTester tester) async {
    final pending = controller.close();
    final prefs = harness.container.read(naiAgentUiPreferencesProvider);
    for (var i = 0; i < 80 && !native.requestedRestore; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(native.requestedRestore, isTrue);
    prefs.replace(
      AgentSettings.fromJson({
        ...harness.c.settings.toJson(),
        'panelExpanded': false,
      }),
    );
    await tester.pump();
    return () async {
      native.restore.complete();
      await pending;
      await tester.pump();
    };
  }

  for (final replyFirst in [true, false]) {
    testWidgets('native close retains main width with replyFirst=$replyFirst', (
      tester,
    ) async {
      await open(tester);
      final page = find.byKey(_page);
      final dock = find.byKey(_dock);
      final element = page.evaluate().single;
      final finish = await startClosing(tester);
      expect(tester.getSize(page).width, 1000);
      expect(tester.getSize(dock).width, 528);

      if (replyFirst) {
        await finish();
        expect(tester.getSize(page).width, 1000);
        expect(tester.getSize(dock).width, 528);
      }
      tester.view.physicalSize = const Size(1000, 700);
      await tester.pump();
      expect(tester.getSize(page).width, 1000);
      expect(tester.getSize(dock).width, 0);
      if (!replyFirst) await finish();
      expect(page.evaluate().single, same(element));

      tester.view.physicalSize = const Size(1528, 700);
      await tester.pump();
      expect(tester.getSize(page).width, 1528);
      expect(tester.getSize(dock).width, 0);
    });
  }

  testWidgets('partial window growth closes without a page-width overshoot', (
    tester,
  ) async {
    await open(tester, workAreaRight: 1400);
    final page = find.byKey(_page);
    final finish = await startClosing(tester);
    expect(tester.getSize(page).width, 764);
    tester.view.physicalSize = const Size(1146, 700);
    await tester.pump();
    expect(tester.getSize(page).width, 882);
    tester.view.physicalSize = const Size(1000, 700);
    await finish();
    expect(tester.getSize(page).width, 1000);
  });

  testWidgets('native restore with unchanged window bounds closes in place', (
    tester,
  ) async {
    await open(tester);
    native.ignoreRestore = true;
    final finish = await startClosing(tester);
    expect(tester.getSize(find.byKey(_page)).width, 1000);
    await finish();
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(_page)).width, 1528);
    expect(tester.getSize(find.byKey(_dock)).width, 0);
  });
}
