import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/cache/gallery_cache_manager.dart';
import '../../../core/database/datasources/gallery_data_source.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/repositories/gallery_folder_repository.dart';
import '../../../data/services/gallery/index.dart';
import '../../../data/services/thumbnail_service.dart';
import '../../providers/local_gallery_provider.dart';
import '../../ui/settings/settings_contract.dart';
import '../../utils/gallery_extra_root_add_flow.dart';
import 'settings_dialogs.dart';
import 'settings_inventory.dart';
import 'settings_caches.dart';

final settingsStorageBusyProvider = StateProvider<bool>((ref) => false);
final settingsLastScanProvider = StateProvider<DateTime?>((ref) => null);

class SettingsStorageActions {
  SettingsStorageActions(this.context, this.ref);
  final BuildContext context;
  final WidgetRef ref;

  void refresh() {
    ref.invalidate(settingsFoldersProvider);
    ref.invalidate(settingsGalleryExtraRootsProvider);
    ref.invalidate(settingsStorageLocationsProvider);
    ref.invalidate(settingsStorageDataProvider);
    ref.invalidate(settingsCacheStatsProvider);
    ref.invalidate(settingsDictionaryDataProvider);
    ref.invalidate(settingsCacheFootprintProvider);
  }

  Future<void> open(String path) async {
    if (!await launchUrl(Uri.directory(path))) {
      throw StateError(
        context.mounted ? context.l10n.common_error : 'Unable to open folder',
      );
    }
  }

  Future<void> openFolder(SettingsFolder folder) async {
    final paths = await ref.read(settingsFoldersProvider.future);
    final path = paths[folder];
    if (path != null) await open(path);
  }

  Future<void> addRoot() async {
    await GalleryExtraRootAddFlow.pickAndAdd(context: context, ref: ref);
    refresh();
  }

  Future<void> removeRoot(String path) async {
    // A forged callback must never remove the primary root.
    final repository = GalleryFolderRepository.instance;
    final extra = await repository.getExtraRootPaths();
    if (!extra.contains(path)) throw ArgumentError.value(path);
    await repository.removeExtraRootPath(path);
    ref.invalidate(localGalleryNotifierProvider);
    refresh();
  }

  Future<void> importTags() async {
    final selected = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jsonl'],
    );
    final path = selected?.files.single.path;
    if (path == null || !context.mounted) return;
    await GalleryExtraRootAddFlow.importTagIndex(
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
      ref.invalidate(localGalleryNotifierProvider);
    });
  }

  // The view already confirms this operation. Existing bounded LRU eviction
  // deletes only generated .thumbs entries and never touches original images.
  Future<void> cleanThumbnails() => _exclusive(() async {
    final service = ref.read(thumbnailServiceProvider);
    for (final root
        in await GalleryFolderRepository.instance.getAllRootDirs()) {
      await service.evictThumbnailCache(root.path);
    }
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
