import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_page.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'blocks_test_harness.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  final thumbnails = [
    for (final (width, height, color) in [
      (24, 48, img.ColorRgb8(50, 120, 200)),
      (48, 24, img.ColorRgb8(190, 90, 120)),
      (24, 30, img.ColorRgb8(60, 150, 110)),
    ])
      MemoryImage(
        img.encodePng(
          img.fill(
            img.Image(width: width, height: height),
            color: color,
          ),
        ),
      ),
  ];

  for (final (view, counts, withImages) in [
    for (final view in BlocksView.values)
      for (final counts in [
        [100, 37, 27],
        [2, 37, 3, 27],
      ])
        (view, counts, false),
    (BlocksView.masonry, [100, 37, 27], true),
    (BlocksView.masonry, [2, 37, 3, 27], true),
  ]) {
    testWidgets('grouped ${view.name} scrolls both ways and replaces pinned '
        'headers $counts images=$withImages', (tester) async {
      final blocks = <BlockData>[];
      final groups = <BlocksGroup>[];
      final now = DateTime(2026, 10, 21);
      for (var group = 0; group < counts.length; group++) {
        groups.add(
          BlocksGroup(
            folderId: 'folder-$group',
            path: 'Folder $group',
            start: blocks.length,
            count: counts[group],
          ),
        );
        for (var i = 0; i < counts[group]; i++) {
          blocks.add(
            BlockData(
              id: '$group-$i',
              title: 'Block $group-$i',
              color: Colors.blue,
              atoms: List.filled(1 + (i * 7) % 40, 'synthetic tag'),
              createdAt: now,
              updatedAt: now,
              folderId: 'folder-$group',
              thumb: withImages && i % 4 != 0
                  ? BlockThumb(
                      MemoryImage(
                        Uint8List.fromList(
                          thumbnails[i % thumbnails.length].bytes,
                        ),
                      ),
                    )
                  : null,
            ),
          );
        }
      }
      await pumpBlocks(
        tester,
        BlocksLibraryPage(
          data: BlocksLibraryViewData(
            now: now,
            blocks: blocks,
            counts: BlocksCounts(all: blocks.length),
            view: view,
            groupByFolder: true,
            groups: groups,
            sidebarOpen: false,
            inspectorOpen: false,
          ),
          actions: RecordingBlocks().library,
        ),
        window: 1500,
        height: 750,
      );
      if (withImages) {
        await tester.runAsync(() async {
          final context = tester.element(find.byType(BlocksLibraryPage));
          for (final block in blocks) {
            if (block.thumb case final thumb?) {
              await precacheImage(thumb.image, context);
            }
          }
        });
        await tester.pumpAndSettle();
      }
      final scrollable = find.descendant(
        of: find.byKey(
          Key(view == BlocksView.list ? 'blocks-list' : 'blocks-grid'),
        ),
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      final point = tester.getCenter(scrollable);
      final viewport = tester.getRect(scrollable);
      int pinnedGroup() {
        for (var group = 0; group < counts.length; group++) {
          final finder = find.byKey(Key('blocks-folder-bar-folder-$group'));
          if (finder.evaluate().isEmpty) continue;
          final header = tester.getRect(finder);
          if (header.bottom > viewport.top + .1 &&
              header.top < viewport.bottom) {
            expect(
              header.top,
              lessThanOrEqualTo(viewport.top + .1),
              reason:
                  'The active folder stays pinned until the next pushes it away.',
            );
            return group;
          }
        }
        fail('No folder header is visible.');
      }

      Future<void> wheel(double delta) async {
        await tester.sendEventToBinding(
          PointerScrollEvent(position: point, scrollDelta: Offset(0, delta)),
        );
        await tester.pumpAndSettle();
      }

      var reachedEnd = false;
      var lastPinned = pinnedGroup();
      var captured = false;
      for (var step = 0; step < 300; step++) {
        final before = position.pixels;
        await wheel(120);
        expect(
          position.pixels,
          greaterThanOrEqualTo(before - .01),
          reason: 'Downward wheel at step $step must not jump upward.',
        );
        final pinned = pinnedGroup();
        expect(pinned, greaterThanOrEqualTo(lastPinned));
        lastPinned = pinned;
        final output = Platform.environment['BLOCKS_GROUP_CAPTURES'];
        if (!captured && output != null && withImages && pinned == 1) {
          captured = true;
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const Key('blocks-capture')),
            );
            final image = await boundary.toImage();
            try {
              final png = (await image.toByteData(
                format: ui.ImageByteFormat.png,
              ))!;
              final file = File('$output/group-transition-${counts.first}.png');
              await file.parent.create(recursive: true);
              await file.writeAsBytes(png.buffer.asUint8List());
            } finally {
              image.dispose();
            }
          });
        }
        if (position.pixels >= position.maxScrollExtent - .01) {
          reachedEnd = true;
          break;
        }
      }
      expect(reachedEnd, isTrue);
      expect(lastPinned, counts.length - 1);
      final itemKind = view == BlocksView.list ? 'row' : 'card';
      expect(
        find.byKey(
          Key('blocks-$itemKind-${counts.length - 1}-${counts.last - 1}'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('blocks-$itemKind-0-0')),
        findsNothing,
        reason: 'Cards outside the viewport must still be released.',
      );
      for (var step = 0; step < 300 && position.pixels > .01; step++) {
        final before = position.pixels;
        await wheel(-120);
        expect(
          position.pixels,
          lessThanOrEqualTo(before + .01),
          reason: 'Upward wheel must not jump downward.',
        );
        final pinned = pinnedGroup();
        expect(pinned, lessThanOrEqualTo(lastPinned));
        lastPinned = pinned;
      }
      expect(position.pixels, closeTo(0, .01));
      expect(lastPinned, 0);
      expect(tester.takeException(), isNull);
    });
  }
}
