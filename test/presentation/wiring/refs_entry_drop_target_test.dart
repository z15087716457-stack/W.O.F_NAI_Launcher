import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/constants/model_spec.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/services/effective_vibe_references.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_entry.dart';
import 'package:nai_launcher/data/services/precise_ref_library_storage_service.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import '../providers/krita/agent_bridge_draft_test.dart'
    show EmptyBlocks, MemoryCharacters, IdleGeneration;
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/precise_ref_library_provider.dart';
import 'package:nai_launcher/presentation/providers/vibe_library_provider.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_contract.dart';
import 'package:nai_launcher/presentation/wiring/floating_resource_drag.dart';
import 'package:nai_launcher/presentation/wiring/floating_resource_windows_host.dart';
import 'package:nai_launcher/presentation/providers/floating_resource_windows_provider.dart';
import 'package:nai_launcher/presentation/wiring/generation_drop_wiring.dart';
import 'package:nai_launcher/presentation/wiring/refs_entry_drop_target.dart';
import 'package:nai_launcher/presentation/wiring/refs_generation_target.dart';
import '../providers/floating_resource_windows_test.dart'
    show MemoryWindowSettings;
import 'refs_generation_target_test.dart' as fixture;

class VibeStorage extends fixture.Storage {
  @override
  Future<void> saveGenerationStateJson(String stateJson) async {}
  @override
  Future<String?> loadGenerationStateJson() async => null;
}

class PreciseLibrary extends fixture.PreciseLibrary {
  @override
  PreciseRefLibraryState build() =>
      PreciseRefLibraryState(entries: [fixture.preciseEntry('precise')]);
  @override
  Future<void> initialize() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  late Directory temp;
  late fixture.Backup backup;
  late fixture.Storage storage;
  late fixture.Library vibes;
  late PreciseLibrary precise;
  late RefsEntryDropActions actions;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    temp = await Directory.systemTemp.createTemp('floating-refs-drop-');
    Hive.init(temp.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.openBox(StorageKeys.historyBox);
    backup = fixture.Backup();
    storage = VibeStorage();
    vibes = fixture.Library();
    precise = PreciseLibrary();
    final preciseStorage = fixture.PreciseStorage()
      ..images['precise'] = fixture.referenceImage;
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryWindowSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockLibraryNotifierProvider.overrideWith(EmptyBlocks.new),
        imageGenerationNotifierProvider.overrideWith(IdleGeneration.new),
        refsDraftBackupProvider.overrideWithValue(backup),
        vibeLibraryStorageServiceProvider.overrideWithValue(storage),
        vibeLibraryNotifierProvider.overrideWith(() => vibes),
        preciseRefLibraryStorageServiceProvider.overrideWithValue(
          preciseStorage,
        ),
        preciseRefLibraryNotifierProvider.overrideWith(() => precise),
      ],
    );
    container
        .read(generationParamsNotifierProvider.notifier)
        .updateModel(ImageModels.animeDiffusionV45Full);
    // Synthetic full entry; no thumbnail or filesystem access.
    storage.entries['a'] = VibeLibraryEntry.fromVibeReference(
      name: 'A',
      vibeData: fixture.vibe('a'),
    ).copyWith(id: 'a');
    actions = container.read(refsEntryDropActionsProvider);
  });
  tearDown(() async {
    container.dispose();
    await Future<void>.delayed(Duration.zero);
    await Hive.close();
    await temp.delete(recursive: true);
  });

  test(
    'typed protocol refuses cross-kind, empty, unsupported-model and dead drops',
    () async {
      final data = FloatingResourceDrag.refs(RefsKind.vibe, ['a']);
      expect(actions.accepts(RefsKind.precise, data), isFalse);
      expect(
        actions.accepts(
          RefsKind.vibe,
          FloatingResourceDrag.refs(RefsKind.vibe, []),
        ),
        isFalse,
      );
      expect(
        (await actions.drop(RefsKind.vibe, data, alive: () => false)).count,
        0,
      );
      container
          .read(generationParamsNotifierProvider.notifier)
          .updateModel(ImageModels.animeDiffusionV5Full);
      expect(actions.accepts(RefsKind.vibe, data), isFalse);
      expect(backup.snapshots, isEmpty);
    },
  );
  test(
    'Vibe drop uses addVibes backup/usage/limit semantics, deduplicating keys',
    () async {
      container
          .read(generationParamsNotifierProvider.notifier)
          .setVibeReferences([
            for (var i = 0; i < 15; i++) fixture.vibe('old$i'),
          ]);
      final data = FloatingResourceDrag.refs(RefsKind.vibe, ['a', 'a']);
      expect(
        (await actions.drop(RefsKind.vibe, data, alive: () => true)).count,
        1,
      );
      expect(backup.snapshots, hasLength(1));
      expect(vibes.used, ['a']);
      final full = await actions.drop(RefsKind.vibe, data, alive: () => true);
      expect(full.count, 0);
      expect(full.truncated, isTrue);
      expect(
        container.read(generationParamsNotifierProvider).vibeReferencesV4,
        hasLength(16),
      );
    },
  );
  test(
    'precise drop resolves current entries and uses saved defaults and usage',
    () async {
      final result = await actions.drop(
        RefsKind.precise,
        FloatingResourceDrag.refs(RefsKind.precise, ['precise', 'precise']),
        alive: () => true,
      );
      expect(result.count, 1);
      final item = container
          .read(generationParamsNotifierProvider)
          .preciseReferences
          .single;
      expect(item.type, fixture.preciseEntry('precise').type);
      expect(item.strength, .3);
      expect(item.fidelity, .4);
      expect(precise.used, ['precise']);
      expect(backup.snapshots, hasLength(1));
    },
  );
  test('deleted reference and stale backup cannot modify draft', () async {
    await expectLater(
      actions.drop(
        RefsKind.precise,
        FloatingResourceDrag.refs(RefsKind.precise, ['deleted']),
        alive: () => true,
      ),
      throwsStateError,
    );
    expect(backup.snapshots, isEmpty);
    backup.wait = Completer<void>();
    final operation = actions.drop(
      RefsKind.vibe,
      FloatingResourceDrag.refs(RefsKind.vibe, ['a']),
      alive: () => true,
    );
    final rejected = expectLater(operation, throwsStateError);
    await Future<void>.delayed(Duration.zero);
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePromptImmediately('new user edit');
    backup.wait!.complete();
    await rejected;
    expect(
      container.read(generationParamsNotifierProvider).vibeReferencesV4,
      isEmpty,
    );
  });
  test(
    'inpaint keeps dropped Vibes in draft but B10 excludes them from request',
    () async {
      container
          .read(generationParamsNotifierProvider.notifier)
          .updateAction(ImageGenerationAction.infill);
      await actions.drop(
        RefsKind.vibe,
        FloatingResourceDrag.refs(RefsKind.vibe, ['a']),
        alive: () => true,
      );
      final params = container.read(generationParamsNotifierProvider);
      expect(params.vibeReferencesV4, hasLength(1));
      expect(
        effectiveVibeReferences(params, ModelSpecs.of(params.model)),
        isEmpty,
      );
    },
  );
  for (final kind in RefsKind.values) {
    testWidgets(
      'actual generation $kind row accepts internal Flutter drag and clears hover',
      (tester) async {
        final payload = FloatingResourceDrag.refs(kind, [
          kind == RefsKind.vibe ? 'a' : 'precise',
        ]);
        final target = kind == RefsKind.vibe
            ? GenDropTarget.vibe
            : GenDropTarget.precise;
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              builder: (context, child) => FloatingResourceWindowsHost(
                builder: (_, window, controller) => Align(
                  alignment: Alignment.centerLeft,
                  child: Draggable<RefsEntryDragData>(
                    hitTestBehavior: HitTestBehavior.opaque,
                    data: payload,
                    feedback: const SizedBox(width: 20, height: 20),
                    child: const SizedBox(
                      key: Key('drag'),
                      width: 80,
                      height: 80,
                    ),
                  ),
                ),
                child: child!,
              ),
              home: Scaffold(
                body: Align(
                  alignment: Alignment.centerRight,
                  child: GenerationDropWiring(
                    target: target,
                    child: const SizedBox(
                      key: Key('target'),
                      width: 240,
                      height: 160,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        container
            .read(floatingResourceWindowsProvider.notifier)
            .open(
              kind == RefsKind.vibe
                  ? FloatingResourceKind.vibe
                  : FloatingResourceKind.precise,
            );
        await tester.pump();
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('drag'))),
        );
        await gesture.moveBy(const Offset(20, 0));
        await tester.pump();
        await gesture.moveTo(tester.getCenter(find.byKey(const Key('target'))));
        await tester.pump();
        expect(container.read(generationDropHoverProvider), target);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(container.read(generationDropHoverProvider), isNull);
        expect(backup.snapshots, hasLength(1));
        if (kind == RefsKind.vibe) {
          expect(vibes.used, ['a']);
        } else {
          expect(precise.used, ['precise']);
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
