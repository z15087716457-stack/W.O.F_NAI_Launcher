import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_dialog.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_text.dart';
import 'settings_kit.dart';

/// 设置页的二级弹窗：和设置页同一套卡片、字号、输入框和按钮，替换 Material 的 AlertDialog。
/// 遮罩颜色同 [UiModal]；出现时 160ms 淡入 + 轻微放大，减少动态效果时直接出现。
Future<T?> showSettingsDialog<T>(
  BuildContext context,
  WidgetBuilder builder, {
  bool dismissible = true,
}) {
  final dark = context.ui.dark;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: dark ? const Color(0x99000000) : const Color(0x730A0A0A),
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (context, _, _) => SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Material(
            type: MaterialType.transparency,
            child: Builder(builder: builder),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) {
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
      final t = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: t,
        child: ScaleTransition(
          scale: Tween(begin: .97, end: 1.0).animate(t),
          child: child,
        ),
      );
    },
  );
}

/// 弹窗外壳：标题区（可带图标格、副标题、右上角关闭）、正文、底栏（左侧说明 + 右侧按钮）。
/// Esc 关闭。正文超出高度时由调用方决定哪块滚动（通常用 [Flexible] 包住滚动区）。
class SettingsDialogFrame extends StatelessWidget {
  const SettingsDialogFrame({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.glyph,
    this.danger = false,
    this.actions = const [],
    this.footerLeading,
    this.width = 480,
    this.maxHeight = 720,
    this.onClose,
  });

  final String title;
  final Widget? subtitle;
  final String? glyph;
  final bool danger;
  final Widget body;
  final List<Widget> actions;
  final Widget? footerLeading;
  final double width;
  final double maxHeight;

  /// 关闭（右上角 ×、Esc）；默认 `Navigator.maybePop`。
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final close = onClose ?? () => Navigator.of(context).maybePop();
    final screen = MediaQuery.sizeOf(context);
    return Focus(
      autofocus: true,
      skipTraversal: true,
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
          close();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        width: math.min(width, screen.width - 48),
        constraints: BoxConstraints(
          maxHeight: math.min(maxHeight, screen.height - 48),
        ),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 40,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  if (glyph != null)
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: (danger ? c.error : c.accent).withValues(
                          alpha: .09,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: UiGlyph(
                        glyph!,
                        size: 17,
                        color: danger ? c.error : c.accent,
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: glyph == null ? 4 : 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 3,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: UiText.sans(
                                15,
                                weight: FontWeight.w600,
                                color: c.ink,
                                height: 1.35,
                              ),
                            ),
                          ),
                          if (subtitle != null)
                            DefaultTextStyle.merge(
                              style: UiText.sans(
                                12,
                                color: c.muted,
                                height: 1.5,
                              ),
                              child: subtitle!,
                            ),
                        ],
                      ),
                    ),
                  ),
                  SettingsIconBtn(
                    key: const Key('settings-dialog-close'),
                    glyph: UiGlyphs.close,
                    tooltip: context.l10n.common_close,
                    onTap: close,
                  ),
                ],
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                child: body,
              ),
            ),
            if (actions.isNotEmpty)
              UiDialogFooter(
                children: [
                  Expanded(
                    child: footerLeading == null
                        ? const SizedBox.shrink()
                        : DefaultTextStyle.merge(
                            style: UiText.sans(12, color: c.muted, height: 1.4),
                            child: footerLeading!,
                          ),
                  ),
                  ...actions,
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// 表单一项：标题（可带右侧淡字）、控件、下方说明或错误。
class SettingsField extends StatelessWidget {
  const SettingsField({
    super.key,
    required this.label,
    required this.child,
    this.trailing,
    this.help,
    this.error,
  });

  final String label;
  final String? trailing;
  final Widget child;
  final String? help;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: UiText.sans(12, weight: FontWeight.w500, color: c.ink),
              ),
            ),
            if (trailing != null)
              Text(trailing!, style: UiText.sans(11.5, color: c.faint)),
          ],
        ),
        child,
        if (error != null)
          Text(error!, style: UiText.sans(11.5, color: c.error, height: 1.5))
        else if (help != null)
          Text(help!, style: UiText.sans(11.5, color: c.muted, height: 1.5)),
      ],
    );
  }
}

/// 输入框（单行 / 多行）：和设置页 `.inp` 同外观，聚焦强调色描边 + 浅环，出错红描边。
class SettingsTextArea extends StatefulWidget {
  const SettingsTextArea({
    super.key,
    required this.controller,
    this.hint,
    this.minLines = 1,
    this.maxLines = 1,
    this.mono = false,
    this.autofocus = false,
    this.error = false,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? hint;
  final int minLines;
  final int maxLines;
  final bool mono;
  final bool autofocus;
  final bool error;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<SettingsTextArea> createState() => _SettingsTextAreaState();
}

class _SettingsTextAreaState extends State<SettingsTextArea> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final on = _focus.hasFocus;
    final single = widget.maxLines == 1;
    final style = widget.mono
        ? UiText.mono(12, color: c.ink, height: 1.55)
        : UiText.sans(13, color: c.ink, height: 1.55);
    return Container(
      constraints: BoxConstraints(minHeight: single ? 34 : 0),
      padding: EdgeInsets.symmetric(horizontal: 11, vertical: single ? 0 : 8),
      alignment: single ? Alignment.centerLeft : null,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.error
              ? c.error
              : on
              ? c.accent
              : c.border,
        ),
        boxShadow: on
            ? [
                BoxShadow(
                  color: (widget.error ? c.error : c.accent).withValues(
                    alpha: .16,
                  ),
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        autofocus: widget.autofocus,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        style: style,
        cursorColor: c.accent,
        decoration: uiBareDecoration(
          hintText: widget.hint,
          hintStyle: style.copyWith(color: c.faint),
        ),
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}

/// 复选一行：16px 方框 + 文字（+ 淡色说明），整行可点。
class SettingsCheckRow extends StatelessWidget {
  const SettingsCheckRow({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.help,
  });

  final bool value;
  final String label;
  final String? help;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Semantics(
      checked: value,
      child: UiPressable(
        onTap: () => onChanged(!value),
        builder: (context, hover) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 9,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: UiCheckBox(value: value),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(label, style: UiText.sans(12.5, color: c.ink)),
                  if (help != null)
                    Text(
                      help!,
                      style: UiText.sans(11.5, color: c.muted, height: 1.5),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 只读长文本（提示词、SKILL.md）：凹底、等宽、可选中、自带滚动条。
class SettingsCodeView extends StatefulWidget {
  const SettingsCodeView({super.key, required this.text, this.mono = true});
  final String text;
  final bool mono;

  @override
  State<SettingsCodeView> createState() => _SettingsCodeViewState();
}

class _SettingsCodeViewState extends State<SettingsCodeView> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      decoration: BoxDecoration(
        color: c.sunk,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: c.border),
      ),
      child: Scrollbar(
        controller: _scroll,
        child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: SelectableText(
            widget.text,
            style: widget.mono
                ? UiText.mono(12, color: c.ink, height: 1.65)
                : UiText.sans(12.5, color: c.ink, height: 1.65),
          ),
        ),
      ),
    );
  }
}

/// “复制”按钮：点后 1.5 秒内显示“已复制 ✓”。
class SettingsCopyButton extends StatefulWidget {
  const SettingsCopyButton({super.key, required this.text});
  final String text;

  @override
  State<SettingsCopyButton> createState() => _SettingsCopyButtonState();
}

class _SettingsCopyButtonState extends State<SettingsCopyButton> {
  var _done = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SettingsBtn(
      key: const Key('settings-dialog-copy'),
      label: _done ? l.common_copied : l.set_copy,
      glyph: _done ? UiGlyphs.check : UiGlyphs.copy,
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: widget.text));
        if (!mounted) return;
        setState(() => _done = true);
        _timer?.cancel();
        _timer = Timer(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _done = false);
        });
      },
    );
  }
}

/// 确认弹窗。[danger] 时图标和确认按钮用错误色。
class SettingsConfirmDialog extends StatelessWidget {
  const SettingsConfirmDialog({
    super.key,
    required this.title,
    required this.body,
    this.confirm,
    this.danger = false,
  });

  final String title;
  final String body;
  final String? confirm;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    return SettingsDialogFrame(
      key: const Key('settings-confirm-dialog'),
      width: 420,
      title: title,
      glyph: danger ? UiGlyphs.trash : UiGlyphs.infoCircle,
      danger: danger,
      body: Text(body, style: UiText.sans(13, color: c.muted, height: 1.65)),
      actions: [
        SettingsBtn(
          key: const Key('confirm-cancel'),
          label: l.set_cancel,
          onTap: () => Navigator.pop(context, false),
        ),
        SettingsBtn(
          key: const Key('confirm-ok'),
          label: confirm ?? l.common_confirm,
          tone: danger ? SettingsBtnTone.danger : SettingsBtnTone.primary,
          onTap: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}

/// 单项文字输入弹窗：[validate] 返回错误文字时就地标红，不关窗。
class SettingsTextDialog extends StatefulWidget {
  const SettingsTextDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.label,
    this.initial = '',
    this.hint,
    this.help,
    this.maxLines = 1,
    this.mono = false,
    this.confirm,
    this.validate,
  });

  final String title;
  final String? subtitle;
  final String? label;
  final String initial;
  final String? hint;
  final String? help;
  final int maxLines;
  final bool mono;
  final String? confirm;
  final String? Function(String value)? validate;

  @override
  State<SettingsTextDialog> createState() => _SettingsTextDialogState();
}

class _SettingsTextDialogState extends State<SettingsTextDialog> {
  late final _text = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _text.text.trim();
    final error = widget.validate?.call(value);
    if (error != null) return setState(() => _error = error);
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final single = widget.maxLines == 1;
    final input = SettingsTextArea(
      key: const Key('settings-dialog-input'),
      controller: _text,
      autofocus: true,
      hint: widget.hint,
      mono: widget.mono,
      minLines: single ? 1 : 6,
      maxLines: widget.maxLines,
      error: _error != null,
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
      onSubmitted: single ? (_) => _submit() : null,
    );
    return SettingsDialogFrame(
      width: single ? 440 : 600,
      title: widget.title,
      subtitle: widget.subtitle == null ? null : Text(widget.subtitle!),
      body: SingleChildScrollView(
        child: widget.label == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 6,
                children: [
                  input,
                  if (_error != null || widget.help != null)
                    Text(
                      _error ?? widget.help!,
                      style: UiText.sans(
                        11.5,
                        color: _error != null
                            ? context.ui.error
                            : context.ui.muted,
                        height: 1.5,
                      ),
                    ),
                ],
              )
            : SettingsField(
                label: widget.label!,
                help: widget.help,
                error: _error,
                child: input,
              ),
      ),
      actions: [
        SettingsBtn(label: l.set_cancel, onTap: () => Navigator.pop(context)),
        SettingsBtn(
          key: const Key('settings-dialog-ok'),
          label: widget.confirm ?? l.set_save,
          tone: SettingsBtnTone.primary,
          onTap: _submit,
        ),
      ],
    );
  }
}
