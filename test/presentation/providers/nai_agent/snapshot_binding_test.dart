import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/generation_snapshot.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/data/models/upscale/local_upscale_models.dart';
import 'package:nai_launcher/core/utils/inpaint_focus_region.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/quality_preset_provider.dart';
import 'package:nai_launcher/presentation/providers/uc_preset_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_studio_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_snapshot.dart';
import '../krita/agent_bridge_draft_test.dart'
    show MemoryDraftSettings, MemoryCharacters, OfflineAuth, IdleGeneration;

class _Blocks extends PromptBlockRepository {
  _Blocks(Directory root) : super(PromptBlockStorage(hivePath: root.path));
  final blocks = <PromptBlock>[];
  Future<void> Function()? onImport;
  @override
  Future<PromptBlockLibraryData> load() async =>
      PromptBlockLibraryData(blocks: blocks, folders: []);
  @override
  Future<void> importBlocks(Iterable<PromptBlock> values) async {
    blocks.addAll(values);
    await onImport?.call();
  }

  @override
  Future<PromptBlock> updateBlock(
    PromptBlock value, {
    void Function(PromptBlock?)? beforeWrite,
  }) async {
    final index = blocks.indexWhere((b) => b.id == value.id);
    beforeWrite?.call(index < 0 ? null : blocks[index]);
    blocks[index] = value;
    return value;
  }

  @override
  Future<PromptBlock?> getBlock(String id) async =>
      blocks.where((b) => b.id == id).firstOrNull;
}

class _Library extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async {
    final data = await ref.read(promptBlockRepositoryProvider).load();
    return PromptBlockLibraryState(blocks: data.blocks, folders: []);
  }
}

class _Vibes extends VibeLibraryStorageService {
  @override
  Future<void> saveGenerationStateJson(String value) async {}
  @override
  Future<String?> loadGenerationStateJson() async => null;
}

void main() {
  late Directory root;
  late ProviderContainer container;
  late _Blocks repository;
  late Uint8List pixels;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('nai-agent-snapshot-binding-');
    Hive.init(root.path);
    await Hive.openBox(StorageKeys.settingsBox);
    repository = _Blocks(root);
    pixels = Uint8List.fromList(img.encodePng(img.Image(width: 3, height: 2)));
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockRepositoryProvider.overrideWithValue(repository),
        promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
        vibeLibraryStorageServiceProvider.overrideWithValue(_Vibes()),
        imageGenerationNotifierProvider.overrideWith(IdleGeneration.new),
        authNotifierProvider.overrideWith(OfflineAuth.new),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
  });
  tearDown(() async {
    container.dispose();
    await Future<void>.delayed(Duration.zero);
    await Hive.close();
    await root.delete(recursive: true);
  });
  Future<String> version() async =>
      (await container
              .read(naiAgentStudioFactoryProvider)(root, root, true)
              .execute('studio_context', {
                'scope': 'draft',
              }, NaiAgentCancellation()))['details']['draft']['draft_version']
          as String;
  Future<Map<String, dynamic>> run(Map<String, dynamic> params) => container
      .read(naiAgentStudioFactoryProvider)(root, root, true)
      .execute('snapshot', params, NaiAgentCancellation());

  ImageWorkflowController workflow() =>
      container.read(imageWorkflowControllerProvider.notifier);
  Future<Map> saveWorkflow(String name) async =>
      (await run({'action': 'save', 'name': name}))['details']['saved'] as Map;
  Future<void> loadWorkflow(Map saved) async {
    await run({
      'action': 'load',
      'id': saved['id'],
      'expected_version': await version(),
    });
  }

  test(
    'native inpaint snapshot restores mask/focus/geometry and original base size',
    () async {
      pixels = Uint8List.fromList(
        img.encodePng(img.Image(width: 128, height: 256)),
      );
      final writer = container.read(generationParamsNotifierProvider.notifier);
      writer.updateSize(832, 1216, persist: false);
      final controller = workflow();
      controller.replaceSourceImage(pixels, autoAdapt: false);
      controller.applyInpaintEditorResult(
        maskImage: pixels,
        focusRegion: const InpaintFocusRegion(
          x: 0,
          y: 0,
          width: 128,
          height: 256,
          context: 16,
        ),
        sourceIsOutpaint: true,
      );
      final before = container.read(generationParamsNotifierProvider);
      final beforeWorkflow = encodeImageWorkflowConfiguration(
        container.read(imageWorkflowControllerProvider),
        before,
      );
      final saved = await saveWorkflow('重绘与扩图');
      controller.clearSourceImage();
      await loadWorkflow(saved);
      final actual = container.read(generationParamsNotifierProvider);
      expect(encodeAgentImageParams(actual), encodeAgentImageParams(before));
      expect(
        encodeImageWorkflowConfiguration(
          container.read(imageWorkflowControllerProvider),
          actual,
        ),
        beforeWorkflow,
      );
      expect(
        container.read(imageWorkflowControllerProvider).mode,
        ImageWorkflowMode.inpaint,
      );
      expect(
        container.read(imageWorkflowControllerProvider).isPanelExpanded,
        isTrue,
      );
      controller.clearSourceImage();
      expect(
        (
          container.read(generationParamsNotifierProvider).width,
          container.read(generationParamsNotifierProvider).height,
        ),
        (832, 1216),
      );
    },
  );

  test(
    'enhance settings restore natively and exiting returns to saved base parameters',
    () async {
      pixels = Uint8List.fromList(
        img.encodePng(img.Image(width: 128, height: 128)),
      );
      final writer = container.read(generationParamsNotifierProvider.notifier);
      writer.updateSize(832, 1216, persist: false);
      writer.updateStrength(0.37);
      writer.updateNoise(0.12);
      final controller = workflow();
      controller.replaceSourceImage(pixels, autoAdapt: false);
      controller.enterEnhanceMode();
      controller.updateEnhanceIndividualSettings(strength: 0.61, noise: 0.21);
      controller.updateEnhanceUpscaleFactor(1.5);
      final params = container.read(generationParamsNotifierProvider);
      final request = container.read(generationRequestParamsProvider);
      final saved = await saveWorkflow('增强配置');
      controller.clearSourceImage();
      controller.updateEnhanceMagnitude(0.2);
      await loadWorkflow(saved);
      expect(
        container.read(imageWorkflowControllerProvider).mode,
        ImageWorkflowMode.enhance,
      );
      expect(
        encodeAgentImageParams(container.read(generationRequestParamsProvider)),
        encodeAgentImageParams(request),
      );
      expect(
        encodeAgentImageParams(
          container.read(generationParamsNotifierProvider),
        ),
        encodeAgentImageParams(params),
      );
      controller.exitEnhanceMode();
      final base = container.read(generationParamsNotifierProvider);
      expect(
        (base.width, base.height, base.strength, base.noise),
        (832, 1216, 0.37, 0.12),
      );
    },
  );

  test(
    'local post-generation enhance settings and SeedVR2 options survive restore and controller recreation',
    () async {
      pixels = Uint8List.fromList(
        img.encodePng(img.Image(width: 128, height: 128)),
      );
      final controller = workflow();
      controller.replaceSourceImage(pixels, autoAdapt: false);
      controller.enterEnhanceMode();
      controller.setEnhanceLocalUpscale();
      controller.updateLocalUpscaleModel('seedvr2-7b');
      controller.updateLocalUpscaleScale(1.75);
      controller.updateLocalSeedvr2Options(
        const Seedvr2Options(
          seed: 42,
          blocksToSwap: 20,
          colorCorrection: 'wavelet',
          vaeTileSize: 512,
          vaeTileOverlap: 64,
        ),
      );
      final saved = await saveWorkflow('本地后放大');
      controller.clearSourceImage();
      controller.updateLocalUpscaleModel('anime');
      controller.updateLocalUpscaleScale(2);
      await loadWorkflow(saved);
      var state = container.read(imageWorkflowControllerProvider);
      expect(
        (
          state.mode,
          state.enhance.localUpscale,
          state.upscale.localModel,
          state.upscale.localScale,
        ),
        (ImageWorkflowMode.enhance, true, 'seedvr2-7b', 1.75),
      );
      expect(state.upscale.selectedSeedvr2Options.seed, 42);
      await Future<void>.delayed(Duration.zero);
      container.invalidate(imageWorkflowControllerProvider);
      state = container.read(imageWorkflowControllerProvider);
      expect(
        (
          state.enhance.localUpscale,
          state.upscale.localModel,
          state.upscale.localScale,
          state.upscale.selectedSeedvr2Options.seed,
        ),
        (true, 'seedvr2-7b', 1.75, 42),
      );
    },
  );

  test(
    'named snapshot excludes canvas temporary upscale but retains current prompt and tool settings',
    () async {
      pixels = Uint8List.fromList(
        img.encodePng(img.Image(width: 128, height: 128)),
      );
      final controller = workflow();
      controller.replaceSourceImage(pixels, autoAdapt: false);
      controller.applyInpaintEditorResult(
        maskImage: pixels,
        sourceIsOutpaint: false,
      );
      final original = container.read(generationParamsNotifierProvider);
      final other = Uint8List.fromList(
        img.encodePng(img.Image(width: 256, height: 128)),
      );
      controller.openTemporaryTool(other, ImageWorkflowMode.upscale);
      container
          .read(pillWorkspaceProvider(PillScopes.main).notifier)
          .replaceWithPlainText('latest draft prompt');
      container
          .read(generationParamsNotifierProvider.notifier)
          .updatePromptImmediately('latest draft prompt');
      controller.updateLocalUpscaleModel('rtx-vsr');
      final saved = await saveWorkflow('工具打开期间');
      final file = jsonDecode(
        await File(saved['path'] as String).readAsString(),
      );
      final snapshotImage = decodeAgentImageParams(
        Map<String, dynamic>.from(file['generation']['image'] as Map),
      );
      expect(snapshotImage.sourceImage, original.sourceImage);
      expect(snapshotImage.maskImage, original.maskImage);
      expect(snapshotImage.action, ImageGenerationAction.infill);
      expect(file['generation']['draft']['fields']['width'], original.width);
      expect(snapshotImage.prompt, 'latest draft prompt');
      await loadWorkflow(saved);
      expect(
        container.read(imageWorkflowControllerProvider).mode,
        ImageWorkflowMode.inpaint,
      );
      expect(
        container.read(imageWorkflowControllerProvider).upscale.localModel,
        'rtx-vsr',
      );
      controller.closeTemporaryTool();
      expect(
        container.read(generationParamsNotifierProvider).sourceImage,
        original.sourceImage,
      );
      expect(
        container.read(generationParamsNotifierProvider).prompt,
        'latest draft prompt',
      );
    },
  );

  test(
    'legacy snapshot derives inpaint mode and keeps current settings explicitly',
    () async {
      pixels = Uint8List.fromList(
        img.encodePng(img.Image(width: 128, height: 128)),
      );
      final controller = workflow();
      controller.replaceSourceImage(pixels, autoAdapt: false);
      controller.applyInpaintEditorResult(
        maskImage: pixels,
        sourceIsOutpaint: false,
      );
      final saved = await saveWorkflow('旧版快照');
      final file = File(saved['path'] as String);
      final json = jsonDecode(await file.readAsString());
      (json['generation'] as Map).remove('image_workflow');
      await file.writeAsString(jsonEncode(json));
      controller.clearSourceImage();
      controller.updateLocalUpscaleModel('rtx-vsr');
      final read = await run({'action': 'read', 'id': saved['id']});
      expect(read['details']['workflow_settings_saved'], isFalse);
      await loadWorkflow(saved);
      final state = container.read(imageWorkflowControllerProvider);
      expect(
        (state.mode, state.sourceWidth, state.sourceImageWidth),
        (ImageWorkflowMode.inpaint, 128, 128),
      );
      expect(state.upscale.localModel, 'rtx-vsr');
    },
  );

  test(
    'workflow-only change during snapshot import rejects load and preserves user setting',
    () async {
      final block = PromptBlock.create(title: 'dependency', content: 'source');
      repository.blocks.add(block);
      await container
          .read(promptBlockLibraryNotifierProvider.notifier)
          .refresh();
      container
          .read(pillWorkspaceProvider(PillScopes.main).notifier)
          .insertBlockAt(offset: 0, blockId: block.id);
      final saved = await saveWorkflow('设置冲突');
      repository.blocks.clear();
      await container
          .read(promptBlockLibraryNotifierProvider.notifier)
          .refresh();
      container
          .read(pillWorkspaceProvider(PillScopes.main).notifier)
          .replaceWithPlainText('before loading');
      final before = await version();
      repository.onImport = () async {
        workflow().updateLocalUpscaleScale(2.25);
      };
      await expectLater(
        run({'action': 'load', 'id': saved['id'], 'expected_version': before}),
        throwsA(
          isA<NaiAgentToolError>().having(
            (e) => e.code,
            'code',
            'draft_conflict',
          ),
        ),
      );
      expect(
        container.read(imageWorkflowControllerProvider).upscale.localScale,
        2.25,
      );
      expect(
        container.read(pillWorkspaceProvider(PillScopes.main)).projection,
        'before loading',
      );
    },
  );

  test(
    'invalid workflow geometry or settings cannot alter the current draft',
    () async {
      final saved = await saveWorkflow('损坏配置');
      final file = File(saved['path'] as String);
      final json = jsonDecode(await file.readAsString());
      json['generation']['image_workflow']['upscale']['localScale'] = 5;
      await file.writeAsString(jsonEncode(json));
      container
          .read(pillWorkspaceProvider(PillScopes.main).notifier)
          .replaceWithPlainText('user draft');
      await expectLater(loadWorkflow(saved), throwsA(isA<FormatException>()));
      expect(
        container.read(pillWorkspaceProvider(PillScopes.main)).projection,
        'user draft',
      );
      expect(
        container.read(imageWorkflowControllerProvider).upscale.localScale,
        1.5,
      );
    },
  );

  test(
    'workflow edit after context read rejects stale load even when ImageParams are unchanged',
    () async {
      final saved = await saveWorkflow('版本保护');
      final before = await version();
      final imageBefore = container.read(generationParamsNotifierProvider);
      workflow().updateLocalUpscaleModel('rtx-vsr');
      expect(
        container.read(generationParamsNotifierProvider),
        same(imageBefore),
      );
      expect(await version(), isNot(before));
      await expectLater(
        run({'action': 'load', 'id': saved['id'], 'expected_version': before}),
        throwsA(
          isA<NaiAgentToolError>().having(
            (e) => e.code,
            'code',
            'draft_conflict',
          ),
        ),
      );
      expect(
        container.read(imageWorkflowControllerProvider).upscale.localModel,
        'rtx-vsr',
      );
    },
  );
  test(
    'native upscale snapshot restores selected backend and can exit to the original draft size',
    () async {
      pixels = Uint8List.fromList(
        img.encodePng(img.Image(width: 128, height: 256)),
      );
      container
          .read(generationParamsNotifierProvider.notifier)
          .updateSize(832, 1216, persist: false);
      final controller = workflow();
      controller.replaceSourceImage(pixels, autoAdapt: false);
      controller.enterUpscaleMode();
      controller.updateUpscaleBackend(UpscaleBackend.novelai);
      final saved = await saveWorkflow('超分模式');
      controller.clearSourceImage();
      controller.updateUpscaleBackend(UpscaleBackend.local);
      await loadWorkflow(saved);
      expect(
        (
          container.read(imageWorkflowControllerProvider).mode,
          container.read(imageWorkflowControllerProvider).upscale.backend,
        ),
        (ImageWorkflowMode.upscale, UpscaleBackend.novelai),
      );
      controller.exitUpscaleMode();
      expect(
        (
          container.read(generationParamsNotifierProvider).width,
          container.read(generationParamsNotifierProvider).height,
        ),
        (832, 1216),
      );
    },
  );
  test(
    'snapshot load clears temporary canvas enhance ownership and keeps saved sidebar source',
    () async {
      pixels = Uint8List.fromList(
        img.encodePng(img.Image(width: 128, height: 128)),
      );
      final controller = workflow();
      controller.replaceSourceImage(pixels, autoAdapt: false);
      final other = Uint8List.fromList(
        img.encodePng(img.Image(width: 256, height: 128)),
      );
      controller.openTemporaryTool(other, ImageWorkflowMode.enhance);
      controller.updateEnhanceMagnitude(0.3);
      final saved = await saveWorkflow('临时增强打开');
      await loadWorkflow(saved);
      expect(
        container.read(imageWorkflowControllerProvider).temporaryEnhanceSource,
        isNull,
      );
      expect(
        container.read(imageWorkflowControllerProvider).enhance.magnitude,
        0.3,
      );
      expect(
        container.read(generationRequestParamsProvider).sourceImage,
        pixels,
      );
      controller.closeTemporaryTool();
      expect(
        container.read(generationParamsNotifierProvider).sourceImage,
        pixels,
      );
      expect(
        container.read(imageWorkflowControllerProvider).mode,
        ImageWorkflowMode.base,
      );
    },
  );
  test(
    'real providers restore images, references, inline translation and character metadata with backup',
    () async {
      final lane = container.read(
        pillWorkspaceProvider(PillScopes.main).notifier,
      );
      lane.insertTranslationAt(offset: 0, source: 'snapshot raw', zh: '快照原文');
      final originalDocument = container
          .read(pillWorkspaceProvider(PillScopes.main))
          .document;
      container
          .read(characterPromptNotifierProvider.notifier)
          .setGlobalAiChoice(false);
      final config = container.read(characterPromptNotifierProvider);
      final params = container
          .read(generationParamsNotifierProvider)
          .copyWith(
            seed: 1337,
            sourceImage: pixels,
            maskImage: pixels,
            action: ImageGenerationAction.infill,
            extraNoiseSeed: 1336,
            enhanceWorkflow: true,
            vibeReferencesV4: [
              VibeReference(
                displayName: 'source',
                vibeEncoding: 'saved encoding',
                rawImageData: pixels,
                thumbnail: pixels,
                enabled: false,
              ),
            ],
          );
      container
          .read(generationParamsNotifierProvider.notifier)
          .restoreAgentSnapshot(params);
      final saved = await run({'action': 'save', 'name': '原始配置'});
      container
          .read(generationParamsNotifierProvider.notifier)
          .restoreAgentSnapshot(const ImageParams(prompt: 'new user draft'));
      lane.replaceWithPlainText('new user draft');
      container.read(characterPromptNotifierProvider.notifier).clearAll();
      final loaded = await run({
        'action': 'load',
        'id': saved['details']['saved']['id'],
        'expected_version': await version(),
      });
      final actual = container.read(generationParamsNotifierProvider);
      expect(encodeAgentImageParams(actual), encodeAgentImageParams(params));
      expect(
        container.read(pillWorkspaceProvider(PillScopes.main)).document,
        originalDocument,
      );
      expect(container.read(characterPromptNotifierProvider), config);
      final backup = jsonDecode(
        await File(loaded['details']['backup_path']).readAsString(),
      );
      expect(
        backup['generation']['draft']['fields']['prompt'],
        'new user draft',
      );
      expect(backup['generation']['image']['extra']['sourceImage'], isNull);
      expect(actual.vibeReferencesV4.single.vibeEncoding, 'saved encoding');
    },
  );
  test(
    'changed/deleted block restores as independent dependency without overwriting current library',
    () async {
      final block = PromptBlock.create(
        title: 'saved preset',
        content: 'saved content',
        atoms: ['saved content'],
        negativeContent: 'saved negative',
      );
      repository.blocks.add(block);
      await container
          .read(promptBlockLibraryNotifierProvider.notifier)
          .refresh();
      container
          .read(pillWorkspaceProvider(PillScopes.main).notifier)
          .insertBlockAt(offset: 0, blockId: block.id);
      container
          .read(qualityPresetNotifierProvider.notifier)
          .setCustomEntry(block.id);
      container
          .read(ucPresetNotifierProvider.notifier)
          .setCustomEntry(block.id);
      await Future<void>.delayed(Duration.zero);
      final saved = await run({'action': 'save', 'name': '含积木'});
      repository.blocks[0] = block.copyWith(content: 'user changed content');
      await container
          .read(promptBlockLibraryNotifierProvider.notifier)
          .refresh();
      container
          .read(pillWorkspaceProvider(PillScopes.main).notifier)
          .replaceWithPlainText('newer');
      await run({
        'action': 'load',
        'id': saved['details']['saved']['id'],
        'expected_version': await version(),
      });
      final restored = container.read(pillWorkspaceProvider(PillScopes.main));
      expect(restored.projection, 'saved content');
      final copyId = restored.document.instances.values.single.blockId;
      expect(copyId, isNot(block.id));
      expect(repository.blocks.first.content, 'user changed content');
      expect(
        repository.blocks.where((b) => b.id == copyId).single.content,
        'saved content',
      );
      expect(
        container.read(qualityPresetNotifierProvider).customEntryId,
        copyId,
      );
      expect(container.read(ucPresetNotifierProvider).customEntryId, copyId);
      final count = repository.blocks.length;
      await run({
        'action': 'load',
        'id': saved['details']['saved']['id'],
        'expected_version': await version(),
      });
      expect(
        repository.blocks,
        hasLength(count),
      ); // Reuse this snapshot's dependency, not another duplicate.
    },
  );
  test(
    'editing during dependency import preserves the newer draft and existing library block',
    () async {
      final block = PromptBlock.create(title: 'original', content: 'old');
      repository.blocks.add(block);
      await container
          .read(promptBlockLibraryNotifierProvider.notifier)
          .refresh();
      container
          .read(pillWorkspaceProvider(PillScopes.main).notifier)
          .insertBlockAt(offset: 0, blockId: block.id);
      final saved = await run({'action': 'save', 'name': 'conflict'});
      repository.blocks.clear();
      await container
          .read(promptBlockLibraryNotifierProvider.notifier)
          .refresh();
      container
          .read(pillWorkspaceProvider(PillScopes.main).notifier)
          .replaceWithPlainText('before import');
      repository.onImport = () async => container
          .read(pillWorkspaceProvider(PillScopes.main).notifier)
          .replaceWithPlainText('user edited while importing');
      await expectLater(
        run({
          'action': 'load',
          'id': saved['details']['saved']['id'],
          'expected_version': await version(),
        }),
        throwsA(
          isA<NaiAgentToolError>().having(
            (e) => e.code,
            'code',
            'draft_conflict',
          ),
        ),
      );
      expect(
        container.read(pillWorkspaceProvider(PillScopes.main)).projection,
        'user edited while importing',
      );
    },
  );
}
