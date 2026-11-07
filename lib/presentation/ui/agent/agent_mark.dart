import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../kit/app_visibility_scope.dart';
import '../kit/ui_colors.dart';

/// Static Anlas sprite for settings, tool menus and the error screen.
class AgentMark extends StatelessWidget {
  const AgentMark({super.key, this.size = 18, this.tileSize});

  final double size;
  final double? tileSize;

  @override
  Widget build(BuildContext context) => _AgentArt(
    size: tileSize ?? size,
    spriteSize: size,
    onTile: tileSize != null,
    tileScale: tileSize == null ? 0 : 1,
  );
}

enum AgentToggleBadge { none, running, waiting, done }

/// Status-only indicator in the sidebar header.
class AgentStatusMark extends StatelessWidget {
  const AgentStatusMark({super.key, this.badge = AgentToggleBadge.none});

  final AgentToggleBadge badge;

  @override
  Widget build(BuildContext context) =>
      _AgentIndicator(expanded: true, size: 26, badge: badge);
}

class AgentToggleButton extends StatelessWidget {
  const AgentToggleButton({
    super.key,
    required this.expanded,
    required this.onPressed,
    required this.tooltip,
    this.size = 28,
    this.badge = AgentToggleBadge.none,
  });

  final bool expanded;
  final VoidCallback onPressed;
  final String tooltip;
  final double size;
  final AgentToggleBadge badge;

  @override
  Widget build(BuildContext context) => _AgentIndicator(
    expanded: expanded,
    size: size,
    badge: badge,
    onPressed: onPressed,
    tooltip: tooltip,
  );
}

class _AgentIndicator extends StatefulWidget {
  const _AgentIndicator({
    required this.expanded,
    required this.size,
    required this.badge,
    this.onPressed,
    this.tooltip,
  });

  final bool expanded;
  final double size;
  final AgentToggleBadge badge;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  State<_AgentIndicator> createState() => _AgentIndicatorState();
}

class _AgentIndicatorState extends State<_AgentIndicator>
    with TickerProviderStateMixin {
  static const _clickDuration = 1070;
  static const _jump = <(int, _Pose)>[
    (0, _squash),
    (150, _stretch),
    (220, (_Sprite.stretch, 2)),
    (290, (_Sprite.happy, 3)),
    (470, (_Sprite.stretch, 2)),
    (540, _stretch),
    (610, _squash),
    (700, (_Sprite.happy, 0)),
  ];
  static const _running = [_base, _base, _squash, _base, _stretch, _stretch];
  static const _openingTile = [.25, .69, 1.12, 1.0];
  static const _closingTile = [1.0, .65, .3];

  late final _click =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: _clickDuration),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _syncMotion();
      });
  late final _tile = AnimationController(vsync: this, value: 1);
  late final _transitions = Listenable.merge([_click, _tile]);
  final _random = Random();
  ValueListenable<bool>? _visibility;
  Timer? _ambient;
  _Pose _pose = _base;
  bool _dimBadge = false;
  bool _hover = false;
  bool _pressed = false;
  bool _tickersEnabled = true;
  bool _reducedMotion = false;

  bool get _motion =>
      _tickersEnabled && !_reducedMotion && _visibility?.value != false;
  bool get _interactive => widget.onPressed != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visibility = AppVisibilityScope.maybeOf(context);
    if (_visibility != visibility) {
      _visibility?.removeListener(_syncMotion);
      _visibility = visibility;
      visibility?.addListener(_syncMotion);
    }
    _tickersEnabled = TickerMode.valuesOf(context).enabled;
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _syncMotion();
  }

  @override
  void didUpdateWidget(_AgentIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_interactive && _motion && widget.expanded != oldWidget.expanded) {
      _tile.duration = Duration(milliseconds: widget.expanded ? 180 : 140);
      _tile.forward(from: 0);
    }
    if (widget.badge != oldWidget.badge) {
      _stopAmbient();
      _syncMotion();
    }
  }

  void _stopAmbient() {
    _ambient?.cancel();
    _ambient = null;
    _pose = _base;
    _dimBadge = false;
  }

  void _syncMotion() {
    if (!_motion) {
      _stopAmbient();
      _pressed = false;
      if (_interactive) {
        _click.reset();
        _tile.value = 1;
      }
      return;
    }
    if (_ambient != null || (_interactive && _click.isAnimating)) return;
    switch (widget.badge) {
      case AgentToggleBadge.running:
        _ambient = Timer.periodic(const Duration(milliseconds: 150), (timer) {
          setState(() {
            _pose = timer.tick % 17 == 0
                ? _blink
                : _running[timer.tick % _running.length];
          });
        });
      case AgentToggleBadge.waiting:
        _ambient = Timer.periodic(const Duration(milliseconds: 500), (_) {
          setState(() => _dimBadge = !_dimBadge);
        });
      case AgentToggleBadge.none:
      case AgentToggleBadge.done:
        _ambient = Timer(
          Duration(milliseconds: 3000 + _random.nextInt(2001)),
          () {
            setState(() => _pose = _blink);
            _ambient = Timer(const Duration(milliseconds: 120), () {
              setState(_stopAmbient);
              _syncMotion();
            });
          },
        );
    }
  }

  void _tap() {
    if (_motion) {
      _stopAmbient();
      _click.forward(from: 0);
    }
    widget.onPressed!();
  }

  @override
  void dispose() {
    _visibility?.removeListener(_syncMotion);
    _ambient?.cancel();
    if (_interactive) {
      _click.dispose();
      _tile.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    if (!_interactive) return _buildMark(c);
    return Tooltip(
      message: widget.tooltip!,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = _motion),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: _tap,
          child: AnimatedBuilder(
            animation: _transitions,
            builder: (_, _) => _buildMark(c),
          ),
        ),
      ),
    );
  }

  Widget _buildMark(UiColors c) {
    final expanded = widget.expanded;
    final tiling = _interactive && _tile.isAnimating;
    final scales = expanded ? _openingTile : _closingTile;
    final tileScale = tiling
        ? scales[min(scales.length - 1, (_tile.value * scales.length).floor())]
        : expanded || _hover
        ? 1.0
        : 0.0;
    final elapsed = _interactive && _click.isAnimating
        ? (_click.value * _clickDuration).floor()
        : _clickDuration;
    final pose = elapsed < _clickDuration
        ? _jump.lastWhere((step) => elapsed >= step.$1).$2
        : _pose;
    final badge = switch (widget.badge) {
      AgentToggleBadge.running => _motion ? null : c.accent,
      AgentToggleBadge.waiting => c.warn.withValues(alpha: _dimBadge ? .25 : 1),
      AgentToggleBadge.done => c.ok,
      AgentToggleBadge.none => null,
    };
    final extent = widget.size + 24;
    return SizedBox.square(
      key: _interactive ? const Key('agent-toggle') : null,
      dimension: widget.size,
      child: OverflowBox(
        minWidth: extent,
        maxWidth: extent,
        minHeight: extent,
        maxHeight: extent,
        child: RepaintBoundary(
          child: _AgentArt(
            size: widget.size,
            onTile: expanded,
            solidTile: expanded || tiling,
            tileScale: tileScale,
            pose: pose,
            pressed: _pressed,
            badge: badge,
            burst: elapsed < 240 ? elapsed ~/ 80 : null,
            splash: elapsed >= 610 && elapsed < 970
                ? (elapsed - 610) ~/ 60
                : null,
          ),
        ),
      ),
    );
  }
}

enum _Sprite {
  base([
    '....#....',
    '...+#=...',
    '..+###=..',
    '.+#####=.',
    '#+######=',
    '##wo#wo#=',
    '##oo#oo#=',
    '=#######=',
    '.=======.',
  ]),
  blink([
    '....#....',
    '...+#=...',
    '..+###=..',
    '.+#####=.',
    '#+######=',
    '#+######=',
    '##oo#oo#=',
    '=#######=',
    '.=======.',
  ]),
  happy([
    '....#....',
    '...+#=...',
    '..+###=..',
    '.+#####=.',
    '#+######=',
    '##o###o#=',
    '#o#o#o#o=',
    '=#######=',
    '.=======.',
  ]),
  squash([
    '.........',
    '.........',
    '....#....',
    '..+###=..',
    '#+######=',
    '##wo#wo#=',
    '##oo#oo#=',
    '#########',
    '=========',
  ]),
  stretch([
    '....#....',
    '....#....',
    '...+#=...',
    '..+###=..',
    '..+###=..',
    '..wo#wo..',
    '..oo#oo..',
    '..=###=..',
    '...===...',
  ]);

  const _Sprite(this.pixels);
  final List<String> pixels;
}

typedef _Pose = (_Sprite, int rise);
const _base = (_Sprite.base, 0);
const _blink = (_Sprite.blink, 0);
const _squash = (_Sprite.squash, 0);
const _stretch = (_Sprite.stretch, 1);

class _AgentArt extends StatelessWidget {
  const _AgentArt({
    required this.size,
    required this.onTile,
    required this.tileScale,
    this.spriteSize = 18,
    this.solidTile = true,
    this.pose = _base,
    this.pressed = false,
    this.badge,
    this.burst,
    this.splash,
  });

  final double size;
  final bool onTile;
  final double tileScale;
  final double spriteSize;
  final bool solidTile;
  final _Pose pose;
  final bool pressed;
  final Color? badge;
  final int? burst;
  final int? splash;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _AgentPainter(
      art: this,
      colors: context.ui,
      dpr: MediaQuery.devicePixelRatioOf(context),
      // A retained layer may have a different origin than the screen.
      screenOrigin: () =>
          (context.findRenderObject()! as RenderBox).localToGlobal(Offset.zero),
    ),
  );
}

class _AgentPainter extends CustomPainter {
  const _AgentPainter({
    required this.art,
    required this.colors,
    required this.dpr,
    required this.screenOrigin,
  });

  final _AgentArt art;
  final UiColors colors;
  final double dpr;
  final Offset Function() screenOrigin;

  double _pixels(double value) => (value * dpr).round() / dpr;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = screenOrigin();
    Offset snap(Offset point) => Offset(
      _pixels(origin.dx + point.dx) - origin.dx,
      _pixels(origin.dy + point.dy) - origin.dy,
    );

    final center = size.center(Offset.zero);
    final paint = Paint()..isAntiAlias = false;
    final palette = colors.agentPixels(onTile: art.onTile);
    if (art.tileScale > 0) {
      final edge = art.size * art.tileScale;
      final start = snap(center - Offset(edge / 2, edge / 2));
      final rect = start & Size.square(_pixels(edge));
      _paintTile(canvas, paint, rect);
    }

    final cell = _pixels(art.spriteSize / 9);
    final topLeft = snap(
      center -
          Offset(cell * 4.5, cell * (4.5 + art.pose.$2)) +
          Offset(0, art.pressed ? 1 : 0),
    );
    final pixels = art.pose.$1.pixels;
    for (var y = 0; y < 9; y++) {
      for (var x = 0; x < 9; x++) {
        final color = switch (pixels[y][x]) {
          '#' => palette.body,
          '+' => palette.highlight,
          '=' => palette.shadow,
          'o' => palette.eyes,
          'w' => colors.onBrand,
          _ => null,
        };
        if (color == null) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            topLeft.dx + x * cell,
            topLeft.dy + y * cell,
            cell,
            cell,
          ),
          paint..color = color,
        );
      }
    }

    if (art.burst case final step?) {
      const distance = [11.0, 16.0, 20.0];
      const opacity = [1.0, .8, .4];
      final edge = _pixels(3);
      for (final direction in _burstDirections) {
        final start = snap(
          center + direction * distance[step] - Offset(edge / 2, edge / 2),
        );
        canvas.drawRect(
          start & Size.square(edge),
          paint..color = colors.accent.withValues(alpha: opacity[step]),
        );
      }
    }
    if (art.splash case final step?) {
      _paintSplash(
        canvas,
        paint,
        topLeft + Offset(0, art.pose.$2 * cell),
        cell,
        step,
        palette.highlight,
      );
    }
    if (art.badge case final color?) {
      final edge = _pixels(6);
      final border = _pixels(2);
      final corner = center + Offset(art.size / 2, -art.size / 2);
      final inner = snap(corner + Offset(2 - edge, -2));
      final rect = inner & Size.square(edge);
      canvas.drawRect(rect.inflate(border), paint..color = colors.bg);
      canvas.drawRect(rect, paint..color = color);
    }
  }

  static const _burstDirections = [
    Offset(1, 0),
    Offset(-1, 0),
    Offset(0, 1),
    Offset(0, -1),
    Offset(.7, .7),
    Offset(-.7, -.7),
    Offset(.7, -.7),
    Offset(-.7, .7),
  ];

  void _paintTile(Canvas canvas, Paint paint, Rect r) {
    final cut = _pixels(2);
    final path = Path()
      ..addPolygon([
        Offset(r.left + cut, r.top),
        Offset(r.right - cut, r.top),
        Offset(r.right - cut, r.top + cut),
        Offset(r.right, r.top + cut),
        Offset(r.right, r.bottom - cut),
        Offset(r.right - cut, r.bottom - cut),
        Offset(r.right - cut, r.bottom),
        Offset(r.left + cut, r.bottom),
        Offset(r.left + cut, r.bottom - cut),
        Offset(r.left, r.bottom - cut),
        Offset(r.left, r.top + cut),
        Offset(r.left + cut, r.top + cut),
      ], true);
    canvas.save();
    canvas.clipPath(path, doAntiAlias: false);
    canvas.drawRect(
      r,
      paint
        ..color = art.solidTile
            ? colors.agentTile
            : colors.accent.withValues(alpha: .13),
    );
    if (art.solidTile) {
      final highlight = paint..color = colors.onBrand.withValues(alpha: .3);
      canvas.drawRect(Rect.fromLTWH(r.left, r.top, r.width, cut), highlight);
      canvas.drawRect(
        Rect.fromLTWH(r.left, r.top + cut, cut, r.height - cut * 2),
        highlight,
      );
      final shadow = paint..color = colors.agentTileBevel;
      canvas.drawRect(
        Rect.fromLTWH(r.left, r.bottom - cut, r.width, cut),
        shadow,
      );
      canvas.drawRect(
        Rect.fromLTWH(r.right - cut, r.top + cut, cut, r.height - cut * 2),
        shadow,
      );
    }
    canvas.restore();
  }

  void _paintSplash(
    Canvas canvas,
    Paint paint,
    Offset origin,
    double cell,
    int step,
    Color color,
  ) {
    const outer = [(0, 0), (1, -1), (2, -1), (3, 0), (3, 1), (3, 2)];
    const inner = [(0, 0), (1, 0), (2, -1), (2, 0), (2, 1)];
    void pair(List<(int, int)> path, int x, int y) {
      if (step >= path.length - 1) return;
      final (dx, dy) = path[step];
      paint.color = color.withValues(alpha: step == path.length - 2 ? .5 : 1);
      for (final column in [x - dx, 8 - x + dx]) {
        canvas.drawRect(
          Rect.fromLTWH(
            origin.dx + column * cell,
            origin.dy + (y + dy) * cell,
            cell,
            cell,
          ),
          paint,
        );
      }
    }

    pair(outer, 0, 7);
    pair(inner, 1, 8);
  }

  @override
  bool shouldRepaint(_AgentPainter old) =>
      dpr != old.dpr ||
      colors.dark != old.colors.dark ||
      colors.accent != old.colors.accent ||
      colors.bg != old.colors.bg ||
      (
            art.spriteSize,
            art.size,
            art.pose,
            art.onTile,
            art.tileScale,
            art.solidTile,
            art.pressed,
            art.badge,
            art.burst,
            art.splash,
          ) !=
          (
            old.art.spriteSize,
            old.art.size,
            old.art.pose,
            old.art.onTile,
            old.art.tileScale,
            old.art.solidTile,
            old.art.pressed,
            old.art.badge,
            old.art.burst,
            old.art.splash,
          );
}
