import 'package:nai_launcher/presentation/widgets/common/studio_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/image/image_operation.dart';

class ImageOperationBadge extends StatelessWidget {
  const ImageOperationBadge({super.key, required this.operation});
  final ImageOperation operation;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = switch (operation) {
      ImageOperation.imageToImage => l10n.img2img_title,
      ImageOperation.inpaint => l10n.img2img_inpaint,
      ImageOperation.enhance => l10n.img2img_enhance,
      ImageOperation.variations => l10n.img2img_generateVariations,
      ImageOperation.upscale => l10n.image_upscale,
      ImageOperation.vibeTransfer => l10n.vibe_title,
      ImageOperation.removeBackground => l10n.img2img_directorRemoveBackground,
      ImageOperation.lineArt => l10n.img2img_directorLineArt,
      ImageOperation.sketch => l10n.img2img_directorSketch,
      ImageOperation.colorize => l10n.img2img_directorColorize,
      ImageOperation.emotion => l10n.img2img_directorEmotion,
      ImageOperation.declutter => l10n.img2img_directorDeclutter,
      ImageOperation.pixelSnap => l10n.img2img_pixelSnap,
    };
    final asset = switch (operation) {
      ImageOperation.imageToImage => 'img2img',
      ImageOperation.inpaint => 'inpaint',
      ImageOperation.enhance => 'enhance',
      ImageOperation.variations => 'variations',
      ImageOperation.upscale => 'upscale',
      ImageOperation.vibeTransfer => 'vibe-transfer',
      _ => null,
    };
    final icon = switch (operation) {
      ImageOperation.removeBackground => Icons.content_cut,
      ImageOperation.lineArt => Icons.draw_outlined,
      ImageOperation.sketch => Icons.gesture,
      ImageOperation.colorize => Icons.palette_outlined,
      ImageOperation.emotion => Icons.mood_outlined,
      ImageOperation.declutter => Icons.cleaning_services_outlined,
      _ => Icons.grid_view,
    };
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: .9),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: asset == null
                ? StudioIcon(icon, size: 16)
                : SvgPicture.asset(
                    'assets/icons/nai-icon-$asset.svg',
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.onSurface,
                      BlendMode.srcIn,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
