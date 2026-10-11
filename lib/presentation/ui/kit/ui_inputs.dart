import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui_colors.dart';
import 'ui_glyph.dart';
import 'ui_keycap.dart';
import 'ui_lib_controls.dart';
import 'ui_text.dart';

/// 搜索框：控件底、圆角 9（[height] 32 时圆角 7）；聚焦时抬起底 + 强调色环。
/// 停 300ms 回调；有字时尾部是清除，空着且没聚焦时显示 “/” 键帽。Esc 先清空、再失焦。
/// [value] 是外部的当前值：外部改了（例如切范围时清空搜索）会同步进来，正在输入时不覆盖。
class UiSearchField extends StatefulWidget {
  const UiSearchField({
    super.key,
    required this.value,
    required this.hint,
    required this.onChanged,
    this.focusNode,
    this.height = 36,
    this.enabled = true,
  });

  final String value;
  final String hint;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;
  final double height;
  final bool enabled;

  @override
  State<UiSearchField> createState() => _UiSearchFieldState();
}

class _UiSearchFieldState extends State<UiSearchField> {
  late final _ctrl = TextEditingController(text: widget.value);
  late var _synced = widget.value;
  Timer? _debounce;
  FocusNode? _own;

  FocusNode get _focus => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void didUpdateWidget(covariant UiSearchField old) {
    super.didUpdateWidget(old);
    if (widget.value != _synced && _debounce?.isActive != true) {
      _synced = widget.value;
      if (_ctrl.text != widget.value) _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _own?.dispose();
    super.dispose();
  }

  void _changed(String v) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _submit(v));
  }

  void _submit(String v) {
    _debounce?.cancel();
    _synced = v.trim();
    widget.onChanged(v.trim());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final small = widget.height < 36;
    return ListenableBuilder(
      listenable: _focus,
      builder: (context, _) {
        final on = _focus.hasFocus;
        return Container(
          height: widget.height,
          padding: EdgeInsets.only(left: small ? 10 : 11, right: 6),
          decoration: BoxDecoration(
            color: on ? c.raised : c.control,
            borderRadius: BorderRadius.circular(small ? 7 : 9),
            boxShadow: on
                ? [
                    BoxShadow(
                      color: c.accent.withValues(alpha: small ? .15 : .14),
                      spreadRadius: 4,
                    ),
                    BoxShadow(color: c.accent, spreadRadius: 1),
                  ]
                : null,
          ),
          child: Row(
            spacing: small ? 7 : 8,
            children: [
              UiGlyph(UiGlyphs.search, size: 15, color: c.faint),
              Expanded(
                child: Focus(
                  onKeyEvent: (_, e) {
                    if (e is KeyDownEvent &&
                        e.logicalKey == LogicalKeyboardKey.escape) {
                      if (_ctrl.text.isNotEmpty) {
                        _ctrl.clear();
                        _submit('');
                      } else {
                        _focus.unfocus();
                      }
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    enabled: widget.enabled,
                    style: UiText.sans(small ? 12.5 : 13, color: c.ink),
                    cursorColor: c.accent,
                    cursorHeight: 15,
                    decoration: uiBareDecoration(
                      hintText: widget.hint,
                      hintStyle: UiText.sans(small ? 12.5 : 13, color: c.faint),
                    ),
                    onChanged: _changed,
                    onSubmitted: _submit,
                  ),
                ),
              ),
              if (_ctrl.text.isNotEmpty)
                UiIconBox(
                  glyph: UiGlyphs.close,
                  size: small ? 22 : 24,
                  glyphSize: 13,
                  onTap: () {
                    _ctrl.clear();
                    _submit('');
                  },
                )
              else if (!on)
                const UiKeycap('/'),
            ],
          ),
        );
      },
    );
  }
}

/// 表单输入框（原型 `.tin`）：最小高 34、圆角 7、1px 较深描边、窗口底；聚焦时强调色描边 + 3px 浅环。
/// 回车 / 失焦调 [onSubmitted]；[onChanged] 每次输入都调。
class UiTextInput extends StatefulWidget {
  const UiTextInput({
    super.key,
    required this.value,
    this.onChanged,
    this.onSubmitted,
    this.hint,
    this.autofocus = false,
    this.selectAll = false,
    this.style,
    this.height = 34,
    this.focusNode,
  });

  final String value;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? hint;
  final bool autofocus;

  /// 获得焦点时全选（重命名）。
  final bool selectAll;
  final TextStyle? style;
  final double height;
  final FocusNode? focusNode;

  @override
  State<UiTextInput> createState() => _UiTextInputState();
}

class _UiTextInputState extends State<UiTextInput> {
  late final _ctrl = TextEditingController(text: widget.value);
  FocusNode? _own;
  FocusNode get _focus => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void initState() {
    super.initState();
    if (widget.selectAll) {
      _ctrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.value.length,
      );
    }
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (!_focus.hasFocus) widget.onSubmitted?.call(_ctrl.text);
  }

  @override
  void didUpdateWidget(covariant UiTextInput old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value && widget.value != _ctrl.text) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _ctrl.dispose();
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return ListenableBuilder(
      listenable: _focus,
      builder: (context, _) {
        final on = _focus.hasFocus;
        return Container(
          constraints: BoxConstraints(minHeight: widget.height),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: on ? c.accent : c.strong),
            boxShadow: on
                ? [
                    BoxShadow(
                      color: c.accent.withValues(alpha: .15),
                      spreadRadius: 3,
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: _ctrl,
            focusNode: _focus,
            autofocus: widget.autofocus,
            style: widget.style ?? UiText.sans(13, color: c.ink),
            cursorColor: c.accent,
            cursorHeight: 15,
            decoration: uiBareDecoration(
              hintText: widget.hint,
              hintStyle: UiText.sans(13, color: c.faint),
            ),
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
          ),
        );
      },
    );
  }
}

/// 按偏移和缩放裁出一块的图片（与旧 `ThumbnailDisplay` 同一坐标系）：先铺满（cover），
/// 再以 [offsetX] / [offsetY]（−1…1，选区在原图里的位置）为锚点放大 [scale] 倍（1…3）。
class UiCroppedImage extends StatelessWidget {
  const UiCroppedImage({
    super.key,
    required this.image,
    this.offsetX = 0,
    this.offsetY = 0,
    this.scale = 1,
  });

  final ImageProvider image;
  final double offsetX;
  final double offsetY;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final a = Alignment(offsetX.clamp(-1.0, 1.0), offsetY.clamp(-1.0, 1.0));
    return ClipRect(
      child: Transform.scale(
        scale: scale.clamp(1.0, 3.0),
        alignment: a,
        child: SizedBox.expand(
          child: Image(
            image: image,
            fit: BoxFit.cover,
            alignment: a,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}
