import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/cache/thumbnail_cache_service.dart';
import 'package:nai_launcher/data/services/thumbnail_service.dart';

void main() {
  test('同一路径不同尺寸通过服务独立生成', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'nai_launcher_thumbnail_service_sizes_',
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

    final service = ThumbnailService.instance;
    await service.initialize();
    final paths = await Future.wait([
      service.getThumbnail(imageFile.path, size: ThumbnailSize.small),
      service.getThumbnail(imageFile.path, size: ThumbnailSize.medium),
    ]);

    expect(paths[0], endsWith('.small.thumb.jpg'));
    expect(paths[1], endsWith('.medium.thumb.jpg'));
  });

  test('同一路径同尺寸通过服务复用活跃任务', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'nai_launcher_thumbnail_service_dedup_',
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

    final service = ThumbnailService.instance;
    await service.initialize();
    final paths = await Future.wait([
      service.getThumbnail(imageFile.path, size: ThumbnailSize.large),
      service.getThumbnail(imageFile.path, size: ThumbnailSize.large),
    ]);

    expect(paths[0], isNotNull);
    expect(paths[0], paths[1]);
    expect(service.queueLength, 0);
  });
}
