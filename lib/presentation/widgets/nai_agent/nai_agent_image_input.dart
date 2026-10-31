import 'dart:async';
import 'dart:typed_data';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:super_clipboard/super_clipboard.dart';
import '../../../core/nai_agent/attachment_image.dart';
import '../../providers/image_generation_provider.dart';
import '../../providers/nai_agent/nai_agent_workspace_controller.dart';
import '../../utils/dropped_file_reader.dart';
import '../../utils/internal_drag_protocol.dart';
import '../../utils/nai_agent_image_reader.dart';
import '../../../core/utils/localization_extension.dart';
import '../common/app_toast.dart';

/// Native OLE is tested with the packaged desktop runtime, outside fake clocks.
final naiAgentNativeDragEnabledProvider = Provider<bool>((ref) => true);

String? agentAttachmentMime(Uint8List bytes) {
  return agentImageMime(bytes);
}

/// Tests inject OS readers, while production keeps the real clipboard channel.
final naiAgentClipboardReadersProvider =
    Provider<Future<List<DataReader>> Function()>(
      (ref) => () async {
        final clipboard = SystemClipboard.instance;
        return clipboard == null ? [] : (await clipboard.read()).items;
      },
    );

class AgentImageImportReport {
  int added = 0, skipped = 0;
  final failures = <String>[];
}

Future<AgentImageImportReport> importAgentImageSources(
  NaiAgentWorkspaceController controller,
  AgentChatRuntime target,
  List<Future<DroppedFileData?> Function()> sources,
) => controller.importImages(target, () async {
  final result = AgentImageImportReport();
  for (final source in sources) {
    try {
      controller.checkImageImportTarget(target);
      final data = await source();
      controller.checkImageImportTarget(target);
      if (data == null) {
        result.skipped++;
        continue;
      }
      await attachAgentImage(controller, target, data);
      result.added++;
    } catch (error) {
      if (error is AgentImageInputException && error.code == 'closed') rethrow;
      result.failures.add(
        error is AgentImageInputException ? error.code : 'unreadable',
      );
    }
  }
  return result;
}, imageCount: sources.length);

void presentAgentImageImport(
  BuildContext context,
  AgentImageImportReport report, {
  bool dropping = false,
}) {
  if (!context.mounted) return;
  final l = context.l10n;
  if (report.failures.isNotEmpty) {
    final reasons = report.failures
        .toSet()
        .map(
          (code) => switch (code) {
            'oversized' => l.naiAgent_imageTooLarge,
            'link_only' => l.naiAgent_linkOnlyImage,
            _ => l.naiAgent_invalidImage,
          },
        )
        .join('\n');
    AppToast.warning(
      context,
      '${l.naiAgent_importResult(report.added, report.failures.length)}\n$reasons',
    );
  } else if (dropping && report.added == 0) {
    AppToast.warning(context, l.naiAgent_invalidImage);
  }
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

/// Native attachment drop target supplied to the composer.
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
    widget.onHighlight?.call(false);
    try {
      final sources = <Future<DroppedFileData?> Function()>[];
      for (final item in event.session.items) {
        final internal = isHistoryInternalDragLocalData(item.localData)
            ? resolveInternalHistoryDropPayload(
                item.localData,
                ref.read(imageGenerationNotifierProvider),
              )
            : null;
        final reader = item.dataReader;
        // Every native request must start before OLE releases this session.
        // Import/decode remains sequential; attach an error listener now too.
        final pending = internal != null || reader == null
            ? Future<DroppedFileData?>.value(internal)
            : readAgentImage(reader, dropping: true);
        pending.ignore();
        sources.add(() => pending);
      }
      final report = await importAgentImageSources(controller, target, sources);
      if (mounted && identical(controller.selected, target)) {
        presentAgentImageImport(context, report, dropping: true);
      }
    } catch (error) {
      if (mounted && error is! AgentImageInputException) {
        AppToast.error(context, context.l10n.naiAgent_invalidImage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(naiAgentNativeDragEnabledProvider)) return widget.child;
    return DropRegion(
      formats: Formats.standardFormats,
      onDropOver: (event) {
        if (!event.session.allowedOperations.contains(DropOperation.copy)) {
          return DropOperation.none;
        }
        widget.onHighlight?.call(true);
        return DropOperation.copy;
      },
      onDropLeave: (_) => widget.onHighlight?.call(false),
      onDropEnded: (_) => widget.onHighlight?.call(false),
      onPerformDrop: (event) async {
        // Do not await file readers inside the Windows OLE drop callback.
        unawaited(_drop(event, widget.runtime));
      },
      child: widget.child,
    );
  }
}
