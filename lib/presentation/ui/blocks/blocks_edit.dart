import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_block_pill.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_inputs.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_lib_nav.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_slider.dart';
import '../kit/ui_text.dart';
import 'blocks_contract.dart';
import 'blocks_format.dart';
import 'blocks_parts.dart';

/// 图标网格（原型 `.icg`）：每格 30、圆角 7、间距 4，一行 10 个；第一格是默认图标，后面是全部 40 个。
/// 选中：块色 14% 底 + 1.5px 块色内描边 + 块色图标。
class BlockIconGrid extends StatelessWidget {
  const BlockIconGrid({
    super.key,
    required this.selected,
    required this.color,
    required this.onChanged,
  });

  final String? selected;
  final Color color;

  /// null = 默认图标。
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    Widget cell(String? key) {
      final on = key == selected;
      return UiPressable(
        key: Key('block-icon-${key ?? 'default'}'),
        onTap: () => onChanged(key),
        builder: (context, hover) => Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? color.withValues(alpha: .14) : (hover ? c.hover : null),
            borderRadius: BorderRadius.circular(7),
            border: on ? Border.all(color: color, width: 1.5) : null,
          ),
          child: UiBlockIcon(key, size: 15, color: on ? color : c.muted),
        ),
      );
    }

    return SizedBox(
      width: 30 * 10 + 4 * 9,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [cell(null), for (final k in UiBlockIcon.keys) cell(k)],
      ),
    );
  }
}

/// 编辑块 / 新建块（原型 `editModal`）：1000 × 720（窗口小时缩到 92%）、圆角 16。
/// 左 330 预览（预览图可拖动 / 滚轮缩放、正文里的样子、卡片样子、来源）；右边 名称 + 文件夹 · 内容（正面 / 负面 / 纯文本）·
/// 外观（10 色 + 41 格图标 + 6 种外观直接画效果）· 标签 · 附带参数。Ctrl+Enter 保存，Esc 取消。
class BlockEditDialog extends StatefulWidget {
  const BlockEditDialog({super.key, required this.data, required this.actions});

  final BlockEditData data;
  final BlockEditActions actions;

  @override
  State<BlockEditDialog> createState() => _BlockEditDialogState();
}

enum _Tab { positive, negative, text }

class _BlockEditDialogState extends State<BlockEditDialog> {
  late BlockDraft _d = widget.data.draft;
  late var _tab = widget.data.draft.atoms == null ? _Tab.text : _Tab.positive;
  late final _text = TextEditingController(
    text:
        widget.data.draft.text ??
        (widget.data.draft.atoms ?? const []).join(', '),
  );
  final _positiveEditor = GlobalKey<_AtomEditorState>();
  final _negativeEditor = GlobalKey<_AtomEditorState>();
  var _confirmDelete = false;
  UiPopoverAnchor? _pop;
  WidgetBuilder? _popBuilder;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _set(BlockDraft d) => setState(() => _d = d);

  List<String> get _atoms => _d.atoms ?? BlocksFormat.split(_text.text);

  _AtomEditorState? get _activeEditor => switch (_tab) {
    _Tab.positive => _positiveEditor.currentState,
    _Tab.negative => _negativeEditor.currentState,
    _Tab.text => null,
  };

  bool get _valid =>
      _atoms.isNotEmpty ||
      _d.negativeAtoms.isNotEmpty ||
      _activeEditor?.hasPendingInput == true;

  void _save() {
    _activeEditor?.commitPending();
    if (!_valid) return;
    final d = _tab == _Tab.text
        ? _d.copyWith(plain: true, text: _text.text)
        : _d.copyWith(title: _d.title.trim());
    widget.actions.onSave(d.copyWith(title: d.title.trim()));
  }

  void _open(BuildContext ctx, WidgetBuilder builder, {bool above = false}) {
    final box = ctx.findRenderObject()! as RenderBox;
    setState(() {
      _pop = UiPopoverAnchor(
        box.localToGlobal(
          above
              ? box.size.topLeft(const Offset(0, -6))
              : box.size.bottomLeft(const Offset(0, 6)),
        ),
        alignBottom: above,
      );
      _popBuilder = builder;
    });
  }

  void _closePop() => setState(() => _pop = null);

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final mq = MediaQuery.sizeOf(context);
    final w = math.min(1000.0, mq.width * .92);
    final h = math.min(720.0, mq.height * .92);
    final narrow = w < 820;
    final isNew = widget.data.blockId == null;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _save,
        const SingleActivator(LogicalKeyboardKey.numpadEnter, control: true):
            _save,
      },
      child: UiPopover(
        anchor: _pop,
        onDismiss: _closePop,
        builder: (ctx) => _popBuilder?.call(ctx) ?? const SizedBox.shrink(),
        child: SizedBox(
          key: const Key('block-edit'),
          width: w,
          height: h,
          child: UiPopoverSurface(
            radius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 56,
                  padding: const EdgeInsets.only(left: 22, right: 10),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: c.line)),
                  ),
                  child: Row(
                    spacing: 10,
                    children: [
                      Text(
                        isNew
                            ? l10n.blocks_newBlock
                            : l10n.blocks_editBlockTitle,
                        style: UiText.sans(
                          16,
                          weight: FontWeight.w700,
                          color: c.ink,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          isNew
                              ? l10n.blocks_newBlockHint
                              : l10n.blocks_editHint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.sans(12, color: c.faint),
                        ),
                      ),
                      UiIconBox(
                        key: const Key('block-edit-close'),
                        glyph: UiGlyphs.close,
                        glyphSize: 17,
                        tooltip: l10n.blocks_close,
                        onTap: widget.actions.onCancel,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!narrow) _preview(context),
                      Expanded(child: _form(context)),
                    ],
                  ),
                ),
                Container(
                  height: 60,
                  padding: const EdgeInsets.only(left: 22, right: 18),
                  decoration: BoxDecoration(
                    color: c.panel,
                    border: Border(top: BorderSide(color: c.line)),
                  ),
                  child: Row(
                    spacing: 8,
                    children: [
                      if (widget.actions.onDelete != null && !_confirmDelete)
                        UiBtn(
                          key: const Key('block-edit-delete'),
                          tone: UiBtnTone.ghost,
                          color: c.error,
                          onTap: () => setState(() => _confirmDelete = true),
                          children: [
                            const UiGlyph(UiGlyphs.trash, size: 14),
                            Text(l10n.blocks_deleteBlock),
                          ],
                        ),
                      if (_confirmDelete) ...[
                        Text(
                          l10n.blocks_deleteConfirmInline,
                          style: UiText.sans(
                            12.5,
                            weight: FontWeight.w600,
                            color: c.error,
                          ),
                        ),
                        UiBtn(
                          key: const Key('block-edit-delete-no'),
                          size: UiBtnSize.small,
                          onTap: () => setState(() => _confirmDelete = false),
                          children: [Text(l10n.blocks_cancel)],
                        ),
                        UiBtn(
                          key: const Key('block-edit-delete-yes'),
                          size: UiBtnSize.small,
                          color: c.error,
                          onTap: widget.actions.onDelete,
                          children: [Text(l10n.blocks_delete)],
                        ),
                      ],
                      const Spacer(),
                      UiGlyph(UiGlyphs.keyboard, size: 13, color: c.faint),
                      Text(
                        l10n.blocks_saveShortcut,
                        style: UiText.sans(12, color: c.faint),
                      ),
                      const SizedBox(width: 4),
                      UiBtn(
                        key: const Key('block-edit-cancel'),
                        size: UiBtnSize.large,
                        onTap: widget.actions.onCancel,
                        children: [Text(l10n.blocks_cancel)],
                      ),
                      UiBtn(
                        key: const Key('block-edit-save'),
                        size: UiBtnSize.large,
                        tone: UiBtnTone.primary,
                        onTap: _valid ? _save : null,
                        children: [Text(l10n.blocks_save)],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 编辑中的块（给预览用）。
  BlockData get _shown => BlockData(
    id: widget.data.blockId ?? 'draft',
    title: _d.title.trim().isEmpty
        ? (_atoms.isEmpty ? context.l10n.blocks_untitled : _atoms.first)
        : _d.title.trim(),
    color: _d.color,
    icon: _d.icon,
    look: _d.look,
    atoms: _atoms,
    negativeAtoms: _d.negativeAtoms,
    thumb: _d.thumb,
    folderName: widget.data.folders
        .where((f) => f.id == _d.folderId)
        .firstOrNull
        ?.name,
    createdAt: DateTime(2000),
    updatedAt: DateTime(2000),
  );

  Widget _preview(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final b = _shown;
    final data = widget.data;
    final t = _d.thumb;
    return Container(
      width: 330,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(right: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          BlockLabel(l10n.blocks_preview),
          SizedBox(
            height: 210,
            child: t == null
                ? UiDashedBox(
                    radius: 10,
                    color: c.strong,
                    child: Center(
                      child: Builder(
                        builder: (ctx) => UiBtn(
                          key: const Key('block-edit-pick'),
                          size: UiBtnSize.small,
                          onTap: _pick,
                          children: [
                            const UiGlyph(UiGlyphs.picture, size: 13),
                            Text(l10n.blocks_addThumb),
                          ],
                        ),
                      ),
                    ),
                  )
                : _Crop(
                    thumb: t,
                    onChanged: (v) => _set(_d.copyWith(thumb: v)),
                    onPick: _pick,
                    onClear: () => _set(_d.copyWith(clearThumb: true)),
                  ),
          ),
          BlockBox(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: '…, wide shot, '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: BlockPill(b),
                  ),
                  const TextSpan(text: ' white dress, blue flower, …'),
                ],
              ),
              style: UiText.sans(13, color: c.ink, height: 1.6),
            ),
          ),
          BlockBox(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Row(
                    spacing: 6,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: BlockPill(b, large: true),
                        ),
                      ),
                      if (b.folderName != null)
                        Text(
                          b.folderName!,
                          style: UiText.sans(11, color: c.faint),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: BlockAtoms(
                    b.atoms.isEmpty ? b.negativeAtoms : b.atoms,
                    max: 5,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (data.sourcePath != null)
            Text(
              [
                l10n.blocks_sourceFile(data.sourcePath!),
                [
                  if (data.importedAt != null)
                    l10n.blocks_importedAt(BlocksFormat.date(data.importedAt!)),
                  switch (data.sourceState) {
                    BlockSourceState.synced => l10n.blocks_sourceSynced,
                    BlockSourceState.changed => l10n.blocks_sourceChanged,
                    BlockSourceState.missing => l10n.blocks_sourceMissing,
                    BlockSourceState.none => '',
                  },
                ].where((s) => s.isNotEmpty).join(' · '),
              ].join('\n'),
              style: UiText.sans(11, color: c.faint, height: 1.7),
            ),
        ],
      ),
    );
  }

  Future<void> _pick() async {
    final r = await widget.actions.onPickThumbnail();
    if (r == null || !mounted) return;
    _set(
      _d.copyWith(
        thumb: BlockThumb(r.image),
        thumbToken: r.token,
        clearThumb: false,
      ),
    );
  }

  Widget _field(String label, Widget child, {Widget? trailing, String? hint}) {
    final c = context.ui;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Row(
          spacing: 6,
          children: [
            Text(
              label,
              style: UiText.sans(12, weight: FontWeight.w600, color: c.muted),
            ),
            if (hint != null)
              Text(hint, style: UiText.mono(11, color: c.faint)),
            if (trailing != null) ...[const Spacer(), trailing],
          ],
        ),
        child,
      ],
    );
  }

  Widget _form(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final data = widget.data;
    final folder = data.folders.where((f) => f.id == _d.folderId).firstOrNull;
    final p = _d.params;

    final content = switch (_tab) {
      _Tab.positive => KeyedSubtree(
        key: const Key('block-edit-atoms'),
        child: _AtomEditor(
          key: _positiveEditor,
          atoms: _d.atoms ?? const [],
          onChanged: (v) => _set(_d.copyWith(atoms: v)),
          onPendingChanged: () => setState(() {}),
        ),
      ),
      _Tab.negative => KeyedSubtree(
        key: const Key('block-edit-negative'),
        child: _AtomEditor(
          key: _negativeEditor,
          atoms: _d.negativeAtoms,
          onChanged: (v) => _set(_d.copyWith(negativeAtoms: v)),
          onPendingChanged: () => setState(() {}),
        ),
      ),
      _Tab.text => Container(
        height: 150,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.strong),
        ),
        child: TextField(
          key: const Key('block-edit-text'),
          controller: _text,
          maxLines: null,
          expands: true,
          style: UiText.mono(12, color: c.ink, height: 1.6),
          cursorColor: c.accent,
          decoration: uiBareDecoration(
            hintText: l10n.blocks_plainTextHint,
            hintStyle: UiText.sans(12, color: c.faint),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 12,
            children: [
              Expanded(
                child: _field(
                  l10n.blocks_name,
                  UiTextInput(
                    key: const Key('block-edit-title'),
                    value: _d.title,
                    autofocus: widget.data.blockId == null,
                    hint: _atoms.isEmpty
                        ? l10n.blocks_namePlaceholder
                        : _atoms.first,
                    onChanged: (v) => _set(_d.copyWith(title: v)),
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                child: _field(
                  l10n.blocks_folder,
                  Builder(
                    builder: (ctx) => UiPressable(
                      key: const Key('block-edit-folder'),
                      onTap: () => _open(
                        ctx,
                        (_) => UiMenu(
                          width: 220,
                          onClose: _closePop,
                          items: [
                            UiMenuItem(
                              glyph: UiGlyphs.minus,
                              label: l10n.blocks_uncategorized,
                              checked: _d.folderId == null,
                              onTap: () => _set(_d.copyWith(root: true)),
                            ),
                            for (final f in data.folders)
                              UiMenuItem(
                                glyph: UiGlyphs.folder,
                                label: f.name,
                                indent: f.depth * 16.0,
                                checked: f.id == _d.folderId,
                                onTap: () => _set(_d.copyWith(folderId: f.id)),
                              ),
                          ],
                        ),
                      ),
                      builder: (context, hover) => Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: hover ? c.hover : c.bg,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: c.strong),
                        ),
                        child: Row(
                          spacing: 8,
                          children: [
                            UiGlyph(UiGlyphs.folder, size: 14, color: c.muted),
                            Expanded(
                              child: Text(
                                folder?.name ?? l10n.blocks_uncategorized,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: UiText.sans(13, color: c.ink),
                              ),
                            ),
                            UiGlyph(
                              UiGlyphs.chevronDown,
                              size: 14,
                              color: c.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          _field(
            l10n.blocks_content,
            hint: l10n.blocks_items(
              _tab == _Tab.negative ? _d.negativeAtoms.length : _atoms.length,
            ),
            trailing: BlockSeg<_Tab>(
              mini: true,
              values: _Tab.values,
              selected: _tab,
              keyOf: (t) => Key('block-edit-tab-${t.name}'),
              labelOf: (t) => switch (t) {
                _Tab.positive => l10n.blocks_positiveN(_atoms.length),
                _Tab.negative => l10n.blocks_negativeN(_d.negativeAtoms.length),
                _Tab.text => l10n.blocks_plainText,
              },
              onTap: (t) {
                if (t == _tab) return;
                _activeEditor?.commitPending();
                if (t == _Tab.text) {
                  _text.text = (_d.atoms ?? const []).join(', ');
                  _set(_d.copyWith(plain: true));
                } else if (_tab == _Tab.text) {
                  _set(_d.copyWith(atoms: BlocksFormat.split(_text.text)));
                }
                setState(() => _tab = t);
              },
            ),
            content,
          ),
          _field(
            l10n.blocks_appearance,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: BlockColorDots(
                        key: const Key('block-edit-colors'),
                        selected: _d.color,
                        size: 20,
                        onChanged: (col) => _set(_d.copyWith(color: col)),
                      ),
                    ),
                    BlockIconGrid(
                      key: const Key('block-edit-icons'),
                      selected: _d.icon,
                      color: _d.color,
                      onChanged: (k) => _set(
                        k == null
                            ? _d.copyWith(clearIcon: true)
                            : _d.copyWith(icon: k),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final cw = (box.maxWidth - 12) / 3;
                      return Wrap(
                        key: const Key('block-edit-looks'),
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final look in BlockAppearance.values)
                            UiPressable(
                              key: Key('block-edit-look-${look.name}'),
                              onTap: () => _set(_d.copyWith(look: look)),
                              builder: (context, hover) {
                                final on = _d.look == look;
                                return Container(
                                  width: cw,
                                  height: 46,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: on
                                        ? Color.alphaBlend(
                                            c.accent.withValues(alpha: .04),
                                            c.raised,
                                          )
                                        : (hover ? c.hover : null),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: on ? c.accent : c.line,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    spacing: 3,
                                    children: [
                                      BlockPill(_shown, look: look),
                                      Text(
                                        BlocksFormat.look(context, look),
                                        style: UiText.sans(
                                          11,
                                          color: on ? c.accent : c.muted,
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Expanded(
                child: _field(
                  l10n.blocks_tags,
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 34),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final t in _d.tags)
                          BlockTagChip(
                            t,
                            onRemove: () => _set(
                              _d.copyWith(tags: [..._d.tags]..remove(t)),
                            ),
                          ),
                        Builder(
                          builder: (ctx) => UiBtn(
                            key: const Key('block-edit-add-tag'),
                            size: UiBtnSize.small,
                            tone: UiBtnTone.ghost,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            onTap: () => _open(
                              ctx,
                              above: true,
                              (_) => _TagPicker(
                                tags: [
                                  for (final t in data.tags)
                                    if (!_d.tags.any((x) => x.name == t.name))
                                      t,
                                ],
                                onPick: (t) {
                                  _closePop();
                                  _set(_d.copyWith(tags: [..._d.tags, t]));
                                },
                              ),
                            ),
                            children: [
                              const UiGlyph(UiGlyphs.plus, size: 13),
                              Text(l10n.blocks_add),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 330,
                child: _field(
                  l10n.blocks_params,
                  Builder(
                    builder: (ctx) {
                      void edit() => _open(
                        ctx,
                        above: true,
                        (_) => _ParamsPanel(
                          params: _d.params ?? const BlockParams(),
                          catalog: data.catalog,
                          onCapture: widget.actions.onCaptureParams,
                          onChanged: (v) => _set(
                            v == null
                                ? _d.copyWith(clearParams: true)
                                : _d.copyWith(params: v),
                          ),
                          onClose: _closePop,
                        ),
                      );
                      if (p == null || p.isEmpty) {
                        return Row(
                          children: [
                            Text(
                              l10n.blocks_noParamsShort,
                              style: UiText.sans(12, color: c.faint),
                            ),
                            const SizedBox(width: 6),
                            UiBtn(
                              key: const Key('block-edit-params'),
                              size: UiBtnSize.small,
                              tone: UiBtnTone.ghost,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              onTap: edit,
                              children: [
                                const UiGlyph(UiGlyphs.plus, size: 13),
                                Text(l10n.blocks_add),
                              ],
                            ),
                          ],
                        );
                      }
                      return Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (p.model case final m?)
                            _chip(data.catalog.model(m), edit),
                          if (p.steps case final s?)
                            _chip(l10n.blocks_steps(s), edit),
                          if (p.scale case final g?)
                            _chip(
                              l10n.blocks_guidance(BlocksFormat.num1(g)),
                              edit,
                            ),
                          if (p.sampler case final s?)
                            _chip(
                              BlocksFormat.shortSampler(
                                data.catalog.sampler(s),
                              ),
                              edit,
                            ),
                          UiIconBox(
                            key: const Key('block-edit-params'),
                            glyph: UiGlyphs.pencil,
                            size: 26,
                            glyphSize: 13,
                            tooltip: l10n.blocks_editParams,
                            onTap: edit,
                          ),
                        ],
                      );
                    },
                  ),
                  hint: null,
                  trailing: Text(
                    l10n.blocks_paramsNotAuto,
                    style: UiText.sans(11, color: c.faint),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, VoidCallback onTap) =>
      UiBtn(size: UiBtnSize.small, onTap: onTap, children: [Text(text)]);
}

/// 预览图裁剪：拖动平移、滚轮缩放（1…3）；左下“换图”、右上清除、右下提示。
class _Crop extends StatelessWidget {
  const _Crop({
    required this.thumb,
    required this.onChanged,
    required this.onPick,
    required this.onClear,
  });
  final BlockThumb thumb;
  final ValueChanged<BlockThumb> onChanged;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, box) => Listener(
        onPointerSignal: (e) {
          if (e is PointerScrollEvent) {
            onChanged(
              thumb.copyWith(
                scale: (thumb.scale - e.scrollDelta.dy / 600).clamp(1.0, 3.0),
              ),
            );
          }
        },
        child: GestureDetector(
          key: const Key('block-edit-crop'),
          onPanUpdate: (e) => onChanged(
            thumb.copyWith(
              offsetX:
                  (thumb.offsetX - e.delta.dx / box.maxWidth * 2 / thumb.scale)
                      .clamp(-1.0, 1.0),
              offsetY:
                  (thumb.offsetY - e.delta.dy / box.maxHeight * 2 / thumb.scale)
                      .clamp(-1.0, 1.0),
            ),
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.move,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: c.accent.withValues(alpha: .5),
                  width: 2,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  UiCroppedImage(
                    image: thumb.image,
                    offsetX: thumb.offsetX,
                    offsetY: thumb.offsetY,
                    scale: thumb.scale,
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: _darkBtn(
                      UiGlyphs.picture,
                      l10n.blocks_changeImage,
                      onPick,
                      const Key('block-edit-pick'),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: _darkBtn(
                      UiGlyphs.close,
                      '',
                      onClear,
                      const Key('block-edit-clear-thumb'),
                      tip: l10n.blocks_clearThumb,
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 12,
                    child: Text(
                      l10n.blocks_cropHint,
                      style:
                          UiText.sans(
                            11,
                            color: Colors.white.withValues(alpha: .9),
                          ).copyWith(
                            shadows: const [
                              Shadow(color: Color(0x80000000), blurRadius: 4),
                            ],
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _darkBtn(
    String glyph,
    String label,
    VoidCallback onTap,
    Key key, {
    String? tip,
  }) => UiPressable(
    key: key,
    onTap: onTap,
    builder: (context, hover) {
      final btn = Container(
        height: 26,
        padding: EdgeInsets.symmetric(horizontal: label.isEmpty ? 6 : 9),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: hover ? .72 : .6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            UiGlyph(glyph, size: 13, color: Colors.white),
            if (label.isNotEmpty)
              Text(
                label,
                style: UiText.sans(
                  12,
                  weight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
          ],
        ),
      );
      return tip == null ? btn : Tooltip(message: tip, child: btn);
    },
  );
}

/// 内容编辑（原型 `.aed`）：已有项是小块（Geist Mono 11.5、24 高），末尾一个输入框；
/// Enter 或逗号成为一项，粘贴一段自动拆分；点一项拿回输入框里改，悬停出 ×，空输入框按退格删最后一项。
class _AtomEditor extends StatefulWidget {
  const _AtomEditor({
    super.key,
    required this.atoms,
    required this.onChanged,
    required this.onPendingChanged,
  });
  final List<String> atoms;
  final ValueChanged<List<String>> onChanged;
  final VoidCallback onPendingChanged;

  @override
  State<_AtomEditor> createState() => _AtomEditorState();
}

class _AtomEditorState extends State<_AtomEditor> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  int? _editing;
  int? _hover;

  bool get hasPendingInput => _ctrl.text.trim().isNotEmpty;

  void commitPending() {
    if (hasPendingInput) _commit(_ctrl.text);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit(String raw) {
    final parts = BlocksFormat.split(raw);
    final list = [...widget.atoms];
    if (_editing != null) {
      list.removeAt(_editing!);
      list.insertAll(_editing!, parts);
    } else {
      list.addAll(parts);
    }
    _ctrl.clear();
    setState(() => _editing = null);
    widget.onChanged(list);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    return GestureDetector(
      onTap: _focus.requestFocus,
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.strong),
        ),
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 5,
            runSpacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final (i, a) in widget.atoms.indexed)
                MouseRegion(
                  onEnter: (_) => setState(() => _hover = i),
                  onExit: (_) => setState(() => _hover = null),
                  child: GestureDetector(
                    key: Key('block-atom-$i'),
                    onTap: () {
                      setState(() => _editing = i);
                      _ctrl.text = a;
                      _focus.requestFocus();
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        BlockAtom(
                          a,
                          small: true,
                          mono: true,
                          fontSize: 11.5,
                          height: 24,
                          focused: _editing == i,
                        ),
                        if (_hover == i && _editing != i)
                          Positioned(
                            right: -5,
                            top: -5,
                            child: UiPressable(
                              key: Key('block-atom-remove-$i'),
                              onTap: () {
                                setState(() {
                                  if (_editing != null && i < _editing!) {
                                    _editing = _editing! - 1;
                                  }
                                  _hover = null;
                                });
                                widget.onChanged(
                                  [...widget.atoms]..removeAt(i),
                                );
                              },
                              builder: (_, h) => Container(
                                width: 15,
                                height: 15,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: h ? c.error : c.muted,
                                  shape: BoxShape.circle,
                                ),
                                child: const UiGlyph(
                                  UiGlyphs.close,
                                  size: 9,
                                  strokeWidth: 2.6,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              IntrinsicWidth(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 160),
                  child: Focus(
                    onKeyEvent: (_, e) {
                      if (e is KeyDownEvent &&
                          e.logicalKey == LogicalKeyboardKey.backspace &&
                          _ctrl.text.isEmpty &&
                          widget.atoms.isNotEmpty &&
                          _editing == null) {
                        widget.onChanged([...widget.atoms]..removeLast());
                        return KeyEventResult.handled;
                      }
                      if (e is KeyDownEvent &&
                          e.logicalKey == LogicalKeyboardKey.escape &&
                          _editing != null) {
                        _ctrl.clear();
                        setState(() => _editing = null);
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      key: const Key('block-atom-input'),
                      controller: _ctrl,
                      focusNode: _focus,
                      style: UiText.mono(11.5, color: c.ink, height: 1.4),
                      cursorColor: c.accent,
                      cursorHeight: 15,
                      decoration: uiBareDecoration(
                        hintText: widget.atoms.isEmpty || _editing == null
                            ? l10n.blocks_atomHint
                            : null,
                        hintStyle: UiText.sans(12, color: c.faint),
                      ),
                      onChanged: (v) {
                        if (v.contains(',') || v.contains('\n')) {
                          _commit(v);
                        } else {
                          widget.onPendingChanged();
                        }
                      },
                      onSubmitted: (_) {
                        commitPending();
                        _focus.requestFocus();
                      },
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

/// 加标签：已有标签列表 + 新标签（名字 + 8 色）。
class _TagPicker extends StatefulWidget {
  const _TagPicker({required this.tags, required this.onPick});
  final List<BlockTag> tags;
  final ValueChanged<BlockTag> onPick;

  @override
  State<_TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends State<_TagPicker> {
  var _name = '';
  var _color = const Color(0xFF2563EB);

  static const _palette = [
    Color(0xFF2563EB),
    Color(0xFF16A34A),
    Color(0xFFDC2626),
    Color(0xFF9333EA), //
    Color(0xFFEA580C), Color(0xFF0891B2), Color(0xFFDB2777), Color(0xFF64748B),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    return UiPopoverSurface(
      key: const Key('block-tag-picker'),
      width: 260,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          if (widget.tags.isNotEmpty) ...[
            BlockLabel(l10n.blocks_existingTags),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final t in widget.tags)
                  BlockTagChip(
                    t,
                    key: Key('block-tag-${t.name}'),
                    onTap: () => widget.onPick(t),
                  ),
              ],
            ),
            Container(height: 1, color: c.line),
          ],
          BlockLabel(l10n.blocks_newTag),
          UiTextInput(
            key: const Key('block-tag-name'),
            value: '',
            submitOnBlur: false,
            hint: l10n.blocks_tagName,
            height: 30,
            onChanged: (v) => setState(() => _name = v),
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) {
                widget.onPick(BlockTag(v.trim(), _color));
              }
            },
          ),
          Row(
            spacing: 7,
            children: [
              for (final col in _palette)
                UiPressable(
                  onTap: () => setState(() => _color = col),
                  builder: (_, _) => Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: col,
                      shape: BoxShape.circle,
                      boxShadow: col == _color
                          ? [
                              BoxShadow(color: col, spreadRadius: 3.5),
                              BoxShadow(color: c.raised, spreadRadius: 2),
                            ]
                          : null,
                    ),
                  ),
                ),
              const Spacer(),
              UiBtn(
                key: const Key('block-tag-create'),
                size: UiBtnSize.small,
                tone: UiBtnTone.primary,
                onTap: _name.trim().isEmpty
                    ? null
                    : () => widget.onPick(BlockTag(_name.trim(), _color)),
                children: [Text(l10n.blocks_add)],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 附带参数：模型 / 步数 / 引导 / 重缩放 / 采样器 / 噪声；“从当前读取”“清除”。改一项立即写回草稿。
class _ParamsPanel extends StatefulWidget {
  const _ParamsPanel({
    required this.params,
    required this.catalog,
    required this.onCapture,
    required this.onChanged,
    required this.onClose,
  });
  final BlockParams params;
  final BlockParamCatalog catalog;
  final Future<BlockParams?> Function() onCapture;
  final ValueChanged<BlockParams?> onChanged;
  final VoidCallback onClose;

  @override
  State<_ParamsPanel> createState() => _ParamsPanelState();
}

class _ParamsPanelState extends State<_ParamsPanel> {
  late var _p = widget.params;
  String? _open;

  void _set(BlockParams p) {
    setState(() => _p = p);
    widget.onChanged(p);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l10n = context.l10n;
    final cat = widget.catalog;
    Widget row(String label, Widget child) => Row(
      spacing: 10,
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: UiText.sans(12, color: c.muted)),
        ),
        Expanded(
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      ],
    );
    Widget pick(
      String key,
      Map<String, String> options,
      String? value,
      ValueChanged<String> onPick,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiPressable(
          key: Key('block-param-$key'),
          onTap: () => setState(() => _open = _open == key ? null : key),
          builder: (context, hover) => Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: hover ? c.hover : c.control,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null
                        ? l10n.blocks_keepCurrent
                        : (options[value] ?? value),
                    style: UiText.sans(
                      12.5,
                      color: value == null ? c.faint : c.ink,
                    ),
                  ),
                ),
                UiGlyph(
                  _open == key ? UiGlyphs.chevronUp : UiGlyphs.chevronDown,
                  size: 13,
                  color: c.muted,
                ),
              ],
            ),
          ),
        ),
        if (_open == key)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final e in options.entries)
                  UiFilterChip(
                    key: Key('block-param-$key-${e.key}'),
                    label: e.value,
                    selected: e.key == value,
                    onTap: () {
                      setState(() => _open = null);
                      onPick(e.key);
                    },
                  ),
              ],
            ),
          ),
      ],
    );
    return UiPopoverSurface(
      key: const Key('block-params-panel'),
      width: 330,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 9,
        children: [
          Row(
            children: [
              BlockLabel(l10n.blocks_params),
              const Spacer(),
              UiBtn(
                key: const Key('block-param-capture'),
                size: UiBtnSize.small,
                onTap: () async {
                  final p = await widget.onCapture();
                  if (p != null && mounted) _set(p);
                },
                children: [
                  const UiGlyph(UiGlyphs.download, size: 13),
                  Text(l10n.blocks_captureParams),
                ],
              ),
            ],
          ),
          row(
            l10n.blocks_paramModel,
            pick(
              'model',
              cat.models,
              _p.model,
              (v) => _set(_p.copyWith(model: v)),
            ),
          ),
          row(
            l10n.blocks_paramSteps,
            UiNumBox(
              key: const Key('block-param-steps'),
              value: (_p.steps ?? 28).toDouble(),
              decimals: 0,
              min: 1,
              max: 50,
              changed: _p.steps != null,
              onSubmitted: (v) => _set(_p.copyWith(steps: v.round())),
            ),
          ),
          row(
            l10n.blocks_paramGuidance,
            Row(
              spacing: 8,
              children: [
                UiNumBox(
                  key: const Key('block-param-scale'),
                  value: _p.scale ?? 5,
                  decimals: 1,
                  max: 10,
                  changed: _p.scale != null,
                  onSubmitted: (v) => _set(_p.copyWith(scale: v)),
                ),
                Text(
                  l10n.blocks_paramRescale,
                  style: UiText.sans(12, color: c.muted),
                ),
                UiNumBox(
                  key: const Key('block-param-rescale'),
                  value: _p.cfgRescale ?? 0,
                  max: 1,
                  changed: _p.cfgRescale != null,
                  onSubmitted: (v) => _set(_p.copyWith(cfgRescale: v)),
                ),
              ],
            ),
          ),
          row(
            l10n.blocks_paramSampler,
            pick(
              'sampler',
              cat.samplers,
              _p.sampler,
              (v) => _set(_p.copyWith(sampler: v)),
            ),
          ),
          row(
            l10n.blocks_paramNoise,
            pick(
              'noise',
              cat.noiseSchedules,
              _p.noiseSchedule,
              (v) => _set(_p.copyWith(noiseSchedule: v)),
            ),
          ),
          row(
            l10n.qualityTags_label,
            pick(
              'quality',
              {
                ...BlocksFormat.qualityOptions(
                  context,
                  _p.model ??
                      cat.currentModel ??
                      ImageModels.animeDiffusionV5Full,
                ),
                for (final e in cat.customPresets.entries)
                  'block:${e.key}': e.value,
              },
              _p.qualityCustomBlockId == null
                  ? _p.qualityPreset
                  : 'block:${_p.qualityCustomBlockId}',
              (v) => _set(
                v.startsWith('block:')
                    ? _p.copyWith(qualityCustomBlockId: v.substring(6))
                    : _p.copyWith(qualityPreset: v, clearQualityCustom: true),
              ),
            ),
          ),
          row(
            l10n.ucPreset_label,
            pick(
              'uc',
              {
                for (final type in UcPresets.getPresetsForModel(
                  _p.model ??
                      cat.currentModel ??
                      ImageModels.animeDiffusionV5Full,
                ).keys)
                  '${UcPresets.toApiValue(type)}': BlocksFormat.ucLabel(
                    context,
                    type,
                  ),
                for (final e in cat.customPresets.entries)
                  'block:${e.key}': e.value,
              },
              _p.ucCustomBlockId == null
                  ? _p.ucPreset?.toString()
                  : 'block:${_p.ucCustomBlockId}',
              (v) => _set(
                v.startsWith('block:')
                    ? _p.copyWith(ucCustomBlockId: v.substring(6))
                    : _p.copyWith(ucPreset: int.parse(v), clearUcCustom: true),
              ),
            ),
          ),
          Row(
            children: [
              UiBtn(
                key: const Key('block-param-clear'),
                size: UiBtnSize.small,
                tone: UiBtnTone.ghost,
                color: c.error,
                onTap: () {
                  widget.onChanged(null);
                  widget.onClose();
                },
                children: [Text(l10n.blocks_clearParams)],
              ),
              const Spacer(),
              UiBtn(
                size: UiBtnSize.small,
                tone: UiBtnTone.primary,
                onTap: widget.onClose,
                children: [Text(l10n.blocks_done)],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
