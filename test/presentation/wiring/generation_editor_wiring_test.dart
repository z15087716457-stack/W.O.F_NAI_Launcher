import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/prompt_pill_editor.dart';
import 'package:nai_launcher/presentation/wiring/generation_editor_wiring.dart';
import '../providers/krita/agent_bridge_draft_test.dart'
    show MemoryCharacters, MemoryDraftSettings, EmptyBlocks;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ProviderContainer container;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('generation-editor-');
    Hive.init(directory.path);
    await Hive.openBox(StorageKeys.settingsBox);
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockLibraryNotifierProvider.overrideWith(EmptyBlocks.new),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePromptImmediately('positive original');
    container
        .read(generationParamsNotifierProvider.notifier)
        .updateNegativePromptImmediately('negative original');
  });
  tearDown(() async {
    container.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });
  Future<void> pump(
    WidgetTester tester,
    GenEditorTarget target, {
    String? characterId,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 400,
              child: GenerationEditorWiring(
                target: target,
                characterId: characterId,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('基础编辑槽只有药丸编辑区，输入同步正面参数且负面保持', (tester) async {
    await pump(tester, const GenEditorTarget.base());
    final editor = tester.widget<PromptPillEditor>(
      find.byType(PromptPillEditor),
    );
    expect(editor.config.showClearButton, isFalse);
    expect(editor.decoration!.contentPadding, EdgeInsets.zero);
    await tester.enterText(find.byType(EditableText), 'positive new');
    await tester.pump();
    await tester.pump();
    expect(
      container.read(generationParamsNotifierProvider).prompt,
      'positive new',
    );
    expect(
      container.read(generationParamsNotifierProvider).negativePrompt,
      'negative original',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('负面槽绑定独立 lane，不覆盖正面', (tester) async {
    await pump(tester, const GenEditorTarget.base(negative: true));
    expect(
      tester.widget<PromptPillEditor>(find.byType(PromptPillEditor)).pillScope,
      PillScopes.negative,
    );
    await tester.enterText(find.byType(EditableText), 'negative new');
    await tester.pump();
    await tester.pump();
    expect(
      container.read(generationParamsNotifierProvider).negativePrompt,
      'negative new',
    );
    expect(
      container.read(generationParamsNotifierProvider).prompt,
      'positive original',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('角色槽按 ID 绑定，重排后仍修改原角色的指定一面', (tester) async {
    await pump(
      tester,
      const GenEditorTarget.character(0, negative: true),
      characterId: 'kept',
    );
    final notifier = container.read(characterPromptNotifierProvider.notifier);
    notifier.addCharacter(CharacterGender.male);
    notifier.moveCharacterDown(0);
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'role negative new');
    await tester.pump();
    await tester.pump();
    final role = container
        .read(characterPromptNotifierProvider)
        .findCharacterById('kept')!;
    expect(role.negativePrompt, 'role negative new');
    expect(role.prompt, 'raw character');
    expect(role.name, 'My character');
    expect(tester.takeException(), isNull);
  });
  testWidgets('全屏编辑复用同一份文档，未找到角色不画占位编辑器', (tester) async {
    await pump(tester, const GenEditorTarget.base(fullscreen: true));
    expect(
      tester.widget<PromptPillEditor>(find.byType(PromptPillEditor)).pillScope,
      PillScopes.main,
    );
    expect(find.byType(SingleChildScrollView), findsWidgets);
    await pump(
      tester,
      const GenEditorTarget.character(0),
      characterId: 'removed',
    );
    expect(find.byType(PromptPillEditor), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
