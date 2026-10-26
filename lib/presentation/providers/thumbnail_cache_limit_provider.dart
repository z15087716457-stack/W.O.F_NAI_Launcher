import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/thumbnail_cache_service.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/storage/local_storage_service.dart';

final thumbnailCacheLimitGbProvider =
    NotifierProvider<ThumbnailCacheLimitGb, int>(ThumbnailCacheLimitGb.new);

int normalizeThumbnailCacheLimitGb(Object? value) =>
    value is num && value.isFinite ? value.round().clamp(1, 50) : 20;

class ThumbnailCacheLimitGb extends Notifier<int> {
  @override
  int build() {
    final value = normalizeThumbnailCacheLimitGb(
      ref
          .read(localStorageServiceProvider)
          .getSetting<Object?>(StorageKeys.thumbnailCacheLimitGb),
    );
    _apply(value);
    return value;
  }

  void _apply(int value) => ThumbnailCacheService.instance.setCacheLimits(
    maxSizeMB: value * 1024,
    maxFiles: value * 25000,
  );

  Future<void> setLimit(num value) async {
    final limit = normalizeThumbnailCacheLimitGb(value);
    await ref
        .read(localStorageServiceProvider)
        .setSetting(StorageKeys.thumbnailCacheLimitGb, limit);
    _apply(limit);
    state = limit;
    // The next startup/manual cleanup uses the new shared limit.
  }
}
