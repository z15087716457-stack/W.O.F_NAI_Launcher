part of 'vibe_library_screen.dart';

extension _VibeLibraryScreenLayout on _VibeLibraryScreenState {
  /// 构建工具栏
  Widget _buildToolbar(
    VibeLibraryState state,
    SelectionModeState selection,
    ThemeData theme,
  ) => LibraryToolbar(
    searchFocusNode: _searchFocus,
    searchController: _searchController,
    searchHint: context.l10n.vibeLibrary_searchHint,
    onSearchChanged: (value) {
      _searchDebounceTimer?.cancel();
      _searchDebounceTimer = Timer(
        const Duration(milliseconds: 300),
        () => ref
            .read(vibeLibraryNotifierProvider.notifier)
            .setSearchQuery(value),
      );
    },
    cardSize: _cardSize,
    onCardSizeChanged: (size) {
      _updateLayoutState(() => _cardSize = size);
      unawaited(size.save('vibe_library_card_size'));
    },
    leading:
        (_navVisible == false ||
            (_navVisible == null && MediaQuery.sizeOf(context).width < 800))
        ? IconButton(
            onPressed: () => _updateLayoutState(() => _navVisible = true),
            icon: const LibraryIcon('dbl', size: 15),
          )
        : null,
    sortBuilder: (compact) => _buildSortButton(theme, state, compact: compact),
    trailingBuilder: (compact) => [
      LibraryModelCapsule(compact: compact),
      const SizedBox(width: 8),
      LibraryActionButton(
        iconOnly: compact,
        action: LibraryAction(
          label: context.l10n.common_multiSelect,
          icon: 'check',
          onPressed: () =>
              ref.read(vibeLibrarySelectionNotifierProvider.notifier).enter(),
        ),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onSecondaryTapDown: (d) => _showImportMenu(d.globalPosition),
        child: PopupMenuButton<int>(
          onSelected: (i) => [
            () => _importVibes(),
            () => _importVibesFromImage(),
            () => _importVibesFromClipboard(),
          ][i](),
          itemBuilder: (_) => [
            PopupMenuItem(value: 0, child: Text(context.l10n.common_import)),
            PopupMenuItem(
              value: 1,
              child: Text(context.l10n.vibeLibrary_importFromImage),
            ),
            PopupMenuItem(
              value: 2,
              child: Text(context.l10n.vibeLibrary_importFromClipboard),
            ),
          ],
          child: LibraryActionButton(
            iconOnly: compact,
            action: LibraryAction(
              label: context.l10n.common_import,
              icon: 'plus',
              primary: true,
              onPressed: _isImporting || _isPickingFile
                  ? null
                  : () => _importVibes(),
            ),
          ),
        ),
      ),
      PopupMenuButton<int>(
        tooltip: context.l10n.library_more,
        onSelected: (i) {
          switch (i) {
            case 0:
              _exportVibes();
            case 1:
              ref
                  .read(vibeLibraryNotifierProvider.notifier)
                  .reload(syncFileSystem: true, showLoading: true);
            case 2:
              _openVibeLibraryFolder();
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 0, child: Text(context.l10n.library_exportAll)),
          PopupMenuItem(
            value: 1,
            child: Text(context.l10n.library_rescanFolders),
          ),
          PopupMenuItem(
            value: 2,
            child: Text(context.l10n.vibeLibrary_openFolderTooltip),
          ),
        ],
        child: const SizedBox(
          width: 28,
          height: 32,
          child: Center(child: LibraryIcon('more')),
        ),
      ),
    ],
  );

  /// 构建搜索框

  /// 构建排序按钮
  Widget _buildSortButton(
    ThemeData theme,
    VibeLibraryState state, {
    bool compact = false,
  }) {
    String sortLabel;

    switch (state.sortOrder) {
      case VibeLibrarySortOrder.createdAt:
        sortLabel = context.l10n.vibeSelectorSortCreated;
      case VibeLibrarySortOrder.lastUsed:
        sortLabel = context.l10n.vibeSelectorSortLastUsed;
      case VibeLibrarySortOrder.usedCount:
        sortLabel = context.l10n.vibeSelectorSortUsedCount;
      case VibeLibrarySortOrder.name:
        sortLabel = context.l10n.vibeSelectorSortName;
    }

    return PopupMenuButton<VibeLibrarySortOrder>(
      tooltip: context.l10n.vibeLibrary_sortTooltip,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LibraryIcon('sort', size: 14),
            const SizedBox(width: 4),
            if (!compact)
              Text(sortLabel, style: const TextStyle(fontSize: 12.5)),
            Icon(
              state.sortDescending
                  ? Icons.arrow_drop_down
                  : Icons.arrow_drop_up,
              size: 16,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildSortMenuItem(
          VibeLibrarySortOrder.createdAt,
          context.l10n.vibeSelectorSortCreated,
          Icons.access_time,
          state,
        ),
        _buildSortMenuItem(
          VibeLibrarySortOrder.lastUsed,
          context.l10n.vibeSelectorSortLastUsed,
          Icons.history,
          state,
        ),
        _buildSortMenuItem(
          VibeLibrarySortOrder.usedCount,
          context.l10n.vibeSelectorSortUsedCount,
          Icons.trending_up,
          state,
        ),
        _buildSortMenuItem(
          VibeLibrarySortOrder.name,
          context.l10n.vibeSelectorSortName,
          Icons.sort_by_alpha,
          state,
        ),
      ],
      onSelected: (order) {
        ref.read(vibeLibraryNotifierProvider.notifier).setSortOrder(order);
      },
    );
  }

  PopupMenuItem<VibeLibrarySortOrder> _buildSortMenuItem(
    VibeLibrarySortOrder order,
    String label,
    IconData icon,
    VibeLibraryState state,
  ) {
    final isSelected = state.sortOrder == order;
    return PopupMenuItem(
      value: order,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isSelected ? Colors.blue : null),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : null,
              fontWeight: isSelected ? FontWeight.w600 : null,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(
              state.sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
              size: 16,
              color: Colors.blue,
            ),
          ],
        ],
      ),
    );
  }

  /// 构建刷新按钮

  /// 构建批量操作栏
  Widget _buildBulkActionBar(
    VibeLibraryState state,
    SelectionModeState selection,
    ThemeData theme,
  ) => LibrarySelectionBar(
    selectedCount: selection.selectedIds.length,
    onExit: () =>
        ref.read(vibeLibrarySelectionNotifierProvider.notifier).exit(),
    onSelectAll: () => ref
        .read(vibeLibrarySelectionNotifierProvider.notifier)
        .selectAll(state.currentEntries.map((e) => e.id).toList()),
    onInvertSelection: () => ref
        .read(vibeLibrarySelectionNotifierProvider.notifier)
        .selectAll(
          state.currentEntries
              .where((e) => !selection.selectedIds.contains(e.id))
              .map((e) => e.id)
              .toList(),
        ),
    actions: [
      LibraryAction(
        label: context.l10n.library_addToGeneration,
        icon: 'plus',
        primary: true,
        onPressed: _batchSendToGeneration,
      ),
      LibraryAction(
        label: context.l10n.common_favorite,
        icon: 'star',
        onPressed: _batchToggleFavorite,
      ),
      LibraryAction(
        label: context.l10n.common_move,
        icon: 'folder',
        onPressed: () => _showMoveToCategoryDialog(context),
      ),
      LibraryAction(
        label: context.l10n.common_export,
        icon: 'upload',
        onPressed: _batchExport,
      ),
      LibraryAction(
        label: context.l10n.common_delete,
        icon: 'trash',
        destructive: true,
        onPressed: _batchDelete,
      ),
    ],
  );

  /// 构建主体内容
  Widget _buildBody(
    VibeLibraryState state,
    int columns,
    double itemWidth,
    SelectionModeState selectionState,
  ) {
    if (state.error != null) {
      return GalleryErrorView(
        error: state.error,
        onRetry: () {
          ref
              .read(vibeLibraryNotifierProvider.notifier)
              .reload(syncFileSystem: true, showLoading: true);
        },
      );
    }

    if (state.isInitializing && state.entries.isEmpty) {
      return const GalleryLoadingView();
    }

    if (state.entries.isEmpty) {
      return const VibeLibraryEmptyView();
    }

    return VibeLibraryContentView(
      columns: columns,
      itemWidth: itemWidth,
      selectedId: _selectedVibeId,
      onSelected: (id) => _updateLayoutState(() => _selectedVibeId = id),
    );
  }

  /// 构建分页条
  Widget _buildPaginationBar(VibeLibraryState state, double contentWidth) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: state.currentPage > 0
                ? () {
                    ref
                        .read(vibeLibraryNotifierProvider.notifier)
                        .loadPreviousPage();
                  }
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              context.l10n.vibeLibrary_pageIndicator(
                state.currentPage + 1,
                state.totalPages,
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: state.currentPage < state.totalPages - 1
                ? () {
                    ref
                        .read(vibeLibraryNotifierProvider.notifier)
                        .loadNextPage();
                  }
                : null,
          ),
          const SizedBox(width: 16),
          Text(
            context.l10n.vibeLibrary_itemsPerPage,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: state.pageSize,
            underline: const SizedBox(),
            items: [20, 50, 100].map((size) {
              return DropdownMenuItem(value: size, child: Text('$size'));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(vibeLibraryNotifierProvider.notifier)
                    .setPageSize(value);
              }
            },
          ),
          const Spacer(),
          Text(
            context.l10n.vibeLibrary_totalCount(state.filteredCount.toString()),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
