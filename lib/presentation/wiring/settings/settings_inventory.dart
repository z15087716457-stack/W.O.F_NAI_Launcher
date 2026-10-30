import 'dart:io';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:nai_launcher/core/utils/app_support_directory.dart';

import '../../../core/autocomplete/autocomplete_providers.dart';
import '../../../core/cache/gallery_cache_manager.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/database/asset_database_manager.dart';
import '../../../core/database/dictionary_data_store.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/hive_storage_helper.dart';
import '../../../data/repositories/gallery_folder_repository.dart';
import '../../providers/image_save_settings_provider.dart';
import '../../providers/nai_agent/nai_agent_workspace_provider.dart';
import '../../providers/rag_provider.dart';
import '../../ui/settings/settings_contract.dart';
import '../../providers/thumbnail_cache_limit_provider.dart';
import 'settings_storage_measurement.dart';
import 'settings_storage_snapshot.dart';

final settingsStorageSignatureProvider = FutureProvider<String>((ref) async {
  final folders = await ref.watch(settingsFoldersProvider.future);
  final roots = await ref.watch(settingsGalleryExtraRootsProvider.future);
  final support = await getApplicationSupportDirectory();
  final rag = await ref.read(ragDirectoryProvider)();
  return [
    for (final folder in SettingsFolder.values) folders[folder] ?? '',
    ...roots,
    support.path,
    rag.path,
  ].map(_physicalPath).join('|');
});

final settingsStorageCachedProvider = FutureProvider<SettingsStorageData?>((
  ref,
) async {
  final signature = await ref.watch(settingsStorageSignatureProvider.future);
  return ref.read(settingsStorageSnapshotStoreProvider).read(signature);
});

class SettingsMeasuredFile {
  const SettingsMeasuredFile(
    this.path,
    this.bytes, {
    this.image = false,
    this.thumbnail = false,
  });
  final String path;
  final int bytes;
  final bool image;
  final bool thumbnail;
}

class SettingsDirectoryMeasurement {
  const SettingsDirectoryMeasurement({
    this.bytes = 0,
    this.thumbs = 0,
    this.images = 0,
    this.other = 0,
    this.incomplete = false,
    this.files = const {},
    this.rootPath,
  });
  final int bytes, thumbs, images, other;
  final bool incomplete;
  final String? rootPath;

  /// Canonical physical paths allow cross-category and configured-alias dedup.
  final Map<String, SettingsMeasuredFile> files;
}

String _physicalPath(String path) {
  final normalized = p.normalize(p.absolute(path));
  return Platform.isWindows ? normalized.toLowerCase() : normalized;
}

typedef SettingsDirectoryMeasure =
    Future<SettingsDirectoryMeasurement> Function(String path, bool gallery);
Future<SettingsDirectoryMeasurement> _backgroundMeasure(
  String path,
  bool gallery,
) => Isolate.run(() => settingsMeasureDirectory(path, gallery: gallery));

/// Share in-flight reads and bound disk traversal to one background job. Rapid
/// refreshes cannot spawn overlapping recursive walks of the same directories.
class SettingsDirectoryMeasurements {
  SettingsDirectoryMeasurements({SettingsDirectoryMeasure? measure})
    : _measure = measure ?? _backgroundMeasure;

  final SettingsDirectoryMeasure _measure;
  final _pending = <(String, bool), Future<SettingsDirectoryMeasurement>>{};
  Future<void> _tail = Future.value();
  Future<SettingsDirectoryMeasurement> measure(
    String path, {
    bool gallery = false,
  }) {
    final key = (p.normalize(p.absolute(path)), gallery);
    return _pending.putIfAbsent(key, () {
      final result = _tail.then((_) => _measure(key.$1, gallery));
      _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
      return result.whenComplete(() {
        _pending.remove(key);
      });
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
  final vibePath = storage.getSetting<String>(StorageKeys.vibeLibrarySavePath);
  return {
    SettingsFolder.images: images,
    SettingsFolder.vibes: vibePath == null || vibePath.trim().isEmpty
        ? p.join(docs.path, 'NAI_Launcher', 'vibes')
        : vibePath,
    SettingsFolder.thumbnails: p.join(images, '.thumbs'),
    SettingsFolder.appData: await HiveStorageHelper.instance.getPath(),
    SettingsFolder.logs:
        AppLogger.logDirectory ?? p.join(docs.path, 'NAI_Launcher', 'logs'),
    SettingsFolder.agent: ref.read(naiAgentWorkspaceStoreProvider).root.path,
  };
});

/// No image decode, model loading, vector work, symlink traversal or writes.
SettingsDirectoryMeasurement settingsMeasureDirectory(
  String path, {
  bool gallery = false,
}) {
  var bytes = 0, thumbs = 0, images = 0, other = 0;
  var incomplete = false;
  final seen = <String>{};
  final files = <String, SettingsMeasuredFile>{};
  String? rootPath;
  void visit(Directory directory, bool thumbnail) {
    try {
      final canonical = _physicalPath(directory.resolveSymbolicLinksSync());
      rootPath ??= canonical;
      if (!seen.add(canonical)) {
        return;
      }
      for (final item in directory.listSync(followLinks: false)) {
        if (item is Directory) {
          visit(
            item,
            thumbnail || gallery && p.basename(item.path) == '.thumbs',
          );
        } else if (item is File) {
          try {
            final canonical = _physicalPath(item.resolveSymbolicLinksSync());
            if (files.containsKey(canonical)) continue;
            final size = item.lengthSync();
            final image =
                gallery &&
                !thumbnail &&
                const {
                  '.png',
                  '.jpg',
                  '.jpeg',
                  '.webp',
                  '.bmp',
                  '.gif',
                  '.avif',
                }.contains(p.extension(item.path).toLowerCase());
            files[canonical] = SettingsMeasuredFile(
              canonical,
              size,
              image: image,
              thumbnail: thumbnail,
            );
            if (thumbnail) {
              thumbs += size;
            } else if (!gallery || image) {
              bytes += size;
              if (image) images++;
            } else {
              other += size;
            }
          } on FileSystemException {
            incomplete = true;
          }
        }
      }
    } on FileSystemException {
      incomplete = true;
    }
  }

  // Nonexistent directories are not silently reported as successfully empty.
  visit(Directory(path), false);
  return SettingsDirectoryMeasurement(
    bytes: bytes,
    thumbs: thumbs,
    images: images,
    other: other,
    incomplete: incomplete,
    files: files,
    rootPath: rootPath,
  );
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

final settingsGalleryExtraRootsProvider = FutureProvider<List<String>>(
  (ref) => GalleryFolderRepository.instance.getExtraRootPaths(),
);

/// Configuration is cheap and remains available while directory walks run.
final settingsStorageLocationsProvider = FutureProvider<SettingsStorageData>((
  ref,
) async {
  final folders = await ref.watch(settingsFoldersProvider.future);
  final extraRoots = await ref.watch(settingsGalleryExtraRootsProvider.future);
  final primary = folders[SettingsFolder.images]!;
  return SettingsStorageData(
    diskLabel: p.rootPrefix(primary),
    roots: [
      for (final path in [primary, ...extraRoots])
        SettingsGalleryRoot(
          id: path,
          path: path,
          images: 0,
          primary: p.equals(path, primary),
        ),
    ],
    thumbnailLimit:
        ref.watch(thumbnailCacheLimitGbProvider) * 1024 * 1024 * 1024,
    folderNames: {
      for (final entry in folders.entries) entry.key: p.basename(entry.value),
    },
  );
});

final settingsStorageDataProvider = FutureProvider<SettingsStorageData>((
  ref,
) async {
  final locations = await ref.watch(settingsStorageLocationsProvider.future);
  final signature = await ref.watch(settingsStorageSignatureProvider.future);
  final folders = await ref.watch(settingsFoldersProvider.future);
  final support = await getApplicationSupportDirectory();
  final rag = await ref.read(ragDirectoryProvider)();
  final primary = folders[SettingsFolder.images]!;
  final registered = locations.roots.map((root) => root.path).toList();
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
  final categoryMeasurements =
      <SettingsStorageKind, Map<String, SettingsDirectoryMeasurement>>{};
  for (final entry in categories.entries) {
    categoryMeasurements[entry.key] = {
      for (final path in entry.value) path: await worker.measure(path),
    };
  }
  final slices = settingsClassifyStorage(
    galleries: measurements,
    categories: categoryMeasurements,
  );
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
  final measured = SettingsStorageData(
    configurationKey: signature,
    slices: slices,
    incomplete: slices.any((s) => s.incomplete),
    diskLabel: p.rootPrefix(primary),
    diskFree: await ref.read(settingsDiskFreeProvider)(primary),
    roots: rootRows,
    imageCount: {
      for (final measurement in measurements.values)
        for (final file in measurement.files.entries)
          if (file.value.image) file.key,
    }.length,
    thumbnailBytes: slices
        .firstWhere((s) => s.kind == SettingsStorageKind.thumbnails)
        .bytes,
    thumbnailCount: {
      for (final measurement in measurements.values)
        for (final file in measurement.files.entries)
          if (file.value.thumbnail) file.key,
    }.length,
    measuredAt: DateTime.now(),
    thumbnailLimit: locations.thumbnailLimit,
    folderNames: locations.folderNames,
  );
  if (!measured.incomplete) {
    await ref
        .read(settingsStorageSnapshotStoreProvider)
        .save(signature, measured)
        .catchError((Object error) {
          AppLogger.w('Storage snapshot save failed: $error', 'Settings');
        });
    ref.invalidate(settingsStorageCachedProvider);
  }
  return measured;
});

final settingsGalleryCacheManagerProvider = Provider(
  (ref) => GalleryCacheManager(),
);

final settingsCacheStatsProvider = FutureProvider.autoDispose((ref) {
  final manager = ref.read(settingsGalleryCacheManagerProvider);
  void invalidate() => ref.invalidateSelf();
  manager.registerOnStatisticsInvalidated(invalidate);
  ref.onDispose(() => manager.unregisterOnStatisticsInvalidated(invalidate));
  return manager.getStatistics(refresh: true);
});
final settingsDictionaryDataProvider = FutureProvider<SettingsDictionaryData>((
  ref,
) async {
  final catalog = await ref.read(tagCatalogRepositoryProvider).metadata();
  final database = await ref.read(databaseManagerProvider.future);
  final cooccurrence = await database.cooccurrenceDataSource.getCount();
  final wikiPath = await AssetDatabaseManager.instance.ensureTagWikiDb();
  final wikiCount = await validateDictionaryInBackground(
    wikiPath,
    DictionaryKind.wiki,
  );
  return SettingsDictionaryData(
    tagCount: int.tryParse(catalog['tag_count'] ?? '') ?? 0,
    dataVersion: catalog['data_version'] ?? '',
    wikiCount: wikiCount,
    cooccurrence: cooccurrence,
  );
});
