import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_dialog.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import '../kit/ui_scrollable_row.dart';
import 'refs_contract.dart';
import 'refs_dialogs.dart';
import 'refs_page.dart';
import 'refs_parts.dart';
import 'refs_wall.dart';

/// 导入 1100 × 860：拖进来的、选的、粘贴的都走这一个窗口。逐个文件说清识别结果和要不要花 Anlas，
/// 底部汇总“库里多几张卡、现在扣多少”。
class RefsImportDialog extends StatefulWidget {
  const RefsImportDialog({
    super.key,
    required this.draft,
    required this.onClose,
  });
  final RefsImportDraft draft;
  final VoidCallback onClose;

  @override
  State<RefsImportDialog> createState() => _RefsImportDialogState();
}

class _RefsImportDialogState extends State<RefsImportDialog> {
  final _removed = <String>{};
  final _names = <String, TextEditingController>{};
  final _bundle = <String, RefsBundleImport>{};
  final _picked = <String, Set<int>>{};
  final _dup = <String, RefsDuplicate>{};
  final _tags = <String>[];
  final _tagCtrl = TextEditingController();
  late String? _category = widget.draft.categoryId;
  var _encodeNow = false;

  @override
  void dispose() {
    for (final c in _names.values) {
      c.dispose();
    }
    _tagCtrl.dispose();
    super.dispose();
  }

  TextEditingController _name(RefsImportRow r) =>
      _names.putIfAbsent(r.id, () => TextEditingController(text: r.name));

  int _cards(RefsImportRow r) {
    if (_dup[r.id] == RefsDuplicate.skip && r.duplicate) return 0;
    if (r.kind != RefsImportKind.bundle) return 1;
    return switch (_bundle[r.id] ?? RefsBundleImport.whole) {
      RefsBundleImport.whole => 1,
      RefsBundleImport.split => r.bundle.length,
      RefsBundleImport.pick => _picked[r.id]?.length ?? 0,
    };
  }

  void _confirm(List<RefsImportRow> rows) {
    final a = RefsScope.of(context).actions;
    final pending = _tagCtrl.text.trim();
    a.onImportConfirm(
      RefsImportPlan(
        categoryId: _category,
        tags: [..._tags, if (pending.isNotEmpty) pending],
        encodeNow: _encodeNow,
        rows: [
          for (final r in rows)
            RefsImportRowPlan(
              id: r.id,
              name: _name(r).text.trim().isEmpty
                  ? r.name
                  : _name(r).text.trim(),
              bundle: _bundle[r.id] ?? RefsBundleImport.whole,
              picked: (_picked[r.id]?.toList() ?? [])..sort(),
              duplicate: _dup[r.id] ?? RefsDuplicate.keepBoth,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final scope = RefsScope.of(context);
    final data = scope.data;
    final ctrl = scope.controller;
    final k = data.costs;
    final rows = widget.draft.rows
        .where((r) => !_removed.contains(r.id))
        .toList();
    final images = rows.where((r) => r.kind == RefsImportKind.image).length;
    final cards = rows.fold<int>(0, (s, r) => s + _cards(r));
    final now = _encodeNow ? images * k.encode : 0;
    final catName =
        data.categories.where((x) => x.id == _category).firstOrNull?.name ??
        l10n.refs_uncategorized;

    Widget label(String t) => Text(t, style: UiText.sans(12, color: c.muted));

    final options = Container(
      key: const Key('refs-import-options'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: UiScrollableRow(
        spacing: 16,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              label(l10n.refs_importPutIn),
              SizedBox(
                width: 150,
                child: Builder(
                  builder: (ctx) => UiDropChip(
                    key: const Key('refs-import-category'),
                    glyph: UiGlyphs.folder,
                    expand: true,
                    label: catName,
                    onTap: () {
                      final box = ctx.findRenderObject()! as RenderBox;
                      ctrl.openMenu(
                        UiPopoverAnchor(
                          box.localToGlobal(
                            box.size.bottomLeft(const Offset(0, 6)),
                          ),
                        ),
                        refsCategoryMenu(
                          context,
                          (id) => setState(() => _category = id),
                          current: _category,
                          markCurrent: true,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Row(
              spacing: 8,
              children: [
                label(l10n.refs_importAddTags),
                for (final t in _tags)
                  RefsTag(t, onRemove: () => setState(() => _tags.remove(t))),
                SizedBox(
                  width: 180,
                  child: _Input(
                    key: const Key('refs-import-tags'),
                    controller: _tagCtrl,
                    hint: l10n.refs_importTagsHint,
                    onSubmitted: (v) {
                      final t = v.trim();
                      if (t.isNotEmpty && !_tags.contains(t)) {
                        setState(() => _tags.add(t));
                      }
                      _tagCtrl.clear();
                    },
                  ),
                ),
              ],
            ),
          ),
          Row(
            key: const Key('refs-import-encode'),
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              label(l10n.refs_importPlainImages),
              UiSeg<bool>(
                small: false,
                values: const [false, true],
                selected: _encodeNow,
                onChanged: (v) => setState(() => _encodeNow = v),
                labelOf: (v) => v
                    ? l10n.refs_importEncodeNow(k.encode)
                    : l10n.refs_importEncodeLater,
              ),
            ],
          ),
        ],
      ),
    );

    final head = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: DefaultTextStyle.merge(
        style: UiText.sans(11.5, weight: FontWeight.w600, color: c.faint),
        child: Row(
          spacing: 12,
          children: [
            const SizedBox(width: 52),
            Expanded(child: Text(l10n.refs_importName)),
            SizedBox(width: 250, child: Text(l10n.refs_importResult)),
            const SizedBox(width: 28),
          ],
        ),
      ),
    );

    return RefsDialogFrame(
      key: const Key('refs-import-dialog'),
      width: 1100,
      height: 860,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiDialogHeader(
            children: [
              Text(l10n.refs_importTitle(rows.length)),
              Expanded(
                child: Text(
                  l10n.refs_importSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(12, color: c.muted),
                ),
              ),
              UiBtn(
                key: const Key('refs-import-more'),
                size: UiBtnSize.small,
                tone: UiBtnTone.ghost,
                onTap: () => scope.actions.onImport(RefsImportSource.files),
                children: [
                  const UiGlyph(UiGlyphs.plus, size: 13, strokeWidth: 2.2),
                  Text(l10n.refs_importMore),
                ],
              ),
              UiIconBox(
                key: const Key('refs-dialog-close'),
                glyph: UiGlyphs.close,
                glyphSize: 16,
                tooltip: l10n.refs_close,
                onTap: widget.onClose,
              ),
            ],
          ),
          options,
          head,
          Expanded(
            child: ListView(children: [for (final r in rows) _row(context, r)]),
          ),
          UiDialogFooter(
            children: [
              Expanded(
                child: Text.rich(
                  key: const Key('refs-import-summary'),
                  TextSpan(
                    children: [
                      TextSpan(
                        text: l10n.refs_importSummary(rows.length, cards),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: [
                          l10n.refs_importNow(now),
                          if (images > 0 && !_encodeNow)
                            l10n.refs_importLater(images, k.encode),
                        ].join(''),
                        style: TextStyle(color: c.muted),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(12, color: c.ink, height: 1.5),
                ),
              ),
              UiBtn(onTap: widget.onClose, children: [Text(l10n.refs_cancel)]),
              UiBtn(
                key: const Key('refs-import-confirm'),
                tone: UiBtnTone.primary,
                onTap: cards == 0 ? null : () => _confirm(rows),
                children: [
                  const UiGlyph(UiGlyphs.download, size: 14),
                  Text(l10n.refs_import),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, RefsImportRow r) {
    final c = context.ui;
    final l10n = context.l10n;
    final data = RefsScope.of(context).data;
    final k = data.costs;
    final m = data.model;
    final dupSkip = r.duplicate && _dup[r.id] == RefsDuplicate.skip;
    final (result, tone, note) = switch (r.kind) {
      RefsImportKind.vibePng => (
        l10n.refs_recPng(r.encodedFor ?? '?'),
        r.encodedForCurrent ? UiMiniTone.ok : UiMiniTone.warn,
        r.encodedForCurrent
            ? l10n.refs_recFree
            : l10n.refs_recReencode(m.shortName),
      ),
      RefsImportKind.vibeFile => (
        l10n.refs_recVibeFile(r.encodedFor ?? '?'),
        r.encodedForCurrent ? UiMiniTone.ok : UiMiniTone.warn,
        r.encodedForCurrent
            ? l10n.refs_recFree
            : l10n.refs_recReencode(m.shortName),
      ),
      RefsImportKind.bundle => (
        l10n.refs_recBundle(r.bundle.length),
        UiMiniTone.accent,
        l10n.refs_recBundleNote(r.bundle.length),
      ),
      RefsImportKind.image =>
        r.duplicate
            ? (l10n.refs_recImageDup, UiMiniTone.error, '')
            : (
                l10n.refs_recImage,
                UiMiniTone.warn,
                _encodeNow
                    ? l10n.refs_recEncodeNow(k.encode)
                    : l10n.refs_recEncodeLater,
              ),
    };
    final mode = _bundle[r.id] ?? RefsBundleImport.whole;
    final picked = _picked[r.id] ?? const <int>{};

    final nameCol = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        _Input(
          key: Key('refs-import-name-${r.id}'),
          controller: _name(r),
          error: r.duplicate && !dupSkip,
          suffix: r.ext,
        ),
        if (r.kind == RefsImportKind.bundle) ...[
          Row(
            children: [
              UiSeg<RefsBundleImport>(
                key: Key('refs-import-bundle-${r.id}'),
                small: false,
                values: RefsBundleImport.values,
                selected: mode,
                onChanged: (v) => setState(() => _bundle[r.id] = v),
                labelOf: (v) => switch (v) {
                  RefsBundleImport.whole => l10n.refs_bundleWhole,
                  RefsBundleImport.split => l10n.refs_bundleSplit(
                    r.bundle.length,
                  ),
                  RefsBundleImport.pick => l10n.refs_bundlePick,
                },
              ),
            ],
          ),
          if (mode == RefsBundleImport.pick)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final (i, b) in r.bundle.indexed)
                  UiPressable(
                    key: Key('refs-import-pick-${r.id}-$i'),
                    onTap: () => setState(() {
                      final s = _picked.putIfAbsent(r.id, () => {});
                      if (!s.remove(i)) s.add(i);
                    }),
                    builder: (_, _) => Container(
                      width: 34,
                      height: 42,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: c.control,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: picked.contains(i) ? c.accent : c.line,
                          width: picked.contains(i) ? 2 : 1,
                        ),
                      ),
                      child: Opacity(
                        opacity: picked.contains(i) ? 1 : .55,
                        child: RefsImage(b.thumb),
                      ),
                    ),
                  ),
              ],
            ),
        ],
        if (r.duplicate)
          Row(
            spacing: 10,
            children: [
              Text(l10n.refs_dupExists, style: UiText.sans(12, color: c.error)),
              UiSeg<RefsDuplicate>(
                key: Key('refs-import-dup-${r.id}'),
                small: false,
                values: RefsDuplicate.values,
                selected: _dup[r.id] ?? RefsDuplicate.keepBoth,
                onChanged: (v) => setState(() => _dup[r.id] = v),
                labelOf: (v) => switch (v) {
                  RefsDuplicate.keepBoth => l10n.refs_dupKeepBoth,
                  RefsDuplicate.overwrite => l10n.refs_dupOverwrite,
                  RefsDuplicate.skip => l10n.refs_dupSkip,
                },
              ),
            ],
          ),
      ],
    );

    return Opacity(
      opacity: dupSkip ? .5 : 1,
      child: Container(
        key: Key('refs-import-row-${r.id}'),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          spacing: 12,
          children: [
            Container(
              width: 52,
              height: 52,
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.control,
                borderRadius: BorderRadius.circular(7),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: c.line),
              ),
              child: r.thumb == null
                  ? UiGlyph(UiGlyphs.stack, size: 22, color: c.faint)
                  : RefsImage(r.thumb),
            ),
            Expanded(child: nameCol),
            SizedBox(
              width: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 3,
                children: [
                  UiMini(result, tone: tone),
                  if (note.isNotEmpty)
                    Text(
                      note,
                      style: UiText.sans(11, color: c.muted, height: 1.45),
                    ),
                ],
              ),
            ),
            UiIconBox(
              key: Key('refs-import-remove-${r.id}'),
              glyph: UiGlyphs.close,
              glyphSize: 14,
              size: 28,
              tooltip: l10n.refs_remove,
              onTap: () => setState(() => _removed.add(r.id)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 输入框：30 高、圆角 6、1px 实描边、页面底；可带灰色后缀（扩展名）。
class _Input extends StatelessWidget {
  const _Input({
    super.key,
    required this.controller,
    this.hint,
    this.suffix,
    this.error = false,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final String? hint;
  final String? suffix;
  final bool error;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border.all(color: error ? c.error : c.strong),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: UiText.sans(12.5, color: c.ink),
              cursorColor: c.accent,
              cursorHeight: 14,
              decoration: uiBareDecoration(
                hintText: hint,
                hintStyle: UiText.sans(12.5, color: c.faint),
              ),
              onSubmitted: onSubmitted,
            ),
          ),
          if (suffix != null)
            Text(suffix!, style: UiText.mono(11, color: c.faint)),
        ],
      ),
    );
  }
}
