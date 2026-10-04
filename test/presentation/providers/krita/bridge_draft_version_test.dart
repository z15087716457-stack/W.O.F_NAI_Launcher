import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/quality_preset_provider.dart';
import 'package:nai_launcher/presentation/providers/uc_preset_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/bridge_draft_snapshot.dart';
import 'agent_bridge_draft_test.dart'
    show MemoryCharacters, MemoryDraftSettings;

class TestBlocks extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async => PromptBlockLibraryState(
    blocks: [
      PromptBlock(
        id: 'quality',
        title: 'Quality',
        content: 'custom quality',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ],
    folders: [],
  );
  void changeContent(String content) {
    state = AsyncData(
      PromptBlockLibraryState(
        blocks: [
          PromptBlock(
            id: 'quality',
            title: 'Quality',
            content: 'custom quality',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ).copyWith(content: content),
        ],
        folders: [],
      ),
    );
  }

  @override
  Future<void> incrementUseCount(String blockId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('确认版本观察参数、角色、等价译块、预设和参考；撤销不恢复；不创建未打开lane', () async {
    final directory = await Directory.systemTemp.createTemp(
      'bridge-version-test-',
    );
    Hive.init(directory.path);
    await Hive.openBox(StorageKeys.settingsBox);
    final container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockLibraryNotifierProvider.overrideWith(TestBlocks.new),
      ],
    );
    try {
      await container.read(promptBlockLibraryNotifierProvider.future);
      String version() => container.read(bridgeDraftVersionProvider);
      var previous = version();
      final subscription = container.listen(
        bridgeDraftVersionProvider,
        (_, _) {},
      );
      expect(container.exists(pillWorkspaceProvider(PillScopes.main)), isFalse);
      expect(
        container.exists(pillWorkspaceProvider(PillScopes.charNeg('kept'))),
        isFalse,
      );
      void changed(void Function() edit) {
        edit();
        final next = version();
        expect(next, isNot(previous));
        previous = next;
      }

      final params = container.read(generationParamsNotifierProvider.notifier);
      final originalSteps = container
          .read(generationParamsNotifierProvider)
          .steps;
      final initial = previous;
      changed(() => params.updateSteps(originalSteps + 1));
      changed(() => params.updateSteps(originalSteps));
      expect(previous, isNot(initial));
      final beforeCosmetic = previous;
      await params.setAdvancedOptionsExpanded(false);
      expect(version(), beforeCosmetic);
      changed(() => params.updatePromptImmediately('scenery'));
      changed(() => params.updateNegativePromptImmediately('text'));
      changed(() => params.setSourceImage(Uint8List.fromList([1, 2, 3])));
      changed(
        () =>
            container.read(autoFormatPromptSettingsProvider.notifier).toggle(),
      );
      changed(
        () => container
            .read(sdSyntaxAutoConvertSettingsProvider.notifier)
            .toggle(),
      );
      final role = container
          .read(characterPromptNotifierProvider)
          .characters
          .single;
      changed(
        () => container
            .read(characterPromptNotifierProvider.notifier)
            .updateCharacter(role.copyWith(enabled: true)),
      );
      final lane = container.read(
        pillWorkspaceProvider(PillScopes.main).notifier,
      );
      // Same generation text, but a new reusable translation document.
      lane.syncFromPlainText('');
      params.updatePromptImmediately('');
      previous = version();
      changed(
        () => lane.insertTranslationAt(offset: 0, source: '', zh: '显示翻译'),
      );
      final marker = container
          .read(pillWorkspaceProvider(PillScopes.main))
          .document
          .instances
          .keys
          .single;
      final translation = container
          .read(pillWorkspaceProvider(PillScopes.main))
          .document
          .instances[marker]!
          .translation!;
      changed(
        () =>
            lane.updateTranslation(marker, translation.copyWith(zh: '另一种显示翻译')),
      );
      changed(
        () => container
            .read(qualityPresetNotifierProvider.notifier)
            .setCustomEntry('quality'),
      );
      changed(
        () =>
            (container.read(promptBlockLibraryNotifierProvider.notifier)
                    as TestBlocks)
                .changeContent('edited quality'),
      );
      changed(
        () => container
            .read(ucPresetNotifierProvider.notifier)
            .setPresetType(UcPresetType.none),
      );
      subscription.close();
    } finally {
      container.dispose();
      await Hive.close();
      await directory.delete(recursive: true);
    }
  });
}
