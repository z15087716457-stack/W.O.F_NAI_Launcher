import 'package:flutter/material.dart';

import '../../widgets/common/studio_icons.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_nav.dart';
import '../kit/ui_resource_kind.dart';
import '../kit/ui_text.dart';
import '../refs/refs_contract.dart';
import '../refs/refs_format.dart';
import 'resource_window_contract.dart';

String resourceCount(int n) {
  final s = '$n';
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// 资源窗口左栏：分组树。外观按各主页面：图库同本地画廊侧栏（30 高、左侧选中条、
/// 箭头槽 16、缩进 14），其余同块库 / 参考库的 [UiNavItem]（32 高、缩进 16）。
///
/// 子级默认展开状态来自 [ResourceGroup.expanded]（主程序记住的那份）；在这里展开 / 收起
/// 只影响本窗口，不写回主程序。窄窗（[collapsed]）只剩图标：资料库条目 + 当前选中项。
class ResourceWindowSide extends StatefulWidget {
  const ResourceWindowSide({
    super.key,
    required this.data,
    required this.actions,
    required this.collapsed,
  });
  final ResourceWindowViewData data;
  final ResourceWindowActions actions;
  final bool collapsed;

  static const width = 224.0;
  static const collapsedWidth = 56.0;

  @override
  State<ResourceWindowSide> createState() => _ResourceWindowSideState();
}

class _ResourceWindowSideState extends State<ResourceWindowSide> {
  /// `kind/groupId` → 本窗口里的展开覆盖。
  final _open = <String, bool>{};

  bool _isOpen(ResourceGroup g) =>
      _open['${widget.data.kind.name}/${g.id}'] ?? g.expanded;

  void _toggle(ResourceGroup g) =>
      setState(() => _open['${widget.data.kind.name}/${g.id}'] = !_isOpen(g));

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final d = widget.data;
    final gallery = d.kind == FloatingResourceKind.gallery;
    final rows = <Widget>[];
    for (final s in d.sections) {
      if (widget.collapsed) {
        final shown = s.id == 'library'
            ? s.groups
            : s.groups.where((g) => g.id == d.groupId).toList();
        if (shown.isEmpty) continue;
        if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
        for (final g in shown) {
          rows.add(
            _IconRow(kind: d.kind, group: g, data: d, a: widget.actions),
          );
        }
        continue;
      }
      if (s.id != 'library' && s.title.isNotEmpty) {
        rows.add(
          gallery
              ? _GalleryHeader(s.title)
              : UiSectionTitle(children: [Text(s.title)]),
        );
      } else if (gallery && s.id == 'library' && s.title.isNotEmpty) {
        rows.add(_GalleryHeader(s.title));
      }
      final children = <String?, List<ResourceGroup>>{};
      for (final g in s.groups) {
        (children[g.parentId] ??= []).add(g);
      }
      final ids = {for (final g in s.groups) g.id};
      void walk(ResourceGroup g, int depth) {
        final kids = children[g.id] ?? const [];
        final open = kids.isNotEmpty && _isOpen(g);
        rows.add(
          gallery
              ? _GalleryRow(
                  kind: d.kind,
                  group: g,
                  depth: depth,
                  selected: g.id == d.groupId,
                  hasChildren: kids.isNotEmpty,
                  open: open,
                  chevronSlot: s.id != 'library',
                  onTap: () => widget.actions.onGroup(g.id),
                  onToggle: () => _toggle(g),
                )
              : _NavRow(
                  kind: d.kind,
                  group: g,
                  depth: depth,
                  selected: g.id == d.groupId,
                  hasChildren: kids.isNotEmpty,
                  open: open,
                  chevronSlot: s.id != 'library',
                  onTap: () => widget.actions.onGroup(g.id),
                  onToggle: () => _toggle(g),
                ),
        );
        if (open) {
          for (final k in kids) {
            walk(k, depth + 1);
          }
        }
      }

      // 父级不在本区里的（数据不完整）也当根级显示，不丢行。
      for (final g in s.groups) {
        if (g.parentId == null || !ids.contains(g.parentId)) walk(g, 0);
      }
    }
    return Container(
      key: const Key('rw-side'),
      width: widget.collapsed
          ? ResourceWindowSide.collapsedWidth
          : ResourceWindowSide.width,
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(right: BorderSide(color: c.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: ListView(
                key: const Key('rw-side-list'),
                padding: EdgeInsets.fromLTRB(
                  gallery && !widget.collapsed ? 8 : 0,
                  4,
                  gallery && !widget.collapsed ? 8 : 0,
                  12,
                ),
                children: rows,
              ),
            ),
          ),
          if (d.statusNote != null && !widget.collapsed)
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border)),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                d.statusNote!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.sans(11, color: c.faint),
              ),
            ),
        ],
      ),
    );
  }
}

/// 行图标：图库用本地画廊的图标字体，其余用库页同款线条图标。
Widget resourceGroupIcon(
  BuildContext context,
  FloatingResourceKind kind,
  ResourceGroup g, {
  required bool selected,
  double size = 15,
}) {
  final c = context.ui;
  final gallery = kind == FloatingResourceKind.gallery;
  final color = selected ? c.ink : c.muted;
  if (gallery) {
    final icon = switch (g.icon) {
      ResourceGroupIcon.all => StudioIcons.galleryImage,
      ResourceGroupIcon.favorite =>
        selected ? StudioIcons.galleryHeartFilled : StudioIcons.galleryHeart,
      ResourceGroupIcon.collection => StudioIcons.galleryCollection,
      ResourceGroupIcon.uncategorized => StudioIcons.galleryArchive,
      _ => StudioIcons.galleryFolder,
    };
    return Icon(icon, size: size + 1, color: color);
  }
  final type = switch (g.icon) {
    ResourceGroupIcon.typeCharacter => RefsPreciseType.character,
    ResourceGroupIcon.typeStyle => RefsPreciseType.style,
    ResourceGroupIcon.typeBoth => RefsPreciseType.both,
    _ => null,
  };
  if (type != null) {
    return UiGlyph(
      RefsFormat.typeGlyph(type),
      size: size,
      color: RefsPalette.type(type),
    );
  }
  if (g.icon == null && g.color != null) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: g.color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
  final glyph = switch (g.icon) {
    ResourceGroupIcon.all => UiGlyphs.grid,
    ResourceGroupIcon.favorite => UiGlyphs.star,
    ResourceGroupIcon.recent => UiGlyphs.clock,
    ResourceGroupIcon.collection => UiGlyphs.layers,
    ResourceGroupIcon.uncategorized => UiGlyphs.minus,
    ResourceGroupIcon.inGeneration => UiGlyphs.check,
    _ => g.glyph ?? UiGlyphs.folder,
  };
  return UiGlyph(glyph, size: size, color: c.muted);
}

/// 本地画廊侧栏小节标题：12 弱色、上 12。
class _GalleryHeader extends StatelessWidget {
  const _GalleryHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 2, left: 8),
    child: SizedBox(
      height: 26,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label, style: UiText.sans(12, color: context.ui.muted)),
      ),
    ),
  );
}

/// 本地画廊侧栏行（`gallery_category_tree_view` `_CategoryItem` 同款）。
class _GalleryRow extends StatelessWidget {
  const _GalleryRow({
    required this.kind,
    required this.group,
    required this.depth,
    required this.selected,
    required this.hasChildren,
    required this.open,
    required this.chevronSlot,
    required this.onTap,
    required this.onToggle,
  });
  final FloatingResourceKind kind;
  final ResourceGroup group;
  final int depth;
  final bool selected, hasChildren, open, chevronSlot;
  final VoidCallback onTap, onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final g = group;
    return Opacity(
      opacity: g.dim && !selected ? .55 : 1,
      child: UiPressable(
        key: Key('rw-group-${g.id}'),
        onTap: onTap,
        builder: (context, hover) => Container(
          height: 30,
          decoration: BoxDecoration(
            color: selected
                ? c.control
                : hover
                ? c.control.withValues(alpha: .55)
                : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 6 + depth * 14.0, right: 8),
                child: Row(
                  children: [
                    if (chevronSlot)
                      SizedBox(
                        width: 16,
                        child: hasChildren
                            ? GestureDetector(
                                key: Key('rw-toggle-${g.id}'),
                                behavior: HitTestBehavior.opaque,
                                onTap: onToggle,
                                child: Icon(
                                  open
                                      ? StudioIcons.galleryChevronDown
                                      : StudioIcons.galleryChevronRight,
                                  size: 15,
                                  color: c.muted,
                                ),
                              )
                            : null,
                      ),
                    const SizedBox(width: 3),
                    resourceGroupIcon(context, kind, g, selected: selected),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        g.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(
                          13,
                          weight: selected ? FontWeight.w500 : FontWeight.w400,
                          color: c.ink,
                        ),
                      ),
                    ),
                    if (g.count != null)
                      Text(
                        resourceCount(g.count!),
                        style: UiText.mono(12, color: c.muted, height: 1),
                      ),
                  ],
                ),
              ),
              if (selected)
                Positioned(
                  left: 0,
                  top: 7,
                  bottom: 7,
                  width: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 块库 / 参考库侧栏行（[UiNavItem]，文件夹行同 `blocks_nav` 的箭头 + 图标）。
class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.kind,
    required this.group,
    required this.depth,
    required this.selected,
    required this.hasChildren,
    required this.open,
    required this.chevronSlot,
    required this.onTap,
    required this.onToggle,
  });
  final FloatingResourceKind kind;
  final ResourceGroup group;
  final int depth;
  final bool selected, hasChildren, open, chevronSlot;
  final VoidCallback onTap, onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final g = group;
    final icon = resourceGroupIcon(context, kind, g, selected: selected);
    return Opacity(
      opacity: g.dim && !selected ? .55 : 1,
      child: UiNavItem(
        key: Key('rw-group-${g.id}'),
        indent: depth * 16.0,
        leading: chevronSlot
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    child: hasChildren
                        ? UiPressable(
                            key: Key('rw-toggle-${g.id}'),
                            onTap: onToggle,
                            builder: (_, h) => UiGlyph(
                              open
                                  ? UiGlyphs.chevronDown
                                  : UiGlyphs.chevronRight,
                              size: 12,
                              color: h ? c.ink : c.faint,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 2),
                  icon,
                ],
              )
            : icon,
        label: g.label,
        selected: selected,
        trailing: UiNavCount(g.count),
        onTap: onTap,
      ),
    );
  }
}

/// 窄窗：只剩图标的一行（悬停给全名）。
class _IconRow extends StatelessWidget {
  const _IconRow({
    required this.kind,
    required this.group,
    required this.data,
    required this.a,
  });
  final FloatingResourceKind kind;
  final ResourceGroup group;
  final ResourceWindowViewData data;
  final ResourceWindowActions a;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final on = group.id == data.groupId;
    return Tooltip(
      message: group.label,
      waitDuration: const Duration(milliseconds: 400),
      child: UiPressable(
        key: Key('rw-group-${group.id}'),
        onTap: () => a.onGroup(group.id),
        builder: (context, hover) => Container(
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? c.control : (hover ? c.hover : null),
            borderRadius: BorderRadius.circular(7),
          ),
          child: resourceGroupIcon(context, kind, group, selected: on),
        ),
      ),
    );
  }
}
