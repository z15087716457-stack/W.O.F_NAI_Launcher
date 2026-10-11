import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/data/services/statistics_cache_service.dart';

import '../../presentation/wiring/statistics_fakes.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'statistics_cache_service_',
    );
    Hive.init(hiveDirectory.path);
    await Hive.openBox(StorageKeys.statisticsCacheBox);
  });

  setUp(() async {
    await Hive.box(StorageKeys.statisticsCacheBox).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test(
    'new cache round-trips every aggregate and isolates filter combinations',
    () async {
      final repository = FakeStatisticsRepository();
      final calculatedAt = DateTime(2026, 10, 11, 12);
      final cached = StatisticsDashboardCache(
        snapshot: repository.dashboard,
        artists: repository.artists,
        signature: 'test:1',
        calculatedAt: calculatedAt,
      );
      final service = StatisticsCacheService();
      await service.saveDashboardCache('all:false', cached);
      await service.saveDashboardCache('days7:true', cached);
      final restored = service.getDashboardCache('all:false')!;
      expect(restored.snapshot.toJson(), repository.dashboard.toJson());
      expect(restored.artists!.toJson(), repository.artists.toJson());
      expect(restored.signature, 'test:1');
      expect(restored.calculatedAt, calculatedAt);
      await service.clearDashboardCache('days7:true');
      expect(service.getDashboardCache('days7:true'), isNull);
      expect(service.getDashboardCache('all:false'), isNotNull);
    },
  );

  test(
    'corrupt new cache is ignored without destroying other entries',
    () async {
      await Hive.box(
        StorageKeys.statisticsCacheBox,
      ).put('dashboard_v2:all:false', '{bad json');
      expect(StatisticsCacheService().getDashboardCache('all:false'), isNull);
    },
  );

  test('settings cleanup clears new and legacy cache entries', () async {
    final box = Hive.box(StorageKeys.statisticsCacheBox);
    await box.putAll({
      'dashboard_v2:all:false': '{}',
      'dashboard_v2:days7:true': '{}',
      StorageKeys.statisticsCacheData: '{}',
      StorageKeys.statisticsCacheMetadata: '{}',
      'unrelated': 1,
    });
    await StatisticsCacheService().clearCache();
    expect(box.keys.toList(), ['unrelated']);
  });

  test(
    'generation count update remains compatible with legacy metadata',
    () async {
      final metadata = StatisticsCacheMetadata(
        imageCount: 10,
        cachedAt: DateTime(2026, 10, 11),
        galleryPath: 'fake gallery',
      );
      await Hive.box(
        StorageKeys.statisticsCacheBox,
      ).put(StorageKeys.statisticsCacheMetadata, jsonEncode(metadata.toJson()));
      final service = StatisticsCacheService();
      await service.incrementImageCount(2);
      expect(service.getCacheMetadata()!.imageCount, 12);
      expect(service.getCacheMetadata()!.cachedAt, metadata.cachedAt);
      expect(service.getCacheMetadata()!.galleryPath, metadata.galleryPath);
    },
  );
}
