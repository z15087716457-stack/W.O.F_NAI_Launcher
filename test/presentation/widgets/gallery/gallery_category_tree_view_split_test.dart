import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/gallery/gallery_category.dart';
import 'package:nai_launcher/data/models/gallery/image_collection.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_category_tree_view.dart';

void main() {
  late Directory hiveTempDir;

  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.now();
  final categories = [
    GalleryCategory(
      id: 'cat-1',
      name: 'Landscape',
      folderPath: 'Landscape',
      sortOrder: 0,
      imageCount: 5,
      createdAt: now,
      updatedAt: now,
    ),
    GalleryCategory(
      id: 'cat-2',
      name: 'Portrait',
      folderPath: 'Portrait',
      sortOrder: 1,
      imageCount: 3,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  final collections = [
    ImageCollection(
      id: 'col-1',
      name: 'Favorites Sub',
      createdAt: now,
      imageCount: 2,
    ),
  ];

  setUp(() async {
    hiveTempDir = await Directory.systemTemp.createTemp(
      'tree_split_persistence_test_',
    );
  });

  tearDown(() async {
    if (await hiveTempDir.exists()) {
      await hiveTempDir.delete(recursive: true);
    }
  });

  /// 扫描进度面板带 repeat() 常驻动画，pumpAndSettle 永不落地，
  /// 用有限推进代替
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Widget buildTree({
    List<GalleryCategory> cats = const [],
    List<ImageCollection> cols = const [],
    double height = 1000.0,
  }) => ProviderScope(
    child: MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 260,
          height: height,
          child: GalleryCategoryTreeView(
            categories: cats,
            collections: cols,
            totalImageCount: 10,
            favoriteCount: 4,
            onCategorySelected: (_) {},
          ),
        ),
      ),
    ),
  );

  /// Hive 真实 I/O 必须放进 runAsync（testWidgets 假异步区里真 Future 无法落地）
  Future<void> withHive(WidgetTester tester, Future<void> Function() body) {
    return tester.runAsync(() async {
      Hive.init(hiveTempDir.path);
      await Hive.openBox(StorageKeys.settingsBox);
      try {
        await body();
      } finally {
        await Hive.close();
      }
    });
  }

  testWidgets('拆区后全部图片/收藏/收藏集/分类树条目全在，手柄存在且两区各自独立滚动', (tester) async {
    await withHive(tester, () async {
      await tester.pumpWidget(buildTree(cats: categories, cols: collections));
      await settle(tester);

      // 上区条目：全部图片、收藏、收藏集
      expect(find.text('全部图片'), findsOneWidget);
      expect(find.text('收藏'), findsOneWidget);
      expect(find.text('Favorites Sub'), findsOneWidget);

      // 下区条目：分类树
      expect(find.text('Landscape'), findsOneWidget);
      expect(find.text('Portrait'), findsOneWidget);

      // 手柄存在
      final handleFinder = find.byKey(
        const Key('gallery-sidebar-resize-handle'),
      );
      expect(handleFinder, findsOneWidget);

      // 两区各是一个独立 ListView
      expect(find.byType(ListView), findsNWidgets(2));

      // 手柄悬停光标为 SystemMouseCursors.resizeUpDown
      final mouseRegion = tester.widget<MouseRegion>(
        find.descendant(of: handleFinder, matching: find.byType(MouseRegion)),
      );
      expect(mouseRegion.cursor, SystemMouseCursors.resizeUpDown);
    });
  });

  testWidgets('无分类时退化为单列表，无手柄', (tester) async {
    await withHive(tester, () async {
      await tester.pumpWidget(buildTree(cats: const [], cols: collections));
      await settle(tester);

      // 全部图片、收藏、收藏集依然可见
      expect(find.text('全部图片'), findsOneWidget);
      expect(find.text('收藏'), findsOneWidget);
      expect(find.text('Favorites Sub'), findsOneWidget);

      // 手柄不存在
      expect(
        find.byKey(const Key('gallery-sidebar-resize-handle')),
        findsNothing,
      );

      // 单 ListView
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  testWidgets('拖动手柄修改比例且写回存储', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await withHive(tester, () async {
      await tester.pumpWidget(
        buildTree(cats: categories, cols: collections, height: 1000.0),
      );
      await settle(tester);

      final handleFinder = find.byKey(
        const Key('gallery-sidebar-resize-handle'),
      );
      expect(handleFinder, findsOneWidget);

      // 默认比例 0.45
      expect(LocalStorageService().getGallerySidebarCollectionSplit(), 0.45);

      // 向下拖动 100px (总高 1000，比例变化 +0.1 -> 0.55)
      final center = tester.getCenter(handleFinder);
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(0, 100));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // 验证存储已更新
      final savedRatio = LocalStorageService()
          .getGallerySidebarCollectionSplit();
      expect(savedRatio, closeTo(0.55, 0.01));
    });
  });

  testWidgets('拖拽比例钳制在 [0.2, 0.8] 上下限', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await withHive(tester, () async {
      await tester.pumpWidget(
        buildTree(cats: categories, cols: collections, height: 1000.0),
      );
      await settle(tester);

      final handleFinder = find.byKey(
        const Key('gallery-sidebar-resize-handle'),
      );

      // 向上大幅拖动 -600px -> 达到下限 0.2
      final gestureUp = await tester.startGesture(
        tester.getCenter(handleFinder),
      );
      await gestureUp.moveBy(const Offset(0, -600));
      await tester.pump();
      await gestureUp.up();
      await tester.pump();

      expect(LocalStorageService().getGallerySidebarCollectionSplit(), 0.2);

      // 向下大幅拖动 +800px -> 达到上限 0.8
      final gestureDown = await tester.startGesture(
        tester.getCenter(handleFinder),
      );
      await gestureDown.moveBy(const Offset(0, 800));
      await tester.pump();
      await gestureDown.up();
      await tester.pump();

      expect(LocalStorageService().getGallerySidebarCollectionSplit(), 0.8);
    });
  });

  testWidgets('重启（重建 widget）从存储恢复比例', (tester) async {
    await withHive(tester, () async {
      // 预先写入存储 0.65
      await LocalStorageService().setGallerySidebarCollectionSplit(0.65);
      expect(LocalStorageService().getGallerySidebarCollectionSplit(), 0.65);

      // 挂载组件
      await tester.pumpWidget(
        buildTree(cats: categories, cols: collections, height: 1000.0),
      );
      await settle(tester);

      // 验证两个 Expanded 的 flex 符合 650 : 350
      final expandedWidgets = tester
          .widgetList<Expanded>(find.byType(Expanded))
          .toList();
      // 上区 ListView 外层 Expanded
      final topExpanded = expandedWidgets.firstWhere(
        (e) => e.child is ListView && e.flex == 650,
      );
      expect(topExpanded.flex, 650);

      final bottomExpanded = expandedWidgets.firstWhere(
        (e) => e.child is ListView && e.flex == 350,
      );
      expect(bottomExpanded.flex, 350);
    });
  });
}
