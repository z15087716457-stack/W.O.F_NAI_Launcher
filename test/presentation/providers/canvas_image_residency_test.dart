// Flutter's test clock dependency; no additional runtime dependency.
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/services/app_visibility.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/services/canvas_pin_repository.dart';
import 'package:nai_launcher/presentation/providers/canvas_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/canvas_image_residency_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_feed_layout.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/generation_canvas_controller.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_preview_image.dart';
import 'package:nai_launcher/presentation/widgets/common/app_visibility_scope.dart';
import 'package:nai_launcher/presentation/wiring/generation_canvas_wiring.dart';
import 'package:nai_launcher/presentation/wiring/generation_history_actions.dart';

import '../../helpers/app_image_cache_test_binding.dart';
import '../../helpers/app_logger_test_isolation.dart';

class _Memory extends LocalStorageService {
  @override
  T? getSetting<T>(String key, {T? defaultValue}) => defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {}
}

class _Generation extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();
  void publish(ImageGenerationState value) => state = value;
}

/// The canvas only differs by screen density: a Retina Mac shows two
/// physical pixels per point, a Windows display at 100% one.
class _Display {
  const _Display(this.name, this.ratio);
  final String name;
  final double ratio;
  @override
  String toString() => name;
}

const _mac = _Display('macOS Retina (2x)', 2);
const _windows = _Display('Windows 100% (1x)', 1);
final _displays = ValueVariant<_Display>({_mac, _windows});

const _native = Size(320, 480);
final _start = DateTime(2026, 10, 30, 12);

GeneratedImage _image(String id, Uint8List bytes) => GeneratedImage(
  id: id,
  bytes: bytes,
  width: _native.width.toInt(),
  height: _native.height.toInt(),
);

void main() {
  // The app's image cache, as in the app.
  AppImageCacheTestBinding();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);

  group('which images keep full resolution', () {
    late ProviderContainer container;
    late _Generation generation;
    late DateTime now;
    final bytes = Uint8List(0);
    CanvasImageResidency residency() =>
        container.read(canvasImageResidencyProvider);
    CanvasImageResidencyNotifier notifier() =>
        container.read(canvasImageResidencyProvider.notifier);
    void select(String? id) {
      final selection = container.read(
        generationPreviewSelectionProvider.notifier,
      );
      id == null ? selection.clear() : selection.select(id);
    }

    setUp(() {
      now = _start;
      generation = _Generation();
      container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(_Memory()),
          imageGenerationNotifierProvider.overrideWith(() => generation),
          canvasResidencyClockProvider.overrideWithValue(() => now),
        ],
      );
      container.read(imageGenerationNotifierProvider);
    });
    tearDown(() => container.dispose());

    List<GeneratedImage> images(String prefix, int count) => [
      for (var i = 0; i < count; i++) _image('$prefix$i', bytes),
    ];

    test('the ten newest: the current batch first, then history', () {
      generation.publish(
        ImageGenerationState(
          currentImages: images('c', 2),
          history: images('h', 14),
        ),
      );
      final recent = residency().recent;
      expect(recent, {'c0', 'c1', for (var i = 0; i < 8; i++) 'h$i'});
      expect(residency().keepsFullResolution('h7'), isTrue);
      expect(residency().keepsFullResolution('h8'), isFalse);
    });

    Uint8List png(int seed) => Uint8List.fromList(
      img.encodePng(
        img.Image(width: 8, height: 12)..clear(img.ColorRgb8(seed, 40, 90)),
      ),
    );

    // Agreed on 2026-10-31: an image put on the canvas (a file, the gallery,
    // img2img) is usually the one about to be worked on, so it counts as one
    // of the newest and keeps its full decode like a generated one.
    test('an image put on the canvas is one of the newest', () {
      generation.publish(ImageGenerationState(history: images('h', 14)));
      final placed = generation.registerSourceImage(png(1))!;
      expect(
        container.read(imageGenerationNotifierProvider).currentImages.first,
        placed,
      );
      expect(residency().recent, {
        placed.id,
        for (var i = 0; i < 9; i++) 'h$i',
      });
      expect(residency().keepsFullResolution(placed.id), isTrue);
      expect(residency().keepsFullResolution('h9'), isFalse);
    });

    test('putting an older image on the canvas again makes it one of the '
        'newest', () {
      // The same bytes reuse the tile, which placing moves to the front of
      // the current images.
      final older = GeneratedImage(
        id: 'h12',
        bytes: png(2),
        width: 8,
        height: 12,
        generationRunId: 1,
      );
      final batch = [
        for (var i = 0; i < 4; i++)
          GeneratedImage(
            id: 'n$i',
            bytes: bytes,
            width: 8,
            height: 12,
            generationRunId: 3,
          ),
      ];
      generation.publish(
        ImageGenerationState(
          generationRunId: 3,
          currentImages: batch,
          history: [
            ...batch,
            for (final image in images('h', 14))
              image.id == 'h12' ? older : image,
          ],
        ),
      );
      expect(generation.registerSourceImage(png(2)), same(older));
      expect(
        container.read(imageGenerationNotifierProvider).currentImages.first,
        older,
      );
      expect(residency().recent, hasLength(10));
      expect(residency().recent, containsAll(['h12', 'n0', 'n3']));
      expect(residency().keepsFullResolution('h12'), isTrue);
    });

    test('a new batch pushes the oldest out of the newest ten', () {
      final old = images('h', 10);
      generation.publish(ImageGenerationState(history: old));
      expect(residency().recent, old.map((i) => i.id).toSet());
      generation.publish(
        ImageGenerationState(history: [...images('n', 4), ...old]),
      );
      expect(residency().recent, containsAll(['n0', 'n3', 'h0', 'h5']));
      for (final id in ['h6', 'h7', 'h8', 'h9']) {
        expect(residency().keepsFullResolution(id), isFalse, reason: id);
      }
    });

    test('the selection keeps it, then five more minutes after moving on', () {
      fakeAsync((async) {
        generation.publish(ImageGenerationState(history: images('h', 20)));
        notifier().attach();
        select('h15');
        expect(residency().keepsFullResolution('h15'), isTrue);
        now = now.add(const Duration(minutes: 1));
        select('h16');
        expect(residency().selected, 'h16');
        expect(residency().keepsFullResolution('h15'), isTrue);

        now = now.add(const Duration(minutes: 4, seconds: 59));
        async.elapse(const Duration(minutes: 4, seconds: 59));
        expect(residency().keepsFullResolution('h15'), isTrue);
        now = now.add(const Duration(seconds: 1));
        async.elapse(const Duration(seconds: 1));
        expect(residency().keepsFullResolution('h15'), isFalse);
        expect(residency().keepsFullResolution('h16'), isTrue, reason: 'sel');
        notifier().detach();
      });
    });

    test('looking again restarts the five minutes', () {
      fakeAsync((async) {
        generation.publish(ImageGenerationState(history: images('h', 20)));
        notifier()
          ..attach()
          ..markViewed('h12');
        now = now.add(const Duration(minutes: 3));
        async.elapse(const Duration(minutes: 3));
        notifier().markViewed('h12');
        now = now.add(const Duration(minutes: 4));
        async.elapse(const Duration(minutes: 4));
        expect(residency().keepsFullResolution('h12'), isTrue);
        now = now.add(const Duration(minutes: 1));
        async.elapse(const Duration(minutes: 1));
        expect(residency().keepsFullResolution('h12'), isFalse);
        notifier().detach();
      });
    });

    test('at most ten looked-at images, the oldest dropped first', () {
      generation.publish(ImageGenerationState(history: images('h', 40)));
      for (var i = 10; i < 25; i++) {
        now = now.add(const Duration(seconds: 1));
        notifier().markViewed('h$i');
      }
      expect(residency().viewed.keys, [for (var i = 15; i < 25; i++) 'h$i']);
      expect(residency().keepsFullResolution('h14'), isFalse);
    });

    test('never more full-resolution images than the cap', () {
      generation.publish(ImageGenerationState(history: images('h', 60)));
      for (var i = 0; i < 60; i++) {
        now = now.add(const Duration(seconds: 7));
        if (i.isEven) notifier().markViewed('h${59 - i}');
        select('h${(i * 13) % 60}');
        expect(
          residency().fullResolutionIds.length,
          lessThanOrEqualTo(CanvasImageResidencyLimits.fullResolution),
        );
      }
      expect(CanvasImageResidencyLimits.fullResolution, 21);
    });

    test('without a canvas tile on screen no timer is left running', () {
      fakeAsync((async) {
        generation.publish(ImageGenerationState(history: images('h', 20)));
        notifier().markViewed('h12');
        expect(async.pendingTimers, isEmpty);
        now = now.add(const Duration(minutes: 6));
        async.elapse(const Duration(minutes: 6));
        // Still listed, but too old to count for a tile built now.
        expect(residency().viewed, contains('h12'));
        expect(residency().keepsFullResolution('h12', at: now), isFalse);
        // The next tile on screen drops it.
        notifier().attach();
        async.elapse(Duration.zero);
        expect(residency().viewed, isEmpty);
        notifier().detach();
        expect(async.pendingTimers, isEmpty);
      });
    });
  });

  group('decode width for the size on screen', () {
    const tile = Rect.fromLTWH(0, 0, 832, 1216);
    const viewport = Size(1000, 800);
    int? width(
      double scale,
      double ratio, {
      Rect at = tile,
      int native = 832,
    }) => canvasTileDecodeWidth(
      tileRect: at,
      nativeWidth: native,
      camera: CanvasCamera(offset: Offset.zero, scale: scale),
      viewport: viewport,
      devicePixelRatio: ratio,
    );

    test('overview: a fraction of the pixels on both platforms', () {
      // 832 * 0.1 * ratio * 1.5 headroom, up to a power of two.
      expect(width(0.1, _mac.ratio), 256);
      expect(width(0.1, _windows.ratio), 128);
      expect(width(0.1, 1.25), 256, reason: 'Windows at 125%');
    });

    test('a batch in focus: full on a Retina Mac, half on Windows', () {
      expect(width(0.32, _mac.ratio), isNull);
      expect(width(0.32, _windows.ratio), 512);
    });

    test('zoomed in: full resolution everywhere', () {
      expect(width(1, _mac.ratio), isNull);
      expect(width(1, _windows.ratio), isNull);
    });

    test('far outside the view: a placeholder at most 256 wide', () {
      const far = Rect.fromLTWH(20000, 0, 832, 1216);
      expect(width(1, _mac.ratio, at: far), 256);
      expect(width(1, _windows.ratio, at: far), 256);
      expect(width(0.1, _windows.ratio, at: far), 128);
    });

    test('small images are never decoded larger than they are', () {
      const small = Rect.fromLTWH(0, 0, 100, 150);
      expect(width(1, _mac.ratio, at: small, native: 100), isNull);
      expect(width(0.1, _mac.ratio, at: small, native: 100), 64);
    });

    test('zooming through a range re-decodes only at a few sizes', () {
      for (final ratio in [_mac.ratio, _windows.ratio]) {
        final sizes = {
          for (var scale = 0.05; scale <= 1.0; scale += 0.005)
            width(scale, ratio),
        };
        expect(sizes.length, lessThanOrEqualTo(6), reason: '$sizes');
      }
    });
  });

  group('canvas tiles', () {
    late ProviderContainer container;
    late _Generation generation;
    late DateTime now;
    late List<GeneratedImage> images;
    final shown = <String, ImageProvider>{};
    final cache = PaintingBinding.instance.imageCache;

    setUpAll(() {
      images = [
        for (var i = 0; i < 24; i++)
          _image(
            'h$i',
            Uint8List.fromList(
              img.encodePng(
                img.Image(
                  width: _native.width.toInt(),
                  height: _native.height.toInt(),
                )..clear(img.ColorRgb8(i * 10, 80, 160)),
              ),
            ),
          ),
      ];
    });

    setUp(() {
      now = _start;
      shown.clear();
      generation = _Generation();
      container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(_Memory()),
          imageGenerationNotifierProvider.overrideWith(() => generation),
          canvasResidencyClockProvider.overrideWithValue(() => now),
        ],
      );
      container.read(imageGenerationNotifierProvider);
    });
    tearDown(() {
      container.dispose();
      cache
        ..clear()
        ..clearLiveImages();
    });

    /// 24 images, newest first, laid out like canvas tiles and all in view
    /// at [scale] (an overview of the whole history by default), under the
    /// app's root [AppVisibilityScope] (with [sources]) when given.
    Future<void> pumpCanvas(
      WidgetTester tester, {
      double scale = 0.1,
      AppVisibilitySources? sources,
    }) async {
      tester.view.devicePixelRatio = _displays.currentValue!.ratio;
      tester.view.physicalSize =
          const Size(1000, 800) * tester.view.devicePixelRatio;
      addTearDown(tester.view.reset);
      generation.publish(ImageGenerationState(history: images));
      container.read(generationCanvasCameraProvider.notifier)
        ..setViewport(const Size(1000, 800))
        ..jump(
          CanvasCamera(offset: Offset.zero, scale: scale),
          notifyIdle: false,
        );
      final canvas = UncontrolledProviderScope(
        container: container,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              for (final (index, image) in images.indexed)
                Positioned(
                  left: (index % 6) * 400 * scale,
                  top: (index ~/ 6) * 560 * scale,
                  width: _native.width * scale,
                  height: _native.height * scale,
                  child: CanvasResidentTile(
                    image: image,
                    worldRect: Rect.fromLTWH(
                      (index % 6) * 400,
                      (index ~/ 6) * 560,
                      _native.width,
                      _native.height,
                    ),
                    builder: (context, display) {
                      shown[image.id] = display;
                      return Image(
                        image: display,
                        fit: BoxFit.fill,
                        gaplessPlayback: true,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
      await tester.pumpWidget(
        sources == null
            ? canvas
            : AppVisibilityScope(sources: sources, child: canvas),
      );
    }

    /// Lets every tile finish decoding what it asked for.
    Future<void> decode(WidgetTester tester) async {
      final element = tester.element(find.byType(Stack));
      await tester.runAsync(
        () => Future.wait([
          for (final provider in shown.values) precacheImage(provider, element),
        ]),
      );
      await tester.pump();
    }

    bool fullInMemory(GeneratedImage image) =>
        cache.statusForKey(MemoryImage(image.bytes)).tracked;

    int? decodeWidth(String id) => switch (shown[id]) {
      ResizeImage(:final width) => width,
      _ => null,
    };

    final oldWidth = {_mac: 128, _windows: 64};

    testWidgets('only the newest, the selected and the looked-at stay full', (
      tester,
    ) async {
      await pumpCanvas(tester);
      container.read(generationPreviewSelectionProvider.notifier).select('h20');
      container.read(canvasImageResidencyProvider.notifier)
        ..markViewed('h15')
        ..markViewed('h16');
      await tester.pump();
      await decode(tester);

      final full = {for (var i = 0; i < 10; i++) 'h$i', 'h15', 'h16', 'h20'};
      for (final image in images) {
        final keep = full.contains(image.id);
        expect(
          decodeWidth(image.id),
          keep ? isNull : oldWidth[_displays.currentValue],
          reason: image.id,
        );
        expect(fullInMemory(image), keep, reason: image.id);
      }
      expect(
        images.where(fullInMemory).length,
        lessThanOrEqualTo(CanvasImageResidencyLimits.fullResolution),
      );
      expect(shown['h3'], isA<MemoryImage>());
    }, variant: _displays);

    testWidgets('a look lasts five minutes, then its full decode is let go', (
      tester,
    ) async {
      await pumpCanvas(tester);
      container.read(canvasImageResidencyProvider.notifier).markViewed('h15');
      await tester.pump();
      await decode(tester);
      final h15 = images[15];
      expect(fullInMemory(h15), isTrue);

      now = now.add(const Duration(minutes: 4, seconds: 59));
      await tester.pump(const Duration(minutes: 4, seconds: 59));
      expect(decodeWidth('h15'), isNull);
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(decodeWidth('h15'), oldWidth[_displays.currentValue]);
      expect(fullInMemory(h15), isFalse, reason: 'released, not cached');
      // The newest are untouched by time.
      expect(decodeWidth('h0'), isNull);
      expect(fullInMemory(images[0]), isTrue);
    }, variant: _displays);

    testWidgets('the newest batch stays sharp, until a newer one arrives', (
      tester,
    ) async {
      await pumpCanvas(tester, scale: 0.05);
      await decode(tester);
      now = now.add(const Duration(minutes: 30));
      await tester.pump(const Duration(minutes: 30));
      for (var i = 0; i < 10; i++) {
        expect(decodeWidth('h$i'), isNull, reason: 'h$i');
        expect(fullInMemory(images[i]), isTrue, reason: 'h$i');
      }

      // A new batch of four: the four oldest of the ten step down.
      final batch = [
        for (var i = 0; i < 4; i++)
          _image('n$i', Uint8List.fromList(images[20 + i].bytes)),
      ];
      generation.publish(ImageGenerationState(history: [...batch, ...images]));
      await tester.pump();
      for (var i = 6; i < 10; i++) {
        expect(decodeWidth('h$i'), isNotNull, reason: 'h$i');
        expect(fullInMemory(images[i]), isFalse, reason: 'h$i');
      }
      for (var i = 0; i < 6; i++) {
        expect(decodeWidth('h$i'), isNull, reason: 'h$i');
      }
    }, variant: _displays);

    testWidgets('hidden, a tile still shown full size keeps its full decode', (
      tester,
    ) async {
      // A batch finishes while the window is hidden (a background
      // generation): h6–h9 leave the newest ten, but at this zoom their tiles
      // still show them at full resolution.
      final visibility = AppVisibility.instance;
      final sources = AppVisibilitySources(platform: TargetPlatform.android);
      addTearDown(() {
        sources.detach();
        visibility.debugSet(true);
      });
      await pumpCanvas(tester, scale: 1, sources: sources);
      await decode(tester);
      final kept = images.sublist(6, 10);
      for (final image in kept) {
        expect(decodeWidth(image.id), isNull, reason: image.id);
        expect(fullInMemory(image), isTrue, reason: image.id);
      }
      final loads = AppImageCacheTestBinding.cache.loads;

      visibility.debugSet(false);
      await tester.pump(); // the frame that pauses every image
      final batch = [
        for (var i = 0; i < 4; i++)
          _image('n$i', Uint8List.fromList(images[20 + i].bytes)),
      ];
      generation.publish(ImageGenerationState(history: [...batch, ...images]));
      await tester.pump(); // a frame while hidden (the release draws one)
      for (final image in kept) {
        expect(
          container
              .read(canvasImageResidencyProvider)
              .keepsFullResolution(image.id),
          isFalse,
        );
        expect(decodeWidth(image.id), isNull, reason: image.id);
        expect(fullInMemory(image), isTrue, reason: '${image.id} on screen');
      }

      visibility.debugSet(true);
      await tester.pump();
      expect(
        AppImageCacheTestBinding.cache.loads,
        loads,
        reason: 'decoded again',
      );
      for (final image in kept) {
        expect(fullInMemory(image), isTrue, reason: '${image.id} still shown');
      }
    }, variant: _displays);

    testWidgets(
      'hidden, a full decode the tile moved off goes once it is back',
      (tester) async {
        // Closed to the tray (Windows keeps drawing frames there), a batch
        // finishes and the window is back within the minute, before the
        // release: h6–h9 leave the newest ten, and at this zoom their tiles
        // switch to the size on screen in the next frame, drawn while hidden.
        final visibility = AppVisibility.instance;
        final sources = AppVisibilitySources(platform: TargetPlatform.android);
        addTearDown(() {
          sources.detach();
          visibility.debugSet(true);
        });
        await pumpCanvas(tester, scale: 0.05, sources: sources);
        await decode(tester);
        final lost = images.sublist(6, 10);
        for (final image in lost) {
          expect(decodeWidth(image.id), isNull, reason: image.id);
          expect(fullInMemory(image), isTrue, reason: image.id);
        }

        visibility.debugSet(false);
        await tester.pump(); // the frame that pauses every image
        final batch = [
          for (var i = 0; i < 4; i++)
            _image('n$i', Uint8List.fromList(images[20 + i].bytes)),
        ];
        generation.publish(
          ImageGenerationState(history: [...batch, ...images]),
        );
        await tester.pump(); // a frame while hidden
        for (final image in lost) {
          expect(decodeWidth(image.id), isNotNull, reason: image.id);
        }

        visibility.debugSet(true);
        await tester.pump();
        for (final image in lost) {
          expect(fullInMemory(image), isFalse, reason: '${image.id} not shown');
        }
      },
      variant: _displays,
    );

    testWidgets(
      'resize alone sharpens an old tile entering the canvas viewport',
      (tester) async {
        final ratio = _displays.currentValue!.ratio;
        tester.view.devicePixelRatio = ratio;
        tester.view.physicalSize = const Size(400, 400) * ratio;
        addTearDown(tester.view.reset);
        generation.publish(ImageGenerationState(history: images));
        final image = images.last;
        final camera = container.read(generationCanvasCameraProvider.notifier);
        final tile = CanvasResidentTile(
          image: image,
          worldRect: const Rect.fromLTWH(1100, 0, 320, 480),
          builder: (_, display) {
            shown[image.id] = display;
            return const SizedBox();
          },
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: LayoutBuilder(
              builder: (_, box) {
                camera.setViewport(box.biggest);
                return tile;
              },
            ),
          ),
        );
        await tester.pump();
        expect(decodeWidth(image.id), 256);
        tester.view.physicalSize = const Size(1400, 600) * ratio;
        await tester.pump();
        await tester.pump();
        expect(shown[image.id], isA<MemoryImage>());
        tester.view.physicalSize = const Size(400, 400) * ratio;
        await tester.pump();
        await tester.pump();
        expect(decodeWidth(image.id), 256);
      },
      variant: _displays,
    );

    testWidgets(
      'deleting the last item using bytes releases its canvas decodes and cover',
      (tester) async {
        final image = images.last;
        final twin = _image('same-pixels', image.bytes);
        generation.publish(
          ImageGenerationState(history: [image, twin, images.first]),
        );
        container.read(canvasImageResidencyProvider);
        container
            .read(canvasImageResidencyProvider.notifier)
            .markViewed(image.id);
        await tester.pumpWidget(const SizedBox());
        final context = tester.element(find.byType(SizedBox));
        final variants = [
          MemoryImage(image.bytes),
          canvasImageProvider(image, decodeWidth: 64),
          canvasImageProvider(image, decodeWidth: 256),
          PreviewImageProvider(MemoryImage(image.bytes), 80, 80),
        ];
        final keys = [
          for (final p in variants) await p.obtainKey(ImageConfiguration.empty),
        ];
        expect(keys, hasLength(4));
        await tester.runAsync(
          () => Future.wait([
            for (final provider in variants) precacheImage(provider, context),
            precacheImage(MemoryImage(images.first.bytes), context),
          ]),
        );
        await tester.pump();
        final actions = container.read(generationHistoryActionsProvider);
        await actions.delete([image.id]);
        await tester.pump();
        expect(
          keys.every((key) => cache.statusForKey(key).keepAlive),
          isTrue,
          reason: 'another generated image uses the same bytes',
        );
        await actions.delete([twin.id]);
        await tester.pump();
        for (final key in keys) {
          expect(
            cache.statusForKey(key).keepAlive,
            isFalse,
            reason: key.toString(),
          );
        }
        expect(
          cache.statusForKey(MemoryImage(images.first.bytes)).keepAlive,
          isTrue,
        );
        // A closing viewer reports its last image from a deferred callback.
        container
            .read(canvasImageResidencyProvider.notifier)
            .markViewed(image.id);
        expect(
          container.read(canvasImageResidencyProvider).viewed,
          isNot(contains(image.id)),
        );
      },
    );

    testWidgets('clearing history keeps a pin until the pin alone is removed', (
      tester,
    ) async {
      final directory = Directory.systemTemp.createTempSync(
        'canvas-pin-cache-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final pins = container.read(canvasPinnedNotifierProvider.notifier);
      pins.debugRepository = CanvasPinRepository(
        storage: _Memory(),
        directory: directory,
      );
      final pinned = images.first, other = images.last;
      generation.publish(ImageGenerationState(history: [pinned, other]));
      container.read(canvasImageResidencyProvider);
      await tester.runAsync(() => pins.toggle(pinned));
      expect(container.read(canvasPinnedNotifierProvider), contains(pinned.id));
      await tester.pumpWidget(const SizedBox());
      final context = tester.element(find.byType(SizedBox));
      await tester.runAsync(
        () => Future.wait([
          precacheImage(MemoryImage(other.bytes), context),
          precacheImage(MemoryImage(pinned.bytes), context),
        ]),
      );
      await tester.pump();
      final actions = container.read(generationHistoryActionsProvider);
      expect(cache.statusForKey(MemoryImage(other.bytes)).keepAlive, isTrue);
      actions.clear();
      expect(cache.statusForKey(MemoryImage(other.bytes)).keepAlive, isFalse);
      expect(cache.statusForKey(MemoryImage(pinned.bytes)).keepAlive, isTrue);
      await tester.runAsync(() => actions.delete([pinned.id]));
      await tester.pump();
      expect(cache.statusForKey(MemoryImage(pinned.bytes)).keepAlive, isFalse);
    });

    testWidgets('zooming in sharpens an old image without one decode a step', (
      tester,
    ) async {
      await pumpCanvas(tester);
      final camera = container.read(generationCanvasCameraProvider.notifier);
      // h12 is old (not among the newest ten) and stays in view throughout.
      final widths = <int?>[decodeWidth('h12')];
      for (var scale = 0.1; scale <= 1.0; scale += 0.01) {
        camera.jump(
          CanvasCamera(offset: Offset.zero, scale: scale),
          notifyIdle: false,
        );
        await tester.pump();
        if (decodeWidth('h12') != widths.last) widths.add(decodeWidth('h12'));
      }
      expect(widths.last, isNull, reason: 'full resolution when large');
      expect(widths.length, lessThanOrEqualTo(4), reason: '$widths');
      // Zooming out again keeps that decode in the cache for a quick return.
      camera.jump(
        const CanvasCamera(offset: Offset.zero, scale: 0.1),
        notifyIdle: false,
      );
      await tester.pump();
      expect(decodeWidth('h12'), oldWidth[_displays.currentValue]);
      expect(fullInMemory(images[12]), isTrue);
    }, variant: _displays);
  });

  group('stream previews', () {
    late ProviderContainer container;
    late _Generation generation;
    late AppVisibilitySources sources;
    final visibility = AppVisibility.instance;
    final cache = AppImageCacheTestBinding.cache;

    setUp(() {
      generation = _Generation();
      sources = AppVisibilitySources(platform: TargetPlatform.android);
      container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(_Memory()),
          imageGenerationNotifierProvider.overrideWith(() => generation),
        ],
      );
      container.read(imageGenerationNotifierProvider);
      container.read(canvasImageResidencyProvider);
    });
    tearDown(() {
      container.dispose();
      sources.detach();
      visibility.debugSet(true);
      cache
        ..clear()
        ..clearLiveImages();
    });

    Uint8List png(int seed) => Uint8List.fromList(
      img.encodePng(
        img.Image(width: 32, height: 48)..clear(img.ColorRgb8(seed, 60, 90)),
      ),
    );

    ImageGenerationState step(Uint8List preview, {double progress = .5}) =>
        ImageGenerationState(
          status: GenerationStatus.generating,
          generationRunId: 1,
          totalImages: 1,
          currentImage: 1,
          streamPreview: preview,
          streamPreviewSlots: [
            StreamPreviewSlot(
              imageNumber: 1,
              totalImages: 1,
              progress: progress,
              previewBytes: preview,
            ),
          ],
        );

    /// The slot's preview as the app shows it: full size on the canvas tile
    /// (and the navigation tip), as a small cover in the history panel; under
    /// the app's root, which pauses both while the window is hidden.
    Future<void> pumpPreview(WidgetTester tester) => tester.pumpWidget(
      AppVisibilityScope(
        sources: sources,
        child: UncontrolledProviderScope(
          container: container,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Consumer(
              builder: (context, ref, _) {
                final bytes = ref.watch(
                  imageGenerationNotifierProvider.select(
                    (state) => state.streamPreview,
                  ),
                );
                if (bytes == null) return const SizedBox();
                return Row(
                  children: [
                    Image(image: MemoryImage(bytes), gaplessPlayback: true),
                    UiPreviewImage(
                      image: MemoryImage(bytes),
                      width: 40,
                      height: 60,
                      gaplessPlayback: true,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    /// Lets every image on screen finish decoding.
    Future<void> decode(WidgetTester tester) async {
      final element = tester.element(find.byType(Row));
      await tester.runAsync(
        () => Future.wait([
          for (final image in tester.widgetList<Image>(find.byType(Image)))
            precacheImage(image.image, element),
        ]),
      );
      await tester.pump();
    }

    /// The cache keys of [bytes]: its full decode and its history cover.
    List<Object> keys(Uint8List bytes) => [
      MemoryImage(bytes),
      for (final key in cache.debugKeys)
        if (key is PreviewImageKey && key.source == MemoryImage(bytes)) key,
    ];

    bool cached(Uint8List bytes) =>
        keys(bytes).any((key) => cache.statusForKey(key).tracked);

    testWidgets('a preview the next step replaces leaves the image cache', (
      tester,
    ) async {
      final first = png(10), second = png(80), third = png(160);
      generation.publish(step(first));
      await pumpPreview(tester);
      await decode(tester);
      expect(keys(first), hasLength(2), reason: 'full decode and cover');
      expect(
        keys(first).every((key) => cache.statusForKey(key).keepAlive),
        isTrue,
      );

      generation.publish(step(second));
      await tester.pump();
      await decode(tester);
      expect(cached(first), isFalse, reason: 'never shown again');
      expect(cached(second), isTrue);

      // Hidden (closed to the tray while generating): the next steps still
      // arrive, the paused images switch to them and release nothing.
      visibility.debugSet(false);
      await tester.pump();
      generation.publish(step(third));
      await tester.pump();
      await decode(tester);
      expect(cached(second), isFalse, reason: 'replaced while hidden');

      // The release a minute after hiding keeps the preview on screen only.
      cache.clear();
      expect(cached(second), isFalse);
      expect(
        keys(third).every((key) => cache.statusForKey(key).keepAlive),
        isTrue,
        reason: 'on screen',
      );
    });

    testWidgets('the last step\'s finished image keeps its decode', (
      tester,
    ) async {
      final preview = png(10), finished = png(200);
      generation.publish(step(preview));
      await pumpPreview(tester);
      await decode(tester);
      // The last step shows the finished image's own bytes, then the tile
      // turns into the finished image with the same decode.
      generation.publish(step(finished, progress: 1));
      await tester.pump();
      await decode(tester);
      generation.publish(
        ImageGenerationState(
          status: GenerationStatus.completed,
          generationRunId: 1,
          currentImages: [_image('done', finished)],
          history: [_image('done', finished)],
        ),
      );
      await tester.pump();
      expect(cached(preview), isFalse);
      expect(cache.statusForKey(MemoryImage(finished)).keepAlive, isTrue);
    });
  });
}
