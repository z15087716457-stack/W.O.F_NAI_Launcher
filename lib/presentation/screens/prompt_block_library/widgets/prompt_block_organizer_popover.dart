import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/prompt_block/prompt_block.dart';
import '../../../../data/models/prompt_block/prompt_block_collection.dart';
import '../../../../data/models/prompt_block/prompt_block_folder.dart';
import '../../../../data/repositories/prompt_block_repository.dart';
import '../../../providers/prompt_block_library_provider.dart';

enum BlockOrganizerPage { favorites, folders, tags }

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
  barrierLabel: '块分类',
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
  final Set<String> _expanded = {};
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
    _search.dispose();
    _name.dispose();
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
          title: const Text('替换同源块？'),
          content: Text('目标中已有 $conflicts 个同源副本。替换会更新目标副本的内容；其他块不受影响。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('替换'),
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
        title: const Text('自定义标签颜色'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '#RRGGBB 或 #AARRGGBB'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || !mounted) return;
    final hex = value.replaceFirst('#', '');
    if (!RegExp(r'^(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').hasMatch(hex)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入六位或八位十六进制颜色')));
      return;
    }
    setState(
      () => _tagColor = Color(
        int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16),
      ),
    );
  }

  Future<void> _manageFolder(
    PromptBlockFolder folder,
    String action,
    PromptBlockLibraryState state,
  ) async {
    final siblings = state.folders.childrenOf(folder.parentId);
    if (action == 'rename') {
      final name = await _askName(folder.name);
      if (name != null) {
        await _notifier.updateFolder(folder.copyWith(name: name));
      }
    } else if (action == 'delete') {
      if (await _confirmDelete('删除「${folder.name}」？其中的块会移至根目录。')) {
        await _notifier.deleteFolder(
          folder.id,
          mode: PromptBlockFolderDeleteMode.moveContentsToRoot,
        );
      }
    } else {
      final ids = siblings.map((item) => item.id).toList();
      final index = ids.indexOf(folder.id);
      final next = action == 'up' ? index - 1 : index + 1;
      if (next < 0 || next >= ids.length) return;
      final id = ids.removeAt(index);
      ids.insert(next, id);
      await _notifier.reorderFolders(folder.parentId, ids);
    }
  }

  Future<void> _manageCollection(
    PromptBlockCollection node,
    String action,
    PromptBlockLibraryState state,
  ) async {
    final siblings = state.collections.childrenOf(node.parentId);
    if (action == 'rename') {
      final name = await _askName(node.name);
      if (name != null) await _notifier.renameCollection(node.id, name);
    } else if (action == 'delete') {
      if (await _confirmDelete('删除「${node.name}」？块本体会保留。')) {
        await _notifier.deleteCollection(node.id);
      }
    } else {
      final ids = siblings.map((item) => item.id).toList();
      final index = ids.indexOf(node.id);
      final next = action == 'up' ? index - 1 : index + 1;
      if (next < 0 || next >= ids.length) return;
      final id = ids.removeAt(index);
      ids.insert(next, id);
      await _notifier.reorderCollections(node.parentId, ids);
    }
  }

  Future<String?> _askName(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名'),
        content: TextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('保存'),
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
          title: const Text('确认删除'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除'),
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
      BlockOrganizerPage.favorites => '收藏与收藏集',
      BlockOrganizerPage.folders => '选择文件夹',
      BlockOrganizerPage.tags => '添加标签',
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
                    padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
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
                          '${widget.blockIds.length} 项',
                          style: theme.textTheme.labelSmall,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
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
                          hintText: '搜索',
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
                                  hintText: '名称',
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
                                const PopupMenuItem(
                                  value: 'custom',
                                  child: Text('自定义颜色…'),
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
                            tooltip: '新建',
                            onSelected: (isFolder) => setState(() {
                              _creating = true;
                              _creatingCollectionFolder = isFolder;
                            }),
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: false, child: Text('新建收藏集')),
                              PopupMenuItem(
                                value: true,
                                child: Text('新建收藏文件夹'),
                              ),
                            ],
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add, size: 17),
                                  SizedBox(width: 5),
                                  Text('新建'),
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
                                  ? '新标签'
                                  : '新建文件夹',
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
                            child: const Text('复制'),
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
                            child: const Text('移动'),
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
        '收藏',
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
      for (final node in state.collections.childrenOf(parentId)) {
        if (!_matches(node.name) && _search.text.isNotEmpty) {
          if (node.isFolder) visit(node.id, depth + 1);
          continue;
        }
        rows.add(
          _row(
            node.isFolder
                ? Icons.folder_outlined
                : Icons.collections_bookmark_outlined,
            node.name,
            indent: depth,
            selected:
                !node.isFolder && widget.blockIds.every(node.blockIds.contains),
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
                    tooltip: _expanded.contains(node.id) ? '收起' : '展开',
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
                  () => _manageCollection(node, 'rename', state),
                  (action) => _manageCollection(node, action, state),
                ),
              ],
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
        '根目录 / 未分类',
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
      for (final folder in state.folders.childrenOf(parentId)) {
        if (_matches(folder.name) || _search.text.isEmpty) {
          rows.add(
            _row(
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
                      tooltip: _expanded.contains(folder.id) ? '收起' : '展开',
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
                    () => _manageFolder(folder, 'rename', state),
                    (action) => _manageFolder(folder, action, state),
                  ),
                ],
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

  Widget _nodeActions(VoidCallback rename, ValueChanged<String> action) =>
      PopupMenuButton<String>(
        tooltip: '管理',
        icon: const Icon(Icons.more_horiz, size: 17),
        padding: EdgeInsets.zero,
        onSelected: (value) => value == 'rename' ? rename() : action(value),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'rename', child: Text('重命名')),
          PopupMenuItem(value: 'up', child: Text('上移')),
          PopupMenuItem(value: 'down', child: Text('下移')),
          PopupMenuItem(value: 'delete', child: Text('删除')),
        ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
