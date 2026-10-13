import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/desktop_app_shutdown_service.dart';
import '../../../data/datasources/remote/nai_image_enhancement_api_service.dart';
import '../../../data/models/image/image_operation.dart';
import '../image_generation_provider.dart';
import '../auth_provider.dart';
import '../image_save_settings_provider.dart';
import '../subscription_provider.dart';
import '../../screens/generation/widgets/canvas/canvas_feed_layout.dart';
import 'image_workflow_controller.dart';
import 'local_upscale_provider.dart';
import 'preview_selection_provider.dart';

class CloudUpscaleState {
  const CloudUpscaleState({
    this.running = false,
    this.error,
    this.completed = false,
  });
  final bool running;
  final String? error;
  final bool completed;
}

final cloudUpscaleTaskProvider =
    NotifierProvider<CloudUpscaleTask, CloudUpscaleState>(CloudUpscaleTask.new);

/// The selected canvas image is read directly; opening settings never takes
/// over the img2img draft. All callers share the same in-flight gate.
class CloudUpscaleTask extends Notifier<CloudUpscaleState> {
  CancelToken? _cancellation;
  Future<void>? _pending;
  bool _disposed = false;

  @override
  CloudUpscaleState build() {
    _disposed = false;
    final remove = DesktopAppShutdownService.registerCleanup(() async {
      cancel();
      await _pending;
    });
    ref.onDispose(() {
      _disposed = true;
      _cancellation?.cancel();
      remove();
    });
    return const CloudUpscaleState();
  }

  void cancel() => _cancellation?.cancel();

  /// Frozen-image execution for callers that own result export/display.
  Future<Uint8List?> processGenerated(
    Uint8List source, {
    required CancelToken cancellation,
    void Function()? onStarted,
  }) async {
    if (_pending != null ||
        state.running ||
        cancellation.isCancelled ||
        ref.read(imageWorkflowControllerProvider).isToolRunning ||
        ref.read(imageGenerationNotifierProvider).isGenerating ||
        ref.read(localUpscaleTaskProvider).running) {
      return null;
    }
    final work = _processGenerated(Uint8List.fromList(source), cancellation);
    _pending = work.then<void>((_) {});
    onStarted?.call();
    try {
      return await work;
    } finally {
      _pending = null;
    }
  }

  Future<Uint8List?> _processGenerated(
    Uint8List source,
    CancelToken token,
  ) async {
    _cancellation = token;
    state = const CloudUpscaleState(running: true);
    final workflow = ref.read(imageWorkflowControllerProvider.notifier);
    workflow.setToolRunning(true);
    try {
      final result = await ref
          .read(naiImageEnhancementApiServiceProvider)
          .upscaleImage(source, cancelToken: token);
      if (_disposed || token.isCancelled) return null;
      state = const CloudUpscaleState(completed: true);
      return result;
    } catch (error) {
      if (!_disposed) {
        state = CloudUpscaleState(error: token.isCancelled ? null : '$error');
      }
      return null;
    } finally {
      _cancellation = null;
      if (!_disposed) {
        workflow.setToolRunning(false);
        if (state.running) state = const CloudUpscaleState();
        if (ref.exists(subscriptionNotifierProvider)) {
          ref
              .read(subscriptionNotifierProvider.notifier)
              .schedulePostBillingRefresh();
        }
      }
    }
  }

  Future<void> start({GeneratedImage? image}) {
    if (_pending != null) return _pending!;
    final work = _start(image);
    _pending = work;
    return work.whenComplete(() => _pending = null);
  }

  Future<void> _start(GeneratedImage? image) async {
    final workflow = ref.read(imageWorkflowControllerProvider);
    final generation = ref.read(imageGenerationNotifierProvider);
    if (workflow.isToolRunning ||
        generation.isGenerating ||
        ref.read(localUpscaleTaskProvider).running ||
        (image != null && !image.canUseAsGenerationInput)) {
      return;
    }
    final params = ref.read(generationParamsNotifierProvider);
    final source = image?.bytes ?? params.sourceImage;
    if (source == null) return;
    final frozen = Uint8List.fromList(source);
    final controller = ref.read(imageWorkflowControllerProvider.notifier);
    final selection = ref.read(generationPreviewSelectionProvider);
    final focus = ref.read(generationCanvasGroupSelectionProvider);
    final display = generation.displayImages;
    final current = generation.currentImages;
    var selectionChanged = false;
    final selectionSub = ref.listen(generationPreviewSelectionProvider, (a, b) {
      if (a != b) selectionChanged = true;
    });
    final focusSub = ref.listen(generationCanvasGroupSelectionProvider, (a, b) {
      if (a != b) selectionChanged = true;
    });
    final token = CancelToken();
    var accountChanged = false;
    final accountSubscription = ref.exists(authNotifierProvider)
        ? ref.listen(
            authNotifierProvider.select(
              (value) => (value.accountId, value.status),
            ),
            (previous, next) {
              if (previous != next) {
                accountChanged = true;
                token.cancel();
              }
            },
          )
        : null;
    _cancellation = token;
    state = const CloudUpscaleState(running: true);
    controller.setToolRunning(true);
    bool canApply() =>
        !_disposed &&
        !accountChanged &&
        !token.isCancelled &&
        !ref.read(imageGenerationNotifierProvider).isGenerating &&
        (image != null ||
            identical(
              ref.read(generationParamsNotifierProvider).sourceImage,
              source,
            ));
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
        );
    try {
      final result = await ref
          .read(naiImageEnhancementApiServiceProvider)
          .upscaleImage(frozen, cancelToken: token);
      if (!canApply()) return;
      await ref
          .read(imageGenerationNotifierProvider.notifier)
          .registerExternalImage(
            result,
            params: params.copyWith(
              prompt: '',
              negativePrompt: '',
              seed: -1,
              characters: [],
            ),
            operation: ImageOperation.upscale,
            originalBytes: frozen,
            saveToLocal: ref.read(imageSaveSettingsNotifierProvider).autoSave,
            replaceCurrentDisplay: true,
            canApply: canApply,
            canReplaceDisplay: canReplace,
            onRegistered: (result, displayed) {
              if (!displayed || _disposed) return;
              ref
                  .read(generationPreviewSelectionProvider.notifier)
                  .select(result.id);
              final request = ref.read(
                canvasHistoryFocusRequestProvider.notifier,
              );
              request.state = (
                group: 'img:${result.id}',
                imageId: result.id,
                revision: (request.state?.revision ?? 0) + 1,
              );
            },
          );
      if (!_disposed) state = const CloudUpscaleState(completed: true);
    } catch (error) {
      if (!_disposed) {
        state = CloudUpscaleState(error: token.isCancelled ? null : '$error');
      }
    } finally {
      accountSubscription?.close();
      selectionSub.close();
      focusSub.close();
      _cancellation = null;
      if (!_disposed &&
          !accountChanged &&
          ref.exists(subscriptionNotifierProvider)) {
        ref
            .read(subscriptionNotifierProvider.notifier)
            .schedulePostBillingRefresh();
      }
      if (!_disposed) {
        controller.setToolRunning(false);
        if (state.running) state = const CloudUpscaleState();
      }
    }
  }
}
