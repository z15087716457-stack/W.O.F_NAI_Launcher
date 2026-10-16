import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nai_launcher/core/constants/api_constants.dart' as api;
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/enums/quality_tag_preset.dart';
import 'package:nai_launcher/core/services/prompt_token_counter_service.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/models/prompt/prompt_preset_mode.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_token_counter_provider.dart';
import 'package:nai_launcher/presentation/providers/quality_preset_provider.dart';
import 'package:nai_launcher/presentation/providers/uc_preset_provider.dart';
import 'package:nai_launcher/presentation/utils/prompt_preset_import_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveTempDir;

  setUpAll(() async {
    hiveTempDir = await Directory.systemTemp.createTemp(
      'prompt_token_counter_provider_test_',
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

  tearDown(() async {
    await Hive.box(StorageKeys.settingsBox).clear();
    _FakePromptTokenEncoder.callCount = 0;
  });

  group('buildPromptTokenCountPayload', () {
    test(
      'positive payload should include request-aligned quality tags and raw enabled character prompts only',
      () {
        final payload = buildPromptTokenCountPayload(
          target: PromptTokenCountTarget.positive,
          prompt: '<hero>',
          negativePrompt: '<bad>',
          model: 'nai-diffusion-4-5-full',
          qualityToggle: true,
          ucPreset: api.UcPresets.toApiValue(api.UcPresetType.heavy),
          characters: [
            CharacterPrompt.create(name: 'A', prompt: '<dress>'),
            CharacterPrompt.create(
              name: 'Positioned',
              prompt: '<cape>',
            ).copyWith(
              positionMode: CharacterPositionMode.custom,
              customPosition: const CharacterPosition(row: 0.0, column: 1.0),
            ),
            CharacterPrompt.create(
              name: 'B',
              prompt: 'ignored',
            ).copyWith(enabled: false),
            CharacterPrompt.create(name: 'C', prompt: ''),
          ],
          resolveAliases: _resolveAliases,
        );

        expect(
          payload.mainText,
          equals('1girl, location, very aesthetic, masterpiece, no text'),
        );
        expect(payload.extraTexts, equals(['blue dress', 'red cape']));
        expect(
          payload.breakdown.map((item) => item.label).toList(),
          equals(['提示词', '质量预设', '角色']),
        );
      },
    );

    test('positive payload should count the V5 Light quality text', () {
      final payload = buildPromptTokenCountPayload(
        target: PromptTokenCountTarget.positive,
        prompt: '1girl',
        negativePrompt: '',
        model: api.ImageModels.animeDiffusionV5Full,
        qualityToggle: true,
        qualityTagPreset: QualityTagPreset.light,
        ucPreset: api.UcPresets.noneApiValue,
        qualityMode: PromptPresetMode.naiLight,
        qualityContent: api.QualityTags.v5Light,
        characters: const [],
        resolveAliases: (text) => text,
      );

      expect(
        payload.mainText,
        '1girl, very aesthetic, amazing quality, no text',
      );
      expect(
        payload.breakdown.singleWhere((item) => item.label == '质量预设').texts,
        [api.QualityTags.v5Light],
      );
    });

    test(
      'negative payload should include request-aligned uc preset, negative prompt and character negatives',
      () {
        final payload = buildPromptTokenCountPayload(
          target: PromptTokenCountTarget.negative,
          prompt: '<hero>',
          negativePrompt: '<bad>',
          model: 'nai-diffusion-4-5-full',
          qualityToggle: true,
          ucPreset: api.UcPresets.toApiValue(api.UcPresetType.light),
          characters: [
            CharacterPrompt.create(
              name: 'A',
              prompt: '1girl',
              negativePrompt: '<charBad>',
            ),
            CharacterPrompt.create(
              name: 'B',
              prompt: '1boy',
              negativePrompt: 'ignored',
            ).copyWith(enabled: false),
          ],
          resolveAliases: _resolveAliases,
        );

        expect(
          payload.mainText,
          equals(
            'lowres, artistic error, scan artifacts, worst quality, bad quality, jpeg artifacts, multiple views, very displeasing, too many watermarks, negative space, blank page, bad hands',
          ),
        );
        expect(payload.extraTexts, equals(['extra fingers']));
        expect(
          payload.breakdown.map((item) => item.label).toList(),
          equals(['负面提示词', '负面预设', '角色负面']),
        );
      },
    );
  });

  group('metadata prompt preset import', () {
    test('should apply imported preset fields to the new providers', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      applyImportedQualityToggle(container.read, false);
      applyImportedUcPreset(
        container.read,
        api.UcPresets.toApiValue(api.UcPresetType.humanFocus),
      );

      expect(
        container.read(qualityPresetNotifierProvider).mode,
        PromptPresetMode.none,
      );
      expect(
        container.read(ucPresetNotifierProvider).presetType,
        api.UcPresetType.humanFocus,
      );

      applyImportedQualityToggle(container.read, true);
      applyImportedUcPreset(container.read, api.UCPresets.furryFocus);

      expect(
        container.read(qualityPresetNotifierProvider).mode,
        PromptPresetMode.naiDefault,
      );
      expect(
        container.read(ucPresetNotifierProvider).presetType,
        api.UcPresetType.furryFocus,
      );
    });
  });

  test('vibe 参数变化不会触发 token 计数重新计算', () async {
    _FakePromptTokenEncoder.callCount = 0;
    final service = PromptTokenCounterService(
      encoder: _FakePromptTokenEncoder(),
    );
    final container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWith((ref) {
          return _TestLocalStorageService();
        }),
        promptTokenCounterServiceProvider.overrideWith((ref) async => service),
        // token 计数现在 watch 块库（别名展开跟随块库变化）；
        // 用 fake 挡住真实 Hive box，避免异步开 box 与 tearDown 删目录竞争。
        promptBlockLibraryNotifierProvider.overrideWith(
          () => _FakePromptBlockLibraryNotifier(
            PromptBlockLibraryState(blocks: const [], folders: const []),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    // 先等块库就绪，避免 usage provider 在计算途中被依赖重建打断。
    await container.read(promptBlockLibraryNotifierProvider.future);
    await container.read(
      promptTokenUsageProvider(PromptTokenCountTarget.positive).future,
    );
    final initialCallCount = _FakePromptTokenEncoder.callCount;

    container
        .read(generationParamsNotifierProvider.notifier)
        .addVibeReference(
          const VibeReference(
            displayName: 'vibe',
            vibeEncoding: 'encoded',
            strength: 0.6,
            infoExtracted: 0.7,
            sourceType: VibeSourceType.naiv4vibe,
          ),
        );
    await Future<void>.delayed(Duration.zero);

    expect(_FakePromptTokenEncoder.callCount, initialCallCount);
  });

  test(
    'unchanged lane reuses usage while cross-lane preset semantics still refresh',
    () async {
      final container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWith(
            (ref) => _TestLocalStorageService(),
          ),
          promptTokenCounterServiceProvider.overrideWith(
            (ref) async =>
                PromptTokenCounterService(encoder: _FakePromptTokenEncoder()),
          ),
          promptBlockLibraryNotifierProvider.overrideWith(
            () => _FakePromptBlockLibraryNotifier(
              PromptBlockLibraryState(blocks: const [], folders: const []),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(promptBlockLibraryNotifierProvider.future);
      container
          .read(ucPresetNotifierProvider.notifier)
          .setPresetType(api.UcPresetType.none);
      final params = container.read(generationParamsNotifierProvider.notifier);
      params.updateNegativePromptImmediately('nsfw, bad hands');
      const target = PromptTokenCountTarget.negative;
      final first = container.read(promptTokenUsageProvider(target).future);
      await first;
      final calls = _FakePromptTokenEncoder.callCount;
      params.updatePromptImmediately('blue sky');
      final unchanged = container.read(promptTokenUsageProvider(target).future);
      expect(identical(unchanged, first), isTrue);
      await unchanged;
      expect(_FakePromptTokenEncoder.callCount, calls);
      expect(
        container.read(promptTokenPayloadProvider(target)).mainText,
        contains('nsfw'),
      );
      params.updatePromptImmediately('nsfw, blue sky');
      final changed = container.read(promptTokenUsageProvider(target).future);
      expect(identical(changed, first), isFalse);
      await changed;
      expect(
        container.read(promptTokenPayloadProvider(target)).mainText,
        isNot(contains('nsfw')),
      );
      expect(_FakePromptTokenEncoder.callCount, greaterThan(calls));
    },
  );
}

String _resolveAliases(String text) {
  return text
      .replaceAll('<hero>', '1girl')
      .replaceAll('<dress>', 'blue dress')
      .replaceAll('<cape>', 'red cape')
      .replaceAll('<bad>', 'bad hands')
      .replaceAll('<charBad>', 'extra fingers');
}

class _FakePromptBlockLibraryNotifier extends PromptBlockLibraryNotifier {
  _FakePromptBlockLibraryNotifier(this.initialState);

  final PromptBlockLibraryState initialState;

  @override
  Future<PromptBlockLibraryState> build() async => initialState;
}

class _FakePromptTokenEncoder implements PromptTokenEncoder {
  static int callCount = 0;

  @override
  Future<int> countTokens(String text) async {
    callCount++;
    return text.isEmpty ? 0 : 1;
  }
}

class _TestLocalStorageService extends LocalStorageService {
  @override
  String getLastPrompt() => '1girl';

  @override
  String getLastNegativePrompt() => 'bad hands';

  @override
  String getDefaultModel() => 'nai-diffusion-4-5-full';

  @override
  String getDefaultSampler() => 'k_euler_ancestral';

  @override
  int getDefaultSteps() => 28;

  @override
  double getDefaultScale() => 5.0;

  @override
  int getDefaultWidth() => 832;

  @override
  int getDefaultHeight() => 1216;

  @override
  bool getLastSmea() => false;

  @override
  bool getLastSmeaDyn() => false;

  @override
  double getLastCfgRescale() => 0.0;

  @override
  String getLastNoiseSchedule() => 'native';
}
