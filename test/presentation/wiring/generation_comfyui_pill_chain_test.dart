import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/tips_provider.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_input.dart';
import 'package:nai_launcher/presentation/widgets/prompt/comfyui_import_dialog.dart';
import 'package:nai_launcher/presentation/widgets/prompt/comfyui_import_wrapper.dart';
import 'package:nai_launcher/presentation/wiring/generation_editor_wiring.dart';
import '../providers/krita/agent_bridge_draft_test.dart'
    show MemoryCharacters, MemoryDraftSettings, EmptyBlocks;
import 'generation_comfyui_import_test.dart' as control;
import '../ui/refs/refs_test_harness.dart' show refsApp;
import '../../helpers/studio_capture_fonts.dart';
import '../../helpers/app_logger_test_isolation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ProviderContainer container;
  var begins = 0, commits = 0;
  setUpAll(() async {
    AppLoggerTestIsolation.setUp();
    await loadStudioCaptureFonts();
  });
  tearDownAll(AppLoggerTestIsolation.tearDown);
  setUp(() async {
    begins = 0;
    commits = 0;
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('audit-comfy-chain-');
    Hive.init(directory.path);
    await Hive.openBox(StorageKeys.settingsBox);
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockLibraryNotifierProvider.overrideWith(EmptyBlocks.new),
        tipEpochProvider.overrideWith((ref) => Stream<int>.value(0)),
        generationEditorImportProvider.overrideWithValue((alive) {
          begins++;
          return (prompt, characters) async {
            commits++;
            container
                .read(generationParamsNotifierProvider.notifier)
                .updatePromptImmediately(prompt);
            container
                .read(characterPromptNotifierProvider.notifier)
                .replaceAll(characters);
          };
        }),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
  });
  tearDown(() async {
    container.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });
  for (final scenario in [
    'confirm',
    'cancel',
    'new text',
    'plain text',
    'negative field',
  ]) {
    testWidgets('pill editor ComfyUI import handles $scenario', (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(1200, 900);
      addTearDown(t.view.reset);
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: refsApp(
            SizedBox(
              width: 450,
              height: 400,
              child: GenerationEditorWiring(
                target: GenEditorTarget.base(
                  negative: scenario == 'negative field',
                ),
              ),
            ),
          ),
        ),
      );
      await t.pump();
      await t.pump();
      final input = t.widget<UnifiedPromptInput>(
        find.byType(UnifiedPromptInput),
      );
      if (scenario != 'negative field') {
        expect(input.beginComfyuiImport, isNotNull);
        expect(find.byType(ComfyuiImportWrapper), findsOneWidget);
      }
      final text = scenario == 'plain text'
          ? 'a normal prompt, scenery, blue sky'
          : control.source;
      await t.enterText(find.byType(EditableText).first, text);
      await t.pumpAndSettle();
      if (scenario == 'plain text' || scenario == 'negative field') {
        expect(find.byType(ComfyuiImportDialog), findsNothing);
        expect(begins, 0);
      } else {
        expect(find.byType(ComfyuiImportDialog), findsOneWidget);
        expect(begins, 1);
        if (scenario == 'new text') {
          input.controller!.text = 'newer user draft';
          await t.pump();
        }
        if (scenario == 'cancel') {
          await t.tap(find.widgetWithText(TextButton, '取消'));
        } else {
          await t.tap(find.byType(FilledButton));
        }
        await t.pumpAndSettle();
        expect(commits, scenario == 'confirm' ? 1 : 0);
        if (scenario == 'confirm') {
          expect(
            container.read(characterPromptNotifierProvider).characters,
            hasLength(2),
          );
          expect(input.controller!.text, 'global scenery, detailed background');
        } else {
          expect(
            input.controller!.text,
            scenario == 'new text' ? 'newer user draft' : control.source,
          );
        }
      }
      await t.pumpWidget(const SizedBox());
      expect(t.takeException(), isNull);
    });
  }
}
