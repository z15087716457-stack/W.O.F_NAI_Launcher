import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/model_spec.dart';
import '../../core/utils/localization_extension.dart';
import '../providers/image_generation_provider.dart';
import '../providers/precise_ref_library_provider.dart';
import '../ui/refs/refs_contract.dart';
import '../widgets/common/app_toast.dart';
import 'floating_resource_drag.dart';
import 'refs_generation_target.dart';

final refsEntryDropActionsProvider = Provider(RefsEntryDropActions.new);

class RefsEntryDropActions {
  RefsEntryDropActions(this.ref);
  final Ref ref;

  bool accepts(RefsKind kind, RefsEntryDragData data) {
    final spec = ModelSpecs.of(
      ref.read(generationParamsNotifierProvider).model,
    );
    return data.kind == kind &&
        data.keys.isNotEmpty &&
        (kind == RefsKind.vibe ? spec.vibetransfer : spec.characterReferences);
  }

  Future<RefsSendResult> drop(
    RefsKind kind,
    RefsEntryDragData data, {
    required bool Function() alive,
  }) async {
    if (!accepts(kind, data) || !alive()) return const RefsSendResult(0);
    final target = ref.read(refsGenerationTargetProvider);
    if (kind == RefsKind.vibe) return target.addVibes(data.keys, alive: alive);
    // Resolve against the current library, never trust a stale dragged entry.
    await ref.read(preciseRefLibraryNotifierProvider.notifier).initialize();
    if (!alive()) return const RefsSendResult(0);
    final library = ref.read(preciseRefLibraryNotifierProvider);
    if (library.error != null) throw StateError(library.error!);
    final entries = {for (final entry in library.entries) entry.id: entry};
    if (data.keys.any((id) => !entries.containsKey(id))) {
      throw StateError(currentL10n.preciseRefLib_imageMissing);
    }
    return target.addPrecise([
      for (final id in data.keys.toSet()) entries[id]!,
    ], alive: alive);
  }
}

/// No highlight/decoration: front-end owns hover visuals. Existing file drop
/// regions stay intact inside [child]. A mismatched resource is rejected.
class RefsEntryDropTarget extends ConsumerStatefulWidget {
  const RefsEntryDropTarget({
    super.key,
    required this.kind,
    required this.child,
    this.onHover,
    this.onDropped,
  });
  final RefsKind kind;
  final Widget child;
  final ValueChanged<bool>? onHover;
  final ValueChanged<RefsSendResult>? onDropped;
  @override
  ConsumerState<RefsEntryDropTarget> createState() =>
      _RefsEntryDropTargetState();
}

class _RefsEntryDropTargetState extends ConsumerState<RefsEntryDropTarget> {
  bool _busy = false;
  Future<void> _drop(RefsEntryDragData data) async {
    if (_busy) return;
    _busy = true;
    try {
      final result = await ref
          .read(refsEntryDropActionsProvider)
          .drop(widget.kind, data, alive: () => mounted);
      if (mounted) widget.onDropped?.call(result);
    } catch (error) {
      if (mounted) AppToast.error(context, error.toString());
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) => DragTarget<RefsEntryDragData>(
    hitTestBehavior: HitTestBehavior.translucent,
    onWillAcceptWithDetails: (details) {
      final accepted =
          !_busy &&
          ref
              .read(refsEntryDropActionsProvider)
              .accepts(widget.kind, details.data);
      widget.onHover?.call(accepted);
      return accepted;
    },
    onLeave: (_) => widget.onHover?.call(false),
    onAcceptWithDetails: (details) {
      widget.onHover?.call(false);
      unawaited(_drop(details.data));
    },
    builder: (_, __, ___) => widget.child,
  );
}
