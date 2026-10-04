import 'package:flutter/material.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';

import '../../../core/utils/localization_extension.dart';

enum LocalImageContextAction {
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
    return showMenu<LocalImageContextAction>(
      context: context,
      constraints: const BoxConstraints(minWidth: 320, maxWidth: 420),
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: buildEntries(
        context,
        hasImportableMetadata: hasImportableMetadata,
        hasPrompt: hasPrompt,
        hasSeed: hasSeed,
        isKritaConnected: isKritaConnected,
      ),
    );
  }

  static Future<LocalImageContextAction?> showSendActions(
    BuildContext context, {
    required Offset position,
    required bool isKritaConnected,
  }) {
    return showMenu<LocalImageContextAction>(
      context: context,
      constraints: const BoxConstraints(minWidth: 320, maxWidth: 420),
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: buildSendEntries(context, isKritaConnected: isKritaConnected),
    );
  }

  static List<PopupMenuEntry<LocalImageContextAction>> buildEntries(
    BuildContext context, {
    required bool hasImportableMetadata,
    required bool hasPrompt,
    required bool hasSeed,
    required bool isKritaConnected,
  }) {
    final hasImageInfoActions = hasImportableMetadata || hasPrompt || hasSeed;

    return [
      ...buildSendEntries(context, isKritaConnected: isKritaConnected),
      if (hasImageInfoActions) const PopupMenuDivider(),
      if (hasImportableMetadata)
        _item(
          context,
          value: LocalImageContextAction.importMetadata,
          icon: StudioIcons.galleryImport,
          label: context.l10n.localGallery_importImageMetadata,
        ),
      if (hasPrompt)
        _item(
          context,
          value: LocalImageContextAction.copyPrompt,
          icon: StudioIcons.galleryCopy,
          label: context.l10n.localGallery_copyPrompt,
        ),
      if (hasSeed)
        _item(
          context,
          value: LocalImageContextAction.copySeed,
          icon: StudioIcons.galleryHash,
          label: context.l10n.localGallery_copySeed,
        ),
      const PopupMenuDivider(),
      _item(
        context,
        value: LocalImageContextAction.moveTo,
        icon: StudioIcons.galleryMove,
        label: context.l10n.localGallery_moveTo,
      ),
      _item(
        context,
        value: LocalImageContextAction.copyTo,
        icon: StudioIcons.galleryCopy,
        label: context.l10n.localGallery_copyTo,
      ),
      _item(
        context,
        value: LocalImageContextAction.showInFolder,
        icon: StudioIcons.galleryReveal,
        label: context.l10n.localGallery_showInFolder,
      ),
      _item(
        context,
        value: LocalImageContextAction.delete,
        icon: StudioIcons.galleryTrash,
        label: context.l10n.common_delete,
        destructive: true,
      ),
    ];
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
