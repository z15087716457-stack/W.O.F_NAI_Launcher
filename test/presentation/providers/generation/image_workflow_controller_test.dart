import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/upscale/local_upscale_models.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';

void main() {
  late Directory hiveTempDir;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    hiveTempDir = await Directory.systemTemp.createTemp(
      'nai_launcher_workflow_hive_',
    );
    Hive.init(hiveTempDir.path);
    await Hive.openBox(StorageKeys.settingsBox);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveTempDir.exists()) {
      await hiveTempDir.delete(recursive: true);
    }
  });

  group('ImageWorkflowController', () {
    late ProviderContainer container;

    setUp(() async {
      await Hive.box(StorageKeys.settingsBox).clear();
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'local SeedVR2 options persist per variant and do not reuse ComfyUI settings',
      () async {
        await Hive.box(
          StorageKeys.settingsBox,
        ).put(StorageKeys.comfyuiSeedvr2BlocksToSwap, 28);
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );
        controller.updateLocalUpscaleModel('seedvr2-3b');
        expect(
          container
              .read(imageWorkflowControllerProvider)
              .upscale
              .selectedSeedvr2Options
              .blocksToSwap,
          0,
        );
        controller.updateLocalSeedvr2Options(
          const Seedvr2Options(
            seed: 42,
            blocksToSwap: 36,
            colorCorrection: 'wavelet',
            vaeTileSize: 256,
            vaeTileOverlap: 500,
          ),
        );
        controller.updateLocalUpscaleModel('seedvr2-7b');
        expect(
          container
              .read(imageWorkflowControllerProvider)
              .upscale
              .selectedSeedvr2Options
              .seed,
          0,
        );
        controller.updateLocalSeedvr2Options(
          const Seedvr2Options(seed: 77, blocksToSwap: 36),
        );
        controller.updateLocalUpscaleModel('rtx-vsr');
        await Future<void>.delayed(Duration.zero);
        container.dispose();
        container = ProviderContainer();
        final restored = container.read(
          imageWorkflowControllerProvider.notifier,
        );
        expect(
          container
              .read(imageWorkflowControllerProvider)
              .upscale
              .localSeedvr2Model,
          'seedvr2-7b',
        );
        restored.updateLocalUpscaleModel('seedvr2-3b');
        final three = container
            .read(imageWorkflowControllerProvider)
            .upscale
            .selectedSeedvr2Options;
        expect(
          (three.seed, three.blocksToSwap, three.vaeTileOverlap),
          (42, 32, 192),
        );
        expect(three.colorCorrection, 'wavelet');
        restored.updateLocalSeedvr2Options(const Seedvr2Options());
        restored.updateLocalUpscaleModel('seedvr2-7b');
        final seven = container
            .read(imageWorkflowControllerProvider)
            .upscale
            .selectedSeedvr2Options;
        expect((seven.seed, seven.blocksToSwap), (77, 36));
        expect(
          container
              .read(imageWorkflowControllerProvider)
              .upscale
              .seedvr2BlocksToSwap,
          28,
        );
      },
    );

    test(
      'enterEnhanceMode should project source dimensions into generation params',
      () {
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );
        final paramsNotifier = container.read(
          generationParamsNotifierProvider.notifier,
        );

        paramsNotifier.updateSize(832, 1216, persist: false);
        paramsNotifier.updateStrength(0.7);
        paramsNotifier.updateNoise(0.0);
        paramsNotifier.setSourceImage(Uint8List.fromList([1, 2, 3]));

        controller.setSourceImageDimensions(768, 1024);
        controller.enterEnhanceMode();
        controller.updateEnhanceUpscaleFactor(1.5);
        controller.updateEnhanceIndividualSettings(strength: 0.42, noise: 0.16);

        final workflow = container.read(imageWorkflowControllerProvider);
        final params = container.read(generationParamsNotifierProvider);

        expect(workflow.mode, ImageWorkflowMode.enhance);
        expect(params.action, ImageGenerationAction.img2img);
        expect(params.width, equals(1152));
        expect(params.height, equals(1536));
        expect(params.strength, equals(0.42));
        expect(params.noise, equals(0.16));
      },
    );

    test(
      'enhance uses the five website presets and preserves fractional source scaling',
      () {
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );
        final params = container.read(
          generationParamsNotifierProvider.notifier,
        );
        params.setSourceImage(Uint8List.fromList([1]));
        controller.setSourceImageDimensions(832, 1216);
        controller.enterEnhanceMode();
        controller.updateEnhanceUpscaleFactor(1.5);
        expect(container.read(generationParamsNotifierProvider).width, 1248);
        expect(container.read(generationParamsNotifierProvider).height, 1824);
        const expected = [
          (0.2, 0.0),
          (0.4, 0.0),
          (0.5, 0.0),
          (0.6, 0.0),
          (0.7, 0.1),
        ];
        for (var i = 0; i < expected.length; i++) {
          controller.updateEnhanceMagnitude(i / 4);
          final p = container.read(generationParamsNotifierProvider);
          expect((p.strength, p.noise), expected[i]);
        }
      },
    );

    test(
      'closing temporary tools restores image state but keeps a newly typed prompt',
      () async {
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );
        final params = container.read(
          generationParamsNotifierProvider.notifier,
        );
        final original = Uint8List.fromList(
          img.encodePng(img.Image(width: 64, height: 64)),
        );
        final toolSource = Uint8List.fromList(
          img.encodePng(img.Image(width: 128, height: 64)),
        );
        final mask = Uint8List.fromList([9, 8, 7]);
        controller.replaceSourceImage(original, autoAdapt: false);
        controller.enterInpaintMode();
        controller.onMaskChanged(mask);
        final before = container.read(generationParamsNotifierProvider);
        controller.openTemporaryTool(toolSource, ImageWorkflowMode.enhance);
        controller.updateEnhanceMagnitude(1);
        expect(container.read(generationParamsNotifierProvider), same(before));
        expect(container.read(draftImageWorkflowProvider).isInpaint, isTrue);
        final request = container.read(generationRequestParamsProvider);
        expect(request.sourceImage, same(toolSource));
        expect(request.maskImage, isNull);
        expect(request.action, ImageGenerationAction.img2img);
        expect(request.enhanceWorkflow, isTrue);
        expect((request.strength, request.noise), (0.7, 0.1));
        expect((request.width, request.height), (128, 64));
        params.updatePrompt('new user draft');
        params.updateSize(896, 1280, persist: false);
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(generationRequestParamsProvider).prompt,
          'new user draft',
        );
        controller.closeTemporaryTool();
        final after = container.read(generationParamsNotifierProvider);
        expect(after.sourceImage, same(original));
        expect(after.maskImage, same(mask));
        expect(after.action, before.action);
        expect(
          (after.width, after.height, after.strength, after.noise),
          (896, 1280, before.strength, before.noise),
        );
        expect(after.prompt, 'new user draft');
        expect(
          container.read(imageWorkflowControllerProvider).mode,
          ImageWorkflowMode.inpaint,
        );
      },
    );

    test('canvas enhance leaves an empty img2img draft empty throughout', () {
      final controller = container.read(
        imageWorkflowControllerProvider.notifier,
      );
      final before = container.read(generationParamsNotifierProvider);
      final source = Uint8List.fromList(
        img.encodePng(img.Image(width: 832, height: 1216)),
      );
      controller.openTemporaryTool(source, ImageWorkflowMode.enhance);
      controller.updateEnhanceUpscaleFactor(1.5);
      controller.updateEnhanceIndividualSettings(strength: .42, noise: .16);
      expect(container.read(generationParamsNotifierProvider), same(before));
      expect(
        container.read(draftImageWorkflowProvider).isPanelExpanded,
        isFalse,
      );
      final request = container.read(generationRequestParamsProvider);
      expect((request.width, request.height), (1248, 1824));
      expect((request.strength, request.noise), (.42, .16));
      expect(request.sourceImage, same(source));
      controller.closeTemporaryTool();
      expect(container.read(generationParamsNotifierProvider), same(before));
      expect(container.read(generationRequestParamsProvider), same(before));
    });

    test('closing a tool does not replace a newer input image', () {
      final controller = container.read(
        imageWorkflowControllerProvider.notifier,
      );
      final a = Uint8List.fromList(
        img.encodePng(img.Image(width: 64, height: 64)),
      );
      final b = Uint8List.fromList(
        img.encodePng(img.Image(width: 128, height: 64)),
      );
      controller.openTemporaryTool(a, ImageWorkflowMode.enhance);
      controller.replaceSourceImage(b, autoAdapt: false);
      controller.closeTemporaryTool();
      expect(
        container.read(generationParamsNotifierProvider).sourceImage,
        same(b),
      );
    });

    test('exitEnhanceMode should restore original img2img params', () {
      final controller = container.read(
        imageWorkflowControllerProvider.notifier,
      );
      final paramsNotifier = container.read(
        generationParamsNotifierProvider.notifier,
      );

      paramsNotifier.updateSize(832, 1216, persist: false);
      paramsNotifier.updateStrength(0.63);
      paramsNotifier.updateNoise(0.04);
      paramsNotifier.setSourceImage(Uint8List.fromList([1, 2, 3]));

      controller.setSourceImageDimensions(768, 1024);
      controller.enterEnhanceMode();
      controller.updateEnhanceUpscaleFactor(1.5);
      controller.exitEnhanceMode();

      final workflow = container.read(imageWorkflowControllerProvider);
      final params = container.read(generationParamsNotifierProvider);

      expect(workflow.mode, ImageWorkflowMode.base);
      expect(params.width, equals(832));
      expect(params.height, equals(1216));
      expect(params.strength, equals(0.63));
      expect(params.noise, equals(0.04));
    });

    test(
      'replaceSourceImageInInpaintMode should restore base workflow before generating with the new source',
      () {
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );
        final paramsNotifier = container.read(
          generationParamsNotifierProvider.notifier,
        );

        paramsNotifier.updateModel(
          ImageModels.animeDiffusionV45Full,
          persist: false,
        );
        paramsNotifier.setSourceImage(Uint8List.fromList([1, 2, 3]));
        paramsNotifier.setMaskImage(Uint8List.fromList([9, 9, 9]));
        controller.enterInpaintMode();

        controller.replaceSourceImage(
          _validImageBytes(width: 512, height: 768),
          sourceWidth: 512,
          sourceHeight: 768,
        );

        final workflow = container.read(imageWorkflowControllerProvider);
        final params = container.read(generationParamsNotifierProvider);

        expect(workflow.mode, ImageWorkflowMode.base);
        expect(params.maskImage, isNull);
        expect(params.action, ImageGenerationAction.img2img);
        expect(params.model, ImageModels.animeDiffusionV45Full);
        expect(params.width, equals(512));
        expect(params.height, equals(768));
      },
    );

    test(
      'replaceSourceImage should keep import bytes while applying the official web bucket',
      () {
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );
        final paramsNotifier = container.read(
          generationParamsNotifierProvider.notifier,
        );

        paramsNotifier.updateModel(
          ImageModels.animeDiffusionV45Curated,
          persist: false,
        );
        paramsNotifier.updateSize(832, 1216, persist: false);

        final original = _validImageBytes(width: 1500, height: 900);

        controller.replaceSourceImage(original);

        final workflow = container.read(imageWorkflowControllerProvider);
        final params = container.read(generationParamsNotifierProvider);
        final source = img.decodeImage(params.sourceImage!);

        expect(workflow.sourceWidth, equals(1472));
        expect(workflow.sourceHeight, equals(896));
        expect(workflow.sourceImageWidth, equals(1500));
        expect(workflow.sourceImageHeight, equals(900));
        expect(params.width, equals(1472));
        expect(params.height, equals(896));
        expect(params.sourceImage, same(original));
        expect(source!.width, equals(1500));
        expect(source.height, equals(900));
        expect(params.action, ImageGenerationAction.img2img);
      },
    );

    test(
      'replaceSourceImageAsync should keep import bytes while applying the official web bucket',
      () async {
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );
        final paramsNotifier = container.read(
          generationParamsNotifierProvider.notifier,
        );

        paramsNotifier.updateModel(
          ImageModels.animeDiffusionV45Curated,
          persist: false,
        );
        paramsNotifier.updateSize(832, 1216, persist: false);

        final original = _validImageBytes(width: 1500, height: 900);

        await controller.replaceSourceImageAsync(original);

        final workflow = container.read(imageWorkflowControllerProvider);
        final params = container.read(generationParamsNotifierProvider);
        final source = img.decodeImage(params.sourceImage!);

        expect(workflow.sourceWidth, equals(1472));
        expect(workflow.sourceHeight, equals(896));
        expect(workflow.sourceImageWidth, equals(1500));
        expect(workflow.sourceImageHeight, equals(900));
        expect(params.width, equals(1472));
        expect(params.height, equals(896));
        expect(params.sourceImage, same(original));
        expect(source!.width, equals(1500));
        expect(source.height, equals(900));
        expect(params.action, ImageGenerationAction.img2img);
      },
    );

    test('updateEnhanceUpscaleFactor should reject unavailable values', () {
      final controller = container.read(
        imageWorkflowControllerProvider.notifier,
      );
      final paramsNotifier = container.read(
        generationParamsNotifierProvider.notifier,
      );

      paramsNotifier.setSourceImage(Uint8List.fromList([1, 2, 3]));
      controller.setSourceImageDimensions(768, 1024);
      controller.enterEnhanceMode();

      controller.updateEnhanceUpscaleFactor(1.5);
      controller.updateEnhanceUpscaleFactor(4.0);

      final workflow = container.read(imageWorkflowControllerProvider);

      expect(workflow.enhance.upscaleFactor, equals(1.5));
    });

    test('enterBaseMode from enhance should restore base workflow', () {
      final controller = container.read(
        imageWorkflowControllerProvider.notifier,
      );
      final paramsNotifier = container.read(
        generationParamsNotifierProvider.notifier,
      );

      paramsNotifier.setSourceImage(Uint8List.fromList([1, 2, 3]));
      controller.enterEnhanceMode();

      controller.enterBaseMode();

      final workflow = container.read(imageWorkflowControllerProvider);

      expect(workflow.mode, ImageWorkflowMode.base);
      expect(workflow.isPanelExpanded, isTrue);
    });

    test(
      'enterInpaintMode should sync request size to source image dimensions',
      () {
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );
        final paramsNotifier = container.read(
          generationParamsNotifierProvider.notifier,
        );

        paramsNotifier.updateSize(832, 1216, persist: false);

        controller.replaceSourceImage(
          _validImageBytes(width: 768, height: 1024),
        );
        controller.enterInpaintMode();
        controller.onMaskChanged(Uint8List.fromList([9, 9, 9]));

        final params = container.read(generationParamsNotifierProvider);

        expect(params.width, equals(768));
        expect(params.height, equals(1024));
        expect(params.action, ImageGenerationAction.infill);
      },
    );

    test(
      'applyInpaintEditorResult should commit inpaint state in one coherent transition',
      () {
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );
        final paramsNotifier = container.read(
          generationParamsNotifierProvider.notifier,
        );

        paramsNotifier.updateModel(
          ImageModels.animeDiffusionV45Full,
          persist: false,
        );
        paramsNotifier.updateSize(832, 1216, persist: false);
        controller.replaceSourceImage(
          _validImageBytes(width: 1536, height: 2304),
        );
        controller.enterEnhanceMode();

        controller.applyInpaintEditorResult(
          maskImage: Uint8List.fromList([9, 9, 9]),
        );

        final workflow = container.read(imageWorkflowControllerProvider);
        final params = container.read(generationParamsNotifierProvider);

        expect(workflow.mode, ImageWorkflowMode.inpaint);
        expect(workflow.isPanelExpanded, isTrue);
        expect(params.width, equals(896));
        expect(params.height, equals(1344));
        expect(params.maskImage, isNotNull);
        expect(params.isOutpaint, isFalse);
        expect(params.action, ImageGenerationAction.infill);
        expect(params.model, equals(ImageModels.animeDiffusionV45Full));
      },
    );

    test(
      'applyInpaintEditorResult can atomically replace source and mask for outpaint',
      () {
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );

        controller.replaceSourceImage(
          _validImageBytes(width: 1024, height: 1216),
        );

        final expandedSource = _validImageBytes(width: 1472, height: 1664);
        final expandedMask = _validMaskBytes(width: 1472, height: 1664);

        controller.applyInpaintEditorResult(
          sourceImage: expandedSource,
          sourceWidth: 1472,
          sourceHeight: 1664,
          maskImage: expandedMask,
        );

        final workflow = container.read(imageWorkflowControllerProvider);
        final params = container.read(generationParamsNotifierProvider);

        expect(workflow.mode, ImageWorkflowMode.inpaint);
        expect(workflow.sourceWidth, equals(1472));
        expect(workflow.sourceHeight, equals(1664));
        expect(workflow.sourceImageWidth, equals(1472));
        expect(workflow.sourceImageHeight, equals(1664));
        expect(workflow.isOutpaint, isTrue);
        expect(params.sourceImage, same(expandedSource));
        expect(params.maskImage, same(expandedMask));
        expect(params.width, equals(1472));
        expect(params.height, equals(1664));
        expect(params.isOutpaint, isTrue);
        expect(params.action, ImageGenerationAction.infill);
      },
    );

    test(
      'applyInpaintEditorResult stores working source dimensions separately from request dimensions',
      () {
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );
        final workingSource = _validImageBytes(width: 1500, height: 900);
        final workingMask = _validMaskBytes(width: 1500, height: 900);

        controller.applyInpaintEditorResult(
          sourceImage: workingSource,
          sourceWidth: 1500,
          sourceHeight: 900,
          sourceIsOutpaint: false,
          maskImage: workingMask,
        );

        final workflow = container.read(imageWorkflowControllerProvider);
        final params = container.read(generationParamsNotifierProvider);

        expect((workflow.sourceWidth, workflow.sourceHeight), (1472, 896));
        expect(
          (workflow.sourceImageWidth, workflow.sourceImageHeight),
          (1500, 900),
        );
        expect(params.sourceImage, same(workingSource));
        expect((params.width, params.height), (1472, 896));
        expect(params.isOutpaint, isFalse);
      },
    );

    test(
      'applyInpaintEditorResult preserves an explicit editor compression target',
      () {
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );
        final source = _validImageBytes(width: 1344, height: 640);
        final mask = _validMaskBytes(width: 1344, height: 640);

        controller.applyInpaintEditorResult(
          sourceImage: source,
          sourceWidth: 1344,
          sourceHeight: 640,
          sourceIsOutpaint: false,
          useExactSourceDimensions: true,
          maskImage: mask,
        );

        final workflow = container.read(imageWorkflowControllerProvider);
        final params = container.read(generationParamsNotifierProvider);
        expect((workflow.sourceWidth, workflow.sourceHeight), (1344, 640));
        expect(
          (workflow.sourceImageWidth, workflow.sourceImageHeight),
          (1344, 640),
        );
        expect((params.width, params.height), (1344, 640));
        expect(params.sourceImage, same(source));
        expect(params.maskImage, same(mask));
      },
    );

    test(
      'applyInpaintEditorResult requires dimensions with outpaint source',
      () {
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );

        expect(
          () => controller.applyInpaintEditorResult(
            sourceImage: _validImageBytes(width: 1472, height: 1664),
            sourceWidth: 1472,
            maskImage: _validMaskBytes(width: 1472, height: 1664),
          ),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              'Outpaint source dimensions are required',
            ),
          ),
        );
      },
    );

    test(
      'applyInpaintEditorResult rejects non 64-compatible outpaint source dimensions',
      () {
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );

        expect(
          () => controller.applyInpaintEditorResult(
            sourceImage: _validImageBytes(width: 1473, height: 1664),
            sourceWidth: 1473,
            sourceHeight: 1664,
            maskImage: _validMaskBytes(width: 1472, height: 1664),
          ),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              'Outpaint source dimensions must be 64-compatible',
            ),
          ),
        );
      },
    );

    test(
      'enterInpaintMode should keep the settings model stable across inpaint',
      () {
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );
        final paramsNotifier = container.read(
          generationParamsNotifierProvider.notifier,
        );

        paramsNotifier.updateModel(
          ImageModels.animeDiffusionV45Full,
          persist: false,
        );
        controller.replaceSourceImage(
          _validImageBytes(width: 768, height: 1024),
        );

        controller.enterInpaintMode();
        controller.onMaskChanged(Uint8List.fromList([9, 9, 9]));

        var params = container.read(generationParamsNotifierProvider);
        expect(params.model, equals(ImageModels.animeDiffusionV45Full));

        paramsNotifier.updateModel(
          ImageModels.animeDiffusionV45Curated,
          persist: false,
        );

        controller.enterBaseMode();

        params = container.read(generationParamsNotifierProvider);
        expect(params.model, equals(ImageModels.animeDiffusionV45Curated));
      },
    );

    test(
      'clearSourceImage should restore base request state after an inpaint session',
      () {
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );
        final paramsNotifier = container.read(
          generationParamsNotifierProvider.notifier,
        );

        paramsNotifier.updateModel(
          ImageModels.animeDiffusionV45Full,
          persist: false,
        );
        paramsNotifier.updateSize(1024, 1536, persist: false);
        controller.replaceSourceImage(
          _validImageBytes(width: 768, height: 1024),
        );

        controller.enterInpaintMode();
        controller.onMaskChanged(Uint8List.fromList([9, 9, 9]));
        controller.clearSourceImage();

        final workflow = container.read(imageWorkflowControllerProvider);
        final params = container.read(generationParamsNotifierProvider);

        expect(workflow.mode, ImageWorkflowMode.base);
        expect(workflow.sourceWidth, isNull);
        expect(workflow.sourceHeight, isNull);
        expect(params.sourceImage, isNull);
        expect(params.maskImage, isNull);
        expect(params.action, ImageGenerationAction.generate);
        expect(params.model, ImageModels.animeDiffusionV45Full);
        expect(params.width, 1024);
        expect(params.height, 1536);
      },
    );

    test(
      'onMaskChanged should keep the settings model while toggling inpaint mode',
      () {
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );
        final paramsNotifier = container.read(
          generationParamsNotifierProvider.notifier,
        );

        paramsNotifier.updateModel(
          ImageModels.animeDiffusionV4Full,
          persist: false,
        );
        controller.replaceSourceImage(
          _validImageBytes(width: 768, height: 1024),
        );

        controller.enterInpaintMode();

        var params = container.read(generationParamsNotifierProvider);
        expect(params.action, ImageGenerationAction.img2img);
        expect(params.model, ImageModels.animeDiffusionV4Full);

        controller.onMaskChanged(Uint8List.fromList([9, 9, 9]));

        params = container.read(generationParamsNotifierProvider);
        expect(params.action, ImageGenerationAction.infill);
        expect(params.model, ImageModels.animeDiffusionV4Full);

        controller.onMaskChanged(null);

        params = container.read(generationParamsNotifierProvider);
        expect(params.action, ImageGenerationAction.img2img);
        expect(params.model, ImageModels.animeDiffusionV4Full);
      },
    );

    test(
      'upscale settings should persist comfy model and scale across rebuilds',
      () async {
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );

        controller.updateUpscaleComfyScale(1.8);
        controller.updateUpscaleComfyModel('4x-ClearRealityV1.pth');
        await Hive.box(StorageKeys.settingsBox).flush();

        container.dispose();
        container = ProviderContainer();

        final workflow = container.read(imageWorkflowControllerProvider);

        expect(workflow.upscale.comfyScale, equals(1.8));
        expect(workflow.upscale.comfyModel, equals('4x-ClearRealityV1.pth'));
      },
    );

    test(
      'upscale settings should persist comfy module and SeedVR2 tile controls across rebuilds',
      () async {
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );

        controller.updateComfyUpscaleModule(ComfyUpscaleModule.seedvr2);
        controller.updateSeedvr2VaeTileSize(768);
        controller.updateSeedvr2Tiled(true);
        controller.updateSeedvr2TileSize(1280);
        await Hive.box(StorageKeys.settingsBox).flush();

        container.dispose();
        container = ProviderContainer();

        final workflow = container.read(imageWorkflowControllerProvider);

        expect(
          workflow.upscale.comfyModule,
          equals(ComfyUpscaleModule.seedvr2),
        );
        expect(workflow.upscale.seedvr2VaeTileSize, equals(768));
        expect(workflow.upscale.seedvr2Tiled, isTrue);
        expect(workflow.upscale.seedvr2TileSize, equals(1280));
      },
    );

    test(
      'upscale settings should persist SeedVR2 blocks to swap across rebuilds',
      () async {
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );

        controller.updateSeedvr2BlocksToSwap(28);
        await Hive.box(StorageKeys.settingsBox).flush();

        container.dispose();
        container = ProviderContainer();

        final workflow = container.read(imageWorkflowControllerProvider);

        expect(workflow.upscale.seedvr2BlocksToSwap, equals(28));
      },
    );

    test(
      'updateSeedvr2BlocksToSwap should clamp values to the valid range',
      () {
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );

        controller.updateSeedvr2BlocksToSwap(-8);
        expect(
          container
              .read(imageWorkflowControllerProvider)
              .upscale
              .seedvr2BlocksToSwap,
          equals(UpscaleWorkflowSettings.minSeedvr2BlocksToSwap),
        );

        controller.updateSeedvr2BlocksToSwap(120);
        expect(
          container
              .read(imageWorkflowControllerProvider)
              .upscale
              .seedvr2BlocksToSwap,
          equals(UpscaleWorkflowSettings.maxSeedvr2BlocksToSwap),
        );
      },
    );

    test('build should default upscale settings to safe local defaults', () {
      final workflow = container.read(imageWorkflowControllerProvider);

      expect(workflow.upscale.backend, equals(UpscaleBackend.local));
      expect(workflow.upscale.comfyModule, equals(ComfyUpscaleModule.seedvr2));
      expect(workflow.upscale.comfyScale, equals(1.5));
      expect(
        workflow.upscale.comfyModel,
        equals(UpscaleWorkflowSettings.defaultComfyModel),
      );
    });

    test(
      'workflow settings should persist enhance settings and upscale backend across rebuilds',
      () async {
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );
        final paramsNotifier = container.read(
          generationParamsNotifierProvider.notifier,
        );

        paramsNotifier.setSourceImage(
          _validImageBytes(width: 768, height: 1024),
        );
        controller.setSourceImageDimensions(768, 1024);
        controller.enterEnhanceMode();
        controller.updateEnhanceMagnitude(0.72);
        controller.toggleEnhanceIndividualSettings(true);
        controller.updateEnhanceUpscaleFactor(1.5);
        controller.updateEnhanceIndividualSettings(strength: 0.38, noise: 0.14);
        controller.updateUpscaleBackend(UpscaleBackend.novelai);
        await Hive.box(StorageKeys.settingsBox).flush();

        container.dispose();
        container = ProviderContainer();

        final workflow = container.read(imageWorkflowControllerProvider);

        expect(workflow.enhance.magnitude, equals(0.72));
        expect(workflow.enhance.showIndividualSettings, isTrue);
        expect(workflow.enhance.upscaleFactor, equals(1.5));
        expect(workflow.enhance.strength, equals(0.38));
        expect(workflow.enhance.noise, equals(0.14));
        expect(workflow.upscale.backend, equals(UpscaleBackend.novelai));
      },
    );

    test(
      'upscale settings should clamp persisted comfy scale to safe max',
      () async {
        await Hive.box(
          StorageKeys.settingsBox,
        ).put(StorageKeys.comfyuiUpscaleScale, 3.4);

        container.dispose();
        container = ProviderContainer();

        final workflow = container.read(imageWorkflowControllerProvider);

        expect(workflow.upscale.comfyScale, equals(2.0));
      },
    );

    test('selectPreferredUpscaleModel should prefer 3b q4 variants', () {
      expect(
        selectPreferredUpscaleModel(const [
          'seedvr2_ema_7b_fp16.safetensors',
          'seedvr2_ema_3b_q4_k_m.safetensors',
        ]),
        equals('seedvr2_ema_3b_q4_k_m.safetensors'),
      );
    });

    test(
      'clearSourceImage should preserve workflow setting preferences',
      () async {
        final controller = container.read(
          imageWorkflowControllerProvider.notifier,
        );

        controller.updateUpscaleBackend(UpscaleBackend.novelai);
        controller.updateUpscaleComfyScale(1.7);
        controller.updateUpscaleComfyModel('seedvr2_ema_3b_q4_k_m.safetensors');
        controller.updateEnhanceMagnitude(0.66);
        controller.toggleEnhanceIndividualSettings(true);
        controller.updateEnhanceIndividualSettings(strength: 0.41, noise: 0.12);
        controller.replaceSourceImage(
          _validImageBytes(width: 768, height: 1024),
        );

        controller.clearSourceImage();

        final workflow = container.read(imageWorkflowControllerProvider);
        expect(workflow.upscale.backend, equals(UpscaleBackend.novelai));
        expect(workflow.upscale.comfyScale, equals(1.7));
        expect(
          workflow.upscale.comfyModel,
          equals('seedvr2_ema_3b_q4_k_m.safetensors'),
        );
        expect(workflow.enhance.magnitude, equals(0.66));
        expect(workflow.enhance.showIndividualSettings, isTrue);
        expect(workflow.enhance.strength, equals(0.41));
        expect(workflow.enhance.noise, equals(0.12));
      },
    );
  });

  group('resolveSeedvr2SwapIoComponents', () {
    test('should keep IO components on the GPU at low swap levels', () {
      expect(resolveSeedvr2SwapIoComponents(0), isFalse);
      expect(
        resolveSeedvr2SwapIoComponents(
          UpscaleWorkflowSettings.defaultSeedvr2BlocksToSwap,
        ),
        isFalse,
      );
      expect(
        resolveSeedvr2SwapIoComponents(seedvr2SwapIoComponentsThreshold - 1),
        isFalse,
      );
    });

    test('should offload IO components once swapping gets aggressive', () {
      expect(
        resolveSeedvr2SwapIoComponents(seedvr2SwapIoComponentsThreshold),
        isTrue,
      );
      expect(
        resolveSeedvr2SwapIoComponents(
          UpscaleWorkflowSettings.maxSeedvr2BlocksToSwap,
        ),
        isTrue,
      );
    });

    test('should stay within the slider range exposed by the UI', () {
      expect(
        seedvr2SwapIoComponentsThreshold,
        greaterThan(UpscaleWorkflowSettings.defaultSeedvr2BlocksToSwap),
      );
      expect(
        seedvr2SwapIoComponentsThreshold,
        lessThanOrEqualTo(UpscaleWorkflowSettings.maxSeedvr2BlocksToSwap),
      );
    });
  });
}

Uint8List _validImageBytes({required int width, required int height}) {
  return Uint8List.fromList(
    img.encodePng(img.Image(width: width, height: height)),
  );
}

Uint8List _validMaskBytes({required int width, required int height}) {
  return Uint8List.fromList(
    img.encodePng(img.Image(width: width, height: height)),
  );
}
