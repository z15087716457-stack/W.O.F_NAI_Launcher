import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/studio_icons.dart';
import '../../widgets/common/translation_icon.dart';
import '../../widgets/bridge/bridge_link_icon.dart';
import '../agent/agent_glyphs.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_keycap.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'gen_contract.dart';
import 'gen_format.dart';
import 'gen_page.dart';
import 'gen_parts.dart';

/// 基础提示词卡（原型 `.card`）：页签 + 桥接 + 工具按钮 │ 编辑器 │ 透明背景 · 预设 │ token 条。
class GenPromptModule extends StatelessWidget {
  const GenPromptModule({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = GenScope.of(context, GenAspect.prompt);
    final p = scope.data.prompt;
    final target = GenEditorTarget.base(negative: p.negative);
    return GenModule(
      key: const Key('gen-prompt'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, 2),
            child: _PromptHead(),
          ),
          GenEditorArea(target: target),
          const _PromptFoot(),
          GenTokenBar(tokens: p.tokens),
        ],
      ),
    );
  }
}

/// 编辑器槽位 + 右上角清空 ×（原型 `.ptext`：内边距 6 32 4 12；× 在右 8 上 6）。
class GenEditorArea extends StatelessWidget {
  const GenEditorArea({
    super.key,
    required this.target,
    this.padding = const EdgeInsets.fromLTRB(12, 6, 32, 4),
    this.clearButton = true,
  });
  final GenEditorTarget target;
  final EdgeInsets padding;

  /// 右上角清空 ×；全屏编辑把清空放到顶栏，这里不再画。
  final bool clearButton;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context, GenAspect.prompt);
    return Stack(
      children: [
        Padding(
          key: Key('gen-editor-$target'),
          padding: padding,
          child: scope.slots.editor(context, target),
        ),
        if (clearButton)
          Positioned(
            right: 8,
            top: padding.top,
            child: Tooltip(
              message: context.l10n.gen_clear,
              child: UiPressable(
                key: Key('gen-clear-$target'),
                onTap: () => scope.actions.onClearPrompt(target),
                builder: (context, hover) => SizedBox(
                  width: 18,
                  height: 18,
                  child: Center(
                    child: UiGlyph(
                      UiGlyphs.close,
                      size: 14,
                      color: hover ? c.ink : c.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PromptHead extends StatelessWidget {
  const _PromptHead();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context, GenAspect.prompt);
    final data = scope.data;
    final p = data.prompt;
    final l = context.l10n;
    final tools = p.tools;
    return Row(
      spacing: 2,
      children: [
        Expanded(
          child: Row(
            spacing: 2,
            children: [
              Flexible(
                child: _PreviewTip(
                  sections: p.positivePreview,
                  title: l.gen_finalPositive,
                  child: GenTab(
                    key: const Key('gen-tab-positive'),
                    label: l.gen_basePrompt,
                    selected: !p.negative,
                    onTap: () => scope.actions.onNegativeTab(false),
                  ),
                ),
              ),
              Flexible(
                child: _PreviewTip(
                  sections: p.negativePreview,
                  title: p.negativeSupported
                      ? l.gen_finalNegative
                      : l.gen_turboNegative,
                  disabledHint: p.negativeSupported
                      ? null
                      : l.gen_turboNegative,
                  child: GenTab(
                    key: const Key('gen-tab-negative'),
                    label: l.gen_negative,
                    selected: p.negative,
                    onTap: p.negativeSupported
                        ? () => scope.actions.onNegativeTab(true)
                        : null,
                  ),
                ),
              ),
              if (p.bridge case final b?) _Bridge(bridge: b),
            ],
          ),
        ),
        if (tools.palettePinned)
          Builder(
            builder: (context) => GenIb(
              key: const Key('gen-tool-palette'),
              animatedIcon: StudioIcons.promptBlockPalette,
              glyphSize: 15,
              tooltip: l.gen_toolPalette,
              onTap: () => scope.actions.onOpenPalette(genRectOf(context)),
            ),
          ),
        if (tools.dockPinned)
          GenIb(
            key: const Key('gen-tool-dock'),
            animatedIcon: StudioIcons.promptBlocks,
            glyphSize: 16,
            active: data.layout.dockOpen,
            tooltip: l.gen_toolDock,
            onTap: () => scope.actions.onLayoutChanged(
              data.layout.copyWith(dockOpen: !data.layout.dockOpen),
            ),
          ),
        if (tools.translatePinned) const _Translate(),
        if (tools.agentPinned && scope.slots.agentToggle != null)
          scope.slots.agentToggle!,
        Builder(
          builder: (context) => GenIb(
            key: const Key('gen-tool-menu'),
            animateOnTap: true,
            icon: GenNaiIcon(
              'prompt-chunk',
              size: 16,
              color: scope.controller.popoverTag == #tools ? c.ink : c.muted,
            ),
            active: scope.controller.popoverTag == #tools,
            tooltip: l.gen_toolsMenu,
            onTap: () => scope.controller.openPopover(
              genBelow(context, dy: 4, right: true),
              (_) => const _ToolsMenu(),
              tag: #tools,
            ),
          ),
        ),
      ],
    );
  }
}

/// 页签悬停：最终发出去的内容（主提示词 + 质量词 + 各角色……）。
class _PreviewTip extends StatelessWidget {
  const _PreviewTip({
    required this.sections,
    required this.title,
    required this.child,
    this.disabledHint,
  });
  final List<GenPreviewSection> sections;
  final String title;
  final Widget child;
  final String? disabledHint;

  @override
  Widget build(BuildContext context) {
    if (disabledHint != null) {
      return Tooltip(message: disabledHint!, child: child);
    }
    if (sections.isEmpty) return child;
    final c = context.ui;
    return Tooltip(
      waitDuration: const Duration(milliseconds: 600),
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.tipBg,
        borderRadius: BorderRadius.circular(9),
      ),
      richMessage: TextSpan(
        style: UiText.sans(12, color: c.tipInk, height: 1.5),
        children: [
          TextSpan(
            text: title,
            style: UiText.sans(12, weight: FontWeight.w700, color: c.tipInk),
          ),
          for (final s in sections) ...[
            TextSpan(
              text: '\n${s.label}\n',
              style: UiText.sans(
                11,
                weight: FontWeight.w600,
                color: c.tipInk.withValues(alpha: .6),
                height: 1.9,
              ),
            ),
            TextSpan(text: s.text),
          ],
        ],
      ),
      child: child,
    );
  }
}

/// 桥接小图标（24 宽）：闲置弱色、工作中强调色、已同步绿、失败橙。
class _Bridge extends StatelessWidget {
  const _Bridge({required this.bridge});
  final GenBridge bridge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (bridge.phase) {
      GenBridgePhase.working => theme.colorScheme.primary,
      GenBridgePhase.synced =>
        theme.brightness == Brightness.dark
            ? const Color(0xFF63D79C)
            : const Color(0xFF17965F),
      GenBridgePhase.failed => Colors.orange,
      GenBridgePhase.idle => theme.colorScheme.onSurfaceVariant.withValues(
        alpha: .55,
      ),
    };
    return Builder(
      builder: (context) => GenIb(
        key: const Key('gen-bridge'),
        plain: true,
        icon: Transform.translate(
          offset: const Offset(0, 1),
          child: BridgeLinkIcon(
            color: color,
            working: bridge.phase == GenBridgePhase.working,
          ),
        ),
        size: 24,
        width: 24,
        color: color,
        tooltip: bridge.label,
        onTap: () => GenScope.of(
          context,
          GenAspect.prompt,
        ).actions.onOpenBridge(genRectOf(context)),
      ),
    );
  }
}

/// 翻译钮（原型 `.ibx`）：26 高、1px 描边、圆角 6；左半翻译 / 显示原文，右半箭头弹菜单。
class _Translate extends StatelessWidget {
  const _Translate();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context, GenAspect.prompt);
    final t = scope.data.prompt.translate;
    final l = context.l10n;
    final open = scope.controller.popoverTag == #translate;
    final tip = t.busy
        ? l.gen_translating
        : t.hasTranslations
        ? (t.showing
              ? l.gen_translateTapOriginal
              : l.gen_translateTapTranslated)
        : t.route == null
        ? l.gen_translateNeedsModel
        : l.gen_translateWith(t.route!);
    return Builder(
      builder: (context) => Container(
        key: const Key('gen-translate'),
        height: 26,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(6),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: tip,
              child: UiPressable(
                key: const Key('gen-translate-run'),
                onTap: t.busy
                    ? null
                    : () {
                        if (t.hasTranslations) {
                          scope.actions.onToggleTranslation();
                        } else if (t.route == null) {
                          scope.actions.onTranslationSettings();
                        } else {
                          scope.actions.onTranslate();
                        }
                      },
                builder: (context, hover) => Container(
                  height: 24,
                  padding: const EdgeInsets.only(left: 5, right: 1),
                  color: hover ? c.control : null,
                  alignment: Alignment.center,
                  child: TranslationIcon(
                    size: 17,
                    busy: t.busy,
                    color: t.busy || t.showing
                        ? c.accent
                        : (hover ? c.ink : c.muted),
                  ),
                ),
              ),
            ),
            UiPressable(
              key: const Key('gen-translate-menu'),
              onTap: () =>
                  _openMenu(context, genBelow(context, dy: 4, right: true)),
              builder: (context, hover) => Container(
                height: 24,
                padding: const EdgeInsets.only(left: 1, right: 3),
                color: hover || open ? c.control : null,
                alignment: Alignment.center,
                child: UiGlyph(UiGlyphs.chevronDown, size: 12, color: c.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _openMenu(BuildContext context, UiPopoverAnchor anchor) {
    final scope = GenScope.of(context, GenAspect.prompt);
    final t = scope.data.prompt.translate;
    final l = context.l10n;
    Rect adjustmentAnchor() {
      var rect = genRectOf(context);
      context.visitAncestorElements((element) {
        if (element.widget.key == const Key('gen-prompt')) {
          rect = genRectOf(element);
          return false;
        }
        return true;
      });
      return rect;
    }

    scope.controller.openMenu(
      anchor,
      [
        UiMenuItem(
          key: const Key('gen-translate-adjust'),
          label: l.gen_translateAdjust,
          subtitle: l.gen_translateAdjustSub,
          glyph: UiGlyphs.external,
          enabled:
              !t.busy &&
              t.canAdjust &&
              scope.actions.onTranslationAdjust != null,
          onTap: () =>
              scope.actions.onTranslationAdjust?.call(adjustmentAnchor()),
        ),
        UiMenuItem(
          key: const Key('gen-translate-new'),
          label: l.gen_translateNew,
          glyph: UiGlyphs.retry,
          enabled: !t.busy && t.route != null,
          onTap: scope.actions.onTranslate,
        ),
        UiMenuItem(
          label: t.showing
              ? l.gen_translateShowOriginal
              : l.gen_translateShowTranslated,
          glyph: UiGlyphs.swap,
          enabled: !t.busy && t.hasTranslations,
          onTap: scope.actions.onToggleTranslation,
        ),
        UiMenuItem(
          key: const Key('gen-translate-clear'),
          label: l.gen_translateClearRestore,
          subtitle: l.gen_translateClearRestoreSub,
          glyph: UiGlyphs.retry,
          enabled:
              !t.busy &&
              t.hasTranslations &&
              scope.actions.onClearTranslations != null,
          onTap: () => scope.actions.onClearTranslations?.call(),
        ),
        UiMenuItem(
          label: l.gen_translateSettings,
          glyph: UiGlyphs.external,
          divider: true,
          trailing: t.route,
          onTap: scope.actions.onTranslationSettings,
        ),
        if (scope.slots.translationGuide != null)
          UiMenuItem(
            key: const Key('gen-translation-tutorial'),
            label: l.promptTranslation_tutorial,
            glyph: UiGlyphs.infoCircle,
            divider: true,
            onTap: () => scope.controller.openPopover(
              anchor,
              (guideContext) => UiPopoverSurface(
                key: const Key('gen-translation-guide'),
                width: 300,
                padding: const EdgeInsets.all(10),
                child: scope.slots.translationGuide!(
                  guideContext,
                  () => _openMenu(context, anchor),
                ),
              ),
              tag: #translate,
            ),
          ),
      ],
      tag: #translate,
      width: 310,
    );
  }
}

/// “模块与开关”菜单：上面是可以钉在头部的工具（点了切钉住），下面是提示词设置开关；点了不收起。
class _ToolsMenu extends StatelessWidget {
  const _ToolsMenu();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context, GenAspect.prompt);
    final t = scope.data.prompt.tools;
    final l = context.l10n;
    Widget pinRow(
      Key key,
      Widget icon,
      String label,
      GenPromptTool tool,
      bool pinned,
    ) => UiPressable(
      key: key,
      onTap: () => scope.actions.onPromptTool(tool, !pinned),
      builder: (context, hover) => Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: hover ? c.control : null,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          spacing: 10,
          children: [
            SizedBox(width: 16, child: Center(child: icon)),
            Expanded(
              child: Text(label, style: UiText.sans(13, color: c.ink)),
            ),
            Tooltip(
              message: pinned ? l.gen_unpin : l.gen_pin,
              child: UiGlyph(
                UiGlyphs.pin,
                size: 14,
                filled: pinned,
                color: pinned ? c.accent : c.faint,
              ),
            ),
          ],
        ),
      ),
    );
    Widget switchRow(
      Key key,
      String label,
      String sub,
      GenPromptTool tool,
      bool on,
    ) => UiPressable(
      key: key,
      onTap: () => scope.actions.onPromptTool(tool, !on),
      builder: (context, hover) => Container(
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
        decoration: BoxDecoration(
          color: hover ? c.control : null,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          spacing: 10,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: UiText.sans(13, color: c.ink)),
                  Text(
                    sub,
                    style: UiText.sans(11.5, color: c.muted, height: 1.35),
                  ),
                ],
              ),
            ),
            UiSwitch(value: on),
          ],
        ),
      ),
    );
    return UiPopoverSurface(
      width: 300,
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiPressable(
            key: const Key('gen-fullscreen'),
            onTap: () {
              scope.controller.closePopover();
              scope.controller.openFullscreen(
                GenEditorTarget.base(
                  negative: scope.data.prompt.negative,
                  fullscreen: true,
                ),
              );
            },
            builder: (context, hover) => Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: hover ? c.control : null,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                spacing: 10,
                children: [
                  SizedBox(
                    width: 16,
                    child: UiGlyph(UiGlyphs.expand, size: 15, color: c.muted),
                  ),
                  Text(l.gen_fullscreen, style: UiText.sans(13, color: c.ink)),
                ],
              ),
            ),
          ),
          _MenuSection(l.gen_toolsPinned),
          pinRow(
            const Key('gen-pin-palette'),
            Icon(StudioIcons.promptBlockPalette, size: 14, color: c.muted),
            l.gen_toolPalette,
            GenPromptTool.palettePinned,
            t.palettePinned,
          ),
          pinRow(
            const Key('gen-pin-dock'),
            Icon(StudioIcons.promptBlocks, size: 15, color: c.muted),
            l.gen_toolDock,
            GenPromptTool.dockPinned,
            t.dockPinned,
          ),
          pinRow(
            const Key('gen-pin-translate'),
            Icon(Icons.translate, size: 15, color: c.muted),
            l.gen_toolTranslate,
            GenPromptTool.translatePinned,
            t.translatePinned,
          ),
          if (scope.slots.agentToggle != null)
            pinRow(
              const Key('gen-pin-agent'),
              AgentMark(size: 15, color: c.muted),
              l.naiAgent_title,
              GenPromptTool.agentPinned,
              t.agentPinned,
            ),
          _MenuSection(l.gen_toolsSettings),
          switchRow(
            const Key('gen-switch-format'),
            l.gen_autoFormat,
            l.gen_autoFormatSub,
            GenPromptTool.autoFormat,
            t.autoFormat,
          ),
          switchRow(
            const Key('gen-switch-highlight'),
            l.gen_highlight,
            l.gen_highlightSub,
            GenPromptTool.highlight,
            t.highlight,
          ),
          switchRow(
            const Key('gen-switch-sd'),
            l.gen_sdConvert,
            l.gen_sdConvertSub,
            GenPromptTool.sdConvert,
            t.sdConvert,
          ),
          switchRow(
            const Key('gen-switch-related'),
            l.gen_related,
            l.gen_relatedSub,
            GenPromptTool.related,
            t.related,
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Text(
        text,
        style: UiText.sans(11, weight: FontWeight.w600, color: c.faint),
      ),
    );
  }
}

/// 底部行（原型 `.pfoot`）：内边距 8 12 6、间距 4、11 号字。左透明背景（V5），右质量词 / 负面预设。
class _PromptFoot extends StatelessWidget {
  const _PromptFoot();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context, GenAspect.prompt);
    final p = scope.data.prompt;
    final l = context.l10n;
    final presets = p.negative ? p.ucPresets : p.qualityPresets;
    final current = p.negative ? p.ucPreset : p.qualityPreset;
    final label =
        presets.where((x) => x.id == current).firstOrNull?.label ??
        l.gen_presetNone;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        spacing: 4,
        children: [
          if (p.transparent case final on?) _Transparent(on: on),
          const Spacer(),
          Builder(
            builder: (context) => UiPressable(
              key: const Key('gen-preset'),
              onTap: presets.isEmpty
                  ? null
                  : () => scope.controller.openMenu(
                      genAbove(context, dy: 4, right: true),
                      [
                        for (final x in presets)
                          UiMenuItem(
                            label: x.label,
                            trailing: x.detail,
                            checked: x.id == current,
                            onTap: () => p.negative
                                ? scope.actions.onUcPreset(x.id)
                                : scope.actions.onQualityPreset(x.id),
                          ),
                      ],
                      tag: #preset,
                      width: 220,
                    ),
              builder: (context, hover) => Row(
                spacing: 4,
                children: [
                  Text(
                    '${p.negative ? l.gen_ucPreset : l.gen_qualityPreset}: $label',
                    style: UiText.sans(
                      11,
                      color: hover ? c.ink : GenFormat.ink55(c),
                    ),
                  ),
                  UiGlyph(UiGlyphs.chevronDown, size: 11, color: c.muted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 透明背景开关（原型 `.chunk`）：14 方棋盘格 + 关 × / 开 ✓。
class _Transparent extends StatelessWidget {
  const _Transparent({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context, GenAspect.prompt);
    final l = context.l10n;
    return Tooltip(
      message: on ? l.gen_transparentOn : l.gen_transparentOff,
      child: UiPressable(
        key: const Key('gen-transparent'),
        onTap: () => scope.actions.onTransparentChanged(!on),
        builder: (context, hover) => Row(
          spacing: 4,
          children: [
            Container(
              width: 14,
              height: 14,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: on ? Border.all(color: c.accent) : null,
              ),
              child: CustomPaint(
                painter: _Checker(
                  a: c.control,
                  b: Color.lerp(c.control, c.ink, .12)!,
                ),
              ),
            ),
            UiGlyph(
              on ? UiGlyphs.check : UiGlyphs.close,
              size: 11,
              strokeWidth: on ? 2.4 : 1.8,
              color: on ? c.accent : (hover ? c.ink : c.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Checker extends CustomPainter {
  const _Checker({required this.a, required this.b});
  final Color a;
  final Color b;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = a);
    final s = size.width / 4;
    final p = Paint()..color = b;
    for (var y = 0; y < 4; y++) {
      for (var x = 0; x < 4; x++) {
        if ((x + y).isOdd) {
          canvas.drawRect(Rect.fromLTWH(x * s, y * s, s, s), p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_Checker old) => old.a != a || old.b != b;
}

/// 全屏编辑：大面板里放同一块编辑器（最宽 960、高到窗口的 86%）。
/// 顶栏：标题 + 正 / 负面分段（角色卡显示角色名）、清空、关闭；
/// 中间编辑区留足边距；底栏：用量条 + token 数 + Esc 提示。
class GenFullscreenEditor extends StatelessWidget {
  const GenFullscreenEditor({super.key, required this.target});
  final GenEditorTarget target;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context, GenAspect.prompt);
    final l = context.l10n;
    final data = scope.data;
    final ch = target.character;
    final negative =
        data.prompt.negativeSupported &&
        (ch == null ? data.prompt.negative : target.negative);
    final t = ch == null
        ? GenEditorTarget.base(negative: negative, fullscreen: true)
        : GenEditorTarget.character(ch, negative: negative, fullscreen: true);
    final tokens = ch == null
        ? data.prompt.tokens
        : (negative
              ? data.characters!.list[ch].negativeTokens
              : data.characters!.list[ch].positiveTokens);
    final size = MediaQuery.sizeOf(context);
    final ratio = tokens.limit <= 0 ? 0.0 : tokens.used / tokens.limit;
    final tokenColor = ratio > 1
        ? c.error
        : ratio > .9
        ? c.warn
        : c.muted;
    final title = ch == null
        ? l.gen_basePrompt
        : data.characters!.list[ch].name ?? l.gen_characterN(ch + 1);
    return UiPopoverSurface(
      key: const Key('gen-fullscreen-editor'),
      width: (size.width - 96).clamp(560.0, 960.0),
      radius: 14,
      child: SizedBox(
        height: size.height * .86,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.only(left: 20, right: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.line)),
              ),
              child: Row(
                spacing: 10,
                children: [
                  UiGlyph(UiGlyphs.expand, size: 15, color: c.muted),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.sans(
                        15,
                        weight: FontWeight.w600,
                        color: c.ink,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (ch == null && data.prompt.negativeSupported)
                    UiSegmented<bool>(
                      key: const Key('gen-fullscreen-tabs'),
                      values: const [false, true],
                      selected: negative,
                      height: 28,
                      itemPadding: 12,
                      labelOf: (v) => v ? l.gen_negative : l.gen_positive,
                      onChanged: scope.actions.onNegativeTab,
                    )
                  else if (ch != null && data.prompt.negativeSupported)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: c.control,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        negative ? l.gen_negative : l.gen_positive,
                        style: UiText.sans(12, color: c.muted, height: 1.2),
                      ),
                    ),
                  UiIconBox(
                    key: Key('gen-clear-$t'),
                    glyph: UiGlyphs.trash,
                    tooltip: l.gen_clear,
                    onTap: () => scope.actions.onClearPrompt(t),
                  ),
                  UiIconBox(
                    key: const Key('gen-fullscreen-close'),
                    glyph: UiGlyphs.close,
                    tooltip: '${l.gen_close} (Esc)',
                    onTap: scope.controller.closeDialog,
                  ),
                ],
              ),
            ),
            Expanded(
              child: GenEditorArea(
                target: t,
                clearButton: false,
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
              ),
            ),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: c.control.withValues(alpha: .45),
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: GenTokenBar(
                      key: const Key('gen-fullscreen-tokens'),
                      tokens: tokens,
                      margin: EdgeInsets.zero,
                    ),
                  ),
                  Text(
                    '${tokens.used} / ${tokens.limit}',
                    key: const Key('gen-fullscreen-count'),
                    style: UiText.mono(12, color: tokenColor, height: 1.2),
                  ),
                  Container(width: 1, height: 14, color: c.line),
                  Row(
                    spacing: 6,
                    children: [
                      const UiKeycap('Esc'),
                      Text(
                        l.gen_close,
                        style: UiText.sans(12, color: c.muted, height: 1.2),
                      ),
                    ],
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
