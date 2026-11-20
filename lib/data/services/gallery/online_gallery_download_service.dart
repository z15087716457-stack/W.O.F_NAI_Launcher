import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../../core/cache/danbooru_image_cache_manager.dart';
import '../../models/online_gallery/gallery_item.dart';
import '../../models/online_gallery/gallery_source.dart';

class OnlineGalleryDownloadService {
  const OnlineGalleryDownloadService();

  Future<(int success, int failed)> download({
    required List<GalleryItem> items,
    required String directory,
    required Future<GalleryDetail> Function(GalleryItem) resolve,
    bool all = false,
    int mediaIndex = 0,
    void Function(int completed, int total)? progress,
  }) async {
    final jobs = <(GalleryItem, GalleryMedia, int)>[];
    var failed = 0;
    for (var start = 0; start < items.length; start += 3) {
      await Future.wait(
        items.sublist(start, min(start + 3, items.length)).map((item) async {
          try {
            final detail = item.sourceId == GallerySourceId.aiTag
                ? await resolve(item)
                : GalleryDetail(item: item, media: [item.cover]);
            if (detail.media.isEmpty ||
                (!all &&
                    (mediaIndex < 0 || mediaIndex >= detail.media.length))) {
              failed++;
              return;
            }
            for (var index = 0; index < detail.media.length; index++) {
              if (all || index == mediaIndex) {
                jobs.add((detail.item, detail.media[index], index));
              }
            }
          } catch (_) {
            failed++;
          }
        }),
      );
    }
    var success = 0;
    var completed = 0;
    progress?.call(0, jobs.length);
    for (var start = 0; start < jobs.length; start += 3) {
      await Future.wait(
        jobs.sublist(start, min(start + 3, jobs.length)).map((job) async {
          final (item, media, index) = job;
          try {
            if (media.downloadUrl.isEmpty) {
              throw StateError('Media URL is empty');
            }
            await saveMedia(media, directory, fileName(item, media, index));
            success++;
          } catch (_) {
            failed++;
          }
          completed++;
          progress?.call(completed, jobs.length);
        }),
      );
    }
    return (success, failed);
  }

  static String fileName(GalleryItem item, GalleryMedia media, int index) {
    final extension =
        media.extension ??
        p.extension(Uri.parse(media.downloadUrl).path).replaceFirst('.', '');
    final safeExtension = RegExp(r'^[a-zA-Z0-9]{1,8}$').hasMatch(extension)
        ? extension
        : 'webp';
    return '${item.sourceId.key}_${item.id}_p${(index + 1).toString().padLeft(2, '0')}.$safeExtension';
  }

  Future<void> saveMedia(
    GalleryMedia media,
    String directory,
    String name,
  ) async {
    final bytes = await mediaBytes(media);
    await saveBytes(bytes, directory, name);
  }

  Future<String> saveBytes(
    List<int> bytes,
    String directory,
    String name,
  ) async {
    for (var suffix = 0; ; suffix++) {
      final candidate = p.join(
        directory,
        suffix == 0
            ? name
            : '${p.basenameWithoutExtension(name)}_$suffix${p.extension(name)}',
      );
      final file = File(candidate);
      try {
        await file.create(exclusive: true);
      } on FileSystemException {
        if (!await file.exists()) rethrow;
        continue;
      }
      try {
        await file.writeAsBytes(bytes, flush: true);
      } catch (_) {
        await file.delete();
        rethrow;
      }
      return file.path;
    }
  }

  Future<List<int>> mediaBytes(GalleryMedia media) =>
      bytesForUrl(media.downloadUrl);

  Future<Uint8List> bytesForUrl(String url) async {
    final source = await DanbooruImageCacheManager.instance.getSingleFile(
      url,
      key: onlineGalleryImageCacheKeyForUrl(url),
      headers: onlineGalleryImageHeadersForUrl(url),
    );
    return source.readAsBytes();
  }
}
