import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/image/image_operation.dart';
import '../../../data/models/upscale/local_upscale_models.dart';
import '../../../data/services/local_upscale_model_manager.dart';
import '../../../data/services/local_upscale_service.dart';
import '../image_generation_provider.dart';
import '../image_save_settings_provider.dart';
import 'image_workflow_controller.dart';
import 'preview_selection_provider.dart';

final localUpscaleModelManagerProvider = Provider((ref) {
  final manager = LocalUpscaleModelManager();
  ref.onDispose(manager.dispose);
  return manager;
});
final localUpscaleServiceProvider = Provider(
  (ref) => LocalUpscaleService(ref.watch(localUpscaleModelManagerProvider)),
);
final localUpscaleModelsProvider = FutureProvider(
  (ref) => ref.watch(localUpscaleModelManagerProvider).models(),
);

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
  bool _disposed = false;
  @override
  LocalUpscaleTaskState build() {
    _disposed = false;
    ref.listen(generationParamsNotifierProvider, (previous, next) {
      if (!_disposed &&
          !state.running &&
          !identical(previous?.sourceImage, next.sourceImage)) {
        state = const LocalUpscaleTaskState();
      }
    });
    ref.onDispose(() {
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

  Future<void> start() async {
    final workflow = ref.read(imageWorkflowControllerProvider);
    final generation = ref.read(imageGenerationNotifierProvider);
    if (state.running ||
        workflow.isToolRunning ||
        generation.status == GenerationStatus.generating) {
      return;
    }
    final params = ref.read(generationParamsNotifierProvider);
    final source = params.sourceImage;
    if (source == null || !workflow.isUpscale) return;
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
        !sourceChanged &&
        !cancellation.isCancelled &&
        controller.sourceRevision == revision &&
        identical(
          ref.read(generationParamsNotifierProvider).sourceImage,
          source,
        ) &&
        ref.read(imageWorkflowControllerProvider).isUpscale;
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
