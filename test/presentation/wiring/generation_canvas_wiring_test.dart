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
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/canvas_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/providers/simple_output_viewer_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/providers/tips_provider.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_controls.dart';
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
    show DataGeneration, DataSubscription, DataShortcuts;
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
        localStorageServiceProvider.overrideWithValue(storage),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockLibraryNotifierProvider.overrideWith(EmptyBlocks.new),
        authNotifierProvider.overrideWith(OfflineAuth.new),
        imageGenerationNotifierProvider.overrideWith(DataGeneration.new),
        subscriptionNotifierProvider.overrideWith(DataSubscription.new),
        shortcutConfigNotifierProvider.overrideWith(DataShortcuts.new),
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
            body: RepaintBoundary(
              key: boundary,
              child: fullPage
                  ? const GenerationWiring()
                  : GenerationWiring(
                      builder:
                          ({required data, required actions, required slots}) =>
                              GenHost(
                                data: data,
                                actions: GenActions.logging(events.add),
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
    final restored = Platform.environment['CAPTURE_CANVAS_PRESENTATION'] == '1';
    if (!restored && Platform.environment['CAPTURE_INFINITE_CANVAS'] != '1') {
      return;
    }
    await tester.runAsync(() async {
      final target =
          boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final snapshot = await target.toImage(pixelRatio: 1);
      final data = await snapshot.toByteData(format: ui.ImageByteFormat.png);
      final area = restored
          ? 'canvas-presentation-20261014'
          : 'infinite-canvas-20261014';
      final file = File('.dart_tool/$area/captures/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
      snapshot.dispose();
    });
  }

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
    final disabled = tester.widget<UiPressable>(
      find.byKey(const Key('gen-canvas-menu-variations')),
    );
    expect(disabled.onTap, isNull);
    expect(
      tester
          .widget<UiPressable>(find.byKey(const Key('gen-canvas-menu-save')))
          .onTap,
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
    for (final key in ['save', 'copy', 'img2img', 'variations']) {
      expect(
        tester
            .widget<UiPressable>(find.byKey(Key('gen-canvas-menu-$key')))
            .onTap,
        isNull,
      );
    }
    await capture(tester, 'failed-frame-retained');
  });
  for (final language in ['zh', 'en', 'ja', 'ko', 'zh_TW']) {
    for (final dark in [false, true]) {
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
