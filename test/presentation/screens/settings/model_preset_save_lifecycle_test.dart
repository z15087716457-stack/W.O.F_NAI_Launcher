import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_task_definitions.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/model_draft_save_controller.dart';
import 'package:nai_launcher/presentation/screens/settings/widgets/model_preset_editor.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_dialogs.dart';

import 'model_management_section_test.dart' show MemorySettings, MemorySecrets;

class _DelayedStorage extends MemorySettings {
  Completer<void>? gate;
  String? submitted;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    if (key == StorageKeys.promptAssistantConfigJson && gate != null) {
      submitted = value as String;
      await gate!.future;
    }
    await super.setSetting(key, value);
  }
}

void main() {
  const preset = TaskPresetConfig(
    id: 'fixture-preset',
    name: 'fixture',
    task: LauncherInterface.translate,
    prompt: 'initial',
  );
  late _DelayedStorage storage;
  late ModelDraftSaveController saveController;
  Future<void> open(WidgetTester tester, {bool fresh = false}) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    storage = _DelayedStorage();
    addTearDown(() {
      if (storage.gate != null && !storage.gate!.isCompleted) {
        storage.gate!.complete();
      }
    });
    storage.values[StorageKeys.promptAssistantConfigJson] =
        PromptAssistantConfigState.defaults()
            .copyWith(presets: fresh ? [] : [preset])
            .encode();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storage),
          secureStorageServiceProvider.overrideWithValue(MemorySecrets()),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showSettingsEditor(context, (dialog, dirty, saved, save) {
                      saveController = save;
                      return ModelPresetEditor(
                        preset: preset,
                        onDirtyChanged: dirty,
                        onSaved: saved,
                        onCreate: (_) {},
                        saveController: save,
                      );
                    }),
                child: const Text('Open fixture editor'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open fixture editor'));
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String key, String text) async {
    final field = find.byKey(Key(key));
    await tester.ensureVisible(field);
    await tester.enterText(field, text);
    await tester.pump();
  }

  Future<void> clickSave(WidgetTester tester) async {
    final button = find.byKey(const Key('preset-save'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
  }

  TaskPresetConfig persisted() => PromptAssistantConfigState.decode(
    storage.values[StorageKeys.promptAssistantConfigJson] as String,
  ).presets.single;
  void release() {
    storage.gate!.complete();
    storage.gate = null;
  }

  for (final fresh in [false, true]) {
    for (final field in ['preset-prompt', 'preset-name']) {
      testWidgets(
        'later $field draft stays open and can be saved again, fresh=$fresh',
        (tester) async {
          await open(tester, fresh: fresh);
          await enter(tester, 'preset-prompt', 'saved-A');
          storage.gate = Completer<void>();
          await clickSave(tester);
          expect(storage.submitted, isNotNull);
          await enter(tester, field, 'new-unsaved-B');
          release();
          await tester.pumpAndSettle();
          expect(find.byType(ModelPresetEditor), findsOneWidget);
          expect(
            tester
                .widget<TextFormField>(find.byKey(Key(field)))
                .controller!
                .text,
            'new-unsaved-B',
          );
          expect(persisted().prompt, 'saved-A');
          expect(persisted().name, 'fixture');
          await clickSave(tester);
          await tester.pumpAndSettle();
          expect(find.byType(ModelPresetEditor), findsNothing);
          expect(
            field == 'preset-name' ? persisted().name : persisted().prompt,
            'new-unsaved-B',
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('restore default during save is kept as a later draft', (
    tester,
  ) async {
    await open(tester);
    await enter(tester, 'preset-prompt', 'saved-A');
    storage.gate = Completer<void>();
    await clickSave(tester);
    final labels = AppLocalizations.of(
      tester.element(find.byType(ModelPresetEditor)),
    )!;
    final restore = find.text(labels.modelPreset_restoreStrategy);
    await tester.ensureVisible(restore);
    await tester.tap(restore);
    await tester.pump();
    release();
    await tester.pumpAndSettle();
    expect(find.byType(ModelPresetEditor), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('preset-prompt')))
          .controller!
          .text,
      preset.task.builtinPrompt,
    );
    expect(persisted().prompt, 'saved-A');
  });
  testWidgets('navigation save reports false while a later draft remains', (
    tester,
  ) async {
    await open(tester);
    await enter(tester, 'preset-prompt', 'saved-A');
    storage.gate = Completer<void>();
    final saving = saveController.save();
    await tester.pump();
    await enter(tester, 'preset-prompt', 'new-unsaved-B');
    release();
    await tester.pumpAndSettle();
    expect(await saving, isFalse);
    expect(find.byType(ModelPresetEditor), findsOneWidget);
  });
  testWidgets('unchanged submission still saves and closes normally', (
    tester,
  ) async {
    await open(tester);
    await enter(tester, 'preset-prompt', 'saved-A');
    await clickSave(tester);
    await tester.pumpAndSettle();
    expect(find.byType(ModelPresetEditor), findsNothing);
    expect(persisted().prompt, 'saved-A');
  });
}
