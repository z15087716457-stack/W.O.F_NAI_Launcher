import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/database/connection_pool_holder.dart';
import 'package:nai_launcher/core/database/datasources/gallery_data_source.dart';
import 'package:nai_launcher/core/utils/app_logger.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/services/gallery_statistics_repository.dart';
import 'package:nai_launcher/data/services/statistics_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDirectory;
  late GalleryDataSource dataSource;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await AppLogger.initialize(isTestEnvironment: true);
  });

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'gallery_dashboard_statistics_',
    );
    await ConnectionPoolHolder.initialize(
      dbPath: '${tempDirectory.path}/gallery.db',
      maxConnections: 2,
    );
    dataSource = GalleryDataSource();
    await dataSource.initialize();
  });

  tearDown(() async {
    await dataSource.dispose();
    await ConnectionPoolHolder.dispose();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test(
    'aggregates active images without materializing large metadata',
    () async {
      final monday = DateTime(2026, 7, 27, 10, 15);
      final tuesday = DateTime(2026, 7, 28, 15, 30);
      final wednesday = DateTime(2026, 7, 29, 20, 45);
      final largeMetadata = List.filled(512 * 1024, 'x').join();

      final firstId = await dataSource.upsertImage(
        filePath: '/test/first.png',
        fileName: 'first.png',
        fileSize: 512 * 1024,
        width: 512,
        height: 768,
        createdAt: monday,
        modifiedAt: monday,
      );
      await dataSource.upsertMetadata(
        firstId,
        NaiImageMetadata(
          prompt: 'first',
          negativePrompt: '',
          sampler: 'k_euler',
          width: 512,
          height: 768,
          model: 'model-a',
          rawJson: largeMetadata,
        ),
      );
      await dataSource.toggleFavorite(firstId);
      await dataSource.setImageTags(firstId, const ['landscape']);

      final secondId = await dataSource.upsertImage(
        filePath: '/test/second.png',
        fileName: 'second.png',
        fileSize: 1536 * 1024,
        width: 1024,
        height: 1024,
        createdAt: tuesday,
        modifiedAt: tuesday,
      );
      await dataSource.upsertMetadata(
        secondId,
        const NaiImageMetadata(
          prompt: 'second',
          negativePrompt: '',
          sampler: 'k_euler_ancestral',
          width: 1024,
          height: 1024,
          model: 'model-a',
        ),
      );

      await dataSource.upsertImage(
        filePath: '/test/third.png',
        fileName: 'third.png',
        fileSize: 12 * 1024 * 1024,
        createdAt: wednesday,
        modifiedAt: wednesday,
      );

      final deletedId = await dataSource.upsertImage(
        filePath: '/test/deleted.png',
        fileName: 'deleted.png',
        fileSize: 64 * 1024 * 1024,
        width: 2048,
        height: 2048,
        createdAt: monday,
        modifiedAt: monday,
      );
      await dataSource.upsertMetadata(
        deletedId,
        const NaiImageMetadata(
          prompt: 'deleted',
          negativePrompt: '',
          sampler: 'ddim',
          width: 2048,
          height: 2048,
          model: 'deleted-model',
        ),
      );
      await dataSource.markAsDeleted('/test/deleted.png');

      final snapshot = await dataSource.getDashboardStatistics();

      expect(snapshot.totalImages, 3);
      expect(snapshot.totalSizeBytes, 14 * 1024 * 1024);
      expect(snapshot.favoriteCount, 1);
      expect(snapshot.taggedImageCount, 1);
      expect(snapshot.imagesWithMetadata, 2);
      expect(snapshot.resolutionCounts, {'512x768': 1, '1024x1024': 1});
      expect(snapshot.modelCounts, {'model-a': 2});
      expect(snapshot.samplerCounts, {'k_euler': 1, 'k_euler_ancestral': 1});
      expect(snapshot.sizeCounts, {'< 1 MB': 1, '1-2 MB': 1, '> 10 MB': 1});
      expect(snapshot.tagCounts, {'landscape': 1});
      expect(snapshot.dailyCounts, {20260727: 1, 20260728: 1, 20260729: 1});
      expect(snapshot.hourlyCounts, {10: 1, 15: 1, 20: 1});
      expect(snapshot.weekdayCounts, {
        DateTime.monday: 1,
        DateTime.tuesday: 1,
        DateTime.wednesday: 1,
      });
    },
  );

  test('scopes totals but keeps calendar history and library total', () async {
    Future<int> add(String name, DateTime day, {String? model}) async {
      final id = await dataSource.upsertImage(
        filePath: '/test/$name.png',
        fileName: '$name.png',
        fileSize: 1048576,
        width: 832,
        height: 1216,
        createdAt: day,
        modifiedAt: day,
      );
      if (model != null) {
        await dataSource.upsertMetadata(
          id,
          NaiImageMetadata(
            prompt: 'artist:Example_Name',
            negativePrompt: '',
            model: model,
            sampler: 'k_euler',
            steps: 28,
            scale: 5.5,
            noiseSchedule: 'karras',
          ),
        );
      }
      return id;
    }

    await add('old', DateTime(2026, 9, 1), model: 'nai-diffusion-5-full');
    final active = await add(
      'active',
      DateTime(2026, 10, 5, 23),
      model: 'nai-diffusion-5-full',
    );
    await dataSource.toggleFavorite(active);
    await add('other', DateTime(2026, 10, 5), model: 'stable-diffusion');
    await add('plain', DateTime(2026, 10, 5));
    await add('end', DateTime(2026, 10, 6), model: 'nai-diffusion-5-full');
    final deleted = await add(
      'deleted',
      DateTime(2026, 10, 5),
      model: 'nai-diffusion-5-full',
    );
    await dataSource.toggleFavorite(deleted);
    await dataSource.markAsDeleted('/test/deleted.png');

    final result = await dataSource.getDashboardStatistics(
      dateStart: DateTime(2026, 10, 5),
      dateEnd: DateTime(2026, 10, 6),
      naiOnly: true,
    );
    expect(result.libraryTotal, 5);
    expect(result.totalImages, 1);
    expect(result.favoriteCount, 1);
    expect(result.totalSizeBytes, 1048576);
    expect(result.imagesWithMetadata, 1);
    expect(result.stepCounts, {28: 1});
    expect(result.cfgCounts, {5.5: 1});
    expect(result.noiseScheduleCounts, {'karras': 1});
    expect(result.weekHourCounts, {23: 1});
    expect(result.sizeBytesCounts, {'1-2 MB': 1048576});
    expect(result.dailyCounts, {20260901: 1, 20261005: 1, 20261006: 1});
    expect(result.dailyModelCounts[20261005], {'nai-diffusion-5-full': 1});
    expect(result.monthlyBytes, {20260901: 1048576, 20261001: 2097152});
  });

  test(
    'statistics and gallery use indexed local dates and exclusive end',
    () async {
      final id = await dataSource.upsertImage(
        filePath: '/test/indexed.png',
        fileName: 'indexed.png',
        fileSize: 10,
        createdAt: DateTime(2026, 10, 8),
        modifiedAt: DateTime(2026, 10, 8),
      );
      await dataSource.execute(
        'test indexed date',
        (db) => db.update(
          'gallery_images',
          {'date_ymd': 20261005},
          where: 'id = ?',
          whereArgs: [id],
        ),
      );
      await dataSource.upsertImage(
        filePath: '/test/end.png',
        fileName: 'end.png',
        fileSize: 20,
        createdAt: DateTime(2026, 10, 6),
        modifiedAt: DateTime(2026, 10, 6),
      );
      final result = await dataSource.getDashboardStatistics(
        dateStart: DateTime(2026, 10, 5),
        dateEnd: DateTime(2026, 10, 6),
      );
      expect(result.totalImages, 1);
      final gallery = await dataSource.advancedSearchResult(
        dateStart: DateTime(2026, 10, 5),
        dateEnd: DateTime(2026, 10, 6),
        indexedDate: true,
        dateEndExclusive: true,
      );
      expect(gallery.ids, [id]);
    },
  );

  test(
    'size boundaries, Sunday hours, metadata presence and artists stay consistent',
    () async {
      final sizes = [1048575, 1048576, 2097152, 5242880, 10485760];
      final ids = <int>[];
      for (var index = 0; index < sizes.length; index++) {
        final id = await dataSource.upsertImage(
          filePath: '/test/bucket$index.png',
          fileName: 'bucket$index.png',
          fileSize: sizes[index],
          width: index == 1 || index == 3 ? 0 : null,
          height: index == 1 || index == 3 ? 0 : null,
          createdAt: DateTime(2026, 10, 11, 23),
          modifiedAt: DateTime(2026, 10, 11, 23),
        );
        ids.add(id);
        if (index < 4) {
          await dataSource.upsertMetadata(
            id,
            NaiImageMetadata(
              prompt: switch (index) {
                0 => 'artist:Example_Name, artist:example name',
                2 => '1.5::artist:SECOND::',
                _ => 'landscape',
              },
              negativePrompt: 'artist:negative_only',
              model: index == 1 ? 'nai-diffusion-5-full' : null,
              software: index == 0 ? 'NovelAI' : null,
              rawJson: index == 2 ? '{"noise_schedule":"karras"}' : null,
              width: index == 0
                  ? 832
                  : index == 2
                  ? 1024
                  : 0,
              height: index == 0
                  ? 1216
                  : index == 2
                  ? 1024
                  : 0,
              sampler: index == 3 ? 'invalid' : 'k_euler',
              steps: 28,
              scale: 5.5,
            ),
          );
        }
      }
      await dataSource.execute(
        'test metadata presence',
        (db) => db.update(
          'gallery_metadata',
          {'has_metadata': 0},
          where: 'image_id = ?',
          whereArgs: [ids[3]],
        ),
      );
      await dataSource.execute(
        'test date fallback',
        (db) => db.update(
          'gallery_images',
          {'date_ymd': 0},
          where: 'id = ?',
          whereArgs: [ids[4]],
        ),
      );
      final all = await dataSource.getDashboardStatistics();
      expect(all.sizeCounts.values.toList(), [1, 1, 1, 1, 1]);
      expect(all.sizeBytesCounts.values.toList(), sizes);
      expect(all.weekHourCounts, {167: 5});
      expect(all.dailyCounts, {20261011: 5});
      expect(all.imagesWithMetadata, 3);
      expect(all.samplerCounts, {'k_euler': 3});
      expect(all.resolutionCounts, {'832x1216': 1, '1024x1024': 1});
      expect(
        (await dataSource.getDashboardStatistics(naiOnly: true)).totalImages,
        3,
      );
      final resolution = await dataSource.advancedSearchResult(
        indexedDate: true,
        resolutions: ['832x1216'],
      );
      expect(resolution.ids, [ids.first]);
      expect(
        (await dataSource.advancedSearchResult(
          indexedDate: true,
          orientation: 'portrait',
        )).ids,
        [ids.first],
      );
      expect(
        (await dataSource.advancedSearchResult(
          indexedDate: true,
          metadataStatuses: ['none'],
          hasMetadata: false,
        )).ids.toSet(),
        {ids[3], ids[4]},
      );
      expect(
        (await dataSource.advancedSearchResult(
          indexedDate: true,
          samplers: ['invalid'],
        )).ids,
        isEmpty,
      );
      final firstPage = await dataSource.getStatisticsArtistPrompts(limit: 1);
      expect(firstPage.single.keys.toSet(), {'id', 'prompt'});
      expect(firstPage.single['id'], ids[0]);
      final secondPage = await dataSource.getStatisticsArtistPrompts(
        limit: 1,
        afterId: ids[0],
      );
      expect(secondPage.single['id'], ids[2]);
      SharedPreferences.setMockInitialValues({});
      final repository = GalleryStatisticsRepository(
        readDataSource: () async => dataSource,
        cache: StatisticsCacheService(),
        preferences: await SharedPreferences.getInstance(),
        readAnlas: () async => [],
      );
      final artists = await repository.loadArtists(
        naiOnly: false,
        isCancelled: () => false,
      );
      expect(artists.counts, {'example name': 1, 'second': 1});
      expect(artists.imagesWithArtist, 2);
    },
  );

  test(
    'persistent revision survives reconnects and tracks count-preserving changes',
    () async {
      final empty = await dataSource.getStatisticsSignature();
      final id = await dataSource.upsertImage(
        filePath: '/test/revision.png',
        fileName: 'revision.png',
        fileSize: 100,
        createdAt: DateTime(2026, 10, 11),
        modifiedAt: DateTime(2026, 10, 11),
      );
      final inserted = await dataSource.getStatisticsSignature();
      expect(inserted, isNot(empty));
      await dataSource.getDashboardStatistics();
      expect(await dataSource.getStatisticsSignature(), inserted);
      await dataSource.toggleFavorite(id);
      final favorite = await dataSource.getStatisticsSignature();
      expect(favorite, isNot(inserted));
      await dataSource.execute(
        'test external size update',
        (db) => db.update(
          'gallery_images',
          {'file_size': 200},
          where: 'id = ?',
          whereArgs: [id],
        ),
      );
      final changed = await dataSource.getStatisticsSignature();
      expect(changed, isNot(favorite));
      await dataSource.dispose();
      await ConnectionPoolHolder.dispose();
      await ConnectionPoolHolder.initialize(
        dbPath: '${tempDirectory.path}/gallery.db',
        maxConnections: 2,
      );
      await dataSource.initialize();
      expect(await dataSource.getStatisticsSignature(), changed);
      expect((await dataSource.getDashboardStatistics()).totalSizeBytes, 200);
    },
  );
}
