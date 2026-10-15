import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_text.dart';
import 'channel_contract.dart';
import 'channel_format.dart';
import 'channel_geometry.dart';
import 'channel_palette.dart';
import 'channel_scene.dart';

/// 显示设置弹层里的“视觉通道”一节：模式、主题卡片、本次顺序 / 换一组、浓淡、时间刻度、空闲微动。
/// 放在宽约 292 的内容区里（弹层宽 316、内边距 12）。
class ChannelSettingsSection extends StatefulWidget {
  const ChannelSettingsSection({
    super.key,
    required this.settings,
    required this.onChanged,
    this.anchorY = 0,
    this.generating = false,
    this.newSeed,
  });

  final ChannelSettings settings;
  final ValueChanged<ChannelSettings> onChanged;

  /// 画布最新一批顶边的世界 y：“本次”从这里所在的段开始列。
  final double anchorY;

  /// 生成中：标题旁写“动画已暂停”（微动开着时）。
  final bool generating;

  /// “换一组”的新种子；默认随机（测试里注入固定值）。
  final int Function()? newSeed;

  @override
  State<ChannelSettingsSection> createState() => _ChannelSettingsSectionState();
}

class _ChannelSettingsSectionState extends State<ChannelSettingsSection> {
  Timer? _flash;

  @override
  void dispose() {
    _flash?.cancel();
    super.dispose();
  }

  void _set(ChannelSettings v) => widget.onChanged(v);

  void _tapCard(ChannelTheme t) {
    final s = widget.settings;
    switch (s.mode) {
      case ChannelMode.fixed:
        _set(s.copyWith(fixed: t));
      case ChannelMode.random:
        if (!s.pool.contains(t)) {
          _set(s.copyWith(pool: {...s.pool, t}));
        } else if (s.pool.length <= 2) {
          setState(() {});
          _flash?.cancel();
          _flash = Timer(const Duration(milliseconds: 1800), () {
            if (mounted) setState(() => _flash = null);
          });
        } else {
          _set(s.copyWith(pool: {...s.pool}..remove(t)));
        }
      case ChannelMode.off:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final s = widget.settings;
    final off = s.mode == ChannelMode.off;
    Widget dim(Widget child) =>
        off ? IgnorePointer(child: Opacity(opacity: .4, child: child)) : child;
    return Column(
      key: const Key('channel-settings'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          spacing: 6,
          children: [
            Text(
              l.channel_title,
              style: UiText.sans(13, weight: FontWeight.w700, color: c.ink),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l.channel_new,
                style: UiText.mono(
                  10,
                  weight: FontWeight.w500,
                  color: c.accent,
                  height: 1.3,
                ),
              ),
            ),
            if (widget.generating && s.motion && !off)
              Flexible(
                child: Text(
                  l.channel_paused,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(10.5, color: c.accent),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          l.channel_subtitle,
          style: UiText.sans(11.5, color: c.muted, height: 1.45),
        ),
        const SizedBox(height: 10),
        _FillSegmented<ChannelMode>(
          key: const Key('channel-mode'),
          values: ChannelMode.values,
          selected: s.mode,
          labelOf: (m) => ChannelFormat.mode(context, m),
          keyOf: (m) => 'channel-mode-${m.name}',
          onChanged: (m) => _set(s.copyWith(mode: m)),
        ),
        const SizedBox(height: 10),
        dim(
          GridView(
            key: const Key('channel-cards'),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              mainAxisExtent: 82.7,
            ),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final t in ChannelTheme.values)
                _Card(
                  theme: t,
                  seed: s.seed,
                  on: s.mode == ChannelMode.fixed
                      ? s.fixed == t
                      : s.pool.contains(t),
                  faded: s.mode == ChannelMode.random && !s.pool.contains(t),
                  onTap: () => _tapCard(t),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        dim(_note(context)),
        const SizedBox(height: 10),
        dim(
          Row(
            spacing: 10,
            children: [
              Text(l.channel_level, style: UiText.sans(12.5, color: c.ink)),
              Expanded(
                child: _FillSegmented<ChannelLevel>(
                  key: const Key('channel-level'),
                  values: ChannelLevel.values,
                  selected: s.level,
                  labelOf: (v) => ChannelFormat.level(context, v),
                  keyOf: (v) => 'channel-level-${v.name}',
                  onChanged: (v) => _set(s.copyWith(level: v)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        dim(
          _SwitchRow(
            key: const Key('channel-ruler'),
            title: l.channel_ruler,
            sub: l.channel_rulerSub,
            value: s.ruler,
            onTap: () => _set(s.copyWith(ruler: !s.ruler)),
          ),
        ),
        const SizedBox(height: 9),
        dim(
          _SwitchRow(
            key: const Key('channel-motion'),
            title: l.channel_motion,
            sub: l.channel_motionSub,
            value: s.motion,
            onTap: () => _set(s.copyWith(motion: !s.motion)),
          ),
        ),
      ],
    );
  }

  Widget _note(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final s = widget.settings;
    final Widget body;
    if (_flash != null) {
      body = Text(
        l.channel_minTwo,
        style: UiText.sans(11.5, color: c.warn, height: 1.45),
      );
    } else {
      switch (s.mode) {
        case ChannelMode.random:
          final env = ChannelEnv.of(s);
          final seq = env.sequenceFrom(
            widget.anchorY,
            math.min(env.order.length, 6),
          );
          body = Row(
            spacing: 8,
            children: [
              Text(
                l.channel_session,
                style: UiText.sans(11.5, color: c.muted, height: 1.45),
              ),
              Expanded(
                child: Text(
                  [
                    for (final t in seq) ChannelFormat.name(context, t),
                  ].join(' → '),
                  key: const Key('channel-sequence'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(11.5, color: c.ink, height: 1.45),
                ),
              ),
              UiPressable(
                key: const Key('channel-reroll'),
                onTap: () =>
                    _set(s.copyWith(seed: (widget.newSeed ?? _randomSeed)())),
                builder: (context, hover) => Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 3,
                  children: [
                    UiGlyph(UiGlyphs.dice, size: 13, color: c.accent),
                    Text(
                      l.channel_reroll,
                      style: UiText.sans(
                        11.5,
                        color: c.accent,
                        weight: hover ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        case ChannelMode.fixed:
          body = Text(
            ChannelFormat.description(context, s.fixed),
            style: UiText.sans(11.5, color: c.muted, height: 1.45),
          );
        case ChannelMode.off:
          body = Text(
            l.channel_offNote,
            style: UiText.sans(11.5, color: c.muted, height: 1.45),
          );
      }
    }
    return Container(
      key: const Key('channel-note'),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(7),
      ),
      child: body,
    );
  }

  static final _rng = math.Random();
  static int _randomSeed() => _rng.nextInt(1 << 31);
}

/// 等分的分段控件（原型 `.seg`）：控件底、内边距 2、圆角 7；选中项抬起。
class _FillSegmented<T> extends StatelessWidget {
  const _FillSegmented({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.keyOf,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final String Function(T) keyOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      height: 30,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        spacing: 2,
        children: [
          for (final v in values)
            Expanded(
              child: UiPressable(
                key: Key(keyOf(v)),
                onTap: v == selected ? null : () => onChanged(v),
                builder: (context, hover) {
                  final on = v == selected;
                  return Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: on ? (c.dark ? c.hover : c.raised) : null,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: on && !c.dark
                          ? const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      labelOf(v),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.sans(
                        12,
                        weight: on ? FontWeight.w500 : FontWeight.w400,
                        color: on || hover ? c.ink : c.muted,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// 开关行：标题 12.5 + 说明 11（次要色）│ 30 × 18 开关；整行可点。
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    super.key,
    required this.title,
    required this.sub,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String sub;
  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      onTap: onTap,
      builder: (context, _) => Row(
        spacing: 10,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: UiText.sans(12.5, color: c.ink, height: 1.45),
                ),
                Text(sub, style: UiText.sans(11, color: c.muted, height: 1.45)),
              ],
            ),
          ),
          UiSwitch(value: value, width: 30, height: 18),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.theme,
    required this.seed,
    required this.on,
    required this.faded,
    required this.onTap,
  });

  final ChannelTheme theme;
  final int seed;
  final bool on;
  final bool faded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      key: Key('channel-card-${theme.name}'),
      onTap: onTap,
      builder: (context, hover) => Opacity(
        opacity: faded ? .45 : 1,
        child: Container(
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: on ? c.accent : (hover ? c.strong : c.border),
            ),
            boxShadow: on
                ? [BoxShadow(color: c.accent, spreadRadius: 1)]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: CustomPaint(
                        painter: ChannelThumbPainter(
                          theme: theme,
                          seed: seed,
                          dark: c.dark,
                          base: c.bg,
                        ),
                      ),
                    ),
                    Container(
                      height: 25,
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: c.border)),
                        color: c.bg,
                      ),
                      alignment: Alignment.centerLeft,
                      child: ChannelSwatchName(theme: theme),
                    ),
                  ],
                ),
                if (on)
                  Positioned(
                    right: 5,
                    top: 5,
                    child: Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.accent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: UiGlyph(
                        UiGlyphs.check,
                        size: 11,
                        color: c.onAccent,
                        strokeWidth: 2.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 卡片底部：7 方色块 + 主题名（11.5 / 500）。
class ChannelSwatchName extends StatelessWidget {
  const ChannelSwatchName({super.key, required this.theme});
  final ChannelTheme theme;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Row(
      spacing: 5,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: ChannelPalette.of(theme).swatch,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: Text(
            ChannelFormat.name(context, theme),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: UiText.sans(11.5, weight: FontWeight.w500, color: c.ink),
          ),
        ),
      ],
    );
  }
}

/// 主题缩略图：装饰坐标里第 0 段 42% 处、图片右侧的一小块，缩放 0.15。
class ChannelThumbPainter extends CustomPainter {
  ChannelThumbPainter({
    required this.theme,
    required this.seed,
    required this.dark,
    required this.base,
  });

  final ChannelTheme theme;
  final int seed;
  final bool dark;
  final Color base;

  @override
  void paint(Canvas canvas, Size size) {
    const k = ChannelGeo.decorScale, decor = 0.15;
    final world = Offset(
      (ChannelGeo.e + 250) * k,
      (ChannelGeo.zoneStart(0) + ChannelGeo.zone * 0.42) * k,
    );
    const scale = decor / k;
    paintChannelScene(
      canvas,
      size,
      ChannelSceneSpec(
        env: ChannelEnv.single(theme),
        camera: ChannelCamera(
          offset: size.center(Offset.zero) - world * scale,
          scale: scale,
        ),
        dark: dark,
        base: base,
        level: 1,
        seed: seed,
        names: const {},
        thumb: true,
      ),
    );
  }

  @override
  bool shouldRepaint(ChannelThumbPainter old) =>
      old.theme != theme ||
      old.seed != seed ||
      old.dark != dark ||
      old.base != base;
}
