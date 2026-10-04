import 'package:flutter/material.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';

import '../../../core/utils/localization_extension.dart';
import '../common/image_action_menu.dart';

enum LocalImageContextAction {
  details,
  sendToTextToImage,
  sendToImg2Img,
  sendToStyleTransfer,
  sendToPreciseReference,
  saveToPreciseRefLibrary,
  sendToKrita,
  upscale,
  importMetadata,
  copyPrompt,
  copySeed,
  moveTo,
  copyTo,
  showInFolder,
  delete,
}

class LocalImageContextMenu {
  const LocalImageContextMenu._();

  static Future<LocalImageContextAction?> show(
    BuildContext context, {
    required Offset position,
    required bool hasImportableMetadata,
    required bool hasPrompt,
    required bool hasSeed,
    required bool isKritaConnected,
  }) {
    final l = context.l10n;
    ImageMenuAction<LocalImageContextAction> item(
      LocalImageContextAction value,
      String label,
      IconData icon, {
      bool enabled = true,
      bool destructive = false,
    }) => ImageMenuAction(
      value: value,
      label: label,
      icon: icon,
      enabled: enabled,
      destructive: destructive,
    );
    return ImageActionMenu.show<LocalImageContextAction>(
      context,
      position: position,
      quickActions: [
        if (hasPrompt)
          item(
            LocalImageContextAction.copyPrompt,
            l.localGallery_copyPrompt,
            StudioIcons.galleryCopy,
          ),
        if (hasSeed)
          item(
            LocalImageContextAction.copySeed,
            l.localGallery_copySeed,
            StudioIcons.galleryHash,
          ),
      ],
      actions: [
        item(
          LocalImageContextAction.details,
          l.imageMenu_details,
          Icons.info_outline,
        ),
        item(
          LocalImageContextAction.sendToImg2Img,
          l.drop_img2img,
          StudioIcons.imageToImage,
        ),
        if (hasImportableMetadata)
          item(
            LocalImageContextAction.importMetadata,
            l.localGallery_importImageMetadata,
            StudioIcons.galleryImport,
          ),
        item(
          LocalImageContextAction.showInFolder,
          l.localGallery_showInFolder,
          StudioIcons.galleryReveal,
        ),
        const ImageMenuAction.divider(),
        ImageMenuAction(
          label: l.imageMenu_creation,
          icon: StudioIcons.referenceFocus,
          children: [
            item(
              LocalImageContextAction.sendToTextToImage,
              l.onlineGallery_sendToTextToImage,
              StudioIcons.gallerySpark,
              enabled: hasImportableMetadata,
            ),
            item(
              LocalImageContextAction.sendToStyleTransfer,
              l.drop_vibeTransfer,
              StudioIcons.styleTransfer,
            ),
            item(
              LocalImageContextAction.sendToPreciseReference,
              l.drop_characterReference,
              StudioIcons.referenceFocus,
            ),
            item(
              LocalImageContextAction.saveToPreciseRefLibrary,
              l.drop_saveToPreciseRefLibrary,
              StudioIcons.galleryBookmarkAdd,
            ),
            item(
              LocalImageContextAction.upscale,
              l.gallery_upscale,
              StudioIcons.galleryUpscale,
            ),
            item(
              LocalImageContextAction.sendToKrita,
              l.localGallery_sendToKrita,
              StudioIcons.galleryBrush,
              enabled: isKritaConnected,
            ),
          ],
        ),
        ImageMenuAction(
          label: l.imageMenu_fileActions,
          icon: Icons.folder_outlined,
          children: [
            item(
              LocalImageContextAction.moveTo,
              l.localGallery_moveTo,
              StudioIcons.galleryMove,
            ),
            item(
              LocalImageContextAction.copyTo,
              l.localGallery_copyTo,
              StudioIcons.galleryCopy,
            ),
          ],
        ),
        const ImageMenuAction.divider(),
        item(
          LocalImageContextAction.delete,
          l.common_delete,
          StudioIcons.galleryTrash,
          destructive: true,
        ),
      ],
    );
  }
}
