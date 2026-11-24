import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../themes/studio_typography.dart';

/// 五套字符艺术动态画布共享的离屏字形图集与 `drawRawAtlas` 批处理引擎。
///
/// 全应用只按固定 2x 超采样烘焙一张纯白单行字形贴图（约 60KB 显存）：
/// - 纯 ASCII 字符由随包内置的 `Geist Mono` 渲染；
/// - 所有非 ASCII 艺术符号（盲文点阵、半色调云块、声纹阶梯、轨道流线、四芒星与生物核）
///   直接通过精密矢量几何在槽位中一次烘焙，100% 不依赖宿主系统字体，全平台零豆腐块。
///
/// 渲染每帧只需把可见字符写入复用的 TypedData 缓冲区，最终以**单次
/// `canvas.drawRawAtlas(..., BlendMode.modulate)`**完成全屏多色字形绘制。
class ChannelGlyphAtlas {
  ChannelGlyphAtlas._();

  /// 5 套字符艺术主题（深海浮游 / 暮光云海 / 晴空云海 / 折光黑洞 / 声纹潮汐）使用的全部字符。
  static const List<String> glyphs = [
    // 基础密度与海洋/云雾/星光字符
    '·', '.', ':', ';', '-', '~', '=', '+', '*', 'x', 'o', '0', 'O', 'X', 'K',
    '%', '#', '@',
    // 盲文点阵柔雾
    '⠁', '⠂', '⠃', '⠇',
    // 半色调云块与声纹地形阶梯
    '░', '▒', '▓', '█',
    '▁', '▂', '▃', '▄', '▅', '▆', '▇',
    // 轨道流线与等高线方向符
    '─', '━', '═', '│', '║', '╱', '╲',
    // 发光核心、星芒与山峰标记
    '∘', '◎', '◈', '◉', '▲', '✦', '✧',
  ];

  static final Map<String, int> indexOf = {
    for (var i = 0; i < glyphs.length; i++) glyphs[i]: i,
  };

  /// 图集逻辑槽位尺寸（烘焙时乘以 [_bakeScale] 超采样，适配高 DPI 大屏）。
  static const double slotW = 10.0;
  static const double slotH = 14.0;
  static const double _bakeScale = 3.0;
  static const double _bakeFontSize = 10.6;

  static ui.Image? _image;
  static bool _failed = false;

  static ui.Image? ensureImage() {
    if (_image != null) return _image;
    if (_failed) return null;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(_bakeScale);
    const style = TextStyle(
      fontFamily: StudioTypography.mono,
      fontFamilyFallback: StudioTypography.fallback,
      fontSize: _bakeFontSize,
      fontWeight: FontWeight.w500,
      height: 1.0,
      color: Color(0xFFFFFFFF),
    );
    for (var i = 0; i < glyphs.length; i++) {
      final ch = glyphs[i];
      final ox = i * slotW;
      if (_paintProceduralGlyph(canvas, ch, ox, 0, slotW, slotH)) {
        continue;
      }
      final tp = TextPainter(
        text: TextSpan(text: ch, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          ox + (slotW - tp.width) * 0.5,
          (slotH - tp.height) * 0.5,
        ),
      );
      tp.dispose();
    }
    final picture = recorder.endRecording();
    try {
      _image = picture.toImageSync(
        (glyphs.length * slotW * _bakeScale).ceil(),
        (slotH * _bakeScale).ceil(),
      );
      return _image;
    } catch (_) {
      _failed = true;
      return null;
    } finally {
      picture.dispose();
    }
  }

  /// 用矢量几何直接烘焙所有非 ASCII 符号，彻底消除字体缺字豆腐块且边缘更锋利均匀。
  static bool _paintProceduralGlyph(
    Canvas canvas,
    String ch,
    double ox,
    double oy,
    double w,
    double h,
  ) {
    final fill = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..isAntiAlias = true;
    final stroke = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final cx = ox + w * 0.5;
    final cy = oy + h * 0.5;

    switch (ch) {
      case '·':
        canvas.drawCircle(Offset(cx, cy), 0.96, fill);
        return true;

      // 盲文点阵柔雾（精密 2×4 圆点网格）
      case '⠁':
        canvas.drawCircle(Offset(ox + 3.4, oy + 3.6), 0.80, fill);
        return true;
      case '⠂':
        canvas.drawCircle(Offset(ox + 3.4, oy + 6.5), 0.84, fill);
        return true;
      case '⠃':
        canvas
          ..drawCircle(Offset(ox + 3.4, oy + 3.8), 0.82, fill)
          ..drawCircle(Offset(ox + 3.4, oy + 7.2), 0.82, fill);
        return true;
      case '⠇':
        canvas
          ..drawCircle(Offset(ox + 3.4, oy + 3.5), 0.82, fill)
          ..drawCircle(Offset(ox + 3.4, oy + 7.0), 0.82, fill)
          ..drawCircle(Offset(ox + 3.4, oy + 10.5), 0.82, fill);
        return true;

      // 半色调云块（精致印刷微点密度阶梯，避免粗重像素砖块感）
      case '░':
        _drawHalftone(canvas, ox, oy, w, h, fill, density: 1);
        return true;
      case '▒':
        _drawHalftone(canvas, ox, oy, w, h, fill, density: 2);
        return true;
      case '▓':
        _drawHalftone(canvas, ox, oy, w, h, fill, density: 3);
        return true;
      case '█':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(ox + 1.25, oy + 1.65, w - 2.5, h - 3.3),
            const Radius.circular(1.35),
          ),
          fill,
        );
        return true;

      // 声纹地形底部对齐阶梯柱 ▁..▇
      case '▁':
      case '▂':
      case '▃':
      case '▄':
      case '▅':
      case '▆':
      case '▇':
        final lvl = ch.codeUnitAt(0) - 0x2581 + 1; // 1..7
        final barH = (h - 2.4) * (lvl / 8.0);
        canvas.drawRect(
          Rect.fromLTWH(ox + 1.25, oy + h - 1.2 - barH, w - 2.5, barH),
          fill,
        );
        return true;

      // 轨道等离子流线与等高线切线（纤细蚀刻感）
      case '─':
        stroke.strokeWidth = 1.05;
        canvas.drawLine(Offset(ox + 0.5, cy), Offset(ox + w - 0.5, cy), stroke);
        return true;
      case '━':
        stroke.strokeWidth = 1.85;
        canvas.drawLine(Offset(ox + 0.5, cy), Offset(ox + w - 0.5, cy), stroke);
        return true;
      case '═':
        stroke.strokeWidth = 0.98;
        canvas
          ..drawLine(
            Offset(ox + 0.5, cy - 1.6),
            Offset(ox + w - 0.5, cy - 1.6),
            stroke,
          )
          ..drawLine(
            Offset(ox + 0.5, cy + 1.6),
            Offset(ox + w - 0.5, cy + 1.6),
            stroke,
          );
        return true;
      case '│':
        stroke.strokeWidth = 1.05;
        canvas.drawLine(Offset(cx, oy + 0.7), Offset(cx, oy + h - 0.7), stroke);
        return true;
      case '║':
        stroke.strokeWidth = 0.98;
        canvas
          ..drawLine(
            Offset(cx - 1.4, oy + 0.7),
            Offset(cx - 1.4, oy + h - 0.7),
            stroke,
          )
          ..drawLine(
            Offset(cx + 1.4, oy + 0.7),
            Offset(cx + 1.4, oy + h - 0.7),
            stroke,
          );
        return true;
      case '╱':
        stroke.strokeWidth = 1.15;
        canvas.drawLine(
          Offset(ox + 1.1, oy + h - 1.3),
          Offset(ox + w - 1.1, oy + 1.3),
          stroke,
        );
        return true;
      case '╲':
        stroke.strokeWidth = 1.15;
        canvas.drawLine(
          Offset(ox + 1.1, oy + 1.3),
          Offset(ox + w - 1.1, oy + h - 1.3),
          stroke,
        );
        return true;

      // 光子环、发光生物核、星芒与山峰结晶
      case '∘':
        stroke.strokeWidth = 1.05;
        canvas.drawCircle(Offset(cx, cy), 2.15, stroke);
        return true;
      case '◎':
        stroke.strokeWidth = 0.98;
        canvas
          ..drawCircle(Offset(cx, cy), 3.4, stroke)
          ..drawCircle(Offset(cx, cy), 1.35, fill);
        return true;
      case '◉':
        stroke.strokeWidth = 1.02;
        canvas
          ..drawCircle(Offset(cx, cy), 3.5, stroke)
          ..drawCircle(Offset(cx, cy), 1.8, fill);
        return true;
      case '◈':
        stroke.strokeWidth = 0.98;
        final outer = Path()
          ..moveTo(cx, cy - 4.0)
          ..lineTo(cx + 3.4, cy)
          ..lineTo(cx, cy + 4.0)
          ..lineTo(cx - 3.4, cy)
          ..close();
        final inner = Path()
          ..moveTo(cx, cy - 1.75)
          ..lineTo(cx + 1.45, cy)
          ..lineTo(cx, cy + 1.75)
          ..lineTo(cx - 1.45, cy)
          ..close();
        canvas
          ..drawPath(outer, stroke)
          ..drawPath(inner, fill);
        return true;
      case '▲':
        final tri = Path()
          ..moveTo(cx, cy - 3.6)
          ..lineTo(cx + 3.5, cy + 3.2)
          ..lineTo(cx - 3.5, cy + 3.2)
          ..close();
        canvas.drawPath(tri, fill);
        return true;
      case '✦':
        canvas.drawPath(_fourPointStar(cx, cy, 4.1, 1.15), fill);
        return true;
      case '✧':
        stroke.strokeWidth = 0.95;
        canvas.drawPath(_fourPointStar(cx, cy, 3.85, 1.1), stroke);
        return true;

      default:
        return false;
    }
  }

  static void _drawHalftone(
    Canvas canvas,
    double ox,
    double oy,
    double w,
    double h,
    Paint paint, {
    required int density,
  }) {
    const padX = 1.15;
    const padY = 1.55;
    final uw = (w - padX * 2) / 3.0;
    final uh = (h - padY * 2) / 4.0;
    if (density == 1) {
      // ░ 稀疏错位微点（柔和空气感）
      for (var r = 0; r < 4; r++) {
        for (var c = 0; c < 3; c++) {
          if ((r + c).isOdd) continue;
          canvas.drawCircle(
            Offset(ox + padX + (c + 0.5) * uw, oy + padY + (r + 0.5) * uh),
            0.66,
            paint,
          );
        }
      }
    } else if (density == 2) {
      // ▒ 中等棋盘圆点（细腻印刷半色调体积）
      for (var r = 0; r < 4; r++) {
        for (var c = 0; c < 3; c++) {
          final big = (r + c).isEven;
          canvas.drawCircle(
            Offset(ox + padX + (c + 0.5) * uw, oy + padY + (r + 0.5) * uh),
            big ? 0.92 : 0.56,
            paint,
          );
        }
      }
    } else {
      // ▓ 细密蚀刻网点（丰盈且保留透气细缝）
      for (var r = 0; r < 4; r++) {
        for (var c = 0; c < 3; c++) {
          canvas.drawCircle(
            Offset(ox + padX + (c + 0.5) * uw, oy + padY + (r + 0.5) * uh),
            1.05,
            paint,
          );
        }
      }
    }
  }

  static Path _fourPointStar(double cx, double cy, double outer, double inner) {
    return Path()
      ..moveTo(cx, cy - outer)
      ..quadraticBezierTo(cx, cy, cx + outer * 0.88, cy)
      ..quadraticBezierTo(cx, cy, cx, cy + outer)
      ..quadraticBezierTo(cx, cy, cx - outer * 0.88, cy)
      ..quadraticBezierTo(cx, cy, cx, cy - outer)
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: inner * 0.75))
      ..close();
  }
}

/// 可复用的 `drawRawAtlas` 批处理缓冲，零逐帧大数组分配。
class ChannelGlyphBatch {
  static final ChannelGlyphBatch shared = ChannelGlyphBatch._();

  ChannelGlyphBatch._();

  int _capacity = 0;
  Float32List _transforms = Float32List(0);
  Float32List _rects = Float32List(0);
  Int32List _colors = Int32List(0);
  int _count = 0;

  static final Paint _atlasPaint = Paint()
    ..filterQuality = FilterQuality.medium
    ..isAntiAlias = true;

  int get count => _count;

  void begin(int estimatedCapacity) {
    _count = 0;
    if (estimatedCapacity > _capacity) {
      _grow(estimatedCapacity);
    }
  }

  void _grow(int minCap) {
    final next = math.max(minCap, _capacity == 0 ? 4096 : _capacity * 2);
    final t = Float32List(next * 4);
    final r = Float32List(next * 4);
    final c = Int32List(next);
    if (_count > 0) {
      t.setRange(0, _count * 4, _transforms);
      r.setRange(0, _count * 4, _rects);
      c.setRange(0, _count, _colors);
    }
    _transforms = t;
    _rects = r;
    _colors = c;
    _capacity = next;
  }

  /// 追加一个居中锚定在 `(cx, cy)`、缩放为 [scale]（相对 10×14 基准槽位）的字形。
  @pragma('vm:prefer-inline')
  void add(
    int glyphIdx,
    double cx,
    double cy,
    double scale,
    int r,
    int g,
    int b,
    int a,
  ) {
    if (glyphIdx < 0 || a <= 0) return;
    if (_count >= _capacity) _grow(_capacity + 2048);
    final k = _count * 4;
    final drawScale = scale / ChannelGlyphAtlas._bakeScale;
    final halfW = ChannelGlyphAtlas.slotW * scale * 0.5;
    final halfH = ChannelGlyphAtlas.slotH * scale * 0.5;
    _transforms[k] = drawScale;
    _transforms[k + 1] = 0.0;
    _transforms[k + 2] = cx - halfW;
    _transforms[k + 3] = cy - halfH;

    final sx = glyphIdx * ChannelGlyphAtlas.slotW * ChannelGlyphAtlas._bakeScale;
    _rects[k] = sx;
    _rects[k + 1] = 0.0;
    _rects[k + 2] =
        sx + ChannelGlyphAtlas.slotW * ChannelGlyphAtlas._bakeScale;
    _rects[k + 3] = ChannelGlyphAtlas.slotH * ChannelGlyphAtlas._bakeScale;

    final ca = a > 255 ? 255 : a;
    final cr = r < 0 ? 0 : (r > 255 ? 255 : r);
    final cg = g < 0 ? 0 : (g > 255 ? 255 : g);
    final cb = b < 0 ? 0 : (b > 255 ? 255 : b);
    _colors[_count] = (ca << 24) | (cr << 16) | (cg << 8) | cb;
    _count++;
  }

  /// 通过一次 GPU `drawRawAtlas` 提交本批次所有字符。
  void flush(Canvas canvas) {
    if (_count == 0) return;
    final atlas = ChannelGlyphAtlas.ensureImage();
    if (atlas == null) {
      _count = 0;
      return;
    }
    canvas.drawRawAtlas(
      atlas,
      Float32List.sublistView(_transforms, 0, _count * 4),
      Float32List.sublistView(_rects, 0, _count * 4),
      Int32List.sublistView(_colors, 0, _count),
      BlendMode.modulate,
      null,
      _atlasPaint,
    );
    _count = 0;
  }
}
