import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../l10n/app_localizations.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_text.dart';
import 'agent_glyphs.dart';

/// 过程行的类型：决定图标和它运行中的小动画。
enum AgentActivityKind { think, read, run, image, write, gen, external, ask }

/// 工具名 → 类型；不认识的（外部 MCP）算外部工具。
AgentActivityKind agentActivityKind(String tool) => switch (tool) {
  'studio_context' ||
  'snapshot' ||
  'wiki_query' ||
  'tag_query' ||
  'block_query' ||
  'settings_read' ||
  'gallery_query' ||
  'reference_library' ||
  'studio_search' ||
  'read' => AgentActivityKind.read,
  'bash' || 'codemode' || 'code_mode' => AgentActivityKind.run,
  'image_read' || 'image_tool' => AgentActivityKind.image,
  'prompt_set' ||
  'prompt_update' ||
  'block_manage' ||
  'settings_update' ||
  'explore_manage' ||
  'gallery_manage' ||
  'reference_manage' ||
  'write' ||
  'edit' => AgentActivityKind.write,
  'generation_prepare' ||
  'generation_run' ||
  'generation_cancel' ||
  'image_generate' => AgentActivityKind.gen,
  'ask_user' => AgentActivityKind.ask,
  _ when tool.endsWith('__codemode') => AgentActivityKind.run,
  _ => AgentActivityKind.external,
};

/// 折叠行汇总里用的类型名（「运行命令 12 次」）。
String agentActivityLabel(AppLocalizations l, AgentActivityKind k) =>
    switch (k) {
      AgentActivityKind.think => l.ag_kindThink,
      AgentActivityKind.read => l.ag_kindRead,
      AgentActivityKind.run => l.ag_kindRun,
      AgentActivityKind.image => l.ag_kindImage,
      AgentActivityKind.write => l.ag_kindWrite,
      AgentActivityKind.gen => l.ag_kindGen,
      AgentActivityKind.external => l.ag_kindExternal,
      AgentActivityKind.ask => l.ag_kindAsk,
    };

enum AgentActivityState { running, done, failed, waiting }

/// 24 网格线性路径；动画分件的拆成两段。
abstract final class _P {
  static const think =
      'M12 3l1.9 7.1L21 12l-7.1 1.9L12 21l-1.9-7.1L3 12l7.1-1.9z';
  static const runFrame =
      'M5.5 4h13A2.5 2.5 0 0121 6.5v11a2.5 2.5 0 01-2.5 2.5h-13A2.5 2.5 0 013 17.5v-11A2.5 2.5 0 015.5 4zM7.5 9.5l3 2.5-3 2.5';
  static const runCursor = 'M13 15h3.5';
  static const genBig =
      'M10.5 3.5l1.9 4.9 4.9 1.9-4.9 1.9-1.9 4.9-1.9-4.9-4.9-1.9 4.9-1.9z';
  static const genSmall =
      'M18.5 14.5l.9 2.1 2.1.9-2.1.9-.9 2.1-.9-2.1-2.1-.9 2.1-.9z';
  static const external =
      'M9 3v4.5M15 3v4.5M6.5 7.5h11V11a5.5 5.5 0 01-11 0zM12 16.5V21';
  static const ask =
      'M4 6a2.5 2.5 0 012.5-2.5h11A2.5 2.5 0 0120 6v8a2.5 2.5 0 01-2.5 2.5H11l-4.5 3.5v-3.5H6.5A2.5 2.5 0 014 14zM10 8.6a2 2 0 113 1.7c-.6.4-1 .8-1 1.5M12 13.6v.01';
}

String _glyph(AgentActivityKind k) => switch (k) {
  AgentActivityKind.think => _P.think,
  AgentActivityKind.read => AgentGlyphs.search,
  AgentActivityKind.run => _P.runFrame,
  AgentActivityKind.image => AgentGlyphs.image,
  AgentActivityKind.write => AgentGlyphs.pen,
  AgentActivityKind.gen => _P.genBig,
  AgentActivityKind.external => _P.external,
  AgentActivityKind.ask => _P.ask,
};

/// 静态小图标（折叠行左侧的类型簇）。
class AgentActivityGlyph extends StatelessWidget {
  const AgentActivityGlyph(this.kind, {super.key, this.size = 12, this.color});
  final AgentActivityKind kind;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.ui.muted;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          AgentIcon(_glyph(kind), size: size, color: c),
          if (kind == AgentActivityKind.run)
            AgentIcon(_P.runCursor, size: size, color: c),
          if (kind == AgentActivityKind.gen)
            AgentIcon(_P.genSmall, size: size, color: c),
        ],
      ),
    );
  }
}

/// 过程行图标：按类型画；运行中有各自的小动画，结束后定格成灰色，
/// 结束那一下轻轻弹一下；失败变红加小红点；等你处理是琥珀色、轻轻浮动。
/// 系统关掉动画时一律静止。
class AgentActivityIcon extends StatefulWidget {
  const AgentActivityIcon({super.key, required this.kind, required this.state});
  final AgentActivityKind kind;
  final AgentActivityState state;

  @override
  State<AgentActivityIcon> createState() => _AgentActivityIconState();
}

class _AgentActivityIconState extends State<AgentActivityIcon>
    with TickerProviderStateMixin {
  late final _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  );
  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(covariant AgentActivityIcon old) {
    super.didUpdateWidget(old);
    if (old.state == AgentActivityState.running &&
        widget.state != AgentActivityState.running &&
        !_still) {
      _pop.forward(from: 0);
    }
    _sync();
  }

  void _sync() {
    final moving =
        !_still &&
        (widget.state == AgentActivityState.running ||
            widget.state == AgentActivityState.waiting);
    if (moving && !_loop.isAnimating) {
      _loop.repeat();
    } else if (!moving && _loop.isAnimating) {
      _loop.stop();
      _loop.value = 0;
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final color = switch (widget.state) {
      AgentActivityState.running => c.accent,
      AgentActivityState.done => c.muted,
      AgentActivityState.failed => c.error,
      AgentActivityState.waiting => c.warn,
    };
    final kind = widget.kind;
    final running = widget.state == AgentActivityState.running;
    final base = AgentIcon(_glyph(kind), size: 16, color: color);
    Widget icon;
    if (!running || _still) {
      icon = AgentActivityGlyph(kind, size: 16, color: color);
      if (widget.state == AgentActivityState.waiting && !_still) {
        icon = AnimatedBuilder(
          animation: _loop,
          child: icon,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, -1.5 * _ease(_loop.value)),
            child: child,
          ),
        );
      }
    } else {
      icon = AnimatedBuilder(
        animation: _loop,
        child: base,
        builder: (_, child) => _animated(kind, _loop.value, child!, color),
      );
    }
    return SizedBox.square(
      key: ValueKey('agent-activity-${kind.name}-${widget.state.name}'),
      dimension: 16,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ScaleTransition(
              scale: _pop.drive(
                Tween(
                  begin: 1.25,
                  end: 1.0,
                ).chain(CurveTween(curve: Curves.easeOut)),
              ),
              child: icon,
            ),
          ),
          if (widget.state == AgentActivityState.failed)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: c.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.card, width: 1.2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 0→1→0 的缓动。
  static double _ease(double t) => .5 - .5 * math.cos(2 * math.pi * t);

  Widget _animated(AgentActivityKind kind, double t, Widget base, Color color) {
    final e = _ease(t);
    switch (kind) {
      case AgentActivityKind.think:
        return Transform.rotate(
          angle: math.pi / 4 * e,
          child: Transform.scale(scale: .8 + .25 * e, child: base),
        );
      case AgentActivityKind.read:
        final a = 2 * math.pi * t;
        return Transform.translate(
          offset: Offset(math.cos(a) * 1.1, math.sin(a) * 1.1),
          child: base,
        );
      case AgentActivityKind.run:
        return Stack(
          children: [
            base,
            if ((t * 2).floor().isEven)
              AgentIcon(_P.runCursor, size: 16, color: color),
          ],
        );
      case AgentActivityKind.image:
        final y = 3.5 + 8 * (t < .5 ? t * 2 : 2 - t * 2);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            base,
            Positioned(
              left: 3,
              right: 3,
              top: y,
              child: Container(
                height: 1.4,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .5),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ],
        );
      case AgentActivityKind.write:
        return Transform.rotate(
          angle: -.12 + .2 * e,
          alignment: const Alignment(-.7, .7),
          child: base,
        );
      case AgentActivityKind.gen:
        final e2 = _ease((t + .5) % 1);
        return Stack(
          children: [
            Transform.scale(
              scale: .85 + .2 * e,
              alignment: const Alignment(-.12, -.17),
              child: base,
            ),
            Opacity(
              opacity: .3 + .7 * e2,
              child: Transform.scale(
                scale: .5 + .6 * e2,
                alignment: const Alignment(.54, .46),
                child: AgentIcon(_P.genSmall, size: 16, color: color),
              ),
            ),
          ],
        );
      case AgentActivityKind.external:
        return Opacity(opacity: .45 + .55 * e, child: base);
      case AgentActivityKind.ask:
        return Transform.translate(offset: Offset(0, -1.5 * e), child: base);
    }
  }
}

/// 流光文字：一道亮光从左往右慢慢扫过；关掉动画时就是普通灰字。
class AgentShimmer extends StatefulWidget {
  const AgentShimmer({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;

  @override
  State<AgentShimmer> createState() => _AgentShimmerState();
}

class _AgentShimmerState extends State<AgentShimmer>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(covariant AgentShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final on = widget.enabled && !_still;
    if (on && !_c.isAnimating) {
      _c.repeat();
    } else if (!on && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _still) return widget.child;
    final c = context.ui;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) => ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (rect) => LinearGradient(
          colors: [c.muted, c.muted, c.ink, c.muted, c.muted],
          stops: const [0, .35, .5, .65, 1],
          transform: _Slide(_c.value * 2 - 1),
        ).createShader(rect),
        child: child,
      ),
    );
  }
}

class _Slide extends GradientTransform {
  const _Slide(this.percent);
  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * percent, 0, 0);
}

/// 对话流里「哪些已经出现过」：打开 / 切换聊天的第一帧 [armed] = false，
/// 那时建出来的内容直接显示并记为已出现；之后新出现的才做进场动画。
class AgentAppearScope extends InheritedWidget {
  const AgentAppearScope({
    super.key,
    required this.armed,
    required super.child,
  });
  final bool armed;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AgentAppearScope>()?.armed ??
      true;

  @override
  bool updateShouldNotify(AgentAppearScope old) => old.armed != armed;
}

/// 新出现的内容：约 0.26 秒淡入、轻轻上浮，高度从 0 展开（下面的内容顺着让位）。
/// 按 [id] 记住出现过的，重建、滚回来、切回聊天都不再动；[enabled] = false
/// 或关掉动画时直接出现。
class AgentAppear extends StatefulWidget {
  const AgentAppear({
    super.key,
    required this.id,
    required this.child,
    this.enabled = true,
    this.grow = true,
  });
  final String id;
  final Widget child;
  final bool enabled;

  /// 高度一起展开；行内小件（步骤行）只淡入上浮。
  final bool grow;

  static const duration = Duration(milliseconds: 260);
  static final _seen = <String>{};

  /// 测试用：清掉记录。
  @visibleForTesting
  static void reset() => _seen.clear();

  static bool _remember(String id) {
    if (_seen.contains(id)) return false;
    if (_seen.length > 6000) {
      final drop = _seen.take(2000).toList();
      _seen.removeAll(drop);
    }
    _seen.add(id);
    return true;
  }

  @override
  State<AgentAppear> createState() => _AgentAppearState();
}

class _AgentAppearState extends State<AgentAppear>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: AgentAppear.duration,
    value: 1,
  );
  late final _curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final fresh = AgentAppear._remember(widget.id);
    if (fresh &&
        widget.enabled &&
        AgentAppearScope.of(context) &&
        !MediaQuery.disableAnimationsOf(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (_, child) => _c.value == 1
          ? child!
          : Opacity(
              opacity: _curve.value,
              child: Transform.translate(
                offset: Offset(0, 6 * (1 - _curve.value)),
                child: child,
              ),
            ),
    );
    if (widget.grow) {
      // SizeTransition 会放松宽度约束：按外面给的宽度撑满，免得窄内容缩到中间。
      final inner = child;
      child = LayoutBuilder(
        builder: (_, box) => SizeTransition(
          sizeFactor: _curve,
          alignment: AlignmentDirectional.topStart,
          child: box.hasBoundedWidth
              ? SizedBox(width: box.maxWidth, child: inner)
              : inner,
        ),
      );
    }
    return child;
  }
}

/// 工作中提示行：呼吸的四角星 + 轮换小标语（按正在做的事换一组，偶尔冒彩蛋）
/// + 已用时间。开始 / 排队 / 等你处理这些真实状态由调用方直接显示，不走这里。
class AgentWorkingLine extends StatefulWidget {
  const AgentWorkingLine({
    super.key,
    required this.kind,
    this.since,
    this.random,
  });

  /// 正在做的事；null = 通用一组。
  final AgentActivityKind? kind;

  /// 这一轮开始的时间；null 或明显不对（超过一天）就不显示用时。
  final DateTime? since;

  /// 测试可注入。
  final math.Random? random;

  static const interval = Duration(seconds: 3);

  @override
  State<AgentWorkingLine> createState() => _AgentWorkingLineState();
}

class _AgentWorkingLineState extends State<AgentWorkingLine>
    with SingleTickerProviderStateMixin {
  late final math.Random _rng = widget.random ?? math.Random();
  late final _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  final _bags = <String, List<String>>{};
  Timer? _rotate, _tick;
  String? _text;
  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    _text ??= _next();
    if (_still) {
      _breath.stop();
      _rotate?.cancel();
      _tick?.cancel();
      _rotate = _tick = null;
    } else {
      if (!_breath.isAnimating) _breath.repeat();
      _rotate ??= Timer.periodic(AgentWorkingLine.interval, (_) {
        if (mounted) setState(() => _text = _next());
      });
      _tick ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && widget.since != null) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(covariant AgentWorkingLine old) {
    super.didUpdateWidget(old);
    // 换了一件事：马上换一句这件事的标语。
    if (old.kind != widget.kind) _text = _next();
  }

  @override
  void dispose() {
    _rotate?.cancel();
    _tick?.cancel();
    _breath.dispose();
    super.dispose();
  }

  List<String> _pool(String raw) =>
      raw.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  /// 洗牌袋：每组打乱后依次取，取完再洗；不和上一句重复。
  String _draw(String name, List<String> pool) {
    final bag = _bags.putIfAbsent(name, () => []);
    if (bag.isEmpty) {
      bag.addAll(pool..shuffle(_rng));
      if (bag.length > 1 && bag.last == _text) {
        bag.insert(0, bag.removeLast());
      }
    }
    return bag.removeLast();
  }

  String _next() {
    final l = context.l10n;
    final roll = _rng.nextDouble();
    if (roll < .05) return _draw('egg', _pool(l.ag_sloganEgg));
    final specific = switch (widget.kind) {
      AgentActivityKind.think => l.ag_sloganThink,
      AgentActivityKind.read => l.ag_sloganRead,
      AgentActivityKind.run => l.ag_sloganRun,
      AgentActivityKind.image => l.ag_sloganImage,
      AgentActivityKind.write => l.ag_sloganWrite,
      AgentActivityKind.gen => l.ag_sloganGen,
      AgentActivityKind.external => l.ag_sloganExternal,
      AgentActivityKind.ask || null => null,
    };
    if (specific != null && roll < .65) {
      return _draw(widget.kind!.name, _pool(specific));
    }
    return _draw('base', _pool(l.ag_sloganBase));
  }

  String? _elapsed() {
    final since = widget.since;
    if (since == null) return null;
    final d = DateTime.now().difference(since);
    if (d.isNegative || d.inHours >= 24) return null;
    final s = d.inSeconds;
    if (s < 60) return '${s}s';
    if (s < 3600) return '${s ~/ 60}m ${(s % 60).toString().padLeft(2, '0')}s';
    return '${s ~/ 3600}h ${(s % 3600 ~/ 60).toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final elapsed = _elapsed();
    final star = CustomPaint(
      size: const Size.square(16),
      painter: _StarPainter(c.accent),
    );
    return Row(
      key: const Key('agent-live'),
      spacing: 8,
      children: [
        SizedBox.square(
          dimension: 16,
          child: _still
              ? star
              : AnimatedBuilder(
                  animation: _breath,
                  child: star,
                  builder: (_, child) {
                    final e = .5 - .5 * math.cos(2 * math.pi * _breath.value);
                    return Opacity(
                      opacity: .75 + .25 * e,
                      child: Transform.rotate(
                        angle: .35 * e,
                        child: Transform.scale(
                          scale: .82 + .22 * e,
                          child: child,
                        ),
                      ),
                    );
                  },
                ),
        ),
        Flexible(
          child: AnimatedSwitcher(
            duration: _still
                ? Duration.zero
                : const Duration(milliseconds: 250),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.centerLeft,
              children: [...previous, ?current],
            ),
            child: AgentShimmer(
              key: ValueKey(_text),
              child: Text(
                _text ?? '',
                key: const Key('agent-live-slogan'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.sans(12.5, color: c.muted, height: 1.2),
              ),
            ),
          ),
        ),
        if (elapsed != null)
          Text(
            '· $elapsed',
            key: const Key('agent-live-elapsed'),
            style: UiText.mono(11, color: c.faint, height: 1),
          ),
      ],
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 16;
    final path = Path()
      ..moveTo(8 * s, 1.5 * s)
      ..lineTo(9.4 * s, 6.6 * s)
      ..lineTo(14.5 * s, 8 * s)
      ..lineTo(9.4 * s, 9.4 * s)
      ..lineTo(8 * s, 14.5 * s)
      ..lineTo(6.6 * s, 9.4 * s)
      ..lineTo(1.5 * s, 8 * s)
      ..lineTo(6.6 * s, 6.6 * s)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => old.color != color;
}
