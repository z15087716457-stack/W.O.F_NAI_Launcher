import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';

import '../../../helpers/app_logger_test_isolation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late Directory directory;
  late ProviderContainer container;
  late ImageWorkflowController workflow;
  var disposed = false;
  final a = Uint8List.fromList(img.encodePng(img.Image(width: 64, height: 64)));
  final b = Uint8List.fromList(
    img.encodePng(img.Image(width: 128, height: 64)),
  );
  final c = Uint8List.fromList(
    img.encodePng(img.Image(width: 64, height: 128)),
  );
  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'source_import_lifecycle_',
    );
    Hive.init(directory.path);
    await Hive.openBox(StorageKeys.settingsBox);
    container = ProviderContainer();
    disposed = false;
    workflow = container.read(imageWorkflowControllerProvider.notifier);
    workflow.replaceSourceImage(a, autoAdapt: false);
  });
  tearDown(() async {
    if (!disposed) container.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });
  for (final hadSource in [false, true]) {
    test(
      'clear cancels an in-flight source import, hadSource=$hadSource',
      () async {
        if (!hadSource) workflow.clearSourceImage();
        final pending = workflow.replaceSourceImageAsync(b);
        workflow.clearSourceImage();
        await pending;
        final params = container.read(generationParamsNotifierProvider);
        expect(params.sourceImage, isNull);
        expect(params.maskImage, isNull);
        expect(params.action, ImageGenerationAction.generate);
        expect(
          container.read(imageWorkflowControllerProvider).mode,
          ImageWorkflowMode.base,
        );
      },
    );
  }
  test('newer direct replacement wins over a pending import', () async {
    final pending = workflow.replaceSourceImageAsync(b);
    workflow.replaceSourceImage(c, autoAdapt: false);
    await pending;
    expect(
      container.read(generationParamsNotifierProvider).sourceImage,
      same(c),
    );
  });
  test('newer asynchronous import wins', () async {
    await Future.wait([
      workflow.replaceSourceImageAsync(b),
      workflow.replaceSourceImageAsync(c),
    ]);
    expect(
      container.read(generationParamsNotifierProvider).sourceImage,
      same(c),
    );
  });
  test('unrelated prompt edits remain valid while importing', () async {
    final pending = workflow.replaceSourceImageAsync(b);
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePromptImmediately('new prompt fixture');
    await pending;
    await container.read(promptBlockLibraryNotifierProvider.future);
    expect(
      container.read(generationParamsNotifierProvider).sourceImage,
      same(b),
    );
    expect(
      container.read(generationParamsNotifierProvider).prompt,
      'new prompt fixture',
    );
  });
  test(
    'newer size edit cannot be replaced by old automatic adaptation',
    () async {
      final pending = workflow.replaceSourceImageAsync(b);
      container
          .read(generationParamsNotifierProvider.notifier)
          .updateSize(256, 512, persist: false);
      await pending;
      final params = container.read(generationParamsNotifierProvider);
      expect(params.sourceImage, same(a));
      expect((params.width, params.height), (256, 512));
    },
  );
  test('newer mask and inpaint mode survive a pending import', () async {
    final pending = workflow.replaceSourceImageAsync(b);
    workflow.enterInpaintMode();
    workflow.onMaskChanged(c);
    await pending;
    final params = container.read(generationParamsNotifierProvider);
    expect(params.sourceImage, same(a));
    expect(params.maskImage, same(c));
    expect(
      container.read(imageWorkflowControllerProvider).mode,
      ImageWorkflowMode.inpaint,
    );
  });
  test(
    'model change invalidates resolution computed for another model',
    () async {
      final pending = workflow.replaceSourceImageAsync(b);
      container
          .read(generationParamsNotifierProvider.notifier)
          .updateModel(ImageModels.animeDiffusionV5Curated, persist: false);
      await pending;
      expect(
        container.read(generationParamsNotifierProvider).sourceImage,
        same(a),
      );
      expect(
        container.read(generationParamsNotifierProvider).model,
        ImageModels.animeDiffusionV5Curated,
      );
    },
  );
  test('editor replacement survives a pending import', () async {
    final pending = workflow.replaceSourceImageAsync(b);
    workflow.applyInpaintEditorResult(
      sourceImage: c,
      sourceWidth: 64,
      sourceHeight: 128,
      maskImage: a,
      sourceIsOutpaint: false,
      useExactSourceDimensions: true,
    );
    await pending;
    expect(
      container.read(generationParamsNotifierProvider).sourceImage,
      same(c),
    );
    expect(container.read(generationParamsNotifierProvider).maskImage, same(a));
  });
  test('running tool cannot receive a late source replacement', () async {
    final pending = workflow.replaceSourceImageAsync(b);
    workflow.setToolRunning(true);
    await pending;
    expect(
      container.read(generationParamsNotifierProvider).sourceImage,
      same(a),
    );
  });
  test('disposal cancels pending import', () async {
    final pending = workflow.replaceSourceImageAsync(b);
    container.dispose();
    disposed = true;
    await pending;
  });
}
