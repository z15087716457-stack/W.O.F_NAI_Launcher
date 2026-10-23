import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:nai_launcher/core/utils/app_support_directory.dart';
import '../../core/autocomplete/completion_models.dart';
import '../../core/database/asset_database_manager.dart';
import '../../core/tag_expansion/tag_semantics_store.dart';
import '../../core/rag/rag_client.dart';
import '../../core/rag/rag_maintenance.dart';
import '../../core/rag/rag_settings.dart';
import '../../core/rag/rag_runtime.dart';
import '../../core/rag/rag_runtime_probe.dart';
import '../../core/rag/rag_text_search.dart';
import '../../core/rag/rag_block_snapshot.dart';
import '../../core/rag/rag_gallery_search.dart';
import '../../data/repositories/gallery_folder_repository.dart';
import 'prompt_block_library_provider.dart';
import '../../core/services/desktop_app_shutdown_service.dart';

class RagStatus {
  const RagStatus({
    this.phase = 'off',
    this.indexed = 0,
    this.processed = 0,
    this.total = 0,
    this.bytes = 0,
    this.jobId,
    this.error,
    this.busy = false,
    this.complete = false,
    this.partial = false,
    this.suspended = false,
    this.searching = 0,
    this.installPhase,
    this.installElapsed = 0,
    this.installDetail = '',
    this.sources = const {},
    this.runtimeReady = false,
    this.details = const {},
    this.indexKnown = false,
    this.initializing = false,
    this.initializationPhase = '',
    this.initializationProcessed = 0,
    this.initializationTotal = 0,
  });
  final String phase;
  final int indexed, processed, total, bytes, searching;
  final String? jobId, error, installPhase;
  final bool busy, complete, partial, suspended;
  final bool runtimeReady;
  final int installElapsed;
  final String installDetail;
  final Map<RagSource, RagStatus> sources;
  final Map<String, int> details;
  final bool indexKnown, initializing;
  final String initializationPhase;
  final int initializationProcessed, initializationTotal;
  bool get hasIndexStatus => indexKnown || indexed > 0 || total > 0 || complete;
  RagStatus forSource(RagSource source) => source == RagSource.tags
      ? this
      : (sources[source] ?? const RagStatus()).copyWith(suspended: suspended);
  bool get anyBusy => busy || sources.values.any((s) => s.busy);
  bool get available =>
      indexed > 0 && error == null && !suspended && phase != 'off';
  RagStatus copyWith({
    String? phase,
    int? indexed,
    int? processed,
    int? total,
    int? bytes,
    String? jobId,
    String? error,
    bool clearError = false,
    bool clearJob = false,
    bool? busy,
    bool? complete,
    bool? partial,
    bool? suspended,
    int? searching,
    String? installPhase,
    int? installElapsed,
    String? installDetail,
    bool clearInstall = false,
    Map<RagSource, RagStatus>? sources,
    bool? runtimeReady,
    Map<String, int>? details,
    bool? indexKnown,
    bool? initializing,
    String? initializationPhase,
    int? initializationProcessed,
    int? initializationTotal,
  }) => RagStatus(
    phase: phase ?? this.phase,
    indexed: indexed ?? this.indexed,
    processed: processed ?? this.processed,
    total: total ?? this.total,
    bytes: bytes ?? this.bytes,
    jobId: clearJob ? null : jobId ?? this.jobId,
    error: clearError ? null : error ?? this.error,
    busy: busy ?? this.busy,
    complete: complete ?? this.complete,
    partial: partial ?? this.partial,
    suspended: suspended ?? this.suspended,
    searching: searching ?? this.searching,
    installPhase: clearInstall ? null : installPhase ?? this.installPhase,
    installElapsed: clearInstall ? 0 : installElapsed ?? this.installElapsed,
    installDetail: installDetail ?? this.installDetail,
    sources: sources ?? this.sources,
    runtimeReady: runtimeReady ?? this.runtimeReady,
    details: details ?? this.details,
    indexKnown: indexKnown ?? this.indexKnown,
    initializing: initializing ?? this.initializing,
    initializationPhase: initializationPhase ?? this.initializationPhase,
    initializationProcessed:
        initializationProcessed ?? this.initializationProcessed,
    initializationTotal: initializationTotal ?? this.initializationTotal,
  );
}

final ragDirectoryProvider = Provider<Future<Directory> Function()>(
  (ref) =>
      () async => Directory(
        p.join((await getApplicationSupportDirectory()).path, 'rag', 'v1'),
      ),
);
final ragControllerProvider = NotifierProvider<RagController, RagStatus>(
  RagController.new,
);
final ragStatusTimeoutProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 60),
);
final ragInitializationTimeoutProvider = Provider<Duration>(
  (ref) => const Duration(minutes: 15),
);
final ragInitializationIdleTimeoutProvider = Provider<Duration>(
  (ref) => const Duration(minutes: 2),
);

typedef RagClientStarter =
    Future<RagClient> Function({
      required String python,
      required Directory directory,
    });
final ragClientStarterProvider = Provider<RagClientStarter>(
  (ref) => RagClient.start,
);
final ragGalleryRootsProvider = Provider<Future<List<String>> Function()>(
  (ref) =>
      () async => [
        for (final root
            in await GalleryFolderRepository.instance.getAllRootDirs())
          root.path,
      ],
);
typedef RagSourcePaths = ({String catalog, String runtime, String wiki});
final ragSourcePathsProvider = Provider<Future<RagSourcePaths> Function()>(
  (ref) => () async {
    await AssetDatabaseManager.initialize();
    final support = await getApplicationSupportDirectory();
    final runtime = File(p.join(support.path, 'databases', 'danbooru.db'));
    return (
      catalog: AssetDatabaseManager.instance.tagCatalogDbPath,
      runtime: await runtime.exists() ? runtime.path : '',
      wiki: await AssetDatabaseManager.instance.ensureTagWikiDb(),
    );
  },
);

final ragWikiTranslationsPathProvider = Provider<Future<String> Function()>(
  (ref) => () async {
    final root = await ref.read(ragDirectoryProvider)();
    return p.join(
      p.dirname(p.dirname(root.path)),
      'autocomplete',
      'visible_tag_translations.db',
    );
  },
);

final ragTagSemanticsPathsProvider =
    Provider<Future<({String base, String supplements})> Function()>(
      (ref) =>
          () async => (
            base: await AssetDatabaseManager.instance.ensureTagSemanticsDb(),
            supplements: await ref.read(tagSemanticsStoreProvider).readyPath(),
          ),
    );

final ragRuntimeProbeFactoryProvider = Provider<RagRuntimeProbe Function()>(
  (ref) =>
      () => RagRuntimeProbe(),
);
// Compatibility belongs to the selected interpreter, not the settings page's
// lifetime. Explicit recheck/install/path changes still invalidate this probe.
final ragRuntimeInfoProvider = FutureProvider.autoDispose<RagRuntimeInfo>((
  ref,
) async {
  final python = ref.watch(ragSettingsProvider.select((s) => s.python));
  final probe = ref.read(ragRuntimeProbeFactoryProvider)();
  var disposed = false;
  ref.onDispose(() {
    disposed = true;
    probe.cancel();
  });
  final root = await ref.read(ragDirectoryProvider)();
  final result = await probe.inspect(root, python);
  // A failed/transient probe remains retryable on reopening settings.
  if (result.ready && !disposed) {
    ref.keepAlive();
  }
  return result;
});

class RagController extends Notifier<RagStatus> {
  RagClient? _client;
  Future<RagClient>? _connecting;
  RagClient? _openingClient;
  ({RagClient client, Map<String, dynamic> status})? _configuration;
  RagCancellation? _initializationCancellation;
  StreamSubscription<Map<String, dynamic>>? _events;
  Timer? _refresh;
  RagRuntimeInstaller? _installer;
  bool _runtimeInstallCancelled = false;
  bool _disposed = false;
  int _epoch = 0, _gpuHolds = 0;

  /// Includes holds acquired before a worker exists (suspended can still be false).
  bool get isGpuBusy => _gpuHolds > 0;
  final _finishedJobs = <String>{};
  Future<void> _snapshotWrites = Future.value();
  Future<void> _retiring = Future.value();
  Object? _refreshToken;
  final _plans = <String, ({RagSource source, int epoch, DateTime expires})>{};

  Future<T> _maintain<T>(Future<T> Function() action) async {
    final release = ref
        .read(ragMaintenanceProvider)
        .claim(indexBusy: state.anyBusy || state.installPhase != null);
    try {
      return await action();
    } finally {
      release();
    }
  }

  @override
  RagStatus build() {
    final unregister = DesktopAppShutdownService.registerCleanup(() async {
      _disposed = true;
      _epoch++;
      _refresh?.cancel();
      _installer?.cancel();
      _initializationCancellation?.cancel();
      await _openingClient?.close();
      await _client?.close();
      await _retiring;
      final opening = _connecting;
      if (opening != null) {
        try {
          await (await opening.timeout(const Duration(seconds: 3))).close();
        } catch (_) {}
      }
    });
    ref.listen(ragSettingsProvider, (previous, next) {
      if (previous?.connectionKey != next.connectionKey) unawaited(_reset());
    });
    ref.onDispose(() {
      unregister();
      _disposed = true;
      _epoch++;
      _refresh?.cancel();
      unawaited(_events?.cancel());
      _initializationCancellation?.cancel();
      unawaited(_openingClient?.close());
      unawaited(_client?.close());
      _installer?.dispose();
    });
    scheduleMicrotask(() {
      if (!_disposed && _enabled) unawaited(refresh());
    });
    return const RagStatus();
  }

  bool get _enabled {
    final s = ref.read(ragSettingsProvider);
    return RagSource.values.any(s.enabledFor);
  }

  Future<void> _reset() async {
    final epoch = ++_epoch;
    _refresh?.cancel();
    _connecting = null;
    _initializationCancellation?.cancel();
    final opening = _openingClient;
    _openingClient = null;
    _refreshToken = null;
    _finishedJobs.clear();
    _plans.clear();
    final old = _client;
    _client = null;
    _configuration = null;
    final events = _events;
    final previousRetirement = _retiring;
    final retirement = _retiring = () async {
      await previousRetirement;
      await events?.cancel();
      await opening?.close();
      await old?.close();
    }();
    await retirement;
    if (_disposed || epoch != _epoch) return;
    state = RagStatus(
      installPhase: state.installPhase,
      installElapsed: state.installElapsed,
      installDetail: state.installDetail,
    );
    if (_enabled) await refresh();
  }

  Future<RagClient> _connect() {
    if (!_enabled) return Future.error(const RagException('disabled'));
    if (_client case final client? when !client.isClosed) {
      return Future.value(client);
    }
    if (_connecting case final pending?) return pending;
    final epoch = _epoch;
    late final Future<RagClient> attempt;
    attempt =
        () async {
          await _retiring;
          if (_disposed || epoch != _epoch) {
            throw const RagException('cancelled');
          }
          if (!_enabled) throw const RagException('disabled');
          return _open();
        }().whenComplete(() {
          if (identical(_connecting, attempt)) _connecting = null;
        });
    return _connecting = attempt;
  }

  Future<RagClient> _open() async {
    final epoch = _epoch;
    final settings = ref.read(ragSettingsProvider);
    final cancellation = _initializationCancellation = RagCancellation();
    state = state.copyWith(
      initializing: true,
      initializationPhase: 'opening',
      initializationProcessed: 0,
      initializationTotal: 0,
    );
    try {
      final root = await ref.read(ragDirectoryProvider)();
      final python = settings.python.isEmpty
          ? p.join(root.path, 'runtime', 'Scripts', 'python.exe')
          : settings.python;
      if (!await File(python).exists()) {
        throw const RagException('runtime_missing');
      }
      if (settings.embedding.isEmpty || settings.reranker.isEmpty) {
        throw const RagException('models_missing');
      }
      if (!_disposed && epoch == _epoch) {
        for (final source in RagSource.values.where(settings.enabledFor)) {
          _change(
            source,
            (s) => s.copyWith(phase: 'loading', clearError: true),
          );
        }
      }
      final paths = await ref.read(ragSourcePathsProvider)();
      final snapshot = settings.blocksEnabled
          ? await _writeBlockSnapshot(root)
          : '';
      final galleryRoots = settings.galleryEnabled
          ? await _writeGalleryRoots(root)
          : '';
      final tagPaths = settings.tagsEnabled
          ? await ref.read(ragTagSemanticsPathsProvider)()
          : null;
      final client = await ref.read(ragClientStarterProvider)(
        python: python,
        directory: root,
      );
      if (_disposed || epoch != _epoch || cancellation.isCancelled) {
        await client.close();
        throw const RagException('cancelled');
      }
      _openingClient = client;
      try {
        final result = await client.configure(
          {
            'embedding': settings.embedding,
            'reranker': settings.reranker,
            'device': settings.device.name,
            'directory': p.join(root.path, 'indices'),
            'catalog': paths.catalog,
            'runtime': paths.runtime,
            'wiki': paths.wiki,
            if (tagPaths != null) 'tag_semantics': tagPaths.base,
            if (tagPaths != null && await File(tagPaths.supplements).exists())
              'tag_supplements': tagPaths.supplements,
            'translations': await ref.read(ragWikiTranslationsPathProvider)(),
            'blocks': snapshot,
            'gallery_roots': galleryRoots,
            'sources': [
              for (final source in RagSource.values)
                if (settings.enabledFor(source)) source.name,
            ],
          },
          cancellation: cancellation,
          timeout: ref.read(ragInitializationTimeoutProvider),
          idleTimeout: ref.read(ragInitializationIdleTimeoutProvider),
          onProgress: (event) {
            if (_disposed || epoch != _epoch || cancellation.isCancelled) {
              return;
            }
            state = state.copyWith(
              initializationPhase: event['phase'] as String? ?? 'opening',
              initializationProcessed:
                  (event['processed'] as num?)?.toInt() ?? 0,
              initializationTotal: (event['total'] as num?)?.toInt() ?? 0,
            );
          },
        );
        if (_disposed || epoch != _epoch) throw const RagException('cancelled');
        if (client.isClosed) throw const RagException('worker_closed');
        unawaited(_events?.cancel());
        _client = client;
        _events = client.events.listen((event) {
          if (_disposed || epoch != _epoch || !identical(_client, client)) {
            return;
          }
          if (event['event'] == 'lost') {
            for (final source in RagSource.values) {
              _change(
                source,
                (s) => s.copyWith(
                  phase: 'error',
                  error: 'worker_closed',
                  busy: false,
                  clearJob: true,
                ),
              );
            }
            state = state.copyWith(runtimeReady: false);
            return;
          }
          if (event['event'] == 'index') {
            final source = RagSource.values.firstWhere(
              (s) => s.name == event['source'],
              orElse: () => RagSource.tags,
            );
            if (['complete', 'error'].contains(event['phase'])) {
              _finishedJobs.add(event['job_id'] as String);
              if (_finishedJobs.length > 32) {
                _finishedJobs.remove(_finishedJobs.first);
              }
            }
            _applyIndex(event, source);
            _change(
              source,
              (s) => s.copyWith(
                jobId: event['job_id'] as String?,
                phase: event['phase'] == 'complete'
                    ? (s.complete ? 'ready' : 'partial')
                    : event['phase'] as String?,
                busy: const {'building', 'checking'}.contains(event['phase']),
                clearJob: ['complete', 'error'].contains(event['phase']),
                error: event['code'] as String?,
                clearError: event['phase'] != 'error',
              ),
            );
          }
        });
        _apply(result);
        _configuration = (client: client, status: result);
        state = state.copyWith(initializing: false);
        _refresh?.cancel();
        _refresh = Timer.periodic(const Duration(seconds: 30), (_) {
          if (!_disposed) unawaited(refresh(autoUpdate: true));
        });
        if (_gpuHolds > 0) {
          state = state.copyWith(suspended: true);
          await client.request('suspend');
        }
        return client;
      } catch (_) {
        await client.close();
        rethrow;
      } finally {
        if (identical(_openingClient, client)) _openingClient = null;
      }
    } finally {
      if (identical(_initializationCancellation, cancellation)) {
        _initializationCancellation = null;
        if (!_disposed && epoch == _epoch) {
          state = state.copyWith(initializing: false);
        }
      }
    }
  }

  void _apply(Map<String, dynamic> result) {
    if (_disposed) return;
    if (result['sources'] case final Map sources) {
      for (final source in RagSource.values) {
        if (sources[source.name] case final Map value) {
          _applyIndex(value.cast<String, dynamic>(), source);
        } else {
          _change(
            source,
            (s) => s.copyWith(phase: 'off', busy: false, clearJob: true),
          );
        }
      }
      final jobs = result['jobs'] as List? ?? const [];
      for (final source in RagSource.values) {
        final job = jobs
            .cast<Map>()
            .where((j) => j['source'] == source.name)
            .firstOrNull;
        _change(
          source,
          (s) =>
              s.copyWith(jobId: job?['id'] as String?, clearJob: job == null),
        );
      }
      state = state.copyWith(
        suspended: result['suspended'] as bool? ?? false,
        runtimeReady: true,
      );
    } else {
      _applyIndex(result, RagSource.tags);
    }
  }

  void _change(RagSource source, RagStatus Function(RagStatus) update) {
    if (_disposed) return;
    if (source == RagSource.tags) {
      state = update(state);
    } else {
      state = state.copyWith(
        sources: {...state.sources, source: update(state.forSource(source))},
      );
    }
  }

  void _applyIndex(Map<String, dynamic> result, RagSource source) {
    _change(
      source,
      (s) => s.copyWith(
        indexKnown: true,
        indexed: (result['indexed'] as num?)?.toInt(),
        processed: (result['processed'] as num?)?.toInt(),
        total: (result['total'] as num?)?.toInt(),
        bytes: (result['bytes'] as num?)?.toInt(),
        complete: result['complete'] as bool?,
        partial: result['partial'] as bool?,
        busy: result['building'] == true || result['checking'] == true,
        details: {
          for (final key in [
            'images',
            'visual_indexed',
            'parameter_chunks',
            'parameters_indexed',
            'skipped',
          ])
            if (result[key] is num) key: (result[key] as num).toInt(),
        },
        phase: result['paused'] == true
            ? 'paused'
            : result['building'] == true
            ? 'building'
            : result['checking'] == true
            ? 'checking'
            : result['complete'] == true
            ? 'ready'
            : (result['indexed'] as num? ?? 0) > 0
            ? 'partial'
            : 'empty',
        clearError: true,
      ),
    );
    if (result['paused'] == true) {
      _change(source, (s) => s.copyWith(busy: false));
    }
  }

  void _fail(Object error, {RagSource source = RagSource.tags}) {
    if (_disposed) return;
    _change(
      source,
      (s) => s.copyWith(
        phase: 'error',
        error: error is RagException ? error.code : 'rag_runtime_error',
        busy: false,
      ),
    );
  }

  Future<void> refresh({bool autoUpdate = false}) async {
    if (!_enabled ||
        _disposed ||
        _refreshToken != null ||
        ref.read(ragMaintenanceProvider).busy ||
        state.installPhase != null) {
      return;
    }
    final refreshToken = _refreshToken = Object();
    final epoch = _epoch;
    try {
      final previousClient = _client;
      final c = await _connect();
      if (_disposed || epoch != _epoch) return;
      // A refresh waiting for a new connection already received authoritative
      // status and snapshots from configure. Existing connections still refresh
      // normally; never replay an old configure result over live index events.
      final configured =
          !identical(previousClient, c) && identical(_configuration?.client, c)
          ? _configuration?.status
          : null;
      final Map<String, dynamic> status;
      if (configured != null) {
        status = configured;
      } else {
        if (ref.read(ragSettingsProvider).enabledFor(RagSource.blocks)) {
          await _writeBlockSnapshot(await ref.read(ragDirectoryProvider)());
        }
        if (ref.read(ragSettingsProvider).enabledFor(RagSource.gallery)) {
          await _writeGalleryRoots(await ref.read(ragDirectoryProvider)());
        }
        status = await c.request(
          'status',
          const {},
          null,
          ref.read(ragStatusTimeoutProvider),
        );
        if (_disposed || epoch != _epoch) return;
        _apply(status);
      }
      final sources = status['sources'] as Map? ?? {'tags': status};
      for (final source in RagSource.values) {
        final value = sources[source.name] as Map?;
        if (autoUpdate &&
            !state.anyBusy &&
            value?['auto_update_allowed'] == true &&
            value?['complete'] != true &&
            state.forSource(source).jobId == null &&
            !state.suspended &&
            _gpuHolds == 0 &&
            ref.read(ragSettingsProvider).enabledFor(source)) {
          final plan = await preview(source: source);
          await start(plan['plan_id'] as String, source: source);
        }
      }
    } catch (error) {
      // The worker serializes inference and status. A heartbeat queued behind
      // an active search timing out does not invalidate that search's results.
      if (error is RagException &&
          error.code == 'timeout' &&
          (state.anyBusy ||
              RagSource.values.any((s) => state.forSource(s).searching > 0))) {
        return;
      }
      if (epoch == _epoch) {
        for (final source in RagSource.values) {
          if (ref.read(ragSettingsProvider).enabledFor(source)) {
            _fail(error, source: source);
          }
        }
      }
    } finally {
      if (identical(_refreshToken, refreshToken)) _refreshToken = null;
    }
  }

  Future<Map<String, dynamic>> preview({RagSource source = RagSource.tags}) =>
      _maintain(() => _preview(source));

  void discardPlan(String id) => _plans.remove(id);

  Future<Map<String, dynamic>> _preview(RagSource source) async {
    final epoch = _epoch;
    final c = await _connect();
    if (source == RagSource.blocks) {
      await _writeBlockSnapshot(await ref.read(ragDirectoryProvider)());
    }
    if (source == RagSource.gallery) {
      await _writeGalleryRoots(await ref.read(ragDirectoryProvider)());
    }
    final plan = await c.request('preview', {'source': source.name});
    if (_disposed || epoch != _epoch) throw const RagException('cancelled');
    _plans.removeWhere((_, value) => value.source == source);
    _plans[plan['plan_id'] as String] = (
      source: source,
      epoch: epoch,
      expires: DateTime.now().add(const Duration(minutes: 29)),
    );
    return plan;
  }

  Future<void> start(
    String planId, {
    bool rebuild = false,
    RagSource source = RagSource.tags,
  }) => _maintain(() => _start(planId, rebuild: rebuild, source: source));

  Future<void> _start(
    String planId, {
    required bool rebuild,
    required RagSource source,
  }) async {
    final epoch = _epoch;
    final plan = _plans[planId];
    if (plan == null ||
        plan.source != source ||
        plan.epoch != epoch ||
        plan.expires.isBefore(DateTime.now())) {
      throw const RagException('invalid_plan');
    }
    try {
      final c = await _connect();
      if (_disposed ||
          epoch != _epoch ||
          !ref.read(ragSettingsProvider).enabledFor(source)) {
        throw const RagException('cancelled');
      }
      _plans.remove(planId);
      final result = await c.request('start', {
        'plan_id': planId,
        'source': source.name,
        'rebuild': rebuild,
      });
      if (!_disposed &&
          epoch == _epoch &&
          !_finishedJobs.contains(result['job_id']) &&
          state.forSource(source).jobId != result['job_id']) {
        _change(
          source,
          (s) => s.copyWith(
            jobId: result['job_id'] as String,
            phase: 'checking',
            processed: 0,
            busy: true,
            clearError: true,
          ),
        );
      }
    } catch (error) {
      if (epoch == _epoch) _fail(error, source: source);
      rethrow;
    }
  }

  Future<void> pause({RagSource source = RagSource.tags}) async {
    final epoch = _epoch;
    final id = state.forSource(source).jobId;
    if (id == null) return;
    await (await _connect()).request('pause', {
      'job_id': id,
      'source': source.name,
    });
    if (!_disposed && epoch == _epoch) {
      _change(source, (s) => s.copyWith(phase: 'paused', busy: false));
    }
  }

  Future<void> resume({RagSource source = RagSource.tags}) =>
      _maintain(() => _resume(source));

  Future<void> _resume(RagSource source) async {
    final epoch = _epoch;
    final id = state.forSource(source).jobId;
    if (id == null) {
      final p = await _preview(source);
      await _start(p['plan_id'] as String, rebuild: false, source: source);
      return;
    }
    final client = await _connect();
    if (_disposed ||
        epoch != _epoch ||
        !ref.read(ragSettingsProvider).enabledFor(source)) {
      throw const RagException('cancelled');
    }
    await client.request('resume', {'job_id': id, 'source': source.name});
    if (!_disposed && epoch == _epoch) {
      _change(source, (s) => s.copyWith(phase: 'checking', busy: true));
    }
  }

  Future<void> clear({RagSource source = RagSource.tags}) =>
      _maintain(() => _clear(source));

  Future<void> _clear(RagSource source) async {
    final epoch = _epoch;
    final c = await _connect();
    if (_disposed ||
        epoch != _epoch ||
        !ref.read(ragSettingsProvider).enabledFor(source)) {
      throw const RagException('cancelled');
    }
    final result = await c.request('clear', {'source': source.name});
    if (_disposed || epoch != _epoch) return;
    _applyIndex(result, source);
    _change(source, (s) => s.copyWith(clearJob: true));
    _plans.removeWhere((_, plan) => plan.source == source);
  }

  Future<void> suspendForGpu() async {
    _gpuHolds++;
    final c = _client;
    if (c == null) return;
    try {
      await c.request('suspend', {}, null, const Duration(seconds: 15));
    } catch (_) {
      await c.close();
      _client = null;
    }
    if (!_disposed) state = state.copyWith(suspended: true);
  }

  Future<void> releaseGpu() async {
    if (_gpuHolds > 0) _gpuHolds--;
    if (_gpuHolds != 0) return;
    final c = _client;
    if (c != null && !c.isClosed) await c.request('release');
    if (!_disposed) state = state.copyWith(suspended: false);
  }

  Future<String> _writeBlockSnapshot(Directory root) async {
    final epoch = _epoch;
    final library = await ref.read(promptBlockLibraryNotifierProvider.future);
    final content = encodeRagBlocks(library.blocks);
    final file = File(p.join(root.path, 'sources', 'blocks.json'));
    final write = _snapshotWrites.catchError((Object _) {}).then((_) async {
      if (_disposed || epoch != _epoch) throw const RagException('cancelled');
      await file.parent.create(recursive: true);
      if (await file.exists() && await file.readAsString() == content) return;
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(content, flush: true);
      if (_disposed || epoch != _epoch) throw const RagException('cancelled');
      await temporary.rename(file.path);
    });
    _snapshotWrites = write;
    await write;
    return file.path;
  }

  Future<List<RagSearchHit>> searchText(
    RagTextQuery query, {
    required RagCancellation cancellation,
  }) async {
    if ((query.source != RagSource.wiki && query.source != RagSource.blocks) ||
        query.query.trim().isEmpty ||
        !ref.read(ragSettingsProvider).enabledFor(query.source) ||
        _gpuHolds > 0) {
      return const [];
    }
    final epoch = _epoch;
    var counted = false;
    try {
      final c = await _connect();
      if (query.source == RagSource.blocks) {
        await _writeBlockSnapshot(await ref.read(ragDirectoryProvider)());
      }
      if (cancellation.isCancelled || _disposed || epoch != _epoch) {
        return const [];
      }
      counted = true;
      _change(query.source, (s) => s.copyWith(searching: s.searching + 1));
      final result = await c.request('text_search', {
        'source': query.source.name,
        'query': query.query,
        if (query.allowed != null) 'allowed': query.allowed,
        if (query.categories != null) 'categories': query.categories,
        'limit': 80,
      }, cancellation);
      if (result['fallback'] == 'resource_busy') {
        throw const RagException('resource_busy');
      }
      if (_disposed || epoch != _epoch || cancellation.isCancelled) {
        return const [];
      }
      return [
        for (final item in result['items'] as List? ?? const [])
          RagSearchHit.fromJson((item as Map).cast<String, dynamic>()),
      ];
    } catch (error) {
      if (error is RagException && error.code == 'resource_busy') rethrow;
      if (epoch == _epoch &&
          !(error is RagException && error.code == 'cancelled')) {
        _fail(error, source: query.source);
      }
      return const [];
    } finally {
      if (counted && !_disposed && epoch == _epoch) {
        _change(
          query.source,
          (s) => s.copyWith(searching: (s.searching - 1).clamp(0, 100)),
        );
      }
    }
  }

  Future<String> _writeGalleryRoots(Directory root) async {
    final roots = (await ref.read(ragGalleryRootsProvider)()).toSet().toList()
      ..sort();
    final content = jsonEncode({'version': 1, 'roots': roots});
    final file = File(p.join(root.path, 'sources', 'gallery-roots.json'));
    final epoch = _epoch;
    final write = _snapshotWrites.catchError((Object _) {}).then((_) async {
      if (_disposed || epoch != _epoch) throw const RagException('cancelled');
      await file.parent.create(recursive: true);
      if (await file.exists() && await file.readAsString() == content) return;
      final temporary = File('${file.path}.tmp');
      await temporary.writeAsString(content, flush: true);
      if (_disposed || epoch != _epoch) throw const RagException('cancelled');
      await temporary.rename(file.path);
    });
    _snapshotWrites = write;
    await write;
    return file.path;
  }

  int _scopeId = 0;
  Future<List<RagGalleryHit>> searchGallery({
    required String query,
    required List<String> allowed,
    required RagCancellation cancellation,
    String image = '',
    RagGalleryMode mode = RagGalleryMode.mixed,
  }) async {
    if (_gpuHolds > 0) throw const RagException('resource_busy');
    if (!ref.read(ragSettingsProvider).enabledFor(RagSource.gallery) ||
        (query.trim().isEmpty && image.isEmpty) ||
        allowed.isEmpty) {
      return const [];
    }
    final epoch = _epoch;
    var counted = false;
    File? scope;
    try {
      final client = await _connect();
      final root = await ref.read(ragDirectoryProvider)();
      await _writeGalleryRoots(root);
      if (_disposed || epoch != _epoch || cancellation.isCancelled) {
        return const [];
      }
      scope = File(
        p.join(
          root.path,
          'search-scopes',
          '$pid-${DateTime.now().microsecondsSinceEpoch}-${_scopeId++}.json',
        ),
      );
      await scope.parent.create(recursive: true);
      await scope.writeAsString(jsonEncode(allowed), flush: true);
      if (_disposed || epoch != _epoch || cancellation.isCancelled) {
        return const [];
      }
      counted = true;
      _change(RagSource.gallery, (s) => s.copyWith(searching: s.searching + 1));
      final result = await client.request(
        'gallery_search',
        {
          'source': 'gallery',
          'query': query,
          'scope': scope.path,
          'image': image,
          'mode': mode.name,
          'limit': 60,
        },
        cancellation,
        const Duration(minutes: 3),
      );
      if (result['fallback'] != null) {
        throw const RagException('resource_busy');
      }
      if (_disposed || epoch != _epoch || cancellation.isCancelled) {
        return const [];
      }
      _change(
        RagSource.gallery,
        (s) => s.copyWith(
          clearError: true,
          phase: s.complete ? 'ready' : 'partial',
        ),
      );
      return [
        for (final value in result['items'] as List? ?? const [])
          RagGalleryHit.fromJson((value as Map).cast<String, dynamic>()),
      ];
    } catch (error) {
      if (epoch == _epoch &&
          !(error is RagException &&
              const {'cancelled', 'resource_busy'}.contains(error.code))) {
        _fail(error, source: RagSource.gallery);
      }
      rethrow;
    } finally {
      if (counted && !_disposed && epoch == _epoch) {
        _change(
          RagSource.gallery,
          (s) => s.copyWith(searching: (s.searching - 1).clamp(0, 100)),
        );
      }
      if (scope != null) {
        try {
          await scope.delete();
        } catch (_) {}
      }
    }
  }

  Future<List<CompletionCandidate>> recommend({
    required String text,
    required int cursor,
    required Set<String> existing,
    required List<CompletionCandidate> lexical,
    required RagCancellation cancellation,
    bool negative = false,
    String keyword = '',
    int limit = 40,
  }) async {
    if (!ref.read(ragSettingsProvider).enabledFor(RagSource.tags) ||
        _gpuHolds > 0) {
      return const [];
    }
    final epoch = _epoch;
    var counted = false;
    try {
      final c = await _connect();
      if (cancellation.isCancelled) return const [];
      if (!_disposed) {
        counted = true;
        state = state.copyWith(searching: state.searching + 1);
      }
      final result = await c.request('search', {
        'text': text,
        'cursor': cursor,
        'mode': ref.read(ragSettingsProvider).mode.name,
        'existing': existing.toList(),
        'lexical': lexical.map((e) => e.canonicalTag).toList(),
        'negative': negative,
        'keyword': keyword,
        'limit': limit,
      }, cancellation);
      if (result['fallback'] == 'resource_busy') {
        throw const RagException('resource_busy');
      }
      if (_disposed || epoch != _epoch || cancellation.isCancelled) {
        return const [];
      }
      return [
        for (final raw in result['items'] as List? ?? const [])
          CompletionCandidate(
            canonicalTag: raw['name'] as String,
            category:
                TagCategory.fromCatalog(raw['category'] as int) ??
                TagCategory.general,
            postCount: (raw['post_count'] as num).toInt(),
            aliases: List<String>.from(raw['aliases'] as List),
            translation: (raw['core_zh'] as String?)?.isEmpty == false
                ? raw['core_zh'] as String
                : null,
            score: (raw['score'] as num?)?.toDouble() ?? 0,
            retrievalOrigins: List<String>.unmodifiable(
              (raw['origins'] as List? ?? const []).cast<String>(),
            ),
            matchKind: CompletionMatchKind.related,
            sources: const {CompletionSourceKind.base},
          ),
      ];
    } catch (error) {
      if (error is RagException && error.code == 'resource_busy') rethrow;
      if (epoch == _epoch &&
          !(error is RagException && error.code == 'cancelled')) {
        _fail(error);
      }
      return const [];
    } finally {
      if (counted && !_disposed && epoch == _epoch) {
        state = state.copyWith(searching: (state.searching - 1).clamp(0, 100));
      }
    }
  }

  Future<void> installRuntime({required bool cuda}) async {
    if (_installer != null || state.installPhase != null) return;
    final release = ref
        .read(ragMaintenanceProvider)
        .claim(indexBusy: state.anyBusy);
    final selectedPython = ref.read(ragSettingsProvider).python;
    _runtimeInstallCancelled = false;
    state = state.copyWith(
      installPhase: 'existing',
      installElapsed: 0,
      installDetail: '',
      clearError: true,
    );
    RagRuntimeInstaller? installer;
    try {
      await _reset();
      if (_disposed || _runtimeInstallCancelled) return;
      final root = await ref.read(ragDirectoryProvider)();
      if (_disposed || _runtimeInstallCancelled) return;
      installer = _installer = RagRuntimeInstaller(root);
      final python = await installer.install(
        cuda: cuda,
        preferredPython: selectedPython,
        onProgress: (seconds, detail) {
          if (!_disposed) {
            state = state.copyWith(
              installElapsed: seconds,
              installDetail: detail,
            );
          }
        },
        onPhase: (phase) {
          if (!_disposed) {
            state = state.copyWith(installPhase: phase, clearError: true);
          }
        },
      );
      if (!_disposed) {
        final latest = ref.read(ragSettingsProvider);
        if (latest.python == selectedPython) {
          await ref
              .read(ragSettingsProvider.notifier)
              .update(latest.copyWith(python: python));
        }
      }
    } catch (error) {
      if (!_runtimeInstallCancelled &&
          !(error is RagException && error.code == 'cancelled')) {
        if (!_disposed) {
          state = state.copyWith(installDetail: installer?.diagnostic ?? '');
        }
        _fail(error);
      }
    } finally {
      installer?.dispose();
      _installer = null;
      release();
      if (!_disposed) {
        state = state.copyWith(clearInstall: true);
        ref.invalidate(ragRuntimeInfoProvider);
        if (_enabled) unawaited(refresh());
      }
    }
  }

  void cancelInstall() {
    _runtimeInstallCancelled = true;
    _installer?.cancel();
  }
}

final ragTextSearchProvider = FutureProvider.autoDispose
    .family<List<RagSearchHit>, RagTextQuery>((ref, query) async {
      final settings = ref.watch(ragSettingsProvider);
      if (!settings.enabledFor(query.source) || query.query.trim().isEmpty) {
        return const [];
      }
      ref.watch(
        ragControllerProvider.select(
          (s) => (
            s.forSource(query.source).indexed,
            s.forSource(query.source).complete,
            s.suspended,
          ),
        ),
      );
      if (query.source == RagSource.blocks) {
        ref.watch(
          promptBlockLibraryNotifierProvider.select(
            (s) => s.valueOrNull == null
                ? null
                : encodeRagBlocks(s.requireValue.blocks),
          ),
        );
      }
      final cancellation = RagCancellation();
      ref.onDispose(cancellation.cancel);
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (cancellation.isCancelled) return const [];
      return ref
          .read(ragControllerProvider.notifier)
          .searchText(query, cancellation: cancellation);
    });
