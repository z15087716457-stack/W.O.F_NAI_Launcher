import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/localization_extension.dart';
import '../../../../services/image_workflow_launcher.dart';
import '../../../../widgets/common/draggable_memory_image.dart';
import '../../../../widgets/common/selectable_image_card.dart';
import '../../../../widgets/image_editor/image_editor_screen.dart';
import '../../../../utils/krita_send_helper.dart';
import '../../../../utils/precise_ref_library_import_helper.dart';
import '../../../../providers/generation/generation_models.dart';
import 'generated_image_actions.dart';

/// 生成图卡片装配助手。
///
/// 历史预览网格与 G11 画布 tile 共用同一套 SelectableImageCard 装配：
/// 右键菜单、详情页、发送到工作流、拖拽注入（DraggableMemoryImage）全保留。
/// 调用方可通过 [onTap] 覆盖点击语义（画布内 tap=仅选中，不弹详情；
/// 预览网格默认仍走全屏详情），或用 [enableHoverScale] 关掉画布里
/// 会造成世界抖动的 hover 放大。
Widget buildGeneratedImageCard({
  required BuildContext context,
  required WidgetRef ref,
  required GeneratedImage image,
  required bool showIndex,
  int? index,
  bool isSelected = false,
  VoidCallback? onTap,
  bool enableHoverScale = true,
}) {
  final actions = GeneratedImageActions(ref);
  final imageBytes = image.bytes;
  final canUseAsInput = image.canUseAsGenerationInput;
  final isFailedSnapshot = image.isFailedStreamSnapshot;

  final card = SelectableImageCard(
    imageBytes: imageBytes,
    sourceFilePath: image.filePath,
    index: index,
    showIndex: showIndex,
    isSelected: isSelected,
    enableSelection: false,
    enableHoverScale: enableHoverScale,
    enableSaveAction: image.canSave,
    enableCopyAction: image.canSave,
    statusBadgeLabel: isFailedSnapshot
        ? context.l10n.generation_failedStreamSnapshot
        : null,
    statusBadgeTooltip: isFailedSnapshot
        ? context.l10n.generation_failedStreamSnapshotHint
        : null,
    onTap: onTap ?? () => actions.showFullscreenImage(context, image),
    onImageToImage: canUseAsInput
        ? () => actions.sendToImageToImage(context, image)
        : null,
    onVibeTransfer: canUseAsInput
        ? () => unawaited(actions.sendToVibeTransfer(context, image))
        : null,
    onPreciseReference: canUseAsInput
        ? () => unawaited(actions.sendToPreciseReference(context, image))
        : null,
    onSaveToPreciseRefLibrary: canUseAsInput
        ? () => unawaited(
            saveBytesToPreciseRefLibrary(ref, context, image.bytes),
          )
        : null,
    onEditImage: canUseAsInput
        ? () => ImageWorkflowLauncher.openEditor(
            context,
            ref,
            imageBytes,
            mode: ImageEditorMode.edit,
          )
        : null,
    onInpaint: canUseAsInput
        ? () => ImageWorkflowLauncher.openInpaint(context, ref, imageBytes)
        : null,
    onGenerateVariations: canUseAsInput
        ? () => ImageWorkflowLauncher.generateVariations(
            context,
            ref,
            imageBytes,
          )
        : null,
    onDirectorTools: canUseAsInput
        ? () => ImageWorkflowLauncher.openDirectorTools(
            context,
            ref,
            imageBytes,
          )
        : null,
    onEnhance: canUseAsInput
        ? () => ImageWorkflowLauncher.openEnhance(ref, imageBytes)
        : null,
    onUpscale: canUseAsInput
        ? () => ImageWorkflowLauncher.openUpscale(ref, imageBytes)
        : null,
    onSendToKrita: canUseAsInput
        ? () => KritaSendHelper.sendImageBytes(
            context,
            ref,
            imageBytes,
            name: actions.previewImageFileName(image),
          )
        : null,
    onOpenInExplorer: image.canSave
        ? () => actions.openImageInExplorer(context, image)
        : null,
    onSaveToLibrary: canUseAsInput
        ? (bytes, _) => actions.showSaveToLibraryDialog(context, bytes)
        : null,
  );

  if (!image.canDrag) {
    return card;
  }

  return DraggableMemoryImage(
    imageId: image.id,
    imageBytes: imageBytes,
    feedbackPixelWidth: image.width,
    feedbackPixelHeight: image.height,
    feedbackFormat: 'PNG',
    fileName: actions.previewImageFileName(image),
    sourceFilePath: image.filePath,
    child: card,
  );
}
