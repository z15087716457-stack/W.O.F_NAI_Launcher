import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_page.dart';

import 'blocks_test_harness.dart';

void main() {
  final now = DateTime(2026, 10, 26);
  final blocks = [
    for (var i = 0; i < 30; i++)
      BlockData(
        id: 'b$i',
        title: 'Block $i',
        color: Colors.blue,
        atoms: const ['blue_eyes'],
        createdAt: now,
        updatedAt: now,
      ),
  ];

  int directlyBelow(WidgetTester t, {bool list = false}) {
    Finder tile(int i) =>
        find.byKey(Key('blocks-${list ? 'row' : 'card'}-b$i'));
    final first = t.getCenter(tile(0));
    final candidates = <(int, double)>[];
    for (var i = 1; i < blocks.length; i++) {
      final card = tile(i);
      if (card.evaluate().isEmpty) continue;
      final point = t.getCenter(card);
      if ((point.dx - first.dx).abs() < .1 && point.dy > first.dy + 1) {
        candidates.add((i, point.dy));
      }
    }
    candidates.sort((a, b) => a.$2.compareTo(b.$2));
    expect(candidates, isNotEmpty);
    return candidates.first.$1;
  }

  for (final (width, sidebar, inspector, size, view, grouped) in [
    (1600.0, true, true, .5, BlocksView.grid, false),
    (1600.0, false, true, .5, BlocksView.grid, false),
    (1600.0, true, false, .5, BlocksView.grid, false),
    (1600.0, false, false, .5, BlocksView.grid, false),
    (1200.0, true, true, .5, BlocksView.grid, false),
    (900.0, true, true, .5, BlocksView.grid, false),
    (650.0, true, true, .5, BlocksView.grid, false),
    (1600.0, true, true, .0, BlocksView.grid, false),
    (1600.0, true, true, 1.0, BlocksView.grid, false),
    (1600.0, true, true, .5, BlocksView.list, false),
    (1600.0, true, true, .5, BlocksView.grid, true),
    (1600.0, true, true, .5, BlocksView.masonry, true),
  ]) {
    testWidgets(
      'vertical navigation follows $width $sidebar/$inspector size=$size ${view.name} grouped=$grouped',
      (t) async {
        final rec = RecordingBlocks();
        BlocksLibraryViewData data(String selected) => BlocksLibraryViewData(
          now: now,
          blocks: blocks,
          counts: const BlocksCounts(all: 30),
          selectedId: selected,
          view: view,
          cardSize: size,
          sidebarOpen: sidebar,
          inspectorOpen: inspector,
          groupByFolder: grouped,
          groups: grouped
              ? const [
                  BlocksGroup(
                    folderId: 'one',
                    path: 'One',
                    start: 0,
                    count: 16,
                  ),
                  BlocksGroup(
                    folderId: 'two',
                    path: 'Two',
                    start: 16,
                    count: 14,
                  ),
                ]
              : null,
        );
        await pumpBlocks(
          t,
          BlocksLibraryPage(data: data('b0'), actions: rec.library),
          window: width,
          rail: false,
        );
        final target = directlyBelow(t, list: view == BlocksView.list);
        await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await t.pump();
        expect(rec.calls, ['select:b$target']);
        rec.calls.clear();
        await t.pumpWidget(
          blocksApp(
            BlocksLibraryPage(data: data('b$target'), actions: rec.library),
          ),
        );
        await t.pumpAndSettle();
        await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await t.pump();
        expect(rec.calls, ['select:b0']);
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'resizing and live card sizing update navigation on the same page',
    (t) async {
      final rec = RecordingBlocks();
      await pumpBlocks(
        t,
        BlocksLibraryPage(
          data: BlocksLibraryViewData(
            now: now,
            blocks: blocks,
            counts: const BlocksCounts(all: 30),
            selectedId: 'b0',
            view: BlocksView.grid,
          ),
          actions: rec.library,
        ),
        rail: false,
      );
      final state = t.state<BlocksLibraryPageState>(
        find.byType(BlocksLibraryPage),
      );
      for (final (width, size) in [(900.0, .0), (1600.0, 1.0), (1200.0, .5)]) {
        t.view.physicalSize = Size(width, 1000);
        state.setLiveSize(size);
        await t.pumpAndSettle();
        final target = directlyBelow(t);
        rec.calls.clear();
        await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await t.pump();
        expect(rec.calls, ['select:b$target']);
      }
    },
  );
}
