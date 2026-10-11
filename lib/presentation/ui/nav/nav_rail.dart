import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../widgets/common/studio_animated_icon.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_text.dart';
import '../kit/ui_tip.dart';
import 'nav_contract.dart';
import 'nav_labels.dart';
import 'nav_tips.dart';

/// 48 宽图标栏：头像固定在顶，中间四组可滚动，底部是后台任务、展开、设置。
class NavRail extends StatelessWidget {
  const NavRail({
    super.key,
    required this.data,
    required this.ctrlHeld,
    required this.tipsEnabled,
    required this.onOpenPage,
    required this.onAvatar,
    required this.onTasks,
    required this.onExpand,
    required this.onContextMenu,
  });

  static const width = 48.0;

  final NavViewData data;

  /// 按住 Ctrl 超过 0.4 秒：每个图标右下角显示编号。
  final bool ctrlHeld;

  /// 有弹层或展开浮层时不出悬停提示。
  final bool tipsEnabled;
  final ValueChanged<NavPage> onOpenPage;

  /// 回调带上被点的组件，用来定位弹层。
  final ValueChanged<BuildContext> onAvatar;
  final ValueChanged<BuildContext> onTasks;
  final VoidCallback onExpand;
  final ValueChanged<Offset> onContextMenu;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final groups = data.visibleGroups;
    List<String>? keys(NavPage p) =>
        data.showShortcutsInTips ? data.shortcuts[p] : null;

    Widget page(NavPage p) {
      final gen = p == NavPage.generation ? data.generation : null;
      final rich = gen != null && gen.state != NavGenerationState.idle;
      return NavRailButton(
        key: Key('main-nav-${p.name}'),
        selected: data.current == p,
        reducedMotion: data.reducedMotion,
        icon: p.icon,
        semanticLabel: p.label(context),
        tipsEnabled: tipsEnabled,
        richTip: rich,
        tip: () => rich
            ? NavGenerationTip(generation: gen, keys: keys(p))
            : NavSimpleTip(label: p.label(context), keys: keys(p)),
        onTap: () => onOpenPage(p),
        badges: [
          if (gen != null) ..._generationBadges(c, gen),
          if (ctrlHeld)
            if (data.ctrlNumber(p) case final n?) _CtrlNumber(n),
        ],
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onSecondaryTapUp: (d) => onContextMenu(d.globalPosition),
      child: Container(
        key: const Key('main-nav-rail'),
        width: width,
        color: c.bg,
        foregroundDecoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: c.line.withValues(alpha: .75)),
          ),
        ),
        // 右边 1px 描边占位（和 CSS border-box 一致），图标中心在 23.5。
        padding: const EdgeInsets.only(right: 1),
        child: Column(
          children: [
            const SizedBox(height: 5),
            NavRailButton(
              key: const Key('main-nav-avatar'),
              plain: true,
              semanticLabel: data.account.current?.name ?? l.navShell_account,
              tipsEnabled: tipsEnabled,
              tip: () => NavSimpleTip(
                label: data.account.current?.name ?? l.navShell_account,
              ),
              onTapWithContext: onAvatar,
              child: (_) => NavAvatar(account: data.account.current, size: 30),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: SingleChildScrollView(
                key: const Key('main-nav-primary-scroll'),
                child: Column(
                  children: [
                    for (final (i, g) in groups.indexed) ...[
                      if (i > 0) _GroupLine(key: Key('main-nav-line-$i')),
                      for (final p in g) page(p),
                    ],
                  ],
                ),
              ),
            ),
            if (data.tasks.isNotEmpty) ...[
              NavRailButton(
                key: const Key('main-nav-tasks'),
                semanticLabel: l.navShell_tasksTitle,
                tipsEnabled: tipsEnabled,
                tip: () => NavSimpleTip(label: l.navShell_tasksTitle),
                onTapWithContext: onTasks,
                child: (_) => NavTasksGlyph(data: data),
              ),
              const SizedBox(height: 6),
            ],
            NavRailButton(
              key: const Key('main-nav-toggle'),
              muted: true,
              semanticLabel: l.navShell_expand,
              tipsEnabled: tipsEnabled,
              tip: () => NavSimpleTip(label: l.navShell_expand),
              onTap: onExpand,
              child: (color) =>
                  UiGlyph(UiGlyphs.doubleRight, size: 17, color: color),
            ),
            NavRailButton(
              key: const Key('main-nav-settings'),
              muted: true,
              selected: data.current == NavPage.settings,
              reducedMotion: data.reducedMotion,
              icon: NavPage.settings.icon,
              iconSize: 19,
              semanticLabel: NavPage.settings.label(context),
              tipsEnabled: tipsEnabled,
              tip: () => NavSimpleTip(
                label: NavPage.settings.label(context),
                keys: keys(NavPage.settings),
              ),
              onTap: () => onOpenPage(NavPage.settings),
              badges: [
                if (data.updateAvailable) _Dot(color: c.error),
                if (ctrlHeld)
                  if (data.ctrlNumber(NavPage.settings) case final n?)
                    _CtrlNumber(n),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static List<Widget> _generationBadges(UiColors c, NavGeneration g) =>
      switch (g.state) {
        NavGenerationState.running => [
          Positioned(
            left: -1,
            top: -1,
            child: CustomPaint(
              size: const Size.square(38),
              painter: _RingPainter(g.ringFraction, c.accent),
            ),
          ),
          if (g.total > 1) _CountBadge('${g.current}/${g.total}'),
        ],
        NavGenerationState.done => [_Dot(color: c.accent)],
        NavGenerationState.failed => [_Dot(color: c.error)],
        NavGenerationState.idle => const [],
      };
}

class _GroupLine extends StatelessWidget {
  const _GroupLine({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 16,
    height: 1.5,
    margin: const EdgeInsets.symmetric(vertical: 9),
    decoration: BoxDecoration(
      color: context.ui.strong,
      borderRadius: BorderRadius.circular(1),
    ),
  );
}

/// 导航栏按钮：点击区 48 × 40，视觉底板 36 × 36、圆角 9；选中时贴左边缘一条竖线。
/// 可 Tab 聚焦、Enter / 空格激活，聚焦时 1.5 强调色描边。悬停 0.3 秒出提示。
class NavRailButton extends StatefulWidget {
  const NavRailButton({
    super.key,
    this.icon,
    this.iconSize = 20,
    this.child,
    this.selected = false,
    this.muted = false,
    this.plain = false,
    this.reducedMotion = false,
    required this.semanticLabel,
    required this.tipsEnabled,
    this.tip,
    this.richTip = false,
    this.onTap,
    this.onTapWithContext,
    this.badges = const [],
  });

  /// 页面图标（带点击动效）；和 [child] 二选一。
  final IconData? icon;
  final double iconSize;
  final Widget Function(Color color)? child;
  final bool selected;

  /// 底部的展开 / 设置：平时用次要文字色。
  final bool muted;

  /// 头像：悬停只加底，不改前景色。
  final bool plain;
  final bool reducedMotion;
  final String semanticLabel;
  final bool tipsEnabled;
  final Widget Function()? tip;
  final bool richTip;
  final VoidCallback? onTap;
  final ValueChanged<BuildContext>? onTapWithContext;

  /// 画在 36 × 36 底板上的角标（Positioned，相对底板）。
  final List<Widget> badges;

  @override
  State<NavRailButton> createState() => _NavRailButtonState();
}

class _NavRailButtonState extends State<NavRailButton> {
  var _hover = false;
  var _focus = false;
  var _pressed = false;
  var _showTip = false;
  var _motion = 0;
  Timer? _tipTimer;

  @override
  void didUpdateWidget(covariant NavRailButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.tipsEnabled) _hideTip();
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    super.dispose();
  }

  void _hideTip() {
    _tipTimer?.cancel();
    _showTip = false;
  }

  void _setHover(bool v) {
    setState(() {
      _hover = v;
      _hideTip();
      if (v && widget.tipsEnabled && widget.tip != null) {
        _tipTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted && _hover && widget.tipsEnabled) {
            setState(() => _showTip = true);
          }
        });
      }
    });
  }

  void _activate() {
    setState(() {
      _motion++;
      _hideTip();
    });
    widget.onTap?.call();
    widget.onTapWithContext?.call(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final on = widget.selected;
    final fg = on
        ? c.accent
        : _hover && !widget.plain
        ? c.ink
        : widget.muted
        ? c.muted
        : c.ink.withValues(alpha: .7);
    final bg = on
        ? c.accent.withValues(alpha: _hover ? .16 : .11)
        : _hover
        ? c.hover
        : Colors.transparent;
    final reduce =
        widget.reducedMotion || MediaQuery.disableAnimationsOf(context);
    final glyph = widget.icon != null
        ? StudioAnimatedIcon(
            icon: widget.icon!,
            trigger: _motion,
            color: fg,
            size: widget.iconSize,
            reducedMotion: widget.reducedMotion,
          )
        : widget.child!(fg);
    final plate = AnimatedContainer(
      duration: reduce ? Duration.zero : const Duration(milliseconds: 150),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9),
      ),
      foregroundDecoration: _focus
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: c.accent, width: 1.5),
            )
          : null,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [glyph, ...widget.badges],
      ),
    );
    final tip = _showTip && widget.tipsEnabled ? widget.tip?.call() : null;
    return Semantics(
      button: true,
      selected: on,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (v) => setState(() => _focus = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: MouseRegion(
          onEnter: (_) => _setHover(true),
          onExit: (_) => _setHover(false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _activate,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: SizedBox(
              width: NavRail.width - 1,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 0,
                    top: 12,
                    child: AnimatedOpacity(
                      opacity: on ? 1 : 0,
                      duration: reduce
                          ? Duration.zero
                          : const Duration(milliseconds: 150),
                      child: const NavSelectedBar(),
                    ),
                  ),
                  AnimatedScale(
                    scale: _pressed && !reduce ? .97 : 1,
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOutCubic,
                    child: UiTipHost(
                      tip: tip == null
                          ? null
                          : UiTip(
                              targetAnchor: widget.richTip
                                  ? Alignment.topRight
                                  : Alignment.centerRight,
                              followerAnchor: widget.richTip
                                  ? Alignment.topLeft
                                  : Alignment.centerLeft,
                              anchor: Offset(12, widget.richTip ? -6 : 0),
                              bare: true,
                              child: tip,
                            ),
                      child: plate,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 选中竖线：3 × 16，右侧圆角 3。
class NavSelectedBar extends StatelessWidget {
  const NavSelectedBar({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 3,
    height: 16,
    decoration: BoxDecoration(
      color: context.ui.accent,
      borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
    ),
  );
}

/// 账号头像：自定义图或首字（品牌蓝底白字），圆角 8（40 及以上为 10）；
/// 订阅快到期 / 已过期时右下角一个琥珀色点。未登录是灰底人像。
class NavAvatar extends StatelessWidget {
  const NavAvatar({
    super.key,
    required this.account,
    required this.size,
    this.muted = false,
    this.showSubscriptionDot = true,
  });

  final NavAccount? account;
  final double size;

  /// 切换列表里的其他账号：强调色 12% 底 + 强调色字。
  final bool muted;
  final bool showSubscriptionDot;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final a = account;
    final radius = BorderRadius.circular(size >= 40 ? 10 : 8);
    final Widget face;
    if (a == null) {
      face = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: c.control, borderRadius: radius),
        alignment: Alignment.center,
        child: UiGlyph(UiGlyphs.user, size: size * .55, color: c.muted),
      );
    } else if (a.avatar != null) {
      face = ClipRRect(
        borderRadius: radius,
        child: Image(
          image: a.avatar!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    } else {
      face = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: muted ? c.accent.withValues(alpha: .12) : c.avatar,
          borderRadius: radius,
        ),
        alignment: Alignment.center,
        child: Text(
          a.name.isEmpty ? '?' : a.name.characters.first.toUpperCase(),
          style: UiText.sans(
            size * .46,
            weight: FontWeight.w700,
            height: 1,
            color: muted ? c.accent : Colors.white,
          ),
        ),
      );
    }
    final warn =
        showSubscriptionDot &&
        (a?.subscription?.state ?? NavSubscriptionState.ok) !=
            NavSubscriptionState.ok;
    if (!warn) return face;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        face,
        Positioned(
          right: -3,
          bottom: -3,
          child: Container(
            key: const Key('main-nav-subscription-dot'),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: c.subWarn,
              shape: BoxShape.circle,
              border: Border.all(color: c.bg, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

/// 后台任务图标：22 的圆环，圈里写进行中的任务数；进度已知时弧长 = 平均进度，未知时一段弧在转。
class NavTasksGlyph extends StatefulWidget {
  const NavTasksGlyph({super.key, required this.data});
  final NavViewData data;

  @override
  State<NavTasksGlyph> createState() => _NavTasksGlyphState();
}

class _NavTasksGlyphState extends State<NavTasksGlyph>
    with SingleTickerProviderStateMixin {
  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  double? get _fraction {
    final known = [
      for (final t in widget.data.tasks)
        if (!t.finished && t.resolvedFraction != null) t.resolvedFraction!,
    ];
    if (widget.data.tasks.every((t) => t.finished)) return 1;
    return known.isEmpty ? null : known.reduce((a, b) => a + b) / known.length;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant NavTasksGlyph oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final run =
        _fraction == null &&
        !widget.data.reducedMotion &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (run && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!run && _spin.isAnimating) {
      _spin
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final f = _fraction;
    return SizedBox.square(
      dimension: 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: _spin,
            child: CustomPaint(
              size: const Size.square(22),
              painter: _TaskRingPainter(
                f == null ? 1 / 6 : math.max(.08, f),
                track: c.line,
                arc: c.accent,
              ),
            ),
          ),
          Text(
            '${widget.data.runningTasks}',
            style: UiText.mono(
              10,
              weight: FontWeight.w600,
              height: 1,
              color: c.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRingPainter extends CustomPainter {
  _TaskRingPainter(this.fraction, {required this.track, required this.arc});
  final double fraction;
  final Color track;
  final Color arc;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: 9 * k,
    );
    final p = Paint()..style = PaintingStyle.stroke;
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      p
        ..color = track
        ..strokeWidth = 2 * k,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * fraction,
      false,
      p
        ..color = arc
        ..strokeWidth = 2.2 * k
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TaskRingPainter old) =>
      old.fraction != fraction || old.track != track || old.arc != arc;
}

/// 生图进度圈：和按钮同形的 38 × 38 圆角矩形（圆角 10），线宽 2.2，
/// 从顶边 12% 处顺时针走；底环强调色 22%。
class _RingPainter extends CustomPainter {
  _RingPainter(this.fraction, this.color);
  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(1, 1, 36, 36),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: .22),
    );
    if (fraction <= 0) return;
    // 从 (x + r, y) 起顺时针，和 SVG <rect> 的描边起点一致。
    final path = Path()
      ..moveTo(11, 1)
      ..lineTo(27, 1)
      ..arcToPoint(const Offset(37, 11), radius: const Radius.circular(10))
      ..lineTo(37, 27)
      ..arcToPoint(const Offset(27, 37), radius: const Radius.circular(10))
      ..lineTo(11, 37)
      ..arcToPoint(const Offset(1, 27), radius: const Radius.circular(10))
      ..lineTo(1, 11)
      ..arcToPoint(const Offset(11, 1), radius: const Radius.circular(10));
    final PathMetric m = path.computeMetrics().first;
    final start = m.length * .12;
    final len = m.length * fraction.clamp(0, 1);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = color;
    final end = start + len;
    canvas.drawPath(m.extractPath(start, math.min(end, m.length)), stroke);
    if (end > m.length) {
      canvas.drawPath(m.extractPath(0, end - m.length), stroke);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color;
}

/// 第几张：高 14、圆角 4、强调色底白字，外加 1.5 底色描边；贴右下角外 (−5, −3)。
class _CountBadge extends StatelessWidget {
  const _CountBadge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Positioned(
      right: -5,
      bottom: -3,
      child: Container(
        height: 17,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.accent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: c.bg, width: 1.5),
        ),
        child: Text(
          text,
          style: UiText.mono(
            9.5,
            weight: FontWeight.w600,
            height: 1,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// 状态点：8 × 8、1.5 底色描边，右上角内 3。
class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Positioned(
    right: 3,
    top: 3,
    child: Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: context.ui.bg, width: 1.5),
      ),
    ),
  );
}

/// 按住 Ctrl 的编号：最小 16 × 16、圆角 4、正文色底、底色字，贴右下角外 (−5, −4)。
class _CtrlNumber extends StatelessWidget {
  const _CtrlNumber(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Positioned(
      right: -5,
      bottom: -4,
      child: Container(
        constraints: const BoxConstraints(minWidth: 16),
        height: 16,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.ink,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [BoxShadow(color: c.bg, spreadRadius: 1.5)],
        ),
        child: Text(
          text,
          style: UiText.mono(
            10.5,
            weight: FontWeight.w600,
            height: 1,
            color: c.bg,
          ),
        ),
      ),
    );
  }
}
