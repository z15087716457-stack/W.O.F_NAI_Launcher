part of 'precise_ref_library_screen.dart';

extension _PreciseLibraryWorkbench on _PreciseRefLibraryScreenState {
  Widget _buildWorkbench(PreciseRefLibraryState state) => LibrarySearchScope(
    focusNode: _searchFocus,
    controller: _searchController,
    onChanged: _onSearchChanged,
    child: LibraryShell(
      navVisible: _navVisible,
      hasSelection: false,
      nav: Column(
        children: [
          LibraryNavHeader(
            title: context.l10n.preciseRefLib_title,
            icon: Icon(
              StudioIcons.preciseReference,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            trailing: LibraryIconButton(
              icon: 'dbl',
              size: 15,
              mirrored: true,
              tooltip: context.l10n.common_collapse,
              onPressed: () => _updateLayoutState(() => _navVisible = false),
            ),
          ),
          LibraryNavItem(
            title: context.l10n.preciseRefLib_title,
            isSelected: true,
            count: state.totalCount,
            icon: const LibraryIcon('grid', size: 15),
            onTap: () => ref
                .read(preciseRefLibraryNotifierProvider.notifier)
                .clearFilters(),
          ),
          LibraryNavItem(
            title: context.l10n.common_favorite,
            count: state.entries.where((e) => e.isFavorite).length,
            icon: const LibraryIcon('star', size: 15),
            onTap: () => ref
                .read(preciseRefLibraryNotifierProvider.notifier)
                .toggleFavoritesOnly(),
          ),
        ],
      ),
      inspector: Column(
        children: [
          Container(
            height: 62,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
          ),
          const Expanded(child: SizedBox.shrink()),
        ],
      ),
      selectionBar: _multi
          ? LibrarySelectionBar(
              selectedCount: _selectedIds.length,
              onExit: () => _updateLayoutState(() {
                _multi = false;
                _selectedIds.clear();
              }),
              onSelectAll: () => _updateLayoutState(
                () =>
                    _selectedIds.addAll(state.filteredEntries.map((e) => e.id)),
              ),
              onInvertSelection: () => _updateLayoutState(() {
                final ids = state.filteredEntries
                    .map((e) => e.id)
                    .toSet()
                    .difference(_selectedIds);
                _selectedIds
                  ..clear()
                  ..addAll(ids);
              }),
              actions: [
                LibraryAction(
                  label: context.l10n.library_addToGeneration,
                  icon: 'plus',
                  primary: true,
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () => _sendSelected(state),
                ),
                LibraryAction(
                  label: context.l10n.common_favorite,
                  icon: 'star',
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () {
                          for (final id in _selectedIds) {
                            ref
                                .read(
                                  preciseRefLibraryNotifierProvider.notifier,
                                )
                                .toggleFavorite(id);
                          }
                        },
                ),
                LibraryAction(
                  label: context.l10n.common_delete,
                  icon: 'trash',
                  destructive: true,
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () => _deleteSelected(state),
                ),
              ],
            )
          : null,
      main: LayoutBuilder(
        builder: (context, c) {
          final columns = ((c.maxWidth - 24) / (_cardSize.width + 12))
              .round()
              .clamp(1, 12);
          final width = (c.maxWidth - 36 - (columns - 1) * 12) / columns;
          return Column(
            children: [
              WindowHeaderDragSurface(child: _buildToolbar(state)),
              LibraryFilterRow(
                chips: [
                  PreciseRefTypeFilterChips(
                    value: state.typeFilter,
                    onChanged: (type) => ref
                        .read(preciseRefLibraryNotifierProvider.notifier)
                        .setTypeFilter(type),
                  ),
                  GalleryFilterChip(
                    key: const Key('precise-ref-library-favorites-toggle'),
                    label: context.l10n.common_favorite,
                    tooltip: context.l10n.preciseRefLib_favoritesOnly,
                    active: state.favoritesOnly,
                    onTap: () => ref
                        .read(preciseRefLibraryNotifierProvider.notifier)
                        .toggleFavoritesOnly(),
                  ),
                ],
                countText: '${state.filteredEntries.length}',
              ),
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.error != null
                    ? _buildErrorView(state.error!)
                    : state.filteredEntries.isEmpty
                    ? _buildEmptyView(state)
                    : _buildGrid(state, columns, width),
              ),
            ],
          );
        },
      ),
    ),
  );

  void _select(PreciseRefLibraryEntry entry, PreciseRefLibraryState state) {
    _gridFocus.requestFocus();
    final keys = HardwareKeyboard.instance;
    _updateLayoutState(() {
      if (keys.isShiftPressed) {
        _multi = true;
        final a = state.filteredEntries.indexWhere(
          (e) => e.id == (_anchorId ?? _selectedId),
        );
        final b = state.filteredEntries.indexWhere((e) => e.id == entry.id);
        if (a >= 0) {
          _selectedIds.addAll(
            state.filteredEntries
                .sublist(a < b ? a : b, (a > b ? a : b) + 1)
                .map((e) => e.id),
          );
        } else {
          _selectedIds.add(entry.id);
        }
      } else if (keys.isControlPressed || keys.isMetaPressed || _multi) {
        if (!_multi && _selectedId != null) _selectedIds.add(_selectedId!);
        _multi = true;
        if (!_selectedIds.remove(entry.id)) _selectedIds.add(entry.id);
        _anchorId = entry.id;
      } else {
        _anchorId = entry.id;
      }
      _selectedId = entry.id;
    });
  }

  KeyEventResult _handleGridKey(
    KeyEvent event,
    PreciseRefLibraryState state,
    int columns,
    double width,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey,
        keys = HardwareKeyboard.instance,
        entries = state.filteredEntries;
    if (key == LogicalKeyboardKey.escape && _multi) {
      _updateLayoutState(() {
        _multi = false;
        _selectedIds.clear();
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyA &&
        (keys.isControlPressed || keys.isMetaPressed)) {
      _updateLayoutState(() {
        _multi = true;
        _selectedIds.addAll(entries.map((e) => e.id));
      });
      return KeyEventResult.handled;
    }
    if (entries.isEmpty) return KeyEventResult.ignored;
    final index = entries.indexWhere((e) => e.id == _selectedId);
    final step = key == LogicalKeyboardKey.arrowRight
        ? 1
        : key == LogicalKeyboardKey.arrowLeft
        ? -1
        : key == LogicalKeyboardKey.arrowDown
        ? columns
        : key == LogicalKeyboardKey.arrowUp
        ? -columns
        : 0;
    if (step != 0) {
      final next = (index < 0 ? 0 : index + step).clamp(0, entries.length - 1);
      _updateLayoutState(() => _selectedId = entries[next].id);
      if (_gridScroll.hasClients) {
        _gridScroll.jumpTo(
          ((next ~/ columns) * (width * 1.25 + 60)).clamp(
            0,
            _gridScroll.position.maxScrollExtent,
          ),
        );
      }
      return KeyEventResult.handled;
    }
    if (index < 0) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.enter) {
      unawaited(_sendToPreciseRef(entries[index]));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete) {
      unawaited(_multi ? _deleteSelected(state) : _deleteEntry(entries[index]));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyF &&
        !keys.isControlPressed &&
        !keys.isMetaPressed &&
        !keys.isAltPressed) {
      ref
          .read(preciseRefLibraryNotifierProvider.notifier)
          .toggleFavorite(entries[index].id);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _sendSelected(PreciseRefLibraryState state) async {
    for (final e in state.filteredEntries.where(
      (e) => _selectedIds.contains(e.id),
    )) {
      if (!mounted) return;
      await _sendToPreciseRef(e);
    }
  }

  Future<void> _deleteSelected(PreciseRefLibraryState state) async {
    for (final e in state.filteredEntries.where(
      (e) => _selectedIds.contains(e.id),
    )) {
      if (!mounted) return;
      await _deleteEntry(e);
    }
  }

  Future<void> _showEntryMenu(
    PreciseRefLibraryEntry entry,
    Offset position,
  ) async {
    final choice = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        PopupMenuItem(
          value: 0,
          child: Text(context.l10n.library_addToGeneration),
        ),
        PopupMenuItem(
          value: 1,
          child: Text(context.l10n.preciseRefLib_sendToImg2Img),
        ),
        PopupMenuItem(
          value: 2,
          child: Text(context.l10n.preciseRefLib_editEntry),
        ),
        PopupMenuItem(value: 3, child: Text(context.l10n.common_delete)),
      ],
    );
    if (!mounted) return;
    switch (choice) {
      case 0:
        await _sendToPreciseRef(entry);
      case 1:
        await _sendToImg2Img(entry);
      case 2:
        await _editEntry(entry);
      case 3:
        await _deleteEntry(entry);
    }
  }
}
