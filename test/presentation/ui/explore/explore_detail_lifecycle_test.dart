import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_contract.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_page.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_page.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';

import 'explore_test_harness.dart';

void main() {
  final now = DateTime(2026, 10, 26);
  late RecordingExploreActions rec;
  setUp(() => rec = RecordingExploreActions());

  Future<void> mount(WidgetTester t, ExploreViewData data) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(2000, 1200);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    await t.pumpWidget(
      exploreApp(
        WindowChromeScope(
          enabled: false,
          child: StyleExplorePage(
            data: data,
            actions: rec.actions,
            editor: (_, _) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  ExploreController controller(WidgetTester t) =>
      t.state(find.byType(StyleExplorePage)) as ExploreController;
  ImageViewerPage viewer(WidgetTester t) =>
      t.widget<ImageViewerPage>(find.byType(ImageViewerPage));

  ExploreViewData evolution() => ExploreViewData(
    now: now,
    run: ExploreRunView(
      id: 'evo',
      name: 'Evolution fixture',
      createdAt: now,
      candidates: [
        for (final (i, key) in [
          'basic',
          'history-only',
          'old-child',
          'old-unused',
          'kid-1',
          'kid-2',
        ].indexed)
          ExploreCandidate(key: key, roundId: 'r', number: i + 1),
      ],
      rounds: [
        ExploreRound(
          id: 'r',
          number: 1,
          createdAt: now,
          keys: const ['basic', 'history-only'],
        ),
      ],
      lines: const [
        ExploreLine(
          id: 'line',
          name: 'Line',
          generations: [
            ExploreGeneration(
              number: 1,
              parents: [
                ExploreParent(
                  id: 'old-basic',
                  atoms: [],
                  candidateKey: 'history-only',
                ),
              ],
              childKeys: ['old-child', 'old-unused'],
            ),
            ExploreGeneration(
              number: 2,
              parents: [
                ExploreParent(id: 'basic', atoms: [], candidateKey: 'basic'),
                ExploreParent(
                  id: 'old-child',
                  atoms: [],
                  candidateKey: 'old-child',
                ),
                ExploreParent(id: 'custom', atoms: []),
              ],
              childKeys: ['kid-1', 'kid-2'],
            ),
          ],
        ),
      ],
    ),
  );

  for (final key in ['basic', 'old-child', 'history-only', 'old-unused']) {
    testWidgets('evolution detail includes $key and its line history', (
      t,
    ) async {
      await mount(t, evolution());
      final ctrl = controller(t);
      ctrl.setTab(ExploreTab.evolution);
      await t.pumpAndSettle();
      if (key == 'basic' || key == 'old-child') {
        await tapKey(t, 'explore-parent-$key');
      } else {
        await t.ensureVisible(find.byKey(const Key('explore-gen-1')));
        await tapKey(t, 'explore-gen-1');
        final target = key == 'history-only'
            ? 'explore-parent-old-basic'
            : 'explore-kid-old-unused';
        await t.ensureVisible(find.byKey(Key(target)));
        await tapKey(t, target);
      }
      expect(ctrl.focusKey, key);
      await tapKey(t, 'explore-inspector-open');
      expect(viewer(t).data.current?.key, key);
      expect(viewer(t).data.items.map((item) => item.key).toSet(), {
        'basic',
        'history-only',
        'old-child',
        'old-unused',
        'kid-1',
        'kid-2',
      });
      final total = viewer(t).data.items.length;
      for (var i = 0; i < total; i++) {
        viewer(t).actions.onJump(last: i.isEven);
        await t.pumpAndSettle();
        expect(viewer(t).data.current, isNotNull);
      }
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('current children keep their existing child-only sequence', (
    t,
  ) async {
    await mount(t, evolution());
    final ctrl = controller(t)..setTab(ExploreTab.evolution);
    await t.pumpAndSettle();
    ctrl.openDetail('kid-1');
    await t.pumpAndSettle();
    expect(viewer(t).data.items.map((item) => item.key), ['kid-1', 'kid-2']);
    expect(viewer(t).data.current?.key, 'kid-1');
  });

  ExploreViewData candidates({
    List<String> keys = const ['one'],
    bool fullscreen = true,
    String? runId = 'run',
  }) => ExploreViewData(
    now: now,
    fullscreen: fullscreen,
    run: runId == null
        ? null
        : ExploreRunView(
            id: runId,
            name: 'Fixture',
            createdAt: now,
            candidates: [
              for (final (i, key) in keys.indexed)
                ExploreCandidate(key: key, roundId: 'r', number: i + 1),
            ],
            rounds: [
              ExploreRound(id: 'r', number: 1, createdAt: now, keys: keys),
            ],
          ),
  );

  for (final reason in ['last deletion', 'new run', 'no run']) {
    testWidgets('automatic detail close exits fullscreen: $reason', (t) async {
      await mount(t, candidates());
      controller(t).openDetail('one');
      await t.pumpAndSettle();
      if (reason == 'last deletion') viewer(t).actions.onDelete('one');
      rec.calls.clear();
      await mount(t, switch (reason) {
        'new run' => candidates(keys: ['other'], runId: 'other'),
        'no run' => candidates(runId: null),
        _ => candidates(keys: []),
      });
      expect(find.byType(ImageViewerPage), findsNothing);
      expect(
        rec.calls.where((value) => value == 'fullscreen:false'),
        hasLength(1),
      );
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('deleting one of several detail items keeps fullscreen open', (
    t,
  ) async {
    await mount(t, candidates(keys: ['one', 'two']));
    controller(t).openDetail('one');
    await t.pumpAndSettle();
    rec.calls.clear();
    await mount(t, candidates(keys: ['two']));
    expect(viewer(t).data.current?.key, 'two');
    expect(viewer(t).data.fullscreen, isTrue);
    expect(rec.calls, isNot(contains('fullscreen:false')));
  });

  testWidgets('ordinary detail close exits fullscreen once', (t) async {
    await mount(t, candidates());
    controller(t).openDetail('one');
    await t.pumpAndSettle();
    rec.calls.clear();
    viewer(t).actions.onClose(keyboard: true);
    await t.pumpAndSettle();
    expect(
      rec.calls.where((value) => value == 'fullscreen:false'),
      hasLength(1),
    );
    expect(find.byType(ImageViewerPage), findsNothing);
  });

  testWidgets('an already closed page does not request a fullscreen change', (
    t,
  ) async {
    await mount(t, candidates());
    rec.calls.clear();
    await mount(t, candidates(runId: 'other', keys: []));
    expect(rec.calls, isNot(contains('fullscreen:false')));
  });

  testWidgets('a queued automatic close does not exit a newly opened detail', (
    t,
  ) async {
    await mount(t, candidates());
    controller(t).openDetail('one');
    await t.pumpAndSettle();
    rec.calls.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller(t).openDetail('two');
    });
    await mount(t, candidates(runId: 'other', keys: ['two']));
    expect(viewer(t).data.current?.key, 'two');
    expect(rec.calls, isNot(contains('fullscreen:false')));
    expect(t.takeException(), isNull);
  });
}
