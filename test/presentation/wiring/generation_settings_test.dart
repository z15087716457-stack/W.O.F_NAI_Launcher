import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/enums/quality_tag_preset.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/models/image/image_params.dart'
    show ImageParamsExtension;
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/layout_state_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/quality_preset_provider.dart';
import 'package:nai_launcher/presentation/providers/uc_preset_provider.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/wiring/generation_backend.dart';
import 'package:nai_launcher/presentation/wiring/generation_settings.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
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
  late ProviderContainer container;
  late Directory directory;
  late GenerationSettings settings;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('generation-settings-');
    Hive.init(directory.path);
    await Hive.openBox(StorageKeys.settingsBox);
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        imageGenerationNotifierProvider.overrideWith(IdleGeneration.new),
        authNotifierProvider.overrideWith(OfflineAuth.new),
        promptBlockLibraryNotifierProvider.overrideWith(EmptyBlocks.new),
        generationPlatformProvider.overrideWithValue(
          MemoryGenerationPlatform(),
        ),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
    settings = container.read(generationSettingsProvider);
  });
  tearDown(() async {
    container.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });
  test(
    'Turbo toggles preserve Full settings, negative draft and saved defaults',
    () async {
      await settings.model(ImageModels.animeDiffusionV5Full);
      final notifier = container.read(
        generationParamsNotifierProvider.notifier,
      );
      notifier.updateSteps(37);
      notifier.updateSampler(Samplers.kDpmpp2m);
      notifier.updateCfgRescale(.65);
      notifier.updateNegativePromptImmediately('keep my negative');
      notifier.updateSeed(99);
      await settings.uc('light');
      final before = container.read(generationParamsNotifierProvider);
      final settingsBefore = Map.of(
        (container.read(localStorageServiceProvider) as MemoryDraftSettings)
            .values,
      );
      for (var i = 0; i < 3; i++) {
        await settings.turbo(true);
        final raw = container.read(generationParamsNotifierProvider);
        expect(raw.model, ImageModels.animeDiffusionV5FullMedium);
        expect(raw.copyWith(model: before.model), before);
        final request = container.read(generationRequestParamsProvider);
        expect(request.steps, 14);
        expect(request.sampler, Samplers.kEulerAncestral);
        expect(request.cfgRescale, 0);
        expect(request.ucPreset, 0);
        expect(request.negativePrompt, isEmpty);
        await settings.param(GenParam.steps, 50);
        await settings.param(GenParam.cfgRescale, .8);
        await settings.sampler(Samplers.kEulerAncestral);
        await settings.uc('heavy');
        expect(container.read(generationParamsNotifierProvider), raw);
        await settings.turbo(false);
        expect(container.read(generationParamsNotifierProvider), before);
      }
      expect(
        (container.read(localStorageServiceProvider) as MemoryDraftSettings)
            .values,
        settingsBefore,
      );
    },
  );

  test('Turbo is unavailable for Curated and other families', () async {
    for (final model in [
      ImageModels.animeDiffusionV5Curated,
      ImageModels.animeDiffusionV45Full,
    ]) {
      await settings.model(model);
      final before = container.read(generationParamsNotifierProvider);
      await settings.turbo(true);
      expect(container.read(generationParamsNotifierProvider), before);
    }
  });
  test(
    'a restart in Turbo keeps Full defaults available for switching back',
    () async {
      await settings.model(ImageModels.animeDiffusionV5Full);
      final notifier = container.read(
        generationParamsNotifierProvider.notifier,
      );
      notifier.updateSteps(37);
      notifier.updateSampler(Samplers.kDpmpp2m);
      notifier.updateCfgRescale(.65);
      notifier.updateNegativePromptImmediately('persistent negative');
      await settings.turbo(true);
      final storage = container.read(localStorageServiceProvider);
      final restarted = ProviderContainer(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
      );
      addTearDown(restarted.dispose);
      final restored = restarted.read(generationParamsNotifierProvider);
      expect(restored.model, ImageModels.animeDiffusionV5FullMedium);
      expect(restored.steps, 37);
      expect(restored.sampler, Samplers.kDpmpp2m);
      expect(restored.cfgRescale, .65);
      expect(restored.negativePrompt, 'persistent negative');
      expect(restored.constrainedForModel.steps, 14);
      restarted
          .read(generationParamsNotifierProvider.notifier)
          .updateModel(ImageModels.animeDiffusionV5Full);
      final full = restarted.read(generationParamsNotifierProvider);
      expect(full.copyWith(model: restored.model), restored);
    },
  );
  test('切模型保留提示词与种子，迁移不支持的采样器', () async {
    final notifier = container.read(generationParamsNotifierProvider.notifier);
    notifier.updatePromptImmediately('keep prompt');
    notifier.updateSeed(17);
    notifier.updateSampler(Samplers.kDpmppSde);
    await settings.model('nai-diffusion-5-full');
    final params = container.read(generationParamsNotifierProvider);
    expect(params.prompt, 'keep prompt');
    expect(params.seed, 17);
    expect(params.sampler, Samplers.kEulerAncestral);
  });
  test('尺寸按 64 归整且有界，非有限参数不进入备份', () async {
    await settings.size(801, 9000);
    final params = container.read(generationParamsNotifierProvider);
    expect(params.width, 832);
    expect(params.height, 4096);
    expect(
      () => settings.param(GenParam.scale, double.nan),
      throwsFormatException,
    );
  });
  test('每次张数与重复次数分别更新，恢复单张不改变重复次数', () async {
    await settings.count(3);
    await settings.repeat(7);
    expect(container.read(imagesPerRequestProvider), 3);
    expect(container.read(generationParamsNotifierProvider).nSamples, 7);
    await settings.count(1);
    expect(container.read(generationParamsNotifierProvider).nSamples, 7);
  });
  test('重复次数保留超过 99 的既有值，减一不跳回 99', () async {
    container
        .read(generationParamsNotifierProvider.notifier)
        .updateNSamples(180);
    await settings.repeat(179);
    expect(container.read(generationParamsNotifierProvider).nSamples, 179);
  });
  test('旧 Furry 的陈旧 V3 控件回调不改参数', () async {
    await settings.model(ImageModels.furryDiffusion);
    final before = container.read(generationParamsNotifierProvider);
    await settings.decrisp(!before.decrisp);
    await settings.smea(
      GenSmea(auto: !before.smeaAuto, smea: !before.smea, dyn: !before.smeaDyn),
    );
    expect(container.read(generationParamsNotifierProvider), before);
  });
  test('固定种子优先上次实际值，取消固定恢复随机', () async {
    await settings.pinSeed(true, lastSeed: 23);
    expect(container.read(generationParamsNotifierProvider).seed, 23);
    await settings.pinSeed(false);
    expect(container.read(generationParamsNotifierProvider).seed, -1);
    await settings.seed(31);
    expect(container.read(generationParamsNotifierProvider).seed, 31);
  });
  test('质量词与 UC 选择同步原生参数和权威预设状态', () async {
    await settings.quality('light');
    expect(
      container
          .read(generationParamsNotifierProvider)
          .effectiveQualityTagPreset,
      QualityTagPreset.light,
    );
    expect(
      container.read(qualityPresetNotifierProvider).nativePreset,
      QualityTagPreset.light,
    );
    await settings.uc('none');
    expect(
      container.read(ucPresetNotifierProvider).presetType,
      UcPresetType.none,
    );
    expect(
      container.read(generationParamsNotifierProvider).ucPreset,
      UcPresets.toApiValue(UcPresetType.none),
    );
  });
  test('不支持的控件回调不会写入隐藏的模型参数', () async {
    await settings.model('nai-diffusion-5-full');
    final before = container.read(generationParamsNotifierProvider);
    await settings.variety(!before.varietyPlus);
    await settings.smea(
      GenSmea(auto: !before.smeaAuto, smea: !before.smea, dyn: !before.smeaDyn),
    );
    await settings.noise(
      before.noiseSchedule == 'native' ? 'karras' : 'native',
    );
    expect(container.read(generationParamsNotifierProvider), before);
  });
  test('角色修改按 ID 定位，保留最新提示词与缩略图', () async {
    final notifier = container.read(characterPromptNotifierProvider.notifier);
    final old = container
        .read(characterPromptNotifierProvider)
        .characters
        .single;
    notifier.updateCharacter(old.copyWith(prompt: 'latest prompt'));
    await settings.renameCharacter(old.id, ' Renamed ');
    final current = container
        .read(characterPromptNotifierProvider)
        .characters
        .single;
    expect(current.name, 'Renamed');
    expect(current.nameIsCustom, isTrue);
    expect(current.prompt, 'latest prompt');
    expect(current.thumbnailPath, 'local-thumbnail');
    await settings.renameCharacter(old.id, '');
    expect(
      container.read(characterPromptNotifierProvider).characters.single.name,
      '',
    );
  });
  test('角色不存在时不能修改新占据相同索引的角色', () async {
    container.read(characterPromptNotifierProvider.notifier).clearAll();
    await expectLater(
      settings.renameCharacter('kept', 'wrong'),
      throwsStateError,
    );
    expect(container.read(characterPromptNotifierProvider).characters, isEmpty);
  });
  test('角色移动按当前 ID 顺序，向下移动不丢失任何元信息', () async {
    await settings.addCharacter(GenGender.male);
    await settings.moveCharacter('kept', 1);
    final characters = container
        .read(characterPromptNotifierProvider)
        .characters;
    expect(characters.last.id, 'kept');
    expect(characters.last.negativePrompt, 'raw uc');
    expect(characters.first.gender.name, 'male');
  });
  test('V4.5 定位吸附网格，V5 保留连续坐标', () async {
    await settings.model('nai-diffusion-4-5-full');
    await settings.characterPosition('kept', const Offset(.44, .66));
    var role = container
        .read(characterPromptNotifierProvider)
        .characters
        .single;
    expect(role.customPosition!.column, .5);
    expect(role.customPosition!.row, closeTo(.7, .00001));
    await settings.model('nai-diffusion-5-full');
    await settings.characterPosition('kept', const Offset(.44, .66));
    role = container.read(characterPromptNotifierProvider).characters.single;
    expect(role.customPosition!.column, .44);
    expect(role.customPosition!.row, .66);
    expect(role.prompt, 'raw character');
  });
  test('V3 不允许新增角色，模型实际上限仍生效', () async {
    await settings.model('nai-diffusion-3');
    await settings.addCharacter(GenGender.other);
    expect(
      container.read(characterPromptNotifierProvider).characters.length,
      1,
    );
  });
  test('布局只写本次变更字段，不覆盖稍后的另一栏设置', () async {
    final before = generationLayoutView(
      container.read(layoutStateNotifierProvider),
    );
    await container
        .read(layoutStateNotifierProvider.notifier)
        .setRightPanelExpanded(false);
    await settings.layout(before.copyWith(leftWidth: 500), previous: before);
    expect(container.read(layoutStateNotifierProvider).webLeftPanelWidth, 500);
    expect(
      container.read(layoutStateNotifierProvider).rightPanelExpanded,
      isFalse,
    );
    container.invalidate(layoutStateNotifierProvider);
    expect(container.read(layoutStateNotifierProvider).webLeftPanelWidth, 500);
    expect(
      container.read(layoutStateNotifierProvider).rightPanelExpanded,
      isFalse,
    );
  });
  test('提示词菜单写入真实偏好，不用切换法模拟显式值', () async {
    await settings.promptTool(GenPromptTool.autoFormat, false);
    await settings.promptTool(GenPromptTool.translatePinned, false);
    await settings.promptTool(GenPromptTool.translatePinned, false);
    await settings.promptTool(GenPromptTool.agentPinned, false);
    await settings.promptTool(GenPromptTool.agentPinned, false);
    expect(container.read(autoFormatPromptSettingsProvider), isFalse);
    expect(
      container.read(layoutStateNotifierProvider).translationToolPinned,
      isFalse,
    );
    container.invalidate(layoutStateNotifierProvider);
    expect(
      container.read(layoutStateNotifierProvider).naiAgentToolPinned,
      isFalse,
    );
    await settings.promptTool(GenPromptTool.agentPinned, true);
    container.invalidate(layoutStateNotifierProvider);
    expect(
      container.read(layoutStateNotifierProvider).naiAgentToolPinned,
      isTrue,
    );
  });
}
