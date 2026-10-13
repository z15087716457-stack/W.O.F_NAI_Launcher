import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/online_gallery/gallery_item.dart';
import 'package:nai_launcher/data/models/online_gallery/gallery_source.dart';
import 'package:nai_launcher/data/repositories/online_favorites_repository.dart';
import 'package:nai_launcher/data/services/gallery/online_gallery_download_service.dart';
import 'package:nai_launcher/presentation/providers/online_favorites_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('current-image download does not download other media', () async {
    final service = _Downloads();
    final result = await service.download(
      items: const [_item],
      directory: 'unused',
      resolve: (_) async => _detail,
      mediaIndex: 1,
    );
    expect(result, (1, 0));
    expect(service.saved.single, ('p1', 'ai_tag_1_p02.png'));
  });

  test(
    'all-media download is limited to three concurrent saves and reports progress',
    () async {
      final service = _Downloads();
      final progress = <(int, int)>[];
      final result = await service.download(
        items: const [_item],
        directory: 'unused',
        resolve: (_) async => GalleryDetail(
          item: _item,
          media: [
            for (var i = 0; i < 8; i++)
              GalleryMedia(
                id: 'p$i',
                downloadUrl: 'https://example.test/$i.png',
              ),
          ],
        ),
        all: true,
        progress: (done, total) => progress.add((done, total)),
      );
      expect(result, (8, 0));
      expect(service.maximum, 3);
      expect(progress.first, (0, 8));
      expect(progress.last, (8, 8));
    },
  );

  test(
    'detail failures and unavailable images are counted rather than reported as success',
    () async {
      final service = _Downloads();
      final result = await service.download(
        items: const [
          _item,
          GalleryItem(id: 2, sourceId: GallerySourceId.aiTag),
        ],
        directory: 'unused',
        resolve: (item) async {
          if (item.id == 2) throw StateError('unavailable');
          return const GalleryDetail(
            item: _item,
            media: [GalleryMedia(id: 'empty')],
          );
        },
        all: true,
      );
      expect(result, (0, 2));
    },
  );

  test(
    'out-of-range media selection never silently downloads a different image',
    () async {
      final service = _Downloads();
      final result = await service.download(
        items: const [_item],
        directory: 'unused',
        resolve: (_) async => _detail,
        mediaIndex: 9,
      );
      expect(result, (0, 1));
      expect(service.saved, isEmpty);
    },
  );

  test(
    'downloads preserve existing files using exclusive collision-safe names',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'online_download_test_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final original = File('${directory.path}/ai_tag_1_p01.png');
      await original.writeAsBytes([9, 9]);
      final service = _Bytes();
      await service.saveMedia(
        _detail.media.first,
        directory.path,
        'ai_tag_1_p01.png',
      );
      expect(await original.readAsBytes(), [9, 9]);
      expect(await File('${directory.path}/ai_tag_1_p01_1.png').readAsBytes(), [
        1,
        2,
        3,
      ]);
    },
  );

  test(
    'favorites refresh publishes entries and collection counts after toggling and moving',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'online_fav_provider_test_',
      );
      final repository = OnlineFavoritesRepository.forTesting(
        '${directory.path}/favorites.db',
      );
      final notifier = _Favorites(repository);
      addTearDown(() async {
        notifier.dispose();
        await repository.close();
        await directory.delete(recursive: true);
      });
      await notifier.bindSource(GallerySourceId.aiTag);
      await notifier.toggleFavorite(_item);
      expect(notifier.value.entries.single.item.stableKey, _item.stableKey);
      final collection = await notifier.createCollection('set');
      await notifier.moveToCollection(_item.id, collection);
      expect(notifier.value.collections.single.itemCount, 1);
      expect(notifier.value.entries.single.collectionId, collection);
      await notifier.deleteCollection(collection);
      expect(notifier.value.entries.single.collectionId, isNull);
      await notifier.toggleFavorite(_item);
      expect(notifier.value.entries, isEmpty);
      expect(notifier.value.favoritedWorkIds, isEmpty);
    },
  );
}

const _item = GalleryItem(
  id: 1,
  sourceId: GallerySourceId.aiTag,
  title: 'work',
  uploaderId: 8,
  author: 'artist',
);
const _detail = GalleryDetail(
  item: _item,
  media: [
    GalleryMedia(id: 'p0', downloadUrl: 'https://example.test/0.png'),
    GalleryMedia(id: 'p1', downloadUrl: 'https://example.test/1.png'),
  ],
);

class _Favorites extends OnlineFavoritesNotifier {
  _Favorites(super.repository);
  OnlineFavoritesState get value => state;
}

class _Downloads extends OnlineGalleryDownloadService {
  final saved = <(String, String)>[];
  int active = 0;
  int maximum = 0;
  @override
  Future<void> saveMedia(
    GalleryMedia media,
    String directory,
    String name,
  ) async {
    active++;
    if (active > maximum) maximum = active;
    await Future<void>.delayed(Duration.zero);
    saved.add((media.id, name));
    active--;
  }
}

class _Bytes extends OnlineGalleryDownloadService {
  @override
  Future<List<int>> mediaBytes(GalleryMedia media) async => [1, 2, 3];
}
