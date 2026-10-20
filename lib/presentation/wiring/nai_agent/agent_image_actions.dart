import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;

import '../../../core/enums/precise_ref_type.dart';
import '../../../core/utils/file_explorer_utils.dart';
import '../../../data/models/gallery/nai_image_metadata.dart';
import '../../../data/models/metadata/metadata_import_options.dart';
import '../../../data/services/image_metadata_service.dart';
import '../../providers/image_generation_provider.dart';
import '../../ui/agent/agent_contract.dart';
import '../../utils/local_gallery_reference_factory.dart';
import '../../utils/metadata_import_coordinator.dart';
import '../../utils/prompt_preset_import_utils.dart';

/// Reads local pixels only. Never downloads an ImageProvider or regenerates it.
Future<Uint8List?> agentImageBytes(
  AgentImage? image, {
  Uint8List? Function(String id)? historyBytes,
  String? fallbackHistoryId,
}) async {
  if (image?.image case final MemoryImage memory) return memory.bytes;
  final historyId = image?.historyId ?? fallbackHistoryId;
  if (historyId != null) {
    final bytes = historyBytes?.call(historyId);
    if (bytes != null) return bytes;
  }
  if (image?.image case final FileImage file) return file.file.readAsBytes();
  return null;
}

/// Reuses the viewer's draft capture/backup boundary; dependency callbacks keep
/// platform dialogs and Explorer replaceable in offline wiring tests.
class AgentImageActions {
  AgentImageActions({
    required this.read,
    required this.alive,
    required this.capture,
    required this.chooseReferenceType,
    required this.chooseImportSelection,
    this.historyBytes,
    this.revealFile = _revealFile,
    this.readMetadata = _readMetadata,
  });

  final ProviderReader read;
  final bool Function() alive;
  final Future<void> Function(FutureOr<void> Function()) Function() capture;
  final Future<PreciseRefType?> Function() chooseReferenceType;
  final Future<OfficialMetadataImportSelection?> Function(
    Uint8List bytes,
    NaiImageMetadata metadata,
    String fileName,
  )
  chooseImportSelection;
  final Uint8List? Function(String id)? historyBytes;
  final Future<void> Function(String path) revealFile;
  final Future<NaiImageMetadata?> Function(Uint8List bytes) readMetadata;

  static Future<void> _revealFile(String path) =>
      FileExplorerUtils.revealFile(path);
  static Future<NaiImageMetadata?> _readMetadata(Uint8List bytes) =>
      ImageMetadataService().getMetadataFromBytes(bytes);

  Future<bool> perform(AgentImage? image, AgentImageAction action) async {
    try {
      if (image == null || !alive()) return false;
      if (action == AgentImageAction.folder) {
        final path = image.path;
        if (path == null || path.trim().isEmpty) return false;
        await revealFile(path);
        return true;
      }
      // Capture BEFORE file I/O, metadata parsing or a modal selection. The
      // viewer checks this snapshot again after backing up, before any write.
      final commit = capture();
      final bytes = await agentImageBytes(image, historyBytes: historyBytes);
      if (bytes == null || bytes.isEmpty || !alive()) return false;
      final fileName = image.path == null
          ? 'agent-image.png'
          : p.basename(image.path!);
      switch (action) {
        case AgentImageAction.vibe:
          if (read(generationParamsNotifierProvider).vibeReferencesV4.length >=
              16) {
            return false;
          }
          await commit(() {
            read(generationParamsNotifierProvider.notifier).addVibeReference(
              LocalGalleryReferenceFactory.createRawStyleReference(
                fileName: fileName,
                imageBytes: bytes,
              ),
            );
          });
        case AgentImageAction.reference:
          final type = await chooseReferenceType();
          if (type == null || !alive()) return false;
          if (read(generationParamsNotifierProvider).preciseReferences.length >=
              16) {
            return false;
          }
          await commit(() {
            read(
              generationParamsNotifierProvider.notifier,
            ).addPreciseReference(bytes, type: type);
          });
        case AgentImageAction.params:
          final metadata = await readMetadata(bytes);
          if (metadata?.hasData != true || !alive()) return false;
          final selection = await chooseImportSelection(
            bytes,
            metadata!,
            fileName,
          );
          if (selection == null || !alive()) return false;
          await commit(() async {
            await MetadataImportCoordinator.applyOfficialSelection(
              read: read,
              metadata: metadata,
              selection: selection,
            );
          });
        case AgentImageAction.folder:
          return false; // Handled above, without initializing generation state.
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
