import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/screens/slideshow_screen.dart';

void main() {
  test('slideshow image provider caps decode size', () {
    final provider = buildSlideshowImageProvider('C:\\tmp\\slide.png');

    expect(provider, isA<ResizeImage>());
    final resized = provider as ResizeImage;
    expect(resized.width, 4096);
    expect(resized.height, 4096);
    expect(resized.policy, ResizeImagePolicy.fit);
  });

  testWidgets('empty slideshow handles a deep link without photos', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const SlideshowScreen(images: [], initialIndex: 7)),
    );
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
  });

  testWidgets('autoplay advances more than once and a manual step pauses it', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SlideshowScreen(
          images: [
            for (var i = 0; i < 3; i++)
              LocalImageRecord(
                path: 'slide-$i.png',
                size: 1,
                modifiedAt: DateTime(2026),
              ),
          ],
        ),
      ),
    );
    final l = AppLocalizations.of(
      tester.element(find.byType(SlideshowScreen)),
    )!;
    await tester.tap(find.byIcon(Icons.play_arrow));
    for (final number in [2, 3, 1]) {
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('$number ${l.slideshow_of} 3'), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);
    }
    await tester.tap(find.byIcon(Icons.arrow_back_ios));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('3 ${l.slideshow_of} 3'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets(
    'updating a shorter list clamps the index and empty playback stops',
    (tester) async {
      final image = LocalImageRecord(
        path: 'slide.png',
        size: 1,
        modifiedAt: DateTime(2026),
      );
      await tester.pumpWidget(
        _wrap(SlideshowScreen(images: [image, image], initialIndex: 1)),
      );
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpWidget(
        _wrap(SlideshowScreen(images: [image], initialIndex: 1)),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(_wrap(const SlideshowScreen(images: [])));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpWidget(_wrap(SlideshowScreen(images: [image])));
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    },
  );

  testWidgets('dispose does not call setState', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SlideshowScreen(
          images: [
            LocalImageRecord(
              path: 'C:\\tmp\\missing_slide.png',
              size: 1,
              modifiedAt: DateTime(2026),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}
