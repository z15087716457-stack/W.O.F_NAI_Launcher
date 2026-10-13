import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/data/models/image/image_stream_chunk.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/canvas_settings_provider.dart';
import 'package:nai_launcher/presentation/widgets/common/decoded_memory_image.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_feed_layout.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_tile_toolbar.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/generation_canvas_controller.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/generation_canvas_view.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_page.dart';
import 'package:nai_launcher/presentation/wiring/image_viewer_wiring.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';

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

class _Shortcuts extends ShortcutConfigNotifier {
  @override
  Future<ShortcutConfig> build() async => ShortcutConfig.createDefault();
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
    kritaBridgeNotifierProvider.overrideWith((ref) => KritaBridgeNotifier()),
    estimatedCostProvider.overrideWithValue(7),
    generationCanvasCameraProvider.overrideWith(_Camera.new),
    shortcutConfigNotifierProvider.overrideWith(_Shortcuts.new),
  ],
);

void _publish(ProviderContainer container, ImageGenerationState next) =>
    (container.read(imageGenerationNotifierProvider.notifier) as _Generation)
        .publish(next);

Future<void> _mount(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ImageViewerHost(
            child: Consumer(
              builder: (context, ref, _) => GenerationCanvasView(
                generationState: ref.watch(imageGenerationNotifierProvider),
              ),
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

class _AnimatedStorage extends _Storage {
  @override
  bool getCanvasReducedMotion() => false;
}

class _LockedStorage extends _Storage {
  @override
  bool getCanvasLockCamera() => true;
}

class _Pins extends CanvasPinnedNotifier {
  int toggles = 0;
  @override
  Set<String> build() => {_image(1).id};
  @override
  List<GeneratedImage> get images => [_image(1)];
  @override
  Future<void> toggle(GeneratedImage image) async => toggles++;
}

void main() {
  testWidgets(
    'batch deletion keeps surviving image identity and clamps removed child focus',
    (tester) async {
      final images = [
        for (var index = 0; index < 4; index++) _image(1, index: index),
      ];
      final container = _container(ImageGenerationState(history: images));
      addTearDown(container.dispose);
      await _mount(tester, container);
      await tester.pumpAndSettle();
      container
          .read(generationPreviewSelectionProvider.notifier)
          .select(images.last.id);
      await tester.pumpAndSettle();
      final notifier = container.read(imageGenerationNotifierProvider.notifier);
      notifier.removeImages({images.first.id});
      await tester.pumpAndSettle();
      expect(
        container.read(generationPreviewSelectionProvider),
        images.last.id,
      );
      expect(
        container.read(generationCanvasGroupSelectionProvider)?.subimage,
        2,
      );
      notifier.removeImages({images.last.id});
      await tester.pumpAndSettle();
      expect(container.read(generationPreviewSelectionProvider), images[2].id);
      expect(
        container.read(generationCanvasGroupSelectionProvider)?.subimage,
        1,
      );
      await _unmount(tester);
    },
  );
  testWidgets(
    'canvas single click focuses immediately; double click opens details',
    (tester) async {
      final image = _image(1);
      final container = _container(ImageGenerationState(history: [image]));
      addTearDown(container.dispose);
      await _mount(tester, container);
      await tester.pumpAndSettle();
      final tile = find.byKey(const ValueKey('canvas-tile:run:1:0'));
      final position = tester.getCenter(tile);
      await tester.tapAt(position);
      await tester.pump();
      expect(
        container.read(generationCanvasGroupSelectionProvider)?.subimage,
        0,
      );
      expect(find.byType(ImageViewerPage), findsNothing);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(position);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final viewer = tester.widget<ImageViewerPage>(
        find.byType(ImageViewerPage),
      );
      expect(viewer.data.currentKey, image.id);
      await _unmount(tester);
    },
  );

  testWidgets(
    'canvas delete removes only clicked image everywhere and keeps saved file',
    (tester) async {
      final temp = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('canvas_delete_test_'),
      ))!;
      addTearDown(() => temp.deleteSync(recursive: true));
      final file = File('${temp.path}/saved.png')..writeAsBytesSync(_png);
      final target = _image(1).copyWithFilePath(file.path);
      final other = _image(2);
      final container = _container(
        ImageGenerationState(
          currentImages: [target, other],
          history: [target, other],
          displayImages: [target, other],
        ),
      );
      addTearDown(container.dispose);
      await _mount(tester, container);
      await tester.pumpAndSettle();
      final tile = find.byKey(const ValueKey('canvas-tile:run:1:0'));
      container
          .read(generationPreviewSelectionProvider.notifier)
          .select(target.id);
      await tester.pumpAndSettle();
      await tester.tap(tile, buttons: kSecondaryButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      final state = container.read(imageGenerationNotifierProvider);
      expect(state.currentImages.map((image) => image.id), [other.id]);
      expect(state.history.map((image) => image.id), [other.id]);
      expect(state.displayImages.map((image) => image.id), [other.id]);
      expect(container.read(generationPreviewSelectionProvider), other.id);
      expect(find.byKey(const ValueKey('canvas-tile:run:1:0')), findsNothing);
      expect(file.readAsBytesSync(), _png);
      await _unmount(tester);
    },
  );

  testWidgets(
    'cancelling delete keeps image; deleting last clears canvas focus',
    (tester) async {
      final image = _image(1);
      final container = _container(ImageGenerationState(history: [image]));
      addTearDown(container.dispose);
      await _mount(tester, container);
      await tester.pumpAndSettle();
      final tile = find.byKey(const ValueKey('canvas-tile:run:1:0'));
      Future<void> openDelete() async {
        await tester.tap(tile, buttons: kSecondaryButton);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();
      }

      await openDelete();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(
        container.read(imageGenerationNotifierProvider).history.single.id,
        image.id,
      );
      await openDelete();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(container.read(imageGenerationNotifierProvider).history, isEmpty);
      expect(container.read(generationPreviewSelectionProvider), isNull);
      expect(container.read(generationCanvasGroupSelectionProvider), isNull);
      expect(find.byType(CanvasEdgeToolbar), findsNothing);
      await _unmount(tester);
    },
  );
  testWidgets('history batch request returns from child focus to whole batch', (
    tester,
  ) async {
    final images = [for (var i = 0; i < 4; i++) _image(1, index: i)];
    final container = _container(
      ImageGenerationState(history: images.reversed.toList()),
    );
    addTearDown(container.dispose);
    await _mount(tester, container);
    await tester.pumpAndSettle();
    container
        .read(generationCanvasGroupSelectionProvider.notifier)
        .selectTile('run:1', 0);
    container
        .read(generationPreviewSelectionProvider.notifier)
        .select(images.first.id);
    await tester.pump();
    container.read(canvasHistoryFocusRequestProvider.notifier).state = (
      group: 'run:1',
      imageId: images.first.id,
      revision: 1,
    );
    await tester.pumpAndSettle();
    final focus = container.read(generationCanvasGroupSelectionProvider)!;
    expect(focus.group, 'run:1');
    expect(focus.subimage, isNull);
    final camera = container.read(generationCanvasCameraProvider);
    final viewport = tester.getSize(find.byType(GenerationCanvasView));
    final visible = camera.visibleWorldRect(viewport);
    final layout = container.read(canvasFeedLayoutProvider);
    for (final item in layout.items) {
      expect(visible.contains(item.worldRect.topLeft), isTrue);
      expect(visible.contains(item.worldRect.bottomRight), isTrue);
    }
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });
  testWidgets('hover and selection keep only the three viewport toolbars', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        imageGenerationNotifierProvider.overrideWith(
          () => _Generation(ImageGenerationState(history: [_image(1)])),
        ),
        localStorageServiceProvider.overrideWith((ref) => _Storage()),
        canvasPinnedNotifierProvider.overrideWith(_Pins.new),
        estimatedCostProvider.overrideWithValue(7),
      ],
    );
    addTearDown(container.dispose);
    await _mount(tester, container);
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(location: const Offset(1, 1));
    await pointer.moveTo(
      tester.getCenter(find.byKey(const ValueKey('canvas-tile:run:1:0'))),
    );
    await tester.pump();
    expect(find.byType(CanvasEdgeToolbar), findsNWidgets(3));
    expect(find.byTooltip('Unpin image'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('canvas-tile:run:1:0')));
    await tester.pump();
    expect(find.byType(CanvasEdgeToolbar), findsNWidgets(3));
    expect(find.byTooltip('Unpin image'), findsOneWidget);
    final toolbar = find.byWidgetPredicate(
      (w) => w is CanvasEdgeToolbar && w.zone == CanvasToolbarZone.bottomEnd,
    );
    final pinButton = find
        .descendant(of: toolbar, matching: find.byType(InkWell))
        .first;
    await tester.tap(pinButton);
    await tester.pump();
    expect(
      (container.read(canvasPinnedNotifierProvider.notifier) as _Pins).toggles,
      1,
    );
    await pointer.removePointer();
    await _unmount(tester);
  });

  testWidgets('restored pins remain reachable when history is empty', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        imageGenerationNotifierProvider.overrideWith(
          () => _Generation(const ImageGenerationState()),
        ),
        localStorageServiceProvider.overrideWith((ref) => _Storage()),
        canvasPinnedNotifierProvider.overrideWith(_Pins.new),
        estimatedCostProvider.overrideWithValue(7),
      ],
    );
    addTearDown(container.dispose);
    await _mount(tester, container);
    container.read(canvasPinboardFocusRequestProvider.notifier).state++;
    await tester.pump();
    expect(
      container.read(generationCanvasGroupSelectionProvider)?.group,
      'pin:1:0',
    );
    final pin = find.byKey(const ValueKey('canvas-tile:pin:1:0:0'));
    expect(pin, findsOneWidget);
    await tester.tap(pin);
    await tester.pump();
    expect(container.read(generationCanvasGroupSelectionProvider)?.subimage, 0);
    await _unmount(tester);
  });

  testWidgets(
    'inpaint stream crop keeps its position and size within the source',
    (tester) async {
      final crop = Uint8List.fromList(
        img.encodePng(img.Image(width: 4, height: 4)),
      );
      final placement = InpaintStreamPreviewPlacement(
        sourceImage: _png,
        xPercent: .25,
        yPercent: .2,
        widthPercent: .5,
        heightPercent: .3,
      );
      final container = _container(
        _loading(
          2,
          slots: [
            StreamPreviewSlot(
              imageNumber: 1,
              totalImages: 1,
              progress: .5,
              previewBytes: crop,
              inpaintPreviewPlacement: placement,
            ),
          ],
        ),
      );
      addTearDown(container.dispose);
      await _mount(tester, container);
      final source = find.byWidgetPredicate(
        (w) => w is DecodedMemoryImage && identical(w.bytes, _png),
      );
      final preview = find.byWidgetPredicate(
        (w) => w is DecodedMemoryImage && identical(w.bytes, crop),
      );
      final baseRect = tester.getRect(source);
      final cropRect = tester.getRect(preview);
      expect(cropRect.width, closeTo(baseRect.width * .5, .01));
      expect(cropRect.height, closeTo(baseRect.height * .3, .01));
      expect(cropRect.left - baseRect.left, closeTo(baseRect.width * .25, .01));
      expect(cropRect.top - baseRect.top, closeTo(baseRect.height * .2, .01));
      await _unmount(tester);
    },
  );

  testWidgets('WASD key-up still stops motion after Ctrl is pressed', (
    tester,
  ) async {
    final container = _container(ImageGenerationState(history: [_image(1)]));
    addTearDown(container.dispose);
    await _mount(tester, container);
    await tester.tapAt(const Offset(20, 200));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyW);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyW);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    final stopped = container.read(generationCanvasCameraProvider).offset;
    await tester.pump(const Duration(milliseconds: 200));
    expect(container.read(generationCanvasCameraProvider).offset, stopped);
    await _unmount(tester);
  });

  testWidgets('Ctrl+0 overview survives stream updates and camera idle', (
    tester,
  ) async {
    final initial = _loading(2, history: [_image(1)]);
    final container = _container(initial);
    addTearDown(container.dispose);
    await _mount(tester, container);
    await tester.tapAt(const Offset(20, 200));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit0);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    _publish(
      container,
      initial.copyWith(
        streamPreviewSlots: [
          StreamPreviewSlot(
            imageNumber: 1,
            totalImages: 1,
            progress: .5,
            previewBytes: _png,
          ),
        ],
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(container.read(generationCanvasGroupSelectionProvider), isNull);
    expect(container.read(generationCanvasCameraProvider).offset, Offset.zero);
    await _unmount(tester);
  });

  testWidgets('Shift plus left mouse drag pans without selecting an image', (
    tester,
  ) async {
    final container = _container(ImageGenerationState(history: [_image(1)]));
    addTearDown(container.dispose);
    await _mount(tester, container);
    final before = container.read(generationCanvasCameraProvider).offset;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    final mouse = await tester.startGesture(
      const Offset(20, 200),
      kind: PointerDeviceKind.mouse,
    );
    await mouse.moveBy(const Offset(50, 0));
    await mouse.up();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(
      container.read(generationCanvasCameraProvider).offset,
      before + const Offset(50, 0),
    );
    await _unmount(tester);
  });

  testWidgets('lock camera should block plus zoom', (tester) async {
    final container = ProviderContainer(
      overrides: [
        imageGenerationNotifierProvider.overrideWith(
          () => _Generation(ImageGenerationState(history: [_image(1)])),
        ),
        localStorageServiceProvider.overrideWith((ref) => _LockedStorage()),
        estimatedCostProvider.overrideWithValue(7),
        generationCanvasCameraProvider.overrideWith(_Camera.new),
      ],
    );
    addTearDown(container.dispose);
    await _mount(tester, container);
    await tester.tapAt(const Offset(20, 200));
    await tester.pump();
    final before = container.read(generationCanvasCameraProvider).scale;
    await tester.sendKeyEvent(LogicalKeyboardKey.equal);
    await tester.pump();
    final after = container.read(generationCanvasCameraProvider).scale;
    await _unmount(tester);
    expect(after, before);
  });
  testWidgets(
    'variations should be disabled while another generation is pending',
    (tester) async {
      final old = _image(1);
      final container = _container(ImageGenerationState(history: [old]));
      addTearDown(container.dispose);
      await _mount(tester, container);
      _publish(container, _loading(2, history: [old]));
      await tester.pump();
      container
          .read(generationPreviewSelectionProvider.notifier)
          .select(old.id);
      await tester.pump();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(GenerationCanvasView)),
      )!;
      final tooltip = find.byTooltip(l10n.img2img_generateVariations);
      final button = tester.widget<InkWell>(
        find.descendant(of: tooltip, matching: find.byType(InkWell)),
      );
      final action = button.onTap;
      await _unmount(tester);
      expect(action, isNull);
    },
  );

  testWidgets('left and right halves should both accept a tile click', (
    tester,
  ) async {
    final container = _container(ImageGenerationState(history: [_image(1)]));
    addTearDown(container.dispose);
    await _mount(tester, container);
    final tile = find.byKey(const ValueKey('canvas-tile:run:1:0'));
    final r = tester.getRect(tile);
    await tester.tapAt(Offset(r.left + r.width * .25, r.center.dy));
    await tester.pump();
    final left = container
        .read(generationCanvasGroupSelectionProvider)
        ?.subimage;
    container
        .read(generationCanvasGroupSelectionProvider.notifier)
        .selectGroup('run:1');
    await tester.pump();
    await tester.tapAt(Offset(r.left + r.width * .75, r.center.dy));
    await tester.pump();
    final right = container
        .read(generationCanvasGroupSelectionProvider)
        ?.subimage;
    await _unmount(tester);
    expect([left, right], [0, 0]);
  });
  testWidgets('a newly generated tile above origin should accept clicks', (
    tester,
  ) async {
    final old = _image(1);
    final container = _container(ImageGenerationState(history: [old]));
    addTearDown(container.dispose);
    await _mount(tester, container);
    _publish(container, _loading(2, history: [old]));
    await tester.pump();
    final done = _image(2);
    _publish(
      container,
      ImageGenerationState(
        generationRunId: 2,
        status: GenerationStatus.completed,
        currentImages: [done],
        history: [done, old],
      ),
    );
    await tester.pump();
    final tile = find.byKey(const ValueKey('canvas-tile:run:2:0'));
    final r = tester.getRect(tile);
    await tester.tapAt(Offset(r.left + r.width * .75, r.center.dy));
    await tester.pump();
    final selected = container.read(generationCanvasGroupSelectionProvider);
    await _unmount(tester);
    expect(selected?.subimage, 0);
  });
  testWidgets('plain left drag should not pan the canvas', (tester) async {
    final container = _container(ImageGenerationState(history: [_image(1)]));
    addTearDown(container.dispose);
    await _mount(tester, container);
    final before = container.read(generationCanvasCameraProvider).offset;
    final mouse = await tester.startGesture(
      const Offset(20, 200),
      kind: PointerDeviceKind.mouse,
    );
    await mouse.moveBy(const Offset(50, 0));
    await mouse.up();
    await tester.pump();
    final after = container.read(generationCanvasCameraProvider).offset;
    await _unmount(tester);
    expect(after, before);
  });
  test('two zoom ticks should accumulate to 1.44 before the first frame', () {
    final container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWith((ref) => _AnimatedStorage()),
        generationCanvasCameraProvider.overrideWith(_Camera.new),
      ],
    );
    final camera =
        container.read(generationCanvasCameraProvider.notifier) as _Camera;
    camera.setViewport(const Size(800, 600));
    camera.jump(CanvasCamera.init);
    camera.zoomBy(1.2);
    camera.zoomBy(1.2);
    final scale = camera.targets.last.scale;
    container.dispose();
    expect(scale, closeTo(1.44, 0.00001));
  });
  test('distant focus must keep the final camera target exact', () {
    final container = _container(const ImageGenerationState());
    final camera = container.read(generationCanvasCameraProvider.notifier);
    camera.jump(CanvasCamera.init);
    const target = CanvasCamera(offset: Offset(0, 10000), scale: 1);
    final adjusted = camera.adjustTargetForTeleport(
      target,
      const Size(800, 600),
    );
    container.dispose();
    expect(adjusted.offset, target.offset);
  });
}
