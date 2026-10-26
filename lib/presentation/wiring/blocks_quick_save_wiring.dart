import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/localization_extension.dart';
import '../../core/utils/pill_roll_engine.dart';
import '../providers/pill_roll_coordinator.dart';
import '../providers/pill_workspace_provider.dart';
import '../providers/prompt_block_library_provider.dart';
import '../ui/blocks/blocks_contract.dart';
import '../ui/blocks/blocks_quick.dart';
import '../ui/kit/ui_dialog.dart';
import '../utils/prompt_block_bundle_insertion.dart';
import '../widgets/common/app_toast.dart';
import 'blocks_actions.dart';
import 'blocks_generation_target.dart';
import 'blocks_library_backend.dart';
import 'blocks_mapping.dart';
import 'blocks_preferences.dart';

Future<void> showBlockQuickSave(
  BuildContext context,
  WidgetRef ref,
  TextEditingController controller, {
  String? scope,
  ValueChanged<String>? onChanged,
}) async {
  final before = controller.value;
  final selection = before.selection;
  if (!selection.isValid || selection.isCollapsed) return;
  final selected = selection.textInside(before.text);
  final atoms = PillRollEngine.splitTopLevelAtoms(selected);
  if (atoms.isEmpty) return;
  final library = ref.read(promptBlockLibraryNotifierProvider).valueOrNull;
  if (library == null) return;
  final backend = ref.read(blocksLibraryBackendProvider);
  final guard = ref.read(blocksGenerationTargetProvider);
  final preferencesNotifier = ref.read(blocksPreferencesProvider.notifier);
  final prefs =
      ref.read(blocksPreferencesProvider).valueOrNull ??
      const BlocksPreferences();
  final laneBefore = scope == null
      ? null
      : ref.read(pillWorkspaceProvider(scope)).document;
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
            color: Color(prefs.quickColor),
            folders: blockFoldersOf(library, prefs.expanded),
            replaceSelection: scope != null && prefs.replaceSelection,
          ),
          actions: BlockQuickSaveActions(
            onSave: (draft) => Navigator.of(ctx).pop(draft),
            onCancel: () => Navigator.of(ctx).pop(),
          ),
        ),
      ),
    ),
  );
  if (result == null || !context.mounted) return;
  final host = BlocksActions(ref, context, () => context.mounted);
  await host.run(() async {
    final block = await backend.save(
      BlockDraft(
        title: result.title,
        atoms: result.atoms,
        color: result.color,
        icon: result.icon,
        folderId: result.folderId,
      ),
    );
    await preferencesNotifier.change(
      (p) => p.copyWith(
        quickColor: result.color.toARGB32(),
        replaceSelection: result.replaceSelection,
      ),
    );
    if (!context.mounted) return;
    if (result.replaceSelection && scope != null) {
      final committed = await guard.commit(
        () {
          final notifier = ref.read(pillWorkspaceProvider(scope).notifier);
          late int added;
          notifier.editAsSingleStep(() {
            notifier.setText(
              before.text.replaceRange(selection.start, selection.end, ''),
            );
            added = insertPromptBlockBundle(
              ref,
              scope: scope,
              offset: selection.start,
              blockId: block.id,
            );
          });
          final next = ref.read(pillWorkspaceProvider(scope)).document.text;
          controller.value = TextEditingValue(
            text: next,
            selection: TextSelection.collapsed(offset: selection.start + added),
          );
          onChanged?.call(next);
          ref.read(pillActiveEditorTargetProvider.notifier).state = (
            scope: scope,
            caret: selection.start + added,
          );
          for (final lane in PillWorkspaceNotifier.activeScopes.toList()) {
            ref
                .read(pillRollCoordinatorProvider)
                .syncLaneProjection(
                  lane,
                  ref.read(pillWorkspaceProvider(lane)).projection,
                );
          }
        },
        alive: () => context.mounted,
        unchanged: () =>
            controller.text == before.text &&
            controller.selection == selection &&
            ref.read(pillWorkspaceProvider(scope)).document == laneBefore,
      );
      if (committed) {
        await preferencesNotifier.recordUse(block.id);
      }
    }
    if (context.mounted) {
      AppToast.success(context, context.l10n.blocks_saveAsBlock);
    }
  });
}
