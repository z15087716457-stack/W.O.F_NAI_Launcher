import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/data/services/gallery/gallery_filter_service.dart';
import 'package:nai_launcher/data/services/gallery/scan_state_manager.dart';
import 'package:nai_launcher/data/services/gallery/gallery_sort.dart';
import 'package:nai_launcher/data/services/gallery/unified_gallery_service.dart';

/// 对拍样本。
///
/// 每个排序字段的键都互异（大小/修改时间/文件名/面积各不相同），
/// List.sort 不稳定也不会影响期望序。
class _Sample {
  const _Sample({
    required this.name,
    required this.path,
    required this.size,
    required this.modified,
    required this.width,
    required this.height,
  });

  final String name;
  final String path;
  final int size;
  final DateTime modified;
  final int width;
  final int height;

  String get nameKey => name.toLowerCase();
  int get area => width * height;
}

/// 基础样本（排序字段键互异：size 100..600、modified 08-01..08-06、area 各不同）
List<_Sample> _sampleSpecs(String rootPath) => [
  _Sample(
    name: 'a.png',
    path: p.join(rootPath, 'a.png'),
    size: 300,
    modified: DateTime(2026, 8, 3, 10),
    width: 250,
    height: 200,
  ),
  _Sample(
    name: 'b.png',
    path: p.join(rootPath, 'b.png'),
    size: 100,
    modified: DateTime(2026, 8, 6, 10),
    width: 200,
    height: 100,
  ),
  _Sample(
    name: 'c.png',
    path: p.join(rootPath, 'c.png'),
    size: 500,
    modified: DateTime(2026, 8, 1, 10),
    width: 300,
    height: 300,
  ),
  _Sample(
    name: 'd.png',
    path: p.join(rootPath, 'd.png'),
    size: 200,
    modified: DateTime(2026, 8, 5, 10),
    width: 100,
    height: 100,
  ),
  _Sample(
    name: 'e.png',
    path: p.join(rootPath, 'e.png'),
    size: 600,
    modified: DateTime(2026, 8, 2, 10),
    width: 350,
    height: 200,
  ),
  _Sample(
    name: 'f.png',
    path: p.join(rootPath, 'f.png'),
    size: 400,
    modified: DateTime(2026, 8, 4, 10),
    width: 150,
    height: 200,
  ),
];

/// 测试中途新出现（初始化后才落盘）的样本：键与全部基础样本互异
_Sample _newSample(String rootPath, String suffix, {required int seed}) =>
    _Sample(
      name: 'g_$suffix.png',
      path: p.join(rootPath, 'g_$suffix.png'),
      size: 700 + seed * 10,
      modified: DateTime(2026, 8, 7 + seed, 10),
      width: 400 + seed * 10,
      height: 200,
    );

/// 期望序的独立实现（不复用 GallerySort.compareFiles，避免自证）
int _compareSamples(_Sample left, _Sample right, GallerySort sort) {
  final primary = switch (sort.field) {
    GallerySortField.modifiedAt => left.modified.compareTo(right.modified),
    // 内存路径的「创建时间」口径 = 文件 mtime（_ensureFileStats 同口径）
    GallerySortField.createdAt => left.modified.compareTo(right.modified),
    GallerySortField.fileName => left.nameKey.compareTo(right.nameKey),
    GallerySortField.fileSize => left.size.compareTo(right.size),
    GallerySortField.imageDimensions => left.area.compareTo(right.area),
  };
  if (primary != 0) {
    return sort.direction == GallerySortDirection.ascending
        ? primary
        : -primary;
  }
  return left.nameKey.compareTo(right.nameKey);
}

void main() {
  group('LocalGalleryService favorite changes keep the active sort order', () {
    late Directory tempDir;
    late Directory galleryRoot;
    late GalleryDataSource dataSource;
    late LocalGalleryServiceImpl service;
    late Map<String, _Sample> sampleByPath;
    late Map<String, _Sample> sampleByName;

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await AppLogger.initialize(isTestEnvironment: true);
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'nai_launcher_gallery_favorite_sort_',
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

      final samples = _sampleSpecs(galleryRoot.path);
      sampleByPath = {for (final sample in samples) sample.path: sample};
      sampleByName = {for (final sample in samples) sample.name: sample};
      for (final sample in samples) {
        await _writeSample(sample);
      }

      await service.initialize();
      await _waitForBackgroundScan();
      // 面积排序的键来自 DB 宽高（初始化扫描解析不出伪 PNG 的尺寸）
      await _registerDimensions(dataSource, samples);
    });

    tearDown(() async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await service.dispose();
      await dataSource.dispose();
      await ConnectionPoolHolder.dispose();
      await Hive.close();

      if (await tempDir.exists()) {
        await _deleteDirectoryWithRetry(tempDir);
      }
    });

    for (final field in GallerySortField.values) {
      test('${field.name}: 收藏/取消/新图/批量取消与全量重排序一致', () async {
        for (final direction in GallerySortDirection.values) {
          final sort = GallerySort(field: field, direction: direction);
          await service.setSort(sort);
          _expectOrder(service, sampleByPath, sort);

          // 已跟踪图片：收藏切换不改排序键，应零比较（不再全量重排）
          final tracked = sampleByName['a.png']!;
          service.sortComparisonsForTesting = 0;
          expect(await service.toggleFavorite(tracked.path), isTrue);
          _expectOrder(service, sampleByPath, sort);
          expect(
            service.sortComparisonsForTesting,
            0,
            reason: '已跟踪图片的收藏切换不应触发任何排序比较',
          );

          expect(await service.toggleFavorite(tracked.path), isFalse);
          _expectOrder(service, sampleByPath, sort);
          expect(service.sortComparisonsForTesting, 0);

          // 初始化后才落盘的新图片：单点二分归位（O(log N) 比较，非全量重排）
          final newSample = _newSample(
            galleryRoot.path,
            direction.name,
            seed: direction == GallerySortDirection.ascending ? 2 : 1,
          );
          await _writeSample(newSample);
          await _registerDimensions(dataSource, [newSample]);
          sampleByPath[newSample.path] = newSample;

          service.sortComparisonsForTesting = 0;
          expect(await service.toggleFavorite(newSample.path), isTrue);
          _expectOrder(service, sampleByPath, sort);
          expect(service.sortComparisonsForTesting, greaterThan(0));
          expect(
            service.sortComparisonsForTesting,
            lessThanOrEqualTo(8),
            reason: '新图片归位应为二分插入（O(log N)），不是全量重排',
          );

          // 批量取消收藏：剩余序与全量重排一致
          final first = sampleByName['e.png']!;
          final second = sampleByName['f.png']!;
          expect(await service.toggleFavorite(first.path), isTrue);
          expect(await service.toggleFavorite(second.path), isTrue);
          _expectOrder(service, sampleByPath, sort);

          service.sortComparisonsForTesting = 0;
          await service.unfavoriteImages([first.path, second.path]);
          _expectOrder(service, sampleByPath, sort);
          expect(
            service.sortComparisonsForTesting,
            0,
            reason: '批量取消收藏不应触发全量重排',
          );
        }
      });
    }

    test('收藏过滤视图的成员与序随收藏变更同步', () async {
      await service.setSort(
        const GallerySort(
          field: GallerySortField.fileName,
          direction: GallerySortDirection.descending,
        ),
      );
      await service.setShowFavoritesOnly(true);
      expect(await service.getPage(0, pageSize: 100), isEmpty);

      final sampleB = sampleByName['b.png']!;
      final sampleD = sampleByName['d.png']!;
      await service.toggleFavorite(sampleB.path);
      await service.toggleFavorite(sampleD.path);

      var page = await service.getPage(0, pageSize: 100);
      expect(
        [for (final record in page) p.basename(record.path)],
        ['d.png', 'b.png'],
      );

      await service.unfavoriteImages([sampleD.path]);
      page = await service.getPage(0, pageSize: 100);
      expect([for (final record in page) p.basename(record.path)], ['b.png']);
    });

    test('refresh 后的首次收藏变更按当前排序兜底重排（保持旧可观察序列）', () async {
      const sort = GallerySort(
        field: GallerySortField.imageDimensions,
        direction: GallerySortDirection.descending,
      );
      await service.setSort(sort);
      _expectOrder(service, sampleByPath, sort);

      // refresh 重建的列表只按「修改时间/大小/文件名」有序（面积键被重置），
      // 旧实现由「下次收藏变更触发全量重排」把列表拉回当前排序
      await service.refresh(scan: false);
      service.sortComparisonsForTesting = 0;

      expect(await service.toggleFavorite(sampleByName['a.png']!.path), isTrue);

      _expectOrder(service, sampleByPath, sort);
      expect(
        service.sortComparisonsForTesting,
        greaterThan(0),
        reason: 'refresh 后的列表与当前排序不一致，首次收藏变更应兜底全量重排',
      );
    });
  });
}

/// 断言当前跟踪列表的顺序 == 独立实现的期望序
void _expectOrder(
  LocalGalleryServiceImpl service,
  Map<String, _Sample> sampleByPath,
  GallerySort sort,
) {
  final actual = [for (final file in service.allFilesForTesting) file.path];
  for (final path in actual) {
    if (!sampleByPath.containsKey(path)) {
      fail('tracked file has no sample spec: $path');
    }
  }
  final expected = [...actual]
    ..sort(
      (left, right) =>
          _compareSamples(sampleByPath[left]!, sampleByPath[right]!, sort),
    );
  expect(actual, expected);
}

Future<void> _writeSample(_Sample sample) async {
  final file = File(sample.path);
  await file.writeAsBytes(List<int>.filled(sample.size, 1));
  file.setLastModifiedSync(sample.modified);
}

Future<void> _registerDimensions(
  GalleryDataSource dataSource,
  List<_Sample> samples,
) async {
  for (final sample in samples) {
    await dataSource.upsertImage(
      filePath: sample.path,
      fileName: sample.name,
      fileSize: sample.size,
      width: sample.width,
      height: sample.height,
      createdAt: sample.modified,
      modifiedAt: sample.modified,
    );
  }
}

/// 等 initialize() 触发的后台扫描收尾（DB 尺寸登记必须在扫描之后）
Future<void> _waitForBackgroundScan() async {
  await Future<void>.delayed(const Duration(milliseconds: 800));
  for (var attempt = 0; attempt < 100; attempt++) {
    if (!ScanStateManager.instance.isScanning) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

Future<void> _deleteDirectoryWithRetry(Directory directory) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
      return;
    } on FileSystemException {
      if (attempt == 9) rethrow;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
}
