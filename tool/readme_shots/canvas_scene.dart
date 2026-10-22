import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_contract.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_layer.dart';
import 'package:nai_launcher/presentation/ui/channel/channel_overlay.dart';

import 'images.dart';

/// README-only layout; the decoration and ruler are production widgets.
/// Keep artwork unique and preserve each source image's actual aspect ratio.
class ReadmeCanvas extends StatelessWidget {
  const ReadmeCanvas({super.key, required this.images, required this.settings});

  final ShotImages images;
  final ChannelSettings settings;

  static const files = ['s07.jpg', 's02.jpg', 's18.jpg', 's13.jpg'];
  static const rects = [
    Rect.fromLTWH(-650, 0, 420, 614),
    Rect.fromLTWH(-190, 0, 840, 575),
    Rect.fromLTWH(-650, 700, 840, 575),
    Rect.fromLTWH(230, 700, 420, 614),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = box.biggest;
      final scale = math.min(
        .57,
        math.min((size.width - 100) / 1300, (size.height - 160) / 1314),
      );
      final camera = ChannelCamera(
        offset: Offset(size.width / 2, (size.height - 1314 * scale) / 2),
        scale: scale,
      );
      final data = ChannelViewData(
        settings: settings,
        camera: camera,
        now: DateTime(2026, 10, 22, 16, 45),
        batches: [
          for (var i = 0; i < rects.length; i++)
            ChannelBatch(
              id: 'readme-$i',
              rect: rects[i],
              time: DateTime(2026, 10, 22, 16, 42 - i * 4),
            ),
        ],
      );
      return ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ChannelBackdrop(data: data),
            for (var i = 0; i < files.length; i++)
              Positioned.fromRect(
                rect: Rect.fromPoints(
                  camera.worldToScreen(rects[i].topLeft),
                  camera.worldToScreen(rects[i].bottomRight),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image(
                    image: images.fileImage(files[i]),
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ChannelOverlay(
              data: data,
              actions: ChannelActions(
                onSettingsChanged: (_) {},
                onJumpTo: (_) {},
              ),
            ),
          ],
        ),
      );
    },
  );
}
