import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/utils/file_explorer_utils.dart';
import '../services/image_clipboard_service.dart';
import '../../core/utils/localization_extension.dart';
import '../../core/utils/pill_roll_engine.dart';
import '../../data/models/gallery/nai_image_metadata.dart';
import '../../data/repositories/gallery_category_repository.dart';
import '../../data/repositories/gallery_folder_repository.dart';
import '../providers/gallery_category_provider.dart';
import '../providers/image_generation_provider.dart';
import '../providers/local_gallery_provider.dart';
import '../providers/prompt_block_library_provider.dart';
import '../services/image_workflow_launcher.dart';
import '../ui/blocks/blocks_contract.dart';
import '../ui/blocks/blocks_quick.dart';
import '../ui/kit/ui_dialog.dart';
import '../ui/viewer/viewer_contract.dart';
import '../utils/asset_protection_guard.dart';
import '../utils/krita_send_helper.dart';
import '../utils/local_gallery_reference_factory.dart';
import '../utils/metadata_import_coordinator.dart';
import '../utils/precise_ref_library_import_helper.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/image_detail/file_image_detail_data.dart';
import '../widgets/common/image_detail/image_detail_data.dart';
import '../widgets/common/precise_reference_type_dialog.dart';
import '../widgets/drop/image_destination_dialog.dart';
import '../widgets/gallery/category_picker_dialog.dart';
import 'image_viewer_generation_target.dart';

String? viewerSourcePath(ImageDetailData source) => switch (source) {
  final LocalImageDetailData image => image.record.path,
  final FileImageDetailData image => image.filePath,
  _ => source.fileInfo?.path,
};

class ImageViewerActionHost {
  ImageViewerActionHost(this.context, this.ref, this.alive);
  final BuildContext context;
  final WidgetRef ref;
  final bool Function() alive;

  void _success(String text) {
    if (alive() && context.mounted) {
      AppToast.success(context, text);
    }
  }

  Future<bool> perform(
    ImageDetailData source,
    ViewerAction action,
    NaiImageMetadata? metadata,
  ) async {
    final path = viewerSourcePath(source);
    final l10n = context.l10n;
    if (!alive() || !context.mounted) {
      return false;
    }
    if (action == ViewerAction.copyPath) {
      if (path == null) {
        return false;
      }
      await Clipboard.setData(ClipboardData(text: path));
    } else if (action == ViewerAction.copyAllPrompts) {
      if (metadata == null || metadata.fullPrompt.isEmpty) {
        return false;
      }
      await Clipboard.setData(ClipboardData(text: metadata.fullPrompt));
    } else if (action == ViewerAction.showInFolder) {
      if (path == null) {
        return false;
      }
      await FileExplorerUtils.revealFile(path);
      return false;
    } else if (action == ViewerAction.copyImage) {
      await ref
          .read(imageClipboardServiceProvider)
          .copyBytes(
            source.getImageBytes,
            fileName: path == null ? 'shared.png' : p.basename(path),
          );
      _success(l10n.image_copiedToClipboard);
      return false;
    } else if (action == ViewerAction.saveAsBlock) {
      await _saveBlock(metadata?.prompt ?? '');
      return false;
    } else if (action == ViewerAction.moveTo || action == ViewerAction.copyTo) {
      if (path != null) {
        await _transfer(path, move: action == ViewerAction.moveTo);
      }
      return false;
    } else if (action == ViewerAction.saveToRefLibrary) {
      final bytes = await source.getImageBytes();
      if (alive() && context.mounted) {
        await saveBytesToPreciseRefLibrary(
          ref,
          context,
          bytes,
          suggestedName: path == null ? null : p.basenameWithoutExtension(path),
        );
      }
      return false;
    } else if (action == ViewerAction.krita) {
      final bytes = await source.getImageBytes();
      if (alive() && context.mounted) {
        KritaSendHelper.sendImageBytes(
          context,
          ref,
          bytes,
          name: path == null ? 'generated.png' : p.basename(path),
        );
      }
      return false;
    } else {
      final commit = ref
          .read(imageViewerGenerationTargetProvider)
          .capture(alive: alive);
      final bytes = await source.getImageBytes();
      if (!alive() || !context.mounted) {
        return false;
      }
      if (action == ViewerAction.reuse) {
        final result = await ImageDestinationDialog.show(
          context,
          imageBytes: bytes,
          fileName: path == null ? 'generated.png' : p.basename(path),
          metadata: metadata,
        );
        if (result == null || !alive() || !context.mounted) {
          return false;
        }
        switch (result.destination) {
          case ImageDestination.extractMetadata:
            if (result.selection == null || metadata == null) {
              return false;
            }
            var count = 0;
            await commit(() async {
              count = await MetadataImportCoordinator.applyOfficialSelection(
                read: ref.read,
                metadata: metadata,
                selection: result.selection!,
              );
            });
            _success(l10n.metadataImport_appliedCount(count));
            return true;
          case ImageDestination.img2img:
            action = ViewerAction.img2img;
          case ImageDestination.vibeTransfer:
          case ImageDestination.vibeTransferRaw:
            action = ViewerAction.styleTransfer;
          case ImageDestination.characterReference:
            action = ViewerAction.preciseRef;
          case ImageDestination.vibeTransferReuse:
          case ImageDestination.saveToVibeLibrary:
            return false;
        }
      }
      if (!alive() || !context.mounted) {
        return false;
      }
      if (action == ViewerAction.preciseRef) {
        final type = await PreciseReferenceTypeDialog.show(context);
        if (type == null || !alive() || !context.mounted) {
          return false;
        }
        if (ref
                .read(generationParamsNotifierProvider)
                .preciseReferences
                .length >=
            16) {
          throw StateError(l10n.toast_styleReferenceLimit(16));
        }
        await commit(() {
          unawaited(
            ref
                .read(generationParamsNotifierProvider.notifier)
                .addPreciseReferenceFromImage(bytes, type: type),
          );
        });
        _success(l10n.drop_addedToCharacterRef);
      } else if (action == ViewerAction.styleTransfer) {
        if (ref
                .read(generationParamsNotifierProvider)
                .vibeReferencesV4
                .length >=
            16) {
          throw StateError(l10n.toast_styleReferenceLimit(16));
        }
        await commit(() {
          ref
              .read(generationParamsNotifierProvider.notifier)
              .addVibeReference(
                LocalGalleryReferenceFactory.createRawStyleReference(
                  fileName: path == null ? 'generated.png' : p.basename(path),
                  imageBytes: bytes,
                ),
              );
        });
        _success(l10n.drop_addedToVibe);
      } else if (action == ViewerAction.img2img) {
        await commit(() => ImageWorkflowLauncher.openImageToImage(ref, bytes));
        _success(l10n.gallery_sentToImg2Img);
      } else if (action == ViewerAction.upscale) {
        await commit(() => ImageWorkflowLauncher.openUpscale(ref, bytes));
        if (alive() && context.mounted) {
          AppToast.info(context, l10n.gallery_upscalePanelLoaded);
        }
      } else {
        return false;
      }
      return true;
    }
    _success(
      action == ViewerAction.copyPath
          ? l10n.common_copied
          : l10n.localGallery_promptCopied,
    );
    return false;
  }

  Future<void> _saveBlock(String prompt) async {
    final atoms = PillRollEngine.splitTopLevelAtoms(prompt);
    if (atoms.isEmpty) {
      return;
    }
    final library = await ref.read(promptBlockLibraryNotifierProvider.future);
    if (!alive() || !context.mounted) {
      return;
    }
    final folders = <BlocksFolder>[];
    final visited = <String>{};
    void append(String? parent, int depth) {
      for (final folder in library.foldersIn(parent)) {
        if (!visited.add(folder.id)) {
          continue;
        }
        folders.add(
          BlocksFolder(
            id: folder.id,
            name: folder.name,
            count: library.blocksInFolderTree(folder.id).length,
            parentId: parent,
            depth: depth,
            hasChildren: library.folders.any(
              (child) => child.parentId == folder.id,
            ),
            expanded: true,
          ),
        );
        append(folder.id, depth + 1);
      }
    }

    append(null, 0);
    final result = await showDialog<BlockQuickDraft>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Material(
        type: MaterialType.transparency,
        child: UiModal(
          child: const SizedBox.shrink(),
          onDismiss: () => Navigator.of(ctx).pop(),
          dialog: (_) => BlockQuickSave(
            data: BlockQuickSaveData(
              atoms: atoms,
              title: atoms.first,
              folders: folders,
              replaceSelection: false,
            ),
            actions: BlockQuickSaveActions(
              onSave: (draft) => Navigator.of(ctx).pop(draft),
              onCancel: () => Navigator.of(ctx).pop(),
            ),
          ),
        ),
      ),
    );
    if (result == null || !alive() || !context.mounted) {
      return;
    }
    await ref
        .read(promptBlockLibraryNotifierProvider.notifier)
        .createBlock(
          title: result.title,
          content: result.atoms.join(', '),
          atoms: result.atoms,
          color:
              '#${result.color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}',
          iconName: result.icon,
          folderId: result.folderId,
        );
    _success(
      context.mounted
          ? context.l10n.blocks_saveAsBlock
          : currentL10n.blocks_saveAsBlock,
    );
  }

  Future<void> _transfer(String path, {required bool move}) async {
    final l10n = context.l10n;
    final pick = await CategoryPickerDialog.show(
      context,
      title: move ? l10n.localGallery_moveTo : l10n.localGallery_copyTo,
    );
    if (pick == null || !alive() || !context.mounted) {
      return;
    }
    final target = pick.category;
    if (move) {
      final sourceExternal = await GalleryFolderRepository.instance
          .isExtraRootPath(path);
      final targetExternal = target?.isExternal ?? false;
      if (!alive() || !context.mounted) {
        return;
      }
      if (sourceExternal || targetExternal) {
        final content = sourceExternal && targetExternal
            ? l10n.localGallery_externalBothMoveConfirmContent(
                1,
                target?.displayName ?? '',
              )
            : sourceExternal
            ? l10n.localGallery_externalSourceMoveConfirmContent(1)
            : l10n.localGallery_externalTargetMoveConfirmContent(
                1,
                target?.displayName ?? '',
              );
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.localGallery_externalSourceMoveConfirmTitle),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.common_cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.common_confirm),
              ),
            ],
          ),
        );
        if (confirmed != true || !alive() || !context.mounted) {
          return;
        }
      }
    }
    final confirmed = await AssetProtectionGuard.confirmDangerousAction(
      context: context,
      ref: ref,
      title: move
          ? l10n.localGallery_confirmMoveImageTitle
          : l10n.localGallery_copyTo,
      content: move
          ? l10n.localGallery_confirmMoveImageContent
          : l10n.localGallery_confirmCopyContent,
      confirmText: move ? l10n.localGallery_confirmMove : l10n.common_confirm,
      icon: move ? Icons.drive_file_move_outline : Icons.file_copy_outlined,
    );
    if (!confirmed || !alive() || !context.mounted) {
      return;
    }
    final result = move
        ? await GalleryCategoryRepository.instance.moveImageToCategory(
            path,
            target,
          )
        : await GalleryCategoryRepository.instance.copyImageToCategory(
            path,
            target,
          );
    if (result == null) {
      throw StateError(
        move
            ? l10n.localGallery_moveImagesFailed
            : l10n.localGallery_copyFailed,
      );
    }
    await ref.read(localGalleryNotifierProvider.notifier).refresh(scan: !move);
    await ref.read(galleryCategoryNotifierProvider.notifier).refresh();
    _success(
      move
          ? l10n.localGallery_imageMovedToCategory
          : l10n.localGallery_copySuccess(1),
    );
  }
}
