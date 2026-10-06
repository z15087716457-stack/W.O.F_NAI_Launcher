import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/services/desktop_app_shutdown_service.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/utils/image_save_utils.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/image/image_operation.dart';
import 'package:nai_launcher/data/models/upscale/local_upscale_models.dart';
import 'package:nai_launcher/data/services/image_metadata_service.dart';
import 'package:nai_launcher/data/services/local_upscale_service.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/image_save_settings_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_feed_layout.dart';

class _Storage extends LocalStorageService {
  final values = <String, Object?>{};
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      (values[key] ?? defaultValue) as T?;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    values[key] = value;
  }
}

class _Params extends GenerationParamsNotifier {
  @override
  ImageParams build() => const ImageParams(
    prompt: 'unrelated draft',
    seed: 999,
    width: 832,
    height: 1216,
  );
}

class _Generation extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();
}

class _Save extends ImageSaveSettingsNotifier {
  @override
  ImageSaveSettings build() => const ImageSaveSettings(autoSave: false);
}

class _Service extends Mock implements LocalUpscaleService {}

Uint8List _png(int w, int h) =>
    Uint8List.fromList(img.encodePng(img.Image(width: w, height: h)));

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(LocalUpscaleCancellation());
    registerFallbackValue(const Seedvr2Options());
  });
  for (final scenario in [
    'success',
    'plain',
    'direct',
    'seedvr2',
    'new-source',
    'new-selection',
    'selection-back',
    'source-back',
    'cancel',
    'shutdown',
  ]) {
    test('local tool $scenario protects source provenance and draft', () async {
      final service = _Service();
      final pending = Completer<LocalUpscaleResult>();
      final storage = _Storage();
      Seedvr2Options? received;
      when(
        () => service.upscale(
          any(),
          modelId: any(named: 'modelId'),
          scale: any(named: 'scale'),
          seedvr2Options: any(named: 'seedvr2Options'),
          cancellation: any(named: 'cancellation'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((call) {
        received = call.namedArguments[#seedvr2Options] as Seedvr2Options;
        return pending.future;
      });
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWith((ref) => storage),
          generationParamsNotifierProvider.overrideWith(_Params.new),
          imageGenerationNotifierProvider.overrideWith(_Generation.new),
          imageSaveSettingsNotifierProvider.overrideWith(_Save.new),
          localUpscaleServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        imageWorkflowControllerProvider.notifier,
      );
      if (scenario == 'seedvr2') {
        controller.updateLocalUpscaleModel('seedvr2-7b');
        controller.updateLocalSeedvr2Options(
          const Seedvr2Options(
            seed: 321,
            colorCorrection: 'wavelet',
            blocksToSwap: 36,
          ),
        );
      }
      final raw = _png(48, 32);
      final source = scenario == 'plain'
          ? raw
          : await ImageSaveUtils.rebuildImageBytesWithMetadata(
              imageBytes: raw,
              params: const ImageParams(
                prompt: 'source prompt',
                negativePrompt: 'source negative',
                seed: 123,
                width: 48,
                height: 32,
              ),
              actualSeed: 123,
            );
      if (scenario != 'direct') {
        controller.openTemporaryTool(source, ImageWorkflowMode.upscale);
      }
      final task = container.read(localUpscaleTaskProvider.notifier);
      if (scenario == 'success') {
        container
            .read(generationPreviewSelectionProvider.notifier)
            .select('previous-canvas-image');
      }
      final done = task.start(
        image: scenario == 'direct'
            ? GeneratedImage.create(source, width: 48, height: 32)
            : null,
      );
      expect(container.read(localUpscaleTaskProvider).running, isTrue);
      if (scenario == 'new-source') {
        container
            .read(generationParamsNotifierProvider.notifier)
            .setSourceImage(_png(32, 48));
      }
      if (scenario == 'new-selection') {
        container
            .read(generationPreviewSelectionProvider.notifier)
            .select('manually-selected');
      }
      if (scenario == 'selection-back') {
        container
            .read(generationPreviewSelectionProvider.notifier)
            .select('manually-selected');
        container.read(generationPreviewSelectionProvider.notifier).clear();
      }
      if (scenario == 'source-back') {
        container
            .read(generationParamsNotifierProvider.notifier)
            .setSourceImage(_png(32, 48));
        container
            .read(generationParamsNotifierProvider.notifier)
            .setSourceImage(source);
      }
      if (scenario == 'cancel') task.cancel();
      Future<void>? shutdown;
      if (scenario == 'shutdown') {
        shutdown = DesktopAppShutdownService.prepareBackgroundShutdown();
        var finished = false;
        unawaited(shutdown.then((_) => finished = true));
        await Future<void>.delayed(Duration.zero);
        expect(
          finished,
          isFalse,
          reason: 'Shutdown must await child/task cleanup',
        );
      }
      pending.complete(LocalUpscaleResult(_png(72, 48), 72, 48));
      await done;
      await shutdown;
      final state = container.read(imageGenerationNotifierProvider);
      expect(
        container.read(imageWorkflowControllerProvider).isToolRunning,
        isFalse,
      );
      expect(
        container.read(generationParamsNotifierProvider).prompt,
        'unrelated draft',
      );
      expect(container.read(generationParamsNotifierProvider).seed, 999);
      if (scenario == 'seedvr2') {
        expect(
          (received!.seed, received!.colorCorrection, received!.blocksToSwap),
          (321, 'wavelet', 36),
        );
      }
      if (scenario == 'direct') {
        expect(
          container.read(generationParamsNotifierProvider).sourceImage,
          isNull,
        );
        expect(
          container.read(imageWorkflowControllerProvider).isUpscale,
          isFalse,
        );
      }
      if (scenario == 'new-source' ||
          scenario == 'source-back' ||
          scenario == 'cancel' ||
          scenario == 'shutdown') {
        expect(state.history, isEmpty);
      } else {
        expect(state.history, hasLength(1));
        final result = state.history.single;
        expect(result.operation, ImageOperation.upscale);
        expect(result.originalBytes, orderedEquals(source));
        final metadata = await ImageMetadataService().getMetadataFromBytes(
          result.bytes,
        );
        if (scenario == 'plain') {
          expect(metadata?.prompt ?? '', isEmpty);
          expect(metadata?.seed, isNot(999));
        } else {
          expect(metadata!.prompt, 'source prompt');
          expect(metadata.seed, 123);
        }
        if (scenario == 'new-selection' || scenario == 'selection-back') {
          expect(state.displayImages, isEmpty);
          expect(
            container.read(generationPreviewSelectionProvider),
            scenario == 'selection-back' ? null : 'manually-selected',
          );
        } else {
          expect(state.displayImages.single.id, result.id);
          expect(container.read(generationPreviewSelectionProvider), result.id);
          expect(
            container.read(canvasHistoryFocusRequestProvider)?.imageId,
            result.id,
          );
        }
      }
    });
  }

  test(
    'legacy ComfyUI choice becomes local without changing connection/model settings',
    () async {
      final storage = _Storage()
        ..values.addAll({
          StorageKeys.comfyuiUpscaleBackend: 'comfyui',
          StorageKeys.comfyuiUpscaleModel: 'my-legacy-model',
          StorageKeys.comfyuiUpscaleScale: 1.8,
        });
      var container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWith((ref) => storage),
          generationParamsNotifierProvider.overrideWith(_Params.new),
        ],
      );
      expect(
        container.read(imageWorkflowControllerProvider).upscale.backend,
        UpscaleBackend.local,
      );
      final controller = container.read(
        imageWorkflowControllerProvider.notifier,
      );
      controller.updateLocalUpscaleScale(3.25);
      controller.updateLocalUpscaleModel('general');
      controller.updateUpscaleBackend(UpscaleBackend.novelai);
      container.dispose();
      container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWith((ref) => storage),
          generationParamsNotifierProvider.overrideWith(_Params.new),
        ],
      );
      addTearDown(container.dispose);
      final settings = container.read(imageWorkflowControllerProvider).upscale;
      expect(settings.localScale, 3.25);
      expect(settings.localModel, 'general');
      expect(settings.backend, UpscaleBackend.novelai);
      expect(storage.values[StorageKeys.comfyuiUpscaleBackend], 'comfyui');
      expect(
        storage.values[StorageKeys.comfyuiUpscaleModel],
        'my-legacy-model',
      );
      expect(storage.values[StorageKeys.comfyuiUpscaleScale], 1.8);
    },
  );
}
