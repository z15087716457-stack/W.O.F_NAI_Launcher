import 'dart:io';
import '../../../../helpers/grouped_canvas_batches.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/services/canvas_pin_repository.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/canvas_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/history_click_behavior_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/history_batch.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_feed_layout.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/generated_image_actions.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_history.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import 'package:nai_launcher/presentation/widgets/common/themed_confirm_dialog.dart';
import 'package:nai_launcher/presentation/wiring/generation_data_wiring.dart';
import 'package:nai_launcher/presentation/wiring/generation_view_mapping.dart';
import 'package:nai_launcher/presentation/wiring/generation_wiring.dart';
import '../../../providers/krita/agent_bridge_draft_test.dart'
    show MemoryCharacters, MemoryDraftSettings, EmptyBlocks, OfflineAuth;
import '../../../wiring/generation_data_wiring_test.dart'
    show DataGeneration, DataSubscription, DataShortcuts;
import '../../../wiring/generation_reference_imports_test.dart'
    show ImportStorage;
import '../../../../helpers/studio_capture_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadStudioCaptureFonts);
  late Directory directory;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('generation-history-ui-');
    Hive.init(directory.path);
    await Hive.openBox(StorageKeys.settingsBox);
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });
  ProviderContainer create(List<GeneratedImage> images) {
    final storage = MemoryDraftSettings();
    storage.values[StorageKeys.historyClickBehavior] =
        HistoryClickBehavior.selectPreview.storageValue;
    final container = ProviderContainer(
      overrides: [
        groupedCanvasBatchesOverride,
        localStorageServiceProvider.overrideWithValue(storage),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockLibraryNotifierProvider.overrideWith(EmptyBlocks.new),
        authNotifierProvider.overrideWith(OfflineAuth.new),
        imageGenerationNotifierProvider.overrideWith(DataGeneration.new),
        subscriptionNotifierProvider.overrideWith(DataSubscription.new),
        shortcutConfigNotifierProvider.overrideWith(DataShortcuts.new),
        vibeLibraryStorageServiceProvider.overrideWithValue(ImportStorage()),
        localUpscaleModelsProvider.overrideWith((ref) async => []),
        generationFavoriteImagesProvider.overrideWith((ref) async => {}),
      ],
    );
    addTearDown(container.dispose);
    container.read(canvasPinnedNotifierProvider.notifier).debugRepository =
        CanvasPinRepository(storage: storage, directory: directory);
    (container.read(imageGenerationNotifierProvider.notifier) as DataGeneration)
        .publish(ImageGenerationState(history: images));
    return container;
  }

  Future<void> pump(
    WidgetTester tester,
    ProviderContainer container, {
    double width = 320,
    Locale locale = const Locale('zh'),
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SizedBox(
              width: width,
              height: 640,
              child: GenerationWiring(
                builder: ({required data, required actions, required slots}) =>
                    GenHost(
                      data: data,
                      actions: actions,
                      slots: slots,
                      child: GenHistoryPanel(width: width),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test(
    'groups only explicit runs, sorts by slot and deduplicates current/history',
    () {
      final images = [
        for (var i = 0; i < 4; i++) _image('batch-$i', run: 7, slot: i),
      ];
      final batches = buildHistoryBatches(
        ImageGenerationState(
          currentImages: [images[0]],
          history: [...images.reversed, _image('legacy-1'), _image('legacy-2')],
        ),
      );
      expect(batches, hasLength(3));
      expect(
        batches.first.images.map((image) => image.id),
        images.map((image) => image.id),
      );
      expect(batches.first.cover?.id, images.first.id);
      expect(batches.first.count, 4);
      expect(batches.skip(1).map((batch) => batch.count), [1, 1]);
    },
  );

  test('a long history retains every image and takes new requests on top', () {
    final images = [for (var i = 0; i < 120; i++) _image('long-$i')];
    final state = ImageGenerationState(history: images);
    final before = generationHistoryView(state);
    expect(before.total, 120);
    // A progress-only update keeps the list; a new image joins at the top.
    final progress = generationHistoryView(state.copyWith(progress: .5));
    expect(
      progress.batches.map((batch) => batch.id),
      before.batches.map((batch) => batch.id),
    );
    final added = generationHistoryView(
      state.copyWith(
        history: [
          _image('long-new', createdAt: DateTime(2026, 10, 13)),
          ...images,
        ],
      ),
    );
    expect(added.total, 121);
    expect(added.batches.first.images.single.id, 'long-new');
    expect(
      added.batches.expand((batch) => batch.images).map((image) => image.id),
      contains('long-119'),
    );
  });

  test(
    'waiting, out-of-order responses and completion keep one batch and first-slot cover',
    () {
      final images = [
        for (var i = 0; i < 4; i++) _image('stream-$i', run: 9, slot: i),
      ];
      var state = const ImageGenerationState(
        status: GenerationStatus.generating,
        generationRunId: 9,
        totalImages: 4,
      );
      var history = generationHistoryView(state);
      expect(history.batches.single.pending, 4);
      state = state.copyWith(
        currentImages: [images[2], images[0]],
        history: [images[2], images[0]],
      );
      history = generationHistoryView(state);
      expect(history.batches.single.images.first.id, 'stream-0');
      expect(history.batches.single.images, hasLength(2));
      expect(history.batches.single.pending, 2);
      history = generationHistoryView(
        state.copyWith(
          status: GenerationStatus.idle,
          currentImages: [],
          history: images.reversed.toList(),
        ),
      );
      expect(history.batches.single.images, hasLength(4));
      expect(history.batches.single.pending, 0);
      expect(history.batches.single.images.first.id, 'stream-0');
    },
  );

  test('cancelled partial batch counts only retained images', () {
    final image = _image('partial', run: 5, slot: 2);
    final history = generationHistoryView(
      ImageGenerationState(history: [image], totalImages: 4),
    );
    expect(history.total, 1);
    expect(history.batches.single.pending, 0);
  });

  testWidgets(
    'empty history has no total count and renders the new empty state',
    (tester) async {
      await pump(tester, create([]));
      expect(find.byKey(const Key('gen-history-empty')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'batch click focuses first slot and confirmed bulk removal removes every batch image',
    (tester) async {
      final images = [
        for (var i = 0; i < 4; i++) _image('batch-$i', run: 7, slot: i),
      ];
      final container = create(images.reversed.toList());
      await pump(tester, container);
      final tile = find.byKey(const Key('gen-batch-tile-run:7'));
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(container.read(canvasHistoryFocusRequestProvider)?.group, 'run:7');
      expect(container.read(generationPreviewSelectionProvider), 'batch-0');
      await tester.tap(find.byKey(const Key('gen-history-select')));
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('gen-history-delete-selected')));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(
        tester.element(find.byType(GenHistoryPanel)),
      )!;
      await tester.tap(find.text(l.gen_removeConfirm));
      await tester.pumpAndSettle();
      expect(container.read(imageGenerationNotifierProvider).history, isEmpty);
      expect(find.byKey(const Key('gen-history-empty')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'selecting a non-cover child highlights its batch through provider data',
    (tester) async {
      final images = [
        _image('cover', run: 1, slot: 0),
        _image('child', run: 1, slot: 1),
      ];
      final container = create(images);
      await pump(tester, container);
      container
          .read(generationPreviewSelectionProvider.notifier)
          .select('child');
      await tester.pump();
      final scope = GenScope.of(tester.element(find.byType(GenHistoryPanel)));
      expect(scope.data.history.selected, 'run:1');
      expect(find.byKey(const Key('gen-batch-focused')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'rapid Ctrl clicks stay in batch multi-selection instead of opening a viewer',
    (tester) async {
      final container = create([_image('first')]);
      await pump(tester, container);
      final tile = find.byKey(const Key('gen-batch-tile-img:first'));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(tile);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('gen-history-selection')), findsOneWidget);
      await tester.tap(tile);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(
        container.read(imageGenerationNotifierProvider).history.single.id,
        'first',
      );
      expect(find.byKey(const Key('gen-history-open')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final locale in ['zh', 'en', 'ja']) {
    for (final width in [200.0, 280.0, 400.0]) {
      testWidgets('bulk actions fit ${width}px history in $locale', (
        tester,
      ) async {
        await pump(
          tester,
          create([_image('bulk-layout')]),
          width: width,
          locale: Locale(locale),
        );
        await tester.tap(find.byKey(const Key('gen-history-select')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('gen-batch-tile-img:bulk-layout')),
        );
        await tester.pumpAndSettle();
        final panel = tester.getRect(find.byType(GenHistoryPanel));
        for (final key in [
          'gen-history-pack',
          'gen-history-save-selected',
          'gen-history-delete-selected',
        ]) {
          final rect = tester.getRect(find.byKey(Key(key)));
          expect(panel.contains(rect.topLeft), isTrue);
          expect(
            panel.contains(rect.bottomRight - const Offset(.1, .1)),
            isTrue,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets('shared image action retains confirmation for other callers', (
    tester,
  ) async {
    final images = [_image('canvas')];
    final container = create(images);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () => GeneratedImageActions(
                  ref,
                ).deleteImage(context, images.single),
                child: const Text('canvas-delete'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('canvas-delete'));
    await tester.pumpAndSettle();
    expect(find.byType(ThemedConfirmDialog), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(
      container.read(imageGenerationNotifierProvider).history.single.id,
      'canvas',
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

GeneratedImage _image(String id, {int? run, int? slot, DateTime? createdAt}) =>
    GeneratedImage(
      id: id,
      bytes: img.encodePng(img.Image(width: 64, height: 64)),
      width: 64,
      height: 64,
      generationRunId: run,
      batchIndex: slot,
      createdAt: createdAt ?? DateTime(2026, 10, 12, 8),
    );
