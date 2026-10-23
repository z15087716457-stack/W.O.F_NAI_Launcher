import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/canvas_channel_feed_provider.dart';
import '../providers/canvas_channel_provider.dart';
import '../providers/simple_output_viewer_provider.dart';
import '../screens/generation/widgets/canvas/canvas_feed_layout.dart';
import '../ui/channel/channel_contract.dart';
import '../ui/channel/channel_layer.dart';
import '../widgets/common/resize_decoration_cache.dart';

/// Paint and pre-blur only the two sidebar regions. The central canvas retains
/// its own decoration and the three floating toolbars retain their material.
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
    ref.listen(simpleOutputViewerNotifierProvider, (_, _) => _refresh());
    final simple = ref.read(simpleOutputViewerNotifierProvider);
    final highContrast = MediaQuery.highContrastOf(context);
    if (highContrast && !simple) return const SizedBox.expand();
    ref.listen(canvasChannelFeedProvider, (_, _) => _refresh());
    ref.listen(
      canvasFeedLayoutProvider.select((s) => s.groups.isEmpty),
      (_, _) => _refresh(),
    );
    ref.listen(generationCanvasCameraProvider, (_, _) => _refresh());
    final feed = ref.read(canvasChannelFeedProvider);
    final empty = ref.read(canvasFeedLayoutProvider).groups.isEmpty;
    final camera = ref.read(generationCanvasCameraProvider);
    final offset = empty
        ? widget.canvasViewport.center
        : camera.offset + widget.canvasViewport.topLeft;
    return LayoutBuilder(
      builder: (context, constraints) {
        final bounds = Offset.zero & constraints.biggest;
        final center = widget.canvasViewport.intersect(bounds);
        Widget region(String name, Rect rect, {required bool blur}) {
          // Three sigma of overscan prevents clamp streaks along panel edges.
          final bleed = blur ? 30.0 : 0.0;
          final origin = rect.topLeft - Offset(bleed, bleed);
          final scene = ChannelBackdrop(
            key: ValueKey('gen-panel-backdrop-$name'),
            data: ChannelViewData(
              settings: settings.copyWith(motion: false, ruler: false),
              camera: ChannelCamera(
                offset: offset - origin,
                scale: empty ? 1 : camera.scale,
              ),
              batches: feed.batches,
              pinboard: feed.pinboard,
              now: feed.now,
              generating: feed.generating,
            ),
          );
          return Positioned.fromRect(
            rect: rect,
            child: ResizeDecorationCache(
              child: ClipRect(
                child: RepaintBoundary(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: -bleed,
                        top: -bleed,
                        width: rect.width + bleed * 2,
                        height: rect.height + bleed * 2,
                        child: blur
                            ? ImageFiltered(
                                imageFilter: ui.ImageFilter.blur(
                                  sigmaX: 10,
                                  sigmaY: 10,
                                  tileMode: ui.TileMode.clamp,
                                ),
                                child: scene,
                              )
                            : scene,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Stack(
          key: const Key('gen-panel-backdrop'),
          children: [
            if (!highContrast && center.left > 0)
              region(
                'left',
                Rect.fromLTRB(0, 0, center.left, bounds.bottom),
                blur: true,
              ),
            if (!highContrast && center.right < bounds.right)
              region(
                'right',
                Rect.fromLTRB(center.right, 0, bounds.right, bounds.bottom),
                blur: true,
              ),
            // Simple output has no canvas engine to paint its center.
            if (simple && !center.isEmpty)
              region('center', center, blur: false),
          ],
        );
      },
    );
  }
}
