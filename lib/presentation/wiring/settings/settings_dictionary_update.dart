import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/asset_database_manager.dart';
import '../../../core/database/dictionary_data_store.dart';
import '../../../core/database/dictionary_downloader.dart';
import '../../../core/database/dictionary_revision.dart';
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

class SettingsDictionaryUpdater extends Notifier<SettingsDictionaryUpdate> {
  DictionaryDownloader? _job;
  DictionaryDataStore? _store;
  bool _disposed = false, _cancelled = false;
  Future<void>? _running;
  @override
  SettingsDictionaryUpdate build() {
    final unregister = DesktopAppShutdownService.registerCleanup(() async {
      _job?.cancel();
      await _running;
    });
    ref.onDispose(() {
      _disposed = true;
      unregister();
      _job?.cancel();
    });
    final load = ref.read(dictionaryUpdateContextProvider);
    scheduleMicrotask(() async {
      try {
        _store = (await load()).store;
        if (!_disposed && state.phase == SettingsDictionaryPhase.idle) {
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
    bool cancelling = false,
  }) => SettingsDictionaryUpdate(
    kind: kind,
    phase: phase,
    received: received,
    total: total,
    rows: rows,
    added: added,
    cancelling: cancelling,
    tagInstalled:
        _store?.record(DictionaryKind.tags)?['sourceHash'] ==
        dictionarySources[DictionaryKind.tags]!.sha256,
    wikiInstalled:
        _store?.record(DictionaryKind.wiki)?['sourceHash'] ==
        dictionarySources[DictionaryKind.wiki]!.sha256,
    tagDate: dictionarySources[DictionaryKind.tags]!.date,
    wikiDate: dictionarySources[DictionaryKind.wiki]!.date,
    tagSource: dictionarySources[DictionaryKind.tags]!.name,
    wikiSource: dictionarySources[DictionaryKind.wiki]!.name,
  );
  Future<void> start(SettingsDictionaryKind kind) {
    if (state.busy) return _running ?? Future.value();
    _cancelled = false;
    state = _view(kind: kind, phase: SettingsDictionaryPhase.downloading);
    return _running = _install(kind);
  }

  Future<void> _install(SettingsDictionaryKind kind) async {
    try {
      final context = await ref.read(dictionaryUpdateContextProvider)();
      _store = context.store;
      if (_cancelled || _disposed) return;
      final coreKind = DictionaryKind.values.byName(kind.name);
      final seed = await context.seed(coreKind);
      if (_cancelled || _disposed) return;
      final job = _job = ref.read(dictionaryDownloaderFactoryProvider)(_store!);
      final result = await job.install(dictionarySources[coreKind]!, seed, (p) {
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
