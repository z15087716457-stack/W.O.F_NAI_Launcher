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
import 'package:nai_launcher/data/services/bulk_operation_service.dart'
    hide bulkOperationServiceProvider;
import 'package:nai_launcher/data/services/gallery/gallery_delete_pool_store.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';
import 'package:nai_launcher/presentation/providers/bulk_operation_provider.dart';
import 'package:nai_launcher/presentation/providers/local_gallery_provider.dart';

class _InjectedGalleryService extends GalleryService {
  _InjectedGalleryService(this._injected);

  final LocalGalleryService _injected;

  @override
  LocalGalleryService build() => _injected;
}

/// 轻量 BulkOperationService：与真实 bulkDelete 相同的软删+入池动作，
/// 但绕开 DatabaseManager（测试环境直接用已建好的 dataSource）。
class _LightBulkService extends BulkOperationService {
  _LightBulkService(this._dataSource);

  final GalleryDataSource _dataSource;

  @override
  Future<BulkOperationResult> bulkDelete(
    List<String> imagePaths, {
    BulkProgressCallback? onProgress,
  }) async {
    await _dataSource.batchMarkAsDeleted(imagePaths);
    await const GalleryDeletePoolStore().addAll(imagePaths);
    onProgress?.call(
      current: imagePaths.length,
      total: imagePaths.length,
      currentItem: '',
      isComplete: true,
    );
    return (success: imagePaths.length, failed: 0, errors: <String>[]);
  }
}

/// 组合级复现：真实 BulkOperationNotifier.bulkDelete 全链
/// （service 软删 → removeDeletedImagesFromMemory → _setState）。
/// 若红：组合链断裂=「删除后图不立即消失」根因。
void main() {
  group('bulkDelete composition (notifier level)', () {
    late Directory tempDir;
    late Directory galleryRoot;
    late GalleryDataSource dataSource;
    late LocalGalleryServiceImpl service;
    late ProviderContainer container;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await AppLogger.initialize(isTestEnvironment: true);
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp(
        'nai_launcher_delete_bulk_',
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

      for (final name in ['a.png', 'b.png', 'c.png']) {
        final f = File(p.join(galleryRoot.path, name));
        await f.writeAsBytes(List.filled(100, 1));
        final stat = await f.stat();
        await dataSource.upsertImage(
          filePath: f.path,
          fileName: name,
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
          bulkOperationServiceProvider.overrideWithValue(
            _LightBulkService(dataSource),
          ),
        ],
      );
      final notifier = container.read(localGalleryNotifierProvider.notifier);
      await notifier.initialize();
      await notifier.loadPage(0);
    });

    tearDown(() async {
      addTearDown(container.dispose);
      await const GalleryDeletePoolStore().clear();
      await ConnectionPoolHolder.getInstanceOrNull()?.dispose();
      await dataSource.dispose();
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('BulkOperationNotifier.bulkDelete 后 currentImages 立即减少', () async {
      var state = container.read(localGalleryNotifierProvider);
      expect(state.currentImages.length, 3);

      final deletedPath = state.currentImages.first.path;
      final result = await container
          .read(bulkOperationNotifierProvider.notifier)
          .bulkDelete([deletedPath]);

      expect(result.success, 1);
      state = container.read(localGalleryNotifierProvider);
      expect(
        state.currentImages.map((r) => r.path),
        isNot(contains(deletedPath)),
        reason: 'bulkDelete 组合链应立即从 currentImages 移除被删图',
      );
      expect(state.currentImages.length, 2);
      expect(state.totalCount, 2);
    });
  });
}
