import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/enums/precise_ref_type.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/providers/tips_provider.dart';
import 'package:nai_launcher/presentation/wiring/generation_backend.dart';
import 'package:nai_launcher/presentation/wiring/generation_wiring.dart';
import '../../helpers/app_logger_test_isolation.dart';
import '../providers/krita/agent_bridge_draft_test.dart'
    show MemoryCharacters, MemoryDraftSettings, EmptyBlocks, OfflineAuth;
import 'generation_backend_test.dart' show MemoryGenerationPlatform;
import 'generation_data_wiring_test.dart'
    show DataGeneration, DataSubscription, DataShortcuts;
import 'generation_reference_imports_test.dart' show ImportStorage;

class StartupReferences extends ImportStorage {
  Completer<String?>? pending;
  int loads = 0;
  final saved = Completer<void>();
  @override
  Future<String?> loadGenerationStateJson() {
    loads++;
    return pending?.future ?? super.loadGenerationStateJson();
  }

  @override
  Future<void> saveGenerationStateJson(String value) async {
    await super.saveGenerationStateJson(value);
    if (!saved.isCompleted) saved.complete();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late Directory directory;
  late StartupReferences storage;
  late ProviderContainer container;
  late GenerationParamsNotifier notifier;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp(
      'generation_startup_refs_',
    );
    Hive.init(directory.path);
    await Hive.openBox(StorageKeys.settingsBox);
    storage = StartupReferences()
      ..generationJson = jsonEncode({
        'vibeReferences': [
          {
            'displayName': 'saved-vibe',
            'vibeEncoding': 'encoding',
            'strength': 0.4,
            'infoExtracted': 0.2,
            'enabled': false,
          },
        ],
        'preciseReferences': [
          {
            'imageBase64': 'AQID',
            'type': 'style',
            'strength': 0.3,
            'fidelity': 0.7,
            'enabled': false,
          },
        ],
        'normalizeVibeStrength': false,
      });
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockLibraryNotifierProvider.overrideWith(EmptyBlocks.new),
        authNotifierProvider.overrideWith(OfflineAuth.new),
        imageGenerationNotifierProvider.overrideWith(DataGeneration.new),
        subscriptionNotifierProvider.overrideWith(DataSubscription.new),
        tipEpochProvider.overrideWith((ref) => Stream.value(0)),
        shortcutConfigNotifierProvider.overrideWith(DataShortcuts.new),
        generationPlatformProvider.overrideWithValue(
          MemoryGenerationPlatform(),
        ),
        vibeLibraryStorageServiceProvider.overrideWithValue(storage),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
    notifier = container.read(generationParamsNotifierProvider.notifier);
  });
  tearDown(() async {
    container.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });
  testWidgets('current generation wiring restores saved references once', (
    tester,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: GenerationWiring(
            builder: ({required data, required actions, required slots}) =>
                const SizedBox(),
          ),
        ),
      ),
    );
    expect(storage.loads, 1);
    for (var i = 0; i < 10 && !storage.saved.isCompleted; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 1));
    }
    final state = container.read(generationParamsNotifierProvider);
    expect(state.vibeReferencesV4.single.displayName, 'saved-vibe');
    expect(state.vibeReferencesV4.single.enabled, isFalse);
    expect(state.vibeReferencesV4.single.strength, 0.4);
    expect(state.preciseReferences.single.image, [1, 2, 3]);
    expect(state.preciseReferences.single.type, PreciseRefType.style);
    expect(state.preciseReferences.single.enabled, isFalse);
    expect(state.normalizeVibeStrength, isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(notifier.restoreGenerationState);
    expect(storage.loads, 1);
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 1));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
    }
    await tester.pump(const Duration(milliseconds: 1));
  });
  test(
    'save waits for restore and retains additions made during loading',
    () async {
      storage.pending = Completer<String?>();
      final restore = notifier.restoreGenerationState();
      notifier.addVibeReferences([
        const VibeReference(
          displayName: 'new-vibe',
          vibeEncoding: 'new-encoding',
        ),
      ], recordUsage: false);
      notifier.addPreciseReference(
        Uint8List.fromList([4, 5, 6]),
        type: PreciseRefType.character,
      );
      var saved = false;
      final save = notifier.saveGenerationState().then((_) => saved = true);
      await Future<void>.delayed(Duration.zero);
      expect(saved, isFalse);
      storage.pending!.complete(storage.generationJson);
      await Future.wait([restore, save]);
      final state = container.read(generationParamsNotifierProvider);
      expect(state.vibeReferencesV4.map((v) => v.displayName), [
        'saved-vibe',
        'new-vibe',
      ]);
      expect(state.preciseReferences, hasLength(2));
      expect(storage.generationJson, contains('new-vibe'));
      expect(storage.generationJson, contains('saved-vibe'));
    },
  );
  test(
    'late restore respects explicit replace, clear, and normalize changes',
    () async {
      storage.pending = Completer<String?>();
      final restore = notifier.restoreGenerationState();
      notifier.setVibeReferences([
        const VibeReference(
          displayName: 'replacement',
          vibeEncoding: 'replacement',
        ),
      ]);
      notifier.clearPreciseReferences();
      notifier.setNormalizeVibeStrength(true);
      storage.pending!.complete(storage.generationJson);
      await restore;
      await notifier.saveGenerationState();
      final state = container.read(generationParamsNotifierProvider);
      expect(state.vibeReferencesV4.single.displayName, 'replacement');
      expect(state.preciseReferences, isEmpty);
      expect(state.normalizeVibeStrength, isTrue);
      expect(storage.generationJson, isNot(contains('saved-vibe')));
    },
  );
}
