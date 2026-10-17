import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/asset_database_manager.dart';
import '../../../core/database/dictionary_data_store.dart';
import '../../../core/database/dictionary_downloader.dart';
import '../../../core/database/dictionary_revision.dart';
import '../../../core/database/dictionary_update_checker.dart';
import '../../../core/services/desktop_app_shutdown_service.dart';
import '../../ui/settings/settings_contract.dart';
import 'settings_inventory.dart';

typedef DictionaryUpdateContext = ({
  DictionaryDataStore store,
  Future<String> Function(DictionaryKind) seed,
});
final dictionaryUpdateContextProvider =
    Provider<Future<DictionaryUpdateContext> Function()>(
      (ref) => () async {
        final manager = AssetDatabaseManager.instance;
        final store = await manager.dictionaryStore();
        await manager.ensureTagWikiDb();
        return (
          store: store,
          seed: (kind) async => kind == DictionaryKind.tags
              ? manager.tagCatalogDbPath
              : await manager.ensureTagWikiDb(),
        );
      },
    );
final dictionaryDownloaderFactoryProvider =
    Provider<DictionaryDownloader Function(DictionaryDataStore)>(
      (ref) =>
          (store) => DictionaryDownloader(store),
    );
final settingsDictionaryUpdateProvider =
    NotifierProvider<SettingsDictionaryUpdater, SettingsDictionaryUpdate>(
      SettingsDictionaryUpdater.new,
    );
final dictionaryUpdateCheckerFactoryProvider =
    Provider<DictionaryUpdateChecker Function()>(
      (ref) =>
          () => DictionaryUpdateChecker(),
    );

class SettingsDictionaryUpdater extends Notifier<SettingsDictionaryUpdate> {
  DictionaryDownloader? _job;
  DictionaryDataStore? _store;
  bool _disposed = false, _cancelled = false;
  Future<void>? _running;
  Future<void>? _checking;
  DictionaryUpdateChecker? _checker;
  DictionaryCheckResult? _checked;
  bool _checkFailed = false;
  Map<DictionaryKind, DictionarySource> get _sources =>
      _checked?.sources ?? dictionarySources;
  @override
  SettingsDictionaryUpdate build() {
    final unregister = DesktopAppShutdownService.registerCleanup(() async {
      _job?.cancel();
      _checker?.cancel();
      await _running;
      await _checking;
    });
    ref.onDispose(() {
      _disposed = true;
      unregister();
      _job?.cancel();
      _checker?.cancel();
    });
    final load = ref.read(dictionaryUpdateContextProvider);
    scheduleMicrotask(() async {
      try {
        _store = (await load()).store;
        final cached = await DictionaryUpdateChecker.load(_store!.root);
        if (!_disposed && _checked == null && _checking == null) {
          _checked = cached;
        }
        if (!_disposed &&
            state.phase == SettingsDictionaryPhase.idle &&
            _checking == null) {
          state = _view();
        }
      } catch (_) {
        /* A click can retry unavailable local data. */
      }
    });
    return _view();
  }

  SettingsDictionaryUpdate _view({
    SettingsDictionaryKind? kind,
    SettingsDictionaryPhase phase = SettingsDictionaryPhase.idle,
    int received = 0,
    int total = 0,
    int rows = 0,
    int added = 0,
    int updated = 0,
    bool cancelling = false,
  }) => SettingsDictionaryUpdate(
    kind: kind,
    phase: phase,
    received: received,
    total: total,
    rows: rows,
    added: added,
    updated: updated,
    cancelling: cancelling,
    tagInstalled: _sources[DictionaryKind.tags]!.matches(
      _store?.record(DictionaryKind.tags),
    ),
    wikiInstalled: _sources[DictionaryKind.wiki]!.matches(
      _store?.record(DictionaryKind.wiki),
    ),
    wikiNeedsRefresh:
        _sources[DictionaryKind.wiki]!.matches(
          _store?.record(DictionaryKind.wiki),
        ) &&
        ((_store?.record(DictionaryKind.wiki)?['mergeVersion'] as int?) ?? 1) <
            2,
    tagDate: _sources[DictionaryKind.tags]!.date,
    wikiDate: _sources[DictionaryKind.wiki]!.date,
    tagSource: _sources[DictionaryKind.tags]!.name,
    wikiSource: _sources[DictionaryKind.wiki]!.name,
    tagBytes: _sources[DictionaryKind.tags]!.bytes,
    wikiBytes: _sources[DictionaryKind.wiki]!.bytes,
    tagInstalledDate:
        _store?.record(DictionaryKind.tags)?['date'] as String? ?? '',
    wikiInstalledDate:
        _store?.record(DictionaryKind.wiki)?['date'] as String? ?? '',
    checking: _checking != null,
    checkFailed: _checkFailed,
    checkedAt: _checked?.checkedAt,
  );

  Future<void> check() {
    if (_checking != null) return _checking!;
    if (state.busy) return _running ?? Future.value();
    _checkFailed = false;
    _checking = _check();
    state = _view();
    return _checking!;
  }

  Future<void> _check() async {
    final checker = _checker = ref.read(
      dictionaryUpdateCheckerFactoryProvider,
    )();
    try {
      final context = await ref.read(dictionaryUpdateContextProvider)();
      if (_disposed) return;
      _store = context.store;
      final result = await checker.check();
      if (_disposed) return;
      for (final source in result.sources.values) {
        final record = _store!.record(source.kind);
        if (record != null &&
            !source.matches(record) &&
            source.date.compareTo(record['date'] as String? ?? '') < 0) {
          throw StateError('dictionary_downgrade');
        }
      }
      await DictionaryUpdateChecker.save(_store!.root, result);
      if (!_disposed) _checked = result;
    } catch (_) {
      if (!_disposed) _checkFailed = true;
    } finally {
      checker.close();
      _checker = null;
      _checking = null;
      if (!_disposed) state = _view();
    }
  }

  Future<void> start(SettingsDictionaryKind kind) {
    if (state.busy || _checking != null) {
      return _running ?? _checking ?? Future.value();
    }
    _cancelled = false;
    state = _view(kind: kind, phase: SettingsDictionaryPhase.downloading);
    return _running = _install(
      kind,
      _sources[DictionaryKind.values.byName(kind.name)]!,
    );
  }

  Future<void> _install(
    SettingsDictionaryKind kind,
    DictionarySource source,
  ) async {
    try {
      final context = await ref.read(dictionaryUpdateContextProvider)();
      _store = context.store;
      if (_cancelled || _disposed) return;
      final coreKind = DictionaryKind.values.byName(kind.name);
      final seed = await context.seed(coreKind);
      if (_cancelled || _disposed) return;
      final job = _job = ref.read(dictionaryDownloaderFactoryProvider)(_store!);
      final result = await job.install(source, seed, (p) {
        if (!_disposed) {
          state = _view(
            kind: kind,
            phase: SettingsDictionaryPhase.values.byName(p.phase.name),
            received: p.received,
            total: p.total,
            rows: p.rows,
            cancelling: _cancelled,
          );
        }
      });
      if (!_disposed) {
        state = _view(
          kind: kind,
          phase: SettingsDictionaryPhase.done,
          added: result['added']!,
          updated: result['updated'] ?? 0,
        );
        ref.invalidate(settingsDictionaryDataProvider);
        ref.read(dictionaryRevisionProvider.notifier).state++;
      }
    } catch (_) {
      if (!_disposed) {
        state = _view(
          kind: kind,
          phase: _cancelled
              ? SettingsDictionaryPhase.cancelled
              : SettingsDictionaryPhase.failed,
        );
      }
    } finally {
      _job = null;
      if (!_disposed && _cancelled && state.busy) {
        state = _view(kind: kind, phase: SettingsDictionaryPhase.cancelled);
      }
    }
  }

  void cancel() {
    if (!state.busy || state.phase == SettingsDictionaryPhase.publishing) {
      return;
    }
    _cancelled = true;
    _job?.cancel();
    state = _view(
      kind: state.kind,
      phase: state.phase,
      received: state.received,
      total: state.total,
      rows: state.rows,
      cancelling: true,
    );
  }
}
