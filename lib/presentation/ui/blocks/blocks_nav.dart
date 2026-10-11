import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/studio_icons.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_inputs.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_lib_nav.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'blocks_contract.dart';
import 'blocks_parts.dart';
import 'blocks_page.dart';

/// 左栏 240：标题 52 · 全部 / 最近使用 / 收藏 · 收藏集 · 文件夹（未分类 + 树）· 标签 · 底部“导入 / 导出”44。
/// 卡片可以拖到收藏集和文件夹上（松手选移动还是复制），文件夹可以拖进别的文件夹。
class BlocksNav extends StatefulWidget {
  const BlocksNav({super.key});

  @override
  State<BlocksNav> createState() => _BlocksNavState();
}

class _BlocksNavState extends State<BlocksNav> {
  /// 正在内联输入的那一行：`folder:<id>` 重命名、`new-folder:<parentId>` 新建、
  /// `collection:<id>` / `new-collection` 同理、`tag:<name>` 改标签名。
  String? _editing;

  void _edit(String? v) => setState(() => _editing = v);

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = BlocksPageScope.of(context);
    final d = scope.data;
    final a = scope.actions;
    final ctrl = scope.controller;
    final empty = d.libraryEmpty;

    Widget view(
      BlocksScope s,
      String glyph,
      String label,
      int count, {
      Color? glyphColor,
      bool filled = false,
    }) => UiNavItem(
      key: Key('blocks-scope-${s.kind.name}'),
      leading: UiGlyph(
        glyph,
        size: 15,
        filled: filled,
        color: glyphColor ?? c.muted,
      ),
      label: label,
      selected: d.scope == s,
      trailing: UiNavCount(empty ? null : count),
      onTap: () => a.onScopeChanged(s),
    );

    Widget input(
      String value,
      String hint,
      ValueChanged<String> onDone, {
      double indent = 0,
    }) => Padding(
      padding: EdgeInsets.fromLTRB(8 + indent, 1, 8, 1),
      child: UiTextInput(
        key: const Key('blocks-nav-input'),
        value: value,
        hint: hint,
        height: 30,
        autofocus: true,
        selectAll: true,
        onSubmitted: (v) {
          if (_editing == null) return;
          _edit(null);
          final t = v.trim();
          if (t.isNotEmpty && t != value) onDone(t);
        },
      ),
    );

    // 拖卡片到目标上：弹一个小菜单选“移动 / 复制”（收藏集是“加入 / 移过去”）。
    void dropCards(
      List<String> ids,
      Offset at, {
      String? folderId,
      bool root = false,
      BlocksCollection? collection,
    }) {
      final name =
          collection?.name ??
          (root
              ? l10n.blocks_uncategorized
              : d.folders.firstWhere((f) => f.id == folderId).name);
      final fromCollection = d.scope.kind == BlocksScopeKind.collection;
      ctrl.openMenu(UiPopoverAnchor(at), width: 230, [
        if (collection != null) ...[
          UiMenuItem(
            key: const Key('blocks-drop-copy'),
            glyph: UiGlyphs.plus,
            label: l10n.blocks_dropAddTo(name),
            onTap: () =>
                a.onDropToCollection(ids, collection.id, BlocksDropMode.copy),
          ),
          if (fromCollection && d.scope.id != collection.id)
            UiMenuItem(
              key: const Key('blocks-drop-move'),
              glyph: UiGlyphs.arrowRight,
              label: l10n.blocks_dropMoveTo(name),
              onTap: () =>
                  a.onDropToCollection(ids, collection.id, BlocksDropMode.move),
            ),
        ] else ...[
          UiMenuItem(
            key: const Key('blocks-drop-move'),
            glyph: UiGlyphs.arrowRight,
            label: l10n.blocks_dropMoveTo(name),
            onTap: () => a.onDropToFolder(ids, folderId, BlocksDropMode.move),
          ),
          UiMenuItem(
            key: const Key('blocks-drop-copy'),
            glyph: UiGlyphs.layers,
            label: l10n.blocks_dropCopyTo(name),
            onTap: () => a.onDropToFolder(ids, folderId, BlocksDropMode.copy),
          ),
        ],
      ]);
    }

    Widget cardTarget({
      required Widget Function(bool hover) builder,
      required void Function(List<String>, Offset) onDrop,
    }) => DragTarget<BlocksCardDrag>(
      onAcceptWithDetails: (e) =>
          onDrop(e.data.ids, e.offset + const Offset(24, 12)),
      builder: (context, cand, _) => builder(cand.isNotEmpty),
    );

    List<UiMenuItem> folderMenu(BlocksFolder f) => [
      UiMenuItem(
        glyph: UiGlyphs.folderPlus,
        label: l10n.blocks_newSubfolder,
        onTap: () => _edit('new-folder:${f.id}'),
      ),
      UiMenuItem(
        glyph: UiGlyphs.pencil,
        label: l10n.blocks_rename,
        onTap: () => _edit('folder:${f.id}'),
      ),
      UiMenuItem(
        glyph: UiGlyphs.chevronUp,
        label: l10n.blocks_moveUp,
        divider: true,
        onTap: () => a.onReorderFolder(f.id, -1),
      ),
      UiMenuItem(
        glyph: UiGlyphs.chevronDown,
        label: l10n.blocks_moveDown,
        onTap: () => a.onReorderFolder(f.id, 1),
      ),
      if (f.parentId != null)
        UiMenuItem(
          glyph: UiGlyphs.doubleLeft,
          label: l10n.blocks_moveToTop,
          onTap: () => a.onMoveFolder(f.id, null),
        ),
      UiMenuItem(
        glyph: UiGlyphs.trash,
        label: l10n.blocks_deleteFolder,
        danger: true,
        divider: true,
        onTap: () => a.onDeleteFolder(f.id),
      ),
    ];

    // 收起的父文件夹下面的子文件夹不显示。
    final visible = <BlocksFolder>[];
    final hidden = <String>{};
    for (final f in d.folders) {
      if (f.parentId != null && hidden.contains(f.parentId)) {
        hidden.add(f.id);
        continue;
      }
      visible.add(f);
      if (f.hasChildren && !f.expanded) hidden.add(f.id);
    }

    Widget folderRow(BlocksFolder f) {
      if (_editing == 'folder:${f.id}') {
        return input(
          f.name,
          l10n.blocks_folderName,
          (v) => a.onRenameFolder(f.id, v),
          indent: f.depth * 16.0,
        );
      }
      final row = DragTarget<BlocksFolderDrag>(
        onWillAcceptWithDetails: (e) => e.data.id != f.id,
        onAcceptWithDetails: (e) => a.onMoveFolder(e.data.id, f.id),
        builder: (context, folderCand, _) => cardTarget(
          onDrop: (ids, at) => dropCards(ids, at, folderId: f.id),
          builder: (hover) => UiNavItem(
            key: Key('blocks-folder-${f.id}'),
            indent: f.depth * 16.0,
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  child: f.hasChildren
                      ? UiPressable(
                          key: Key('blocks-folder-toggle-${f.id}'),
                          onTap: () => a.onToggleFolder(f.id, !f.expanded),
                          builder: (_, h) => UiGlyph(
                            f.expanded
                                ? UiGlyphs.chevronDown
                                : UiGlyphs.chevronRight,
                            size: 12,
                            color: h ? c.ink : c.faint,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 2),
                UiGlyph(
                  UiGlyphs.folder,
                  size: 15,
                  color: hover || folderCand.isNotEmpty ? c.accent : c.muted,
                ),
              ],
            ),
            label: f.name,
            selected: d.scope == BlocksScope.folder(f.id),
            drop: hover || folderCand.isNotEmpty,
            trailing: UiNavCount(f.count),
            onTap: () => a.onScopeChanged(BlocksScope.folder(f.id)),
            onSecondaryTap: (at) =>
                ctrl.openMenu(UiPopoverAnchor(at), folderMenu(f)),
          ),
        ),
      );
      return Draggable<BlocksFolderDrag>(
        data: BlocksFolderDrag(f.id),
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Material(
          type: MaterialType.transparency,
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: c.raised,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: c.line),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                UiGlyph(UiGlyphs.folder, size: 14, color: c.muted),
                Text(f.name, style: UiText.sans(12.5, color: c.ink)),
              ],
            ),
          ),
        ),
        child: row,
      );
    }

    Widget sectionTitle(
      String text, {
      String? addKey,
      String? addTip,
      VoidCallback? onAdd,
    }) => UiSectionTitle(
      children: [
        Text(text),
        const Spacer(),
        if (onAdd != null)
          UiIconBox(
            key: addKey == null ? null : Key(addKey),
            glyph: UiGlyphs.plus,
            size: 22,
            glyphSize: 13,
            tooltip: addTip,
            onTap: onAdd,
          ),
      ],
    );

    final newFolderParent =
        _editing != null && _editing!.startsWith('new-folder:')
        ? _editing!.substring(11)
        : null;

    final body = <Widget>[
      view(
        const BlocksScope.all(),
        UiGlyphs.grid,
        l10n.blocks_allBlocks,
        d.counts.all,
      ),
      view(
        const BlocksScope.recent(),
        UiGlyphs.clock,
        l10n.blocks_recent,
        d.counts.recent,
      ),
      view(
        const BlocksScope.favorites(),
        UiGlyphs.star,
        l10n.blocks_favorites,
        d.counts.favorites,
      ),
      sectionTitle(
        l10n.blocks_collections,
        addKey: 'blocks-new-collection',
        addTip: l10n.blocks_newCollection,
        onAdd: empty ? null : () => _edit('new-collection'),
      ),
      for (final k in d.collections)
        if (_editing == 'collection:${k.id}')
          input(
            k.name,
            l10n.blocks_collectionName,
            (v) => a.onRenameCollection(k.id, v),
            indent: k.depth * 16.0,
          )
        else
          cardTarget(
            onDrop: (ids, at) =>
                k.isFolder ? null : dropCards(ids, at, collection: k),
            builder: (hover) => UiNavItem(
              key: Key('blocks-collection-${k.id}'),
              indent: k.depth * 16.0,
              glyph: k.isFolder ? UiGlyphs.folder : UiGlyphs.layers,
              label: k.name,
              selected: d.scope == BlocksScope.collection(k.id),
              drop: hover && !k.isFolder,
              trailing: UiNavCount(k.count),
              onTap: () => a.onScopeChanged(BlocksScope.collection(k.id)),
              onSecondaryTap: (at) => ctrl.openMenu(UiPopoverAnchor(at), [
                if (k.isFolder)
                  UiMenuItem(
                    glyph: UiGlyphs.plus,
                    label: l10n.blocks_newCollection,
                    onTap: () async {
                      await a.onCreateCollection(
                        l10n.blocks_newCollection,
                        parentId: k.id,
                      );
                    },
                  ),
                UiMenuItem(
                  glyph: UiGlyphs.pencil,
                  label: l10n.blocks_rename,
                  onTap: () => _edit('collection:${k.id}'),
                ),
                UiMenuItem(
                  glyph: UiGlyphs.trash,
                  label: l10n.blocks_deleteCollection,
                  danger: true,
                  divider: true,
                  onTap: () => a.onDeleteCollection(k.id),
                ),
              ]),
            ),
          ),
      if (_editing == 'new-collection')
        input('', l10n.blocks_collectionName, (v) => a.onCreateCollection(v)),
      if (d.collections.isEmpty && _editing != 'new-collection')
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 16, 4),
          child: Text(
            l10n.blocks_noCollections,
            style: UiText.sans(11.5, color: c.faint, height: 1.5),
          ),
        ),
      sectionTitle(
        l10n.blocks_folders,
        addKey: 'blocks-new-folder',
        addTip: l10n.blocks_newFolder,
        onAdd: () => _edit('new-folder:'),
      ),
      cardTarget(
        onDrop: (ids, at) => dropCards(ids, at, root: true),
        builder: (hover) => UiNavItem(
          key: const Key('blocks-scope-uncategorized'),
          leading: SizedBox(
            width: 31,
            child: Align(
              alignment: Alignment.centerRight,
              child: UiGlyph(
                UiGlyphs.minus,
                size: 15,
                color: hover ? c.accent : c.muted,
              ),
            ),
          ),
          label: l10n.blocks_uncategorized,
          selected: d.scope == const BlocksScope.uncategorized(),
          drop: hover,
          trailing: UiNavCount(empty ? null : d.counts.uncategorized),
          onTap: () => a.onScopeChanged(const BlocksScope.uncategorized()),
        ),
      ),
      for (final f in visible) ...[
        folderRow(f),
        if (newFolderParent == f.id)
          input(
            '',
            l10n.blocks_folderName,
            (v) => a.onCreateFolder(v, parentId: f.id),
            indent: (f.depth + 1) * 16.0,
          ),
      ],
      if (newFolderParent == '')
        input('', l10n.blocks_folderName, (v) => a.onCreateFolder(v)),
      if (d.tags.isNotEmpty) ...[
        sectionTitle(l10n.blocks_tags),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 16, 8),
          child: Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final t in d.tags)
                if (_editing == 'tag:${t.tag.name}')
                  SizedBox(
                    width: 120,
                    child: input(
                      t.tag.name,
                      l10n.blocks_tagName,
                      (v) => a.onRenameTag(t.tag.name, v),
                    ),
                  )
                else
                  GestureDetector(
                    key: Key('blocks-tag-${t.tag.name}'),
                    onSecondaryTapUp: (e) => ctrl.openMenu(
                      UiPopoverAnchor(e.globalPosition),
                      width: 236,
                      [
                        UiMenuItem(
                          glyph: UiGlyphs.pencil,
                          label: l10n.blocks_rename,
                          onTap: () => _edit('tag:${t.tag.name}'),
                        ),
                        UiMenuItem(
                          glyph: UiGlyphs.palette,
                          label: l10n.blocks_tagColor,
                          onTap: () => ctrl.openPanel(
                            UiPopoverAnchor(e.globalPosition),
                            (_) => BlocksTagColorPanel(
                              selected: t.tag.color,
                              onPick: (col) {
                                ctrl.closeMenu();
                                a.onSetTagColor(t.tag.name, col);
                              },
                            ),
                          ),
                        ),
                        UiMenuItem(
                          glyph: UiGlyphs.trash,
                          label: l10n.blocks_deleteTag,
                          danger: true,
                          divider: true,
                          onTap: () => a.onDeleteTag(t.tag.name),
                        ),
                      ],
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: d.scope == BlocksScope.tag(t.tag.name)
                            ? [BoxShadow(color: t.tag.color, spreadRadius: 1.5)]
                            : null,
                      ),
                      child: BlockTagChip(
                        t.tag,
                        onTap: () =>
                            a.onScopeChanged(BlocksScope.tag(t.tag.name)),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 8),
    ];

    return Container(
      key: const Key('blocks-nav'),
      width: BlocksLibraryPage.sidebarWidth,
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(right: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Row(
                spacing: 8,
                children: [
                  Icon(StudioIcons.promptBlocks, size: 18, color: c.accent),
                  Text(
                    l10n.blocks_title,
                    style: UiText.sans(
                      14,
                      weight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                  const Spacer(),
                  UiIconBox(
                    key: const Key('blocks-collapse-nav'),
                    glyph: UiGlyphs.doubleLeft,
                    tooltip: l10n.blocks_collapseSidebar,
                    onTap: () => a.onSidebarChanged(false),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 1,
                children: body,
              ),
            ),
          ),
          Builder(
            builder: (ctx) => UiPressable(
              key: const Key('blocks-io'),
              onTap: () {
                final box = ctx.findRenderObject()! as RenderBox;
                ctrl.openMenu(
                  UiPopoverAnchor(
                    box.localToGlobal(box.size.topRight(const Offset(-8, -6))),
                    alignBottom: true,
                    alignRight: true,
                  ),
                  width: 220,
                  [
                    UiMenuItem(
                      glyph: UiGlyphs.file,
                      label: l10n.blocks_importTxt,
                      onTap: a.onImportTxt,
                    ),
                    UiMenuItem(
                      glyph: UiGlyphs.folder,
                      label: l10n.blocks_importFolder,
                      onTap: a.onImportFolder,
                    ),
                    UiMenuItem(
                      glyph: UiGlyphs.sort,
                      label: l10n.blocks_importCuration,
                      onTap: a.onImportCuration,
                    ),
                    UiMenuItem(
                      glyph: UiGlyphs.upload,
                      label: l10n.blocks_exportBackup,
                      divider: true,
                      onTap: a.onExportBackup,
                    ),
                    UiMenuItem(
                      glyph: UiGlyphs.download,
                      label: l10n.blocks_importBackup,
                      onTap: a.onImportBackup,
                    ),
                  ],
                );
              },
              builder: (context, hover) => Container(
                height: 44,
                padding: const EdgeInsets.only(left: 18, right: 12),
                decoration: BoxDecoration(
                  color: hover ? c.hover : null,
                  border: Border(top: BorderSide(color: c.line)),
                ),
                child: Row(
                  spacing: 8,
                  children: [
                    UiGlyph(UiGlyphs.upload, size: 15, color: c.muted),
                    Expanded(
                      child: Text(
                        l10n.blocks_importExport,
                        style: UiText.sans(12.5, color: c.muted),
                      ),
                    ),
                    UiGlyph(UiGlyphs.chevronRight, size: 14, color: c.faint),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 标签可选色（与旧标签对话框同一组）。
const blocksTagPalette = <Color>[
  Color(0xFF2563EB),
  Color(0xFF16A34A),
  Color(0xFFDC2626),
  Color(0xFF9333EA),
  Color(0xFFEA580C),
  Color(0xFF0891B2),
  Color(0xFFDB2777),
  Color(0xFF64748B),
];

/// 标签改色浮层：一行 8 个 20px 圆点，当前色带环。
class BlocksTagColorPanel extends StatelessWidget {
  const BlocksTagColorPanel({
    super.key,
    required this.selected,
    required this.onPick,
  });
  final Color selected;
  final ValueChanged<Color> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPopoverSurface(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          for (final (i, col) in blocksTagPalette.indexed)
            UiPressable(
              key: Key('blocks-tag-color-$i'),
              onTap: () => onPick(col),
              builder: (_, hover) => Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: col,
                  shape: BoxShape.circle,
                  boxShadow: col.toARGB32() == selected.toARGB32() || hover
                      ? [
                          BoxShadow(color: col, spreadRadius: 3.5),
                          BoxShadow(color: c.raised, spreadRadius: 2),
                        ]
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
