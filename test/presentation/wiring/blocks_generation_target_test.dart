import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/wiring/blocks_generation_target.dart';
import 'package:nai_launcher/presentation/providers/krita/bridge_draft_snapshot.dart';
import 'package:nai_launcher/presentation/wiring/blocks_platform.dart';

class TestBackup extends BlocksPlatform {
  final snapshots = <String>[];
  Completer<void>? wait;
  bool fail = false;
  @override
  Future<void> backupDraft(String snapshot) async {
    snapshots.add(snapshot);
    if (fail) throw StateError('Backup failed');
    await wait?.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporary;
  late ProviderContainer container;
  late TestBackup backup;
  setUpAll(() async {
    temporary = await Directory.systemTemp.createTemp('blocks_guard_');
    Hive.init(temporary.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.openBox(StorageKeys.historyBox);
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backup = TestBackup();
    container = ProviderContainer(
      overrides: [blocksPlatformProvider.overrideWithValue(backup)],
    );
  });
  tearDown(() async {
    container.dispose();
    await Future<void>.delayed(Duration.zero);
    await Hive.box(StorageKeys.settingsBox).clear();
  });
  tearDownAll(() async {
    await Hive.close();
    await temporary.delete(recursive: true);
  });

  test('commits only after complete draft backup', () async {
    final params = container.read(generationParamsNotifierProvider.notifier);
    params.updatePromptImmediately('before');
    final target = container.read(blocksGenerationTargetProvider);
    expect(
      await target.commit(
        () => params.updatePromptImmediately('after'),
        alive: () => true,
      ),
      isTrue,
    );
    expect(container.read(generationParamsNotifierProvider).prompt, 'after');
    expect(
      (jsonDecode(backup.snapshots.single) as Map)['generation']['prompt'],
      'before',
    );
  });

  test('a newer edit during backup is not overwritten', () async {
    backup.wait = Completer<void>();
    final params = container.read(generationParamsNotifierProvider.notifier);
    final target = container.read(blocksGenerationTargetProvider);
    final saving = target.commit(
      () => params.updatePromptImmediately('old'),
      alive: () => true,
    );
    final assertion = expectLater(saving, throwsStateError);
    params.updatePromptImmediately('new');
    backup.wait!.complete();
    await assertion;
    expect(container.read(generationParamsNotifierProvider).prompt, 'new');
  });

  test(
    'generation parameters are guarded independently of the bridge version',
    () async {
      container.dispose();
      container = ProviderContainer(
        overrides: [
          blocksPlatformProvider.overrideWithValue(backup),
          bridgeDraftVersionProvider.overrideWithValue(
            'unchanged-bridge-version',
          ),
        ],
      );
      backup.wait = Completer<void>();
      final params = container.read(generationParamsNotifierProvider.notifier);
      final target = container.read(blocksGenerationTargetProvider);
      final saving = target.commit(
        () => params.updatePromptImmediately('old'),
        alive: () => true,
      );
      final assertion = expectLater(saving, throwsStateError);
      params.updatePromptImmediately('new');
      backup.wait!.complete();
      await assertion;
      expect(container.read(generationParamsNotifierProvider).prompt, 'new');
    },
  );

  test('duplicate commits are suppressed while backup is pending', () async {
    backup.wait = Completer<void>();
    final target = container.read(blocksGenerationTargetProvider);
    var writes = 0;
    final first = target.commit(() => writes++, alive: () => true);
    expect(await target.commit(() => writes++, alive: () => true), isFalse);
    backup.wait!.complete();
    await first;
    expect(writes, 1);
  });

  test('failed backup cannot modify draft and a later retry works', () async {
    final target = container.read(blocksGenerationTargetProvider);
    var writes = 0;
    backup.fail = true;
    await expectLater(
      target.commit(() => writes++, alive: () => true),
      throwsStateError,
    );
    expect(writes, 0);
    backup.fail = false;
    await target.commit(() => writes++, alive: () => true);
    expect(writes, 1);
  });

  test('unmounted caller or changed selection cannot commit', () async {
    final target = container.read(blocksGenerationTargetProvider);
    await expectLater(
      target.commit(() => fail('unexpected write'), alive: () => false),
      throwsStateError,
    );
    await expectLater(
      target.commit(
        () => fail('unexpected write'),
        alive: () => true,
        unchanged: () => false,
      ),
      throwsStateError,
    );
    expect(backup.snapshots, isEmpty);
  });
}
