import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/canvas_channel_feed_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_feed_layout.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import 'package:nai_launcher/presentation/wiring/generation_data_wiring.dart';

import '../providers/krita/agent_bridge_draft_test.dart'
    show MemoryDraftSettings;
import 'generation_data_wiring_test.dart' show DataGeneration;

class _Gallery extends LocalGalleryNotifier {
  final paths = <String>[];
  final favorites = <String>{};
  Completer<void>? gate;
  @override
  LocalGalleryState build() => const LocalGalleryState();
  @override
  Future<bool> isFavorite(String filePath) async {
    paths.add(filePath);
    final value = favorites.contains(filePath);
    await gate?.future;
    return value;
  }

  void revision() =>
      state = state.copyWith(contentRevision: state.contentRevision + 1);
}

class _ReadList extends ListBase<CanvasFeedItem> {
  _ReadList(this.source);
  final List<CanvasFeedItem> source;
  int reads = 0;
  @override
  int get length => source.length;
  @override
  set length(int value) => throw UnsupportedError('read only');
  @override
  CanvasFeedItem operator [](int index) {
    reads++;
    return source[index];
  }

  @override
  void operator []=(int index, CanvasFeedItem value) =>
      throw UnsupportedError('read only');
}

class _Section extends StatelessWidget {
  const _Section(this.aspect);
  final GenAspect aspect;
  static final builds = <GenAspect, int>{};
  @override
  Widget build(BuildContext context) {
    final scope = GenScope.of(context, aspect);
    builds.update(aspect, (value) => value + 1, ifAbsent: () => 1);
    return Text(
      '${aspect.name}:${scope.data.canvas.info?.seed}',
      textDirection: TextDirection.ltr,
    );
  }
}

GeneratedImage _image(
  String id, {
  String? path,
  int run = 1,
  int index = 0,
  int width = 832,
}) => GeneratedImage(
  id: id,
  bytes: Uint8List(0),
  width: width,
  height: 1216,
  filePath: path,
  generationRunId: run,
  batchIndex: index,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  late DataGeneration generation;
  setUp(() {
    container = ProviderContainer(
      overrides: [
        imageGenerationNotifierProvider.overrideWith(DataGeneration.new),
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        localGalleryNotifierProvider.overrideWith(_Gallery.new),
      ],
    );
    generation =
        container.read(imageGenerationNotifierProvider.notifier)
            as DataGeneration;
  });
  tearDown(() => container.dispose());

  test(
    'favorite queries ignore progress, deduplicate paths, and refresh by content revision',
    () async {
      final gallery =
          container.read(localGalleryNotifierProvider.notifier) as _Gallery;
      gallery.favorites.add('memory:/a');
      final history = [
        _image('a', path: 'memory:/a'),
        _image('b', path: 'memory:/a', index: 1),
      ];
      generation.publish(ImageGenerationState(history: history));
      final sub = container.listen(generationFavoriteImagesProvider, (_, _) {});
      addTearDown(sub.close);
      expect(await container.read(generationFavoriteImagesProvider.future), {
        'a',
        'b',
      });
      for (var i = 0; i < 10; i++) {
        generation.publish(
          ImageGenerationState(history: history, progress: i / 10),
        );
        await container.read(generationFavoriteImagesProvider.future);
      }
      expect(gallery.paths, ['memory:/a']);
      gallery.favorites.clear();
      gallery.revision();
      expect(
        await container.read(generationFavoriteImagesProvider.future),
        isEmpty,
      );
      expect(gallery.paths, ['memory:/a', 'memory:/a']);
      generation.publish(
        ImageGenerationState(history: [_image('a', path: 'memory:/new')]),
      );
      await container.read(generationFavoriteImagesProvider.future);
      expect(gallery.paths.last, 'memory:/new');
      generation.publish(const ImageGenerationState());
      expect(
        await container.read(generationFavoriteImagesProvider.future),
        isEmpty,
      );
    },
  );

  test(
    'progress reuses an in-flight favorite lookup and stale replies cannot restore removed IDs',
    () async {
      final gallery =
          container.read(localGalleryNotifierProvider.notifier) as _Gallery;
      final gate = gallery.gate = Completer<void>();
      gallery.favorites.add('memory:/a');
      final history = [_image('a', path: 'memory:/a')];
      generation.publish(ImageGenerationState(history: history));
      final sub = container.listen(generationFavoriteImagesProvider, (_, _) {});
      addTearDown(sub.close);
      final pending = container.read(generationFavoriteImagesProvider.future);
      generation.publish(ImageGenerationState(history: history, progress: .7));
      expect(
        identical(
          pending,
          container.read(generationFavoriteImagesProvider.future),
        ),
        isTrue,
      );
      generation.publish(const ImageGenerationState());
      expect(
        await container.read(generationFavoriteImagesProvider.future),
        isEmpty,
      );
      gate.complete();
      await pending;
      expect(
        container.read(generationFavoriteImagesProvider).valueOrNull,
        isEmpty,
      );
      expect(gallery.paths, ['memory:/a']);
    },
  );

  test(
    'stream frames reuse geometry/history while refreshing slots and channel only follows geometry',
    () {
      final history = [
        for (var i = 0; i < 800; i++)
          _image('h$i', run: i ~/ 4 + 1, index: i % 4),
      ];
      final initial = ImageGenerationState(
        history: history,
        generationRunId: 900,
        status: GenerationStatus.generating,
        batchWidth: 832,
        batchHeight: 1216,
        currentImage: 1,
        totalImages: 2,
      );
      generation.publish(initial);
      final before = container.read(canvasFeedLayoutProvider);
      final geometry = container.read(canvasFeedGeometryProvider);
      final channel = container.read(canvasChannelFeedProvider);
      final old = before.items.firstWhere((item) => item.image?.id == 'h0');
      final preview = Uint8List.fromList([1, 2, 3]);
      for (var i = 1; i <= 10; i++) {
        generation.publish(
          initial.copyWith(progress: i / 10, streamPreview: preview),
        );
        final next = container.read(canvasFeedLayoutProvider);
        expect(
          identical(container.read(canvasFeedGeometryProvider), geometry),
          isTrue,
        );
        expect(
          identical(container.read(canvasChannelFeedProvider), channel),
          isTrue,
        );
        expect(
          identical(
            next.items.firstWhere((item) => item.image?.id == 'h0'),
            old,
          ),
          isTrue,
        );
        expect(next.items.first.tile.slot!.progress, i / 10);
        expect(next.items.first.tile.slot!.previewBytes, same(preview));
        expect(next.items.first.worldRect, before.items.first.worldRect);
      }
      final secondPreview = Uint8List.fromList([4, 5]);
      generation.publish(
        initial.copyWith(
          currentImage: 2,
          streamPreviewSlots: [
            StreamPreviewSlot(
              imageNumber: 2,
              totalImages: 2,
              progress: .4,
              previewBytes: secondPreview,
            ),
          ],
        ),
      );
      final frame = container.read(canvasFeedLayoutProvider);
      expect(frame.items[1].tile.slot!.previewBytes, same(secondPreview));
      final completed = _image('done', run: 900, width: 1216);
      generation.publish(initial.copyWith(currentImages: [completed]));
      final done = container.read(canvasFeedLayoutProvider);
      expect(done.items.first.image, same(completed));
      expect(done.items.first.worldRect.width, 1216);
      expect(
        done.items.firstWhere((item) => item.image?.id == 'h0').worldRect,
        old.worldRect,
      );
    },
  );

  test(
    'batch bounds index scans once and preserves exact unions / empty groups',
    () {
      final groups = groupCanvasImages([
        for (var i = 0; i < 800; i++) _image('i$i', run: i ~/ 4, index: i % 4),
      ]);
      final laid = layoutCanvasFeed(groups);
      final items = _ReadList(laid.items);
      final result = CanvasFeedLayoutResult(
        items: items,
        groups: groups,
        bounds: laid.bounds,
      );
      final index = CanvasGroupBoundsIndex();
      for (var step = 0; step < 20; step++) {
        for (final group in groups) {
          final rects = laid.items
              .where((item) => item.group.key == group.key)
              .map((item) => item.worldRect);
          expect(
            index.boundsOf(result, group.key),
            rects.reduce((a, b) => a.expandToInclude(b)),
          );
        }
      }
      expect(items.reads, items.length);
      expect(index.boundsOf(result, 'removed'), Rect.zero);
      expect(
        index.boundsOf(
          const CanvasFeedLayoutResult(
            items: [],
            groups: [],
            bounds: Rect.zero,
          ),
          groups.first.key,
        ),
        Rect.zero,
      );
    },
  );

  testWidgets(
    'input changes leave canvas/history/refs untouched, meaningful data and actions still notify',
    (tester) async {
      _Section.builds.clear();
      var data = const GenViewData(model: 'm', models: []);
      var actions = GenActions.logging((_) {});
      const slots = GenSlots(editor: _editor);
      Future<void> pump() => tester.pumpWidget(
        MaterialApp(
          home: GenHost(
            data: data,
            actions: actions,
            slots: slots,
            child: const Column(
              children: [
                _Section(GenAspect.canvas),
                _Section(GenAspect.canvasTile),
                _Section(GenAspect.history),
                _Section(GenAspect.refs),
              ],
            ),
          ),
        ),
      );
      await pump();
      data = data.copyWith(
        prompt: const GenPromptData(
          positivePreview: [GenPreviewSection(label: 'p', text: 'new text')],
        ),
      );
      await pump();
      expect(_Section.builds.values, everyElement(1));
      data = data.copyWith(
        canvas: const GenCanvasData(
          info: GenFocusInfo(tileId: 'new', width: 832, height: 1216, seed: 42),
        ),
      );
      await pump();
      expect(_Section.builds[GenAspect.canvas], 2);
      expect(_Section.builds[GenAspect.history], 1);
      expect(_Section.builds[GenAspect.canvasTile], 2);
      data = data.copyWith(
        canvas: const GenCanvasData(
          info: GenFocusInfo(tileId: 'new', width: 832, height: 1216, seed: 42),
          focus: GenGroup(
            id: 'active',
            tiles: [
              GenTile(
                id: 'slot',
                width: 832,
                height: 1216,
                state: GenTileState.streaming,
                progress: .5,
              ),
            ],
          ),
        ),
      );
      await pump();
      expect(_Section.builds[GenAspect.canvas], 3);
      expect(_Section.builds[GenAspect.canvasTile], 2);
      actions = GenActions.logging((_) {});
      await pump();
      expect(_Section.builds[GenAspect.history], 2);
    },
  );
}

Widget _editor(BuildContext context, GenEditorTarget target) =>
    const SizedBox();
