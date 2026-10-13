import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/bridge_draft_snapshot.dart';
import 'package:nai_launcher/presentation/wiring/image_viewer_generation_target.dart';
import 'package:nai_launcher/presentation/wiring/image_viewer_platform.dart';

class _Backup extends ImageViewerPlatform {
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
  late _Backup backup;
  setUpAll(() async {
    temporary = await Directory.systemTemp.createTemp('viewer_guard_');
    Hive.init(temporary.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.openBox(StorageKeys.historyBox);
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backup = _Backup();
    container = ProviderContainer(
      overrides: [imageViewerPlatformProvider.overrideWithValue(backup)],
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

  test('complete draft backed up before any write', () async {
    final params = container.read(generationParamsNotifierProvider.notifier);
    params.updatePromptImmediately('before');
    final commit = container
        .read(imageViewerGenerationTargetProvider)
        .capture(alive: () => true);
    await commit(() => params.updatePromptImmediately('after'));
    expect(container.read(generationParamsNotifierProvider).prompt, 'after');
    expect(
      (jsonDecode(backup.snapshots.single) as Map)['generation']['prompt'],
      'before',
    );
  });

  test('capture precedes asynchronous image or dialog loading', () async {
    final params = container.read(generationParamsNotifierProvider.notifier);
    final commit = container
        .read(imageViewerGenerationTargetProvider)
        .capture(alive: () => true);
    params.updatePromptImmediately('new');
    await expectLater(
      commit(() => params.updatePromptImmediately('old')),
      throwsStateError,
    );
    expect(backup.snapshots, isEmpty);
    expect(container.read(generationParamsNotifierProvider).prompt, 'new');
  });

  test('new edit during backup is not overwritten', () async {
    backup.wait = Completer<void>();
    final params = container.read(generationParamsNotifierProvider.notifier);
    final commit = container
        .read(imageViewerGenerationTargetProvider)
        .capture(alive: () => true);
    final writing = commit(() => params.updatePromptImmediately('old'));
    final assertion = expectLater(writing, throwsStateError);
    params.updatePromptImmediately('new');
    backup.wait!.complete();
    await assertion;
    expect(container.read(generationParamsNotifierProvider).prompt, 'new');
  });

  test(
    'generation parameters are checked even with unchanged bridge version',
    () async {
      container.dispose();
      container = ProviderContainer(
        overrides: [
          imageViewerPlatformProvider.overrideWithValue(backup),
          bridgeDraftVersionProvider.overrideWithValue('fixed'),
        ],
      );
      final params = container.read(generationParamsNotifierProvider.notifier);
      final commit = container
          .read(imageViewerGenerationTargetProvider)
          .capture(alive: () => true);
      params.updatePromptImmediately('new');
      await expectLater(
        commit(() => params.updatePromptImmediately('old')),
        throwsStateError,
      );
      expect(container.read(generationParamsNotifierProvider).prompt, 'new');
    },
  );

  test('backup failure does not write; a new attempt can retry', () async {
    final target = container.read(imageViewerGenerationTargetProvider);
    var writes = 0;
    backup.fail = true;
    await expectLater(
      target.capture(alive: () => true)(() {
        writes++;
      }),
      throwsStateError,
    );
    expect(writes, 0);
    backup.fail = false;
    await target.capture(alive: () => true)(() {
      writes++;
    });
    expect(writes, 1);
  });

  test(
    'caller disappearance or selection change during backup stops write',
    () async {
      backup.wait = Completer<void>();
      var alive = true;
      final commit = container
          .read(imageViewerGenerationTargetProvider)
          .capture(alive: () => alive);
      final writing = commit(() => fail('unexpected write'));
      final assertion = expectLater(writing, throwsStateError);
      alive = false;
      backup.wait!.complete();
      await assertion;
    },
  );

  test('concurrent commits cannot duplicate dispatch', () async {
    backup.wait = Completer<void>();
    final commit = container
        .read(imageViewerGenerationTargetProvider)
        .capture(alive: () => true);
    var writes = 0;
    final first = commit(() {
      writes++;
    });
    await expectLater(
      commit(() {
        writes++;
      }),
      throwsStateError,
    );
    backup.wait!.complete();
    await first;
    expect(writes, 1);
  });
}
