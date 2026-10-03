import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/prompt_block/prompt_block.dart';
import '../../../../data/models/prompt_block/prompt_block_collection.dart';
import '../../../../data/models/prompt_block/prompt_block_folder.dart';
import '../../../../data/repositories/prompt_block_repository.dart';
import '../../../providers/prompt_block_library_provider.dart';
import '../../../../core/utils/localization_extension.dart';

enum BlockOrganizerPage { favorites, folders, tags }

enum _OrganizerNodeKind { folder, collection }

class _OrganizerNodeDrag {
  const _OrganizerNodeDrag(this.kind, this.id, this.parentId);

  final _OrganizerNodeKind kind;
  final String id;
  final String? parentId;
}

/// 管理页、生成页和拖放共用的紧凑定位窗。
Future<void> showBlockOrganizerPopover(
  BuildContext context, {
  required List<String> blockIds,
  required Offset anchor,
  required BlockOrganizerPage page,
  PromptBlockTransferTarget? dropTarget,
  String? sourceCollectionId,
  bool sourceFavorites = false,
}) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: context.l10n.blockOrganizer_barrierLabel,
  barrierColor: Colors.transparent,
  transitionDuration: const Duration(milliseconds: 110),
  pageBuilder: (context, _, _) => _OrganizerPanel(
    blockIds: blockIds,
    anchor: anchor,
    page: page,
    dropTarget: dropTarget,
    sourceCollectionId: sourceCollectionId,
    sourceFavorites: sourceFavorites,
  ),
);

class _OrganizerPanel extends ConsumerStatefulWidget {
  const _OrganizerPanel({
    required this.blockIds,
    required this.anchor,
    required this.page,
    this.dropTarget,
    this.sourceCollectionId,
    this.sourceFavorites = false,
  });

  final List<String> blockIds;
  final Offset anchor;
  final BlockOrganizerPage page;
  final PromptBlockTransferTarget? dropTarget;
  final String? sourceCollectionId;
  final bool sourceFavorites;

  @override
  ConsumerState<_OrganizerPanel> createState() => _OrganizerPanelState();
}

class _OrganizerPanelState extends ConsumerState<_OrganizerPanel> {
  final _search = TextEditingController();
  final _name = TextEditingController();
  final _listScrollController = ScrollController();
  final _listViewportKey = GlobalKey();
  final Set<String> _expanded = {};
  Timer? _autoScrollTimer;
  double _autoScrollStep = 0;
  PromptBlockTransferTarget? _picked;
  bool _creating = false;
  bool _creatingCollectionFolder = false;
  bool _busy = false;
  Color _tagColor = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _picked = widget.dropTarget;
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _stopAutoScroll();
    _search.dispose();
    _name.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  PromptBlockLibraryNotifier get _notifier =>
      ref.read(promptBlockLibraryNotifierProvider.notifier);

  Future<void> _transfer(PromptBlockTransferMode mode) async {
    final target = _picked;
    if (target == null || _busy) return;
    final conflicts = _notifier.transferConflictCount(widget.blockIds, target);
    if (conflicts > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.blockOrganizer_replaceTitle),
          content: Text(
            mode == PromptBlockTransferMode.move
                ? context.l10n.blockOrganizer_replaceMoveBody(conflicts)
                : context.l10n.blockOrganizer_replaceCopyBody(conflicts),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.common_cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.blockOrganizer_replace),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await _notifier.transferBlocks(
        widget.blockIds,
        target,
        mode,
        sourceCollectionId: widget.sourceCollectionId,
        sourceFavorites: widget.sourceFavorites,
        replaceConflicts: conflicts > 0,
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setFavorite(bool favorite) async {
    setState(() => _busy = true);
    try {
      await _notifier.setFavorite(widget.blockIds, favorite);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleCollection(PromptBlockCollection node) async {
    final state = ref.read(promptBlockLibraryNotifierProvider).valueOrNull;
    if (state == null || _busy) return;
    final allMembers = widget.blockIds.every(node.blockIds.contains);
    setState(() => _busy = true);
    try {
      for (final id in widget.blockIds) {
        if (node.blockIds.contains(id) != allMembers) continue;
        await _notifier.toggleBlockInCollection(node.id, id);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveNew() async {
    final name = _name.text.trim();
    if (name.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      if (widget.page == BlockOrganizerPage.tags) {
        await _applyTag(
          PromptBlockTag(
            name: name,
            color:
                '#${_tagColor.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0')}',
          ),
          add: true,
        );
      } else if (widget.page == BlockOrganizerPage.folders) {
        final folder = await _notifier.createFolder(
          name: name,
          parentId: _picked?.kind == PromptBlockTransferKind.folder
              ? _picked?.id
              : null,
        );
        _picked = PromptBlockTransferTarget(
          PromptBlockTransferKind.folder,
          folder.id,
        );
      } else {
        final parentId = _picked?.kind == PromptBlockTransferKind.collection
            ? _picked?.id
            : null;
        final selected = ref
            .read(promptBlockLibraryNotifierProvider)
            .valueOrNull
            ?.collectionById(parentId ?? '');
        final node = await _notifier.createCollection(
          name: name,
          isFolder: _creatingCollectionFolder,
          parentId: selected?.isFolder == true
              ? selected!.id
              : selected?.parentId,
        );
        _picked = PromptBlockTransferTarget(
          PromptBlockTransferKind.collection,
          node.id,
        );
      }
      _name.clear();
      if (mounted) setState(() => _creating = false);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _applyTag(PromptBlockTag tag, {required bool add}) async {
    final state = ref.read(promptBlockLibraryNotifierProvider).valueOrNull;
    if (state == null) return;
    for (final id in widget.blockIds) {
      final block = state.blockById(id);
      if (block == null) continue;
      final tags = block.tags
          .where((item) => item.name.toLowerCase() != tag.name.toLowerCase())
          .toList();
      if (add) tags.add(tag);
      await _notifier.updateBlock(block.copyWith(tags: tags));
    }
  }

  Future<void> _customTagColor() async {
    final controller = TextEditingController(
      text:
          '#${_tagColor.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0')}',
    );
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.blockOrganizer_customTagColor),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: context.l10n.blockOrganizer_colorHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.l10n.common_confirm),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !mounted) return;
    final hex = value.replaceFirst('#', '');
    if (!RegExp(r'^(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').hasMatch(hex)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.blockOrganizer_invalidColor)),
      );
      return;
    }
    setState(
      () => _tagColor = Color(
        int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16),
      ),
    );
  }

  Future<void> _manageFolder(PromptBlockFolder folder, String action) async {
    if (action == 'rename') {
      final name = await _askName(folder.name);
      if (name != null) {
        await _notifier.updateFolder(folder.copyWith(name: name));
      }
    } else if (action == 'delete') {
      if (await _confirmDelete(
        context.l10n.blockOrganizer_deleteFolderConfirm(folder.name),
      )) {
        await _notifier.deleteFolder(
          folder.id,
          mode: PromptBlockFolderDeleteMode.moveContentsToRoot,
        );
      }
    }
  }

  Future<void> _manageCollection(
    PromptBlockCollection node,
    String action,
  ) async {
    if (action == 'rename') {
      final name = await _askName(node.name);
      if (name != null) await _notifier.renameCollection(node.id, name);
    } else if (action == 'delete') {
      if (await _confirmDelete(
        context.l10n.blockOrganizer_deleteCollectionConfirm(node.name),
      )) {
        await _notifier.deleteCollection(node.id);
      }
    }
  }

  Future<void> _reorderNode(
    _OrganizerNodeDrag source,
    _OrganizerNodeDrag target,
  ) async {
    if (_busy ||
        source.kind != target.kind ||
        source.parentId != target.parentId ||
        source.id == target.id) {
      return;
    }
    final state = ref.read(promptBlockLibraryNotifierProvider).valueOrNull;
    if (state == null) return;
    final ids = switch (source.kind) {
      _OrganizerNodeKind.folder =>
        state.folders
            .childrenOf(source.parentId)
            .map((item) => item.id)
            .toList(),
      _OrganizerNodeKind.collection =>
        state.collections
            .childrenOf(source.parentId)
            .map((item) => item.id)
            .toList(),
    };
    final from = ids.indexOf(source.id);
    final to = ids.indexOf(target.id);
    if (from < 0 || to < 0) return;
    ids.removeAt(from);
    final targetIndex = ids.indexOf(target.id);
    ids.insert(from < to ? targetIndex + 1 : targetIndex, source.id);
    setState(() => _busy = true);
    try {
      switch (source.kind) {
        case _OrganizerNodeKind.folder:
          await _notifier.reorderFolders(source.parentId, ids);
        case _OrganizerNodeKind.collection:
          await _notifier.reorderCollections(source.parentId, ids);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _updateAutoScroll(Offset globalPosition) {
    final box = _listViewportKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !_listScrollController.hasClients) return;
    final localY = box.globalToLocal(globalPosition).dy;
    const edge = 28.0;
    _autoScrollStep = localY < edge
        ? -6
        : localY > box.size.height - edge
        ? 6
        : 0;
    if (_autoScrollStep == 0) {
      _stopAutoScroll();
    } else {
      _autoScrollTimer ??= Timer.periodic(const Duration(milliseconds: 16), (
        _,
      ) {
        if (!mounted || !_listScrollController.hasClients) {
          _stopAutoScroll();
          return;
        }
        final position = _listScrollController.position;
        _listScrollController.jumpTo(
          (position.pixels + _autoScrollStep).clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          ),
        );
      });
    }
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _autoScrollStep = 0;
  }

  Future<String?> _askName(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.common_rename),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.l10n.common_save),
          ),
        ],
      ),
    );
    controller.dispose();
    return value?.isNotEmpty == true ? value : null;
  }

  Future<bool> _confirmDelete(String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.common_confirmDelete),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.common_cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.common_delete),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overlay = Overlay.of(context).context.findRenderObject();
    final size = overlay is RenderBox
        ? overlay.size
        : MediaQuery.sizeOf(context);
    final anchor = overlay is RenderBox
        ? overlay.globalToLocal(widget.anchor)
        : widget.anchor;
    final width = math.min(326.0, math.max(160.0, size.width - 16));
    final left = anchor.dx.clamp(
      8.0,
      (size.width - width - 8).clamp(8.0, size.width),
    );
    final top = anchor.dy.clamp(
      8.0,
      (size.height - 440).clamp(8.0, size.height),
    );
    final state = ref.watch(promptBlockLibraryNotifierProvider).valueOrNull;
    final title = switch (widget.page) {
      BlockOrganizerPage.favorites =>
        context.l10n.blockOrganizer_titleFavorites,
      BlockOrganizerPage.folders => context.l10n.blockOrganizer_titleFolders,
      BlockOrganizerPage.tags => context.l10n.promptBlockLibrary_addTag,
    };
    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          width: width,
          child: Material(
            key: const Key('prompt-block-organizer-popover'),
            elevation: 12,
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: (size.height - top - 8).clamp(160.0, 440.0),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    child: Row(
                      children: [
                        Icon(
                          switch (widget.page) {
                            BlockOrganizerPage.favorites => Icons.star_outline,
                            BlockOrganizerPage.folders => Icons.folder_outlined,
                            BlockOrganizerPage.tags => Icons.sell_outlined,
                          },
                          size: 19,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          context.l10n.blockOrganizer_itemCount(
                            widget.blockIds.length,
                          ),
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: context.l10n.common_close,
                          icon: const Icon(Icons.close, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 28,
                            height: 28,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _search,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search, size: 18),
                          hintText: context.l10n.blockOrganizer_search,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      key: _listViewportKey,
                      controller: _listScrollController,
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                      child: state == null
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: switch (widget.page) {
                                BlockOrganizerPage.favorites => _favoriteRows(
                                  state,
                                ),
                                BlockOrganizerPage.folders => _folderRows(
                                  state,
                                ),
                                BlockOrganizerPage.tags => _tagRows(state),
                              },
                            ),
                    ),
                  ),
                  if (_creating)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 34,
                              child: TextField(
                                controller: _name,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: context.l10n.blockOrganizer_name,
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onSubmitted: (_) => _saveNew(),
                              ),
                            ),
                          ),
                          if (widget.page == BlockOrganizerPage.tags)
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.circle,
                                color: _tagColor,
                                size: 18,
                              ),
                              onSelected: (value) {
                                if (value == 'custom') {
                                  _customTagColor();
                                } else {
                                  setState(
                                    () => _tagColor = Color(
                                      int.parse(value, radix: 16),
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (_) => [
                                for (final color in [
                                  const Color(0xFF2563EB),
                                  const Color(0xFF0D9488),
                                  const Color(0xFFD97706),
                                  const Color(0xFFDB2777),
                                  const Color(0xFF7C3AED),
                                ])
                                  PopupMenuItem(
                                    value: color.toARGB32().toRadixString(16),
                                    child: Icon(
                                      Icons.circle,
                                      color: color,
                                      size: 18,
                                    ),
                                  ),
                                PopupMenuItem(
                                  value: 'custom',
                                  child: Text(
                                    context.l10n.blockOrganizer_customColor,
                                  ),
                                ),
                              ],
                            ),
                          IconButton(
                            icon: const Icon(Icons.check, size: 18),
                            onPressed: _saveNew,
                          ),
                        ],
                      ),
                    ),
                  Divider(height: 1, color: theme.colorScheme.outlineVariant),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    child: Row(
                      children: [
                        if (widget.page == BlockOrganizerPage.favorites)
                          PopupMenuButton<bool>(
                            tooltip: context.l10n.common_new,
                            onSelected: (isFolder) => setState(() {
                              _creating = true;
                              _creatingCollectionFolder = isFolder;
                            }),
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: false,
                                child: Text(
                                  context.l10n.blockOrganizer_newCollection,
                                ),
                              ),
                              PopupMenuItem(
                                value: true,
                                child: Text(
                                  context
                                      .l10n
                                      .blockOrganizer_newCollectionFolder,
                                ),
                              ),
                            ],
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add, size: 17),
                                  const SizedBox(width: 5),
                                  Text(context.l10n.common_new),
                                ],
                              ),
                            ),
                          )
                        else
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => _creating = !_creating),
                            icon: const Icon(Icons.add, size: 17),
                            label: Text(
                              widget.page == BlockOrganizerPage.tags
                                  ? context.l10n.blockOrganizer_newTag
                                  : context.l10n.blockOrganizer_newFolder,
                            ),
                          ),
                        const Spacer(),
                        if (widget.page != BlockOrganizerPage.tags) ...[
                          TextButton(
                            onPressed:
                                _picked == null ||
                                    _busy ||
                                    (_picked?.kind ==
                                            PromptBlockTransferKind
                                                .collection &&
                                        state
                                                ?.collectionById(
                                                  _picked?.id ?? '',
                                                )
                                                ?.isFolder ==
                                            true)
                                ? null
                                : () => _transfer(PromptBlockTransferMode.copy),
                            child: Text(context.l10n.common_copy),
                          ),
                          FilledButton(
                            onPressed:
                                _picked == null ||
                                    _busy ||
                                    (_picked?.kind ==
                                            PromptBlockTransferKind
                                                .collection &&
                                        state
                                                ?.collectionById(
                                                  _picked?.id ?? '',
                                                )
                                                ?.isFolder ==
                                            true)
                                ? null
                                : () => _transfer(PromptBlockTransferMode.move),
                            child: Text(context.l10n.common_move),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _matches(String name) =>
      name.toLowerCase().contains(_search.text.trim().toLowerCase());

  List<Widget> _favoriteRows(PromptBlockLibraryState state) {
    final allFavorite = widget.blockIds.every(
      (id) => state.blockById(id)?.isFavorite ?? false,
    );
    final rows = <Widget>[
      _row(
        Icons.star_outline,
        context.l10n.promptBlockLibrary_favorites,
        selected: allFavorite,
        onTap: () {
          setState(
            () => _picked = const PromptBlockTransferTarget(
              PromptBlockTransferKind.favorites,
            ),
          );
          _setFavorite(!allFavorite);
        },
      ),
    ];
    void visit(String? parentId, int depth) {
      final siblings = state.collections.childrenOf(parentId);
      final siblingIds = siblings.map((node) => node.id).toList();
      for (final node in siblings) {
        if (!_matches(node.name) && _search.text.isNotEmpty) {
          if (node.isFolder) visit(node.id, depth + 1);
          continue;
        }
        rows.add(
          _reorderTarget(
            target: _OrganizerNodeDrag(
              _OrganizerNodeKind.collection,
              node.id,
              parentId,
            ),
            siblingIds: siblingIds,
            child: _row(
              node.isFolder
                  ? Icons.folder_outlined
                  : Icons.collections_bookmark_outlined,
              node.name,
              indent: depth,
              selected:
                  !node.isFolder &&
                  widget.blockIds.every(node.blockIds.contains),
              onTap: () {
                if (node.isFolder) {
                  setState(() {
                    _picked = PromptBlockTransferTarget(
                      PromptBlockTransferKind.collection,
                      node.id,
                    );
                    _expanded.add(node.id);
                  });
                } else if (widget.dropTarget != null) {
                  setState(
                    () => _picked = PromptBlockTransferTarget(
                      PromptBlockTransferKind.collection,
                      node.id,
                    ),
                  );
                } else {
                  setState(
                    () => _picked = PromptBlockTransferTarget(
                      PromptBlockTransferKind.collection,
                      node.id,
                    ),
                  );
                  _toggleCollection(node);
                }
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (node.isFolder)
                    IconButton(
                      tooltip: _expanded.contains(node.id)
                          ? context.l10n.common_collapse
                          : context.l10n.common_expand,
                      icon: Icon(
                        _expanded.contains(node.id)
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 17,
                      ),
                      onPressed: () => setState(() {
                        if (!_expanded.remove(node.id)) {
                          _expanded.add(node.id);
                        }
                      }),
                    ),
                  _nodeActions(
                    node: _OrganizerNodeDrag(
                      _OrganizerNodeKind.collection,
                      node.id,
                      parentId,
                    ),
                    label: node.name,
                    onRename: () => _manageCollection(node, 'rename'),
                    onDelete: () => _manageCollection(node, 'delete'),
                  ),
                ],
              ),
            ),
          ),
        );
        if (node.isFolder &&
            (_expanded.contains(node.id) || _search.text.isNotEmpty)) {
          visit(node.id, depth + 1);
        }
      }
    }

    visit(null, 0);
    return rows;
  }

  List<Widget> _folderRows(PromptBlockLibraryState state) {
    final rows = <Widget>[
      _row(
        Icons.folder_open_outlined,
        context.l10n.blockOrganizer_rootUncategorized,
        selected:
            _picked?.kind == PromptBlockTransferKind.folder &&
            _picked?.id == null,
        onTap: () => setState(
          () => _picked = const PromptBlockTransferTarget(
            PromptBlockTransferKind.folder,
          ),
        ),
      ),
    ];
    void visit(String? parentId, int depth) {
      final siblings = state.folders.childrenOf(parentId);
      final siblingIds = siblings.map((folder) => folder.id).toList();
      for (final folder in siblings) {
        if (_matches(folder.name) || _search.text.isEmpty) {
          rows.add(
            _reorderTarget(
              target: _OrganizerNodeDrag(
                _OrganizerNodeKind.folder,
                folder.id,
                parentId,
              ),
              siblingIds: siblingIds,
              child: _row(
                Icons.folder_outlined,
                folder.name,
                indent: depth,
                selected: _picked?.id == folder.id,
                onTap: () => setState(() {
                  _picked = PromptBlockTransferTarget(
                    PromptBlockTransferKind.folder,
                    folder.id,
                  );
                  _expanded.add(folder.id);
                }),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.folders.childrenOf(folder.id).isNotEmpty)
                      IconButton(
                        tooltip: _expanded.contains(folder.id)
                            ? context.l10n.common_collapse
                            : context.l10n.common_expand,
                        icon: Icon(
                          _expanded.contains(folder.id)
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 17,
                        ),
                        onPressed: () => setState(() {
                          if (!_expanded.remove(folder.id)) {
                            _expanded.add(folder.id);
                          }
                        }),
                      ),
                    _nodeActions(
                      node: _OrganizerNodeDrag(
                        _OrganizerNodeKind.folder,
                        folder.id,
                        parentId,
                      ),
                      label: folder.name,
                      onRename: () => _manageFolder(folder, 'rename'),
                      onDelete: () => _manageFolder(folder, 'delete'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (_expanded.contains(folder.id) || _search.text.isNotEmpty) {
          visit(folder.id, depth + 1);
        }
      }
    }

    visit(null, 0);
    return rows;
  }

  List<Widget> _tagRows(PromptBlockLibraryState state) {
    final tags = <String, PromptBlockTag>{};
    for (final block in state.blocks) {
      for (final tag in block.tags) {
        tags[tag.name.toLowerCase()] = tag;
      }
    }
    return [
      for (final tag in tags.values)
        if (_matches(tag.name))
          _row(
            Icons.sell_outlined,
            tag.name,
            iconColor: Color(
              int.tryParse(tag.color.replaceFirst('#', ''), radix: 16) ??
                  0xFF2563EB,
            ),
            selected: widget.blockIds.every(
              (id) =>
                  state
                      .blockById(id)
                      ?.tags
                      .any(
                        (item) =>
                            item.name.toLowerCase() == tag.name.toLowerCase(),
                      ) ??
                  false,
            ),
            onTap: () async {
              final all = widget.blockIds.every(
                (id) =>
                    state
                        .blockById(id)
                        ?.tags
                        .any(
                          (item) =>
                              item.name.toLowerCase() == tag.name.toLowerCase(),
                        ) ??
                    false,
              );
              await _applyTag(tag, add: !all);
            },
          ),
    ];
  }

  Widget _nodeActions({
    required _OrganizerNodeDrag node,
    required String label,
    required VoidCallback onRename,
    required VoidCallback onDelete,
  }) => Draggable<_OrganizerNodeDrag>(
    key: ValueKey('organizer-reorder-handle-${node.kind.name}-${node.id}'),
    data: node,
    axis: Axis.vertical,
    rootOverlay: true,
    maxSimultaneousDrags: _busy ? 0 : 1,
    onDragUpdate: (details) => _updateAutoScroll(details.globalPosition),
    onDragEnd: (_) => _stopAutoScroll(),
    feedback: Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 210),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    ),
    childWhenDragging: const SizedBox(
      width: 32,
      height: 32,
      child: Icon(Icons.more_horiz, size: 17),
    ),
    child: PopupMenuButton<String>(
      tooltip: context.l10n.blockOrganizer_manageDrag,
      padding: EdgeInsets.zero,
      onSelected: (value) => value == 'rename' ? onRename() : onDelete(),
      itemBuilder: (_) => [
        PopupMenuItem(value: 'rename', child: Text(context.l10n.common_rename)),
        PopupMenuItem(value: 'delete', child: Text(context.l10n.common_delete)),
      ],
      child: const MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(Icons.more_horiz, size: 17),
        ),
      ),
    ),
  );

  Widget _reorderTarget({
    required _OrganizerNodeDrag target,
    required List<String> siblingIds,
    required Widget child,
  }) => DragTarget<_OrganizerNodeDrag>(
    key: ValueKey('organizer-reorder-target-${target.kind.name}-${target.id}'),
    onWillAcceptWithDetails: (details) =>
        details.data.kind == target.kind &&
        details.data.parentId == target.parentId &&
        details.data.id != target.id,
    onAcceptWithDetails: (details) => _reorderNode(details.data, target),
    builder: (context, candidates, _) {
      final source = candidates.isEmpty ? null : candidates.first;
      final sourceIndex = source == null ? -1 : siblingIds.indexOf(source.id);
      final targetIndex = siblingIds.indexOf(target.id);
      final fromAbove = sourceIndex >= 0 && sourceIndex < targetIndex;
      return Stack(
        children: [
          child,
          if (sourceIndex >= 0)
            Positioned(
              left: 8,
              right: 8,
              top: fromAbove ? null : 0,
              bottom: fromAbove ? 0 : null,
              child: IgnorePointer(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );

  Widget _row(
    IconData icon,
    String label, {
    required VoidCallback onTap,
    bool selected = false,
    int indent = 0,
    Color? iconColor,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.09)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            height: 36,
            child: Row(
              children: [
                SizedBox(width: 9.0 + indent * 15),
                Icon(
                  icon,
                  size: 17,
                  color:
                      iconColor ??
                      (selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check, size: 15, color: theme.colorScheme.primary),
                if (trailing != null) trailing,
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
