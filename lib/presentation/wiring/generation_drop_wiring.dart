import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../ui/gen/gen_contract.dart';
import '../utils/dropped_file_reader.dart';
import '../widgets/common/app_toast.dart';
import 'generation_reference_imports.dart';

final generationDropHoverProvider = StateProvider<GenDropTarget?>(
  (ref) => null,
);

class GenerationDropWiring extends ConsumerStatefulWidget {
  const GenerationDropWiring({
    super.key,
    required this.target,
    required this.child,
  });
  final GenDropTarget target;
  final Widget child;
  @override
  ConsumerState<GenerationDropWiring> createState() =>
      _GenerationDropWiringState();
}

class _GenerationDropWiringState extends ConsumerState<GenerationDropWiring> {
  bool busy = false;
  void clearHover() {
    if (ref.read(generationDropHoverProvider) == widget.target) {
      ref.read(generationDropHoverProvider.notifier).state = null;
    }
  }

  Future<void> dropped(PerformDropEvent event) async {
    if (busy) return;
    busy = true;
    clearHover();
    try {
      await ref.read(generationReferenceImportsProvider).files(
        widget.target,
        () async {
          final files = <GenerationReferenceFile>[];
          for (final item in event.session.items) {
            final reader = item.dataReader;
            if (reader == null) continue;
            final file = await DroppedFileReader.read(
              reader,
              logTag: 'GenerationDrop',
            );
            if (file != null) {
              files.add(GenerationReferenceFile(file.fileName, file.bytes));
            }
          }
          return files;
        },
        alive: () => mounted,
      );
    } catch (error) {
      if (mounted) AppToast.error(context, error.toString());
    } finally {
      busy = false;
    }
  }

  @override
  Widget build(BuildContext context) => DropRegion(
    formats: Formats.standardFormats,
    hitTestBehavior: HitTestBehavior.opaque,
    onDropOver: (event) {
      if (busy ||
          !event.session.allowedOperations.contains(DropOperation.copy)) {
        return DropOperation.none;
      }
      ref.read(generationDropHoverProvider.notifier).state = widget.target;
      return DropOperation.copy;
    },
    onDropLeave: (_) => clearHover(),
    onPerformDrop: dropped,
    child: widget.child,
  );
}
