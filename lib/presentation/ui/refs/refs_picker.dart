import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/studio_icons.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_dialog.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_keycap.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'refs_contract.dart';
import 'refs_format.dart';
import 'refs_parts.dart';

/// 生图页“从库添加”选择器 640 × 760：和库页同一套卡片；搜索、分类筛选、最近用过、
/// 底部写清加入后的数量和费用，可以追加或替换现有。
class RefsPicker extends StatefulWidget {
  const RefsPicker({super.key, required this.data, required this.actions});
  final RefsPickerData data;
  final RefsPickerActions actions;

  @override
  State<RefsPicker> createState() => _RefsPickerState();
}

enum _Chip { all, favorites, bundles }

class _RefsPickerState extends State<RefsPicker> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _picked = <String>[];
  Object _chip = _Chip.all;

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  bool _match(RefsEntry e) {
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty &&
        !e.name.toLowerCase().contains(q) &&
        !e.tags.any((t) => t.toLowerCase().contains(q))) {
      return false;
    }
    return switch (_chip) {
      _Chip.favorites => e.favorite,
      _Chip.bundles => e.isBundle,
      final RefsPreciseType t => e.type == t,
      final String id => e.categoryId == id,
      _ => true,
    };
  }

  void _toggle(String key) {
    final d = widget.data;
    if (d.single) return widget.actions.onConfirm([key], replace: true);
    setState(() {
      if (!_picked.remove(key)) _picked.add(key);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final d = widget.data;
    final a = widget.actions;
    final k = d.costs;
    final vibe = d.kind == RefsKind.vibe;
    final list = d.entries.where(_match).toList();
    final byKey = {for (final e in d.entries) e.key: e};
    final recent = [for (final r in d.recent) ?byKey[r]];
    final picked = [for (final p in _picked) ?byKey[p]];
    final adding = picked.where((e) => !e.inGeneration).toList();
    final after = d.inUse + adding.length;
    final encodes = adding
        .where(
          (e) =>
              e.encoding == RefsEncoding.encodeOnUse ||
              e.encoding == RefsEncoding.reencode,
        )
        .toList();

    Widget chip(Object id, String label) => UiFilterChip(
      key: Key('refs-picker-chip-${id is Enum ? id.name : id}'),
      label: label,
      selected: _chip == id,
      onTap: () => setState(() => _chip = id),
    );

    final costLine = vibe
        ? [
            for (final e in encodes.take(1))
              l10n.refs_pickerEncode(e.name, d.model.shortName, k.encode),
            if (encodes.length > 1)
              l10n.refs_pickerEncodeMore(encodes.length - 1),
            if (after > k.freeVibes)
              l10n.refs_pickerExtra(k.freeVibes, k.extraPerVibe),
          ].join(' · ')
        : l10n.refs_pickerPreciseCost(k.precise, after * k.precise);

    return RefsPickerFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiDialogHeader(
            children: [
              Text(
                vibe ? l10n.refs_pickerVibeTitle : l10n.refs_pickerPreciseTitle,
              ),
              const Spacer(),
              UiBtn(
                key: const Key('refs-picker-open'),
                size: UiBtnSize.small,
                tone: UiBtnTone.ghost,
                onTap: a.onOpenLibrary,
                children: [
                  Icon(
                    vibe
                        ? StudioIcons.vibeLibrary
                        : StudioIcons.preciseReference,
                    size: 13,
                  ),
                  Text(
                    vibe
                        ? l10n.refs_openVibeLibrary
                        : l10n.refs_openPreciseLibrary,
                  ),
                ],
              ),
              UiIconBox(
                key: const Key('refs-picker-close'),
                glyph: UiGlyphs.close,
                glyphSize: 16,
                tooltip: l10n.refs_close,
                onTap: a.onClose,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                Container(
                  key: const Key('refs-picker-search'),
                  height: 32,
                  padding: const EdgeInsets.only(left: 10, right: 6),
                  decoration: BoxDecoration(
                    color: c.control,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    spacing: 7,
                    children: [
                      UiGlyph(UiGlyphs.search, size: 15, color: c.faint),
                      Expanded(
                        child: TextField(
                          controller: _search,
                          focusNode: _searchFocus,
                          autofocus: true,
                          style: UiText.sans(12.5, color: c.ink),
                          cursorColor: c.accent,
                          cursorHeight: 14,
                          decoration: uiBareDecoration(
                            hintText: vibe
                                ? l10n.refs_searchVibe
                                : l10n.refs_searchPrecise,
                            hintStyle: UiText.sans(12.5, color: c.faint),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const UiKeycaps(['Ctrl', 'F']),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  key: const Key('refs-picker-chips'),
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    spacing: 4,
                    children: [
                      chip(_Chip.all, l10n.refs_quickAll),
                      chip(_Chip.favorites, l10n.refs_quickFavorites),
                      if (vibe) ...[
                        for (final cat in d.categories) chip(cat.id, cat.name),
                        chip(_Chip.bundles, l10n.refs_quickBundles),
                      ] else
                        for (final t in RefsPreciseType.values)
                          chip(t, RefsFormat.type(context, t)),
                    ],
                  ),
                ),
                if (recent.isNotEmpty)
                  Column(
                    key: const Key('refs-picker-recent'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 6,
                    children: [
                      Text(
                        l10n.refs_recentUsed,
                        style: UiText.sans(
                          11.5,
                          weight: FontWeight.w600,
                          color: c.muted,
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          spacing: 6,
                          children: [
                            for (final e in recent)
                              _RecentThumb(
                                entry: e,
                                picked: _picked.contains(e.key),
                                onTap: () => _toggle(e.key),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(
                      l10n.refs_noResults,
                      style: UiText.sans(13, color: c.muted),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, box) {
                      const cols = 5;
                      final cw = (box.maxWidth - 32 - 10 * (cols - 1)) / cols;
                      return GridView.builder(
                        key: const Key('refs-picker-grid'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 10,
                          mainAxisExtent: cw * 1.25 + _PickerCard.caption,
                        ),
                        itemCount: list.length,
                        itemBuilder: (context, i) => _PickerCard(
                          key: Key('refs-picker-card-${list[i].key}'),
                          entry: list[i],
                          kind: d.kind,
                          model: d.model,
                          picked: _picked.contains(list[i].key),
                          single: d.single,
                          onTap: () => _toggle(list[i].key),
                        ),
                      );
                    },
                  ),
          ),
          UiDialogFooter(
            children: [
              Expanded(
                child: Column(
                  key: const Key('refs-picker-summary'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: l10n.refs_pickedN(picked.length),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: vibe
                                ? l10n.refs_pickerAfterVibe(after, k.maxVibes)
                                : l10n.refs_pickerAfterPrecise(after),
                          ),
                        ],
                      ),
                      style: UiText.sans(
                        12,
                        color: vibe && after > k.maxVibes ? c.error : c.ink,
                      ),
                    ),
                    if (costLine.isNotEmpty)
                      Text(
                        costLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(11, color: c.muted),
                      ),
                  ],
                ),
              ),
              if (!d.single) ...[
                UiBtn(
                  key: const Key('refs-picker-replace'),
                  onTap: picked.isEmpty
                      ? null
                      : () => a.onConfirm([..._picked], replace: true),
                  children: [
                    const UiGlyph(UiGlyphs.swap, size: 14),
                    Text(l10n.refs_replaceExisting),
                  ],
                ),
                UiBtn(
                  key: const Key('refs-picker-append'),
                  tone: UiBtnTone.primary,
                  onTap: picked.isEmpty
                      ? null
                      : () => a.onConfirm([..._picked], replace: false),
                  children: [
                    const UiGlyph(UiGlyphs.plus, size: 14, strokeWidth: 2.4),
                    Text(l10n.refs_appendN(picked.length)),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// 选择器外框：640 × 760、圆角 14（窗口矮时随宿主变矮）。
class RefsPickerFrame extends StatelessWidget {
  const RefsPickerFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const Key('refs-picker'),
    width: 640,
    height: 760,
    child: UiPopoverSurface(radius: 14, child: child),
  );
}

class _RecentThumb extends StatelessWidget {
  const _RecentThumb({
    required this.entry,
    required this.picked,
    required this.onTap,
  });
  final RefsEntry entry;
  final bool picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      key: Key('refs-picker-recent-${entry.key}'),
      onTap: onTap,
      builder: (_, hover) => Tooltip(
        message: entry.name,
        child: Container(
          width: 62,
          height: 76,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: c.control,
            borderRadius: BorderRadius.circular(7),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: picked ? c.accent : c.line,
              width: picked ? 2 : 1,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              RefsImage(entry.thumb),
              if (entry.inGeneration)
                Positioned(
                  left: 3,
                  top: 3,
                  child: Container(
                    height: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      context.l10n.refs_inUse,
                      style: UiText.sans(
                        9.5,
                        weight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.1,
                      ),
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

/// 选择器里的紧凑卡片：名称一行 + 编码标签（或“强度 · 信息”）一行。
class _PickerCard extends StatefulWidget {
  const _PickerCard({
    super.key,
    required this.entry,
    required this.kind,
    required this.model,
    required this.picked,
    required this.single,
    required this.onTap,
  });
  final RefsEntry entry;
  final RefsKind kind;
  final RefsModel model;
  final bool picked;
  final bool single;
  final VoidCallback onTap;

  static const caption = 7 + 18.85 + 2 + 18.0;

  @override
  State<_PickerCard> createState() => _PickerCardState();
}

class _PickerCardState extends State<_PickerCard> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final e = widget.entry;
    final vibe = widget.kind == RefsKind.vibe;
    final picked = widget.picked;
    final chip = vibe
        ? RefsEncodingChip(entry: e, model: widget.model)
        : RefsTypeChip(e.type);
    final showChip =
        !vibe ||
        (widget.model.vibeUsable &&
            e.encoding != RefsEncoding.ready &&
            e.encoding != RefsEncoding.unknown);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    if (picked) ...[
                      BoxShadow(
                        color: c.accent.withValues(alpha: .16),
                        spreadRadius: 5,
                      ),
                      BoxShadow(color: c.accent, spreadRadius: 2),
                    ] else if (_hover)
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: c.dark ? .45 : .14,
                        ),
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
                          border: Border.all(
                            color: c.ink.withValues(alpha: .07),
                          ),
                        ),
                      ),
                      if (!widget.single)
                        Positioned(
                          left: 7,
                          top: 7,
                          child: RefsPickMark(on: picked),
                        ),
                      if (e.favorite)
                        const Positioned(
                          right: 7,
                          top: 7,
                          child: RefsStarButton(on: true),
                        ),
                      if (e.isBundle)
                        Positioned(
                          right: 7,
                          bottom: 7,
                          child: RefsDarkBadge(
                            glyph: UiGlyphs.stack,
                            text: '${e.bundleCount}',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: _PickerCard.caption,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(2, 7, 2, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    SizedBox(
                      height: 18.85,
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
                    SizedBox(
                      height: 18,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: showChip
                            ? chip
                            : Text(
                                '${RefsFormat.two(e.strength)} · '
                                '${RefsFormat.two(vibe ? e.infoExtracted : e.fidelity)}',
                                style: UiText.mono(
                                  11,
                                  weight: FontWeight.w500,
                                  color: c.muted,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
