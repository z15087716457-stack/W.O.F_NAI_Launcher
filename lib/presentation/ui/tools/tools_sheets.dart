import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../gen/gen_parts.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_keycap.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'tools_contract.dart';
import 'tools_format.dart';
import 'tools_parts.dart';

/// 从工具条落下的面板外框（原型 `.sheet`）：抬起底、1px 描边、圆角 12、大投影；
/// 头（图标块 + 标题 + 一句说明 + ×）│ 内容 │ 底栏（面板底、上分隔线）。
/// Esc = [onClose]，Ctrl+Enter = [onRun]（焦点在面板里时）。
class ToolsSheetFrame extends StatefulWidget {
  const ToolsSheetFrame({
    super.key,
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.footer,
    required this.onClose,
    this.onRun,
  });

  final double width;
  final String icon;
  final String title;
  final String subtitle;
  final Widget body;
  final List<Widget> footer;
  final VoidCallback onClose;
  final VoidCallback? onRun;

  @override
  State<ToolsSheetFrame> createState() => _ToolsSheetFrameState();
}

class _ToolsSheetFrameState extends State<ToolsSheetFrame> {
  UiPopoverAnchor? _anchor;
  WidgetBuilder? _menu;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return ToolsSheetScope(
      openMenu: (anchor, builder) => setState(() {
        _anchor = anchor;
        _menu = builder;
      }),
      closeMenu: () => setState(() {
        _anchor = null;
        _menu = null;
      }),
      child: UiPopover(
        anchor: _anchor,
        onDismiss: () => setState(() {
          _anchor = null;
          _menu = null;
        }),
        builder: (ctx) => _menu?.call(ctx) ?? const SizedBox.shrink(),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
            if (widget.onRun != null)
              const SingleActivator(LogicalKeyboardKey.enter, control: true):
                  widget.onRun!,
          },
          child: Focus(
            autofocus: true,
            child: Container(
              width: widget.width,
              clipBehavior: Clip.antiAlias,
              foregroundDecoration: BoxDecoration(
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(12),
              ),
              decoration: BoxDecoration(
                color: c.raised,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: c.dark ? .6 : .18),
                    blurRadius: 34,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: c.dark ? .3 : .08),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      key: const Key('tools-sheet-head'),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        spacing: 10,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: c.accent.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ToolsIcon(
                              widget.icon,
                              size: 16,
                              color: c.accent,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: UiText.sans(
                                    14,
                                    weight: FontWeight.w600,
                                    color: c.ink,
                                  ),
                                ),
                                Text(
                                  widget.subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: UiText.sans(12, color: c.muted),
                                ),
                              ],
                            ),
                          ),
                          ToolsIb(
                            key: const Key('tools-sheet-close'),
                            glyph: UiGlyphs.close,
                            tooltip: context.l10n.tools_close,
                            onTap: widget.onClose,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      key: const Key('tools-sheet-body'),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                      child: widget.body,
                    ),
                    Container(
                      key: const Key('tools-sheet-footer'),
                      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: c.panel,
                        border: Border(top: BorderSide(color: c.line)),
                      ),
                      child: Row(spacing: 8, children: widget.footer),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 面板里的菜单（模型下拉、高级设置的多选一）。
class ToolsSheetScope extends InheritedWidget {
  const ToolsSheetScope({
    super.key,
    required this.openMenu,
    required this.closeMenu,
    required super.child,
  });

  final void Function(UiPopoverAnchor anchor, WidgetBuilder builder) openMenu;
  final VoidCallback closeMenu;

  static ToolsSheetScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ToolsSheetScope>()!;

  @override
  bool updateShouldNotify(ToolsSheetScope old) => false;
}

UiPopoverAnchor _below(BuildContext context, {double dy = 4}) {
  final box = context.findRenderObject()! as RenderBox;
  return UiPopoverAnchor(box.localToGlobal(Offset(0, box.size.height + dy)));
}

/// 面板底栏左边的一句弱色说明（撑满剩余宽度，放不下省略）。
class _FooterNote extends StatelessWidget {
  const _FooterNote(this.text, {this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: UiText.sans(12, color: color ?? context.ui.muted),
    ),
  );
}

// ───────────────────────── 增强 ─────────────────────────

/// 增强面板（宽 620）：放大档 + 输出尺寸 │（本地放大：本机模型卡）│ 幅度 1–5 或自定义强度 / 噪声 │
/// 底栏：模型 · 步数、取消、“增强 · 价格”。
class ToolsEnhanceSheet extends StatelessWidget {
  const ToolsEnhanceSheet({
    super.key,
    required this.data,
    required this.actions,
  });

  final ToolsEnhanceData data;
  final ToolsEnhanceActions actions;

  static const width = 620.0;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final d = data;
    final busy = d.busy;
    final out = d.isLocal
        ? l.tools_enhanceOutLocal(
            ToolsFormat.tight(d.sourceWidth, d.sourceHeight),
            ToolsFormat.factor(d.local?.factor ?? 2),
          )
        : '${ToolsFormat.tight(d.sourceWidth, d.sourceHeight)} → '
              '${ToolsFormat.tight(d.outWidth ?? d.sourceWidth, d.outHeight ?? d.sourceHeight)}';
    Widget scaleLabel(String s) => switch (s) {
      ToolsEnhanceScale.max => const Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 3,
        children: [
          Text('Max'),
          UiGlyph(
            ToolsGlyphs.sparkle,
            size: 12,
            filled: true,
            color: Color(0xFFF5A623),
          ),
        ],
      ),
      ToolsEnhanceScale.local => Text(l.tools_enhanceLocal),
      _ => Text('$s×'),
    };
    final magnitudes = [1, 2, 3, 4, 5];
    String? magName(int m) => switch (m) {
      1 => l.tools_magLight,
      3 => l.tools_magMedium,
      5 => l.tools_magStrong,
      _ => null,
    };
    final magSeg = ToolsSeg<int>(
      key: const Key('tools-enhance-magnitude'),
      values: magnitudes,
      selected: d.magnitude,
      disabled: d.custom,
      keyOf: (m) => Key('tools-mag-$m'),
      onChanged: busy ? null : actions.onMagnitude,
      label: (context, m, on) => Text.rich(
        TextSpan(
          text: '$m',
          children: [
            if (!d.custom && magName(m) != null)
              TextSpan(
                text: ' ${magName(m)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ToolsFieldRow(
          key: const Key('tools-enhance-scale-row'),
          label: l.tools_enhanceScale,
          children: [
            ToolsSeg<String>(
              key: const Key('tools-enhance-scale'),
              values: d.scales,
              selected: d.scale,
              keyOf: (s) => Key('tools-scale-$s'),
              onChanged: busy ? null : actions.onScale,
              label: (context, s, on) => scaleLabel(s),
            ),
            const Spacer(),
            Text(
              out,
              key: const Key('tools-enhance-out'),
              style: UiText.mono(12, color: c.muted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (d.isLocal)
          ToolsFieldRow(
            label: l.tools_enhanceLocalRow,
            children: [
              Expanded(
                child: _LocalCard(
                  local: d.local,
                  onSettings: actions.onOpenUpscaleSettings,
                ),
              ),
            ],
          )
        else ...[
          ToolsFieldRow(
            key: const Key('tools-enhance-magnitude-row'),
            label: l.tools_enhanceMagnitude,
            children: [
              magSeg,
              if (d.custom) UiMini(l.tools_enhanceCustomTag),
              const Spacer(),
              Text(
                l.tools_enhanceValues(
                  d.strength.toStringAsFixed(2),
                  d.noise.toStringAsFixed(2),
                ),
                key: const Key('tools-enhance-values'),
                style: UiText.mono(12, color: c.muted),
              ),
            ],
          ),
          if (d.custom)
            Padding(
              padding: const EdgeInsets.only(left: 68, top: 10),
              child: Container(
                key: const Key('tools-enhance-custom'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.panel,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LabeledSlider(
                      key: const Key('tools-enhance-strength'),
                      label: l.tools_strength,
                      value: d.strength,
                      min: .01,
                      max: .99,
                      onChanged: busy ? null : actions.onStrength,
                    ),
                    const SizedBox(height: 10),
                    _LabeledSlider(
                      key: const Key('tools-enhance-noise'),
                      label: l.tools_noise,
                      value: d.noise,
                      max: .99,
                      onChanged: busy ? null : actions.onNoise,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.tools_enhanceCustomHint,
                      style: UiText.sans(11, color: c.faint),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 68, top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ToolsSwitchLabel(
                key: const Key('tools-enhance-custom-switch'),
                value: d.custom,
                muted: true,
                label: l.tools_enhanceCustom,
                onChanged: busy ? null : actions.onCustom,
              ),
            ),
          ),
        ],
      ],
    );
    return ToolsSheetFrame(
      key: const Key('tools-enhance-sheet'),
      width: width,
      icon: 'nai-icon-enhance',
      title: l.tools_enhance,
      subtitle: l.tools_enhanceSub,
      onClose: actions.onClose,
      onRun: busy ? null : actions.onRun,
      body: body,
      footer: [
        _FooterNote(l.tools_enhanceFooter(d.model, d.steps)),
        ToolsButton(
          key: const Key('tools-enhance-cancel'),
          tone: ToolsButtonTone.ghost,
          small: true,
          onTap: actions.onClose,
          children: [Text(l.tools_cancel), const UiKeycap('Esc')],
        ),
        ToolsButton(
          key: const Key('tools-enhance-run'),
          tone: ToolsButtonTone.primary,
          onTap: busy ? null : actions.onRun,
          cost: ToolsButtonCost(d.cost, insufficient: d.insufficient),
          children: [
            Text(d.isLocal ? l.tools_enhanceRunLocal : l.tools_enhanceRun),
          ],
        ),
      ],
    );
  }
}

class _LocalCard extends StatelessWidget {
  const _LocalCard({required this.local, required this.onSettings});
  final ToolsLocalUpscale? local;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final m = local;
    return Container(
      key: const Key('tools-enhance-local'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.accent, width: 2),
      ),
      child: Row(
        spacing: 10,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: m?.ready ?? false ? c.ok : c.strong,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m == null
                      ? l.tools_localNotSet
                      : '${m.label} · ${ToolsFormat.factor(m.factor)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(12, weight: FontWeight.w600, color: c.ink),
                ),
                Text(
                  l.tools_localHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(11, color: c.muted),
                ),
              ],
            ),
          ),
          ToolsButton(
            key: const Key('tools-enhance-local-settings'),
            small: true,
            onTap: onSettings,
            children: [
              Text(l.tools_upscaleSettings),
              UiGlyph(UiGlyphs.chevronRight, size: 12, color: c.ink),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
  });
  final String label;
  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) => Row(
    spacing: 10,
    children: [
      SizedBox(
        width: 34,
        child: Text(label, style: UiText.sans(12, color: context.ui.muted)),
      ),
      Expanded(
        child: ToolsSlider(
          value: value,
          min: min,
          max: max,
          enabled: onChanged != null,
          onChanged: onChanged ?? (_) {},
        ),
      ),
    ],
  );
}

// ───────────────────────── 放大设置 ─────────────────────────

/// 放大设置（宽 520）：本机 / 云端两张卡 │ 方法 │ 模型（带安装状态）+ 管理模型 │ 倍数 + 输出尺寸 │
/// 高级设置（折叠）│ 底栏：设置会记住、“放大 · 免费 / 价格”。
class ToolsUpscaleSheet extends StatefulWidget {
  const ToolsUpscaleSheet({
    super.key,
    required this.data,
    required this.actions,
  });

  final ToolsUpscaleData data;
  final ToolsUpscaleActions actions;

  static const width = 520.0;

  @override
  State<ToolsUpscaleSheet> createState() => _ToolsUpscaleSheetState();
}

class _ToolsUpscaleSheetState extends State<ToolsUpscaleSheet> {
  var _advanced = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final d = widget.data;
    final a = widget.actions;
    final busy = d.running;
    final canRun = !busy && d.blocked == null;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            key: const Key('tools-upscale-backends'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              for (final b in d.backends)
                Expanded(
                  child: _BackendCard(
                    backend: b,
                    selected: b.id == d.backend,
                    onTap: busy || !b.enabled ? null : () => a.onBackend(b.id),
                  ),
                ),
            ],
          ),
        ),
        if (d.methods.isNotEmpty) ...[
          const SizedBox(height: 14),
          ToolsFieldRow(
            key: const Key('tools-upscale-method-row'),
            label: l.tools_upscaleMethod,
            children: [
              ToolsSeg<String>(
                key: const Key('tools-upscale-method'),
                values: [for (final m in d.methods) m.id],
                selected: d.method,
                keyOf: (id) => Key('tools-method-$id'),
                onChanged: busy ? null : a.onMethod,
                label: (context, id, on) =>
                    Text(d.methods.firstWhere((m) => m.id == id).label),
              ),
            ],
          ),
        ],
        if (d.models.isNotEmpty) ...[
          const SizedBox(height: 8),
          ToolsFieldRow(
            key: const Key('tools-upscale-model-row'),
            label: l.tools_upscaleModel,
            children: [
              Builder(
                builder: (ctx) => _ModelChip(
                  model: d.currentModel,
                  onTap: busy
                      ? null
                      : () => ToolsSheetScope.of(ctx).openMenu(
                          _below(ctx),
                          (_) => UiMenu(
                            width: 260,
                            onClose: ToolsSheetScope.of(ctx).closeMenu,
                            items: [
                              for (final m in d.models)
                                UiMenuItem(
                                  key: Key('tools-model-${m.id}'),
                                  label: m.label,
                                  trailing: m.state == ToolsModelState.ready
                                      ? m.detail
                                      : _stateLabel(context, m.state),
                                  checked: m.id == d.model,
                                  onTap: () => a.onModel(m.id),
                                ),
                            ],
                          ),
                        ),
                ),
              ),
              ToolsButton(
                key: const Key('tools-upscale-manage'),
                tone: ToolsButtonTone.ghost,
                small: true,
                color: c.accent,
                onTap: a.onManageModels,
                children: [
                  Text(l.tools_upscaleManage),
                  UiGlyph(ToolsGlyphs.external, size: 12, color: c.accent),
                ],
              ),
            ],
          ),
        ],
        if (d.scale != null) ...[
          const SizedBox(height: 8),
          ToolsFieldRow(
            key: const Key('tools-upscale-scale-row'),
            label: l.tools_upscaleScale,
            children: [
              ToolsSlider(
                key: const Key('tools-upscale-scale'),
                width: 92,
                value: d.scale!,
                min: d.minScale,
                max: d.maxScale,
                enabled: !busy,
                display: (v) => '${v.toStringAsFixed(2)} ×',
                onChanged: a.onScale,
              ),
              const Spacer(),
              Text(
                '${ToolsFormat.tight(d.sourceWidth, d.sourceHeight)} → '
                '${ToolsFormat.tight(d.outWidth ?? d.sourceWidth, d.outHeight ?? d.sourceHeight)}',
                key: const Key('tools-upscale-out'),
                style: UiText.mono(12, color: c.muted),
              ),
            ],
          ),
        ],
        if (d.advanced.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UiPressable(
                  key: const Key('tools-upscale-advanced'),
                  onTap: () => setState(() => _advanced = !_advanced),
                  builder: (context, hover) => Row(
                    spacing: 6,
                    children: [
                      UiGlyph(
                        _advanced
                            ? UiGlyphs.chevronDown
                            : UiGlyphs.chevronRight,
                        size: 13,
                        color: hover ? c.ink : c.muted,
                      ),
                      Text(
                        l.tools_upscaleAdvanced,
                        style: UiText.sans(12, color: hover ? c.ink : c.muted),
                      ),
                      if (d.advancedHint != null)
                        Expanded(
                          child: Text(
                            d.advancedHint!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: UiText.sans(12, color: c.faint),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_advanced)
                  Padding(
                    key: const Key('tools-upscale-fields'),
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 6,
                      children: [
                        for (final f in d.advanced)
                          _Field(
                            field: f,
                            onChanged: busy
                                ? null
                                : (v) => a.onAdvanced(f.id, v),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
    return ToolsSheetFrame(
      key: const Key('tools-upscale-sheet'),
      width: ToolsUpscaleSheet.width,
      icon: 'nai-icon-upscale',
      title: l.tools_upscale,
      subtitle: l.tools_upscaleSub,
      onClose: a.onClose,
      onRun: canRun ? a.onRun : null,
      body: body,
      footer: [
        _FooterNote(
          d.blocked ?? l.tools_upscaleFooter,
          color: d.blocked != null ? c.warn : null,
        ),
        ToolsButton(
          key: const Key('tools-upscale-run'),
          tone: ToolsButtonTone.primary,
          onTap: canRun ? a.onRun : null,
          cost: ToolsButtonCost(d.cost ?? 0),
          children: [Text(l.tools_upscale)],
        ),
      ],
    );
  }

  static String _stateLabel(BuildContext context, ToolsModelState s) =>
      switch (s) {
        ToolsModelState.missing => context.l10n.tools_modelMissing,
        ToolsModelState.downloading => context.l10n.tools_modelDownloading,
        ToolsModelState.ready => '',
      };
}

/// 放大方式卡（原型 `.opt`）：单选圈 + 名字 + 价格角标，下面一句说明；选中强调色 2px 描边 + 6% 底。
class _BackendCard extends StatelessWidget {
  const _BackendCard({
    required this.backend,
    required this.selected,
    required this.onTap,
  });
  final ToolsUpscaleBackend backend;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final b = backend;
    final card = UiPressable(
      key: Key('tools-backend-${b.id}'),
      onTap: selected ? null : onTap,
      builder: (context, hover) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? c.accent.withValues(alpha: .06)
              : (hover ? c.hover : null),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? c.accent : c.line),
        ),
        // 选中再往里加 1px（原型 inset 阴影），不占位置、内容不跳。
        foregroundDecoration: selected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.accent, width: 2),
              )
            : null,
        child: Row(
          spacing: 10,
          children: [
            UiRadio(value: selected),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      Flexible(
                        child: Text(
                          b.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: UiText.sans(
                            13,
                            weight: FontWeight.w600,
                            color: c.ink,
                          ),
                        ),
                      ),
                      if (b.cost == null)
                        UiMini(l.tools_free, foreground: c.ok)
                      else
                        Container(
                          height: 18,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: c.control,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            widthFactor: 1,
                            child: GenAnlas(
                              '${b.cost}',
                              size: 10.5,
                              iconSize: 10,
                              color: c.muted,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    b.detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.sans(11, color: c.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return b.enabled ? card : Opacity(opacity: .5, child: card);
  }
}

/// 模型下拉（原型 `.chip`，30 高、最小宽 220）：状态点 + 名字，右边箭头。
class _ModelChip extends StatelessWidget {
  const _ModelChip({required this.model, required this.onTap});
  final ToolsUpscaleModel? model;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final m = model;
    final dot = switch (m?.state) {
      ToolsModelState.ready => c.ok,
      ToolsModelState.downloading => c.warn,
      _ => c.strong,
    };
    return UiPressable(
      key: const Key('tools-upscale-model'),
      onTap: onTap,
      builder: (context, hover) => Container(
        height: 30,
        constraints: const BoxConstraints(minWidth: 220),
        padding: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
          color: hover ? c.hover : c.control,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 34),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: dot,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    m?.label ?? l.tools_modelNone,
                    style: UiText.sans(12, color: c.ink),
                  ),
                  if (m != null && m.state != ToolsModelState.ready)
                    Text(
                      m.state == ToolsModelState.missing
                          ? l.tools_modelMissing
                          : l.tools_modelDownloading,
                      style: UiText.sans(11, color: c.warn),
                    ),
                ],
              ),
            ),
            Positioned(
              right: 10,
              child: UiGlyph(UiGlyphs.chevronDown, size: 13, color: c.ink),
            ),
          ],
        ),
      ),
    );
  }
}

/// 高级设置的一项：标签（宽 96）+ 数字滑杆 / 开关 / 分段。
class _Field extends StatelessWidget {
  const _Field({required this.field, required this.onChanged});
  final ToolsUpscaleField field;
  final ValueChanged<Object>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final f = field;
    final label = SizedBox(
      width: 96,
      child: Text(
        f.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: UiText.sans(12, color: c.muted),
      ),
    );
    final Widget control = switch (f.kind) {
      ToolsFieldKind.number => Expanded(
        child: ToolsSlider(
          value: (f.value as num).toDouble(),
          min: f.min,
          max: f.max,
          decimals: f.decimals,
          enabled: onChanged != null,
          onChanged: (v) => onChanged?.call(v),
        ),
      ),
      ToolsFieldKind.toggle => ToolsSwitchLabel(
        value: f.value as bool,
        label: '',
        onChanged: onChanged == null ? null : (v) => onChanged!(v),
      ),
      ToolsFieldKind.choice => ToolsSeg<String>(
        height: 28,
        values: [for (final o in f.options) o.id],
        selected: f.value as String,
        onChanged: onChanged == null ? null : (v) => onChanged!(v),
        label: (context, id, on) =>
            Text(f.options.firstWhere((o) => o.id == id).label),
      ),
    };
    final row = SizedBox(
      key: Key('tools-field-${f.id}'),
      height: 30,
      child: Row(spacing: 10, children: [label, control]),
    );
    return f.hint == null ? row : Tooltip(message: f.hint, child: row);
  }
}
