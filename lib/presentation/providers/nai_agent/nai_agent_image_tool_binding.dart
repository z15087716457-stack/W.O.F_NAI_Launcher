import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/studio_tools.dart';
import '../../../core/nai_agent/generation_tools.dart';
import '../../../core/utils/image_save_utils.dart';
import '../../../core/utils/nai_resolution_adapter.dart';
import '../../../data/models/image/image_operation.dart';
import '../../../data/models/upscale/local_upscale_models.dart';
import '../../../data/services/local_upscale_service.dart';
import '../../../data/services/nai_agent/agent_workspace_files.dart';
import '../generation/local_upscale_provider.dart';
import '../image_generation_provider.dart';
import 'nai_agent_image_actions.dart';

/// Local inference uses the same native task/locks/shutdown as Studio.
class NaiAgentImageToolBinding {
  NaiAgentImageToolBinding(
    this.ref,
    Directory workspace,
    this.loadImage,
    this.isBusy,
    this.isAlive, {
    AgentWorkspaceFiles? workspaceFiles,
    NaiAgentConversationOwner? owner,
  }) : files = workspaceFiles ?? AgentWorkspaceFiles(workspace) {
    _actions = NaiAgentImageActions(
      ref,
      workspace,
      loadImage,
      isBusy,
      isAlive,
      owner,
    );
  }

  final Ref ref;
  final Future<NaiAgentImage> Function(
    Map<String, dynamic>,
    NaiAgentCancellation,
  )
  loadImage;
  final bool Function() isBusy, isAlive;
  final AgentWorkspaceFiles files;
  late final NaiAgentImageActions _actions;
  String? _activeJob;
  LocalUpscaleTask? _ownedTask;
  NaiAgentCancellation? _jobToken;
  bool _started = false;

  void _check(NaiAgentCancellation token) {
    token.check();
    if (!isAlive()) {
      throw const NaiAgentToolError('closed', 'Studio binding closed');
    }
  }

  void _admit(NaiAgentCancellation token) {
    _check(token);
    if (isBusy() || _activeJob != null) {
      throw const NaiAgentToolError(
        'busy',
        'Another Studio image task is active',
      );
    }
  }

  Seedvr2Options _options(Object? value, LocalUpscaleModel model) {
    if (value == null) return const Seedvr2Options();
    const keys = {
      'colorCorrection',
      'seed',
      'blocksToSwap',
      'vaeTiled',
      'vaeTileSize',
      'vaeTileOverlap',
      'inputNoise',
      'latentNoise',
    };
    if (model.method != LocalUpscaleMethod.seedvr2 ||
        value is! Map ||
        value.keys.any((key) => !keys.contains(key))) {
      throw const NaiAgentToolError(
        'invalid_options',
        'SeedVR2 options require a SeedVR2 model',
      );
    }
    final normalized = Seedvr2Options.fromJson(
      value,
      modelId: model.id,
    ).toJson();
    if (value.entries.any(
      (entry) =>
          normalized[entry.key] != entry.value ||
          (normalized[entry.key] is int && entry.value is! int),
    )) {
      throw const NaiAgentToolError(
        'invalid_options',
        'Use valid bounded native SeedVR2 options',
      );
    }
    return Seedvr2Options.fromJson(value, modelId: model.id);
  }

  Future<Map<String, dynamic>> execute(
    Map<String, dynamic> params,
    NaiAgentCancellation token,
  ) async {
    _check(token);
    final action = params['action'];
    if (action == 'prepare' ||
        action == 'run' ||
        action == 'pixel_snap' ||
        (action == 'cancel' && params['job_id'] != _activeJob)) {
      return _actions.execute(params, token);
    }
    final fields = switch (action) {
      'list' || 'status' => {'action'},
      'cancel' => {'action', 'job_id'},
      'upscale' => {
        'action',
        'image_id',
        'path',
        'model_id',
        'scale',
        'seedvr2',
      },
      _ => <String>{},
    };
    if (fields.isEmpty || params.keys.any((key) => !fields.contains(key))) {
      throw const NaiAgentToolError(
        'invalid_image_tool',
        'Unsupported image tool action or field',
      );
    }
    if (action == 'status') {
      if (_actions.activeId != null) {
        return naiAgentTextResult(_actions.status());
      }
      final task = _started && _ownedTask != null
          ? ref.read(localUpscaleTaskProvider)
          : null;
      return naiAgentTextResult({
        'job_id': _activeJob,
        'owned': _activeJob != null,
        'phase': task?.progress?.phase.name,
        'fraction': task?.progress?.fraction,
        'cancelling': _jobToken?.isCancelled ?? false,
        'studio_busy': isBusy(),
      });
    }
    if (action == 'cancel') {
      if (params['job_id'] is! String ||
          params['job_id'] != _activeJob ||
          _jobToken == null) {
        throw const NaiAgentToolError(
          'not_owned',
          'No matching image task belongs to this chat',
        );
      }
      _jobToken!.cancel();
      return naiAgentTextResult({
        'job_id': _activeJob,
        'cancel_requested': true,
      });
    }
    final models = await ref.read(localUpscaleModelsProvider.future);
    _check(token);
    if (action == 'list') {
      return naiAgentTextResult({
        'models': [
          for (final model in models)
            {
              'model_id': model.id,
              'name': model.name,
              'method': model.method.name,
              'installed': model.installed,
              'bundled': model.bundled,
              'custom': model.custom,
              'disk_bytes': model.diskBytes,
              'native_scales': model.scales,
              if (model.method == LocalUpscaleMethod.seedvr2) ...{
                'seedvr2_defaults': const Seedvr2Options().toJson(),
                'max_blocks_to_swap': Seedvr2Options.maxBlocks(model.id),
              },
            },
        ],
        'scale': {'min': 1, 'max': 4},
        'max_native_output_pixels': LocalUpscaleService.maxNativeOutputPixels,
        'downloads': false,
        'anlas': 0,
        'cloud_tools': NaiAgentImageActions.tools,
        'cloud_authorization': 'prepare_then_run_with_explicit_user_button',
        'pixel_snap': {
          'paletteMode': ['off', 'auto', 'custom'],
          'colors': {'min': 16, 'max': 256},
          'avoidOverRefining': false,
          'upscale': false,
          'anlas': 0,
        },
      });
    }
    _admit(token);
    final id = params['model_id'], scale = params['scale'];
    final model = models.where((model) => model.id == id).firstOrNull;
    if (model == null || !model.installed) {
      throw const NaiAgentToolError(
        'model_missing',
        'Choose an installed model from image_tool(list)',
      );
    }
    if (scale is! num || !scale.isFinite || scale < 1 || scale > 4) {
      throw const NaiAgentToolError(
        'invalid_scale',
        'Scale must be finite and between 1 and 4',
      );
    }
    final options = _options(params['seedvr2'], model);
    final source = await loadImage({
      if (params.containsKey('image_id')) 'image_id': params['image_id'],
      if (params.containsKey('path')) 'path': params['path'],
    }, token);
    _admit(token);
    final size = NaiResolutionAdapter.readImageSize(source.bytes)!;
    final width = (size.$1 * scale).round(), height = (size.$2 * scale).round();
    final nativeScale = model.inferenceScale(scale.toDouble());
    if ((size.$1 * nativeScale).round() * (size.$2 * nativeScale).round() >
        LocalUpscaleService.maxNativeOutputPixels) {
      throw const NaiAgentToolError(
        'size_limit',
        'Native model output exceeds 64 million pixels',
      );
    }
    final job = const Uuid().v4(),
        task = ref.read(localUpscaleTaskProvider.notifier);
    _activeJob = job;
    _ownedTask = task;
    _jobToken = token;
    final nativeCancellation = LocalUpscaleCancellation();
    unawaited(
      token.whenCancelled.then((_) {
        nativeCancellation.cancel();
      }),
    );
    try {
      final result = await task.processGenerated(
        source.bytes,
        modelId: model.id,
        scale: scale.toDouble(),
        seedvr2Options: options,
        onStarted: () => _started = true,
        cancellation: nativeCancellation,
      );
      final admitted = _started;
      _started = false;
      _check(token);
      if (!admitted) {
        throw const NaiAgentToolError(
          'busy',
          'Native image task was already admitted',
        );
      }
      if (result == null) {
        final code =
            ref.read(localUpscaleTaskProvider).error?.name ?? 'processFailed';
        throw NaiAgentToolError(code, 'Native local upscale failed');
      }
      final actual = NaiResolutionAdapter.readImageSize(result.bytes);
      if (actual != (width, height) ||
          result.width != width ||
          result.height != height) {
        throw const NaiAgentToolError(
          'invalid_result',
          'Native output dimensions do not match the frozen request',
        );
      }
      final bytes = await ImageSaveUtils.inheritSourceMetadata(
        imageBytes: result.bytes,
        sourceBytes: source.bytes,
        width: width,
        height: height,
      );
      _check(token);
      final sourceName = source.bytes[0] == 137
          ? 'source.png'
          : source.bytes[0] == 255
          ? 'source.jpg'
          : source.bytes[0] == 71
          ? 'source.gif'
          : 'source.webp';
      final output = await files.export(
        'image.png',
        bytes,
        () => _check(token),
        companions: {
          sourceName: source.bytes,
          'image-tool.json': Uint8List.fromList(
            utf8.encode(
              jsonEncode({
                'job_id': job,
                'action': action,
                'source_image_id': source.id,
                'model_id': model.id,
                'scale': scale,
                'width': width,
                'height': height,
                if (model.method == LocalUpscaleMethod.seedvr2)
                  'seedvr2': options.toJson(),
              }),
            ),
          ),
        },
      );
      _check(token);
      final images = isBusy()
          ? <GeneratedImage>[]
          : ref
                .read(imageGenerationNotifierProvider.notifier)
                .registerToolResults(
                  [bytes],
                  operation: ImageOperation.upscale,
                  originalBytes: source.bytes,
                );
      return naiAgentTextResult({
        'ok': true,
        'job_id': job,
        'source_image_id': source.id,
        'model_id': model.id,
        'scale': scale,
        'width': width,
        'height': height,
        'path': output,
        'image_id': images.firstOrNull?.id,
        'history_registered': images.isNotEmpty,
        'display_changed': false,
        'source_path': output.replaceFirst(RegExp(r'image\.png$'), sourceName),
        'artifacts': [
          {'type': 'image', 'path': output, 'width': width, 'height': height},
        ],
        'anlas': 0,
      });
    } finally {
      _started = false;
      _activeJob = null;
      _ownedTask = null;
      _jobToken = null;
    }
  }
}
