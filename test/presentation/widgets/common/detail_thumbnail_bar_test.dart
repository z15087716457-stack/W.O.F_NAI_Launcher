import 'dart:typed_data';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/presentation/widgets/common/image_detail/components/viewer_filmstrip.dart';
import 'package:nai_launcher/presentation/widgets/common/image_detail/image_detail_data.dart';
import '../library/library_test_helpers.dart';

void main() {
  testWidgets('thumbnail bar does not compose ResizeImage providers', (
    tester,
  ) async {
    final sourceProvider = MemoryImage(Uint8List.fromList(const [1]));
    final data = _TestImageDetailData(
      ResizeImage(ResizeImage(sourceProvider, width: 4096), height: 4096),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ViewerFilmstrip(
          items: [ViewerFilmstripItem(thumbnail: data.getImageProvider())],
          currentIndex: 0,
          scrollController: ScrollController(),
          onTap: (_) {},
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final thumbnailProvider = image.image as ResizeImage;

    expect(thumbnailProvider.height, 120);
    expect(thumbnailProvider.width, isNull);
    expect(thumbnailProvider.imageProvider, same(sourceProvider));
    expect(thumbnailProvider.imageProvider, isNot(isA<ResizeImage>()));
  });

  testWidgets('landscape is wider; current thumbnail is 60 and others are 52', (
    tester,
  ) async {
    await pumpLibrary(
      tester,
      ViewerFilmstrip(
        items: const [
          ViewerFilmstripItem(aspectRatio: 2),
          ViewerFilmstripItem(aspectRatio: .5),
        ],
        currentIndex: 0,
        onTap: (_) {},
      ),
    );
    final wide = tester.getSize(
      find.byKey(const Key('viewer-filmstrip-item-0')),
    );
    final tall = tester.getSize(
      find.byKey(const Key('viewer-filmstrip-item-1')),
    );
    expect(wide, const Size(120, 60));
    expect(tall, const Size(26, 52));
  });
  testWidgets(
    'adjacent days insert localized separators; generated batch has none',
    (tester) async {
      final items = [
        ViewerFilmstripItem(groupDate: DateTime(2026, 8, 31, 2)),
        ViewerFilmstripItem(groupDate: DateTime(2026, 8, 31, 18)),
        ViewerFilmstripItem(groupDate: DateTime(2026, 9, 1)),
      ];
      for (final language in ['zh', 'en', 'ja', 'ko']) {
        await pumpLibrary(
          tester,
          ViewerFilmstrip(items: items, currentIndex: 1, onTap: (_) {}),
          language: language,
        );
        expect(
          find.byKey(const Key('viewer-filmstrip-date-0')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('viewer-filmstrip-date-1')), findsNothing);
        expect(
          find.byKey(const Key('viewer-filmstrip-date-2')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
      await pumpLibrary(
        tester,
        ViewerFilmstrip(
          items: const [ViewerFilmstripItem(), ViewerFilmstripItem()],
          currentIndex: 0,
          onTap: (_) {},
        ),
      );
      expect(find.byKey(const Key('viewer-filmstrip-date-0')), findsNothing);
      expect(find.byKey(const Key('viewer-filmstrip-date-1')), findsNothing);
    },
  );
  testWidgets('click jumps; hovering changes opacity without changing size', (
    tester,
  ) async {
    var clicked = -1;
    await pumpLibrary(
      tester,
      ViewerFilmstrip(
        items: const [ViewerFilmstripItem(), ViewerFilmstripItem()],
        currentIndex: 0,
        onTap: (i) => clicked = i,
      ),
    );
    final item = find.byKey(const Key('viewer-filmstrip-item-1'));
    final before = tester.getSize(item);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(item));
    await tester.pumpAndSettle();
    final opacity = tester.widget<AnimatedOpacity>(
      find.descendant(of: item, matching: find.byType(AnimatedOpacity)),
    );
    expect(opacity.opacity, .85);
    expect(tester.getSize(item), before);
    await tester.tap(item);
    expect(clicked, 1);
    await mouse.removePointer();
  });
  testWidgets(
    'mixed widths and date labels center current item after appending',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      List<ViewerFilmstripItem> items(int count) => [
        for (var i = 0; i < count; i++)
          ViewerFilmstripItem(
            aspectRatio: i.isEven ? 2 : .5,
            groupDate: DateTime(2026, 8, 31 - i ~/ 10),
          ),
      ];
      Future<void> show(int count, int index) => pumpLibrary(
        tester,
        ViewerFilmstrip(
          items: items(count),
          currentIndex: index,
          scrollController: controller,
          onTap: (_) {},
        ),
        size: const Size(480, 200),
      );
      await show(40, 20);
      expect(
        tester.getCenter(find.byKey(const Key('viewer-filmstrip-item-20'))).dx,
        closeTo(240, 1),
      );
      await show(60, 45);
      expect(
        tester.getCenter(find.byKey(const Key('viewer-filmstrip-item-45'))).dx,
        closeTo(240, 1),
      );
      await show(60, 59);
      expect(
        tester.getRect(find.byKey(const Key('viewer-filmstrip-item-59'))).right,
        lessThanOrEqualTo(480),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('null, invalid and extreme ratios stay bounded', (tester) async {
    await pumpLibrary(
      tester,
      ViewerFilmstrip(
        items: const [
          ViewerFilmstripItem(),
          ViewerFilmstripItem(aspectRatio: double.nan),
          ViewerFilmstripItem(aspectRatio: 100),
          ViewerFilmstripItem(aspectRatio: .01),
        ],
        currentIndex: 0,
        onTap: (_) {},
      ),
    );
    Size size(int i) =>
        tester.getSize(find.byKey(Key('viewer-filmstrip-item-$i')));
    expect(size(0), const Size(60, 60));
    expect(size(1), const Size(52, 52));
    expect(size(2), const Size(130, 52));
    expect(size(3), const Size(21, 52));
  });
}

class _TestImageDetailData implements ImageDetailData {
  _TestImageDetailData(this.provider);

  final ImageProvider<Object> provider;

  @override
  ImageProvider<Object> getImageProvider() => provider;

  @override
  Future<Uint8List> getImageBytes() async => Uint8List(0);

  @override
  NaiImageMetadata? get metadata => null;

  @override
  double? get aspectRatio => null;

  @override
  DateTime? get groupDate => null;

  @override
  bool get isFavorite => false;

  @override
  String get identifier => 'test';

  @override
  FileInfo? get fileInfo => null;

  @override
  bool get showSaveButton => false;

  @override
  bool get showCopyButton => false;

  @override
  bool get showFavoriteButton => false;
}
