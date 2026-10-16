import 'dart:io';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/autocomplete/autocomplete_providers.dart';
import '../../../core/cache/gallery_cache_manager.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/hive_storage_helper.dart';
import '../../../data/repositories/gallery_folder_repository.dart';
import '../../providers/image_save_settings_provider.dart';
import '../../providers/nai_agent/nai_agent_workspace_provider.dart';
import '../../providers/rag_provider.dart';
import '../../ui/settings/settings_contract.dart';
import '../../../core/cache/thumbnail_cache_service.dart';

typedef SettingsDirectoryMeasurement = ({int bytes, int thumbs, int images});
Future<SettingsDirectoryMeasurement> _backgroundMeasure(
  String path,
  bool gallery,
) => Isolate.run(() => settingsMeasureDirectory(path, gallery: gallery));

/// Share in-flight reads and bound disk traversal to one background job. Rapid
/// refreshes cannot spawn overlapping recursive walks of the same directories.
class SettingsDirectoryMeasurements {
  final _pending = <(String, bool), Future<SettingsDirectoryMeasurement>>{};
  Future<void> _tail = Future.value();
  Future<SettingsDirectoryMeasurement> measure(
    String path, {
    bool gallery = false,
  }) {
    final key = (p.normalize(p.absolute(path)), gallery);
    return _pending.putIfAbsent(key, () {
      final result = _tail.then((_) => _backgroundMeasure(key.$1, gallery));
      _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
      return result.whenComplete(() => _pending.remove(key));
    });
  }
}

final settingsMeasurementsProvider = Provider(
  (ref) => SettingsDirectoryMeasurements(),
);

final settingsIndexBytesProvider = FutureProvider<int>((ref) async {
  ref.watch(
    ragControllerProvider.select(
      (s) =>
          s.bytes +
          s.sources.values.fold<int>(0, (sum, source) => sum + source.bytes),
    ),
  );
  final path = p.join((await ref.read(ragDirectoryProvider)()).path, 'indices');
  return (await ref.read(settingsMeasurementsProvider).measure(path)).bytes;
});

final settingsFoldersProvider = FutureProvider<Map<SettingsFolder, String>>((
  ref,
) async {
  final docs = await getApplicationDocumentsDirectory();
  final storage = ref.read(localStorageServiceProvider);
  final save = ref.watch(imageSaveSettingsNotifierProvider);
  final images = save.hasCustomPath
      ? save.customPath!
      : p.join(docs.path, 'NAI_Launcher', 'images');
  return {
    SettingsFolder.images: images,
    SettingsFolder.vibes:
        storage.getSetting<String>(StorageKeys.vibeLibrarySavePath) ??
        p.join(docs.path, 'NAI_Launcher', 'vibes'),
    SettingsFolder.thumbnails: p.join(images, '.thumbs'),
    SettingsFolder.appData: await HiveStorageHelper.instance.getPath(),
    SettingsFolder.logs:
        AppLogger.logDirectory ?? p.join(docs.path, 'NAI_Launcher', 'logs'),
    SettingsFolder.agent: ref.read(naiAgentWorkspaceStoreProvider).root.path,
  };
});

/// No image decode, model loading, vector work, symlink traversal or writes.
({int bytes, int thumbs, int images}) settingsMeasureDirectory(
  String path, {
  bool gallery = false,
}) {
  var bytes = 0, thumbs = 0, images = 0;
  final seen = <String>{};
  void visit(Directory directory, bool thumbnail) {
    final canonical = p.normalize(directory.absolute.path).toLowerCase();
    if (!seen.add(canonical)) return;
    try {
      for (final item in directory.listSync(followLinks: false)) {
        if (item is Directory) {
          visit(
            item,
            thumbnail || gallery && p.basename(item.path) == '.thumbs',
          );
        } else if (item is File) {
          try {
            final size = item.lengthSync();
            if (thumbnail) {
              thumbs += size;
            } else if (!gallery ||
                const {
                  '.png',
                  '.jpg',
                  '.jpeg',
                  '.webp',
                  '.bmp',
                  '.gif',
                  '.avif',
                }.contains(p.extension(item.path).toLowerCase())) {
              bytes += size;
              if (gallery) images++;
            }
          } on FileSystemException {
            /* A file may be removed during measurement. */
          }
        }
      }
    } on FileSystemException {
      /* Unavailable directories do not stop other sources. */
    }
  }

  if (Directory(path).existsSync()) visit(Directory(path), false);
  return (bytes: bytes, thumbs: thumbs, images: images);
}

typedef SettingsDiskFree = Future<int?> Function(String path);
final settingsDiskFreeProvider = Provider<SettingsDiskFree>(
  (ref) => (path) async {
    if (!Platform.isWindows) return null;
    try {
      final quoted = path.replaceAll("'", "''");
      final result = await Process.run('powershell.exe', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        "(Get-Item -LiteralPath '$quoted').PSDrive.Free",
      ]).timeout(const Duration(seconds: 5));
      return result.exitCode == 0
          ? int.tryParse('${result.stdout}'.trim())
          : null;
    } catch (_) {
      return null;
    }
  },
);

final settingsStorageDataProvider = FutureProvider<SettingsStorageData>((
  ref,
) async {
  final folders = await ref.watch(settingsFoldersProvider.future);
  final support = await getApplicationSupportDirectory();
  final rag = await ref.read(ragDirectoryProvider)();
  final primary = folders[SettingsFolder.images]!;
  final registered = [
    primary,
    ...await GalleryFolderRepository.instance.getExtraRootPaths(),
  ];
  final roots = <String>[];
  // Nested roots refer to the same bytes and must not inflate totals.
  for (final path in registered) {
    final normalized = p.normalize(p.absolute(path));
    if (roots.any(
      (root) =>
          p.equals(root.toLowerCase(), normalized.toLowerCase()) ||
          p.isWithin(root.toLowerCase(), normalized.toLowerCase()),
    )) {
      continue;
    }
    roots.removeWhere(
      (root) => p.isWithin(normalized.toLowerCase(), root.toLowerCase()),
    );
    roots.add(normalized);
  }
  final worker = ref.read(settingsMeasurementsProvider);
  final measurements = <String, SettingsDirectoryMeasurement>{};
  for (final path in roots) {
    measurements[path] = await worker.measure(path, gallery: true);
  }
  final nested = <String, SettingsDirectoryMeasurement>{};
  for (final path in registered.map((path) => p.normalize(p.absolute(path)))) {
    if (!measurements.containsKey(path)) {
      nested[path] = await worker.measure(path, gallery: true);
    }
  }
  final categories = <SettingsStorageKind, List<String>>{
    SettingsStorageKind.upscaleModels: [p.join(support.path, 'upscale')],
    SettingsStorageKind.vibes: [folders[SettingsFolder.vibes]!],
    SettingsStorageKind.ragIndex: [p.join(rag.path, 'indices')],
    SettingsStorageKind.dictionaries: [
      p.join(support.path, 'databases'),
      p.join(support.path, 'autocomplete'),
    ],
    SettingsStorageKind.agent: [folders[SettingsFolder.agent]!],
  };
  final sizes = <SettingsStorageKind, int>{};
  for (final entry in categories.entries) {
    var total = 0;
    for (final path in entry.value) {
      total += (await worker.measure(path)).bytes;
    }
    sizes[entry.key] = total;
  }
  final rootRows = <SettingsGalleryRoot>[];
  for (final path in registered) {
    final normalized = p.normalize(p.absolute(path));
    final count = (measurements[normalized] ?? nested[normalized])?.images ?? 0;
    rootRows.add(
      SettingsGalleryRoot(
        id: path,
        path: path,
        images: count,
        primary: p.equals(path, primary),
      ),
    );
  }
  return SettingsStorageData(
    slices: [
      SettingsStorageSlice(
        SettingsStorageKind.images,
        measurements.values.fold(0, (sum, value) => sum + value.bytes),
      ),
      SettingsStorageSlice(
        SettingsStorageKind.thumbnails,
        measurements.values.fold(0, (sum, value) => sum + value.thumbs),
      ),
      for (final entry in sizes.entries)
        SettingsStorageSlice(entry.key, entry.value),
    ],
    diskLabel: p.rootPrefix(primary),
    diskFree: await ref.read(settingsDiskFreeProvider)(primary),
    roots: rootRows,
    imageCount: measurements.values.fold(0, (sum, value) => sum + value.images),
    thumbnailBytes: measurements.values.fold(
      0,
      (sum, value) => sum + value.thumbs,
    ),
    thumbnailLimit: ThumbnailCacheService.defaultMaxCacheSizeMB * 1024 * 1024,
    folderNames: {
      for (final entry in folders.entries) entry.key: p.basename(entry.value),
    },
  );
});

final settingsCacheStatsProvider = FutureProvider.autoDispose(
  (ref) => GalleryCacheManager().getStatistics(),
);
final settingsDictionaryDataProvider = FutureProvider<SettingsDictionaryData>((
  ref,
) async {
  final catalog = await ref.read(tagCatalogRepositoryProvider).metadata();
  final cache = await ref.read(autocompleteCacheDatabaseProvider).statistics();
  final bytes = await ref
      .read(autocompleteCacheDatabaseProvider)
      .contentBytes();
  final stats = await ref.watch(settingsCacheStatsProvider.future);
  final database = await ref.read(databaseManagerProvider.future);
  final cooccurrence = await database.cooccurrenceDataSource.getCount();
  return SettingsDictionaryData(
    tagCount: int.tryParse(catalog['tag_count'] ?? '') ?? 0,
    dataVersion: catalog['data_version'] ?? '',
    cooccurrence: cooccurrence,
    caches: {
      SettingsCacheKind.danbooru: (
        cache['danbooruCache'] ?? 0,
        bytes['danbooruCache'] ?? 0,
      ),
      SettingsCacheKind.translation: (
        cache['aiTranslations'] ?? 0,
        bytes['aiTranslations'] ?? 0,
      ),
    },
    l1: SettingsCacheStat(
      hitRate: stats.l1HitRate,
      entries: stats.l1MemorySize,
    ),
    l2: SettingsCacheStat(hitRate: stats.l2HitRate, entries: stats.l2HiveSize),
    // L3 has an indexed-image count but no independent cache-hit telemetry.
    // Null is the contract's honest "—" state, not the L1/L2 weighted rate.
    l3: null,
    statsUpdatedAt: stats.lastUpdated,
  );
});
