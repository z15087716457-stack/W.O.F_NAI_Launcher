import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/enums/precise_ref_type.dart';
import 'package:nai_launcher/data/models/precise_ref/precise_ref_library_entry.dart';
import 'package:nai_launcher/data/services/precise_ref_library_storage_service.dart';
import 'package:nai_launcher/presentation/providers/precise_ref_library_provider.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_entry.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/vibe_library_provider.dart';
import 'package:nai_launcher/presentation/ui/refs/refs_contract.dart';
import 'package:nai_launcher/presentation/wiring/refs_generation_target.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Backup extends RefsDraftBackup {
  final snapshots = <String>[];
  Completer<void>? wait;
  @override
  Future<void> save(String snapshot) async {
    snapshots.add(snapshot);
    await wait?.future;
  }
}

class Storage extends VibeLibraryStorageService {
  final entries = <String, VibeLibraryEntry>{};
  Completer<void>? wait;
  @override
  Future<VibeLibraryEntry?> getEntry(String id) async {
    await wait?.future;
    return entries[id];
  }
}

class Library extends VibeLibraryNotifier {
  final used = <String>[];
  @override
  VibeLibraryState build() => const VibeLibraryState();
  @override
  Future<VibeLibraryEntry?> recordUsage(String id) async {
    used.add(id);
    return null;
  }
}

class PreciseStorage extends PreciseRefLibraryStorageService {
  final images = <String, Uint8List>{};
  @override
  Future<Uint8List?> readImageBytes(String id) async => images[id];
}

class PreciseLibrary extends PreciseRefLibraryNotifier {
  final used = <String>[];
  @override
  PreciseRefLibraryState build() => const PreciseRefLibraryState();
  @override
  Future<void> recordUsage(String id) async {
    used.add(id);
  }
}

final referenceImage = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==',
);
PreciseRefLibraryEntry preciseEntry(String id) => PreciseRefLibraryEntry(
  id: id,
  name: id,
  imagePath: '$id.png',
  typeIndex: PreciseRefType.style.index,
  strength: .3,
  fidelity: .4,
  createdAt: DateTime(2026),
);

VibeReference vibe(String key) => VibeReference(
  displayName: key,
  vibeEncoding: key,
  encodingModel: ImageModels.animeDiffusionV45Full,
  sourceType: VibeSourceType.naiv4vibe,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporary;
  late ProviderContainer container;
  late Backup backup;
  late Storage storage;
  late Library library;
  late PreciseStorage preciseStorage;
  late PreciseLibrary preciseLibrary;

  setUpAll(() async {
    temporary = await Directory.systemTemp.createTemp('refs_target_');
    Hive.init(temporary.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.openBox(StorageKeys.historyBox);
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backup = Backup();
    storage = Storage();
    library = Library();
    preciseStorage = PreciseStorage();
    preciseLibrary = PreciseLibrary();
    preciseStorage.images['precise'] = referenceImage;
    container = ProviderContainer(
      overrides: [
        refsDraftBackupProvider.overrideWithValue(backup),
        vibeLibraryStorageServiceProvider.overrideWithValue(storage),
        vibeLibraryNotifierProvider.overrideWith(() => library),
        preciseRefLibraryStorageServiceProvider.overrideWithValue(
          preciseStorage,
        ),
        preciseRefLibraryNotifierProvider.overrideWith(() => preciseLibrary),
      ],
    );
    final params = container.read(generationParamsNotifierProvider.notifier);
    params.updateModel(ImageModels.animeDiffusionV45Full);
    params.setVibeReferences([vibe('old')]);
    storage.entries['a'] = VibeLibraryEntry.fromVibeReference(
      name: 'A',
      vibeData: vibe('a'),
    ).copyWith(id: 'a');
  });
  tearDown(() async {
    container.dispose();
    await Future<void>.delayed(Duration.zero);
    await Hive.box(StorageKeys.settingsBox).clear();
    await Hive.box(StorageKeys.historyBox).clear();
  });
  tearDownAll(() async {
    await Hive.close();
    await temporary.delete(recursive: true);
  });

  test(
    'append and replace back up the complete draft and record one usage',
    () async {
      final target = container.read(refsGenerationTargetProvider);
      await target.addVibes(['a'], alive: () => true);
      expect(
        container
            .read(generationParamsNotifierProvider)
            .vibeReferencesV4
            .map((v) => v.displayName),
        ['old', 'a'],
      );
      expect(library.used, ['a']);
      expect(
        (jsonDecode(backup.snapshots.single) as Map)['vibes'],
        hasLength(1),
      );
      await target.addVibes(['a'], replace: true, alive: () => true);
      expect(
        container
            .read(generationParamsNotifierProvider)
            .vibeReferencesV4
            .single
            .displayName,
        'a',
      );
    },
  );

  test(
    'missing replacement leaves the existing references untouched',
    () async {
      final target = container.read(refsGenerationTargetProvider);
      await expectLater(
        target.addVibes(['missing'], replace: true, alive: () => true),
        throwsStateError,
      );
      expect(
        container
            .read(generationParamsNotifierProvider)
            .vibeReferencesV4
            .single
            .displayName,
        'old',
      );
      expect(backup.snapshots, isEmpty);
    },
  );

  test('a newer edit while the library loads is not overwritten', () async {
    storage.wait = Completer<void>();
    final target = container.read(refsGenerationTargetProvider);
    final operation = target.addVibes(['a'], replace: true, alive: () => true);
    container.read(generationParamsNotifierProvider.notifier).setVibeReferences(
      [vibe('new')],
    );
    storage.wait!.complete();
    await expectLater(operation, throwsStateError);
    expect(
      container
          .read(generationParamsNotifierProvider)
          .vibeReferencesV4
          .single
          .displayName,
      'new',
    );
    expect(library.used, isEmpty);
  });

  test('a newer edit during backup is rechecked before writing', () async {
    backup.wait = Completer<void>();
    final target = container.read(refsGenerationTargetProvider);
    final operation = target.addVibes(['a'], replace: true, alive: () => true);
    while (backup.snapshots.isEmpty) {
      await Future<void>.delayed(Duration.zero);
    }
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePromptImmediately('new prompt');
    backup.wait!.complete();
    await expectLater(operation, throwsStateError);
    expect(
      container
          .read(generationParamsNotifierProvider)
          .vibeReferencesV4
          .single
          .displayName,
      'old',
    );
  });

  test(
    '16-item limit truncates a bundle without dropping old references',
    () async {
      container
          .read(generationParamsNotifierProvider.notifier)
          .setVibeReferences([for (var i = 0; i < 15; i++) vibe('old-$i')]);
      storage.entries['bundle'] = storage.entries['a']!.copyWith(
        id: 'bundle',
        bundledVibeNames: ['a', 'b'],
        bundledVibeEncodings: ['a', 'b'],
        bundledVibeEncodingModels: [
          ImageModels.animeDiffusionV45Full,
          ImageModels.animeDiffusionV45Full,
        ],
      );
      final result = await container
          .read(refsGenerationTargetProvider)
          .addVibes(['bundle'], alive: () => true);
      expect(result.truncated, isTrue);
      expect(result.count, 1);
      expect(
        container.read(generationParamsNotifierProvider).vibeReferencesV4,
        hasLength(16),
      );
      expect(library.used, ['bundle']);
    },
  );

  test('temporary overrides do not update library defaults', () async {
    storage.entries['a'] = storage.entries['a']!.copyWith(
      rawImageData: Uint8List.fromList([1, 2]),
    );
    await container
        .read(refsGenerationTargetProvider)
        .addVibes(
          ['a'],
          overrides: {
            'a': const RefsSendOverride(strength: .2, infoExtracted: .4),
          },
          alive: () => true,
        );
    final sent = container
        .read(generationParamsNotifierProvider)
        .vibeReferencesV4
        .last;
    expect(sent.strength, .2);
    expect(sent.infoExtracted, .4);
    expect(sent.vibeEncoding, isEmpty);
    expect(storage.entries['a']!.strength, .6);
    expect(storage.entries['a']!.infoExtracted, .7);
  });

  test(
    'a stale tray ID cannot remove a later reference at the same index',
    () async {
      final target = container.read(refsGenerationTargetProvider);
      final id = target.tray(RefsKind.vibe).items.single.id;
      container
          .read(generationParamsNotifierProvider.notifier)
          .setVibeReferences([vibe('new')]);
      await target.removeTray(RefsKind.vibe, id, alive: () => true);
      expect(
        container
            .read(generationParamsNotifierProvider)
            .vibeReferencesV4
            .single
            .displayName,
        'new',
      );
      expect(backup.snapshots, isEmpty);
    },
  );

  test(
    'precise replacement applies saved defaults and leaves Vibes intact',
    () async {
      final notifier = container.read(
        generationParamsNotifierProvider.notifier,
      );
      notifier.addPreciseReference(
        referenceImage,
        type: PreciseRefType.character,
      );
      final target = container.read(refsGenerationTargetProvider);
      final result = await target.addPrecise(
        [preciseEntry('precise')],
        replace: true,
        alive: () => true,
      );
      final params = container.read(generationParamsNotifierProvider);
      expect(result.count, 1);
      expect(params.preciseReferences.single.type, PreciseRefType.style);
      expect(params.preciseReferences.single.strength, .3);
      expect(params.preciseReferences.single.fidelity, .4);
      expect(params.vibeReferencesV4.single.displayName, 'old');
      expect(target.tray(RefsKind.precise).items.single.entryKey, 'precise');
      expect(preciseLibrary.used, ['precise']);
    },
  );

  test(
    'missing precise replacement cannot clear existing references',
    () async {
      container
          .read(generationParamsNotifierProvider.notifier)
          .addPreciseReference(referenceImage, type: PreciseRefType.character);
      await expectLater(
        container
            .read(refsGenerationTargetProvider)
            .addPrecise(
              [preciseEntry('missing')],
              replace: true,
              alive: () => true,
            ),
        throwsStateError,
      );
      expect(
        container.read(generationParamsNotifierProvider).preciseReferences,
        hasLength(1),
      );
      expect(backup.snapshots, isEmpty);
    },
  );

  test(
    'removing a duplicated image retires old tray IDs instead of removing the next copy',
    () async {
      final notifier = container.read(
        generationParamsNotifierProvider.notifier,
      );
      notifier.addPreciseReference(
        referenceImage,
        type: PreciseRefType.character,
      );
      notifier.addPreciseReference(referenceImage, type: PreciseRefType.style);
      final target = container.read(refsGenerationTargetProvider);
      final first = target.tray(RefsKind.precise).items.first.id;
      await target.removeTray(RefsKind.precise, first, alive: () => true);
      await target.removeTray(RefsKind.precise, first, alive: () => true);
      expect(
        container
            .read(generationParamsNotifierProvider)
            .preciseReferences
            .single
            .type,
        PreciseRefType.style,
      );
      expect(backup.snapshots, hasLength(1));
    },
  );

  test(
    'clear then re-add does not restore the removed reference tray ID',
    () async {
      final target = container.read(refsGenerationTargetProvider);
      final oldId = target.tray(RefsKind.vibe).items.single.id;
      await target.removeTray(RefsKind.vibe, null, alive: () => true);
      container
          .read(generationParamsNotifierProvider.notifier)
          .setVibeReferences([vibe('old')]);
      await target.removeTray(RefsKind.vibe, oldId, alive: () => true);
      expect(
        container.read(generationParamsNotifierProvider).vibeReferencesV4,
        hasLength(1),
      );
    },
  );

  test(
    'pause and resume affect enabled flags without losing Vibe parameters',
    () async {
      final target = container.read(refsGenerationTargetProvider);
      await target.pauseVibes(true, alive: () => true);
      expect(target.tray(RefsKind.precise).vibesPaused, isTrue);
      expect(target.tray(RefsKind.precise).otherVibes, 0);
      await target.pauseVibes(false, alive: () => true);
      expect(target.tray(RefsKind.precise).otherVibes, 1);
      expect(
        container
            .read(generationParamsNotifierProvider)
            .vibeReferencesV4
            .single
            .strength,
        .6,
      );
    },
  );

  test(
    'append preserves an existing same-content reference and its draft parameters',
    () async {
      container
          .read(generationParamsNotifierProvider.notifier)
          .setVibeReferences([vibe('a').copyWith(strength: .9)]);
      await container.read(refsGenerationTargetProvider).addVibes([
        'a',
      ], alive: () => true);
      final references = container
          .read(generationParamsNotifierProvider)
          .vibeReferencesV4;
      expect(references, hasLength(2));
      expect(references.first.strength, .9);
      expect(references.last.strength, .6);
    },
  );

  test('a stale ID cannot remove a new same-content reference', () async {
    final target = container.read(refsGenerationTargetProvider);
    final old = container
        .read(generationParamsNotifierProvider)
        .vibeReferencesV4
        .single;
    final id = target.tray(RefsKind.vibe).items.single.id;
    container.read(generationParamsNotifierProvider.notifier).setVibeReferences(
      [old.copyWith(strength: .8)],
    );
    await target.removeTray(RefsKind.vibe, id, alive: () => true);
    expect(
      container
          .read(generationParamsNotifierProvider)
          .vibeReferencesV4
          .single
          .strength,
      .8,
    );
  });

  test('same-image precise presets retain separate library origins', () async {
    preciseStorage.images['other'] = referenceImage;
    final target = container.read(refsGenerationTargetProvider);
    await target.addPrecise([
      preciseEntry('precise'),
      preciseEntry('other'),
    ], alive: () => true);
    expect(target.tray(RefsKind.precise).items.map((item) => item.entryKey), [
      'precise',
      'other',
    ]);
  });

  test('duplicate sends while loading are not dispatched twice', () async {
    storage.wait = Completer<void>();
    final target = container.read(refsGenerationTargetProvider);
    final first = target.addVibes(['a'], alive: () => true);
    expect((await target.addVibes(['a'], alive: () => true)).count, 0);
    storage.wait!.complete();
    await first;
    expect(library.used, ['a']);
  });
}
