import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/cache/thumbnail_cache_service.dart';

void main() {
  group('ThumbnailCacheService thumbnail filename helpers', () {
    test('应能从 Windows 混合分隔符路径中提取正确文件名', () {
      expect(
        ThumbnailCacheService.extractOriginalFileNameForTest(
          r'G:\AIdarw\novelai/NAI_1775993430335.png',
        ),
        'NAI_1775993430335.png',
      );
    });

    test('应为混合分隔符路径生成稳定缩略图文件名', () {
      expect(
        ThumbnailCacheService.buildThumbnailFileNameForTest(
          r'G:\AIdarw\novelai/NAI_1775993430335.png',
          size: ThumbnailSize.small,
        ),
        'NAI_1775993430335.png.small.thumb.jpg',
      );
    });

    test('直接生成缩略图后并发计数应恢复到调用前状态', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'nai_launcher_thumbnail_counter_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final imageFile = File('${tempDir.path}${Platform.pathSeparator}a.png');
      await imageFile.writeAsBytes(
        img.encodePng(img.Image(width: 32, height: 32)),
      );

      final service = ThumbnailCacheService.instance;
      await service.init();
      final activeBefore = service.getStats()['activeGenerations'] as int;

      final thumbnailPath = await service.generateThumbnail(
        imageFile.path,
        size: ThumbnailSize.small,
      );

      expect(thumbnailPath, isNotNull);
      expect(await File(thumbnailPath!).exists(), isTrue);
      expect(service.getStats()['activeGenerations'], activeBefore);
    });

    test('同一路径不同尺寸并发生成不会串档', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'nai_launcher_thumbnail_sizes_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final imageFile = File('${tempDir.path}${Platform.pathSeparator}a.png');
      await imageFile.writeAsBytes(
        img.encodePng(img.Image(width: 900, height: 600)),
      );

      final service = ThumbnailCacheService.instance;
      await service.init();
      final paths = await Future.wait([
        service.generateThumbnail(imageFile.path, size: ThumbnailSize.small),
        service.generateThumbnail(imageFile.path, size: ThumbnailSize.medium),
      ]);

      expect(paths[0], endsWith('.small.thumb.jpg'));
      expect(paths[1], endsWith('.medium.thumb.jpg'));
      expect(await File(paths[0]!).exists(), isTrue);
      expect(await File(paths[1]!).exists(), isTrue);
    });

    test('同一路径同尺寸并发请求共享一个终态', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'nai_launcher_thumbnail_dedup_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final imageFile = File('${tempDir.path}${Platform.pathSeparator}a.png');
      await imageFile.writeAsBytes(
        img.encodePng(img.Image(width: 900, height: 600)),
      );

      final service = ThumbnailCacheService.instance;
      await service.init();
      final before = service.getStats()['generatedCount'] as int;
      final paths = await Future.wait([
        service.generateThumbnail(imageFile.path, size: ThumbnailSize.large),
        service.generateThumbnail(imageFile.path, size: ThumbnailSize.large),
      ]);

      expect(paths[0], paths[1]);
      expect(service.getStats()['generatedCount'], before + 1);
    });
  });

  group('ThumbnailCacheService 失败冷却剩余时间', () {
    test('无失败记录时剩余时间为零', () {
      final service = ThumbnailCacheService.instance;
      expect(service.failureCooldownRemaining(r'C:\nope\a.png'), Duration.zero);
    });

    test('失败后剩余时间从冷却时长递减、过期后归零并清除记录', () {
      final service = ThumbnailCacheService.instance;
      service.setFailureRetryCooldownForTesting(const Duration(seconds: 5));
      addTearDown(
        () => service.setFailureRetryCooldownForTesting(
          const Duration(seconds: 10),
        ),
      );

      const path = r'C:\nope\cooldown.png';
      service.seedFailureRecordForTesting(
        path,
        failedAt: DateTime.now().subtract(const Duration(seconds: 2)),
      );

      final remaining = service.failureCooldownRemaining(path);
      expect(remaining, greaterThan(Duration.zero));
      expect(remaining, lessThanOrEqualTo(const Duration(seconds: 3)));

      // 过期记录在查询时被清除：下一次查询直接为零
      service.seedFailureRecordForTesting(
        path,
        failedAt: DateTime.now().subtract(const Duration(seconds: 30)),
      );
      expect(service.failureCooldownRemaining(path), Duration.zero);
      expect(service.failureCooldownRemaining(path), Duration.zero);
    });

    test('不同档位的冷却记录互不影响', () {
      final service = ThumbnailCacheService.instance;
      const path = r'C:\nope\tier.png';
      service.seedFailureRecordForTesting(path, failedAt: DateTime.now());

      expect(
        service.failureCooldownRemaining(path, size: ThumbnailSize.small),
        greaterThan(Duration.zero),
      );
      expect(
        service.failureCooldownRemaining(path, size: ThumbnailSize.medium),
        Duration.zero,
      );
    });
  });
}
