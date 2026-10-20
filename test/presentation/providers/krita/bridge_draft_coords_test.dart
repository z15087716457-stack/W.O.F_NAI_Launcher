import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/pill_workspace_storage.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/bridge_draft_snapshot.dart';
import 'package:nai_launcher/presentation/providers/krita/bridge_draft_writer.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'agent_bridge_draft_test.dart'
    show MemoryCharacters, MemoryDraftSettings, EmptyBlocks;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ProviderContainer container;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('bridge-draft-coords-');
    Hive.init(directory.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.openBox<String>(PillWorkspaceStorage.boxName);
    final repository = MemoryCharacters()
      ..value = const CharacterPromptConfig(
        characters: [CharacterPrompt(id: 'kept', prompt: '1girl')],
      );
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(repository),
        promptBlockLibraryNotifierProvider.overrideWith(EmptyBlocks.new),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
  });
  tearDown(() async {
    container.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });
  final refProvider = Provider<Ref>((ref) => ref);

  test('自定义模式快照忽略过时的 ImageParams.useCoords=false', () {
    container
        .read(characterPromptNotifierProvider.notifier)
        .setGlobalAiChoice(false);
    container
        .read(generationParamsNotifierProvider.notifier)
        .updateUseCoords(false);

    final snapshot = readBridgeDraft(container.read(refProvider));
    expect(
      container.read(characterPromptNotifierProvider).globalAiChoice,
      false,
    );
    expect(container.read(generationParamsNotifierProvider).useCoords, false);
    expect(snapshot.fields['use_coords'], true);
  });

  test('AI 选择模式快照忽略过时的 ImageParams.useCoords=true', () {
    container
        .read(generationParamsNotifierProvider.notifier)
        .updateUseCoords(true);

    final snapshot = readBridgeDraft(container.read(refProvider));
    expect(
      container.read(characterPromptNotifierProvider).globalAiChoice,
      true,
    );
    expect(container.read(generationParamsNotifierProvider).useCoords, true);
    expect(snapshot.fields['use_coords'], false);
  });

  test('面板定位开关改变 use_coords 字段版本并使旧版本写入失效', () {
    final subscription = container.listen(
      bridgeDraftVersionProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    final params = container.read(generationParamsNotifierProvider);
    final before = readBridgeDraft(container.read(refProvider));
    final beforeVersion = container.read(bridgeDraftVersionProvider);

    container
        .read(characterPromptNotifierProvider.notifier)
        .setGlobalAiChoice(false);

    final after = readBridgeDraft(container.read(refProvider));
    expect(container.read(generationParamsNotifierProvider), params);
    expect(after.fields['use_coords'], true);
    expect(
      after.fieldVersions['use_coords'],
      isNot(before.fieldVersions['use_coords']),
    );
    expect(after.matches({'use_coords': false}, before.fieldVersions), false);
    expect(after.matches({'use_coords': false}, after.fieldVersions), true);
    expect(container.read(bridgeDraftVersionProvider), isNot(beforeVersion));
  });

  test('写入 use_coords 双向切换面板并同步参数，回读模式一致', () {
    container
        .read(characterPromptNotifierProvider.notifier)
        .setGlobalAiChoice(false);
    final writer = container.read(bridgeDraftWriterProvider);

    for (final value in [false, true]) {
      expect(writer({'use_coords': value}), ['use_coords']);
      final config = container.read(characterPromptNotifierProvider);
      expect(config.globalAiChoice, !value);
      expect(container.read(generationParamsNotifierProvider).useCoords, value);
      expect(
        readBridgeDraft(container.read(refProvider)).fields['use_coords'],
        value,
      );
      if (value) {
        expect(
          config.characters.single.positionMode,
          CharacterPositionMode.custom,
        );
        expect(config.characters.single.customPosition, isNotNull);
      }
    }
  });

  for (final useCoords in [true, false]) {
    test('联合写入 characters 与 use_coords=$useCoords 保留显式连续坐标', () {
      container
          .read(characterPromptNotifierProvider.notifier)
          .setGlobalAiChoice(useCoords);
      final characters = [
        {'id': 'kept', 'prompt': '1girl', 'x': 0.173, 'y': 0.827},
        {'id': 'added', 'prompt': '1boy', 'x': 0.912, 'y': 0.064},
      ];

      final applied = container.read(bridgeDraftWriterProvider)({
        'characters': characters,
        'use_coords': useCoords,
      });

      expect(applied, containsAll(['characters(2)', 'use_coords']));
      final config = container.read(characterPromptNotifierProvider);
      final params = container.read(generationParamsNotifierProvider);
      expect(config.globalAiChoice, !useCoords);
      expect(params.useCoords, useCoords);
      expect(
        config.characters.map(
          (c) => (c.id, c.customPosition!.column, c.customPosition!.row),
        ),
        [('kept', 0.173, 0.827), ('added', 0.912, 0.064)],
      );
      expect(params.characters.map((c) => (c.positionX, c.positionY)), [
        (0.173, 0.827),
        (0.912, 0.064),
      ]);
      final snapshot = readBridgeDraft(container.read(refProvider));
      expect(snapshot.fields['use_coords'], useCoords);
      expect(
        (snapshot.fields['characters'] as List).map(
          (c) => (c['id'], c['x'], c['y']),
        ),
        [('kept', 0.173, 0.827), ('added', 0.912, 0.064)],
      );
    });
  }
}
