import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_preview_image.dart';
import '../kit/ui_text.dart';
import 'agent_contract.dart';
import 'agent_glyphs.dart';
import 'agent_parts.dart';
import 'agent_position_board.dart';
import 'agent_tag_window.dart';

/// Conversation-only view: no providers, disk access or draft writes.
class AgentPromptSetCard extends StatefulWidget {
  const AgentPromptSetCard({
    super.key,
    required this.data,
    required this.onAction,
    required this.onEdit,
    required this.onImage,
  });
  final AgentPromptSet? data;
  final Future<void> Function(int, AgentPromptSetAction) onAction;
  final ValueChanged<String> onEdit;
  final void Function(AgentImage, List<AgentImage>) onImage;

  @override
  State<AgentPromptSetCard> createState() => _AgentPromptSetCardState();
}

class _AgentPromptSetCardState extends State<AgentPromptSetCard> {
  final _focus = FocusNode();
  int _index = 0;
  bool _overview = false, _prompt = false, _all = false;

  @override
  void didUpdateWidget(covariant AgentPromptSetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final count = widget.data?.items.length;
    if (count != null) _index = _index.clamp(0, count - 1);
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _go(int index) {
    if (index < 0 || index >= widget.data!.items.length) return;
    setState(() {
      _index = index;
      _overview = false;
    });
    _focus.requestFocus();
  }

  Widget _text(
    String text, {
    double size = 12,
    Color? color,
    bool bold = false,
    int? lines,
  }) => Text(
    text,
    maxLines: lines,
    overflow: lines == null ? null : TextOverflow.ellipsis,
    style: UiText.sans(
      size,
      color: color ?? context.ui.ink,
      weight: bold ? FontWeight.w600 : FontWeight.w400,
    ),
  );

  Widget _box(
    Widget child, {
    Color? color,
    Color? border,
    double radius = 8,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      border: border == null ? null : Border.all(color: border),
      borderRadius: BorderRadius.circular(radius),
    ),
    child: child,
  );

  Widget _iconButton(
    String key,
    String glyph,
    String tip,
    VoidCallback? action, {
    bool active = false,
  }) => AgentIconButton(
    key: Key(key),
    glyph: glyph,
    tooltip: tip,
    onPressed: action,
    active: active,
  );

  List<AgentDiffSegment> _segments(String shared, String addition) {
    final tags = <AgentDiffSegment>[];
    for (final (text, kind) in [
      (shared, AgentDiffKind.same),
      (addition, AgentDiffKind.added),
    ]) {
      for (final tag
          in text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty)) {
        tags.add(AgentDiffSegment('${tags.isEmpty ? '' : ' '}$tag,', kind));
      }
    }
    if (tags.isNotEmpty) {
      final last = tags.removeLast();
      tags.add(
        AgentDiffSegment(
          last.text.substring(0, last.text.length - 1),
          last.kind,
        ),
      );
    }
    return tags;
  }

  Widget _promptView(AgentPromptSet data, AgentPromptSetItem item) {
    final c = context.ui, l = context.l10n;
    final fields = [
      (l.ag_psMain, data.shared.main, item.main),
      for (var j = 0; j < data.shared.characters.length; j++)
        (
          l.ag_psCharacter(j + 1),
          data.shared.characters[j],
          j < item.characters.length ? item.characters[j] : '',
        ),
      (l.ag_psNegative, data.shared.negative, ''),
    ];
    final windows = [
      for (final field in fields)
        agentDiffWindow(_segments(field.$2, field.$3), windowUnchanged: true),
    ];
    final hidden = windows.any((w) => w.contains(null));
    final marks = item.positionMarks(data.shared);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: _box(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              key: const Key('agent-ps-prompt'),
              borderRadius: BorderRadius.circular(9),
              onTap: () => setState(() => _prompt = !_prompt),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: Row(
                  spacing: 6,
                  children: [
                    AgentIcon(
                      _prompt ? AgentGlyphs.chevron : AgentGlyphs.chevronRight,
                      size: 13,
                    ),
                    _text(l.ag_psPrompt, color: c.muted),
                    const Spacer(),
                    _box(
                      const SizedBox(width: 7, height: 7),
                      color: c.faint.withValues(alpha: .5),
                      radius: 2,
                    ),
                    Flexible(
                      child: _text(
                        l.ag_psShared,
                        size: 11,
                        color: c.faint,
                        lines: 1,
                      ),
                    ),
                    _box(
                      const SizedBox(width: 7, height: 7),
                      color: c.warnBg,
                      border: c.warn,
                      radius: 2,
                    ),
                    Flexible(
                      child: _text(
                        l.ag_psThisItem(data.unit),
                        size: 11,
                        color: c.faint,
                        lines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_prompt)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, field) in fields.indexed) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 2),
                        child: _text(field.$1, size: 11, color: c.faint),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            for (final seg
                                in _all
                                    ? _segments(field.$2, field.$3)
                                    : windows[i])
                              TextSpan(
                                text: seg?.text ?? '… ',
                                style:
                                    UiText.mono(
                                      11.8,
                                      color: seg?.kind == AgentDiffKind.added
                                          ? c.warn
                                          : c.faint,
                                    ).copyWith(
                                      backgroundColor:
                                          seg?.kind == AgentDiffKind.added
                                          ? c.warnBg
                                          : null,
                                    ),
                              ),
                          ],
                        ),
                        style: UiText.mono(11.8, height: 1.6),
                      ),
                      if (i == data.shared.characters.length &&
                          marks.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: AgentPositionBoard(
                              key: const Key('agent-ps-position-preview'),
                              height: 84,
                              block: AgentPositionBlock(
                                id: 'prompt-set/${data.setId}/$_index',
                                aspect: data.aspect,
                                marks: marks,
                              ),
                            ),
                          ),
                        ),
                    ],
                    if (hidden || _all)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          key: const Key('agent-ps-more-prompt'),
                          onPressed: () => setState(() => _all = !_all),
                          child: _text(
                            _all ? l.ag_diffCollapse : l.ag_diffExpand,
                            color: c.accent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
        border: c.border,
        radius: 9,
      ),
    );
  }

  Future<void> _menu(AgentPromptSet data, Offset position) async {
    final l = context.l10n;
    final selected = _index, item = data.items[_index];
    final choice = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, 0, 0),
      items: [
        PopupMenuItem(
          value: 0,
          child: Row(
            spacing: 8,
            children: [
              const AgentIcon(AgentGlyphs.layers),
              _text(l.ag_psSaveBlock),
            ],
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: Row(
            spacing: 8,
            children: [
              const AgentIcon(AgentGlyphs.copy),
              _text(l.ag_psCopyItem(data.unit)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 2,
          child: Row(
            spacing: 8,
            children: [
              const AgentIcon(AgentGlyphs.copy),
              _text(l.ag_psCopyAll),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 3,
          child: Row(
            spacing: 8,
            children: [
              const AgentIcon(AgentGlyphs.pen),
              _text(l.ag_psEditItem(data.unit)),
            ],
          ),
        ),
      ],
    );
    if (!mounted || choice == null) return;
    if (choice == 3) {
      widget.onEdit(
        l.ag_psEditDraft(data.title, selected + 1, data.unit, item.title),
      );
    } else {
      await widget.onAction(
        selected,
        [
          AgentPromptSetAction.saveBlock,
          AgentPromptSetAction.copyItem,
          AgentPromptSetAction.copyAll,
        ][choice],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui, l = context.l10n;
    final data = widget.data;
    if (data == null) {
      return _box(
        Padding(
          padding: const EdgeInsets.all(12),
          child: _text(l.ag_psMissing, color: c.faint),
        ),
        border: c.border,
      );
    }
    final item = data.items[_index], count = data.items.length;
    final shots = data.images[_index] ?? [];
    return Focus(
      focusNode: _focus,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent ||
            FocusManager.instance.primaryFocus?.context?.widget
                is EditableText) {
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _go(_index - 1);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _go(_index + 1);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: _focus.requestFocus,
        behavior: HitTestBehavior.translucent,
        child: _box(
          _content(data, item, count, shots),
          color: c.card,
          border: c.border,
          radius: 12,
        ),
      ),
    );
  }

  Widget _content(
    AgentPromptSet data,
    AgentPromptSetItem item,
    int count,
    List<AgentImage> shots,
  ) {
    final c = context.ui, l = context.l10n;
    return Column(
      key: Key('agent-ps-${data.setId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Row(
            spacing: 8,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      child: _box(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 5,
                          children: [
                            AgentIcon(
                              agentPromptSetGlyph(data.kindIcon),
                              size: 13,
                              color: c.accent,
                            ),
                            Flexible(
                              child: _text(
                                data.kind,
                                size: 11.5,
                                color: c.accent,
                                bold: true,
                                lines: 1,
                              ),
                            ),
                          ],
                        ),
                        color: Color.lerp(c.card, c.accent, .10)!,
                        radius: 99,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: _text(
                        data.title,
                        size: 13.5,
                        bold: true,
                        lines: 1,
                      ),
                    ),
                    _text(
                      '· ${l.ag_psCount(count, data.unit)}',
                      size: 12,
                      color: c.faint,
                    ),
                    if (data.revision > 1)
                      _box(
                        _text(
                          l.ag_psRevision(
                            data.revision,
                            data.changedItems.length,
                          ),
                          size: 11,
                          color: c.amber,
                        ),
                        border: c.amber.withValues(alpha: .4),
                        radius: 99,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                  ],
                ),
              ),
              _iconButton(
                'agent-ps-overview',
                AgentGlyphs.psGrid,
                _overview ? l.ag_psSingle : l.ag_psOverview,
                () => setState(() => _overview = !_overview),
                active: _overview,
              ),
            ],
          ),
        ),
        if (_overview)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: LayoutBuilder(
              builder: (context, box) {
                final columns = box.maxWidth < 360 ? 2 : 3;
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final (i, tile) in data.items.indexed)
                      SizedBox(
                        width: (box.maxWidth - 6 * (columns - 1)) / columns,
                        child: InkWell(
                          onTap: () => _go(i),
                          child: _box(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  spacing: 5,
                                  children: [
                                    AgentIcon(
                                      agentPromptSetGlyph(tile.icon),
                                      size: 13,
                                    ),
                                    _text(
                                      '${i + 1}'.padLeft(2, '0'),
                                      size: 11,
                                      color: c.faint,
                                    ),
                                    const Spacer(),
                                    if ((data.images[i] ?? []).isNotEmpty)
                                      _text(
                                        '● ${data.images[i]!.length}',
                                        size: 10,
                                        color: c.ok,
                                      ),
                                  ],
                                ),
                                _text(tile.title, bold: true, lines: 1),
                                _text(
                                  tile.note,
                                  size: 11,
                                  color: c.muted,
                                  lines: 2,
                                ),
                              ],
                            ),
                            border: i == _index ? c.accent : c.border,
                            radius: 9,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  spacing: 6,
                  children: [
                    _box(
                      _iconButton(
                        'agent-ps-prev',
                        'm15 18-6-6 6-6',
                        l.ag_psSingle,
                        _index == 0 ? null : () => _go(_index - 1),
                      ),
                      border: c.border,
                    ),
                    _box(
                      AgentIcon(agentPromptSetGlyph(item.icon), size: 17),
                      color: c.control,
                      padding: const EdgeInsets.all(7),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _text(
                            data.ordered
                                ? l.ag_psPosition(_index + 1, count, data.unit)
                                : l
                                      .ag_psPosition(
                                        _index + 1,
                                        count,
                                        data.unit,
                                      )
                                      .split(' / ')
                                      .first,
                            size: 11.5,
                            color: c.faint,
                            lines: 1,
                          ),
                          _text(item.title, size: 14, bold: true, lines: 1),
                        ],
                      ),
                    ),
                    _box(
                      _iconButton(
                        'agent-ps-next',
                        AgentGlyphs.chevronRight,
                        l.ag_psSingle,
                        _index == count - 1 ? null : () => _go(_index + 1),
                      ),
                      border: c.border,
                    ),
                  ],
                ),
                if (item.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _text(item.note, size: 13, color: c.muted),
                  ),
                if (shots.isNotEmpty || data.busyIndex == _index)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final (j, image) in shots.indexed)
                          GestureDetector(
                            onTap: () => widget.onImage(image, shots),
                            child: Container(
                              width: 58,
                              height: 84,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(color: c.border),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  UiPreviewImage(image: image.image),
                                  Positioned(
                                    left: 4,
                                    bottom: 3,
                                    child: _text(
                                      '#${j + 1}',
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (data.busyIndex == _index)
                          SizedBox(
                            width: 58,
                            height: 84,
                            child: _box(
                              Center(
                                child: _text(
                                  l.ag_psGenerating,
                                  size: 11,
                                  color: c.faint,
                                ),
                              ),
                              color: c.control,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          _promptView(data, item),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final (i, dot) in data.items.indexed)
                _box(
                  Stack(
                    children: [
                      _iconButton(
                        'agent-ps-dot-$i',
                        agentPromptSetGlyph(dot.icon),
                        '${i + 1} ${dot.title}',
                        () => _go(i),
                        active: i == _index,
                      ),
                      if ((data.images[i] ?? []).isNotEmpty)
                        Positioned(
                          right: 2,
                          top: 2,
                          child: _box(
                            const SizedBox(width: 6, height: 6),
                            color: c.ok,
                            radius: 99,
                          ),
                        ),
                      if (data.changedItems.contains(i))
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: _box(
                            const SizedBox(width: 5, height: 5),
                            color: c.warn,
                            radius: 99,
                          ),
                        ),
                    ],
                  ),
                  color: i == _index
                      ? Color.lerp(c.card, c.accent, .10)!
                      : null,
                  border: i == _index ? c.accent : null,
                  radius: 7,
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            spacing: 6,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Tooltip(
                      message: l.ag_psImportTip,
                      child: AgentButton(
                        key: const Key('agent-ps-import'),
                        label: l.ag_psImport,
                        glyph: 'M12 3v11M7.5 9.5 12 14l4.5-4.5M4 15v5h16v-5',
                        onPressed: data.busyIndex == null
                            ? () => widget.onAction(
                                _index,
                                AgentPromptSetAction.import,
                              )
                            : null,
                      ),
                    ),
                    AgentButton(
                      key: const Key('agent-ps-generate'),
                      label: l.ag_psGenerate,
                      glyph: AgentGlyphs.gen,
                      style: AgentButtonStyle.primary,
                      trailing: data.unitAnlas == null
                          ? null
                          : _box(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 3,
                                children: [
                                  AgentAnlas(size: 12, color: c.warn),
                                  _text(
                                    '${data.unitAnlas}',
                                    size: 11.5,
                                    color: c.bg,
                                  ),
                                ],
                              ),
                              color: c.bg.withValues(alpha: .18),
                              radius: 99,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                            ),
                      onPressed: data.busyIndex == null
                          ? () => widget.onAction(
                              _index,
                              AgentPromptSetAction.generate,
                            )
                          : null,
                    ),
                    Builder(
                      builder: (context) => _iconButton(
                        'agent-ps-menu',
                        AgentGlyphs.more,
                        l.ag_psCopyAll,
                        () {
                          final box = context.findRenderObject()! as RenderBox;
                          _menu(data, box.localToGlobal(Offset.zero));
                        },
                      ),
                    ),
                  ],
                ),
              ),
              _text('${_index + 1} / $count', color: c.faint),
            ],
          ),
        ),
        if (data.importedIndex case final imported?)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _box(
              Row(
                spacing: 8,
                children: [
                  AgentIcon(AgentGlyphs.check, color: c.ok),
                  Expanded(
                    child: _text(
                      l.ag_psImported(data.items[imported].title),
                      color: c.muted,
                    ),
                  ),
                  if (data.canUndoImport)
                    TextButton(
                      key: const Key('agent-ps-undo'),
                      onPressed: () =>
                          widget.onAction(imported, AgentPromptSetAction.undo),
                      child: _text(l.ag_diffUndo, color: c.accent),
                    ),
                ],
              ),
              color: c.control,
              radius: 9,
              padding: const EdgeInsets.all(8),
            ),
          ),
      ],
    );
  }
}
