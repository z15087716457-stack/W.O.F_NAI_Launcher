import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/gen/gen_parts.dart';

import '../providers/generation/preview_selection_provider.dart';
import '../providers/image_generation_provider.dart';
import '../providers/simple_viewer_group_batches_provider.dart';
import 'generation_history_actions.dart';

class SimpleViewerGroupControl extends ConsumerWidget {
  const SimpleViewerGroupControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => GenGroupBatchesToggle(
    grouped: ref.watch(simpleViewerGroupBatchesProvider),
    onChanged: (grouped) =>
        ref.read(simpleViewerGroupBatchesProvider.notifier).setGrouped(grouped),
  );
}

/// Only the preview owns these keys. Ancestor shortcuts must not steal arrows
/// from prompt editors (or other text fields).
class SimpleViewerNavigation extends ConsumerWidget {
  const SimpleViewerNavigation({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(imageGenerationNotifierProvider, (previous, next) {
      if (previous?.isGenerating == true &&
          !next.isGenerating &&
          ref.read(simpleViewerSingleImagesProvider)) {
        ref.read(generationPreviewSelectionProvider.notifier).clear();
      }
    });
    return Focus(
      focusNode: ref.watch(generationPreviewFocusNodeProvider),
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent ||
            !ref.read(simpleViewerSingleImagesProvider) ||
            ref.read(imageGenerationNotifierProvider).isGenerating) {
          return KeyEventResult.ignored;
        }
        final selection = ref.read(generationPreviewSelectionProvider.notifier);
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          selection.selectPrevious(singleImages: true);
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          selection.selectNext(singleImages: true);
        } else {
          return KeyEventResult.ignored;
        }
        final selected = ref.read(generationPreviewSelectionProvider);
        if (selected != null) {
          ref.read(generationHistoryActionsProvider).focusTile(selected);
        }
        return KeyEventResult.handled;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () =>
            ref.read(generationPreviewFocusNodeProvider).requestFocus(),
        child: child,
      ),
    );
  }
}
