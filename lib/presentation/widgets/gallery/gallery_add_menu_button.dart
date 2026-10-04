import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';

enum _GalleryAddAction { createCategory, importFolder }

/// Compact add menu anchored to the Local Gallery sidebar title button.
class GalleryAddMenuButton extends StatefulWidget {
  const GalleryAddMenuButton({
    super.key,
    required this.onCreateCategory,
    required this.onImportFolder,
  });

  final VoidCallback onCreateCategory;
  final VoidCallback onImportFolder;

  @override
  State<GalleryAddMenuButton> createState() => _GalleryAddMenuButtonState();
}

class _GalleryAddMenuButtonState extends State<GalleryAddMenuButton> {
  final GlobalKey _buttonKey = GlobalKey();

  Future<void> _showMenu() async {
    final button = _buttonKey.currentContext?.findRenderObject();
    final overlay = Overlay.of(context).context.findRenderObject();
    if (button is! RenderBox || overlay is! RenderBox) return;

    final globalBottomLeft = button.localToGlobal(
      Offset(0, button.size.height),
    );
    final anchor = overlay.globalToLocal(globalBottomLeft);
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(anchor.dx, anchor.dy, button.size.width, 0),
      Offset.zero & overlay.size,
    );
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final action = await showMenu<_GalleryAddAction>(
      context: context,
      position: position,
      constraints: const BoxConstraints(minWidth: 166, maxWidth: 190),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      items: [
        PopupMenuItem(
          value: _GalleryAddAction.createCategory,
          height: 42,
          child: Row(
            children: [
              const Icon(Icons.create_new_folder_outlined, size: 18),
              const SizedBox(width: 10),
              Text(l10n.localGallery_createCategoryTitle),
            ],
          ),
        ),
        PopupMenuItem(
          value: _GalleryAddAction.importFolder,
          height: 42,
          child: Row(
            children: [
              const Icon(Icons.drive_folder_upload_outlined, size: 18),
              const SizedBox(width: 10),
              Text(l10n.localGallery_importFolder),
            ],
          ),
        ),
      ],
    );
    if (!mounted) return;
    switch (action) {
      case _GalleryAddAction.createCategory:
        widget.onCreateCategory();
      case _GalleryAddAction.importFolder:
        widget.onImportFolder();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: _buttonKey,
      onPressed: _showMenu,
      tooltip: context.l10n.localGallery_newOrImport,
      icon: const Icon(Icons.add, size: 18),
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        fixedSize: const Size(30, 30),
        minimumSize: const Size(30, 30),
      ),
    );
  }
}
