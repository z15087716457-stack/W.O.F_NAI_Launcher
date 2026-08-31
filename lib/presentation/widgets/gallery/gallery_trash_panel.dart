import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/database_providers.dart';
import '../../../core/database/datasources/gallery_data_source.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/services/gallery/gallery_delete_pool_store.dart';
import '../../providers/gallery_category_provider.dart';
import '../../providers/local_gallery_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/localization_extension.dart';
import '../common/app_toast.dart';
import '../common/themed_confirm_dialog.dart';

/// 删除池条目信息
class _TrashEntry {
  const _TrashEntry({required this.path, required this.existsOnDisk});

  final String path;
  final bool existsOnDisk;

  String get fileName => p.basename(path);
}

/// 删除池（回收站）面板：列出软删入池的文件，支持恢复与彻底删除。
///
/// 池内文件仍在磁盘上（软删语义，下次启动自动物理清理）；
/// 恢复=DB is_deleted 置 0 + 出池，文件立即回到图库。
Future<void> showGalleryTrashPanel(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _GalleryTrashPanelDialog(),
  );
}

class _GalleryTrashPanelDialog extends ConsumerStatefulWidget {
  const _GalleryTrashPanelDialog();

  @override
  ConsumerState<_GalleryTrashPanelDialog> createState() =>
      _GalleryTrashPanelDialogState();
}

class _GalleryTrashPanelDialogState
    extends ConsumerState<_GalleryTrashPanelDialog> {
  List<_TrashEntry> _entries = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final paths = await const GalleryDeletePoolStore().load();
    if (!mounted) return;
    final entries = <_TrashEntry>[];
    for (final path in paths) {
      entries.add(
        _TrashEntry(path: path, existsOnDisk: await File(path).exists()),
      );
    }
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<GalleryDataSource?> _getDataSource() async {
    try {
      final dbManager = await ref.read(databaseManagerProvider.future);
      return dbManager.getDataSource<GalleryDataSource>('gallery');
    } catch (e) {
      AppLogger.e('Trash panel: failed to get data source', e, null, 'Trash');
      return null;
    }
  }

  Future<void> _refreshGallery() async {
    await ref.read(localGalleryNotifierProvider.notifier).refresh();
    await ref.read(galleryCategoryNotifierProvider.notifier).refresh();
  }

  Future<void> _restore(List<String> paths) async {
    if (_busy || paths.isEmpty) return;
    setState(() => _busy = true);
    try {
      final dataSource = await _getDataSource();
      if (dataSource != null) {
        await dataSource.batchRestoreDeleted(paths);
      }
      await const GalleryDeletePoolStore().removeAll(paths);
      // 解除防复活屏，恢复的图才能回到画廊列表
      await ref
          .read(localGalleryNotifierProvider.notifier)
          .clearRecentlyDeleted(paths);
      await _refreshGallery();
      if (mounted) {
        AppToast.success(
          context,
          context.l10n.localGallery_trashRestored(paths.length),
        );
      }
    } catch (e) {
      AppLogger.e('Trash restore failed', e, null, 'Trash');
      if (mounted) {
        AppToast.error(context, context.l10n.localGallery_trashRestoreFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      await _reload();
    }
  }

  Future<void> _deleteAllForever() async {
    if (_busy || _entries.isEmpty) return;
    final l10n = context.l10n;
    final confirmed = await ThemedConfirmDialog.show(
      // ignore: use_build_context_synchronously
      context: context,
      title: l10n.localGallery_trashDeleteAll,
      content: l10n.localGallery_trashDeleteAllConfirm(_entries.length),
      confirmText: l10n.localGallery_trashDeleteAll,
      cancelText: l10n.common_cancel,
      type: ThemedConfirmDialogType.danger,
      icon: Icons.delete_forever_outlined,
    );
    if (!confirmed || !mounted || _busy) return;

    setState(() => _busy = true);
    var deleted = 0;
    try {
      final purged = <String>[];
      for (final entry in _entries) {
        try {
          final file = File(entry.path);
          if (await file.exists()) {
            await file.delete();
          }
          purged.add(entry.path);
          deleted++;
        } catch (e) {
          AppLogger.w(
            'Trash purge failed (kept in pool): ${entry.path}: $e',
            'Trash',
          );
        }
      }
      // 成功删除的出池；失败的留着下次再试——与启动清理同一语义
      await const GalleryDeletePoolStore().removeAll(purged);
      // 画廊列表轻量对齐：被彻底删除的图不该还挂在视图里
      // （软删时内存已摘；这里兜底重取当前页，配合数据集重挂刷新）
      try {
        final galleryState = ref.read(localGalleryNotifierProvider);
        await ref
            .read(localGalleryNotifierProvider.notifier)
            .loadPage(galleryState.currentPage, showLoading: false);
        await ref.read(galleryCategoryNotifierProvider.notifier).refresh();
      } catch (e) {
        AppLogger.w('Trash purge gallery refresh failed: $e', 'Trash');
      }
      if (mounted) {
        AppToast.success(
          context,
          context.l10n.localGallery_trashDeletedForever(deleted),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.delete_outline, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Text(l10n.localGallery_trashTitle),
          const Spacer(),
          if (!_loading && _entries.isNotEmpty)
            Text(
              l10n.localGallery_trashCount(_entries.length),
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
      content: SizedBox(
        width: 520,
        height: 420,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _entries.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 48,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.localGallery_trashEmpty),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      l10n.localGallery_trashHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        return _buildEntryTile(theme, l10n, entry);
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        if (!_loading && _entries.isNotEmpty) ...[
          TextButton(
            onPressed: _busy
                ? null
                : () => _restore(_entries.map((e) => e.path).toList()),
            child: Text(l10n.localGallery_trashRestoreAll),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: _busy ? null : _deleteAllForever,
            icon: const Icon(Icons.delete_forever, size: 18),
            label: Text(l10n.localGallery_trashDeleteAll),
          ),
        ],
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_close),
        ),
      ],
    );
  }

  Widget _buildEntryTile(
    ThemeData theme,
    AppLocalizations l10n,
    _TrashEntry entry,
  ) {
    return ListTile(
      dense: true,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 44,
          height: 44,
          child: entry.existsOnDisk
              ? Image.file(
                  File(entry.path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.broken_image_outlined,
                    color: theme.colorScheme.outline,
                  ),
                )
              : Icon(Icons.help_outline, color: theme.colorScheme.outline),
        ),
      ),
      title: Text(entry.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        entry.existsOnDisk
            ? p.dirname(entry.path)
            : l10n.localGallery_trashFileMissing,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      trailing: TextButton(
        onPressed: _busy ? null : () => _restore([entry.path]),
        child: Text(l10n.localGallery_trashRestore),
      ),
    );
  }
}
