import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/canvas_channel_feed_provider.dart';
import '../providers/canvas_channel_provider.dart';
import '../providers/canvas_settings_provider.dart';
import '../screens/generation/widgets/canvas/canvas_feed_layout.dart';
import '../ui/channel/channel_contract.dart';
import '../ui/channel/channel_layer.dart';
import '../ui/kit/ui_colors.dart';

/// 贯通整个生图页窗口的统一动态视觉通道底景。
///
/// 全窗口只绘制一份连续实时动态场景，左侧参数栏与右侧历史栏以通透半透明玻璃
/// 浮在上面，彻底消除侧栏单独压扁重绘、静止割裂与重度糊斑问题。
class GenerationPanelBackdropWiring extends ConsumerStatefulWidget {
  const GenerationPanelBackdropWiring({
    super.key,
    required this.canvasViewport,
  });

  final Rect canvasViewport;

  @override
  ConsumerState<GenerationPanelBackdropWiring> createState() =>
      _GenerationPanelBackdropWiringState();
}

class _GenerationPanelBackdropWiringState
    extends ConsumerState<GenerationPanelBackdropWiring> {
  bool _queued = false;

  void _refresh() {
    if (!mounted) return;
    // The canvas can flush its retained layout while building. A background
    // sibling must wait until that frame finishes instead of invalidating it.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_queued) return;
      _queued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _queued = false;
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(canvasChannelNotifierProvider, (_, _) => _refresh());
    final settings = ref.read(canvasChannelNotifierProvider);
    if (settings.mode == ChannelMode.off) return const SizedBox.expand();

    ref.listen(canvasReducedMotionNotifierProvider, (_, _) => _refresh());
    final reducedMotion = ref.read(canvasReducedMotionNotifierProvider);

    final highContrast = MediaQuery.highContrastOf(context);

    ref.listen(canvasChannelFeedProvider, (_, _) => _refresh());
    ref.listen(
      canvasFeedLayoutProvider.select((s) => s.groups.isEmpty),
      (_, _) => _refresh(),
    );
    ref.listen(generationCanvasCameraProvider, (_, _) => _refresh());

    final feed = ref.read(canvasChannelFeedProvider);
    final empty = ref.read(canvasFeedLayoutProvider).groups.isEmpty;
    final world = ref.read(generationCanvasCameraProvider);
    final camera = empty
        ? ChannelCamera.welcome(widget.canvasViewport.size)
        : ChannelCamera(offset: world.offset, scale: world.scale);
    final offset = camera.offset + widget.canvasViewport.topLeft;
    final effectiveSettings = reducedMotion
        ? settings.copyWith(motion: false, ruler: false)
        : settings.copyWith(ruler: false);
    final uiColors = context.ui;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bounds = Offset.zero & constraints.biggest;
        if (bounds.isEmpty) return const SizedBox.expand();
        final center = widget.canvasViewport.intersect(bounds);

        // 正常宽窗下将视觉主舞台对齐中央画布中心；极窄窗下平滑过渡至全窗中心
        final tCenter = ((center.width - 120.0) / 160.0).clamp(0.0, 1.0);
        final stageCenterX = center.isEmpty
            ? bounds.center.dx
            : ui.lerpDouble(bounds.center.dx, center.center.dx, tCenter)!;

        final stage = ChannelBackdrop(
          key: const ValueKey('gen-panel-backdrop-stage'),
          pass: ChannelPaintPass.scene,
          data: ChannelViewData(
            settings: effectiveSettings,
            camera: ChannelCamera(offset: offset, scale: camera.scale),
            welcome: empty,
            batches: feed.batches,
            pinboard: feed.pinboard,
            now: feed.now,
            generating: feed.generating,
            stageCenterX: stageCenterX,
          ),
        );

        // 高对比度模式下侧栏不透明，仅裁切绘制中央可视画布区域
        if (highContrast) {
          if (center.isEmpty) return const SizedBox.expand();
          return Stack(
            key: const Key('gen-panel-backdrop'),
            children: [
              Positioned.fill(
                child: ClipRect(
                  clipper: _RectClipper(center),
                  child: stage,
                ),
              ),
            ],
          );
        }

        // 按用户可调的侧栏透明度叠加本底柔化膜：
        // sideTransparency = 0.0 → veilAlpha = 1.0（完全不透纯实底）；
        // 默认 0.45 → veilAlpha = 0.55（搭配 GenPanelSurface 65% 后约 16% 温和透光）；
        // sideTransparency = 1.0 → veilAlpha = 0.0（最通透，约 35% 透光）。
        final veilAlpha = (1.0 - settings.sideTransparency).clamp(0.0, 1.0);
        final veilColor = uiColors.bg.withValues(alpha: veilAlpha);

        return Stack(
          key: const Key('gen-panel-backdrop'),
          children: [
            Positioned.fill(child: stage),
            if (center.left > 0)
              Positioned(
                key: const ValueKey('gen-panel-veil-left'),
                left: 0,
                top: 0,
                width: center.left,
                height: bounds.height,
                child: ColoredBox(color: veilColor),
              ),
            if (center.right < bounds.right)
              Positioned(
                key: const ValueKey('gen-panel-veil-right'),
                left: center.right,
                top: 0,
                width: bounds.right - center.right,
                height: bounds.height,
                child: ColoredBox(color: veilColor),
              ),
          ],
        );
      },
    );
  }
}

class _RectClipper extends CustomClipper<Rect> {
  const _RectClipper(this.rect);
  final Rect rect;

  @override
  Rect getClip(Size size) => rect;

  @override
  bool shouldReclip(_RectClipper oldClipper) => oldClipper.rect != rect;
}
