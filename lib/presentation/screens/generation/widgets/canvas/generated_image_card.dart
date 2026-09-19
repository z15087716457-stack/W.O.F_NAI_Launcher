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

  /// 画布 tile 轻量模式：关 hover 特效/光泽/分享预热/右键菜单/拖拽包装。
  ///
  /// 画布滑动时 tile 批量滑过光标会连环触发 onEnter→warmUp（写临时文件
  /// +isolate 编解码）和 hover setState，是滑卡卡死的主因；画布上动作面
  /// 由 CanvasTileToolbar（R3）承担，右键菜单与拖拽暂不在画布提供。
  bool canvasTile = false,

  /// 解码降采样（0.5=半尺寸解码）。画布 tile 按自然像素布局，全尺寸
  /// 解码 + 双阴影在相机逐帧 Transform 下是 GPU/内存炸弹。
  double? decodeScale,
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
    enableHoverScale: canvasTile ? false : enableHoverScale,
    // 右键菜单保留兜底（详情/发送到工作流），只是不再有 hover 特效与预热。
    enableContextMenu: true,
    enableGlossEffect: !canvasTile,
    hoverEffectsEnabled: !canvasTile,
    shareWarmupEnabled: !canvasTile,
    decodeScale: decodeScale,
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

  // 画布 tile 不挂拖拽（避免 hover→warmUp 预热写盘）；canDrag 兜底同原。
  if (canvasTile || !image.canDrag) {
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
