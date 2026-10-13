import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/nai_agent/agent_tool.dart';
import '../../../core/nai_agent/generation_tools.dart';
import '../../../core/nai_agent/studio_tools.dart';
import '../../../core/network/nai_api_endpoint_service.dart';
import '../../../core/services/anlas_calculator.dart';
import '../../../core/utils/image_save_utils.dart';
import '../../../core/utils/nai_resolution_adapter.dart';
import '../../../data/models/director/director_tool_type.dart';
import '../../../data/models/image/image_operation.dart';
import '../../../data/models/user/user_subscription.dart';
import '../../../data/services/director/pixel_snap_service.dart';
import '../../../data/services/nai_agent/agent_workspace_files.dart';
import '../auth_provider.dart';
import '../director_tools_notifier.dart';
import '../generation/cloud_upscale_provider.dart';
import '../image_generation_provider.dart';
import '../subscription_provider.dart';
import 'nai_agent_image_approvals.dart';

class _ImageQuote {
  _ImageQuote(
    this.source,
    this.params,
    this.accountId,
    this.endpoint,
    this.cost,
    this.summary,
  );
  final String id = const Uuid().v4();
  final DateTime expires = DateTime.now().add(const Duration(minutes: 5));
  final NaiAgentImage source;
  final Map<String, dynamic> params, summary;
  final String accountId, endpoint;
  final int cost;
  bool reserved = false;
  Map<String, dynamic> toJson() => {
    'quote_id': id,
    'expires_at': expires.toIso8601String(),
    ...summary,
    ...params,
    'estimated_anlas': cost,
    'authorization': 'explicit_user_button_required',
  };
}

/// Paid operations require a live UI decision; model flags never authorize.
class NaiAgentImageActions {
  NaiAgentImageActions(
    this.ref,
    Directory workspace,
    this.loadImage,
    this.isBusy,
    this.isAlive,
    this.owner,
  ) : files = AgentWorkspaceFiles(workspace);
  final Ref ref;
  final AgentWorkspaceFiles files;
  final Future<NaiAgentImage> Function(
    Map<String, dynamic>,
    NaiAgentCancellation,
  )
  loadImage;
  final bool Function() isBusy, isAlive;
  final NaiAgentConversationOwner? owner;
  final _quotes = <String, _ImageQuote>{};
  String? activeId;
  NaiAgentCancellation? _activeToken;
  String? _phase;
  static const tools = [
    'cloud_upscale',
    'removeBackground',
    'extractLineArt',
    'toSketch',
    'colorize',
    'fixEmotion',
    'declutter',
  ];
  Map<String, dynamic> status() => {
    'job_id': activeId,
    'owned': activeId != null,
    'phase': _phase,
    'cancelling': _activeToken?.isCancelled ?? false,
    'studio_busy': isBusy(),
  };
  void _check(NaiAgentCancellation token) {
    token.check();
    if (!isAlive()) {
      throw const NaiAgentToolError('closed', 'Image binding closed');
    }
  }

  void _admit(NaiAgentCancellation token) {
    _check(token);
    if (isBusy() || activeId != null) {
      throw const NaiAgentToolError('busy', 'Studio image task is active');
    }
  }

  String get _endpoint =>
      jsonEncode(ref.read(naiApiEndpointServiceProvider).current.toJson());
  UserSubscription? get _subscription {
    final loaded = ref.exists(subscriptionNotifierProvider)
        ? ref.read(subscriptionNotifierProvider).subscription
        : null;
    final raw = ref.read(authNotifierProvider).subscriptionInfo;
    return loaded ?? (raw == null ? null : UserSubscription.fromJson(raw));
  }

  int _cost(String tool, NaiAgentImage source) {
    final size = NaiResolutionAdapter.readImageSize(source.bytes)!;
    return tool == 'cloud_upscale'
        ? AnlasCalculator.calculateNovelAiUpscaleCost(
            inputWidth: size.$1,
            inputHeight: size.$2,
          )
        : AnlasCalculator.calculateAugmentCost(
            width: size.$1,
            height: size.$2,
            isBgRemoval: tool == 'removeBackground',
            isOpus: _subscription?.isOpus == true,
          );
  }

  void _validQuote(_ImageQuote q, NaiAgentCancellation token) {
    _admit(token);
    final auth = ref.read(authNotifierProvider), subscription = _subscription;
    if (!_quotes.containsKey(q.id) || !q.expires.isAfter(DateTime.now())) {
      throw const NaiAgentToolError(
        'quote_expired',
        'Prepare a new image quote',
      );
    }
    if (!auth.isAuthenticated ||
        auth.accountId != q.accountId ||
        _endpoint != q.endpoint ||
        _cost(q.params['tool'], q.source) != q.cost) {
      throw const NaiAgentToolError(
        'quote_changed',
        'Account, endpoint or image price changed',
      );
    }
    if (subscription?.trainingStepsLeft == null) {
      throw const NaiAgentToolError(
        'balance_unavailable',
        'No cached account balance',
      );
    }
    if (subscription!.anlasBalance < q.cost) {
      throw const NaiAgentToolError(
        'insufficient_balance',
        'Insufficient Anlas',
      );
    }
  }

  PixelSnapOptions _pixel(Object? value) {
    if (value == null) return const PixelSnapOptions();
    if (value is! Map ||
        value.keys.any(
          (k) => !{
            'paletteMode',
            'colors',
            'avoidOverRefining',
            'upscale',
          }.contains(k),
        )) {
      throw const NaiAgentToolError(
        'invalid_options',
        'Invalid Pixel Snap options',
      );
    }
    final mode = value['paletteMode'] ?? 'auto', colors = value['colors'] ?? 64;
    if (!PixelSnapPaletteMode.values.any((m) => m.name == mode) ||
        colors is! int ||
        colors < 16 ||
        colors > 256 ||
        (value.containsKey('avoidOverRefining') &&
            value['avoidOverRefining'] is! bool) ||
        (value.containsKey('upscale') && value['upscale'] is! bool)) {
      throw const NaiAgentToolError(
        'invalid_options',
        'Use bounded native Pixel Snap options',
      );
    }
    return PixelSnapOptions(
      paletteMode: PixelSnapPaletteMode.values.firstWhere(
        (m) => m.name == mode,
      ),
      colors: colors,
      avoidOverRefining: value['avoidOverRefining'] ?? false,
      upscale: value['upscale'] ?? false,
    );
  }

  Map<String, dynamic> _pixelJson(PixelSnapOptions p) => {
    'paletteMode': p.paletteMode.name,
    'colors': p.colors,
    'avoidOverRefining': p.avoidOverRefining,
    'upscale': p.upscale,
  };
  Future<Map<String, dynamic>> execute(
    Map<String, dynamic> params,
    NaiAgentCancellation token,
  ) async {
    _check(token);
    final action = params['action'];
    final fields = switch (action) {
      'prepare' => {
        'action',
        'tool',
        'image_id',
        'path',
        'prompt',
        'defry',
        'emotion',
      },
      'run' => {'action', 'quote_id'},
      'pixel_snap' => {'action', 'image_id', 'path', 'pixel'},
      'cancel' => {'action', 'job_id'},
      _ => <String>{},
    };
    if (fields.isEmpty || params.keys.any((k) => !fields.contains(k))) {
      throw const NaiAgentToolError(
        'invalid_image_tool',
        'Unsupported image action or field',
      );
    }
    if (action == 'cancel') {
      if (params['job_id'] != activeId || _activeToken == null) {
        throw const NaiAgentToolError(
          'not_owned',
          'No matching image task belongs to this chat',
        );
      }
      _activeToken!.cancel();
      return naiAgentTextResult({'job_id': activeId, 'cancel_requested': true});
    }
    if (action == 'run') {
      final q = _quotes[params['quote_id']];
      if (q == null || q.reserved || owner == null) {
        throw const NaiAgentToolError(
          'quote_missing',
          'Read a fresh quote in this chat',
        );
      }
      _validQuote(q, token);
      q.reserved = true;
      try {
        final accepted = await ref
            .read(naiAgentImageApprovalsProvider)
            .request(
              owner!,
              q.toJson(),
              q.expires,
              token,
              () => _validQuote(q, token),
              sourceBytes: q.source.bytes,
            );
        if (!accepted) {
          return naiAgentTextResult({
            'ok': false,
            'cancelled': true,
            'quote_id': q.id,
          });
        }
        _validQuote(q, token);
        final backup = await files.export(
          'image-request.json',
          Uint8List.fromList(utf8.encode(jsonEncode(q.toJson()))),
          () => _validQuote(q, token),
          companions: {_sourceName(q.source.bytes): q.source.bytes},
        );
        _validQuote(q, token);
        return await _run(
          q.source,
          q.params,
          token,
          cost: q.cost,
          backup: backup,
          onStarted: () => _quotes.remove(q.id),
        );
      } finally {
        q.reserved = false;
      }
    }
    _admit(token);
    final tool = params['tool'];
    if (action == 'prepare') {
      if (owner == null || !tools.contains(tool)) {
        throw const NaiAgentToolError(
          'invalid_tool',
          'Choose a supported image tool in a live chat',
        );
      }
      final prompt = params['prompt'] ?? '',
          defry = params['defry'] ?? 0,
          emotion = params['emotion'] ?? 'neutral';
      final type = DirectorToolType.values
          .where((t) => t.name == tool)
          .firstOrNull;
      if (prompt is! String ||
          prompt.length > 20000 ||
          defry is! int ||
          defry < 0 ||
          defry > 5 ||
          emotion is! String ||
          (params.containsKey('prompt') && type?.needsPrompt != true) ||
          (params.containsKey('defry') && type?.supportsDefry != true) ||
          (params.containsKey('emotion') && tool != 'fixEmotion') ||
          (tool == 'fixEmotion' &&
              !emotionPresets.any((p) => p.mood == emotion))) {
        throw const NaiAgentToolError(
          'invalid_options',
          'Invalid native director options',
        );
      }
    } else {
      _pixel(params['pixel']);
    }
    final loaded = await loadImage({
      if (params.containsKey('image_id')) 'image_id': params['image_id'],
      if (params.containsKey('path')) 'path': params['path'],
    }, token);
    final source = NaiAgentImage(
      id: loaded.id,
      bytes: Uint8List.fromList(loaded.bytes),
    );
    _admit(token);
    if (action == 'pixel_snap') {
      return _run(
        source,
        {'tool': 'pixelSnap', 'pixel': _pixelJson(_pixel(params['pixel']))},
        token,
        cost: 0,
      );
    }
    final cost = _cost(tool, source),
        auth = ref.read(authNotifierProvider),
        size = NaiResolutionAdapter.readImageSize(source.bytes)!;
    if (cost < 0) {
      throw const NaiAgentToolError(
        'size_limit',
        'Cloud upscale input exceeds the native size limit',
      );
    }
    if (!auth.isAuthenticated || auth.accountId == null) {
      throw const NaiAgentToolError(
        'account_unavailable',
        'No active NovelAI account',
      );
    }
    _quotes.removeWhere(
      (_, q) => !q.expires.isAfter(DateTime.now()) && !q.reserved,
    );
    if (_quotes.length >= 5 ||
        _quotes.values.fold<int>(
              source.bytes.length,
              (sum, q) => sum + q.source.bytes.length,
            ) >
            64 * 1024 * 1024) {
      throw const NaiAgentToolError(
        'quote_limit',
        'Finish or expire existing image quotes',
      );
    }
    final q = _ImageQuote(
      source,
      {
        'tool': tool,
        if (DirectorToolType.values.any((t) => t.name == tool && t.needsPrompt))
          'prompt': params['prompt'] ?? '',
        if (DirectorToolType.values.any(
          (t) => t.name == tool && t.supportsDefry,
        ))
          'defry': params['defry'] ?? 0,
        if (tool == 'fixEmotion') 'emotion': params['emotion'] ?? 'neutral',
      },
      auth.accountId!,
      _endpoint,
      cost,
      {
        'account_name': auth.displayName ?? '',
        'balance_anlas': _subscription?.trainingStepsLeft == null
            ? null
            : _subscription!.anlasBalance,
        'width': size.$1,
        'height': size.$2,
        'source_image_id': source.id,
      },
    );
    _quotes[q.id] = q;
    return naiAgentTextResult({'quote': q.toJson()});
  }

  String _sourceName(Uint8List b) => b[0] == 137
      ? 'source.png'
      : b[0] == 255
      ? 'source.jpg'
      : b[0] == 71
      ? 'source.gif'
      : 'source.webp';
  Future<Map<String, dynamic>> _run(
    NaiAgentImage source,
    Map<String, dynamic> request,
    NaiAgentCancellation token, {
    required int cost,
    String? backup,
    void Function()? onStarted,
  }) async {
    _admit(token);
    final nativeToken = CancelToken();
    unawaited(token.whenCancelled.then((_) => nativeToken.cancel()));
    activeId = const Uuid().v4();
    _activeToken = token;
    _phase = 'processing';
    var admitted = false;
    void started() {
      admitted = true;
      onStarted?.call();
    }

    try {
      final tool = request['tool'] as String;
      final List<Uint8List>? results;
      if (tool == 'cloud_upscale') {
        final result = await ref
            .read(cloudUpscaleTaskProvider.notifier)
            .processGenerated(
              source.bytes,
              cancellation: nativeToken,
              onStarted: started,
            );
        results = result == null ? null : [result];
      } else {
        results = await ref
            .read(directorToolsNotifierProvider.notifier)
            .processGenerated(
              source.bytes,
              tool: DirectorToolType.values.firstWhere((t) => t.name == tool),
              prompt: tool == 'fixEmotion'
                  ? '${request['emotion']};;${request['prompt']}'
                  : request['prompt'] ?? '',
              defry: request['defry'] ?? 0,
              pixelOptions: _pixel(request['pixel']),
              cancellation: nativeToken,
              onStarted: started,
            );
      }
      _check(token);
      if (!admitted) {
        throw const NaiAgentToolError(
          'busy',
          'Native image task was already admitted',
        );
      }
      if (results == null || results.isEmpty || results.length > 4) {
        throw const NaiAgentToolError(
          'image_process_failed',
          'Native image tool returned no valid results',
        );
      }
      _phase = 'saving';
      final outputs = <Map<String, dynamic>>[], bytes = <Uint8List>[];
      for (final result in results) {
        final size = NaiResolutionAdapter.readImageSize(result);
        if (size == null || size.$1 * size.$2 > 64000000) {
          throw const NaiAgentToolError(
            'invalid_result',
            'Native image result is invalid',
          );
        }
        if (tool == 'cloud_upscale') {
          final original = NaiResolutionAdapter.readImageSize(source.bytes)!;
          if (size != (original.$1 * 2, original.$2 * 2)) {
            throw const NaiAgentToolError(
              'invalid_result',
              'Cloud upscale must return the frozen 2x dimensions',
            );
          }
        }
        final aligned = await ImageSaveUtils.inheritSourceMetadata(
          imageBytes: result,
          sourceBytes: source.bytes,
          width: size.$1,
          height: size.$2,
        );
        _check(token);
        final path = await files.export(
          'image.png',
          aligned,
          () => _check(token),
          companions: {
            _sourceName(source.bytes): source.bytes,
            'image-tool.json': Uint8List.fromList(
              utf8.encode(
                jsonEncode({
                  'job_id': activeId,
                  ...request,
                  'source_image_id': source.id,
                  'estimated_anlas': cost,
                  if (backup != null) 'request_backup': backup,
                }),
              ),
            ),
          },
        );
        _check(token);
        bytes.add(aligned);
        outputs.add({
          'type': 'image',
          'path': path,
          'width': size.$1,
          'height': size.$2,
        });
      }
      final images = isBusy()
          ? <GeneratedImage>[]
          : ref
                .read(imageGenerationNotifierProvider.notifier)
                .registerToolResults(
                  bytes,
                  operation: tool == 'cloud_upscale'
                      ? ImageOperation.upscale
                      : DirectorToolType.values
                            .firstWhere((t) => t.name == tool)
                            .operation,
                  originalBytes: source.bytes,
                );
      return naiAgentTextResult({
        'ok': true,
        'job_id': activeId,
        'tool': tool,
        'source_image_id': source.id,
        'artifacts': outputs,
        'image_ids': images.map((i) => i.id).toList(),
        'history_registered': images.isNotEmpty,
        'display_changed': false,
        'estimated_anlas': cost,
        if (backup != null) 'request_backup': backup,
      });
    } finally {
      activeId = null;
      _activeToken = null;
      _phase = null;
    }
  }
}
