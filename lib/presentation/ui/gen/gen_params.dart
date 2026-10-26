import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'gen_contract.dart';
import 'gen_format.dart';
import 'gen_page.dart';
import 'gen_parts.dart';

/// 参数条（原型 `sumA`）：步数 / 引导 / 种子 / 采样器四列，右端展开钮。
/// 点种子列切换固定 / 随机，点采样器列弹分组菜单，点步数 / 引导或箭头开参数抽屉。
class GenParamStrip extends StatelessWidget {
  const GenParamStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context, GenAspect.params);
    final p = scope.data.params;
    final l = context.l10n;
    final open = scope.controller.drawerOpen;
    void toggle() => scope.controller.setDrawer(!open);
    return Container(
      key: const Key('gen-params'),
      decoration: BoxDecoration(
        color: GenPanelSurface.activeOf(context) ? Colors.transparent : c.bg,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          _Cell(
            key: const Key('gen-param-steps'),
            label: l.gen_steps,
            tooltip: p.fixedSampling ? l.gen_turboFixed : null,
            onTap: p.fixedSampling ? null : toggle,
            child: Text('${p.steps}'),
          ),
          _Cell(
            key: const Key('gen-param-scale'),
            label: l.gen_guidance,
            onTap: toggle,
            child: Text(GenFormat.decimal(p.scale)),
          ),
          _Cell(
            key: const Key('gen-param-seed'),
            label: p.seedPinned ? l.gen_seedPinned : l.gen_seed,
            tooltip: p.seedPinned ? l.gen_seedUnpinTip : l.gen_seedPinTip,
            onTap: p.seed == null && !p.seedPinned
                ? null
                : () => scope.actions.onSeedPinned(!p.seedPinned),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                if (p.seedPinned)
                  UiGlyph(
                    UiGlyphs.lock,
                    size: 12,
                    strokeWidth: 2,
                    color: c.accent,
                  ),
                Text(p.seed == null ? l.gen_random : '${p.seed}'),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (ctx) => _Cell(
                key: const Key('gen-param-sampler'),
                label: l.gen_sampler,
                tooltip: p.fixedSampling ? l.gen_turboFixed : null,
                onTap: p.fixedSampling ? null : () => _samplerMenu(ctx, scope),
                child: Text(p.samplerLabel, overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: AnimatedRotation(
              turns: open ? .5 : 0,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              child: GenIb(
                key: const Key('gen-params-toggle'),
                glyph: UiGlyphs.chevronUp,
                glyphSize: 15,
                strokeWidth: 2.2,
                bordered: true,
                color: c.ink,
                tooltip: open ? l.gen_paramsClose : l.gen_paramsOpen,
                onTap: toggle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _samplerMenu(BuildContext context, GenScope scope) {
  final p = scope.data.params;
  final l = context.l10n;
  final rec = p.samplers.where((s) => s.detail != null).toList();
  final other = p.samplers.where((s) => s.detail == null).toList();
  scope.controller.openPopover(
    genAbove(context, dy: 4),
    (_) => _GroupedMenu(
      groups: [
        if (rec.isNotEmpty) (l.gen_samplerRecommended, rec),
        if (other.isNotEmpty) (l.gen_samplerOther, other),
      ],
      selected: p.sampler,
      onSelect: scope.actions.onSamplerChanged,
    ),
    tag: #sampler,
  );
}

/// 参数条的一列（原型 `.sc`）：内边距 6 10、圆角 5；上小标签 11 / w500 弱 55%，下值 12 / w500。
class _Cell extends StatelessWidget {
  const _Cell({
    super.key,
    required this.label,
    required this.child,
    this.onTap,
    this.tooltip,
  });
  final String label;
  final Widget child;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final cell = UiPressable(
      onTap: onTap,
      builder: (context, hover) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: hover ? c.control : null,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              style: UiText.sans(
                11,
                weight: FontWeight.w500,
                color: GenFormat.ink55(c),
                height: 1.4,
              ),
            ),
            DefaultTextStyle.merge(
              style: UiText.sans(
                12,
                weight: FontWeight.w500,
                color: c.ink,
                height: 1.4,
              ),
              maxLines: 1,
              child: child,
            ),
          ],
        ),
      ),
    );
    return tooltip == null ? cell : Tooltip(message: tooltip, child: cell);
  }
}

/// 分组菜单（采样器 / 噪声调度）：组标题 + 项（右侧弱色说明），当前项打勾。
class _GroupedMenu extends StatelessWidget {
  const _GroupedMenu({
    required this.groups,
    required this.selected,
    required this.onSelect,
  });
  final List<(String, List<GenOption>)> groups;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context, GenAspect.params);
    return UiPopoverSurface(
      width: 250,
      padding: const EdgeInsets.all(4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (title, items) in groups) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                  child: Text(
                    title,
                    style: UiText.sans(
                      11,
                      weight: FontWeight.w600,
                      color: c.faint,
                    ),
                  ),
                ),
                for (final o in items)
                  UiPressable(
                    key: Key('gen-option-${o.id}'),
                    onTap: () {
                      scope.controller.closePopover();
                      if (o.id != selected) onSelect(o.id);
                    },
                    builder: (context, hover) => Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: hover ? c.control : null,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: Text(
                              o.label,
                              style: UiText.sans(
                                13,
                                weight: o.id == selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: c.ink,
                              ),
                            ),
                          ),
                          if (o.detail?.isNotEmpty ?? false)
                            Text(
                              o.detail!,
                              style: UiText.sans(11.5, color: c.faint),
                            ),
                          if (o.id == selected)
                            UiGlyph(
                              UiGlyphs.check,
                              size: 14,
                              strokeWidth: 2.4,
                              color: c.accent,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 参数抽屉的宿主：抽屉开着时盖住模块区（黑 25% 遮罩，点遮罩收起），抽屉从参数条上沿拉出（220ms）。
class GenParamDrawerHost extends StatefulWidget {
  const GenParamDrawerHost({super.key, required this.child});
  final Widget child;

  @override
  State<GenParamDrawerHost> createState() => _GenParamDrawerHostState();
}

class _GenParamDrawerHostState extends State<GenParamDrawerHost>
    with SingleTickerProviderStateMixin {
  late final _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final open = GenScope.of(context, GenAspect.params).controller.drawerOpen;
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (open && _a.value < 1 && _a.status != AnimationStatus.forward) {
      reduce ? _a.value = 1 : _a.forward();
    } else if (!open && _a.value > 0 && _a.status != AnimationStatus.reverse) {
      reduce ? _a.value = 0 : _a.reverse();
    }
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = GenScope.of(context, GenAspect.params);
    return LayoutBuilder(
      builder: (context, box) => AnimatedBuilder(
        animation: _a,
        builder: (context, _) {
          final t = Curves.easeOutCubic.transform(_a.value);
          return Stack(
            children: [
              widget.child,
              if (_a.value > 0) ...[
                Positioned.fill(
                  child: GestureDetector(
                    key: const Key('gen-params-mask'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => scope.controller.setDrawer(false),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: .25 * t),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ClipRect(
                    child: FractionalTranslation(
                      translation: Offset(0, 1 - t),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: box.maxHeight - 12,
                        ),
                        child: const _Drawer(),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Drawer extends StatelessWidget {
  const _Drawer();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context, GenAspect.params);
    final p = scope.data.params;
    final a = scope.actions;
    final l = context.l10n;
    return Container(
      key: const Key('gen-params-drawer'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        border: Border(
          top: BorderSide(color: c.line),
          left: BorderSide(color: c.line),
          right: BorderSide(color: c.line),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.only(left: 14, right: 6),
            child: Row(
              children: [
                Text(
                  l.gen_paramsTitle,
                  style: UiText.sans(13, weight: FontWeight.w700, color: c.ink),
                ),
                const Spacer(),
                GenIb(
                  key: const Key('gen-params-close'),
                  glyph: UiGlyphs.chevronDown,
                  tooltip: l.gen_paramsClose,
                  onTap: () => scope.controller.setDrawer(false),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      const Expanded(child: _SeedField()),
                      if (!p.fixedSampling)
                        const Expanded(child: _SamplerField()),
                    ],
                  ),
                  if (p.noise != null) const _NoiseField(),
                  if (!p.fixedSampling)
                    GenSliderRow(
                      key: const Key('gen-drawer-steps'),
                      label: l.gen_steps,
                      labelWidth: 72,
                      value: p.steps.toDouble(),
                      min: 1,
                      max: p.maxSteps.toDouble(),
                      decimals: 0,
                      defaultValue: 28,
                      onChanged: (v) => a.onParamChanged(GenParam.steps, v),
                    ),
                  GenSliderRow(
                    key: const Key('gen-drawer-scale'),
                    label: l.gen_guidance,
                    labelWidth: 72,
                    tooltip: l.gen_guidanceTip,
                    value: p.scale,
                    max: p.maxScale,
                    decimals: 1,
                    defaultValue: 5,
                    onChanged: (v) => a.onParamChanged(GenParam.scale, v),
                  ),
                  if (p.cfgRescaleSupported)
                    GenSliderRow(
                      key: const Key('gen-drawer-rescale'),
                      label: l.gen_cfgRescale,
                      labelWidth: 72,
                      tooltip: l.gen_cfgRescaleTip,
                      value: p.cfgRescale,
                      defaultValue: 0,
                      onChanged: (v) =>
                          a.onParamChanged(GenParam.cfgRescale, v),
                    ),
                  if (p.varietyPlus != null || p.decrisp != null)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (p.varietyPlus case final v?)
                          Tooltip(
                            message: l.gen_varietyTip,
                            child: UiFilterChip(
                              key: const Key('gen-variety'),
                              label: 'Variety+',
                              selected: v,
                              showCheck: true,
                              onTap: () => a.onVarietyChanged(!v),
                            ),
                          ),
                        if (p.decrisp case final v?)
                          Tooltip(
                            message: l.gen_decrispTip,
                            child: UiFilterChip(
                              key: const Key('gen-decrisp'),
                              label: 'Decrisp',
                              selected: v,
                              showCheck: true,
                              onTap: () => a.onDecrispChanged(!v),
                            ),
                          ),
                      ],
                    ),
                  if (p.smea case final s?) _SmeaRow(smea: s),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 抽屉里的字段：上标签（12 次要色）+ 下控件。
class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 6,
    children: [GenLabel(label), child],
  );
}

/// 下拉框：32 高、圆角 6、控件底。
class _Dropdown extends StatelessWidget {
  const _Dropdown({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      onTap: onTap,
      builder: (context, hover) => Container(
        height: 32,
        padding: const EdgeInsets.only(left: 10, right: 8),
        decoration: BoxDecoration(
          color: hover ? c.hover : c.control,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          spacing: 6,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.sans(13, color: c.ink),
              ),
            ),
            UiGlyph(UiGlyphs.chevronDown, size: 14, color: c.muted),
          ],
        ),
      ),
    );
  }
}

class _SamplerField extends StatelessWidget {
  const _SamplerField();

  @override
  Widget build(BuildContext context) {
    final scope = GenScope.of(context, GenAspect.params);
    return _Field(
      label: context.l10n.gen_sampler,
      child: Builder(
        builder: (ctx) => _Dropdown(
          key: const Key('gen-drawer-sampler'),
          label: scope.data.params.samplerLabel,
          onTap: () => _samplerMenu(ctx, scope),
        ),
      ),
    );
  }
}

class _NoiseField extends StatelessWidget {
  const _NoiseField();

  @override
  Widget build(BuildContext context) {
    final scope = GenScope.of(context, GenAspect.params);
    final p = scope.data.params;
    final label =
        p.noises.where((n) => n.id == p.noise).firstOrNull?.label ?? p.noise!;
    return _Field(
      label: context.l10n.gen_noiseSchedule,
      child: Builder(
        builder: (ctx) => _Dropdown(
          key: const Key('gen-drawer-noise'),
          label: label,
          onTap: () => scope.controller.openMenu(
            genAbove(ctx, dy: 4),
            [
              for (final n in p.noises)
                UiMenuItem(
                  label: n.label,
                  trailing: n.detail,
                  checked: n.id == p.noise,
                  onTap: () => scope.actions.onNoiseChanged(n.id),
                ),
            ],
            tag: #noise,
            width: 220,
          ),
        ),
      ),
    );
  }
}

/// 种子：输入框（回车提交并固定）+ 骰子（换成随机）+ 锁（固定 / 解除）。
class _SeedField extends StatefulWidget {
  const _SeedField();

  @override
  State<_SeedField> createState() => _SeedFieldState();
}

class _SeedFieldState extends State<_SeedField> {
  final _c = TextEditingController();
  final _f = FocusNode();
  var _beforeEdit = '';

  @override
  void initState() {
    super.initState();
    _f.addListener(() {
      if (_f.hasFocus) {
        _beforeEdit = _c.text;
      } else {
        _commit();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  void _commit() {
    if (_c.text == _beforeEdit) return;
    _beforeEdit = _c.text;
    final v = int.tryParse(_c.text.trim());
    if (v != null) {
      GenScope.of(context, GenAspect.params).actions.onSeedChanged(v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = GenScope.of(context, GenAspect.params);
    final p = scope.data.params;
    final l = context.l10n;
    final text = p.seed == null ? '' : '${p.seed}';
    if (!_f.hasFocus && _c.text != text) _c.text = text;
    return _Field(
      label: l.gen_seed,
      child: Container(
        height: 32,
        padding: const EdgeInsets.only(left: 10, right: 2),
        decoration: BoxDecoration(
          color: c.control,
          borderRadius: BorderRadius.circular(6),
          border: _f.hasFocus ? Border.all(color: c.accent) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('gen-drawer-seed'),
                controller: _c,
                focusNode: _f,
                style: UiText.mono(12.5, color: c.ink, height: 1.2),
                cursorColor: c.accent,
                cursorHeight: 14,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: uiBareDecoration(
                  hintText: l.gen_random,
                  hintStyle: UiText.sans(12.5, color: c.faint, height: 1.2),
                ),
                onSubmitted: (_) => _f.unfocus(),
              ),
            ),
            GenIb(
              key: const Key('gen-seed-random'),
              glyph: UiGlyphs.dice,
              size: 26,
              glyphSize: 14,
              tooltip: l.gen_seedRandomize,
              onTap: () => scope.actions.onSeedPinned(false),
            ),
            GenIb(
              key: const Key('gen-seed-lock'),
              glyph: p.seedPinned ? UiGlyphs.lock : UiGlyphs.unlock,
              size: 26,
              glyphSize: 14,
              color: p.seedPinned ? c.accent : null,
              tooltip: p.seedPinned ? l.gen_seedUnpinTip : l.gen_seedPinTip,
              onTap: p.seed == null && !p.seedPinned
                  ? null
                  : () => scope.actions.onSeedPinned(!p.seedPinned),
            ),
          ],
        ),
      ),
    );
  }
}

/// SMEA（V3）：自动开关 + SMEA / DYN 两个开关胶囊（自动时不可点）。
class _SmeaRow extends StatelessWidget {
  const _SmeaRow({required this.smea});
  final GenSmea smea;

  @override
  Widget build(BuildContext context) {
    final scope = GenScope.of(context, GenAspect.params);
    final s = smea;
    final l = context.l10n;
    void set({bool? auto, bool? on, bool? dyn}) => scope.actions.onSmeaChanged(
      GenSmea(auto: auto ?? s.auto, smea: on ?? s.smea, dyn: dyn ?? s.dyn),
    );
    return _Field(
      label: 'SMEA',
      child: Row(
        spacing: 6,
        children: [
          Tooltip(
            message: l.gen_smeaAutoTip,
            child: UiFilterChip(
              key: const Key('gen-smea-auto'),
              label: l.gen_auto,
              selected: s.auto,
              showCheck: true,
              onTap: () => set(auto: !s.auto),
            ),
          ),
          UiFilterChip(
            key: const Key('gen-smea'),
            label: 'SMEA',
            selected: s.smea,
            showCheck: true,
            onTap: s.auto ? null : () => set(on: !s.smea),
          ),
          UiFilterChip(
            key: const Key('gen-smea-dyn'),
            label: 'DYN',
            selected: s.dyn,
            showCheck: true,
            onTap: s.auto || !s.smea ? null : () => set(dyn: !s.dyn),
          ),
        ],
      ),
    );
  }
}
