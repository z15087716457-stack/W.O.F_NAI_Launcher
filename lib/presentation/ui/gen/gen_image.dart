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
    final scope = GenScope.of(context);
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
        return Row(
          spacing: 8,
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
              itemWidth: 34,
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
    final scope = GenScope.of(context);
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

/// 重复步进（原型 `.st2`）：32 高、圆角 6、控件底；两端 22 × 28 箭头，中间等宽数字。滚轮也能调。
class _RepeatStepper extends StatelessWidget {
  const _RepeatStepper();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context);
    final img = scope.data.image;
    final l = context.l10n;
    void set(int v) {
      final n = v.clamp(1, img.maxRepeat);
      if (n != img.repeat) scope.actions.onRepeatChanged(n);
    }

    Widget arrow(String glyph, int delta, Key key) {
      final enabled = delta < 0 ? img.repeat > 1 : img.repeat < img.maxRepeat;
      return UiPressable(
        key: key,
        onTap: enabled ? () => set(img.repeat + delta) : null,
        builder: (context, hover) => SizedBox(
          width: 22,
          height: 28,
          child: Center(
            child: UiGlyph(
              glyph,
              size: 13,
              color: !enabled ? c.faint : (hover ? c.ink : c.muted),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: l.gen_repeatTotal(img.repeat, img.repeat * img.count),
      child: Listener(
        onPointerSignal: (e) {
          if (e is PointerScrollEvent) {
            set(img.repeat + (e.scrollDelta.dy < 0 ? 1 : -1));
          }
        },
        child: Container(
          key: const Key('gen-repeat'),
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: c.control,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              arrow(UiGlyphs.chevronLeft, -1, const Key('gen-repeat-down')),
              Container(
                constraints: const BoxConstraints(minWidth: 30),
                alignment: Alignment.center,
                child: Text(
                  '${img.repeat}',
                  style: UiText.mono(13, weight: FontWeight.w600, color: c.ink),
                ),
              ),
              arrow(UiGlyphs.chevronRight, 1, const Key('gen-repeat-up')),
            ],
          ),
        ),
      ),
    );
  }
}
