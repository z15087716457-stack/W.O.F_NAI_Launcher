import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_text.dart';
import 'gen_contract.dart';
import 'gen_format.dart';
import 'gen_page.dart';
import 'gen_parts.dart';

/// 图像模块（原型 `imageModuleA`）：尺寸一行（分组下拉、方向分段、宽 × 高）+ 张数 / 重复一行。
class GenImageModule extends StatelessWidget {
  const GenImageModule({super.key, this.showCount = true});
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return GenModule(
      key: const Key('gen-image'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GenModuleHeader(children: [Text(l.gen_image)]),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: _SizeRow(),
          ),
          if (showCount)
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: _CountRow(),
            ),
        ],
      ),
    );
  }
}

class _SizeRow extends StatelessWidget {
  const _SizeRow();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context, GenAspect.image);
    final img = scope.data.image;
    final l = context.l10n;
    final o = GenFormat.orientationOf(img.width, img.height);
    final match = img.presets
        .where((p) => p.width == img.width && p.height == img.height)
        .firstOrNull;
    final group = match?.group ?? GenSizeGroup.custom;
    GenSizePreset? presetOf(GenSizeGroup g, GenOrientation o) => img.presets
        .where((p) => p.group == g && p.orientation == o)
        .firstOrNull;
    void setOrientation(GenOrientation next) {
      final p = presetOf(group, next);
      if (p != null) {
        scope.actions.onSizeChanged(p.width, p.height);
        return;
      }
      final (w, h) = (img.width, img.height);
      final long = w > h ? w : h;
      final short = w > h ? h : w;
      switch (next) {
        case GenOrientation.portrait:
          scope.actions.onSizeChanged(short, long);
        case GenOrientation.landscape:
          scope.actions.onSizeChanged(long, short);
        case GenOrientation.square:
          scope.actions.onSizeChanged(short, short);
      }
    }

    return LayoutBuilder(
      builder: (context, box) {
        // 窄栏（左栏 < 400）下拉缩到 80，宽高框缩到 52。
        final tight = box.maxWidth < 350;
        final compact = box.maxWidth < 330;
        return Row(
          spacing: compact ? 4 : 8,
          children: [
            Builder(
              builder: (ctx) => UiPressable(
                key: const Key('gen-size-group'),
                onTap: () => scope.controller.openMenu(
                  genBelow(ctx, dy: 4),
                  [
                    for (final g in GenSizeGroup.values.where(
                      (g) => g != GenSizeGroup.custom,
                    ))
                      if (presetOf(g, o) ?? presetOf(g, GenOrientation.portrait)
                          case final p?)
                        UiMenuItem(
                          key: Key('gen-size-${g.name}'),
                          label: GenFormat.sizeGroupLabel(context, g),
                          trailing: '${p.width}×${p.height}',
                          checked: g == group,
                          onTap: () =>
                              scope.actions.onSizeChanged(p.width, p.height),
                        ),
                  ],
                  tag: #size,
                  width: 220,
                ),
                builder: (context, hover) => Container(
                  width: tight ? 80 : 96,
                  height: 32,
                  padding: const EdgeInsets.only(left: 10, right: 8),
                  decoration: BoxDecoration(
                    color: hover || scope.controller.popoverTag == #size
                        ? c.hover
                        : c.control,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    spacing: 6,
                    children: [
                      Expanded(
                        child: Text(
                          GenFormat.sizeGroupLabel(context, group),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.sans(13, color: c.ink),
                        ),
                      ),
                      UiGlyph(UiGlyphs.chevronDown, size: 14, color: c.muted),
                    ],
                  ),
                ),
              ),
            ),
            GenTrack<GenOrientation>(
              key: const Key('gen-orientation'),
              values: const [
                GenOrientation.landscape,
                GenOrientation.portrait,
                GenOrientation.square,
              ],
              selected: o,
              itemWidth: compact ? 24 : 34,
              keyOf: (v) => Key('gen-orientation-${v.name}'),
              tooltipOf: (v) => GenFormat.orientationLabel(context, v),
              onChanged: setOrientation,
              itemBuilder: (context, v, on) => UiGlyph(
                switch (v) {
                  GenOrientation.landscape => UiGlyphs.landscape,
                  GenOrientation.portrait => UiGlyphs.portrait,
                  GenOrientation.square => UiGlyphs.square,
                },
                size: 15,
                color: on ? c.ink : c.muted,
              ),
            ),
            const Spacer(),
            Row(
              spacing: 4,
              children: [
                _DimField(
                  key: const Key('gen-width'),
                  value: img.width,
                  width: tight ? 52 : 58,
                  tooltip: l.gen_width,
                  onSubmit: (v) => scope.actions.onSizeChanged(v, img.height),
                ),
                Tooltip(
                  message: l.gen_swapSize,
                  child: UiPressable(
                    key: const Key('gen-swap-size'),
                    onTap: () =>
                        scope.actions.onSizeChanged(img.height, img.width),
                    builder: (context, hover) => Text(
                      '×',
                      style: UiText.sans(12, color: hover ? c.ink : c.muted),
                    ),
                  ),
                ),
                _DimField(
                  key: const Key('gen-height'),
                  value: img.height,
                  width: tight ? 52 : 58,
                  tooltip: l.gen_height,
                  onSubmit: (v) => scope.actions.onSizeChanged(img.width, v),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// 宽 / 高输入框（原型 `.inp`）：32 高、58 宽、圆角 5、控件底、Geist Mono 12.5。
/// 回车 / 失焦提交，按 64 取整（64–4096）。
class _DimField extends StatefulWidget {
  const _DimField({
    super.key,
    required this.value,
    required this.onSubmit,
    required this.width,
    required this.tooltip,
  });
  final int value;
  final ValueChanged<int> onSubmit;
  final double width;
  final String tooltip;

  @override
  State<_DimField> createState() => _DimFieldState();
}

class _DimFieldState extends State<_DimField> {
  late final _c = TextEditingController(text: '${widget.value}');
  final _f = FocusNode();

  @override
  void initState() {
    super.initState();
    _f.addListener(() {
      if (!_f.hasFocus) _commit();
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant _DimField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !_f.hasFocus) _c.text = '${widget.value}';
  }

  @override
  void dispose() {
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  void _commit() {
    final v = int.tryParse(_c.text.trim());
    if (v == null) {
      _c.text = '${widget.value}';
      return;
    }
    final r = ((v / 64).round() * 64).clamp(64, 4096);
    _c.text = '$r';
    if (r != widget.value) widget.onSubmit(r);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Tooltip(
      message: widget.tooltip,
      child: Container(
        width: widget.width,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.control,
          borderRadius: BorderRadius.circular(5),
          border: _f.hasFocus ? Border.all(color: c.accent) : null,
        ),
        child: TextField(
          controller: _c,
          focusNode: _f,
          textAlign: TextAlign.center,
          style: UiText.mono(12.5, color: c.ink, height: 1.2),
          cursorColor: c.accent,
          cursorHeight: 14,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: uiBareDecoration(),
          onSubmitted: (_) => _f.unfocus(),
        ),
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context, GenAspect.image);
    final img = scope.data.image;
    final l = context.l10n;
    return Row(
      spacing: 8,
      children: [
        Tooltip(message: l.gen_countTip, child: GenLabel(l.gen_count)),
        Expanded(
          child: GenTrack<int>(
            key: const Key('gen-count'),
            values: [for (var i = 1; i <= img.maxCount; i++) i],
            selected: img.count,
            expand: true,
            keyOf: (v) => Key('gen-count-$v'),
            onChanged: scope.actions.onCountChanged,
            itemBuilder: (context, v, on) => Text(
              '$v',
              style: UiText.mono(
                13,
                weight: v == img.count ? FontWeight.w600 : FontWeight.w400,
                color: on ? c.ink : c.muted,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Tooltip(
            message: l.gen_repeatTip,
            child: GenLabel(l.gen_repeat),
          ),
        ),
        const _RepeatStepper(),
      ],
    );
  }
}

/// 箭头即时提交；数字拖动只预览，松手才更新报价。滚轮留给父级滚动。
class _RepeatStepper extends StatefulWidget {
  const _RepeatStepper();

  @override
  State<_RepeatStepper> createState() => _RepeatStepperState();
}

class _RepeatStepperState extends State<_RepeatStepper> {
  final _bubble = OverlayPortalController();
  final _link = LayerLink();
  final _text = TextEditingController();
  final _focus = FocusNode();
  bool _hover = false;
  bool _editing = false;
  int? _pointer;
  double _startX = 0;
  int _startValue = 1;
  int? _preview;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) _finishEdit();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  void _set(int value) {
    final scope = GenScope.of(context, GenAspect.image);
    final img = scope.data.image;
    final next = value.clamp(1, img.maxRepeat);
    if (next != img.repeat) scope.actions.onRepeatChanged(next);
  }

  void _endDrag({bool commit = false}) {
    final value = _preview;
    _bubble.hide();
    setState(() {
      _pointer = null;
      _preview = null;
    });
    if (commit && value != null) _set(value);
  }

  void _finishEdit({bool cancel = false}) {
    final value = int.tryParse(_text.text.trim());
    setState(() => _editing = false);
    _focus.unfocus();
    if (!cancel && value != null) _set(value);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final img = GenScope.of(context, GenAspect.image).data.image;
    final l = context.l10n;
    final value = _preview ?? img.repeat;
    final dragging = _pointer != null;
    final active = dragging || _editing;

    // `.st .ar`
    Widget arrow(String glyph, int delta, Key key) {
      final enabled =
          !active && (delta < 0 ? img.repeat > 1 : img.repeat < img.maxRepeat);
      return UiPressable(
        key: key,
        onTap: enabled ? () => _set(img.repeat + delta) : null,
        builder: (context, hover) => SizedBox(
          width: 22,
          height: 28,
          child: Center(
            child: Opacity(
              opacity: enabled ? 1 : .45,
              child: UiGlyph(
                glyph,
                size: 13,
                strokeWidth: 2.2,
                color: !enabled ? c.faint : (hover ? c.ink : c.muted),
              ),
            ),
          ),
        ),
      );
    }

    // `.bub` + `.ruler`: preview bubble above the number, ticks below.
    Widget overlay(BuildContext context) => Positioned(
      left: 0,
      top: 0,
      child: CompositedTransformFollower(
        link: _link,
        targetAnchor: Alignment.center,
        followerAnchor: Alignment.center,
        child: IgnorePointer(
          child: SizedBox(
            width: 180,
            height: 32 + 2 * 44,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 44 + 32 + 3,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        key: const Key('gen-repeat-bubble'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: c.ink,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: c.dark ? .4 : .14,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(
                          l.gen_repeatDragTotal(value, value * img.count),
                          style: UiText.sans(11.5, color: c.bg, height: 1.3),
                        ),
                      ),
                      CustomPaint(
                        size: const Size(10, 5),
                        painter: _BubbleTail(c.ink),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 44 + 32 + 6,
                  child: Row(
                    key: const Key('gen-repeat-ruler'),
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: 7,
                    children: [
                      for (var i = -3; i <= 3; i++)
                        Container(
                          width: i == 0 ? 2 : 1,
                          height: i == 0 ? 9 : 5,
                          color: i == 0 ? c.accent : c.strong,
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

    final Widget number = _editing
        ? SizedBox(
            width: 34,
            height: 28,
            child: Center(
              child: Focus(
                onKeyEvent: (_, event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.escape) {
                    _finishEdit(cancel: true);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  key: const Key('gen-repeat-input'),
                  controller: _text,
                  focusNode: _focus,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: UiText.mono(13, weight: FontWeight.w600, color: c.ink),
                  cursorColor: c.accent,
                  cursorWidth: 1.5,
                  decoration: uiBareDecoration(),
                  onSubmitted: (_) => _finishEdit(),
                ),
              ),
            ),
          )
        : MouseRegion(
            cursor: SystemMouseCursors.resizeLeftRight,
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: GestureDetector(
              onDoubleTap: () {
                _text.text = '${img.repeat}';
                _text.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _text.text.length,
                );
                setState(() => _editing = true);
                _focus.requestFocus();
              },
              child: Listener(
                onPointerDown: (e) {
                  if (_pointer != null || e.buttons != kPrimaryButton) return;
                  _startX = e.position.dx;
                  _startValue = img.repeat;
                  setState(() {
                    _pointer = e.pointer;
                    _preview = img.repeat;
                  });
                  _bubble.show();
                },
                onPointerMove: (e) {
                  if (e.pointer != _pointer) return;
                  final steps = ((e.position.dx - _startX) / 12).truncate();
                  final scale = HardwareKeyboard.instance.isShiftPressed
                      ? 5
                      : 1;
                  setState(
                    () => _preview = (_startValue + steps * scale).clamp(
                      1,
                      img.maxRepeat,
                    ),
                  );
                },
                onPointerUp: (e) {
                  if (e.pointer == _pointer) _endDrag(commit: true);
                },
                onPointerCancel: (e) {
                  if (e.pointer == _pointer) _endDrag();
                },
                // `.st .v`: hover tint + dotted underline; accent while dragging.
                child: Container(
                  key: const Key('gen-repeat-value'),
                  constraints: const BoxConstraints(minWidth: 34),
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: dragging
                        ? c.accent.withValues(alpha: .10)
                        : _hover
                        ? c.ink.withValues(alpha: .06)
                        : null,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$value',
                        style: UiText.mono(
                          13,
                          weight: FontWeight.w600,
                          color: dragging ? c.accent : c.ink,
                        ),
                      ),
                      if (_hover || dragging)
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 3,
                          child: CustomPaint(
                            key: const Key('gen-repeat-dots'),
                            size: const Size(double.infinity, 2),
                            painter: _DotLine(c.faint.withValues(alpha: .9)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );

    final stepper = CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _bubble,
        overlayChildBuilder: overlay,
        // `.st`; raised + accent ring while dragging or typing (`.st.drag`).
        child: Container(
          key: const Key('gen-repeat'),
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: active ? c.raised : c.control,
            borderRadius: BorderRadius.circular(6),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: c.accent.withValues(alpha: .35),
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              arrow(UiGlyphs.chevronLeft, -1, const Key('gen-repeat-down')),
              number,
              arrow(UiGlyphs.chevronRight, 1, const Key('gen-repeat-up')),
            ],
          ),
        ),
      ),
    );
    // Keep the tree stable while dragging; the tooltip hides on pointer down.
    return Tooltip(
      message:
          '${l.gen_repeatTotal(img.repeat, img.repeat * img.count)}\n'
          '${l.gen_repeatDragHint}',
      child: stepper,
    );
  }
}

class _BubbleTail extends CustomPainter {
  const _BubbleTail(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close(),
    Paint()..color = color,
  );

  @override
  bool shouldRepaint(_BubbleTail old) => old.color != color;
}

/// Prototype `.st .v::after`: dots every 4px.
class _DotLine extends CustomPainter {
  const _DotLine(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var x = 2.0; x < size.width; x += 4) {
      canvas.drawCircle(Offset(x, size.height / 2), .8, paint);
    }
  }

  @override
  bool shouldRepaint(_DotLine old) => old.color != color;
}
