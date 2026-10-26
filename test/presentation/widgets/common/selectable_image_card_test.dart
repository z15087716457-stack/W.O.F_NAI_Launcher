import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/data/models/image/image_stream_chunk.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/simple_output_viewer_provider.dart';
import 'package:nai_launcher/presentation/providers/simple_viewer_group_batches_provider.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_history.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import 'package:nai_launcher/presentation/wiring/generation_wiring.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import '../../providers/krita/agent_bridge_draft_test.dart'
    show MemoryCharacters, MemoryDraftSettings, EmptyBlocks, OfflineAuth;
import '../../wiring/generation_data_wiring_test.dart'
    show DataGeneration, DataSubscription, DataShortcuts;
import '../../wiring/generation_reference_imports_test.dart' show ImportStorage;
import 'package:nai_launcher/presentation/screens/generation/widgets/image_preview.dart';
import 'package:nai_launcher/presentation/widgets/common/draggable_memory_image.dart';
import 'package:nai_launcher/presentation/widgets/common/selectable_image_card.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import '../../../helpers/studio_capture_fonts.dart';

void main() {
  late Directory hiveTempDir;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    hiveTempDir = await Directory.systemTemp.createTemp(
      'nai_launcher_selectable_card_hive_',
    );
    Hive.init(hiveTempDir.path);
    await Hive.openBox(StorageKeys.settingsBox);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveTempDir.exists()) {
      await hiveTempDir.delete(recursive: true);
    }
  });

  tearDown(() async {
    await Hive.box(StorageKeys.settingsBox).clear();
  });

  if (Platform.environment['CAPTURE_FEEDBACK_UI'] == '1' ||
      Platform.environment['CAPTURE_IMAGE_ACTIONS'] == '1') {
    testWidgets('generation menu real-font locale and theme captures', (
      tester,
    ) async {
      final oldShadows = debugDisableShadows;
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = oldShadows);
      await tester.runAsync(() async {
        await loadStudioCaptureFonts();
        final file = File(
          'C:/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        );
        await (FontLoader(
          'MaterialIcons',
        )..addFont(file.readAsBytes().then(ByteData.sublistView))).load();
      });
      await tester.binding.setSurfaceSize(const Size(760, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final folder = Directory(
        Platform.environment['CAPTURE_IMAGE_ACTIONS'] == '1'
            ? '.dart_tool/generation-image-actions-20261006/captures'
            : '.dart_tool/feedback-ui-captures',
      )..createSync(recursive: true);
      for (final locale in const [
        Locale('zh'),
        Locale('zh', 'TW'),
        Locale('en'),
        Locale('ja'),
        Locale('ko'),
      ]) {
        for (final brightness in Brightness.values) {
          final key = GlobalKey();
          await tester.pumpWidget(
            _buildCardApp(
              locale: locale,
              brightness: brightness,
              captureKey: key,
              onFullscreen: _noop,
              onDelete: _noop,
              onImageToImage: _noop,
              onVibeTransfer: _noop,
              onPreciseReference: _noop,
              onEditImage: _noop,
              onGenerateVariations: _noop,
              onDirectorTools: _noop,
              onEnhance: _noop,
              onOpenInExplorer: _noop,
              onSendToKrita: _noop,
              onSaveToPreciseRefLibrary: _noop,
            ),
          );
          await tester.pumpAndSettle();
          final gesture = await tester.startGesture(
            tester.getCenter(find.byType(SelectableImageCard)),
            kind: PointerDeviceKind.mouse,
            buttons: kSecondaryMouseButton,
          );
          await gesture.up();
          await tester.pumpAndSettle();
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            File(
              '${folder.path}/generation-${locale.toLanguageTag()}-${brightness.name}.png',
            ).writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
          final l = AppLocalizations.of(
            tester.element(find.byType(SelectableImageCard)),
          )!;
          expect(
            tester.getTopLeft(find.text(l.imageMenu_details)).dy,
            lessThan(tester.getTopLeft(find.text(l.common_delete)).dy),
          );
          expect(
            tester.getTopLeft(find.text(l.common_delete)).dy,
            lessThan(tester.getTopLeft(find.text(l.drop_img2img)).dy),
          );
          expect(tester.takeException(), isNull);
          await gesture.removePointer();
          await tester.pumpWidget(const SizedBox());
        }
      }
      debugDisableShadows = oldShadows;
    });
  }

  testWidgets(
    'hover hides inpaint and upscale shortcuts but context actions still run',
    (tester) async {
      var inpaintCalls = 0;
      var upscaleCalls = 0;
      await tester.pumpWidget(
        _buildCardApp(
          onInpaint: () => inpaintCalls++,
          onUpscale: () => upscaleCalls++,
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer();
      await gesture.moveTo(tester.getCenter(find.byType(SelectableImageCard)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byTooltip('局部重绘'), findsNothing);
      expect(find.byTooltip('放大'), findsNothing);
      // 悬浮操作条被魔改总开关 showHoverActionBar 默认关闭（0ff49fc7），
      // 悬浮不显示操作按钮；对应动作仍由右键菜单执行
      expect((inpaintCalls, upscaleCalls), (0, 0));
      for (final action in ['局部重绘', '放大']) {
        await _openImageContextMenu(tester);
        await tester.tap(find.text('编辑与派生'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(action));
        await tester.pumpAndSettle();
        await tester.pump();
        expect(find.byType(MenuAnchor), findsNothing);
      }
      expect((inpaintCalls, upscaleCalls), (1, 1));
    },
  );

  testWidgets('generation hover submenu aligns beside its parent row', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var calls = 0;
    await tester.pumpWidget(_buildCardApp(onInpaint: () => calls++));
    final mouse = await tester.startGesture(
      tester.getCenter(find.byType(SelectableImageCard)),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    addTearDown(mouse.removePointer);
    await mouse.up();
    await tester.pumpAndSettle();
    final parent = find.ancestor(
      of: find.text('编辑与派生'),
      matching: find.byType(SubmenuButton),
    );
    final rect = tester.getRect(parent);
    await mouse.moveTo(rect.center);
    await tester.pumpAndSettle();
    final child = find.ancestor(
      of: find.text('局部重绘'),
      matching: find.byType(MenuItemButton),
    );
    expect(tester.getRect(child).left, greaterThanOrEqualTo(rect.right));
    await mouse.moveTo(tester.getCenter(child));
    await tester.pumpAndSettle();
    await tester.tap(child);
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.byType(MenuAnchor), findsNothing);
  });

  testWidgets('context menu should expose inpaint and upscale shortcuts', (
    tester,
  ) async {
    await tester.pumpWidget(_buildCardApp());

    final center = tester.getCenter(find.byType(SelectableImageCard));
    final gesture = await tester.startGesture(
      center,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    addTearDown(gesture.removePointer);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('局部重绘'), findsNothing);
    await tester.tap(find.text('编辑与派生'));
    await tester.pumpAndSettle();
    expect(find.text('局部重绘'), findsOneWidget);
    expect(find.text('放大'), findsOneWidget);
  });

  testWidgets('context menu closes before invoking route launching actions', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      _buildCardApp(
        navigatorKey: navigatorKey,
        onInpaint: () {
          navigatorKey.currentState!.push(
            MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('inpaint route')),
            ),
          );
        },
      ),
    );

    final center = tester.getCenter(find.byType(SelectableImageCard));
    final gesture = await tester.startGesture(
      center,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    addTearDown(gesture.removePointer);
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();

    await tester.tap(find.text('编辑与派生'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('局部重绘'));
    await tester.pumpAndSettle();

    expect(find.text('inpaint route'), findsOneWidget);
    expect(find.byKey(const Key('image-action-menu')), findsNothing);
  });

  testWidgets(
    'hover hides generation shortcuts but each context destination still runs',
    (tester) async {
      final calls = {'图生图': 0, '风格迁移': 0, '精准参考': 0};
      await tester.pumpWidget(
        _buildCardApp(
          onImageToImage: () => calls['图生图'] = calls['图生图']! + 1,
          onVibeTransfer: () => calls['风格迁移'] = calls['风格迁移']! + 1,
          onPreciseReference: () => calls['精准参考'] = calls['精准参考']! + 1,
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer();
      await gesture.moveTo(tester.getCenter(find.byType(SelectableImageCard)));
      await tester.pumpAndSettle();

      for (final action in calls.keys) {
        expect(find.byTooltip(action), findsNothing);
      }
      expect(calls.values, everyElement(0));
      for (final action in calls.keys) {
        await _openImageContextMenu(tester);
        await tester.tap(find.text(action));
        await tester.pumpAndSettle();
        await tester.pump();
        expect(find.byType(MenuAnchor), findsNothing);
      }
      expect(calls.values, everyElement(1));
    },
  );

  testWidgets('context menu should expose generation destination shortcuts', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildCardApp(
        onImageToImage: _noop,
        onVibeTransfer: _noop,
        onPreciseReference: _noop,
      ),
    );

    final center = tester.getCenter(find.byType(SelectableImageCard));
    final gesture = await tester.startGesture(
      center,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    addTearDown(gesture.removePointer);
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('图生图'), findsOneWidget);
    expect(find.text('风格迁移'), findsOneWidget);
    expect(find.text('精准参考'), findsOneWidget);
  });

  testWidgets(
    'generation preview hover hides shortcuts without disabling its context menu',
    (tester) async {
      final container = _createContainerWithPreviewImage();
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildPreviewApp(container));
      await tester.pumpAndSettle();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer();
      await gesture.moveTo(tester.getCenter(find.byType(SelectableImageCard)));
      await tester.pumpAndSettle();

      expect(find.byTooltip('图生图'), findsNothing);
      expect(find.byTooltip('风格迁移'), findsNothing);
      expect(find.byTooltip('精准参考'), findsNothing);
      await _openImageContextMenu(tester);
      expect(find.text('图生图'), findsOneWidget);
      expect(find.text('风格迁移'), findsOneWidget);
      expect(find.text('精准参考'), findsOneWidget);
    },
  );

  testWidgets(
    'generation preview context menu exposes history destination shortcuts',
    (tester) async {
      final container = _createContainerWithPreviewImage();
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildPreviewApp(container));
      await tester.pumpAndSettle();

      final center = tester.getCenter(find.byType(SelectableImageCard));
      final gesture = await tester.startGesture(
        center,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      addTearDown(gesture.removePointer);
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('图生图'), findsOneWidget);
      expect(find.text('风格迁移'), findsOneWidget);
      expect(find.text('精准参考'), findsOneWidget);
    },
  );

  testWidgets(
    'generation preview right-click copy writes the displayed image',
    (tester) async {
      Uint8List? copiedBytes;
      bool? menuVisibleWhenCopyStarted;
      final container = _createContainerWithPreviewImage(
        clipboardWriter: (bytes) async {
          menuVisibleWhenCopyStarted = find
              .byKey(const Key('image-action-menu'))
              .evaluate()
              .isNotEmpty;
          copiedBytes = bytes;
        },
      );
      addTearDown(container.dispose);
      final expectedBytes = container
          .read(imageGenerationNotifierProvider)
          .displayImages
          .single
          .bytes;

      await tester.pumpWidget(_buildPreviewApp(container));
      await tester.pumpAndSettle();
      await _openImageContextMenu(tester);

      await tester.tap(find.text('复制图像'));
      await tester.pumpAndSettle();

      expect(copiedBytes, orderedEquals(expectedBytes));
      expect(menuVisibleWhenCopyStarted, isFalse);
      expect(find.byKey(const Key('image-action-menu')), findsNothing);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('image-action-menu')), findsNothing);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('generation history right-click copy writes the history image', (
    tester,
  ) async {
    Uint8List? copiedBytes;
    final bytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 32, height: 32)),
    );
    final container = ProviderContainer(
      overrides: [
        imageClipboardWriterProvider.overrideWithValue(
          (imageBytes) async => copiedBytes = imageBytes,
        ),
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockLibraryNotifierProvider.overrideWith(EmptyBlocks.new),
        authNotifierProvider.overrideWith(OfflineAuth.new),
        imageGenerationNotifierProvider.overrideWith(DataGeneration.new),
        subscriptionNotifierProvider.overrideWith(DataSubscription.new),
        shortcutConfigNotifierProvider.overrideWith(DataShortcuts.new),
        vibeLibraryStorageServiceProvider.overrideWithValue(ImportStorage()),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(imageGenerationNotifierProvider.notifier);
    notifier.state = notifier.state.copyWith(
      history: [
        GeneratedImage(
          id: 'history-copy-image',
          bytes: bytes,
          width: 32,
          height: 32,
        ),
      ],
    );

    await tester.pumpWidget(_buildHistoryApp(container));
    await tester.pumpAndSettle();
    final tile = find.byKey(const Key('gen-batch-tile-img:history-copy-image'));
    final gesture = await tester.startGesture(
      tester.getCenter(tile),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    addTearDown(gesture.removePointer);
    await gesture.up();
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(
      tester.element(find.byType(GenHistoryPanel)),
    )!;
    await tester.tap(find.text(l.gen_copyImage));
    await tester.pumpAndSettle();

    expect(copiedBytes, orderedEquals(bytes));
    expect(find.text(l.gen_copyImage), findsNothing);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'generation preview makes completed single and grid images draggable',
    (tester) async {
      // 网格只在“按批次分组”开启时出现；默认逐张显示。
      final container = _createContainerWithPreviewImage(grouped: true);
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildPreviewApp(container));
      await tester.pumpAndSettle();

      expect(find.byType(DraggableMemoryImage), findsOneWidget);

      final bytes = Uint8List.fromList(
        img.encodePng(img.Image(width: 32, height: 32)),
      );
      container
          .read(imageGenerationNotifierProvider.notifier)
          .updateDisplayImages([
            GeneratedImage(id: 'grid-1', bytes: bytes, width: 32, height: 32),
            GeneratedImage(id: 'grid-2', bytes: bytes, width: 32, height: 32),
          ]);
      await tester.pumpAndSettle();

      expect(find.byType(DraggableMemoryImage), findsNWidgets(2));
    },
  );

  testWidgets('generation preview keeps failed snapshots non-draggable', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final bytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 32, height: 32)),
    );
    container
        .read(imageGenerationNotifierProvider.notifier)
        .updateDisplayImages([
          GeneratedImage(
            id: 'failed-preview',
            bytes: bytes,
            width: 32,
            height: 32,
            kind: GeneratedImageKind.failedStreamSnapshot,
          ),
        ]);

    await tester.pumpWidget(_buildPreviewApp(container));
    await tester.pumpAndSettle();

    expect(find.byType(SelectableImageCard), findsOneWidget);
    expect(find.byType(DraggableMemoryImage), findsNothing);
  });

  testWidgets('generation preview renders multiple stream preview slots', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        simpleOutputViewerNotifierProvider.overrideWith(
          _SimpleViewerNotifier.new,
        ),
      ],
    );
    addTearDown(container.dispose);

    final firstPreview = Uint8List.fromList(
      img.encodePng(img.Image(width: 32, height: 32)),
    );
    final secondPreview = Uint8List.fromList(
      img.encodePng(img.Image(width: 48, height: 32)),
    );
    final notifier = container.read(imageGenerationNotifierProvider.notifier);
    notifier.state = notifier.state.copyWith(
      status: GenerationStatus.generating,
      currentImage: 1,
      totalImages: 2,
      batchWidth: 32,
      batchHeight: 32,
      streamPreviewSlots: [
        StreamPreviewSlot(
          imageNumber: 1,
          totalImages: 2,
          progress: 0.25,
          previewBytes: firstPreview,
        ),
        StreamPreviewSlot(
          imageNumber: 2,
          totalImages: 2,
          progress: 0.35,
          previewBytes: secondPreview,
        ),
      ],
      clearStreamPreview: true,
    );

    await tester.pumpWidget(_buildPreviewApp(container));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SelectableImageCard), findsNWidgets(2));
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('2/2'), findsOneWidget);
  });

  testWidgets('inpaint stream preview with mask uses masked preview path', (
    tester,
  ) async {
    final sourceBytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 32, height: 32)),
    );
    final previewBytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 16, height: 16)),
    );
    final mask = img.Image(width: 16, height: 16, numChannels: 4);
    mask.setPixelRgba(8, 8, 255, 255, 255, 255);
    final maskBytes = Uint8List.fromList(img.encodePng(mask));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SizedBox(
              width: 160,
              height: 160,
              child: SelectableImageCard(
                imageBytes: sourceBytes,
                streamPreview: previewBytes,
                inpaintPreviewPlacement: InpaintStreamPreviewPlacement(
                  sourceImage: sourceBytes,
                  maskImage: maskBytes,
                  xPercent: 0.25,
                  yPercent: 0.25,
                  widthPercent: 0.5,
                  heightPercent: 0.5,
                ),
                isGenerating: true,
                imageWidth: 32,
                imageHeight: 32,
                currentImage: 1,
                totalImages: 1,
                progress: 0.5,
                enableSelection: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget.runtimeType.toString() == '_InpaintStreamPreviewImage',
      ),
      findsOneWidget,
    );
  });

  testWidgets('disabled hover effects should not expose hover action bar', (
    tester,
  ) async {
    await tester.pumpWidget(_buildCardApp(hoverEffectsEnabled: false));

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byType(SelectableImageCard)));
    await tester.pumpAndSettle();

    expect(find.byTooltip('局部重绘'), findsNothing);
    expect(find.byTooltip('放大'), findsNothing);
  });

  testWidgets('favorite button should appear at the top right and toggle', (
    tester,
  ) async {
    var toggled = false;
    await tester.pumpWidget(
      _buildCardApp(isFavorite: true, onFavoriteToggle: () => toggled = true),
    );

    expect(find.byTooltip('取消收藏'), findsOneWidget);

    await tester.tap(find.byTooltip('取消收藏'));
    await tester.pump();

    expect(toggled, isTrue);
  });

  testWidgets('read-only card hides save and copy actions but keeps badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildCardApp(
        enableSaveAction: false,
        enableCopyAction: false,
        statusBadgeLabel: '失败快照',
        onInpaint: null,
        onUpscale: null,
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byType(SelectableImageCard)));
    await tester.pumpAndSettle();

    expect(find.text('失败快照'), findsOneWidget);
    expect(find.byTooltip('保存'), findsNothing);
    expect(find.byTooltip('复制'), findsNothing);

    final center = tester.getCenter(find.byType(SelectableImageCard));
    final secondary = await tester.startGesture(
      center,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    addTearDown(secondary.removePointer);
    await tester.pumpAndSettle();
    await secondary.up();
    await tester.pumpAndSettle();

    expect(find.text('保存图片'), findsNothing);
    expect(find.text('复制图片'), findsNothing);
    expect(find.byKey(const Key('image-action-menu')), findsNothing);
  });
}

void _noop() {}

/// 画布（G11）是默认预览实现；这些用例断言经典网格/单卡语义，
/// 一律强制 simpleOutputViewer=true 走回退档。
class _GroupedBatches extends SimpleViewerGroupBatches {
  @override
  bool build() => true;
}

class _SimpleViewerNotifier extends SimpleOutputViewerNotifier {
  @override
  bool build() => true;
}

ProviderContainer _createContainerWithPreviewImage({
  ImageClipboardWriter? clipboardWriter,
  bool grouped = false,
}) {
  final container = ProviderContainer(
    overrides: [
      // 经典预览档：画布接管后 SelectableImageCard 由画布 tile 复用，断言要钉回旧实现
      simpleOutputViewerNotifierProvider.overrideWith(
        _SimpleViewerNotifier.new,
      ),
      if (clipboardWriter != null)
        imageClipboardWriterProvider.overrideWithValue(clipboardWriter),
      if (grouped)
        simpleViewerGroupBatchesProvider.overrideWith(_GroupedBatches.new),
    ],
  );
  final bytes = Uint8List.fromList(
    img.encodePng(img.Image(width: 32, height: 32)),
  );

  container.read(imageGenerationNotifierProvider.notifier).updateDisplayImages([
    GeneratedImage(id: 'preview-image', bytes: bytes, width: 32, height: 32),
  ]);

  return container;
}

Widget _buildPreviewApp(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      locale: Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: SizedBox(width: 480, height: 480, child: ImagePreviewWidget()),
      ),
    ),
  );
}

Widget _buildHistoryApp(ProviderContainer container) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: SizedBox(
          width: 320,
          height: 640,
          child: GenerationWiring(
            builder: ({required data, required actions, required slots}) =>
                GenHost(
                  data: data,
                  actions: actions,
                  slots: slots,
                  child: const GenHistoryPanel(width: 320),
                ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openImageContextMenu(WidgetTester tester) async {
  final center = tester.getCenter(find.byType(SelectableImageCard).first);
  final gesture = await tester.startGesture(
    center,
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryMouseButton,
  );
  addTearDown(gesture.removePointer);
  await tester.pumpAndSettle();
  await gesture.up();
  await tester.pumpAndSettle();
}

Widget _buildCardApp({
  bool hoverEffectsEnabled = true,
  bool isFavorite = false,
  bool enableSaveAction = true,
  bool enableCopyAction = true,
  String? statusBadgeLabel,
  VoidCallback? onFavoriteToggle,
  VoidCallback? onInpaint = _noop,
  VoidCallback? onUpscale = _noop,
  VoidCallback? onImageToImage,
  VoidCallback? onVibeTransfer,
  VoidCallback? onPreciseReference,
  VoidCallback? onFullscreen,
  VoidCallback? onDelete,
  VoidCallback? onEditImage,
  VoidCallback? onGenerateVariations,
  VoidCallback? onDirectorTools,
  VoidCallback? onEnhance,
  VoidCallback? onOpenInExplorer,
  VoidCallback? onSendToKrita,
  VoidCallback? onSaveToPreciseRefLibrary,
  Locale locale = const Locale('zh'),
  Brightness brightness = Brightness.light,
  GlobalKey? captureKey,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  final bytes = Uint8List.fromList(
    img.encodePng(img.Image(width: 32, height: 32)),
  );

  return ProviderScope(
    child: MaterialApp(
      navigatorKey: navigatorKey,
      locale: locale,
      theme: AppTheme.getTheme(AppStyle.geist, brightness),
      builder: captureKey == null
          ? null
          : (_, child) => RepaintBoundary(key: captureKey, child: child!),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 160,
            height: 160,
            child: SelectableImageCard(
              imageBytes: bytes,
              enableSelection: false,
              hoverEffectsEnabled: hoverEffectsEnabled,
              enableSaveAction: enableSaveAction,
              enableCopyAction: enableCopyAction,
              statusBadgeLabel: statusBadgeLabel,
              isFavorite: isFavorite,
              onFavoriteToggle: onFavoriteToggle,
              onInpaint: onInpaint,
              onUpscale: onUpscale,
              onImageToImage: onImageToImage,
              onVibeTransfer: onVibeTransfer,
              onPreciseReference: onPreciseReference,
              onFullscreen: onFullscreen,
              onDelete: onDelete,
              onEditImage: onEditImage,
              onGenerateVariations: onGenerateVariations,
              onDirectorTools: onDirectorTools,
              onEnhance: onEnhance,
              onOpenInExplorer: onOpenInExplorer,
              onSendToKrita: onSendToKrita,
              onSaveToPreciseRefLibrary: onSaveToPreciseRefLibrary,
            ),
          ),
        ),
      ),
    ),
  );
}
