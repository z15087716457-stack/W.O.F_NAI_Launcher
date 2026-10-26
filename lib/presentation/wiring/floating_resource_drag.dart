import 'package:flutter/widgets.dart';

import '../../data/models/gallery/local_image_record.dart';
import '../ui/refs/refs_contract.dart';
import '../widgets/gallery/draggable_image_card.dart';
import '../widgets/prompt/blocks/prompt_block_drag_data.dart';

/// Typed library references, never a snapshot of image bytes or parameters.
/// Existing RefsCardDrag is untyped; using it across two libraries could treat
/// an unrelated key as the wrong kind, so floating windows use this protocol.
class RefsEntryDragData {
  RefsEntryDragData({required this.kind, required List<String> keys})
    : keys = List.unmodifiable(keys);
  final RefsKind kind;
  final List<String> keys;
}

abstract final class FloatingResourceDrag {
  /// Preserves gallery_internal and the native file/PNG export protocol.
  static Widget gallery({
    required LocalImageRecord record,
    required Widget child,
    List<String>? selectedPaths,
  }) => DraggableImageCard.createDragWrapper(
    record: record,
    selectedPaths: selectedPaths,
  )(child);

  static PromptBlockDragData block(String id) =>
      PromptBlockDragData(blockId: id);
  static RefsEntryDragData refs(RefsKind kind, List<String> keys) =>
      RefsEntryDragData(kind: kind, keys: keys);
}
