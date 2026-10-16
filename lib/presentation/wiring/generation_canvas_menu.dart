import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/localization_extension.dart';
import '../providers/image_generation_provider.dart';
import '../screens/generation/widgets/canvas/generated_image_actions.dart';
import '../ui/gen/gen_canvas.dart';
import '../ui/gen/gen_contract.dart';
import '../ui/gen/gen_page.dart';
import '../ui/kit/ui_image_menu.dart';
import '../widgets/common/image_action_menu.dart';
import '../widgets/common/studio_icons.dart';
import '../utils/krita_send_helper.dart';
import '../utils/precise_ref_library_import_helper.dart';
import 'generation_operations.dart';
import 'generation_history_actions.dart';

class GenerationCanvasMenuWiring extends ConsumerStatefulWidget {
  const GenerationCanvasMenuWiring({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<GenerationCanvasMenuWiring> createState() =>
      _GenerationCanvasMenuWiringState();
}

class _GenerationCanvasMenuWiringState
    extends ConsumerState<GenerationCanvasMenuWiring> {
  late final _onOpen = _open;

  void _open(BuildContext context, String id, Offset position) {
    final image = ref
        .read(generationHistoryActionsProvider)
        .images
        .where((image) => image.id == id)
        .firstOrNull;
    if (image != null) {
      unawaited(openGenerationCanvasMenu(context, ref, image, position));
    }
  }

  @override
  Widget build(BuildContext context) =>
      GenCanvasMenuScope(onOpen: _onOpen, child: widget.child);
}

/// 复用旧图片菜单：顶部快捷操作，编辑与更多操作分别折入子菜单。
Future<void> openGenerationCanvasMenu(
  BuildContext context,
  WidgetRef ref,
  GeneratedImage image,
  Offset position,
) async {
  final scope = GenScope.read(context);
  final a = scope.actions;
  final l = context.l10n;
  final id = image.id;
  final canInput = image.canUseAsGenerationInput && !scope.data.canvas.locked;
  final operations = GenerationOperations(ref, context, () => context.mounted);
  void run(Future<void> Function() task) => operations.run(task);
  ImageMenuAction<VoidCallback> action(
    String key,
    String label,
    IconData icon,
    VoidCallback callback, {
    bool enabled = true,
    bool destructive = false,
  }) => ImageMenuAction(
    key: Key('gen-canvas-menu-$key'),
    label: label,
    icon: icon,
    value: callback,
    enabled: enabled,
    destructive: destructive,
  );
  scope.controller.closePopover();
  final selected = await UiImageMenu.show<VoidCallback>(
    context,
    position: position,
    quickActions: [
      action(
        'save',
        l.shortcut_action_save_image,
        Icons.save_alt,
        () => a.onSaveImage(id),
        enabled: image.canSave,
      ),
      action(
        'copy',
        l.shortcut_action_copy_image,
        Icons.copy,
        () => a.onCopyImage(id),
        enabled: image.canSave,
      ),
    ],
    actions: [
      action(
        'viewer',
        l.imageMenu_details,
        Icons.open_in_full,
        () => a.onOpenViewer(id),
      ),
      action(
        'delete',
        l.common_delete,
        Icons.delete_outline,
        () => a.onDeleteImages([id]),
        destructive: true,
      ),
      action(
        'img2img',
        l.drop_img2img,
        Icons.image_outlined,
        () => a.onSendTo(id, GenSendTarget.img2img),
        enabled: canInput,
      ),
      action(
        'vibe',
        l.drop_vibeTransfer,
        StudioIcons.vibeLibrary,
        () => a.onSendTo(id, GenSendTarget.vibe),
        enabled: canInput && scope.data.refs.vibes != null,
      ),
      action(
        'precise',
        l.drop_characterReference,
        StudioIcons.preciseReference,
        () => a.onSendTo(id, GenSendTarget.precise),
        enabled: canInput && scope.data.refs.precise != null,
      ),
      const ImageMenuAction.divider(),
      ImageMenuAction(
        key: const Key('gen-canvas-menu-edit-group'),
        label: l.imageMenu_editAndDerive,
        icon: Icons.auto_fix_high_outlined,
        children: [
          action(
            'edit',
            l.img2img_editImage,
            Icons.edit_outlined,
            () => a.onEditImage(id),
            enabled: canInput,
          ),
          action(
            'inpaint',
            l.img2img_inpaint,
            Icons.draw_outlined,
            () => a.onInpaint(id),
            enabled: canInput,
          ),
          action(
            'variations',
            l.img2img_generateVariations,
            Icons.auto_awesome_motion_outlined,
            () => a.onVariations(id),
            enabled: canInput,
          ),
          action(
            'tools',
            l.img2img_directorTools,
            Icons.auto_fix_high_outlined,
            () => a.onSendToTools(id),
            enabled: canInput,
          ),
          action(
            'enhance',
            l.img2img_enhance,
            Icons.auto_awesome_outlined,
            () => a.onEnhance(id),
            enabled: canInput,
          ),
          action(
            'upscale',
            l.image_upscale,
            Icons.zoom_out_map_rounded,
            () => a.onUpscale(id),
            enabled: canInput,
          ),
        ],
      ),
      ImageMenuAction(
        key: const Key('gen-canvas-menu-more-group'),
        label: l.imageMenu_more,
        icon: Icons.more_horiz,
        children: [
          action(
            'precise-library',
            l.drop_saveToPreciseRefLibrary,
            Icons.bookmark_add_outlined,
            () => run(
              () => saveBytesToPreciseRefLibrary(ref, context, image.bytes),
            ),
            enabled: canInput,
          ),
          action(
            'reveal',
            l.shortcut_action_open_folder,
            Icons.folder_open,
            () => a.onReveal(id),
            enabled: image.canSave,
          ),
          action(
            'krita',
            l.gallery_sendToKritaAction,
            Icons.brush_outlined,
            () => KritaSendHelper.sendImageBytes(
              context,
              ref,
              image.bytes,
              name: GeneratedImageActions(ref).previewImageFileName(image),
            ),
            enabled: canInput,
          ),
        ],
      ),
    ],
  );
  if (context.mounted) selected?.call();
}
