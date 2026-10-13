import 'dart:async';
import 'dart:typed_data';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import '../../providers/image_generation_provider.dart';
import '../../providers/nai_agent/nai_agent_workspace_controller.dart';
import '../../utils/dropped_file_reader.dart';
import '../../utils/internal_drag_protocol.dart';
import 'nai_agent_shared.dart';

/// Native OLE is tested with the packaged desktop runtime, outside fake clocks.
final naiAgentNativeDragEnabledProvider = Provider<bool>((ref) => true);

String? agentAttachmentMime(Uint8List bytes) {
  if (bytes.length < 12) return null;
  if (bytes[0] == 137 && bytes[1] == 80 && bytes[2] == 78 && bytes[3] == 71) {
    return 'image/png';
  }
  if (bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255) {
    return 'image/jpeg';
  }
  if (String.fromCharCodes(bytes.take(3)) == 'GIF') return 'image/gif';
  if (String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    return 'image/webp';
  }
  return null;
}

Future<void> attachAgentImage(
  NaiAgentWorkspaceController controller,
  AgentChatRuntime target,
  DroppedFileData data,
) async {
  final mime = agentAttachmentMime(data.bytes);
  if (mime == null) throw const FormatException('Unsupported image');
  await controller.attach(data.fileName, data.bytes, mime, target: target);
}

/// Covers the entire chat surface, so dropping over messages cannot fall
/// through to the canvas's import workflow.
class NaiAgentDropTarget extends ConsumerStatefulWidget {
  const NaiAgentDropTarget({
    super.key,
    required this.child,
    required this.controller,
    required this.runtime,
    this.onHighlight,
  });
  final Widget child;
  final NaiAgentWorkspaceController controller;
  final AgentChatRuntime runtime;
  final ValueChanged<bool>? onHighlight;
  @override
  ConsumerState<NaiAgentDropTarget> createState() => _DropTargetState();
}

class _DropTargetState extends ConsumerState<NaiAgentDropTarget> {
  Future<void> _drop(PerformDropEvent event, AgentChatRuntime target) async {
    final controller = widget.controller;
    final generation = ref.read(imageGenerationNotifierProvider);
    widget.onHighlight?.call(false);
    try {
      var handled = false;
      for (final item in event.session.items) {
        final internal = resolveInternalHistoryDropPayload(
          item.localData,
          generation,
        );
        final data =
            internal ??
            (item.dataReader == null
                ? null
                : await DroppedFileReader.read(
                    item.dataReader!,
                    allowRemoteImages: false,
                    logTag: 'NaiAgentDrop',
                  ));
        if (data != null) {
          await attachAgentImage(controller, target, data);
          handled = true;
        }
      }
      if (!handled) throw const FormatException('No readable image');
    } catch (error) {
      if (mounted) await agentUiAction(context, () => Future.error(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(naiAgentNativeDragEnabledProvider)) return widget.child;
    return DropRegion(
      formats: Formats.standardFormats,
      onDropOver: (_) {
        widget.onHighlight?.call(true);
        return DropOperation.copy;
      },
      onDropLeave: (_) => widget.onHighlight?.call(false),
      onPerformDrop: (event) async {
        // Do not await file readers inside the Windows OLE drop callback.
        unawaited(_drop(event, widget.runtime));
      },
      child: widget.child,
    );
  }
}
