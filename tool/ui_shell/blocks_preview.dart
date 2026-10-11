// 块系统预览：本地模拟器按契约回调改假数据，让管理页、侧栏、实例卡、编辑块、存为块在预览里都“真的”起作用。
// 只给 preview_main.dart 用，不进应用。
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_dock.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_edit.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_fixture.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_instance.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_quick.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_block_pill.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_colors.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_dialog.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_fixture_image.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_popover.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_text.dart';

/// 预设状态（预览顶栏切换）。
enum BlocksScene { ready, loading, empty }

final _images = <String, ImageProvider>{};

/// 优先用原型图（.devin/mockups/blocks/assets），没有就用生成的渐变图。
ImageProvider blocksPreviewImage(String key) => _images.putIfAbsent(key, () {
  final f = File('../../mockups/blocks/assets/$key.jpg');
  return f.existsSync() ? FileImage(f) : UiFixtureImage.gradient(key);
});

const _collectionMembers = {
  'k-artists': ['pk', 'bl', 'hz', 'af', 'ak', 'y99', 'xs', 'd3'],
  'k-daily': ['aq', 'sy', 'lk', 'kx'],
};

class BlocksPreviewSim extends ChangeNotifier {
  BlocksPreviewSim({required this.log});

  final ValueChanged<String> log;

  var scene = BlocksScene.ready;
  var blocks = BlocksFixture.blocks(blocksPreviewImage);
  var folders = [...BlocksFixture.folders];
  var collections = [...BlocksFixture.collections];
  var tags = [...BlocksFixture.tags];
  final _members = {
    for (final e in _collectionMembers.entries) e.key: [...e.value],
  };
  var scope = const BlocksScope.all();
  var query = '';
  var sort = BlocksSort.custom;
  var descending = true;
  var view = BlocksView.grid;
  var quick = <BlocksQuick>{};
  var cardSize = .5;
  String? selected = 'y99';
  var sidebar = true;
  var inspector = true;
  final palette = <String>{'aq'};
  var _seq = 0;

  void _set(VoidCallback f, String what) {
    f();
    log(what);
    notifyListeners();
  }

  BlockData _byId(String id) => blocks.firstWhere((b) => b.id == id);

  BlockData _copy(
    BlockData b, {
    String? id,
    String? title,
    Color? color,
    String? icon,
    bool clearIcon = false,
    BlockAppearance? look,
    String? folderId,
    bool root = false,
    List<BlockTag>? tags,
    bool? favorite,
    List<String>? atoms,
    List<String>? negativeAtoms,
    BlockParams? params,
    bool clearParams = false,
    BlockThumb? thumb,
    bool clearThumb = false,
  }) {
    final f = root ? null : (folderId ?? b.folderId);
    return BlockData(
      id: id ?? b.id,
      title: title ?? b.title,
      color: color ?? b.color,
      icon: clearIcon ? null : (icon ?? b.icon),
      look: look ?? b.look,
      atoms: atoms ?? b.atoms,
      negativeAtoms: negativeAtoms ?? b.negativeAtoms,
      params: clearParams ? null : (params ?? b.params),
      tags: tags ?? b.tags,
      folderId: f,
      folderName: folders.where((x) => x.id == f).firstOrNull?.name,
      thumb: clearThumb ? null : (thumb ?? b.thumb),
      useCount: b.useCount,
      favorite: favorite ?? b.favorite,
      createdAt: b.createdAt,
      updatedAt: BlocksFixture.now,
      sourcePath: b.sourcePath,
      importedAt: b.importedAt,
      sourceState: b.sourceState,
    );
  }

  void _update(Iterable<String> ids, BlockData Function(BlockData) f) {
    final s = ids.toSet();
    blocks = [for (final b in blocks) s.contains(b.id) ? f(b) : b];
  }

  Set<String> _subtree(String id) => {
    id,
    for (final f in folders)
      if (f.parentId == id) ..._subtree(f.id),
  };

  List<BlockData> get _visible {
    final q = query.toLowerCase();
    Iterable<BlockData> list = switch (scope.kind) {
      BlocksScopeKind.all => blocks,
      BlocksScopeKind.recent => ([
        ...blocks,
      ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt))).take(8),
      BlocksScopeKind.favorites => blocks.where((b) => b.favorite),
      BlocksScopeKind.uncategorized => blocks.where((b) => b.folderId == null),
      BlocksScopeKind.folder => () {
        final ids = _subtree(scope.id!);
        return blocks.where((b) => ids.contains(b.folderId));
      }(),
      BlocksScopeKind.collection => [
        for (final id in _members[scope.id] ?? const <String>[])
          ?blocks.where((b) => b.id == id).firstOrNull,
      ],
      BlocksScopeKind.tag => blocks.where(
        (b) => b.tags.any((t) => t.name == scope.id),
      ),
    };
    if (q.isNotEmpty) {
      list = list.where(
        (b) =>
            b.title.toLowerCase().contains(q) ||
            b.content.toLowerCase().contains(q) ||
            b.tags.any((t) => t.name.toLowerCase().contains(q)),
      );
    }
    if (quick.contains(BlocksQuick.image)) {
      list = list.where((b) => b.thumb != null);
    }
    if (quick.contains(BlocksQuick.negative)) {
      list = list.where((b) => b.hasNegative);
    }
    if (quick.contains(BlocksQuick.params)) {
      list = list.where((b) => b.hasParams);
    }
    final out = list.toList();
    int cmp(BlockData a, BlockData b) => switch (sort) {
      BlocksSort.custom => 0,
      BlocksSort.updated => a.updatedAt.compareTo(b.updatedAt),
      BlocksSort.title => a.title.compareTo(b.title),
      BlocksSort.color =>
        blockPalette.indexOf(a.color).compareTo(blockPalette.indexOf(b.color)),
      BlocksSort.icon => (a.icon ?? '').compareTo(b.icon ?? ''),
    };
    if (sort != BlocksSort.custom) {
      out.sort((a, b) => descending ? cmp(b, a) : cmp(a, b));
    }
    return out;
  }

  BlocksLibraryViewData get data {
    if (scene == BlocksScene.empty) {
      return BlocksLibraryViewData(
        now: BlocksFixture.now,
        catalog: BlocksFixture.catalog,
      );
    }
    const grid = BlocksFixture.grid;
    final vis = _visible;
    final ordered =
        sort == BlocksSort.custom &&
            scope.kind == BlocksScopeKind.all &&
            _seq == 0
        ? [
            for (final k in grid) ?vis.where((b) => b.id == k).firstOrNull,
            ...vis.where((b) => !grid.contains(b.id)),
          ]
        : vis;
    return BlocksLibraryViewData(
      now: BlocksFixture.now,
      loading: scene == BlocksScene.loading,
      blocks: scene == BlocksScene.loading ? const [] : ordered,
      counts: BlocksCounts(
        all: 703 + blocks.length - 22,
        recent: 32,
        favorites: blocks.where((b) => b.favorite).length,
        uncategorized: 26,
      ),
      folders: folders,
      collections: [
        for (final k in collections)
          BlocksCollection(
            id: k.id,
            name: k.name,
            count: _members[k.id]?.length ?? k.count,
            parentId: k.parentId,
            depth: k.depth,
            isFolder: k.isFolder,
          ),
      ],
      tags: tags,
      scope: scope,
      query: query,
      sort: sort,
      descending: descending,
      view: view,
      quick: quick,
      cardSize: cardSize,
      selectedId: selected,
      sidebarOpen: sidebar,
      inspectorOpen: inspector,
      catalog: BlocksFixture.catalog,
      paletteIds: palette,
    );
  }

  BlockData _fromDraft(String id, BlockDraft d, {BlockData? base}) => BlockData(
    id: id,
    title: d.title.isEmpty ? (d.atoms?.firstOrNull ?? d.text ?? '') : d.title,
    color: d.color,
    icon: d.icon,
    look: d.look,
    atoms: d.atoms ?? [?d.text],
    negativeAtoms: d.negativeAtoms,
    params: d.params,
    tags: d.tags,
    folderId: d.folderId,
    folderName: folders.where((x) => x.id == d.folderId).firstOrNull?.name,
    thumb: d.thumb,
    useCount: base?.useCount ?? 0,
    favorite: base?.favorite ?? false,
    createdAt: base?.createdAt ?? BlocksFixture.now,
    updatedAt: BlocksFixture.now,
    sourcePath: base?.sourcePath,
    importedAt: base?.importedAt,
    sourceState: base?.sourceState ?? BlockSourceState.none,
  );

  late final BlocksLibraryActions actions = BlocksLibraryActions(
    onScopeChanged: (s) => _set(() {
      scope = s;
      query = '';
    }, 'onScopeChanged(${s.kind.name} ${s.id ?? ''})'),
    onQueryChanged: (q) => _set(() => query = q, 'onQueryChanged($q)'),
    onSortChanged: (s, {required descending}) => _set(() {
      sort = s;
      this.descending = descending;
    }, 'onSortChanged(${s.name}, desc: $descending)'),
    onViewChanged: (v) => _set(() => view = v, 'onViewChanged(${v.name})'),
    onQuickChanged: (q) =>
        _set(() => quick = {...q}, 'onQuickChanged(${q.map((e) => e.name)})'),
    onCardSizeChanged: (v) =>
        _set(() => cardSize = v, 'onCardSizeChanged(${v.toStringAsFixed(2)})'),
    onSidebarChanged: (v) => _set(() => sidebar = v, 'onSidebarChanged($v)'),
    onInspectorChanged: (v) =>
        _set(() => inspector = v, 'onInspectorChanged($v)'),
    onSelect: (id) => _set(() => selected = id, 'onSelect($id)'),
    onInsert: (ids) => log('onInsert($ids)'),
    onSetFavorite: (ids, v) => _set(
      () => _update(ids, (b) => _copy(b, favorite: v)),
      'onSetFavorite($ids, $v)',
    ),
    onDuplicate: (id) => _set(() {
      final b = _byId(id);
      final i = blocks.indexOf(b);
      final n = _copy(b, id: '$id-copy${++_seq}', title: '${b.title} 副本');
      blocks = [...blocks]..insert(i + 1, n);
      selected = n.id;
    }, 'onDuplicate($id)'),
    onCopyText: (id) => log('onCopyText($id)'),
    onCreate: (d) async => _set(() {
      final id = 'new${++_seq}';
      blocks = [_fromDraft(id, d), ...blocks];
      selected = id;
    }, 'onCreate(${d.title})'),
    onSave: (id, d) async => _set(
      () => _update([id], (b) => _fromDraft(id, d, base: b)),
      'onSave($id)',
    ),
    onUpdate: (id, p) => _set(
      () => _update(
        [id],
        (b) => _copy(
          b,
          title: p.title,
          color: p.color,
          icon: p.icon,
          clearIcon: p.clearIcon,
          look: p.look,
          folderId: p.folderId,
          root: p.toRoot,
          tags: p.tags,
        ),
      ),
      'onUpdate($id)',
    ),
    onBatchStyle: (ids, {color, look}) => _set(
      () => _update(ids, (b) => _copy(b, color: color, look: look)),
      'onBatchStyle($ids)',
    ),
    onDelete: (ids) => _set(() {
      blocks = [
        for (final b in blocks)
          if (!ids.contains(b.id)) b,
      ];
      if (ids.contains(selected)) selected = null;
    }, 'onDelete($ids)'),
    onDropToFolder: (ids, folder, mode) => _set(() {
      if (mode == BlocksDropMode.move) {
        _update(ids, (b) => _copy(b, folderId: folder, root: folder == null));
      } else {
        blocks = [
          ...blocks,
          for (final id in ids)
            _copy(
              _byId(id),
              id: '$id-c${++_seq}',
              folderId: folder,
              root: folder == null,
            ),
        ];
      }
    }, 'onDropToFolder($ids, $folder, ${mode.name})'),
    onDropToCollection: (ids, k, mode) => _set(() {
      final m = _members.putIfAbsent(k, () => []);
      for (final id in ids) {
        if (!m.contains(id)) m.add(id);
      }
      if (mode == BlocksDropMode.move &&
          scope.kind == BlocksScopeKind.collection) {
        _members[scope.id]?.removeWhere(ids.contains);
      }
    }, 'onDropToCollection($ids, $k, ${mode.name})'),
    onRemoveFromCollection: (ids, k) => _set(
      () => _members[k]?.removeWhere(ids.contains),
      'onRemoveFromCollection($ids, $k)',
    ),
    onReorder: (id, before) => _set(() {
      _seq++;
      final b = _byId(id);
      final list = [...data.blocks]..remove(b);
      final i = before == null
          ? list.length
          : list.indexWhere((x) => x.id == before);
      list.insert(math.max(0, i), b);
      blocks = [...list, ...blocks.where((x) => !list.contains(x))];
    }, 'onReorder($id, before: $before)'),
    onAddTag: (ids, t) => _set(
      () => _update(
        ids,
        (b) => b.tags.any((x) => x.name == t.name)
            ? b
            : _copy(b, tags: [...b.tags, t]),
      ),
      'onAddTag($ids, ${t.name})',
    ),
    onRemoveTag: (ids, t) => _set(
      () => _update(
        ids,
        (b) => _copy(
          b,
          tags: [
            for (final x in b.tags)
              if (x.name != t) x,
          ],
        ),
      ),
      'onRemoveTag($ids, $t)',
    ),
    onAddToPalette: (ids) =>
        _set(() => palette.addAll(ids), 'onAddToPalette($ids)'),
    onExport: (ids) => log('onExport($ids)'),
    onApplyParams: (id) => log('onApplyParams($id)'),
    onPickThumbnail: () async {
      log('onPickThumbnail');
      return BlockThumbPick(blocksPreviewImage('c12'), r'D:\pics\c12.jpg');
    },
    onCaptureParams: () async {
      log('onCaptureParams');
      return BlocksFixture.y99Params;
    },
    onCreateFolder: (name, {parentId}) async {
      final id = 'f-new${++_seq}';
      _set(() {
        final i = parentId == null
            ? folders.length
            : folders.indexWhere((f) => f.id == parentId) + 1;
        final depth = parentId == null
            ? 0
            : folders.firstWhere((f) => f.id == parentId).depth + 1;
        folders = [...folders]
          ..insert(
            i,
            BlocksFolder(
              id: id,
              name: name,
              count: 0,
              parentId: parentId,
              depth: depth,
            ),
          );
      }, 'onCreateFolder($name, parent: $parentId)');
      return id;
    },
    onRenameFolder: (id, name) => _set(
      () => folders = [
        for (final f in folders)
          f.id == id
              ? BlocksFolder(
                  id: f.id,
                  name: name,
                  count: f.count,
                  parentId: f.parentId,
                  depth: f.depth,
                  hasChildren: f.hasChildren,
                  expanded: f.expanded,
                )
              : f,
      ],
      'onRenameFolder($id, $name)',
    ),
    onDeleteFolder: (id) => log('onDeleteFolder($id) → 接线方弹现有删除对话框'),
    onToggleFolder: (id, v) => _set(
      () => folders = [
        for (final f in folders)
          f.id == id
              ? BlocksFolder(
                  id: f.id,
                  name: f.name,
                  count: f.count,
                  parentId: f.parentId,
                  depth: f.depth,
                  hasChildren: f.hasChildren,
                  expanded: v,
                )
              : f,
      ],
      'onToggleFolder($id, $v)',
    ),
    onMoveFolder: (id, parent) => log('onMoveFolder($id, $parent)'),
    onReorderFolder: (id, delta) => log('onReorderFolder($id, $delta)'),
    onCreateCollection: (name, {parentId, isFolder = false}) async {
      final id = 'k-new${++_seq}';
      _set(
        () => collections = [
          ...collections,
          BlocksCollection(id: id, name: name, count: 0),
        ],
        'onCreateCollection($name)',
      );
      return id;
    },
    onRenameCollection: (id, name) => _set(
      () => collections = [
        for (final k in collections)
          k.id == id
              ? BlocksCollection(id: k.id, name: name, count: k.count)
              : k,
      ],
      'onRenameCollection($id, $name)',
    ),
    onDeleteCollection: (id) => _set(
      () => collections = [
        for (final k in collections)
          if (k.id != id) k,
      ],
      'onDeleteCollection($id)',
    ),
    onRenameTag: (name, n) => log('onRenameTag($name, $n)'),
    onSetTagColor: (name, col) => _set(
      () => tags = [
        for (final t in tags)
          t.tag.name == name ? BlocksTagInfo(BlockTag(name, col), t.count) : t,
      ],
      'onSetTagColor($name)',
    ),
    onDeleteTag: (name) => _set(
      () => tags = [
        for (final t in tags)
          if (t.tag.name != name) t,
      ],
      'onDeleteTag($name)',
    ),
    onImportTxt: () => log('onImportTxt'),
    onImportFolder: () => log('onImportFolder'),
    onImportCuration: () => log('onImportCuration'),
    onExportBackup: () => log('onExportBackup'),
    onImportBackup: () => log('onImportBackup'),
  );
}

/// 生图页模拟：左边块库侧栏（300），右边一段带药丸的提示词——点药丸开实例卡，“模拟选中文字”开存为块。
class BlocksGenerationMock extends StatefulWidget {
  const BlocksGenerationMock({super.key, required this.log});
  final ValueChanged<String> log;

  @override
  State<BlocksGenerationMock> createState() => _BlocksGenerationMockState();
}

class _Inst {
  _Inst(this.data);
  BlockInstanceViewData data;
}

class _BlocksGenerationMockState extends State<BlocksGenerationMock> {
  var _filter = const BlocksDockFilter.all();
  var _query = '';
  final _collapsed = <String>{};
  late final _inst = {
    'pk': _Inst(BlocksFixture.instanceRandom()),
    'cy': _Inst(BlocksFixture.instanceSeq(blocksPreviewImage)),
    'y99': _Inst(BlocksFixture.instanceFixed(blocksPreviewImage)),
  };
  String? _open;
  UiPopoverAnchor? _anchor;
  var _selection = false;
  var _quick = false;
  var _edit = false;
  var _roll = 0;

  void _log(String s) => widget.log(s);

  BlocksDockViewData get _dock {
    final d = BlocksFixture.dock(
      image: blocksPreviewImage,
      filter: _filter,
      query: _query,
    );
    return BlocksDockViewData(
      total: d.total,
      query: d.query,
      filter: d.filter,
      chips: d.chips,
      favorites: d.favorites,
      recent: d.recent,
      results: d.results,
      groups: [
        for (final g in d.groups)
          BlocksDockGroup(
            id: g.id,
            name: g.name,
            count: g.count,
            blocks: g.blocks,
            expanded: !_collapsed.contains(g.id),
          ),
      ],
    );
  }

  BlockInstanceActions _actions(String id) {
    final i = _inst[id]!;
    void set(
      BlockInstanceViewData Function(BlockInstanceViewData d) f,
      String what,
    ) {
      setState(() => i.data = f(i.data));
      _log(what);
    }

    BlockInstanceViewData copy(
      BlockInstanceViewData d, {
      BlockRollSettings? settings,
      bool? locked,
      bool? enabled,
      List<BlockDrawn>? drawn,
      int? seqIndex,
      BlockScopeSide? side,
    }) {
      final atoms = d.block.atoms;
      final idx = seqIndex ?? d.seqIndex;
      final dr = drawn ?? d.drawn;
      return BlockInstanceViewData(
        block: d.block,
        settings: settings ?? d.settings,
        locked: locked ?? d.locked,
        enabled: enabled ?? d.enabled,
        drawn: dr,
        send: dr.isEmpty
            ? d.block.content
            : dr
                  .map(
                    (x) =>
                        x.weight == null ? x.text : '${x.weight}::${x.text}::',
                  )
                  .join(', '),
        seqIndex: idx,
        seqCount: d.seqCount,
        prevText: idx > 0 ? atoms[idx - 1] : null,
        nextText: idx + 1 < atoms.length ? atoms[idx + 1] : null,
        side: side ?? d.side,
        catalog: d.catalog,
      );
    }

    return BlockInstanceActions(
      onReroll: () => set(
        (d) => copy(
          d,
          drawn: BlocksFixture.sample(
            d.block,
            d.settings,
            1,
            seed: ++_roll,
          ).first,
        ),
        'onReroll($id)',
      ),
      onLockChanged: (v) =>
          set((d) => copy(d, locked: v), 'onLockChanged($id, $v)'),
      onModeChanged: (m) => set(
        (d) => copy(
          d,
          settings: d.settings.copyWith(mode: m),
          drawn: m == BlockMode.fixed
              ? const []
              : m == BlockMode.sequential
              ? [
                  BlockDrawn(
                    d.block.atoms[d.seqIndex.clamp(
                      0,
                      d.block.atoms.length - 1,
                    )],
                  ),
                ]
              : BlocksFixture.sample(
                  d.block,
                  d.settings.copyWith(mode: m),
                  1,
                  seed: ++_roll,
                ).first,
        ),
        'onModeChanged($id, ${m.name})',
      ),
      onStep: (delta) => set((d) {
        final n = (d.seqIndex + delta) % d.block.atoms.length;
        final idx = n < 0 ? n + d.block.atoms.length : n;
        return copy(d, seqIndex: idx, drawn: [BlockDrawn(d.block.atoms[idx])]);
      }, 'onStep($id, $delta)'),
      onSideChanged: (s) =>
          set((d) => copy(d, side: s), 'onSideChanged($id, ${s.name})'),
      onEnabledChanged: (v) =>
          set((d) => copy(d, enabled: v), 'onEnabledChanged($id, $v)'),
      onEditBlock: () => setState(() {
        _open = null;
        _edit = true;
      }),
      onRemove: () => _log('onRemove($id)'),
      onApplyParams: () => _log('onApplyParams($id)'),
      onSaveSettings: (s) => set(
        (d) => copy(d, settings: s),
        'onSaveSettings($id, ${s.mode.name})',
      ),
      sample: (s, n) => BlocksFixture.sample(i.data.block, s, n, seed: ++_roll),
      onShowInLibrary: () => _log('onShowInLibrary($id)'),
      onCopySend: () => _log('onCopySend($id)'),
    );
  }

  Widget _pill(String id) {
    final d = _inst[id]!.data;
    return Builder(
      builder: (ctx) => GestureDetector(
        key: Key('mock-pill-$id'),
        onTap: () {
          final box = ctx.findRenderObject()! as RenderBox;
          setState(() {
            _open = id;
            _anchor = UiPopoverAnchor(
              box.localToGlobal(box.size.bottomLeft(const Offset(0, 8))),
            );
          });
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: UiBlockPill(
            label: d.block.title,
            color: d.block.color,
            icon: d.block.icon,
            look: d.block.look,
            open: _open == id,
            disabled: !d.enabled,
            paired: d.side == BlockScopeSide.both,
            badge: d.locked
                ? UiBlockBadge.locked
                : switch (d.settings.mode) {
                    BlockMode.fixed => UiBlockBadge.none,
                    BlockMode.sequential => UiBlockBadge.sequential,
                    BlockMode.random => UiBlockBadge.random,
                  },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final dock = BlocksDock(
      data: _dock,
      actions: BlocksDockActions(
        onQueryChanged: (q) => setState(() => _query = q),
        onFilterChanged: (f) => setState(() => _filter = f),
        onInsert: (id) => _log('dock.onInsert($id)'),
        dragDataOf: (id) => id,
        onCreate: () => setState(() => _edit = true),
        onOpenLibrary: () => _log('dock.onOpenLibrary'),
        onClose: () => _log('dock.onClose'),
        onToggleGroup: (g, v) =>
            setState(() => v ? _collapsed.remove(g) : _collapsed.add(g)),
        onEdit: (id) => setState(() => _edit = true),
        onSetFavorite: (id, v) => _log('dock.onSetFavorite($id, $v)'),
        onAddToPalette: (id) => _log('dock.onAddToPalette($id)'),
        onShowInLibrary: (id) => _log('dock.onShowInLibrary($id)'),
      ),
    );
    final mono = UiText.sans(13, color: c.ink, height: 1.75);
    final editor = Container(
      color: c.page,
      padding: const EdgeInsets.all(24),
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: c.raised,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.line),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text:
                          '… dynamic composition, sitting, wide shot, giant, ',
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: _pill('pk'),
                    ),
                    const TextSpan(text: ', very aesthetic, masterpiece, '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: _pill('y99'),
                    ),
                    const TextSpan(text: ' '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: _pill('cy'),
                    ),
                    const TextSpan(text: ' girl, '),
                    TextSpan(
                      text: 'white dress, blue flower, frilled dress',
                      style: _selection
                          ? TextStyle(
                              backgroundColor: c.accent.withValues(alpha: .22),
                            )
                          : null,
                    ),
                    const TextSpan(text: ', no text'),
                  ],
                ),
                style: mono,
              ),
            ),
            Row(
              spacing: 8,
              children: [
                FilledButton.tonal(
                  key: const Key('mock-select'),
                  onPressed: () => setState(() {
                    _selection = !_selection;
                    _quick = false;
                  }),
                  child: Text(_selection ? '取消选中' : '模拟选中文字'),
                ),
              ],
            ),
            if (_selection && !_quick)
              BlockSelectionToolbar(
                onSaveAsBlock: () => setState(() => _quick = true),
                onCopy: () => _log('selection.onCopy'),
                onLookup: () => _log('selection.onLookup'),
              ),
            if (_quick)
              BlockQuickSave(
                data: BlocksFixture.quick,
                actions: BlockQuickSaveActions(
                  onSave: (d) {
                    _log(
                      'quick.onSave(${d.title}, replace: ${d.replaceSelection})',
                    );
                    setState(() => _quick = _selection = false);
                  },
                  onCancel: () => setState(() => _quick = false),
                ),
              ),
          ],
        ),
      ),
    );
    return UiModal(
      dialog: _edit
          ? (_) => BlockEditDialog(
              data: BlocksFixture.edit(blocksPreviewImage),
              actions: BlockEditActions(
                onSave: (d) {
                  _log('edit.onSave(${d.title})');
                  setState(() => _edit = false);
                },
                onCancel: () => setState(() => _edit = false),
                onPickThumbnail: () async =>
                    BlockThumbPick(blocksPreviewImage('c12'), 'c12'),
                onCaptureParams: () async => BlocksFixture.y99Params,
                onDelete: () => setState(() => _edit = false),
              ),
            )
          : null,
      barrierDismissible: false,
      onDismiss: () => setState(() => _edit = false),
      child: UiPopover(
        anchor: _open == null ? null : _anchor,
        onDismiss: () => setState(() => _open = null),
        builder: (_) => BlockInstanceCard(
          key: ValueKey(_open),
          data: _inst[_open]!.data,
          actions: _actions(_open!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 300, child: dock),
            Expanded(child: editor),
          ],
        ),
      ),
    );
  }
}
