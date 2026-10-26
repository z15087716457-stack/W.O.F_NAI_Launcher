import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../agent/agent_contract.dart';
import '../agent/agent_thread.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_text.dart';

/// 「追加翻译调整」浮窗，照原型 `.devin/mockups/fix-batch-1024/mock.html` 场景 translate
/// （`.tfloat`）。纯界面：会话、块引用、撤销都由接线层给数据和回调。

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

/// 原型 `.stepl`：一张小卡，每行一个块操作（`split_block  银色长发 → 2 块`）。
final class TranslationAdjustSteps extends TranslationAdjustEntry {
  const TranslationAdjustSteps(this.steps);
  final List<TranslationAdjustStep> steps;
}

class TranslationAdjustStep {
  const TranslationAdjustStep({
    required this.id,
    required this.op,
    required this.status,
    this.subject,
  });
  final String id;

  /// 等宽显示的操作名（split_block / merge_blocks / retranslate / rejoin）。
  final String op;
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

  /// 提示词框的位置；浮窗默认贴在它右侧 12px、顶对齐。
  final Rect anchor;
  final TranslationAdjustView view;
  final TranslationAdjustActions actions;

  static const width = 392.0;
  static const height = 600.0;

  @override
  State<TranslationAdjustWindow> createState() =>
      _TranslationAdjustWindowState();
}

class _TranslationAdjustWindowState extends State<TranslationAdjustWindow> {
  static const _headHeight = 49.0;
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
        if (mounted && _scroll.hasClients) {
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

  /// Enter 发送；Shift+Enter 换行。
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
    final screen = MediaQuery.sizeOf(context);
    final width = math.min(TranslationAdjustWindow.width, screen.width - 16);
    final height = _collapsed
        ? _headHeight + 2
        : math.min(TranslationAdjustWindow.height, screen.height - 16);
    final at = _position ?? Offset(widget.anchor.right + 12, widget.anchor.top);
    final left = at.dx
        .clamp(8.0, math.max(8.0, screen.width - width - 8))
        .toDouble();
    final top = at.dy
        .clamp(8.0, math.max(8.0, screen.height - height - 8))
        .toDouble();
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          key: const Key('translation-adjustment-window'),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: c.bg,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: c.dark ? .45 : .14),
                blurRadius: 56,
                offset: const Offset(0, 22),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: c.dark ? .3 : .06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _head(context, Offset(left, top)),
              if (!_collapsed) ...[
                Expanded(child: _body(context)),
                _quickActions(context),
                _composer(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// `.tfh`：图标 · 标题 · 上下文胶囊 · 收起 · 关闭；整条可拖。
  Widget _head(BuildContext context, Offset at) {
    final c = context.ui;
    final l = context.l10n;
    final v = widget.view;
    return GestureDetector(
      key: const Key('translation-adjustment-drag'),
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (e) =>
          setState(() => _position = (_position ?? at) + e.delta),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Container(
          height: _headHeight,
          padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
          decoration: BoxDecoration(
            border: _collapsed
                ? null
                : Border(bottom: BorderSide(color: c.line)),
          ),
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
                    key: const Key('translation-adjustment-context'),
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
                            color: v.error == null ? c.ok : c.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            l.gen_translateAdjustContext(v.blockCount),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.sans(11, color: c.muted, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _HeadButton(
                key: const Key('translation-adjustment-collapse'),
                glyph: _collapsed ? UiGlyphs.chevronUp : UiGlyphs.chevronDown,
                tooltip: l.gen_translateAdjustCollapse,
                onTap: () => setState(() => _collapsed = !_collapsed),
              ),
              _HeadButton(
                key: const Key('translation-adjustment-close'),
                glyph: UiGlyphs.close,
                tooltip: l.common_close,
                onTap: widget.actions.onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// `.tfb`：上下文说明 + 对话，间距 11。
  Widget _body(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final v = widget.view;
    final items = <Widget>[
      Text(
        v.entries.isEmpty
            ? '${l.gen_translateAdjustContextNote}\n${l.gen_translateAdjustIntro}'
            : l.gen_translateAdjustContextNote,
        textAlign: TextAlign.center,
        style: UiText.sans(11, color: c.faint, height: 1.6),
      ),
      for (final e in v.entries) _entry(context, e),
      if (v.busy &&
          (v.entries.isEmpty || v.entries.last is TranslationAdjustUser))
        const Align(alignment: Alignment.centerLeft, child: UiSpinner()),
      if (v.error != null)
        Text(
          v.error!,
          key: const Key('translation-adjustment-error'),
          style: UiText.sans(12, color: c.error, height: 1.6),
        ),
    ];
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 11),
      itemBuilder: (_, i) => items[i],
    );
  }

  Widget _entry(BuildContext context, TranslationAdjustEntry e) {
    final c = context.ui;
    return switch (e) {
      // `.mu`：右对齐气泡，最宽 90%，右下角小圆角。
      TranslationAdjustUser(:final text) => LayoutBuilder(
        builder: (context, box) => Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: box.maxWidth * .9),
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
      // `.reply`
      TranslationAdjustReply(:final markdown) => DefaultTextStyle.merge(
        style: UiText.sans(12.5, color: c.ink, height: 1.7),
        child: AgentMarkdown(markdown, onOpenLink: widget.actions.onOpenLink),
      ),
      // `.stepl`
      TranslationAdjustSteps(:final steps) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: c.panel,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 4,
          children: [for (final s in steps) _step(context, s)],
        ),
      ),
    };
  }

  Widget _step(BuildContext context, TranslationAdjustStep s) {
    final c = context.ui;
    final l = context.l10n;
    return Row(
      key: Key('translation-adjustment-step-${s.id}'),
      spacing: 7,
      children: [
        SizedBox.square(
          dimension: 13,
          child: switch (s.status) {
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
          },
        ),
        Text(
          s.op,
          style: UiText.mono(11.5, weight: FontWeight.w500, color: c.ink),
        ),
        Expanded(
          child: Text(
            s.subject ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: UiText.sans(12, color: c.muted),
          ),
        ),
        if (s.status == TranslationAdjustStepStatus.failed)
          Text(l.ag_stepFailed, style: UiText.sans(11, color: c.error)),
      ],
    );
  }

  /// `.qacts`：三个胶囊快捷动作，点了把模板填进输入框。
  Widget _quickActions(BuildContext context) {
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

  /// `.tcomp`：第一行引用胶囊 + 提示（+ 撤销），第二行输入 · 模型 · 发送。
  Widget _composer(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final v = widget.view;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          Row(
            spacing: 6,
            children: [
              if (v.selected > 0)
                _RefChip(
                  label: l.gen_translateAdjustSelected(v.selected),
                  tooltip: l.gen_translateAdjustClearRefs,
                  onClear: widget.actions.onClearSelected,
                ),
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
                  builder: (context, hover) => Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: [
                      UiGlyph(
                        UiGlyphs.undo,
                        size: 12,
                        color: hover ? c.ink : c.faint,
                      ),
                      Text(
                        l.common_undo,
                        style: UiText.sans(11, color: hover ? c.ink : c.faint),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Focus(
                    onKeyEvent: _key,
                    child: TextField(
                      key: const Key('translation-adjustment-input'),
                      controller: _text,
                      focusNode: _focus,
                      minLines: 1,
                      maxLines: 4,
                      style: UiText.sans(12.5, color: c.ink, height: 1.5),
                      cursorColor: c.accent,
                      cursorWidth: 1.5,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: l.gen_translateAdjustHint,
                        hintMaxLines: 1,
                        hintStyle: UiText.sans(
                          12.5,
                          color: c.faint,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // `.pchip`
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Container(
                  key: const Key('translation-adjustment-model'),
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: c.control,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: [
                      UiGlyph(UiGlyphs.spark, size: 12, color: c.muted),
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
              // `.send`：30×30 墨色方块，运行中换成停止。
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
                      color: hover ? c.ink.withValues(alpha: .85) : c.ink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: v.busy
                        ? UiGlyph(
                            UiGlyphs.stop,
                            key: const Key('translation-adjustment-stop-glyph'),
                            size: 11,
                            filled: true,
                            color: c.bg,
                          )
                        : UiGlyph(
                            UiGlyphs.arrowUp,
                            key: const Key('translation-adjustment-send-glyph'),
                            size: 15,
                            strokeWidth: 2,
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

/// `.ib`：28×28、圆角 6，悬停变墨色。
class _HeadButton extends StatelessWidget {
  const _HeadButton({
    super.key,
    required this.glyph,
    required this.tooltip,
    required this.onTap,
  });
  final String glyph, tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Tooltip(
      message: tooltip,
      child: UiPressable(
        onTap: onTap,
        builder: (context, hover) => Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hover ? c.hover : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: UiGlyph(glyph, size: 15, color: hover ? c.ink : c.muted),
        ),
      ),
    );
  }
}

/// `.qact`：高 26 胶囊，细边，悬停边框加深、字变墨色。
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
          spacing: 5,
          children: [
            UiGlyph(glyph, size: 13, color: hover ? c.ink : c.muted),
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

/// `.refchip`：浅蓝底、蓝字，右侧小 × 清除引用。
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
      padding: const EdgeInsets.fromLTRB(7, 2, 4, 2),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Text(label, style: UiText.sans(11.5, color: c.accent, height: 1.3)),
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
