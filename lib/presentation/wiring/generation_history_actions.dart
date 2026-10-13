import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/localization_extension.dart';
import '../providers/canvas_settings_provider.dart';
import '../providers/generation/preview_selection_provider.dart';
import '../providers/image_generation_provider.dart';
import '../screens/generation/widgets/canvas/canvas_feed_layout.dart';
import 'generation_view_mapping.dart';

final generationHistoryActionsProvider = Provider<GenerationHistoryActions>(
  GenerationHistoryActions.new,
);

class GenerationHistoryActions {
  GenerationHistoryActions(this.ref) {
    ref.onDispose(() => _disposed = true);
  }
  final Ref ref;
  bool _disposed = false;
  Future<void> _queue = Future.value();
  List<GeneratedImage> get images {
    ref.read(canvasPinnedNotifierProvider);
    final state = ref.read(imageGenerationNotifierProvider);
    return {
      for (final image in [
        ...state.mergedPanelImages,
        ...state.displayImages,
        ...ref.read(canvasPinnedNotifierProvider.notifier).images,
      ])
        image.id: image,
    }.values.toList();
  }

  GeneratedImage image(String id) =>
      images.where((image) => image.id == id).firstOrNull ??
      (throw StateError(currentL10n.bridge_conflict));
  void focusBatch(String key) {
    if (_disposed) return;
    final layout = ref.read(canvasFeedLayoutProvider);
    final group = layout.groups.where((group) => group.key == key).firstOrNull;
    if (group == null) return;
    ref.read(generationCanvasGroupSelectionProvider.notifier).selectGroup(key);
    final selected = group.images.firstOrNull;
    if (selected == null) {
      ref.read(generationPreviewSelectionProvider.notifier).clear();
    } else {
      ref.read(generationPreviewSelectionProvider.notifier).select(selected.id);
    }
    final previous = ref.read(canvasHistoryFocusRequestProvider);
    ref.read(canvasHistoryFocusRequestProvider.notifier).state = (
      group: key,
      imageId: selected?.id,
      revision: (previous?.revision ?? 0) + 1,
    );
  }

  void focusTile(String id) {
    if (_disposed) return;
    final layout = ref.read(canvasFeedLayoutProvider);
    final item = layout.items.where((item) => item.image?.id == id).firstOrNull;
    if (item == null) return;
    ref
        .read(generationCanvasGroupSelectionProvider.notifier)
        .selectTile(item.group.key, item.subimageIndex);
    ref.read(generationPreviewSelectionProvider.notifier).select(id);
  }

  void focusPins() {
    if (_disposed) return;
    final pinned = ref.read(canvasPinnedNotifierProvider.notifier).images;
    if (pinned.isEmpty) return;
    focusBatch('pin:${pinned.first.id}');
    ref.read(canvasPinboardFocusRequestProvider.notifier).state++;
  }

  Future<void> _serialize(Future<void> Function() task) {
    final pending = _queue.then((_) async {
      if (!_disposed) await task();
    });
    _queue = pending.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return pending;
  }

  Future<void> pin(String id, bool value) => _serialize(() async {
    final pins = ref.read(canvasPinnedNotifierProvider.notifier);
    if (ref.read(canvasPinnedNotifierProvider).contains(id) == value) return;
    if (value) {
      await pins.toggle(image(id));
    } else {
      await pins.remove(id);
    }
  });
  Future<void> delete(List<String> ids) => _serialize(() async {
    final targets = ids.toSet().intersection(
      images.map((image) => image.id).toSet(),
    );
    if (targets.isEmpty) return;
    final pins = ref.read(canvasPinnedNotifierProvider.notifier);
    for (final id in targets) {
      await pins.remove(id);
      if (_disposed) return;
    }
    final state = ref.read(imageGenerationNotifierProvider);
    final focus = ref.read(generationCanvasGroupSelectionProvider);
    final selected = ref.read(generationPreviewSelectionProvider);
    final group = images
        .where((image) => generationBatchKey(image) == focus?.group)
        .toList();
    final index = group.indexWhere((image) => image.id == selected);
    ref.read(imageGenerationNotifierProvider.notifier).removeImages(targets);
    if (selected != null && targets.contains(selected)) {
      final survivors = group
          .where((image) => !targets.contains(image.id))
          .toList();
      if (survivors.isNotEmpty) {
        focusTile(survivors[index.clamp(0, survivors.length - 1)].id);
      } else {
        ref.read(generationPreviewSelectionProvider.notifier).clear();
        ref.read(generationCanvasGroupSelectionProvider.notifier).clear();
      }
    } else if (focus?.group != null &&
        !images.any(
          (image) =>
              generationBatchKey(image) == focus!.group ||
              'pin:${image.id}' == focus.group,
        ) &&
        focus!.group != 'run:${state.generationRunId}') {
      ref.read(generationCanvasGroupSelectionProvider.notifier).clear();
    }
  });
  void clear() {
    if (_disposed) return;
    ref.read(imageGenerationNotifierProvider.notifier).clearHistory();
    final selection = ref.read(generationPreviewSelectionProvider);
    if (selection != null && !images.any((image) => image.id == selection)) {
      ref.read(generationPreviewSelectionProvider.notifier).clear();
      ref.read(generationCanvasGroupSelectionProvider.notifier).clear();
    }
  }
}
