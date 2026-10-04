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

  static Future<LocalImageContextAction?> showSendActions(
    BuildContext context, {
    required Offset position,
    required bool isKritaConnected,
  }) {
    return showMenu<LocalImageContextAction>(
      context: context,
      constraints: const BoxConstraints(minWidth: 248, maxWidth: 280),
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: buildSendEntries(context, isKritaConnected: isKritaConnected),
    );
  }

  static List<PopupMenuEntry<LocalImageContextAction>> buildSendEntries(
    BuildContext context, {
    required bool isKritaConnected,
  }) {
    return [
      _item(
        context,
        value: LocalImageContextAction.sendToTextToImage,
        icon: StudioIcons.gallerySpark,
        label: context.l10n.onlineGallery_sendToTextToImage,
      ),
      _item(
        context,
        value: LocalImageContextAction.sendToImg2Img,
        icon: StudioIcons.imageToImage,
        label: context.l10n.localGallery_sendToImg2Img,
      ),
      _item(
        context,
        value: LocalImageContextAction.sendToStyleTransfer,
        icon: StudioIcons.styleTransfer,
        label: context.l10n.localGallery_sendToStyleTransfer,
      ),
      _item(
        context,
        value: LocalImageContextAction.sendToPreciseReference,
        icon: StudioIcons.referenceFocus,
        label: context.l10n.localGallery_sendToPreciseReference,
      ),
      _item(
        context,
        value: LocalImageContextAction.saveToPreciseRefLibrary,
        icon: StudioIcons.galleryBookmarkAdd,
        label: context.l10n.localGallery_saveToPreciseRefLibrary,
      ),
      _item(
        context,
        value: LocalImageContextAction.sendToKrita,
        icon: StudioIcons.galleryBrush,
        label: context.l10n.localGallery_sendToKrita,
        enabled: isKritaConnected,
      ),
      _item(
        context,
        value: LocalImageContextAction.upscale,
        icon: StudioIcons.galleryUpscale,
        label: context.l10n.gallery_upscale,
      ),
    ];
  }

  static PopupMenuItem<LocalImageContextAction> _item(
    BuildContext context, {
    required LocalImageContextAction value,
    required IconData icon,
    required String label,
    bool enabled = true,
    bool destructive = false,
  }) {
    final color = !enabled
        ? Theme.of(context).disabledColor
        : destructive
        ? Theme.of(context).colorScheme.error
        : null;

    return PopupMenuItem<LocalImageContextAction>(
      value: value,
      height: 34,
      enabled: enabled,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: color == null ? null : TextStyle(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
