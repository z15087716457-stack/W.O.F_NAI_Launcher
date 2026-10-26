import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/studio_icons.dart';
import '../../widgets/navigation/window_chrome_layout.dart';
import '../kit/ui_block_pill.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_inputs.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_slider.dart';
import '../kit/ui_text.dart';
import 'blocks_contract.dart';
import 'blocks_format.dart';
import 'blocks_page.dart';
import 'blocks_parts.dart';
import 'blocks_rag_badge.dart';

String? _lastTapId;
var _lastTapAt = DateTime(0);

/// 单击选中、300ms 内再点同一张 = 编辑；多选中或按着 Ctrl / Shift 时切换勾选。
/// 不用 onDoubleTap：那会让单击和卡片上的按钮都等 300ms 才响应。
void _tapBlock(BlocksLibraryPageState ctrl, BlocksLibraryActions a, String id) {
  final hw = HardwareKeyboard.instance;
  if (ctrl.picking || hw.isControlPressed || hw.isShiftPressed) {
    ctrl.togglePick(id);
    return;
  }
  final now = DateTime.now();
  final again =
      _lastTapId == id && now.difference(_lastTapAt) < kDoubleTapTimeout;
  _lastTapId = again ? null : id;
  _lastTapAt = now;
  again ? ctrl.openEdit(id) : a.onSelect(id);
}

/// “含负面”的图标：圆里一横。
const _negGlyph = 'M12 21a9 9 0 100-18 9 9 0 000 18zM8 12h8';

UiPopoverAnchor _below(BuildContext ctx, {bool right = false}) {
  final box = ctx.findRenderObject()! as RenderBox;
  return UiPopoverAnchor(
    box.localToGlobal(
      right
          ? box.size.bottomRight(const Offset(0, 6))
          : box.size.bottomLeft(const Offset(0, 6)),
    ),
    alignRight: right,
  );
}

UiPopoverAnchor _above(BuildContext ctx) {
  final box = ctx.findRenderObject()! as RenderBox;
  return UiPopoverAnchor(
    box.localToGlobal(box.size.topLeft(const Offset(0, -8))),
    alignBottom: true,
  );
}

/// 工具栏 62：范围标题 + 计数 · 搜索（最宽 300）· 排序 · 网格 / 列表 ┊ 多选 · 新建块 · 详情开关。
/// 详情收起时窗口按钮落在工具栏右上角，让出位置。
class BlocksToolbar extends StatelessWidget {
  const BlocksToolbar({
    super.key,
    required this.inspectorShown,
    required this.sidebarShown,
  });
  final bool inspectorShown;
  final bool sidebarShown;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = BlocksPageScope.of(context);
    final d = scope.data;
    final a = scope.actions;
    final ctrl = scope.controller;
    final empty = d.libraryEmpty;

    List<UiMenuItem> sortMenu() => [
      for (final s in BlocksSort.values)
        UiMenuItem(
          key: Key('blocks-sort-${s.name}'),
          label: BlocksFormat.sort(context, s),
          checked: d.sort == s,
          onTap: () => a.onSortChanged(s, descending: d.descending),
        ),
      if (d.sort != BlocksSort.custom)
        UiMenuItem(
          glyph: d.descending ? UiGlyphs.chevronDown : UiGlyphs.chevronUp,
          label: d.descending ? l10n.blocks_sortDesc : l10n.blocks_sortAsc,
          divider: true,
          onTap: () => a.onSortChanged(d.sort, descending: !d.descending),
        ),
      // 分组和排序同一处：窄屏工具栏放不下独立开关时也能在这里切。
      if (a.onGroupByFolderChanged != null)
        UiMenuItem(
          key: const Key('blocks-sort-group'),
          glyph: UiGlyphs.folder,
          label: l10n.blocks_groupByFolder,
          checked: d.groupByFolder,
          divider: true,
          onTap: () => a.onGroupByFolderChanged!(!d.groupByFolder),
        ),
    ];

    final reserve = !inspectorShown;
    final chrome = WindowChromeScope.activeOf(context);
    return WindowHeader(
      key: const Key('blocks-toolbar'),
      enabled: reserve,
      minimumInlineWidth: 0,
      inlineDragWidth: 12,
      dragBackground: true,
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Container(
        height: 61,
        padding: EdgeInsets.only(
          left: sidebarShown ? 18 : 12,
          right: reserve && chrome ? 0 : 16,
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final compact = box.maxWidth < 860;
            final tight = box.maxWidth < 620;
            return Row(
              spacing: 8,
              children: [
                if (!sidebarShown)
                  UiIconBox(
                    key: const Key('blocks-expand-nav'),
                    glyph: UiGlyphs.doubleRight,
                    tooltip: l10n.blocks_expandSidebar,
                    onTap: () => a.onSidebarChanged(true),
                  ),
                if (!tight) ...[
                  Flexible(
                    flex: 0,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        blocksScopeTitle(context, d),
                        key: const Key('blocks-scope-title'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(
                          15,
                          weight: FontWeight.w700,
                          color: c.ink,
                        ),
                      ),
                    ),
                  ),
                  if (!empty) _Count(d.blocks.length),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Row(
                    spacing: 8,
                    children: [
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: KeyedSubtree(
                            key: const Key('blocks-search'),
                            child: UiSearchField(
                              key: ValueKey(d.scope),
                              value: d.query,
                              hint: l10n.blocks_searchLibrary,
                              focusNode: ctrl.searchFocus,
                              enabled: !empty,
                              onChanged: a.onQueryChanged,
                              trailing: d.rag.enabled
                                  ? BlocksRagBadge(data: d.rag)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      if (!empty) ...[
                        Builder(
                          builder: (ctx) => compact
                              ? UiIconBox(
                                  key: const Key('blocks-sort'),
                                  glyph: UiGlyphs.sort,
                                  tone: UiIconBoxTone.bordered,
                                  tooltip: BlocksFormat.sort(context, d.sort),
                                  onTap: () =>
                                      ctrl.openMenu(_below(ctx), sortMenu()),
                                )
                              : UiDropChip(
                                  key: const Key('blocks-sort'),
                                  glyph: UiGlyphs.sort,
                                  label: BlocksFormat.sort(context, d.sort),
                                  onTap: () =>
                                      ctrl.openMenu(_below(ctx), sortMenu()),
                                ),
                        ),
                        UiSeg<BlocksView>(
                          key: const Key('blocks-view'),
                          values: BlocksView.values,
                          selected: d.view,
                          onChanged: a.onViewChanged,
                          labelOf: (_) => '',
                          glyphOf: (v) => switch (v) {
                            BlocksView.masonry => UiGlyphs.masonryMedium,
                            BlocksView.grid => UiGlyphs.grid,
                            BlocksView.list => UiGlyphs.list,
                          },
                          tooltipOf: (v) => switch (v) {
                            BlocksView.masonry => l10n.blocks_viewMasonry,
                            BlocksView.grid => l10n.blocks_viewGrid,
                            BlocksView.list => l10n.blocks_viewList,
                          },
                        ),
                        if (!compact)
                          UiIconBox(
                            key: const Key('blocks-group-folders'),
                            glyph: UiGlyphs.folder,
                            tone: d.groupByFolder
                                ? UiIconBoxTone.on
                                : UiIconBoxTone.bordered,
                            tooltip: l10n.blocks_groupByFolder,
                            onTap: a.onGroupByFolderChanged == null
                                ? null
                                : () => a.onGroupByFolderChanged!(
                                    !d.groupByFolder,
                                  ),
                          ),
                      ],
                    ],
                  ),
                ),
                if (!empty)
                  UiBtn(
                    key: Key(
                      ctrl.picking ? 'blocks-multi-done' : 'blocks-multi',
                    ),
                    tone: ctrl.picking ? UiBtnTone.accent : UiBtnTone.normal,
                    tooltip: compact
                        ? (ctrl.picking
                              ? l10n.blocks_multiDone
                              : l10n.blocks_multiSelect)
                        : null,
                    padding: compact
                        ? const EdgeInsets.symmetric(horizontal: 7)
                        : null,
                    onTap: () => ctrl.setPicking(!ctrl.picking),
                    children: [
                      const UiGlyph(UiGlyphs.box, size: 14),
                      if (!compact)
                        Text(
                          ctrl.picking
                              ? l10n.blocks_multiDone
                              : l10n.blocks_multiSelect,
                        ),
                    ],
                  ),
                UiBtn(
                  key: const Key('blocks-create'),
                  tone: UiBtnTone.primary,
                  tooltip: l10n.blocks_newBlockTip,
                  onTap: () => ctrl.openEdit(null),
                  children: [
                    const UiGlyph(UiGlyphs.plus, size: 14, strokeWidth: 2.2),
                    Text(l10n.blocks_newBlock),
                  ],
                ),
                if (!empty)
                  UiIconBox(
                    key: const Key('blocks-inspector-toggle'),
                    glyph: UiGlyphs.panel,
                    tone: inspectorShown
                        ? UiIconBoxTone.on
                        : UiIconBoxTone.plain,
                    tooltip: inspectorShown
                        ? l10n.blocks_hideInspector
                        : l10n.blocks_showInspector,
                    onTap: () => a.onInspectorChanged(!d.inspectorOpen),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.n);
  final int n;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      key: const Key('blocks-count'),
      height: 18,
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '$n',
        style: UiText.sans(
          11,
          weight: FontWeight.w600,
          color: c.muted,
          height: 1.2,
        ),
      ),
    );
  }
}

/// 快速筛选行 46：全部 · 有预览图 · 含负面 · 附带参数（可多选）；右边“卡片大小”滑杆（网格时）。
class BlocksFilterRow extends StatelessWidget {
  const BlocksFilterRow({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = BlocksPageScope.of(context);
    final d = scope.data;
    final a = scope.actions;
    final ctrl = scope.controller;
    Widget chip(BlocksQuick q, String glyph, String label) {
      final on = d.quick.contains(q);
      return UiFilterChip(
        key: Key('blocks-quick-${q.name}'),
        label: label,
        selected: on,
        gap: 5,
        leading: UiGlyph(glyph, size: 13, color: on ? c.bg : c.muted),
        onTap: () =>
            a.onQuickChanged(on ? ({...d.quick}..remove(q)) : {...d.quick, q}),
      );
    }

    return Container(
      key: const Key('blocks-filter-row'),
      height: 46,
      padding: const EdgeInsets.only(left: 18, right: 16),
      child: Row(
        spacing: 6,
        children: [
          UiFilterChip(
            key: const Key('blocks-quick-all'),
            label: l10n.blocks_filterAll,
            selected: d.quick.isEmpty,
            onTap: () => a.onQuickChanged(const {}),
          ),
          chip(BlocksQuick.image, UiGlyphs.picture, l10n.blocks_quickImage),
          chip(BlocksQuick.negative, _negGlyph, l10n.blocks_quickNegative),
          chip(BlocksQuick.params, UiGlyphs.bolt, l10n.blocks_quickParams),
          const Spacer(),
          if (d.view != BlocksView.list) ...[
            Text(l10n.blocks_cardSize, style: UiText.sans(12, color: c.faint)),
            SizedBox(
              key: const Key('blocks-card-size'),
              width: 88,
              child: UiSlider(
                value: ctrl.cardSize,
                onChanged: ctrl.setLiveSize,
                onChangeEnd: (v) {
                  ctrl.setLiveSize(null);
                  a.onCardSizeChanged(v);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 卡片墙 / 列表。没数据时：读库中画骨架，筛选后为空给“清除筛选”。
class BlocksWall extends StatelessWidget {
  const BlocksWall({super.key});

  /// 卡片最小宽：卡片大小 0…1 → 160…280（1600 宽窗口、默认 0.5 时一行 4 张，同原型）。
  static double minCard(double size) => 160 + 120 * size.clamp(0, 1);

  static int columnsFor(double width, double size) =>
      math.max(1, ((width - 36 + 12) / (minCard(size) + 12)).floor());

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = BlocksPageScope.of(context);
    final d = scope.data;
    final a = scope.actions;
    final ctrl = scope.controller;

    if (!d.loading && d.blocks.isEmpty) {
      return Center(
        key: const Key('blocks-no-results'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            UiGlyph(UiGlyphs.search, size: 26, color: c.faint),
            Text(
              l10n.blocks_noMatch,
              style: UiText.sans(13.5, weight: FontWeight.w600, color: c.ink),
            ),
            Text(
              l10n.blocks_noMatchBody,
              style: UiText.sans(12.5, color: c.muted),
            ),
            if (d.query.isNotEmpty || d.quick.isNotEmpty)
              UiBtn(
                key: const Key('blocks-clear-filters'),
                size: UiBtnSize.small,
                onTap: () {
                  a.onQueryChanged('');
                  a.onQuickChanged(const {});
                },
                children: [Text(l10n.blocks_clearFilters)],
              ),
          ],
        ),
      );
    }

    if (d.view == BlocksView.list && !d.loading) return const _ListView();

    return LayoutBuilder(
      builder: (context, box) {
        final cols = columnsFor(box.maxWidth, ctrl.cardSize);
        ctrl.wallColumns = cols;
        final cardW = (box.maxWidth - 36 - 12 * (cols - 1)) / cols;
        final coverH = (cardW * .6).roundToDouble();
        if (d.loading) {
          return GridView.builder(
            key: const Key('blocks-grid'),
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 80),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              mainAxisExtent: coverH + 58,
            ),
            itemCount: cols * 3,
            itemBuilder: (context, i) => _Skeleton(coverH: coverH),
          );
        }
        final masonry = d.view == BlocksView.masonry;
        Widget content(int start, int count) => masonry && d.groups != null
            ? _GroupedMasonry(
                blocks: d.blocks.sublist(start, start + count),
                columns: cols,
                width: cardW,
              )
            : masonry
            ? SliverMasonryGrid.count(
                crossAxisCount: cols,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
                childCount: count,
                itemBuilder: (context, i) => _Card(
                  key: ValueKey(d.blocks[start + i].id),
                  block: d.blocks[start + i],
                  coverH: null,
                  width: cardW,
                ),
              )
            : SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 14,
                  mainAxisExtent: coverH + 58,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _Card(
                    key: ValueKey(d.blocks[start + i].id),
                    block: d.blocks[start + i],
                    coverH: coverH,
                    width: cardW,
                  ),
                  childCount: count,
                ),
              );
        return _GroupedScroll(
          key: const Key('blocks-grid'),
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
          content: content,
        );
      },
    );
  }
}

/// 卡片墙 / 列表的滚动体：不分组时一段内容；按文件夹分组时每组一个吸顶文件夹条，
/// 下一组的条滚上来会把它顶走（`SliverMainAxisGroup` 把吸顶限制在本组范围内）。
class _GroupedScroll extends StatelessWidget {
  const _GroupedScroll({
    super.key,
    required this.padding,
    required this.content,
  });
  final EdgeInsets padding;
  final Widget Function(int start, int count) content;

  @override
  Widget build(BuildContext context) {
    final d = BlocksPageScope.of(context).data;
    final groups = d.groups;
    return CustomScrollView(
      slivers: [
        if (groups == null)
          SliverPadding(padding: padding, sliver: content(0, d.blocks.length))
        else
          for (final g in groups)
            SliverMainAxisGroup(
              key: ValueKey('blocks-group-${g.folderId}'),
              slivers: [
                PinnedHeaderSliver(child: _FolderBar(group: g)),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    padding.left,
                    6,
                    padding.right,
                    18,
                  ),
                  sliver: content(g.start, g.count),
                ),
              ],
            ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

/// 分组瀑布流使用并排的懒加载列表。旧 SliverMasonryGrid 在整组滚出
/// 缓存区后会错误请求回退校正，把外层滚动位置拉回上一组。
class _GroupedMasonry extends StatefulWidget {
  const _GroupedMasonry({
    required this.blocks,
    required this.columns,
    required this.width,
  });
  final List<BlockData> blocks;
  final int columns;
  final double width;

  @override
  State<_GroupedMasonry> createState() => _GroupedMasonryState();
}

class _GroupedMasonryState extends State<_GroupedMasonry> {
  bool _relayoutQueued = false;

  void _thumbnailResolved() {
    if (_relayoutQueued) return;
    _relayoutQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _relayoutQueued = false;
      if (mounted) setState(() {});
    });
  }

  double _height(BuildContext context, BlockData block) {
    final thumb = block.thumb;
    double cover;
    if (thumb != null) {
      final aspect = _MasonryThumbState._aspects[thumb.image] ?? 4 / 3;
      cover = (widget.width / aspect)
          .clamp(widget.width * .5, widget.width * 1.6)
          .roundToDouble();
    } else {
      final picking = BlocksPageScope.of(context).controller.picking;
      final painter = TextPainter(
        text: TextSpan(
          text: block.atoms.isEmpty
              ? block.negativeAtoms.join(', ')
              : block.content,
          style: UiText.mono(11, height: 1.6),
        ),
        maxLines: 8,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: math.max(1, widget.width - (picking ? 66 : 42)));
      cover = math.max(72, painter.height + 23);
      painter.dispose();
    }
    // 标题、计数与内边距高度相近；估算只决定放到哪列，卡片仍按自然高度布局。
    return cover + 58;
  }

  @override
  Widget build(BuildContext context) {
    final columns = List.generate(widget.columns, (_) => <BlockData>[]);
    final heights = List.filled(widget.columns, 0.0);
    for (final block in widget.blocks) {
      var column = 0;
      for (var i = 1; i < heights.length; i++) {
        if (heights[i] < heights[column]) column = i;
      }
      columns[column].add(block);
      heights[column] += _height(context, block) + 14;
    }
    return SliverCrossAxisGroup(
      slivers: [
        for (var column = 0; column < columns.length; column++) ...[
          if (column > 0)
            const SliverConstrainedCrossAxis(
              maxExtent: 12,
              sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
          SliverConstrainedCrossAxis(
            maxExtent: widget.width,
            sliver: SliverList.separated(
              itemCount: columns[column].length,
              findItemIndexCallback: (key) {
                final index = columns[column].indexWhere(
                  (block) => ValueKey(block.id) == key,
                );
                return index < 0 ? null : index;
              },
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, i) => _Card(
                key: ValueKey(columns[column][i].id),
                block: columns[column][i],
                coverH: null,
                width: widget.width,
                onThumbnailResolved: _thumbnailResolved,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 吸顶文件夹条：文件夹图标 · 路径（父级弱色、当前级加粗）· 块数；根目录写“未分类”。
class _FolderBar extends StatelessWidget {
  const _FolderBar({required this.group});
  final BlocksGroup group;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final parts = group.folderId == null
        ? [l10n.blocks_uncategorized]
        : group.path.split(' / ');
    return Container(
      key: Key('blocks-folder-bar-${group.folderId}'),
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        spacing: 8,
        children: [
          UiGlyph(
            group.folderId == null ? UiGlyphs.box : UiGlyphs.folder,
            size: 14,
            color: c.muted,
          ),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  for (final (i, p) in parts.indexed) ...[
                    if (i > 0)
                      TextSpan(
                        text: '  /  ',
                        style: UiText.sans(12.5, color: c.faint),
                      ),
                    TextSpan(
                      text: p,
                      style: i == parts.length - 1
                          ? UiText.sans(
                              13,
                              weight: FontWeight.w600,
                              color: c.ink,
                            )
                          : UiText.sans(12.5, color: c.muted),
                    ),
                  ],
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${group.count}',
            style: UiText.mono(11.5, color: c.faint, height: 1.2),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.coverH});
  final double coverH;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    Widget bar(double w) => Container(
      width: w,
      height: 10,
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(4),
      ),
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: coverH, color: c.control),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [bar(110), bar(70)],
            ),
          ),
        ],
      ),
    );
  }
}

/// 卡片（原型 `.bc`）：圆角 10、1px 描边、抬起底；封面高 = 卡宽 × 0.6（预览图或内容封面）；
/// 正文 8 / 10 / 9：图标 + 标题 13 / w600，“N 项 · 用过 N 次”11.5 弱色 + “负面”“参数”小标。
/// 选中强调色描边 + 3px 浅环；悬停时封面底部浮出操作条（插入 · 收藏 · 编辑 · 更多）。
class _Card extends StatefulWidget {
  const _Card({
    super.key,
    required this.block,
    required this.coverH,
    required this.width,
    this.onThumbnailResolved,
  });
  final BlockData block;

  /// 网格：固定封面高（卡宽 × 0.6）；null = 瀑布流，封面按内容 / 原图比例自然高。
  final double? coverH;
  final double width;
  final VoidCallback? onThumbnailResolved;

  @override
  State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = BlocksPageScope.of(context);
    final d = scope.data;
    final a = scope.actions;
    final ctrl = scope.controller;
    final b = widget.block;
    final picking = ctrl.picking;
    final picked = ctrl.picked.contains(b.id);
    final selected = !picking && d.selectedId == b.id;

    void tap() => _tapBlock(ctrl, a, b.id);

    Widget hoverBtn(
      String glyph,
      String tip,
      VoidCallback onTap, {
      String? label,
      Key? key,
      bool filled = false,
      Color? color,
    }) => UiPressable(
      key: key,
      onTap: onTap,
      builder: (context, h) => Tooltip(
        message: tip,
        child: Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: h ? Colors.white.withValues(alpha: .16) : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              UiGlyph(
                glyph,
                size: 14,
                filled: filled,
                color: color ?? Colors.white,
              ),
              if (label != null)
                Text(
                  label,
                  style: UiText.sans(12, color: Colors.white, height: 1.2),
                ),
            ],
          ),
        ),
      ),
    );

    final inset = picking ? 36.0 : 12.0;
    final cover = SizedBox(
      key: Key('blocks-cover-${b.id}'),
      height: widget.coverH,
      child: Stack(
        fit: widget.coverH == null ? StackFit.loose : StackFit.expand,
        children: [
          if (widget.coverH != null)
            BlockCover(b, leftInset: inset)
          else if (b.thumb != null)
            _MasonryThumb(
              thumb: b.thumb!,
              width: widget.width,
              onResolved: widget.onThumbnailResolved,
            )
          else
            _MasonryTextCover(block: b, leftInset: inset),
          if (b.favorite)
            Positioned(
              right: 7,
              top: 7,
              child: Container(
                key: Key('blocks-fav-${b.id}'),
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xEBFFFFFF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: UiGlyph(
                  UiGlyphs.star,
                  size: 13,
                  filled: true,
                  color: c.star,
                ),
              ),
            ),
          if (picking)
            Positioned(
              left: 7,
              top: 7,
              child: Container(
                key: Key('blocks-check-${b.id}'),
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: picked
                      ? c.accent
                      : Colors.black.withValues(alpha: .22),
                  border: Border.all(
                    color: picked ? c.accent : Colors.white,
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4D000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: picked
                    ? const UiGlyph(
                        UiGlyphs.check,
                        size: 12,
                        strokeWidth: 3,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          if (_hover && !picking)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Container(
                key: Key('blocks-hoverbar-${b.id}'),
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xBD141414),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    hoverBtn(
                      UiGlyphs.plus,
                      l10n.blocks_insertToPrompt,
                      () => a.onInsert([b.id]),
                      label: l10n.blocks_insert,
                      key: Key('blocks-insert-${b.id}'),
                    ),
                    hoverBtn(
                      UiGlyphs.star,
                      b.favorite
                          ? l10n.blocks_unfavorite
                          : l10n.blocks_favorite,
                      () => a.onSetFavorite([b.id], !b.favorite),
                      filled: b.favorite,
                      color: b.favorite ? c.star : null,
                    ),
                    hoverBtn(
                      UiGlyphs.pencil,
                      l10n.blocks_edit,
                      () => ctrl.openEdit(b.id),
                    ),
                    Builder(
                      builder: (ctx) => hoverBtn(
                        UiGlyphs.more,
                        l10n.blocks_more,
                        () => ctrl.openMenu(
                          _below(ctx, right: true),
                          blocksCardMenu(context, b),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );

    final card = AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 120),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected || picked ? c.accent : (_hover ? c.strong : c.line),
        ),
        boxShadow: [
          if (selected || picked)
            BoxShadow(color: c.accent.withValues(alpha: .14), spreadRadius: 3),
          if (_hover && !selected)
            BoxShadow(
              color: Colors.black.withValues(alpha: c.dark ? .3 : .07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          cover,
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 3,
              children: [
                Row(
                  key: Key('blocks-title-${b.id}'),
                  spacing: 6,
                  children: [
                    UiBlockIcon(b.icon, size: 14, color: b.color),
                    Expanded(
                      child: Text(
                        b.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(
                          13,
                          weight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  key: Key('blocks-meta-${b.id}'),
                  spacing: 6,
                  children: [
                    Expanded(
                      child: Text(
                        '${l10n.blocks_items(b.itemCount)} · ${l10n.blocks_usedTimes(b.useCount)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(11.5, color: c.faint),
                      ),
                    ),
                    if (b.hasNegative)
                      _Mini(l10n.blocks_miniNegative, negative: true),
                    if (b.hasParams) _Mini(l10n.blocks_miniParams),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final ids = picked ? ctrl.picked.toList() : [b.id];
    Widget result = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        key: Key('blocks-card-${b.id}'),
        onTap: tap,
        onSecondaryTapUp: (e) {
          if (!picking) a.onSelect(b.id);
          ctrl.openMenu(
            UiPopoverAnchor(e.globalPosition),
            blocksCardMenu(context, b),
          );
        },
        child: Draggable<BlocksCardDrag>(
          data: BlocksCardDrag(ids),
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: _DragFeedback(block: b, count: ids.length),
          childWhenDragging: Opacity(opacity: .4, child: card),
          child: card,
        ),
      ),
    );
    if (d.sort == BlocksSort.custom && !picking) {
      final inner = result;
      result = DragTarget<BlocksCardDrag>(
        onWillAcceptWithDetails: (e) =>
            e.data.ids.length == 1 && e.data.ids.first != b.id,
        onAcceptWithDetails: (e) => a.onReorder(e.data.ids.first, b.id),
        builder: (context, cand, _) => Stack(
          clipBehavior: Clip.none,
          children: [
            inner,
            if (cand.isNotEmpty)
              Positioned(
                left: -7,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return result;
  }
}

/// 瀑布流封面（有预览图）：按原图比例显示整张图，比例夹在 0.5 ~ 1.6 倍宽之间；
/// 图还没解码时先按 4:3 占位。
class _MasonryThumb extends StatefulWidget {
  const _MasonryThumb({
    required this.thumb,
    required this.width,
    this.onResolved,
  });
  final BlockThumb thumb;
  final double width;
  final VoidCallback? onResolved;

  @override
  State<_MasonryThumb> createState() => _MasonryThumbState();
}

class _MasonryThumbState extends State<_MasonryThumb> {
  static final _aspects = <ImageProvider, double>{};
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(_MasonryThumb old) {
    super.didUpdateWidget(old);
    if (old.thumb.image != widget.thumb.image) _resolve();
  }

  void _resolve() {
    _stop();
    final image = widget.thumb.image;
    if (_aspects.containsKey(image)) return;
    final stream = image.resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener((info, _) {
      final i = info.image;
      if (i.width > 0 && i.height > 0 && mounted) {
        _aspects[image] = i.width / i.height;
        widget.onResolved?.call();
        // 已缓存的图在构建期间同步回调：此时 build 还没跑，直接读到新比例即可。
        if (SchedulerBinding.instance.schedulerPhase !=
            SchedulerPhase.persistentCallbacks) {
          setState(() {});
        }
      }
      _stop();
    }, onError: (_, _) => _stop());
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  void _stop() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aspect = _aspects[widget.thumb.image] ?? 4 / 3;
    final w = widget.width;
    final h = (w / aspect).clamp(w * .5, w * 1.6).roundToDouble();
    final t = widget.thumb;
    return SizedBox(
      height: h,
      width: double.infinity,
      child: Image(
        image: t.image,
        fit: BoxFit.cover,
        alignment: Alignment(t.offsetX.clamp(-1, 1), t.offsetY.clamp(-1, 1)),
        gaplessPlayback: true,
      ),
    );
  }
}

/// 瀑布流封面（无预览图）：内容按自然高度最多 8 行，短内容的卡就矮。
class _MasonryTextCover extends StatelessWidget {
  const _MasonryTextCover({required this.block, required this.leftInset});
  final BlockData block;
  final double leftInset;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final col = block.color;
    final text = block.atoms.isEmpty
        ? block.negativeAtoms.join(', ')
        : block.content;
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      width: double.infinity,
      color: Color.alphaBlend(
        col.withValues(alpha: c.dark ? .10 : .07),
        c.raised,
      ),
      padding: EdgeInsets.fromLTRB(leftInset, 11, 12, 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              text,
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
              style: UiText.mono(
                11,
                height: 1.6,
                color: Color.lerp(c.muted, col, .55),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -4,
            child: UiBlockIcon(
              block.icon,
              size: 34,
              color: col.withValues(alpha: .22),
            ),
          ),
        ],
      ),
    );
  }
}

/// 拖动时跟手的小卡：药丸 + “N 个”角标。
class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.block, required this.count});
  final BlockData block;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.raised,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: c.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .16),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: BlockPill(block),
            ),
            if (count > 1)
              Container(
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  context.l10n.blocks_nBlocks(count),
                  style: UiText.sans(
                    11,
                    weight: FontWeight.w600,
                    color: c.onAccent,
                    height: 1.2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 卡片右下的小标（原型 `.mini`）：17 高、圆角 4、10.5 / w600；“负面”用错误色 9% 底。
class _Mini extends StatelessWidget {
  const _Mini(this.text, {this.negative = false});
  final String text;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      height: 17,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: negative ? c.error.withValues(alpha: .09) : c.control,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: UiText.sans(
          10.5,
          weight: FontWeight.w600,
          color: negative ? c.error : c.muted,
          height: 1.2,
        ),
      ),
    );
  }
}

/// 列表视图：表头 34 + 行 44（勾选 · 缩略 28 · 药丸 · 内容预览 · 项数 · 文件夹 · 使用 · 修改）。
class _ListView extends StatelessWidget {
  const _ListView();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = BlocksPageScope.of(context);
    final d = scope.data;
    final ctrl = scope.controller;
    final head = UiText.sans(11.5, weight: FontWeight.w600, color: c.faint);
    return Column(
      key: const Key('blocks-list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 34,
          margin: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.line)),
          ),
          child: Row(
            children: [
              SizedBox(width: ctrl.picking ? 30 : 0),
              const SizedBox(width: 38),
              SizedBox(
                width: 200,
                child: Text(l10n.blocks_colName, style: head),
              ),
              Expanded(child: Text(l10n.blocks_content, style: head)),
              SizedBox(
                width: 56,
                child: Text(
                  l10n.blocks_colItems,
                  textAlign: TextAlign.right,
                  style: head,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 96,
                child: Text(l10n.blocks_colFolder, style: head),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  l10n.blocks_colUsed,
                  textAlign: TextAlign.right,
                  style: head,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 44,
                child: Text(l10n.blocks_colModified, style: head),
              ),
            ],
          ),
        ),
        Expanded(
          child: _GroupedScroll(
            padding: const EdgeInsets.fromLTRB(18, 2, 18, 0),
            content: (start, count) => SliverFixedExtentList(
              itemExtent: 44,
              delegate: SliverChildBuilderDelegate(
                (context, i) => _Row(block: d.blocks[start + i]),
                childCount: count,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.block});
  final BlockData block;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = BlocksPageScope.of(context);
    final d = scope.data;
    final a = scope.actions;
    final ctrl = scope.controller;
    final b = block;
    final picked = ctrl.picked.contains(b.id);
    final on = ctrl.picking ? picked : d.selectedId == b.id;
    final mono = UiText.mono(12, color: c.muted);
    return GestureDetector(
      key: Key('blocks-row-${b.id}'),
      onSecondaryTapUp: (e) {
        a.onSelect(b.id);
        ctrl.openMenu(
          UiPopoverAnchor(e.globalPosition),
          blocksCardMenu(context, b),
        );
      },
      child: Draggable<BlocksCardDrag>(
        data: BlocksCardDrag(picked ? ctrl.picked.toList() : [b.id]),
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: _DragFeedback(
          block: b,
          count: picked ? ctrl.picked.length : 1,
        ),
        child: UiPressable(
          onTap: () => _tapBlock(ctrl, a, b.id),
          builder: (context, hover) => Container(
            decoration: BoxDecoration(
              color: on ? c.control : (hover ? c.hover : null),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              children: [
                if (ctrl.picking)
                  SizedBox(
                    width: 30,
                    child: Center(
                      child: Container(
                        width: 16,
                        height: 16,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: picked ? c.accent : c.raised,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: picked ? c.accent : c.strong,
                            width: 1.5,
                          ),
                        ),
                        child: picked
                            ? const UiGlyph(
                                UiGlyphs.check,
                                size: 11,
                                strokeWidth: 3,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 6),
                  child: Container(
                    width: 28,
                    height: 28,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        b.color.withValues(alpha: .12),
                        c.raised,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: b.thumb != null
                        ? BlockCover(b)
                        : Center(
                            child: UiBlockIcon(
                              b.icon,
                              size: 14,
                              color: b.color,
                            ),
                          ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: BlockPill(b),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8),
                    child: Text(
                      b.atoms.isEmpty ? b.negativeAtoms.join(', ') : b.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.mono(11.5, color: c.faint),
                    ),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    '${b.itemCount}',
                    textAlign: TextAlign.right,
                    style: mono,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 96,
                  child: Text(
                    b.folderName ?? context.l10n.blocks_uncategorized,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.sans(12, color: c.muted),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text(
                    '${b.useCount}',
                    textAlign: TextAlign.right,
                    style: mono,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 44,
                  child: Text(
                    BlocksFormat.date(b.updatedAt),
                    style: UiText.mono(11, color: c.faint),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 多选浮条（原型 `.selbar`）：正文色底、窗口底色字、圆角 12、内边距 6 / 6 / 6 / 14、底部 20 居中；
/// 已选 N 个 ┊ 收藏 · 移到… · 标签 · 放进积木 · 导出 · 删除 ┊ ×。
class BlocksSelectionBar extends StatelessWidget {
  const BlocksSelectionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = BlocksPageScope.of(context);
    final d = scope.data;
    final a = scope.actions;
    final ctrl = scope.controller;
    final ids = ctrl.picked.toList();
    final allFav = ids.every(
      (id) => d.blocks.firstWhere((b) => b.id == id).favorite,
    );
    Widget vs() => Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: c.bg.withValues(alpha: .25),
    );
    Widget btn(
      String key,
      String glyph,
      String label,
      void Function(BuildContext) onTap, {
      bool danger = false,
      bool icon = false,
    }) => Builder(
      builder: (ctx) => UiPressable(
        key: Key('blocks-sel-$key'),
        onTap: () => onTap(ctx),
        builder: (context, hover) {
          final fg = danger ? const Color(0xFFFF8A8A) : c.bg;
          return Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: hover ? c.bg.withValues(alpha: .12) : null,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                if (glyph.isNotEmpty) UiGlyph(glyph, size: 15, color: fg),
                if (!icon)
                  Text(
                    label,
                    style: UiText.sans(
                      12.5,
                      weight: FontWeight.w500,
                      color: fg,
                      height: 1.2,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
    return Container(
      key: const Key('blocks-selection-bar'),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: c.ink,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.dark ? .5 : .18),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Text(
            l10n.blocks_selectedN(ids.length),
            style: UiText.sans(13, weight: FontWeight.w600, color: c.bg),
          ),
          vs(),
          btn(
            'favorite',
            UiGlyphs.star,
            allFav ? l10n.blocks_unfavorite : l10n.blocks_favorite,
            (_) => a.onSetFavorite(ids, !allFav),
          ),
          btn(
            'move',
            UiGlyphs.folder,
            l10n.blocks_moveTo,
            (ctx) => ctrl.openMenu(
              _above(ctx),
              blocksMoveMenu(context, ids),
              width: 230,
            ),
          ),
          btn(
            'tags',
            UiGlyphs.tag,
            l10n.blocks_tags,
            (ctx) => ctrl.openMenu(_above(ctx), [
              for (final t in d.tags)
                UiMenuItem(
                  label: t.tag.name,
                  glyph: UiGlyphs.tag,
                  onTap: () => a.onAddTag(ids, t.tag),
                ),
              if (d.tags.isEmpty)
                UiMenuItem(
                  label: l10n.blocks_noTags,
                  enabled: false,
                  onTap: () {},
                ),
            ]),
          ),
          btn(
            'palette',
            UiGlyphs.box,
            l10n.blocks_addToPalette,
            (_) => a.onAddToPalette(ids),
          ),
          btn(
            'export',
            UiGlyphs.upload,
            l10n.blocks_export,
            (_) => a.onExport(ids),
          ),
          btn(
            'delete',
            UiGlyphs.trash,
            l10n.blocks_delete,
            (_) => ctrl.confirmDelete(ids),
            danger: true,
          ),
          vs(),
          btn(
            'close',
            UiGlyphs.close,
            l10n.blocks_close,
            (_) => ctrl.setPicking(false),
            icon: true,
          ),
        ],
      ),
    );
  }
}

/// 空库：大图标 + 一句话 + 新建 / 导入 TXT / 整理导入。
class BlocksEmpty extends StatelessWidget {
  const BlocksEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = BlocksPageScope.of(context);
    final a = scope.actions;
    return Center(
      key: const Key('blocks-empty'),
      child: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(StudioIcons.promptBlocks, size: 30, color: c.accent),
            ),
            Text(
              l10n.blocks_emptyTitle,
              style: UiText.sans(16, weight: FontWeight.w700, color: c.ink),
            ),
            Text(
              l10n.blocks_emptyBody,
              textAlign: TextAlign.center,
              style: UiText.sans(12.5, color: c.muted, height: 1.7),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                UiBtn(
                  tone: UiBtnTone.primary,
                  onTap: () => scope.controller.openEdit(null),
                  children: [
                    const UiGlyph(UiGlyphs.plus, size: 14, strokeWidth: 2.2),
                    Text(l10n.blocks_newBlock),
                  ],
                ),
                UiBtn(
                  onTap: a.onImportTxt,
                  children: [
                    const UiGlyph(UiGlyphs.file, size: 14),
                    Text(l10n.blocks_importTxt),
                  ],
                ),
                UiBtn(
                  onTap: a.onImportCuration,
                  children: [
                    const UiGlyph(UiGlyphs.sort, size: 14),
                    Text(l10n.blocks_importCuration),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
