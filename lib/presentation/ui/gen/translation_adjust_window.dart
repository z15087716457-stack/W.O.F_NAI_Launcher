import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../agent/agent_contract.dart';
import '../agent/agent_thread.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';

/// 「追加翻译调整」浮窗（原型 .devin/mockups/fix-batch-1024 场景 translate）。
/// 纯界面：会话、块引用和撤销都由接线层给数据和回调。

enum TranslationAdjustQuick { split, retranslate, merge }

enum TranslationAdjustStepStatus { running, done, failed }

sealed class TranslationAdjustEntry {
  const TranslationAdjustEntry();
}

final class TranslationAdjustUser extends TranslationAdjustEntry {
  const TranslationAdjustUser(this.text);
  final String text;
}

final class TranslationAdjustThinking extends TranslationAdjustEntry {
  const TranslationAdjustThinking(this.text, {this.live = false});
  final String text;
  final bool live;
}

final class TranslationAdjustReply extends TranslationAdjustEntry {
  const TranslationAdjustReply(this.markdown);
  final String markdown;
}

/// 连续的工具步骤合成一张小卡。
final class TranslationAdjustSteps extends TranslationAdjustEntry {
  const TranslationAdjustSteps(this.steps);
  final List<TranslationAdjustStep> steps;
}

class TranslationAdjustStep {
  const TranslationAdjustStep({
    required this.id,
    required this.label,
    required this.status,
    this.subject,
  });
  final String id;
  final String label;
  final String? subject;
  final TranslationAdjustStepStatus status;
}

class TranslationAdjustView {
  const TranslationAdjustView({
    required this.blockCount,
    required this.entries,
    required this.selected,
    required this.modelLabel,
    this.busy = false,
    this.canUndo = false,
    this.error,
  });
  final int blockCount;
  final List<TranslationAdjustEntry> entries;

  /// 已引用的块数。
  final int selected;
  final String modelLabel;
  final bool busy, canUndo;
  final String? error;
}

class TranslationAdjustActions {
  const TranslationAdjustActions({
    required this.onSend,
    required this.onStop,
    required this.onUndo,
    required this.onClose,
    required this.onClearSelected,
    required this.quickText,
    required this.onOpenLink,
  });
  final ValueChanged<String> onSend;
  final VoidCallback onStop, onUndo, onClose, onClearSelected;

  /// 快捷动作填进输入框的文字（模板 + 当前引用）。
  final String Function(TranslationAdjustQuick kind) quickText;
  final ValueChanged<String> onOpenLink;
}

class TranslationAdjustWindow extends StatefulWidget {
  const TranslationAdjustWindow({
    super.key,
    required this.anchor,
    required this.view,
    required this.actions,
  });

  /// 提示词框的位置；浮窗默认贴在它右侧。
  final Rect anchor;
  final TranslationAdjustView view;
  final TranslationAdjustActions actions;

  @override
  State<TranslationAdjustWindow> createState() =>
      _TranslationAdjustWindowState();
}

class _TranslationAdjustWindowState extends State<TranslationAdjustWindow> {
  static const _width = 392.0;
  static const _head = 52.0;
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  Offset? _position;
  var _collapsed = false;

  @override
  void didUpdateWidget(TranslationAdjustWindow old) {
    super.didUpdateWidget(old);
    if (old.view.entries.length != widget.view.entries.length ||
        old.view.busy != widget.view.busy) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    if (widget.view.busy || _text.text.trim().isEmpty) return;
    final text = _text.text;
    _text.clear();
    widget.actions.onSend(text);
  }

  KeyEventResult _key(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent ||
        (event.logicalKey != LogicalKeyboardKey.enter &&
            event.logicalKey != LogicalKeyboardKey.numpadEnter)) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      final value = _text.value;
      final sel = value.selection;
      final start = sel.isValid ? sel.start : value.text.length;
      final end = sel.isValid ? sel.end : value.text.length;
      _text.value = TextEditingValue(
        text: value.text.replaceRange(start, end, '\n'),
        selection: TextSelection.collapsed(offset: start + 1),
      );
    } else {
      _send();
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final size = MediaQuery.sizeOf(context);
    final width = math.min(_width, size.width - 16);
    final height = _collapsed ? _head + 2 : math.min(600.0, size.height - 16);
    final position =
        _position ?? Offset(widget.anchor.right + 12, widget.anchor.top);
    final left = position.dx
        .clamp(8.0, math.max(8.0, size.width - width - 8))
        .toDouble();
    final top = position.dy
        .clamp(8.0, math.max(8.0, size.height - height - 8))
        .toDouble();
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Material(
        type: MaterialType.transparency,
        child: UiPopoverSurface(
          key: const Key('translation-adjustment-window'),
          radius: 14,
          color: c.raised,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context, Offset(left, top)),
              if (!_collapsed) ...[
                Container(height: 1, color: c.line),
                Expanded(child: _body(context)),
                _quick(context),
                _composer(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, Offset at) {
    final c = context.ui;
    final l = context.l10n;
    return GestureDetector(
      key: const Key('translation-adjustment-drag'),
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (e) =>
          setState(() => _position = (_position ?? at) + e.delta),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: SizedBox(
          height: _head,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
            child: Row(
              children: [
                UiGlyph(UiGlyphs.translate, size: 16, color: c.ink),
                const SizedBox(width: 8),
                Text(
                  l.gen_translateAdjustTitle,
                  style: UiText.sans(13, weight: FontWeight.w600, color: c.ink),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: c.control,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: widget.view.error == null ? c.ok : c.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              l.gen_translateAdjustContext(
                                widget.view.blockCount,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: UiText.sans(
                                11,
                                color: c.muted,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                UiIconBox(
                  key: const Key('translation-adjustment-collapse'),
                  glyph: _collapsed ? UiGlyphs.chevronDown : UiGlyphs.chevronUp,
                  size: 28,
                  tooltip: l.gen_translateAdjustCollapse,
                  onTap: () => setState(() => _collapsed = !_collapsed),
                ),
                UiIconBox(
                  key: const Key('translation-adjustment-close'),
                  glyph: UiGlyphs.close,
                  size: 28,
                  tooltip: l.common_close,
                  onTap: widget.actions.onClose,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final v = widget.view;
    final children = <Widget>[
      if (v.entries.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
          child: Text(
            l.gen_translateAdjustIntro,
            textAlign: TextAlign.center,
            style: UiText.sans(11.5, color: c.faint, height: 1.6),
          ),
        ),
      for (final e in v.entries) _entry(context, e),
      if (v.busy &&
          (v.entries.isEmpty || v.entries.last is TranslationAdjustUser))
        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 2),
            child: UiSpinner(size: 13),
          ),
        ),
      if (v.error != null)
        Text(
          v.error!,
          key: const Key('translation-adjustment-error'),
          style: UiText.sans(12, color: c.error, height: 1.55),
        ),
    ];
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(height: 11),
      itemBuilder: (_, i) => children[i],
    );
  }

  Widget _entry(BuildContext context, TranslationAdjustEntry e) {
    final c = context.ui;
    return switch (e) {
      TranslationAdjustUser(:final text) => Align(
        alignment: Alignment.centerRight,
        child: FractionallySizedBox(
          widthFactor: .9,
          alignment: Alignment.centerRight,
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: c.control,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                text,
                style: UiText.sans(12.5, color: c.ink, height: 1.6),
              ),
            ),
          ),
        ),
      ),
      TranslationAdjustThinking(:final text, :final live) => AgentThinking(
        block: AgentThinkingBlock(text, live: live),
      ),
      TranslationAdjustReply(:final markdown) => AgentMarkdown(
        markdown,
        onOpenLink: widget.actions.onOpenLink,
      ),
      TranslationAdjustSteps(:final steps) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: c.panel,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, s) in steps.indexed) ...[
              if (i > 0) const SizedBox(height: 4),
              _step(context, s),
            ],
          ],
        ),
      ),
    };
  }

  Widget _step(BuildContext context, TranslationAdjustStep s) {
    final c = context.ui;
    final l = context.l10n;
    final icon = switch (s.status) {
      TranslationAdjustStepStatus.running => const UiSpinner(size: 12),
      TranslationAdjustStepStatus.done => UiGlyph(
        UiGlyphs.check,
        size: 13,
        color: c.ok,
      ),
      TranslationAdjustStepStatus.failed => UiGlyph(
        UiGlyphs.close,
        size: 13,
        color: c.error,
      ),
    };
    return Row(
      key: Key('translation-adjustment-step-${s.id}'),
      children: [
        SizedBox(width: 14, child: Center(child: icon)),
        const SizedBox(width: 7),
        Text(
          s.label,
          style: UiText.sans(12, weight: FontWeight.w500, color: c.ink),
        ),
        if (s.subject != null) ...[
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              s.subject!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(12, color: c.muted),
            ),
          ),
        ] else
          const Spacer(),
        if (s.status == TranslationAdjustStepStatus.failed)
          Text(l.ag_stepFailed, style: UiText.sans(11, color: c.error)),
      ],
    );
  }

  Widget _quick(BuildContext context) {
    final l = context.l10n;
    Widget chip(TranslationAdjustQuick kind, String glyph, String label) =>
        _QuickChip(
          key: Key('translation-adjustment-quick-${kind.name}'),
          glyph: glyph,
          label: label,
          onTap: () {
            final text = widget.actions.quickText(kind);
            _text.value = TextEditingValue(
              text: text,
              selection: TextSelection.collapsed(offset: text.length),
            );
            _focus.requestFocus();
          },
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          chip(
            TranslationAdjustQuick.split,
            UiGlyphs.scissors,
            l.gen_translateAdjustSplit,
          ),
          chip(
            TranslationAdjustQuick.retranslate,
            UiGlyphs.refresh,
            l.gen_translateAdjustRetranslate,
          ),
          chip(
            TranslationAdjustQuick.merge,
            UiGlyphs.merge,
            l.gen_translateAdjustMerge,
          ),
        ],
      ),
    );
  }

  Widget _composer(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final v = widget.view;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (v.selected > 0) ...[
                _RefChip(
                  label: l.gen_translateAdjustSelected(v.selected),
                  tooltip: l.gen_translateAdjustClearRefs,
                  onClear: widget.actions.onClearSelected,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  l.gen_translateAdjustPickHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(11, color: c.faint),
                ),
              ),
              if (v.canUndo)
                UiPressable(
                  key: const Key('translation-adjustment-undo'),
                  onTap: widget.actions.onUndo,
                  builder: (context, hover) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        UiGlyph(
                          UiGlyphs.undo,
                          size: 12,
                          color: hover ? c.ink : c.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l.common_undo,
                          style: UiText.sans(
                            11.5,
                            color: hover ? c.ink : c.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Focus(
            onKeyEvent: _key,
            child: TextField(
              key: const Key('translation-adjustment-input'),
              controller: _text,
              focusNode: _focus,
              minLines: 1,
              maxLines: 4,
              style: UiText.sans(12.5, color: c.ink, height: 1.5),
              cursorColor: c.accent,
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: l.gen_translateAdjustHint,
                hintStyle: UiText.sans(12.5, color: c.faint, height: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Spacer(),
              Flexible(
                child: Container(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: c.control,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      UiGlyph(UiGlyphs.spark, size: 12, color: c.muted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          v.modelLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.sans(12, color: c.muted, height: 1.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: v.busy ? l.ag_stop : l.ag_send,
                child: UiPressable(
                  key: const Key('translation-adjustment-send'),
                  onTap: v.busy ? widget.actions.onStop : _send,
                  builder: (context, hover) => Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: hover ? c.ink.withValues(alpha: .86) : c.ink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: UiGlyph(
                      v.busy ? UiGlyphs.stop : UiGlyphs.send,
                      key: Key(
                        v.busy
                            ? 'translation-adjustment-stop-glyph'
                            : 'translation-adjustment-send-glyph',
                      ),
                      size: v.busy ? 12 : 15,
                      filled: v.busy,
                      color: c.bg,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    super.key,
    required this.glyph,
    required this.label,
    required this.onTap,
  });
  final String glyph, label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      onTap: onTap,
      builder: (context, hover) => Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: c.bg,
          border: Border.all(color: hover ? c.strong : c.line),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UiGlyph(glyph, size: 13, color: hover ? c.ink : c.muted),
            const SizedBox(width: 5),
            Text(
              label,
              style: UiText.sans(
                12,
                color: hover ? c.ink : c.muted,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefChip extends StatelessWidget {
  const _RefChip({
    required this.label,
    required this.tooltip,
    required this.onClear,
  });
  final String label, tooltip;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      key: const Key('translation-adjustment-refs'),
      padding: const EdgeInsets.fromLTRB(7, 2, 3, 2),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: UiText.sans(11.5, color: c.accent, height: 1.3)),
          const SizedBox(width: 3),
          Tooltip(
            message: tooltip,
            child: UiPressable(
              onTap: onClear,
              builder: (context, hover) => UiGlyph(
                UiGlyphs.close,
                size: 11,
                color: c.accent.withValues(alpha: hover ? 1 : .7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
