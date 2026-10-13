import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/models/online_gallery/gallery_item.dart';
import 'package:nai_launcher/data/models/online_gallery/gallery_source.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/pending_prompt_provider.dart';
import 'package:nai_launcher/presentation/ui/online/online_contract.dart';
import 'package:nai_launcher/presentation/wiring/online_generation_target.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporary;
  late ProviderContainer container;
  late _Backup backup;

  setUpAll(() async {
    temporary = await Directory.systemTemp.createTemp('online_send_test_');
    Hive.init(temporary.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.openBox(StorageKeys.historyBox);
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backup = _Backup();
    container = ProviderContainer(
      overrides: [onlineDraftBackupProvider.overrideWithValue(backup)],
    );
    final params = container.read(generationParamsNotifierProvider.notifier);
    params.updatePromptImmediately('existing draft');
    params.updateNegativePromptImmediately('old negative');
    container
        .read(characterPromptNotifierProvider.notifier)
        .addCharacter(CharacterGender.female, prompt: 'existing character');
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

  for (final mode in [OnlineSendMode.replace, OnlineSendMode.promptOnly]) {
    test(
      '$mode replaces both prompts and applies the requested character policy',
      () async {
        final target = container.read(onlineGenerationTargetProvider);
        await target.apply(
          _detail,
          mode,
          snapshot: target.capture(),
          alive: () => true,
        );
        final params = container.read(generationParamsNotifierProvider);
        expect(params.prompt, 'imported prompt');
        expect(params.negativePrompt, '');
        expect(
          container.read(pendingPromptNotifierProvider).prompt,
          'imported prompt',
        );
        expect(
          container.read(pendingPromptNotifierProvider).negativePrompt,
          '',
        );
        expect(
          container.read(characterPromptNotifierProvider).characters.length,
          mode == OnlineSendMode.replace ? 0 : 1,
        );
        expect(backup.snapshots, hasLength(1));
        final json = jsonDecode(backup.snapshots.single) as Map;
        expect((json['generation'] as Map)['prompt'], 'existing draft');
        expect((json['documents'] as Map)['characters'], isNotNull);
      },
    );
  }

  test(
    'withParams uses official import, replaces characters and clears stale pending text',
    () async {
      container
          .read(pendingPromptNotifierProvider.notifier)
          .set(prompt: 'stale pending');
      final target = container.read(onlineGenerationTargetProvider);
      await target.apply(
        _detail,
        OnlineSendMode.withParams,
        snapshot: target.capture(),
        alive: () => true,
      );
      final params = container.read(generationParamsNotifierProvider);
      expect(params.prompt, 'imported prompt');
      expect(params.negativePrompt, '');
      expect(params.seed, 123);
      expect(params.steps, 28);
      expect(params.width, 832);
      expect(params.height, 1216);
      expect(params.scale, 5.5);
      expect(params.model, 'nai-diffusion-5-full');
      expect(container.read(pendingPromptNotifierProvider).prompt, isNull);
      expect(
        container
            .read(characterPromptNotifierProvider)
            .characters
            .single
            .prompt,
        '1girl, blue hair',
      );
      expect(params.characters.single.prompt, '1girl, blue hair');
    },
  );

  test('a newer edit while detail loads is never overwritten', () async {
    final target = container.read(onlineGenerationTargetProvider);
    final snapshot = target.capture();
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePromptImmediately('new user edit');
    await expectLater(
      target.apply(
        _detail,
        OnlineSendMode.replace,
        snapshot: snapshot,
        alive: () => true,
      ),
      throwsStateError,
    );
    expect(
      container.read(generationParamsNotifierProvider).prompt,
      'new user edit',
    );
    expect(
      container.read(characterPromptNotifierProvider).characters,
      hasLength(1),
    );
    expect(backup.snapshots, isEmpty);
  });

  test('a newer edit during backup is rechecked before any write', () async {
    backup.wait = Completer<void>();
    final target = container.read(onlineGenerationTargetProvider);
    final operation = target.apply(
      _detail,
      OnlineSendMode.replace,
      snapshot: target.capture(),
      alive: () => true,
    );
    await Future<void>.delayed(Duration.zero);
    container
        .read(generationParamsNotifierProvider.notifier)
        .updateNegativePromptImmediately('new negative');
    backup.wait!.complete();
    await expectLater(operation, throwsStateError);
    expect(
      container.read(generationParamsNotifierProvider).prompt,
      'existing draft',
    );
    expect(
      container.read(generationParamsNotifierProvider).negativePrompt,
      'new negative',
    );
  });

  test(
    'backup failure stops import without clearing characters or pending text',
    () async {
      backup.fail = true;
      final target = container.read(onlineGenerationTargetProvider);
      await expectLater(
        target.apply(
          _detail,
          OnlineSendMode.replace,
          snapshot: target.capture(),
          alive: () => true,
        ),
        throwsStateError,
      );
      expect(
        container.read(generationParamsNotifierProvider).prompt,
        'existing draft',
      );
      expect(
        container.read(characterPromptNotifierProvider).characters,
        hasLength(1),
      );
    },
  );

  test('missing metadata does not silently downgrade withParams', () async {
    final target = container.read(onlineGenerationTargetProvider);
    await expectLater(
      target.apply(
        const GalleryDetail(item: GalleryItem(id: 9), media: []),
        OnlineSendMode.withParams,
        snapshot: target.capture(),
        alive: () => true,
      ),
      throwsStateError,
    );
    expect(
      container.read(generationParamsNotifierProvider).prompt,
      'existing draft',
    );
    expect(backup.snapshots, isEmpty);
  });

  test('disposed or superseded sends cannot modify the draft', () async {
    final target = container.read(onlineGenerationTargetProvider);
    await expectLater(
      target.apply(
        _detail,
        OnlineSendMode.replace,
        snapshot: target.capture(),
        alive: () => false,
      ),
      throwsStateError,
    );
    expect(backup.snapshots, isEmpty);
    expect(
      container.read(characterPromptNotifierProvider).characters,
      hasLength(1),
    );
  });

  test('new pending imports are also protected from late writes', () async {
    final target = container.read(onlineGenerationTargetProvider);
    final snapshot = target.capture();
    container
        .read(pendingPromptNotifierProvider.notifier)
        .set(prompt: 'new pending');
    await expectLater(
      target.apply(
        _detail,
        OnlineSendMode.replace,
        snapshot: snapshot,
        alive: () => true,
      ),
      throwsStateError,
    );
    expect(container.read(pendingPromptNotifierProvider).prompt, 'new pending');
    expect(backup.snapshots, isEmpty);
  });
}

const _detail = GalleryDetail(
  item: GalleryItem(id: 1, sourceId: GallerySourceId.aiTag),
  media: [
    GalleryMedia(
      id: 'p0',
      prompt: 'imported prompt',
      negativePrompt: '',
      naiMetadata: NaiImageMetadata(
        prompt: 'imported prompt',
        negativePrompt: '',
        model: 'nai-diffusion-5-full',
        seed: 123,
        width: 832,
        height: 1216,
        steps: 28,
        scale: 5.5,
        sampler: 'k_euler',
        characterPrompts: ['1girl, blue hair'],
      ),
    ),
  ],
);

class _Backup extends OnlineDraftBackup {
  final snapshots = <String>[];
  Completer<void>? wait;
  bool fail = false;
  @override
  Future<void> save(String snapshot) async {
    if (fail) throw StateError('backup failed');
    snapshots.add(snapshot);
    await wait?.future;
  }
}
