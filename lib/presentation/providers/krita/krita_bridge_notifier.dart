import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/krita/krita_bridge_server.dart';
import '../../../core/krita/bridge_session.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/datasources/remote/nai_image_generation_api_service.dart';
import '../image_generation_provider.dart';
import '../image_save_settings_provider.dart';
import '../pill_roll_coordinator.dart';
import 'krita_bridge_service.dart';
import 'bridge_draft_snapshot.dart';
import 'bridge_draft_writer.dart';
import '../auth_provider.dart';

import '../character_prompt_provider.dart';
import '../prompt_token_counter_provider.dart';

typedef KritaBridgeServerFactory = KritaBridgeServer Function();
final kritaBridgeServerFactoryProvider = Provider<KritaBridgeServerFactory>(
  (ref) =>
      () => KritaBridgeServer(),
);
typedef KritaBridgeEnabledPersister = FutureOr<void> Function(bool enabled);
typedef KritaBridgeServiceFactory =
    KritaBridgeMessageService Function(KritaBridgeServer server);

enum KritaBridgeStatus { disabled, starting, listening, connected, error }

class KritaBridgeState {
  const KritaBridgeState({
    this.enabled = false,
    this.status = KritaBridgeStatus.disabled,
    this.port,
    this.secret,
    this.discoveryFilePath,
    this.connectedClientLabel,
    this.activeRequestId,
    this.errorMessage,
    this.session = const BridgeSession(),
  });

  final bool enabled;
  final KritaBridgeStatus status;
  final int? port;
  final String? secret;
  final String? discoveryFilePath;
  final String? connectedClientLabel;
  final String? activeRequestId;
  final String? errorMessage;
  final BridgeSession session;

  bool get isActive =>
      status == KritaBridgeStatus.listening ||
      status == KritaBridgeStatus.connected;

  bool get isBridgeGenerating => activeRequestId != null;

  KritaBridgeState copyWith({
    bool? enabled,
    KritaBridgeStatus? status,
    int? port,
    String? secret,
    String? discoveryFilePath,
    String? connectedClientLabel,
    String? activeRequestId,
    String? errorMessage,
    bool clearSession = false,
    bool clearConnectedClientLabel = false,
    bool clearActiveRequest = false,
    bool clearError = false,
    BridgeSession? session,
  }) {
    return KritaBridgeState(
      enabled: enabled ?? this.enabled,
      status: status ?? this.status,
      port: clearSession ? null : (port ?? this.port),
      secret: clearSession ? null : (secret ?? this.secret),
      discoveryFilePath: clearSession
          ? null
          : (discoveryFilePath ?? this.discoveryFilePath),
      connectedClientLabel: clearSession || clearConnectedClientLabel
          ? null
          : (connectedClientLabel ?? this.connectedClientLabel),
      activeRequestId: clearSession || clearActiveRequest
          ? null
          : (activeRequestId ?? this.activeRequestId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      session: clearSession ? const BridgeSession() : (session ?? this.session),
    );
  }
}

class KritaBridgeNotifier extends StateNotifier<KritaBridgeState> {
  KritaBridgeNotifier({
    KritaBridgeServerFactory? serverFactory,
    KritaBridgeEnabledPersister? persistEnabled,
    KritaBridgeServiceFactory? serviceFactory,
  }) : _serverFactory = serverFactory ?? (() => KritaBridgeServer()),
       _persistEnabled = persistEnabled,
       _serviceFactory = serviceFactory,
       super(const KritaBridgeState());

  final KritaBridgeServerFactory _serverFactory;
  final KritaBridgeEnabledPersister? _persistEnabled;
  final KritaBridgeServiceFactory? _serviceFactory;
  KritaBridgeServer? _server;
  KritaBridgeMessageService? _service;
  StreamSubscription? _messagesSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<BridgeSession>? _sessionSubscription;
  StreamSubscription<BridgeClient>? _disconnectSubscription;
  static const String _logTag = 'KritaBridge';

  KritaBridgeServer? get server => _server;

  Future<void> setEnabled(bool enabled) async {
    if (enabled) {
      await enable();
    } else {
      await disable();
    }
  }

  Future<void> enable({bool persist = true}) async {
    if (state.isActive || state.status == KritaBridgeStatus.starting) {
      return;
    }

    state = state.copyWith(
      enabled: true,
      status: KritaBridgeStatus.starting,
      clearSession: true,
      clearError: true,
    );

    final server = _serverFactory();
    try {
      AppLogger.i('Enabling Krita bridge', _logTag);
      await server.start(preferredPort: 0);
      _server = server;
      _service = _serviceFactory?.call(server);
      _service?.setActiveRequestReporter(_setActiveRequest);
      _messagesSubscription = server.requests.listen((request) {
        final service = _service;
        if (service == null) {
          return;
        }
        unawaited(
          server.inClientScope(request, () => service.handle(request.message)),
        );
      });
      _sessionSubscription = server.sessionChanges.listen((session) {
        if (mounted && state.enabled) state = state.copyWith(session: session);
      });
      _disconnectSubscription = server.disconnections.listen((client) {
        if (server.ownsActiveOperation(client.id)) {
          _service?.handleClientDisconnected();
        }
      });
      _connectionSubscription = server.authenticationChanges.listen((
        connected,
      ) {
        if (!mounted || !state.enabled) {
          return;
        }
        AppLogger.i(
          connected ? 'Krita client connected' : 'Krita client disconnected',
          _logTag,
        );
        state = state.copyWith(
          status: connected
              ? KritaBridgeStatus.connected
              : KritaBridgeStatus.listening,
          connectedClientLabel: connected ? server.connectedClientLabel : null,
          clearConnectedClientLabel: !connected,
        );
      });
      if (!mounted) {
        await server.dispose();
        return;
      }
      state = KritaBridgeState(
        enabled: true,
        status: KritaBridgeStatus.listening,
        port: server.port,
        secret: server.secret,
        discoveryFilePath: server.discoveryFile.path,
      );
      if (persist) {
        await _persistEnabled?.call(true);
      }
      if (!mounted) {
        await server.dispose();
        return;
      }
      AppLogger.i('Krita bridge enabled on port ${server.port}', _logTag);
    } catch (error) {
      await server.dispose();
      AppLogger.e('Failed to enable Krita bridge', error, null, _logTag);
      if (!mounted) {
        return;
      }
      state = KritaBridgeState(
        enabled: false,
        status: KritaBridgeStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> disable({bool persist = true}) async {
    if (state.isBridgeGenerating) {
      _service?.handleClientDisconnected();
    }

    await _messagesSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _sessionSubscription?.cancel();
    await _disconnectSubscription?.cancel();
    _messagesSubscription = null;
    _connectionSubscription = null;
    _sessionSubscription = null;
    _disconnectSubscription = null;
    _service = null;

    final server = _server;
    _server = null;
    if (server != null) {
      AppLogger.i('Disabling Krita bridge', _logTag);
      await server.dispose();
    }

    if (!mounted) {
      return;
    }
    state = const KritaBridgeState();
    if (persist) {
      await _persistEnabled?.call(false);
    }
    AppLogger.i('Krita bridge disabled', _logTag);
  }

  void _setActiveRequest(String? requestId) {
    if (!mounted || !state.enabled) {
      return;
    }
    state = state.copyWith(
      activeRequestId: requestId,
      clearActiveRequest: requestId == null,
    );
  }

  bool sendImageToKrita(Uint8List image, {required String name}) {
    final server = _server;
    if (server == null || !server.isClientAuthenticated) {
      AppLogger.w(
        'Cannot send image to Krita: no authenticated client',
        _logTag,
      );
      return false;
    }

    server.send({
      'type': 'push_image',
      'image': base64Encode(image),
      'name': name,
    });
    AppLogger.i('Sent image to Krita: $name (${image.length} bytes)', _logTag);
    return true;
  }

  Future<void> regenerateSession() async {
    if (!state.enabled) {
      return;
    }

    await disable(persist: false);
    await enable(persist: false);
    AppLogger.i('Krita bridge session regenerated', _logTag);
  }

  Future<void> disconnectAgents() async => _server?.disconnectAgents();
  void cancelActiveRequest() => _service?.handleClientDisconnected();

  Future<void> close() async {
    await disable(persist: false);
  }

  @override
  void dispose() {
    unawaited(close());
    super.dispose();
  }
}

final kritaBridgePromptPreparerProvider = Provider<KritaBridgeParamsPreparer>(
  (ref) =>
      (params, overrides) => ref
          .read(imageGenerationNotifierProvider.notifier)
          .preparePromptParams(
            params,
            useParamsCharacters:
                overrides.containsKey('characters') ||
                overrides['clear_characters'] == true,
            useParamsQualityPreset:
                overrides.containsKey('quality_preset') ||
                overrides.containsKey('quality_toggle'),
            useParamsUcPreset: overrides.containsKey('uc_preset'),
          ),
);

final kritaBridgeNotifierProvider =
    StateNotifierProvider<KritaBridgeNotifier, KritaBridgeState>((ref) {
      final box = Hive.box(StorageKeys.settingsBox);
      final notifier = KritaBridgeNotifier(
        serverFactory: ref.read(kritaBridgeServerFactoryProvider),
        persistEnabled: (enabled) =>
            box.put(StorageKeys.kritaBridgeEnabled, enabled),
        serviceFactory: (server) => KritaBridgeService(
          isAgentRequest: () => server.currentClient?.isAgent ?? false,
          requesterName: () => server.currentClient?.name ?? 'External Agent',
          readAccountIdentity: () => ref.read(authNotifierProvider).accountId,
          isRequestAlive: () => server.session.clients.any(
            (c) => c.id == server.currentClient?.id,
          ),
          readDraft: () => readBridgeDraft(ref),
          acknowledgeDraft: server.acknowledgeDraft,
          backupDraft: (draft) =>
              backupBridgeDraft(server.discoveryFile.parent, draft),
          readBilling: (params) => readBridgeBilling(ref, params),
          readBaseParams: () => ref.read(generationParamsNotifierProvider),
          prepareParams: ref.read(kritaBridgePromptPreparerProvider),
          // P2.5：桥接生成受理后重 roll 随机块实例（逐张重抽）
          onGenerationEnqueued: () =>
              ref.read(pillRollCoordinatorProvider).rollAllLanesAndSync(),
          readPromptSnapshot: (params) =>
              (prompt: params.prompt, negativePrompt: params.negativePrompt),
          // AI 接管扩展：set_params → GenerationParamsNotifier setters。
          // seed_lock 是协议兼容派生值：有值即固定，无独立锁标志
          readSeedLock: () =>
              ref.read(generationParamsNotifierProvider).seed != -1,
          // AI 接管扩展：get_params 回读 UI 角色框系统（界面可见的那套）
          readCharacters: () {
            final config = ref.read(characterPromptNotifierProvider);
            return [
              for (final c in config.characters)
                {
                  'name': c.name,
                  'prompt': c.prompt,
                  'uc': c.negativePrompt,
                  'enabled': c.enabled,
                  if (c.customPosition != null) ...{
                    'x': c.customPosition!.column,
                    'y': c.customPosition!.row,
                  },
                },
            ];
          },
          // AI 接管扩展：token 用量回读（与 UI 的 373/512 计数器同源）
          readTokens: () async {
            final positive = await ref.read(
              promptTokenUsageProvider(PromptTokenCountTarget.positive).future,
            );
            final negative = await ref.read(
              promptTokenUsageProvider(PromptTokenCountTarget.negative).future,
            );
            return {
              'prompt_tokens': positive?.usedTokens,
              'prompt_token_limit': positive?.limit,
              'uc_tokens': negative?.usedTokens,
            };
          },
          writeParams: ref.read(bridgeDraftWriterProvider),
          send: server.send,
          isUiGenerating: () =>
              ref.read(imageGenerationNotifierProvider).isGenerating,
          generateStream: (request) {
            final apiService = ref.read(naiImageGenerationApiServiceProvider);
            return apiService.generateImageStream(request.params);
          },
          generateFallback: (request) async {
            final apiService = ref.read(naiImageGenerationApiServiceProvider);
            return apiService.generateImageArtifactsCancellable(
              request.params,
              onProgress: (_, __) {},
            );
          },
          registerExternalImage: (image, {required params, addToDisplay}) => ref
              .read(imageGenerationNotifierProvider.notifier)
              .registerExternalImage(
                image,
                params: params,
                saveToLocal: ref
                    .read(imageSaveSettingsNotifierProvider)
                    .autoSave,
                addToDisplay: addToDisplay ?? false,
              ),
          cancelGeneration: () =>
              ref.read(naiImageGenerationApiServiceProvider).cancelGeneration(),
        ),
      );
      final enabled =
          box.get(StorageKeys.kritaBridgeEnabled, defaultValue: false) as bool;
      if (enabled) {
        unawaited(notifier.enable(persist: false));
      }
      ref.onDispose(() {
        unawaited(notifier.close());
      });
      return notifier;
    });
