import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/enums/precise_ref_type.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/wiring/generation_backend.dart';
import 'package:nai_launcher/presentation/wiring/generation_reference_identity.dart';
import 'package:nai_launcher/presentation/wiring/generation_references.dart';
import '../providers/krita/agent_bridge_draft_test.dart'
    show
        MemoryCharacters,
        MemoryDraftSettings,
        EmptyBlocks,
        IdleGeneration,
        OfflineAuth;
import 'generation_backend_test.dart' show MemoryGenerationPlatform;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ProviderContainer container;
  late GenerationReferences actions;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('generation-references-');
    Hive.init(directory.path);
    await Hive.openBox(StorageKeys.settingsBox);
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockLibraryNotifierProvider.overrideWith(EmptyBlocks.new),
        imageGenerationNotifierProvider.overrideWith(IdleGeneration.new),
        authNotifierProvider.overrideWith(OfflineAuth.new),
        generationPlatformProvider.overrideWithValue(
          MemoryGenerationPlatform(),
        ),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
    actions = container.read(generationReferencesProvider);
  });
  tearDown(() async {
    container.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });
  test('参考图按模型隐藏但不丢失已存参数，编码状态按目标模型', () {
    final vibe = VibeReference(
      displayName: 'raw',
      vibeEncoding: 'cached',
      rawImageData: Uint8List.fromList([1]),
      encodingModel: ImageModels.animeDiffusionV45Full,
    );
    final params = ImageParams(
      model: ImageModels.animeDiffusionV45Full,
      vibeReferencesV4: [vibe],
    );
    final identity = GenerationReferenceIdentity()..sync(params);
    expect(
      generationRefsView(
        params,
        const ImageWorkflowState(),
        identity,
      ).vibes!.list.single.state,
      GenVibeState.encoded,
    );
    final v4 = params.copyWith(model: ImageModels.animeDiffusionV4Full);
    expect(
      generationRefsView(
        v4,
        const ImageWorkflowState(),
        identity,
      ).vibes!.list.single.state,
      GenVibeState.pending,
    );
    final v5 = generationRefsView(
      params.copyWith(model: ImageModels.animeDiffusionV5Full),
      const ImageWorkflowState(),
      identity,
    );
    expect(v5.vibes, isNull);
    expect(v5.precise, isNull);
    expect(params.vibeReferencesV4, [vibe]);
  });
  test('图生图开关只改请求投影，原图与蒙版留在草稿', () async {
    final notifier = container.read(generationParamsNotifierProvider.notifier);
    final bytes = Uint8List.fromList([1, 2]);
    notifier.setSourceImage(bytes);
    notifier.setMaskImage(Uint8List.fromList([3]));
    notifier.updateAction(ImageGenerationAction.infill);
    await actions.img2img(const GenImg2Img(enabled: false));
    final draft = container.read(generationParamsNotifierProvider);
    final request = container.read(generationRequestParamsProvider);
    expect(draft.sourceImage, same(bytes));
    expect(draft.maskImage, isNotNull);
    expect(request.sourceImage, isNull);
    expect(request.maskImage, isNull);
    expect(request.action, ImageGenerationAction.generate);
    await actions.img2img(const GenImg2Img(enabled: true));
    expect(
      container.read(generationRequestParamsProvider).sourceImage,
      same(bytes),
    );
    expect(
      container.read(generationRequestParamsProvider).action,
      ImageGenerationAction.infill,
    );
  });
  test('修改一个 Vibe 字段不把另一项新参数覆盖回旧值', () async {
    final notifier = container.read(generationParamsNotifierProvider.notifier);
    notifier.setVibeReferences([
      VibeReference(
        displayName: 'raw',
        vibeEncoding: '',
        rawImageData: Uint8List.fromList([1]),
      ),
    ]);
    final before = generationRefsView(
      container.read(generationParamsNotifierProvider),
      const ImageWorkflowState(),
      container.read(generationReferenceIdentityProvider),
    ).vibes!.list.single;
    notifier.updateVibeReference(0, enabled: false);
    await actions.vibe(
      GenVibe(
        id: before.id,
        name: before.name,
        thumb: before.thumb,
        strength: .4,
        info: before.info,
        enabled: before.enabled,
      ),
      previous: before,
    );
    final after = container
        .read(generationParamsNotifierProvider)
        .vibeReferencesV4
        .single;
    expect(after.strength, .4);
    expect(after.enabled, isFalse);
  });
  test('删除后旧 Vibe 回调不能修改新的同名条目', () async {
    final notifier = container.read(generationParamsNotifierProvider.notifier);
    const vibe = VibeReference(displayName: 'same', vibeEncoding: 'one');
    notifier.setVibeReferences([vibe]);
    final id = container.read(generationReferenceIdentityProvider).vibes.single;
    notifier.clearVibeReferences();
    notifier.setVibeReferences([vibe.copyWith(vibeEncoding: 'two')]);
    await expectLater(actions.removeVibe(id), throwsStateError);
    expect(
      container
          .read(generationParamsNotifierProvider)
          .vibeReferencesV4
          .single
          .vibeEncoding,
      'two',
    );
  });
  test('精准参考改类型、保真、启用，保留原图与未改的最新强度', () async {
    final notifier = container.read(generationParamsNotifierProvider.notifier);
    final bytes = Uint8List.fromList([1]);
    notifier.addPreciseReference(bytes, type: PreciseRefType.character);
    final before = generationRefsView(
      container.read(generationParamsNotifierProvider),
      const ImageWorkflowState(),
      container.read(generationReferenceIdentityProvider),
    ).precise!.list.single;
    notifier.updatePreciseReference(0, strength: .8);
    await actions.precise(
      GenPrecise(
        id: before.id,
        thumb: before.thumb,
        type: GenPreciseType.both,
        fidelity: .4,
        enabled: false,
        strength: before.strength,
      ),
      previous: before,
    );
    final after = container
        .read(generationParamsNotifierProvider)
        .preciseReferences
        .single;
    expect(after.image, same(bytes));
    expect(after.type, PreciseRefType.characterAndStyle);
    expect(after.strength, .8);
    expect(after.fidelity, .4);
    expect(after.enabled, isFalse);
  });
  test('V5 旧参考回调不改不支持的字段，模型切回仍保留条目', () async {
    final notifier = container.read(generationParamsNotifierProvider.notifier);
    notifier.setVibeReferences([
      const VibeReference(displayName: 'keep', vibeEncoding: 'one'),
    ]);
    notifier.updateModel(ImageModels.animeDiffusionV5Full);
    await actions.clearVibes();
    expect(
      container.read(generationParamsNotifierProvider).vibeReferencesV4,
      hasLength(1),
    );
  });
}
