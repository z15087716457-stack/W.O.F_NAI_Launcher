import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/utils/gallery_storage_layout.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/gallery/gallery_category.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/gallery/gallery_category_tree_view.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';

void main() {
  late Directory hiveTempDir;

  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.now();
  final categories = [
    GalleryCategory(
      id: 'cat-p',
      name: 'parent',
      folderPath: 'parent',
      sortOrder: 0,
      imageCount: 1,
      createdAt: now,
      updatedAt: now,
    ),
    GalleryCategory(
      id: 'cat-c',
      parentId: 'cat-p',
      name: 'child',
      folderPath: 'parent/child',
      sortOrder: 0,
      imageCount: 1,
      createdAt: now,
      updatedAt: now,
    ),
  ];

  setUp(() async {
    hiveTempDir = await Directory.systemTemp.createTemp(
      'tree_expansion_persistence_test_',
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

  Widget buildTree() => ProviderScope(
    child: MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: GalleryCategoryTreeView(
          categories: categories,
          totalImageCount: 2,
          onCategorySelected: (_) {},
        ),
      ),
    ),
  );

  /// Hive 真实 I/O 必须放进 runAsync（testWidgets 假异步区里真 Future
  /// 无法落地，会把测试挂死）
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

  testWidgets(
    'uncategorized is a selectable archive and old dates remain accessible',
    (tester) async {
      await withHive(tester, () async {
        String? selected;
        final folders = [
          GalleryCategory.create(
            name: galleryUncategorizedFolderName,
            folderPath: galleryUncategorizedFolderName,
          ),
          GalleryCategory.create(name: '2026-10-01', folderPath: '2026-10-01'),
          GalleryCategory.create(name: '2026-10-02', folderPath: '2026-10-02'),
        ];
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              locale: const Locale('zh'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: GalleryCategoryTreeView(
                  categories: folders,
                  totalImageCount: 0,
                  onCategorySelected: (id) => selected = id,
                ),
              ),
            ),
          ),
        );
        await settle(tester);
        expect(find.text('未分类文件夹'), findsOneWidget);
        expect(find.byIcon(StudioIcons.galleryArchive), findsOneWidget);
        expect(find.text('日期文件夹'), findsNothing);
        expect(find.text('2026-10-01'), findsOneWidget);
        expect(find.text('2026-10-02'), findsOneWidget);
        await tester.tap(
          find.byKey(const Key('gallery-sidebar-uncategorized')),
        );
        expect(selected, folders.first.id);
      });
    },
  );

  testWidgets('expansion persists to storage and restores on rebuild', (
    tester,
  ) async {
    await withHive(tester, () async {
      await tester.pumpWidget(buildTree());
      await settle(tester);

      // 默认收起：child 不可见
      expect(find.text('parent'), findsOneWidget);
      expect(find.text('child'), findsNothing);

      // 点展开箭头 → child 出现
      await tester.tap(find.byIcon(StudioIcons.galleryChevronRight));
      await settle(tester);
      expect(find.text('child'), findsOneWidget);

      // 存储已写入展开 id
      expect(
        LocalStorageService().getGalleryCategoryTreeExpandedIds(),
        contains('cat-p'),
      );

      // 重建组件（模拟重启后再开）：initState 恢复 → child 直接可见
      await tester.pumpWidget(buildTree());
      await settle(tester);
      expect(find.text('child'), findsOneWidget);
    });
  });

  testWidgets('collapse also persists: rebuilt tree stays collapsed', (
    tester,
  ) async {
    await withHive(tester, () async {
      // 预置已展开状态
      await LocalStorageService().setGalleryCategoryTreeExpandedIds(['cat-p']);

      await tester.pumpWidget(buildTree());
      await settle(tester);
      expect(find.text('child'), findsOneWidget);

      // 收起 → child 消失、存储清空
      // 分组标题也有 expand_more：限定在「parent」这一行里找展开箭头
      final parentRow = find
          .ancestor(of: find.text('parent'), matching: find.byType(Row))
          .first;
      await tester.tap(
        find.descendant(
          of: parentRow,
          matching: find.byIcon(StudioIcons.galleryChevronDown),
        ),
      );
      await settle(tester);
      expect(find.text('child'), findsNothing);
      expect(
        LocalStorageService().getGalleryCategoryTreeExpandedIds(),
        isEmpty,
      );

      // 重建后仍收起
      await tester.pumpWidget(buildTree());
      await settle(tester);
      expect(find.text('child'), findsNothing);
    });
  });
}
