import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/localization_extension.dart';
import '../providers/image_generation_provider.dart';
import '../screens/generation/widgets/canvas/generated_image_actions.dart';
import '../ui/gen/gen_contract.dart';
import '../ui/gen/gen_page.dart';
import '../ui/gen/gen_parts.dart';
import '../ui/kit/ui_glyph.dart';
import '../ui/kit/ui_menu.dart';
import '../ui/kit/ui_popover.dart';
import '../utils/krita_send_helper.dart';
import '../utils/precise_ref_library_import_helper.dart';
import 'generation_operations.dart';

/// 使用新页面菜单外观，接回旧图块的图片操作；菜单对象始终是右击的图。
void openGenerationCanvasMenu(
  BuildContext context,
  WidgetRef ref,
  GeneratedImage image,
  Offset position,
) {
  final scope = GenScope.of(context);
  final a = scope.actions;
  final l = context.l10n;
  final id = image.id;
  final canInput = image.canUseAsGenerationInput && !scope.data.canvas.locked;
  final operations = GenerationOperations(ref, context, () => context.mounted);
  void run(Future<void> Function() task) => operations.run(task);
  scope.controller.openMenu(
    UiPopoverAnchor(position),
    [
      UiMenuItem(
        key: const Key('gen-canvas-menu-viewer'),
        label: l.imageMenu_details,
        glyph: UiGlyphs.expand,
        onTap: () => a.onOpenViewer(id),
      ),
      UiMenuItem(
        key: const Key('gen-canvas-menu-delete'),
        label: l.common_delete,
        glyph: UiGlyphs.trash,
        danger: true,
        onTap: () => a.onDeleteImages([id]),
      ),
      UiMenuItem(
        key: const Key('gen-canvas-menu-save'),
        label: l.gen_saveImage,
        glyph: GenGlyphs.save2,
        divider: true,
        enabled: image.canSave,
        onTap: () => a.onSaveImage(id),
      ),
      UiMenuItem(
        key: const Key('gen-canvas-menu-copy'),
        label: l.gen_copyImage,
        glyph: UiGlyphs.copy,
        enabled: image.canSave,
        onTap: () => a.onCopyImage(id),
      ),
      UiMenuItem(
        key: const Key('gen-canvas-menu-reveal'),
        label: l.gen_reveal,
        glyph: GenGlyphs.reveal,
        enabled: image.canSave,
        onTap: () => a.onReveal(id),
      ),
      UiMenuItem(
        key: const Key('gen-canvas-menu-img2img'),
        label: l.gen_sendImg2Img,
        glyph: UiGlyphs.image,
        divider: true,
        enabled: canInput,
        onTap: () => a.onSendTo(id, GenSendTarget.img2img),
      ),
      UiMenuItem(
        key: const Key('gen-canvas-menu-vibe'),
        label: l.gen_sendVibe,
        glyph: UiGlyphs.palette,
        enabled: canInput && scope.data.refs.vibes != null,
        onTap: () => a.onSendTo(id, GenSendTarget.vibe),
      ),
      UiMenuItem(
        key: const Key('gen-canvas-menu-precise'),
        label: l.gen_sendPrecise,
        glyph: UiGlyphs.personStar,
        enabled: canInput && scope.data.refs.precise != null,
        onTap: () => a.onSendTo(id, GenSendTarget.precise),
      ),
      UiMenuItem(
        key: const Key('gen-canvas-menu-precise-library'),
        label: l.drop_saveToPreciseRefLibrary,
        enabled: canInput,
        onTap: () =>
            run(() => saveBytesToPreciseRefLibrary(ref, context, image.bytes)),
      ),
      UiMenuItem(
        key: const Key('gen-canvas-menu-edit'),
        label: l.gen_editImage,
        divider: true,
        enabled: canInput,
        onTap: () => a.onEditImage(id),
      ),
      UiMenuItem(
        key: const Key('gen-canvas-menu-inpaint'),
        label: l.gen_inpaint,
        enabled: canInput,
        onTap: () => a.onInpaint(id),
      ),
      UiMenuItem(
        key: const Key('gen-canvas-menu-variations'),
        label: l.gen_variations,
        enabled: canInput,
        onTap: () => a.onVariations(id),
      ),
      UiMenuItem(
        key: const Key('gen-canvas-menu-tools'),
        label: l.img2img_directorTools,
        enabled: canInput,
        onTap: () => a.onSendToTools(id),
      ),
      UiMenuItem(
        key: const Key('gen-canvas-menu-enhance'),
        label: l.gen_enhance,
        enabled: canInput,
        onTap: () => a.onEnhance(id),
      ),
      UiMenuItem(
        key: const Key('gen-canvas-menu-upscale'),
        label: l.gen_upscale,
        enabled: canInput,
        onTap: () => a.onUpscale(id),
      ),
      UiMenuItem(
        key: const Key('gen-canvas-menu-krita'),
        label: l.gallery_sendToKritaAction,
        divider: true,
        enabled: canInput,
        onTap: () => KritaSendHelper.sendImageBytes(
          context,
          ref,
          image.bytes,
          name: GeneratedImageActions(ref).previewImageFileName(image),
        ),
      ),
      UiMenuItem(
        key: const Key('gen-canvas-menu-block-library'),
        label: l.image_saveToLibrary,
        enabled: canInput,
        onTap: () => run(
          () => GeneratedImageActions(
            ref,
          ).showSaveToLibraryDialog(context, image.bytes),
        ),
      ),
    ],
    tag: ('canvas', id),
    width: 240,
  );
}
