import '../widgets/settings_tile.dart';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/hive_storage_helper.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../core/utils/vibe_library_path_helper.dart';
import '../../../../data/repositories/gallery_folder_repository.dart';
import '../../../providers/image_save_settings_provider.dart';
import '../../../providers/tag_index_import_provider.dart';
import '../../../utils/gallery_extra_root_add_flow.dart';
import '../../../widgets/common/app_toast.dart';
import '../widgets/cache_statistics_tile.dart';
import '../widgets/data_source_cache_settings.dart';
import '../widgets/gallery_cache_actions.dart';
import '../widgets/gallery_thumbnail_quality_settings_tile.dart';
import '../widgets/settings_card.dart';

/// 存储设置板块
class StorageSettingsSection extends ConsumerStatefulWidget {
  const StorageSettingsSection({super.key});

  @override
  ConsumerState<StorageSettingsSection> createState() =>
      _StorageSettingsSectionState();
}

class _StorageSettingsSectionState
    extends ConsumerState<StorageSettingsSection> {
  Future<void> _selectSaveDirectory(BuildContext context) async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: context.l10n.settings_selectFolder,
      );

      if (result != null && context.mounted) {
        await ref
            .read(imageSaveSettingsNotifierProvider.notifier)
            .setCustomPath(result);

        if (context.mounted) {
          AppToast.success(context, context.l10n.settings_pathSaved);
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, context.l10n.image_saveFailed(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final saveSettings = ref.watch(imageSaveSettingsNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          child: Column(
            children: [
              // 图片保存路径设置
              SettingsTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(context.l10n.settings_imageSavePath),
                subtitle: Text(
                  saveSettings.getDisplayPath(
                    context.l10n.settings_defaultImagesPath,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.folder_open, size: 20),
                      tooltip: context.l10n.settings_openFolder,
                      onPressed: () async {
                        final openFolderFailed =
                            context.l10n.settings_openFolderFailed;
                        try {
                          String path;
                          if (saveSettings.hasCustomPath) {
                            path = saveSettings.customPath!;
                          } else {
                            final docDir =
                                await getApplicationDocumentsDirectory();
                            path =
                                '${docDir.path}${Platform.pathSeparator}NAI_Launcher${Platform.pathSeparator}images';
                          }
                          await launchUrl(
                            Uri.directory(path),
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (e) {
                          AppLogger.e(openFolderFailed, e);
                        }
                      },
                    ),
                    if (saveSettings.hasCustomPath)
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        tooltip: context.l10n.common_reset,
                        onPressed: () async {
                          await ref
                              .read(imageSaveSettingsNotifierProvider.notifier)
                              .resetToDefault();
                          if (context.mounted) {
                            AppToast.success(
                              context,
                              context.l10n.settings_pathReset,
                            );
                          }
                        },
                      ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => _selectSaveDirectory(context),
              ),
              // 自动保存开关
              SettingsSwitchTile(
                secondary: const Icon(Icons.save_outlined),
                title: Text(context.l10n.settings_autoSave),
                subtitle: Text(context.l10n.settings_autoSaveSubtitle),
                value: saveSettings.autoSave,
                onChanged: (value) async {
                  await ref
                      .read(imageSaveSettingsNotifierProvider.notifier)
                      .setAutoSave(value);
                },
              ),
              const Divider(height: 24),
              // Vibe库保存路径设置
              const VibeLibraryPathTile(),
              // Hive 数据存储路径设置
              const HiveStoragePathTile(),
              const Divider(height: 32),
              // 缓存统计
              const CacheStatisticsTile(),
              const Divider(height: 32),
              const GalleryThumbnailQualitySettingsTile(),
              const Divider(height: 32),
              // 画廊缓存操作（清除缓存 + 重建索引）
              const GalleryCacheActions(),
            ],
          ),
        ),
        const DataSourceCacheSettings(cacheOnly: true),
        // 图库源管理（主源 + 额外图库源）
        const GalleryExtraRootsCard(),
      ],
    );
  }
}

/// 图库源管理
///
/// 额外图库源：任意文件夹加入画廊，可浏览可搜索，不参与自动保存。
/// 图片级移动/复制仍遵循画廊现有的保护与确认流程。
class GalleryExtraRootsCard extends ConsumerStatefulWidget {
  const GalleryExtraRootsCard({super.key});

  @override
  ConsumerState<GalleryExtraRootsCard> createState() =>
      _GalleryExtraRootsCardState();
}

class _GalleryExtraRootsCardState extends ConsumerState<GalleryExtraRootsCard> {
  List<String> _extraRoots = const [];

  @override
  void initState() {
    super.initState();
    _loadExtraRoots();
  }

  Future<void> _loadExtraRoots() async {
    final roots = await GalleryFolderRepository.instance.getExtraRootPaths();
    if (!mounted) return;
    setState(() => _extraRoots = roots);
  }

  Future<void> _addExtraRoot() async {
    final added = await GalleryExtraRootAddFlow.pickAndAdd(
      context: context,
      ref: ref,
    );
    if (added != null && mounted) await _loadExtraRoots();
  }

  /// 选择 JSONL 标签索引文件并导入
  Future<void> _importTagIndex() async {
    final l10n = context.l10n;
    try {
      final picked = await FilePicker.platform.pickFiles(
        dialogTitle: l10n.settings_importTagIndexPickTitle,
        type: FileType.custom,
        allowedExtensions: ['jsonl'],
      );
      if (picked == null || picked.files.isEmpty || !mounted) return;

      // 【闪退加固】对话框返回后让出一帧再继续（与加源流程一致）
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;

      final filePath = picked.files.single.path;
      if (filePath == null || filePath.isEmpty) return;

      await _runImport(filePath);
    } catch (e) {
      AppLogger.e('选择标签索引文件失败', e);
      if (mounted) {
        AppToast.error(
          context,
          '${l10n.settings_selectFolderFailed}: ${e.toString()}',
        );
      }
    }
  }

  /// 执行导入，完成后 toast 报告计数
  Future<void> _runImport(String filePath) async {
    await GalleryExtraRootAddFlow.importTagIndex(
      context: context,
      ref: ref,
      filePath: filePath,
    );
  }

  Future<void> _removeExtraRoot(String path) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.folder_off_outlined, color: Colors.orange),
        title: Text(context.l10n.settings_extraRootsRemoveConfirmTitle),
        content: Text(
          context.l10n.settings_extraRootsRemoveConfirmContent(path),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.common_confirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final removed = await GalleryFolderRepository.instance.removeExtraRootPath(
      path,
    );
    if (removed) {
      await _loadExtraRoots();
      if (mounted) {
        AppToast.success(context, context.l10n.settings_extraRootsRemoved);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final importState = ref.watch(tagIndexImportProvider);

    return SettingsCard(
      title: context.l10n.settings_extraRootsTitle,
      icon: Icons.library_books_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              context.l10n.settings_extraRootsHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          if (_extraRoots.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                context.l10n.settings_extraRootsEmpty,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            )
          else
            ..._extraRoots.map(
              (path) => SettingsTile(
                dense: true,
                leading: const Icon(Icons.folder_outlined, size: 20),
                title: Text(
                  path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: context.l10n.settings_extraRootsRemove,
                  onPressed: () => _removeExtraRoot(path),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
            child: OutlinedButton.icon(
              onPressed: _addExtraRoot,
              icon: const Icon(Icons.create_new_folder_outlined, size: 18),
              label: Text(context.l10n.settings_extraRootsAdd),
            ),
          ),
          const Divider(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: importState.isImporting ? null : _importTagIndex,
                  icon: const Icon(Icons.upload_file_outlined, size: 18),
                  label: Text(context.l10n.settings_importTagIndex),
                ),
                if (importState.isImporting) ...[
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: importState.totalLines > 0
                        ? importState.progress
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.settings_importTagIndexProgress(
                      importState.processedLines,
                      importState.totalLines,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vibe库保存路径设置项
class VibeLibraryPathTile extends StatefulWidget {
  const VibeLibraryPathTile({super.key});

  @override
  State<VibeLibraryPathTile> createState() => _VibeLibraryPathTileState();
}

class _VibeLibraryPathTileState extends State<VibeLibraryPathTile> {
  final _pathHelper = VibeLibraryPathHelper.instance;

  Future<void> _selectVibeLibraryDirectory(BuildContext context) async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: context.l10n.settings_selectVibeLibraryFolder,
      );

      if (result != null && context.mounted) {
        await _pathHelper.setPath(result);
        await _pathHelper.ensurePathExists(result);
        setState(() {});

        if (context.mounted) {
          AppToast.success(context, context.l10n.settings_vibePathSaved);
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(
          context,
          '${context.l10n.settings_selectFolderFailed}: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _resetToDefault(BuildContext context) async {
    await _pathHelper.resetToDefault();
    setState(() {});

    if (context.mounted) {
      AppToast.success(context, context.l10n.settings_pathReset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customPath = _pathHelper.getCustomPath();
    final hasCustomPath = _pathHelper.hasCustomPath;

    return SettingsTile(
      leading: const Icon(StudioIcons.vibeLibrary),
      title: Text(context.l10n.settings_vibeLibraryPath),
      subtitle: FutureBuilder<String>(
        future: _pathHelper.getPath(),
        builder: (context, snapshot) {
          final displayPath = hasCustomPath
              ? (customPath ?? '')
              : (snapshot.data != null
                    ? context.l10n.settings_defaultVibePath(snapshot.data!)
                    : context.l10n.settings_defaultVibePath(
                        'Documents/NAI_Launcher/vibes/',
                      ));
          return Text(
            displayPath,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.folder_open, size: 20),
            tooltip: context.l10n.settings_openFolder,
            onPressed: () async {
              final openFolderFailed = context.l10n.settings_openFolderFailed;
              try {
                final path = await _pathHelper.getPath();
                await launchUrl(
                  Uri.directory(path),
                  mode: LaunchMode.externalApplication,
                );
              } catch (e) {
                AppLogger.e(openFolderFailed, e);
              }
            },
          ),
          if (hasCustomPath)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: context.l10n.common_reset,
              onPressed: () => _resetToDefault(context),
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => _selectVibeLibraryDirectory(context),
    );
  }
}

/// Hive 数据存储路径设置 Tile
class HiveStoragePathTile extends StatefulWidget {
  const HiveStoragePathTile({super.key});

  @override
  State<HiveStoragePathTile> createState() => _HiveStoragePathTileState();
}

class _HiveStoragePathTileState extends State<HiveStoragePathTile> {
  final _hiveHelper = HiveStorageHelper.instance;

  Future<void> _selectHiveStorageDirectory(BuildContext context) async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: context.l10n.settings_selectHiveFolder,
      );

      if (result != null && context.mounted) {
        // 显示警告：更改存储路径需要重启应用
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            title: Text(context.l10n.settings_restartRequiredTitle),
            content: Text(context.l10n.settings_changePathConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(context.l10n.common_cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(context.l10n.common_confirm),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await _hiveHelper.setCustomPath(result);
          setState(() {});

          if (context.mounted) {
            AppToast.success(context, context.l10n.settings_hivePathSaved);
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(
          context,
          '${context.l10n.settings_selectFolderFailed}: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _resetToDefault(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
        title: Text(context.l10n.settings_restartRequiredTitle),
        content: Text(context.l10n.settings_resetPathConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.common_confirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _hiveHelper.resetToDefault();
      setState(() {});

      if (context.mounted) {
        AppToast.success(
          context,
          context.l10n.settings_pathSavedRestartRequired,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCustomPath = _hiveHelper.hasCustomPath;

    return SettingsTile(
      leading: const Icon(Icons.storage_outlined),
      title: Text(context.l10n.settings_hiveStoragePath),
      subtitle: Text(
        hasCustomPath
            ? (_hiveHelper.getCustomPath() ?? '')
            : context.l10n.settings_defaultHivePath,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.folder_open, size: 20),
            tooltip: context.l10n.settings_openFolder,
            onPressed: () async {
              final openFolderFailed = context.l10n.settings_openFolderFailed;
              try {
                final path = await _hiveHelper.getPath();
                await launchUrl(
                  Uri.directory(path),
                  mode: LaunchMode.externalApplication,
                );
              } catch (e) {
                AppLogger.e(openFolderFailed, e);
              }
            },
          ),
          if (hasCustomPath)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: context.l10n.common_reset,
              onPressed: () => _resetToDefault(context),
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => _selectHiveStorageDirectory(context),
    );
  }
}
