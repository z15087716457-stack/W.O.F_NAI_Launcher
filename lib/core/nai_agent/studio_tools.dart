import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import '../krita/bridge_draft_guard.dart';
import '../utils/nai_resolution_adapter.dart';
import '../../presentation/prompt_assistant/services/provider_adapters/prompt_assistant_adapter.dart';
import 'agent_tool.dart';
import 'attachment_image.dart';
import 'vision_access.dart';

class NaiAgentImage {
  const NaiAgentImage({required this.id, required this.bytes, this.metadata});
  final String id;
  final Uint8List bytes;
  final Map<String, dynamic>? metadata;
}

/// Thin business adapter: state, writer and backup are the existing Studio paths.
class NaiAgentStudioTools {
  NaiAgentStudioTools({
    required this.workspaceDirectory,
    required this.readDraft,
    required this.readSummary,
    required this.isGenerating,
    required this.backupDraft,
    required this.writeDraft,
    required this.readImage,
    required this.allowsImages,
    this.visionAccess = const NaiAgentVisionAccess(),
    this.loadImageById,
    this.domainTools = const {},
    this.isAlive = _alive,
  });
  final Directory workspaceDirectory;
  final BridgeDraftSnapshot Function() readDraft;
  final Map<String, dynamic> Function() readSummary;
  final bool Function() isGenerating, isAlive;
  final Future<String> Function(BridgeDraftSnapshot) backupDraft;
  final List<String> Function(Map<String, dynamic>) writeDraft;
  final NaiAgentImage? Function(String) readImage;
  final Future<NaiAgentImage?> Function(String, NaiAgentCancellation)?
  loadImageById;
  final bool allowsImages;
  final NaiAgentVisionAccess visionAccess;
  final Map<
    String,
    Future<Map<String, dynamic>> Function(
      Map<String, dynamic>,
      NaiAgentCancellation,
    )
  >
  domainTools;
  List<String> get domainToolNames => domainTools.keys.toList(growable: false);
  static bool _alive() => true;

  Future<Map<String, dynamic>> execute(
    String name,
    Map<String, dynamic> params,
    NaiAgentCancellation cancellation,
  ) async {
    cancellation.check();
    switch (name) {
      case 'studio_context':
        final scope = params['scope'] ?? 'summary';
        if (scope != 'summary' && scope != 'draft') {
          throw const NaiAgentToolError(
            'invalid_scope',
            'Expected summary or draft',
          );
        }
        return naiAgentTextResult({
          ...readSummary(),
          if (scope == 'draft')
            'draft': {
              ...readDraft().toJson(),
              'draft_version': readDraft().acknowledgementVersion,
            },
        });
      case 'prompt_update':
        return _update(params, cancellation);
      case 'image_read':
        return _image(params, cancellation);
      default:
        final domain = domainTools[name];
        if (domain != null) return domain(params, cancellation);
        throw const NaiAgentToolError('unknown_tool', 'Unknown Studio tool');
    }
  }

  Future<Map<String, dynamic>> _update(
    Map<String, dynamic> params,
    NaiAgentCancellation cancellation,
  ) async {
    if (params['changes'] is! Map || params['expected'] is! Map) {
      throw const NaiAgentToolError(
        'invalid_patch',
        'Expected changes and field versions',
      );
    }
    final changes = Map<String, dynamic>.from(params['changes'] as Map);
    final expected = Map<String, dynamic>.from(params['expected'] as Map);
    if (changes.isEmpty) {
      throw const NaiAgentToolError('invalid_patch', 'Empty draft patch');
    }
    try {
      validateBridgePatch(changes);
    } on FormatException catch (error) {
      throw NaiAgentToolError('invalid_patch', error.message);
    }
    void check(BridgeDraftSnapshot draft) {
      cancellation.check();
      if (!isAlive()) {
        throw const NaiAgentToolError('closed', 'Studio binding closed');
      }
      if (isGenerating()) {
        throw const NaiAgentToolError(
          'busy',
          'Generation is active; draft was not changed',
        );
      }
      if (!draft.matches(changes, expected)) {
        throw const NaiAgentToolError(
          'draft_conflict',
          'Draft changed; read studio_context(scope=draft) again',
        );
      }
    }

    final before = readDraft();
    check(before);
    final backup = await backupDraft(before);
    // All checks are repeated after IO. Keep comparison and writer synchronous.
    check(readDraft());
    final applied = writeDraft(changes);
    final actual = readDraft();
    return naiAgentTextResult({
      'applied': applied,
      'backup_path': backup,
      'draft': {
        ...actual.toJson(),
        'draft_version': actual.acknowledgementVersion,
      },
    });
  }

  Future<Map<String, dynamic>> _image(
    Map<String, dynamic> params,
    NaiAgentCancellation cancellation,
  ) async {
    final metadataOnly = params['metadata_only'] == true;
    if (!allowsImages && !metadataOnly) {
      throw NaiAgentToolError(
        'vision_unavailable',
        visionAccess.unavailableMessage,
      );
    }
    final image = await loadImage(params, cancellation);
    final size = NaiResolutionAdapter.readImageSize(image.bytes)!;
    final mime = _mime(image.bytes)!;
    final metadata = image.metadata ?? readNaiAttachmentMetadata(image.bytes);
    final originalInfo = {
      'image_id': image.id,
      'width': size.$1,
      'height': size.$2,
      'source_bytes': image.bytes.length,
      'source_mime': mime,
      'metadata': metadata,
    };
    if (metadataOnly) return naiAgentTextResult(originalInfo);
    final visual = await agentAttachmentVisualBytes(image.bytes, mime);
    final optimized = await optimizePromptAssistantImagePartForUpload(
      PromptAssistantImagePart(
        bytes: visual,
        mimeType: mime == 'image/bmp' ? 'image/png' : mime,
      ),
    );
    cancellation.check();
    if (!isAlive()) {
      throw const NaiAgentToolError('closed', 'Studio binding closed');
    }
    if (optimized.bytes.length > promptAssistantImageUploadMaxBytes) {
      throw const NaiAgentToolError(
        'image_too_large',
        'Image could not fit the model upload limit',
      );
    }
    final info = {
      'image_id': image.id,
      'width': size.$1,
      'height': size.$2,
      'source_bytes': image.bytes.length,
      'source_mime': mime,
      'sent_bytes': optimized.bytes.length,
      'sent_mime': optimized.mimeType,
      'metadata': metadata,
    };
    return {
      'content': [
        {'type': 'text', 'text': jsonEncode(info)},
        {
          'type': 'image',
          'mimeType': optimized.mimeType,
          'data': base64Encode(optimized.bytes),
        },
      ],
      'details': info,
    };
  }

  /// Original, frozen bytes for domain tools. Vision upload optimization is
  /// deliberately separate, so reference/source setup never uses a thumbnail.
  Future<NaiAgentImage> loadImage(
    Map<String, dynamic> params,
    NaiAgentCancellation cancellation,
  ) async {
    cancellation.check();
    if (!isAlive()) {
      throw const NaiAgentToolError('closed', 'Studio binding closed');
    }
    final imageId = params['image_id'], path = params['path'];
    if ((imageId == null) == (path == null) ||
        (imageId != null && (imageId is! String || imageId.isEmpty)) ||
        (path != null && (path is! String || path.isEmpty))) {
      throw const NaiAgentToolError(
        'invalid_image',
        'Provide one image_id or workspace-relative path',
      );
    }
    NaiAgentImage image;
    if (imageId is String) {
      final selected =
          readImage(imageId) ??
          await loadImageById?.call(imageId, cancellation);
      if (selected == null) {
        throw const NaiAgentToolError(
          'image_missing',
          'Image is no longer available',
        );
      }
      // Freeze identity and bytes before asynchronous processing or selection changes.
      image = NaiAgentImage(
        id: selected.id,
        bytes: Uint8List.fromList(selected.bytes),
        metadata: selected.metadata,
      );
    } else {
      final relative = path as String;
      if (p.isAbsolute(relative)) {
        throw const NaiAgentToolError(
          'path_outside_workspace',
          'Expected workspace-relative path',
        );
      }
      final root = await workspaceDirectory.resolveSymbolicLinks();
      final file = File(p.join(root, relative));
      final resolved = await file.resolveSymbolicLinks();
      if (!p.isWithin(root, resolved)) {
        throw const NaiAgentToolError(
          'path_outside_workspace',
          'Image path leaves this workspace',
        );
      }
      if (await File(resolved).length() > 64 * 1024 * 1024) {
        throw const NaiAgentToolError(
          'image_too_large',
          'Image exceeds 64 MiB',
        );
      }
      image = NaiAgentImage(
        id: relative,
        bytes: await File(resolved).readAsBytes(),
      );
    }
    cancellation.check();
    if (!isAlive()) {
      throw const NaiAgentToolError('closed', 'Studio binding closed');
    }
    if (image.bytes.length > 64 * 1024 * 1024) {
      throw const NaiAgentToolError('image_too_large', 'Image exceeds 64 MiB');
    }
    final size = NaiResolutionAdapter.readImageSize(image.bytes);
    final mime = _mime(image.bytes);
    if (size == null || mime == null) {
      throw const NaiAgentToolError(
        'invalid_image',
        'Unsupported or invalid image',
      );
    }
    if (size.$1 * size.$2 > 64000000) {
      throw const NaiAgentToolError(
        'image_too_large',
        'Image exceeds 64 million pixels',
      );
    }
    return image;
  }

  static String? _mime(Uint8List bytes) {
    if (agentImageMime(bytes) == 'image/bmp') return 'image/bmp';
    if (bytes.length < 12) return null;
    if (bytes[0] == 137 && bytes[1] == 80 && bytes[2] == 78 && bytes[3] == 71) {
      return 'image/png';
    }
    if (bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255) {
      return 'image/jpeg';
    }
    final header = ascii.decode(bytes.take(12).toList(), allowInvalid: true);
    if (header.startsWith('RIFF') && header.endsWith('WEBP')) {
      return 'image/webp';
    }
    if (header.startsWith('GIF87a') || header.startsWith('GIF89a')) {
      return 'image/gif';
    }
    return null;
  }
}
