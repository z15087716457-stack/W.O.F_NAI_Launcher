import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/bridge_draft_snapshot.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_runner.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_contract.dart';
import 'package:nai_launcher/presentation/wiring/style_explore_backend.dart';
import 'package:nai_launcher/presentation/wiring/style_explore_platform.dart';

class _Backup extends StyleExplorePlatform {
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

class _Auth extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(accountId: 'test', status: AuthStatus.authenticated);
  void choose(String id) {
    state = state.copyWith(accountId: id);
  }
}

class _IdleRunner extends ExploreRunRunner {
  @override
  ExploreRunRunnerState build() => const ExploreRunRunnerState();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporary;
  late ProviderContainer container;
  late _Backup backup;
  setUpAll(() async {
    temporary = await Directory.systemTemp.createTemp('explore_guard_');
    Hive.init(temporary.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.openBox(StorageKeys.historyBox);
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backup = _Backup();
    container = ProviderContainer(
      overrides: [
        styleExplorePlatformProvider.overrideWithValue(backup),
        exploreRunRunnerProvider.overrideWith(_IdleRunner.new),
        authNotifierProvider.overrideWith(_Auth.new),
      ],
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
        .read(styleExploreBackendProvider)
        .captureDraft(alive: () => true);
    await commit(() => params.updatePromptImmediately('after'));
    expect(container.read(generationParamsNotifierProvider).prompt, 'after');
    expect(
      (jsonDecode(backup.snapshots.single) as Map)['generation']['prompt'],
      'before',
    );
  });

  test(
    'capture precedes an asynchronous confirmation or candidate read',
    () async {
      final params = container.read(generationParamsNotifierProvider.notifier);
      final commit = container
          .read(styleExploreBackendProvider)
          .captureDraft(alive: () => true);
      params.updatePromptImmediately('new');
      await expectLater(
        commit(() => params.updatePromptImmediately('old')),
        throwsStateError,
      );
      expect(backup.snapshots, isEmpty);
      expect(container.read(generationParamsNotifierProvider).prompt, 'new');
    },
  );

  test('new edit during backup is not overwritten', () async {
    backup.wait = Completer<void>();
    final params = container.read(generationParamsNotifierProvider.notifier);
    final commit = container
        .read(styleExploreBackendProvider)
        .captureDraft(alive: () => true);
    final writing = commit(() => params.updatePromptImmediately('old'));
    final assertion = expectLater(writing, throwsStateError);
    params.updatePromptImmediately('new');
    backup.wait!.complete();
    await assertion;
    expect(container.read(generationParamsNotifierProvider).prompt, 'new');
  });

  test(
    'generation parameters are checked even with a fixed bridge version',
    () async {
      container.dispose();
      container = ProviderContainer(
        overrides: [
          styleExplorePlatformProvider.overrideWithValue(backup),
          exploreRunRunnerProvider.overrideWith(_IdleRunner.new),
          authNotifierProvider.overrideWith(_Auth.new),
          bridgeDraftVersionProvider.overrideWithValue('fixed'),
        ],
      );
      final params = container.read(generationParamsNotifierProvider.notifier);
      final commit = container
          .read(styleExploreBackendProvider)
          .captureDraft(alive: () => true);
      params.updatePromptImmediately('new');
      await expectLater(
        commit(() => params.updatePromptImmediately('old')),
        throwsStateError,
      );
      expect(container.read(generationParamsNotifierProvider).prompt, 'new');
    },
  );

  test('backup failure never writes and allows retry', () async {
    final target = container.read(styleExploreBackendProvider);
    var writes = 0;
    backup.fail = true;
    await expectLater(
      target.captureDraft(alive: () => true)(() {
        writes++;
      }),
      throwsStateError,
    );
    expect(writes, 0);
    backup.fail = false;
    await target.captureDraft(alive: () => true)(() {
      writes++;
    });
    expect(writes, 1);
  });

  test('a changed caller or selection during backup stops the write', () async {
    backup.wait = Completer<void>();
    var alive = true;
    final commit = container
        .read(styleExploreBackendProvider)
        .captureDraft(alive: () => alive);
    final writing = commit(() => fail('unexpected write'));
    final assertion = expectLater(writing, throwsStateError);
    alive = false;
    backup.wait!.complete();
    await assertion;
  });

  test('concurrent commits cannot duplicate dispatch', () async {
    backup.wait = Completer<void>();
    final commit = container
        .read(styleExploreBackendProvider)
        .captureDraft(alive: () => true);
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

  test(
    'generation confirmation binds the account, draft and run-selection epoch',
    () {
      final backend = container.read(styleExploreBackendProvider);
      final current = backend.captureGeneration(null, alive: () => true);
      expect(current(), isTrue);
      (container.read(authNotifierProvider.notifier) as _Auth).choose('other');
      expect(current(), isFalse);
      final next = backend.captureGeneration(null, alive: () => true);
      expect(next(), isTrue);
      container.read(exploreRunSelectionEpochProvider.notifier).state++;
      expect(next(), isFalse);
      final draft = backend.captureGeneration(null, alive: () => true);
      container
          .read(generationParamsNotifierProvider.notifier)
          .updatePromptImmediately('new');
      expect(draft(), isFalse);
    },
  );

  test(
    'generation confirmation cannot target another active run or a vanished caller',
    () {
      var alive = true;
      final current = container
          .read(styleExploreBackendProvider)
          .captureGeneration(null, alive: () => alive);
      alive = false;
      expect(current(), isFalse);
      alive = true;
      container.read(exploreActiveRunIdProvider.notifier).state = 'other';
      expect(current(), isFalse);
    },
  );

  test(
    'card-size preference persists independently of other layout preferences',
    () async {
      expect(
        container.read(styleExploreCardSizeProvider),
        ExploreCardSize.large,
      );
      await container
          .read(styleExploreBackendProvider)
          .setCardSize(ExploreCardSize.small);
      expect(
        container.read(styleExploreCardSizeProvider),
        ExploreCardSize.small,
      );
      final fresh = ProviderContainer();
      expect(fresh.read(styleExploreCardSizeProvider), ExploreCardSize.small);
      fresh.dispose();
    },
  );
}
