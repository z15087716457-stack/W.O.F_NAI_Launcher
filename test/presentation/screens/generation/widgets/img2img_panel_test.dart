import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/presentation/providers/comfyui/comfyui_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/image_action_providers.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_feed_layout.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/generation_canvas_view.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/generation_canvas_controller.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/image_editor_screen.dart';
import 'package:nai_launcher/presentation/widgets/image_editor/canvas/editor_canvas.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/img2img_panel.dart';
import 'package:nai_launcher/presentation/widgets/common/image_picker_card/image_picker_card.dart';
import 'package:nai_launcher/presentation/widgets/common/collapsible_image_panel.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_animated_icon.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';

import '../../../../helpers/light_theme_contrast.dart';

void main() {
  group('Img2ImgPanel', () {
    testWidgets('空底图区为参考库导入+绘制草图双卡，且无重复上传/底部导入行', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // 320px 侧栏宽度下不应溢出
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      container
          .read(imageWorkflowControllerProvider.notifier)
          .setPanelExpanded(true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('zh'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: Img2ImgPanel()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 标题行保留唯一的“上传图片”入口（大上传块已移除）
      expect(find.text('上传图片'), findsOneWidget);

      // 空态内容区：左侧精准参考库导入卡片，右侧绘制草图卡片
      final libraryCard = find.byKey(
        const Key('img2img-from-precise-ref-library'),
      );
      final sketchCard = find.widgetWithText(ImagePickerCard, '绘制草图');
      expect(libraryCard, findsOneWidget);
      expect(sketchCard, findsOneWidget);
      expect(find.text('从精准参考库导入'), findsOneWidget);
      expect(
        tester.getCenter(libraryCard).dx,
        lessThan(tester.getCenter(sketchCard).dx),
      );

      // 底部独立的整行导入按钮已删除，导入入口只有卡片一处
      expect(find.widgetWithText(OutlinedButton, '从精准参考库导入'), findsNothing);

      // 卡片走自定义 onTap（打开参考库对话框而非文件选择）
      expect(tester.widget<ImagePickerCard>(libraryCard).onTap, isNotNull);
      expect(tester.widget<ImagePickerCard>(sketchCard).onTap, isNotNull);

      await tester.tap(find.text('图生图'));
      await tester.pump();
      expect(
        tester
            .widget<CollapsibleImagePanel>(find.byType(CollapsibleImagePanel))
            .isExpanded,
        isFalse,
      );
      final headerIcon = tester.widget<StudioAnimatedIcon>(
        find
            .descendant(
              of: find.byType(CollapsibleImagePanel),
              matching: find.byType(StudioAnimatedIcon),
            )
            .first,
      );
      expect(headerIcon.icon, StudioIcons.imageToImage);
      expect(headerIcon.trigger, 1);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint && widget.painter is StudioIconPainter,
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('放入画布保留原图与草稿，重复点击重新对焦且无更多菜单', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.binding.setSurfaceSize(const Size(1400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = container.read(
        imageWorkflowControllerProvider.notifier,
      );
      controller.replaceSourceImage(_testImageBytes);
      controller.setPanelExpanded(true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('zh'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: Img2ImgPanel()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final draft = container.read(generationParamsNotifierProvider);
      final workflow = container.read(draftImageWorkflowProvider);
      expect(find.byKey(const Key('img2img-overflow-menu')), findsNothing);
      expect(find.byKey(const Key('img2img-action-edit')), findsNothing);
      expect(find.byKey(const Key('img2img-action-inpaint')), findsNothing);
      expect(find.byKey(const Key('img2img-action-replace')), findsOneWidget);
      expect(find.byKey(const Key('img2img-action-clear')), findsOneWidget);
      final button = find.byKey(const Key('img2img-action-place-on-canvas'));
      expect(button, findsOneWidget);
      expect(find.byTooltip('放入画布'), findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();
      final image = container
          .read(imageGenerationNotifierProvider)
          .history
          .single;
      expect(image.bytes, orderedEquals(_testImageBytes));
      expect(container.read(generationPreviewSelectionProvider), image.id);
      expect(
        container.read(canvasFeedLayoutProvider).groups.single.key,
        'img:${image.id}',
      );
      final request = container.read(canvasHistoryFocusRequestProvider)!;
      expect(request.imageId, image.id);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(
        container.read(imageGenerationNotifierProvider).history,
        hasLength(1),
      );
      expect(
        container.read(canvasHistoryFocusRequestProvider)!.revision,
        request.revision + 1,
      );
      expect(container.read(generationParamsNotifierProvider), same(draft));
      expect(container.read(draftImageWorkflowProvider), same(workflow));
      expect(tester.takeException(), isNull);
    });

    testWidgets('原图直接进入实际画布，可反复对焦并打开本地编辑器', (tester) async {
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWith(
            (ref) => _MemoryLocalStorageService(),
          ),
          estimatedCostProvider.overrideWithValue(0),
          imageVariationCostProvider.overrideWith((ref, image) => 0),
          generationCanvasCameraProvider.overrideWith(_TrackingCamera.new),
        ],
      );
      addTearDown(container.dispose);
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      container
          .read(imageWorkflowControllerProvider.notifier)
          .replaceSourceImage(_testImageBytes);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('zh'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: Row(
                children: [
                  const SizedBox(
                    width: 400,
                    child: SingleChildScrollView(child: Img2ImgPanel()),
                  ),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, _) => GenerationCanvasView(
                        generationState: ref.watch(
                          imageGenerationNotifierProvider,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final action = find.byKey(const Key('img2img-action-place-on-canvas'));
      await tester.tap(action);
      await tester.pumpAndSettle();
      final image = container
          .read(imageGenerationNotifierProvider)
          .history
          .single;
      expect(
        container.read(generationCanvasGroupSelectionProvider)?.group,
        'img:${image.id}',
      );
      final camera =
          container.read(generationCanvasCameraProvider.notifier)
              as _TrackingCamera;
      final focusCount = camera.focusCount;
      camera.panBy(const Offset(2000, 0));
      await tester.pump();
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(camera.focusCount, greaterThan(focusCount));
      final toolbarEdit = find.descendant(
        of: find.byType(GenerationCanvasView),
        matching: find.byTooltip('编辑图像'),
      );
      expect(toolbarEdit, findsOneWidget);
      await tester.tap(toolbarEdit);
      await tester.pump();
      for (
        var attempt = 0;
        attempt < 100 && find.byType(EditorCanvas).evaluate().isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(EditorCanvas), findsOneWidget);
      final editor = tester.widget<ImageEditorScreen>(
        find.byType(ImageEditorScreen),
      );
      expect(editor.mode, ImageEditorMode.edit);
      expect(editor.initialImage, orderedEquals(_testImageBytes));
      expect(
        (tester.state(find.byType(ImageEditorScreen)) as dynamic)
            .debugCanvasSize,
        const Size(8, 8),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('超分模型下拉项不重复显示当前模块前缀', (tester) async {
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWith(
            (ref) => _MemoryLocalStorageService(),
          ),
          comfyUISettingsProvider.overrideWith(_EnabledComfyUISettings.new),
          comfyUISeedvr2ModelsProvider.overrideWith(
            _FixedComfyUIUpscaleModels.new,
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.binding.setSurfaceSize(const Size(1400, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = container.read(
        imageWorkflowControllerProvider.notifier,
      );
      controller.replaceSourceImage(_testImageBytes);
      controller.enterUpscaleMode();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('zh'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: Img2ImgPanel(toolOnly: true)),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('seedvr2_ema_7b_fp16'), findsOneWidget);
      expect(find.textContaining('SeedVR2 ·'), findsNothing);

      await tester.tap(find.text('普通模型'));
      await tester.pumpAndSettle();

      expect(find.text('4x-UltraSharpV2'), findsOneWidget);
      expect(find.textContaining('普通模型 ·'), findsNothing);
    });

    testWidgets('浅色主题下展开面板不应出现贴在面板底色上的近白色文字', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(
        imageWorkflowControllerProvider.notifier,
      );
      controller.replaceSourceImage(_testImageBytes);
      controller.enterInpaintMode();
      // 展开后背景图不再渲染，内容直接贴在 Card 表面上，
      // 此时任何白色文字在浅色主题下都不可读。
      controller.setPanelExpanded(true);

      await pumpPanelInLightTheme(
        tester,
        container: container,
        panel: const Img2ImgPanel(),
      );

      expectNoUnreadableLightText(tester, panelName: 'Img2ImgPanel（重绘模式）');
    });
  });
}

final Uint8List _testImageBytes = Uint8List.fromList(
  img.encodePng(img.Image(width: 8, height: 8)),
);

class _EnabledComfyUISettings extends ComfyUISettings {
  @override
  ComfyUISettingsState build() {
    return const ComfyUISettingsState(enabled: true);
  }
}

class _FixedComfyUIUpscaleModels extends ComfyUISeedvr2Models {
  @override
  List<String> build() {
    return const ['seedvr2_ema_7b_fp16.safetensors', '4x-UltraSharpV2.pth'];
  }

  @override
  Future<void> fetch({bool force = false}) async {}
}

class _MemoryLocalStorageService extends LocalStorageService {
  @override
  bool getCanvasReducedMotion() => true;
  final Map<String, Object?> _values = {};

  @override
  T? getSetting<T>(String key, {T? defaultValue}) {
    final value = _values.containsKey(key) ? _values[key] : defaultValue;
    return value as T?;
  }

  @override
  Future<void> setSetting<T>(String key, T value) async {
    _values[key] = value;
  }

  @override
  Future<void> deleteSetting(String key) async {
    _values.remove(key);
  }
}

class _TrackingCamera extends GenerationCanvasCameraNotifier {
  int focusCount = 0;

  @override
  void flyTo(
    CanvasCamera target, {
    double speed = 11,
    Duration duration = const Duration(milliseconds: 500),
    VoidCallback? onDone,
  }) {
    focusCount++;
    super.flyTo(target, speed: speed, duration: duration, onDone: onDone);
  }
}
