import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../../widgets/common/studio_icons.dart';
import '../kit/ui_keycap.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_scrollable_row.dart';
import '../kit/ui_lib_nav.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'refs_contract.dart';
import 'refs_format.dart';
import 'refs_page.dart';
import 'refs_parts.dart';
import 'refs_sidebar.dart';
import 'refs_toolbar.dart';

/// 卡片墙区域：墙 + 多选操作条（托盘上方 20）。
class RefsWallArea extends StatelessWidget {
  const RefsWallArea({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = RefsScope.of(context);
    return Stack(
      children: [
        const Positioned.fill(child: RefsWall()),
        if (scope.controller.picking)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(child: RefsSelectionBar()),
          ),
      ],
    );
  }
}

/// 卡片网格：图片 4:5 + 两行文字，连续滚动不分页。
class RefsWall extends StatefulWidget {
  const RefsWall({super.key});

  static var _columns = 5;

  /// 方向键上下一次跨几张（当前列数）。
  static int columnsOf(BuildContext context) => _columns;

  @override
  State<RefsWall> createState() => _RefsWallState();
}

class _RefsWallState extends State<RefsWall> {
  final _scroll = ScrollController();
  String? _lastSelected;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _reveal(int index, int cols, double rowExtent, double viewport) {
    if (!_scroll.hasClients) return;
    final top = (index ~/ cols) * (rowExtent + RefsLayout.rowGap);
    final bottom = top + rowExtent + RefsLayout.padding.vertical;
    final o = _scroll.offset;
    final target = top < o
        ? top
        : bottom > o + viewport
        ? bottom - viewport
        : null;
    if (target != null) {
      _scroll.jumpTo(target.clamp(0, _scroll.position.maxScrollExtent));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = RefsScope.of(context);
    final data = scope.data;
    final items = data.entries;
    if (data.loading && items.isEmpty) {
      return const Center(child: UiSpinner());
    }
    if (items.isEmpty) return const _NoResults();
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth - RefsLayout.padding.horizontal;
        final cols = RefsLayout.columns(width, data.cardSize);
        RefsWall._columns = cols;
        final cw = (width - (cols - 1) * RefsLayout.colGap) / cols;
        final extent = RefsLayout.cardHeight(cw);
        if (data.selectedKey != _lastSelected) {
          _lastSelected = data.selectedKey;
          final i = items.indexWhere((e) => e.key == data.selectedKey);
          if (i >= 0) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => mounted ? _reveal(i, cols, extent, box.maxHeight) : null,
            );
          }
        }
        return GridView.builder(
          key: const Key('refs-wall'),
          controller: _scroll,
          padding: RefsLayout.padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: RefsLayout.colGap,
            mainAxisSpacing: RefsLayout.rowGap,
            mainAxisExtent: extent,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) =>
              RefsCard(key: ValueKey(items[i].key), entry: items[i]),
        );
      },
    );
  }
}

/// 筛选后没有结果。
class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = RefsScope.of(context);
    final f = scope.data.filter;
    return Center(
      child: Column(
        key: const Key('refs-no-results'),
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          UiGlyph(UiGlyphs.search, size: 28, color: c.faint),
          Text(
            f.query.isEmpty
                ? l10n.refs_noResults
                : l10n.refs_noResultsFor(f.query),
            style: UiText.sans(14, weight: FontWeight.w600, color: c.ink),
          ),
          UiBtn(
            size: UiBtnSize.small,
            onTap: () => scope.actions.onFilterChanged(const RefsFilter()),
            children: [Text(l10n.refs_clearFilters)],
          ),
        ],
      ),
    );
  }
}

/// 卡片：单击选中，双击加入生图页，Ctrl / Shift 单击多选；悬停出操作条；右键菜单；可拖到分类或托盘。
class RefsCard extends StatefulWidget {
  const RefsCard({super.key, required this.entry});
  final RefsEntry entry;

  @override
  State<RefsCard> createState() => _RefsCardState();
}

class _RefsCardState extends State<RefsCard> {
  var _hover = false;
  DateTime? _lastTap;

  void _tap(RefsScope scope) {
    final e = widget.entry;
    final ctrl = scope.controller;
    final hw = HardwareKeyboard.instance;
    if (hw.isShiftPressed) return ctrl.pickRange(e.key);
    if (hw.isControlPressed || hw.isMetaPressed || ctrl.picking) {
      return ctrl.togglePick(e.key);
    }
    final now = DateTime.now();
    if (_lastTap != null &&
        now.difference(_lastTap!) < const Duration(milliseconds: 320)) {
      _lastTap = null;
      ctrl.add([e.key]);
      return;
    }
    _lastTap = now;
    ctrl.select(e.key);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = RefsScope.of(context);
    final data = scope.data;
    final ctrl = scope.controller;
    final e = widget.entry;
    final vibe = data.kind == RefsKind.vibe;
    final picking = ctrl.picking;
    final picked = ctrl.picked.contains(e.key);
    final selected = picking ? picked : data.selectedKey == e.key;
    final hover = _hover && !picking;
    final reduce =
        data.reducedMotion || MediaQuery.disableAnimationsOf(context);

    final image = LayoutBuilder(
      builder: (context, box) => Stack(
        clipBehavior: Clip.none,
        children: [
          if (e.isBundle)
            for (final (i, t) in e.bundleThumbs.indexed.toList().reversed)
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(i == 0 ? 5 : 9, i == 0 ? -5 : -9),
                  child: Transform.rotate(
                    angle: (i == 0 ? 2.5 : 5) * math.pi / 180,
                    child: Opacity(
                      opacity: i == 0 ? .85 : .6,
                      child: _Paper(image: t),
                    ),
                  ),
                ),
              ),
          Positioned.fill(
            child: AnimatedContainer(
              duration: reduce
                  ? Duration.zero
                  : const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  if (selected) ...[
                    BoxShadow(
                      color: c.accent.withValues(alpha: .16),
                      spreadRadius: 5,
                    ),
                    BoxShadow(color: c.accent, spreadRadius: 2),
                  ] else if (hover)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: c.dark ? .45 : .14),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: c.control),
                    RefsImage(
                      e.thumb,
                      alignment: vibe
                          ? Alignment.center
                          : const Alignment(0, -.6),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: c.ink.withValues(alpha: .07)),
                      ),
                    ),
                    if (picking)
                      Positioned(
                        left: 7,
                        top: 7,
                        child: RefsPickMark(on: picked),
                      )
                    else if (e.inGeneration)
                      const Positioned(
                        left: 7,
                        top: 7,
                        child: RefsInGenBadge(),
                      ),
                    if (e.favorite || hover)
                      Positioned(
                        right: 7,
                        top: 7,
                        child: RefsStarButton(
                          on: e.favorite,
                          onTap: () =>
                              scope.actions.onSetFavorite([e.key], !e.favorite),
                        ),
                      ),
                    if (e.isBundle && !hover)
                      Positioned(
                        right: 7,
                        bottom: 7,
                        child: RefsDarkBadge(
                          glyph: UiGlyphs.stack,
                          text: '${e.bundleCount}',
                        ),
                      ),
                    if (hover)
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: _HoverBar(entry: e),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Widget card = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: Key('refs-card-${e.key}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _tap(scope),
        onSecondaryTapUp: (d) => ctrl.openMenu(
          UiPopoverAnchor(d.globalPosition),
          refsEntryMenu(context, e),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: image),
            _Caption(entry: e),
          ],
        ),
      ),
    );

    final keys = picking && picked ? ctrl.picked.toList() : [e.key];
    card = Draggable<Object>(
      data: RefsCardDrag(keys),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: RefsDragFeedback(image: e.thumb, count: keys.length),
      childWhenDragging: Opacity(opacity: .4, child: card),
      child: card,
    );
    return card;
  }
}

class _Paper extends StatelessWidget {
  const _Paper({required this.image});
  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(_saturate80),
        child: RefsImage(image),
      ),
    );
  }

  static const _saturate80 = <double>[
    0.8574, 0.1144, 0.0282, 0, 0, //
    0.0426, 0.9290, 0.0284, 0, 0,
    0.0426, 0.1144, 0.8430, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

class _Caption extends StatelessWidget {
  const _Caption({required this.entry});
  final RefsEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final data = RefsScope.of(context).data;
    final e = entry;
    final vibe = data.kind == RefsKind.vibe;
    final chip = vibe
        ? RefsEncodingChip(entry: e, model: data.model)
        : RefsTypeChip(e.type);
    TextSpan pair(String label, double v) => TextSpan(
      children: [
        TextSpan(text: '$label '),
        TextSpan(
          text: RefsFormat.two(v),
          style: TextStyle(fontWeight: FontWeight.w500, color: c.muted),
        ),
      ],
    );
    return SizedBox(
      height: RefsLayout.caption,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 7, 2, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 2,
          children: [
            SizedBox(
              height: 18.85,
              child: Row(
                spacing: 6,
                children: [
                  Expanded(
                    child: Text(
                      e.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.sans(
                        13,
                        weight: FontWeight.w600,
                        color: c.ink,
                        height: 1.45,
                      ),
                    ),
                  ),
                  chip,
                ],
              ),
            ),
            SizedBox(
              height: 15.4,
              child: Text.rich(
                TextSpan(
                  children: [
                    pair(l10n.refs_strengthShort, e.strength),
                    const TextSpan(text: '  '),
                    vibe
                        ? pair(l10n.refs_infoShort, e.infoExtracted)
                        : pair(l10n.refs_fidelityShort, e.fidelity),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: UiText.mono(11, color: c.faint, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverBar extends StatelessWidget {
  const _HoverBar({required this.entry});
  final RefsEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scope = RefsScope.of(context);
    final ctrl = scope.controller;
    final data = scope.data;
    final vibe = data.kind == RefsKind.vibe;
    final usable = vibe ? data.model.vibeUsable : data.model.preciseUsable;
    final e = entry;
    return RefsDarkBar(
      children: [
        RefsBarButton(
          key: const Key('refs-card-add'),
          primary: true,
          glyph: UiGlyphs.plus,
          label: vibe ? l10n.refs_addShort : l10n.refs_sendPrecise,
          onTap: usable ? () => ctrl.add([e.key]) : null,
        ),
        if (vibe)
          RefsBarButton(
            key: const Key('refs-card-detail'),
            glyph: UiGlyphs.eye,
            tooltip: e.isBundle ? l10n.refs_openBundle : l10n.refs_detail,
            onTap: () => ctrl.openDetail(e.key),
          ),
        const Spacer(),
        Builder(
          builder: (ctx) => RefsBarButton(
            key: const Key('refs-card-more'),
            glyph: UiGlyphs.more,
            glyphSize: 15,
            tooltip: l10n.refs_more,
            onTap: () =>
                ctrl.openMenu(anchorBelow(ctx), refsEntryMenu(context, e)),
          ),
        ),
      ],
    );
  }
}

/// 卡片右键 / ⋯ 菜单（Vibe 和精准参考各一套）。
List<UiMenuItem> refsEntryMenu(BuildContext context, RefsEntry e) {
  final l10n = context.l10n;
  final scope = RefsScope.of(context);
  final a = scope.actions;
  final ctrl = scope.controller;
  final data = scope.data;
  final vibe = data.kind == RefsKind.vibe;
  final usable = vibe ? data.model.vibeUsable : data.model.preciseUsable;
  return [
    UiMenuItem(
      glyph: UiGlyphs.plus,
      label: vibe ? l10n.refs_addToGeneration : l10n.refs_sendPrecise,
      trailing: 'Enter',
      enabled: usable,
      onTap: () => ctrl.add([e.key]),
    ),
    UiMenuItem(
      glyph: UiGlyphs.swap,
      label: vibe ? l10n.refs_replaceVibes : l10n.refs_replacePrecise,
      enabled: usable,
      onTap: () => ctrl.add([e.key], replace: true),
    ),
    if (!vibe) ...[
      UiMenuItem(
        glyph: UiGlyphs.picture,
        label: l10n.refs_sendImg2Img,
        onTap: () => a.onSendImg2Img(e.key),
      ),
      UiMenuItem(
        glyph: UiGlyphs.spark,
        label: l10n.refs_saveAsVibe,
        onTap: () => a.onSaveAsVibe(e.key),
      ),
    ],
    UiMenuItem(
      glyph: e.isBundle ? UiGlyphs.stack : UiGlyphs.eye,
      label: e.isBundle ? l10n.refs_openBundle : l10n.refs_detail,
      trailing: 'Space',
      divider: true,
      onTap: () => ctrl.openDetail(e.key),
    ),
    UiMenuItem(
      glyph: UiGlyphs.star,
      label: e.favorite ? l10n.refs_unfavorite : l10n.refs_favorite,
      trailing: 'F',
      onTap: () => a.onSetFavorite([e.key], !e.favorite),
    ),
    if (vibe) ...[
      UiMenuItem(
        glyph: UiGlyphs.picture,
        label: l10n.refs_replacePreview,
        onTap: () => a.onReplacePreview(e.key),
      ),
      UiMenuItem(
        glyph: UiGlyphs.upload,
        label: l10n.refs_exportEllipsis,
        trailing: 'Ctrl E',
        onTap: () => ctrl.openExport([e.key]),
      ),
      UiMenuItem(
        glyph: UiGlyphs.folder,
        label: l10n.refs_showInFolder,
        onTap: () => a.onOpenFolder(e.key),
      ),
    ] else
      UiMenuItem(
        glyph: UiGlyphs.copy,
        label: l10n.refs_copyImage,
        onTap: () => a.onCopyImage(e.key),
      ),
    UiMenuItem(
      glyph: UiGlyphs.trash,
      label: l10n.refs_delete,
      trailing: 'Del',
      danger: true,
      divider: true,
      onTap: () => ctrl.confirmDelete([e.key]),
    ),
  ];
}

/// 多选操作条：深色胶囊，“已选 N · 加入生图页 ┊ 收藏 · 移到 · 导出 ┊ 删除 · ×”。
class RefsSelectionBar extends StatelessWidget {
  const RefsSelectionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = RefsScope.of(context);
    final ctrl = scope.controller;
    final data = scope.data;
    final a = scope.actions;
    final keys = ctrl.picked.toList();
    final vibe = data.kind == RefsKind.vibe;
    final usable = vibe ? data.model.vibeUsable : data.model.preciseUsable;
    final none = keys.isEmpty;
    final allFav =
        !none &&
        data.entries
            .where((e) => keys.contains(e.key))
            .every((e) => e.favorite);
    Widget btn(
      String key,
      String glyph,
      String? label, {
      VoidCallback? onTap,
      bool primary = false,
      Color? color,
    }) => UiPressable(
      key: Key('refs-sel-$key'),
      onTap: onTap,
      builder: (context, hover) {
        final fg = onTap == null
            ? c.bg.withValues(alpha: .4)
            : (primary ? Colors.white : (color ?? c.bg));
        return Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: primary
                ? (onTap == null ? c.brand.withValues(alpha: .5) : c.brand)
                : (hover && onTap != null ? c.bg.withValues(alpha: .12) : null),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              UiGlyph(
                glyph,
                size: 14,
                color: fg,
                strokeWidth: primary ? 2.4 : 2,
              ),
              if (label != null)
                Text(
                  label,
                  style: UiText.sans(12.5, weight: FontWeight.w500, color: fg),
                ),
            ],
          ),
        );
      },
    );
    Widget sep() => Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: c.bg.withValues(alpha: .25),
    );
    return Container(
      key: const Key('refs-selection-bar'),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: c.ink,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.dark ? .5 : .18),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: UiScrollableRow(
        shrinkWrap: true,
        spacing: 4,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              l10n.refs_selected(keys.length),
              style: UiText.sans(12, color: c.bg.withValues(alpha: .8)),
            ),
          ),
          btn(
            'add',
            UiGlyphs.plus,
            vibe ? l10n.refs_addToGeneration : l10n.refs_sendPrecise,
            primary: true,
            onTap: none || !usable ? null : () => ctrl.add(keys),
          ),
          sep(),
          btn(
            'favorite',
            UiGlyphs.star,
            allFav ? l10n.refs_unfavorite : l10n.refs_favorite,
            onTap: none ? null : () => a.onSetFavorite(keys, !allFav),
          ),
          if (vibe) ...[
            Builder(
              builder: (ctx) => btn(
                'move',
                UiGlyphs.folder,
                l10n.refs_moveTo,
                onTap: none
                    ? null
                    : () {
                        final box = ctx.findRenderObject()! as RenderBox;
                        ctrl.openMenu(
                          UiPopoverAnchor(
                            box.localToGlobal(const Offset(0, -8)),
                            alignBottom: true,
                          ),
                          refsCategoryMenu(
                            context,
                            (id) => a.onMoveToCategory(keys, id),
                          ),
                        );
                      },
              ),
            ),
            btn(
              'export',
              UiGlyphs.upload,
              l10n.refs_export,
              onTap: none ? null : () => ctrl.openExport(keys),
            ),
          ],
          sep(),
          btn(
            'delete',
            UiGlyphs.trash,
            l10n.refs_delete,
            color: const Color(0xFFFF8A8A),
            onTap: none ? null : () => ctrl.confirmDelete(keys),
          ),
          Opacity(
            opacity: .7,
            child: btn(
              'close',
              UiGlyphs.close,
              null,
              onTap: () => ctrl.setPicking(false),
            ),
          ),
        ],
      ),
    );
  }
}

/// “移到分类”菜单：未分类 + 分类树。
List<UiMenuItem> refsCategoryMenu(
  BuildContext context,
  ValueChanged<String?> onPick, {
  String? current,
  bool markCurrent = false,
}) {
  final l10n = context.l10n;
  final cats = RefsScope.of(context).data.categories;
  int depth(RefsCategory c) {
    var d = 0;
    var p = c.parentId;
    while (p != null && d < 6) {
      d++;
      p = cats.where((x) => x.id == p).firstOrNull?.parentId;
    }
    return d;
  }

  return [
    for (final cat in cats)
      UiMenuItem(
        glyph: UiGlyphs.folder,
        label: cat.name,
        indent: 18.0 * depth(cat),
        checked: markCurrent && current == cat.id,
        onTap: () => onPick(cat.id),
      ),
    UiMenuItem(
      glyph: UiGlyphs.inbox,
      label: l10n.refs_uncategorized,
      divider: cats.isNotEmpty,
      checked: markCurrent && current == null,
      onTap: () => onPick(null),
    ),
  ];
}

/// 空库：拖放区 + 选择文件 / 粘贴 + 别的入口，下面一段说清楚 Vibe 和精准参考的区别。
class RefsEmptyState extends StatelessWidget {
  const RefsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = RefsScope.of(context);
    final a = scope.actions;
    final vibe = scope.data.kind == RefsKind.vibe;
    final costs = scope.data.costs;
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: SizedBox(
                width: 620,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 16,
                  children: [
                    UiDashedBox(
                      key: const Key('refs-empty'),
                      radius: 18,
                      padding: const EdgeInsets.fromLTRB(36, 40, 36, 32),
                      child: Column(
                        spacing: 14,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: c.accent.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              vibe
                                  ? StudioIcons.vibeLibrary
                                  : StudioIcons.preciseReference,
                              size: 30,
                              color: c.accent,
                            ),
                          ),
                          Text(
                            vibe
                                ? l10n.refs_emptyVibeTitle
                                : l10n.refs_emptyPreciseTitle,
                            style: UiText.sans(
                              19,
                              weight: FontWeight.w700,
                              color: c.ink,
                            ),
                          ),
                          Text(
                            vibe
                                ? l10n.refs_emptyVibeDesc
                                : l10n.refs_emptyPreciseDesc,
                            textAlign: TextAlign.center,
                            style: UiText.sans(13, color: c.muted, height: 1.6),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              key: const Key('refs-empty-actions'),
                              mainAxisSize: MainAxisSize.min,
                              spacing: 8,
                              children: [
                                UiBtn(
                                  key: const Key('refs-empty-pick'),
                                  size: UiBtnSize.large,
                                  tone: UiBtnTone.primary,
                                  onTap: () => a.onImport(
                                    vibe
                                        ? RefsImportSource.files
                                        : RefsImportSource.images,
                                  ),
                                  children: [
                                    const UiGlyph(UiGlyphs.folder, size: 15),
                                    Text(l10n.refs_pickFiles),
                                  ],
                                ),
                                UiBtn(
                                  key: const Key('refs-empty-paste'),
                                  size: UiBtnSize.large,
                                  onTap: () =>
                                      a.onImport(RefsImportSource.clipboard),
                                  children: [
                                    const UiGlyph(UiGlyphs.clipboard, size: 15),
                                    Text(l10n.refs_pasteClipboard),
                                    const UiKeycaps(['Ctrl', 'V']),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 2),
                            child: Container(height: 1, color: c.line),
                          ),
                          Wrap(
                            key: const Key('refs-empty-entries'),
                            alignment: WrapAlignment.center,
                            spacing: 18,
                            runSpacing: 6,
                            children: [
                              _Entry(
                                StudioIcons.generation,
                                vibe
                                    ? l10n.refs_emptyFromResultVibe
                                    : l10n.refs_emptyFromResultPrecise,
                              ),
                              _Entry(
                                StudioIcons.localGallery,
                                l10n.refs_emptyFromGallery,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      key: const Key('refs-empty-help'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: c.panel,
                        border: Border.all(color: c.line),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 10,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: UiGlyph(
                              UiGlyphs.help,
                              size: 15,
                              color: c.muted,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.refs_emptyHelpTitle,
                                  style: UiText.sans(
                                    12,
                                    weight: FontWeight.w600,
                                    color: c.ink,
                                    height: 1.55,
                                  ),
                                ),
                                Text(
                                  l10n.refs_emptyHelpBody(costs.precise),
                                  style: UiText.sans(
                                    12,
                                    color: c.muted,
                                    height: 1.55,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Icon(icon, size: 14, color: c.muted),
        Text(label, style: UiText.sans(12, color: c.muted)),
      ],
    );
  }
}

/// 拖文件进窗口：虚线强调框盖住页面，先说清认出了什么、松手后会怎样。
class RefsDropOverlay extends StatelessWidget {
  const RefsDropOverlay({super.key, required this.summary});
  final RefsDropSummary summary;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final s = summary;
    final vibe = RefsScope.of(context).data.kind == RefsKind.vibe;
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              c.accent.withValues(alpha: .07),
              c.bg.withValues(alpha: .8),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: UiDashedBox(
            key: const Key('refs-drop'),
            radius: 16,
            strokeWidth: 2,
            dash: 7,
            gap: 5,
            color: c.accent,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 10,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const UiGlyph(
                      UiGlyphs.download,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    l10n.refs_dropTitle(s.total),
                    style: UiText.sans(
                      20,
                      weight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                  Text(
                    vibe ? l10n.refs_dropVibeDesc : l10n.refs_dropPreciseDesc,
                    style: UiText.sans(13, color: c.muted),
                  ),
                  if (vibe)
                    Wrap(
                      spacing: 6,
                      children: [
                        if (s.vibePngs > 0)
                          UiMini(
                            l10n.refs_dropVibePngs(s.vibePngs),
                            tone: UiMiniTone.ok,
                          ),
                        if (s.vibeFiles > 0)
                          UiMini(
                            l10n.refs_dropVibeFiles(s.vibeFiles),
                            tone: UiMiniTone.ok,
                          ),
                        if (s.bundles > 0)
                          UiMini(
                            l10n.refs_dropBundles(s.bundles),
                            tone: UiMiniTone.accent,
                          ),
                        if (s.images > 0)
                          UiMini(
                            l10n.refs_dropImages(s.images),
                            tone: UiMiniTone.warn,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
