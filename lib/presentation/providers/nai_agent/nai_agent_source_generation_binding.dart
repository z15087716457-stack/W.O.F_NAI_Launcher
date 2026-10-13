import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/generation_snapshot.dart';
import '../../../core/nai_agent/generation_tools.dart';
import '../../../core/nai_agent/studio_tools.dart';
import '../../../core/network/nai_api_endpoint_service.dart';
import '../../../core/krita/bridge_draft_guard.dart';
import '../../../core/utils/max_enhance_utils.dart';
import '../../../core/utils/nai_resolution_adapter.dart';
import '../../../data/models/image/image_operation.dart';
import '../../../data/models/image/image_params.dart';
import '../../../data/models/gallery/nai_image_metadata.dart';
import '../../../data/services/metadata/unified_metadata_parser.dart';
import '../../../data/services/nai_agent/agent_workspace_files.dart';
import '../../utils/native_image_enhance.dart';
import '../../utils/official_image_variations.dart';
import '../auth_provider.dart';
import '../generation/image_workflow_controller.dart';
import '../image_generation_provider.dart';
import '../krita/bridge_draft_snapshot.dart';
import '../prompt_block_library_provider.dart';
import 'nai_agent_generation_approvals.dart';
import 'nai_agent_generation_binding.dart';

class _SourceRequest {
  _SourceRequest(this.source, this.params, this.operation, this.storageBytes);
  final String id = const Uuid().v4();
  final DateTime expires = DateTime.now().add(const Duration(minutes: 5));
  final NaiAgentImage source;
  final ImageParams params;
  final String operation;
  final int storageBytes;
  bool reserved = false;
}

/// Source actions freeze pixels and request parameters without importing them
/// into the editor. The existing generation harness owns price/approval/run.
class NaiAgentSourceGenerationBinding {
  NaiAgentSourceGenerationBinding(
    this.ref,
    Directory workspace,
    this.owner,
    this.loadImage,
    this.isBusy,
    this.isAlive,
  ) : files = AgentWorkspaceFiles(workspace) {
    generation = NaiAgentGenerationTools(
      readInput: _read,
      isAlive: isAlive,
      approve: (quote, token, check) => ref
          .read(naiAgentGenerationApprovalsProvider)
          .request(owner, quote, token, check),
      backup: (input) async {
        final request = input.workflowGuard! as _SourceRequest;
        return files.export(
          _sourceName(request.source.bytes),
          request.source.bytes,
          _checkAlive,
          companions: {
            'generation-request.json': Uint8List.fromList(
              utf8.encode(
                jsonEncode({
                  'source_image_id': request.source.id,
                  'source_file': _sourceName(request.source.bytes),
                  'source_operation': request.operation,
                  'estimated_anlas': input.estimate,
                  'balance_before_anlas': input.balance,
                  'image': encodeAgentImageParams(
                    request.params.copyWith(sourceImage: null),
                  ),
                }),
              ),
            ),
          },
        );
      },
      start: (input) {
        final request = input.workflowGuard! as _SourceRequest;
        final size = NaiResolutionAdapter.readImageSize(request.source.bytes)!;
        final operation = request.operation == 'variations'
            ? ImageOperation.variations
            : ImageOperation.enhance;
        final job = startNaiAgentNativeGeneration(
          ref,
          input,
          isAlive,
          launch: (native, onBatch) => native.generateSourceImage(
            request.params,
            operation: operation,
            original: operation == ImageOperation.variations
                ? GeneratedImage.create(
                    request.source.bytes,
                    width: size.$1,
                    height: size.$2,
                    isVariationOriginal: true,
                  )
                : null,
            onBatchEvent: onBatch,
          ),
          completed: (result, images) async {
            final artifacts = <Map<String, dynamic>>[];
            for (final image in images) {
              _checkAlive();
              final path = await files.export(
                'image.png',
                image.bytes,
                _checkAlive,
                companions: {
                  _sourceName(request.source.bytes): request.source.bytes,
                  'generation-result.json': Uint8List.fromList(
                    utf8.encode(
                      jsonEncode({
                        'source_image_id': request.source.id,
                        'source_file': _sourceName(request.source.bytes),
                        'source_operation': request.operation,
                        'image_id': image.id,
                        'estimated_anlas': input.estimate,
                        'native_generation_id': result['native_generation_id'],
                        'metadata': image.metadata?.toJson(),
                      }),
                    ),
                  ),
                },
              );
              artifacts.add({
                'type': 'image',
                'path': path,
                'width': image.width,
                'height': image.height,
                'image_id': image.id,
              });
            }
            return {
              ...result,
              'source_operation': request.operation,
              'source_image_id': request.source.id,
              'artifacts': artifacts,
              'draft_changed': false,
            };
          },
        );
        if (job != null) {
          _requests.remove(request.id);
          _quoteRequests.removeWhere((_, r) => identical(r, request));
        }
        return job;
      },
    );
  }

  final Ref ref;
  final AgentWorkspaceFiles files;
  final NaiAgentConversationOwner owner;
  final Future<NaiAgentImage> Function(
    Map<String, dynamic>,
    NaiAgentCancellation,
  )
  loadImage;
  final bool Function() isBusy, isAlive;
  late final NaiAgentGenerationTools generation;
  final _requests = <String, _SourceRequest>{};
  final _quoteRequests = <String, _SourceRequest>{};
  String? get activeId => generation.activeId;

  String _sourceName(Uint8List bytes) => bytes[0] == 137
      ? 'source.png'
      : bytes[0] == 255
      ? 'source.jpg'
      : bytes[0] == 71
      ? 'source.gif'
      : 'source.webp';

  void _checkAlive() {
    if (!isAlive()) {
      throw const NaiAgentToolError('closed', 'Studio owner closed');
    }
  }

  NaiAgentGenerationInput _read(Map<String, dynamic> params) {
    _checkAlive();
    final request = _requests[params['request_id']];
    if (request == null) {
      throw const NaiAgentToolError(
        'quote_missing',
        'Prepare a fresh source quote',
      );
    }
    final image = request.params;
    validateBridgePatch({
      'model': image.model,
      'width': image.width,
      'height': image.height,
      'steps': image.steps,
      'cfg_scale': image.scale,
      'sampler': image.sampler,
      'seed': image.seed,
    });
    final billing = readBridgeBilling(
      ref,
      image,
      batchCount: 1,
      batchSize: request.operation == 'variations'
          ? OfficialImageVariations.count
          : 1,
    );
    final auth = ref.read(authNotifierProvider);
    final cooldown = ref.read(generationCooldownProvider);
    final balance = billing['balance_anlas'] as int?;
    final cost = billing['estimated_anlas'] as int;
    final blocked = !auth.isAuthenticated || auth.accountId == null
        ? 'account_unavailable'
        : balance == null
        ? 'balance_unavailable'
        : cost < 0
        ? 'invalid_price'
        : balance < cost
        ? 'insufficient_balance'
        : isBusy()
        ? 'busy'
        : cooldown.availableAt?.isAfter(DateTime.now()) == true
        ? 'cooldown'
        : null;
    return NaiAgentGenerationInput(
      raw: image,
      effective: image,
      draftVersion: request.id,
      batchSize: request.operation == 'variations'
          ? OfficialImageVariations.count
          : 1,
      billing: billing,
      accountId: auth.accountId,
      accountName: auth.displayName ?? '',
      endpoint: jsonEncode(
        ref.read(naiApiEndpointServiceProvider).current.toJson(),
      ),
      workflowGuard: request,
      blockedReason: blocked,
      sourceOperation: request.operation,
      sourceImageId: request.source.id,
    );
  }

  Future<Map<String, dynamic>> execute(
    Map<String, dynamic> params,
    NaiAgentCancellation token,
  ) async {
    token.check();
    _checkAlive();
    final action = params['action'];
    final fields = switch (action) {
      'prepare' => {
        'action',
        'operation',
        'image_id',
        'path',
        'scale',
        'max',
        'magnitude',
        'strength',
        'noise',
      },
      'run' => {'action', 'quote_id'},
      'cancel' => {'action', 'run_id'},
      'status' => {'action'},
      _ => <String>{},
    };
    if (fields.isEmpty || params.keys.any((key) => !fields.contains(key))) {
      throw const NaiAgentToolError(
        'invalid_source_generation',
        'Unsupported source generation action or field',
      );
    }
    if (action == 'status') {
      return naiAgentTextResult({
        'run_id': activeId,
        'owned': activeId != null,
        'studio_busy': isBusy(),
      });
    }
    if (action == 'cancel') return generation.cancel(params, token);
    if (action == 'run') {
      final request = _quoteRequests[params['quote_id']];
      if (request?.reserved == true) {
        throw const NaiAgentToolError(
          'quote_in_use',
          'Source quote is already pending or running',
        );
      }
      if (request != null) request.reserved = true;
      try {
        final result = await generation.run(params, token);
        if (request != null) {
          _requests.remove(request.id);
          _quoteRequests.remove(params['quote_id']);
        }
        return result;
      } finally {
        if (request != null) {
          request.reserved = false;
          if (token.isCancelled) {
            _requests.remove(request.id);
            _quoteRequests.remove(params['quote_id']);
          }
        }
      }
    }
    final operation = params['operation'];
    if (operation != 'variations' && operation != 'enhance') {
      throw const NaiAgentToolError(
        'invalid_operation',
        'Choose variations or enhance',
      );
    }
    if (operation == 'variations' &&
        params.keys.any(
          (key) =>
              {'scale', 'max', 'magnitude', 'strength', 'noise'}.contains(key),
        )) {
      throw const NaiAgentToolError(
        'invalid_options',
        'Official variations have fixed native settings',
      );
    }
    final loaded = await loadImage(params, token);
    token.check();
    _checkAlive();
    final source = NaiAgentImage(
      id: loaded.id,
      bytes: Uint8List.fromList(loaded.bytes),
      metadata: loaded.metadata,
    );
    final size = NaiResolutionAdapter.readImageSize(source.bytes);
    if (size == null ||
        !OfficialImageVariations.supportsSize(size.$1, size.$2)) {
      throw const NaiAgentToolError(
        'invalid_source_size',
        'Source must fit the native 3MP generation limit',
      );
    }
    await ref.read(promptBlockLibraryNotifierProvider.future);
    token.check();
    _checkAlive();
    final current = ref.read(generationParamsNotifierProvider);
    final native = ref.read(imageGenerationNotifierProvider.notifier);
    ImageParams projected;
    if (operation == 'variations') {
      final metadata =
          UnifiedMetadataParser.parseFromImageBytes(source.bytes).metadata ??
          (source.metadata == null
              ? null
              : NaiImageMetadata.fromJson(source.metadata!));
      projected = OfficialImageVariations.project(
        current: metadata?.hasData == true
            ? current
            : native.preparePromptParams(current),
        source: source.bytes,
        width: size.$1,
        height: size.$2,
        metadata: metadata,
      );
    } else {
      final settings = ref.read(imageWorkflowControllerProvider).enhance;
      final available = NativeImageEnhance.factors(
        current.model,
        size.$1,
        size.$2,
      );
      final factor =
          params['scale'] ??
          (available.contains(settings.upscaleFactor)
              ? settings.upscaleFactor
              : 1.0);
      final max =
          params['max'] ??
          (settings.maxUpscale &&
              MaxEnhanceMath.isEligible(current.model, size.$1, size.$2));
      final level = params['magnitude'];
      final strength = params['strength'], noise = params['noise'];
      if (factor is! num ||
          !factor.isFinite ||
          max is! bool ||
          (level != null && (level is! int || level < 1 || level > 5)) ||
          [strength, noise].any(
            (v) => v != null && (v is! num || !v.isFinite || v < 0 || v > 1),
          ) ||
          (level != null && (strength != null || noise != null))) {
        throw const NaiAgentToolError(
          'invalid_options',
          'Use magnitude 1..5 or strength/noise 0..1 and a native scale',
        );
      }
      if ((max &&
              !MaxEnhanceMath.isEligible(current.model, size.$1, size.$2)) ||
          (!max &&
              !NativeImageEnhance.factors(
                current.model,
                size.$1,
                size.$2,
              ).contains(factor)) ||
          (max && params['scale'] != null)) {
        throw const NaiAgentToolError(
          'invalid_scale',
          'Use an available native scale, or eligible V5 Max without scale',
        );
      }
      final defaults = level != null
          ? NativeImageEnhance.magnitude(((level as int) - 1) / 4)
          : settings.showIndividualSettings
          ? (settings.strength, settings.noise)
          : NativeImageEnhance.magnitude(settings.magnitude);
      projected =
          NativeImageEnhance.project(
            current: native
                .preparePromptParams(current)
                .copyWith(inpaintFocusRegion: null),
            source: source.bytes,
            width: size.$1,
            height: size.$2,
            factor: factor.toDouble(),
            max: max,
            strength: (strength as num?)?.toDouble() ?? defaults.$1,
            noise: (noise as num?)?.toDouble() ?? defaults.$2,
          ).copyWith(
            nSamples: 1,
            seed: -1,
            extraNoiseSeed: null,
            addOriginalImage: false,
          );
    }
    // Clone reference/source bytes as well as the immutable request fields.
    final encoded = jsonEncode(encodeAgentImageParams(projected));
    final storageBytes = utf8.encode(encoded).length + source.bytes.length;
    _requests.removeWhere(
      (_, r) => !r.reserved && !r.expires.isAfter(DateTime.now()),
    );
    _quoteRequests.removeWhere((_, r) => !_requests.containsKey(r.id));
    if (_requests.length >= 5 ||
        storageBytes +
                _requests.values.fold<int>(0, (n, r) => n + r.storageBytes) >
            AgentWorkspaceFiles.maxBytes) {
      throw const NaiAgentToolError(
        'quote_busy',
        'Source quote storage is full; run or expire existing quotes',
      );
    }
    final request = _SourceRequest(
      source,
      decodeAgentImageParams(
        Map<String, dynamic>.from(jsonDecode(encoded) as Map),
      ),
      operation as String,
      storageBytes,
    );
    _requests[request.id] = request;
    try {
      final result = await generation.prepare({
        'request_id': request.id,
      }, token);
      _quoteRequests[result['details']['quote']['quote_id'] as String] =
          request;
      return result;
    } catch (_) {
      _requests.remove(request.id);
      rethrow;
    }
  }
}
