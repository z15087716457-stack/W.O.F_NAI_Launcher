import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/desktop_app_shutdown_service.dart';

import '../../../data/models/image/image_operation.dart';
import '../../../data/models/upscale/local_upscale_models.dart';
import '../../../data/services/local_upscale_model_manager.dart';
import '../../../data/services/advanced_upscale_component_manager.dart';
import '../../../data/services/local_upscale_service.dart';
import '../image_generation_provider.dart';
import '../image_save_settings_provider.dart';
import '../proxy_settings_provider.dart';
import 'image_workflow_controller.dart';
import 'preview_selection_provider.dart';
import '../../screens/generation/widgets/canvas/canvas_feed_layout.dart';

final localUpscaleModelManagerProvider = Provider((ref) {
  final manager = LocalUpscaleModelManager();
  ref.onDispose(manager.dispose);
  return manager;
});
final localUpscaleServiceProvider = Provider(
  (ref) => LocalUpscaleService(
    ref.watch(localUpscaleModelManagerProvider),
    advanced: ref.watch(advancedUpscaleComponentManagerProvider),
  ),
);
final advancedUpscaleComponentManagerProvider = Provider((ref) {
  final manager = AdvancedUpscaleComponentManager(
    proxyAddress: () => ref.read(currentProxyAddressProvider),
  );
  ref.onDispose(manager.dispose);
  return manager;
});
final localUpscaleModelsProvider = FutureProvider(
  (ref) async => [
    ...await ref.watch(localUpscaleModelManagerProvider).models(),
    ...await ref.watch(advancedUpscaleComponentManagerProvider).models(),
  ],
);

class AdvancedUpscaleInstallState {
  const AdvancedUpscaleInstallState({
    this.id,
    this.phase = '',
    this.fraction,
    this.error,
    this.cancelling = false,
  });
  final String? id;
  final String phase;
  final double? fraction;
  final LocalUpscaleError? error;
  final bool cancelling;
  bool get running => id != null;
}

final advancedUpscaleInstallProvider =
    NotifierProvider<AdvancedUpscaleInstall, AdvancedUpscaleInstallState>(
      AdvancedUpscaleInstall.new,
    );

class AdvancedUpscaleInstall extends Notifier<AdvancedUpscaleInstallState> {
  LocalUpscaleCancellation? _cancel;
  Future<void>? _pending;
  bool _disposed = false;
  @override
  AdvancedUpscaleInstallState build() {
    _disposed = false;
    final remove = DesktopAppShutdownService.registerCleanup(() async {
      _cancel?.cancel();
      await _pending;
    });
    ref.onDispose(() {
      _disposed = true;
      _cancel?.cancel();
      remove();
    });
    return const AdvancedUpscaleInstallState();
  }

  void cancel() {
    if (!state.running) return;
    state = AdvancedUpscaleInstallState(
      id: state.id,
      phase: state.phase,
      fraction: state.fraction,
      cancelling: true,
    );
    _cancel?.cancel();
  }

  Future<void> install(String id) => _operate(id, false);
  Future<void> delete(String id) => _operate(id, true);
  Future<void> _operate(String id, bool remove) {
    if (_pending != null) return _pending!;
    final work = _run(id, remove);
    _pending = work;
    return work.whenComplete(() => _pending = null);
  }

  Future<void> _run(String id, bool remove) async {
    final base = ref.read(localUpscaleModelManagerProvider);
    var locked = false;
    final cancellation = LocalUpscaleCancellation();
    _cancel = cancellation;
    state = AdvancedUpscaleInstallState(id: id, phase: 'component');
    try {
      base.claimInference(id);
      locked = true;
      final manager = ref.read(advancedUpscaleComponentManagerProvider);
      if (remove) {
        await manager.delete(id);
      } else {
        await manager.install(
          id,
          cancellation: cancellation,
          onProgress: (phase, fraction) {
            if (!_disposed && !cancellation.isCancelled) {
              state = AdvancedUpscaleInstallState(
                id: id,
                phase: phase,
                fraction: fraction,
              );
            }
          },
        );
      }
      if (!_disposed) state = const AdvancedUpscaleInstallState();
    } catch (error) {
      if (!_disposed) {
        state = AdvancedUpscaleInstallState(
          error: cancellation.isCancelled
              ? LocalUpscaleError.cancelled
              : error is LocalUpscaleException
              ? error.code
              : LocalUpscaleError.modelOperationFailed,
        );
      }
    } finally {
      if (locked) base.releaseInference();
      _cancel = null;
      if (!_disposed) ref.invalidate(localUpscaleModelsProvider);
    }
  }
}

class LocalUpscaleTaskState {
  const LocalUpscaleTaskState({
    this.running = false,
    this.cancelling = false,
    this.progress,
    this.error,
    this.completed = false,
  });
  final bool running;
  final bool cancelling;
  final bool completed;
  final LocalUpscaleProgress? progress;
  final LocalUpscaleError? error;
}

final localUpscaleTaskProvider =
    NotifierProvider<LocalUpscaleTask, LocalUpscaleTaskState>(
      LocalUpscaleTask.new,
    );

class LocalUpscaleTask extends Notifier<LocalUpscaleTaskState> {
  LocalUpscaleCancellation? _cancellation;
  Future<void>? _pending;
  bool _disposed = false;
  @override
  LocalUpscaleTaskState build() {
    _disposed = false;
    final removeCleanup = DesktopAppShutdownService.registerCleanup(() async {
      _cancellation?.cancel();
      await _pending;
    });
    ref.listen(generationParamsNotifierProvider, (previous, next) {
      if (!_disposed &&
          !state.running &&
          !identical(previous?.sourceImage, next.sourceImage)) {
        state = const LocalUpscaleTaskState();
      }
    });
    ref.onDispose(() {
      removeCleanup();
      _disposed = true;
      _cancellation?.cancel();
    });
    return const LocalUpscaleTaskState();
  }

  void cancel() {
    if (!state.running || state.cancelling) return;
    state = LocalUpscaleTaskState(
      running: true,
      cancelling: true,
      progress: state.progress,
    );
    _cancellation?.cancel();
  }

  Future<void> start({GeneratedImage? image}) {
    if (_pending != null) return _pending!;
    final work = _start(image);
    _pending = work;
    return work.whenComplete(() => _pending = null);
  }

  /// Shared native inference for automatic enhancement. The generation run
  /// owns registration; this task owns progress, cancellation and shutdown.
  Future<LocalUpscaleResult?> processGenerated(
    Uint8List source, {
    required String modelId,
    required double scale,
  }) async {
    if (_pending != null || state.running) return null;
    final work = _processGenerated(source, modelId: modelId, scale: scale);
    _pending = work.then<void>((_) {});
    try {
      return await work;
    } finally {
      _pending = null;
    }
  }

  Future<LocalUpscaleResult?> _processGenerated(
    Uint8List source, {
    required String modelId,
    required double scale,
  }) async {
    final cancellation = LocalUpscaleCancellation();
    _cancellation = cancellation;
    state = const LocalUpscaleTaskState(running: true);
    try {
      final result = await ref
          .read(localUpscaleServiceProvider)
          .upscale(
            Uint8List.fromList(source),
            modelId: modelId,
            scale: scale,
            cancellation: cancellation,
            onProgress: (progress) {
              if (!_disposed && !cancellation.isCancelled) {
                state = LocalUpscaleTaskState(
                  running: true,
                  progress: progress,
                );
              }
            },
          );
      if (_disposed || cancellation.isCancelled) return null;
      state = const LocalUpscaleTaskState(
        completed: true,
        progress: LocalUpscaleProgress(LocalUpscalePhase.complete, 1),
      );
      return result;
    } catch (error) {
      if (!_disposed) {
        state = LocalUpscaleTaskState(
          error: cancellation.isCancelled
              ? LocalUpscaleError.cancelled
              : error is LocalUpscaleException
              ? error.code
              : LocalUpscaleError.processFailed,
        );
      }
      return null;
    } finally {
      if (!_disposed && state.running) {
        state = LocalUpscaleTaskState(
          error: cancellation.isCancelled ? LocalUpscaleError.cancelled : null,
        );
      }
      _cancellation = null;
    }
  }

  Future<void> _start(GeneratedImage? image) async {
    final workflow = ref.read(imageWorkflowControllerProvider);
    final generation = ref.read(imageGenerationNotifierProvider);
    if ((image != null && !image.canUseAsGenerationInput) ||
        state.running ||
        workflow.isToolRunning ||
        generation.status == GenerationStatus.generating) {
      return;
    }
    final params = ref.read(generationParamsNotifierProvider);
    final source = image?.bytes ?? params.sourceImage;
    if (source == null || (image == null && !workflow.isUpscale)) return;
    final frozen = Uint8List.fromList(source);
    final controller = ref.read(imageWorkflowControllerProvider.notifier);
    final revision = controller.sourceRevision;
    final selection = ref.read(generationPreviewSelectionProvider);
    final focus = ref.read(generationCanvasGroupSelectionProvider);
    final display = generation.displayImages;
    final current = generation.currentImages;
    var sourceChanged = false;
    var selectionChanged = false;
    final sourceSubscription = ref.listen(generationParamsNotifierProvider, (
      previous,
      next,
    ) {
      if (!identical(previous?.sourceImage, next.sourceImage)) {
        sourceChanged = true;
      }
    });
    final selectionSubscription = ref.listen(
      generationPreviewSelectionProvider,
      (previous, next) {
        if (previous != next) {
          selectionChanged = true;
        }
      },
    );
    final focusSubscription = ref.listen(
      generationCanvasGroupSelectionProvider,
      (previous, next) {
        if (previous != next) {
          selectionChanged = true;
        }
      },
    );
    final cancellation = LocalUpscaleCancellation();
    _cancellation = cancellation;
    state = const LocalUpscaleTaskState(running: true);
    controller.setToolRunning(true);
    bool canApply() =>
        !_disposed &&
        !cancellation.isCancelled &&
        (image != null ||
            (!sourceChanged &&
                controller.sourceRevision == revision &&
                identical(
                  ref.read(generationParamsNotifierProvider).sourceImage,
                  source,
                ) &&
                ref.read(imageWorkflowControllerProvider).isUpscale)) &&
        !ref.read(imageGenerationNotifierProvider).isGenerating;
    bool canReplace() =>
        canApply() &&
        !selectionChanged &&
        ref.read(generationPreviewSelectionProvider) == selection &&
        ref.read(generationCanvasGroupSelectionProvider) == focus &&
        identical(
          ref.read(imageGenerationNotifierProvider).displayImages,
          display,
        ) &&
        identical(
          ref.read(imageGenerationNotifierProvider).currentImages,
          current,
        ) &&
        ref.read(imageGenerationNotifierProvider).status !=
            GenerationStatus.generating;
    try {
      final result = await ref
          .read(localUpscaleServiceProvider)
          .upscale(
            frozen,
            modelId: workflow.upscale.localModel,
            scale: workflow.upscale.localScale,
            cancellation: cancellation,
            onProgress: (progress) {
              if (!_disposed && !cancellation.isCancelled) {
                state = LocalUpscaleTaskState(
                  running: true,
                  progress: progress,
                );
              }
            },
          );
      if (!canApply()) return;
      final save = ref.read(imageSaveSettingsNotifierProvider);
      await ref
          .read(imageGenerationNotifierProvider.notifier)
          .registerExternalImage(
            result.bytes,
            params: params.copyWith(
              prompt: '',
              negativePrompt: '',
              seed: -1,
              characters: [],
            ),
            width: result.width,
            height: result.height,
            operation: ImageOperation.upscale,
            originalBytes: frozen,
            saveToLocal: save.autoSave,
            replaceCurrentDisplay: true,
            canApply: canApply,
            canReplaceDisplay: canReplace,
            onRegistered: (image, displayed) {
              if (!displayed || _disposed) return;
              ref
                  .read(generationPreviewSelectionProvider.notifier)
                  .select(image.id);
              final request = ref.read(
                canvasHistoryFocusRequestProvider.notifier,
              );
              request.state = (
                group: 'img:${image.id}',
                imageId: image.id,
                revision: (request.state?.revision ?? 0) + 1,
              );
            },
          );
      if (canApply()) {
        state = const LocalUpscaleTaskState(
          completed: true,
          progress: LocalUpscaleProgress(LocalUpscalePhase.complete, 1),
        );
      }
    } on LocalUpscaleException catch (error) {
      if (!_disposed) state = LocalUpscaleTaskState(error: error.code);
    } catch (_) {
      if (!_disposed) {
        state = const LocalUpscaleTaskState(
          error: LocalUpscaleError.processFailed,
        );
      }
    } finally {
      sourceSubscription.close();
      selectionSubscription.close();
      focusSubscription.close();
      if (!_disposed) {
        controller.setToolRunning(false);
        if (state.running) {
          state = LocalUpscaleTaskState(
            error: cancellation.isCancelled
                ? LocalUpscaleError.cancelled
                : null,
          );
        }
      }
      _cancellation = null;
    }
  }
}
