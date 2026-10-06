import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_feed_layout.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_tile_toolbar.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/generation_canvas_controller.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/generation_canvas_view.dart';

final _png = Uint8List.fromList(img.encodePng(img.Image(width: 1, height: 1)));

GeneratedImage _image(int run, {int index = 0}) => GeneratedImage(
  id: '$run:$index',
  bytes: _png,
  width: 512,
  height: 768,
  createdAt: DateTime(2026, 9, 21).add(Duration(seconds: run)),
  generationRunId: run,
  batchIndex: index,
);

ImageGenerationState _loading(
  int run, {
  List<GeneratedImage> history = const [],
  int count = 1,
  List<StreamPreviewSlot> slots = const [],
}) => ImageGenerationState(
  generationRunId: run,
  status: GenerationStatus.generating,
  history: history,
  totalImages: count,
  currentImage: 1,
  batchWidth: 512,
  batchHeight: 768,
  streamPreviewSlots: slots,
);

class _Generation extends ImageGenerationNotifier {
  _Generation(this.initial);
  final ImageGenerationState initial;

  @override
  ImageGenerationState build() => initial;

  void publish(ImageGenerationState next) => state = next;
}

class _Storage extends LocalStorageService {
  @override
  bool getCanvasLockCamera() => false;
  @override
  bool getCanvasReducedMotion() => true;
  @override
  Set<String> getCanvasPinnedImages() => {};
}

class _Camera extends GenerationCanvasCameraNotifier {
  final targets = <CanvasCamera>[];

  @override
  void flyTo(
    CanvasCamera target, {
    bool fitInsideViewport = false,
    double speed = 11,
    Duration duration = const Duration(milliseconds: 500),
    VoidCallback? onDone,
  }) {
    targets.add(target);
    super.flyTo(
      target,
      fitInsideViewport: fitInsideViewport,
      speed: speed,
      duration: duration,
      onDone: onDone,
    );
  }
}

ProviderContainer _container(ImageGenerationState initial) => ProviderContainer(
  overrides: [
    imageGenerationNotifierProvider.overrideWith(() => _Generation(initial)),
    localStorageServiceProvider.overrideWith((ref) => _Storage()),
    estimatedCostProvider.overrideWithValue(7),
    generationCanvasCameraProvider.overrideWith(_Camera.new),
  ],
);

void _publish(ProviderContainer container, ImageGenerationState next) =>
    (container.read(imageGenerationNotifierProvider.notifier) as _Generation)
        .publish(next);

Rect _rect(ProviderContainer container, int run, {int index = 0}) => container
    .read(canvasFeedLayoutProvider)
    .items
    .firstWhere((it) => it.group.key == 'run:$run' && it.subimageIndex == index)
    .worldRect;

Future<void> _mount(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => GenerationCanvasView(
              generationState: ref.watch(imageGenerationNotifierProvider),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  test(
    'placeholder, stream and final share geometry; next run is above it',
    () {
      final old = _image(1);
      final container = _container(
        ImageGenerationState(currentImages: [old], history: [old]),
      );
      addTearDown(container.dispose);
      final oldRect = _rect(container, 1);

      final loading = _loading(2, history: [old]);
      _publish(container, loading);
      final placeholder = _rect(container, 2);
      expect(placeholder.size, const Size(512, 768));
      expect(placeholder.bottom + kCanvasGroupSpacing, oldRect.top);
      expect(_rect(container, 1), oldRect);
      expect(
        container.read(canvasFeedLayoutProvider).groups.first.isInFlight,
        true,
      );

      _publish(container, loading.copyWith(streamPreview: _png, progress: 0.4));
      expect(_rect(container, 2), placeholder);
      expect(
        container
            .read(canvasFeedLayoutProvider)
            .items
            .first
            .tile
            .slot!
            .previewBytes,
        same(_png),
      );

      final done = _image(2);
      _publish(
        container,
        loading.copyWith(
          status: GenerationStatus.completed,
          currentImages: [done],
          history: [done, old],
          totalImages: 0,
          clearStreamPreview: true,
        ),
      );
      expect(_rect(container, 2), placeholder);
      expect(_rect(container, 1), oldRect);
      expect(
        container.read(canvasFeedLayoutProvider).groups.first.isInFlight,
        false,
      );

      _publish(container, _loading(3, history: [done, old]));
      expect(_rect(container, 3).bottom + kCanvasGroupSpacing, placeholder.top);
      expect(_rect(container, 2), placeholder);
      expect(_rect(container, 1), oldRect);
    },
  );

  test(
    'all batch slots exist before a stream; partial results keep their index',
    () {
      final old = _image(1);
      final container = _container(ImageGenerationState(history: [old]));
      addTearDown(container.dispose);
      final oldRect = _rect(container, 1);
      final loading = _loading(2, history: [old], count: 4);
      // Explore retains an older current image while preparing its request.
      _publish(container, loading.copyWith(currentImages: [old]));
      final layout = container.read(canvasFeedLayoutProvider);
      expect(layout.groups.length, 2);
      expect(layout.groups.first.tiles.length, 4);
      expect(layout.groups.first.images, isEmpty);
      final rects = [for (var i = 0; i < 4; i++) _rect(container, 2, index: i)];

      final third = _image(2, index: 2);
      _publish(container, loading.copyWith(currentImages: [third]));
      final group = container.read(canvasFeedLayoutProvider).groups.first;
      expect(group.tiles[2].image, same(third));
      expect(group.tiles[0].slot!.imageNumber, 1);
      expect(group.tiles[1].slot!.imageNumber, 2);
      expect(group.tiles[3].slot!.imageNumber, 4);
      expect([
        for (var i = 0; i < 4; i++) _rect(container, 2, index: i),
      ], rects);
      expect(_rect(container, 1), oldRect);

      _publish(
        container,
        loading.copyWith(status: GenerationStatus.cancelled, totalImages: 0),
      );
      expect(
        container.read(canvasFeedLayoutProvider).groups.single.key,
        'run:1',
      );
      expect(_rect(container, 1), oldRect);
    },
  );

  testWidgets(
    'click lifecycle focuses loading now, streams in place, and flies once per run',
    (tester) async {
      final old = _image(1);
      final container = _container(ImageGenerationState(history: [old]));
      addTearDown(container.dispose);
      await _mount(tester, container);
      final camera =
          container.read(generationCanvasCameraProvider.notifier) as _Camera;
      expect(camera.targets.length, 1);
      final oldCenter = container
          .read(generationCanvasCameraProvider)
          .screenToWorld(tester.getCenter(find.byType(GenerationCanvasView)));
      final bars =
          tester
              .elementList(find.byType(CanvasEdgeToolbar))
              .map((e) => tester.getRect(find.byWidget(e.widget)))
              .toList()
            ..sort((a, b) => a.top.compareTo(b.top));
      final safeCenter = Offset(
        tester.getCenter(find.byType(GenerationCanvasView)).dx,
        (bars.first.bottom + bars[1].top) / 2,
      );

      final loading = _loading(2, history: [old]);
      _publish(container, loading);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        container.read(generationCanvasGroupSelectionProvider)?.group,
        'run:2',
      );
      expect(camera.targets.length, 2);
      final position = container.read(generationCanvasCameraProvider);
      final newCenter = position.screenToWorld(safeCenter);
      expect(newCenter.dy, lessThan(oldCenter.dy));
      expect((newCenter - _rect(container, 2).center).distance, lessThan(0.01));
      // 占位卡显示一句等待小贴士，流式帧到来后保持同一句
      final waitTip = find.byKey(const Key('canvas-inflight-tip'));
      expect(waitTip, findsOneWidget);
      final waitText = tester.widget<Text>(waitTip).data;
      final tile = find.byKey(const ValueKey('canvas-tile:run:2:0'));
      final screenRect = tester.getRect(tile);

      _publish(
        container,
        loading.copyWith(
          streamPreviewSlots: [
            StreamPreviewSlot(
              imageNumber: 1,
              totalImages: 1,
              progress: 0.4,
              previewBytes: _png,
            ),
          ],
        ),
      );
      await tester.pump();
      expect(tester.widget<Text>(waitTip).data, waitText);
      final preview = tester.widget<Image>(
        find.descendant(of: tile, matching: find.byType(Image)).first,
      );
      final provider = preview.image is ResizeImage
          ? (preview.image as ResizeImage).imageProvider
          : preview.image;
      expect((provider as MemoryImage).bytes, same(_png));
      expect(tester.getRect(tile), screenRect);
      expect(camera.targets.length, 2);

      final done = _image(2);
      _publish(
        container,
        loading.copyWith(
          status: GenerationStatus.completed,
          currentImages: [done],
          history: [done, old],
          totalImages: 0,
          clearStreamPreview: true,
        ),
      );
      await tester.pump();
      expect(tester.getRect(tile), screenRect);
      expect(camera.targets.length, 2);
      expect(container.read(generationPreviewSelectionProvider), done.id);

      _publish(container, _loading(3, history: [done, old]));
      await tester.pump();
      expect(camera.targets.length, 3);
      expect(
        container.read(generationCanvasGroupSelectionProvider)?.group,
        'run:3',
      );
      expect(tester.takeException(), isNull);
      await _unmount(tester);
    },
  );

  testWidgets(
    'first generation focuses when mounted empty or already loading',
    (tester) async {
      for (final initiallyLoading in [false, true]) {
        final container = _container(
          initiallyLoading ? _loading(1) : const ImageGenerationState(),
        );
        await _mount(tester, container);
        if (!initiallyLoading) {
          _publish(container, _loading(1));
          await tester.pump();
        }
        final camera =
            container.read(generationCanvasCameraProvider.notifier) as _Camera;
        expect(camera.targets.length, 1);
        expect(
          container.read(generationCanvasGroupSelectionProvider)?.group,
          'run:1',
        );
        final center = tester.getCenter(find.byType(GenerationCanvasView));
        expect(
          (container
                      .read(generationCanvasCameraProvider)
                      .screenToWorld(center) -
                  _rect(container, 1).center)
              .distance,
          lessThan(0.01),
        );
        expect(tester.takeException(), isNull);
        await _unmount(tester);
        container.dispose();
      }
    },
  );

  testWidgets('completion respects a history selection made while waiting', (
    tester,
  ) async {
    final old = _image(1);
    final container = _container(ImageGenerationState(history: [old]));
    addTearDown(container.dispose);
    await _mount(tester, container);
    final loading = _loading(2, history: [old]);
    _publish(container, loading);
    await tester.pump();
    container.read(generationPreviewSelectionProvider.notifier).select(old.id);
    await tester.pump();
    final camera =
        container.read(generationCanvasCameraProvider.notifier) as _Camera;
    final flights = camera.targets.length;
    final done = _image(2);
    _publish(
      container,
      loading.copyWith(
        status: GenerationStatus.completed,
        currentImages: [done],
        history: [done, old],
      ),
    );
    await tester.pump();
    expect(camera.targets.length, flights);
    expect(
      container.read(generationCanvasGroupSelectionProvider)?.group,
      'run:1',
    );
    expect(container.read(generationPreviewSelectionProvider), old.id);
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });
}
