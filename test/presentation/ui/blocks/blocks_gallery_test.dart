import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_edit.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_gallery.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_parts.dart';

import '../../../helpers/studio_capture_fonts.dart';
import 'blocks_test_harness.dart';

final _assetRoot = Platform.environment['BLOCK_GALLERY_IMAGE_DIR'];
final _captures = Platform.environment['BLOCK_GALLERY_CAPTURES'];
final _geometry = <String, Object>{};

List<BlockThumb> _images() => [
  for (var i = 0; i < 7; i++)
    BlockThumb(
      _assetRoot == null
          ? blocksTestImage('gallery-$i')
          : MemoryImage(
              File(
                '$_assetRoot/${i == 0 ? 'source.png' : 'gallery-${(i + 1).toString().padLeft(2, '0')}.jpg'}',
              ).readAsBytesSync(),
            ),
      path: 'managed-$i.png',
      offsetY: i == 0 ? -.63 : 0,
    ),
];

Future<void> _ready(WidgetTester tester, List<BlockThumb> images) async {
  await tester.runAsync(() async {
    final context = tester.element(find.byType(Scaffold));
    for (final image in images) {
      await precacheImage(image.image, context);
      for (final size in [38, 44]) {
        unawaited(
          precacheImage(
            blockThumbnailProvider(
              image,
              size.toDouble(),
              MediaQuery.devicePixelRatioOf(context),
            ),
            context,
          ),
        );
      }
    }
  });
  // Codec completions created by a widget run in the fake async zone. Drain
  // that zone while native decoding proceeds before capturing the frame.
  for (
    var frame = 0;
    frame < 200 && PaintingBinding.instance.imageCache.pendingImageCount > 0;
    frame++
  ) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  expect(PaintingBinding.instance.imageCache.pendingImageCount, 0);
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, Finder target, String name) async {
  final output = _captures;
  if (output == null) return;
  final rect = tester.getRect(target);
  final measured = <String, Object>{};
  for (final key in [
    'block-edit-crop',
    'block-edit-range-caption',
    'block-edit-reset-zoom',
    'block-thumbnail-0',
    'block-gallery-viewport',
  ]) {
    final finder = find.descendant(of: target, matching: find.byKey(Key(key)));
    if (finder.evaluate().isEmpty) continue;
    final box = tester.getRect(finder.first).shift(-rect.topLeft);
    measured[key] = [box.left, box.top, box.width, box.height];
  }
  final guide = find.descendant(
    of: target,
    matching: find.byKey(const Key('block-edit-crop-range')),
  );
  if (guide.evaluate().isNotEmpty) {
    final range =
        (tester.widget<CustomPaint>(guide).painter! as BlockPreviewGuidePainter)
            .range;
    measured['range'] = [range.left, range.top, range.width, range.height];
  }
  _geometry[name] = measured;
  final root = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('blocks-capture')),
  );
  final shadows = debugDisableShadows;
  debugDisableShadows = false;
  root.markNeedsPaint();
  await tester.pump();
  try {
    await tester.runAsync(() async {
      final image = await root.toImage();
      final recorder = ui.PictureRecorder();
      Canvas(
        recorder,
      ).drawImageRect(image, rect, Offset.zero & rect.size, Paint());
      final picture = recorder.endRecording();
      final crop = await picture.toImage(rect.width.ceil(), rect.height.ceil());
      final bytes = await crop.toByteData(format: ui.ImageByteFormat.png);
      await Directory(output).create(recursive: true);
      await File('$output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      await File(
        '$output/native-geometry.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(_geometry));
      image.dispose();
      crop.dispose();
      picture.dispose();
    });
  } finally {
    debugDisableShadows = shadows;
    await tester.pump();
  }
}

void main() {
  setUpAll(loadStudioCaptureFonts);

  test('display guides contain the full crop for portrait and wide images', () {
    const editor = Size(294, 210);
    const thumb = BlockThumb(AssetImage('unused'), offsetY: -.63);
    final portrait = blockPreviewRange(
      const Size(832, 1216),
      editor,
      const Size(300, 150),
      thumb,
    );
    expect(portrait.left, closeTo(0, .001));
    expect(portrait.top, closeTo(11.655, .001));
    expect(portrait.size, const Size(294, 147));
    final detail = blockPreviewRange(
      const Size(832, 1216),
      editor,
      const Size(308, 176),
      thumb,
    );
    expect(detail.height, closeTo(168, .001));
    expect(detail.top, closeTo(7.77, .001));
    for (final size in [
      const Size(832, 1216),
      const Size(1216, 832),
      const Size(2400, 800),
    ]) {
      for (final x in [-1.0, 0.0, 1.0]) {
        for (final y in [-1.0, 0.0, 1.0]) {
          for (final zoom in [1.0, 2.0, 3.0]) {
            final range = blockPreviewRange(
              size,
              editor,
              const Size(300, 150),
              thumb.copyWith(offsetX: x, offsetY: y, scale: zoom),
            );
            expect(range.left, greaterThanOrEqualTo(-.001));
            expect(range.top, greaterThanOrEqualTo(-.001));
            expect(range.right, lessThanOrEqualTo(294.001));
            expect(range.bottom, lessThanOrEqualTo(210.001));
          }
        }
      }
    }
    final wide = blockPreviewRange(
      const Size(2400, 800),
      editor,
      const Size(300, 150),
      thumb.copyWith(offsetX: 0, offsetY: 0),
    );
    expect(wide, const Rect.fromLTWH(49, 56, 196, 98));
  });

  testWidgets(
    'editor keeps framing per image, adds many, replaces one and removes one',
    (t) async {
      final images = _images();
      BlockDraft? saved;
      await pumpBlocks(
        t,
        BlockEditDialog(
          data: BlockEditData(
            draft: BlockDraft(
              title: 'SALTY',
              atoms: const ['artist:example'],
              thumb: images.first,
              additionalThumbs: images.skip(1).toList(),
            ),
          ),
          actions: BlockEditActions(
            onSave: (draft) => saved = draft,
            onCancel: () {},
            onPickThumbnail: () async =>
                BlockThumbPick(blocksTestImage('c12'), 'replacement'),
            onPickThumbnails: () async => [
              BlockThumbPick(blocksTestImage('c12'), 'new-a'),
              BlockThumbPick(blocksTestImage('c12'), 'new-b'),
            ],
            onCaptureParams: () async => null,
          ),
        ),
        window: 1200,
        height: 900,
        rail: false,
        dark: true,
      );
      await _ready(t, images);
      expect(find.byKey(const Key('block-edit-crop-range')), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      final crop = find.byKey(const Key('block-edit-crop'));
      final before = t.getRect(crop);
      await t.sendEventToBinding(
        PointerScrollEvent(
          position: before.center,
          scrollDelta: const Offset(0, -120),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('120%'), findsOneWidget);
      expect(
        t.getRect(crop),
        before,
        reason: 'zoom must consume the wheel before the parent editor scrolls',
      );
      await tapKey(t, 'block-thumbnail-1');
      expect(find.text('100%'), findsOneWidget);
      await tapKey(t, 'block-thumbnail-0');
      expect(find.text('120%'), findsOneWidget);
      await t.drag(crop, const Offset(20, 12));
      await t.pumpAndSettle();
      await tapKey(t, 'block-edit-reset-zoom');
      expect(find.text('100%'), findsOneWidget);
      expect(find.byType(Slider), findsNothing);
      final caption = t.getRect(
        find.byKey(const Key('block-edit-range-caption')),
      );
      expect(caption.top, greaterThan(t.getRect(crop).bottom));
      await tapKey(t, 'block-edit-save');
      final framing = saved!.thumb!;
      expect(framing.offsetX, isNot(0));
      expect(framing.offsetY, isNot(images.first.offsetY));
      await _capture(
        t,
        find.byKey(const Key('block-edit-preview-panel')),
        'editor-dark',
      );
      await tapKey(t, 'block-edit-add-thumbnails');
      expect(find.text('8 / 9'), findsOneWidget);
      await tapKey(t, 'block-edit-clear-thumb');
      expect(find.text('8 / 8'), findsOneWidget);
      await tapKey(t, 'block-edit-pick');
      await tapKey(t, 'block-edit-save');
      expect(saved!.thumbs, hasLength(8));
      expect(saved!.thumbs.last.pickToken, 'replacement');
      expect(saved!.thumb!.offsetX, framing.offsetX);
      expect(saved!.thumb!.offsetY, framing.offsetY);
      await tapKey(t, 'block-edit-range-detail');
      await tapKey(t, 'block-edit-show-range');
      expect(find.byKey(const Key('block-edit-crop-range')), findsNothing);
    },
  );

  testWidgets(
    'wide previews keep the guide visible and follow the pan direction',
    (t) async {
      final path = Platform.environment['BLOCK_GALLERY_WIDE_IMAGE'];
      final image = BlockThumb(
        MemoryImage(
          path == null
              ? img.encodePng(img.Image(width: 320, height: 200))
              : File(path).readAsBytesSync(),
        ),
      );
      await pumpBlocks(
        t,
        BlockEditDialog(
          data: BlockEditData(
            draft: BlockDraft(title: 'Wide', atoms: const ['a'], thumb: image),
          ),
          actions: BlockEditActions(
            onSave: (_) {},
            onCancel: () {},
            onPickThumbnail: () async => null,
            onCaptureParams: () async => null,
          ),
        ),
        window: 1200,
        height: 860,
        dark: true,
        rail: false,
      );
      await _ready(t, [image]);
      final crop = find.byKey(const Key('block-edit-crop'));
      final positioned = find.descendant(
        of: crop,
        matching: find.byWidgetPredicate(
          (widget) => widget is Positioned && widget.child is Image,
        ),
      );
      final before = t.widget<Positioned>(positioned).top!;
      await t.drag(crop, const Offset(0, 30));
      await t.pumpAndSettle();
      expect(t.widget<Positioned>(positioned).top!, greaterThan(before));
      final range =
          (t
                      .widget<CustomPaint>(
                        find.byKey(const Key('block-edit-crop-range')),
                      )
                      .painter!
                  as BlockPreviewGuidePainter)
              .range;
      expect(range.top, greaterThanOrEqualTo(0));
      expect(range.bottom, lessThanOrEqualTo(210));
      await _capture(
        t,
        find.byKey(const Key('block-edit-preview-panel')),
        'editor-wide-dark',
      );
    },
  );

  testWidgets(
    'hover arrows switch images then disappear and thumbnail wheel stays horizontal',
    (t) async {
      final images = _images();
      await pumpBlocks(
        t,
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 300,
            child: BlockImageGallery(images: images, height: 150),
          ),
        ),
        window: 900,
        height: 700,
        rail: false,
        dark: true,
      );
      await _ready(t, images);
      final next = find.byKey(const Key('block-gallery-next'));
      double opacity() => t
          .widget<AnimatedOpacity>(
            find
                .ancestor(of: next, matching: find.byType(AnimatedOpacity))
                .first,
          )
          .opacity;
      expect(opacity(), 0);
      final mouse = await hoverOver(t, find.byType(BlockGalleryFrame));
      expect(opacity(), 1);
      await mouse.moveTo(t.getCenter(next));
      await mouse.down(t.getCenter(next));
      await mouse.up();
      await t.pumpAndSettle();
      expect(find.text('2 / 7'), findsOneWidget);
      await mouse.moveTo(const Offset(700, 500));
      await t.pumpAndSettle();
      expect(
        opacity(),
        0,
        reason: 'mouse focus after a click must not keep arrows visible',
      );
      final strip = find.byKey(const Key('block-thumbnail-scroll'));
      await t.sendEventToBinding(
        PointerScrollEvent(
          position: t.getCenter(strip),
          scrollDelta: const Offset(0, 18),
        ),
      );
      await t.pumpAndSettle();
      expect(
        find.byKey(const Key('block-thumbnails-fade-left')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('block-thumbnails-fade-right')),
        findsOneWidget,
      );
      await _capture(t, find.byType(BlockImageGallery), 'gallery-dark');
      await t.pumpWidget(
        blocksApp(
          SizedBox(
            width: 300,
            child: BlockImageGallery(images: [images.first], height: 150),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byType(BlockThumbnailStrip), findsNothing);
      expect(find.byKey(const Key('block-gallery-next')), findsNothing);
    },
  );

  for (final locale in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      testWidgets('gallery editor layout $locale ${dark ? 'dark' : 'light'}', (
        t,
      ) async {
        final images = _images();
        await pumpBlocks(
          t,
          BlockEditDialog(
            data: BlockEditData(
              draft: BlockDraft(
                title: 'SALTY',
                atoms: const ['artist:example'],
                thumb: images.first,
                additionalThumbs: images.skip(1).toList(),
              ),
            ),
            actions: BlockEditActions(
              onSave: (_) {},
              onCancel: () {},
              onPickThumbnail: () async => null,
              onCaptureParams: () async => null,
            ),
          ),
          window: 1200,
          height: 860,
          rail: false,
          dark: dark,
          locale: locale,
        );
        await _ready(t, images);
        expect(t.takeException(), isNull);
        await _capture(
          t,
          find.byKey(const Key('block-edit-preview-panel')),
          'editor-$locale-${dark ? 'dark' : 'light'}',
        );
        await t.pumpWidget(
          blocksApp(
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 300,
                child: BlockHoverCard(
                  BlockData(
                    id: 'capture',
                    title: 'SALTY',
                    color: const Color(0xff607d8b),
                    atoms: const [
                      'artist:shio (shiofeifei)',
                      '1.2::omochi monaka::',
                      'rucaco',
                      'nakkar',
                    ],
                    thumb: images.first,
                    additionalThumbs: images.skip(1).toList(),
                    createdAt: DateTime(2026),
                    updatedAt: DateTime(2026),
                  ),
                ),
              ),
            ),
            dark: dark,
            locale: locale,
          ),
        );
        await t.pumpAndSettle();
        await _capture(
          t,
          find.byKey(const Key('block-hover-card')),
          'hover-$locale-${dark ? 'dark' : 'light'}',
        );
        expect(t.takeException(), isNull);
      });
    }
  }
}
