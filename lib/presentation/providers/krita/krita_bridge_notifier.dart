import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/krita/krita_bridge_server.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/datasources/remote/nai_image_generation_api_service.dart';
import '../fixed_tags_provider.dart';
import '../generation/image_workflow_controller.dart';
import '../image_generation_provider.dart';
import '../image_save_settings_provider.dart';
import 'krita_bridge_service.dart';

import 'package:uuid/uuid.dart';

import '../../../data/models/character/character_prompt.dart' as char_model;
import '../../../data/models/image/image_params.dart';
import '../character_prompt_provider.dart';

typedef KritaBridgeServerFactory = KritaBridgeServer Function();
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
  });

  final bool enabled;
  final KritaBridgeStatus status;
  final int? port;
  final String? secret;
  final String? discoveryFilePath;
  final String? connectedClientLabel;
  final String? activeRequestId;
  final String? errorMessage;

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
      _messagesSubscription = server.messages.listen((message) {
        final service = _service;
        if (service == null) {
          return;
        }
        unawaited(service.handle(message));
      });
      _connectionSubscription = server.authenticationChanges.listen((
        connected,
      ) {
        if (!mounted || !state.enabled) {
          return;
        }
        if (!connected) {
          _service?.handleClientDisconnected();
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
        await server.stop();
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
        await server.stop();
        return;
      }
      AppLogger.i('Krita bridge enabled on port ${server.port}', _logTag);
    } catch (error) {
      await server.stop();
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
    _messagesSubscription = null;
    _connectionSubscription = null;
    _service = null;

    final server = _server;
    _server = null;
    if (server != null) {
      AppLogger.i('Disabling Krita bridge', _logTag);
      await server.stop();
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

  Future<void> close() async {
    await disable(persist: false);
  }

  @override
  void dispose() {
    unawaited(close());
    super.dispose();
  }
}

final kritaBridgeNotifierProvider =
    StateNotifierProvider<KritaBridgeNotifier, KritaBridgeState>((ref) {
      final box = Hive.box(StorageKeys.settingsBox);
      final notifier = KritaBridgeNotifier(
        persistEnabled: (enabled) =>
            box.put(StorageKeys.kritaBridgeEnabled, enabled),
        serviceFactory: (server) => KritaBridgeService(
          readBaseParams: () => ref.read(generationParamsNotifierProvider),
          readPromptSnapshot: (params) {
            final fixedTags = ref.read(fixedTagsNotifierProvider);
            return (
              prompt: fixedTags.applyToPrompt(params.prompt),
              negativePrompt: fixedTags.applyToNegativePrompt(
                params.negativePrompt,
              ),
            );
          },
          readMinimumContextPixels: () => ref
              .read(imageWorkflowControllerProvider)
              .minimumContextMegaPixels
              .round()
              .clamp(16, 192)
              .toInt(),
          // AI 接管扩展：set_params → GenerationParamsNotifier setters
          writeParams: (payload) {
            final notifier = ref.read(
              generationParamsNotifierProvider.notifier,
            );
            final applied = <String>[];
            String? str(String k) =>
                payload[k] is String ? payload[k] as String : null;
            int? integer(String k) =>
                payload[k] is num ? (payload[k] as num).toInt() : null;
            double? dbl(String k) =>
                payload[k] is num ? (payload[k] as num).toDouble() : null;
            bool? flag(String k) =>
                payload[k] is bool ? payload[k] as bool : null;

            void apply<T>(String key, T? value, void Function(T) setter) {
              if (value != null) {
                setter(value);
                applied.add(key);
              }
            }

            apply<String>('prompt', str('prompt'), notifier.updatePrompt);
            apply<String>(
              'negative_prompt',
              str('negative_prompt'),
              notifier.updateNegativePrompt,
            );
            apply<String>('model', str('model'), notifier.updateModel);
            apply<int>('steps', integer('steps'), notifier.updateSteps);
            apply<double>(
              'cfg_scale',
              dbl('cfg_scale'),
              notifier.updateScale,
            );
            apply<String>(
              'sampler',
              str('sampler'),
              notifier.updateSampler,
            );
            apply<int>('seed', integer('seed'), notifier.updateSeed);
            final seedLock = flag('seed_lock');
            if (seedLock != null && seedLock != notifier.isSeedLocked) {
              notifier.toggleSeedLock();
              applied.add('seed_lock');
            }
            apply<int>(
              'n_samples',
              integer('n_samples'),
              notifier.updateNSamples,
            );
            apply<int>(
              'uc_preset',
              integer('uc_preset'),
              notifier.updateUcPreset,
            );
            apply<bool>(
              'quality_toggle',
              flag('quality_toggle'),
              notifier.updateQualityToggle,
            );
            apply<double>(
              'cfg_rescale',
              dbl('cfg_rescale'),
              notifier.updateCfgRescale,
            );
            apply<String>(
              'noise_schedule',
              str('noise_schedule'),
              notifier.updateNoiseSchedule,
            );
            apply<bool>(
              'variety_plus',
              flag('variety_plus'),
              notifier.updateVarietyPlus,
            );
            apply<bool>(
              'smea_auto',
              flag('smea_auto'),
              notifier.updateSmeaAuto,
            );
            apply<bool>('smea', flag('smea'), notifier.updateSmea);
            apply<bool>(
              'smea_dyn',
              flag('smea_dyn'),
              notifier.updateSmeaDyn,
            );
            apply<bool>(
              'use_coords',
              flag('use_coords'),
              notifier.updateUseCoords,
            );

            final w = integer('width');
            final h = integer('height');
            if (w != null || h != null) {
              final cur = ref.read(generationParamsNotifierProvider);
              notifier.updateSize(w ?? cur.width, h ?? cur.height);
              if (w != null) applied.add('width');
              if (h != null) applied.add('height');
            }

            final chars = payload['characters'];
            if (chars is List) {
              // 双写：UI 角色系统（characterPromptNotifier，界面可见+UI生成用）
              //      + 生成参数态（generationParams.characters，桥接 generate 用）
              final uiChars = <char_model.CharacterPrompt>[];
              final paramChars = <CharacterPrompt>[];
              var index = 0;
              for (final entry in chars) {
                if (entry is! Map || entry['prompt'] is! String) continue;
                final prompt = entry['prompt'] as String;
                final uc = entry['uc'] is String ? entry['uc'] as String : '';
                final x = entry['x'] is num ? (entry['x'] as num).toDouble() : null;
                final y = entry['y'] is num ? (entry['y'] as num).toDouble() : null;
                final hasPos = x != null && y != null;
                uiChars.add(
                  char_model.CharacterPrompt(
                    id: const Uuid().v4(),
                    name: 'Character ${index + 1}',
                    prompt: prompt,
                    negativePrompt: uc,
                    positionMode: hasPos
                        ? char_model.CharacterPositionMode.custom
                        : char_model.CharacterPositionMode.aiChoice,
                    customPosition: hasPos
                        ? char_model.CharacterPosition(
                            mode: char_model.CharacterPositionMode.custom,
                            row: y,
                            column: x,
                          )
                        : null,
                  ),
                );
                paramChars.add(
                  CharacterPrompt(
                    prompt: prompt,
                    negativePrompt: uc,
                    position: entry['position'] is String
                        ? entry['position'] as String
                        : null,
                    positionX: x,
                    positionY: y,
                  ),
                );
                index++;
              }
              ref
                  .read(characterPromptNotifierProvider.notifier)
                  .replaceAll(uiChars);
              notifier.clearCharacters();
              for (final c in paramChars) {
                notifier.addCharacter(c);
              }
              applied.add('characters($index)');
            } else if (flag('clear_characters') == true) {
              ref
                  .read(characterPromptNotifierProvider.notifier)
                  .clearAllCharacters();
              notifier.clearCharacters();
              applied.add('clear_characters');
            }

            return applied;
          },
          send: server.send,
          isUiGenerating: () =>
              ref.read(imageGenerationNotifierProvider).isGenerating,
          generateStream: (request) {
            final apiService = ref.read(naiImageGenerationApiServiceProvider);
            return apiService.generateImageStream(
              request.params,
              focusedInpaintEnabled: request.focusedInpaintEnabled,
              minimumContextMegaPixels: request.minimumContextPixels,
              focusedSelectionRect: request.focusedSelectionRect,
            );
          },
          generateFallback: (request) async {
            final apiService = ref.read(naiImageGenerationApiServiceProvider);
            return apiService.generateImageArtifactsCancellable(
              request.params,
              onProgress: (_, __) {},
              focusedInpaintEnabled: request.focusedInpaintEnabled,
              minimumContextMegaPixels: request.minimumContextPixels,
              focusedSelectionRect: request.focusedSelectionRect,
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
