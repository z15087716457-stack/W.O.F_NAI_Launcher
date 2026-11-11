import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../kit/app_visibility_scope.dart';
import '../kit/ui_colors.dart';

/// Source of the idle animation's variety; tests replace it with a seeded one.
@visibleForTesting
Random agentMarkRandom = Random();

/// Idle time after which the indicator dozes off until hovered or tapped.
@visibleForTesting
const agentMarkDozeAfter = Duration(minutes: 2);

/// Sprite rows indexed by pose name for shape and expression regression checks.
@visibleForTesting
Map<String, List<String>> get agentMarkFrames => {
  'base': _F.base.rows,
  'squash': _F.squash.rows,
  'stretch': _F.stretch.rows,
  'breathe': _F.breathe.rows,
  'melt': _F.melt.rows,
  'melt2': _F.melt2.rows,
  'blink': _F.blink.rows,
  'happy': _F.happy.rows,
  'lookL': _F.lookL.rows,
  'lookR': _F.lookR.rows,
  'lookU': _F.lookU.rows,
  'ouch': _F.ouch.rows,
  'talkA': _F.talkA.rows,
  'talkB': _F.talkB.rows,
  'squashBlink': _F.squashBlink.rows,
  'breatheBlink': _F.breatheBlink.rows,
  'breatheL': _F.breatheL.rows,
  'breatheR': _F.breatheR.rows,
  'breatheU': _F.breatheU.rows,
  'breatheOuch': _F.breatheOuch.rows,
};

/// Static Anlas sprite for settings, tool menus and the error screen.
class AgentMark extends StatelessWidget {
  const AgentMark({super.key, this.size = 18, this.tileSize});

  final double size;
  final double? tileSize;

  @override
  Widget build(BuildContext context) => _AgentArt(
    size: tileSize ?? size,
    spriteSize: size,
    scene: _Scene(
      pose: _F.base,
      onTile: tileSize != null,
      tile: tileSize == null ? _Tile.none : _Tile.solid,
    ),
  );
}

/// What the Agent is doing. When several chats are active, the wiring reports
/// the highest-priority one: [question], [approval], [runLimit], [error],
/// [generating], [compacting], [tool], [writing], [thinking], [starting],
/// [done], then [none].
enum AgentToggleBadge {
  /// Idle: nothing running and no unseen outcome.
  none,

  /// A chat is starting its host or queued for a request slot.
  starting,

  /// Running with reasoning streaming, or waiting for the first output.
  thinking,

  /// Streaming visible reply text.
  writing,

  /// Executing a tool other than image generation.
  tool,

  /// Executing an image-generation tool (spends Anlas).
  generating,

  /// Compacting the conversation context.
  compacting,

  /// A run finished normally and the user has not looked at it yet.
  done,

  /// A run ended with an error or interruption the user has not looked at.
  error,

  /// A run stopped at the per-run request limit and awaits a decision.
  runLimit,

  /// The Agent asked the user a question.
  question,

  /// A generation or image-use approval is pending.
  approval;

  bool get isRunning => switch (this) {
    starting || thinking || writing || tool || generating || compacting => true,
    _ => false,
  };

  bool get isWaiting =>
      this == question || this == approval || this == runLimit;
}

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

enum _Gaze { left, right, center }

class _AgentIndicatorState extends State<_AgentIndicator> {
  ValueListenable<bool>? _visibility;
  bool _tickersEnabled = true;
  bool _reducedMotion = false;
  bool _hover = false;
  bool _pressed = false;
  _Gaze? _gaze;

  // Logical time advanced only by our own timers, so fake-async tests and a
  // hidden window (which stops the timers) both see consistent durations.
  int _clock = 0;
  int _stepEnd = 0;
  int _idleSince = 0;
  bool _dozing = false;
  Timer? _timer;
  Iterator<_Step> _steps = const <_Step>[].iterator;
  _Step _step = _Step(_F.base, 0);
  final _particles = <_Particle>[];
  int? _burstAt;

  bool get _motion =>
      _tickersEnabled && !_reducedMotion && _visibility?.value != false;
  bool get _interactive => widget.onPressed != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visibility = AppVisibilityScope.maybeOf(context);
    if (_visibility != visibility) {
      _visibility?.removeListener(_onVisibility);
      _visibility = visibility;
      visibility?.addListener(_onVisibility);
    }
    _tickersEnabled = TickerMode.valuesOf(context).enabled;
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(_AgentIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.badge == oldWidget.badge) return;
    _dozing = false;
    _idleSince = _clock;
    if (!_motion) return;
    _particles.clear();
    _play(_Seq.enter(widget.badge) ?? _loop());
  }

  void _onVisibility() {
    if (mounted) setState(_sync);
  }

  void _sync() {
    if (!_motion) {
      _stop();
      _pressed = false;
      _dozing = false;
      return;
    }
    if (_timer == null) _play(_loop());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _particles.clear();
    _burstAt = null;
  }

  List<_Step> _loop() {
    final badge = widget.badge;
    if (badge != AgentToggleBadge.none && badge != AgentToggleBadge.done) {
      return _Seq.loop(badge);
    }
    if (_dozing) return _Seq.doze;
    if (badge == AgentToggleBadge.none &&
        _clock - _idleSince >= agentMarkDozeAfter.inMilliseconds) {
      _dozing = true;
      return _Seq.dozeOff;
    }
    return _Seq.idle(agentMarkRandom);
  }

  void _play(List<_Step> steps) {
    _timer?.cancel();
    _timer = null;
    _steps = steps.iterator;
    _advance();
    _schedule();
  }

  void _advance() {
    while (!_steps.moveNext()) {
      _steps = _loop().iterator;
    }
    _step = _steps.current;
    _stepEnd = _clock + _step.ms;
    _step.fx?.call(this);
  }

  void _schedule() {
    var next = _stepEnd;
    for (final particle in _particles) {
      next = min(next, particle.nextBoundary(_clock));
    }
    if (_burstAt case final start?) {
      next = min(next, start + ((_clock - start) ~/ 80 + 1) * 80);
    }
    _timer = Timer(Duration(milliseconds: max(1, next - _clock)), () {
      _timer = null;
      if (!mounted || !_motion) return;
      setState(() {
        _clock = next;
        _particles.removeWhere((particle) => particle.done(_clock));
        if (_burstAt case final start? when _clock - start >= 240) {
          _burstAt = null;
        }
        if (_clock >= _stepEnd) _advance();
      });
      _schedule();
    });
  }

  void _spawn(
    List<(int, int, _Ink)> pixels,
    List<(int, int, double)> path,
    int stepMs, {
    int delay = 0,
  }) => _particles.add(_Particle(pixels, path, stepMs, _clock + delay));

  void _wake() {
    _idleSince = _clock;
    if (!_dozing) return;
    _dozing = false;
    if (_motion) _play(_loop());
  }

  void _look(Offset local) {
    final dx = (local.dx - widget.size / 2) / widget.size;
    final gaze = dx < -.18
        ? _Gaze.left
        : dx > .18
        ? _Gaze.right
        : _Gaze.center;
    if (gaze != _gaze) setState(() => _gaze = gaze);
  }

  void _tap() {
    if (_motion) {
      setState(() {
        _wake();
        _particles.clear();
        _burstAt = _clock;
        _play(_Seq.jump());
      });
    }
    widget.onPressed!();
  }

  @override
  void dispose() {
    _visibility?.removeListener(_onVisibility);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final mark = _buildMark(c);
    if (!_interactive) return mark;
    return Tooltip(
      message: widget.tooltip!,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (event) => setState(() {
          _hover = true;
          _wake();
          _look(event.localPosition);
        }),
        onHover: (event) => _look(event.localPosition),
        onExit: (_) => setState(() {
          _hover = false;
          _gaze = null;
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = _motion),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: _tap,
          child: mark,
        ),
      ),
    );
  }

  Widget _buildMark(UiColors c) {
    final badge = widget.badge;
    final step = _motion ? _step : _Seq.still(badge);
    final pose = _motion && step.rest && _gaze != null
        ? switch (_gaze!) {
            _Gaze.left => _F.lookL,
            _Gaze.right => _F.lookR,
            _Gaze.center => _F.happy,
          }
        : step.pose;
    final cells = [
      ...step.symbols,
      for (final particle in _particles) ...particle.cellsAt(_clock),
    ];
    final badgeColor = switch (badge) {
      AgentToggleBadge.none => null,
      AgentToggleBadge.done => c.ok,
      AgentToggleBadge.error => c.error,
      AgentToggleBadge.runLimit => c.warn,
      _ when _motion => null,
      final b when b.isWaiting => c.warn,
      _ => c.accent,
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
            scene: _Scene(
              pose: pose,
              onTile: widget.expanded,
              outline: widget.expanded,
              tile: _interactive && _hover ? _Tile.hover : _Tile.none,
              pressed: _pressed,
              cells: cells,
              burst: _burstAt == null ? null : (_clock - _burstAt!) ~/ 80,
              badge: badgeColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// A frame centered on the 9x9 grid, moved by cells (negative [dy] is up).
typedef _Pose = ({List<String> rows, int dx, int dy});

/// A loose pixel drawn relative to the unmoved sprite origin, in cells.
typedef _Cell = (int x, int y, _Ink ink, double opacity);

enum _Ink { accent, warn, faint, star, water }

/// Sprite frames. `#` body, `+` highlight, `=` shadow, `o` eyes, `w` eye
/// shine. Rows are 9 or 11 cells wide, with wide rows extending one cell past
/// each side of the grid. Every outline widens at most one cell per side per
/// row, otherwise the silhouette grows square shoulders. Wide sides span
/// adjacent rows so compression spreads the body instead of sprouting hands.
abstract final class _F {
  static const _base = [
    '....#....',
    '...+#=...',
    '..+###=..',
    '.+#####=.',
    '#+######=',
    '##wo#wo#=',
    '##oo#oo#=',
    '=#######=',
    '.=======.',
  ];
  static const _squash = [
    '...........',
    '...........',
    '....+#=....',
    '...+###=...',
    '..+#####=..',
    '.+#######=.',
    '+##wo#wo##=',
    '###oo#oo##=',
    '.=========.',
  ];
  static const _stretch = [
    '....#....',
    '....#....',
    '...+#=...',
    '..+###=..',
    '..+###=..',
    '..wo#wo..',
    '..oo#oo..',
    '..=###=..',
    '...===...',
  ];
  static const _breathe = [
    '...........',
    '.....#.....',
    '....+#=....',
    '...+###=...',
    '..+#####=..',
    '.+#wo#wo#=.',
    '###oo#oo##=',
    '=#########=',
    '.=========.',
  ];
  static const _melt = [
    '...........',
    '...........',
    '...........',
    '...........',
    '...........',
    '..+#####=..',
    '.+#oo#oo#=.',
    '+#########=',
    '===========',
  ];
  static const _melt2 = [
    '...........',
    '...........',
    '...........',
    '...........',
    '...+###=...',
    '..+#####=..',
    '.+#oo#oo#=.',
    '+#########=',
    '===========',
  ];

  static const _blink = {5: '#+######=', 6: '##oo#oo#='};
  static const _happy = {5: '##o###o#=', 6: '#o#o#o#o='};
  static const _lookL = {5: '#wo#wo##=', 6: '#oo#oo##='};
  static const _lookR = {5: '###wo#wo=', 6: '###oo#oo='};
  static const _lookU = {4: '#+wo#wo#=', 5: '##oo#oo#=', 6: '########='};
  static const _ouch = {4: '#+o###o#=', 5: '###o#o##=', 6: '##o###o#='};

  static _Pose _p(List<String> rows) => (rows: rows, dx: 0, dy: 0);
  static _Pose _face(
    Map<int, String> eyes, [
    List<String> body = _base,
    int rowOffset = 0,
  ]) {
    const eyePixels = {'o', 'w'};
    final rows = [...body];
    for (final entry in eyes.entries) {
      final y = entry.key + rowOffset;
      final pixels = body[y].split('');
      final inset = (pixels.length - 9) ~/ 2;
      for (var x = 0; x < 9; x++) {
        if (pixels[x + inset] != '.' &&
            (eyePixels.contains(entry.value[x]) ||
                eyePixels.contains(_base[entry.key][x]))) {
          pixels[x + inset] = entry.value[x];
        }
      }
      rows[y] = pixels.join();
    }
    return _p(rows);
  }

  static final base = _p(_base);
  static final squash = _p(_squash);
  static final stretch = _p(_stretch);
  static final breathe = _p(_breathe);
  static final melt = _p(_melt);
  static final melt2 = _p(_melt2);
  // The original blink adds a shoulder highlight as well as closing its eyes.
  static final blink = _p(_face(_blink).rows..[5] = _blink[5]!);
  static final happy = _face(_happy);
  static final lookL = _face(_lookL);
  static final lookR = _face(_lookR);
  static final lookU = _face(_lookU);
  static final ouch = _face(_ouch);
  static final talkA = _face({7: '=###o###='});
  static final talkB = _face({7: '=##ooo##='});
  static final squashBlink = _face(_blink, _squash, 1);
  static final breatheBlink = _face(_blink, _breathe);
  static final breatheL = _face(_lookL, _breathe);
  static final breatheR = _face(_lookR, _breathe);
  static final breatheU = _face(_lookU, _breathe);
  static final breatheOuch = _face(_ouch, _breathe);
}

extension on _Pose {
  _Pose at({int dx = 0, int dy = 0}) => (rows: rows, dx: dx, dy: dy);
}

/// Status symbols live in the empty space above and right of the head.
abstract final class _Glyph {
  static const question = [(6, -3), (7, -3), (8, -3), (8, -2), (7, -1), (7, 1)];
  static const exclaim = [(7, -3), (7, -2), (7, -1), (7, 1)];
  static const gearA = [(7, -2), (6, -1), (7, -1), (8, -1), (7, 0)];
  static const gearB = [(6, -2), (8, -2), (7, -1), (6, 0), (8, 0)];
  static const dots = [(2, -2), (4, -2), (6, -2)];
  static const z = [(0, 0), (1, 0), (2, 0), (1, 1), (0, 2), (1, 2), (2, 2)];
  static const gem = [(1, 0), (0, 1), (1, 1), (2, 1), (1, 2)];

  static List<_Cell> of(
    List<(int, int)> cells,
    _Ink ink, {
    int dx = 0,
    int dy = 0,
    double opacity = 1,
  }) => [for (final (x, y) in cells) (x + dx, y + dy, ink, opacity)];
}

class _Step {
  const _Step(
    this.pose,
    this.ms, {
    this.symbols = const [],
    this.fx,
    this.rest = false,
  });

  final _Pose pose;
  final int ms;
  final List<_Cell> symbols;
  final void Function(_AgentIndicatorState state)? fx;

  /// Resting frames may be replaced by eyes that follow the pointer.
  final bool rest;
}

class _Particle {
  _Particle(this.pixels, this.path, this.stepMs, this.start);

  final List<(int, int, _Ink)> pixels;
  final List<(int, int, double)> path;
  final int stepMs;
  final int start;

  int get _end => start + path.length * stepMs;
  bool done(int now) => now >= _end;
  int nextBoundary(int now) =>
      now < start ? start : start + ((now - start) ~/ stepMs + 1) * stepMs;

  Iterable<_Cell> cellsAt(int now) sync* {
    if (now < start || now >= _end) return;
    final (dx, dy, opacity) = path[(now - start) ~/ stepMs];
    if (opacity <= 0) return;
    for (final (x, y, ink) in pixels) {
      yield (x + dx, y + dy, ink, opacity);
    }
  }
}

abstract final class _Seq {
  static int _range(Random random, int low, int high) =>
      low + random.nextInt(high - low + 1);

  static void _splash(_AgentIndicatorState s) {
    const step = 60;
    s._spawn(
      [(0, 7, _Ink.water)],
      [(0, 0, 1), (-1, -1, 1), (-2, -1, 1), (-3, 0, 1), (-3, 1, .5)],
      step,
    );
    s._spawn(
      [(8, 7, _Ink.water)],
      [(0, 0, 1), (1, -1, 1), (2, -1, 1), (3, 0, 1), (3, 1, .5)],
      step,
    );
    s._spawn(
      [(1, 8, _Ink.water)],
      [(0, 0, 1), (-1, 0, 1), (-2, -1, 1), (-2, 0, .5)],
      step,
    );
    s._spawn(
      [(7, 8, _Ink.water)],
      [(0, 0, 1), (1, 0, 1), (2, -1, 1), (2, 0, .5)],
      step,
    );
  }

  static void _shakeOff(_AgentIndicatorState s) {
    s._spawn([(0, 6, _Ink.water)], [(0, 0, 1), (-1, -1, 1), (-2, 0, .5)], 70);
    s._spawn([(8, 6, _Ink.water)], [(0, 0, 1), (1, -1, 1), (2, 0, .5)], 70);
  }

  static void _sweat(_AgentIndicatorState s) => s._spawn(
    [(-1, 1, _Ink.water)],
    [(0, 0, 1), (0, 0, 1), (0, 1, 1), (0, 2, .6)],
    170,
  );

  static void _snore(_AgentIndicatorState s) => s._spawn(
    [for (final (x, y) in _Glyph.z) (x + 6, y - 1, _Ink.faint)],
    [(0, 0, .9), (0, 0, 1), (0, -1, 1), (0, -1, .6), (0, -2, .3)],
    240,
  );

  static void _sparkles(_AgentIndicatorState s) {
    for (final (x, y, delay) in [(-2, 1, 0), (10, 2, 90), (1, -2, 170)]) {
      s._spawn(
        [(x, y, _Ink.star)],
        [(0, 0, 1), (0, 0, 1), (0, 0, 1), (0, 0, .5)],
        70,
        delay: delay,
      );
      s._spawn(
        [
          (x - 1, y, _Ink.star),
          (x + 1, y, _Ink.star),
          (x, y - 1, _Ink.star),
          (x, y + 1, _Ink.star),
        ],
        [(0, 0, 0), (0, 0, 1), (0, 0, 1)],
        70,
        delay: delay,
      );
    }
    s._spawn(
      [(9, -2, _Ink.star)],
      [(0, 0, 1), (0, 0, 1), (0, 0, .5)],
      70,
      delay: 240,
    );
  }

  static List<_Step> jump({bool celebrate = false}) => [
    _Step(_F.squash, 90),
    _Step(_F.squash, 60),
    _Step(_F.stretch.at(dy: -1), 70),
    _Step(_F.stretch.at(dy: -2), 70),
    _Step(_F.happy.at(dy: -3), 70, fx: celebrate ? _sparkles : null),
    _Step(_F.happy.at(dy: -3), 110),
    _Step(_F.stretch.at(dy: -2), 70),
    _Step(_F.stretch.at(dy: -1), 70),
    _Step(_F.squash, 90, fx: _splash),
    _Step(_F.happy, 70),
    _Step(_F.happy, 300),
  ];

  static List<_Step> _hop(
    List<_Cell> Function(int dy) symbols, {
    _Pose? face,
  }) => [
    _Step(_F.squash, 80, symbols: symbols(0)),
    _Step(_F.stretch.at(dy: -1), 70, symbols: symbols(-1)),
    _Step((face ?? _F.base).at(dy: -1), 120, symbols: symbols(-1)),
    _Step(_F.stretch.at(dy: -1), 60, symbols: symbols(-1)),
    _Step(_F.squash, 80, symbols: symbols(0)),
    _Step(face ?? _F.base, 70, symbols: symbols(0)),
  ];

  static List<_Cell> _none(int _) => const [];
  static List<_Cell> _question(int dy) =>
      _Glyph.of(_Glyph.question, _Ink.warn, dy: dy);
  static List<_Cell> _exclaim(int dy, [double opacity = 1]) =>
      _Glyph.of(_Glyph.exclaim, _Ink.warn, dy: dy, opacity: opacity);
  static List<_Cell> _dots(int count, [double opacity = 1]) => _Glyph.of(
    _Glyph.dots.take(count).toList(),
    _Ink.accent,
    opacity: opacity,
  );
  static List<_Cell> _gem(int x, int y, [double opacity = 1]) =>
      _Glyph.of(_Glyph.gem, _Ink.accent, dx: x, dy: y, opacity: opacity);

  static List<_Step> idle(Random random) {
    final roll = random.nextDouble();
    return [
      _Step(_F.base, _range(random, 2200, 3000), rest: true),
      _Step(_F.breathe, 240),
      _Step(_F.base, _range(random, 1600, 2600), rest: true),
      if (roll < .3)
        _Step(_F.blink, 120)
      else if (roll < .42) ...[
        _Step(_F.lookL, 420),
        _Step(_F.base, 140),
        _Step(_F.lookR, 420),
        _Step(_F.base, 100),
      ] else if (roll < .52)
        ..._hop(_none, face: _F.happy)
      else if (roll < .6) ...[
        _Step(_F.blink.at(dx: -1), 70),
        _Step(_F.blink.at(dx: 1), 70),
        _Step(_F.blink.at(dx: -1), 70),
        _Step(_F.blink.at(dx: 1), 70, fx: _shakeOff),
        _Step(_F.happy, 260),
      ],
    ];
  }

  static final dozeOff = [
    _Step(_F.blink, 500),
    _Step(_F.base, 200),
    _Step(_F.blink, 600),
    _Step(_F.breatheBlink, 500),
  ];

  static final doze = [
    _Step(_F.blink, 1000, fx: _snore),
    _Step(_F.breatheBlink, 1000),
  ];

  /// A one-off reaction played when the state changes, before its loop.
  static List<_Step>? enter(AgentToggleBadge badge) => switch (badge) {
    AgentToggleBadge.done => [...jump(celebrate: true), _Step(_F.happy, 500)],
    AgentToggleBadge.error => [
      _Step(_F.ouch.at(dx: -1), 70),
      _Step(_F.ouch.at(dx: 1), 70),
      _Step(_F.ouch.at(dx: -1), 70),
      _Step(_F.ouch.at(dx: 1), 70),
      _Step(_F.ouch, 200),
    ],
    AgentToggleBadge.runLimit => [
      _Step(_F.blink, 220),
      _Step(_F.breatheBlink, 180),
      _Step(_F.squashBlink, 220),
      _Step(_F.melt, 300),
    ],
    AgentToggleBadge.question => _hop(_question),
    AgentToggleBadge.approval => _hop(_exclaim),
    _ => null,
  };

  static List<_Step> loop(AgentToggleBadge badge) {
    final random = agentMarkRandom;
    return switch (badge) {
      AgentToggleBadge.starting => [
        _Step(_F.lookL, 320),
        _Step(_F.breatheL, 320),
        _Step(_F.lookL, 320),
        _Step(_F.base, 220),
        _Step(_F.lookR, 320),
        _Step(_F.breatheR, 320),
        _Step(_F.lookR, 320),
        if (random.nextDouble() < .4) _Step(_F.blink, 120),
        _Step(_F.base, 220),
      ],
      AgentToggleBadge.thinking => [
        _Step(_F.lookU, 280),
        _Step(_F.lookU, 280, symbols: _dots(1)),
        _Step(_F.lookU, 280, symbols: _dots(2)),
        _Step(_F.lookU, 460, symbols: _dots(3)),
        _Step(_F.breatheU, 280, symbols: _dots(3, .35)),
        if (random.nextDouble() < .3) _Step(_F.blink, 120),
      ],
      AgentToggleBadge.writing => [
        for (var i = _range(random, 6, 10); i > 0; i--)
          _Step(
            [_F.talkA, _F.talkB, _F.talkB, _F.base][random.nextInt(4)],
            _range(random, 90, 140),
          ),
        _Step(_F.base, _range(random, 220, 420)),
        if (random.nextDouble() < .25) _Step(_F.blink, 110),
      ],
      AgentToggleBadge.tool => () {
        final a = _Glyph.of(_Glyph.gearA, _Ink.accent);
        final b = _Glyph.of(_Glyph.gearB, _Ink.accent);
        return [
          _Step(_F.lookR, 160, symbols: a),
          _Step(_F.breatheR, 160, symbols: b),
          _Step(_F.lookR, 160, symbols: a),
          _Step(_F.lookR, 160, symbols: b),
          if (random.nextDouble() < .2) _Step(_F.blink, 120, symbols: a),
        ];
      }(),
      AgentToggleBadge.generating => [
        _Step(_F.base, 520),
        _Step(_F.squash, 110),
        _Step(_F.squash, 90, symbols: _gem(3, -1)),
        _Step(_F.stretch.at(dy: -1), 90, symbols: _gem(5, -3)),
        _Step(_F.happy, 340, symbols: _gem(6, -2)),
        _Step(_F.happy, 140, symbols: _gem(6, -2, .45)),
        _Step(_F.base, 240),
      ],
      AgentToggleBadge.compacting => [
        _Step(_F.base, 620),
        _Step(_F.squash, 110),
        _Step(_F.squashBlink, 340, fx: _splash),
        _Step(_F.stretch.at(dy: -1), 80),
        _Step(_F.base, 80),
        _Step(_F.breathe, 90),
        _Step(_F.base, 260),
      ],
      AgentToggleBadge.question => [
        _Step(_F.base, 900, symbols: _question(0)),
        _Step(_F.blink, 110, symbols: _question(0)),
        _Step(_F.base, 600, symbols: _question(0)),
        ..._hop(_question),
        ..._hop(_question),
        _Step(_F.base, 300, symbols: _question(0)),
      ],
      AgentToggleBadge.approval => [
        _Step(_F.base, 380, symbols: _exclaim(0)),
        _Step(_F.base.at(dx: -1), 190, symbols: _exclaim(0, .25)),
        _Step(_F.base, 190, symbols: _exclaim(0, .25)),
        _Step(_F.base, 380, symbols: _exclaim(0)),
        _Step(_F.base.at(dx: 1), 190, symbols: _exclaim(0, .25)),
        _Step(_F.base, 190, symbols: _exclaim(0, .25)),
        ..._hop(_exclaim),
        _Step(_F.blink, 110, symbols: _exclaim(0)),
      ],
      AgentToggleBadge.runLimit => [_Step(_F.melt, 1300), _Step(_F.melt2, 700)],
      AgentToggleBadge.error => [
        _Step(_F.ouch, 1500, fx: _sweat),
        _Step(_F.breatheOuch, 260),
        _Step(_F.ouch, 900),
      ],
      AgentToggleBadge.none || AgentToggleBadge.done => idle(random),
    };
  }

  /// One representative frame per state for reduced motion or hidden windows.
  static _Step still(AgentToggleBadge badge) => switch (badge) {
    AgentToggleBadge.none => _Step(_F.base, 0),
    AgentToggleBadge.starting => _Step(_F.lookR, 0),
    AgentToggleBadge.thinking => _Step(_F.lookU, 0, symbols: _dots(3)),
    AgentToggleBadge.writing => _Step(_F.talkB, 0),
    AgentToggleBadge.tool => _Step(_F.lookR, 0),
    AgentToggleBadge.generating => _Step(_F.happy, 0),
    AgentToggleBadge.compacting => _Step(_F.squashBlink, 0),
    AgentToggleBadge.done => _Step(_F.happy, 0),
    AgentToggleBadge.error => _Step(_F.ouch, 0),
    AgentToggleBadge.runLimit => _Step(_F.melt, 0),
    AgentToggleBadge.question => _Step(_F.lookU, 0),
    AgentToggleBadge.approval => _Step(_F.happy, 0),
  };
}

enum _Tile { none, hover, solid }

@immutable
class _Scene {
  const _Scene({
    required this.pose,
    this.onTile = false,
    this.outline = false,
    this.tile = _Tile.none,
    this.pressed = false,
    this.cells = const [],
    this.burst,
    this.badge,
  });

  final _Pose pose;

  /// Uses the light-on-brand palette (expanded toggle and solid tiles).
  final bool onTile;

  /// Rings the sprite in brand blue so a light body reads on any background.
  final bool outline;
  final _Tile tile;
  final bool pressed;
  final List<_Cell> cells;
  final int? burst;
  final Color? badge;

  @override
  bool operator ==(Object other) =>
      other is _Scene &&
      identical(other.pose.rows, pose.rows) &&
      other.pose.dx == pose.dx &&
      other.pose.dy == pose.dy &&
      other.onTile == onTile &&
      other.outline == outline &&
      other.tile == tile &&
      other.pressed == pressed &&
      listEquals(other.cells, cells) &&
      other.burst == burst &&
      other.badge == badge;

  @override
  int get hashCode => Object.hash(
    pose.rows,
    pose.dx,
    pose.dy,
    onTile,
    outline,
    tile,
    pressed,
    Object.hashAll(cells),
    burst,
    badge,
  );
}

class _AgentArt extends StatelessWidget {
  const _AgentArt({
    required this.size,
    required this.scene,
    this.spriteSize = 18,
  });

  final double size;
  final double spriteSize;
  final _Scene scene;

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
    final scene = art.scene;
    final origin = screenOrigin();
    Offset snap(Offset point) => Offset(
      _pixels(origin.dx + point.dx) - origin.dx,
      _pixels(origin.dy + point.dy) - origin.dy,
    );

    final center = size.center(Offset.zero);
    final paint = Paint()..isAntiAlias = false;
    final palette = colors.agentPixels(onTile: scene.onTile);
    if (scene.tile != _Tile.none) {
      final edge = art.size;
      final start = snap(center - Offset(edge / 2, edge / 2));
      _paintTile(
        canvas,
        paint,
        start & Size.square(_pixels(edge)),
        solid: scene.tile == _Tile.solid,
      );
    }

    final cell = _pixels(art.spriteSize / 9);
    final base = snap(
      center -
          Offset(cell * 4.5, cell * 4.5) +
          Offset(0, scene.pressed ? 1 : 0),
    );
    final body = base + Offset(scene.pose.dx * cell, scene.pose.dy * cell);
    void pixel(Offset at, int x, int y, Color color) => canvas.drawRect(
      Rect.fromLTWH(at.dx + x * cell, at.dy + y * cell, cell, cell),
      paint..color = color,
    );

    final rows = scene.pose.rows;
    bool filled(int x, int y) {
      if (y < 0 || y >= 9) return false;
      final row = rows[y];
      final i = x + (row.length - 9) ~/ 2;
      return i >= 0 && i < row.length && row[i] != '.';
    }

    if (scene.outline) {
      for (var y = -1; y <= 9; y++) {
        for (var x = -2; x <= 10; x++) {
          if (filled(x, y)) continue;
          if (filled(x - 1, y) ||
              filled(x + 1, y) ||
              filled(x, y - 1) ||
              filled(x, y + 1)) {
            pixel(body, x, y, colors.agentTile);
          }
        }
      }
    }
    for (var y = 0; y < 9; y++) {
      final row = rows[y];
      for (var i = 0; i < row.length; i++) {
        final x = i - (row.length - 9) ~/ 2;
        final color = switch (row[i]) {
          '#' => palette.body,
          '+' => palette.highlight,
          '=' => palette.shadow,
          'o' => palette.eyes,
          'w' => colors.onBrand,
          _ => null,
        };
        if (color != null) pixel(body, x, y, color);
      }
    }

    for (final (x, y, ink, opacity) in scene.cells) {
      final color = switch (ink) {
        _Ink.accent => colors.accent,
        _Ink.warn => colors.warn,
        _Ink.faint => colors.faint,
        _Ink.star => colors.star,
        _Ink.water => colors.agentPixels(onTile: false).highlight,
      };
      pixel(base, x, y, color.withValues(alpha: opacity));
    }

    if (scene.burst case final step? when step < 3) {
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
    if (scene.badge case final color?) {
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

  void _paintTile(Canvas canvas, Paint paint, Rect r, {required bool solid}) {
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
        ..color = solid
            ? colors.agentTile
            : colors.accent.withValues(alpha: .13),
    );
    if (solid) {
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

  @override
  bool shouldRepaint(_AgentPainter old) =>
      dpr != old.dpr ||
      colors.dark != old.colors.dark ||
      colors.accent != old.colors.accent ||
      colors.bg != old.colors.bg ||
      art.spriteSize != old.art.spriteSize ||
      art.size != old.art.size ||
      art.scene != old.art.scene;
}
