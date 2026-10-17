import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/database/dictionary_data_store.dart';
import 'package:nai_launcher/core/database/dictionary_downloader.dart';
import 'package:nai_launcher/core/database/dictionary_revision.dart';
import 'package:nai_launcher/core/database/dictionary_update_checker.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_dictionary_update.dart';

class _Job extends DictionaryDownloader {
  _Job(super.store);
  final started = Completer<void>();
  final result = Completer<Map<String, int>>();
  late void Function(DictionaryProgress) report;
  int cancels = 0;
  DictionarySource? source;
  @override
  Future<Map<String, int>> install(
    DictionarySource source,
    String seed,
    void Function(DictionaryProgress) callback,
  ) {
    report = callback;
    this.source = source;
    started.complete();
    return result.future;
  }

  @override
  void cancel() {
    cancels++;
    if (!result.isCompleted) {
      result.completeError(StateError('cancelled fixture'));
    }
  }
}

class _Checker extends DictionaryUpdateChecker {
  final result = Completer<DictionaryCheckResult>();
  @override
  Future<DictionaryCheckResult> check() => result.future;
  @override
  void cancel() {
    if (!result.isCompleted) result.completeError(StateError('cancelled'));
  }
}

class _Store extends DictionaryDataStore {
  _Store(super.root);
  final records = <DictionaryKind, Map<String, dynamic>>{};
  @override
  Map<String, dynamic>? record(DictionaryKind kind) => records[kind];
}

void main() {
  late ProviderContainer container;
  late Directory root;
  late Completer<DictionaryUpdateContext> context;
  late List<_Job> jobs;
  late List<_Checker> checks;
  late _Store store;
  late DateTime checkedAt;
  setUp(() {
    root = Directory.systemTemp.createTempSync('dictionary_wiring_');
    context = Completer();
    jobs = [];
    checks = [];
    store = _Store(root);
    checkedAt = DateTime.now().toUtc().subtract(const Duration(minutes: 1));
    container = ProviderContainer(
      overrides: [
        dictionaryUpdateCheckerFactoryProvider.overrideWithValue(() {
          final checker = _Checker();
          checks.add(checker);
          return checker;
        }),
        dictionaryUpdateContextProvider.overrideWithValue(() => context.future),
        dictionaryDownloaderFactoryProvider.overrideWithValue((store) {
          final job = _Job(store);
          jobs.add(job);
          return job;
        }),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await root.delete(recursive: true);
  });
  void ready() =>
      context.complete((store: store, seed: (_) async => 'fixture.db'));

  void installed({int wikiMerge = 2}) {
    for (final kind in DictionaryKind.values) {
      store.records[kind] = {
        'sourceHash': dictionarySources[kind]!.sha256,
        'date': dictionarySources[kind]!.date,
        'mergeVersion': kind == DictionaryKind.wiki ? wikiMerge : 1,
      };
    }
  }

  DictionaryCheckResult result() =>
      DictionaryCheckResult(dictionarySources, checkedAt);

  test(
    'opening reads local metadata only; a shared check never downloads data',
    () async {
      installed();
      ready();
      final controller = container.read(
        settingsDictionaryUpdateProvider.notifier,
      );
      await Future<void>.delayed(Duration.zero);
      expect(checks, isEmpty);
      expect(jobs, isEmpty);
      final first = controller.check();
      final second = controller.check();
      expect(identical(first, second), isTrue);
      expect(container.read(settingsDictionaryUpdateProvider).checking, isTrue);
      expect(
        identical(controller.start(SettingsDictionaryKind.tags), first),
        isTrue,
      );
      await Future<void>.delayed(Duration.zero);
      checks.single.result.complete(result());
      await first;
      final state = container.read(settingsDictionaryUpdateProvider);
      expect(state.checking, isFalse);
      expect(state.checkedAt, result().checkedAt);
      expect(state.tagInstalled && state.wikiInstalled, isTrue);
      expect(state.wikiNeedsRefresh, isFalse);
      expect(jobs, isEmpty);
      expect(container.read(dictionaryRevisionProvider), 0);
    },
  );
  test(
    'failed checks retain the last successful sources, installation and time',
    () async {
      installed();
      ready();
      final controller = container.read(
        settingsDictionaryUpdateProvider.notifier,
      );
      var future = controller.check();
      await Future<void>.delayed(Duration.zero);
      checks.last.result.complete(result());
      await future;
      future = controller.check();
      await Future<void>.delayed(Duration.zero);
      checks.last.result.completeError(StateError('network fixture'));
      await future;
      final state = container.read(settingsDictionaryUpdateProvider);
      expect(state.checkFailed, isTrue);
      expect(state.checkedAt, result().checkedAt);
      expect(state.tagInstalled && state.wikiInstalled, isTrue);
      expect(jobs, isEmpty);
    },
  );
  test(
    'a legacy installed Wiki offers explicit refresh without claiming a new upstream file',
    () async {
      installed(wikiMerge: 1);
      ready();
      container.read(settingsDictionaryUpdateProvider);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final state = container.read(settingsDictionaryUpdateProvider);
      expect(state.wikiInstalled, isTrue);
      expect(state.wikiNeedsRefresh, isTrue);
    },
  );
  test(
    'a later process restores checked versions without contacting the network',
    () async {
      installed();
      await DictionaryUpdateChecker.save(root, result());
      ready();
      container.read(settingsDictionaryUpdateProvider);
      for (
        var i = 0;
        i < 20 &&
            container.read(settingsDictionaryUpdateProvider).checkedAt == null;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(
        container.read(settingsDictionaryUpdateProvider).checkedAt,
        result().checkedAt,
      );
      expect(checks, isEmpty);
      expect(jobs, isEmpty);
    },
  );

  test(
    'install uses the checked immutable source and announces changes only on success',
    () async {
      installed();
      ready();
      final controller = container.read(
        settingsDictionaryUpdateProvider.notifier,
      );
      final candidate = DictionarySource(
        DictionaryKind.tags,
        'https://raw.githubusercontent.com/DraconicDragon/dbr-e621-lists-archive/${'1' * 40}/tag-lists/danbooru/danbooru_2027-01-01_pt20-ia-dd.csv',
        '',
        1234,
        '2027-01-01',
        'Fixture',
        gitBlobSha1: 'a' * 40,
      );
      final check = controller.check();
      await Future<void>.delayed(Duration.zero);
      checks.single.result.complete(
        DictionaryCheckResult({
          ...dictionarySources,
          DictionaryKind.tags: candidate,
        }, checkedAt),
      );
      await check;
      expect(
        container.read(settingsDictionaryUpdateProvider).tagInstalled,
        isFalse,
      );
      final pending = controller.start(SettingsDictionaryKind.tags);
      expect(
        container.read(settingsDictionaryUpdateProvider).tagInstalledDate,
        '2026-10-01',
      );
      expect(
        container.read(settingsDictionaryUpdateProvider).tagDate,
        '2027-01-01',
      );
      await Future<void>.delayed(Duration.zero);
      expect(jobs.single.source, same(candidate));
      jobs.single.result.complete({'count': 5, 'added': 1, 'updated': 2});
      await pending;
      expect(container.read(settingsDictionaryUpdateProvider).updated, 2);
      expect(container.read(dictionaryRevisionProvider), 1);
    },
  );

  test(
    'upstream rollback cannot offer an older version over an installed dataset',
    () async {
      installed();
      store.records[DictionaryKind.tags]!['date'] = '2027-01-01';
      store.records[DictionaryKind.tags]!['sourceHash'] = 'a' * 64;
      ready();
      final controller = container.read(
        settingsDictionaryUpdateProvider.notifier,
      );
      final future = controller.check();
      await Future<void>.delayed(Duration.zero);
      checks.single.result.complete(result());
      await future;
      expect(
        container.read(settingsDictionaryUpdateProvider).checkFailed,
        isTrue,
      );
      expect(await DictionaryUpdateChecker.load(root), isNull);
      expect(jobs, isEmpty);
    },
  );

  test(
    'duplicate clicks share one job; progress and successful revision are projected',
    () async {
      ready();
      final controller = container.read(
        settingsDictionaryUpdateProvider.notifier,
      );
      final first = controller.start(SettingsDictionaryKind.tags);
      final second = controller.start(SettingsDictionaryKind.wiki);
      expect(identical(first, second), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(jobs, hasLength(1));
      await jobs.single.started.future;
      jobs.single.report(
        const DictionaryProgress(
          DictionaryPhase.downloading,
          received: 5,
          total: 10,
        ),
      );
      expect(container.read(settingsDictionaryUpdateProvider).received, 5);
      jobs.single.result.complete({'count': 5, 'added': 3});
      await first;
      final state = container.read(settingsDictionaryUpdateProvider);
      expect(state.phase, SettingsDictionaryPhase.done);
      expect(state.added, 3);
      expect(container.read(dictionaryRevisionProvider), 1);
    },
  );
  test(
    'cancel while resolving local data never starts a downloader or changes revision',
    () async {
      final controller = container.read(
        settingsDictionaryUpdateProvider.notifier,
      );
      final pending = controller.start(SettingsDictionaryKind.wiki);
      controller.cancel();
      ready();
      await pending;
      expect(jobs, isEmpty);
      expect(
        container.read(settingsDictionaryUpdateProvider).phase,
        SettingsDictionaryPhase.cancelled,
      );
      expect(container.read(dictionaryRevisionProvider), 0);
    },
  );
  test(
    'failure leaves a retryable status and does not announce a new data revision',
    () async {
      ready();
      final controller = container.read(
        settingsDictionaryUpdateProvider.notifier,
      );
      final pending = controller.start(SettingsDictionaryKind.tags);
      await Future<void>.delayed(Duration.zero);
      jobs.single.result.completeError(StateError('fixture failure'));
      await pending;
      expect(
        container.read(settingsDictionaryUpdateProvider).phase,
        SettingsDictionaryPhase.failed,
      );
      expect(container.read(dictionaryRevisionProvider), 0);
      final retry = controller.start(SettingsDictionaryKind.tags);
      await Future<void>.delayed(Duration.zero);
      expect(jobs, hasLength(2));
      controller.cancel();
      await retry;
      expect(
        container.read(settingsDictionaryUpdateProvider).phase,
        SettingsDictionaryPhase.cancelled,
      );
    },
  );
  test(
    'commit point cannot be cancelled after a verified database is ready',
    () async {
      ready();
      final controller = container.read(
        settingsDictionaryUpdateProvider.notifier,
      );
      final pending = controller.start(SettingsDictionaryKind.tags);
      await Future<void>.delayed(Duration.zero);
      jobs.single.report(const DictionaryProgress(DictionaryPhase.publishing));
      controller.cancel();
      expect(jobs.single.cancels, 0);
      jobs.single.result.complete({'count': 5, 'added': 3});
      await pending;
      expect(
        container.read(settingsDictionaryUpdateProvider).phase,
        SettingsDictionaryPhase.done,
      );
    },
  );
}
