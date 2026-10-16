import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/canvas_channel_feed_provider.dart';
import '../providers/canvas_channel_provider.dart';
import '../screens/generation/widgets/canvas/canvas_feed_layout.dart';
import '../ui/channel/channel_contract.dart';
import '../ui/channel/channel_layer.dart';

/// Continue the existing canvas decoration under the glass side panels without
/// moving the image viewport or changing the camera's input coordinates.
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
    ref.listen(canvasChannelFeedProvider, (_, _) => _refresh());
    ref.listen(
      canvasFeedLayoutProvider.select((s) => s.groups.isEmpty),
      (_, _) => _refresh(),
    );
    ref.listen(generationCanvasCameraProvider, (_, _) => _refresh());
    final feed = ref.read(canvasChannelFeedProvider);
    final empty = ref.read(canvasFeedLayoutProvider).groups.isEmpty;
    final camera = ref.read(generationCanvasCameraProvider);
    return ChannelBackdrop(
      key: const Key('gen-panel-backdrop'),
      data: ChannelViewData(
        // Keep the decoration behind text quiet; animation remains on the
        // central canvas. No second background ticker or repeated time labels.
        settings: settings.copyWith(motion: false, ruler: false),
        camera: ChannelCamera(
          offset: empty
              ? widget.canvasViewport.center
              : camera.offset + widget.canvasViewport.topLeft,
          scale: empty ? 1 : camera.scale,
        ),
        batches: feed.batches,
        pinboard: feed.pinboard,
        now: feed.now,
        generating: feed.generating,
      ),
    );
  }
}
