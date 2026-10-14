import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as pixels;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/datasources/remote/nai_image_enhancement_api_service.dart';
import 'package:nai_launcher/data/models/director/director_tool_type.dart';
import 'package:nai_launcher/data/models/upscale/local_upscale_models.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/services/director/pixel_snap_service.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/director_tools_notifier.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_contract.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_director.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_editor.dart';
import 'package:nai_launcher/presentation/ui/tools/tools_sheets.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/core/editor_state.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/canvas/editor_canvas.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/image_editor_screen.dart';
import 'package:nai_launcher/presentation/wiring/generation_backend.dart';
import 'package:nai_launcher/presentation/wiring/generation_wiring.dart';
import 'package:nai_launcher/presentation/wiring/tools_director_wiring.dart';
import 'package:nai_launcher/presentation/wiring/tools_editor_layer_actions.dart';
import 'package:nai_launcher/presentation/wiring/tools_generation_wiring.dart';

import '../providers/krita/agent_bridge_draft_test.dart'
    show MemoryCharacters, MemoryDraftSettings, EmptyBlocks;
import '../screens/generation/widgets/reference_module_test.dart'
    show prepareGenerationDropTestPlatform;
import 'generation_backend_test.dart'
    show MemoryGenerationPlatform, SwitchingAuth;
import 'generation_data_wiring_test.dart'
    show DataGeneration, DataSubscription, DataShortcuts;
import 'generation_reference_imports_test.dart' show ImportStorage;
import '../../helpers/studio_capture_fonts.dart';

class _Subscription extends DataSubscription {
  @override
  void schedulePostBillingRefresh({Duration delay = Duration.zero}) {}
}

class _Api extends Mock implements NAIImageEnhancementApiService {}

Uint8List png(int width, [int height = 128]) => Uint8List.fromList(
  pixels.encodePng(pixels.Image(width: width, height: height)),
);

void main() {
  prepareGenerationDropTestPlatform();
  setUpAll(() async {
    registerFallbackValue(Uint8List(0));
    await loadStudioCaptureFonts();
  });
  late Directory directory;
  late ProviderContainer container;
  late MemoryGenerationPlatform platform;
  late _Api api;
  late Future<bool> Function(int) approval;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('tools-wiring-');
    Hive.init(directory.path);
    await Hive.openBox(StorageKeys.settingsBox);
    platform = MemoryGenerationPlatform();
    api = _Api();
    approval = (_) async => true;
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockLibraryNotifierProvider.overrideWith(EmptyBlocks.new),
        authNotifierProvider.overrideWith(SwitchingAuth.new),
        subscriptionNotifierProvider.overrideWith(_Subscription.new),
        imageGenerationNotifierProvider.overrideWith(DataGeneration.new),
        shortcutConfigNotifierProvider.overrideWith(DataShortcuts.new),
        generationPlatformProvider.overrideWithValue(platform),
        vibeLibraryStorageServiceProvider.overrideWithValue(ImportStorage()),
        naiImageEnhancementApiServiceProvider.overrideWithValue(api),
        toolsDirectorConfirmationProvider.overrideWithValue(
          (_, cost) => approval(cost),
        ),
        localUpscaleModelsProvider.overrideWith(
          (ref) async => [
            localUpscaleCatalog.first.withInstalled(true),
            advancedUpscaleCatalog.first.withInstalled(true),
          ],
        ),
        toolsWindowsProvider.overrideWithValue(true),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
    await container.read(localUpscaleModelsProvider.future);
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePromptImmediately('current draft');
  });
  tearDown(() async {
    container.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> drain(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'enhance uses locked sheet, backups and request projection; draft source stays intact',
    (tester) async {
      final image = GeneratedImage(
        id: 'source',
        bytes: png(832, 1216),
        width: 832,
        height: 1216,
      );
      (container.read(imageGenerationNotifierProvider.notifier)
              as DataGeneration)
          .publish(
            ImageGenerationState(history: [image], displayImages: [image]),
          );
      final before = container.read(generationParamsNotifierProvider);
      await pump(tester, const GenerationRoute());
      tester
          .widget<GenerationPage>(find.byType(GenerationPage))
          .actions
          .onEnhance(image.id);
      await drain(tester);
      final sheet = tester.widget<ToolsEnhanceSheet>(
        find.byType(ToolsEnhanceSheet),
      );
      expect(sheet.data.scales, containsAll(['1', '1.5', 'local']));
      expect(
        container.read(generationParamsNotifierProvider).sourceImage,
        before.sourceImage,
      );
      expect(
        container.read(generationRequestParamsProvider).sourceImage,
        image.bytes,
      );
      sheet.actions.onScale('1.5');
      await drain(tester);
      expect(container.read(generationRequestParamsProvider).width, 1248);
      expect(
        container.read(generationParamsNotifierProvider).width,
        before.width,
      );
      expect(platform.backups, hasLength(2));
      expect(
        tester
            .widget<GenerationPage>(find.byType(GenerationPage))
            .data
            .canvas
            .info!
            .enhanceCost,
        tester
            .widget<ToolsEnhanceSheet>(find.byType(ToolsEnhanceSheet))
            .data
            .cost,
      );
      tester
          .widget<ToolsEnhanceSheet>(find.byType(ToolsEnhanceSheet))
          .actions
          .onClose();
      await drain(tester);
      expect(container.read(toolsSheetProvider), isNull);
      expect(container.read(generationParamsNotifierProvider), before);
      verifyNever(
        () => api.augmentImages(
          any(),
          reqType: any(named: 'reqType'),
          prompt: any(named: 'prompt'),
          defry: any(named: 'defry'),
        ),
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'upscale arrow opens settings; method and SeedVR2 options persist without taking draft image',
    (tester) async {
      final image = GeneratedImage(
        id: 'upscale',
        bytes: png(256),
        width: 256,
        height: 128,
      );
      (container.read(imageGenerationNotifierProvider.notifier)
              as DataGeneration)
          .publish(
            ImageGenerationState(history: [image], displayImages: [image]),
          );
      await pump(tester, const GenerationRoute());
      tester
          .widget<GenerationPage>(find.byType(GenerationPage))
          .actions
          .onUpscaleSettings!();
      await drain(tester);
      var sheet = tester.widget<ToolsUpscaleSheet>(
        find.byType(ToolsUpscaleSheet),
      );
      final cloudOption = sheet.data.backends.singleWhere(
        (b) => b.id == 'novelai',
      );
      expect(cloudOption.title, isNot(cloudOption.detail));
      expect(cloudOption.title, isNot(contains('2')));
      expect(cloudOption.detail, contains('2'));
      sheet.actions.onMethod('seedvr2');
      await drain(tester);
      sheet = tester.widget<ToolsUpscaleSheet>(find.byType(ToolsUpscaleSheet));
      expect(sheet.data.advanced, hasLength(8));
      sheet.actions.onAdvanced('blocksToSwap', 999.0);
      await drain(tester);
      expect(
        container
            .read(imageWorkflowControllerProvider)
            .upscale
            .selectedSeedvr2Options
            .blocksToSwap,
        32,
      );
      expect(
        container.read(generationParamsNotifierProvider).sourceImage,
        isNull,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test(
    'director names, prices, source identities, variants and pixel options map to the real contract',
    () {
      for (final value in DirectorToolType.values) {
        expect(directorTool(toolsDirectorTool(value)), value);
      }
      final source = DirectorSource(
        id: 'input',
        bytes: png(128),
        width: 128,
        height: 128,
      );
      final outputs = [
        for (var i = 0; i < 3; i++)
          GeneratedImage(
            id: 'output-$i',
            bytes: png(64),
            width: 64,
            height: 128,
          ),
      ];
      final data = toolsDirectorView(
        DirectorToolsState(
          sources: [source],
          selectedRunIndex: 0,
          variantIndex: 2,
          runs: [
            DirectorResultRun(
              source: source,
              tool: DirectorToolType.removeBackground,
              images: outputs,
              prompt: 'saved',
              defry: 1,
              emotion: 'happy',
              pixelOptions: const PixelSnapOptions(),
              cost: 8,
            ),
          ],
        ),
        anlas: 20,
        opus: true,
      );
      expect(data.input, source.id);
      expect(data.runs.single.inputId, source.id);
      expect(data.runs.single.images, hasLength(3));
      expect(data.runs.single.variants, hasLength(3));
      expect(data.runs.single.cost, 8);
      expect(data.costs[ToolsDirectorTool.pixelSnap], 0);
      expect(data.variant, 2);
    },
  );

  test(
    'late director API response cannot register results for a cancelled session',
    () async {
      final pending = Completer<List<Uint8List>>();
      when(
        () => api.augmentImages(
          any(),
          reqType: 'bg-removal',
          prompt: null,
          defry: 0,
        ),
      ).thenAnswer((_) => pending.future);
      final controller = container.read(directorToolsNotifierProvider.notifier);
      controller.addSource(png(128));
      var alive = true;
      final task = controller.runTool(canApply: () => alive, quotedCost: 10);
      alive = false;
      pending.complete([png(64)]);
      await task;
      expect(container.read(directorToolsNotifierProvider).runs, isEmpty);
      expect(container.read(imageGenerationNotifierProvider).history, isEmpty);
      expect(container.read(directorToolsNotifierProvider).isRunning, isFalse);
    },
  );

  testWidgets(
    'director callback selects real tool/emotion and dismissing error preserves the chosen run',
    (tester) async {
      await pump(tester, ToolsDirectorWiring(sourceImage: png(128)));
      await drain(tester);
      final page = tester.widget<ToolsDirectorPage>(
        find.byType(ToolsDirectorPage),
      );
      page.actions.onTool(ToolsDirectorTool.emotion);
      page.actions.onEmotion('happy');
      page.actions.onPixel(
        const ToolsPixelOptions(
          palette: ToolsPixelPalette.custom,
          colors: 256,
          upscale: true,
        ),
      );
      await tester.pump();
      final state = container.read(directorToolsNotifierProvider);
      expect(state.selectedTool, DirectorToolType.fixEmotion);
      expect(state.prompt, 'smile');
      expect(state.pixelOptions.colors, 256);
      expect(state.pixelOptions.upscale, isTrue);
      expect(
        container.read(generationParamsNotifierProvider).prompt,
        'current draft',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final change in [
    'tool',
    'source',
    'account-restored',
    'generation',
    'closed',
  ]) {
    testWidgets('director quote cannot submit after $change changes', (
      tester,
    ) async {
      final pending = Completer<bool>();
      approval = (_) => pending.future;
      await pump(tester, ToolsDirectorWiring(sourceImage: png(128)));
      await drain(tester);
      final page = tester.widget<ToolsDirectorPage>(
        find.byType(ToolsDirectorPage),
      );
      page.actions.onRun();
      await tester.pump();
      switch (change) {
        case 'tool':
          container
              .read(directorToolsNotifierProvider.notifier)
              .selectTool(DirectorToolType.colorize);
        case 'source':
          container
              .read(directorToolsNotifierProvider.notifier)
              .addSource(png(256));
        case 'account-restored':
          final auth =
              container.read(authNotifierProvider.notifier) as SwitchingAuth;
          auth.changeAccount();
          auth.changeAccount('account-a');
        case 'generation':
          (container.read(imageGenerationNotifierProvider.notifier)
                  as DataGeneration)
              .publish(
                const ImageGenerationState(status: GenerationStatus.generating),
              );
        case 'closed':
          await tester.pumpWidget(const SizedBox());
      }
      pending.complete(true);
      await tester.pump();
      verifyNever(
        () => api.augmentImages(
          any(),
          reqType: any(named: 'reqType'),
          prompt: any(named: 'prompt'),
          defry: any(named: 'defry'),
        ),
      );
      await tester.pumpWidget(const SizedBox());
    });
  }

  test(
    'dismissing a director failure retains the previous selected output',
    () async {
      when(
        () => api.augmentImages(
          any(),
          reqType: 'bg-removal',
          prompt: null,
          defry: 0,
        ),
      ).thenAnswer((_) async => [png(64)]);
      final controller = container.read(directorToolsNotifierProvider.notifier);
      controller.addSource(png(128));
      await controller.runTool(quotedCost: 5);
      final selected = container
          .read(directorToolsNotifierProvider)
          .selectedResult;
      when(
        () => api.augmentImages(
          any(),
          reqType: 'bg-removal',
          prompt: null,
          defry: 0,
        ),
      ).thenThrow(StateError('offline'));
      await controller.runTool();
      expect(container.read(directorToolsNotifierProvider).error, isNotNull);
      controller.clearError();
      expect(container.read(directorToolsNotifierProvider).error, isNull);
      expect(
        container.read(directorToolsNotifierProvider).selectedResult,
        same(selected),
      );
    },
  );

  testWidgets(
    'director output cannot overwrite a newer draft typed after opening',
    (tester) async {
      when(
        () => api.augmentImages(
          any(),
          reqType: 'bg-removal',
          prompt: null,
          defry: 0,
        ),
      ).thenAnswer((_) async => [png(64)]);
      await pump(tester, ToolsDirectorWiring(sourceImage: png(128)));
      await drain(tester);
      await container.read(directorToolsNotifierProvider.notifier).runTool();
      container
          .read(generationParamsNotifierProvider.notifier)
          .updatePromptImmediately('new user draft');
      await tester.pump();
      tester
          .widget<ToolsDirectorPage>(find.byType(ToolsDirectorPage))
          .actions
          .onUseAsInit();
      await tester.pump();
      expect(
        container.read(generationParamsNotifierProvider).prompt,
        'new user draft',
      );
      expect(
        container.read(generationParamsNotifierProvider).sourceImage,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'new editor mounts actual canvas and tool, focus, mask and zoom callbacks change its engine',
    (tester) async {
      await pump(
        tester,
        ImageEditorScreen(
          initialImage: png(256),
          mode: ImageEditorMode.inpaint,
          debugDisableDropRegion: true,
        ),
      );
      for (
        var i = 0;
        i < 10 && find.byType(ToolsEditorPage).evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        for (var frame = 0; frame < 4; frame++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      }
      expect(find.byType(EditorCanvas), findsOneWidget);
      var page = tester.widget<ToolsEditorPage>(find.byType(ToolsEditorPage));
      page.actions.onTool(ToolsTool.eraser);
      page.actions.onOptions(const ToolsToolOptions(size: 48, square: true));
      page.actions.onMaskLook(
        const ToolsMaskLook(
          color: Colors.red,
          opacity: .2,
          pattern: ToolsMaskPattern.grid,
        ),
      );
      page.actions.onFocusContext(128);
      page.actions.onZoomIn();
      page.actions.onInpaintStrength(.7);
      await tester.pump();
      page = tester.widget<ToolsEditorPage>(find.byType(ToolsEditorPage));
      expect(page.data.tool, ToolsTool.eraser);
      expect(page.data.options.size, 48);
      expect(page.data.options.square, isTrue);
      expect(page.data.mask.pattern, ToolsMaskPattern.grid);
      expect(page.data.inpaint.focusContext, 128);
      expect(page.data.inpaint.strength, .7);
      expect(
        container.read(generationParamsNotifierProvider).inpaintStrength,
        isNot(.7),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );

  testWidgets(
    'HSV preview cannot erase strokes added after the preview began',
    (tester) async {
      await pump(
        tester,
        const ImageEditorScreen(
          initialSize: Size(128, 128),
          debugDisableDropRegion: true,
        ),
      );
      for (
        var i = 0;
        i < 10 && find.byType(ToolsEditorPage).evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      final dynamic session = tester.state(find.byType(ImageEditorScreen));
      final state = session.debugEditorState as EditorState;
      tester
          .widget<ToolsEditorPage>(find.byType(ToolsEditorPage))
          .actions
          .onAdjust(const ToolsAdjust(hue: 45));
      for (var i = 0; i < 10 && state.rasterPreview == null; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(state.rasterPreview, isNotNull);
      final origin = tester.getTopLeft(find.byType(EditorCanvas));
      final start =
          origin +
          (session.debugCanvasToScreen(const Offset(16, 16)) as Offset);
      final end =
          origin +
          (session.debugCanvasToScreen(const Offset(48, 48)) as Offset);
      final gesture = await tester.startGesture(start);
      await tester.pump();
      await gesture.moveTo(end);
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(state.layerManager.activeLayer!.strokes, hasLength(1));
      tester
          .widget<ToolsEditorPage>(find.byType(ToolsEditorPage))
          .actions
          .onAdjustApply();
      await tester.pump();
      expect(state.layerManager.activeLayer!.strokes, hasLength(1));
      expect(state.rasterPreview, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'layer duplicate and merge keep raster pixels; undo restores independent image ownership',
    (tester) async {
      final state = EditorState();
      state.initNewCanvas(const Size(128, 128));
      final first = await tester.runAsync(
        () => state.layerManager.addLayerFromImage(png(128)),
      );
      final second = await tester.runAsync(
        () => state.layerManager.addLayerFromImage(png(128)),
      );
      expect(first!.baseImage, isNotNull);
      state.historyManager.execute(
        ToolsEditorLayerAction(
          (state) => toolsDuplicateLayer(state, first),
          description: 'Duplicate',
        ),
        state,
      );
      final copy = state.layerManager.activeLayer!;
      expect(copy.baseImage, isNotNull);
      expect(copy.id, isNot(first.id));
      state.undo();
      final bottom = state.layerManager.getLayerById(first.id)!;
      final top = state.layerManager.getLayerById(second!.id)!;
      state.historyManager.execute(
        ToolsEditorLayerAction(
          (state) => toolsMergeLayers(state, top, bottom),
          description: 'Merge',
        ),
        state,
      );
      expect(state.layerManager.getLayerById(top.id), isNull);
      expect(state.layerManager.getLayerById(bottom.id)!.baseImage, isNotNull);
      state.undo();
      expect(state.layerManager.getLayerById(top.id)!.baseImage, isNotNull);
      expect(state.layerManager.getLayerById(bottom.id)!.baseImage, isNotNull);
      state.dispose();
    },
  );
}
