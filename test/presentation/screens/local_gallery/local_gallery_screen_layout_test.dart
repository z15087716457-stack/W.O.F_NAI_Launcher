// ignore: depend_on_referenced_packages
import 'package:irondash_message_channel/irondash_message_channel.dart';
// ignore: implementation_imports, depend_on_referenced_packages
import 'package:super_native_extensions/src/native/context.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_inspector_panel.dart';
import 'package:nai_launcher/presentation/widgets/gallery/local_image_card.dart';
import 'package:nai_launcher/presentation/widgets/gallery/timeline/gallery_timeline_view.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_local_gallery_service.dart';
import '../../../helpers/studio_capture_fonts.dart';

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

  final cases = <(Locale, bool, Size, String)>[
    (const Locale('zh'), false, const Size(1600, 1000), 'zh-light-wide'),
    (const Locale('zh'), true, const Size(1600, 1000), 'zh-dark-wide'),
    (const Locale('zh'), true, const Size(1920, 1080), 'zh-dark-1080p'),
    (const Locale('en'), false, const Size(1600, 1000), 'en-light-wide'),
    (const Locale('ja'), true, const Size(1600, 1000), 'ja-dark-wide'),
    (const Locale('ko'), false, const Size(1366, 768), 'ko-light-laptop'),
    (const Locale('zh'), false, const Size(1100, 760), 'zh-light-narrow'),
  ];

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

      // 单击第二张：进入查看，详情面板显示参数
      final cards = find.byType(LocalImageCard);
      expect(cards, findsWidgets);
      await tester.tap(cards.at(1));
      await _settle(tester);
      expect(container.read(localGalleryFocusNotifierProvider), isNotNull);

      final inspector = find.byType(GalleryInspectorPanel);
      if (size.width >= 1300) {
        expect(inspector, findsOneWidget);
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
}

final _captureKey = GlobalKey();

/// 样本里独占一天的那张（真实样本中是 1920×1088 横图）
const _loneIndex = 10;

Finder _cardFor(LocalImageRecord record) => find.byWidgetPredicate(
  (widget) => widget is LocalImageCard && widget.record.path == record.path,
);

Future<ProviderContainer> _pumpScreen(
  WidgetTester tester, {
  required List<LocalImageRecord> records,
  required Map<String, (int, int)> dimensions,
  required Locale locale,
  required bool dark,
  required Size size,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final service = FakeLocalGalleryService(records, dimensions: dimensions);
  final container = ProviderContainer(
    overrides: [
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
  final theme = dark ? GeistTheme.dark : GeistTheme.light;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: theme,
        builder: (context, child) => RepaintBoundary(
          key: _captureKey,
          child: WindowChromeScope(child: _CaptionStub(child: child!)),
        ),
        home: const LocalGalleryScreen(),
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
    final dir = Directory('.dart_tool/local-gallery-captures')
      ..createSync(recursive: true);
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
