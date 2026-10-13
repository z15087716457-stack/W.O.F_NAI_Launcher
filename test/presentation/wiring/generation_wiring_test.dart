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
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import 'package:nai_launcher/presentation/wiring/generation_wiring.dart';
import 'package:nai_launcher/presentation/wiring/generation_backend.dart';
import 'package:nai_launcher/presentation/providers/krita/bridge_draft_snapshot.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import '../providers/krita/agent_bridge_draft_test.dart'
    show MemoryCharacters, MemoryDraftSettings, EmptyBlocks, OfflineAuth;
import 'generation_backend_test.dart' show MemoryGenerationPlatform;
import 'generation_data_wiring_test.dart'
    show DataGeneration, DataSubscription, DataShortcuts;

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
              builder: (_, child) =>
                  IntegratedTitleBarShell(deferToRoute: true, child: child!),
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
