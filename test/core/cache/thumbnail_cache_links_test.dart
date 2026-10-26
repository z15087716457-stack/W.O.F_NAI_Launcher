import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/cache/thumbnail_cache_service.dart';

import '../../helpers/app_logger_test_isolation.dart';

void main() {
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  for (final operation in ['lru', 'before', 'clear', 'stats']) {
    test('$operation does not follow nested cache links', () async {
      final root = await Directory.systemTemp.createTemp('thumbnail_links_');
      final gallery = Directory('${root.path}/gallery');
      final thumbs = Directory('${gallery.path}/.thumbs');
      final outside = Directory('${root.path}/outside');
      final link = Link('${thumbs.path}/linked');
      try {
        await Directory('${thumbs.path}/ordinary').create(recursive: true);
        await outside.create();
        final kept = await File(
          '${outside.path}/keep.small.thumb.jpg',
        ).writeAsBytes([8, 9]);
        final local = await File(
          '${thumbs.path}/ordinary/local.small.thumb.jpg',
        ).writeAsBytes([1, 2]);
        await link.create(outside.path);
        final service = ThumbnailCacheService.instance;
        switch (operation) {
          case 'lru':
            final result = await service.evictLRU(
              gallery.path,
              targetFileCount: 0,
              targetSizeMB: 0,
            );
            expect(result.evictedCount, 1);
          case 'before':
            expect(
              await service.clearCacheBefore(
                gallery.path,
                DateTime.now().add(const Duration(days: 1)),
              ),
              1,
            );
          case 'clear':
            expect(await service.clearCache(gallery.path), 1);
          case 'stats':
            final stats = await service.getCacheSize(gallery.path);
            expect(stats['fileCount'], 1);
            expect(stats['totalSize'], 2);
        }
        expect(await kept.readAsBytes(), [8, 9]);
        expect(await local.exists(), operation == 'stats');
      } finally {
        // Remove the link itself before recursive fixture cleanup.
        if (await link.exists()) await link.delete();
        expect(root.absolute.path.contains('thumbnail_links_'), isTrue);
        await root.delete(recursive: true);
      }
    });
  }
}
