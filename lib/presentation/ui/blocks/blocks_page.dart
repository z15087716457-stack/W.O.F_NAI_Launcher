import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_dialog.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'blocks_contract.dart';
import 'blocks_edit.dart';
import 'blocks_inspector.dart';
import 'blocks_nav.dart';
import 'blocks_wall.dart';

/// 页面内共享：数据、回调、页面控制器（多选、菜单、弹窗、卡片大小拖动中的值）。
class BlocksPageScope extends InheritedWidget {
  const BlocksPageScope({
    super.key,
    required this.data,
    required this.actions,
    required this.controller,
    required super.child,
  });

  final BlocksLibraryViewData data;
  final BlocksLibraryActions actions;
  final BlocksLibraryPageState controller;

  static BlocksPageScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BlocksPageScope>()!;

  @override
  bool updateShouldNotify(BlocksPageScope old) => true;
}

/// 拖动中的卡片（一张或多选的一批）。
class BlocksCardDrag {
  const BlocksCardDrag(this.ids);
  final List<String> ids;
}

/// 拖动中的文件夹。
class BlocksFolderDrag {
  const BlocksFolderDrag(this.id);
  final String id;
}

/// 块库管理页（三栏）：左栏 240（范围 / 收藏集 / 文件夹 / 标签）· 卡片墙（工具栏 62 + 快速筛选 46）· 详情 340。
/// 窄了先收详情、再收左栏（卡片墙至少 [minWall]）。
class BlocksLibraryPage extends StatefulWidget {
  const BlocksLibraryPage({
    super.key,
    required this.data,
    required this.actions,
  });

  final BlocksLibraryViewData data;
  final BlocksLibraryActions actions;

  static const sidebarWidth = 240.0;
  static const inspectorWidth = 340.0;
  static const minWall = 520.0;

  @override
  State<BlocksLibraryPage> createState() => BlocksLibraryPageState();
}

enum _Dialog { none, edit, delete }

class BlocksLibraryPageState extends State<BlocksLibraryPage> {
  final _focus = FocusNode(debugLabel: 'blocks-page');
  final searchFocus = FocusNode(debugLabel: 'blocks-search');

  var _picking = false;
  final _picked = <String>{};
  double? _liveSize;
  int wallColumns = 1;

  UiPopoverAnchor? _menuAnchor;
  WidgetBuilder? _pop;

  var _dialog = _Dialog.none;
  String? _editId;
  BlockDraft? _editDraft;
  List<String> _deleteIds = const [];

  BlocksLibraryViewData get _data => widget.data;
  BlocksLibraryActions get _actions => widget.actions;

  bool get picking => _picking;
  Set<String> get picked => _picked;

  /// 拖动卡片大小滑杆时的实时值（松手才回调）。
  double get cardSize => _liveSize ?? _data.cardSize;

  @override
  void didUpdateWidget(covariant BlocksLibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 删掉或筛走的块不留在多选里。
    final ids = {for (final b in _data.blocks) b.id};
    _picked.removeWhere((k) => !ids.contains(k));
  }

  @override
  void dispose() {
    _focus.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  void setPicking(bool v) => setState(() {
    _picking = v;
    _picked.clear();
  });

  void togglePick(String id) => setState(() {
    if (!_picking) _picking = true;
    _picked.contains(id) ? _picked.remove(id) : _picked.add(id);
  });

  void setPicked(Iterable<String> ids) => setState(() {
    _picking = true;
    _picked
      ..clear()
      ..addAll(ids);
  });

  void setLiveSize(double? v) => setState(() => _liveSize = v);

  void openMenu(
    UiPopoverAnchor anchor,
    List<UiMenuItem> items, {
    double width = 210,
  }) => openPanel(
    anchor,
    (_) => UiMenu(items: items, onClose: closeMenu, width: width),
  );

  /// 在 [anchor] 处弹一个自定义浮层（标签改色这类）。
  void openPanel(UiPopoverAnchor anchor, WidgetBuilder builder) => setState(() {
    _menuAnchor = anchor;
    _pop = builder;
  });

  void closeMenu() {
    if (_menuAnchor == null) return;
    setState(() => _menuAnchor = null);
  }

  /// 打开编辑块（[id] 为 null 且没给 [draft] = 新建空块）。
  void openEdit(String? id, {BlockDraft? draft}) => setState(() {
    _editId = id;
    _editDraft =
        draft ??
        (id == null
            ? BlockDraft(folderId: _scopeFolder)
            : BlockDraft.of(_data.blocks.firstWhere((b) => b.id == id)));
    _dialog = _Dialog.edit;
  });

  /// 合并选中的块：内容按选中顺序拼起来，标题“A + B”，颜色取第一个。
  void openMerge(List<String> ids) {
    final blocks = [
      for (final id in ids) ?_data.blocks.where((b) => b.id == id).firstOrNull,
    ];
    if (blocks.isEmpty) return;
    openEdit(
      null,
      draft: BlockDraft(
        title: blocks.map((b) => b.title).take(3).join(' + '),
        atoms: [for (final b in blocks) ...b.atoms],
        negativeAtoms: [for (final b in blocks) ...b.negativeAtoms],
        color: blocks.first.color,
        icon: blocks.first.icon,
        folderId: blocks.first.folderId,
      ),
    );
  }

  void confirmDelete(List<String> ids) => setState(() {
    _deleteIds = ids;
    _dialog = _Dialog.delete;
  });

  void _closeDialog() {
    setState(() => _dialog = _Dialog.none);
    _focus.requestFocus();
  }

  String? get _scopeFolder =>
      _data.scope.kind == BlocksScopeKind.folder ? _data.scope.id : null;

  bool _typing() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    return ctx != null &&
        (ctx.widget is EditableText ||
            ctx.findAncestorWidgetOfExactType<EditableText>() != null);
  }

  List<String> get targets => _picking ? _picked.toList() : [?_data.selectedId];

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final k = e.logicalKey;
    final hw = HardwareKeyboard.instance;
    final ctrl = hw.isControlPressed || hw.isMetaPressed;
    if (ctrl && k == LogicalKeyboardKey.keyF) {
      searchFocus.requestFocus();
      return KeyEventResult.handled;
    }
    if (_typing() || _dialog != _Dialog.none) return KeyEventResult.ignored;
    if (k == LogicalKeyboardKey.slash && !ctrl) {
      searchFocus.requestFocus();
      return KeyEventResult.handled;
    }
    if (ctrl && k == LogicalKeyboardKey.keyN) {
      openEdit(null);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.escape && _picking) {
      setPicking(false);
      return KeyEventResult.handled;
    }
    final items = _data.blocks;
    if (items.isEmpty) return KeyEventResult.ignored;
    if (ctrl && k == LogicalKeyboardKey.keyA) {
      setPicked(items.map((b) => b.id));
      return KeyEventResult.handled;
    }
    final cols = _data.view == BlocksView.list ? 1 : wallColumns;
    final dir = switch (k) {
      LogicalKeyboardKey.arrowLeft => -1,
      LogicalKeyboardKey.arrowRight => 1,
      LogicalKeyboardKey.arrowUp => -cols,
      LogicalKeyboardKey.arrowDown => cols,
      _ => 0,
    };
    if (dir != 0) {
      final i = items.indexWhere((b) => b.id == _data.selectedId);
      final next = i < 0 ? 0 : (i + dir).clamp(0, items.length - 1);
      _actions.onSelect(items[next].id);
      return KeyEventResult.handled;
    }
    final t = targets;
    if (t.isEmpty) return KeyEventResult.ignored;
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      _actions.onInsert(t);
    } else if (k == LogicalKeyboardKey.keyE && !ctrl && !_picking) {
      openEdit(t.first);
    } else if (k == LogicalKeyboardKey.keyF && !ctrl) {
      final all = t.every((id) => items.firstWhere((b) => b.id == id).favorite);
      _actions.onSetFavorite(t, !all);
    } else if (ctrl && k == LogicalKeyboardKey.keyD && !_picking) {
      _actions.onDuplicate(t.first);
    } else if (k == LogicalKeyboardKey.delete) {
      confirmDelete(t);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  WidgetBuilder? get _dialogBuilder => switch (_dialog) {
    _Dialog.none => null,
    _Dialog.edit => (_) => BlockEditDialog(
      key: ValueKey('edit-${_editId ?? 'new'}'),
      data: BlockEditData(
        draft: _editDraft!,
        blockId: _editId,
        folders: _data.folders,
        tags: [for (final t in _data.tags) t.tag],
        catalog: _data.catalog,
        folderName: _data.folders
            .where((f) => f.id == _editDraft!.folderId)
            .firstOrNull
            ?.name,
        sourcePath: _block(_editId)?.sourcePath,
        importedAt: _block(_editId)?.importedAt,
        sourceState: _block(_editId)?.sourceState ?? BlockSourceState.none,
      ),
      actions: BlockEditActions(
        onSave: (draft) {
          final id = _editId;
          _closeDialog();
          id == null ? _actions.onCreate(draft) : _actions.onSave(id, draft);
        },
        onCancel: _closeDialog,
        onPickThumbnail: _actions.onPickThumbnail,
        onCaptureParams: _actions.onCaptureParams,
        onDelete: _editId == null
            ? null
            : () {
                final id = _editId!;
                _closeDialog();
                _actions.onDelete([id]);
              },
      ),
    ),
    _Dialog.delete => (_) => BlocksDeleteDialog(
      blocks: [for (final id in _deleteIds) ?_block(id)],
      onCancel: _closeDialog,
      onConfirm: () {
        final ids = _deleteIds;
        _closeDialog();
        _actions.onDelete(ids);
        if (_picking) setPicking(false);
      },
    ),
  };

  BlockData? _block(String? id) =>
      id == null ? null : _data.blocks.where((b) => b.id == id).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final data = _data;
    return BlocksPageScope(
      data: data,
      actions: _actions,
      controller: this,
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: UiModal(
          dialog: _dialogBuilder,
          barrierDismissible: _dialog != _Dialog.edit,
          onDismiss: _closeDialog,
          child: UiPopover(
            anchor: _menuAnchor,
            onDismiss: closeMenu,
            builder: (ctx) => _pop?.call(ctx) ?? const SizedBox.shrink(),
            child: ColoredBox(
              color: c.bg,
              child: LayoutBuilder(
                builder: (context, box) {
                  final w = box.maxWidth;
                  var sidebar = data.sidebarOpen;
                  var inspector = data.inspectorOpen && !data.libraryEmpty;
                  if (inspector &&
                      w -
                              (sidebar ? BlocksLibraryPage.sidebarWidth : 0) -
                              BlocksLibraryPage.inspectorWidth <
                          BlocksLibraryPage.minWall) {
                    inspector = false;
                  }
                  if (sidebar &&
                      w - BlocksLibraryPage.sidebarWidth <
                          BlocksLibraryPage.minWall) {
                    sidebar = false;
                  }
                  return Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (_) {
                      if (!_typing()) _focus.requestFocus();
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (sidebar) const BlocksNav(),
                        Expanded(
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    BlocksToolbar(
                                      inspectorShown: inspector,
                                      sidebarShown: sidebar,
                                    ),
                                    if (data.libraryEmpty)
                                      const Expanded(child: BlocksEmpty())
                                    else ...[
                                      const BlocksFilterRow(),
                                      const Expanded(child: BlocksWall()),
                                    ],
                                  ],
                                ),
                              ),
                              if (_picking && _picked.isNotEmpty)
                                const Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 20,
                                  child: Center(child: BlocksSelectionBar()),
                                ),
                            ],
                          ),
                        ),
                        if (inspector) const BlocksInspector(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 删除确认：一个块写名字，多个写数量；提醒提示词里的实例会变成“块已删除”。
class BlocksDeleteDialog extends StatelessWidget {
  const BlocksDeleteDialog({
    super.key,
    required this.blocks,
    required this.onCancel,
    required this.onConfirm,
  });
  final List<BlockData> blocks;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    return SizedBox(
      key: const Key('blocks-delete'),
      width: 420,
      child: UiPopoverSurface(
        radius: 14,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.error.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: UiGlyph(UiGlyphs.trash, size: 16, color: c.error),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 6,
                      children: [
                        Text(
                          blocks.length == 1
                              ? l10n.blocks_deleteOne(blocks.first.title)
                              : l10n.blocks_deleteMany(blocks.length),
                          style: UiText.sans(
                            15,
                            weight: FontWeight.w700,
                            color: c.ink,
                          ),
                        ),
                        Text(
                          l10n.blocks_deleteBody,
                          style: UiText.sans(12.5, color: c.muted, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            UiDialogFooter(
              children: [
                const Spacer(),
                UiBtn(
                  key: const Key('blocks-delete-cancel'),
                  onTap: onCancel,
                  children: [Text(l10n.blocks_cancel)],
                ),
                UiBtn(
                  key: const Key('blocks-delete-confirm'),
                  tone: UiBtnTone.primary,
                  onTap: onConfirm,
                  children: [Text(l10n.blocks_delete)],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 卡片 / 行的右键菜单（卡片墙、列表、详情栏“…”共用）。
List<UiMenuItem> blocksCardMenu(BuildContext context, BlockData b) {
  final l10n = context.l10n;
  final scope = BlocksPageScope.of(context);
  final a = scope.actions;
  final ctrl = scope.controller;
  final data = scope.data;
  final inCollection = data.scope.kind == BlocksScopeKind.collection;
  return [
    UiMenuItem(
      glyph: UiGlyphs.plus,
      label: l10n.blocks_insertToPrompt,
      trailing: 'Enter',
      onTap: () => a.onInsert([b.id]),
    ),
    UiMenuItem(
      glyph: UiGlyphs.pencil,
      label: l10n.blocks_edit,
      trailing: 'E',
      onTap: () => ctrl.openEdit(b.id),
    ),
    UiMenuItem(
      glyph: UiGlyphs.star,
      label: b.favorite ? l10n.blocks_unfavorite : l10n.blocks_favorite,
      trailing: 'F',
      onTap: () => a.onSetFavorite([b.id], !b.favorite),
    ),
    UiMenuItem(
      glyph: UiGlyphs.layers,
      label: l10n.blocks_duplicate,
      trailing: 'Ctrl D',
      onTap: () => a.onDuplicate(b.id),
    ),
    UiMenuItem(
      glyph: UiGlyphs.copy,
      label: l10n.blocks_copyContent,
      onTap: () => a.onCopyText(b.id),
    ),
    UiMenuItem(
      glyph: UiGlyphs.box,
      label: l10n.blocks_addToPalette,
      enabled: !data.paletteIds.contains(b.id),
      onTap: () => a.onAddToPalette([b.id]),
    ),
    if (b.hasParams)
      UiMenuItem(
        glyph: UiGlyphs.bolt,
        label: l10n.blocks_applyParams,
        enabled: b.params!.incompatible == null,
        onTap: () => a.onApplyParams(b.id),
      ),
    UiMenuItem(
      glyph: UiGlyphs.check,
      label: l10n.blocks_multiSelect,
      divider: true,
      onTap: () => ctrl.togglePick(b.id),
    ),
    UiMenuItem(
      glyph: UiGlyphs.upload,
      label: l10n.blocks_exportTxt,
      onTap: () => a.onExport([b.id]),
    ),
    if (inCollection)
      UiMenuItem(
        glyph: UiGlyphs.minus,
        label: l10n.blocks_removeFromCollection,
        onTap: () => a.onRemoveFromCollection([b.id], data.scope.id!),
      ),
    UiMenuItem(
      glyph: UiGlyphs.trash,
      label: l10n.blocks_delete,
      trailing: 'Del',
      danger: true,
      divider: true,
      onTap: () => ctrl.confirmDelete([b.id]),
    ),
  ];
}

/// “移到…”菜单：根目录 + 整棵文件夹树（缩进）。
List<UiMenuItem> blocksMoveMenu(
  BuildContext context,
  List<String> ids, {
  BlocksDropMode mode = BlocksDropMode.move,
}) {
  final l10n = context.l10n;
  final scope = BlocksPageScope.of(context);
  final a = scope.actions;
  final current = ids.length == 1
      ? scope.data.blocks.where((b) => b.id == ids.first).firstOrNull?.folderId
      : '\u0000';
  return [
    UiMenuItem(
      glyph: UiGlyphs.minus,
      label: l10n.blocks_uncategorized,
      checked: current == null,
      onTap: () => a.onDropToFolder(ids, null, mode),
    ),
    for (final f in scope.data.folders)
      UiMenuItem(
        glyph: UiGlyphs.folder,
        label: f.name,
        indent: f.depth * 16.0,
        checked: current == f.id,
        onTap: () => a.onDropToFolder(ids, f.id, mode),
      ),
  ];
}

/// 范围标题（工具栏左侧）：全部块 / 最近使用 / 收藏 / 某个收藏集 / 文件夹 / 标签。
String blocksScopeTitle(BuildContext context, BlocksLibraryViewData d) {
  final l10n = context.l10n;
  final s = d.scope;
  return switch (s.kind) {
    BlocksScopeKind.all => l10n.blocks_allBlocks,
    BlocksScopeKind.recent => l10n.blocks_recent,
    BlocksScopeKind.favorites => l10n.blocks_favorites,
    BlocksScopeKind.uncategorized => l10n.blocks_uncategorized,
    BlocksScopeKind.collection =>
      d.collections.where((x) => x.id == s.id).firstOrNull?.name ?? '',
    BlocksScopeKind.folder =>
      d.folders.where((x) => x.id == s.id).firstOrNull?.name ?? '',
    BlocksScopeKind.tag => '#${s.id}',
  };
}
