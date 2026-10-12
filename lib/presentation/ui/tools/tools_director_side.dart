import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_keycap.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_text.dart';
import 'tools_contract.dart';
import 'tools_director.dart';
import 'tools_format.dart';
import 'tools_parts.dart';

/// 导演工具右栏（320 宽）：当前工具（图标 + 名字 + 一句说明）│ 选项 │ 运行（工具名 + 价格，Ctrl+Enter）│
/// 结果列表（缩略图、工具、时间、花费；点一行回看，悬停“沿用设置”）。
class ToolsDirectorSide extends StatelessWidget {
  const ToolsDirectorSide({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsDirectorScope.of(context);
    final d = scope.data;
    final l = context.l10n;
    return Container(
      key: const Key('tools-director-side'),
      width: ToolsDirectorPage.sideWidth,
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(left: BorderSide(color: c.line)),
      ),
      child: LayoutBuilder(
        builder: (context, box) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ToolsPanelSection(
              key: const Key('tools-dt-head'),
              child: Row(
                spacing: 10,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: ToolsIcon(
                      ToolsFormat.toolIcon(d.tool),
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ToolsFormat.toolName(l, d.tool),
                          style: UiText.sans(
                            14,
                            weight: FontWeight.w600,
                            color: c.ink,
                          ),
                        ),
                        Text(
                          ToolsFormat.toolDesc(l, d.tool),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.sans(12, color: c.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 选项 + 运行按内容高，太高时滚动；结果列表至少留 180。
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: (box.maxHeight - 66 - 180).clamp(
                  120,
                  double.infinity,
                ),
              ),
              child: SingleChildScrollView(
                key: const Key('tools-dt-options'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [..._options(context, scope), const _Run()],
                ),
              ),
            ),
            const Expanded(child: _Results()),
          ],
        ),
      ),
    );
  }

  List<Widget> _options(BuildContext context, ToolsDirectorScope scope) {
    final c = context.ui;
    final d = scope.data;
    final a = scope.actions;
    final l = context.l10n;
    final busy = d.running;
    Widget defry(String hint) => ToolsPanelSection(
      key: const Key('tools-dt-defry'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToolsSec(l.tools_dtStrength),
          ToolsSeg<int>(
            key: const Key('tools-defry'),
            expand: true,
            values: const [0, 1, 2, 3, 4, 5],
            selected: d.defry,
            keyOf: (v) => Key('tools-defry-$v'),
            onChanged: busy ? null : a.onDefry,
            label: (context, v, on) => Text(ToolsFormat.defry(l, v)),
          ),
          const SizedBox(height: 6),
          Text(hint, style: UiText.sans(11, color: c.faint)),
        ],
      ),
    );
    Widget prompt(String hint) => ToolsPanelSection(
      key: const Key('tools-dt-prompt'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToolsSec(
            l.tools_dtPrompt,
            trailing: [
              Text(l.tools_optional, style: UiText.sans(11.5, color: c.faint)),
            ],
          ),
          _PromptField(value: d.prompt, enabled: !busy, onChanged: a.onPrompt),
          const SizedBox(height: 6),
          Text(hint, style: UiText.sans(11, color: c.faint)),
        ],
      ),
    );
    return switch (d.tool) {
      ToolsDirectorTool.emotion => [
        const _Emotions(),
        defry(l.tools_dtEmotionStrengthHint),
        prompt(l.tools_dtEmotionPromptHint),
      ],
      ToolsDirectorTool.colorize => [
        prompt(l.tools_dtColorizePromptHint),
        defry(l.tools_dtColorizeStrengthHint),
      ],
      ToolsDirectorTool.pixelSnap => [const _Pixel()],
      _ => [
        ToolsPanelSection(
          key: const Key('tools-dt-none'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ToolsSec(l.tools_dtOptions),
              Text(switch (d.tool) {
                ToolsDirectorTool.removeBackground => l.tools_dtNoOptionsBg,
                ToolsDirectorTool.declutter => l.tools_dtNoOptionsDeclutter,
                ToolsDirectorTool.lineArt => l.tools_dtNoOptionsLineArt,
                _ => l.tools_dtNoOptionsSketch,
              }, style: UiText.sans(12, color: c.muted, height: 1.6)),
            ],
          ),
        ),
      ],
    };
  }
}

/// 表情：4 列网格（常用 16 个 + 展开更多 8 个），选中强调色实心。
class _Emotions extends StatefulWidget {
  const _Emotions();

  @override
  State<_Emotions> createState() => _EmotionsState();
}

class _EmotionsState extends State<_Emotions> {
  var _more = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsDirectorScope.of(context);
    final d = scope.data;
    final l = context.l10n;
    final more = _more || ToolsEmotions.more.contains(d.emotion);
    final list = [...ToolsEmotions.common, if (more) ...ToolsEmotions.more];
    return ToolsPanelSection(
      key: const Key('tools-dt-emotions'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToolsSec(l.tools_dtEmotionLabel),
          LayoutBuilder(
            builder: (context, box) {
              final w = (box.maxWidth - 18) / 4;
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final e in list)
                    UiPressable(
                      key: Key('tools-emo-$e'),
                      onTap: d.running || e == d.emotion
                          ? null
                          : () => scope.actions.onEmotion(e),
                      builder: (context, hover) {
                        final on = e == d.emotion;
                        return Container(
                          width: w,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: on
                                ? c.accent
                                : (hover ? c.hover : c.control),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            ToolsFormat.emotion(l, e),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.sans(
                              12,
                              weight: on ? FontWeight.w600 : FontWeight.w400,
                              color: on ? Colors.white : c.ink,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
          UiPressable(
            key: const Key('tools-emo-more'),
            onTap: ToolsEmotions.more.contains(d.emotion)
                ? null
                : () => setState(() => _more = !_more),
            builder: (context, hover) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                spacing: 4,
                children: [
                  UiGlyph(
                    more ? UiGlyphs.chevronUp : UiGlyphs.chevronDown,
                    size: 13,
                    color: hover ? c.ink : c.muted,
                  ),
                  Text(
                    more
                        ? l.tools_dtEmotionLess
                        : l.tools_dtEmotionMore(ToolsEmotions.more.length),
                    style: UiText.sans(12, color: hover ? c.ink : c.muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 像素对齐：调色板（关 / 自动 / 自定义 + 颜色数）、避免过度细化、放大。
class _Pixel extends StatelessWidget {
  const _Pixel();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsDirectorScope.of(context);
    final d = scope.data;
    final p = d.pixel;
    final a = scope.actions;
    final l = context.l10n;
    final busy = d.running;
    return ToolsPanelSection(
      key: const Key('tools-dt-pixel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToolsSec(l.tools_dtPalette),
          ToolsSeg<ToolsPixelPalette>(
            key: const Key('tools-pixel-palette'),
            expand: true,
            values: ToolsPixelPalette.values,
            selected: p.palette,
            keyOf: (v) => Key('tools-palette-${v.name}'),
            onChanged: busy ? null : (v) => a.onPixel(p.copyWith(palette: v)),
            label: (context, v, on) => Text(switch (v) {
              ToolsPixelPalette.off => l.tools_dtPaletteOff,
              ToolsPixelPalette.auto => l.tools_dtPaletteAuto,
              ToolsPixelPalette.custom => l.tools_dtPaletteCustom,
            }),
          ),
          if (p.palette == ToolsPixelPalette.custom) ...[
            const SizedBox(height: 10),
            Row(
              spacing: 10,
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    l.tools_dtColors,
                    style: UiText.sans(12, color: c.muted),
                  ),
                ),
                Expanded(
                  child: ToolsSlider(
                    key: const Key('tools-pixel-colors'),
                    value: p.colors.toDouble(),
                    min: 16,
                    max: 256,
                    decimals: 0,
                    enabled: !busy,
                    display: (v) => '${v.round()}',
                    onChanged: (v) => a.onPixel(p.copyWith(colors: v.round())),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          ToolsSwitchLabel(
            key: const Key('tools-pixel-refine'),
            value: p.avoidOverRefining,
            label: l.tools_dtAvoidRefine,
            onChanged: busy
                ? null
                : (v) => a.onPixel(p.copyWith(avoidOverRefining: v)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 35, top: 2, bottom: 8),
            child: Text(
              l.tools_dtAvoidRefineHint,
              style: UiText.sans(11, color: c.faint),
            ),
          ),
          ToolsSwitchLabel(
            key: const Key('tools-pixel-upscale'),
            value: p.upscale,
            label: l.tools_dtPixelUpscale,
            onChanged: busy ? null : (v) => a.onPixel(p.copyWith(upscale: v)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 35, top: 2),
            child: Text(
              l.tools_dtPixelUpscaleHint,
              style: UiText.sans(11, color: c.faint),
            ),
          ),
        ],
      ),
    );
  }
}

/// 补充提示词输入框（原型 `.txt`）：描边、圆角 9、内边距 9 / 11、最小高 64。
class _PromptField extends StatefulWidget {
  const _PromptField({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });
  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  State<_PromptField> createState() => _PromptFieldState();
}

class _PromptFieldState extends State<_PromptField> {
  late final _text = TextEditingController(text: widget.value);
  final _focus = FocusNode();

  @override
  void didUpdateWidget(covariant _PromptField old) {
    super.didUpdateWidget(old);
    // 选表情会带上常用标签：外面改了、自己又不在输入时同步。
    if (widget.value != _text.text && !_focus.hasFocus) {
      _text.text = widget.value;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      key: const Key('tools-dt-prompt-box'),
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _focus.hasFocus ? c.accent : c.line),
      ),
      child: Focus(
        onFocusChange: (_) => setState(() {}),
        child: TextField(
          key: const Key('tools-dt-prompt-field'),
          controller: _text,
          focusNode: _focus,
          enabled: widget.enabled,
          minLines: 2,
          maxLines: 5,
          style: UiText.sans(12.5, color: c.ink, height: 1.5),
          cursorColor: c.accent,
          decoration: uiBareDecoration(
            hintText: context.l10n.tools_dtPromptHint,
            hintStyle: UiText.sans(12.5, color: c.faint, height: 1.5),
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}

/// 运行按钮（44 高、圆角 10、品牌蓝）：“运行 + 工具名” + 价格；下面一行快捷键说明。
class _Run extends StatelessWidget {
  const _Run();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsDirectorScope.of(context);
    final d = scope.data;
    final l = context.l10n;
    final name = ToolsFormat.toolName(l, d.tool);
    final local = d.tool == ToolsDirectorTool.pixelSnap;
    final cost = d.cost;
    final button = UiPressable(
      key: const Key('tools-dt-run'),
      onTap: d.canRun ? scope.actions.onRun : null,
      builder: (context, hover) => Container(
        height: 44,
        decoration: BoxDecoration(
          color: hover ? Color.lerp(c.brand, Colors.black, .08) : c.brand,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 10,
          children: [
            if (d.running) ...[
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  // 减少动态效果时停在一段弧上。
                  value: MediaQuery.disableAnimationsOf(context) ? .3 : null,
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              Text(
                l.tools_running(name),
                style: UiText.sans(
                  14,
                  weight: FontWeight.w600,
                  color: c.onBrand,
                ),
              ),
            ] else ...[
              Text(
                l.tools_runTool(name),
                style: UiText.sans(
                  14,
                  weight: FontWeight.w600,
                  color: c.onBrand,
                ),
              ),
              Opacity(
                opacity: .9,
                child: local
                    ? Text(
                        l.tools_localFree,
                        style: UiText.sans(
                          13,
                          weight: FontWeight.w600,
                          color: c.onBrand,
                        ),
                      )
                    : ToolsButtonCost(cost),
              ),
            ],
          ],
        ),
      ),
    );
    return ToolsPanelSection(
      key: const Key('tools-dt-run-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (d.canRun || d.running)
            button
          else
            Opacity(opacity: .45, child: button),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6,
            children: [
              const UiKeycaps(['Ctrl', '↵']),
              Text(
                d.currentInput == null ? l.tools_runNeedInput : l.tools_runHint,
                style: UiText.sans(11, color: c.faint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 结果列表：新的在前；当前看的那条强调色 9% 底；悬停出“沿用设置”。
class _Results extends StatelessWidget {
  const _Results();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsDirectorScope.of(context);
    final d = scope.data;
    final l = context.l10n;
    final now = d.now ?? DateTime.now();
    return ToolsPanelSection(
      key: const Key('tools-dt-results'),
      border: false,
      expand: true,
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ToolsSec(
              l.tools_results,
              trailing: [
                const Spacer(),
                Text(
                  '${d.runs.length}',
                  style: UiText.mono(11.5, color: c.faint),
                ),
              ],
            ),
          ),
          Expanded(
            child: d.runs.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      l.tools_resultsEmpty,
                      style: UiText.sans(12, color: c.faint),
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      for (final r in d.runs)
                        _ResultRow(run: r, now: now, on: r.id == d.run),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                        child: Text(
                          l.tools_resultsHint,
                          style: UiText.sans(11, color: c.faint, height: 1.5),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.run, required this.now, required this.on});
  final ToolsDirectorRun run;
  final DateTime now;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsDirectorScope.of(context);
    final d = scope.data;
    final l = context.l10n;
    final title = run.variants.length > 1 && run.images.length > 1
        ? '${ToolsFormat.toolName(l, run.tool)} · ${run.variants.last}'
        : ToolsFormat.toolName(l, run.tool);
    final cost = run.cost == null || run.cost == 0
        ? l.tools_free
        : l.tools_anlasN(run.cost!);
    return UiPressable(
      key: Key('tools-run-${run.id}'),
      onTap: d.running ? null : () => scope.actions.onSelectRun(run.id),
      builder: (context, hover) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: on
              ? c.accent.withValues(alpha: .09)
              : (hover ? c.control.withValues(alpha: .6) : null),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          spacing: 10,
          children: [
            Container(
              width: 38,
              height: 50,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: c.line),
              ),
              child: run.images.isEmpty
                  ? null
                  : Image(image: run.images.last, fit: BoxFit.cover),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.sans(
                      12,
                      weight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                  Text(
                    '${ToolsFormat.ago(l, run.time, now)} · $cost',
                    maxLines: 1,
                    style: UiText.sans(11, color: c.faint),
                  ),
                ],
              ),
            ),
            if (hover && !d.running)
              ToolsButton(
                key: Key('tools-run-reuse-${run.id}'),
                small: true,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                onTap: () => scope.actions.onReuseSettings(run.id),
                children: [Text(l.tools_reuse)],
              )
            else
              UiGlyph(UiGlyphs.chevronRight, size: 14, color: c.muted),
          ],
        ),
      ),
    );
  }
}
