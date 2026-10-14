import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_dock.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'blocks_test_harness.dart';

BlockData _block(String id, {bool image = false, bool many = false}) =>
    BlockData(
      id: id,
      title: many ? '艺术家：示例，抓拍，2025年，极具美感' : 'visual novel art',
      color: const Color(0xFF607D8B),
      atoms: many
          ? List.generate(11, (i) => 'example content $i')
          : const ['visual novel art'],
      thumb: image ? BlockThumb(blocksTestImage('c12')) : null,
      createdAt: DateTime(2026, 10, 14),
      updatedAt: DateTime(2026, 10, 14),
    );

BlocksDockGroup _group(
  String id,
  List<BlockData> blocks, {
  bool expanded = true,
}) => BlocksDockGroup(
  id: id,
  name: id,
  count: blocks.length,
  blocks: blocks,
  expanded: expanded,
);

void main() {
  setUpAll(loadStudioCaptureFonts);
  late RecordingBlocks rec;
  setUp(() => rec = RecordingBlocks());

  Future<void> pump(
    WidgetTester tester,
    BlocksDockViewData data, {
    double top = 0,
    double width = 300,
    double height = 1000,
    bool dark = false,
    String locale = 'zh',
  }) => pumpBlocks(
    tester,
    Padding(
      padding: EdgeInsets.only(left: 48, top: top),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: width,
            child: BlocksDock(data: data, actions: rec.dock),
          ),
          const Spacer(),
        ],
      ),
    ),
    window: 1000,
    height: height,
    dark: dark,
    locale: locale,
    rail: false,
  );

  Future<void> capture(WidgetTester tester, String name) async {
    if (Platform.environment['CAPTURE_BLOCKS_DOCK'] != '1') return;
    debugDisableShadows = false;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('blocks-capture')),
    );
    boundary.markNeedsPaint();
    await tester.pump();
    try {
      await tester.runAsync(() async {
        final box = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('blocks-capture')),
        );
        final image = await box.toImage();
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        final file = File('.dart_tool/blocks-dock-20261014/captures/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes.buffer.asUint8List());
        image.dispose();
      });
    } finally {
      debugDisableShadows = true;
    }
  }

  for (final dark in [false, true]) {
    for (final (name, image, many) in [
      ('short', false, false),
      ('many', false, true),
      ('thumbnail', true, true),
    ]) {
      testWidgets(
        'preview uses actual height and joins both centers $name $dark',
        (tester) async {
          final block = _block(name, image: image, many: many);
          await pump(
            tester,
            BlocksDockViewData(
              total: 1,
              groups: [
                _group('group', [block]),
              ],
            ),
            top: 260,
            dark: dark,
          );
          final pill = find.byKey(Key('dock-pill-$name'));
          await hoverOver(tester, pill);
          await tester.pump(const Duration(milliseconds: 200));
          await tester.pumpAndSettle();
          final card = tester.getRect(
            find.byKey(const Key('block-hover-card')),
          );
          final anchor = tester.getRect(pill);
          expect(card.center.dy, closeTo(anchor.center.dy, .1));
          expect(card.left, closeTo(358, .1));
          final connector = find.byKey(const Key('dock-preview-connector'));
          final painter =
              tester.widget<CustomPaint>(connector).painter as dynamic;
          final origin = tester.getTopLeft(connector);
          expect(origin + (painter.start as Offset), anchor.centerRight);
          expect(origin + (painter.end as Offset), card.centerLeft);
          await capture(tester, '$name-${dark ? 'dark' : 'light'}');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'switching between different card heights never reuses the old anchor',
    (tester) async {
      final short = _block('short');
      final tall = _block('tall', image: true, many: true);
      await pump(
        tester,
        BlocksDockViewData(
          total: 2,
          groups: [
            _group('short', [short]),
            _group('tall', [tall]),
          ],
        ),
        top: 260,
      );
      final mouse = await hoverOver(
        tester,
        find.byKey(const Key('dock-pill-short')),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      final first = tester.getRect(find.byKey(const Key('block-hover-card')));
      await mouse.moveTo(
        tester.getCenter(find.byKey(const Key('dock-pill-tall'))),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      final second = tester.getRect(find.byKey(const Key('block-hover-card')));
      expect(second.height, greaterThan(first.height));
      expect(
        second.center.dy,
        closeTo(
          tester.getCenter(find.byKey(const Key('dock-pill-tall'))).dy,
          .1,
        ),
      );
    },
  );

  testWidgets(
    'a tall preview near the top stays visible and the line ends at its center',
    (tester) async {
      final b = _block('tall', image: true, many: true);
      await pump(
        tester,
        BlocksDockViewData(
          total: 1,
          groups: [
            _group('group', [b]),
          ],
        ),
        height: 600,
      );
      await hoverOver(tester, find.byKey(const Key('dock-pill-tall')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      final card = tester.getRect(find.byKey(const Key('block-hover-card')));
      expect(card.top, greaterThanOrEqualTo(8));
      expect(card.bottom, lessThanOrEqualTo(592));
      final connector = find.byKey(const Key('dock-preview-connector'));
      final painter = tester.widget<CustomPaint>(connector).painter as dynamic;
      expect(
        tester.getTopLeft(connector) + (painter.end as Offset),
        card.centerLeft,
      );
      await capture(tester, 'preview-top-edge');
    },
  );

  testWidgets(
    'content groups precede empty groups while preserving order and collapse state',
    (tester) async {
      final input = [
        _group('empty-a', []),
        _group('content-a', [_block('a')], expanded: false),
        _group('empty-b', []),
        _group('content-b', [_block('b')]),
      ];
      await pump(tester, BlocksDockViewData(total: 2, groups: input));
      final ids = ['content-a', 'content-b', 'empty-a', 'empty-b'];
      final tops = [
        for (final id in ids)
          tester.getTopLeft(find.byKey(Key('dock-group-$id'))).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
      expect(find.byKey(const Key('dock-pill-a')), findsNothing);
      expect(input.map((g) => g.id), [
        'empty-a',
        'content-a',
        'empty-b',
        'content-b',
      ]);
      await capture(tester, 'groups-nonempty-first');
    },
  );

  testWidgets(
    'vertical wheel slides chips both ways and never moves All or the body',
    (tester) async {
      await pump(
        tester,
        BlocksDockViewData(
          total: 40,
          chips: [
            for (var i = 0; i < 20; i++)
              BlocksDockChip(id: 'c$i', name: 'Category $i', count: 2),
          ],
          groups: [
            for (var i = 0; i < 40; i++) _group('g$i', [_block('b$i')]),
          ],
        ),
      );
      final scroll = tester
          .widget<SingleChildScrollView>(
            find.byKey(const Key('dock-chips-scroll')),
          )
          .controller!;
      final bodyFinder = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      );
      final body = tester.state<ScrollableState>(bodyFinder.first).position;
      final all = tester.getRect(find.byKey(const Key('dock-chip-all')));
      final divider = tester.getRect(
        find.byKey(const Key('dock-chips-divider')),
      );
      final point = tester.getCenter(
        find.byKey(const Key('dock-chips-scroll')),
      );
      for (final delta in [
        const Offset(0, 120),
        const Offset(80, 0),
        const Offset(0, -60),
      ]) {
        final before = scroll.offset;
        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: point,
            scrollDelta: delta,
            kind: PointerDeviceKind.mouse,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          scroll.offset,
          closeTo(before + (delta.dx == 0 ? delta.dy : delta.dx), .1),
        );
        expect(body.pixels, 0);
        expect(tester.getRect(find.byKey(const Key('dock-chip-all'))), all);
        expect(
          tester.getRect(find.byKey(const Key('dock-chips-divider'))),
          divider,
        );
      }
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: point,
          scrollDelta: const Offset(0, 10000),
        ),
      );
      await tester.pumpAndSettle();
      expect(scroll.offset, scroll.position.maxScrollExtent);
      await tester.tap(find.byKey(const Key('dock-chip-all')));
      expect(rec.calls.last, 'dock.filter:false:null');
      await capture(tester, 'chips-scrolled-to-end');
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: point,
          scrollDelta: const Offset(0, -10000),
        ),
      );
      await tester.pumpAndSettle();
      expect(scroll.offset, 0);
    },
  );

  testWidgets('scrolling the block list dismisses the old hover connector', (
    tester,
  ) async {
    await pump(
      tester,
      BlocksDockViewData(
        total: 30,
        groups: [
          for (var i = 0; i < 30; i++) _group('g$i', [_block('b$i')]),
        ],
      ),
      height: 600,
    );
    final pill = find.byKey(const Key('dock-pill-b0'));
    await hoverOver(tester, pill);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('block-hover-card')), findsOneWidget);
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(pill),
        scrollDelta: const Offset(0, 80),
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('block-hover-card')), findsNothing);
    expect(find.byKey(const Key('dock-preview-connector')), findsNothing);
  });

  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      testWidgets('fixed All and divider fit a narrow sidebar $locale $dark', (
        tester,
      ) async {
        await pump(
          tester,
          BlocksDockViewData(
            total: 1,
            chips: const [
              BlocksDockChip(id: 'empty', name: 'Empty category', count: 0),
              BlocksDockChip(id: 'full', name: 'Full category', count: 1),
            ],
            groups: [
              _group('full', [_block('a')]),
            ],
          ),
          width: 300,
          locale: locale,
          dark: dark,
        );
        expect(
          tester.getRect(find.byKey(const Key('dock-chip-all'))).right,
          lessThan(
            tester.getRect(find.byKey(const Key('dock-chips-divider'))).left,
          ),
        );
        expect(
          tester.getTopLeft(find.byKey(const Key('dock-chip-full'))).dx,
          lessThan(
            tester.getTopLeft(find.byKey(const Key('dock-chip-empty'))).dx,
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
