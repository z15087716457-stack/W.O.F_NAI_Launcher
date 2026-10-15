import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/autocomplete/completion_models.dart';
import '../../core/database/asset_database_manager.dart';
import '../../core/rag/rag_client.dart';
import '../../core/rag/rag_settings.dart';
import '../../core/rag/rag_runtime.dart';
import '../../core/rag/rag_text_search.dart';
import '../../core/rag/rag_block_snapshot.dart';
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
    this.sources = const {},
    this.runtimeReady = false,
  });
  final String phase;
  final int indexed, processed, total, bytes, searching;
  final String? jobId, error, installPhase;
  final bool busy, complete, partial, suspended;
  final bool runtimeReady;
  final Map<RagSource, RagStatus> sources;
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
    bool clearInstall = false,
    Map<RagSource, RagStatus>? sources,
    bool? runtimeReady,
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
    sources: sources ?? this.sources,
    runtimeReady: runtimeReady ?? this.runtimeReady,
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

typedef RagClientStarter =
    Future<RagClient> Function({
      required String python,
      required Directory directory,
    });
final ragClientStarterProvider = Provider<RagClientStarter>(
  (ref) => RagClient.start,
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

class RagController extends Notifier<RagStatus> {
  RagClient? _client;
  Future<RagClient>? _connecting;
  StreamSubscription<Map<String, dynamic>>? _events;
  Timer? _refresh;
  RagRuntimeInstaller? _installer;
  bool _disposed = false;
  int _epoch = 0, _gpuHolds = 0;
  final _finishedJobs = <String>{};
  Future<void> _snapshotWrites = Future.value();
  Object? _refreshToken;
  @override
  RagStatus build() {
    final unregister = DesktopAppShutdownService.registerCleanup(() async {
      _disposed = true;
      _epoch++;
      _refresh?.cancel();
      _installer?.cancel();
      await _client?.close();
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
    _refreshToken = null;
    _finishedJobs.clear();
    final old = _client;
    _client = null;
    await _events?.cancel();
    await old?.close();
    if (_disposed || epoch != _epoch) return;
    state = const RagStatus();
    if (_enabled) await refresh();
  }

  Future<RagClient> _connect() {
    if (!_enabled) return Future.error(const RagException('disabled'));
    if (_client case final client? when !client.isClosed) {
      return Future.value(client);
    }
    if (_connecting case final pending?) return pending;
    late final Future<RagClient> attempt;
    attempt = _open().whenComplete(() {
      if (identical(_connecting, attempt)) _connecting = null;
    });
    return _connecting = attempt;
  }

  Future<RagClient> _open() async {
    final epoch = _epoch;
    final settings = ref.read(ragSettingsProvider);
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
        _change(source, (s) => s.copyWith(phase: 'loading', clearError: true));
      }
    }
    final paths = await ref.read(ragSourcePathsProvider)();
    final snapshot = settings.blocksEnabled
        ? await _writeBlockSnapshot(root)
        : '';
    final client = await ref.read(ragClientStarterProvider)(
      python: python,
      directory: root,
    );
    try {
      final result = await client.request('configure', {
        'embedding': settings.embedding,
        'reranker': settings.reranker,
        'device': settings.device.name,
        'directory': p.join(root.path, 'indices'),
        'catalog': paths.catalog,
        'runtime': paths.runtime,
        'wiki': paths.wiki,
        'blocks': snapshot,
        'sources': [
          for (final source in RagSource.values)
            if (settings.enabledFor(source)) source.name,
        ],
      });
      if (_disposed || epoch != _epoch) throw const RagException('cancelled');
      _client = client;
      _events = client.events.listen((event) {
        if (_disposed || epoch != _epoch) return;
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
              busy: event['phase'] == 'building',
              clearJob: ['complete', 'error'].contains(event['phase']),
              error: event['code'] as String?,
              clearError: event['phase'] != 'error',
            ),
          );
        }
      });
      _apply(result);
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
        indexed: (result['indexed'] as num?)?.toInt(),
        processed: (result['processed'] as num?)?.toInt(),
        total: (result['total'] as num?)?.toInt(),
        bytes: (result['bytes'] as num?)?.toInt(),
        complete: result['complete'] as bool?,
        partial: result['partial'] as bool?,
        busy: result['building'] as bool?,
        phase: result['paused'] == true
            ? 'paused'
            : result['building'] == true
            ? 'building'
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
    if (!_enabled || _disposed || _refreshToken != null) return;
    final refreshToken = _refreshToken = Object();
    final epoch = _epoch;
    try {
      final c = await _connect();
      if (ref.read(ragSettingsProvider).enabledFor(RagSource.blocks)) {
        await _writeBlockSnapshot(await ref.read(ragDirectoryProvider)());
      }
      final status = await c.request('status');
      if (_disposed || epoch != _epoch) return;
      _apply(status);
      final sources = status['sources'] as Map? ?? {'tags': status};
      for (final source in RagSource.values) {
        final value = sources[source.name] as Map?;
        if (autoUpdate &&
            value?['auto_update_allowed'] == true &&
            value?['complete'] != true &&
            state.forSource(source).jobId == null &&
            !state.suspended &&
            _gpuHolds == 0 &&
            ref.read(ragSettingsProvider).enabledFor(source)) {
          final plan = await c.request('preview', {'source': source.name});
          await start(plan['plan_id'] as String, source: source);
        }
      }
    } catch (error) {
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

  Future<Map<String, dynamic>> preview({
    RagSource source = RagSource.tags,
  }) async {
    final c = await _connect();
    if (source == RagSource.blocks) {
      await _writeBlockSnapshot(await ref.read(ragDirectoryProvider)());
    }
    return c.request('preview', {'source': source.name});
  }

  Future<void> start(
    String planId, {
    bool rebuild = false,
    RagSource source = RagSource.tags,
  }) async {
    final epoch = _epoch;
    try {
      final c = await _connect();
      if (rebuild) await c.request('clear', {'source': source.name});
      final result = await c.request('start', {
        'plan_id': planId,
        'source': source.name,
      });
      if (!_disposed &&
          epoch == _epoch &&
          !_finishedJobs.contains(result['job_id'])) {
        _change(
          source,
          (s) => s.copyWith(
            jobId: result['job_id'] as String,
            phase: 'building',
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

  Future<void> resume({RagSource source = RagSource.tags}) async {
    final epoch = _epoch;
    final id = state.forSource(source).jobId;
    if (id == null) {
      final p = await preview(source: source);
      await start(p['plan_id'] as String, source: source);
      return;
    }
    await (await _connect()).request('resume', {
      'job_id': id,
      'source': source.name,
    });
    if (!_disposed && epoch == _epoch) {
      _change(source, (s) => s.copyWith(phase: 'building', busy: true));
    }
  }

  Future<void> clear({RagSource source = RagSource.tags}) async {
    final epoch = _epoch;
    final c = await _connect();
    final result = await c.request('clear', {'source': source.name});
    if (_disposed || epoch != _epoch) return;
    _applyIndex(result, source);
    _change(source, (s) => s.copyWith(clearJob: true));
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
    if (query.source == RagSource.tags ||
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
      if (_disposed || epoch != _epoch || cancellation.isCancelled) {
        return const [];
      }
      return [
        for (final item in result['items'] as List? ?? const [])
          RagSearchHit.fromJson((item as Map).cast<String, dynamic>()),
      ];
    } catch (error) {
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
            matchKind: CompletionMatchKind.related,
            sources: const {CompletionSourceKind.base},
          ),
      ];
    } catch (error) {
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
    if (_installer != null) return;
    final installer = _installer = RagRuntimeInstaller(
      await ref.read(ragDirectoryProvider)(),
    );
    try {
      final python = await installer.install(
        cuda: cuda,
        onPhase: (phase) {
          if (!_disposed) {
            state = state.copyWith(installPhase: phase, clearError: true);
          }
        },
      );
      if (!_disposed) {
        await ref
            .read(ragSettingsProvider.notifier)
            .update(ref.read(ragSettingsProvider).copyWith(python: python));
      }
    } catch (error) {
      _fail(error);
    } finally {
      installer.dispose();
      _installer = null;
      if (!_disposed) state = state.copyWith(clearInstall: true);
    }
  }

  void cancelInstall() => _installer?.cancel();
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
