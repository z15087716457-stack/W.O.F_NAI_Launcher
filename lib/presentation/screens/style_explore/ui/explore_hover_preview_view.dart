import 'dart:io';
import 'dart:math' as math;
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import '../actions/explore_hover_data.dart';

Widget buildExploreHoverPreview(
  BuildContext context,
  ExploreCandidateHoverInfo info,
  Rect? anchor,
) {
  final scheme = Theme.of(context).colorScheme;
  final path = info.filePath;
  return Positioned.fill(
    child: IgnorePointer(
      child: CustomSingleChildLayout(
        delegate: _PreviewPlacement(anchor),
        child: Material(
          key: const Key('explore-candidate-hover-preview'),
          elevation: 8,
          color: scheme.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: KeyedSubtree(
            key: ValueKey('explore-candidate-hover-${info.candidateId}'),
            child: Stack(
              children: [
                if (path != null)
                  info.imageBuilder?.call(context, path) ??
                      Image.file(
                        File(path),
                        fit: BoxFit.contain,
                        cacheWidth: 720,
                        gaplessPlayback: true,
                        errorBuilder: (_, _, _) => SizedBox(
                          width: 120,
                          height: 120,
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 32,
                            color: scheme.outline,
                          ),
                        ),
                      ),
                if (info.badgeText.isNotEmpty)
                  Positioned(
                    left: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: .75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        info.badgeText,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _PreviewPlacement extends SingleChildLayoutDelegate {
  _PreviewPlacement(this.anchor);
  final Rect? anchor;
  static const margin = 8.0, gap = 6.0, side = 320.0;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints limits) =>
      BoxConstraints(
        maxWidth: math.min(side, math.max(0, limits.maxWidth - margin * 2)),
        maxHeight: math.min(side, math.max(0, limits.maxHeight - margin * 2)),
      );
  @override
  Offset getPositionForChild(Size viewport, Size image) {
    final rect = anchor;
    if (rect == null) return const Offset(-10000, -10000);
    final above = rect.top - gap - image.height, below = rect.bottom + gap;
    final y = above >= margin
        ? above
        : below + image.height <= viewport.height - margin
        ? below
        : rect.top - margin >= viewport.height - margin - rect.bottom
        ? above
        : below;
    return Offset(
      (rect.center.dx - image.width / 2).clamp(
        margin,
        math.max(margin, viewport.width - margin - image.width),
      ),
      y.clamp(
        margin,
        math.max(margin, viewport.height - margin - image.height),
      ),
    );
  }

  @override
  bool shouldRelayout(covariant _PreviewPlacement oldDelegate) =>
      oldDelegate.anchor != anchor;
}
