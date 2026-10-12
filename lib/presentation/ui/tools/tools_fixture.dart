import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../kit/ui_colors.dart';
import '../kit/ui_fixture_image.dart';
import '../kit/ui_text.dart';
import 'tools_contract.dart';
import 'tools_editor.dart';

/// 画布工具的假数据（测试、预览用）：数值照原型（832 × 1216、Opus、V5 Full）。
/// [ToolsFixture.images] 换成原型图（`src`、`q2`、`q3`、`sketch`、`lineart`）时就和原型同图。
abstract final class ToolsFixture {
  static ImageProvider Function(String key) images = UiFixtureImage.gradient;

  static ImageProvider _img(String key, ImageProvider? Function(String)? f) =>
      f?.call(key) ?? images(key);

  static final now = DateTime(2026, 10, 12, 16, 45);

  // ───────── 增强 / 放大 ─────────

  static ToolsEnhanceData enhance({bool custom = false, bool local = false}) =>
      ToolsEnhanceData(
        sourceWidth: 832,
        sourceHeight: 1216,
        scales: const [
          '1',
          '1.5',
          ToolsEnhanceScale.max,
          ToolsEnhanceScale.local,
        ],
        scale: local ? ToolsEnhanceScale.local : '1',
        outWidth: local ? null : 832,
        outHeight: local ? null : 1216,
        magnitude: 3,
        strength: custom ? .62 : .5,
        noise: custom ? .05 : 0,
        custom: custom,
        local: const ToolsLocalUpscale(label: 'SeedVR2 3B FP8', factor: 2),
        model: 'V5 Full',
        steps: 28,
        cost: 20,
      );

  static const backends = [
    ToolsUpscaleBackend(
      id: 'local',
      title: '本机',
      detail: '用本机显卡 · 只支持 Windows',
    ),
    ToolsUpscaleBackend(
      id: 'novelai',
      title: 'NovelAI 云端',
      detail: '官方放大 · 输入上限约 2.8 MP',
      cost: 1,
    ),
  ];

  static ToolsUpscaleData upscale({bool cloud = false, bool missing = false}) =>
      ToolsUpscaleData(
        backends: backends,
        backend: cloud ? 'novelai' : 'local',
        sourceWidth: 832,
        sourceHeight: 1216,
        methods: cloud
            ? const []
            : const [
                ToolsOption(id: 'regular', label: '普通模型'),
                ToolsOption(id: 'seedvr2', label: 'SeedVR2'),
                ToolsOption(id: 'rtx', label: 'RTX'),
              ],
        method: 'seedvr2',
        models: cloud
            ? const []
            : [
                ToolsUpscaleModel(
                  id: 'seedvr2-3b',
                  label: 'SeedVR2 3B FP8',
                  state: missing
                      ? ToolsModelState.missing
                      : ToolsModelState.ready,
                  detail: '3.4 GB',
                ),
                const ToolsUpscaleModel(
                  id: 'seedvr2-7b',
                  label: 'SeedVR2 7B FP8',
                  state: ToolsModelState.missing,
                ),
                const ToolsUpscaleModel(
                  id: 'seedvr2-3b-q4',
                  label: 'SeedVR2 3B Q4',
                  detail: '1.9 GB',
                ),
              ],
        model: 'seedvr2-3b',
        scale: cloud ? null : 2,
        minScale: 1,
        maxScale: 4,
        outWidth: cloud ? 3328 : 1664,
        outHeight: cloud ? 4864 : 2432,
        advanced: cloud
            ? const []
            : const [
                ToolsUpscaleField(
                  id: 'blocksToSwap',
                  label: '显存分块',
                  kind: ToolsFieldKind.number,
                  value: 16.0,
                  max: 36,
                  hint: '放到内存里的层数：调高省显存但更慢',
                ),
                ToolsUpscaleField(
                  id: 'vaeTiled',
                  label: 'VAE 分块',
                  kind: ToolsFieldKind.toggle,
                  value: true,
                ),
                ToolsUpscaleField(
                  id: 'inputNoise',
                  label: '输入噪声',
                  kind: ToolsFieldKind.number,
                  value: 0.0,
                  decimals: 2,
                ),
                ToolsUpscaleField(
                  id: 'color',
                  label: '色彩校正',
                  kind: ToolsFieldKind.choice,
                  value: 'lab',
                  options: [
                    ToolsOption(id: 'lab', label: 'Lab'),
                    ToolsOption(id: 'wavelet', label: 'Wavelet'),
                    ToolsOption(id: 'none', label: '关闭'),
                  ],
                ),
              ],
        advancedHint: 'SeedVR2 的显存分块、VAE 分块、噪声、种子',
        cost: cloud ? 1 : null,
        blocked: missing ? '模型还没下载，先到“管理模型”里装好' : null,
      );

  // ───────── 编辑器 ─────────

  static ToolsEditorData editor({
    ToolsEditorMode mode = ToolsEditorMode.edit,
    ToolsTool? tool,
    bool focus = false,
    bool expand = false,
    ImageProvider? Function(String key)? images,
  }) {
    final f = images;
    final inpaint = mode == ToolsEditorMode.inpaint;
    final t = tool ?? (focus ? ToolsTool.focus : ToolsTool.brush);
    return ToolsEditorData(
      mode: mode,
      width: 832,
      height: 1216,
      image: _img('src', f),
      zoom: 560 / 832,
      canUndo: true,
      dirty: true,
      tool: t,
      options: optionsFor(t, inpaint: inpaint),
      layers: inpaint
          ? [
              const ToolsLayer(
                id: 'mask',
                name: '蒙版',
                detail: '画笔画的地方会被重画',
                kind: ToolsLayerKind.mask,
              ),
              ToolsLayer(
                id: 'base',
                name: '底图',
                detail: '原图，不会被修改',
                kind: ToolsLayerKind.base,
                locked: true,
                thumb: _img('src', f),
              ),
            ]
          : [
              const ToolsLayer(
                id: 'l1',
                name: '图层 1',
                detail: '画笔 · 3 笔',
                kind: ToolsLayerKind.paint,
              ),
              ToolsLayer(
                id: 'base',
                name: '底图',
                detail: '832 × 1216',
                kind: ToolsLayerKind.base,
                thumb: _img('src', f),
              ),
            ],
      layer: inpaint ? 'mask' : 'l1',
      adjust: inpaint
          ? const ToolsAdjust()
          : const ToolsAdjust(saturation: 8, brightness: -3),
      inpaint: ToolsInpaintInfo(
        coverage: .18,
        regions: 2,
        focusWidth: focus ? 512 : null,
        focusHeight: focus ? 640 : null,
      ),
      expanding: expand,
      expand: expand
          ? const ToolsExpand(bottom: 128, left: 64, right: 64)
          : const ToolsExpand(),
      cursor: const Offset(412, 538),
      applyCost: 20,
    );
  }

  /// 每个工具的默认选项（照原型：画笔 18 px / 85% / 硬 / 压感，蒙版 24 px）。
  static ToolsToolOptions optionsFor(ToolsTool t, {required bool inpaint}) =>
      switch (t) {
        ToolsTool.brush when inpaint => const ToolsToolOptions(
          size: 24,
          maxSize: 200,
          square: false,
        ),
        ToolsTool.eraser when inpaint => const ToolsToolOptions(
          size: 24,
          maxSize: 200,
          square: false,
        ),
        ToolsTool.fill when inpaint => const ToolsToolOptions(tolerance: 15),
        ToolsTool.brush => const ToolsToolOptions(
          size: 18,
          maxSize: 200,
          opacity: .85,
          tip: ToolsBrushTip.hard,
          pressure: true,
        ),
        ToolsTool.eraser => const ToolsToolOptions(
          size: 20,
          maxSize: 200,
          tip: ToolsBrushTip.hard,
        ),
        ToolsTool.fill => const ToolsToolOptions(tolerance: 15),
        ToolsTool.blur => const ToolsToolOptions(
          size: 20,
          maxSize: 200,
          intensity: .5,
        ),
        ToolsTool.stamp => const ToolsToolOptions(
          size: 20,
          maxSize: 200,
          opacity: 1,
        ),
        _ => const ToolsToolOptions(),
      };

  // ───────── 导演工具 ─────────

  static const costs = {
    ToolsDirectorTool.removeBackground: 65,
    ToolsDirectorTool.declutter: 0,
    ToolsDirectorTool.lineArt: 0,
    ToolsDirectorTool.sketch: 0,
    ToolsDirectorTool.colorize: 0,
    ToolsDirectorTool.emotion: 0,
  };

  static List<ToolsDirectorInput> inputs(ImageProvider? Function(String)? f) =>
      [
        ToolsDirectorInput(
          id: 'in1',
          thumb: _img('src', f),
          width: 832,
          height: 1216,
        ),
        ToolsDirectorInput(
          id: 'in2',
          thumb: _img('q2', f),
          width: 832,
          height: 1216,
        ),
        ToolsDirectorInput(
          id: 'in3',
          thumb: _img('q3', f),
          width: 924,
          height: 1200,
        ),
      ];

  static List<ToolsDirectorRun> runs(ImageProvider? Function(String)? f) => [
    ToolsDirectorRun(
      id: 'r1',
      tool: ToolsDirectorTool.sketch,
      inputId: 'in1',
      images: [_img('sketch', f)],
      time: now.subtract(const Duration(seconds: 20)),
      width: 832,
      height: 1216,
      cost: 0,
    ),
    ToolsDirectorRun(
      id: 'r2',
      tool: ToolsDirectorTool.removeBackground,
      inputId: 'in1',
      images: [_img('src', f), _img('q3', f), _img('src', f)],
      variants: const ['透明底', '背景', '合成'],
      time: now.subtract(const Duration(minutes: 3)),
      width: 832,
      height: 1216,
      cost: 65,
    ),
    ToolsDirectorRun(
      id: 'r3',
      tool: ToolsDirectorTool.lineArt,
      inputId: 'in2',
      images: [_img('q2', f)],
      time: now.subtract(const Duration(minutes: 12)),
      width: 832,
      height: 1216,
      cost: 0,
    ),
  ];

  /// 草图化刚跑完（原型 `dt`）。
  static ToolsDirectorData director({
    ToolsDirectorTool tool = ToolsDirectorTool.sketch,
    ImageProvider? Function(String key)? images,
  }) => ToolsDirectorData(
    tool: tool,
    costs: costs,
    anlas: 29053,
    inputs: inputs(images),
    input: 'in1',
    runs: runs(images),
    run: 'r1',
    now: now,
  );

  /// 表情修复，运行前（原型 `dt-emotion`）：结果列表里没有刚跑的草图化。
  static ToolsDirectorData emotion({
    ImageProvider? Function(String key)? images,
  }) => ToolsDirectorData(
    tool: ToolsDirectorTool.emotion,
    costs: costs,
    anlas: 29053,
    inputs: inputs(images),
    input: 'in1',
    runs: runs(images).skip(1).toList(),
    emotion: 'shy',
    prompt: 'blush, embarrassed, looking away',
    now: now,
  );

  /// 背景移除的结果（三张可切）。
  static ToolsDirectorData removeBg({
    ImageProvider? Function(String key)? images,
  }) => ToolsDirectorData(
    tool: ToolsDirectorTool.removeBackground,
    costs: costs,
    anlas: 29053,
    inputs: inputs(images),
    input: 'in1',
    runs: runs(images),
    run: 'r2',
    variant: 2,
    now: now,
  );

  static ToolsDirectorData running({
    ImageProvider? Function(String key)? images,
  }) => ToolsDirectorData(
    tool: ToolsDirectorTool.lineArt,
    costs: costs,
    anlas: 29053,
    inputs: inputs(images),
    input: 'in1',
    runs: runs(images),
    running: true,
    now: now,
  );

  static ToolsDirectorData failed({
    ImageProvider? Function(String key)? images,
  }) => ToolsDirectorData(
    tool: ToolsDirectorTool.colorize,
    costs: costs,
    anlas: 29053,
    inputs: inputs(images),
    input: 'in1',
    runs: runs(images),
    prompt: 'blue dress, silver hair',
    defry: 1,
    error: 'HTTP 429 Too Many Requests：同一账号同时只能跑一个请求，稍等几秒再试',
    now: now,
  );

  static ToolsDirectorData pixel({
    ImageProvider? Function(String key)? images,
  }) => ToolsDirectorData(
    tool: ToolsDirectorTool.pixelSnap,
    costs: costs,
    anlas: 29053,
    inputs: inputs(images),
    input: 'in2',
    runs: runs(images),
    pixel: const ToolsPixelOptions(
      palette: ToolsPixelPalette.custom,
      colors: 48,
    ),
    now: now,
  );

  /// 刚打开、队列是空的。
  static const empty = ToolsDirectorData(
    tool: ToolsDirectorTool.removeBackground,
    costs: costs,
    anlas: 29053,
  );
}

/// 预览 / 测试用的画布舞台（接线后换成画布引擎）：按缩放居中摆底图，
/// 画上原型里的示意笔画、蒙版、聚焦框、扩展区域和手柄（坐标是 832 × 1216 的图上坐标）。
class ToolsFixtureStage extends StatelessWidget {
  const ToolsFixtureStage({super.key});

  static Widget builder(BuildContext context) => const ToolsFixtureStage();

  @override
  Widget build(BuildContext context) {
    final scope = ToolsEditorScope.of(context);
    final d = scope.data;
    final mask = d.mask;
    return LayoutBuilder(
      builder: (context, box) {
        final k = d.zoom;
        final w = d.width * k, h = d.height * k;
        final ox = ((box.maxWidth - w) / 2).roundToDouble();
        final oy = ((box.maxHeight - h) / 2).roundToDouble();
        final e = d.expand;
        final ex = d.inpainting && (d.expanding || !e.isZero);
        final c = context.ui;
        final accent = c.accent;
        return Stack(
          children: [
            if (ex)
              Positioned(
                left: ox - e.left * k,
                top: oy - e.top * k,
                width: w + (e.left + e.right) * k,
                height: h + (e.top + e.bottom) * k,
                child: CustomPaint(
                  key: const Key('tools-stage-expand'),
                  painter: _ExpandPainter(accent, c.dark),
                ),
              ),
            Positioned(
              key: const Key('tools-stage-image'),
              left: ox,
              top: oy,
              width: w,
              height: h,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (d.image != null)
                      Image(image: d.image!, fit: BoxFit.fill),
                    CustomPaint(
                      painter: _OverlayPainter(
                        inpaint: d.inpainting,
                        mask: !d.expanding,
                        focus: d.inpaint.hasFocus,
                        look: mask,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (ex && d.expanding) ...[
              for (final p in [
                Offset(ox - e.left * k, oy + h / 2),
                Offset(ox + w + e.right * k, oy + h / 2),
                Offset(ox + w / 2, oy + h + e.bottom * k),
                Offset(ox + w / 2, oy - e.top * k),
              ])
                Positioned(
                  left: p.dx - 7,
                  top: p.dy - 7,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              if (e.bottom > 0)
                Positioned(
                  left: ox + w / 2 - 40,
                  width: 80,
                  top: oy + h + e.bottom * k + 12,
                  child: Center(
                    child: Container(
                      height: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '+${e.bottom} px',
                        style: UiText.mono(
                          12,
                          weight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
            if (!d.inpainting && d.cursor != null)
              Positioned(
                left: ox + w * .77 - 9,
                top: oy + h * .345 - 9,
                child: IgnorePointer(
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0x80000000)),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OverlayPainter extends CustomPainter {
  const _OverlayPainter({
    required this.inpaint,
    required this.mask,
    required this.focus,
    required this.look,
  });

  /// 局部重绘：画蒙版（[mask]，扩展边缘时不画）和聚焦框；编辑图像：画两道示意笔画。
  final bool inpaint;
  final bool mask;
  final bool focus;
  final ToolsMaskLook look;

  @override
  void paint(Canvas canvas, Size size) {
    if (inpaint && !this.mask) return;
    canvas.save();
    canvas.scale(size.width / 832, size.height / 1216);
    final mask = look;
    if (inpaint) {
      final blobs = [
        Path()
          ..moveTo(330, 520)
          ..cubicTo(300, 470, 330, 400, 400, 392)
          ..cubicTo(470, 386, 520, 430, 522, 500)
          ..cubicTo(526, 560, 500, 610, 470, 640)
          ..cubicTo(430, 676, 360, 660, 340, 610)
          ..cubicTo(330, 585, 336, 556, 330, 520)
          ..close(),
        Path()
          ..moveTo(560, 840)
          ..cubicTo(600, 820, 680, 830, 700, 870)
          ..cubicTo(715, 905, 690, 940, 640, 944)
          ..cubicTo(590, 948, 545, 920, 545, 885)
          ..cubicTo(545, 865, 548, 850, 560, 840)
          ..close(),
      ];
      for (final b in blobs) {
        canvas.drawPath(
          b,
          Paint()..color = mask.color.withValues(alpha: mask.opacity * .75),
        );
        if (mask.pattern != ToolsMaskPattern.solid) {
          canvas.save();
          canvas.clipPath(b);
          final p = Paint()
            ..color = Colors.white.withValues(alpha: .5)
            ..strokeWidth = 3;
          for (var x = -1216.0; x < 832; x += 14) {
            canvas.drawLine(Offset(x, 1216), Offset(x + 1216, 0), p);
          }
          canvas.restore();
        }
        canvas.drawPath(
          b,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = mask.color,
        );
      }
      if (focus) {
        _dashed(
          canvas,
          const Rect.fromLTWH(290, 350, 290, 340),
          Colors.white,
          3,
          14,
          9,
        );
        _dashed(
          canvas,
          const Rect.fromLTWH(226, 286, 418, 468),
          Colors.white.withValues(alpha: .55),
          2,
          4,
          8,
        );
      }
    } else {
      final pink = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xD9E94B6A);
      canvas.drawPath(
        Path()
          ..moveTo(120, 250)
          ..cubicTo(180, 200, 260, 230, 300, 200)
          ..cubicTo(340, 170, 400, 170, 440, 210),
        pink,
      );
      canvas.drawPath(
        Path()
          ..moveTo(540, 300)
          ..quadraticBezierTo(580, 240, 630, 280)
          ..quadraticBezierTo(670, 300, 710, 290),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xE6FFFFFF),
      );
    }
    canvas.restore();
  }

  static void _dashed(
    Canvas canvas,
    Rect r,
    Color color,
    double width,
    double dash,
    double gap,
  ) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = color;
    final path = Path()..addRect(r);
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += dash + gap) {
        canvas.drawPath(m.extractPath(d, math.min(d + dash, m.length)), p);
      }
    }
  }

  @override
  bool shouldRepaint(_OverlayPainter old) =>
      old.inpaint != inpaint ||
      old.mask != mask ||
      old.focus != focus ||
      old.look != look;
}

/// 扩展出来的区域：棋盘格 + 2px 强调色虚线框。
class _ExpandPainter extends CustomPainter {
  const _ExpandPainter(this.accent, this.dark);
  final Color accent;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = dark ? const Color(0xFF111111) : Colors.white,
    );
    final alt = Paint()
      ..color = dark ? const Color(0xFF232323) : const Color(0xFFF2F2F2);
    const s = 8.0;
    for (var y = 0; y * s < size.height; y++) {
      for (var x = 0; x * s < size.width; x++) {
        if ((x + y).isEven) {
          canvas.drawRect(Rect.fromLTWH(x * s, y * s, s, s), alt);
        }
      }
    }
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = accent;
    final path = Path()..addRect((Offset.zero & size).deflate(1));
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 10) {
        canvas.drawPath(m.extractPath(d, math.min(d + 6, m.length)), p);
      }
    }
  }

  @override
  bool shouldRepaint(_ExpandPainter old) =>
      old.accent != accent || old.dark != dark;
}
