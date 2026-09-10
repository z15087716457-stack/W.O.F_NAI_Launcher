import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/cache/thumbnail_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('thumbnail_lru_test_');
    ThumbnailCacheService.instance.resetStats();
  });

  tearDown(() async {
    ThumbnailCacheService.instance
      ..setCacheLimits(
        maxSizeMB: ThumbnailCacheService.defaultMaxCacheSizeMB,
        maxFiles: ThumbnailCacheService.defaultMaxFileCount,
      )
      ..resetStats();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  String fullPath(String relative) =>
      '${tempDir.path}${Platform.pathSeparator}$relative';

  Future<File> createThumbFile(
    String relative, {
    required DateTime modified,
    int byteLength = 1024,
  }) async {
    final file = File(fullPath(relative));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(Uint8List(byteLength));
    await file.setLastModified(modified);
    return file;
  }

  group('evictLRU 淘汰规则', () {
    test('超过文件数上限时按 mtime 从最旧开始淘汰', () async {
      final base = DateTime(2026, 1, 1);
      final files = <File>[];
      for (var i = 0; i < 4; i++) {
        files.add(
          await createThumbFile(
            '.thumbs/${String.fromCharCode(97 + i)}.small.thumb.jpg',
            modified: base.add(Duration(days: i)),
          ),
        );
      }

      final result = await ThumbnailCacheService.instance.evictLRU(
        tempDir.path,
        targetSizeMB: 1024,
        targetFileCount: 2,
      );

      expect(result.evictedCount, 2);
      expect(result.evictedBytes, 2048);
      expect(await files[0].exists(), isFalse);
      expect(await files[1].exists(), isFalse);
      expect(await files[2].exists(), isTrue);
      expect(await files[3].exists(), isTrue);
    });

    test('未超限时不删除任何文件', () async {
      final a = await createThumbFile(
        '.thumbs/a.small.thumb.jpg',
        modified: DateTime(2026, 1, 1),
      );
      final b = await createThumbFile(
        '.thumbs/b.small.thumb.jpg',
        modified: DateTime(2026, 1, 2),
      );

      final result = await ThumbnailCacheService.instance.evictLRU(
        tempDir.path,
        targetSizeMB: 1024,
        targetFileCount: 10,
      );

      expect(result.evictedCount, 0);
      expect(result.evictedBytes, 0);
      expect(await a.exists(), isTrue);
      expect(await b.exists(), isTrue);
    });

    test('只删 .thumbs 内的缩略图，原图与目录外文件不受影响', () async {
      final original = File(fullPath('original.png'));
      await original.writeAsBytes(Uint8List(1024));
      final outside = File(fullPath('outside.small.thumb.jpg'));
      await outside.writeAsBytes(Uint8List(1024));

      final insideA = await createThumbFile(
        '.thumbs/a.small.thumb.jpg',
        modified: DateTime(2026, 1, 1),
      );
      final insideB = await createThumbFile(
        'sub/.thumbs/b.small.thumb.jpg',
        modified: DateTime(2026, 1, 2),
      );

      final result = await ThumbnailCacheService.instance.evictLRU(
        tempDir.path,
        targetSizeMB: 1024,
        targetFileCount: 0,
      );

      expect(result.evictedCount, 2);
      expect(await insideA.exists(), isFalse);
      expect(await insideB.exists(), isFalse);
      expect(await original.exists(), isTrue);
      expect(await outside.exists(), isTrue);
    });

    test('按字节上限淘汰，不会因逐文件 MB 截断而多删', () async {
      final base = DateTime(2026, 1, 1);
      const chunk = 300 * 1024;
      final files = <File>[];
      for (var i = 0; i < 5; i++) {
        files.add(
          await createThumbFile(
            '.thumbs/${String.fromCharCode(97 + i)}.medium.thumb.jpg',
            modified: base.add(Duration(days: i)),
            byteLength: chunk,
          ),
        );
      }

      final result = await ThumbnailCacheService.instance.evictLRU(
        tempDir.path,
        targetSizeMB: 1,
        targetFileCount: 100,
      );

      expect(result.evictedCount, 2);
      expect(result.evictedBytes, 2 * chunk);
      expect(await files[0].exists(), isFalse);
      expect(await files[1].exists(), isFalse);
      expect(await files[2].exists(), isTrue);
      expect(await files[3].exists(), isTrue);
      expect(await files[4].exists(), isTrue);
    });

    test('setCacheLimits 设置的上限参与淘汰（80% 目标）', () async {
      final service = ThumbnailCacheService.instance;
      final base = DateTime(2026, 1, 1);
      final files = <File>[];
      for (var i = 0; i < 4; i++) {
        files.add(
          await createThumbFile(
            '.thumbs/${String.fromCharCode(97 + i)}.small.thumb.jpg',
            modified: base.add(Duration(days: i)),
          ),
        );
      }

      service.setCacheLimits(maxFiles: 2);
      final result = await service.evictLRU(tempDir.path, targetSizeMB: 1024);

      expect(result.evictedCount, 3);
      expect(await files[0].exists(), isFalse);
      expect(await files[1].exists(), isFalse);
      expect(await files[2].exists(), isFalse);
      expect(await files[3].exists(), isTrue);
    });

    test('图库源目录不存在时安全返回空结果', () async {
      final result = await ThumbnailCacheService.instance.evictLRU(
        '${tempDir.path}${Platform.pathSeparator}missing',
        targetSizeMB: 1,
        targetFileCount: 0,
      );

      expect(result.evictedCount, 0);
      expect(result.evictedBytes, 0);
    });
  });

  group('isDeletableThumbnailFile 目录名 + 扩展名双重校验', () {
    test('允许 .thumbs 目录内的 .thumb.jpg', () {
      expect(
        ThumbnailCacheService.isDeletableThumbnailFile(
          r'C:\gallery\pic\.thumbs\a.small.thumb.jpg',
        ),
        isTrue,
      );
      expect(
        ThumbnailCacheService.isDeletableThumbnailFile(
          'C:/gallery/pic/.thumbs/a.large.thumb.jpg',
        ),
        isTrue,
      );
    });

    test('拒绝目录外的 .thumb.jpg 与 .thumbs 内的其它扩展名', () {
      expect(
        ThumbnailCacheService.isDeletableThumbnailFile(
          r'C:\gallery\a.small.thumb.jpg',
        ),
        isFalse,
      );
      expect(
        ThumbnailCacheService.isDeletableThumbnailFile(
          r'C:\gallery\.thumbs\a.png',
        ),
        isFalse,
      );
      expect(
        ThumbnailCacheService.isDeletableThumbnailFile(
          r'C:\gallery\.thumbs\a.jpg',
        ),
        isFalse,
      );
      expect(
        ThumbnailCacheService.isDeletableThumbnailFile('a.small.thumb.jpg'),
        isFalse,
      );
    });
  });
}
