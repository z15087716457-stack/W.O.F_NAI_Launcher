import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/database/dictionary_data_store.dart';
import 'package:nai_launcher/core/database/dictionary_downloader.dart';
import 'package:nai_launcher/core/database/dictionary_revision.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_dictionary_update.dart';

class _Job extends DictionaryDownloader {
  _Job(super.store);
  final started = Completer<void>();
  final result = Completer<Map<String, int>>();
  late void Function(DictionaryProgress) report;
  int cancels = 0;
  @override
  Future<Map<String, int>> install(
    DictionarySource source,
    String seed,
    void Function(DictionaryProgress) callback,
  ) {
    report = callback;
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

void main() {
  late ProviderContainer container;
  late Directory root;
  late Completer<DictionaryUpdateContext> context;
  late List<_Job> jobs;
  setUp(() {
    root = Directory.systemTemp.createTempSync('dictionary_wiring_');
    context = Completer();
    jobs = [];
    container = ProviderContainer(
      overrides: [
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
  void ready() => context.complete((
    store: DictionaryDataStore(root),
    seed: (_) async => 'fixture.db',
  ));

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
