import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../../core/utils/localization_extension.dart';
import '../../data/repositories/gallery_folder_repository.dart';
import '../../data/services/gallery/gallery_extra_root_validator.dart';
import '../../data/services/gallery/scan_state_manager.dart';
import '../../data/services/gallery/tag_index_import_service.dart';
import '../providers/gallery_category_provider.dart';
import '../providers/local_gallery_provider.dart';
import '../providers/tag_index_import_provider.dart';
import '../widgets/common/app_toast.dart';

/// Shared folder-picker and registration flow for Settings and Local Gallery.
class GalleryExtraRootAddFlow {
  GalleryExtraRootAddFlow._();

  static bool _isAdding = false;

  /// Returns the registered path, including when a subsequent scan fails.
  static Future<String?> pickAndAdd({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    if (_isAdding) return null;
    _isAdding = true;

    final l10n = context.l10n;
    try {
      final selected = await FilePicker.platform.getDirectoryPath(
        dialogTitle: l10n.settings_extraRootsAddTitle,
      );
      if (selected == null || !context.mounted) return null;

      // Let the Windows common dialog fully unwind before a scan or Hive work.
      // Without the frame and delay, comdlg32 can re-enter the message loop.
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 150));
      if (!context.mounted) return null;

      final repository = GalleryFolderRepository.instance;
      final error = await validateGalleryExtraRoot(
        selectedPath: selected,
        mainRoot: await repository.getRootPath(),
        existingRoots: await repository.getExtraRootPaths(),
      );
      if (!context.mounted) return null;
      if (error != null) {
        switch (error) {
          case GalleryExtraRootValidationError.notFound:
            AppToast.error(context, l10n.settings_extraRootsNotFound);
          case GalleryExtraRootValidationError.sameAsMain:
            AppToast.warning(context, l10n.settings_extraRootsSameAsMain);
          case GalleryExtraRootValidationError.duplicate:
            AppToast.warning(context, l10n.settings_extraRootsDuplicate);
          case GalleryExtraRootValidationError.nested:
            AppToast.warning(context, l10n.settings_extraRootsNested);
        }
        return null;
      }

      final added = await repository.addExtraRootPath(selected);
      if (!context.mounted) return added ? selected : null;
      if (!added) {
        AppToast.warning(context, l10n.settings_extraRootsDuplicate);
        return null;
      }

      // A running startup scan does not include a root registered after it
      // started. Wait for it before importing an index or requesting the new
      // scan; both operations are otherwise silently rejected by the scanner.
      if (ScanStateManager.instance.isScanning) {
        AppToast.info(context, l10n.settings_extraRootsWaitingScan);
        while (ScanStateManager.instance.isScanning && context.mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
        if (!context.mounted) return selected;
        await Future.delayed(const Duration(milliseconds: 50));
      }

      try {
        final indexFile = await findTagIndexFileForRoot(selected);
        if (indexFile != null && context.mounted) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              icon: const Icon(Icons.upload_file_outlined),
              title: Text(l10n.settings_extraRootsIndexImportTitle),
              content: Text(
                l10n.settings_extraRootsIndexImportContent(selected),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.common_cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(l10n.settings_extraRootsIndexImportConfirm),
                ),
              ],
            ),
          );
          if (confirmed == true && context.mounted) {
            await importTagIndex(
              context: context,
              ref: ref,
              filePath: indexFile.path,
            );
          }
        }
      } catch (e) {
        // The source is registered even if its optional index is unreadable.
        AppLogger.e('检查额外图库源标签索引失败', e);
      }

      if (!context.mounted) return selected;
      try {
        await ref.read(localGalleryNotifierProvider.notifier).refresh();
        if (!context.mounted) return selected;
        // Settings does not normally watch this auto-dispose provider. Keep
        // it alive while the category sync runs, including large folders.
        final categorySubscription = ref.listenManual(
          galleryCategoryNotifierProvider,
          (_, _) {},
        );
        try {
          await ref
              .read(galleryCategoryNotifierProvider.notifier)
              .syncWithFileSystem();
          if (!context.mounted) return selected;

          final galleryError = ref.read(localGalleryNotifierProvider).error;
          final categoryError = ref.read(galleryCategoryNotifierProvider).error;
          if (galleryError != null || categoryError != null) {
            AppToast.warning(context, l10n.settings_extraRootsScanFailed);
          } else {
            AppToast.success(context, l10n.settings_extraRootsAdded);
          }
        } finally {
          categorySubscription.close();
        }
      } catch (e) {
        AppLogger.e('扫描新图库源失败', e);
        if (context.mounted) {
          AppToast.warning(context, l10n.settings_extraRootsScanFailed);
        }
      }
      return selected;
    } catch (e) {
      AppLogger.e('添加额外图库源失败', e);
      if (context.mounted) {
        AppToast.error(context, '${l10n.settings_selectFolderFailed}: $e');
      }
      return null;
    } finally {
      _isAdding = false;
    }
  }

  /// Also used by Settings' explicit JSONL import button.
  static Future<void> importTagIndex({
    required BuildContext context,
    required WidgetRef ref,
    required String filePath,
  }) async {
    if (!context.mounted) return;
    final l10n = context.l10n;
    final notifier = ref.read(tagIndexImportProvider.notifier);
    final result = await notifier.startImport(filePath);
    if (!context.mounted) return;

    if (result != null) {
      final message = l10n.settings_importTagIndexDone(
        result.imported,
        result.updated,
        result.skipped,
        result.errors,
      );
      if (result.hasErrors) {
        AppToast.warning(context, message);
      } else {
        AppToast.success(context, message);
      }
    } else if (!notifier.isImporting) {
      final state = ref.read(tagIndexImportProvider);
      final message = state.blockedByScan
          ? l10n.settings_importTagIndexBlockedByScan
          : state.error ?? l10n.settings_importTagIndexFailed;
      AppToast.error(context, message);
    }
  }
}
