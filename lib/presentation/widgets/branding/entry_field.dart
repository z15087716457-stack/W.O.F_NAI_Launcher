import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/scheduler.dart';

import '../../themes/presets/geist_theme.dart';
import '../../themes/studio_typography.dart';

/// 登录 / 载入页的「去噪」背景。
///
/// 整页是一张 Geist Pixel 字符网格：未解出的格子是随流动噪声闪烁的
/// 噪点（Circle 变体）；去噪程度越高，偶数行越多的格子解出提示词原文
/// （Square 变体），刚解出的格子闪一下品牌蓝。载入页的去噪程度就是
/// 预热进度；登录页另有零星的逐字解码和跟随指针的去噪透镜。
///
/// 时钟与去噪程度跨实例保留：载入页换成登录页时画面接着走，文字墙
/// 慢慢散回噪点，而不是从头开始。
class EntryField extends StatefulWidget {
  const EntryField({
    super.key,
    required this.signal,
    this.ambient = true,
    this.busy = false,
    this.clearKey,
    this.pointer,
  });

  /// 目标去噪程度 0–1；载入页传预热进度，登录页传 0。
  final double signal;

  /// 是否穿插零星的逐字解码（登录页）。
  final bool ambient;

  /// 登录中：去噪程度至少升到 [busyLevel]，透镜变大、噪声流得更快。
  final bool busy;

  /// 需要留白的中央内容（Logo + 卡片），字符在它周围淡出。
  final GlobalKey? clearKey;

  /// 指针位置（与本组件同一坐标系），null 表示指针不在页面上。
  final ValueListenable<Offset?>? pointer;

  /// 登录中的去噪程度下限。
  static const double busyLevel = 0.42;

  /// 最近一次解码使用的种子，供页脚显示。
  static final ValueNotifier<int> seed = ValueNotifier<int>(2481937562);

  /// 当前去噪程度（约 4 Hz 更新），供页脚显示。
  static final ValueNotifier<double> level = ValueNotifier<double>(0);

  static final Stopwatch _clock = Stopwatch()..start();
  static double _level = 0;

  @override
  State<EntryField> createState() => _EntryFieldState();
}

// Geist Pixel 的像素格是 76/1000 em：13.16 号字正好一个逻辑像素一格。
const double _cellW = 10;
const double _cellH = 18;
const double _fontSize = 13.16;
const int _frameMs = 33;

const String _prompt =
    'masterpiece, best quality, 1girl, solo, looking at viewer, '
    '{{cinematic lighting}}, depth of field, watercolor, detailed background, '
    'night sky, city lights, rain, reflections, from side, floating hair, '
    'dynamic angle, volumetric light, film grain, very aesthetic, absurdres, '
    '1.2::soft focus::, upper body, outdoors, cherry blossoms, petals, '
    'golden hour, pastel colors, ink wash, lineart, [[flat color]], bokeh, '
    'chromatic aberration, wind, looking back, scenery, steps: 28, '
    'scale: 5.0, sampler: k_euler_ancestral, noise_schedule: karras, '
    'cfg_rescale: 0.0, 832x1216, nai-diffusion-4-5-full, -1::lowres::, '
    'undesired: lowres, bad anatomy, jpeg artifacts, blurry, ';
const String _noiseLight = '·.';
const String _noiseMid = ':·.';
const String _noiseAlpha = 'abcdefghijklmnopqrstuvwxyz0123456789';

final List<String> _glyphs = () {
  final seen = <String>{};
  for (final ch in (_prompt + _noiseLight + _noiseMid + _noiseAlpha).split(
    '',
  )) {
    if (ch != ' ') seen.add(ch);
  }
  return List<String>.unmodifiable(seen);
}();
final Map<String, int> _glyphIndex = {
  for (var i = 0; i < _glyphs.length; i++) _glyphs[i]: i,
};
final List<int> _promptGlyphs = [
  for (final ch in _prompt.split('')) ch == ' ' ? -1 : _glyphIndex[ch]!,
];
final List<int> _lightGlyphs = [
  for (final ch in _noiseLight.split('')) _glyphIndex[ch]!,
];
final List<int> _midGlyphs = [
  for (final ch in _noiseMid.split('')) _glyphIndex[ch]!,
];
final List<int> _alphaGlyphs = [
  for (final ch in _noiseAlpha.split('')) _glyphIndex[ch]!,
];

double _hash(int x, int y, int z) {
  var h = ((x * 374761393) ^ (y * 668265263) ^ (z * 1274126177)) & 0xFFFFFFFF;
  h = ((h ^ (h >> 13)) * 1103515245) & 0xFFFFFFFF;
  h ^= h >> 16;
  return h / 4294967296.0;
}

double _valueNoise(double x, double y, double z) {
  final xi = x.floor(), yi = y.floor(), zi = z.floor();
  var xf = x - xi, yf = y - yi, zf = z - zi;
  xf = xf * xf * (3 - 2 * xf);
  yf = yf * yf * (3 - 2 * yf);
  zf = zf * zf * (3 - 2 * zf);
  final a = _hash(xi, yi, zi), b = _hash(xi + 1, yi, zi);
  final c = _hash(xi, yi + 1, zi), d = _hash(xi + 1, yi + 1, zi);
  final e = _hash(xi, yi, zi + 1), f = _hash(xi + 1, yi, zi + 1);
  final g = _hash(xi, yi + 1, zi + 1), h = _hash(xi + 1, yi + 1, zi + 1);
  final l1 = a + (b - a) * xf, l2 = c + (d - c) * xf;
  final l3 = e + (f - e) * xf, l4 = g + (h - g) * xf;
  final m1 = l1 + (l2 - l1) * yf, m2 = l3 + (l4 - l3) * yf;
  return m1 + (m2 - m1) * zf;
}

double _smooth(double a, double b, double x) {
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

class _DecodeEvent {
  _DecodeEvent(
    this.row,
    this.col,
    this.length,
    this.start,
    this.speed,
    this.hold,
  );
  final int row, col, length;
  final double start, speed, hold;
  static const double dissolve = 1.1;
  double get end => start + length / speed + hold;
}

class _Repaint extends ChangeNotifier {
  void tick() => notifyListeners();
}

class _EntryFieldState extends State<EntryField>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker = createTicker(_onTick);
  final _repaint = _Repaint();
  final _rng = math.Random();

  bool _animate = true;
  bool _visible = true;
  bool _primed = false;
  int _lastMs = -1000;
  int _lastHudMs = -1000;
  double _nextEvent = 0;
  final _events = <_DecodeEvent>[];

  Size _size = Size.zero;
  int _cols = 0, _rows = 0, _count = 0;
  double _ox = 0, _oy = 0;
  Float32List _thr = Float32List(0), _mask = Float32List(0);
  Float32List _rollAt = Float32List(0), _flashAt = Float32List(0);
  Uint16List _roll = Uint16List(0);
  Uint8List _resolved = Uint8List(0), _band = Uint8List(0);
  Uint8List _scramble = Uint8List(0);
  Float32List _transforms = Float32List(0), _rects = Float32List(0);
  Int32List _colors = Int32List(0);
  Rect? _clearRect;

  ui.Image? _atlas;
  double _atlasDpr = 0;
  bool _light = false;
  int _inkRgb = 0, _flashRgb = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate = !MediaQuery.disableAnimationsOf(context);
    _syncTicker();
  }

  @override
  void didUpdateWidget(EntryField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_animate &&
        (oldWidget.signal != widget.signal || oldWidget.busy != widget.busy)) {
      _scheduleStillFrame();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 窗口收进托盘时不再空转；失焦但仍可见时照常播放。
    _visible =
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    _syncTicker();
  }

  void _syncTicker() {
    final run = _animate && _visible;
    if (run && !_ticker.isActive) {
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
    if (!_animate) _scheduleStillFrame();
  }

  void _scheduleStillFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _animate) return;
      EntryField._level = _target;
      _primed = false;
      _advance(EntryField._clock.elapsedMilliseconds / 1000.0);
      _repaint.tick();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _repaint.dispose();
    _atlas?.dispose();
    super.dispose();
  }

  double get _target => widget.busy
      ? math.max(widget.signal, EntryField.busyLevel)
      : widget.signal.clamp(0.0, 1.0);

  void _onTick(Duration _) {
    final ms = EntryField._clock.elapsedMilliseconds;
    if (ms - _lastMs < _frameMs) return;
    _lastMs = ms;
    final target = _target;
    final level = EntryField._level;
    // 往上跟得快（进度、登录中），往下散得慢（载入页换成登录页）。
    EntryField._level =
        level + (target - level) * (target > level ? 0.14 : 0.05);
    if (ms - _lastHudMs > 250) {
      _lastHudMs = ms;
      EntryField.level.value = EntryField._level;
    }
    _advance(ms / 1000.0);
    _repaint.tick();
  }

  void _ensureAtlas(double dpr) {
    if (_atlas != null && _atlasDpr == dpr) return;
    _atlas?.dispose();
    _atlas = null;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    for (var row = 0; row < 2; row++) {
      final family = row == 0
          ? StudioTypography.pixelSquare
          : StudioTypography.pixelCircle;
      for (var i = 0; i < _glyphs.length; i++) {
        final painter = TextPainter(
          text: TextSpan(
            text: _glyphs[i],
            style: TextStyle(
              fontFamily: family,
              fontSize: _fontSize,
              height: 1,
              color: Colors.white,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        painter.paint(
          canvas,
          Offset(
            i * _cellW + (_cellW - painter.width) / 2,
            row * _cellH + (_cellH - painter.height) / 2 + 1,
          ),
        );
        painter.dispose();
      }
    }
    final picture = recorder.endRecording();
    try {
      _atlas = picture.toImageSync(
        (_glyphs.length * _cellW * dpr).ceil(),
        (2 * _cellH * dpr).ceil(),
      );
      _atlasDpr = dpr;
    } catch (_) {
      _atlas = null;
    } finally {
      picture.dispose();
    }
  }

  void _resize(Size size) {
    _size = size;
    _cols = (size.width / _cellW).ceil() + 1;
    _rows = (size.height / _cellH).ceil() + 1;
    final n = _cols * _rows;
    _ox =
        ((size.width - (_cols - 1) * _cellW) / 2).floorToDouble() - _cellW / 2;
    _oy =
        ((size.height - (_rows - 1) * _cellH) / 2).floorToDouble() - _cellH / 2;
    _thr = Float32List(n);
    _mask = Float32List(n);
    _rollAt = Float32List(n);
    _flashAt = Float32List(n)..fillRange(0, n, -9);
    _roll = Uint16List(n);
    _resolved = Uint8List(n);
    _band = Uint8List(n);
    _scramble = Uint8List(n);
    _transforms = Float32List(n * 8);
    _rects = Float32List(n * 8);
    _colors = Int32List(n * 2);
    final now = EntryField._clock.elapsedMilliseconds / 1000.0;
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        final i = r * _cols + c;
        // 阈值带一点空间连续性：成片解出，边缘仍是参差的
        final coarse = _valueNoise(c * 0.07, r * 0.11, 7.3);
        _thr[i] =
            0.02 + 0.97 * math.min(1, 0.55 * coarse + 0.45 * _hash(c, r, 99));
        _roll[i] = (_hash(c, r, 5) * 65535).floor();
        _rollAt[i] = now + _hash(c, r, 6) * 2;
      }
    }
    _events.clear();
    _clearRect = null;
    _primed = false;
    _computeMask();
  }

  void _measureClearRect() {
    final me = context.findRenderObject();
    final target = widget.clearKey?.currentContext?.findRenderObject();
    Rect? rect;
    if (me is RenderBox &&
        target is RenderBox &&
        me.hasSize &&
        target.hasSize &&
        me.attached &&
        target.attached) {
      final origin =
          target.localToGlobal(Offset.zero) - me.localToGlobal(Offset.zero);
      rect = origin & target.size;
    }
    final old = _clearRect;
    final same =
        (old == null && rect == null) ||
        (old != null &&
            rect != null &&
            (old.left - rect.left).abs() < 0.5 &&
            (old.top - rect.top).abs() < 0.5 &&
            (old.width - rect.width).abs() < 0.5 &&
            (old.height - rect.height).abs() < 0.5);
    if (same) return;
    _clearRect = rect;
    _computeMask();
  }

  void _computeMask() {
    final rect = _clearRect;
    final hasClear = rect != null && !rect.isEmpty;
    final cx = hasClear ? rect.center.dx : 0.0;
    final cy = hasClear ? rect.center.dy : 0.0;
    final rx = hasClear ? rect.width / 2 + 120 : 1.0;
    final ry = hasClear ? rect.height / 2 + 90 : 1.0;
    final w = _size.width, h = _size.height;
    for (var r = 0; r < _rows; r++) {
      final y = _oy + r * _cellH + _cellH / 2;
      final vy = _smooth(0, 74, y) * _smooth(h - 30, h - 96, y);
      for (var c = 0; c < _cols; c++) {
        final x = _ox + c * _cellW + _cellW / 2;
        var m = vy * _smooth(0, 60, x) * _smooth(w, w - 60, x);
        if (hasClear && m > 0) {
          final dx = (x - cx) / rx, dy = (y - cy) / ry;
          m *= _smooth(0.68, 1.28, math.sqrt(dx * dx + dy * dy));
        }
        _mask[r * _cols + c] = m;
      }
    }
  }

  int _promptGlyphAt(int r, int c) {
    final length = _promptGlyphs.length;
    return _promptGlyphs[((r * 97 + c) % length + length) % length];
  }

  void _spawnEvent(double t) {
    if (_rows < 6 || _cols < 32) return;
    for (var tries = 0; tries < 30; tries++) {
      final r = 2 + 2 * _rng.nextInt(math.max(1, (_rows - 4) ~/ 2));
      var c0 = _rng.nextInt(_cols - 30);
      if (_mask[r * _cols + c0] < 0.55 ||
          _mask[r * _cols + math.min(_cols - 1, c0 + 24)] < 0.55) {
        continue;
      }
      // 从一个提示词的开头解起，到逗号收尾
      var back = 0;
      while (back < 12 && c0 > 0 && _promptGlyphAt(r, c0 - 1) >= 0) {
        c0--;
        back++;
      }
      final comma = _glyphIndex[',']!;
      var length = 16 + _rng.nextInt(26);
      while (length < 52 && _promptGlyphAt(r, c0 + length) != comma) {
        length++;
      }
      length = math.min(length + 1, _cols - c0 - 1);
      if (length <= 0) continue;
      _events.add(
        _DecodeEvent(
          r,
          c0,
          length,
          t,
          26 + _rng.nextDouble() * 16,
          3.2 + _rng.nextDouble() * 3,
        ),
      );
      EntryField.seed.value = _rng.nextInt(1 << 32);
      return;
    }
  }

  void _advance(double t) {
    if (_cols == 0 || _atlas == null) return;
    _measureClearRect();
    final n = _cols * _rows;
    final level = EntryField._level;

    if (widget.ambient && _animate && t > _nextEvent) {
      if (_events.length < 4) _spawnEvent(t);
      _nextEvent = t + 0.9 + _rng.nextDouble() * 1.6;
    }
    _band.fillRange(0, n, 0);
    _scramble.fillRange(0, n, 0);
    _events.removeWhere((event) {
      final end = event.end;
      if (t > end + _DecodeEvent.dissolve) return true;
      for (var k = 0; k < event.length; k++) {
        final i = event.row * _cols + event.col + k;
        if (i >= n) break;
        final reveal = event.start + k / event.speed;
        final gone =
            end + _hash(event.col + k, event.row, 3) * _DecodeEvent.dissolve;
        if (t >= reveal && t < gone) {
          _band[i] = 1;
        } else if (t >= reveal - 0.22 && t < reveal) {
          _scramble[i] = 1;
        }
      }
      return false;
    });

    final pointer = widget.pointer?.value;
    final lens = widget.busy ? 170.0 : 125.0;
    final lens2 = lens * lens;
    final resolvedAlpha = _light ? 0.34 : 0.30;
    final dotAlpha = _light ? 0.10 : 0.085;
    final z = t * (widget.busy ? 0.34 : 0.14);
    final floor = 0.5 + 0.42 * level;
    final primed = _primed;
    _count = 0;

    for (var r = 0; r < _rows; r++) {
      final y = _oy + r * _cellH;
      final textRow = r.isEven;
      for (var c = 0; c < _cols; c++) {
        final i = r * _cols + c;
        final m = _mask[i];
        if (m < 0.02) continue;
        final x = _ox + c * _cellW;
        var signal = level + (_band[i] == 1 ? 2 : 0);
        if (pointer != null) {
          final dx = x + _cellW / 2 - pointer.dx;
          final dy = y + _cellH / 2 - pointer.dy;
          final d2 = dx * dx + dy * dy;
          if (d2 < lens2) {
            final q = 1 - d2 / lens2;
            signal += 1.15 * q * q;
          }
        }
        final resolved = signal > _thr[i];
        if (resolved != (_resolved[i] == 1)) {
          _resolved[i] = resolved ? 1 : 0;
          // 首帧直接落到当前状态，不让整面文字一起闪蓝
          if (resolved) _flashAt[i] = primed ? t : -9;
        }
        if (_scramble[i] == 1) {
          final glyph = _alphaGlyphs[_rng.nextInt(_alphaGlyphs.length)];
          _add(glyph, 0, x, y, _inkRgb, 0.55 * m);
          continue;
        }
        if (resolved) {
          if (!textRow) continue;
          final glyph = _promptGlyphAt(r, c);
          if (glyph < 0) continue;
          final f = (t - _flashAt[i]) / 0.5;
          if (f < 1) {
            _add(glyph, 0, x, y, _flashRgb, m * (1 - f) * 0.95);
            _add(glyph, 0, x, y, _inkRgb, m * resolvedAlpha * f);
          } else {
            _add(glyph, 0, x, y, _inkRgb, m * resolvedAlpha);
          }
          continue;
        }
        final noise =
            0.66 * _valueNoise(c * 0.055, r * 0.09, z) +
            0.34 * _valueNoise(c * 0.19, r * 0.3, z * 1.7 + 11);
        if (noise < floor) continue;
        if (t > _rollAt[i]) {
          _roll[i] = _rng.nextInt(65535);
          _rollAt[i] =
              t + 0.12 + _rng.nextDouble() * (noise > floor + 0.14 ? 0.5 : 1.6);
        }
        final List<int> set;
        final double alpha;
        if (noise < floor + 0.07) {
          set = _lightGlyphs;
          alpha = dotAlpha;
        } else if (noise < floor + 0.14) {
          set = _midGlyphs;
          alpha = dotAlpha * 1.15;
        } else {
          set = _alphaGlyphs;
          alpha = dotAlpha * 1.35;
        }
        _add(set[_roll[i] % set.length], 1, x, y, _inkRgb, m * alpha);
      }
    }
    _primed = true;
  }

  void _add(int glyph, int row, double x, double y, int rgb, double alpha) {
    final a = (alpha * 255).round();
    if (a <= 0 || _count >= _colors.length) return;
    final k = _count * 4;
    final dpr = _atlasDpr;
    _transforms[k] = 1 / dpr;
    _transforms[k + 1] = 0;
    _transforms[k + 2] = x;
    _transforms[k + 3] = y;
    final sx = glyph * _cellW * dpr, sy = row * _cellH * dpr;
    _rects[k] = sx;
    _rects[k + 1] = sy;
    _rects[k + 2] = sx + _cellW * dpr;
    _rects[k + 3] = sy + _cellH * dpr;
    _colors[_count] = (math.min(a, 255) << 24) | rgb;
    _count++;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final light = scheme.brightness == Brightness.light;
    if (light != _light && !_animate) _scheduleStillFrame();
    _light = light;
    _inkRgb = scheme.onSurface.toARGB32() & 0xFFFFFF;
    _flashRgb =
        (light ? GeistTheme.blue : const Color(0xFF3D8BFF)).toARGB32() &
        0xFFFFFF;
    _ensureAtlas(MediaQuery.devicePixelRatioOf(context));
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        if (size != _size && size.isFinite) {
          _resize(size);
          if (!_animate) _scheduleStillFrame();
        }
        return CustomPaint(
          key: const Key('entry_field'),
          size: size,
          isComplex: true,
          willChange: _animate,
          painter: _FieldPainter(this),
        );
      },
    );
  }
}

class _FieldPainter extends CustomPainter {
  _FieldPainter(this.state) : super(repaint: state._repaint);

  final _EntryFieldState state;
  static final Paint _paint = Paint()..filterQuality = FilterQuality.none;

  @override
  void paint(Canvas canvas, Size size) {
    final atlas = state._atlas;
    final count = state._count;
    if (atlas == null || count == 0) return;
    canvas.drawRawAtlas(
      atlas,
      Float32List.sublistView(state._transforms, 0, count * 4),
      Float32List.sublistView(state._rects, 0, count * 4),
      Int32List.sublistView(state._colors, 0, count),
      BlendMode.modulate,
      null,
      _paint,
    );
  }

  @override
  bool shouldRepaint(_FieldPainter oldDelegate) => oldDelegate.state != state;
}
