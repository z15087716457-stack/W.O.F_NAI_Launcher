part of 'vibe_library_screen.dart';

extension _VibeLibraryWorkbench on _VibeLibraryScreenState {
  Widget _buildWorkbench(
    VibeLibraryState state,
    VibeLibraryCategoryState categoryState,
    SelectionModeState selection,
    ThemeData theme,
  ) => LibrarySearchScope(
    focusNode: _searchFocus,
    controller: _searchController,
    onChanged: (value) {
      _searchDebounceTimer?.cancel();
      _searchDebounceTimer = Timer(
        const Duration(milliseconds: 300),
        () => ref
            .read(vibeLibraryNotifierProvider.notifier)
            .setSearchQuery(value),
      );
    },
    child: LibraryShell(
      navVisible: _navVisible,
      hasSelection: false,
      nav: Column(
        children: [
          LibraryNavHeader(
            title: context.l10n.vibeLibrary_title,
            icon: Icon(
              StudioIcons.vibeLibrary,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            trailing: LibraryIconButton(
              icon: 'dbl',
              size: 15,
              mirrored: true,
              tooltip: context.l10n.common_collapse,
              onPressed: () => _updateLayoutState(() => _navVisible = false),
            ),
          ),
          LibraryNavSection(
            title: context.l10n.vibeLibrary_categories,
            trailing: LibraryIconButton(
              icon: 'plus',
              size: 14,
              tooltip: context.l10n.vibeLibrary_createCategoryTitle,
              onPressed: () => _showCreateCategoryDialog(context),
            ),
          ),
          Expanded(
            child: VibeCategoryTreeView(
              categories: categoryState.categories,
              totalEntryCount: state.entries.length,
              favoriteCount: state.favoriteCount,
              selectedCategoryId: categoryState.selectedCategoryId,
              onCategorySelected: (id) {
                ref
                    .read(vibeLibraryCategoryNotifierProvider.notifier)
                    .selectCategory(id);
                if (id == 'favorites') {
                  ref
                      .read(vibeLibraryNotifierProvider.notifier)
                      .setFavoritesOnly(true);
                } else {
                  // 切换到其他分类时，清除收藏过滤状态
                  ref
                      .read(vibeLibraryNotifierProvider.notifier)
                      .setFavoritesOnly(false);
                  ref
                      .read(vibeLibraryNotifierProvider.notifier)
                      .setCategoryFilter(id);
                }
              },
              onCategoryRename: (id, newName) async {
                await ref
                    .read(vibeLibraryCategoryNotifierProvider.notifier)
                    .renameCategory(id, newName);
              },
              onCategoryDelete: (id) async {
                final confirmed = await ThemedConfirmDialog.show(
                  context: context,
                  title: context.l10n.vibeLibrary_deleteCategoryTitle,
                  content: context.l10n.vibeLibrary_deleteCategoryContent,
                  confirmText: context.l10n.common_delete,
                  cancelText: context.l10n.common_cancel,
                  type: ThemedConfirmDialogType.danger,
                  icon: Icons.delete_outline,
                );
                if (confirmed) {
                  await ref
                      .read(vibeLibraryCategoryNotifierProvider.notifier)
                      .deleteCategory(id, moveEntriesToParent: true);
                }
              },
              onAddSubCategory: (parentId) async {
                final name = await ThemedInputDialog.show(
                  context: context,
                  title: parentId == null
                      ? context.l10n.vibeLibrary_createCategoryTitle
                      : context.l10n.vibeLibrary_createSubCategoryTitle,
                  hintText: context.l10n.vibeLibrary_categoryNameHint,
                  confirmText: context.l10n.vibeLibrary_createCategoryConfirm,
                  cancelText: context.l10n.common_cancel,
                );
                if (name != null && name.isNotEmpty) {
                  await ref
                      .read(vibeLibraryCategoryNotifierProvider.notifier)
                      .createCategory(name, parentId: parentId);
                }
              },
              onCategoryMove: (categoryId, newParentId) async {
                await ref
                    .read(vibeLibraryCategoryNotifierProvider.notifier)
                    .moveCategory(categoryId, newParentId);
              },
            ),
          ),
        ],
      ),
      inspector: Column(
        children: [
          Container(
            height: 62,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
          ),
          const Expanded(child: SizedBox.shrink()),
        ],
      ),
      selectionBar: selection.isActive
          ? _buildBulkActionBar(state, selection, theme)
          : null,
      main: LayoutBuilder(
        builder: (context, c) {
          final columns = ((c.maxWidth - 24) / (_cardSize.width + 12))
              .round()
              .clamp(1, 12);
          final width = (c.maxWidth - 36 - (columns - 1) * 12) / columns;
          return Column(
            children: [
              WindowHeaderDragSurface(
                child: _buildToolbar(state, selection, theme),
              ),
              LibraryFilterRow(
                chips: [
                  GalleryFilterChip(
                    label: context.l10n.localGallery_allVersions,
                    tooltip: context.l10n.localGallery_allVersions,
                    active: !state.favoritesOnly,
                    count: state.totalCount,
                    onTap: () => ref
                        .read(vibeLibraryNotifierProvider.notifier)
                        .setFavoritesOnly(false),
                  ),
                  GalleryFilterChip(
                    label: context.l10n.common_favorite,
                    tooltip: context.l10n.common_favorite,
                    active: state.favoritesOnly,
                    onTap: () => ref
                        .read(vibeLibraryNotifierProvider.notifier)
                        .setFavoritesOnly(true),
                  ),
                ],
                countText: '${state.filteredCount}',
              ),
              Expanded(child: _buildBody(state, columns, width, selection)),
              if (!state.isLoading &&
                  state.filteredEntries.isNotEmpty &&
                  state.totalPages > 0)
                _buildPaginationBar(state, c.maxWidth),
            ],
          );
        },
      ),
    ),
  );
}
