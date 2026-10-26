import 'package:nai_launcher/presentation/router/app_router.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';
import 'dart:async';
import 'package:nai_launcher/presentation/ui/tools/tools_sheets.dart';
import 'dart:io';
import 'package:nai_launcher/presentation/providers/prompt_translation_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nai_launcher/core/shortcuts/default_shortcuts.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_contract.dart';
import 'package:nai_launcher/presentation/ui/viewer/viewer_page.dart';
import 'package:nai_launcher/presentation/wiring/generation_viewer_wiring.dart';
import 'package:nai_launcher/presentation/wiring/generation_viewer_window.dart';
import 'generation_viewer_window_test.dart' show MemoryViewerWindow;
import 'generation_reference_imports_test.dart' show ImportStorage;
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/generation/widgets/reference_module_test.dart'
    show prepareGenerationDropTestPlatform;
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/tips_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_header.dart';
import 'package:nai_launcher/presentation/providers/floating_resource_windows_provider.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/wiring/generation_wiring.dart';
import 'package:nai_launcher/presentation/wiring/generation_backend.dart';
import 'package:nai_launcher/presentation/wiring/generation_operations.dart';
import 'package:nai_launcher/presentation/providers/krita/bridge_draft_snapshot.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import '../providers/krita/agent_bridge_draft_test.dart'
    show MemoryCharacters, MemoryDraftSettings, EmptyBlocks, OfflineAuth;
import 'generation_backend_test.dart' show MemoryGenerationPlatform;
import 'generation_data_wiring_test.dart'
    show DataGeneration, DataSubscription, DataShortcuts;
import '../../helpers/studio_capture_fonts.dart';

class MemoryViewerTranslation extends PromptTranslationCoordinator {
  MemoryViewerTranslation(super.ref);
  final pending = Completer<PillDocument>();
  @override
  Future<PillDocument> translateDocument(
    PillDocument document, {
    required String sessionId,
  }) => pending.future;
}

void main() {
  prepareGenerationDropTestPlatform();
  setUpAll(loadStudioCaptureFonts);
  late Directory directory;
  late ProviderContainer container;
  late MemoryViewerWindow viewerPlatform;
  setUp(() async {
    viewerPlatform = MemoryViewerWindow();
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('generation-wiring-');
    Hive.init(directory.path);
    await Hive.openBox(StorageKeys.settingsBox);
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockLibraryNotifierProvider.overrideWith(EmptyBlocks.new),
        authNotifierProvider.overrideWith(OfflineAuth.new),
        imageGenerationNotifierProvider.overrideWith(DataGeneration.new),
        subscriptionNotifierProvider.overrideWith(DataSubscription.new),
        tipEpochProvider.overrideWith((ref) => Stream.value(0)),
        shortcutConfigNotifierProvider.overrideWith(DataShortcuts.new),
        promptTranslationCoordinatorProvider.overrideWith(
          (ref) => MemoryViewerTranslation(ref),
        ),
        generationPlatformProvider.overrideWithValue(
          MemoryGenerationPlatform(),
        ),
        generationViewerPlatformProvider.overrideWithValue(viewerPlatform),
        vibeLibraryStorageServiceProvider.overrideWithValue(ImportStorage()),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePromptImmediately('current prompt');
  });
  tearDown(() async {
    container.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });
  Future<void> pump(WidgetTester tester, {bool shortcuts = false}) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(
            body: shortcuts
                ? const GenerationRoute()
                : const GenerationWiring(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  /// 内联 × 已移除（10-25），清空入口在全屏编辑顶栏。
  Future<void> clearFromFullscreen(
    WidgetTester tester,
    GenEditorTarget target,
  ) async {
    Future<void> tap(String key) async {
      final f = find.byKey(Key(key));
      await tester.ensureVisible(f);
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    final ch = target.character;
    if (ch == null) {
      await tap('gen-tool-menu');
      await tap('gen-fullscreen');
    } else {
      await tap('gen-character-more-$ch');
      await tap('gen-character-fullscreen-$ch');
    }
    final full = ch == null
        ? GenEditorTarget.base(negative: target.negative, fullscreen: true)
        : GenEditorTarget.character(
            ch,
            negative: target.negative,
            fullscreen: true,
          );
    await tap('gen-clear-$full');
    await tap('gen-fullscreen-close');
  }

  String promptFor(GenEditorTarget target) {
    if (target.character case final index?) {
      final character = container
          .read(characterPromptNotifierProvider)
          .characters[index];
      return target.negative ? character.negativePrompt : character.prompt;
    }
    final params = container.read(generationParamsNotifierProvider);
    return target.negative ? params.negativePrompt : params.prompt;
  }

  testWidgets(
    'prompt tools menu opens each resource window kind',
    (tester) async {
      await pump(tester);
      final header = tester.widget<GenHeader>(find.byType(GenHeader).first);
      expect(header.onOpenResourceWindow, isNotNull);
      for (final kind in FloatingResourceKind.values) {
        await tester.tap(find.byKey(const Key('gen-tool-menu')).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('gen-resource-windows')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key('gen-resource-${kind.name}')));
        await tester.pumpAndSettle();
      }
      expect(
        container
            .read(floatingResourceWindowsProvider)
            .map((window) => window.kind),
        FloatingResourceKind.values,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'placing img2img source preserves bytes, reuses tile and focuses it',
    (tester) async {
      final bytes = Uint8List.fromList(
        img.encodePng(img.Image(width: 16, height: 16)),
      );
      container
          .read(generationParamsNotifierProvider.notifier)
          .setSourceImage(bytes);
      await pump(tester);
      final host = tester.state<ConsumerState>(find.byType(GenerationWiring));
      final operations = GenerationOperations(
        host.ref,
        host.context,
        () => host.mounted,
      );
      await tester.runAsync(operations.placeSource);
      final generation = container.read(imageGenerationNotifierProvider);
      expect(generation.history, hasLength(1));
      final id = generation.history.single.id;
      expect(generation.history.single.bytes, orderedEquals(bytes));
      expect(container.read(generationPreviewSelectionProvider), id);
      final otherBytes = Uint8List.fromList(
        img.encodePng(img.Image(width: 17, height: 17)),
      );
      container
          .read(imageGenerationNotifierProvider.notifier)
          .registerSourceImage(otherBytes);
      await tester.runAsync(operations.placeSource);
      expect(
        container.read(imageGenerationNotifierProvider).history,
        hasLength(2),
      );
      expect(container.read(generationPreviewSelectionProvider), id);
      expect(
        container.read(generationParamsNotifierProvider).prompt,
        'current prompt',
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('placing img2img source is blocked during generation', (
    tester,
  ) async {
    final bytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 16, height: 16)),
    );
    container
        .read(generationParamsNotifierProvider.notifier)
        .setSourceImage(bytes);
    (container.read(imageGenerationNotifierProvider.notifier) as DataGeneration)
        .publish(
          const ImageGenerationState(status: GenerationStatus.generating),
        );
    await pump(tester);
    final host = tester.state<ConsumerState>(find.byType(GenerationWiring));
    await tester.runAsync(
      GenerationOperations(
        host.ref,
        host.context,
        () => host.mounted,
      ).placeSource,
    );
    expect(container.read(imageGenerationNotifierProvider).history, isEmpty);
    expect(container.read(generationPreviewSelectionProvider), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final target in const [
    GenEditorTarget.base(),
    GenEditorTarget.base(negative: true),
    GenEditorTarget.character(0),
    GenEditorTarget.character(0, negative: true),
  ]) {
    testWidgets('$target 清空撤销提示显示两秒后自动消退', (tester) async {
      container
          .read(generationParamsNotifierProvider.notifier)
          .updateNegativePromptImmediately('base negative');
      final before = promptFor(target);
      expect(before, isNotEmpty);
      await pump(tester);
      if (target.negative) {
        final tab = find.byKey(
          Key(
            target.isBase
                ? 'gen-tab-negative'
                : 'gen-character-tab-neg-${target.character}',
          ),
        );
        await tester.ensureVisible(tab);
        await tester.tap(tab);
        await tester.pumpAndSettle();
      }
      await clearFromFullscreen(tester, target);
      expect(promptFor(target), isEmpty);
      expect(
        (container.read(generationPlatformProvider) as MemoryGenerationPlatform)
            .backups,
        hasLength(1),
      );
      expect(find.byType(SnackBarAction), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1900));
      expect(find.byType(SnackBarAction), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(SnackBar), findsNothing);
      expect(promptFor(target), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('清空后两秒内仍能撤销并恢复原提示词', (tester) async {
    await pump(tester);
    await clearFromFullscreen(tester, const GenEditorTarget.base());
    expect(promptFor(const GenEditorTarget.base()), isEmpty);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byType(SnackBarAction));
    await tester.pumpAndSettle();
    expect(promptFor(const GenEditorTarget.base()), 'current prompt');
    expect(find.byType(SnackBar), findsNothing);
    expect(
      (container.read(generationPlatformProvider) as MemoryGenerationPlatform)
          .backups,
      hasLength(2),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final path in [AppRoutes.home, AppRoutes.generation]) {
    testWidgets(
      'actual $path transition and viewer fallback own one caption cluster',
      (tester) async {
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(
          const MethodChannel('window_manager'),
          (call) async => call.method == 'isMaximized' ? false : null,
        );
        addTearDown(
          () => messenger.setMockMethodCallHandler(
            const MethodChannel('window_manager'),
            null,
          ),
        );
        final production = container.read(appRouterProvider);
        addTearDown(production.dispose);
        final shell = production.configuration.routes
            .whereType<StatefulShellRoute>()
            .single;
        final route = shell.branches.first.routes
            .whereType<GoRoute>()
            .singleWhere((route) => route.path == path);
        final router = GoRouter(
          initialLocation: path,
          routes: [
            GoRoute(
              path: path,
              pageBuilder: route.pageBuilder,
              routes: route.routes.whereType<GoRoute>().toList(),
            ),
          ],
        );
        addTearDown(router.dispose);
        tester.view.physicalSize = const Size(1600, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('zh'),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: IntegratedTitleBarShell(
                  deferToRoute: true,
                  child: child!,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('window-caption-controls')),
          findsOneWidget,
        );
        expect(find.byType(WindowChromePage), findsOneWidget);
        if (path == AppRoutes.generation) {
          router.go('$path/viewer');
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('window-caption-controls')),
            findsOneWidget,
          );
          expect(find.byType(WindowChromePage), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('路由宿主注册可自定义正负面快捷键，禁用后不触发', (tester) async {
    await tester.runAsync(() async {
      await container.read(shortcutConfigNotifierProvider.future);
      await container
          .read(shortcutConfigNotifierProvider.notifier)
          .setCustomShortcut(ShortcutIds.togglePromptMode, 'Ctrl+Shift+M');
    });
    await pump(tester, shortcuts: true);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(container.read(generationNegativeTabProvider), isTrue);
    await tester.runAsync(
      () => container
          .read(shortcutConfigNotifierProvider.notifier)
          .setEnabled(ShortcutIds.togglePromptMode, false),
    );
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(container.read(generationNegativeTabProvider), isTrue);
    await tester.pumpWidget(const SizedBox());
  });
  test('已接线的生图快捷键都能进入用户配置并归属生图上下文', () {
    for (final id in [
      ShortcutIds.saveImage,
      ShortcutIds.copyImage,
      ShortcutIds.fullscreenPreview,
      ShortcutIds.openParamsPanel,
      ShortcutIds.openHistoryPanel,
      ShortcutIds.reuseParams,
    ]) {
      expect(DefaultShortcuts.all.containsKey(id), isTrue, reason: id);
      expect(DefaultShortcuts.getContext(id), ShortcutContext.generation);
    }
  });

  testWidgets('焦点不在编辑器时，参数抽屉快捷键也能打开宿主', (tester) async {
    await tester.runAsync(
      () => container.read(shortcutConfigNotifierProvider.future),
    );
    await pump(tester, shortcuts: true);
    await tester.tap(find.byKey(const Key('gen-canvas')));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gen-params-drawer')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('复用快捷键备份并同步真实提示词及药丸草稿，不调用生成', (tester) async {
    final image = GeneratedImage(
      id: 'reuse-image',
      bytes: img.encodePng(img.Image(width: 512, height: 768)),
      width: 512,
      height: 768,
      generationRunId: 7,
      metadata: const NaiImageMetadata(
        prompt: 'saved prompt',
        negativePrompt: 'saved uc',
      ),
    );
    final generation =
        container.read(imageGenerationNotifierProvider.notifier)
            as DataGeneration;
    generation.publish(
      ImageGenerationState(history: [image], displayImages: [image]),
    );
    container
        .read(generationPreviewSelectionProvider.notifier)
        .select(image.id);
    container
        .read(pillWorkspaceProvider(PillScopes.main).notifier)
        .restoreDocument(
          const PillDocument(text: 'current prompt', instances: {}),
        );
    await tester.runAsync(
      () => container.read(shortcutConfigNotifierProvider.future),
    );
    await pump(tester, shortcuts: true);
    await tester.tap(find.byKey(const Key('gen-canvas')));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();
    expect(
      container.read(generationParamsNotifierProvider).prompt,
      'saved prompt',
    );
    expect(
      container.read(Provider(readBridgeDraft)).fields['prompt'],
      'saved prompt',
    );
    expect(
      (container.read(generationPlatformProvider) as MemoryGenerationPlatform)
          .backups,
      hasLength(1),
    );
    expect(generation.state.isGenerating, isFalse);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('增强入口显示现有工具控制，但不接管草稿底图或发起生成', (tester) async {
    final image = GeneratedImage(
      id: 'enhance-image',
      bytes: img.encodePng(img.Image(width: 512, height: 768)),
      width: 512,
      height: 768,
    );
    final generation =
        container.read(imageGenerationNotifierProvider.notifier)
            as DataGeneration;
    generation.publish(
      ImageGenerationState(history: [image], displayImages: [image]),
    );
    await pump(tester, shortcuts: true);
    final page = tester.widget<GenerationPage>(find.byType(GenerationPage));
    page.actions.onEnhance(image.id);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();
    expect(find.byType(ToolsEnhanceSheet), findsOneWidget);
    expect(container.read(imageWorkflowControllerProvider).isEnhance, isTrue);
    expect(
      container.read(generationParamsNotifierProvider).sourceImage,
      isNull,
    );
    expect(generation.state.isGenerating, isFalse);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
  });

  Future<GoRouter> pumpViewer(WidgetTester tester) async {
    final image = GeneratedImage(
      id: 'viewer-image',
      bytes: img.encodePng(img.Image(width: 512, height: 768)),
      width: 512,
      height: 768,
      metadata: const NaiImageMetadata(prompt: 'image prompt'),
    );
    (container.read(imageGenerationNotifierProvider.notifier) as DataGeneration)
        .publish(ImageGenerationState(history: [image]));
    final router = GoRouter(
      initialLocation: '/generation/viewer',
      routes: [
        GoRoute(
          path: '/generation',
          builder: (_, _) => const GenerationRoute(),
          routes: [
            GoRoute(
              path: 'viewer',
              builder: (_, _) => GenerationViewerWiring(
                request: GenerationViewerRequest([image], image.id),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          routerConfig: router,
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump();
    return router;
  }

  testWidgets('大图翻译显示忙态，取消后慢结果不复活，也不写入生图草稿', (tester) async {
    await pumpViewer(tester);
    final before = container.read(generationParamsNotifierProvider);
    final translation =
        container.read(promptTranslationCoordinatorProvider)
            as MemoryViewerTranslation;
    var page = tester.widget<ImageViewerPage>(find.byType(ImageViewerPage));
    page.actions.onToggleTranslation('viewer-image', ViewerPart.prompt);
    await tester.pump();
    page = tester.widget<ImageViewerPage>(find.byType(ImageViewerPage));
    expect(page.data.translations[ViewerPart.prompt]?.busy, isTrue);
    page.actions.onToggleTranslation('viewer-image', ViewerPart.prompt);
    translation.pending.complete(
      const PillDocument(text: 'late translation', instances: {}),
    );
    await tester.pump();
    await tester.pump();
    page = tester.widget<ImageViewerPage>(find.byType(ImageViewerPage));
    expect(page.data.translations, isEmpty);
    expect(container.read(generationParamsNotifierProvider), before);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('生图大图使用用户查看器快捷键，禁用和全局关闭均生效', (tester) async {
    await tester.runAsync(() async {
      await container.read(shortcutConfigNotifierProvider.future);
      await container
          .read(shortcutConfigNotifierProvider.notifier)
          .setCustomShortcut(ShortcutIds.nextImage, 'Ctrl+Shift+N');
    });
    await pumpViewer(tester);
    var page = tester.widget<ImageViewerPage>(find.byType(ImageViewerPage));
    final key = page.data.keys[ViewerCommand.next]!.single;
    expect(key.trigger, LogicalKeyboardKey.keyN);
    expect(key.control && key.shift, isTrue);
    await tester.runAsync(
      () => container
          .read(shortcutConfigNotifierProvider.notifier)
          .setEnabled(ShortcutIds.nextImage, false),
    );
    await tester.pump();
    page = tester.widget<ImageViewerPage>(find.byType(ImageViewerPage));
    expect(page.data.keys[ViewerCommand.next], isEmpty);
    await tester.runAsync(
      () => container
          .read(shortcutConfigNotifierProvider.notifier)
          .updateSettings(enableShortcuts: false),
    );
    await tester.pump();
    page = tester.widget<ImageViewerPage>(find.byType(ImageViewerPage));
    expect(page.data.keys.values.every((keys) => keys.isEmpty), isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('不经关闭按钮离开大图也恢复窗口并清除全屏宿主状态', (tester) async {
    final platform = viewerPlatform;
    final router = await pumpViewer(tester);
    final page = tester.widget<ImageViewerPage>(find.byType(ImageViewerPage));
    page.actions.onFullscreenChanged(true);
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    expect(platform.full, isTrue);
    expect(container.read(generationViewerWindowProvider).fullscreen, isTrue);
    router.go('/generation');
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    expect(platform.full, isFalse);
    expect(container.read(generationViewerWindowProvider).fullscreen, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('真实页面挂载使用契约和编辑器槽，不实例化旧生图页', (tester) async {
    await pump(tester);
    expect(find.byType(GenerationPage), findsOneWidget);
    final page = tester.widget<GenerationPage>(find.byType(GenerationPage));
    expect(page.data.prompt.negative, isFalse);
    expect(page.slots.drop, isNotNull);
    expect(page.slots.dock, isNotNull);
    expect(page.slots.historyDrag, isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('参数、正负面回调改实际 provider 并刷新页面数据', (tester) async {
    await pump(tester);
    final page = tester.widget<GenerationPage>(find.byType(GenerationPage));
    page.actions.onSizeChanged(896, 1152);
    await tester.pump();
    await tester.runAsync(
      () async => await Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    expect(container.read(generationParamsNotifierProvider).width, 896);
    page.actions.onNegativeTab(true);
    await tester.pump();
    expect(
      tester
          .widget<GenerationPage>(find.byType(GenerationPage))
          .data
          .prompt
          .negative,
      isTrue,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
