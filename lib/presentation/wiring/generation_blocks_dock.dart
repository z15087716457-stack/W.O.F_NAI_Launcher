import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pill_roll_coordinator.dart';
import '../providers/pill_workspace_provider.dart';
import '../utils/prompt_block_bundle_insertion.dart';
import 'blocks_preferences.dart';
import 'generation_backend.dart';

Future<void> insertGenerationDockBlock(
  WidgetRef ref,
  String id, {
  required String fallbackScope,
}) async {
  final recent = ref.read(blocksPreferencesProvider.notifier);
  final target = ref.read(pillActiveEditorTargetProvider);
  final scope = target?.scope ?? fallbackScope;
  final write = ref
      .read(generationBackendProvider)
      .captureDraft(
        nextRequest: true,
        alive: () =>
            ref.context.mounted &&
            ref.read(pillActiveEditorTargetProvider) == target,
      );
  await write(() {
    final lane = pillWorkspaceProvider(scope);
    final offset = (target?.caret ?? ref.read(lane).document.text.length).clamp(
      0,
      ref.read(lane).document.text.length,
    );
    insertPromptBlockBundle(ref, scope: scope, offset: offset, blockId: id);
    ref
        .read(pillRollCoordinatorProvider)
        .syncLaneProjection(scope, ref.read(lane).projection);
    if (scope == PillScopes.main || scope == PillScopes.negative) {
      final paired = pillWorkspaceProvider(
        scope == PillScopes.main ? PillScopes.negative : PillScopes.main,
      );
      ref
          .read(pillRollCoordinatorProvider)
          .syncLaneProjection(
            scope == PillScopes.main ? PillScopes.negative : PillScopes.main,
            ref.read(paired).projection,
          );
    }
  });
  await recent.recordUse(id);
}
