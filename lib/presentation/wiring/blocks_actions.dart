import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/api_constants.dart';
import '../../core/utils/localization_extension.dart';
import '../../core/utils/prompt_block_exchange.dart';
import '../../data/models/prompt_block/prompt_block.dart';
import '../../data/models/prompt_block/prompt_block_folder.dart';
import '../../data/repositories/prompt_block_repository.dart';
import '../providers/character_prompt_provider.dart';
import '../providers/image_generation_provider.dart';
import '../providers/pill_roll_coordinator.dart';
import '../providers/pill_workspace_provider.dart';
import '../providers/prompt_block_library_provider.dart';
import '../router/app_router.dart';
import '../widgets/prompt/blocks/curation_import_preview_dialog.dart';
import '../widgets/prompt/blocks/prompt_block_folder_delete_dialog.dart';
import '../ui/blocks/blocks_contract.dart';
import '../ui/blocks/blocks_edit.dart';
import '../ui/kit/ui_dialog.dart';
import '../utils/prompt_block_bundle_insertion.dart';
import '../utils/prompt_block_generation_settings_applier.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/themed_confirm_dialog.dart';
import 'blocks_generation_target.dart';
import 'blocks_library_backend.dart';
import 'blocks_mapping.dart';
import 'blocks_platform.dart';
import 'blocks_preferences.dart';

const blocksParamCatalog = BlockParamCatalog(
  models: ImageModels.modelDisplayNames,
  samplers: Samplers.samplerDisplayNames,
  noiseSchedules: NoiseSchedules.displayNames,
);
final blocksLibrarySelectionProvider = StateProvider<String?>((ref) => null);

class BlocksActions {
  BlocksActions(this.ref, this.context, this.alive);
  final WidgetRef ref;
  final BuildContext context;
  final bool Function() alive;
  BlocksLibraryBackend get backend => ref.read(blocksLibraryBackendProvider);

  Future<T?> run<T>(Future<T> Function() operation) async {
    try {
      if ((!alive() || !context.mounted)) return null;
      return await operation();
    } catch (error) {
      if (alive() && context.mounted) {
        AppToast.error(
          context,
          context.l10n.promptBlockLibrary_importFailed('$error'),
        );
      }
      return null;
    }
  }

  void preference(BlocksPreferences Function(BlocksPreferences) change) {
    final notifier = ref.read(blocksPreferencesProvider.notifier);
    unawaited(run(() => notifier.change(change)));
  }

  Future<void> insert(
    List<String> ids, {
    String fallbackScope = PillScopes.main,
    ({String scope, int caret})? at,
    ValueChanged<int>? onInserted,
  }) async {
    final guard = ref.read(blocksGenerationTargetProvider);
    final recent = ref.read(blocksPreferencesProvider.notifier);
    final laneBefore = at == null
        ? null
        : ref.read(pillWorkspaceProvider(at.scope)).document;
    await run(() async {
      final library = await ref.read(promptBlockLibraryNotifierProvider.future);
      if (!alive() || !context.mounted) return;
      final blocks = [
        for (final id in ids.toSet())
          if (library.blockById(id) case final block?) block,
      ];
      if (blocks.isEmpty) return;
      final committed = await guard.commit(
        () {
          final target = at ?? ref.read(pillActiveEditorTargetProvider);
          final scope = target?.scope ?? fallbackScope;
          final params = ref.read(generationParamsNotifierProvider);
          void seed(String laneScope, String text) {
            final lane = pillWorkspaceProvider(laneScope);
            if (!ref.exists(lane)) {
              ref.read(lane.notifier).syncFromPlainText(text);
            }
          }

          seed(PillScopes.main, params.prompt);
          seed(PillScopes.negative, params.negativePrompt);
          for (final c
              in ref.read(characterPromptNotifierProvider).characters) {
            if (scope == PillScopes.charPos(c.id) ||
                scope == PillScopes.charNeg(c.id)) {
              seed(PillScopes.charPos(c.id), c.prompt);
              seed(PillScopes.charNeg(c.id), c.negativePrompt);
            }
          }
          var caret =
              (target?.caret ??
                      ref
                          .read(pillWorkspaceProvider(scope))
                          .document
                          .text
                          .length)
                  .clamp(
                    0,
                    ref.read(pillWorkspaceProvider(scope)).document.text.length,
                  );
          for (final b in blocks) {
            caret += insertPromptBlockBundle(
              ref,
              scope: scope,
              offset: caret,
              blockId: b.id,
            );
          }
          ref.read(pillActiveEditorTargetProvider.notifier).state = (
            scope: scope,
            caret: caret,
          );
          for (final lane in PillWorkspaceNotifier.activeScopes.toList()) {
            ref
                .read(pillRollCoordinatorProvider)
                .syncLaneProjection(
                  lane,
                  ref.read(pillWorkspaceProvider(lane)).projection,
                );
          }
          onInserted?.call(caret);
        },
        alive: alive,
        unchanged: () =>
            blocks.every((b) => backend.library.blockById(b.id) == b) &&
            (at == null ||
                ref.read(pillWorkspaceProvider(at.scope)).document ==
                    laneBefore),
      );
      if (committed) {
        for (final b in blocks) {
          await recent.recordUse(b.id);
        }
        if (alive() && context.mounted) {
          AppToast.success(context, context.l10n.blocks_insertToPrompt);
        }
      }
    });
  }

  Future<void> applyParams(String id) async {
    final block = backend.requireBlock(id);
    final settings = block.generationSettings;
    if (settings == null || settings.isEmpty) return;
    final guard = ref.read(blocksGenerationTargetProvider);
    await run(() async {
      validatePromptBlockGenerationSettings(
        settings,
        settings.model ?? ref.read(generationParamsNotifierProvider).model,
      );
      final committed = await guard.commit(
        () => applyPromptBlockGenerationSettings(ref, settings),
        alive: alive,
        unchanged: () => backend.library.blockById(id) == block,
      );
      if (committed && alive() && context.mounted) {
        AppToast.success(
          context,
          context.l10n.promptBlockLibrary_settingsApplied,
        );
      }
    });
  }

  Future<BlockParams?> captureParams() async {
    final p = ref.read(generationParamsNotifierProvider);
    return BlockParams(
      model: p.model,
      steps: p.steps,
      scale: p.scale,
      cfgRescale: p.cfgRescale,
      sampler: p.sampler,
      noiseSchedule: p.noiseSchedule,
    );
  }

  Future<PromptBlock?> edit({
    String? id,
    String? initialContent,
    String? folderId,
    BlockDraft? initialDraft,
  }) async {
    final service = backend;
    final library = service.library;
    final existing = id == null ? null : service.requireBlock(id);
    final block = existing == null ? null : blockDataOf(existing, library);
    final platform = ref.read(blocksPlatformProvider);
    var deleting = false;
    var decided = false;
    void finish(BuildContext dialog, BlockDraft? value) {
      if (decided || !dialog.mounted) return;
      decided = true;
      Navigator.of(dialog).pop(value);
    }

    final draft = await showDialog<BlockDraft>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => Material(
        type: MaterialType.transparency,
        child: UiModal(
          child: const SizedBox.shrink(),
          onDismiss: () => finish(ctx, null),
          dialog: (_) => BlockEditDialog(
            data: BlockEditData(
              blockId: id,
              draft:
                  initialDraft ??
                  (block == null
                      ? BlockDraft(
                          folderId: folderId,
                          atoms: initialContent == null ? const [] : null,
                          text: initialContent,
                        )
                      : existing!.atoms == null
                      ? BlockDraft.of(
                          block,
                        ).copyWith(plain: true, text: existing.content)
                      : BlockDraft.of(block)),
              folders: blockFoldersOf(library, {}),
              tags: mapBlocksLibrary(library).tags.map((t) => t.tag).toList(),
              catalog: blocksParamCatalog,
              sourcePath: block?.sourcePath,
              importedAt: block?.importedAt,
              sourceState: block?.sourceState ?? BlockSourceState.none,
            ),
            actions: BlockEditActions(
              onSave: (value) => finish(ctx, value),
              onCancel: () => finish(ctx, null),
              onDelete: id == null
                  ? null
                  : () {
                      if (!decided) {
                        deleting = true;
                        finish(ctx, null);
                      }
                    },
              onPickThumbnail: () =>
                  run<BlockThumbPick?>(platform.pickThumbnail),
              onCaptureParams: captureParams,
            ),
          ),
        ),
      ),
    );
    if (!alive() || !context.mounted) return null;
    if (deleting && id != null) {
      await delete([id]);
      return null;
    }
    if (draft == null) return null;
    return run(() => service.save(draft, id: id, expected: existing));
  }

  Future<void> delete(List<String> ids) async {
    final service = backend;
    final deletion = await run(() => service.delete(ids));
    if (deletion == null || (!alive() || !context.mounted)) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(context.l10n.promptBlockLibrary_deleted),
        action: SnackBarAction(
          label: context.l10n.common_undo,
          onPressed: () => unawaited(run(() => service.undo(deletion))),
        ),
      ),
    );
  }

  Future<void> transfer(
    List<String> ids,
    PromptBlockTransferTarget target,
    BlocksDropMode mode, {
    String? sourceCollectionId,
  }) async {
    final service = backend;
    if (target.kind == PromptBlockTransferKind.collection) {
      await run(
        () => service.addToCollection(
          ids,
          target.id!,
          sourceCollectionId: mode == BlocksDropMode.move
              ? sourceCollectionId
              : null,
        ),
      );
      return;
    }
    final snapshots = [for (final id in ids.toSet()) service.requireBlock(id)];
    final conflicts = service.notifier.transferConflictCount(ids, target);
    if (conflicts > 0) {
      final confirmed = await ThemedConfirmDialog.show(
        context: context,
        title: context.l10n.common_confirm,
        content: context.l10n.blockOrganizer_replaceMoveBody(conflicts),
      );
      if (!confirmed || (!alive() || !context.mounted)) return;
    }
    await run(
      () => service.serialize(() async {
        if (!snapshots.every((b) => service.library.blockById(b.id) == b)) {
          throw StateError(context.l10n.bridge_conflict);
        }
        await service.notifier.transferBlocks(
          ids,
          target,
          mode == BlocksDropMode.move
              ? PromptBlockTransferMode.move
              : PromptBlockTransferMode.copy,
          sourceCollectionId: sourceCollectionId,
        );
      }),
    );
  }

  Future<void> deleteFolder(String id) async {
    final service = backend;
    final library = service.library;
    final folder = library.folderById(id);
    if (folder == null) return;
    final descendants = library.folders.getDescendantIds(id);
    final decision = await PromptBlockFolderDeleteDialog.show(
      context: context,
      folder: folder,
      destinationFolders: library.folders
          .where((f) => f.id != id && !descendants.contains(f.id))
          .toList(),
    );
    if (decision == null || (!alive() || !context.mounted)) return;
    await run(
      () => service.serialize(
        () => service.notifier.deleteFolder(
          id,
          mode: decision.mode,
          destinationFolderId: decision.destinationFolderId,
        ),
      ),
    );
  }

  Future<void> importTxt() async {
    final service = backend;
    final platform = ref.read(blocksPlatformProvider);
    final scope = ref.read(blocksPreferencesProvider).valueOrNull?.scope;
    await run(() async {
      final paths = await platform.pickTxt(
        context.l10n.promptBlockLibrary_importTxtTitle,
      );
      if (paths.isEmpty || (!alive() || !context.mounted)) return;
      final result = await service.serialize(
        () => service.notifier.importTxtFiles(
          paths: paths,
          folderId: scope?.kind == BlocksScopeKind.folder ? scope!.id : null,
        ),
      );
      if (alive() && context.mounted) {
        AppToast.success(
          context,
          context.l10n.promptBlockLibrary_txtImportDone(
            result.created,
            result.skipped,
          ),
        );
      }
    });
  }

  Future<void> importFolder() async {
    final service = backend;
    final platform = ref.read(blocksPlatformProvider);
    final l10n = context.l10n;
    await run(() async {
      final root = await platform.pickDirectory(
        l10n.promptBlockLibrary_curationTitle,
      );
      if (root == null || (!alive() || !context.mounted)) return;
      final files = await PromptBlockExchange.scanTxtDirectory(root);
      if ((!alive() || !context.mounted)) return;
      if (files.isEmpty) {
        AppToast.warning(context, l10n.promptBlockLibrary_curationEmpty);
        return;
      }
      final library = service.library;
      final plan = PromptBlockExchange.buildPlan(
        files: files,
        library: PromptBlockLibraryData(
          blocks: library.blocks,
          folders: library.folders,
        ),
        folderChainOf: (file) =>
            PromptBlockExchange.curationFolderChain(file, root),
      );
      final decision = await CurationImportPreviewDialog.show(
        context: context,
        rootPath: root,
        plan: plan,
      );
      if (decision == null || (!alive() || !context.mounted)) return;
      final result = await service.serialize(
        () => service.notifier.applyExchangePlan(
          plan,
          updateChanged: decision.updateChanged,
        ),
      );
      if (alive() && context.mounted) {
        AppToast.success(
          context,
          l10n.promptBlockLibrary_curationDone(
            result.created,
            result.updated,
            result.skipped,
          ),
        );
      }
    });
  }

  void showInLibrary(String? id) {
    final selection = ref.read(blocksLibrarySelectionProvider.notifier);
    if (id != null && selection.state == id) {
      selection.state = null;
    }
    selection.state = id;
    preference((p) => p.copyWith(scope: const BlocksScope.all()));
    context.go(AppRoutes.promptBlockLibrary);
  }
}
