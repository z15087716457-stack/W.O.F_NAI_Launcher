// ignore: depend_on_referenced_packages
import 'package:irondash_message_channel/irondash_message_channel.dart';
// ignore: implementation_imports, depend_on_referenced_packages
import 'package:super_native_extensions/src/native/context.dart';
import 'dart:convert';
import 'package:nai_launcher/presentation/services/image_clipboard_service.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:file_picker/file_picker.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';
import 'package:nai_launcher/presentation/providers/gallery_trash_provider.dart';
import 'package:nai_launcher/presentation/router/gallery_navigation_request.dart';
import 'package:flutter/material.dart';
import 'package:nai_launcher/presentation/widgets/common/text_editing_shortcuts.dart';
import 'package:nai_launcher/presentation/providers/bulk_operation_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/cache/thumbnail_cache_service.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/data/models/gallery/gallery_category.dart';
import 'package:nai_launcher/data/models/gallery/image_collection.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/services/gallery/gallery_column_width_store.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/data/services/thumbnail_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/collection_provider.dart';
import 'package:nai_launcher/presentation/providers/gallery_category_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_focus_provider.dart';
import 'package:nai_launcher/presentation/providers/selection_mode_provider.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/screens/local_gallery/local_gallery_screen.dart';
import 'package:nai_launcher/presentation/themes/app_theme.dart';
import 'package:nai_launcher/presentation/providers/font_provider.dart';
import 'package:nai_launcher/presentation/widgets/drop/image_destination_dialog.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_inspector_panel.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_add_menu_button.dart';
import 'package:nai_launcher/presentation/widgets/gallery/local_gallery_toolbar.dart';
import 'package:nai_launcher/presentation/widgets/common/image_detail/components/detail_prompt_section.dart';
import 'package:nai_launcher/presentation/widgets/common/image_detail/components/detail_prompt_translation.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';
import 'package:nai_launcher/presentation/widgets/prompt/blocks/prompt_block_drag_data.dart';
import 'package:nai_launcher/presentation/widgets/gallery/local_image_card.dart';
import 'package:nai_launcher/presentation/widgets/gallery/timeline/gallery_timeline_view.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/utils/gallery_storage_layout.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_feed_layout.dart';

import '../../../helpers/fake_local_gallery_service.dart';
import '../../../helpers/studio_capture_fonts.dart';
import '../../../helpers/light_theme_contrast.dart'
    show InMemoryLocalStorageService;

class _RecordingClipboard extends ImageClipboardService {
  _RecordingClipboard(this.onCopy) : super(stripMetadata: () => false);
  final void Function(String) onCopy;
  @override
  Future<void> copyFile(String path) async => onCopy(path);
}

/// 本地画廊三栏布局：深浅主题、多语言、宽窄窗口下的实际渲染回归。
///
/// `CAPTURE_LOCAL_GALLERY=1` 时把画面写到 `.dart_tool/local-gallery-captures/`；
/// `GALLERY_CAPTURE_IMAGES=<目录>` 可指定带 manifest.json 的真实缩略图样本。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setContextOverride(
    MockMessageChannelContext()
      ..registerMockMethodCallHandler('DropManager', (_) async => null)
      ..registerMockMethodCallHandler('DragManager', (_) async => null),
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dev.irondash.engine_context'),
        (_) async => 1,
      );

  late Directory tempDir;
  late List<LocalImageRecord> records;
  late Map<String, (int, int)> dimensions;

  setUpAll(() async {
    await loadStudioCaptureFonts();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    tempDir = await Directory.systemTemp.createTemp('nai_gallery_layout_');
    (records, dimensions) = await _prepareImages(tempDir);
  });

  tearDownAll(() async {
    ThumbnailService.instance.cancelAll();
    try {
      await tempDir.delete(recursive: true);
    } on FileSystemException {
      // 图片句柄可能尚未释放
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      StorageKeys.hasSeenLocalGalleryTip: true,
    });
  });

  testWidgets(
    'recent and trash reuse the gallery without a dialog or sidebar shift',
    (tester) async {
      final container = await _pumpScreen(
        tester,
        records: records,
        dimensions: dimensions,
        locale: const Locale('zh'),
        dark: true,
        size: const Size(1600, 1000),
        extraOverrides: [
          galleryTrashTimelineProvider.overrideWith(
            (ref) async => [
              for (final r in records.take(2))
                GalleryTimelineEntry(
                  path: r.path,
                  modifiedAt: r.modifiedAt,
                  width: dimensions[r.path]?.$1,
                  height: dimensions[r.path]?.$2,
                ),
            ],
          ),
        ],
      );
      final gallery = container.read(localGalleryNotifierProvider.notifier);
      final beforeTitle = tester.getTopLeft(
        find.byKey(const Key('gallery-toolbar-sort')),
      );
      await tester.runAsync(() => gallery.recordViewed(records.first.path));
      await tester.tap(find.byKey(const Key('gallery-sidebar-recent')));
      await _settle(tester);
      expect(
        container.read(localGalleryNotifierProvider).browseScope,
        GalleryBrowseScope.recent,
      );
      expect(find.byType(GalleryTimelineView), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        container
            .read(localGalleryNotifierProvider)
            .timeline
            .entries
            .single
            .path,
        records.first.path,
      );
      await _capture(tester, 'recent-gallery');
      await tester.tap(find.byKey(const Key('gallery-sidebar-trash')));
      await _settle(tester);
      expect(
        container.read(localGalleryNotifierProvider).browseScope,
        GalleryBrowseScope.trash,
      );
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        tester.getTopLeft(find.byKey(const Key('gallery-toolbar-sort'))).dy,
        beforeTitle.dy,
      );
      final cards = tester.widgetList<LocalImageCard>(
        find.byType(LocalImageCard),
      );
      expect(cards.length, 2);
      expect(
        cards.every(
          (c) =>
              c.onFavoriteToggle == null &&
              c.onUseImage == null &&
              c.dragWrapper == null,
        ),
        isTrue,
      );
      await tester.tap(_cardFor(records.first));
      await _settle(tester);
      expect(find.byKey(const Key('gallery-inspector-reuse')), findsNothing);
      expect(find.text('恢复'), findsOneWidget);
      await tester.tap(_cardFor(records.first), buttons: kSecondaryMouseButton);
      await _settle(tester);
      expect(find.text('彻底删除'), findsOneWidget);
      await tester.tap(find.text('彻底删除'));
      await _settle(tester);
      expect(find.textContaining('不可恢复'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await _settle(tester);
      expect(
        await tester.runAsync(() => File(records.first.path).exists()),
        isTrue,
      );
      await _capture(tester, 'trash-gallery');
      await tester.tap(find.byKey(const Key('gallery-sidebar-all')));
      await _settle(tester);
      expect(
        container.read(localGalleryNotifierProvider).browseScope,
        GalleryBrowseScope.library,
      );
      expect(
        container.read(localGallerySelectionNotifierProvider).selectedIds,
        isEmpty,
      );
      expect(container.read(localGalleryFocusNotifierProvider), isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'R2 gallery bulk undo/redo never runs while search text is focused',
    (tester) async {
      final bulk = _RecordingBulkOperations();
      final container = await _pumpScreen(
        tester,
        records: records,
        dimensions: dimensions,
        locale: const Locale('zh'),
        dark: false,
        size: const Size(1600, 1000),
        extraOverrides: [
          bulkOperationNotifierProvider.overrideWith(() => bulk),
        ],
      );
      final field = find
          .descendant(
            of: find.byType(LocalGalleryToolbar),
            matching: find.byType(TextField),
          )
          .first;
      await tester.tap(field);
      await tester.pump();
      Future<void> type(String text) async {
        tester.testTextInput.updateEditingValue(
          TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          ),
        );
        await tester.pump(const Duration(milliseconds: 550));
      }

      Future<void> key(LogicalKeyboardKey key, {bool shift = false}) async {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(key);
        if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pump();
      }

      final controller = tester.widget<TextField>(field).controller!;
      await type('blue');
      await type('blue eyes');
      await key(LogicalKeyboardKey.keyZ);
      expect(controller.text, 'blue');
      await key(LogicalKeyboardKey.keyY);
      expect(controller.text, 'blue eyes');
      await key(LogicalKeyboardKey.keyZ);
      await key(LogicalKeyboardKey.keyZ, shift: true);
      expect(controller.text, 'blue eyes');
      expect(bulk.calls, isEmpty);
      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pump();
      tester
          .widget<KeyboardListener>(find.byType(KeyboardListener).first)
          .focusNode
          .requestFocus();
      await tester.pump();
      await key(LogicalKeyboardKey.keyZ);
      await _settle(tester);
      await key(LogicalKeyboardKey.keyY);
      await _settle(tester);
      expect(bulk.calls, ['undo', 'redo']);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tester.pump(const Duration(minutes: 1));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  final cases = <(Locale, bool, Size, String)>[
    (const Locale('zh'), false, const Size(1600, 1000), 'zh-light-wide'),
    (const Locale('zh'), true, const Size(1600, 1000), 'zh-dark-wide'),
    (const Locale('zh'), true, const Size(1920, 1080), 'zh-dark-1080p'),
    (const Locale('en'), false, const Size(1600, 1000), 'en-light-wide'),
    (const Locale('ja'), true, const Size(1600, 1000), 'ja-dark-wide'),
    (const Locale('ko'), false, const Size(1366, 768), 'ko-light-laptop'),
    (const Locale('zh'), false, const Size(1100, 760), 'zh-light-narrow'),
    (
      const Locale('zh', 'TW'),
      false,
      const Size(1600, 1000),
      'zh-TW-light-wide',
    ),
    (const Locale('zh', 'TW'), true, const Size(1600, 1000), 'zh-TW-dark-wide'),
  ];

  testWidgets('repeated app focus changes do not reload the gallery', (
    tester,
  ) async {
    final container = await _pumpScreen(
      tester,
      records: records,
      dimensions: dimensions,
      locale: const Locale('zh'),
      dark: false,
      size: const Size(1600, 1000),
    );
    final service =
        container.read(galleryServiceProvider) as FakeLocalGalleryService;
    final timelineRequests = service.timelineRequests;
    final before = container.read(localGalleryNotifierProvider).timeline;
    for (var i = 0; i < 3; i++) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump(const Duration(seconds: 6));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 6));
    }
    expect(service.refreshCount, 0);
    expect(service.timelineRequests, timelineRequests);
    expect(container.read(localGalleryNotifierProvider).timeline, same(before));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump(const Duration(minutes: 1));
  });

  testWidgets(
    'gallery context action imports original onto canvas and navigates home',
    (tester) async {
      final generation = _CanvasImportGeneration();
      final router = GoRouter(
        initialLocation: '/gallery',
        routes: [
          GoRoute(
            path: '/gallery',
            builder: (context, state) => const LocalGalleryScreen(),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: Text('canvas-home')),
          ),
        ],
      );
      addTearDown(router.dispose);
      final container = await _pumpScreen(
        tester,
        records: records,
        dimensions: dimensions,
        locale: const Locale('zh'),
        dark: false,
        size: const Size(1600, 1000),
        router: router,
        extraOverrides: [
          imageGenerationNotifierProvider.overrideWith(() => generation),
          localStorageServiceProvider.overrideWith(
            (ref) => InMemoryLocalStorageService(),
          ),
        ],
      );
      final draft = container.read(generationParamsNotifierProvider);
      final record = records.first;
      final original = await tester.runAsync(
        () => File(record.path).readAsBytes(),
      );
      await tester.tap(_cardFor(record), buttons: kSecondaryMouseButton);
      await _settle(tester);
      expect(find.text('放入画布'), findsOneWidget);
      await _capture(tester, 'canvas-context-action');
      await tester.tap(find.text('放入画布'));
      await _settle(tester);
      expect(find.text('canvas-home'), findsOneWidget);
      final image = container
          .read(imageGenerationNotifierProvider)
          .currentImages
          .single;
      expect(image.bytes, original);
      expect(image.filePath, isNull);
      expect(container.read(generationPreviewSelectionProvider), image.id);
      expect(
        container.read(canvasHistoryFocusRequestProvider)!.imageId,
        image.id,
      );
      expect(container.read(generationParamsNotifierProvider), same(draft));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tester.pump(const Duration(minutes: 1));
    },
  );

  testWidgets(
    'context copy uses captured original once and permits character-only Prompt',
    (tester) async {
      final record = records.first.copyWith(
        metadata: const NaiImageMetadata(
          prompt: '',
          characterPrompts: ['blue eyes'],
        ),
      );
      final copies = <String>[];
      final clipboard = _RecordingClipboard(copies.add);
      final container = await _pumpScreen(
        tester,
        records: [record, ...records.skip(1)],
        dimensions: dimensions,
        locale: const Locale('en'),
        dark: false,
        size: const Size(1600, 1000),
        extraOverrides: [
          imageClipboardServiceProvider.overrideWithValue(clipboard),
        ],
      );
      await tester.tap(_cardFor(record), buttons: kSecondaryMouseButton);
      await _settle(tester);
      final prompt = tester.widget<MenuItemButton>(
        find.ancestor(
          of: find.text('Copy Prompt'),
          matching: find.byType(MenuItemButton),
        ),
      );
      expect(prompt.onPressed, isNotNull);
      final button = tester.widget<MenuItemButton>(
        find.ancestor(
          of: find.text('Copy image'),
          matching: find.byType(MenuItemButton),
        ),
      );
      button.onPressed!();
      await tester.pump();
      for (var i = 0; i < 10 && copies.isEmpty; i++) {
        await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      expect(find.byKey(const Key('image-action-menu')), findsNothing);
      expect(copies, [record.path]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tester.pump(const Duration(minutes: 1));
    },
  );

  for (final (locale, dark, size, name) in cases) {
    testWidgets('local gallery three-pane layout $name', (tester) async {
      final container = await _pumpScreen(
        tester,
        records: records,
        dimensions: dimensions,
        locale: locale,
        dark: dark,
        size: size,
      );

      if (size.width > 800) {
        await _capture(tester, '$name-header');
        final l = AppLocalizations.of(
          tester.element(find.byType(LocalGalleryScreen)),
        )!;
        final title = find.text(l.localGallery_title);
        final toolbar = find.byType(LocalGalleryToolbar);
        final rowCenter = tester.getCenter(toolbar).dy;
        final breadcrumb = find.descendant(
          of: toolbar,
          matching: find.text(l.localGallery_allImages),
        );
        expect(tester.getCenter(breadcrumb).dy, closeTo(rowCenter, .6));
        expect(tester.getCenter(title).dy, closeTo(rowCenter, .6));
        expect(
          tester.getCenter(find.byType(GalleryAddMenuButton)).dy,
          closeTo(rowCenter, .6),
        );
        final add = find.byType(GalleryAddMenuButton);
        final addIcon = find.descendant(of: add, matching: find.byType(Icon));
        final addInk = find.descendant(
          of: add,
          matching: find.byWidgetPredicate((w) => w is InkResponse),
        );
        expect(tester.getRect(addIcon).center, tester.getRect(addInk).center);
      }

      // 单击第二张：进入查看，详情面板显示参数
      final cards = find.byType(LocalImageCard);
      expect(cards, findsWidgets);
      await tester.tap(cards.at(1));
      await _settle(tester);
      expect(container.read(localGalleryFocusNotifierProvider), isNotNull);

      final inspector = find.byType(GalleryInspectorPanel);
      if (size.width >= 1300) {
        expect(inspector, findsOneWidget);
        for (final button
            in tester
                .widgetList<IconButton>(
                  find.descendant(
                    of: inspector,
                    matching: find.byType(IconButton),
                  ),
                )
                .where(
                  (b) => b.style?.fixedSize?.resolve({}) == const Size(32, 32),
                )) {
          final host = find.byWidget(button);
          final icon = find.descendant(of: host, matching: find.byType(Icon));
          final ink = find.descendant(
            of: host,
            matching: find.byWidgetPredicate((w) => w is InkResponse),
          );
          expect(tester.getRect(icon).center, tester.getRect(ink).center);
        }
        expect(
          find.byKey(const Key('gallery-inspector-reuse')),
          findsOneWidget,
        );
      } else {
        expect(inspector, findsNothing);
      }

      // 悬停第五张：底部渐变与操作按钮
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(cards.at(4)));
      await _settle(tester, rounds: 4);

      expect(tester.takeException(), isNull);
      await _capture(tester, name);

      // 多选：底部浮动操作条
      container
          .read(localGallerySelectionNotifierProvider.notifier)
          .enterAndSelect(records[2].path);
      container
          .read(localGallerySelectionNotifierProvider.notifier)
          .select(records[3].path);
      await _settle(tester, rounds: 4);
      expect(
        find.byKey(const Key('gallery-floating-bulk-bar')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await _capture(tester, '$name-selection');

      // 只有一张图的那天：保持目标行高靠左，不被拉满整行；悬停按钮在右下角
      container.read(localGallerySelectionNotifierProvider.notifier).exit();
      final position = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(GalleryTimelineView),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      final lone = _cardFor(records[_loneIndex]);
      while (lone.evaluate().isEmpty &&
          position.pixels < position.maxScrollExtent) {
        position.jumpTo(
          (position.pixels + 300).clamp(0.0, position.maxScrollExtent),
        );
        await _settle(tester, rounds: 2);
      }
      await Scrollable.ensureVisible(
        tester.element(lone),
        alignment: 0.4,
        duration: Duration.zero,
      );
      await _settle(tester, rounds: 4);
      final loneCard = tester.widget<LocalImageCard>(lone);
      expect(loneCard.height, GalleryColumnWidthStore.defaultColumnWidth);
      final (w, h) = dimensions[records[_loneIndex].path]!;
      expect(loneCard.width, closeTo(loneCard.height * w / h, 0.5));
      await gesture.moveTo(tester.getCenter(lone));
      await _settle(tester, rounds: 4);
      expect(tester.takeException(), isNull);
      await _capture(tester, '$name-lone');

      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tester.pump(const Duration(minutes: 1));
    });
  }

  testWidgets(
    'card arrow opens the shared import dialog and cancellation preserves gallery state',
    (tester) async {
      final container = await _pumpScreen(
        tester,
        records: records,
        dimensions: dimensions,
        locale: const Locale('zh'),
        dark: false,
        size: const Size(1600, 1000),
      );
      final focusBefore = container.read(localGalleryFocusNotifierProvider);
      final recordBefore = records[1];
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(
        location: tester.getCenter(_cardFor(recordBefore)),
      );
      await tester.pumpAndSettle();
      final arrow = find.descendant(
        of: _cardFor(recordBefore),
        matching: find.byIcon(StudioIcons.gallerySend),
      );
      expect(arrow, findsOneWidget);
      await tester.tap(arrow);
      await _settle(tester, rounds: 20);
      expect(find.byType(ImageDestinationDialog), findsOneWidget);
      expect(find.byType(MenuItemButton), findsNothing);
      final dialog = tester.widget<ImageDestinationDialog>(
        find.byType(ImageDestinationDialog),
      );
      expect(dialog.metadata?.prompt, recordBefore.metadata?.prompt);
      expect(dialog.fileName, 'image_1.png');
      await _capture(tester, 'card-arrow-import-dialog');
      await tester.tap(find.byTooltip('关闭').last);
      await tester.pumpAndSettle();
      expect(find.byType(ImageDestinationDialog), findsNothing);
      expect(container.read(localGalleryFocusNotifierProvider), focusBefore);
      expect(records[1], recordBefore);
      expect(tester.takeException(), isNull);
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tester.pump(const Duration(minutes: 1));
    },
  );

  testWidgets(
    'inspector translates each field independently and stores at the click point',
    (tester) async {
      final disableShadows = debugDisableShadows;
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = disableShadows);
      final metadata = records[1].metadata!.copyWith(
        prompt: '1.5::blue eyes, white hair ::, scenery',
        characterPrompts: ['girl, 1.3::long hair::'],
        negativePrompt: 'lowres, 0.8::bad quality::',
      );
      final samples = [...records];
      samples[1] = samples[1].copyWith(metadata: metadata);
      final requests = <String>[];
      final container = await _pumpScreen(
        tester,
        records: samples,
        dimensions: dimensions,
        locale: const Locale('zh'),
        dark: false,
        size: const Size(1600, 1000),
        translator: (doc, _) async {
          requests.add(doc.text);
          return PillDocument(
            text: '\uE000',
            instances: {
              '\uE000': PillInstance(
                blockId: '',
                translation: TranslationPill(
                  source: doc.text,
                  zh: '测试译文：${doc.text}',
                  languageCode: 'zh',
                ),
              ),
            },
          );
        },
      );
      await tester.tap(_cardFor(samples[1]));
      await _settle(tester);
      expect(find.byType(PromptSection), findsAtLeastNWidgets(1));
      expect(requests, isEmpty);
      await _capture(tester, 'feedback-aligned-original');
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      for (var i = 0; i < 3; i++) {
        final field = ['positive', 'character-0', 'negative'][i];
        final section = find.byKey(
          ValueKey('gallery-prompt-${samples[1].path}-$field'),
        );
        await tester.scrollUntilVisible(
          section,
          200,
          scrollable: find
              .descendant(
                of: find.byType(GalleryInspectorPanel),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await Scrollable.ensureVisible(tester.element(section), alignment: .3);
        await tester.pumpAndSettle();
        await mouse.moveTo(tester.getCenter(section));
        await tester.pumpAndSettle();
        final button = find
            .descendant(
              of: section,
              matching: find.byKey(const Key('detail-prompt-translate')),
            )
            .hitTestable();
        expect(button, findsOneWidget);
        await _capture(tester, 'feedback-hover-field-$i');
        await tester.tap(button);
        await tester.pumpAndSettle();
        await _capture(tester, 'feedback-blocks-field-$i');
      }
      expect(requests, [
        metadata.prompt,
        metadata.characterPrompts.single,
        metadata.negativePrompt,
      ]);
      final section = find.byType(PromptSection).first;
      await Scrollable.ensureVisible(tester.element(section), alignment: .3);
      await tester.pumpAndSettle();
      final block = find.descendant(
        of: section,
        matching: find.byWidgetPredicate(
          (w) => w is Draggable<PromptBlockDragData>,
        ),
      );
      expect(
        tester
            .widget<Draggable<PromptBlockDragData>>(block)
            .data!
            .translation!
            .source,
        metadata.prompt,
      );
      await tester.tap(block);
      await tester.pumpAndSettle();
      expect(find.text('存入积木'), findsOneWidget);
      expect(find.byIcon(StudioIcons.promptBlockPalette), findsOneWidget);
      expect(tester.getSize(find.byType(MenuItemButton)).width, lessThan(190));
      await _capture(tester, 'feedback-gallery-store');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tester.pump(const Duration(minutes: 1));
      debugDisableShadows = disableShadows;
    },
  );

  testWidgets(
    'statistics navigation survives preference restoration and retained gallery updates',
    (tester) async {
      final criteria = FilterCriteria(
        naiOnly: false,
        indexedDate: true,
        dateEndExclusive: true,
        dateStart: DateTime(2026, 10, 5),
        dateEnd: DateTime(2026, 10, 12),
        filterMinSteps: 28,
        filterMaxSteps: 28,
      );
      final navigation = ValueNotifier<GalleryNavigationRequest?>(
        GalleryNavigationRequest(criteria: criteria),
      );
      addTearDown(navigation.dispose);
      final container = await _pumpScreen(
        tester,
        records: records,
        dimensions: dimensions,
        locale: const Locale('zh'),
        dark: false,
        size: const Size(1600, 1000),
        navigation: navigation,
      );
      expect(
        container.read(localGalleryNotifierProvider).filterCriteria,
        criteria,
      );
      final next = criteria.copyWith(filterMinSteps: 20, filterMaxSteps: 20);
      navigation.value = GalleryNavigationRequest(criteria: next);
      await _settle(tester);
      expect(container.read(localGalleryNotifierProvider).filterCriteria, next);
      await container
          .read(localGalleryNotifierProvider.notifier)
          .clearAllFilters();
      expect(
        container.read(localGalleryNotifierProvider).hasSessionFilters,
        isFalse,
      );
      navigation.value = null;
      await _settle(tester, rounds: 2);
      expect(
        container.read(localGalleryNotifierProvider).hasSessionFilters,
        isFalse,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tester.pump(const Duration(minutes: 1));
    },
  );

  testWidgets(
    'statistics navigation opens existing folder flow once per request without native IO',
    (tester) async {
      final picker = _CancelledFolderPicker();
      FilePicker.platform = picker;
      final navigation = ValueNotifier<GalleryNavigationRequest?>(
        GalleryNavigationRequest(addFolder: true),
      );
      addTearDown(navigation.dispose);
      final container = await _pumpScreen(
        tester,
        records: records,
        dimensions: dimensions,
        locale: const Locale('zh'),
        dark: false,
        size: const Size(1600, 1000),
        navigation: navigation,
      );
      expect(picker.calls, 1);
      container.read(localGalleryFocusNotifierProvider.notifier).clear();
      await _settle(tester, rounds: 2);
      expect(picker.calls, 1);
      navigation.value = GalleryNavigationRequest(addFolder: true);
      await _settle(tester);
      expect(picker.calls, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tester.pump(const Duration(minutes: 1));
    },
  );
}

class _CancelledFolderPicker extends FilePicker {
  var calls = 0;
  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
  }) async {
    calls++;
    return null;
  }
}

final _captureKey = GlobalKey();

/// 样本里独占一天的那张（真实样本中是 1920×1088 横图）
const _loneIndex = 10;

Finder _cardFor(LocalImageRecord record) => find.byWidgetPredicate(
  (widget) => widget is LocalImageCard && widget.record.path == record.path,
);

class _RecordingBulkOperations extends BulkOperationNotifier {
  final calls = <String>[];
  @override
  BulkOperationState build() =>
      const BulkOperationState(canUndo: true, canRedo: true);
  @override
  Future<void> undo() async {
    calls.add('undo');
  }

  @override
  Future<void> redo() async {
    calls.add('redo');
  }
}

Future<ProviderContainer> _pumpScreen(
  WidgetTester tester, {
  required List<LocalImageRecord> records,
  required Map<String, (int, int)> dimensions,
  required Locale locale,
  required bool dark,
  required Size size,
  Future<PillDocument> Function(PillDocument, String)? translator,
  ValueNotifier<GalleryNavigationRequest?>? navigation,
  GoRouter? router,
  List<Override> extraOverrides = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final service = FakeLocalGalleryService(records, dimensions: dimensions);
  final container = ProviderContainer(
    overrides: [
      ...extraOverrides,
      galleryFileMonitorProvider.overrideWith(
        (ref) => fakeGalleryFileMonitor(),
      ),
      if (translator != null)
        detailPromptTranslatorProvider.overrideWithValue(translator),
      galleryServiceProvider.overrideWith(
        () => FakeGalleryServiceNotifier(service),
      ),
      galleryCategoryNotifierProvider.overrideWith(_FakeCategoryNotifier.new),
      collectionNotifierProvider.overrideWith(_FakeCollectionNotifier.new),
      shortcutConfigNotifierProvider.overrideWith(
        _FakeShortcutConfigNotifier.new,
      ),
      kritaBridgeNotifierProvider.overrideWith(
        (ref) => _TestKritaBridgeNotifier(),
      ),
    ],
  );
  final theme = AppTheme.getTheme(
    AppStyle.geist,
    dark ? Brightness.dark : Brightness.light,
    fontConfig: FontConfig.defaultFont,
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: router != null
          ? MaterialApp.router(
              debugShowCheckedModeBanner: false,
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: theme,
              routerConfig: router,
              builder: (context, child) => RepaintBoundary(
                key: _captureKey,
                child: TextEditingShortcuts(
                  child: WindowChromeScope(child: _CaptionStub(child: child!)),
                ),
              ),
            )
          : MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: theme,
              builder: (context, child) => RepaintBoundary(
                key: _captureKey,
                child: TextEditingShortcuts(
                  child: WindowChromeScope(child: _CaptionStub(child: child!)),
                ),
              ),
              home: navigation == null
                  ? const LocalGalleryScreen()
                  : ValueListenableBuilder<GalleryNavigationRequest?>(
                      valueListenable: navigation,
                      builder: (context, request, _) =>
                          LocalGalleryScreen(navigationRequest: request),
                    ),
            ),
    ),
  );
  await _settle(tester, rounds: 30);
  return container;
}

/// 交替推进真实事件循环与假异步区：缩略图存在性检查与解码都是真实 IO。
Future<void> _settle(WidgetTester tester, {int rounds = 12}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (Platform.environment['CAPTURE_LOCAL_GALLERY'] != '1') return;
  await tester.runAsync(() async {
    final boundary =
        _captureKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory(
      Platform.environment['LOCAL_GALLERY_CAPTURE_DIR'] ??
          (Platform.environment['GALLERY_FOLLOWUP_CAPTURE'] == '1'
              ? '.dart_tool/gallery-followup-captures/gallery'
              : Platform.environment['GALLERY_FEEDBACK_CAPTURE'] == '1'
              ? '.dart_tool/gallery-feedback-captures/gallery'
              : '.dart_tool/local-gallery-captures'),
    )..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

/// 在右上角画出窗口按钮占位，便于核对标题栏避让。
class _CaptionStub extends StatelessWidget {
  const _CaptionStub({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned(
          top: 0,
          right: 0,
          width: WindowChromeScope.controlsWidth,
          height: WindowChromeScope.height,
          child: IgnorePointer(
            child: Row(
              children: [
                for (final icon in [
                  Icons.remove,
                  Icons.crop_square,
                  Icons.close,
                ])
                  Expanded(child: Icon(icon, size: 14, color: color)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TestKritaBridgeNotifier extends KritaBridgeNotifier {
  @override
  Future<void> close() async {}
}

class _CanvasImportGeneration extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();
}

class _FakeShortcutConfigNotifier extends ShortcutConfigNotifier {
  @override
  Future<ShortcutConfig> build() async => ShortcutConfig.createDefault();
}

class _FakeCollectionNotifier extends CollectionNotifier {
  @override
  CollectionState build() {
    final now = DateTime(2026, 9, 1);
    return CollectionState(
      collections: [
        ImageCollection(
          id: 'wof',
          name: 'W.O.F',
          createdAt: now,
          isFolder: true,
          imageCount: 77,
        ),
        ImageCollection(
          id: 'artists',
          name: '画师收藏集',
          createdAt: now,
          parentId: 'wof',
        ),
        ImageCollection(
          id: 'travel',
          name: '旅行',
          createdAt: now,
          parentId: 'wof',
          imageCount: 77,
        ),
      ],
    );
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> refresh() async {}
}

class _FakeCategoryNotifier extends GalleryCategoryNotifier {
  @override
  GalleryCategoryState build() {
    final now = DateTime(2026, 9, 1);
    GalleryCategory category(
      String id,
      String name,
      int count, {
      String? parent,
      int order = 0,
    }) => GalleryCategory(
      id: id,
      name: name,
      folderPath: parent == null ? name : '$parent/$name',
      parentId: parent,
      imageCount: count,
      sortOrder: order,
      createdAt: now,
      updatedAt: now,
    );
    return GalleryCategoryState(
      categories: [
        category('root', '01_图库', 48809),
        category('v3', 'NAI 3', 375, parent: 'root', order: 0),
        category('v4', 'NAI 4', 749, parent: 'root', order: 1),
        category('v45', 'NAI 4.5', 27049, parent: 'root', order: 2),
        category('v45r', 'R18', 7217, parent: 'v45', order: 0),
        category('v45n', '正常向', 19832, parent: 'v45', order: 1),
        category('v5', 'NAI 5', 17543, parent: 'root', order: 3),
        category('misc', '_杂物', 0, parent: 'root', order: 4),
        category('explore', 'style_explore_runs', 32, order: 1),
        category('uncategorized', galleryUncategorizedFolderName, 32, order: 1),
        category('d1', '2026-09-09', 3, order: 2),
        category('d2', '2026-09-13', 2, order: 3),
        category('d3', '2026-09-21', 1, order: 4),
      ],
    );
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<void> syncWithFileSystem() async {}
}

/// 准备样本：有 `GALLERY_CAPTURE_IMAGES` 时读真实缩略图与清单，否则生成色块图。
/// 每张图同时写好三档缩略图，卡片直接命中缓存而不进生成 isolate。
Future<(List<LocalImageRecord>, Map<String, (int, int)>)> _prepareImages(
  Directory dir,
) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 14);
  // 样本按时间倒序：今天 6 张、昨天 4 张、前天只有 [_loneIndex] 一张、更早 31 张
  final dates = [
    for (var i = 0; i < 6; i++) today.subtract(Duration(minutes: i * 7)),
    for (var i = 0; i < 4; i++)
      today.subtract(Duration(days: 1, minutes: i * 9)),
    today.subtract(const Duration(days: 2)),
    for (var i = 0; i < 31; i++)
      today.subtract(Duration(days: 3 + i ~/ 9, minutes: i * 11)),
  ];

  final source = Platform.environment['GALLERY_CAPTURE_IMAGES'];
  final samples = <(List<int>, int, int, Map<String, dynamic>)>[];
  if (source != null && File('$source/manifest.json').existsSync()) {
    final manifest =
        jsonDecode(File('$source/manifest.json').readAsStringSync()) as List;
    for (final item in manifest.cast<Map<String, dynamic>>()) {
      final file = File('$source/${item['src']}');
      if (!file.existsSync()) continue;
      samples.add((
        file.readAsBytesSync(),
        int.parse('${item['w']}'),
        int.parse('${item['h']}'),
        item,
      ));
    }
  }
  if (samples.isEmpty) {
    const sizes = [(832, 1216), (1216, 832), (1024, 1024)];
    for (var i = 0; i < 42; i++) {
      final (w, h) = sizes[i % 3];
      final image = img.Image(width: w ~/ 8, height: h ~/ 8);
      img.fill(
        image,
        color: img.ColorRgb8(
          60 + (i * 37) % 180,
          80 + (i * 53) % 150,
          100 + (i * 29) % 140,
        ),
      );
      samples.add((img.encodeJpg(image), w, h, const {}));
    }
  }

  final thumbs = Directory('${dir.path}${Platform.pathSeparator}.thumbs')
    ..createSync(recursive: true);
  final records = <LocalImageRecord>[];
  final dimensions = <String, (int, int)>{};
  for (var i = 0; i < samples.length && i < dates.length; i++) {
    final (bytes, w, h, meta) = samples[i];
    final path = '${dir.path}${Platform.pathSeparator}image_$i.png';
    File(path).writeAsBytesSync(bytes);
    for (final size in ThumbnailSize.values) {
      File(
        '${thumbs.path}${Platform.pathSeparator}'
        '${ThumbnailCacheService.buildThumbnailFileNameForTest(path, size: size)}',
      ).writeAsBytesSync(bytes);
    }
    dimensions[path] = (w, h);
    final ver = meta['ver'] as String?;
    records.add(
      LocalImageRecord(
        path: path,
        size: 1400000 + i * 3917,
        modifiedAt: dates[i],
        isFavorite: i % 7 == 3,
        metadata: NaiImageMetadata(
          prompt:
              (meta['prompt'] as String?) ??
              '1girl, solo, silver hair, blue eyes, black capelet, '
                  'outdoors, ocean, very aesthetic, masterpiece, no text',
          negativePrompt:
              (meta['uc'] as String?) ??
              'lowres, artistic error, film grain, scan artifacts, worst '
                  'quality, bad quality, jpeg artifacts, very displeasing, '
                  'chromatic aberration, multiple views, logo',
          seed: int.tryParse('${meta['seed']}') ?? 1313949686 + i,
          steps: int.tryParse('${meta['steps']}') ?? 23,
          scale: double.tryParse('${meta['scale']}') ?? 4.5,
          sampler: (meta['sampler'] as String?) ?? 'k_euler_ancestral',
          width: w,
          height: h,
          model: switch (ver) {
            'V4.5' => 'nai-diffusion-4-5-full',
            'NAI' => null,
            _ => 'nai-diffusion-5-full',
          },
          characterPrompts: _characterPrompts(meta['chars']),
        ),
      ),
    );
  }
  return (records, dimensions);
}

/// 清单里的角色提示词可能是列表或 Python 风格的列表字符串。
List<String> _characterPrompts(Object? raw) {
  if (raw is List) return [for (final item in raw) '$item'];
  if (raw is! String || raw.length < 4) return const [];
  return [raw.substring(2, raw.length - 2)];
}
