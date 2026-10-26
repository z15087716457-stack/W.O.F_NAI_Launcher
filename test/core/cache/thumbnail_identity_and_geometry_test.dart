import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/cache/thumbnail_cache_service.dart';
import 'package:path/path.dart' as p;

import '../../helpers/app_logger_test_isolation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late Directory directory;
  final service = ThumbnailCacheService.instance;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('thumbnail_identity_');
    await service.init();
    service.setRootPaths([directory.path]);
    service.resetStats();
  });
  tearDown(() async {
    expect(service.getStats()['activeGenerations'], 0);
    service.setRootPaths([]);
    await directory.delete(recursive: true);
  });

  Future<File> source(
    String name, {
    int red = 255,
    int blue = 0,
    int width = 32,
    int height = 32,
  }) async {
    final image = img.Image(width: width, height: height)
      ..clear(img.ColorRgb8(red, 0, blue));
    final bytes = name.toLowerCase().endsWith('.png')
        ? img.encodePng(image)
        : img.encodeJpg(image);
    return File(p.join(directory.path, name)).writeAsBytes(bytes);
  }

  test(
    'F20 same stem with different extensions keeps every source and size',
    () async {
      final red = await source('same.png');
      final blue = await source('same.jpg', red: 0, blue: 255);
      final another = await source('same.JPEG', red: 128, blue: 128);
      final requests = [
        for (final file in [red, blue, another])
          for (final size in ThumbnailSize.values) (file, size),
      ];
      final paths = await Future.wait([
        for (final (file, size) in requests)
          service.getOrGenerateThumbnail(file.path, size: size),
      ]);
      expect(paths.whereType<String>().toSet(), hasLength(requests.length));
      for (var i = 0; i < requests.length; i++) {
        final pixel = img
            .decodeJpg(await File(paths[i]!).readAsBytes())!
            .getPixel(0, 0);
        final original = requests[i].$1;
        if (original == red) expect(pixel.r, greaterThan(220));
        if (original == blue) expect(pixel.b, greaterThan(220));
      }
      expect(service.getStats()['generatedCount'], requests.length);
    },
  );

  test('F20 ambiguous legacy cache is ignored without changing it', () async {
    final blue = await source('same.jpg', red: 0, blue: 255);
    final old = File(p.join(directory.path, '.thumbs', 'same.small.thumb.jpg'));
    await old.parent.create();
    final legacyBytes = img.encodeJpg(
      img.Image(width: 32, height: 32)..clear(img.ColorRgb8(255, 0, 0)),
    );
    await old.writeAsBytes(legacyBytes);
    expect(service.getThumbnailPathSync(blue.path), isNull);
    final current = await service.getOrGenerateThumbnail(blue.path);
    expect(current, isNot(old.path));
    expect(
      img.decodeJpg(await File(current!).readAsBytes())!.getPixel(0, 0).b,
      greaterThan(220),
    );
    expect(await old.readAsBytes(), legacyBytes);
  });

  test(
    'F20 a source change invalidates asynchronous and synchronous cache hits',
    () async {
      final original = await source('changed.png');
      final cached = (await service.getOrGenerateThumbnail(original.path))!;
      await File(cached).setLastModified(DateTime(2000));
      await source('changed.png', red: 0, blue: 255);
      expect(await service.getThumbnailPath(original.path), isNull);
      expect(service.getThumbnailPathSync(original.path), isNull);
      expect(service.thumbnailExists(original.path), isFalse);
      expect(await service.thumbnailExistsAsync(original.path), isFalse);
      final regenerated = await service.getOrGenerateThumbnail(original.path);
      expect(
        img.decodeJpg(await File(regenerated!).readAsBytes())!.getPixel(0, 0).b,
        greaterThan(220),
      );
    },
  );

  test(
    'F20 same-key requests after the file check share one generation',
    () async {
      final original = await source('parallel.png');
      final paths = await Future.wait(
        List.generate(6, (_) => service.generateThumbnail(original.path)),
      );
      expect(paths.toSet(), hasLength(1));
      expect(service.getStats()['generatedCount'], 1);
    },
  );

  for (final size in ThumbnailSize.values) {
    test(
      'F21 visible $size survives before a newer hidden thumbnail',
      () async {
        final visible = await source('visible.png');
        final hidden = await source('hidden.png');
        final visiblePath = (await service.getOrGenerateThumbnail(
          visible.path,
          size: size,
        ))!;
        final hiddenPath = (await service.getOrGenerateThumbnail(
          hidden.path,
          size: size,
        ))!;
        await File(visiblePath).setLastModified(DateTime(2000));
        await File(hiddenPath).setLastModified(DateTime(2026));
        service.updateThumbnailVisibility(
          visible.path.replaceAll(r'\', '/'),
          isVisible: true,
          priority: 1,
        );
        service.updateThumbnailVisibility(hidden.path, isVisible: false);
        await service.evictLRU(
          directory.path,
          targetFileCount: 1,
          targetSizeMB: 1,
        );
        expect(await File(visiblePath).exists(), isTrue);
        expect(await File(hiddenPath).exists(), isFalse);
      },
    );
  }

  test('F21 lower numeric visibility priority is retained first', () async {
    final important = await source('important.small.png');
    final ordinary = await source('ordinary.png');
    final importantPath = (await service.getOrGenerateThumbnail(
      important.path,
      size: ThumbnailSize.medium,
    ))!;
    final ordinaryPath = (await service.getOrGenerateThumbnail(
      ordinary.path,
      size: ThumbnailSize.medium,
    ))!;
    service.updateThumbnailVisibility(
      important.path,
      isVisible: true,
      priority: 1,
    );
    service.updateThumbnailVisibility(
      ordinary.path,
      isVisible: true,
      priority: 3,
    );
    await service.evictLRU(directory.path, targetFileCount: 1, targetSizeMB: 1);
    expect(await File(importantPath).exists(), isTrue);
    expect(await File(ordinaryPath).exists(), isFalse);
  });

  test('F21 visible identity covers all sizes', () async {
    final a = await source('a.png');
    final b = await source('b.png');
    final paths = [
      for (final file in [a, b])
        for (final size in [ThumbnailSize.small, ThumbnailSize.large])
          (await service.getOrGenerateThumbnail(file.path, size: size))!,
    ];
    for (final path in paths.take(2)) {
      await File(path).setLastModified(DateTime(2000));
    }
    service.updateThumbnailVisibility(a.path, isVisible: true);
    await service.evictLRU(directory.path, targetFileCount: 2, targetSizeMB: 1);
    for (var i = 0; i < paths.length; i++) {
      expect(await File(paths[i]).exists(), i < 2);
    }
  });

  test(
    'F21 equal-priority LRU recognizes access through mixed path separators',
    () async {
      final a = await source('accessed.png');
      final b = await source('untouched.png');
      final aPath = (await service.getOrGenerateThumbnail(a.path))!;
      final bPath = (await service.getOrGenerateThumbnail(b.path))!;
      await a.setLastModified(DateTime(1999));
      await b.setLastModified(DateTime(1999));
      await File(aPath).setLastModified(DateTime(2000));
      await File(bPath).setLastModified(DateTime(2001));
      final alias = a.path.replaceAll(r'\', '/');
      expect(service.getThumbnailPathSync(alias), isNotNull);
      await service.evictLRU(
        directory.path,
        targetFileCount: 1,
        targetSizeMB: 1,
      );
      expect(await File(aPath).exists(), isTrue);
      expect(await File(bPath).exists(), isFalse);
    },
  );

  for (final (width, height) in [(2000, 1), (1, 2000), (1, 1)]) {
    for (final size in ThumbnailSize.values) {
      test(
        'F23 $width x $height produces a decodable $size thumbnail',
        () async {
          final original = await source(
            'extreme.png',
            width: width,
            height: height,
          );
          final path = await service.getOrGenerateThumbnail(
            original.path,
            size: size,
          );
          final bytes = await File(path!).readAsBytes();
          final image = img.decodeJpg(bytes)!;
          expect(image.width, inInclusiveRange(1, size.width));
          expect(image.height, inInclusiveRange(1, size.height));
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          expect(frame.image.width, image.width);
          expect(frame.image.height, image.height);
          frame.image.dispose();
          codec.dispose();
        },
      );
    }
  }
}
