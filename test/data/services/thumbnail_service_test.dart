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

  test('失败立即返回 null，后台重试延迟到冷却截止后并能成功', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'nai_launcher_thumbnail_service_retry_',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final imageFile = File('${tempDir.path}${Platform.pathSeparator}a.png');
    // 先写入损坏内容制造首次生成失败
    await imageFile.writeAsString('not an image');

    final cache = ThumbnailCacheService.instance;
    cache.setFailureRetryCooldownForTesting(const Duration(milliseconds: 300));
    addTearDown(
      () =>
          cache.setFailureRetryCooldownForTesting(const Duration(seconds: 10)),
    );

    final service = ThumbnailService.instance;
    await service.initialize();

    final completedTasks = <ThumbnailTask>[];
    final sub = service.taskStream.listen((task) {
      if (task.originalPath == imageFile.path &&
          task.state == ThumbnailTaskState.completed) {
        completedTasks.add(task);
      }
    });
    addTearDown(sub.cancel);

    // 首回合失败立即返回 null（不等待 3 次重试烧完）
    final first = await service.getThumbnail(
      imageFile.path,
      size: ThumbnailSize.small,
    );
    expect(first, isNull);

    // 修复文件，等后台重试窗口（冷却 300ms + 余量）跑完
    await imageFile.writeAsBytes(
      img.encodePng(img.Image(width: 900, height: 600)),
    );
    final generatedBefore = cache.getStats()['generatedCount'] as int;
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    // 重试真正执行并成功：缓存统计增长且任务以 completed 收尾
    expect(cache.getStats()['generatedCount'], greaterThan(generatedBefore));
    expect(completedTasks, isNotEmpty);
    expect(completedTasks.last.retryCount, lessThanOrEqualTo(3));
  });

  test('重试在冷却期内不被弹回：修复后重试一次即成功', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'nai_launcher_thumbnail_service_retry_once_',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final imageFile = File('${tempDir.path}${Platform.pathSeparator}b.png');
    await imageFile.writeAsString('broken');

    final cache = ThumbnailCacheService.instance;
    cache.setFailureRetryCooldownForTesting(const Duration(milliseconds: 200));
    addTearDown(
      () =>
          cache.setFailureRetryCooldownForTesting(const Duration(seconds: 10)),
    );

    final service = ThumbnailService.instance;
    await service.initialize();

    await service.getThumbnail(imageFile.path, size: ThumbnailSize.medium);
    await imageFile.writeAsBytes(
      img.encodePng(img.Image(width: 640, height: 480)),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    // 后台重试真正执行并落盘（旧实现里重试会在冷却期内被弹回、次数烧完，
    // 这里会是 null）
    final landed = await cache.getThumbnailPath(
      imageFile.path,
      size: ThumbnailSize.medium,
    );
    expect(landed, isNotNull);
    expect(landed, endsWith('.medium.thumb.jpg'));
  });
}
