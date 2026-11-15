import 'dart:io';

import '../../providers/gallery_category_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/gallery_cache_manager.dart';
import '../../../core/database/datasources/gallery_data_source.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../core/utils/file_explorer_utils.dart';
import '../../../data/repositories/gallery_folder_repository.dart';
import '../../../data/services/gallery/index.dart';
import '../../../data/services/thumbnail_service.dart';
import '../../providers/local_gallery_provider.dart';
import '../../providers/thumbnail_cache_limit_provider.dart';
import '../../ui/settings/settings_contract.dart';
import '../../utils/gallery_source_add_flow.dart';
import 'settings_dialogs.dart';
import 'settings_inventory.dart';
import 'settings_caches.dart';
import 'settings_storage_snapshot.dart';

final settingsStorageBusyProvider = StateProvider<bool>((ref) => false);
final settingsLastScanProvider = StateProvider<DateTime?>((ref) => null);

class SettingsStorageActions {
  SettingsStorageActions(this.context, this.ref);
  final BuildContext context;
  final WidgetRef ref;

  void refresh() {
    ref.invalidate(settingsFoldersProvider);
    ref.invalidate(settingsGallerySourcesProvider);
    ref.invalidate(settingsStorageLocationsProvider);
    ref.invalidate(settingsStorageDataProvider);
    ref.invalidate(settingsStorageSignatureProvider);
    ref.invalidate(settingsStorageCachedProvider);
    ref.invalidate(settingsCacheStatsProvider);
    ref.invalidate(settingsDictionaryDataProvider);
    ref.invalidate(settingsCacheFootprintProvider);
  }

  Future<void> recount() async {
    final manual = ref.read(settingsStorageManualRefreshProvider.notifier);
    if (manual.state) return;
    manual.state = true;
    try {
      refresh();
      await ref.read(settingsStorageDataProvider.future);
    } finally {
      if (manual.mounted) manual.state = false;
    }
  }

  Future<void> open(String path) => FileExplorerUtils.openDirectory(path);

  Future<void> openFolder(SettingsFolder folder) async {
    final paths = await ref.read(settingsFoldersProvider.future);
    final path = paths[folder];
    if (path == null) return;
    if (const {
      SettingsFolder.images,
      SettingsFolder.vibes,
      SettingsFolder.preciseRefs,
    }.contains(folder)) {
      await Directory(path).create(recursive: true);
    }
    await open(path);
  }

  Future<void> addRoot() async {
    await GallerySourceAddFlow.pickAndAdd(context: context, ref: ref);
    refresh();
  }

  Future<void> removeRoot(String path) async {
    final repository = GalleryFolderRepository.instance;
    final sources = await repository.getSourcePaths();
    if (!sources.contains(path)) throw ArgumentError.value(path);
    await repository.removeSourcePath(path);
    ref.invalidate(galleryCategoryNotifierProvider);
    await ref.read(localGalleryNotifierProvider.notifier).refreshSources();
    refresh();
  }

  Future<void> importTags() async {
    final selected = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jsonl'],
    );
    final path = selected?.files.single.path;
    if (path == null || !context.mounted) return;
    await GallerySourceAddFlow.importTagIndex(
      context: context,
      ref: ref,
      filePath: path,
    );
    refresh();
  }

  Future<void> _exclusive(Future<void> Function() action) async {
    final busy = ref.read(settingsStorageBusyProvider.notifier);
    if (busy.state) throw StateError('Gallery maintenance is busy');
    busy.state = true;
    try {
      await action();
    } finally {
      if (busy.mounted) busy.state = false;
      refresh();
    }
  }

  Future<void> rescan() async {
    final messages = context.l10n;
    if (!await settingsConfirm(
          context,
          context.l10n.galleryCache_rescanTitle,
          context.l10n.galleryCache_rescanContent,
        ) ||
        !context.mounted) {
      return;
    }
    await _exclusive(() async {
      if (ScanStateManager.instance.isScanning) {
        throw StateError(messages.galleryCache_scanAlreadyRunning);
      }
      final roots = await GalleryFolderRepository.instance.getAllRootDirs();
      if (roots.isEmpty) {
        throw StateError(messages.galleryCache_noGalleryFolder);
      }
      final scanner = GalleryStreamScanner(dataSource: GalleryDataSource());
      await scanner.startScanning(
        roots,
        retryMissingMetadata: true,
        retryFailedMetadata: true,
      );
      ref.read(settingsLastScanProvider.notifier).state = DateTime.now();
      await ref.read(localGalleryNotifierProvider.notifier).refreshSources();
    });
  }

  // The view already confirms this operation. Existing bounded LRU eviction
  // deletes only generated .thumbs entries and never touches original images.
  Future<void> cleanThumbnails() => _exclusive(() async {
    final service = ref.read(thumbnailServiceProvider);
    ref.read(thumbnailCacheLimitGbProvider);
    final roots = await GalleryFolderRepository.instance.getAllRootDirs();
    await service.evictThumbnailCaches(roots.map((root) => root.path));
  });

  Future<void> clearCache(SettingsCacheKind kind) async {
    try {
      await ref.read(settingsCachesProvider).clear(kind);
    } finally {
      ref.invalidate(settingsCacheFootprintProvider);
      ref.invalidate(settingsStorageDataProvider);
    }
  }

  void resetStatistics() {
    GalleryCacheManager().resetStatistics();
    refresh();
  }
}
