import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/gallery/gallery_category.dart';
import 'package:nai_launcher/data/repositories/gallery_category_repository.dart';
import 'package:nai_launcher/presentation/providers/gallery_category_provider.dart';

class _FakeCategoryRepository extends GalleryCategoryRepository {
  _FakeCategoryRepository() : super.forTesting();

  Completer<List<GalleryCategory>>? loadCompleter;
  List<GalleryCategory> storedCategories = [];
  bool configFileExists = true;
  int syncCallCount = 0;

  @override
  Future<bool> hasCategoriesConfigFile() async => configFileExists;

  @override
  Future<bool> isCategoriesConfigGenuinelyEmpty() async =>
      storedCategories.isEmpty;

  @override
  Future<List<GalleryCategory>> loadCategories() async {
    if (loadCompleter != null) {
      return await loadCompleter!.future;
    }
    return storedCategories;
  }

  @override
  Future<int> countImagesInCategory(
    GalleryCategory category, {
    bool includeDescendants = true,
  }) async => 5;

  @override
  Future<List<GalleryCategory>> syncWithFileSystem(
    List<GalleryCategory> existingCategories,
  ) async {
    syncCallCount++;
    // 模拟真实仓库行为：若传入空列表，误判为全新文件夹并重分配随机 UUID；
    // 若传入现有分类，保留既有 UUID。
    if (existingCategories.isEmpty) {
      return [GalleryCategory.create(name: 'Category1', folderPath: 'cat1')];
    }
    return existingCategories
        .map((c) => c.updateImageCount(c.imageCount + 1))
        .toList();
  }

  @override
  Future<bool> saveCategories(List<GalleryCategory> categories) async {
    storedCategories = categories;
    return true;
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDown(() {
    GalleryCategoryNotifier.testRepositoryOverride = null;
  });

  group('GalleryCategoryNotifier race guard & UUID preservation (B-1)', () {
    test('慢加载期间触发 syncWithFileSystem 不会洗牌 UUID', () async {
      final repo = _FakeCategoryRepository();
      final originalCategory = GalleryCategory(
        id: 'stable-uuid-12345',
        name: 'Category1',
        folderPath: 'cat1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      repo.storedCategories = [originalCategory];
      repo.loadCompleter = Completer<List<GalleryCategory>>();
      GalleryCategoryNotifier.testRepositoryOverride = repo;

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(galleryCategoryNotifierProvider.notifier);

      // 此时 _loadCategories 挂起中，state.categories 为空
      expect(
        container.read(galleryCategoryNotifierProvider).categories,
        isEmpty,
      );

      // 模拟首屏竞态：在 _loadCategories 完成前调用 syncWithFileSystem
      final syncFuture = notifier.syncWithFileSystem();

      // 在途状态应等待，此时尚未完成同步
      expect(
        container.read(galleryCategoryNotifierProvider).categories,
        isEmpty,
      );

      // 模拟后台耗时递归数文件完成后释放
      repo.loadCompleter!.complete([originalCategory]);
      await syncFuture;

      final resultCategories = container
          .read(galleryCategoryNotifierProvider)
          .categories;
      expect(resultCategories, isNotEmpty);
      // 核心断言：UUID 必须与配置文件一致，绝不能被重分配！
      expect(resultCategories.first.id, equals('stable-uuid-12345'));
    });

    test('并发调用 syncWithFileSystem 幂等，等待同一个在途加载', () async {
      final repo = _FakeCategoryRepository();
      final originalCategory = GalleryCategory(
        id: 'stable-uuid-88888',
        name: 'Category1',
        folderPath: 'cat1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      repo.storedCategories = [originalCategory];
      repo.loadCompleter = Completer<List<GalleryCategory>>();
      GalleryCategoryNotifier.testRepositoryOverride = repo;

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(galleryCategoryNotifierProvider.notifier);

      // 多个调用方同时发起 syncWithFileSystem
      final future1 = notifier.syncWithFileSystem();
      final future2 = notifier.syncWithFileSystem();
      final future3 = notifier.syncWithFileSystem();

      // 释放底层加载
      repo.loadCompleter!.complete([originalCategory]);

      await Future.wait([future1, future2, future3]);

      final resultCategories = container
          .read(galleryCategoryNotifierProvider)
          .categories;
      expect(resultCategories.first.id, equals('stable-uuid-88888'));
      // 守卫幂等：多个并发调用复用同一个在途同步
      expect(repo.syncCallCount, equals(1));
    });

    test('新安装无配置文件时首次自动发现并同步分类', () async {
      final repo = _FakeCategoryRepository();
      repo.configFileExists = false;
      repo.storedCategories = [];
      GalleryCategoryNotifier.testRepositoryOverride = repo;

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(galleryCategoryNotifierProvider.notifier);

      // 手动触发 _doLoadCategories 等价过程（通过 refresh）
      await notifier.refresh();

      // 新安装应当调用 syncWithFileSystem 创建初始分类
      expect(repo.syncCallCount, equals(1));
      expect(repo.storedCategories, isNotEmpty);
      expect(
        container.read(galleryCategoryNotifierProvider).categories,
        isNotEmpty,
      );
    });
  });
}
