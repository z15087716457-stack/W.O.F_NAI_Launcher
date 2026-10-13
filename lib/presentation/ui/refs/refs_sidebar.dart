import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/studio_icons.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_lib_nav.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'refs_contract.dart';
import 'refs_format.dart';
import 'refs_page.dart';

/// 拖动中的卡片（一张，或多选时整组）。
@immutable
class RefsCardDrag {
  const RefsCardDrag(this.keys);
  final List<String> keys;
}

/// 拖动中的分类（拖到别的分类上 = 改父级）。
@immutable
class RefsCategoryDrag {
  const RefsCategoryDrag(this.id);
  final String id;
}

/// 左栏 240：标题行 52、视图、分类树 / 参考类型、来源、底部文件夹或说明。
class RefsSidebar extends StatelessWidget {
  const RefsSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = RefsScope.of(context);
    final data = scope.data;
    final a = scope.actions;
    final vibe = data.kind == RefsKind.vibe;
    return Container(
      key: const Key('refs-sidebar'),
      width: 240,
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
                  Icon(
                    vibe
                        ? StudioIcons.vibeLibrary
                        : StudioIcons.preciseReference,
                    size: 18,
                    color: c.accent,
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Tooltip(
                        message: vibe
                            ? l10n.refs_vibeTitle
                            : l10n.refs_preciseTitle,
                        child: Text(
                          vibe ? l10n.refs_vibeTitle : l10n.refs_preciseTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.sans(
                            14,
                            weight: FontWeight.w700,
                            color: c.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                  UiIconBox(
                    glyph: UiGlyphs.doubleLeft,
                    tooltip: l10n.refs_collapseSidebar,
                    onTap: () => a.onSidebarChanged(false),
                  ),
                ],
              ),
            ),
          ),
          _Views(data: data, actions: a),
          Expanded(
            child: SingleChildScrollView(
              child: vibe ? const _VibeSections() : const _PreciseSections(),
            ),
          ),
          if (vibe) const _FolderRow() else const _PreciseFooter(),
        ],
      ),
    );
  }
}

class _Views extends StatelessWidget {
  const _Views({required this.data, required this.actions});
  final RefsViewData data;
  final RefsActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final f = data.filter;
    final n = data.counts;
    final plain = f.categoryId == null && f.source == null && f.type == null;
    final empty = data.libraryEmpty;
    Widget item(RefsView v, String glyph, String label, int? count) =>
        UiNavItem(
          key: Key('refs-view-${v.name}'),
          glyph: glyph,
          label: label,
          selected: plain && f.view == v,
          trailing: UiNavCount(empty ? null : count),
          onTap: () => actions.onFilterChanged(
            f.copyWith(
              view: v,
              categoryId: () => null,
              source: () => null,
              type: () => null,
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 1,
      children: [
        item(RefsView.all, UiGlyphs.grid, l10n.refs_viewAll, n.all),
        item(
          RefsView.favorites,
          UiGlyphs.star,
          l10n.refs_viewFavorites,
          n.favorites,
        ),
        item(RefsView.recent, UiGlyphs.clock, l10n.refs_viewRecent, null),
        item(
          RefsView.inGeneration,
          UiGlyphs.check,
          l10n.refs_viewInGeneration,
          n.inGeneration,
        ),
      ],
    );
  }
}

class _VibeSections extends StatefulWidget {
  const _VibeSections();

  @override
  State<_VibeSections> createState() => _VibeSectionsState();
}

class _VibeSectionsState extends State<_VibeSections> {
  /// 正在新建的分类的父级（'' = 顶层），或正在重命名的分类 id。
  String? _creatingUnder;
  String? _renaming;
  String? _drop;

  bool _isDescendant(List<RefsCategory> all, String id, String? of) {
    var cur = of;
    while (cur != null) {
      if (cur == id) return true;
      cur = all.where((x) => x.id == cur).firstOrNull?.parentId;
    }
    return false;
  }

  int _depth(List<RefsCategory> all, RefsCategory cat) {
    var d = 0;
    var p = cat.parentId;
    while (p != null && d < 6) {
      d++;
      p = all.where((x) => x.id == p).firstOrNull?.parentId;
    }
    return d;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = RefsScope.of(context);
    final data = scope.data;
    final a = scope.actions;
    final f = data.filter;
    final cats = data.categories;

    Widget target({
      required String dropKey,
      required String? categoryId,
      required Widget Function(bool drop) child,
    }) => DragTarget<Object>(
      onWillAcceptWithDetails: (d) {
        final ok =
            d.data is RefsCardDrag ||
            (d.data is RefsCategoryDrag &&
                categoryId != null &&
                !_isDescendant(
                  cats,
                  (d.data as RefsCategoryDrag).id,
                  categoryId,
                ));
        if (ok) setState(() => _drop = dropKey);
        return ok;
      },
      onLeave: (_) => setState(() => _drop = null),
      onAcceptWithDetails: (d) {
        setState(() => _drop = null);
        switch (d.data) {
          case RefsCardDrag(:final keys):
            a.onMoveToCategory(keys, categoryId);
          case RefsCategoryDrag(:final id):
            a.onMoveCategory(id, categoryId);
        }
      },
      builder: (context, _, _) => child(_drop == dropKey),
    );

    Widget category(RefsCategory cat) {
      final indent = 20.0 * _depth(cats, cat);
      if (_renaming == cat.id) {
        return _NameField(
          initial: cat.name,
          indent: indent,
          onDone: (v) {
            setState(() => _renaming = null);
            if (v != null && v.isNotEmpty && v != cat.name) {
              a.onRenameCategory(cat.id, v);
            }
          },
        );
      }
      final row = target(
        dropKey: cat.id,
        categoryId: cat.id,
        child: (drop) => UiNavItem(
          key: Key('refs-cat-${cat.id}'),
          glyph: UiGlyphs.folder,
          label: cat.name,
          indent: indent,
          drop: drop,
          selected: f.categoryId == cat.id,
          trailing: UiNavCount(cat.count),
          onTap: () => a.onFilterChanged(
            f.copyWith(
              view: RefsView.all,
              categoryId: () => cat.id,
              source: () => null,
            ),
          ),
          onSecondaryTap: (pos) =>
              scope.controller.openMenu(UiPopoverAnchor(pos), [
                UiMenuItem(
                  glyph: UiGlyphs.plus,
                  label: l10n.refs_newSubcategory,
                  onTap: () => setState(() => _creatingUnder = cat.id),
                ),
                UiMenuItem(
                  glyph: UiGlyphs.pencil,
                  label: l10n.refs_rename,
                  onTap: () => setState(() => _renaming = cat.id),
                ),
                UiMenuItem(
                  glyph: UiGlyphs.trash,
                  label: l10n.refs_deleteCategory,
                  danger: true,
                  divider: true,
                  onTap: () => a.onDeleteCategory(cat.id),
                ),
              ]),
        ),
      );
      return Draggable<Object>(
        data: RefsCategoryDrag(cat.id),
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: _DragChip(label: cat.name),
        child: row,
      );
    }

    Widget newField(String under, double indent) => _NameField(
      initial: '',
      indent: indent,
      onDone: (v) {
        setState(() => _creatingUnder = null);
        if (v != null && v.isNotEmpty) {
          a.onCreateCategory(v, parentId: under.isEmpty ? null : under);
        }
      },
    );

    final children = <Widget>[
      UiSectionTitle(
        children: [
          Text(l10n.refs_categories),
          const Spacer(),
          UiPressable(
            key: const Key('refs-new-category'),
            onTap: () => setState(() => _creatingUnder = ''),
            builder: (context, hover) => Tooltip(
              message: l10n.refs_newCategory,
              child: UiGlyph(
                UiGlyphs.plus,
                size: 14,
                color: hover ? c.ink : c.faint,
              ),
            ),
          ),
        ],
      ),
    ];
    if (data.libraryEmpty && cats.isEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 0),
          child: Text(
            l10n.refs_noCategories,
            style: UiText.sans(12, color: c.faint, height: 1.5),
          ),
        ),
      );
      if (_creatingUnder == '') children.add(newField('', 0));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }
    for (final cat in cats) {
      children.add(category(cat));
      if (_creatingUnder == cat.id) {
        children.add(newField(cat.id, 20.0 * (_depth(cats, cat) + 1)));
      }
    }
    if (_creatingUnder == '') children.add(newField('', 0));
    children
      ..add(
        target(
          dropKey: '*uncategorized',
          categoryId: null,
          child: (drop) => UiNavItem(
            key: const Key('refs-cat-uncategorized'),
            glyph: UiGlyphs.inbox,
            label: l10n.refs_uncategorized,
            drop: drop,
            selected: f.categoryId == RefsCategory.uncategorized,
            trailing: UiNavCount(data.counts.uncategorized),
            onTap: () => a.onFilterChanged(
              f.copyWith(
                view: RefsView.all,
                categoryId: () => RefsCategory.uncategorized,
                source: () => null,
              ),
            ),
          ),
        ),
      )
      ..add(UiSectionTitle(children: [Text(l10n.refs_sources)]));
    for (final s in RefsVibeSource.values) {
      children.add(
        UiNavItem(
          key: Key('refs-src-${s.name}'),
          glyph: RefsFormat.sourceGlyph(s),
          label: RefsFormat.sourceNav(context, s),
          selected: f.source == s,
          trailing: UiNavCount(data.counts.sources[s] ?? 0),
          onTap: () => a.onFilterChanged(
            f.copyWith(
              view: RefsView.all,
              source: () => s,
              categoryId: () => null,
            ),
          ),
        ),
      );
    }
    children.add(const SizedBox(height: 8));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _PreciseSections extends StatelessWidget {
  const _PreciseSections();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = RefsScope.of(context);
    final data = scope.data;
    final f = data.filter;
    final type = data.importType;
    final note = f.type == null
        ? l10n.refs_importTypeNoteAll('\u0001')
        : l10n.refs_importTypeNoteSelected('\u0001');
    final parts = note.split('\u0001');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiSectionTitle(children: [Text(l10n.refs_types)]),
        for (final t in RefsPreciseType.values)
          UiNavItem(
            key: Key('refs-type-${t.name}'),
            glyph: RefsFormat.typeGlyph(t),
            glyphColor: RefsPalette.type(t),
            label: RefsFormat.type(context, t),
            selected: f.type == t,
            trailing: UiNavCount(
              data.libraryEmpty ? null : data.counts.types[t] ?? 0,
            ),
            onTap: () => scope.actions.onFilterChanged(
              f.copyWith(view: RefsView.all, type: () => t),
            ),
          ),
        Container(
          key: const Key('refs-import-type'),
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            color: c.control,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: parts.first),
                TextSpan(
                  text: RefsFormat.type(context, type),
                  style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
                ),
                if (parts.length > 1) TextSpan(text: parts[1]),
              ],
            ),
            style: UiText.sans(11.5, color: c.muted, height: 1.55),
          ),
        ),
      ],
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow();

  /// `E:\A.I\NovelAI\NAI\vibes` → `E:\…\NAI\vibes`。
  static String shorten(String p) {
    final sep = p.contains(r'\') ? r'\' : '/';
    final parts = p.split(sep);
    if (parts.length <= 3) return p;
    return [parts.first, '…', ...parts.sublist(parts.length - 2)].join(sep);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = RefsScope.of(context);
    final path = scope.data.folderPath;
    return Container(
      key: const Key('refs-folder'),
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        spacing: 6,
        children: [
          UiGlyph(UiGlyphs.folder, size: 13, color: c.faint),
          Expanded(
            child: Tooltip(
              message: path ?? '',
              child: Text(
                path == null ? '' : shorten(path),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.sans(11, color: c.faint),
              ),
            ),
          ),
          UiPressable(
            key: const Key('refs-open-folder'),
            onTap: () => scope.actions.onOpenFolder(null),
            builder: (context, hover) => Text(
              l10n.refs_open,
              style: UiText.sans(
                11,
                color: hover ? c.ink : c.accent,
                weight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreciseFooter extends StatelessWidget {
  const _PreciseFooter();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final costs = RefsScope.of(context).data.costs;
    final style = UiText.sans(11, color: c.faint, height: 1.5);
    return Container(
      key: const Key('refs-precise-footer'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Row(
            spacing: 6,
            children: [
              UiGlyph(UiGlyphs.infoCircle, size: 13, color: c.faint),
              Text(l10n.refs_preciseOnlyV45, style: style),
            ],
          ),
          Text(l10n.refs_preciseCostNote(costs.precise), style: style),
        ],
      ),
    );
  }
}

/// 分类名输入（新建 / 重命名）：回车确认，Esc 或失焦取消。
class _NameField extends StatefulWidget {
  const _NameField({
    required this.initial,
    required this.onDone,
    this.indent = 0,
  });
  final String initial;
  final ValueChanged<String?> onDone;
  final double indent;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final _ctrl = TextEditingController(text: widget.initial);
  final _focus = FocusNode();
  var _done = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _finish(null);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _finish(String? v) {
    if (_done) return;
    _done = true;
    widget.onDone(v?.trim());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        height: 32,
        padding: EdgeInsets.only(left: 10 + widget.indent, right: 10),
        decoration: BoxDecoration(
          color: c.raised,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: c.accent),
        ),
        child: Row(
          spacing: 9,
          children: [
            UiGlyph(UiGlyphs.folder, size: 15, color: c.muted),
            Expanded(
              child: Focus(
                onKeyEvent: (_, e) {
                  if (e is KeyDownEvent &&
                      e.logicalKey == LogicalKeyboardKey.escape) {
                    _finish(null);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  key: const Key('refs-category-name'),
                  controller: _ctrl,
                  focusNode: _focus,
                  style: UiText.sans(13, color: c.ink),
                  cursorColor: c.accent,
                  cursorHeight: 15,
                  decoration: uiBareDecoration(
                    hintText: context.l10n.refs_categoryNameHint,
                    hintStyle: UiText.sans(13, color: c.faint),
                  ),
                  onSubmitted: _finish,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DragChip extends StatelessWidget {
  const _DragChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: c.raised,
          border: Border.all(color: c.accent),
          borderRadius: BorderRadius.circular(7),
          boxShadow: const [
            BoxShadow(
              color: Color(0x29000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            UiGlyph(UiGlyphs.folder, size: 14, color: c.accent),
            Text(label, style: UiText.sans(12.5, color: c.ink)),
          ],
        ),
      ),
    );
  }
}
