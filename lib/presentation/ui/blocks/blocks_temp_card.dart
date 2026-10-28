import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/prompt/pills/translation_pill_view.dart';
import '../kit/ui_block_pill.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_inputs.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'blocks_contract.dart';
import 'blocks_parts.dart';

/// 临时块的实例卡（原型 `.devin/mockups/fix-batch-1024` 场景 blocks，`.bc`）：
/// 斑马纹药丸 + “临时块” / 改动说明 / 内容（编辑 ⇄ 对比原块）/ 还原 · 继续编辑 · 另存为新块。
/// 另存为新块时在底部展开名称 + 文件夹一行；原块保持不变。
class BlockTempCard extends StatefulWidget {
  const BlockTempCard({super.key, required this.data, required this.actions});
  final BlockInstanceViewData data;
  final BlockInstanceActions actions;

  /// 和普通实例卡同宽。
  static const width = 348.0;

  @override
  State<BlockTempCard> createState() => _BlockTempCardState();
}

/// 临时块配色（原型 `--hz*` / `--add*` / `--del*`）。
class _Hz {
  _Hz(UiColors c)
    : ink = c.dark ? const Color(0xFFFFD65C) : const Color(0xFF3D2E00),
      add = c.dark ? const Color(0xFF10301F) : const Color(0xFFE6F6EC),
      addInk = c.dark ? const Color(0xFF6FE0A5) : const Color(0xFF17663D),
      del = c.dark ? const Color(0xFF3A1517) : const Color(0xFFFDECEC),
      delInk = c.dark ? const Color(0xFFFF8F93) : const Color(0xFFA1262B),
      infoBg = Color.alphaBlend(
        UiBlockPill.hazard.withValues(alpha: .10),
        c.raised,
      ),
      infoLine = UiBlockPill.hazard.withValues(alpha: .35),
      warn = c.warn;
  final Color ink, add, addInk, del, delInk, infoBg, infoLine, warn;
}

List<String> _tags(String text) => [
  for (final t in text.split(','))
    if (t.trim().isNotEmpty) t.trim(),
];

String _norm(String tag) => tag.trim().toLowerCase();

/// 编辑框里把原块没有的词标成“新增”色。
class _DiffController extends TextEditingController {
  _DiffController(String text, this.original, this.style) : super(text: text);
  Set<String> original;
  TextStyle style;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (withComposing && value.isComposingRangeValid) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    final children = <TextSpan>[];
    final parts = text.split(',');
    for (final (i, part) in parts.indexed) {
      if (i > 0) children.add(const TextSpan(text: ','));
      final lead = part.length - part.trimLeft().length;
      final tail = part.trimRight().length;
      final core = part.trim();
      if (core.isEmpty || original.contains(_norm(core))) {
        children.add(TextSpan(text: part));
        continue;
      }
      children
        ..add(TextSpan(text: part.substring(0, lead)))
        ..add(TextSpan(text: core, style: this.style))
        ..add(TextSpan(text: part.substring(tail)));
    }
    return TextSpan(style: style, children: children);
  }
}

class _BlockTempCardState extends State<BlockTempCard> {
  var _negative = false;
  var _compare = false;
  var _saving = false;
  var _busy = false;
  var _editingTranslations = false;
  final _sourceViews = <int>{};
  String? _folderId;
  late String _name = widget.data.block.title;
  UiPopoverAnchor? _menu;
  UiPopoverAnchor? _folderMenu;
  _DiffController? _text;
  final _focus = FocusNode();

  BlockInstanceViewData get d => widget.data;
  BlockInstanceActions get a => widget.actions;

  String get _current =>
      (_negative ? d.tempNegativeContent : d.tempContent) ?? '';
  String get _original =>
      (_negative ? d.originalNegativeContent : d.originalContent) ?? '';
  bool get _hasNegative =>
      (d.tempNegativeContent ?? '').trim().isNotEmpty ||
      (d.originalNegativeContent ?? '').trim().isNotEmpty;
  bool get _dirty => _text != null && _text!.text != _current;

  @override
  void initState() {
    super.initState();
    _folderId = d.block.folderId;
  }

  @override
  void didUpdateWidget(BlockTempCard old) {
    super.didUpdateWidget(old);
    final t = _text;
    if (t != null && !_dirty) {
      final next = _current;
      if (t.text != next) t.text = next;
      t.original = _tags(_original).map(_norm).toSet();
    }
  }

  @override
  void dispose() {
    _text?.dispose();
    _focus.dispose();
    super.dispose();
  }

  _DiffController _controller(_Hz hz) {
    // 没有原块时不标“新增”：对着空串，每个词都会被标绿。
    final style = d.standalone
        ? const TextStyle()
        : TextStyle(backgroundColor: hz.add, color: hz.addInk);
    final t = _text ??= _DiffController(
      _current,
      _tags(_original).map(_norm).toSet(),
      style,
    );
    t.style = style;
    return t;
  }

  void _switchFace(bool negative) {
    if (negative == _negative) return;
    _text?.dispose();
    _text = null;
    _editingTranslations = false;
    _sourceViews.clear();
    setState(() => _negative = negative);
  }

  Future<void> _run(Future<void> Function() f) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await f();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _applyEdit() {
    final edit = a.onEditTempContent;
    final t = _text;
    if (edit == null || t == null) return;
    final value = t.text;
    _run(
      () => _negative
          ? edit(d.tempContent ?? '', value)
          : edit(value, d.tempNegativeContent),
    );
  }

  void _expand() {
    final expand = a.onExpandTempContent;
    if (!_dirty || expand == null) {
      a.onExpand?.call();
      return;
    }
    _run(
      () => expand(
        _negative ? d.tempContent ?? '' : _text!.text,
        _negative ? _text!.text : d.tempNegativeContent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final hz = _Hz(c);
    final b = d.block;

    final more = Builder(
      builder: (ctx) => UiIconBox(
        key: const Key('block-temp-more'),
        glyph: UiGlyphs.more,
        glyphSize: 16,
        size: 28,
        tooltip: l.blocks_more,
        onTap: () {
          final box = ctx.findRenderObject()! as RenderBox;
          setState(
            () => _menu = UiPopoverAnchor(
              box.localToGlobal(box.size.bottomRight(const Offset(0, 4))),
              alignRight: true,
            ),
          );
        },
      ),
    );

    // `.bch`
    final head = Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
      child: Row(
        spacing: 8,
        children: [
          Flexible(
            child: UiBlockPill(
              key: const Key('block-temp-pill'),
              label: b.title,
              color: b.color,
              icon: b.icon,
              look: b.look,
              large: true,
              temporary: true,
              disabled: !d.enabled,
              translationMark: l.blocks_translationMark,
            ),
          ),
          Text(
            l.blocks_tempLabel,
            style: UiText.sans(12, weight: FontWeight.w600, color: hz.ink),
          ),
          const Spacer(),
          more,
        ],
      ),
    );

    final at = d.editedAt;
    final when = at == null
        ? ''
        : ' ${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
    // `.info`
    final info = Container(
      key: const Key('block-temp-info'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: hz.infoBg,
        border: Border.all(color: hz.infoLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: UiGlyph(UiGlyphs.wrench, size: 14, color: hz.warn),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: d.standalone
                        ? (d.editedBy == 'agent'
                              ? l.blocks_tempCreatedByAgent(when)
                              : l.blocks_tempCreatedByYou(when))
                        : d.editedBy == 'agent'
                        ? l.blocks_tempEditedByAgent(when)
                        : l.blocks_tempEditedByYou(when),
                    style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
                  ),
                  TextSpan(
                    text: d.standalone
                        ? l.blocks_tempStandaloneExplain
                        : l.blocks_tempExplain(b.title),
                  ),
                ],
              ),
              style: UiText.sans(12, color: c.muted, height: 1.55),
            ),
          ),
        ],
      ),
    );

    final original = _tags(_original);
    final current = _tags(_compare ? _current : (_text?.text ?? _current));
    final originalSet = original.map(_norm).toSet();
    final currentSet = current.map(_norm).toSet();
    final added = current.where((t) => !originalSet.contains(_norm(t)));
    final removed = original.where((t) => !currentSet.contains(_norm(t)));

    final mono = UiText.mono(12.5, color: c.ink, height: 1.75);
    final translations = _negative
        ? d.tempNegativeTranslations
        : d.tempTranslations;
    final reading = translations.isEmpty || _editingTranslations
        ? null
        : LayoutBuilder(
            builder: (context, constraints) {
              final spans = <InlineSpan>[];
              var offset = 0;
              for (final (index, translation) in translations.indexed) {
                final start = _current.indexOf(translation.source, offset);
                if (start > offset) {
                  spans.add(TextSpan(text: _current.substring(offset, start)));
                }
                void toggle() => setState(() {
                  if (!_sourceViews.remove(index)) _sourceViews.add(index);
                });
                spans.add(
                  WidgetSpan(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth,
                      ),
                      child: TranslationPillView(
                        key: ValueKey('block-temp-translation-$index'),
                        pill: translation.copyWith(
                          marks: const [],
                          showOriginal:
                              translation.showOriginal !=
                              _sourceViews.contains(index),
                        ),
                        toggleOnTap: true,
                        onToggle: toggle,
                        onEdit: (_) => toggle(),
                      ),
                    ),
                  ),
                );
                offset = start + translation.source.length;
              }
              spans.add(TextSpan(text: _current.substring(offset)));
              return Text.rich(TextSpan(children: spans), style: mono);
            },
          );
    final Widget content = _compare && !d.standalone
        ? Container(
            key: const Key('block-temp-diff'),
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: c.panel,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text.rich(
              TextSpan(children: _diffSpans(original, current, hz)),
              style: mono,
            ),
          )
        : Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: c.bg,
              border: Border.all(color: _focus.hasFocus ? c.strong : c.line),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                reading ??
                Focus(
                  onFocusChange: (_) => setState(() {}),
                  child: TextField(
                    key: const Key('block-temp-editor'),
                    controller: _controller(hz),
                    focusNode: _focus,
                    minLines: 2,
                    maxLines: 8,
                    style: mono,
                    cursorColor: c.accent,
                    cursorWidth: 1.5,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
          );

    Widget tag(String text, {required bool add}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: add ? hz.add : hz.del,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: UiText.sans(
          10.5,
          color: add ? hz.addInk : hz.delInk,
          height: 1.4,
        ).copyWith(decoration: add ? null : TextDecoration.lineThrough),
      ),
    );

    // `.bcb`
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          info,
          Row(
            spacing: 6,
            children: [
              Text(
                l.blocks_content,
                style: UiText.sans(
                  11.5,
                  weight: FontWeight.w600,
                  color: c.muted,
                  letterSpacing: .23,
                ),
              ),
              if (_hasNegative)
                BlockSeg<bool>(
                  mini: true,
                  values: const [false, true],
                  selected: _negative,
                  keyOf: (v) => Key('block-temp-face-${v ? 'neg' : 'pos'}'),
                  labelOf: (v) => v ? l.blocks_negative : l.blocks_positive,
                  onTap: _switchFace,
                ),
              const Spacer(),
              if (!d.standalone)
                BlockSeg<bool>(
                  values: const [false, true],
                  selected: _compare,
                  keyOf: (v) => Key('block-temp-${v ? 'compare' : 'edit'}'),
                  labelOf: (v) => v ? l.blocks_tempCompare : l.blocks_tempEdit,
                  onTap: (v) => setState(() => _compare = v),
                ),
            ],
          ),
          content,
          if (!d.standalone)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                tag(l.blocks_tempAdded, add: true),
                Text(
                  added.isEmpty
                      ? l.blocks_tempAddedNone
                      : l.blocks_tempAddedCount(added.length),
                  style: UiText.sans(11, color: c.faint),
                ),
                const SizedBox(width: 6),
                tag(
                  removed.isEmpty ? l.blocks_tempRemoved : removed.first,
                  add: false,
                ),
                Text(
                  removed.isEmpty
                      ? l.blocks_tempRemovedNone
                      : l.blocks_tempRemovedHint(removed.length),
                  style: UiText.sans(11, color: c.faint),
                ),
              ],
            ),
        ],
      ),
    );

    final quickActions = <Widget>[
      if (a.onExpand != null)
        UiBtn(
          key: const Key('block-temp-expand'),
          size: UiBtnSize.small,
          tone: UiBtnTone.ghost,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          tooltip: l.translationEditor_restore,
          onTap: _busy || (_dirty && a.onExpandTempContent == null)
              ? null
              : _expand,
          children: [Text('A', style: UiText.sans(18, color: c.muted))],
        ),
      UiIconBox(
        key: const Key('block-temp-delete'),
        glyph: UiGlyphs.trash,
        glyphSize: 16,
        size: 26,
        tooltip: l.blocks_removeInstance,
        color: c.error,
        onTap: _busy ? null : a.onRemove,
      ),
    ];
    // `.bcf`
    final footer = Container(
      key: const Key('block-temp-footer'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Color.alphaBlend(c.panel.withValues(alpha: .7), c.raised),
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: 8,
            children: [
              if (d.standalone) ...quickActions,
              if (!d.standalone)
                UiBtn(
                  key: const Key('block-temp-revert'),
                  size: UiBtnSize.small,
                  tone: UiBtnTone.ghost,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  onTap: a.onRevertTemp == null || _busy
                      ? null
                      : () => _run(a.onRevertTemp!),
                  children: [
                    const UiGlyph(UiGlyphs.undo, size: 13),
                    Text(l.blocks_tempRevert),
                  ],
                ),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    UiBtn(
                      key: const Key('block-temp-apply'),
                      size: UiBtnSize.small,
                      tone: _dirty ? UiBtnTone.primary : UiBtnTone.normal,
                      onTap: _busy
                          ? null
                          : _dirty
                          ? _applyEdit
                          : () => setState(() {
                              _compare = false;
                              _editingTranslations = true;
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => _focus.requestFocus(),
                              );
                            }),
                      children: [
                        UiGlyph(
                          _dirty ? UiGlyphs.check : UiGlyphs.pencil,
                          size: 13,
                        ),
                        Text(
                          _dirty
                              ? l.blocks_tempApply
                              : l.blocks_tempKeepEditing,
                        ),
                      ],
                    ),
                    if (a.onSaveTempAsNewBlock != null)
                      UiBtn(
                        key: const Key('block-temp-save-as'),
                        size: UiBtnSize.small,
                        tone: _saving ? UiBtnTone.normal : UiBtnTone.primary,
                        onTap: _busy
                            ? null
                            : () => setState(() => _saving = !_saving),
                        children: [
                          const UiGlyph(UiGlyphs.saveAs, size: 13),
                          Text(l.blocks_tempSaveAs),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (!d.standalone)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: quickActions,
              ),
            ),
        ],
      ),
    );

    final folderName = _folderId == null
        ? l.blocks_uncategorized
        : d.folders
                  .where((f) => f.id == _folderId)
                  .map((f) => f.name)
                  .firstOrNull ??
              b.folderName ??
              l.blocks_uncategorized;
    final saveRow = Container(
      key: const Key('block-temp-save-row'),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          Text(
            l.blocks_tempSaveAsHint,
            style: UiText.sans(11.5, weight: FontWeight.w600, color: c.muted),
          ),
          Row(
            spacing: 6,
            children: [
              Expanded(
                child: UiTextInput(
                  key: const Key('block-temp-save-name'),
                  value: _name,
                  height: 30,
                  autofocus: true,
                  selectAll: true,
                  hint: l.blocks_name,
                  onChanged: (v) => setState(() => _name = v),
                  onSubmitted: (v) {
                    setState(() => _name = v);
                    _save();
                  },
                ),
              ),
              Builder(
                builder: (ctx) => UiPressable(
                  key: const Key('block-temp-save-folder'),
                  onTap: () {
                    final box = ctx.findRenderObject()! as RenderBox;
                    setState(
                      () => _folderMenu = UiPopoverAnchor(
                        box.localToGlobal(
                          box.size.bottomRight(const Offset(0, 4)),
                        ),
                        alignRight: true,
                      ),
                    );
                  },
                  builder: (context, hover) => Container(
                    height: 30,
                    constraints: const BoxConstraints(maxWidth: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    decoration: BoxDecoration(
                      color: hover ? c.hover : c.control,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 6,
                      children: [
                        UiGlyph(UiGlyphs.folder, size: 13, color: c.muted),
                        Flexible(
                          child: Text(
                            folderName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.sans(12.5, color: c.ink, height: 1.2),
                          ),
                        ),
                        UiGlyph(UiGlyphs.chevronDown, size: 12, color: c.muted),
                      ],
                    ),
                  ),
                ),
              ),
              UiBtn(
                key: const Key('block-temp-save-confirm'),
                size: UiBtnSize.small,
                tone: UiBtnTone.primary,
                onTap: _name.trim().isEmpty || _busy ? null : _save,
                children: [Text(l.blocks_tempSaveConfirm)],
              ),
            ],
          ),
        ],
      ),
    );

    final card = UiPopoverSurface(
      width: BlockTempCard.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [head, body, footer, if (_saving) saveRow],
      ),
    );

    return UiPopover(
      anchor: _folderMenu,
      onDismiss: () => setState(() => _folderMenu = null),
      builder: (_) => UiMenu(
        items: [
          UiMenuItem(
            glyph: UiGlyphs.folder,
            label: l.blocks_uncategorized,
            checked: _folderId == null,
            onTap: () => setState(() => _folderId = null),
          ),
          for (final f in d.folders)
            UiMenuItem(
              glyph: UiGlyphs.folder,
              label: f.name,
              indent: f.depth * 14.0,
              checked: _folderId == f.id,
              onTap: () => setState(() => _folderId = f.id),
            ),
        ],
        onClose: () => setState(() => _folderMenu = null),
      ),
      child: UiPopover(
        anchor: _menu,
        onDismiss: () => setState(() => _menu = null),
        builder: (_) => UiMenu(
          items: [
            if (!d.standalone)
              UiMenuItem(
                glyph: UiGlyphs.external,
                label: l.blocks_tempShowOriginal,
                onTap: a.onShowInLibrary,
              ),
            UiMenuItem(
              glyph: UiGlyphs.copy,
              label: l.blocks_copySend,
              onTap: a.onCopySend,
            ),
            if (a.onExpand != null)
              UiMenuItem(
                key: const Key('block-card-expand'),
                glyph: UiGlyphs.unfold,
                label: l.blocks_expandToText,
                onTap: a.onExpand!,
              ),
            UiMenuItem(
              glyph: d.enabled ? UiGlyphs.eyeOff : UiGlyphs.eye,
              label: d.enabled ? l.blocks_disable : l.blocks_enable,
              onTap: () => a.onEnabledChanged(!d.enabled),
            ),
            UiMenuItem(
              glyph: UiGlyphs.trash,
              label: l.blocks_removeInstance,
              danger: true,
              divider: true,
              onTap: a.onRemove,
            ),
          ],
          onClose: () => setState(() => _menu = null),
        ),
        child: card,
      ),
    );
  }

  void _save() {
    final save = a.onSaveTempAsNewBlock;
    final name = _name.trim();
    if (save == null || name.isEmpty) return;
    _run(() => save(name, _folderId));
  }

  /// 对比原块：按原块顺序列出，被删的划掉；新增的词接在后面。
  List<InlineSpan> _diffSpans(
    List<String> original,
    List<String> current,
    _Hz hz,
  ) {
    final currentSet = current.map(_norm).toSet();
    final originalSet = original.map(_norm).toSet();
    final spans = <InlineSpan>[];
    void sep() {
      if (spans.isNotEmpty) spans.add(const TextSpan(text: ', '));
    }

    for (final t in original) {
      sep();
      spans.add(
        currentSet.contains(_norm(t))
            ? TextSpan(text: t)
            : TextSpan(
                text: t,
                style: TextStyle(
                  backgroundColor: hz.del,
                  color: hz.delInk,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: hz.delInk,
                ),
              ),
      );
    }
    for (final t in current.where((t) => !originalSet.contains(_norm(t)))) {
      sep();
      spans.add(
        TextSpan(
          text: t,
          style: TextStyle(backgroundColor: hz.add, color: hz.addInk),
        ),
      );
    }
    return spans;
  }
}
