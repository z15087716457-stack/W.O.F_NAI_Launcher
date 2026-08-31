import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/data/services/gallery/gallery_delete_pool_store.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';

/// 注入已初始化服务的 GalleryService notifier（绕开 DatabaseManager 全量初始化）
class _InjectedGalleryService extends GalleryService {
  _InjectedGalleryService(this._injected);

  final LocalGalleryService _injected;

  @override
  LocalGalleryService build() => _injected;
}

/// 删除后图片应立即从 provider 的 currentImages 消失（内存级即时移除）。
///
/// 复现链路与 BulkOperationNotifier.bulkDelete 完全一致：
/// ① DB 软删 + ② 入池 + ③ removeDeletedImagesFromMemory。
/// 若此测试红，说明 provider 层内存移除断裂（UI 需切文件夹才刷新的根因）。
void main() {
  group('delete immediate removal (provider level)', () {
    late Directory tempDir;
    late Directory galleryRoot;
    late GalleryDataSource dataSource;
    late LocalGalleryServiceImpl service;
    late ProviderContainer container;
    late File fileA;
    late File fileB;
    late File fileC;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await AppLogger.initialize(isTestEnvironment: true);
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp(
        'nai_launcher_delete_immediate_',
      );
      galleryRoot = Directory(p.join(tempDir.path, 'gallery'));
      await galleryRoot.create(recursive: true);

      Hive.init(p.join(tempDir.path, 'hive'));
      await Hive.openBox(StorageKeys.settingsBox);
      await Hive.box(
        StorageKeys.settingsBox,
      ).put(StorageKeys.imageSavePath, galleryRoot.path);

      await ConnectionPoolHolder.initialize(
        dbPath: p.join(tempDir.path, 'gallery.db'),
        maxConnections: 2,
      );

      dataSource = GalleryDataSource();
      await dataSource.initialize();
      service = LocalGalleryServiceImpl(
        dataSource: dataSource,
        filterService: GalleryFilterService(dataSource),
      );

      fileA = File(p.join(galleryRoot.path, 'a.png'));
      await fileA.writeAsBytes(List.filled(200, 1));
      fileA.setLastModifiedSync(DateTime(2026, 8, 3, 10));

      fileB = File(p.join(galleryRoot.path, 'b.png'));
      await fileB.writeAsBytes(List.filled(100, 1));
      fileB.setLastModifiedSync(DateTime(2026, 8, 1, 10));

      fileC = File(p.join(galleryRoot.path, 'c.png'));
      await fileC.writeAsBytes(List.filled(50, 1));
      fileC.setLastModifiedSync(DateTime(2026, 8, 2, 10));

      for (final f in [fileA, fileB, fileC]) {
        final stat = await f.stat();
        await dataSource.upsertImage(
          filePath: f.path,
          fileName: p.basename(f.path),
          fileSize: stat.size,
          createdAt: stat.changed,
          modifiedAt: stat.modified,
        );
      }

      await service.initialize();

      container = ProviderContainer(
        overrides: [
          galleryServiceProvider.overrideWith(
            () => _InjectedGalleryService(service),
          ),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await GalleryDeletePoolStoreTestReset.reset();
      await ConnectionPoolHolder.getInstanceOrNull()?.dispose();
      await dataSource.dispose();
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('bulkDelete 后 currentImages 立即不含被删路径（不调 loadPage）', () async {
      final galleryNotifier = container.read(
        localGalleryNotifierProvider.notifier,
      );
      await galleryNotifier.initialize();
      await galleryNotifier.loadPage(0);

      var state = container.read(localGalleryNotifierProvider);
      expect(state.currentImages.length, 3, reason: '删除前当前页 3 张');

      // 与 BulkOperationNotifier.bulkDelete 相同的编排
      await dataSource.batchMarkAsDeleted([fileA.path]);
      await const GalleryDeletePoolStore().addAll([fileA.path]);
      await galleryNotifier.removeDeletedImagesFromMemory([fileA.path]);

      state = container.read(localGalleryNotifierProvider);
      expect(
        state.currentImages.map((r) => r.path),
        isNot(contains(fileA.path)),
        reason: '删除后 currentImages 应立即不含被删路径',
      );
      expect(state.currentImages.length, 2);
      expect(state.totalCount, 2);

      // 防线：随后任何 loadPage 也不得复活
      await galleryNotifier.loadPage(state.currentPage);
      state = container.read(localGalleryNotifierProvider);
      expect(
        state.currentImages.map((r) => r.path),
        isNot(contains(fileA.path)),
        reason: 'loadPage 不得复活软删文件',
      );
    });
  });
}

/// 测试间清掉删除池的 SharedPreferences 残留
class GalleryDeletePoolStoreTestReset {
  static Future<void> reset() async {
    await const GalleryDeletePoolStore().clear();
  }
}
