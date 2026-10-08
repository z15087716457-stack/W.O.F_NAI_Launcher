import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';
import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:path/path.dart' as p;
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';

import '../../../core/enums/precise_ref_type.dart';
import '../../../data/models/image/image_params.dart';
import '../../../data/models/precise_ref/precise_ref_library_entry.dart';
import '../../../data/services/precise_ref_library_storage_service.dart';
import '../../providers/image_generation_provider.dart';
import '../../providers/precise_ref_library_provider.dart';
import '../../widgets/library/library_widgets.dart';
import '../../widgets/gallery/gallery_filter_widgets.dart';
import '../../services/image_workflow_launcher.dart';
import '../../utils/dropped_file_reader.dart';
import '../../widgets/common/app_toast.dart';
import 'widgets/precise_ref_card.dart';
import 'widgets/precise_ref_entry_edit_dialog.dart';
import 'widgets/precise_ref_type_filter_chips.dart';

part 'precise_ref_library_workbench.dart';

/// 精准参考库页面
///
/// 管理可复用的精准参考图片：卡片网格 + 搜索 + 收藏 + 排序，
/// 支持拖拽/粘贴/文件选择入库，条目可一键发送到精准参考或图生图。
class PreciseRefLibraryScreen extends ConsumerStatefulWidget {
  const PreciseRefLibraryScreen({super.key});

  @override
  ConsumerState<PreciseRefLibraryScreen> createState() =>
      _PreciseRefLibraryScreenState();
}

class _PreciseRefLibraryScreenState
    extends ConsumerState<PreciseRefLibraryScreen> {
  final FocusNode _searchFocus = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounceTimer;
  bool _isDragging = false;
  bool _isPickingFile = false;
  LibraryCardSize _cardSize = LibraryCardSize.medium;
  bool? _navVisible;
  String? _selectedId, _anchorId;
  final Set<String> _selectedIds = {};
  bool _multi = false;
  final FocusNode _gridFocus = FocusNode();
  final ScrollController _gridScroll = ScrollController();
  void _updateLayoutState(VoidCallback update) => setState(update);

  @override
  void initState() {
    super.initState();
    LibraryCardSize.load('precise_ref_library_card_size').then((size) {
      if (mounted) setState(() => _cardSize = size);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(preciseRefLibraryNotifierProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _gridFocus.dispose();
    _gridScroll.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref
          .read(preciseRefLibraryNotifierProvider.notifier)
          .setSearchQuery(value);
    });
  }

  // ============================================================
  // 入库
  // ============================================================

  /// 导入时套用的类型：正处于某个类型分类下时跟随该分类，否则用默认
  PreciseRefType get _importType =>
      ref.read(preciseRefLibraryNotifierProvider).typeFilter ??
      PreciseRefType.characterAndStyle;

  Future<void> _importImages() async {
    if (_isPickingFile) return;
    setState(() => _isPickingFile = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: false,
      );
      if (result == null || !mounted) return;

      final importType = _importType;
      final sources = [
        for (final file in result.files)
          PreciseRefLibraryImportSource(
            name: p.basenameWithoutExtension(file.name),
            type: importType,
            loadBytes: () async {
              final filePath = file.path;
              return filePath == null
                  ? file.bytes
                  : File(filePath).readAsBytes();
            },
          ),
      ];
      final batch = await ref
          .read(preciseRefLibraryNotifierProvider.notifier)
          .importMany(sources);
      if (mounted && batch.importedCount > 0) {
        AppToast.success(
          context,
          context.l10n.preciseRefLib_importedCount(batch.importedCount),
        );
      }
      if (mounted && batch.failedCount > 0) {
        AppToast.error(
          context,
          context.l10n.preciseRefLib_importFailedCount(batch.failedCount),
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, context.l10n.preciseRefLib_importFailed('$e'));
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingFile = false);
      }
    }
  }

  Future<void> _handleDrop(PerformDropEvent event) async {
    // 在拖放会话仍存活时并发发起全部读取；逐个串行读取会导致
    // 后续 item 的 reader 随会话释放而失效（platform reader not found）
    final futures = <Future<DroppedFileData?>>[];
    for (final item in event.session.items) {
      final reader = item.dataReader;
      if (reader == null) continue;
      futures.add(
        DroppedFileReader.read(
          reader,
          logTag: 'PreciseRefLibraryDrop',
        ).catchError((Object _) => null),
      );
    }
    final results = await Future.wait(futures);
    if (!mounted) return;

    final importType = _importType;
    final validDrops = results
        .whereType<DroppedFileData>()
        .where((dropped) => dropped.bytes.isNotEmpty)
        .toList();
    final readFailureCount = results.length - validDrops.length;
    final sources = [
      for (final dropped in validDrops)
        PreciseRefLibraryImportSource(
          name: p.basenameWithoutExtension(dropped.fileName),
          type: importType,
          loadBytes: () async => dropped.bytes,
        ),
    ];
    final PreciseRefLibraryBatchImportResult batch;
    try {
      batch = await ref
          .read(preciseRefLibraryNotifierProvider.notifier)
          .importMany(sources);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, context.l10n.preciseRefLib_importFailed('$e'));
      }
      return;
    }
    if (!mounted) return;
    final failedCount = readFailureCount + batch.failedCount;
    if (batch.importedCount > 0) {
      AppToast.success(
        context,
        context.l10n.preciseRefLib_importedCount(batch.importedCount),
      );
    }
    if (failedCount > 0) {
      AppToast.error(
        context,
        context.l10n.preciseRefLib_importFailedCount(failedCount),
      );
    }
  }

  // ============================================================
  // 发送
  // ============================================================

  Future<void> _sendToPreciseRef(PreciseRefLibraryEntry entry) async {
    final replace = HardwareKeyboard.instance.isShiftPressed;
    final l10n = context.l10n;
    final params = ref.read(generationParamsNotifierProvider);
    if (!params.isV4Model) {
      AppToast.warning(context, l10n.preciseRef_v4Only);
      return;
    }

    final bytes = await ref
        .read(preciseRefLibraryStorageServiceProvider)
        .readImageBytes(entry.id);
    if (!mounted) return;
    if (bytes == null) {
      AppToast.error(context, l10n.preciseRefLib_imageMissing);
      return;
    }

    if (replace) {
      ref
          .read(generationParamsNotifierProvider.notifier)
          .clearPreciseReferences();
    }

    // 不等待：方法在第一个 await 前已把原图塞进状态，
    // Director PNG 规范化在后台完成后自动替换（与拖拽/图库发送路径一致）
    unawaited(
      ref
          .read(generationParamsNotifierProvider.notifier)
          .addPreciseReferenceFromImage(
            bytes,
            type: entry.type,
            strength: entry.strength,
            fidelity: entry.fidelity,
          ),
    );
    unawaited(
      ref
          .read(preciseRefLibraryNotifierProvider.notifier)
          .recordUsage(entry.id),
    );
    AppToast.success(context, l10n.preciseRefLib_sent(entry.name));
  }

  Future<void> _sendToImg2Img(PreciseRefLibraryEntry entry) async {
    final l10n = context.l10n;
    final bytes = await ref
        .read(preciseRefLibraryStorageServiceProvider)
        .readImageBytes(entry.id);
    if (!mounted) return;
    if (bytes == null) {
      AppToast.error(context, l10n.preciseRefLib_imageMissing);
      return;
    }

    ImageWorkflowLauncher.openImageToImage(ref, bytes);
    unawaited(
      ref
          .read(preciseRefLibraryNotifierProvider.notifier)
          .recordUsage(entry.id),
    );
    AppToast.success(context, l10n.preciseRefLib_sentToImg2Img(entry.name));
  }

  // ============================================================
  // 编辑 / 删除
  // ============================================================

  Future<void> _editEntry(PreciseRefLibraryEntry entry) async {
    final result = await PreciseRefEntryEditDialog.show(context, entry);
    if (result == null) return;
    await ref
        .read(preciseRefLibraryNotifierProvider.notifier)
        .updateEntry(
          entry.id,
          name: result.name,
          type: result.type,
          strength: result.strength,
          fidelity: result.fidelity,
        );
  }

  Future<void> _deleteEntry(PreciseRefLibraryEntry entry) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.preciseRefLib_confirmDeleteTitle),
        content: Text(l10n.preciseRefLib_confirmDelete(entry.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            key: const Key('precise-ref-delete-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final removed = await ref
          .read(preciseRefLibraryNotifierProvider.notifier)
          .deleteEntry(entry.id);
      if (mounted && !removed) {
        AppToast.error(context, l10n.preciseRefLib_deleteFailed);
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(context, l10n.preciseRefLib_deleteFailed);
      }
    }
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(preciseRefLibraryNotifierProvider);

    return Scaffold(
      body: DropRegion(
        formats: Formats.standardFormats,
        hitTestBehavior: HitTestBehavior.opaque,
        onDropOver: (event) {
          if (event.session.allowedOperations.contains(DropOperation.copy)) {
            if (!_isDragging) {
              setState(() => _isDragging = true);
            }
            return DropOperation.copy;
          }
          return DropOperation.none;
        },
        onDropLeave: (event) {
          if (_isDragging) {
            setState(() => _isDragging = false);
          }
        },
        onPerformDrop: (event) async {
          setState(() => _isDragging = false);
          // 不等待处理完成，让拖放回调立即返回（避免资源管理器卡死）
          unawaited(_handleDrop(event));
          return;
        },
        child: Stack(
          children: [
            _buildWorkbench(state),
            if (_isDragging) _buildDropOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              l10n.preciseRefLib_loadFailed(error),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              key: const Key('precise-ref-library-retry'),
              onPressed: () => ref
                  .read(preciseRefLibraryNotifierProvider.notifier)
                  .reload(showLoading: true),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.common_retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(PreciseRefLibraryState state) => LibraryToolbar(
    searchFocusNode: _searchFocus,
    searchKey: const Key('precise-ref-library-search'),
    searchController: _searchController,
    searchHint: context.l10n.preciseRefLib_searchHint,
    onSearchChanged: _onSearchChanged,
    cardSize: _cardSize,
    onCardSizeChanged: (size) {
      setState(() => _cardSize = size);
      unawaited(size.save('precise_ref_library_card_size'));
    },
    leading:
        (_navVisible == false ||
            (_navVisible == null && MediaQuery.sizeOf(context).width < 800))
        ? LibraryIconButton(
            icon: 'dbl',
            size: 15,
            tooltip: context.l10n.common_expand,
            onPressed: () => setState(() => _navVisible = true),
          )
        : null,
    sortBuilder: (compact) => PopupMenuButton<PreciseRefLibrarySortOrder>(
      key: const Key('precise-ref-library-sort-menu'),
      tooltip: context.l10n.preciseRefLib_sortBy,
      onSelected: (order) => ref
          .read(preciseRefLibraryNotifierProvider.notifier)
          .setSortOrder(order),
      itemBuilder: (_) => [
        _sortMenuItem(
          PreciseRefLibrarySortOrder.createdAt,
          context.l10n.preciseRefLib_sortCreatedAt,
          state,
        ),
        _sortMenuItem(
          PreciseRefLibrarySortOrder.lastUsed,
          context.l10n.preciseRefLib_sortLastUsed,
          state,
        ),
        _sortMenuItem(
          PreciseRefLibrarySortOrder.usedCount,
          context.l10n.preciseRefLib_sortUsedCount,
          state,
        ),
        _sortMenuItem(
          PreciseRefLibrarySortOrder.name,
          context.l10n.preciseRefLib_sortName,
          state,
        ),
      ],
      child: LibraryDropdownFace(
        icon: 'sort',
        label: compact
            ? null
            : switch (state.sortOrder) {
                PreciseRefLibrarySortOrder.createdAt =>
                  context.l10n.preciseRefLib_sortCreatedAt,
                PreciseRefLibrarySortOrder.lastUsed =>
                  context.l10n.preciseRefLib_sortLastUsed,
                PreciseRefLibrarySortOrder.usedCount =>
                  context.l10n.preciseRefLib_sortUsedCount,
                PreciseRefLibrarySortOrder.name =>
                  context.l10n.preciseRefLib_sortName,
              },
        trailingIcon: state.sortDescending ? 'chevD' : 'chevU',
      ),
    ),
    trailingBuilder: (compact) => [
      LibraryModelCapsule(preciseReference: true, compact: compact),
      const SizedBox(width: 8),
      LibraryActionButton(
        iconOnly: compact,
        bordered: true,
        selected: _multi,
        height: 30,
        action: LibraryAction(
          label: context.l10n.common_multiSelect,
          icon: 'check',
          onPressed: () => setState(() {
            _multi = !_multi;
            if (!_multi) _selectedIds.clear();
          }),
        ),
      ),
      const SizedBox(width: 8),
      LibraryActionButton(
        iconOnly: compact,
        height: 30,
        action: LibraryAction(
          key: const Key('precise-ref-library-import-button'),
          label: context.l10n.preciseRefLib_import,
          icon: 'plus',
          primary: true,
          onPressed: _isPickingFile ? null : _importImages,
        ),
      ),
      PopupMenuButton<int>(
        tooltip: context.l10n.library_more,
        onSelected: (_) => ref
            .read(preciseRefLibraryNotifierProvider.notifier)
            .reload(showLoading: true),
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 0,
            child: Text(context.l10n.library_rescanFolders),
          ),
        ],
        child: SizedBox(
          width: 28,
          height: 28,
          child: Center(
            child: LibraryIcon(
              'more',
              strokeWidth: 3,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    ],
  );

  PopupMenuItem<PreciseRefLibrarySortOrder> _sortMenuItem(
    PreciseRefLibrarySortOrder order,
    String label,
    PreciseRefLibraryState state,
  ) {
    final selected = state.sortOrder == order;
    return PopupMenuItem(
      value: order,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          if (selected)
            Icon(
              state.sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildGrid(PreciseRefLibraryState state, int columns, double width) =>
      Focus(
        focusNode: _gridFocus,
        onKeyEvent: (node, event) =>
            _handleGridKey(event, state, columns, width),
        child: GridView.builder(
          key: const PageStorageKey('precise_ref_library_grid'),
          controller: _gridScroll,
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 14,
            crossAxisSpacing: 12,
            mainAxisExtent: width * 1.25 + 46,
          ),
          itemCount: state.filteredEntries.length,
          itemBuilder: (context, index) {
            final entry = state.filteredEntries[index];
            return PreciseRefCard(
              key: Key('precise-ref-card-${entry.id}'),
              entry: entry,
              isSelected: _multi
                  ? _selectedIds.contains(entry.id)
                  : _selectedId == entry.id,
              checkbox: _multi ? _selectedIds.contains(entry.id) : null,
              onTap: () => _select(entry, state),
              onLongPress: () {
                setState(() {
                  _multi = true;
                  _selectedIds.add(entry.id);
                  _selectedId = entry.id;
                });
                _gridFocus.requestFocus();
              },
              onDoubleTap: () => _sendToPreciseRef(entry),
              onSecondaryTapDown: (d) =>
                  _showEntryMenu(entry, d.globalPosition),
              onSendToPreciseRef: () => _sendToPreciseRef(entry),
              onSendToImg2Img: () => _sendToImg2Img(entry),
              onEdit: () => _editEntry(entry),
              onDelete: () => _deleteEntry(entry),
              onToggleFavorite: () => ref
                  .read(preciseRefLibraryNotifierProvider.notifier)
                  .toggleFavorite(entry.id),
            );
          },
        ),
      );

  Widget _buildEmptyView(PreciseRefLibraryState state) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    // 过滤后无结果：给出条目总数与一键清除过滤
    if (state.hasFilters) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_alt_off_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              '${l10n.localGallery_noMatchingResults} '
              '(${l10n.preciseRefLib_entryCount(state.totalCount)})',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const Key('precise-ref-library-clear-filters'),
              onPressed: () {
                _searchController.clear();
                ref
                    .read(preciseRefLibraryNotifierProvider.notifier)
                    .clearFilters();
              },
              icon: const Icon(Icons.filter_alt_off, size: 18),
              label: Text(l10n.localGallery_clearFilters),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            StudioIcons.preciseReference,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.preciseRefLib_empty,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (!state.hasFilters) ...[
            const SizedBox(height: 6),
            Text(
              l10n.preciseRefLib_emptyHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isPickingFile ? null : _importImages,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: Text(l10n.preciseRefLib_import),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropOverlay() {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.preciseRefLib_empty,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
