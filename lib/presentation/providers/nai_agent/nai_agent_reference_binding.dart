import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/precise_ref_type.dart';
import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/generation_snapshot.dart';
import '../../../core/nai_agent/studio_tools.dart';
import '../../../core/utils/inpaint_focus_region.dart';
import '../../../core/utils/nai_api_utils.dart';
import '../../../core/utils/nai_resolution_adapter.dart';
import '../../../data/models/image/image_params.dart';
import '../../../data/models/vibe/vibe_reference.dart';
import '../../../data/services/nai_agent/agent_snapshot_files.dart';
import '../generation/image_workflow_controller.dart';
import '../generation/image_workflow_snapshot.dart';
import '../image_generation_provider.dart';
import '../krita/bridge_draft_snapshot.dart';

const _actions = {
  'list',
  'set_source',
  'clear_source',
  'set_mask',
  'clear_mask',
  'add_vibe',
  'update_vibe',
  'remove_vibe',
  'clear_vibes',
  'add_precise',
  'update_precise',
  'remove_precise',
  'clear_precise',
};
const _imageActions = {'set_source', 'set_mask', 'add_vibe', 'add_precise'};
const _sourceActions = {'set_source', 'clear_source', 'set_mask', 'clear_mask'};

double? _scalar(
  Map<String, dynamic> p,
  String key, {
  bool free = false,
  double min = 0,
}) {
  final v = p[key];
  if (v == null) return null;
  if (v is! num || !v.isFinite || (!free && (v < min || v > 1))) {
    throw NaiAgentToolError('invalid_reference', 'Invalid $key');
  }
  return v.toDouble();
}

class NaiAgentReferenceBinding {
  NaiAgentReferenceBinding(
    this.ref,
    Directory workspace,
    this.loadImage,
    this.isBusy,
    this.isAlive, {
    AgentSnapshotFiles? snapshots,
  }) : snapshots = snapshots ?? AgentSnapshotFiles(workspace);
  final Ref ref;
  final Future<NaiAgentImage> Function(
    Map<String, dynamic>,
    NaiAgentCancellation,
  )
  loadImage;
  final bool Function() isBusy, isAlive;
  final AgentSnapshotFiles snapshots;

  /// Already-loaded library/file data. Keep its real encoding and model rather
  /// than turning a preview into a new raw-image reference.
  Future<Map<String, dynamic>> applyPrepared({
    List<VibeReference>? vibes,
    Uint8List? preciseImage,
    PreciseRefType preciseType = PreciseRefType.characterAndStyle,
    double preciseStrength = 1,
    double preciseFidelity = 1,
    required String expectedVersion,
    required NaiAgentCancellation token,
    required void Function() checkSource,
    Future<void> Function()? refreshSource,
  }) async {
    void check() {
      _live(token);
      checkSource();
      if (isBusy()) {
        throw const NaiAgentToolError('busy', 'A Studio image job is active');
      }
      if (readBridgeDraft(ref).acknowledgementVersion != expectedVersion) {
        throw const NaiAgentToolError(
          'draft_conflict',
          'Draft changed; read studio_context again',
        );
      }
    }

    check();
    final before = ref.read(generationParamsNotifierProvider);
    if (vibes != null &&
        (!before.modelSpec.vibetransfer ||
            vibes.isEmpty ||
            before.vibeReferencesV4.length + vibes.length > 16)) {
      throw const NaiAgentToolError(
        'invalid_reference',
        'Unsupported model, empty Vibe list or 16-reference limit exceeded',
      );
    }
    if (preciseImage != null && !before.modelSpec.characterReferences) {
      throw const NaiAgentToolError(
        'unsupported_model',
        'Current model does not support precise references',
      );
    }
    final normalized = preciseImage == null
        ? null
        : await NAIApiUtils.ensurePngFormatAsync(preciseImage);
    check();
    final controller = ref.read(imageWorkflowControllerProvider.notifier);
    final backupImage = controller.snapshotDraftParams;
    final saved = await snapshots.save('Before Agent library reference apply', {
      'kind': 'reference_library_before_apply',
      'draft': readBridgeDraft(ref, imageOverride: backupImage).toJson(),
      'image': encodeAgentImageParams(backupImage),
      'image_workflow': encodeImageWorkflowConfiguration(
        controller.snapshotDraftWorkflow,
        backupImage,
      ),
    }, backup: true);
    await refreshSource?.call();
    check();
    final writer = ref.read(generationParamsNotifierProvider.notifier);
    if (vibes != null) writer.addVibeReferences(vibes, recordUsage: false);
    if (normalized != null) {
      writer.addPreciseReference(
        normalized,
        type: preciseType,
        strength: preciseStrength,
        fidelity: preciseFidelity,
        isNormalizedPng: true,
      );
    }
    return naiAgentTextResult({...summary(), 'backup_path': saved['path']});
  }

  void _live(NaiAgentCancellation token) {
    token.check();
    if (!isAlive()) {
      throw const NaiAgentToolError('closed', 'Studio binding closed');
    }
  }

  Map<String, dynamic> summary() {
    final image = ref.read(generationParamsNotifierProvider);
    Map<String, dynamic>? picture(Uint8List? bytes, String id) {
      if (bytes == null) return null;
      final size = NaiResolutionAdapter.readImageSize(bytes);
      return {
        'image_id': id,
        'bytes': bytes.length,
        'width': size?.$1,
        'height': size?.$2,
      };
    }

    final focus = image.inpaintFocusRegion;
    final preciseActive =
        image.modelSpec.characterReferences &&
        image.preciseReferences.any((r) => r.enabled);
    String? vibeReason(VibeReference vibe) => !image.modelSpec.vibetransfer
        ? 'unsupported_model'
        : !vibe.enabled
        ? 'disabled'
        : preciseActive
        ? 'precise_reference_priority'
        : image.action.name == 'infill'
        ? 'inpainting_excludes_vibe'
        : null;
    return {
      'draft_version': readBridgeDraft(ref).acknowledgementVersion,
      'model': image.model,
      'supports_vibe': image.modelSpec.vibetransfer,
      'supports_precise': image.modelSpec.characterReferences,
      'action': image.action.name,
      'workflow': ref.exists(imageWorkflowControllerProvider)
          ? ref.read(imageWorkflowControllerProvider).mode.name
          : 'uninitialized',
      'request_width': image.width,
      'request_height': image.height,
      'source': picture(image.sourceImage, 'draft:source'),
      'mask': picture(image.maskImage, 'draft:mask'),
      'focus_region': focus == null
          ? null
          : {
              'x': focus.x,
              'y': focus.y,
              'width': focus.width,
              'height': focus.height,
              'context': focus.context,
            },
      'strength': image.strength,
      'noise': image.noise,
      'vibes': [
        for (var i = 0; i < image.vibeReferencesV4.length; i++)
          {
            'index': i,
            'name': image.vibeReferencesV4[i].displayName,
            'image': picture(
              image.vibeReferencesV4[i].rawImageData ??
                  image.vibeReferencesV4[i].thumbnail,
              'draft:vibe:$i',
            ),
            'enabled': image.vibeReferencesV4[i].enabled,
            'participates': vibeReason(image.vibeReferencesV4[i]) == null,
            'inactive_reason': vibeReason(image.vibeReferencesV4[i]),
            'strength': image.vibeReferencesV4[i].strength,
            'info_extracted': image.vibeReferencesV4[i].infoExtracted,
            'encoded': image.vibeReferencesV4[i].vibeEncoding.isNotEmpty,
            'encoding_model': image.vibeReferencesV4[i].encodingModel,
            'source_type': image.vibeReferencesV4[i].sourceType.name,
          },
      ],
      'precise': [
        for (var i = 0; i < image.preciseReferences.length; i++)
          {
            'index': i,
            'image': picture(
              image.preciseReferences[i].image,
              'draft:precise:$i',
            ),
            'enabled': image.preciseReferences[i].enabled,
            'participates':
                image.modelSpec.characterReferences &&
                image.preciseReferences[i].enabled,
            'type': image.preciseReferences[i].type.name,
            'strength': image.preciseReferences[i].strength,
            'fidelity': image.preciseReferences[i].fidelity,
          },
      ],
    };
  }

  void _validate(String action, Map<String, dynamic> p, ImageParams image) {
    final allowed = {
      'action',
      if (action != 'list') 'expected_draft_version',
      if (_imageActions.contains(action)) ...{'image_id', 'path'},
      if (action == 'set_source') ...{'use_image_size', 'strength', 'noise'},
      if (action == 'set_mask') 'focus_region',
      if (action.startsWith('add_') || action.startsWith('update_')) 'strength',
      if (action == 'add_vibe' || action == 'update_vibe') 'info_extracted',
      if (action == 'add_precise' || action == 'update_precise') ...{
        'type',
        'fidelity',
      },
      if (action.startsWith('update_') || action.startsWith('remove_')) 'index',
      if (action.startsWith('update_')) 'enabled',
      if (action == 'add_vibe') 'name',
    };
    if (p.keys.any((key) => !allowed.contains(key))) {
      throw const NaiAgentToolError(
        'invalid_reference',
        'Unexpected field for this reference action',
      );
    }
    if (p.containsKey('enabled') && p['enabled'] is! bool ||
        p.containsKey('use_image_size') && p['use_image_size'] is! bool) {
      throw const NaiAgentToolError('invalid_reference', 'Expected a boolean');
    }
    _scalar(p, 'strength', free: action.endsWith('_vibe'));
    _scalar(p, 'noise');
    _scalar(p, 'fidelity');
    _scalar(p, 'info_extracted', min: VibeReference.minInfoExtracted);
    if (p.containsKey('type') &&
        !PreciseRefType.values.asNameMap().containsKey(p['type'])) {
      throw const NaiAgentToolError(
        'invalid_reference',
        'Use character, style or characterAndStyle',
      );
    }
    if (p.containsKey('name') &&
        (p['name'] is! String ||
            (p['name'] as String).trim().isEmpty ||
            (p['name'] as String).length > 200)) {
      throw const NaiAgentToolError(
        'invalid_reference',
        'Invalid reference name',
      );
    }
    if (action.startsWith('update_') || action.startsWith('remove_')) {
      final count = action.endsWith('_vibe')
          ? image.vibeReferencesV4.length
          : image.preciseReferences.length;
      if (p['index'] is! int ||
          (p['index'] as int) < 0 ||
          (p['index'] as int) >= count) {
        throw const NaiAgentToolError(
          'reference_missing',
          'Read reference_manage(action=list) for current indices',
        );
      }
    }
    if ((action == 'add_vibe' || action == 'update_vibe') &&
            !image.modelSpec.vibetransfer ||
        (action == 'add_precise' || action == 'update_precise') &&
            !image.modelSpec.characterReferences) {
      throw const NaiAgentToolError(
        'reference_unsupported',
        'Current model does not support this reference',
      );
    }
    if (action == 'add_vibe' && image.vibeReferencesV4.length >= 16) {
      throw const NaiAgentToolError(
        'reference_limit',
        'Vibe supports at most 16 references',
      );
    }
    if (action == 'set_mask' && image.sourceImage == null) {
      throw const NaiAgentToolError(
        'source_missing',
        'Set a source image before its mask',
      );
    }
  }

  InpaintFocusRegion? _focus(Map<String, dynamic> p, Uint8List source) {
    final raw = p['focus_region'];
    if (raw == null) return null;
    if (raw is! Map ||
        raw.keys.any(
          (k) => !{'x', 'y', 'width', 'height', 'context'}.contains(k),
        ) ||
        ['x', 'y', 'width', 'height'].any((k) => raw[k] is! int) ||
        (raw.containsKey('context') && raw['context'] is! int)) {
      throw const NaiAgentToolError(
        'invalid_reference',
        'Invalid source-pixel focus rectangle',
      );
    }
    final size = NaiResolutionAdapter.readImageSize(source);
    final x = raw['x'] as int,
        y = raw['y'] as int,
        width = raw['width'] as int,
        height = raw['height'] as int,
        context = raw['context'] as int? ?? 96;
    if (size == null ||
        x < 0 ||
        y < 0 ||
        width < 8 ||
        height < 8 ||
        x + width > size.$1 ||
        y + height > size.$2 ||
        context < 0 ||
        [x, y, width, height].any((n) => n % 8 != 0) ||
        context * 2 >= width ||
        context * 2 >= height) {
      throw const NaiAgentToolError(
        'invalid_reference',
        'Focus must fit source on the eight-pixel grid and leave an interior after context',
      );
    }
    return InpaintFocusRegion(
      x: x,
      y: y,
      width: width,
      height: height,
      context: context,
    );
  }

  Future<Map<String, dynamic>> execute(
    Map<String, dynamic> p,
    NaiAgentCancellation token,
  ) async {
    _live(token);
    final action = p['action'] ?? 'list';
    if (action is! String || !_actions.contains(action)) {
      throw const NaiAgentToolError(
        'invalid_reference',
        'Unknown reference action',
      );
    }
    final before = ref.read(generationParamsNotifierProvider);
    _validate(action, p, before);
    if (action == 'list') return naiAgentTextResult(summary());
    final draft = readBridgeDraft(ref);
    final expected = p['expected_draft_version'];
    if (expected is! String || expected != draft.acknowledgementVersion) {
      throw const NaiAgentToolError(
        'draft_conflict',
        'Read studio_context(scope=draft) or reference_manage(action=list) again',
      );
    }
    final workflow = _sourceActions.contains(action)
        ? ref.read(imageWorkflowControllerProvider)
        : null;
    void check() {
      _live(token);
      if (isBusy()) {
        throw const NaiAgentToolError('busy', 'A Studio image job is active');
      }
      if (readBridgeDraft(ref).acknowledgementVersion != expected ||
          workflow != null &&
              !identical(ref.read(imageWorkflowControllerProvider), workflow)) {
        throw const NaiAgentToolError(
          'draft_conflict',
          'Studio draft/workflow changed; read it again',
        );
      }
    }

    check();
    NaiAgentImage? picture;
    if (_imageActions.contains(action)) {
      picture = await loadImage({
        if (p.containsKey('image_id')) 'image_id': p['image_id'],
        if (p.containsKey('path')) 'path': p['path'],
      }, token);
    }
    Uint8List? normalized;
    if (action == 'add_precise') {
      normalized = await NAIApiUtils.ensurePngFormatAsync(picture!.bytes);
    }
    InpaintFocusRegion? focus;
    if (action == 'set_mask') {
      if (NaiResolutionAdapter.readImageSize(picture!.bytes) !=
          NaiResolutionAdapter.readImageSize(before.sourceImage!)) {
        throw const NaiAgentToolError(
          'mask_size_mismatch',
          'Mask must match the original source pixel dimensions',
        );
      }
      focus = _focus(p, before.sourceImage!);
    }
    check();
    final controller = ref.read(imageWorkflowControllerProvider.notifier);
    final backupImage = controller.snapshotDraftParams;
    final saved = await snapshots.save('Before Agent reference change', {
      'kind': 'reference_before_write',
      'action': action,
      'draft': readBridgeDraft(ref, imageOverride: backupImage).toJson(),
      'image': encodeAgentImageParams(backupImage),
      'image_workflow': encodeImageWorkflowConfiguration(
        controller.snapshotDraftWorkflow,
        backupImage,
      ),
    }, backup: true);
    check();
    // No await between the final guard and native writes. Do not restore an old
    // whole ImageParams over the editor; mutate only through its native methods.
    final writer = ref.read(generationParamsNotifierProvider.notifier);
    switch (action) {
      case 'set_source':
        final tool = ref.read(imageWorkflowControllerProvider.notifier);
        tool.enterBaseMode();
        final originalSize = NaiResolutionAdapter.readImageSize(
          picture!.bytes,
        )!;
        tool.replaceSourceImage(
          picture.bytes,
          autoAdapt: p['use_image_size'] != false,
          sourceWidth: p['use_image_size'] == false
              ? before.width
              : originalSize.$1,
          sourceHeight: p['use_image_size'] == false
              ? before.height
              : originalSize.$2,
        );
        if (p['strength'] != null) {
          writer.updateStrength(_scalar(p, 'strength')!);
        }
        if (p['noise'] != null) writer.updateNoise(_scalar(p, 'noise')!);
      case 'clear_source':
        ref.read(imageWorkflowControllerProvider.notifier).clearSourceImage();
      case 'set_mask':
        ref
            .read(imageWorkflowControllerProvider.notifier)
            .applyInpaintEditorResult(
              maskImage: picture!.bytes,
              focusRegion: focus,
              sourceIsOutpaint: false,
            );
      case 'clear_mask':
        ref.read(imageWorkflowControllerProvider.notifier).enterBaseMode();
      case 'add_vibe':
        writer.addVibeReference(
          VibeReference(
            displayName: p['name'] as String? ?? picture!.id,
            vibeEncoding: '',
            rawImageData: picture!.bytes,
            thumbnail: picture.bytes,
            strength:
                _scalar(p, 'strength', free: true) ??
                VibeReference.defaultStrength,
            infoExtracted: _scalar(p, 'info_extracted') ?? 0.7,
          ),
        );
      case 'update_vibe':
        writer.updateVibeReference(
          p['index'] as int,
          strength: _scalar(p, 'strength', free: true),
          infoExtracted: _scalar(p, 'info_extracted'),
          enabled: p['enabled'] as bool?,
        );
      case 'remove_vibe':
        writer.removeVibeReference(p['index'] as int);
      case 'clear_vibes':
        writer.clearVibeReferences();
      case 'add_precise':
        writer.addPreciseReference(
          normalized!,
          type:
              PreciseRefType.values.asNameMap()[p['type']] ??
              PreciseRefType.character,
          strength: _scalar(p, 'strength') ?? 1,
          fidelity: _scalar(p, 'fidelity') ?? 1,
          isNormalizedPng: true,
        );
      case 'update_precise':
        writer.updatePreciseReference(
          p['index'] as int,
          type: PreciseRefType.values.asNameMap()[p['type']],
          strength: _scalar(p, 'strength'),
          fidelity: _scalar(p, 'fidelity'),
          enabled: p['enabled'] as bool?,
        );
      case 'remove_precise':
        writer.removePreciseReference(p['index'] as int);
      case 'clear_precise':
        writer.clearPreciseReferences();
    }
    return naiAgentTextResult({
      'applied_action': action,
      'backup_path': saved['path'],
      ...summary(),
    });
  }
}
