import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as pixels;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/shortcuts/default_shortcuts.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/services/canvas_pin_repository.dart';
import 'package:nai_launcher/data/models/image/image_stream_chunk.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/canvas_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/canvas_channel_provider.dart';
import 'package:nai_launcher/presentation/providers/canvas_channel_feed_provider.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_contract.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_layer.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_overlay.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_settings.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/image_action_providers.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/providers/simple_output_viewer_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/providers/tips_provider.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_colors.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_feed_layout.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_tile_toolbar.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_world_viewport.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/generation_canvas_controller.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/generation_canvas_view.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_canvas.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import 'package:nai_launcher/presentation/wiring/generation_canvas_wiring.dart';
import 'package:nai_launcher/presentation/wiring/generation_data_wiring.dart';
import 'package:nai_launcher/presentation/wiring/generation_history_actions.dart';
import 'package:nai_launcher/presentation/wiring/generation_wiring.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/shortcuts/shortcut_aware_widget.dart';
import '../../helpers/studio_capture_fonts.dart';
import '../providers/krita/agent_bridge_draft_test.dart'
    show MemoryCharacters, MemoryDraftSettings, EmptyBlocks, OfflineAuth;
import 'generation_data_wiring_test.dart'
    show DataGeneration, DataSubscription, DataShortcuts, DataRecents;
import '../screens/generation/widgets/reference_module_test.dart'
    show prepareGenerationDropTestPlatform;

class _CountingTipDeck extends TipDeck {
  _CountingTipDeck() : super(seed: 23);
  int generatingDraws = 0;
  @override
  Tip draw(TipSurface surface, {DateTime? now}) {
    if (surface == TipSurface.generating) generatingDraws++;
    return super.draw(surface, now: now);
  }
}

void main() {
  prepareGenerationDropTestPlatform();
  late Directory directory;
  late ProviderContainer container;
  late MemoryDraftSettings storage;
  late _CountingTipDeck deck;
  final events = <String>[];
  final bytes = Uint8List.fromList(
    pixels.encodePng(
      pixels.Image(width: 64, height: 96)
        ..clear(pixels.ColorRgb8(40, 100, 190)),
    ),
  );
  GeneratedImage image(int run, [int index = 0]) => GeneratedImage(
    id: '$run-$index',
    bytes: bytes,
    width: 512,
    height: 768,
    generationRunId: run,
    batchIndex: index,
  );
  void publish(ImageGenerationState value) =>
      (container.read(imageGenerationNotifierProvider.notifier)
              as DataGeneration)
          .publish(value);
  CanvasCamera camera() => container.read(generationCanvasCameraProvider);
  ImageGenerationState loading(int run, {int count = 1}) =>
      ImageGenerationState(
        status: GenerationStatus.generating,
        generationRunId: run,
        totalImages: count,
        currentImage: 1,
        batchWidth: 512,
        batchHeight: 768,
      );
  final boundary = GlobalKey();

  setUpAll(loadStudioCaptureFonts);
  setUp(() async {
    events.clear();
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('canvas-wiring-');
    Hive.init(directory.path);
    await Hive.openBox(StorageKeys.settingsBox);
    storage = MemoryDraftSettings();
    deck = _CountingTipDeck();
    storage.values[StorageKeys.canvasReducedMotion] = true;
    container = ProviderContainer(
      overrides: [
        tipDeckProvider.overrideWithValue(deck),
        tipEpochProvider.overrideWith((ref) => Stream.value(0)),
        localStorageServiceProvider.overrideWithValue(storage),
        canvasChannelSeedProvider.overrideWithValue(7),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockLibraryNotifierProvider.overrideWith(EmptyBlocks.new),
        authNotifierProvider.overrideWith(OfflineAuth.new),
        imageGenerationNotifierProvider.overrideWith(DataGeneration.new),
        subscriptionNotifierProvider.overrideWith(DataSubscription.new),
        shortcutConfigNotifierProvider.overrideWith(DataShortcuts.new),
        referencePanelNotifierProvider.overrideWith(DataRecents.new),
        localUpscaleModelsProvider.overrideWith((ref) async => []),
        generationFavoriteImagesProvider.overrideWith((ref) async => {}),
      ],
    );
    container.read(canvasPinnedNotifierProvider.notifier).debugRepository =
        CanvasPinRepository(storage: storage, directory: directory);
    await container.read(promptBlockLibraryNotifierProvider.future);
  });
  tearDown(() async {
    container.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });
  Future<void> pump(
    WidgetTester tester, {
    bool fullPage = false,
    bool shortcutHost = false,
    String language = 'zh',
    bool dark = false,
  }) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            locale: language == 'zh_TW'
                ? const Locale('zh', 'TW')
                : Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: dark ? GeistTheme.dark : GeistTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: Scaffold(
              body: fullPage
                  ? const GenerationWiring()
                  : GenerationWiring(
                      builder:
                          ({required data, required actions, required slots}) =>
                              GenHost(
                                data: data,
                                actions: GenActions.logging(
                                  events.add,
                                ).withChannel(actions.onChannelChanged),
                                slots: slots,
                                child: shortcutHost
                                    ? ShortcutAwareWidget(
                                        contextType: ShortcutContext.generation,
                                        shortcuts: {
                                          ShortcutIds.togglePromptMode: () =>
                                              events.add('host-toggle'),
                                        },
                                        child: const GenCanvas(),
                                      )
                                    : const GenCanvas(),
                              ),
                    ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        MemoryImage(bytes),
        tester.element(find.byType(GenCanvas)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> wheel(WidgetTester tester, Offset delta, {Offset? at}) async {
    final location =
        at ?? tester.getCenter(find.byKey(const Key('gen-canvas')));
    await tester.sendEventToBinding(
      PointerScrollEvent(position: location, scrollDelta: delta),
    );
    await tester.pumpAndSettle();
  }

  void bars() {
    for (final key in ['gen-bar-top', 'gen-bar-info', 'gen-bar-actions']) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }
    expect(find.byType(CanvasEdgeToolbar), findsNothing);
    expect(find.byKey(const ValueKey('canvas-pixel-background')), findsNothing);
  }

  Future<void> capture(WidgetTester tester, String name) async {
    final notice =
        Platform.environment['CAPTURE_CHANNEL_NOTICE'] == '1' &&
        name.startsWith('notice-');
    final welcome =
        Platform.environment['CAPTURE_WELCOME_ALIGNMENT'] == '1' &&
        name.startsWith('welcome-');
    final feedback =
        Platform.environment['CAPTURE_R6_FEEDBACK'] == '1' &&
        name.startsWith('r6-');
    final channel =
        Platform.environment['CAPTURE_CHANNEL_BACKEND'] == '1' &&
        name.startsWith('channel-');
    final oldCompare = Platform.environment['CAPTURE_OLD_COMPARE'] == '1';
    final retiredEntry =
        Platform.environment['CAPTURE_CANVAS_MENU_RETIRED_ENTRY'] == '1';
    final imageMenu = Platform.environment['CAPTURE_CANVAS_IMAGE_MENU'] == '1';
    final contextMenu =
        Platform.environment['CAPTURE_CANVAS_CONTEXT_MENU'] == '1';
    final restored = Platform.environment['CAPTURE_CANVAS_PRESENTATION'] == '1';
    if (!notice &&
        !welcome &&
        !feedback &&
        !channel &&
        !oldCompare &&
        !retiredEntry &&
        !imageMenu &&
        !contextMenu &&
        !restored &&
        Platform.environment['CAPTURE_INFINITE_CANVAS'] != '1') {
      return;
    }
    await tester.runAsync(() async {
      final target =
          boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final snapshot = await target.toImage(pixelRatio: 1);
      final data = await snapshot.toByteData(format: ui.ImageByteFormat.png);
      final area = notice
          ? 'channel-entry-notice-20261015'
          : welcome
          ? 'canvas-welcome-alignment-20261015'
          : feedback
          ? 'feedback-r6-20261015'
          : channel
          ? 'channel-backend-20261015'
          : oldCompare
          ? 'inpaint-old-compare-20261014'
          : retiredEntry
          ? 'canvas-menu-retired-entry-20261014'
          : imageMenu
          ? 'canvas-image-menu-20261014'
          : contextMenu
          ? 'canvas-context-menu-20261014'
          : restored
          ? 'canvas-presentation-20261014'
          : 'infinite-canvas-20261014';
      final file = File('.dart_tool/$area/captures/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
      snapshot.dispose();
    });
  }

  testWidgets('滚轮自动切图后往返报价不闪空，工具条逐帧保持位置', (tester) async {
    final sources = [
      for (final (run, steps) in [(60, 28), (61, 50)])
        GeneratedImage(
          id: 'quote-scroll-$run',
          bytes: bytes,
          width: 512,
          height: 768,
          generationRunId: run,
          metadata: NaiImageMetadata(
            prompt: 'synthetic scroll source',
            steps: steps,
            model: 'nai-diffusion-4-5-full',
          ),
        ),
    ];
    publish(ImageGenerationState(history: sources));
    await pump(tester);
    final initialBar = tester.getRect(find.byKey(const Key('gen-bar-top')));
    final initialDraft = container.read(generationParamsNotifierProvider);
    final prices = <String, int>{};
    for (final image in sources) {
      await container.read(generatedImageMetadataProvider(image).future);
    }
    await tester.pumpAndSettle();

    for (final image in [...sources, ...sources, ...sources]) {
      final layout = container.read(canvasFeedLayoutProvider);
      final item = layout.items.firstWhere(
        (item) => item.image?.id == image.id,
      );
      final view = tester.getSize(find.byKey(const Key('gen-canvas')));
      final center = camera().worldToScreen(item.worldRect.center);
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(find.byKey(const Key('gen-canvas'))),
          scrollDelta: Offset(0, center.dy - view.height / 2),
        ),
      );
      for (var frame = 0; frame < 16; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          tester.getRect(find.byKey(const Key('gen-bar-top'))),
          initialBar,
        );
        expect(tester.takeException(), isNull);
      }
      final selected = container.read(generationCanvasGroupSelectionProvider);
      expect(selected?.group, 'run:${image.generationRunId}');
      final info = container
          .read(
            generationViewDataProvider(
              AppLocalizations.of(tester.element(find.byType(GenCanvas)))!,
            ),
          )
          .canvas
          .info!;
      expect(info.tileId, image.id);
      expect(info.variationsCostLoading, isFalse);
      expect(info.variationsCost, isNotNull);
      expect(
        container.read(generatedImageMetadataProvider(image)).isLoading,
        isFalse,
      );
      prices[image.id] = info.variationsCost!;
    }
    expect(prices.values.toSet(), hasLength(2));
    expect(container.read(generationParamsNotifierProvider), initialDraft);
    expect(events, isEmpty);
  });

  testWidgets('首张出图前保留同一背景和画布，出图后欢迎内容退场', (tester) async {
    publish(const ImageGenerationState());
    await pump(tester, fullPage: true);
    expect(find.byType(ChannelBackdrop), findsOneWidget);
    expect(find.byKey(const Key('tip-welcome-text')), findsOneWidget);
    final logo = find.byWidgetPredicate(
      (widget) => widget is Image && widget.semanticLabel == 'W.O.F NAI Studio',
    );
    expect(logo, findsOneWidget);
    await tester.runAsync(
      () => precacheImage(
        tester.widget<Image>(logo).image,
        tester.element(find.byType(GenCanvas)),
      ),
    );
    await tester.pump();
    final canvasState = tester.state(find.byType(GenerationCanvasView));
    final backdrop = tester
        .widget<ChannelBackdrop>(find.byType(ChannelBackdrop))
        .data
        .settings;
    await capture(tester, 'r6-before-first-image');
    publish(ImageGenerationState(history: [image(42)]));
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(GenerationCanvasView)), same(canvasState));
    expect(find.byKey(const Key('tip-welcome-text')), findsNothing);
    expect(logo, findsNothing);
    expect(
      tester
          .widget<ChannelBackdrop>(find.byType(ChannelBackdrop))
          .data
          .settings,
      backdrop,
    );
    expect(find.byKey(const ValueKey('canvas-world-viewport')), findsOneWidget);
    await capture(tester, 'r6-after-first-image');
  });

  Finder welcomeLogo() => find.byWidgetPredicate(
    (widget) => widget is Image && widget.semanticLabel == 'W.O.F NAI Studio',
  );

  testWidgets('本次通道提示每轮启动一次，重进和切模式不重弹', (tester) async {
    publish(const ImageGenerationState());
    await pump(tester, fullPage: true);
    final toast = find.byKey(const Key('channel-toast'));
    expect(toast, findsOneWidget);
    await capture(tester, 'notice-first-entry');
    await tester.pumpWidget(const SizedBox());
    await pump(tester, fullPage: true);
    expect(toast, findsNothing);
    await capture(tester, 'notice-return-within-four-seconds');
    final settings = container.read(canvasChannelNotifierProvider.notifier);
    for (final mode in [
      ChannelMode.fixed,
      ChannelMode.random,
      ChannelMode.off,
      ChannelMode.random,
    ]) {
      await settings.set(
        container.read(canvasChannelNotifierProvider).copyWith(mode: mode),
      );
      await tester.pumpAndSettle();
      expect(toast, findsNothing);
    }
    await settings.set(
      container
          .read(canvasChannelNotifierProvider)
          .copyWith(seed: 91, pool: {ChannelTheme.stars, ChannelTheme.wave}),
    );
    await tester.pumpAndSettle();
    expect(toast, findsNothing);
    publish(ImageGenerationState(history: [image(81)]));
    await tester.pumpAndSettle();
    expect(toast, findsNothing);
    await capture(tester, 'notice-after-mode-and-seed-changes');
  });

  for (final initial in [ChannelMode.fixed, ChannelMode.off]) {
    testWidgets('通道提示不被 $initial 提前消耗，首次随机后不重弹', (tester) async {
      publish(const ImageGenerationState());
      final settings = container.read(canvasChannelNotifierProvider.notifier);
      await settings.set(
        container.read(canvasChannelNotifierProvider).copyWith(mode: initial),
      );
      await pump(tester, fullPage: true);
      final toast = find.byKey(const Key('channel-toast'));
      expect(toast, findsNothing);
      await settings.set(
        container
            .read(canvasChannelNotifierProvider)
            .copyWith(mode: ChannelMode.random),
      );
      await tester.pumpAndSettle();
      expect(toast, findsOneWidget);
      await settings.set(
        container
            .read(canvasChannelNotifierProvider)
            .copyWith(mode: ChannelMode.fixed),
      );
      await tester.pumpAndSettle();
      expect(toast, findsNothing);
      await settings.set(
        container
            .read(canvasChannelNotifierProvider)
            .copyWith(mode: ChannelMode.random),
      );
      await tester.pumpAndSettle();
      expect(toast, findsNothing);
    });
  }

  void expectWelcomeCentered(WidgetTester tester) {
    final viewport = tester.getRect(find.byKey(const Key('gen-canvas')));
    final logo = tester.getRect(welcomeLogo());
    final tip = tester.getRect(find.byKey(const Key('tip-welcome-text')));
    final background = tester
        .widget<ChannelBackdrop>(find.byType(ChannelBackdrop))
        .data;
    final quietCenter =
        viewport.left + background.camera.worldToScreen(Offset.zero).dx;
    expect(logo.center.dx, closeTo(viewport.center.dx, .01));
    expect(quietCenter, closeTo(logo.center.dx, .01));
    expect(tip.center.dx, closeTo(quietCenter, .01));
    expect(background.camera.scale, 1);
    expect(logo.left, greaterThanOrEqualTo(quietCenter - 416));
    expect(logo.right, lessThanOrEqualTo(quietCenter + 416));
    expect(tip.left, greaterThanOrEqualTo(quietCenter - 416));
    expect(tip.right, lessThanOrEqualTo(quietCenter + 416));
    final world = tester.widget<CanvasWorldViewport>(
      find.byType(CanvasWorldViewport),
    );
    expect(world.camera.offset, background.camera.offset);
    expect(world.camera.scale, background.camera.scale);
  }

  for (final dark in [false, true]) {
    testWidgets('空态六种背景与 Logo 同轴，缩窗和重进不继承偏移：$dark', (tester) async {
      publish(const ImageGenerationState());
      final controller = container.read(
        generationCanvasCameraProvider.notifier,
      );
      controller.jump(
        const CanvasCamera(offset: Offset(-800, 9000), scale: .4),
        notifyIdle: false,
      );
      await pump(tester, fullPage: true, dark: dark);
      await tester.runAsync(
        () => precacheImage(
          tester.widget<Image>(welcomeLogo()).image,
          tester.element(find.byType(GenCanvas)),
        ),
      );
      await tester.pump();
      expectWelcomeCentered(tester);
      final state = tester.state(find.byType(GenerationCanvasView));
      final settings = container.read(canvasChannelNotifierProvider.notifier);
      for (final theme in ChannelTheme.values) {
        await settings.set(
          container
              .read(canvasChannelNotifierProvider)
              .copyWith(mode: ChannelMode.fixed, fixed: theme, motion: false),
        );
        for (final width in [2240.0, 1280.0]) {
          tester.view.physicalSize = Size(width, width == 2240 ? 1345 : 850);
          await tester.pumpAndSettle();
          expectWelcomeCentered(tester);
          expect(tester.state(find.byType(GenerationCanvasView)), same(state));
          expect(tester.takeException(), isNull);
          await capture(
            tester,
            'welcome-${theme.name}-${dark ? 'dark' : 'light'}-${width.toInt()}',
          );
        }
      }
      await wheel(tester, const Offset(200, 800));
      expectWelcomeCentered(tester);
      await tester.pumpWidget(const SizedBox());
      controller.jump(
        const CanvasCamera(offset: Offset(3000, -7000), scale: .1),
        notifyIdle: false,
      );
      await pump(tester, fullPage: true, dark: dark);
      expectWelcomeCentered(tester);
    });
  }

  testWidgets('首批从空态实际视图接续，完成后正常滚动，清空后恢复居中', (tester) async {
    storage.values[StorageKeys.canvasReducedMotion] = false;
    publish(const ImageGenerationState());
    final controller = container.read(generationCanvasCameraProvider.notifier);
    controller.jump(
      const CanvasCamera(offset: Offset(6000, -9000), scale: .2),
      notifyIdle: false,
    );
    await pump(tester, fullPage: true);
    final before = tester
        .widget<ChannelBackdrop>(find.byType(ChannelBackdrop))
        .data
        .camera;
    publish(loading(71));
    await tester.pump();
    expect(find.byKey(const Key('tip-welcome-text')), findsNothing);
    expect(camera().offset, before.offset);
    expect(camera().scale, before.scale);
    publish(ImageGenerationState(history: [image(71)]));
    await tester.pumpAndSettle();
    final viewport = tester.getRect(find.byKey(const Key('gen-canvas')));
    final item = container.read(canvasFeedLayoutProvider).items.single;
    expect(
      (camera().worldToScreen(item.worldRect.center) -
              Offset(viewport.width / 2, viewport.height / 2 - 10))
          .distance,
      lessThan(1),
    );
    final settled = camera();
    await wheel(tester, const Offset(0, 80));
    expect(camera().offset, settled.offset - const Offset(0, 80));
    publish(const ImageGenerationState());
    await tester.pumpAndSettle();
    expectWelcomeCentered(tester);
  });

  testWidgets('主画布显式启用通道，开关不重挂图块，设置回调落到存储', (tester) async {
    publish(ImageGenerationState(history: [image(1), image(1, 1)]));
    await pump(tester);
    expect(find.byType(ChannelBackdrop), findsOneWidget);
    expect(find.byType(ChannelOverlay), findsOneWidget);
    final backdrop = tester
        .widget<ChannelBackdrop>(find.byType(ChannelBackdrop))
        .data;
    final feed = container.read(canvasChannelFeedProvider);
    expect(backdrop.batches, same(feed.batches));
    expect(backdrop.camera.offset, camera().offset);
    expect(backdrop.camera.scale, camera().scale);
    expect(
      backdrop.settings.motion,
      isFalse,
    ); // Application reduced-motion setting.
    final tile = find.byKey(const Key('gen-tile-1-0'));
    final element = tester.element(tile);
    await tester.tap(find.byKey(const Key('gen-display')));
    await tester.pumpAndSettle();
    final section = tester.widget<ChannelSettingsSection>(
      find.byType(ChannelSettingsSection),
    );
    section.onChanged(section.settings.copyWith(mode: ChannelMode.off));
    await tester.pumpAndSettle();
    expect(find.byType(ChannelBackdrop), findsNothing);
    expect(find.byType(ChannelOverlay), findsNothing);
    expect(tester.element(tile), same(element));
    expect(
      storage.values.containsKey(StorageKeys.canvasChannelPreferences),
      isTrue,
    );
    expect(container.read(canvasChannelNotifierProvider).mode, ChannelMode.off);
  });

  for (final kind in [PointerDeviceKind.mouse, PointerDeviceKind.touch]) {
    testWidgets('导航尺点击与拖动保持缩放及选中，锁相机时忽略 $kind', (tester) async {
      publish(ImageGenerationState(history: [image(1), image(2)]));
      await pump(tester);
      final before = camera();
      final focus = container.read(generationCanvasGroupSelectionProvider);
      final selection = container.read(generationPreviewSelectionProvider);
      final rect = tester.getRect(find.byKey(const Key('channel-scrubber')));
      final gesture = await tester.startGesture(
        rect.topLeft + Offset(12, rect.height * .6),
        kind: kind,
      );
      await tester.pump();
      await gesture.moveTo(rect.topLeft + Offset(12, rect.height * .8));
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 20));
      final feed = container.read(canvasChannelFeedProvider);
      final top = feed.batches.first.rect.top - 1600;
      final bottom = feed.batches.last.rect.bottom + 1600;
      final view = tester.getSize(find.byKey(const Key('gen-canvas')));
      final center = camera().screenToWorld(view.center(Offset.zero));
      expect(center.dx, closeTo(0, .001));
      expect(center.dy, closeTo(top + (bottom - top) * .8, .001));
      expect(camera().scale, before.scale);
      final jumped = camera();
      await tester.pump(const Duration(seconds: 3));
      expect(camera().offset, jumped.offset);
      expect(container.read(generationCanvasGroupSelectionProvider), focus);
      expect(container.read(generationPreviewSelectionProvider), selection);
      await container
          .read(canvasLockCameraNotifierProvider.notifier)
          .setLocked(true);
      await tester.tap(find.byKey(const Key('channel-scrubber')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(camera().offset, jumped.offset);
      expect(camera().scale, jumped.scale);
    });
  }

  testWidgets('通道叠层透传图块点击、滚轮、Ctrl 缩放与 WASD', (tester) async {
    publish(ImageGenerationState(history: [image(1), image(1, 1)]));
    await pump(tester);
    await tester.tap(find.byKey(const Key('gen-tile-1-1')));
    await tester.pumpAndSettle();
    expect(container.read(generationPreviewSelectionProvider), '1-1');
    final before = camera();
    await wheel(tester, const Offset(0, 45));
    expect(camera().offset, before.offset - const Offset(0, 45));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await wheel(tester, const Offset(0, -50));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(camera().scale, greaterThan(before.scale));
    final moved = camera().offset;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyW);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyW);
    expect(camera().offset, isNot(moved));
    expect(tester.takeException(), isNull);
  });

  testWidgets('未显式启用的嵌入视图不出现通道', (tester) async {
    final data = ImageGenerationState(history: [image(1)]);
    publish(data);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: GeistTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GenerationCanvasView(
            generationState: data,
            tileBuilder: (_, _, _, _, _) => const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChannelBackdrop), findsNothing);
    expect(find.byType(ChannelOverlay), findsNothing);
  });

  testWidgets('生成占位与首张结果映射到真实批次数量和时间', (tester) async {
    publish(loading(71, count: 2));
    await pump(tester);
    var data = tester
        .widget<ChannelBackdrop>(find.byType(ChannelBackdrop))
        .data;
    expect(data.generating, isTrue);
    expect(data.batches.first.count, 2);
    expect(data.batches.first.pending, isTrue);
    expect(data.batches.first.time, isNull);
    final result = image(71);
    publish(
      ImageGenerationState(
        status: GenerationStatus.generating,
        generationRunId: 71,
        totalImages: 2,
        currentImage: 2,
        currentImages: [result],
        batchWidth: 512,
        batchHeight: 768,
      ),
    );
    await tester.pumpAndSettle();
    data = tester.widget<ChannelBackdrop>(find.byType(ChannelBackdrop)).data;
    expect(data.batches.first.count, 2);
    expect(data.batches.first.pending, isFalse);
    expect(data.batches.first.time, result.createdAt);
  });

  for (final language in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      testWidgets('真实通道设置、导航提示与本次顺序 $language dark=$dark', (tester) async {
        publish(ImageGenerationState(history: [image(1), image(2)]));
        await pump(tester, fullPage: true, language: language, dark: dark);
        expect(find.byKey(const Key('channel-toast')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await capture(tester, 'channel-$language-$dark-canvas');
        await tester.tap(find.byKey(const Key('gen-display')));
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(const Key('gen-display-popover'))).width,
          316,
        );
        expect(find.byType(ChannelSettingsSection), findsOneWidget);
        expect(tester.takeException(), isNull);
        await capture(tester, 'channel-$language-$dark-settings');
        GenScope.of(
          tester.element(find.byType(GenCanvas)),
        ).controller.closePopover();
        await tester.pumpAndSettle();
        final pointer = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await pointer.addPointer(location: Offset.zero);
        await pointer.moveTo(
          tester.getCenter(find.byKey(const Key('channel-scrubber'))),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('channel-scrub-tip')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await capture(tester, 'channel-$language-$dark-tip');
        await pointer.removePointer();
      });
    }
  }

  GeneratedImage comparisonImage(String id, {bool masked = true}) {
    final original = Uint8List.fromList(
      pixels.encodePng(
        pixels.Image(width: 64, height: 96)
          ..clear(pixels.ColorRgb8(70, 160, 80)),
      ),
    );
    final mask = pixels.Image(width: 64, height: 96)
      ..clear(pixels.ColorRgb8(0, 0, 0));
    pixels.fillRect(
      mask,
      x1: 20,
      y1: 40,
      x2: 43,
      y2: 51,
      color: pixels.ColorRgb8(255, 255, 255),
    );
    return GeneratedImage(
      id: id,
      bytes: bytes,
      width: 512,
      height: 768,
      generationRunId: 70,
      originalBytes: original,
      inpaintMaskBytes: masked
          ? Uint8List.fromList(pixels.encodePng(mask))
          : null,
    );
  }

  Future<void> settleComparison(WidgetTester tester, String id) async {
    await tester.pump();
    final builders = find.descendant(
      of: find.byKey(Key('gen-original-$id')),
      matching: find.byType(FutureBuilder<Uint8List?>),
    );
    if (builders.evaluate().isNotEmpty) {
      // The isolate is real; its completion callback runs in the widget test's
      // fake zone. Pump between real waits rather than await that fake-zone Future.
      for (
        var attempt = 0;
        attempt < 100 &&
            find.byKey(Key('gen-original-mask-$id')).evaluate().isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
    }
    await tester.pump();
    await tester.runAsync(() async {
      for (final node
          in find
              .descendant(
                of: find.byKey(Key('gen-original-$id')),
                matching: find.byType(Image),
              )
              .evaluate()) {
        await precacheImage((node.widget as Image).image, node);
      }
    });
    await tester.pumpAndSettle();
  }

  for (final language in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      testWidgets('$language dark=$dark OLD 按住原图蒙版、松手恢复且不改相机和结果', (
        tester,
      ) async {
        final result = comparisonImage('old-test');
        publish(ImageGenerationState(history: [result]));
        await pump(tester, language: language, dark: dark);
        expect(find.byKey(const Key('gen-old')), findsOneWidget);
        final before = camera();
        final draft = Map<String, dynamic>.from(storage.values);
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('gen-old'))),
          kind: PointerDeviceKind.mouse,
        );
        await settleComparison(tester, result.id);
        expect(find.byKey(Key('gen-original-${result.id}')), findsOneWidget);
        final mask = tester.widget<Image>(
          find.byKey(Key('gen-original-mask-${result.id}')),
        );
        final overlay = pixels.decodePng((mask.image as MemoryImage).bytes)!;
        expect(overlay.getPixel(0, 0).a, 0);
        expect(overlay.getPixel(30, 45).a, 77);
        expect(camera().offset, before.offset);
        expect(camera().scale, before.scale);
        expect(
          container.read(imageGenerationNotifierProvider).history.single,
          same(result),
        );
        expect(storage.values, draft);
        expect(events, isEmpty);
        if (language == 'zh') {
          await capture(tester, 'studio-old-held-${dark ? 'dark' : 'light'}');
        }
        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.byKey(Key('gen-original-${result.id}')), findsNothing);
        await tester.tap(find.byKey(const Key('gen-save')));
        await tester.tap(find.byKey(const Key('gen-copy')));
        expect(events, ['onSaveImage(old-test)', 'onCopyImage(old-test)']);
        expect(
          container.read(imageGenerationNotifierProvider).history.single.bytes,
          same(bytes),
        );
        expect(tester.takeException(), isNull);
        if (language == 'zh') {
          await capture(tester, 'studio-result-${dark ? 'dark' : 'light'}');
        }
      });
    }
  }

  testWidgets('OLD 简单视图、无蒙版、移出后释放和取消均恢复', (tester) async {
    final result = comparisonImage('simple-old', masked: false);
    publish(ImageGenerationState(history: [result]));
    await container
        .read(simpleOutputViewerNotifierProvider.notifier)
        .setSimple(true);
    await pump(tester);
    final old = find.byKey(const Key('gen-old'));
    var gesture = await tester.startGesture(
      tester.getCenter(old),
      kind: PointerDeviceKind.mouse,
    );
    await settleComparison(tester, result.id);
    expect(find.byKey(Key('gen-original-${result.id}')), findsOneWidget);
    expect(find.byKey(Key('gen-original-mask-${result.id}')), findsNothing);
    await gesture.moveTo(const Offset(20, 20));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(Key('gen-original-${result.id}')), findsNothing);
    gesture = await tester.startGesture(
      tester.getCenter(old),
      kind: PointerDeviceKind.mouse,
    );
    await settleComparison(tester, result.id);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(find.byKey(Key('gen-original-${result.id}')), findsNothing);
  });

  testWidgets('OLD 换图、新生成和回到原图不会留住旧预览', (tester) async {
    final first = comparisonImage('first-old');
    final second = comparisonImage('second-old');
    publish(ImageGenerationState(history: [first, second]));
    await pump(tester);
    final history = container.read(generationHistoryActionsProvider);
    history.focusTile(first.id);
    await tester.pumpAndSettle();
    var gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('gen-old'))),
    );
    await settleComparison(tester, first.id);
    expect(find.byKey(Key('gen-original-${first.id}')), findsOneWidget);
    expect(find.byKey(Key('gen-original-${second.id}')), findsNothing);
    history.focusTile(second.id);
    await tester.pumpAndSettle();
    expect(find.byKey(Key('gen-original-${first.id}')), findsNothing);
    await gesture.up();
    history.focusTile(first.id);
    await tester.pumpAndSettle();
    expect(find.byKey(Key('gen-original-${first.id}')), findsNothing);
    gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('gen-old'))),
    );
    await settleComparison(tester, first.id);
    publish(loading(71).copyWith(history: [first, second]));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('gen-original-${first.id}')), findsNothing);
    await gesture.up();
    publish(ImageGenerationState(history: [first, second]));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('gen-original-${first.id}')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('OLD 支持空格按住，失焦恢复，右键不进入对比', (tester) async {
    final result = comparisonImage('keyboard-old', masked: false);
    publish(ImageGenerationState(history: [result]));
    await pump(tester);
    await tester.tap(find.byKey(const Key('gen-old')));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await settleComparison(tester, result.id);
    expect(find.byKey(Key('gen-original-${result.id}')), findsOneWidget);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.byKey(Key('gen-original-${result.id}')), findsNothing);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(find.byKey(Key('gen-original-${result.id}')), findsNothing);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('gen-old'))),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await tester.pump();
    expect(find.byKey(Key('gen-original-${result.id}')), findsNothing);
    await gesture.up();
    expect(events, isEmpty);
  });

  testWidgets('无原图与失败快照不出现 OLD', (tester) async {
    publish(ImageGenerationState(history: [image(1)]));
    await pump(tester);
    expect(find.byKey(const Key('gen-old')), findsNothing);
    final result = comparisonImage('failed-old');
    publish(
      ImageGenerationState(
        history: [
          GeneratedImage(
            id: result.id,
            bytes: bytes,
            width: 512,
            height: 768,
            kind: GeneratedImageKind.failedStreamSnapshot,
            originalBytes: result.originalBytes,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gen-old')), findsNothing);
  });

  testWidgets('OLD 360px 窄画布保留完整种子，底部两条不重叠、不遮住图片', (tester) async {
    final source = comparisonImage('narrow-old', masked: false);
    final result = GeneratedImage(
      id: source.id,
      bytes: bytes,
      width: 512,
      height: 768,
      originalBytes: source.originalBytes,
      metadata: const NaiImageMetadata(seed: 4294967295),
    );
    publish(ImageGenerationState(history: [result]));
    await pump(tester);
    tester.view.physicalSize = const Size(360, 600);
    await tester.pumpAndSettle();
    final info = tester.getRect(find.byKey(const Key('gen-bar-info')));
    final actions = tester.getRect(find.byKey(const Key('gen-bar-actions')));
    final tile = tester.getRect(find.byKey(Key('gen-tile-${result.id}')));
    expect(info.overlaps(actions), isFalse);
    expect(tile.overlaps(info), isFalse);
    expect(tile.overlaps(actions), isFalse);
    expect(find.text('4294967295'), findsOneWidget);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('gen-old'))),
    );
    await settleComparison(tester, result.id);
    expect(find.byKey(Key('gen-original-${result.id}')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capture(tester, 'studio-old-narrow');
    await gesture.up();
  });

  testWidgets('真实页面默认挂无限画布，仅保留新图块和三条工具条', (tester) async {
    publish(ImageGenerationState(history: [image(2), image(1)]));
    await pump(tester, fullPage: true);
    expect(find.byType(GenerationCanvasWiring), findsOneWidget);
    expect(find.byType(CanvasWorldViewport), findsOneWidget);
    expect(find.byType(GenCanvasTile), findsWidgets);
    bars();
    await capture(tester, 'full-page-light');
  });
  testWidgets('简单模式不挂相机，切回后定位原选择且可反复切换', (tester) async {
    publish(ImageGenerationState(history: [image(2), image(1)]));
    await container
        .read(simpleOutputViewerNotifierProvider.notifier)
        .setSimple(true);
    await pump(tester);
    expect(find.byType(GenerationCanvasView), findsNothing);
    container.read(generationHistoryActionsProvider).focusTile(image(1).id);
    for (var i = 0; i < 3; i++) {
      await container
          .read(simpleOutputViewerNotifierProvider.notifier)
          .setSimple(false);
      await tester.pumpAndSettle();
      expect(find.byKey(Key('gen-tile-${image(1).id}')), findsOneWidget);
      expect(container.read(generationPreviewSelectionProvider), image(1).id);
      await container
          .read(simpleOutputViewerNotifierProvider.notifier)
          .setSimple(true);
      await tester.pumpAndSettle();
      expect(find.byType(GenerationCanvasView), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets('滚轮平移和 Ctrl 缩放不移动外围工具条，缩放锚定光标', (tester) async {
    publish(ImageGenerationState(history: [image(2), image(1)]));
    await pump(tester);
    bars();
    final barRect = tester.getRect(find.byKey(const Key('gen-bar-top')));
    final before = camera();
    await wheel(tester, const Offset(13, 47));
    expect(camera().offset, before.offset - const Offset(13, 47));
    expect(camera().scale, before.scale);
    const at = Offset(500, 350);
    final world = camera().screenToWorld(at);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await wheel(tester, const Offset(0, -20), at: at);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    expect(camera().scale, greaterThan(before.scale));
    expect((camera().screenToWorld(at) - world).distance, lessThan(.001));
    expect(tester.getRect(find.byKey(const Key('gen-bar-top'))), barRect);
  });
  testWidgets('Shift 滚轮横移，锁相机阻止手动移动但历史定位仍有效', (tester) async {
    publish(ImageGenerationState(history: [image(2), image(1)]));
    await pump(tester);
    final before = camera();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await wheel(tester, const Offset(0, 40));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(camera().offset, before.offset - const Offset(40, 0));
    await container
        .read(canvasLockCameraNotifierProvider.notifier)
        .setLocked(true);
    final locked = camera();
    await wheel(tester, const Offset(0, 80));
    expect(camera(), locked);
    container.read(generationHistoryActionsProvider).focusBatch('run:1');
    await tester.pumpAndSettle();
    expect(camera(), isNot(locked));
  });
  testWidgets('单击选图，双击只开一次大图，不退整组', (tester) async {
    publish(ImageGenerationState(history: [image(1), image(1, 1)]));
    await pump(tester);
    final target = find.byKey(Key('gen-tile-${image(1, 1).id}'));
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(container.read(generationPreviewSelectionProvider), image(1, 1).id);
    expect(container.read(generationCanvasGroupSelectionProvider)!.subimage, 1);
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(events.where((event) => event.startsWith('onOpenViewer')), [
      'onOpenViewer(1-1)',
    ]);
    expect(container.read(generationCanvasGroupSelectionProvider)!.subimage, 1);
  });
  testWidgets('Shift 左键拖动图块不选图、不打开大图', (tester) async {
    publish(ImageGenerationState(history: [image(1), image(1, 1)]));
    await pump(tester);
    final selected = container.read(generationPreviewSelectionProvider);
    final before = camera();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.drag(
      find.byKey(Key('gen-tile-${image(1, 1).id}')),
      const Offset(35, 25),
    );
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(camera().offset, isNot(before.offset));
    expect(container.read(generationPreviewSelectionProvider), selected);
    expect(events.where((event) => event.startsWith('onOpenViewer')), isEmpty);
  });
  testWidgets('重复单图定位与历史整组定位都能从移开的相机返回', (tester) async {
    publish(ImageGenerationState(history: [image(1), image(1, 1)]));
    await pump(tester);
    final history = container.read(generationHistoryActionsProvider);
    history.focusTile('1-1');
    await tester.pumpAndSettle();
    final target = camera();
    await wheel(tester, const Offset(0, 90));
    history.focusTile('1-1');
    await tester.pumpAndSettle();
    expect(camera().offset, target.offset);
    expect(camera().scale, target.scale);
    history.focusBatch('run:1');
    await tester.pumpAndSettle();
    expect(
      container.read(generationCanvasGroupSelectionProvider)!.subimage,
      isNull,
    );
    expect(camera().scale, lessThanOrEqualTo(target.scale));
  });
  testWidgets('生成占位到流式到完成保持同一相机和运行身份', (tester) async {
    publish(ImageGenerationState(history: [image(1)]));
    await pump(tester);
    final engine = tester.state(find.byType(GenerationCanvasView));
    publish(
      ImageGenerationState(
        status: GenerationStatus.generating,
        generationRunId: 2,
        history: [image(1)],
        totalImages: 2,
        currentImage: 1,
        batchWidth: 512,
        batchHeight: 768,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(GenerationCanvasView)), same(engine));
    expect(find.byKey(const Key('gen-tile-slot:run:2:0')), findsOneWidget);
    expect(find.byKey(const Key('gen-tile-slot:run:2:1')), findsOneWidget);
    await capture(tester, 'pending-two');
    final selected = camera();
    publish(
      container
          .read(imageGenerationNotifierProvider)
          .copyWith(
            streamPreviewSlots: [
              StreamPreviewSlot(
                imageNumber: 1,
                totalImages: 2,
                progress: .5,
                previewBytes: bytes,
              ),
            ],
          ),
    );
    await tester.pumpAndSettle();
    expect(camera(), selected);
    expect(
      tester
          .widget<GenCanvasTile>(
            find.ancestor(
              of: find.byKey(const Key('gen-tile-slot:run:2:0')),
              matching: find.byType(GenCanvasTile),
            ),
          )
          .tile
          .state,
      GenTileState.streaming,
    );
    publish(
      ImageGenerationState(
        status: GenerationStatus.completed,
        generationRunId: 2,
        currentImages: [image(2), image(2, 1)],
        history: [image(1)],
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(GenerationCanvasView)), same(engine));
    expect(
      container.read(generationCanvasGroupSelectionProvider)!.group,
      'run:2',
    );
    expect(camera(), selected);
  });
  testWidgets('独立固定图区在清空历史后可定位，点击保持 pin 分组身份', (tester) async {
    publish(ImageGenerationState(history: [image(1)]));
    final history = container.read(generationHistoryActionsProvider);
    await tester.runAsync(() => history.pin(image(1).id, true));
    await pump(tester);
    history.clear();
    history.focusPins();
    await tester.pumpAndSettle();
    final target = find.byKey(const Key('gen-tile-1-0'));
    expect(target, findsWidgets);
    // 当前图仍在 display，钉板实例位于当前相机视口。
    final visible = target.hitTestable();
    await tester.tap(visible);
    await tester.pumpAndSettle();
    expect(
      container.read(generationCanvasGroupSelectionProvider)!.group,
      'pin:1-0',
    );
    expect(container.read(canvasPinnedNotifierProvider), {'1-0'});
  });
  testWidgets('工具返回的 display 图与清历史保留图仍显示，不重复入库', (tester) async {
    final kept = image(1);
    publish(
      ImageGenerationState(
        displayImages: [kept],
        displayWidth: 512,
        displayHeight: 768,
      ),
    );
    await pump(tester);
    expect(find.byKey(const Key('gen-tile-1-0')), findsOneWidget);
    expect(container.read(canvasFeedLayoutProvider).items, hasLength(1));
    publish(ImageGenerationState(history: [kept], displayImages: [kept]));
    await tester.pumpAndSettle();
    expect(container.read(canvasFeedLayoutProvider).items, hasLength(1));
    container.read(generationHistoryActionsProvider).clear();
    await tester.pumpAndSettle();
    expect(container.read(imageGenerationNotifierProvider).history, isEmpty);
    expect(find.byKey(const Key('gen-tile-1-0')), findsOneWidget);
  });
  testWidgets('画布有焦点时，自定义 F 快捷键优先交给页面宿主', (tester) async {
    publish(ImageGenerationState(history: [image(1)]));
    await tester.runAsync(() async {
      await container.read(shortcutConfigNotifierProvider.future);
      await container
          .read(shortcutConfigNotifierProvider.notifier)
          .setCustomShortcut(ShortcutIds.togglePromptMode, 'F');
    });
    await pump(tester, shortcutHost: true);
    await tester.tap(find.byKey(const Key('gen-tile-1-0')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.pumpAndSettle();
    expect(events.where((event) => event == 'host-toggle'), hasLength(1));
    await tester.runAsync(
      () => container
          .read(shortcutConfigNotifierProvider.notifier)
          .setEnabled(ShortcutIds.togglePromptMode, false),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('gen-tile-1-0')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    expect(events.where((event) => event == 'host-toggle'), hasLength(1));
  });
  testWidgets('相机连续帧复用已挂载图片，不重新构建或解码图块', (tester) async {
    publish(ImageGenerationState(history: [image(1)]));
    await pump(tester);
    final element = find.byType(GenCanvasTile).evaluate().single;
    final widget = element.widget;
    final imageWidget = find
        .descendant(
          of: find.byType(GenCanvasTile),
          matching: find.byType(Image),
        )
        .evaluate()
        .single
        .widget;
    for (var i = 0; i < 4; i++) {
      container
          .read(generationCanvasCameraProvider.notifier)
          .panBy(const Offset(10, 10));
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(GenCanvasTile).evaluate().single, same(element));
      expect(element.widget, same(widget));
      expect(
        find
            .descendant(
              of: find.byType(GenCanvasTile),
              matching: find.byType(Image),
            )
            .evaluate()
            .single
            .widget,
        same(imageWidget),
      );
    }
  });
  testWidgets('空态、错误和恢复不卸载画布，错误仍由新页面展示', (tester) async {
    await pump(tester);
    final engine = tester.state(find.byType(GenerationCanvasView));
    expect(find.byType(GenCanvasTile), findsNothing);
    publish(
      const ImageGenerationState(
        status: GenerationStatus.error,
        errorMessage: 'test error',
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(GenerationCanvasView)), same(engine));
    final error = find.byKey(const Key('gen-error'));
    expect(error, findsOneWidget);
    expect(
      GenScope.of(tester.element(error)).data.canvas.error!.detail,
      'test error',
    );
    publish(ImageGenerationState(history: [image(1)]));
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(GenerationCanvasView)), same(engine));
    expect(find.byKey(const Key('gen-tile-1-0')), findsOneWidget);
  });
  testWidgets('窗口缩窄重新对焦，图片避开新工具条和底栏', (tester) async {
    publish(ImageGenerationState(history: [image(1)]));
    await pump(tester, fullPage: true);
    tester.view.physicalSize = const Size(1280, 700);
    await tester.pumpAndSettle();
    final viewport = tester.getRect(find.byKey(const Key('gen-canvas')));
    final tile = tester.getRect(find.byKey(const Key('gen-tile-1-0')));
    expect(tile.left, greaterThanOrEqualTo(viewport.left + GenCanvas.pad.left));
    expect(tile.right, lessThanOrEqualTo(viewport.right - GenCanvas.pad.right));
    expect(tile.top, greaterThanOrEqualTo(viewport.top + GenCanvas.pad.top));
    expect(
      tile.bottom,
      lessThanOrEqualTo(viewport.bottom - GenCanvas.pad.bottom),
    );
  });
  testWidgets('局部重绘流式预览继续使用源图与裁片位置合成', (tester) async {
    publish(
      ImageGenerationState(
        status: GenerationStatus.generating,
        generationRunId: 2,
        totalImages: 1,
        currentImage: 1,
        batchWidth: 512,
        batchHeight: 768,
        streamPreviewSlots: [
          StreamPreviewSlot(
            imageNumber: 1,
            totalImages: 1,
            progress: .5,
            previewBytes: bytes,
            inpaintPreviewPlacement: InpaintStreamPreviewPlacement(
              sourceImage: bytes,
              xPercent: .2,
              yPercent: .3,
              widthPercent: .4,
              heightPercent: .4,
            ),
          ),
        ],
      ),
    );
    await pump(tester);
    final scope = tester.widget<GenCanvasTileScope>(
      find.byType(GenCanvasTileScope),
    );
    expect(scope.preview, isNotNull);
    expect(find.byType(ImageFiltered), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2));
    await capture(tester, 'inpaint-stream');
  });
  testWidgets('旧图块回调不选中已移除的图片，也不覆盖最新选择', (tester) async {
    publish(ImageGenerationState(history: [image(1), image(1, 1)]));
    await pump(tester);
    final old = tester.widget<GenCanvasTileScope>(
      find.ancestor(
        of: find.byKey(const Key('gen-tile-1-1')),
        matching: find.byType(GenCanvasTileScope),
      ),
    );
    publish(ImageGenerationState(history: [image(1)]));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('gen-tile-1-0')));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit0);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    final focus = container.read(generationCanvasGroupSelectionProvider);
    expect(focus, isNull);
    final selected = container.read(generationPreviewSelectionProvider);
    old.onFocus();
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(generationCanvasGroupSelectionProvider), focus);
    expect(container.read(generationPreviewSelectionProvider), selected);
    expect(find.byKey(const Key('gen-tile-1-1')), findsNothing);
  });
  testWidgets('旧悬浮动效从 .98 平滑到 1，离开后恢复且不改变相机', (tester) async {
    publish(ImageGenerationState(history: [image(1)]));
    await pump(tester);
    final scale = find.byKey(const ValueKey('canvas-tile-scale:run:1:0'));
    final target = find.byKey(const Key('gen-tile-1-0'));
    expect(tester.widget<AnimatedScale>(scale).scale, .98);
    final width = tester.getRect(target).width;
    final before = camera();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(5, 5));
    await mouse.moveTo(tester.getCenter(target));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(scale).scale, 1);
    expect(tester.getRect(target).width / width, closeTo(1 / .98, .001));
    expect(camera().offset, before.offset);
    expect(camera().scale, before.scale);
    await capture(tester, 'hover-restored');
    await mouse.moveTo(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(scale).scale, .98);
    await mouse.removePointer();
  });
  testWidgets('子图已选中时保持 1 倍，不随移入移出收缩', (tester) async {
    publish(ImageGenerationState(history: [image(1)]));
    await pump(tester);
    await tester.tap(find.byKey(const Key('gen-tile-1-0')));
    await tester.pumpAndSettle();
    final scale = find.byKey(const ValueKey('canvas-tile-scale:run:1:0'));
    expect(tester.widget<AnimatedScale>(scale).scale, 1);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(5, 5));
    await mouse.moveTo(tester.getCenter(find.byKey(const Key('gen-tile-1-0'))));
    await tester.pumpAndSettle();
    await mouse.moveTo(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(scale).scale, 1);
    await mouse.removePointer();
  });
  testWidgets('生成文案跨进度、流式帧、可见剔除保持，同槽位只抽一次', (tester) async {
    publish(loading(2));
    await pump(tester);
    final tip = find.byKey(const Key('canvas-inflight-tip'));
    final text = tester.widget<Text>(tip).data;
    expect(text, isNotEmpty);
    expect(deck.generatingDraws, 1);
    publish(
      container
          .read(imageGenerationNotifierProvider)
          .copyWith(progress: .5, streamPreview: bytes),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(tip).data, text);
    final before = camera();
    container
        .read(generationCanvasCameraProvider.notifier)
        .panBy(const Offset(0, -5000));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tip, findsNothing);
    container.read(generationCanvasCameraProvider.notifier).jump(before);
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.widget<Text>(tip).data, text);
    expect(deck.generatingDraws, 1);
    await capture(tester, 'stable-generating-tip');
    publish(loading(3));
    await tester.pumpAndSettle();
    expect(deck.generatingDraws, 2);
  });
  testWidgets('生成动效跟随减少动态设置，停止动画仍显示文案', (tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('zh'),
          home: Scaffold(body: Center(child: CanvasGeneratingContent())),
        ),
      ),
    );
    await tester.pump();
    final animated = find.descendant(
      of: find.byType(CanvasGeneratingContent),
      matching: find.byType(AnimatedBuilder),
    );
    final animation =
        tester.widget<AnimatedBuilder>(animated).animation
            as AnimationController;
    expect(animation.isAnimating, isFalse);
    await container
        .read(canvasReducedMotionNotifierProvider.notifier)
        .setReduced(false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(animation.isAnimating, isTrue);
    await container
        .read(canvasReducedMotionNotifierProvider.notifier)
        .setReduced(true);
    await tester.pump();
    expect(animation.isAnimating, isFalse);
    expect(find.byKey(const Key('canvas-inflight-tip')), findsOneWidget);
  });
  testWidgets('固定角标、变体原图和组张数重新接回，缩放时固定角标恒定', (tester) async {
    final original = GeneratedImage(
      id: 'original',
      bytes: bytes,
      width: 512,
      height: 768,
      generationRunId: 1,
      batchIndex: 0,
      isVariationOriginal: true,
    );
    publish(ImageGenerationState(history: [original, image(1, 1)]));
    await tester.runAsync(
      () => container
          .read(generationHistoryActionsProvider)
          .pin(original.id, true),
    );
    await pump(tester);
    final item = find.byKey(const ValueKey('canvas-tile:run:1:0'));
    expect(
      find.descendant(
        of: item,
        matching: find.byKey(
          const ValueKey('canvas-variation-original:original'),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: item,
        matching: find.byKey(const ValueKey('canvas-pin:original')),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('canvas-batch-count:run:1')),
      findsOneWidget,
    );
    final pin = find.descendant(
      of: item,
      matching: find.byIcon(Icons.push_pin),
    );
    final width = tester.getRect(pin).width;
    final before = camera();
    container
        .read(generationCanvasCameraProvider.notifier)
        .jump(CanvasCamera(offset: before.offset, scale: before.scale * 2));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.getRect(pin).width, closeTo(width, .001));
    await capture(tester, 'restored-badges');
  });
  testWidgets('右击未选中图的菜单操作准确指向该图，无真实请求', (tester) async {
    publish(ImageGenerationState(history: [image(1), image(1, 1)]));
    await pump(tester);
    await tester.tap(
      find.byKey(const Key('gen-tile-1-1')),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    final selected = container.read(generationPreviewSelectionProvider);
    expect(find.byKey(const Key('gen-canvas-menu-save')), findsOneWidget);
    await capture(tester, 'restored-context-menu');
    await tester.tap(find.byKey(const Key('gen-canvas-menu-save')));
    await tester.pumpAndSettle();
    expect(events, contains('onSaveImage(1-1)'));
    expect(container.read(generationPreviewSelectionProvider), selected);
    await tester.tap(
      find.byKey(const Key('gen-tile-1-1')),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('gen-canvas-menu-delete')));
    await tester.pumpAndSettle();
    expect(events, contains('onDeleteImages([1-1])'));
  });
  for (final simple in [false, true]) {
    testWidgets('${simple ? '简单模式' : '无限画布'}正中央焦点图右击显示菜单且指向本图', (tester) async {
      publish(ImageGenerationState(history: [image(1)]));
      await container
          .read(simpleOutputViewerNotifierProvider.notifier)
          .setSimple(simple);
      await pump(tester);
      final target = find.byKey(const Key('gen-tile-1-0'));
      final center = tester.getCenter(find.byKey(const Key('gen-canvas')));
      expect(tester.getRect(target).contains(center), isTrue);
      final selected = container.read(generationPreviewSelectionProvider);
      await tester.tapAt(center, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gen-canvas-menu-copy')), findsOneWidget);
      expect(events, isEmpty);
      expect(container.read(generationPreviewSelectionProvider), selected);
      await capture(
        tester,
        simple ? 'simple-center-menu' : 'canvas-center-menu',
      );
      await tester.tap(find.byKey(const Key('gen-canvas-menu-copy')));
      await tester.pumpAndSettle();
      expect(events, ['onCopyImage(1-0)']);
      await tester.tapAt(
        tester.getTopLeft(find.byKey(const Key('gen-canvas'))) +
            const Offset(20, 100),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gen-canvas-menu-copy')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('切换画布模式后右键保持目标图，生成槽不会弹图片菜单', (tester) async {
    publish(loading(2).copyWith(history: [image(1)]));
    await pump(tester);
    for (final simple in [false, true, false]) {
      await container
          .read(simpleOutputViewerNotifierProvider.notifier)
          .setSimple(simple);
      container.read(generationHistoryActionsProvider).focusTile('1-0');
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('gen-tile-1-0')),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gen-canvas-menu-copy')), findsOneWidget);
      await tester.tap(find.byKey(const Key('gen-canvas-menu-copy')));
      await tester.pumpAndSettle();
      container.read(generationHistoryActionsProvider).focusBatch('run:2');
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('gen-tile-slot:run:2:0')),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gen-canvas-menu-copy')), findsNothing);
    }
    expect(events, List.filled(3, 'onCopyImage(1-0)'));
    expect(tester.takeException(), isNull);
  });
  testWidgets('生成期间右键禁用派生入口，保留成图保存和查看', (tester) async {
    publish(loading(2).copyWith(history: [image(1)]));
    await pump(tester);
    container.read(generationHistoryActionsProvider).focusBatch('run:1');
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('gen-tile-1-0')),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('gen-canvas-menu-edit-group')));
    await tester.pumpAndSettle();
    final disabled = tester.widget<MenuItemButton>(
      find.byKey(const Key('gen-canvas-menu-variations')),
    );
    expect(disabled.onPressed, isNull);
    expect(
      tester
          .widget<MenuItemButton>(find.byKey(const Key('gen-canvas-menu-save')))
          .onPressed,
      isNotNull,
    );
    await tester.ensureVisible(
      find.byKey(const Key('gen-canvas-menu-variations')),
    );
    await tester.tap(find.byKey(const Key('gen-canvas-menu-variations')));
    await tester.pumpAndSettle();
    expect(events.where((event) => event.startsWith('onVariations')), isEmpty);
  });
  testWidgets('失败快照仍渲染原图片与状态标签，双击可查看，派生保存禁用', (tester) async {
    final failed = GeneratedImage(
      id: 'failed',
      bytes: bytes,
      width: 512,
      height: 768,
      generationRunId: 1,
      kind: GeneratedImageKind.failedStreamSnapshot,
    );
    publish(ImageGenerationState(history: [failed]));
    await pump(tester);
    final target = find.byKey(const Key('gen-tile-failed'));
    expect(
      find.descendant(of: target, matching: find.byType(Image)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('canvas-failed-snapshot:failed')),
      findsOneWidget,
    );
    await tester.tap(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(events, contains('onOpenViewer(failed)'));
    await tester.tap(target, buttons: kSecondaryMouseButton);
    await tester.pumpAndSettle();
    for (final key in ['save', 'copy', 'img2img']) {
      expect(
        tester
            .widget<MenuItemButton>(find.byKey(Key('gen-canvas-menu-$key')))
            .onPressed,
        isNull,
      );
    }
    await tester.tap(find.byKey(const Key('gen-canvas-menu-edit-group')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<MenuItemButton>(
            find.byKey(const Key('gen-canvas-menu-variations')),
          )
          .onPressed,
      isNull,
    );
    await capture(tester, 'failed-frame-retained');
  });
  for (final language in ['zh', 'en', 'ja', 'ko', 'zh_TW']) {
    for (final dark in [false, true]) {
      testWidgets('$language ${dark ? 'dark' : 'light'} 图片菜单双快捷按钮、详情下删除及分层', (
        tester,
      ) async {
        publish(ImageGenerationState(history: [image(1)]));
        await pump(tester, language: language, dark: dark);
        await tester.tap(
          find.byKey(const Key('gen-tile-1-0')),
          buttons: kSecondaryMouseButton,
        );
        await tester.pumpAndSettle();
        final save = tester.getRect(
          find.byKey(const Key('gen-canvas-menu-save')),
        );
        final copy = tester.getRect(
          find.byKey(const Key('gen-canvas-menu-copy')),
        );
        final detail = tester.getRect(
          find.byKey(const Key('gen-canvas-menu-viewer')),
        );
        final trash = find.byKey(const Key('gen-canvas-menu-delete'));
        expect(save.top, closeTo(copy.top, .001));
        expect(save.right, lessThan(copy.left));
        expect(tester.getRect(trash).top, closeTo(detail.bottom, .001));
        expect(
          find.descendant(
            of: trash,
            matching: find.byIcon(Icons.delete_outline),
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key('gen-canvas-menu-edit')), findsNothing);
        expect(find.byKey(const Key('gen-canvas-menu-reveal')), findsNothing);
        final button = tester.widget<MenuItemButton>(trash);
        final colors = tester.element(trash).ui;
        expect(button.style!.foregroundColor!.resolve({}), colors.error);
        expect(
          tester
              .widget<MenuAnchor>(find.byKey(const Key('image-action-menu')))
              .style!
              .backgroundColor!
              .resolve({}),
          colors.raised,
        );
        final regular = tester.widget<MenuItemButton>(
          find.byKey(const Key('gen-canvas-menu-viewer')),
        );
        expect(regular.style!.fixedSize!.resolve({})!.height, 34);
        expect(
          regular.style!.textStyle!.resolve({})!.fontWeight,
          FontWeight.w400,
        );
        await capture(
          tester,
          'compact-menu-$language-${dark ? 'dark' : 'light'}',
        );
        await tester.tap(find.byKey(const Key('gen-canvas-menu-edit-group')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('gen-canvas-menu-inpaint')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('gen-canvas-menu-upscale')),
          findsOneWidget,
        );
        await capture(tester, 'edit-menu-$language-${dark ? 'dark' : 'light'}');
        await tester.tap(find.byKey(const Key('gen-canvas-menu-edit')));
        await tester.pumpAndSettle();
        expect(events, ['onEditImage(1-0)']);
        expect(find.byKey(const Key('image-action-menu')), findsNothing);
        await tester.tap(
          find.byKey(const Key('gen-tile-1-0')),
          buttons: kSecondaryMouseButton,
        );
        await tester.pumpAndSettle();
        final more = find.byKey(const Key('gen-canvas-menu-more-group'));
        await tester.tap(more);
        await tester.pumpAndSettle();
        expect(tester.widget<SubmenuButton>(more).menuChildren, hasLength(3));
        for (final key in ['precise-library', 'reveal', 'krita']) {
          expect(find.byKey(Key('gen-canvas-menu-$key')), findsOneWidget);
        }
        expect(
          find.byKey(const Key('gen-canvas-menu-block-library')),
          findsNothing,
        );
        await capture(tester, 'more-menu-$language-${dark ? 'dark' : 'light'}');
        await tester.tap(find.byKey(const Key('gen-canvas-menu-reveal')));
        await tester.pumpAndSettle();
        expect(events, ['onEditImage(1-0)', 'onReveal(1-0)']);
        expect(find.byKey(const Key('image-action-menu')), findsNothing);
        expect(tester.takeException(), isNull);
      });
      testWidgets('$language ${dark ? 'dark' : 'light'} 生成文案实绘和布局', (
        tester,
      ) async {
        publish(loading(2, count: 2));
        await pump(tester, fullPage: true, language: language, dark: dark);
        expect(find.byKey(const Key('canvas-inflight-tip')), findsNWidgets(2));
        expect(deck.generatingDraws, 2);
        for (final element in find.byType(CanvasGeneratingContent).evaluate()) {
          final widget = element.widget as CanvasGeneratingContent;
          final text = widget.tip!.text(element.l10n);
          expect(
            find.descendant(
              of: find.byWidget(widget),
              matching: find.text(text),
            ),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
        await capture(tester, 'tips-$language-${dark ? 'dark' : 'light'}');
      });
    }
  }
  for (final language in ['zh', 'en', 'ja', 'ko', 'zh_TW']) {
    for (final dark in [false, true]) {
      testWidgets('$language ${dark ? 'dark' : 'light'} 新页面完整挂载与缩窄', (
        tester,
      ) async {
        publish(ImageGenerationState(history: [image(1), image(1, 1)]));
        await pump(tester, fullPage: true, language: language, dark: dark);
        bars();
        tester.view.physicalSize = const Size(1280, 850);
        await tester.pumpAndSettle();
        final viewport = tester.getRect(find.byKey(const Key('gen-canvas')));
        final info = tester.getRect(find.byKey(const Key('gen-bar-info')));
        expect(viewport.contains(info.center), isTrue);
        expect(tester.takeException(), isNull);
        await capture(tester, '$language-${dark ? 'dark' : 'light'}-narrow');
      });
    }
  }
}
