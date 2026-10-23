import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/cache/thumbnail_cache_service.dart';
import 'package:nai_launcher/data/models/gallery/local_image_record.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/services/thumbnail_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/gallery/local_image_card.dart';

/// P5 回归：缩略图生成失败时卡片保持轻量占位、不再回退解码数 MB 原图。
///
/// 环境说明：widget 测试里真实 isolate 缩略图生成不推进（先前探针验证），
/// 因此用「缓存层已有失败记录 → 冷却期内直接判失败」这条真实失败路径
/// 驱动卡片，全程不进 isolate。真实 FS 调用需经 `tester.runAsync` 窗口
/// 推进（假异步区里真实 IO 回调不落地）。
void main() {
  final seededPaths = <String>[];

  setUp(() {
    // 假时钟下的重试延迟：由 tester.pump(duration) 精确控制触不发触发
    thumbnailFailureRetryDelayForTesting = const Duration(milliseconds: 500);
    // 冷却拉长：种入的失败记录在测试期内持续有效
    ThumbnailCacheService.instance.setFailureRetryCooldownForTesting(
      const Duration(minutes: 10),
    );
  });

  tearDown(() {
    thumbnailFailureRetryDelayForTesting = const Duration(seconds: 30);
    ThumbnailCacheService.instance.setFailureRetryCooldownForTesting(
      const Duration(seconds: 10),
    );
    for (final path in seededPaths) {
      ThumbnailCacheService.instance.clearFailureRecordForTesting(path);
    }
    seededPaths.clear();
    // 服务层重试定时器不随 widget 卸载，统一清理防挂起
    ThumbnailService.instance.cancelAll();
  });

  /// 交替推进真实事件循环与假异步区，直到 [done] 成立或轮次用尽。
  ///
  /// 卡片的每条 `await` 真实 IO 都需要一轮「真实事件循环 + pump」才能推进，
  /// 链路里这样的等待点有数处，因此按条件轮询而非固定拍数。
  Future<void> settleUntil(
    WidgetTester tester,
    bool Function() done, {
    int maxRounds = 40,
  }) async {
    for (var i = 0; i < maxRounds; i++) {
      if (done()) return;
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 60));
      });
      await tester.pump();
    }
  }

  LocalImageRecord record(String path) => LocalImageRecord(
    path: path,
    size: 42,
    modifiedAt: DateTime(2026, 9, 10),
    metadata: const NaiImageMetadata(width: 1000, height: 1000),
  );

  Widget wrap(LocalImageRecord record) => ProviderScope(
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: LocalImageCard(record: record, width: 180, height: 180),
      ),
    ),
  );

  /// 取出树上所有 Image 实际解码的文件路径。
  ///
  /// `Image.file` 带 cacheWidth/cacheHeight 时内部会包一层 ResizeImage，
  /// 必须解包到 FileImage 才能拿到真实路径（否则断言会假通过）。
  List<String> displayedFilePaths(WidgetTester tester) {
    final result = <String>[];
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      var provider = image.image;
      while (provider is ResizeImage) {
        provider = provider.imageProvider;
      }
      if (provider is FileImage) {
        result.add(provider.file.path);
      }
    }
    return result;
  }

  testWidgets('portrait square card decodes one cover axis from the large tier', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    late File original;
    late Directory temp;
    await tester.runAsync(() async {
      temp = await Directory.systemTemp.createTemp('card-cover-');
      original = File('${temp.path}/portrait.png');
      await original.writeAsString('original is not decoded');
      final thumbs = Directory(
        '${temp.path}/${ThumbnailCacheService.thumbsDirName}',
      );
      await thumbs.create();
      for (final tier in ThumbnailSize.values) {
        await File(
          '${thumbs.path}/${ThumbnailCacheService.buildThumbnailFileNameForTest(original.path, size: tier)}',
        ).writeAsBytes(img.encodeJpg(img.Image(width: 602, height: 880)));
      }
    });
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LocalImageCard(
              record: record(original.path),
              width: 250,
              height: 250,
              imageWidth: 832,
              imageHeight: 1216,
            ),
          ),
        ),
      ),
    );
    await settleUntil(tester, () => find.byType(Image).evaluate().isNotEmpty);
    final image = tester.widget<Image>(find.byType(Image).first);
    final resize = image.image as ResizeImage;
    expect(resize.width, 375);
    expect(resize.height, isNull);
    expect((resize.imageProvider as FileImage).file.path, contains('.large.'));
    await tester.pumpWidget(const SizedBox.shrink());
    ThumbnailService.instance.cancelAll();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await tester.runAsync(() => temp.delete(recursive: true));
  });

  testWidgets('same-path content change replaces the decoded thumbnail', (
    tester,
  ) async {
    late Directory temp;
    late File original;
    Future<void> writeThumbs(img.Color color) async {
      final folder = await Directory(
        '${temp.path}/${ThumbnailCacheService.thumbsDirName}',
      ).create();
      final image = img.Image(width: 300, height: 300);
      img.fill(image, color: color);
      for (final tier in ThumbnailSize.values) {
        await File(
          '${folder.path}/${ThumbnailCacheService.buildThumbnailFileNameForTest(original.path, size: tier)}',
        ).writeAsBytes(img.encodeJpg(image));
      }
    }

    await tester.runAsync(() async {
      temp = await Directory.systemTemp.createTemp('card-file-change-');
      original = await File('${temp.path}/same.png').writeAsString('original');
      await writeThumbs(img.ColorRgb8(255, 0, 0));
    });
    bool decoded() => find
        .byType(RawImage)
        .evaluate()
        .any((element) => (element.widget as RawImage).image != null);
    Future<List<int>> pixel() async {
      final image = tester
          .widgetList<RawImage>(find.byType(RawImage))
          .firstWhere((w) => w.image != null)
          .image!;
      return (await tester.runAsync(
        () => image.toByteData(),
      ))!.buffer.asUint8List().take(3).toList();
    }

    await tester.pumpWidget(wrap(record(original.path)));
    await settleUntil(tester, decoded);
    expect((await pixel()).first, greaterThan(200));
    await tester.runAsync(() => writeThumbs(img.ColorRgb8(0, 0, 255)));
    await tester.pumpWidget(
      wrap(
        record(
          original.path,
        ).copyWith(modifiedAt: DateTime(2026, 9, 11), size: 43),
      ),
    );
    await settleUntil(tester, decoded);
    expect((await pixel()).last, greaterThan(200));
    expect((await pixel()).first, lessThan(20));
    await tester.pumpWidget(const SizedBox.shrink());
    ThumbnailService.instance.cancelAll();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    await tester.runAsync(() => temp.delete(recursive: true));
  });

  testWidgets('缩略图生成失败：显示失败占位，不解码原图', (tester) async {
    late final File original;

    await tester.runAsync(() async {
      final tempDir = await Directory.systemTemp.createTemp('nai_card_fail_');
      addTearDown(() async {
        try {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        } on FileSystemException {
          // 句柄未释放：忽略
        }
      });

      original = File('${tempDir.path}${Platform.pathSeparator}a.png');
      await original.writeAsString('placeholder bytes');
      // 种入失败记录：生成请求在冷却期内立即失败（不进 isolate）
      ThumbnailCacheService.instance.seedFailureRecordForTesting(
        original.path,
        failedAt: DateTime.now(),
      );
      seededPaths.add(original.path);
    });

    await tester.pumpWidget(wrap(record(original.path)));
    await settleUntil(
      tester,
      () =>
          find.byIcon(Icons.image_not_supported_outlined).evaluate().isNotEmpty,
    );

    // 关键断言：失败态下绝不把原图路径交给 Image.file 解码
    expect(
      displayedFilePaths(tester),
      isNot(contains(original.path)),
      reason: '缩略图生成失败不得回退解码原图',
    );
    // 正向断言：确实走到了失败占位态（而非卡在加载中）
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);

    // 卸载卡片并清掉服务层重试定时器（挂载期安排的延迟重试）
    await tester.pumpWidget(const SizedBox.shrink());
    ThumbnailService.instance.cancelAll();
  });

  testWidgets('晚到缩略图落盘后：翻页返回（重新挂载）自动恢复显示', (tester) async {
    late final File original;

    await tester.runAsync(() async {
      final tempDir = await Directory.systemTemp.createTemp('nai_card_retry_');
      addTearDown(() async {
        // Image.file 在 Flutter 图片缓存里仍持有句柄，删不掉时容忍
        // （系统临时目录由 OS 兜底清理）
        try {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        } on FileSystemException {
          // 句柄未释放：忽略
        }
      });

      original = File('${tempDir.path}${Platform.pathSeparator}b.png');
      await original.writeAsString('placeholder bytes');
      ThumbnailCacheService.instance.seedFailureRecordForTesting(
        original.path,
        failedAt: DateTime.now(),
      );
      seededPaths.add(original.path);

      final thumbsDir =
          '${tempDir.path}${Platform.pathSeparator}'
          '${ThumbnailCacheService.thumbsDirName}';
      await Directory(thumbsDir).create(recursive: true);
    });

    // 第一程：失败 → 轻量占位（不回退原图）
    await tester.pumpWidget(wrap(record(original.path)));
    await settleUntil(
      tester,
      () =>
          find.byIcon(Icons.image_not_supported_outlined).evaluate().isNotEmpty,
    );
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    expect(displayedFilePaths(tester), isNot(contains(original.path)));

    // 模拟首次任务超时后底层完成落盘；同时解除冷却（等价于新会话/冷却过期）
    // 注：卡片 initState 首载时 DPR 尚为 1.0（didChangeDependencies 之前），
    // 可能与后续帧档位不同，故各档位一并落盘。
    await tester.runAsync(() async {
      final dir = File(original.path).parent.path;
      final bytes = img.encodeJpg(img.Image(width: 180, height: 220));
      for (final size in ThumbnailSize.values) {
        final target =
            '$dir${Platform.pathSeparator}${ThumbnailCacheService.thumbsDirName}'
            '${Platform.pathSeparator}'
            '${ThumbnailCacheService.buildThumbnailFileNameForTest(original.path, size: size)}';
        await File(target).writeAsBytes(bytes);
      }
      ThumbnailCacheService.instance.clearFailureRecordForTesting(
        original.path,
      );
    });

    // 翻页离开：卸载卡片
    await tester.pumpWidget(const SizedBox.shrink());
    ThumbnailService.instance.cancelAll();
    await tester.pump();

    // 翻回该页：重新挂载 → 走 getThumbnailPath 快速路径吃晚到结果
    await tester.pumpWidget(wrap(record(original.path)));
    await settleUntil(
      tester,
      () => displayedFilePaths(tester).any((p) => p.endsWith('.thumb.jpg')),
    );

    final paths = displayedFilePaths(tester);
    expect(paths, isNotEmpty, reason: '晚到缩略图落盘后翻回该页应恢复显示');
    expect(paths.last, endsWith('.thumb.jpg'));
    expect(paths, isNot(contains(original.path)));
    expect(find.byIcon(Icons.image_not_supported_outlined), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    ThumbnailService.instance.cancelAll();
  });
}
