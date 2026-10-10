part of 'explore_candidate_wall.dart';

abstract class _ExploreWallController
    extends ConsumerState<ExploreCandidateWall> {
  final _stageFocus = FocusNode(debugLabel: 'exploration-stage');
  final _scroll = ScrollController();
  final _groupButton = GlobalKey();
  final Map<String, GlobalKey> _cardKeys = {};
  int _columns = 2;
  double _cardExtent = 300;
  bool get _selectionMode => ref.read(exploreSelectionModeProvider);
  Set<String> get _selectedIds => ref.read(exploreSelectionProvider);

  /// 候选堆缩略图悬停预览会话（FEAT-41）：谱系区全部堆卡共享。
  final ExploreCandidateHoverSession _hoverSession =
      ExploreCandidateHoverSession();

  @override
  void dispose() {
    _hoverSession.dispose();
    _stageFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _setFilter(ExploreGalleryFilter filter) {
    ref.read(exploreGalleryFilterProvider.notifier).state = filter;
  }

  /// 文件夹 chip 右键小菜单：重命名/删除。与牌堆组头按钮同链路，
  /// 覆盖「空文件夹没有组头、无处删除」的缺口。
  Future<void> _showFolderMenu(
    ExploreRun run,
    ExploreCandidateFolder folder,
    Offset globalPosition,
  ) async {
    final overlay = Overlay.of(context).context.findRenderObject();
    if (overlay is! RenderBox) return;
    final localPosition = overlay.globalToLocal(globalPosition);
    final errorColor = Theme.of(context).colorScheme.error;
    final choice = await showMenu<String>(
      context: context,
      constraints: const BoxConstraints(minWidth: 144, maxWidth: 188),
      menuPadding: const EdgeInsets.symmetric(vertical: 4),
      position: RelativeRect.fromRect(
        Rect.fromPoints(localPosition, localPosition),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          key: const Key('explore-folder-menu-rename'),
          value: 'rename',
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 18),
              const SizedBox(width: 10),
              Text(context.l10n.styleExplore_renameFolder),
            ],
          ),
        ),
        PopupMenuItem(
          key: const Key('explore-folder-menu-delete'),
          value: 'delete',
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: errorColor),
              const SizedBox(width: 10),
              Text(
                context.l10n.styleExplore_deleteFolder,
                style: TextStyle(color: errorColor),
              ),
            ],
          ),
        ),
      ],
    );
    if (!mounted) return;
    switch (choice) {
      case 'rename':
        await _renameFolder(run, folder.id);
        break;
      case 'delete':
        await _deleteFolder(run, folder.id);
        break;
    }
  }

  /// 文件夹 chip 拖动落序：全部/收藏在前、未分类在尾均锁定，
  /// 拖入落点夹回文件夹区间，写回 run.folders 顺序（牌堆分组同源）。
  /// onReorderItem 的 newIndex 已按移除项调整（= 最终插入位）。
  void _reorderFolderChips(ExploreRun run, int oldIndex, int newIndex) {
    const locked = 3;
    final folderCount = run.folders.length;
    if (oldIndex < locked || oldIndex >= locked + folderCount) return;
    final target = newIndex.clamp(locked, locked + folderCount - 1);
    final ordered = [for (final folder in run.folders) folder.id];
    ordered.insert(target - locked, ordered.removeAt(oldIndex - locked));
    ref
        .read(exploreRunListNotifierProvider.notifier)
        .reorderFolders(run.id, ordered);
  }

  Future<void> _renameFolder(ExploreRun run, String folderId) async {
    final l10n = context.l10n;
    final folder = run.folderById(folderId);
    if (folder == null) return;
    final name = await ThemedInputDialog.show(
      context: context,
      title: l10n.styleExplore_renameFolder,
      labelText: l10n.styleExplore_folderNameLabel,
      initialValue: folder.name,
      validator: (value) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return l10n.styleExplore_nameRequired;
        // 重名预检（provider 层同名硬校验兜底）。
        if (run.folders.any((f) => f.id != folderId && f.name == trimmed)) {
          return l10n.toast_renameNameConflict;
        }
        return null;
      },
    );
    if (name == null || name.trim().isEmpty) return;
    await ref
        .read(exploreRunListNotifierProvider.notifier)
        .renameFolder(run.id, folderId, name);
  }

  Future<void> _deleteFolder(ExploreRun run, String folderId) async {
    final l10n = context.l10n;
    final folder = run.folderById(folderId);
    if (folder == null) return;
    final confirmed = await ThemedConfirmDialog.show(
      context: context,
      title: l10n.styleExplore_deleteFolder,
      content: l10n.styleExplore_deleteFolderMessage(folder.name),
      confirmText: l10n.common_delete,
      type: ThemedConfirmDialogType.danger,
      icon: Icons.delete_outline,
    );
    if (!confirmed) return;
    await ref
        .read(exploreRunListNotifierProvider.notifier)
        .deleteFolder(run.id, folderId);
  }

  Widget _buildCandidateCard(
    ExploreRun run,
    ExploreCandidate candidate, {
    bool selectable = true,
  }) {
    final current = ref.watch(exploreGeneratingCandidateIdProvider);
    return KeyedSubtree(
      key: ValueKey('explore-candidate-${candidate.id}'),
      child: ExploreCandidateCard(
        key: _cardKeys.putIfAbsent(candidate.id, GlobalKey.new),
        run: run,
        candidate: candidate,
        sequenceNumber:
            run.candidates.indexWhere((c) => c.id == candidate.id) + 1,
        compact:
            ref.watch(exploreStageTabProvider) == ExploreStageTab.evolution,
        selectionMode:
            selectable &&
            (_selectionMode ||
                ref.watch(exploreStageTabProvider) ==
                    ExploreStageTab.evolution),
        selected: selectable && _selectedIds.contains(candidate.id),
        focused: ref.watch(exploreFocusedCandidateIdProvider) == candidate.id,
        generating: candidate.id == current,
        onFocus: () => selectable
            ? _clickCandidate(candidate.id)
            : ref.read(exploreFocusedCandidateIdProvider.notifier).state =
                  candidate.id,
        onToggleSelect: selectable ? () => _clickCandidate(candidate.id) : null,
        onEnterSelection: selectable
            ? () => _enterSelection(candidate.id)
            : null,
        onOpenDetail: () => openExploreCandidate(
          context,
          ref,
          run,
          candidate,
          browsingIds:
              ref.read(exploreStageTabProvider) == ExploreStageTab.evolution
              ? [
                  for (final c in run.candidates)
                    if (c.roundId == candidate.roundId) c.id,
                ]
              : null,
        ),
      ),
    );
  }

  // ==================== 多选与出口 ====================

  bool _canBreed(ExploreRun run) {
    final family = exploreSelectedFamily(
      run,
      ref.read(exploreActiveFamilyIdProvider),
    );
    final set = run.parentSetById(family?.activeParentSetId ?? '');
    final runner = ref.read(exploreRunRunnerProvider);
    return set != null &&
        exploreParentSetRoundsComplete(run, set) &&
        !(runner.isRunning && runner.runId == run.id);
  }

  void _clickCandidate(String id) {
    _stageFocus.requestFocus();
    final focused = ref.read(exploreFocusedCandidateIdProvider);
    final selection = ref.read(exploreSelectionProvider.notifier);
    if (HardwareKeyboard.instance.isShiftPressed) {
      ref.read(exploreSelectionModeProvider.notifier).state = true;
      selection.selectRange(
        focused,
        id,
        ref.read(exploreVisibleCandidatesProvider).map((c) => c.id).toList(),
      );
    } else if (_selectionMode || HardwareKeyboard.instance.isControlPressed) {
      ref.read(exploreSelectionModeProvider.notifier).state = true;
      selection.toggle(id);
    }
    ref.read(exploreFocusedCandidateIdProvider.notifier).state = id;
  }

  void _enterSelection(String? id) {
    _stageFocus.requestFocus();
    ref.read(exploreSelectionModeProvider.notifier).state = true;
    if (id != null) {
      ref.read(exploreFocusedCandidateIdProvider.notifier).state = id;
      if (!_selectedIds.contains(id)) {
        ref.read(exploreSelectionProvider.notifier).toggle(id);
      }
    } else {
      ref.read(exploreSelectionProvider.notifier).clear();
    }
  }

  void _selectAll() {
    ref.read(exploreSelectionModeProvider.notifier).state = true;
    ref
        .read(exploreSelectionProvider.notifier)
        .selectAll(ref.read(exploreVisibleCandidatesProvider).map((c) => c.id));
  }

  void _exitSelection() {
    ref.read(exploreSelectionProvider.notifier).clear();
    ref.read(exploreSelectionModeProvider.notifier).state = false;
  }

  Future<void> _toggleHearts(ExploreRun run, Set<String> ids) async {
    final targets = run.candidates.where((c) => ids.contains(c.id)).toList();
    final heart = !targets.every((c) => c.review.heart);
    for (final target in targets) {
      await ref
          .read(exploreRunListNotifierProvider.notifier)
          .updateReview(run.id, target.id, heart: heart);
    }
  }

  Future<void> _assignMenu(ExploreRun run) async {
    final anchor =
        _groupButton.currentContext?.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final rect = anchor == null
        ? Rect.fromLTWH(overlay.size.width / 2, overlay.size.height - 62, 0, 0)
        : Rect.fromPoints(
            overlay.globalToLocal(anchor.localToGlobal(Offset.zero)),
            overlay.globalToLocal(
              anchor.localToGlobal(
                Offset(anchor.size.width, anchor.size.height),
              ),
            ),
          );
    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(rect, Offset.zero & overlay.size),
      items: [
        for (final folder in run.folders)
          PopupMenuItem(value: folder.id, child: Text(folder.name)),
        PopupMenuItem(
          value: '__none',
          child: Text(context.l10n.styleExplore_folderUncategorized),
        ),
        PopupMenuItem(
          value: '__new',
          child: Text(context.l10n.styleExplore_newGroup),
        ),
      ],
    );
    if (value == null || !mounted) return;
    String? folderId = value == '__none' ? null : value;
    if (value == '__new') {
      final folder = await promptCreateExploreFolder(context, ref, run.id);
      if (folder == null) return;
      folderId = folder.id;
    }
    if (_selectedIds.isNotEmpty) {
      await ref
          .read(exploreRunListNotifierProvider.notifier)
          .assignCandidatesFolder(run.id, _selectedIds.toList(), folderId);
    }
  }

  KeyEventResult _key(ExploreRun run, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (FocusManager.instance.primaryFocus?.context
            ?.findAncestorStateOfType<EditableTextState>() !=
        null) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final visible = ref.read(exploreVisibleCandidatesProvider);
    final focused = ref.read(exploreFocusedCandidateIdProvider);
    final targets = _selectionMode && _selectedIds.isNotEmpty
        ? _selectedIds
        : {if (focused != null) focused};
    if (HardwareKeyboard.instance.isControlPressed) {
      if (key == LogicalKeyboardKey.keyA) {
        _selectAll();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    final horizontal = key == LogicalKeyboardKey.arrowLeft
        ? -1
        : key == LogicalKeyboardKey.arrowRight
        ? 1
        : 0;
    final vertical = key == LogicalKeyboardKey.arrowUp
        ? -1
        : key == LogicalKeyboardKey.arrowDown
        ? 1
        : 0;
    if (horizontal != 0 || vertical != 0) {
      final id = exploreMovedFocus(
        visible,
        focused,
        horizontal,
        vertical,
        _columns,
      );
      ref.read(exploreFocusedCandidateIdProvider.notifier).state = id;
      if (id != null) unawaited(_reveal(id, visible));
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space) {
      final candidate = run.candidateById(focused ?? '');
      if (candidate != null) _openCandidateDetail(run, candidate);
    } else if (key == LogicalKeyboardKey.keyF) {
      if (targets.isNotEmpty) unawaited(_toggleHearts(run, targets));
    } else if (key == LogicalKeyboardKey.keyE) {
      if (targets.isNotEmpty) {
        if (ref.read(exploreStageTabProvider) == ExploreStageTab.evolution) {
          if (_canBreed(run)) {
            unawaited(
              breedExploreNextGeneration(context, ref, run, ids: targets),
            );
          }
        } else {
          unawaited(_createFamilyFromSelection(run, ids: targets));
        }
      }
    } else if (key == LogicalKeyboardKey.delete) {
      if (targets.isNotEmpty) {
        unawaited(_deleteSelected(run, ids: targets));
      }
    } else if (key == LogicalKeyboardKey.escape) {
      if (_selectionMode) {
        _exitSelection();
      } else {
        ref.read(exploreFocusedCandidateIdProvider.notifier).state = null;
      }
    } else {
      final number =
          int.tryParse(key.keyLabel) ??
          [
            LogicalKeyboardKey.numpad0,
            LogicalKeyboardKey.numpad1,
            LogicalKeyboardKey.numpad2,
            LogicalKeyboardKey.numpad3,
            LogicalKeyboardKey.numpad4,
            LogicalKeyboardKey.numpad5,
            LogicalKeyboardKey.numpad6,
            LogicalKeyboardKey.numpad7,
            LogicalKeyboardKey.numpad8,
            LogicalKeyboardKey.numpad9,
          ].indexOf(key);
      if (number < 0 || number > 9) return KeyEventResult.ignored;
      if (number > run.folders.length) return KeyEventResult.handled;
      String? folderId = number == 0 ? null : run.folders[number - 1].id;
      if (folderId != null &&
          run.candidates
              .where((c) => targets.contains(c.id))
              .every((c) => c.folderId == folderId)) {
        folderId = null;
      }
      if (targets.isNotEmpty) {
        unawaited(
          ref
              .read(exploreRunListNotifierProvider.notifier)
              .assignCandidatesFolder(run.id, targets.toList(), folderId),
        );
      }
    }
    return KeyEventResult.handled;
  }

  Future<void> _reveal(String id, List<ExploreCandidate> visible) async {
    var target = _cardKeys[id]?.currentContext;
    if (target == null && _scroll.hasClients) {
      double offset = 0;
      for (final group in visible.map((c) => c.roundId).toSet()) {
        final candidates = visible.where((c) => c.roundId == group).toList();
        final index = candidates.indexWhere((c) => c.id == id);
        if (index >= 0) {
          offset += 48 + (index ~/ _columns) * _cardExtent;
          break;
        }
        offset += 48 + (candidates.length / _columns).ceil() * _cardExtent;
      }
      await _scroll.animateTo(
        offset.clamp(0, _scroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      target = _cardKeys[id]?.currentContext;
    }
    if (target != null && target.mounted) {
      await Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 200),
      );
    }
  }

  /// 多选合并收编：成功后退出多选，取消则保留选择。
  Future<void> _adoptSelected(ExploreRun run) async {
    final selected = [
      for (final candidate in run.candidates)
        if (_selectedIds.contains(candidate.id)) candidate,
    ];
    if (selected.isEmpty) return;
    final created = await ExploreCandidateActions.adoptMerged(
      context,
      ref,
      run: run,
      candidates: selected,
    );
    if (created && mounted) _exitSelection();
  }

  /// 多选批量删图（FEAT-56，FEAT-55 拍板 = 连记录删）：一次确认 → 逐张
  /// 删副本文件 + 移除候选记录，与 FEAT-42 管理弹窗 `_deleteSelected`
  /// 同链路；无副本记录也可删除。生成中的候选保持原状态。
  Future<void> _deleteSelected(ExploreRun run, {Set<String>? ids}) async {
    final targets = [
      for (final candidate in run.candidates)
        if ((ids ?? _selectedIds).contains(candidate.id) &&
            candidate.generation.status !=
                ExploreCandidateGenerationStatus.pending)
          candidate,
    ];
    if (targets.isEmpty) return;
    final l10n = context.l10n;
    final confirmed = await ThemedConfirmDialog.show(
      context: context,
      title: l10n.styleExplore_deleteCandidatesTitle,
      content: l10n.styleExplore_deleteCandidatesMessage(targets.length),
      confirmText: l10n.common_delete,
      type: ThemedConfirmDialogType.danger,
      icon: Icons.delete_outline,
    );
    if (!confirmed || !mounted) return;
    var deleted = 0;
    try {
      final store = ref.read(exploreRunImageStoreProvider);
      final notifier = ref.read(exploreRunListNotifierProvider.notifier);
      // FEAT-55 拍板 = 连记录删：副本删成功的候选整条记录移除。
      final deletedIds = <String>[];
      for (final target in targets) {
        final candidate = ref
            .read(exploreRunListNotifierProvider)
            .valueOrNull
            ?.runById(run.id)
            ?.candidateById(target.id);
        if (candidate == null ||
            candidate.generation.status ==
                ExploreCandidateGenerationStatus.pending) {
          continue;
        }
        final filePath = candidate.generation.filePath;
        if (filePath != null && !await store.deleteCandidateImage(filePath)) {
          continue;
        }
        deletedIds.add(candidate.id);
        deleted++;
      }
      if (deletedIds.isNotEmpty) {
        await notifier.removeCandidates(run.id, deletedIds);
      }
      if (mounted) {
        AppToast.success(
          context,
          l10n.styleExplore_pileManageDeleteDone(deleted),
        );
        _exitSelection();
      }
    } catch (error) {
      AppLogger.e('Batch delete images failed', error, null, 'StyleExplore');
      if (mounted) {
        AppToast.error(context, l10n.styleExplore_operationFailed);
      }
    }
  }

  /// 候选详情弹窗（画廊卡片与谱系区候选堆缩略图点击共用）。
  ///
  /// 翻页序 = 打开瞬间的筛选快照；点开的候选不在快照内（谱系区旁路）
  /// 时退化为单张序列。
  void _openCandidateDetail(ExploreRun run, ExploreCandidate candidate) =>
      openExploreCandidate(context, ref, run, candidate);

  Future<void> _createFamilyFromSelection(
    ExploreRun run, {
    Set<String>? ids,
  }) async {
    final selected = [
      for (final candidate in run.candidates)
        if ((ids ?? _selectedIds).contains(candidate.id)) candidate,
    ];
    if (selected.isEmpty) return;
    if (await startExploreEvolution(context, ref, run, selected) && mounted) {
      _exitSelection();
    }
  }
}
